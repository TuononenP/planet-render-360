extends RefCounted

## Studio Aalto (Alvar Aalto's studio, Tiilimaki 20, 1955). Origin at the OSM
## building (way 27705480, 60.198187, 24.869493, yaw 0): white-painted brick
## round a fan-shaped courtyard, the tall studio wing along the long outer
## side lit by clerestory glazing between white fins.
##
## Measured: the outline; the City LoD2 gives 9.6 m (the wing's roofs), so
## the wing now rises to 9.2 m. Estimated: the 4.2 m low wing, the fin spacing
## and the colours.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const STUDIO_M := 9.2

const ENTRY := {"type": "studio_aalto", "name": "Studio Aalto", "lat": 60.198187, "lon": 24.869493,
	"radius_m": 2000.0, "wiki_title": "Studio Aalto", "height_m": 9.2, "clear_m": 12.0,
	"kind": "Studio", "aliases": ["studio aalto", "alvar aalto studio", "alvar aallon ateljee",
		"aalto atelier", "tiilimäki 20"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EFEEEA", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Roof", LandmarkMaterials.paint("#4E5050", 0.8))
	var poly := W.outline("studio_aalto")
	var low := 4.2
	lm.poly_prism("White", poly, 0.0, low)
	W.edge_windows(lm, "Glass", poly, 1.0, 1, 0.0, 2.4, 1.6, 1.6, "White")
	lm.poly_prism("Roof", F.offset(poly, -0.2), low, low + 0.1)
	var a := Vector2(-16.2, 8.2)
	var b := Vector2(-3.7, -13.8)
	var inward := -W.outward(poly, a, b)
	var wing := PackedVector2Array([a, b, b + inward * 6.5, a + inward * 6.5])
	lm.poly_prism("White", wing, 0.0, STUDIO_M - 2.4)
	lm.poly_prism("Glass", F.offset(wing, 0.02), STUDIO_M - 2.4, STUDIO_M - 0.4, false)
	W.ribs(lm, "White", wing, STUDIO_M - 2.4, STUDIO_M - 0.4, 0.9, 0.25, 0.3)
	lm.poly_prism("White", F.offset(wing, 0.15), STUDIO_M - 0.4, STUDIO_M)
	lm.commit(model, "Studio_aalto_")
