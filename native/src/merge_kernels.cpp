#include "merge_kernels.h"

#include "parallel.h"

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/transform3d.hpp>

#include <cstring>
#include <vector>

namespace godot {

namespace {

// One source surface: the channels it carries (a null slot is absent).
struct Src {
	PackedVector3Array v, n;
	PackedVector2Array uv, uv2;
	PackedFloat32Array tan;
	PackedColorArray col;
	PackedInt32Array idx;
	bool has_n = false, has_uv = false, has_uv2 = false, has_tan = false, has_col = false,
		 has_idx = false;
	Transform3D xf;
};

bool present(const Array &a, int slot) {
	return a[slot].get_type() != Variant::NIL;
}

template <typename P, typename T>
P packed(const std::vector<T> &v) {
	P out;
	out.resize((int64_t)v.size());
	if (!v.empty()) {
		std::memcpy(out.ptrw(), v.data(), v.size() * sizeof(T));
	}
	return out;
}

// MeshArrays.append over all of a group's surfaces.
Array merge_group(const std::vector<Src> &srcs) {
	std::vector<Vector3> dv, dn;
	std::vector<Vector2> duv, duv2;
	std::vector<float> dt;
	std::vector<Color> dc;
	std::vector<int32_t> di;
	bool d_vert = false, d_n = false, d_uv = false, d_uv2 = false, d_t = false, d_c = false;
	for (const Src &s : srcs) {
		const int64_t count = s.v.size();
		if (count == 0) {
			continue;
		}
		const int64_t base = d_vert ? (int64_t)dv.size() : 0;
		// A channel only one side carries is padded with its neutral value.
		if (base > 0) {
			if (!d_t && s.has_tan) {
				dt.assign((size_t)base * 4, 0.0f);
				for (int64_t i = 0; i < base; i++) {
					dt[i * 4] = 1.0f;
					dt[i * 4 + 3] = 1.0f;
				}
				d_t = true;
			}
			if (!d_c && s.has_col) {
				dc.assign((size_t)base, Color(1, 1, 1, 1));
				d_c = true;
			}
		}
		const bool pad_tan = !s.has_tan && d_t;
		const bool pad_col = !s.has_col && d_c;
		d_vert = true;
		const Vector3 *sv = s.v.ptr();
		const Transform3D &xf = s.xf;
		const Basis &nb = xf.basis;
		const Transform3D nxf(nb, Vector3());
		for (int64_t i = 0; i < count; i++) {
			dv.push_back(xf.xform(sv[i]));
		}
		if (s.has_n) {
			const Vector3 *sn = s.n.ptr();
			for (int64_t i = 0; i < s.n.size(); i++) {
				dn.push_back(nxf.xform(sn[i]));
			}
			d_n = true;
		}
		if (s.has_tan || pad_tan) {
			// A padded source carries the neutral tangent, transformed
			// like a real one (MeshArrays._pad runs before the loop).
			const size_t n_t = s.has_tan ? (size_t)s.tan.size() : (size_t)count * 4;
			for (size_t i = 0; i + 3 < n_t; i += 4) {
				Vector3 raw(1, 0, 0);
				float w = 1.0f;
				if (s.has_tan) {
					const float *st = s.tan.ptr();
					raw = Vector3(st[i], st[i + 1], st[i + 2]);
					w = st[i + 3];
				}
				const Vector3 t = nb.xform(raw).normalized();
				dt.push_back(t.x);
				dt.push_back(t.y);
				dt.push_back(t.z);
				dt.push_back(w);
			}
			d_t = true;
		}
		if (s.has_uv) {
			const Vector2 *p = s.uv.ptr();
			duv.insert(duv.end(), p, p + s.uv.size());
			d_uv = true;
		}
		if (s.has_uv2) {
			const Vector2 *p = s.uv2.ptr();
			duv2.insert(duv2.end(), p, p + s.uv2.size());
			d_uv2 = true;
		}
		if (s.has_col || pad_col) {
			if (!s.has_col) {
				dc.insert(dc.end(), (size_t)count, Color(1, 1, 1, 1));
			} else {
				const Color *p = s.col.ptr();
				dc.insert(dc.end(), p, p + s.col.size());
			}
			d_c = true;
		}
		if (s.has_idx) {
			const int32_t *si = s.idx.ptr();
			for (int64_t i = 0; i < s.idx.size(); i++) {
				di.push_back(si[i] + (int32_t)base);
			}
		} else {
			for (int64_t i = 0; i < count; i++) {
				di.push_back((int32_t)(base + i));
			}
		}
	}
	Array out;
	out.resize(Mesh::ARRAY_MAX);
	if (d_vert) {
		out[Mesh::ARRAY_VERTEX] = packed<PackedVector3Array>(dv);
		out[Mesh::ARRAY_INDEX] = packed<PackedInt32Array>(di);
	}
	if (d_n) {
		out[Mesh::ARRAY_NORMAL] = packed<PackedVector3Array>(dn);
	}
	if (d_t) {
		out[Mesh::ARRAY_TANGENT] = packed<PackedFloat32Array>(dt);
	}
	if (d_uv) {
		out[Mesh::ARRAY_TEX_UV] = packed<PackedVector2Array>(duv);
	}
	if (d_uv2) {
		out[Mesh::ARRAY_TEX_UV2] = packed<PackedVector2Array>(duv2);
	}
	if (d_c) {
		out[Mesh::ARRAY_COLOR] = packed<PackedColorArray>(dc);
	}
	return out;
}

} // namespace

Array MergeKernels::merge_many(const Array &groups) {
	const int n = (int)groups.size();
	std::vector<std::vector<Src>> in((size_t)n);
	for (int g = 0; g < n; g++) {
		const Array grp = groups[g];
		const Array srcs = grp[0];
		const Array xfs = grp[1];
		in[g].resize((size_t)srcs.size());
		for (int64_t i = 0; i < srcs.size(); i++) {
			const Array a = srcs[i];
			Src &s = in[g][i];
			s.v = a[Mesh::ARRAY_VERTEX];
			if ((s.has_n = present(a, Mesh::ARRAY_NORMAL))) {
				s.n = a[Mesh::ARRAY_NORMAL];
			}
			if ((s.has_uv = present(a, Mesh::ARRAY_TEX_UV))) {
				s.uv = a[Mesh::ARRAY_TEX_UV];
			}
			if ((s.has_uv2 = present(a, Mesh::ARRAY_TEX_UV2))) {
				s.uv2 = a[Mesh::ARRAY_TEX_UV2];
			}
			if ((s.has_tan = present(a, Mesh::ARRAY_TANGENT))) {
				s.tan = a[Mesh::ARRAY_TANGENT];
			}
			if ((s.has_col = present(a, Mesh::ARRAY_COLOR))) {
				s.col = a[Mesh::ARRAY_COLOR];
			}
			if ((s.has_idx = present(a, Mesh::ARRAY_INDEX))) {
				s.idx = a[Mesh::ARRAY_INDEX];
			}
			s.xf = xfs[i];
		}
	}
	std::vector<Array> res((size_t)n);
	parallel_for(n, [&](int g) { res[g] = merge_group(in[g]); });
	Array out;
	out.resize(n);
	for (int g = 0; g < n; g++) {
		out[g] = res[g];
	}
	return out;
}

void MergeKernels::_bind_methods() {
	ClassDB::bind_static_method("MergeKernels", D_METHOD("merge_many", "groups"), &MergeKernels::merge_many);
}

} // namespace godot
