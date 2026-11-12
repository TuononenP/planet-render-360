class_name LandmarkFhKatajanokka
extends RefCounted

## Katajanokka, true metres, extruded from OpenStreetMap outlines
## (LandmarkFhInnerFootprints): Alvar Aalto's Enso-Gutzeit headquarters
## (1962, "Sokeripala"), five storeys of square windows in a white Carrara
## marble grid over a recessed colonnade, a set-back glazed top floor
## under a thin roof slab, the south-east face left blank for an
## extension that never came, and the recess facing Uspenski; Engel's
## Merikasarmi (1816–38, now the Foreign Ministry), ochre Empire wings
## with column porticos under grey hipped roofs; and the brick Katajanokka
## ferry terminal on its pillared ground floor. Sources and estimates:
## docs/helsinki-landmark-sources.md.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENSO_M := 24.0
const MERIKASARMI_M := 18.0
const TERMINAL_M := 14.0

static func enso(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F3F2EE", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#26333A"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6C6A66", 3.0))
	lm.use("Metal", LandmarkMaterials.paint("#5E5446", 0.5, 0.6))
	var poly := I.outline("enso_gutzeit_hq")
	var skin := F.offset(poly, -0.45)
	var floors := 5
	var pitch := 3.3
	var y0 := 4.4
	var grid_top := y0 + pitch * float(floors)
	# Recessed glazed ground floor behind the marble-clad columns.
	lm.poly_prism("Granite", F.offset(poly, 0.1), 0.0, 0.35)
	lm.poly_prism("Glass", F.offset(poly, -2.2), 0.35, y0)
	W.ribs(lm, "Marble", F.offset(poly, -0.6), 0.35, y0, 5.4, 0.55, 0.55)
	# The grid: square windows set back between marble piers and spandrels.
	lm.poly_prism("Marble", F.offset(poly, -2.2), y0 - 0.5, y0)
	lm.poly_prism("Glass", skin, y0, grid_top, false)
	W.ribs(lm, "Marble", skin, y0, grid_top, 2.05, 0.5, 0.45)
	W.ribbons(lm, "Marble", skin, y0, 1.35, floors, pitch, 0.45)
	_blank_face(lm, poly, Vector2(0.7071, 0.7071), y0, grid_top)
	lm.poly_prism("Marble", poly, grid_top, grid_top + 0.5)
	# Set-back top floor of brass-framed glass under the thin roof slab.
	var top_floor := F.offset(poly, -1.6)
	lm.poly_prism("Glass", top_floor, grid_top + 0.5, ENSO_M - 0.4, false)
	W.ribs(lm, "Metal", top_floor, grid_top + 0.5, ENSO_M - 0.4, 1.6, 0.08, 0.1)
	lm.poly_prism("Marble", F.offset(poly, -0.3), ENSO_M - 0.4, ENSO_M)
	lm.commit(model, "Enso_")

## A full marble wall over the facade edge whose outward normal is
## closest to `dir` (the blank south-east end).
static func _blank_face(lm: LandmarkMesh, poly: PackedVector2Array, dir: Vector2, y0: float, y1: float) -> void:
	var best := -2.0
	var at := 0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var d := W.outward(poly, a, b).dot(dir)
		if d > best and a.distance_to(b) > 8.0:
			best = d
			at = i
	var a := poly[at]
	var b := poly[(at + 1) % poly.size()]
	var along := (b - a).normalized()
	var c := (a + b) * 0.5 - W.outward(poly, a, b) * 0.25
	lm.box("Marble", Vector3(c.x, (y0 + y1) * 0.5, c.y), Vector3(a.distance_to(b), y1 - y0, 0.5),
		Basis(Vector3.UP, atan2(-along.y, along.x)), 0.0)

## Merikasarmi's main barracks (OSM way 23446530): the long courtyard
## wing between two end blocks, each with a south wing ending in a
## pedimented portico, three storeys of punched windows, a white
## colonnade in the middle of the courtyard front and chimneys on the ridge.
static func merikasarmi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#E2C57C", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F2EFE6", 2.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#7A7670", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F3A3F"))
	lm.use("Roof", LandmarkMaterials.paint("#7B7F80", 0.6, 0.4))
	var poly := I.outline("merikasarmi")
	var eave := 12.6
	lm.poly_prism("Plinth", F.offset(poly, 0.12), 0.0, 0.9)
	lm.poly_prism("Render", poly, 0.9, eave)
	lm.poly_prism("Trim", F.offset(poly, 0.12), 4.1, 4.4, false)
	lm.poly_prism("Trim", F.offset(poly, 0.3), eave - 0.5, eave, false)
	W.edge_windows(lm, "Glass", poly, 1.4, 3, 4.1, 3.0, 1.2, 2.1, "Trim")
	# Frame along the courtyard wing: u east-south-east, n toward the sea.
	var u := (Vector2(37.1, -26.0) - Vector2(-43.3, 16.3)).normalized()
	var n := Vector2(-u.y, u.x)
	var rects := [[-48.0, 46.0, -5.7, 12.1], [-63.8, -48.0, -1.4, 10.1], [-63.8, -46.0, -22.9, -11.5],
		[-50.6, -46.0, -11.5, -1.4], [46.0, 63.3, -1.4, 10.9], [44.9, 63.2, -21.6, -10.8],
		[44.9, 50.0, -10.9, -1.4]]
	for r: Array in rects:
		var u0 := float(r[0]) - 0.4
		var u1 := float(r[1]) + 0.4
		var n0 := float(r[2]) - 0.4
		var n1 := float(r[3]) + 0.4
		var rise := minf(u1 - u0, n1 - n0) * 0.5 * 0.47
		W.hip_rect(lm, "Roof", u * u0 + n * n0, u * u1 + n * n0, u * u1 + n * n1, u * u0 + n * n1, eave, rise)
	# Chimneys along the long wing's ridge.
	for k in 7:
		var c := u * (-36.0 + 12.0 * float(k)) + n * 3.2
		U.blk(lm, "Render", c.x, eave + 3.0, c.y, 1.0, MERIKASARMI_M - eave - 3.0, 1.0)
	# Pedimented porticos on the two south wings, the courtyard colonnade.
	_portico(lm, u, n, -63.8, -46.0, -22.9, eave, true)
	_portico(lm, u, n, 44.9, 63.2, -21.6, eave, true)
	_portico(lm, u, n, -12.0, 12.0, -5.7, eave, false)
	lm.commit(model, "Merikasarmi_")

## Columns standing 1.5 m out from the face at n = `face` between u0 and
## u1 over the rusticated ground floor, an entablature and, when
## `pediment`, a gable closing the front.
static func _portico(lm: LandmarkMesh, u: Vector2, n: Vector2, u0: float, u1: float, face: float,
		eave: float, pediment: bool) -> void:
	var front := face - 1.5
	var a := u * (u0 + 1.6) + n * front
	var b := u * (u1 - 1.6) + n * front
	var count := 6 if pediment else 8
	U.columns(lm, "Trim", Vector3(a.x, 4.4, a.y), Vector3(b.x, 4.4, b.y), count, eave - 4.4 - 0.7, 0.42)
	var mid := u * ((u0 + u1) * 0.5) + n * (face - 0.75)
	var basis := Basis(Vector3.UP, atan2(n.x, n.y))
	lm.box("Trim", Vector3(mid.x, eave - 0.35, mid.y), Vector3(u1 - u0 - 1.0, 0.7, 2.0), basis, 0.0)
	if pediment:
		var c := u * ((u0 + u1) * 0.5) + n * (face + 2.5)
		lm.gable("Roof", Vector3(c.x, eave, c.y), u1 - u0 - 1.0, 8.0, 2.6, basis, 0.2, "Trim")

## Dark brick upper storeys on a recessed glazed ground floor behind
## concrete pillars, window rows with concrete sills, a plant room on the
## flat roof.
static func terminal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#5E3A30", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A8A49C", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C3539"))
	lm.use("Roof", LandmarkMaterials.paint("#4B4D4E", 0.8))
	lm.use("Metal", LandmarkMaterials.paint("#2E3133", 0.5))
	var poly := I.outline("katajanokka_terminal")
	var eave := 12.6
	lm.poly_prism("Glass", F.offset(poly, -2.0), 0.0, 4.2)
	W.ribs(lm, "Concrete", F.offset(poly, -0.9), 0.0, 4.2, 4.5, 0.9, 0.9)
	lm.poly_prism("Brick", poly, 4.2, eave)
	lm.poly_prism("Concrete", F.offset(poly, 0.1), 4.0, 4.4, false)
	W.edge_windows(lm, "Glass", poly, 5.4, 2, 3.5, 2.4, 1.4, 2.0, "Concrete")
	lm.poly_prism("Concrete", F.offset(poly, 0.1), eave, eave + 0.4, false)
	lm.poly_prism("Roof", F.offset(poly, -0.2), eave, eave + 0.2)
	U.blk(lm, "Metal", 5.0, eave, 0.0, 14.0, TERMINAL_M - eave, 8.0)
	lm.commit(model, "Katajanokka_terminal_")
