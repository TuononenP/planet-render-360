class_name BridgeParamMovable
extends RefCounted

## Movable and floating bridges from a spec row. A swing bridge is a girder
## (a through truss over the swing span when `rise` is set) with a drum pier
## under the centre of span `moving`; a vertical-lift bridge adds two lift
## towers on the supports at the ends of span `moving`, joined at the top; a
## pontoon bridge is a deck on one pontoon per span.

static func swing(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var depth := BridgeParamBeam.girder_depth(row)
	var m := int(row["moving"])
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var rise := float(row.get("rise", 0.0))
	if rise > 0.0:
		var cell := clampf(rise * 1.1, 4.0, 12.0)
		var chord := 0.6
		var top := clear + rise - chord * 0.7
		for z in [-width * 0.5 + 0.3, width * 0.5 - 0.3]:
			LandmarkBrKit.truss_side(lm, "Steel", xs[m], xs[m + 1], clear - 0.3, top, z, cell, chord)
	# The drum pier the span turns on, with its fender ring.
	var xc := (xs[m] + xs[m + 1]) * 0.5
	var r := clampf(minf(xs[m + 1] - xs[m], width * 2.0) * 0.12, 2.5, 8.0)
	if clear - depth > 0.8:
		lm.lathe("Concrete", Vector3(xc, 0.0, 0), PackedVector2Array([Vector2(r * 1.25, 0.0),
			Vector2(r * 1.25, 1.0), Vector2(r, 1.3), Vector2(r, clear - depth)]), 20)
	BridgeParamBeam.piers(lm, row, clear - depth)

static func lift(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var top := float(row["tower"])
	var depth := BridgeParamBeam.girder_depth(row)
	var m := int(row["moving"])
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var leg_z := width * 0.5 + 1.5
	for x in [xs[m], xs[m + 1]]:
		LandmarkBrKit.portal_tower(lm, "Steel", x, 0.0, top, leg_z, Vector2(1.8, 1.6), Vector2(1.5, 1.3),
			[clear + 4.0, top - 1.2], 2.4, true, 0.8)
	# The top beam over the lifting span.
	lm.box("Steel", Vector3((xs[m] + xs[m + 1]) * 0.5, top - 1.2, 0),
		Vector3(xs[m + 1] - xs[m], 2.4, 1.6), Basis(), 0.0)
	BridgeParamBeam.piers(lm, row, clear - depth)

static func pontoon(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	BridgeParam.slab(lm, -h, h, clear, width)
	BridgeParam.markings(lm, -h, h, clear, width)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	# One pontoon per span, a little shorter than its bay so the joints show.
	for i in xs.size() - 1:
		var unit := xs[i + 1] - xs[i] - 0.5
		lm.box("Concrete", Vector3((xs[i] + xs[i + 1]) * 0.5, (clear - SLAB_FREE) * 0.5, 0),
			Vector3(unit, clear - SLAB_FREE, width * 0.96), Basis(), 0.0)
	BridgeParam.abutments(lm, row, clear * 0.8)

## Space between the pontoon top and the road surface, metres.
const SLAB_FREE := 0.5
