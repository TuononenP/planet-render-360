extends SceneTree

## Headless: godot --headless --script tests/street_furniture_test.gd
## Street furniture (StreetFurniture, desktop Ultra): OSM nodes parse to
## kinds; a signal node gets a pole on each kerb, a stop moves to its own
## kerb, a bench in the road moves out and faces the street; the kit is
## regional; with nothing mapped a sparse fill adds bins (not in Japan)
## and signals where main roads meet; every mesh builds with lit lenses.

func _init() -> void:
	_run()

func _data() -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.roads = [
		{"class": "primary", "width_m": 10.0, "points": PackedVector2Array([Vector2(-200, 0), Vector2(0, 0), Vector2(200, 0)])},
		{"class": "secondary", "width_m": 8.0, "points": PackedVector2Array([Vector2(0, -200), Vector2(0, 0), Vector2(0, 200)])},
	]
	return d

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	# Parser kinds.
	var kinds := {
		"bench": {"amenity": "bench"}, "bin": {"amenity": "waste_basket"},
		"signals": {"highway": "traffic_signals"}, "bus_stop": {"highway": "bus_stop"},
		"bollard": {"barrier": "bollard"}, "subway_entrance": {"railway": "subway_entrance"},
		"": {"amenity": "cafe"},
	}
	for k in kinds:
		if OsmParser.furniture_kind(kinds[k]) != k:
			failures.append("tags %s should parse as '%s'" % [kinds[k], k])
	var d := _data()
	var roads := StreetFurniture.RoadIndex.new(d, m, 400.0 * m)
	# A signal node on the primary 60 m east: two poles, one per kerb.
	var sig := StreetFurniture.spots({"x": 60.0 * m, "z": 0.0, "kind": "signals"}, roads, "europe", m)
	if sig.size() != 2 or absf(absf((sig[0][0] as Vector2).y) - 5.6 * m) > 0.01 * m \
			or signf((sig[0][0] as Vector2).y) == signf((sig[1][0] as Vector2).y):
		failures.append("a signal node should get a pole 0.6 m out on each kerb: %s" % [sig])
	if not str(sig[0][2]).begins_with("signals_post_"):
		failures.append("European signals are post-mounted, got %s" % sig[0][2])
	# A stop mapped just south of the road's axis: its own (south, +z) kerb.
	var stop := StreetFurniture.spots({"x": 100.0 * m, "z": 1.0 * m, "kind": "bus_stop", "shelter": true}, roads, "europe", m)
	if stop.size() != 1 or (stop[0][0] as Vector2).y < 5.6 * m or str(stop[0][2]) != "shelter":
		failures.append("a stop should stand on its own kerb as a shelter: %s" % [stop])
	# A bench mapped in the carriageway moves out and faces the road.
	var bench := StreetFurniture.spots({"x": -80.0 * m, "z": -2.0 * m, "kind": "bench"}, roads, "europe", m)
	var bp: Vector2 = bench[0][0]
	var bf: Vector2 = bench[0][1]
	if bp.y > -5.5 * m or bf.y <= 0.0:
		failures.append("a bench in the road should move to the kerb and face it: %s" % [bench])
	# Regional kit.
	for c in [["north_america", "US", "signals", "signals_na"], ["japan", "JP", "signals", "signals_jp"],
			["west_europe_brick", "GB", "bin", "bin_black"], ["west_europe_brick", "NL", "bollard", "bollard_red"],
			["france", "FR", "bin", "bin_post"], ["north_america", "US", "bin", "bin_drum"]]:
		var got := StreetFurniture.mesh_key(c[2], StreetFurniture.furniture_family(c[0], c[1]))
		if got != c[3]:
			failures.append("%s %s should be %s, got %s" % [c[1], c[2], c[3], got])
	if StreetFurniture.furniture_family("stockholm", "SE") != "nordic_se":
		failures.append("Sweden should use its Nordic stop kit")
	var sl := StreetFurniture.spots({"x": 100.0 * m, "z": 1.0 * m, "kind": "bus_stop"}, roads, "nordic_se", m)
	if sl.is_empty() or str(sl[0][2]) != "stop_sl":
		failures.append("a Swedish bus stop should use the SL stop sign")
	if StreetFurniture.furniture_family("north_america", "US", "new_york") != "nyc" \
			or StreetFurniture.mesh_key("bin", "nyc") != "bin_nyc":
		failures.append("New York should use its wire-basket furniture kit")
	var entrance := StreetFurniture.spots({"x": 50.0 * m, "z": 6.0 * m, "kind": "subway_entrance"}, roads, "nyc", m)
	if entrance.size() != 1 or str(entrance[0][2]) != "subway_entrance":
		failures.append("a mapped subway entrance should place one stair kiosk")
	# Fill: bins along lit streets, signals where the two main roads meet.
	var fill := StreetFurniture.fill(d, roads, "europe", m)
	var bins := fill.filter(func(it: Dictionary) -> bool: return it["kind"] == "bin").size()
	var sigs := fill.filter(func(it: Dictionary) -> bool: return it["kind"] == "signals").size()
	if bins < 8 or sigs != 1:
		failures.append("fill: %d bins along 800 m of street, %d signals at the crossing" % [bins, sigs])
	if StreetFurniture.fill(d, roads, "japan", m).any(func(it: Dictionary) -> bool: return it["kind"] == "bin"):
		failures.append("Japanese streets get no fill bins")
	# An offset preset eye must dress nearby roads even when they are far from the origin.
	var offset := _data()
	offset.latitude = 40.7060
	offset.longitude = -74.0040
	offset.view = PresetViews.for_pin(offset.latitude, offset.longitude)
	var eye := View360.spawn_xz(offset)
	offset.roads = [{"class": "primary", "width_m": 10.0, "points": PackedVector2Array([eye + Vector2(-100, 0), eye + Vector2(100, 0)])}]
	var offset_roads := StreetFurniture.RoadIndex.new(offset, m, 425.0 * m, eye)
	if offset_roads.nearest(eye, 10.0 * m).is_empty() or StreetFurniture.fill(offset, offset_roads, "na", m).is_empty():
		failures.append("offset eye should index and populate nearby streets")
	# A coastal railing needs a parallel landward paved path and no mapped barrier.
	var shore := {"a": Vector2(0, 0), "b": Vector2(10, 0), "land": Vector2(0, 1)}
	var walk := [[Vector2(0, 5), Vector2(10, 5), 2.0]]
	var fence := [[Vector2(0, 1), Vector2(10, 1), 0.0]]
	if not ShoreRailings.eligible(shore, walk, [], 1.0) \
			or ShoreRailings.eligible(shore, walk, fence, 1.0) \
			or ShoreRailings.eligible(shore, [[Vector2(5, -5), Vector2(5, 5), 2.0]], [], 1.0) \
			or ShoreRailings.eligible(shore, [[Vector2(0, -5), Vector2(10, -5), 2.0]], [], 1.0):
		failures.append("waterfront rail requires a parallel landward path and no mapped barrier")
	# Every mesh builds; a lit lens glows.
	for key in ["bench_wood", "bench_stone", "bin_post", "bin_drum", "bin_black", "bollard_black",
			"bollard_red", "bin_nyc", "subway_entrance", "signals_post_r", "signals_na_g", "signals_jp_r", "shelter", "stop_pole", "stop_hsl", "stop_sl"]:
		var mesh := StreetFurniture.mesh(key)
		if mesh.get_surface_count() == 0:
			failures.append("%s should build a mesh" % key)
		if key.begins_with("signals") or key == "subway_entrance":
			var glows := false
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s) as StandardMaterial3D
				glows = glows or (mat != null and mat.emission_enabled and mat.emission_energy_multiplier > 0.0)
			if not glows:
				failures.append("%s should have a lit lens" % key)
	# Stair globes are diffused lamps, rather than the saturated traffic lenses.
	var subway := StreetFurniture.mesh("subway_entrance")
	var globes := 0
	var globe_bottom := INF
	var iron_top := -INF
	for s in subway.get_surface_count():
		var mat := subway.surface_get_material(s) as StandardMaterial3D
		if mat != null and mat.emission_enabled:
			globes += 1
			for vertex in subway.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				globe_bottom = minf(globe_bottom, vertex.y)
			if mat.emission_energy_multiplier > 0.5:
				failures.append("subway globe emission should retain its diffuser colour in daylight")
		elif subway.surface_get_material(s) is ShaderMaterial \
				and float((subway.surface_get_material(s) as ShaderMaterial).get_shader_parameter("base_metallic")) > 0.4:
			for vertex in subway.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				iron_top = maxf(iron_top, vertex.y)
	if globes != 2:
		failures.append("subway globes should have separate white and green hemispheres")
	if iron_top < globe_bottom:
		failures.append("subway lamps must be supported by the entrance posts")
	failures.erase(failures[0])
	if failures.is_empty():
		print("STREET FURNITURE OK: OSM kinds, kerb placement, regional kit, sparse fill, meshes")
		quit(0)
	else:
		for f in failures:
			printerr("STREET FURNITURE FAIL: ", f)
		quit(1)
