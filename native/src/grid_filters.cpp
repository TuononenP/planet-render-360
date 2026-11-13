#include "grid_filters.h"

#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>
#include <vector>

namespace godot {

PackedFloat32Array GridFilters::rank_filter(const PackedFloat32Array &src, int size, int r, bool lowest) {
	const int64_t count = (int64_t)size * size;
	PackedFloat32Array out;
	if (size <= 0 || src.size() < count) return out;
	std::vector<float> tmp((size_t)count);
	const float *s = src.ptr();
	// minf / maxf: a < b ? a : b and a > b ? a : b, on the float values.
	const auto pick = [lowest](double v, double w) { return lowest ? (v < w ? v : w) : (v > w ? v : w); };
	for (int z = 0; z < size; ++z) {
		const int64_t base = (int64_t)z * size;
		for (int x = 0; x < size; ++x) {
			double v = s[base + x];
			for (int dx = std::max(x - r, 0); dx <= std::min(x + r, size - 1); ++dx) v = pick(v, s[base + dx]);
			tmp[base + x] = (float)v;
		}
	}
	out.resize(count);
	float *o = out.ptrw();
	for (int z = 0; z < size; ++z) {
		for (int x = 0; x < size; ++x) {
			double v = tmp[(int64_t)z * size + x];
			for (int dz = std::max(z - r, 0); dz <= std::min(z + r, size - 1); ++dz) v = pick(v, tmp[(int64_t)dz * size + x]);
			o[(int64_t)z * size + x] = (float)v;
		}
	}
	return out;
}

PackedByteArray GridFilters::dilate(const PackedByteArray &src, int size, int r) {
	const int64_t count = (int64_t)size * size;
	PackedByteArray out;
	if (size <= 0 || src.size() < count) return out;
	std::vector<uint8_t> row((size_t)count, 0);
	const uint8_t *s = src.ptr();
	for (int z = 0; z < size; ++z) {
		const int64_t base = (int64_t)z * size;
		for (int x = 0; x < size; ++x) {
			if (s[base + x] == 0) continue;
			for (int dx = std::max(x - r, 0); dx <= std::min(x + r, size - 1); ++dx) row[base + dx] = 1;
		}
	}
	out.resize(count);
	uint8_t *o = out.ptrw();
	std::fill(o, o + count, 0);
	for (int z = 0; z < size; ++z) {
		for (int x = 0; x < size; ++x) {
			if (row[(int64_t)z * size + x] == 0) continue;
			for (int dz = std::max(z - r, 0); dz <= std::min(z + r, size - 1); ++dz) o[(int64_t)dz * size + x] = 1;
		}
	}
	return out;
}

PackedFloat32Array GridFilters::box_sum(const PackedFloat32Array &src, int size, int r, bool rows) {
	const int64_t count = (int64_t)size * size;
	PackedFloat32Array out;
	if (size <= 0 || src.size() < count) return out;
	out.resize(count);
	const float *s = src.ptr();
	float *o = out.ptrw();
	for (int line = 0; line < size; ++line) {
		double acc = 0.0;
		const int64_t stride = rows ? 1 : size;
		const int64_t base = rows ? (int64_t)line * size : line;
		for (int t = 0; t < std::min(r, size); ++t) acc += s[base + t * stride];
		for (int t = 0; t < size; ++t) {
			if (t + r < size) acc += s[base + (t + r) * stride];
			if (t - r - 1 >= 0) acc -= s[base + (t - r - 1) * stride];
			o[base + t * stride] = (float)acc;
		}
	}
	return out;
}

PackedFloat32Array GridFilters::relax(const PackedFloat32Array &filled, const PackedInt32Array &holes, int size, int sweeps) {
	PackedFloat32Array out = filled;
	const int64_t count = (int64_t)size * size;
	if (size <= 0 || out.size() < count) return out;
	float *f = out.ptrw();
	const int32_t *h = holes.ptr();
	for (int s = 0; s < sweeps; ++s) {
		for (int64_t k = 0; k < holes.size(); ++k) {
			const int i = h[k];
			const int x = i % size, z = i / size;
			double sum = 0.0;
			int n = 0;
			if (x > 0) { sum += f[i - 1]; ++n; }
			if (x < size - 1) { sum += f[i + 1]; ++n; }
			if (z > 0) { sum += f[i - size]; ++n; }
			if (z < size - 1) { sum += f[i + size]; ++n; }
			f[i] = (float)(sum / (double)n);
		}
	}
	return out;
}

PackedFloat32Array GridFilters::box_mean(const PackedFloat32Array &src, int size, int r, bool horizontal) {
	const int64_t count = (int64_t)size * size;
	PackedFloat32Array out;
	if (size <= 0 || src.size() < count) return out;
	out.resize(count);
	const float *s = src.ptr();
	float *o = out.ptrw();
	const auto at = [size, horizontal](int line, int j) {
		return horizontal ? (int64_t)line * size + j : (int64_t)j * size + line;
	};
	for (int line = 0; line < size; ++line) {
		double sum = 0.0;
		int n = 0;
		for (int j = 0; j <= std::min(r, size - 1); ++j) {
			sum += s[at(line, j)];
			++n;
		}
		for (int j = 0; j < size; ++j) {
			o[at(line, j)] = (float)(sum / (double)n);
			const int add = j + r + 1, drop = j - r;
			if (add < size) {
				sum += s[at(line, add)];
				++n;
			}
			if (drop >= 0) {
				sum -= s[at(line, drop)];
				--n;
			}
		}
	}
	return out;
}

PackedFloat32Array GridFilters::edge_blur(const PackedFloat32Array &src, int size, double inv) {
	const int64_t count = (int64_t)size * size;
	PackedFloat32Array out;
	if (size <= 0 || src.size() < count) return out;
	out.resize(count);
	const float *s = src.ptr();
	float *o = out.ptrw();
	const auto post = [s, size](int x, int z) {
		return (double)s[(int64_t)std::clamp(z, 0, size - 1) * size + std::clamp(x, 0, size - 1)];
	};
	for (int z = 0; z < size; ++z) {
		for (int x = 0; x < size; ++x) {
			const double c = post(x, z);
			double sum = c * 2.0;
			double n = 2.0;
			for (int dz = -1; dz <= 1; ++dz) {
				for (int dx = -1; dx <= 1; ++dx) {
					if (dx == 0 && dz == 0) continue;
					const double h = post(x + dx, z + dz);
					const double w = std::exp(-(h - c) * (h - c) * inv);
					sum += h * w;
					n += w;
				}
			}
			o[(int64_t)z * size + x] = (float)(sum / n);
		}
	}
	return out;
}

void GridFilters::_bind_methods() {
	ClassDB::bind_static_method("GridFilters", D_METHOD("edge_blur", "src", "size", "inv"), &GridFilters::edge_blur);
	ClassDB::bind_static_method("GridFilters", D_METHOD("rank_filter", "src", "size", "r", "lowest"), &GridFilters::rank_filter);
	ClassDB::bind_static_method("GridFilters", D_METHOD("dilate", "src", "size", "r"), &GridFilters::dilate);
	ClassDB::bind_static_method("GridFilters", D_METHOD("box_sum", "src", "size", "r", "rows"), &GridFilters::box_sum);
	ClassDB::bind_static_method("GridFilters", D_METHOD("relax", "filled", "holes", "size", "sweeps"), &GridFilters::relax);
	ClassDB::bind_static_method("GridFilters", D_METHOD("box_mean", "src", "size", "r", "horizontal"), &GridFilters::box_mean);
}

} // namespace godot
