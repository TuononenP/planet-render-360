class_name LandmarkMiSpanishMonastery
extends RefCounted

## Ancient Spanish Monastery (St. Bernard de Clairvaux), North Miami Beach (MI-10).
## 58 x 44 m: 12th-century Segovian Romanesque/Gothic honey-gold limestone.
##   - Cloister arcades round a lush courtyard garden with a central wellhead.
##   - Church (north), chapter house (east) and refectory (west) with clay barrel-tile roofs.
##   - Stone bell-cote turret on the church front gable reaching y = 16.0 m.

const HEIGHT_M := 16.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#D9BC86", 2.6))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C9AD7A", 2.4))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B5603C", 2.0))
	lm.use("Garden", LandmarkMaterials.pbr("grass", "#3F7A33", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A231C", 0.8, 0.0))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#386B2E", 2.0))

	_build_church(lm)
	_build_wings(lm)
	_build_cloister(lm)
	_build_garden(lm)
	lm.commit(model)

static func _build_church(lm: LandmarkMesh) -> void:
	# Nave: x -7..7, z -22..-6, walls to y = 10, gable ridge at 13.5
	lm.box("Limestone", Vector3(0.0, 5.0, -14.0), Vector3(14.0, 10.0, 16.0), Basis(), 0.0)
	lm.gable("Tile", Vector3(0.0, 10.0, -14.0), 14.0, 16.0, 3.5, Basis(), 0.5, "Limestone")
	# Buttresses
	for sx: float in [-1.0, 1.0]:
		for k: int in 4:
			lm.box("Stone", Vector3(sx * 7.35, 4.0, -21.0 + float(k) * 4.6), Vector3(0.9, 8.0, 1.0), Basis(), 0.0)
		# Narrow lancet windows
		for k: int in 3:
			lm.box("Dark", Vector3(sx * 7.04, 6.2, -19.0 + float(k) * 4.6), Vector3(0.12, 3.0, 0.9), Basis(), 0.0)
	# Romanesque west portal: stepped recessed arches
	for k: int in 3:
		var r := 2.2 - float(k) * 0.55
		lm.box("Dark" if k == 2 else "Stone", Vector3(0.0, 2.4, -5.9 + float(k) * 0.05), Vector3(r * 2.0, 4.8, 0.2), Basis(), 0.0)
		lm.disc("Dark" if k == 2 else "Stone", Vector3(0.0, 4.8, -5.8 + float(k) * 0.05), Vector3(0, 0, 1), r, 20)
	# Rose window
	lm.disc("Dark", Vector3(0.0, 8.2, -5.9), Vector3(0, 0, 1), 1.0, 20)
	# Bell-cote turret on the front gable, top exactly 16.0 m
	lm.box("Limestone", Vector3(0.0, 12.6, -6.4), Vector3(2.6, 5.2, 1.0), Basis(), 0.0)
	lm.box("Dark", Vector3(-0.6, 13.2, -5.88), Vector3(0.7, 1.8, 0.1), Basis(), 0.0)
	lm.box("Dark", Vector3(0.6, 13.2, -5.88), Vector3(0.7, 1.8, 0.1), Basis(), 0.0)
	lm.spire("Stone", Vector3(0.0, 15.2, -6.4), 1.3, 0.8, 0.0, 4)
	# Apse
	lm.frustum("Limestone", Vector3(0.0, 0.0, -22.0), 5.0, 5.0, 8.0, 12)
	lm.frustum("Tile", Vector3(0.0, 8.0, -22.0), 5.6, 0.2, 3.2, 12)

static func _build_wings(lm: LandmarkMesh) -> void:
	# Chapter house (east, x 14..29) and refectory (west, x -29..-14), z -6..12
	for sx: float in [-1.0, 1.0]:
		var cx := sx * 21.5
		lm.box("Limestone", Vector3(cx, 3.5, 3.0), Vector3(15.0, 7.0, 18.0), Basis(), 0.0)
		lm.gable("Tile", Vector3(cx, 7.0, 3.0), 15.0, 18.0, 2.6, Basis(), 0.5, "Limestone")
		for k: int in 4:
			lm.box("Dark", Vector3(cx + sx * 7.54, 4.0, -1.0 + float(k) * 4.4), Vector3(0.12, 2.6, 0.9), Basis(), 0.0)
		lm.box("Stone", Vector3(cx, 0.3, 3.0), Vector3(15.6, 0.6, 18.6), Basis(), 0.0)
	# South range + gatehouse
	lm.box("Limestone", Vector3(0.0, 3.2, 20.0), Vector3(58.0, 6.4, 4.0), Basis(), 0.0)
	lm.gable("Tile", Vector3(0.0, 6.4, 20.0), 4.0, 58.0, 1.6, Basis(Vector3.UP, PI * 0.5), 0.3, "Limestone")
	lm.box("Dark", Vector3(0.0, 2.0, 18.0), Vector3(3.0, 4.0, 0.2), Basis(), 0.0)
	lm.disc("Dark", Vector3(0.0, 4.0, 17.95), Vector3(0, 0, 1), 1.5, 18)

static func _build_cloister(lm: LandmarkMesh) -> void:
	_arcade(lm, Vector2(-13.0, -4.5), Vector2(13.0, -4.5), Vector2(0.0, -1.0))
	_arcade(lm, Vector2(-13.0, 16.5), Vector2(13.0, 16.5), Vector2(0.0, 1.0))
	_arcade(lm, Vector2(-13.0, -4.5), Vector2(-13.0, 16.5), Vector2(-1.0, 0.0))
	_arcade(lm, Vector2(13.0, -4.5), Vector2(13.0, 16.5), Vector2(1.0, 0.0))

static func _arcade(lm: LandmarkMesh, a: Vector2, b: Vector2, outward: Vector2) -> void:
	var length := a.distance_to(b)
	var bays := int(round(length / 3.6))
	var dir := (b - a) / length
	var bay_w := length / float(bays)
	var out3 := Vector3(outward.x, 0.0, outward.y)
	var spring := 2.6
	var r := bay_w * 0.5 - 0.15
	for i: int in bays + 1:
		var p := a + dir * (bay_w * float(i))
		lm.frustum("Stone", Vector3(p.x, 0.0, p.y), 0.30, 0.24, spring, 8)
		lm.box("Stone", Vector3(p.x, spring + 0.1, p.y), Vector3(0.6, 0.2, 0.6), Basis(), 0.0)
	for i: int in bays:
		var m := a + dir * (bay_w * (float(i) + 0.5))
		var prev := Vector3.ZERO
		for j: int in 7:
			var t := PI * float(j) / 6.0
			var pt := Vector3(m.x - dir.x * cos(t) * r, spring + 0.2 + sin(t) * r, m.y - dir.y * cos(t) * r)
			if j > 0:
				lm.beam("Stone", prev, pt, 0.34, 0.5, out3)
			prev = pt
	# Entablature, lean-to barrel-tile roof sloping away from the courtyard
	var mid := (a + b) * 0.5
	var basis := Basis(Vector3(dir.x, 0.0, dir.y), Vector3.UP, out3)
	lm.box("Limestone", Vector3(mid.x, 4.3, mid.y), Vector3(length + 0.8, 0.5, 0.7), basis, 0.0)
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", a - dir * 0.4, b + dir * 0.4, 4.0, 5.8, 2.6, -outward)
	lm.box("Limestone", Vector3(mid.x + outward.x * 1.3, 2.9, mid.y + outward.y * 1.3),
		Vector3(length if absf(dir.x) > 0.5 else 0.7, 5.8, 0.7 if absf(dir.x) > 0.5 else length), Basis(), 0.0)

static func _build_garden(lm: LandmarkMesh) -> void:
	lm.box("Garden", Vector3(0.0, 0.05, 6.0), Vector3(24.8, 0.2, 20.0), Basis(), 0.0)
	# Cross paths and well
	lm.box("Stone", Vector3(0.0, 0.14, 6.0), Vector3(1.6, 0.1, 20.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0.0, 0.14, 6.0), Vector3(24.8, 0.1, 1.6), Basis(), 0.0)
	lm.frustum("Stone", Vector3(0.0, 0.1, 6.0), 1.15, 1.0, 1.0, 14)
	lm.frustum("Dark", Vector3(0.0, 1.05, 6.0), 0.8, 0.8, 0.05, 14)
	for sx: float in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 0.95, 1.8, 6.0), Vector3(0.18, 1.6, 0.18), Basis(), 0.0)
	lm.box("Stone", Vector3(0.0, 2.65, 6.0), Vector3(2.1, 0.18, 0.3), Basis(), 0.0)
	for k: int in 4:
		var sx: float = -1.0 if k % 2 == 0 else 1.0
		var sz: float = -1.0 if k < 2 else 1.0
		LandmarkMiKit.royal_palm(lm, "Stone", "PalmFrond", Vector3(sx * 7.0, 0.1, 6.0 + sz * 6.0), 8.0, float(k))
