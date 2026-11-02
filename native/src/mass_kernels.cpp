#include "mass_kernels.h"

#include "parallel.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <vector>

namespace godot {

PackedFloat32Array MassKernels::tangents(const PackedVector3Array &v, const PackedVector3Array &n,
		const PackedVector2Array &uv, const PackedInt32Array &idx) {
	const int64_t nv = v.size();
	const Vector3 *vp = v.ptr();
	const Vector3 *np = n.ptr();
	const Vector2 *up = uv.ptr();
	const int32_t *ip = idx.ptr();
	std::vector<Vector3> tu(nv);
	std::vector<Vector3> tv(nv);
	// Accumulated in triangle order, as the script does (float sums
	// depend on the order).
	const int64_t tris = idx.size() / 3;
	for (int64_t t = 0; t < tris; t++) {
		int32_t i0 = ip[t * 3];
		int32_t i1 = ip[t * 3 + 1];
		int32_t i2 = ip[t * 3 + 2];
		Vector3 e1 = vp[i1] - vp[i0];
		Vector3 e2 = vp[i2] - vp[i0];
		Vector2 d1 = up[i1] - up[i0];
		Vector2 d2 = up[i2] - up[i0];
		double det = (double)d1.x * (double)d2.y - (double)d2.x * (double)d1.y;
		if (std::abs(det) < 1e-12) {
			continue;
		}
		double r = 1.0 / det;
		// Vector3 * float: the script's double factor rounds to float32.
		Vector3 su = (e1 * d2.y - e2 * d1.y) * (float)r;
		Vector3 sv = (e2 * d1.x - e1 * d2.x) * (float)r;
		for (int32_t i : { i0, i1, i2 }) {
			tu[i] += su;
			tv[i] += sv;
		}
	}
	PackedFloat32Array out;
	out.resize(nv * 4);
	float *op = out.ptrw();
	const int64_t chunk = 4096;
	parallel_for((int)((nv + chunk - 1) / chunk), [&](int c) {
		int64_t end = Math::min((int64_t)(c + 1) * chunk, nv);
		for (int64_t i = (int64_t)c * chunk; i < end; i++) {
			Vector3 nn = np[i];
			Vector3 t = tu[i] - nn * nn.dot(tu[i]);
			if ((double)t.length_squared() < 1e-12) {
				t = std::abs((double)nn.x) < 0.9 ? Vector3(1, 0, 0) : Vector3(0, 0, 1);
				t = (t - nn * nn.dot(t));
			}
			t = t.normalized();
			float w = nn.cross(t).dot(-tv[i]) >= 0.0 ? 1.0f : -1.0f;
			op[i * 4] = t.x;
			op[i * 4 + 1] = t.y;
			op[i * 4 + 2] = t.z;
			op[i * 4 + 3] = w;
		}
	});
	return out;
}

void MassKernels::_bind_methods() {
	ClassDB::bind_static_method("MassKernels", D_METHOD("tangents", "v", "n", "uv", "idx"),
			&MassKernels::tangents);
}

} // namespace godot
