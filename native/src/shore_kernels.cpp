#include "shore_kernels.h"
#include "segments.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <unordered_set>

namespace godot {
namespace {
constexpr double eps = 0.00001;
struct Edge { Vector2 a, b; };
Vector2 snap(Vector2 p) {
	return Vector2(Math::snapped(p.x, (real_t)0.01), Math::snapped(p.y, (real_t)0.01));
}
double line_y(const Edge &e, double x) {
	return (double)e.a.y + ((double)e.b.y - (double)e.a.y) * (x - (double)e.a.x) / ((double)e.b.x - (double)e.a.x);
}
double cross(double ax, double ay, double bx, double by) { return ax * by - ay * bx; }
bool clip(Vector2 a, Vector2 b, const Rect2 &box, Edge &out) {
	const Vector2 d = b - a;
	double lo = 0.0, hi = 1.0;
	for (int axis = 0; axis < 2; ++axis) {
		if (std::abs((double)d[axis]) < eps) {
			if (a[axis] < box.position[axis] - eps || a[axis] > box.get_end()[axis] + eps) return false;
		} else {
			const double t0 = (box.position[axis] - a[axis]) / d[axis];
			const double t1 = (box.get_end()[axis] - a[axis]) / d[axis];
			lo = std::max(lo, std::min(t0, t1));
			hi = std::min(hi, std::max(t0, t1));
		}
		if (lo > hi) return false;
	}
	if ((hi - lo) * d.length() < eps) return false;
	out = {snap(a + d * (real_t)lo), snap(a + d * (real_t)hi)};
	return true;
}
} // namespace

Array ShoreKernels::partition(const Rect2 &box, const Array &segments) {
	std::vector<Edge> edges;
	std::vector<double> xs = {box.position.x, box.get_end().x};
	for (int64_t i = 0; i < segments.size(); ++i) {
		Array segment = segments[i];
		Edge e;
		if (clip(segment[0], segment[1], box, e)) {
			edges.push_back(e);
			xs.push_back(e.a.x); xs.push_back(e.b.x);
		}
	}
	for (size_t i = 0; i < edges.size(); ++i) {
		for (size_t j = i + 1; j < edges.size(); ++j) {
			Vector2 hit;
			if (segments_cross(edges[i].a, edges[i].b, edges[j].a, edges[j].b, hit)) xs.push_back(snap(hit).x);
		}
	}
	std::sort(xs.begin(), xs.end());
	std::vector<double> unique;
	for (double x : xs) {
		x = std::clamp(x, (double)box.position.x, (double)box.get_end().x);
		if (unique.empty() || x - unique.back() > eps) unique.push_back(x);
	}
	Array out;
	for (size_t i = 0; i + 1 < unique.size(); ++i) {
		const double left = unique[i], right = unique[i + 1], mid = (left + right) * 0.5;
		std::vector<Edge> active = {{box.position, Vector2(box.get_end().x, box.position.y)},
			{Vector2(box.position.x, box.get_end().y), box.get_end()}};
		for (const Edge &e : edges) {
			if (mid > std::min(e.a.x, e.b.x) && mid < std::max(e.a.x, e.b.x)) active.push_back(e);
		}
		std::sort(active.begin(), active.end(), [mid](const Edge &a, const Edge &b) { return line_y(a, mid) < line_y(b, mid); });
		for (size_t j = 0; j + 1 < active.size(); ++j) {
			if (line_y(active[j + 1], mid) - line_y(active[j], mid) < eps) continue;
			Vector2 corners[] = {Vector2(left, line_y(active[j], left)), Vector2(right, line_y(active[j], right)),
				Vector2(right, line_y(active[j + 1], right)), Vector2(left, line_y(active[j + 1], left))};
			PackedVector2Array ring;
			for (const Vector2 &p : corners) {
				const Vector2 q = snap(p);
				if (ring.is_empty() || q.distance_squared_to(ring[ring.size() - 1]) > eps * eps) ring.push_back(q);
			}
			if (ring.size() > 2 && ring[0].distance_squared_to(ring[ring.size() - 1]) < eps * eps) ring.resize(ring.size() - 1);
			double area = 0.0;
			for (int64_t k = 0; k < ring.size(); ++k) area += (double)ring[k].cross(ring[(k + 1) % ring.size()]);
			if (ring.size() >= 3 && std::abs(area) > eps * 2.0) out.push_back(ring);
		}
	}
	return out;
}

void ShoreSampler::setup(const PackedFloat32Array &p_surface, const Dictionary &p_patches, int p_size, double p_step, double p_origin) {
	size = p_size; step = p_step; origin = p_origin;
	surface.resize(p_surface.size());
	if (!surface.empty()) std::memcpy(surface.data(), p_surface.ptr(), surface.size() * sizeof(float));
	y_range = Vector2(INFINITY, -INFINITY);
	for (float y : surface) { y_range.x = std::min(y_range.x, y); y_range.y = std::max(y_range.y, y); }
	patches.clear(); patch_cells.clear(); dry_patches.clear();
	const Array keys = p_patches.keys();
	for (int64_t i = 0; i < keys.size(); ++i) {
		const Vector2i key = keys[i];
		const Dictionary patch = p_patches[keys[i]];
		const PackedVector3Array triangles = patch["triangles"];
		for (int64_t j = 0; j < triangles.size(); ++j) {
			y_range.x = std::min(y_range.x, triangles[j].y); y_range.y = std::max(y_range.y, triangles[j].y);
		}
		const int64_t cell = (int64_t)key.y * size + key.x;
		patches[cell] = std::vector<Vector3>(triangles.ptr(), triangles.ptr() + triangles.size());
		auto &buckets = patch_cells[cell];
		const double cell_x = origin + key.x * step, cell_z = origin + key.y * step;
		const double pad = step * 0.0003 + 0.01;
		for (int64_t j = 0; j + 2 < triangles.size(); j += 3) {
			const Vector3 a = triangles[j], b = triangles[j + 1], c = triangles[j + 2];
			const int x0 = std::clamp((int)std::floor((std::min({a.x, b.x, c.x}) - pad - cell_x) * 4 / step), 0, 3);
			const int x1 = std::clamp((int)std::floor((std::max({a.x, b.x, c.x}) + pad - cell_x) * 4 / step), 0, 3);
			const int z0 = std::clamp((int)std::floor((std::min({a.z, b.z, c.z}) - pad - cell_z) * 4 / step), 0, 3);
			const int z1 = std::clamp((int)std::floor((std::max({a.z, b.z, c.z}) + pad - cell_z) * 4 / step), 0, 3);
			for (int z = z0; z <= z1; ++z) for (int x = x0; x <= x1; ++x) buckets[z * 4 + x].push_back((int)j);
		}
		const PackedInt32Array owners = patch["owners"];
		auto &dry = dry_patches[cell];
		for (int64_t j = 0; j < owners.size(); ++j) if (owners[j] < 0) for (int k = 0; k < 3; ++k) dry.push_back(triangles[j * 3 + k]);
	}
}

double ShoreSampler::height(double x, double z) const {
	const int cx = std::clamp((int)std::floor((x - origin) / step), 0, size - 2), cz = std::clamp((int)std::floor((z - origin) / step), 0, size - 2);
	// Exact cell-edge queries must see the land-side triangles in the
	// adjacent patch as well as the submerged bed in the current cell.
	const double gx = (x - origin) / step, gz = (z - origin) / step;
	const int rx = (int)std::round(gx), rz = (int)std::round(gz);
	const bool edge_x = std::abs(x - (origin + rx * step)) <= 0.006;
	const bool edge_z = std::abs(z - (origin + rz * step)) <= 0.006;
	const int x0 = edge_x ? std::max(0, rx - 1) : cx, x1 = edge_x ? std::min(size - 2, rx) : cx;
	const int z0 = edge_z ? std::max(0, rz - 1) : cz, z1 = edge_z ? std::min(size - 2, rz) : cz;
	double best = -INFINITY;
	for (int iz = z0; iz <= z1; ++iz) for (int ix = x0; ix <= x1; ++ix) {
		const auto patch = patches.find((int64_t)iz * size + ix);
		if (patch == patches.end()) continue;
		const auto &triangles = patch->second;
		const int bx = std::clamp((int)std::floor((x - origin - ix * step) * 4 / step), 0, 3);
		const int bz = std::clamp((int)std::floor((z - origin - iz * step) * 4 / step), 0, 3);
		const auto &candidates = patch_cells.at((int64_t)iz * size + ix)[bz * 4 + bx];
		for (int i : candidates) {
			const Vector3 a = triangles[i], b = triangles[i + 1], c = triangles[i + 2];
			const double det = cross(b.x - a.x, b.z - a.z, c.x - a.x, c.z - a.z);
			if (std::abs(det) < eps) continue;
			const double u = cross(x - a.x, z - a.z, c.x - a.x, c.z - a.z) / det;
			const double v = cross(b.x - a.x, b.z - a.z, x - a.x, z - a.z) / det;
			if (u >= -0.0001 && v >= -0.0001 && u + v <= 1.0001) best = std::max(best, a.y + u * (b.y - a.y) + v * (c.y - a.y));
		}
	}
	if (std::isfinite(best)) return best;
	if (size < 2 || surface.size() != (size_t)size * size) return 0.0;
	const double fx = std::clamp((x - origin) / step, 0.0, (double)size - 1);
	const double fz = std::clamp((z - origin) / step, 0.0, (double)size - 1);
	const int ix = std::min((int)fx, size - 2), iz = std::min((int)fz, size - 2);
	const double tx = fx - ix, tz = fz - iz;
	const double a = surface[iz * size + ix] + tx * (surface[iz * size + ix + 1] - surface[iz * size + ix]);
	const double b = surface[(iz + 1) * size + ix] + tx * (surface[(iz + 1) * size + ix + 1] - surface[(iz + 1) * size + ix]);
	return a + tz * (b - a);
}

PackedFloat32Array ShoreSampler::grid_heights() const {
	PackedFloat32Array out;
	if (size < 2) return out;
	out.resize((int64_t)size * size);
	float *values = out.ptrw();
	const Vector2 lo(origin, origin), hi = lo + Vector2(1, 1) * (real_t)step * (real_t)(size - 1);
	for (int z = 0; z < size; ++z) for (int x = 0; x < size; ++x) {
		const Vector2 p = Vector2(((double)x - size * 0.5) * step, ((double)z - size * 0.5) * step).clamp(lo, hi);
		values[(int64_t)z * size + x] = (float)height(p.x, p.y);
	}
	return out;
}

const std::vector<Vector3> *ShoreSampler::dry_triangles(double x, double z) const {
	const int cx = (int)std::floor((x - origin) / step), cz = (int)std::floor((z - origin) / step);
	const auto found = dry_patches.find((int64_t)cz * size + cx);
	return found == dry_patches.end() ? nullptr : &found->second;
}
Vector2 ShoreSampler::height_range() const { return y_range; }

void ShoreSampler::setup_banks(const Array &segments) {
	banks.clear(); bank_cells.clear();
	for (int64_t i = 0; i < segments.size(); ++i) {
		const Dictionary s = segments[i];
		const Vector2 a = s["a"], b = s["b"];
		banks.push_back({a, b, String(s.get("kind", "natural")) == "hard"});
		const int x0 = (int)std::floor((std::min(a.x, b.x) - origin - 0.01) / step);
		const int x1 = (int)std::floor((std::max(a.x, b.x) - origin + 0.01) / step);
		const int z0 = (int)std::floor((std::min(a.y, b.y) - origin - 0.01) / step);
		const int z1 = (int)std::floor((std::max(a.y, b.y) - origin + 0.01) / step);
		for (int z = z0; z <= z1; ++z) for (int x = x0; x <= x1; ++x) bank_cells[(int64_t)z * size + x].push_back((int)i);
	}
}

Vector4 ShoreSampler::nearest_bank(const Vector2 &p, int treatment) const {
	const int cx = (int)std::floor((p.x - origin) / step), cz = (int)std::floor((p.y - origin) / step);
	double best = INFINITY;
	bool best_hard = false;
	Vector4 result(-1, 0, 0, INFINITY);
	std::unordered_set<int> seen;
	for (int z = cz - 1; z <= cz + 1; ++z) for (int x = cx - 1; x <= cx + 1; ++x) {
		const auto cell = bank_cells.find((int64_t)z * size + x);
		if (cell == bank_cells.end()) continue;
		for (int id : cell->second) {
			if (!seen.insert(id).second) continue;
			const Bank &b = banks[id];
			if ((treatment == 1 && !b.hard) || (treatment == 2 && b.hard)) continue;
			const Vector2 d = b.b - b.a;
			const double t = std::clamp((double)(p - b.a).dot(d) / std::max((double)d.length_squared(), 0.0001), 0.0, 1.0);
			const Vector2 q = b.a + d * (real_t)t;
			const double distance = p.distance_to(q);
			if (distance < best - 0.00001 || (std::abs(distance - best) <= 0.00001 && b.hard && !best_hard)) {
				best = distance; best_hard = b.hard; result = Vector4((real_t)id, q.x, q.y, (real_t)distance);
			}
		}
	}
	return result;
}

namespace {
int64_t domain_key(int x, int z) { return (int64_t)((uint64_t)(uint32_t)x << 32 | (uint32_t)z); }
}
void ShoreDomainIndex::setup(const Array &bodies, const Dictionary &p_cells) {
	polygons.clear(); cells.clear();
	for (int64_t i = 0; i < bodies.size(); ++i) {
		Dictionary body = bodies[i];
		Object *index = body["index"];
		polygons.push_back(far::read_poly(index));
	}
	const Array keys = p_cells.keys();
	for (int64_t i = 0; i < keys.size(); ++i) {
		Vector2i p = keys[i];
		Array entries = p_cells[keys[i]];
		auto &cell = cells[domain_key(p.x, p.y)];
		for (int64_t j = 0; j < entries.size(); ++j) cell.push_back((int)entries[j]);
	}
}
void ShoreDomainIndex::setup_polygons(const Array &indices, const Rect2 &bounds) {
	polygons.clear(); cells.clear();
	for (int64_t i = 0; i < indices.size(); ++i) {
		Object *index = indices[i];
		polygons.push_back(far::read_poly(index));
		const Rect2 box = polygons.back().box.intersection(bounds);
		if (!box.has_area()) continue;
		for (int z = (int)std::floor(box.position.y / 64.0); z <= (int)std::floor(box.get_end().y / 64.0); ++z)
			for (int x = (int)std::floor(box.position.x / 64.0); x <= (int)std::floor(box.get_end().x / 64.0); ++x) cells[domain_key(x, z)].push_back((int)i);
	}
}
int ShoreDomainIndex::at(const Vector2 &p, int exclude) const {
	const auto cell = cells.find(domain_key((int)std::floor(p.x / 64.0), (int)std::floor(p.y / 64.0)));
	if (cell == cells.end()) return -1;
	for (int id : cell->second) if (id != exclude && polygons[id].contains(p)) return id;
	return -1;
}

Array ShoreDomainIndex::outside_runs(const Vector2 &a, const Vector2 &b) const {
	std::vector<double> cuts = {0.0, 1.0};
	const Vector2 d = b - a;
	const double length = d.length_squared();
	Array out;
	if (length < eps) return out;
	const Vector2 lo(std::min(a.x, b.x), std::min(a.y, b.y)), hi(std::max(a.x, b.x), std::max(a.y, b.y));
	std::unordered_set<int> candidates;
	for (int z = (int)std::floor(lo.y / 64.0); z <= (int)std::floor(hi.y / 64.0); ++z) {
		for (int x = (int)std::floor(lo.x / 64.0); x <= (int)std::floor(hi.x / 64.0); ++x) {
			const auto cell = cells.find(domain_key(x, z));
			if (cell != cells.end()) candidates.insert(cell->second.begin(), cell->second.end());
		}
	}
	for (int id : candidates) {
		for (const auto &ring : polygons[id].rings) for (int64_t i = 0; i < ring.size(); ++i) {
			const Vector2 c = ring[i], e = ring[(i + 1) % ring.size()];
			if (std::max(c.x, e.x) < lo.x || std::min(c.x, e.x) > hi.x || std::max(c.y, e.y) < lo.y || std::min(c.y, e.y) > hi.y) continue;
			Vector2 hit;
			if (segments_cross(a, b, c, e, hit)) cuts.push_back(std::clamp((double)(hit - a).dot(d) / length, 0.0, 1.0));
		}
	}
	std::sort(cuts.begin(), cuts.end());
	for (size_t i = 0; i + 1 < cuts.size(); ++i) {
		if (cuts[i + 1] - cuts[i] < 1e-7 || at(a + d * (real_t)((cuts[i] + cuts[i + 1]) * 0.5)) >= 0) continue;
		PackedVector2Array line; line.push_back(a + d * (real_t)cuts[i]); line.push_back(a + d * (real_t)cuts[i + 1]); out.push_back(line);
	}
	return out;
}

void ShoreKernels::_bind_methods() {
	ClassDB::bind_static_method("ShoreKernels", D_METHOD("partition", "box", "segments"), &ShoreKernels::partition);
}
void ShoreSampler::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "surface", "patches", "size", "step", "origin"), &ShoreSampler::setup);
	ClassDB::bind_method(D_METHOD("height", "x", "z"), &ShoreSampler::height);
	ClassDB::bind_method(D_METHOD("grid_heights"), &ShoreSampler::grid_heights);
	ClassDB::bind_method(D_METHOD("height_range"), &ShoreSampler::height_range);
	ClassDB::bind_method(D_METHOD("setup_banks", "segments"), &ShoreSampler::setup_banks);
	ClassDB::bind_method(D_METHOD("nearest_bank", "point", "treatment"), &ShoreSampler::nearest_bank, DEFVAL(0));
}
void ShoreDomainIndex::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "bodies", "cells"), &ShoreDomainIndex::setup);
	ClassDB::bind_method(D_METHOD("setup_polygons", "indices", "bounds"), &ShoreDomainIndex::setup_polygons);
	ClassDB::bind_method(D_METHOD("at", "point", "exclude"), &ShoreDomainIndex::at, DEFVAL(-1));
	ClassDB::bind_method(D_METHOD("outside_runs", "a", "b"), &ShoreDomainIndex::outside_runs);
}
} // namespace godot
