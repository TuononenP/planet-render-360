#include "image_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <algorithm>
#include <array>
#include <vector>

namespace godot {
namespace {
constexpr int RADIUS = 4;
constexpr int THRESHOLD = 20;
constexpr int SIDE = RADIUS * 2 + 1;
struct Offset { int dy, dx; };
// The engine's scan visits rows then columns from the top-left of the
// window and keeps a texel only when strictly nearer: the winner is the
// nearest, the first in that order among equals.
std::array<Offset, SIDE * SIDE> nearest_first() {
	std::array<Offset, SIDE * SIDE> out;
	int n = 0;
	for (int dy = -RADIUS; dy <= RADIUS; ++dy) for (int dx = -RADIUS; dx <= RADIUS; ++dx) out[n++] = { dy, dx };
	std::stable_sort(out.begin(), out.end(), [](const Offset &a, const Offset &b) {
		return a.dy * a.dy + a.dx * a.dx < b.dy * b.dy + b.dx * b.dx;
	});
	return out;
}
} // namespace

void ImageKernels::fix_alpha_edges(const Ref<Image> &image) {
	if (image.is_null() || image->is_empty()) return;
	if (image->get_format() != Image::FORMAT_RGBA8) {
		image->fix_alpha_edges();
		return;
	}
	static const std::array<Offset, SIDE * SIDE> order = nearest_first();
	const int w = image->get_width(), h = image->get_height();
	PackedByteArray data = image->get_data();
	const PackedByteArray src = data.duplicate();
	const uint8_t *s = src.ptr();
	uint8_t *d = data.ptrw();
	// Solid texels per window, from a summed-area table.
	std::vector<int> sum((size_t)(w + 1) * (h + 1), 0);
	for (int y = 0; y < h; ++y) {
		int row = 0;
		for (int x = 0; x < w; ++x) {
			row += s[((size_t)y * w + x) * 4 + 3] >= THRESHOLD ? 1 : 0;
			sum[(size_t)(y + 1) * (w + 1) + x + 1] = sum[(size_t)y * (w + 1) + x + 1] + row;
		}
	}
	bool changed = false;
	for (int y = 0; y < h; ++y) {
		const int y0 = std::max(0, y - RADIUS), y1 = std::min(h - 1, y + RADIUS);
		for (int x = 0; x < w; ++x) {
			if (s[((size_t)y * w + x) * 4 + 3] >= THRESHOLD) continue;
			const int x0 = std::max(0, x - RADIUS), x1 = std::min(w - 1, x + RADIUS);
			const int solid = sum[(size_t)(y1 + 1) * (w + 1) + x1 + 1] - sum[(size_t)y0 * (w + 1) + x1 + 1]
					- sum[(size_t)(y1 + 1) * (w + 1) + x0] + sum[(size_t)y0 * (w + 1) + x0];
			if (solid == 0) continue;
			for (const Offset &o : order) {
				const int k = y + o.dy, l = x + o.dx;
				if (k < 0 || k >= h || l < 0 || l >= w) continue;
				const uint8_t *p = &s[((size_t)k * w + l) * 4];
				if (p[3] < THRESHOLD) continue;
				uint8_t *q = &d[((size_t)y * w + x) * 4];
				q[0] = p[0];
				q[1] = p[1];
				q[2] = p[2];
				changed = true;
				break;
			}
		}
	}
	if (changed) image->set_data(w, h, image->has_mipmaps(), Image::FORMAT_RGBA8, data);
}

void ImageKernels::_bind_methods() {
	ClassDB::bind_static_method("ImageKernels", D_METHOD("fix_alpha_edges", "image"), &ImageKernels::fix_alpha_edges);
}

} // namespace godot
