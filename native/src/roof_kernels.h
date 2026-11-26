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
	// form() over `jobs` ([ring, top, rh, shape, party, gable_front, holes]
	// each) on every core, results in job order.
	static Array form_many(const Array &jobs);
	// RoofGeometry.split_gables in native code: returns [] when no gable
	// triangles exist, else [[rv, rn, ru, rt], [ov, on, ou, ot], [pv, pn, pu, pt]].
	static Array split_gables(const PackedVector3Array &sv, const PackedVector3Array &sn,
			const PackedVector2Array &su, const PackedFloat32Array &st,
			const PackedVector2Array &ring, const PackedByteArray &party,
			double gable_max_y, double gable_uv_scale);
	// BuildingTrim.add mesh arrays in native code: [verts, normals, uvs, tangents, idx].
	static Array trim_arrays(const PackedVector2Array &ring, double top, int trim,
			const PackedByteArray &party, double m2u);
	// BuildingWalls._walls (when edge_materials is empty): returns [face_arr, blank_arr].
	static Array walls_arrays(const PackedVector2Array &ring, double base, double top,
			const Vector3 &uvp, double bay_scale, double v_repeat, const Array &cover,
			bool has_fire, bool is_glass, bool invert, bool use_tangents, double m2u);
	// BuildingWalls._roof_cap: returns [verts, normals, uvs, tangents, idx].
	static Array roof_cap_arrays(const PackedVector2Array &ring, const PackedInt32Array &idx,
			double top, bool use_tangents);
};

} // namespace godot
