#include "video_decoder.h"

#include "video_encoder.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/char_string.hpp>

#include <algorithm>
#include <vector>

namespace godot {

VideoDecoder::~VideoDecoder() {
	close();
}

bool VideoDecoder::is_supported() {
	return make_video_decode_backend() != nullptr;
}

Dictionary VideoDecoder::thumbnail(const String &path, int max_side) {
	Dictionary out;
	std::unique_ptr<VideoDecodeBackend> b = make_video_decode_backend();
	if (!b || max_side <= 0) {
		return out;
	}
	int w = 0;
	int h = 0;
	int64_t dur = 0;
	std::string err;
	if (!b->open(std::string(path.utf8().get_data()), w, h, dur, err) || w <= 0 || h <= 0) {
		return out;
	}
	std::vector<uint8_t> rgba((size_t)w * h * 4);
	int64_t pts = 0;
	bool eof = false;
	if (!b->next(rgba.data(), pts, eof, err)) {
		return out;
	}
	double k = std::min(1.0, (double)max_side / std::max(w, h));
	int dw = std::max(1, (int)(w * k + 0.5));
	int dh = std::max(1, (int)(h * k + 0.5));
	PackedByteArray small;
	small.resize((int64_t)dw * dh * 4);
	video_scale_rgba(rgba.data(), w, h, small.ptrw(), dw, dh);
	out["width"] = dw;
	out["height"] = dh;
	out["data"] = small;
	out["duration_usec"] = dur;
	return out;
}

bool VideoDecoder::decode_one(Frame &out, bool &eof, std::string &err) {
	out.data.resize((int64_t)width * height * 4);
	int64_t pts = 0;
	if (!backend->next(out.data.ptrw(), pts, eof, err)) {
		return false;
	}
	out.pts = pts - origin;
	return true;
}

bool VideoDecoder::open(const String &path) {
	close();
	error.clear();
	backend = make_video_decode_backend();
	if (!backend) {
		error = "this device can't play videos";
		return false;
	}
	if (!backend->open(std::string(path.utf8().get_data()), width, height, duration, error)
			|| width <= 0 || height <= 0) {
		if (error.empty()) {
			error = "couldn't read the video";
		}
		backend.reset();
		return false;
	}
	// The first frame now: it sets the clock's zero and shows at once.
	Frame first;
	bool eof = false;
	origin = 0;
	if (!decode_one(first, eof, error)) {
		if (error.empty()) {
			error = "the video has no frames";
		}
		backend.reset();
		return false;
	}
	origin = first.pts;
	first.pts = 0;
	duration = std::max<int64_t>(0, duration - origin);
	{
		std::lock_guard<std::mutex> g(lock);
		queue.clear();
		queue.push_back(first);
		stopping = false;
		ended = false;
		failed = false;
		seek_to = -1;
		generation = 0;
		frame_pts = -1;
	}
	worker = std::thread(&VideoDecoder::run, this);
	return true;
}

void VideoDecoder::stop_worker() {
	{
		std::lock_guard<std::mutex> g(lock);
		stopping = true;
	}
	wake.notify_all();
	if (worker.joinable()) {
		worker.join();
	}
}

void VideoDecoder::close() {
	stop_worker();
	backend.reset();
	std::lock_guard<std::mutex> g(lock);
	queue.clear();
	stopping = false;
}

void VideoDecoder::run() {
	// Frames before a seek's target are held back one at a time: the last
	// of them is the frame on screen at the target itself.
	Frame held;
	bool holding = false;
	int64_t target = -1;
	uint64_t gen = 0;
	for (;;) {
		{
			std::unique_lock<std::mutex> g(lock);
			wake.wait(g, [&] {
				return stopping || seek_to >= 0 || (!ended && !failed && (int)queue.size() < QUEUE_MAX);
			});
			if (stopping) {
				return;
			}
			if (seek_to >= 0) {
				target = seek_to;
				seek_to = -1;
				gen = generation;
				holding = false;
				ended = false;
				failed = false;
				g.unlock();
				std::string err;
				if (!backend->seek(target + origin, err)) {
					std::lock_guard<std::mutex> g2(lock);
					if (gen == generation) {
						failed = true;
						error = err;
					}
				}
				continue;
			}
			gen = generation;
		}
		Frame f;
		bool eof = false;
		std::string err;
		bool ok = decode_one(f, eof, err);
		std::lock_guard<std::mutex> g(lock);
		if (gen != generation) {
			continue; // A seek came in meanwhile: this frame is from before it.
		}
		if (!ok) {
			if (holding) {
				queue.push_back(held);
				holding = false;
			}
			if (eof) {
				ended = true;
			} else {
				failed = true;
				error = err;
			}
			continue;
		}
		if (target >= 0 && f.pts < target) {
			held = f;
			holding = true;
			continue;
		}
		if (holding) {
			queue.push_back(held);
			holding = false;
		}
		target = -1;
		queue.push_back(f);
	}
}

void VideoDecoder::seek(int64_t usec) {
	if (!backend) {
		return;
	}
	{
		std::lock_guard<std::mutex> g(lock);
		seek_to = std::max<int64_t>(0, std::min(usec, duration));
		generation++;
		queue.clear();
		frame_pts = -1;
		ended = false;
	}
	wake.notify_all();
}

PackedByteArray VideoDecoder::poll(int64_t usec) {
	PackedByteArray out;
	bool popped = false;
	{
		std::lock_guard<std::mutex> g(lock);
		while (!queue.empty() && queue.front().pts <= usec) {
			out = queue.front().data;
			frame_pts = queue.front().pts;
			queue.pop_front();
			popped = true;
		}
	}
	if (popped) {
		wake.notify_all();
	}
	return out;
}

int64_t VideoDecoder::get_frame_pts() const {
	return frame_pts;
}

bool VideoDecoder::is_ended() {
	std::lock_guard<std::mutex> g(lock);
	return ended && queue.empty() && seek_to < 0;
}

bool VideoDecoder::is_failed() {
	std::lock_guard<std::mutex> g(lock);
	return failed;
}

int VideoDecoder::get_width() const {
	return width;
}

int VideoDecoder::get_height() const {
	return height;
}

int64_t VideoDecoder::get_duration_usec() const {
	return duration;
}

String VideoDecoder::get_last_error() {
	std::lock_guard<std::mutex> g(lock);
	return String::utf8(error.c_str());
}

void VideoDecoder::_bind_methods() {
	ClassDB::bind_static_method("VideoDecoder", D_METHOD("is_supported"), &VideoDecoder::is_supported);
	ClassDB::bind_static_method("VideoDecoder", D_METHOD("thumbnail", "path", "max_side"), &VideoDecoder::thumbnail);
	ClassDB::bind_method(D_METHOD("open", "path"), &VideoDecoder::open);
	ClassDB::bind_method(D_METHOD("close"), &VideoDecoder::close);
	ClassDB::bind_method(D_METHOD("seek", "usec"), &VideoDecoder::seek);
	ClassDB::bind_method(D_METHOD("poll", "usec"), &VideoDecoder::poll);
	ClassDB::bind_method(D_METHOD("get_frame_pts"), &VideoDecoder::get_frame_pts);
	ClassDB::bind_method(D_METHOD("is_ended"), &VideoDecoder::is_ended);
	ClassDB::bind_method(D_METHOD("is_failed"), &VideoDecoder::is_failed);
	ClassDB::bind_method(D_METHOD("get_width"), &VideoDecoder::get_width);
	ClassDB::bind_method(D_METHOD("get_height"), &VideoDecoder::get_height);
	ClassDB::bind_method(D_METHOD("get_duration_usec"), &VideoDecoder::get_duration_usec);
	ClassDB::bind_method(D_METHOD("get_last_error"), &VideoDecoder::get_last_error);
}

#if !defined(__APPLE__) && !defined(__ANDROID__)
std::unique_ptr<VideoDecodeBackend> make_video_decode_backend() {
	return nullptr;
}
#endif

} // namespace godot
