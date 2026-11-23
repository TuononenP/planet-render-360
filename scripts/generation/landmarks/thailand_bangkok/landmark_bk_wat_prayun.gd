class_name LandmarkBkWatPrayun
extends RefCounted

## Wat Prayurawongsawat — Phra Borommathat Maha Chedi (`วัดประยุรวงศาวาสวรวิหาร`) — Bangkok BK-5.4
## Site: OSM way 30753271, centroid 13.737368, 100.495376 (`height_m: 60.5`, `yaw_deg: 6.0`).
## Spec (Somdet Chao Phraya Borom Maha Prayurawongse 1828, UNESCO Heritage Award, Commons `front.jpg`):
##   - Gleaming pure-white **60.5 m Sri Lankan bell chedi** (`Phra Borommathat Maha Chedi`):
##     ringed lower drum mouldings, smooth white bell dome, square harmika, ringed conical
##     *plong chanai* spire, and golden dewdrop finial at `60.5 m`.
##   - Unique circular Neo-Classical arched gallery porch (`vihara khot`, `R = 21.0 m`, `6.8 m` tall)
##     with 24 round-headed open arches, balustraded roof terrace, **18 smaller white bell chedis**
##     ringed around its parapet (`front.jpg`), and Neo-Classical pedimented entrance porches.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const HEIGHT_M := 60.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F7F5EF", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EAE5DA", 3.0))
	lm.use("Court", LandmarkMaterials.pbr("terracotta", "#9A5A42", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B84C2E", 2.4))
	lm.use("DoorGreen", LandmarkMaterials.pbr("wood", "#2D5A3C", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#262220", 0.9, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())

	_circular_porch_and_18_chedis(lm)
	_great_white_bell_chedi(lm)
	lm.commit(model)

	# Warm amber/white uplighting washing the gleaming white 60.5 m bell chedi & 18 satellite chedis (`front.jpg`)
	var spots: Array = []
	for i in 4:
		var a := PI * 0.25 + PI * 0.5 * float(i)
		var d := Vector3(cos(a), 0, sin(a))
		spots.append([d * 28.0 + Vector3(0, 2.5, 0), Vector3(0, 32.0, 0),
			50.0, 1.45, 62.0, Color(1.0, 0.90, 0.68)])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _circular_porch_and_18_chedis(lm: LandmarkMesh) -> void:
	lm.lathe("Court", Vector3.ZERO, PackedVector2Array([
		Vector2(26.5, 0.0), Vector2(26.5, 0.2), Vector2(0.0, 0.2)]), 32)
	# Circular Neo-Classical arched gallery (`R = 21.2 m`, `y = 0.2..6.8 m`)
	lm.lathe("White", Vector3(0, 0.2, 0), PackedVector2Array([
		Vector2(21.6, 0.0), Vector2(21.2, 0.8), Vector2(21.2, 6.0),
		Vector2(21.8, 6.4), Vector2(21.4, 7.3), Vector2(14.0, 7.3)]), 36, 1.0, 1.0, 0.0, false)
	for i in 24:
		var a := TAU * (float(i) + 0.5) / 24.0
		var n := Vector3(sin(a), 0, cos(a))
		K.arch_window(lm, "Trim", "Shadow", n * 21.15 + Vector3(0, 1.2, 0), n, 2.1, 3.8, 0)

	# Ring of 18 white satellite bell chedis around the porch parapet (`R = 18.4 m`, `y = 7.5..15.2 m`)
	var mini := LandmarkMesh.new()
	for k in ["White", "Gold"]:
		mini.use(k, LandmarkMaterials.gold())
	U.bell_chedi(mini, "White", "White", "Gold", Vector3.ZERO, 1.35, 7.8)
	for i in 18:
		var a := TAU * float(i) / 18.0
		lm.merge(mini, Transform3D(Basis(), Vector3(cos(a) * 18.4, 7.5, sin(a) * 18.4)))

	# Axial Neo-Classical pedimented entrance pavilions (`+Z` & `-Z`) with green doors (`front.jpg`)
	for sz in [-1.0, 1.0]:
		var s := float(sz)
		var pc := Vector3(0, 0.2, s * 22.8)
		var b := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		lm.box("White", pc + Vector3(0, 2.8, 0), Vector3(7.4, 5.6, 4.2), b)
		lm.gable("Tile", pc + Vector3(0, 5.6, 0), 7.8, 4.6, 1.6, b, 0.2, "White")
		K.arch_window(lm, "Trim", "DoorGreen", pc + b * Vector3(0, 0.4, 2.12), b.z, 2.2, 4.2, 1)

static func _great_white_bell_chedi(lm: LandmarkMesh) -> void:
	# Stepped circular ringed plinth (`y = 7.5..16.5 m`) + smooth bell (`16.5..31.5 m`) + harmika + ringed spire (`60.5 m`)
	var prof := PackedVector2Array([Vector2(14.2, 0.0), Vector2(13.8, 1.6)])
	for r_i in 9:
		var y := 1.6 + 0.82 * float(r_i)
		var rad := 13.4 - 0.34 * float(r_i)
		prof.append(Vector2(rad * 1.02, y))
		prof.append(Vector2(rad * 0.98, y + 0.45))
		prof.append(Vector2(rad, y + 0.80))
	# Smooth Sri Lankan bell curve (`y = 9.0..23.5` above 7.5 = `16.5..31.0 m`)
	prof.append_array(PackedVector2Array([
		Vector2(10.2, 9.2), Vector2(10.0, 12.0), Vector2(9.1, 16.0),
		Vector2(7.4, 19.6), Vector2(5.0, 22.4), Vector2(3.6, 23.6)]))
	lm.lathe("White", Vector3(0, 7.5, 0), prof, 32)

	# Square Harmika (`balang`, `y = 31.1..34.2 m`)
	lm.box("White", Vector3(0, 32.65, 0), Vector3(5.6, 3.1, 5.6))
	lm.box("Trim", Vector3(0, 34.1, 0), Vector3(6.1, 0.45, 6.1))

	# Ringed conical spire (`y = 34.3..58.2 m`) + golden finial (`58.2..60.5 m`)
	var sp := PackedVector2Array()
	for i in 24:
		var t := float(i) / 24.0
		var r := lerpf(3.2, 0.28, pow(t, 0.86))
		var y := 23.9 * t
		sp.append(Vector2(r, y))
		sp.append(Vector2(r * 1.09, y + 0.35))
		sp.append(Vector2(r * 0.95, y + 0.92))
	sp.append(Vector2(0.14, 24.1))
	lm.lathe("White", Vector3(0, 34.3, 0), sp, 20)
	lm.beam("Gold", Vector3(0, 58.3, 0), Vector3(0, HEIGHT_M, 0), 0.14, 0.14)
	lm.lathe("Gold", Vector3(0, 58.8, 0), PackedVector2Array([
		Vector2(0.28, 0.0), Vector2(0.38, 0.35), Vector2(0.12, 0.85), Vector2(0.0, 1.3)]), 10)
