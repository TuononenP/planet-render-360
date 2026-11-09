class_name BridgeParamArch
extends RefCounted

## Arch bridges from a spec row, one arch per span on elliptical ribs
## (LandmarkBrKit.arch_pts). `arch_deck` carries the road on spandrel
## columns above the ribs, `rise` metres from springing to crown;
## `arch_through` / `arch_tied` put the ribs beside the road, `rise` metres
## over the deck, hung from the ribs on vertical hangers.

const SEG := 16

## Height of the rib centre line at x for an arch centred cx of half-span r.
static func _rib_y(cx: float, spring: float, r: float, ry: float, x: float) -> float:
	var u := clampf((x - cx) / r, -1.0, 1.0)
	return spring + ry * sqrt(maxf(1.0 - u * u, 0.0))

static func _rib(lm: LandmarkMesh, pts: PackedVector2Array, z: float, rib_w: float, t: float) -> void:
	for k in pts.size() - 1:
		lm.beam("Steel", Vector3(pts[k].x, pts[k].y, z), Vector3(pts[k + 1].x, pts[k + 1].y, z), rib_w, t,
			Vector3(0, 0, 1))

static func deck(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var depth := minf(1.2, clear - 0.3)
	var soffit := clear - depth
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var rise := float(row["rise"])
	var zs: Array[float] = [-width * 0.3, width * 0.3]
	if width > 25.0:
		zs = [-width * 0.42, -width * 0.14, width * 0.14, width * 0.42]
	for i in xs.size() - 1:
		if row.has("arch_spans") and not (i in row["arch_spans"]):
			continue
		var span := xs[i + 1] - xs[i]
		var cx := (xs[i] + xs[i + 1]) * 0.5
		var r := span * 0.5
		var t := clampf(span / 45.0, 0.8, 2.5)
		# The springing keeps the whole rib above the water.
		var spring := maxf(soffit - rise, t * 0.5 + 0.05)
		var ry := soffit - t * 0.5 - spring
		var pts := LandmarkBrKit.arch_pts(cx, spring, r, ry, SEG)
		var cols := maxi(int(span / 10.0), 2)
		for z in zs:
			_rib(lm, pts, z, minf(width * 0.18, 3.0), t)
			for k in range(1, cols):
				var x := lerpf(xs[i], xs[i + 1], float(k) / cols)
				var y := _rib_y(cx, spring, r, ry, x)
				if soffit - y > 0.8:
					lm.beam("Steel", Vector3(x, y, z), Vector3(x, soffit, z), 0.6, 0.6)
	BridgeParamBeam.piers(lm, row, maxf(soffit - rise, 0.3) + 0.4)

static func through(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var depth := minf(1.4, clear - 0.3)
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var rise := float(row["rise"])
	var zr := width * 0.5 + 0.3
	for i in xs.size() - 1:
		if row.has("arch_spans") and not (i in row["arch_spans"]):
			continue
		var span := xs[i + 1] - xs[i]
		var cx := (xs[i] + xs[i + 1]) * 0.5
		var r := span * 0.5
		var t := clampf(span / 50.0, 0.9, 2.2)
		var ry := rise - t * 0.5
		var pts := LandmarkBrKit.arch_pts(cx, clear, r, ry, SEG)
		for z in [-zr, zr]:
			_rib(lm, pts, z, 1.2, t)
			var n := maxi(int(span / 8.0), 3)
			for k in range(1, n):
				var x := lerpf(xs[i], xs[i + 1], float(k) / n)
				var y := _rib_y(cx, clear, r, ry, x)
				if y - clear > 1.5:
					lm.beam("Steel", Vector3(x, clear, z), Vector3(x, y, z), 0.35, 0.35)
		# Lateral bracing between the ribs over the crown third of the span.
		for u in [-0.3, -0.15, 0.0, 0.15, 0.3]:
			var x: float = cx + u * span
			var y := _rib_y(cx, clear, r, ry, x)
			if y - clear > 6.0:
				lm.beam("Steel", Vector3(x, y, -zr), Vector3(x, y, zr), 0.5, 0.5)
	BridgeParamBeam.piers(lm, row, clear - depth)
