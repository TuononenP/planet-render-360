class_name LandmarkFrTurku
extends RefCounted

## The south-west Finland landmarks of the finland_regions batch in true
## metres, in the frame of the real plan (+X east, +Z south, turned onto
## the map by yaw_deg): Turku Castle on the Aura river mouth, the Naantali
## convent church and Rauma's Church of the Holy Cross. Plans follow the
## OpenStreetMap footprints.

## Turku Castle (Turun linna), founded in the 1280s on a 65 x 30 m camp
## castle plan: the medieval main castle in grey stone with its
## Renaissance upper floors added by Duke John (west, on the river mouth:
## the north and south wings with over 40 rooms round a long narrow
## courtyard, the western keep, 38 m to the top of its roof and the
## highest point of the castle, the eastern gate tower raised with firing
## galleries in the 1400s, and the small (1550) and large (1558) stair
## towers in the yard) and the lower Renaissance bailey of 1576-1588 beside
## it (east: a four-sided group of wings with the pentagonal north corner
## tower, the hexagonal tower of the south wing, the square tower in the
## middle of the east side and the round gun tower at the east corner).
## Outer walls carry few, small windows; the larger Renaissance windows
## are high up and on the yard.
const TURKU_TOP := 38.0
const TURKU_STONE_H := 9.0

static func turku_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkFrKit.palette(lm, "#8F8B80", "#D9D1BD", "#4A4642")
	lm.use("RoofRed", LandmarkMaterials.pbr("terracotta", "#85493A", 2.5))
	lm.use("Dark", LandmarkMaterials.pbr("slate", "#2C2B29", 2.0))
	# Main castle: north and south wings, the west keep and the east block
	# round the long courtyard (x -70..-6.5, z -17..24).
	_wing(lm, -56.0, -18.5, -17.0, -9.5, 18.0, 7.0, "Roof", 1)
	_wing(lm, -56.0, -18.5, 16.5, 24.2, 18.0, 7.0, "Roof", 1)
	_wing(lm, -70.4, -56.0, -17.0, 24.2, 27.0, 11.0, "Roof", -1, true)
	_wing(lm, -18.5, -6.5, -17.0, 24.2, 20.0, 7.5, "Roof", 0)
	LandmarkFrKit.rect(lm, "Stone", -56.0, -18.5, -9.5, 16.5, 0.0, 0.4)
	# Battered stone plinth round the main castle.
	LandmarkFrKit.rect(lm, "Stone", -71.2, -5.7, -17.8, 25.0, 0.0, 1.4)
	# Fronts: small Renaissance windows in the plastered storeys, gun loops
	# in the stone, buttresses on the long outer walls.
	for side in [[-17.0, -1.0], [24.2, 1.0]]:
		var z: float = side[0]
		var s: float = side[1]
		var n := Vector3(0, 0, s)
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-56.0, TURKU_STONE_H, z), Vector3(-18.5, TURKU_STONE_H, z),
			n, 18.0 - TURKU_STONE_H, 9, 2, Vector2(1.2, 1.9), 1.6, 4.4, 0.25)
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-70.4, TURKU_STONE_H, z), Vector3(-56.0, TURKU_STONE_H, z),
			n, 27.0 - TURKU_STONE_H, 3, 4, Vector2(1.1, 1.8), 1.6, 4.2, 0.25)
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-18.5, TURKU_STONE_H, z), Vector3(-6.5, TURKU_STONE_H, z),
			n, 20.0 - TURKU_STONE_H, 3, 2, Vector2(1.1, 1.8), 1.8, 4.6, 0.25)
		LandmarkFrParts.gun_loops(lm, "Stone", "Dark", Vector3(-68.0, 3.0, z), Vector3(-9.0, 3.0, z), n, 12)
		LandmarkFrParts.band(lm, "Trim", -70.4, -6.5, z - 0.01 if s < 0.0 else z, z if s < 0.0 else z + 0.01,
			TURKU_STONE_H - 0.2, 0.4, 0.15)
		for k in 4:
			LandmarkFrParts.buttress(lm, "Stone", Vector3(-50.0 + 10.5 * float(k), 0, z), n, 2.0, 2.2, 11.0, 2)
	# West keep: windows on its west face, quoins up the corners.
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-70.4, TURKU_STONE_H, 24.2), Vector3(-70.4, TURKU_STONE_H, -17.0),
		Vector3.LEFT, 27.0 - TURKU_STONE_H, 7, 4, Vector2(1.1, 1.8), 1.6, 4.2, 0.25)
	LandmarkFrParts.gun_loops(lm, "Stone", "Dark", Vector3(-70.4, 3.0, 22.0), Vector3(-70.4, 3.0, -15.0), Vector3.LEFT, 6)
	LandmarkFrParts.corner_strips(lm, "Stone", -70.4, -56.0, -17.0, 24.2, TURKU_STONE_H, 27.0, 0.9, 0.15)
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-6.5, TURKU_STONE_H, -17.0), Vector3(-6.5, TURKU_STONE_H, 24.2),
		Vector3.RIGHT, 20.0 - TURKU_STONE_H, 6, 2, Vector2(1.1, 1.8), 1.8, 4.6, 0.25)
	# Courtyard: the two stair towers, yard windows and the gate arch.
	for st in [[-40.0, -8.6, 2.4, 21.0], [-27.0, 15.6, 3.0, 23.0]]:
		var sx: float = st[0]
		var sz: float = st[1]
		var sr: float = st[2]
		var sh: float = st[3]
		lm.frustum("Wall", Vector3(sx, 0, sz), sr, sr * 0.97, sh, 8, PI / 8.0)
		lm.lathe("Roof", Vector3(sx, sh, sz), PackedVector2Array([Vector2(sr * 1.2, 0), Vector2(sr * 0.5, 2.2),
			Vector2(0.1, 5.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(sx, 6.0, sz), sr, 4, 0.7, 1.4,
			LandmarkFrParts.HEAD_FLAT, PI / 8.0)
		LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(sx, 13.0, sz), sr, 4, 0.7, 1.4,
			LandmarkFrParts.HEAD_FLAT, PI / 8.0)
	for yz in [[-9.5, 1.0], [16.5, -1.0]]:
		var zz: float = yz[0]
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-54.0, 11.0, zz), Vector3(-20.0, 11.0, zz),
			Vector3(0, 0, yz[1]), 8, 1.4, 2.3, LandmarkFrParts.HEAD_FLAT, 0.16, 0.1, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-54.0, 14.6, zz), Vector3(-20.0, 14.6, zz),
			Vector3(0, 0, yz[1]), 8, 1.2, 1.8, LandmarkFrParts.HEAD_FLAT, 0.16, 0.1, 1)
	LandmarkFrParts.opening(lm, "Stone", "Dark", Vector3(-6.4, 0.0, 3.5), Vector3.RIGHT, 3.4, 5.0,
		LandmarkFrParts.HEAD_ROUND, 0.5, 0.3)
	# Roof bargeboards, ridges, chimneys and small dormers.
	LandmarkFrParts.roof_trim(lm, "Dark", -56.0, -18.5, -17.0, -9.5, 18.0, 7.0, 0.5, 1)
	LandmarkFrParts.roof_trim(lm, "Dark", -56.0, -18.5, 16.5, 24.2, 18.0, 7.0, 0.5, 1)
	LandmarkFrParts.roof_trim(lm, "Dark", -18.5, -6.5, -17.0, 24.2, 20.0, 7.5, 0.5, 0)
	for cx: float in [-50.0, -38.0, -26.0]:
		LandmarkFrParts.chimney(lm, "Stone", Vector3(cx, 22.0, -13.2), 26.6, 1.2)
		LandmarkFrParts.chimney(lm, "Stone", Vector3(cx + 4.0, 22.0, 20.4), 26.6, 1.2)
	for k in 4:
		var dx := -49.0 + 9.0 * float(k)
		LandmarkFrParts.dormer(lm, "Wall", "Roof", "Glass", Vector3(dx, 20.4, -16.0), Vector3.FORWARD, 1.6, 1.6, 1.4)
		LandmarkFrParts.dormer(lm, "Wall", "Roof", "Glass", Vector3(dx, 20.4, 23.2), Vector3.BACK, 1.6, 1.6, 1.4)
	# East gate tower of the main castle with its pyramid cap.
	LandmarkFrKit.tower(lm, "Wall", "Roof", -12.5, -13.0, 3.4, TURKU_STONE_H, 25.0, 7.0)
	LandmarkFrKit.rect(lm, "Stone", -15.9, -9.1, -16.4, -9.6, 0.0, TURKU_STONE_H)
	LandmarkFrParts.band(lm, "Trim", -15.9, -9.1, -16.4, -9.6, 24.6, 0.5, 0.2)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-12.5, 21.5, -13.0) + fn * 3.4, fn, 0.9, 1.6,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.1)
	lm.spire("Dark", Vector3(-12.5, 32.0, -13.0), 0.18, 1.6)
	lm.spire("Dark", Vector3(-63.2, 37.6, 3.6), 0.12, 0.4)
	# Bailey (x -6.5..52, z -33..31): wings of red roofs round its yard.
	_wing(lm, -6.5, 50.0, -33.0, -21.0, 12.0, 5.0, "RoofRed", 1)
	_wing(lm, -6.5, 47.0, 21.0, 31.5, 12.0, 5.0, "RoofRed", 1)
	_wing(lm, 43.0, 55.0, -25.0, 10.0, 12.0, 5.0, "RoofRed", 0)
	LandmarkFrKit.rect(lm, "Stone", -6.5, 43.0, -21.0, 21.0, 0.0, 0.4)
	LandmarkFrParts.roof_trim(lm, "Dark", -6.5, 50.0, -33.0, -21.0, 12.0, 5.0, 0.5, 1, 0.25)
	LandmarkFrParts.roof_trim(lm, "Dark", -6.5, 47.0, 21.0, 31.5, 12.0, 5.0, 0.5, 1, 0.25)
	LandmarkFrParts.roof_trim(lm, "Dark", 43.0, 55.0, -25.0, 10.0, 12.0, 5.0, 0.5, 0, 0.25)
	for bz in [[-33.0, -1.0, 50.0], [31.5, 1.0, 47.0], [-21.0, 1.0, 43.0], [21.0, -1.0, 43.0]]:
		var z2: float = bz[0]
		var n2 := Vector3(0, 0, bz[1])
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-6.5, TURKU_STONE_H, z2), Vector3(bz[2], TURKU_STONE_H, z2),
			n2, 12.0 - TURKU_STONE_H, 10, 1, Vector2(1.1, 1.6), 0.8, 3.0, 0.2)
		LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(-4.0, 4.0, z2), Vector3(float(bz[2]) - 4.0, 4.0, z2), n2,
			8, 0.9, 1.5, LandmarkFrParts.HEAD_ROUND, 0.25, 0.12)
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(55.0, TURKU_STONE_H, -25.0), Vector3(55.0, TURKU_STONE_H, 10.0),
		Vector3.RIGHT, 12.0 - TURKU_STONE_H, 7, 1, Vector2(1.1, 1.6), 0.8, 3.0, 0.2)
	# The bailey's main gate in the east wing.
	LandmarkFrParts.opening(lm, "Stone", "Dark", Vector3(55.05, 0.0, -14.0), Vector3.RIGHT, 3.6, 5.2,
		LandmarkFrParts.HEAD_ROUND, 0.55, 0.35)
	# Pentagonal, hexagonal and square towers, round cannon tower.
	lm.frustum("Stone", Vector3(-3.0, 0, -29.0), 4.4, 4.0, 10.0, 5)
	lm.frustum("Wall", Vector3(-3.0, 10.0, -29.0), 4.0, 3.9, 9.0, 5)
	lm.lathe("RoofRed", Vector3(-3.0, 19.0, -29.0), PackedVector2Array([Vector2(5.0, 0), Vector2(0.0, 7.5)]), 5,
		1.0, 1.0, 0.0, false)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(-3.0, 13.5, -29.0), 3.4, 5, 0.8, 1.5,
		LandmarkFrParts.HEAD_FLAT, PI / 5.0)
	lm.frustum("Stone", Vector3(8.0, 0, 28.5), 3.9, 3.6, 9.5, 6)
	lm.frustum("Wall", Vector3(8.0, 9.5, 28.5), 3.6, 3.5, 7.5, 6)
	lm.lathe("RoofRed", Vector3(8.0, 17.0, 28.5), PackedVector2Array([Vector2(4.4, 0), Vector2(0.0, 6.5)]), 6,
		1.0, 1.0, 0.0, false)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(8.0, 12.0, 28.5), 3.1, 6, 0.8, 1.5,
		LandmarkFrParts.HEAD_FLAT, PI / 6.0)
	LandmarkFrKit.tower(lm, "Wall", "RoofRed", 52.0, -6.0, 3.6, 0.0, 19.0, 8.0)
	LandmarkFrKit.rect(lm, "Stone", 48.4, 55.6, -9.6, -2.4, 0.0, TURKU_STONE_H)
	LandmarkFrParts.band(lm, "Trim", 48.4, 55.6, -9.6, -2.4, 18.6, 0.4, 0.15)
	for f2 in 4:
		var rb2 := Basis(Vector3.UP, PI * 0.5 * float(f2))
		var fn2: Vector3 = rb2 * Vector3(0, 0, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(52.0, 14.0, -6.0) + fn2 * 3.6, fn2, 0.9, 1.6,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.1)
	LandmarkFrKit.round_tower(lm, "Stone", "RoofRed", 59.0, 21.0, 10.0, 0.0, 13.0, 5.0, 28)
	lm.frustum("Stone", Vector3(59.0, 0, 21.0), 10.8, 10.2, 2.4, 28)
	for k in 8:
		var a := -PI * 0.6 + PI * 1.2 * float(k) / 7.0
		var gn := Vector3(cos(a), 0, sin(a))
		LandmarkFrParts.opening(lm, "Stone", "Dark", Vector3(59.0, 6.0, 21.0) + gn * 9.95, gn, 0.6, 0.6,
			LandmarkFrParts.HEAD_ROUND, 0.25, 0.15)
	lm.commit(model)

## Stone base up to TURKU_STONE_H, whitewashed storeys above, then the roof
## (gabled with ridge along X when ridge_x = 1, along Z when 0; hipped).
static func _wing(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, eave: float,
		rise: float, roof: String, ridge_x: int, hipped: bool = false) -> void:
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, 0.0, TURKU_STONE_H)
	LandmarkFrKit.rect(lm, "Wall", x0, x1, z0, z1, TURKU_STONE_H, eave)
	LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, z0, z1, eave - 0.45, 0.45)
	if hipped:
		LandmarkFrKit.hip(lm, roof, x0, x1, z0, z1, eave, rise, 0.5)
	else:
		LandmarkFrKit.gable(lm, roof, x0, x1, z0, z1, eave, rise, 0.5, "Wall", ridge_x)

## Naantali Convent Church (Naantalin kirkko), the Bridgettine convent
## church consecrated in 1462 and finished after 1480: a grey stone hall
## church (nave 43.5 x 28.5 m inside, three aisles) under one steep
## shingle roof, stout buttresses along the long walls with pointed
## windows between them, the east gable in brick with white blind niches,
## a small porch on the south, and the Baroque bell tower (1797) against
## the west gable with four clock faces under a bell-shaped cupola, an
## open lantern, a small cupola, the gilded balls and vane.
## Nave along X, tower at the west (-X) end.
const NAANTALI_TOP := 47.1

static func naantali(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkFrKit.palette(lm, "#A19D94", "#D7D3C6", "#5A5148", "#EDE8DA")
	lm.use("Roof", LandmarkFrKit.shingle("#574E45"))
	lm.use("Copper", LandmarkFrKit.copper("#5E8F7C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4A36", 2.5))
	# Hall, plinth and the single steep roof (eaves 11.5, ridge 26 m).
	LandmarkFrKit.rect(lm, "Stone", -18.0, 29.8, -15.2, 15.2, 0.0, 1.4)
	LandmarkFrKit.rect(lm, "Stone", -18.0, 29.5, -14.9, 14.9, 1.4, 11.5)
	LandmarkFrKit.gable(lm, "Roof", -18.0, 29.5, -14.9, 14.9, 11.5, 14.5, 0.8, "Brick", 1)
	LandmarkFrParts.roof_trim(lm, "Roof", -18.0, 29.5, -14.9, 14.9, 11.5, 14.5, 0.8, 1, 0.35)
	LandmarkFrParts.band(lm, "Trim", -18.0, 29.5, -14.9, 14.9, 11.0, 0.5, 0.12)
	# Long walls: buttresses with pointed windows between them.
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 8:
			var x := -12.0 + 5.9 * float(k)
			LandmarkFrParts.buttress(lm, "Stone", Vector3(x, 0, sz * 14.9), n, 1.4, 1.8, 10.0, 2)
			if k < 7:
				LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(x + 2.95, 3.6, sz * 14.9), n, 1.8, 6.4,
					LandmarkFrParts.HEAD_POINTED, 0.3, 0.14, 1)
	# East gable: brick with white blind niches, three lancets below.
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(29.5, 11.5, 0), Vector3.RIGHT, 29.8, 14.5, 7)
	for k in 3:
		LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(29.5, 3.5, -5.0 + 5.0 * float(k)), Vector3.RIGHT, 1.6,
			6.0 + (1.0 if k == 1 else 0.0), LandmarkFrParts.HEAD_POINTED, 0.3, 0.14, 1)
	for sz2: float in [-1.0, 1.0]:
		LandmarkFrParts.buttress(lm, "Stone", Vector3(29.5, 0, sz2 * 12.0), Vector3.RIGHT, 1.4, 1.8, 10.0, 2)
	# South porch with its stepped gable and door.
	LandmarkFrKit.rect(lm, "Stone", 1.0, 8.0, 14.9, 20.5, 0.0, 6.0)
	LandmarkFrKit.gable(lm, "Roof", 1.0, 8.0, 14.9, 20.5, 6.0, 4.0, 0.4, "Brick", 0)
	LandmarkFrParts.roof_trim(lm, "Roof", 1.0, 8.0, 14.9, 20.5, 6.0, 4.0, 0.4, 0, 0.25)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(4.5, 6.0, 20.5), Vector3.BACK, 7.0, 4.0, 3)
	LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(4.5, 0.0, 20.5), Vector3.BACK, 1.8, 3.4,
		LandmarkFrParts.HEAD_POINTED, 0.3, 0.15)
	# Bell tower on the west gable: base to above the eaves, clock stage,
	# bell-shaped cupola, lantern, small cupola, balls and vane.
	var tx := -24.0
	LandmarkFrKit.rect(lm, "Wall", -30.0, -18.0, -8.0, 8.0, 0.0, 24.5)
	LandmarkFrKit.rect(lm, "Stone", -30.3, -17.7, -8.3, 8.3, 0.0, 1.2)
	LandmarkFrParts.corner_strips(lm, "Trim", -30.0, -18.0, -8.0, 8.0, 1.2, 24.0, 0.8, 0.15)
	LandmarkFrParts.cornice_ring(lm, "Trim", -30.0, -18.0, -8.0, 8.0, 23.9, 0.9)
	LandmarkFrParts.band(lm, "Trim", -30.0, -18.0, -8.0, 8.0, 11.5, 0.4, 0.1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-30.0, 0.0, 0.0), Vector3.LEFT, 2.0, 3.8,
		LandmarkFrParts.HEAD_ROUND, 0.3, 0.18)
	for k in 2:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-30.0, 8.0 + 7.5 * float(k), 0), Vector3.LEFT, 1.5, 3.4,
			LandmarkFrParts.HEAD_ROUND, 0.22, 0.12, 1)
		for sz3: float in [-1.0, 1.0]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx, 8.0 + 7.5 * float(k), sz3 * 8.0), Vector3(0, 0, sz3),
				1.5, 3.4, LandmarkFrParts.HEAD_ROUND, 0.22, 0.12, 1)
	LandmarkFrKit.rect(lm, "Wall", tx - 4.6, tx + 4.6, -4.6, 4.6, 24.9, 33.0)
	LandmarkFrKit.hip(lm, "Roof", -30.0, -18.0, -8.0, 8.0, 24.9, 1.6, 0.3)
	LandmarkFrParts.corner_strips(lm, "Trim", tx - 4.6, tx + 4.6, -4.6, 4.6, 24.9, 32.6, 0.6, 0.12)
	LandmarkFrKit.clocks(lm, "Gilt", "Trim", tx, 0.0, 4.6, 29.5, 1.7)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		LandmarkFrParts.louvre(lm, "Roof", Vector3(tx, 26.0, 0) + fn * 4.6, fn, 1.6, 1.6, 5)
	LandmarkFrKit.rect(lm, "Trim", tx - 5.0, tx + 5.0, -5.0, 5.0, 32.6, 33.4)
	lm.lathe("Copper", Vector3(tx, 33.4, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(5.0, 0.4), Vector2(5.0, 0.9),
		Vector2(4.7, 1.8), Vector2(4.2, 2.6), Vector2(3.4, 3.5), Vector2(2.7, 4.2), Vector2(2.0, 5.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	# Open lantern: eight posts round a core, then the small cupola.
	lm.frustum("Wall", Vector3(tx, 38.4, 0), 1.1, 1.0, 3.2, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Trim", Vector3(tx + cos(a) * 1.75, 40.0, sin(a) * 1.75), Vector3(0.28, 3.2, 0.28))
	lm.frustum("Trim", Vector3(tx, 38.4, 0), 2.0, 2.0, 0.3, 8, PI / 8.0)
	lm.frustum("Trim", Vector3(tx, 41.3, 0), 2.1, 2.1, 0.3, 8, PI / 8.0)
	LandmarkFrParts.ring_railing(lm, "Trim", Vector3(tx, 38.7, 0), 2.0, 0.9, 16, 0.06)
	lm.lathe("Copper", Vector3(tx, 41.6, 0), PackedVector2Array([Vector2(2.3, 0), Vector2(2.0, 0.6),
		Vector2(1.5, 1.2), Vector2(0.9, 2.2), Vector2(0.4, 3.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", Vector3(tx, 44.9, 0), LandmarkFrKit.ball(0.5), 10)
	lm.box("Gilt", Vector3(tx, 46.0, 0), Vector3(0.14, 2.2, 0.14))
	lm.lathe("Gilt", Vector3(tx, 45.95, 0), LandmarkFrKit.ball(0.22), 8)
	lm.box("Gilt", Vector3(tx + 0.5, 46.5, 0), Vector3(1.0, 0.5, 0.04))
	lm.commit(model)

## Church of the Holy Cross, Rauma (Pyhan Ristin kirkko), c. 1515-1520: the
## Franciscan friary's grey granite church in Old Rauma, a low two-aisle
## nave (about 24 x 19 m) under a high shingled roof, the choir (11 x 14
## m) to the east with the cross niche in its gable, the south (1862) and
## north (1891) porches and the sacristy, and the whitewashed steeple
## (1816) built from the stones of the Holy Trinity ruin at the west end,
## its top rebuilt after the 1967 fire to an 1803 drawing.
## Nave along X, tower at the west (-X) end.
const RAUMA_TOP := 38.5

static func rauma(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkFrKit.palette(lm, "#8C897F", "#B9B5A9", "#4A4138", "#EAE6DA")
	lm.use("Roof", LandmarkFrKit.shingle("#4B4239"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4836", 2.5))
	# Nave, choir, sacristy and porches in grey stone with brick gables.
	_stone_house(lm, -14.2, 11.5, -16.3, 4.7, 9.0, 9.5, 0.7, 1)
	_stone_house(lm, 11.5, 22.3, -12.2, 4.5, 8.2, 6.8, 0.6, 1)
	_stone_house(lm, 11.6, 19.9, 4.5, 16.3, 5.6, 4.2, 0.5, 0)
	_stone_house(lm, -7.7, -1.2, 4.7, 10.4, 5.2, 3.6, 0.4, 0)
	_stone_house(lm, 13.3, 18.2, -15.5, -12.2, 4.6, 3.0, 0.3, 0)
	LandmarkFrKit.rect(lm, "Stone", -14.6, 22.7, -16.7, 5.1, 0.0, 0.8)
	# Choir gable with its cross niche and blind niches, a lancet below.
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(22.3, 8.2, -3.85), Vector3.RIGHT, 16.7, 6.8, 5)
	LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(22.3, 2.2, -3.8), Vector3.RIGHT, 1.4, 4.6,
		LandmarkFrParts.HEAD_POINTED, 0.28, 0.12, 1)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(15.75, 5.6, 16.3), Vector3.BACK, 8.3, 4.2, 3)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(-4.45, 5.2, 10.4), Vector3.BACK, 6.5, 3.6, 3)
	# Windows: pointed lancets along the nave and choir, buttresses.
	for side in [[4.7, 1.0], [-16.3, -1.0]]:
		var z: float = side[0]
		var n := Vector3(0, 0, side[1])
		for k in 5:
			var x := -11.5 + 4.6 * float(k)
			if side[1] > 0.0 and x > -8.5 and x < -0.5:
				continue
			LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(x, 2.4, z), n, 1.4, 5.0,
				LandmarkFrParts.HEAD_POINTED, 0.26, 0.12, 1)
		for k2 in 3:
			LandmarkFrParts.buttress(lm, "Stone", Vector3(-9.2 + 9.2 * float(k2) + 2.3, 0, z), n, 1.2, 1.4, 7.6, 2)
	LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(12.5, 2.4, -12.2), Vector3(22.0, 2.4, -12.2),
		Vector3.FORWARD, 2, 1.3, 4.4, LandmarkFrParts.HEAD_POINTED, 0.26, 0.12, 1)
	LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(-4.45, 0.0, 10.4), Vector3.BACK, 1.6, 3.0,
		LandmarkFrParts.HEAD_POINTED, 0.28, 0.14)
	LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(15.75, 0.0, 16.3), Vector3.BACK, 1.6, 3.0,
		LandmarkFrParts.HEAD_POINTED, 0.28, 0.14)
	# Tower: whitewashed stone base, clock stage and belfry with arched
	# openings, cornices, the octagonal lantern, slim steeple, ball, cross.
	var cx := -18.3
	var cz := -7.1
	LandmarkFrKit.tower(lm, "Trim", "Trim", cx, cz, 4.1, 0.0, 14.0, 0.0)
	LandmarkFrKit.rect(lm, "Trim", cx - 4.4, cx + 4.4, cz - 4.4, cz + 4.4, 0.0, 0.9)
	LandmarkFrParts.cornice_ring(lm, "Trim", cx - 4.1, cx + 4.1, cz - 4.1, cz + 4.1, 13.4, 0.8)
	LandmarkFrKit.rect(lm, "Trim", cx - 4.4, cx + 4.4, cz - 4.4, cz + 4.4, 13.6, 14.4)
	LandmarkFrKit.tower(lm, "Trim", "Trim", cx, cz, 3.5, 14.4, 21.5, 0.0)
	LandmarkFrKit.clocks(lm, "Gilt", "Wall", cx, cz, 3.5, 18.0, 1.4)
	LandmarkFrKit.tower(lm, "Trim", "Trim", cx, cz, 3.1, 21.5, 26.0, 0.0)
	LandmarkFrParts.corner_strips(lm, "Trim", cx - 3.5, cx + 3.5, cz - 3.5, cz + 3.5, 14.4, 21.4, 0.5, 0.1)
	LandmarkFrParts.corner_strips(lm, "Trim", cx - 3.1, cx + 3.1, cz - 3.1, cz + 3.1, 21.5, 25.8, 0.45, 0.1)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		var tc := Vector3(cx, 0, cz)
		LandmarkFrParts.opening(lm, "Trim", "Roof", tc + fn * 3.1 + Vector3(0, 22.3, 0), fn, 1.6, 2.9,
			LandmarkFrParts.HEAD_ROUND, 0.2, 0.12)
		LandmarkFrParts.louvre(lm, "Roof", tc + fn * 3.12 + Vector3(0, 22.3, 0), fn, 1.5, 2.0, 6)
		LandmarkFrParts.opening(lm, "Trim", "Glass", tc + fn * 4.1 + Vector3(0, 7.0, 0), fn, 1.0, 2.2,
			LandmarkFrParts.HEAD_ROUND, 0.18, 0.1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(cx - 4.1, 0.0, cz), Vector3.LEFT, 1.8, 3.2,
		LandmarkFrParts.HEAD_ROUND, 0.3, 0.16)
	LandmarkFrKit.rect(lm, "Trim", cx - 3.5, cx + 3.5, cz - 3.5, cz + 3.5, 25.8, 26.5)
	LandmarkFrKit.lantern(lm, "Trim", "Trim", cx, cz, 2.6, 26.5, 4.0, 6.0)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var on := Vector3(cos(a), 0, sin(a))
		LandmarkFrParts.opening(lm, "", "Roof", Vector3(cx, 27.3, cz) + on * 2.48, on, 0.7, 1.9,
			LandmarkFrParts.HEAD_ROUND)
	lm.lathe("Gilt", Vector3(cx, 36.8, cz), LandmarkFrKit.ball(0.4), 10)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(cx, 37.5, cz), 1.0)
	lm.commit(model)

## Rauma: grey stone walls to the eaves, a shingle roof with its trim and
## brick gables (ridge along X when ridge_x = 1, Z when 0).
static func _stone_house(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, eave: float, rise: float,
		over: float, ridge_x: int) -> void:
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, 0.0, eave)
	LandmarkFrKit.gable(lm, "Roof", x0, x1, z0, z1, eave, rise, over, "Brick", ridge_x)
	LandmarkFrParts.roof_trim(lm, "Roof", x0, x1, z0, z1, eave, rise, over, ridge_x, 0.28)
