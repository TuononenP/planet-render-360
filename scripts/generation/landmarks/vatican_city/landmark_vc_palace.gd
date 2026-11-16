class_name LandmarkVcPalace
extends RefCounted

## The Apostolic Palace and the Vatican Museums' Belvedere courts in
## true metres: the palace round the Cortile di San Damaso, Sixtus V's
## Library wing across the great court, Bramante's two corridors, the
## Cortile della Pigna and its Nicchione, and the Belvedere Palace.

## Origin in the Cortile della Pigna's middle, 156 m north of the
## Cortile di San Damaso (z +84), axes along the compass (north is -Z).
## The palace is a ring of 27 m wings round the 54 x 56 m court, three
## tiers of Raphael's loggias on its west and north sides, with
## Sixtus V's 31 m wing on the east facing St Peter's Square; north of it
## the 18 m Library wing crosses between Bramante's two 21 m corridors
## (each with three arcaded tiers facing a paved court 60 m wide), which end
## at the Nicchione, a 12 m exedra under a half-dome holding the bronze
## Pigna, in front of the 20 m Belvedere Palace.
static func palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C99A6F", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C8A8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DCC3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#8A523F", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B9AE98", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6C5A3C", 2.0, 0.4, 0.7))
	_damaso(lm)
	_belvedere(lm)
	lm.commit(model)

## The palace ring: west wing with Raphael's loggias, north wing, south
## wing and the Sixtus V wing, round the Cortile di San Damaso.
static func _damaso(lm: LandmarkMesh) -> void:
	lm.box("Paving", Vector3(16, 0.1, 84), Vector3(54, 0.2, 56))
	var win := Vector2(1.6, 2.5)
	LandmarkRmLUtil.block(lm, "Wall", Vector3(-22, 0, 84), 100.0, 27.0, 22.0, Vector3(-1, 0, 0), 5, 20, win.x, win.y, "Tile", 2)
	LandmarkRmLUtil.block(lm, "Wall", Vector3(16, 0, 45), 54.0, 27.0, 22.0, Vector3(0, 0, -1), 5, 11, win.x, win.y, "Tile", 2)
	LandmarkRmLUtil.block(lm, "Wall", Vector3(16, 0, 123), 54.0, 27.0, 22.0, Vector3(0, 0, 1), 5, 11, win.x, win.y, "Tile", 2)
	LandmarkRmLUtil.block(lm, "Wall", Vector3(55, 0, 84), 100.0, 31.0, 24.0, Vector3(1, 0, 0), 7, 22, win.x, win.y, "Tile", 2)
	# Court faces of the east and south wings (plain window bands).
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3(55, 0, 84), Vector3(-1, 0, 0), 56.0, 31.0, 24.0, 7, 12, win)
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3(16, 0, 123), Vector3(0, 0, -1), 54.0, 27.0, 22.0, 5, 11, win)
	for e in [Vector3(0, 0, -1), Vector3(0, 0, 1)]:
		LandmarkVcUtil.face_windows(lm, "Wall", Vector3(55, 0, 84), e, 24.0, 31.0, 100.0, 7, 5, win)
		LandmarkVcUtil.face_windows(lm, "Wall", Vector3(-22, 0, 84), e, 22.0, 27.0, 100.0, 5, 5, win)
	# Raphael's loggias: three arcaded tiers on the west and north court faces.
	for tier in 3:
		var y := 7.0 * float(tier)
		LandmarkRmLKit.arcade(lm, "Wall", "Shadow", Vector3(-12.2, y, 112), Vector3(0, 0, -1), Vector3(1, 0, 0),
			56.0, 7.0, 11, 3.5, 3.9, 1.2)
		LandmarkRmLKit.arcade(lm, "Wall", "Shadow", Vector3(-11, y, 54.8), Vector3(1, 0, 0), Vector3(0, 0, 1),
			54.0, 7.0, 11, 3.5, 3.9, 1.2)
		lm.box("Trim", Vector3(-11.5, y + 7.0, 84), Vector3(1.5, 0.35, 56.0))
		lm.box("Trim", Vector3(16, y + 7.0, 55.5), Vector3(54.0, 0.35, 1.5))
	# Pope's apartment: the loggia of the top floor and the corner windows.
	for k in 4:
		LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(43.0, 25.0, 20.0 + 2.6 * float(k)), Vector3(0, 0, 1), Vector3(-1, 0, 0), 1.4, 2.6, 0)

## Library wing, the two corridors, the paved court, the Nicchione and
## the Belvedere Palace.
static func _belvedere(lm: LandmarkMesh) -> void:
	var win := Vector2(1.5, 2.4)
	lm.box("Paving", Vector3(0, 0.1, -26), Vector3(60, 0.2, 100))
	LandmarkRmLUtil.block(lm, "Wall", Vector3(0, 0, 24), 72.0, 18.0, 14.0, Vector3(0, 0, 1), 3, 14, win.x, win.y, "Tile")
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3(0, 0, 24), Vector3(0, 0, -1), 72.0, 18.0, 14.0, 3, 14, win)
	# Bramante's corridors, three arcaded tiers toward the court.
	LandmarkRmLUtil.block(lm, "Wall", Vector3(-36, 0, -26), 100.0, 21.0, 12.0, Vector3(-1, 0, 0), 3, 20, win.x, win.y, "Tile")
	LandmarkRmLUtil.block(lm, "Wall", Vector3(36, 0, -26), 100.0, 21.0, 12.0, Vector3(1, 0, 0), 3, 20, win.x, win.y, "Tile")
	for tier in 3:
		var y := 7.0 * float(tier)
		LandmarkRmLKit.arcade(lm, "Stone", "Shadow", Vector3(-31.0, y, 24), Vector3(0, 0, -1), Vector3(1, 0, 0),
			100.0, 7.0, 25, 3.0, 3.4, 1.0)
		LandmarkRmLKit.arcade(lm, "Stone", "Shadow", Vector3(31.0, y, -76), Vector3(0, 0, 1), Vector3(-1, 0, 0),
			100.0, 7.0, 25, 3.0, 3.4, 1.0)
		lm.box("Trim", Vector3(-30.5, y + 7.0, -26), Vector3(1.3, 0.3, 100.0))
		lm.box("Trim", Vector3(30.5, y + 7.0, -26), Vector3(1.3, 0.3, 100.0))
	# The Nicchione: a tall exedra of pilasters and statue niches under a
	# half-dome, the Pigna on its pedestal in front.
	var c := Vector3(0, 0, -76)
	var r := 12.0
	LandmarkVcUtil.half_ring(lm, "Stone", c, r, 13.0, 1.6, 18)
	LandmarkVcUtil.half_ring(lm, "Trim", c + Vector3(0, 13.0, 0), r + 0.3, 1.2, 2.4, 18)
	LandmarkVcUtil.niche_dome(lm, "Stone", c + Vector3(0, 13.6, 0), r - 0.6)
	for k in 9:
		var a := PI * (float(k) + 0.5) / 9.0
		var inward := Vector3(-cos(a), 0, sin(a))
		var p := c + Vector3(cos(a) * (r - 0.8), 0, -sin(a) * (r - 0.8))
		if k % 2 == 0:
			SEuParts.niche(lm, "Trim", "Shadow", p + Vector3(0, 1.8, 0), inward, 1.6, 4.2, SEuParts.ROUND, 0.3)
		else:
			LandmarkRmLKit.pilaster(lm, "Trim", p, Vector3.UP.cross(inward), inward, 0.9, 12.5, 0.5, true)
	lm.box("Trim", Vector3(0, 1.5, -82.0), Vector3(3.0, 3.0, 3.0))
	lm.frustum("Bronze", Vector3(0, 3.0, -82.0), 1.2, 0.3, 3.8, 10)
	SEuUtil.steps_up(lm, "Stone", Vector3(0, 0, -62.0), Vector3(0, 0, -1), 16.0, 0.6, 0.12, 4)
	# The Belvedere Palace behind the Nicchione.
	LandmarkRmLUtil.block(lm, "Wall", Vector3(0, 0, -96), 70.0, 20.0, 14.0, Vector3(0, 0, 1), 4, 14, win.x, win.y, "Tile")
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3(0, 0, -96), Vector3(0, 0, -1), 70.0, 20.0, 14.0, 4, 14, win)
