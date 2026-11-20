extends RefCounted

## Didrichsen Art Museum (Viljo Revell, villa 1957-58 and exhibition wing
## 1964), Kuusisaari shore. Origin at the OSM building (way 31984997,
## 60.185289, 24.856504, yaw 0). Glass between red-brick piers on a stone
## terrace wall, a pale floor band and a deep overhanging fascia.
##
## Measured: the outline and the City LoD2 roof (8.3 m). Estimated: the 7 m
## glass height, the pier spacing and colours; not yet matched against a
## photograph in this pass.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const DIDRICHSEN_M := 8.4

const ENTRY := {"type": "didrichsen_art_museum", "name": "Didrichsen Art Museum", "lat": 60.185289, "lon": 24.856504,
	"radius_m": 2500.0, "wiki_title": "Didrichsen Art Museum", "height_m": 8.4, "clear_m": 18.0,
	"kind": "Art museum", "aliases": ["didrichsen art museum", "didrichsenin taidemuseo",
		"didrichsens konstmuseum", "didrichsen museum"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#33423F"))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8B3B2C", 2.5))
	lm.use("Fascia", LandmarkMaterials.pbr("concrete", "#DADAD4", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C7066", 2.5))
	var poly := W.outline("didrichsen_art_museum")
	var eave := 7.0
	lm.poly_prism("Stone", F.offset(poly, 0.2), 0.0, 0.6)
	lm.poly_prism("Glass", F.offset(poly, -0.3), 0.6, eave)
	W.ribs(lm, "Brick", F.offset(poly, -0.3), 0.6, eave, 4.2, 0.9, 0.3)
	W.ribs(lm, "Fascia", F.offset(poly, -0.25), 0.6, eave, 1.4, 0.08, 0.1)
	lm.poly_prism("Fascia", poly, 3.5, 4.0, false)
	lm.poly_prism("Fascia", F.offset(poly, 0.9), eave, DIDRICHSEN_M)
	lm.commit(model, "Didrichsen_")
