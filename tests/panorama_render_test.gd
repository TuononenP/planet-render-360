extends SceneTree

## Needs a window (a real renderer): godot --path . --position 4000,4000 --script tests/panorama_render_test.gd
## Renders a room whose six walls are six colours and checks the projection
## puts each wall where the viewer would see it: ahead at the centre of the
## picture, right a quarter of the way along, behind at the edges, up at the
## top and down at the bottom, whatever the camera's pitch.

const FACE := 256
const WALLS := {
	"+X": [Vector3(1, 0, 0), Color(1, 0, 0)],
	"-X": [Vector3(-1, 0, 0), Color(0, 1, 1)],
	"+Y": [Vector3(0, 1, 0), Color(0, 1, 0)],
	"-Y": [Vector3(0, -1, 0), Color(1, 0, 1)],
	"+Z": [Vector3(0, 0, 1), Color(0, 0, 1)],
	"-Z": [Vector3(0, 0, -1), Color(1, 1, 0)],
}

var _failures: Array[String] = []
var _nodes: Array[Node] = []

func _init() -> void:
	_run()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("PANORAMA RENDER SKIPPED: needs a window")
		quit(0)
		return
	DisplayServer.window_set_size(Vector2i(640, 360))
	root.size = Vector2i(640, 360)
	for key in WALLS:
		var dir: Vector3 = WALLS[key][0]
		var quad := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(60, 60)
		quad.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = WALLS[key][1]
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		quad.material_override = mat
		root.add_child(quad)
		_nodes.append(quad)
		# A quad faces +Z; put it at 10 m along `dir`, facing the origin.
		var up := Vector3.UP if absf(dir.y) < 0.5 else Vector3.RIGHT
		quad.transform = Transform3D(Basis.looking_at(-dir, up), dir * 10.0)
	var cam := Camera3D.new()
	root.add_child(cam)
	_nodes.append(cam)
	cam.current = true
	await process_frame
	# Looking along +X; level, then pitched up 40 degrees.
	for pitch in [0.0, 40.0]:
		cam.transform = Transform3D(Basis.looking_at(Vector3(1, tan(deg_to_rad(pitch)), 0).normalized(), Vector3.UP), Vector3.ZERO)
		var img := await PanoramaCapture.capture(root, cam, RenderSettings.Preset.HIGH, FACE)
		_check(img, pitch)
		var out := OS.get_environment("PANORAMA_OUT")
		if out != "" and img != null:
			img.save_png("%s/panorama_pitch%d.png" % [out, int(pitch)])
	for n in _nodes:
		n.queue_free()
	if _failures.is_empty():
		print("PANORAMA RENDER OK: each wall lands where the viewer sees it, at level and pitched")
		quit(0)
	else:
		for f in _failures:
			printerr("PANORAMA RENDER FAIL: ", f)
		quit(1)

func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.45

func _check(img: Image, pitch: float) -> void:
	if img == null:
		_failures.append("no picture at pitch %.0f" % pitch)
		return
	var w := img.get_width()
	var h := img.get_height()
	if w != PanoramaCapture.width_for(FACE) or h != w / 2:
		_failures.append("size should be %dx%d, got %dx%d" % [PanoramaCapture.width_for(FACE), PanoramaCapture.width_for(FACE) / 2, w, h])
		return
	# Looking along +X: right is +Z, behind is -X.
	var probes := {
		"ahead (+X) at the centre": [Vector2i(w / 2, h / 2), "+X"],
		"right (+Z) a quarter along": [Vector2i(w * 3 / 4, h / 2), "+Z"],
		"left (-Z) three quarters along": [Vector2i(w / 4, h / 2), "-Z"],
		"behind (-X) at the left edge": [Vector2i(4, h / 2), "-X"],
		"behind (-X) at the right edge": [Vector2i(w - 5, h / 2), "-X"],
		"up (+Y) at the top": [Vector2i(w / 2, 4), "+Y"],
		"down (-Y) at the bottom": [Vector2i(w / 2, h - 5), "-Y"],
	}
	for label in probes:
		var at: Vector2i = probes[label][0]
		var want: Color = WALLS[probes[label][1]][1]
		var got := img.get_pixelv(at)
		if not _near(got, want):
			_failures.append("pitch %.0f, %s: got %s, wanted %s (%s)" % [pitch, label, got, want, probes[label][1]])
	# Few pixels should be none of the six colours (wall edges only).
	var off := 0
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			var c := img.get_pixel(x, y)
			var known := false
			for key in WALLS:
				if _near(c, WALLS[key][1]):
					known = true
					break
			if not known:
				off += 1
	var sampled := (h / 4) * (w / 4)
	if off > sampled / 40:
		_failures.append("pitch %.0f: %d of %d sampled pixels are none of the wall colours (seams?)" % [pitch, off, sampled])
