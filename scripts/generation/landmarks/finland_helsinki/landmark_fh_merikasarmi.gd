extends RefCounted

## Merikasarmi, the Naval Barracks (Carl Ludvig Engel, 1816-38; now the
## Ministry for Foreign Affairs), Katajanokka. True metres from the OSM
## outline of way 23446530 (stored in LandmarkFhInnerFootprints), no yaw: +X
## is east, +Z south.
##
## From the Commons photos in visual-plan/refs/landmarks/merikasarmi/:
## - butter-yellow render with white trim over a rough granite base, three
##   storeys of small rectangular windows with string courses;
## - the long courtyard wing is lower than the two end blocks and has a
##   row of small round-headed attic windows, and in the middle a giant
##   order of eight white pilasters over the upper two storeys, carrying a
##   cornice and a raised flat attic block;
## - each end block ends in a pedimented portico of six tall white columns
##   in front of the upper two storeys;
## - grey zinc hipped roofs with square black chimney stacks about every
##   12 m and a flagpole in the middle.
##
## Measured: the outline and the main axis (28 degrees off east) from OSM.
## Estimated: the 12.6 m eave and 18 m top, the storey pitch, the granite
## base height (2.6 m), pilaster counts and the chimney spacing. LoD2 was not
## used because the LoD2 rows over this wing are merged with its annexes.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENTRY := {"type": "merikasarmi", "name": "Merikasarmi", "lat": 60.168092, "lon": 24.972175,
	"radius_m": 2500.0, "wiki_title": "Merikasarmi", "height_m": 18.0, "clear_m": 15.0,
	"clear_offsets_m": [[-48.2, 28.8], [-30.4, 19.6], [-12.7, 10.3], [22.7, -8.4], [40.4, -17.7],
		[51.5, -22.6], [-56.6, 10.6], [40.3, -39.4]],
	"kind": "Barracks", "aliases": ["merikasarmi", "marinkasernen", "ministry for foreign affairs",
		"ulkoministeriö", "utrikesministeriet", "katajanokka naval barracks"]}

const EAVE := 12.6
const TOP := 18.0
const BASE_H := 2.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#E6CB82", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F2EFE6", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7C7167", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2F3A3F"))
	lm.use("Roof", LandmarkMaterials.paint("#868B92", 0.6, 0.4))
	lm.use("Soot", LandmarkMaterials.paint("#2A2B2D", 0.8, 0.2))
	var poly := I.outline("merikasarmi")
	lm.poly_prism("Granite", F.offset(poly, 0.12), 0.0, BASE_H)
	lm.poly_prism("Render", poly, BASE_H, EAVE)
	lm.poly_prism("Trim", F.offset(poly, 0.12), BASE_H, BASE_H + 0.3, false)
	lm.poly_prism("Trim", F.offset(poly, 0.12), 7.2, 7.45, false)
	lm.poly_prism("Trim", F.offset(poly, 0.35), EAVE - 0.55, EAVE, false)
	W.edge_windows(lm, "Glass", poly, 3.7, 3, 3.0, 3.0, 1.2, 2.1, "Trim")
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
		W.hip_rect(lm, "Roof", u * u0 + n * n0, u * u1 + n * n0, u * u1 + n * n1, u * u0 + n * n1, EAVE, rise)
	# Chimney stacks along the long wing's ridge, black caps.
	for k in 7:
		var c := u * (-36.0 + 12.0 * float(k)) + n * 3.2
		U.blk(lm, "Render", c.x, EAVE + 3.0, c.y, 1.0, TOP - EAVE - 3.6, 1.0)
		U.blk(lm, "Soot", c.x, TOP - 0.6, c.y, 1.3, 0.6, 1.3)
	_attic_windows(lm, u, n)
	_giant_order(lm, u, n)
	_portico(lm, u, n, -63.8, -46.0, -22.9)
	_portico(lm, u, n, 44.9, 63.2, -21.6)
	# Flagpole over the middle of the courtyard wing.
	var m := u * 0.0 + n * 3.0
	lm.beam("Soot", Vector3(m.x, EAVE + 2.0, m.y), Vector3(m.x, TOP, m.y), 0.1)
	lm.commit(model, "Merikasarmi_")

## The round-headed attic windows of the long wing, either side of the
## giant order, on its southern (-n) face.
static func _attic_windows(lm: LandmarkMesh, u: Vector2, n: Vector2) -> void:
	var out := Vector3(-n.x, 0, -n.y)
	for run in [[-46.0, -14.0], [14.0, 46.0]]:
		var a := u * float(run[0]) + n * -5.5
		var b := u * float(run[1]) + n * -5.5
		U.openings(lm, "Glass", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), out, EAVE - 3.2, 14, 1.3, 2.2, true, 0.1)

## Eight pilasters over the upper storeys of the middle of the long wing,
## the entablature, and the taller flat attic block behind it.
static func _giant_order(lm: LandmarkMesh, u: Vector2, n: Vector2) -> void:
	var basis := Basis(Vector3.UP, atan2(-u.y, u.x))
	for k in 8:
		var c := u * (-12.0 + 24.0 * float(k) / 7.0) + n * -6.0
		lm.box("Trim", Vector3(c.x, (4.4 + EAVE - 0.7) * 0.5, c.y), Vector3(1.0, EAVE - 0.7 - 4.4, 0.6), basis, 0.0)
	var mid := u * 0.0 + n * -6.0
	lm.box("Trim", Vector3(mid.x, EAVE - 0.35, mid.y), Vector3(26.0, 0.7, 1.0), basis, 0.0)
	var back := u * 0.0 + n * -4.4
	lm.box("Render", Vector3(back.x, EAVE + 0.9, back.y), Vector3(26.0, 1.8, 3.4), basis, 0.0)
	lm.box("Trim", Vector3(back.x, EAVE + 1.9, back.y), Vector3(26.6, 0.3, 3.8), basis, 0.0)

## Six tall white columns in front of an end block's upper storeys, an
## entablature and a pediment closing the front.
static func _portico(lm: LandmarkMesh, u: Vector2, n: Vector2, u0: float, u1: float, face: float) -> void:
	var front := face - 1.5
	var a := u * (u0 + 1.6) + n * front
	var b := u * (u1 - 1.6) + n * front
	U.columns(lm, "Trim", Vector3(a.x, 4.4, a.y), Vector3(b.x, 4.4, b.y), 6, EAVE - 4.4 - 0.7, 0.42)
	var mid := u * ((u0 + u1) * 0.5) + n * (face - 0.75)
	var basis := Basis(Vector3.UP, atan2(n.x, n.y))
	lm.box("Trim", Vector3(mid.x, EAVE - 0.35, mid.y), Vector3(u1 - u0 - 1.0, 0.7, 2.0), basis, 0.0)
	var c := u * ((u0 + u1) * 0.5) + n * (face + 2.5)
	lm.gable("Roof", Vector3(c.x, EAVE, c.y), u1 - u0 - 1.0, 8.0, 2.6, basis, 0.2, "Trim")
