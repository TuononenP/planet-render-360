extends SceneTree

## Headless: godot --headless --script tests/panorama_test.gd
## The parts of the 360° photo that need no window: the file name, the
## GPano metadata, the JPEG with that metadata inserted (still a valid
## JPEG, JFIF header first), and the geometry of the six faces. The
## rendering itself is checked by tests/panorama_render_test.gd.

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame  # cameras added to the root are in the tree from here
	_test_names()
	_test_xmp()
	_test_jpeg()
	_test_geometry()
	_test_heading()
	_test_extensions()
	_test_settle()
	_test_save()
	await _test_encode_async()
	if _failures.is_empty():
		print("PANORAMA OK: file name, GPano metadata, JPEG insertion, face geometry")
		quit(0)
	else:
		for f in _failures:
			printerr("PANORAMA FAIL: ", f)
		quit(1)

func _test_names() -> void:
	var when := {"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 30}
	if PanoramaCapture.file_name("Paris, France", when) != "planet-render-360_paris-france_360_20261101-1730.jpg":
		_failures.append("file name: %s" % PanoramaCapture.file_name("Paris, France", when))
	if PanoramaCapture.file_name("", when) != "planet-render-360_view_360_20261101-1730.jpg":
		_failures.append("file name without a place: %s" % PanoramaCapture.file_name("", when))
	if PanoramaCapture.width_for(1024) != 4096 or PanoramaCapture.face_px() < 512:
		_failures.append("size should be four faces wide")

func _test_xmp() -> void:
	var x := PanoramaCapture.xmp(4096, 2048, -90.0)
	for needle in ["<GPano:ProjectionType>equirectangular</GPano:ProjectionType>",
			"<GPano:UsePanoramaViewer>True</GPano:UsePanoramaViewer>",
			"<GPano:FullPanoWidthPixels>4096</GPano:FullPanoWidthPixels>",
			"<GPano:FullPanoHeightPixels>2048</GPano:FullPanoHeightPixels>",
			"<GPano:CroppedAreaImageWidthPixels>4096</GPano:CroppedAreaImageWidthPixels>",
			"<GPano:PoseHeadingDegrees>270.0</GPano:PoseHeadingDegrees>",
			"xmlns:GPano=\"http://ns.google.com/photos/1.0/panorama/\""]:
		if not x.contains(needle):
			_failures.append("XMP lacks %s" % needle)
	var parser := XMLParser.new()
	if parser.open_buffer(x.replace("<?xpacket begin=\"﻿\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>", "").replace("<?xpacket end=\"w\"?>", "").to_utf8_buffer()) != OK:
		_failures.append("XMP did not open as XML")
	var elements := 0
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			elements += 1
	if elements < 10:
		_failures.append("XMP should parse as XML with its elements, got %d" % elements)

func _test_jpeg() -> void:
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	img.fill(Color(0.2, 0.5, 0.8))
	var plain := img.save_jpg_to_buffer(0.9)
	var packet := PanoramaCapture.xmp(64, 32, 10.0)
	var tagged := PanoramaCapture.with_xmp(plain, packet)
	if tagged.size() <= plain.size() or tagged[0] != 0xFF or tagged[1] != 0xD8:
		_failures.append("the tagged JPEG should be larger and still start with SOI")
		return
	# Segment order: SOI, (JFIF APP0), APP1 with the XMP header.
	var at := 2
	if plain[2] == 0xFF and plain[3] == 0xE0:
		if tagged.slice(0, 4 + (plain[4] << 8 | plain[5])) != plain.slice(0, 4 + (plain[4] << 8 | plain[5])):
			_failures.append("the JFIF segment should stay first and unchanged")
		at = 4 + (plain[4] << 8 | plain[5])
	if tagged[at] != 0xFF or tagged[at + 1] != 0xE1:
		_failures.append("an APP1 segment should follow, got %02x %02x" % [tagged[at], tagged[at + 1]])
	var length: int = tagged[at + 2] << 8 | tagged[at + 3]
	var header := PanoramaCapture.xmp_header()
	# Spelled out here, not taken from the code under test: the namespace,
	# then one NUL byte, which XMP readers require.
	var spelled := "http://ns.adobe.com/xap/1.0/".to_ascii_buffer()
	spelled.append(0)
	if header != spelled or header.size() != 29 or header[28] != 0:
		_failures.append("the XMP header should be the namespace and a NUL byte, got %s" % [header])
	if tagged.slice(at + 4, at + 4 + spelled.size()) != spelled:
		_failures.append("the APP1 segment should start with the XMP namespace and its NUL")
	if tagged[at + 4 + 28] != 0:
		_failures.append("the byte after the namespace should be 0, got %d" % tagged[at + 4 + 28])
	if at + 2 + length > tagged.size() or tagged.slice(at + 2 + length) != plain.slice(at):
		_failures.append("the rest of the JPEG should follow the segment untouched")
	if tagged.slice(at + 4 + header.size(), at + 2 + length).get_string_from_utf8() != packet:
		_failures.append("the packet should be stored whole")
	var back := Image.new()
	if back.load_jpg_from_buffer(tagged) != OK or back.get_size() != Vector2i(64, 32):
		_failures.append("the tagged JPEG should still decode at its size")
	# Not a JPEG, and a packet too large for a segment: returned unchanged.
	var junk := PackedByteArray([1, 2, 3, 4, 5])
	if PanoramaCapture.with_xmp(junk, packet) != junk:
		_failures.append("bytes that are not a JPEG should be returned as they are")
	if PanoramaCapture.with_xmp(plain, "x".repeat(70000)) != plain:
		_failures.append("a packet too big for one segment should be left out")

func _test_encode_async() -> void:
	# Encoding a full-size panorama must not block the main thread (on
	# macOS a block of a second or more shows the beachball): frames keep
	# being processed while it runs, and the bytes match encode().
	var img := Image.create(1024, 512, false, Image.FORMAT_RGB8)
	for i in 32:
		img.fill_rect(Rect2i(i * 32, 0, 32, 512), Color(float(i % 8) / 7.0, float(i / 8) / 3.0, float(i % 5) / 4.0))
	var frames := [0]
	var on_frame := func() -> void: frames[0] += 1
	process_frame.connect(on_frame)
	var bytes: PackedByteArray = await PanoramaCapture.encode_async(img, 10.0, self)
	process_frame.disconnect(on_frame)
	if frames[0] < 1:
		_failures.append("encode_async should let frames run while it encodes")
	if bytes != PanoramaCapture.encode(img, 10.0):
		_failures.append("encode_async should return the same bytes as encode")
	var back := Image.new()
	if back.load_jpg_from_buffer(bytes) != OK or back.get_size() != Vector2i(1024, 512):
		_failures.append("encode_async bytes should decode at the image size")

func _test_heading() -> void:
	# Compass heading of the centre, 0 north (-Z), clockwise: the same as
	# the rig's yaw negated, whatever the camera's pitch.
	for row in [[Vector3(0, 0, -1), 0.0], [Vector3(1, 0, 0), 90.0], [Vector3(0, 0, 1), 180.0],
			[Vector3(-1, 0, 0), 270.0], [Vector3(1, 0, -1), 45.0], [Vector3(1, 3, 0), 90.0]]:
		var cam := Camera3D.new()
		root.add_child(cam)  # global_transform needs the tree
		cam.transform = Transform3D(Basis.looking_at(row[0], Vector3.UP), Vector3.ZERO)
		var got := PanoramaCapture.heading_deg(cam)
		if absf(angle_difference(deg_to_rad(got), deg_to_rad(row[1]))) > 1e-4:
			_failures.append("looking %s should face heading %.0f, got %.2f" % [row[0], row[1], got])
		cam.free()
	for yaw in [0.0, 0.7, -1.9, 3.0]:
		var turned := Camera3D.new()
		root.add_child(turned)
		turned.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO)
		var want := fposmod(-rad_to_deg(yaw), 360.0)
		if absf(angle_difference(deg_to_rad(PanoramaCapture.heading_deg(turned)), deg_to_rad(want))) > 1e-4:
			_failures.append("a view yaw of %.1f rad should give heading %.2f, got %.2f" % [yaw, want, PanoramaCapture.heading_deg(turned)])
		turned.free()

func _test_settle() -> void:
	# Lighting that builds up over many frames (SDFGI) needs a long first
	# settle; everything else, and every turn, a short one.
	var ultra := RenderSettings.Preset.ULTRA
	var long := PanoramaCapture.first_settle_frames(ultra, true)
	if long != PanoramaCapture.GI_SETTLE_FRAMES:
		_failures.append("Ultra on Forward+ should settle for %d frames, got %d" % [PanoramaCapture.GI_SETTLE_FRAMES, long])
	for row in [[ultra, false], [RenderSettings.Preset.HIGH, true], [RenderSettings.Preset.BALANCED, true],
			[RenderSettings.Preset.FAST, false]]:
		if PanoramaCapture.first_settle_frames(row[0], row[1]) != PanoramaCapture.BASIC_SETTLE_FRAMES:
			_failures.append("preset %d (Forward+ %s) has no SDFGI, so a short settle" % [row[0], str(row[1])])
	if not (PanoramaCapture.TURN_SETTLE_FRAMES < PanoramaCapture.BASIC_SETTLE_FRAMES
			and PanoramaCapture.BASIC_SETTLE_FRAMES < PanoramaCapture.GI_SETTLE_FRAMES):
		_failures.append("settle lengths should grow from a turn to a first face to a first face with GI")

func _test_extensions() -> void:
	if PhotoMode.accepted_extensions("jpg") != ["jpg", "jpeg"] or PhotoMode.accepted_extensions("png") != ["png"]:
		_failures.append("a typed .jpeg should be accepted for a JPEG, and only .png for a PNG")

func _test_save() -> void:
	var dir := "user://panorama-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	var bytes := PackedByteArray([0xFF, 0xD8, 1, 2, 3, 0xFF, 0xD9])
	var saved: Array = []
	var done := func(path: String, failed: bool) -> void: saved.append([path, failed])
	var target := dir.path_join("pano.jpg")
	PhotoMode._report(func(p: String) -> bool: return PhotoMode._write_bytes(bytes, p), target, done)
	if saved != [[target, false]] or FileAccess.get_file_as_bytes(target) != bytes:
		_failures.append("bytes should be written whole and reported with their path: %s" % [saved])
	saved.clear()
	PhotoMode._report(func(p: String) -> bool: return PhotoMode._write_bytes(bytes, p),
		"/nonexistent-dir-pr360/pano.jpg", done)
	if saved != [["", true]]:
		_failures.append("a failed byte write should be reported as a failure: %s" % [saved])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))

func _test_geometry() -> void:
	# A look straight down falls back to a defined heading.
	var down := PanoramaCapture.horizontal_basis(Vector3.DOWN)
	if not (down[0] as Vector3).is_equal_approx(Vector3(0, 0, -1)):
		_failures.append("a vertical look should fall back to -Z, got %s" % down[0])
	for look in [Vector3(0, 0, -1), Vector3(1, 0.3, 0), Vector3(-1, -0.5, 2), Vector3(0.2, 0.9, 0.1)]:
		var hb := PanoramaCapture.horizontal_basis(look)
		var f0: Vector3 = hb[0]
		var r0: Vector3 = hb[1]
		if absf(f0.y) > 1e-6 or absf(f0.length() - 1.0) > 1e-5 or absf(r0.dot(f0)) > 1e-5:
			_failures.append("horizontal basis not horizontal/orthonormal for %s" % look)
		var faces := PanoramaCapture.face_bases(f0, r0)
		if faces.size() != 6:
			_failures.append("six faces expected")
			continue
		for b in faces:
			var fwd: Vector3 = b[0]
			var rgt: Vector3 = b[1]
			var upv: Vector3 = b[2]
			if absf(fwd.dot(rgt)) > 1e-5 or absf(fwd.dot(upv)) > 1e-5 or absf(rgt.dot(upv)) > 1e-5:
				_failures.append("face basis not orthogonal for look %s" % look)
			if not rgt.is_equal_approx(fwd.cross(upv)):
				_failures.append("face basis not right-handed (right = forward x up) for look %s" % look)
		# Every direction belongs to a face whose axis is within 54.8 degrees.
		for d in [Vector3(1, 1, 1), Vector3(-1, 0.2, 0.7), Vector3(0.3, -1, -0.2), Vector3(0, 0, 1)]:
			var best := -2.0
			for b in faces:
				best = maxf(best, d.normalized().dot(b[0]))
			if best < 0.577:
				_failures.append("direction %s is far from every face (cos %.3f)" % [d, best])
	# Neighbouring faces must overlap, and be rendered wide enough to cover it.
	if not (PanoramaCapture.BLEND_IN < 1.0 and PanoramaCapture.BLEND_OUT > 1.0):
		_failures.append("the cross-fade must straddle the 90 degree face edge (tan = 1)")
	for face in [256, 1024, 2048]:
		if PanoramaCapture.reach_for(face) <= PanoramaCapture.BLEND_OUT:
			_failures.append("a %d px face must reach past the end of the cross-fade" % face)
		if PanoramaCapture.fov_for(face) <= 95.0 or PanoramaCapture.fov_for(face) >= 120.0:
			_failures.append("face field of view looks wrong: %.1f" % PanoramaCapture.fov_for(face))
	for face in [256, 1024, 2048]:
		var t := tan(deg_to_rad(PanoramaCapture.fov_for(face)) / 2.0) * PanoramaCapture.shrink_for(face)
		if absf(t - 1.0) > 1e-9:
			_failures.append("fov and shrink disagree for %d px faces: %f" % [face, t])
