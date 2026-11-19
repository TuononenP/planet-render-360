#include "plinth_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cstring>
#include <vector>

namespace godot {
namespace {

// GDScript's minf / maxf on doubles.
double min_d(double a, double b) { return a < b ? a : b; }
double max_d(double a, double b) { return a > b ? a : b; }

// BuildingWalls' face arrays: [verts, normals, uvs, tangents, indices].
struct Face {
	std::vector<Vector3> verts, normals;
	std::vector<Vector2> uvs;
	std::vector<float> tangents;
	std::vector<int32_t> indices;
};

// BuildingWalls._quad; `tangents` is false in batch mode.
void quad(Face &f, const Vector2 &a, const Vector2 &b, double y0, double y1, const Vector2 &n,
		const Vector2 &uv, bool tangents) {
	const Vector2 e = b - a;
	const Vector3 n3(n.x, 0.0f, n.y);
	const int32_t k = (int32_t)f.verts.size();
	f.verts.push_back(Vector3(a.x, (real_t)y0, a.y));
	f.verts.push_back(Vector3(b.x, (real_t)y0, b.y));
	f.verts.push_back(Vector3(b.x, (real_t)y1, b.y));
	f.verts.push_back(Vector3(a.x, (real_t)y1, a.y));
	Vector3 t3;
	float w = 1.0f;
	if (tangents) {
		t3 = Vector3(e.x, 0.0f, e.y).normalized();
		w = (double)n3.cross(t3).y > 0.0 ? 1.0f : -1.0f;
	}
	for (int j = 0; j < 4; ++j) {
		f.normals.push_back(n3);
		if (tangents) {
			f.tangents.push_back(t3.x);
			f.tangents.push_back(t3.y);
			f.tangents.push_back(t3.z);
			f.tangents.push_back(w);
		}
	}
	f.uvs.push_back(Vector2(0.0f, uv.y));
	f.uvs.push_back(Vector2(uv.x, uv.y));
	f.uvs.push_back(Vector2(uv.x, 0.0f));
	f.uvs.push_back(Vector2(0.0f, 0.0f));
	const double s = (double)e.x * (double)n.y - (double)e.y * (double)n.x;
	if (s > 0.0) {
		f.indices.insert(f.indices.end(), { k, k + 2, k + 1, k, k + 3, k + 2 });
	} else {
		f.indices.insert(f.indices.end(), { k, k + 1, k + 2, k, k + 2, k + 3 });
	}
}

// PlinthStyle._flat: a horizontal quad at `y` facing up (`up` > 0) or down.
void flat(Face &f, const Vector2 &p0, const Vector2 &p1, const Vector2 &p2, const Vector2 &p3, double y,
		double up, double m, bool tangents) {
	const int32_t k = (int32_t)f.verts.size();
	const Vector3 t = Vector3((real_t)((double)p1.x - (double)p0.x), 0.0f,
			(real_t)((double)p1.y - (double)p0.y)).normalized();
	const Vector2 corners[4] = { p0, p1, p2, p3 };
	for (const Vector2 &q : corners) {
		f.verts.push_back(Vector3(q.x, (real_t)y, q.y));
		f.normals.push_back(Vector3(0.0f, (real_t)up, 0.0f));
		f.uvs.push_back((q / (real_t)m) / (real_t)4.0);
		if (tangents) {
			f.tangents.push_back(t.x);
			f.tangents.push_back(t.y);
			f.tangents.push_back(t.z);
			f.tangents.push_back(1.0f);
		}
	}
	const bool face_up = (double)(p1 - p0).cross(p3 - p0) > 0.0;
	if (face_up == (up > 0.0)) {
		f.indices.insert(f.indices.end(), { k, k + 1, k + 2, k, k + 2, k + 3 });
	} else {
		f.indices.insert(f.indices.end(), { k, k + 2, k + 1, k, k + 3, k + 2 });
	}
}

// PlinthStyle.miters.
std::vector<Vector2> miters(const PackedVector2Array &ring, double outward) {
	const int64_t count = ring.size();
	std::vector<Vector2> normals, out;
	for (int64_t i = 0; i < count; ++i) {
		const Vector2 e = ring[(i + 1) % count] - ring[i];
		normals.push_back(Vector2(e.y, -e.x).normalized() * (real_t)outward);
	}
	for (int64_t i = 0; i < count; ++i) {
		const Vector2 n1 = normals[i];
		const Vector2 mm = (normals[(i - 1 + count) % count] + n1).normalized();
		if (mm != Vector2()) {
			out.push_back(mm / (real_t)max_d((double)mm.dot(n1), 0.35));
		} else {
			out.push_back(n1);
		}
	}
	return out;
}

PackedVector3Array to_packed(const std::vector<Vector3> &v) {
	PackedVector3Array out;
	out.resize((int64_t)v.size());
	if (!v.empty()) std::memcpy(out.ptrw(), v.data(), v.size() * sizeof(Vector3));
	return out;
}

Array to_array(const Face &f) {
	PackedVector2Array uvs;
	uvs.resize((int64_t)f.uvs.size());
	if (!f.uvs.empty()) std::memcpy(uvs.ptrw(), f.uvs.data(), f.uvs.size() * sizeof(Vector2));
	PackedFloat32Array tangents;
	tangents.resize((int64_t)f.tangents.size());
	if (!f.tangents.empty()) std::memcpy(tangents.ptrw(), f.tangents.data(), f.tangents.size() * sizeof(float));
	PackedInt32Array indices;
	indices.resize((int64_t)f.indices.size());
	if (!f.indices.empty()) std::memcpy(indices.ptrw(), f.indices.data(), f.indices.size() * sizeof(int32_t));
	Array out;
	out.push_back(to_packed(f.verts));
	out.push_back(to_packed(f.normals));
	out.push_back(uvs);
	out.push_back(tangents);
	out.push_back(indices);
	return out;
}

} // namespace

PackedVector2Array PlinthKernels::edge_points(const PackedVector2Array &ring) {
	const int64_t n = ring.size();
	PackedVector2Array out;
	out.resize(n * 2);
	for (int64_t i = 0; i < n; ++i) {
		out.set(i, ring[i]);
		out.set(n + i, (ring[i] + ring[(i + 1) % n]) * (real_t)0.5);
	}
	return out;
}

Array PlinthKernels::plinth(const Array &rings, const Array &grounds, const PackedByteArray &ccw,
		const PackedFloat64Array &params, bool tangents) {
	const double m = params[0], floor_y = params[1];
	const double sink_m = params[2], gap_m = params[3], coping_min_m = params[4];
	const double coping_depth_m = params[5], coping_proud_m = params[6];
	const double y1 = floor_y - sink_m * m;
	Face face, coping;
	for (int64_t r = 0; r < rings.size(); ++r) {
		const PackedVector2Array ring = rings[r];
		const PackedFloat64Array g = grounds[r];
		const bool counter = ccw[r] != 0;
		const int64_t n = ring.size();
		const std::vector<Vector2> mit = miters(ring, (counter ? 1.0 : -1.0) * (r > 0 ? -1.0 : 1.0));
		for (int64_t i = 0; i < n; ++i) {
			const Vector2 a = ring[i];
			const Vector2 b = ring[(i + 1) % n];
			const Vector2 d = b - a;
			if ((double)d.length() < 0.001) continue;
			const double edge_low = min_d(g[i], min_d(g[(i + 1) % n], g[n + i]));
			if (floor_y - edge_low < gap_m * m) continue;
			const double y0 = edge_low - sink_m * m;
			Vector2 nrm = counter ? Vector2(d.y, -d.x).normalized() : Vector2(-d.y, d.x).normalized();
			if (r > 0) nrm = -nrm;
			quad(face, a, b, y0, y1, nrm,
					Vector2((real_t)((double)d.length() / m / 4.0), (real_t)((y1 - y0) / m / 4.0)), tangents);
			if (y1 - edge_low >= coping_min_m * m) {
				// PlinthStyle.coping
				const double proud = coping_proud_m * m;
				const double bot = y1 - coping_depth_m * m;
				const Vector2 ma = mit[i], mb = mit[(i + 1) % n];
				const Vector2 ca = a + ma * (real_t)proud;
				const Vector2 cb = b + mb * (real_t)proud;
				quad(coping, ca, cb, bot, y1, nrm,
						Vector2((real_t)((double)ca.distance_to(cb) / m / 4.0), (real_t)(coping_depth_m / 4.0)), tangents);
				flat(coping, a, b, cb, ca, y1, 1.0, m, tangents);
				flat(coping, a, b, cb, ca, bot, -1.0, m, tangents);
			}
		}
	}
	Array out;
	out.push_back(to_array(face));
	out.push_back(to_array(coping));
	return out;
}

void PlinthKernels::_bind_methods() {
	ClassDB::bind_static_method("PlinthKernels", D_METHOD("edge_points", "ring"), &PlinthKernels::edge_points);
	ClassDB::bind_static_method("PlinthKernels",
			D_METHOD("plinth", "rings", "grounds", "ccw", "params", "tangents"), &PlinthKernels::plinth);
}

} // namespace godot
