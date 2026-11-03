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
	if failures.is_empty():
		print("LANDCOVER GROUND OK: classes, OSM precedence, water and climate fallback")
		quit(0)
	else:
		for failure in failures:
			printerr("LANDCOVER GROUND FAIL: ", failure)
		quit(1)
