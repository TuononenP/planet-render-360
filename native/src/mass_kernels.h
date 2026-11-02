#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

// Building and city-mass geometry in native code. As FarKernels, each
// function repeats its GDScript twin's arithmetic and float32 rounding,
// so the world is byte-identical with or without the library.
class MassKernels : public Object {
	GDCLASS(MassKernels, Object)

protected:
	static void _bind_methods();

public:
	// MassBatch.tangents: per-vertex tangents from UV gradients.
	static PackedFloat32Array tangents(const PackedVector3Array &v, const PackedVector3Array &n,
			const PackedVector2Array &uv, const PackedInt32Array &idx);
};

} // namespace godot
