class_name LandmarkSaoRio
extends RefCounted

## Rio de Janeiro: Christ the Redeemer and the Metropolitan Cathedral of
## Saint Sebastian, in true metres.

# --- Christ the Redeemer ---

const STATUE_Y := 8.0
const ARM_SPAN := 28.0
const SHOULDER_Y := STATUE_Y + 23.0
## Robe outline as (radius, height above the pedestal): hem, skirt
## narrowing to the girdle, chest, shoulders and neck.
static var ROBE := PackedVector2Array([Vector2(2.75, 0.0), Vector2(2.6, 1.2), Vector2(2.4, 5.0),
	Vector2(2.05, 11.0), Vector2(1.7, 16.0), Vector2(1.62, 17.2), Vector2(1.78, 20.0),
	Vector2(2.08, 22.0), Vector2(2.15, 22.9), Vector2(1.85, 24.4), Vector2(1.05, 25.5),
	Vector2(0.68, 26.1), Vector2(0.6, 26.9)])

## Art Deco statue by Paul Landowski and Heitor da Silva Costa (1931):
## 30 m of reinforced concrete faced in soapstone, arms 28 m across, on
## an 8 m pedestal holding the Nossa Senhora Aparecida chapel. The robe
## falls in straight Art Deco pleats, a cord girds the waist, the
## Sacred Heart stands on the chest and wide sleeves hang under the
## level arms. Built facing -Z; the registry yaw turns it east over
## Guanabara Bay.
static func christ(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Soapstone", LandmarkMaterials.pbr("limestone", "#C7CBBE", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#908A80", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	_pedestal(lm)
	_body(lm)
	_arms(lm)
	_head(lm)
	lm.commit(model)

## Terrace slab with steps, the tapering chapel block with Art Deco
## fins and stepped cap to y = 8; the chapel door is at the back.
static func _pedestal(lm: LandmarkMesh) -> void:
	lm.box("Granite", Vector3(0, 0.3, 0), Vector3(17.0, 0.6, 17.0))
	for k in 3:
		lm.box("Granite", Vector3(0, 0.1 + 0.2 * float(k), 8.9 + 0.4 * float(2 - k)),
			Vector3(6.0, 0.2, 0.4), Basis(), 0.0)
	lm.box("Granite", Vector3(0, 1.0, 0), Vector3(10.4, 0.8, 10.4))
	lm.spire("Granite", Vector3(0, 1.4, 0), 4.7, 5.6, 4.1)
	lm.box("Granite", Vector3(0, 7.25, 0), Vector3(9.0, 0.5, 9.0))
	lm.box("Granite", Vector3(0, 7.75, 0), Vector3(7.6, 0.5, 7.6))
	# Three shallow fins up each face, leaning with the taper.
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		for f in [-2.6, 0.0, 2.6]:
			var lo: Vector3 = rot * Vector3(float(f), 1.4, -4.78)
			var hi: Vector3 = rot * Vector3(float(f) * 0.87, 7.0, -4.18)
			lm.beam("Granite", lo, hi, 0.55, 0.35, rot * Vector3.RIGHT)
	# Chapel door (back), with a stepped Art Deco surround.
	lm.box("Windows", Vector3(0, 3.0, 4.66), Vector3(1.6, 3.0, 0.1), Basis(), 0.0)
	lm.box("Granite", Vector3(0, 4.7, 4.6), Vector3(2.6, 0.4, 0.5))
	for s in [-1.0, 1.0]:
		lm.box("Granite", Vector3(float(s) * 1.0, 3.0, 4.62), Vector3(0.4, 3.0, 0.45))
		# Slit windows on the side faces.
		lm.box("Windows", Vector3(float(s) * 4.45, 4.6, 0), Vector3(0.1, 2.0, 0.5), Basis(), 0.0)

## Robe, pleats, girdle cord and the Sacred Heart.
static func _body(lm: LandmarkMesh) -> void:
	var base := Vector3(0, STATUE_Y, 0)
	lm.lathe("Soapstone", base, ROBE, 28, 1.0, 0.78)
	# Feet under the hem.
	for s in [-1.0, 1.0]:
		lm.box("Soapstone", base + Vector3(float(s) * 0.7, 0.25, -2.2), Vector3(0.75, 0.5, 1.1))
	# Straight pleats down the skirt and over the chest.
	for k in 20:
		var a := TAU * (float(k) + 0.5) / 20.0
		var d := Vector3(cos(a), 0, sin(a) * 0.78)
		var prev := Vector3.ZERO
		for j in 6:
			var y := lerpf(0.3, 21.5, float(j) / 5.0)
			var p := base + d * (LandmarkMesh.profile_at(_robe_table(), y) + 0.08) + Vector3(0, y, 0)
			if j > 0:
				lm.beam("Soapstone", prev, p, 0.42, 0.3, d.cross(Vector3.UP))
			prev = p
	# Girdle cord with its knot and two hanging ends.
	lm.frustum("Soapstone", base + Vector3(0, 16.3, 0), 1.78, 1.76, 0.5, 28, 0.0, 1.0, 0.8)
	lm.box("Soapstone", base + Vector3(0, 16.5, -1.42), Vector3(0.6, 0.6, 0.4))
	for s in [-1.0, 1.0]:
		lm.beam("Soapstone", base + Vector3(float(s) * 0.15, 16.3, -1.45),
			base + Vector3(float(s) * 0.35, 12.8, -1.75), 0.28, 0.24)
	# Sacred Heart: a heart of two lobes and a point, with its rays.
	var h := base + Vector3(0, 20.3, -1.62)
	for s in [-1.0, 1.0]:
		lm.box("Soapstone", h + Vector3(float(s) * 0.22, 0.12, 0), Vector3(0.5, 0.5, 0.3))
	lm.box("Soapstone", h + Vector3(0, -0.2, -0.02), Vector3(0.5, 0.5, 0.28), Basis(Vector3.BACK, PI * 0.25))
	for k in 5:
		var a := PI * (0.15 + 0.7 * float(k) / 4.0)
		lm.beam("Soapstone", h + Vector3(cos(a) * 0.5, 0.2 + sin(a) * 0.5, 0.05),
			h + Vector3(cos(a) * 0.9, 0.2 + sin(a) * 0.9, 0.05), 0.08, 0.1)

## ROBE as a (height, radius) table for profile_at.
static func _robe_table() -> PackedVector2Array:
	var t := PackedVector2Array()
	for p in ROBE:
		t.append(Vector2(p.y, p.x))
	return t

## Both arms: tapering upper arm and forearm in their sleeves, the open
## hands with fingers, and the wide sleeve hanging in a curve below.
static func _arms(lm: LandmarkMesh) -> void:
	var half := ARM_SPAN * 0.5
	for sv in [-1.0, 1.0]:
		var s: float = sv
		var sh := Vector3(s * 1.5, SHOULDER_Y, 0)
		var el := Vector3(s * 7.6, SHOULDER_Y - 0.25, 0)
		var wr := Vector3(s * (half - 2.4), SHOULDER_Y - 0.6, 0)
		var segs := 6
		for k in segs:
			var t0 := float(k) / segs
			var t1 := float(k + 1) / segs
			var a := sh.lerp(el, t0)
			var b := sh.lerp(el, t1)
			lm.beam("Soapstone", a, b, lerpf(2.2, 1.6, t0), lerpf(1.8, 1.3, t0))
			lm.beam("Soapstone", el.lerp(wr, t0), el.lerp(wr, t1), lerpf(1.6, 1.15, t0), lerpf(1.3, 0.95, t0))
		# Sleeve cuff and the open hand: palm, four fingers, thumb.
		lm.beam("Soapstone", wr - Vector3(s * 0.6, 0, 0), wr + Vector3(s * 0.15, 0, 0), 1.6, 1.4)
		var palm := wr + Vector3(s * 0.75, -0.05, 0)
		lm.box("Soapstone", palm, Vector3(1.1, 1.0, 0.36))
		for f in 4:
			var fy := 0.33 - 0.22 * float(f)
			var fl := 1.15 if f == 1 else (0.95 if f == 3 else 1.05)
			lm.beam("Soapstone", palm + Vector3(s * 0.5, fy, 0), palm + Vector3(s * (0.5 + fl), fy - 0.06, -0.04),
				0.2, 0.22)
		lm.beam("Soapstone", palm + Vector3(s * 0.15, 0.45, -0.1), palm + Vector3(s * 0.6, 0.9, -0.2), 0.22, 0.22)
		_sleeve(lm, s)

## One hanging sleeve: a curtain of cloth under the arm from the
## shoulder (deepest, 4 m) to the cuff, front and back faces and hem.
static func _sleeve(lm: LandmarkMesh, s: float) -> void:
	var cols := 9
	var front: Array = []
	var back: Array = []
	for r in 5:
		var fr := PackedVector3Array()
		var bk := PackedVector3Array()
		for c in cols:
			var t := float(c) / float(cols - 1)
			var x := s * lerpf(2.0, ARM_SPAN * 0.5 - 2.0, t)
			var top := SHOULDER_Y - 0.6 - 0.45 * t
			var drop := lerpf(4.4, 0.5, pow(t, 0.8))
			var y := top - drop * float(r) / 4.0
			var bulge := 0.5 + 0.15 * sin(PI * float(r) / 4.0)
			fr.append(Vector3(x, y, -bulge))
			bk.append(Vector3(x, y, bulge))
		front.append(fr)
		back.append(bk)
	lm.grid("Soapstone", front, Vector3(0, 0, -1))
	lm.grid("Soapstone", back, Vector3(0, 0, 1))
	var fl: PackedVector3Array = front[4]
	var bl: PackedVector3Array = back[4]
	for c in cols - 1:
		lm.quad("Soapstone", fl[c], fl[c + 1], bl[c + 1], bl[c], Vector3.DOWN)

## Neck, head bowed a little, the face (brow, nose, beard) and the
## shoulder-length hair parted in the middle.
static func _head(lm: LandmarkMesh) -> void:
	var b := Vector3(0, STATUE_Y + 26.8, 0)
	var head := PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.85, 0.35), Vector2(1.05, 1.0),
		Vector2(1.18, 1.8), Vector2(1.12, 2.4), Vector2(0.9, 2.9), Vector2(0.5, 3.15), Vector2(0.0, 3.25)])
	lm.lathe("Soapstone", b, head, 18, 1.0, 0.92)
	# Beard and moustache.
	lm.lathe("Soapstone", b + Vector3(0, 0.1, -0.35), PackedVector2Array([Vector2(0.3, 0.0),
		Vector2(0.75, 0.5), Vector2(0.85, 1.1), Vector2(0.0, 1.2)]), 12, 1.0, 0.8)
	lm.box("Soapstone", b + Vector3(0, 1.55, -1.0), Vector3(0.3, 0.75, 0.4))
	lm.box("Soapstone", b + Vector3(0, 2.05, -1.0), Vector3(1.2, 0.18, 0.25))
	# Hair falling behind the shoulders, parted at the crown.
	lm.lathe("Soapstone", b + Vector3(0, -0.8, 0.25), PackedVector2Array([Vector2(1.0, 0.0),
		Vector2(1.25, 1.2), Vector2(1.3, 2.6), Vector2(1.2, 3.3), Vector2(0.0, 3.85)]), 18, 1.0, 0.85)
	lm.box("Soapstone", b + Vector3(0, 3.15, -0.2), Vector3(0.08, 0.2, 1.6), Basis(), 0.0)

# --- Metropolitan Cathedral of Rio de Janeiro ---

const CONE_H := 75.0
const BASE_R := 53.0
const TOP_R := 30.0
const ROWS := 18
const FINS := 72
## The four 64 m windows: 17.8 m wide at the foot, 9.6 m at the roof.
const WIN_Y0 := 12.0
const WIN_W0 := 17.8
const WIN_W1 := 9.6

## Edgar Fonseca's truncated concrete cone (1964-79): 75 m high, 106 m
## across the foot. Its flank is a lattice of eighteen rows of deep
## rectangular cells; four stained-glass windows 64 m tall run up the
## flank at the cardinal points and cross the flat roof as a glazed
## cross; bronze doors under each window; and a separate bell tower.
static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9C968C", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F5A6B"))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5A4632", 2.0, 0.45, 0.7))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#B9B3A6", 4.0))
	lm.frustum("Plaza", Vector3.ZERO, BASE_R + 9.0, BASE_R + 8.0, 0.3, 64)
	lm.lathe("Concrete", Vector3(0, 0.3, 0), PackedVector2Array([Vector2(BASE_R, 0.0),
		Vector2(TOP_R, CONE_H - 0.3)]), 72)
	_lattice(lm)
	for k in 4:
		_window_strip(lm, PI * 0.5 * float(k))
	_roof(lm)
	_campanile(lm, Vector3(-74.0, 0, 30.0))
	lm.commit(model)

static func _cone_r(y: float) -> float:
	return lerpf(BASE_R, TOP_R, y / CONE_H)

## True when azimuth `a` falls inside one of the window strips at y.
static func _in_window(a: float, y: float) -> bool:
	if y < 1.0:
		return false
	var half := (lerpf(WIN_W0, WIN_W1, clampf((y - WIN_Y0) / (CONE_H - WIN_Y0), 0.0, 1.0)) * 0.5 + 1.2) / _cone_r(y)
	for k in 4:
		var d := absf(wrapf(a - PI * 0.5 * float(k), -PI, PI))
		if d < half:
			return true
	return false

## The cellular flank: a projecting ledge ring at every row line and a
## radial fin between the cells, broken where the windows run.
static func _lattice(lm: LandmarkMesh) -> void:
	var row_h := (CONE_H - 3.0) / float(ROWS)
	for j in ROWS + 1:
		var y := 3.0 + row_h * float(j)
		var r := _cone_r(y)
		lm.lathe("Concrete", Vector3(0, y - 0.3, 0), PackedVector2Array([Vector2(_cone_r(y - 0.3), 0.0),
			Vector2(r + 1.1, 0.05), Vector2(r + 1.1, 0.55), Vector2(_cone_r(y + 0.3), 0.6)]), 96, 1.0, 1.0,
			0.0, true, false)
	for j in ROWS:
		var y0 := 3.0 + row_h * float(j) + 0.3
		var y1 := y0 + row_h - 0.6
		for i in FINS:
			var a := TAU * float(i) / float(FINS)
			if _in_window(a, y0) or _in_window(a, y1):
				continue
			var d := Vector3(cos(a), 0, sin(a))
			var p0 := d * (_cone_r(y0) + 0.5) + Vector3(0, y0, 0)
			var p1 := d * (_cone_r(y1) + 0.5) + Vector3(0, y1, 0)
			lm.beam("Concrete", p0, p1, 0.5, 1.0, d.cross(Vector3.UP))

## One window at azimuth `a`: glass panes up the flank between concrete
## frames, transoms at each lattice row, and the bronze doorway below.
static func _window_strip(lm: LandmarkMesh, a: float) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var t := Vector3(-sin(a), 0, cos(a))
	var steps := 18
	var slope := (BASE_R - TOP_R) / CONE_H
	var n := (d + Vector3.UP * slope).normalized()
	for j in steps:
		var y0 := lerpf(WIN_Y0, CONE_H, float(j) / steps)
		var y1 := lerpf(WIN_Y0, CONE_H, float(j + 1) / steps)
		var w0 := lerpf(WIN_W0, WIN_W1, float(j) / steps) * 0.5
		var w1 := lerpf(WIN_W0, WIN_W1, float(j + 1) / steps) * 0.5
		var c0 := d * (_cone_r(y0) + 0.05) + Vector3(0, y0, 0)
		var c1 := d * (_cone_r(y1) + 0.05) + Vector3(0, y1, 0)
		lm.quad("Glass", c0 - t * w0, c0 + t * w0, c1 + t * w1, c1 - t * w1, n)
		# Transom and three mullions.
		lm.beam("Concrete", c0 - t * w0 + n * 0.2, c0 + t * w0 + n * 0.2, 0.35, 0.4, n)
		for m in [-0.5, 0.0, 0.5]:
			lm.beam("Concrete", c0 + t * w0 * float(m) + n * 0.15, c1 + t * w1 * float(m) + n * 0.15, 0.25, 0.3, n)
		# Deep side frames.
		for s in [-1.0, 1.0]:
			lm.beam("Concrete", c0 + t * (w0 + 0.6) * float(s) + n * 0.5, c1 + t * (w1 + 0.6) * float(s) + n * 0.5,
				1.2, 1.4, n)
	# Doorway: a tall bronze door set in a projecting concrete portal.
	var foot := d * (_cone_r(0.0) + 0.2) + Vector3(0, 0.3, 0)
	var basis := Basis(t, Vector3.UP, d)
	lm.box("Concrete", foot + d * 1.6 + Vector3(0, 11.2, 0), Vector3(WIN_W0 + 3.0, 1.6, 3.6), basis)
	for s in [-1.0, 1.0]:
		lm.box("Concrete", foot + d * 1.6 + t * (WIN_W0 * 0.5 + 0.7) * float(s) + Vector3(0, 5.6, 0),
			Vector3(1.4, 11.2, 3.6), basis)
	lm.box("Bronze", foot + d * 0.4 + Vector3(0, 5.3, 0), Vector3(WIN_W0 - 0.4, 10.6, 0.3), basis, 0.0)
	# Relief panels on the doors: a 4 x 6 grid of raised squares.
	for i in 4:
		for j in 6:
			lm.box("Bronze", foot + d * 0.62 + t * (-6.3 + 4.2 * float(i)) + Vector3(0, 1.2 + 1.65 * float(j), 0),
				Vector3(3.4, 1.3, 0.16), basis, 0.0)

## Flat roof ring with its parapet and the glazed cross where the four
## windows meet, with its frames.
static func _roof(lm: LandmarkMesh) -> void:
	var y := CONE_H
	lm.frustum("Concrete", Vector3(0, y - 0.2, 0), TOP_R + 0.6, TOP_R + 0.6, 1.4, 72)
	for k in 2:
		var basis := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.box("Glass", Vector3(0, y + 0.35, 0), Vector3(WIN_W1, 0.5, TOP_R * 2.0 - 0.6), basis, 0.0)
		for s in [-1.0, 1.0]:
			lm.box("Concrete", basis * Vector3(float(s) * (WIN_W1 * 0.5 + 0.3), y + 0.6, 0),
				Vector3(0.6, 1.0, TOP_R * 2.0 - 0.6), basis)
		for i in 13:
			var z := -TOP_R + 3.0 + float(i) * (TOP_R * 2.0 - 6.0) / 12.0
			lm.box("Concrete", basis * Vector3(0, y + 0.7, z), Vector3(WIN_W1, 0.3, 0.3), basis, 0.0)

## Bell tower: two concrete slabs joined by bell beams, the bells
## between them, a cross on top.
static func _campanile(lm: LandmarkMesh, b: Vector3) -> void:
	for s in [-1.0, 1.0]:
		lm.box("Concrete", b + Vector3(float(s) * 2.6, 12.0, 0), Vector3(1.2, 24.0, 6.0))
	lm.box("Concrete", b + Vector3(0, 0.5, 0), Vector3(8.0, 1.0, 8.0))
	for y in [8.0, 14.0, 20.0, 24.4]:
		lm.box("Concrete", b + Vector3(0, float(y), 0), Vector3(6.4, 0.8, 6.0))
	for k in 3:
		var bell := b + Vector3(0, 9.8 + 6.0 * float(k), 0)
		lm.lathe("Bronze", bell, PackedVector2Array([Vector2(1.2, 0.0), Vector2(1.0, 0.4),
			Vector2(0.75, 1.3), Vector2(0.6, 1.9), Vector2(0.0, 2.1)]), 14)
	lm.box("Concrete", b + Vector3(0, 27.5, 0), Vector3(0.6, 5.4, 0.6))
	lm.box("Concrete", b + Vector3(0, 28.6, 0), Vector3(3.0, 0.6, 0.6))
