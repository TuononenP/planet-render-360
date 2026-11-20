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
	if int(row.get("pocks", 0)) > 0:
		_pocks(lm, row, xs, pier_w, spring, rise_k)

## Shrapnel and bullet scars (`pocks` a face): small dark patches on the
## spandrels between the openings and on the parapet's outer face, in a
## fixed pseudo-random scatter so a rebuild looks the same. Drawn with the
## otherwise unused "Concrete" key, dark.
static func _pocks(lm: LandmarkMesh, row: Dictionary, xs: PackedFloat32Array, pier_w: float,
		spring: float, rise_k: float) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#3F3A36", 2.0))
	var clear := float(row["clear"])
	var hz := float(row["width"]) * 0.5 - 0.05
	var h := BridgeParam.half_length(row)
	var seed_v := 20260
	for face in [-1.0, 1.0]:
		var placed := 0
		var tries := 0
		while placed < int(row["pocks"]) and tries < 2000:
			tries += 1
			seed_v = (seed_v * 1103515245 + 12345) & 0x7FFFFFFF
			var u := float((seed_v >> 8) & 0xFFFF) / 65535.0
			seed_v = (seed_v * 1103515245 + 12345) & 0x7FFFFFFF
			var v := float((seed_v >> 8) & 0xFFFF) / 65535.0
			seed_v = (seed_v * 1103515245 + 12345) & 0x7FFFFFFF
			var k := float((seed_v >> 8) & 0xFFFF) / 65535.0
			var x := lerpf(-h + 1.0, h - 1.0, u)
			var on_parapet := k < 0.35
			var y := lerpf(clear + 0.1, clear + BridgeSpec.PARAPET_M - 0.1, v) if on_parapet \
				else lerpf(0.9, clear - 0.7, v)
			if not on_parapet and not _in_wall(xs, x, y, pier_w, spring, rise_k, clear):
				continue
			var z: float = face * (hz + 0.07) if on_parapet else face * (hz + 0.02)
			var w := 0.12 + 0.3 * k
			lm.box("Concrete", Vector3(x, y, z), Vector3(w, w * lerpf(0.45, 1.2, u * v), 0.06), Basis(), 0.0)
			placed += 1

## True when (x, y) on a face is solid wall: not under an arch opening.
static func _in_wall(xs: PackedFloat32Array, x: float, y: float, pier_w: float, spring: float,
		rise_k: float, clear: float) -> bool:
	for i in xs.size() - 1:
		if x < xs[i] or x > xs[i + 1]:
			continue
		var r := (xs[i + 1] - xs[i] - pier_w) * 0.5
		var ry := minf(r * rise_k, clear - 1.2 - spring)
		var u := (x - (xs[i] + xs[i + 1]) * 0.5) / r
		if absf(u) >= 1.0:
			return true
		return y > spring + ry * sqrt(1.0 - u * u) + 0.35
	return true
