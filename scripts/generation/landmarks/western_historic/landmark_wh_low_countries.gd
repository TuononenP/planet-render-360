class_name LandmarkWhLowCountries
extends RefCounted

## Two civic Gothic towers of the Low Countries in true metres, y = 0 at
## the square, the front facing north (-Z): Brussels Town Hall and the
## Belfry of Bruges.

## Brussels Town Hall (96 m to the sword of Saint Michael; 1401-55): the
## Gothic hôtel de ville on the south side of the Grand-Place. The long
## front of two unequal wings (the older east wing with eleven bays),
## the open arcade along the ground floor, two storeys of traceried
## cross windows with statues in canopied niches on every pier, the
## openwork parapet between octagonal corner turrets, the steep slate
## roof with two rows of dormers; and Jan van Ruysbroeck's off-centre
## tower (1449-55): the square shaft to above the roof, the square
## stage with four corner turrets, three diminishing octagonal stages
## ringed with pinnacles and flyers, and the openwork spire crowned by
## the gilded archangel slaying the dragon.
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
	# The arcade: an open gallery of pointed arches on slim piers.
	LandmarkWestKit.blk(lm, "Stone", 0.5, 7.0, -2.0, 68.0, 1.0, 4.0)
	for w in [[-33.0, -3.0, 6], [-3.0, 34.0, 11]]:
		var x0: float = w[0]
		var x1: float = w[1]
		var cnt: int = w[2]
		var bay := (x1 - x0) / float(cnt)
		for k in cnt + 1:
			var px := x0 + bay * float(k)
			LandmarkWestKit.blk(lm, "Stone", px, 0, -3.6, 0.8, 7.0, 0.8)
			LandmarkWestKit.blk(lm, "Stone", px, 0, -0.45, 0.8, 21.0, 0.9)
			# Statues in canopied niches up the piers, two storeys.
			for y in [9.6, 16.2]:
				LandmarkWhGothic.niche_statue(lm, "Stone", Vector3(px, y, -0.9), n, 1.8)
		for k in cnt:
			var dx := x0 + bay * (float(k) + 0.5)
			LandmarkWhGothic._run(lm, "Stone", LandmarkWhGothic._arch_pts(Vector3(dx, 0, -3.6), Vector3(-1, 0, 0),
				bay * 0.5 - 0.4, 4.2, 2.0, 3), n, 0.4, 0.6)
			LandmarkWhKit.lancet(lm, "Glass", Vector3(dx, 0.2, -0.05), n, bay * 0.55, 3.6, bay * 0.4)
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(dx, 9.0, -0.1), n, bay * 0.46, 4.6, bay * 0.3, 2, 0.25)
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(dx, 15.6, -0.1), n, bay * 0.42, 3.4, bay * 0.26, 2, 0.25)
			_dormer(lm, Vector3(dx, 24.0, 1.6), n, 1.8, 2.8)
			if k % 2 == 0:
				_dormer(lm, Vector3(dx, 28.6, 5.0), n, 1.6, 2.2)
	LandmarkWestKit.blk(lm, "Stone", 0.5, 14.5, -0.35, 68.0, 0.6, 0.7)
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-33.0, 22.0, -0.2), Vector3(34.0, 22.0, -0.2), n, 1.4, 1.2)
	# Octagonal corner turrets with stone spires and crockets.
	for tx in [-33.5, -0.5, 34.5]:
		var tc := Vector3(tx, 0, 0.3)
		lm.lathe("Stone", tc, PackedVector2Array([Vector2(2.4, 0), Vector2(2.4, 24.0)]), 8,
			1.0, 1.0, PI / 8.0, false)
		for y in [7.0, 14.5, 22.0]:
			lm.frustum("Stone", tc + Vector3(0, y, 0), 2.6, 2.6, 0.5, 8, PI / 8.0)
		LandmarkWhKit.crenel_ring(lm, "Stone", tc + Vector3(0, 24.0, 0), 2.45, 8, 0.8, 1.0, 0.35)
		lm.lathe("Stone", tc + Vector3(0, 24.0, 0), PackedVector2Array([Vector2(2.5, 0), Vector2(0, 11.0)]), 8,
			1.0, 1.0, PI / 8.0, false)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			for j in 4:
				var t := (float(j) + 0.6) / 4.6
				lm.box("Stone", tc + d * 2.4 * (1.0 - t) + Vector3(0, 24.0 + 11.0 * t, 0), Vector3(0.3, 0.35, 0.3),
					Basis(), 0.0)
		LandmarkWhGothic.window(lm, "Glass", "Stone", tc + Vector3(0, 9.0, -2.25), n, 0.8, 3.4, 0.8, 1, 0.2)
		LandmarkWhGothic.window(lm, "Glass", "Stone", tc + Vector3(0, 16.5, -2.25), n, 0.8, 3.0, 0.8, 1, 0.2)
	_brussels_tower(lm, Vector3(-7.0, 0, 5.5))
	LandmarkWhKit.shift(lm, Vector3(-0.5, 0, -21.0))
	lm.commit(model)

## A slate-roof dormer with a stone gable and glazed front.
static func _dormer(lm: LandmarkMesh, base: Vector3, n: Vector3, w: float, h: float) -> void:
	LandmarkWhKit.dormer(lm, "Stone", "Glass", base, n, w, h)
	LandmarkWhGothic.pinnacle(lm, "Stone", base + Vector3(0, h + w * 0.9, 0) + n * 0.8, 0.12, 0.3, 0.6)

## The town hall tower at `tc`: the square shaft (to 36 m) with its
## clasping buttresses and the archway, the square stage with corner
## turrets to 46 m, three octagonal stages with pinnacles and flyers,
## the openwork spire and Saint Michael (5 m, 1455) at the top.
static func _brussels_tower(lm: LandmarkMesh, tc: Vector3) -> void:
	var n := Vector3(0, 0, -1)
	LandmarkWhKit.square_tower(lm, "Stone", "Glass", tc, 11.0, 46.0, 23.0,
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0)], 3.0, 4.0)
	LandmarkWhGothic.window(lm, "Glass", "Stone", tc + Vector3(0, 0.2, -5.55), n, 3.6, 4.2, 2.2, 1, 0.5)
	# Corner turrets on the square stage.
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tp := tc + Vector3(q.x * 5.4, 34.0, q.y * 5.4)
		lm.frustum("Stone", tp, 1.1, 1.0, 12.0, 8, PI / 8.0)
		lm.frustum("Stone", tp + Vector3(0, 6.0, 0), 1.25, 1.25, 0.3, 8, PI / 8.0)
	# Octagonal stages, each a little narrower, with a pinnacle on every
	# angle buttress and a flyer back to the stage above.
	var stages := [[46.8, 4.8, 6.0], [52.8, 4.3, 5.0], [57.8, 3.7, 4.6]]
	for st in stages:
		var y0: float = st[0]
		var r: float = st[1]
		var sh: float = st[2]
		var ob := tc + Vector3(0, y0, 0)
		lm.lathe("Stone", ob, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.96, sh)]), 8, 1.0, 1.0, PI / 8.0, false)
		lm.frustum("Stone", ob + Vector3(0, sh - 0.4, 0), r * 1.1, r * 1.1, 0.4, 8, PI / 8.0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkWhGothic.window(lm, "Glass", "Stone", ob + d * r * 0.92 + Vector3(0, sh * 0.15, 0), d, r * 0.32,
				sh * 0.5, r * 0.22, 1, 0.2)
			var pd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
			LandmarkWhGothic.pinnacle(lm, "Stone", ob + pd * (r + 0.3) + Vector3(0, sh * 0.5, 0), 0.3, sh * 0.5, 1.8)
			LandmarkWhKit.flyer(lm, "Stone", ob + pd * (r + 0.3) + Vector3(0, sh * 0.8, 0),
				ob + pd * r * 0.8 + Vector3(0, sh + 1.6, 0), 0.2, 0.2)
	var sb := tc + Vector3(0, 62.4, 0)
	LandmarkWhKit.open_spire(lm, "Core", "Stone", sb, 3.4, 28.4, 8, 7)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 5:
			var t := (float(j) + 0.5) / 5.5
			lm.box("Stone", sb + d * 3.6 * (1.0 - t) + Vector3(0, 28.4 * t, 0), Vector3(0.35, 0.4, 0.35), Basis(), 0.0)
	LandmarkWhKit.ball(lm, "Gilt", sb + Vector3(0, 28.2, 0), 0.7)
	# Saint Michael with the dragon at his feet.
	var mb := sb + Vector3(0, 29.6, 0)
	lm.beam("Gilt", mb + Vector3(-1.2, 0.2, 0), mb + Vector3(1.2, 0.4, 0.3), 0.6, 0.5)
	LandmarkKits.statue_figure(lm, "Gilt", mb + Vector3(0, 0.4, 0), 4.6, true)
	for s in [-1.0, 1.0]:
		lm.beam("Gilt", mb + Vector3(s * 0.4, 3.4, 0.3), mb + Vector3(s * 1.4, 4.4, 0.8), 0.9, 0.08)

## Belfry of Bruges (83 m; leaning about 87 cm east): the brick bell
## tower rising from the front of the Halle on the Markt (front north,
## -Z). The two square brick stages (13th century) to 47 m with their
## clasping buttresses, the stone parapet with its four corner turrets,
## then the octagonal stage of 1482-86 with tall lancets between angle
## buttresses, its balcony, the upper octagon and the crenellated crown
## with its corner pinnacles; behind it the Halle ranges round the inner
## courtyard (44 x 84 m) with their corner turrets and dormers.
static func bruges_belfry(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F4C3B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC6B0", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4D36", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
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
	LandmarkWestKit.blk(lm, "Stone", 0, 6.0, -14.15, 44.0, 0.4, 0.4)
	for sx in [-1.0, 1.0]:
		var x0: float = 6.75 * sx
		var x1: float = 22.0 * sx
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(x0, 0, -14.0), Vector3(x1, 0, -14.0), n, 5, 1.8, 3.6,
			0.6, 1.4, 2, 0.25)
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(x0, 0, -14.0), Vector3(x1, 0, -14.0), n, 5, 1.2, 3.0,
			7.0, 1.0, 1, 0.25)
		for k in 5:
			var dx := lerpf(x0, x1, (float(k) + 0.5) / 5.0)
			LandmarkWhKit.dormer(lm, "Brick", "Glass", Vector3(dx, 15.6, -9.5), n, 1.8, 2.4)
		# Corner turrets of the Halle front.
		var tc := Vector3(x1, 0, -14.0)
		lm.frustum("Brick", tc, 1.4, 1.4, 15.0, 8, PI / 8.0)
		LandmarkWhKit.crenel_ring(lm, "Stone", tc + Vector3(0, 15.0, 0), 1.35, 6, 0.6, 0.8, 0.3)
		lm.lathe("Tile", tc + Vector3(0, 15.0, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(0, 5.0)]), 8,
			1.0, 1.0, PI / 8.0, false)
		LandmarkWhGothic.parapet(lm, "Stone", Vector3(x0, 13.0, -14.0), Vector3(x1 - sx * 1.4, 13.0, -14.0), n, 1.0, 1.2,
			0.3)
	# The tower: 13.5 m square, brick to 47 m with two stages.
	var tc2 := Vector3(0, 0, -7.25)
	LandmarkWestKit.blk(lm, "Brick", tc2.x, 0, tc2.z, 13.5, 28.0, 13.5)
	LandmarkWestKit.blk(lm, "Stone", tc2.x, 28.0, tc2.z, 14.0, 0.8, 14.0)
	LandmarkWestKit.blk(lm, "Brick", tc2.x, 28.8, tc2.z, 12.6, 18.4, 12.6)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(0, 0.2, -14.0), n, 3.4, 5.0, 2.6, 1, 0.5)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		for o in [Vector3(q.x, 0, 0), Vector3(0, 0, q.y)]:
			var ov: Vector3 = o
			var side := Vector3(0, 0, q.y) if ov.x != 0.0 else Vector3(q.x, 0, 0)
			LandmarkWhGothic.buttress(lm, "Brick", tc2 + ov * 6.75 + side * 6.0, ov, 1.2, 1.2, 28.0, 3)
	for f in [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
		var fn: Vector3 = f
		var half := LandmarkWhKit.along(fn) * 2.6
		var fp := tc2 + fn * 6.75
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 2, 1.1, 6.0, 14.0, 1.4, 1, 0.25)
		var fq := tc2 + fn * 6.3
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", fq - half, fq + half, fn, 2, 1.6, 8.0, 31.0, 1.8, 2, 0.3)
	# The clock dial on the front of the upper brick stage.
	lm.disc("Stone", Vector3(0, 43.0, -13.6), n, 1.9, 24)
	lm.disc("Gilt", Vector3(0, 43.0, -13.65), n, 1.6, 24)
	lm.box("Brick", Vector3(0, 43.4, -13.7), Vector3(0.12, 1.1, 0.05), Basis(), 0.0)
	lm.box("Brick", Vector3(0.4, 43.0, -13.7), Vector3(0.8, 0.12, 0.05), Basis(), 0.0)
	LandmarkWestKit.blk(lm, "Stone", tc2.x, 47.2, tc2.z, 14.2, 1.2, 14.2)
	var c := [Vector3(-6.9, 48.4, tc2.z - 6.9), Vector3(6.9, 48.4, tc2.z - 6.9), Vector3(6.9, 48.4, tc2.z + 6.9),
		Vector3(-6.9, 48.4, tc2.z + 6.9)]
	for i in 4:
		LandmarkWestKit.merlons(lm, "Stone", c[i], c[(i + 1) % 4], 1.5, 0.8, 1.0, 0.6)
		var cp: Vector3 = c[i]
		lm.frustum("Stone", cp - Vector3(0, 6.0, 0), 0.9, 0.9, 7.4, 8, PI / 8.0)
		LandmarkWhGothic.pinnacle(lm, "Stone", cp + Vector3(0, 1.4, 0), 0.55, 2.6, 3.2)
	# Octagonal stages: lower octagon with angle buttresses, balcony,
	# upper octagon, crenellated crown with its pinnacles.
	var ob := Vector3(0, 48.4, tc2.z)
	lm.lathe("Stone", ob, PackedVector2Array([Vector2(5.8, 0), Vector2(5.5, 18.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhGothic.window(lm, "Glass", "Stone", ob + d * 5.05 + Vector3(0, 4.0, 0), d, 1.8, 9.0, 2.4, 2, 0.3)
		var pd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWhGothic.buttress(lm, "Stone", ob + pd * 5.7, pd, 0.7, 0.9, 17.0, 3)
	lm.lathe("Stone", ob + Vector3(0, 18.0, 0), PackedVector2Array([Vector2(6.9, 0), Vector2(6.9, 0.9)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkWhKit.crenel_ring(lm, "Stone", ob + Vector3(0, 18.9, 0), 6.7, 16, 1.2, 1.0, 0.7)
	var ub := ob + Vector3(0, 18.9, 0)
	lm.lathe("Stone", ub, PackedVector2Array([Vector2(4.8, 0), Vector2(4.4, 13.7)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhGothic.window(lm, "Glass", "Stone", ub + d * 4.2 + Vector3(0, 2.5, 0), d, 1.4, 6.0, 1.8, 2, 0.25)
		var pd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWhGothic.buttress(lm, "Stone", ub + pd * 4.75, pd, 0.6, 0.7, 12.5, 2)
	lm.lathe("Stone", ub + Vector3(0, 13.7, 0), PackedVector2Array([Vector2(5.6, 0), Vector2(5.6, 1.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkWhKit.crenel_ring(lm, "Stone", ub + Vector3(0, 14.7, 0), 5.4, 12, 1.2, 1.0, 0.7)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		LandmarkWhGothic.pinnacle(lm, "Stone", ub + Vector3(cos(a) * 5.4, 14.7, sin(a) * 5.4), 0.25, 0.5, 0.9)
	LandmarkWhKit.shift(lm, Vector3(0, 0, -28.0))
	lm.commit(model)
