extends SceneTree

## Reproducible car inspection: every CarSpecs kind in a sky-lit studio,
## drawn through a one-car MultiMesh like ParkedCars (instance colour and
## CarPaint finish), plus triangle counts per kind and LOD.
## tools/godot_bg.sh --path . --script tools/capture_cars.gd --position 4000,4000 -- --out=visual-plan/reviews/cars/before
## --only=sedan,suv limits the shots to those kinds; --metrics-only (with
## --headless) writes stats.json alone.
const SIZE := Vector2i(960, 640)
const PAINTS := {
	"sedan": Color(0.04, 0.08, 0.2), "hatch": Color(0.2, 0.04, 0.04), "wagon": Color(0.3, 0.31, 0.32),
	"suv": Color(0.85, 0.85, 0.84), "compact_suv": Color(0.55, 0.56, 0.57), "van": Color(0.85, 0.85, 0.84),
	"pickup": Color(0.03, 0.03, 0.035), "kei": Color(0.85, 0.85, 0.84), "minivan": Color(0.42, 0.4, 0.34),
	"cab_london": Color(0.03, 0.03, 0.035), "bus": Color(0.1, 0.32, 0.6), "taxi": Color(0.95, 0.62, 0.02),
	"taxi_lisbon": Color(0.03, 0.03, 0.035), "sports": Color(0.5, 0.02, 0.02),
}
var _out := "visual-plan/reviews/cars"
var _metrics_only := false
var _only: PackedStringArray = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		_metrics_only = _metrics_only or arg == "--metrics-only"
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	DirAccess.make_dir_recursive_absolute(_out)
	var stats := {}
	for kind: String in CarSpecs.KINDS:
		var start := Time.get_ticks_usec()
		var near := CarModel.mesh(kind)
		var build_us := Time.get_ticks_usec() - start
		stats[kind] = {"near": _tris(near), "far": _tris(CarModel.mesh(kind, true)), "build_us": build_us}
	if not _metrics_only:
		await _captures()
	var f := FileAccess.open(_out.path_join("stats.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(stats, "\t") + "\n")
	print("CAR CAPTURE DONE ", _out, " ", JSON.stringify(stats))
	quit(0)

func _tris(m: ArrayMesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		n += m.surface_get_array_len(s) / 3
	return n

func _car(kind: String, far: bool, at: Vector3 = Vector3.ZERO, yaw: float = 0.0) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = CarModel.mesh(kind, far)
	mm.instance_count = 1
	mm.set_instance_transform(0, Transform3D(Basis(Vector3.UP, yaw), at))
	var paint: Color = PAINTS.get(kind, Color.WHITE)
	var solid := kind.begins_with("taxi") or kind == "cab_london" or kind == "bus"
	mm.set_instance_color(0, paint)
	mm.set_instance_custom_data(0, Color(0.0 if solid else 1.0, 0.3, 0.0, 0.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	var shadow := MeshInstance3D.new()
	shadow.mesh = ParkedCars.shadow_mesh(kind)
	shadow.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	mmi.add_child(shadow)
	return mmi

func _captures() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = SIZE
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#5d86b8")
	sky_mat.sky_horizon_color = Color("#c4d3df")
	sky_mat.ground_bottom_color = Color("#3a3d40")
	sky_mat.ground_horizon_color = Color("#9aa3a8")
	sky.sky_material = sky_mat
	env.environment.sky = sky
	env.environment.background_mode = Environment.BG_SKY
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.environment.ambient_light_energy = 0.8
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.environment.ssao_enabled = true
	vp.add_child(env)
	RenderingServer.global_shader_parameter_set("climate_snow_on", 0.0)
	RenderingServer.global_shader_parameter_set("climate_snow_y", -30.0)
	RenderingServer.global_shader_parameter_set("climate_snow_band", 1.0)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -55, 0)
	light.light_energy = 1.6
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 80.0
	light.shadow_bias = 0.06
	light.shadow_normal_bias = 1.6
	vp.add_child(light)
	var camera := Camera3D.new()
	camera.fov = 38.0
	camera.far = 600.0
	vp.add_child(camera)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(800, 800)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#56595c")
	mat.roughness = 0.85
	ground.material_override = mat
	vp.add_child(ground)
	for kind: String in CarSpecs.KINDS:
		if not _only.is_empty() and kind not in _only:
			continue
		var s := CarSpecs.spec(kind)
		var length := float(s["len"])
		var height := float(s["h"])
		var dist := maxf(length * 1.45, height * 3.0)
		var target := Vector3(0, height * 0.45, 0)
		var shots := {
			"front": Vector3(0.85, 0.32, 0.75), "rear": Vector3(-0.85, 0.32, 0.75), "side": Vector3(0.0, 0.12, 1.0),
			"top": Vector3(0.5, 0.95, 0.6),
		}
		for far in [false, true]:
			var car := _car(kind, far)
			vp.add_child(car)
			for shot: String in (shots.keys() if not far else ["front"]):
				camera.look_at_from_position(target + (shots[shot] as Vector3).normalized() * dist, target)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join("%s_%s%s.jpg" % [kind, shot, "_far" if far else ""]), 0.9)
			if not far:
				# Close on the nose and on a front wheel at eye height.
				var nose := Vector3(length * 0.45, height * 0.42, 0)
				camera.look_at_from_position(nose + Vector3(1.0, 0.18, 0.42).normalized() * maxf(length * 0.55, 2.6), nose)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join(kind + "_nose.jpg"), 0.9)
				var tail := Vector3(-length * 0.45, height * 0.42, 0)
				camera.look_at_from_position(tail + Vector3(-1.0, 0.18, 0.42).normalized() * maxf(length * 0.55, 2.6), tail)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join(kind + "_tail.jpg"), 0.9)
				# The windscreen's foot from behind and above the driver's seat: wipers, scuttle.
				var gh3 := float((s["gh"] as PackedFloat32Array)[3])
				var sb := Vector3(gh3 - 0.05, float(s["belt_h"]) + 0.1, 0.0)
				camera.look_at_from_position(sb + Vector3(-0.9, 0.55, 0.55), sb)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join(kind + "_screen.jpg"), 0.9)
				# Under the body from ground height, side on: the gap between sill and road.
				var belly := Vector3(0.0, 0.17, 0.0)
				camera.look_at_from_position(Vector3(0.6, 0.22, 3.2), belly)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join(kind + "_belly.jpg"), 0.9)
				# The bumper's lower corner from just above the ground.
				var corner := Vector3(length * 0.5 - 0.15, 0.2, float(s["wid"]) * 0.35)
				camera.look_at_from_position(corner + Vector3(0.9, 0.12, 0.8).normalized() * 1.1, corner)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join(kind + "_corner.jpg"), 0.9)
				var wheel := Vector3(float(s["axle_f"]), float(s["wheel_r"]), float(s["wid"]) * 0.5)
				camera.look_at_from_position(wheel + Vector3(0.35, 0.25, 1.0).normalized() * 1.9, wheel)
				await _settle(10)
				vp.get_texture().get_image().save_jpg(_out.path_join(kind + "_wheel.jpg"), 0.9)
			vp.remove_child(car)
			car.free()
	if _only.is_empty():
		# The whole fleet in a row, as a pedestrian on the far kerb sees it.
		var row := Node3D.new()
		vp.add_child(row)
		var x := 0.0
		for kind: String in CarSpecs.KINDS:
			var l := CarSpecs.length_m(kind)
			row.add_child(_car(kind, false, Vector3(x + l * 0.5, 0, 0)))
			x += l + 0.9
		var mid := Vector3(x * 0.5, 0.9, 0)
		camera.look_at_from_position(mid + Vector3(-0.15, 0.08, 1).normalized() * x * 0.62, mid)
		await _settle(12)
		vp.get_texture().get_image().save_jpg(_out.path_join("lineup.jpg"), 0.9)
		# A pedestrian's eye along the kerb: 1.7 m up, a few cars in view, near and further.
		camera.fov = 60.0
		for k in 3:
			var from := Vector3(6.0 + float(k) * 18.0, 1.7, 5.5)
			camera.look_at_from_position(from, from + Vector3(14.0, -0.6, -4.5))
			await _settle(12)
			vp.get_texture().get_image().save_jpg(_out.path_join("street_%d.jpg" % k), 0.9)
		camera.fov = 38.0
		vp.remove_child(row)
		row.free()
	vp.free()

func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
		RenderingServer.force_draw(false)
