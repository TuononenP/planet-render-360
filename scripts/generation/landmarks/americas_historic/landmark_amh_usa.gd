class_name LandmarkAmhUsa
extends RefCounted

## Two American founding landmarks in true metres: the Jefferson
## Memorial on Washington's Tidal Basin and Independence Hall in
## Philadelphia.

const JEFFERSON_TOP_M := 33.8
const INDEPENDENCE_TOP_M := 51.4

## Jefferson Memorial (1939-43): the circular stepped platform about
## 165 ft (50 m) across, the open rotunda's peristyle of 26 smooth Ionic
## columns (43 ft, 13.1 m tall and 5 ft 3 in, 1.6 m through) round the
## chamber wall with its four openings, each framed by a pair of
## columns, the entablature, the stepped attic rings and the shallow
## dome, to 33.8 m; the north portico of twelve columns (eight across in
## seven bays, two rows of two behind) under the pediment carrying
## Weinman's group of the Committee of Five, above the broad stair to
## the Tidal Basin; and inside, the 19 ft bronze Jefferson on his 6 ft
## pedestal. The portico faces north (-Z) over the Tidal Basin.
static func jefferson_memorial(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDEBE4", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D8D5CC", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#A9AFAC", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	lm.use("Bronze", LandmarkMaterials.paint("#4A3B2A", 0.45, 0.6))
	var floor_y := 4.3
	var col_r := 20.8
	var col_h := 13.1
	# Twelve circular steps up to the floor.
	for i in 12:
		lm.frustum("Steps", Vector3(0, 0.3583 * float(i), 0), 25.4 - 0.24 * float(i),
			25.4 - 0.24 * float(i), 0.3583, 64)
	lm.frustum("Marble", Vector3(0, floor_y, 0), 14.0, 14.0, 13.1, 64)
	# Peristyle: 26 columns on the arc outside the portico.
	var gap := asin(14.1 / col_r)
	var start := -PI * 0.5 + gap
	var step := (TAU - 2.0 * gap) / 26.0
	for k in 26:
		var a := start + step * (float(k) + 0.5)
		LandmarkDetail.column(lm, "Marble", Vector3(cos(a) * col_r, floor_y, sin(a) * col_r), 0.8,
			col_h, "ionic", 0)
	# Entablature (architrave, frieze, cornice) and the stepped attic.
	var ey := floor_y + col_h
	lm.frustum("Marble", Vector3(0, ey, 0), 21.6, 21.6, 1.3, 64)
	lm.frustum("Marble", Vector3(0, ey + 1.3, 0), 21.4, 21.4, 1.4, 64)
	lm.lathe("Marble", Vector3(0, ey + 2.7, 0),
		PackedVector2Array([Vector2(21.4, 0.0), Vector2(21.7, 0.25), Vector2(22.2, 0.5),
		Vector2(22.3, 0.75), Vector2(22.4, 0.9)]), 64)
	lm.frustum("Marble", Vector3(0, ey + 3.6, 0), 19.4, 19.4, 1.6, 64)
	lm.frustum("Marble", Vector3(0, ey + 5.2, 0), 18.3, 18.3, 1.4, 64)
	lm.frustum("Marble", Vector3(0, ey + 6.6, 0), 17.4, 17.2, 1.4, 64)
	# Shallow dome: a spherical cap 8.4 m high on a 17.0 m radius.
	var dr := 17.0
	var dh := JEFFERSON_TOP_M - (ey + 8.0)
	var sphere_r := (dr * dr + dh * dh) / (2.0 * dh)
	var prof := PackedVector2Array()
	for i in 13:
		var r := dr * (1.0 - float(i) / 12.0)
		prof.append(Vector2(r, sqrt(sphere_r * sphere_r - r * r) - (sphere_r - dh)))
	lm.lathe("Dome", Vector3(0, ey + 8.0, 0), prof, 64)
	# The four openings, each framed by antae and a pair of columns.
	for q in 4:
		var a := PI * 0.5 * float(q)
		var d := Vector3(cos(a), 0, sin(a))
		var r := Basis.looking_at(-d)
		LandmarkAmhParts.opening(lm, "Door", Vector3(0, floor_y + 5.0, 0) + d * 14.0, r, 7.6, 10.0, 0.3)
		for sx in [-1.0, 1.0]:
			lm.box("Marble", Vector3(0, floor_y + 5.0, 0) + d * 14.2 + r * Vector3(sx * 4.3, 0, 0),
				Vector3(1.0, 10.0, 0.6), r)
			LandmarkDetail.column(lm, "Marble",
				Vector3(0, floor_y, 0) + d * 14.6 + r * Vector3(sx * 1.9, 0, 0), 0.55, 9.6, "ionic", 0)
		lm.box("Marble", Vector3(0, floor_y + 10.4, 0) + d * 14.3, Vector3(9.6, 0.8, 0.8), r)
	# Jefferson on his pedestal in the chamber.
	lm.box("Door", Vector3(0, floor_y + 0.9, 0), Vector3(2.2, 1.8, 2.2))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, floor_y + 1.8, 0), 5.8)
	_jefferson_portico(lm, floor_y, col_h)
	lm.commit(model)

## North portico: the stepped podium and stair, twelve columns,
## entablature with dentilled cornice, pediment and its sculpture.
static func _jefferson_portico(lm: LandmarkMesh, floor_y: float, col_h: float) -> void:
	var north := Basis(Vector3.UP, PI)
	lm.box("Steps", Vector3(0, floor_y * 0.5, -25.0), Vector3(31.0, floor_y, 12.0))
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, north, 30.0, 44.0, 0.0, 31.0, floor_y, 29.0, 24)
	LandmarkAmhParts.rails(lm, "Steps", Vector3.ZERO, north, 30.0, 44.0, 0.0, 31.0, floor_y, 2.4, 1.6)
	for i in 8:
		LandmarkDetail.column(lm, "Marble", Vector3((float(i) - 3.5) * 3.8, floor_y, -29.0), 0.8, col_h,
			"ionic", 0)
	for z in [-25.2, -21.4]:
		for x in [-13.3, 13.3]:
			LandmarkDetail.column(lm, "Marble", Vector3(x, floor_y, z), 0.8, col_h, "ionic", 0)
	var ey := floor_y + col_h
	lm.box("Marble", Vector3(0, ey + 0.65, -24.5), Vector3(28.6, 1.3, 11.0))
	lm.box("Marble", Vector3(0, ey + 1.95, -24.5), Vector3(28.4, 1.3, 10.8))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-14.2, ey + 2.6, -29.9),
		Vector3(14.2, ey + 2.6, -29.9), Vector3.FORWARD, 0.9, true)
	lm.box("Marble", Vector3(0, ey + 3.3, -24.6), Vector3(29.6, 0.6, 11.4))
	var py := ey + 3.6
	lm.gable("Dome", Vector3(0, py, -24.6), 29.6, 11.4, 4.1, Basis(), 0.3, "Marble")
	# Raking cornices and the Committee of Five in the tympanum.
	for s in [-1.0, 1.0]:
		lm.beam("Marble", Vector3(s * 15.0, py, -30.4), Vector3(0, py + 4.3, -30.4), 0.7, 0.6,
			Vector3.UP)
	for i in 5:
		var x := (float(i) - 2.0) * 2.6
		var h := 2.7 - absf(float(i) - 2.0) * 0.25
		LandmarkKits.statue_figure(lm, "Marble", Vector3(x, py + 0.1, -30.0), h, i == 2)

## Independence Hall (1732-53): the red-brick Georgian State House
## (33 x 15 m, two storeys of nine bays on a stone water table, marble
## belt course and keystoned windows with marble panels between the
## storeys, the modillioned cornice, the hipped roof with its
## balustraded deck and the paired end chimneys, the pedimented door on
## Chestnut Street), the open-arcaded hyphens and the two wings, and on
## the south (+Z) face the brick tower with its Palladian window
## carrying Strickland's 1828 white wooden steeple: the clock stage with
## its four 8 ft dials, the octagonal belfry, the upper octagon, the
## cupola, lantern, spire and vane, to 51.4 m (168 ft 7 in). The long
## axis runs along X.
static func independence_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A44A36", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EAE6DA", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5D6368", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A9488", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Gold", LandmarkMaterials.gold())
	# Central block: water table, walls, belt course, cornice, roof.
	lm.box("Stone", Vector3(0, 0.45, 0), Vector3(33.6, 0.9, 15.6))
	lm.box("Brick", Vector3(0, 6.0, 0), Vector3(33.0, 10.8, 15.0))
	lm.box("Trim", Vector3(0, 6.6, 0), Vector3(33.3, 0.35, 15.3))
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Trim", Vector3(-16.5, 11.2, s * 7.5), Vector3(16.5, 11.2, s * 7.5),
			Vector3(0, 0, s), 0.7, true)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 16.5, 11.2, -7.5), Vector3(s * 16.5, 11.2, 7.5),
			Vector3(s, 0, 0), 0.7, true)
		# Quoins up the corners.
		for z in [-7.5, 7.5]:
			for j in 9:
				var long := j % 2 == 0
				lm.box("Trim", Vector3(s * 16.5, 1.4 + 1.1 * float(j), z),
					Vector3(0.9 if long else 0.6, 0.5, 0.9 if long else 0.6), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 11.75, 0), Vector3(34.6, 0.3, 16.8))
	LandmarkNaParts.hip(lm, "Roof", Vector3(0, 11.9, 0), Basis(), 17.2, 8.3, 0.55, 4.0)
	var deck := 15.9
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var e := 4.4 if q % 2 == 0 else 9.3
		var hw := 9.3 if q % 2 == 0 else 4.4
		LandmarkNaParts.balusters(lm, "Trim", Vector3(0, deck, 0) + r * Vector3(-hw, 0, e),
			Vector3(0, deck, 0) + r * Vector3(hw, 0, e), 0.9, 0.35, 3.1)
	for cx in [-11.0, 11.0]:
		for cz in [-3.0, 3.0]:
			lm.box("Brick", Vector3(cx, 15.65, cz), Vector3(1.5, 3.5, 1.5))
			lm.box("Trim", Vector3(cx, 17.5, cz), Vector3(1.8, 0.3, 1.8))
		lm.box("Brick", Vector3(cx, 16.9, 0), Vector3(1.2, 0.9, 4.6))
	for q in 2:
		var r := Basis(Vector3.UP, PI * float(q))
		var n := r * Vector3.BACK
		for i in range(-4, 5):
			var x := 3.5 * float(i)
			if q == 0 and absi(i) <= 1:
				continue
			if q == 1 and i == 0:
				_hall_door(lm, r * Vector3(x, 0.9, 7.5), r)
			else:
				LandmarkDetail.window(lm, "Trim", "Windows", r * Vector3(x, 4.1, 7.5), n, 1.4, 2.9,
					false, 0.2)
				lm.box("Trim", r * Vector3(x, 5.75, 7.6), Vector3(0.45, 0.6, 0.25), r, 0.0)
			LandmarkDetail.window(lm, "Trim", "Windows", r * Vector3(x, 9.0, 7.5), n, 1.4, 2.7, false,
				0.2)
			lm.box("Trim", r * Vector3(x, 7.15, 7.55), Vector3(1.6, 0.6, 0.12), r, 0.0)
	# Hyphens (open arcades) and wings, mirrored east and west.
	for s in [-1.0, 1.0]:
		var hx: float = s * 20.5
		lm.box("Stone", Vector3(hx, 0.45, 0), Vector3(8.4, 0.9, 6.8))
		lm.box("Brick", Vector3(hx, 3.3, 0), Vector3(8.0, 5.4, 4.2))
		for zf in [-3.0, 3.0]:
			for i in 4:
				lm.box("Brick", Vector3(hx - 3.6 + 2.4 * float(i), 3.3, zf), Vector3(0.8, 5.4, 0.8))
			for i in 3:
				var ac := Vector3(hx - 2.4 + 2.4 * float(i), 3.6, zf)
				LandmarkDetail.arch(lm, "Trim", ac + Vector3(0, 0, 0.4 * signf(zf)),
					Vector3(0, 0, signf(zf)), 1.6, 0.3, 0.3)
				lm.box("Brick", ac + Vector3(0, 1.45, 0), Vector3(1.6, 1.3, 0.8))
		lm.box("Trim", Vector3(hx, 6.25, 0), Vector3(8.4, 0.5, 6.8))
		LandmarkNaParts.hip(lm, "Roof", Vector3(hx, 6.5, 0), Basis(), 4.2, 3.4, 0.6, 1.4)
		var wx: float = s * 33.0
		lm.box("Stone", Vector3(wx, 0.45, 0), Vector3(17.4, 0.9, 10.9))
		lm.box("Brick", Vector3(wx, 5.0, 0), Vector3(17.0, 8.8, 10.5))
		lm.box("Trim", Vector3(wx, 5.0, 0), Vector3(17.2, 0.3, 10.7))
		lm.box("Trim", Vector3(wx, 9.65, 0), Vector3(17.6, 0.5, 11.1))
		LandmarkNaParts.hip(lm, "Roof", Vector3(wx, 9.9, 0), Basis(), 8.8, 5.5, 0.55, 3.4)
		lm.box("Brick", Vector3(s * 36.5, 14.3, 0), Vector3(1.4, 4.0, 1.4))
		for q in 2:
			var r := Basis(Vector3.UP, PI * float(q))
			var n := r * Vector3.BACK
			for i in 4:
				var x := wx - 5.25 + 3.5 * float(i)
				for y in [2.9, 7.0]:
					LandmarkDetail.window(lm, "Trim", "Windows",
						r * Vector3(x * (1.0 if q == 0 else -1.0), y, 5.25), n, 1.3, 2.4, false, 0.2)
		for z in [-2.0, 2.0]:
			for y in [2.9, 7.0]:
				LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * 41.5, y, z), Vector3(s, 0, 0),
					1.3, 2.4, false, 0.2)
	_steeple_tower(lm)
	lm.commit(model)

## The north doorway at `p` (threshold centre on the wall face): the
## door, flanking Doric pilasters, entablature and triangular pediment.
static func _hall_door(lm: LandmarkMesh, p: Vector3, r: Basis) -> void:
	LandmarkAmhParts.opening(lm, "Windows", p + r * Vector3(0, 1.9, 0.05), r, 2.0, 3.8, 0.1)
	for sx in [-1.0, 1.0]:
		lm.box("Trim", p + r * Vector3(sx * 1.45, 2.0, 0.2), Vector3(0.5, 4.0, 0.4), r)
	lm.box("Trim", p + r * Vector3(0, 4.3, 0.25), Vector3(3.6, 0.6, 0.5), r)
	lm.gable("Trim", p + r * Vector3(0, 4.6, 0.25), 3.8, 0.5, 0.9, r * Basis(Vector3.UP, PI * 0.5), 0.1,
		"Trim")
	lm.box("Stone", p + r * Vector3(0, -0.25, 0.8), Vector3(3.4, 0.4, 1.4), r)

## The brick tower on the south face (stone string courses, the
## Palladian window, the round-headed door) and Strickland's wooden
## steeple above it.
static func _steeple_tower(lm: LandmarkMesh) -> void:
	var tc := Vector3(0, 0, 11.0)
	lm.box("Brick", tc + Vector3(0, 14.05, 0), Vector3(9.4, 26.9, 9.4))
	for y in [6.6, 12.6, 22.0]:
		lm.box("Trim", tc + Vector3(0, y, 0), Vector3(9.9, 0.45, 9.9))
	var n := Vector3.BACK
	# Round-headed door under the Palladian window.
	LandmarkAmhParts.opening(lm, "Windows", tc + Vector3(0, 2.6, 4.75), Basis(), 2.2, 3.6, 0.1)
	LandmarkDetail.arch(lm, "Trim", tc + Vector3(0, 4.4, 4.7), n, 2.2, 0.35, 0.3)
	LandmarkDetail.window(lm, "Trim", "Windows", tc + Vector3(0, 9.4, 4.7), n, 2.2, 4.4, true, 0.3)
	for sx in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "Trim", "Windows", tc + Vector3(sx * 2.3, 8.9, 4.7), n, 1.0, 2.8,
			false, 0.3)
	for sx in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "Trim", "Windows", tc + Vector3(sx * 4.7, 9.4, 0), Vector3(sx, 0, 0),
			1.4, 3.2, true, 0.25)
	LandmarkDetail.window(lm, "Trim", "Windows", tc + Vector3(0, 17.2, 4.7), n, 1.6, 3.4, true, 0.25)
	LandmarkDetail.cornice(lm, "Trim", tc + Vector3(-4.7, 27.4, 4.7), tc + Vector3(4.7, 27.4, 4.7), n,
		0.6, true)
	lm.box("Trim", tc + Vector3(0, 27.8, 0), Vector3(10.0, 0.6, 10.0))
	# Clock stage: square, four dials, urns on the corners.
	var cs := tc + Vector3(0, 28.1, 0)
	lm.box("Trim", cs + Vector3(0, 1.9, 0), Vector3(8.2, 3.8, 8.2))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var d := r * Vector3.BACK
		lm.disc("Trim", cs + Vector3(0, 1.9, 0) + d * 4.12, d, 1.35, 32)
		lm.disc("Windows", cs + Vector3(0, 1.9, 0) + d * 4.16, d, 1.2, 32)
		lm.beam("Gold", cs + Vector3(0, 1.9, 0) + d * 4.2, cs + Vector3(0, 2.7, 0) + d * 4.2, 0.1, 0.04)
		lm.beam("Gold", cs + Vector3(0, 1.9, 0) + d * 4.2,
			cs + Vector3(0, 1.9, 0) + d * 4.2 + r * Vector3(0.6, 0, 0), 0.08, 0.04)
		lm.lathe("Trim", cs + Vector3(0, 3.8, 0) + r * Vector3(3.8, 0, 3.8),
			PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.4, 0.3), Vector2(0.25, 0.7),
			Vector2(0.1, 1.0), Vector2(0.0, 1.1)]), 8)
	lm.box("Trim", cs + Vector3(0, 3.95, 0), Vector3(8.6, 0.3, 8.6))
	# Octagonal belfry: arched openings, pilasters, cornice.
	var bf := cs + Vector3(0, 4.1, 0)
	lm.frustum("Trim", bf, 3.9, 3.9, 5.5, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", bf + d * 3.6 + Vector3(0, 2.6, 0), d, 1.1, 3.2,
			true, 0.2)
		var ap := a + PI / 8.0
		lm.box("Trim", bf + Vector3(cos(ap), 0, sin(ap)) * 3.95 + Vector3(0, 2.75, 0),
			Vector3(0.35, 5.5, 0.35), Basis.looking_at(Vector3(cos(ap), 0, sin(ap))), 0.0)
	lm.frustum("Trim", bf + Vector3(0, 5.5, 0), 4.3, 4.3, 0.4, 8, PI / 8.0)
	# Upper octagon with round windows, cupola, lantern, spire, vane.
	var uo := bf + Vector3(0, 5.9, 0)
	lm.frustum("Trim", uo, 3.0, 2.9, 3.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.disc("Windows", uo + d * 2.83 + Vector3(0, 1.5, 0), d, 0.6, 16)
	lm.frustum("Trim", uo + Vector3(0, 3.0, 0), 3.3, 3.3, 0.3, 8, PI / 8.0)
	var dm := uo + Vector3(0, 3.3, 0)
	lm.lathe("Roof", dm,
		PackedVector2Array([Vector2(3.0, 0.0), Vector2(3.1, 0.3), Vector2(2.7, 1.4), Vector2(1.9, 2.3),
		Vector2(1.0, 2.9), Vector2(0.5, 3.1)]), 24)
	var ln := dm + Vector3(0, 3.1, 0)
	lm.frustum("Trim", ln, 0.9, 0.85, 1.8, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Trim", ln + Vector3(cos(a) * 0.95, 0.9, sin(a) * 0.95), Vector3(0.12, 1.8, 0.12),
			Basis(), 0.0)
	lm.frustum("Trim", ln + Vector3(0, 1.8, 0), 1.05, 1.05, 0.2, 8, PI / 8.0)
	var sp := ln + Vector3(0, 2.0, 0)
	lm.spire("Roof", sp, 0.75, INDEPENDENCE_TOP_M - 1.4 - sp.y, 0.1, 8)
	var v := Vector3(0, INDEPENDENCE_TOP_M - 1.4, 11.0)
	lm.lathe("Gold", v,
		PackedVector2Array([Vector2(0.1, 0.0), Vector2(0.35, 0.2), Vector2(0.45, 0.45),
		Vector2(0.3, 0.75), Vector2(0.1, 0.9)]), 10)
	lm.beam("Gold", v + Vector3(0, 0.9, 0), Vector3(0, INDEPENDENCE_TOP_M, 11.0), 0.12, 0.12)
	lm.beam("Gold", v + Vector3(-0.6, 1.1, 0), v + Vector3(0.6, 1.1, 0), 0.06, 0.25)
