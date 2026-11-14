#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

// LandmarkMesh primitives emitted in bulk, byte-identical with the script.
class LandmarkKernels : public Object {
	GDCLASS(LandmarkKernels, Object)

protected:
	static void _bind_methods();

public:
	// LandmarkMesh.box for each centre and size in turn (one basis), with
	// the chamfer the script chose for it (bevels: > 0.001 chamfers):
	// [vertices, normals, uvs] in emission order.
	static Array boxes(const PackedVector3Array &centers, const PackedVector3Array &sizes,
			const PackedFloat64Array &bevels, const Basis &basis);
};

} // namespace godot
