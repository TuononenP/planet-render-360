#pragma once

// Far-terrain sampling shared by the native kernels: the GDScript
// FarSampler / FarSurface / GroundTruth reads, each repeating its
// script twin's arithmetic and float32 rounding.

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <algorithm>
#include <cmath>
#include <vector>

namespace godot {
namespace far {

// FarSurface.RING_FADE_PX
constexpr double RING_FADE_PX = 24.0;
// FarTerrainBuilder constants.
constexpr double OUTER_RADIUS_M = 30000.0;
constexpr double OUTER_FADE = 0.8;
constexpr double CARVE_TOL_M = 8.0;
constexpr double INNER_TUCK_M = 0.15;
constexpr double SEA_LEVEL_M = 0.5;

struct Ring {
	int w = 0;
	int h = 0;
	int zoom = 0;
	double n = 0.0;
	Vector2 origin;
	PackedFloat32Array heights;
};

// FarWaterMask: LAND / INLAND / OCEAN bytes over a Mercator window.
constexpr int MASK_NONE = -1;
constexpr int MASK_LAND = 0;
constexpr int MASK_OCEAN = 255;

struct WaterMask {
	int n = 0;
	double world = 0.0; // global px across the world at the mask zoom
	Vector2 origin, size;
	PackedByteArray bytes;

	// FarWaterMask.sample_uv
	int sample_uv(double u, double v) const {
		if (n <= 0) {
			return MASK_NONE;
		}
		double tx = (u * world - (double)origin.x) / (double)size.x;
		double ty = (v * world - (double)origin.y) / (double)size.y;
		if (tx < 0.0 || ty < 0.0 || tx >= 1.0 || ty >= 1.0) {
			return MASK_NONE;
		}
		int ix = Math::min((int)(tx * n), n - 1);
		int iy = Math::min((int)(ty * n), n - 1);
		return bytes.ptr()[(int64_t)iy * n + ix];
	}
};

// FarWaterMask.native_params; empty dictionary = no mask.
inline WaterMask read_mask(const Dictionary &d) {
	WaterMask m;
	if (d.is_empty()) {
		return m;
	}
	m.bytes = d["bytes"];
	int n = d["n"];
	if (m.bytes.size() != (int64_t)n * n) {
		return m;
	}
	m.n = n;
	m.world = (double)(1 << (int)d["zoom"]) * 256.0;
	m.origin = d["origin_px"];
	m.size = d["size_px"];
	return m;
}

struct Far {
	double lat, lon, m2u;
	double fcx, fcy; // far_centre_frac, float32 widened
	double s_0, blend_u, span_u, edge_hi;
	int grid;
	double water_level_m, datum_m, y_scale, step_units;
	int size;
	const float *far = nullptr;
	const float *surface = nullptr;
	int64_t surface_n = 0;
	Object *shore_sampler = nullptr;
	// GroundTruth._half_units / _level (carved water surface per post).
	double half_units = 0.0;
	const float *level = nullptr;
	int64_t level_n = 0;
	std::vector<Ring> rings;
	WaterMask mask;
	// Keep the arrays alive while the pointers are used.
	PackedFloat32Array far_keep, surface_keep, level_keep;
};

// The script side packs these (FarSampler.native_params).
inline Far read_far(const Dictionary &params, const Array &dem_rings) {
	Far f;
	if (params.has("shore_sampler")) f.shore_sampler = params["shore_sampler"];
	f.lat = params["lat"];
	f.lon = params["lon"];
	f.m2u = params["m2u"];
	Vector2 fc = params["far_centre_frac"];
	f.fcx = fc.x;
	f.fcy = fc.y;
	f.s_0 = params["s_0"];
	f.blend_u = params["blend_u"];
	f.span_u = params["span_u"];
	f.edge_hi = params["edge_hi"];
	f.grid = params["far_grid_size"];
	f.water_level_m = params["water_level_m"];
	f.datum_m = params["datum_m"];
	f.y_scale = params["y_scale"];
	f.step_units = params["step_units"];
	f.size = params["size"];
	f.half_units = params.get("half_units", 0.0);
	f.far_keep = params["far_heights"];
	f.surface_keep = params["surface"];
	f.level_keep = params.get("level", PackedFloat32Array());
	f.far = f.far_keep.ptr();
	f.surface = f.surface_keep.ptr();
	f.surface_n = f.surface_keep.size();
	f.level = f.level_keep.ptr();
	f.level_n = f.level_keep.size();
	f.mask = read_mask(params.get("water_mask", Dictionary()));
	for (int64_t k = 0; k < dem_rings.size(); k++) {
		Dictionary d = dem_rings[k];
		Ring r;
		r.w = d["width"];
		r.h = d["height"];
		r.zoom = d["zoom"];
		r.n = (double)(1 << r.zoom) * 256.0;
		r.origin = d["origin_px"];
		r.heights = d["heights"];
		f.rings.push_back(r);
	}
	return f;
}

// FarSurface.merc_uv (through WorldScale.latlon_from_xz).
inline Vector2 merc_uv(const Far &f, double xm, double zm) {
	double north_m = -zm;
	double east_m = xm;
	Vector2 ll(f.lat + north_m / 110540.0,
			f.lon + east_m / (111320.0 * std::cos(Math::deg_to_rad(f.lat))));
	double u = ((double)ll.y + 180.0) / 360.0;
	double lat = Math::clamp((double)ll.x, -85.0, 85.0);
	double v = (1.0 - std::asinh(std::tan(Math::deg_to_rad(lat))) / Math::PI) / 2.0;
	return Vector2(u, v);
}

// FarSampler._sample_far_dem
inline double sample_far_dem(const Far &f, double u, double v) {
	int grid = f.grid;
	double fu = Math::clamp(u, 0.0, 1.0) * (double)(grid - 1);
	double fv = Math::clamp(v, 0.0, 1.0) * (double)(grid - 1);
	int x0 = Math::clamp((int)fu, 0, grid - 2);
	int z0 = Math::clamp((int)fv, 0, grid - 2);
	double tx = fu - (double)x0;
	double tz = fv - (double)z0;
	double a = Math::lerp((double)f.far[z0 * grid + x0], (double)f.far[z0 * grid + x0 + 1], tx);
	double b = Math::lerp((double)f.far[(z0 + 1) * grid + x0], (double)f.far[(z0 + 1) * grid + x0 + 1], tx);
	return Math::lerp(a, b, tz);
}

// FarSurface.ring_sample_uv
inline Vector2 ring_sample_uv(const Ring &r, double u, double v) {
	Vector2 p = Vector2(u * r.n, v * r.n) - r.origin - Vector2(0.5, 0.5);
	double px = p.x;
	double py = p.y;
	double edge = Math::min(Math::min(px, py), Math::min((double)(r.w - 1) - px, (double)(r.h - 1) - py));
	if (edge <= 0.0) {
		return Vector2();
	}
	int x0 = Math::min((int)px, r.w - 2);
	int y0 = Math::min((int)py, r.h - 2);
	double tx = px - (double)x0;
	double ty = py - (double)y0;
	int64_t i = (int64_t)y0 * r.w + x0;
	const float *hs = r.heights.ptr();
	double a = Math::lerp((double)hs[i], (double)hs[i + 1], tx);
	double b = Math::lerp((double)hs[i + r.w], (double)hs[i + r.w + 1], tx);
	return Vector2(Math::lerp(a, b, ty), Math::clamp(edge / RING_FADE_PX, 0.0, 1.0));
}

// FarSurface.height_m_uv
inline double height_m_uv(const Far &f, double u, double v, double fallback_m, double outer_fade) {
	double h = fallback_m;
	int n = (int)f.rings.size();
	for (int k = n - 1; k >= 0; k--) {
		Vector2 s = ring_sample_uv(f.rings[k], u, v);
		double w = (double)s.y * (k == n - 1 ? outer_fade : 1.0);
		if (w > 0.0) {
			h = Math::lerp(h, (double)s.x, w);
		}
	}
	return h;
}

inline double sea_floor(const Far &f, double h_m) {
	if (Math::is_equal_approx(f.water_level_m, -3.0)) {
		return h_m;
	}
	return Math::max(h_m, 0.0);
}

inline double render_y(const Far &f, double m_asl) {
	return (m_asl - f.datum_m) * f.y_scale;
}

// FarSampler._open_sea
inline bool open_sea(const Far &f, double u, double v) {
	if (f.mask.n <= 0 || Math::is_equal_approx(f.water_level_m, -3.0)) {
		return false;
	}
	return f.mask.sample_uv(u, v) == MASK_OCEAN;
}

// GroundTruth.height_at_world
inline double height_at_world(const Far &f, double x, double z) {
	if (f.shore_sampler != nullptr) {
		const double lo = -f.size * 0.5 * f.step_units;
		const double hi = lo + (f.size - 1) * f.step_units;
		return f.shore_sampler->call("height", Math::clamp(x, lo, hi), Math::clamp(z, lo, hi));
	}
	int size = f.size;
	if (size < 2 || f.surface_n != (int64_t)size * size) {
		return f.water_level_m;
	}
	double fx = Math::clamp(x / f.step_units + (double)size * 0.5, 0.0, (double)(size - 1));
	double fz = Math::clamp(z / f.step_units + (double)size * 0.5, 0.0, (double)(size - 1));
	int x0 = Math::min((int)fx, size - 2);
	int z0 = Math::min((int)fz, size - 2);
	double tx = fx - (double)x0;
	double tz = fz - (double)z0;
	const float *s = f.surface;
	double a = Math::lerp((double)s[z0 * size + x0], (double)s[z0 * size + x0 + 1], tx);
	double b = Math::lerp((double)s[(z0 + 1) * size + x0], (double)s[(z0 + 1) * size + x0 + 1], tx);
	return Math::lerp(a, b, tz);
}

// FarSampler._mid_dem_height_uv
inline double mid_dem_height_uv(const Far &f, double x, double z, double u, double v) {
	Vector2 uv(f.fcx + x / f.span_u, f.fcy + z / f.span_u);
	double far_m = sample_far_dem(f, uv.x, uv.y);
	if (open_sea(f, u, v)) {
		return render_y(f, 0.0);
	}
	if (f.rings.empty()) {
		return render_y(f, sea_floor(f, far_m));
	}
	double d_m = Math::max(std::abs(x), std::abs(z)) / f.m2u;
	double fade = 1.0 - Math::smoothstep(OUTER_RADIUS_M * OUTER_FADE, OUTER_RADIUS_M, d_m);
	return render_y(f, sea_floor(f, height_m_uv(f, u, v, far_m, fade)));
}

inline double shore_join(const Far &f, double x, double z, double dem) {
	const double lo = -f.size * 0.5 * f.step_units, hi = lo + (f.size - 1) * f.step_units;
	const double outside = std::max({lo - x, x - hi, lo - z, z - hi, 0.0});
	const double w = Math::smoothstep(0.0, f.blend_u, outside);
	if (w >= 1.0) return dem;
	return Math::lerp(height_at_world(f, x, z), dem, w) - INNER_TUCK_M * f.m2u * (1.0 - w);
}

// FarSampler._blend_height_uv
inline double blend_height_uv(const Far &f, double x, double z, double u, double v) {
	double d = Math::max(std::abs(x), std::abs(z));
	double w = Math::smoothstep(f.s_0, f.s_0 + f.blend_u, d);
	double dem = mid_dem_height_uv(f, x, z, u, v);
	if (f.shore_sampler != nullptr) return shore_join(f, x, z, dem);
	if (w >= 1.0) {
		return dem;
	}
	double g = Math::max(height_at_world(f, x, z), dem - CARVE_TOL_M * f.m2u);
	double h = Math::lerp(g, dem, w);
	double lip = INNER_TUCK_M * f.m2u * (1.0 - Math::smoothstep(f.s_0, f.edge_hi + (f.edge_hi - f.s_0), d));
	return h - lip;
}

// --- Metre-XZ (non-UV) path: FarCityBuilder samples through these. ---

// FarSurface.global_px (WorldScale.latlon_from_xz, TileFetcher.global_pixel):
// x n before the float32 rounding, unlike merc_uv.
inline Vector2 global_px(const Far &f, double xm, double zm, int zoom) {
	double north_m = -zm;
	double east_m = xm;
	Vector2 ll(f.lat + north_m / 110540.0,
			f.lon + east_m / (111320.0 * std::cos(Math::deg_to_rad(f.lat))));
	double n = (double)(1 << zoom) * 256.0;
	double px = ((double)ll.y + 180.0) / 360.0 * n;
	double lat_rad = Math::deg_to_rad(Math::clamp((double)ll.x, -85.0, 85.0));
	double py = (1.0 - std::asinh(std::tan(lat_rad)) / Math::PI) / 2.0 * n;
	return Vector2(px, py);
}

// FarSurface.ring_sample
inline Vector2 ring_sample(const Far &f, const Ring &r, double xm, double zm) {
	Vector2 p = global_px(f, xm, zm, r.zoom) - r.origin - Vector2(0.5, 0.5);
	double px = p.x;
	double py = p.y;
	double edge = Math::min(Math::min(px, py), Math::min((double)(r.w - 1) - px, (double)(r.h - 1) - py));
	if (edge <= 0.0) {
		return Vector2();
	}
	int x0 = Math::min((int)px, r.w - 2);
	int y0 = Math::min((int)py, r.h - 2);
	double tx = px - (double)x0;
	double ty = py - (double)y0;
	int64_t i = (int64_t)y0 * r.w + x0;
	const float *hs = r.heights.ptr();
	double a = Math::lerp((double)hs[i], (double)hs[i + 1], tx);
	double b = Math::lerp((double)hs[i + r.w], (double)hs[i + r.w + 1], tx);
	return Vector2(Math::lerp(a, b, ty), Math::clamp(edge / RING_FADE_PX, 0.0, 1.0));
}

// FarSurface.height_m
inline double height_m(const Far &f, double xm, double zm, double fallback_m, double outer_fade) {
	double h = fallback_m;
	int n = (int)f.rings.size();
	for (int k = n - 1; k >= 0; k--) {
		Vector2 s = ring_sample(f, f.rings[k], xm, zm);
		double w = (double)s.y * (k == n - 1 ? outer_fade : 1.0);
		if (w > 0.0) {
			h = Math::lerp(h, (double)s.x, w);
		}
	}
	return h;
}

// FarSampler._mid_dem_height
inline double mid_dem_height(const Far &f, double x, double z) {
	Vector2 uv(f.fcx + x / f.span_u, f.fcy + z / f.span_u);
	double far_m = sample_far_dem(f, uv.x, uv.y);
	if (f.mask.n > 0) {
		Vector2 muv = merc_uv(f, x / f.m2u, z / f.m2u);
		if (open_sea(f, muv.x, muv.y)) {
			return render_y(f, 0.0);
		}
	}
	if (f.rings.empty()) {
		return render_y(f, sea_floor(f, far_m));
	}
	double d_m = Math::max(std::abs(x), std::abs(z)) / f.m2u;
	double fade = 1.0 - Math::smoothstep(OUTER_RADIUS_M * OUTER_FADE, OUTER_RADIUS_M, d_m);
	return render_y(f, sea_floor(f, height_m(f, x / f.m2u, z / f.m2u, far_m, fade)));
}

// FarSampler._blend_height
inline double blend_height(const Far &f, double x, double z) {
	double d = Math::max(std::abs(x), std::abs(z));
	double w = Math::smoothstep(f.s_0, f.s_0 + f.blend_u, d);
	double dem = mid_dem_height(f, x, z);
	if (f.shore_sampler != nullptr) return shore_join(f, x, z, dem);
	if (w >= 1.0) {
		return dem;
	}
	double g = Math::max(height_at_world(f, x, z), dem - CARVE_TOL_M * f.m2u);
	double h = Math::lerp(g, dem, w);
	double lip = INNER_TUCK_M * f.m2u * (1.0 - Math::smoothstep(f.s_0, f.edge_hi + (f.edge_hi - f.s_0), d));
	return h - lip;
}

// GroundTruth.is_inside
inline bool is_inside(const Far &f, double x, double z) {
	return std::abs(x) <= f.half_units && std::abs(z) <= f.half_units;
}

// GroundTruth.asl_y
inline double asl_y(const Far &f, double render) {
	return render / f.y_scale + f.datum_m;
}

// GroundTruth.water_level_at
inline double water_level_at(const Far &f, double x, double z) {
	int size = f.size;
	if (size < 2 || f.level_n != (int64_t)size * size) {
		return f.water_level_m;
	}
	double fx = Math::clamp(x / f.step_units + (double)size * 0.5, 0.0, (double)(size - 1));
	double fz = Math::clamp(z / f.step_units + (double)size * 0.5, 0.0, (double)(size - 1));
	int x0 = Math::min((int)fx, size - 2);
	int z0 = Math::min((int)fz, size - 2);
	double sum = 0.0;
	double wsum = 0.0;
	for (int k = 0; k < 4; k++) {
		int px = x0 + (k & 1);
		int pz = z0 + (k >> 1);
		double lv = f.level[pz * size + px];
		if (std::isinf(lv)) {
			continue;
		}
		double w = Math::max((1.0 - std::abs(fx - (double)px)) * (1.0 - std::abs(fz - (double)pz)), 1e-4);
		sum += lv * w;
		wsum += w;
	}
	if (wsum <= 0.0) {
		return f.water_level_m;
	}
	return Math::max(f.water_level_m, sum / wsum);
}

// GroundTruth.water_at
inline double water_at(const Far &f, double x, double z) {
	return Math::max(0.0, water_level_at(f, x, z) - height_at_world(f, x, z));
}

// PolygonIndex, read once from the script object.
struct Poly {
	std::vector<PackedVector2Array> rings;
	Rect2 box;
	double y0 = 0.0;
	double band_h = 1.0;
	std::vector<std::vector<int64_t>> bands;

	bool contains(const Vector2 &p) const {
		if (rings.empty() || !box.has_point(p)) {
			return false;
		}
		int band = Math::clamp((int)std::floor(((double)p.y - y0) / band_h), 0, (int)bands.size() - 1);
		const double px = p.x;
		const double py = p.y;
		// Codes are sorted (read_poly), so each ring's edges form one run:
		// inside the outer ring (0) and in none of the holes.
		bool outer = false;
		int current = -1;
		uint8_t parity = 0;
		for (int64_t code : bands[band]) {
			int ri = (int)(code >> 32);
			if (ri != current) {
				if (current == 0) {
					outer = parity == 1;
				} else if (current > 0 && parity == 1) {
					return false;
				}
				current = ri;
				parity = 0;
			}
			const PackedVector2Array &ring = rings[ri];
			int64_t i = code & 0xFFFFFFFF;
			Vector2 pi = ring[i];
			Vector2 pj = ring[i > 0 ? i - 1 : ring.size() - 1];
			if (((double)pi.y > py) != ((double)pj.y > py) &&
					px < ((double)pj.x - (double)pi.x) * (py - (double)pi.y) / ((double)pj.y - (double)pi.y) + (double)pi.x) {
				parity ^= 1;
			}
		}
		if (current == 0) {
			outer = parity == 1;
		} else if (current > 0 && parity == 1) {
			return false;
		}
		return outer;
	}
};

inline Poly read_poly(Object *o) {
	Poly q;
	Array rings = o->get("_rings");
	for (int64_t i = 0; i < rings.size(); i++) {
		q.rings.push_back(rings[i]);
	}
	q.box = o->get("_box");
	q.y0 = o->get("_y0");
	q.band_h = o->get("_band_h");
	Array bands = o->get("_bands");
	q.bands.resize(bands.size());
	for (int64_t b = 0; b < bands.size(); b++) {
		Array codes = bands[b];
		for (int64_t c = 0; c < codes.size(); c++) {
			q.bands[b].push_back((int64_t)codes[c]);
		}
		std::sort(q.bands[b].begin(), q.bands[b].end());
	}
	return q;
}

// TerrainBuilder._hash
inline double hash(double x, double z) {
	return std::fmod(std::abs(std::sin(x * 12.9898 + z * 78.233) * 43758.5453), 1.0);
}

} // namespace far
} // namespace godot
