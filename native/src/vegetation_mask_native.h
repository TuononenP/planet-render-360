#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cstdint>
#include <unordered_map>
#include <vector>

namespace godot {

// Native backing for VegetationMask: polygon scan-conversion onto the
// exclusion/cover rasters and 24 m spatial-bucket road/sidewalk queries.
class VegetationMaskNative : public RefCounted {
	GDCLASS(VegetationMaskNative, RefCounted)

	struct Segment {
		Vector2 a;
		Vector2 b;
		float core;
		float edge;
		float paved;
		uint8_t sides;
	};

	int n = 1;
	float half = 110.0f;
	float cell = 1.0f;
	int block = 16;
	int nb = 1;
	float bucket = 24.0f;

	std::vector<uint8_t> bits;
	std::vector<int32_t> cover;
	std::vector<int32_t> built_blocks;
	std::vector<Segment> segs;
	std::unordered_map<int64_t, std::vector<int>> buckets;

	static inline int64_t bucket_key(int bx, int bz) {
		return (static_cast<int64_t>(bx) << 32) | static_cast<uint32_t>(bz);
	}
	bool near_road(float x, float z, bool want_core, float margin) const;
	bool near_paved(float x, float z, float margin) const;

protected:
	static void _bind_methods();

public:
	void setup(int p_n, float p_half, float p_cell, int p_block, int p_nb, float p_bucket);
	int fill_rings(const Array &rings, int bit, int cov, bool count_built);
	void add_segment(const Vector2 &a, const Vector2 &b, float core, float edge, float paved, int sides);
	void add_polyline(const PackedVector2Array &pts, float core, float edge, float paved, int sides);
	void mark_trees(const Array &positions);
	bool blocked(float x, float z, int mask, float margin_m, float m2u) const;
	int cover_at(float x, float z) const;
	int cover_at_cell(int cx, int cz) const;
	float built_fraction(float x, float z) const;
};

} // namespace godot
