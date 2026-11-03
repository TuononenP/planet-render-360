#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

namespace godot {

// MvtReader.read in native code: the Mapbox Vector Tile decoder behind the
// map picker. Repeats the script's reads, integer arithmetic and bounds
// handling, so a tile (truncated or corrupt ones too) decodes to the same
// Dictionary with or without the library. Safe to call from several
// threads: it keeps no state.
class MvtKernels : public Object {
	GDCLASS(MvtKernels, Object)

protected:
	static void _bind_methods();

public:
	// { layer name: { "name", "extent", "features": [{ "type", "tags",
	// "geom" }] } } for the layers in `wanted` (layer name -> Array of
	// tag keys to keep), as MvtReader.read documents.
	static Dictionary read(const PackedByteArray &bytes, const Dictionary &wanted);
};

} // namespace godot
