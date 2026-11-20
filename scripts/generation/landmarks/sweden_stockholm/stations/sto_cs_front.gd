extends RefCounted

## The Vasagatan front of Stockholm Central: Edelsvarda's 1871 range, +Z out
## to the square. Spec, from visual-plan/refs/landmarks/stockholm_central_station
## (front.jpg, quarter.jpg) and the OSM outline:
## - Pale grey-white plaster over a rusticated granite ground floor with
##   round-arched windows, a stringcourse above it, two plastered floors of
##   framed rectangular windows (nine bays a wing) and a moulded cornice.
## - The central block stands 4-5 m forward and a little higher: a rusticated
##   arcade of four round arches under a flat marquee with the CENTRALSTATION
##   letters, a piano nobile of five tall arched windows between two pairs of
##   pilasters, a frieze of small attic windows, and a pedimented bay on each
##   side with its own pair of tall windows.
## - Each end of the range is a pavilion of three or four bays, quoined, with
##   a small pediment on its front.
## The roofs (mansards, dormers, flag) are in sto_cs_roofs.gd.

const P = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_plan.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Height of the rusticated base of the central block.
const C_RUST := 6.0

static func build(lm: LandmarkMesh) -> void:
	var tpl := _bay_template()
	for s in P.SECTIONS:
		var x0 := float(s[0])
		var x1 := float(s[1])
		var zf := float(s[2])
		var kind := str(s[3])
		if kind == "centre":
			_centre(lm)
			continue
		var h := P.EAVE
		var w := x1 - x0
		var d := zf - P.ZB
		FhU.blk(lm, "Wall", (x0 + x1) * 0.5, 0.0, (zf + P.ZB) * 0.5, w, h, d)
		FhU.blk(lm, "Rustic", (x0 + x1) * 0.5, 0.0, zf - 0.05, w, P.RUST, 0.4)
		var a := Vector3(x0, 0, zf)
		var b := Vector3(x1, 0, zf)
		FhP.band(lm, "Trim", a, b, Vector3.BACK, P.RUST, 0.5, 0.25)
		FhP.band(lm, "Trim", a, b, Vector3.BACK, P.FLOOR2 - 0.15, 0.3, 0.12)
		LandmarkDetail.cornice(lm, "Trim", Vector3(x0, h - 0.9, zf), Vector3(x1, h - 0.9, zf), Vector3.BACK, 0.9, false)
		var bays := int(s[4])
		var pitch := w / float(bays)
		for i in bays:
			lm.merge(tpl, Transform3D(Basis(), Vector3(x0 + pitch * (float(i) + 0.5), 0.0, zf)))
		if kind == "pav":
			_pavilion(lm, x0, x1, zf)
	_ends(lm)

## One bay of a wing: the arched ground-floor window and a framed window on
## each upper floor, standing on the facade plane z = 0, built once.
static func _bay_template() -> LandmarkMesh:
	var t := LandmarkMesh.new()
	P.materials(t)
	LandmarkDetail.window(t, "Trim", "Glass", Vector3(0, 2.9, 0.02), Vector3.BACK, 1.5, 3.0, true, 0.2)
	LandmarkDetail.window(t, "Trim", "Glass", Vector3(0, 7.65, 0.02), Vector3.BACK, 1.7, 2.7, false, 0.2)
	LandmarkDetail.window(t, "Trim", "Glass", Vector3(0, 12.15, 0.02), Vector3.BACK, 1.7, 2.5, false, 0.2)
	return t

## An end pavilion: quoin strips on its corners and a small pediment over the
## middle bays.
static func _pavilion(lm: LandmarkMesh, x0: float, x1: float, zf: float) -> void:
	for x in [x0 + 0.55, x1 - 0.55]:
		lm.box("Trim", Vector3(x, P.EAVE * 0.5, zf - 0.05), Vector3(1.1, P.EAVE, 0.5))
	var xm := (x0 + x1) * 0.5
	lm.gable("Trim", Vector3(xm, P.EAVE, zf - 0.3), (x1 - x0) * 0.45, 1.0, 1.7, Basis(), 0.25, "Wall")

## The plain end walls of the two pavilions (the faces on the line of the
## range): windows in the three floors.
static func _ends(lm: LandmarkMesh) -> void:
	var left: Array = P.SECTIONS[0]
	var right: Array = P.SECTIONS[P.SECTIONS.size() - 1]
	for e in [[float(left[0]), float(left[2]), -1.0], [float(right[1]), float(right[2]), 1.0]]:
		var x: float = e[0]
		var out := Vector3(e[2], 0, 0)
		var a := Vector3(x, 0, P.ZB + 1.0)
		var b := Vector3(x, 0, float(e[1]) - 1.0)
		FhU.window_grid(lm, "Glass", a, b, out, 6.4, 2, 4.5, 4, 1.4, 2.4)
		FhU.openings(lm, "Glass", a, b, out, 1.5, 4, 1.2, 2.8, true)
		FhP.band(lm, "Trim", a, b, out, P.RUST, 0.5, 0.2)

## The central block (x -13..22, 47 m deep): arcade and marquee, piano nobile,
## attic frieze, flanking pediments.
static func _centre(lm: LandmarkMesh) -> void:
	var s: Array = P.SECTIONS[2]
	var x0 := float(s[0])
	var x1 := float(s[1])
	var zf := float(s[2])
	var cx := P.CX
	var h := P.C_EAVE
	var out := Vector3.BACK
	FhU.blk(lm, "Wall", (x0 + x1) * 0.5, 0.0, (zf + P.ZC_BACK) * 0.5, x1 - x0, h, zf - P.ZC_BACK)
	FhU.blk(lm, "Rustic", (x0 + x1) * 0.5, 0.0, zf - 0.05, x1 - x0, C_RUST, 0.4)
	var a := Vector3(x0, 0, zf)
	var b := Vector3(x1, 0, zf)
	FhP.band(lm, "Trim", a, b, out, C_RUST, 0.5, 0.3)
	FhP.band(lm, "Trim", a, b, out, P.C_ATTIC - 0.7, 0.7, 0.25)
	LandmarkDetail.cornice(lm, "Trim", Vector3(x0, h - 1.1, zf), Vector3(x1, h - 1.1, zf), out, 1.1, true)
	# Corner strips.
	for x in [x0 + 0.6, x1 - 0.6]:
		lm.box("Trim", Vector3(x, h * 0.5, zf - 0.05), Vector3(1.2, h, 0.5))
	_arcade(lm, zf)
	# Piano nobile: five arched windows, two pairs of pilasters.
	for i in 5:
		var x := cx + (float(i) - 2.0) * 3.6
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 9.4, zf + 0.02), out, 2.2, 4.8, true, 0.25)
	for px in [cx - 10.2, cx + 10.2]:
		for off in [-0.9, 0.9]:
			var x: float = px + off
			lm.box("Trim", Vector3(x, 9.2, zf + 0.12), Vector3(0.8, 5.6, 0.45))
			lm.box("Trim", Vector3(x, 12.2, zf + 0.15), Vector3(1.1, 0.5, 0.6))
			lm.box("Trim", Vector3(x, 6.4, zf + 0.15), Vector3(1.1, 0.4, 0.6))
	# Attic frieze of small windows.
	FhU.openings(lm, "Glass", Vector3(x0 + 1.0, 0, zf), Vector3(x1 - 1.0, 0, zf), out, 13.2, 16, 1.0, 1.8, false)
	# Flank bays: two tall windows each, a pedimented attic over them.
	for fx in [(x0 + cx - 10.2 - 0.9) * 0.5, (x1 + cx + 10.2 + 0.9) * 0.5]:
		var fw := 6.0
		for off in [-1.5, 1.5]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(fx + off, 9.1, zf + 0.02), out, 1.6, 3.8, false, 0.22)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(fx + off, 2.9, zf + 0.02), out, 1.5, 3.0, true, 0.2)
		lm.box("Wall", Vector3(fx, (P.C_ATTIC + h) * 0.5, zf + 0.3), Vector3(fw, h - P.C_ATTIC, 0.7))
		lm.gable("Trim", Vector3(fx, h, zf + 0.3), fw, 1.0, 1.8, Basis(), 0.3, "Wall")
		FhU.openings(lm, "Glass", Vector3(fx - 1.6, 0, zf + 0.7), Vector3(fx + 1.6, 0, zf + 0.7), out, 13.4, 2, 1.0, 1.8, false)

## The rusticated arcade, the marquee over it and its lettering.
static func _arcade(lm: LandmarkMesh, zf: float) -> void:
	var cx := P.CX
	for i in 4:
		var x := cx + (float(i) - 1.5) * 3.6
		K.arch_window(lm, "Trim", "Glass", Vector3(x, 0.0, zf + 0.02), Vector3.BACK, 2.8, 5.0, 3)
	K.canopy(lm, "Steel", "Steel", Vector3(cx - 7.6, 0, zf), Vector3(cx + 7.6, 0, zf), Vector3.BACK, 3.0, 5.2, 4)
	lm.box("Steel", Vector3(cx, 6.1, zf + 0.35), Vector3(15.2, 1.0, 0.3))
	for i in 14:
		var lx := cx - 6.2 + 0.95 * float(i)
		lm.box("Sign", Vector3(lx, 6.1, zf + 0.55), Vector3(0.55, 0.75, 0.12), Basis(), 0.0)
	K.clock(lm, "Dial", "Trim", Vector3(cx - 8.6, 4.2, zf + 0.5), Vector3.BACK, 0.45)
