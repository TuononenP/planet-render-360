#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace godot {

// Why a recording couldn't start (VideoEncoder.get_error_kind): the file
// (worth retrying), no H.264 encoder at all, or none for this size.
enum VideoErrorKind {
	VIDEO_ERROR_FILE = 0,
	VIDEO_ERROR_NO_ENCODER = 1,
	VIDEO_ERROR_TOO_LARGE = 2,
};

// The reason finish() gives when no frame reached the encoder.
extern const char *const VIDEO_NO_FRAMES;

// One platform's H.264 MP4 writer, fed frames already at the output size
// as tightly packed 8-bit rows, RGBA or (`bgra`) BGRA: each backend takes
// either order as it copies, so no frame is reordered twice. Runs on the
// encoder's worker thread only.
class VideoBackend {
public:
	virtual ~VideoBackend() {}
	// false (with `error` set) when the platform cannot write this file;
	// `kind` (VideoErrorKind) says whether retrying can help.
	virtual bool open(const std::string &path, int width, int height, int fps, int bitrate,
			std::string &error, int &kind) = 0;
	virtual bool encode(const uint8_t *pixels, bool bgra, int64_t pts_usec, std::string &error) = 0;
	virtual bool close(std::string &error) = 0;
};

// The platform's backend, or null where there is none (video_encoder_*.cpp/.mm).
std::unique_ptr<VideoBackend> make_video_backend();

// The 360 view as an H.264 MP4 (VideoRecorder drives it). push_frame
// queues the frame (sharing the array's data, no copy) and returns at
// once; a worker thread hands it, already at the video's size (VideoScaler
// scales on the GPU), to the platform encoder (AVFoundation on macOS and iOS,
// MediaCodec on Android). A full queue drops the frame instead of
// blocking the game loop. finish() drains the queue and closes the file.
class VideoEncoder : public RefCounted {
	GDCLASS(VideoEncoder, RefCounted)

public:
	// Pixel layouts push_frame takes (VideoRecorder.FORMAT_*).
	enum Format {
		FORMAT_RGBA8 = 0,
		FORMAT_BGRA8 = 1,
	};

private:
	struct Frame {
		PackedByteArray data;
		int width = 0;
		int height = 0;
		int format = FORMAT_RGBA8;
		int64_t pts = 0;
	};

	std::unique_ptr<VideoBackend> backend;
	std::thread worker;
	std::mutex lock;
	std::condition_variable wake;
	std::deque<Frame> queue;
	bool stopping = false;
	bool running = false;
	int error_kind = VIDEO_ERROR_FILE;
	std::atomic<bool> failed{ false };
	std::atomic<int64_t> encoded{ 0 };
	int64_t dropped = 0;
	int64_t last_pts = -1;
	int out_w = 0;
	int out_h = 0;
	std::string error;

	void run();
	void fail(const std::string &message);
	void stop_worker();

protected:
	static void _bind_methods();

public:
	static constexpr int QUEUE_MAX = 4;

	~VideoEncoder();

	static bool is_supported();
	static int bytes_per_pixel(int format);
	bool start(const String &path, int width, int height, int fps, int bitrate);
	bool push_frame(const PackedByteArray &data, int width, int height, int64_t pts_usec, int format);
	bool finish();
	bool is_recording() const;
	int64_t get_encoded_frames() const;
	int64_t get_dropped_frames() const;
	String get_last_error();
	int get_error_kind() const;
	bool is_failed() const;
};

// `src` (sw x sh RGBA8) box-filtered to `dst` (dw x dh RGBA8).
void video_scale_rgba(const uint8_t *src, int sw, int sh, uint8_t *dst, int dw, int dh);

} // namespace godot
