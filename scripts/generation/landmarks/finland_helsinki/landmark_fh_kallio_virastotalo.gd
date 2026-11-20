extends RefCounted

## Kallio Office Building (Kallion virastotalo, Kaija and Heikki Siren, 1965),
## the City's offices at the Siltasaari bridge head. Origin at the registry
## point (OSM way 140493078), yaw 0: the outline and the 20.6 x 78 m
## north-south slab are traced from OSM in LandmarkFhInnerFootprints.
##
## From the Commons photos (visual-plan/refs/landmarks/kallio_virastotalo/):
## - An 11-storey slab clad in pale warm-grey tile (OSM building:colour
##   whitesmoke), every storey a continuous ribbon of windows over a tiled
##   spandrel, broken by thin pale mullions about every 2.4 m.
## - A blue-grey metal plant storey, set back, caps the roof.
## - Lower east-west wings round it carry a long glazed ribbon over a pale
##   fascia; a dark glass entrance pavilion stands on the granite steps.
##
## Measured: the outline and the 38.1 m LoD2 roof. Estimated: the 14.4 m wing
## height, the 3.27 m storey pitch, the 2.5 m plant storey and the colours.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const VIRASTOTALO_M := 38.5

const ENTRY := {"type": "kallio_virastotalo", "name": "Kallio Office Building", "lat": 60.181371, "lon": 24.946693,
	"radius_m": 3000.0, "wiki_title": "Kallio", "height_m": 38.5, "clear_m": 14.0,
	"clear_offsets_m": [[10.0, -24.0], [11.0, 0.0], [11.0, 22.0], [11.0, 38.0], [-40.0, -19.0],
		[-20.0, -19.0], [-5.0, -19.0], [30.0, -21.0], [45.0, -21.0], [-40.0, 31.0], [-20.0, 31.0],
		[-6.0, 31.0]],
	"kind": "Office", "aliases": ["kallio office building", "kallion virastotalo", "berghälls ämbetshus",
		"kallio municipal offices"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#DCD8CB", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2C3A42"))
	lm.use("Mull", LandmarkMaterials.pbr("concrete", "#EBE8DE", 2.0))
	lm.use("Plant", LandmarkMaterials.paint("#7E8B95", 0.5, 0.4))
	lm.use("Roof", LandmarkMaterials.paint("#55524F", 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2B0", 0.6))
	var poly := I.outline("kallio_virastotalo")
	var wing := 14.4
	lm.poly_prism("White", poly, 0.0, wing)
	W.ribbons(lm, "Glass", poly, 1.2, 1.7, 4, 3.4)
	W.ribs(lm, "Mull", poly, 1.0, wing - 0.4, 2.4, 0.12, 0.1)
	lm.poly_prism("White", F.offset(poly, 0.15), wing - 0.4, wing, false)
	lm.poly_prism("Roof", F.offset(poly, -0.2), wing, wing + 0.1)
	var tower := PackedVector2Array([Vector2(-1.9, -31.7), Vector2(18.7, -32.5), Vector2(22.0, 45.8), Vector2(1.2, 46.6)])
	var top := 36.0
	lm.poly_prism("White", tower, 0.0, top)
	W.ribbons(lm, "Glass", tower, 1.2, 1.75, 11, 3.27)
	W.ribs(lm, "Mull", tower, 1.0, top - 0.6, 2.4, 0.12, 0.12)
	# Every second floor lit at night, a thin band behind the ribbon glass.
	for r in range(1, 11, 2):
		lm.poly_prism("Lamp", F.offset(tower, 0.09), 1.3 + 3.27 * float(r), 1.4 + 3.27 * float(r) + 1.5, false)
	lm.poly_prism("Roof", F.offset(tower, -0.2), top, top + 0.2)
	lm.poly_prism("Plant", F.offset(tower, -2.5), top, VIRASTOTALO_M)
	lm.commit(model, "Kallio_virastotalo_")
