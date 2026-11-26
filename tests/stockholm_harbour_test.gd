extends SceneTree

## Headless: godot --headless --script tests/stockholm_harbour_test.gd
## Stockholm's water traffic, offline on a synthetic map: the Djurgården
## ferries and white Waxholm boats stand on their routes (HarbourFerries
## ROUTES), Viking and Silja ferries berth at Stadsgården and Värtahamnen
## from the preset eye's distance (QuayMoorings FERRY_PORTS, 4.5 km reach),
## the Strandvägen steamboat row and the Söder Mälarstrand houseboats are
## dressed (QUAY_ROWS), and Paris and Helsinki get none of it.

## The preset eye (Monteliusvägen) and the one over Nybroplan, as lat/lon.
const MONTELIUS := Vector2(59.3207, 18.0604)
const NYBROPLAN := Vector2(59.3330, 18.0780)
## World centres. A world reaches 1,200 m each way from its centre
## (GroundTruth), so each of these holds its sight in the ground: the
## ports and rows are 1.4-1.8 km from the eye, past a plain liner berth.
const ROUTE_WORLD := Vector2(59.3250, 18.0930)
const STADSGARDEN_WORLD := Vector2(59.3190, 18.0757)
const VARTAHAMNEN_WORLD := Vector2(59.3415, 18.0945)
const STRANDVAGEN_WORLD := Vector2(59.3314, 18.0885)
const SODER_WORLD := Vector2(59.3207, 18.0520)
const MALAREN_WORLD := Vector2(59.3250, 18.0440)

var failures: Array[String] = []

func _init() -> void:
	var m := WorldScale.metres_to_units()
	_route_checks(m)
	_port_checks(m)
	_row_checks(m)
	_malar_checks(m)
	_row_silhouette_checks(m)
	_other_city_checks(m)
	if failures.is_empty():
		print("STOCKHOLM HARBOUR OK: Djurgården and Waxholm routes, Viking/Silja ports at 4.5 km, steamboat row, houseboats, other cities unchanged")
		quit(0)
	else:
		for f in failures:
			printerr("STOCKHOLM HARBOUR FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

## An Ultra world centred on `at`, `height` everywhere, no map but what
## the caller adds. The eye stands at `eye` (lat/lon) when given, else at
## the centre.
func _data(at: Vector2, height: float, eye: Vector2 = Vector2.INF) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(height)
	d.water_level = 0.0
	d.seed_value = 7
	d.country = "SE"
	d.latitude = at.x
	d.longitude = at.y
	if eye != Vector2.INF:
		d.view = {"lat": eye.x, "lon": eye.y}
	return d

func _lake(d: LocationData, ring: Array) -> void:
	d.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array(ring)}]

func _ground(d: LocationData) -> GroundTruth:
	return GroundTruth.new(d)

func _world_xz(d: LocationData, lat: float, lon: float) -> Vector2:
	return WorldScale.xz_from_latlon(lat, lon, d.latitude, d.longitude) * WorldScale.metres_to_units()

# --- ferries under way ---------------------------------------------------

func _route_checks(m: float) -> void:
	var d := _data(ROUTE_WORLD, -8.0)
	var e := 2400.0 * m
	_lake(d, [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e)])
	var g := _ground(d)
	var mask := VegetationMask.new(d, g)
	var boats := HarbourFerries.route_boats(d, g, mask)
	var by_route := {}
	for boat: Dictionary in boats:
		by_route[boat["route"]] = int(by_route.get(boat["route"], 0)) + 1
		var spec: Dictionary = HarbourFerries.VESSELS[str(boat["vessel"])]
		_check(HarbourFerries._open(g, mask, boat["centre"], boat["axis"], float(spec["length"]) * m, float(spec["beam"]) * m),
			"%s boat stands in open water" % boat["route"])
	_check(int(by_route.get("djurgarden_slussen", 0)) == 1, "line 82 should carry its Djurgården ferry, got %s" % by_route)
	_check(int(by_route.get("waxholm_stromkajen", 0)) == 2, "the Strömkajen route should carry two Waxholm boats, got %s" % by_route)
	var classes := {"waxholm": "waxholm", "malaren": "steamer", "sightseeing": "sightseeing"}
	for boat: Dictionary in boats:
		var want := "djurgarden"
		for prefix: String in classes:
			if str(boat["route"]).begins_with(prefix):
				want = classes[prefix]
		_check(str(boat["vessel"]) == want, "%s runs the wrong vessel class %s" % [boat["route"], boat["vessel"]])
	# Strömmen carries sightseeing boats; Riddarfjärden's steamer is checked in its own world.
	_check(int(by_route.get("sightseeing_stromkajen", 0)) >= 1, "Strömmen should carry a sightseeing boat, got %s" % by_route)
	_check(Color.html(HarbourFerries.VESSELS["steamer"]["hull"]).get_luminance() < 0.2, "the Mälaren steamer has a black hull")
	var malaren := _data(MALAREN_WORLD, -8.0)
	_lake(malaren, [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e)])
	var mg := _ground(malaren)
	var steamers := HarbourFerries.route_boats(malaren, mg, VegetationMask.new(malaren, mg)).filter(
		func(b: Dictionary) -> bool: return b["route"] == "malaren_steamer")
	_check(steamers.size() == 2, "Riddarfjärden should carry two Mälaren steamers, got %d" % steamers.size())
	if steamers.size() == 2:
		_check((steamers[0]["axis"] as Vector2).dot(steamers[1]["axis"]) < 0.0, "the Mälaren steamers run opposite ways")
	# The two Waxholm boats run opposite ways.
	var ways: Array[Vector2] = []
	for boat: Dictionary in boats:
		if boat["route"] == "waxholm_stromkajen":
			ways.append(boat["axis"])
	_check(ways.size() == 2 and ways[0].dot(ways[1]) < 0.0, "Waxholm boats should alternate outbound and inbound")
	# Vessel classes: dark green Djurgården ferry, white Waxholm boat.
	_check(Color.html(HarbourFerries.VESSELS["djurgarden"]["hull"]).g > Color.html(HarbourFerries.VESSELS["djurgarden"]["hull"]).r,
		"the Djurgården ferry has a green hull")
	var wax := Color.html(HarbourFerries.VESSELS["waxholm"]["hull"])
	_check(wax.r > 0.9 and wax.g > 0.9 and wax.b > 0.85, "the Waxholm boat has a white hull")
	_check(float(HarbourFerries.VESSELS["waxholm"]["length"]) > float(HarbourFerries.VESSELS["djurgarden"]["length"]),
		"a Waxholm boat is longer than a Djurgården ferry")
	# They reach the world as meshes, tagged with their route.
	var root := Node3D.new()
	var liners := HarbourFerries.liner_boats(d, g, mask)
	var placed := HarbourFerries.build(root, d, g, mask)
	_check(placed == boats.size() + liners.size(),
		"build() should place every route boat and liner, got %d of %d" % [placed, boats.size() + liners.size()])
	var tagged := 0
	for node in root.find_children("RouteFerry_*", "MeshInstance3D", true, false):
		tagged += 1 if str(node.get_meta("ferry_route", "")) != "" else 0
	_check(tagged >= boats.size(), "route ferry meshes should carry their route")
	var liner_tagged := 0
	for prefix in ["LinerFerry_*", "CruiseLiner_*"]:
		for node in root.find_children(prefix, "MeshInstance3D", true, false):
			liner_tagged += 1 if str(node.get_meta("liner_route", "")) != "" else 0
	_check(liner_tagged >= liners.size(), "liner meshes should carry their route")
	_motion_checks(root, boats.size() + liners.size(), m)
	_liner_checks(liners, m)
	root.free()
	# A boat never stands across a bridge or on land.
	var bridged := _data(ROUTE_WORLD, -8.0)
	_lake(bridged, [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e)])
	var first: Dictionary = boats[0] if not boats.is_empty() else {}
	if not first.is_empty():
		var c: Vector2 = first["centre"]
		bridged.roads = [{"class": "primary", "width_m": 12.0, "bridge": true,
			"points": PackedVector2Array([c - Vector2(0.0, 200.0 * m), c + Vector2(0.0, 200.0 * m)])}]
		var bg := _ground(bridged)
		for boat: Dictionary in HarbourFerries.route_boats(bridged, bg, VegetationMask.new(bridged, bg)):
			_check((boat["centre"] as Vector2).distance_to(c) > 20.0 * m or boat["route"] != first["route"],
				"no route boat under a bridge")
	var dry := _data(ROUTE_WORLD, 5.0)
	var dg := _ground(dry)
	_check(HarbourFerries.route_boats(dry, dg, VegetationMask.new(dry, dg)).is_empty(), "no route boat on dry land")
	# Ultra only.
	var high := _data(ROUTE_WORLD, -8.0)
	high.quality_preset = RenderSettings.Preset.HIGH
	_lake(high, [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e)])
	var hg := _ground(high)
	var hroot := Node3D.new()
	_check(HarbourFerries.build(hroot, high, hg, VegetationMask.new(high, hg)) == 0, "route ferries and liners are Ultra only")
	hroot.free()

## The route boats travel (RouteBoatDriver): positions change over simulated time,
## the wake and every hull part follow, a boat stays on its stretch and turns
## at the end of it, and two boats of one line never come within a hull length.
func _motion_checks(root: Node3D, count: int, m: float) -> void:
	var driver := root.get_node_or_null("RouteBoats") as RouteBoatDriver
	_check(driver != null and driver.boats.size() == count, "every route boat and liner is driven")
	if driver == null or driver.boats.is_empty():
		return
	var start: Array[Vector2] = []
	for b: Dictionary in driver.boats:
		start.append(driver.position_of(int(b["id"])))
	driver.advance(60.0)
	var moved := 0
	for i in driver.boats.size():
		moved += 1 if driver.position_of(int(driver.boats[i]["id"])).distance_to(start[i]) > 10.0 * m else 0
	_check(moved >= driver.boats.size() - 1, "route boats and liners should travel over a minute, %d of %d moved" % [moved, driver.boats.size()])
	# The hull parts and the wake stand where the driver says.
	for b: Dictionary in driver.boats:
		var id := int(b["id"])
		var at := driver.position_of(id)
		for node in root.get_children():
			if node is Node3D and node.has_meta("boat_id") and int(node.get_meta("boat_id")) == id:
				_check(Vector2((node as Node3D).position.x, (node as Node3D).position.z).distance_to(at) < 0.01 * m,
					"%s of boat %d follows the driver" % [node.name, id])
	# Ten simulated minutes: always on the stretch, turned round at least once.
	var turned := 0
	var min_gap := INF
	var last_dir: Array[float] = []
	for b: Dictionary in driver.boats:
		last_dir.append(float(b["dir"]))
	for step in 600:
		driver.advance(1.0)
		for i in driver.boats.size():
			var b: Dictionary = driver.boats[i]
			_check(float(b["s"]) >= float(b["lo"]) - 0.01 and float(b["s"]) <= float(b["hi"]) + 0.01, "a boat stays on its stretch")
			if float(b["dir"]) != last_dir[i]:
				turned += 1
				last_dir[i] = float(b["dir"])
			for j in range(i + 1, driver.boats.size()):
				if driver.boats[j]["route"] == b["route"]:
					min_gap = minf(min_gap, driver.position_of(int(b["id"])).distance_to(driver.position_of(int(driver.boats[j]["id"]))))
	_check(turned >= 1, "a route boat turns round at the end of its stretch")
	_check(min_gap > 20.0 * m, "boats of one line keep a hull length apart, closest %.0f m" % min_gap)

## The moving liners of the route world: the Saltsjön fairway carries a
## Viking-red cruise ferry, liners are liner-sized with slow-turning
## drivers, and they stay in open water.
func _liner_checks(liners: Array, m: float) -> void:
	var ids := {}
	for liner: Dictionary in liners:
		ids[str(liner["route"])] = true
		var route: Dictionary = liner["route_row"]
		_check(float(route["length"]) >= 190.0 and float(route["length"]) <= 260.0,
			"a liner is liner-sized, got %.0f m" % float(route["length"]))
		_check(float(liner["hi"]) > float(liner["lo"]),
			"%s has open water to travel" % liner["route"])
	_check(ids.has("stockholm_viking"), "the Saltsjön fairway should carry a moving Viking ferry, got %s" % [ids.keys()])
	for liner: Dictionary in liners:
		if str(liner["route"]) == "stockholm_viking":
			var route: Dictionary = liner["route_row"]
			_check(str(route.get("hull", "")) == "#c21f2c",
				"the moving Stadsgården ferry is Viking red, got %s" % route.get("hull", "none"))
	for liner: Dictionary in liners:
		var lm := HarbourFerries.liner_model(liner["route_row"], liner)
		var holder := Node3D.new()
		_check(lm.commit(holder, "L_").size() >= 8, "%s builds a detailed cruise ferry" % liner["route"])
		holder.free()

# --- cruise ferries at the ports ----------------------------------------

## A mapped quay along `at`'s parallel, 500 m long, with its sea on the
## side toward the middle of the map; appends to `d`.
func _port_quay(d: LocationData, at: Vector2, m: float) -> void:
	var side := -1.0 if at.y > 0.0 else 1.0
	var a := Vector2(at.x - 250.0 * m, at.y)
	var b := Vector2(at.x + 250.0 * m, at.y)
	d.shore_structures.append({"kind": "quay", "points": PackedVector2Array([a, b])})
	var far := Vector2(0.0, side * 700.0 * m)
	d.land_polygons.append({"class": "water", "tidal": true,
		"points": PackedVector2Array([a + Vector2(-150.0 * m, 0.0), b + Vector2(150.0 * m, 0.0),
			b + Vector2(150.0 * m, 0.0) + far, a + Vector2(-150.0 * m, 0.0) + far])})

func _ferries(d: LocationData, m: float) -> Array:
	var g := _ground(d)
	var taken := {}
	QuayMoorings.begin_plan(d, m)
	var out := QuayMoorings.liners(d, g, taken, m, VegetationMask.new(d, g))
	QuayMoorings.end_plan()
	return out

func _port_checks(m: float) -> void:
	var ids: Array = QuayMoorings.FERRY_PORTS.map(func(p: Dictionary) -> String: return str(p["id"]))
	_check(ids.has("stadsgarden") and ids.has("vartahamnen"), "Stadsgården and Värtahamnen are listed ports")
	for port: Dictionary in QuayMoorings.FERRY_PORTS:
		_check(float(port["reach_m"]) >= 4500.0, "%s ferries show out to 4.5 km" % port["id"])
		_check(float(port["reach_m"]) > QuayMoorings.LINER_RADIUS_M, "%s outreaches a plain liner berth" % port["id"])
	# Stadsgården from the preset eye: 1.7 km off, past a plain liner berth.
	var d := _data(STADSGARDEN_WORLD, 3.0, MONTELIUS)
	var ports := QuayMoorings.ports(d, m)
	_check(ports.size() == 1 and ports[0]["id"] == "stadsgarden", "only Stadsgården is in this map")
	var at := _world_xz(d, 59.3170, 18.0910)
	_port_quay(d, at, m)
	var seen := _ferries(d, m)
	_check(seen.size() == 1, "one ferry berths at Stadsgården, got %d" % seen.size())
	for l: Array in seen:
		var info: Dictionary = l[7]
		_check(str(l[6]) == "ferry", "a ship at a listed port is a ferry")
		_check(str(info.get("hull", "")) == "#c21f2c" and str(info.get("livery", "")) == "#c21f2c",
			"the Stadsgården ferry is Viking red, got %s" % info.get("hull", "none"))
		var dist := Vector2((l[0] as Vector3).x, (l[0] as Vector3).z).distance_to(View360.spawn_xz(d)) / m
		_check(dist > QuayMoorings.LINER_RADIUS_M and dist <= 4500.0,
			"the Stadsgården ferry stands %.0f m from the eye: past 1.2 km, within 4.5 km" % dist)
	_check(QuayMoorings.port_at(d, at, m).get("id", "") == "stadsgarden", "port_at finds Stadsgården at its quay")
	_check(QuayMoorings.port_at(d, at + Vector2(900.0 * m, 0.0), m).is_empty(), "port_at is empty 900 m from the port")
	# Värtahamnen from the Nybroplan eye: Silja white hull, navy sweep.
	var v := _data(VARTAHAMNEN_WORLD, 3.0, NYBROPLAN)
	var vports := QuayMoorings.ports(v, m)
	_check(vports.size() == 1 and vports[0]["id"] == "vartahamnen", "only Värtahamnen is in this map")
	_port_quay(v, _world_xz(v, 59.3500, 18.1110), m)
	var silja := _ferries(v, m)
	_check(silja.size() == 1, "one ferry berths at Värtahamnen, got %d" % silja.size())
	for l: Array in silja:
		var info: Dictionary = l[7]
		_check(str(info.get("hull", "")) == "#f0eee8" and str(info.get("livery", "")) == "#1b2f5c",
			"the Värtahamnen ferry is Silja white with a navy sweep, got %s / %s" % [info.get("hull", "none"), info.get("livery", "none")])
		var dist := Vector2((l[0] as Vector3).x, (l[0] as Vector3).z).distance_to(View360.spawn_xz(v)) / m
		_check(dist > QuayMoorings.LINER_RADIUS_M and dist <= 4500.0,
			"the Värtahamnen ferry stands %.0f m from the eye: past 1.2 km, within 4.5 km" % dist)
	# The same quay far from the ports gets no port colours.
	var away := _data(Vector2(48.8566, 2.3522), 3.0)
	_port_quay(away, Vector2(0.0, -300.0 * m), m)
	_check(QuayMoorings.ports(away, m).is_empty(), "no ferry port in a Paris map")
	for l: Array in _ferries(away, m):
		_check(not (l[7] as Dictionary).has("livery"), "no port livery on a Paris quay ship")

# --- quay rows ------------------------------------------------------------

## A mapped quay through the row's lat/lon `points`, sea on the `side`
## (+1 south, -1 north) of it.
func _row_quay(d: LocationData, row: Dictionary, side: float, m: float) -> void:
	var pts := PackedVector2Array()
	for ll: Array in row["points"]:
		pts.append(_world_xz(d, float(ll[0]), float(ll[1])))
	d.shore_structures.append({"kind": "quay", "points": pts})
	var ring := PackedVector2Array(pts)
	for i in range(pts.size() - 1, -1, -1):
		ring.append(pts[i] + Vector2(0.0, side * 120.0 * m))
	d.land_polygons.append({"class": "water", "tidal": true, "points": ring})

func _row_checks(m: float) -> void:
	var rows := {}
	for row: Dictionary in QuayMoorings.QUAY_ROWS:
		rows[row["id"]] = row
	_check(rows.has("strandvagen") and rows.has("soder_malarstrand"), "both named quay rows are listed")
	_check(float(rows["strandvagen"]["reach_m"]) > MarinaBuilder.RADIUS_M, "Strandvägen is dressed beyond the generic radius")
	# Strandvägen: its sea lies south of the quay.
	var d := _data(STRANDVAGEN_WORLD, 3.0)
	_row_quay(d, rows["strandvagen"], 1.0, m)
	var g := _ground(d)
	_check(QuayMoorings.quay_rows(d, m).any(func(r: Dictionary) -> bool: return r["id"] == "strandvagen"),
		"Strandvägen is in reach of its map")
	var boats := _row_boats(d, g, m)
	var steam := 0
	for boat: Array in boats:
		steam += 1 if str(boat[3]) == "steam" else 0
	_check(boats.size() >= 6 and boats.size() <= QuayMoorings.ROW_MAX_BOATS,
		"Strandvägen should hold a steamboat row, got %d" % boats.size())
	_check(steam == boats.size(), "every Strandvägen boat is a steamer (%d of %d)" % [steam, boats.size()])
	_check(boats == _row_boats(d, g, m), "the Strandvägen row is deterministic")
	# Söder Mälarstrand: its water lies north of the quay.
	var s := _data(SODER_WORLD, 3.0)
	_row_quay(s, rows["soder_malarstrand"], -1.0, m)
	var sg := _ground(s)
	var houses := _row_boats(s, sg, m)
	var houseboats := 0
	for boat: Array in houses:
		houseboats += 1 if str(boat[3]) == "houseboat" else 0
	_check(houses.size() >= 6 and houses.size() <= QuayMoorings.ROW_MAX_BOATS,
		"Söder Mälarstrand should hold a boat row, got %d" % houses.size())
	_check(houseboats * 2 > houses.size(), "Söder Mälarstrand is mostly houseboats (%d of %d)" % [houseboats, houses.size()])
	_fleet_checks(s, sg, m)
	# Rows far beyond their reach are not dressed.
	_check(QuayMoorings.quay_rows(_data(Vector2(59.40, 18.20), 3.0), m).is_empty(), "rows far from the eye are not dressed")

## Söder Mälarstrand's own fleet (QuayFleet): not one repeated ship, spread by
## unequal gaps, every hull off the quay edge, and Riddarfjärden's hotel ship.
func _fleet_checks(d: LocationData, g: GroundTruth, m: float) -> void:
	var ships := _fleet_again(d, g, m)
	_check(ships.size() >= 4 and ships.size() <= QuayFleet.ROW_MAX, "Söder Mälarstrand should hold 4-8 fleet vessels, got %d" % ships.size())
	_check(ships == _fleet_again(d, g, m), "the Söder fleet is deterministic")
	var models := {}
	var hulls := {}
	var lengths := {}
	var quay: PackedVector2Array = d.shore_structures[0]["points"]
	var ahead := []
	for ship: Array in ships:
		models[str(ship[6])] = true
		hulls[str((ship[7] as Dictionary)["hull"])] = true
		lengths[snappedf(float(ship[2]), 0.5)] = true
		var c := Vector2((ship[0] as Vector3).x, (ship[0] as Vector3).z)
		var off := INF
		for i in quay.size() - 1:
			off = minf(off, Geometry2D.get_closest_point_to_segment(c, quay[i], quay[i + 1]).distance_to(c))
		_check(off / m > float(ship[3]) * 0.5 + 1.0, "a fleet hull stays off the quay edge (%.1f m from it, beam %.1f)" % [off / m, ship[3]])
		ahead.append(c.x)
	var moored := 0
	for ship: Array in ships:
		moored += 1 if (ship[7] as Dictionary).has("quay_sign") else 0
	_check(moored >= 1 and moored < ships.size() + 1, "vessels near the eye carry their quay side for mooring lines, got %d" % moored)
	_check(models.size() >= 3, "the fleet mixes at least three models, got %s" % [models.keys()])
	_check(hulls.size() >= 4, "the fleet wears at least four liveries, got %d" % hulls.size())
	_check(lengths.size() >= 4, "the fleet has at least four lengths, got %d" % lengths.size())
	ahead.sort()
	var gaps := {}
	for i in ahead.size() - 1:
		gaps[snappedf((float(ahead[i + 1]) - float(ahead[i])) / m, 5.0)] = true
	_check(gaps.size() >= 3, "the fleet is spaced unevenly, got %s" % [gaps.keys()])
	# The same quay in another city carries none of it.
	var paris := _data(Vector2(48.8566, 2.3522), 3.0)
	_check(QuayFleet.plan(paris, _ground(paris), {}, m).is_empty(), "no fleet vessels in Paris")
	# Riddarfjärden's liner berth becomes a hotel ship (no cruise liner at the Mälaren quays).
	var h := _data(Vector2(59.3248, 18.0600), 3.0)
	var at := _world_xz(h, 59.3243, 18.0620)
	_port_quay(h, at, m)
	var hg := _ground(h)
	QuayMoorings.begin_plan(h, m)
	var large := QuayMoorings.liners(h, hg, {}, m, VegetationMask.new(h, hg))
	QuayMoorings.end_plan()
	for ship: Array in large:
		_check(str(ship[6]).begins_with("fleet:") and float(ship[2]) <= QuayFleet.HOTEL_LENGTH_M + 0.1,
			"a Riddarfjärden quay berths a hotel ship, got %s %.0f m" % [ship[6], ship[2]])

func _fleet_again(d: LocationData, g: GroundTruth, m: float) -> Array:
	QuayMoorings.begin_plan(d, m)
	var ships := QuayFleet.plan(d, g, {}, m, VegetationMask.new(d, g))
	QuayMoorings.end_plan()
	return ships

## The boats of `d`'s named quay row (the water's own edge adds none of its own).
func _row_boats(d: LocationData, g: GroundTruth, m: float) -> Array:
	var rows := QuayMoorings.quay_rows(d, m)
	return QuayMoorings.plan(d, g, {}, m, VegetationMask.new(d, g)).filter(func(b: Array) -> bool:
		return not QuayMoorings._row_at(rows, Vector2((b[0] as Vector3).x, (b[0] as Vector3).z), m).is_empty())

# --- mapped Mälaren ships -------------------------------------------------

## MalarShips: a livery each for Stockholm's mapped steamers, a hull off the
## quay, and nothing changed elsewhere.
func _malar_checks(m: float) -> void:
	var sto := _data(SODER_WORLD, 3.0)
	var paris := _data(Vector2(48.8566, 2.3522), 3.0)
	_check(MalarShips.applies(sto, "passenger") and MalarShips.applies(sto, "liner"), "Stockholm dresses mapped steamers and liners")
	_check(not MalarShips.applies(sto, "cargo") and not MalarShips.applies(sto, "cruise_ferry"), "cargo and ro-pax ships keep their model")
	_check(not MalarShips.applies(paris, "passenger"), "Paris mapped ships keep ShipBuilder's look")
	var hulls := {}
	var models := {}
	for i in 12:
		var look := MalarShips.look(30.0 + float(i), float(i) / 12.0, "", Vector2(40.0 * float(i), -3.0))
		hulls[look["hull"]] = true
		models[look["model"]] = true
		_check(float(look["height"]) >= MalarShips.HEIGHT_MIN_M and float(look["height"]) <= MalarShips.HEIGHT_MAX_M,
			"a steamer's height stays in bounds, got %s" % look["height"])
	_check(hulls.size() >= 5, "twelve mapped ships wear at least five hulls, got %d" % hulls.size())
	for i in 11:
		_check(MalarShips.look(40.0, 0.5, "", Vector2(40.0 * float(i), -3.0))["hull"]
			!= MalarShips.look(40.0, 0.5, "", Vector2(40.0 * float(i + 1), -3.0))["hull"],
			"neighbours 40 m apart wear different hulls")
	_check(models.has("restaurant_boat") and models.has("passenger"), "some take the café-boat model, most the steamer")
	_check(MalarShips.look(150.0, 0.9, "")["model"] == "passenger", "a liner-sized mapped hull becomes a steamer")
	# Moored hulls carry lines and fenders where the quay side is known, none otherwise.
	var holder := Node3D.new()
	var moored := {"hull": "#e9e6dc", "funnel": "#24415f", "quay_sign": 1.0, "quay_gap": 5.0}
	var with_lines := QuayFleet.vessel("passenger", 40.0, 7.0, 12.0, moored, true, true).commit(holder, "T_")
	var without := QuayFleet.vessel("passenger", 40.0, 7.0, 12.0, {"hull": "#e9e6dc", "funnel": "#24415f"}, true, true).commit(holder, "U_")
	var ropes := 0
	var fenders := 0
	for part in with_lines:
		ropes += 1 if str(part.name).contains("Rope") else 0
		fenders += 1 if str(part.name).contains("Fender") else 0
	_check(ropes >= 1 and fenders >= 1, "a moored steamer carries mooring lines and fenders, got %d and %d" % [ropes, fenders])
	_check(with_lines.size() - without.size() <= 4, "moorings add at most four surfaces to a hull, got %d" % (with_lines.size() - without.size()))
	for part in without:
		_check(not str(part.name).contains("Fender"), "a hull with no known quay side has no fenders")
	holder.free()
	_check(MalarShips.look(30.0, 0.5, "#c01010")["hull"] == "#c01010", "a mapped colour wins")
	# The hull moves off the quay toward the water.
	var d := _data(SODER_WORLD, 3.0)
	var e := 1500.0 * m
	d.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-e, -e), Vector2(e, -e), Vector2(e, 0.0), Vector2(-e, 0.0)])}]
	var g := _ground(d)
	var shift := MalarShips.offshore(g, Vector2(0.0, -4.0 * m), Vector2(1.0, 0.0), 8.0 * m)
	_check(shift.y < 0.0 and absf(shift.length() - MalarShips.OFFSHORE_M) < 0.001, "a hull at the quay edge moves toward the water, got %s" % shift)
	_check(MalarShips.offshore(g, Vector2(0.0, -400.0 * m), Vector2(1.0, 0.0), 8.0 * m) == Vector2.ZERO,
		"a hull far from any quay stays where it is")

# --- the Söder row's silhouettes -------------------------------------------

## Mapped building=ship footprints along a quay (lengths 18-70 m): at least four
## hull types, none beside the same type, each allowed by its footprint, and the
## built meshes carry those types (and the two new models build).
func _row_silhouette_checks(m: float) -> void:
	var d := _data(SODER_WORLD, -8.0)
	var e := 2400.0 * m
	_lake(d, [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e)])
	var g := _ground(d)
	var lengths := [48.0, 40.0, 32.0, 59.0, 45.0, 20.0, 66.0, 38.0, 52.0]
	for i in lengths.size():
		d.buildings.append({"kind": "ship", "x": -200.0 * m + 55.0 * m * float(i), "z": -60.0 * m,
			"size_x": float(lengths[i]) * m, "size_z": float(lengths[i]) * 0.2 * m, "name": "Ship %d" % i})
	var plan := MalarShips.plan(d)
	_check(plan.size() == lengths.size(), "every mapped steamer is planned, got %d" % plan.size())
	var keys: Array = plan.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	var kinds := {}
	for i in keys.size():
		kinds[plan[keys[i]]] = true
		if i > 0:
			_check(plan[keys[i]] != plan[keys[i - 1]], "neighbouring hulls %d and %d are both %s" % [i - 1, i, plan[keys[i]]])
		_check(MalarShips.eligible(float(lengths[i]), float(lengths[i]) * 0.2).has(plan[keys[i]]),
			"hull %d (%.0f m) is a %s its footprint does not allow" % [i, lengths[i], plan[keys[i]]])
	var barques := 0
	for k in keys:
		barques += 1 if plan[k] == "tall_ship" else 0
	_check(barques <= 1, "a row holds at most one sailing ship, got %d" % barques)
	_check(kinds.size() >= 4, "the row mixes at least four hull types, got %s" % [kinds.keys()])
	_check(plan == MalarShips.plan(d), "the row's hull types are deterministic")
	var root := Node3D.new()
	var built := {}
	for b in d.buildings:
		_check(ShipBuilder.build(root, b, d, g), "a mapped ship builds")
	for part in root.get_children():
		if part.has_meta("vessel_model"):
			built[str(part.get_meta("vessel_model"))] = true
	_check(built.size() >= 4, "the built row carries at least four hull types, got %s" % [built.keys()])
	root.free()
	for model in MalarVesselModels.MODELS:
		var lm := QuayFleet.vessel(model, 40.0, 7.0, 12.0, {"hull": "#e9e6dc", "funnel": "#24415f"}, true, true)
		var holder := Node3D.new()
		_check(lm.commit(holder, "S_").size() >= 8, "%s builds a detailed hull and house" % model)
		holder.free()
	# The barque's rig stays near half its length, with set canvas on the yards.
	var barque := QuayFleet.vessel("tall_ship", 40.0, 8.0, MalarShips.look(40.0, 0.5, "", Vector2.ZERO, "tall_ship")["height"],
		{"hull": "#2a2420"}, true, true)
	var rig := Node3D.new()
	var top := 0.0
	var sail_tris := 0
	for part in barque.commit(rig, "B_"):
		var arrays := (part as MeshInstance3D).mesh.surface_get_arrays(0)
		for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			top = maxf(top, v.y)
		if str(part.name).contains("Sail"):
			sail_tris += int((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
	rig.free()
	_check(top > 40.0 * 0.4 and top < 40.0 * 0.62, "a 40 m barque's masts reach about half its length, got %.1f m" % top)
	_check(sail_tris > 150, "the barque carries set square sails, got %d sail triangles" % sail_tris)
	_check(barque.triangle_count() < 40000, "the barque stays inside its triangle budget, got %d" % barque.triangle_count())
	# Another city's mapped ships keep one model.
	var paris := _data(Vector2(48.8566, 2.3522), -8.0)
	paris.buildings = d.buildings.duplicate()
	_check(MalarShips.model_at(paris, Vector2(-200.0 * m, -60.0 * m)) == "" and not MalarShips.applies(paris, "passenger"),
		"Paris mapped ships get no Stockholm hull types")

# --- other cities ---------------------------------------------------------

func _other_city_checks(m: float) -> void:
	for city in [["Paris", Vector2(48.8566, 2.3522)], ["Helsinki", Vector2(60.1665, 24.9600)],
			["New York", Vector2(40.7033, -74.0170)]]:
		var at: Vector2 = city[1]
		var d := _data(at, -8.0)
		var e := 2400.0 * m
		_lake(d, [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e)])
		var g := _ground(d)
		_check(HarbourFerries.route_boats(d, g, VegetationMask.new(d, g)).is_empty(),
			"%s gets no Stockholm route boats" % city[0])
		_check(QuayMoorings.ports(d, m).is_empty() and QuayMoorings.port_at(d, Vector2.ZERO, m).is_empty(),
			"%s has no Stockholm ferry port" % city[0])
		var rows := QuayMoorings.quay_rows(d, m)
		_check(rows.all(func(r: Dictionary) -> bool: return str(r["id"]) not in ["strandvagen", "soder_malarstrand"]),
			"%s has no Stockholm quay row" % city[0])
	# New York still gets its Staten Island ferry beside the terminal.
	var ny := _data(Vector2(40.7033, -74.0170), -8.0)
	var e2 := 2400.0 * m
	_lake(ny, [Vector2(-e2, -e2), Vector2(e2, -e2), Vector2(e2, e2), Vector2(-e2, e2)])
	ny.buildings = [{"name": "Staten Island Ferry Whitehall Terminal", "use": "ferry_terminal", "x": 0.0, "z": 0.0}]
	var ng := _ground(ny)
	var root := Node3D.new()
	var count := HarbourFerries.build(root, ny, ng, VegetationMask.new(ny, ng))
	_check(count == 1 and root.find_children("HarbourFerry_*", "MeshInstance3D", true, false).size() > 0,
		"New York keeps its one Staten Island ferry, got %d" % count)
	root.free()
