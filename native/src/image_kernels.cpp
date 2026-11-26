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

Ref<Image> ImageKernels::hsy_canopy_compose(const Array &bands, const Ref<Image> &chm, int size) {
	constexpr int NBANDS = 4;
	constexpr uint8_t BAND_LO[NBANDS] = { 2, 10, 15, 20 };
	constexpr uint8_t BAND_HI[NBANDS] = { 10, 15, 20, 32 };
	constexpr uint8_t BAND_MID[NBANDS] = { 6, 12, 17, 24 };
	constexpr uint8_t NO_DATA = 255;
	if (size <= 0 || bands.size() != NBANDS) {
		return Ref<Image>();
	}
	PackedByteArray alpha_bufs[NBANDS];
	const uint8_t *alpha_ptrs[NBANDS] = {};
	for (int i = 0; i < NBANDS; ++i) {
		Ref<Image> b = bands[i];
		if (b.is_null() || b->get_width() != size || b->get_height() != size) {
			return Ref<Image>();
		}
		if (b->get_format() == Image::FORMAT_RGBA8) {
			alpha_bufs[i] = b->get_data();
		} else {
			Ref<Image> dup = b->duplicate();
			dup->convert(Image::FORMAT_RGBA8);
			alpha_bufs[i] = dup->get_data();
		}
		if (alpha_bufs[i].size() < (int64_t)size * size * 4) {
			return Ref<Image>();
		}
		alpha_ptrs[i] = alpha_bufs[i].ptr();
	}
	PackedByteArray refine_buf;
	const uint8_t *refine = nullptr;
	if (chm.is_valid() && chm->get_width() == size && chm->get_height() == size &&
			chm->get_format() == Image::FORMAT_L8) {
		refine_buf = chm->get_data();
		if (refine_buf.size() >= (int64_t)size * size) {
			refine = refine_buf.ptr();
		}
	}
	const int64_t total = (int64_t)size * size;
	PackedByteArray out;
	out.resize(total);
	uint8_t *op = out.ptrw();
	for (int64_t p = 0; p < total; ++p) {
		const int64_t aidx = p * 4 + 3;
		int band = -1;
		for (int i = NBANDS - 1; i >= 0; --i) {
			if (alpha_ptrs[i][aidx] > 127) {
				band = i;
				break;
			}
		}
		if (band < 0) {
			op[p] = 0;
			continue;
		}
		uint8_t h = BAND_MID[band];
		if (refine != nullptr) {
			const uint8_t r = refine[p];
			if (r != NO_DATA && r > 0) {
				h = std::clamp(r, BAND_LO[band], BAND_HI[band]);
			}
		}
		op[p] = h;
	}
	return Image::create_from_data(size, size, false, Image::FORMAT_L8, out);
}

Ref<Image> ImageKernels::r8_overlay(const Ref<Image> &base, const Ref<Image> &top, const Array &replace) {
	if (base.is_null() || top.is_null()) {
		return base;
	}
	const int w = base->get_width(), h = base->get_height();
	const int tw = top->get_width(), th = top->get_height();
	PackedByteArray out = base->get_data();
	const PackedByteArray src_buf = top->get_data();
	if (out.size() < (int64_t)w * h || src_buf.size() < (int64_t)tw * th) {
		return base;
	}
	uint8_t mask[256] = {};
	const int64_t rn = replace.size();
	for (int64_t i = 0; i < rn; ++i) {
		const int id = (int)replace[i];
		if (id >= 0 && id < 256) {
			mask[id] = 1;
		}
	}
	const bool any = (rn == 0);
	uint8_t *op = out.ptrw();
	const uint8_t *sp = src_buf.ptr();
	if (tw == w && th == h) {
		const int64_t total = (int64_t)w * h;
		for (int64_t i = 0; i < total; ++i) {
			const uint8_t v = sp[i];
			if (v != 0 && (any || mask[op[i]] == 1)) {
				op[i] = v;
			}
		}
	} else {
		for (int y = 0; y < h; ++y) {
			const int sy = std::min((int)(((double)y + 0.5) * (double)th / (double)h), th - 1) * tw;
			const int row = y * w;
			for (int x = 0; x < w; ++x) {
				const int sx = std::min((int)(((double)x + 0.5) * (double)tw / (double)w), tw - 1);
				const uint8_t v = sp[sy + sx];
				if (v != 0 && (any || mask[op[row + x]] == 1)) {
					op[row + x] = v;
				}
			}
		}
	}
	return Image::create_from_data(w, h, false, Image::FORMAT_R8, out);
}

PackedFloat32Array ImageKernels::terrarium_assemble(const Array &tiles, const Array &images,
		const Rect2i &rect, int tile_px) {
	const int w = rect.size.x;
	const int h = rect.size.y;
	PackedFloat32Array heights;
	if (w <= 0 || h <= 0) {
		return heights;
	}
	heights.resize((int64_t)w * h);
	float *hp = heights.ptrw();
	std::fill(hp, hp + (size_t)w * h, 0.0f);
	const int64_t n = std::min(tiles.size(), images.size());
	for (int64_t ti = 0; ti < n; ++ti) {
		const Vector2i t = tiles[ti];
		Ref<Image> img = images[ti];
		if (img.is_null() || img->is_empty()) {
			continue;
		}
		if (img->get_format() != Image::FORMAT_RGB8) {
			Ref<Image> dup = img->duplicate();
			dup->convert(Image::FORMAT_RGB8);
			img = dup;
		}
		const PackedByteArray bytes = img->get_data();
		const uint8_t *bp = bytes.ptr();
		const int tw = img->get_width();
		const Rect2i tile_rect(t.x * tile_px, t.y * tile_px, tile_px, tile_px);
		const Rect2i inter = tile_rect.intersection(rect);
		if (!inter.has_area()) {
			continue;
		}
		const int y0 = inter.position.y;
		const int y1 = inter.position.y + inter.size.y;
		const int x0 = inter.position.x;
		const int x1 = inter.position.x + inter.size.x;
		for (int gy = y0; gy < y1; ++gy) {
			const int row_src = (gy - tile_rect.position.y) * tw;
			const int row_dst = (gy - rect.position.y) * w - rect.position.x;
			for (int gx = x0; gx < x1; ++gx) {
				const int64_t idx = (int64_t)(row_src + gx - tile_rect.position.x) * 3;
				hp[row_dst + gx] = (float)bp[idx] * 256.0f + (float)bp[idx + 1] +
						(float)bp[idx + 2] / 256.0f - 32768.0f;
			}
		}
	}
	return heights;
}

void ImageKernels::_bind_methods() {
	ClassDB::bind_static_method("ImageKernels", D_METHOD("fix_alpha_edges", "image"), &ImageKernels::fix_alpha_edges);
	ClassDB::bind_static_method("ImageKernels", D_METHOD("hsy_canopy_compose", "bands", "chm", "size"),
			&ImageKernels::hsy_canopy_compose);
	ClassDB::bind_static_method("ImageKernels", D_METHOD("r8_overlay", "base", "top", "replace"),
			&ImageKernels::r8_overlay);
	ClassDB::bind_static_method("ImageKernels", D_METHOD("terrarium_assemble", "tiles", "images", "rect", "tile_px"),
			&ImageKernels::terrarium_assemble);
}

} // namespace godot
