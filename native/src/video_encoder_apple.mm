// VideoEncoder's backend on macOS and iOS: AVAssetWriter writing H.264
// into an MP4, fed BGRA pixel buffers (VideoToolbox converts to YUV).
// Compiled with ARC.

#include "video_encoder.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>

#include <chrono>
#include <cstring>
#include <thread>

namespace godot {

namespace {

constexpr int READY_WAIT_MS = 2000;

std::string describe(NSError *err, const char *fallback) {
	if (err == nil) {
		return fallback;
	}
	return std::string(fallback) + ": " + std::string(err.localizedDescription.UTF8String ?: "");
}

class AppleVideoBackend : public VideoBackend {
	AVAssetWriter *writer = nil;
	AVAssetWriterInput *input = nil;
	AVAssetWriterInputPixelBufferAdaptor *adaptor = nil;
	int width = 0;
	int height = 0;
	bool started = false;

	static std::string reason(NSException *e) {
		return std::string("the video writer failed: ") + std::string(e.reason.UTF8String ?: "");
	}

public:
	// AVFoundation reports misuse with exceptions; one escaping the
	// encoder's thread would end the app, so each call turns it into an error.
	bool open(const std::string &path, int w, int h, int fps, int bitrate, std::string &error,
			int &kind) override {
		@try {
			return open_body(path, w, h, fps, bitrate, error, kind);
		} @catch (NSException *e) {
			error = reason(e);
			writer = nil;
			return false;
		}
	}

	bool encode(const uint8_t *pixels, bool bgra, int64_t pts_usec, std::string &error) override {
		@try {
			return encode_body(pixels, bgra, pts_usec, error);
		} @catch (NSException *e) {
			error = reason(e);
			return false;
		}
	}

	bool close(std::string &error) override {
		@try {
			return close_body(error);
		} @catch (NSException *e) {
			error = reason(e);
			writer = nil;
			input = nil;
			adaptor = nil;
			return false;
		}
	}

private:
	bool open_body(const std::string &path, int w, int h, int fps, int bitrate, std::string &error,
			int &kind) {
		@autoreleasepool {
			width = w;
			height = h;
			NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path.c_str()]];
			[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
			NSError *err = nil;
			writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeMPEG4 error:&err];
			if (writer == nil) {
				error = describe(err, "couldn't create the video file");
				return false;
			}
			NSDictionary *compression = @{
				AVVideoAverageBitRateKey : @(bitrate),
				AVVideoMaxKeyFrameIntervalKey : @(fps * 2),
				AVVideoExpectedSourceFrameRateKey : @(fps),
				AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
			};
			NSDictionary *settings = @{
				AVVideoCodecKey : AVVideoCodecTypeH264,
				AVVideoWidthKey : @(w),
				AVVideoHeightKey : @(h),
				AVVideoCompressionPropertiesKey : compression,
				AVVideoColorPropertiesKey : @{
					AVVideoColorPrimariesKey : AVVideoColorPrimaries_ITU_R_709_2,
					AVVideoTransferFunctionKey : AVVideoTransferFunction_ITU_R_709_2,
					AVVideoYCbCrMatrixKey : AVVideoYCbCrMatrix_ITU_R_709_2,
				},
			};
			if (![writer canApplyOutputSettings:settings forMediaType:AVMediaTypeVideo]) {
				error = "this device can't encode H.264 at that size";
				kind = VIDEO_ERROR_TOO_LARGE;
				writer = nil;
				return false;
			}
			input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:settings];
			input.expectsMediaDataInRealTime = YES;
			NSDictionary *attrs = @{
				(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
				(NSString *)kCVPixelBufferWidthKey : @(w),
				(NSString *)kCVPixelBufferHeightKey : @(h),
			};
			adaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:input
																 sourcePixelBufferAttributes:attrs];
			if (![writer canAddInput:input]) {
				error = "couldn't add the video track";
				writer = nil;
				return false;
			}
			[writer addInput:input];
			if (![writer startWriting]) {
				error = describe(writer.error, "couldn't start writing the video");
				writer = nil;
				return false;
			}
			started = false;
			return true;
		}
	}

	bool encode_body(const uint8_t *pixels, bool bgra, int64_t pts_usec, std::string &error) {
		@autoreleasepool {
			CMTime when = CMTimeMake(pts_usec, 1000000);
			if (writer.status != AVAssetWriterStatusWriting) {
				error = describe(writer.error, "the video writer stopped");
				return false;
			}
			if (!started) {
				[writer startSessionAtSourceTime:when];
				started = true;
			}
			auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(READY_WAIT_MS);
			while (!input.readyForMoreMediaData) {
				if (writer.status != AVAssetWriterStatusWriting) {
					error = describe(writer.error, "the video writer stopped");
					return false;
				}
				if (std::chrono::steady_clock::now() > deadline) {
					error = "the video encoder stopped accepting frames";
					return false;
				}
				std::this_thread::sleep_for(std::chrono::milliseconds(2));
			}
			CVPixelBufferRef buffer = nullptr;
			CVPixelBufferPoolRef pool = adaptor.pixelBufferPool;
			if (pool == nullptr || CVPixelBufferPoolCreatePixelBuffer(nullptr, pool, &buffer) != kCVReturnSuccess) {
				error = describe(writer.error, "couldn't get a video frame buffer");
				return false;
			}
			CVPixelBufferLockBaseAddress(buffer, 0);
			uint8_t *base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
			size_t stride = CVPixelBufferGetBytesPerRow(buffer);
			for (int y = 0; y < height; y++) {
				const uint8_t *s = pixels + (size_t)y * width * 4;
				uint8_t *d = base + (size_t)y * stride;
				if (bgra) {
					// The pixel buffer's own order: rows copy as they are.
					std::memcpy(d, s, (size_t)width * 4);
					continue;
				}
				for (int x = 0; x < width; x++, s += 4, d += 4) {
					d[0] = s[2];
					d[1] = s[1];
					d[2] = s[0];
					d[3] = 255;
				}
			}
			CVPixelBufferUnlockBaseAddress(buffer, 0);
			BOOL ok = [adaptor appendPixelBuffer:buffer withPresentationTime:when];
			CVPixelBufferRelease(buffer);
			if (!ok) {
				error = describe(writer.error, "couldn't add a frame to the video");
				return false;
			}
			return true;
		}
	}

	bool close_body(std::string &error) {
		@autoreleasepool {
			if (writer == nil) {
				return false;
			}
			if (!started) {
				if (writer.status == AVAssetWriterStatusWriting) {
					[writer cancelWriting];
				}
				writer = nil;
				error = VIDEO_NO_FRAMES;
				return false;
			}
			if (writer.status != AVAssetWriterStatusWriting) {
				// A writer that already failed throws if asked to finish.
				error = describe(writer.error, "couldn't finish the video file");
				if (writer.status != AVAssetWriterStatusFailed) {
					[writer cancelWriting];
				}
				writer = nil;
				input = nil;
				adaptor = nil;
				return false;
			}
			[input markAsFinished];
			dispatch_semaphore_t done = dispatch_semaphore_create(0);
			[writer finishWritingWithCompletionHandler:^{
				dispatch_semaphore_signal(done);
			}];
			dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
			bool ok = writer.status == AVAssetWriterStatusCompleted;
			if (!ok) {
				error = describe(writer.error, "couldn't finish the video file");
			}
			writer = nil;
			input = nil;
			adaptor = nil;
			return ok;
		}
	}
};

} // namespace

std::unique_ptr<VideoBackend> make_video_backend() {
	return std::unique_ptr<VideoBackend>(new AppleVideoBackend());
}

} // namespace godot
