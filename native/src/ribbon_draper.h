#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

#include <vector>

namespace godot {

// RoadBuilder._ribbon and RoadDrape's cuts in native code: the ribbon
// laid on the drawn terrain (RoadBuilder._Surface heights and normals),
// cut along its grid lines and diagonals, welded per ribbon, with the
// script's float32 rounding, so roads are byte-identical either way.
// Set up once per build; ribbon() is safe to call from several threads.
class RibbonDraper : public RefCounted {
	GDCLASS(RibbonDraper, RefCounted)

	std::vector<float> surface;
	int g_size = 0;
	double g_step = 1.0;
	double water_level = 0.0;
	int size = 0;
	double step = 1.0;
	int mesh_size = 0;
	double mesh_step = 1.0;

	double ground_height(double x, double z) const;
	double post(int x, int z) const;
	double mesh_tri(double x, double z) const;

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
	// RoadBuilder._ribbon over `pts` with per-point junction fractions
	// `jf`: [verts, normals, uvs, colors, uv2s, indices], the indices
	// starting at `base` (the batch's vertex count).
	Array ribbon(const PackedVector2Array &pts, double width, double lift, const Color &attr,
			const PackedFloat64Array &jf, double layer, double m2u, int base) const;
};

} // namespace godot
