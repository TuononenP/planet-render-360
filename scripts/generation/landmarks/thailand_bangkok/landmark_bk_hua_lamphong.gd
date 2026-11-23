class_name LandmarkBkHuaLamphong
extends RefCounted

## Bangkok Railway Station — Hua Lamphong (สถานีรถไฟกรุงเทพ หัวลำโพง) — BK-4.4
## Site: registry 13.7377, 100.5172, `yaw_deg: 138.7`, `height_m: 26.2`,
## `clear_rect_m: [0.0, -56.0, 80.4, 67.4]`.
## Frame: +X along main facade, +Z out to forecourt, -Z along train shed & tracks.
## Spec (Mario Tamagno & Annibale Rigotti, 1910–1916, Italian Neo-Renaissance):
##   - Great semi-circular half-barrel vault facade (`44 m` span, `26.2 m` crest):
##     butter-yellow stucco walls (`#EAD07C`), broad cream Neo-Renaissance archivolts &
##     pilasters (`#F3EDE0`), dark radially-mullioned stained-glass lunette (`Glass`)
##     centring the illuminated 3.8 m station clock (`Dial`) & gilded State Railway crest,
##     flanked by twin stepped Neo-Renaissance corner turrets.
##   - Ground entrance colonnade & projecting porte-cochère canopy (`+Z`).
##   - Symmetrical two-storey arcaded side wings (`±44 m`) ending in 3-storey corner
##     pavilions (`±71 m`) with Classical pediments & roof balustrades.
##   - 122 m curved steel-truss train shed (`-Z`) with clerestory lantern, exposed interior
##     steel arch ribs, and 6 passenger platforms.
##   - Forecourt (`+Z = +16 m`) oval fountain pool & white three-headed Erawan elephant memorial.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const HEIGHT_M := 26.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Walls", LandmarkMaterials.pbr("render", "#EAD07C", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F4EFE2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#9C7B48", 2.5, 0.52, 0.35))
	lm.use("WingRoof", LandmarkMaterials.pbr("terracotta", "#8E4A32", 2.5))
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#3A4046", 2.0, 0.45, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#243848"))
	lm.use("Dial", LandmarkMaterials.lit("#FFF7DE", 2.2))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Platform", LandmarkMaterials.pbr("concrete", "#B8B2A6", 3.0))
	lm.use("Water", LandmarkMaterials.pool_water("#3B5D66", 0.12))

	_train_shed_and_platforms(lm)
	_main_arch_frontispiece(lm)
	_side_wings_and_pavilions(lm)
	_forecourt_fountain(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 2.0, 22.0), Vector3(-8.0, 16.0, 2.0), 52.0, 1.35, 42.0, Color(1.0, 0.90, 0.68)],
		[Vector3(22.0, 2.0, 22.0), Vector3(8.0, 16.0, 2.0), 52.0, 1.35, 42.0, Color(1.0, 0.90, 0.68)],
		[Vector3(0.0, 2.0, 26.0), Vector3(0.0, 21.0, 2.0), 48.0, 1.45, 42.0, Color(1.0, 0.92, 0.72)],
		[Vector3(-56.0, 2.0, 18.0), Vector3(-56.0, 9.0, 2.0), 52.0, 0.95, 34.0, Color(1.0, 0.90, 0.68)],
		[Vector3(56.0, 2.0, 18.0), Vector3(56.0, 9.0, 2.0), 52.0, 0.95, 34.0, Color(1.0, 0.90, 0.68)],
	])

static func _train_shed_and_platforms(lm: LandmarkMesh) -> void:
	# 122 m arched barrel train shed (y = 0..25.6 m, z = 0..-122 m) + raised clerestory skylight
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, 0), Vector3.FORWARD, 44.0, 122.0, 11.8, 13.8, 8.8, 0.24, 1)
	# Side arcade walls of the train shed
	for s in [-1.0, 1.0]:
		var sx := float(s)
		lm.box("Walls", Vector3(sx * 22.2, 5.9, -61.0), Vector3(1.1, 11.8, 122.0))
		lm.box("Trim", Vector3(sx * 22.3, 11.6, -61.0), Vector3(1.4, 0.6, 122.4))
		K.arch_row(lm, "Trim", "Glass", Vector3(sx * 22.8, 0, -4.0), Vector3(sx * 22.8, 0, -118.0),
			Vector3(sx, 0, 0), 2.8, 15, 2.8, 6.2, 1)
	# Six concrete passenger platforms & concourse floor inside the train shed
	lm.box("Platform", Vector3(0, 0.35, -8.0), Vector3(43.0, 0.7, 18.0))
	for p in 6:
		var px := -17.5 + 7.0 * float(p)
		lm.box("Platform", Vector3(px, 0.45, -66.0), Vector3(3.6, 0.9, 108.0))

static func _main_arch_frontispiece(lm: LandmarkMesh) -> void:
	# Neo-Renaissance headhouse wall & moulded cream semicircular arch ring reaching 26.2 m
	lm.box("Walls", Vector3(0, 5.9, 1.8), Vector3(46.8, 11.8, 4.4))
	lm.box("Trim", Vector3(0, 11.8, 2.0), Vector3(48.0, 0.9, 5.0))
	# Great stained-glass lunette (z = +3.6 m) + thick moulded cream outer archivolt ring
	K.lunette(lm, "Trim", "Glass", Vector3(0, 11.9, 3.6), Vector3.BACK, 42.4, 13.6, 14, 9)
	var arch_segs := 18
	for i in arch_segs:
		var a0 := PI * float(i) / float(arch_segs)
		var a1 := PI * float(i + 1) / float(arch_segs)
		var r_mid := 22.1
		var p0 := Vector3(-cos(a0) * r_mid, 11.9 + sin(a0) * 13.9, 3.9)
		var p1 := Vector3(-cos(a1) * r_mid, 11.9 + sin(a1) * 13.9, 3.9)
		lm.beam("Trim", p0, p1, 1.65, 1.15, Vector3.BACK)
		var p0_in := Vector3(-cos(a0) * 20.6, 11.9 + sin(a0) * 12.6, 3.8)
		var p1_in := Vector3(-cos(a1) * 20.6, 11.9 + sin(a1) * 12.6, 3.8)
		lm.beam("Walls", p0_in, p1_in, 1.1, 0.85, Vector3.BACK)

	# Crowning Neo-Renaissance keystone crest cleanly at HEIGHT_M = 26.2 m + illuminated station clock
	lm.box("Trim", Vector3(0, 25.75, 4.05), Vector3(5.4, 0.9, 1.4))
	lm.box("Gold", Vector3(0, 25.65, 4.80), Vector3(1.8, 1.2, 0.25))
	K.clock(lm, "Dial", "Trim", Vector3(0, 19.2, 4.15), Vector3.BACK, 2.1)

	# Twin rusticated Neo-Renaissance corner pylons flanking the great arch (`x = ±23.2 m`)
	for s in [-1.0, 1.0]:
		var sx := float(s)
		lm.box("Walls", Vector3(sx * 23.2, 8.2, 2.2), Vector3(4.2, 16.4, 5.2))
		lm.box("Trim", Vector3(sx * 23.2, 16.7, 2.2), Vector3(4.8, 0.7, 5.8))
		lm.box("Trim", Vector3(sx * 23.2, 18.0, 2.2), Vector3(3.4, 2.0, 4.0))
		lm.spire("Trim", Vector3(sx * 23.2, 19.0, 2.2), 1.8, 1.4, 0.0, 4)

	# Ground-floor 7-bay arched loggia & projecting porte-cochère canopy (`z = +4..+8.5 m`)
	K.arch_row(lm, "Trim", "Glass", Vector3(-19.5, 0, 4.05), Vector3(19.5, 0, 4.05), Vector3.BACK, 0.8, 7, 3.4, 8.4, 1)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-20.5, 0, 7.6), Vector3(20.5, 0, 7.6), 10, 6.4, 0.44)
	lm.box("Trim", Vector3(0, 6.8, 5.9), Vector3(43.0, 0.85, 4.4))
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-21.0, 7.22, 7.8), Vector3(21.0, 7.22, 7.8), 0.7, 0.35, 0.75, 0.3)

static func _side_wings_and_pavilions(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var sx := float(s)
		# Two-storey arcaded cream-and-yellow wing (`x = ±45.5 m`, 40 m wide) with hipped tile roof & balustrade
		K.block(lm, "Walls", "Trim", "Glass", "WingRoof", sx * 45.5, -2.0, 40.5, 16.5, 0.0, 10.4, "hip", 1.8, 3.8, 5.0, true)
		LandmarkFhUtil.merlons(lm, "Trim", Vector3(sx * 25.5, 10.4, 6.1), Vector3(sx * 65.5, 10.4, 6.1), 0.75, 0.35, 0.85, 0.3)
		# Three-storey Neo-Renaissance end pavilion (`x = ±72.0 m`, 13.5 m wide) with Classical pediment
		K.block(lm, "Walls", "Trim", "Glass", "WingRoof", sx * 72.0, -1.0, 13.5, 19.0, 0.0, 14.2, "hip", 2.1, 3.8, 5.2, true)
		lm.gable("Trim", Vector3(sx * 72.0, 14.2, 8.6), 12.8, 1.2, 2.2, Basis(), 0.2, "Walls")
		LandmarkFhUtil.merlons(lm, "Trim", Vector3(sx * 65.4, 14.2, 8.4), Vector3(sx * 78.6, 14.2, 8.4), 0.75, 0.35, 0.9, 0.3)

static func _forecourt_fountain(lm: LandmarkMesh) -> void:
	# Forecourt oval fountain & white three-headed elephant monument at z = +16.0 m
	var fc := Vector3(0, 0.0, 16.0)
	lm.lathe("Trim", fc, PackedVector2Array([
		Vector2(6.4, 0.0), Vector2(6.4, 0.55), Vector2(5.8, 0.65)]), 20, 1.35, 0.85)
	lm.lathe("Water", fc + Vector3(0, 0.48, 0), PackedVector2Array([
		Vector2(5.7, 0.0), Vector2(0.0, 0.02)]), 20, 1.35, 0.85)
	lm.box("Trim", fc + Vector3(0, 1.25, 0), Vector3(2.2, 1.5, 2.2))
	lm.box("Trim", fc + Vector3(0, 2.45, 0), Vector3(1.2, 1.1, 1.6))
	lm.spire("Gold", fc + Vector3(0, 3.0, 0), 0.45, 0.85, 0.0, 6)
