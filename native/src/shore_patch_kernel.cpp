#include "shore_patch_kernel.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <atomic>
#include <memory>
#include <mutex>
#include <vector>
#include "parallel.h"

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
	levels.clear(); banks.clear(); quays.clear(); heights.clear();
	for (int64_t i = 0; i < p_bodies.size(); ++i) {
		Dictionary body = p_bodies[i]; Level level;
		level.start = body["level"]; level.end = body.get("level_end", level.start); level.profile = body.has("level_end");
		if (level.profile) { PackedVector2Array axis = body["axis"]; level.a = axis[0]; level.b = axis[1]; }
		levels.push_back(level);
	}
	for (int64_t i = 0; i < segments.size(); ++i) {
		Dictionary s = segments[i];
		// A low quay's wall (ShorelineModel.quays) or a bridge's abutment: its street keeps its own class.
		bool quay = false;
		const Array sources = s.get("sources", Array());
		for (int64_t k = 0; k < sources.size(); ++k) quay = quay || String(sources[k]).begins_with("quay:") || String(sources[k]).begins_with("abutment:");
		banks.push_back({s["a"], s["b"], s["top_a"], s["top_b"], s["body"], String(s["kind"]) == "hard", quay});
	}
}
void ShorePatchKernel::setup_quays(const Array &p_quays, double p_pave_reach) {
	pave_reach = p_pave_reach;
	quays.clear(); heights.clear();
	for (int64_t i = 0; i < p_quays.size(); ++i) {
		const Dictionary q = p_quays[i];
		Quay quay;
		quay.ring = q["ring"]; quay.body = q["body"]; quay.low = q["low"];
		if (quay.ring.is_empty()) continue;
		quay.box = Rect2(quay.ring[0], Vector2());
		for (int64_t k = 1; k < quay.ring.size(); ++k) quay.box = quay.box.expand(quay.ring[k]);
		quays.push_back(quay);
	}
}
int ShorePatchKernel::quay_at(Vector2 p) const {
	for (size_t i = 0; i < quays.size(); ++i) {
		const Quay &q = quays[i];
		if (!q.box.has_point(p)) continue;
		// Geometry2D.is_point_in_polygon: even-odd crossings.
		bool inside = false;
		const int64_t n = q.ring.size();
		for (int64_t a = 0, b = n - 1; a < n; b = a++) {
			const Vector2 pa = q.ring[a], pb = q.ring[b];
			if ((pa.y > p.y) != (pb.y > p.y) && p.x < (pb.x - pa.x) * (p.y - pa.y) / (pb.y - pa.y) + pa.x) inside = !inside;
		}
		if (inside) return (int)i;
	}
	return -1;
}
double ShorePatchKernel::quay_height(Vector2 p, int quay, Heights &memo) const {
	const Vector3i key((int)Math::round((double)p.x * 100), (int)Math::round((double)p.y * 100), -3 - quay);
	const auto cached = memo.find(key);
	if (cached != memo.end()) return cached->second;
	const Quay &q = quays[quay];
	double h = levels[q.body].at(p) + q.low;
	const Vector4 near = sampler->nearest_bank(p, 2);
	if (near.x >= 0 && near.w < step)
		h = Math::lerp(levels[banks[(int)near.x].body].at(p), h, std::clamp((double)near.w / step, 0.0, 1.0));
	memo[key] = h;
	return h;
}
double ShorePatchKernel::grid_height(const PackedFloat32Array &values, Vector2 p) const {
	const Vector2 f = ((p - Vector2(origin, origin)) / (real_t)step).clamp(Vector2(), Vector2(size - 1, size - 1));
	const int x = std::min((int)f.x, size - 2), z = std::min((int)f.y, size - 2), k = z * size + x;
	const double tx = (double)f.x - x, tz = (double)f.y - z;
	return Math::lerp(Math::lerp((double)values[k], (double)values[k + 1], tx),
		Math::lerp((double)values[k + size], (double)values[k + size + 1], tx), tz);
}
double ShorePatchKernel::vertex_height(Vector2 p, int owner, bool hard, Heights &heights) const {
	const Vector3i key((int)Math::round((double)p.x * 100), (int)Math::round((double)p.y * 100), hard ? -2 : owner);
	const auto cached = heights.find(key);
	if (cached != heights.end()) return cached->second;
	double h;
	if (owner >= 0) h = std::min(grid_height(base, p), levels[owner].at(p) - depth);
	else {
		h = grid_height(land, p);
		const Vector4 near = sampler->nearest_bank(p, hard ? 1 : 2);
		if (near.x >= 0) {
			const Bank &bank = banks[(int)near.x];
			const double reach = bank.hard ? (double)step : std::min((double)step, 3.0);
			if (near.w < reach) {
				const Vector2 d = bank.b - bank.a;
				const double t = std::clamp((double)(Vector2(near.y, near.z) - bank.a).dot(d) / std::max((double)d.length_squared(), 0.0001), 0.0, 1.0);
				const double rim = bank.hard ? Math::lerp(bank.top_a, bank.top_b, t) : levels[bank.body].at(p);
				const double w = bank.hard ? std::clamp((double)near.w / reach, 0.0, 1.0) : Math::smoothstep(0.0, reach, (double)near.w);
				h = Math::lerp(rim, h, w);
			}
		}
	}
	heights[key] = h;
	return h;
}
Dictionary ShorePatchKernel::build(const Array &pieces) {
	return build_with(pieces, heights);
}
Dictionary ShorePatchKernel::build_with(const Array &pieces, Heights &memo) const {
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
		const int quay = owner < 0 ? quay_at(centre) : -1;
		const bool street_of_quay = hard && near.x >= 0 && banks[(int)near.x].quay;
		const bool natural = (hard || quay >= 0) && evidence.is_valid() && evidence->contains_code(centre, ShoreEvidenceIndex::NATURAL);
		for (int64_t i = 1; i + 1 < ring.size(); ++i) {
			const double tri_area = std::abs((double)(ring[i] - ring[0]).cross(ring[i + 1] - ring[0])) * 0.5;
			if (tri_area < 0.00001) continue;
			// 2: a low quay's walk (ShoreMesh.stitch keeps it apart from the street).
			area += tri_area; owners.push_back(owner); hard_regions.push_back(quay >= 0 ? 2 : hard ? 1 : 0);
			// ShoreSurface.HARD_PAVING_M: forced only near the wall.
			const bool pave_hard = hard && !street_of_quay && near.w <= pave_reach;
			paving.push_back((quay >= 0 || pave_hard) && !natural ? 1 : 0);
			for (const Vector2 &p : {ring[0], ring[i], ring[i + 1]})
				vertices.emplace_back(p.x, quay >= 0 ? quay_height(p, quay, memo) : vertex_height(p, owner, hard, memo), p.y);
		}
	}
	PackedVector3Array v; v.resize(vertices.size()); if (!vertices.empty()) std::memcpy(v.ptrw(), vertices.data(), vertices.size() * sizeof(Vector3));
	PackedInt32Array o; o.resize(owners.size()); if (!owners.empty()) std::memcpy(o.ptrw(), owners.data(), owners.size() * sizeof(int32_t));
	PackedByteArray h, p; h.resize(hard_regions.size()); p.resize(paving.size());
	if (!hard_regions.empty()) { std::memcpy(h.ptrw(), hard_regions.data(), hard_regions.size()); std::memcpy(p.ptrw(), paving.data(), paving.size()); }
	Dictionary out; out["triangles"] = v; out["owners"] = o; out["hard"] = h; out["paving"] = p; out["area"] = area;
	return out;
}
namespace {
// ShoreGeometry.snap.
Vector2 snap_cm(const Vector2 &p) {
	return Vector2(Math::snapped(p.x, (real_t)0.01), Math::snapped(p.y, (real_t)0.01));
}
// ShoreGeometry.clip_segment, its parameters in doubles as the script's.
bool clip_segment(const Vector2 &a, const Vector2 &b, const Rect2 &box, Vector2 &ca, Vector2 &cb) {
	const double eps = 0.00001;
	const Vector2 d = b - a;
	double lo = 0.0, hi = 1.0;
	for (int axis = 0; axis < 2; ++axis) {
		const double da = d[axis], aa = a[axis], lo_edge = box.position[axis], hi_edge = box.get_end()[axis];
		if (std::abs(da) < eps) {
			if (aa < lo_edge - eps || aa > hi_edge + eps) return false;
		} else {
			const double t0 = (lo_edge - aa) / da, t1 = (hi_edge - aa) / da;
			const double near_t = t0 < t1 ? t0 : t1, far_t = t0 > t1 ? t0 : t1;
			lo = lo > near_t ? lo : near_t;
			hi = hi < far_t ? hi : far_t;
		}
		if (lo > hi) return false;
	}
	if ((hi - lo) * (double)d.length() < eps) return false;
	ca = snap_cm(a + d * (real_t)lo);
	cb = snap_cm(a + d * (real_t)hi);
	return true;
}
double area_of(const PackedVector2Array &ring) {
	double a = 0.0;
	for (int64_t i = 0; i < ring.size(); ++i) {
		const Vector2 p = ring[i], q = ring[(i + 1) % ring.size()];
		a += (double)p.x * (double)q.y - (double)q.x * (double)p.y;
	}
	return a * 0.5;
}
} // namespace

Array ShorePatchKernel::cell(const Vector2i &key, const Dictionary &edge_cells, const Dictionary &transition_cells,
		const Array &edges, const Array &transition_edges, Heights &memo) const {
	const Vector2 corner = Vector2(1, 1) * (real_t)origin;
	// ShorelineModel.cell_box.
	const Vector2 a0 = snap_cm(corner + Vector2(key) * (real_t)step);
	const Vector2 b0 = snap_cm(corner + Vector2(key + Vector2i(1, 1)) * (real_t)step);
	const Rect2 box(a0, b0 - a0);
	Array cut_edges;
	const Array transitions = transition_cells.get(key, Array());
	for (int64_t t = 0; t < transitions.size(); ++t) cut_edges.push_back(transition_edges[(int64_t)transitions[t]]);
	const Array raw_ids = edge_cells.get(key, Array());
	for (int64_t r = 0; r < raw_ids.size(); ++r) {
		const Dictionary raw = edges[(int64_t)raw_ids[r]];
		const Vector2 a = raw["a"], b = raw["b"];
		const int count = std::max(1, (int)std::ceil((double)a.distance_to(b) / 2.0));
		Vector2 c0, c1;
		if (!clip_segment(a, b, box, c0, c1)) continue;
		const Vector2 d = b - a;
		const double len2 = d.length_squared();
		const int first = std::clamp((int)std::floor((double)(c0 - a).dot(d) / len2 * count), 0, count - 1);
		const int last = std::clamp((int)std::ceil((double)(c1 - a).dot(d) / len2 * count), first + 1, count);
		for (int i = first; i < last; ++i) {
			Array piece;
			piece.push_back(a.lerp(b, (real_t)((double)i / (double)count)));
			piece.push_back(a.lerp(b, (real_t)((double)(i + 1) / (double)count)));
			cut_edges.push_back(piece);
		}
	}
	for (int sub = 1; sub < 4; ++sub) {
		const real_t f = (real_t)sub / (real_t)4;
		const real_t sx = snap_cm(Vector2(Math::lerp(box.position.x, box.get_end().x, f), box.position.y)).x;
		const real_t sz = snap_cm(Vector2(box.position.x, Math::lerp(box.position.y, box.get_end().y, f))).y;
		Array vx; vx.push_back(Vector2(sx, box.position.y)); vx.push_back(Vector2(sx, box.get_end().y));
		Array hz; hz.push_back(Vector2(box.position.x, sz)); hz.push_back(Vector2(box.get_end().x, sz));
		cut_edges.push_back(vx);
		cut_edges.push_back(hz);
	}
	const double expected = box.get_area();
	const double tolerance = std::max(0.02, expected * 0.001);
	const Array pieces = ShoreKernels::partition(box, cut_edges);
	double coverage = 0.0;
	for (int64_t p = 0; p < pieces.size(); ++p) coverage += std::abs(area_of(pieces[p]));
	Array entry;
	entry.push_back(key);
	if (std::abs(coverage - expected) > tolerance) {
		entry.push_back(2);
		entry.push_back(cut_edges);
		return entry;
	}
	Dictionary patch = build_with(pieces, memo);
	const double area = patch["area"];
	patch.erase("area");
	if (std::abs(area - expected) > tolerance || PackedVector3Array(patch["triangles"]).is_empty()) {
		Dictionary diagnostic;
		diagnostic["kind"] = "patch_failure";
		diagnostic["cell"] = key;
		diagnostic["area"] = area;
		diagnostic["expected"] = expected;
		entry.push_back(1);
		entry.push_back(diagnostic);
	} else {
		entry.push_back(0);
		entry.push_back(patch);
	}
	return entry;
}

Array ShorePatchKernel::cells(const Array &keys, const Dictionary &edge_cells, const Dictionary &transition_cells,
		const Array &edges, const Array &transition_edges, Object *abort) {
	Array out;
	if (abort != nullptr && (bool)abort->get("requested")) return out;
	// Each cell on its own, every core; per-thread height memos, results
	// in key order.
	const int n = (int)keys.size();
	std::vector<Array> entries((size_t)n);
	std::vector<Vector2i> cell_keys((size_t)n);
	for (int k = 0; k < n; ++k) cell_keys[k] = keys[k];
	// A memo per worker thread for this call alone (the id is unique per
	// call, so a thread never reads a memo of an earlier call).
	static std::atomic<uint64_t> calls{ 0 };
	const uint64_t call = ++calls;
	std::mutex memo_lock;
	std::vector<std::unique_ptr<Heights>> memos;
	parallel_for(n, [&](int k) {
		thread_local Heights *memo = nullptr;
		thread_local uint64_t memo_call = 0;
		if (memo_call != call) {
			std::lock_guard<std::mutex> guard(memo_lock);
			memos.push_back(std::make_unique<Heights>());
			memo = memos.back().get();
			memo_call = call;
		}
		entries[k] = cell(cell_keys[k], edge_cells, transition_cells, edges, transition_edges, *memo);
	});
	if (abort != nullptr && (bool)abort->get("requested")) return out;
	for (int k = 0; k < n; ++k) out.push_back(entries[k]);
	return out;
}

void ShorePatchKernel::_bind_methods() {
	ClassDB::bind_method(D_METHOD("cells", "keys", "edge_cells", "transition_cells", "edges", "transition_edges", "abort"),
		&ShorePatchKernel::cells);
	ClassDB::bind_method(D_METHOD("setup", "base", "land", "bodies", "segments", "grid", "sampler", "domains", "evidence"), &ShorePatchKernel::setup);
	ClassDB::bind_method(D_METHOD("build", "pieces"), &ShorePatchKernel::build);
	ClassDB::bind_method(D_METHOD("setup_quays", "quays", "pave_reach"), &ShorePatchKernel::setup_quays);
}
}
