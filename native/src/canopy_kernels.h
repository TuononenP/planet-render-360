#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace godot {

// FarCanopy's probe pass in native code: every jittered probe of each
// vegetation cell, its far-drape pixel and the darkness / greenness test,
// byte-identical with the script (scalars are doubles, vectors and colours
// float32, the drape UV through the same lat/lon and Mercator steps as
// FarSurface.drape_uv). Height, species and size stay in script.
class CanopyKernels : public Object {
	GDCLASS(CanopyKernels, Object)

protected:
	static void _bind_methods();

public:
	// `cells`: centres (metres) nearest first with their `dists`; `steps`:
	// FarCanopy.STEPS_M flattened [from_m, step_m, ...]; `drapes`: the
	// finest first, each {bytes: RGB8, w, h, zoom, origin: Vector2, size:
	// Vector2} (those the script skips left out); `lat`, `lon`: the place;
	// `dark`, `min_green`: the survivor test; `cell_m`; `budget`: most
	// survivors wanted. Returns {x, z: PackedFloat64Array, rgb:
	// PackedFloat32Array (3 each), widen: PackedFloat64Array}, one entry per
	// survivor in probe order, stopping at the budget.
	static Dictionary probes(const PackedVector2Array &cells, const PackedFloat64Array &dists,
			const PackedFloat64Array &steps, const Array &drapes, double lat, double lon, double dark,
			double min_green, double cell_m, int64_t budget);
};

} // namespace godot
