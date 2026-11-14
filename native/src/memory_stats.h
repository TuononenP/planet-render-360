#pragma once

#include <godot_cpp/classes/object.hpp>

namespace godot {

// The process's memory as the OS sees it, for MemoryLog: iOS ends an
// app whose footprint reaches its limit, and Godot's own counters miss
// what the GPU driver and the system frameworks hold.
class MemoryStats : public Object {
	GDCLASS(MemoryStats, Object)

protected:
	static void _bind_methods();

public:
	// The footprint the OS counts against the app (phys_footprint on
	// Apple, resident set on Android), in bytes; -1 where unknown.
	static int64_t footprint_bytes();
	// Bytes the app may still use before iOS ends it; -1 elsewhere.
	static int64_t available_bytes();
};

} // namespace godot
