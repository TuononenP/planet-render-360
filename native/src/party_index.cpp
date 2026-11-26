#include "party_index.h"

#include <godot_cpp/classes/geometry2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {

// PartyWalls constants (metres = units).
constexpr double TOL_M = 0.8;
constexpr double PARALLEL = 0.96;
constexpr double MIN_COVER_M = 0.6;
constexpr double GAP_M = 0.9;
constexpr double STREET_M = 9.0;
constexpr double CELL_M = 32.0;
constexpr double OPEN = -INFINITY;
constexpr double SAME_TOL_M = 0.05;

inline double D(real_t v) {
	return (double)v;
}

inline int64_t cell_key(int64_t ix, int64_t iz) {
	return (ix << 32) ^ (iz & 0xFFFFFFFF);
}

inline int64_t floori(double v) {
	return (int64_t)std::floor(v);
}

double signed_area(const PackedVector2Array &ring) {
	double a = 0.0;
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 p = ring[i];
		Vector2 q = ring[(i + 1) % n];
		a += D(p.x) * D(q.y) - D(q.x) * D(p.y);
	}
	return a * 0.5;
}

// PartyWalls._outward_ccw
Vector2 outward_ccw(const PackedVector2Array &ring, int64_t i, bool hole, bool ccw) {
	Vector2 e = ring[(i + 1) % ring.size()] - ring[i];
	Vector2 n = ccw ? Vector2(e.y, -e.x).normalized() : Vector2(-e.y, e.x).normalized();
	return hole ? -n : n;
}

struct Cover {
	double t0, t1, top;
};

Array piece(double t0, double t1, double top) {
	Array p;
	p.push_back(t0);
	p.push_back(t1);
	p.push_back(top);
	return p;
}

// PartyWalls._pieces
Array pieces(const std::vector<Cover> &spans, double len_m) {
	std::vector<double> cuts = { 0.0, 1.0 };
	for (const Cover &s : spans) {
		cuts.push_back(s.t0);
		cuts.push_back(s.t1);
	}
	std::sort(cuts.begin(), cuts.end());
	std::vector<Cover> out;
	for (size_t i = 0; i + 1 < cuts.size(); i++) {
		double t0 = cuts[i];
		double t1 = cuts[i + 1];
		if (t1 - t0 < 0.000001) {
			continue;
		}
		double mid = (t0 + t1) * 0.5;
		double top = OPEN;
		for (const Cover &s : spans) {
			if (mid >= s.t0 && mid <= s.t1) {
				top = Math::max(top, s.top);
			}
		}
		if ((!out.empty() && std::abs(out.back().top - top) < 0.05) ||
				(!out.empty() && std::isinf(top) && std::isinf(out.back().top))) {
			out.back().t1 = t1;
		} else {
			out.push_back({ t0, t1, top });
		}
	}
	for (size_t i = 1; i + 1 < out.size(); i++) {
		if (std::isinf(out[i].top) && !std::isinf(out[i - 1].top) && !std::isinf(out[i + 1].top) &&
				(out[i].t1 - out[i].t0) * len_m < GAP_M) {
			out[i].top = Math::min(out[i - 1].top, out[i + 1].top);
		}
	}
	Array res;
	for (const Cover &s : out) {
		res.push_back(piece(s.t0, s.t1, s.top));
	}
	return res;
}

Rect2 ring_aabb(const PackedVector2Array &ring) {
	if (ring.is_empty()) {
		return Rect2();
	}
	const Vector2 *p = ring.ptr();
	real_t min_x = p[0].x, max_x = p[0].x;
	real_t min_y = p[0].y, max_y = p[0].y;
	const int64_t n = ring.size();
	for (int64_t i = 1; i < n; ++i) {
		if (p[i].x < min_x) min_x = p[i].x;
		else if (p[i].x > max_x) max_x = p[i].x;
		if (p[i].y < min_y) min_y = p[i].y;
		else if (p[i].y > max_y) max_y = p[i].y;
	}
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y));
}

bool point_in_poly(const Vector2 &p, const PackedVector2Array &poly) {
	const int64_t n = poly.size();
	if (n < 3) {
		return false;
	}
	const Vector2 *pts = poly.ptr();
	bool inside = false;
	for (int64_t i = 0, j = n - 1; i < n; j = i++) {
		const Vector2 &a = pts[i];
		const Vector2 &b = pts[j];
		if (((a.y > p.y) != (b.y > p.y)) &&
				(D(p.x) < (D(b.x) - D(a.x)) * (D(p.y) - D(a.y)) / (D(b.y) - D(a.y)) + D(a.x))) {
			inside = !inside;
		}
	}
	return inside;
}

bool within_ring(const PackedVector2Array &inner, const PackedVector2Array &outer, double tol) {
	const int64_t ni = inner.size();
	const int64_t no = outer.size();
	if (no < 3) {
		return false;
	}
	const Vector2 *pi = inner.ptr();
	const Vector2 *po = outer.ptr();
	const double tol2 = tol * tol;
	for (int64_t k = 0; k < ni; ++k) {
		const Vector2 &p = pi[k];
		if (point_in_poly(p, outer)) {
			continue;
		}
		bool on = false;
		for (int64_t i = 0; i < no; ++i) {
			const Vector2 &a = po[i];
			const Vector2 &b = po[(i + 1) % no];
			const double abx = D(b.x) - D(a.x);
			const double aby = D(b.y) - D(a.y);
			const double l2 = abx * abx + aby * aby;
			double dx, dy;
			if (l2 > 1e-12) {
				const double t = Math::clamp(((D(p.x) - D(a.x)) * abx + (D(p.y) - D(a.y)) * aby) / l2, 0.0, 1.0);
				dx = D(a.x) + abx * t - D(p.x);
				dy = D(a.y) + aby * t - D(p.y);
			} else {
				dx = D(a.x) - D(p.x);
				dy = D(a.y) - D(p.y);
			}
			if (dx * dx + dy * dy <= tol2) {
				on = true;
				break;
			}
		}
		if (!on) {
			return false;
		}
	}
	return true;
}

PackedVector2Array inset_ring(const PackedVector2Array &ring, double inset) {
	Geometry2D *g = Geometry2D::get_singleton();
	TypedArray<PackedVector2Array> offset = g->offset_polygon(ring, -(real_t)inset);
	const int64_t count = offset.size();
	if (count == 0) {
		return PackedVector2Array();
	}
	double largest = 0.0;
	bool cw = false;
	for (int64_t i = 0; i < count; ++i) {
		const PackedVector2Array p = offset[i];
		const double ar = std::abs(signed_area(p));
		if (ar > largest) {
			largest = ar;
			cw = g->is_polygon_clockwise(p);
		}
	}
	int solid_count = 0;
	PackedVector2Array result;
	for (int64_t i = 0; i < count; ++i) {
		const PackedVector2Array p = offset[i];
		if (g->is_polygon_clockwise(p) == cw) {
			solid_count++;
			if (solid_count > 1) {
				return PackedVector2Array();
			}
			result = p;
		}
	}
	if (solid_count != 1 || result.size() < 3 ||
			std::abs(signed_area(result)) < std::abs(signed_area(ring)) * 0.2) {
		return PackedVector2Array();
	}
	return result;
}

bool pokes_into(const PackedVector2Array &outer, const PackedVector2Array &inner) {
	if (inner.size() < 3) {
		return false;
	}
	const int64_t n = outer.size();
	const Vector2 *p = outer.ptr();
	for (int64_t i = 0; i < n; ++i) {
		if (point_in_poly(p[i], inner)) {
			return true;
		}
	}
	return false;
}

bool meets_hole(const PackedVector2Array &ring, const std::vector<PackedVector2Array> &holes) {
	if (holes.empty()) {
		return false;
	}
	const int64_t rn = ring.size();
	const Vector2 *rp = ring.ptr();
	for (const PackedVector2Array &h : holes) {
		const int64_t hn = h.size();
		const Vector2 *hp = h.ptr();
		for (int64_t i = 0; i < hn; ++i) {
			if (point_in_poly(hp[i], ring)) {
				return true;
			}
		}
		for (int64_t i = 0; i < rn; ++i) {
			if (point_in_poly(rp[i], h)) {
				return true;
			}
		}
	}
	return false;
}

} // namespace

int PartyIndex::key_id(const String &key) {
	std::string k = key.utf8().get_data();
	auto it = keys.find(k);
	if (it != keys.end()) {
		return it->second;
	}
	int id = (int)keys.size();
	keys.emplace(k, id);
	key_tops.push_back(-INFINITY);
	return id;
}

// PartyWalls._insert
void PartyIndex::insert(std::unordered_map<int64_t, std::vector<int>> &grid, const Vector2 &a, const Vector2 &b, int rec) {
	const double c = CELL_M;
	int64_t x0 = floori(Math::min(D(a.x), D(b.x)) / c);
	int64_t x1 = floori(Math::max(D(a.x), D(b.x)) / c);
	int64_t z0 = floori(Math::min(D(a.y), D(b.y)) / c);
	int64_t z1 = floori(Math::max(D(a.y), D(b.y)) / c);
	for (int64_t ix = x0; ix <= x1; ix++) {
		for (int64_t iz = z0; iz <= z1; iz++) {
			grid[cell_key(ix, iz)].push_back(rec);
		}
	}
}

void PartyIndex::add_ring(const PackedVector2Array &ring, const String &key, double top, bool hole) {
	int kid = key_id(key);
	key_tops[kid] = Math::max(key_tops[kid], top);
	bool ccw = signed_area(ring) > 0.0;
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		Vector2 a = ring[i];
		Vector2 b = ring[(i + 1) % n];
		if (D(a.distance_to(b)) < 0.01) {
			continue;
		}
		edges.push_back({ a, b, outward_ccw(ring, i, hole, ccw), kid, top });
		insert(edge_cells, a, b, (int)edges.size() - 1);
	}
}

void PartyIndex::add_road(const Vector2 &a, const Vector2 &b, double hw) {
	roads.push_back({ a, b, hw });
	insert(road_cells, a, b, (int)roads.size() - 1);
}

// PartyWalls.partition
Array PartyIndex::partition(const Vector2 &a, const Vector2 &b, const Vector2 &n, int key) const {
	Vector2 e = b - a;
	double len2 = e.length_squared();
	if (len2 < 0.0001) {
		Array one;
		one.push_back(piece(0.0, 1.0, OPEN));
		return one;
	}
	const double tol = TOL_M;
	const double c = CELL_M;
	std::vector<Cover> spans;
	// rec ids already counted (an edge spans several cells); few per query.
	std::vector<int> seen;
	int64_t x0 = floori((Math::min(D(a.x), D(b.x)) - tol) / c);
	int64_t x1 = floori((Math::max(D(a.x), D(b.x)) + tol) / c);
	int64_t z0 = floori((Math::min(D(a.y), D(b.y)) - tol) / c);
	int64_t z1 = floori((Math::max(D(a.y), D(b.y)) + tol) / c);
	for (int64_t ix = x0; ix <= x1; ix++) {
		for (int64_t iz = z0; iz <= z1; iz++) {
			auto it = edge_cells.find(cell_key(ix, iz));
			if (it == edge_cells.end()) {
				continue;
			}
			for (int rid : it->second) {
				if (std::find(seen.begin(), seen.end(), rid) != seen.end()) {
					continue;
				}
				const Edge &r = edges[rid];
				if (r.key == key) {
					continue;
				}
				seen.push_back(rid);
				double rec_top = r.top;
				double facing = D(r.out.dot(n));
				if (facing >= PARALLEL) {
					// PartyWalls: the same wall drawn by another mass is
					// hidden here when that mass stands at least as tall
					// (a tie goes to the first registered).
					if (std::abs(D((r.a - a).dot(n))) > SAME_TOL_M ||
							std::abs(D((r.b - a).dot(n))) > SAME_TOL_M) {
						continue;
					}
					// An unregistered (raised) part gives the shared wall to
					// the mass registered there, up to that mass's top.
					if (key >= 0) {
						double own = key_tops[key];
						if (!(r.top > own + SAME_TOL_M || (r.top >= own - SAME_TOL_M && r.key < key))) {
							continue;
						}
						// A tie hides the whole wall, even a few cm taller.
						rec_top = Math::max(r.top, own);
					}
				} else if (facing > -PARALLEL) {
					continue;
				} else if (std::abs(D((r.a - a).dot(n))) > tol || std::abs(D((r.b - a).dot(n))) > tol) {
					continue;
				}
				double t0 = Math::clamp(D((r.a - a).dot(e)) / len2, 0.0, 1.0);
				double t1 = Math::clamp(D((r.b - a).dot(e)) / len2, 0.0, 1.0);
				if (std::abs(t1 - t0) * std::sqrt(len2) < MIN_COVER_M) {
					continue;
				}
				spans.push_back({ Math::min(t0, t1), Math::max(t0, t1), rec_top });
			}
		}
	}
	if (spans.empty()) {
		Array one;
		one.push_back(piece(0.0, 1.0, OPEN));
		return one;
	}
	return pieces(spans, std::sqrt(len2) / 1.0);
}

Array PartyIndex::ring_cover(const PackedVector2Array &ring, const String &key, bool hole) {
	auto it = keys.find(key.utf8().get_data());
	int kid = it != keys.end() ? it->second : -1;
	bool ccw = signed_area(ring) > 0.0;
	Array out;
	int64_t n = ring.size();
	for (int64_t i = 0; i < n; i++) {
		out.push_back(partition(ring[i], ring[(i + 1) % n], outward_ccw(ring, i, hole, ccw), kid));
	}
	return out;
}

bool PartyIndex::faces_street(const Vector2 &a, const Vector2 &b, const Vector2 &n) const {
	Vector2 p = (a + b) * 0.5 + n * 1.5 * 1.0;
	const double reach = STREET_M;
	const double c = CELL_M;
	Geometry2D *g = Geometry2D::get_singleton();
	for (int64_t ix = floori((D(p.x) - reach) / c); ix <= floori((D(p.x) + reach) / c); ix++) {
		for (int64_t iz = floori((D(p.y) - reach) / c); iz <= floori((D(p.y) + reach) / c); iz++) {
			auto it = road_cells.find(cell_key(ix, iz));
			if (it == road_cells.end()) {
				continue;
			}
			for (int rid : it->second) {
				const Road &r = roads[rid];
				const Vector2 ab = r.b - r.a;
				const double l2 = D(ab.x) * D(ab.x) + D(ab.y) * D(ab.y);
				Vector2 q = r.a;
				if (l2 > 1e-12) {
					const double t = Math::clamp((D(p.x - r.a.x) * D(ab.x) + D(p.y - r.a.y) * D(ab.y)) / l2, 0.0, 1.0);
					q = r.a + ab * (real_t)t;
				}
				if (D(q.distance_to(p)) < reach + r.hw && D((q - p).dot(n)) > -1.0 * 1.0) {
					return true;
				}
			}
		}
	}
	return false;
}

void PartyIndex::add_roads(const Array &data_roads, double m2u) {
	const int64_t rn = data_roads.size();
	for (int64_t ri = 0; ri < rn; ++ri) {
		const Variant &item = data_roads[ri];
		PackedVector2Array pts;
		double hw = 4.0;
		if (item.get_type() == Variant::DICTIONARY) {
			const Dictionary d = item;
			if ((bool)d.get("tunnel", false)) {
				continue;
			}
			const Variant pv = d.get("points", Variant());
			if (pv.get_type() != Variant::PACKED_VECTOR2_ARRAY) {
				continue;
			}
			pts = pv;
			hw = (double)d.get("width_m", 8.0) * 0.5;
		} else if (item.get_type() == Variant::PACKED_VECTOR2_ARRAY) {
			pts = item;
		} else {
			continue;
		}
		const int64_t pn = pts.size();
		if (pn < 2) {
			continue;
		}
		const Vector2 *pp = pts.ptr();
		const double hw_u = hw * m2u;
		for (int64_t i = 0; i < pn - 1; ++i) {
			add_road(pp[i], pp[i + 1], hw_u);
		}
	}
}

void PartyIndex::add_outline(const PackedVector2Array &ring, const Array &holes, const String &key, double top) {
	if (ring.is_empty()) {
		return;
	}
	const int kid = key_id(key);
	const Rect2 box = ring_aabb(ring);
	const int order = (int)outline_of.size();
	Outline o;
	o.ring = ring;
	const int64_t hn = holes.size();
	o.holes.reserve((size_t)hn);
	for (int64_t i = 0; i < hn; ++i) {
		if (holes[i].get_type() == Variant::PACKED_VECTOR2_ARRAY) {
			o.holes.push_back((PackedVector2Array)holes[i]);
		}
	}
	o.key = kid;
	o.top = top;
	o.order = order;
	o.box = box;
	const int idx = (int)outlines.size();
	outlines.push_back(std::move(o));
	outline_of[kid] = idx;
	const double c = CELL_M;
	const int64_t x0 = floori(D(box.position.x) / c);
	const int64_t x1 = floori(D(box.position.x + box.size.x) / c);
	const int64_t z0 = floori(D(box.position.y) / c);
	const int64_t z1 = floori(D(box.position.y + box.size.y) / c);
	for (int64_t ix = x0; ix <= x1; ++ix) {
		for (int64_t iz = z0; iz <= z1; ++iz) {
			outline_cells[cell_key(ix, iz)].push_back(idx);
		}
	}
}

bool PartyIndex::enclosed(const PackedVector2Array &ring, const String &key, double roof_h) const {
	if (ring.is_empty()) {
		return false;
	}
	auto kit = keys.find(key.utf8().get_data());
	if (kit == keys.end()) {
		return false;
	}
	const int kid = kit->second;
	auto oit = outline_of.find(kid);
	if (oit == outline_of.end()) {
		return false;
	}
	const Outline &own = outlines[oit->second];
	const double tol = SAME_TOL_M;
	const double own_top = own.top + roof_h;
	const int own_order = own.order;
	const Rect2 box = ring_aabb(ring);
	const int64_t ck = cell_key(floori(D(box.position.x) / CELL_M), floori(D(box.position.y) / CELL_M));
	auto cit = outline_cells.find(ck);
	if (cit == outline_cells.end()) {
		return false;
	}
	const Rect2 box_grown = box.grow((real_t)tol);
	bool inset_ready = false;
	PackedVector2Array inset;
	for (int idx : cit->second) {
		const Outline &rec = outlines[idx];
		if (rec.key == kid || rec.top < own_top - tol) {
			continue;
		}
		if (rec.top <= own_top + tol && rec.order > own_order && box_grown.encloses(rec.box)) {
			continue;
		}
		if (!rec.box.grow((real_t)tol).encloses(box)) {
			continue;
		}
		if (!within_ring(ring, rec.ring, tol)) {
			continue;
		}
		if (!inset_ready) {
			inset = inset_ring(ring, tol);
			inset_ready = true;
		}
		if (pokes_into(rec.ring, inset) || meets_hole(ring, rec.holes)) {
			continue;
		}
		return true;
	}
	return false;
}

void PartyIndex::_bind_methods() {
	ClassDB::bind_method(D_METHOD("add_ring", "ring", "key", "top", "hole"), &PartyIndex::add_ring);
	ClassDB::bind_method(D_METHOD("add_outline", "ring", "holes", "key", "top"), &PartyIndex::add_outline);
	ClassDB::bind_method(D_METHOD("enclosed", "ring", "key", "roof_h"), &PartyIndex::enclosed);
	ClassDB::bind_method(D_METHOD("add_road", "a", "b", "hw"), &PartyIndex::add_road);
	ClassDB::bind_method(D_METHOD("add_roads", "data_roads", "m2u"), &PartyIndex::add_roads);
	ClassDB::bind_method(D_METHOD("ring_cover", "ring", "key", "hole"), &PartyIndex::ring_cover);
	ClassDB::bind_method(D_METHOD("faces_street", "a", "b", "n"), &PartyIndex::faces_street);
}

} // namespace godot
