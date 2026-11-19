extends SceneTree

## Turku landmarks, bridges and architecture tests (offline):
## tools/godot_bg.sh --headless --path . --script tests/turku_landmarks_test.gd

var failures: Array[String] = []

const EXPECTED_TYPES := [
	"turku_cathedral", "turku_castle", "mikaelinkirkko", "martinkirkko",
	"turku_orthodox_church", "turku_art_museum", "vartiovuori_observatory",
	"turku_market_hall", "turku_main_library", "turku_city_theatre",
	"kakola_prison", "vanha_suurtori", "suomen_joutsen", "fori_ferry",
]

const EXPECTED_BRIDGES := [
	"br_turku_tuomiokirkkosilta", "br_turku_kirjastosilta", "br_turku_auransilta",
	"br_turku_teatterisilta", "br_turku_myllysilta", "br_turku_martinsilta",
]

func _init() -> void:
	# 1. All 14 Turku landmarks exist, have non-empty meshes, and sit inside Turku.
	for t in EXPECTED_TYPES:
		var e := LocationData.entry_for_type(t)
		_check(not e.is_empty(), "Registry entry present for %s" % t)
		if e.is_empty():
			continue
		var lat := float(e.get("lat", 0.0))
		var lon := float(e.get("lon", 0.0))
		_check(lat > 60.42 and lat < 60.47 and lon > 22.20 and lon < 22.30,
			"%s coordinates inside Turku: %s, %s" % [t, lat, lon])
		var root := LandmarkBuilder.build(t)
		var meshes := _count_meshes(root)
		_check(meshes > 0, "%s built %d meshes" % [t, meshes])
		root.free()
	# 2. All 6 Aurajoki bridges exist with conf >= 2 and build cleanly.
	for bid in EXPECTED_BRIDGES:
		var row := BridgeSpecs.row_for(bid)
		_check(not row.is_empty(), "BridgeSpec present for %s" % bid)
		if not row.is_empty():
			_check(int(row.get("conf", 0)) >= BridgeSpec.MIN_BUILT_CONF, "%s conf >= 2" % bid)
			var b := LandmarkBuilder.build_bridge(bid, float(row.get("clear", 4.5)))
			_check(_count_meshes(b) > 0, "%s bridge built geometry" % bid)
			b.free()
	# 3. Turku architecture districts & Föli bus livery.
	var z := CityStyles.zone_at(60.4518, 22.2666)
	_check(not z.is_empty() and str(z[0]) == "turku", "Turku centre resolves to city 'turku'")
	var f_ports := CityStyles.local_frame("turku", 60.4480, 22.2480)
	var ports := BuildingEra.refine("turku", "house", {"x": 0.0, "z": 0.0, "levels": 2}, f_ports, 0.5, 140.0)
	_check(ports == "turku_wood", "Port Arthur house resolves to turku_wood (got %s)" % ports)
	var f_ruissalo := CityStyles.local_frame("turku", 60.4290, 22.1500)
	var ruissalo := BuildingEra.refine("turku", "house", {"x": 0.0, "z": 0.0, "levels": 2}, f_ruissalo, 0.5, 180.0)
	_check(ruissalo == "turku_villa", "Ruissalo house resolves to turku_villa (got %s)" % ruissalo)
	_check(TransitVehicles.BUS_PAINT.has("turku"), "Föli bus paint present for turku")
	if failures.is_empty():
		print("TURKU LANDMARKS OK: %d landmarks, %d bridges, districts & Föli livery" % [
			EXPECTED_TYPES.size(), EXPECTED_BRIDGES.size()])
		quit(0)
	else:
		for msg in failures:
			printerr("TURKU LANDMARKS FAIL: ", msg)
		quit(1)

func _count_meshes(node: Node) -> int:
	var n := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for c in node.get_children():
		n += _count_meshes(c)
	return n

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
