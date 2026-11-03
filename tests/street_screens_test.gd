extends SceneTree

## Headless: godot --headless --script tests/street_screens_test.gd
## Big screens (StreetFront._screen, desktop Ultra): a tall street front in
## a `screens` style gets one poster panel above the third storey, drawn
## from the poster atlas; no flag, no style key, a short front or a narrow
## one gets none; the atlas is 1024² with eight distinct tiles.

func _init() -> void:
	var failures: Array[String] = []
	var m := WorldScale.metres_to_units()
	var with := _count(true, 1.0, 8, 30.0)
	if with != 1:
		failures.append("a tall front with screens on should get one panel, got %d" % with)
	if _count(false, 1.0, 8, 30.0) != 0:
		failures.append("no screens off Ultra")
	if _count(true, 0.0, 8, 30.0) != 0:
		failures.append("no screens without the style key")
	if _count(true, 1.0, 4, 30.0) != 0:
		failures.append("a 4-storey front is too short for a screen")
	if _count(true, 1.0, 8, 8.0) != 0:
		failures.append("an 8 m front is too narrow for a screen")
	var img := (ReliefKit.screen() as StandardMaterial3D).albedo_texture.get_image()
	if img.get_width() != 1024 or img.get_height() != 1024:
		failures.append("the poster atlas should be 1024², got %s" % img.get_size())
	else:
		var means := []
		for tile in ReliefKit.SCREEN_TILES:
			var c := img.get_region(Rect2i((tile % 2) * 512 + 8, (tile / 2) * 256 + 8, 496, 240)).get_pixel(30, 30)
			means.append(c.to_html(false))
		var distinct := {}
		for c in means:
			distinct[c] = true
		if distinct.size() < 6:
			failures.append("the eight posters should differ: %s" % [means])
	if failures.is_empty():
		print("STREET SCREENS OK: one panel on a tall front on Ultra, none off it / short / narrow / unstyled; 8-tile atlas")
		quit(0)
	else:
		for f in failures:
			printerr("STREET SCREENS FAIL: ", f)
		quit(1)

## Number of screen quads drawn on one `len_m`-long front of `storeys` storeys.
func _count(flag: bool, share: float, storeys: int, len_m: float) -> int:
	var m := WorldScale.metres_to_units()
	var sp := {"a": Vector2(0, -10) * m, "b": Vector2(len_m, -10) * m, "n": Vector2(0, -1),
		"dir": Vector2(1, 0), "len_m": len_m, "street": true, "bays": 6}
	var rows := []
	for i in storeys:
		rows.append({"y0": float(i) * 3.5 * m, "y1": float(i + 1) * 3.5 * m, "storey": i, "ground": i == 0})
	var look := {"ground": "signage", "relief": {"screens": share}, "pattern": "punched"}
	var kit := ReliefKit.new()
	StreetFront.add(kit, [sp], rows, {"look": look, "seed": 0.3, "b": {}, "ground_y": 0.0,
		"screens": flag}, null)
	var root := Node3D.new()
	kit.flush(root, "R")
	var n := 0
	for mi in root.get_children():
		if mi is MeshInstance3D:
			for s in (mi as MeshInstance3D).mesh.get_surface_count():
				if (mi as MeshInstance3D).mesh.surface_get_material(s) == ReliefKit.screen():
					n += (mi as MeshInstance3D).mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size() / 4
	root.free()
	return n
