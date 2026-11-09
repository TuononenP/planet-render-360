class_name BridgeParamBeam
extends RefCounted

## Girder, truss and bascule bridges from a spec row. A girder is a
## continuous box under the road on tapering piers (depth a fraction of the
## longest span); a truss is a Warren truss each side of the road, through
## (`rise` over the deck); a bascule has two towers over the piers, the
## walkway between them and the leaves of the opening span as a girder. A
## haunched bridge is a box girder deep over the piers and slender at mid-span
## (optionally on inclined rigid-frame legs). `lower` hangs a second deck under
## a girder or truss (rail below road); `arch_spans` limits a truss to some spans.

## Girder depth, slab included: about 1/18 of the longest span, 1.2..6 m, and
## never more than the clearance leaves.
static func girder_depth(row: Dictionary) -> float:
	return minf(clampf(BridgeSpec.widest_span(row) / 18.0, 1.2, 6.0), float(row["clear"]) - 0.3)

## Piers under every interior support and the abutments, up to the soffit.
static func piers(lm: LandmarkMesh, row: Dictionary, soffit: float) -> void:
	var xs := BridgeParam.supports(row)
	var width := float(row["width"])
	for i in range(1, xs.size() - 1):
		BridgeParam.pier(lm, "Concrete", xs[i], soffit, 1.4 + BridgeSpec.widest_span(row) * 0.01, width * 0.3)
	BridgeParam.abutments(lm, row, soffit)

static func girder(lm: LandmarkMesh, row: Dictionary) -> void:
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var depth := girder_depth(row)
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var lower := float(row.get("lower", 0.0))
	if lower > 0.0:
		_lower_deck(lm, h, width, clear, depth, lower)
	piers(lm, row, clear - depth - lower)

## A second, narrower deck `lower` m under the road, tied to the girder by a
## web plate each side.
static func _lower_deck(lm: LandmarkMesh, h: float, width: float, clear: float, depth: float,
		lower: float) -> void:
	BridgeParam.slab(lm, -h, h, clear - lower, width * 0.9)
	var web := lower - depth
	if web > 0.5:
		for z in [-width * 0.45, width * 0.45]:
			lm.box("Steel", Vector3(0, clear - depth - web * 0.5, z), Vector3(2.0 * h, web, 0.4), Basis(), 0.0)

static func truss(lm: LandmarkMesh, row: Dictionary) -> void:
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var rise := float(row["rise"])
	var depth := minf(1.6, clear - 0.3)
	var lower := float(row.get("lower", 0.0))
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	if lower > 0.0:
		_lower_deck(lm, h, width, clear, depth, lower)
	# At most about 70 cells over the whole length keeps a long viaduct truss in budget.
	var cell := maxf(clampf(rise * 1.1, 4.0, 14.0), 2.0 * h / 70.0)
	var chord := 0.7
	var top := clear + rise - chord * 0.7
	var xs := BridgeParam.supports(row)
	var runs: Array = []
	if row.has("arch_spans"):
		for i in row["arch_spans"]:
			runs.append([xs[int(i)], xs[int(i) + 1]])
	else:
		runs.append([-h, h])
	for run in runs:
		var x0: float = run[0]
		var x1: float = run[1]
		for z in [-width * 0.5 + 0.3, width * 0.5 - 0.3]:
			LandmarkBrKit.truss_side(lm, "Steel", x0, x1, clear - lower - 0.3, top, z, cell, chord)
		# Top lateral struts every second panel keep the two trusses together.
		var n := maxi(int(round((x1 - x0) / (cell * 2.0))), 1)
		for k in n + 1:
			var x := lerpf(x0, x1, float(k) / n)
			lm.beam("Steel", Vector3(x, top, -width * 0.5 + 0.3), Vector3(x, top, width * 0.5 - 0.3), 0.5, 0.5)
	piers(lm, row, clear - depth - lower)

## Variable-depth box girder: deep over the piers (`pier_depth`, default
## span/16), slender at mid-span (`mid_depth`, default span/40), a parabola
## between, stepped in 12 segments a span. With `legs` the interior supports
## are V-shaped inclined legs from the foot at the water to the soffit that far
## each side of the support (rigid frame) instead of piers.
static func haunched(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var widest := BridgeSpec.widest_span(row)
	var room := clear - 0.5
	var pier_d := minf(float(row.get("pier_depth", clampf(widest / 16.0, 1.5, 12.0))), room)
	var mid_d := minf(float(row.get("mid_depth", clampf(widest / 40.0, 1.2, 4.0))), pier_d)
	BridgeParam.slab(lm, -h, h, clear, width)
	BridgeParam.markings(lm, -h, h, clear, width)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var seg := 12
	for i in xs.size() - 1:
		for k in seg:
			var u0 := float(k) / seg
			var u1 := float(k + 1) / seg
			var t := absf(2.0 * (u0 + u1) * 0.5 - 1.0)
			var d := mid_d + (pier_d - mid_d) * t * t
			# The abutment ends are slender.
			if (i == 0 and k < 2) or (i == xs.size() - 2 and k >= seg - 2):
				d = mid_d
			var xa := lerpf(xs[i], xs[i + 1], u0)
			var xb := lerpf(xs[i], xs[i + 1], u1)
			lm.box("Steel", Vector3((xa + xb) * 0.5, clear - BridgeParam.SLAB_M - (d - BridgeParam.SLAB_M) * 0.5, 0),
				Vector3(xb - xa, maxf(d - BridgeParam.SLAB_M, 0.3), width * 0.82), Basis(), 0.0)
	var legs := float(row.get("legs", 0.0))
	if legs > 0.0:
		var soffit := clear - pier_d
		var leg_d := maxf(widest * 0.02, 1.4)
		for i in range(1, xs.size() - 1):
			for s in [-1.0, 1.0]:
				# The foot starts a little above the water so the slanted
				# end face stays out of it.
				lm.beam("Concrete", Vector3(xs[i], leg_d * 0.8, 0), Vector3(xs[i] + s * legs, soffit, 0),
					width * 0.5, leg_d, Vector3(0, 0, 1))
		BridgeParam.abutments(lm, row, clear - mid_d)
	else:
		piers(lm, row, clear - pier_d)

static func bascule(lm: LandmarkMesh, row: Dictionary) -> void:
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var depth := girder_depth(row)
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var xs := BridgeParam.supports(row)
	var tower_top := float(row.get("tower", clear + BridgeSpec.PARAPET_M))
	var key := "Stone" if str(row["material"]) == "stone" else "Steel"
	var towers: Array[float] = []
	if tower_top > clear + 6.0 and xs.size() >= 4:
		towers = [xs[1], xs[xs.size() - 2]]
	elif tower_top > clear + 6.0:
		towers = [xs[1]]
	var cap := minf(tower_top * 0.12, 9.0)
	for x in towers:
		LandmarkBrKit.tapered_box(lm, key, Vector3(x, 0, 0), 6.0, width * 0.46, 4.5, width * 0.4, tower_top - cap)
		lm.spire(key, Vector3(x, tower_top - cap, 0), 4.5, cap, 0.0, 4)
	# The high-level walkway joins the two towers.
	if towers.size() == 2:
		var wy := clear + (tower_top - clear) * 0.62
		lm.box("Steel", Vector3((towers[0] + towers[1]) * 0.5, wy, 0),
			Vector3(towers[1] - towers[0], 2.4, width * 0.5), Basis(), 0.0)
	piers(lm, row, clear - depth)
