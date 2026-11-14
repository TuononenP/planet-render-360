extends SceneTree

## Reproducible vessel inspection, including costs before GPU upload.
## tools/godot_bg.sh --path . --script tools/capture_vessels.gd --position 4000,4000 -- --out=visual-plan/reviews/vessels/before
## Add --metrics-only and --headless for geometry-only measurements.
## --only=liner,ferry limits the studio shots to those case ids. Ships of
## 40 m and more also get close-ups (bow quarter, midships) and a night shot.
const CASES := [
	["liner", 250.0, 31.0, 50.0, ""], ["passenger", 50.0, 8.0, 12.0, ""],
	["tall_ship", 60.0, 9.5, 32.0, ""], ["houseboat", 14.0, 4.2, 4.5, ""],
	["motor_yacht", 24.0, 0.0, 0.0, "flybridge"], ["motor_yacht", 11.0, 0.0, 0.0, "sport"],
	["sail_yacht", 12.0, 0.0, 0.0, ""], ["runabout", 7.0, 0.0, 0.0, "runabout"],
	["runabout", 7.0, 0.0, 0.0, "console"], ["runabout", 7.0, 0.0, 0.0, "rib"],
	["ferry", 94.5, 21.3, 16.0, ""], ["catamaran", 12.0, 0.0, 15.5, ""],
	["cruise_ferry", 200.0, 30.0, 44.0, ""], ["cargo", 300.0, 45.0, 52.0, "container"],
	["cargo", 190.0, 30.0, 32.0, "bulk"], ["cargo", 250.0, 44.0, 40.0, "tanker"], ["cargo", 110.0, 17.0, 26.0, "general"]]
const SIZE := Vector2i(960, 640)
var _out := "visual-plan/reviews/vessels"
var _metrics_only := false
var _benchmark_only := false
var _only: PackedStringArray = []

func _init() -> void:
	_run.call_deferred()

func _model(c: Array, detail: bool) -> LandmarkMesh:
	if c[0] == "ferry":
		return HarbourFerries.model()
	return VesselPrototypes.geometry(c[0], c[1], c[2], c[3], VesselMaterials.paint("#294158"), detail, true, 0.9, c[4])

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		_metrics_only = _metrics_only or arg == "--metrics-only"
		_benchmark_only = _benchmark_only or arg == "--benchmark-only"
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	DirAccess.make_dir_recursive_absolute(_out)
	MaterialLibrary.hi_res = true
	var stats := {"models": {}, "prototypes": {}}
	for c in CASES:
		if c[0] == "catamaran" and "catamaran" not in VesselPrototypes.KINDS:
			continue
		var id: String = c[4] if c[4] != "" else c[0]
		var start := Time.get_ticks_usec()
		var near := _model(c, true)
		var build_us := Time.get_ticks_usec() - start
		stats["models"][id] = {"near": near.triangle_count(), "far": _model(c, false).triangle_count(), "build_us": build_us}
	for kind in VesselPrototypes.KINDS:
		for suffix in ["", "_far"]:
			var start := Time.get_ticks_usec()
			var mesh := VesselPrototypes.mesh(kind + suffix)
			var triangles := 0
			for s in mesh.get_surface_count():
				triangles += mesh.surface_get_array_len(s) / 3
			stats["prototypes"][kind + suffix] = {"triangles": triangles, "surfaces": mesh.get_surface_count(), "build_us": Time.get_ticks_usec() - start}
	if not _metrics_only:
		await _captures(stats)
	var f := FileAccess.open(_out.path_join("stats.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(stats, "\t") + "\n")
	print("VESSEL CAPTURE DONE ", _out, " ", JSON.stringify(stats))
	quit(0)

func _captures(stats: Dictionary) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = SIZE
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#b8cdd7")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#dbe8ef")
	env.environment.ambient_light_energy = 0.65
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	vp.add_child(env)
	RenderingServer.global_shader_parameter_set("climate_snow_on", 0.0)
	RenderingServer.global_shader_parameter_set("climate_snow_y", -30.0)
	RenderingServer.global_shader_parameter_set("climate_snow_band", 1.0)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -35, 0)
	light.light_energy = 1.5
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 700.0
	vp.add_child(light)
	var camera := Camera3D.new()
	camera.fov = 42.0
	camera.far = 2000.0
	vp.add_child(camera)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2000, 2000)
	water.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#3c6874")
	mat.roughness = 0.28
	mat.metallic = 0.2
	water.material_override = mat
	vp.add_child(water)
	for c in CASES:
		if _benchmark_only:
			break
		if c[0] == "catamaran" and "catamaran" not in VesselPrototypes.KINDS:
			continue
		var id: String = c[4] if c[4] != "" else c[0]
		if not _only.is_empty() and id not in _only:
			continue
		var holder := Node3D.new()
		vp.add_child(holder)
		VesselPrototypes.snow_parts(_model(c, true).commit(holder))
		var length: float = c[1]
		var height: float = c[3] if c[3] > 0.0 else length * 0.4
		var target := Vector3(0, height * 0.45, 0)
		var distance := maxf(length * 1.05, height * 1.85)
		var directions := [Vector3(0.8, 0.42, 1), Vector3(-0.8, 0.42, 1), Vector3(0.2, 0.85, 1)]
		for i in directions.size():
			camera.look_at_from_position(target + (directions[i] as Vector3).normalized() * distance, target)
			await _settle(12)
			vp.get_texture().get_image().save_jpg(_out.path_join("%s_%d.jpg" % [id, i]), 0.9)
		# Deck inspection deliberately crops tall masts to expose the fittings.
		var deck_target := Vector3(0, minf(height * 0.2, length * 0.13), 0)
		camera.look_at_from_position(deck_target + Vector3(-0.4, 0.65, 1).normalized() * length * 0.85, deck_target)
		await _settle(12)
		vp.get_texture().get_image().save_jpg(_out.path_join(id + "_deck.jpg"), 0.9)
		if length >= 40.0:
			await _close_ups(vp, camera, env.environment, light, holder, id, length, height)
		if id in ["houseboat", "sail_yacht"]:
			RenderingServer.global_shader_parameter_set("climate_snow_on", 1.0)
			await _settle(12)
			vp.get_texture().get_image().save_jpg(_out.path_join(id + "_winter.jpg"), 0.9)
			RenderingServer.global_shader_parameter_set("climate_snow_on", 0.0)
		vp.remove_child(holder)
		holder.free()
		if id != "ferry":
			var distant := Node3D.new()
			vp.add_child(distant)
			VesselPrototypes.snow_parts(_model(c, false).commit(distant))
			camera.look_at_from_position(target + (directions[0] as Vector3).normalized() * distance, target)
			await _settle(12)
			vp.get_texture().get_image().save_jpg(_out.path_join(id + "_far.jpg"), 0.9)
			vp.remove_child(distant)
			distant.free()
	# A fixed 700-vessel fleet tests the actual instancing path and renderer.
	var fleet := Node3D.new()
	vp.add_child(fleet)
	var start := Time.get_ticks_usec()
	var surfaces := 0
	for k in 7:
		for far in 2:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = VesselPrototypes.mesh(VesselPrototypes.KINDS[k] + ("_far" if far == 1 else ""))
			mm.instance_count = 50
			surfaces += mm.mesh.get_surface_count()
			for i in 50:
				mm.set_instance_transform(i, Transform3D(Basis(), Vector3((i % 10) * 14 - 70, 0, (k * 10 + far * 5 + i / 10) * 5 - 160)))
				mm.set_instance_color(i, Color("#e1e3df") if i % 3 else Color("#294158"))
			var instance := MultiMeshInstance3D.new()
			instance.multimesh = mm
			fleet.add_child(instance)
	stats["fleet_build_us"] = Time.get_ticks_usec() - start
	stats["fleet_surfaces"] = surfaces
	camera.look_at_from_position(Vector3(-130, 180, 230), Vector3(0, 0, 0))
	await _settle(60)
	start = Time.get_ticks_usec()
	var cpu := 0.0
	var gpu := 0.0
	for i in 90:
		await _settle(1)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid())
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
	stats["fleet_cpu_ms"] = cpu / 90.0
	stats["fleet_gpu_ms"] = gpu / 90.0
	stats["fleet_frame_ms"] = float(Time.get_ticks_usec() - start) / 90000.0
	stats["renderer"] = RenderingServer.get_current_rendering_method()
	vp.get_texture().get_image().save_jpg(_out.path_join("fleet.jpg"), 0.9)
	vp.free()

## Bow quarter and midships from near the waterline, then the bow quarter
## again at night with CityLights at full strength.
func _close_ups(vp: SubViewport, camera: Camera3D, env: Environment, light: DirectionalLight3D,
		holder: Node3D, id: String, length: float, height: float) -> void:
	var bow := Vector3(length * 0.3, height * 0.22, 0)
	camera.look_at_from_position(bow + Vector3(0.55, 0.12, 1).normalized() * length * 0.42, bow)
	await _settle(12)
	vp.get_texture().get_image().save_jpg(_out.path_join(id + "_close_bow.jpg"), 0.9)
	var mid := Vector3(-length * 0.05, height * 0.3, 0)
	camera.look_at_from_position(mid + Vector3(-0.15, 0.05, 1).normalized() * length * 0.3, mid)
	await _settle(12)
	vp.get_texture().get_image().save_jpg(_out.path_join(id + "_close_mid.jpg"), 0.9)
	var bg := env.background_color
	var ambient := env.ambient_light_energy
	var sun := light.light_energy
	env.background_color = Color("#0b1220")
	env.ambient_light_energy = 0.08
	light.light_energy = 0.03
	CityLights.apply(holder, 1.0)
	camera.look_at_from_position(Vector3(0, height * 0.35, 0) + Vector3(0.8, 0.3, 1).normalized() * length * 0.75,
		Vector3(0, height * 0.35, 0))
	await _settle(12)
	vp.get_texture().get_image().save_jpg(_out.path_join(id + "_night.jpg"), 0.9)
	CityLights.apply(holder, 0.0)
	env.background_color = bg
	env.ambient_light_energy = ambient
	light.light_energy = sun

func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
		RenderingServer.force_draw(false)
