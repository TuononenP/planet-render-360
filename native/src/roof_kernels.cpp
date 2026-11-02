#include "roof_kernels.h"

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

#include <cmath>
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
// RoofSkeleton
constexpr double MERGE_M = 0.08;

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

struct Faces {
	PackedVector3Array verts, normals;
	PackedVector2Array uvs;
};

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

PackedFloat32Array tangents_for(const PackedVector3Array &normals, const Vector2 &fu) {
	PackedFloat32Array out;
	out.resize(normals.size() * 4);
	float *o = out.ptrw();
	bool have = false;
	Vector3 last_n(INFINITY, INFINITY, INFINITY);
	Vector3 last_t, last_d;
	float last_w = 0.0f;
	for (int64_t k = 0; k < normals.size(); k++) {
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
	int64_t before = f.verts.size();
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

Rings to_rings(const TypedArray<PackedVector2Array> &a) {
	Rings out;
	for (int64_t i = 0; i < a.size(); i++) {
		out.push_back(a[i]);
	}
	return out;
}

bool in_any(const Vector2 &p, const Rings &rings) {
	Geometry2D *g = Geometry2D::get_singleton();
	for (const Ring &r : rings) {
		if (g->is_point_in_polygon(p, r)) {
			return true;
		}
	}
	return false;
}

struct VecKeyLess {
	bool operator()(const Vector2i &a, const Vector2i &b) const {
		return a.x != b.x ? a.x < b.x : a.y < b.y;
	}
};

void sk_add_ring(const Ring &r, double step, double f, Ring &pts, std::vector<float> &lift,
		std::set<Vector2i, VecKeyLess> &seen, const Rings &within, const Rings &outside) {
	int64_t n = r.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = r[i];
		Vector2 b = r[(i + 1) % n];
		int parts = Math::max(1, (int)std::ceil(D((b - a).length()) / step));
		for (int s = 0; s < parts; s++) {
			Vector2 p = a.lerp(b, (double)s / (double)parts);
			if (!within.empty() && !in_any(p, within)) {
				continue;
			}
			if (in_any(p, outside)) {
				continue;
			}
			Vector2i key((int)std::round(D(p.x) / MERGE_M), (int)std::round(D(p.y) / MERGE_M));
			if (!seen.insert(key).second) {
				continue;
			}
			pts.push_back(p);
			lift.push_back((float)f);
		}
	}
}

bool survives(const Ring &ring, const Rings &holes, double d) {
	Geometry2D *g = Geometry2D::get_singleton();
	Rings inner = to_rings(g->offset_polygon(ring, -d, Geometry2D::JOIN_MITER));
	for (const Ring &h : holes) {
		Rings next;
		for (const Ring &gr : to_rings(g->offset_polygon(h, d, Geometry2D::JOIN_MITER))) {
			for (const Ring &c : inner) {
				for (const Ring &x : to_rings(g->clip_polygons(c, gr))) {
					next.push_back(x);
				}
			}
		}
		inner = next;
	}
	return !inner.empty();
}

double depth(const Ring &ring, const Rings &holes) {
	double lo = 0.0;
	// RingGeometry.aabb(ring).size.length() * 0.5
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
	Geometry2D *g = Geometry2D::get_singleton();
	double run = Math::min(Math::clamp(rh * 1.1, 1.2 * 1.0, 3.6 * 1.0), depth(ring, holes) * 0.96);
	if (run < 0.3) {
		return false;
	}
	rh = Math::min(rh, run * 1.2);
	double step = Math::clamp(run * 1.2, 2.0, 4.5);
	Ring pts;
	std::vector<float> lift;
	std::set<Vector2i, VecKeyLess> seen;
	const Rings none;
	sk_add_ring(ring, step, 0.0, pts, lift, seen, none, none);
	for (const Ring &h : holes) {
		sk_add_ring(h, step, 0.0, pts, lift, seen, none, none);
	}
	const std::pair<double, double> mans[2] = { { 0.38, 0.75 }, { 1.0, 1.0 } };
	const std::pair<double, double> str[2] = { { 0.5, 0.5 }, { 1.0, 1.0 } };
	for (const auto &knot : mansard ? mans : str) {
		double d = knot.first * run;
		double fk = knot.second;
		Rings grown;
		for (const Ring &h : holes) {
			for (const Ring &gr : to_rings(g->offset_polygon(h, d, Geometry2D::JOIN_MITER))) {
				grown.push_back(gr);
			}
		}
		Rings inner = to_rings(g->offset_polygon(ring, -d, Geometry2D::JOIN_MITER));
		for (const Ring &c : inner) {
			sk_add_ring(c, step, fk, pts, lift, seen, none, grown);
		}
		for (const Ring &gr : grown) {
			sk_add_ring(gr, step, fk, pts, lift, seen, inner, none);
		}
	}
	if (pts.size() < 3) {
		return false;
	}
	PackedInt32Array tri = g->triangulate_delaunay(pts);
	int64_t before = f.verts.size();
	Rings cores;
	for (const Ring &h : holes) {
		for (const Ring &cr : to_rings(g->offset_polygon(h, -0.05, Geometry2D::JOIN_SQUARE))) {
			cores.push_back(cr);
		}
	}
	for (int64_t k = 0; k + 2 < tri.size(); k += 3) {
		int32_t a = tri[k];
		int32_t b = tri[k + 1];
		int32_t c = tri[k + 2];
		if ((double)lift[a] + (double)lift[b] + (double)lift[c] <= 0.0) {
			continue;
		}
		const Vector2 probes[4] = { (pts[a] + pts[b] + pts[c]) / 3.0, (pts[a] + pts[b]) * 0.5,
			(pts[b] + pts[c]) * 0.5, (pts[c] + pts[a]) * 0.5 };
		bool ok = true;
		for (const Vector2 &p : probes) {
			if (!g->is_point_in_polygon(p, ring) || in_any(p, cores)) {
				ok = false;
				break;
			}
		}
		if (!ok) {
			continue;
		}
		push_tri(f, Vector2(), Vector3(pts[a].x, top + rh * (double)lift[a], pts[a].y),
				Vector3(pts[b].x, top + rh * (double)lift[b], pts[b].y),
				Vector3(pts[c].x, top + rh * (double)lift[c], pts[c].y), fu, true);
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
	if (f.verts.is_empty()) {
		return none;
	}
	Array out;
	out.push_back(f.verts);
	out.push_back(f.normals);
	out.push_back(f.uvs);
	out.push_back(tangents_for(f.normals, u));
	return out;
}

void RoofKernels::_bind_methods() {
	ClassDB::bind_static_method("RoofKernels",
			D_METHOD("form", "ring", "top", "rh", "shape", "party", "gable_front", "holes"),
			&RoofKernels::form);
}

} // namespace godot
