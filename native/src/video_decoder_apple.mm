// VideoDecoder's backend on macOS and iOS: AVAssetReader decoding the
// video track to BGRA pixel buffers, copied out as RGBA. Compiled with ARC.

#include "video_decoder.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>

#include <cstring>

namespace godot {

namespace {

std::string describe(NSError *err, const char *fallback) {
	if (err == nil) {
		return fallback;
	}
	return std::string(fallback) + ": " + std::string(err.localizedDescription.UTF8String ?: "");
}

class AppleVideoDecodeBackend : public VideoDecodeBackend {
	AVURLAsset *asset = nil;
	AVAssetTrack *track = nil;
	AVAssetReader *reader = nil;
	AVAssetReaderTrackOutput *output = nil;
	int width = 0;
	int height = 0;

	static std::string reason(NSException *e) {
		return std::string("the video reader failed: ") + std::string(e.reason.UTF8String ?: "");
	}

	bool start_reader(CMTime from, std::string &error) {
		NSError *err = nil;
		reader = [[AVAssetReader alloc] initWithAsset:asset error:&err];
		if (reader == nil) {
			error = describe(err, "couldn't read the video");
			return false;
		}
		NSDictionary *settings = @{
			(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
		};
		output = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:settings];
		output.alwaysCopiesSampleData = NO;
		if (![reader canAddOutput:output]) {
			error = "couldn't read the video track";
			reader = nil;
			return false;
		}
		[reader addOutput:output];
		reader.timeRange = CMTimeRangeMake(from, kCMTimePositiveInfinity);
		if (![reader startReading]) {
			error = describe(reader.error, "couldn't start reading the video");
			reader = nil;
			return false;
		}
		return true;
	}

public:
	~AppleVideoDecodeBackend() override {
		if (reader != nil && reader.status == AVAssetReaderStatusReading) {
			[reader cancelReading];
		}
	}

	bool open(const std::string &path, int &w, int &h, int64_t &duration_usec, std::string &error) override {
		@try {
			@autoreleasepool {
				NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path.c_str()]];
				asset = [AVURLAsset URLAssetWithURL:url
											options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES }];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				// The synchronous forms: this runs on a worker (or the
				// thumbnail task), never on the main thread.
				track = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
				CMTime dur = asset.duration;
#pragma clang diagnostic pop
				if (track == nil) {
					error = "the file has no video";
					return false;
				}
				CGSize size = track.naturalSize;
				width = w = (int)size.width;
				height = h = (int)size.height;
				duration_usec = CMTIME_IS_NUMERIC(dur) ? (int64_t)(CMTimeGetSeconds(dur) * 1e6) : 0;
				return start_reader(kCMTimeZero, error);
			}
		} @catch (NSException *e) {
			error = reason(e);
			reader = nil;
			return false;
		}
	}

	bool seek(int64_t usec, std::string &error) override {
		@try {
			@autoreleasepool {
				if (reader != nil && reader.status == AVAssetReaderStatusReading) {
					[reader cancelReading];
				}
				reader = nil;
				output = nil;
				return start_reader(CMTimeMake(usec, 1000000), error);
			}
		} @catch (NSException *e) {
			error = reason(e);
			reader = nil;
			return false;
		}
	}

	bool next(uint8_t *rgba, int64_t &pts_usec, bool &eof, std::string &error) override {
		@try {
			return next_body(rgba, pts_usec, eof, error);
		} @catch (NSException *e) {
			error = reason(e);
			return false;
		}
	}

private:
	bool next_body(uint8_t *rgba, int64_t &pts_usec, bool &eof, std::string &error) {
		eof = false;
		if (reader == nil) {
			error = "the video reader isn't open";
			return false;
		}
		for (;;) {
			@autoreleasepool {
				CMSampleBufferRef sample = [output copyNextSampleBuffer];
				if (sample == nullptr) {
					if (reader.status == AVAssetReaderStatusCompleted) {
						eof = true;
					} else {
						error = describe(reader.error, "couldn't read a frame");
					}
					return false;
				}
				CVImageBufferRef image = CMSampleBufferGetImageBuffer(sample);
				if (image == nullptr) {
					CFRelease(sample);
					continue; // No picture in this sample.
				}
				CMTime when = CMSampleBufferGetPresentationTimeStamp(sample);
				pts_usec = (int64_t)(CMTimeGetSeconds(when) * 1e6 + 0.5);
				CVPixelBufferLockBaseAddress(image, kCVPixelBufferLock_ReadOnly);
				const uint8_t *base = (const uint8_t *)CVPixelBufferGetBaseAddress(image);
				size_t stride = CVPixelBufferGetBytesPerRow(image);
				int bw = (int)CVPixelBufferGetWidth(image);
				int bh = (int)CVPixelBufferGetHeight(image);
				int cw = bw < width ? bw : width;
				int ch = bh < height ? bh : height;
				if (cw < width || ch < height) {
					std::memset(rgba, 0, (size_t)width * height * 4);
				}
				for (int y = 0; y < ch; y++) {
					const uint8_t *s = base + (size_t)y * stride;
					uint8_t *d = rgba + (size_t)y * width * 4;
					for (int x = 0; x < cw; x++, s += 4, d += 4) {
						d[0] = s[2];
						d[1] = s[1];
						d[2] = s[0];
						d[3] = 255;
					}
				}
				CVPixelBufferUnlockBaseAddress(image, kCVPixelBufferLock_ReadOnly);
				CFRelease(sample);
				return true;
			}
		}
	}
};

} // namespace

std::unique_ptr<VideoDecodeBackend> make_video_decode_backend() {
	return std::unique_ptr<VideoDecodeBackend>(new AppleVideoDecodeBackend());
}

} // namespace godot
