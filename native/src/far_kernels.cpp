#include "far_kernels.h"

#include "far_sampling.h"
#include "parallel.h"
#include "shore_kernels.h"

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>
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

PackedInt32Array FarKernels::band_indices(int loops, int per, bool has_skirt) {
	int64_t body_n = (int64_t)Math::max(loops - 1, 0) * per * 6;
	int64_t skirt_n = has_skirt ? (int64_t)per * 6 : 0;
	PackedInt32Array indices;
	indices.resize(body_n + skirt_n);
	int32_t *out = indices.ptrw();
	for (int k = 1; k < loops; k++) {
		int inner = (k - 1) * per;
		int outer = k * per;
		int64_t row = (int64_t)(k - 1) * per * 6;
		for (int j = 0; j < per; j++) {
			int j1 = (j + 1) % per;
			int64_t idx = row + (int64_t)j * 6;
			out[idx + 0] = outer + j;
			out[idx + 1] = outer + j1;
			out[idx + 2] = inner + j;
			out[idx + 3] = outer + j1;
			out[idx + 4] = inner + j1;
			out[idx + 5] = inner + j;
		}
	}
	if (has_skirt) {
		int edge = (loops - 1) * per;
		int base = loops * per;
		for (int j = 0; j < per; j++) {
			int j1 = (j + 1) % per;
			int64_t idx = body_n + (int64_t)j * 6;
			out[idx + 0] = edge + j;
			out[idx + 1] = base + j;
			out[idx + 2] = edge + j1;
			out[idx + 3] = edge + j1;
			out[idx + 4] = base + j;
			out[idx + 5] = base + j1;
		}
	}
	return indices;
}

Array FarKernels::band_drape_uvs(const PackedVector3Array &verts, const Dictionary &params,
		const Dictionary &fine, const Dictionary &coarse) {
	Far geo;
	geo.lat = params["lat"];
	geo.lon = params["lon"];
	geo.m2u = params["m2u"];
	const bool has_fine = !fine.is_empty();
	const bool has_coarse = !coarse.is_empty();
	double fine_n = 0.0, coarse_n = 0.0;
	Vector2 fine_origin, fine_size, coarse_origin, coarse_size;
	if (has_fine) {
		fine_n = (double)(1 << (int)fine["zoom"]) * 256.0;
		fine_origin = fine["origin_px"];
		Vector2i sz = fine["size_px"];
		fine_size = Vector2((float)sz.x, (float)sz.y);
	}
	if (has_coarse) {
		coarse_n = (double)(1 << (int)coarse["zoom"]) * 256.0;
		coarse_origin = coarse["origin_px"];
		Vector2i sz = coarse["size_px"];
		coarse_size = Vector2((float)sz.x, (float)sz.y);
	}
	const int64_t n = verts.size();
	PackedVector2Array uvs;
	PackedVector2Array uv2s;
	uvs.resize(n);
	uv2s.resize(n);
	const Vector3 *vp = verts.ptr();
	Vector2 *up = uvs.ptrw();
	Vector2 *u2p = uv2s.ptrw();
	parallel_for((int)n, [&](int i) {
		Vector3 v = vp[i];
		Vector2 uv = merc_uv(geo, (double)v.x / geo.m2u, (double)v.z / geo.m2u);
		if (has_fine) {
			Vector2 p(uv.x * fine_n, uv.y * fine_n);
			up[i] = (p - fine_origin) / fine_size;
		}
		if (has_coarse) {
			Vector2 p(uv.x * coarse_n, uv.y * coarse_n);
			u2p[i] = (p - coarse_origin) / coarse_size;
		}
	});
	Array out;
	out.push_back(uvs);
	out.push_back(uv2s);
	return out;
}

Array FarKernels::terrain_grid_sat(int size, double step, const PackedFloat32Array &post_heights,
		const Dictionary &params, const Array &drapes, Object *shore_domains) {
	const bool shore = params["shore"];
	const bool shore_empty = params["shore_empty"];
	const Rect2 shore_bounds = params["shore_bounds"];
	const double water_level_m = params["water_level_m"];
	const double datum_m = params["datum_m"];
	const double y_scale = params["y_scale"];
	const double lat = params["lat"];
	const double lon = params["lon"];
	const double m2u = params["m2u"];
	const int sat_zoom = params["sat_zoom"];
	const Vector2 sat_origin = params["sat_origin_px"];
	const double sat_mosaic_px = params["sat_mosaic_px"];
	const double sat_n = (double)(1 << sat_zoom) * 256.0;
	const double cos_lat = std::cos(Math::deg_to_rad(lat));
	const int gt_size = params["gt_size"];
	const double gt_step = params["gt_step_units"];
	const PackedFloat32Array gt_level = params["gt_level"];
	const float *gt_lv = gt_level.ptr();
	const int64_t gt_lv_n = gt_level.size();
	Climate cl;
	cl.tl = params["tl"];
	cl.sl = params["sl"];
	cl.forest = params["forest"];
	cl.meadow = params["meadow"];
	Far geo;
	geo.lat = lat;
	geo.lon = lon;
	geo.m2u = m2u;

	struct DrapeInfo {
		Ref<Image> img;
		int w = 0, h = 0;
		double n = 0.0;
		Vector2 origin, size;
	};
	std::vector<DrapeInfo> drape_list;
	for (int64_t i = 0; i < drapes.size(); i++) {
		Dictionary d = drapes[i];
		Ref<Image> img = d.get("image", Variant());
		if (img.is_null() || img->is_empty()) {
			continue;
		}
		DrapeInfo di;
		di.img = img;
		di.w = img->get_width();
		di.h = img->get_height();
		di.n = (double)(1 << (int)d["zoom"]) * 256.0;
		di.origin = d["origin_px"];
		Vector2i sz = d["size_px"];
		di.size = Vector2((float)sz.x, (float)sz.y);
		drape_list.push_back(di);
	}

	struct BodyInfo {
		double level = 0.0;
		bool has_end = false;
		double level_end = 0.0;
		Vector2 ax0, ax1;
	};
	std::vector<BodyInfo> bodies;
	const ShoreDomainIndex *dom = shore ? Object::cast_to<ShoreDomainIndex>(shore_domains) : nullptr;
	if (dom != nullptr) {
		Array sb = params["shore_bodies"];
		bodies.reserve(sb.size());
		for (int64_t i = 0; i < sb.size(); i++) {
			Dictionary b = sb[i];
			BodyInfo bi;
			bi.level = b["level"];
			if (b.has("level_end")) {
				bi.has_end = true;
				bi.level_end = b["level_end"];
				PackedVector2Array ax = b["axis"];
				if (ax.size() >= 2) {
					bi.ax0 = ax[0];
					bi.ax1 = ax[1];
				}
			}
			bodies.push_back(bi);
		}
	}

	auto body_level = [&](int id, const Vector2 &p) -> double {
		const BodyInfo &bi = bodies[id];
		if (!bi.has_end) {
			return bi.level;
		}
		Vector2 d = bi.ax1 - bi.ax0;
		double t = Math::clamp((double)(p - bi.ax0).dot(d) / Math::max((double)d.length_squared(), 0.0001), 0.0, 1.0);
		return Math::lerp(bi.level, bi.level_end, t);
	};

	auto grid_water_level = [&](double wx, double wz) -> double {
		if (gt_size < 2 || gt_lv_n != (int64_t)gt_size * gt_size) {
			return water_level_m;
		}
		double fx = Math::clamp(wx / gt_step + (double)gt_size * 0.5, 0.0, (double)(gt_size - 1));
		double fz = Math::clamp(wz / gt_step + (double)gt_size * 0.5, 0.0, (double)(gt_size - 1));
		int x0 = Math::min((int)fx, gt_size - 2);
		int z0 = Math::min((int)fz, gt_size - 2);
		double tx = fx - (double)x0;
		double tz = fz - (double)z0;
		double sum = 0.0;
		double wsum = 0.0;
		for (int k = 0; k < 4; k++) {
			int px = x0 + (k & 1);
			int pz = z0 + (k >> 1);
			double lv = gt_lv[(int64_t)pz * gt_size + px];
			if (!std::isnan(lv)) {
				double w = ((k & 1) ? tx : (1.0 - tx)) * ((k >> 1) ? tz : (1.0 - tz));
				sum += lv * w;
				wsum += w;
			}
		}
		return wsum > 0.0 ? sum / wsum : water_level_m;
	};

	const int64_t total = (int64_t)size * size;
	PackedVector3Array verts;
	PackedVector3Array normals;
	PackedColorArray colors;
	PackedFloat32Array tangents;
	PackedVector2Array uvs;
	PackedVector2Array water_levels;
	verts.resize(total);
	normals.resize(total);
	colors.resize(total);
	tangents.resize(total * 4);
	uvs.resize(total);
	water_levels.resize(total);

	const float *ph = post_heights.ptr();
	Vector3 *vp = verts.ptrw();
	Vector3 *np = normals.ptrw();
	Color *cp = colors.ptrw();
	float *tp = tangents.ptrw();
	Vector2 *up = uvs.ptrw();
	Vector2 *wlp = water_levels.ptrw();
	const double half_sz = (double)size * 0.5;
	constexpr double SNAP = 0.01;

	parallel_for(size, [&](int z) {
		int z0 = Math::max(0, z - 1);
		int z1 = Math::min(size - 1, z + 1);
		for (int x = 0; x < size; x++) {
			int64_t idx = (int64_t)z * size + x;
			double wx = ((double)x - half_sz) * step;
			double wz = ((double)z - half_sz) * step;
			if (shore) {
				Vector2 sn = Vector2(wx, wz).snapped(Vector2(SNAP, SNAP));
				wx = sn.x;
				wz = sn.y;
			}
			double h = ph[idx];
			vp[idx] = Vector3(wx, h, wz);

			double wl = water_level_m;
			double water_depth = 0.0;
			if (dom != nullptr) {
				Vector2 p2(wx, wz);
				int body = dom->at(p2);
				if (body >= 0 && body < (int)bodies.size()) {
					wl = body_level(body, p2);
					if (shore_bounds.has_point(p2)) {
						water_depth = Math::max(0.0, wl - h);
					}
				}
			} else {
				wl = grid_water_level(wx, wz);
				if (!shore_empty) {
					water_depth = Math::max(0.0, wl - h);
				}
			}
			wlp[idx] = Vector2(wl, 0.0);

			int x0 = Math::max(0, x - 1);
			int x1 = Math::min(size - 1, x + 1);
			double slope_x = ((double)ph[(int64_t)z * size + x1] - (double)ph[(int64_t)z * size + x0]) / (2.0 * step);
			double slope_z = ((double)ph[(int64_t)z1 * size + x] - (double)ph[(int64_t)z0 * size + x]) / (2.0 * step);
			Vector3 normal = Vector3(-slope_x, 1.0, -slope_z).normalized();
			np[idx] = normal;

			// FarTerrainBuilder.far_albedo_at_cached
			Color fc(0, 0, 0, 0);
			if (!drape_list.empty()) {
				Vector2 muv = merc_uv(geo, wx / m2u, wz / m2u);
				for (const DrapeInfo &di : drape_list) {
					Vector2 duv = (Vector2(muv.x * di.n, muv.y * di.n) - di.origin) / di.size;
					if (duv.x > 0.0f && duv.y > 0.0f && duv.x < 1.0f && duv.y < 1.0f) {
						int px = Math::clamp((int)(duv.x * (float)di.w), 0, di.w - 1);
						int py = Math::clamp((int)(duv.y * (float)di.h), 0, di.h - 1);
						Color sc = di.img->get_pixel(px, py).srgb_to_linear();
						fc = Color(Math::min((double)sc.r * 1.6, 0.85),
								Math::min((double)sc.g * 1.6, 0.85),
								Math::min((double)sc.b * 1.6, 0.85), 1.0);
						break;
					}
				}
			}
			if (fc.a <= 0.0f) {
				double h_asl = h / y_scale + datum_m;
				fc = ramp_color(cl, normal, h_asl, water_depth > 0.05, hash(wx * 1.3, wz * 1.7));
			}
			double s = 0.85 + 0.15 * Math::clamp((double)normal.y, 0.0, 1.0);
			cp[idx] = Color(fc.r, fc.g, fc.b, s);

			int64_t t4 = idx * 4;
			tp[t4 + 0] = 1.0f;
			tp[t4 + 1] = 0.0f;
			tp[t4 + 2] = 0.0f;
			tp[t4 + 3] = 1.0f;

			double slat = Math::clamp(lat - wz / 110540.0, -85.0, 85.0);
			double slon = lon + wx / (111320.0 * cos_lat);
			double spx = (slon + 180.0) / 360.0 * sat_n - (double)sat_origin.x;
			double spy = (1.0 - std::asinh(std::tan(Math::deg_to_rad(slat))) / Math::PI) / 2.0 * sat_n - (double)sat_origin.y;
			up[idx] = Vector2(spx / sat_mosaic_px, spy / sat_mosaic_px);
		}
	});

	PackedInt32Array indices;
	if (!shore) {
		int quads = size - 1;
		indices.resize((int64_t)quads * quads * 6);
		int32_t *ip = indices.ptrw();
		for (int z = 0; z < quads; z++) {
			for (int x = 0; x < quads; x++) {
				int a = z * size + x;
				int b = a + 1;
				int c = a + size;
				int d = c + 1;
				int64_t off = ((int64_t)z * quads + x) * 6;
				ip[off + 0] = a;
				ip[off + 1] = b;
				ip[off + 2] = c;
				ip[off + 3] = b;
				ip[off + 4] = d;
				ip[off + 5] = c;
			}
		}
	}

	Array out;
	out.push_back(verts);
	out.push_back(normals);
	out.push_back(colors);
	out.push_back(tangents);
	out.push_back(uvs);
	out.push_back(water_levels);
	out.push_back(indices);
	return out;
}

namespace {

struct ImpostorBatch {
	PackedVector3Array verts;
	PackedVector3Array norms;
	PackedInt32Array idx;
	PackedColorArray vcols;
	Color base_col;
	bool has_n = false;
	bool has_vc = false;
};

static inline void splat_segment(uint8_t *px, float *zbuf, int size,
		float ax, float ay, float za, float bx, float by, float zb,
		uint8_t cr, uint8_t cg, uint8_t cb) {
	float dx = bx - ax;
	float dy = by - ay;
	float dist = std::sqrt(dx * dx + dy * dy);
	int steps = std::min(std::max((int)std::ceil(dist), 1), size * 2);
	float inv_steps = 1.0f / (float)steps;
	for (int s = 0; s <= steps; s++) {
		float t = (float)s * inv_steps;
		int x = (int)std::llround(ax + dx * t);
		int y = (int)std::llround(ay + dy * t);
		if (x < 0 || x >= size || y < 0 || y >= size) {
			continue;
		}
		float z = za + (zb - za) * t;
		int di = y * size + x;
		if (z > zbuf[di]) {
			zbuf[di] = z;
			int o = di * 4;
			px[o + 0] = cr;
			px[o + 1] = cg;
			px[o + 2] = cb;
			px[o + 3] = 255;
		}
	}
}

static PackedByteArray rasterize_one_view(const std::vector<ImpostorBatch> &batches,
		const Vector3 &center, float y_top, float span_y,
		const Vector3 &out_normal, const Vector3 &right_axis, float half_w,
		const Vector3 &key_dir, int size) {
	PackedByteArray px_arr;
	px_arr.resize(size * size * 4);
	uint8_t *px = px_arr.ptrw();
	std::memset(px, 0, (size_t)size * (size_t)size * 4);
	std::vector<float> zbuf((size_t)size * (size_t)size, -std::numeric_limits<float>::infinity());
	float *zp = zbuf.data();

	const float inv_w = (float)(size - 1) / std::max(2.0f * half_w, 1e-3f);
	const float inv_h = (float)(size - 1) / std::max(span_y, 1e-3f);

	for (const ImpostorBatch &b : batches) {
		const Vector3 *vp = b.verts.ptr();
		const Vector3 *np = b.has_n ? b.norms.ptr() : nullptr;
		const int32_t *ip = b.idx.is_empty() ? nullptr : b.idx.ptr();
		const Color *cp = b.has_vc ? b.vcols.ptr() : nullptr;
		const int64_t count = ip != nullptr ? b.idx.size() : b.verts.size();
		const int64_t vcount = b.verts.size();

		for (int64_t t = 0; t + 2 < count; t += 3) {
			const int64_t ia = ip != nullptr ? ip[t] : t;
			const int64_t ib = ip != nullptr ? ip[t + 1] : t + 1;
			const int64_t ic = ip != nullptr ? ip[t + 2] : t + 2;
			if (ia < 0 || ib < 0 || ic < 0 || ia >= vcount || ib >= vcount || ic >= vcount) {
				continue;
			}
			const Vector3 va = vp[ia];
			const Vector3 vb = vp[ib];
			const Vector3 vc = vp[ic];
			const Vector3 da = va - center;
			const Vector3 db = vb - center;
			const Vector3 dc = vc - center;

			const float pax = (da.dot(right_axis) + half_w) * inv_w;
			const float pay = (y_top - va.y) * inv_h;
			const float pbx = (db.dot(right_axis) + half_w) * inv_w;
			const float pby = (y_top - vb.y) * inv_h;
			const float pcx = (dc.dot(right_axis) + half_w) * inv_w;
			const float pcy = (y_top - vc.y) * inv_h;

			const float za = da.dot(out_normal);
			const float zb = db.dot(out_normal);
			const float zc = dc.dot(out_normal);

			Vector3 fn;
			if (np != nullptr) {
				fn = (np[ia] + np[ib] + np[ic]).normalized();
			} else {
				fn = (vc - va).cross(vb - va).normalized();
			}
			if (fn.length_squared() < 1e-6f) {
				fn = out_normal;
			}
			const float shade = 0.76f + 0.24f * std::max(fn.dot(key_dir), 0.0f)
					+ 0.06f * std::max(fn.y, 0.0f);
			Color c = b.base_col;
			if (cp != nullptr) {
				const Color vc_avg = (cp[ia] + cp[ib] + cp[ic]) / 3.0f;
				c = Color(c.r * vc_avg.r, c.g * vc_avg.g, c.b * vc_avg.b);
			}
			const uint8_t cr = (uint8_t)std::clamp((int)std::llround(c.r * shade * 255.0f), 1, 255);
			const uint8_t cg = (uint8_t)std::clamp((int)std::llround(c.g * shade * 255.0f), 1, 255);
			const uint8_t cb = (uint8_t)std::clamp((int)std::llround(c.b * shade * 255.0f), 1, 255);

			const int min_x = std::max((int)std::floor(std::min(pax, std::min(pbx, pcx))), 0);
			const int max_x = std::min((int)std::ceil(std::max(pax, std::max(pbx, pcx))), size - 1);
			const int min_y = std::max((int)std::floor(std::min(pay, std::min(pby, pcy))), 0);
			const int max_y = std::min((int)std::ceil(std::max(pay, std::max(pby, pcy))), size - 1);
			if (min_x > max_x || min_y > max_y) {
				continue;
			}

			const float abx = pbx - pax;
			const float aby = pby - pay;
			const float acx = pcx - pax;
			const float acy = pcy - pay;
			const float area = abx * acy - aby * acx;

			if (std::fabs(area) >= 0.02f) {
				const float inv_area = 1.0f / area;
				const float bcx = pcx - pbx;
				const float bcy = pcy - pby;
				const float cax = pax - pcx;
				const float cay = pay - pcy;
				for (int y = min_y; y <= max_y; y++) {
					const float py_f = (float)y + 0.5f;
					const float row_base_y = (float)y * (float)size;
					(void)row_base_y;
					const int row = y * size;
					for (int x = min_x; x <= max_x; x++) {
						const float px_f = (float)x + 0.5f;
						const float w0 = (bcx * (py_f - pby) - bcy * (px_f - pbx)) * inv_area;
						const float w1 = (cax * (py_f - pcy) - cay * (px_f - pcx)) * inv_area;
						const float w2 = 1.0f - w0 - w1;
						if (w0 < -1e-4f || w1 < -1e-4f || w2 < -1e-4f) {
							continue;
						}
						const float z = za * w0 + zb * w1 + zc * w2;
						const int di = row + x;
						if (z > zp[di]) {
							zp[di] = z;
							const int o = di * 4;
							px[o + 0] = cr;
							px[o + 1] = cg;
							px[o + 2] = cb;
							px[o + 3] = 255;
						}
					}
				}
			}

			if (std::min(max_x - min_x, max_y - min_y) <= 1 || std::fabs(area) < 0.75f) {
				splat_segment(px, zp, size, pax, pay, za, pbx, pby, zb, cr, cg, cb);
				splat_segment(px, zp, size, pbx, pby, zb, pcx, pcy, zc, cr, cg, cb);
				splat_segment(px, zp, size, pcx, pcy, zc, pax, pay, za, cr, cg, cb);
			}
		}
	}
	return px_arr;
}

} // namespace

Array FarKernels::rasterize_impostor_views(const Array &batches_in, const Vector3 &center,
		double y_top, double span_y, double wx, double wz, const Vector3 &key_dir, int size) {
	Array out;
	if (size <= 0 || batches_in.is_empty()) {
		return out;
	}
	std::vector<ImpostorBatch> batches;
	batches.reserve(batches_in.size());
	for (int64_t i = 0; i < batches_in.size(); i++) {
		Dictionary d = batches_in[i];
		ImpostorBatch b;
		b.verts = d.get("v", PackedVector3Array());
		if (b.verts.size() < 3) {
			continue;
		}
		b.norms = d.get("n", PackedVector3Array());
		b.idx = d.get("idx", PackedInt32Array());
		b.vcols = d.get("cols", PackedColorArray());
		b.base_col = d.get("color", Color(0.66f, 0.63f, 0.58f));
		b.has_n = b.norms.size() == b.verts.size();
		b.has_vc = b.vcols.size() == b.verts.size();
		batches.push_back(std::move(b));
	}

	const Vector3 normals[4] = {
		Vector3(0.0f, 0.0f, -1.0f), Vector3(1.0f, 0.0f, 0.0f),
		Vector3(0.0f, 0.0f, 1.0f), Vector3(-1.0f, 0.0f, 0.0f)
	};
	const Vector3 rights[4] = {
		Vector3(-1.0f, 0.0f, 0.0f), Vector3(0.0f, 0.0f, -1.0f),
		Vector3(1.0f, 0.0f, 0.0f), Vector3(0.0f, 0.0f, 1.0f)
	};
	const float widths[4] = { (float)wx, (float)wz, (float)wx, (float)wz };

	for (int v_idx = 0; v_idx < 4; v_idx++) {
		out.push_back(rasterize_one_view(batches, center, (float)y_top, (float)span_y,
				normals[v_idx], rights[v_idx], widths[v_idx] * 0.5f, key_dir, size));
	}
	return out;
}

void FarKernels::_bind_methods() {
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("ring_positions", "radii", "segs", "params", "dem_rings"),
			&FarKernels::ring_positions);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("ring_colors", "pos", "loops", "per", "params", "water"),
			&FarKernels::ring_colors);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("band_indices", "loops", "per", "has_skirt"),
			&FarKernels::band_indices);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("band_drape_uvs", "verts", "params", "fine", "coarse"),
			&FarKernels::band_drape_uvs);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("terrain_grid_sat", "size", "step", "post_heights", "params", "drapes", "shore_domains"),
			&FarKernels::terrain_grid_sat);
	ClassDB::bind_static_method("FarKernels",
			D_METHOD("rasterize_impostor_views", "batches", "center", "y_top", "span_y", "wx", "wz", "key_dir", "size"),
			&FarKernels::rasterize_impostor_views);
}

} // namespace godot
