#include "vegetation_mask_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

#include <algorithm>
#include <cmath>
#include <limits>

namespace godot {

void VegetationMaskNative::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "n", "half", "cell", "block", "nb", "bucket"), &VegetationMaskNative::setup);
	ClassDB::bind_method(D_METHOD("fill_rings", "rings", "bit", "cov", "count_built"), &VegetationMaskNative::fill_rings);
	ClassDB::bind_method(D_METHOD("add_segment", "a", "b", "core", "edge", "paved", "sides"), &VegetationMaskNative::add_segment);
	ClassDB::bind_method(D_METHOD("add_polyline", "pts", "core", "edge", "paved", "sides"), &VegetationMaskNative::add_polyline);
	ClassDB::bind_method(D_METHOD("mark_trees", "positions"), &VegetationMaskNative::mark_trees);
	ClassDB::bind_method(D_METHOD("blocked", "x", "z", "mask", "margin_m", "m2u"), &VegetationMaskNative::blocked);
	ClassDB::bind_method(D_METHOD("cover_at", "x", "z"), &VegetationMaskNative::cover_at);
	ClassDB::bind_method(D_METHOD("cover_at_cell", "cx", "cz"), &VegetationMaskNative::cover_at_cell);
	ClassDB::bind_method(D_METHOD("built_fraction", "x", "z"), &VegetationMaskNative::built_fraction);
}

void VegetationMaskNative::setup(int p_n, float p_half, float p_cell, int p_block, int p_nb, float p_bucket) {
	n = std::max(p_n, 1);
	half = p_half;
	cell = p_cell;
	block = std::max(p_block, 1);
	nb = std::max(p_nb, 1);
	bucket = p_bucket;
	bits.assign(static_cast<size_t>(n) * static_cast<size_t>(n), 0);
	cover.assign(static_cast<size_t>(n) * static_cast<size_t>(n), 0);
	built_blocks.assign(static_cast<size_t>(nb) * static_cast<size_t>(nb), 0);
	segs.clear();
	buckets.clear();
}

int VegetationMaskNative::fill_rings(const Array &rings, int bit, int cov, bool count_built) {
	if (rings.is_empty()) {
		return 0;
	}
	PackedVector2Array outer = rings[0];
	const int outer_n = outer.size();
	if (outer_n < 3) {
		return 0;
	}
	const Vector2 *optr = outer.ptr();
	float minz = std::numeric_limits<float>::infinity();
	float maxz = -std::numeric_limits<float>::infinity();
	for (int i = 0; i < outer_n; ++i) {
		if (optr[i].y < minz) minz = optr[i].y;
		if (optr[i].y > maxz) maxz = optr[i].y;
	}
	const int r0 = std::max(static_cast<int>(std::ceil((minz + half) / cell - 0.5f)), 0);
	const int r1 = std::min(static_cast<int>(std::floor((maxz + half) / cell - 0.5f)), n - 1);
	if (r1 < r0) {
		return 0;
	}
	const int row_count = r1 - r0 + 1;
	std::vector<std::vector<float>> rows(static_cast<size_t>(row_count));
	const int ring_count = rings.size();
	for (int ri_idx = 0; ri_idx < ring_count; ++ri_idx) {
		PackedVector2Array pts = rings[ri_idx];
		const int m = pts.size();
		if (m < 2) {
			continue;
		}
		const Vector2 *ptr = pts.ptr();
		for (int i = 0; i < m; ++i) {
			const Vector2 a = ptr[i];
			const Vector2 b = ptr[(i + 1) % m];
			if (Math::is_equal_approx(a.y, b.y)) {
				continue;
			}
			const float lo = std::min(a.y, b.y);
			const float hi = std::max(a.y, b.y);
			const int ra = std::max(static_cast<int>(std::ceil((lo + half) / cell - 0.5f)), r0);
			const int rb = std::min(static_cast<int>(std::floor((hi + half) / cell - 0.5f)), r1);
			const float dx = b.x - a.x;
			const float dy = b.y - a.y;
			for (int r = ra; r <= rb; ++r) {
				const float zc = (static_cast<float>(r) + 0.5f) * cell - half;
				if ((a.y > zc) != (b.y > zc)) {
					rows[static_cast<size_t>(r - r0)].push_back(a.x + (zc - a.y) * dx / dy);
				}
			}
		}
	}
	int count = 0;
	const uint8_t ubit = static_cast<uint8_t>(bit);
	for (int ri = 0; ri < row_count; ++ri) {
		auto &xs = rows[static_cast<size_t>(ri)];
		if (xs.size() < 2) {
			continue;
		}
		std::sort(xs.begin(), xs.end());
		const int base = (r0 + ri) * n;
		const int brow = ((r0 + ri) / block) * nb;
		for (size_t k = 0; k + 1 < xs.size(); k += 2) {
			const int c0 = std::max(static_cast<int>(std::ceil((xs[k] + half) / cell - 0.5f)), 0);
			const int c1 = std::min(static_cast<int>(std::floor((xs[k + 1] + half) / cell - 0.5f)), n - 1);
			if (c1 < c0) {
				continue;
			}
			if (count_built) {
				for (int c = c0; c <= c1; ++c) {
					built_blocks[static_cast<size_t>(brow + c / block)] += 1;
				}
			}
			if (ubit != 0 && cov != 0) {
				for (int c = c0; c <= c1; ++c) {
					bits[static_cast<size_t>(base + c)] |= ubit;
					cover[static_cast<size_t>(base + c)] = cov;
				}
			} else if (ubit != 0) {
				for (int c = c0; c <= c1; ++c) {
					bits[static_cast<size_t>(base + c)] |= ubit;
				}
			} else if (cov != 0) {
				for (int c = c0; c <= c1; ++c) {
					cover[static_cast<size_t>(base + c)] = cov;
				}
			}
			count += (c1 - c0 + 1);
		}
	}
	return count;
}

void VegetationMaskNative::add_segment(const Vector2 &a, const Vector2 &b, float core, float edge, float paved, int sides) {
	const float reach = std::max(edge, paved);
	const float lim = half + reach;
	if ((std::fabs(a.x) > lim && std::fabs(b.x) > lim && ((a.x > 0.0f) == (b.x > 0.0f))) ||
			(std::fabs(a.y) > lim && std::fabs(b.y) > lim && ((a.y > 0.0f) == (b.y > 0.0f)))) {
		return;
	}
	const int si = static_cast<int>(segs.size());
	segs.push_back({a, b, core, edge, paved, static_cast<uint8_t>(sides)});
	const int bx0 = static_cast<int>(std::floor((std::min(a.x, b.x) - reach) / bucket));
	const int bx1 = static_cast<int>(std::floor((std::max(a.x, b.x) + reach) / bucket));
	const int bz0 = static_cast<int>(std::floor((std::min(a.y, b.y) - reach) / bucket));
	const int bz1 = static_cast<int>(std::floor((std::max(a.y, b.y) + reach) / bucket));
	for (int bz = bz0; bz <= bz1; ++bz) {
		for (int bx = bx0; bx <= bx1; ++bx) {
			buckets[bucket_key(bx, bz)].push_back(si);
		}
	}
}

void VegetationMaskNative::add_polyline(const PackedVector2Array &pts, float core, float edge, float paved, int sides) {
	const int count = pts.size();
	if (count < 2) {
		return;
	}
	const Vector2 *ptr = pts.ptr();
	for (int i = 0; i < count - 1; ++i) {
		add_segment(ptr[i], ptr[i + 1], core, edge, paved, sides);
	}
}

void VegetationMaskNative::mark_trees(const Array &positions) {
	const int count = positions.size();
	for (int i = 0; i < count; ++i) {
		const Vector3 p = positions[i];
		const int cx = static_cast<int>(std::floor((p.x + half) / cell));
		const int cz = static_cast<int>(std::floor((p.z + half) / cell));
		if (cx >= 0 && cz >= 0 && cx < n && cz < n) {
			bits[static_cast<size_t>(cz * n + cx)] |= 16;
		}
	}
}

bool VegetationMaskNative::near_road(float x, float z, bool want_core, float margin) const {
	const int bx = static_cast<int>(std::floor(x / bucket));
	const int bz = static_cast<int>(std::floor(z / bucket));
	auto it = buckets.find(bucket_key(bx, bz));
	if (it == buckets.end()) {
		return false;
	}
	const Vector2 p(x, z);
	for (int si : it->second) {
		const Segment &s = segs[static_cast<size_t>(si)];
		float lim = want_core ? s.core : s.edge;
		if (lim < 0.0f) {
			continue;
		}
		lim += margin;
		const Vector2 ab = s.b - s.a;
		const float len2 = std::max(ab.length_squared(), 1e-6f);
		const float t = Math::clamp((p - s.a).dot(ab) / len2, 0.0f, 1.0f);
		if ((s.a + ab * t).distance_squared_to(p) <= lim * lim) {
			return true;
		}
	}
	return false;
}

bool VegetationMaskNative::near_paved(float x, float z, float margin) const {
	const int bx = static_cast<int>(std::floor(x / bucket));
	const int bz = static_cast<int>(std::floor(z / bucket));
	auto it = buckets.find(bucket_key(bx, bz));
	if (it == buckets.end()) {
		return false;
	}
	const Vector2 p(x, z);
	for (int si : it->second) {
		const Segment &s = segs[static_cast<size_t>(si)];
		float lim = s.paved;
		if (lim < 0.0f) {
			continue;
		}
		lim += margin;
		const Vector2 ab = s.b - s.a;
		const float len2 = std::max(ab.length_squared(), 1e-6f);
		const float t = Math::clamp((p - s.a).dot(ab) / len2, 0.0f, 1.0f);
		if ((s.a + ab * t).distance_squared_to(p) > lim * lim) {
			continue;
		}
		const bool left = ab.y * (p.x - s.a.x) - ab.x * (p.y - s.a.y) > 0.0f;
		if ((s.sides & (left ? 1 : 2)) != 0) {
			return true;
		}
	}
	return false;
}

bool VegetationMaskNative::blocked(float x, float z, int mask, float margin_m, float m2u) const {
	const int r = static_cast<int>(std::ceil(margin_m * m2u / cell));
	const int cx = static_cast<int>(std::floor((x + half) / cell));
	const int cz = static_cast<int>(std::floor((z + half) / cell));
	if (cx < 0 || cz < 0 || cx >= n || cz >= n) {
		return true;
	}
	const float m = static_cast<float>(r) * cell;
	if ((mask & 2) && near_road(x, z, true, m)) {
		return true;
	}
	if ((mask & 8) && near_road(x, z, false, m)) {
		return true;
	}
	if ((mask & 32) && near_paved(x, z, m)) {
		return true;
	}
	const uint8_t umask = static_cast<uint8_t>(mask) & (1 | 4 | 8 | 16);
	if (umask != 0) {
		const int z0 = std::max(cz - r, 0);
		const int z1 = std::min(cz + r, n - 1);
		const int x0 = std::max(cx - r, 0);
		const int x1 = std::min(cx + r, n - 1);
		for (int zz = z0; zz <= z1; ++zz) {
			const int row = zz * n;
			for (int xx = x0; xx <= x1; ++xx) {
				if ((bits[static_cast<size_t>(row + xx)] & umask) != 0) {
					return true;
				}
			}
		}
	}
	return false;
}

int VegetationMaskNative::cover_at(float x, float z) const {
	const int cx = static_cast<int>(std::floor((x + half) / cell));
	const int cz = static_cast<int>(std::floor((z + half) / cell));
	if (cx < 0 || cz < 0 || cx >= n || cz >= n) {
		return -1;
	}
	return cover[static_cast<size_t>(cz * n + cx)] - 1;
}

int VegetationMaskNative::cover_at_cell(int cx, int cz) const {
	if (cx < 0 || cz < 0 || cx >= n || cz >= n) {
		return -1;
	}
	return cover[static_cast<size_t>(cz * n + cx)] - 1;
}

float VegetationMaskNative::built_fraction(float x, float z) const {
	const int bx = Math::clamp(static_cast<int>(std::floor((x + half) / cell)) / block, 0, nb - 1);
	const int bz = Math::clamp(static_cast<int>(std::floor((z + half) / cell)) / block, 0, nb - 1);
	int total = 0;
	int cells = 0;
	const int b2 = block * block;
	for (int dz = -1; dz <= 1; ++dz) {
		const int zz = bz + dz;
		if (zz < 0 || zz >= nb) {
			continue;
		}
		for (int dx = -1; dx <= 1; ++dx) {
			const int xx = bx + dx;
			if (xx < 0 || xx >= nb) {
				continue;
			}
			total += built_blocks[static_cast<size_t>(zz * nb + xx)];
			cells += b2;
		}
	}
	return static_cast<float>(total) / static_cast<float>(std::max(cells, 1));
}

} // namespace godot
