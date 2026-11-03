#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <unordered_map>
#include <vector>

namespace godot {
class ShoreEvidenceIndex : public RefCounted {
	GDCLASS(ShoreEvidenceIndex, RefCounted)
	struct Feature {
		String kind;
		PackedVector2Array points;
		std::vector<PackedVector2Array> holes;
		Rect2 bounds;
		Variant id;
		double width = 0.0;
		bool area = false;
	};
	std::vector<Feature> features;
	std::unordered_map<int64_t, std::vector<int>> cells;
	std::vector<int> candidates(const Vector2 &p, double radius) const;
	static bool inside(const Vector2 &p, const Feature &f);
	static Vector4 nearest(const Vector2 &p, const Feature &f);
protected:
	static void _bind_methods();
public:
	void setup(const Array &features, const Dictionary &cells);
	bool contains_kind(const Vector2 &p, const String &kind) const;
	Dictionary classify(const Vector2 &a, const Vector2 &b, const Vector2 &land) const;
};
} // namespace godot
