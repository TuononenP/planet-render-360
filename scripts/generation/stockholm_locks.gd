class_name StockholmLocks
extends RefCounted

## Slussen's lock chambers (the panes StockholmShore marks `lock_site`) with their
## gates: at both ends of each chamber a pair of steel mitre-gate leaves meeting
## in a shallow point, standing between granite recess piers, with a steel
## walkway beam, handrails and a small gear housing across the top. Simple
## massing, no fittings. Built where the chamber's water ring really has water
## at the gate. Stockholm only (QuayBuilder calls it), deterministic.

## Gate span across the chamber, at most this wide (metres); the leaves' pointed
## apex stands this share of the span down the chamber.
const SPAN_M := 16.0
const APEX := 0.16
## Leaves: thickness, depth below the water and the least height over it.
const LEAF_M := 0.5
const DEPTH_M := 1.6
const MIN_OVER_M := 2.6
const MAX_OVER_M := 4.5
## Piers either side of the gate.
const PIER_M := Vector2(2.2, 2.4)
const MIN_CHAMBER_M := 14.0

static func build(root: Node3D, model: ShorelineModel, data: LocationData) -> int:
	if not ShoreApron.stockholm(data) or model == null or not model.ready:
		return 0
	var lm := LandmarkMesh.new()
	# Weathered grey-green steel over a red-lead foot, light handrails, a near-black slot.
	lm.use("Leaf", LandmarkMaterials.paint("#77887F", 0.6, 0.3))
	lm.use("Foot", LandmarkMaterials.paint("#8C3C30", 0.6, 0.3))
	lm.use("Steel", LandmarkMaterials.paint("#4A5053", 0.5, 0.45))
	lm.use("Rail", LandmarkMaterials.paint("#C5CAC6", 0.5, 0.3))
	lm.use("Slot", LandmarkMaterials.paint("#151617", 0.9, 0.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#5E656B", 2.0))
	var count := 0
	var flagged := 0
	for id in model.domains.bodies.size():
		var body: Dictionary = model.domains.bodies[id]
		if not bool(body.get("lock_site", false)):
			continue
		flagged += 1
		count += _chamber(lm, model, id, body["points"])
	print("STOCKHOLM LOCKS %d chambers, %d gates" % [flagged, count])
	if count == 0:
		return 0
	var node := Node3D.new()
	node.name = "StockholmLocks"
	lm.commit(node)
	root.add_child(node)
	return count

## Gates at the ends of one chamber's long axis; returns how many stood.
static func _chamber(lm: LandmarkMesh, model: ShorelineModel, id: int, ring: PackedVector2Array) -> int:
	var axes := frame(ring)
	if axes.is_empty():
		return 0
	var u: Vector2 = axes["u"]
	var v := Vector2(-u.y, u.x)
	var lo: Vector2 = axes["lo"]
	var hi: Vector2 = axes["hi"]
	if hi.y - lo.y < MIN_CHAMBER_M:
		return 0
	var span := minf(SPAN_M, hi.y - lo.y - 2.0)
	var mid_v := (lo.y + hi.y) * 0.5
	var n := 0
	for end: float in [lo.x, hi.x]:
		var out := 1.0 if end == hi.x else -1.0
		var at: Vector2 = u * (end - out * 1.2) + v * mid_v
		# Water under the gate and its ends, else the ring's corner is no chamber.
		var wet := true
		for k in [-0.5, 0.0, 0.5]:
			var p: Vector2 = at + v * span * float(k)
			wet = wet and model.domains.at(p) >= 0
		if not wet:
			continue
		var level := model.domains.level(id, at)
		var beyond := model.height(at + u * out * 4.0)
		var top := clampf(beyond, level + MIN_OVER_M, level + MAX_OVER_M)
		_gate(lm, at, u * out, v, span, level, top)
		n += 1
	return n

## The chamber's frame: {u (long axis), lo, hi (min and max of (u, v) extents)}, or {}.
static func frame(ring: PackedVector2Array) -> Dictionary:
	var best := 0.0
	var u := Vector2.ZERO
	for i in ring.size():
		var d := ring[(i + 1) % ring.size()] - ring[i]
		if d.length() > best:
			best = d.length()
			u = d / best
	if best < 1.0:
		return {}
	var v := Vector2(-u.y, u.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var q := Vector2(p.dot(u), p.dot(v))
		lo = lo.min(q)
		hi = hi.max(q)
	# The long axis along the longer extent.
	if hi.y - lo.y > hi.x - lo.x:
		return {"u": v, "lo": Vector2(lo.y, -hi.x), "hi": Vector2(hi.y, -lo.x)}
	return {"u": u, "lo": lo, "hi": hi}

## One gate at `at` across `v`, pointing down the chamber along `out`.
static func _gate(lm: LandmarkMesh, at: Vector2, out: Vector2, v: Vector2, span: float, level: float, top: float) -> void:
	var bottom := level - DEPTH_M
	var h := top - bottom
	var apex := at + out * span * APEX
	var wet_top := level + 0.5
	for sgn in [-1.0, 1.0]:
		var foot := at + v * span * 0.5 * float(sgn)
		# The leaf: a red-lead foot to just over the water, grey-green steel above it.
		lm.beam("Foot", Vector3(foot.x, (bottom + wet_top) * 0.5, foot.y), Vector3(apex.x, (bottom + wet_top) * 0.5, apex.y), LEAF_M + 0.04, wet_top - bottom)
		lm.beam("Leaf", Vector3(foot.x, (wet_top + top) * 0.5, foot.y), Vector3(apex.x, (wet_top + top) * 0.5, apex.y), LEAF_M, top - wet_top)
		# The pier, with the gate's recess slot cut into its inner face.
		var pier := foot + v * PIER_M.y * 0.5 * float(sgn)
		var basis := Basis.looking_at(Vector3(v.x, 0.0, v.y), Vector3.UP)
		lm.box("Granite", Vector3(pier.x, bottom + (h + 0.3) * 0.5, pier.y), Vector3(PIER_M.x, h + 0.3, PIER_M.y), basis, 0.0)
		var slot := foot + v * 0.05 * float(sgn)
		lm.box("Slot", Vector3(slot.x, bottom + (h + 0.3) * 0.5, slot.y), Vector3(1.1, h + 0.1, 0.12), basis, 0.0)
	# Walkway beam across the top, rails, and the gear housing.
	var walk_basis := Basis.looking_at(Vector3(v.x, 0.0, v.y), Vector3.UP)
	var c := Vector3(at.x, top + 0.1, at.y)
	var width := span + PIER_M.y * 2.0 - 0.4
	lm.box("Steel", c, Vector3(1.2, 0.22, width), walk_basis, 0.0)
	for sgn in [-1.0, 1.0]:
		var edge := Vector3(at.x + out.x * 0.55 * float(sgn), top + 0.1, at.y + out.y * 0.55 * float(sgn))
		var a := edge + Vector3(v.x, 0.0, v.y) * width * 0.5
		var b := edge - Vector3(v.x, 0.0, v.y) * width * 0.5
		lm.beam("Rail", a + Vector3(0, 1.05, 0), b + Vector3(0, 1.05, 0), 0.09, 0.09)
		lm.beam("Rail", a + Vector3(0, 0.55, 0), b + Vector3(0, 0.55, 0), 0.06, 0.06)
		for k in 7:
			var q := a.lerp(b, float(k) / 6.0)
			lm.beam("Rail", q, q + Vector3(0, 1.05, 0), 0.09, 0.09)
	var housing := Vector3(at.x + out.x * 0.2, top + 0.22 + 0.55, at.y + out.y * 0.2)
	lm.box("Steel", housing, Vector3(1.1, 1.1, 1.3), walk_basis, 0.0)
