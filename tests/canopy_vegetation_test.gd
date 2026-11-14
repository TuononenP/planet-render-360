extends SceneTree

const Canopy = preload("res://scripts/generation/canopy_vegetation.gd")

func _init() -> void:
	var failures: Array[String] = []
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.grid_size = 32
	data.heights.resize(data.grid_size * data.grid_size)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.trees = [{"x": 0.0, "z": 0.0}]
	var raster := PackedByteArray()
	raster.resize(16)
	raster.fill(15)
	raster[0] = 0
	raster[15] = 255
	data.canopy_image = Image.create_from_data(4, 4, false, Image.FORMAT_L8, raster)
	var ground := GroundTruth.new(data)
	var mask := VegetationMask.new(data, ground)
	var ctx := VegetationBuilder._context(data, ground)
	var plan := {"pos": [], "sp": [], "scale": [], "real": []}
	var count := Canopy.add(plan, data, ground, mask, ctx)
	if count <= 0 or count != (plan["pos"] as Array).size():
		failures.append("canopy heights should produce bounded tree placements")
	for p in plan["pos"]:
		var pos: Vector3 = p
		if Vector2(pos.x, pos.z).length() <= Canopy.TREE_EXCLUSION_M:
			failures.append("canopy tree overlaps a mapped tree")
			break
		var px := clampi(int((pos.x / 2400.0 + 0.5) * 4.0), 0, 3)
		var py := clampi(int((pos.z / 2400.0 + 0.5) * 4.0), 0, 3)
		if raster[py * 4 + px] in [0, 255]:
			failures.append("no-data or bare canopy cell produced a tree")
			break
	# A no-data canopy sample may use WorldCover, while a valid zero remains
	# bare even when WorldCover classifies the area as trees.
	var cover_bytes := PackedByteArray()
	cover_bytes.resize(16)
	cover_bytes.fill(10)
	data.landcover_image = Image.create_from_data(4, 4, false, Image.FORMAT_L8, cover_bytes)
	data.canopy_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([255]))
	var fallback_plan := {"pos": [], "sp": [], "scale": [], "real": []}
	if Canopy.add(fallback_plan, data, ground, mask, ctx) <= 0:
		failures.append("no-data canopy should fall back to WorldCover trees")
	data.canopy_image = Image.create_from_data(2, 1, false, Image.FORMAT_L8, PackedByteArray([255, 0]))
	var partial_plan := {"pos": [], "sp": [], "scale": [], "real": []}
	if Canopy.add(partial_plan, data, ground, mask, ctx) <= 0:
		failures.append("partial no-data canopy should fall back to WorldCover trees")
	for p in partial_plan["pos"]:
		if (p as Vector3).x >= 0.0:
			failures.append("valid zero canopy cell must not fall back to WorldCover")
			break
	data.canopy_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([0]))
	if Canopy.add({"pos": [], "sp": [], "scale": [], "real": []}, data, ground, mask, ctx) != 0:
		failures.append("valid bare canopy must take precedence over WorldCover")
	data.canopy_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([255]))
	data.landcover_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([0]))
	if bool(VegetationBuilder._context(data, ground)["canopy_present"]):
		failures.append("all-no-data rasters must not suppress procedural fallback")
	var fast_ctx := ctx.duplicate()
	fast_ctx["preset"] = RenderSettings.Preset.FAST
	var fast := {"pos": [], "sp": [], "scale": [], "real": []}
	if Canopy.add(fast, data, ground, mask, fast_ctx) != 0:
		failures.append("Fast must not add raster-derived trees")
	var abort := BuildAbort.new()
	abort.requested = true
	if Canopy.add({"pos": [], "sp": [], "scale": [], "real": []}, data, ground, mask, ctx, abort) != 0:
		failures.append("cancelled canopy placement must stop")
	# Canopy over a pitch: the ground is painted as the pitch, so no
	# tree stands on it; the canopy round it still plants.
	var pitched := LocationData.new()
	RenderSettings.apply_preset(pitched, RenderSettings.Preset.HIGH)
	pitched.latitude = 48.8566
	pitched.longitude = 2.3522
	pitched.grid_size = 32
	pitched.heights.resize(pitched.grid_size * pitched.grid_size)
	pitched.heights.fill(3.0)
	pitched.water_level = -3.0
	pitched.canopy_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([15]))
	pitched.land_polygons = [{"class": "pitch", "points": PackedVector2Array([Vector2(-200, -200),
		Vector2(200, -200), Vector2(200, 200), Vector2(-200, 200)]), "holes": []}]
	var pg := GroundTruth.new(pitched)
	var pitch_plan := {"pos": [], "sp": [], "scale": [], "real": []}
	Canopy.add(pitch_plan, pitched, pg, VegetationMask.new(pitched, pg), VegetationBuilder._context(pitched, pg))
	var on_pitch := 0
	for p in pitch_plan["pos"]:
		if absf((p as Vector3).x) < 199.0 and absf((p as Vector3).z) < 199.0:
			on_pitch += 1
	if on_pitch > 0 or (pitch_plan["pos"] as Array).is_empty():
		failures.append("canopy plants round a pitch but not on it: %d of %d" % [on_pitch,
			(pitch_plan["pos"] as Array).size()])
	if failures.is_empty():
		print("CANOPY VEGETATION OK: height cells, mapped trees, Fast and cancellation")
		quit(0)
	else:
		for failure in failures:
			printerr("CANOPY VEGETATION FAIL: ", failure)
		quit(1)
