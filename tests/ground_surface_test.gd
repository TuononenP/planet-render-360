extends SceneTree

## Headless: godot --headless --script tests/ground_surface_test.gd
## GroundSurface: placers read the ground exactly as the shader paints it
## (road, sidewalk, a paved square, a pitch inside a park, WorldCover
## built-up ground), and the mask's PAINTED bit follows it.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()
	if failures.is_empty():
		print("GROUND SURFACE OK")
		quit(0)
	else:
		for f in failures:
			printerr("GROUND SURFACE FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

func _run() -> void:
	failures.clear()
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	# Away from any CityStyles zone: 3 m sidewalks.
	d.latitude = 0.5
	d.longitude = 0.5
	d.roads = [{"class": "primary", "width_m": 10.0, "sidewalk": 3,
		"points": PackedVector2Array([Vector2(-300, 0), Vector2(300, 0)])}]
	# The first containing polygon wins: the pitch is listed before its park.
	d.land_polygons = [
		{"class": "pitch", "points": _rect(150, 100, 200, 150), "holes": []},
		{"class": "grass", "points": _rect(100, 50, 300, 250), "holes": []},
		{"class": "urban", "points": _rect(-300, 50, -200, 150), "holes": []},
	]
	# WorldCover: built-up in the north-east quarter, grassland elsewhere.
	d.landcover_image = Image.create_from_data(2, 2, false, Image.FORMAT_L8, PackedByteArray([30, 50, 30, 30]))
	var g := GroundTruth.new(d)
	var s := g.surface(d)
	_check(s == g.surface(d), "one surface per ground, built once")
	var id := GroundMaterial.ID
	for c: Array in [[0.0, 0.0, "road"], [-50.0, 7.0, "urban"], [175.0, 125.0, "pitch"],
			[250.0, 200.0, "grass"], [-250.0, 100.0, "urban"], [600.0, -600.0, "urban"],
			[-600.0, 600.0, "meadow"]]:
		var got := s.class_at(c[0], c[1])
		_check(got == int(id[c[2]]), "(%s, %s) is painted %s, got %d" % [c[0], c[1], c[2], got])
	_check(s.class_at(5000.0, 0.0) == 0, "outside the extent is unmapped")
	_check(not s.hard_at(-50.0, 12.0), "meadow past the sidewalk is soft")
	_check(s.hard_at(-50.0, 12.0, 5.0), "a probe 5 m off reaches the sidewalk")
	_check(s.hard_at(175.0, 125.0, 0.0, GroundSurface.NO_PLANTING), "a pitch takes no planting")
	_check(not s.hard_at(175.0, 125.0), "a pitch is not hard ground")
	_check(not s.hard_at(-250.0, 100.0, 0.0, GroundSurface.NO_TREES), "a tree may grow out of paving")
	var mask := VegetationMask.new(d, g)
	_check(mask.blocked(175.0, 125.0, VegetationMask.PAINTED), "the mask keeps planting off a pitch in a park")
	_check(mask.blocked(-250.0, 100.0, VegetationMask.PAINTED), "and off a paved square")
	_check(not mask.blocked(250.0, 200.0, VegetationMask.PAINTED), "but not off the park's lawn")
