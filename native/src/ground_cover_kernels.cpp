#include "ground_cover_kernels.h"

#include "parallel.h"
#include "photo_sampler.h"
#include "shore_kernels.h"
#include "vegetation_mask_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <vector>

namespace godot {

namespace {

constexpr int HARD_BITS = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5);
constexpr int BIT_BUILDING = 1 << 0;
constexpr int BIT_WATER = 1 << 2;
constexpr int BIT_ROAD_EDGE = 1 << 3;
constexpr int BIT_TREE = 1 << 6;

constexpr double PHOTO_GREEN = 0.07;
constexpr double PHOTO_MIN_LUM = 0.06;
constexpr double PHOTO_NEIGHBOUR_M = 4.0;
constexpr int PHOTO_NEIGHBOURS = 3;
constexpr double EDGE_CLEAR_M = 1.1;
constexpr double PHOTO_ROAD_CLEAR_M = 5.0;
constexpr double EDGE_TALL_M = 3.0;
constexpr double TRUNK_TALL_M = 1.5;
constexpr double SEEDHEAD_SHARE = 0.3;
constexpr int WILD_EXTRA = 2;
constexpr double TUFT_VALUE = 0.8;
constexpr double TURF_GREY = 0.18;

// Class weights [tuft, flower] per class_id (1=grass, 2=cemetery, 3=orchard, 4=forest, 5=wetland).
constexpr double CLASS_W[6][2] = {
	{ 0.0, 0.0 },
	{ 0.95, 0.035 },
	{ 0.85, 0.05 },
	{ 0.80, 0.12 },
	{ 0.45, 0.0 },
	{ 0.90, 0.05 },
};

inline double gc_hash(double x, double z, double salt) {
	const double v = std::sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453;
	return v - std::floor(v);
}

inline double gc_vnoise(double x, double z) {
	const double ix = std::floor(x);
	const double iz = std::floor(z);
	double fx = x - ix;
	double fz = z - iz;
	fx = fx * fx * (3.0 - 2.0 * fx);
	fz = fz * fz * (3.0 - 2.0 * fz);
	const double a = Math::lerp(gc_hash(ix, iz, 11.0), gc_hash(ix + 1.0, iz, 11.0), fx);
	const double b = Math::lerp(gc_hash(ix, iz + 1.0, 11.0), gc_hash(ix + 1.0, iz + 1.0, 11.0), fx);
	return Math::lerp(a, b, fz);
}

inline double gc_smoothstep(double from, double to, double x) {
	if (to == from) {
		return x < from ? 0.0 : 1.0;
	}
	const double t = std::clamp((x - from) / (to - from), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

inline bool gc_photo_green(const Color &c) {
	if (c.a <= 0.0f) {
		return false;
	}
	const double r = c.r, g = c.g, b = c.b;
	const double sum = r + g + b;
	const double gi = (2.0 * g - r - b) / (sum > 0.001 ? sum : 0.001);
	const double lum = r * 0.2126 + g * 0.7152 + b * 0.0722;
	return gi >= PHOTO_GREEN && lum >= PHOTO_MIN_LUM;
}

inline Color gc_rooted(const Color &base, const Color &photo) {
	if (photo.a <= 0.0f) {
		return base;
	}
	const double lb = base.r * 0.2126 + base.g * 0.7152 + base.b * 0.0722;
	const double lp = std::max(photo.r * 0.2126 + photo.g * 0.7152 + photo.b * 0.0722, 0.005);
	const double k = lb / lp;
	const Color target((float)(photo.r * k), (float)(photo.g * k), (float)(photo.b * k), 1.0f);
	return base.lerp(target, 0.6f);
}

inline Color gc_turf(const Color &c) {
	const float l = (float)(c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722);
	return c.lerp(Color(l, l, l, c.a), (float)TURF_GREY);
}

inline double sample_height(const ShoreSampler *shore, const Rect2 &shore_bounds,
		const float *surf, int grid_size, double step_units, double water_level_m,
		double x, double z) {
	if (shore != nullptr) {
		const double cx = std::clamp(x, (double)shore_bounds.position.x, (double)(shore_bounds.position.x + shore_bounds.size.x));
		const double cz = std::clamp(z, (double)shore_bounds.position.y, (double)(shore_bounds.position.y + shore_bounds.size.y));
		return shore->height(cx, cz);
	}
	if (grid_size < 2 || surf == nullptr) {
		return water_level_m;
	}
	const double fx = std::clamp(x / step_units + (double)grid_size * 0.5, 0.0, (double)(grid_size - 1));
	const double fz = std::clamp(z / step_units + (double)grid_size * 0.5, 0.0, (double)(grid_size - 1));
	const int x0 = std::min((int)fx, grid_size - 2);
	const int z0 = std::min((int)fz, grid_size - 2);
	const double tx = fx - (double)x0;
	const double tz = fz - (double)z0;
	const double a = Math::lerp((double)surf[z0 * grid_size + x0], (double)surf[z0 * grid_size + x0 + 1], tx);
	const double b = Math::lerp((double)surf[(z0 + 1) * grid_size + x0], (double)surf[(z0 + 1) * grid_size + x0 + 1], tx);
	return Math::lerp(a, b, tz);
}

struct CoverInst {
	uint8_t kind;
	float x, y, z;
	float scale;
	float yaw;
	float hs;
	float r, g, b, a;
};

} // namespace

Dictionary GroundCoverKernels::build_chunks(const Dictionary &params) {
	Dictionary out;
	out["total"] = 0;
	out["chunks"] = Array();

	Object *mask_obj = Object::cast_to<Object>(params.get("mask", Variant()));
	const VegetationMaskNative *mask = Object::cast_to<VegetationMaskNative>(mask_obj);
	if (mask == nullptr) {
		return out;
	}
	Object *photo_obj = Object::cast_to<Object>(params.get("sampler", Variant()));
	const PhotoSampler *photo_sampler = Object::cast_to<PhotoSampler>(photo_obj);
	Object *shore_obj = Object::cast_to<Object>(params.get("shore_sampler", Variant()));
	const ShoreSampler *shore = Object::cast_to<ShoreSampler>(shore_obj);
	const Rect2 shore_bounds = params.get("shore_bounds", Rect2());

	const PackedFloat32Array surface_arr = params.get("surface", PackedFloat32Array());
	const int grid_size = (int)params.get("grid_size", 0);
	const double step_units = (double)params.get("step_units", 1.0);
	const double water_level_m = (double)params.get("water_level_m", 0.0);
	const float *surf_ptr = (grid_size >= 2 && surface_arr.size() == grid_size * grid_size) ? surface_arr.ptr() : nullptr;

	Object *land_obj = Object::cast_to<Object>(params.get("land_index", Variant()));
	const ShoreDomainIndex *land_idx = Object::cast_to<ShoreDomainIndex>(land_obj);
	const PackedByteArray land_urban = params.get("land_urban", PackedByteArray());
	const uint8_t *urban_ptr = land_urban.ptr();
	const int urban_n = land_urban.size();
	const double half_units = (double)params.get("half_units", 1200.0);

	const PackedByteArray green_cls = params.get("green_cls", PackedByteArray());
	const PackedByteArray green_wild = params.get("green_wild", PackedByteArray());
	const uint8_t *gcls_ptr = green_cls.ptr();
	const uint8_t *gwild_ptr = green_wild.ptr();
	const int green_n = green_cls.size();

	const Vector2 centre = params.get("centre", Vector2());
	const Color grass = params.get("grass", Color(0.26f, 0.42f, 0.11f, 1.0f));
	const double m2u = (double)params.get("m2u", 1.0);
	const double u2m = 1.0 / m2u;
	const double reach = (double)params.get("reach", 0.0);
	const bool full_reach = (bool)params.get("full_reach", false);
	const double sp = (double)params.get("sp", 2.1);
	const bool photo_cover = (bool)params.get("photo_cover", false) && (photo_sampler != nullptr);
	const bool seeds = (bool)params.get("seeds", true);
	const double chunk_u = (double)params.get("chunk_u", 128.0);

	if (reach <= 0.0 || sp <= 0.0) {
		return out;
	}
	const int steps = (int)std::ceil(reach / sp);
	const int total_rows = 2 * steps + 1;
	const double reach2 = reach * reach;
	const float edge_clear = (float)(EDGE_CLEAR_M * m2u);
	const float photo_road_clear = (float)(PHOTO_ROAD_CLEAR_M * m2u);
	const float m2uf = (float)m2u;
	const double photo_nb_r = PHOTO_NEIGHBOUR_M * m2u;

	std::vector<std::vector<CoverInst>> row_out(total_rows);
	parallel_for(total_rows, [&](int r_idx) {
		const int j = r_idx - steps;
		const double fj = (double)j;
		auto &dst = row_out[r_idx];
		for (int i = -steps; i <= steps; ++i) {
			const double fi = (double)i;
			const double h1 = gc_hash(fi, fj, 1.0);
			const double h2 = gc_hash(fi, fj, 2.0);
			const double dx = (fi + h1 - 0.5) * sp;
			const double dz = (fj + h2 - 0.5) * sp;
			const double d2 = dx * dx + dz * dz;
			if (d2 > reach2) {
				continue;
			}
			const double x = (double)centre.x + dx;
			const double z = (double)centre.y + dz;
			const float xf = (float)x;
			const float zf = (float)z;
			const int id = (green_n > 0) ? mask->cover_at(xf, zf) : -1;
			uint8_t cls = 1; // grass
			bool wild = false;
			Color photo(0.0f, 0.0f, 0.0f, 0.0f);
			if (id >= 0 && id < green_n) {
				cls = gcls_ptr[id];
				if (cls == 0 || cls > 5 || mask->blocked(xf, zf, HARD_BITS, edge_clear, m2uf)) {
					continue;
				}
				wild = gwild_ptr[id] != 0;
			} else {
				if (!photo_cover) {
					continue;
				}
				if (mask->blocked(xf, zf, HARD_BITS, edge_clear, m2uf) ||
						mask->blocked(xf, zf, BIT_ROAD_EDGE, photo_road_clear, m2uf)) {
					continue;
				}
				photo = photo_sampler->photo(x, z);
				if (!gc_photo_green(photo)) {
					continue;
				}
				if (land_idx != nullptr && std::abs(x) < half_units && std::abs(z) < half_units) {
					const int lid = land_idx->at(Vector2(xf, zf));
					if (lid >= 0 && lid < urban_n && urban_ptr[lid] != 0) {
						continue;
					}
				}
				if (photo_sampler->green_around(x, z, photo_nb_r, PHOTO_GREEN, PHOTO_MIN_LUM) < PHOTO_NEIGHBOURS) {
					continue;
				}
				wild = !(mask->built_fraction(xf, zf) > 0.04f);
			}
			const double h3 = gc_hash(fi, fj, 3.0);
			const double w0 = CLASS_W[cls][0];
			const double w1 = CLASS_W[cls][1];
			uint8_t kind = 0; // 0=tuft, 1=seedhead, 2=flower, 3=shrub
			if (h3 > w0 + w1) {
				kind = 3;
			} else if (h3 > w0) {
				kind = 2;
			} else if (wild && seeds && gc_hash(fi, fj, 9.0) < SEEDHEAD_SHARE) {
				kind = 1;
			}
			const double d = std::sqrt(d2);
			const bool is_short = (kind == 0 || kind == 1);
			const double r_kind = reach * ((is_short && !full_reach) ? 0.5 : 1.0);
			if (d > r_kind) {
				continue;
			}
			const double clump = gc_vnoise(x * u2m / 6.0, z * u2m / 6.0) * 0.6 +
					gc_vnoise(x * u2m / 19.0 + 7.0, z * u2m / 19.0) * 0.4;
			const double keep = (1.0 - gc_smoothstep(r_kind * 0.85, r_kind, d)) *
					(wild ? (0.75 + 0.5 * clump) : (0.35 + 0.8 * clump));
			if (gc_hash(fi, fj, 4.0) > keep || (kind == 3 && gc_hash(fi, fj, 5.0) > 0.5)) {
				continue;
			}
			const double s = 0.7 + 0.6 * gc_hash(fi, fj, 6.0);
			double hr_x = 0.3, hr_y = 0.55;
			if (wild) {
				hr_x = 0.9;
				hr_y = 1.9;
			} else if (is_short && (mask->blocked(xf, zf, BIT_BUILDING | BIT_WATER, (float)EDGE_TALL_M, m2uf) ||
					mask->blocked(xf, zf, BIT_TREE, (float)TRUNK_TALL_M, m2uf))) {
				hr_x = 0.8;
				hr_y = 1.3;
			}
			double hs = 1.0;
			if (is_short) {
				hs = Math::lerp(hr_x, hr_y, std::clamp(clump * 0.7 + gc_hash(fi, fj, 10.0) * 0.5, 0.0, 1.0));
			}
			const double v = 0.88 + 0.24 * gc_hash(fi, fj, 7.0);
			if (photo.a <= 0.0f && photo_cover) {
				photo = photo_sampler->photo(x, z);
			}
			const Color root = gc_rooted(grass, photo);
			Color col = gc_turf(Color((float)(root.r * v), (float)(root.g * v * (0.95 + 0.1 * h1)), (float)(root.b * v), 1.0f));
			col = Color(col.r * (float)TUFT_VALUE, col.g * (float)TUFT_VALUE, col.b * (float)TUFT_VALUE, 1.0f);
			if (wild) {
				col = col.lerp(Color(col.g * 0.95f, col.g * 0.9f, col.g * 0.45f, 1.0f), (float)(0.12 * clump));
			}
			if (kind == 2) {
				col = Color((float)v, (float)v, (float)v, 1.0f);
			} else if (kind == 3) {
				col = Color((float)(root.r * v * 0.7), (float)(root.g * v * 0.8), (float)(root.b * v * 0.6), 1.0f);
			}
			const double y = sample_height(shore, shore_bounds, surf_ptr, grid_size, step_units, water_level_m, x, z);
			const double yaw = gc_hash(fi, fj, 8.0) * Math::TAU;
			dst.push_back({ kind, xf, (float)y, zf, (float)s, (float)yaw, (float)hs, col.r, col.g, col.b, col.a });
			if (wild && is_short) {
				for (int k = 0; k < WILD_EXTRA; ++k) {
					const double ex = x + (gc_hash(fi, fj, 20.0 + (double)k) - 0.5) * sp;
					const double ez = z + (gc_hash(fi, fj, 30.0 + (double)k) - 0.5) * sp;
					const float exf = (float)ex;
					const float ezf = (float)ez;
					if (mask->blocked(exf, ezf, HARD_BITS, edge_clear, m2uf)) {
						continue;
					}
					if (id < 0 && mask->blocked(exf, ezf, BIT_ROAD_EDGE, photo_road_clear, m2uf)) {
						continue;
					}
					const double eh = Math::lerp(hr_x, hr_y, gc_hash(fi, fj, 40.0 + (double)k));
					const double ey = sample_height(shore, shore_bounds, surf_ptr, grid_size, step_units, water_level_m, ex, ez);
					const double es = s * (0.8 + 0.4 * gc_hash(fi, fj, 50.0 + (double)k));
					const double eyaw = gc_hash(fi, fj, 60.0 + (double)k) * Math::TAU;
					dst.push_back({ kind, exf, (float)ey, ezf, (float)es, (float)eyaw, (float)eh, col.r, col.g, col.b, col.a });
				}
			}
		}
	});

	// Bucket by (kind, cell_x, cell_z) in deterministic row order and pack 16-float MultiMesh buffers.
	struct CellBucket {
		int kind;
		int cx;
		int cz;
		float first_y;
		std::vector<const CoverInst *> items;
	};
	std::map<std::tuple<int, int, int>, int> key_to_idx;
	std::vector<CellBucket> buckets;
	int total = 0;
	for (int r_idx = 0; r_idx < total_rows; ++r_idx) {
		for (const CoverInst &inst : row_out[r_idx]) {
			++total;
			const int cx = (int)std::floor((double)inst.x / chunk_u);
			const int cz = (int)std::floor((double)inst.z / chunk_u);
			const auto key = std::make_tuple((int)inst.kind, cx, cz);
			auto it = key_to_idx.find(key);
			if (it == key_to_idx.end()) {
				const int bi = (int)buckets.size();
				key_to_idx.emplace(key, bi);
				buckets.push_back({ (int)inst.kind, cx, cz, inst.y, {} });
				buckets[bi].items.push_back(&inst);
			} else {
				buckets[it->second].items.push_back(&inst);
			}
		}
	}

	// Preserve kind order 0..3 as GroundCover.build() iterates KINDS.
	Array chunks;
	for (int kind = 0; kind < 4; ++kind) {
		for (const CellBucket &b : buckets) {
			if (b.kind != kind) {
				continue;
			}
			const int n = (int)b.items.size();
			PackedFloat32Array buf;
			buf.resize(n * 16);
			float *w = buf.ptrw();
			const float ox = (float)(((double)b.cx + 0.5) * chunk_u);
			const float oy = b.first_y;
			const float oz = (float)(((double)b.cz + 0.5) * chunk_u);
			for (int k = 0; k < n; ++k) {
				const CoverInst &inst = *b.items[k];
				const float cs = std::cos(inst.yaw);
				const float sn = std::sin(inst.yaw);
				const float s = inst.scale;
				float *p = w + k * 16;
				p[0] = cs * s;  p[1] = 0.0f;           p[2] = sn * s;  p[3] = inst.x - ox;
				p[4] = 0.0f;    p[5] = s * inst.hs;    p[6] = 0.0f;    p[7] = inst.y - oy;
				p[8] = -sn * s; p[9] = 0.0f;           p[10] = cs * s; p[11] = inst.z - oz;
				p[12] = inst.r; p[13] = inst.g;        p[14] = inst.b; p[15] = inst.a;
			}
			Array row;
			row.resize(5);
			row[0] = b.kind;
			row[1] = b.cx;
			row[2] = b.cz;
			row[3] = oy;
			row[4] = buf;
			chunks.append(row);
		}
	}

	out["total"] = total;
	out["chunks"] = chunks;
	return out;
}

void GroundCoverKernels::_bind_methods() {
	ClassDB::bind_static_method("GroundCoverKernels", D_METHOD("build_chunks", "params"), &GroundCoverKernels::build_chunks);
}

} // namespace godot
