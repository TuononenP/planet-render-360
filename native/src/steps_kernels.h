#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace godot {

// The loops of StepsGround (flights of steps for GroundTruth) that run over
// a whole place, with the script's own float32 and float64 steps so the
// results match it bit for bit.
class StepsKernels : public Object {
	GDCLASS(StepsKernels, Object)

protected:
	static void _bind_methods();

public:
	// Indices of the roads whose class is "steps" (StepsGround._edges).
	static PackedInt32Array step_roads(const Array &roads);

	// StepsGround._touch: for each node (a flight's end, `nodes`), what the
	// roads passing within `reach` of it say. [bridged, classes]: bridged
	// holds 1 for a node a bridge (bridge tag or layer 1+) touches; classes
	// is one PackedStringArray per node, the distinct classes of the other
	// ways on the ground (not areas, tunnels or steps) that touch it. `cell`
	// is the script's lookup grid, which decides which nodes a point is
	// tested against.
	static Array touch(const Array &roads, const PackedVector2Array &nodes, double cell, double reach);

	// StepsGround._hold_parks from its ring loop on: the parks and squares in
	// `rings` (dictionaries with points and holes) at the foot of a flight
	// (`foot_pos`, its top at `top_pos`; `foot_levels` holds its bottom and
	// top levels, two per foot) are levelled to the foot's bottom, round the
	// posts not under a flight (`under`) nor in water (`level`) nor in a
	// building footprint outside its courtyards (`buildings`). A ring nearer
	// the flight's top than its foot is the terrace it comes down from, left
	// alone. Returns [post indices, new heights] of the posts it changed, for
	// the caller to write into `surface`.
	static Array hold_parks(const PackedFloat32Array &surface, const PackedFloat32Array &level, int size, double step,
			const Array &rings, const Array &buildings, const PackedVector2Array &foot_pos,
			const PackedVector2Array &top_pos, const PackedFloat64Array &foot_levels, const PackedInt32Array &under,
			double reach, double max_area, double slack);
};

} // namespace godot
