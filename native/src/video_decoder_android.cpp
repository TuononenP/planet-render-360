// VideoDecoder's backend on Android: the NDK's MediaExtractor and
// MediaCodec (H.264) decoding to YUV 4:2:0 buffers, converted here to
// RGBA (BT.709, limited range, as the recorder writes). No JNI.

#ifdef __ANDROID__

#include "video_decoder.h"

#include <fcntl.h>
#include <media/NdkMediaCodec.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>
#include <sys/stat.h>
#include <unistd.h>

#include <cstring>

namespace godot {

namespace {

constexpr int32_t COLOR_YUV420_PLANAR = 19;
constexpr int32_t COLOR_YUV420_PACKED_PLANAR = 20;
constexpr int64_t DEQUEUE_US = 10000;
constexpr int OUTPUT_TRIES = 300; // About three seconds of 10 ms waits.

inline uint8_t clamp8(int v) {
	return (uint8_t)(v < 0 ? 0 : (v > 255 ? 255 : v));
}

class AndroidVideoDecodeBackend : public VideoDecodeBackend {
	AMediaExtractor *extractor = nullptr;
	AMediaCodec *codec = nullptr;
	int fd = -1;
	int width = 0;
	int height = 0;
	// The decoder's output layout, which it may pad and crop.
	int32_t color = 21;
	int stride = 0;
	int slice = 0;
	int crop_left = 0;
	int crop_top = 0;
	bool input_done = false;
	bool output_done = false;

	void read_output_format() {
		AMediaFormat *f = AMediaCodec_getOutputFormat(codec);
		if (f == nullptr) {
			return;
		}
		int32_t v = 0;
		if (AMediaFormat_getInt32(f, AMEDIAFORMAT_KEY_COLOR_FORMAT, &v)) {
			color = v;
		}
		int32_t w = width;
		int32_t h = height;
		AMediaFormat_getInt32(f, AMEDIAFORMAT_KEY_WIDTH, &w);
		AMediaFormat_getInt32(f, AMEDIAFORMAT_KEY_HEIGHT, &h);
		stride = AMediaFormat_getInt32(f, "stride", &v) && v > 0 ? v : w;
		slice = AMediaFormat_getInt32(f, "slice-height", &v) && v > 0 ? v : h;
		crop_left = AMediaFormat_getInt32(f, "crop-left", &v) ? v : 0;
		crop_top = AMediaFormat_getInt32(f, "crop-top", &v) ? v : 0;
		AMediaFormat_delete(f);
	}

	void to_rgba(const uint8_t *buf, size_t size, uint8_t *rgba) const {
		bool planar = color == COLOR_YUV420_PLANAR || color == COLOR_YUV420_PACKED_PLANAR;
		size_t luma = (size_t)stride * slice;
		const uint8_t *yp = buf;
		const uint8_t *up = buf + luma;
		const uint8_t *vp = planar ? up + (size_t)(stride / 2) * ((slice + 1) / 2) : up + 1;
		int cstride = planar ? stride / 2 : stride;
		int cstep = planar ? 1 : 2;
		size_t need = planar ? luma + (size_t)(stride / 2) * ((slice + 1) / 2) * 2 : luma + (size_t)stride * (slice / 2);
		if (size < need) {
			std::memset(rgba, 0, (size_t)width * height * 4);
			return;
		}
		for (int y = 0; y < height; y++) {
			int sy = y + crop_top;
			const uint8_t *yr = yp + (size_t)sy * stride + crop_left;
			const uint8_t *ur = up + (size_t)(sy / 2) * cstride;
			const uint8_t *vr = vp + (size_t)(sy / 2) * cstride;
			uint8_t *d = rgba + (size_t)y * width * 4;
			for (int x = 0; x < width; x++, d += 4) {
				int sx = x + crop_left;
				int c = 298 * (yr[x] - 16);
				int u = ur[(sx / 2) * cstep] - 128;
				int v = vr[(sx / 2) * cstep] - 128;
				d[0] = clamp8((c + 459 * v + 128) >> 8);
				d[1] = clamp8((c - 55 * u - 136 * v + 128) >> 8);
				d[2] = clamp8((c + 541 * u + 128) >> 8);
				d[3] = 255;
			}
		}
	}

	void feed() {
		if (input_done) {
			return;
		}
		ssize_t idx = AMediaCodec_dequeueInputBuffer(codec, 0);
		if (idx < 0) {
			return;
		}
		size_t cap = 0;
		uint8_t *in = AMediaCodec_getInputBuffer(codec, (size_t)idx, &cap);
		ssize_t n = in != nullptr ? AMediaExtractor_readSampleData(extractor, in, cap) : -1;
		if (n < 0) {
			AMediaCodec_queueInputBuffer(codec, (size_t)idx, 0, 0, 0, AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM);
			input_done = true;
			return;
		}
		AMediaCodec_queueInputBuffer(codec, (size_t)idx, 0, (size_t)n,
				(uint64_t)AMediaExtractor_getSampleTime(extractor), 0);
		AMediaExtractor_advance(extractor);
	}

public:
	~AndroidVideoDecodeBackend() override {
		if (codec != nullptr) {
			AMediaCodec_stop(codec);
			AMediaCodec_delete(codec);
		}
		if (extractor != nullptr) {
			AMediaExtractor_delete(extractor);
		}
		if (fd >= 0) {
			::close(fd);
		}
	}

	bool open(const std::string &path, int &w, int &h, int64_t &duration_usec, std::string &error) override {
		fd = ::open(path.c_str(), O_RDONLY);
		struct stat st;
		if (fd < 0 || fstat(fd, &st) != 0) {
			error = "couldn't open the video file";
			return false;
		}
		extractor = AMediaExtractor_new();
		if (AMediaExtractor_setDataSourceFd(extractor, fd, 0, st.st_size) != AMEDIA_OK) {
			error = "couldn't read the video file";
			return false;
		}
		size_t tracks = AMediaExtractor_getTrackCount(extractor);
		for (size_t i = 0; i < tracks; i++) {
			AMediaFormat *f = AMediaExtractor_getTrackFormat(extractor, i);
			const char *mime = nullptr;
			if (AMediaFormat_getString(f, AMEDIAFORMAT_KEY_MIME, &mime) && mime != nullptr
					&& std::strncmp(mime, "video/", 6) == 0) {
				int32_t fw = 0;
				int32_t fh = 0;
				int64_t dur = 0;
				AMediaFormat_getInt32(f, AMEDIAFORMAT_KEY_WIDTH, &fw);
				AMediaFormat_getInt32(f, AMEDIAFORMAT_KEY_HEIGHT, &fh);
				AMediaFormat_getInt64(f, AMEDIAFORMAT_KEY_DURATION, &dur);
				width = w = fw;
				height = h = fh;
				stride = fw;
				slice = fh;
				duration_usec = dur;
				AMediaExtractor_selectTrack(extractor, i);
				codec = AMediaCodec_createDecoderByType(mime);
				bool ok = codec != nullptr
						&& AMediaCodec_configure(codec, f, nullptr, nullptr, 0) == AMEDIA_OK
						&& AMediaCodec_start(codec) == AMEDIA_OK;
				AMediaFormat_delete(f);
				if (!ok) {
					error = "this device can't decode the video";
				}
				return ok;
			}
			AMediaFormat_delete(f);
		}
		error = "the file has no video";
		return false;
	}

	bool seek(int64_t usec, std::string &error) override {
		if (AMediaExtractor_seekTo(extractor, usec, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC) != AMEDIA_OK
				|| AMediaCodec_flush(codec) != AMEDIA_OK) {
			error = "couldn't move in the video";
			return false;
		}
		input_done = false;
		output_done = false;
		return true;
	}

	bool next(uint8_t *rgba, int64_t &pts_usec, bool &eof, std::string &error) override {
		eof = false;
		if (output_done) {
			eof = true;
			return false;
		}
		for (int tries = 0; tries < OUTPUT_TRIES; tries++) {
			feed();
			AMediaCodecBufferInfo info;
			ssize_t idx = AMediaCodec_dequeueOutputBuffer(codec, &info, DEQUEUE_US);
			if (idx == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
				read_output_format();
				continue;
			}
			if (idx < 0) {
				continue; // Try again later, or the output buffers changed.
			}
			bool last = (info.flags & AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) != 0;
			if (info.size > 0) {
				size_t cap = 0;
				uint8_t *out = AMediaCodec_getOutputBuffer(codec, (size_t)idx, &cap);
				if (out != nullptr) {
					to_rgba(out + info.offset, (size_t)info.size, rgba);
				}
				pts_usec = info.presentationTimeUs;
				AMediaCodec_releaseOutputBuffer(codec, (size_t)idx, false);
				output_done = last;
				return true;
			}
			AMediaCodec_releaseOutputBuffer(codec, (size_t)idx, false);
			if (last) {
				eof = true;
				return false;
			}
		}
		error = "the video decoder stopped giving frames";
		return false;
	}
};

} // namespace

std::unique_ptr<VideoDecodeBackend> make_video_decode_backend() {
	return std::unique_ptr<VideoDecodeBackend>(new AndroidVideoDecodeBackend());
}

} // namespace godot

#endif
