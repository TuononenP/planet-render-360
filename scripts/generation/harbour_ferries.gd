class_name HarbourFerries
extends RefCounted

## Procedural harbour traffic: scenery, not a claim about a vessel's
## real-time position.
## * New York: an orange Staten Island ferry beside the mapped terminal.
##   The 310 ft / 70 ft municipal-orange ferries: https://siferry.com/current-vessels/
## * Route fleets (ROUTES): boats under way on real passenger lines, as
##   lat/lon waypoints from the operators' route maps (the payloads carry
##   no route=ferry ways). Each boat stands at a share of its route's
##   length, nudged across (and along) the line to the first spot where the
##   whole hull is in open water, clear of mapped roads, buildings and
##   bridges; a route with no such spot gets no boat. Bows point along the
##   route, alternately outbound and inbound, each with a wake.
const LENGTH_M := 94.5
const BEAM_M := 21.3

## Route vessel classes (true metres; `height` is the funnel top over the
## waterline). Plain colour blocks, no operator marks.
const VESSELS := {
	# Djurgårdsfärjan: the small double-deck harbour ferries (M/S Emelie,
	# Djurgården 3 ..; 20-28 m) with a dark green hull and a white house.
	"djurgarden": {"length": 24.0, "beam": 6.4, "height": 8.5, "speed": 4.5, "hull": "#2c5a3c", "funnel": "#f1efe8"},
	# Waxholmsbolaget's archipelago boats (Waxholm I/II/III, Västan; 30-45 m):
	# white hull, house and funnel.
	"waxholm": {"length": 36.0, "beam": 7.6, "height": 12.0, "speed": 6.0, "hull": "#f1efe8", "funnel": "#f1efe8"},
	# Mälaren steamers (S/S Mariefred, Drottningholm line; 30-40 m): black hull, white
	# house, a tall red funnel.
	"steamer": {"length": 34.0, "beam": 6.6, "height": 12.5, "speed": 5.0, "hull": "#1d2126", "funnel": "#a8352a"},
	# Strömma's canal and sightseeing boats (25-32 m): a blue hull, white house and funnel.
	"sightseeing": {"length": 28.0, "beam": 7.0, "height": 8.0, "speed": 4.5, "hull": "#27506e", "funnel": "#eceae2"},
}

## Lines with boats under way: "points" [lat, lon] from pier to pier,
## "boats" the shares of the length where one stands.
const ROUTES := [
	# Line 82, Slussen (Stadsgårdskajen) - Skeppsholmen - Allmänna gränd (Djurgården).
	{"id": "djurgarden_slussen", "vessel": "djurgarden", "boats": [0.42],
		"points": [[59.3199, 18.0762], [59.3204, 18.0800], [59.3207, 18.0860], [59.3216, 18.0920],
			[59.3236, 18.0962]]},
	# Line 80 (summer), Nybroplan - Allmänna gränd across Nybroviken and Saltsjön.
	{"id": "djurgarden_nybroplan", "vessel": "djurgarden", "boats": [0.55],
		"points": [[59.3316, 18.0786], [59.3306, 18.0830], [59.3290, 18.0890], [59.3262, 18.0945],
			[59.3240, 18.0966]]},
	# Waxholm boats from Strömkajen (Grand Hôtel) south round Skeppsholmen
	# and out past Kastellholmen and Beckholmen toward Vaxholm.
	{"id": "waxholm_stromkajen", "vessel": "waxholm", "boats": [0.3, 0.72],
		"points": [[59.3288, 18.0752], [59.3262, 18.0768], [59.3228, 18.0790], [59.3210, 18.0860],
			[59.3214, 18.0960], [59.3236, 18.1080], [59.3268, 18.1210]]},
	# Mälaren steamers from Stadshusbron / Riddarholmen west across Riddarfjärden
	# toward Drottningholm and Mariefred, one in each direction.
	{"id": "malaren_steamer", "vessel": "steamer", "boats": [0.08, 0.5],
		"points": [[59.3250, 18.0600], [59.3252, 18.0540], [59.3247, 18.0470], [59.3240, 18.0390],
			[59.3236, 18.0310], [59.3246, 18.0220]]},
	# Sightseeing boats from Strömkajen out through Saltsjön, between
	# Skeppsholmen and Södermalm, and on past Beckholmen.
	{"id": "sightseeing_stromkajen", "vessel": "sightseeing", "boats": [0.25, 0.7],
		"points": [[59.3280, 18.0768], [59.3254, 18.0796], [59.3234, 18.0838], [59.3226, 18.0900],
			[59.3230, 18.0975]]},
]
## How far across the line (m) a boat may move to find open water, and
## how far along it.
const ACROSS_M := [0.0, 20.0, -20.0, 45.0, -45.0, 80.0, -80.0]
const ALONG_M := [0.0, 40.0, -40.0, 90.0, -90.0]
## Open water kept round a hull (m) and from the eye.
const MARGIN_M := 6.0
const EYE_CLEAR_M := 60.0
## Step (m) a boat's run is checked for open water along its route.
const SPAN_STEP_M := 10.0

## Moving cruise ferries and liners on their approach fairways: one entry
## per approach, with "boats" as [{"at": share, "line": optional
## HarbourVesselData.CRUISE_LIVERIES id}] so two companies can share one
## fairway (Turku, Helsinki West Harbour). Scenery, not live positions:
## each ship shuttles along the open-water stretch of its fairway with a
## wake, like the small route boats. Points are [lat, lon] from the open
## sea to the terminal.
const LINER_ACROSS_M := [0.0, 30.0, -30.0, 70.0, -70.0, 130.0, -130.0]
const LINER_ALONG_M := [0.0, 80.0, -80.0, 180.0, -180.0]
const LINER_MARGIN_M := 12.0
const LINER_EYE_CLEAR_M := 150.0
const LINER_SPAN_STEP_M := 20.0
const LINER_TURN_RAD_S := 0.15
const LINER_ACCEL_MS2 := 0.25
const LINER_BRAKE_MS2 := 0.35
const LINER_DWELL_S := 25.0
const LINER_ROUTES := [
	# Silja Line to Olympiaterminaali: open sea south of Suomenlinna through
	# the strait to the terminal.
	{"id": "helsinki_silja", "model": "cruise_ferry", "length": 200.0, "beam": 27.0, "height": 42.0,
		"line": "silja", "speed": 7.0,
		"points": [[60.1300, 24.9850], [60.1400, 24.9780], [60.1500, 24.9680], [60.1570, 24.9620], [60.1606, 24.9588]],
		"boats": [{"at": 0.85}]},
	# Viking Line to Katajanokka: south-east approach past Katajaluoto.
	{"id": "helsinki_viking", "model": "cruise_ferry", "length": 200.0, "beam": 27.0, "height": 42.0,
		"line": "viking", "speed": 7.0,
		"points": [[60.1300, 25.0000], [60.1420, 24.9900], [60.1540, 24.9780], [60.1639, 24.9684]],
		"boats": [{"at": 0.85}]},
	# Tallink and Eckerö Line to West Harbour: south-west approach shared by
	# both companies' ships.
	{"id": "helsinki_west", "model": "cruise_ferry", "length": 190.0, "beam": 27.0, "height": 40.0,
		"line": "tallink", "speed": 7.0,
		"points": [[60.1300, 24.8800], [60.1380, 24.8950], [60.1450, 24.9070], [60.1500, 24.9140]],
		"boats": [{"at": 0.7}, {"at": 0.9, "line": "eckero"}]},
	# Viking Line to Stadsgården: Saltsjön fairway from the east.
	{"id": "stockholm_viking", "model": "cruise_ferry", "length": 200.0, "beam": 28.0, "height": 42.0,
		"hull": "#c21f2c", "livery": "#c21f2c", "speed": 7.0,
		"points": [[59.3220, 18.1500], [59.3205, 18.1300], [59.3185, 18.1080], [59.3170, 18.0910]],
		"boats": [{"at": 0.75}]},
	# Tallink Silja to Värtahamnen: Lilla Värtan fairway from the east.
	{"id": "stockholm_silja", "model": "cruise_ferry", "length": 200.0, "beam": 28.0, "height": 42.0,
		"hull": "#f0eee8", "livery": "#1b2f5c", "speed": 7.0,
		"points": [[59.3550, 18.1600], [59.3530, 18.1380], [59.3510, 18.1220], [59.3500, 18.1110]],
		"boats": [{"at": 0.75}]},
	# Viking and Silja Lines to Linnansatama, Turku: Airisto fairway shared
	# by both companies' ships.
	{"id": "turku_approach", "model": "cruise_ferry", "length": 190.0, "beam": 27.0, "height": 40.0,
		"line": "turku_viking", "speed": 7.0,
		"points": [[60.4100, 22.1650], [60.4200, 22.1850], [60.4290, 22.2050], [60.4345, 22.2215]],
		"boats": [{"at": 0.75}, {"at": 0.9, "line": "turku_silja"}]},
	# PortMiami cruise approach through Government Cut: a generic ocean liner
	# standing in for the lines berthed on Dodge Island.
	{"id": "miami_cruise", "model": "liner", "length": 260.0, "beam": 32.0, "height": 58.0,
		"hull": "#e9e8e2", "speed": 8.0,
		"points": [[25.7550, -80.0600], [25.7600, -80.1000], [25.7670, -80.1350], [25.7760, -80.1680]],
		"boats": [{"at": 0.9}]},
]

## Extra separation (m) kept between the centres of two placed hulls,
## beyond their half-lengths: small craft keep 20 m, liners 80 m, so a
## berthed hull and a passing one never overlap, moving or not.
const TAKEN_GAP_M := 20.0
const LINER_TAKEN_GAP_M := 80.0

## Centre distance (m) keeping hulls of `a_len` and `b_len` metres apart:
## half-lengths plus `margin`.
static func hull_gap(a_len: float, b_len: float, margin: float) -> float:
	return (a_len + b_len) * 0.5 + margin

static func terminal(b: Dictionary) -> bool:
	return str(b.get("use", "")) == "ferry_terminal" \
		and str(b.get("name", "")).to_lower().contains("staten island ferry")

## Search outward from the terminal, keeping the entire vessel in water
## and clear of mapped roads and buildings. Its long axis points to shore.
static func berth(b: Dictionary, ground: GroundTruth, mask: VegetationMask) -> Dictionary:
	var origin := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	for distance in [180.0, 220.0, 260.0, 300.0]:
		for i in 24:
			var a := TAU * float(i) / 24.0
			var axis := Vector2(cos(a), sin(a))
			var centre: Vector2 = origin + axis * float(distance)
			if _open(ground, mask, centre, axis, LENGTH_M + 16.0, BEAM_M + 16.0):
				return {"centre": centre, "axis": axis}
	return {}

## Whether a `length` x `beam` rectangle round `centre` along `axis` is
## all water, clear of buildings and roads.
static func _open(ground: GroundTruth, mask: VegetationMask, centre: Vector2, axis: Vector2,
		length: float, beam: float) -> bool:
	var side := Vector2(-axis.y, axis.x)
	for along in [-0.5, 0.0, 0.5]:
		for across in [-0.5, 0.0, 0.5]:
			var p: Vector2 = centre + axis * length * float(along) + side * beam * float(across)
			if not ground.is_inside(p.x, p.y) or ground.water_at(p.x, p.y) < 0.5 \
					or mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD, 0.0):
				return false
	return true

static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return 0
	var count := 0
	var m := WorldScale.metres_to_units()
	for b in data.buildings:
		if not (b is Dictionary) or not terminal(b):
			continue
		var site := berth(b, ground, mask)
		if site.is_empty():
			continue
		var p: Vector2 = site["centre"]
		var axis: Vector2 = site["axis"]
		print("HARBOUR-FERRY berth=(%.1f, %.1f) axis=(%.2f, %.2f)" % [p.x, p.y, axis.x, axis.y])
		_commit(root, model(), "HarbourFerry_", p, axis, ground, LENGTH_M, BEAM_M)
		count = 1
		break
	var driver := RouteBoatDriver.new()
	driver.name = "RouteBoats"
	# One shared separation list across every moving fleet: each fleet below
	# keeps clear of the moored rows and of the fleets placed before it, so
	# a berthed ferry and a passing liner never share a hull rectangle.
	var moored := HarbourTraffic.plan(data, ground, mask)
	var small := route_boats(data, ground, mask, moored)
	# Berthed static hulls keep moving ships off their rectangles: a liner
	# dwelling at its terminal never overlaps the ferry, liner, hotel ship
	# or cargo ship already berthed there. MarinaBuilder ran just above,
	# so its berths are reused; a direct build (tests) plans them here with
	# an empty claim map instead.
	var static_ships := MarinaBuilder.static_ships(data, ground)
	if static_ships.is_empty() and not data.has_meta(MarinaBuilder.STATIC_META):
		QuayMoorings.begin_plan(data, m)
		static_ships = QuayMoorings.liners(data, ground, {}, m, mask)
		static_ships.append_array(CargoBerths.plan(data, ground, {}, m, mask, static_ships))
		QuayMoorings.end_plan()
	var seed: Array = small.duplicate()
	for s in static_ships:
		var sc: Vector3 = s[0]
		seed.append({"centre": Vector2(sc.x, sc.z), "length": float(s[2])})
	for boat in small:
		var bid := _next_boat_id(driver)
		var spec: Dictionary = VESSELS[str(boat["vessel"])]
		var parts := _commit(root, vessel_model(str(boat["vessel"])), "RouteFerry_", boat["centre"], boat["axis"],
			ground, float(spec["length"]), float(spec["beam"]), bid)
		driver.boats.append({"id": bid, "route": boat["route"], "pts": boat["pts"], "s": boat["t"], "lo": boat["lo"], "hi": boat["hi"],
			"dir": boat["dir"], "across": boat["across"], "speed": float(spec["speed"]) * m,
			"y": ground.water_level_at((boat["centre"] as Vector2).x, (boat["centre"] as Vector2).y),
			"length": float(spec["length"])})
		for part in parts:
			part.set_meta("ferry_route", str(boat["route"]))
		var at: Vector2 = boat["centre"]
		print("HARBOUR-ROUTE %s %s at=(%.1f, %.1f)" % [boat["route"], boat["vessel"], at.x, at.y])
		count += 1
	var liners := liner_boats(data, ground, mask, seed)
	for liner in liners:
		var bid := _next_boat_id(driver)
		var route: Dictionary = liner["route_row"]
		var prefix := "CruiseLiner_" if str(route.get("model", "cruise_ferry")) == "liner" else "LinerFerry_"
		var parts := _commit(root, liner_model(route, liner), prefix, liner["centre"], liner["axis"],
			ground, float(route["length"]), float(route["beam"]), bid)
		driver.boats.append({"id": bid, "route": str(liner["route"]), "pts": liner["pts"], "s": liner["t"],
			"lo": liner["lo"], "hi": liner["hi"], "dir": liner["dir"], "across": liner["across"],
			"speed": float(route["speed"]) * m, "accel": LINER_ACCEL_MS2, "brake": LINER_BRAKE_MS2,
			"turn": LINER_TURN_RAD_S, "dwell": LINER_DWELL_S,
			"y": ground.water_level_at((liner["centre"] as Vector2).x, (liner["centre"] as Vector2).y),
			"length": float(route["length"])})
		for part in parts:
			part.set_meta("liner_route", str(liner["route"]))
		var pos: Vector2 = liner["centre"]
		print("HARBOUR-LINER %s at=(%.1f, %.1f)" % [liner["route"], pos.x, pos.y])
		count += 1
	var moving: Array = small.duplicate()
	moving.append_array(liners)
	# Commuter ferries, icebreakers and market boats of rows in view (Helsinki).
	count += HarbourTraffic.build(root, data, ground, mask)
	count += _bangkok_boats(root, data, ground, mask, driver, _next_boat_id(driver), m, moving)
	count += _venice_boats(root, data, ground, mask, driver, _next_boat_id(driver), m, moving)
	if not driver.boats.is_empty():
		root.add_child(driver)
	else:
		driver.free()
	return count

static func _bangkok_boats(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask,
		driver: RouteBoatDriver, next_id: int, m: float, seed: Array = []) -> int:
	if CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) != "bangkok":
		return 0
	var eye := View360.spawn_xz(data)
	var bridge_list := QuayMoorings.bridges(data, m)
	var taken: Array = seed.duplicate()
	var added := 0
	for row: Dictionary in BangkokVesselModels.ROUTES:
		var pts := PackedVector2Array()
		for pt in row["points"]:
			pts.append(WorldScale.xz_from_latlon(float(pt[0]), float(pt[1]), data.latitude, data.longitude))
		if not HarbourTraffic._any_inside(ground, pts):
			continue
		var total := MarinaBuilder._length(pts)
		var length := float(row["length_m"])
		var beam := float(row["beam_m"])
		var model_name := str(row["model"])
		for share in row["boats"]:
			var site := _route_site(pts, total, float(share), length, beam, ground, mask, bridge_list, eye, taken, m)
			if site.is_empty():
				continue
			taken.append({"centre": site["centre"], "length": length})
			var lm := LandmarkMesh.new()
			BangkokVesselModels.build(lm, model_name, {
				"length": length, "beam": beam, "detail": true, "maps": true,
				"flag": str(row.get("flag", "#E86A1E")),
			})
			_commit(root, lm, "BangkokBoat_", site["centre"], site["axis"], ground, length, beam, next_id + added)
			added += 1
	return added

static func _venice_boats(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask,
		driver: RouteBoatDriver, next_id: int, m: float, seed: Array = []) -> int:
	if CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) != "venice":
		return 0
	var eye := View360.spawn_xz(data)
	var bridge_list := QuayMoorings.bridges(data, m)
	var taken: Array = seed.duplicate()
	var added := 0
	for row: Dictionary in VeniceVesselModels.ROUTES:
		var pts := PackedVector2Array()
		for pt in row["points"]:
			pts.append(WorldScale.xz_from_latlon(float(pt[0]), float(pt[1]), data.latitude, data.longitude) * m)
		if not HarbourTraffic._any_inside(ground, pts):
			continue
		var total := MarinaBuilder._length(pts)
		var length := float(row["length_m"])
		var beam := float(row["beam_m"])
		var model_name := str(row["model"])
		var shares: Array = row["boats"]
		for i in shares.size():
			var site := _route_site(pts, total, float(shares[i]), length, beam, ground, mask, bridge_list, eye, taken, m)
			if site.is_empty():
				continue
			taken.append({"centre": site["centre"], "length": length})
			var axis: Vector2 = site["axis"]
			if i % 2 == 1:
				axis = -axis
			var lm := LandmarkMesh.new()
			VeniceVesselModels.build(lm, model_name, {"length": length, "beam": beam, "detail": true, "maps": true})
			var bid := next_id + added
			_commit(root, lm, "VeniceBoat_", site["centre"], axis, ground, length, beam, bid)
			var span := _span(pts, total, float(site["t"]), float(site["across"]), length, beam, ground, mask, bridge_list, m)
			driver.boats.append({"id": bid, "route": str(row["id"]), "pts": pts, "s": site["t"], "lo": span.x, "hi": span.y,
				"dir": -1.0 if i % 2 == 1 else 1.0, "across": site["across"], "speed": float(row.get("speed", 3.5)) * m,
				"y": ground.water_level_at((site["centre"] as Vector2).x, (site["centre"] as Vector2).y),
				"length": length})
			added += 1
	return added

static func _commit(root: Node3D, lm: LandmarkMesh, prefix: String, p: Vector2, axis: Vector2,
		ground: GroundTruth, length: float, beam: float, boat_id: int = -1) -> Array[MeshInstance3D]:
	var m2u := WorldScale.metres_to_units()
	var wpos := Vector3(p.x, ground.water_level_at(p.x, p.y), p.y)
	var yaw := atan2(-axis.y, axis.x)
	var parts := lm.commit(root, prefix)
	for part in parts:
		part.position = wpos
		part.rotation.y = yaw
		part.scale = Vector3.ONE * m2u
		part.set_meta("procedural_ferry", true)
	var wake := WaterWakes.add_wake(root, wpos, yaw, length * m2u, beam * m2u)
	# A boat a RouteBoatDriver moves: its parts and wake share an id.
	if boat_id >= 0:
		wake.set_meta("boat_id", boat_id)
		for part in parts:
			part.set_meta("boat_id", boat_id)
	return parts

## The route boats of `data`: {"route", "vessel", "centre" (world XZ),
## "axis" (bow direction), "length" (m)}, ROUTES order. `seed` holds taken
## {"centre", "length"} hulls of fleets placed earlier (moored rows); every
## fleet below keeps the same contract, so no two hulls overlap at build.
static func route_boats(data: LocationData, ground: GroundTruth, mask: VegetationMask, seed: Array = []) -> Array:
	var out: Array = []
	var taken: Array = seed.duplicate()
	var m := WorldScale.metres_to_units()
	var eye := View360.spawn_xz(data)
	var bridge_list := {}
	for route: Dictionary in ROUTES:
		var pts := PackedVector2Array()
		for ll: Array in route["points"]:
			pts.append(WorldScale.xz_from_latlon(float(ll[0]), float(ll[1]), data.latitude, data.longitude) * m)
		var inside := false
		for q in pts:
			inside = inside or ground.is_inside(q.x, q.y)
		if not inside:
			continue
		if bridge_list.is_empty():
			bridge_list = QuayMoorings.bridges(data, m)
		var spec: Dictionary = VESSELS[str(route["vessel"])]
		var length := float(spec["length"])
		var beam := float(spec["beam"])
		var total := MarinaBuilder._length(pts)
		var boats: Array = route["boats"]
		for i in boats.size():
			var site := _route_site(pts, total, float(boats[i]), length, beam, ground, mask, bridge_list, eye,
				taken, m)
			if site.is_empty():
				continue
			var axis: Vector2 = site["axis"]
			if i % 2 == 1:
				axis = -axis
			var span := _span(pts, total, float(site["t"]), float(site["across"]), length, beam, ground, mask,
				bridge_list, m)
			out.append({"route": str(route["id"]), "vessel": str(route["vessel"]), "centre": site["centre"],
				"axis": axis, "pts": pts, "t": site["t"], "across": site["across"], "lo": span.x, "hi": span.y,
				"dir": -1.0 if i % 2 == 1 else 1.0, "length": length})
			taken.append({"centre": site["centre"], "length": length})
		_keep_apart(out, str(route["id"]), (length + 20.0) * m)
	return out

## The stretch [lo, hi] of arc length round `t` over which a hull `across`
## off the line stays in open water clear of bridges, in SPAN_STEP_M steps.
static func _span(pts: PackedVector2Array, total: float, t: float, across: float, length: float, beam: float,
		ground: GroundTruth, mask: VegetationMask, bridge_list: Dictionary, m: float) -> Vector2:
	var out := Vector2(t, t)
	for dir_s: float in [-1.0, 1.0]:
		var at_t := t
		while true:
			var next := at_t + dir_s * SPAN_STEP_M * m
			if next < length * 0.5 * m or next > total - length * 0.5 * m:
				break
			var sample := MarinaBuilder._at(pts, next, [0, 0.0])
			var dir: Vector2 = sample[1]
			var c: Vector2 = (sample[0] as Vector2) + Vector2(-dir.y, dir.x) * across * m
			if not _open(ground, mask, c, dir, (length + 2.0 * MARGIN_M) * m, (beam + 2.0 * MARGIN_M) * m) \
					or QuayMoorings.near_bridge(bridge_list, c - dir * length * 0.5 * m, c + dir * length * 0.5 * m,
						(beam * 0.5 + MARGIN_M) * m):
				break
			at_t = next
		if dir_s < 0.0:
			out.x = at_t
		else:
			out.y = at_t
	return out

## Cuts the stretches of the boats of `route` (the last ones of `out`) so that
## neighbours never reach each other: each keeps `gap` short of the midpoint.
static func _keep_apart(out: Array, route: String, gap: float) -> void:
	var line: Array = out.filter(func(b: Dictionary) -> bool: return b["route"] == route)
	line.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	for i in line.size() - 1:
		var mid := (float(line[i]["t"]) + float(line[i + 1]["t"])) * 0.5
		line[i]["hi"] = minf(float(line[i]["hi"]), maxf(mid - gap * 0.5, float(line[i]["t"])))
		line[i + 1]["lo"] = maxf(float(line[i + 1]["lo"]), minf(mid + gap * 0.5, float(line[i + 1]["t"])))

static func _route_site(pts: PackedVector2Array, total: float, share: float, length: float, beam: float,
		ground: GroundTruth, mask: VegetationMask, bridge_list: Dictionary, eye: Vector2, taken: Array,
		m: float) -> Dictionary:
	for along: float in ALONG_M:
		var t := clampf(total * share + along * m, length * m, total - length * m)
		var sample := MarinaBuilder._at(pts, t, [0, 0.0])
		var at: Vector2 = sample[0]
		var dir: Vector2 = sample[1]
		var side := Vector2(-dir.y, dir.x)
		for across: float in ACROSS_M:
			var c: Vector2 = at + side * across * m
			if c.distance_to(eye) < (EYE_CLEAR_M + length * 0.5) * m \
					or not _open(ground, mask, c, dir, (length + 2.0 * MARGIN_M) * m, (beam + 2.0 * MARGIN_M) * m) \
					or QuayMoorings.near_bridge(bridge_list, c - dir * length * 0.5 * m, c + dir * length * 0.5 * m,
						(beam * 0.5 + MARGIN_M) * m):
				continue
			var clear := true
			for other: Dictionary in taken:
				var gap := hull_gap(length, float(other.get("length", length)), TAKEN_GAP_M)
				clear = clear and (other["centre"] as Vector2).distance_to(c) > gap * m
			if clear:
				return {"centre": c, "axis": dir, "t": t, "across": across}
	return {}

static func model() -> LandmarkMesh:
	return FerryVesselModel.build()

## The route boat of class `id` (VESSELS) at true size, +X bow.
static func vessel_model(id: String) -> LandmarkMesh:
	var spec: Dictionary = VESSELS[id]
	var lm := LandmarkMesh.new()
	PassengerVesselModel.build(lm, {"length": float(spec["length"]), "beam": float(spec["beam"]),
		"height": float(spec["height"]), "hull": VesselMaterials.paint(str(spec["hull"]), true, 0.42, 0.05),
		"funnel": str(spec["funnel"]), "detail": true, "maps": true, "ultra": MaterialLibrary.hi_res})
	return lm

## An unused boat id for `driver` (route, liner, Bangkok and Venice boats
## share one driver with sparse ids).
static func _next_boat_id(driver: RouteBoatDriver) -> int:
	var top := -1
	for b: Dictionary in driver.boats:
		top = maxi(top, int(b["id"]))
	return top + 1

## The moving ship of a LINER_ROUTES entry at true size, +X bow. A listed
## line (HarbourVesselData.CRUISE_LIVERIES) wears its full livery, a plain
## "livery" hex rides as the sweep colour, and a "liner" is a generic
## cruise ship.
static func liner_model(route: Dictionary, boat: Dictionary) -> LandmarkMesh:
	var length := float(route["length"])
	var beam := float(route["beam"])
	var height := float(route["height"])
	var seed_value := fposmod(float(boat.get("at", 0.5)) * 7.0 + length * 0.01, 1.0)
	if str(route.get("model", "cruise_ferry")) == "liner":
		return VesselPrototypes.geometry("liner", length, beam, height,
			VesselMaterials.paint(str(route.get("hull", "#e9e8e2")), true, 0.42, 0.05),
			true, true, seed_value)
	var line_id := str(boat.get("line", route.get("line", "")))
	var variant := ""
	if line_id != "":
		variant = "line:" + line_id
	elif str(route.get("livery", "")) != "":
		variant = str(route["livery"])
	return VesselPrototypes.geometry("cruise_ferry", length, beam, height,
		VesselMaterials.paint(str(route.get("hull", "#f0eee8")), true, 0.42, 0.05),
		true, true, seed_value, variant)

## The moving liners of `data`: one row per ship, like route_boats but on
## the LINER_ROUTES fairways with liner-sized search margins. `seed` holds
## taken {"centre", "length"} hulls of fleets placed earlier.
static func liner_boats(data: LocationData, ground: GroundTruth, mask: VegetationMask, seed: Array = []) -> Array:
	var out: Array = []
	var taken: Array = seed.duplicate()
	var m := WorldScale.metres_to_units()
	var eye := View360.spawn_xz(data)
	var bridge_list := {}
	for route: Dictionary in LINER_ROUTES:
		var pts := PackedVector2Array()
		for ll: Array in route["points"]:
			pts.append(WorldScale.xz_from_latlon(float(ll[0]), float(ll[1]), data.latitude, data.longitude) * m)
		var inside := false
		for q in pts:
			inside = inside or ground.is_inside(q.x, q.y)
		if not inside:
			continue
		if bridge_list.is_empty():
			bridge_list = QuayMoorings.bridges(data, m)
		var length := float(route["length"])
		var beam := float(route["beam"])
		var total := MarinaBuilder._length(pts)
		var ships: Array = route["boats"]
		for i in ships.size():
			var entry: Dictionary = ships[i]
			var site := _liner_site(pts, total, float(entry.get("at", 0.5)), length, beam, ground, mask,
				bridge_list, eye, taken, m)
			if site.is_empty():
				continue
			var axis: Vector2 = site["axis"]
			if i % 2 == 1:
				axis = -axis
			var span := _liner_span(pts, total, float(site["t"]), float(site["across"]), length, beam, ground,
				mask, bridge_list, m)
			out.append({"route": str(route["id"]), "route_row": route, "at": float(entry.get("at", 0.5)),
				"line": str(entry.get("line", route.get("line", ""))),
				"centre": site["centre"], "axis": axis, "pts": pts, "t": site["t"], "across": site["across"],
				"lo": span.x, "hi": span.y, "dir": -1.0 if i % 2 == 1 else 1.0, "length": length})
			taken.append({"centre": site["centre"], "length": length})
		_keep_apart(out, str(route["id"]), (length + 80.0) * m)
	return out

## Wide fallback window (m) used only when a berthed hull sits on every
## in-window site: the liner squeezes past instead of vanishing.
const LINER_ALONG_WIDE_M := [0.0, 80.0, -80.0, 180.0, -180.0, 320.0, -320.0, 500.0, -500.0]
const LINER_ACROSS_WIDE_M := [0.0, 30.0, -30.0, 70.0, -70.0, 130.0, -130.0, 200.0, -200.0, 280.0, -280.0]

static func _liner_site(pts: PackedVector2Array, total: float, share: float, length: float, beam: float,
		ground: GroundTruth, mask: VegetationMask, bridge_list: Dictionary, eye: Vector2, taken: Array,
		m: float) -> Dictionary:
	var site := _liner_search(pts, total, share, length, beam, ground, mask, bridge_list, eye, taken, m,
		LINER_ALONG_M, LINER_ACROSS_M)
	if not site.is_empty():
		return site
	# Squeeze past instead of vanishing: search a wider window before
	# giving up. Every cell still passes the water, bridge, eye and hull
	# checks, so a truly blocked fairway still drops the liner.
	return _liner_search(pts, total, share, length, beam, ground, mask, bridge_list, eye, taken, m,
		LINER_ALONG_WIDE_M, LINER_ACROSS_WIDE_M)

static func _liner_search(pts: PackedVector2Array, total: float, share: float, length: float, beam: float,
		ground: GroundTruth, mask: VegetationMask, bridge_list: Dictionary, eye: Vector2, taken: Array,
		m: float, alongs: Array, acrosses: Array) -> Dictionary:
	for along: float in alongs:
		var t := clampf(total * share + along * m, length * m, total - length * m)
		var sample := MarinaBuilder._at(pts, t, [0, 0.0])
		var at: Vector2 = sample[0]
		var dir: Vector2 = sample[1]
		var side := Vector2(-dir.y, dir.x)
		for across: float in acrosses:
			var c: Vector2 = at + side * across * m
			if c.distance_to(eye) < (LINER_EYE_CLEAR_M + length * 0.5) * m \
					or not _open(ground, mask, c, dir, (length + 2.0 * LINER_MARGIN_M) * m,
						(beam + 2.0 * LINER_MARGIN_M) * m) \
					or QuayMoorings.near_bridge(bridge_list, c - dir * length * 0.5 * m,
						c + dir * length * 0.5 * m, (beam * 0.5 + LINER_MARGIN_M) * m):
				continue
			var clear := true
			for other: Dictionary in taken:
				var gap := hull_gap(length, float(other.get("length", length)), LINER_TAKEN_GAP_M)
				clear = clear and (other["centre"] as Vector2).distance_to(c) > gap * m
			if clear:
				return {"centre": c, "axis": dir, "t": t, "across": across}
	return {}

static func _liner_span(pts: PackedVector2Array, total: float, t: float, across: float, length: float,
		beam: float, ground: GroundTruth, mask: VegetationMask, bridge_list: Dictionary, m: float) -> Vector2:
	var out := Vector2(t, t)
	for dir_s: float in [-1.0, 1.0]:
		var at_t := t
		while true:
			var next := at_t + dir_s * LINER_SPAN_STEP_M * m
			if next < length * 0.5 * m or next > total - length * 0.5 * m:
				break
			var sample := MarinaBuilder._at(pts, next, [0, 0.0])
			var dir: Vector2 = sample[1]
			var c: Vector2 = (sample[0] as Vector2) + Vector2(-dir.y, dir.x) * across * m
			if not _open(ground, mask, c, dir, (length + 2.0 * LINER_MARGIN_M) * m,
					(beam + 2.0 * LINER_MARGIN_M) * m) \
					or QuayMoorings.near_bridge(bridge_list, c - dir * length * 0.5 * m,
						c + dir * length * 0.5 * m, (beam * 0.5 + LINER_MARGIN_M) * m):
				break
			at_t = next
		if dir_s < 0.0:
			out.x = at_t
		else:
			out.y = at_t
	return out
