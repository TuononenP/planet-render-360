#include "video_encoder.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/char_string.hpp>

#include <cstring>

namespace godot {

const char *const VIDEO_NO_FRAMES = "no frames were recorded";

void video_scale_rgba(const uint8_t *src, int sw, int sh, uint8_t *dst, int dw, int dh) {
	if (sw == dw && sh == dh) {
		std::memcpy(dst, src, (size_t)sw * sh * 4);
		return;
	}
	for (int y = 0; y < dh; y++) {
		int y0 = (int)((int64_t)y * sh / dh);
		int y1 = (int)((int64_t)(y + 1) * sh / dh);
		if (y1 <= y0) {
			y1 = y0 + 1;
		}
		for (int x = 0; x < dw; x++) {
			int x0 = (int)((int64_t)x * sw / dw);
			int x1 = (int)((int64_t)(x + 1) * sw / dw);
			if (x1 <= x0) {
				x1 = x0 + 1;
			}
			uint32_t sum[4] = { 0, 0, 0, 0 };
			for (int sy = y0; sy < y1; sy++) {
				const uint8_t *row = src + ((size_t)sy * sw + x0) * 4;
				for (int sx = x0; sx < x1; sx++, row += 4) {
					sum[0] += row[0];
					sum[1] += row[1];
					sum[2] += row[2];
					sum[3] += row[3];
				}
			}
			uint32_t n = (uint32_t)((y1 - y0) * (x1 - x0));
			uint8_t *out = dst + ((size_t)y * dw + x) * 4;
			for (int c = 0; c < 4; c++) {
				out[c] = (uint8_t)((sum[c] + n / 2) / n);
			}
		}
	}
}

VideoEncoder::~VideoEncoder() {
	if (running) {
		finish();
	}
}

bool VideoEncoder::is_supported() {
	return make_video_backend() != nullptr;
}

int VideoEncoder::bytes_per_pixel(int format) {
	switch (format) {
		case FORMAT_RGBA8:
		case FORMAT_BGRA8:
			return 4;
		default:
			return 0;
	}
}

bool VideoEncoder::start(const String &path, int width, int height, int fps, int bitrate) {
	if (running) {
		// Leaves the recording in progress alone.
		return false;
	}
	error.clear();
	failed = false;
	error_kind = VIDEO_ERROR_FILE;
	encoded = 0;
	dropped = 0;
	last_pts = -1;
	if (width < 16 || height < 16 || (width & 1) || (height & 1) || fps <= 0 || bitrate <= 0) {
		fail("bad video size or rate");
		return false;
	}
	backend = make_video_backend();
	if (!backend) {
		error_kind = VIDEO_ERROR_NO_ENCODER;
		fail("video recording is not supported on this platform");
		return false;
	}
	std::string message;
	int kind = VIDEO_ERROR_FILE;
	if (!backend->open(std::string(path.utf8().get_data()), width, height, fps, bitrate, message, kind)) {
		backend.reset();
		error_kind = kind;
		fail(message);
		return false;
	}
	out_w = width;
	out_h = height;
	stopping = false;
	running = true;
	worker = std::thread(&VideoEncoder::run, this);
	return true;
}

bool VideoEncoder::push_frame(const PackedByteArray &data, int width, int height, int64_t pts_usec, int format) {
	if (!running || failed) {
		return false;
	}
	// Frames come already at the video's size (VideoScaler on the GPU).
	int bpp = bytes_per_pixel(format);
	if (bpp == 0 || width != out_w || height != out_h || data.size() < (int64_t)width * height * bpp
			|| pts_usec <= last_pts) {
		dropped++;
		return false;
	}
	{
		std::lock_guard<std::mutex> guard(lock);
		if ((int)queue.size() >= QUEUE_MAX) {
			dropped++;
			return false;
		}
		Frame frame;
		// Shares the array's buffer (copy on write): no copy on this thread.
		frame.data = data;
		frame.width = width;
		frame.height = height;
		frame.format = format;
		frame.pts = pts_usec;
		queue.push_back(std::move(frame));
	}
	last_pts = pts_usec;
	wake.notify_one();
	return true;
}

void VideoEncoder::run() {
	while (true) {
		Frame frame;
		{
			std::unique_lock<std::mutex> guard(lock);
			wake.wait(guard, [this] { return stopping || !queue.empty(); });
			if (queue.empty()) {
				return;
			}
			frame = std::move(queue.front());
			queue.pop_front();
		}
		if (failed) {
			continue;
		}
		// 8-bit frames keep their byte order (the backend takes either).
		const uint8_t *pixels = frame.data.ptr();
		bool bgra = frame.format == FORMAT_BGRA8;
		std::string message;
		bool ok = backend->encode(pixels, bgra, frame.pts, message);
		frame.data = PackedByteArray();
		if (ok) {
			encoded++;
		} else {
			fail(message);
		}
	}
}

void VideoEncoder::stop_worker() {
	{
		std::lock_guard<std::mutex> guard(lock);
		stopping = true;
	}
	wake.notify_one();
	if (worker.joinable()) {
		worker.join();
	}
}

bool VideoEncoder::finish() {
	if (!running) {
		return false;
	}
	stop_worker();
	running = false;
	std::string message;
	bool closed = backend->close(message);
	backend.reset();
	if (!closed) {
		fail(message);
	}
	if (encoded == 0) {
		fail(VIDEO_NO_FRAMES);
		return false;
	}
	// A fault mid-way (kept in get_last_error) still leaves the frames
	// before it in a file the backend could finish: keep that.
	return closed;
}

void VideoEncoder::fail(const std::string &message) {
	std::lock_guard<std::mutex> guard(lock);
	if (error.empty()) {
		error = message.empty() ? std::string("the video encoder failed") : message;
	}
	failed = true;
}

bool VideoEncoder::is_recording() const {
	return running;
}

int64_t VideoEncoder::get_encoded_frames() const {
	return encoded;
}

int64_t VideoEncoder::get_dropped_frames() const {
	return dropped;
}

String VideoEncoder::get_last_error() {
	std::lock_guard<std::mutex> guard(lock);
	return String::utf8(error.c_str());
}

int VideoEncoder::get_error_kind() const {
	return error_kind;
}

bool VideoEncoder::is_failed() const {
	return failed;
}

void VideoEncoder::_bind_methods() {
	ClassDB::bind_static_method("VideoEncoder", D_METHOD("is_supported"), &VideoEncoder::is_supported);
	ClassDB::bind_method(D_METHOD("start", "path", "width", "height", "fps", "bitrate"), &VideoEncoder::start);
	ClassDB::bind_method(D_METHOD("push_frame", "data", "width", "height", "pts_usec", "format"),
			&VideoEncoder::push_frame, DEFVAL(FORMAT_RGBA8));
	ClassDB::bind_method(D_METHOD("finish"), &VideoEncoder::finish);
	ClassDB::bind_method(D_METHOD("is_recording"), &VideoEncoder::is_recording);
	ClassDB::bind_method(D_METHOD("get_encoded_frames"), &VideoEncoder::get_encoded_frames);
	ClassDB::bind_method(D_METHOD("get_dropped_frames"), &VideoEncoder::get_dropped_frames);
	ClassDB::bind_method(D_METHOD("get_last_error"), &VideoEncoder::get_last_error);
	ClassDB::bind_method(D_METHOD("get_error_kind"), &VideoEncoder::get_error_kind);
	ClassDB::bind_method(D_METHOD("is_failed"), &VideoEncoder::is_failed);
}

#if !defined(__APPLE__) && !defined(__ANDROID__)
std::unique_ptr<VideoBackend> make_video_backend() {
	return nullptr;
}
#endif

} // namespace godot
