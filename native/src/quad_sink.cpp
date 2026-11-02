#include "quad_sink.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

#include <cmath>
#include <cstring>

namespace godot {

namespace {

// GDScript's signf on a double difference of two float32 components.
real_t sign_of(real_t a, real_t b) {
	const double d = (double)a - (double)b;
	return d > 0.0 ? 1.0f : (d < 0.0 ? -1.0f : 0.0f);
}

} // namespace

// ReliefKit._tangents
void QuadSink::tangent(const Vector3 &n, const Vector3 &du, const Vector3 &dnv, int count) {
	Vector3 t = du - n * n.dot(du);
	if ((double)t.length_squared() < 1e-10) {
		t = n.cross(std::fabs((double)n.y) < 0.9 ? Vector3(0, 1, 0) : Vector3(1, 0, 0));
	}
	t = t.normalized();
	const float w = n.cross(t).dot(dnv) >= 0.0f ? 1.0f : -1.0f;
	for (int j = 0; j < count; j++) {
		tangents.push_back(t.x);
		tangents.push_back(t.y);
		tangents.push_back(t.z);
		tangents.push_back(w);
	}
}

void QuadSink::quad(const Vector3 &p0, const Vector3 &p1, const Vector3 &p2, const Vector3 &p3,
		const Vector3 &n, const Vector2 &uv0, const Vector2 &uv1) {
	const int32_t k = (int32_t)verts.size();
	verts.push_back(p0);
	verts.push_back(p1);
	verts.push_back(p2);
	verts.push_back(p3);
	for (int j = 0; j < 4; j++) {
		normals.push_back(n);
	}
	uvs.push_back(Vector2(uv0.x, uv1.y));
	uvs.push_back(Vector2(uv1.x, uv1.y));
	uvs.push_back(Vector2(uv1.x, uv0.y));
	uvs.push_back(Vector2(uv0.x, uv0.y));
	tangent(n, (p1 - p0) * sign_of(uv1.x, uv0.x), (p3 - p0) * sign_of(uv1.y, uv0.y), 4);
	// Godot's front face is clockwise seen from outside.
	if ((p2 - p0).cross(p1 - p0).dot(n) >= 0.0f) {
		indices.insert(indices.end(), { k, k + 1, k + 2, k, k + 2, k + 3 });
	} else {
		indices.insert(indices.end(), { k, k + 2, k + 1, k, k + 3, k + 2 });
	}
}

void QuadSink::tri(const Vector3 &p0, const Vector3 &p1, const Vector3 &p2, const Vector3 &n) {
	const int32_t k = (int32_t)verts.size();
	verts.push_back(p0);
	verts.push_back(p1);
	verts.push_back(p2);
	const Vector3 ax = (p1 - p0).normalized();
	const Vector3 ay = n.cross(ax);
	for (const Vector3 &p : { p0, p1, p2 }) {
		normals.push_back(n);
		uvs.push_back(Vector2((p - p0).dot(ax), (p - p0).dot(ay)) * 0.5f);
	}
	tangent(n, ax, -ay, 3);
	if ((p2 - p0).cross(p1 - p0).dot(n) >= 0.0f) {
		indices.insert(indices.end(), { k, k + 1, k + 2 });
	} else {
		indices.insert(indices.end(), { k, k + 2, k + 1 });
	}
}

void QuadSink::box(const Vector3 &c, const Vector3 &ax, const Vector3 &az, const Vector3 &size) {
	const Vector3 hx = ax * size.x * 0.5f;
	const Vector3 hy = Vector3(0, 1, 0) * size.y * 0.5f;
	const Vector3 hz = az * size.z * 0.5f;
	const Vector2 z2(0, 0);
	const Vector2 uvx = Vector2(size.x, size.y) * 0.5f;
	quad(c - hx - hy + hz, c + hx - hy + hz, c + hx + hy + hz, c - hx + hy + hz, az, z2, uvx);
	quad(c + hx - hy - hz, c - hx - hy - hz, c - hx + hy - hz, c + hx + hy - hz, -az, z2, uvx);
	const Vector2 uvz = Vector2(size.z, size.y) * 0.5f;
	quad(c + hx - hy + hz, c + hx - hy - hz, c + hx + hy - hz, c + hx + hy + hz, ax, z2, uvz);
	quad(c - hx - hy - hz, c - hx - hy + hz, c - hx + hy + hz, c - hx + hy - hz, -ax, z2, uvz);
	const Vector2 uvt = Vector2(size.x, size.z) * 0.5f;
	quad(c - hx + hy + hz, c + hx + hy + hz, c + hx + hy - hz, c - hx + hy - hz, Vector3(0, 1, 0), z2, uvt);
	quad(c - hx - hy - hz, c + hx - hy - hz, c + hx - hy + hz, c - hx - hy + hz, Vector3(0, -1, 0), z2, uvt);
}

Array QuadSink::arrays() const {
	PackedVector3Array v, nn;
	PackedVector2Array uv;
	PackedInt32Array idx;
	PackedFloat32Array tan;
	v.resize((int64_t)verts.size());
	nn.resize((int64_t)normals.size());
	uv.resize((int64_t)uvs.size());
	idx.resize((int64_t)indices.size());
	tan.resize((int64_t)tangents.size());
	if (!verts.empty()) {
		std::memcpy(v.ptrw(), verts.data(), verts.size() * sizeof(Vector3));
		std::memcpy(nn.ptrw(), normals.data(), normals.size() * sizeof(Vector3));
		std::memcpy(uv.ptrw(), uvs.data(), uvs.size() * sizeof(Vector2));
		std::memcpy(idx.ptrw(), indices.data(), indices.size() * sizeof(int32_t));
		std::memcpy(tan.ptrw(), tangents.data(), tangents.size() * sizeof(float));
	}
	Array out;
	out.push_back(v);
	out.push_back(nn);
	out.push_back(uv);
	out.push_back(idx);
	out.push_back(tan);
	return out;
}

void QuadSink::_bind_methods() {
	ClassDB::bind_method(D_METHOD("quad", "p0", "p1", "p2", "p3", "n", "uv0", "uv1"), &QuadSink::quad);
	ClassDB::bind_method(D_METHOD("tri", "p0", "p1", "p2", "n"), &QuadSink::tri);
	ClassDB::bind_method(D_METHOD("box", "c", "ax", "az", "size"), &QuadSink::box);
	ClassDB::bind_method(D_METHOD("arrays"), &QuadSink::arrays);
}

} // namespace godot
