#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

// One material's surface for ReliefKit in native code: quad, tri and box
// append the same vertices, normals, UVs, tangents and indices as the
// script (same float32 rounding), one call per box instead of six quads.
class QuadSink : public RefCounted {
	GDCLASS(QuadSink, RefCounted)

	std::vector<Vector3> verts, normals;
	std::vector<Vector2> uvs;
	std::vector<int32_t> indices;
	std::vector<float> tangents;

	void tangent(const Vector3 &n, const Vector3 &du, const Vector3 &dnv, int count);

protected:
	static void _bind_methods();

public:
	// ReliefKit.quad
	void quad(const Vector3 &p0, const Vector3 &p1, const Vector3 &p2, const Vector3 &p3,
			const Vector3 &n, const Vector2 &uv0, const Vector2 &uv1);
	// ReliefKit.tri
	void tri(const Vector3 &p0, const Vector3 &p1, const Vector3 &p2, const Vector3 &n);
	// ReliefKit.box
	void box(const Vector3 &c, const Vector3 &ax, const Vector3 &az, const Vector3 &size);
	// [verts, normals, uvs, indices, tangents], ReliefKit's surface layout.
	Array arrays() const;
};

} // namespace godot
