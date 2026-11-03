#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace godot {

// Triangulation of a polygon with holes (earcut: ear clipping with
// z-order hashing, holes bridged into the outline by Eberly's visibility
// rule). Unlike Geometry2D.triangulate_polygon, which knows no holes and
// gives up on any ring that touches itself, it triangulates what it is
// given as well as it can, so generalised map data (islands touching a
// coast or each other) still comes out as a mesh. Keeps no state, so it is
// safe to call from several threads.
class EarcutKernels : public Object {
	GDCLASS(EarcutKernels, Object)

protected:
	static void _bind_methods();

public:
	// Triangle indices (three per triangle) into the vertices of `outer`
	// followed by those of each ring of `holes` (Array of
	// PackedVector2Array), in that order; empty when `outer` has no area.
	static PackedInt32Array triangulate(const PackedVector2Array &outer, const Array &holes);
};

} // namespace godot
