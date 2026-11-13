#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

// Per-vertex building tints (WallVariety, RoofVariety), byte-identical
// with the script: scalars are doubles, colours are stored as floats.
class TintKernels : public Object {
	GDCLASS(TintKernels, Object)

protected:
	static void _bind_methods();

public:
	// WallVariety.colours: `c` shaded from foot_shade at `foot` (INF: the
	// lowest vertex) to 1 over `fade`.
	static PackedColorArray wall_colours(const PackedVector3Array &verts, const Color &c, double foot,
			double fade, double foot_shade);
	// RoofVariety.weathered: `c`, on a surface rising at least min_rise
	// darkened to eave_shade at its foot and leaning to moss facing north.
	static PackedColorArray roof_colours(const PackedVector3Array &verts, const PackedVector3Array &normals,
			const Color &c, double min_rise, double eave_shade);
	// The lowest vertex height, INF for none.
	static double min_y(const PackedVector3Array &verts);
};

} // namespace godot
