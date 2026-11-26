#include "ribbon_draper.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

#include <cmath>
#include <cstring>
#include <unordered_map>

namespace godot {

namespace {

// GDScript's minf / maxf / clampf / lerpf on doubles.
inline double mn(double a, double b) {
	return a < b ? a : b;
}
inline double mx(double a, double b) {
	return a > b ? a : b;
}
inline double clampd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
inline double lerpd(double a, double b, double t) {
	return a + (b - a) * t;
}

// RoadDrape._Poly: one convex piece, per corner XZ, UV, junction
// fraction (float32, as its PackedFloat32Array) and normal.
struct Poly {
	std::vector<Vector2> pos, uv;
	std::vector<float> jf;
	std::vector<Vector3> nrm;

	void add(const Vector2 &p, const Vector2 &u, double j, const Vector3 &n) {
		pos.push_back(p);
		uv.push_back(u);
		jf.push_back((float)j);
		nrm.push_back(n);
	}
	void add_lerp(Poly &to, int i, int k, double t) const {
		const real_t tf = (real_t)t;
		to.add(pos[i].lerp(pos[k], tf), uv[i].lerp(uv[k], tf), lerpd(jf[i], jf[k], t),
				nrm[i].lerp(nrm[k], tf));
	}
	void add_from(Poly &to, int i) const {
		to.add(pos[i], uv[i], jf[i], nrm[i]);
	}
};

struct Row {
	Vector2 left, right;
	double v;
	double jf;
	Vector3 n;
};

// RoadDrape.SEAM
const double SEAM = 0.05;

struct Out {
	std::vector<Vector3> verts, normals;
	std::vector<Vector2> uvs, uv2s;
	std::vector<Color> colors;
	std::vector<int32_t> indices;
	std::unordered_map<int64_t, int32_t> weld;
};

// RoadBuilder._side
Vector2 side(const PackedVector2Array &pts, int64_t i) {
	const int64_t n = pts.size();
	Vector2 d0 = pts[i] - pts[i > 0 ? i - 1 : 0];
	Vector2 d1 = pts[i + 1 < n ? i + 1 : n - 1] - pts[i];
	if ((double)d0.length() < 0.00001) {
		d0 = d1;
	}
	if ((double)d1.length() < 0.00001) {
		d1 = d0;
	}
	const Vector2 n0 = Vector2(-d0.y, d0.x).normalized();
	const Vector2 n1 = Vector2(-d1.y, d1.x).normalized();
	Vector2 m = n0 + n1;
	if ((double)m.length() < 0.001) {
		return n1;
	}
	m = m.normalized();
	const double k = 1.0 / mx((double)m.dot(n1), 0.4);
	return m * (real_t)k;
}

// RoadDrape._cut
void cut(const Poly &poly, int fam, double mesh_step, int mesh_size, std::vector<Poly> &out) {
	std::vector<float> g;
	double lo = INFINITY;
	double hi = -INFINITY;
	const double inv = 1.0 / mesh_step;
	const double hs = (double)mesh_size * 0.5;
	for (const Vector2 &p : poly.pos) {
		const double v = (fam != 1 ? (double)p.x * inv + hs : 0.0) + (fam != 0 ? (double)p.y * inv + hs : 0.0);
		g.push_back((float)v);
		lo = mn(lo, v);
		hi = mx(hi, v);
	}
	double k = std::floor(lo) + 1.0;
	if (k >= hi - 1e-5) {
		out.push_back(poly);
		return;
	}
	Poly cur = poly;
	while (k < hi - 1e-5) {
		if (k <= lo + 1e-5) {
			k += 1.0;
			continue;
		}
		Poly below, above;
		const int n = (int)cur.pos.size();
		std::vector<float> ga;
		for (int i = 0; i < n; i++) {
			const int j = (i + 1) % n;
			const double gi = g[i];
			const double gj = g[j];
			if (gi <= k) {
				cur.add_from(below, i);
			}
			if (gi >= k) {
				cur.add_from(above, i);
				ga.push_back(g[i]);
			}
			if ((gi < k && gj > k) || (gi > k && gj < k)) {
				const double t = (k - gi) / (gj - gi);
				cur.add_lerp(below, i, j, t);
				cur.add_lerp(above, i, j, t);
				ga.push_back((float)k);
			}
		}
		if (below.pos.size() >= 3) {
			out.push_back(std::move(below));
		}
		cur = std::move(above);
		g = std::move(ga);
		k += 1.0;
	}
	if (cur.pos.size() >= 3) {
		out.push_back(std::move(cur));
	}
}

} // namespace

void RibbonDraper::setup(const PackedFloat32Array &p_surface, int p_g_size, double p_g_step,
		double p_water_level, int p_size, double p_step, int p_mesh_size, double p_mesh_step) {
	surface.resize((size_t)p_surface.size());
	if (!surface.empty()) {
		std::memcpy(surface.data(), p_surface.ptr(), surface.size() * sizeof(float));
	}
	g_size = p_g_size;
	g_step = p_g_step;
	water_level = p_water_level;
	size = p_size;
	step = p_step;
	mesh_size = p_mesh_size;
	mesh_step = p_mesh_step;
}

// GroundTruth.height_at_world
double RibbonDraper::ground_height(double x, double z) const {
	if (g_size < 2 || surface.size() != (size_t)g_size * (size_t)g_size) {
		return water_level;
	}
	const double fx = clampd(x / g_step + (double)g_size * 0.5, 0.0, (double)(g_size - 1));
	const double fz = clampd(z / g_step + (double)g_size * 0.5, 0.0, (double)(g_size - 1));
	const int x0 = std::min((int)fx, g_size - 2);
	const int z0 = std::min((int)fz, g_size - 2);
	const double tx = fx - (double)x0;
	const double tz = fz - (double)z0;
	const double a = lerpd(surface[z0 * g_size + x0], surface[z0 * g_size + x0 + 1], tx);
	const double b = lerpd(surface[(z0 + 1) * g_size + x0], surface[(z0 + 1) * g_size + x0 + 1], tx);
	return lerpd(a, b, tz);
}

// GroundTruth.surface_at_post
double RibbonDraper::post(int x, int z) const {
	if (surface.empty()) {
		return water_level;
	}
	const int cx = x < 0 ? 0 : (x > g_size - 1 ? g_size - 1 : x);
	const int cz = z < 0 ? 0 : (z > g_size - 1 ? g_size - 1 : z);
	if (shore_posts.size() == surface.size()) return shore_posts[cz * g_size + cx];
	return surface[cz * g_size + cx];
}

// _Surface._mesh_tri
double RibbonDraper::mesh_tri(double x, double z) const {
	const double hs = (double)mesh_size * 0.5;
	const double fx = clampd(x / mesh_step + hs, 0.0, (double)(mesh_size - 1));
	const double fz = clampd(z / mesh_step + hs, 0.0, (double)(mesh_size - 1));
	const int x0 = std::min((int)fx, mesh_size - 2);
	const int z0 = std::min((int)fz, mesh_size - 2);
	const double tx = fx - (double)x0;
	const double tz = fz - (double)z0;
	const double px = ((double)x0 - hs) * mesh_step;
	const double pz = ((double)z0 - hs) * mesh_step;
	const double hb = ground_height(px + mesh_step, pz);
	const double hc = ground_height(px, pz + mesh_step);
	if (tx + tz <= 1.0) {
		const double ha = ground_height(px, pz);
		return ha + (hb - ha) * tx + (hc - ha) * tz;
	}
	const double hd = ground_height(px + mesh_step, pz + mesh_step);
	return hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz);
}

double RibbonDraper::height(double x, double z) const {
	if (shore_sampler.is_valid() && shore_sampler->dry_triangles(x, z) != nullptr) return shore_sampler->height(x, z);
	if (mesh_size >= 2 && mesh_size != size) {
		return mx(mesh_tri(x, z), ground_height(x, z));
	}
	if (size < 2) {
		return ground_height(x, z);
	}
	const double fx = clampd(x / step + (double)size * 0.5, 0.0, (double)(size - 1));
	const double fz = clampd(z / step + (double)size * 0.5, 0.0, (double)(size - 1));
	const int x0 = std::min((int)fx, size - 2);
	const int z0 = std::min((int)fz, size - 2);
	const double tx = fx - (double)x0;
	const double tz = fz - (double)z0;
	const double ha = post(x0, z0);
	const double hb = post(x0 + 1, z0);
	const double hc = post(x0, z0 + 1);
	const double hd = post(x0 + 1, z0 + 1);
	const double a = lerpd(ha, hb, tx);
	const double b = lerpd(hc, hd, tx);
	const double bil = lerpd(a, b, tz);
	double tri;
	if (tx + tz <= 1.0) {
		tri = ha + (hb - ha) * tx + (hc - ha) * tz;
	} else {
		tri = hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz);
	}
	return mx(tri, bil);
}

Vector3 RibbonDraper::normal(double x, double z) const {
	const double e = step * 0.5;
	const double dx = height(x + e, z) - height(x - e, z);
	const double dz = height(x, z + e) - height(x, z - e);
	return Vector3(-dx, 2.0 * e, -dz).normalized();
}

Array RibbonDraper::ribbon(const PackedVector2Array &pts, double width, double lift, const Color &attr,
		const PackedFloat64Array &jf, double layer, double m2u, int base) const {
	return build(pts, width, lift, attr, jf, layer, m2u, base, false);
}

Array RibbonDraper::area(const PackedVector2Array &triangles, double lift, const Color &attr,
		double layer, double m2u, int base) const {
	return build(triangles, 0.0, lift, attr, PackedFloat64Array(), layer, m2u, base, true);
}

Array RibbonDraper::build(const PackedVector2Array &pts, double width, double lift, const Color &attr,
		const PackedFloat64Array &jf, double layer, double m2u, int base, bool is_area) const {
	Out o;
	const double half = width * 0.5;
	double along = 0.0;
	const double u1 = width / m2u / 4.0;
	const Vector2 w2(width / m2u, layer);
	// RoadDrape._emit: `on`, the shore triangle the piece was cut to, else null.
	auto emit = [&](const Poly &pc, const Vector3 *on) {
		std::vector<int32_t> ids;
		const Vector3 normal = on != nullptr ? (on[1] - on[0]).cross(on[2] - on[0]) : Vector3();
		for (size_t i = 0; i < pc.pos.size(); i++) {
			const Vector2 p = pc.pos[i];
			const int64_t kx = (int64_t)std::round((double)p.x * 1000.0);
			const int64_t kz = (int64_t)std::round((double)p.y * 1000.0);
			int64_t key = (int64_t)(((uint64_t)kx << 32) ^ ((uint64_t)kz & 0xffffffffULL));
			double y = INFINITY;
			if (std::abs(normal.y) > 1e-9) {
				// RoadDrape._emit: a piece on the lower ground beside a wall
				// lies on its own triangle, welded apart from the upper level.
				auto top = o.weld.find(key);
				y = top != o.weld.end() ? (double)o.verts[top->second - base].y - lift : height(p.x, p.y);
				const double own = on[0].y - (normal.x * (p.x - on[0].x) + normal.z * (p.y - on[0].z)) / normal.y;
				if (y - own > SEAM) {
					y = own;
					key ^= (int64_t)1 << 62;
				}
			}
			auto it = o.weld.find(key);
			int32_t id;
			if (it == o.weld.end()) {
				id = base + (int32_t)o.verts.size();
				o.weld.emplace(key, id);
				o.verts.push_back(Vector3(p.x, (std::isinf(y) ? height(p.x, p.y) : y) + lift, p.y));
				o.normals.push_back(pc.nrm[i].normalized());
				o.uvs.push_back(pc.uv[i]);
				o.colors.push_back(Color(attr.r, attr.g, attr.b, pc.jf[i]));
				o.uv2s.push_back(w2);
			} else {
				id = it->second;
			}
			ids.push_back(id);
		}
		for (size_t i = 1; i + 1 < ids.size(); i++) {
			const int32_t a = ids[0];
			const int32_t c = ids[i];
			const int32_t d = ids[i + 1];
			if (a == c || c == d || a == d) {
				continue;
			}
			const Vector3 va = o.verts[a - base];
			const real_t up = (o.verts[d - base] - va).cross(o.verts[c - base] - va).y;
			if (up >= 0.0f) {
				o.indices.insert(o.indices.end(), { a, c, d });
			} else {
				o.indices.insert(o.indices.end(), { a, d, c });
			}
		}
	};
	// RoadDrape._lay
	auto lay = [&](const Poly &t) {
		std::vector<Poly> pieces{ t };
		for (int fam = 0; fam < 3; fam++) {
			std::vector<Poly> next;
			for (const Poly &pc : pieces) {
				cut(pc, fam, mesh_step, mesh_size, next);
			}
			pieces = std::move(next);
		}
		for (const Poly &pc : pieces) {
			Vector2 centre;
			for (const auto &p : pc.pos) centre += p;
			if (!pc.pos.empty()) centre /= (real_t)pc.pos.size();
			const auto *triangles = shore_sampler.is_valid() ? shore_sampler->dry_triangles(centre.x, centre.y) : nullptr;
			if (triangles == nullptr) { emit(pc, nullptr); continue; }
			double x0 = INFINITY, z0 = INFINITY, x1 = -INFINITY, z1 = -INFINITY;
			for (const auto &p : pc.pos) {
				x0 = mn(x0, p.x); x1 = mx(x1, p.x);
				z0 = mn(z0, p.y); z1 = mx(z1, p.y);
			}
			for (size_t i = 0; i + 2 < triangles->size(); i += 3) {
				const Vector3 a = (*triangles)[i], b = (*triangles)[i + 1], c = (*triangles)[i + 2];
				if (mx(a.x, mx(b.x, c.x)) < x0 - 0.0001 || mn(a.x, mn(b.x, c.x)) > x1 + 0.0001 ||
					mx(a.z, mx(b.z, c.z)) < z0 - 0.0001 || mn(a.z, mn(b.z, c.z)) > z1 + 0.0001) continue;
				Poly clipped = pc;
				for (int edge = 0; edge < 3 && clipped.pos.size() >= 3; ++edge) {
					const Vector3 aa = (*triangles)[i + edge], bb = (*triangles)[i + (edge + 1) % 3];
					const Vector2 a(aa.x, aa.z), d(bb.x - aa.x, bb.z - aa.z);
					Poly next;
					for (size_t j = 0; j < clipped.pos.size(); ++j) {
						const size_t k = (j + 1) % clipped.pos.size();
						const double da = d.cross(clipped.pos[j] - a), db = d.cross(clipped.pos[k] - a);
						if (da >= -0.00001) clipped.add_from(next, (int)j);
						if ((da < -0.00001 && db > 0.00001) || (da > 0.00001 && db < -0.00001)) clipped.add_lerp(next, (int)j, (int)k, da / (da - db));
					}
					clipped = std::move(next);
				}
				if (clipped.pos.size() >= 3) emit(clipped, &(*triangles)[i]);
			}
		}
	};
	if (is_area) {
		for (int64_t i = 0; i + 2 < pts.size(); i += 3) {
			Poly t;
			for (int j = 0; j < 3; ++j) {
				const Vector2 p = pts[i + j];
				t.add(p, p / (real_t)m2u / (real_t)4.0, 1.0, normal(p.x, p.y));
			}
			lay(t);
		}
	} else {
		Row prev;
		for (int64_t i = 0; i < pts.size(); i++) {
			if (i > 0) {
				along += (double)pts[i].distance_to(pts[i - 1]);
			}
			const Vector2 s = side(pts, i) * (real_t)half;
			const Row row{ pts[i] + s, pts[i] - s, along / m2u / 4.0, jf[i], normal(pts[i].x, pts[i].y) };
			if (i > 0) {
				// RoadDrape.quad
				Poly t0, t1;
				t0.add(prev.left, Vector2(0.0, prev.v), prev.jf, prev.n);
				t0.add(prev.right, Vector2(u1, prev.v), prev.jf, prev.n);
				t0.add(row.left, Vector2(0.0, row.v), row.jf, row.n);
				t1.add(prev.right, Vector2(u1, prev.v), prev.jf, prev.n);
				t1.add(row.right, Vector2(u1, row.v), row.jf, row.n);
				t1.add(row.left, Vector2(0.0, row.v), row.jf, row.n);
				lay(t0);
				lay(t1);
			}
			prev = row;
		}
	}
	PackedVector3Array v, n;
	PackedVector2Array uv, uv2;
	PackedColorArray col;
	PackedInt32Array idx;
	v.resize((int64_t)o.verts.size());
	n.resize((int64_t)o.normals.size());
	uv.resize((int64_t)o.uvs.size());
	uv2.resize((int64_t)o.uv2s.size());
	col.resize((int64_t)o.colors.size());
	idx.resize((int64_t)o.indices.size());
	if (!o.verts.empty()) {
		std::memcpy(v.ptrw(), o.verts.data(), o.verts.size() * sizeof(Vector3));
		std::memcpy(n.ptrw(), o.normals.data(), o.normals.size() * sizeof(Vector3));
		std::memcpy(uv.ptrw(), o.uvs.data(), o.uvs.size() * sizeof(Vector2));
		std::memcpy(uv2.ptrw(), o.uv2s.data(), o.uv2s.size() * sizeof(Vector2));
		std::memcpy(col.ptrw(), o.colors.data(), o.colors.size() * sizeof(Color));
	}
	if (!o.indices.empty()) {
		std::memcpy(idx.ptrw(), o.indices.data(), o.indices.size() * sizeof(int32_t));
	}
	Array out;
	out.push_back(v);
	out.push_back(n);
	out.push_back(uv);
	out.push_back(col);
	out.push_back(uv2);
	out.push_back(idx);
	return out;
}

void RibbonDraper::set_shore_sampler(const Ref<ShoreSampler> &sampler) {
	shore_sampler = sampler;
	shore_posts.clear();
	if (sampler.is_valid()) {
		const PackedFloat32Array posts = sampler->grid_heights();
		shore_posts.assign(posts.ptr(), posts.ptr() + posts.size());
	}
}

void RibbonDraper::set_water_context(const Ref<ShoreDomainIndex> &domains, const Rect2 &bounds, bool empty,
		const PackedFloat64Array &body_levels_in, const PackedFloat32Array &level_in, double half_u) {
	shore_domains = domains;
	shore_bounds = bounds;
	shore_empty = empty;
	half_units = half_u;
	body_levels.assign(body_levels_in.ptr(), body_levels_in.ptr() + body_levels_in.size());
	water_level_grid.assign(level_in.ptr(), level_in.ptr() + level_in.size());
	water_ready = true;
}

static inline int64_t junc_cell_key(int32_t cx, int32_t cz) {
	return (int64_t(cx) << 32) | uint32_t(cz);
}

void RibbonDraper::set_junctions(const Dictionary &buckets, double junction_m) {
	junc_buckets.clear();
	junc_m = junction_m > 0.0 ? junction_m : 1.0;
	const Array keys = buckets.keys();
	junc_buckets.reserve((size_t)keys.size());
	for (int64_t i = 0; i < keys.size(); i++) {
		const Vector2i cell = keys[i];
		const PackedVector2Array pts = buckets[keys[i]];
		std::vector<Vector2> vec;
		vec.assign(pts.ptr(), pts.ptr() + pts.size());
		junc_buckets[junc_cell_key(cell.x, cell.y)] = std::move(vec);
	}
}

bool RibbonDraper::inside(const Vector2 &p) const {
	const double lo = -(double)mesh_size * 0.5 * mesh_step + 2.0;
	const double hi = ((double)mesh_size * 0.5 - 1.0) * mesh_step - 2.0;
	return (double)p.x >= lo && (double)p.x <= hi && (double)p.y >= lo && (double)p.y <= hi;
}

double RibbonDraper::water_at(double x, double z) const {
	if (shore_domains.is_valid() && shore_bounds.has_point(Vector2((real_t)x, (real_t)z))) {
		const int id = shore_domains->at(Vector2((real_t)x, (real_t)z));
		if (id == 0) {
			return -1.0;
		}
		if (id > 0 && id < (int)body_levels.size()) {
			return (double)body_levels[id] - ground_height(x, z);
		}
	} else if (shore_empty) {
		return -1.0;
	}
	if ((int)water_level_grid.size() == g_size * g_size && g_size >= 2) {
		const double fx = clampd((x + half_units) / g_step, 0.0, (double)(g_size - 1));
		const double fz = clampd((z + half_units) / g_step, 0.0, (double)(g_size - 1));
		const int x0 = std::min((int)fx, g_size - 2);
		const int z0 = std::min((int)fz, g_size - 2);
		const double tx = fx - (double)x0;
		const double tz = fz - (double)z0;
		const double a = (double)water_level_grid[z0 * g_size + x0];
		const double b = (double)water_level_grid[z0 * g_size + x0 + 1];
		const double c = (double)water_level_grid[(z0 + 1) * g_size + x0];
		const double d = (double)water_level_grid[(z0 + 1) * g_size + x0 + 1];
		if (a <= -9000.0 && b <= -9000.0 && c <= -9000.0 && d <= -9000.0) {
			return -1.0;
		}
		const double wl = lerpd(lerpd(a, b, tx), lerpd(c, d, tx), tz);
		if (wl <= -9000.0) {
			return -1.0;
		}
		return wl - ground_height(x, z);
	}
	return water_level - ground_height(x, z);
}

double RibbonDraper::junction_frac_at(const Vector2 &p) const {
	if (junc_buckets.empty()) {
		return 1.0;
	}
	const int32_t cx = (int32_t)std::floor((double)p.x / junc_m);
	const int32_t cz = (int32_t)std::floor((double)p.y / junc_m);
	double best = junc_m;
	for (int32_t dz = -1; dz <= 1; dz++) {
		for (int32_t dx = -1; dx <= 1; dx++) {
			auto it = junc_buckets.find(junc_cell_key(cx + dx, cz + dz));
			if (it == junc_buckets.end()) {
				continue;
			}
			for (const Vector2 &q : it->second) {
				const double d = (double)q.distance_to(p);
				if (d < best) {
					best = d;
				}
			}
		}
	}
	return best / junc_m;
}

Array RibbonDraper::dry_runs(const PackedVector2Array &pts, double max_resample) const {
	Array runs;
	const int64_t pn = pts.size();
	if (pn < 2) {
		return runs;
	}
	std::vector<Vector2> dense;
	if (max_resample > 0.0) {
		const double step_lim = max_resample > 0.05 ? max_resample : 0.05;
		dense.reserve((size_t)pn * 2);
		dense.push_back(pts[0]);
		for (int64_t i = 1; i < pn; i++) {
			const Vector2 a = pts[i - 1];
			const Vector2 b = pts[i];
			const int n = std::max(1, (int)std::ceil((double)a.distance_to(b) / step_lim));
			for (int k = 1; k <= n; k++) {
				dense.push_back(a.lerp(b, (real_t)((double)k / (double)n)));
			}
		}
	} else {
		dense.assign(pts.ptr(), pts.ptr() + pn);
	}
	std::vector<Vector2> cur;
	auto flush_cur = [&]() {
		if (cur.size() >= 2) {
			PackedVector2Array arr;
			arr.resize((int64_t)cur.size());
			std::memcpy(arr.ptrw(), cur.data(), cur.size() * sizeof(Vector2));
			runs.push_back(arr);
		}
		cur.clear();
	};
	for (const Vector2 &p : dense) {
		if (inside(p) && water_at((double)p.x, (double)p.y) <= 0.0) {
			cur.push_back(p);
		} else {
			flush_cur();
		}
	}
	flush_cur();
	return runs;
}

PackedVector2Array RibbonDraper::straighten(const PackedVector2Array &pts, double max_len) const {
	const int64_t n = pts.size();
	if (n <= 2) {
		return pts;
	}
	std::vector<Vector2> out;
	out.reserve((size_t)n);
	out.push_back(pts[0]);
	for (int64_t i = 1; i < n - 1; i++) {
		const Vector2 d0 = pts[i] - out.back();
		const Vector2 d1 = pts[i + 1] - pts[i];
		const bool bend = std::fabs((double)d0.normalized().cross(d1.normalized())) > 0.001;
		if (bend || (double)(pts[i + 1] - out.back()).length() > max_len) {
			out.push_back(pts[i]);
		}
	}
	out.push_back(pts[n - 1]);
	PackedVector2Array arr;
	arr.resize((int64_t)out.size());
	std::memcpy(arr.ptrw(), out.data(), out.size() * sizeof(Vector2));
	return arr;
}

Array RibbonDraper::ribbon_junc(const PackedVector2Array &pts, double width, double lift, const Color &attr,
		bool use_junc, double layer, double m2u, int base) const {
	const int64_t n = pts.size();
	PackedFloat64Array jf;
	jf.resize(n);
	double *jfp = jf.ptrw();
	if (use_junc && !junc_buckets.empty()) {
		for (int64_t i = 0; i < n; i++) {
			jfp[i] = junction_frac_at(pts[i]);
		}
	} else {
		for (int64_t i = 0; i < n; i++) {
			jfp[i] = 1.0;
		}
	}
	return build(pts, width, lift, attr, jf, layer, m2u, base, false);
}

void RibbonDraper::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "surface", "g_size", "g_step", "water_level", "size", "step",
								 "mesh_size", "mesh_step"),
			&RibbonDraper::setup);
	ClassDB::bind_method(D_METHOD("height", "x", "z"), &RibbonDraper::height);
	ClassDB::bind_method(D_METHOD("normal", "x", "z"), &RibbonDraper::normal);
	ClassDB::bind_method(D_METHOD("set_shore_sampler", "sampler"), &RibbonDraper::set_shore_sampler);
	ClassDB::bind_method(D_METHOD("set_water_context", "domains", "bounds", "empty", "body_levels", "level", "half_u"),
			&RibbonDraper::set_water_context);
	ClassDB::bind_method(D_METHOD("set_junctions", "buckets", "junction_m"), &RibbonDraper::set_junctions);
	ClassDB::bind_method(D_METHOD("dry_runs", "pts", "max_resample"), &RibbonDraper::dry_runs);
	ClassDB::bind_method(D_METHOD("straighten", "pts", "max_len"), &RibbonDraper::straighten);
	ClassDB::bind_method(D_METHOD("ribbon_junc", "pts", "width", "lift", "attr", "use_junc", "layer", "m2u", "base"),
			&RibbonDraper::ribbon_junc);
	ClassDB::bind_method(D_METHOD("area", "triangles", "lift", "attr", "layer", "m2u", "base"), &RibbonDraper::area);
	ClassDB::bind_method(D_METHOD("ribbon", "pts", "width", "lift", "attr", "jf", "layer", "m2u", "base"),
			&RibbonDraper::ribbon);
}

} // namespace godot
