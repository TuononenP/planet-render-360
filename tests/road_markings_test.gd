extends SceneTree

## Headless: godot --headless --script tests/road_markings_test.gd
## RoadMarkings: an apron under a junction (never over a building), zebras
## inferred only on arms with no mapped crossing, crossing width decided
## per collinear chain, scramble detection, and stop lines on the
## arriving side for either traffic hand, never on outgoing one-ways.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()

func _place(country: String = "") -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.latitude = 48.8566
	d.longitude = 2.3522
	d.country = country
	d.land_polygons = [{"class": "urban", "points": PackedVector2Array([Vector2(-400, -400),
		Vector2(400, -400), Vector2(400, 400), Vector2(-400, 400)]), "holes": []}]
	return d

func _road(a: Vector2, mid: Vector2, b: Vector2, oneway: int = 0) -> Dictionary:
	return {"class": "residential", "width_m": 8.0, "oneway": oneway, "points": PackedVector2Array([a, mid, b])}

func _four_way() -> Array:
	return [_road(Vector2(-100, 0), Vector2(0, 0), Vector2(100, 0)), _road(Vector2(0, -100), Vector2(0, 0), Vector2(0, 100))]

func _crossing(a: Vector2, b: Vector2, extra: Dictionary = {}) -> Dictionary:
	var tags := {"highway": "footway", "footway": "crossing"}
	tags.merge(extra)
	return OsmTags._road_entry(tags, PackedVector2Array([a, b]))

const SIGNAL := {"crossing": "traffic_signals"}

func _plan(d: LocationData) -> RoadMarkings.Plan:
	return RoadMarkings.plan(d, GroundTruth.new(d))

## A built-up Japanese four-way, with a signalled ring of crossings or none.
func _lamp_place(ring: bool) -> LocationData:
	var d := _place("JP")
	d.roads = _four_way()
	if ring:
		for c in [[-15, -15, 15, -15], [15, -15, 15, 15], [15, 15, -15, 15], [-15, 15, -15, -15]]:
			d.roads.append(_crossing(Vector2(c[0], c[1]), Vector2(c[2], c[3]), SIGNAL))
	for x in range(-80, 81, 20):
		for z in range(-80, 81, 20):
			if absi(x) >= 20 and absi(z) >= 20:
				d.buildings.append({"x": float(x), "z": float(z), "size_x": 8.0, "size_z": 8.0, "height": 9.0})
	return d

## Lamp count per style that StreetProps places on `d`.
func _lamps(d: LocationData) -> Dictionary:
	var ground := GroundTruth.new(d)
	var root := Node3D.new()
	StreetProps._lampposts(root, d, ground, VegetationMask.new(d, ground), {"m2u": 1.0, "preset": 3})
	var out := {}
	for c in root.get_children():
		if c is MultiMeshInstance3D:
			out[str(c.name).trim_prefix("Prop_lamp_")] = (c as MultiMeshInstance3D).multimesh.instance_count
	root.free()
	return out

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	failures.clear()
	# Apron and inferred zebras at a plain four-way.
	var d := _place()
	d.roads = _four_way()
	var p := _plan(d)
	_check(p.aprons.size() == 1, "a four-way gets one apron, got %d" % p.aprons.size())
	if p.aprons.size() == 1:
		var hull: PackedVector2Array = p.aprons[0]
		_check(Geometry2D.is_point_in_polygon(Vector2(4.5, 4.5), hull), "the apron fills the junction corners")
		_check(not Geometry2D.is_point_in_polygon(Vector2(30, 0), hull), "the apron stays at the junction")
	_check(p.inferred.size() == 4, "four urban arms get inferred zebras, got %d" % p.inferred.size())
	for c: PackedVector2Array in p.inferred:
		var mid := (c[0] + c[1]) * 0.5
		var along_road := absf(mid.x) > absf(mid.y)
		var runs_across := absf((c[1] - c[0]).x) < 0.01 if along_road else absf((c[1] - c[0]).y) < 0.01
		_check(runs_across, "an inferred zebra's walking line crosses the road: %s" % c)
		_check(mid.length() > 5.5 and mid.length() < 12.0, "an inferred zebra sits just past the apron: %.1f m" % mid.length())
	_check(p.stops.is_empty(), "no signals, no stop lines")
	# A mapped crossing, even an unmarked one, replaces the inferred zebra.
	d = _place()
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(14, -5), Vector2(14, 5), {"crossing": "unmarked"}))
	p = _plan(d)
	_check(p.inferred.size() == 3, "a mapped crossing replaces that arm's inferred zebra, got %d" % p.inferred.size())
	# A building in the way rejects the apron.
	d = _place()
	d.roads = _four_way()
	d.buildings = [{"x": 3.0, "z": 3.0, "size_x": 2.0, "size_z": 2.0, "height": 9.0}]
	_check(_plan(d).aprons.is_empty(), "an apron must not pave a building")
	# A way merely split in two is no junction.
	d = _place()
	d.roads = [_road(Vector2(-100, 0), Vector2(-50, 0), Vector2(0, 0)), _road(Vector2(0, 0), Vector2(50, 0), Vector2(100, 0))]
	p = _plan(d)
	_check(p.aprons.is_empty() and p.inferred.is_empty(), "a split way gets no junction markings")
	# Width is per chain: mappers split one crossing into pieces.
	d = _place()
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(60, -8), Vector2(60, -6), SIGNAL))
	d.roads.append(_crossing(Vector2(60, -6), Vector2(60, 12), SIGNAL))
	d.roads.append(_crossing(Vector2(-60, -8), Vector2(-60, 8)))
	p = _plan(d)
	_check(is_equal_approx(float(p.by_road[2]["width_m"]), 5.0) and is_equal_approx(float(p.by_road[3]["width_m"]), 5.0),
		"two pieces of one 20 m signalled crossing share its width: %s" % [p.by_road])
	_check(is_equal_approx(float(p.by_road[4]["width_m"]), 4.0), "an unsignalled crossing stays 4 m")
	# A tagged width wins; a footpath-narrow tag does not shrink the band.
	d = _place()
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(60, -8), Vector2(60, 8), {"width": "7"}))
	d.roads.append(_crossing(Vector2(-60, -8), Vector2(-60, 8), {"width": "2"}))
	p = _plan(d)
	_check(is_equal_approx(float(p.by_road[2]["width_m"]), 7.0), "a tagged width is used")
	_check(is_equal_approx(float(p.by_road[3]["width_m"]), 4.0), "a crossing is at least 4 m wide")
	# Scramble: a ring of signalled crossings and one through the centre.
	d = _place()
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(-12, -12), Vector2(12, -12), SIGNAL))
	d.roads.append(_crossing(Vector2(12, -12), Vector2(12, 12), SIGNAL))
	d.roads.append(_crossing(Vector2(12, 12), Vector2(-12, 12), SIGNAL))
	d.roads.append(_crossing(Vector2(-12, 12), Vector2(-12, -12), SIGNAL))
	d.roads.append(_crossing(Vector2(-12, -12), Vector2(12, 12), SIGNAL))
	p = _plan(d)
	_check(p.scrambles == 1, "ring plus diagonal is a scramble, got %d" % p.scrambles)
	for i in range(2, 7):
		_check(is_equal_approx(float(p.by_road[i]["width_m"]), RoadMarkings.SCRAMBLE_WIDTH_M), "scramble band %d is wide: %s" % [i, p.by_road[i]])
	_check(p.aprons.size() == 1 and Geometry2D.is_point_in_polygon(Vector2(11, 11), p.aprons[0]),
		"the apron reaches the scramble's bands")
	# The same ring without a diagonal is not a scramble.
	d.roads.remove_at(6)
	_check(_plan(d).scrambles == 0, "a ring alone is no scramble")
	# A kiosk inside the ring denies the apron, not the clear lane paint.
	d.roads.append(_crossing(Vector2(-12, -12), Vector2(12, 12), SIGNAL))
	d.buildings = [{"x": 11.0, "z": -7.0, "size_x": 2.0, "size_z": 2.0, "height": 3.0}]
	p = _plan(d)
	_check(RoadSurface.junction_frac(p.junctions, Vector2(10, 0)) * RoadSurface.JUNCTION_M < 2.5,
		"lane paint clears up to the ring despite a kiosk")
	# Untagged crossing ways: painted over a road, plain off it.
	d = _place()
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(30, -6), Vector2(30, 6)))
	d.roads.append(_crossing(Vector2(20, 20), Vector2(40, 20)))
	d.roads.append(_crossing(Vector2(20, 30), Vector2(40, 30), {"crossing:markings": "zebra"}))
	p = _plan(d)
	_check(str(p.by_road[2]["finish"]).begins_with("crossing"), "a crossing over a road is painted")
	_check(not str(p.by_road[3]["finish"]).begins_with("crossing"), "a pavement link is not painted")
	_check(str(p.by_road[4]["finish"]).begins_with("crossing"), "tagged markings are painted wherever they are mapped")
	# A short stub beside a band stays unpainted; a cycle crossing keeps its width.
	d = _place()
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(30, -6), Vector2(30, 6), {"crossing:markings": "zebra"}))
	d.roads.append(_crossing(Vector2(31.5, 7), Vector2(31.5, 9), {"crossing:markings": "zebra"}))
	var bike := OsmTags._road_entry({"highway": "cycleway", "cycleway": "crossing", "crossing:markings": "dashes"},
		PackedVector2Array([Vector2(50, -6), Vector2(50, 6)]))
	d.roads.append(bike)
	p = _plan(d)
	_check(str(p.by_road[2]["finish"]).begins_with("crossing"), "the band stays painted")
	_check(not str(p.by_road[3]["finish"]).begins_with("crossing"), "a stub beside a band is not painted")
	_check(float(p.by_road[4]["width_m"]) < RoadBuilder.CROSSING_MIN_M, "a cycle crossing keeps its own width: %s" % p.by_road[4])
	# Stop lines: arriving traffic on its own driving side, right or left.
	for row in [["FR", -1.0], ["JP", 1.0]]:
		d = _place(str(row[0]))
		d.roads = _four_way()
		d.roads.append(_crossing(Vector2(30, -5), Vector2(30, 5), SIGNAL))
		p = _plan(d)
		_check(p.stops.size() == 1, "%s: one stop line for traffic arriving at the junction, got %d" % [row[0], p.stops.size()])
		if p.stops.size() == 1:
			var bar: PackedVector2Array = p.stops[0]
			var mid := (bar[0] + bar[1]) * 0.5
			var band_edge := 30.0 + float(p.by_road[2]["width_m"]) * 0.5
			_check(mid.x > band_edge + 1.0 and mid.x < band_edge + 4.0, "%s: bar 2 m behind the band: x %.1f" % [row[0], mid.x])
			_check(signf(mid.y) == float(row[1]), "%s: bar on the driving side: z %.1f" % [row[0], mid.y])
	# A one-way leaving the junction has no stop line at its crossing.
	d = _place()
	d.roads = [_road(Vector2(0, -100), Vector2(0, 0), Vector2(0, 100)), _road(Vector2(0, 0), Vector2(50, 0), Vector2(100, 0), 1)]
	d.roads.append(_crossing(Vector2(30, -5), Vector2(30, 5), SIGNAL))
	_check(_plan(d).stops.is_empty(), "outgoing one-way traffic does not stop at this crossing")
	# ... while one arriving there does, across its whole width.
	d = _place()
	d.roads = [_road(Vector2(0, -100), Vector2(0, 0), Vector2(0, 100)), _road(Vector2(100, 0), Vector2(50, 0), Vector2(0, 0), 1)]
	d.roads.append(_crossing(Vector2(30, -5), Vector2(30, 5), SIGNAL))
	p = _plan(d)
	_check(p.stops.size() == 1 and absf(p.stops[0][0].distance_to(p.stops[0][1]) - 7.4) < 0.1, "an arriving one-way stops across its width")
	# A lone signal node on an arm: a bar toward the junction, at the node.
	d = _place("FR")
	d.roads = _four_way()
	d.street_furniture = [{"x": 25.0, "z": 0.0, "kind": "signals", "shelter": false}]
	p = _plan(d)
	_check(p.stops.size() == 1 and absf(((p.stops[0][0] + p.stops[0][1]) * 0.5).x - 25.0) < 0.5, "a signal node marks one arriving stop line")
	# Lamps: none on a junction surface; signals swap the utility pole.
	var plain := _lamps(_lamp_place(false))
	var ringed := _lamps(_lamp_place(true))
	_check(plain.get("utility", 0) > 0 and plain.get("modern", 0) == 0, "back streets keep utility poles: %s" % [plain])
	_check(ringed.get("modern", 0) > 0 and ringed.get("utility", 0) > 0, "only streets near signals change lamp: %s" % [ringed])
	_check(ringed.get("modern", 0) + ringed.get("utility", 0) <= plain.get("utility", 0) - 4,
		"no lamp on the junction surface: %s vs %s" % [ringed, plain])
	# Everything lays into real meshes.
	d = _place("JP")
	d.roads = _four_way()
	d.roads.append(_crossing(Vector2(30, -5), Vector2(30, 5), SIGNAL))
	var roads := RoadBuilder.build_roads(d, GroundTruth.new(d))
	var names := {}
	for c in roads.get_children():
		names[str(c.name)] = true
	_check(names.has("Road_crossing") and names.has("Road_marking") and names.has("Road_asphalt"), "meshes built: %s" % [names.keys()])
	roads.free()
	if failures.is_empty():
		print("ROAD MARKINGS OK")
		quit(0)
	else:
		for f in failures:
			printerr("ROAD MARKINGS FAIL: ", f)
		quit(1)
