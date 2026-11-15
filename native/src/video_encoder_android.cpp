// VideoEncoder's backend on Android: the NDK's MediaCodec (H.264) and
// MediaMuxer (MP4), fed YUV 4:2:0 converted here from RGBA (BT.709,
// limited range). No JNI.

#ifdef __ANDROID__

#include "video_encoder.h"

#include <dlfcn.h>
#include <fcntl.h>
#include <media/NdkMediaCodec.h>
#include <media/NdkMediaFormat.h>
#include <media/NdkMediaMuxer.h>
#include <unistd.h>

#include <cstring>

namespace godot {

namespace {

constexpr int32_t COLOR_YUV420_PLANAR = 19;
constexpr int32_t COLOR_YUV420_SEMIPLANAR = 21;
constexpr int64_t DEQUEUE_US = 10000;
constexpr int INPUT_TRIES = 200; // About two seconds of 10 ms waits.

inline uint8_t clamp8(int v) {
	return (uint8_t)(v < 0 ? 0 : (v > 255 ? 255 : v));
}

class AndroidVideoBackend : public VideoBackend {
	AMediaCodec *codec = nullptr;
	AMediaMuxer *muxer = nullptr;
	int fd = -1;
	std::string file_path;
	int width = 0;
	int height = 0;
	int32_t color = COLOR_YUV420_SEMIPLANAR;
	// The codec's input layout: row stride and rows per plane, which many
	// hardware encoders pad past the width and height.
	int stride = 0;
	int slice = 0;
	ssize_t track = -1;
	bool muxing = false;
	int64_t frames = 0;

	AMediaFormat *format_for(int fps, int bitrate, int32_t color_format) {
		AMediaFormat *f = AMediaFormat_new();
		AMediaFormat_setString(f, AMEDIAFORMAT_KEY_MIME, "video/avc");
		AMediaFormat_setInt32(f, AMEDIAFORMAT_KEY_WIDTH, width);
		AMediaFormat_setInt32(f, AMEDIAFORMAT_KEY_HEIGHT, height);
		AMediaFormat_setInt32(f, AMEDIAFORMAT_KEY_BIT_RATE, bitrate);
		AMediaFormat_setInt32(f, AMEDIAFORMAT_KEY_FRAME_RATE, fps);
		AMediaFormat_setInt32(f, AMEDIAFORMAT_KEY_I_FRAME_INTERVAL, 2);
		AMediaFormat_setInt32(f, AMEDIAFORMAT_KEY_COLOR_FORMAT, color_format);
		// BT.709, limited range, SDR video transfer (MediaFormat constants).
		AMediaFormat_setInt32(f, "color-standard", 1);
		AMediaFormat_setInt32(f, "color-range", 2);
		AMediaFormat_setInt32(f, "color-transfer", 3);
		return f;
	}

	// Bytes of one frame in the codec's layout, padding included.
	size_t frame_bytes() const {
		return (size_t)stride * slice + (size_t)stride * ((slice + 1) / 2);
	}

	// Bytes to_yuv writes: the last plane needs no padding rows after it.
	size_t written_bytes() const {
		size_t chroma_rows = (size_t)height / 2;
		if (color == COLOR_YUV420_SEMIPLANAR) {
			return (size_t)stride * slice + (size_t)stride * chroma_rows;
		}
		return (size_t)stride * slice + (size_t)(stride / 2) * ((slice + 1) / 2) + (size_t)(stride / 2) * chroma_rows;
	}

	// Reads the input layout the codec asked for (API 28+; older devices
	// take the plain width and height, which the 16-aligned size keeps).
	void read_layout() {
		stride = width;
		slice = height;
		using GetInputFormat = AMediaFormat *(*)(AMediaCodec *);
		auto get = (GetInputFormat)dlsym(RTLD_DEFAULT, "AMediaCodec_getInputFormat");
		if (get == nullptr) {
			return;
		}
		AMediaFormat *f = get(codec);
		if (f == nullptr) {
			return;
		}
		int32_t v = 0;
		if (AMediaFormat_getInt32(f, "stride", &v) && v >= width) {
			stride = v;
		}
		if (AMediaFormat_getInt32(f, "slice-height", &v) && v >= height) {
			slice = v;
		}
		AMediaFormat_delete(f);
	}

	// `px` RGBA, or BGRA when `bgra`: read in either order, no reordering.
	void to_yuv(const uint8_t *px, bool bgra, uint8_t *out) {
		const int ri = bgra ? 2 : 0;
		const int bi = bgra ? 0 : 2;
		const uint8_t *rgba = px;
		uint8_t *yp = out;
		uint8_t *up = out + (size_t)stride * slice;
		// Planar: the V plane follows a U plane of half stride, half rows.
		uint8_t *vp = up + (size_t)(stride / 2) * ((slice + 1) / 2);
		for (int y = 0; y < height; y++) {
			const uint8_t *s = rgba + (size_t)y * width * 4;
			uint8_t *dy = yp + (size_t)y * stride;
			for (int x = 0; x < width; x++, s += 4) {
				dy[x] = clamp8(((47 * s[ri] + 157 * s[1] + 16 * s[bi] + 128) >> 8) + 16);
			}
		}
		for (int y = 0; y < height / 2; y++) {
			for (int x = 0; x < width / 2; x++) {
				int r = 0, g = 0, b = 0;
				for (int k = 0; k < 4; k++) {
					const uint8_t *s = rgba + ((size_t)(y * 2 + (k >> 1)) * width + x * 2 + (k & 1)) * 4;
					r += s[ri];
					g += s[1];
					b += s[bi];
				}
				r >>= 2;
				g >>= 2;
				b >>= 2;
				uint8_t u = clamp8(((-26 * r - 87 * g + 112 * b + 128) >> 8) + 128);
				uint8_t v = clamp8(((112 * r - 102 * g - 10 * b + 128) >> 8) + 128);
				if (color == COLOR_YUV420_SEMIPLANAR) {
					size_t i = (size_t)y * stride + (size_t)x * 2;
					up[i] = u;
					up[i + 1] = v;
				} else {
					size_t i = (size_t)y * (stride / 2) + x;
					up[i] = u;
					vp[i] = v;
				}
			}
		}
	}

	// Moves finished output into the muxer; with `until_eos`, until the end.
	bool drain(bool until_eos, std::string &error) {
		int waits = 0;
		while (true) {
			AMediaCodecBufferInfo info;
			ssize_t index = AMediaCodec_dequeueOutputBuffer(codec, &info, until_eos ? DEQUEUE_US : 0);
			if (index == AMEDIACODEC_INFO_TRY_AGAIN_LATER) {
				if (!until_eos) {
					return true;
				}
				if (++waits > INPUT_TRIES) {
					error = "couldn't finish the video file";
					return false;
				}
				continue;
			}
			if (index == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
				AMediaFormat *f = AMediaCodec_getOutputFormat(codec);
				track = AMediaMuxer_addTrack(muxer, f);
				AMediaFormat_delete(f);
				if (track < 0 || AMediaMuxer_start(muxer) != AMEDIA_OK) {
					error = "couldn't start the video file";
					return false;
				}
				muxing = true;
				continue;
			}
			if (index == AMEDIACODEC_INFO_OUTPUT_BUFFERS_CHANGED) {
				continue;
			}
			if (index < 0) {
				error = "the video encoder failed";
				return false;
			}
			size_t size = 0;
			uint8_t *data = AMediaCodec_getOutputBuffer(codec, (size_t)index, &size);
			bool config = (info.flags & AMEDIACODEC_BUFFER_FLAG_CODEC_CONFIG) != 0;
			if (data != nullptr && info.size > 0 && !config && muxing) {
				AMediaMuxer_writeSampleData(muxer, (size_t)track, data, &info);
			}
			AMediaCodec_releaseOutputBuffer(codec, (size_t)index, false);
			if (info.flags & AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) {
				return true;
			}
		}
	}

	void release() {
		if (codec != nullptr) {
			AMediaCodec_stop(codec);
			AMediaCodec_delete(codec);
			codec = nullptr;
		}
		if (muxer != nullptr) {
			if (muxing) {
				AMediaMuxer_stop(muxer);
			}
			AMediaMuxer_delete(muxer);
			muxer = nullptr;
		}
		if (fd >= 0) {
			::close(fd);
			fd = -1;
		}
		muxing = false;
	}

public:
	~AndroidVideoBackend() override {
		release();
	}

	bool open(const std::string &path, int w, int h, int fps, int bitrate, std::string &error,
			int &kind) override {
		width = w;
		height = h;
		codec = AMediaCodec_createEncoderByType("video/avc");
		if (codec == nullptr) {
			error = "this device has no H.264 encoder";
			kind = VIDEO_ERROR_NO_ENCODER;
			return false;
		}
		bool configured = false;
		for (int32_t c : { COLOR_YUV420_SEMIPLANAR, COLOR_YUV420_PLANAR }) {
			if (codec == nullptr) {
				// A failed configure can leave the codec unusable: a new one.
				codec = AMediaCodec_createEncoderByType("video/avc");
				if (codec == nullptr) {
					break;
				}
			}
			AMediaFormat *f = format_for(fps, bitrate, c);
			media_status_t st = AMediaCodec_configure(codec, f, nullptr, nullptr, AMEDIACODEC_CONFIGURE_FLAG_ENCODE);
			AMediaFormat_delete(f);
			if (st == AMEDIA_OK) {
				color = c;
				configured = true;
				break;
			}
			AMediaCodec_delete(codec);
			codec = nullptr;
		}
		if (!configured || AMediaCodec_start(codec) != AMEDIA_OK) {
			error = "this device can't encode H.264 at that size";
			kind = VIDEO_ERROR_TOO_LARGE;
			release();
			return false;
		}
		read_layout();
		file_path = path;
		fd = ::open(path.c_str(), O_CREAT | O_TRUNC | O_RDWR, 0644);
		if (fd < 0) {
			error = "couldn't create the video file";
			release();
			return false;
		}
		muxer = AMediaMuxer_new(fd, AMEDIAMUXER_OUTPUT_FORMAT_MPEG_4);
		if (muxer == nullptr) {
			error = "couldn't create the video file";
			release();
			return false;
		}
		return true;
	}

	bool encode(const uint8_t *pixels, bool bgra, int64_t pts_usec, std::string &error) override {
		ssize_t index = -1;
		for (int i = 0; i < INPUT_TRIES && index < 0; i++) {
			index = AMediaCodec_dequeueInputBuffer(codec, DEQUEUE_US);
			if (index < 0 && !drain(false, error)) {
				return false;
			}
		}
		if (index < 0) {
			error = "the video encoder stopped accepting frames";
			return false;
		}
		size_t capacity = 0;
		uint8_t *buf = AMediaCodec_getInputBuffer(codec, (size_t)index, &capacity);
		if (buf == nullptr || capacity < written_bytes()) {
			error = "the video encoder's frame buffer is too small";
			return false;
		}
		to_yuv(pixels, bgra, buf);
		size_t need = frame_bytes() <= capacity ? frame_bytes() : written_bytes();
		if (AMediaCodec_queueInputBuffer(codec, (size_t)index, 0, need, (uint64_t)pts_usec, 0) != AMEDIA_OK) {
			error = "couldn't add a frame to the video";
			return false;
		}
		frames++;
		return drain(false, error);
	}

	bool close(std::string &error) override {
		if (codec == nullptr) {
			return false;
		}
		if (frames == 0) {
			// A muxer stopped with no samples fails: say what happened.
			muxing = false;
			release();
			::unlink(file_path.c_str());
			error = VIDEO_NO_FRAMES;
			return false;
		}
		bool ok = true;
		// Room for the end-of-stream marker: empty finished output meanwhile,
		// as encode() does, or a codec with every slot busy never gives one.
		ssize_t index = -1;
		for (int i = 0; i < INPUT_TRIES && index < 0; i++) {
			index = AMediaCodec_dequeueInputBuffer(codec, DEQUEUE_US);
			if (index < 0 && !drain(false, error)) {
				break;
			}
		}
		if (index >= 0) {
			if (AMediaCodec_queueInputBuffer(codec, (size_t)index, 0, 0, 0, AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) == AMEDIA_OK) {
				ok = drain(true, error);
			} else {
				ok = false;
				error = "couldn't end the video stream";
			}
		} else {
			ok = false;
			if (error.empty()) {
				error = "couldn't finish the video file";
			}
		}
		if (!muxing) {
			// Frames went in (frames > 0) but no video came out.
			ok = false;
			if (error.empty()) {
				error = "the video encoder produced no video";
			}
		} else {
			// Stopping writes the file's index: without it the MP4 won't play.
			if (AMediaMuxer_stop(muxer) != AMEDIA_OK && ok) {
				ok = false;
				error = "couldn't finish the video file";
			}
			muxing = false;
		}
		release();
		if (!ok) {
			// A file that couldn't be finished can't play: don't leave it
			// (it may be in the shared Movies folder, out of the app's reach).
			::unlink(file_path.c_str());
		}
		return ok;
	}
};

} // namespace

std::unique_ptr<VideoBackend> make_video_backend() {
	return std::unique_ptr<VideoBackend>(new AndroidVideoBackend());
}

} // namespace godot

#endif // __ANDROID__
