class_name LandmarkSfPalace
extends RefCounted

## The Palace of Fine Arts in true metres on LandmarkMesh, y = 0 at the
## ground and the rotunda's centre at the origin, built along its long
## axis: +X is north, +Z east over the lagoon. The colonnades and the
## exhibition hall are arcs round one centre ARC_Z metres out in the
## lagoon (fitted to the mapped footprints).

const TOP_M := 49.4
const ARC_Z := 60.0
const COL_R := 93.5
const COL_HALF := 2.5
const COL_A0 := 162.0
const COL_A1 := 122.0
const COL_BAYS := 12
const COL_TAIL := 3
const COL_PED := 0.9
const COL_H := 13.9
const ENT_Y := 17.7
const HALL_R0 := 116.0
const HALL_R1 := 156.0
const HALL_A := 56.0
const HALL_WALL := 11.0
const HALL_RIDGE := 15.0
const HALL_SEGS := 40
const ROT_AP := 18.48

## Palace of Fine Arts (1915, Bernard Maybeck; rebuilt in concrete
## 1964-74): the open octagonal rotunda on the lagoon's west shore, its
## two curved Corinthian colonnades crowned by the "weeping women"
## planter boxes, and the long, plain curved exhibition hall behind,
## all in weathered ochre travertine render under a burnt-orange dome.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9A27C", 3.0))
	lm.use("Shaft", LandmarkMaterials.pbr("render", "#A65E4B", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("terracotta", "#B5683F", 3.0))
	lm.use("Hall", LandmarkMaterials.pbr("render", "#C4A587", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#8C8278", 4.0))
	lm.use("Dark", LandmarkMaterials.glass("#2B2724"))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B9AF9E", 3.0))
	_rotunda(lm)
	for s in [-1.0, 1.0]:
		_colonnade(lm, s)
	_hall(lm)
	lm.commit(model)

## Point on the arc of radius `rad` at `deg` degrees about the arc
## centre (180 = due west of it, on the rotunda's axis), height y.
static func _at(rad: float, deg: float, y: float) -> Vector3:
	var p := deg_to_rad(deg)
	return Vector3(rad * sin(p), y, ARC_Z + rad * cos(p))

## Horizontal unit vector away from the arc centre at `deg`.
static func _out(deg: float) -> Vector3:
	var p := deg_to_rad(deg)
	return Vector3(sin(p), 0, cos(p))

## The open octagonal rotunda: a paved terrace, eight arches between
## the corner piers, each pier fronted by four red-shafted Corinthian
## columns on pedestals under a projecting entablature and a tall
## sculptured box crowned by four figures; the octagonal entablature,
## the frieze band of relief panels and the ribbed burnt-orange dome,
## open beneath to its coffered ceiling.
static func _rotunda(lm: LandmarkMesh) -> void:
	lm.lathe("Pave", Vector3.ZERO, PackedVector2Array([Vector2(31.0, 0.0), Vector2(31.0, 0.5)]), 8,
		1.0, 1.0, PI / 8.0, false)
	var side := 2.0 * 20.0 * sin(PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3(-n.z, 0, n.x)
		var basis := Basis.looking_at(n)
		_arch_wall(lm, "Stone", n * ROT_AP + Vector3(0, 0.5, 0), n, side - 5.0, 18.5, 9.0, 11.0, 2.4)
		# Archivolt round the opening and the octagon's entablature.
		LandmarkDetail.arch(lm, "Stone", n * (ROT_AP + 1.2) + Vector3(0, 11.5, 0), n, 9.0, 0.7, 0.3, 14)
		lm.box("Stone", n * ROT_AP + Vector3(0, 20.4, 0), Vector3(side + 0.6, 2.8, 3.0), basis, 0.0)
		lm.box("Stone", n * (ROT_AP + 0.4) + Vector3(0, 22.15, 0), Vector3(side + 1.6, 0.7, 3.8), basis, 0.0)
		# Relief panels of the frieze band (Zimm's "Struggle for the Beautiful").
		for j in 3:
			lm.box("Stone", n * 17.8 + r * (float(j) - 1.0) * 4.4 + Vector3(0, 25.0, 0), Vector3(3.6, 3.0, 0.3), basis, 0.0)
		_corner(lm, a + PI / 8.0)
	# Frieze band, its cornice, and the inner face seen through the arches.
	lm.lathe("Stone", Vector3(0, 22.5, 0), PackedVector2Array([Vector2(19.2, 0.0), Vector2(19.2, 5.0),
		Vector2(19.9, 5.4), Vector2(19.9, 5.8), Vector2(17.6, 5.8)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Stone", Vector3(0, 19.0, 0), PackedVector2Array([Vector2(17.4, 8.6), Vector2(17.4, 0.0)]), 8,
		1.0, 1.0, PI / 8.0, false, false)
	# Dome: stepped base, the shell and its ribs, the crowning ring.
	var db := Vector3(0, 28.3, 0)
	lm.lathe("Stone", db, PackedVector2Array([Vector2(17.6, 0.0), Vector2(17.6, 1.2), Vector2(17.0, 1.2),
		Vector2(17.0, 2.0)]), 48)
	var sh := db + Vector3(0, 2.0, 0)
	var sr := 16.6
	var shh := 17.6
	lm.lathe("Dome", sh, LandmarkKits._dome_profile(sr, shh, 16), 56)
	var prof := LandmarkKits._dome_profile(sr + 0.1, shh + 0.1, 12)
	for i in 16:
		var d := Vector3(cos(TAU * float(i) / 16.0), 0, sin(TAU * float(i) / 16.0))
		for j in prof.size() - 3:
			lm.beam("Dome", sh + d * prof[j].x + Vector3(0, prof[j].y, 0),
				sh + d * prof[j + 1].x + Vector3(0, prof[j + 1].y, 0), 0.5, 0.25, d.cross(Vector3.UP))
	for ring_y in [3.0, 9.0]:
		var ry: float = ring_y
		var rr := sr * sqrt(1.0 - pow(ry / shh, 2.0))
		LandmarkNaParts.ring(lm, "Dome", sh + Vector3(0, ry, 0), rr + 0.05, 0.3, 0.4, 56)
	lm.frustum("Stone", sh + Vector3(0, shh - 0.8, 0), 3.0, 2.6, TOP_M - sh.y - shh + 0.8, 24)
	# Ceiling: the coffered underside, facing in.
	var inner := LandmarkKits._dome_profile(16.2, 18.6, 10)
	inner.reverse()
	lm.lathe("Stone", Vector3(0, 27.4, 0), inner, 32, 1.0, 1.0, 0.0, true, false)

## One corner of the rotunda at angle `a`: the pier, four columns on
## pedestals, their entablature block, and the sculptured box with a
## relief panel, and on its lid a block with four mourning figures.
static func _corner(lm: LandmarkMesh, a: float) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var t := Vector3(-d.z, 0, d.x)
	var basis := Basis.looking_at(d)
	lm.box("Stone", d * 18.8 + Vector3(0, 9.5, 0), Vector3(5.0, 19.0, 5.6), basis, 0.0)
	for rr in [22.2, 25.4]:
		for sd in [-1.0, 1.0]:
			var p: Vector3 = d * float(rr) + t * 2.1 * float(sd)
			lm.box("Stone", p + Vector3(0, 1.5, 0), Vector3(2.3, 3.0, 2.3), basis, 0.0)
			lm.box("Stone", p + Vector3(0, 3.15, 0), Vector3(2.6, 0.3, 2.6), basis, 0.0)
			_column(lm, "Shaft", p + Vector3(0, 3.3, 0), 0.85, 15.7, true)
	lm.box("Stone", d * 21.2 + Vector3(0, 20.4, 0), Vector3(7.4, 2.8, 11.0), basis, 0.0)
	lm.box("Stone", d * 21.4 + Vector3(0, 22.2, 0), Vector3(8.4, 0.8, 12.0), basis, 0.0)
	var bc := d * 22.6
	lm.box("Stone", bc + Vector3(0, 26.8, 0), Vector3(5.0, 8.4, 5.8), basis, 0.0)
	lm.box("Stone", bc + d * 3.0 + Vector3(0, 26.6, 0), Vector3(3.6, 5.0, 0.3), basis, 0.0)
	lm.box("Stone", bc + Vector3(0, 31.3, 0), Vector3(5.8, 0.6, 6.6), basis, 0.0)
	lm.box("Stone", bc + Vector3(0, 32.8, 0), Vector3(2.4, 2.4, 2.4), basis, 0.0)
	for q in 4:
		var f := basis * Vector3(cos(PI * 0.5 * float(q)), 0, sin(PI * 0.5 * float(q)))
		_mourner(lm, bc + Vector3(0, 31.6, 0) + f * 1.75, -f, 3.4)

## Corinthian column of height h (base to abacus), lower radius r: base
## mouldings and the bell capital in Stone, the shaft in `shaft_key`;
## `leaves` adds a ring of acanthus.
static func _column(lm: LandmarkMesh, shaft_key: String, base: Vector3, r: float, h: float, leaves: bool) -> void:
	var cap_h := r * 2.2
	var base_h := r * 0.7
	lm.lathe("Stone", base, PackedVector2Array([Vector2(r * 1.3, 0.0), Vector2(r * 1.25, base_h * 0.5),
		Vector2(r * 1.02, base_h)]), 10)
	var sh := h - cap_h - base_h
	lm.lathe(shaft_key, base + Vector3(0, base_h, 0), PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.98, sh * 0.4),
		Vector2(r * 0.86, sh)]), 10)
	var cb := base + Vector3(0, base_h + sh, 0)
	lm.lathe("Stone", cb, PackedVector2Array([Vector2(r * 0.9, 0.0), Vector2(r * 1.0, cap_h * 0.35),
		Vector2(r * 1.2, cap_h * 0.6), Vector2(r * 1.45, cap_h * 0.82)]), 10)
	lm.box("Stone", cb + Vector3(0, cap_h * 0.9, 0), Vector3(r * 2.9, cap_h * 0.2, r * 2.9), Basis(), 0.0)
	if leaves:
		for i in 8:
			var la := TAU * float(i) / 8.0
			var ld := Vector3(cos(la), 0, sin(la))
			lm.beam("Stone", cb + ld * r * 0.9, cb + ld * r * 1.35 + Vector3(0, cap_h * 0.55, 0), r * 0.5, r * 0.12,
				ld.cross(Vector3.UP))

## A draped mourning figure `h` tall standing at `foot`, leaning in to
## the box it faces along `facing` with its arms raised to the lid.
static func _mourner(lm: LandmarkMesh, foot: Vector3, facing: Vector3, h: float) -> void:
	lm.lathe("Stone", foot, PackedVector2Array([Vector2(h * 0.15, 0.0), Vector2(h * 0.12, h * 0.45),
		Vector2(h * 0.1, h * 0.72), Vector2(h * 0.05, h * 0.8)]), 6)
	lm.lathe("Stone", foot + facing * h * 0.08 + Vector3(0, h * 0.78, 0), PackedVector2Array([Vector2(0.0, 0.0),
		Vector2(h * 0.065, h * 0.07), Vector2(0.0, h * 0.16)]), 6)
	lm.beam("Stone", foot + Vector3(0, h * 0.68, 0), foot + facing * h * 0.2 + Vector3(0, h * 0.9, 0), h * 0.22, h * 0.06)

## A planter box on the entablature at `p` (lid level `p.y` + 3.9),
## aligned to `dir`, with a mourning woman leaning on each side.
static func _planter(lm: LandmarkMesh, p: Vector3, dir: Vector3) -> void:
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	lm.box("Stone", p + Vector3(0, 0.25, 0), Vector3(3.6, 0.5, 3.6), basis, 0.0)
	lm.box("Stone", p + Vector3(0, 2.0, 0), Vector3(2.4, 3.0, 2.4), basis, 0.0)
	lm.box("Stone", p + Vector3(0, 3.7, 0), Vector3(2.8, 0.4, 2.8), basis, 0.0)
	for q in 4:
		var f := basis * Vector3(cos(PI * 0.5 * float(q)), 0, sin(PI * 0.5 * float(q)))
		_mourner(lm, p + Vector3(0, 0.5, 0) + f * 1.55, -f, 2.7)

## A wall slab `w` wide, `h` tall and `t` thick (bottom centre `c`,
## facing `n`) pierced by a round-headed opening `span` wide springing
## at `spring`: both faces, the soffit, the jambs and the wall head.
static func _arch_wall(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, w: float, h: float,
		span: float, spring: float, t: float) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var hs := span * 0.5
	var segs := 12
	var up := Vector3.UP
	for face in [-1.0, 1.0]:
		var o: Vector3 = c + n * t * 0.5 * float(face)
		var fn: Vector3 = n * float(face)
		for sd in [-1.0, 1.0]:
			var s: float = sd
			lm.quad(key, o + r * s * hs, o + r * s * w * 0.5, o + r * s * w * 0.5 + up * h, o + r * s * hs + up * h, fn)
		for i in segs:
			var t0 := PI * float(i) / float(segs)
			var t1 := PI * float(i + 1) / float(segs)
			lm.quad(key, o + r * hs * cos(t0) + up * (spring + hs * sin(t0)), o + r * hs * cos(t1) + up * (spring + hs * sin(t1)),
				o + r * hs * cos(t1) + up * h, o + r * hs * cos(t0) + up * h, fn)
	var hn := n * t * 0.5
	for i in segs:
		var t0 := PI * float(i) / float(segs)
		var t1 := PI * float(i + 1) / float(segs)
		var p0 := c + r * hs * cos(t0) + up * (spring + hs * sin(t0))
		var p1 := c + r * hs * cos(t1) + up * (spring + hs * sin(t1))
		var tm := (t0 + t1) * 0.5
		lm.quad(key, p0 - hn, p1 - hn, p1 + hn, p0 + hn, -(r * cos(tm) + up * sin(tm)))
	for sd in [-1.0, 1.0]:
		var s: float = sd
		var j := c + r * s * hs
		lm.quad(key, j - hn, j + hn, j + hn + up * spring, j - hn + up * spring, -r * s)
	lm.quad(key, c - r * w * 0.5 - hn + up * h, c + r * w * 0.5 - hn + up * h, c + r * w * 0.5 + hn + up * h,
		c - r * w * 0.5 + hn + up * h, up)

## One colonnade (s = 1 north, -1 south): two rows of Corinthian
## columns on low pedestals along the arc and a short straight run to
## the end pavilion, each row carrying its entablature, with planter
## boxes and their mourners over every third pair, on a paved walk.
static func _colonnade(lm: LandmarkMesh, s: float) -> void:
	var rows_in: Array[Vector3] = []
	var rows_out: Array[Vector3] = []
	var tans: Array[Vector3] = []
	var step := (COL_A0 - COL_A1) / float(COL_BAYS)
	var bay := COL_R * deg_to_rad(step)
	var arc_end := Vector3.ZERO
	for k in COL_BAYS + COL_TAIL + 1:
		var c: Vector3
		var nrm: Vector3
		var tan: Vector3
		if k <= COL_BAYS:
			var phi := deg_to_rad(COL_A0 - step * float(k))
			c = Vector3(s * COL_R * sin(phi), 0, ARC_Z + COL_R * cos(phi))
			nrm = Vector3(s * sin(phi), 0, cos(phi))
			tan = Vector3(-s * cos(phi), 0, sin(phi))
			arc_end = c
		else:
			c = arc_end + Vector3(s * bay * float(k - COL_BAYS), 0, 0)
			nrm = Vector3(0, 0, -1)
			tan = Vector3(s, 0, 0)
		rows_in.append(c - nrm * COL_HALF)
		rows_out.append(c + nrm * COL_HALF)
		tans.append(tan)
	var count := rows_in.size()
	for row in [rows_in, rows_out]:
		var pts: Array[Vector3] = row
		for k in count:
			var p := pts[k]
			lm.box("Stone", p + Vector3(0, COL_PED * 0.5, 0), Vector3(1.9, COL_PED, 1.9), Basis(), 0.0)
			_column(lm, "Stone", p + Vector3(0, COL_PED, 0), 0.72, COL_H, false)
			if k % 3 == 0:
				_planter(lm, p + Vector3(0, ENT_Y, 0), tans[k])
		for k in count - 1:
			var a := pts[k]
			var b := pts[k + 1]
			var dir := (b - a).normalized()
			var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
			var mid := (a + b) * 0.5
			var run := a.distance_to(b)
			lm.box("Stone", mid + Vector3(0, (COL_PED + COL_H + ENT_Y - 0.7) * 0.5, 0),
				Vector3(run + 0.6, ENT_Y - 0.7 - COL_PED - COL_H, 1.7), basis, 0.0)
			lm.box("Stone", mid + Vector3(0, ENT_Y - 0.35, 0), Vector3(run + 1.0, 0.7, 2.5), basis, 0.0)
	# Paved walk under the colonnade.
	for k in count - 1:
		var w0 := (rows_out[k] - rows_in[k]).normalized() * 2.2
		var w1 := (rows_out[k + 1] - rows_in[k + 1]).normalized() * 2.2
		lm.quad("Pave", rows_in[k] - w0 + Vector3(0, 0.12, 0), rows_in[k + 1] - w1 + Vector3(0, 0.12, 0),
			rows_out[k + 1] + w1 + Vector3(0, 0.12, 0), rows_out[k] + w0 + Vector3(0, 0.12, 0), Vector3.UP)
	# End pavilion past the last pair, crowned by a planter.
	var tail := (rows_in[count - 1] + rows_out[count - 1]) * 0.5 + Vector3(s * 4.2, 0, 0)
	lm.box("Stone", tail + Vector3(0, ENT_Y * 0.5, 0), Vector3(5.4, ENT_Y, 8.4), Basis(), 0.0)
	lm.box("Stone", tail + Vector3(s * 2.75, 8.0, 0), Vector3(0.3, 7.0, 4.4), Basis(), 0.0)
	lm.box("Stone", tail + Vector3(0, ENT_Y + 0.3, 0), Vector3(6.2, 0.6, 9.2), Basis(), 0.0)
	_planter(lm, tail + Vector3(0, ENT_Y + 0.6, 0), Vector3(s, 0, 0))

## The exhibition hall: a 40 m deep arc of plain rendered wall behind
## the colonnades (its 1915 ornament was never rebuilt) under a low
## gabled roof with a glazed monitor along the ridge; pilasters, cornice
## bands and doors on the inner front, and gabled end walls.
static func _hall(lm: LandmarkMesh) -> void:
	var a0 := 180.0 - HALL_A
	var step := HALL_A * 2.0 / float(HALL_SEGS)
	var r_mid := (HALL_R0 + HALL_R1) * 0.5
	var rise := HALL_RIDGE - HALL_WALL
	var run := r_mid - HALL_R0
	var m0 := r_mid - 5.0
	var m1 := r_mid + 5.0
	var my := HALL_WALL + (m0 - HALL_R0) * rise / run
	for i in HALL_SEGS:
		var pa := a0 + step * float(i)
		var pb := pa + step
		var nm := _out(pa + step * 0.5)
		lm.quad("Hall", _at(HALL_R0, pa, 0.0), _at(HALL_R0, pb, 0.0), _at(HALL_R0, pb, HALL_WALL), _at(HALL_R0, pa, HALL_WALL), -nm)
		lm.quad("Hall", _at(HALL_R1, pa, 0.0), _at(HALL_R1, pb, 0.0), _at(HALL_R1, pb, HALL_WALL), _at(HALL_R1, pa, HALL_WALL), nm)
		var eave := HALL_WALL - 0.8 * rise / run
		lm.quad("Roof", _at(HALL_R0 - 0.8, pa, eave), _at(HALL_R0 - 0.8, pb, eave), _at(r_mid, pb, HALL_RIDGE),
			_at(r_mid, pa, HALL_RIDGE), (-nm * rise + Vector3.UP * run).normalized())
		lm.quad("Roof", _at(HALL_R1 + 0.8, pa, eave), _at(HALL_R1 + 0.8, pb, eave), _at(r_mid, pb, HALL_RIDGE),
			_at(r_mid, pa, HALL_RIDGE), (nm * rise + Vector3.UP * run).normalized())
		# Glazed monitor along the ridge.
		lm.quad("Dark", _at(m0, pa, my), _at(m0, pb, my), _at(m0, pb, 16.2), _at(m0, pa, 16.2), -nm)
		lm.quad("Dark", _at(m1, pa, my), _at(m1, pb, my), _at(m1, pb, 16.2), _at(m1, pa, 16.2), nm)
		lm.quad("Roof", _at(m0 - 0.4, pa, 16.1), _at(m0 - 0.4, pb, 16.1), _at(r_mid, pb, 17.0), _at(r_mid, pa, 17.0),
			(-nm * 0.8 + Vector3.UP * 5.0).normalized())
		lm.quad("Roof", _at(m1 + 0.4, pa, 16.1), _at(m1 + 0.4, pb, 16.1), _at(r_mid, pb, 17.0), _at(r_mid, pa, 17.0),
			(nm * 0.8 + Vector3.UP * 5.0).normalized())
		# Cornice and base bands on both fronts, pilasters on the inner.
		for rr in [HALL_R0 - 0.35, HALL_R1 + 0.35]:
			lm.beam("Hall", _at(float(rr), pa, HALL_WALL - 0.5), _at(float(rr), pb, HALL_WALL - 0.5), 0.9, 0.7)
			lm.beam("Hall", _at(float(rr), pa, 0.5), _at(float(rr), pb, 0.5), 1.0, 0.7)
		lm.box("Hall", _at(HALL_R0 - 0.25, pa, HALL_WALL * 0.5), Vector3(1.0, HALL_WALL, 0.5), Basis.looking_at(_out(pa)), 0.0)
		if i % 4 == 2:
			var c := _at(HALL_R0 - 0.06, pa + step * 0.5, 0.0)
			var tg := Vector3(-nm.z, 0, nm.x)
			lm.quad("Dark", c - tg * 1.8, c + tg * 1.8, c + tg * 1.8 + Vector3(0, 5.0, 0), c - tg * 1.8 + Vector3(0, 5.0, 0), -nm)
	for e in [a0, a0 + HALL_A * 2.0]:
		var deg: float = e
		var p := deg_to_rad(deg)
		var tn := Vector3(cos(p), 0, -sin(p)) * (-1.0 if deg < 180.0 else 1.0)
		lm.quad("Hall", _at(HALL_R0, deg, 0.0), _at(HALL_R1, deg, 0.0), _at(HALL_R1, deg, HALL_WALL),
			_at(HALL_R0, deg, HALL_WALL), tn)
		lm.tri("Hall", _at(HALL_R0, deg, HALL_WALL), _at(HALL_R1, deg, HALL_WALL), _at(r_mid, deg, HALL_RIDGE), tn, tn, tn,
			Vector2(0, 0), Vector2(HALL_R1 - HALL_R0, 0), Vector2(run, -rise))
		var ofs := tn * 0.05
		lm.quad("Hall", _at(m0, deg, my) + ofs, _at(m1, deg, my) + ofs, _at(m1, deg, 16.2) + ofs, _at(m0, deg, 16.2) + ofs, tn)
		lm.tri("Hall", _at(m0, deg, 16.2) + ofs, _at(m1, deg, 16.2) + ofs, _at(r_mid, deg, 17.0) + ofs, tn, tn, tn,
			Vector2(0, 0), Vector2(m1 - m0, 0), Vector2(5.0, -0.8))
