#include "canopy_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <algorithm>
#include <cmath>
#include <vector>

namespace godot {
namespace {

// Math::fposmod, as GDScript's fposmod.
double fposmod_d(double x, double y) {
	double v = std::fmod(x, y);
	if ((v < 0.0 && y > 0.0) || (v > 0.0 && y < 0.0)) v += y;
	v += 0.0;
	return v;
}

// FarCanopy._hash.
double hash(double x, double z, double salt) {
	return fposmod_d(std::sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0);
}

struct Drape {
	PackedByteArray bytes;
	int64_t w, h;
	int zoom;
	Vector2 origin, size;
};

} // namespace

Dictionary CanopyKernels::probes(const PackedVector2Array &cells, const PackedFloat64Array &dists,
		const PackedFloat64Array &steps, const Array &drapes, double lat, double lon, double dark,
		double min_green, double cell_m, int64_t budget) {
	// Inputs that do not line up would be read past their end: no probes.
	if (steps.size() < 2 || dists.size() != cells.size() || steps[1] <= 0.0) {
		Dictionary none;
		none["x"] = PackedFloat64Array();
		none["z"] = PackedFloat64Array();
		none["rgb"] = PackedFloat32Array();
		none["widen"] = PackedFloat64Array();
		return none;
	}
	std::vector<Drape> ds;
	for (int64_t k = 0; k < drapes.size(); ++k) {
		const Dictionary d = drapes[k];
		Drape drape = { d["bytes"], (int64_t)d["w"], (int64_t)d["h"], (int)(int64_t)d["zoom"], d["origin"], d["size"] };
		// A drape whose bytes are not RGB8 for its size is skipped, as an empty one is.
		if (drape.w <= 0 || drape.h <= 0 || drape.bytes.size() < drape.w * drape.h * 3) continue;
		ds.push_back(drape);
	}
	const double cos_lat = std::cos(lat * (Math::PI / 180.0));
	PackedFloat64Array xs, zs, widens;
	PackedFloat32Array rgb;
	int64_t kept = 0;
	for (int64_t c = 0; c < cells.size() && kept < budget; ++c) {
		const Vector2 centre = cells[c];
		const double dist = dists[c];
		double step = steps[1];
		for (int64_t r = 0; r + 1 < steps.size(); r += 2) {
			if (dist >= steps[r]) step = steps[r + 1];
		}
		const int per_cell = (int)(cell_m / step);
		const double widen = step / steps[1];
		for (int sj = 0; sj < per_cell && kept < budget; ++sj) {
			for (int si = 0; si < per_cell && kept < budget; ++si) {
				double x = (double)centre.x + ((double)si + 0.5) * step - cell_m * 0.5;
				double z = (double)centre.y + ((double)sj + 0.5) * step - cell_m * 0.5;
				x += (hash(x, z, 1.0) - 0.5) * step;
				z += (hash(x, z, 2.0) - 0.5) * step;
				// FarCanopy.pixel: the finest drape that covers the point.
				const Drape *hit = nullptr;
				int64_t o = 0;
				const real_t ll_lat = (real_t)(lat + (-z) / 110540.0);
				const real_t ll_lon = (real_t)(lon + x / (111320.0 * cos_lat));
				for (const Drape &d : ds) {
					if (d.bytes.is_empty()) continue;
					const double n = (double)(1 << d.zoom) * 256.0;
					const double px = ((double)ll_lon + 180.0) / 360.0 * n;
					const double lat_c = std::clamp((double)ll_lat, -85.0, 85.0);
					const double lat_rad = lat_c * (Math::PI / 180.0);
					const double py = (1.0 - std::asinh(std::tan(lat_rad)) / Math::PI) / 2.0 * n;
					const Vector2 uv = (Vector2((real_t)px, (real_t)py) - d.origin) / d.size;
					if ((double)uv.x <= 0.0 || (double)uv.y <= 0.0 || (double)uv.x >= 1.0 || (double)uv.y >= 1.0) continue;
					const int64_t iy = std::clamp((int64_t)((double)uv.y * (double)d.h), (int64_t)0, d.h - 1);
					const int64_t ix = std::clamp((int64_t)((double)uv.x * (double)d.w), (int64_t)0, d.w - 1);
					o = (iy * d.w + ix) * 3;
					hit = &d;
					break;
				}
				if (hit == nullptr) continue;
				const uint8_t *buf = hit->bytes.ptr();
				const real_t cr = (real_t)((double)buf[o] / 255.0);
				const real_t cg = (real_t)((double)buf[o + 1] / 255.0);
				const real_t cb = (real_t)((double)buf[o + 2] / 255.0);
				const double l = 0.299 * (double)cr + 0.587 * (double)cg + 0.114 * (double)cb;
				if (l >= dark || (double)cg - ((double)cr + (double)cb) * 0.5 < min_green) continue;
				xs.push_back(x);
				zs.push_back(z);
				widens.push_back(widen);
				rgb.push_back(cr);
				rgb.push_back(cg);
				rgb.push_back(cb);
				++kept;
			}
		}
	}
	Dictionary out;
	out["x"] = xs;
	out["z"] = zs;
	out["rgb"] = rgb;
	out["widen"] = widens;
	return out;
}

void CanopyKernels::_bind_methods() {
	ClassDB::bind_static_method("CanopyKernels",
			D_METHOD("probes", "cells", "dists", "steps", "drapes", "lat", "lon", "dark", "min_green", "cell_m",
					"budget"),
			&CanopyKernels::probes);
}

} // namespace godot
