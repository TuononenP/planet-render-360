#include "steps_kernels.h"

#include <godot_cpp/classes/geometry2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <unordered_map>
#include <vector>

namespace godot {

namespace {

// Geometry2D.is_point_in_polygon itself: on a polygon's edge the engine's
// answer is not the plain even-odd ray's, so the script's is asked for.
bool in_polygon(const Vector2 &p, const PackedVector2Array &polygon) {
	return Geometry2D::get_singleton()->is_point_in_polygon(p, polygon);
}

// Geometry2D.get_closest_point_to_segment, the engine's own.
Vector2 closest_on_segment(const Vector2 &point, const Vector2 &s0, const Vector2 &s1) {
	return Geometry2D::get_singleton()->get_closest_point_to_segment(point, s0, s1);
}

// RoadGrading._ring_distance: from p to the nearest edge of the ring.
double ring_distance(const Vector2 &p, const Vector2 *ring, int64_t n) {
	double best = INFINITY;
	for (int64_t i = 0; i < n; i++) {
		const double d = (double)p.distance_to(closest_on_segment(p, ring[i], ring[(i + 1) % n]));
		best = d < best ? d : best;
	}
	return best;
}

// RoadGrading._area.
double ring_area(const Vector2 *ring, int64_t n) {
	double s = 0.0;
	for (int64_t i = 0; i < n; i++) {
		const Vector2 a = ring[i];
		const Vector2 b = ring[(i + 1) % n];
		s += (double)a.x * (double)b.y - (double)b.x * (double)a.y;
	}
	return std::fabs(s) * 0.5;
}

// RingGeometry.aabb (a ring of at least one point).
Rect2 ring_box(const Vector2 *ring, int64_t n) {
	Vector2 mn = ring[0];
	Vector2 mx = ring[0];
	for (int64_t i = 0; i < n; i++) {
		mn.x = ring[i].x < mn.x ? ring[i].x : mn.x;
		mn.y = ring[i].y < mn.y ? ring[i].y : mn.y;
		mx.x = ring[i].x > mx.x ? ring[i].x : mx.x;
		mx.y = ring[i].y > mx.y ? ring[i].y : mx.y;
	}
	return Rect2(mn, mx - mn);
}

// StepsGround._near_buildings' entries: the footprint box grown a post,
// the footprint and its courtyards.
struct Building {
	Rect2 box;
	PackedVector2Array footprint;
	std::vector<PackedVector2Array> holes;
};

// From p to the ring: 0 inside it, else to its nearest edge (_ring_gap).
double ring_gap(const Vector2 &p, const PackedVector2Array &ring) {
	return in_polygon(p, ring) ? 0.0 : ring_distance(p, ring.ptr(), ring.size());
}

struct Parks {
	int size = 0;
	double step = 1.0;
	double hs = 0.0;
	double slack = 0.0;
	const float *level = nullptr;
	std::vector<float> work;
	std::vector<uint8_t> blocked;
	std::vector<uint8_t> changed;
	std::vector<Building> buildings;

	Vector2 post(int x, int z) const {
		return Vector2((real_t)(((double)x - hs) * step), (real_t)(((double)z - hs) * step));
	}
	// The posts of `box`: [x0, x1] x [z0, z1].
	void range(const Rect2 &box, int &x0, int &x1, int &z0, int &z1) const {
		const Vector2 end = box.get_end();
		x0 = (int)std::max((int64_t)std::floor((double)box.position.x / step + hs), (int64_t)0);
		x1 = (int)std::min((int64_t)std::ceil((double)end.x / step + hs), (int64_t)size - 1);
		z0 = (int)std::max((int64_t)std::floor((double)box.position.y / step + hs), (int64_t)0);
		z1 = (int)std::min((int64_t)std::ceil((double)end.y / step + hs), (int64_t)size - 1);
	}

	// StepsGround._mean_inside: the mean height of the dry posts inside the
	// ring and outside the buildings near it, NAN when there is none.
	double mean_inside(const PackedVector2Array &ring, const std::vector<const Building *> &near) const {
		const Vector2 *r = ring.ptr();
		const Rect2 box = ring_box(r, ring.size());
		int x0, x1, z0, z1;
		range(box, x0, x1, z0, z1);
		double sum = 0.0;
		int n = 0;
		for (int z = z0; z <= z1; z++) {
			for (int x = x0; x <= x1; x++) {
				const int64_t i = (int64_t)z * size + x;
				if (!std::isinf(level[i])) {
					continue;
				}
				const Vector2 w = post(x, z);
				if (in_polygon(w, ring) && !in_building(w, near)) {
					sum += (double)work[i];
					n++;
				}
			}
		}
		return n > 0 ? sum / (double)n : NAN;
	}

	// StepsGround._level_polygon: the posts inside the ring (not its holes,
	// water, a building or a flight) to `target`, lifted at most `slack`,
	// those one post outside easing back to the ground.
	void level_polygon(const PackedVector2Array &ring, const Array &holes, double target,
			const std::vector<const Building *> &near) {
		const Vector2 *r = ring.ptr();
		const int64_t rn = ring.size();
		const Rect2 box = ring_box(r, rn).grow((real_t)step);
		int x0, x1, z0, z1;
		range(box, x0, x1, z0, z1);
		for (int z = z0; z <= z1; z++) {
			for (int x = x0; x <= x1; x++) {
				const int64_t i = (int64_t)z * size + x;
				if (!std::isinf(level[i]) || blocked[i]) {
					continue;
				}
				const Vector2 w = post(x, z);
				double weight = 1.0;
				if (!in_polygon(w, ring)) {
					const double d = ring_distance(w, r, rn);
					if (d >= step) {
						continue;
					}
					weight = 1.0 - d / step;
				} else if (in_hole(w, holes)) {
					continue;
				}
				if (in_building(w, near)) {
					continue;
				}
				const double a = (double)work[i];
				const double lifted = a + slack;
				const double to = target < lifted ? target : lifted;
				work[i] = (float)(a + (to - a) * weight);
				changed[i] = 1;
			}
		}
	}

	// StepsGround._near_buildings: those whose footprint box reaches the
	// posts round the ring.
	std::vector<const Building *> near_buildings(const PackedVector2Array &ring) const {
		const Rect2 box = ring_box(ring.ptr(), ring.size()).grow((real_t)(step * 2.0));
		std::vector<const Building *> near;
		for (const Building &b : buildings) {
			if (box.intersects(b.box, true)) {
				near.push_back(&b);
			}
		}
		return near;
	}

	static bool in_hole(const Vector2 &p, const Array &holes) {
		for (int64_t k = 0; k < holes.size(); k++) {
			const Variant h = holes[k];
			if (h.get_type() == Variant::PACKED_VECTOR2_ARRAY) {
				const PackedVector2Array hole = h;
				if (in_polygon(p, hole)) {
					return true;
				}
			}
		}
		return false;
	}

	static bool in_building(const Vector2 &p, const std::vector<const Building *> &near) {
		for (const Building *b : near) {
			if (!b->box.has_point(p) || !in_polygon(p, b->footprint)) {
				continue;
			}
			bool courtyard = false;
			for (const PackedVector2Array &h : b->holes) {
				if (in_polygon(p, h)) {
					courtyard = true;
					break;
				}
			}
			if (!courtyard) {
				return true;
			}
		}
		return false;
	}
};

} // namespace

PackedInt32Array StepsKernels::step_roads(const Array &roads) {
	PackedInt32Array out;
	for (int64_t i = 0; i < roads.size(); i++) {
		const Variant r = roads[i];
		if (r.get_type() != Variant::DICTIONARY) {
			continue;
		}
		const Dictionary d = r;
		const String cls = d.get("class", "");
		if (cls == "steps") {
			out.push_back((int32_t)i);
		}
	}
	return out;
}

Array StepsKernels::touch(const Array &roads, const PackedVector2Array &nodes, double cell, double reach) {
	const int64_t count = nodes.size();
	PackedByteArray bridged;
	bridged.resize(count);
	bridged.fill(0);
	std::vector<std::vector<String>> seen((size_t)count);

	auto key = [cell](const Vector2 &p) -> int64_t {
		return ((int64_t)std::floor((double)p.x / cell) + 4096) * 8192 + (int64_t)std::floor((double)p.y / cell) + 4096;
	};
	// StepsGround._Net.index: each node in the cells its box spans.
	std::unordered_map<int64_t, std::vector<int>> grid;
	for (int64_t i = 0; i < count; i++) {
		const Vector2 c = nodes[i];
		const double xs[2] = { (double)c.x - reach, (double)c.x + reach };
		const double zs[2] = { (double)c.y - reach, (double)c.y + reach };
		for (double cx : xs) {
			for (double cz : zs) {
				std::vector<int> &cellv = grid[key(Vector2((real_t)cx, (real_t)cz))];
				if (std::find(cellv.begin(), cellv.end(), (int)i) == cellv.end()) {
					cellv.push_back((int)i);
				}
			}
		}
	}

	for (int64_t w = 0; w < roads.size(); w++) {
		const Variant rv = roads[w];
		if (rv.get_type() != Variant::DICTIONARY) {
			continue;
		}
		const Dictionary d = rv;
		const String cls = d.get("class", "");
		if ((bool)d.get("area", false) || (bool)d.get("tunnel", false) || cls == "steps") {
			continue;
		}
		const bool bridge = (bool)d.get("bridge", false) || (int64_t)d.get("layer", 0) >= 1;
		const PackedVector2Array pts = d.get("points", PackedVector2Array());
		for (int64_t k = 0; k < pts.size(); k++) {
			const Vector2 p = pts[k];
			const auto near = grid.find(key(p));
			if (near == grid.end()) {
				continue;
			}
			for (int i : near->second) {
				if ((double)nodes[i].distance_to(p) > reach) {
					continue;
				}
				if (bridge) {
					bridged[i] = 1;
				} else {
					std::vector<String> &classes = seen[(size_t)i];
					if (std::find(classes.begin(), classes.end(), cls) == classes.end()) {
						classes.push_back(cls);
					}
				}
			}
		}
	}

	Array classes_out;
	for (int64_t i = 0; i < count; i++) {
		PackedStringArray names;
		for (const String &s : seen[(size_t)i]) {
			names.push_back(s);
		}
		classes_out.push_back(names);
	}
	Array out;
	out.push_back(bridged);
	out.push_back(classes_out);
	return out;
}

Array StepsKernels::hold_parks(const PackedFloat32Array &surface, const PackedFloat32Array &level, int size, double step,
		const Array &rings, const Array &buildings, const PackedVector2Array &foot_pos,
		const PackedVector2Array &top_pos, const PackedFloat64Array &foot_levels, const PackedInt32Array &under,
		double reach, double max_area, double slack) {
	PackedInt32Array out_index;
	PackedFloat32Array out_value;
	Array out;
	const int64_t count = (int64_t)size * size;
	if (size < 2 || surface.size() != count || level.size() != count || top_pos.size() < foot_pos.size() ||
			foot_levels.size() < foot_pos.size() * 2) {
		out.push_back(out_index);
		out.push_back(out_value);
		return out;
	}

	Parks parks;
	parks.size = size;
	parks.step = step;
	parks.hs = (double)size * 0.5;
	parks.slack = slack;
	parks.level = level.ptr();
	parks.work.assign(surface.ptr(), surface.ptr() + count);
	parks.blocked.assign((size_t)count, 0);
	parks.changed.assign((size_t)count, 0);
	for (int64_t k = 0; k < under.size(); k++) {
		if (under[k] >= 0 && under[k] < count) {
			parks.blocked[(size_t)under[k]] = 1;
		}
	}
	// The buildings, read on the first ring a foot reaches.
	bool read = false;
	auto read_buildings = [&]() {
		read = true;
		for (int64_t k = 0; k < buildings.size(); k++) {
			const Variant bv = buildings[k];
			if (bv.get_type() != Variant::DICTIONARY) {
				continue;
			}
			const Dictionary b = bv;
			const Variant fv = b.get("footprint", PackedVector2Array());
			if (fv.get_type() != Variant::PACKED_VECTOR2_ARRAY) {
				continue;
			}
			const PackedVector2Array fp = fv;
			if (fp.size() < 3) {
				continue;
			}
			Building out_b;
			out_b.box = ring_box(fp.ptr(), fp.size()).grow((real_t)step);
			out_b.footprint = fp;
			const Variant hv = b.get("holes", Array());
			if (hv.get_type() == Variant::ARRAY) {
				const Array hs = hv;
				for (int64_t h = 0; h < hs.size(); h++) {
					if (hs[h].get_type() == Variant::PACKED_VECTOR2_ARRAY) {
						out_b.holes.push_back(hs[h]);
					}
				}
			}
			parks.buildings.push_back(out_b);
		}
	};

	for (int64_t ri = 0; ri < rings.size(); ri++) {
		const Dictionary poly = rings[ri];
		const PackedVector2Array ring = poly.get("points", PackedVector2Array());
		const int64_t rn = ring.size();
		if (rn < 3 || ring_area(ring.ptr(), rn) > max_area) {
			continue;
		}
		const Rect2 box = ring_box(ring.ptr(), rn).grow((real_t)reach);
		std::vector<const Building *> near;
		double mean = NAN;
		bool measured = false;
		for (int64_t f = 0; f < foot_pos.size(); f++) {
			const Vector2 c = foot_pos[f];
			if (!box.has_point(c)) {
				continue;
			}
			// Not the terrace the flight comes down from.
			const double gap = ring_gap(c, ring);
			if (gap > reach || ring_gap(top_pos[f], ring) < gap) {
				continue;
			}
			if (!measured) {
				if (!read) {
					read_buildings();
				}
				near = parks.near_buildings(ring);
				mean = parks.mean_inside(ring, near);
				measured = true;
			}
			const double bottom = foot_levels[f * 2];
			const double top = foot_levels[f * 2 + 1];
			if (std::isnan(mean) || mean < bottom - slack || mean > top) {
				continue;
			}
			parks.level_polygon(ring, poly.get("holes", Array()), bottom, near);
			break;
		}
	}

	for (int64_t i = 0; i < count; i++) {
		if (parks.changed[(size_t)i]) {
			out_index.push_back((int32_t)i);
			out_value.push_back(parks.work[(size_t)i]);
		}
	}
	out.push_back(out_index);
	out.push_back(out_value);
	return out;
}

void StepsKernels::_bind_methods() {
	ClassDB::bind_static_method("StepsKernels", D_METHOD("step_roads", "roads"), &StepsKernels::step_roads);
	ClassDB::bind_static_method("StepsKernels", D_METHOD("touch", "roads", "nodes", "cell", "reach"),
			&StepsKernels::touch);
	ClassDB::bind_static_method("StepsKernels",
			D_METHOD("hold_parks", "surface", "level", "size", "step", "rings", "buildings", "foot_pos",
					"top_pos", "foot_levels", "under", "reach", "max_area", "slack"),
			&StepsKernels::hold_parks);
}

} // namespace godot
