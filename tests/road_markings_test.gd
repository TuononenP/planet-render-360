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

func _four_way(cls: String = "residential") -> Array:
	var roads := [_road(Vector2(-100, 0), Vector2(0, 0), Vector2(100, 0)), _road(Vector2(0, -100), Vector2(0, 0), Vector2(0, 100))]
	for r: Dictionary in roads:
		r["class"] = cls
	return roads

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

## Wear seeds: a split street ages as one, a side street on its own, and
## the order of the road list changes nothing.
func _check_wear_seeds() -> void:
	var west := _road(Vector2(-100, 0), Vector2(-50, 0), Vector2(0, 0))
	var east := _road(Vector2(0, 0), Vector2(50, 0), Vector2(100, 0))
	var side := _road(Vector2(0, 0), Vector2(0, 50), Vector2(0, 100))
	var d := _place()
	d.roads = [west, east, side]
	var seeds := RoadSurface.wear_seeds(d)
	_check(is_equal_approx(seeds[0], seeds[1]), "a street split into two ways keeps one wear seed")
	_check(not is_equal_approx(seeds[0], seeds[2]), "a side street gets its own wear seed")
	d.roads = [side, east, west]
	var again := RoadSurface.wear_seeds(d)
	_check(is_equal_approx(again[2], seeds[0]) and is_equal_approx(again[0], seeds[2]),
		"wear seeds do not depend on the road order")
	_check(RoadSurface.wear_attr(true, 0.0) >= 0.5 and RoadSurface.wear_attr(true, 1.0) < 1.0,
		"an urban ribbon stays in the upper half of COLOR.b at any seed")
	_check(RoadSurface.wear_attr(false, 1.0) < 0.5, "a rural ribbon stays in the lower half of COLOR.b at any seed")

## An apron follows its kerbs and takes the finish of the roads it joins.
func _check_apron_shape() -> void:
	var d := _place()
	d.roads = _four_way()
	var p := _plan(d)
	_check(p.aprons.size() == 1 and p.apron_arms.size() == 1, "one apron with its arms")
	if p.aprons.size() != 1:
		return
	var ring: PackedVector2Array = p.aprons[0]
	_check(Geometry2D.is_point_in_polygon(Vector2(4.5, 4.5), ring), "the kerb corner curves into the junction's corner")
	_check(not Geometry2D.is_point_in_polygon(Vector2(6.2, 6.2), ring), "the pavement keeps its corner: an apron is not a hull")
	var paved := _road(Vector2(-100, 0), Vector2(0, 0), Vector2(100, 0))
	paved["surface"] = "paving_stones"
	var paved2 := paved.duplicate()
	paved2["points"] = PackedVector2Array([Vector2(0, -100), Vector2(0, 0), Vector2(0, 100)])
	var side := _road(Vector2(0, 0), Vector2(70, 70), Vector2(100, 100))
	d.roads = [paved, paved2, side]
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	_check(RoadMarkings.apron_finish([[0, 8.0], [1, 8.0], [2, 4.0]], d, surf, 1.0) == "sett",
		"an apron among paved streets is paved")
	_check(RoadMarkings.apron_finish([[0, 2.0], [2, 8.0]], d, surf, 1.0) == "asphalt",
		"the wider road sets the apron's finish")

## The paint layer's lane layout, dash chains, crossing clips and styles.
func _check_paint() -> void:
	var plain := RoadPaint.lane_lines(6.0, 2, false, 1, true, 0.12)
	_check(plain.size() == 1 and is_equal_approx(float(plain[0]["x"]), 0.0) and bool(plain[0]["centre"]),
		"a plain two-lane street has one centre line")
	var parked := RoadPaint.lane_lines(8.2, 2, false, 1, true, 0.12, Vector2(0.0, 2.2))
	var centre := 0.0
	for l: Dictionary in parked:
		if bool(l["centre"]):
			centre = float(l["x"])
	_check(is_equal_approx(centre, 1.1), "parking on the right moves the centre line left: %.2f" % centre)
	_check(not parked.any(func(l: Dictionary) -> bool: return bool(l["solid"])), "a side street's parking lane has no line")
	var main_parked := RoadPaint.lane_lines(8.2, 2, false, 2, true, 0.12, Vector2(0.0, 2.2))
	_check(main_parked.any(func(l: Dictionary) -> bool: return bool(l["solid"]) and is_equal_approx(float(l["x"]), -1.9)),
		"a line marks off a main road's tagged parking lane")
	# Kerbside room inferred from the sidewalks moves the lanes in, and paints nothing.
	var hyde := RoadPaint.lane_lines(12.0, 0, false, 1, true, 0.125, Vector2(2.5, 2.5), 0,
		{"class": "tertiary", "inferred_parking": true, "double_centre": true})
	_check(hyde.size() == 2 and hyde.all(func(l: Dictionary) -> bool: return bool(l["centre"]) and bool(l["solid"])),
		"an unlaned US town street has a double centre line and nothing else: %s" % [hyde])
	var inferred_main := RoadPaint.lane_lines(14.0, 2, false, 2, true, 0.12, Vector2(2.5, 2.5), 0, {"inferred_parking": true})
	_check(not inferred_main.any(func(l: Dictionary) -> bool: return not bool(l["centre"])), "inferred parking is never marked off")
	_check(not RoadPaint.lane_lines(12.0, 2, false, 2, true, 0.12, Vector2.ZERO, 0, {"class": "primary"}).any(
		func(l: Dictionary) -> bool: return not bool(l["centre"])), "a kerbed main street in town has no edge lines")
	_check(RoadPaint.lane_lines(12.0, 2, false, 2, false, 0.12, Vector2.ZERO, 0, {"class": "primary"}).filter(
		func(l: Dictionary) -> bool: return bool(l["solid"]) and not bool(l["centre"])).size() == 2, "an open main road has both edge lines")
	_check(RoadPaint.lane_lines(12.0, 2, true, 2, true, 0.12, Vector2.ZERO, 0, {"class": "motorway"}).filter(
		func(l: Dictionary) -> bool: return bool(l["solid"])).size() == 2, "a motorway keeps its edge lines in town")
	var houses := _place()
	houses.buildings = [{"x": 20.0, "z": 18.0, "size_x": 10.0, "size_z": 10.0, "height": 9.0}]
	var house_grid := RoadMarkings._building_grid(houses, 1.0)
	_check(RoadPaint.built_up(PackedVector2Array([Vector2(-40, 0), Vector2(40, 0)]), house_grid, 1.0), "a street past a house is in town")
	_check(not RoadPaint.built_up(PackedVector2Array([Vector2(-40, 200), Vector2(40, 200)]), house_grid, 1.0), "a road in open country is not")
	_check(RoadPaint.lane_lines(8.0, 0, false, 1, true, 0.12, Vector2.ZERO, 0, {"class": "residential"}).is_empty(),
		"a side street with no lanes tagged has no lines")
	_check(RoadPaint.lane_lines(8.0, 2, false, 1, true, 0.12, Vector2.ZERO, 0, {"class": "residential"}).size() == 1,
		"a side street tagged with two lanes has its centre line")
	_check(RoadPaint.lane_lines(8.0, 2, false, 1, true, 0.12, Vector2.ZERO, 0, {"unmarked": true}).is_empty(),
		"lane_markings=no paints nothing")
	_check(RoadPaint.lane_lines(8.0, 0, true, 1, true, 0.12, Vector2.ZERO, 0, {"class": "tertiary"}).is_empty(),
		"an unlaned one-way street is one lane")
	_check(RoadPaint.lane_lines(10.0, 0, true, 2, false, 0.12).filter(func(l: Dictionary) -> bool: return not bool(l["solid"])).size() == 2,
		"an unlaned 10 m one-way main road has three lanes")
	# Three lanes: opposing traffic meets off the middle, on a lane boundary.
	var three := RoadPaint.lane_lines(9.9, 3, false, 1, true, 0.12)
	var c3 := three.filter(func(l: Dictionary) -> bool: return bool(l["centre"]))
	_check(c3.size() == 1 and is_equal_approx(float(c3[0]["x"]), 1.65), "two lanes forward put the centre line left of the middle: %s" % [three])
	_check(three.size() == 2 and three.any(func(l: Dictionary) -> bool: return is_equal_approx(float(l["x"]), -1.65) and not bool(l["centre"])),
		"the other boundary is a lane divider: %s" % [three])
	c3 = RoadPaint.lane_lines(9.9, 3, false, 1, true, 0.12, Vector2.ZERO, 0, {"forward": 1, "backward": 2}) \
		.filter(func(l: Dictionary) -> bool: return bool(l["centre"]))
	_check(c3.size() == 1 and is_equal_approx(float(c3[0]["x"]), -1.65), "lanes:forward=1 moves it to the right")
	_check(RoadPaint.lane_lines(6.0, 2, false, 1, true, 0.12, Vector2.ZERO, 0, {"rails": [[0.2, 0.98]]}).is_empty(),
		"no line is painted along a rail set in the street")
	var rail_grid := {}
	RoadMarkings._grid_add(rail_grid, Vector2(-100, 1.6), Vector2(100, 1.6), [Vector2(-100, 1.6), Vector2(100, 1.6), 0, 0.98], 1.0)
	var along := RoadPaint.rails_along(PackedVector2Array([Vector2(-50, 0), Vector2(50, 0)]), rail_grid, 6.0, 1.0)
	_check(along.size() == 1 and is_equal_approx(float(along[0][0]), -1.6), "a track to the south of eastbound travel is on its right: %s" % [along])
	_check(RoadPaint.rails_along(PackedVector2Array([Vector2(0, -50), Vector2(0, 50)]), rail_grid, 6.0, 1.0).is_empty(),
		"a track crossing the street is not along it")
	var squeezed := RoadPaint.lane_lines(6.0, 2, false, 1, true, 0.12, Vector2(2.2, 2.2))
	_check(squeezed.size() == 1 and is_equal_approx(float(squeezed[0]["x"]), 0.0), "lanes keep the road when strips leave no room")
	_check(RoadPaint.lane_lines(4.0, 1, false, 1, true, 0.12).is_empty(), "a narrow lane gets no lines")
	var bike := RoadPaint.lane_lines(9.0, 2, false, 1, true, 0.12, Vector2.ZERO, 2)
	_check(bike.any(func(l: Dictionary) -> bool: return bool(l["solid"]) and is_equal_approx(float(l["x"]), -3.0)),
		"a bike lane is marked off its 1.5 m from the right kerb")
	_check(OsmTags.cycle_lane_sides({"cycleway:right": "lane"}) == 2, "cycleway:right=lane is the right side")
	_check(OsmTags.cycle_lane_sides({"cycleway": "lane"}) == 3, "cycleway=lane on a two-way road is both sides")
	_check(OsmTags.cycle_lane_sides({"cycleway": "lane", "oneway": "yes"}) == 2, "cycleway=lane on a one-way road is one side")
	_check(RoadPaint.style_for("US", "urban") == [3.05, 9.14, 0.125], "US dashes follow the MUTCD")
	_check(RoadPaint.style_for("AT", "motorway")[1] == 12.0, "Austrian motorway gaps are 12 m")
	_check(RoadPaint.style_for("XX", "urban") == RoadPaint.STYLES[""]["urban"], "an unlisted country uses the default")
	# A street split in two is one chain; a side street is its own.
	var d := _place()
	var a := _road(Vector2(-100, 0), Vector2(-50, 0), Vector2(0, 0))
	var b := _road(Vector2(0, 0), Vector2(50, 0), Vector2(100, 0))
	var side := _road(Vector2(0, 0), Vector2(0, 50), Vector2(0, 100))
	var wider := _road(Vector2(100, 0), Vector2(150, 0), Vector2(200, 0))
	wider["width_m"] = 12.0
	wider["parking_m"] = 4.0
	# Drawn the other way round, as mappers do.
	var back := _road(Vector2(300, 0), Vector2(250, 0), Vector2(200, 0))
	var laned := _road(Vector2(300, 0), Vector2(350, 0), Vector2(400, 0))
	laned["lanes"] = 4
	d.roads = [a, b, side, wider, back, laned]
	var chains := RoadPaint.line_chains(d, PackedInt32Array([0, 1, 2, 3, 4, 5]))
	_check(chains.size() == 3, "split ways join; a turn or a new layout starts a chain, got %d: %s" % [chains.size(), chains])
	_check(chains.any(func(c: Array) -> bool: return c == [0, 1, 3, ~4]),
		"the street is one chain through a width change and a reversed way: %s" % [chains])
	var oneway_a := _road(Vector2(-100, 0), Vector2(-50, 0), Vector2(0, 0), 1)
	var oneway_b := _road(Vector2(100, 0), Vector2(50, 0), Vector2(0, 0), 1)
	d.roads = [oneway_a, oneway_b]
	_check(RoadPaint.line_chains(d, PackedInt32Array([0, 1])).size() == 2, "one-ways meeting head on are two streets")
	oneway_b["oneway"] = -1
	_check(RoadPaint.line_chains(d, PackedInt32Array([0, 1])).size() == 1, "a one-way drawn backwards runs on")
	# A crossing's paint stops at the kerb.
	var grid := {}
	RoadMarkings._grid_add(grid, Vector2(-100, 0), Vector2(100, 0), [Vector2(-100, 0), Vector2(100, 0), 4.5], 1.0)
	var runs := RoadCrossingClip.on_road_runs(PackedVector2Array([Vector2(0.3, -20.4), Vector2(0.3, 20.3)]), grid, {}, 1.0)
	_check(runs.size() == 1, "one stretch of a crossing is over the road, got %d" % runs.size())
	if runs.size() == 1:
		var run: PackedVector2Array = runs[0]
		_check(absf(absf(run[0].y) - 4.5) < 0.1 and absf(absf(run[run.size() - 1].y) - 4.5) < 0.1,
			"a crossing's paint ends at the kerb: %.2f to %.2f" % [run[0].y, run[run.size() - 1].y])
	RoadMarkings._grid_add(grid, Vector2(50, 0), Vector2(50, 60), [Vector2(50, 0), Vector2(50, 60), 3.0, true], 1.0)
	var drive := PackedVector2Array([Vector2(40, 30), Vector2(60, 30)])
	_check(RoadCrossingClip.on_road_runs(drive, grid, {}, 1.0, true, true).is_empty(), "a driveway is no carriageway")
	_check(RoadCrossingClip.pieces(drive, grid, {}, 1.0).size() == 1, "a crossing over only a service road is still painted")
	_check(RoadCrossingClip.on_road_runs(PackedVector2Array([Vector2(0, 20), Vector2(0, 40)]), grid, {}, 1.0).is_empty(),
		"a way wholly on the pavement paints nothing")

## A bent crossing is laid in straight pieces; a stop line gives way to paint.
func _check_crossing_shape() -> void:
	var nearly := PackedVector2Array([Vector2(0, 0), Vector2(5, 0.4), Vector2(10, 0)])
	_check(RoadCrossingClip.straight_pieces(nearly, 1.0).size() == 1, "a nearly straight crossing stays one piece")
	var bent := PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(5, 5)])
	var pieces := RoadCrossingClip.straight_pieces(bent, 1.0)
	_check(pieces.size() == 2, "a crossing turning a corner is two pieces, got %d" % pieces.size())
	var road := {}
	RoadMarkings._grid_add(road, Vector2(0, -50), Vector2(0, 50), [Vector2(0, -50), Vector2(0, 50), 6.0, false], 1.0)
	var hooked := RoadCrossingClip.pieces(PackedVector2Array([Vector2(-8, 0), Vector2(4.5, 0), Vector2(6, 1.5), Vector2(8, 1.5)]), road, {}, 1.0)
	_check(hooked.size() == 1 and hooked[0][0].distance_to(hooked[0][1]) > 10.0, "the hook a way makes at the kerb paints no scrap: %s" % [hooked])
	var grid := {}
	RoadMarkings._grid_add(grid, Vector2(-10, 0), Vector2(10, 0), [Vector2(-10, 0), Vector2(10, 0), 2.0], 1.0)
	var clear := RoadCrossingClip.on_road_runs(PackedVector2Array([Vector2(0, -10), Vector2(0, 10)]), grid, {}, 1.0, false)
	_check(clear.size() == 2, "a line through a crossing keeps both sides of it, got %d" % clear.size())
	# Two ways mapped over one crossing paint one band; bands meeting at a corner do not overlap.
	var by_road := {
		0: {"finish": "crossing", "width_m": 4.0, "runs": [PackedVector2Array([Vector2(0, 0), Vector2(12, 0)])]},
		1: {"finish": "crossing", "width_m": 4.0, "runs": [PackedVector2Array([Vector2(1, 0.5), Vector2(11, 0.5)])]},
		2: {"finish": "crossing_ladder", "width_m": 4.0, "runs": [PackedVector2Array([Vector2(11, 0), Vector2(11, 14)])]},
		3: {"finish": "paving", "width_m": 2.0}}
	RoadCrossingClip.dedupe(by_road, 1.0)
	_check((by_road[0]["runs"] as Array).size() == 1 and (by_road[1]["runs"] as Array).is_empty(),
		"the shorter of two bands over one crossing is dropped: %s" % [by_road])
	var met: PackedVector2Array = (by_road[0]["runs"] as Array)[0]
	_check(absf(met[1].x - 9.0) < 0.1 and (by_road[2]["runs"] as Array).size() == 1,
		"a band meeting a longer one at a corner ends at its edge: %s" % [met])
	_check(not by_road[3].has("runs"), "plain paving is left alone")

## Lane lines stop at junctions, crossings and stop lines.
func _check_cuts() -> void:
	var plan := RoadMarkings.Plan.new()
	plan.clear = [PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])]
	plan.discs = [[Vector2(200, 0), 6.0]]
	plan.by_road = {7: {"finish": "crossing", "width_m": 4.0, "runs": [PackedVector2Array([Vector2(60, -5), Vector2(60, 5)])]},
		8: {"finish": "paving", "width_m": 4.0, "runs": [PackedVector2Array([Vector2(120, -5), Vector2(120, 5)])]}}
	plan.stops = [PackedVector2Array([Vector2(65, 0.15), Vector2(65, 4)])]
	var grid := RoadPaintCut.zones(plan, 1.0)
	var street := PackedVector2Array()
	for x in range(-100, 301, 3):
		street.append(Vector2(float(x), 0.4))
	var kept := RoadPaintCut.keep(street, grid, 1.0)
	_check(kept.size() == 4, "a street is cut at the junction, the crossing and the bare node, got %d" % kept.size())
	if kept.size() == 4:
		_check(absf((kept[0] as PackedVector2Array)[(kept[0] as PackedVector2Array).size() - 1].x + 8.0) < 0.1, "the line stops at the apron's edge")
		_check(absf((kept[1] as PackedVector2Array)[0].x - 8.0) < 0.1 and absf((kept[1] as PackedVector2Array)[(kept[1] as PackedVector2Array).size() - 1].x - 57.7) < 0.1,
			"the line stops short of the crossing band: %s" % [kept[1]])
		_check(absf((kept[2] as PackedVector2Array)[0].x - 65.525) < 0.1, "nothing is painted between a crossing and its stop line: %s" % [(kept[2] as PackedVector2Array)[0]])
		_check(absf((kept[2] as PackedVector2Array)[(kept[2] as PackedVector2Array).size() - 1].x - 194.0) < 0.15, "a junction without an apron still clears its lines")
	_check(RoadPaintCut.keep(street, RoadPaintCut.zones(plan, 1.0, true), 1.0).size() == 3, "junction zones alone leave the crossing out")
	# A junction whose apron a building denies still has its zone.
	var d := _place()
	d.roads = _four_way()
	d.buildings = [{"x": 3.0, "z": 3.0, "size_x": 2.0, "size_z": 2.0, "height": 9.0}]
	var p := _plan(d)
	_check(p.aprons.is_empty() and p.discs.size() == 1, "a denied apron leaves a disc: %s" % [p.discs])
	_check(RoadPaintCut.inside(RoadPaintCut.zones(p, 1.0), Vector2(4, 0), 1.0), "lines stop at a junction with no apron")

func _run() -> void:
	failures.clear()
	_check_crossing_shape()
	_check_wear_seeds()
	_check_apron_shape()
	_check_paint()
	_check_cuts()
	# Side streets meeting get an apron and no zebras.
	var d := _place()
	d.roads = _four_way()
	var p := _plan(d)
	_check(p.aprons.size() == 1 and p.inferred.is_empty(), "side streets meeting are not given crossings, got %d" % p.inferred.size())
	# Apron and inferred zebras at a main road's four-way.
	d = _place()
	d.roads = _four_way("primary")
	p = _plan(d)
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
	d.roads = _four_way("primary")
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
	# The bar spans the lanes, not the parked cars beside them.
	(d.roads[1] as Dictionary)["width_m"] = 12.0
	(d.roads[1] as Dictionary)["parking_m"] = 5.0
	(d.roads[2] as Dictionary)["points"] = PackedVector2Array([Vector2(30, -7), Vector2(30, 7)])
	p = _plan(d)
	_check(p.stops.size() == 1 and absf(p.stops[0][0].distance_to(p.stops[0][1]) - 6.4) < 0.1,
		"a stop line leaves the parking strips out: %s" % [p.stops])
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
