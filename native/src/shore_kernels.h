#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
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

class ShoreDomainIndex;

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
	// BuildingFoundation footing reads (setup_footing): the water bodies,
	// their levels and the dry land grid, as GroundTruth reads them.
	Ref<RefCounted> footing_domains;
	const ShoreDomainIndex *domain_index = nullptr;
	std::vector<double> levels;
	std::vector<float> land;
	Rect2 domain_bounds, height_bounds;
	double height_clamped(const Vector2 &p) const;
	double water_level(const Vector2 &p) const;
	double land_height(const Vector2 &p) const;
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
	void setup_footing(const Ref<RefCounted> &domains, const PackedFloat64Array &levels, const PackedFloat32Array &land,
			const Rect2 &domain_bounds, const Rect2 &height_bounds);
	PackedFloat64Array footing(const PackedVector2Array &ring, const Vector2 &centre, double sea_y, double edge_step, int max_n) const;
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
