#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>

#include <unordered_map>
#include <vector>
#include "shore_kernels.h"

namespace godot {

// RoadBuilder._ribbon and RoadDrape's cuts in native code: the ribbon
// laid on the drawn terrain (RoadBuilder._Surface heights and normals),
// cut along its grid lines and diagonals, welded per ribbon, with the
// script's float32 rounding, so roads are byte-identical either way.
// Set up once per build; ribbon() is safe to call from several threads.
class RibbonDraper : public RefCounted {
	GDCLASS(RibbonDraper, RefCounted)

	std::vector<float> surface;
	std::vector<float> shore_posts;
	int g_size = 0;
	double g_step = 1.0;
	double water_level = 0.0;
	int size = 0;
	double step = 1.0;
	int mesh_size = 0;
	double mesh_step = 1.0;
	Ref<ShoreSampler> shore_sampler;
	Ref<ShoreDomainIndex> shore_domains;
	Rect2 shore_bounds;
	bool shore_empty = false;
	bool water_ready = false;
	std::vector<double> body_levels;
	std::vector<float> water_level_grid;
	double half_units = 0.0;
	std::unordered_map<int64_t, std::vector<Vector2>> junc_buckets;
	double junc_m = 1.0;

	double ground_height(double x, double z) const;
	double water_at(double x, double z) const;
	bool inside(const Vector2 &p) const;
	double junction_frac_at(const Vector2 &p) const;
	double post(int x, int z) const;
	double mesh_tri(double x, double z) const;
	Array build(const PackedVector2Array &pts, double width, double lift, const Color &attr,
			const PackedFloat64Array &jf, double layer, double m2u, int base, bool area) const;

protected:
	static void _bind_methods();

public:
	// GroundTruth's surface, size, step and water level, then _Surface's
	// size, step, mesh_size and mesh_step.
	void setup(const PackedFloat32Array &surface, int g_size, double g_step, double water_level,
			int size, double step, int mesh_size, double mesh_step);
	// _Surface.height / normal
	double height(double x, double z) const;
	Vector3 normal(double x, double z) const;
	void set_shore_sampler(const Ref<ShoreSampler> &sampler);
	void set_water_context(const Ref<ShoreDomainIndex> &domains, const Rect2 &bounds, bool empty,
			const PackedFloat64Array &body_levels_in, const PackedFloat32Array &level_in, double half_u);
	void set_junctions(const Dictionary &buckets, double junction_m);
	// RoadBuilder._resample + _dry_runs in one call (or _dry_runs only if max_resample <= 0).
	Array dry_runs(const PackedVector2Array &pts, double max_resample) const;
	// RoadBuilder._straighten
	PackedVector2Array straighten(const PackedVector2Array &pts, double max_len) const;
	// RoadBuilder._ribbon using native junc_buckets when use_junc is true.
	Array ribbon_junc(const PackedVector2Array &pts, double width, double lift, const Color &attr,
			bool use_junc, double layer, double m2u, int base) const;
	// RoadBuilder._ribbon over `pts` with per-point junction fractions
	// `jf`: [verts, normals, uvs, colors, uv2s, indices], the indices
	// starting at `base` (the batch's vertex count).
	Array ribbon(const PackedVector2Array &pts, double width, double lift, const Color &attr,
			const PackedFloat64Array &jf, double layer, double m2u, int base) const;
	Array area(const PackedVector2Array &triangles, double lift, const Color &attr,
			double layer, double m2u, int base) const;
};

} // namespace godot
