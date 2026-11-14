#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include <condition_variable>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

namespace godot {

// One platform's H.264 MP4 reader, giving frames as tightly packed RGBA8
// rows at the video's size. Runs on one thread at a time.
class VideoDecodeBackend {
public:
	virtual ~VideoDecodeBackend() {}
	// false (with `error` set) when the platform cannot read this file.
	virtual bool open(const std::string &path, int &width, int &height, int64_t &duration_usec,
			std::string &error) = 0;
	// Restarts reading at the key frame at or before `usec`; frames before
	// `usec` still come out (the caller drops them).
	virtual bool seek(int64_t usec, std::string &error) = 0;
	// The next frame into `rgba` (width * height * 4 bytes). false with
	// `eof` set at the end of the video, else with `error` set.
	virtual bool next(uint8_t *rgba, int64_t &pts_usec, bool &eof, std::string &error) = 0;
};

// The platform's backend, or null where there is none (video_decoder_*.cpp/.mm).
std::unique_ptr<VideoDecodeBackend> make_video_decode_backend();

// Plays back a recorded MP4 (MediaViewer drives it). open() reads the
// first frame at once; a worker thread then decodes ahead into a short
// queue, and poll(time) hands over the newest frame due by then, so the
// game loop only copies a finished frame into a texture. Times are from
// the first frame (0) and seek() is exact: decoding resumes at the key
// frame before the target and the frames before it are dropped.
class VideoDecoder : public RefCounted {
	GDCLASS(VideoDecoder, RefCounted)

	struct Frame {
		PackedByteArray data;
		int64_t pts = 0;
	};

	std::unique_ptr<VideoDecodeBackend> backend;
	std::thread worker;
	std::mutex lock;
	std::condition_variable wake;
	std::deque<Frame> queue;
	bool stopping = false;
	bool ended = false;
	bool failed = false;
	// A seek waiting for the worker (-1 none), and the count of seeks so a
	// frame decoded before one is never queued after it.
	int64_t seek_to = -1;
	uint64_t generation = 0;
	int width = 0;
	int height = 0;
	int64_t duration = 0;
	// The first frame's own time: subtracted so playback starts at 0.
	int64_t origin = 0;
	int64_t frame_pts = -1;
	std::string error;

	void run();
	void stop_worker();
	bool decode_one(Frame &out, bool &eof, std::string &err);

protected:
	static void _bind_methods();

public:
	static constexpr int QUEUE_MAX = 3;

	~VideoDecoder();

	static bool is_supported();
	// The first frame scaled to fit `max_side`, for a Gallery card:
	// {width, height, data (RGBA8), duration_usec}, or {} when it can't.
	static Dictionary thumbnail(const String &path, int max_side);
	bool open(const String &path);
	void close();
	void seek(int64_t usec);
	// The newest decoded frame due at `usec` (RGBA8 at get_width x
	// get_height), or empty when none is newer than the last one handed over.
	PackedByteArray poll(int64_t usec);
	int64_t get_frame_pts() const;
	bool is_ended();
	bool is_failed();
	int get_width() const;
	int get_height() const;
	int64_t get_duration_usec() const;
	String get_last_error();
};

} // namespace godot
