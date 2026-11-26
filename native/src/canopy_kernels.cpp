#include "canopy_kernels.h"
#include "far_sampling.h"

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

Dictionary CanopyKernels::build_instances(const PackedFloat64Array &xs, const PackedFloat64Array &zs,
		const PackedFloat32Array &rgb, const PackedFloat64Array &widens,
		const Dictionary &far_params, const Array &dem_rings, bool far_ok,
		const PackedFloat64Array &bands, const PackedFloat64Array &mix_weights,
		bool winter, const Ref<FastNoiseLite> &stand) {
	Dictionary out;
	Array groups_out;
	const int64_t n = xs.size();
	const int64_t n_sp = mix_weights.size();
	const int64_t n_bands = bands.size() - 1;
	if (n == 0 || zs.size() != n || widens.size() != n || rgb.size() < n * 3 || n_sp <= 0 || n_bands <= 0) {
		out["total"] = (int64_t)0;
		out["groups"] = groups_out;
		return out;
	}
	far::Far f = far::read_far(far_params, dem_rings);
	double w_total = 0.0;
	for (int64_t i = 0; i < n_sp; ++i) w_total += mix_weights[i];
	if (w_total <= 0.0) w_total = 1.0;
	std::vector<double> cdf(n_sp);
	double acc = 0.0;
	for (int64_t i = 0; i < n_sp; ++i) {
		acc += mix_weights[i] / w_total;
		cdf[i] = acc;
	}
	std::vector<std::vector<float>> buckets((size_t)(n_sp * n_bands));
	const double *xp = xs.ptr();
	const double *zp = zs.ptr();
	const float *rp = rgb.ptr();
	const double *wp = widens.ptr();
	const double *bp = bands.ptr();
	const bool has_stand = stand.is_valid();
	int64_t total = 0;
	for (int64_t k = 0; k < n; ++k) {
		const double x = xp[k];
		const double z = zp[k];
		if (f.mask.n > 0) {
			const Vector2 muv = far::merc_uv(f, x, z);
			if (f.mask.sample_uv(muv.x, muv.y) > far::MASK_LAND) continue;
		}
		const double y = far_ok ? far::blend_height(f, x, z) : far::height_at_world(f, x, z);
		const double u_sp = hash(x, z, 5.0) * 0.999;
		int64_t sp = n_sp - 1;
		for (int64_t i = 0; i < n_sp; ++i) {
			if (u_sp < cdf[i]) {
				sp = i;
				break;
			}
		}
		const double n2d = has_stand ? (double)stand->get_noise_2d((float)x, (float)z) : 0.0;
		const double st_t = Math::clamp(0.5 + n2d * 0.9, 0.0, 1.0);
		const double sz = Math::lerp(0.75, 1.25, st_t) * Math::lerp(0.8, 1.2, hash(x, z, 4.0));
		const double sw = sz * wp[k];
		const double cr = (double)rp[k * 3];
		const double cg = (double)rp[k * 3 + 1];
		const double cb = (double)rp[k * 3 + 2];
		const double lum = 0.299 * cr + 0.587 * cg + 0.114 * cb;
		const double v = Math::clamp(lum / 0.3, 0.5, 1.25) * (0.88 + 0.24 * hash(x, z, 7.0));
		float col_r, col_g, col_b;
		if (winter) {
			col_r = col_g = col_b = (float)v;
		} else {
			const double warm = Math::clamp((cr - cb) * 2.0, -0.3, 0.3);
			col_r = (float)(v * (1.0 + warm * 0.25));
			col_g = (float)v;
			col_b = (float)(v * (1.0 - warm * 0.3));
		}
		const double r_len = std::sqrt(x * x + z * z);
		int64_t band = 0;
		while (band < n_bands - 1 && r_len >= bp[band + 1]) ++band;
		const double ang = hash(x, z, 6.0) * Math::TAU;
		const double cs = std::cos(ang);
		const double sn = std::sin(ang);
		std::vector<float> &dst = buckets[(size_t)(sp * n_bands + band)];
		const size_t o = dst.size();
		dst.resize(o + 16);
		dst[o + 0] = (float)(cs * sw);
		dst[o + 1] = 0.0f;
		dst[o + 2] = (float)(sn * sw);
		dst[o + 3] = (float)x;
		dst[o + 4] = 0.0f;
		dst[o + 5] = (float)sz;
		dst[o + 6] = 0.0f;
		dst[o + 7] = (float)y;
		dst[o + 8] = (float)(-sn * sw);
		dst[o + 9] = 0.0f;
		dst[o + 10] = (float)(cs * sw);
		dst[o + 11] = (float)z;
		dst[o + 12] = col_r;
		dst[o + 13] = col_g;
		dst[o + 14] = col_b;
		dst[o + 15] = 1.0f;
		++total;
	}
	for (int64_t sp = 0; sp < n_sp; ++sp) {
		for (int64_t band = 0; band < n_bands; ++band) {
			const std::vector<float> &src = buckets[(size_t)(sp * n_bands + band)];
			if (src.empty()) continue;
			PackedFloat32Array pbuf;
			pbuf.resize((int64_t)src.size());
			std::copy(src.begin(), src.end(), pbuf.ptrw());
			Array entry;
			entry.append(sp);
			entry.append(band);
			entry.append(pbuf);
			groups_out.append(entry);
		}
	}
	out["total"] = total;
	out["groups"] = groups_out;
	return out;
}

void CanopyKernels::_bind_methods() {
	ClassDB::bind_static_method("CanopyKernels",
			D_METHOD("probes", "cells", "dists", "steps", "drapes", "lat", "lon", "dark", "min_green", "cell_m",
					"budget"),
			&CanopyKernels::probes);
	ClassDB::bind_static_method("CanopyKernels",
			D_METHOD("build_instances", "xs", "zs", "rgb", "widens", "far_params", "dem_rings", "far_ok",
					"bands", "mix_weights", "winter", "stand"),
			&CanopyKernels::build_instances);
}

} // namespace godot
