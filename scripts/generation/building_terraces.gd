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
## A strip piece smaller than this (m²) is a sliver of the outline, and
## a footprint smaller than SPLIT_MIN_AREA_M2 is left whole.
const MIN_AREA_M2 := 4.0
const SPLIT_MIN_AREA_M2 := 30.0
## Times a terrace still too steep is cut again, and the share of its
## parent's buried height above which the parent's cut did not help.
const DEPTH := 2
const NO_GAIN := 0.7
## The plinth a piece across a cliff may stand on, and the mass key that
## carries it to BuildingFoundation.sample.
const CLIFF_TALL_M := 36.0
const PLINTH_KEY := "plinth_tall_m"
## Terrace floors stand on multiples of SNAP_M (half a storey), so two
## side by side are level or a clear step apart, never a sliver of wall;
## and every terrace takes its looks from the whole building's centre
## (SEED_KEY), not its own, so the building stays one colour.
const SNAP_M := 1.6
const SNAP_KEY := "floor_snap_m"
const SEED_KEY := "seed_at"
## A terrace runs at most this far up the slope where the footprint is
## long enough to need more steps than its relief alone asks for.
const STEP_RUN_M := 25.0
const STEP_MIN_RUN_M := 8.0

## `masses` (BuildingMasses.plan) with each standing mass on too steep a
## site replaced by its terraces.
static func split(masses: Array, ground: GroundTruth, sea_y: float) -> Array:
	var out: Array = []
	for mass in masses:
		var md := mass as Dictionary
		var steps := terraces(md, ground, sea_y)
		if steps.is_empty():
			steps = [md]
		for step: Dictionary in steps:
			out.append(_on_cliff(step, ground, sea_y))
	return out

## `md`, with a taller plinth allowed (PLINTH_KEY) when it stands across
## a drop no cut can step up: a retaining wall or a rock face under it.
## The building then shows the drop's height in storeys on its low side,
## as one built against a cliff does, and keeps its floor at the top.
static func _on_cliff(md: Dictionary, ground: GroundTruth, sea_y: float) -> Dictionary:
	if float(md.get("min_m", 0.0)) > 0.0:
		return md
	var m := WorldScale.metres_to_units()
	var footing := BuildingFoundation.sample(ground, md["ring"], md["centre"], sea_y)
	if float(footing["high"]) - float(footing["floor"]) <= (BuildingFoundation.BURY_MAX_M + 0.05) * m:
		return md
	var out := md.duplicate()
	out[PLINTH_KEY] = CLIFF_TALL_M
	return out

## The terraces of `md`, or none when a plinth seats it (or it is a raised
## part or too small to cut). A terrace still too
## steep (the hill curves under a big block) is cut again across its own
## slope, `depth` more times. A courtyard stays a hole in the terraces
## around it.
static func terraces(md: Dictionary, ground: GroundTruth, sea_y: float, depth: int = DEPTH,
		parent: Array = []) -> Array:
	if float(md.get("min_m", 0.0)) > 0.0:
		return []
	var ring: PackedVector2Array = md["ring"]
	var m := WorldScale.metres_to_units()
	if ring.size() < 3 or absf(RingGeometry.signed_area(ring)) < SPLIT_MIN_AREA_M2 * m * m:
		return []
	var footing := BuildingFoundation.sample(ground, ring, md["centre"], sea_y)
	var buried := float(footing["high"]) - float(footing["floor"])
	if buried <= (BuildingFoundation.BURY_MAX_M + 0.05) * m:
		return []
	var uphill := _uphill(ring, ground)
	if not parent.is_empty() and buried > float(parent[1]) * NO_GAIN:
		# The cut that made this strip took little off its relief: the hill
		# runs along it (a spur, a curving street), so cut it the other way.
		uphill = parent[0]
	elif uphill == Vector2.ZERO:
		# A crown or a hollow has no one slope: cut across the long side.
		var box := RingGeometry.aabb(ring)
		uphill = Vector2.RIGHT if box.size.x >= box.size.y else Vector2.DOWN
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
	var span := buried + BuildingFoundation.PLINTH_TALL_M * m
	var steps := clampi(maxi(ceili(span / (STEP_RELIEF_M * m)), ceili((t1 - t0) / (STEP_RUN_M * m))), 2, STEPS_MAX)
	# No terrace shallower than a room: a steeper site is a cliff (_on_cliff).
	steps = mini(steps, floori((t1 - t0) / (STEP_MIN_RUN_M * m)))
	if steps < 2:
		return []
	var pad := 1.0 * m
	var holes: Array = md.get("holes", [])
	var out: Array = []
	for k in steps:
		var a := lerpf(t0, t1, float(k) / float(steps)) - (pad if k == 0 else 0.0)
		var b := lerpf(t0, t1, float(k + 1) / float(steps)) + (pad if k == steps - 1 else 0.0)
		var strip := PackedVector2Array([uphill * a + side * (s0 - pad), uphill * b + side * (s0 - pad),
			uphill * b + side * (s1 + pad), uphill * a + side * (s1 + pad)])
		for cut: Array in _without_holes(Geometry2D.intersect_polygons(ring, strip), holes):
			var piece: PackedVector2Array = cut[0]
			if absf(RingGeometry.signed_area(piece)) < MIN_AREA_M2 * m * m:
				continue
			var step := md.duplicate()
			step["ring"] = piece
			step["holes"] = cut[1]
			step["centre"] = _centroid(piece)
			# Its own walls all round: the neighbours' shared walls were
			# found against the whole footprint, and a stepped block has a
			# flat roof on each terrace.
			step.erase("key")
			step["shape"] = "flat"
			step["rh_m"] = 0.0
			step["terrace"] = k
			step[SNAP_KEY] = SNAP_M
			step[SEED_KEY] = md.get(SEED_KEY, md["centre"])
			var finer := terraces(step, ground, sea_y, depth - 1, [side, buried]) if depth > 0 else []
			if finer.is_empty():
				out.append(step)
			else:
				out.append_array(finer)
	return out

## `pieces` less the courtyards `holes`, as [ring, holes inside it]: a
## courtyard a piece surrounds stays its hole, one on its edge is cut out.
static func _without_holes(pieces: Array, holes: Array) -> Array:
	var out: Array = []
	for piece: PackedVector2Array in pieces:
		if Geometry2D.is_polygon_clockwise(piece):
			continue
		var rings: Array = [piece]
		var inner: Array = []
		for hole: PackedVector2Array in holes:
			var next: Array = []
			for ring: PackedVector2Array in rings:
				var cut := Geometry2D.clip_polygons(ring, hole)
				if cut.any(func(c: PackedVector2Array) -> bool: return Geometry2D.is_polygon_clockwise(c)):
					next.append(ring)
					inner.append(hole)
				else:
					next.append_array(cut)
			rings = next
		for ring: PackedVector2Array in rings:
			out.append([ring, inner.filter(func(h: PackedVector2Array) -> bool:
				return Geometry2D.is_point_in_polygon(h[0], ring))])
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
