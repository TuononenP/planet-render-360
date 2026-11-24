class_name QuayMoorings
extends RefCounted

## Alongside berths at mapped quays or a finalized masonry bank. These
## are procedural harbour dressing, not a claim that OSM mapped a vessel.
## Small craft are steamers, houseboats and the odd large yacht; long,
## straight, deep sea quays (tidal water, a clear fairway) also get up to
## MAX_LINERS cruise liners.
## * Known quay rows (QUAY_ROWS) keep their real character: a steamboat
##   row stays steamers, a houseboat quay is mostly houseboats, and a
##   row reaches farther than MarinaBuilder.RADIUS_M (it is a known sight
##   seen across the water), with its own cap of ROW_MAX_BOATS.
## * Big ferry ports (FERRY_PORTS) count as ferry terminals where the POI
##   layer (capped round the eye) misses them, and give their ferries the
##   line's livery. A ro-pax ferry stands 40-60 m tall, a skyline object
##   like a tower landmark, so a port's ferries show out to its reach_m
##   (the landmark registry's radius_m rule) rather than LINER_RADIUS_M.
const MAX_BOATS := 24
const GAP_M := 8.0
const MAX_LINERS := 2
const LINER_MIN_RUN_M := 170.0
const LINER_MIN_M := 140.0
const LINER_MAX_M := 300.0
const LINER_RADIUS_M := 1200.0
const LINER_SPACING_M := 400.0
const LINER_DEPTH_M := 2.0
## PortMiami (Dodge Island's north cruise berths): [lat0, lat1, lon0, lon1];
## liners there show out to CRUISE_REACH_M, line up CRUISE_SPACING_M apart,
## up to CRUISE_MAX_LINERS, bows east-south-east toward Government Cut.
const CRUISE_PORT_BOX := [25.768, 25.785, -80.185, -80.148]
const CRUISE_REACH_M := 3600.0
const CRUISE_SPACING_M := 310.0
const CRUISE_MAX_LINERS := 4
## The hull may not come nearer the eye than this (m).
const LINER_EYE_CLEAR_M := 40.0
const LINER_TURN_RAD := 0.12
const LINER_DEVIATION_M := 6.0
## Ferry ports by lat/lon: "reach_m" how far from the eye their ferries
## show; "hull" and "livery" (CruiseFerryModel sweep and funnel) colours.
## Plain colour blocks, no company marks.
const FERRY_PORTS := [
	# Stadsgården (Viking Line to Helsinki, Mariehamn): red hull, white upper works.
	{"id": "stadsgarden", "lat": 59.3170, "lon": 18.0910, "reach_m": 4500.0, "hull": "#c21f2c", "livery": "#c21f2c"},
	# Värtahamnen (Tallink Silja to Helsinki, Riga): white hull, navy sweep.
	{"id": "vartahamnen", "lat": 59.3500, "lon": 18.1110, "reach_m": 4500.0, "hull": "#f0eee8", "livery": "#1b2f5c"},
	# Linnansatama, Port of Turku (Viking Line to Stockholm/Mariehamn): red Viking livery.
	{"id": "turku_viking", "lat": 60.4352, "lon": 22.2195, "reach_m": 4500.0, "hull": "#f4f3ee", "livery": "#c8102e",
		"line": "turku_viking"},
	# Linnansatama, Port of Turku (Tallink Silja to Stockholm): white hull, navy Silja livery.
	{"id": "turku_silja", "lat": 60.4338, "lon": 22.2235, "reach_m": 4500.0, "hull": "#f4f3ee", "livery": "#16295a",
		"line": "turku_silja"},
]
## A ferry port's ships are those berthed within this of it (m).
const PORT_M := 500.0
## Named quay rows: "points" [lat, lon] along the quay, "houseboat" the
## share of houseboats, "corridor_m" how near the row a berth must be,
## "reach_m" how far from the eye the row is dressed.
const QUAY_ROWS := [
	# Strandvägen's veteran steamboat row (Nybroplan to Djurgårdsbron).
	{"id": "strandvagen", "houseboat": 0.0, "corridor_m": 60.0, "reach_m": 2600.0,
		"points": [[59.3322, 18.0775], [59.3317, 18.0860], [59.3313, 18.0940], [59.3309, 18.1000]]},
	# Söder Mälarstrand: houseboats and boat homes from Slussen west, and the
	# hotel ships and old steamers of QuayFleet. The points follow the street
	# (OSM), the quay edge lies 10-30 m north of it.
	{"id": "soder_malarstrand", "houseboat": 0.7, "corridor_m": 75.0, "reach_m": 2600.0,
		"points": [[59.31971, 18.03378], [59.32051, 18.04320], [59.32100, 18.04946], [59.32113, 18.05591],
			[59.32114, 18.05926], [59.32118, 18.06103], [59.32106, 18.06566], [59.32086, 18.06810]]},
	# Aurajoki east bank (Itäinen Rantakatu: Auransilta -> Teatterisilta -> Martinsilta),
	# Turku's signature moored restaurant ships (jokilaivat: Donna, Cindy, Katarina, Esposito).
	{"id": "aurajoki_east", "houseboat": 0.75, "kind": "restaurant_boat", "corridor_m": 35.0, "reach_m": 2600.0,
		"points": [[60.44854, 22.27035], [60.44768, 22.26763], [60.44694, 22.26510],
			[60.44556, 22.26029], [60.44419, 22.25624]]},
	# Aurajoki west bank (Läntinen Rantakatu: Kristiinankatu -> Martinsilta -> Tervatori),
	# moored restaurant ships (Svarte Rudolf, Papa Joe, Lulu).
	{"id": "aurajoki_west", "houseboat": 0.75, "kind": "restaurant_boat", "corridor_m": 35.0, "reach_m": 2600.0,
		"points": [[60.44799, 22.26680], [60.44767, 22.26555], [60.44613, 22.25984],
			[60.44506, 22.25596], [60.44476, 22.25492], [60.44381, 22.25241], [60.44280, 22.25027]]},
	# Paris Seine quays: Port de la Bourdonnais & Port de Suffren (Bateaux Parisiens,
	# Vedettes de Paris & moored péniches below the Eiffel Tower), plus Port de la Conférence.
	{"id": "seine_eiffel", "houseboat": 0.6, "kind": "restaurant_boat", "corridor_m": 45.0, "reach_m": 2600.0,
		"points": [[48.8559, 2.2889], [48.8586, 2.2921], [48.8608, 2.2962], [48.8622, 2.3008]]},
	{"id": "seine_alma", "houseboat": 0.5, "kind": "restaurant_boat", "corridor_m": 45.0, "reach_m": 2600.0,
		"points": [[48.8641, 2.3025], [48.8643, 2.3082], [48.8642, 2.3130]]},
]
const ROW_MAX_BOATS := 16

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

## The quay and bank lines small craft and row vessels berth along:
## {"points", "mapped"}.
static func berth_lines(data: LocationData, ground: GroundTruth) -> Array:
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
	return lines

static func plan(data: LocationData, ground: GroundTruth, taken: Dictionary,
		m: float, mask: VegetationMask = null) -> Array:
	var lines := berth_lines(data, ground)
	var centre := View360.spawn_xz(data)
	var stairs := _stairs(data)
	var bridge_list := bridges(data, m)
	var rows := quay_rows(data, m)
	var row_counts := {}
	var generic := 0
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
			var row := _row_at(rows, at, m)
			var reach := float(row.get("reach_m", MarinaBuilder.RADIUS_M))
			if at.distance_to(centre) > reach * m:
				continue
			if (row.is_empty() and generic >= MAX_BOATS) \
					or int(row_counts.get(row.get("id", ""), 0)) >= ROW_MAX_BOATS:
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
			var bow := position + dir * length * 0.5
			# Stairs down the wall run on to the water: no berth across them.
			if _near_stairs(stairs, position, dir, length, beam, m) \
					or near_bridge(bridge_list, stern, bow, beam * 0.5 + 3.0 * m):
				continue
			var clear := true
			for along in [-0.5, 0.0, 0.5]:
				for across in [-0.5, 0.5]:
					clear = clear and _wet(ground, position + dir * length * along + normal * beam * across, mask)
			if not clear or not MarinaBuilder._claim(taken, stern, dir, length / m, beam / m, m):
				continue
			var y := ground.water_level_at(position.x, position.y)
			var is_houseboat := hash_v >= 0.80
			if not row.is_empty():
				is_houseboat = MarinaBuilder._hash(at.x, at.y, 53.0) < float(row["houseboat"])
				# A row with its own fleet (QuayFleet) keeps houseboats only here.
				if QuayFleet.FLEETS.has(row["id"]) and not is_houseboat:
					continue
				row_counts[row["id"]] = int(row_counts.get(row["id"], 0)) + 1
			else:
				generic += 1
			var scale_len := minf(length, 20.0 * m) if is_houseboat else length
			var boat_kind := str(row.get("kind", "houseboat")) if is_houseboat else "steam"
			out.append([Vector3(position.x, y, position.y), atan2(-dir.y, dir.x), scale_len / (10.0 * m),
				boat_kind, Color.WHITE])
	return out

## QUAY_ROWS in `data`'s frame: each row with "pts" (world XZ).
static func quay_rows(data: LocationData, m: float) -> Array:
	var out: Array = []
	for row: Dictionary in QUAY_ROWS:
		var pts := PackedVector2Array()
		for ll: Array in row["points"]:
			pts.append(WorldScale.xz_from_latlon(float(ll[0]), float(ll[1]), data.latitude, data.longitude) * m)
		var near := false
		for q in pts:
			near = near or q.length() < (WorldScale.DETAILED_EXTENT_M + float(row["reach_m"])) * m
		if near:
			var placed := row.duplicate()
			placed["pts"] = pts
			out.append(placed)
	return out

## The row whose corridor holds `at`, or {}.
static func _row_at(rows: Array, at: Vector2, m: float) -> Dictionary:
	for row: Dictionary in rows:
		var pts: PackedVector2Array = row["pts"]
		for i in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(at, pts[i], pts[i + 1]).distance_to(at) \
					<= float(row["corridor_m"]) * m:
				return row
	return {}

## FERRY_PORTS inside `data`'s detailed extent, each with "at" (world XZ).
static func ports(data: LocationData, m: float) -> Array:
	var out: Array = []
	for port: Dictionary in FERRY_PORTS:
		var at := WorldScale.xz_from_latlon(float(port["lat"]), float(port["lon"]), data.latitude, data.longitude) * m
		if absf(at.x) <= WorldScale.DETAILED_EXTENT_M * m and absf(at.y) <= WorldScale.DETAILED_EXTENT_M * m:
			var placed := port.duplicate()
			placed["at"] = at
			out.append(placed)
	return out

## The listed port within PORT_M of `at`, or {}.
static func port_at(data: LocationData, at: Vector2, m: float) -> Dictionary:
	for port: Dictionary in ports(data, m):
		if (port["at"] as Vector2).distance_to(at) <= PORT_M * m:
			return port
	return {}

## The mapped steps ways' lines (stairs down a quay wall).
static func _stairs(data: LocationData) -> Array:
	var out: Array = []
	for road in data.roads:
		if road is Dictionary and str(road.get("class", "")) == "steps":
			var pts: PackedVector2Array = road.get("points", PackedVector2Array())
			if pts.size() >= 2:
				out.append(pts)
	return out

## True when a stair comes within the boat's hull (length, beam) and 3 m.
static func _near_stairs(stairs: Array, position: Vector2, dir: Vector2, length: float, beam: float, m: float) -> bool:
	var reach := beam * 0.5 + 3.0 * m
	for pts: PackedVector2Array in stairs:
		for i in pts.size() - 1:
			for along in [-0.5, -0.25, 0.0, 0.25, 0.5]:
				var q: Vector2 = position + dir * length * along
				if Geometry2D.get_closest_point_to_segment(q, pts[i], pts[i + 1]).distance_to(q) <= reach:
					return true
	return false

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
## claims its berth in `taken` so small craft keep clear. A row's own fleet
## (QuayFleet) follows the liners.
static func liners(data: LocationData, ground: GroundTruth, taken: Dictionary, m: float,
		mask: VegetationMask = null) -> Array:
	var out := _large_ships(data, ground, taken, m, mask)
	out.append_array(QuayFleet.plan(data, ground, taken, m, mask))
	return out

static func _large_ships(data: LocationData, ground: GroundTruth, taken: Dictionary, m: float,
		mask: VegetationMask = null) -> Array:
	var out: Array = []
	if ground.shoreline == null or not ground.shoreline.ready:
		return out
	var eye := View360.spawn_xz(data)
	var bridge_list := bridges(data, m)
	var cap := CRUISE_MAX_LINERS if WaterSurface.miami_water(data.latitude, data.longitude) else MAX_LINERS
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
		# The central tidal Thames upstream of Tower Bridge and the Paris Seine cannot pass ocean liners or cruise ferries.
		if (data.latitude >= 51.45 and data.latitude <= 51.53 and data.longitude >= -0.22 and data.longitude <= -0.06) \
				or WaterSurface.seine(data.latitude, data.longitude):
			continue
		if not ferry and CargoBerths.port_run(data, a, b, m):
			continue  # cargo quays berth cargo ships (CargoBerths)
		var length := minf(200.0 if ferry else 230.0, run_m - 30.0)
		if length < LINER_MIN_M:
			continue
		# Riddarfjärden's quays berth a Mälaren steamer or hotel ship, not a liner.
		var hotel := not ferry and QuayFleet.hotel_water(data, (a + b) * 0.5, m)
		if hotel:
			length = QuayFleet.HOTEL_LENGTH_M
		var beam := length * (QuayFleet.HOTEL_BEAM_SHARE if hotel else 0.125)
		for frac in [0.5, 0.2, 0.8]:
			var along := (length * 0.5 + 15.0 + (run_m - length - 30.0) * float(frac)) * m
			var at := a + dir * along
			if not _near_terminal(data, at, m) and not _mapped_quay_at(data, at, m):
				continue
			var berth := _liner_berth(ground, mask, at, dir, length, beam, m)
			if berth.is_empty():
				continue
			var c: Vector2 = berth["centre"]
			var port := port_at(data, c, m) if ferry else {}
			var radius := float(port.get("reach_m", LINER_RADIUS_M))
			var spacing := LINER_SPACING_M
			if not ferry and cruise_port_at(data, c, m):
				radius = CRUISE_REACH_M
				spacing = CRUISE_SPACING_M
			if c.distance_to(eye) > radius * m or _near_eye(c, dir, length, beam, eye, m) \
					or not _spaced(out, c, m, spacing) or _mapped_ship_near(data, c, length, m):
				continue
			var bow_dir := dir
			var stern := c - dir * length * 0.5 * m
			var bow := c + dir * length * 0.5 * m
			if near_bridge(bridge_list, stern, bow, (beam * 0.5 + 6.0) * m) \
					or not MarinaBuilder._claim(taken, stern, dir, length, beam, m):
				continue
			var info := berth_info(ground, a, b, at, berth, beam, m)
			if not port.is_empty():
				info["hull"] = str(port["hull"])
				info["livery"] = str(port["livery"])
				if port.has("line"):
					info["line"] = str(port["line"])
			elif ferry:
				var line := FerryLivery.line_at(data, c, m)
				if not line.is_empty():
					info["hull"] = str(line["hull"])
					info["line"] = str(line["id"])
			var seed_value := fposmod(c.x * 0.0131 + c.y * 0.0077, 1.0)
			if hotel:
				out.append(QuayFleet.hotel_ship(Vector3(c.x, ground.water_level_at(c.x, c.y), c.y),
					atan2(-bow_dir.y, bow_dir.x), length, beam, seed_value))
				break
			out.append([Vector3(c.x, ground.water_level_at(c.x, c.y), c.y), atan2(-bow_dir.y, bow_dir.x),
				length, beam, clampf(length * 0.21 if ferry else length * 0.2, 22.0, 65.0),
				seed_value, "ferry" if ferry else "liner", info])
			break
		if out.size() >= cap:
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
	for port: Dictionary in ports(data, WorldScale.metres_to_units()):
		out.append(port["at"])
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

## Whether world point `at` lies inside PortMiami's cruise-berth box.
static func cruise_port_at(data: LocationData, at: Vector2, m: float) -> bool:
	if not WaterSurface.miami_water(data.latitude, data.longitude):
		return false
	var ll := WorldScale.latlon_from_xz(at.x / m, at.y / m, data.latitude, data.longitude)
	return ll.x >= CRUISE_PORT_BOX[0] and ll.x <= CRUISE_PORT_BOX[1] \
		and ll.y >= CRUISE_PORT_BOX[2] and ll.y <= CRUISE_PORT_BOX[3]

static func _spaced(out: Array, c: Vector2, m: float, spacing: float = LINER_SPACING_M) -> bool:
	for l in out:
		var q: Vector3 = l[0]
		if Vector2(q.x, q.z).distance_to(c) < spacing * m:
			return false
	return true

## Bridge segments and outlines in `data`, for berth bridge-clearance checks.
static func bridges(data: LocationData, m: float) -> Dictionary:
	var segs: Array = []
	var polys: Array = []
	for r in data.roads:
		if not (r is Dictionary) or not bool((r as Dictionary).get("bridge", false)) \
				or bool((r as Dictionary).get("tunnel", false)):
			continue
		var pts: PackedVector2Array = (r as Dictionary).get("points", PackedVector2Array())
		var hw := maxf(float((r as Dictionary).get("width_m", 4.0)), 2.0) * 0.5 * m
		for i in pts.size() - 1:
			segs.append([pts[i], pts[i + 1], hw, Rect2(pts[i], Vector2.ZERO).expand(pts[i + 1]).grow(hw)])
	for rw in data.railways:
		if not (rw is Dictionary) or not bool((rw as Dictionary).get("bridge", false)) \
				or bool((rw as Dictionary).get("tunnel", false)):
			continue
		var pts: PackedVector2Array = (rw as Dictionary).get("points", PackedVector2Array())
		var hw := maxf(float((rw as Dictionary).get("width_m", 5.0)), 4.0) * 0.5 * m
		for i in pts.size() - 1:
			segs.append([pts[i], pts[i + 1], hw, Rect2(pts[i], Vector2.ZERO).expand(pts[i + 1]).grow(hw)])
	for sp in LandmarkSites.bridge_spans(data):
		var at: Vector2 = sp[0]
		var entry: Dictionary = sp[1]
		var reach := LandmarkSites.axis(entry) * float(entry.get("span_m", 0.0)) * 0.5 * m
		var hw := LandmarkSites.clear_m(entry) * m
		segs.append([at - reach, at + reach, hw, Rect2(at - reach, Vector2.ZERO).expand(at + reach).grow(hw)])
	for area in data.bridge_areas:
		if not (area is Dictionary):
			continue
		var ring: PackedVector2Array = (area as Dictionary).get("points", PackedVector2Array())
		if ring.size() < 3:
			continue
		polys.append([ring, RingGeometry.aabb(ring)])
		for i in ring.size():
			var p0 := ring[i]
			var p1 := ring[(i + 1) % ring.size()]
			segs.append([p0, p1, 0.0, Rect2(p0, Vector2.ZERO).expand(p1)])
	return {"segs": segs, "polys": polys}

## True when hull centreline `stern..bow` comes within `clearance` of any bridge.
static func near_bridge(bridge_list: Dictionary, stern: Vector2, bow: Vector2, clearance: float) -> bool:
	var box := Rect2(stern, Vector2.ZERO).expand(bow).grow(clearance)
	for seg: Array in bridge_list["segs"]:
		if not (seg[3] as Rect2).intersects(box, true):
			continue
		var hits := Geometry2D.get_closest_points_between_segments(stern, bow, seg[0], seg[1])
		if hits[0].distance_to(hits[1]) <= float(seg[2]) + clearance:
			return true
	var mid := (stern + bow) * 0.5
	for poly: Array in bridge_list["polys"]:
		if not (poly[1] as Rect2).intersects(box, true):
			continue
		var ring: PackedVector2Array = poly[0]
		if Geometry2D.is_point_in_polygon(stern, ring) or Geometry2D.is_point_in_polygon(mid, ring) \
				or Geometry2D.is_point_in_polygon(bow, ring):
			return true
	return false
