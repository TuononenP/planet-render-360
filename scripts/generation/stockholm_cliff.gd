class_name StockholmCliff
extends RefCounted

## Mariaberget and Fjällgatan, Södermalm's granite cliff over Söder Mälarstrand:
## a public stair switching back up the face: granite flights of 0.17 m risers
## across the slope, square landings at the turns, a steel rail on each flight's
## downhill side. It is searched on the real ground at build time, so it stands
## where the cliff really climbs and clear of the mapped steps, buildings and
## carriageways; nothing is built if no clean face fits. The houseboats at the foot are QuayMoorings'
## (its soder_malarstrand row), not repeated here. Stockholm only (RockOutcrops
## calls it), deterministic.

## The search windows (lat, lon, height deg, width deg).
const CLIFF := Rect2(59.3196, 18.0556, 0.0016, 0.0052)
## Stair: columns tried every COLUMN_M, a station every STATION_M; the face
## must climb DROP_M over at most RUN_M, the stair ends where the ground flattens.
const COLUMN_M := 5.0
const STATION_M := 0.3
const MIN_DROP_M := 8.0
const MAX_RUN_M := 70.0
const FLAT_SLOPE := 0.16
const WIDTH_M := 2.0
const RISE_M := 0.17
## Switchbacks: each flight crosses the face SWING_M either side of the fall line
## while climbing HALF_M of it; landings are LANDING_M square; the corridor kept
## clear is the swing plus the landing and a margin; mapped steps stay CLEAR_M off.
const SWING_M := 5.0
const HALF_M := 8.0
const LANDING_M := 2.6
const CLEAR_M := 3.0
## Treads stand on a masonry core down to the ground, at most this deep (metres).
const CORE_M := 4.0

static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask) -> int:
	if not ShoreApron.stockholm(data) or ground == null:
		return 0
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7B746E", 2.0))
	lm.use("Iron", LandmarkMaterials.paint("#2F3437", 0.5, 0.4))
	var stair := find_stair(data, ground, mask)
	var count := 0
	if not stair.is_empty():
		_stair(lm, stair, ground)
		count += 1
		var foot := WorldScale.latlon_from_xz((stair[0]["p"] as Vector2).x, (stair[0]["p"] as Vector2).y, data.latitude, data.longitude)
		print("STOCKHOLM STAIR %d stations, %.1f m climb, foot %.5f %.5f" % [stair.size(),
			float(stair[stair.size() - 1]["y"]) - float(stair[0]["y"]), foot.x, foot.y])
	if count > 0:
		var node := Node3D.new()
		node.name = "StockholmCliff"
		lm.commit(node)
		root.add_child(node)
	return count

static func _box_xz(data: LocationData, box: Rect2) -> Rect2:
	return StockholmShore._xz_box(data, box)

## The stair's ground stations [{p: Vector2, y: float}], bottom to top, from
## the straight north-to-south column that climbs the steepest clean face, or [].
static func find_stair(data: LocationData, ground: GroundTruth, mask: VegetationMask) -> Array:
	var m := WorldScale.metres_to_units()
	var win := _box_xz(data, CLIFF)
	var best: Array = []
	var best_score := -INF
	var steps := _mapped_steps(data)
	var x := win.position.x
	while x <= win.end.x:
		var stations := _column(ground, mask, x, win.position.y, win.end.y, m)
		if stations.size() >= 2:
			var drop := float(stations[stations.size() - 1]["y"]) - float(stations[0]["y"])
			var run := float(stations[stations.size() - 1]["p"].y) - float(stations[0]["p"].y)
			if drop >= MIN_DROP_M * m and absf(run) <= MAX_RUN_M * m and _corridor_clear(mask, stations, steps, m):
				# Taller and steeper; the middle of the cliff ties.
				var score := drop - 0.05 * absf(run) - 0.002 * absf(x - (win.position.x + win.end.x) * 0.5)
				if score > best_score:
					best_score = score
					best = stations
		x += COLUMN_M * m
	return best

## One column x from north (z0, the water) to south (z1): the first station on
## ground above the quay, climbing while the ground stays steep and clean.
static func _column(ground: GroundTruth, mask: VegetationMask, x: float, z0: float, z1: float, m: float) -> Array:
	var out: Array = []
	var step := STATION_M * m
	var z := z0
	var started := false
	var flat := 0
	while z <= z1:
		var y := ground.height_at_world(x, z)
		if not ground.is_inside(x, z) or ground.water_at(x, z) > 0.0:
			if started:
				break
			z += step * 4.0
			continue
		var slope := ground.slope_at(x, z)
		var blocked := mask != null and mask.blocked(x, z, VegetationMask.BUILDING | VegetationMask.ROAD, 1.0)
		if not started:
			# The foot: where the face begins to rise out of the quay's flat.
			if slope >= 0.4 and not blocked:
				started = true
				out.append({"p": Vector2(x, z), "y": y})
			z += step * 4.0
			continue
		if blocked:
			break
		if slope < FLAT_SLOPE * m:
			flat += 1
			if flat > 8:
				break
		else:
			flat = 0
		out.append({"p": Vector2(x, z), "y": y})
		z += step
	return out

## The mapped steps' polylines (OSM class steps).
static func _mapped_steps(data: LocationData) -> Array:
	var out: Array = []
	for r in data.roads:
		if r is Dictionary and str((r as Dictionary).get("class", "")) == "steps":
			out.append((r as Dictionary).get("points", PackedVector2Array()))
	return out

## True when the switchback corridor along `stations` (the swing, the landings
## and a margin either side of the fall line) holds no building or carriageway
## and stays CLEAR_M off every mapped steps way.
static func _corridor_clear(mask: VegetationMask, stations: Array, steps: Array, m: float) -> bool:
	var reach := (SWING_M + LANDING_M + 1.0) * m
	for k in range(0, stations.size(), 7):
		var p: Vector2 = stations[k]["p"]
		for lat in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			var q := p + Vector2(reach * float(lat), 0.0)
			if mask != null and mask.blocked(q.x, q.y, VegetationMask.BUILDING | VegetationMask.ROAD, 1.0):
				return false
			for line: PackedVector2Array in steps:
				for i in line.size() - 1:
					if Geometry2D.get_closest_point_to_segment(q, line[i], line[i + 1]).distance_to(q) < CLEAR_M * m:
						return false
	return true

## The switchback path along the fall line `stations` (bottom to top): flights
## {a, b, n, ya, yb}, and the landings {p, y, dir} (the turn's centre, its
## height and the flight's heading), from the foot's and the head's ground heights.
static func plan(stations: Array, m: float) -> Dictionary:
	var first: Vector2 = stations[0]["p"]
	var last: Vector2 = stations[stations.size() - 1]["p"]
	var y0 := float(stations[0]["y"])
	var y1 := float(stations[stations.size() - 1]["y"])
	var fall := last - first
	var run := fall.length()
	if run < 1.0 or y1 - y0 < RISE_M * m:
		return {}
	var f := fall / run
	var c := Vector2(-f.y, f.x)
	var count := maxi(2, roundi(run / (HALF_M * m)))
	var half := run / float(count)
	var swing := SWING_M * m
	var risers := maxi(count, roundi((y1 - y0) / (RISE_M * m)))
	var flights: Array = []
	var landings: Array = []
	var done := 0
	for k in count:
		var side := -1.0 if k % 2 == 0 else 1.0
		var a := first + f * half * float(k) + c * swing * side
		var b := first + f * half * float(k + 1) - c * swing * side
		# The first flight starts on the fall line's foot, the last ends on its head.
		if k == 0:
			a = first
		if k == count - 1:
			b = last
		var n := roundi(float(risers) * float(k + 1) / float(count)) - done
		var ya := y0 + (y1 - y0) * float(done) / float(risers)
		var yb := y0 + (y1 - y0) * float(done + n) / float(risers)
		flights.append({"a": a, "b": b, "n": n, "ya": ya, "yb": yb})
		if k < count - 1:
			landings.append({"p": b, "y": yb, "dir": (b - a).normalized()})
		done += n
	return {"flights": flights, "landings": landings, "f": f, "c": c}

## The stair: a granite tread per riser on a masonry core down to the ground,
## square landings at the turns, rails on each flight's downhill (foot) side.
static func _stair(lm: LandmarkMesh, stations: Array, ground: GroundTruth) -> void:
	var m := WorldScale.metres_to_units()
	var path := plan(stations, m)
	if path.is_empty():
		return
	var w := WIDTH_M * m
	var f: Vector2 = path["f"]
	for flight: Dictionary in path["flights"]:
		var a: Vector2 = flight["a"]
		var b: Vector2 = flight["b"]
		var n: int = flight["n"]
		if n < 1:
			continue
		var dir := (b - a).normalized()
		var basis := Basis.looking_at(Vector3(dir.x, 0.0, dir.y), Vector3.UP)
		var run := a.distance_to(b) / float(n)
		var side := Vector2(-dir.y, dir.x)
		# The rail stands on the flight's side that faces down the fall line.
		var down := side if side.dot(-f) > 0.0 else -side
		var prev_top := Vector3.INF
		for i in n:
			var t := (float(i) + 0.5) / float(n)
			var p := a.lerp(b, t)
			var top := lerpf(float(flight["ya"]), float(flight["yb"]), (float(i) + 1.0) / float(n))
			_core(lm, p, basis, w, run, top, ground, m)
			if i % 6 == 0 or i == n - 1:
				var q := p + down * (w * 0.5 + 0.05 * m)
				var rail := Vector3(q.x, top + 0.95 * m, q.y)
				if prev_top != Vector3.INF:
					lm.beam("Iron", prev_top, rail, 0.05 * m)
				lm.beam("Iron", Vector3(q.x, top - 0.1 * m, q.y), rail, 0.06 * m)
				prev_top = rail
	for landing: Dictionary in path["landings"]:
		var p: Vector2 = landing["p"]
		var dir: Vector2 = landing["dir"]
		var basis := Basis.looking_at(Vector3(f.x, 0.0, f.y), Vector3.UP)
		var size := LANDING_M * m
		var centre := p
		_core(lm, centre, basis, size, size, float(landing["y"]), ground, m)
		# A rail round the landing's outer and downhill edges.
		var corner_a := centre + Vector2(-size, -size) * 0.5
		var corner_b := centre + Vector2(size, -size) * 0.5
		var corner_c := centre + Vector2(size, size) * 0.5
		var corner_d := centre + Vector2(-size, size) * 0.5
		var top := float(landing["y"]) + 0.95 * m
		var ring := [corner_a, corner_b, corner_c, corner_d]
		for e in 4:
			var u: Vector2 = ring[e]
			var v: Vector2 = ring[(e + 1) % 4]
			var mid := (u + v) * 0.5
			# Open toward the flights; closed on the sides facing down the fall line and beyond the turn.
			if (mid - centre).dot(-f) > 0.1 or (mid - centre).dot(dir) > 0.1:
				lm.beam("Iron", Vector3(u.x, top, u.y), Vector3(v.x, top, v.y), 0.05 * m)
				lm.beam("Iron", Vector3(u.x, top - 0.95 * m, u.y), Vector3(u.x, top, u.y), 0.06 * m)

## One tread's block: top at `top`, down to the lowest ground under it (at most
## CORE_M), so a tread over a drop stands on masonry, not in the air.
static func _core(lm: LandmarkMesh, p: Vector2, basis: Basis, width: float, depth: float, top: float, ground: GroundTruth, m: float) -> void:
	var low := top
	var sx := Vector2(basis.x.x, basis.x.z) * width * 0.5
	var sz := Vector2(basis.z.x, basis.z.z) * depth * 0.5
	for q in [p, p + sx, p - sx, p + sz, p - sz]:
		low = minf(low, ground.height_at_world(q.x, q.y))
	var bottom := maxf(low - 0.2 * m, top - CORE_M * m)
	var h := maxf(top - bottom, 0.1 * m)
	lm.box("Granite", Vector3(p.x, top - h * 0.5, p.y), Vector3(width, h, depth), basis, 0.0)
