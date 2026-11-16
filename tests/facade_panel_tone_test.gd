extends SceneTree

## Headless: godot --headless --script tests/facade_panel_tone_test.gd
## The "panel" pattern varies each bay's tone a few per cent. On a dark wall
## (brick) that step must stay a few per cent of the wall's own brightness:
## a fixed blend toward white turned half the bays of a brick front pale
## pink beside red ones. Every bay of every variant stays within 1.2x of
## the dimmest, for dark brick and for pale render alike.

func _init() -> void:
	var failures: Array[String] = []
	MaterialLibrary.hi_res = false
	for set_name in ["brick", "concrete", "render"]:
		for variant in 6:
			var look := {"frame": Color(0.85, 0.83, 0.78), "window": "casement", "variant": variant}
			var d := FacadeComposer.compose_tile(set_name, "panel", 1, look, Callable(MaterialLibrary, "_set_image"))
			var img := (d["albedo"] as Texture2D).get_image()
			var lo := INF
			var hi := 0.0
			for bay in FacadeComposer.BAYS:
				var l := _luma(img, Rect2i(bay * FacadeComposer.CELL, 0, FacadeComposer.CELL, FacadeComposer.CELL))
				lo = minf(lo, l)
				hi = maxf(hi, l)
			if hi > lo * 1.2:
				failures.append("%s variant %d: brightest bay %.3f vs dimmest %.3f" % [set_name, variant, hi, lo])
	if failures.is_empty():
		print("FACADE PANEL TONE OK: bays of a panel facade stay within 1.2x in brightness, brick included")
		quit(0)
	else:
		for f in failures:
			printerr("FACADE PANEL TONE FAIL: ", f)
		quit(1)

func _luma(img: Image, r: Rect2i) -> float:
	var sum := 0.0
	for j in 8:
		for i in 8:
			var c := img.get_pixel(r.position.x + (i * r.size.x) / 8, r.position.y + (j * r.size.y) / 8)
			sum += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	return sum / 64.0
