class_name ShoreTerrace
extends RefCounted

## Levels the street along a quay's upper wall. The elevation model blurs
## a river and its low quays into the street behind them, so the ground
## there dipped and bumped toward the wall, and the wall's top waved with
## it. Each station of a low quay (ShoreEvidence.quays) or of a bridge's
## abutment on a quayed bank (abutment_runs) takes the street's level from
## further back, and the posts behind the wall blend to it: wholly at the
## wall and in front of it, not at all TERRACE_M behind it. Under a bridge
## the ground between the water's edge and the wall is the abutment.

## How far behind the wall the street is levelled, metres.
const TERRACE_M := 30.0
## The street is wholly level this far behind the wall, metres.
const FULL_M := 10.0
## Where the street's level is read behind the wall, metres.
const PROBES_M := [20.0, 30.0, 45.0]
## The street's level where those fall in water, metres.
const NEAR_PROBES_M := [4.0, 8.0, 12.0]
## Most a DEM river-blur dip behind a quay wall is lifted toward inland
## probes, metres; suppressed when those probes climb a hillside instead.
const MAX_LIFT_M := 2.0
## Stations either side a level is averaged over (2 m apart).
const SMOOTH_STATIONS := 30
## A station levels the posts this far to either side of its line, metres.
const SIDE_M := 2.0

## Grid index -> levelled height for `model`'s dry surface, in its units
## before ground.render_y: the posts on land, and the posts under the river
## between a wall and its water's edge (and a post and a half past it),
## whose dry height the street triangles near the wall interpolate from
## (a blurred valley there pulled the wall's top toward the river).
static func posts(model: ShorelineModel, evidence: ShoreEvidence) -> Dictionary:
	var weights := {}
	var out := {}
	var wet := {}
	var m2u := WorldScale.metres_to_units()
	for group: Array in [evidence.quays, evidence.abutment_runs]:
		for run: Dictionary in group:
			var shore: PackedVector2Array = run["shore"]
			var wall: PackedVector2Array = run["wall"]
			var land: Vector2 = run["land"]
			var id := model.domains.at(shore[shore.size() / 2] - land.normalized() * 0.5 * m2u)
			if id >= 0 and not model.domains.is_quayed(id):
				continue
			var levels := _levels(model, evidence, wall, land, m2u)
			for i in wall.size():
				if is_nan(levels[i]):
					continue
				# From the water's edge: a post just in front of the wall is a
				# corner of the street's triangles behind it (a low quay's walk
				# takes its own height, ShorelineModel._quay_height).
				var front := -shore[i].distance_to(wall[i]) - model.step * 1.5
				_station(model, wall[i], land, front, levels[i], weights, out, wet, m2u)
	return {"heights": out, "wet": wet, "weights": weights}

## The street's level behind each wall station, smoothed along the run;
## NAN where no probe is on open dry ground.
static func _levels(model: ShorelineModel, evidence: ShoreEvidence, wall: PackedVector2Array, land: Vector2,
		m2u: float) -> PackedFloat32Array:
	var raw := PackedFloat32Array()
	for p in wall:
		# Read both the far probes (past a blurred river dip) and the street
		# strip just behind the wall: when the far probes climb a park hill
		# behind the street, keep the street's own level instead of lifting it
		# onto a cliff.
		var far: Array[float] = []
		for d: float in PROBES_M:
			var q := p + land * d * m2u
			if model.bounds.has_point(q) and model.domains.at(q) < 0 and not evidence.contains_kind(q, "building"):
				far.append(model.dry_height(q.x, q.y))
		var near: Array[float] = []
		for d: float in NEAR_PROBES_M:
			var q := p + land * d * m2u
			if model.bounds.has_point(q) and model.domains.at(q) < 0 and not evidence.contains_kind(q, "building"):
				near.append(model.dry_height(q.x, q.y))
		if far.is_empty() and near.is_empty():
			raw.append(NAN)
			continue
		if far.is_empty():
			near.sort()
			raw.append(near[near.size() / 2])
			continue
		var rise := maxf(far[far.size() - 1] - far[0], 0.0) / m2u if far.size() >= 2 else 0.0
		far.sort()
		var far_med := far[far.size() / 2]
		if near.is_empty():
			raw.append(far_med)
			continue
		near.sort()
		var near_med := near[near.size() / 2]
		var max_lift := MAX_LIFT_M * (1.0 - smoothstep(1.2, 2.5, rise)) * m2u
		raw.append(clampf(far_med, near_med - 0.5 * m2u, near_med + max_lift))
	var out := PackedFloat32Array()
	for i in raw.size():
		var sum := 0.0
		var n := 0
		for k in range(maxi(0, i - SMOOTH_STATIONS), mini(raw.size(), i + SMOOTH_STATIONS + 1)):
			if not is_nan(raw[k]):
				sum += raw[k]
				n += 1
		out.append(sum / float(n) if n > 0 else NAN)
	return out

## Blends the dry posts along the line from `front` (behind the wall at
## `at`, negative toward the water) to TERRACE_M behind it toward `level`;
## a post takes the station that weighs most on it.
static func _station(model: ShorelineModel, at: Vector2, land: Vector2, front: float, level: float,
		weights: Dictionary, out: Dictionary, wet: Dictionary, m2u: float) -> void:
	var far := TERRACE_M * m2u
	var side := maxf(SIDE_M * m2u, model.step * 0.75)
	var across := Vector2(-land.y, land.x)
	var box := Rect2(at + land * front, Vector2.ZERO).expand(at + land * far).grow(side)
	var lo := ((box.position - Vector2.ONE * model.origin) / model.step).floor()
	var hi := ((box.end - Vector2.ONE * model.origin) / model.step).ceil()
	for z in range(maxi(0, int(lo.y)), mini(model.size - 1, int(hi.y)) + 1):
		for x in range(maxi(0, int(lo.x)), mini(model.size - 1, int(hi.x)) + 1):
			var q := Vector2(model.origin + float(x) * model.step, model.origin + float(z) * model.step)
			var t := (q - at).dot(land)
			if t < front or t > far or absf((q - at).dot(across)) > side:
				continue
			var w := 1.0 - smoothstep(FULL_M * m2u, far, t)
			var k := z * model.size + x
			if w <= float(weights.get(k, 0.0)):
				continue
			# Water behind the wall is another bank's (an arm round an island).
			var in_water := model.domains.at(q) >= 0
			if in_water and t >= 0.0:
				continue
			weights[k] = w
			out[k] = lerpf(model.dry[k], level, w)
			if in_water:
				wet[k] = true
			else:
				wet.erase(k)
