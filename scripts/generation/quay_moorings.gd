class_name QuayMoorings
extends RefCounted

## Alongside berths at mapped quays or a finalized masonry bank. These
## are procedural harbour dressing, not a claim that OSM mapped a vessel.
## Small craft are steamers, houseboats and the odd large yacht; long,
## straight, deep sea quays (tidal water, a clear fairway) also get up to
## MAX_LINERS cruise liners.
const MAX_BOATS := 24
const GAP_M := 8.0
const MAX_LINERS := 2
const LINER_MIN_RUN_M := 170.0
const LINER_MIN_M := 140.0
const LINER_MAX_M := 300.0
const LINER_SHARE := 0.6
const LINER_RADIUS_M := 1200.0
const LINER_SPACING_M := 400.0
const LINER_DEPTH_M := 2.0
## The hull may not come nearer the eye than this (m).
const LINER_EYE_CLEAR_M := 40.0
const LINER_TURN_RAD := 0.07
const LINER_DEVIATION_M := 3.0

static func plan(data: LocationData, ground: GroundTruth, taken: Dictionary,
		m: float, mask: VegetationMask = null) -> Array:
	var lines: Array = []
	for structure in data.shore_structures:
		if str(structure.get("kind", "")) in ["quay", "retaining_wall"]:
			lines.append({"points": structure["points"], "mapped": true})
	if ground.shoreline != null and ground.shoreline.ready:
		for w in data.waterways:
			if str(w.get("class", "")) == "coastline":
				lines.append({"points": w["points"], "mapped": false})
		for p in data.land_polygons:
			if str(p.get("class", "")) == "water" and not bool(p.get("still_pool", false)):
				var points: PackedVector2Array = p["points"].duplicate()
				if not points.is_empty() and points[0] != points[-1]:
					points.append(points[0])
				lines.append({"points": points, "mapped": false})
	var centre := View360.spawn_xz(data)
	var out: Array = []
	for line in lines:
		var pts: PackedVector2Array = line["points"]
		var total := MarinaBuilder._length(pts)
		var t := 18.0 * m
		while t < total - 18.0 * m:
			var sample := MarinaBuilder._at(pts, t)
			var at: Vector2 = sample[0]
			var dir: Vector2 = sample[1]
			var hash_v := MarinaBuilder._hash(at.x, at.y, 37.0)
			var length := (18.0 + hash_v * 14.0) * m
			t += length + GAP_M * m
			if at.distance_to(centre) > MarinaBuilder.RADIUS_M * m:
				continue
			if not bool(line["mapped"]) and not _hard_span(ground, at, dir, length):
				continue
			var normal := Vector2(-dir.y, dir.x)
			var side := 0.0
			for sign_n in [-1.0, 1.0]:
				if _wet(ground, at + normal * sign_n * 2.0 * m, mask) \
						and not _wet(ground, at - normal * sign_n * 2.0 * m, null):
					side = sign_n
			if side == 0.0:
				continue
			var beam := length * 0.30
			var position := at + normal * side * (beam * 0.5 + 1.4 * m)
			var stern := position - dir * length * 0.5
			var clear := true
			for along in [-0.5, 0.0, 0.5]:
				for across in [-0.5, 0.5]:
					clear = clear and _wet(ground, position + dir * length * along + normal * beam * across, mask)
			if not clear or not MarinaBuilder._claim(taken, stern, dir, length / m, beam / m, m):
				continue
			var y := ground.water_level_at(position.x, position.y)
			out.append([Vector3(position.x, y, position.y), atan2(-dir.y, dir.x), length / (10.0 * m),
				"steam" if hash_v < 0.65 else "houseboat", Color.WHITE])
			if out.size() >= MAX_BOATS:
				return out
	return out

static func _hard_span(ground: GroundTruth, at: Vector2, dir: Vector2, length: float) -> bool:
	for along in [-0.35, 0.0, 0.35]:
		var near: Dictionary = ground.shoreline.nearest(at + dir * length * along, 1)
		if near.is_empty() or float(near["distance"]) > 2.0:
			return false
	return true

static func _wet(ground: GroundTruth, p: Vector2, mask: VegetationMask) -> bool:
	if not ground.is_inside(p.x, p.y) or ground.water_at(p.x, p.y) < MarinaBuilder.MIN_DEPTH_M:
		return false
	if ground.shoreline != null and ground.shoreline.ready:
		var id: int = ground.shoreline.domains.at(p)
		if id >= 0 and bool(ground.shoreline.domains.bodies[id].get("still_pool", false)):
			return false
	return mask == null or not mask.blocked(p.x, p.y,
		VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.ROAD_EDGE, 0.5)

## Cruise liners [centre, yaw, length m, beam m, height m, seed] along long
## straight mapped quays on tidal (sea) water with a clear fairway; each
## claims its berth in `taken` so small craft keep clear.
static func liners(data: LocationData, ground: GroundTruth, taken: Dictionary, m: float,
		mask: VegetationMask = null) -> Array:
	var out: Array = []
	if ground.shoreline == null or not ground.shoreline.ready:
		return out
	var eye := View360.spawn_xz(data)
	for structure in data.shore_structures:
		if str(structure.get("kind", "")) != "quay":
			continue
		for run in _straight_runs(structure["points"], m):
			var a: Vector2 = run[0]
			var b: Vector2 = run[1]
			var run_m := a.distance_to(b) / m
			var dir := (b - a).normalized()
			var pick := MarinaBuilder._hash(a.x, a.y, 91.0)
			if pick >= LINER_SHARE:
				continue
			var length := minf(LINER_MIN_M + (LINER_MAX_M - LINER_MIN_M) * MarinaBuilder._hash(b.x, b.y, 92.0), run_m - 30.0)
			if length < LINER_MIN_M:
				continue
			var beam := length * 0.125
			for frac in [0.5, 0.2, 0.8]:
				var along := (length * 0.5 + 15.0 + (run_m - length - 30.0) * float(frac)) * m
				var berth := _liner_berth(ground, mask, a + dir * along, dir, length, beam, m)
				if berth.is_empty():
					continue
				var c: Vector2 = berth["centre"]
				if c.distance_to(eye) > LINER_RADIUS_M * m or _near_eye(c, dir, length, beam, eye, m) \
						or not _spaced(out, c, m):
					continue
				var bow_dir := dir if MarinaBuilder._hash(c.x, c.y, 93.0) < 0.5 else -dir
				var stern := c - dir * length * 0.5 * m
				if not MarinaBuilder._claim(taken, stern, dir, length, beam, m):
					continue
				out.append([Vector3(c.x, ground.water_level_at(c.x, c.y), c.y), atan2(-bow_dir.y, bow_dir.x),
					length, beam, clampf(length * 0.2, 22.0, 65.0), MarinaBuilder._hash(c.x, c.y, 94.0)])
				break
			if out.size() >= MAX_LINERS:
				return out
	return out

## Chords of `pts` that stay within LINER_DEVIATION_M of a straight line
## with no turn sharper than LINER_TURN_RAD, at least LINER_MIN_RUN_M long.
static func _straight_runs(pts: PackedVector2Array, m: float) -> Array:
	var runs: Array = []
	var i := 0
	while i < pts.size() - 1:
		var j := i + 1
		while j + 1 < pts.size() and _straight(pts, i, j + 1, m):
			j += 1
		if pts[i].distance_to(pts[j]) >= LINER_MIN_RUN_M * m:
			runs.append([pts[i], pts[j]])
		i = j
	return runs

static func _straight(pts: PackedVector2Array, i: int, j: int, m: float) -> bool:
	var chord := (pts[j] - pts[i]).normalized()
	for k in range(i, j):
		var seg := pts[k + 1] - pts[k]
		if seg.length() > 0.0001 and absf(seg.normalized().angle_to(chord)) > LINER_TURN_RAD:
			return false
		var off := absf((pts[k] - pts[i]).cross(chord))
		if off > LINER_DEVIATION_M * m:
			return false
	return true

## A hull rectangle beside the quay at `at`: its centre when one side is deep
## open sea water, clear of buildings and roads, with a fairway beyond.
static func _liner_berth(ground: GroundTruth, mask: VegetationMask, at: Vector2, dir: Vector2,
		length: float, beam: float, m: float) -> Dictionary:
	var normal := Vector2(-dir.y, dir.x)
	for sign_n: float in [-1.0, 1.0]:
		if not _wet(ground, at + normal * sign_n * 4.0 * m, mask) \
				or _wet(ground, at - normal * sign_n * 4.0 * m, null):
			continue
		var c: Vector2 = at + normal * sign_n * (beam * 0.5 + 2.0) * m
		var id: int = ground.shoreline.domains.at(c)
		if id < 0 or not bool(ground.shoreline.domains.bodies[id].get("tidal", false)):
			continue
		var deep := true
		for ix in 11:
			for iz in 3:
				var q := c + dir * (float(ix) / 10.0 - 0.5) * length * m + normal * (float(iz) - 1.0) * beam * 0.5 * m
				deep = deep and _wet(ground, q, mask) and ground.water_at(q.x, q.y) >= LINER_DEPTH_M * m
		var fairway := maxf(beam * 3.0, 100.0)
		var d := beam
		while deep and d <= fairway:
			var q := c + normal * sign_n * d * m
			deep = ground.is_inside(q.x, q.y) and ground.water_at(q.x, q.y) >= 1.0 * m
			d += 20.0
		if deep:
			return {"centre": c, "side": sign_n}
	return {}

## Whether the hull rectangle comes within LINER_EYE_CLEAR_M of the eye.
static func _near_eye(c: Vector2, dir: Vector2, length: float, beam: float, eye: Vector2, m: float) -> bool:
	var rel := eye - c
	var along := absf(rel.dot(dir))
	var across := absf(rel.dot(Vector2(-dir.y, dir.x)))
	return maxf(along - length * 0.5 * m, 0.0) < LINER_EYE_CLEAR_M * m \
		and maxf(across - beam * 0.5 * m, 0.0) < LINER_EYE_CLEAR_M * m

static func _spaced(out: Array, c: Vector2, m: float) -> bool:
	for l in out:
		var q: Vector3 = l[0]
		if Vector2(q.x, q.z).distance_to(c) < LINER_SPACING_M * m:
			return false
	return true
