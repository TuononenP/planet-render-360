#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

// Far-terrain hot loops in native code, across every core. Each kernel
// repeats its GDScript twin's arithmetic in the same order and rounds
// through float32 where the script goes through Vector2/Vector3, so the
// world is byte-identical with or without the library
// (tools/build_bench.gd checks it).
class FarKernels : public Object {
	GDCLASS(FarKernels, Object)

protected:
	static void _bind_methods();

public:
	// FarTerrainBuilder._ring_bands' vertex positions: loops of
	// 4 * segs vertices around the square rings at `radii`.
	static PackedVector3Array ring_positions(const PackedFloat64Array &radii, int segs,
			const Dictionary &params, const Array &dem_rings);
	// Its normals and colours over those positions: [normals, colors].
	// `water` holds the PolygonIndex objects of the OSM water.
	static Array ring_colors(const PackedVector3Array &pos, int loops, int per,
			const Dictionary &params, const Array &water);
};

} // namespace godot
