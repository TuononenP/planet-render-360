extends SceneTree

## Headless: large-ship paint is shared per colour and length, safe to
## build from worker threads, and its textures put seams, grime and rust
## where the hull UVs say; liners lose the yacht gelcoat while yachts keep it.
var failures: Array[String] = []
var _threaded: Array = []

func _init() -> void:
	MaterialLibrary.hi_res = true
	var navy := Color("#1c2a43")
	var a := ShipPaint.hull(navy, 250.0, 10.0)
	_check(a == ShipPaint.hull(navy, 250.0, 10.0), "same hull arguments must share one material")
	_check(a != ShipPaint.hull(Color("#e9e8e2"), 250.0, 10.0), "hull colours must not share a material")
	_check(a.albedo_texture == ShipPaint.hull(Color("#e9e8e2"), 252.0, 10.0).albedo_texture,
		"one hull texture must serve every colour of a length bucket")
	_check(a.detail_enabled and a.detail_albedo != null and a.normal_texture != null, "hull needs weathering and plating maps")
	_check(not ShipPaint.enamel(Color("#ebe9e2")).clearcoat_enabled, "ship enamel must not be gelcoat")
	_check(RoofVariety.is_roof(ShipPaint.enamel(Color("#ebe9e2"))), "snow must still settle on enamel decks")
	# Four threads asking at once get the winner's material.
	var threads: Array[Thread] = []
	for i in 4:
		var t := Thread.new()
		t.start(func() -> void: _threaded.append(ShipPaint.hull(Color("#6f2c26"), 180.0, 8.0)))
		threads.append(t)
	for t in threads:
		t.wait_to_finish()
	for m in _threaded:
		_check(m == _threaded[0] and m == ShipPaint.hull(Color("#6f2c26"), 180.0, 8.0), "threaded builds must share one material")
	_textures()
	_models()
	if failures.is_empty():
		print("SHIP PAINT OK: shared, threaded, seams, grime, rust, liners matte, yachts gelcoat")
		quit(0)
	else:
		for f in failures:
			printerr("SHIP PAINT FAIL: ", f)
		quit(1)

func _textures() -> void:
	var texs := ShipPaint.textures(200.0, 10.0, true)
	var albedo: Image = (texs["albedo"] as Texture2D).get_image()
	var detail: Image = (texs["detail"] as Texture2D).get_image()
	# Seam rows are darker than the mid-plate rows 1.25 m below them.
	var darker := 0
	var seams := 0
	var py_m := float(ShipPaint.TEX_H) / (ShipPaint.TOP_M + ShipPaint.BELOW_M)
	for y in ShipPaint.TEX_H - 20:
		var m := ShipPaint.TOP_M - float(y) / py_m
		if floori((m - 1.0 / py_m) / ShipPaint.PLATE_M) == floori(m / ShipPaint.PLATE_M):
			continue
		seams += 1
		var below := y + int(ShipPaint.PLATE_M * 0.5 * py_m)
		for x in range(7, ShipPaint.TEX_W, 97):
			if albedo.get_pixel(x, y).r < albedo.get_pixel(x, below).r - 0.03:
				darker += 1
	_check(seams >= 8 and darker > seams * 15, "plate seams must darken the albedo at strake lines (%d / %d)" % [darker, seams])
	var water := ShipPaint._row(0.0)
	var high := ShipPaint._row(6.0)
	var grime := 0.0
	var clean := 0.0
	for c in range(0, ShipPaint.TEX_W, 16):
		grime += detail.get_pixel(c, water).a
		clean += detail.get_pixel(c, high).a
	_check(grime > clean * 3.0 + 1.0, "waterline grime must sit at the waterline")
	var hawse := ShipPaint._col(0.43 * 200.0, 200.0)
	var rust := 0.0
	for y in range(ShipPaint._row(8.0), ShipPaint._row(5.0)):
		for dx in range(-2, 3):
			var p := detail.get_pixel(hawse + dx, y)
			if p.a > 0.1 and p.r > p.b * 1.5:
				rust += 1.0
	_check(rust > 3.0, "rust must weep below the hawse pipe")

func _models() -> void:
	var hull := VesselMaterials.paint("#2d3b4a")
	var liner := VesselPrototypes.geometry("liner", 250.0, 31.0, 50.0, hull, true, true, 0.9)
	var root := Node3D.new()
	for part in liner.commit(root):
		var m := part.mesh.surface_get_material(0)
		if part.name == "White":
			_check(m is StandardMaterial3D and not (m as StandardMaterial3D).clearcoat_enabled, "liner white must be matte enamel")
		if part.name == "Hull":
			_check(m is StandardMaterial3D and (m as StandardMaterial3D).detail_enabled, "liner hull must be weathered steel")
			_check(is_equal_approx((m as StandardMaterial3D).albedo_color.r, hull.albedo_color.r), "liner hull keeps its painted colour")
	root.free()
	_check(VesselMaterials.get_mat("white").clearcoat_enabled, "yacht gelcoat must keep its clearcoat")

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
