extends RefCounted

## Finnish National Theatre (Onni Tarjanne, 1902), Rautatientori, built on
## its OpenStreetMap outline (way 122595207, simplified to 0.6 m, recentred
## on its bounding box and turned by the entry's yaw so the long walls run
## along X and Z; the 31 m front faces +Z, onto the station square).
##
## From the Commons photos in visual-plan/refs/landmarks/finnish_national_theatre/:
## - The National Romantic walls are rock-faced grey granite on a red
##   granite base, under steep red clay-tile roofs.
## - The front has a central gabled pavilion: three round-arched doors up a
##   broad stair, a first-floor loggia of five round arches on short
##   columns over three small balconies, and tall windows with a round
##   window in the gable above, stepping up to a finial.
## - Two square towers with arched belfry windows stand at the front
##   corners, each under a steep pointed red tile pyramid.
## - Behind the front block the stage house is higher, under a green copper
##   roof, with a tall red brick chimney at the back.
## - Aleksis Kivi's bronze statue stands in the square on a granite
##   pedestal, with two granite lamp piers at the stair.
##
## Measured: the outline (OSM), the 38 m top (LoD2: the chimney) and, from the
## straight-on photo scaled by the 31 m front, the 16 m eave, 23 m gable peak,
## 24 m tower tops and the arcade and door spacing. Estimated: the stage
## house height (24 m), the window counts on the flanks.

const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "finnish_national_theatre", "name": "Finnish National Theatre", "lat": 60.172465, "lon": 24.943834,
	"radius_m": 1500.0, "wiki_title": "Finnish National Theatre", "height_m": 38.0, "clear_m": 62.0,
	"yaw_deg": -3.1, "kind": "Theatre",
	"aliases": ["finnish national theatre", "suomen kansallisteatteri", "finlands nationalteater"]}

const OUTLINE := [-19.0, 43.7, -19.0, 32.2, -15.9, 32.2, -15.8, 12.2, -19.0, 12.2, -18.4, -16.9, -12.8, -16.9,
	-12.7, -30.9, -18.9, -30.9, -18.9, -48.8, 19.0, -48.7, 19.0, -28.4, 13.0, -28.5, 13.0, -17.1, 19.0, -17.1,
	18.9, 12.4, 16.1, 12.4, 16.0, 32.2, 18.8, 32.2, 18.8, 43.6, 15.5, 43.6, 15.5, 48.8, -15.7, 48.8, -15.6, 43.7]

const ZF := 48.8
const EAVE := 16.0
const STAGE := 24.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#85857F", 2.5))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#76504A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#A9A89F", 2.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#8C3E3A", 2.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9A88", 2.0, 0.5, 0.3))
	lm.use("Window", LandmarkMaterials.paint("#4A5A64", 0.3, 0.3))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3020", 2.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4A38", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#4C5A4A", 0.5, 0.4))
	lm.use("Lamp", LandmarkMaterials.lit("#F0E6C8", 0.5))
	var poly := PackedVector2Array()
	for i in range(0, OUTLINE.size() - 1, 2):
		poly.append(Vector2(float(OUTLINE[i]), float(OUTLINE[i + 1])))
	lm.poly_prism("Stone", poly, 0.0, EAVE)
	lm.poly_prism("Base", F.offset(poly, 0.35), 0.0, 1.6)
	lm.poly_prism("Trim", F.offset(poly, 0.3), EAVE - 0.6, EAVE)
	# Tall round-headed-style windows in rows on every wall (towers, wings, flanks).
	W.edge_windows(lm, "Window", poly, 4.2, 2, 5.4, 4.4, 1.3, 2.8, "Trim")
	# Front block roof: steep hip of red tile, the stage house higher behind.
	FhU.hip(lm, "Tile", Vector3(0.0, EAVE, 15.9), 33.0, 66.0, 5.5, 0.2)
	FhU.blk(lm, "Stone", 0.0, EAVE, -39.0, 37.6, STAGE - EAVE, 19.6)
	FhU.hip(lm, "Copper", Vector3(0.0, STAGE, -39.0), 39.0, 21.0, 5.0, 0.3)
	FhU.blk(lm, "Stone", 0.0, EAVE, -22.0, 25.6, 5.0, 12.0)
	FhU.hip(lm, "Copper", Vector3(0.0, EAVE + 5.0, -22.0), 27.0, 13.5, 3.0, 0.3)
	W.edge_windows(lm, "Window", F.offset(PackedVector2Array([Vector2(-18.8, -48.7), Vector2(18.8, -48.7),
		Vector2(18.8, -29.0), Vector2(-18.8, -29.0)]), 0.0), EAVE + 2.0, 1, 4.0, 5.0, 1.3, 2.6, "Trim")
	# Red brick chimney at the back to the LoD2 top.
	lm.frustum("Brick", Vector3(-11.0, STAGE, -43.0), 1.5, 1.1, 38.0 - STAGE, 10)
	lm.frustum("Trim", Vector3(-11.0, 37.6, -43.0), 1.3, 1.3, 0.4, 10)
	# Two corner towers: a square shaft rising a little above the eave to a
	# copper-green cornice, one big round-headed window and a steep bell-shaped
	# red pyramid. Triple tall slits and ornament plates in the front wall.
	for s in [-1.0, 1.0]:
		var tx: float = s * 12.7
		FhU.blk(lm, "Stone", tx, EAVE, ZF - 3.0, 5.8, 3.4, 6.0)
		FhU.blk(lm, "Copper", tx, EAVE + 3.4, ZF - 3.0, 6.3, 0.4, 6.5)
		FhU.hip(lm, "Tile", Vector3(tx, EAVE + 3.8, ZF - 3.0), 6.4, 6.6, 4.8, 0.0)
		lm.frustum("Copper", Vector3(tx, EAVE + 8.6, ZF - 3.0), 0.12, 0.04, 0.9, 6)
		FhU.opening(lm, "Window", Vector3(tx, EAVE - 0.8, ZF + 0.03), Vector3(0, 0, 1), 2.4, 3.2, true)
		for k in 3:
			FhU.opening(lm, "Window", Vector3(tx + (float(k) - 1.0) * 1.5, 6.8, ZF + 0.03), Vector3(0, 0, 1), 0.7, 5.2, false)
			FhU.opening(lm, "Window", Vector3(tx + (float(k) - 1.0) * 1.5, 12.4, ZF + 0.03), Vector3(0, 0, 1), 0.6, 2.6, true)
		for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			FhU.opening(lm, "Window", Vector3(tx, EAVE - 0.8, ZF - 3.0) + d * 2.93, d, 2.0, 3.0, true)
	# Central front pavilion: arcade, doors, stair, gable.
	FhU.blk(lm, "Base", 0.0, 0.0, ZF + 0.2, 31.8, 0.7, 1.0)
	for k in 3:
		var px := (float(k) - 1.0) * 4.5
		lm.box("Door", Vector3(px, 1.9, ZF + 0.05), Vector3(2.0, 3.6, 0.12))
		FhU.opening(lm, "Window", Vector3(px, 3.7, ZF + 0.06), Vector3(0, 0, 1), 2.0, 1.1, true)
		lm.box("Trim", Vector3(px, 4.1, ZF + 0.25), Vector3(3.8, 0.35, 0.4))
		lm.box("Trim", Vector3(px - 1.8, 2.2, ZF + 0.2), Vector3(0.35, 4.3, 0.35))
		lm.box("Trim", Vector3(px + 1.8, 2.2, ZF + 0.2), Vector3(0.35, 4.3, 0.35))
		# Semicircular iron balconies over the doors.
		lm.box("Bronze", Vector3(px, 6.55, ZF + 0.6), Vector3(2.6, 0.35, 1.0))
	for k in 5:
		var px := (float(k) - 2.0) * 2.2
		FhU.opening(lm, "Window", Vector3(px, 7.0, ZF + 0.12), Vector3(0, 0, 1), 1.9, 3.8, true)
	for k in 6:
		lm.frustum("Trim", Vector3((float(k) - 2.5) * 2.2, 6.8, ZF + 0.3), 0.18, 0.16, 3.0, 8)
	for s in [-1.0, 1.0]:
		for k in 3:
			var px: float = s * (6.8 + 2.0 * float(k)) * (1.0 if k < 2 else 1.0)
			lm.disc("Window", Vector3(px, 13.2, ZF + 0.08), Vector3(0, 0, 1), 0.55, 12)
	FhU.steps(lm, "Base", Vector3(0.0, 0.0, ZF + 0.7), Vector3(0, 0, 1), 15.0, 0.6, 0.14, 5)
	FhU.ridge_z(lm, "Tile", "Stone", Vector3(0.0, EAVE, ZF - 3.0), 10.0, 6.0, 7.2, 0.0)
	FhU.opening(lm, "Window", Vector3(0.0, 9.6, ZF + 0.1), Vector3(0, 0, 1), 1.0, 5.0, true)
	FhU.opening(lm, "Window", Vector3(-1.5, 10.6, ZF + 0.1), Vector3(0, 0, 1), 0.7, 3.4, true)
	FhU.opening(lm, "Window", Vector3(1.5, 10.6, ZF + 0.1), Vector3(0, 0, 1), 0.7, 3.4, true)
	for k in 6:
		lm.box("Window", Vector3((float(k) - 2.5) * 0.9, 17.7, ZF + 0.02), Vector3(0.45, 1.2, 0.05))
	lm.box("Trim", Vector3(0.0, 15.6, ZF + 0.25), Vector3(7.0, 0.5, 0.6))
	lm.frustum("Trim", Vector3(0.0, EAVE + 7.0, ZF - 1.0), 0.3, 0.1, 2.6, 6)
	# Stone balustrade along the front eave between the towers and the gable.
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(s * 8.0, EAVE + 0.6, ZF - 0.1), Vector3(5.4, 1.1, 0.5))
	# Granite lamp piers at the stair and Wäinö Aaltonen's brooding seated Aleksis Kivi memorial (1939).
	for s in [-1.0, 1.0]:
		lm.box("Base", Vector3(s * 8.7, 2.1, ZF + 1.6), Vector3(1.8, 4.2, 1.8))
		lm.frustum("Lamp", Vector3(s * 8.7, 4.2, ZF + 1.6), 0.34, 0.2, 1.0, 8)
	var kz := ZF + 17.0
	lm.box("Base", Vector3(0.0, 0.16, kz), Vector3(4.6, 0.32, 4.8))
	lm.box("Trim", Vector3(0.0, 1.25, kz), Vector3(2.7, 1.86, 3.1))
	lm.box("Trim", Vector3(0.0, 2.28, kz), Vector3(2.95, 0.24, 3.35))
	SculptureKit.stamp_path(lm, "Bronze", "res://assets/landmarks/helsinki_3d/aleksis_kivi_seated.glb",
		Vector3(0.0, 2.40, kz), Vector3.ONE, 0.0)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 2.5, ZF + 22.0), Vector3(-6.0, 9.0, ZF), 40.0, 0.9, 50.0, warm],
		[Vector3(12.0, 2.5, ZF + 22.0), Vector3(6.0, 9.0, ZF), 40.0, 0.9, 50.0, warm],
		[Vector3(0.0, 2.5, ZF + 22.0), Vector3(12.7, 20.0, ZF - 3.0), 25.0, 0.9, 60.0, warm],
	])
