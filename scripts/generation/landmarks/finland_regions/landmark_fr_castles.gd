class_name LandmarkFrCastles
extends RefCounted

## Three medieval castles of Finland in true metres, in the frame of the
## real plan (+X east, +Z south, turned onto the map by yaw_deg): Hame
## Castle on Lake Vanajavesi, Olavinlinna on its rock in Savonlinna and
## Kastelholm on Aland. Plans follow the OpenStreetMap footprints.

## Storeyed castle wing: grey stone base to `stone_h`, upper storeys in
## `wall`, then a gabled roof (ridge along X when ridge_x = 1, Z when 0).
static func _wing(lm: LandmarkMesh, wall: String, roof: String, x0: float, x1: float, z0: float,
		z1: float, y0: float, stone_h: float, eave: float, rise: float, ridge_x: int,
		over: float = 0.5) -> void:
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, y0, stone_h)
	LandmarkFrKit.rect(lm, wall, x0, x1, z0, z1, stone_h, eave)
	LandmarkFrKit.gable(lm, roof, x0, x1, z0, z1, eave, rise, over, wall, ridge_x)

## Hame Castle (Hameen linna), Hameenlinna, begun in the 1260s-1300s: the
## granite castle later raised in red brick, a four-wing keep round a small
## yard (37 x 30 m) with steep roofs, inside a crenellated curtain wall with
## the gatehouse, the octagonal brick corner turret and the round gun
## turret, on the shore of Lake Vanajavesi.
const HAME_TOP := 28.0

static func hame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8D8A83", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4A36", 2.5))
	lm.use("Roof", LandmarkFrKit.shingle("#5A4A42"))
	lm.use("RoofRed", LandmarkMaterials.pbr("terracotta", "#8C4634", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E3DDCC", 3.0))
	# Keep: four wings round the yard (x -18.6..18.6, z -15.3..15.3).
	_wing(lm, "Brick", "Roof", -13.3, 18.4, -15.3, -7.0, 0.0, 7.5, 15.5, 4.6, 1)
	_wing(lm, "Brick", "Roof", -13.6, 18.6, 3.9, 15.3, 0.0, 7.5, 15.5, 5.6, 1)
	_wing(lm, "Brick", "Roof", 8.6, 18.6, -7.0, 3.9, 0.0, 7.5, 15.5, 5.0, 0)
	_wing(lm, "Brick", "Roof", -13.3, -3.5, -7.0, 3.9, 0.0, 7.5, 15.5, 5.0, 0)
	_wing(lm, "Brick", "Roof", -18.6, -13.3, -1.9, 10.1, 0.0, 7.5, 13.0, 4.0, 0)
	LandmarkFrKit.rect(lm, "Stone", -3.5, 8.6, -7.0, 3.9, 0.0, 0.4)
	# Gabled stair tower on the south front and a clock-less brick gable.
	LandmarkFrKit.tower(lm, "Brick", "RoofRed", 2.0, 15.0, 2.6, 0.0, 19.0, 6.0, 0.3)
	# Octagonal brick corner turret of the keep and the round gun turret.
	lm.frustum("Stone", Vector3(18.6, 0, -15.3), 3.5, 3.3, 8.0, 8, PI / 8.0)
	lm.frustum("Brick", Vector3(18.6, 8.0, -15.3), 3.3, 3.2, 14.0, 8, PI / 8.0)
	lm.lathe("RoofRed", Vector3(18.6, 22.0, -15.3), PackedVector2Array([Vector2(3.9, 0), Vector2(0.15, 6.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -30.0, 29.0, 6.5, 0.0, 12.0, 4.0, 18)
	# Curtain wall with merlons and the gatehouse on the south side.
	var wall := PackedVector2Array([Vector2(-32, -30), Vector2(34, -30), Vector2(34, 31), Vector2(-32, 31)])
	LandmarkFrKit.curtain(lm, "Stone", wall, 0.0, 8.0, 2.4, "Stone")
	LandmarkFrKit.house(lm, "Brick", "Roof", -7.0, 1.0, 27.5, 34.5, 0.0, 10.0, 4.0, 0.5, 0)
	lm.box("Glass", Vector3(-3.0, 3.0, 34.55), Vector3(3.0, 5.0, 0.15))
	# Windows on the keep fronts.
	for z in [-15.35, 15.35]:
		var sgn := -1.0 if z < 0.0 else 1.0
		LandmarkFrKit.windows(lm, "Glass", Vector3(2.5, 12.0, z + sgn * 0.02), Vector3.RIGHT, 7, 4.4,
			Vector3(1.1, 2.2, 0.2))
		LandmarkFrKit.windows(lm, "Glass", Vector3(2.5, 4.5, z + sgn * 0.02), Vector3.RIGHT, 5, 6.0,
			Vector3(0.6, 1.4, 0.2))
	lm.commit(model)

## Olavinlinna (St Olaf's Castle), Savonlinna, 1475: the first Swedish castle
## with round cannon-proof towers, three of them (St Olaf's, the Bell Tower
## and the Keep Tower) at the corners of the keep with their green conical
## roofs, the grey granite palace wing between them, and the outer bailey
## on the east with its curtain wall, the ruined Thick Tower and the
## smaller towers, all on a rock island in Lake Haapavesi (y = 0 at the
## water; the rock and foundations reach below it).
const OLAVI_TOP := 38.0

static func olavinlinna(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8B84", 3.5))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#6F6A62", 4.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C9C2B0", 3.0))
	lm.use("Roof", LandmarkFrKit.copper("#5E8F7C"))
	lm.use("RoofDark", LandmarkFrKit.shingle("#5B4D44"))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	var island := PackedVector2Array([Vector2(-80, -34), Vector2(-74, -24), Vector2(-72, -8), Vector2(-74, 16),
		Vector2(-47, 16), Vector2(-30, 14), Vector2(-12, 18), Vector2(-4, 40), Vector2(14, 33), Vector2(30, 21),
		Vector2(42, 28), Vector2(63, 22), Vector2(80, 10), Vector2(81, -6), Vector2(70, -36), Vector2(56, -39),
		Vector2(48, -44), Vector2(40, -39), Vector2(-14, -37), Vector2(-26, -39), Vector2(-46, -39),
		Vector2(-58, -37), Vector2(-76, -44)])
	lm.poly_prism("Rock", island, -10.0, 3.0)
	var g := 3.0
	# Keep: palace wings round the courtyard (x -56..-8, z -34..4).
	_wing(lm, "Wall", "RoofDark", -56.0, -8.0, -34.0, -27.0, g, g + 5.0, 21.0, 5.0, 1)
	_wing(lm, "Wall", "RoofDark", -56.0, -8.0, -3.0, 4.0, g, g + 5.0, 21.0, 5.0, 1)
	_wing(lm, "Wall", "RoofDark", -56.0, -49.0, -27.0, -3.0, g, g + 5.0, 21.0, 5.0, 0)
	_wing(lm, "Wall", "RoofDark", -15.0, -8.0, -27.0, -3.0, g, g + 5.0, 21.0, 5.0, 0)
	LandmarkFrKit.rect(lm, "Stone", -49.0, -15.0, -27.0, -3.0, g, g + 0.4)
	# The three round towers with their conical roofs, and a fourth stump.
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -56.0, -34.0, 7.2, g, 30.0, 8.0, 20)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -8.0, -34.0, 6.4, g, 27.0, 7.0, 20)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -8.0, 4.0, 6.6, g, 25.0, 7.0, 20)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -56.0, 4.0, 4.6, g, 16.0, 5.0, 14)
	# Outer bailey: curtain wall, towers and a long house.
	var ward := PackedVector2Array([Vector2(-6, -36), Vector2(70, -36), Vector2(78, -6), Vector2(66, 8),
		Vector2(26, 10), Vector2(-6, 6)])
	LandmarkFrKit.curtain(lm, "Stone", ward, g, 9.0, 2.6, "Stone")
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", 48.0, -38.0, 8.0, g, 17.0, 0.0, 20)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", 70.0, -34.0, 5.2, g, 16.0, 6.0, 16)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", 70.0, 8.0, 5.0, g, 15.0, 6.0, 16)
	LandmarkFrKit.house(lm, "Wall", "RoofDark", 8.0, 56.0, -30.0, -20.0, g, g + 5.5, 4.0, 0.5, 1)
	LandmarkFrKit.house(lm, "Wall", "RoofDark", 20.0, 50.0, -4.0, 4.0, g, g + 4.5, 3.2, 0.5, 1)
	# Windows on the palace fronts.
	for z in [-34.05, 4.05]:
		var sgn := -1.0 if z < 0.0 else 1.0
		LandmarkFrKit.windows(lm, "Glass", Vector3(-32.0, g + 11.0, z + sgn * 0.02), Vector3.RIGHT, 8, 4.8,
			Vector3(1.2, 2.4, 0.2))
	lm.commit(model)

## Kastelholm Castle, Sund, Aland, late 14th century: the main castle
## (about 30 x 20 m, three storeys with stone below and plastered storeys
## and a steep roof above, round a small yard), the lower outer bailey
## with its wings and corner towers, and between them the high Kuuri
## tower, the gate towers merged into one donjon. Built on what was an
## island in the fjord.
const KASTEL_TOP := 30.0

static func kastelholm(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8C85", 3.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C8C2B3", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8A4D3A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	# Main castle (x 3..43, z -7..16): wings round a yard.
	_wing(lm, "Wall", "Roof", 3.0, 43.0, -7.0, 0.0, 0.0, 5.0, 12.0, 5.0, 1)
	_wing(lm, "Wall", "Roof", 3.0, 43.0, 9.0, 16.0, 0.0, 5.0, 12.0, 5.0, 1)
	_wing(lm, "Wall", "Roof", 3.0, 11.0, 0.0, 9.0, 0.0, 5.0, 12.0, 5.0, 0)
	_wing(lm, "Wall", "Roof", 35.0, 43.0, 0.0, 9.0, 0.0, 5.0, 12.0, 5.0, 0)
	LandmarkFrKit.rect(lm, "Stone", 11.0, 35.0, 0.0, 9.0, 0.0, 0.3)
	# Outer bailey (x -45..-2, z -10..12): low wings, wall and corner towers.
	_wing(lm, "Wall", "Roof", -45.0, -2.0, -10.0, -4.0, 0.0, 3.5, 7.5, 3.4, 1)
	_wing(lm, "Wall", "Roof", -45.0, -2.0, 6.0, 12.0, 0.0, 3.5, 7.5, 3.4, 1)
	_wing(lm, "Wall", "Roof", -45.0, -38.0, -4.0, 6.0, 0.0, 3.5, 7.5, 3.4, 0)
	LandmarkFrKit.rect(lm, "Stone", -38.0, -2.0, -4.0, 6.0, 0.0, 0.3)
	LandmarkFrKit.tower(lm, "Stone", "Roof", -44.0, -9.0, 3.0, 0.0, 12.0, 5.0)
	LandmarkFrKit.tower(lm, "Stone", "Roof", -44.0, 11.0, 3.0, 0.0, 12.0, 5.0)
	# Kuuri tower: stone shaft, plastered top storeys and the steep hipped roof.
	LandmarkFrKit.rect(lm, "Stone", -6.0, 3.0, -7.0, 2.0, 0.0, 12.0)
	LandmarkFrKit.rect(lm, "Wall", -6.0, 3.0, -7.0, 2.0, 12.0, 22.0)
	LandmarkFrKit.hip(lm, "Roof", -6.0, 3.0, -7.0, 2.0, 22.0, 8.0, 0.8)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		LandmarkFrKit.windows(lm, "Glass", Vector3(-1.5, 17.0, -2.5) + r * Vector3(0, 0, 4.55), r * Vector3.RIGHT,
			2, 3.0, Vector3(1.0, 2.0, 0.15), r)
	for z in [-7.05, 16.05]:
		var sgn := -1.0 if z < 0.0 else 1.0
		LandmarkFrKit.windows(lm, "Glass", Vector3(23.0, 8.5, z + sgn * 0.02), Vector3.RIGHT, 6, 5.5,
			Vector3(1.1, 2.0, 0.2))
	lm.commit(model)
