extends SceneTree

## Capital stations test: godot --headless --script tests/capital_stations_test.gd
## Offline. Every capital's main railway station is a registry landmark:
## the hand-built termini (LandmarkRegistryCapitalStations) and the
## `station` archetypes on their OSM outlines (LandmarkRegistryCapital-
## StationsOsm). Each row names a capital of CapitalCatalog, stands within
## STATION_REACH_M of it, is a secondary "Station" (never displaces a
## capital's icon), clears its footprint with clear_rect_m, and builds a
## model reaching its height_m (from its style: a hall, tower or dome
## only where the real station has one). The station tags make an OSM building a
## `station` archetype, metro stops and museums excepted, and small halts
## stay ordinary buildings.

const STATION_REACH_M := 20000.0
const MIN_STATIONS := 80

func _init() -> void:
	var failures: Array[String] = []
	var capitals := {}
	for row in CapitalCatalog.ROWS:
		var cc := str(row[0])
		if not capitals.has(cc):
			capitals[cc] = []
		(capitals[cc] as Array).append(Vector2(float(row[3]), float(row[4])))
	var rows: Array = LandmarkRegistryCapitalStations.entries() + LandmarkRegistryCapitalStationsOsm.entries()
	if rows.size() < MIN_STATIONS:
		failures.append("only %d capital stations (want %d)" % [rows.size(), MIN_STATIONS])
	for e in rows:
		var t := str(e["type"])
		var cc := str(e.get("capital", ""))
		if not capitals.has(cc):
			failures.append("%s names no CapitalCatalog country (%s)" % [t, cc])
		else:
			var near := INF
			for p in capitals[cc]:
				near = minf(near, LocationData.distance_m((p as Vector2).x, (p as Vector2).y,
					float(e["lat"]), float(e["lon"])))
			if near > STATION_REACH_M:
				failures.append("%s stands %.0f m from its capital" % [t, near])
		if str(e.get("kind", "")) != "Station" or not bool(e.get("secondary", false)):
			failures.append("%s should be a secondary Station" % t)
		if (e.get("clear_rect_m", []) as Array).size() != 4:
			failures.append("%s lacks clear_rect_m" % t)
		var archetype := str(e.get("archetype", "")) == "station"
		if archetype == LandmarkBuilder.is_bespoke(t):
			failures.append("%s should be either hand-built or a station archetype" % t)
		if archetype and (e.get("outline_m", []) as Array).size() < 3:
			failures.append("%s has no outline" % t)
		var root := LandmarkBuilder.build(t)
		var top := 0.0
		for m in LandmarkBuilder.parts(root):
			top = maxf(top, (m.transform * m.mesh.get_aabb()).end.y)
		var h := float(e["height_m"])
		if absf(top - h) > maxf(2.0, h * 0.03):
			failures.append("%s should stand %.1f m tall, got %.1f m" % [t, h, top])
		root.free()
	# A capital's station never becomes the place's primary landmark.
	if LocationData.landmark_for(48.8566, 2.3522, "Paris") != "eiffel":
		failures.append("Paris should still open on the Eiffel Tower")
	# OSM tags.
	var cases := [[{"building": "train_station"}, "station"],
		[{"building": "yes", "railway": "station"}, "station"],
		[{"building": "yes", "public_transport": "station", "train": "yes"}, "station"],
		[{"building": "train_station", "station": "subway"}, ""],
		[{"building": "train_station", "tourism": "museum"}, ""],
		[{"railway": "station"}, ""]]
	for c in cases:
		var got := OsmTags.archetype_for(c[0] as Dictionary)
		if got != str(c[1]):
			failures.append("tags %s should give '%s', got '%s'" % [c[0], c[1], got])
	if not OsmQuery.LANDMARK_KINDS.contains("train_station"):
		failures.append("the landmark query should fetch station buildings and their parts")
	var m := 1.0 / WorldScale.metres_to_units()
	if LandmarkSites.major_station({"size_x": 20.0 / m, "size_z": 15.0 / m}):
		failures.append("a 300 m² halt should stay an ordinary building")
	if not LandmarkSites.major_station({"size_x": 120.0 / m, "size_z": 30.0 / m}):
		failures.append("a 3600 m² station should be a landmark")
	var arch := LandmarkBuilder.build_archetype("station", 24.0, Vector2(30.0, 110.0) / m)
	if LandmarkBuilder.parts(arch).size() < 2:
		failures.append("the station archetype should build")
	arch.free()
	# A low untagged station hall keeps its own height (no 20 m floor).
	var low := LandmarkBuilder.build_archetype("station", 10.0, Vector2(30.0, 80.0) / m)
	var low_top := 0.0
	for part in LandmarkBuilder.parts(low):
		low_top = maxf(low_top, (part.transform * part.mesh.get_aabb()).end.y * (1.0 / WorldScale.metres_to_units()))
	if absf(low_top - 10.0) > 1.0:
		failures.append("a 10 m station should stand 10 m tall, got %.1f m" % low_top)
	low.free()
	# The archetype draws a hall, tower or dome only where the style asks:
	# a plain station is its body; a tower or dome sets the top.
	var ring := PackedVector2Array([Vector2(-40, -12), Vector2(40, -12), Vector2(40, 12), Vector2(-40, 12)])
	var plain := LandmarkMesh.new()
	for key in ["Walls", "Roof", "Trim", "Windows", "Gilt", "Dial", "Steel"]:
		plain.use(key, LandmarkMaterials.paint("#888888"))
	if absf(LandmarkCoreBArchStation.build(plain, 14.0, ring) - 14.0) > 0.01:
		failures.append("a plain station should stop at its body height")
	if absf(LandmarkCoreBArchStation.build(plain, 14.0, ring, {"eave": 12.0, "tower": "centre", "tower_h": 40.0,
			"tower_cap": "spire"}) - 40.0) > 0.01:
		failures.append("a tower style should reach its tower_h")
	if absf(LandmarkCoreBArchStation.build(plain, 14.0, ring, {"eave": 12.0, "dome": true, "dome_top": 30.0}) - 30.0) > 0.01:
		failures.append("a dome style should reach its dome_top")
	if failures.is_empty():
		print("CAPITAL STATIONS OK: %d stations" % rows.size())
		quit(0)
	else:
		for f in failures:
			printerr("CAPITAL STATIONS FAIL: ", f)
		quit(1)
