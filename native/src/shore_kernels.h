#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/vector4.hpp>
#include <unordered_map>
#include <array>
#include <vector>
#include "far_sampling.h"

namespace godot {

// Exact local planar subdivision; same 1 cm rounding as ShoreGeometry.
class ShoreKernels : public Object {
	GDCLASS(ShoreKernels, Object)
protected:
	static void _bind_methods();
public:
	static Array partition(const Rect2 &box, const Array &segments);
};

// Immutable corrected-surface sampler shared by all placement consumers.
class ShoreSampler : public RefCounted {
	GDCLASS(ShoreSampler, RefCounted)
	std::vector<float> surface;
	std::unordered_map<int64_t, std::vector<Vector3>> patches;
	std::unordered_map<int64_t, std::array<std::vector<int>, 16>> patch_cells;
	std::unordered_map<int64_t, std::vector<Vector3>> dry_patches;
	struct Bank { Vector2 a, b; bool hard; };
	std::vector<Bank> banks;
	std::unordered_map<int64_t, std::vector<int>> bank_cells;
	int size = 0;
	double step = 1.0;
	double origin = 0.0;
	Vector2 y_range;
protected:
	static void _bind_methods();
public:
	void setup(const PackedFloat32Array &surface, const Dictionary &patches, int size, double step, double origin);
	double height(double x, double z) const;
	PackedFloat32Array grid_heights() const;
	void setup_banks(const Array &segments);
	Vector4 nearest_bank(const Vector2 &point, int treatment = 0) const;
	const std::vector<Vector3> *dry_triangles(double x, double z) const;
	Vector2 height_range() const;
};

class ShoreDomainIndex : public RefCounted {
	GDCLASS(ShoreDomainIndex, RefCounted)
	std::vector<far::Poly> polygons;
	std::unordered_map<int64_t, std::vector<int>> cells;
protected:
	static void _bind_methods();
public:
	void setup(const Array &bodies, const Dictionary &cells);
	void setup_polygons(const Array &indices, const Rect2 &bounds);
	int at(const Vector2 &point, int exclude = -1) const;
	Array outside_runs(const Vector2 &a, const Vector2 &b) const;
};
} // namespace godot
