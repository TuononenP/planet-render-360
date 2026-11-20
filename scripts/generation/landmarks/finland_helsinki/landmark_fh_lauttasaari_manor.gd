extends RefCounted

## Lauttasaari Manor (Lauttasaaren kartano, Drumsö gård), main building of
## 1837 in Empire style (fi.wikipedia; Koneen Saatio restored it in 2018).
## Origin at the OSM building (way 29993853, 60.159028, 24.879080, yaw 0),
## `roof:shape=hipped`, two storeys.
##
## Measured: the outline and the City LoD2 roof (13.5 m with the chimneys).
## Estimated: the 7.8 m eaves, the pale ochre render, white trim, the grey
## roof and the two chimneys. Commons photos are not yet matched against the
## model (visual-plan/refs/landmarks/lauttasaari_manor/ if present).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const ENTRY := {"type": "lauttasaari_manor", "name": "Lauttasaari Manor", "lat": 60.159028, "lon": 24.879080,
	"radius_m": 3500.0, "wiki_title": "Lauttasaari Manor", "height_m": 13.5, "clear_m": 19.0,
	"kind": "Manor", "aliases": ["lauttasaari manor", "lauttasaaren kartano", "drumsö gård"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("concrete", "#E6D9A6", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#F1EEE4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6A6A66", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Roof", LandmarkMaterials.paint("#4E5352", 0.7))
	var poly := W.outline("lauttasaari_manor")
	var eave := 7.8
	lm.poly_prism("Granite", F.offset(poly, 0.15), 0.0, 0.8)
	lm.poly_prism("Render", poly, 0.8, eave)
	lm.poly_prism("Trim", F.offset(poly, 0.12), 4.1, 4.4, false)
	lm.poly_prism("Trim", F.offset(poly, 0.2), eave - 0.5, eave)
	W.edge_windows(lm, "Glass", poly, 1.5, 2, 3.4, 2.8, 1.1, 1.8, "Trim")
	# White corner pilasters and narrow wall strips between the bays.
	W.ribs(lm, "Trim", poly, 0.8, eave - 0.5, 5.6, 0.5, 0.1)
	var main := [Vector2(5.0, -16.8), Vector2(15.9, -7.4), Vector2(1.6, 8.9), Vector2(-9.3, -0.5)]
	W.hip_rect(lm, "Roof", main[0], main[1], main[2], main[3], eave, 4.0)
	W.hip_rect(lm, "Roof", Vector2(0.3, 7.8), Vector2(-1.9, 10.3), Vector2(-9.7, 3.6),
		Vector2(-7.5, 1.1), eave, 1.8)
	# Two brick chimneys on the ridge line of the main block.
	var centre: Vector2 = (main[0] + main[1] + main[2] + main[3]) * 0.25
	var ridge: Vector2 = (main[2] - main[1]).normalized()
	for s: float in [-1.0, 1.0]:
		var c := centre + ridge * (3.2 * s)
		U.blk(lm, "Render", c.x, eave + 2.0, c.y, 0.9, 3.45, 0.9)
		U.blk(lm, "Trim", c.x, eave + 5.45, c.y, 1.1, 0.25, 1.1)
	lm.commit(model, "Lauttasaari_manor_")
