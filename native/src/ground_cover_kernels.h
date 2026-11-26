#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

// Native C++17 parallel implementation of GroundCover._scatter() + _chunk()
// 16-float MultiMesh.buffer packing, reading VegetationMaskNative, PhotoSampler,
// ShoreSampler and ShoreDomainIndex directly without GDScript lock contention.
class GroundCoverKernels : public Object {
	GDCLASS(GroundCoverKernels, Object)

protected:
	static void _bind_methods();

public:
	static Dictionary build_chunks(const Dictionary &params);
};

} // namespace godot
