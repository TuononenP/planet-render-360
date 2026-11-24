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
	var boat_id := 0
	for boat in route_boats(data, ground, mask):
		var spec: Dictionary = VESSELS[str(boat["vessel"])]
		var parts := _commit(root, vessel_model(str(boat["vessel"])), "RouteFerry_", boat["centre"], boat["axis"],
			ground, float(spec["length"]), float(spec["beam"]), boat_id)
		driver.boats.append({"id": boat_id, "route": boat["route"], "pts": boat["pts"], "s": boat["t"], "lo": boat["lo"], "hi": boat["hi"],
			"dir": boat["dir"], "across": boat["across"], "speed": float(spec["speed"]) * m,
			"y": ground.water_level_at((boat["centre"] as Vector2).x, (boat["centre"] as Vector2).y),
			"length": float(spec["length"])})
		boat_id += 1
		for part in parts:
			part.set_meta("ferry_route", str(boat["route"]))
		var at: Vector2 = boat["centre"]
		print("HARBOUR-ROUTE %s %s at=(%.1f, %.1f)" % [boat["route"], boat["vessel"], at.x, at.y])
		count += 1
	# Commuter ferries, icebreakers and market boats of rows in view (Helsinki).
	count += HarbourTraffic.build(root, data, ground, mask)
	count += _bangkok_boats(root, data, ground, mask, driver, boat_id, m)
	count += _venice_boats(root, data, ground, mask, driver, boat_id + count, m)
	if not driver.boats.is_empty():
		root.add_child(driver)
	else:
		driver.free()
	return count

static func _bangkok_boats(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask,
		driver: RouteBoatDriver, next_id: int, m: float) -> int:
	if CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) != "bangkok":
		return 0
	var eye := View360.spawn_xz(data)
	var bridge_list := QuayMoorings.bridges(data, m)
	var taken: Array = []
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
			taken.append({"centre": site["centre"]})
			var lm := LandmarkMesh.new()
			BangkokVesselModels.build(lm, model_name, {
				"length": length, "beam": beam, "detail": true, "maps": true,
				"flag": str(row.get("flag", "#E86A1E")),
			})
			_commit(root, lm, "BangkokBoat_", site["centre"], site["axis"], ground, length, beam, next_id + added)
			added += 1
	return added

static func _venice_boats(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask,
		driver: RouteBoatDriver, next_id: int, m: float) -> int:
	if CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) != "venice":
		return 0
	var eye := View360.spawn_xz(data)
	var bridge_list := QuayMoorings.bridges(data, m)
	var taken: Array = []
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
			taken.append({"centre": site["centre"]})
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
## "axis" (bow direction)}, ROUTES order.
static func route_boats(data: LocationData, ground: GroundTruth, mask: VegetationMask) -> Array:
	var out: Array = []
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
			var site := _route_site(pts, total, float(boats[i]), length, beam, ground, mask, bridge_list, eye, out, m)
			if site.is_empty():
				continue
			var axis: Vector2 = site["axis"]
			if i % 2 == 1:
				axis = -axis
			var span := _span(pts, total, float(site["t"]), float(site["across"]), length, beam, ground, mask,
				bridge_list, m)
			out.append({"route": str(route["id"]), "vessel": str(route["vessel"]), "centre": site["centre"],
				"axis": axis, "pts": pts, "t": site["t"], "across": site["across"], "lo": span.x, "hi": span.y,
				"dir": -1.0 if i % 2 == 1 else 1.0})
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
				clear = clear and (other["centre"] as Vector2).distance_to(c) > (length + 20.0) * m
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
