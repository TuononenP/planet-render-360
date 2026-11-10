extends SceneTree

## Headless: godot --headless --script tests/ground_cover_test.gd
## GroundCover: colour rooted in the ground photo, cover that reaches on
## for a walk, chunks that carry their own range, and flowers kept rare.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()
	if failures.is_empty():
		print("GROUND COVER OK")
		quit(0)
	else:
		for f in failures:
			printerr("GROUND COVER FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

## A wide flat park around the viewpoint.
func _park(preset: int, half: float = 700.0) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, preset)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.latitude = 48.8566
	d.longitude = 2.3522
	d.land_polygons = [{"class": "grass", "points": PackedVector2Array([Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)]), "holes": []}]
	return d

func _plan(d: LocationData) -> Dictionary:
	var g := GroundTruth.new(d)
	return GroundCover.plan(d, g, VegetationMask.new(d, g))

func _run() -> void:
	failures.clear()
	var base := Color(0.26, 0.42, 0.11)
	_check(GroundCover.rooted(base, Color(0, 0, 0, 0)) == base, "no photo leaves the palette colour")
	var straw := GroundCover.rooted(base, Color(0.4, 0.3, 0.1, 1.0))
	_check(straw.r > base.r and straw.g < base.g, "cover takes its hue from a straw-coloured photo")
	var lum := func(c: Color) -> float: return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	_check(absf(float(lum.call(straw)) - float(lum.call(base))) < 0.02, "the photo sets the hue, not the brightness")
	_check(GroundCover.green_index(Color(0.1, 0.3, 0.05)) > GroundCover.PHOTO_GREEN, "lawn reads as green")
	_check(GroundCover.green_index(Color(0.3, 0.28, 0.25)) < GroundCover.PHOTO_GREEN, "bare earth does not")
	_check(GroundCover.photo_green(Color(0.1, 0.3, 0.05, 1.0)), "bright green photo ground grows cover")
	_check(not GroundCover.photo_green(Color(0.03, 0.05, 0.02, 1.0)), "dark ground never does, whatever its index")
	_check(not GroundCover.photo_green(Color(0.1, 0.3, 0.05, 0.0)), "no photo, no cover")
	var fast := _plan(_park(RenderSettings.Preset.FAST))
	_check(fast.is_empty(), "Fast lays no cover")
	var d := _park(RenderSettings.Preset.ULTRA)
	var placed := _plan(d)
	var centre := View360.spawn_xz(d)
	var far_out := 0
	var total := 0
	for kind: String in placed:
		for e: Array in placed[kind]:
			var o: Vector3 = e[0]
			var r := Vector2(o.x - centre.x, o.z - centre.y).length()
			total += 1
			far_out += 1 if r > 300.0 else 0
	_check(far_out > 500, "cover reaches on for a walk 300 m out: %d" % far_out)
	var flowers := float((placed["flower"] as Array).size())
	_check(flowers / float(total) < 0.06, "flowers stay rare on a lawn: %.3f" % (flowers / float(total)))
	# Chunks carry their own range past LodRing, and no more than a grid's worth.
	var g := GroundTruth.new(d)
	var root := Node3D.new()
	var built := GroundCover.build(root, d, g, VegetationMask.new(d, g))
	_check(built == total, "every placement is built: %d of %d" % [built, total])
	_check(root.get_child_count() > 3, "cover is split into chunks: %d" % root.get_child_count())
	var ok := true
	for c in root.get_children():
		var mmi := c as MultiMeshInstance3D
		ok = ok and mmi != null and str(mmi.get_meta("lod_layer", "")) == "GroundCover" and float(mmi.get_meta("cover_end", 0.0)) > 0.0
	_check(ok, "each chunk is on the GroundCover layer with its own range")
	var first := root.get_child(0) as GeometryInstance3D
	LodRing.apply(root, RenderSettings.Preset.ULTRA)
	_check(is_equal_approx(first.visibility_range_end, float(first.get_meta("cover_end"))), "LodRing keeps the chunk's own range")
	root.free()
	# Photo-green ground grows cover with no mapped polygon; bare ground none.
	var wild := _park(RenderSettings.Preset.ULTRA)
	wild.land_polygons = []
	_check(_plan(wild).is_empty(), "no polygon and no photo lays nothing")
