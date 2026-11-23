class_name LandmarkBkThammasatDome
extends RefCounted

## Thammasat University Dome Building (`ตึกโดม มหาวิทยาลัยธรรมศาสตร์`) — Bangkok BK-5.1
## Site: OSM way 134106801, centroid 13.757443, 100.489970 (`height_m: 28.0`, `yaw_deg: 15.0`).
## Neighbour `way:83608615` (`Thammasat Auditorium`) is deliberately left outside `model_rects_m`.
## Spec (Mew Aphaiwong, 1936, Commons `front.jpg`):
##   - Long 3-storey cream-and-white riverfront wing (`112 × 22 m`, `12.4 m` eaves, dark-brown
##     hipped tile roof to `15.2 m`) with arched ground-floor windows and side pavilions.
##   - Central 4-storey square frontispiece (`12 × 14 m`, `17.2 m` cornice) with 3-arch
##     projecting entrance canopy, crimson-and-gold university nameplate (`มหาวิทยาลัยธรรมศาสตร์`),
##     and round clock oculus.
##   - Signature "Dome": flared dark-brown mansard lower tier with twin dormer windows (`17.2..21.2 m`),
##     cream octagonal lantern collar (`21.2..23.0 m`), and sharp 4-sided pointed "pencil-tip"
##     spire reaching `28.0 m`.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const HEIGHT_M := 28.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("render", "#F0E5C8", 3.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F8F6F0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A3830", 2.5))
	lm.use("Crimson", LandmarkMaterials.pbr("terracotta", "#8C2220", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gold", LandmarkMaterials.gold())

	_main_wings(lm)
	_central_dome_tower(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-14.0, 1.8, 22.0), Vector3(0.0, 20.0, 2.0), 50.0, 1.35, 38.0, Color(1.0, 0.90, 0.65)],
		[Vector3(14.0, 1.8, 22.0), Vector3(0.0, 20.0, 2.0), 50.0, 1.35, 38.0, Color(1.0, 0.90, 0.65)],
	])

static func _main_wings(lm: LandmarkMesh) -> void:
	# Symmetrical 3-storey cream wings (`x = ±31 m`, `48 m` each) + end pavilions (`x = ±52 m`)
	for s in [-1.0, 1.0]:
		var sx := float(s)
		K.block(lm, "Cream", "White", "Glass", "Roof", sx * 30.0, 0.0, 46.0, 19.0, 0.0, 12.2, "hip", 2.8, 4.2, 4.0, true)
		K.block(lm, "Cream", "White", "Glass", "Roof", sx * 51.0, 0.8, 12.0, 21.5, 0.0, 13.0, "hip", 3.0, 4.0, 4.2, true)

static func _central_dome_tower(lm: LandmarkMesh) -> void:
	# 4-storey cream central tower (`12.4 × 14.4 m`, `17.2 m` cornice)
	K.block(lm, "Cream", "White", "Glass", "Roof", 0.0, 1.6, 12.4, 15.0, 0.0, 17.2, "flat", 0.0, 3.8, 4.2, true)
	# Projecting 3-arch entrance canopy (`z = +9..+12.8 m`)
	lm.box("White", Vector3(0, 4.6, 10.9), Vector3(11.2, 0.55, 3.8))
	for ix in [-4.6, -1.5, 1.5, 4.6]:
		lm.box("White", Vector3(ix, 2.3, 12.5), Vector3(0.45, 4.6, 0.45))
	# Crimson university nameplate banner + round clock oculus (`front.jpg`)
	lm.box("Crimson", Vector3(0, 10.4, 9.22), Vector3(8.6, 1.15, 0.16))
	lm.box("Gold", Vector3(0, 10.4, 9.31), Vector3(7.6, 0.35, 0.08))
	lm.disc("Glass", Vector3(0, 14.8, 9.22), Vector3.BACK, 0.95, 16)
	LandmarkFhParts.ring(lm, "White", Vector3(0, 14.8, 9.18), Vector3.BACK, 0.95, 1.18, 0.16, 16)

	# Flared lower mansard skirt (`17.2..21.2 m`) with twin gabled dormers on front & rear
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, 17.2, 1.6), 14.2, 14.2, 4.0, 0.46)
	for sz in [-1.0, 1.0]:
		for sx in [-1.6, 1.6]:
			var dp := Vector3(sx, 19.2, 1.6 + float(sz) * 5.2)
			lm.box("Cream", dp, Vector3(1.3, 1.4, 1.2))
			lm.gable("Roof", dp + Vector3(0, 0.7, 0), 1.5, 1.4, 0.65, Basis(), 0.1, "Cream")

	# Cream octagonal lantern collar (`21.2..23.0 m`) + iconic 4-sided pointed "pencil-tip" spire (`23.0..28.0 m`)
	lm.lathe("Cream", Vector3(0, 21.2, 1.6), PackedVector2Array([
		Vector2(3.1, 0.0), Vector2(3.1, 1.8)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("White", Vector3(0, 22.8, 1.6), PackedVector2Array([
		Vector2(3.35, 0.0), Vector2(3.35, 0.3)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.spire("Roof", Vector3(0, 23.0, 1.6), 3.3, 4.5, 0.0, 4)
	lm.beam("Gold", Vector3(0, 27.4, 1.6), Vector3(0, HEIGHT_M, 1.6), 0.08, 0.08)
