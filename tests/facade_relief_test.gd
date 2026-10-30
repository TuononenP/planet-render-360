extends SceneTree

## Headless: godot --headless --script tests/facade_relief_test.gd
## Window recesses and roof variety: the depth map reads glass off the
## roughness map; Ultra facades get deep parallax over it (High does not);
## walls carry tangents; each real building's roof carries one stable
## vertex tint, the tints average 1 (AC-12), and the LodRing merge keeps
## every channel aligned with the vertices.

func _init() -> void:
	_run()

func _data(preset: int) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.seed_value = 7
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.buildings = []
	for i in 16:
		var c := Vector2(float(i % 4) * 40.0 - 60.0, float(i / 4) * 40.0 - 60.0)
		data.buildings.append({"x": c.x, "z": c.y, "size_x": 20.0, "size_z": 14.0,
			"height": 18.0, "levels": 6, "height_source": "levels", "name": "r%d" % i,
			"roof_shape": "gabled" if i % 2 == 0 else "",
			"footprint": PackedVector2Array([c + Vector2(-10, -7), c + Vector2(10, -7),
				c + Vector2(10, 7), c + Vector2(-10, 7)])})
	return data

## {parallax, tangents, roof_colours: Array[Color], roofs_untinted, misaligned}
## over a built (optionally merged) building root.
func _scan(root: Node) -> Dictionary:
	var out := {"parallax": 0, "parallax_no_tangent": 0, "roof_colours": [], "roofs_untinted": 0,
		"misaligned": 0}
	for c in root.get_children():
		if not (c is MeshInstance3D) or (c as MeshInstance3D).mesh == null:
			continue
		var mi := c as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			var arrays := MeshArrays.surface(mi.mesh, s)
			var nv := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			if arrays[Mesh.ARRAY_COLOR] != null and (arrays[Mesh.ARRAY_COLOR] as PackedColorArray).size() != nv:
				out["misaligned"] += 1
			if arrays[Mesh.ARRAY_TANGENT] != null and (arrays[Mesh.ARRAY_TANGENT] as PackedFloat32Array).size() != nv * 4:
				out["misaligned"] += 1
			if mat is BaseMaterial3D and (mat as BaseMaterial3D).heightmap_enabled:
				out["parallax"] += 1
				if arrays[Mesh.ARRAY_TANGENT] == null:
					out["parallax_no_tangent"] += 1
			if RoofVariety.is_roof(mat) and not c.has_meta("lod_impostor"):
				if arrays[Mesh.ARRAY_COLOR] == null:
					out["roofs_untinted"] += 1
				else:
					(out["roof_colours"] as Array).append((arrays[Mesh.ARRAY_COLOR] as PackedColorArray)[0])
	return out

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	# Depth map: glass (rough 0.2) black, wall (0.5 and up) white.
	var rgh := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	rgh.fill(Color(0.5, 0.5, 0.5))
	rgh.fill_rect(Rect2i(2, 1, 3, 2), Color(0.2, 0.2, 0.2))
	var depth := FacadeComposer.depth_from_rough(rgh).get_image()
	if depth == null:
		failures.append("depth map should keep its image")
	elif depth.get_pixel(3, 2).r > 0.05 or depth.get_pixel(0, 0).r < 0.95:
		failures.append("depth map: glass %.2f should be ~0, wall %.2f ~1"
			% [depth.get_pixel(3, 2).r, depth.get_pixel(0, 0).r])
	# Tints are stable per building and average 1.
	if RoofVariety.tint_for(12.0, -40.0) != RoofVariety.tint_for(12.0, -40.0):
		failures.append("roof tint should be stable per building")
	var mean := Color(0, 0, 0)
	for i in 4000:
		mean += RoofVariety.tint_for(float(i % 80) * 23.0 - 900.0, float(i / 80) * 31.0 - 700.0)
	mean = mean / 4000.0
	if absf(mean.r - 1.0) > 0.015 or absf(mean.g - 1.0) > 0.015 or absf(mean.b - 1.0) > 0.015:
		failures.append("roof tints should average 1 (AC-12), got %s" % mean)
	# Built worlds: Ultra recesses windows, High does not.
	for preset in [RenderSettings.Preset.HIGH, RenderSettings.Preset.ULTRA]:
		var data := _data(preset)
		var root := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
		var scan := _scan(root)
		var ultra: bool = preset == RenderSettings.Preset.ULTRA
		if ultra and int(scan["parallax"]) == 0:
			failures.append("Ultra facades should have window parallax")
		if not ultra and int(scan["parallax"]) > 0:
			failures.append("High should not pay for window parallax")
		if int(scan["parallax_no_tangent"]) > 0:
			failures.append("%d parallax walls lack tangents" % scan["parallax_no_tangent"])
		var cols: Array = scan["roof_colours"]
		var distinct := {}
		for c in cols:
			distinct[(c as Color).to_html()] = true
		if int(scan["roofs_untinted"]) > 0 or cols.size() < 8 or distinct.size() < 6:
			failures.append("preset %d: real roofs should carry per-building tints (%d tinted, %d untinted, %d distinct)"
				% [preset, cols.size(), scan["roofs_untinted"], distinct.size()])
		# The near-field merge keeps colour/tangent channels aligned.
		var flat := Node3D.new()
		for c in root.get_children():
			root.remove_child(c)
			if not c.has_meta("lod_layer"):
				c.set_meta("lod_layer", "Buildings")
			flat.add_child(c)
		root.free()
		LodRing.merge_buildings(flat)
		var merged := _scan(flat)
		if int(merged["misaligned"]) > 0:
			failures.append("preset %d: %d merged surfaces have misaligned channels" % [preset, merged["misaligned"]])
		flat.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("FACADE RELIEF OK: depth map, Ultra-only parallax with tangents, per-building roof tints averaging 1, aligned merges")
		quit(0)
	else:
		for f in failures:
			printerr("FACADE RELIEF FAIL: ", f)
		quit(1)
