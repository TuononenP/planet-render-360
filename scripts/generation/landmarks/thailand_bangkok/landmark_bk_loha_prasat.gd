class_name LandmarkBkLohaPrasat
extends RefCounted

## Loha Prasat (Wat Ratchanatdaram / โลหะปราสาท วัดราชนัดดาราม) — Bangkok BK-2.4
## Site: OSM way 103097698 (13.754813, 100.504163, 39.5 x 38.9 m, axis 15 deg) plus
## Maha Chetsadabodin Royal Pavilion (`way:560754640`) & ceremonial plaza (`way:560594892`)
## immediately NNE toward Ratchadamnoen Klang.
## Spec (Rama III 1846, spires gilded 2014-17, Fine Arts Dept / Commons refs):
##   - Total height: 36.0 m to the central relic mondop spire tip.
##   - Square stepped pyramid of 3 concentric colonnaded whitewashed storeys:
##       Tier 1 (ground): 38.6 x 38.6 m, open square pillar arcades around perimeter, 24 spires on roof corners/bays.
##       Tier 2 (middle): 26.2 x 26.2 m, open arcaded gallery, 12 spires on roof ring.
##       Tier 3 (upper):  14.0 x 14.0 m, relic sanctuary pavilion crowned by the tallest 37th central gilt spire.
##   - Total metallic gilded spires: 24 + 12 + 1 = 37 slender prasat spires with 4 gilded flame
##     gable pediments around every mondop base over dark-bronze/red-brown eaves.
##   - Forecourt (+17.2 X, -93.8 Z at yaw 15 deg): paved Maha Chetsadabodin plaza with manicured
##     side lawns, Thai royal reception pavilion, and King Rama III seated bronze memorial statue.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 36.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F3F0E7", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD6C7", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#5A3828", 2.0, 0.55, 0.25))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D9661F", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2F7F5A", 2.0))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#38682E", 3.5, 0.9, 0.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4E3E30", 2.0, 0.42, 0.6))
	lm.use("Dark", LandmarkMaterials.paint("#231D1A", 0.9, 0.05))

	_loha_prasat(lm)
	_chetsadabodin_court(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 26.0), Vector3(0.0, 20.0, 0.0), 52.0, 1.35, 48.0, Color(1.0, 0.88, 0.58)],
		[Vector3(0.0, 2.0, -26.0), Vector3(0.0, 20.0, 0.0), 52.0, 1.35, 48.0, Color(1.0, 0.88, 0.58)],
		[Vector3(26.0, 2.0, 0.0), Vector3(0.0, 20.0, 0.0), 52.0, 1.35, 48.0, Color(1.0, 0.88, 0.58)],
		[Vector3(-26.0, 2.0, 0.0), Vector3(0.0, 20.0, 0.0), 52.0, 1.35, 48.0, Color(1.0, 0.88, 0.58)],
		[Vector3(17.2, 1.5, -72.0), Vector3(17.2, 9.0, -93.8), 45.0, 0.95, 36.0, Color(1.0, 0.90, 0.68)],
	])

static func _loha_prasat(lm: LandmarkMesh) -> void:
	K.plinth(lm, "Stone", Vector3.ZERO, Basis(), 41.0, 41.0, 1.6)
	for side in 4:
		var sb := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.stairs(lm, "Stone", sb * Vector3(0, 1.6, 20.8), sb, 4.6, 6, 0.34, 0.267)

	_arcaded_tier(lm, 1.6, 38.4, 6.6, 9)
	_arcaded_tier(lm, 8.2, 25.6, 6.4, 5)
	_arcaded_tier(lm, 14.6, 13.2, 6.6, 3)

	var spire_sm := _make_spire(2.2, 7.8)
	var spire_md := _make_spire(2.45, 8.8)

	# Ring 1: 24 spires around outer roof terrace (y = 8.2 m)
	for pos2 in _perimeter_ring(17.2, 6):
		lm.merge(spire_sm, Transform3D(Basis(), Vector3(pos2.x, 8.2, pos2.y)))

	# Ring 2: 12 spires around middle roof terrace (y = 14.6 m)
	for pos2 in _perimeter_ring(10.9, 3):
		lm.merge(spire_md, Transform3D(Basis(), Vector3(pos2.x, 14.6, pos2.y)))

	# Central 37th spire crowning Tier 3 from y = 21.2 m cleanly to HEIGHT_M = 36.0 m
	var top_spire := _make_spire(4.4, HEIGHT_M - 21.2)
	lm.merge(top_spire, Transform3D(Basis(), Vector3(0, 21.2, 0)))

static func _arcaded_tier(lm: LandmarkMesh, y0: float, w: float, h: float, bays: int) -> void:
	var inset := 2.4
	lm.box("Dark", Vector3(0, y0 + h * 0.48, 0), Vector3(w - inset * 1.4, h * 0.92, w - inset * 1.4), Basis(), 0.0)
	lm.box("Wall", Vector3(0, y0 + h * 0.48, 0), Vector3(w - inset * 2.2, h * 0.94, w - inset * 2.2))
	var half := w * 0.5 - 0.55
	var col_h := h - 1.05
	var step := (half * 2.0) / float(bays)
	for i in bays + 1:
		var u := -half + step * float(i)
		for s in [-1.0, 1.0]:
			lm.box("Wall", Vector3(u, y0 + col_h * 0.5, float(s) * half), Vector3(0.85, col_h, 0.85), Basis(), 0.0)
			if i > 0 and i < bays:
				lm.box("Wall", Vector3(float(s) * half, y0 + col_h * 0.5, u), Vector3(0.85, col_h, 0.85), Basis(), 0.0)
	lm.box("Wall", Vector3(0, y0 + h - 0.65, 0), Vector3(w, 0.85, w))
	lm.spire("Roof", Vector3(0, y0 + h - 0.55, 0), w * 0.53, 0.55, w * 0.49, 4)
	lm.box("Gold", Vector3(0, y0 + h - 0.58, 0), Vector3(w * 1.05, 0.14, w * 1.05))
	lm.box("Stone", Vector3(0, y0 + h + 0.18, 0), Vector3(w * 0.96, 0.36, w * 0.96))

static func _perimeter_ring(r: float, segs_per_side: int) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var corners := [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		for k in segs_per_side:
			pts.append(a.lerp(b, float(k) / float(segs_per_side)))
	return pts

static func _make_spire(base_w: float, h: float) -> LandmarkMesh:
	var sub := LandmarkMesh.new()
	for k in ["Wall", "Roof", "Gold", "Dark"]:
		sub.use(k, LandmarkMaterials.gold())
	# White square mondop turret base with 4 recessed red-dark windows & 4 golden flame pediments!
	var bh := h * 0.27
	sub.box("Wall", Vector3(0, bh * 0.5, 0), Vector3(base_w, bh, base_w))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		sub.box("Dark", b * Vector3(0, bh * 0.46, base_w * 0.51), Vector3(base_w * 0.36, bh * 0.56, 0.08), b, 0.0)
		K.outline_prism(sub, "Gold", b * Vector3(0, bh * 0.78, base_w * 0.53), b,
			K.flame_outline(base_w * 0.78, bh * 0.52), 0.12)
	# Gilded eave collar + multi-tier gilded metallic prasat spire needle
	sub.spire("Gold", Vector3(0, bh, 0), base_w * 0.66, h * 0.10, base_w * 0.44, 4)
	var sy := bh + h * 0.10
	var sh := h - sy
	K.redent_lathe(sub, "Gold", Vector3(0, sy, 0), PackedVector2Array([
		Vector2(base_w * 0.44, 0.0), Vector2(base_w * 0.36, sh * 0.18),
		Vector2(base_w * 0.41, sh * 0.22), Vector2(base_w * 0.28, sh * 0.40),
		Vector2(base_w * 0.32, sh * 0.44), Vector2(base_w * 0.19, sh * 0.62),
		Vector2(base_w * 0.10, sh * 0.78), Vector2(base_w * 0.035, sh * 0.91),
		Vector2(0.0, sh)]), 0.14, 0.0, 1)
	return sub

static func _chetsadabodin_court(lm: LandmarkMesh) -> void:
	var pc := Vector3(17.2, 0.0, -93.8)
	# Stepped stone courtyard paved axis framed by manicured green lawn beds & low white kerb
	lm.box("Stone", pc + Vector3(-1.5, 0.14, 11.0), Vector3(32.0, 0.28, 56.0))
	for sx in [-12.5, 12.5]:
		lm.box("Grass", pc + Vector3(-1.5 + sx, 0.31, 8.0), Vector3(5.2, 0.08, 44.0))
		lm.box("Wall", pc + Vector3(-1.5 + sx * 1.24, 0.42, 8.0), Vector3(0.45, 0.36, 46.0))
	var hk := {"wall": "Wall", "stone": "Stone", "tile": "Orange", "border": "Green", "gold": "Gold", "dark": "Dark", "col": "Wall"}
	K.thai_hall(lm, hk, pc, Basis(), 10.5, 18.5, 5.2, 5, 2.0, 2, 1, 4.2, 1.1)
	var sc := pc + Vector3(0.0, 0.28, -19.5)
	K.plinth(lm, "Stone", sc, Basis(Vector3.UP, PI), 6.2, 6.2, 2.2)
	K.seated_buddha(lm, "Bronze", sc + Vector3(0, 2.2, 0), Basis(Vector3.UP, PI), 3.4)
	for sx in [-3.4, 3.4]:
		K2.royal_umbrella(lm, "Gold", "Bronze", sc + Vector3(sx, 0.0, 0.0), 5.2, 5)
