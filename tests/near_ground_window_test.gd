extends SceneTree

## Headless: godot --headless --script tests/near_ground_window_test.gd
## NearGroundWindow: attaches only to a world with a near map, follows the
## eye past its limit on whole texels, ignores small moves and high eyes,
## and keeps the old map if a new one cannot be drawn.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
var calls: Array = []
var draw_nothing := false

func _init() -> void:
	_run()
	if failures.is_empty():
		print("NEAR GROUND WINDOW OK")
		quit(0)
	else:
		for f in failures:
			printerr("NEAR GROUND WINDOW FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

## Stands in for GroundMaterial.near_class_map.
func _raster(_data: LocationData, n: int, centre: Vector2, size_u: float) -> Image:
	calls.append([n, centre, size_u])
	if draw_nothing:
		return null
	return Image.create(n, n, false, Image.FORMAT_R8)

func _world(with_map: bool) -> Node3D:
	var root := Node3D.new()
	var terrain := MeshInstance3D.new()
	terrain.name = "Terrain"
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nuniform sampler2D near_class;\nuniform float near_n = 0.0;\nuniform vec4 near_rect = vec4(0.0);\n"
	mat.shader = sh
	if with_map:
		mat.set_shader_parameter("near_class", ImageTexture.create_from_image(Image.create(64, 64, false, Image.FORMAT_R8)))
		mat.set_shader_parameter("near_n", 64.0)
		mat.set_shader_parameter("near_rect", Vector4(100.0, -50.0, 600.0, 60.0))
	terrain.material_override = mat
	root.add_child(terrain)
	return root

## Ticks `w` until its job is done (a job is asynchronous by design).
func _finish(w: NearGroundWindow, eye: Vector2) -> void:
	var guard := 0
	while w.busy() and guard < 2000:
		OS.delay_msec(1)
		w.tick(eye, 30.0)
		guard += 1

func _rect(root: Node3D) -> Vector4:
	var mat := (root.get_child(0) as MeshInstance3D).material_override as ShaderMaterial
	return mat.get_shader_parameter("near_rect")

func _run() -> void:
	failures.clear()
	var data := LocationData.new()
	var bare := _world(false)
	_check(NearGroundWindow.attach(bare, data, _raster) == null, "a world with no near map has nothing to move")
	bare.free()
	var root := _world(true)
	var w := NearGroundWindow.attach(root, data, _raster)
	_check(w != null, "a world with a near map attaches")
	if w == null:
		root.free()
		return
	_check(w.centre() == Vector2(100.0, -50.0), "it starts on the map's own centre")
	w.tick(Vector2(250.0, -50.0), 30.0)
	_check(not w.busy() and calls.is_empty(), "a short walk leaves the map alone")
	w.tick(Vector2(400.0, -50.0), 400.0)
	_check(not w.busy() and calls.is_empty(), "too high to see it: no new map")
	var eye := Vector2(413.0, 20.0)
	w.tick(eye, 30.0)
	_check(w.busy(), "a long walk starts a new map")
	_finish(w, eye)
	_check(calls.size() == 1 and not w.busy(), "one new map is drawn: %d" % calls.size())
	if calls.size() == 1:
		_check(int(calls[0][0]) == 64 and is_equal_approx(float(calls[0][2]), 1200.0), "the new map keeps its size")
	var texel := 1200.0 / 64.0
	var moved := w.centre() - Vector2(100.0, -50.0)
	_check(is_equal_approx(fposmod(moved.x + texel * 0.5, texel), texel * 0.5)
		and is_equal_approx(fposmod(moved.y + texel * 0.5, texel), texel * 0.5), "the centre moves by whole texels: %s" % moved)
	_check(w.centre().distance_to(eye) <= texel, "the new map is centred on the eye: %s" % w.centre())
	var rect := _rect(root)
	_check(Vector2(rect.x, rect.y) == w.centre() and is_equal_approx(rect.z, 600.0) and is_equal_approx(rect.w, 60.0),
		"the material follows and keeps its size and hand-over: %s" % rect)
	# A failed draw keeps the map that works.
	draw_nothing = true
	var kept := w.centre()
	var far_eye := kept + Vector2(0.0, 300.0)
	w.tick(far_eye, 30.0)
	_finish(w, far_eye)
	_check(w.centre() == kept, "a failed draw keeps the old map")
	var snap := w.snapped_centre(kept + Vector2(texel * 3.2, texel * -1.7))
	_check(snap.is_equal_approx(kept + Vector2(texel * 3.0, texel * -2.0)), "snapping rounds to texels: %s" % snap)
	w.stop()
	root.free()
