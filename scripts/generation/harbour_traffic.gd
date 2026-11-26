class_name HarbourTraffic
extends RefCounted

## Helsinki-style harbour scenery from HarbourVesselData rows: commuter
## ferries and water buses on their mapped routes (one berthed at the city
## pier, the rest under way with a wake), the state icebreakers moored in
## rafts along their winter quay, and the market boats lying at the
## Kauppatori quay. A row whose points fall outside the built square places
## nothing, so other cities build exactly as before. Scenery, not live
## positions.
## `plan` decides every vessel once per world (cached on the data and ground
## it was asked for), so MarinaBuilder can keep its small craft off the
## hulls (`claim`) before `build` commits them.

## Berth search from a route's first point: forward steps and offsets
## across the line (m), and the open water kept round a berthed hull.
const BERTH_ALONG_M := 4.0
const BERTH_REACH_M := 220.0
const BERTH_ACROSS_M := [0.0, 5.0, -5.0, 10.0, -10.0, 16.0, -16.0]
const BERTH_MARGIN_M := 2.0
## A moored ship's distance from the quay line grows by this until its
## stern, middle and bow are all over water (m), up to FENDER_MAX_M. A
## fleet's first ship slides along the quay by these shifts (m) to find a
## berth with water on its whole length.
const FENDER_M := 1.2
const FENDER_STEP_M := 1.5
const FENDER_MAX_M := 24.0
const SLIDE_M := [0.0, -20.0, 20.0, -40.0, 40.0, -70.0, 70.0, -100.0, 100.0]
const WET_M := 0.5

static var _plan_for: Array = []
static var _plan_cached: Array = []

static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask) -> int:
	var m := WorldScale.metres_to_units()
	var count := 0
	for v: Dictionary in plan(data, ground, mask):
		var lm := LandmarkMesh.new()
		var length := float(v["length"])
		var beam := float(v["beam"])
		match str(v["kind"]):
			"commuter":
				lm = CommuterFerryModel.build(v["row"])
			"icebreaker":
				IcebreakerModel.build(lm, {"length": length, "beam": beam, "name": str(v["name"]),
					"detail": true, "maps": true, "ultra": MaterialLibrary.hi_res})
			_:
				MarketBoatModel.build(lm, {"length": length, "detail": true, "maps": true,
					"hull": v["hull"], "awning": v["awning"]})
		var centre: Vector2 = v["centre"]
		var axis: Vector2 = v["axis"]
		var wpos := Vector3(centre.x, ground.water_level_at(centre.x, centre.y), centre.y)
		for part in lm.commit(root, str(v["prefix"])):
			part.position = wpos
			part.rotation.y = atan2(-axis.y, axis.x)
			part.scale = Vector3.ONE * m
			part.set_meta("procedural_ferry", true)
			part.set_meta("harbour_vessel", str(v["id"]))
			part.set_meta("harbour_kind", str(v["kind"]))
		if bool(v["underway"]):
			WaterWakes.add_wake(root, wpos, atan2(-axis.y, axis.x), length * m, beam * m)
		count += 1
	return count

## Marks every planned hull taken in `taken` (MarinaBuilder's claim map).
static func claim(taken: Dictionary, data: LocationData, ground: GroundTruth, mask: VegetationMask,
		m: float) -> void:
	for v: Dictionary in plan(data, ground, mask):
		var axis: Vector2 = v["axis"]
		var stern: Vector2 = (v["centre"] as Vector2) - axis * float(v["length"]) * 0.5 * m
		MarinaBuilder._claim(taken, stern, axis, float(v["length"]), float(v["beam"]), m)

## The vessels for `data`: dictionaries with "kind" (commuter, icebreaker,
## market), "prefix", "id", "centre", "axis" (bow direction, world XZ),
## "length" and "beam" (m), "underway", and the kind's own keys. Empty for a
## place the rows do not reach.
static func plan(data: LocationData, ground: GroundTruth, mask: VegetationMask) -> Array:
	var key := [data.get_instance_id(), ground.get_instance_id(), mask != null]
	if _plan_for == key:
		return _plan_cached
	var m := WorldScale.metres_to_units()
	var out: Array = []
	# One shared separation list across the moored fleets: a berthed ferry,
	# an icebreaker raft and a market boat never share a hull rectangle,
	# even though none of them moves.
	var taken: Array = []
	if mask != null:
		out.append_array(_commuters(data, ground, mask, m, taken))
	out.append_array(_icebreakers(data, ground, m, taken))
	out.append_array(_market_boats(data, ground, m, taken))
	_plan_for = key
	_plan_cached = out
	return out

## Fender gap (m) kept between the hulls of two stationary vessels.
const CLEAR_M := 4.0

## True when a `length`-metre hull at `c` keeps half-lengths plus CLEAR_M
## from every taken {"centre", "length"} hull, except `ignore` (a raft
## lies outboard of its parent by design).
static func _clear_of(taken: Array, c: Vector2, length: float, m: float, ignore: Vector2 = Vector2.INF) -> bool:
	for other: Dictionary in taken:
		var oc: Vector2 = other["centre"]
		if oc == ignore:
			continue
		var gap := (length + float(other.get("length", length))) * 0.5 + CLEAR_M
		if oc.distance_to(c) <= gap * m:
			return false
	return true

## `points` ([lat, lon] rows) as world XZ in internal units.
static func _world(data: LocationData, points: Array, m: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in HarbourVesselData.to_world(points, data.latitude, data.longitude):
		out.append(q * m)
	return out

static func _any_inside(ground: GroundTruth, pts: PackedVector2Array) -> bool:
	for q in pts:
		if ground.is_inside(q.x, q.y):
			return true
	return false

# --- Commuter ferries and water buses -----------------------------------

static func _commuters(data: LocationData, ground: GroundTruth, mask: VegetationMask, m: float,
		taken: Array) -> Array:
	var out: Array = []
	var eye := View360.spawn_xz(data)
	var bridge_list := {}
	for row: Dictionary in HarbourVesselData.FERRY_ROUTES:
		if str(row.get("kind", "")) != "route":
			continue
		var pts := _world(data, row["route"], m)
		if not _any_inside(ground, pts):
			continue
		if bridge_list.is_empty():
			bridge_list = QuayMoorings.bridges(data, m)
		var length := float(row["length_m"])
		var beam := float(row["beam_m"])
		var total := MarinaBuilder._length(pts)
		for ship: Dictionary in row.get("ships", []):
			var berthed := bool(ship.get("berthed", false))
			var site := _berth_site(pts, total, length, beam, ground, mask, m, taken) if berthed \
				else HarbourFerries._route_site(pts, total, float(ship.get("at", 0.0)), length, beam, ground,
					mask, bridge_list, eye, taken, m)
			if site.is_empty():
				continue
			taken.append({"centre": site["centre"], "length": length})
			out.append({"kind": "commuter", "prefix": "CommuterFerry_", "id": str(row["id"]), "row": row,
				"centre": site["centre"], "axis": site["axis"], "length": length, "beam": beam,
				"underway": not berthed})
	return out

## The first spot along the route from its start where a berthed hull lies
## wholly over open water: {"centre", "axis"} or {}.
static func _berth_site(pts: PackedVector2Array, total: float, length: float, beam: float,
		ground: GroundTruth, mask: VegetationMask, m: float, taken: Array) -> Dictionary:
	var t := length * 0.5 * m
	while t < minf(total, (BERTH_REACH_M + length) * m):
		var sample := MarinaBuilder._at(pts, t, [0, 0.0])
		var at: Vector2 = sample[0]
		var dir: Vector2 = sample[1]
		var side := Vector2(-dir.y, dir.x)
		for across: float in BERTH_ACROSS_M:
			var c: Vector2 = at + side * across * m
			if not HarbourFerries._open(ground, mask, c, dir, (length + 2.0 * BERTH_MARGIN_M) * m,
					(beam + 2.0 * BERTH_MARGIN_M) * m):
				continue
			var clear := true
			for other: Dictionary in taken:
				var gap := (length + float(other.get("length", length))) * 0.5 + 6.0
				clear = clear and (other["centre"] as Vector2).distance_to(c) > gap * m
			if clear:
				return {"centre": c, "axis": dir}
		t += BERTH_ALONG_M * m
	return {}

# --- Moored and market craft ---------------------------------------------

## The sign (-1 or 1) of the quay normal that points over water at `at`.
static func _water_side(ground: GroundTruth, at: Vector2, dir: Vector2, m: float) -> float:
	var n := Vector2(-dir.y, dir.x)
	var a := ground.water_at(at.x + n.x * 8.0 * m, at.y + n.y * 8.0 * m)
	var b := ground.water_at(at.x - n.x * 8.0 * m, at.y - n.y * 8.0 * m)
	return 1.0 if a >= b else -1.0

static func _wet(ground: GroundTruth, p: Vector2, m: float) -> bool:
	return ground.is_inside(p.x, p.y) and ground.water_at(p.x, p.y) > WET_M * m

## The offset (m) from the quay line at which a `length` x `beam` hull lying
## along `dir` at `at` stands over water, searching outward from
## `start_m`; -1 when there is none within FENDER_MAX_M.
static func _offset_over_water(ground: GroundTruth, at: Vector2, dir: Vector2, side: float, length: float,
		beam: float, start_m: float, m: float) -> float:
	var n := Vector2(-dir.y, dir.x) * side
	var off := start_m
	while off <= FENDER_MAX_M + beam:
		var c := at + n * off * m
		var ok := true
		for along in [-0.45, 0.0, 0.45]:
			for across in [-0.4, 0.4]:
				ok = ok and _wet(ground, c + dir * length * float(along) * m + n * beam * float(across) * m, m)
		if ok:
			return off
		off += FENDER_STEP_M
	return -1.0

static func _icebreakers(data: LocationData, ground: GroundTruth, m: float, taken: Array) -> Array:
	var out: Array = []
	for fleet: Dictionary in HarbourVesselData.MOORED_FLEETS:
		if str(fleet.get("kind", "")) != "icebreaker":
			continue
		var pts := _world(data, fleet["quay"], m)
		if not _any_inside(ground, pts):
			continue
		var total := MarinaBuilder._length(pts)
		var shift := 0.0
		var previous := {}
		for ship: Dictionary in fleet["ships"]:
			var length := float(ship["length_m"])
			var beam := float(ship["beam_m"])
			var rafted := bool(ship.get("raft", false)) and not previous.is_empty()
			var slides: Array = [shift] if rafted else SLIDE_M
			var found := {}
			for slide: float in slides:
				var sample := MarinaBuilder._at(pts, clampf(total * float(ship["at"]) + slide * m, 0.0, total),
					[0, 0.0])
				var spot: Vector2 = sample[0]
				var heading: Vector2 = sample[1]
				var side := float(previous["side"]) if rafted else _water_side(ground, spot, heading, m)
				var start := FENDER_M + beam * 0.5
				if rafted:
					# Outboard of the ship before it, one fender apart.
					start = float(previous["offset"]) + float(previous["beam"]) * 0.5 + beam * 0.5 + 1.0
				var off := _offset_over_water(ground, spot, heading, side, length, beam, start, m)
				if off < 0.0:
					continue
				var centre := spot + Vector2(-heading.y, heading.x) * side * off * m
				# A raft lies outboard of its parent by design; every other
				# hull keeps half-lengths plus a fender gap, moving or not.
				if not _clear_of(taken, centre, length, m, previous.get("centre", Vector2.INF)):
					continue
				found = {"at": spot, "dir": heading, "side": side, "offset": off, "shift": slide,
					"centre": centre}
				break
			if found.is_empty():
				previous = {}
				continue
			shift = float(found["shift"])
			var at: Vector2 = found["at"]
			var dir: Vector2 = found["dir"]
			var centre: Vector2 = found["centre"]
			out.append({"kind": "icebreaker", "prefix": "Icebreaker_", "id": str(ship.get("name", "")),
				"name": str(ship.get("name", "")), "centre": centre, "axis": dir, "length": length,
				"beam": beam, "underway": false})
			taken.append({"centre": centre, "length": length})
			previous = {"offset": found["offset"], "beam": beam, "side": found["side"], "centre": centre}
	return out

static func _market_boats(data: LocationData, ground: GroundTruth, m: float, taken: Array) -> Array:
	var out: Array = []
	for fleet: Dictionary in HarbourVesselData.MARKET_BOATS:
		var pts := _world(data, fleet["quay"], m)
		if not _any_inside(ground, pts):
			continue
		var total := MarinaBuilder._length(pts) / m
		var range_m: Array = fleet["length_m"]
		var cursor := 1.0
		for i in int(fleet["count"]):
			var h := MarinaBuilder._hash(pts[0].x + float(i) * 3.1, pts[0].y, 71.0)
			var length := lerpf(float(range_m[0]), float(range_m[1]), h)
			if cursor + length > total - 1.0:
				break
			var beam := length * 0.3
			var sample := MarinaBuilder._at(pts, (cursor + length * 0.5) * m, [0, 0.0])
			var at: Vector2 = sample[0]
			var dir: Vector2 = sample[1]
			cursor += length + 0.8
			var side := _water_side(ground, at, dir, m)
			var off := _offset_over_water(ground, at, dir, side, length, beam, FENDER_M + beam * 0.5, m)
			if off < 0.0:
				continue
			var centre := at + Vector2(-dir.y, dir.x) * side * off * m
			# A market boat never shares a hull rectangle with a berthed
			# ferry or an icebreaker, even though none of them moves.
			if not _clear_of(taken, centre, length, m):
				continue
			taken.append({"centre": centre, "length": length})
			var hulls: Array = MarketBoatModel.HULLS
			var awnings: Array = MarketBoatModel.AWNINGS
			out.append({"kind": "market", "prefix": "MarketBoat_", "id": "market boat",
				"centre": centre, "axis": dir if i % 2 == 0 else -dir,
				"length": length, "beam": beam, "underway": false,
				"hull": hulls[int(h * 997.0) % hulls.size()], "awning": awnings[int(h * 541.0) % awnings.size()]})
	return out
