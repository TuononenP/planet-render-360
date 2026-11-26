#pragma once

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
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
	// ReliefKit.rail
	void rail(const Vector3 &a, const Vector3 &b, real_t h, const Vector3 &n, real_t m);
	bool is_empty() const { return verts.empty(); }
	// FinlandRelief.plinth
	void granite_plinth(const Vector2 &a, const Vector2 &dir, const Vector2 &n,
			real_t len, real_t y0, real_t h, double seed_v, real_t m);
	// StreetFront._shopfront
	void shopfront(const Vector2 &a, const Vector2 &dir, const Vector2 &n,
			real_t ground_y, real_t step_m, real_t height_m, int bays, int door,
			int sign_px, real_t cell, int bays_mod, real_t m);
	// FacadeRelief._storeys (+ _balcony, _deep_balcony, _quoins)
	static void build_storeys(const Ref<QuadSink> &stone, const Ref<QuadSink> &frame,
			const Ref<QuadSink> &iron, const Ref<QuadSink> &glass, const Ref<QuadSink> &glazed_frame,
			const Vector2 &a, const Vector2 &dir, const Vector2 &n, real_t len_m, int bays,
			const Array &rows, const PackedByteArray &stacks, int flags, double seed_v,
			real_t balconette_prob, real_t deep_balcony_m, real_t m);
	// [verts, normals, uvs, indices, tangents], ReliefKit's surface layout.
	Array arrays() const;
};

} // namespace godot
