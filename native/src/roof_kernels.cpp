#include "roof_kernels.h"

#include "earcut_kernels.h"
#include "parallel.h"

#include <godot_cpp/classes/geometry2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <array>
#include <cmath>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace godot {

namespace {

using Ring = PackedVector2Array;

// Scalar arithmetic in the scripts is double; vector components are
// float32 and widen on read (D()).
inline double D(real_t v) {
	return (double)v;
}

// RoofGeometry
constexpr double INSET_MIN_AREA_M2 = 380.0;
constexpr double INSET_CONVEX_RATIO = 0.94;
// RoofForms
const char *const RIDGED[] = { "gabled", "hipped", "mansard", "gambrel", "half-hipped", "saltbox" };
constexpr int BARREL_SEGMENTS = 8;
// RoofDomes
constexpr int DOME_STEPS = 8;
constexpr int MIN_SIDES = 24;

bool is_ridged(const std::string &s) {
	for (const char *r : RIDGED) {
		if (s == r) {
			return true;
		}
	}
	return false;
}

double hip_end(const std::string &s) {
	if (s == "gabled" || s == "gambrel" || s == "saltbox") {
		return 0.98;
	}
	if (s == "hipped" || s == "mansard") {
		return 0.45;
	}
	if (s == "half-hipped") {
		return 0.72;
	}
	return 0.98;
}

// Plain vectors while building (a packed array's push_back is a call
// through the extension API); packed once in RoofKernels::form.
struct Faces {
	std::vector<Vector3> verts, normals;
	std::vector<Vector2> uvs;
};

template <typename P, typename T>
P packed(const std::vector<T> &v) {
	P out;
	out.resize((int64_t)v.size());
	if (!v.empty()) {
		std::memcpy(out.ptrw(), v.data(), v.size() * sizeof(T));
	}
	return out;
}

// --- RingGeometry ---

double signed_area(const Ring &ring) {
	double a = 0.0;
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 p = ring[i];
		Vector2 q = ring[(i + 1) % n];
		a += D(p.x) * D(q.y) - D(q.x) * D(p.y);
	}
	return a * 0.5;
}

Vector2 centroid(const Ring &ring) {
	Vector2 c;
	for (int64_t i = 0; i < ring.size(); i++) {
		c += ring[i];
	}
	return c / (double)Math::max((int64_t)ring.size(), (int64_t)1);
}

bool point_in_ring(const Vector2 &p, const Ring &ring) {
	bool inside = false;
	int64_t n = ring.size();
	int64_t j = n - 1;
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i];
		Vector2 b = ring[j];
		if ((D(a.y) > D(p.y)) != (D(b.y) > D(p.y)) &&
				D(p.x) < (D(b.x) - D(a.x)) * (D(p.y) - D(a.y)) / (D(b.y) - D(a.y)) + D(a.x)) {
			inside = !inside;
		}
		j = i;
	}
	return inside;
}

Vector2 interior_point(const Ring &ring) {
	Vector2 c = centroid(ring);
	if (point_in_ring(c, ring)) {
		return c;
	}
	const Vector2 nudges[3] = { Vector2(0.03, 0.02), Vector2(-0.02, 0.03), Vector2(0.02, -0.03) };
	for (const Vector2 &n : nudges) {
		if (point_in_ring(c + n, ring)) {
			return c + n;
		}
	}
	return c;
}

Vector2 fold(Vector2 axis) {
	if (D(axis.x) < -0.000001 || (std::abs(D(axis.x)) <= 0.000001 && D(axis.y) < 0.0)) {
		axis = -axis;
	}
	return axis;
}

Vector2 dominant_axis(const Ring &ring) {
	double best = 0.0;
	Vector2 axis(1, 0);
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 e = ring[(i + 1) % n] - ring[i];
		if (D(e.length_squared()) > best + 0.000001) {
			best = e.length_squared();
			axis = e;
		}
	}
	return fold(axis.normalized());
}

double half_extent(const Ring &ring, const Vector2 &c, const Vector2 &axis) {
	double e = 0.0;
	for (int64_t i = 0; i < ring.size(); i++) {
		e = Math::max(e, std::abs(D((ring[i] - c).dot(axis))));
	}
	return e;
}

// --- RoofGeometry.push_tri / slope_axes / tangents_for ---

void slope_axes(const Vector3 &n, const Vector2 &fu, Vector3 &along, Vector3 &down) {
	Vector2 h(n.x, n.z);
	if (D(h.length()) < 0.05) {
		along = Vector3(1, 0, 0);
		down = Vector3(0, 0, 1);
		return;
	}
	h = h.normalized();
	if (fu != Vector2()) {
		Vector2 f = fu.normalized();
		double q = std::round(std::atan2(D(h.dot(Vector2(-f.y, f.x))), D(h.dot(f))) / (Math::PI * 0.5)) * (Math::PI * 0.5);
		h = f.rotated(q);
	}
	Vector3 d(h.x, 0.0, h.y);
	down = (d - n * d.dot(n)).normalized();
	along = Vector3(-h.y, 0.0, h.x);
}

void push_tri(Faces &f, const Vector2 &c, Vector3 v0, Vector3 v1, Vector3 v2, const Vector2 &fu,
		bool up_only = false) {
	Vector3 front = (v2 - v0).cross(v1 - v0);
	if (D(front.length_squared()) < 0.00000001) {
		return;
	}
	front = front.normalized();
	Vector3 mid = (v0 + v1 + v2) / 3.0;
	Vector3 ref = up_only ? Vector3(0.0, 1.0, 0.0) : Vector3(D(mid.x) - D(c.x), 0.35, D(mid.z) - D(c.y));
	if (D(front.dot(ref)) < 0.0) {
		std::swap(v1, v2);
		front = -front;
	}
	f.verts.push_back(v0);
	f.verts.push_back(v1);
	f.verts.push_back(v2);
	for (int j = 0; j < 3; j++) {
		f.normals.push_back(front);
	}
	Vector3 ax0, ax1;
	slope_axes(front, fu, ax0, ax1);
	for (const Vector3 &v : { v0, v1, v2 }) {
		f.uvs.push_back(Vector2(v.dot(ax0), v.dot(ax1)) * 0.05);
	}
}

PackedFloat32Array tangents_for(const std::vector<Vector3> &normals, const Vector2 &fu) {
	PackedFloat32Array out;
	out.resize(normals.size() * 4);
	float *o = out.ptrw();
	bool have = false;
	Vector3 last_n(INFINITY, INFINITY, INFINITY);
	Vector3 last_t, last_d;
	float last_w = 0.0f;
	for (size_t k = 0; k < normals.size(); k++) {
		Vector3 n = normals[k];
		if (!have || n != last_n) {
			slope_axes(n, fu, last_t, last_d);
			last_n = n;
			have = true;
			last_w = D(n.cross(last_t).dot(-last_d)) > 0.0 ? 1.0f : -1.0f;
		}
		o[k * 4] = last_t.x;
		o[k * 4 + 1] = last_t.y;
		o[k * 4 + 2] = last_t.z;
		o[k * 4 + 3] = last_w;
	}
	return out;
}

bool needs_inset(const Ring &ring) {
	double area = std::abs(signed_area(ring));
	if (area / (1.0 * 1.0) < INSET_MIN_AREA_M2) {
		return false;
	}
	double hull_area = std::abs(signed_area(Geometry2D::get_singleton()->convex_hull(ring)));
	return hull_area > 0.0 && area / hull_area < INSET_CONVEX_RATIO;
}

void apex_faces(Faces &f, const Ring &ring, const Vector2 &c, double top, double rh, bool domed,
		const Vector2 &fu) {
	Vector3 apex(c.x, top + rh, c.y);
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i];
		Vector2 b = ring[(i + 1) % n];
		if (D((b - a).length()) < 0.001) {
			continue;
		}
		if (domed) {
			Vector2 ma = a.lerp(c, 0.42);
			Vector2 mb = b.lerp(c, 0.42);
			Vector3 a3(a.x, top, a.y);
			Vector3 b3(b.x, top, b.y);
			Vector3 ma3(ma.x, top + rh * 0.70, ma.y);
			Vector3 mb3(mb.x, top + rh * 0.70, mb.y);
			if (point_in_ring((a + b + ma + mb) * 0.25, ring)) {
				push_tri(f, c, a3, b3, mb3, fu);
				push_tri(f, c, a3, mb3, ma3, fu);
			}
			if (point_in_ring((ma + mb + c) / 3.0, ring)) {
				push_tri(f, c, ma3, mb3, apex, fu);
			}
		} else if (point_in_ring((a + b + c) / 3.0, ring)) {
			push_tri(f, c, Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), apex, fu);
		}
	}
}

// --- RoofForms ---

bool has_party(const Ring &ring, const PackedByteArray &party) {
	return party.size() == ring.size() && party.has(1);
}

// PartyWalls.outward (not a courtyard ring).
Vector2 outward(const Ring &ring, int64_t i) {
	bool ccw = signed_area(ring) > 0.0;
	Vector2 e = ring[(i + 1) % ring.size()] - ring[i];
	return ccw ? Vector2(e.y, -e.x).normalized() : Vector2(-e.y, e.x).normalized();
}

Vector2 party_axis(const Ring &ring, const PackedByteArray &party) {
	double best = -1.0;
	Vector2 axis(1, 0);
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		if (party[i] == 0) {
			continue;
		}
		Vector2 e = ring[(i + 1) % n] - ring[i];
		if (D(e.length_squared()) > best) {
			best = e.length_squared();
			axis = Vector2(e.y, -e.x).normalized();
		}
	}
	return fold(axis);
}

bool end_party(const Ring &ring, const PackedByteArray &party, const Vector2 &dir) {
	for (int64_t i = 0; i < ring.size(); i++) {
		if (party[i] == 1 && D(outward(ring, i).dot(dir)) > 0.7) {
			return true;
		}
	}
	return false;
}

Vector2 ridge_axis(const Ring &ring, const PackedByteArray &party, bool gable_front) {
	if (has_party(ring, party)) {
		Vector2 pu = party_axis(ring, party);
		return gable_front ? Vector2(-pu.y, pu.x) : pu;
	}
	return dominant_axis(ring);
}

bool boxy(const Ring &ring) {
	if (ring.size() > 8) {
		return false;
	}
	Vector2 u = dominant_axis(ring);
	Vector2 v(-u.y, u.x);
	Vector2 c = centroid(ring);
	Vector2 lo(INFINITY, INFINITY);
	Vector2 hi(-INFINITY, -INFINITY);
	for (int64_t i = 0; i < ring.size(); i++) {
		Vector2 p = ring[i];
		Vector2 q((p - c).dot(u), (p - c).dot(v));
		lo = lo.min(q);
		hi = hi.max(q);
	}
	double box = (D(hi.x) - D(lo.x)) * (D(hi.y) - D(lo.y));
	return box > 0.0 && std::abs(signed_area(ring)) / box > 0.85;
}

double fit(const Vector2 &c, const Vector2 &dir, double len, const Ring &ring) {
	int guard = 0;
	while (len > 0.05 && guard < 12 && !point_in_ring(c + dir * len, ring)) {
		len *= 0.85;
		guard++;
	}
	return len > 0.05 && point_in_ring(c + dir * len, ring) ? len : 0.0;
}

void one_pitch(Faces &f, const Ring &ring, const Vector2 &c, const Vector2 &u, const Vector2 &r1,
		const Vector2 &r2, double top, double rh) {
	Vector2 d = r2 - r1;
	double denom = Math::max(D(d.length_squared()), 0.000001);
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i];
		Vector2 b = ring[(i + 1) % n];
		if (D((b - a).length()) < 0.001) {
			continue;
		}
		Vector2 pa = r1 + d * Math::clamp(D((a - r1).dot(d)) / denom, 0.0, 1.0);
		Vector2 pb = r1 + d * Math::clamp(D((b - r1).dot(d)) / denom, 0.0, 1.0);
		Vector3 a3(a.x, top, a.y);
		Vector3 b3(b.x, top, b.y);
		Vector3 pa3(pa.x, top + rh, pa.y);
		Vector3 pb3(pb.x, top + rh, pb.y);
		push_tri(f, c, a3, pa3, pb3, u);
		push_tri(f, c, a3, pb3, b3, u);
	}
}

void two_pitch(Faces &f, const Ring &ring, const Vector2 &c, const Vector2 &u, const Vector2 &r1,
		const Vector2 &r2, double top, double rh, double run, double rise, double max_run) {
	Vector2 d = r2 - r1;
	double denom = Math::max(D(d.length_squared()), 0.000001);
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i];
		Vector2 b = ring[(i + 1) % n];
		if (D((b - a).length()) < 0.001) {
			continue;
		}
		Vector2 qa = r1 + d * Math::clamp(D((a - r1).dot(d)) / denom, 0.0, 1.0);
		Vector2 qb = r1 + d * Math::clamp(D((b - r1).dot(d)) / denom, 0.0, 1.0);
		Vector3 a3(a.x, top, a.y);
		Vector3 b3(b.x, top, b.y);
		Vector2 ma = a.lerp(qa, Math::min(run, max_run / Math::max(D(a.distance_to(qa)), 0.001)));
		Vector2 mb = b.lerp(qb, Math::min(run, max_run / Math::max(D(b.distance_to(qb)), 0.001)));
		Vector3 ma3(ma.x, top + rh * rise, ma.y);
		Vector3 mb3(mb.x, top + rh * rise, mb.y);
		Vector3 ta3(qa.x, top + rh, qa.y);
		Vector3 tb3(qb.x, top + rh, qb.y);
		push_tri(f, c, a3, b3, mb3, u);
		push_tri(f, c, a3, mb3, ma3, u);
		push_tri(f, c, ma3, mb3, tb3, u);
		push_tri(f, c, ma3, tb3, ta3, u);
	}
}

bool ridged(Faces &f, const Ring &ring, const Vector2 &c, double top, double rh, const std::string &shape,
		const PackedByteArray &party, bool gable_front) {
	Vector2 u = ridge_axis(ring, party, gable_front);
	bool hp = has_party(ring, party);
	Vector2 v(-u.y, u.x);
	double lo = INFINITY;
	double hi = -INFINITY;
	for (int64_t i = 0; i < ring.size(); i++) {
		double d = (ring[i] - c).dot(u);
		lo = Math::min(lo, d);
		hi = Math::max(hi, d);
	}
	double keep = hip_end(shape);
	double k_hi = hp && end_party(ring, party, u) ? 0.995 : keep;
	double k_lo = hp && end_party(ring, party, -u) ? 0.995 : keep;
	Vector2 off = shape == "saltbox" ? v * (half_extent(ring, c, v) * 0.35) : Vector2();
	double e_hi = fit(c + off, u, hi * k_hi, ring);
	double e_lo = fit(c + off, -u, -lo * k_lo, ring);
	if (e_hi <= 0.0 && e_lo <= 0.0) {
		return false;
	}
	Vector2 r1 = c + off + u * e_hi;
	Vector2 r2 = c + off - u * e_lo;
	if (shape == "mansard") {
		two_pitch(f, ring, c, u, r1, r2, top, rh, 0.38, 0.75, 1.5 * 1.0);
	} else if (shape == "gambrel") {
		two_pitch(f, ring, c, u, r1, r2, top, rh, 0.30, 0.55, 99.0 * 1.0);
	} else {
		one_pitch(f, ring, c, u, r1, r2, top, rh);
	}
	return true;
}

void skillion(Faces &f, const Ring &ring, const Vector2 &c, double top, double rh, const PackedByteArray &party) {
	Vector2 u = dominant_axis(ring);
	Vector2 v(-u.y, u.x);
	if (has_party(ring, party)) {
		v = party_axis(ring, party);
		if (!end_party(ring, party, v)) {
			v = -v;
		}
	}
	double lv = Math::max(half_extent(ring, c, v), 0.01);
	int64_t n = ring.size();
	std::vector<float> hs(n);
	for (int64_t i = 0; i < n; i++) {
		hs[i] = (float)(top + rh * Math::clamp(0.5 + 0.5 * D((ring[i] - c).dot(v)) / lv, 0.0, 1.0));
	}
	PackedInt32Array idx = Geometry2D::get_singleton()->triangulate_polygon(ring);
	for (int64_t k = 0; k + 2 < idx.size(); k += 3) {
		Vector2 p0 = ring[idx[k]];
		Vector2 p1 = ring[idx[k + 1]];
		Vector2 p2 = ring[idx[k + 2]];
		push_tri(f, c, Vector3(p0.x, hs[idx[k]], p0.y), Vector3(p1.x, hs[idx[k + 1]], p1.y),
				Vector3(p2.x, hs[idx[k + 2]], p2.y), u, true);
	}
	for (int64_t i = 0; i < n; i++) {
		int64_t j = (i + 1) % n;
		Vector2 a = ring[i];
		Vector2 b = ring[j];
		if ((double)hs[i] - top < 0.01 && (double)hs[j] - top < 0.01) {
			continue;
		}
		push_tri(f, c, Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), Vector3(b.x, hs[j], b.y), u);
		push_tri(f, c, Vector3(a.x, top, a.y), Vector3(b.x, hs[j], b.y), Vector3(a.x, hs[i], a.y), u);
	}
}

bool barrel(Faces &f, const Ring &ring, const Vector2 &c, double top, double rh) {
	if (ring.size() != 4) {
		return false;
	}
	Vector2 u = dominant_axis(ring);
	Vector2 v(-u.y, u.x);
	double lu = half_extent(ring, c, u);
	double lv = half_extent(ring, c, v);
	Vector3 prev_a, prev_b;
	for (int s = 0; s < BARREL_SEGMENTS + 1; s++) {
		double ang = Math::PI * (double)s / (double)BARREL_SEGMENTS;
		double dv = -std::cos(ang) * lv;
		double y = top + std::sin(ang) * rh;
		Vector2 pa = c + u * lu + v * dv;
		Vector2 pb = c - u * lu + v * dv;
		Vector3 a3(pa.x, y, pa.y);
		Vector3 b3(pb.x, y, pb.y);
		if (s > 0) {
			push_tri(f, c, prev_a, a3, b3, u, true);
			push_tri(f, c, prev_a, b3, prev_b, u, true);
			Vector2 m0 = c + u * lu;
			Vector2 m1 = c - u * lu;
			push_tri(f, c, prev_a, a3, Vector3(m0.x, top, m0.y), u);
			push_tri(f, c, prev_b, b3, Vector3(m1.x, top, m1.y), u);
		}
		prev_a = a3;
		prev_b = b3;
	}
	return true;
}

// --- RoofDomes ---

bool star_shaped(const Ring &ring, const Vector2 &c) {
	double turn = 0.0;
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i] - c;
		Vector2 b = ring[(i + 1) % n] - c;
		double cr = a.cross(b);
		if (std::abs(cr) < 0.000001) {
			if (D(a.dot(b)) <= 0.0) {
				return false;
			}
			continue;
		}
		if (turn == 0.0) {
			turn = Math::sign(cr);
		} else if (Math::sign(cr) != turn) {
			return false;
		}
	}
	return turn != 0.0;
}

Ring subdivided(const Ring &ring, int sides) {
	if (ring.size() >= sides) {
		return ring;
	}
	int per = (int)std::ceil((double)sides / (double)ring.size());
	Ring out;
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i];
		Vector2 b = ring[(i + 1) % n];
		for (int s = 0; s < per; s++) {
			out.push_back(a.lerp(b, (double)s / (double)per));
		}
	}
	return out;
}

Vector2 edge_normal(const Vector2 &a, const Vector2 &b, const Vector2 &c) {
	Vector2 e = b - a;
	if (D(e.length()) < 0.0001) {
		return Vector2();
	}
	Vector2 nn = Vector2(e.y, -e.x).normalized();
	return D(nn.dot((a + b) * 0.5 - c)) < 0.0 ? -nn : nn;
}

void dome_tri(Faces &f, const Vector3 p[3], const Vector3 nrm[3], const Vector2 uv[3]) {
	Vector3 front = (p[2] - p[0]).cross(p[1] - p[0]);
	if (D(front.length_squared()) < 0.00000001) {
		return;
	}
	Vector3 mean = nrm[0] + nrm[1] + nrm[2];
	int order[3] = { 0, 1, 2 };
	if (D(front.dot(mean)) < 0.0) {
		order[1] = 2;
		order[2] = 1;
	}
	for (int o : order) {
		f.verts.push_back(p[o]);
		f.normals.push_back(nrm[o]);
		f.uvs.push_back(uv[o]);
	}
}

bool domes(Faces &f, const Ring &ring, const Vector2 &c, double top, double rh, const std::string &shape) {
	if ((shape != "dome" && shape != "onion" && shape != "cone") || ring.size() < 3 || !star_shaped(ring, c)) {
		return false;
	}
	Ring base = shape == "cone" ? ring : subdivided(ring, MIN_SIDES);
	std::vector<std::pair<double, double>> prof;
	if (shape == "onion") {
		prof = { { 1.0, 0.0 }, { 1.18, 0.12 }, { 1.28, 0.25 }, { 1.24, 0.38 }, { 1.05, 0.52 },
			{ 0.75, 0.64 }, { 0.45, 0.75 }, { 0.22, 0.86 }, { 0.08, 0.95 }, { 0.0, 1.0 } };
	} else if (shape == "cone") {
		prof = { { 1.0, 0.0 }, { 0.0, 1.0 } };
	} else {
		for (int i = 0; i < DOME_STEPS + 1; i++) {
			double t = (double)i / DOME_STEPS * Math::PI * 0.5;
			prof.emplace_back(std::cos(t), std::sin(t));
		}
	}
	int64_t n = base.size();
	std::vector<Vector2> out_n;
	std::vector<float> apo, along;
	double run = 0.0;
	for (int64_t i = 0; i < n; i++) {
		Vector2 p = base[i];
		Vector2 nn = edge_normal(base[(i - 1 + n) % n], p, c) + edge_normal(p, base[(i + 1) % n], c);
		nn = D(nn.length()) > 0.0001 ? nn.normalized() : (p - c).normalized();
		out_n.push_back(nn);
		apo.push_back((float)Math::max(D((p - c).dot(nn)), 0.0001));
		along.push_back((float)run);
		run += D(p.distance_to(base[(i + 1) % n]));
	}
	int np = (int)prof.size();
	std::vector<std::vector<Vector3>> rings(np), ring_n(np);
	std::vector<float> arc;
	double s_len = 0.0;
	for (int k = 0; k < np; k++) {
		double s = prof[k].first;
		double h = prof[k].second;
		int k0 = Math::max(k - 1, 0);
		int k1 = Math::min(k + 1, np - 1);
		double ds = prof[k1].first - prof[k0].first;
		double dh = prof[k1].second - prof[k0].second;
		if (k > 0) {
			double r_mean = ((double)apo[0] + (double)apo[n >> 1]) * 0.5;
			s_len += D(Vector2((s - prof[k - 1].first) * r_mean, (h - prof[k - 1].second) * rh).length());
		}
		arc.push_back((float)s_len);
		for (int64_t i = 0; i < n; i++) {
			Vector2 q = c + (base[i] - c) * s;
			rings[k].push_back(Vector3(q.x, top + rh * h, q.y));
			Vector2 o = out_n[i];
			Vector2 v = Vector2(rh * dh, -(double)apo[i] * ds).normalized();
			if (k == np - 1 && shape != "cone") {
				v = Vector2(0.0, 1.0);
			}
			ring_n[k].push_back(Vector3(D(o.x) * D(v.x), v.y, D(o.y) * D(v.x)).normalized());
		}
	}
	size_t before = f.verts.size();
	for (int k = 0; k < np - 1; k++) {
		for (int64_t i = 0; i < n; i++) {
			int64_t j = (i + 1) % n;
			double u0 = (double)along[i] * 0.05;
			double u1 = ((double)along[i] + D(base[i].distance_to(base[j]))) * 0.05;
			double v0 = -(double)arc[k] * 0.05;
			double v1 = -(double)arc[k + 1] * 0.05;
			const Vector3 pa[3] = { rings[k][i], rings[k][j], rings[k + 1][j] };
			const Vector3 na[3] = { ring_n[k][i], ring_n[k][j], ring_n[k + 1][j] };
			const Vector2 ua[3] = { Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1) };
			dome_tri(f, pa, na, ua);
			const Vector3 pb[3] = { rings[k][i], rings[k + 1][j], rings[k + 1][i] };
			const Vector3 nb[3] = { ring_n[k][i], ring_n[k + 1][j], ring_n[k + 1][i] };
			const Vector2 ub[3] = { Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1) };
			dome_tri(f, pb, nb, ub);
		}
	}
	return f.verts.size() > before;
}

// --- RoofSkeleton ---

using Rings = std::vector<Ring>;

struct RegionComp {
	Ring outer;
	Rings holes;
};

using Region = std::vector<RegionComp>;

constexpr double MIN_AREA_M2 = 0.02;

Rings to_rings(const TypedArray<PackedVector2Array> &a) {
	Rings out;
	out.reserve((size_t)a.size());
	for (int64_t i = 0; i < a.size(); i++) {
		out.push_back(a[i]);
	}
	return out;
}

bool in_any(const Vector2 &p, const Rings &rings) {
	for (const Ring &r : rings) {
		if (point_in_ring(p, r)) {
			return true;
		}
	}
	return false;
}

void split_winding(const Rings &polys, double min_area, Rings &outers, Rings &holes) {
	Geometry2D *g = Geometry2D::get_singleton();
	double largest = 0.0;
	bool cw = false;
	for (const Ring &p : polys) {
		if (p.size() < 3) {
			continue;
		}
		double a = std::abs(signed_area(p));
		if (a > largest) {
			largest = a;
			cw = g->is_polygon_clockwise(p);
		}
	}
	if (largest < min_area) {
		return;
	}
	for (const Ring &p : polys) {
		if (p.size() < 3 || std::abs(signed_area(p)) < min_area) {
			continue;
		}
		if (g->is_polygon_clockwise(p) == cw) {
			outers.push_back(p);
		} else {
			holes.push_back(p);
		}
	}
}

Rings solid_rings(const TypedArray<PackedVector2Array> &polys, double min_area) {
	Rings outers, holes;
	split_winding(to_rings(polys), min_area, outers, holes);
	return outers;
}

Rings merge_disjoint(Rings rings, double min_area) {
	if (rings.size() <= 1) {
		return rings;
	}
	Geometry2D *g = Geometry2D::get_singleton();
	size_t i = 0;
	while (i < rings.size()) {
		bool merged = false;
		for (size_t j = i + 1; j < rings.size(); j++) {
			if (!g->intersect_polygons(rings[i], rings[j]).is_empty()) {
				Rings u = solid_rings(g->merge_polygons(rings[i], rings[j]), min_area);
				if (u.size() == 1) {
					rings[i] = u[0];
					rings.erase(rings.begin() + (ptrdiff_t)j);
					merged = true;
					break;
				}
			}
		}
		if (!merged) {
			i++;
		}
	}
	return rings;
}

Region inset_region(const Region &comps, double dd, double min_area) {
	Geometry2D *g = Geometry2D::get_singleton();
	Region out;
	for (const RegionComp &c : comps) {
		Rings shrunk = solid_rings(g->offset_polygon(c.outer, -dd, Geometry2D::JOIN_MITER), min_area);
		if (shrunk.empty()) {
			continue;
		}
		if (c.holes.empty()) {
			for (const Ring &s : shrunk) {
				out.push_back({ s, {} });
			}
			continue;
		}
		Rings grown;
		for (const Ring &h : c.holes) {
			Rings gh = solid_rings(g->offset_polygon(h, dd, Geometry2D::JOIN_MITER), min_area);
			grown.insert(grown.end(), gh.begin(), gh.end());
		}
		grown = merge_disjoint(std::move(grown), min_area);
		for (const Ring &s : shrunk) {
			Region pieces;
			pieces.push_back({ s, {} });
			for (const Ring &gr : grown) {
				Region next_pieces;
				for (const RegionComp &p : pieces) {
					TypedArray<PackedVector2Array> clipped = g->clip_polygons(p.outer, gr);
					if (clipped.is_empty()) {
						continue;
					}
					Rings new_outers, new_holes;
					split_winding(to_rings(clipped), min_area, new_outers, new_holes);
					for (const Ring &no : new_outers) {
						Rings hs;
						for (const Ring &nh : new_holes) {
							if (point_in_ring(nh[0], no)) {
								hs.push_back(nh);
							}
						}
						for (const Ring &eh : p.holes) {
							if (point_in_ring(eh[0], no) && !in_any(eh[0], hs)) {
								hs.push_back(eh);
							}
						}
						next_pieces.push_back({ no, std::move(hs) });
					}
				}
				pieces = std::move(next_pieces);
			}
			out.insert(out.end(), pieces.begin(), pieces.end());
		}
	}
	return out;
}

double orient2d(const Vector2 &a, const Vector2 &b, const Vector2 &c) {
	return (D(b.x) - D(a.x)) * (D(c.y) - D(a.y)) - (D(b.y) - D(a.y)) * (D(c.x) - D(a.x));
}

bool in_circle(const Vector2 &a, const Vector2 &b, const Vector2 &c, const Vector2 &d) {
	double adx = D(a.x) - D(d.x), ady = D(a.y) - D(d.y);
	double bdx = D(b.x) - D(d.x), bdy = D(b.y) - D(d.y);
	double cdx = D(c.x) - D(d.x), cdy = D(c.y) - D(d.y);
	double al = adx * adx + ady * ady;
	double bl = bdx * bdx + bdy * bdy;
	double cl = cdx * cdx + cdy * cdy;
	double det = al * (bdx * cdy - bdy * cdx) - bl * (adx * cdy - ady * cdx) + cl * (adx * bdy - ady * bdx);
	double sc = Math::max(al, Math::max(bl, cl));
	return det > 1e-6 * sc * sc;
}

void lawson_cdt(const std::vector<Vector2> &pts, std::vector<std::array<int32_t, 3>> &tris) {
	constexpr int max_passes = 32;
	bool changed = true;
	std::vector<uint8_t> used;
	for (int pass = 0; pass < max_passes && changed; pass++) {
		changed = false;
		std::map<std::pair<int32_t, int32_t>, std::vector<std::pair<size_t, int>>> edges;
		for (size_t ti = 0; ti < tris.size(); ti++) {
			for (int e = 0; e < 3; e++) {
				int32_t u = tris[ti][e];
				int32_t v = tris[ti][(e + 1) % 3];
				edges[{ Math::min(u, v), Math::max(u, v) }].emplace_back(ti, e);
			}
		}
		used.assign(tris.size(), 0);
		for (const auto &kv : edges) {
			const auto &pair = kv.second;
			if (pair.size() != 2) {
				continue;
			}
			size_t t0 = pair[0].first;
			size_t t1 = pair[1].first;
			if (used[t0] || used[t1]) {
				continue;
			}
			int e0 = pair[0].second;
			int e1 = pair[1].second;
			int32_t a = tris[t0][e0];
			int32_t b = tris[t0][(e0 + 1) % 3];
			int32_t c = tris[t0][(e0 + 2) % 3];
			int32_t d = tris[t1][(e1 + 2) % 3];
			if (d == a || d == b || d == c || pts[a].is_equal_approx(pts[b])) {
				continue;
			}
			if (tris[t1][e1] != b || tris[t1][(e1 + 1) % 3] != a) {
				continue;
			}
			if (orient2d(pts[c], pts[d], pts[b]) <= 1e-6 || orient2d(pts[d], pts[c], pts[a]) <= 1e-6) {
				continue;
			}
			if (in_circle(pts[a], pts[b], pts[c], pts[d])) {
				tris[t0] = { c, d, b };
				tris[t1] = { d, c, a };
				used[t0] = 1;
				used[t1] = 1;
				changed = true;
			}
		}
	}
}

Ring subdivide_ring(const Ring &r, double step) {
	Ring out;
	int64_t n = r.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = r[i];
		Vector2 b = r[(i + 1) % n];
		int parts = Math::max(1, (int)std::ceil(D((b - a).length()) / step));
		for (int s = 0; s < parts; s++) {
			out.push_back(a.lerp(b, (double)s / (double)parts));
		}
	}
	return out;
}

Region subdivide_region(const Region &comps, double step) {
	Region out;
	out.reserve(comps.size());
	for (const RegionComp &c : comps) {
		Rings hs;
		hs.reserve(c.holes.size());
		for (const Ring &h : c.holes) {
			hs.push_back(subdivide_ring(h, step));
		}
		out.push_back({ subdivide_ring(c.outer, step), std::move(hs) });
	}
	return out;
}

void triangulate_piece(Faces &f, const Ring &outer, double outer_y, const Rings &holes,
		const std::vector<double> &hole_ys, const Vector2 &fu) {
	if (outer.size() < 3) {
		return;
	}
	std::vector<Vector2> pts;
	std::vector<double> ys;
	pts.reserve((size_t)outer.size());
	ys.reserve((size_t)outer.size());
	for (int64_t i = 0; i < outer.size(); i++) {
		pts.push_back(outer[i]);
		ys.push_back(outer_y);
	}
	Array h_arr;
	for (size_t j = 0; j < holes.size(); j++) {
		const Ring &h = holes[j];
		h_arr.push_back(h);
		for (int64_t i = 0; i < h.size(); i++) {
			pts.push_back(h[i]);
			ys.push_back(hole_ys[j]);
		}
	}
	PackedInt32Array idx = EarcutKernels::triangulate(outer, h_arr);
	const int32_t *ip = idx.ptr();
	std::vector<std::array<int32_t, 3>> tris;
	tris.reserve((size_t)(idx.size() / 3));
	for (int64_t k = 0; k + 2 < idx.size(); k += 3) {
		int32_t a = ip[k];
		int32_t b = ip[k + 1];
		int32_t c = ip[k + 2];
		double cr = orient2d(pts[a], pts[b], pts[c]);
		if (std::abs(cr) < 1e-6) {
			continue;
		}
		if (cr < 0.0) {
			std::swap(b, c);
		}
		tris.push_back({ a, b, c });
	}
	if (!holes.empty() && tris.size() >= 2) {
		lawson_cdt(pts, tris);
	}
	for (const auto &t : tris) {
		push_tri(f, Vector2(), Vector3(pts[t[0]].x, ys[t[0]], pts[t[0]].y),
				Vector3(pts[t[1]].x, ys[t[1]], pts[t[1]].y),
				Vector3(pts[t[2]].x, ys[t[2]], pts[t[2]].y), fu, true);
	}
}

void emit_band(Faces &f, const Region &r0, double y0, const Region &r1, double y1, const Vector2 &fu) {
	Rings r1_holes;
	for (const RegionComp &c1 : r1) {
		r1_holes.insert(r1_holes.end(), c1.holes.begin(), c1.holes.end());
	}
	for (const RegionComp &c0 : r0) {
		Rings band_holes;
		std::vector<double> hole_ys;
		for (const RegionComp &c1 : r1) {
			if (point_in_ring(c1.outer[0], c0.outer) && !in_any(c1.outer[0], c0.holes)) {
				band_holes.push_back(c1.outer);
				hole_ys.push_back(y1);
			}
		}
		for (const Ring &h0 : c0.holes) {
			if (!in_any(h0[0], r1_holes)) {
				band_holes.push_back(h0);
				hole_ys.push_back(y0);
			}
		}
		triangulate_piece(f, c0.outer, y0, band_holes, hole_ys, fu);
	}
	for (const Ring &h1 : r1_holes) {
		Rings inner_holes;
		std::vector<double> inner_ys;
		for (const RegionComp &c0 : r0) {
			for (const Ring &h0 : c0.holes) {
				if (point_in_ring(h0[0], h1)) {
					inner_holes.push_back(h0);
					inner_ys.push_back(y0);
				}
			}
		}
		if (!inner_holes.empty()) {
			triangulate_piece(f, h1, y1, inner_holes, inner_ys, fu);
		}
	}
}

bool survives(const Ring &ring, const Rings &holes, double d) {
	Geometry2D *g = Geometry2D::get_singleton();
	Rings inner = solid_rings(g->offset_polygon(ring, -d, Geometry2D::JOIN_MITER), 0.001);
	for (const Ring &h : holes) {
		Rings next;
		for (const Ring &gr : solid_rings(g->offset_polygon(h, d, Geometry2D::JOIN_MITER), 0.001)) {
			for (const Ring &c : inner) {
				Rings clipped = solid_rings(g->clip_polygons(c, gr), 0.001);
				next.insert(next.end(), clipped.begin(), clipped.end());
			}
		}
		inner = std::move(next);
	}
	return !inner.empty();
}

double depth(const Ring &ring, const Rings &holes) {
	double lo = 0.0;
	Vector2 mn = ring[0];
	Vector2 mx = ring[0];
	for (int64_t i = 0; i < ring.size(); i++) {
		mn.x = Math::min(D(mn.x), D(ring[i].x));
		mn.y = Math::min(D(mn.y), D(ring[i].y));
		mx.x = Math::max(D(mx.x), D(ring[i].x));
		mx.y = Math::max(D(mx.y), D(ring[i].y));
	}
	double hi = D((mx - mn).length()) * 0.5;
	for (int i = 0; i < 10; i++) {
		double d = (lo + hi) * 0.5;
		if (survives(ring, holes, d)) {
			lo = d;
		} else {
			hi = d;
		}
	}
	return lo;
}

bool skeleton(Faces &f, const Ring &ring, const Rings &holes, double top, double rh, bool mansard,
		const Vector2 &fu) {
	double d_max = depth(ring, holes) * 0.96;
	if (d_max < 0.3) {
		return false;
	}
	std::vector<std::pair<double, double>> knots;
	if (mansard) {
		double d1 = Math::min(Math::clamp(rh * 0.36, 0.9, 2.4), d_max * 0.38);
		if (d1 < 0.25) {
			d1 = Math::min(d_max * 0.5, 0.5);
		}
		rh = Math::min(rh, d1 * 3.4);
		double d_end = Math::min(Math::max(d1 + 1.2, Math::clamp(rh * 2.2, 3.6, 8.0)), d_max);
		knots.emplace_back(d1, 0.72);
		if (d_end - d1 > 2.6) {
			knots.emplace_back((d1 + d_end) * 0.5, 0.86);
		}
		if (d_end - d1 > 0.35) {
			knots.emplace_back(d_end, 1.0);
		} else {
			knots[0].second = 1.0;
		}
	} else {
		double run = Math::min(Math::clamp(rh * 1.5, 1.4, 8.0), d_max);
		if (run < 0.3) {
			return false;
		}
		rh = Math::min(rh, run * 1.2);
		if (run >= 1.8) {
			knots.emplace_back(run * 0.5, 0.5);
		}
		knots.emplace_back(run, 1.0);
	}
	Rings clean_holes;
	for (const Ring &h : holes) {
		if (h.size() >= 3 && std::abs(signed_area(h)) >= MIN_AREA_M2) {
			clean_holes.push_back(h);
		}
	}
	std::vector<Region> tiers;
	std::vector<double> ys;
	tiers.push_back({ { ring, std::move(clean_holes) } });
	ys.push_back(top);
	double prev_d = 0.0;
	for (const auto &knot : knots) {
		double d = knot.first;
		double dd = d - prev_d;
		if (dd < 0.05) {
			continue;
		}
		Region next_comps = inset_region(tiers.back(), dd, MIN_AREA_M2);
		if (next_comps.empty()) {
			break;
		}
		tiers.push_back(std::move(next_comps));
		ys.push_back(top + rh * knot.second);
		prev_d = d;
	}
	if (tiers.size() < 2) {
		return false;
	}
	double step = Math::clamp(d_max * 0.55, 1.8, 3.2);
	for (size_t ti = 0; ti < tiers.size(); ti++) {
		tiers[ti] = subdivide_region(tiers[ti], step);
	}
	size_t before = f.verts.size();
	for (size_t k = 0; k + 1 < tiers.size(); k++) {
		emit_band(f, tiers[k], ys[k], tiers[k + 1], ys[k + 1], fu);
	}
	double top_y = ys.back();
	for (const RegionComp &c : tiers.back()) {
		std::vector<double> hys(c.holes.size(), top_y);
		triangulate_piece(f, c.outer, top_y, c.holes, hys, fu);
	}
	return f.verts.size() > before;
}

} // namespace

Array RoofKernels::form(const PackedVector2Array &ring, double top, double rh, const String &shape_s,
		const PackedByteArray &party_in, bool gable_front, const Array &holes_in) {
	Array none;
	if (rh <= 0.01 || ring.size() < 3) {
		return none;
	}
	std::string shape = shape_s.utf8().get_data();
	PackedByteArray party = party_in;
	Rings holes;
	for (int64_t i = 0; i < holes_in.size(); i++) {
		holes.push_back(holes_in[i]);
	}
	bool pitched = is_ridged(shape) || shape == "pyramidal";
	bool inset = pitched && (!holes.empty() || needs_inset(ring) || ring.size() > 8);
	Vector2 c = interior_point(ring);
	if (!inset && !point_in_ring(c, ring)) {
		return none;
	}
	Vector2 u = dominant_axis(ring);
	Faces f;
	if (inset) {
		if (!skeleton(f, ring, holes, top, rh, shape == "mansard" || shape == "gambrel", u) && holes.empty()) {
			apex_faces(f, ring, c, top, rh, false, u);
		}
		shape = "";
	} else if (!boxy(ring)) {
		party = PackedByteArray();
	}
	if (is_ridged(shape)) {
		if (!ridged(f, ring, c, top, rh, shape, party, gable_front)) {
			apex_faces(f, ring, c, top, rh, false, u);
		}
		shape = "";
	}
	if (shape == "pyramidal") {
		apex_faces(f, ring, c, top, rh, false, u);
	} else if (shape == "dome" || shape == "onion" || shape == "cone") {
		if (!domes(f, ring, c, top, rh, shape)) {
			apex_faces(f, ring, c, top, rh, shape != "cone", u);
		}
	} else if (shape == "skillion") {
		skillion(f, ring, c, top, rh, party);
	} else if (shape == "round") {
		if (!barrel(f, ring, c, top, rh) && !ridged(f, ring, c, top, rh, "gabled", party, gable_front)) {
			apex_faces(f, ring, c, top, rh, false, u);
		}
	} else if (shape != "") {
		return none;
	}
	if (f.verts.empty()) {
		return none;
	}
	Array out;
	out.push_back(packed<PackedVector3Array>(f.verts));
	out.push_back(packed<PackedVector3Array>(f.normals));
	out.push_back(packed<PackedVector2Array>(f.uvs));
	out.push_back(tangents_for(f.normals, u));
	return out;
}

Array RoofKernels::form_many(const Array &jobs) {
	const int n = (int)jobs.size();
	std::vector<Array> in((size_t)n);
	for (int i = 0; i < n; i++) {
		in[i] = jobs[i];
	}
	std::vector<Array> res((size_t)n);
	Geometry2D::get_singleton();
	parallel_for(n, [&](int i) {
		const Array &j = in[i];
		res[i] = form(j[0], j[1], j[2], j[3], j[4], j[5], j[6]);
	});
	Array out;
	out.resize(n);
	for (int i = 0; i < n; i++) {
		out[i] = res[i];
	}
	return out;
}

Array RoofKernels::split_gables(const PackedVector3Array &sv, const PackedVector3Array &sn,
		const PackedVector2Array &su, const PackedFloat32Array &st,
		const PackedVector2Array &ring, const PackedByteArray &party,
		double gable_max_y, double gable_uv_scale) {
	const int64_t n_tris = sn.size() / 3;
	if (n_tris <= 0) {
		return Array();
	}
	// Precompute outward normals of party edges once.
	std::vector<Vector2> party_norms;
	const int64_t rn = ring.size();
	if (rn >= 3 && party.size() == rn) {
		const Vector2 *rvec = ring.ptr();
		const bool ccw = signed_area(ring) > 0.0;
		const uint8_t *pp = party.ptr();
		for (int64_t i = 0; i < rn; ++i) {
			if (pp[i] != 1) continue;
			const Vector2 e = rvec[(i + 1) % rn] - rvec[i];
			party_norms.push_back(ccw ? Vector2(e.y, -e.x).normalized() : Vector2(-e.y, e.x).normalized());
		}
	}
	const Vector3 *np = sn.ptr();
	std::vector<int64_t> roof_tris, open_tris, party_tris;
	roof_tris.reserve(n_tris);
	for (int64_t t = 0; t < n_tris; ++t) {
		const Vector3 &n = np[t * 3];
		if (std::abs((double)n.y) >= gable_max_y) {
			roof_tris.push_back(t);
		} else {
			bool on_p = false;
			if (!party_norms.empty()) {
				const Vector2 n2 = Vector2(n.x, n.z).normalized();
				for (const Vector2 &pn : party_norms) {
					if ((double)pn.dot(n2) > 0.7) {
						on_p = true;
						break;
					}
				}
			}
			if (on_p) party_tris.push_back(t);
			else open_tris.push_back(t);
		}
	}
	if (open_tris.empty() && party_tris.empty()) {
		return Array();
	}
	const Vector3 *vp = sv.ptr();
	const Vector2 *up = su.ptr();
	const float *tp = st.ptr();
	const bool has_t = (st.size() == sv.size() * 4);
	auto pack_tris = [&](const std::vector<int64_t> &tris, float uv_s) -> Array {
		if (tris.empty()) return Array();
		const int64_t vc = (int64_t)tris.size() * 3;
		PackedVector3Array ov, on;
		PackedVector2Array ou;
		PackedFloat32Array ot;
		ov.resize(vc); on.resize(vc); ou.resize(vc);
		if (has_t) ot.resize(vc * 4);
		Vector3 *ovw = ov.ptrw(), *onw = on.ptrw();
		Vector2 *ouw = ou.ptrw();
		float *otw = has_t ? ot.ptrw() : nullptr;
		int64_t dst = 0;
		for (int64_t tri : tris) {
			const int64_t base = tri * 3;
			for (int k = 0; k < 3; ++k, ++dst) {
				const int64_t si = base + k;
				ovw[dst] = vp[si];
				onw[dst] = np[si];
				ouw[dst] = up[si] * uv_s;
				if (has_t) {
					otw[dst * 4 + 0] = tp[si * 4 + 0];
					otw[dst * 4 + 1] = tp[si * 4 + 1];
					otw[dst * 4 + 2] = tp[si * 4 + 2];
					otw[dst * 4 + 3] = tp[si * 4 + 3];
				}
			}
		}
		Array a;
		a.resize(4);
		a[0] = ov; a[1] = on; a[2] = ou; a[3] = ot;
		return a;
	};
	Array out;
	out.resize(3);
	out[0] = pack_tris(roof_tris, 1.0f);
	out[1] = pack_tris(open_tris, (float)gable_uv_scale);
	out[2] = pack_tris(party_tris, (float)gable_uv_scale);
	return out;
}

Array RoofKernels::trim_arrays(const PackedVector2Array &ring, double top, int trim,
		const PackedByteArray &party, double m2u) {
	const int64_t n = ring.size();
	if (trim == 0 || n < 3) {
		return Array();
	}
	const Vector2 *rvec = ring.ptr();
	const bool ccw = signed_area(ring) > 0.0;
	const bool has_p = (party.size() == n);
	const uint8_t *pp = has_p ? party.ptr() : nullptr;
	std::vector<Vector2> onorms(n);
	for (int64_t i = 0; i < n; ++i) {
		const Vector2 e = rvec[(i + 1) % n] - rvec[i];
		onorms[i] = ccw ? Vector2(e.y, -e.x).normalized() : Vector2(-e.y, e.x).normalized();
	}
	auto offset_ring = [&](double d, bool use_party) -> std::vector<Vector2> {
		std::vector<Vector2> out(n);
		for (int64_t i = 0; i < n; ++i) {
			const int64_t prev = (i - 1 + n) % n;
			const Vector2 &n0 = onorms[prev];
			const Vector2 &n1 = onorms[i];
			if (use_party && has_p && (pp[prev] == 1 || pp[i] == 1)) {
				Vector2 keep(0.0f, 0.0f);
				if (pp[prev] == 0) keep = n0;
				else if (pp[i] == 0) keep = n1;
				out[i] = rvec[i] + keep * (float)d;
				continue;
			}
			const double denom = std::max(1.0 + (double)n0.dot(n1), 0.0001);
			Vector2 off = (n0 + n1) * (float)(d / denom);
			const double max_off = std::abs(d) * 3.0;
			if ((double)off.length() > max_off) {
				off = off.normalized() * (float)max_off;
			}
			out[i] = rvec[i] + off;
		}
		return out;
	};

	std::vector<Vector3> verts, normals;
	std::vector<Vector2> uvs;
	std::vector<int32_t> idx;
	verts.reserve(n * 16);
	normals.reserve(n * 16);
	uvs.reserve(n * 16);
	idx.reserve(n * 24);
	auto push_quad = [&](const Vector3 &a, const Vector3 &b, const Vector3 &c, const Vector3 &d, const Vector3 &nrm) {
		const int32_t k = (int32_t)verts.size();
		verts.push_back(a); verts.push_back(b); verts.push_back(c); verts.push_back(d);
		for (int q = 0; q < 4; ++q) normals.push_back(nrm);
		const float e = (b - a).length();
		const float h = (d - a).length();
		const float u0 = (a.x + a.z) * 0.5f;
		uvs.emplace_back(u0, 0.0f);
		uvs.emplace_back((a.x + a.z + e) * 0.5f, 0.0f);
		uvs.emplace_back((a.x + a.z + e) * 0.5f, h * 0.5f);
		uvs.emplace_back(u0, h * 0.5f);
		if ((c - a).cross(b - a).dot(nrm) >= 0.0f) {
			idx.push_back(k); idx.push_back(k + 1); idx.push_back(k + 2);
			idx.push_back(k); idx.push_back(k + 2); idx.push_back(k + 3);
		} else {
			idx.push_back(k); idx.push_back(k + 2); idx.push_back(k + 1);
			idx.push_back(k); idx.push_back(k + 3); idx.push_back(k + 2);
		}
	};

	const float topf = (float)top;
	if (trim == 1) { // CORNICE
		const auto outer = offset_ring(0.28 * m2u, false);
		const float y0 = (float)(top - 0.34 * m2u);
		const float y1 = (float)(y0 + 0.22 * m2u);
		for (int64_t i = 0; i < n; ++i) {
			if (has_p && pp[i] == 1) continue;
			const int64_t j = (i + 1) % n;
			const Vector2 &a = rvec[i], &b = rvec[j], &oa = outer[i], &ob = outer[j];
			const Vector2 &out = onorms[i];
			push_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y),
					Vector3(ob.x, y0, ob.y), Vector3(oa.x, y0, oa.y), Vector3(0.0f, -1.0f, 0.0f));
			push_quad(Vector3(oa.x, y0, oa.y), Vector3(ob.x, y0, ob.y),
					Vector3(ob.x, y1, ob.y), Vector3(oa.x, y1, oa.y), Vector3(out.x, 0.0f, out.y));
			push_quad(Vector3(oa.x, y1, oa.y), Vector3(ob.x, y1, ob.y),
					Vector3(b.x, topf, b.y), Vector3(a.x, topf, a.y),
					Vector3(out.x * 0.6f, 0.8f, out.y * 0.6f).normalized());
		}
	} else { // PARAPET
		const auto inner = offset_ring(-0.28 * m2u, false);
		const auto cin = offset_ring(-(0.28 + 0.06) * m2u, false);
		const auto cout = offset_ring(0.06 * m2u, true);
		const float y0 = (float)(top - 0.65 * m2u);
		const float y1 = (float)(top - 0.1 * m2u);
		for (int64_t i = 0; i < n; ++i) {
			const int64_t j = (i + 1) % n;
			const Vector3 o3(onorms[i].x, 0.0f, onorms[i].y);
			push_quad(Vector3(inner[i].x, y0, inner[i].y), Vector3(inner[j].x, y0, inner[j].y),
					Vector3(inner[j].x, y1, inner[j].y), Vector3(inner[i].x, y1, inner[i].y), -o3);
			if (has_p && pp[i] == 1) {
				push_quad(Vector3(cin[i].x, topf, cin[i].y), Vector3(cin[j].x, topf, cin[j].y),
						Vector3(rvec[j].x, topf, rvec[j].y), Vector3(rvec[i].x, topf, rvec[i].y),
						Vector3(0.0f, 1.0f, 0.0f));
				continue;
			}
			const Vector3 e3 = Vector3(rvec[j].x - rvec[i].x, 0.0f, rvec[j].y - rvec[i].y).normalized();
			if (has_p && pp[(i - 1 + n) % n] == 1) {
				push_quad(Vector3(rvec[i].x, y1, rvec[i].y), Vector3(cout[i].x, y1, cout[i].y),
						Vector3(cout[i].x, topf, cout[i].y), Vector3(rvec[i].x, topf, rvec[i].y), -e3);
			}
			if (has_p && pp[j] == 1) {
				push_quad(Vector3(rvec[j].x, y1, rvec[j].y), Vector3(cout[j].x, y1, cout[j].y),
						Vector3(cout[j].x, topf, cout[j].y), Vector3(rvec[j].x, topf, rvec[j].y), e3);
			}
			push_quad(Vector3(rvec[i].x, y1, rvec[i].y), Vector3(rvec[j].x, y1, rvec[j].y),
					Vector3(cout[j].x, y1, cout[j].y), Vector3(cout[i].x, y1, cout[i].y),
					Vector3(0.0f, -1.0f, 0.0f));
			push_quad(Vector3(cout[i].x, y1, cout[i].y), Vector3(cout[j].x, y1, cout[j].y),
					Vector3(cout[j].x, topf, cout[j].y), Vector3(cout[i].x, topf, cout[i].y), o3);
			push_quad(Vector3(cin[i].x, topf, cin[i].y), Vector3(cin[j].x, topf, cin[j].y),
					Vector3(cout[j].x, topf, cout[j].y), Vector3(cout[i].x, topf, cout[i].y),
					Vector3(0.0f, 1.0f, 0.0f));
		}
	}
	if (idx.empty()) {
		return Array();
	}
	// Compute per-vertex tangents matching MassBatch.tangents(verts, normals, uvs, idx).
	const size_t vn = verts.size();
	std::vector<Vector3> tan_acc(vn, Vector3(0.0f, 0.0f, 0.0f));
	std::vector<Vector3> bitan_acc(vn, Vector3(0.0f, 0.0f, 0.0f));
	for (size_t t = 0; t + 2 < idx.size(); t += 3) {
		const int32_t i0 = idx[t], i1 = idx[t + 1], i2 = idx[t + 2];
		const Vector3 e1 = verts[i1] - verts[i0];
		const Vector3 e2 = verts[i2] - verts[i0];
		const Vector2 d1 = uvs[i1] - uvs[i0];
		const Vector2 d2 = uvs[i2] - uvs[i0];
		const float det = d1.x * d2.y - d2.x * d1.y;
		if (std::abs(det) < 1e-8f) continue;
		const float inv = 1.0f / det;
		const Vector3 tx = (e1 * d2.y - e2 * d1.y) * inv;
		const Vector3 bx = (e2 * d1.x - e1 * d2.x) * inv;
		tan_acc[i0] += tx; tan_acc[i1] += tx; tan_acc[i2] += tx;
		bitan_acc[i0] += bx; bitan_acc[i1] += bx; bitan_acc[i2] += bx;
	}
	PackedFloat32Array tans;
	tans.resize((int64_t)vn * 4);
	float *tw = tans.ptrw();
	for (size_t i = 0; i < vn; ++i) {
		const Vector3 &nrm = normals[i];
		Vector3 t = tan_acc[i] - nrm * nrm.dot(tan_acc[i]);
		if (t.length_squared() < 1e-10f) {
			t = nrm.cross(std::abs(nrm.y) < 0.9f ? Vector3(0.0f, 1.0f, 0.0f) : Vector3(1.0f, 0.0f, 0.0f));
		}
		t.normalize();
		const float w = (nrm.cross(t).dot(bitan_acc[i]) < 0.0f) ? -1.0f : 1.0f;
		tw[i * 4 + 0] = t.x; tw[i * 4 + 1] = t.y; tw[i * 4 + 2] = t.z; tw[i * 4 + 3] = w;
	}
	Array out;
	out.resize(5);
	out[0] = packed<PackedVector3Array>(verts);
	out[1] = packed<PackedVector3Array>(normals);
	out[2] = packed<PackedVector2Array>(uvs);
	out[3] = tans;
	out[4] = packed<PackedInt32Array>(idx);
	return out;
}

namespace {

struct WallBuf {
	std::vector<Vector3> verts, normals;
	std::vector<Vector2> uvs;
	std::vector<float> tangents;
	std::vector<int32_t> indices;

	void quad(const Vector2 &a, const Vector2 &b, real_t y0, real_t y1,
			const Vector2 &n, const Vector2 &uv, real_t u0, bool use_tangents) {
		const Vector2 e = b - a;
		const Vector3 n3(n.x, 0.0f, n.y);
		const int32_t k = (int32_t)verts.size();
		verts.push_back(Vector3(a.x, y0, a.y));
		verts.push_back(Vector3(b.x, y0, b.y));
		verts.push_back(Vector3(b.x, y1, b.y));
		verts.push_back(Vector3(a.x, y1, a.y));
		Vector3 t3(0, 0, 0);
		float w = 1.0f;
		if (use_tangents) {
			t3 = Vector3(e.x, 0.0f, e.y).normalized();
			w = n3.cross(t3).y > 0.0f ? 1.0f : -1.0f;
		}
		for (int j = 0; j < 4; ++j) {
			normals.push_back(n3);
			if (use_tangents) {
				tangents.push_back(t3.x);
				tangents.push_back(t3.y);
				tangents.push_back(t3.z);
				tangents.push_back(w);
			}
		}
		uvs.push_back(Vector2(u0, uv.y));
		uvs.push_back(Vector2(uv.x, uv.y));
		uvs.push_back(Vector2(uv.x, 0.0f));
		uvs.push_back(Vector2(u0, 0.0f));
		const real_t s = e.x * n.y - e.y * n.x;
		if (s > 0.0f) {
			indices.push_back(k); indices.push_back(k + 2); indices.push_back(k + 1);
			indices.push_back(k); indices.push_back(k + 3); indices.push_back(k + 2);
		} else {
			indices.push_back(k); indices.push_back(k + 1); indices.push_back(k + 2);
			indices.push_back(k); indices.push_back(k + 2); indices.push_back(k + 3);
		}
	}

	Array to_array() const {
		Array a;
		if (indices.empty()) {
			return a;
		}
		a.resize(5);
		a[0] = packed<PackedVector3Array>(verts);
		a[1] = packed<PackedVector3Array>(normals);
		a[2] = packed<PackedVector2Array>(uvs);
		a[3] = packed<PackedFloat32Array>(tangents);
		a[4] = packed<PackedInt32Array>(indices);
		return a;
	}
};

} // namespace

Array RoofKernels::walls_arrays(const PackedVector2Array &ring, double base, double top,
		const Vector3 &uvp, double bay_scale, double v_repeat, const Array &cover,
		bool has_fire, bool is_glass, bool invert, bool use_tangents, double m2u) {
	const int64_t n = ring.size();
	Array res;
	res.resize(2);
	if (n < 3) {
		res[0] = Array();
		res[1] = Array();
		return res;
	}
	const Vector2 *rp = ring.ptr();
	const bool ccw = signed_area(ring) > 0.0;
	const double bay = (double)uvp.x * bay_scale;
	const int64_t cov_n = cover.size();

	// Inline BuildingWalls.curve_bays
	std::vector<uint8_t> has_curve((size_t)n, 0);
	std::vector<Vector2> curve_uv((size_t)n);
	if (bay > 0.0 && n >= 3) {
		std::vector<uint8_t> ok((size_t)n, 0);
		for (int64_t i = 0; i < n; ++i) {
			const double len_m = (double)rp[i].distance_to(rp[(i + 1) % n]) / m2u;
			bool open_one = true;
			if (i < cov_n) {
				const Array pieces = cover[i];
				if (pieces.size() != 1) {
					open_one = false;
				} else {
					const Array pc0 = pieces[0];
					if (!std::isinf((double)pc0[2])) {
						open_one = false;
					}
				}
			}
			ok[i] = (len_m > 0.001 && len_m < bay * 1.5 && open_one) ? 1 : 0;
		}
		std::vector<uint8_t> link((size_t)n, 0);
		const double cos_max = std::cos(25.0 * Math::PI / 180.0);
		for (int64_t i = 0; i < n; ++i) {
			const int64_t j = (i + 1) % n;
			if (ok[i] && ok[j]) {
				const Vector2 d0 = (rp[j] - rp[i]).normalized();
				const Vector2 d1 = (rp[(j + 1) % n] - rp[j]).normalized();
				link[i] = (double)d0.dot(d1) > cos_max ? 1 : 0;
			}
		}
		int64_t start = 0;
		for (int64_t i = 0; i < n; ++i) {
			if (!link[(i - 1 + n) % n]) {
				start = i;
				break;
			}
		}
		std::vector<int64_t> run;
		auto spread = [&]() {
			if (run.size() < 3) {
				return;
			}
			double total = 0.0;
			for (int64_t idx : run) {
				total += (double)rp[idx].distance_to(rp[(idx + 1) % n]) / m2u;
			}
			const int bays_c = total < bay * 0.5 ? 0 : std::max(1, (int)std::llround(total / bay));
			if (bays_c == 0) {
				return;
			}
			double s = 0.0;
			for (int64_t idx : run) {
				const double lm = (double)rp[idx].distance_to(rp[(idx + 1) % n]) / m2u;
				has_curve[idx] = 1;
				curve_uv[idx] = Vector2((real_t)((double)bays_c * s / total), (real_t)((double)bays_c * (s + lm) / total));
				s += lm;
			}
		};
		for (int64_t k = 0; k <= n; ++k) {
			const int64_t i = (start + k) % n;
			if (k < n && ok[i] && (run.empty() || link[run.back()])) {
				run.push_back(i);
				continue;
			}
			spread();
			run.clear();
			if (k < n && ok[i]) {
				run.push_back(i);
			}
		}
	}

	WallBuf face, blank;
	face.verts.reserve((size_t)n * 4);
	face.normals.reserve((size_t)n * 4);
	face.uvs.reserve((size_t)n * 4);
	face.indices.reserve((size_t)n * 6);
	if (use_tangents) {
		face.tangents.reserve((size_t)n * 16);
	}
	const bool no_band = !has_fire || is_glass;
	const double fire_band = 9.0 * m2u;

	for (int64_t i = 0; i < n; ++i) {
		const Vector2 ea = rp[i];
		const Vector2 eb = rp[(i + 1) % n];
		const Vector2 ed = eb - ea;
		if ((double)ed.length() < 0.001) {
			continue;
		}
		Vector2 nrm = ccw ? Vector2(ed.y, -ed.x).normalized() : Vector2(-ed.y, ed.x).normalized();
		if (invert) {
			nrm = -nrm;
		}
		auto emit_piece = [&](double t0, double t1, double nb_top) {
			const Vector2 a = ea.lerp(eb, (real_t)t0);
			const Vector2 b = ea.lerp(eb, (real_t)t1);
			if (std::isinf(nb_top) || nb_top <= base) {
				double u0 = 0.0;
				double u1 = 1.0;
				double v0 = 1.0;
				if ((double)uvp.x > 0.0) {
					const double len_m = (double)(b - a).length() / m2u;
					u1 = len_m < bay * 0.5 ? 0.03 : std::max(1.0, std::round(len_m / bay)) / (double)uvp.y;
					if (has_curve[i]) {
						u0 = (double)curve_uv[i].x / (double)uvp.y;
						u1 = (double)curve_uv[i].y / (double)uvp.y;
					}
					if ((double)uvp.z > 0.0) {
						v0 = v_repeat;
					}
				}
				face.quad(a, b, (real_t)base, (real_t)top, nrm, Vector2((real_t)u1, (real_t)v0), (real_t)u0, use_tangents);
			} else if (nb_top < top - 0.3 * m2u) {
				const double y0 = std::max(base, nb_top);
				WallBuf &arr = has_fire ? blank : face;
				double y1 = top;
				if (no_band || top - y0 > fire_band * 1.5) {
					y1 = no_band ? y0 : y0 + fire_band;
					const double len_m = (double)(b - a).length() / m2u;
					double u1 = 1.0;
					if ((double)uvp.x > 0.0) {
						u1 = len_m < bay * 0.5 ? 0.03 : std::max(1.0, std::round(len_m / bay)) / (double)uvp.y;
					}
					const double v_up = ((double)uvp.z > 0.0 ? v_repeat : 1.0) * (top - y1) / std::max(top - base, 1e-4);
					face.quad(a, b, (real_t)y1, (real_t)top, nrm, Vector2((real_t)u1, (real_t)v_up), 0.0f, use_tangents);
				}
				if (y1 > y0) {
					arr.quad(a, b, (real_t)y0, (real_t)y1, nrm,
							Vector2((real_t)((double)(b - a).length() / m2u / 4.0), (real_t)((y1 - y0) / m2u / 4.0)),
							0.0f, use_tangents);
				}
			}
		};
		if (i < cov_n) {
			const Array pieces = cover[i];
			const int64_t pn = pieces.size();
			for (int64_t p = 0; p < pn; ++p) {
				const Array pc = pieces[p];
				emit_piece((double)pc[0], (double)pc[1], (double)pc[2]);
			}
		} else {
			emit_piece(0.0, 1.0, -INFINITY);
		}
	}
	res[0] = face.to_array();
	res[1] = has_fire ? blank.to_array() : Array();
	return res;
}

Array RoofKernels::roof_cap_arrays(const PackedVector2Array &ring, const PackedInt32Array &idx,
		double top, bool use_tangents) {
	const int64_t rn = ring.size();
	const int64_t in = idx.size();
	const Vector2 *rp = ring.ptr();
	const int32_t *ip = idx.ptr();
	bool flip = false;
	if (in >= 3) {
		const Vector2 p0 = rp[ip[0]];
		const Vector2 p1 = rp[ip[1]];
		const Vector2 p2 = rp[ip[2]];
		flip = ((double)(p1.x - p0.x) * (double)(p2.y - p0.y) - (double)(p1.y - p0.y) * (double)(p2.x - p0.x)) < 0.0;
	}
	PackedVector3Array verts, normals;
	PackedVector2Array uvs;
	verts.resize(rn);
	normals.resize(rn);
	uvs.resize(rn);
	Vector3 *vw = verts.ptrw();
	Vector3 *nw = normals.ptrw();
	Vector2 *uw = uvs.ptrw();
	const real_t topf = (real_t)top;
	for (int64_t i = 0; i < rn; ++i) {
		vw[i] = Vector3(rp[i].x, topf, rp[i].y);
		nw[i] = Vector3(0.0f, 1.0f, 0.0f);
		uw[i] = rp[i] * 0.05f;
	}
	PackedInt32Array indices;
	indices.resize((in / 3) * 3);
	int32_t *iw = indices.ptrw();
	for (int64_t t = 0; t + 2 < in; t += 3) {
		iw[t] = ip[t];
		if (flip) {
			iw[t + 1] = ip[t + 2];
			iw[t + 2] = ip[t + 1];
		} else {
			iw[t + 1] = ip[t + 1];
			iw[t + 2] = ip[t + 2];
		}
	}
	PackedFloat32Array tangents;
	if (use_tangents) {
		tangents.resize(rn * 4);
		float *tw = tangents.ptrw();
		for (int64_t i = 0; i < rn; ++i) {
			tw[i * 4 + 0] = 1.0f;
			tw[i * 4 + 1] = 0.0f;
			tw[i * 4 + 2] = 0.0f;
			tw[i * 4 + 3] = 1.0f;
		}
	}
	Array out;
	out.resize(5);
	out[0] = verts;
	out[1] = normals;
	out[2] = uvs;
	out[3] = tangents;
	out[4] = indices;
	return out;
}

void RoofKernels::_bind_methods() {
	ClassDB::bind_static_method("RoofKernels",
			D_METHOD("form", "ring", "top", "rh", "shape", "party", "gable_front", "holes"),
			&RoofKernels::form);
	ClassDB::bind_static_method("RoofKernels", D_METHOD("form_many", "jobs"), &RoofKernels::form_many);
	ClassDB::bind_static_method("RoofKernels",
			D_METHOD("split_gables", "sv", "sn", "su", "st", "ring", "party", "gable_max_y", "gable_uv_scale"),
			&RoofKernels::split_gables);
	ClassDB::bind_static_method("RoofKernels",
			D_METHOD("trim_arrays", "ring", "top", "trim", "party", "m2u"),
			&RoofKernels::trim_arrays);
	ClassDB::bind_static_method("RoofKernels",
			D_METHOD("walls_arrays", "ring", "base", "top", "uvp", "bay_scale", "v_repeat", "cover", "has_fire", "is_glass", "invert", "use_tangents", "m2u"),
			&RoofKernels::walls_arrays);
	ClassDB::bind_static_method("RoofKernels",
			D_METHOD("roof_cap_arrays", "ring", "idx", "top", "use_tangents"),
			&RoofKernels::roof_cap_arrays);
}

} // namespace godot
