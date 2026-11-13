#include "landmark_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <cstring>
#include <vector>

namespace godot {
namespace {
// Scalars are doubles as in GDScript; each meets a vector as real_t, as
// the script's Vector3 * float does.
struct Sink {
	std::vector<Vector3> v, n;
	std::vector<Vector2> uv;

	// LandmarkMesh.tri: swapped when facing away from the summed normals.
	void tri(const Vector3 &a, const Vector3 &b, const Vector3 &c, const Vector3 &na, const Vector3 &nb,
			const Vector3 &nc, const Vector2 &ua, const Vector2 &ub, const Vector2 &uc) {
		if ((c - a).cross(b - a).dot(na + nb + nc) < 0.0) {
			v.insert(v.end(), { a, c, b });
			n.insert(n.end(), { na, nc, nb });
			uv.insert(uv.end(), { ua, uc, ub });
		} else {
			v.insert(v.end(), { a, b, c });
			n.insert(n.end(), { na, nb, nc });
			uv.insert(uv.end(), { ua, ub, uc });
		}
	}

	// LandmarkMesh.quad with uv0 at the origin.
	void quad(const Vector3 &a, const Vector3 &b, const Vector3 &c, const Vector3 &d, const Vector3 &normal) {
		Vector3 nn = normal;
		if (nn == Vector3()) nn = (b - a).cross(d - a).normalized();
		const double w = a.distance_to(b);
		const double h = a.distance_to(d);
		const Vector2 uv0;
		const Vector2 ua = uv0;
		const Vector2 ub = uv0 + Vector2((real_t)w, 0);
		const Vector2 uc = uv0 + Vector2((real_t)w, (real_t)-h);
		const Vector2 ud = uv0 + Vector2(0, (real_t)-h);
		tri(a, b, c, nn, nn, nn, ua, ub, uc);
		tri(a, c, d, nn, nn, nn, ua, uc, ud);
	}

	// LandmarkMesh.box, sharp edges.
	void sharp_box(const Vector3 &center, const Vector3 &size, const Basis &basis) {
		const Vector3 hx = basis.get_column(0) * size.x * (real_t)0.5;
		const Vector3 hy = basis.get_column(1) * size.y * (real_t)0.5;
		const Vector3 hz = basis.get_column(2) * size.z * (real_t)0.5;
		const Vector3 faces[6][3] = { { hx, hy, hz }, { -hx, hy, -hz }, { hz, hy, -hx }, { -hz, hy, hx },
			{ hy, hz, hx }, { -hy, hz, -hx } };
		for (const auto &f : faces) {
			const Vector3 o = center + f[0];
			const Vector3 &up = f[1], &side = f[2];
			quad(o - side - up, o + side - up, o + side + up, o - side + up, f[0].normalized());
		}
	}

	// LandmarkMesh._bevel_box.
	void bevel_box(const Vector3 &center, const Vector3 &size, const Basis &basis, double c) {
		const Vector3 ax[3] = { basis.get_column(0).normalized(), basis.get_column(1).normalized(),
			basis.get_column(2).normalized() };
		const double h[3] = { (double)size.x * 0.5, (double)size.y * 0.5, (double)size.z * 0.5 };
		const double hin[3] = { h[0] - c, h[1] - c, h[2] - c };
		const auto fv = [&](int a, double s, const Vector3 &sg) {
			Vector3 p = center;
			for (int k = 0; k < 3; ++k) {
				const double value = k == a ? h[k] * s : hin[k] * (double)sg[k];
				p += ax[k] * (real_t)value;
			}
			return p;
		};
		const struct { int a; double s; int up, side; } faces[6] = { { 0, 1.0, 1, 2 }, { 0, -1.0, 1, 2 },
			{ 1, 1.0, 2, 0 }, { 1, -1.0, 2, 0 }, { 2, 1.0, 1, 0 }, { 2, -1.0, 1, 0 } };
		for (const auto &f : faces) {
			const Vector3 o = center + ax[f.a] * (real_t)h[f.a] * (real_t)f.s;
			const Vector3 up = ax[f.up] * (real_t)hin[f.up];
			const Vector3 side = ax[f.side] * (real_t)hin[f.side];
			quad(o - side - up, o + side - up, o + side + up, o - side + up, ax[f.a] * (real_t)f.s);
		}
		for (int a = 0; a < 3; ++a) {
			for (int b = a + 1; b < 3; ++b) {
				const int k = 3 - a - b;
				for (double sa : { -1.0, 1.0 }) {
					for (double sb : { -1.0, 1.0 }) {
						Vector3 g0;
						g0[a] = (real_t)sa;
						g0[b] = (real_t)sb;
						g0[k] = -1.0;
						Vector3 g1 = g0;
						g1[k] = 1.0;
						const Vector3 na = ax[a] * (real_t)sa;
						const Vector3 nb = ax[b] * (real_t)sb;
						const Vector3 a0 = fv(a, sa, g0), a1 = fv(a, sa, g1);
						const Vector3 b0 = fv(b, sb, g0), b1 = fv(b, sb, g1);
						const double len_k = hin[k] * 2.0;
						tri(a0, a1, b1, na, na, nb, Vector2(), Vector2((real_t)len_k, 0), Vector2((real_t)len_k, (real_t)-c));
						tri(a0, b1, b0, na, nb, nb, Vector2(), Vector2((real_t)len_k, (real_t)-c), Vector2(0, (real_t)-c));
					}
				}
			}
		}
		for (int i = 0; i < 8; ++i) {
			const Vector3 g((i & 1) ? 1.0 : -1.0, (i & 2) ? 1.0 : -1.0, (i & 4) ? 1.0 : -1.0);
			const Vector3 vx = fv(0, g.x, g), vy = fv(1, g.y, g), vz = fv(2, g.z, g);
			tri(vx, vy, vz, ax[0] * g.x, ax[1] * g.y, ax[2] * g.z, Vector2(), Vector2((real_t)c, 0), Vector2(0, (real_t)-c));
		}
	}
};

template <typename P, typename T>
P pack(const std::vector<T> &values) {
	P out;
	out.resize((int64_t)values.size());
	if (!values.empty()) std::memcpy(out.ptrw(), values.data(), values.size() * sizeof(T));
	return out;
}
} // namespace

Array LandmarkKernels::boxes(const PackedVector3Array &centers, const PackedVector3Array &sizes,
		const PackedFloat64Array &bevels, const Basis &basis) {
	Sink sink;
	const int64_t count = std::min(centers.size(), std::min(sizes.size(), bevels.size()));
	for (int64_t i = 0; i < count; ++i) {
		if (bevels[i] > 0.001) sink.bevel_box(centers[i], sizes[i], basis, bevels[i]);
		else sink.sharp_box(centers[i], sizes[i], basis);
	}
	Array out;
	out.push_back(pack<PackedVector3Array>(sink.v));
	out.push_back(pack<PackedVector3Array>(sink.n));
	out.push_back(pack<PackedVector2Array>(sink.uv));
	return out;
}

void LandmarkKernels::_bind_methods() {
	ClassDB::bind_static_method("LandmarkKernels", D_METHOD("boxes", "centers", "sizes", "bevels", "basis"),
			&LandmarkKernels::boxes);
}

} // namespace godot
