class_name BuildingTerraces
extends RefCounted

## A building on ground steeper than a plinth can take steps up the hill
## in terraces, as hillside blocks do: its footprint is cut across the
## slope into strips, each with its own floor. One floor across 20-40 m
## of relief (a Monaco cliff street) buried the uphill half of the
## building, ground floor and all.

## Relief one terrace takes; under PLINTH_TALL_M + BURY_MAX_M, so each
## strip seats like an ordinary hillside building.
const STEP_RELIEF_M := 8.0
## Most terraces a footprint is cut into.
const STEPS_MAX := 6
## A strip piece smaller than this (m²) is a sliver of the outline.
const MIN_AREA_M2 := 4.0

## `masses` (BuildingMasses.plan) with each standing mass on too steep a
## site replaced by its terraces.
static func split(masses: Array, ground: GroundTruth, sea_y: float) -> Array:
	var out: Array = []
	for mass in masses:
		var md := mass as Dictionary
		var steps := terraces(md, ground, sea_y)
		if steps.is_empty():
			out.append(md)
		else:
			out.append_array(steps)
	return out

## The terraces of `md`, or none when a plinth seats it (or it is a raised
## part, a courtyard block or a waterfront building). A terrace still too
## steep (the hill curves under a big block) is cut again across its own
## slope, `depth` more times.
static func terraces(md: Dictionary, ground: GroundTruth, sea_y: float, depth: int = 1) -> Array:
	if float(md.get("min_m", 0.0)) > 0.0 or not (md.get("holes", []) as Array).is_empty():
		return []
	var ring: PackedVector2Array = md["ring"]
	if ring.size() < 3:
		return []
	var m := WorldScale.metres_to_units()
	var footing := BuildingFoundation.sample(ground, ring, md["centre"], sea_y)
	var relief := float(footing["high"]) - float(footing["low"])
	if bool(footing["raised"]) or relief <= (BuildingFoundation.PLINTH_TALL_M + BuildingFoundation.BURY_MAX_M) * m:
		return []
	var uphill := _uphill(ring, ground)
	if uphill == Vector2.ZERO:
		return []
	var t0 := INF
	var t1 := -INF
	var s0 := INF
	var s1 := -INF
	var side := uphill.orthogonal()
	for p in ring:
		t0 = minf(t0, p.dot(uphill))
		t1 = maxf(t1, p.dot(uphill))
		s0 = minf(s0, p.dot(side))
		s1 = maxf(s1, p.dot(side))
	var steps := clampi(ceili(relief / (STEP_RELIEF_M * m)), 2, STEPS_MAX)
	var pad := 1.0 * m
	var out: Array = []
	for k in steps:
		var a := lerpf(t0, t1, float(k) / float(steps)) - (pad if k == 0 else 0.0)
		var b := lerpf(t0, t1, float(k + 1) / float(steps)) + (pad if k == steps - 1 else 0.0)
		var strip := PackedVector2Array([uphill * a + side * (s0 - pad), uphill * b + side * (s0 - pad),
			uphill * b + side * (s1 + pad), uphill * a + side * (s1 + pad)])
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(ring, strip):
			if absf(RingGeometry.signed_area(piece)) < MIN_AREA_M2 * m * m:
				continue
			var step := md.duplicate()
			step["ring"] = piece
			step["centre"] = _centroid(piece)
			# Its own walls all round: the neighbours' shared walls were
			# found against the whole footprint, and a stepped block has a
			# flat roof on each terrace.
			step.erase("key")
			step["shape"] = "flat"
			step["rh_m"] = 0.0
			step["terrace"] = k
			var finer := terraces(step, ground, sea_y, depth - 1) if depth > 0 else []
			if finer.is_empty():
				out.append(step)
			else:
				out.append_array(finer)
	return out

## Unit direction up the slope under `ring`: the least-squares plane of
## the ground along its edges.
static func _uphill(ring: PackedVector2Array, ground: GroundTruth) -> Vector2:
	var m := WorldScale.metres_to_units()
	var pts: Array[Vector2] = []
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var n := clampi(ceili(a.distance_to(b) / (4.0 * m)), 1, 24)
		for k in n:
			pts.append(a.lerp(b, float(k) / float(n)))
	var c := Vector2.ZERO
	var hc := 0.0
	var hs := PackedFloat32Array()
	for p in pts:
		var h := ground.height_at_world(p.x, p.y)
		hs.append(h)
		c += p
		hc += h
	c /= float(pts.size())
	hc /= float(pts.size())
	var sxx := 0.0
	var sxz := 0.0
	var szz := 0.0
	var sxh := 0.0
	var szh := 0.0
	for i in pts.size():
		var d := pts[i] - c
		var dh := hs[i] - hc
		sxx += d.x * d.x
		sxz += d.x * d.y
		szz += d.y * d.y
		sxh += d.x * dh
		szh += d.y * dh
	var det := sxx * szz - sxz * sxz
	if absf(det) < 0.000001:
		return Vector2.ZERO
	var g := Vector2((sxh * szz - szh * sxz) / det, (szh * sxx - sxh * sxz) / det)
	return g.normalized() if g.length() > 0.000001 else Vector2.ZERO

static func _centroid(ring: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in ring:
		c += p
	return c / float(ring.size())
