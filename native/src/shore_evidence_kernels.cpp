#include "shore_evidence_kernels.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/geometry2d.hpp>
#include <godot_cpp/variant/vector4.hpp>
#include <algorithm>
#include <cmath>
#include <unordered_set>

namespace godot {
namespace {
int64_t key(int x, int z) { return (int64_t)((uint64_t)(uint32_t)x << 32 | (uint32_t)z); }

}
void ShoreEvidenceIndex::setup(const Array &input, const Dictionary &p_cells) {
	features.clear(); cells.clear();
	for (int64_t i = 0; i < input.size(); ++i) {
		Dictionary item = input[i];
		Feature f;
		f.kind = item["kind"]; f.points = item["points"]; f.area = item.get("area", false);
		f.width = item.get("width", 0.0); f.id = item.get("id", f.kind);
		const Array holes = item.get("holes", Array());
		for (int64_t j = 0; j < holes.size(); ++j) f.holes.push_back(holes[j]);
		if (!f.points.is_empty()) {
			f.bounds = Rect2(f.points[0], Vector2());
			for (int64_t j = 1; j < f.points.size(); ++j) f.bounds.expand_to(f.points[j]);
		}
		features.push_back(std::move(f));
	}
	const Array keys = p_cells.keys();
	for (int64_t i = 0; i < keys.size(); ++i) {
		Vector2i p = keys[i]; const Array ids = p_cells[keys[i]];
		auto &cell = cells[key(p.x, p.y)];
		for (int64_t j = 0; j < ids.size(); ++j) cell.push_back(ids[j]);
	}
}
std::vector<int> ShoreEvidenceIndex::candidates(const Vector2 &p, double radius) const {
	std::unordered_set<int> unique;
	for (int z = (int)std::floor((p.y - radius) / 64.0); z <= (int)std::floor((p.y + radius) / 64.0); ++z) {
		for (int x = (int)std::floor((p.x - radius) / 64.0); x <= (int)std::floor((p.x + radius) / 64.0); ++x) {
			const auto cell = cells.find(key(x, z));
			if (cell != cells.end()) unique.insert(cell->second.begin(), cell->second.end());
		}
	}
	std::vector<int> out(unique.begin(), unique.end());
	std::sort(out.begin(), out.end());
	return out;
}
bool ShoreEvidenceIndex::inside(const Vector2 &p, const Feature &f) {
	if (!f.bounds.grow(0.0001).has_point(p) || !Geometry2D::get_singleton()->is_point_in_polygon(p, f.points)) return false;
	for (const auto &hole : f.holes) if (Geometry2D::get_singleton()->is_point_in_polygon(p, hole)) return false;
	return true;
}
Vector4 ShoreEvidenceIndex::nearest(const Vector2 &p, const Feature &f) {
	if (f.area && inside(p, f)) return Vector4(p.x, p.y, 0, 0);
	double best = INFINITY; Vector2 point, dir;
	const int64_t count = f.area ? f.points.size() : f.points.size() - 1;
	for (int64_t i = 0; i < count; ++i) {
		const Vector2 a = f.points[i], b = f.points[(i + 1) % f.points.size()], d = b - a;
		const double t = std::clamp((double)(p - a).dot(d) / std::max((double)d.length_squared(), 0.00001), 0.0, 1.0);
		const Vector2 q = a + d * (real_t)t;
		const double distance = std::max(0.0, (double)p.distance_to(q) - f.width);
		if (distance < best) { best = distance; point = q; dir = d.normalized(); }
	}
	// Direction is recovered from its angle; distance is independent.
	return Vector4(point.x, point.y, (real_t)best, dir.angle());
}
bool ShoreEvidenceIndex::contains_kind(const Vector2 &p, const String &kind) const {
	for (int id : candidates(p, 0)) {
		const Feature &f = features[id];
		if (f.kind == kind && f.area && inside(p, f)) return true;
	}
	return false;
}
Dictionary ShoreEvidenceIndex::classify(const Vector2 &a, const Vector2 &b, const Vector2 &land) const {
	Array explicit_ids, sources;
	int votes = 0;
	bool natural_cover = false;
	const Vector2 dir = (b - a).normalized();
	for (double t : {0.0, 0.5, 1.0}) {
		const Vector2 p = a.lerp(b, (real_t)t);
		bool paved = false, built = false;
		const bool natural = contains_kind(p + land * (real_t)2.0, "natural");
		natural_cover = natural_cover || natural;
		for (int id : candidates(p, 24)) {
			const Feature &f = features[id];
			// Natural cover was tested above. Its often large boundary is
			// not distance evidence for paving, frontage or structures.
			if (f.kind == "natural") continue;
			const double limit = f.kind == "structure" ? 3.0 : f.kind == "break" ? 1.0 : f.kind == "paved" ? 8.0 : 20.0;
			if (!f.bounds.grow(limit + f.width + 0.0001).has_point(p)) continue;
			const Vector4 near = nearest(p, f);
			const Vector2 q(near.x, near.y), tangent(std::cos(near.w), std::sin(near.w));
			if (f.kind == "structure" && near.z <= 3.0 && std::abs((double)dir.dot(tangent)) >= 0.8) explicit_ids.push_back(f.id);
			else if (f.kind == "break" && near.z <= 1.0) { Dictionary out; out["kind"] = "natural"; out["reason"] = "mapped_access"; Array ids; ids.push_back(f.id); out["sources"] = ids; return out; }
			else if ((q - p).dot(land) >= -0.01) {
				if (f.kind == "paved" && near.z <= 8.0) { paved = true; sources.push_back(f.id); }
				if (f.kind == "building" && near.z <= 20.0) { built = true; sources.push_back(f.id); }
			}
		}
		if (!natural && paved && built) ++votes;
	}
	Dictionary out;
	out["kind"] = !explicit_ids.is_empty() || (!natural_cover && votes >= 2) ? "hard" : "natural";
	out["reason"] = !explicit_ids.is_empty() ? "mapped_structure" : (natural_cover ? "natural_cover" : (votes >= 2 ? "paving_and_frontage" : "insufficient_evidence"));
	out["sources"] = !explicit_ids.is_empty() ? explicit_ids : (!natural_cover && votes >= 2 ? sources : Array());
	return out;
}
void ShoreEvidenceIndex::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "features", "cells"), &ShoreEvidenceIndex::setup);
	ClassDB::bind_method(D_METHOD("contains_kind", "point", "kind"), &ShoreEvidenceIndex::contains_kind);
	ClassDB::bind_method(D_METHOD("classify", "a", "b", "land"), &ShoreEvidenceIndex::classify);
}
} // namespace godot
