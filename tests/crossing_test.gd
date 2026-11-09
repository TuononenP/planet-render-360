extends SceneTree

## Headless: godot --headless --script tests/crossing_test.gd
## Marked crossings (footway/cycleway/highway=crossing): the parser flags
## them and reads their paint style, RoadBuilder gives them their own
## "crossing" finish at least 4 m wide, drawn above every carriageway (depth
## layer and lift agree) with the crossing paint, and plain footways and
## ways tagged unmarked stay unpainted.

func _init() -> void:
	var failures: Array[String] = []
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(0, 6)])
	for t in [{"highway": "footway", "footway": "crossing"}, {"highway": "cycleway", "cycleway": "crossing"},
			{"highway": "crossing"}]:
		if not bool(OsmTags._road_entry(t, pts)["crossing"]):
			failures.append("%s should parse as a crossing" % [t])
	for t in [{"highway": "footway"}, {"highway": "footway", "footway": "sidewalk"}, {"highway": "residential"}]:
		if bool(OsmTags._road_entry(t, pts)["crossing"]):
			failures.append("%s is no crossing" % [t])
	var way := {"highway": "footway", "footway": "crossing"}
	for row in [[{}, "auto"], [{"crossing:markings": "yes"}, "auto"], [{"crossing:markings": "zebra"}, "zebra"],
			[{"crossing:markings": "zebra:bicolour"}, "zebra"], [{"crossing:markings": "zebra;dots"}, "zebra"],
			[{"crossing:markings": "zebra,_dots"}, "zebra"], [{"crossing:markings": "ladder"}, "ladder"],
			[{"crossing:markings": "ladder:skewed"}, "ladder"], [{"crossing:markings": "lines"}, "lines"],
			[{"crossing:markings": "dashes"}, "dashes"], [{"crossing:markings": "dots"}, "dashes"],
			[{"crossing:markings": "surface"}, "none"], [{"crossing:markings": "pictograms"}, "none"],
			[{"crossing:markings": "no"}, "none"], [{"crossing": "unmarked"}, "none"], [{"crossing": "no"}, "none"],
			[{"crossing": "informal"}, "none"], [{"crossing": "underpass"}, "none"],
			[{"crossing": "unmarked", "crossing:markings": "yes"}, "auto"],
			[{"crossing": "traffic_signals"}, "auto"]]:
		var tags: Dictionary = way.duplicate()
		tags.merge(row[0])
		var style := OsmTags.crossing_style(tags)
		if style != str(row[1]):
			failures.append("%s should be style %s, got %s" % [tags, row[1], style])
		if OsmTags.is_crossing(tags) != (str(row[1]) != "none"):
			failures.append("%s: painted flag disagrees with style %s" % [tags, row[1]])
	if OsmTags.crossing_style({"highway": "footway"}) != "":
		failures.append("a plain footway has no crossing style")
	var place := LocationData.new()
	for row in [["", "auto", true, "crossing"], ["DE", "auto", true, "crossing_dashes"], ["DE", "auto", false, "crossing"],
			["US", "auto", true, "crossing_lines"], ["JP", "auto", true, "crossing"], ["US", "ladder", true, "crossing_ladder"]]:
		place.country = row[0]
		var f := RoadSurface.crossing_finish(row[1], row[2], place)
		if f != str(row[3]):
			failures.append("finish for %s/%s/%s should be %s, got %s" % [row[0], row[1], row[2], row[3], f])
	var prev := -1.0
	for layer in [0.5, 1.0, 2.9, 4.0, 6.0, 6.9, 7.67]:
		var lift := RoadBuilder.lift_for_layer(layer)
		if lift < prev or lift > 0.05:
			failures.append("lift must rise with the layer and stay <= 0.05 m: %.4f at %.2f" % [lift, layer])
		prev = lift
	if RoadBuilder.lift_for_layer(RoadBuilder.depth_layer(0, "crossing", 0)) <= RoadBuilder.lift_for_layer(RoadBuilder.depth_layer(2, "asphalt", 7)):
		failures.append("a crossing must lie higher than the tallest carriageway")
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.seed_value = 7
	d.latitude = 35.66
	d.longitude = 139.70
	d.roads = [
		{"class": "tertiary", "width_m": 8.0, "lanes": 2, "surface": "asphalt",
			"points": PackedVector2Array([Vector2(-60, 0), Vector2(60, 0)])},
		{"class": "footway", "width_m": 2.0, "surface": "asphalt", "crossing": true,
			"points": PackedVector2Array([Vector2(0, -8), Vector2(0, 8)])},
		{"class": "footway", "width_m": 2.0, "surface": "paving_stones",
			"points": PackedVector2Array([Vector2(20, 8), Vector2(60, 8)])},
	]
	var roads := RoadBuilder.build_roads(d, GroundTruth.new(d))
	var layers := {}
	var cross_mat: ShaderMaterial = null
	var width := 0.0
	for c in roads.get_children():
		if not (c is MeshInstance3D):
			continue
		var arrays := (c as MeshInstance3D).mesh.surface_get_arrays(0)
		var u2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var top := 0.0
		for v in u2:
			top = maxf(top, v.y)
		layers[str(c.name)] = top
		if str(c.name) == "Road_crossing":
			cross_mat = (c as MeshInstance3D).material_override as ShaderMaterial
			width = u2[0].x
	if not layers.has("Road_crossing"):
		failures.append("the crossing should get its own mesh, got %s" % [layers.keys()])
	else:
		if float(layers["Road_crossing"]) <= float(layers.get("Road_asphalt", 99.0)):
			failures.append("the crossing must draw above the carriageway: %s" % [layers])
		if cross_mat == null or float(cross_mat.get_shader_parameter("crossing_kind")) != float(RoadSurface.CROSSING_KINDS["zebra"]):
			failures.append("the crossing needs the zebra material")
		if width < CROSSING_MIN:
			failures.append("a crossing is at least %.0f m wide, got %.1f" % [CROSSING_MIN, width])
	var plain := RoadSurface.material(Color(0.05, 0.05, 0.05))
	var plain_zebra: Variant = plain.get_shader_parameter("crossing_kind")
	if plain_zebra != null and float(plain_zebra) != 0.0:
		failures.append("the carriageway material must not carry zebra bars")
	roads.free()
	if failures.is_empty():
		print("CROSSING OK: styles from tags, own finish at 4+ m, lift follows layer, above the carriageway")
		quit(0)
	else:
		for f in failures:
			printerr("CROSSING FAIL: ", f)
		quit(1)

const CROSSING_MIN := 4.0
