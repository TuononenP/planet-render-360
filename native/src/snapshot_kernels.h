#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// OsmbCodec.decode in native code: a bundled snapshot's .osmb payload back
// to Overpass JSON text (format in tools/osmb.py). Writes the same text as
// the script, byte for byte, and "" for a payload that is not a whole
// .osmb. Safe to call from several threads: it keeps no state.
class SnapshotKernels : public Object {
	GDCLASS(SnapshotKernels, Object)

protected:
	static void _bind_methods();

public:
	static String decode_osmb(const PackedByteArray &payload);
};

} // namespace godot
