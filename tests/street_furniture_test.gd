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
		"bollard": {"barrier": "bollard"}, "": {"amenity": "cafe"},
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
	# Fill: bins along lit streets, signals where the two main roads meet.
	var fill := StreetFurniture.fill(d, roads, "europe", m)
	var bins := fill.filter(func(it: Dictionary) -> bool: return it["kind"] == "bin").size()
	var sigs := fill.filter(func(it: Dictionary) -> bool: return it["kind"] == "signals").size()
	if bins < 8 or sigs != 1:
		failures.append("fill: %d bins along 800 m of street, %d signals at the crossing" % [bins, sigs])
	if StreetFurniture.fill(d, roads, "japan", m).any(func(it: Dictionary) -> bool: return it["kind"] == "bin"):
		failures.append("Japanese streets get no fill bins")
	# Every mesh builds; a lit lens glows.
	for key in ["bench_wood", "bench_stone", "bin_post", "bin_drum", "bin_black", "bollard_black",
			"bollard_red", "signals_post_r", "signals_na_g", "signals_jp_r", "shelter", "stop_pole"]:
		var mesh := StreetFurniture.mesh(key)
		if mesh.get_surface_count() == 0:
			failures.append("%s should build a mesh" % key)
		if key.begins_with("signals"):
			var glows := false
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s) as StandardMaterial3D
				glows = glows or (mat.emission_enabled and mat.emission_energy_multiplier > 0.0)
			if not glows:
				failures.append("%s should have a lit lens" % key)
	failures.erase(failures[0])
	if failures.is_empty():
		print("STREET FURNITURE OK: OSM kinds, kerb placement, regional kit, sparse fill, meshes")
		quit(0)
	else:
		for f in failures:
			printerr("STREET FURNITURE FAIL: ", f)
		quit(1)
