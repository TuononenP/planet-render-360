#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

namespace godot {

// PartyWalls' edge and road grid in native code: the same records, cells
// and answers (ring_cover pieces, faces_street) as the script.
class PartyIndex : public RefCounted {
	GDCLASS(PartyIndex, RefCounted)

	struct Edge {
		Vector2 a, b, out;
		int key;
		double top;
	};
	struct Road {
		Vector2 a, b;
		double hw;
	};
	std::vector<Edge> edges;
	std::vector<Road> roads;
	std::unordered_map<int64_t, std::vector<int>> edge_cells, road_cells;
	std::unordered_map<std::string, int> keys;

	int key_id(const String &key);
	void insert(std::unordered_map<int64_t, std::vector<int>> &grid, const Vector2 &a, const Vector2 &b, int rec);
	Array partition(const Vector2 &a, const Vector2 &b, const Vector2 &n, int key) const;

protected:
	static void _bind_methods();

public:
	// PartyWalls._add_ring
	void add_ring(const PackedVector2Array &ring, const String &key, double top, bool hole);
	// PartyWalls.build's road segments (hw already in units).
	void add_road(const Vector2 &a, const Vector2 &b, double hw);
	// PartyWalls.ring_cover
	Array ring_cover(const PackedVector2Array &ring, const String &key, bool hole);
	// PartyWalls.faces_street
	bool faces_street(const Vector2 &a, const Vector2 &b, const Vector2 &n) const;
};

} // namespace godot
