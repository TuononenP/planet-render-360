class_name LandmarkMseVietnam
extends RefCounted

## Vietnam in true metres: the Temple of Literature in Hanoi (gate courts,
## the Khue Van Cac pavilion, stele houses and the two sanctuary halls),
## the One Pillar Pagoda, the Ngo Mon Gate of the Imperial City of Hue and
## Saigon Notre-Dame Cathedral. Gates and halls face south (+Z).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

const PILLAR_M := 9.4
const NGO_MON_M := 17.0
const NOTRE_DAME_M := 58.0

## Curved hip roof (LandmarkAeParts) with a soffit slab under the eaves.
static func _hip(lm: LandmarkMesh, key: String, c: Vector3, eave: Vector2, top: Vector2, rise: float,
		lift: float) -> void:
	LandmarkAeParts.hip_roof(lm, key, c, eave, top, rise, lift)
	lm.box(key, c + Vector3(0, lift - 0.25, 0), Vector3(eave.x - 0.6, 0.3, eave.y - 0.6))

## Brick wall run a..b, 3.6 m with a tiled cap.
static func _wall(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	var m := (a + b) * 0.5
	lm.box("Brick", m + Vector3(0, 1.8, 0), Vector3(0.9, 3.6, d.length()), basis)
	lm.box("Tile", m + Vector3(0, 3.75, 0), Vector3(1.5, 0.3, d.length() + 0.2), basis)

## Three-bay tiled gate (central archway under a two-tier roof, a lower
## bay on each side) at ground point `c`, facing +Z, scaled by `sc`.
static func _gate(lm: LandmarkMesh, c: Vector3, sc: float) -> void:
	var h := 5.2 * sc
	LandmarkAsiaSouthUtil.arch_wall(lm, "Brick", c, Basis(), 8.0 * sc, h, 5.0 * sc, 3.6 * sc, 4.2 * sc)
	for s in [-1.0, 1.0]:
		var sc_c := c + Vector3(s * 6.25 * sc, 0, 0)
		LandmarkAsiaSouthUtil.arch_wall(lm, "Brick", sc_c, Basis(), 4.5 * sc, 4.0 * sc, 4.4 * sc, 2.0 * sc, 3.0 * sc)
		_hip(lm, "Tile", sc_c + Vector3(0, 4.0 * sc, 0), Vector2(6.2, 6.0) * sc, Vector2(3.0, 1.6) * sc,
			1.5 * sc, 0.5 * sc)
	_hip(lm, "Tile", c + Vector3(0, h, 0), Vector2(11.0, 7.6) * sc, Vector2(6.4, 3.4) * sc, 2.0 * sc, 0.6 * sc)
	lm.box("Red", c + Vector3(0, h + 2.4 * sc, 0), Vector3(5.6, 2.0, 3.4) * sc)
	_hip(lm, "Tile", c + Vector3(0, h + 3.4 * sc, 0), Vector2(7.6, 5.0) * sc, Vector2(2.6, 0.8) * sc,
		2.0 * sc, 0.7 * sc)
	lm.box("Gold", c + Vector3(0, h + 5.8 * sc, 0), Vector3(0.6, 0.8, 0.6) * sc)

# --- Temple of Literature ---

## Temple of Literature: from the Van Mieu gate in the south through the
## Dai Trung gate, the Khue Van Cac pavilion on its gate, the Dai Thanh
## gate, the Thien Quang well between two stele houses, to the Dai Bai
## Duong hall and the Hau Cung sanctuary hall at the north end.
static func temple_of_literature(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8573A", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4A30", 2.0))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#A52A22", 2.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#E8E3D6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E877A", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#3F5A4A"))
	var hw := 34.0
	_wall(lm, Vector3(-hw, 0, -140), Vector3(-hw, 0, 115))
	_wall(lm, Vector3(hw, 0, -140), Vector3(hw, 0, 115))
	_wall(lm, Vector3(-hw, 0, -140), Vector3(hw, 0, -140))
	for e in [[115.0, 8.5], [60.0, 7.2], [0.0, 5.5], [-62.0, 7.2]]:
		_wall(lm, Vector3(-hw, 0, float(e[0])), Vector3(-float(e[1]), 0, float(e[0])))
		_wall(lm, Vector3(float(e[1]), 0, float(e[0])), Vector3(hw, 0, float(e[0])))
	_gate(lm, Vector3(0, 0, 115), 1.0)
	for s in [-1.0, 1.0]:
		for dx in [4.5, 9.5]:
			lm.box("Stone", Vector3(s * (8.5 + dx), 3.2, 118.0), Vector3(0.9, 6.4, 0.9))
			lm.spire("Gold", Vector3(s * (8.5 + dx), 6.4, 118.0), 0.45, 0.9, 0.1)
	_gate(lm, Vector3(0, 0, 60), 0.85)
	_khue_van_cac(lm, Vector3(0, 0, 0))
	_gate(lm, Vector3(0, 0, -62), 0.85)
	# Thien Quang well and the two long stele houses.
	lm.box("Stone", Vector3(0, 0.5, -31), Vector3(13.0, 1.0, 13.0))
	lm.box("Water", Vector3(0, 0.95, -31), Vector3(10.6, 0.15, 10.6))
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 16.5, 0, -31)
		lm.box("Stone", c + Vector3(0, 0.3, 0), Vector3(5.6, 0.6, 40.0))
		for r in [-1.0, 1.0]:
			U.posts(lm, "Red", c + Vector3(r * 2.4, 0.6, -18.0), c + Vector3(r * 2.4, 0.6, 18.0), 10, 3.4, 0.4)
		U.swept_roof(lm, "Tile", "Brick", "", c + Vector3(0, 4.0, 0), Basis(), 5.0, 40.0, 1.9, 0.8, 0.8, 0.3)
	_hall(lm, Vector3(0, 0, -96), 28.0, 12.0, 5.2, 4.0)
	_hall(lm, Vector3(0, 0, -128), 22.0, 11.0, 5.8, 4.4)
	lm.commit(model)

## Khue Van Cac, the Constellation of Literature Pavilion: a brick gate
## carrying four whitewashed stone pillars, the red timber pavilion with
## round windows and two stacked curved roofs (12.3 m).
static func _khue_van_cac(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkAsiaSouthUtil.arch_wall(lm, "Brick", c, Basis(), 11.0, 3.2, 5.0, 3.0, 2.8)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("White", c + Vector3(sx * 2.3, 4.9, sz * 2.3), Vector3(0.9, 3.4, 0.9))
	lm.box("Red", c + Vector3(0, 6.75, 0), Vector3(7.0, 0.3, 7.0))
	lm.box("Red", c + Vector3(0, 8.0, 0), Vector3(6.0, 2.2, 6.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.disc("Gold", c + b * Vector3(0, 8.0, 3.03), b * Vector3(0, 0, 1), 0.85, 16)
	_hip(lm, "Tile", c + Vector3(0, 9.1, 0), Vector2(8.6, 8.6), Vector2(5.0, 5.0), 1.0, 0.6)
	lm.box("Red", c + Vector3(0, 10.2, 0), Vector3(3.4, 1.4, 3.4))
	_hip(lm, "Tile", c + Vector3(0, 10.9, 0), Vector2(5.6, 5.6), Vector2(0.8, 0.8), 1.3, 0.5)
	lm.spire("Gold", c + Vector3(0, 12.2, 0), 0.25, 0.5, 0.0)

## A sanctuary hall: stone base, brick back and side walls, a red-pillared
## open front and one long up-swept tiled roof, ridge across X.
static func _hall(lm: LandmarkMesh, c: Vector3, w: float, d: float, col_h: float, rise: float,
		lift: float = 1.4) -> void:
	lm.box("Stone", c + Vector3(0, 0.6, 0), Vector3(w + 4.0, 1.2, d + 4.0))
	lm.box("Brick", c + Vector3(0, 1.2 + col_h * 0.5, -d * 0.5 + 0.5), Vector3(w, col_h, 1.0))
	for s in [-1.0, 1.0]:
		lm.box("Brick", c + Vector3(s * (w * 0.5 - 0.5), 1.2 + col_h * 0.5, 0), Vector3(1.0, col_h, d))
	lm.box("Dark", c + Vector3(0, 1.2 + col_h * 0.45, d * 0.5 - 1.8), Vector3(w - 2.0, col_h * 0.9, 0.2))
	U.posts(lm, "Red", c + Vector3(-w * 0.5 + 0.5, 1.2, d * 0.5 - 0.7), c + Vector3(w * 0.5 - 0.5, 1.2, d * 0.5 - 0.7),
		int(w / 2.6) + 1, col_h, 0.6)
	U.swept_roof(lm, "Tile", "Brick", "Brick", c + Vector3(0, 1.2 + col_h, 0), Basis(Vector3.UP, PI * 0.5),
		d, w, rise, lift, 1.4, 0.3)

# --- One Pillar Pagoda ---

## One Pillar Pagoda (Chua Mot Cot): the lotus-bud shrine of red posts
## under a curved four-corner roof on a single stone pillar in the square
## lotus pond, its steep stair, and the Dien Huu temple halls behind a
## tiled gate and walls.
static func one_pillar_pagoda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A8478", 3.0))
	lm.use("Water", LandmarkMaterials.glass("#3F5A4A"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6E4A32", 2.0))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#A52A22", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4A30", 2.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8573A", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var pr := 8.0
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, 0.45, s * pr), Vector3(pr * 2.0 + 1.0, 0.9, 1.0))
		lm.box("Stone", Vector3(s * pr, 0.45, 0), Vector3(1.0, 0.9, pr * 2.0 - 1.0))
	lm.box("Water", Vector3(0, 0.2, 0), Vector3(pr * 2.0 - 1.0, 0.4, pr * 2.0 - 1.0))
	# The pillar (1.25 m across) with its lotus capital, the shrine on top.
	lm.lathe("Stone", Vector3.ZERO, PackedVector2Array([Vector2(0.72, 0), Vector2(0.63, 1.0), Vector2(0.62, 3.2),
		Vector2(0.78, 3.6), Vector2(1.0, 3.9)]), 16)
	lm.lathe("Stone", Vector3(0, 3.9, 0), PackedVector2Array([Vector2(0.95, 0), Vector2(1.45, 0.3),
		Vector2(1.35, 0.55), Vector2(1.0, 0.7)]), 16)
	lm.box("Wood", Vector3(0, 4.7, 0), Vector3(3.6, 0.3, 3.6))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Red", Vector3(sx * 1.45, 5.85, sz * 1.45), Vector3(0.22, 2.0, 0.22))
	lm.box("Dark", Vector3(0, 5.85, -1.4), Vector3(2.6, 1.9, 0.15))
	_hip(lm, "Tile", Vector3(0, 6.85, 0), Vector2(5.6, 5.6), Vector2(0.9, 0.9), 1.4, 0.5)
	lm.lathe("Gold", Vector3(0, 8.3, 0), PackedVector2Array([Vector2(0.28, 0), Vector2(0.4, 0.35),
		Vector2(0.2, 0.7), Vector2(0.0, PILLAR_M - 8.3)]), 8)
	U.stairs(lm, "Stone", Vector3(0, 0, 2.2), Basis(), 1.6, 14, 0.4, 4.55 / 14.0)
	# Dien Huu temple: main hall, side halls, gate and the walls.
	_hall(lm, Vector3(0, 0, -17), 14.0, 8.0, 3.6, 2.6, 1.0)
	for s in [-1.0, 1.0]:
		_hall(lm, Vector3(s * 14.0, 0, -6), 7.0, 6.0, 3.0, 2.0, 0.8)
		_wall(lm, Vector3(s * 19.0, 0, 18.0), Vector3(s * 19.0, 0, -24.0))
		_wall(lm, Vector3(s * 19.0, 0, 18.0), Vector3(s * 4.6, 0, 18.0))
	_wall(lm, Vector3(-19, 0, -24.0), Vector3(19.0, 0, -24.0))
	_gate(lm, Vector3(0, 0, 18.0), 0.6)
	lm.commit(model)

# --- Ngo Mon Gate ---

## Ngo Mon (17 m): the U-shaped red-brick and stone base 57 m wide, five
## gateways (three in the main wall, one through each wing), the five-
## phoenix pavilion on top, a double-roofed hall in the middle and a
## hipped hall on each wing, all under imperial yellow tiles. Faces south.
static func ngo_mon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Base", LandmarkMaterials.pbr("stone", "#A8573F", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CFB8", 3.0))
	lm.use("Yellow", LandmarkMaterials.pbr("terracotta", "#D8A92A", 2.0))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#A3261E", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	var z0 := -7.75
	var mc := Vector3(0, 0, z0)
	LandmarkAsiaSouthUtil.arch_wall(lm, "Base", mc, Basis(), 10.0, 5.0, 12.0, 4.2, 4.2)
	for s in [-1.0, 1.0]:
		LandmarkAsiaSouthUtil.arch_wall(lm, "Base", mc + Vector3(s * 9.25, 0, 0), Basis(), 8.5, 5.0, 12.0, 3.2, 3.8)
		lm.box("Base", mc + Vector3(s * 16.0, 2.5, 0), Vector3(5.0, 5.0, 12.0))
		var wc := Vector3(s * 23.5, 0, 6.0)
		LandmarkAsiaSouthUtil.arch_wall(lm, "Base", wc, Basis(Vector3.UP, PI * 0.5), 15.5, 5.0, 10.0, 3.2, 3.8)
		lm.box("Stone", wc + Vector3(0, 5.2, 0), Vector3(10.6, 0.4, 16.1))
		U.stairs(lm, "Stone", Vector3(s * 12.0, 0, z0 - 6.0), Basis(Vector3.UP, PI), 3.4, 10, 0.6, 0.54)
	lm.box("Stone", mc + Vector3(0, 5.2, 0), Vector3(58.6, 0.4, 12.6))
	var py := 5.4
	# Central hall: colonnade, then the two-tier five-phoenix roof.
	lm.box("Dark", mc + Vector3(0, py + 2.0, 0), Vector3(25.0, 3.8, 8.4))
	for i in 11:
		for r in [-1.0, 1.0]:
			lm.box("Red", mc + Vector3(-13.0 + 2.6 * float(i), py + 2.1, r * 4.5), Vector3(0.5, 4.2, 0.5))
	lm.box("Red", mc + Vector3(0, py + 4.35, 0), Vector3(27.0, 0.6, 9.8))
	_hip(lm, "Yellow", mc + Vector3(0, py + 4.5, 0), Vector2(31.0, 14.0), Vector2(17.0, 5.0), 2.6, 0.8)
	lm.box("Red", mc + Vector3(0, 12.2, 0), Vector3(16.0, 2.4, 5.0))
	_hip(lm, "Yellow", mc + Vector3(0, 13.4, 0), Vector2(21.0, 9.5), Vector2(9.0, 1.4), 3.1, 0.9)
	for s in [-1.0, 1.0]:
		lm.box("Gold", mc + Vector3(s * 4.2, 16.75, 0), Vector3(1.0, 0.5, 1.0))
		# Galleries and wing pavilions.
		var gc := mc + Vector3(s * 16.5, 0, 0)
		lm.box("Dark", gc + Vector3(0, py + 1.8, 0), Vector3(6.0, 3.6, 5.0))
		_hip(lm, "Yellow", gc + Vector3(0, py + 3.6, 0), Vector2(8.0, 10.5), Vector2(4.0, 3.0), 1.4, 0.6)
		var pc := Vector3(s * 23.5, py, 6.0)
		lm.box("Dark", pc + Vector3(0, 2.0, 0), Vector3(8.0, 4.0, 12.0))
		for i in 4:
			for r in [-1.0, 1.0]:
				lm.box("Red", pc + Vector3(r * 4.1, 2.0, -5.4 + 3.6 * float(i)), Vector3(0.5, 4.0, 0.5))
		_hip(lm, "Yellow", pc + Vector3(0, 4.0, 0), Vector2(11.4, 15.6), Vector2(4.4, 8.0), 2.9, 0.8)
	lm.commit(model)

# --- Saigon Notre-Dame ---

## Notre-Dame Cathedral Basilica of Saigon (58 m): red Marseille brick
## Romanesque, about 83 m long, a gabled nave with lower aisles and a transept, a
## round apse and the two square towers of the west front with belfries
## and slim steel spires carrying crosses. Faces +Z (the front).
static func saigon_notre_dame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B04A30", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBFA6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B5573A", 2.0))
	lm.use("Steel", LandmarkMaterials.paint("#5A6068", 0.5, 0.6))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A60"))
	# Nave, aisles, transept, apse.
	lm.box("Brick", Vector3(0, 10.5, 0), Vector3(22.0, 21.0, 62.0))
	U.swept_roof(lm, "Roof", "", "Brick", Vector3(0, 21.0, 0), Basis(), 21.0, 62.0, 8.6, 0.0, 0.6)
	for s in [-1.0, 1.0]:
		lm.box("Brick", Vector3(s * 14.0, 5.5, 0), Vector3(7.0, 11.0, 62.0))
		U.swept_roof(lm, "Roof", "", "Brick", Vector3(s * 14.0, 11.0, 0), Basis(), 6.4, 62.0, 3.0, 0.0, 0.5)
		for i in 8:
			lm.box("Dark", Vector3(s * 17.55, 6.0, -26.0 + 7.5 * float(i)), Vector3(0.15, 4.6, 1.5))
			lm.box("Dark", Vector3(s * 11.05, 16.0, -26.0 + 7.5 * float(i)), Vector3(0.15, 5.0, 1.6))
	lm.box("Brick", Vector3(0, 8.0, -12.0), Vector3(48.0, 16.0, 12.0))
	U.swept_roof(lm, "Roof", "", "Brick", Vector3(0, 16.0, -12.0), Basis(Vector3.UP, PI * 0.5), 12.0, 48.0, 5.0, 0.0, 0.6)
	lm.frustum("Brick", Vector3(0, 0, -31.0), 10.5, 10.5, 21.0, 16)
	lm.frustum("Roof", Vector3(0, 21.0, -31.0), 11.0, 0.0, 6.5, 16)
	# West front: the gable between the towers, portals and the rose window.
	lm.box("Brick", Vector3(0, 12.0, 37.5), Vector3(13.0, 24.0, 9.0))
	lm.box("Stone", Vector3(0, 24.2, 37.5), Vector3(13.6, 0.5, 9.6))
	lm.box("Dark", Vector3(0, 4.2, 42.05), Vector3(4.2, 7.0, 0.2))
	lm.box("Stone", Vector3(0, 7.9, 42.1), Vector3(5.4, 0.7, 0.2))
	lm.disc("Glass", Vector3(0, 17.0, 42.1), Vector3(0, 0, 1), 3.2, 16)
	lm.box("Stone", Vector3(0, 17.0, 42.05), Vector3(7.0, 0.4, 0.15))
	for s in [-1.0, 1.0]:
		_nd_tower(lm, Vector3(s * 12.0, 0, 36.25))
		lm.box("Dark", Vector3(s * 12.0, 3.0, 42.15), Vector3(2.2, 5.0, 0.2))
	lm.commit(model)

## One 58 m west tower on a 11.5 m square: stone plinth, brick shaft with
## lancet windows in three stages, string courses, a belfry with paired
## arched openings and corner pinnacles, the eight-sided steel spire
## and the cross on top.
static func _nd_tower(lm: LandmarkMesh, c: Vector3) -> void:
	var w := 11.5
	lm.box("Stone", c + Vector3(0, 1.0, 0), Vector3(w + 1.0, 2.0, w + 1.0))
	lm.box("Brick", c + Vector3(0, 20.0, 0), Vector3(w, 36.0, w))
	for y in [12.0, 22.0, 32.0]:
		lm.box("Stone", c + Vector3(0, y, 0), Vector3(w + 0.6, 0.5, w + 0.6))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for x in [-2.2, 2.2]:
				lm.box("Dark", c + b * Vector3(x, y + 3.0, w * 0.5 + 0.06), Vector3(0.9, 4.2, 0.15), b)
	lm.box("Stone", c + Vector3(0, 38.2, 0), Vector3(w + 1.0, 0.9, w + 1.0))
	lm.box("Brick", c + Vector3(0, 43.0, 0), Vector3(w - 0.6, 8.8, w - 0.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for x in [-2.3, 2.3]:
			lm.box("Dark", c + b * Vector3(x, 42.8, (w - 0.6) * 0.5 + 0.06), Vector3(1.8, 5.4, 0.15), b)
	lm.box("Stone", c + Vector3(0, 47.6, 0), Vector3(w + 0.8, 0.9, w + 0.8))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.spire("Brick", c + Vector3(sx * 4.8, 48.0, sz * 4.8), 0.6, 2.4, 0.0)
	lm.spire("Steel", c + Vector3(0, 48.0, 0), 4.4, 6.5, 0.3, 8)
	lm.beam("Steel", c + Vector3(0, 54.5, 0), c + Vector3(0, NOTRE_DAME_M, 0), 0.3, 0.3)
	lm.beam("Steel", c + Vector3(-0.8, 56.6, 0), c + Vector3(0.8, 56.6, 0), 0.3, 0.3)
