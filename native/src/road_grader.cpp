#include "road_grader.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

void RoadGrader::setup(const PackedFloat32Array &p_src, const PackedFloat32Array &p_level, int p_size, double p_step,
		double p_max_shift) {
	src = p_src;
	level = p_level;
	size = p_size;
	step = p_step;
	max_shift = p_max_shift;
	const size_t count = (size_t)std::max(size, 0) * (size_t)std::max(size, 0);
	best_w.assign(count, 0.0f);
	best_h.assign(count, 0.0f);
	best_d.assign(count, INFINITY);
}

PackedFloat32Array RoadGrader::smooth(const PackedFloat32Array &h, const PackedByteArray &valid,
		const PackedFloat32Array &arc, double radius) {
	PackedFloat32Array out;
	const int64_t n = h.size();
	out.resize(n);
	float *o = out.ptrw();
	for (int64_t i = 0; i < n; ++i) {
		double sum = 0.0, wsum = 0.0;
		int64_t j = i;
		while (j >= 0 && (double)arc[i] - (double)arc[j] <= radius) {
			if (valid[j] == 1) {
				const double w = 1.0 - ((double)arc[i] - (double)arc[j]) / radius;
				sum += (double)h[j] * w;
				wsum += w;
			}
			j -= 1;
		}
		j = i + 1;
		while (j < n && (double)arc[j] - (double)arc[i] <= radius) {
			if (valid[j] == 1) {
				const double w = 1.0 - ((double)arc[j] - (double)arc[i]) / radius;
				sum += (double)h[j] * w;
				wsum += w;
			}
			j += 1;
		}
		o[i] = (float)(wsum > 0.0 ? sum / wsum : (double)h[i]);
	}
	return out;
}

void RoadGrader::stamp_line(const PackedVector2Array &line, const PackedFloat32Array &prof, const PackedByteArray &valid,
		double half) {
	if (size <= 0 || src.size() < (int64_t)size * size || level.size() < (int64_t)size * size) return;
	const float *s = src.ptr();
	const float *lv = level.ptr();
	const double inner = half + step * 0.5;
	const double reach = half + step * 1.8;
	const double hs = (double)size * 0.5;
	for (int64_t k = 0; k < line.size(); ++k) {
		if (valid[k] != 1) continue;
		const Vector2 p = line[k];
		const double target = prof[k];
		const int x0 = std::clamp((int)std::floor(((double)p.x - reach) / step + hs), 0, size - 1);
		const int x1 = std::clamp((int)std::ceil(((double)p.x + reach) / step + hs), 0, size - 1);
		const int z0 = std::clamp((int)std::floor(((double)p.y - reach) / step + hs), 0, size - 1);
		const int z1 = std::clamp((int)std::ceil(((double)p.y + reach) / step + hs), 0, size - 1);
		for (int z = z0; z <= z1; ++z) {
			for (int x = x0; x <= x1; ++x) {
				const int64_t i = (int64_t)z * size + x;
				if (!std::isinf(lv[i])) continue;
				const double d = Vector2((real_t)(((double)x - hs) * step), (real_t)(((double)z - hs) * step)).distance_to(p);
				if (d >= reach) continue;
				const double w = 1.0 - Math::smoothstep(inner, reach, d);
				if (w > (double)best_w[i] || (w == (double)best_w[i] && d < (double)best_d[i])) {
					best_w[i] = (float)w;
					best_d[i] = (float)d;
					const double lo = (double)s[i] - max_shift, hi = (double)s[i] + max_shift;
					best_h[i] = (float)(target < lo ? lo : (target > hi ? hi : target));
				}
			}
		}
	}
}

PackedFloat32Array RoadGrader::apply(const PackedFloat32Array &surface) const {
	PackedFloat32Array out = surface;
	const int64_t count = std::min((int64_t)best_w.size(), out.size());
	float *o = out.ptrw();
	for (int64_t i = 0; i < count; ++i) {
		if (best_w[i] > 0.0f) {
			const double a = o[i];
			o[i] = (float)(a + ((double)best_h[i] - a) * (double)best_w[i]);
		}
	}
	return out;
}

void RoadGrader::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "src", "level", "size", "step", "max_shift"), &RoadGrader::setup);
	ClassDB::bind_static_method("RoadGrader", D_METHOD("smooth", "heights", "valid", "arc", "radius"), &RoadGrader::smooth);
	ClassDB::bind_method(D_METHOD("stamp_line", "line", "prof", "valid", "half"), &RoadGrader::stamp_line);
	ClassDB::bind_method(D_METHOD("apply", "surface"), &RoadGrader::apply);
}

} // namespace godot
