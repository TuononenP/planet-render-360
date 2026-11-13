#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>

namespace godot {

// Square-grid filters of BareEarth and UrbanSmooth (size x size posts),
// byte-identical with the script: sums run in doubles and store as floats.
class GridFilters : public Object {
	GDCLASS(GridFilters, Object)

protected:
	static void _bind_methods();

public:
	// BareEarth._rank_filter: separable square min (`lowest`) or max of
	// radius r, clamped at the edges.
	static PackedFloat32Array rank_filter(const PackedFloat32Array &src, int size, int r, bool lowest);
	// BareEarth._dilate: the mask grown by r posts (square, separable).
	static PackedByteArray dilate(const PackedByteArray &src, int size, int r);
	// BareEarth._box_sum: the sum over a (2r+1) window along rows or columns.
	static PackedFloat32Array box_sum(const PackedFloat32Array &src, int size, int r, bool rows);
	// BareEarth.strip's relaxation: `sweeps` in-place passes setting each
	// hole post to the mean of its in-grid 4-neighbours, holes in order.
	static PackedFloat32Array relax(const PackedFloat32Array &filled, const PackedInt32Array &holes, int size, int sweeps);
	// GroundTruth._blur_pass: each post the mean of itself (weight 2) and
	// its 8 neighbours (edge posts clamped), each weighted by
	// exp(-dh² * inv) of its height step dh.
	static PackedFloat32Array edge_blur(const PackedFloat32Array &src, int size, double inv);
	// UrbanSmooth._box: the mean over a half-width r window along rows
	// (`horizontal`) or columns, clipped at the edge.
	static PackedFloat32Array box_mean(const PackedFloat32Array &src, int size, int r, bool horizontal);
};

} // namespace godot
