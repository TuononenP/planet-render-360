#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>

namespace godot {

// Ground-texture rasterising in native code (GroundMaterial.class_map's
// scanline fills), rows across every core, same texels as the script.
class GroundKernels : public Object {
	GDCLASS(GroundKernels, Object)

protected:
	static void _bind_methods();

public:
	// GroundMaterial._fill_rings over `fills` ([byte, rings] in paint
	// order, later fills on top) into an n x n R8 buffer over an extent
	// of `extent` units centred on the origin.
	static PackedByteArray fill_rings(int n, double extent, const Array &fills);

	// Underpasses.carve's crossings: for each bridge (PackedVector2Array)
	// with layer b_layers[b], each lower way with a smaller layer in way
	// order, the engine's segment_intersects_segment over every segment
	// pair in bridge-then-way order. One PackedFloat64Array per bridge,
	// stride 5: way index, arc position along the bridge and along the
	// way at the hit, and the hit's x and z.
	static Array underpass_hits(const Array &bridges, const Array &ways,
			const PackedInt32Array &b_layers, const PackedInt32Array &w_layers);
};

} // namespace godot
