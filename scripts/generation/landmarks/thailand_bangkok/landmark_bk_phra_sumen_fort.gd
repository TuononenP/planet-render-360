class_name LandmarkBkPhraSumenFort
extends RefCounted

## Phra Sumen Fort (`ป้อมพระสุเมรุ`) — Santichaiprakarn Park, Bangkok BK-5.3
## Site: OSM way 107936513, centroid 13.763998, 100.495730 (`height_m: 24.5`, `yaw_deg: 47.0`).
## Spec (King Rama I 1783 river-corner octagonal fort, restored 1981, Commons `front.jpg`):
##   - Outer octagonal glacis & low cannon battery (`R = 22.5 m`, `2.8 m` wall + thick bevelled
##     whitewashed gun merlons & black cast-iron cannons, `front.jpg` foreground).
##   - Main battered whitewashed octagonal masonry bastion (`R = 16.5 m` -> `15.4 m`, `11.6 m`
##     parapet) with arched casemate embrasures and pointed-lotus battlements (`K2.fort_tier`).
##   - Crowning 2-storey octagonal whitewashed watchtower (`R = 6.2 m`, `11.6..20.2 m`) with
##     square lower windows, triple-arched upper gallery, terracotta hipped octagonal roof, and
##     gilded finial reaching `24.5 m`.

const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 24.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F4EFEA", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E4DDD4", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B84C2C", 2.2))
	lm.use("BrickWalk", LandmarkMaterials.pbr("terracotta", "#A85D3B", 3.5))
	lm.use("Dark", LandmarkMaterials.paint("#221F1E", 0.88, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())

	_outer_cannon_battery(lm)
	_main_octagonal_bastion(lm)
	_watchtower_pavilion(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-26.0, 1.6, 26.0), Vector3(0.0, 14.0, 0.0), 50.0, 1.30, 44.0, Color(1.0, 0.92, 0.74)],
		[Vector3(26.0, 1.6, -26.0), Vector3(0.0, 14.0, 0.0), 50.0, 1.25, 44.0, Color(1.0, 0.92, 0.74)],
	])

static func _outer_cannon_battery(lm: LandmarkMesh) -> void:
	# Brick-paved perimeter apron + low octagonal battery (`R = 22.2 m`) with thick bevelled cannon merlons
	var rot := PI / 8.0
	lm.lathe("BrickWalk", Vector3.ZERO, PackedVector2Array([
		Vector2(24.6, 0.0), Vector2(24.6, 0.14), Vector2(0.0, 0.14)]), 8, 1.0, 1.0, rot, false)
	lm.lathe("Wall", Vector3(0, 0.14, 0), PackedVector2Array([
		Vector2(22.2, 0.0), Vector2(21.8, 2.3), Vector2(22.3, 2.55), Vector2(0.0, 2.55)]), 8, 1.0, 1.0, rot, false)
	var apothem := 21.8 * cos(rot)
	var edge := 2.0 * 21.8 * sin(rot)
	for s in 8:
		var a := rot + TAU * (float(s) + 0.5) / 8.0
		var fb := Basis(Vector3.UP, PI * 0.5 - a)
		for m in 4:
			var u := -edge * 0.38 + edge * 0.76 * float(m) / 3.0
			lm.box("Wall", fb * Vector3(u, 3.35, apothem - 0.55), Vector3(2.4, 1.35, 1.15), fb)
			lm.box("Trim", fb * Vector3(u, 4.08, apothem - 0.55), Vector3(2.55, 0.18, 1.28), fb)
		for c in [-0.25, 0.25]:
			var cp := fb * Vector3(c * edge, 2.95, apothem - 0.5)
			lm.beam("Dark", cp + fb * Vector3(0, 0, -0.5), cp + fb * Vector3(0, 0.08, 0.85), 0.34, 0.34, fb.x)

static func _main_octagonal_bastion(lm: LandmarkMesh) -> void:
	# Battered main octagonal fort (`y = 2.55..11.6 m`) with arched casemates & pointed-lotus battlements
	K2.fort_tier(lm, "Wall", "Dark", Vector3(0, 2.55, 0), 16.4, 15.2, 9.05, 8, true, true)
	lm.lathe("Trim", Vector3(0, 8.8, 0), PackedVector2Array([
		Vector2(15.65, 0.0), Vector2(15.65, 0.38)]), 8, 1.0, 1.0, PI / 8.0, false)

static func _watchtower_pavilion(lm: LandmarkMesh) -> void:
	# Two-storey octagonal watchtower (`R = 6.2 m`, `y = 11.6..20.1 m`) + terracotta roof (`20.1..24.5 m`)
	var rot := PI / 8.0
	var y0 := 11.6
	lm.lathe("Wall", Vector3(0, y0, 0), PackedVector2Array([
		Vector2(6.3, 0.0), Vector2(6.1, 8.5)]), 8, 1.0, 1.0, rot, false)
	lm.lathe("Trim", Vector3(0, y0 + 8.3, 0), PackedVector2Array([
		Vector2(6.55, 0.0), Vector2(6.55, 0.4)]), 8, 1.0, 1.0, rot, false)
	var apothem := 6.15 * cos(rot)
	for s in 8:
		var a := rot + TAU * (float(s) + 0.5) / 8.0
		var fb := Basis(Vector3.UP, PI * 0.5 - a)
		lm.box("Dark", fb * Vector3(0, y0 + 3.2, apothem + 0.02), Vector3(1.3, 2.1, 0.12), fb, 0.0)
		for u in [-1.35, 0.0, 1.35]:
			lm.box("Dark", fb * Vector3(u, y0 + 6.6, apothem + 0.02), Vector3(0.82, 1.45, 0.12), fb, 0.0)
	lm.lathe("Tile", Vector3(0, 20.1, 0), PackedVector2Array([
		Vector2(6.9, 0.0), Vector2(6.3, 0.4), Vector2(0.45, 3.75), Vector2(0.0, 3.95)]), 8, 1.0, 1.0, rot, false)
	lm.frustum("Gold", Vector3(0, 23.9, 0), 0.22, 0.03, HEIGHT_M - 23.9, 8)
