#include "city_kernels.h"

#include "far_sampling.h"
#include "parallel.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <algorithm>
#include <cmath>
#include <map>
#include <string>
#include <tuple>
#include <vector>

namespace godot {

namespace {

using namespace far;

// FarCityBuilder constants.
constexpr double R_IN = 1230.0;
constexpr double SPLIT_M = 3500.0;
constexpr double BANDS[] = { 1200.0, 2500.0, 4500.0, 7500.0, 12001.0 };
constexpr int N_BANDS = 5;
constexpr double MIN_SCORE = 0.22;
constexpr double THIN_FAR = 0.55;
constexpr double MAX_SLOPE = 0.3;
constexpr double STREET_M = 12.0;
constexpr double LANDMARK_CLEAR_M = 120.0;
// FarCityBuilder.PAIR_*: an apartment lot wider than PAIR_MIN_M holds two buildings.
constexpr double PAIR_MIN_M = 28.0;
constexpr double PAIR_GAP_M = 5.0;
constexpr double PAIR_SHARE = 0.35;
// SettlementMap.
constexpr double CELL_M = 100.0;
constexpr double RADIUS_M = 12000.0;
enum Cls { NONE, RESIDENTIAL, COMMERCIAL, INDUSTRIAL };
// MassBatch tint kinds (WallVariety / RoofVariety / white).
enum Tint { TINT_NONE, TINT_WALL, TINT_ROOF };

struct Profile {
	int st_lo = 1, st_hi = 1;
	double fh = 3.0;
	double pitch = 1.0;
	std::vector<std::pair<std::string, double>> roofs;
};

struct City {
	Far far;
	bool far_ok = false;
	bool sea = true;
	double h_edge = -1.0;
	int n = 0, half = 0;
	PackedFloat32Array score;
	PackedByteArray cls, blocked;
	std::vector<uint8_t> tower_cell;
	Profile apt, house, ind, com;
	std::vector<Vector2> landmarks;
	int n_dfs = 0, n_drs = 0;
	std::vector<Vector3> facade_uv; // per facade
	std::vector<uint8_t> tint; // per material (facades then roofs)
	// WallVariety paint weight and per-place tone for the far blocks
	// (FarCityBuilder._paint); 0 keeps the plain tint.
	double chroma = 0.0;
	double tone = 0.0;
	// First index of the same Material object: MassBatch groups by
	// material identity, and the distant sets repeat materials.
	std::vector<int> canon;
};

// FarCityBuilder._hash
double city_hash(double x, double z, double salt = 0.0) {
	return Math::fposmod(std::sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0);
}

// ArchitectureStyle._h / _pick_weighted
std::string pick_weighted(const std::vector<std::pair<std::string, double>> &pairs, double seed_v, int salt) {
	double total = 0.0;
	for (const auto &pr : pairs) {
		total += pr.second;
	}
	double t = Math::fposmod(std::sin(seed_v * 12.9898 + (double)salt * 78.233) * 43758.5453, 1.0) * total;
	for (const auto &pr : pairs) {
		t -= pr.second;
		if (t < 0.0) {
			return pr.first;
		}
	}
	return pairs[0].first;
}

// BuildingHeights._roof_height_m with no tag.
double roof_height_m(const std::string &shape, double span_m, double pitch) {
	double lo = Math::min(pitch, 1.0);
	double hi = Math::max(pitch, 1.0);
	if (shape == "gabled") {
		return Math::clamp(span_m * 0.28 * pitch, 1.2 * lo, 4.5 * hi);
	} else if (shape == "hipped") {
		return Math::clamp(span_m * 0.25 * pitch, 1.2 * lo, 4.0 * hi);
	} else if (shape == "mansard") {
		return Math::clamp(span_m * 0.24 * pitch, 1.5 * lo, 3.2 * hi);
	} else if (shape == "pyramidal") {
		return Math::clamp(span_m * 0.32 * pitch, 1.0 * lo, 5.0 * hi);
	} else if (shape == "dome") {
		return Math::max(span_m * 0.5, 1.0);
	} else if (shape == "onion") {
		return Math::max(span_m * 1.1, 1.0);
	} else if (shape == "cone") {
		return Math::clamp(span_m * 1.6, 1.0, 80.0);
	} else if (shape == "gambrel" || shape == "saltbox") {
		return Math::clamp(span_m * 0.30 * pitch, 1.5 * lo, 5.0 * hi);
	} else if (shape == "half-hipped") {
		return Math::clamp(span_m * 0.26 * pitch, 1.2 * lo, 4.2 * hi);
	} else if (shape == "skillion") {
		return Math::clamp(span_m * 0.15 * pitch, 0.8 * lo, 3.0 * hi);
	} else if (shape == "round") {
		return Math::clamp(span_m * 0.25 * pitch, 1.0 * lo, 5.0 * hi);
	}
	return 0.0;
}

// WallVariety.FAMILIES: per-channel paint multipliers (cream, ochre, blush, sage, mist).
static const float PAINT_FAMILIES[6][3] = {
	{ 1.00f, 1.00f, 1.00f }, { 1.00f, 0.95f, 0.80f }, { 1.00f, 0.84f, 0.58f },
	{ 1.00f, 0.84f, 0.80f }, { 0.84f, 0.95f, 0.80f }, { 0.82f, 0.90f, 1.00f }
};

// WallVariety._family: a seeded pick weighted by how close each family sits
// to the place's tone on a circle.
int paint_family(double x, double z, double tone) {
	const int n = 6;
	float weights[n];
	float total = 0.0f;
	for (int i = 0; i < n; i++) {
		float k = (float)Math::max(0.25, 1.0 + 1.1 * std::cos(6.283185307179586 * ((double)i / (double)n - tone)));
		weights[i] = k;
		total += k;
	}
	double t = hash(x * 0.83 + 29.0, z * 0.47 + 7.0) * (double)total;
	for (int i = 0; i < n; i++) {
		t -= (double)weights[i];
		if (t < 0.0) {
			return i;
		}
	}
	return 0;
}

// WallVariety.tint_for / RoofVariety.tint_for (TerrainBuilder._hash). `chroma`
// is the wall's paint weight (a roof gets RoofVariety.ROOF_CHROMA of it, passed
// in by the caller); 0 is the plain seeded tint.
Color tint_for(int kind, const Vector3 &p, double chroma, double tone) {
	double x = p.x;
	double z = p.z;
	if (kind == TINT_WALL) {
		double l = 1.0 + (hash(x * 0.53 + 17.0, z * 0.29) * 2.0 - 1.0) * 0.14;
		double w = (hash(z * 0.61 + 3.0, x * 1.13) * 2.0 - 1.0) * 0.04;
		double r = l * (1.0 + w);
		double g = l;
		double b = l * (1.0 - w);
		if (chroma <= 0.0) {
			return Color(r, g, b);
		}
		const float *f = PAINT_FAMILIES[paint_family(x, z, tone)];
		double k = Math::min(chroma, 1.0);
		return Color(Math::min(r * (1.0 + ((double)f[0] - 1.0) * k), 1.0),
				Math::min(g * (1.0 + ((double)f[1] - 1.0) * k), 1.0),
				Math::min(b * (1.0 + ((double)f[2] - 1.0) * k), 1.0));
	}
	if (kind == TINT_ROOF) {
		double l = 1.0 + (hash(x * 0.37 + 5.0, z * 0.91) * 2.0 - 1.0) * 0.18;
		double w = (hash(z * 1.7 + 11.0, x * 0.23) * 2.0 - 1.0) * 0.05;
		if (chroma <= 0.0) {
			return Color(l * (1.0 + w), l, l * (1.0 - w));
		}
		w = w * (1.0 + 2.0 * chroma) + (tone - 0.5) * 0.06 * chroma;
		double m = (hash(x * 0.61 + 23.0, z * 1.31 + 2.0) * 2.0 - 1.0) * 0.06 * chroma;
		return Color(l * (1.0 + w), l * (1.0 + m), l * (1.0 - w));
	}
	return Color(1, 1, 1, 1);
}

// One MassBatch.add call.
struct Add {
	int oct = 0, band = 0, mat = 0;
	std::vector<Vector3> v, n;
	std::vector<Vector2> uv;
	std::vector<int32_t> i;
};

struct Row {
	std::vector<Add> adds;
	int blocks = 0;
};

// FarCityBuilder._key
void key_of(double x, double z, int &oct, int &band) {
	double r = Vector2(x, z).length();
	band = 0;
	while (band < N_BANDS - 2 && r >= BANDS[band + 1]) {
		band++;
	}
	oct = (int)Math::posmod((int64_t)std::floor((std::atan2(z, x) + Math::PI) / (Math::TAU / 8.0)), (int64_t)8);
}

bool near_landmark(const City &c, double x, double z) {
	for (const Vector2 &p : c.landmarks) {
		if ((double)p.distance_to(Vector2(x, z)) < LANDMARK_CLEAR_M) {
			return true;
		}
	}
	return false;
}

// FarCityBuilder._ground_y
double ground_y(const City &c, double x, double z) {
	if (is_inside(c.far, x, z) || !c.far_ok) {
		return height_at_world(c.far, x, z);
	}
	return blend_height(c.far, x, z);
}

// FarCityBuilder._site (INF when unbuildable).
double site(const City &c, const Vector2 *ring, int nr, double span) {
	double lo = INFINITY;
	double hi = -INFINITY;
	for (int k = 0; k < nr; k++) {
		double h = ground_y(c, ring[k].x, ring[k].y);
		lo = Math::min(lo, h);
		hi = Math::max(hi, h);
	}
	// RingGeometry.aabb(ring).get_center()
	Vector2 mn = ring[0];
	Vector2 mx = ring[0];
	for (int k = 0; k < nr; k++) {
		mn.x = Math::min((double)mn.x, (double)ring[k].x);
		mn.y = Math::min((double)mn.y, (double)ring[k].y);
		mx.x = Math::max((double)mx.x, (double)ring[k].x);
		mx.y = Math::max((double)mx.y, (double)ring[k].y);
	}
	Vector2 ctr = Rect2(mn, mx - mn).get_center();
	if (hi - lo > MAX_SLOPE * Math::max(span, 10.0)) {
		return INFINITY;
	}
	if (is_inside(c.far, ctr.x, ctr.y)) {
		if (water_at(c.far, ctr.x, ctr.y) > 0.0) {
			return INFINITY;
		}
	} else if (c.sea && asl_y(c.far, lo) < SEA_LEVEL_M) {
		return INFINITY;
	}
	return lo - 2.0;
}

// BuildingWalls._walls in batch mode, no party cover.
void walls(Row &row, int oct, int band, int mat, const Vector2 *ring, int nr, double base, double top,
		const Vector3 &uvp, double v_repeat) {
	double area = 0.0;
	for (int k = 0; k < nr; k++) {
		const Vector2 &p = ring[k];
		const Vector2 &q = ring[(k + 1) % nr];
		area += (double)p.x * (double)q.y - (double)q.x * (double)p.y;
	}
	bool ccw = area * 0.5 > 0.0;
	Add a;
	a.oct = oct;
	a.band = band;
	a.mat = mat;
	for (int k = 0; k < nr; k++) {
		Vector2 ea = ring[k];
		Vector2 eb = ring[(k + 1) % nr];
		if ((double)(eb - ea).length() < 0.001) {
			continue;
		}
		Vector2 nv = ccw ? Vector2((eb - ea).y, -(eb - ea).x).normalized()
						 : Vector2(-(eb - ea).y, (eb - ea).x).normalized();
		Vector2 pa = ea.lerp(eb, 0.0);
		Vector2 pb = ea.lerp(eb, 1.0);
		double u1 = 1.0;
		double v0 = 1.0;
		if (uvp.x > 0.0) {
			double len_m = (double)(pb - pa).length() / 1.0;
			u1 = len_m < (double)uvp.x * 0.5 ? 0.03 : Math::max(1.0, std::round(len_m / (double)uvp.x)) / (double)uvp.y;
			if (uvp.z > 0.0) {
				v0 = v_repeat;
			}
		}
		// BuildingWalls._quad
		Vector2 uv(u1, v0);
		Vector2 e = pb - pa;
		Vector3 n3(nv.x, 0.0, nv.y);
		int32_t kk = (int32_t)a.v.size();
		a.v.push_back(Vector3(pa.x, base, pa.y));
		a.v.push_back(Vector3(pb.x, base, pb.y));
		a.v.push_back(Vector3(pb.x, top, pb.y));
		a.v.push_back(Vector3(pa.x, top, pa.y));
		for (int j = 0; j < 4; j++) {
			a.n.push_back(n3);
		}
		a.uv.push_back(Vector2(0, uv.y));
		a.uv.push_back(Vector2(uv.x, uv.y));
		a.uv.push_back(Vector2(uv.x, 0));
		a.uv.push_back(Vector2(0, 0));
		double s = (double)e.x * (double)nv.y - (double)e.y * (double)nv.x;
		if (s > 0.0) {
			a.i.insert(a.i.end(), { kk, kk + 2, kk + 1, kk, kk + 3, kk + 2 });
		} else {
			a.i.insert(a.i.end(), { kk, kk + 1, kk + 2, kk, kk + 2, kk + 3 });
		}
	}
	if (!a.i.empty()) {
		row.adds.push_back(std::move(a));
	}
}

// BuildingWalls._roof_cap over the rect ring, idx [0, 1, 2, 0, 2, 3], no trim.
void roof_cap(Row &row, int oct, int band, int mat, const Vector2 *ring, double top) {
	const int32_t idx[6] = { 0, 1, 2, 0, 2, 3 };
	const Vector2 &p0 = ring[idx[0]];
	const Vector2 &p1 = ring[idx[1]];
	const Vector2 &p2 = ring[idx[2]];
	bool flip = ((double)p1.x - (double)p0.x) * ((double)p2.y - (double)p0.y) - ((double)p1.y - (double)p0.y) * ((double)p2.x - (double)p0.x) < 0.0;
	Add a;
	a.oct = oct;
	a.band = band;
	a.mat = mat;
	for (int k = 0; k < 4; k++) {
		a.v.push_back(Vector3(ring[k].x, top, ring[k].y));
		a.n.push_back(Vector3(0, 1, 0));
		a.uv.push_back(ring[k] * 0.05);
	}
	for (int t = 0; t < 2; t++) {
		int32_t i0 = idx[t * 3], i1 = idx[t * 3 + 1], i2 = idx[t * 3 + 2];
		if (flip) {
			a.i.insert(a.i.end(), { i0, i2, i1 });
		} else {
			a.i.insert(a.i.end(), { i0, i1, i2 });
		}
	}
	row.adds.push_back(std::move(a));
}

// FarCityBuilder._roof: low-poly pitched roof over the rect ring.
void pitched_roof(Row &row, int oct, int band, int mat, const Vector2 *ring, double top, double rh,
		const std::string &shape, const Vector2 &size, double yaw) {
	Vector2 c = (ring[0] + ring[2]) * 0.5;
	Vector2 ax = Vector2(1, 0).rotated(yaw);
	Vector2 az = Vector2(0, 1).rotated(yaw);
	double inset = 0.5;
	bool along_x = size.x >= size.y;
	if (shape == "gabled") {
		inset = 0.0;
	} else if (shape == "hipped" || shape == "mansard") {
		inset = 0.28;
	}
	double half_ridge = 0.0;
	if (shape == "gabled" || shape == "hipped" || shape == "mansard") {
		double longer = Math::max((double)size.x, (double)size.y);
		half_ridge = shape != "gabled" ? (longer * 0.5) * (1.0 - inset * 2.0) : longer * 0.5;
		half_ridge = Math::max(half_ridge, 0.0);
	}
	Vector2 dir = along_x ? ax : az;
	Vector2 r0 = c - dir * half_ridge;
	Vector2 r1 = c + dir * half_ridge;
	double apex_y = top + rh;
	Add a;
	a.oct = oct;
	a.band = band;
	a.mat = mat;
	for (int e = 0; e < 4; e++) {
		Vector2 pa2 = ring[e];
		Vector2 pb2 = ring[(e + 1) % 4];
		Vector2 mid = (pa2 + pb2) * 0.5;
		Vector2 pa = mid.distance_squared_to(r0) <= mid.distance_squared_to(r1) ? r0 : r1;
		Vector2 edge_dir = (pb2 - pa2).normalized();
		bool long_edge = std::abs((double)edge_dir.dot(dir)) > 0.7;
		Vector3 pts[4];
		int np = 0;
		pts[np++] = Vector3(pa2.x, top, pa2.y);
		pts[np++] = Vector3(pb2.x, top, pb2.y);
		if (long_edge && half_ridge > 0.01) {
			Vector2 q0 = (double)(r0 - pa2).dot(edge_dir) <= (double)(r1 - pa2).dot(edge_dir) ? r0 : r1;
			Vector2 q1 = q0 == r0 ? r1 : r0;
			pts[np++] = Vector3(q1.x, apex_y, q1.y);
			pts[np++] = Vector3(q0.x, apex_y, q0.y);
		} else {
			Vector2 p = half_ridge > 0.01 ? pa : c;
			pts[np++] = Vector3(p.x, apex_y, p.y);
		}
		Vector3 nrm = (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized();
		bool flip = (double)nrm.dot(Vector3((double)mid.x - (double)c.x, 0.01, (double)mid.y - (double)c.y)) < 0.0;
		if (flip) {
			nrm = -nrm;
		}
		int32_t k = (int32_t)a.v.size();
		for (int q = 0; q < np; q++) {
			a.v.push_back(pts[q]);
			a.n.push_back(nrm);
			a.uv.push_back(Vector2(pts[q].x, pts[q].z) * 0.05);
		}
		static const int tri3[3] = { 0, 1, 2 };
		static const int tri4[6] = { 0, 1, 2, 0, 2, 3 };
		const int *tris = np == 3 ? tri3 : tri4;
		int nt = np == 3 ? 3 : 6;
		for (int t = 0; t < nt; t += 3) {
			if (flip) {
				a.i.insert(a.i.end(), { k + tris[t], k + tris[t + 1], k + tris[t + 2] });
			} else {
				a.i.insert(a.i.end(), { k + tris[t], k + tris[t + 2], k + tris[t + 1] });
			}
		}
	}
	row.adds.push_back(std::move(a));
}

// FarCityBuilder._district
int district_of(const Vector2 &ctr) {
	constexpr double DISTRICT_M = 600.0;
	double px = std::floor((double)ctr.x / DISTRICT_M);
	double pz = std::floor((double)ctr.y / DISTRICT_M);
	double cx = (px + 0.5) * DISTRICT_M;
	double cz = (pz + 0.5) * DISTRICT_M;
	double old_share = Math::lerp(0.5, 0.15, Math::smoothstep(R_IN, RADIUS_M, std::sqrt(cx * cx + cz * cz)));
	double pick = city_hash(px, pz, 23.0);
	if (pick < old_share) {
		return -1;
	}
	return pick > 0.65 ? 1 : 0;
}

// FarCityBuilder._mass
void mass(const City &c, Row &row, const Vector2 &ctr, const Vector2 &size, double yaw,
		const Profile &prof, double d, const std::string &kind) {
	// BuildingWalls._rect_ring
	Vector2 ring[4];
	const Vector2 corners[4] = { Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1) };
	for (int k = 0; k < 4; k++) {
		ring[k] = ctr + (corners[k] * size * 0.5).rotated(yaw);
	}
	double base = site(c, ring, 4, Math::min((double)size.x, (double)size.y));
	if (std::isinf(base)) {
		return;
	}
	double seed_v = city_hash(ctr.x, ctr.y, 11.0);
	int lo = prof.st_lo;
	int hi = prof.st_hi;
	if (kind == "apartments") {
		// SettlementMap.score_at
		int ci = (int)std::floor((double)ctr.x / CELL_M) + c.half;
		int cj = (int)std::floor((double)ctr.y / CELL_M) + c.half;
		double sc = (ci < 0 || cj < 0 || ci >= c.n || cj >= c.n) ? 0.0 : (double)c.score[cj * c.n + ci];
		if (sc > 0.65) {
			lo += 1;
			hi = (int)std::ceil((double)hi * 1.3);
		}
	}
	int district = (kind == "apartments" || kind == "commercial") ? district_of(ctr) : 0;
	if (district != 0) {
		int mid = (int)((double)(lo + hi) * 0.5);
		if (district < 0) {
			hi = mid;
		} else {
			lo = mid;
		}
	}
	int storeys = lo + (int)(seed_v * (double)(hi - lo + 1));
	double fh = prof.fh;
	double wall = (double)storeys * fh;
	if (c.h_edge > 0.0 && kind == "apartments") {
		double near_h = c.h_edge * (0.65 + 0.7 * seed_v);
		wall = Math::lerp(near_h, wall, Math::smoothstep(R_IN, 4000.0, d));
		storeys = Math::max(1, (int)std::round(wall / fh));
	}
	std::string shape = pick_weighted(prof.roofs, seed_v, 3);
	if ((district < 0 && shape == "flat") || (district > 0 && shape != "flat")) {
		shape = pick_weighted(prof.roofs, seed_v, 29);
	}
	double span = Math::min((double)size.x, (double)size.y);
	double pitch = prof.pitch * (0.9 + 0.2 * city_hash(ctr.x, ctr.y, 41.0));
	double rh = roof_height_m(shape, span, pitch);
	if (shape != "flat") {
		wall = Math::max(wall - rh * 0.5, fh);
	}
	double top = base + 2.0 + wall;
	bool is_far = d >= SPLIT_M;
	int facade = (int)(seed_v * 97.0) % (is_far ? Math::min(2, c.n_dfs) : c.n_dfs);
	int roof = c.n_dfs + (is_far ? 0 : (int)(seed_v * 53.0) % c.n_drs);
	int oct, band;
	key_of(ctr.x, ctr.y, oct, band);
	walls(row, oct, band, facade, ring, 4, base, top, c.facade_uv[facade], (double)storeys);
	if (shape == "flat" || rh < 0.3) {
		roof_cap(row, oct, band, roof, ring, top);
	} else {
		pitched_roof(row, oct, band, roof, ring, top, rh, shape, size, yaw);
	}
	row.blocks++;
}

Profile read_profile(const Dictionary &d) {
	Profile p;
	Array st = d["st"];
	p.st_lo = st[0];
	p.st_hi = st[1];
	p.fh = d["fh"];
	p.pitch = d.get("pitch", 1.0);
	Array r = d["r"];
	for (int64_t k = 0; k < r.size(); k++) {
		Array pr = r[k];
		p.roofs.emplace_back(String(pr[0]).utf8().get_data(), (double)pr[1]);
	}
	return p;
}

// FarCityBuilder._fabric, one settlement-map row.
void fabric_row(const City &c, int j, Row &row) {
	const double r2_in = R_IN * R_IN;
	const double r2_out = RADIUS_M * RADIUS_M;
	for (int i = 0; i < c.n; i++) {
		int k = j * c.n + i;
		double s = c.score[k];
		if (s < MIN_SCORE || c.blocked[k] != 0) {
			continue;
		}
		// SettlementMap.centre
		Vector2 cc = Vector2(((double)(i - c.half) + 0.5) * CELL_M, ((double)(j - c.half) + 0.5) * CELL_M);
		double d2 = cc.length_squared();
		if (d2 < r2_in || d2 > r2_out || c.tower_cell[k]) {
			continue;
		}
		double d = std::sqrt(d2);
		int cls = c.cls[k];
		const Profile *prof = &c.apt;
		std::string kind = "apartments";
		if (cls == INDUSTRIAL) {
			prof = &c.ind;
			kind = "industrial";
		} else if (cls == COMMERCIAL) {
			prof = &c.com;
			kind = "commercial";
		} else if (s < 0.42) {
			prof = &c.house;
			kind = "house";
		}
		double yaw = city_hash(std::floor((double)i / 6.0), std::floor((double)j / 6.0), 3.0) * Math::PI * 0.5;
		double thin = Math::lerp(1.0, THIN_FAR, Math::smoothstep(SPLIT_M, RADIUS_M, d));
		double keep = Math::clamp((s - 0.12) / 0.45, 0.2, 1.0) * thin;
		int lots = d < SPLIT_M ? 2 : 1;
		double lot = CELL_M / (double)lots;
		for (int lj = 0; lj < lots; lj++) {
			for (int li = 0; li < lots; li++) {
				Vector2 lc = cc + Vector2(((double)li + 0.5) * lot - CELL_M * 0.5, ((double)lj + 0.5) * lot - CELL_M * 0.5);
				double hv = city_hash(lc.x, lc.y);
				if (hv > keep) {
					continue;
				}
				if (near_landmark(c, lc.x, lc.y)) {
					continue;
				}
				if (kind == "house") {
					for (int hi = 0; hi < 2; hi++) {
						Vector2 o((city_hash(lc.x, lc.y, 5.0 + hi) - 0.5) * lot * 0.5, ((double)hi - 0.5) * lot * 0.45);
						mass(c, row, lc + o.rotated(yaw),
								Vector2(Math::lerp(9.0, 14.0, city_hash(lc.x, lc.y, 7.0 + hi)), Math::lerp(7.0, 10.0, hv)),
								yaw, *prof, d, "house");
					}
				} else {
					double fill = kind == "industrial" ? 0.75 : 1.0;
					double side = (lot - STREET_M) * fill;
					// Footprints differ in size and sit off-centre in their
					// lot; some apartment lots hold a pair.
					Vector2 size(side * Math::lerp(0.55, 1.0, city_hash(lc.x, lc.y, 2.0)),
							side * Math::lerp(0.5, 1.0, city_hash(lc.x, lc.y, 4.0)));
					Vector2 slack = Vector2(side, side) - size;
					Vector2 at = lc + Vector2((city_hash(lc.x, lc.y, 13.0) - 0.5) * slack.x,
											  (city_hash(lc.x, lc.y, 17.0) - 0.5) * slack.y)
											  .rotated(yaw);
					if (kind == "apartments" && size.x > PAIR_MIN_M && city_hash(lc.x, lc.y, 19.0) < PAIR_SHARE) {
						double w = (size.x - PAIR_GAP_M) * 0.5;
						for (int pi = 0; pi < 2; pi++) {
							double off = ((double)pi - 0.5) * (w + PAIR_GAP_M);
							mass(c, row, at + Vector2(off, 0.0).rotated(yaw), Vector2(w, size.y), yaw, *prof, d, kind);
						}
					} else {
						mass(c, row, at, size, yaw, *prof, d, kind);
					}
				}
			}
		}
	}
}

} // namespace

Dictionary CityKernels::fabric(const Dictionary &city, const Dictionary &far_params, const Array &dem_rings) {
	City c;
	c.far = read_far(far_params, dem_rings);
	c.far_ok = city["far_ok"];
	c.sea = city["sea"];
	c.h_edge = city["h_edge"];
	c.n = city["n"];
	c.half = city["half"];
	c.score = city["score"];
	c.cls = city["cls"];
	c.blocked = city["blocked"];
	c.tower_cell.assign((size_t)c.n * c.n, 0);
	PackedInt32Array towers = city["tower_cells"];
	for (int64_t k = 0; k < towers.size(); k++) {
		if (towers[k] >= 0 && towers[k] < (int64_t)c.tower_cell.size()) {
			c.tower_cell[towers[k]] = 1;
		}
	}
	c.apt = read_profile(city["apt"]);
	c.house = read_profile(city["house"]);
	c.ind = read_profile(city["ind"]);
	c.com = read_profile(city["com"]);
	PackedVector2Array lms = city["landmarks"];
	for (int64_t k = 0; k < lms.size(); k++) {
		c.landmarks.push_back(lms[k]);
	}
	c.n_dfs = city["n_dfs"];
	c.n_drs = city["n_drs"];
	PackedVector3Array fuv = city["facade_uv"];
	for (int64_t k = 0; k < fuv.size(); k++) {
		c.facade_uv.push_back(fuv[k]);
	}
	c.chroma = (double)city.get("chroma", 0.0);
	c.tone = (double)city.get("tone", 0.0);
	PackedByteArray tint = city["tint"];
	for (int64_t k = 0; k < tint.size(); k++) {
		c.tint.push_back(tint[k]);
	}
	PackedInt32Array canon = city["canon"];
	for (int64_t k = 0; k < canon.size(); k++) {
		c.canon.push_back(canon[k]);
	}

	std::vector<Row> rows(c.n);
	parallel_for(c.n, [&](int j) { fabric_row(c, j, rows[j]); });

	// MassBatch.add, in the script's order: groups by first add.
	struct Group {
		int oct, band, mat;
		PackedVector3Array v, n;
		PackedVector2Array uv;
		PackedColorArray col;
		PackedInt32Array i;
	};
	std::vector<Group> groups;
	std::map<std::tuple<int, int, int>, size_t> at;
	int blocks = 0;
	int64_t tris = 0;
	for (Row &row : rows) {
		blocks += row.blocks;
		for (Add &a : row.adds) {
			int mat = c.canon[a.mat];
			auto key = std::make_tuple(a.oct, a.band, mat);
			auto it = at.find(key);
			if (it == at.end()) {
				it = at.emplace(key, groups.size()).first;
				groups.push_back(Group{ a.oct, a.band, mat });
			}
			Group &g = groups[it->second];
			int32_t base = (int32_t)g.v.size();
			// A roof takes half the wall's paint weight (RoofVariety.ROOF_CHROMA).
			double chroma = c.tint[a.mat] == TINT_ROOF ? c.chroma * 0.5 : c.chroma;
			Color t = tint_for(c.tint[a.mat], a.v[0], chroma, c.tone);
			for (size_t q = 0; q < a.v.size(); q++) {
				g.v.push_back(a.v[q]);
				g.n.push_back(a.n[q]);
				g.uv.push_back(a.uv[q]);
				g.col.push_back(t);
			}
			for (int32_t ix : a.i) {
				g.i.push_back(ix + base);
			}
			tris += (int64_t)a.i.size() / 3;
		}
	}
	Array out_groups;
	for (Group &g : groups) {
		Array e;
		e.push_back(String::num_int64(g.oct) + "," + String::num_int64(g.band));
		e.push_back(g.mat);
		e.push_back(g.v);
		e.push_back(g.n);
		e.push_back(g.uv);
		e.push_back(g.col);
		e.push_back(g.i);
		out_groups.push_back(e);
	}
	Dictionary out;
	out["groups"] = out_groups;
	out["blocks"] = blocks;
	out["tris"] = tris;
	return out;
}

Dictionary CityKernels::settlement_features(const Array &infos, int n, int half) {
	struct Drape {
		int id, width, height;
		double step;
		PackedFloat32Array col, row;
		PackedByteArray bytes;
	};
	std::vector<Drape> drapes;
	for (int k = 0; k < infos.size(); ++k) {
		Dictionary d = infos[k];
		drapes.push_back({int(d["di"]), int(d["w"]), int(d["h"]), double(d["step"]),
				d["col_uv"], d["row_uv"], d["buf"]});
	}
	PackedFloat64Array ls, gs, stds, brs;
	PackedByteArray ids, present;
	const int count = n * n;
	ls.resize(count); gs.resize(count); stds.resize(count); brs.resize(count);
	ids.resize(count); present.resize(count);
	for (int j = 0; j < n; ++j) {
		const double z = (double(j - half) + 0.5) * CELL_M;
		for (int i = 0; i < n; ++i) {
			const double x = (double(i - half) + 0.5) * CELL_M;
			if (x * x + z * z > RADIUS_M * RADIUS_M) continue;
			for (const Drape &d : drapes) {
				const double u = d.col[i], v = d.row[j];
				if (u <= 0.0 || u >= 1.0 || v <= 0.0 || v >= 1.0 || d.bytes.is_empty()) continue;
				const double px0 = u * double(d.width) - d.step * 2.0;
				const double pz0 = v * double(d.height) - d.step * 2.0;
				double sl = 0.0, sl2 = 0.0, sg = 0.0, sbr = 0.0;
				for (int sj = 0; sj < 5; ++sj) {
					const int pz = std::max(0, std::min(int(pz0 + d.step * double(sj)), d.height - 1));
					for (int si = 0; si < 5; ++si) {
						const int px = std::max(0, std::min(int(px0 + d.step * double(si)), d.width - 1));
						const int o = (pz * d.width + px) * 3;
						const double r = double(d.bytes[o]) / 255.0, g = double(d.bytes[o + 1]) / 255.0;
						const double b = double(d.bytes[o + 2]) / 255.0;
						const double l = 0.299 * r + 0.587 * g + 0.114 * b;
						sl += l; sl2 += l * l; sg += g - (r + b) * 0.5; sbr += b - r;
					}
				}
				const int index = j * n + i;
				const double mean = sl / 25.0;
				ls.set(index, mean); gs.set(index, sg / 25.0);
				stds.set(index, std::sqrt(std::max(sl2 / 25.0 - mean * mean, 0.0)));
				brs.set(index, sbr / 25.0); ids.set(index, d.id); present.set(index, 1);
				break;
			}
		}
	}
	Dictionary out;
	out["l"] = ls; out["g"] = gs; out["std"] = stds; out["br"] = brs;
	out["drape"] = ids; out["present"] = present;
	return out;
}

Dictionary CityKernels::settlement_finish(const Dictionary &features, const Dictionary &l0,
		const Dictionary &g0, int n) {
	PackedFloat64Array ls = features["l"], gs = features["g"], stds = features["std"], brs = features["br"];
	PackedByteArray ids = features["drape"], present = features["present"];
	PackedFloat32Array raw, score;
	PackedByteArray blocked, cls;
	const int count = n * n;
	raw.resize(count); score.resize(count); blocked.resize(count); cls.resize(count);
	for (int k = 0; k < count; ++k) {
		if (!present[k]) continue;
		const int di = ids[k];
		const double l = ls[k], g = gs[k], lmed = l0[di], gmed = g0[di];
		int cover = 0;
		if (brs[k] > 0.06) cover = 2;
		else if (g > gmed + 0.025) cover = 1;
		else if (l < 0.7 * lmed && g < gmed + 0.01) cover = 2;
		blocked.set(k, cover);
		if (cover == 0) {
			const double not_green = std::clamp((gmed + 0.02 - g) / 0.03, 0.0, 1.0);
			const double not_dark = std::clamp((l - 0.75 * lmed) / std::max(0.25 * lmed, 0.01), 0.0, 1.0);
			const double busy = std::clamp((stds[k] - 0.06) / 0.06, 0.0, 1.0);
			raw.set(k, not_green * not_dark * busy);
		}
	}
	for (int j = 0; j < n; ++j) {
		for (int i = 0; i < n; ++i) {
			const int k = j * n + i;
			if (blocked[k]) continue;
			double sum = 0.0, weight = 0.0;
			for (int dj = -1; dj <= 1; ++dj) {
				for (int di = -1; di <= 1; ++di) {
					const int ii = i + di, jj = j + dj;
					if (ii < 0 || jj < 0 || ii >= n || jj >= n) continue;
					const double wt = di == 0 && dj == 0 ? 4.0 : 1.0;
					sum += double(raw[jj * n + ii]) * wt;
					weight += wt;
				}
			}
			score.set(k, sum / weight);
			if (score[k] > 0.0) cls.set(k, RESIDENTIAL);
		}
	}
	Dictionary out;
	out["score"] = score; out["blocked"] = blocked; out["cls"] = cls;
	return out;
}

void CityKernels::_bind_methods() {
	ClassDB::bind_static_method("CityKernels", D_METHOD("fabric", "city", "far", "dem_rings"),
			&CityKernels::fabric);
	ClassDB::bind_static_method("CityKernels", D_METHOD("settlement_features", "infos", "n", "half"),
			&CityKernels::settlement_features);
	ClassDB::bind_static_method("CityKernels", D_METHOD("settlement_finish", "features", "l0", "g0", "n"),
			&CityKernels::settlement_finish);
}

} // namespace godot
