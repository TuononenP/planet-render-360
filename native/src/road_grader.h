#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <vector>

namespace godot {

// RoadGrading.grade's per-road work, byte-identical with the script: the
// profile smooth, the stamps onto the posts (best weight, height and
// distance per post across every road) and the final blend.
class RoadGrader : public RefCounted {
	GDCLASS(RoadGrader, RefCounted)

	PackedFloat32Array src, level;
	int size = 0;
	double step = 1.0, max_shift = 0.0;
	std::vector<float> best_w, best_h, best_d;

protected:
	static void _bind_methods();

public:
	// The ungraded surface, the water levels (INF: dry), the grid and the
	// largest cut or fill.
	void setup(const PackedFloat32Array &src, const PackedFloat32Array &level, int size, double step, double max_shift);
	// RoadGrading._smooth: the valid heights averaged along the line with a
	// tent of `radius` (arc length).
	static PackedFloat32Array smooth(const PackedFloat32Array &heights, const PackedByteArray &valid,
			const PackedFloat32Array &arc, double radius);
	// RoadGrading._stamp at each valid point of the line, in order.
	void stamp_line(const PackedVector2Array &line, const PackedFloat32Array &prof, const PackedByteArray &valid, double half);
	// `surface` eased to the stamped heights by their weights.
	PackedFloat32Array apply(const PackedFloat32Array &surface) const;
};

} // namespace godot
