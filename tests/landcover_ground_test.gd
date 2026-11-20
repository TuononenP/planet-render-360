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
	if TerrainTextures.LAYERS[3] != "soil" or not MaterialLibrary.PBR_SETS.has("soil"):
		failures.append("the soil set should be terrain layer 3")
	if TerrainTextures.LAYERS.size() != TerrainTextures.TILE_M.size():
		failures.append("each terrain layer needs a tile size")
	# Road ground must not draw the soil layer now in the old asphalt slot.
	var pal := GroundMaterial.palette()
	if pal.get_pixel(int(GroundMaterial.ID["road"]), 0).a != 0.0:
		failures.append("road ground should not weight the soil layer")
	# Open paving is the footways' stone: a gap between street ribbons
	# must not read as a darker, cooler pavement.
	for pair in [["urban", "paving"], ["sett", "sett"]]:
		var got := pal.get_pixel(int(GroundMaterial.ID[pair[0]]), 1)
		var want := Color.html(RoadBuilder.FINISH_HEX[pair[1]])
		if absf(got.r - want.r) > 1.5 / 255.0 or absf(got.g - want.g) > 1.5 / 255.0 \
				or absf(got.b - want.b) > 1.5 / 255.0:
			failures.append("%s ground should be the %s finish %s, got %s" % [pair[0], pair[1], want.to_html(false), got.to_html(false)])
		if got.a > 0.05:
			failures.append("%s ground should take little of the photo's tint" % pair[0])
	# Finland's granite overrides rock and setts; elsewhere the palette stays.
	var fi := LocationData.new()
	fi.country = "FI"
	var fi_pal := GroundMaterial.palette(LocationData.Season.SUMMER, Color(0, 0, 0, 0),
		FinnishGranite.palette_overrides(fi))
	var fi_rock := fi_pal.get_pixel(int(GroundMaterial.ID["rock"]), 1)
	if absf(fi_rock.r - FinnishGranite.ROCK.r) > 1.5 / 255.0 or fi_rock.r <= fi_rock.b + 0.05:
		failures.append("Finnish rock should be pink-grey, got %s" % fi_rock.to_html(false))
	if pal.get_pixel(int(GroundMaterial.ID["rock"]), 1).to_html(false) == fi_rock.to_html(false):
		failures.append("the default rock colour should differ from Finland's")
	var fi_urban := fi_pal.get_pixel(int(GroundMaterial.ID["urban"]), 1)
	if fi_urban.to_html(false) != FinnishGranite.PAVING_HEX.trim_prefix("#"):
		failures.append("Finnish open paving should be the granite slab, got %s" % fi_urban.to_html(false))
	var fi_path := fi_pal.get_pixel(int(GroundMaterial.ID["path"]), 1)
	if fi_path.to_html(false) != FinnishGranite.GRAVEL_HEX.trim_prefix("#") or fi_path.r <= fi_path.b + 0.1:
		failures.append("Finnish park gravel should be red-brown, got %s" % fi_path.to_html(false))
	# A footway through a park is gravel there; tagged, crossing or outside it is not.
	var park := [[PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]), Vector2(0, 0), Vector2(10, 10)]]
	var walk := {"class": "footway", "points": PackedVector2Array([Vector2(2, 5), Vector2(8, 5)])}
	if not FinnishGranite.park_way(walk, park):
		failures.append("an unsurfaced footway in a park should be gravel")
	for variant in [{"surface": "paving_stones"}, {"crossing": true}, {"class": "cycleway"},
			{"points": PackedVector2Array([Vector2(20, 5), Vector2(28, 5)])}]:
		var other := walk.duplicate()
		other.merge(variant, true)
		if FinnishGranite.park_way(other, park):
			failures.append("%s should not be a park gravel way" % [variant])
	# The ground paint under such a way is the gravel class in Finland, paving elsewhere.
	for country in ["FI", ""]:
		var way_data := LocationData.new()
		way_data.country = country
		way_data.roads = [{"class": "footway", "surface": "compacted", "width_m": 8.0,
			"points": PackedVector2Array([Vector2(-100, 0), Vector2(100, 0)])}]
		var cmap := GroundMaterial.class_map(way_data)
		var ids := {}
		for dy in range(-4, 5):
			ids[roundi(cmap.get_pixel(GroundMaterial.CLASS_TEXELS / 2, GroundMaterial.CLASS_TEXELS / 2 + dy).r * 255.0)] = true
		var want := int(GroundMaterial.ID["path"] if country == "FI" else GroundMaterial.ID["urban"])
		if not ids.has(want):
			failures.append("a compacted footway should paint class %d (%s), got %s" % [want, country, ids.keys()])
	if not FinnishGranite.palette_overrides(LocationData.new()).is_empty():
		failures.append("a place outside Finland keeps the shared palette")
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
