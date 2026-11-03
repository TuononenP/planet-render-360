extends SceneTree

## Headless: godot --headless --script tests/crossing_test.gd
## Marked crossings (footway/cycleway/highway=crossing): the parser flags
## them, RoadBuilder gives them their own "crossing" finish at least 4 m
## wide, drawn above every carriageway (depth layer) with the zebra
## material, and plain footways stay unmarked.

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
		if cross_mat == null or float(cross_mat.get_shader_parameter("zebra_all")) != 1.0:
			failures.append("the crossing needs the zebra material")
		if width < CROSSING_MIN:
			failures.append("a crossing is at least %.0f m wide, got %.1f" % [CROSSING_MIN, width])
	var plain := RoadSurface.material(Color(0.05, 0.05, 0.05))
	var plain_zebra: Variant = plain.get_shader_parameter("zebra_all")
	if plain_zebra != null and float(plain_zebra) != 0.0:
		failures.append("the carriageway material must not carry zebra bars")
	roads.free()
	if failures.is_empty():
		print("CROSSING OK: tags flagged, own finish at 4+ m, above the carriageway, zebra material")
		quit(0)
	else:
		for f in failures:
			printerr("CROSSING FAIL: ", f)
		quit(1)

const CROSSING_MIN := 4.0
