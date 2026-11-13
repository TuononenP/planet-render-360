extends SceneTree

## DemRelief (offline): godot --headless --script tests/dem_relief_test.gd
## A ramp the mesh already shows bakes flat; a 5 m mound between posts
## bakes slopes of the right sign; sea cells stay flat; the window maps
## onto the local frame.

const N := DemRelief.CELLS

var failures: Array[String] = []

func _init() -> void:
	_ramp()
	_mound()
	_sea()
	_rect()
	if failures.is_empty():
		print("DEM RELIEF OK: ramp flat, mound slopes, sea flat, window rect")
		quit(0)
	else:
		for f in failures:
			printerr("DEM RELIEF FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _raster(values: PackedFloat32Array) -> Dictionary:
	return {"size": Vector2i(N, N), "values": values, "origin": Vector2.ZERO, "cell": Vector2(2.5, 2.5)}

func _at(img: Image, i: int, j: int) -> Vector2i:
	var c := img.get_pixel(i, j)
	return Vector2i(int(roundf(c.r * 255.0)), int(roundf(c.g * 255.0)))

func _ramp() -> void:
	var v := PackedFloat32Array()
	v.resize(N * N)
	for j in N:
		for i in N:
			v[j * N + i] = 10.0 + float(i) * 0.25 + float(j) * 0.1
	var img := DemRelief.bake(_raster(v))
	_check(img != null and img.get_format() == Image.FORMAT_RG8, "A ramp bakes to RG8")
	if img == null:
		return
	var worst := 0
	for p in [Vector2i(100, 100), Vector2i(256, 300), Vector2i(400, 200)]:
		var s := _at(img, p.x, p.y)
		worst = maxi(worst, maxi(absi(s.x - 128), absi(s.y - 128)))
	_check(worst <= 2, "A ramp the mesh already carries must bake flat (off by %d)" % worst)

func _mound() -> void:
	var v := PackedFloat32Array()
	v.resize(N * N)
	var c := Vector2(256.0, 256.0)
	for j in N:
		for i in N:
			var d2 := Vector2(i, j).distance_squared_to(c)
			v[j * N + i] = 20.0 + 1.5 * exp(-d2 / 4.0)  # ~5 m wide, 1.5 m tall
	var img := DemRelief.bake(_raster(v))
	if img == null:
		_check(false, "A mound bakes")
		return
	_check(_at(img, 254, 256).x > 140 and _at(img, 258, 256).x < 116,
		"Rising west of the top, falling east of it (dh/dx)")
	_check(_at(img, 256, 254).y > 140 and _at(img, 256, 258).y < 116,
		"Rising north of the top, falling south of it (dh/dz, z south)")

func _sea() -> void:
	var v := PackedFloat32Array()
	v.resize(N * N)
	for j in N:
		for i in N:
			v[j * N + i] = HelsinkiDem.NODATA if i < 200 else 3.0
	var img := DemRelief.bake(_raster(v))
	_check(img != null and _at(img, 200, 256) == Vector2i(128, 128) and _at(img, 199, 256) == Vector2i(128, 128),
		"Cells touching the sea stay flat")
	for j in N:
		for i in N:
			v[j * N + i] = HelsinkiDem.NODATA if i < 400 else 3.0
	_check(DemRelief.bake(_raster(v)) == null, "A window mostly without data bakes nothing")

func _rect() -> void:
	var r := DemRelief.rect(60.1680, 24.9530)
	var m := WorldScale.metres_to_units()
	_check(Vector2(r.x, r.y).length() < 1.5 * m, "The whole-metre window centre lies within a metre of the viewpoint")
	# WorldScale's flat degrees (110 540 m of latitude) run ~1 % short of
	# GK25 metres at 60°N: the rect carries that, within 1.5 %.
	_check(absf(r.z / m / DemRelief.HALF_M - 1.0) < 0.015 and absf(r.w / m / DemRelief.HALF_M - 1.0) < 0.015,
		"The window's half sizes are HALF_M in the local frame (%.1f, %.1f)" % [r.z / m, r.w / m])
