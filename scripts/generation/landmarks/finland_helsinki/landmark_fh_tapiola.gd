class_name LandmarkFhTapiola
extends RefCounted

## Tapiola garden-city centre beside Keskustorni, true metres, extruded
## from OpenStreetMap outlines (LandmarkFhWestFootprints): Sipinen's
## Espoo Cultural Centre on the central pool (1989), Ervi's 11-storey
## Mäntytorni (1954, 31 m) and Revell's four 9-storey hip-flask houses
## (1959–61, about 30 m; white per OSM building:colour). Sources and
## estimates: docs/espoo-landmark-sources.md.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

static func _materials() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#E2E0D8", 3.0))
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#ECEAE3", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F4148"))
	lm.use("Teak", LandmarkMaterials.pbr("wood", "#7A5638", 2.0))
	lm.use("Metal", LandmarkMaterials.paint("#40474A", 0.6))
	lm.use("Roof", LandmarkMaterials.paint("#55595A", 0.8))
	return lm

## Light ceramic-panelled foyer wings with glazed ribbons, and the
## concert-hall volume rising from the middle of the plan.
static func cultural_centre(model: Node3D) -> void:
	var lm := _materials()
	var poly := W.outline("espoo_cultural_centre")
	var eave := 13.0
	lm.poly_prism("Wall", poly, 0.0, eave)
	lm.poly_prism("Glass", F.offset(poly, 0.06), 0.6, 4.4, false)
	W.ribbons(lm, "Glass", poly, 6.4, 1.6, 2, 3.4)
	W.ribs(lm, "Metal", poly, 0.6, 4.4, 4.0, 0.16, 0.18)
	lm.poly_prism("Panel", F.offset(poly, 0.3), eave, eave + 0.7)
	lm.poly_prism("Roof", F.offset(poly, -0.6), eave + 0.7, eave + 0.9)
	# Tapiolasali: the stepped hall block over the core of the plan.
	var hall := F.offset(poly, -16.0)
	if not hall.is_empty():
		lm.poly_prism("Wall", hall, eave, 19.5)
		lm.poly_prism("Panel", F.offset(hall, 0.3), 19.5, 20.2)
		lm.poly_prism("Roof", F.offset(hall, -0.8), 20.2, 21.0)
	lm.commit(model, "Kulttuurikeskus_")

## Slip-formed white point block, a French balcony at each flat window
## and the original top-floor café band.
static func mantytorni(model: Node3D) -> void:
	var lm := _materials()
	var poly := W.outline("mantytorni")
	lm.poly_prism("Wall", poly, 0.0, 30.2)
	W.edge_windows(lm, "Glass", poly, 1.2, 10, 2.8, 2.6, 1.3, 1.6, "Metal", true)
	for i in 10:
		lm.poly_prism("Metal", F.offset(poly, 0.12), 1.2 + 2.8 * float(i), 1.3 + 2.8 * float(i), false)
	W.ribbons(lm, "Glass", poly, 28.6, 1.4, 1, 1.0)
	lm.poly_prism("Wall", F.offset(poly, 0.15), 30.2, 31.0)
	lm.poly_prism("Roof", F.offset(poly, -0.5), 30.4, 30.8)
	lm.commit(model, "Mantytorni_")

## Hexagonal flask plans: horizontal white Mineriitti cladding with dark
## window bands and teak grids on the long faces, balconies set into the
## facade line, separate canopies over the sauna and terrace storey.
static func hip_flask_houses(model: Node3D) -> void:
	var lm := _materials()
	for poly in W.outlines("tapiola_hip_flask_houses"):
		lm.poly_prism("Panel", poly, 0.0, 27.0)
		W.ribbons(lm, "Glass", poly, 1.3, 1.3, 8, 3.0)
		W.ribbons(lm, "Wall", poly, 0.0, 0.25, 9, 3.0, 0.12)
		W.ribs(lm, "Teak", poly, 1.3, 25.3, 1.4, 0.08, 0.1)
		# Top storey: set back under its own canopy.
		lm.poly_prism("Glass", F.offset(poly, -1.2), 27.0, 29.4)
		lm.poly_prism("Roof", F.offset(poly, 0.6), 29.4, 30.0)
	lm.commit(model, "Taskumatti_")
