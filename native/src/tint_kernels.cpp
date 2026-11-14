#include "tint_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <cmath>

namespace godot {
namespace {
// GDScript's minf / maxf / clampf / lerpf on doubles.
double min_d(double a, double b) { return a < b ? a : b; }
double max_d(double a, double b) { return a > b ? a : b; }
double clamp_d(double v, double lo, double hi) { return v < lo ? lo : (v > hi ? hi : v); }
double lerp_d(double a, double b, double t) { return a + (b - a) * t; }
} // namespace

double TintKernels::min_y(const PackedVector3Array &verts) {
	double out = INFINITY;
	const Vector3 *v = verts.ptr();
	for (int64_t i = 0; i < verts.size(); ++i) out = min_d(out, v[i].y);
	return out;
}

PackedColorArray TintKernels::wall_colours(const PackedVector3Array &verts, const Color &c, double foot,
		double fade, double foot_shade) {
	const double y0 = std::isinf(foot) ? min_d(foot, min_y(verts)) : foot;
	PackedColorArray out;
	out.resize(verts.size());
	const Vector3 *v = verts.ptr();
	Color *w = out.ptrw();
	for (int64_t i = 0; i < verts.size(); ++i) {
		const double k = lerp_d(foot_shade, 1.0, clamp_d(((double)v[i].y - y0) / fade, 0.0, 1.0));
		w[i] = Color((real_t)((double)c.r * k), (real_t)((double)c.g * k), (real_t)((double)c.b * k));
	}
	return out;
}

PackedColorArray TintKernels::roof_colours(const PackedVector3Array &verts, const PackedVector3Array &normals,
		const Color &c, double min_rise, double eave_shade) {
	double y0 = INFINITY, y1 = -INFINITY;
	const Vector3 *v = verts.ptr();
	for (int64_t i = 0; i < verts.size(); ++i) {
		y0 = min_d(y0, v[i].y);
		y1 = max_d(y1, v[i].y);
	}
	PackedColorArray out;
	out.resize(verts.size());
	Color *w = out.ptrw();
	const double rise = y1 - y0;
	if (rise < min_rise) {
		for (int64_t i = 0; i < verts.size(); ++i) w[i] = c;
		return out;
	}
	const Vector3 *n = normals.ptr();
	for (int64_t i = 0; i < verts.size(); ++i) {
		const double k = lerp_d(eave_shade, 1.0, ((double)v[i].y - y0) / rise);
		const double north = clamp_d(-(double)n[i].z, 0.0, 1.0);
		w[i] = Color((real_t)((double)c.r * k * (1.0 - 0.09 * north)), (real_t)((double)c.g * k * (1.0 - 0.02 * north)),
				(real_t)((double)c.b * k * (1.0 - 0.11 * north)));
	}
	return out;
}

void TintKernels::_bind_methods() {
	ClassDB::bind_static_method("TintKernels", D_METHOD("wall_colours", "verts", "c", "foot", "fade", "foot_shade"),
			&TintKernels::wall_colours);
	ClassDB::bind_static_method("TintKernels", D_METHOD("roof_colours", "verts", "normals", "c", "min_rise", "eave_shade"),
			&TintKernels::roof_colours);
	ClassDB::bind_static_method("TintKernels", D_METHOD("min_y", "verts"), &TintKernels::min_y);
}

} // namespace godot
