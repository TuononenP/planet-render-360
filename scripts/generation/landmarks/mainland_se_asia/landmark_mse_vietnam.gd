class_name LandmarkMseVietnam
extends RefCounted

## Vietnam in true metres: the Temple of Literature in Hanoi (gate courts,
## the Khue Van Cac pavilion, the 82 doctors' steles on their turtles in
## the stele houses by the Thien Quang well, and the two sanctuary
## halls), the One Pillar Pagoda and the Ngo Mon Gate of the Imperial
## City of Hue. Gates and halls face south (+Z).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const PILLAR_M := 9.4
const NGO_MON_M := 17.0

## Curved hip roof (LandmarkAeParts) with a soffit slab under the eaves,
## the four hip ridges and, when `ridge` > 0, a ridge roll with curled
## dragon ends `ridge` m tall.
static func _hip(lm: LandmarkMesh, key: String, c: Vector3, eave: Vector2, top: Vector2, rise: float,
		lift: float, ridge: float = 0.0) -> void:
	LandmarkAeParts.hip_roof(lm, key, c, eave, top, rise, lift)
	lm.box(key, c + Vector3(0, lift - 0.25, 0), Vector3(eave.x - 0.6, 0.3, eave.y - 0.6))
	var rw := clampf(eave.x * 0.025, 0.14, 0.4)
	LandmarkAeParts.hip_ridges(lm, key, c, eave, top, rise, lift, rw)
	if ridge > 0.0 and top.x > 1.0:
		var ry := c.y + rise + rw * 0.5
		lm.box(key, Vector3(c.x, ry, c.z), Vector3(top.x + 0.2, rw * 1.6, rw * 1.4), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			var e := Vector3(c.x + s * top.x * 0.5, ry, c.z)
			var prev := e
			for k in 4:
				var a := PI * 0.5 * float(k + 1) / 4.0
				var p := e + Vector3(s * ridge * 0.3 * (1.0 - cos(a)), ridge * sin(a), 0)
				lm.beam(key, prev, p, rw * 1.4, rw * 1.2)
				prev = p

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
			1.5 * sc, 0.5 * sc, 0.6 * sc)
		# Red lacquered doors in the archways.
		lm.box("Red", sc_c + Vector3(0, 1.0 * sc, -0.6 * sc), Vector3(2.0, 2.0, 0.12) * sc, Basis(), 0.0)
	lm.box("Red", c + Vector3(0, 1.6 * sc, -1.0 * sc), Vector3(3.6, 3.2, 0.12) * sc, Basis(), 0.0)
	_hip(lm, "Tile", c + Vector3(0, h, 0), Vector2(11.0, 7.6) * sc, Vector2(6.4, 3.4) * sc, 2.0 * sc, 0.6 * sc)
	lm.box("Red", c + Vector3(0, h + 2.4 * sc, 0), Vector3(5.6, 2.0, 3.4) * sc)
	lm.box("Gold", c + Vector3(0, h + 2.4 * sc, 1.72 * sc), Vector3(2.6, 0.9, 0.08) * sc, Basis(), 0.0)
	_hip(lm, "Tile", c + Vector3(0, h + 3.4 * sc, 0), Vector2(7.6, 5.0) * sc, Vector2(2.6, 0.8) * sc,
		2.0 * sc, 0.7 * sc, 0.8 * sc)
	lm.box("Gold", c + Vector3(0, h + 5.8 * sc, 0), Vector3(0.6, 0.8, 0.6) * sc)

## Doctors' stele on its tortoise, facing `b` Z: the tortoise's shell
## and head on a slab, the stone tablet with its rounded crest.
static func _stele(lm: LandmarkMesh, p: Vector3, b: Basis) -> void:
	lm.box("Stone", p + Vector3(0, 0.1, 0), Vector3(1.0, 0.2, 1.5), b, 0.0)
	lm.lathe("Stone", p + Vector3(0, 0.2, 0), PackedVector2Array([Vector2(0.55, 0), Vector2(0.5, 0.25),
		Vector2(0.3, 0.42), Vector2(0.0, 0.48)]), 6, 0.9, 1.25, b.get_euler().y)
	lm.box("Stone", p + b * Vector3(0, 0.3, 0.78), Vector3(0.26, 0.24, 0.32), b, 0.0)
	K.outline_prism(lm, "Stone", p + Vector3(0, 0.6, 0), b * Basis(Vector3.UP, PI * 0.5), PackedVector2Array([
		Vector2(-0.4, 0), Vector2(0.4, 0), Vector2(0.4, 1.3), Vector2(0.3, 1.52), Vector2(0, 1.62),
		Vector2(-0.3, 1.52), Vector2(-0.4, 1.3)]), 0.18)

# --- Temple of Literature ---

## Temple of Literature: from the Van Mieu gate in the south through the
## Dai Trung gate, the Khue Van Cac pavilion on its gate, the Dai Thanh
## gate, the Thien Quang well between two stele houses (82 steles of
## the examinations 1442-1779 on stone tortoises), to the Dai Bai
## Duong hall and the Thuong Dien sanctuary at the north end.
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
	# The four tall pillars (nghi mon) before the great gate.
	for s in [-1.0, 1.0]:
		for dx in [4.5, 9.5]:
			var pp := Vector3(s * (8.5 + dx), 0, 118.0)
			lm.box("Stone", pp + Vector3(0, 0.3, 0), Vector3(1.4, 0.6, 1.4))
			lm.box("Stone", pp + Vector3(0, 3.4, 0), Vector3(0.9, 6.2, 0.9))
			lm.box("Stone", pp + Vector3(0, 5.6, 0), Vector3(1.1, 0.25, 1.1))
			lm.lathe("Stone", pp + Vector3(0, 6.5, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(0.62, 0.3),
				Vector2(0.4, 0.7), Vector2(0.0, 0.9)]), 8)
			lm.spire("Gold", pp + Vector3(0, 7.3, 0), 0.25, 0.6, 0.0)
	_gate(lm, Vector3(0, 0, 60), 0.85)
	_khue_van_cac(lm, Vector3(0, 0, 0))
	_gate(lm, Vector3(0, 0, -62), 0.85)
	# Thien Quang well with its stone railing, and the two stele houses.
	lm.box("Stone", Vector3(0, 0.5, -31), Vector3(13.0, 1.0, 13.0))
	lm.box("Water", Vector3(0, 0.95, -31), Vector3(10.6, 0.15, 10.6))
	var wc := [Vector3(-6, 1.0, -37), Vector3(6, 1.0, -37), Vector3(6, 1.0, -25), Vector3(-6, 1.0, -25)]
	for i in 4:
		var a: Vector3 = wc[i]
		var b: Vector3 = wc[(i + 1) % 4]
		U.posts(lm, "Stone", a, b, 7, 0.9, 0.3, 0.0)
		lm.beam("Stone", a + Vector3(0, 0.95, 0), b + Vector3(0, 0.95, 0), 0.26, 0.2)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 16.5, 0, -31)
		lm.box("Stone", c + Vector3(0, 0.3, 0), Vector3(5.6, 0.6, 40.0))
		for r in [-1.0, 1.0]:
			U.posts(lm, "Red", c + Vector3(r * 2.4, 0.6, -18.0), c + Vector3(r * 2.4, 0.6, 18.0), 10, 3.4, 0.4)
			lm.beam("Red", c + Vector3(r * 2.4, 4.0, -18.0), c + Vector3(r * 2.4, 4.0, 18.0), 0.3, 0.4)
		U.swept_roof(lm, "Tile", "Brick", "", c + Vector3(0, 4.0, 0), Basis(), 5.0, 40.0, 1.9, 0.8, 0.8, 0.3)
		# 41 steles a side in two staggered rows, facing the well.
		var fb := Basis(Vector3.UP, -PI * 0.5 * s)
		for i in 41:
			var row := float(i % 2)
			_stele(lm, c + Vector3(s * (-0.9 + 1.8 * row), 0.6, -18.5 + 37.0 * float(i) / 40.0), fb)
	_hall(lm, Vector3(0, 0, -96), 28.0, 12.0, 5.2, 4.0)
	_hall(lm, Vector3(0, 0, -128), 22.0, 11.0, 5.8, 4.4)
	lm.commit(model)

## Khue Van Cac, the Constellation of Literature Pavilion (1805): four
## whitewashed brick pillars 1 m square on a 6.8 m square, the red
## timber upper storey with its railed gallery and a round window on
## each face (the rays of the star), under eight curved roofs in two
## tiers (12.3 m).
static func _khue_van_cac(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkAsiaSouthUtil.arch_wall(lm, "Brick", c, Basis(), 11.0, 3.2, 5.0, 3.0, 2.8)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("White", c + Vector3(sx * 2.9, 4.9, sz * 2.9), Vector3(1.0, 3.4, 1.0))
			lm.box("White", c + Vector3(sx * 2.9, 6.55, sz * 2.9), Vector3(1.2, 0.2, 1.2))
	lm.box("Red", c + Vector3(0, 6.75, 0), Vector3(7.6, 0.3, 7.6))
	# The gallery railing round the upper floor.
	var rc := [Vector3(-3.6, 6.9, -3.6), Vector3(3.6, 6.9, -3.6), Vector3(3.6, 6.9, 3.6), Vector3(-3.6, 6.9, 3.6)]
	for i in 4:
		var a: Vector3 = c + (rc[i] as Vector3)
		var b: Vector3 = c + (rc[(i + 1) % 4] as Vector3)
		U.posts(lm, "Red", a, b, 9, 0.7, 0.12, 0.0)
		lm.beam("Red", a + Vector3(0, 0.72, 0), b + Vector3(0, 0.72, 0), 0.14, 0.14)
	lm.box("Red", c + Vector3(0, 8.0, 0), Vector3(6.0, 2.2, 6.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var n: Vector3 = b * Vector3(0, 0, 1)
		var wc := c + b * Vector3(0, 8.0, 3.03)
		lm.disc("Dark", wc, n, 0.85, 16)
		var u: Vector3 = b * Vector3(1, 0, 0)
		var prev := wc + u * 0.9
		for k in 16:
			var a := TAU * float(k + 1) / 16.0
			var p := wc + (u * cos(a) + Vector3.UP * sin(a)) * 0.9
			lm.beam("Gold", prev, p, 0.12, 0.12, n)
			prev = p
		for k in 8:
			var a := TAU * float(k) / 8.0
			lm.beam("Gold", wc + n * 0.02, wc + n * 0.02 + (u * cos(a) + Vector3.UP * sin(a)) * 0.85, 0.06, 0.06, n)
	_hip(lm, "Tile", c + Vector3(0, 9.1, 0), Vector2(8.6, 8.6), Vector2(5.0, 5.0), 1.0, 0.6)
	lm.box("Red", c + Vector3(0, 10.2, 0), Vector3(3.4, 1.4, 3.4))
	_hip(lm, "Tile", c + Vector3(0, 10.9, 0), Vector2(5.6, 5.6), Vector2(0.8, 0.8), 1.3, 0.5)
	lm.spire("Gold", c + Vector3(0, 12.2, 0), 0.25, 0.5, 0.0)

## A sanctuary hall: stone base with steps, brick back and side walls, a
## red-pillared open front of two rows, lacquered doors, and one long
## up-swept tiled roof, ridge across X, with dragons facing the moon on
## the ridge.
static func _hall(lm: LandmarkMesh, c: Vector3, w: float, d: float, col_h: float, rise: float,
		lift: float = 1.4) -> void:
	lm.box("Stone", c + Vector3(0, 0.6, 0), Vector3(w + 4.0, 1.2, d + 4.0))
	U.stairs(lm, "Stone", c + Vector3(0, 0, d * 0.5 + 2.0), Basis(), w * 0.4, 3, 0.4, 0.4)
	lm.box("Brick", c + Vector3(0, 1.2 + col_h * 0.5, -d * 0.5 + 0.5), Vector3(w, col_h, 1.0))
	for s in [-1.0, 1.0]:
		lm.box("Brick", c + Vector3(s * (w * 0.5 - 0.5), 1.2 + col_h * 0.5, 0), Vector3(1.0, col_h, d))
	lm.box("Dark", c + Vector3(0, 1.2 + col_h * 0.45, d * 0.5 - 3.4), Vector3(w - 2.0, col_h * 0.9, 0.2))
	var n := int(w / 2.6) + 1
	for i in n:
		var x := -w * 0.5 + 0.5 + (w - 1.0) * float(i) / float(n - 1)
		if i > 0 and i < n - 1:
			lm.box("Red", c + Vector3(x, 1.2 + col_h * 0.42, d * 0.5 - 3.3), Vector3((w - 1.0) / float(n - 1) - 0.5,
				col_h * 0.84, 0.1), Basis(), 0.0)
		for zz in [d * 0.5 - 0.7, d * 0.5 - 3.0]:
			lm.lathe("Red", c + Vector3(x, 1.2, zz), PackedVector2Array([Vector2(0.38, 0), Vector2(0.38, 0.4),
				Vector2(0.3, 0.5), Vector2(0.28, col_h)]), 8)
	lm.box("Red", c + Vector3(0, 1.2 + col_h - 0.2, d * 0.5 - 0.7), Vector3(w, 0.4, 0.4))
	var rb := Basis(Vector3.UP, PI * 0.5)
	var rc := c + Vector3(0, 1.2 + col_h, 0)
	U.swept_roof(lm, "Tile", "Brick", "Brick", rc, rb, d, w, rise, lift, 1.4, 0.3)
	K.eave_border(lm, "Brick", rc, rb, d, w, rise, lift, 1.4)
	var ry := rc.y + rise + lift * 0.1 + 0.3
	lm.disc("Gold", Vector3(c.x, ry + 0.7, c.z), Vector3(0, 0, 1), 0.5, 12)
	for s in [-1.0, 1.0]:
		var prev := Vector3(c.x + s * 1.0, ry, c.z)
		for k in 6:
			var t := float(k + 1) / 6.0
			var p := Vector3(c.x + s * (1.0 + t * 2.6), ry + 0.25 + 0.35 * sin(t * TAU * 1.5), c.z)
			lm.beam("Brick", prev, p, 0.3 - 0.03 * float(k), 0.26)
			prev = p

# --- One Pillar Pagoda ---

## One Pillar Pagoda (Chua Mot Cot, 1049): the 3 m square lotus shrine
## of red posts and lattice walls under a curved four-corner roof with
## dragons on the ridge, its railed gallery on eight struts flaring from
## the single stone pillar (1.2 m across, 4 m tall) in the square lotus
## pond with its green-glazed railing and lotus leaves, the stair, and
## the Dien Huu temple halls behind a tiled gate and walls.
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
	lm.use("Glaze", LandmarkMaterials.pbr("slate", "#4E7F5E", 2.0))
	var pr := 8.0
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, 0.45, s * pr), Vector3(pr * 2.0 + 1.0, 0.9, 1.0))
		lm.box("Stone", Vector3(s * pr, 0.45, 0), Vector3(1.0, 0.9, pr * 2.0 - 1.0))
	lm.box("Water", Vector3(0, 0.2, 0), Vector3(pr * 2.0 - 1.0, 0.4, pr * 2.0 - 1.0))
	# The green-glazed railing on the pond's rim (open at the stair).
	var pc := [Vector3(-pr, 0.9, -pr), Vector3(pr, 0.9, -pr), Vector3(pr, 0.9, pr), Vector3(-pr, 0.9, pr)]
	for i in 4:
		var a: Vector3 = pc[i]
		var b: Vector3 = pc[(i + 1) % 4]
		if i == 2:
			for half in [[a, Vector3(1.4, 0.9, pr)], [Vector3(-1.4, 0.9, pr), b]]:
				U.posts(lm, "Glaze", half[0], half[1], 6, 0.8, 0.3, 0.0)
				lm.box("Glaze", ((half[0] as Vector3) + (half[1] as Vector3)) * 0.5 + Vector3(0, 0.45, 0),
					Vector3(absf((half[1] as Vector3).x - (half[0] as Vector3).x), 0.5, 0.14), Basis(), 0.0)
			continue
		U.posts(lm, "Glaze", a, b, 13, 0.8, 0.3, 0.0)
		var d := b - a
		lm.box("Glaze", (a + b) * 0.5 + Vector3(0, 0.45, 0), Vector3(maxf(absf(d.x), 0.14), 0.5, maxf(absf(d.z), 0.14)),
			Basis(), 0.0)
	# The pillar with its lotus capital, the struts and the shrine floor.
	lm.lathe("Stone", Vector3.ZERO, PackedVector2Array([Vector2(0.72, 0), Vector2(0.63, 1.0), Vector2(0.6, 3.2),
		Vector2(0.78, 3.6), Vector2(1.0, 3.9)]), 16)
	lm.lathe("Stone", Vector3(0, 3.9, 0), PackedVector2Array([Vector2(0.95, 0), Vector2(1.45, 0.3),
		Vector2(1.35, 0.55), Vector2(1.0, 0.7)]), 16)
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		var dv := Vector3(cos(a), 0, sin(a))
		lm.beam("Wood", dv * 0.9 + Vector3(0, 3.7, 0), dv * 2.1 + Vector3(0, 4.55, 0), 0.18, 0.22)
		lm.beam("Wood", dv * 2.1 + Vector3(0, 4.55, 0), dv * 2.4 + Vector3(0, 4.62, 0), 0.16, 0.16)
	lm.box("Wood", Vector3(0, 4.5, 0), Vector3(3.2, 0.2, 3.2))
	lm.box("Wood", Vector3(0, 4.7, 0), Vector3(4.0, 0.2, 4.0))
	# Gallery railing round the floor, open on the stair side.
	var gc := [Vector3(-1.9, 4.8, -1.9), Vector3(1.9, 4.8, -1.9), Vector3(1.9, 4.8, 1.9), Vector3(-1.9, 4.8, 1.9)]
	for i in 4:
		if i == 2:
			continue
		var a: Vector3 = gc[i]
		var b: Vector3 = gc[(i + 1) % 4]
		U.posts(lm, "Red", a, b, 9, 0.55, 0.08, 0.0)
		lm.beam("Red", a + Vector3(0, 0.58, 0), b + Vector3(0, 0.58, 0), 0.1, 0.1)
	# The shrine: corner posts, lattice walls, the door to the stair (+Z).
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Red", Vector3(sx * 1.45, 5.85, sz * 1.45), Vector3(0.22, 2.1, 0.22))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", b * Vector3(0, 5.8, 1.38), Vector3(2.7, 1.9, 0.08), b, 0.0)
		if side == 0:
			lm.box("Red", b * Vector3(0, 6.75, 1.44), Vector3(2.8, 0.2, 0.12), b, 0.0)
			continue
		for k in 7:
			lm.box("Red", b * Vector3(-1.2 + 0.4 * float(k), 5.8, 1.44), Vector3(0.06, 1.9, 0.08), b, 0.0)
		for k in 4:
			lm.box("Red", b * Vector3(0, 5.05 + 0.5 * float(k), 1.44), Vector3(2.7, 0.06, 0.08), b, 0.0)
	lm.box("Red", Vector3(0, 6.95, 0), Vector3(3.3, 0.24, 3.3))
	_hip(lm, "Tile", Vector3(0, 6.95, 0), Vector2(5.6, 5.6), Vector2(1.2, 0.9), 1.3, 0.55, 0.45)
	lm.lathe("Gold", Vector3(0, 8.3, 0), PackedVector2Array([Vector2(0.28, 0), Vector2(0.4, 0.35),
		Vector2(0.2, 0.7), Vector2(0.0, PILLAR_M - 8.3)]), 8)
	# Two dragons on the ridge, turned toward the finial.
	for s in [-1.0, 1.0]:
		var prev := Vector3(s * 0.4, 8.4, 0)
		for k in 6:
			var t := float(k + 1) / 6.0
			var p := Vector3(s * (0.4 + t * 1.6), 8.35 + 0.22 * sin(t * TAU * 1.25) - t * 0.25, 0)
			lm.beam("Tile", prev, p, 0.16, 0.14)
			prev = p
	# Lotus leaves floating in the pond.
	for i in 22:
		var a := float(i) * 2.39996
		var rr := 2.6 + 4.2 * sqrt(float(i) / 22.0)
		var lp := Vector3(cos(a) * rr, 0.42, sin(a) * rr)
		if absf(lp.x) < 1.2 and lp.z > 1.5:
			continue
		lm.disc("Glaze", lp, Vector3.UP, 0.35 + 0.15 * fmod(float(i) * 0.61, 1.0), 9)
	U.stairs(lm, "Stone", Vector3(0, 0, 2.2), Basis(), 1.6, 14, 0.4, 4.55 / 14.0)
	for sx in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(sx * 0.9, 1.2, 7.8), Vector3(sx * 0.9, 5.4, 2.2), 0.2, 0.3)
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

## Ngo Mon (1833, 17 m): the U-shaped red-brick and stone base 57 m wide
## with string courses and a crenellated parapet, five gateways (the
## emperor's square-headed central gate and two side gates in the main
## wall, an arched gate through each wing), and on top the Lau Ngu Phung
## (five-phoenix pavilion): a two-storey timber hall on a hundred red
## columns, its railed gallery and nine roofs of imperial yellow glazed
## tiles (the two-tier central roof, the galleries and the two-tier wing
## pavilions). Faces south.
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
	# Central gate: square-headed passage with stone surround and the name board.
	for s in [-1.0, 1.0]:
		lm.box("Base", mc + Vector3(s * 3.6, 2.5, 0), Vector3(2.8, 5.0, 12.0))
		lm.box("Stone", mc + Vector3(s * 2.35, 2.0, 6.05), Vector3(0.3, 4.0, 0.2), Basis(), 0.0)
	lm.box("Base", mc + Vector3(0, 4.55, 0), Vector3(4.4, 0.9, 12.0))
	lm.box("Stone", mc + Vector3(0, 4.05, 6.05), Vector3(5.0, 0.3, 0.2), Basis(), 0.0)
	lm.box("Gold", mc + Vector3(0, 4.6, 6.1), Vector3(3.0, 0.7, 0.1), Basis(), 0.0)
	lm.box("Red", mc + Vector3(0, 1.9, -1.0), Vector3(4.0, 3.8, 0.15), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		LandmarkAsiaSouthUtil.arch_wall(lm, "Base", mc + Vector3(s * 9.25, 0, 0), Basis(), 8.5, 5.0, 12.0, 3.2, 3.8)
		lm.box("Base", mc + Vector3(s * 16.0, 2.5, 0), Vector3(5.0, 5.0, 12.0))
		var wc := Vector3(s * 23.5, 0, 6.0)
		LandmarkAsiaSouthUtil.arch_wall(lm, "Base", wc, Basis(Vector3.UP, PI * 0.5), 15.5, 5.0, 10.0, 3.2, 3.8)
		lm.box("Stone", wc + Vector3(0, 5.2, 0), Vector3(10.6, 0.4, 16.1))
		U.stairs(lm, "Stone", Vector3(s * 12.0, 0, z0 - 6.0), Basis(Vector3.UP, PI), 3.4, 10, 0.6, 0.54)
		# String courses on the wings' outer faces.
		for y in [1.2, 3.4]:
			lm.box("Stone", wc + Vector3(0, y, 0), Vector3(10.4, 0.25, 15.9), Basis(), 0.0)
	for y in [1.2, 3.4]:
		for s in [-1.0, 1.0]:
			lm.box("Stone", mc + Vector3(s * 12.25, y, 0), Vector3(19.5, 0.25, 12.2), Basis(), 0.0)
	lm.box("Stone", mc + Vector3(0, 5.2, 0), Vector3(58.6, 0.4, 12.6))
	# Crenellated parapet round the platform's outer edges.
	U.crenel_run(lm, "Base", mc + Vector3(-29.0, 5.4, -6.1), mc + Vector3(29.0, 5.4, -6.1), 0.6, 0.5, 1.6)
	for s in [-1.0, 1.0]:
		U.crenel_run(lm, "Base", Vector3(s * 29.0, 5.4, z0 - 6.1), Vector3(s * 29.0, 5.4, 13.9), 0.6, 0.5, 1.6)
		U.crenel_run(lm, "Base", Vector3(s * 29.0, 5.4, 13.9), Vector3(s * 18.0, 5.4, 13.9), 0.6, 0.5, 1.6)
	var py := 5.4
	# Central hall: the columns (4 rows of 11) and the two-tier roof.
	lm.box("Dark", mc + Vector3(0, py + 2.0, 0), Vector3(23.0, 3.8, 6.4))
	for i in 11:
		for r in [-4.5, -1.6, 1.6, 4.5]:
			_col(lm, mc + Vector3(-13.0 + 2.6 * float(i), py, r), 4.2 if absf(r) > 2.0 else 6.6)
	for r in [-1.0, 1.0]:
		lm.box("Red", mc + Vector3(0, py + 0.9, r * 4.5), Vector3(26.0, 0.12, 0.1), Basis(), 0.0)
		lm.box("Red", mc + Vector3(0, py + 0.5, r * 4.5), Vector3(26.0, 0.12, 0.1), Basis(), 0.0)
	lm.box("Red", mc + Vector3(0, py + 4.35, 0), Vector3(27.0, 0.6, 9.8))
	_hip(lm, "Yellow", mc + Vector3(0, py + 4.5, 0), Vector2(31.0, 14.0), Vector2(17.0, 5.0), 2.6, 0.8)
	lm.box("Red", mc + Vector3(0, 12.2, 0), Vector3(16.0, 2.4, 5.0))
	for i in 7:
		lm.box("Dark", mc + Vector3(-6.0 + 2.0 * float(i), 12.2, 2.52), Vector3(1.2, 1.4, 0.06), Basis(), 0.0)
	_hip(lm, "Yellow", mc + Vector3(0, 13.4, 0), Vector2(21.0, 9.5), Vector2(9.0, 1.4), 3.1, 0.9, 0.5)
	lm.disc("Gold", mc + Vector3(0, 17.1, 0), Vector3(0, 0, 1), 0.45, 12)
	for s in [-1.0, 1.0]:
		# Galleries.
		var gc := mc + Vector3(s * 16.5, 0, 0)
		lm.box("Dark", gc + Vector3(0, py + 1.8, 0), Vector3(6.0, 3.6, 5.0))
		for i in 3:
			for r in [-3.0, 3.0]:
				_col(lm, gc + Vector3(-2.4 + 2.4 * float(i), py, r), 3.6)
		_hip(lm, "Yellow", gc + Vector3(0, py + 3.6, 0), Vector2(8.0, 10.5), Vector2(4.0, 3.0), 1.4, 0.6)
		# Wing pavilions: columns, the lower skirt roof, the upper roof.
		var pc := Vector3(s * 23.5, py, 6.0)
		lm.box("Dark", pc + Vector3(0, 2.0, 0), Vector3(6.0, 4.0, 10.0))
		for i in 4:
			for r in [-4.1, 4.1]:
				_col(lm, pc + Vector3(r, 0, -5.4 + 3.6 * float(i)), 3.4)
			_col(lm, pc + Vector3(0, 0, -5.4 + 3.6 * float(i)), 5.6)
		_hip(lm, "Yellow", pc + Vector3(0, 3.4, 0), Vector2(11.4, 15.6), Vector2(7.0, 12.0), 1.0, 0.6)
		lm.box("Red", pc + Vector3(0, 4.9, 0), Vector3(6.0, 1.6, 10.6))
		_hip(lm, "Yellow", pc + Vector3(0, 5.6, 0), Vector2(9.0, 13.6), Vector2(3.6, 8.0), 2.3, 0.7, 0.8)
	lm.commit(model)

## Round red lacquered column h tall on a stone base at `p`.
static func _col(lm: LandmarkMesh, p: Vector3, h: float) -> void:
	lm.box("Stone", p + Vector3(0, 0.12, 0), Vector3(0.7, 0.24, 0.7), Basis(), 0.0)
	lm.lathe("Red", p + Vector3(0, 0.24, 0), PackedVector2Array([Vector2(0.24, 0), Vector2(0.22, h - 0.24)]), 8,
		1.0, 1.0, 0.0, true, false)
