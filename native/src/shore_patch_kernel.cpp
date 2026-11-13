#include "shore_patch_kernel.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <algorithm>
#include <cmath>
#include <cstring>

namespace godot {
size_t ShorePatchKernel::Hash::operator()(const Vector3i &p) const {
	size_t h = std::hash<int>{}(p.x);
	for (int v : {p.y, p.z}) h ^= std::hash<int>{}(v) + 0x9e3779b9 + (h << 6) + (h >> 2);
	return h;
}
double ShorePatchKernel::Level::at(Vector2 p) const {
	if (!profile) return start;
	const Vector2 d = b - a;
	const double t = std::clamp((double)(p - a).dot(d) / std::max((double)d.length_squared(), 0.0001), 0.0, 1.0);
	return Math::lerp(start, end, t);
}
void ShorePatchKernel::setup(const PackedFloat32Array &p_base, const PackedFloat32Array &p_land, const Array &p_bodies,
		const Array &segments, const Vector4 &grid, const Ref<ShoreSampler> &p_sampler,
		const Ref<ShoreDomainIndex> &p_domains, const Ref<ShoreEvidenceIndex> &p_evidence) {
	base = p_base; land = p_land; size = (int)grid.x; step = grid.y; origin = grid.z; depth = grid.w;
	sampler = p_sampler; domains = p_domains; evidence = p_evidence;
	levels.clear(); banks.clear(); heights.clear();
	for (int64_t i = 0; i < p_bodies.size(); ++i) {
		Dictionary body = p_bodies[i]; Level level;
		level.start = body["level"]; level.end = body.get("level_end", level.start); level.profile = body.has("level_end");
		if (level.profile) { PackedVector2Array axis = body["axis"]; level.a = axis[0]; level.b = axis[1]; }
		levels.push_back(level);
	}
	for (int64_t i = 0; i < segments.size(); ++i) {
		Dictionary s = segments[i];
		banks.push_back({s["a"], s["b"], s["top_a"], s["top_b"], s["body"], String(s["kind"]) == "hard"});
	}
}
double ShorePatchKernel::grid_height(const PackedFloat32Array &values, Vector2 p) const {
	const Vector2 f = ((p - Vector2(origin, origin)) / (real_t)step).clamp(Vector2(), Vector2(size - 1, size - 1));
	const int x = std::min((int)f.x, size - 2), z = std::min((int)f.y, size - 2), k = z * size + x;
	const double tx = (double)f.x - x, tz = (double)f.y - z;
	return Math::lerp(Math::lerp((double)values[k], (double)values[k + 1], tx),
		Math::lerp((double)values[k + size], (double)values[k + size + 1], tx), tz);
}
double ShorePatchKernel::vertex_height(Vector2 p, int owner, bool hard) {
	const Vector3i key((int)Math::round((double)p.x * 100), (int)Math::round((double)p.y * 100), hard ? -2 : owner);
	const auto cached = heights.find(key);
	if (cached != heights.end()) return cached->second;
	double h;
	if (owner >= 0) h = std::min(grid_height(base, p), levels[owner].at(p) - depth);
	else {
		h = grid_height(land, p);
		const Vector4 near = sampler->nearest_bank(p, hard ? 1 : 2);
		if (near.x >= 0 && near.w < step) {
			const Bank &bank = banks[(int)near.x]; const Vector2 d = bank.b - bank.a;
			const double t = std::clamp((double)(Vector2(near.y, near.z) - bank.a).dot(d) / std::max((double)d.length_squared(), 0.0001), 0.0, 1.0);
			const double rim = bank.hard ? Math::lerp(bank.top_a, bank.top_b, t) : levels[bank.body].at(p);
			h = Math::lerp(rim, h, std::clamp((double)near.w / step, 0.0, 1.0));
		}
	}
	heights[key] = h;
	return h;
}
Dictionary ShorePatchKernel::build(const Array &pieces) {
	std::vector<Vector3> vertices;
	std::vector<int32_t> owners;
	std::vector<uint8_t> hard_regions, paving;
	double area = 0;
	const Vector2 lo(origin + 0.001, origin + 0.001), hi(origin + step * (size - 1) - 0.001, origin + step * (size - 1) - 0.001);
	for (int64_t n = 0; n < pieces.size(); ++n) {
		const PackedVector2Array ring = pieces[n];
		Vector2 centre;
		for (int64_t i = 0; i < ring.size(); ++i) centre += ring[i];
		centre /= (real_t)std::max((int64_t)1, ring.size());
		const int owner = domains->at(centre.clamp(lo, hi));
		const Vector4 near = sampler->nearest_bank(centre);
		const bool hard = owner < 0 && near.x >= 0 && banks[(int)near.x].hard;
		const bool natural = hard && evidence.is_valid() && evidence->contains_code(centre, ShoreEvidenceIndex::NATURAL);
		for (int64_t i = 1; i + 1 < ring.size(); ++i) {
			const double tri_area = std::abs((double)(ring[i] - ring[0]).cross(ring[i + 1] - ring[0])) * 0.5;
			if (tri_area < 0.00001) continue;
			area += tri_area; owners.push_back(owner); hard_regions.push_back(hard ? 1 : 0); paving.push_back(hard && !natural ? 1 : 0);
			for (const Vector2 &p : {ring[0], ring[i], ring[i + 1]}) vertices.emplace_back(p.x, vertex_height(p, owner, hard), p.y);
		}
	}
	PackedVector3Array v; v.resize(vertices.size()); if (!vertices.empty()) std::memcpy(v.ptrw(), vertices.data(), vertices.size() * sizeof(Vector3));
	PackedInt32Array o; o.resize(owners.size()); if (!owners.empty()) std::memcpy(o.ptrw(), owners.data(), owners.size() * sizeof(int32_t));
	PackedByteArray h, p; h.resize(hard_regions.size()); p.resize(paving.size());
	if (!hard_regions.empty()) { std::memcpy(h.ptrw(), hard_regions.data(), hard_regions.size()); std::memcpy(p.ptrw(), paving.data(), paving.size()); }
	Dictionary out; out["triangles"] = v; out["owners"] = o; out["hard"] = h; out["paving"] = p; out["area"] = area;
	return out;
}
void ShorePatchKernel::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "base", "land", "bodies", "segments", "grid", "sampler", "domains", "evidence"), &ShorePatchKernel::setup);
	ClassDB::bind_method(D_METHOD("build", "pieces"), &ShorePatchKernel::build);
}
}
