#pragma once

#include "shore_evidence_kernels.h"
#include "shore_kernels.h"
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

// ShorelineModel._classify in native code, byte-identical with the script:
// each shore edge cut into ~2 unit pieces, each piece's water side, its
// evidence-classified treatment (cached per 10-unit cell and land bearing,
// as the script caches it), its bank tops and water levels, the segment
// cell index and the averaged tops at shared hard ends.
class ShoreClassifier : public RefCounted {
	GDCLASS(ShoreClassifier, RefCounted)

	PackedFloat32Array dry;
	int size = 0;
	double step = 1.0, origin = 0.0, m2u = 1.0;
	Rect2 bounds, domain_bounds;
	Ref<ShoreDomainIndex> domains;
	Ref<ShoreEvidenceIndex> evidence;
	std::vector<double> levels;
	Dictionary abutment_ends;

	int at(Vector2 p) const;
	double level(int body, const Vector2 &p) const;
	double dry_height(const Vector2 &p) const;
	double bank_top(const Vector2 &p, const Vector2 &land) const;
	double abutment_top(const Dictionary &treatment, const Vector2 &mid) const;
	Vector2i cell_at(const Vector2 &p) const;

protected:
	static void _bind_methods();

public:
	// The pre-carve surface (render units) and its grid, the model's and
	// the water domains' bounds, the domain index, the bodies' levels (7
	// per body: level, level_end, has_end, axis start, axis end), the
	// evidence index, its bridge ends by id and metres_to_units.
	void setup(const PackedFloat32Array &dry, int size, double step, double origin, const Rect2 &bounds,
			const Rect2 &domain_bounds, const Ref<ShoreDomainIndex> &domains, const PackedFloat64Array &levels,
			const Ref<ShoreEvidenceIndex> &evidence, const Dictionary &abutment_ends, double m2u);
	// The model's raw edges ({a, b, body}; each gains its "segments"):
	// {segments, cells, diagnostics}, or {aborted: true} once `abort` asks.
	Dictionary classify(const Array &edges, Object *abort);
};

} // namespace godot
