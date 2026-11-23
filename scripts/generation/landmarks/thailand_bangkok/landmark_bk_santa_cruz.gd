class_name LandmarkBkSantaCruz
extends RefCounted

## Santa Cruz Church (`วัดซางตาครู้ส` / Kudi Chin) — Thonburi Bank, Bangkok BK-5.4
## Site: OSM way 304092134, centroid 13.738909, 100.493746 (`height_m: 36.0`, `yaw_deg: 17.0`).
## Spec (Annibale Rigotti & Mario Tamagno, 1916, Italian Renaissance Revival, Commons `front.jpg`):
##   - Cream stucco basilica nave & aisles (`16.5 × 44 m`, `13.2 m` balustrade parapet) banded
##     with muted terracotta-rose pilasters & cornices (`#B3736A`) under a terracotta tile roof.
##   - Riverside entrance frontispiece (`+Z`) with Classical colonnade, rooftop balustrade & urns,
##     square belfry pedestal (`13.2..19.8 m`) with carved rose window (`front.jpg`), octagonal
##     arched bell-chamber drum (`19.8..26.2 m`), ribbed crimson-terracotta dome (`#8B3836`,
##     `26.2..31.4 m`) with 8 cream ribs, open lantern cupola (`31.4..34.3 m`), and gilt cross at `36.0 m`.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const HEIGHT_M := 36.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("render", "#F1EAD9", 3.0))
	lm.use("RoseTrim", LandmarkMaterials.pbr("limestone", "#BC8378", 3.0))
	lm.use("DomeRed", LandmarkMaterials.pbr("terracotta", "#8B3836", 2.2))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A84E38", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#26303A"))
	lm.use("Gold", LandmarkMaterials.gold())

	_basilica_nave(lm)
	_belfry_and_red_dome(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 2.0, 32.0), Vector3(0.0, 24.0, 14.0), 48.0, 1.35, 42.0, Color(1.0, 0.90, 0.68)],
		[Vector3(12.0, 2.0, 32.0), Vector3(0.0, 24.0, 14.0), 48.0, 1.35, 42.0, Color(1.0, 0.90, 0.68)],
	])

static func _basilica_nave(lm: LandmarkMesh) -> void:
	# Side aisles (`16.8 m` wide, `9.4 m` tall) + taller central clerestory nave (`10.2 m` wide, `13.0 m` tall)
	K.block(lm, "Cream", "RoseTrim", "Glass", "Tile", 0.0, -2.0, 16.8, 42.0, 0.0, 9.4, "hip", 1.8, 4.6, 4.4, true)
	K.block(lm, "Cream", "RoseTrim", "Glass", "Tile", 0.0, -2.0, 10.4, 40.0, 9.0, 4.0, "gable_z", 2.6, 4.6, 3.6, false)
	# Semicircular apse at `-Z = -23.0 m`
	lm.lathe("Cream", Vector3(0, 0, -22.5), PackedVector2Array([
		Vector2(4.8, 0.0), Vector2(4.8, 10.5), Vector2(0.0, 12.6)]), 14, 1.0, 1.0, 0.0, false)
	# Riverside front parapet balustrade & corner finials (`z = +19.2 m`, `front.jpg`)
	lm.box("Cream", Vector3(0, 6.4, 19.2), Vector3(17.2, 12.8, 2.4))
	lm.box("RoseTrim", Vector3(0, 12.8, 19.3), Vector3(17.8, 0.6, 2.8))
	LandmarkFhUtil.merlons(lm, "Cream", Vector3(-8.4, 13.1, 20.3), Vector3(8.4, 13.1, 20.3), 0.85, 0.35, 0.95, 0.3)
	for sx in [-8.2, 8.2]:
		lm.frustum("RoseTrim", Vector3(sx, 13.1, 20.3), 0.42, 0.12, 1.9, 8)
	K.arch_row(lm, "RoseTrim", "Glass", Vector3(-6.4, 0, 20.42), Vector3(6.4, 0, 20.42),
		Vector3.BACK, 0.8, 3, 2.8, 6.8, 1)

static func _belfry_and_red_dome(lm: LandmarkMesh) -> void:
	var tc := Vector3(0.0, 0.0, 15.5)
	# Square rose-window pedestal stage (`13.0..19.8 m`)
	lm.box("Cream", tc + Vector3(0, 16.4, 0), Vector3(7.8, 6.8, 7.8))
	lm.box("RoseTrim", tc + Vector3(0, 19.7, 0), Vector3(8.5, 0.65, 8.5))
	lm.disc("Glass", tc + Vector3(0, 16.4, 3.96), Vector3.BACK, 1.65, 20)
	LandmarkFhParts.ring(lm, "RoseTrim", tc + Vector3(0, 16.4, 3.92), Vector3.BACK, 1.65, 2.05, 0.22, 20)

	# Octagonal arched bell-chamber drum (`19.8..26.2 m`)
	var rot := PI / 8.0
	lm.lathe("Cream", tc + Vector3(0, 19.8, 0), PackedVector2Array([
		Vector2(4.05, 0.0), Vector2(3.95, 6.4)]), 8, 1.0, 1.0, rot, false)
	lm.lathe("RoseTrim", tc + Vector3(0, 26.0, 0), PackedVector2Array([
		Vector2(4.35, 0.0), Vector2(4.35, 0.5)]), 8, 1.0, 1.0, rot, false)
	var apothem := 3.98 * cos(rot)
	for s in 8:
		var a := rot + TAU * (float(s) + 0.5) / 8.0
		var n := Vector3(sin(a), 0, cos(a))
		K.arch_window(lm, "RoseTrim", "Glass", tc + n * apothem + Vector3(0, 20.6, 0), n, 1.45, 4.2, 1)

	# Ribbed terracotta-red dome (`26.4..31.5 m`) + 8 cream ribs + cupola lantern (`31.5..34.4 m`) + golden cross (`36.0 m`)
	lm.lathe("DomeRed", tc + Vector3(0, 26.4, 0), LandmarkFhUtil.dome_prof(4.0, 5.1), 16)
	for s in 8:
		var a := rot + TAU * float(s) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Cream", tc + Vector3(0, 26.5, 0) + d * 3.95, tc + Vector3(0, 31.3, 0) + d * 0.95, 0.18, 0.18)
	lm.lathe("Cream", tc + Vector3(0, 31.4, 0), PackedVector2Array([
		Vector2(1.05, 0.0), Vector2(0.95, 2.1)]), 8, 1.0, 1.0, rot, false)
	lm.lathe("DomeRed", tc + Vector3(0, 33.5, 0), LandmarkFhUtil.dome_prof(1.08, 0.95), 10)
	lm.beam("Gold", tc + Vector3(0, 34.4, 0), tc + Vector3(0, HEIGHT_M, 0), 0.12, 0.12)
	lm.beam("Gold", tc + Vector3(-0.48, 35.4, 0), tc + Vector3(0.48, 35.4, 0), 0.11, 0.11)
