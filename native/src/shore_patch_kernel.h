#pragma once
#include "shore_kernels.h"
#include "shore_evidence_kernels.h"
#include <godot_cpp/classes/ref.hpp>
#include <unordered_map>

namespace godot {
class ShorePatchKernel : public RefCounted {
	GDCLASS(ShorePatchKernel, RefCounted)
	struct Level { double start, end; Vector2 a, b; bool profile; double at(Vector2 p) const; };
	struct Bank { Vector2 a, b; double top_a, top_b; int body; bool hard; };
	struct Hash { size_t operator()(const Vector3i &p) const; };
	PackedFloat32Array base, land;
	std::vector<Level> levels;
	std::vector<Bank> banks;
	std::unordered_map<Vector3i, double, Hash> heights;
	Ref<ShoreSampler> sampler;
	Ref<ShoreDomainIndex> domains;
	Ref<ShoreEvidenceIndex> evidence;
	int size = 0;
	double step = 1, origin = 0, depth = 2;
	double grid_height(const PackedFloat32Array &values, Vector2 p) const;
	double vertex_height(Vector2 p, int owner, bool hard);
protected:
	static void _bind_methods();
public:
	void setup(const PackedFloat32Array &base, const PackedFloat32Array &land, const Array &bodies,
		const Array &segments, const Vector4 &grid, const Ref<ShoreSampler> &sampler,
		const Ref<ShoreDomainIndex> &domains, const Ref<ShoreEvidenceIndex> &evidence);
	Dictionary build(const Array &pieces);
	// ShoreSurface.build's cells in `keys` order: each one's transition
	// edges, its raw shore edges cut into the classifier's ~2-unit pieces,
	// the partition, its coverage check and build(). Per key [key, 0, patch],
	// [key, 1, diagnostic] or [key, 2, edges] when the native partition
	// left a gap (the script partitions those).
	Array cells(const Array &keys, const Dictionary &edge_cells, const Dictionary &transition_cells,
		const Array &edges, const Array &transition_edges, Object *abort);
};
}
