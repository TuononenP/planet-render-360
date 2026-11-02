#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// RoofGeometry.form_mesh's faces in native code: every roof form
// (ridged, apex, skeleton, domes, skillion, barrel) with the script's
// float32 rounding, so roofs are byte-identical with or without the
// library.
class RoofKernels : public Object {
	GDCLASS(RoofKernels, Object)

protected:
	static void _bind_methods();

public:
	// [verts, normals, uvs, tangents], or [] where form_mesh returns null.
	static Array form(const PackedVector2Array &ring, double top, double rh, const String &shape,
			const PackedByteArray &party, bool gable_front, const Array &holes);
};

} // namespace godot
