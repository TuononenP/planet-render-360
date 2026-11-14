class_name LandmarkFhLauttasaari
extends RefCounted

## Lauttasaari, true metres, extruded from OpenStreetMap outlines
## (LandmarkFhWestFootprints): the Petäjäs' cast-concrete church halls
## round the churchyard (1958) with the tall narrow cross-crowned bell
## tower in its middle (OSM way 404164145, 61 m), and the 1837 Empire
## main building of Lauttasaari Manor under its hipped roof. Colours
## other than the concrete are estimates; see
## docs/helsinki-landmark-sources.md.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

## Bell tower centre about the church entry (OSM way 404164145).
const TOWER := Vector2(7.8, -4.8)
const TOWER_M := 61.0

static func church(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFCBC0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3B40"))
	lm.use("Roof", LandmarkMaterials.paint("#4A4E4E", 0.8))
	lm.use("Metal", LandmarkMaterials.paint("#2F3335", 0.5))
	var poly := W.outline("lauttasaari_church")
	var eave := 8.5
	lm.poly_prism("Concrete", poly, 0.0, eave)
	# Low glazed entrances and the high clerestory strip of the halls.
	lm.poly_prism("Glass", F.offset(poly, 0.06), 0.4, 2.8, false)
	lm.poly_prism("Glass", F.offset(poly, 0.06), 5.6, 7.4, false)
	W.ribs(lm, "Concrete", poly, 0.0, eave, 3.2, 0.5, 0.25)
	lm.poly_prism("Concrete", F.offset(poly, 0.4), eave, eave + 0.6)
	lm.poly_prism("Roof", F.offset(poly, -0.4), eave + 0.6, eave + 0.8)
	# Tall narrow tower: slit sound openings below the cap, then the cross.
	var shaft := 54.0
	U.blk(lm, "Concrete", TOWER.x, 0.0, TOWER.y, 5.0, shaft, 4.4)
	for s in [-1.0, 1.0]:
		for k in 3:
			var off := (float(k) - 1.0) * 1.3
			U.blk(lm, "Metal", TOWER.x + off, 44.0, TOWER.y + s * 2.22, 0.45, 8.0, 0.06)
			U.blk(lm, "Metal", TOWER.x + s * 2.52, 44.0, TOWER.y + off, 0.06, 8.0, 0.45)
	U.blk(lm, "Concrete", TOWER.x, shaft, TOWER.y, 5.4, 0.5, 4.8)
	U.blk(lm, "Metal", TOWER.x, shaft + 0.5, TOWER.y, 0.35, TOWER_M - shaft - 0.5, 0.35)
	U.blk(lm, "Metal", TOWER.x, TOWER_M - 2.4, TOWER.y, 2.6, 0.35, 0.35)
	lm.commit(model, "Lauttasaari_church_")

## Two plastered storeys with a granite plinth, white trim and a hipped
## roof over the main block and the projecting porch wing.
static func manor(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("concrete", "#E2CD98", 2.0))
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
		U.blk(lm, "Render", c.x, eave + 2.0, c.y, 0.9, 2.45, 0.9)
		U.blk(lm, "Trim", c.x, eave + 4.45, c.y, 1.1, 0.25, 1.1)
	lm.commit(model, "Lauttasaari_manor_")
