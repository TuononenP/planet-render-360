class_name LandmarkNaCapitol
extends RefCounted

## The United States Capitol in true metres, east front facing +X.

const TOP_M := 88.0
const ROOF_M := 28.0

## US Capitol: the 229 m north-south front of the central block (1793-
## 1826), the Senate (north, -Z) and House (south, +Z) wings of 1851-68
## joined by links, each storey of windows set in real openings
## between Corinthian pilasters over a rusticated ground floor, the
## roof balustrade, the three pedimented east porticos of unfluted
## Corinthian columns over their flights of steps, the west front
## loggias over the Olmsted terrace, and the 1855-66 cast-iron dome: the
## stepped base, the 36-column peristyle with its balustrade, the
## windowed attic, the ribbed shell with its two tiers of lights, the
## 12-column tholos and the bronze Statue of Freedom, to 88 m.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E9E6DE", 3.0))
	lm.use("Dome", LandmarkMaterials.paint("#F2F1ED", 0.5, 0.1))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7E8884", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bronze", LandmarkMaterials.paint("#5C4B34", 0.5, 0.5))
	lm.use("Terrace", LandmarkMaterials.pbr("stone", "#B5AE9F", 4.0))
	# West terrace (Olmsted, 1890s) and the plinth of the whole front.
	lm.box("Terrace", Vector3(-46.0, 3.0, 0), Vector3(30.0, 6.0, 150.0))
	lm.box("Marble", Vector3(0, 0.7, 0), Vector3(118.0, 1.4, 236.0))
	# [z centre, z length, x depth, height]: Senate, link, centre, link, House.
	var blocks := [[-78.0, 70.0, 50.0, 23.0], [-37.0, 12.0, 36.0, 19.0], [0.0, 62.0, 56.0, ROOF_M],
		[37.0, 12.0, 36.0, 19.0], [78.0, 70.0, 50.0, 23.0]]
	for b in blocks:
		_block(lm, float(b[0]), float(b[1]), float(b[2]), float(b[3]), absf(float(b[0])) > 50.0)
	# East porticos: the central one (eight columns two deep, pediment)
	# and one on each wing (eight columns, pediment).
	_portico(lm, 0.0, 34.0, 28.0, 8, 13.2, 5.0, true)
	for s in [-1.0, 1.0]:
		_portico(lm, s * 78.0, 25.0, 25.0, 8, 11.6, 3.4, false)
		# West front of each wing: a loggia of ten columns on its balcony.
		lm.box("Marble", Vector3(-26.4, 5.8, s * 78.0), Vector3(2.8, 0.8, 40.0))
		lm.box("Marble", Vector3(-26.2, 17.5, s * 78.0), Vector3(2.4, 1.4, 40.0))
		for i in 10:
			LandmarkNaParts.column_lite(lm, "Marble", Vector3(-26.2, 6.2, s * 78.0 - 18.0 + 4.0 * i), 0.55, 10.6)
	# West central loggia over the terrace.
	for i in 10:
		LandmarkNaParts.column_lite(lm, "Marble", Vector3(-29.6, 7.4, -18.0 + 4.0 * i), 0.6, 11.0)
	lm.box("Marble", Vector3(-29.6, 19.2, 0), Vector3(2.4, 1.6, 40.0))
	lm.box("Marble", Vector3(-30.0, 6.7, 0), Vector3(4.0, 1.4, 42.0))
	_dome(lm, Vector3(0, ROOF_M, 0))
	lm.commit(model)

## One block of the front: mass, real window openings on every face in
## three bands (rusticated ground floor, principal storey between
## pilasters, attic), the moulded cornice, a light balustrade and a low
## hipped roof behind it. `end_faces` adds the north/south faces.
static func _block(lm: LandmarkMesh, z: float, zl: float, xd: float, h: float, end_faces: bool) -> void:
	var skin := 0.35
	lm.box("Marble", Vector3(0, 1.4 + (h - 1.4) * 0.5, z), Vector3(xd - skin * 2.0, h - 1.4, zl - skin * 2.0))
	var faces := [[Vector3(xd * 0.5 - skin, 0, z + zl * 0.5), Vector3(0, 0, -1), Vector3(1, 0, 0), zl],
		[Vector3(-xd * 0.5 + skin, 0, z - zl * 0.5), Vector3(0, 0, 1), Vector3(-1, 0, 0), zl]]
	if end_faces:
		var sz := signf(z)
		faces.append([Vector3(sz * xd * 0.5, 0, z + sz * (zl * 0.5 - skin)), Vector3(-sz, 0, 0),
			Vector3(0, 0, sz), xd])
	for f in faces:
		var o: Vector3 = f[0]
		var r: Vector3 = f[1]
		var n: Vector3 = f[2]
		var w: float = f[3]
		var cols := maxi(2, floori(w / 4.6))
		var top_h := h - 1.4
		var att := 3.8
		var gnd := 5.2
		var main_h := top_h - gnd - att
		var y0 := Vector3(0, 1.4, 0)
		LandmarkDetail.pierced_face(lm, "Marble", "Windows", o + y0, r, n, w, gnd, cols, 1,
			Vector2(1.5, 2.4), 1.4, 5.0, skin)
		var storey := main_h * 0.5
		LandmarkDetail.pierced_face(lm, "Marble", "Windows", o + y0 + Vector3(0, gnd, 0), r, n, w, main_h, cols, 2,
			Vector2(1.8, minf(4.0, storey - 2.0)), 1.4, storey, skin)
		LandmarkDetail.pierced_face(lm, "Marble", "Windows", o + y0 + Vector3(0, gnd + main_h, 0), r, n, w, att,
			cols, 1, Vector2(1.4, 1.5), 1.2, 4.0, skin)
		# Rustication joints on the ground floor, a string course, and
		# pilasters between the principal-storey bays.
		var pitch := w / float(cols)
		var basis := Basis(r, Vector3.UP, n)
		for k in 3:
			lm.box("Marble", o + y0 + r * w * 0.5 + n * (skin + 0.02) + Vector3(0, 1.0 + 1.4 * k, 0),
				Vector3(w, 0.08, 0.06), basis, 0.0)
		lm.box("Marble", o + y0 + r * w * 0.5 + n * (skin + 0.2) + Vector3(0, gnd, 0), Vector3(w, 0.5, 0.4), basis)
		for i in cols + 1:
			var pc := o + y0 + r * pitch * float(i) + n * (skin + 0.2) + Vector3(0, gnd + main_h * 0.5, 0)
			lm.box("Marble", pc, Vector3(0.8, main_h - 0.6, 0.4), basis, 0.0)
			lm.box("Marble", pc + Vector3(0, main_h * 0.5 - 0.2, 0) + n * 0.1, Vector3(1.1, 0.7, 0.55), basis, 0.0)
		LandmarkDetail.cornice(lm, "Marble", o + Vector3(0, h, 0) - r * 0.5 + n * skin,
			o + Vector3(0, h, 0) + r * (w + 0.5) + n * skin, n, 1.2, z == 0.0)
		LandmarkNaParts.balusters(lm, "Marble", o + Vector3(0, h + 1.2, 0) + n * (skin + 0.4),
			o + Vector3(0, h + 1.2, 0) + r * w + n * (skin + 0.4), 1.1, 0.6)
	if h > 20.0 and z != 0.0:
		LandmarkNaParts.hip(lm, "Roof", Vector3(0, h + 1.2, z), Basis(), xd * 0.5 - 1.0, zl * 0.5 - 1.0, 0.5, 3.0)
	else:
		lm.box("Roof", Vector3(0, h + 1.4, z), Vector3(xd - 1.0, 0.4, zl - 1.0))

## A pedimented east portico centred on z, `w` wide, its columns
## (`n` across, `ch` tall) standing `px` out from the facade line; the
## central one is two rows deep over a broad flight of steps.
static func _portico(lm: LandmarkMesh, z: float, w: float, px: float, n: int, ch: float, rise: float,
		central: bool) -> void:
	var stylo := 1.4 if not central else 6.0
	var depth := 10.0 if not central else 12.0
	var fx := px + depth
	lm.box("Marble", Vector3(px + depth * 0.5, stylo * 0.5, z), Vector3(depth, stylo, w + 2.0))
	# Steps down from the stylobate.
	var steps := int(stylo / 0.18)
	var run := 0.36
	for k in steps:
		var top := stylo - 0.18 * float(k)
		lm.box("Marble", Vector3(fx + run * (float(k) + 0.5), top * 0.5, z), Vector3(run, top, w - 6.0), Basis(), 0.0)
	var cr := ch * 0.055
	var rows := 2 if central else 1
	for row in rows:
		var x := fx - 1.6 - 4.0 * float(row)
		for i in n:
			var zz := z - w * 0.5 + 1.6 + (w - 3.2) * float(i) / float(n - 1)
			LandmarkDetail.column(lm, "Marble", Vector3(x, stylo, zz), cr, ch, "corinthian", 0)
	# Entablature, pediment with its raking cornice and a sculpture group.
	var ey := stylo + ch
	lm.box("Marble", Vector3(px + depth * 0.5, ey + 1.0, z), Vector3(depth, 2.0, w))
	LandmarkDetail.cornice(lm, "Marble", Vector3(fx, ey + 2.0, z - w * 0.5 - 0.6),
		Vector3(fx, ey + 2.0, z + w * 0.5 + 0.6), Vector3.RIGHT, 1.0, true)
	var pc := Vector3(px + depth * 0.5, ey + 3.0, z)
	lm.gable("Roof", pc, w + 1.0, depth, rise, Basis(Vector3.UP, PI * 0.5), 0.6, "Marble")
	for s in [-1.0, 1.0]:
		lm.beam("Marble", Vector3(fx + 0.4, ey + 3.0, z + s * (w * 0.5 + 0.6)),
			Vector3(fx + 0.4, ey + 3.0 + rise, z), 0.8, 0.9, Vector3.UP)
	for i in 7:
		var zz := z + (float(i) - 3.0) * w * 0.09
		var fh := rise * 0.75 * (1.0 - absf(float(i) - 3.0) / 4.0)
		if fh > 0.8:
			LandmarkKits.statue_figure(lm, "Marble", Vector3(fx + 0.5, ey + 3.0, zz), fh)

## The cast-iron dome on the central block's roof at `b`.
static func _dome(lm: LandmarkMesh, b: Vector3) -> void:
	# Stepped base (the rusticated drum foot) to the peristyle floor.
	lm.frustum("Dome", b, 22.5, 22.5, 2.5, 48)
	lm.frustum("Dome", b + Vector3(0, 2.5, 0), 21.6, 21.6, 2.5, 48)
	var pf := b + Vector3(0, 5.0, 0)
	# Peristyle: 36 Corinthian columns round the windowed drum.
	var ch := 8.6
	lm.frustum("Dome", pf, 17.6, 17.6, ch, 48)
	for k in 36:
		var a := TAU * float(k) / 36.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkNaParts.column_lite(lm, "Dome", pf + d * 20.3, 0.5, ch)
		var wa := a + TAU / 72.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		LandmarkDetail.window(lm, "Dome", "Windows", pf + wd * 17.7 + Vector3(0, 4.4, 0), wd, 1.4, 4.2, true, 0.2)
	var ey := pf + Vector3(0, ch, 0)
	lm.frustum("Dome", ey, 21.0, 21.0, 1.6, 48)
	lm.lathe("Dome", ey + Vector3(0, 1.6, 0), PackedVector2Array([Vector2(21.0, 0.0), Vector2(21.6, 0.4),
		Vector2(21.9, 0.9), Vector2(21.9, 1.2), Vector2(19.0, 1.2)]), 48)
	# Balustrade round the peristyle roof.
	var bal := ey + Vector3(0, 2.8, 0)
	LandmarkNaParts.ring(lm, "Dome", bal, 21.3, 0.5, 0.2, 48)
	LandmarkNaParts.ring_posts(lm, "Dome", bal, 21.3, 1.0, 144, 0.18, 0.18)
	LandmarkNaParts.ring(lm, "Dome", bal + Vector3(0, 1.0, 0), 21.3, 0.55, 0.2, 48)
	# Attic drum: pilasters and 36 small windows, its cornice.
	var at := ey + Vector3(0, 2.8, 0)
	lm.frustum("Dome", at, 17.2, 17.2, 7.6, 48)
	for k in 36:
		var a := TAU * float(k) / 36.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Dome", at + d * 17.35 + Vector3(0, 3.6, 0), Vector3(0.9, 7.2, 0.4), Basis.looking_at(d))
		var wa := a + TAU / 72.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		LandmarkDetail.window(lm, "Dome", "Windows", at + wd * 17.25 + Vector3(0, 3.8, 0), wd, 1.2, 2.2, false, 0.15)
	lm.lathe("Dome", at + Vector3(0, 7.6, 0), PackedVector2Array([Vector2(17.2, 0.0), Vector2(17.7, 0.5),
		Vector2(18.0, 1.0), Vector2(16.6, 1.1)]), 48)
	# Shell: 36 ribs and two tiers of small lights between them.
	var sh := at + Vector3(0, 8.6, 0)
	var sr := 16.6
	var shh := 19.4
	lm.lathe("Dome", sh, LandmarkKits._dome_profile(sr, shh, 16), 72)
	var prof := LandmarkKits._dome_profile(sr + 0.25, shh + 0.2, 16)
	for i in 36:
		var a := TAU * float(i) / 36.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 13:
			lm.beam("Dome", sh + d * prof[j].x + Vector3(0, prof[j].y, 0),
				sh + d * prof[j + 1].x + Vector3(0, prof[j + 1].y, 0), 0.5, 0.35, d.cross(Vector3.UP))
		var wa := a + TAU / 72.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		for tier in [0.16, 0.45]:
			var ang := PI * 0.5 * float(tier)
			var p := sh + wd * sr * cos(ang) + Vector3(0, shh * sin(ang), 0)
			var nn := (wd * cos(ang) / sr + Vector3.UP * sin(ang) / shh).normalized()
			lm.box("Dome", p, Vector3(1.4, 2.0, 0.3), Basis(wd.cross(Vector3.UP).normalized() * -1.0,
				nn.cross(wd.cross(Vector3.UP) * -1.0).normalized(), nn).orthonormalized())
			lm.box("Windows", p + nn * 0.12, Vector3(0.9, 1.4, 0.2), Basis(wd.cross(Vector3.UP).normalized() * -1.0,
				nn.cross(wd.cross(Vector3.UP) * -1.0).normalized(), nn).orthonormalized(), 0.0)
	# Tholos: 12 columns round the lantern, its cupola and balcony.
	var th := sh + Vector3(0, shh - 0.6, 0)
	lm.frustum("Dome", th, 5.4, 5.2, 0.8, 32)
	LandmarkNaParts.ring_rail(lm, "Dome", th + Vector3(0, 0.8, 0), 5.0, 1.0, 0.8)
	lm.frustum("Dome", th + Vector3(0, 0.8, 0), 3.0, 3.0, 5.0, 24)
	for k in 12:
		var a := TAU * float(k) / 12.0
		LandmarkNaParts.column_lite(lm, "Dome", th + Vector3(0, 0.8, 0) + Vector3(cos(a), 0, sin(a)) * 4.0, 0.24, 4.6)
	lm.frustum("Dome", th + Vector3(0, 5.4, 0), 4.6, 4.6, 0.8, 32)
	lm.lathe("Dome", th + Vector3(0, 6.2, 0), LandmarkKits._dome_profile(4.2, 2.4, 8), 32)
	# Statue of Freedom (5.9 m) on her globe and pedestal.
	var sb := th + Vector3(0, 8.4, 0)
	lm.frustum("Bronze", sb, 1.0, 0.8, 0.8, 12)
	lm.lathe("Bronze", sb + Vector3(0, 0.8, 0), LandmarkKits._dome_profile(0.9, 0.9, 6), 12)
	var fb := sb + Vector3(0, 1.6, 0)
	LandmarkKits.statue_figure(lm, "Bronze", fb, TOP_M - fb.y - 0.8)
	# Helmet crest of eagle feathers.
	lm.lathe("Bronze", fb + Vector3(0, TOP_M - fb.y - 1.1, 0), PackedVector2Array([Vector2(0.25, 0.0),
		Vector2(0.3, 0.4), Vector2(0.12, 0.9), Vector2(0.0, 1.1)]), 8, 0.6, 1.0)
