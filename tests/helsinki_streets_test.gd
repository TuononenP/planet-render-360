extends SceneTree

## HelsinkiStreets / RoadWidths.from_polygons (offline):
## godot --headless --script tests/helsinki_streets_test.gd
## Decoding a trimmed real WFS answer, ground classes for light-traffic
## parts, the kerb-to-kerb width probe (parking share, islands left out,
## adjoining parts crossed, tagged widths kept), and the class map
## painting surveyed pavements instead of inferred bands.

const FIXTURE := "res://tests/fixtures/helsinki_streets_sample.json"
var failures: Array[String] = []

func _init() -> void:
	_decode()
	_widths()
	_surfaces()
	_class_map()
	if failures.is_empty():
		print("HELSINKI STREETS OK: decode, classes, widths, stone surfaces, class map")
		quit(0)
	else:
		for f in failures:
			printerr("HELSINKI STREETS FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _decode() -> void:
	var rows: Variant = HelsinkiStreets.decode(FileAccess.get_file_as_string(FIXTURE))
	_check(rows is Array and (rows as Array).size() == 24, "The fixture decodes to 24 parts")
	_check(HelsinkiStreets.decode("<ExceptionReport/>") == null, "An exception decodes to null")
	if not (rows is Array):
		return
	var local := HelsinkiStreets.localise(rows, 60.1690, 24.9450)
	_check(local.size() == 24 and (local[0]["points"] as PackedVector2Array).size() >= 3, "Parts localise to rings")
	var p: Vector2 = (local[0]["points"] as PackedVector2Array)[0]
	_check(absf(p.x) < 2000.0 and absf(p.y) < 2000.0, "Rings land near the centre (%s)" % str(p))
	_check(HelsinkiStreets.walk_class({"type": "Portaat", "material": "Graniittikivi"}) == "", "Steps stay terrain")
	_check(HelsinkiStreets.walk_class({"type": "Puistokäytävät", "material": "Kivituhka"}) == "path", "Stone dust is path")
	_check(HelsinkiStreets.walk_class({"type": "Jalankulkualue", "material": "Graniittilaatta"}) == "urban", "Slabs are paving")
	_check(HelsinkiStreets.walk_class({"type": "Jalkakäytävä", "material": "Noppakivi"}) == "sett", "Setts are their own paving")
	var sett := int(GroundMaterial.ID["sett"])
	_check(is_equal_approx(GroundMaterial.palette().get_pixel(sett, 2).a, 1.0), "Setts are laid paving in the palette")
	_check(GroundSurface.HARD.has(sett) and GroundSurface.NO_PLANTING.has(sett), "Setts are hard ground nothing is planted on")
	var square_ring := PackedVector2Array([Vector2(0, 0), Vector2(60, 0), Vector2(60, 40), Vector2(0, 40)])
	var cobbled := {"class": "pedestrian", "area": true, "points": square_ring}
	var flagged := {"class": "pedestrian", "area": true,
		"points": PackedVector2Array([Vector2(200, 0), Vector2(260, 0), Vector2(260, 40), Vector2(200, 40)])}
	var tagged := {"class": "pedestrian", "area": true, "surface": "asphalt", "points": square_ring}
	var laid := [{"class": "sett", "points": PackedVector2Array([Vector2(-1, -1), Vector2(61, -1), Vector2(61, 41), Vector2(-1, 41)]), "holes": []}]
	_check(HelsinkiStreets.sett_squares([cobbled, flagged, tagged], laid) == 1, "One square is laid in setts")
	_check(str(cobbled.get("surface", "")) == "sett" and RoadBuilder._finish("pedestrian", "sett") == "sett", "A cobbled square takes the sett finish")
	_check(str(flagged.get("surface", "")) == "" and str(tagged["surface"]) == "asphalt", "Squares without setts or with a mapped surface keep theirs")
	for layer in HelsinkiStreets.LAYERS:
		_check(not HostPolicy.is_blocked(HelsinkiStreets.request_url(layer, 60.169, 24.945)), "Street URLs pass HostPolicy")

func _rect(x0: float, z0: float, x1: float, z1: float) -> Dictionary:
	return {"points": PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]), "holes": []}

func _stone(x0: float, z0: float, x1: float, z1: float, material: String) -> Dictionary:
	var r := _rect(x0, z0, x1, z1)
	r["material"] = material
	return r

func _surfaces() -> void:
	# Cobbles from x -100 to 60, asphalt beyond; a second street all asphalt.
	var drive := [_stone(-100, -5, 60, 5, "Nupukivi"), _stone(60, -5, 100, 5, "Asfalttibetoni"),
		_stone(-100, 45, 100, 55, "Asfalttibetoni")]
	var cobbled := {"class": "residential", "points": PackedVector2Array([Vector2(-90, 0), Vector2(90, 0)])}
	var tagged := {"class": "residential", "surface": "asphalt", "points": PackedVector2Array([Vector2(-90, 1), Vector2(90, 1)])}
	var plain := {"class": "residential", "points": PackedVector2Array([Vector2(-90, 50), Vector2(90, 50)])}
	var walk := {"class": "footway", "points": PackedVector2Array([Vector2(-90, 2), Vector2(90, 2)])}
	var n := HelsinkiStreets.surfaces([cobbled, tagged, plain, walk], drive)
	_check(n == 1 and str(cobbled.get("surface", "")) == "sett", "A mostly cobbled street takes setts (%d)" % n)
	_check(str(tagged["surface"]) == "asphalt", "A mapped surface is kept")
	_check(not plain.has("surface") and not walk.has("surface"), "Asphalt streets and footways are left")
	_check(RoadBuilder._finish("residential", str(cobbled["surface"])) == "sett", "The sett surface lays the sett finish")

func _widths() -> void:
	# A street along x: two lane parts meeting at z = 0 (5 m + 4 m), a 2 m
	# parking strip at z 4..6, and a traffic island beside it (not drive).
	var drive := [_rect(-100, -5, 100, 0), _rect(-100, 0, 100, 4)]
	var parking := [_rect(-100, 4, 100, 6)]
	var road := {"class": "residential", "width_m": 6.0, "points": PackedVector2Array([Vector2(-90, 0.5), Vector2(90, 0.5)])}
	var tagged := {"class": "residential", "width_m": 7.0, "width_tagged": true,
		"points": PackedVector2Array([Vector2(-90, 0.5), Vector2(90, 0.5)])}
	var away := {"class": "residential", "width_m": 6.0, "points": PackedVector2Array([Vector2(-90, 80), Vector2(90, 80)])}
	var path := {"class": "footway", "width_m": 2.0, "points": PackedVector2Array([Vector2(-90, 1), Vector2(90, 1)])}
	var roads := [road, tagged, away, path]
	var n := RoadWidths.from_polygons(roads, drive, parking)
	_check(n == 1, "Only the surveyed car road takes a width (got %d)" % n)
	_check(absf(float(road["width_m"]) - 11.0) < 0.3, "Kerb to kerb across adjoining parts and parking: 11 m (got %.2f)" % float(road["width_m"]))
	_check(absf(float(road.get("parking_m", 0.0)) - 2.0) < 0.3, "The parking strip is parking_m (got %.2f)" % float(road.get("parking_m", 0.0)))
	_check(road.get("surveyed", false) and road.get("width_tagged", false), "A surveyed road is marked")
	_check(float(tagged["width_m"]) == 7.0, "A tagged width wins")
	_check(float(away["width_m"]) == 6.0 and not away.has("surveyed"), "A road off the survey keeps its width")
	_check(float(path["width_m"]) == 2.0, "Footways take no carriageway width")
	# Pavement beside the street keeps it surveyed; none beside unmarks it.
	var d := LocationData.new()
	d.roads = [{"class": "residential", "width_m": 6.0, "points": PackedVector2Array([Vector2(-90, 0.5), Vector2(90, 0.5)])}]
	HelsinkiStreets._keep_bands_without_pavement(d.roads, [])
	var beside := [_rect(-100, 6, 100, 9)]
	RoadWidths.from_polygons(d.roads, drive, parking, true)
	HelsinkiStreets._keep_bands_without_pavement(d.roads, beside)
	_check(d.roads[0].get("surveyed", false), "A street with surveyed pavement beside stays surveyed")
	var far := [_rect(-100, 60, 100, 70)]
	HelsinkiStreets._keep_bands_without_pavement(d.roads, far)
	_check(not d.roads[0].has("surveyed"), "A street with no surveyed pavement beside keeps its bands")

func _class_map() -> void:
	var half := WorldScale.detailed_extent_units() * 0.5
	var d := LocationData.new()
	d.roads = [{"class": "residential", "width_m": 10.0, "sidewalk": 3, "surveyed": true,
		"points": PackedVector2Array([Vector2(-half, 0), Vector2(half, 0)])}]
	var plain := GroundMaterial.class_map(d, 256)
	var at := func(img: Image, x: float, z: float) -> int:
		return roundi(img.get_pixel(int((x / (2.0 * half) + 0.5) * 256), int((z / (2.0 * half) + 0.5) * 256)).r * 255.0)
	_check(at.call(plain, 0.0, 14.0) == 0, "A surveyed street paints no inferred pavement band")
	d.paved_areas = [{"class": "path", "points": PackedVector2Array([Vector2(-200, 8), Vector2(200, 8),
		Vector2(200, 40), Vector2(-200, 40)]), "holes": []}]
	var with := GroundMaterial.class_map(d, 256)
	_check(at.call(with, 0.0, 24.0) == int(GroundMaterial.ID["path"]), "Surveyed paths paint their class")
	_check(at.call(with, 0.0, 0.0) == at.call(plain, 0.0, 0.0), "The carriageway paints over the survey")
