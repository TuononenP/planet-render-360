class_name LandmarkSfCivic
extends RefCounted

## San Francisco City Hall in true metres on LandmarkMesh, built about
## its centre with y = 0 at the ground: the Polk Street front faces +X,
## McAllister Street -Z. The Palace of Fine Arts is LandmarkSfPalace.

const CH_HX := 44.0
const CH_HZ := 62.0
const CH_SKIN := 0.35
const CH_PAV := 12.0
const CH_PAV_OUT := 1.2
const CH_PW := 14.5
const CH_COURT_X := 20.0
const CH_COURT_Z0 := 22.0
const CH_COURT_Z1 := 35.0
const CH_CORE_TOP := 31.0
const CH_GROUND := 9.0
const CH_ORDER := 22.0
const CH_CORNICE := 24.5
const CH_ATTIC := 27.5
const CH_TOP_M := 93.7

## San Francisco City Hall (1915, Arthur Brown Jr.): the pale granite
## Beaux-Arts block of two city blocks round two light courts. The Polk
## Street front (+X) and the matching Van Ness front (-X) each run a
## rusticated ground storey under a giant Doric colonnade between
## projecting corner pavilions, with a central pedimented portico of six
## columns over three arched doors; the raised rotunda block, the drum
## of sixteen paired Doric columns round pedimented windows, the attic
## of pinnacles, the grey-green ribbed dome with gilded ribs and
## cartouches, and the lantern and spire to 93.7 m.
static func city_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#C9C6BC", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D8D4CA", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#7F8588", 4.0))
	lm.use("Dome", LandmarkMaterials.paint("#6C7A73", 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	_ch_mass(lm)
	for s in [-1.0, 1.0]:
		_ch_front(lm, s)
		_ch_side(lm, s)
		for t in [-1.0, 1.0]:
			_ch_pavilion(lm, s, t)
	_ch_dome(lm, Vector3(0, CH_CORE_TOP, 0))
	lm.commit(model)

## Granite plinth, the four ranges round the two light courts (glazed
## inside), their flat roofs, and the raised rotunda block between the
## courts with its cornice, balustrade and attic lights.
static func _ch_mass(lm: LandmarkMesh) -> void:
	lm.box("Trim", Vector3(0, 0.6, 0), Vector3(CH_HX * 2.0 + 3.0, 1.2, CH_HZ * 2.0 + 3.0), Basis(), 0.0)
	var hx := CH_HX - CH_SKIN
	var hz := CH_HZ - CH_SKIN
	var ranges := [[CH_COURT_X, hx, -hz, hz], [-hx, -CH_COURT_X, -hz, hz],
		[-CH_COURT_X, CH_COURT_X, CH_COURT_Z1, hz], [-CH_COURT_X, CH_COURT_X, -hz, -CH_COURT_Z1]]
	for rg in ranges:
		var x0: float = rg[0]
		var x1: float = rg[1]
		var z0: float = rg[2]
		var z1: float = rg[3]
		var c := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
		lm.box("Granite", c + Vector3(0, CH_ATTIC * 0.5, 0), Vector3(x1 - x0, CH_ATTIC, z1 - z0), Basis(), 0.0)
		lm.box("Roof", c + Vector3(0, CH_ATTIC + 0.15, 0), Vector3(x1 - x0 - 1.0, 0.3, z1 - z0 - 1.0), Basis(), 0.0)
	# Light courts: four storeys of windows on their long walls.
	var span := CH_COURT_X * 2.0 - 4.0
	for sz in [-1.0, 1.0]:
		var s: float = sz
		LandmarkNaParts.windows(lm, "Windows", Vector3(0, 0, s * CH_COURT_Z0), Basis(Vector3.UP, 0.0 if s > 0.0 else PI),
			span, 2.0, CH_ATTIC - 2.0, 4, 8, Vector2(1.6, 2.6), 0.05)
		LandmarkNaParts.windows(lm, "Windows", Vector3(0, 0, s * CH_COURT_Z1), Basis(Vector3.UP, PI if s > 0.0 else 0.0),
			span, 2.0, CH_ATTIC - 2.0, 4, 8, Vector2(1.6, 2.6), 0.05)
	# Rotunda block: rises above the ranges to carry the dome.
	var core := CH_COURT_Z0
	lm.box("Granite", Vector3(0, CH_CORE_TOP * 0.5, 0), Vector3(core * 2.0, CH_CORE_TOP, core * 2.0), Basis(), 0.0)
	lm.box("Roof", Vector3(0, CH_CORE_TOP + 0.15, 0), Vector3(core * 2.0 - 1.0, 0.3, core * 2.0 - 1.0), Basis(), 0.0)
	for k in 4:
		var a := PI * 0.5 * float(k)
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3(-n.z, 0, n.x)
		var top := n * core + Vector3(0, CH_CORE_TOP, 0)
		LandmarkDetail.cornice(lm, "Trim", top - r * (core + 0.6) - Vector3(0, 1.2, 0),
			top + r * (core + 0.6) - Vector3(0, 1.2, 0), n, 1.2, false)
		LandmarkNaParts.balusters(lm, "Trim", top + n * 0.4 - r * core, top + n * 0.4 + r * core, 1.1, 0.8)
		LandmarkNaParts.windows(lm, "Windows", n * core, Basis(Vector3.UP, PI * 0.5 - a), core * 2.0 - 6.0,
			CH_ATTIC + 0.2, CH_CORE_TOP - 1.6, 1, 7, Vector2(1.6, 1.4), 0.05)

## A granite front of `cols` bays, `w` wide, laid over the mass face at
## `o` (bottom-left seen from outside, `r` to the right, `n` out): the
## rusticated ground storey, the two storeys of the order and the attic,
## each in real window openings; rustication joints, the string course
## over the ground storey and the coping at `top`.
static func _ch_bays(lm: LandmarkMesh, o: Vector3, r: Vector3, n: Vector3, w: float, cols: int,
		top: float = CH_ATTIC) -> void:
	LandmarkDetail.pierced_face(lm, "Granite", "Windows", o + Vector3(0, 1.2, 0), r, n, w, CH_GROUND - 1.2,
		cols, 1, Vector2(1.9, 3.4), 1.8, 9.0, CH_SKIN)
	LandmarkDetail.pierced_face(lm, "Granite", "Windows", o + Vector3(0, CH_GROUND, 0), r, n, w,
		CH_CORNICE - CH_GROUND, cols, 2, Vector2(2.0, 3.8), 1.6, 6.4, CH_SKIN)
	LandmarkDetail.pierced_face(lm, "Granite", "Windows", o + Vector3(0, CH_CORNICE, 0), r, n, w,
		top - CH_CORNICE, cols, 1, Vector2(1.5, 1.3), 0.9, 3.0, CH_SKIN)
	var basis := Basis(r, Vector3.UP, n)
	var mid := o + r * w * 0.5 + n * CH_SKIN
	for k in 4:
		lm.box("Granite", mid + n * 0.03 + Vector3(0, 2.6 + 1.6 * float(k), 0), Vector3(w, 0.1, 0.08), basis, 0.0)
	lm.box("Trim", mid + n * 0.25 + Vector3(0, CH_GROUND, 0), Vector3(w + 0.2, 0.6, 0.5), basis, 0.0)
	lm.box("Trim", mid + n * 0.3 - n * CH_SKIN * 0.5 + Vector3(0, top + 0.25, 0), Vector3(w + 0.4, 0.5, 0.6 + CH_SKIN),
		basis, 0.0)

## Shallow entablature and cornice over a pilastered front of width `w`
## (origin `o`, `r`, `n` as _ch_bays), proud of the skin by `out`.
static func _ch_entablature(lm: LandmarkMesh, o: Vector3, r: Vector3, n: Vector3, w: float, out: float) -> void:
	var y0 := CH_ORDER
	var y1 := CH_CORNICE - 0.6
	var face := o + n * (CH_SKIN + out)
	lm.box("Trim", face - n * out * 0.5 + r * w * 0.5 + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(w, y1 - y0, out),
		Basis(r, Vector3.UP, n), 0.0)
	LandmarkDetail.cornice(lm, "Trim", face + Vector3(0, y1, 0) - r * 0.2, face + r * (w + 0.2) + Vector3(0, y1, 0),
		n, 1.0, false)

## The Polk Street (+X, s = 1) or Van Ness (-X) front between the corner
## pavilions: two wings of eight bays, each a giant Doric colonnade on
## its balcony carrying the entablature, and the central portico.
static func _ch_front(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(s, 0, 0)
	var r := Vector3(0, 0, -s)
	var face := s * (CH_HX - CH_SKIN)
	var wing_w := CH_HZ - CH_PAV - CH_PW
	var cols := 8
	var pitch := wing_w / float(cols)
	var depth := 2.6
	for side in [-1.0, 1.0]:
		var sd: float = side
		var z_lo: float = CH_PW if sd > 0.0 else -(CH_HZ - CH_PAV)
		var z_hi: float = z_lo + wing_w
		_ch_bays(lm, Vector3(face, 0, z_hi if s > 0.0 else z_lo), r, n, wing_w, cols)
		var zc := (z_lo + z_hi) * 0.5
		var ex := s * (CH_HX + depth * 0.5)
		lm.box("Trim", Vector3(ex, CH_GROUND - 0.4, zc), Vector3(depth, 0.8, wing_w), Basis(), 0.0)
		for i in range(1, cols):
			LandmarkNaParts.column_lite(lm, "Trim", Vector3(s * (CH_HX + 1.45), CH_GROUND, z_lo + pitch * float(i)),
				0.72, CH_ORDER - CH_GROUND, 0.0, 12)
		var y1 := CH_CORNICE - 0.6
		lm.box("Trim", Vector3(ex, (CH_ORDER + y1) * 0.5, zc), Vector3(depth, y1 - CH_ORDER, wing_w), Basis(), 0.0)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * (CH_HX + depth), y1, z_lo), Vector3(s * (CH_HX + depth), y1, z_hi),
			n, 1.0, false)
	_ch_portico(lm, s)

## Central portico: a base storey with three arched doors over the
## entrance steps, six Doric columns before a windowed pavilion wall,
## the entablature with its dentil cornice, and the pediment.
static func _ch_portico(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(s, 0, 0)
	var front := CH_HX + 5.5
	var half := CH_PW
	# Base storey and the steps up to its doors.
	lm.box("Granite", Vector3(s * (CH_HX - 0.4 + front) * 0.5, CH_GROUND * 0.5, 0),
		Vector3(front - CH_HX + 0.4, CH_GROUND, half * 2.0), Basis(), 0.0)
	for k in 3:
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * front, 4.5, (float(k) - 1.0) * 6.5), n, 3.4, 6.6,
			true, 0.3)
	for k in 4:
		var top := 1.2 - 0.3 * float(k)
		lm.box("Trim", Vector3(s * (front + 0.45 * (float(k) + 0.5)), top * 0.5, 0), Vector3(0.45, top, 24.0),
			Basis(), 0.0)
	lm.box("Trim", Vector3(s * (CH_HX + front + 0.3) * 0.5, CH_GROUND - 0.3, 0),
		Vector3(front - CH_HX + 0.3, 0.6, half * 2.0 + 0.4), Basis(), 0.0)
	# Pavilion wall with two storeys of windows between the columns.
	var wall := CH_HX + 1.0
	lm.box("Granite", Vector3(s * (CH_HX - 0.4 + wall) * 0.5, (CH_GROUND + 27.0) * 0.5, 0),
		Vector3(wall - CH_HX + 0.4, 27.0 - CH_GROUND, half * 2.0), Basis(), 0.0)
	for k in 5:
		var z := (float(k) - 2.0) * 5.0
		for y in [13.0, 19.4]:
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * wall, float(y), z), n, 2.2, 3.8, false, 0.25)
	for k in 6:
		LandmarkNaParts.column_lite(lm, "Trim", Vector3(s * (CH_HX + 4.0), CH_GROUND, -12.5 + 5.0 * float(k)),
			0.9, 15.0, 0.0, 14)
	# Entablature, cornice and pediment.
	var ey := 24.0
	var et := 26.8
	lm.box("Trim", Vector3(s * (CH_HX + front + 0.2) * 0.5, (ey + et) * 0.5, 0),
		Vector3(front - CH_HX + 0.2, et - ey, half * 2.0 + 0.6), Basis(), 0.0)
	LandmarkDetail.cornice(lm, "Trim", Vector3(s * (front + 0.1), et, -half - 0.6), Vector3(s * (front + 0.1), et, half + 0.6),
		n, 1.2, true)
	var rise := 5.6
	var py := et + 1.2
	lm.gable("Trim", Vector3(s * (CH_HX + front) * 0.5, py, 0), half * 2.0 + 0.6, front - CH_HX + 0.6, rise,
		Basis(Vector3.UP, PI * 0.5), 0.6, "Granite")
	for sd in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(s * (front + 0.5), py, float(sd) * (half + 0.9)), Vector3(s * (front + 0.5), py + rise, 0),
			0.8, 0.9, Vector3.UP)
	# Sculpture group in the tympanum: low relief blocks.
	for k in 5:
		var z := (float(k) - 2.0) * 3.6
		var fh := rise * 0.7 * (1.0 - absf(float(k) - 2.0) / 3.2)
		lm.box("Trim", Vector3(s * (front + 0.15), py + fh * 0.5 + 0.2, z), Vector3(0.5, fh, 2.2), Basis(), 0.0)

## The McAllister (-Z, s = -1) or Grove Street (+Z) front between the
## corner pavilions: fourteen bays between giant Doric pilasters under
## the entablature.
static func _ch_side(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(0, 0, s)
	var r := Vector3(s, 0, 0)
	var w := (CH_HX - CH_PAV) * 2.0
	var cols := 14
	var o := Vector3(-s * (CH_HX - CH_PAV), 0, s * (CH_HZ - CH_SKIN))
	_ch_bays(lm, o, r, n, w, cols)
	var pitch := w / float(cols)
	var basis := Basis(r, Vector3.UP, n)
	for i in range(1, cols):
		var p := o + r * pitch * float(i) + n * (CH_SKIN + 0.25)
		lm.box("Trim", p + Vector3(0, (CH_GROUND + CH_ORDER) * 0.5, 0), Vector3(1.0, CH_ORDER - CH_GROUND, 0.5), basis, 0.0)
		lm.box("Trim", p + n * 0.1 + Vector3(0, CH_ORDER - 0.4, 0), Vector3(1.4, 0.8, 0.7), basis, 0.0)
	_ch_entablature(lm, o, r, n, w, 0.8)

## A corner pavilion (sx, sz the signs of its corner), 1.2 m proud of
## both fronts and a metre above the attic: three bays each way framed
## by giant pilasters under the entablature.
static func _ch_pavilion(lm: LandmarkMesh, sx: float, sz: float) -> void:
	var top := CH_ATTIC + 1.0
	var x0 := CH_HX - CH_PAV
	var x1 := CH_HX + CH_PAV_OUT
	var z0 := CH_HZ - CH_PAV
	var z1 := CH_HZ + CH_PAV_OUT
	var c := Vector3(sx * (x0 + x1 - CH_SKIN) * 0.5, top * 0.5, sz * (z0 + z1 - CH_SKIN) * 0.5)
	lm.box("Granite", c, Vector3(x1 - x0 - CH_SKIN, top, z1 - z0 - CH_SKIN), Basis(), 0.0)
	lm.box("Roof", Vector3(c.x, top + 0.15, c.z), Vector3(x1 - x0 - 1.4, 0.3, z1 - z0 - 1.4), Basis(), 0.0)
	var w := CH_PAV + CH_PAV_OUT
	var zlo := minf(sz * z0, sz * z1)
	var zhi := maxf(sz * z0, sz * z1)
	var xlo := minf(sx * x0, sx * x1)
	var xhi := maxf(sx * x0, sx * x1)
	var faces := [[Vector3(sx * (x1 - CH_SKIN), 0, zhi if sx > 0.0 else zlo), Vector3(0, 0, -sx), Vector3(sx, 0, 0)],
		[Vector3(xlo if sz > 0.0 else xhi, 0, sz * (z1 - CH_SKIN)), Vector3(sz, 0, 0), Vector3(0, 0, sz)]]
	for f in faces:
		var o: Vector3 = f[0]
		var r: Vector3 = f[1]
		var n: Vector3 = f[2]
		_ch_bays(lm, o, r, n, w, 3, top)
		var basis := Basis(r, Vector3.UP, n)
		for e in [0.7, w - 0.7]:
			var p: Vector3 = o + r * float(e) + n * (CH_SKIN + 0.3)
			lm.box("Trim", p + Vector3(0, (CH_GROUND + CH_ORDER) * 0.5, 0), Vector3(1.3, CH_ORDER - CH_GROUND, 0.6),
				basis, 0.0)
		_ch_entablature(lm, o, r, n, w, 0.9)

## The rotunda's dome on the raised block at `b`: the podium ring and
## its balustrade, the drum of sixteen paired Doric columns before piers
## and pedimented windows, the entablature, the attic of pinnacles and
## oculi, the ribbed shell with gilded ribs and cartouches, and the
## lantern with its gilded rail, finials and spire.
static func _ch_dome(lm: LandmarkMesh, b: Vector3) -> void:
	var seg := 48
	lm.frustum("Granite", b, 21.6, 21.6, 3.6, seg)
	lm.lathe("Trim", b + Vector3(0, 3.6, 0), PackedVector2Array([Vector2(21.6, 0.0), Vector2(22.1, 0.3),
		Vector2(22.1, 0.7), Vector2(17.8, 0.7)]), seg)
	var cy := b + Vector3(0, 4.3, 0)
	LandmarkNaParts.ring(lm, "Trim", cy, 21.5, 0.4, 0.15, seg)
	LandmarkNaParts.ring_posts(lm, "Trim", cy, 21.5, 1.0, 96, 0.16, 0.16)
	LandmarkNaParts.ring(lm, "Trim", cy + Vector3(0, 1.0, 0), 21.5, 0.45, 0.15, seg)
	var col_h := 12.6
	lm.frustum("Granite", cy, 17.8, 17.8, col_h, seg)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var t := Vector3(-d.z, 0, d.x)
		for side in [-1.0, 1.0]:
			LandmarkNaParts.column_lite(lm, "Trim", cy + d * 19.9 + t * 1.15 * float(side), 0.6, col_h, 0.0, 10)
		lm.box("Granite", cy + d * 18.7 + Vector3(0, col_h * 0.5, 0), Vector3(3.4, col_h, 1.8), Basis.looking_at(d), 0.0)
		var wa := a + TAU / 32.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		var wr := Vector3.UP.cross(wd).normalized()
		LandmarkDetail.window(lm, "Trim", "Windows", cy + wd * 17.8 + Vector3(0, 5.6, 0), wd, 2.4, 6.0, false, 0.25)
		lm.gable("Trim", cy + wd * 18.0 + Vector3(0, 9.4, 0), 3.2, 0.5, 0.9, Basis(wr, Vector3.UP, wd), 0.1, "Trim")
	# Entablature and its cornice.
	var ey := cy + Vector3(0, col_h, 0)
	lm.frustum("Trim", ey, 21.0, 21.0, 1.6, seg)
	lm.lathe("Trim", ey + Vector3(0, 1.6, 0), PackedVector2Array([Vector2(21.0, 0.0), Vector2(21.5, 0.4),
		Vector2(21.6, 0.8), Vector2(18.6, 0.8)]), seg)
	# Attic: oculi between pinnacles over each column pair.
	var at := ey + Vector3(0, 2.4, 0)
	lm.frustum("Granite", at, 18.8, 18.6, 4.6, seg)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := at + d * 20.0
		lm.box("Trim", p + Vector3(0, 0.8, 0), Vector3(1.4, 1.6, 1.4), Basis.looking_at(d), 0.0)
		lm.lathe("Trim", p + Vector3(0, 1.6, 0), PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.65, 0.5),
			Vector2(0.3, 1.4), Vector2(0.18, 2.6), Vector2(0.0, 3.2)]), 8)
		lm.beam("Trim", p + Vector3(0, 0.3, 0), at + d * 18.7 + Vector3(0, 3.8, 0), 0.6, 0.5)
		var oa := a + TAU / 32.0
		var od := Vector3(cos(oa), 0, sin(oa))
		lm.disc("Windows", at + od * 18.78 + Vector3(0, 2.3, 0), od, 0.8, 12)
	lm.lathe("Trim", at + Vector3(0, 4.6, 0), PackedVector2Array([Vector2(18.6, 0.0), Vector2(19.2, 0.4),
		Vector2(19.2, 0.8), Vector2(17.6, 0.8)]), seg)
	# Shell, gilded ribs and cartouches.
	var sh := at + Vector3(0, 5.4, 0)
	var sr := 17.4
	var shh := 14.6
	lm.lathe("Dome", sh, LandmarkKits._dome_profile(sr, shh, 16), 64)
	var prof := LandmarkKits._dome_profile(sr + 0.12, shh + 0.12, 12)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Gold", sh + d * prof[j].x + Vector3(0, prof[j].y, 0),
				sh + d * prof[j + 1].x + Vector3(0, prof[j + 1].y, 0), 0.42, 0.25, d.cross(Vector3.UP))
		var cd := Vector3(cos(a + TAU / 32.0), 0, sin(a + TAU / 32.0))
		var ang := 0.75
		var nn := (cd * cos(ang) / sr + Vector3.UP * sin(ang) / shh).normalized()
		var right := Vector3.UP.cross(cd).normalized()
		lm.box("Gold", sh + cd * sr * cos(ang) + Vector3(0, shh * sin(ang), 0) + nn * 0.1, Vector3(1.6, 1.9, 0.35),
			Basis(right, nn.cross(right).normalized(), nn).orthonormalized(), 0.0)
	_ch_lantern(lm, sh + Vector3(0, shh, 0))

## Lantern on the dome's crown `lt`: the base ring and gilded balcony
## rail, the drum of eight columns round arched lights with gilded urn
## finials, the cupola and the slim spire with its gilded ball and spike.
static func _ch_lantern(lm: LandmarkMesh, lt: Vector3) -> void:
	lm.frustum("Trim", lt - Vector3(0, 0.6, 0), 5.2, 5.0, 1.2, 24)
	var lb := lt + Vector3(0, 0.6, 0)
	LandmarkNaParts.ring_rail(lm, "Gold", lb, 4.8, 1.0, 1.2)
	lm.frustum("Trim", lb, 2.9, 2.9, 5.6, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkNaParts.column_lite(lm, "Trim", lb + d * 3.6, 0.26, 5.6, 1.0, 8)
		lm.lathe("Gold", lb + d * 3.7 + Vector3(0, 6.6, 0), PackedVector2Array([Vector2(0.22, 0.0), Vector2(0.38, 0.4),
			Vector2(0.18, 0.9), Vector2(0.0, 1.4)]), 8)
		var wd := Vector3(cos(TAU * float(k) / 8.0), 0, sin(TAU * float(k) / 8.0))
		lm.box("Windows", lb + wd * 2.92 + Vector3(0, 2.8, 0), Vector3(1.3, 3.6, 0.1), Basis.looking_at(wd), 0.0)
	lm.lathe("Trim", lb + Vector3(0, 5.6, 0), PackedVector2Array([Vector2(4.0, 0.0), Vector2(4.2, 0.5),
		Vector2(4.2, 1.0), Vector2(3.0, 1.0)]), 24)
	var cup := lb + Vector3(0, 6.6, 0)
	lm.lathe("Dome", cup, LandmarkKits._dome_profile(3.0, 2.6, 8), 24)
	var sp := cup + Vector3(0, 2.2, 0)
	lm.lathe("Dome", sp, PackedVector2Array([Vector2(1.3, 0.0), Vector2(1.0, 1.0), Vector2(0.75, 4.0),
		Vector2(0.45, 8.0), Vector2(0.25, 11.2)]), 12)
	lm.frustum("Gold", sp + Vector3(0, 0.9, 0), 1.12, 1.06, 0.5, 12)
	lm.frustum("Gold", sp + Vector3(0, 5.8, 0), 0.68, 0.64, 0.4, 12)
	var fin := sp + Vector3(0, 11.2, 0)
	lm.lathe("Gold", fin, PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.6, 0.5), Vector2(0.62, 0.9),
		Vector2(0.4, 1.4), Vector2(0.12, 1.6), Vector2(0.1, 2.2), Vector2(0.0, CH_TOP_M - fin.y)]), 10)
