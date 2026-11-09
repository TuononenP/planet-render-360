class_name BridgeParamMasonry
extends RefCounted

## Multi-arch masonry (or concrete-faced) bridges from a spec row: solid
## spandrel walls pierced by one segmental opening per span
## (LandmarkBrKit.arcade), pointed cutwaters on every pier, the roadway
## between parapets. `rise` is the crown height of the largest opening over
## its springing line's span, so a flatter or rounder arch is a number.

static func build(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var rise := float(row.get("rise", clear * 0.5))
	var widest := 0.0
	for s in row["spans"]:
		widest = maxf(widest, float(s))
	var pier_w := clampf(widest * 0.14, 1.6, 7.0)
	var half_span := (widest - pier_w) * 0.5
	# Every arch keeps the proportions of the widest one; the crown stays
	# a spandrel's thickness (1.2 m, enforced by the kit) under the road.
	var rise_k := minf(rise / half_span, 1.0)
	var spring := maxf(clear - rise - 1.2, 0.4)
	var hz := width * 0.5 - 0.05
	for i in xs.size() - 1:
		LandmarkBrKit.arcade(lm, "Stone", PackedFloat32Array([xs[i], xs[i + 1]]), 0.0, clear, spring,
			rise_k, pier_w, hz, 10)
	# Cutwaters: a pointed nose each side of every interior pier, to the
	# springing line.
	var nose := minf(width * 0.12, 4.0)
	for i in range(1, xs.size() - 1):
		for s in [-1.0, 1.0]:
			var z0: float = s * hz
			lm.poly_prism("Stone", PackedVector2Array([Vector2(xs[i] - pier_w * 0.5, z0),
				Vector2(xs[i], z0 + s * nose), Vector2(xs[i] + pier_w * 0.5, z0)]), 0.0, spring + 0.5)
	var h := BridgeParam.half_length(row)
	lm.box("Deck", Vector3(0, clear + 0.04, 0), Vector3(2.0 * h, 0.08, width - 1.4), Basis(), 0.0)
	BridgeParam.markings(lm, -h, h, clear + 0.08, width - 1.4)
	BridgeParam.parapets(lm, "Stone", -h, h, clear, width)
	# String course under the parapet on both faces.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, clear - 0.35, s * (hz + 0.1)), Vector3(2.0 * h, 0.5, 0.3), Basis(), 0.0)
