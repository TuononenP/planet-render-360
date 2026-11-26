#include "prop_kernels.h"

#include "parallel.h"
#include "shore_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/vector4.hpp>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <unordered_map>
#include <vector>

namespace godot {

namespace {

inline int64_t cell_key(int cx, int cz) {
	return (static_cast<int64_t>(cx) << 32) | static_cast<uint32_t>(cz);
}

inline double pk_hash(double x, double z, double salt) {
	const double v = std::sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453;
	return v - std::floor(v);
}

inline Vector2 closest_on_seg(const Vector2 &p, const Vector2 &a, const Vector2 &b) {
	const Vector2 ab = b - a;
	const float l2 = ab.length_squared();
	if (l2 <= 1e-12f) {
		return a;
	}
	const float t = std::clamp((p - a).dot(ab) / l2, 0.0f, 1.0f);
	return a + ab * t;
}

inline bool point_in_poly(const Vector2 &p, const std::vector<Vector2> &ring) {
	const int n = (int)ring.size();
	if (n < 3) {
		return false;
	}
	bool inside = false;
	for (int i = 0, j = n - 1; i < n; j = i++) {
		const Vector2 &a = ring[i];
		const Vector2 &b = ring[j];
		if (((a.y > p.y) != (b.y > p.y)) &&
				(p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x)) {
			inside = !inside;
		}
	}
	return inside;
}

struct PolyBox {
	std::vector<Vector2> pts;
	float min_x, min_z, max_x, max_z;
	bool contains(const Vector2 &p) const {
		if (p.x < min_x || p.x > max_x || p.y < min_z || p.y > max_z) {
			return false;
		}
		return point_in_poly(p, pts);
	}
};

PolyBox make_poly(const PackedVector2Array &arr) {
	PolyBox pb;
	const int n = arr.size();
	pb.pts.resize(n);
	if (n == 0) {
		pb.min_x = pb.max_x = pb.min_z = pb.max_z = 0.0f;
		return pb;
	}
	const Vector2 *ptr = arr.ptr();
	pb.min_x = pb.max_x = ptr[0].x;
	pb.min_z = pb.max_z = ptr[0].y;
	for (int i = 0; i < n; ++i) {
		pb.pts[i] = ptr[i];
		if (ptr[i].x < pb.min_x) pb.min_x = ptr[i].x;
		else if (ptr[i].x > pb.max_x) pb.max_x = ptr[i].x;
		if (ptr[i].y < pb.min_z) pb.min_z = ptr[i].y;
		else if (ptr[i].y > pb.max_z) pb.max_z = ptr[i].y;
	}
	return pb;
}

struct GroundCtx {
	const ShoreSampler *shore = nullptr;
	const ShoreDomainIndex *domains = nullptr;
	Rect2 shore_bounds;
	bool shore_empty = false;
	// Flattened shore body levels: 6 doubles per body [l0, l1_or_nan, ax0, az0, ax1, az1].
	const double *body_levels = nullptr;
	int body_count = 0;
	const float *surface = nullptr;
	const float *level = nullptr;
	int grid_size = 0;
	double step_units = 1.0;
	double half_units = 1200.0;
	double water_level_m = 0.0;

	double height(double x, double z) const {
		if (shore != nullptr) {
			const double cx = std::clamp(x, (double)shore_bounds.position.x, (double)(shore_bounds.position.x + shore_bounds.size.x));
			const double cz = std::clamp(z, (double)shore_bounds.position.y, (double)(shore_bounds.position.y + shore_bounds.size.y));
			return shore->height(cx, cz);
		}
		if (grid_size < 2 || surface == nullptr) {
			return water_level_m;
		}
		const double fx = std::clamp(x / step_units + (double)grid_size * 0.5, 0.0, (double)(grid_size - 1));
		const double fz = std::clamp(z / step_units + (double)grid_size * 0.5, 0.0, (double)(grid_size - 1));
		const int x0 = std::min((int)fx, grid_size - 2);
		const int z0 = std::min((int)fz, grid_size - 2);
		const double tx = fx - (double)x0;
		const double tz = fz - (double)z0;
		const double a = Math::lerp((double)surface[z0 * grid_size + x0], (double)surface[z0 * grid_size + x0 + 1], tx);
		const double b = Math::lerp((double)surface[(z0 + 1) * grid_size + x0], (double)surface[(z0 + 1) * grid_size + x0 + 1], tx);
		return Math::lerp(a, b, tz);
	}

	double water_at(double x, double z) const {
		if (shore_empty) {
			return 0.0;
		}
		const Vector2 p((float)x, (float)z);
		if (shore != nullptr && domains != nullptr && shore_bounds.has_point(p)) {
			const int body = domains->at(p);
			if (body < 0 || body >= body_count) {
				return 0.0;
			}
			const double *bl = body_levels + body * 6;
			double lvl = bl[0];
			if (!std::isnan(bl[1])) {
				const Vector2 a0((float)bl[2], (float)bl[3]);
				const Vector2 a1((float)bl[4], (float)bl[5]);
				const Vector2 d = a1 - a0;
				const float t = std::clamp((p - a0).dot(d) / std::max(d.length_squared(), 0.0001f), 0.0f, 1.0f);
				lvl = Math::lerp(bl[0], bl[1], (double)t);
			}
			return std::max(0.0, lvl - height(x, z));
		}
		// Fallback non-shoreline water_level_at: weighted _level around post, else water_level_m.
		double wl = water_level_m;
		if (grid_size >= 2 && level != nullptr) {
			const double fx = std::clamp(x / step_units + (double)grid_size * 0.5, 0.0, (double)(grid_size - 1));
			const double fz = std::clamp(z / step_units + (double)grid_size * 0.5, 0.0, (double)(grid_size - 1));
			const int x0 = std::min((int)fx, grid_size - 2);
			const int z0 = std::min((int)fz, grid_size - 2);
			const double tx = fx - (double)x0;
			const double tz = fz - (double)z0;
			const double ws[4] = { (1.0 - tx) * (1.0 - tz), tx * (1.0 - tz), (1.0 - tx) * tz, tx * tz };
			const int idxs[4] = { z0 * grid_size + x0, z0 * grid_size + x0 + 1, (z0 + 1) * grid_size + x0, (z0 + 1) * grid_size + x0 + 1 };
			double num = 0.0, den = 0.0;
			for (int k = 0; k < 4; ++k) {
				const float lv = level[idxs[k]];
				if (!std::isinf(lv)) {
					num += (double)lv * ws[k];
					den += ws[k];
				}
			}
			if (den > 0.0) {
				wl = num / den;
			}
		}
		return std::max(0.0, wl - height(x, z));
	}
};

GroundCtx read_ground_ctx(const Dictionary &params, PackedFloat32Array &surf_hold, PackedFloat32Array &lvl_hold,
		PackedFloat64Array &body_hold) {
	GroundCtx g;
	g.shore = Object::cast_to<ShoreSampler>(Object::cast_to<Object>(params.get("shore_sampler", Variant())));
	g.domains = Object::cast_to<ShoreDomainIndex>(Object::cast_to<Object>(params.get("shore_domains", Variant())));
	g.shore_bounds = params.get("shore_bounds", Rect2());
	g.shore_empty = (bool)params.get("shore_empty", false);
	body_hold = params.get("body_levels", PackedFloat64Array());
	g.body_levels = body_hold.ptr();
	g.body_count = body_hold.size() / 6;
	surf_hold = params.get("surface", PackedFloat32Array());
	lvl_hold = params.get("level", PackedFloat32Array());
	g.grid_size = (int)params.get("grid_size", 0);
	g.step_units = (double)params.get("step_units", 1.0);
	g.half_units = (double)params.get("half_units", 1200.0);
	g.water_level_m = (double)params.get("water_level_m", 0.0);
	g.surface = (g.grid_size >= 2 && surf_hold.size() == g.grid_size * g.grid_size) ? surf_hold.ptr() : nullptr;
	g.level = (g.grid_size >= 2 && lvl_hold.size() == g.grid_size * g.grid_size) ? lvl_hold.ptr() : nullptr;
	return g;
}

struct Seg5 {
	Vector2 a, b;
	float r;
};

struct MeshBuf {
	std::vector<Vector3> verts;
	std::vector<Vector3> normals;
	std::vector<Vector2> uvs;
	std::vector<Color> colors;
	std::vector<int32_t> idx;

	void card(const Vector3 c[4], const Vector3 &n, const float ao[4], const Vector2 uv[4]) {
		const int32_t base = (int32_t)verts.size();
		for (int i = 0; i < 4; ++i) {
			verts.push_back(c[i]);
			normals.push_back(n);
			uvs.push_back(uv[i]);
			colors.emplace_back(ao[i], ao[i], ao[i], 1.0f);
		}
		idx.push_back(base);
		idx.push_back(base + 1);
		idx.push_back(base + 2);
		idx.push_back(base);
		idx.push_back(base + 2);
		idx.push_back(base + 3);
	}

	void append(const MeshBuf &o) {
		if (o.idx.empty()) {
			return;
		}
		const int32_t base = (int32_t)verts.size();
		verts.insert(verts.end(), o.verts.begin(), o.verts.end());
		normals.insert(normals.end(), o.normals.begin(), o.normals.end());
		uvs.insert(uvs.end(), o.uvs.begin(), o.uvs.end());
		colors.insert(colors.end(), o.colors.begin(), o.colors.end());
		const size_t old_n = idx.size();
		idx.resize(old_n + o.idx.size());
		for (size_t i = 0; i < o.idx.size(); ++i) {
			idx[old_n + i] = o.idx[i] + base;
		}
	}
};

void wall_piece(MeshBuf &b, const Vector2 &p0, const Vector2 &p1, float y0, float y1,
		float h, float t, float sink, float m2u, float h1 = -1.0f) {
	const Vector2 d = p1 - p0;
	const float ln = d.length();
	if (ln < 0.0001f) {
		return;
	}
	const Vector2 n2 = Vector2(-d.y, d.x) / ln * (t * 0.5f);
	const Vector3 n3 = Vector3(n2.x, 0.0f, n2.y).normalized();
	const Vector3 a(p0.x, y0 - sink, p0.y);
	const Vector3 c(p1.x, y1 - sink, p1.y);
	const Vector3 up(0.0f, h + sink, 0.0f);
	const Vector3 up1 = (h1 < 0.0f) ? up : Vector3(0.0f, h1 + sink, 0.0f);
	const Vector3 o(n2.x, 0.0f, n2.y);
	const float u1 = ln / m2u / 2.0f;
	const float v1 = (h + sink) / m2u / 2.0f;
	const float v2 = (h1 < 0.0f) ? v1 : (h1 + sink) / m2u / 2.0f;
	const Vector2 uvs[4] = { Vector2(0.0f, 0.0f), Vector2(u1, 0.0f), Vector2(u1, v2), Vector2(0.0f, v1) };
	const float ao_side[4] = { 1.0f, 1.0f, 0.75f, 0.75f };
	const Vector3 c1[4] = { a + o + up, c + o + up1, c + o, a + o };
	b.card(c1, n3, ao_side, uvs);
	const Vector3 c2[4] = { c - o + up1, a - o + up, a - o, c - o };
	b.card(c2, -n3, ao_side, uvs);
	const float tu = t / m2u / 2.0f;
	const Vector2 uv_top[4] = { Vector2(0.0f, 0.0f), Vector2(u1, 0.0f), Vector2(u1, tu), Vector2(0.0f, tu) };
	const float ao_top[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
	const Vector3 c3[4] = { a - o + up, c - o + up1, c + o + up1, a + o + up };
	b.card(c3, Vector3(0.0f, 1.0f, 0.0f), ao_top, uv_top);
}

void fence_piece(MeshBuf &b, const Vector2 &p0, const Vector2 &p1, float y0, float y1, float h, float m2u) {
	const float ln = p0.distance_to(p1);
	if (ln < 0.0001f) {
		return;
	}
	const Vector2 d = (p1 - p0) / ln;
	const Vector3 n3(-d.y, 0.0f, d.x);
	const Vector3 a(p0.x, y0, p0.y);
	const Vector3 c(p1.x, y1, p1.y);
	const Vector3 up(0.0f, h, 0.0f);
	const float u1 = ln / m2u / 1.5f;
	const Vector3 pts[4] = { a + up, c + up, c, a };
	const float ao[4] = { 1.0f, 1.0f, 0.8f, 0.8f };
	const Vector2 uvs[4] = { Vector2(0.0f, 0.0f), Vector2(u1, 0.0f), Vector2(u1, 1.0f), Vector2(0.0f, 1.0f) };
	b.card(pts, n3, ao, uvs);
}

} // namespace

Dictionary PropKernels::parked_cars_plan(const Dictionary &params) {
	PackedFloat32Array surf_hold, lvl_hold;
	PackedFloat64Array body_hold;
	const GroundCtx g = read_ground_ctx(params, surf_hold, lvl_hold, body_hold);

	const Vector2 centre = params.get("centre", Vector2());
	const double r2 = (double)params.get("r2", 0.0);
	const double m2u = (double)params.get("m2u", 1.0);
	const bool left_traffic = (bool)params.get("left_traffic", false);
	const int max_cars = (int)params.get("max_cars", 1500);
	const double slot_u = 6.0 * m2u;
	const double cut_u = 9.0 * m2u;
	const double junc_cell = (double)params.get("junc_cell", 32.0);
	const double obs_cell = 6.0 * m2u;
	const double bldg_cell = 24.0 * m2u;
	const double road_pad = (320.0 + 25.0) * m2u;
	const float min_x = (float)((double)centre.x - road_pad);
	const float max_x = (float)((double)centre.x + road_pad);
	const float min_z = (float)((double)centre.y - road_pad);
	const float max_z = (float)((double)centre.y + road_pad);

	// Spatial hash junctions.
	const PackedVector2Array junc_pts = params.get("junc_pts", PackedVector2Array());
	std::unordered_map<int64_t, std::vector<Vector2>> junc_grid;
	junc_grid.reserve(junc_pts.size());
	for (int i = 0; i < junc_pts.size(); ++i) {
		const Vector2 &p = junc_pts[i];
		junc_grid[cell_key((int)std::floor((double)p.x / junc_cell), (int)std::floor((double)p.y / junc_cell))].push_back(p);
	}

	// Spatial hash obstacles.
	const PackedFloat32Array obs_raw = params.get("obs_segs", PackedFloat32Array());
	const int obs_n = obs_raw.size() / 5;
	std::vector<Seg5> obs_segs(obs_n);
	std::unordered_map<int64_t, std::vector<int>> obs_grid;
	const float *op = obs_raw.ptr();
	for (int i = 0; i < obs_n; ++i) {
		const Vector2 a(op[i * 5 + 0], op[i * 5 + 1]);
		const Vector2 b(op[i * 5 + 2], op[i * 5 + 3]);
		const float rad = op[i * 5 + 4];
		obs_segs[i] = { a, b, rad };
		const int x0 = (int)std::floor((double)(std::min(a.x, b.x) - rad) / obs_cell);
		const int x1 = (int)std::floor((double)(std::max(a.x, b.x) + rad) / obs_cell);
		const int z0 = (int)std::floor((double)(std::min(a.y, b.y) - rad) / obs_cell);
		const int z1 = (int)std::floor((double)(std::max(a.y, b.y) + rad) / obs_cell);
		for (int cx = x0; cx <= x1; ++cx) {
			for (int cz = z0; cz <= z1; ++cz) {
				obs_grid[cell_key(cx, cz)].push_back(i);
			}
		}
	}

	// Spatial hash building footprints.
	const Array bldg_arr = params.get("bldg_rings", Array());
	const int bldg_n = bldg_arr.size();
	std::vector<PolyBox> bldgs;
	bldgs.reserve(bldg_n);
	std::unordered_map<int64_t, std::vector<int>> bldg_grid;
	for (int i = 0; i < bldg_n; ++i) {
		PolyBox pb = make_poly(bldg_arr[i]);
		if (pb.pts.size() < 3) {
			continue;
		}
		const int bi = (int)bldgs.size();
		const int x0 = (int)std::floor((double)pb.min_x / bldg_cell);
		const int x1 = (int)std::floor((double)pb.max_x / bldg_cell);
		const int z0 = (int)std::floor((double)pb.min_z / bldg_cell);
		const int z1 = (int)std::floor((double)pb.max_z / bldg_cell);
		bldgs.push_back(std::move(pb));
		for (int cx = x0; cx <= x1; ++cx) {
			for (int cz = z0; cz <= z1; ++cz) {
				bldg_grid[cell_key(cx, cz)].push_back(bi);
			}
		}
	}

	// Fleet profile.
	const Dictionary fleet = params.get("fleet", Dictionary());
	const double taxi_share = (double)fleet.get("taxi_share", 0.04);
	const double sports_share = (double)fleet.get("sports_share", 0.02);
	const int taxi_kind_idx = (int)fleet.get("taxi_kind_idx", 0);
	const int sports_kind_idx = (int)fleet.get("sports_kind_idx", 0);
	const int tuk_kind_idx = (int)fleet.get("tuk_kind_idx", -1);
	const PackedInt32Array fleet_kinds = fleet.get("fleet_kinds", PackedInt32Array());
	const PackedFloat32Array kind_lens = fleet.get("kind_lens", PackedFloat32Array());
	const PackedFloat32Array kind_widths = fleet.get("kind_widths", PackedFloat32Array());
	const PackedColorArray paints = fleet.get("paint", PackedColorArray());
	const PackedColorArray taxi_paints = fleet.get("taxi_paint", PackedColorArray());
	const PackedColorArray sports_paints = fleet.get("sports_paint", PackedColorArray());
	const PackedColorArray tuk_paints = fleet.get("tuk_paint", PackedColorArray());

	struct RoadIn {
		std::vector<Vector2> pts;
		float off_l, off_r;
		int sides, oneway;
	};
	const Array roads_arr = params.get("roads", Array());
	const int rn = roads_arr.size();
	std::vector<RoadIn> roads(rn);
	for (int i = 0; i < rn; ++i) {
		const Array r = roads_arr[i];
		const PackedVector2Array pts = r[0];
		roads[i].pts.assign(pts.ptr(), pts.ptr() + pts.size());
		roads[i].off_l = (float)r[1];
		roads[i].off_r = (float)r[2];
		roads[i].sides = (int)r[3];
		roads[i].oneway = (int)r[4];
	}

	auto near_junc = [&](const Vector2 &p) -> bool {
		const int cx = (int)std::floor((double)p.x / junc_cell);
		const int cz = (int)std::floor((double)p.y / junc_cell);
		for (int dx = -1; dx <= 1; ++dx) {
			for (int dz = -1; dz <= 1; ++dz) {
				auto it = junc_grid.find(cell_key(cx + dx, cz + dz));
				if (it == junc_grid.end()) continue;
				for (const Vector2 &q : it->second) {
					if ((double)q.distance_to(p) < cut_u) return true;
				}
			}
		}
		return false;
	};

	auto is_blocked = [&](const Vector2 &p) -> bool {
		const int cx = (int)std::floor((double)p.x / obs_cell);
		const int cz = (int)std::floor((double)p.y / obs_cell);
		for (int dx = -1; dx <= 1; ++dx) {
			for (int dz = -1; dz <= 1; ++dz) {
				auto it = obs_grid.find(cell_key(cx + dx, cz + dz));
				if (it == obs_grid.end()) continue;
				for (int oi : it->second) {
					const Seg5 &s = obs_segs[oi];
					const Vector2 q = (s.a != s.b) ? closest_on_seg(p, s.a, s.b) : s.a;
					if (p.distance_to(q) < s.r) return true;
				}
			}
		}
		return false;
	};

	auto in_building = [&](const Vector2 &q, const Vector2 &fw, float len, float wid) -> bool {
		if (bldgs.empty()) return false;
		const Vector2 side(-fw.y, fw.x);
		const Vector2 test_pts[9] = {
			q,
			q - fw * (len * 0.5f) - side * (wid * 0.5f),
			q - fw * (len * 0.5f) + side * (wid * 0.5f),
			q - side * (wid * 0.5f),
			q + side * (wid * 0.5f),
			q + fw * (len * 0.5f) - side * (wid * 0.5f),
			q + fw * (len * 0.5f) + side * (wid * 0.5f),
			q + fw * (len * 0.5f),
			q - fw * (len * 0.5f),
		};
		for (int k = 0; k < 9; ++k) {
			const Vector2 &tp = test_pts[k];
			auto it = bldg_grid.find(cell_key((int)std::floor((double)tp.x / bldg_cell), (int)std::floor((double)tp.y / bldg_cell)));
			if (it == bldg_grid.end()) continue;
			for (int bi : it->second) {
				if (bldgs[bi].contains(tp)) return true;
			}
		}
		return false;
	};

	struct CarOut {
		Vector3 pos;
		Basis basis;
		int kind_idx;
		Color col;
		Color finish;
		float d2;
	};

	std::vector<std::vector<CarOut>> per_road(rn);
	const int fk_n = fleet_kinds.size();
	const int32_t *fk_ptr = fleet_kinds.ptr();
	const float *kl_ptr = kind_lens.ptr();
	const float *kw_ptr = kind_widths.ptr();
	const double deg12 = Math::deg_to_rad(1.2);

	parallel_for(rn, [&](int ri) {
		const RoadIn &rd = roads[ri];
		auto &dst = per_road[ri];
		const int pn = (int)rd.pts.size();
		for (int pass = 0; pass < 2; ++pass) {
			const int bit = (pass == 0) ? 1 : 2;
			if ((rd.sides & bit) == 0) continue;
			const float off = (pass == 0) ? rd.off_l : rd.off_r;
			for (int i = 0; i < pn - 1; ++i) {
				const Vector2 &a = rd.pts[i];
				const Vector2 &b = rd.pts[i + 1];
				if (std::max(a.x, b.x) < min_x || std::min(a.x, b.x) > max_x ||
						std::max(a.y, b.y) < min_z || std::min(a.y, b.y) > max_z) {
					continue;
				}
				const float seg_len = a.distance_to(b);
				if ((double)seg_len < slot_u) continue;
				const Vector2 dir = (b - a) / seg_len;
				const Vector2 left(dir.y, -dir.x);
				const int slots = (int)((double)seg_len / slot_u);
				for (int k = 0; k < slots; ++k) {
					const float t = ((float)k + 0.5f) * seg_len / (float)slots;
					const Vector2 p = a + dir * t + left * off;
					const float d2 = (p - centre).length_squared();
					if ((double)d2 > r2 || near_junc(p)) continue;
					if (pk_hash(p.x, p.y, 1.3) > 0.78) continue;
					if (is_blocked(p) || g.water_at(p.x, p.y) > 0.0) continue;
					// CarFleet.pick
					const bool is_taxi = pk_hash(p.x, p.y, 9.1) < taxi_share;
					const bool is_sports = !is_taxi && pk_hash(p.x, p.y, 10.7) < sports_share;
					int kidx = taxi_kind_idx;
					if (is_taxi) {
						kidx = taxi_kind_idx;
					} else if (is_sports) {
						kidx = sports_kind_idx;
					} else if (fk_n > 0) {
						kidx = fk_ptr[((int)(pk_hash(p.x, p.y, 2.7) * (double)fk_n)) % fk_n];
					}
					const PackedColorArray *pal = &paints;
					if (is_taxi && taxi_paints.size() > 0) pal = &taxi_paints;
					else if (is_sports && sports_paints.size() > 0) pal = &sports_paints;
					else if (kidx == tuk_kind_idx && tuk_paints.size() > 0) pal = &tuk_paints;
					const Color col = (pal->size() > 0)
							? (*pal)[((int)(pk_hash(p.x, p.y, 4.9) * (double)pal->size())) % pal->size()]
							: Color(0.5f, 0.5f, 0.5f, 1.0f);
					const float v_col = std::max(col.r, std::max(col.g, col.b));
					const bool solid_shade = (v_col > 0.8f || v_col < 0.05f);
					const double mshare = is_taxi ? 0.0 : (solid_shade ? 0.25 : 0.85);
					const float metallic = (pk_hash(p.x, p.y, 5.3) < mshare) ? 1.0f : 0.0f;
					const Color finish(metallic, (float)(0.2 + 0.65 * pk_hash(p.x, p.y, 8.2)), 0.0f, 0.0f);

					const float car_len = kl_ptr[kidx] * (float)m2u;
					const float car_wid = kw_ptr[kidx] * (float)m2u;
					Vector2 base_fw;
					if (rd.oneway != 0) {
						base_fw = dir * (float)(rd.oneway > 0 ? 1 : -1);
					} else {
						base_fw = ((off < 0.0f) != left_traffic) ? dir : -dir;
					}
					const float jitter_rad = (float)(deg12 * (pk_hash(p.x, p.y, 6.1) * 2.0 - 1.0));
					const Vector2 fw = base_fw.rotated(jitter_rad);
					const Vector2 q = p + left * (float)(0.1 * m2u * (pk_hash(p.x, p.y, 7.3) * 2.0 - 1.0));
					if (in_building(q, fw, car_len, car_wid)) continue;
					const Vector2 front = q + fw * (car_len * 0.4f);
					const Vector2 back = q - fw * (car_len * 0.4f);
					const float yf = (float)g.height(front.x, front.y);
					const float yb = (float)g.height(back.x, back.y);
					const Vector3 forward = Vector3(fw.x * car_len * 0.8f, yf - yb, fw.y * car_len * 0.8f).normalized();
					const Vector2 across = Vector2(-fw.y, fw.x) * (float)(0.8 * m2u);
					const float yl = (float)g.height(q.x + across.x, q.y + across.y);
					const float yr = (float)g.height(q.x - across.x, q.y - across.y);
					const Vector3 lean = Vector3(across.x * 2.0f, yl - yr, across.y * 2.0f).normalized();
					Vector3 up = lean.cross(forward).normalized();
					if (up.y < 0.0f) up = -up;
					const Basis basis(forward, up, forward.cross(up));
					const Vector3 pos(q.x, (yf + yb) * 0.5f + (float)(0.04 * m2u), q.y);
					const Vector3 sz(
							(float)(1.0 + 0.03 * (pk_hash(p.x, p.y, 3.4) * 2.0 - 1.0)) * (float)m2u,
							(float)(1.0 + 0.02 * (pk_hash(p.x, p.y, 3.9) * 2.0 - 1.0)) * (float)m2u,
							(float)m2u);
					dst.push_back({ pos, basis * Basis::from_scale(sz), kidx, col, finish, d2 });
				}
			}
		}
	});

	std::vector<CarOut> all;
	for (auto &v : per_road) {
		all.insert(all.end(), v.begin(), v.end());
	}
	std::stable_sort(all.begin(), all.end(), [](const CarOut &a, const CarOut &b) {
		return a.d2 < b.d2;
	});
	if ((int)all.size() > max_cars) {
		all.resize(max_cars);
	}

	const int cn = (int)all.size();
	PackedVector3Array pos_a, bx_a, by_a, bz_a;
	PackedInt32Array kind_a;
	PackedColorArray col_a, fin_a;
	PackedFloat32Array d2_a;
	pos_a.resize(cn); bx_a.resize(cn); by_a.resize(cn); bz_a.resize(cn);
	kind_a.resize(cn); col_a.resize(cn); fin_a.resize(cn); d2_a.resize(cn);
	for (int i = 0; i < cn; ++i) {
		pos_a[i] = all[i].pos;
		bx_a[i] = all[i].basis.get_column(0);
		by_a[i] = all[i].basis.get_column(1);
		bz_a[i] = all[i].basis.get_column(2);
		kind_a[i] = all[i].kind_idx;
		col_a[i] = all[i].col;
		fin_a[i] = all[i].finish;
		d2_a[i] = all[i].d2;
	}
	Dictionary out;
	out["pos"] = pos_a;
	out["bx"] = bx_a;
	out["by"] = by_a;
	out["bz"] = bz_a;
	out["kind"] = kind_a;
	out["col"] = col_a;
	out["finish"] = fin_a;
	out["d2"] = d2_a;
	return out;
}

Dictionary PropKernels::barriers_build(const Dictionary &params) {
	PackedFloat32Array surf_hold, lvl_hold;
	PackedFloat64Array body_hold;
	const GroundCtx g = read_ground_ctx(params, surf_hold, lvl_hold, body_hold);

	const double m2u = (double)params.get("m2u", 1.0);
	const float m2uf = (float)m2u;
	const float piece = 3.0f * m2uf;
	const double road_cell = 32.0 * m2u;

	// Road grid.
	const PackedFloat32Array road_raw = params.get("road_segs", PackedFloat32Array());
	const int rseg_n = road_raw.size() / 5;
	std::vector<Seg5> rsegs(rseg_n);
	std::unordered_map<int64_t, std::vector<int>> road_grid;
	const float *rp = road_raw.ptr();
	for (int i = 0; i < rseg_n; ++i) {
		const Vector2 a(rp[i * 5 + 0], rp[i * 5 + 1]);
		const Vector2 b(rp[i * 5 + 2], rp[i * 5 + 3]);
		const float half = rp[i * 5 + 4];
		rsegs[i] = { a, b, half };
		const int x0 = (int)std::floor((double)(std::min(a.x, b.x) - half) / road_cell);
		const int x1 = (int)std::floor((double)(std::max(a.x, b.x) + half) / road_cell);
		const int z0 = (int)std::floor((double)(std::min(a.y, b.y) - half) / road_cell);
		const int z1 = (int)std::floor((double)(std::max(a.y, b.y) + half) / road_cell);
		for (int cx = x0; cx <= x1; ++cx) {
			for (int cz = z0; cz <= z1; ++cz) {
				road_grid[cell_key(cx, cz)].push_back(i);
			}
		}
	}

	// Stair & bridge deck polygons.
	auto read_polys = [](const Array &arr) {
		std::vector<PolyBox> out;
		out.reserve(arr.size());
		for (int i = 0; i < arr.size(); ++i) {
			PolyBox pb = make_poly(arr[i]);
			if (pb.pts.size() >= 3) out.push_back(std::move(pb));
		}
		return out;
	};
	const std::vector<PolyBox> stairs = read_polys(params.get("stair_rings", Array()));
	const std::vector<PolyBox> decks = read_polys(params.get("deck_rings", Array()));

	// Model rects: 6 floats each [cx, cz, ax, az, half_a, half_c].
	const PackedFloat32Array mrects = params.get("model_rects", PackedFloat32Array());
	const int mrect_n = mrects.size() / 6;
	const float *mrp = mrects.ptr();

	// Quay wall segments: 4 floats each [ax, az, bx, bz].
	const PackedFloat32Array qsegs = params.get("quay_segs", PackedFloat32Array());
	const int qseg_n = qsegs.size() / 4;
	const float *qsp = qsegs.ptr();
	const float quay_reach = 1.5f * m2uf;

	struct BarrierIn {
		std::vector<Vector2> pts;
		int kind; // 0=wall, 1=fence, 2=chain_link, 3=wood_fence, 4=hedge
		float hgt, thick;
		bool retaining, tagged_h;
	};
	const Array barr_arr = params.get("barriers", Array());
	const int bn = barr_arr.size();
	std::vector<BarrierIn> barriers(bn);
	for (int i = 0; i < bn; ++i) {
		const Array b = barr_arr[i];
		const PackedVector2Array pts = b[0];
		barriers[i].pts.assign(pts.ptr(), pts.ptr() + pts.size());
		barriers[i].kind = (int)b[1];
		barriers[i].hgt = (float)b[2];
		barriers[i].thick = (float)b[3];
		barriers[i].retaining = (bool)b[4];
		barriers[i].tagged_h = (bool)b[5];
	}

	auto on_road = [&](const Vector2 &p) -> bool {
		auto it = road_grid.find(cell_key((int)std::floor((double)p.x / road_cell), (int)std::floor((double)p.y / road_cell)));
		if (it == road_grid.end()) return false;
		for (int ri : it->second) {
			const Seg5 &s = rsegs[ri];
			if (p.distance_to(closest_on_seg(p, s.a, s.b)) < s.r) return true;
		}
		return false;
	};
	auto in_polys = [](const Vector2 &p, const std::vector<PolyBox> &ps) -> bool {
		for (const PolyBox &pb : ps) {
			if (pb.contains(p)) return true;
		}
		return false;
	};
	auto in_mrects = [&](const Vector2 &p) -> bool {
		for (int i = 0; i < mrect_n; ++i) {
			const float *r = mrp + i * 6;
			const Vector2 d(p.x - r[0], p.y - r[1]);
			const Vector2 a(r[2], r[3]);
			const Vector2 cr(-a.y, a.x);
			if (std::abs(d.dot(a)) <= r[4] && std::abs(d.dot(cr)) <= r[5]) return true;
		}
		return false;
	};
	auto near_quay = [&](const Vector2 &p) -> bool {
		for (int i = 0; i < qseg_n; ++i) {
			const float *q = qsp + i * 4;
			const Vector2 a(q[0], q[1]), b(q[2], q[3]);
			if (p.distance_to(closest_on_seg(p, a, b)) <= quay_reach) return true;
		}
		return false;
	};

	const int chunks = std::min(std::max(1, bn), 16);
	std::vector<std::array<MeshBuf, 6>> chunk_bufs(chunks);
	std::vector<double> chunk_m(chunks, 0.0);

	parallel_for(chunks, [&](int c) {
		const int i0 = (bn * c) / chunks;
		const int i1 = (bn * (c + 1)) / chunks;
		auto &bufs = chunk_bufs[c];
		double tm = 0.0;
		for (int bi = i0; bi < i1; ++bi) {
			const BarrierIn &br = barriers[bi];
			const int pn = (int)br.pts.size();
			float hgt_cur = br.hgt;
			for (int i = 0; i < pn - 1; ++i) {
				const Vector2 &a = br.pts[i];
				const Vector2 &b = br.pts[i + 1];
				const float seg = a.distance_to(b);
				const int nseg = std::max((int)std::ceil(seg / piece), 1);
				for (int k = 0; k < nseg; ++k) {
					const Vector2 p0 = a.lerp(b, (float)k / (float)nseg);
					const Vector2 p1 = a.lerp(b, (float)(k + 1) / (float)nseg);
					if (std::abs((double)p0.x) > g.half_units || std::abs((double)p0.y) > g.half_units) continue;
					if (g.water_at(p0.x, p0.y) > 0.0 || g.water_at(p1.x, p1.y) > 0.0) continue;
					const Vector2 mid = (p0 + p1) * 0.5f;
					if (on_road(mid) || in_polys(mid, stairs)) continue;
					if (in_mrects(mid)) continue;
					if (in_polys(p0, decks) || in_polys(p1, decks)) continue;
					if (qseg_n > 0 && near_quay(mid)) continue;
					if (br.retaining && g.shore != nullptr) {
						const Vector4 nb = g.shore->nearest_bank(mid, 1);
						if (!std::isnan(nb.w) && nb.w >= 0.0f && nb.w <= 3.0f * m2uf) continue;
					}
					float y0 = (float)g.height(p0.x, p0.y);
					float y1 = (float)g.height(p1.x, p1.y);
					if (br.kind == 1 || br.kind == 2) {
						const Vector2 side = (p1 - p0).orthogonal().normalized() * (1.5f * m2uf);
						const float l0 = (float)g.height(p0.x + side.x, p0.y + side.y);
						const float r0 = (float)g.height(p0.x - side.x, p0.y - side.y);
						const float l1 = (float)g.height(p1.x + side.x, p1.y + side.y);
						const float r1 = (float)g.height(p1.x - side.x, p1.y - side.y);
						if (std::max(std::abs(l0 - r0), std::abs(l1 - r1)) > 0.4f * m2uf) {
							y0 = std::max(std::max(l0, r0), y0);
							y1 = std::max(std::max(l1, r1), y1);
						}
					}
					float h1 = -1.0f;
					if (br.retaining && !br.tagged_h) {
						const Vector2 side = (p1 - p0).orthogonal().normalized() * (2.0f * m2uf);
						const float l0 = (float)g.height(p0.x + side.x, p0.y + side.y);
						const float r0 = (float)g.height(p0.x - side.x, p0.y - side.y);
						const float l1 = (float)g.height(p1.x + side.x, p1.y + side.y);
						const float r1 = (float)g.height(p1.x - side.x, p1.y - side.y);
						const float b0 = std::min(l0, r0), t0 = std::max(l0, r0) + 0.15f * m2uf;
						const float b1 = std::min(l1, r1), t1 = std::max(l1, r1) + 0.15f * m2uf;
						const float drop = std::max(t0 - b0, t1 - b1) / m2uf - 0.15f;
						if (drop >= 0.3f && drop <= 8.0f) {
							y0 = b0; y1 = b1;
							hgt_cur = t0 - b0;
							h1 = t1 - b1;
						}
					}
					tm += (double)p0.distance_to(p1) / m2u;
					switch (br.kind) {
						case 0: wall_piece(bufs[0], p0, p1, y0, y1, hgt_cur, br.thick, 0.3f * m2uf, m2uf, h1); break;
						case 1: fence_piece(bufs[1], p0, p1, y0, y1, hgt_cur, m2uf); break;
						case 2: fence_piece(bufs[2], p0, p1, y0, y1, hgt_cur, m2uf); break;
						case 3: wall_piece(bufs[3], p0, p1, y0, y1, hgt_cur, 0.06f * m2uf, 0.0f, m2uf); break;
						case 4:
							wall_piece(bufs[5], p0, p1, y0, y1, hgt_cur * 0.9f, br.thick * 0.8f, 0.1f * m2uf, m2uf);
							wall_piece(bufs[4], p0, p1, y0, y1, hgt_cur, br.thick, 0.1f * m2uf, m2uf);
							break;
					}
				}
			}
		}
		chunk_m[c] = tm;
	});

	std::array<MeshBuf, 6> merged;
	double total_m = 0.0;
	for (int c = 0; c < chunks; ++c) {
		total_m += chunk_m[c];
		for (int k = 0; k < 6; ++k) {
			merged[k].append(chunk_bufs[c][k]);
		}
	}

	Array meshes;
	meshes.resize(6);
	for (int k = 0; k < 6; ++k) {
		const MeshBuf &mb = merged[k];
		if (mb.idx.empty()) {
			meshes[k] = Array();
			continue;
		}
		PackedVector3Array va, na;
		PackedVector2Array ua;
		PackedColorArray ca;
		PackedInt32Array ia;
		va.resize((int)mb.verts.size());
		na.resize((int)mb.normals.size());
		ua.resize((int)mb.uvs.size());
		ca.resize((int)mb.colors.size());
		ia.resize((int)mb.idx.size());
		std::copy(mb.verts.begin(), mb.verts.end(), va.ptrw());
		std::copy(mb.normals.begin(), mb.normals.end(), na.ptrw());
		std::copy(mb.uvs.begin(), mb.uvs.end(), ua.ptrw());
		std::copy(mb.colors.begin(), mb.colors.end(), ca.ptrw());
		std::copy(mb.idx.begin(), mb.idx.end(), ia.ptrw());
		Array a;
		a.resize(5);
		a[0] = va; a[1] = na; a[2] = ua; a[3] = ca; a[4] = ia;
		meshes[k] = a;
	}
	Dictionary out;
	out["total_m"] = total_m;
	out["meshes"] = meshes;
	return out;
}

void PropKernels::_bind_methods() {
	ClassDB::bind_static_method("PropKernels", D_METHOD("parked_cars_plan", "params"), &PropKernels::parked_cars_plan);
	ClassDB::bind_static_method("PropKernels", D_METHOD("barriers_build", "params"), &PropKernels::barriers_build);
	ClassDB::bind_static_method("PropKernels", D_METHOD("stairs_build", "params"), &PropKernels::stairs_build);
}

namespace {

struct ReliefBuf {
	std::vector<Vector3> verts;
	std::vector<Vector3> normals;
	std::vector<Vector2> uvs;
	std::vector<float> tangents;
	std::vector<int32_t> idx;

	void quad(const Vector3 &p0, const Vector3 &p1, const Vector3 &p2, const Vector3 &p3,
			const Vector3 &n, const Vector2 &uv0, const Vector2 &uv1) {
		const int32_t k = (int32_t)verts.size();
		verts.push_back(p0); verts.push_back(p1); verts.push_back(p2); verts.push_back(p3);
		for (int j = 0; j < 4; ++j) normals.push_back(n);
		uvs.emplace_back(uv0.x, uv1.y);
		uvs.emplace_back(uv1.x, uv1.y);
		uvs.emplace_back(uv1.x, uv0.y);
		uvs.emplace_back(uv0.x, uv0.y);
		const float sx = (uv1.x >= uv0.x) ? 1.0f : -1.0f;
		const float sy = (uv1.y >= uv0.y) ? 1.0f : -1.0f;
		const Vector3 du = (p1 - p0) * sx;
		const Vector3 dnv = (p3 - p0) * sy;
		Vector3 t = du - n * n.dot(du);
		if (t.length_squared() < 1e-10f) {
			t = n.cross(std::abs(n.y) < 0.9f ? Vector3(0.0f, 1.0f, 0.0f) : Vector3(1.0f, 0.0f, 0.0f));
		}
		t.normalize();
		const float w = (n.cross(t).dot(dnv) >= 0.0f) ? 1.0f : -1.0f;
		for (int j = 0; j < 4; ++j) {
			tangents.push_back(t.x); tangents.push_back(t.y); tangents.push_back(t.z); tangents.push_back(w);
		}
		if ((p2 - p0).cross(p1 - p0).dot(n) >= 0.0f) {
			idx.push_back(k); idx.push_back(k + 1); idx.push_back(k + 2);
			idx.push_back(k); idx.push_back(k + 2); idx.push_back(k + 3);
		} else {
			idx.push_back(k); idx.push_back(k + 2); idx.push_back(k + 1);
			idx.push_back(k); idx.push_back(k + 3); idx.push_back(k + 2);
		}
	}

	void face(const Vector2 &a, float ya0, const Vector2 &b, float yb0,
			float ya1, float yb1, const Vector3 &n, float m2u) {
		if (std::max(ya1 - ya0, yb1 - yb0) < 0.01f * m2u) return;
		const float run = a.distance_to(b) / m2u;
		const float rise = std::max(ya1 - ya0, yb1 - yb0) / m2u;
		quad(Vector3(a.x, ya0, a.y), Vector3(b.x, yb0, b.y),
				Vector3(b.x, yb1, b.y), Vector3(a.x, ya1, a.y),
				n, Vector2(0.0f, 0.0f), Vector2(run, rise) * 0.25f);
	}

	void append(const ReliefBuf &o) {
		if (o.idx.empty()) return;
		const int32_t base = (int32_t)verts.size();
		verts.insert(verts.end(), o.verts.begin(), o.verts.end());
		normals.insert(normals.end(), o.normals.begin(), o.normals.end());
		uvs.insert(uvs.end(), o.uvs.begin(), o.uvs.end());
		tangents.insert(tangents.end(), o.tangents.begin(), o.tangents.end());
		const size_t old_n = idx.size();
		idx.resize(old_n + o.idx.size());
		for (size_t i = 0; i < o.idx.size(); ++i) idx[old_n + i] = o.idx[i] + base;
	}
};

Vector2 poly_at(const std::vector<Vector2> &pts, float s) {
	float run = 0.0f;
	const int pn = (int)pts.size();
	for (int i = 1; i < pn; ++i) {
		const float ln = pts[i].distance_to(pts[i - 1]);
		if (s <= run + ln || i == pn - 1) {
			return pts[i - 1].lerp(pts[i], std::clamp((s - run) / std::max(ln, 1e-9f), 0.0f, 1.0f));
		}
		run += ln;
	}
	return pts[0];
}

Vector2 poly_dir(const std::vector<Vector2> &pts, float s) {
	float run = 0.0f;
	const int pn = (int)pts.size();
	for (int i = 1; i < pn; ++i) {
		const float ln = pts[i].distance_to(pts[i - 1]);
		if (s <= run + ln || i == pn - 1) {
			return (pts[i] - pts[i - 1]).normalized();
		}
		run += ln;
	}
	return Vector2(1.0f, 0.0f);
}

} // namespace

Dictionary PropKernels::stairs_build(const Dictionary &params) {
	PackedFloat32Array surf_hold, lvl_hold;
	PackedFloat64Array body_hold;
	const GroundCtx g = read_ground_ctx(params, surf_hold, lvl_hold, body_hold);
	const float m2u = (float)(double)params.get("m2u", 1.0);

	struct FlightIn {
		std::vector<Vector2> pts;
		int n;
		float y_top, y_bot, width;
		bool handrail;
		int fin; // 0=paving, 1=sett, 2=gravel
	};
	const Array fl_arr = params.get("flights", Array());
	const int fn = fl_arr.size();
	std::vector<FlightIn> flights(fn);
	for (int i = 0; i < fn; ++i) {
		const Array f = fl_arr[i];
		const PackedVector2Array pts = f[0];
		flights[i].pts.assign(pts.ptr(), pts.ptr() + pts.size());
		flights[i].n = std::max((int)f[1], 1);
		flights[i].y_top = (float)f[2];
		flights[i].y_bot = (float)f[3];
		flights[i].width = (float)f[4];
		flights[i].handrail = (bool)f[5];
		flights[i].fin = std::clamp((int)f[6], 0, 2);
	}

	// 8 buckets: 0..2 tread, 3..5 riser, 6 cheek, 7 iron
	const int chunks = std::min(std::max(1, fn), 8);
	std::vector<std::array<ReliefBuf, 8>> cbufs(chunks);
	parallel_for(chunks, [&](int c) {
		const int i0 = (fn * c) / chunks;
		const int i1 = (fn * (c + 1)) / chunks;
		auto &bufs = cbufs[c];
		for (int fi = i0; fi < i1; ++fi) {
			const FlightIn &f = flights[fi];
			const int pn = (int)f.pts.size();
			if (pn < 2) continue;
			float total = 0.0f;
			for (int i = 1; i < pn; ++i) total += f.pts[i].distance_to(f.pts[i - 1]);
			if (total < 0.01f) continue;
			const float rise = (f.y_top - f.y_bot) / (float)f.n;
			const float half = f.width * 0.5f;
			const float width_m = f.width / m2u;
			ReliefBuf &tread = bufs[f.fin];
			ReliefBuf &riser = bufs[3 + f.fin];
			ReliefBuf &cheek = bufs[6];
			ReliefBuf &iron = bufs[7];
			for (int j = 1; j <= f.n; ++j) {
				const float s0 = total * (float)(j - 1) / (float)f.n;
				const float s1 = total * (float)j / (float)f.n;
				const Vector2 d = poly_dir(f.pts, (s0 + s1) * 0.5f);
				const Vector2 p0 = poly_at(f.pts, s0);
				const Vector2 p1 = poly_at(f.pts, s1);
				const Vector2 side = d.orthogonal() * half;
				const float yj = f.y_top - rise * (float)j;
				const Vector2 a_l = p0 + side, a_r = p0 - side;
				const Vector2 b_l = p1 + side, b_r = p1 - side;
				tread.quad(Vector3(a_l.x, yj, a_l.y), Vector3(a_r.x, yj, a_r.y),
						Vector3(b_r.x, yj, b_r.y), Vector3(b_l.x, yj, b_l.y),
						Vector3(0.0f, 1.0f, 0.0f), Vector2(0.0f, 0.0f),
						Vector2(width_m, p0.distance_to(p1) / m2u) * 0.25f);
				float yb = yj - rise;
				if (j == f.n) {
					const float gh = (float)g.height((b_l.x + b_r.x) * 0.5f, (b_l.y + b_r.y) * 0.5f);
					yb = std::clamp(gh, yj - 0.6f * m2u, yj - 0.02f * m2u);
				}
				riser.face(b_l, yb, b_r, yb, yj, yj, Vector3(d.x, 0.0f, d.y), m2u);
				if (j == 1) {
					const float gh = (float)g.height((a_l.x + a_r.x) * 0.5f, (a_l.y + a_r.y) * 0.5f);
					if (gh < yj - 0.02f * m2u) {
						const float ft = std::max(gh, yj - 0.6f * m2u);
						riser.face(a_r, ft, a_l, ft, yj, yj, Vector3(-d.x, 0.0f, -d.y), m2u);
					}
				}
				for (float sign : { 1.0f, -1.0f }) {
					const Vector2 out = d.orthogonal() * sign;
					const Vector2 c0 = p0 + out * half;
					const Vector2 c1 = p1 + out * half;
					const float g0 = (float)g.height(c0.x, c0.y);
					const float g1 = (float)g.height(c1.x, c1.y);
					if (g0 < yj && g1 < yj) {
						riser.face(c0, std::max(g0, yj - 8.0f * m2u), c1, std::max(g1, yj - 8.0f * m2u),
								yj, yj, Vector3(out.x, 0.0f, out.y), m2u);
					}
					const Vector2 o0 = c0 + out * (0.35f * m2u);
					const Vector2 o1 = c1 + out * (0.35f * m2u);
					const float h0 = (float)g.height(o0.x, o0.y);
					const float h1 = (float)g.height(o1.x, o1.y);
					if (std::max(h0, h1) - yj > 0.4f * m2u) {
						cheek.face(c0, yj, c1, yj, std::max(h0, yj), std::max(h1, yj),
								Vector3(-out.x, 0.0f, -out.y), m2u);
					}
				}
			}
			if (f.handrail) {
				const float inset = half - 0.05f * m2u;
				const float rh = 0.9f * m2u;
				float s = 0.0f;
				for (int i = 1; i < pn; ++i) {
					const Vector2 seg = f.pts[i] - f.pts[i - 1];
					const float ln = seg.length();
					if (ln < 0.01f) continue;
					const Vector2 out = seg.normalized().orthogonal();
					const float ya = Math::lerp(f.y_top, f.y_bot, s / total);
					const float yb = Math::lerp(f.y_top, f.y_bot, (s + ln) / total);
					for (float sign : { 1.0f, -1.0f }) {
						const Vector2 off = out * (inset * sign);
						const Vector3 a3(f.pts[i - 1].x + off.x, ya, f.pts[i - 1].y + off.y);
						const Vector3 b3(f.pts[i].x + off.x, yb, f.pts[i].y + off.y);
						const float len_m = a3.distance_to(b3) / m2u;
						iron.quad(a3, b3, b3 + Vector3(0.0f, rh, 0.0f), a3 + Vector3(0.0f, rh, 0.0f),
								Vector3(out.x * sign, 0.0f, out.y * sign),
								Vector2(0.0f, 0.0f), Vector2(std::max(len_m, 0.3f), 1.0f));
					}
					s += ln;
				}
			}
		}
	});

	std::array<ReliefBuf, 8> merged;
	for (int c = 0; c < chunks; ++c) {
		for (int k = 0; k < 8; ++k) merged[k].append(cbufs[c][k]);
	}
	Array surfaces;
	surfaces.resize(8);
	for (int k = 0; k < 8; ++k) {
		const ReliefBuf &rb = merged[k];
		if (rb.idx.empty()) {
			surfaces[k] = Array();
			continue;
		}
		PackedVector3Array va, na;
		PackedVector2Array ua;
		PackedFloat32Array ta;
		PackedInt32Array ia;
		va.resize((int)rb.verts.size());
		na.resize((int)rb.normals.size());
		ua.resize((int)rb.uvs.size());
		ta.resize((int)rb.tangents.size());
		ia.resize((int)rb.idx.size());
		std::copy(rb.verts.begin(), rb.verts.end(), va.ptrw());
		std::copy(rb.normals.begin(), rb.normals.end(), na.ptrw());
		std::copy(rb.uvs.begin(), rb.uvs.end(), ua.ptrw());
		std::copy(rb.tangents.begin(), rb.tangents.end(), ta.ptrw());
		std::copy(rb.idx.begin(), rb.idx.end(), ia.ptrw());
		Array a;
		a.resize(5);
		a[0] = va; a[1] = na; a[2] = ua; a[3] = ia; a[4] = ta;
		surfaces[k] = a;
	}
	Dictionary out;
	out["surfaces"] = surfaces;
	return out;
}

} // namespace godot
