extends SceneTree

## Headless: godot --headless --script tests/panorama_viewer_test.gd
## PanoramaViewer maths: centre faces heading, seam wraps, poles clamp,
## zoom narrows field, drag matches CameraRig sign convention.

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	# Centre pixel faces the heading; its UV is image centre when heading == origin.
	var dir := PanoramaViewer.direction_for_pixel(Vector2.ZERO, 90.0, 0.0, 70.0, 1.0)
	_check(is_equal_approx(PanoramaViewer.heading_of(dir), 90.0), "centre heading 90, got %s" % PanoramaViewer.heading_of(dir))
	var uv := PanoramaViewer.equirect_uv(dir, 90.0)
	_check(uv.is_equal_approx(Vector2(0.5, 0.5)), "centre uv, got %s" % uv)
	# North / east / south / west cardinal UV columns relative to origin 0.
	_check(is_equal_approx(PanoramaViewer.equirect_uv(Vector3(0, 0, -1), 0.0).x, 0.5), "north centre")
	_check(is_equal_approx(PanoramaViewer.equirect_uv(Vector3(1, 0, 0), 0.0).x, 0.75), "east quarter")
	_check(is_equal_approx(PanoramaViewer.equirect_uv(Vector3(0, 0, 1), 0.0).x, 1.0) or
		is_equal_approx(PanoramaViewer.equirect_uv(Vector3(0, 0, 1), 0.0).x, 0.0), "south seam edge")
	# Seam: headings just either side of 180 wrap to adjacent UV.
	var a := PanoramaViewer.equirect_uv(Vector3(sin(deg_to_rad(179.0)), 0, -cos(deg_to_rad(179.0))), 0.0).x
	var b := PanoramaViewer.equirect_uv(Vector3(sin(deg_to_rad(-179.0)), 0, -cos(deg_to_rad(-179.0))), 0.0).x
	_check(absf(a - b) > 0.9, "seam columns at opposite edges: %s %s" % [a, b])
	# Poles: v at extremes, no NaN.
	var top := PanoramaViewer.equirect_uv(Vector3.UP, 0.0)
	var bot := PanoramaViewer.equirect_uv(Vector3.DOWN, 0.0)
	_check(is_equal_approx(top.y, 0.0) and is_equal_approx(bot.y, 1.0), "poles v: %s %s" % [top, bot])
	_check(not is_nan(top.x) and not is_nan(bot.x), "poles not NaN")
	# Right edge looks right of centre (heading increases = eastward for north view).
	var right := PanoramaViewer.direction_for_pixel(Vector2(1, 0), 0.0, 0.0, 70.0, 1.0)
	_check(PanoramaViewer.heading_of(right) > 0.0 and PanoramaViewer.heading_of(right) < 90.0, "right edge heads NE-ish: %s" % PanoramaViewer.heading_of(right))
	# Up edge looks up.
	var up := PanoramaViewer.direction_for_pixel(Vector2(0, 1), 0.0, 0.0, 70.0, 1.0)
	_check(up.y > 0.3, "up edge rises: %s" % up.y)
	# Zoom: narrower FOV -> right edge closer to centre heading.
	var wide := PanoramaViewer.heading_of(PanoramaViewer.direction_for_pixel(Vector2(1, 0), 0.0, 0.0, 90.0, 1.0))
	var narrow := PanoramaViewer.heading_of(PanoramaViewer.direction_for_pixel(Vector2(1, 0), 0.0, 0.0, 30.0, 1.0))
	_check(narrow < wide, "zoom narrows: %s < %s" % [narrow, wide])
	# Drag: exact CameraRig sensitivity (0.005 rad/px), both signs.
	var after := PanoramaViewer.apply_drag(10.0, 0.0, Vector2(100, 0))
	_check(is_equal_approx(after.x, 10.0 + rad_to_deg(0.5)), "drag exact: %s" % after.x)
	var down := PanoramaViewer.apply_drag(0.0, 0.0, Vector2(0, 100))
	_check(is_equal_approx(down.y, -0.5), "drag down exact: %s" % down.y)
	# Pitch clamps at both poles, exactly.
	_check(is_equal_approx(PanoramaViewer.apply_drag(0.0, 0.0, Vector2(0, -100000)).y, PanoramaViewer.PITCH_MAX), "pitch clamp up")
	_check(is_equal_approx(PanoramaViewer.apply_drag(0.0, 0.0, Vector2(0, 100000)).y, -PanoramaViewer.PITCH_MAX), "pitch clamp down")
	# Directions at pitch clamp stay finite unit vectors at any heading.
	for h in [0.0, 90.0, 210.0]:
		var d := PanoramaViewer.direction_for_pixel(Vector2(0.4, -0.3), h, PanoramaViewer.PITCH_MAX, 70.0, 1.7)
		_check(d.is_normalized() and not is_nan(d.x + d.y + d.z), "pole direction finite h=%s" % h)
	# Wide / portrait aspect widens / narrows the right-edge heading exactly by tan-half-FOV.
	var h_wide := PanoramaViewer.heading_of(PanoramaViewer.direction_for_pixel(Vector2(1, 0), 0.0, 0.0, 90.0, 2.0))
	var h_port := PanoramaViewer.heading_of(PanoramaViewer.direction_for_pixel(Vector2(1, 0), 0.0, 0.0, 90.0, 0.5))
	_check(is_equal_approx(h_wide, rad_to_deg(atan(2.0))) and is_equal_approx(h_port, rad_to_deg(atan(0.5))),
		"aspect headings: %s %s" % [h_wide, h_port])
	# Zoom clamps.
	_check(is_equal_approx(PanoramaViewer.apply_zoom(70.0, 100.0), 25.0), "zoom clamp in")
	_check(is_equal_approx(PanoramaViewer.apply_zoom(70.0, 0.01), 95.0), "zoom clamp out")
	_check(is_equal_approx(PanoramaViewer.apply_zoom(70.0, 2.0), 35.0), "zoom exact")
	# Compass
	_check(PanoramaViewer.compass_text(0.0) == "N" and PanoramaViewer.compass_text(90.0) == "E"
		and PanoramaViewer.compass_text(359.0) == "N", "compass text")

	await _instance_test()
	_finish()

## Instance-level: open decodes off-thread then sets the shader texture
## and origin heading, routed viewport input drags, close clears, a
## missing file fails at once and a damaged one reports open_failed.
func _instance_test() -> void:
	const VDIR := "user://panorama-viewer-test"
	PanoramaLibrary.dir_override = VDIR
	DirAccess.make_dir_recursive_absolute(VDIR)
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	img.fill(Color(0.3, 0.5, 0.8))
	var entry := PanoramaLibrary.add(PanoramaCapture.encode(img, 42.0), "Test Place", 1.0, 2.0, 42.0,
		{"year": 2026, "month": 11, "day": 1, "hour": 10, "minute": 0})
	_check(not entry.is_empty(), "instance entry added")
	var viewer := PanoramaViewer.new()
	viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(viewer)
	await process_frame
	# Phone width: bottom buttons go icon-only (keeping tooltips) so all fit.
	viewer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	viewer.size = Vector2(390, 844)
	viewer._layout()
	_check(viewer._bar_buttons.size() == 3 and viewer._bar_buttons.all(func(b: Button) -> bool:
		return b.text == "" and b.tooltip_text != ""), "phone bar is icon-only with tooltips")
	viewer.size = Vector2(1200, 800)
	viewer._layout()
	_check(viewer._bar_buttons.all(func(b: Button) -> bool: return b.text != ""), "wide bar keeps labels")
	viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer.offset_right = 0
	viewer.offset_bottom = 0
	_check(viewer.open(entry), "open succeeds")
	_check(viewer.is_loading() and viewer._loading.visible, "loading label while decoding")
	await _until_loaded(viewer)
	_check(not viewer._loading.visible, "loading label hidden after decode")
	_check(viewer._mat.get_shader_parameter("pano") != null, "shader pano set")
	_check(viewer._caption.text.begins_with("Test Place · "), "caption has place and date: %s" % viewer._caption.text)
	_check(is_equal_approx(viewer._heading_deg, 42.0), "opens at capture heading")
	# Routed input: a left-drag through the real viewport must turn the view.
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(100, 0)
	# Window coordinates: the headless root is a tiny window stretched
	# to the content size, and events outside it are dropped.
	motion.position = Vector2(root.size) * 0.5
	root.push_input(motion)
	await process_frame
	# The GUI sees `relative` in content coordinates (window stretch undone).
	var rel_x := root.get_final_transform().affine_inverse().basis_xform(motion.relative).x
	_check(is_equal_approx(viewer._heading_deg, 42.0 + rel_x * rad_to_deg(0.005)),
		"routed drag turns view: %s (rel %s)" % [viewer._heading_deg, rel_x])
	viewer.close()
	_check(viewer._mat.get_shader_parameter("pano") == null, "close clears pano")
	_check(not viewer.open({"file": "missing.jpg", "place": "Gone"}), "open missing fails")
	# Damaged file: open() accepts it, the decode then reports failure.
	var junk := FileAccess.open(VDIR.path_join("junk_360_x.jpg"), FileAccess.WRITE)
	junk.store_buffer(PackedByteArray([0xFF, 0xD8, 1, 2, 3, 4]))
	junk.close()
	var failed := [false]
	viewer.open_failed.connect(func(_e: Dictionary) -> void: failed[0] = true)
	_check(viewer.open({"file": "junk_360_x.jpg", "place": "Junk"}), "damaged file starts opening")
	await _until_loaded(viewer)
	_check(failed[0], "damaged file reports open_failed")
	_check(viewer._mat.get_shader_parameter("pano") == null, "damaged file sets no texture")
	# Close mid-decode abandons it cleanly.
	_check(viewer.open(entry), "reopen")
	viewer.close()
	_check(not viewer.is_loading(), "close abandons decode")
	await process_frame
	_check(viewer._mat.get_shader_parameter("pano") == null, "abandoned decode sets no texture")
	for i in 300:
		if viewer._abandoned.is_empty():
			break
		await process_frame
	_check(viewer._abandoned.is_empty(), "abandoned decode is reaped without blocking close")
	_check(viewer._mat.get_shader_parameter("pano") == null, "reaped decode still sets no texture")
	viewer.queue_free()
	PanoramaLibrary.dir_override = ""
	for fn in DirAccess.get_files_at(VDIR):
		DirAccess.remove_absolute(VDIR.path_join(fn))
	if DirAccess.dir_exists_absolute(VDIR.path_join("thumbs")):
		for fn in DirAccess.get_files_at(VDIR.path_join("thumbs")):
			DirAccess.remove_absolute(VDIR.path_join("thumbs").path_join(fn))
		DirAccess.remove_absolute(VDIR.path_join("thumbs"))
	DirAccess.remove_absolute(VDIR)

func _until_loaded(viewer: PanoramaViewer) -> void:
	for i in 300:
		if not viewer.is_loading():
			return
		await process_frame
	_check(false, "decode finished in time")

func _finish() -> void:
	if _failures.is_empty():
		print("PANORAMA VIEWER OK: centre, seam, poles, zoom, drag, compass")
		quit(0)
	else:
		for f in _failures:
			printerr("PANORAMA VIEWER FAIL: ", f)
		quit(1)
