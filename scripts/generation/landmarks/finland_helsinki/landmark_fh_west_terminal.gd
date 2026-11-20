extends RefCounted

## West Terminal 2 (Länsiterminaali 2, Helsinki Port, 2017), the Tallink and
## Silja terminal on Jätkäsaari. Origin at the registry point (OSM way
## 457955056), yaw 0; the outline is in LandmarkFhInnerFootprints.
##
## From the Commons photos (visual-plan/refs/landmarks/west_terminal_2/):
## - A long, faceted glass hall: dark teal reflective glass in a rhythm of
##   slim vertical fins, a timber-clad base at the entrance, and a thin
##   silver-grey metal roof plate that overhangs the glass by several
##   metres on the quay side and slopes up over the raised central hall.
## - Elevated glazed gangways run off the hall to the ships.
##
## Measured: the outline and the 23.4 m LoD2 ridge (area 7025 m2, "complex"
## roof 9.4 m, so the eaves are about 14 m). Estimated: the 14 m eaves, the
## 4 m overhang, the 2.2 m timber base, the raised hall inset and all
## colours. The gangways are not modelled.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENTRY := {"type": "west_terminal_2", "name": "West Terminal 2", "lat": 60.149594, "lon": 24.914487,
	"radius_m": 2500.0, "wiki_title": "West Harbour, Helsinki", "height_m": 23.4, "clear_m": 16.0,
	"clear_offsets_m": [[-29.0, 10.0], [9.0, 30.0], [15.0, -30.0], [29.0, -54.0], [-13.0, 20.0],
		[-47.0, 8.0], [17.0, 44.0], [13.0, 0.0], [-9.0, -12.0], [15.0, 30.0], [21.0, -48.0],
		[19.0, -18.0], [-23.0, -6.0]],
	"kind": "Ferry terminal", "aliases": ["west terminal 2", "länsiterminaali 2", "västra terminalen 2",
		"west harbour terminal", "tallink terminal helsinki"]}

const TOP_M := 23.4
const EAVE := 14.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.paint("#3E7C78", 0.2, 0.5))
	lm.use("Fin", LandmarkMaterials.paint("#2A3033", 0.5, 0.5))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#9B7B58", 1.5))
	lm.use("Roof", LandmarkMaterials.paint("#B7C0C6", 0.4, 0.6))
	lm.use("Edge", LandmarkMaterials.paint("#D6DCE0", 0.4, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE7B8", 0.8))
	var poly := I.outline("west_terminal_2")
	lm.poly_prism("Glass", F.offset(poly, -0.3), 0.0, EAVE)
	lm.poly_prism("Timber", F.offset(poly, -0.1), 0.0, 2.2, false)
	W.ribs(lm, "Fin", poly, 2.2, EAVE, 1.8, 0.16, 0.3)
	# Transoms every 3.5 m.
	for k in 3:
		lm.poly_prism("Fin", F.offset(poly, 0.02), 2.2 + 3.7 * float(k + 1), 2.34 + 3.7 * float(k + 1), false)
	# Overhanging roof plate with its thick edge, lit underneath at night.
	lm.poly_prism("Roof", F.offset(poly, 4.0), EAVE, EAVE + 0.9)
	lm.poly_prism("Edge", F.offset(poly, 4.05), EAVE + 0.5, EAVE + 1.0, false)
	lm.poly_prism("Lamp", F.offset(poly, 3.6), EAVE - 0.08, EAVE - 0.02, false)
	# Raised central hall.
	var hall := F.offset(poly, -9.0)
	if hall.size() >= 3:
		lm.poly_prism("Glass", hall, EAVE + 0.9, TOP_M - 2.2, false)
		W.ribs(lm, "Fin", hall, EAVE + 0.9, TOP_M - 2.2, 1.8, 0.16, 0.3)
		lm.poly_prism("Roof", F.offset(hall, 2.2), TOP_M - 2.2, TOP_M - 1.1)
		lm.poly_prism("Edge", F.offset(hall, 2.25), TOP_M - 1.6, TOP_M, true)
	lm.commit(model, "West_terminal_2_")
