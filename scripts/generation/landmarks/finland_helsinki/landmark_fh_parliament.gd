class_name LandmarkFhParliament
extends RefCounted

## Sirén's Eduskuntatalo (1931), origin at the OSM footprint centre, front
## +Z. The registry yaw (73) turns the front west onto Mannerheimintie, so
## model -X is north and +X south. The 77.8 x 56 m block is honed pinkish-grey
## Kalvola granite in large ashlar courses.
##
## From the front:
## - The stair, split by one landing, rises about 7.6 m to the colonnade.
##   The lower flight runs wider beside the low wings.
## - Fourteen smooth monolithic columns stand between two blank end
##   pylons. Their capitals are Gunnar Finne's stylised Corinthian: a
##   necking ring, a slightly flared bell with side volutes, and a
##   concave-sided abacus.
## - The darker recessed wall behind them has 15 bays of three windows
##   each: an arched window or door with a lion-head boss over it, a very
##   tall window, then a short one.
## - Above run the architrave, the frieze of 17 roundels (15 glazed, a
##   blind one over each pylon) with tablets between, the cornice, and the
##   plain coursed attic up to the parapet.
##
## The flanks and back are plain coursed walls with punched dark-framed
## windows in six rows, small squares under the cornice, and a tall framed
## stair window near each end of the flanks. The one-storey wings by the
## stair have tall arched windows and a rosette frieze. Each wing has a
## framed public-gallery door that widens toward the foot, beside the stair.
##
## In front stand two white flagpoles and Aaltonen's bronze statues on red
## granite pedestals: Ståhlberg to the north (-X), Svinhufvud to the south
## (+X).
##
## The roof is flat behind the parapet, with rows of small skylights. The
## circular Session Hall (Ø 25 m) shows as a low ribbed saucer dome carrying
## a windowed lantern drum and a faceted cone, with two small round drums
## beside it. Four narrow light courts flank it.
##
## Sources: en/fi Wikipedia (six storeys, Session Hall Ø 25 m, four inner
## courts, Finne's capitals and lion heads, the gallery doors, the statues).
## Heights and the facade rhythm are measured from Commons photos in
## visual-plan/refs/landmarks/parliament_house_helsinki/, using a
## straight-on front view scaled by the footprint width. The published 25 m
## is the height above the colonnade terrace; the podium adds 7.6 m from
## Mannerheimintie, giving 34.9 m to the parapet. Court sizes and the flank
## window count are approximate.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const X0 := -35.0
const X1 := 42.8
const CX := (X0 + X1) * 0.5
## Back wall, the wall behind the colonnade, the front of the pylons.
const ZB := -26.8
const ZW := 24.7
const ZF := 29.3
## Colonnade terrace, the roof deck behind the parapet, the parapet top.
const TERR := 7.6
const RIM := 33.7
const TOP := 34.9
## Column top, frieze band, the main cornice under the attic.
const COL_H := 17.9
const FRIEZE0 := TERR + 19.6
const CORNICE := TERR + 22.7
## Floor of the light courts.
const COURT_Y := 12.0
## Plan of the wings round the hall above COURT_Y: the core band between
## the front and back ranges, the court columns left and right of the
## hall, and the cross wing splitting each pair of courts.
const ZC0 := -13.8
const ZC1 := 11.7
const ZM0 := -2.4
const ZM1 := 0.4
const CL0 := -22.0
const CL1 := -13.0
const CR0 := 20.8
const CR1 := 29.8
const HALL := Vector3(3.9, 0.0, -1.05)
const HALL_R := 12.5
## Colonnade: 14 columns in 15 bays between the end pylons.
const PX0 := X0 + 12.0
const PX1 := X1 - 12.0
## Stair: upper flight, landing, lower flight.
const UPPER := 30
const LOWER := 14
const LANDING_Y := 2.4
const LANDING_D := 3.0
const TREAD := 0.42

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	# Granite in large ashlar courses (the limestone set is coursed by
	# LandmarkShader), the lighter, greyer honed columns (their drum joints
	# read as courses), the darker wall in the colonnade's shade, the
	# weathered grey steps.
	lm.use("Granite", LandmarkMaterials.pbr("limestone", "#AD978E", 3.2))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#B8A49B", 2.4))
	lm.use("Recess", LandmarkMaterials.pbr("limestone", "#8E7D76", 3.2))
	lm.use("Column", LandmarkMaterials.pbr("limestone", "#BCB0A8", 2.0, 0.55))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#9A928D", 3.0))
	lm.use("Pedestal", LandmarkMaterials.pbr("stone", "#7B5550", 2.0, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bronze", LandmarkMaterials.paint("#2E2B28", 0.45, 0.6))
	lm.use("Pole", LandmarkMaterials.paint("#EDEDED", 0.5, 0.3))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#555652", 3.0, 0.55, 0.35))
	lm.use("Seam", LandmarkMaterials.pbr("sheet_metal", "#6A6C68", 3.0, 0.45, 0.45))
	_mass(lm)
	_front(lm)
	_stair(lm)
	_flanks(lm)
	_wings(lm)
	_grounds(lm)
	_roof(lm)
	_courts(lm)
	_hall(lm)
	lm.commit(model)

# --- Massing -----------------------------------------------------------

## Plinth, the solid block up to the court floor, the ranges and cross
## wings round the courts and hall up to the deck, the end pylons, the
## parapet, the main cornice and the coping.
static func _mass(lm: LandmarkMesh) -> void:
	var w := X1 - X0
	var d := ZF - ZB
	var cz := (ZB + ZF) * 0.5
	FhU.blk(lm, "Step", CX, 0.0, (ZB + ZW) * 0.5, w + 0.8, 1.2, ZW - ZB + 0.8)
	FhU.blk(lm, "Granite", CX, 0.0, (ZB + ZW) * 0.5, w, COURT_Y, ZW - ZB)
	var h := RIM - COURT_Y
	for r in [[X0, X1, ZB, ZC0], [X0, X1, ZC1, ZW], [X0, CL0, ZC0, ZC1], [CL1, CR0, ZC0, ZC1],
			[CR1, X1, ZC0, ZC1], [CL0, CL1, ZM0, ZM1], [CR0, CR1, ZM0, ZM1]]:
		var a: float = r[0]
		var b: float = r[1]
		var c: float = r[2]
		var e: float = r[3]
		FhU.blk(lm, "Granite", (a + b) * 0.5, COURT_Y, (c + e) * 0.5, b - a, h, e - c)
	for pv in [[X0, PX0], [PX1, X1]]:
		var a: float = pv[0]
		var b: float = pv[1]
		FhU.blk(lm, "Granite", (a + b) * 0.5, 0.0, (ZW + ZF) * 0.5, b - a, RIM, ZF - ZW)
		# Carved fret panels level with the capitals and at the landing.
		for y: float in [TERR + COL_H - 1.6, TERR + 0.2]:
			FhU.blk(lm, "Trim", (a + b) * 0.5, y, ZF + 0.05, b - a - 2.4, 1.3, 0.12)
			var n := int((b - a - 3.0) / 0.9)
			for k in n:
				var x := a + 1.5 + (float(k) + 0.5) * (b - a - 3.0) / float(n)
				lm.box("Trim", Vector3(x, y + 0.65, ZF + 0.17), Vector3(0.5, 0.5 if k % 2 == 0 else 0.9, 0.12))
	# Parapet ring from the deck to the top.
	var pt := 0.8
	FhU.blk(lm, "Granite", CX, RIM, ZF - pt * 0.5, w, TOP - RIM, pt)
	FhU.blk(lm, "Granite", CX, RIM, ZB + pt * 0.5, w, TOP - RIM, pt)
	FhU.blk(lm, "Granite", X0 + pt * 0.5, RIM, cz, pt, TOP - RIM, d - pt * 2.0)
	FhU.blk(lm, "Granite", X1 - pt * 0.5, RIM, cz, pt, TOP - RIM, d - pt * 2.0)
	# The main cornice under the attic and the plain coping.
	for face in FhP.faces(CX, cz, w, d):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		LandmarkDetail.cornice(lm, "Trim", fa + Vector3(0, CORNICE - 0.7, 0), fb + Vector3(0, CORNICE - 0.7, 0), fo, 0.9,
			false)
		FhP.band(lm, "Trim", fa, fb, fo, TOP - 0.45, 0.45, 0.25)

# --- Main front ----------------------------------------------------------

## Terrace, columns, architrave and roundel frieze, attic, and the
## recessed wall behind the columns.
static func _front(lm: LandmarkMesh) -> void:
	var span := PX1 - PX0
	var bay := span / 15.0
	var fo := Vector3(0, 0, 1)
	var fz := (ZW + ZF) * 0.5
	FhU.blk(lm, "Step", CX, 0.0, fz, span, TERR, ZF - ZW)
	for i in 14:
		_finne_column(lm, Vector3(PX0 + float(i + 1) * bay, TERR, 27.2), 0.85, COL_H)
	# Architrave with its soffit beams, the frieze, the attic.
	var top_col := TERR + COL_H
	FhU.blk(lm, "Trim", CX, top_col, fz, span, FRIEZE0 - top_col, ZF - ZW)
	for i in 16:
		lm.box("Trim", Vector3(PX0 + float(i) * bay, top_col - 0.2, fz), Vector3(0.5, 0.4, ZF - ZW))
	FhU.blk(lm, "Granite", CX, FRIEZE0, fz, span, RIM - FRIEZE0, ZF - ZW)
	FhP.band(lm, "Trim", Vector3(PX0, 0, ZF), Vector3(PX1, 0, ZF), fo, FRIEZE0, 0.3, 0.15)
	# Seventeen roundels across colonnade and pylons, tablets between.
	var ry := FRIEZE0 + 1.4
	var rx0 := PX0 - 2.8
	var rstep := (span + 5.6) / 16.0
	for i in 17:
		var rc := Vector3(rx0 + float(i) * rstep, ry, ZF)
		var blind := i == 0 or i == 16
		lm.disc("Trim" if blind else "Glass", rc + Vector3(0, 0, 0.03 if blind else -0.15), fo, 0.72, 16)
		FhP.ring(lm, "Trim", rc - Vector3(0, 0, 0.15), fo, 0.72, 0.98, 0.3, 16)
		if not blind:
			lm.box("Bronze", rc - Vector3(0, 0, 0.12), Vector3(1.44, 0.07, 0.05), Basis(), 0.0)
			lm.box("Bronze", rc - Vector3(0, 0, 0.12), Vector3(0.07, 1.44, 0.05), Basis(), 0.0)
		if i < 16:
			lm.box("Trim", rc + Vector3(rstep * 0.5, 0, 0.08), Vector3(0.32, 1.1, 0.16))
	# The recessed wall: 15 bays of arched window or door, a tall window
	# and a short one, punched into the darker granite.
	var wa := Vector3(PX0, 0, ZW)
	var wb := Vector3(PX1, 0, ZW)
	FhP.pierce(lm, "Recess", "Glass", wa, wb, fo, TERR + 5.0, 14.0, 15, 2, Vector2(1.2, 6.0), 0.6, 9.1, 0.3)
	_bars(lm, wa, wb, fo, TERR + 5.6, 15, Vector2(1.2, 6.0), 6)
	_bars(lm, wa, wb, fo, TERR + 14.7, 15, Vector2(1.2, 2.7), 3)
	FhP.band(lm, "Recess", wa, wb, fo, TERR + 13.9, 0.25, 0.4)
	for i in 15:
		var wx := PX0 + (float(i) + 0.5) * bay
		var door := i == 4 or i == 7 or i == 10
		var oc := Vector3(wx, TERR, ZW)
		FhU.blk(lm, "Recess", wx, TERR, ZW + 0.15, bay - 0.01, 5.0, 0.3)
		_arched(lm, oc + Vector3(0, 0, 0.3), fo, 1.7, 3.9, door)
		_lion(lm, oc + Vector3(0, 4.45, 0.38), fo, 0.55)
		# A wall lantern on its bracket between bays.
		if i > 0:
			var lx := PX0 + float(i) * bay
			lm.box("Bronze", Vector3(lx, TERR + 6.0, ZW + 0.6), Vector3(0.08, 0.08, 0.5), Basis(), 0.0)
			lm.box("Bronze", Vector3(lx, TERR + 5.75, ZW + 0.85), Vector3(0.3, 0.45, 0.3))

## An arched opening w x h (to the crown) on the wall face at ground point
## `o`: dark-framed glazing with a fanlight, or bronze doors under a glazed
## fanlight, in a shallow reveal.
static func _arched(lm: LandmarkMesh, o: Vector3, out: Vector3, w: float, h: float, door: bool) -> void:
	var n := out.normalized()
	var rt := Vector3.UP.cross(n).normalized()
	var basis := Basis(rt, Vector3.UP, n)
	var spring := h - w * 0.5
	var g := o + n * 0.02
	lm.quad("Bronze" if door else "Glass", g - rt * w * 0.5, g + rt * w * 0.5, g + rt * w * 0.5 + Vector3(0, spring, 0),
		g - rt * w * 0.5 + Vector3(0, spring, 0), n)
	FhU.opening(lm, "Glass", g + Vector3(0, spring, 0), n, w, w * 0.5, true)
	LandmarkDetail.arch(lm, "Trim", o + Vector3(0, spring, 0), n, w, 0.22, 0.12, 13)
	lm.box("Bronze", g + Vector3(0, spring, 0.03), Vector3(w, 0.1, 0.06), basis, 0.0)
	lm.box("Bronze", g + Vector3(0, h * 0.5, 0.03), Vector3(0.09, h, 0.06), basis, 0.0)
	if not door:
		for k in 2:
			lm.box("Bronze", g + Vector3(0, spring * (float(k) + 1.0) / 3.0, 0.03), Vector3(w, 0.07, 0.06), basis, 0.0)

## Finne's column: square plinth and torus, a smooth monolithic shaft with
## slight entasis, and the stylised capital: necking ring, slightly flared
## bell with low leaf blades and four side volutes, and the concave-sided
## abacus with pointed corners. h is base to abacus top.
static func _finne_column(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	var cap_h := r * 2.2
	var base_h := r * 0.6
	lm.box("Column", base + Vector3(0, base_h * 0.3, 0), Vector3(r * 2.5, base_h * 0.6, r * 2.5))
	lm.lathe("Column", base + Vector3(0, base_h * 0.6, 0), PackedVector2Array([Vector2(r * 1.15, 0),
		Vector2(r * 1.16, base_h * 0.15), Vector2(r * 1.04, base_h * 0.4)]), 20)
	var sb := base + Vector3(0, base_h, 0)
	var sh := h - cap_h - base_h
	lm.lathe("Column", sb, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.99, sh * 0.33),
		Vector2(r * 0.94, sh * 0.7), Vector2(r * 0.88, sh)]), 20, 1.0, 1.0, 0.0, true, false)
	var cb := sb + Vector3(0, sh, 0)
	var ra := r * 0.88
	lm.frustum("Column", cb, ra * 1.08, ra * 1.08, cap_h * 0.09, 20)
	lm.lathe("Column", cb + Vector3(0, cap_h * 0.09, 0), PackedVector2Array([Vector2(ra, 0),
		Vector2(ra * 1.02, cap_h * 0.35), Vector2(ra * 1.12, cap_h * 0.62), Vector2(ra * 1.3, cap_h * 0.74)]), 20)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Column", cb + d * ra * 0.98 + Vector3(0, cap_h * 0.1, 0),
			cb + d * ra * 1.08 + Vector3(0, cap_h * 0.36, 0), r * 0.42, r * 0.08, d.cross(Vector3.UP))
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		var tip := cb + d * r * 1.32 + Vector3(0, cap_h * 0.66, 0)
		lm.beam("Column", cb + d * ra * 1.0 + Vector3(0, cap_h * 0.2, 0), tip, r * 0.12)
		lm.lathe("Column", tip - Vector3(0, r * 0.13, 0), FhU.ball(r * 0.13), 8)
	# Abacus: a square slab with diagonal horns, so its sides read concave.
	var ay := cb + Vector3(0, cap_h * 0.86, 0)
	lm.box("Column", ay, Vector3(r * 2.3, cap_h * 0.16, r * 2.3))
	for k in 2:
		lm.box("Column", ay, Vector3(r * 3.6, cap_h * 0.16, r * 0.7), Basis(Vector3.UP, PI * 0.25 + PI * 0.5 * float(k)))
	lm.box("Column", ay + Vector3(0, cap_h * 0.1, 0), Vector3(r * 2.1, cap_h * 0.06, r * 2.1))

## Finne's stylised lion-head boss, `s` across, on a wall facing `out`.
static func _lion(lm: LandmarkMesh, c: Vector3, out: Vector3, s: float) -> void:
	var o := out.normalized()
	var rt := Vector3.UP.cross(o).normalized()
	var basis := Basis(rt, Vector3.UP, o)
	lm.box("Trim", c, Vector3(s, s, s * 0.25), basis)
	lm.lathe("Trim", c + o * s * 0.12 - Vector3(0, s * 0.15, 0), FhU.ball(s * 0.22), 8)
	for k: float in [-1.0, 1.0]:
		lm.box("Trim", c + rt * s * 0.32 * k + Vector3(0, s * 0.42, 0) + o * s * 0.1, Vector3(s * 0.2, s * 0.2,
			s * 0.15), basis)

## Dark glazing grid over a row of `cols` windows `win` (w, h) whose sills
## sit at y0, centred in equal bays along a..b: `rows` transoms and two
## mullions in each.
static func _bars(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, y0: float, cols: int, win: Vector2,
		rows: int) -> void:
	var o := out.normalized()
	var rt := Vector3.UP.cross(o).normalized()
	var basis := Basis(rt, Vector3.UP, o)
	for i in cols:
		var p := a.lerp(b, (float(i) + 0.5) / float(cols)) + o * 0.06
		for k: float in [-1.0, 1.0]:
			var mp := p + rt * win.x * k / 6.0
			lm.box("Bronze", Vector3(mp.x, y0 + win.y * 0.5, mp.z), Vector3(0.06, win.y, 0.05), basis, 0.0)
		for j in rows - 1:
			lm.box("Bronze", Vector3(p.x, y0 + win.y * float(j + 1) / float(rows), p.z), Vector3(win.x, 0.06, 0.05),
				basis, 0.0)

# --- Stair -------------------------------------------------------------------

## Upper flight as wide as the colonnade, the landing, then the lower flight
## running out beside the wings, with dark handrails down the flights.
static func _stair(lm: LandmarkMesh) -> void:
	var span := PX1 - PX0
	var up_rise := (TERR - LANDING_Y) / float(UPPER)
	for k in UPPER:
		var d := TREAD * float(k + 1)
		var hk := LANDING_Y + up_rise * float(UPPER - k)
		lm.box("Step", Vector3(CX, hk * 0.5, ZF + d * 0.5), Vector3(span + 1.0, hk, d))
	var z_land := ZF + TREAD * float(UPPER)
	var wide := X1 - X0 + 4.0
	FhU.blk(lm, "Step", CX, 0.0, z_land + LANDING_D * 0.5, wide, LANDING_Y, LANDING_D)
	var z_low := z_land + LANDING_D
	var lo_rise := LANDING_Y / float(LOWER)
	for k in LOWER:
		var d := TREAD * float(k + 1)
		var hk := lo_rise * float(LOWER - k)
		lm.box("Step", Vector3(CX, hk * 0.5, z_low + d * 0.5), Vector3(wide, hk, d))
	var z_foot := z_low + TREAD * float(LOWER)
	for x: float in [PX0 + 4.5, CX - 3.6, CX + 3.6, PX1 - 4.5]:
		_rail(lm, Vector3(x, TERR, ZF + 0.2), Vector3(x, LANDING_Y, z_land))
		_rail(lm, Vector3(x, LANDING_Y, z_low), Vector3(x, 0.0, z_foot))

## A dark steel handrail 0.9 m over the nosings from a to b (on the steps),
## with posts about every 3 m.
static func _rail(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var up := Vector3(0, 0.9, 0)
	lm.beam("Bronze", a + up, b + up, 0.06)
	var n := maxi(int(a.distance_to(b) / 3.0), 1)
	for k in n + 1:
		var p := a.lerp(b, float(k) / float(n))
		lm.box("Bronze", p + up * 0.5, Vector3(0.05, 0.9, 0.05), Basis(), 0.0)

# --- Flanks and back -------------------------------------------------------

static func _flanks(lm: LandmarkMesh) -> void:
	for s: float in [-1.0, 1.0]:
		var x := X1 if s > 0.0 else X0
		var o := Vector3(s, 0, 0)
		_field(lm, Vector3(x, 0, ZB + 6.0), Vector3(x, 0, ZF - 13.0), o, 10)
		for z: float in [ZB + 3.0, ZF - 6.5]:
			_stair_window(lm, Vector3(x, 0, z), o)
	_field(lm, Vector3(X1 - 5.0, 0, ZB), Vector3(X0 + 5.0, 0, ZB), Vector3(0, 0, -1), 17)

## A plain coursed wall run a..b (ground points): six rows of punched
## dark-framed windows, then small squares under the main cornice.
static func _field(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, bays: int) -> void:
	var win := Vector2(1.4, 2.6)
	FhP.pierce(lm, "Granite", "Glass", a, b, out, 1.2, 27.0, bays, 6, win, 0.6, 4.4, 0.3)
	for j in 6:
		_bars(lm, a, b, out, 1.8 + 4.4 * float(j), bays, win, 2)
	FhP.pierce(lm, "Granite", "Glass", a, b, out, 28.2, 1.9, bays, 1, Vector2(1.1, 1.1), 0.4, 3.0, 0.3)
	FhP.band(lm, "Trim", a, b, out, 25.6, 0.3, 0.45)

## The tall framed stair window on a flank: a projecting stone frame and a
## fine dark grid, from the first floor to under the cornice.
static func _stair_window(lm: LandmarkMesh, p: Vector3, out: Vector3) -> void:
	var o := out.normalized()
	var rt := Vector3.UP.cross(o).normalized()
	var basis := Basis(rt, Vector3.UP, o)
	var y0 := 5.0
	var h := 21.0
	var w := 1.8
	var g := p + o * 0.03
	lm.quad("Glass", g - rt * w * 0.5 + Vector3(0, y0, 0), g + rt * w * 0.5 + Vector3(0, y0, 0),
		g + rt * w * 0.5 + Vector3(0, y0 + h, 0), g - rt * w * 0.5 + Vector3(0, y0 + h, 0), o)
	for k: float in [-1.0, 1.0]:
		lm.box("Trim", p + rt * (w * 0.5 + 0.25) * k + Vector3(0, y0 + h * 0.5, 0) + o * 0.2, Vector3(0.5, h, 0.4), basis)
	lm.box("Trim", p + Vector3(0, y0 + h + 0.3, 0) + o * 0.25, Vector3(w + 1.4, 0.6, 0.5), basis)
	lm.box("Trim", p + Vector3(0, y0 - 0.2, 0) + o * 0.25, Vector3(w + 1.2, 0.4, 0.5), basis)
	lm.box("Bronze", g + Vector3(0, y0 + h * 0.5, 0.0) + o * 0.03, Vector3(0.07, h, 0.05), basis, 0.0)
	var n := int(h / 1.2)
	for k in n:
		lm.box("Bronze", g + Vector3(0, y0 + 1.2 * float(k + 1), 0) + o * 0.03, Vector3(w, 0.06, 0.05), basis, 0.0)

# --- Wings, gallery doors, grounds ------------------------------------------

## The one-storey wings by the stair: tall recessed arched windows, a
## rosette frieze under the cornice and the flat terrace roof. Each runs on
## in front of its pylon, where the public-gallery door faces the street.
static func _wings(lm: LandmarkMesh) -> void:
	var wh := TERR + 0.4
	for s: float in [-1.0, 1.0]:
		var side: Array = [X0 - 16.0, X0, ZW - 4.0, ZF + 9.0] if s < 0.0 else [X1, X1 + 16.0, ZW - 4.0, ZF + 9.0]
		var front: Array = [X0, PX0 - 0.5, ZF, ZF + 9.0] if s < 0.0 else [PX1 + 0.5, X1, ZF, ZF + 9.0]
		for pi in 2:
			var part: Array = side if pi == 0 else front
			var is_front := pi == 1
			var a: float = part[0]
			var b: float = part[1]
			var c: float = part[2]
			var e: float = part[3]
			var wc := Vector3((a + b) * 0.5, 0.0, (c + e) * 0.5)
			FhU.blk(lm, "Granite", wc.x, 0.0, wc.z, b - a, wh, e - c)
			FhU.blk(lm, "Step", wc.x, wh, wc.z, b - a - 0.6, 0.1, e - c - 0.6)
			for face in FhP.faces(wc.x, wc.z, b - a, e - c):
				var fa: Vector3 = face[0]
				var fb: Vector3 = face[1]
				var fo: Vector3 = face[2]
				# Faces against the main block or the other part stay plain.
				if fo.z < -0.5 or (is_front and absf(fo.x) > 0.5):
					continue
				if not is_front and ((fo.x > 0.5 and s < 0.0) or (fo.x < -0.5 and s > 0.0)):
					continue
				LandmarkDetail.cornice(lm, "Trim", fa + Vector3(0, wh - 0.6, 0), fb + Vector3(0, wh - 0.6, 0), fo, 0.6,
					false)
				var l := fa.distance_to(fb)
				var nr := int(l / 2.2)
				for k in nr:
					var rp := fa.lerp(fb, (float(k) + 0.5) / float(nr))
					lm.disc("Trim", rp + Vector3(0, wh - 1.05, 0) + fo * 0.05, fo, 0.25, 8)
				if is_front:
					_gallery_door(lm, (fa + fb) * 0.5, fo)
					continue
				var nw := maxi(int(l / 3.6), 1)
				FhP.pierce(lm, "Granite", "Glass", fa, fb, fo, 0.0, wh - 1.4, nw, 1, Vector2(1.5, 3.8), 1.2, 4.0, 0.45)
				for k in nw:
					var ap := fa.lerp(fb, (float(k) + 0.5) / float(nw))
					FhU.opening(lm, "Glass", ap + Vector3(0, 5.0, 0) + fo * 0.1, fo, 1.5, 0.75, true)
					LandmarkDetail.arch(lm, "Trim", ap + Vector3(0, 5.0, 0), fo, 1.5, 0.2, 0.15, 11)

## A public-gallery door at ground point `c` on a wall facing `out`: a
## raised plinth and steps, and a stone frame widening toward the foot
## round dark bronze doors, under a lintel.
static func _gallery_door(lm: LandmarkMesh, c: Vector3, out: Vector3) -> void:
	var o := out.normalized()
	var rt := Vector3.UP.cross(o).normalized()
	var basis := Basis(rt, Vector3.UP, o)
	var y0 := 0.9
	var h := 3.0
	var wb := 3.0
	var wt := 2.6
	var fw := 0.5
	var dp := 0.3
	var p := c + Vector3(0, y0, 0)
	lm.box("Step", c + Vector3(0, y0 * 0.5, 0) + o * 0.9, Vector3(wb + 3.0, y0, 1.8), basis)
	FhU.steps(lm, "Step", c + o * 1.8, o, wb + 2.0, 0.35, 0.18, 5)
	for k: float in [-1.0, 1.0]:
		var foot := p + rt * (wb * 0.5 + fw * 0.5) * k + o * dp * 0.5
		var head := p + rt * (wt * 0.5 + fw * 0.5) * k + o * dp * 0.5 + Vector3(0, h, 0)
		lm.beam("Trim", foot, head, fw, dp, o)
	lm.box("Trim", p + Vector3(0, h + 0.3, 0) + o * dp * 0.6, Vector3(wt + fw * 3.0, 0.6, dp * 1.2), basis)
	var g := p + o * 0.03
	lm.quad("Bronze", g - rt * wb * 0.5, g + rt * wb * 0.5, g + rt * wt * 0.5 + Vector3(0, h, 0),
		g - rt * wt * 0.5 + Vector3(0, h, 0), o)
	lm.quad("Glass", g - rt * wt * 0.45 + Vector3(0, h * 0.75, 0.01), g + rt * wt * 0.45 + Vector3(0, h * 0.75, 0.01),
		g + rt * wt * 0.45 + Vector3(0, h * 0.97, 0.01), g - rt * wt * 0.45 + Vector3(0, h * 0.97, 0.01), o)

## Aaltonen's bronze statues on red granite pedestals, Ståhlberg to the
## north (-X) and Svinhufvud to the south (+X), and the two white flagpoles
## at the outer ends of the forecourt.
static func _grounds(lm: LandmarkMesh) -> void:
	for x: float in [X0 - 6.0, X1 + 6.0]:
		var p := Vector3(x, 0.0, ZF + 15.0)
		lm.box("Pedestal", p + Vector3(0, 0.2, 0), Vector3(3.6, 0.4, 3.0))
		lm.box("Pedestal", p + Vector3(0, 1.4, 0), Vector3(2.6, 2.0, 2.0))
		LandmarkKits.statue_figure(lm, "Bronze", p + Vector3(0, 2.4, 0), 3.6, false)
	for x: float in [X0 - 14.0, X1 + 14.0]:
		var p := Vector3(x, 0.0, ZF + 20.0)
		lm.box("Step", p + Vector3(0, 0.25, 0), Vector3(1.0, 0.5, 1.0))
		lm.frustum("Pole", p + Vector3(0, 0.5, 0), 0.14, 0.06, 25.0, 8)
		lm.lathe("Pole", p + Vector3(0, 25.5, 0), FhU.ball(0.18), 8)

# --- Roof, courts and the Session Hall ---------------------------------------

## The flat dark roof deck behind the parapet, round the courts and the
## hall, with rows of small glazed skylights and a plant room.
static func _roof(lm: LandmarkMesh) -> void:
	var y := RIM + 0.02
	var xi0 := X0 + 0.8
	var xi1 := X1 - 0.8
	var zi0 := ZB + 0.8
	var zi1 := ZF - 0.8
	for r in [[xi0, xi1, zi0, ZC0], [xi0, xi1, ZC1, zi1], [xi0, CL0, ZC0, ZC1], [CL1, CR0, ZC0, ZC1],
			[CR1, xi1, ZC0, ZC1], [CL0, CL1, ZM0, ZM1], [CR0, CR1, ZM0, ZM1]]:
		var a: float = r[0]
		var b: float = r[1]
		var c: float = r[2]
		var d: float = r[3]
		lm.quad("Roof", Vector3(a, y, d), Vector3(b, y, d), Vector3(b, y, c), Vector3(a, y, c), Vector3.UP)
	# Skylights in rows round the ranges, 4 m in from the parapet.
	var ring := [[Vector3(X0 + 4.0, y, ZF - 4.0), Vector3(X1 - 4.0, y, ZF - 4.0)],
		[Vector3(X0 + 4.0, y, ZB + 4.0), Vector3(X1 - 4.0, y, ZB + 4.0)],
		[Vector3(X0 + 4.0, y, ZB + 9.0), Vector3(X0 + 4.0, y, ZF - 9.0)],
		[Vector3(X1 - 4.0, y, ZB + 9.0), Vector3(X1 - 4.0, y, ZF - 9.0)]]
	for run in ring:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var n := int(a.distance_to(b) / 4.8)
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(n))
			lm.box("Seam", p + Vector3(0, 0.2, 0), Vector3(1.6, 0.4, 1.6))
			FhU.hip(lm, "Glass", p + Vector3(0, 0.4, 0), 1.5, 1.5, 0.8)
	FhU.blk(lm, "Granite", X1 - 13.0, RIM, ZW - 7.0, 7.0, 2.2, 4.0)
	FhU.blk(lm, "Roof", X1 - 13.0, RIM + 2.2, ZW - 7.0, 7.4, 0.2, 4.4)

## The four narrow light courts: a paved floor, coursed walls with four
## rows of windows and a coping on the rim.
static func _courts(lm: LandmarkMesh) -> void:
	for r in [[CL0, CL1, ZC0, ZM0], [CL0, CL1, ZM1, ZC1], [CR0, CR1, ZC0, ZM0], [CR0, CR1, ZM1, ZC1]]:
		var a: float = r[0]
		var b: float = r[1]
		var c: float = r[2]
		var d: float = r[3]
		lm.quad("Step", Vector3(a, COURT_Y, d), Vector3(b, COURT_Y, d), Vector3(b, COURT_Y, c), Vector3(a, COURT_Y, c),
			Vector3.UP)
		var walls := [[Vector3(a, 0, c), Vector3(b, 0, c), Vector3(0, 0, 1)],
			[Vector3(b, 0, c), Vector3(b, 0, d), Vector3(-1, 0, 0)],
			[Vector3(b, 0, d), Vector3(a, 0, d), Vector3(0, 0, -1)],
			[Vector3(a, 0, d), Vector3(a, 0, c), Vector3(1, 0, 0)]]
		for wl in walls:
			var wa: Vector3 = wl[0]
			var wb: Vector3 = wl[1]
			var o: Vector3 = wl[2]
			var n := maxi(int(wa.distance_to(wb) / 3.0), 1)
			FhP.pierce(lm, "Granite", "Glass", wa, wb, o, COURT_Y, RIM - COURT_Y, n, 4, Vector2(1.2, 2.4), 1.2, 4.8,
				0.2)
			FhP.band(lm, "Trim", wa, wb, o, RIM - 0.4, 0.5, 0.25)

## The Session Hall seen from above: a low granite drum, the ribbed saucer
## dome, the windowed lantern drum with its faceted cone, and the two small
## round drums either side.
static func _hall(lm: LandmarkMesh) -> void:
	var drum_top := RIM + 0.6
	lm.frustum("Granite", HALL + Vector3(0, RIM - 0.3, 0), HALL_R, HALL_R, 0.9, 40)
	lm.frustum("Trim", HALL + Vector3(0, drum_top - 0.1, 0), HALL_R + 0.25, HALL_R + 0.25, 0.25, 40)
	var dome_h := 0.9
	lm.lathe("Roof", HALL + Vector3(0, drum_top, 0), FhU.dome_prof(HALL_R, dome_h, 8), 40)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := HALL + d * HALL_R + Vector3(0, drum_top + 0.05, 0)
		for j in range(1, 4):
			var ang := PI * 0.5 * float(j) / 3.0 * 0.75
			var p := HALL + d * HALL_R * cos(ang) + Vector3(0, drum_top + 0.05 + dome_h * sin(ang), 0)
			lm.beam("Seam", prev, p, 0.16, 0.1, d.cross(Vector3.UP))
			prev = p
	# The lantern drum: a ring of tall windows between dark posts.
	var lr := 4.2
	var lb := HALL + Vector3(0, drum_top + dome_h * 0.6, 0)
	lm.frustum("Roof", lb, lr, lr, 0.3, 24)
	lm.frustum("Glass", lb + Vector3(0, 0.3, 0), lr - 0.05, lr - 0.05, 0.85, 24)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Seam", lb + Vector3(cos(a) * lr, 0.72, sin(a) * lr), Vector3(0.18, 0.85, 0.18), Basis(), 0.0)
	lm.lathe("Roof", lb + Vector3(0, 1.15, 0), PackedVector2Array([Vector2(lr + 0.2, 0), Vector2(lr * 0.15, 0.55),
		Vector2(0.0, 0.6)]), 16, 1.0, 1.0, 0.0, false)
	for x: float in [HALL.x - HALL_R - 2.2, HALL.x + HALL_R + 2.2]:
		var p := Vector3(x, RIM, HALL.z)
		lm.frustum("Granite", p, 1.8, 1.8, 1.2, 20)
		lm.frustum("Roof", p + Vector3(0, 1.2, 0), 2.0, 1.6, 0.2, 20)
