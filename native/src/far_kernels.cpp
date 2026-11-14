#include "far_kernels.h"

#include "far_sampling.h"
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

using namespace far;

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
	const WaterMask mask = read_mask(params.get("water_mask", Dictionary()));
	Far geo; // merc_uv's viewpoint, for the mask lookup
	geo.lat = params.get("lat", 0.0);
	geo.lon = params.get("lon", 0.0);
	geo.m2u = params.get("m2u", 1.0);
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
			// FarSampler._far_water: the water mask decides where it covers.
			int mv = MASK_NONE;
			if (!in_osm && mask.n > 0) {
				Vector2 muv = merc_uv(geo, (double)v.x / geo.m2u, (double)v.z / geo.m2u);
				mv = mask.sample_uv(muv.x, muv.y);
			}
			bool wet = in_osm || (mv != MASK_NONE ? mv != MASK_LAND
					: (water_asl == -3.0 ? h_asl < water_asl + 1.0 : h_asl < SEA_LEVEL_M));
			cout[row + j] = ramp_color(cl, nrm, h_asl, wet, hash((double)v.x * 1.3, (double)v.z * 1.7));
		}
	});
	Array out;
	out.push_back(normals);
	out.push_back(colors);
	return out;
}

PackedVector3Array FarKernels::ring_positions(const PackedFloat64Array &radii, int segs,
		const Dictionary &params, const Array &dem_rings) {
	Far f = read_far(params, dem_rings);
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
			D_METHOD("ring_positions", "radii", "segs", "params", "dem_rings"),
			&FarKernels::ring_positions);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("ring_colors", "pos", "loops", "per", "params", "water"),
			&FarKernels::ring_colors);
}

} // namespace godot
