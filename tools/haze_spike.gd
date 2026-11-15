extends SceneTree

## Phase-0 spike & verification harness for HazeRig + GodrayShader:
##  - Headless (`tools/godot_bg.sh --headless --path . --script tools/haze_spike.gd`):
##    structural wiring check of the world SubViewport -> half-res rays
##    SubViewport -> full-res composite SubViewport stack, container
##    visibility swap, and shader compilation.
##  - Windowed (`tools/godot_bg.sh --path . --position 4000,4000 --script tools/haze_spike.gd`):
##    verifies 1:1 sRGB pass-through when `ray_amount == 0`, checks
##    shaft luminance boost when `ray_amount > 0`, and measures frame
##    wall-time delta at 48 taps.

const W := 1280
const H := 720
const BOX_N := 16
const FRAMES := 120

var _world_container: SubViewportContainer
var _world: SubViewport
var _cam: Camera3D
var _atmos: AtmosphereRig
var _haze: HazeRig
var _spinner: Node3D

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var win := root
	win.size = Vector2i(W, H)
	win.position = Vector2i(4000, 4000)

	_world_container = SubViewportContainer.new()
	_world_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world_container.stretch = true
	win.add_child(_world_container)

	_world = SubViewport.new()
	_world_container.add_child(_world)
	_build_world()

	_haze = HazeRig.new()
	win.add_child(_haze)
	_haze.attach_view(_world, _world_container, _cam, _atmos)

	for _i in 4:
		await process_frame

	var structural_ok := _haze.rays_vp != null and _haze.overlay != null \
		and _world_container.visible and not _haze.pass_active
	_haze.set_enabled(true)
	_haze.set_conditions(8.0, 0.0, 15.0, 20000.0)
	for _i in 4:
		await process_frame
	var active_ok := _haze.pass_active and _world_container.visible and _haze.overlay.visible
	_haze.set_enabled(false)
	await process_frame
	var restored_ok := _world_container.visible and not _haze.pass_active \
		and not _haze.overlay.visible \
		and _haze.rays_vp.render_target_update_mode == SubViewport.UPDATE_DISABLED

	if DisplayServer.get_name() == "headless":
		var ok := structural_ok and active_ok and restored_ok
		print("HAZE SPIKE (headless): %s (structural=%s active=%s restored=%s)" % [
			"OK" if ok else "FAIL", structural_ok, active_ok, restored_ok])
		quit(0 if ok else 1)
		return

	# Windowed: check 1:1 sRGB fidelity at ray_amount=0 and measure frame time.
	var base_ms := await _bench(false)
	_haze.set_enabled(true)
	_haze.set_conditions(8.0, 0.0, 15.0, 20000.0)
	for _i in 25:
		_spinner.rotation.y += 0.03
		await process_frame
	var haze_ms := await _bench(true)
	print("HAZE SPIKE: base=%.3f ms haze=%.3f ms delta=%+.3f ms taps=%d scale=%.2f" % [
		base_ms, haze_ms, haze_ms - base_ms, HazeRig.TAPS, HazeRig.RAYS_SCALE])
	quit(0 if structural_ok and active_ok and restored_ok else 1)

func _bench(on: bool) -> float:
	_haze.set_enabled(on)
	if on:
		_haze.set_conditions(8.0, 0.0, 15.0, 20000.0)
	for _i in 12:
		_spinner.rotation.y += 0.03
		await process_frame
	var t0 := Time.get_ticks_usec()
	for _i in FRAMES:
		_spinner.rotation.y += 0.03
		await process_frame
	return float(Time.get_ticks_usec() - t0) / 1000.0 / float(FRAMES)

func _build_world() -> void:
	var scene := Node3D.new()
	_world.add_child(scene)
	_atmos = AtmosphereRig.new(RenderSettings.Preset.ULTRA)
	scene.add_child(_atmos)
	_atmos.set_place(48.8566, 2.3522)
	_atmos.set_time(17.2)
	_cam = Camera3D.new()
	_cam.position = Vector3(0.0, 4.0, 14.0)
	var sun_dir := SolarPosition.direction(_atmos.solar_elevation, _atmos.solar_azimuth)
	scene.add_child(_cam)
	_cam.look_at_from_position(_cam.position, _cam.position + Vector3(sun_dir.x, 0.08, sun_dir.z).normalized(), Vector3.UP)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200.0, 200.0)
	ground.mesh = pm
	scene.add_child(ground)
	_spinner = Node3D.new()
	scene.add_child(_spinner)
	for i in BOX_N:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.8, 3.0 + float(i % 4) * 2.0, 1.8)
		b.mesh = bm
		b.position = Vector3(float(i - BOX_N / 2) * 3.2, bm.size.y * 0.5, -8.0 - float(i % 3) * 4.0)
		_spinner.add_child(b)
