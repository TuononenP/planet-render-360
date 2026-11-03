#pragma once

#include "shore_kernels.h"
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>

namespace godot {
// Packing and conforming the canonical patches without per-vertex
// GDScript/Variant round trips. The script path remains the reference.
class ShoreMesh : public Object {
	GDCLASS(ShoreMesh, Object)
protected:
	static void _bind_methods();
public:
	static Dictionary stitch(const Dictionary &patches, int size, double step, double origin, Object *abort);
	static Array surface(const Array &source, const Dictionary &patches, int size, double step, double origin,
		const Array &bodies, const Ref<ShoreSampler> &sampler, Object *abort);
	static Array water(const Dictionary &patches, int size, double step, double origin, const Array &bodies,
		const Ref<ShoreDomainIndex> &domains, const PackedFloat32Array &distance, const PackedFloat32Array &hard_distance, const Vector4 &calibration, Object *abort);
};
}
