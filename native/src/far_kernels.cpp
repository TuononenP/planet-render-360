#include "far_kernels.h"

#include "parallel.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

namespace godot {

namespace {

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
	double n = 0.0;
	Vector2 origin;
	PackedFloat32Array heights;
};

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
	std::vector<Ring> rings;
};

// FarSurface.merc_uv (through WorldScale.latlon_from_xz).
Vector2 merc_uv(const Far &f, double xm, double zm) {
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
double sample_far_dem(const Far &f, double u, double v) {
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
Vector2 ring_sample_uv(const Ring &r, double u, double v) {
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
double height_m_uv(const Far &f, double u, double v, double fallback_m, double outer_fade) {
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

double sea_floor(const Far &f, double h_m) {
	if (Math::is_equal_approx(f.water_level_m, -3.0)) {
		return h_m;
	}
	return Math::max(h_m, 0.0);
}

double render_y(const Far &f, double m_asl) {
	return (m_asl - f.datum_m) * f.y_scale;
}

// GroundTruth.height_at_world
double height_at_world(const Far &f, double x, double z) {
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
double mid_dem_height_uv(const Far &f, double x, double z, double u, double v) {
	Vector2 uv(f.fcx + x / f.span_u, f.fcy + z / f.span_u);
	double far_m = sample_far_dem(f, uv.x, uv.y);
	if (f.rings.empty()) {
		return render_y(f, sea_floor(f, far_m));
	}
	double d_m = Math::max(std::abs(x), std::abs(z)) / f.m2u;
	double fade = 1.0 - Math::smoothstep(OUTER_RADIUS_M * OUTER_FADE, OUTER_RADIUS_M, d_m);
	return render_y(f, sea_floor(f, height_m_uv(f, u, v, far_m, fade)));
}

// FarSampler._blend_height_uv
double blend_height_uv(const Far &f, double x, double z, double u, double v) {
	double d = Math::max(std::abs(x), std::abs(z));
	double w = Math::smoothstep(f.s_0, f.s_0 + f.blend_u, d);
	double dem = mid_dem_height_uv(f, x, z, u, v);
	if (w >= 1.0) {
		return dem;
	}
	double g = Math::max(height_at_world(f, x, z), dem - CARVE_TOL_M * f.m2u);
	double h = Math::lerp(g, dem, w);
	double lip = INNER_TUCK_M * f.m2u * (1.0 - Math::smoothstep(f.s_0, f.edge_hi + (f.edge_hi - f.s_0), d));
	return h - lip;
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
		std::vector<uint8_t> parity(rings.size(), 0);
		for (int64_t code : bands[band]) {
			int ri = (int)(code >> 32);
			const PackedVector2Array &ring = rings[ri];
			int64_t i = code & 0xFFFFFFFF;
			Vector2 pi = ring[i];
			Vector2 pj = ring[i > 0 ? i - 1 : ring.size() - 1];
			if (((double)pi.y > py) != ((double)pj.y > py) &&
					px < ((double)pj.x - (double)pi.x) * (py - (double)pi.y) / ((double)pj.y - (double)pi.y) + (double)pi.x) {
				parity[ri] ^= 1;
			}
		}
		if (parity[0] == 0) {
			return false;
		}
		for (size_t k = 1; k < parity.size(); k++) {
			if (parity[k] == 1) {
				return false;
			}
		}
		return true;
	}
};

Poly read_poly(Object *o) {
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
	}
	return q;
}

// TerrainBuilder._hash
double hash(double x, double z) {
	return std::fmod(std::abs(std::sin(x * 12.9898 + z * 78.233) * 43758.5453), 1.0);
}

struct Climate {
	double tl, sl;
	Color forest, meadow;
};

// FarSurface.ramp_color_cached
Color ramp_color(const Climate &cl, const Vector3 &nrm, double h_asl, bool water, double noise) {
	if (water) {
		return Color(0.149, 0.263, 0.247, 0.0).srgb_to_linear();
	}
	const double tl = cl.tl;
	const double sl = cl.sl;
	Color alpine(0.42, 0.43, 0.32);
	Color rock(0.40, 0.38, 0.36);
	Color snow(0.90, 0.92, 0.95);
	double ny = nrm.y;
	double flat = Math::clamp((ny - 0.80) / 0.15, 0.0, 1.0);
	Color c = cl.forest.lerp(cl.meadow, Math::clamp(flat * 0.8 + (noise - 0.5) * 0.5, 0.0, 1.0));
	c = c.lerp(alpine, Math::smoothstep(tl - 150.0, tl + 150.0, h_asl));
	double steep = 1.0 - Math::smoothstep(0.55, 0.80, ny);
	double high = Math::smoothstep(tl, tl + 500.0, h_asl);
	c = c.lerp(rock, Math::clamp(Math::max(steep, high * 0.85), 0.0, 1.0));
	double hold = Math::smoothstep(0.45, 0.70, ny);
	double snow_w = Math::smoothstep(sl - 200.0, sl + 200.0, h_asl + (noise - 0.5) * 160.0) * hold;
	c = c.lerp(snow, snow_w);
	double shade = 0.92 + noise * 0.16;
	return Color((double)c.r * shade, (double)c.g * shade, (double)c.b * shade).srgb_to_linear();
}

} // namespace

Array FarKernels::ring_colors(const PackedVector3Array &pos, int loops, int per,
		const Dictionary &params, const Array &water) {
	Climate cl;
	cl.tl = params["tl"];
	cl.sl = params["sl"];
	cl.forest = params["forest"];
	cl.meadow = params["meadow"];
	const double water_level_m = params["water_level_m"];
	const double datum_m = params["datum_m"];
	const double y_scale = params["y_scale"];
	const Rect2 wbounds = params["wbounds"];
	std::vector<Poly> polys;
	for (int64_t i = 0; i < water.size(); i++) {
		Object *o = water[i];
		if (o != nullptr) {
			polys.push_back(read_poly(o));
		}
	}
	// GroundTruth.asl_y
	auto asl_y = [&](double render) { return render / y_scale + datum_m; };
	const double water_asl = asl_y(water_level_m);
	PackedVector3Array normals;
	normals.resize(pos.size());
	PackedColorArray colors;
	colors.resize(pos.size());
	const Vector3 *v3 = pos.ptr();
	Vector3 *nout = normals.ptrw();
	Color *cout = colors.ptrw();
	parallel_for(loops, [&](int k) {
		int64_t ki = (int64_t)Math::max(k - 1, 0) * per;
		int64_t ko = (int64_t)Math::min(k + 1, loops - 1) * per;
		int64_t row = (int64_t)k * per;
		for (int j = 0; j < per; j++) {
			Vector3 v = v3[row + j];
			Vector3 tan = v3[row + (j + 1) % per] - v3[row + (j - 1 + per) % per];
			Vector3 rad = v3[ko + j] - v3[ki + j];
			Vector3 nrm = tan.cross(rad).normalized();
			if (nrm.y < 0.0) {
				nrm = -nrm;
			}
			nout[row + j] = nrm;
			// FarSampler._is_wet: union-bounds reject, then each polygon.
			Vector2 p(v.x, v.z);
			bool in_osm = false;
			if (!(wbounds.has_area() && !wbounds.has_point(p))) {
				for (const Poly &q : polys) {
					if (q.contains(p)) {
						in_osm = true;
						break;
					}
				}
			}
			double h_asl = asl_y(v.y);
			// FarSampler._far_water
			bool wet = in_osm || (water_asl == -3.0 ? h_asl < water_asl + 1.0 : h_asl < SEA_LEVEL_M);
			cout[row + j] = ramp_color(cl, nrm, h_asl, wet, hash((double)v.x * 1.3, (double)v.z * 1.7));
		}
	});
	Array out;
	out.push_back(normals);
	out.push_back(colors);
	return out;
}

PackedVector3Array FarKernels::ring_positions(const PackedFloat64Array &radii, int segs,
		const Dictionary &params, const PackedFloat32Array &far_heights,
		const PackedFloat32Array &ground_surface, const Array &dem_rings) {
	Far f;
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
	f.far = far_heights.ptr();
	f.surface = ground_surface.ptr();
	f.surface_n = ground_surface.size();
	for (int64_t k = 0; k < dem_rings.size(); k++) {
		Dictionary d = dem_rings[k];
		Ring r;
		r.w = d["width"];
		r.h = d["height"];
		int zoom = d["zoom"];
		r.n = (double)(1 << zoom) * 256.0;
		r.origin = d["origin_px"];
		r.heights = d["heights"];
		f.rings.push_back(r);
	}
	int per = 4 * segs;
	int loops = (int)radii.size();
	PackedVector3Array pos;
	pos.resize((int64_t)loops * per);
	Vector3 *out = pos.ptrw();
	const double *rad = radii.ptr();
	parallel_for(loops, [&](int k) {
		double r = rad[k];
		for (int side = 0; side < 4; side++) {
			for (int i = 0; i < segs; i++) {
				double t = ((double)i / (double)segs - 0.5) * 2.0 * r;
				Vector2 p(t, -r);
				if (side == 1) {
					p = Vector2(r, t);
				} else if (side == 2) {
					p = Vector2(-t, r);
				} else if (side == 3) {
					p = Vector2(-r, -t);
				}
				Vector2 uv = merc_uv(f, p.x / f.m2u, p.y / f.m2u);
				double h = blend_height_uv(f, p.x, p.y, uv.x, uv.y);
				out[(int64_t)k * per + side * segs + i] = Vector3(p.x, h, p.y);
			}
		}
	});
	return pos;
}

void FarKernels::_bind_methods() {
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("ring_positions", "radii", "segs", "params", "far_heights", "ground_surface", "dem_rings"),
			&FarKernels::ring_positions);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("ring_colors", "pos", "loops", "per", "params", "water"),
			&FarKernels::ring_colors);
}

} // namespace godot
