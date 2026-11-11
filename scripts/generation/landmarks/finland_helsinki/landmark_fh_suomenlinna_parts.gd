class_name LandmarkFhSuomenlinnaParts
extends RefCounted

## Suomenlinna composite components, true metres: the fortress is five
## islands, so its named sites are separate models at their own ground
## (the church remains the suomenlinna_fortress anchor). Bastion fabric
## between them stays with the mapped-OSM SuomenlinnaFortress system.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

static func _mats() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A867E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8E2D2", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D8C9A8", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#4E5A54", 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Water", LandmarkMaterials.glass("#3E6B74"))
	return lm

## King's Gate (Kuninkaanportti, 1754): classical stone gate recessed in
## the waterfront bastion, curved steps down to the water.
static func kings_gate(model: Node3D) -> void:
	var lm := _mats()
	# Grass-topped bastion cheeks flank the gate (stone faces here).
	U.blk(lm, "Stone", -13.0, 0, 0, 14.0, 7.0, 10.0)
	U.blk(lm, "Stone", 13.0, 0, 0, 14.0, 7.0, 10.0)
	U.blk(lm, "Stone", 0, 0, -2.0, 12.0, 9.0, 8.0)
	U.blk(lm, "Trim", 0, 9.0, -2.0, 13.0, 0.7, 9.0)
	# Gate surround, pediment and the dark arched passage.
	U.blk(lm, "Trim", 0, 0, 2.2, 7.0, 10.6, 1.2)
	FhP.pierce(lm, "Trim", "Glass", Vector3(-3.4, 0, 2.85), Vector3(3.4, 0, 2.85), Vector3(0, 0, 1),
		0.0, 7.5, 1, 1, Vector2(3.4, 5.5), 3.4, 5.5, 0.2)
	lm.gable("Trim", Vector3(0, 10.6, 2.2), 8.0, 1.6, 1.4, Basis(), 0.1, "Trim")
	U.steps(lm, "Stone", Vector3(0, 0, 3.2), Vector3(0, 0, 1), 9.0, 0.55, 0.22, 6)
	lm.commit(model)

## The old dry dock on Susisaari: stone basin rim, water at the dock
## floor, gate end and a small crane mast.
static func dry_dock(model: Node3D) -> void:
	var lm := _mats()
	U.blk(lm, "Stone", -19.0, 0, 0, 6.0, 3.2, 62.0)
	U.blk(lm, "Stone", 19.0, 0, 0, 6.0, 3.2, 62.0)
	U.blk(lm, "Stone", 0, 0, -31.0, 44.0, 3.2, 6.0)
	U.blk(lm, "Water", 0, 0.7, 2.0, 32.0, 0.15, 58.0)
	# Keel blocks and a berthed hull silhouette in the basin.
	for i in 6:
		U.blk(lm, "Stone", 0, 0.85, -22.0 + float(i) * 9.0, 8.0, 0.7, 2.0)
	U.blk(lm, "Roof", 0, 1.55, 0, 7.0, 1.6, 42.0)
	U.blk(lm, "Trim", 0, 3.15, 0, 5.0, 1.2, 30.0)
	# Crane mast at the dock head closes at the registered height.
	U.blk(lm, "Stone", -19.0, 3.2, -28.0, 1.0, 4.8, 1.0)
	lm.beam("Trim", Vector3(-19.0, 8.0, -28.0), Vector3(-8.0, 6.4, -20.0), 0.18)
	lm.commit(model)

## Jetty Barracks (Rantakasarmi): the long rendered barracks at the main
## pier, gabled roof and even window rhythm.
static func jetty_barracks(model: Node3D) -> void:
	var lm := _mats()
	U.blk(lm, "Stone", 0, 0, 0, 62.0, 1.0, 15.0)
	U.blk(lm, "Wall", 0, 1.0, 0, 62.0, 8.5, 14.0)
	U.ridge_x(lm, "Roof", "Wall", Vector3(0, 9.5, 0), 63.0, 15.0, 4.5)
	U.box_windows(lm, "Glass", 0, 0, 62.0, 14.0, 2.2, 2, 3.4, 13, 3, 1.3, 2.2)
	U.blk(lm, "Trim", 0, 1.0, 7.2, 6.0, 5.5, 1.4)
	# Chimneys, dormers and shutters break up the long roof and walls.
	for x in [-24.0, -8.0, 8.0, 24.0]:
		U.blk(lm, "Stone", x, 11.4, 0, 1.1, 2.2, 1.1)
		U.blk(lm, "Wall", x * 0.6, 9.5, 3.4, 2.0, 1.5, 0.3)
		U.blk(lm, "Wall", x * 0.6, 9.5, -3.4, 2.0, 1.5, 0.3)
	for x in [-27.0, -18.0, 18.0, 27.0]:
		U.blk(lm, "Trim", x, 0, 7.6, 0.16, 2.6, 0.16)
		lm.lathe("Glass", Vector3(x, 2.6, 7.6), U.ball(0.22), 8)
	lm.commit(model)
