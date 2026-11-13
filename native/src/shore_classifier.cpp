#include "shore_classifier.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector3i.hpp>
#include <algorithm>
#include <cmath>
#include <map>
#include <unordered_map>

namespace godot {
namespace {
// ShoreGeometry.snap: Vector2.snapped to 1 cm, in floats.
Vector2 snap(const Vector2 &p) {
	return Vector2(Math::snapped(p.x, (real_t)0.01), Math::snapped(p.y, (real_t)0.01));
}
double gd_max(double a, double b) { return a > b ? a : b; }
double gd_clamp(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }
// Vector2 keys as the script's Dictionary compares them (-0 == 0).
struct PointLess {
	bool operator()(const Vector2 &a, const Vector2 &b) const { return a.x < b.x || (a.x == b.x && a.y < b.y); }
};
struct CacheHash {
	size_t operator()(const Vector3i &k) const {
		return (size_t)k.x * 73856093u ^ (size_t)k.y * 19349663u ^ (size_t)k.z * 83492791u;
	}
};
} // namespace

void ShoreClassifier::setup(const PackedFloat32Array &p_dry, int p_size, double p_step, double p_origin,
		const Rect2 &p_bounds, const Rect2 &p_domain_bounds, const Ref<ShoreDomainIndex> &p_domains,
		const PackedFloat64Array &p_levels, const Ref<ShoreEvidenceIndex> &p_evidence, const Dictionary &p_abutment_ends,
		double p_m2u) {
	dry = p_dry;
	size = p_size;
	step = p_step;
	origin = p_origin;
	bounds = p_bounds;
	domain_bounds = p_domain_bounds;
	domains = p_domains;
	evidence = p_evidence;
	abutment_ends = p_abutment_ends;
	m2u = p_m2u;
	levels.assign(p_levels.ptr(), p_levels.ptr() + p_levels.size());
}

// ShoreDomains.at: clamped just inside the domains' bounds when near them.
int ShoreClassifier::at(Vector2 p) const {
	if (domain_bounds.grow(0.01).has_point(p))
		p = p.clamp(domain_bounds.position + Vector2(1, 1) * (real_t)0.001, domain_bounds.get_end() - Vector2(1, 1) * (real_t)0.001);
	return domains->at(p, -1);
}

// ShoreDomains.level.
double ShoreClassifier::level(int body, const Vector2 &p) const {
	const double *b = &levels[(size_t)body * 7];
	if (b[2] == 0.0) return b[0];
	const Vector2 a0((real_t)b[3], (real_t)b[4]), a1((real_t)b[5], (real_t)b[6]);
	const Vector2 d = a1 - a0;
	const double t = gd_clamp((double)(p - a0).dot(d) / gd_max((double)d.length_squared(), 0.0001), 0.0, 1.0);
	return b[0] + (b[1] - b[0]) * t;
}

// ShorelineModel.dry_height (_grid_height over the dry grid).
double ShoreClassifier::dry_height(const Vector2 &p) const {
	if (size < 2 || dry.is_empty()) return 0.0;
	Vector2 f = (p - Vector2(1, 1) * (real_t)origin) / (real_t)step;
	f = f.clamp(Vector2(0, 0), Vector2(1, 1) * (real_t)(size - 1));
	const int x = std::min((int)f.x, size - 2), z = std::min((int)f.y, size - 2);
	const double tx = (double)f.x - x, tz = (double)f.y - z;
	const float *v = dry.ptr();
	const double v00 = v[z * size + x], v01 = v[z * size + x + 1];
	const double v10 = v[(z + 1) * size + x], v11 = v[(z + 1) * size + x + 1];
	const double a = v00 + (v01 - v00) * tx, b = v10 + (v11 - v10) * tx;
	return a + (b - a) * tz;
}

// ShorelineModel._bank_top_at: the median dry height 2, 5, 10 and 20
// inland, over open dry ground only; NAN under three samples.
double ShoreClassifier::bank_top(const Vector2 &p, const Vector2 &land) const {
	std::vector<double> values;
	for (double distance : { 2.0, 5.0, 10.0, 20.0 }) {
		const Vector2 q = p + land * (real_t)distance;
		if (bounds.has_point(q) && at(q) < 0 && !evidence->contains_code(q, ShoreEvidenceIndex::BUILDING))
			values.push_back(dry_height(q));
	}
	if (values.size() < 3) return NAN;
	std::sort(values.begin(), values.end());
	const size_t n = values.size();
	return (values[(n - 1) / 2] + values[n / 2]) * 0.5;
}

// ShorelineModel._abutment_top.
double ShoreClassifier::abutment_top(const Dictionary &treatment, const Vector2 &mid) const {
	const Array sources = treatment.get("sources", Array());
	for (int64_t s = 0; s < sources.size(); ++s) {
		const PackedVector2Array ends = abutment_ends.get(String(sources[s]), PackedVector2Array());
		if (ends.size() != 2) continue;
		const bool near0 = ends[0].distance_squared_to(mid) <= ends[1].distance_squared_to(mid);
		const Vector2 e = near0 ? ends[0] : ends[1];
		if (at(e) < 0) return dry_height(e);
		const Vector2 out = (e - (near0 ? ends[1] : ends[0])).normalized();
		double best = NAN;
		for (int k = 1; k < 11; ++k) {
			const Vector2 q = e + out * (real_t)2.0 * (real_t)(double)k * (real_t)m2u;
			if (bounds.has_point(q) && at(q) < 0) best = std::isnan(best) ? dry_height(q) : gd_max(best, dry_height(q));
		}
		return best;
	}
	return NAN;
}

// ShorelineModel.cell_at.
Vector2i ShoreClassifier::cell_at(const Vector2 &p) const {
	return Vector2i(std::clamp((int)std::floor(((double)p.x - origin) / step), 0, size - 2),
			std::clamp((int)std::floor(((double)p.y - origin) / step), 0, size - 2));
}

Dictionary ShoreClassifier::classify(const Array &edges, Object *abort) {
	Dictionary result;
	if (domains.is_null() || evidence.is_null()) return result;
	Array segments, diagnostics;
	Dictionary cells;
	std::unordered_map<Vector3i, Dictionary, CacheHash> cache;
	std::map<Vector2, std::vector<double>, PointLess> endpoint_tops;
	const Vector2 pad = Vector2(1, 1) * (real_t)0.01;
	for (int64_t e = 0; e < edges.size(); ++e) {
		if (abort != nullptr && (bool)abort->get("requested")) {
			result["aborted"] = true;
			return result;
		}
		Dictionary edge = edges[e];
		const Vector2 a = edge["a"], b = edge["b"];
		const Vector2 dir = (b - a).normalized();
		const Vector2 n(-dir.y, dir.x);
		const int count = std::max(1, (int)std::ceil((double)a.distance_to(b) / 2.0));
		for (int i = 0; i < count; ++i) {
			const Vector2 start = snap(a.lerp(b, (real_t)((double)i / (double)count)));
			const Vector2 end = snap(a.lerp(b, (real_t)((double)(i + 1) / (double)count)));
			const Vector2 mid = (start + end) * (real_t)0.5;
			const int left = at(mid + n * (real_t)0.05);
			const int right = at(mid - n * (real_t)0.05);
			if ((left >= 0) == (right >= 0)) {
				if (left < 0) {
					Dictionary d;
					d["kind"] = "ambiguous_shore";
					d["body"] = edge["body"];
					d["a"] = start;
					d["b"] = end;
					d["reason"] = "no_resolved_water_side";
					diagnostics.push_back(d);
				}
				continue;
			}
			const Vector2 land = left >= 0 ? -n : n;
			const int body = left >= 0 ? left : right;
			const Vector3i key((int)std::floor((double)mid.x / 10.0), (int)std::floor((double)mid.y / 10.0),
					(int)std::round((double)land.angle() * 12.0));
			auto cached = cache.find(key);
			if (cached == cache.end())
				cached = cache.emplace(key, evidence->classify(mid - dir * (real_t)5.0, mid + dir * (real_t)5.0, land)).first;
			Dictionary treatment = cached->second.duplicate();
			const bool hard = String(treatment["kind"]) == "hard";
			double top_a = hard ? bank_top(start, land) : dry_height(start);
			double top_b = hard ? bank_top(end, land) : dry_height(end);
			if (hard) {
				const double road_top = abutment_top(treatment, mid);
				if (!std::isnan(road_top)) {
					// A bridge abutment's top is the road's level at the bridge's end.
					top_a = road_top;
					top_b = road_top;
				}
			}
			if (hard && (std::isnan(top_a) || std::isnan(top_b))) {
				treatment = Dictionary();
				treatment["kind"] = "natural";
				treatment["reason"] = "insufficient_dry_samples";
				treatment["sources"] = Array();
			}
			if (std::isnan(top_a)) top_a = dry_height(start);
			if (std::isnan(top_b)) top_b = dry_height(end);
			treatment["a"] = start;
			treatment["b"] = end;
			treatment["land"] = land;
			treatment["body"] = body;
			treatment["top_a"] = top_a;
			treatment["top_b"] = top_b;
			treatment["water_a"] = level(body, start);
			treatment["water_b"] = level(body, end);
			const int segment_id = (int)segments.size();
			segments.push_back(treatment);
			const Vector2i lo = cell_at(start.min(end) - pad), hi = cell_at(start.max(end) + pad);
			for (int x = lo.x; x <= hi.x; ++x) {
				for (int z = lo.y; z <= hi.y; ++z) {
					const Vector2i cell(x, z);
					if (!cells.has(cell)) cells[cell] = Array();
					Array ids = cells[cell];
					ids.push_back(segment_id);
				}
			}
			if (String(treatment["kind"]) == "hard") {
				endpoint_tops[start].push_back(top_a);
				endpoint_tops[end].push_back(top_b);
			}
			// The raw edge keeps its resolved segments for local height lookup.
			if (!edge.has("segments")) edge["segments"] = Array();
			Array own = edge["segments"];
			own.push_back(segment_id);
		}
	}
	for (int64_t s = 0; s < segments.size(); ++s) {
		Dictionary segment = segments[s];
		if (String(segment["kind"]) != "hard") continue;
		for (int end = 0; end < 2; ++end) {
			const std::vector<double> &values = endpoint_tops[(Vector2)segment[end == 0 ? "a" : "b"]];
			double sum = 0.0;
			for (double v : values) sum += v;
			segment[end == 0 ? "top_a" : "top_b"] = sum / (double)values.size();
		}
	}
	result["segments"] = segments;
	result["cells"] = cells;
	result["diagnostics"] = diagnostics;
	return result;
}

void ShoreClassifier::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "dry", "size", "step", "origin", "bounds", "domain_bounds", "domains", "levels",
			"evidence", "abutment_ends", "m2u"), &ShoreClassifier::setup);
	ClassDB::bind_method(D_METHOD("classify", "edges", "abort"), &ShoreClassifier::classify);
}

} // namespace godot
