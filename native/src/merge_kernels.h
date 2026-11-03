#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

// LodRing.merge_buildings' mesh merge in native code: each group's
// surfaces appended in order, transformed and padded exactly as
// MeshArrays.append does, groups across every core.
class MergeKernels : public Object {
	GDCLASS(MergeKernels, Object)

protected:
	static void _bind_methods();

public:
	// `groups`: per group [srcs, xfs], the kept surface arrays (ARRAY_MAX
	// layout) and a Transform3D each, in append order. Returns per group
	// the merged ARRAY_MAX array (vertex slot null when nothing was
	// appended).
	static Array merge_many(const Array &groups);
};

} // namespace godot
