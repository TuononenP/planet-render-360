extends SceneTree

## Parallel world build (offline): godot --headless --script tests/parallel_build_test.gd
## WorldBuildGraph must give the serial build's world: same child order,
## names, classes, transforms, metas, kept mesh arrays, MultiMesh buffers
## and material properties. A stop request returns an empty world, and
## the progress phase never goes backwards. (Windowed byte-level check of
## every mesh and texture: tools/build_bench.gd parallel vs build.)

func _init() -> void:
	_run()

func _fixture() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	var n := data.grid_size
	data.heights.resize(n * n)
	for z in n:
		for x in n:
			data.heights[z * n + x] = 8.0 + sin(float(x) * 0.3) * 0.5
	data.water_level = -3.0
	data.seed_value = 42
	data.latitude = 48.8566
	data.longitude = 2.3522
	var rect := PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)])
	data.buildings = [
		{"x": -30.0, "z": 0.0, "size_x": 12.0, "size_z": 12.0, "footprint": rect, "height": 18.0,
			"levels": 6, "kind": "apartments", "roof_shape": "mansard", "parts": [], "holes": []},
		{"x": 30.0, "z": 10.0, "size_x": 14.0, "size_z": 14.0, "footprint": PackedVector2Array([
			Vector2(10, -10), Vector2(24, -10), Vector2(24, 4), Vector2(10, 4)]), "height": 12.0,
			"levels": 4, "kind": "house", "roof_shape": "gabled", "parts": [], "holes": []},
	]
	data.roads = [{"points": PackedVector2Array([Vector2(-60, 0), Vector2(60, 0)]), "width_m": 8.0,
		"class": "residential", "surface": "asphalt", "lanes": 2, "bridge": false, "tunnel": false}]
	data.pois = [{"x": 0.0, "z": -22.0, "category": "shop", "kind": "bakery", "name": "Test Bakery"}]
	data.barriers = [
		{"class": "fence", "points": PackedVector2Array([Vector2(40, 80), Vector2(65, 80)]), "fence_type": "chain_link", "height_m": 2.2},
		{"class": "fence", "points": PackedVector2Array([Vector2(70, 80), Vector2(95, 80)]), "material": "wood"}]
	data.landcover_image = Image.create_from_data(2, 2, false, Image.FORMAT_L8,
		PackedByteArray([50, 10, 10, 50]))
	data.canopy_image = Image.create_from_data(2, 2, false, Image.FORMAT_L8,
		PackedByteArray([0, 15, 15, 0]))
	data.land_polygons = [
		{"class": "forest", "points": PackedVector2Array([Vector2(-100, -100), Vector2(100, -100),
			Vector2(100, 100), Vector2(-100, 100)])},
		{"class": "water", "points": PackedVector2Array([Vector2(-80, 40), Vector2(-40, 40),
			Vector2(-40, 60), Vector2(-80, 60)])},
	]
	data.landmark_candidates = [{"archetype": "tower", "x": 140.0, "z": -90.0, "height": 40.0,
		"size_x": 10.0, "size_z": 10.0, "yaw": 0.3}]
	return data

func _hash(root: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for c in root.get_children():
		var hc := HashingContext.new()
		hc.start(HashingContext.HASH_SHA256)
		_feed(c, hc)
		out.append("%s %s %s" % [c.get_class(), "" if str(c.name).begins_with("@") else str(c.name),
			hc.finish().hex_encode().substr(0, 16)])
	return out

func _feed(n: Node, hc: HashingContext) -> void:
	hc.update(("%s|%s|%d" % [n.get_class(), "" if str(n.name).begins_with("@") else str(n.name),
		n.get_child_count()]).to_utf8_buffer())
	var metas := n.get_meta_list()
	metas.sort()
	for m in metas:
		hc.update(("%s=%s" % [m, var_to_str(n.get_meta(m))]).to_utf8_buffer())
	if n is Node3D:
		hc.update(var_to_bytes((n as Node3D).transform))
	if n is GeometryInstance3D:
		var gi := n as GeometryInstance3D
		hc.update(var_to_bytes([gi.cast_shadow, gi.visibility_range_end]))
		_feed_mat(gi.material_override, hc)
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mesh := (n as MeshInstance3D).mesh
		hc.update(mesh.get_class().to_utf8_buffer())
		if mesh.has_meta(MeshArrays.META):
			hc.update(var_to_bytes(mesh.get_meta(MeshArrays.META)))
		for s in mesh.get_surface_count():
			_feed_mat(mesh.surface_get_material(s), hc)
	if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
		var mm := (n as MultiMeshInstance3D).multimesh
		hc.update(var_to_bytes([mm.instance_count, mm.use_colors]))
		if not mm.buffer.is_empty():
			hc.update(mm.buffer.to_byte_array())
	for c in n.get_children():
		_feed(c, hc)

## Material properties by value (textures by size: the dummy renderer
## keeps no texels), so two equal materials hash alike across builds.
func _feed_mat(m: Material, hc: HashingContext) -> void:
	if m == null:
		return
	hc.update(m.get_class().to_utf8_buffer())
	for p in m.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE) or str(p["name"]).begins_with("resource_"):
			continue
		var v: Variant = m.get(p["name"])
		if v is Texture2D:
			hc.update(var_to_bytes((v as Texture2D).get_size()))
		elif v is Shader:
			hc.update((v as Shader).code.to_utf8_buffer())
		elif not (v is Object):
			hc.update(var_to_bytes(v))

## Builds on a Thread, as View360.build_location does (on the main
## thread the graph builds serially).
func _build(data: LocationData, ground: GroundTruth, abort: BuildAbort) -> Node3D:
	var th := Thread.new()
	th.start(func() -> Node3D: return TerrainBuilder.build_world(data, ground, abort))
	while th.is_alive():
		await process_frame
	return th.wait_to_finish()

func _run() -> void:
	var failures: Array[String] = []
	var data := _fixture()
	var ground := GroundTruth.new(data)
	WorldBuildGraph.force_serial = true
	var serial: Node3D = await _build(data, ground, BuildAbort.new())
	WorldBuildGraph.force_serial = false
	var abort := BuildAbort.new()
	var parallel: Node3D = await _build(data, ground, abort)
	var again: Node3D = await _build(data, ground, BuildAbort.new())
	var hs := _hash(serial)
	var hp := _hash(parallel)
	if hs.size() < 6:
		failures.append("fixture world too small to compare (%d children)" % hs.size())
	if hs != hp:
		failures.append("parallel world differs from serial:\n  serial   %s\n  parallel %s"
			% ["\n           ".join(hs), "\n           ".join(hp)])
	if _hash(again) != hp:
		failures.append("a second parallel build differs from the first")
	if abort.step < BuildAbort.Step.VEGETATION:
		failures.append("progress should end past Vegetation, got step %d" % abort.step)
	# A stop requested up front: the graph returns an empty world, fast.
	var stop := BuildAbort.new()
	stop.requested = true
	var stopped: Node3D = await _build(data, ground, stop)
	if stopped == null or stopped.get_child_count() != 0:
		failures.append("a stopped parallel build should return an empty world")
	for w in [serial, parallel, again, stopped]:
		if w != null:
			(w as Node3D).free()
	WorldBuildGraph.force_serial = false
	if failures.is_empty():
		print("PARALLEL BUILD OK: %d top-level children identical to the serial build" % hs.size())
		quit(0)
	else:
		for f in failures:
			printerr("PARALLEL BUILD FAIL: ", f)
		quit(1)
