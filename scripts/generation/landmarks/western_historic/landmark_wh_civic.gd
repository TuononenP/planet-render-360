class_name LandmarkWhCivic
extends RefCounted

## Three civic and spa landmarks in true metres, y = 0 at the street or
## pavement: the Roman Baths of Bath, Brussels Town Hall and the
## Belfry of Bruges.

## Roman Baths (49 m to the tip of the Abbey tower): the Great Bath
## (22 x 12 m, lead-lined, green water) in its pavement, ringed by the
## Victorian colonnade of Tuscan columns under the statue-lined terrace,
## the Georgian Pump Room behind it to the north (-Z), and beyond it
## Bath Abbey with its west front, ladder turrets and crossing tower.
static func roman_baths(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9C9A0", 3.5))
	lm.use("Paving", LandmarkMaterials.pbr("stone", "#9E9886", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#667078", 2.5))
	lm.use("Water", LandmarkMaterials.paint("#4F7F58", 0.1, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	# Pavement ring round the pool, lead floor, green water.
	for r in [[0.0, -9.0, 34.0, 6.0], [0.0, 9.0, 34.0, 6.0], [-14.0, 0.0, 6.0, 12.0], [14.0, 0.0, 6.0, 12.0]]:
		LandmarkWestKit.blk(lm, "Paving", r[0], -1.5, r[1], r[2], 1.5, r[3])
	LandmarkWestKit.blk(lm, "Slate", 0, -1.9, 0, 22.0, 0.4, 12.0)
	lm.quad("Water", Vector3(-11, -0.3, 6), Vector3(11, -0.3, 6), Vector3(11, -0.3, -6), Vector3(-11, -0.3, -6),
		Vector3.UP)
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Paving", sx * 11.0, -1.5, 0, 0.6, 1.5, 12.0)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Paving", 0, -1.5, sz * 6.0, 22.0, 1.5, 0.6)
	# Tuscan colonnade round the pool, entablature and the terrace above.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.col_row(lm, "Stone", Vector3(-15.0, 0, sz * 9.5), Vector3(15.0, 0, sz * 9.5), 12,
			0.55, 0.48, 6.4, 12)
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.col_row(lm, "Stone", Vector3(sx * 15.0, 0, -7.5), Vector3(sx * 15.0, 0, 7.5), 6,
			0.55, 0.48, 6.4, 12)
	for r in [[0.0, -9.5, 32.0, 2.4], [0.0, 9.5, 32.0, 2.4], [-15.0, 0.0, 2.4, 20.0], [15.0, 0.0, 2.4, 20.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 6.4, r[1], r[2], 1.1, r[3])
	for r in [[0.0, -13.0, 40.0, 5.0], [0.0, 13.0, 40.0, 5.0], [-18.0, 0.0, 4.0, 21.0], [18.0, 0.0, 4.0, 21.0]]:
		LandmarkWestKit.blk(lm, "Paving", r[0], 7.5, r[1], r[2], 0.5, r[3])
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.merlons(lm, "Stone", Vector3(-20, 8.0, sz * 15.5), Vector3(20, 8.0, sz * 15.5), 1.2, 0.5,
			1.0, 0.5)
		for k in 8:
			var px := -17.5 + 5.0 * float(k)
			LandmarkWestKit.blk(lm, "Stone", px, 8.0, sz * 10.8, 1.1, 1.6, 1.1)
			LandmarkKits.statue_figure(lm, "Stone", Vector3(px, 9.6, sz * 10.8), 2.7)
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.merlons(lm, "Stone", Vector3(sx * 20.0, 8.0, -12), Vector3(sx * 20.0, 8.0, 12), 1.2, 0.5,
			1.0, 0.5)
	# Georgian Pump Room to the north: columned pilasters, tall arched windows.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -32.0, 44.0, 14.0, 18.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 14.0, -32.0, 45.0, 1.0, 19.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(0, 15.0, -32.0), 40.0, 15.0, 2.5, 0.8)
	for k in 7:
		var px := -18.0 + 6.0 * float(k)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(px, 2.2, -22.9), Vector3(0, 0, 1), 3.2, 5.6)
		LandmarkWestKit.blk(lm, "Stone", px + 3.0, 0, -22.7, 0.9, 14.0, 0.6)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-4.5, 0, -24.5), Vector3(4.5, 0, -24.5), 4, 0.6, 0.5, 11.0, 12)
	LandmarkWestKit.blk(lm, "Stone", 0, 11.0, -24.5, 11.0, 1.4, 3.0)
	lm.gable("Stone", Vector3(0, 12.4, -24.5), 11.0, 3.0, 2.2, Basis(), 0.0, "Stone")
	# Bath Abbey beyond: nave, crossing tower (49 m), west front with turrets.
	var az := -52.0
	LandmarkWhKit.aisled_body(lm, "Stone", "Slate", "Glass", 50.0, 83.0, 6.5, 21.0, 10.5, 12.0, 4.0, 5, az)
	LandmarkWhKit.aisled_body(lm, "Stone", "Slate", "Glass", 95.0, 119.0, 6.5, 21.0, 10.5, 12.0, 4.0, 3, az)
	LandmarkWestKit.blk(lm, "Stone", 89.0, 0, az, 12.0, 21.0, 36.0)
	lm.gable("Slate", Vector3(89.0, 21.0, az), 12.0, 36.0, 3.5, Basis(), 0.3, "Stone")
	LandmarkWhKit.lancet(lm, "Glass", Vector3(49.9, 5.0, az), Vector3(-1, 0, 0), 4.5, 12.0, 3.4)
	for sz in [-1.0, 1.0]:
		lm.lathe("Stone", Vector3(50.8, 0, az + sz * 7.2), PackedVector2Array([Vector2(1.8, 0), Vector2(1.6, 26.0)]),
			8, 1.0, 1.0, PI / 8.0, false)
		lm.lathe("Stone", Vector3(50.8, 26.0, az + sz * 7.2), PackedVector2Array([Vector2(1.9, 0), Vector2(0, 5.0)]),
			8, 1.0, 1.0, PI / 8.0, false)
	LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(89.0, 0, az), 11.0, 43.2, 20.0,
		[Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)], 2.4, 2.6)
	LandmarkWhKit.shift(lm, Vector3(-48.6, 0, 27.2))
	lm.commit(model)

## Brussels Town Hall (96 m to the sword of Saint Michael): the Gothic
## hôtel de ville on the south side of the Grand-Place, front facing
## north (-Z). The long arcaded facade of two unequal wings (the east
## wing the earlier, with eleven arches), its tall mullioned windows,
## openwork parapet, steep slate roof with two rows of dormers, corner
## turrets with stone spires, and the off-centre belfry tower rising to
## its openwork spire crowned by the gilded archangel.
static func brussels_town_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC3A6", 3.5))
	lm.use("Core", LandmarkMaterials.pbr("stone", "#8A7E6A", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	var n := Vector3(0, 0, -1)
	# Front range (16 m deep, eaves 22 m, ridge 33 m), side wings and rear range.
	LandmarkWestKit.blk(lm, "Stone", 0.5, 0, 8.0, 67.0, 22.0, 16.0)
	lm.gable("Slate", Vector3(0.5, 22.0, 8.0), 16.0, 67.0, 11.0, rot, 0.5, "Stone")
	for sx in [-26.0, 27.0]:
		LandmarkWestKit.blk(lm, "Stone", sx, 0, 23.0, 14.0, 20.0, 14.0)
		lm.gable("Slate", Vector3(sx, 20.0, 23.0), 14.0, 14.0, 7.0, Basis(), 0.4, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 0.5, 0, 37.0, 67.0, 20.0, 14.0)
	lm.gable("Slate", Vector3(0.5, 20.0, 37.0), 14.0, 67.0, 7.0, rot, 0.4, "Stone")
	# Arcade (west wing 6 bays, east wing 11), two storeys of windows above.
	for w in [[-33.0, -3.0, 6], [-3.0, 34.0, 11]]:
		var x0: float = w[0]
		var x1: float = w[1]
		var cnt: int = w[2]
		var bay := (x1 - x0) / float(cnt)
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, -0.05), Vector3(x1, 0, -0.05), n, cnt, bay * 0.6, 4.2,
			0.2, bay * 0.5)
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, -0.05), Vector3(x1, 0, -0.05), n, cnt, bay * 0.42, 5.0,
			9.0, bay * 0.36)
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, -0.05), Vector3(x1, 0, -0.05), n, cnt, bay * 0.38, 3.4,
			16.0, bay * 0.3)
		for k in cnt + 1:
			LandmarkWestKit.blk(lm, "Stone", x0 + bay * float(k), 0, -0.45, 0.8, 21.0, 0.9)
		for k in cnt:
			var dx := x0 + bay * (float(k) + 0.5)
			LandmarkWhKit.dormer(lm, "Stone", "Glass", Vector3(dx, 24.0, 1.6), n, 1.8, 2.8)
			if k % 2 == 0:
				LandmarkWhKit.dormer(lm, "Stone", "Glass", Vector3(dx, 28.6, 5.0), n, 1.8, 2.4)
	LandmarkWestKit.blk(lm, "Stone", 0.5, 7.0, -0.35, 68.0, 0.8, 0.8)
	LandmarkWestKit.blk(lm, "Stone", 0.5, 14.5, -0.35, 68.0, 0.6, 0.7)
	LandmarkWestKit.merlons(lm, "Stone", Vector3(-33, 22.0, -0.3), Vector3(34, 22.0, -0.3), 1.6, 0.9, 1.1, 0.6)
	# Corner turrets with stone spires.
	for tx in [-33.5, -0.5, 34.5]:
		lm.lathe("Stone", Vector3(tx, 0, 0.3), PackedVector2Array([Vector2(2.4, 0), Vector2(2.4, 24.0)]), 8,
			1.0, 1.0, PI / 8.0, false)
		lm.lathe("Stone", Vector3(tx, 24.0, 0.3), PackedVector2Array([Vector2(2.7, 0), Vector2(0, 11.0)]), 8,
			1.0, 1.0, PI / 8.0, false)
		LandmarkWhKit.lancet(lm, "Glass", Vector3(tx, 9.0, 0.3 - 2.25), n, 0.8, 4.0, 0.8)
		LandmarkWhKit.lancet(lm, "Glass", Vector3(tx, 17.0, 0.3 - 2.25), n, 0.8, 3.5, 0.8)
	# The off-centre belfry tower: square stages to 46 m, octagon, spire.
	var tc := Vector3(-7.0, 0, 5.5)
	LandmarkWhKit.square_tower(lm, "Stone", "Glass", tc, 11.0, 46.0, 23.0,
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0)], 3.0, 4.0)
	var ob := tc + Vector3(0, 46.8, 0)
	lm.lathe("Stone", ob, PackedVector2Array([Vector2(4.8, 0), Vector2(4.4, 12.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkWhKit.lancet(lm, "Glass", ob + Vector3(cos(a), 0, sin(a)) * 4.35 + Vector3(0, 2.5, 0),
			Vector3(cos(a), 0, sin(a)), 1.3, 6.0, 1.8)
	lm.lathe("Stone", ob + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(5.4, 0), Vector2(5.4, 0.8)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		LandmarkWhKit.pinnacle(lm, "Stone", ob + Vector3(q.x * 4.6, 12.0, q.y * 4.6), 0.4, 2.0, 4.0)
	var sb := ob + Vector3(0, 12.6, 0)
	LandmarkWhKit.open_spire(lm, "Core", "Stone", sb, 4.0, 30.8, 8, 7)
	LandmarkWhKit.ball(lm, "Gilt", sb + Vector3(0, 30.6, 0), 0.7)
	LandmarkKits.statue_figure(lm, "Gilt", sb + Vector3(0, 32.0, 0), 4.6, true)
	LandmarkWhKit.shift(lm, Vector3(-0.5, 0, -21.0))
	lm.commit(model)

## Belfry of Bruges (83 m): the brick bell tower rising from the front
## of the Halle on the Markt (front north, -Z). Two plain brick stages
## of blind lancets to 47 m, the stone parapet with its four corner
## turrets, then the two octagonal stages with their balcony and
## crenellated crown; behind it the red-tiled Halle ranges round the
## inner courtyard (44 x 84 m).
static func bruges_belfry(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F4C3B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC6B0", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4D36", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	var rot := Basis(Vector3.UP, PI * 0.5)
	var n := Vector3(0, 0, -1)
	# Halle: front range, two side wings, rear range round the courtyard.
	LandmarkWestKit.blk(lm, "Brick", 0, 0, -7.0, 44.0, 13.0, 14.0)
	lm.gable("Tile", Vector3(0, 13.0, -7.0), 14.0, 44.0, 7.0, rot, 0.5, "Brick")
	for sx in [-17.0, 17.0]:
		LandmarkWestKit.blk(lm, "Brick", sx, 0, 28.0, 10.0, 13.0, 56.0)
		lm.gable("Tile", Vector3(sx, 13.0, 28.0), 10.0, 56.0, 5.0, Basis(), 0.4, "Brick")
	LandmarkWestKit.blk(lm, "Brick", 0, 0, 63.0, 44.0, 13.0, 14.0)
	lm.gable("Tile", Vector3(0, 13.0, 63.0), 14.0, 44.0, 7.0, rot, 0.5, "Brick")
	for sx in [-1.0, 1.0]:
		var x0: float = 6.75 * sx
		var x1: float = 22.0 * sx
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, -14.05), Vector3(x1, 0, -14.05), n, 5, 1.8, 3.8, 0.4, 1.4)
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, -14.05), Vector3(x1, 0, -14.05), n, 5, 1.2, 3.0, 6.5, 1.0)
		for k in 5:
			var dx := lerpf(x0, x1, (float(k) + 0.5) / 5.0)
			LandmarkWhKit.dormer(lm, "Brick", "Glass", Vector3(dx, 15.6, -9.5), n, 1.8, 2.4)
	# The tower: 13.5 m square, brick to 47 m with two stages.
	var tc := Vector3(0, 0, -7.25)
	LandmarkWestKit.blk(lm, "Brick", tc.x, 0, tc.z, 13.5, 28.0, 13.5)
	LandmarkWestKit.blk(lm, "Stone", tc.x, 28.0, tc.z, 14.0, 0.8, 14.0)
	LandmarkWestKit.blk(lm, "Brick", tc.x, 28.8, tc.z, 12.6, 18.4, 12.6)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(0, 0, -14.05), n, 3.4, 5.0, 2.6)
	for f in [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
		var fn: Vector3 = f
		var half := LandmarkWhKit.along(fn) * 2.6
		var fp := tc + fn * 6.8
		LandmarkWhKit.lancet_row(lm, "Glass", fp - half, fp + half, fn, 2, 1.1, 6.0, 14.0, 1.4)
		var fq := tc + fn * 6.35
		LandmarkWhKit.lancet_row(lm, "Glass", fq - half, fq + half, fn, 2, 1.4, 8.0, 33.0, 1.8)
	LandmarkWestKit.blk(lm, "Stone", tc.x, 47.2, tc.z, 14.2, 1.2, 14.2)
	var c := [Vector3(-6.9, 48.4, tc.z - 6.9), Vector3(6.9, 48.4, tc.z - 6.9), Vector3(6.9, 48.4, tc.z + 6.9),
		Vector3(-6.9, 48.4, tc.z + 6.9)]
	for i in 4:
		LandmarkWestKit.merlons(lm, "Stone", c[i], c[(i + 1) % 4], 1.5, 0.8, 1.0, 0.6)
		LandmarkWhKit.pinnacle(lm, "Stone", c[i], 0.55, 4.0, 3.2)
	# Octagonal stages: lower octagon, balcony, upper octagon, crown.
	var ob := Vector3(0, 48.4, tc.z)
	lm.lathe("Stone", ob, PackedVector2Array([Vector2(5.8, 0), Vector2(5.5, 18.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkWhKit.lancet(lm, "Glass", ob + Vector3(cos(a), 0, sin(a)) * 5.0 + Vector3(0, 4.0, 0),
			Vector3(cos(a), 0, sin(a)), 1.8, 9.0, 2.4)
	lm.lathe("Stone", ob + Vector3(0, 18.0, 0), PackedVector2Array([Vector2(6.9, 0), Vector2(6.9, 0.9)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkWhKit.crenel_ring(lm, "Stone", ob + Vector3(0, 18.9, 0), 6.7, 16, 1.2, 1.0, 0.7)
	var ub := ob + Vector3(0, 18.9, 0)
	lm.lathe("Stone", ub, PackedVector2Array([Vector2(4.8, 0), Vector2(4.4, 13.7)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkWhKit.lancet(lm, "Glass", ub + Vector3(cos(a), 0, sin(a)) * 4.1 + Vector3(0, 2.5, 0),
			Vector3(cos(a), 0, sin(a)), 1.4, 6.0, 1.8)
	lm.lathe("Stone", ub + Vector3(0, 13.7, 0), PackedVector2Array([Vector2(5.6, 0), Vector2(5.6, 1.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkWhKit.crenel_ring(lm, "Stone", ub + Vector3(0, 14.7, 0), 5.4, 12, 1.2, 1.0, 0.7)
	LandmarkWhKit.shift(lm, Vector3(0, 0, -28.0))
	lm.commit(model)
