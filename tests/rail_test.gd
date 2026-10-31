extends SceneTree

## Headless: godot --headless --script tests/rail_test.gd
## Railway layer: OsmParser reads track, platform and station / subway
## entrance elements into LocationData shapes (gauge, bridge, tunnel,
## embedded tram, covered, direction); RailBuilder draws ballast, rails
## and sleepers for surface track, nothing for tunnels, a viaduct deck
## well above the ground for a long elevated line, platforms at their
## height above the rail with a canopy, and New York style entrances
## (green railing + globe lamps) in North America only.

const FIXTURE := """
{"elements":[
 {"type":"way","id":10,"tags":{"railway":"rail","gauge":"1435","electrified":"contact_line"},
  "geometry":[{"lat":40.7500,"lon":-73.9900},{"lat":40.7500,"lon":-73.9860}]},
 {"type":"way","id":11,"tags":{"railway":"subway","tunnel":"yes","layer":"-2"},
  "geometry":[{"lat":40.7510,"lon":-73.9900},{"lat":40.7510,"lon":-73.9860}]},
 {"type":"way","id":12,"tags":{"railway":"tram"},
  "geometry":[{"lat":40.7490,"lon":-73.9900},{"lat":40.7490,"lon":-73.9860}]},
 {"type":"way","id":13,"tags":{"railway":"narrow_gauge","gauge":"1000","bridge":"yes","layer":"1"},
  "geometry":[{"lat":40.7480,"lon":-73.9900},{"lat":40.7480,"lon":-73.9860}]},
 {"type":"way","id":14,"tags":{"railway":"platform","covered":"yes","name":"P1"},
  "geometry":[{"lat":40.75004,"lon":-73.9895},{"lat":40.75004,"lon":-73.9885},
              {"lat":40.75008,"lon":-73.9885},{"lat":40.75008,"lon":-73.9895},
              {"lat":40.75004,"lon":-73.9895}]},
 {"type":"way","id":15,"tags":{"railway":"abandoned"},
  "geometry":[{"lat":40.7470,"lon":-73.9900},{"lat":40.7470,"lon":-73.9860}]},
 {"type":"node","id":20,"tags":{"railway":"subway_entrance","name":"34 St","direction":"90"},
  "lat":40.7505,"lon":-73.9880},
 {"type":"node","id":21,"tags":{"railway":"station","station":"subway","name":"34 St"},
  "lat":40.7506,"lon":-73.9881},
 {"type":"node","id":22,"tags":{"railway":"subway_entrance","entrance":"elevator"},
  "lat":40.7504,"lon":-73.9875}
]}
"""

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	_parse(failures)
	_build(failures)
	if failures.is_empty():
		print("RAIL TEST OK")
		quit(0)
	else:
		for f in failures:
			printerr("RAIL TEST FAIL: ", f)
		quit(1)

func _parse(failures: Array[String]) -> void:
	var r := OsmParser.parse_features(FIXTURE, 40.7500, -73.9880)
	var rails: Array = r.get("railways", [])
	var platforms: Array = r.get("rail_platforms", [])
	var stops: Array = r.get("transit_stops", [])
	if rails.size() != 4:
		failures.append("expected 4 track ways (abandoned skipped), got %d" % rails.size())
		return
	if absf(float(rails[0]["gauge_m"]) - 1.435) > 0.001 \
			or str(rails[0]["electrified"]) != "contact_line" or bool(rails[0]["tunnel"]):
		failures.append("main line attributes wrong: %s" % [rails[0]])
	if not bool(rails[1]["tunnel"]) or int(rails[1]["layer"]) != -2:
		failures.append("subway tunnel not flagged: %s" % [rails[1]])
	if not bool(rails[2]["embedded"]):
		failures.append("tram should default to embedded street track")
	if absf(float(rails[3]["gauge_m"]) - 1.0) > 0.001 or not bool(rails[3]["bridge"]):
		failures.append("narrow-gauge bridge attributes wrong: %s" % [rails[3]])
	if platforms.size() != 1 or not bool(platforms[0]["closed"]) \
			or str(platforms[0]["covered"]) != "yes":
		failures.append("platform parse wrong: %s" % [platforms])
	if stops.size() != 3:
		failures.append("expected 3 stops, got %d" % stops.size())
		return
	if str(stops[0]["kind"]) != "subway_entrance" or absf(float(stops[0]["direction"]) - 90.0) > 0.01:
		failures.append("entrance parse wrong: %s" % [stops[0]])
	if str(stops[1]["station"]) != "subway":
		failures.append("station mode not read: %s" % [stops[1]])
	if not bool(stops[2]["elevator"]):
		failures.append("elevator entrance not flagged")
	if OsmRail._compass("NE") != 45.0 or not is_nan(OsmRail._compass("up")):
		failures.append("compass direction parse wrong")

func _data(lat: float, lon: float) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = lat
	data.longitude = lon
	return data

func _line(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z1)])

func _named(root: Node, name: String) -> MeshInstance3D:
	for c in root.get_children():
		if c is MeshInstance3D and c.name == name:
			return c
	return null

func _max_y(mi: MeshInstance3D) -> float:
	return mi.mesh.get_aabb().end.y if mi != null and mi.mesh != null else -INF

func _build(failures: Array[String]) -> void:
	var data := _data(40.7500, -73.9880)
	data.railways = [
		{"points": _line(-150, 0, 150, 0), "class": "rail", "gauge_m": 1.435,
			"bridge": false, "tunnel": false, "layer": 0, "electrified": "contact_line",
			"embedded": false, "service": ""},
		# A long elevated line: viaduct, no ramps needed to read it.
		{"points": _line(-200, 60, 200, 60), "class": "subway", "gauge_m": 1.435,
			"bridge": true, "tunnel": false, "layer": 1, "electrified": "rail",
			"embedded": false, "service": ""},
	]
	data.rail_platforms = [{"points": PackedVector2Array([Vector2(-40, 3), Vector2(40, 3),
		Vector2(40, 9), Vector2(-40, 9), Vector2(-40, 3)]), "closed": true, "height_m": 0.0,
		"width_m": 0.0, "covered": "yes", "layer": 0, "tunnel": false}]
	data.transit_stops = [{"x": 20.0, "z": -20.0, "kind": "subway_entrance", "direction": NAN,
		"elevator": false, "tunnel": false},
		{"x": 0.0, "z": 0.0, "kind": "station", "direction": NAN}]
	data.roads = [{"points": _line(-100, -24, 100, -24), "class": "residential",
		"width_m": 6.0, "tunnel": false}]
	var ground := GroundTruth.new(data)
	var root := RailBuilder.build_rail(data, ground)
	for name in ["Rail_ballast", "Rail_rails", "Rail_sleepers", "Rail_overhead",
			"Rail_platform", "Rail_platform_edge", "Rail_canopy", "Rail_el_steel",
			"Rail_entrance_metal", "Rail_entrance_stair", "Rail_entrance_light"]:
		if _named(root, name) == null:
			failures.append("rail world missing %s" % name)
	var g0 := RoadBuilder.surface_height(data, ground, 0.0, 6.0)
	var steel := _named(root, "Rail_el_steel")
	if steel != null and _max_y(steel) < g0 + RailBuilder.VIADUCT_CLEAR_M - 0.5:
		failures.append("viaduct deck too low: %.2f" % _max_y(steel))
	var plat := _named(root, "Rail_platform")
	var want := g0 + RailStations.RAIL_TOP_M + RailStations.MAINLINE_HEIGHT_M
	if plat != null and absf(_max_y(plat) - want) > 0.2:
		failures.append("platform top %.2f, want %.2f" % [_max_y(plat), want])
	root.free()
	# Tunnel-only data draws no track; Europe gets no globe lamps.
	var eu := _data(48.8566, 2.3522)
	eu.railways = [{"points": _line(-100, 0, 100, 0), "class": "subway", "gauge_m": 1.435,
		"bridge": false, "tunnel": true, "layer": -1, "electrified": "", "embedded": false}]
	eu.transit_stops = [{"x": 10.0, "z": 10.0, "kind": "subway_entrance", "direction": 0.0,
		"elevator": false, "tunnel": false}]
	var eu_ground := GroundTruth.new(eu)
	var eu_root := RailBuilder.build_rail(eu, eu_ground)
	if _named(eu_root, "Rail_ballast") != null or _named(eu_root, "Rail_rails") != null:
		failures.append("tunnel track must not be drawn")
	if _named(eu_root, "Rail_entrance_metal") == null:
		failures.append("European entrance missing")
	var light := _named(eu_root, "Rail_entrance_light")
	if light == null or _max_y(light) < RoadBuilder.surface_height(eu, eu_ground, 10.0, 10.0) + 3.0:
		failures.append("European entrance should carry a lit totem, not globes")
	eu_root.free()
