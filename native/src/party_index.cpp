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

} // namespace

int PartyIndex::key_id(const String &key) {
	std::string k = key.utf8().get_data();
	auto it = keys.find(k);
	if (it != keys.end()) {
		return it->second;
	}
	int id = (int)keys.size();
	keys.emplace(k, id);
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
				if (D(r.out.dot(n)) > -PARALLEL) {
					continue;
				}
				if (std::abs(D((r.a - a).dot(n))) > tol || std::abs(D((r.b - a).dot(n))) > tol) {
					continue;
				}
				double t0 = Math::clamp(D((r.a - a).dot(e)) / len2, 0.0, 1.0);
				double t1 = Math::clamp(D((r.b - a).dot(e)) / len2, 0.0, 1.0);
				if (std::abs(t1 - t0) * std::sqrt(len2) < MIN_COVER_M) {
					continue;
				}
				spans.push_back({ Math::min(t0, t1), Math::max(t0, t1), r.top });
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
				Vector2 q = g->get_closest_point_to_segment(p, r.a, r.b);
				if (D(q.distance_to(p)) < reach + r.hw && D((q - p).dot(n)) > -1.0 * 1.0) {
					return true;
				}
			}
		}
	}
	return false;
}

void PartyIndex::_bind_methods() {
	ClassDB::bind_method(D_METHOD("add_ring", "ring", "key", "top", "hole"), &PartyIndex::add_ring);
	ClassDB::bind_method(D_METHOD("add_road", "a", "b", "hw"), &PartyIndex::add_road);
	ClassDB::bind_method(D_METHOD("ring_cover", "ring", "key", "hole"), &PartyIndex::ring_cover);
	ClassDB::bind_method(D_METHOD("faces_street", "a", "b", "n"), &PartyIndex::faces_street);
}

} // namespace godot
