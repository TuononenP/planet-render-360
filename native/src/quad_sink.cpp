#include "quad_sink.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

#include <algorithm>
#include <cmath>
#include <cstring>

namespace godot {

namespace {

// GDScript's signf on a double difference of two float32 components.
real_t sign_of(real_t a, real_t b) {
	const double d = (double)a - (double)b;
	return d > 0.0 ? 1.0f : (d < 0.0 ? -1.0f : 0.0f);
}

// ArchitectureStyle._h(seed_v, salt)
double arch_hash(double seed_v, int salt) {
	const double x = std::sin(seed_v * 12.9898 + (double)salt * 78.233) * 43758.5453;
	const double r = std::fmod(x, 1.0);
	return r < 0.0 ? r + 1.0 : r;
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

void QuadSink::rail(const Vector3 &a, const Vector3 &b, real_t h, const Vector3 &n, real_t m) {
	const real_t len_m = a.distance_to(b) / m;
	quad(a, b, b + Vector3(0, h, 0), a + Vector3(0, h, 0), n,
			Vector2(0, 0), Vector2(len_m > 0.3f ? len_m : 0.3f, 1.0f));
}

void QuadSink::granite_plinth(const Vector2 &a, const Vector2 &dir, const Vector2 &n,
		real_t len, real_t y0, real_t h, double seed_v, real_t m) {
	const Vector3 ax(dir.x, 0.0f, dir.y);
	const Vector3 az(n.x, 0.0f, n.y);
	const int count = std::max(1, (int)std::ceil((double)len / (0.95 * (double)m)));
	const real_t rh = h / 3.0f;
	const real_t width = len / (real_t)count;
	const Vector3 sz(width - 0.025f * m, rh - 0.02f * m, 0.18f * m);
	const size_t add_v = (size_t)count * 3 * 24;
	verts.reserve(verts.size() + add_v);
	normals.reserve(normals.size() + add_v);
	uvs.reserve(uvs.size() + add_v);
	indices.reserve(indices.size() + (size_t)count * 3 * 36);
	tangents.reserve(tangents.size() + add_v * 4);
	for (int row = 0; row < 3; row++) {
		const real_t cy = y0 + rh * ((real_t)row + 0.5f);
		for (int j = 0; j < count; j++) {
			const Vector2 c2 = a + dir * width * ((real_t)j + 0.5f);
			const real_t zoff = (real_t)((0.06 + arch_hash(seed_v + (double)j, 94 + row) * 0.04) * (double)m);
			box(Vector3(c2.x, cy, c2.y) + az * zoff, ax, az, sz);
		}
	}
}

void QuadSink::shopfront(const Vector2 &a, const Vector2 &dir, const Vector2 &n,
		real_t ground_y, real_t step_m, real_t height_m, int bays, int door,
		int sign_px, real_t cell, int bays_mod, real_t m) {
	if (bays <= 0) {
		return;
	}
	const Vector3 ax(dir.x, 0.0f, dir.y);
	const Vector3 az(n.x, 0.0f, n.y);
	const real_t sx = step_m / cell;
	const real_t sy = height_m / cell;
	const real_t gy = 12.0f + (real_t)sign_px;
	auto emit = [&](const Vector2 &left, real_t x0, real_t x1, real_t py0, real_t py1, real_t depth_m) {
		const real_t p0 = x0 * sx;
		const real_t p1 = x1 * sx;
		const real_t p2 = (cell - py1) * sy;
		const real_t p3 = (cell - py0) * sy;
		const real_t cx = (p0 + p1) * 0.5f * m;
		const real_t cy = (p2 + p3) * 0.5f * m;
		const real_t depth = depth_m * m;
		box(Vector3(left.x, ground_y + cy, left.y) + ax * cx + az * depth * 0.5f, ax, az,
				Vector3((p1 - p0) * m, (p3 - p2) * m, depth));
	};
	for (int j = 0; j < bays; j++) {
		const Vector2 left = a + dir * (step_m * (real_t)j * m);
		emit(left, 4.0f, cell - 4.0f, 8.0f, 10.0f, 0.12f);
		emit(left, 4.0f, cell - 4.0f, gy - 2.0f, gy, 0.06f);
		if (j % bays_mod == door) {
			emit(left, 40.0f, 44.0f, gy, cell, 0.07f);
			emit(left, 84.0f, 88.0f, gy, cell, 0.07f);
			emit(left, 63.0f, 65.0f, gy, cell, 0.05f);
		} else {
			emit(left, 6.0f, 9.0f, gy, cell - 6.0f, 0.07f);
			emit(left, cell - 9.0f, cell - 6.0f, gy, cell - 6.0f, 0.07f);
			emit(left, 63.0f, 65.0f, gy, cell - 12.0f, 0.05f);
			emit(left, 6.5f, cell - 6.5f, cell - 12.0f, cell, 0.08f);
		}
	}
}

void QuadSink::build_storeys(const Ref<QuadSink> &stone, const Ref<QuadSink> &frame,
		const Ref<QuadSink> &iron, const Ref<QuadSink> &glass, const Ref<QuadSink> &glazed_frame,
		const Vector2 &a, const Vector2 &dir, const Vector2 &n, real_t len_m, int bays,
		const Array &rows, const PackedByteArray &stacks, int flags, double seed_v,
		real_t balconette_prob, real_t deep_balcony_m, real_t m) {
	const bool paris = (flags & 1) != 0;
	const bool punched = (flags & 2) != 0;
	const bool pattern_balcony = (flags & 4) != 0;
	const bool french = (flags & 8) != 0;
	const bool courses = (flags & 16) != 0;
	const bool mullion = (flags & 32) != 0;
	const bool deep = (flags & 64) != 0;
	const bool solid = (flags & 128) != 0;
	const bool quoins = (flags & 256) != 0;
	const bool b_inside = (flags & 512) != 0;
	const bool first_out = (flags & 1024) != 0;
	const bool last_out = (flags & 2048) != 0;

	const Vector3 ax(dir.x, 0.0f, dir.y);
	const Vector3 az(n.x, 0.0f, n.y);
	const real_t len = len_m * m;
	const real_t step = len / (real_t)(bays > 1 ? bays : 1);
	const real_t b_depth = (paris ? 0.55f : 0.8f) * m;
	const uint8_t *st_ptr = stacks.ptr();
	const int64_t st_n = stacks.size();

	const int64_t n_rows = rows.size();
	for (int64_t r = 0; r < n_rows; r++) {
		const Dictionary row = rows[r];
		if ((bool)row["ground"]) {
			continue;
		}
		const real_t y0 = (real_t)(double)row["y0"];
		const real_t y1 = (real_t)(double)row["y1"];
		const bool has_balcony = (bool)row["balcony"];
		const bool has_balconette = (bool)row["balconette"];
		const real_t win_w = (real_t)(double)row["win_w"];
		const real_t win0 = (real_t)(double)row["win0"];
		const real_t win1 = (real_t)(double)row["win1"];
		const int storey = (int)(int64_t)row["storey"];

		if (courses) {
			const real_t cl = len - (b_inside ? 0.12f * m : 0.0f);
			const Vector2 cm = a + dir * (cl * 0.5f);
			frame->box(Vector3(cm.x, y0 + 0.09f * m, cm.y) + az * (0.06f * m), ax, az,
					Vector3(cl, 0.18f * m, 0.12f * m));
		}
		if (has_balcony) {
			const real_t blen = len - (b_inside ? b_depth : 0.0f);
			const real_t slab = (real_t)(double)row["slab"];
			const real_t rail_h = (real_t)(double)row["rail_h"];
			const Vector2 mid = a + dir * (blen * 0.5f);
			const real_t t = 0.16f * m;
			stone->box(Vector3(mid.x, slab - t * 0.5f, mid.y) + az * (b_depth * 0.5f), ax, az,
					Vector3(blen - 0.03f * m, t, b_depth));
			const real_t h = std::clamp(rail_h, 0.8f * m, 1.1f * m);
			const Vector3 f0 = Vector3(a.x, slab, a.y) + az * (b_depth - 0.03f * m) + ax * (0.05f * m);
			const Vector3 f1 = f0 + ax * (blen - 0.1f * m);
			iron->rail(f0, f1, h, az, m);
			iron->rail(Vector3(a.x, slab, a.y) + ax * (0.05f * m), f0, h, -ax, m);
			iron->rail(f1, Vector3(a.x, slab, a.y) + ax * (blen - 0.05f * m), h, ax, m);
		}
		for (int j = 0; j < bays; j++) {
			const Vector2 c = a + dir * (step * ((real_t)j + 0.5f));
			if (mullion) {
				const Vector2 edge = a + dir * (step * (real_t)j);
				frame->box(Vector3(edge.x, (y0 + y1) * 0.5f, edge.y) + az * (0.05f * m),
						ax, az, Vector3(0.10f * m, y1 - y0, 0.10f * m));
			}
			const real_t ww = step * win_w;
			const double hv = arch_hash(seed_v + (double)j * 0.37, 70 + storey);
			const bool glazed_here = (j < st_n) && (st_ptr[j] != 0);
			const bool end_bay = (j == 0 || j == bays - 1);
			if ((deep || glazed_here) && !has_balcony && !end_bay) {
				const real_t w = glazed_here ? step : step * 0.86f;
				const real_t depth = deep_balcony_m * m;
				const real_t t = 0.18f * m;
				const Vector3 base(c.x, y0, c.y);
				const Vector3 up(0, 1, 0);
				stone->box(base + up * (t * 0.5f) + az * (depth * 0.5f), ax, az, Vector3(w, t, depth));
				if (glazed_here) {
					const real_t cap = 0.08f * m;
					const real_t storey_h = y1 - y0;
					const real_t h = storey_h > t + cap + 1.0f * m ? (storey_h - t - cap) : 2.5f * m;
					glass->box(base + up * (t + h * 0.5f) + az * depth, ax, az, Vector3(w - 0.02f * m, h, 0.025f * m));
					stone->box(base + up * (t + h + cap * 0.5f) + az * (depth * 0.5f), ax, az, Vector3(w, cap, depth));
					for (real_t s : { -1.0f, 1.0f }) {
						stone->box(base + up * (t + h * 0.5f) + az * (depth * 0.5f) + ax * (s * (w * 0.5f - 0.05f * m)),
								ax, az, Vector3(0.1f * m, h, depth));
					}
					for (real_t s : { -1.0f, 0.0f, 1.0f }) {
						glazed_frame->box(base + up * (t + h * 0.5f) + az * (depth + 0.02f * m) + ax * (s * w * 0.48f),
								ax, az, Vector3(0.035f * m, h + 0.02f * m, 0.04f * m));
					}
					glazed_frame->box(base + up * (t + 1.0f * m) + az * (depth + 0.02f * m), ax, az,
							Vector3(w, 0.05f * m, 0.03f * m));
				} else if (solid) {
					stone->box(base + up * (t + 0.5f * m) + az * (depth - 0.05f * m), ax, az,
							Vector3(w, 1.0f * m, 0.1f * m));
					const real_t side_d = depth - 0.1f * m;
					for (real_t s : { -1.0f, 1.0f }) {
						stone->box(base + up * (t + 0.5f * m) + az * (side_d * 0.5f) + ax * (s * (w * 0.5f - 0.05f * m)),
								ax, az, Vector3(0.1f * m, 1.0f * m, side_d));
					}
				} else {
					const Vector3 f0 = base + up * t + az * (depth - 0.03f * m) - ax * (w * 0.5f);
					const Vector3 f1 = f0 + ax * w;
					iron->rail(f0, f1, 1.0f * m, az, m);
					iron->rail(f0 - az * (depth - 0.06f * m), f0, 1.0f * m, -ax, m);
					iron->rail(f1, f1 - az * (depth - 0.06f * m), 1.0f * m, ax, m);
				}
				continue;
			}
			const bool rail_here = paris ? has_balconette : (french && hv < (double)balconette_prob);
			if (punched && !has_balcony && !pattern_balcony && !rail_here) {
				stone->box(Vector3(c.x, win0 - 0.04f * m, c.y) + az * (0.07f * m), ax, az,
						Vector3(ww + 0.2f * m, 0.08f * m, 0.14f * m));
			}
			if (rail_here && !has_balcony) {
				const real_t h = std::min(0.9f * m, (win1 - win0) * 0.32f);
				const Vector3 off = az * (0.16f * m);
				const Vector3 p0 = Vector3(c.x, win0, c.y) - ax * (ww * 0.5f + 0.06f * m) + off;
				const Vector3 p1 = Vector3(c.x, win0, c.y) + ax * (ww * 0.5f + 0.06f * m) + off;
				iron->rail(p0, p1, h, az, m);
				stone->box(Vector3(c.x, win0 - 0.03f * m, c.y) + az * (0.09f * m), ax, az,
						Vector3(ww + 0.18f * m, 0.06f * m, 0.18f * m));
			}
		}
	}
	if (quoins && n_rows > 0) {
		const Dictionary r0 = rows[0];
		const Dictionary rl = rows[n_rows - 1];
		const real_t y_lo = (bool)r0["ground"] ? (real_t)(double)r0["y1"] : (real_t)(double)r0["y0"];
		const real_t y_hi = (real_t)(double)rl["y1"];
		const int q_courses = (int)((double)(y_hi - y_lo) / (0.6 * (double)m));
		const Vector2 b_pt = a + dir * len;
		for (int end_i = 0; end_i < 2; end_i++) {
			if (end_i == 0 ? !first_out : !last_out) {
				continue;
			}
			const Vector2 p = end_i == 0 ? a : b_pt;
			const real_t sgn = end_i == 0 ? 1.0f : -1.0f;
			for (int k = 0; k < q_courses; k++) {
				const real_t w = (k % 2 == 0 ? 0.9f : 0.55f) * m;
				const Vector3 c = Vector3(p.x, y_lo + ((real_t)k + 0.5f) * 0.6f * m, p.y)
						+ ax * (sgn * (w * 0.5f + 0.01f * m)) + az * (0.03f * m);
				stone->box(c, ax, az, Vector3(w, 0.52f * m, 0.06f * m));
			}
		}
	}
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
	ClassDB::bind_method(D_METHOD("rail", "a", "b", "h", "n", "m"), &QuadSink::rail);
	ClassDB::bind_method(D_METHOD("is_empty"), &QuadSink::is_empty);
	ClassDB::bind_method(D_METHOD("granite_plinth", "a", "dir", "n", "len", "y0", "h", "seed_v", "m"), &QuadSink::granite_plinth);
	ClassDB::bind_method(D_METHOD("shopfront", "a", "dir", "n", "ground_y", "step_m", "height_m", "bays", "door", "sign_px", "cell", "bays_mod", "m"), &QuadSink::shopfront);
	ClassDB::bind_static_method("QuadSink", D_METHOD("build_storeys", "stone", "frame", "iron", "glass", "glazed_frame", "a", "dir", "n", "len_m", "bays", "rows", "stacks", "flags", "seed_v", "balconette_prob", "deep_balcony_m", "m"), &QuadSink::build_storeys);
	ClassDB::bind_method(D_METHOD("arrays"), &QuadSink::arrays);
}

} // namespace godot
