#include "shore_mesh.h"
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>
#include <unordered_map>

namespace godot {
namespace {
bool stopped(Object *abort) { return abort && (bool)abort->get("requested"); }
template<class Packed, class Value> Packed pack(const std::vector<Value> &v) {
	Packed out; out.resize(v.size());
	if (!v.empty()) std::memcpy(out.ptrw(), v.data(), v.size() * sizeof(Value));
	return out;
}
Vector2 snap(Vector2 p) { return p.snapped(Vector2(0.01f, 0.01f)); }
Rect2 box_at(Vector2i key, double step, double origin) {
	const Vector2 a = snap(Vector2(origin, origin) + Vector2(key.x, key.y) * (real_t)step);
	const Vector2 b = snap(Vector2(origin, origin) + Vector2(key.x + 1, key.y + 1) * (real_t)step);
	return Rect2(a, b - a);
}
struct Border {
	int axis, line, cell;
	bool operator==(const Border &b) const { return axis == b.axis && line == b.line && cell == b.cell; }
	bool operator<(const Border &b) const { return std::tie(axis, line, cell) < std::tie(b.axis, b.line, b.cell); }
};
std::vector<Border> borders(Vector3 p, Rect2 box, Vector2i key) {
	std::vector<Border> out;
	if (std::abs((double)p.x - box.position.x) < 0.005) out.push_back({0, key.x, key.y});
	if (std::abs((double)p.x - box.get_end().x) < 0.005) out.push_back({0, key.x + 1, key.y});
	if (std::abs((double)p.z - box.position.y) < 0.005) out.push_back({1, key.y, key.x});
	if (std::abs((double)p.z - box.get_end().y) < 0.005) out.push_back({1, key.y + 1, key.x});
	return out;
}
struct Patch {
	Vector2i key;
	PackedVector3Array points;
	PackedInt32Array owners;
	PackedByteArray hard, paving;
	int kind(int triangle) const { return owners[triangle] >= 0 ? 0 : hard[triangle] ? 2 : 1; }
};
std::vector<Patch> read_patches(const Dictionary &input) {
	std::vector<Patch> out;
	const Array keys = input.keys();
	for (int64_t i = 0; i < keys.size(); ++i) {
		Dictionary p = input[keys[i]];
		out.push_back({keys[i], p["triangles"], p["owners"], p["hard"], p["paving"]});
	}
	return out;
}
struct Body {
	double level, end;
	Vector2 a, b;
	bool axis, tidal, still;
	double at(Vector2 p) const {
		if (!axis) return level;
		const Vector2 d = b - a;
		const double t = std::clamp((double)(p - a).dot(d) / std::max((double)d.length_squared(), 0.0001), 0.0, 1.0);
		return Math::lerp(level, end, t);
	}
};
std::vector<Body> read_bodies(const Array &input) {
	std::vector<Body> out;
	for (int64_t i = 0; i < input.size(); ++i) {
		const Dictionary p = input[i]; Body b;
		b.level = p["level"]; b.end = p.get("level_end", b.level);
		b.axis = p.has("level_end"); b.tidal = p.get("tidal", false); b.still = p.get("still_pool", false);
		if (b.axis) { PackedVector2Array axis = p["axis"]; b.a = axis[0]; b.b = axis[1]; }
		out.push_back(b);
	}
	return out;
}
struct VHash {
	size_t operator()(const Vector4 &p) const {
		size_t h = std::hash<float>{}(p.x);
		for (float v : {p.y, p.z, p.w}) h ^= std::hash<float>{}(v) + 0x9e3779b9 + (h << 6) + (h >> 2);
		return h;
	}
};
struct IHash {
	size_t operator()(const Vector3i &p) const {
		size_t h = std::hash<int>{}(p.x);
		for (int v : {p.y, p.z}) h ^= std::hash<int>{}(v) + 0x9e3779b9 + (h << 6) + (h >> 2);
		return h;
	}
};
}

Dictionary ShoreMesh::stitch(const Dictionary &input, int size, double step, double origin, Object *abort) {
	const auto patches = read_patches(input);
	using Heights = std::array<double, 3>;
	std::map<Border, std::map<double, Heights>> bins;
	for (const Patch &p : patches) {
		if (stopped(abort)) return Dictionary();
		const Rect2 box = box_at(p.key, step, origin);
		for (int64_t i = 0; i < p.points.size(); ++i) {
			const Vector3 v = p.points[i];
			for (const Border &edge : borders(v, box, p.key)) {
				auto &positions = bins[edge];
				const double along = edge.axis == 0 ? v.z : v.x;
				auto it = positions.emplace(along, Heights{INFINITY, INFINITY, INFINITY}).first;
				const int kind = p.kind(i / 3);
				it->second[kind] = std::min(it->second[kind], (double)v.y);
			}
		}
	}
	Dictionary result;
	for (const Patch &p : patches) {
		if (stopped(abort)) return Dictionary();
		const Rect2 box = box_at(p.key, step, origin);
		std::vector<Vector3> vertices;
		std::vector<int32_t> owners;
		std::vector<uint8_t> hard, paving;
		auto append = [&](Vector3 a, Vector3 b, Vector3 c, int triangle) {
			vertices.insert(vertices.end(), {a, b, c});
			owners.push_back(p.owners[triangle]); hard.push_back(p.hard[triangle]); paving.push_back(p.paving[triangle]);
		};
		for (int64_t i = 0; i + 2 < p.points.size(); i += 3) {
			std::vector<Vector3> ring;
			for (int edge = 0; edge < 3; ++edge) {
				const Vector3 a = p.points[i + edge], b = p.points[i + (edge + 1) % 3];
				ring.push_back(a);
				const auto other = borders(b, box, p.key);
				for (const Border &border : borders(a, box, p.key)) {
					if (std::find(other.begin(), other.end(), border) == other.end()) continue;
					const Vector2 start(a.x, a.z), d(b.x - a.x, b.z - a.z);
					if (d.length_squared() < 0.000001) continue;
					std::vector<std::pair<double, Vector3>> stations;
					for (const auto &entry : bins[border]) {
						const Vector2 q = border.axis == 0 ? Vector2(a.x, entry.first) : Vector2(entry.first, a.z);
						const double t = (double)(q - start).dot(d) / d.length_squared();
						if (t <= 0.00001 || t >= 0.99999) continue;
						const double value = entry.second[p.kind(i / 3)];
						const double y = std::isfinite(value) ? value : Math::lerp((double)a.y, (double)b.y, t);
						stations.push_back({t, Vector3(q.x, y, q.y)});
					}
					std::sort(stations.begin(), stations.end(), [](const auto &a, const auto &b) { return a.first < b.first; });
					for (const auto &station : stations) ring.push_back(station.second);
				}
			}
			if (ring.size() == 3) append(ring[0], ring[1], ring[2], i / 3);
			else {
				const Vector3 centre = (p.points[i] + p.points[i + 1] + p.points[i + 2]) / (real_t)3.0;
				for (size_t j = 0; j < ring.size(); ++j) append(centre, ring[j], ring[(j + 1) % ring.size()], i / 3);
			}
		}
		Dictionary out;
		out["triangles"] = pack<PackedVector3Array>(vertices); out["owners"] = pack<PackedInt32Array>(owners);
		out["hard"] = pack<PackedByteArray>(hard); out["paving"] = pack<PackedByteArray>(paving);
		result[p.key] = out;
	}
	return result;
}

Array ShoreMesh::surface(const Array &source, const Dictionary &input, int size, double step, double origin,
		const Array &p_bodies, const Ref<ShoreSampler> &sampler, Object *abort) {
	const PackedVector3Array src_v = source[Mesh::ARRAY_VERTEX], src_n = source[Mesh::ARRAY_NORMAL];
	const PackedColorArray src_c = source[Mesh::ARRAY_COLOR];
	const PackedVector2Array src_uv = source[Mesh::ARRAY_TEX_UV], src_uv2 = source[Mesh::ARRAY_TEX_UV2];
	const PackedInt32Array src_i = source[Mesh::ARRAY_INDEX];
	const PackedFloat32Array src_t = source[Mesh::ARRAY_TANGENT];
	const auto bodies = read_bodies(p_bodies);
	std::vector<Vector3> vertices, normals;
	std::vector<Color> colors;
	std::vector<Vector2> uv, uv2;
	std::vector<float> tangents;
	std::vector<int32_t> indices, old(src_v.size(), -1);
	std::unordered_map<Vector4, int, VHash> welded;
	std::unordered_map<Vector3i, double, IHash> wetness;
	auto emit = [&](Vector3 p, Vector3 normal, Color color, Vector2 tex, Vector2 bank, const float *tangent) {
		const Vector4 key(p.x, p.y, p.z, bank.y);
		const auto found = welded.find(key);
		int id;
		if (found != welded.end()) { id = found->second; normals[id] += normal; }
		else {
			id = (int)vertices.size(); welded[key] = id;
			vertices.push_back(p); normals.push_back(normal); colors.push_back(color); uv.push_back(tex); uv2.push_back(bank);
			tangents.insert(tangents.end(), tangent, tangent + 4);
		}
		indices.push_back(id);
		return id;
	};
	for (int64_t i = 0; i < src_i.size(); ++i) {
		if ((i & 4095) == 0 && stopped(abort)) return Array();
		const int id = src_i[i];
		if (old[id] < 0) old[id] = emit(src_v[id], src_n[id], src_c[id], src_uv[id], src_uv2[id], src_t.ptr() + id * 4);
		else indices.push_back(old[id]);
	}
	const float tangent[] = {1, 0, 0, 1};
	for (const Patch &patch : read_patches(input)) {
		if (stopped(abort)) return Array();
		const int base = patch.key.y * size + patch.key.x;
		for (int64_t i = 0; i + 2 < patch.points.size(); i += 3) {
			Vector3 normal = (patch.points[i + 2] - patch.points[i]).cross(patch.points[i + 1] - patch.points[i]).normalized();
			if (normal.y < 0) normal = -normal;
			const int owner = patch.owners[i / 3];
			for (int j = 0; j < 3; ++j) {
				const Vector3 p = patch.points[i + j]; const Vector2 xz(p.x, p.z);
				Vector2 f = ((xz - Vector2(origin, origin)) / (real_t)step - Vector2(patch.key.x, patch.key.y)).clamp(Vector2(), Vector2(1, 1));
				const Color c = src_c[base].lerp(src_c[base + 1], f.x).lerp(src_c[base + size].lerp(src_c[base + size + 1], f.x), f.y);
				const Vector2 tex = src_uv[base].lerp(src_uv[base + 1], f.x).lerp(src_uv[base + size].lerp(src_uv[base + size + 1], f.x), f.y);
				const double level = owner >= 0 ? bodies[owner].at(xz) : src_uv2[base].x;
				double bank = patch.paving[i / 3];
				if (owner < 0 && !patch.hard[i / 3] && sampler.is_valid()) {
					const Vector3i key((int)Math::round((double)p.x * 100), (int)Math::round((double)p.z * 100), 0);
					const auto cached = wetness.find(key);
					if (cached != wetness.end()) bank = cached->second;
					else {
						const Vector4 near = sampler->nearest_bank(xz, 2);
						if (near.x >= 0) bank = -std::clamp(1.0 - (double)near.w / 1.5, 0.0, 1.0);
						wetness[key] = bank;
					}
				}
				emit(p, normal, c, tex, Vector2(level, bank), tangent);
			}
		}
	}
	for (auto &n : normals) n.normalize();
	Array out = source.duplicate();
	out[Mesh::ARRAY_VERTEX] = pack<PackedVector3Array>(vertices); out[Mesh::ARRAY_NORMAL] = pack<PackedVector3Array>(normals);
	out[Mesh::ARRAY_COLOR] = pack<PackedColorArray>(colors); out[Mesh::ARRAY_TEX_UV] = pack<PackedVector2Array>(uv);
	out[Mesh::ARRAY_TEX_UV2] = pack<PackedVector2Array>(uv2); out[Mesh::ARRAY_INDEX] = pack<PackedInt32Array>(indices);
	out[Mesh::ARRAY_TANGENT] = pack<PackedFloat32Array>(tangents);
	return out;
}

Array ShoreMesh::water(const Dictionary &patches, int size, double step, double origin, const Array &p_bodies,
		const Ref<ShoreDomainIndex> &domains, const PackedFloat32Array &distance, const PackedFloat32Array &hard_distance, const Vector4 &calibration, Object *abort) {
	const auto bodies = read_bodies(p_bodies);
	struct Batch {
		std::vector<Vector3> vertices;
		std::vector<Color> colors;
		std::vector<Vector2> flow;
		std::vector<int32_t> indices;
		std::unordered_map<Vector3i, int, IHash> welded;
	};
	Batch batches[2];
	auto append = [&](int owner, Vector2 p) {
		const Body &body = bodies[owner]; Batch &batch = batches[body.still ? 1 : 0];
		const Vector3i key((int)Math::round((double)p.x * 100), (int)Math::round((double)p.y * 100), owner);
		const auto found = batch.welded.find(key);
		int id;
		if (found != batch.welded.end()) id = found->second;
		else {
			id = (int)batch.vertices.size(); batch.welded[key] = id;
			const Vector2 f = ((p - Vector2(origin, origin)) / (real_t)step).clamp(Vector2(), Vector2(size - 1, size - 1));
			const int ix = std::min((int)f.x, size - 2), iz = std::min((int)f.y, size - 2), k = iz * size + ix;
			const double d = Math::lerp(Math::lerp((double)distance[k], (double)distance[k + 1], (double)f.x - ix),
				Math::lerp((double)distance[k + size], (double)distance[k + size + 1], (double)f.x - ix), (double)f.y - iz);
			const double hard = Math::lerp(Math::lerp((double)hard_distance[k], (double)hard_distance[k + 1], (double)f.x - ix),
				Math::lerp((double)hard_distance[k + size], (double)hard_distance[k + size + 1], (double)f.x - ix), (double)f.y - iz);
			const double ramp = calibration.x * (body.tidal && hard > d + step * 1.5 ? calibration.y : 1.0);
			batch.vertices.emplace_back(p.x, body.at(p) + 0.03, p.y);
			batch.colors.emplace_back(std::clamp(d / ramp, 0.0, 1.0), body.tidal ? 1.0 : 0.0, std::clamp(d / calibration.z, 0.0, 1.0));
			batch.flow.push_back(body.axis ? (body.b - body.a).normalized() * calibration.w : Vector2());
		}
		batch.indices.push_back(id);
	};
	for (int z = 0; z < size - 1; ++z) {
		if (stopped(abort)) return Array();
		for (int x = 0; x < size - 1; ++x) {
			const Vector2i key(x, z);
			if (patches.has(key)) {
				const Dictionary patch = patches[key]; const PackedVector3Array triangles = patch["triangles"];
				const PackedInt32Array owners = patch["owners"];
				for (int64_t i = 0; i + 2 < triangles.size(); i += 3) if (owners[i / 3] >= 0) {
					for (int j = 0; j < 3; ++j) append(owners[i / 3], Vector2(triangles[i + j].x, triangles[i + j].z));
				}
			} else {
				const Rect2 box = box_at(key, step, origin); const int owner = domains->at(box.get_center());
				if (owner < 0) continue;
				const Vector2 a = box.position, b(box.get_end().x, a.y), c = box.get_end(), d(a.x, c.y);
				for (const Vector2 &p : {a, b, d, b, c, d}) append(owner, p);
			}
		}
	}
	Array out;
	for (const auto &batch : batches) {
		Array arrays;
		arrays.push_back(pack<PackedVector3Array>(batch.vertices)); arrays.push_back(pack<PackedColorArray>(batch.colors));
		arrays.push_back(pack<PackedInt32Array>(batch.indices)); arrays.push_back(pack<PackedVector2Array>(batch.flow));
		out.push_back(arrays);
	}
	return out;
}

void ShoreMesh::_bind_methods() {
	ClassDB::bind_static_method("ShoreMesh", D_METHOD("stitch", "patches", "size", "step", "origin", "abort"), &ShoreMesh::stitch);
	ClassDB::bind_static_method("ShoreMesh", D_METHOD("surface", "source", "patches", "size", "step", "origin", "bodies", "sampler", "abort"), &ShoreMesh::surface);
	ClassDB::bind_static_method("ShoreMesh", D_METHOD("water", "patches", "size", "step", "origin", "bodies", "domains", "distance", "hard_distance", "calibration", "abort"), &ShoreMesh::water);
}
}
