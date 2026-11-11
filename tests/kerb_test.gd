extends SceneTree

## Headless: godot --headless --script tests/kerb_test.gd
## Raised kerbs (KerbBuilder, desktop Ultra): both edges of an urban
## street, cut short of the junction, the vertical face looking at the
## carriageway, granite in Europe and concrete in North America, none
## off Ultra.

func _init() -> void:
	_run()

func _data(preset: int) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, preset)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.latitude = 48.8566
	d.longitude = 2.3522
	d.land_polygons = [{"class": "urban", "points": PackedVector2Array([Vector2(-400, -400),
		Vector2(400, -400), Vector2(400, 400), Vector2(-400, 400)]), "holes": []}]
	d.roads = [
		{"class": "residential", "width_m": 8.0, "points": PackedVector2Array([Vector2(-100, 0), Vector2(0, 0), Vector2(100, 0)])},
		{"class": "residential", "width_m": 8.0, "points": PackedVector2Array([Vector2(0, -100), Vector2(0, 0), Vector2(0, 100)])},
	]
	return d

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	var d := _data(RenderSettings.Preset.ULTRA)
	var ground := GroundTruth.new(d)
	var root := Node3D.new()
	var metres := KerbBuilder.build(root, d, ground)
	if not RenderQuality.ultra_desktop(d.quality_preset):
		print("KERB SKIP: no Forward+ here")
		root.free()
		quit(0)
		return
	# Two 200 m streets, two kerbs each, less ~2 × CUT_M at the crossing.
	if metres < 650.0 or metres > 800.0:
		failures.append("kerb length %.0f m, want ~730" % metres)
	var mi := root.get_node("Kerbs") as MeshInstance3D
	var arr := mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var near_junction := 0
	var faces_ok := 0
	var faces := 0
	for i in v.size():
		var p := Vector2(v[i].x, v[i].z) / m
		if p.length() < KerbBuilder.CUT_M - 0.5:
			near_junction += 1
		# Face vertices of the east-west street's kerbs (|z| ≈ 3.75 m).
		if absf(p.x) > 20.0 and absf(absf(p.y) - 3.75) < 0.01 and absf(nrm[i].y) < 0.3:
			faces += 1
			if signf(nrm[i].z) == -signf(p.y):
				faces_ok += 1
	if near_junction > 0:
		failures.append("%d kerb vertices inside the junction cut" % near_junction)
	if faces == 0 or faces_ok < faces * 0.9:
		failures.append("kerb faces should look at the carriageway (%d of %d)" % [faces_ok, faces])
	var us := _data(RenderSettings.Preset.ULTRA)
	us.country = "US"
	if KerbBuilder.stone_for(us) != KerbBuilder.CONCRETE or KerbBuilder.stone_for(d) != KerbBuilder.GRANITE:
		failures.append("concrete kerbs in North America, granite in Europe")
	var flush := _data(RenderSettings.Preset.ULTRA)
	for r: Dictionary in flush.roads:
		r["class"] = "pedestrian"
	var flush_root := Node3D.new()
	if KerbBuilder.build(flush_root, flush, GroundTruth.new(flush)) != 0.0:
		failures.append("pedestrian streets are paved flush, no kerb")
	flush_root.free()
	var high := Node3D.new()
	if KerbBuilder.build(high, _data(RenderSettings.Preset.HIGH), ground) != 0.0:
		failures.append("raised kerbs are desktop Ultra only")
	root.free()
	high.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("KERB OK: both edges, cut at junctions, faces to the road, regional stone, Ultra only")
		quit(0)
	else:
		for f in failures:
			printerr("KERB FAIL: ", f)
		quit(1)
