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
const LINER_RADIUS_M := 1200.0
const LINER_SPACING_M := 400.0
const LINER_DEPTH_M := 2.0
## The hull may not come nearer the eye than this (m).
const LINER_EYE_CLEAR_M := 40.0
const LINER_TURN_RAD := 0.12
const LINER_DEVIATION_M := 6.0

## One harbour plan's shared lookups: [data, its ferry terminals, its
## joined quay lines (null until asked for), m]. The terminal test runs
## for every vertex of every coastline and water polygon, twice (liners,
## then cargo berths), and each one scanned every building and POI:
## 2.4 s of a Paris build with no ship to berth. Other data, and calls
## outside a plan, find their own.
static var _scope: Array = []

## Brackets MarinaBuilder.plan for `data`.
static func begin_plan(data: LocationData, m: float) -> void:
	_scope = [data, _terminals(data), null, m]

static func end_plan() -> void:
	_scope = []

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
		var cursor: Array = [0, 0.0]
		while t < total - 18.0 * m:
			var sample := MarinaBuilder._at(pts, t, cursor)
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

## Large vessels [centre, yaw, length m, beam m, height m, seed, kind] along
## mapped quays or terminal banks on tidal water with a clear fairway; each
## claims its berth in `taken` so small craft keep clear.
static func liners(data: LocationData, ground: GroundTruth, taken: Dictionary, m: float,
		mask: VegetationMask = null) -> Array:
	var out: Array = []
	if ground.shoreline == null or not ground.shoreline.ready:
		return out
	var eye := View360.spawn_xz(data)
	var runs: Array = []
	for points in _quay_lines(data, m):
		runs.append_array(_straight_runs(points, m))
	runs.sort_custom(func(a: Array, b: Array) -> bool:
		return _terminal_distance(data, (a[0] + a[1]) * 0.5) < _terminal_distance(data, (b[0] + b[1]) * 0.5))
	for run in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var run_m := a.distance_to(b) / m
		# Canonical direction is independent of the OSM way direction.
		if a.x > b.x or (is_equal_approx(a.x, b.x) and a.y > b.y):
			var swap := a
			a = b
			b = swap
		var dir := (b - a).normalized()
		var ferry := _near_terminal(data, (a + b) * 0.5, m)
		if not ferry and CargoBerths.port_run(data, a, b, m):
			continue  # cargo quays berth cargo ships (CargoBerths)
		var length := minf(200.0 if ferry else 230.0, run_m - 30.0)
		if length < LINER_MIN_M:
			continue
		var beam := length * 0.125
		for frac in [0.5, 0.2, 0.8]:
			var along := (length * 0.5 + 15.0 + (run_m - length - 30.0) * float(frac)) * m
			var at := a + dir * along
			if not _near_terminal(data, at, m) and not _mapped_quay_at(data, at, m):
				continue
			var berth := _liner_berth(ground, mask, at, dir, length, beam, m)
			if berth.is_empty():
				continue
			var c: Vector2 = berth["centre"]
			if c.distance_to(eye) > LINER_RADIUS_M * m or _near_eye(c, dir, length, beam, eye, m) \
					or not _spaced(out, c, m) or _mapped_ship_near(data, c, length, m):
				continue
			var bow_dir := dir
			var stern := c - dir * length * 0.5 * m
			if not MarinaBuilder._claim(taken, stern, dir, length, beam, m):
				continue
			out.append([Vector3(c.x, ground.water_level_at(c.x, c.y), c.y), atan2(-bow_dir.y, bow_dir.x),
				length, beam, clampf(length * 0.21 if ferry else length * 0.2, 22.0, 65.0),
				fposmod(c.x * 0.0131 + c.y * 0.0077, 1.0), "ferry" if ferry else "liner",
				berth_info(ground, a, b, at, berth, beam, m)])
			break
		if out.size() >= MAX_LINERS:
			return out
	return out

## Join nearby quay fragments before looking for straight berths. A gap is
## allowed only when the joined polyline still passes the straightness test.
static func _quay_lines(data: LocationData, m: float) -> Array:
	var scope := _scope
	var scoped: bool = scope.size() == 4 and is_same(scope[0], data) and scope[3] == m
	if scoped and scope[2] != null:
		return scope[2]
	var lines := _join_quay_lines(data, m)
	if scoped:
		scope[2] = lines
	return lines

static func _join_quay_lines(data: LocationData, m: float) -> Array:
	var lines: Array = []
	for structure in data.shore_structures:
		if str(structure.get("kind", "")) == "quay":
			var points: PackedVector2Array = structure.get("points", PackedVector2Array())
			if points.size() >= 2:
				lines.append(points.duplicate())
	# Ferry terminals are sometimes mapped on a coastline or water polygon
	# rather than a separate man_made=quay. Only use such banks near a terminal.
	for w in data.waterways:
		if str(w.get("class", "")) == "coastline":
			_add_terminal_bank(lines, data, w.get("points", PackedVector2Array()), m)
	for poly in data.land_polygons:
		if str(poly.get("class", "")) == "water" and not bool(poly.get("still_pool", false)):
			_add_terminal_bank(lines, data, poly.get("points", PackedVector2Array()), m)
	var changed := true
	while changed:
		changed = false
		for i in lines.size():
			if changed:
				break
			for j in range(i + 1, lines.size()):
				var left: PackedVector2Array = lines[i]
				var right: PackedVector2Array = lines[j]
				var joined := PackedVector2Array()
				var best := 10.0 * m
				for flip_a in [false, true]:
					for flip_b in [false, true]:
						var a := left.duplicate()
						var b := right.duplicate()
						if flip_a: a.reverse()
						if flip_b: b.reverse()
						var gap := a[-1].distance_to(b[0])
						if gap <= best:
							var candidate := a.duplicate()
							if gap < 0.001:
								b.remove_at(0)
							candidate.append_array(b)
							if _straight(candidate, 0, candidate.size() - 1, m):
								joined = candidate
								best = gap
				if not joined.is_empty():
					lines[i] = joined
					lines.remove_at(j)
					changed = true
					break
	return lines

static func _add_terminal_bank(lines: Array, data: LocationData, points: PackedVector2Array, m: float) -> void:
	# Keep contiguous nearby segments together; this avoids joining every
	# individual vertex on detailed coastlines.
	var run := PackedVector2Array()
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var mid := (a + b) * 0.5
		if _near_terminal(data, mid, m) and not _mapped_quay_at(data, mid, m):
			if run.is_empty():
				run.append(a)
			run.append(b)
		elif run.size() >= 2:
			lines.append(run)
			run = PackedVector2Array()
	if run.size() >= 2:
		lines.append(run)

static func _mapped_quay_at(data: LocationData, at: Vector2, m: float) -> bool:
	for structure in data.shore_structures:
		if str(structure.get("kind", "")) != "quay":
			continue
		var points: PackedVector2Array = structure.get("points", PackedVector2Array())
		for i in range(points.size() - 1):
			var near := Geometry2D.get_closest_point_to_segment(at, points[i], points[i + 1])
			if at.distance_to(near) < 15.0 * m:
				return true
	return false

static func _terminal_distance(data: LocationData, at: Vector2) -> float:
	var scope := _scope
	var terminals: PackedVector2Array = scope[1] if scope.size() == 4 and is_same(scope[0], data) \
		else _terminals(data)
	var distance := INF
	for t in terminals:
		distance = minf(distance, at.distance_to(t))
	return distance

## Where `data`'s ferry terminals stand (buildings, then POIs), less the
## ones that keep ferry scenery of their own (HarbourFerries).
static func _terminals(data: LocationData) -> PackedVector2Array:
	var out := PackedVector2Array()
	for b in data.buildings:
		if b is Dictionary and str(b.get("use", "")) == "ferry_terminal" and not HarbourFerries.terminal(b):
			out.append(Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))))
	for p in data.pois:
		if p is Dictionary and str(p.get("kind", "")) == "ferry_terminal" \
				and not str(p.get("name", "")).to_lower().contains("staten island ferry"):
			out.append(Vector2(float(p.get("x", 0.0)), float(p.get("z", 0.0))))
	return out

static func _near_terminal(data: LocationData, at: Vector2, m: float) -> bool:
	return _terminal_distance(data, at) < 400.0 * m

## Mapped ships have precedence over decorative ships. A conservative radius
## also prevents a procedural ship from obscuring an existing mapped hull.
static func _mapped_ship_near(data: LocationData, centre: Vector2, length: float, m: float) -> bool:
	for b in data.buildings:
		if b is Dictionary and HarbourFerries.terminal(b):
			var terminal := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
			if centre.distance_to(terminal) < 400.0 * m:
				return true
		if b is Dictionary and ShipBuilder.accepts(b):
			var frame := ShipBuilder.frame(b)
			if centre.distance_to(frame["centre"]) < (length + float(frame["length"])) * 0.5 * m + 30.0 * m:
				return true
	return false

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
				deep = deep and _wet(ground, q, mask) and _liner_deep(ground.water_at(q.x, q.y), m)
		var fairway := maxf(beam * 3.0, 100.0)
		var d := beam
		while deep and d <= fairway:
			var q := c + normal * sign_n * d * m
			deep = ground.is_inside(q.x, q.y) and ground.water_at(q.x, q.y) >= 1.0 * m
			d += 20.0
		if deep:
			return {"centre": c, "side": sign_n}
	return {}

## Where the quay is in the berthed ship's own frame (metres, +X bow,
## +Z = the berth normal): "quay_z" the quay edge, "quay_top" its height
## over the water, "along" the run's ends in ship x. ShipMooring reads it.
static func berth_info(ground: GroundTruth, a: Vector2, b: Vector2, at: Vector2, berth: Dictionary,
		beam: float, m: float) -> Dictionary:
	var c: Vector2 = berth["centre"]
	var side: float = berth["side"]
	var dir := (b - a).normalized()
	var land := at - Vector2(-dir.y, dir.x) * side * 3.0 * m
	var water := ground.water_level_at(c.x, c.y)
	var top := (ground.height_at_world(land.x, land.y) - water) / m
	return {"quay_z": -side * (beam * 0.5 + 2.0), "quay_top": clampf(top, 0.8, 6.0),
		"along": Vector2((a - c).dot(dir) / m, (b - c).dot(dir) / m)}

## The carved sea floor is often 2 m deep; interpolated floats can fall
## microscopically below that value, so allow a millimetre of rounding.
static func _liner_deep(depth: float, m: float) -> bool:
	return depth + 0.001 * m >= LINER_DEPTH_M * m

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
