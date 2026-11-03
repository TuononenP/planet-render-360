#pragma once

#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// Geometry2D::segment_intersects_segment, the engine's float32 steps
// (checked against the engine point for point).
inline bool segments_cross(const Vector2 &from_a, const Vector2 &to_a, const Vector2 &from_b,
		const Vector2 &to_b, Vector2 &res) {
	const Vector2 b = to_a - from_a;
	Vector2 c = from_b - from_a;
	Vector2 d = to_b - from_a;
	const real_t ab_len = b.dot(b);
	if (ab_len <= 0) {
		return false;
	}
	const Vector2 bn(b.x / ab_len, b.y / ab_len);
	c = Vector2(c.x * bn.x + c.y * bn.y, c.y * bn.x - c.x * bn.y);
	d = Vector2(d.x * bn.x + d.y * bn.y, d.y * bn.x - d.x * bn.y);
	const real_t eps = (real_t)CMP_EPSILON;
	if ((c.y < -eps && d.y < -eps) || (c.y > eps && d.y > eps)) {
		return false;
	}
	if (Math::is_equal_approx(c.y, d.y)) {
		return false;
	}
	const real_t ab_pos = d.x + (c.x - d.x) * d.y / (d.y - c.y);
	if (ab_pos < 0 || ab_pos > 1) {
		return false;
	}
	res = from_a + b * ab_pos;
	return true;
}

} // namespace godot
