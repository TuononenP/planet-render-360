#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

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
};

} // namespace godot
