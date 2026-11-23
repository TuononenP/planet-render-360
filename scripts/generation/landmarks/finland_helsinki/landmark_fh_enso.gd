extends RefCounted

## Enso-Gutzeit headquarters (Alvar Aalto, 1962, "Sokeripala" / the Sugar
## Cube), Kanavaranta, beside Uspenski Cathedral. Model origin at the
## registry point, extruded from the OSM outline (way 23192809, 52 x 31 m,
## LandmarkFhInnerFootprints) in world axes (yaw 0).
##
## From the photos (visual-plan/refs/landmarks/enso_gutzeit_hq/): white
## Carrara marble, five storeys of square windows set deep in marble frames
## (blue glass in brown wood frames) over a recessed glazed ground floor on
## marble-clad columns, a set-back glazed top floor under a thin roof slab,
## and the blank south-east end left for an extension that never came.
##
## Measured: outline (OSM) and height (LoD2 25.1 m nearest the centre; model
## 24.0, so it no longer masks Uspenski's drum from the harbour). Estimated:
## floor pitch and the recess depths.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENSO_M := 24.0

const ENTRY := {"type": "enso_gutzeit_hq", "name": "Enso-Gutzeit Headquarters", "lat": 60.167904, "lon": 24.958537,
	"radius_m": 2500.0, "wiki_title": "Enso headquarters", "height_m": 24.0, "clear_m": 27.0,
	"kind": "Office", "aliases": ["enso-gutzeit headquarters", "enso headquarters", "enso-gutzeitin pääkonttori",
		"enso-gutzeitin toimitalo", "stora enso headquarters", "stora enson pääkonttori", "sokeripala",
		"sugar cube helsinki"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F3F2EE", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#5B7185"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6C6A66", 3.0))
	lm.use("Metal", LandmarkMaterials.paint("#6B4A32", 0.5, 0.4))
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
	var marble_warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 1.5, 29.0), Vector3(-7.0, 13.0, 13.0), 50.0, 0.9, 55.0, marble_warm],
		[Vector3(38.0, 1.5, 23.0), Vector3(23.0, 13.0, 14.0), 48.0, 0.85, 50.0, marble_warm],
		[Vector3(18.0, 1.5, -28.0), Vector3(10.0, 13.0, -10.0), 50.0, 0.85, 55.0, marble_warm],
		[Vector3(-35.0, 1.5, -24.0), Vector3(-20.0, 13.0, -15.0), 48.0, 0.85, 50.0, marble_warm],
	])

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
