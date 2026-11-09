extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var source := Image.create_from_data(2, 2, false, Image.FORMAT_L8,
		PackedByteArray([10, 50, 70, 80]))
	var target := Image.create(4, 4, false, Image.FORMAT_R8)
	target.fill(Color.BLACK)
	target.set_pixel(0, 0, Color(float(GroundMaterial.ID["road"]) / 255.0, 0, 0))
	var out := GroundMaterial._worldcover_fallback(target, source, false)
	for check in [[0, 0, "road"], [1, 1, "forest"], [3, 0, "urban"], [0, 3, "glacier"], [3, 3, ""]]:
		var id := roundi(out.get_pixel(check[0], check[1]).r * 255.0)
		if id != int(GroundMaterial.ID[check[2]]):
			failures.append("ground fallback or mapped precedence wrong at %s: %d" % [check, id])
	var bare := Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([60]))
	var empty := Image.create(1, 1, false, Image.FORMAT_R8)
	empty.fill(Color.BLACK)
	if roundi(GroundMaterial._worldcover_fallback(empty, bare, true).get_pixel(0, 0).r * 255.0) != int(GroundMaterial.ID["sand"]) \
			or roundi(GroundMaterial._worldcover_fallback(empty, bare, false).get_pixel(0, 0).r * 255.0) != int(GroundMaterial.ID["rock"]):
		failures.append("bare ground should respect dry and temperate climates")
	var data := LocationData.new()
	data.landcover_image = source
	var actual := GroundMaterial.class_map(data, 4)
	if roundi(actual.get_pixel(3, 0).r * 255.0) != int(GroundMaterial.ID["urban"]):
		failures.append("class map did not consume available WorldCover")
	_check_near_map(failures)
	if failures.is_empty():
		print("LANDCOVER GROUND OK: classes, OSM precedence, water and climate fallback")
		quit(0)
	else:
		for failure in failures:
			printerr("LANDCOVER GROUND FAIL: ", failure)
		quit(1)

## The class id `near` holds at world (x, z), for a window of `size` around `centre`.
func _near_id(near: Image, centre: Vector2, size: float, x: float, z: float) -> int:
	var n := near.get_width()
	var px := int((x - centre.x + size * 0.5) / size * float(n))
	var py := int((z - centre.y + size * 0.5) / size * float(n))
	return roundi(near.get_pixel(px, py).r * 255.0)

func _check_near_map(failures: Array[String]) -> void:
	if GroundMaterial.near_texels(RenderSettings.Preset.FAST) != 0 or GroundMaterial.near_texels(RenderSettings.Preset.ULTRA) != 4096:
		failures.append("near map sizes per tier are wrong")
	var d := LocationData.new()
	d.land_polygons = [{"class": "grass", "points": PackedVector2Array([Vector2(60, -100), Vector2(160, -100),
		Vector2(160, 100), Vector2(60, 100)]), "holes": []}]
	d.buildings = [{"x": 110.0, "z": -40.0, "size_x": 20.0, "size_z": 20.0, "height": 9.0}]
	# A road with both ends far outside the window still crosses it.
	d.roads = [{"class": "residential", "width_m": 8.0, "points": PackedVector2Array([Vector2(-5000, 0), Vector2(5000, 0)])},
		{"class": "residential", "width_m": 8.0, "points": PackedVector2Array([Vector2(30, 20), Vector2(30, 60)])}]
	var centre := Vector2(100, 0)
	var near := GroundMaterial.near_class_map(d, 512, centre, 200.0)
	if near == null:
		print("LANDCOVER GROUND: native rasteriser absent, near map not checked")
		return
	for c: Array in [[110.0, -40.0, "building"], [70.0, 50.0, "grass"], [100.0, 0.0, "road"], [40.0, 50.0, ""]]:
		var id := _near_id(near, centre, 200.0, float(c[0]), float(c[1]))
		if id != int(GroundMaterial.ID[c[2]]):
			failures.append("near map at (%.0f, %.0f) holds %d, want %s" % [c[0], c[1], id, c[2]])
	# Near paint stops half a fine texel inside the ribbon, not the coarse 1.2 m.
	var edge := _near_id(near, centre, 200.0, 100.0, 3.5)
	if edge != int(GroundMaterial.ID["road"]):
		failures.append("the near map keeps the road almost to its edge, got %d" % edge)
	if _near_id(near, centre, 200.0, 30.0, 58.0) != int(GroundMaterial.ID["road"]) or _near_id(near, centre, 200.0, 30.0, 63.0) != 0:
		failures.append("road paint should stop at a dead end")
	var far_away := GroundMaterial.near_class_map(d, 64, Vector2(0, 90000), 100.0)
	if far_away == null or far_away.get_pixel(32, 32).r != 0.0:
		failures.append("a window over nothing stays unmapped")
