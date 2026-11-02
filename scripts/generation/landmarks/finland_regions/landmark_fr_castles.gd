class_name LandmarkFrCastles
extends RefCounted

## Three medieval castles of Finland in true metres, in the frame of the
## real plan (+X east, +Z south, turned onto the map by yaw_deg): Hame
## Castle on Lake Vanajavesi, Olavinlinna on its rock in Savonlinna and
## Kastelholm on Aland. Plans follow the OpenStreetMap footprints.

## Storeyed castle wing: grey stone base to `stone_h`, upper storeys in
## `wall`, then a gabled roof (ridge along X when ridge_x = 1, Z when 0)
## with its bargeboards and ridge in `trim`.
static func _wing(lm: LandmarkMesh, wall: String, roof: String, x0: float, x1: float, z0: float,
		z1: float, y0: float, stone_h: float, eave: float, rise: float, ridge_x: int,
		over: float = 0.5, trim: String = "") -> void:
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, y0, stone_h)
	LandmarkFrKit.rect(lm, wall, x0, x1, z0, z1, stone_h, eave)
	LandmarkFrKit.gable(lm, roof, x0, x1, z0, z1, eave, rise, over, wall, ridge_x)
	if trim != "":
		LandmarkFrParts.roof_trim(lm, trim, x0, x1, z0, z1, eave, rise, over, ridge_x, 0.28)

## Hame Castle (Hameen linna), Hameenlinna, begun in the late 1200s as a
## grey-stone camp castle and raised in red brick in the 1300s-1400s (rare
## in medieval Finland; brick gave its Gothic vaults and ornament): the
## four-wing keep round a small yard (37 x 30 m) with steep roofs and brick
## gables patterned with white blind niches, the stair tower on the south,
## the octagonal brick corner turret and one of the two round gun turrets
## of 1559 (Henrik von Collen), inside the crenellated curtain wall with
## its gatehouse, restored by 1988, on the shore of Lake Vanajavesi.
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
	_wing(lm, "Brick", "Roof", -13.3, 18.4, -15.3, -7.0, 0.0, 7.5, 15.5, 4.6, 1, 0.5, "Roof")
	_wing(lm, "Brick", "Roof", -13.6, 18.6, 3.9, 15.3, 0.0, 7.5, 15.5, 5.6, 1, 0.5, "Roof")
	_wing(lm, "Brick", "Roof", 8.6, 18.6, -7.0, 3.9, 0.0, 7.5, 15.5, 5.0, 0, 0.5, "Roof")
	_wing(lm, "Brick", "Roof", -13.3, -3.5, -7.0, 3.9, 0.0, 7.5, 15.5, 5.0, 0, 0.5, "Roof")
	_wing(lm, "Brick", "Roof", -18.6, -13.3, -1.9, 10.1, 0.0, 7.5, 13.0, 4.0, 0, 0.5, "Roof")
	LandmarkFrKit.rect(lm, "Stone", -3.5, 8.6, -7.0, 3.9, 0.0, 0.4)
	LandmarkFrKit.rect(lm, "Stone", -14.0, 19.3, -16.0, 16.0, 0.0, 1.2)
	# Brick gables with white blind niches at the wing ends.
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(18.4, 15.5, -11.15), Vector3.RIGHT, 8.3, 4.6, 4)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(18.6, 15.5, 9.6), Vector3.RIGHT, 11.4, 5.6, 5)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(-13.3, 15.5, -11.15), Vector3.LEFT, 8.3, 4.6, 4)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(-13.6, 15.5, 12.7), Vector3.LEFT, 5.2, 5.6, 3)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(-15.95, 13.0, -1.9), Vector3.FORWARD, 5.3, 4.0, 3)
	# Brick friezes under the eaves: a white band of small niches.
	for zz in [[-15.3, -1.0], [15.3, 1.0]]:
		var z: float = zz[0]
		var n := Vector3(0, 0, zz[1])
		lm.box("Trim", Vector3(2.5, 14.3, z + zz[1] * 0.03), Vector3(31.0, 0.8, 0.06), Basis(), 0.0)
		LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(-12.0, 10.5, z), Vector3(17.0, 10.5, z), n, 7,
			1.1, 2.2, LandmarkFrParts.HEAD_POINTED, 0.24, 0.12, 1)
		LandmarkFrParts.gun_loops(lm, "Stone", "Glass", Vector3(-12.0, 3.0, z), Vector3(17.0, 3.0, z), n, 5,
			0.5, 1.3)
	for xx in [[18.6, 1.0], [-18.6, -1.0]]:
		var x: float = xx[0]
		LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(x, 9.0, -1.0), Vector3(x, 9.0, 8.0), Vector3(xx[1], 0, 0),
			2, 1.0, 2.0, LandmarkFrParts.HEAD_POINTED, 0.24, 0.12)
	# Gabled stair tower on the south front, its door and windows.
	LandmarkFrKit.tower(lm, "Brick", "RoofRed", 2.0, 15.0, 2.6, 0.0, 19.0, 6.0, 0.3)
	for k in 3:
		LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(2.0, 5.0 + 4.5 * float(k), 17.6), Vector3.BACK, 0.7, 1.5,
			LandmarkFrParts.HEAD_POINTED, 0.2, 0.1)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(4.6, 0.0, 15.3), Vector3.BACK, 1.8, 3.2,
		LandmarkFrParts.HEAD_POINTED, 0.35, 0.2)
	LandmarkFrParts.band(lm, "Trim", -0.6, 4.6, 12.4, 17.6, 18.4, 0.4, 0.1)
	# Chimneys on the long roofs.
	for cx: float in [-6.0, 6.0, 14.0]:
		LandmarkFrParts.chimney(lm, "Brick", Vector3(cx, 17.0, -11.15), 21.6, 1.0)
		LandmarkFrParts.chimney(lm, "Brick", Vector3(cx - 2.0, 17.0, 9.6), 22.6, 1.0)
	# Octagonal brick corner turret of the keep and the round gun turret.
	lm.frustum("Stone", Vector3(18.6, 0, -15.3), 3.5, 3.3, 8.0, 8, PI / 8.0)
	lm.frustum("Brick", Vector3(18.6, 8.0, -15.3), 3.3, 3.2, 14.0, 8, PI / 8.0)
	lm.frustum("Trim", Vector3(18.6, 20.6, -15.3), 3.36, 3.36, 0.5, 8, PI / 8.0)
	lm.lathe("RoofRed", Vector3(18.6, 22.0, -15.3), PackedVector2Array([Vector2(3.9, 0), Vector2(0.15, 6.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkFrParts.ring_openings(lm, "Brick", "Glass", Vector3(18.6, 12.0, -15.3), 3.05, 4, 0.7, 1.6,
		LandmarkFrParts.HEAD_POINTED, PI * 0.25 - PI * 0.5)
	LandmarkFrParts.ring_openings(lm, "Brick", "Glass", Vector3(18.6, 17.0, -15.3), 3.0, 4, 0.7, 1.6,
		LandmarkFrParts.HEAD_POINTED, PI * 0.25)
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -30.0, 29.0, 6.5, 0.0, 12.0, 4.0, 28)
	lm.frustum("Brick", Vector3(-30.0, 9.0, 29.0), 6.3, 6.3, 3.0, 28)
	for k in 6:
		var a := PI * 0.5 + PI * 1.4 * (float(k) / 5.0 - 0.5)
		var gn := Vector3(cos(a), 0, sin(a))
		LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(-30.0, 5.0, 29.0) + gn * 6.45, gn, 0.6, 0.6,
			LandmarkFrParts.HEAD_ROUND, 0.25, 0.15)
	# Curtain wall with merlons, a brick top band and the gatehouse.
	var wall := PackedVector2Array([Vector2(-32, -30), Vector2(34, -30), Vector2(34, 31), Vector2(-32, 31)])
	LandmarkFrKit.curtain(lm, "Stone", wall, 0.0, 8.0, 2.4, "Brick")
	for i in wall.size():
		var p := wall[i]
		var q := wall[(i + 1) % wall.size()]
		lm.beam("Brick", Vector3(p.x, 7.4, p.y), Vector3(q.x, 7.4, q.y), 1.2, 2.5, Vector3.UP)
		lm.beam("Stone", Vector3(p.x, 0.8, p.y), Vector3(q.x, 0.8, q.y), 1.6, 3.2, Vector3.UP)
		LandmarkFrKit.round_tower(lm, "Stone", "Roof", p.x, p.y, 2.4, 0.0, 9.5, 3.0, 12)
	LandmarkFrKit.house(lm, "Brick", "Roof", -7.0, 1.0, 27.5, 34.5, 0.0, 10.0, 4.0, 0.5, 0)
	LandmarkFrParts.roof_trim(lm, "Roof", -7.0, 1.0, 27.5, 34.5, 10.0, 4.0, 0.5, 0, 0.25)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(-3.0, 10.0, 34.5), Vector3.BACK, 8.0, 4.0, 3)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(-3.0, 0.0, 34.5), Vector3.BACK, 3.0, 4.6,
		LandmarkFrParts.HEAD_POINTED, 0.5, 0.3)
	LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(-6.0, 6.6, 34.5), Vector3(0.0, 6.6, 34.5), Vector3.BACK, 2,
		0.8, 1.6, LandmarkFrParts.HEAD_POINTED, 0.2, 0.1)
	lm.commit(model)

## Olavinlinna (St Olaf's Castle), Savonlinna, 1475 (keep complete by
## 1485, outer bailey 1495): the first Swedish castle with round
## cannon-proof towers. The keep on the west of the rock island in the
## Kyronsalmi strait with its three standing round towers (the Church
## Tower, the Bell Tower and Kijl's Tower) under conical roofs, each with a
## row of round gun ports below the eaves, the stump of St Erik's Tower
## (cut to its two lowest storeys in 1714), and the three-storey palace
## wing between them; the larger rectangular outer bailey on the east with
## its curtain wall, the Thick Bastion where the Thick Tower blew up in
## 1791 and the smaller towers. y = 0 at the water.
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
	lm.poly_prism("Rock", island, 0.0, 1.6)
	var shrunk := PackedVector2Array()
	for p in island:
		shrunk.append(p * 0.97 + Vector2(0.0, -0.5))
	lm.poly_prism("Rock", shrunk, 1.6, 3.0)
	var g := 3.0
	# Keep: palace wings round the courtyard (x -56..-8, z -34..4).
	_wing(lm, "Wall", "RoofDark", -56.0, -8.0, -34.0, -27.0, g, g + 5.0, 21.0, 5.0, 1, 0.5, "RoofDark")
	_wing(lm, "Wall", "RoofDark", -56.0, -8.0, -3.0, 4.0, g, g + 5.0, 21.0, 5.0, 1, 0.5, "RoofDark")
	_wing(lm, "Wall", "RoofDark", -56.0, -49.0, -27.0, -3.0, g, g + 5.0, 21.0, 5.0, 0, 0.5, "RoofDark")
	_wing(lm, "Wall", "RoofDark", -15.0, -8.0, -27.0, -3.0, g, g + 5.0, 21.0, 5.0, 0, 0.5, "RoofDark")
	LandmarkFrKit.rect(lm, "Stone", -49.0, -15.0, -27.0, -3.0, g, g + 0.4)
	# Palace fronts: three storeys of small windows, gun loops in the stone.
	for zz in [[-34.0, -1.0], [4.0, 1.0]]:
		var z: float = zz[0]
		var n := Vector3(0, 0, zz[1])
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-49.0, g + 5.0, z), Vector3(-15.0, g + 5.0, z), n,
			21.0 - g - 5.0, 8, 3, Vector2(1.1, 1.8), 1.2, 4.3, 0.25)
		LandmarkFrParts.gun_loops(lm, "Stone", "Glass", Vector3(-48.0, g + 1.5, z), Vector3(-16.0, g + 1.5, z), n, 7,
			0.4, 1.2)
	for zz2 in [[-27.0, 1.0], [-3.0, -1.0]]:
		LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(-48.0, g + 9.0, zz2[0]), Vector3(-16.0, g + 9.0, zz2[0]),
			Vector3(0, 0, zz2[1]), 7, 1.3, 2.2, LandmarkFrParts.HEAD_ROUND, 0.25, 0.12, 1)
	for cx: float in [-44.0, -30.0, -20.0]:
		LandmarkFrParts.chimney(lm, "Stone", Vector3(cx, 22.0, -30.5), 27.0, 1.1)
	# The three standing round towers with their conical roofs, gun ports
	# under the eaves and string courses; St Erik's Tower a roofless stump.
	for t in [[-56.0, -34.0, 7.2, 30.0, 8.0], [-8.0, -34.0, 6.4, 27.0, 7.0], [-8.0, 4.0, 6.6, 25.0, 7.0]]:
		_round_tower(lm, t[0], t[1], t[2], g, t[3], t[4])
	lm.frustum("Stone", Vector3(-56.0, g, 4.0), 4.8, 4.6, 9.0, 24)
	for k in 10:
		var a := TAU * float(k) / 10.0
		lm.box("Stone", Vector3(-56.0 + cos(a) * 4.3, g + 9.0 + 0.4 * float(k % 3), 4.0 + sin(a) * 4.3),
			Vector3(1.4, 0.8 + 0.6 * float(k % 3), 1.0), Basis(Vector3.UP, -a))
	# Outer bailey: curtain wall with its wall walk, towers and houses.
	var ward := PackedVector2Array([Vector2(-6, -36), Vector2(70, -36), Vector2(78, -6), Vector2(66, 8),
		Vector2(26, 10), Vector2(-6, 6)])
	LandmarkFrKit.curtain(lm, "Stone", ward, g, 9.0, 2.6, "Stone")
	for i in ward.size():
		var p := ward[i]
		var q := ward[(i + 1) % ward.size()]
		lm.beam("Stone", Vector3(p.x, g + 1.0, p.y), Vector3(q.x, g + 1.0, q.y), 2.0, 3.4, Vector3.UP)
	# Thick Bastion on the site of the Thick Tower: a low round platform.
	lm.frustum("Stone", Vector3(48.0, g, -38.0), 9.0, 8.4, 9.0, 32)
	lm.frustum("Stone", Vector3(48.0, g + 9.0, -38.0), 8.6, 8.6, 1.2, 32)
	lm.frustum("Rock", Vector3(48.0, g + 9.0, -38.0), 7.6, 7.6, 1.25, 32)
	_round_tower(lm, 70.0, -34.0, 5.2, g, 16.0, 6.0)
	_round_tower(lm, 70.0, 8.0, 5.0, g, 15.0, 6.0)
	LandmarkFrKit.house(lm, "Wall", "RoofDark", 8.0, 56.0, -30.0, -20.0, g, g + 5.5, 4.0, 0.5, 1)
	LandmarkFrParts.roof_trim(lm, "RoofDark", 8.0, 56.0, -30.0, -20.0, g + 5.5, 4.0, 0.5, 1, 0.25)
	LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(10.0, g + 1.0, -20.0), Vector3(54.0, g + 1.0, -20.0),
		Vector3.BACK, 9, 1.0, 1.6, LandmarkFrParts.HEAD_FLAT, 0.2, 0.1, 1)
	LandmarkFrKit.house(lm, "Wall", "RoofDark", 20.0, 50.0, -4.0, 4.0, g, g + 4.5, 3.2, 0.5, 1)
	LandmarkFrParts.roof_trim(lm, "RoofDark", 20.0, 50.0, -4.0, 4.0, g + 4.5, 3.2, 0.5, 1, 0.25)
	LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(22.0, g + 1.0, -4.0), Vector3(48.0, g + 1.0, -4.0),
		Vector3.FORWARD, 6, 1.0, 1.6, LandmarkFrParts.HEAD_FLAT, 0.2, 0.1, 1)
	# Gate in the east wall and the landing stage on the water below it.
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(76.0, g, -14.0), Vector3(0.966, 0, 0.259), 3.2, 4.4,
		LandmarkFrParts.HEAD_ROUND, 0.5, 0.35)
	lm.commit(model)

## Olavinlinna round tower about (cx, cz): battered stone shaft from y0 to
## y1, string course, a ring of round gun ports below the eaves and the
## conical roof rising `cap`.
static func _round_tower(lm: LandmarkMesh, cx: float, cz: float, r: float, y0: float, y1: float,
		cap: float) -> void:
	var c := Vector3(cx, y0, cz)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(r * 1.08, 0), Vector2(r, 3.0), Vector2(r * 0.97, y1 - y0)]), 32)
	lm.frustum("Stone", c + Vector3(0, (y1 - y0) * 0.45, 0), r * 1.0 + 0.12, r * 0.99 + 0.12, 0.45, 32)
	var ports := int(TAU * r / 3.2)
	for k in ports:
		var a := TAU * (float(k) + 0.5) / float(ports)
		var n := Vector3(cos(a), 0, sin(a))
		LandmarkFrParts.opening(lm, "Stone", "Glass", c + n * (r * 0.97) + Vector3(0, y1 - y0 - 2.2, 0), n, 0.55,
			0.55, LandmarkFrParts.HEAD_ROUND, 0.2, 0.12)
	for k2 in 3:
		var a2 := TAU * float(k2) / 3.0 + 0.4
		var n2 := Vector3(cos(a2), 0, sin(a2))
		LandmarkFrParts.opening(lm, "Stone", "Glass", c + n2 * (r * 0.985) + Vector3(0, (y1 - y0) * 0.55, 0), n2, 0.8,
			1.4, LandmarkFrParts.HEAD_ROUND, 0.22, 0.12)
	if cap > 0.0:
		lm.lathe("Roof", Vector3(cx, y1, cz), PackedVector2Array([Vector2(r * 1.12, 0), Vector2(r * 0.9, cap * 0.18),
			Vector2(r * 0.45, cap * 0.62), Vector2(0.0, cap)]), 32)
		lm.frustum("Roof", Vector3(cx, y1 + cap - 1.0, cz), 0.08, 0.04, 1.0, 6)

## Kastelholm Castle, Sund, Aland, late 14th century, on what was an
## island of about 1.7 ha in the fjord: the main castle (about 30 x 20 m)
## with its three-storey palace wing, stone below and plastered storeys
## and a steep roof above, round a small yard; the bailey north of it
## (about 45 x 25 m) with its low wings, wall and corner towers; and
## between them the high Kuuri tower, the gate tower to the bailey,
## merged into one donjon. The east wing's roof and shutters are from the
## 1980s.
const KASTEL_TOP := 30.0

static func kastelholm(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8C85", 3.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C8C2B3", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8A4D3A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5A3A2A", 1.8))
	# Main castle (x 3..43, z -7..16): wings round a yard.
	_wing(lm, "Wall", "Roof", 3.0, 43.0, -7.0, 0.0, 0.0, 5.0, 12.0, 5.0, 1, 0.5, "Wood")
	_wing(lm, "Wall", "Roof", 3.0, 43.0, 9.0, 16.0, 0.0, 5.0, 12.0, 5.0, 1, 0.5, "Wood")
	_wing(lm, "Wall", "Roof", 3.0, 11.0, 0.0, 9.0, 0.0, 5.0, 12.0, 5.0, 0, 0.5, "Wood")
	_wing(lm, "Wall", "Roof", 35.0, 43.0, 0.0, 9.0, 0.0, 5.0, 12.0, 5.0, 0, 0.5, "Wood")
	LandmarkFrKit.rect(lm, "Stone", 11.0, 35.0, 0.0, 9.0, 0.0, 0.3)
	LandmarkFrKit.rect(lm, "Stone", 2.4, 43.6, -7.6, 16.6, 0.0, 1.0)
	# Long fronts: two plastered storeys of shuttered windows over stone,
	# gun loops low down, the east gable with its windows.
	for zz in [[-7.0, -1.0], [16.0, 1.0]]:
		var z: float = zz[0]
		var n := Vector3(0, 0, zz[1])
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(3.0, 5.0, z), Vector3(43.0, 5.0, z), n, 7.0, 7, 2,
			Vector2(1.1, 1.8), 0.8, 3.4, 0.25)
		LandmarkFrParts.gun_loops(lm, "Stone", "Glass", Vector3(5.0, 1.8, z), Vector3(41.0, 1.8, z), n, 6, 0.4, 1.0)
		for k in 7:
			var x := 3.0 + 40.0 * (float(k) + 0.5) / 7.0
			for s: float in [-1.0, 1.0]:
				lm.box("Wood", Vector3(x + s * 1.05, 5.8 + 0.9, z + zz[1] * 0.3), Vector3(0.5, 1.8, 0.06), Basis(), 0.0)
				lm.box("Wood", Vector3(x + s * 1.05, 5.8 + 0.9 + 3.4, z + zz[1] * 0.3), Vector3(0.5, 1.8, 0.06), Basis(),
					0.0)
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(43.0, 5.0, -7.0), Vector3(43.0, 5.0, 16.0), Vector3.RIGHT,
		7.0, 4, 2, Vector2(1.1, 1.8), 0.8, 3.4, 0.25)
	for cx: float in [12.0, 24.0, 36.0]:
		LandmarkFrParts.chimney(lm, "Stone", Vector3(cx, 14.0, -3.5), 18.2, 0.9)
	LandmarkFrParts.chimney(lm, "Stone", Vector3(30.0, 14.0, 12.5), 18.2, 0.9)
	# Outer bailey (x -45..-2, z -10..12): low wings, wall and corner towers.
	_wing(lm, "Wall", "Roof", -45.0, -2.0, -10.0, -4.0, 0.0, 3.5, 7.5, 3.4, 1, 0.5, "Wood")
	_wing(lm, "Wall", "Roof", -45.0, -2.0, 6.0, 12.0, 0.0, 3.5, 7.5, 3.4, 1, 0.5, "Wood")
	_wing(lm, "Wall", "Roof", -45.0, -38.0, -4.0, 6.0, 0.0, 3.5, 7.5, 3.4, 0, 0.5, "Wood")
	LandmarkFrKit.rect(lm, "Stone", -38.0, -2.0, -4.0, 6.0, 0.0, 0.3)
	for zz2 in [[-10.0, -1.0], [12.0, 1.0]]:
		LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(-43.0, 4.0, zz2[0]), Vector3(-8.0, 4.0, zz2[0]),
			Vector3(0, 0, zz2[1]), 8, 0.9, 1.5, LandmarkFrParts.HEAD_FLAT, 0.2, 0.12, 1)
		LandmarkFrParts.gun_loops(lm, "Stone", "Glass", Vector3(-43.0, 1.5, zz2[0]), Vector3(-8.0, 1.5, zz2[0]),
			Vector3(0, 0, zz2[1]), 6, 0.35, 0.9)
	LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(-45.0, 4.0, -3.0), Vector3(-45.0, 4.0, 5.0), Vector3.LEFT,
		3, 0.9, 1.5, LandmarkFrParts.HEAD_FLAT, 0.2, 0.12, 1)
	for t in [[-44.0, -9.0], [-44.0, 11.0]]:
		var tx: float = t[0]
		var tz: float = t[1]
		LandmarkFrKit.tower(lm, "Stone", "Roof", tx, tz, 3.0, 0.0, 12.0, 5.0)
		LandmarkFrParts.band(lm, "Wall", tx - 3.0, tx + 3.0, tz - 3.0, tz + 3.0, 11.4, 0.6, 0.1)
		for f in 4:
			var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
			var fn: Vector3 = rb * Vector3(0, 0, 1)
			LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(tx, 8.5, tz) + fn * 3.0, fn, 0.45, 1.1,
				LandmarkFrParts.HEAD_FLAT, 0.2, 0.1)
		lm.box("Wood", Vector3(tx, 17.3, tz), Vector3(0.12, 0.8, 0.12))
	# Kuuri tower: stone shaft with the gate passage, plastered top storeys
	# with windows on every face, eave cornice and the steep hipped roof.
	LandmarkFrKit.rect(lm, "Stone", -6.0, 3.0, -7.0, 2.0, 0.0, 12.0)
	LandmarkFrKit.rect(lm, "Wall", -6.0, 3.0, -7.0, 2.0, 12.0, 22.0)
	LandmarkFrParts.band(lm, "Stone", -6.0, 3.0, -7.0, 2.0, 11.6, 0.6, 0.12)
	LandmarkFrParts.cornice_ring(lm, "Wall", -6.0, 3.0, -7.0, 2.0, 21.4, 0.6)
	LandmarkFrKit.hip(lm, "Roof", -6.0, 3.0, -7.0, 2.0, 22.0, 8.0, 0.8)
	LandmarkFrParts.corner_strips(lm, "Stone", -6.0, 3.0, -7.0, 2.0, 12.0, 21.4, 0.7, 0.1)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(-6.0, 0.0, -2.5), Vector3.LEFT, 3.0, 4.2,
		LandmarkFrParts.HEAD_ROUND, 0.45, 0.3)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(3.0, 0.0, -2.5), Vector3.RIGHT, 3.0, 4.2,
		LandmarkFrParts.HEAD_ROUND, 0.45, 0.3)
	for f2 in 4:
		var r2 := Basis(Vector3.UP, PI * 0.5 * float(f2))
		var half := 4.5
		var fn2: Vector3 = r2 * Vector3(0, 0, 1)
		var along: Vector3 = r2 * Vector3.RIGHT
		for s2: float in [-1.0, 1.0]:
			for y: float in [14.0, 18.0]:
				LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(-1.5, y, -2.5) + fn2 * half + along * s2 * 1.6,
					fn2, 1.0, 2.0, LandmarkFrParts.HEAD_FLAT, 0.18, 0.12, 1)
		LandmarkFrParts.gun_loops(lm, "Stone", "Glass", Vector3(-1.5, 7.0, -2.5) + fn2 * half - along * 2.5,
			Vector3(-1.5, 7.0, -2.5) + fn2 * half + along * 2.5, fn2, 2, 0.35, 1.0)
	lm.spire("Wood", Vector3(-1.5, 29.6, -2.5), 0.1, 0.4)
	lm.commit(model)
