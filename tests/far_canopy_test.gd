extends SceneTree

## FarCanopy plants crowns only where the far drape shows tree canopy:
## in a dark forest past the extent, not on a sunlit lawn beside it nor on
## the grey roofscape, never inside the extent, within the preset budget,
## and none on Fast.

const ZOOM := 13

func _px_hash(x: int, y: int) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)

func _data(preset: int) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	data.latitude = 40.75
	data.longitude = -73.98
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.far_grid_size = 16
	data.far_heights.resize(16 * 16)
	data.far_heights.fill(3.0)
	var origin := FarSurface.global_px(data, -6500.0, -6500.0, ZOOM)
	var far_c := FarSurface.global_px(data, 6500.0, 6500.0, ZOOM)
	var size := Vector2i(int(far_c.x - origin.x), int(far_c.y - origin.y))
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var east_px := FarSurface.global_px(data, 1500.0, 0.0, ZOOM).x - origin.x
	var mid_px := FarSurface.global_px(data, 0.0, 0.0, ZOOM).y - origin.y
	for y in size.y:
		for x in size.x:
			var v := 0.22 + 0.4 * _px_hash(x, y)
			var c := Color(v, v, v * 0.97)  # busy grey roofscape
			if float(x) > east_px:
				c = Color(0.13, 0.26, 0.11) if float(y) < mid_px else Color(0.50, 0.62, 0.30)
			img.set_pixel(x, y, c)
	data.far_drapes = [{"zoom": ZOOM, "origin_px": origin, "size_px": size,
		"texture": null, "image": img, "reach_m": 9500.0}]
	return data

func _init() -> void:
	var failures: Array[String] = []
	var data := _data(3)
	var crowns := FarCanopy.plan(data, GroundTruth.new(data), SettlementMap.build(data))
	var count := crowns.size()
	var forest := 0
	var lawn := 0
	var roofs := 0
	for c in crowns:
		var p: Vector3 = (c as Array)[0]
		if Vector2(p.x, p.z).length() < FarCityBuilder.R_IN - 10.0:
			failures.append("a crown stands inside the detailed extent at %s" % p)
			break
		if p.x < 1400.0:
			roofs += 1
		elif p.z < 0.0:
			forest += 1
		else:
			lawn += 1
	var root := Node3D.new()
	FarCanopy.build(root, data, GroundTruth.new(data), SettlementMap.build(data))
	for mi in root.get_children():
		if str(mi.get_meta("lod_layer", "")) != "FarCity" or not mi.has_meta("far_r0"):
			failures.append("a canopy mesh is not on a FarCity band")
	if count == 0 or forest == 0:
		failures.append("no crowns in the dark forest (%d total)" % count)
	if count > FarCanopy.MAX_CROWNS[3]:
		failures.append("%d crowns over the Ultra budget" % count)
	if lawn > forest / 20:
		failures.append("%d crowns on the sunlit lawn against %d in the forest" % [lawn, forest])
	if roofs > forest / 50:
		failures.append("%d crowns on the roofscape" % roofs)
	root.free()
	var fast := _data(0)
	var none := Node3D.new()
	if FarCanopy.build(none, fast, GroundTruth.new(fast), SettlementMap.build(fast)) != 0:
		failures.append("Fast built far crowns")
	none.free()
	for f in failures:
		printerr("FAR CANOPY FAIL: ", f)
	print("far_canopy_test: forest %d lawn %d roofs %d %s" % [forest, lawn, roofs,
		"FAIL" if not failures.is_empty() else "PASS"])
	quit(1 if not failures.is_empty() else 0)
