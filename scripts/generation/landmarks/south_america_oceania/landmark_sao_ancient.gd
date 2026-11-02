class_name LandmarkSaoAncient
extends RefCounted

## Pre-Columbian monuments in true metres: the Inca citadel of Machu
## Picchu and the fifteen moai of Ahu Tongariki on Rapa Nui.

# --- Machu Picchu ---

const PLAZA_Y := 16.2
const TERRACES := 12
const TERRACE_DEPTH := 5.0
## Main Plaza: a lawn two terraces below the upper town, running
## north-south between the sacred (west) and residential (east) halves.
const LAWN_Y := PLAZA_Y - 2.4

## [x, z, width, length, roofed] of the kancha houses: rows on the
## east (residential) side and the royal and sacred quarters on the west.
const HOUSES := [[30.0, -40.0, 6.0, 11.0, true], [38.0, -40.0, 6.0, 11.0, false],
	[46.0, -40.0, 6.0, 11.0, false], [30.0, -26.0, 6.0, 11.0, false], [38.0, -26.0, 6.0, 11.0, true],
	[46.0, -26.0, 6.0, 11.0, false], [30.0, -12.0, 6.0, 10.0, false], [38.0, -12.0, 6.0, 10.0, false],
	[46.0, -12.0, 6.0, 10.0, true], [38.0, 4.0, 6.0, 10.0, false], [46.0, 4.0, 6.0, 10.0, false],
	[-44.0, 8.0, 7.0, 12.0, true], [-35.0, 8.0, 7.0, 12.0, false], [-26.0, 8.0, 7.0, 12.0, false],
	[-44.0, -8.0, 6.0, 10.0, false], [-36.0, -8.0, 6.0, 10.0, false], [-12.0, 12.0, 5.0, 9.0, true],
	[-4.0, 12.0, 5.0, 9.0, false], [6.0, 12.0, 5.0, 9.0, false], [22.0, -2.0, 5.0, 9.0, false]]

## The Inca citadel (c. 1450): twelve agricultural terraces climbing
## 16 m from the south to the upper town, the Guardhouse hut, twenty
## kancha houses of fitted granite with trapezoidal doors and niches
## (a few under restored thatch), the Main Plaza lawn, the curved
## Temple of the Sun, the Principal Temple and Temple of the Three
## Windows on the Sacred Plaza, and the terraced Intihuatana hill with
## its carved gnomon, 27 m above the lowest terrace.
static func machu_picchu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C8578", 3.0))
	lm.use("Grass", LandmarkMaterials.pbr("lawn", "#6E8A4A", 4.0))
	lm.use("Thatch", LandmarkMaterials.pbr("wood", "#A68E5A", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("rock", "#3A3631", 2.0))
	_terraces(lm)
	_upper_town(lm)
	for h in HOUSES:
		_house(lm, float(h[0]), float(h[1]), float(h[2]), float(h[3]), bool(h[4]))
	_temple_of_sun(lm, Vector3(22.0, PLAZA_Y, 12.0))
	_sacred_plaza(lm, Vector3(-30.0, PLAZA_Y, -24.0))
	_intihuatana(lm, Vector3(-30.0, PLAZA_Y, -44.0))
	lm.commit(model)

## Terrace stack on the south slope: each a curved dry-stone wall with a
## grass tread, a stair climbing them and the Guardhouse at the top.
static func _terraces(lm: LandmarkMesh) -> void:
	var rise := PLAZA_Y / float(TERRACES + 1)
	for i in TERRACES:
		var top := rise * float(i + 1)
		var z_front := 76.0 - TERRACE_DEPTH * float(i)
		var w := 110.0 - 2.5 * float(i)
		var front := PackedVector2Array()
		var segs := 10
		for k in segs + 1:
			var x := lerpf(-w * 0.5, w * 0.5, float(k) / segs)
			front.append(Vector2(x, z_front - 6.0 * pow(x / (w * 0.5), 2.0)))
		var poly := PackedVector2Array(front)
		poly.append(Vector2(w * 0.5, 20.0))
		poly.append(Vector2(-w * 0.5, 20.0))
		lm.poly_prism("Stone", poly, 0.0, top, false)
		lm.poly_prism("Grass", poly, top, top + 0.12)
		# Coping stones along the wall head.
		for k in segs:
			var a := Vector3(front[k].x, top + 0.15, front[k].y)
			var b := Vector3(front[k + 1].x, top + 0.15, front[k + 1].y)
			lm.beam("Stone", a, b, 0.7, 0.3)
	# Stair up the terraces (one flight per terrace).
	for i in TERRACES + 1:
		var y := rise * float(i)
		var z := 76.0 - TERRACE_DEPTH * float(i) + 2.0
		for k in 4:
			lm.box("Stone", Vector3(-6.0, y + rise * (float(k) + 0.5) / 4.0, z - 0.6 * float(k)),
				Vector3(1.8, rise / 4.0, 0.6), Basis(), 0.0)
	# Guardhouse: thatched hut overlooking the terraces.
	var g := Vector3(-52.0, PLAZA_Y + 0.12, 15.0)
	lm.box("Stone", g + Vector3(0, 1.4, 0), Vector3(5.0, 2.8, 8.0))
	lm.gable("Thatch", g + Vector3(0, 2.8, 0), 5.0, 8.0, 2.6, Basis(), 0.6, "Stone")
	lm.quad("Shadow", g + Vector3(-1.0, 0.1, -4.03), g + Vector3(1.0, 0.1, -4.03),
		g + Vector3(0.8, 2.2, -4.03), g + Vector3(-0.8, 2.2, -4.03), Vector3.FORWARD)

## The upper-town platform with the sunken Main Plaza lawn stepped
## down in two terraces between the west and east quarters.
static func _upper_town(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(s) * 36.5, PLAZA_Y * 0.5, -18.0), Vector3(43.0, PLAZA_Y, 76.0), Basis(), 0.0)
		lm.box("Grass", Vector3(float(s) * 36.5, PLAZA_Y + 0.06, -18.0), Vector3(43.0, 0.12, 76.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0, PLAZA_Y * 0.5, 12.5), Vector3(30.0, PLAZA_Y, 15.0), Basis(), 0.0)
	lm.box("Grass", Vector3(0, PLAZA_Y + 0.06, 12.5), Vector3(30.0, 0.12, 15.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0, PLAZA_Y * 0.5, -55.0), Vector3(30.0, PLAZA_Y, 2.0), Basis(), 0.0)
	# The plaza: a lawn 2.4 m down, stepped by a retaining terrace.
	lm.box("Stone", Vector3(0, LAWN_Y * 0.5, -24.5), Vector3(30.0, LAWN_Y, 59.0), Basis(), 0.0)
	lm.box("Grass", Vector3(0, LAWN_Y + 0.06, -24.5), Vector3(24.0, 0.12, 59.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(s) * 13.5, LAWN_Y + 0.6, -24.5), Vector3(3.0, 1.2, 59.0), Basis(), 0.0)
		lm.box("Grass", Vector3(float(s) * 13.5, LAWN_Y + 1.26, -24.5), Vector3(3.0, 0.12, 59.0), Basis(), 0.0)
	# Stairways down into the plaza.
	for s in [-1.0, 1.0]:
		for k in 6:
			lm.box("Stone", Vector3(float(s) * (14.7 - 0.5 * float(k)), PLAZA_Y - 0.2 - 0.4 * float(k), -6.0),
				Vector3(0.6, 0.4, 2.0), Basis(), 0.0)

## Kancha house: four fitted-stone walls with stone gable ends, a
## trapezoidal door and niches; thatched when `roofed`, else a ruin.
static func _house(lm: LandmarkMesh, x: float, z: float, w: float, l: float, roofed: bool) -> void:
	var y := PLAZA_Y + 0.12
	var c := Vector3(x, y, z)
	var t := 0.8
	var wh := 2.9
	for s in [-1.0, 1.0]:
		lm.box("Stone", c + Vector3(float(s) * (w * 0.5 - t * 0.5), wh * 0.5, 0), Vector3(t, wh, l))
		lm.box("Stone", c + Vector3(0, wh * 0.5, float(s) * (l * 0.5 - t * 0.5)), Vector3(w - t * 2.0, wh, t))
		# Stone gable end over each short wall.
		var e := c + Vector3(0, wh, float(s) * (l * 0.5 - t * 0.5))
		for f in [-1.0, 1.0]:
			var off := Vector3(0, 0, float(f) * t * 0.5)
			lm.quad("Stone", e + off + Vector3(-w * 0.5, 0, 0), e + off + Vector3(w * 0.5, 0, 0),
				e + off + Vector3(0.3, 2.3, 0), e + off + Vector3(-0.3, 2.3, 0), Vector3(0, 0, float(f)))
		for side in [-1.0, 1.0]:
			var a := e + Vector3(float(side) * w * 0.5, 0, 0)
			var b := e + Vector3(float(side) * 0.3, 2.3, 0)
			lm.quad("Stone", a - Vector3(0, 0, t * 0.5), a + Vector3(0, 0, t * 0.5), b + Vector3(0, 0, t * 0.5),
				b - Vector3(0, 0, t * 0.5), Vector3(float(side), 0.6, 0).normalized())
	# Door on the long west/east wall facing the plaza, two niches beside it.
	var face := -1.0 if x > 0.0 else 1.0
	var fx := x + face * (w * 0.5 + 0.02)
	var n := Vector3(face, 0, 0)
	_trapezoid(lm, Vector3(fx, y, z), n, 1.1, 0.8, 2.2)
	for k in [-1.0, 1.0]:
		_trapezoid(lm, Vector3(fx, y + 1.0, z + float(k) * l * 0.3), n, 0.55, 0.4, 0.75)
	if roofed:
		lm.gable("Thatch", c + Vector3(0, wh, 0), w, l, 2.5, Basis(), 0.55)

## Trapezoidal opening (wider at the sill) on a wall facing `n`, from
## its sill centre `c`: a dark recess with a lintel stone above.
static func _trapezoid(lm: LandmarkMesh, c: Vector3, n: Vector3, w0: float, w1: float, h: float) -> void:
	var r := Vector3.UP.cross(n).normalized()
	lm.quad("Shadow", c - r * w0 * 0.5, c + r * w0 * 0.5, c + r * w1 * 0.5 + Vector3(0, h, 0),
		c - r * w1 * 0.5 + Vector3(0, h, 0), n)
	lm.box("Stone", c + Vector3(0, h + 0.15, 0) + n * 0.08, Vector3(w1 + 0.6, 0.3, 0.25), Basis(r, Vector3.UP, n), 0.0)

## Temple of the Sun (Torreón): a curved tower of finely fitted ashlar
## on its granite outcrop, two trapezoidal windows and the Serpent Door,
## the rectangular precinct beside it.
static func _temple_of_sun(lm: LandmarkMesh, b: Vector3) -> void:
	lm.lathe("Shadow", b, PackedVector2Array([Vector2(5.0, 0.0), Vector2(4.6, 1.2), Vector2(3.6, 2.2),
		Vector2(0.0, 2.4)]), 12, 1.3, 1.0, 0.3, false)
	var top := b + Vector3(0, 2.2, 0)
	# D-shaped wall: a half-round lathe band plus its straight chord wall.
	var prof := PackedVector2Array([Vector2(4.6, 0.0), Vector2(4.5, 5.0), Vector2(4.48, 5.4)])
	var half := 10
	for k in half:
		var a0 := PI * float(k) / float(half)
		var a1 := PI * float(k + 1) / float(half)
		var d0 := Vector3(cos(a0), 0, -sin(a0))
		var d1 := Vector3(cos(a1), 0, -sin(a1))
		for j in prof.size() - 1:
			var p := prof[j]
			var q := prof[j + 1]
			lm.quad("Stone", top + d0 * p.x + Vector3(0, p.y, 0), top + d1 * p.x + Vector3(0, p.y, 0),
				top + d1 * q.x + Vector3(0, q.y, 0), top + d0 * q.x + Vector3(0, q.y, 0), (d0 + d1).normalized())
			lm.quad("Stone", top + d0 * (p.x - 0.8) + Vector3(0, p.y, 0), top + d1 * (p.x - 0.8) + Vector3(0, p.y, 0),
				top + d1 * (q.x - 0.8) + Vector3(0, q.y, 0), top + d0 * (q.x - 0.8) + Vector3(0, q.y, 0),
				-(d0 + d1).normalized())
		lm.quad("Stone", top + d0 * 3.7 + Vector3(0, 5.4, 0), top + d1 * 3.7 + Vector3(0, 5.4, 0),
			top + d1 * 4.5 + Vector3(0, 5.4, 0), top + d0 * 4.5 + Vector3(0, 5.4, 0), Vector3.UP)
	lm.box("Stone", top + Vector3(0, 2.7, 0.4), Vector3(9.8, 5.4, 0.8))
	for a in [PI * 0.3, PI * 0.7]:
		var d := Vector3(cos(float(a)), 0, -sin(float(a)))
		_trapezoid(lm, top + d * 4.62 + Vector3(0, 2.2, 0), d, 0.7, 0.5, 0.9)
	_trapezoid(lm, top + Vector3(0, 0, 0.82), Vector3.BACK, 1.0, 0.75, 2.0)
	# Precinct walls south of the tower.
	lm.box("Stone", b + Vector3(-6.0, 1.3, 7.0), Vector3(0.8, 2.6, 12.0))
	lm.box("Stone", b + Vector3(0, 1.3, 12.6), Vector3(12.0, 2.6, 0.8))

## Sacred Plaza: the Principal Temple (three walls of huge polygonal
## blocks, open to the plaza, a bench and niches), the Temple of the
## Three Windows facing east, and the Priest's House.
static func _sacred_plaza(lm: LandmarkMesh, b: Vector3) -> void:
	var y := b + Vector3(0, 0.12, 0)
	# Principal Temple, open to the south.
	lm.box("Stone", y + Vector3(0, 0.6, 0), Vector3(1.2, 1.2, 1.2))
	lm.box("Stone", y + Vector3(0, 2.4, -4.5), Vector3(11.0, 4.8, 1.2))
	for s in [-1.0, 1.0]:
		lm.box("Stone", y + Vector3(float(s) * 5.0, 2.2, -1.0), Vector3(1.2, 4.4, 8.0))
	lm.box("Stone", y + Vector3(0, 0.5, -3.4), Vector3(9.0, 1.0, 1.0))
	for k in 5:
		_trapezoid(lm, y + Vector3(-3.6 + 1.8 * float(k), 1.6, -3.88), Vector3.BACK, 0.8, 0.6, 1.1)
	# Temple of the Three Windows: an east wall with three big windows.
	var t := y + Vector3(9.0, 0, -1.0)
	lm.box("Stone", t + Vector3(0, 0.4, 0), Vector3(1.4, 0.8, 11.0))
	for k in 4:
		lm.box("Stone", t + Vector3(0, 2.6, -5.0 + 3.33 * float(k)), Vector3(1.4, 4.4, 1.2))
	lm.box("Stone", t + Vector3(0, 4.4, 0), Vector3(1.4, 0.8, 11.0))
	for k in 3:
		_trapezoid(lm, t + Vector3(0.72, 0.8, -3.33 + 3.33 * float(k)), Vector3.RIGHT, 2.0, 1.6, 2.6)
	for s in [-1.0, 1.0]:
		lm.box("Stone", t + Vector3(-4.0, 2.2, float(s) * 5.0), Vector3(8.0, 4.4, 1.0))
	# Priest's House beside it.
	lm.box("Stone", y + Vector3(-11.0, 1.4, -1.0), Vector3(6.0, 2.8, 9.0))
	lm.gable("Thatch", y + Vector3(-11.0, 2.8, -1.0), 6.0, 9.0, 2.4, Basis(), 0.5, "Stone")

## Stepped hill of seven curved terraces, its stairway and the
## Intihuatana: a carved granite block with its upright gnomon.
static func _intihuatana(lm: LandmarkMesh, base: Vector3) -> void:
	var rise := 1.2
	for k in 7:
		var f := float(k) / 6.0
		var rx := lerpf(14.0, 4.0, f)
		var rz := lerpf(11.0, 3.2, f)
		lm.lathe("Stone", base + Vector3(0, rise * float(k), 0), PackedVector2Array([Vector2(1.0, 0.0),
			Vector2(0.99, rise), Vector2(0.0, rise)]), 20, rx, rz)
		lm.lathe("Grass", base + Vector3(0, rise * float(k + 1), 0), PackedVector2Array([Vector2(0.98, 0.0),
			Vector2(0.0, 0.08)]), 20, rx, rz)
	for k in 21:
		lm.box("Stone", base + Vector3(15.0 - 12.0 * float(k) / 20.0, rise * 7.0 * (float(k) + 0.5) / 21.0, 0),
			Vector3(0.7, rise * 7.0 / 21.0, 2.0), Basis(), 0.0)
	var top := base + Vector3(0, rise * 7.0 + 0.08, 0)
	lm.box("Stone", top + Vector3(0, 0.4, 0), Vector3(3.6, 0.8, 2.4))
	lm.box("Stone", top + Vector3(0.6, 0.9, 0), Vector3(1.6, 0.4, 1.8))
	var g := top + Vector3(-0.4, 0.8, 0)
	lm.box("Stone", g + Vector3(0, 0.82, 0), Vector3(0.8, 1.64, 0.7), Basis(Vector3.UP, 0.4))
	lm.box("Stone", g + Vector3(0, 1.72, 0), Vector3(0.6, 0.18, 0.5), Basis(Vector3.UP, 0.4), 0.0)

# --- Ahu Tongariki ---

const AHU_H := 2.9
## Heights of the fifteen moai, west to east.
const MOAI_H := [5.2, 5.6, 4.8, 5.9, 5.0, 6.0, 5.4, 5.8, 5.1, 5.6, 4.9, 5.7, 5.3, 5.5, 4.6]
const MOAI_SPACING := 6.0
## Torso cross-section as [height, half width, half depth] fractions of
## the statue's height: base, belly, chest, shoulders, neck.
const TORSO := [[0.0, 0.2, 0.12], [0.18, 0.205, 0.126], [0.4, 0.2, 0.12], [0.56, 0.185, 0.11],
	[0.6, 0.15, 0.105], [0.62, 0.13, 0.1]]
## Head as [height, half width, half depth]: chin, jaw, cheeks, brow,
## flat crown.
const HEAD := [[0.6, 0.13, 0.11], [0.66, 0.14, 0.12], [0.78, 0.15, 0.12], [0.9, 0.15, 0.115],
	[0.97, 0.14, 0.1], [1.0, 0.12, 0.08]]

## The restored ahu (1992-96), about 100 m long: a dry-stone platform
## with a facing of fitted basalt slabs to the sea, side wings, a
## sloping pavement of beach boulders inland, fifteen tuff moai facing
## inland (-Z); the second from the right (west) wears its red scoria pukao and
## other pukao lie on the pavement in front.
static func moai(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Ahu", LandmarkMaterials.pbr("rock", "#4F4A44", 2.5))
	lm.use("Ramp", LandmarkMaterials.pbr("gravel", "#8F8271", 3.0))
	lm.use("Moai", LandmarkMaterials.pbr("stone", "#6B6459", 1.5))
	lm.use("Pukao", LandmarkMaterials.pbr("terracotta", "#8A4630", 1.0))
	_ahu(lm)
	for i in MOAI_H.size():
		var x := (float(i) - 7.0) * MOAI_SPACING
		_moai(lm, x, float(MOAI_H[i]), i == 1)
	for p in [[-30.0, -14.0, 0.3], [-8.0, -17.0, 1.2], [14.0, -13.0, 2.1], [33.0, -16.0, 0.8]]:
		var c := Vector3(float(p[0]), 0.9, float(p[1]))
		lm.lathe("Pukao", c + Vector3(0, -0.85, 0), PackedVector2Array([Vector2(0.0, 0.0),
			Vector2(0.85, 0.1), Vector2(0.9, 1.7), Vector2(0.0, 1.75)]), 12)
	lm.commit(model)

## Platform, sea wall of fitted slabs, wings and the inland pavement.
static func _ahu(lm: LandmarkMesh) -> void:
	lm.box("Ahu", Vector3(0, AHU_H * 0.5, 0), Vector3(98.0, AHU_H, 8.0))
	lm.box("Ahu", Vector3(0, AHU_H + 0.15, 0), Vector3(96.0, 0.3, 7.0))
	# Seaward facing: big fitted slabs of alternating size.
	for k in 32:
		var x := -47.0 + 3.0 * float(k) + 1.5
		var h := AHU_H * (0.95 if k % 2 == 0 else 0.8)
		lm.box("Ahu", Vector3(x, h * 0.5, 4.2), Vector3(2.8, h, 0.6), Basis(Vector3.UP, 0.02 * float(k % 3 - 1)))
	# Wings stepping down at either end.
	for s in [-1.0, 1.0]:
		for k in 3:
			var h := AHU_H * (0.8 - 0.22 * float(k))
			lm.box("Ahu", Vector3(float(s) * (52.0 + 4.0 * float(k)), h * 0.5, -0.5), Vector3(4.0, h, 7.0))
	# Inland pavement sloping from the platform to the ground.
	var top := AHU_H - 0.6
	for k in 6:
		var z0 := -4.0 - 5.0 * float(k)
		var y0 := top * (1.0 - float(k) / 6.0)
		var y1 := top * (1.0 - float(k + 1) / 6.0)
		lm.quad("Ramp", Vector3(-46, y0, z0), Vector3(46, y0, z0), Vector3(46, y1, z0 - 5.0),
			Vector3(-46, y1, z0 - 5.0), Vector3(0, 1.0, -0.12).normalized())
		# A curb of boulders on the pavement edge.
		for i in 12:
			var x := -44.0 + 8.0 * float(i) + float(k % 2) * 4.0
			lm.lathe("Ahu", Vector3(x, y1, z0 - 4.5), PackedVector2Array([Vector2(0.45, 0.0),
				Vector2(0.4, 0.3), Vector2(0.0, 0.42)]), 6)

## One moai of height h standing on the platform at x, facing -Z: a
## rounded tapering torso, the long head (3/8 of the statue) with its
## heavy brow, deep eye sockets, long nose, pouting lips, jutting chin
## and long ears; arms in relief with long fingers meeting at the hami.
static func _moai(lm: LandmarkMesh, x: float, h: float, topknot: bool) -> void:
	var b := Vector3(x, AHU_H + 0.3, 0)
	lm.grid("Moai", _rings(b, h, TORSO, 0.0), b + Vector3(0, h * 0.3, 0), true)
	lm.grid("Moai", _rings(b, h, HEAD, -0.015), b + Vector3(0, h * 0.8, 0), true)
	var top := HEAD[HEAD.size() - 1] as Array
	lm.lathe("Moai", b + Vector3(0, h, -0.015 * h), PackedVector2Array([Vector2(float(top[1]) * h, 0.0),
		Vector2(0.0, 0.004 * h)]), 16, 1.0, float(top[2]) / float(top[1]))
	var f := b + Vector3(0, 0, -0.135 * h)
	# Brow ridge, eye sockets under it, nose, nostrils, lips, chin.
	lm.box("Moai", f + Vector3(0, 0.865 * h, 0.0), Vector3(0.27 * h, 0.035 * h, 0.05 * h))
	for s in [-1.0, 1.0]:
		lm.box("Ahu", f + Vector3(float(s) * 0.06 * h, 0.82 * h, 0.022 * h), Vector3(0.07 * h, 0.035 * h, 0.01 * h), Basis(), 0.0)
		lm.box("Moai", f + Vector3(float(s) * 0.04 * h, 0.715 * h, -0.02 * h), Vector3(0.03 * h, 0.03 * h, 0.035 * h))
		# Long ears down the sides of the head.
		lm.box("Moai", b + Vector3(float(s) * 0.15 * h, 0.79 * h, 0.01 * h), Vector3(0.025 * h, 0.17 * h, 0.06 * h))
		# Arm down the flank and hand across the belly, four long fingers.
		lm.beam("Moai", b + Vector3(float(s) * 0.19 * h, 0.52 * h, -0.02 * h),
			b + Vector3(float(s) * 0.205 * h, 0.24 * h, -0.08 * h), 0.04 * h, 0.03 * h)
		lm.box("Moai", b + Vector3(float(s) * 0.17 * h, 0.22 * h, -0.122 * h), Vector3(0.06 * h, 0.05 * h, 0.02 * h))
		for k in 4:
			var fy := 0.205 * h + 0.012 * h * float(k)
			lm.beam("Moai", b + Vector3(float(s) * 0.14 * h, fy, -0.128 * h),
				b + Vector3(float(s) * 0.035 * h, fy - 0.02 * h, -0.13 * h), 0.009 * h, 0.012 * h)
	lm.beam("Moai", f + Vector3(0, 0.85 * h, 0.005 * h), f + Vector3(0, 0.71 * h, -0.045 * h), 0.06 * h, 0.05 * h)
	lm.box("Moai", f + Vector3(0, 0.665 * h, -0.012 * h), Vector3(0.11 * h, 0.022 * h, 0.03 * h))
	lm.box("Moai", f + Vector3(0, 0.62 * h, -0.004 * h), Vector3(0.14 * h, 0.035 * h, 0.04 * h))
	# Hami: the carved girdle across the front at the base.
	lm.box("Moai", b + Vector3(0, 0.11 * h, -0.125 * h), Vector3(0.3 * h, 0.03 * h, 0.012 * h))
	if topknot:
		lm.lathe("Pukao", b + Vector3(0, h - 0.01, 0), PackedVector2Array([Vector2(0.15 * h, 0.0),
			Vector2(0.17 * h, 0.03 * h), Vector2(0.17 * h, 0.1 * h), Vector2(0.09 * h, 0.115 * h),
			Vector2(0.0, 0.12 * h)]), 14)

## Closed rounded-rectangle rings (superellipse) for a lm.grid surface
## through the [height, half width, half depth] table, shifted forward
## by `fwd` x h.
static func _rings(b: Vector3, h: float, table: Array, fwd: float) -> Array:
	var rows: Array = []
	var n := 16
	for e in table:
		var row := PackedVector3Array()
		for i in n + 1:
			var a := TAU * float(i % n) / float(n)
			var cx := cos(a)
			var cz := sin(a)
			var sx := signf(cx) * pow(absf(cx), 0.6)
			var sz := signf(cz) * pow(absf(cz), 0.6)
			row.append(b + Vector3(sx * float(e[1]) * h, float(e[0]) * h, sz * float(e[2]) * h + fwd * h))
		rows.append(row)
	return rows
