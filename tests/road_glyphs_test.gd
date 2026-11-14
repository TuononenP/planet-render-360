extends SceneTree

## Headless: godot --headless --script tests/road_glyphs_test.gd
## RoadGlyphs and turn:lanes: parsing, arrow shapes, lane order and which
## half a two-way road's arrows take, arrows only into junctions, and
## bicycles only in mapped bike lanes.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()
	if failures.is_empty():
		print("ROAD GLYPHS OK")
		quit(0)
	else:
		for f in failures:
			printerr("ROAD GLYPHS FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _place(country: String = "") -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.latitude = 48.8566
	d.longitude = 2.3522
	d.country = country
	return d

func _road(a: Vector2, b: Vector2, oneway: int, width: float, extra: Dictionary = {}) -> Dictionary:
	var r := {"class": "residential", "width_m": width, "oneway": oneway, "lanes": 2, "points": PackedVector2Array([a, a.lerp(b, 0.5), b])}
	r.merge(extra)
	return r

## Count of glyphs and of the marking polygons' vertices `roads` lay.
func _lay(d: LocationData) -> Array:
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	var batches := {}
	var n := RoadGlyphs.lay(batches, d, surf, 1.0)
	return [n, (batches["marking"] as RoadBuilder._Batch).verts.size() if batches.has("marking") else 0]

func _run() -> void:
	failures.clear()
	_check(OsmTags.turn_lanes({"turn:lanes": "left|through;right"}, "forward") == [["left"], ["through", "right"]], "lanes and their turns split")
	_check(OsmTags.turn_lanes({"turn:lanes:forward": "slight_left|none"}, "forward") == [["left"], []], "slight turns count; none paints nothing")
	_check(OsmTags.turn_lanes({"turn:lanes": "left"}, "backward").is_empty(), "plain turn:lanes means the forward direction")
	_check(OsmTags.turn_lanes({"turn:lanes:backward": "right"}, "backward") == [["right"]], "backward has its own tag")
	_check(OsmTags.turn_lanes({"turn:lanes": "merge_to_left|through"}, "forward") == [[], ["through"]], "merges paint no arrow")
	_check(RoadGlyphs.arrow_parts(["through"]).size() == 1, "a through arrow is one shape")
	_check(RoadGlyphs.arrow_parts(["through", "right"]).size() == 2, "a through-right arrow adds a branch")
	_check(RoadGlyphs.arrow_parts(["left", "right"]).size() == 3, "a fork is a shaft and two branches")
	_check(RoadGlyphs.arrow_parts([]).is_empty(), "no turn paints nothing")
	var branch: PackedVector2Array = RoadGlyphs.arrow_parts(["left"])[1]
	_check(branch[3].x < 0.0, "a left arrow points to negative across (left of travel)")
	_check(Geometry2D.triangulate_polygon(RoadGlyphs.arrow_parts(["through"])[0]).size() >= 9, "the arrow triangulates")
	# Lane order from the left; a two-way road's arrows on its driving half.
	_check(RoadGlyphs.lane_offset(6.0, 0, 2, true, false) < RoadGlyphs.lane_offset(6.0, 1, 2, true, false), "lane 0 is the leftmost")
	_check(is_equal_approx(RoadGlyphs.lane_offset(6.0, 0, 2, true, false), -1.5), "one-way lanes span the whole width")
	_check(RoadGlyphs.lane_offset(8.0, 0, 1, false, false) > 0.0, "right-hand traffic keeps to the right half")
	_check(RoadGlyphs.lane_offset(8.0, 0, 1, false, true) < 0.0, "left-hand traffic keeps to the left half")
	_check(is_nan(RoadGlyphs.lane_offset(4.0, 0, 2, true, false)), "lanes too narrow to mark get no arrow")
	# Travel frame: right of a north-bound travel is +x (east), z south.
	var world := RoadGlyphs._world(PackedVector2Array([Vector2(1.0, 2.0)]), Vector2(10, 20), Vector2(0, -1), 0.0, 1.0)
	_check(world[0].is_equal_approx(Vector2(11, 18)), "a glyph's frame maps right and forward: %s" % world[0])
	# Arrows into a junction only.
	var turn := {"turn_forward": [["through"], ["right"]]}
	var main := _road(Vector2(0, -80), Vector2(0, 80), 0, 8.0)
	var into := _road(Vector2(-90, 0), Vector2(0, 0), 1, 7.0, turn)
	var d := _place()
	d.roads = [main, into]
	var laid := _lay(d)
	_check(int(laid[0]) == 4, "two lanes get two arrows each on a long approach, got %d" % int(laid[0]))
	_check(int(laid[1]) > 0, "arrows reach the marking mesh")
	var dead_end := _road(Vector2(-90, 300), Vector2(0, 300), 1, 7.0, turn)
	d.roads = [dead_end]
	_check(int(_lay(d)[0]) == 0, "a way ending in no junction gets no arrows")
	# An arrow moves back behind other paint rather than overlapping it.
	var approach := PackedVector2Array([Vector2(-90, 0), Vector2(0, 0)])
	_check(RoadGlyphs.arrow_backs(approach, {}, 1.0) == [16.0, 45.0], "free road: arrows at 16 m and 45 m back")
	var paint := {}
	RoadMarkings._grid_add(paint, Vector2(-18, -5), Vector2(-18, 5), [Vector2(-18, -5), Vector2(-18, 5), 2.0], 1.0)
	var moved := RoadGlyphs.arrow_backs(approach, paint, 1.0)
	_check(moved.size() >= 1 and moved[0] > 22.0 + 2.0 - 0.01, "an arrow clears a crossing by its margin: %s" % [moved])
	if moved.size() >= 1:
		_check(moved[0] >= 22.0, "the arrow's tail sits behind the band: %.1f" % moved[0])
	_check(RoadGlyphs.arrow_backs(PackedVector2Array([Vector2(-10, 0), Vector2(0, 0)]), {}, 1.0).is_empty(), "too short for an arrow")
	# Bicycles need a mapped lane and a long enough way.
	var bike_road := _road(Vector2(-100, 200), Vector2(100, 200), 0, 10.0, {"cycle_lane": 2})
	d.roads = [bike_road]
	_check(int(_lay(d)[0]) == 4, "one bike lane on 200 m has a bicycle every 45 m, got %d" % int(_lay(d)[0]))
	d.roads = [_road(Vector2(-100, 200), Vector2(100, 200), 0, 10.0)]
	_check(int(_lay(d)[0]) == 0, "no mapped lane, no bicycle")
	var parts := RoadGlyphs.bike_parts()
	_check(parts.size() == 2 * RoadGlyphs.WHEEL_SEGMENTS + 6, "a bicycle is two rings of quads and six bars, got %d" % parts.size())
	for part: PackedVector2Array in parts:
		_check(not Geometry2D.triangulate_polygon(part).is_empty(), "every bicycle part triangulates")
	# Room inferred for parking does not push a bike lane off the kerb.
	_check(RoadPaint.parking_strips({"parking_m": 6.0, "cycle_lane": 2}) == Vector2(3.0, 0.0), "the bike lane keeps its kerb")
	_check(RoadPaint.parking_strips({"parking_m": 6.0}) == Vector2(3.0, 3.0), "with no bike lane the room stays parking")
	_check(RoadPaint.parking_strips({"parking": 2, "cycle_lane": 2}) == Vector2(0.0, OsmTags.PARKING_LANE_M), "tagged parking stays where it is tagged")
