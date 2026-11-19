#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace godot {

// BuildingFoundation.plinth's edge loop in native code: the granite face and
// the dressed coping along each downhill footprint edge, in BuildingWalls'
// face arrays, byte-identical with the script (scalars are doubles, vectors
// and stored values float32, as GDScript evaluates them).
class PlinthKernels : public Object {
	GDCLASS(PlinthKernels, Object)

protected:
	static void _bind_methods();

public:
	// Each ring's corners followed by its edge midpoints (the points whose
	// ground BuildingFoundation._edge_grounds reads).
	static PackedVector2Array edge_points(const PackedVector2Array &ring);
	// `rings`: the footprint then its holes; `grounds`: for each ring, the
	// ground at its corners then at its edge midpoints (edge_points order);
	// `ccw`: whether each ring winds counter-clockwise (one byte each);
	// `params`: [metres to units, floor, sink_m, edge_gap_m, coping_min_m,
	// coping_depth_m, coping_proud_m]; `tangents`: write tangents (not in
	// batch mode). Returns [face, coping], each [verts, normals, uvs,
	// tangents, indices].
	static Array plinth(const Array &rings, const Array &grounds, const PackedByteArray &ccw,
			const PackedFloat64Array &params, bool tangents);
};

} // namespace godot
