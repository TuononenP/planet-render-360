class_name LandmarkMseWatPho
extends RefCounted

## Wat Pho — Wat Phra Chetuphon Vimolmangklararm (`วัดพระเชตุพนวิมลมังคลาราม`) — Bangkok BK-4.2
## Site: registry 13.74668, 100.49237, `clear_m: 135.0`, `height_m: 42.0`.
## Spec (Rama I & Rama III royal monastery, Fine Arts Dept / UNESCO Memory of the World / Commons refs):
##   - Viharn Phranorn (`วิหารพระพุทธไสยาสน์`, NW compound at `(-73, 0, 20)`, 24 × 56 m, 2-step 3-tier
##     orange-and-green Thai roof): pierced window walls & open tall east colonnade doors (`LandmarkDetail.pierced_face`)
##     revealing the monumental **46 m long × 15 m tall gilded Reclining Buddha** (`K2.reclining_buddha`),
##     head to the south (`+Z`), facing east (`+X`), with dark mother-of-pearl-inlaid flat soles (`SolePearl`) at north (`-Z`).
##   - Phra Maha Chedi Si Ratchakan: 4 great 42 m redented mosaic chedis of Kings Rama I–IV in green
##     (`#2F7D5B`), white (`#EDE6D2`), yellow (`#D9A83A`), and dark-blue (`#2C5FA3`) glazed porcelain tile
##     inside a white `sema_wall` courtyard.
##   - Phra Mondop scripture library (crowned by a 5-tier porcelain prasat spire) & Ho Rakhang belfry.
##   - Phra Ubosot (`(70, 0, 32)`) on a double marble balustrade terrace inside the double cloister (`Phra Rabiang`)
##     lined with gilded seated Buddhas, 4 axial viharns, 4 corner marble prangs, and 4 five-chedi corner clusters.
##   - 71 Phra Chedi Rai (`5.2 m` small porcelain chedis) arranged around the inner courts, plus whitewashed
##     outer compound walls with porcelain-pediment gates guarded by `K2.chinese_guardian` ballast warriors.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const WAT_PHO_M := 42.0

static func wat_pho(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkMseBangkok._tiles(lm)
	lm.use("ChediGreen", LandmarkMaterials.pbr("render", "#2F7D5B", 3.0))
	lm.use("ChediYellow", LandmarkMaterials.pbr("render", "#D9A83A", 3.0))
	lm.use("ChediBlue", LandmarkMaterials.pbr("render", "#2C5FA3", 3.0))
	lm.use("SolePearl", LandmarkMaterials.pbr("slate", "#222930", 4.0, 0.25, 0.35))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8B8880", 3.0))

	_outer_compound_walls_and_giants(lm)
	_four_great_chedis_and_mondop(lm)
	_viharn_reclining_buddha(lm)
	_ubosot_double_cloister(lm)
	_chedi_rai_rows(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-55.0, 2.5, 4.0), Vector3(-55.0, 26.0, -38.0), 54.0, 1.45, 62.0, Color(1.0, 0.88, 0.56)],
		[Vector3(-55.0, 2.5, -78.0), Vector3(-55.0, 26.0, -38.0), 54.0, 1.35, 62.0, Color(1.0, 0.88, 0.56)],
		[Vector3(-42.0, 2.5, 20.0), Vector3(-73.0, 14.0, 20.0), 52.0, 1.35, 48.0, Color(1.0, 0.86, 0.48)],
		[Vector3(70.0, 2.5, -14.0), Vector3(70.0, 18.0, 32.0), 52.0, 1.25, 58.0, Color(1.0, 0.90, 0.62)],
	])

static func _outer_compound_walls_and_giants(lm: LandmarkMesh) -> void:
	# Whitewashed outer monastery compound wall (`216 × 162 m`) with crowned Thai-Chinese porcelain gates
	# guarded by pairs of top-hatted / bearded `K2.chinese_guardian` stone warriors (`front.jpg`).
	var corners := [
		Vector3(-106.0, 0.0, -78.0), Vector3(128.0, 0.0, -78.0),
		Vector3(128.0, 0.0, 78.0), Vector3(-106.0, 0.0, 78.0),
	]
	for i in 4:
		K.sema_wall(lm, "Wall", corners[i], corners[(i + 1) % 4], 3.2, 1.2, 3.2)

	var guard := LandmarkMesh.new()
	guard.use("Granite", LandmarkMaterials.gold())
	K2.chinese_guardian(guard, "Granite", Vector3.ZERO, Basis(), 3.4)

	var gates := [
		[Vector3(-73.0, 0.0, -78.0), PI],
		[Vector3(-12.0, 0.0, -78.0), PI],
		[Vector3(-106.0, 0.0, 20.0), -PI * 0.5],
		[Vector3(70.0, 0.0, 78.0), 0.0],
	]
	for g in gates:
		var gc: Vector3 = g[0]
		var yaw: float = g[1]
		var gb := Basis(Vector3.UP, yaw)
		lm.box("Wall", gc + Vector3(0, 2.6, 0), Vector3(5.6, 5.2, 1.8), gb)
		lm.box("Dark", gc + Vector3(0, 1.9, 0), Vector3(2.4, 3.8, 2.0), gb, 0.0)
		K.outline_prism(lm, "ChediGreen", gc + gb * Vector3(0, 5.2, 0), gb, K.flame_outline(5.8, 2.4), 1.4)
		K.outline_prism(lm, "Gold", gc + gb * Vector3(0, 5.3, 0.05), gb, K.flame_outline(4.8, 1.9), 1.5)
		for sx in [-1.0, 1.0]:
			lm.merge(guard, Transform3D(gb, gc + gb * Vector3(float(sx) * 3.2, 0.0, 1.5)))

static func _four_great_chedis_and_mondop(lm: LandmarkMesh) -> void:
	# Four 42 m Phra Maha Chedi Si Ratchakan in their walled courtyard
	var keys := ["ChediGreen", "Wall", "ChediYellow", "ChediBlue"]
	var k := 0
	lm.box("Stone", Vector3(-55, 0.4, -38), Vector3(64, 0.8, 52))
	var ring := [Vector3(-87, 0, -64), Vector3(-23, 0, -64), Vector3(-23, 0, -12), Vector3(-87, 0, -12)]
	for i in 4:
		K.sema_wall(lm, "Wall", ring[i], ring[(i + 1) % 4], 2.4, 0.8, 2.2)
	for cz: float in [-51.0, -25.0]:
		for cx: float in [-68.0, -42.0]:
			var cc := Vector3(cx, 0.8, cz)
			K.redent_chedi(lm, keys[k], keys[k], "Gold", cc, 6.4, WAT_PHO_M - 0.8)
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				lm.box(keys[k], cc + b * Vector3(0, 2.6, 11.4), Vector3(3.2, 5.2, 2.0), b)
				lm.box("Gold", cc + b * Vector3(0, 5.4, 11.4), Vector3(3.5, 0.5, 2.3), b)
				lm.box("Dark", cc + b * Vector3(0, 2.0, 12.42), Vector3(1.4, 2.8, 0.1), b, 0.0)
			k += 1

	# Phra Mondop (Scripture Library, east of the 4 great chedis at `(-8, 0, -42)`) + Ho Rakhang belfry
	var mk := {"wall": "Wall", "stone": "Stone", "tile": "ChediGreen", "gold": "Gold", "dark": "Dark", "col": "Wall"}
	K2.mondop(lm, mk, Vector3(-8.0, 0.0, -42.0), Basis(), 10.5, 6.8, 13.5, 5, 1.4)
	K2.mondop(lm, {"wall": "Wall", "stone": "Stone", "tile": "ChediBlue", "gold": "Gold", "dark": "Dark", "col": "Gold"},
		Vector3(-22.0, 0.0, 6.0), Basis(), 4.8, 4.6, 9.2, 4, 1.1)

static func _viharn_reclining_buddha(lm: LandmarkMesh) -> void:
	# Viharn Phranorn (`(-73, 0, 20)`): long axis N-S (`56 m`), width E-W (`22 m`).
	# Built with `LandmarkDetail.pierced_face` open doors & tall windows so the golden 46 m × 15 m
	# Reclining Buddha (`K2.reclining_buddha`) and its dark pearl-inlaid soles are genuinely visible inside!
	var vc := Vector3(-73.0, 0.0, 20.0)
	var plinth_h := 1.4
	var wall_h := 14.8
	var w := 18.0
	var l := 52.0
	K.plinth(lm, "Stone", vc, Basis(), w + 6.4, l + 6.4, plinth_h)
	# Outer colonnade peristyle supporting the sweeping 2-step, 3-tier Thai roof
	K.peristyle(lm, "Wall", "Gold", vc + Vector3(0, plinth_h, 0), Basis(), w + 4.8, l + 4.8, wall_h, 0.72, 4.4)

	# Pierced long East & West walls (`glass = ""` leaves open reveals so the golden Reclining Buddha shines inside!)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		var right_v := Vector3(0, 0, -s)
		var norm_v := Vector3(s, 0, 0)
		var origin := vc + Vector3(s * (w * 0.5 - 0.55), plinth_h, 0) - right_v * (l * 0.5)
		LandmarkDetail.pierced_face(lm, "Wall", "", origin, right_v, norm_v,
			l, wall_h, 11, 1, Vector2(2.3, 8.2), 0.8, 9.0, 0.55)
		for bi in 11:
			var wp := origin + right_v * ((float(bi) + 0.5) * l / 11.0) + Vector3(0, 9.1, 0) + norm_v * 0.58
			K.outline_prism(lm, "Gold", wp, Basis(right_v, Vector3.UP, norm_v), K.flame_outline(2.6, 1.8), 0.14)

	# Pierced North & South end walls with 3 tall open ceremonial doorways (`sill = 0.0`)
	for sz in [-1.0, 1.0]:
		var s := float(sz)
		var right_v := Vector3(s, 0, 0)
		var norm_v := Vector3(0, 0, s)
		var origin := vc + Vector3(0, plinth_h, s * (l * 0.5 - 0.55)) - right_v * (w * 0.5)
		LandmarkDetail.pierced_face(lm, "Wall", "", origin, right_v, norm_v,
			w, wall_h, 3, 1, Vector2(2.8, 9.2), 0.0, 10.0, 0.55)
		for bi in 3:
			var dp := origin + right_v * ((float(bi) + 0.5) * w / 3.0) + Vector3(0, 9.3, 0) + norm_v * 0.58
			K.outline_prism(lm, "Gold", dp, Basis(right_v, Vector3.UP, norm_v), K.flame_outline(3.1, 2.1), 0.16)

	# Monumental 46 m long × 15 m tall Reclining Buddha inside the hall:
	# `Basis(Vector3.UP, PI * 0.5)` places head at +Z (south), feet/pearl soles at -Z (north), facing +X (east)!
	K2.reclining_buddha(lm, "Gold", "SolePearl", "Gold",
		vc + Vector3(-0.6, plinth_h, 0.0), Basis(Vector3.UP, PI * 0.5), 46.0, 15.0)

	# Grand 2-step, 3-layer orange-and-green Thai roof crowning the Viharn
	K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", vc + Vector3(0, plinth_h + wall_h, 0),
		Basis(), w + 5.2, l + 5.2, 6.2, 1.3, 2, 2, 1.8)

static func _ubosot_double_cloister(lm: LandmarkMesh) -> void:
	# Phra Ubosot facing east on its double marble balustrade terrace (`bai sema` shrines at 8 points)
	var oc := Vector3(70.0, 0.0, 32.0)
	lm.box("Stone", oc + Vector3(0, 0.35, 0), Vector3(44.0, 0.7, 30.0))
	for sz in [-1.0, 1.0]:
		U.posts(lm, "Stone", oc + Vector3(-21.5, 0.7, float(sz) * 14.6),
			oc + Vector3(21.5, 0.7, float(sz) * 14.6), 22, 0.9, 0.28)
		U.posts(lm, "Stone", oc + Vector3(-19.5, 0.7, float(sz) * 12.6),
			oc + Vector3(19.5, 0.7, float(sz) * 12.6), 20, 0.9, 0.26)
	K.thai_hall(lm, LandmarkMseBangkok.hall_keys(), oc + Vector3(0, 0.7, 0),
		Basis(Vector3.UP, PI * 0.5), 15.0, 30.0, 9.2, 7, 2.2, 2, 1, 5.2, 1.5)
	_cloister(lm, oc, 45.0, 33.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K.redent_prang(lm, "Wall", "Dark", "Gold",
				oc + Vector3(float(sx) * 33.0, 0.0, float(sz) * 21.0), 1.9, 16.0, 5, true)
			var gc := oc + Vector3(float(sx) * 52.0, 0.0, float(sz) * 38.0)
			lm.box("Stone", gc + Vector3(0, 0.6, 0), Vector3(10.0, 1.2, 10.0))
			K.small_chedi(lm, "Wall", "Gold", gc + Vector3(0, 1.2, 0), 1.6, 11.0)
			for dx in [-3.2, 3.2]:
				for dz in [-3.2, 3.2]:
					K.small_chedi(lm, "ChediGreen", "Gold", gc + Vector3(dx, 1.2, dz), 0.9, 7.0)

static func _chedi_rai_rows(lm: LandmarkMesh) -> void:
	# 71 small glazed Phra Chedi Rai (`5.2 m` tall) built once & instanced along the inner monastery courts
	var rai := LandmarkMesh.new()
	for k in ["Wall", "Gold"]:
		rai.use(k, LandmarkMaterials.gold())
	K.small_chedi(rai, "Wall", "Gold", Vector3.ZERO, 0.95, 5.2)

	# 20 along West cloister flank, 20 along North cloister flank, 17 along South flank, 14 along central walk = 71!
	for i in 20:
		lm.merge(rai, Transform3D(Basis(), Vector3(16.0, 0.0, -24.0 + 5.6 * float(i))))
		lm.merge(rai, Transform3D(Basis(), Vector3(24.0 + 4.8 * float(i), 0.0, -8.0)))
	for i in 17:
		lm.merge(rai, Transform3D(Basis(), Vector3(28.0 + 5.0 * float(i), 0.0, 72.0)))
	for i in 14:
		lm.merge(rai, Transform3D(Basis(), Vector3(6.0, 0.0, -38.0 + 6.0 * float(i))))

static func _cloister(lm: LandmarkMesh, c: Vector3, hx: float, hz: float) -> void:
	var t := 8.0
	var bud := LandmarkMesh.new()
	bud.use("Gold", LandmarkMaterials.gold())
	K.seated_buddha(bud, "Gold", Vector3.ZERO, Basis(), 1.6)

	for s in [-1.0, 1.0]:
		var sf := float(s)
		for g in 2:
			var off := t * 0.25 + t * 0.5 * float(g)
			var zc: float = sf * (hz - off)
			lm.gable("Orange", c + Vector3(0, 4.2, zc), t * 0.5, hx * 2.0 - off * 2.0, 2.2, Basis(Vector3.UP, PI * 0.5),
				0.4, "Wall")
			var xc: float = sf * (hx - off)
			lm.gable("Orange", c + Vector3(xc, 4.2, 0), t * 0.5, hz * 2.0 - off * 2.0, 2.2, Basis(), 0.4, "Wall")
		lm.box("Wall", c + Vector3(0, 2.1, sf * (hz - t * 0.5)), Vector3(hx * 2.0 - t, 4.2, 0.6))
		lm.box("Wall", c + Vector3(sf * (hx - t * 0.5), 2.1, 0), Vector3(0.6, 4.2, hz * 2.0 - t))
		lm.box("Wall", c + Vector3(0, 2.1, sf * hz), Vector3(hx * 2.0, 4.2, 0.6))
		lm.box("Wall", c + Vector3(sf * hx, 2.1, 0), Vector3(0.6, 4.2, hz * 2.0))
		U.posts(lm, "Wall", c + Vector3(-hx + t, 0, sf * (hz - t)), c + Vector3(hx - t, 0, sf * (hz - t)), 26, 4.2, 0.5, 0.0)
		U.posts(lm, "Wall", c + Vector3(sf * (hx - t), 0, -hz + t), c + Vector3(sf * (hx - t), 0, hz - t), 18, 4.2, 0.5, 0.0)
		var fb := Basis(Vector3.UP, 0.0 if sf < 0.0 else PI)
		for i in 22:
			var x := -hx + t + 2.0 + (hx * 2.0 - t * 2.0 - 4.0) * float(i) / 21.0
			lm.merge(bud, Transform3D(fb, c + Vector3(x, 0.4, sf * (hz - t * 0.5 - 1.2))))
		var sb := Basis(Vector3.UP, -PI * 0.5 * sf)
		for i in 14:
			var z := -hz + t + 2.0 + (hz * 2.0 - t * 2.0 - 4.0) * float(i) / 13.0
			lm.merge(bud, Transform3D(sb, c + Vector3(sf * (hx - t * 0.5 - 1.2), 0.4, z)))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var half := hz if side % 2 == 0 else hx
		var vc := c + b * Vector3(0, 0, half - t * 0.5)
		lm.box("Stone", vc + Vector3(0, 0.4, 0), Vector3(12.0, 0.8, 16.0), b)
		lm.box("Wall", vc + Vector3(0, 3.6, 0), Vector3(10.0, 5.6, 14.0), b)
		K.thai_window(lm, "Wall", "Dark", "Gold", vc + b * Vector3(0, 0.8, 7.02), b, 2.2, 4.0)
		K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", vc + Vector3(0, 6.4, 0), b, 11.0, 16.0, 3.6, 1.0, 1, 0, 1.6)
