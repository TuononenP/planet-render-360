class_name LandmarkWhCathedrals
extends RefCounted

## Two great French Gothic cathedrals in true metres, y = 0 at the
## parvis, nave along X with the west front at -X: Chartres and
## Strasbourg.

## Chartres Cathedral (113 m to the cross of the Gothic north spire):
## the west front with the Royal Portal, three lancets and the rose
## between the two unequal towers (the plain 105 m Romanesque south
## tower, the Flamboyant 113 m north tower), the nave and choir with
## their steep green copper roofs and double flying buttresses, the
## deep transept porches under rose windows, and the apse ringed by the
## ambulatory and its radiating chapels.
static func chartres(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C8BDA2", 3.5))
	lm.use("Core", LandmarkMaterials.pbr("stone", "#8A7E6A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6D9C84", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#27385A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Nave and choir body: vessel 20 m wide to 36 m, aisles to 17 m.
	LandmarkWestKit.blk(lm, "Stone", -37.0, 0, 0, 56.0, 36.0, 20.0)
	LandmarkWestKit.blk(lm, "Stone", -37.0, 0, 0, 56.0, 17.0, 38.0)
	lm.gable("Roof", Vector3(-37.0, 36.0, 0), 20.0, 56.0, 12.5, rot, 0.3, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 22.5, 0, 0, 27.0, 36.0, 20.0)
	LandmarkWestKit.blk(lm, "Stone", 22.5, 0, 0, 27.0, 17.0, 38.0)
	lm.gable("Roof", Vector3(22.5, 36.0, 0), 20.0, 27.0, 12.5, rot, 0.3, "Stone")
	for sx in [-37.0, 22.5]:
		var half := 28.0 if sx < 0.0 else 13.5
		for sz in [-1.0, 1.0]:
			lm.quad("Roof", Vector3(sx - half, 17.4, sz * 19.4), Vector3(sx + half, 17.4, sz * 19.4),
				Vector3(sx + half, 24.5, sz * 10.0), Vector3(sx - half, 24.5, sz * 10.0),
				Vector3(0, 9.4, sz * 7.1).normalized())
	# Transept: 64 m across, rose windows over the deep three-portal porches.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 18.0, 36.0, 64.0)
	lm.gable("Roof", Vector3(0, 36.0, 0), 18.0, 64.0, 12.0, Basis(), 0.3, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.rose(lm, "Glass", "Stone", Vector3(0, 28.0, sz * 32.2), Vector3(0, 0, sz), 5.2, 16)
		LandmarkWestKit.blk(lm, "Stone", 0, 0, sz * 36.0, 22.0, 14.0, 8.0)
		lm.gable("Stone", Vector3(0, 14.0, sz * 36.0), 22.0, 8.0, 7.0, Basis(), 0.0, "Stone")
		for px in [-7.0, 0.0, 7.0]:
			LandmarkWhKit.lancet(lm, "Glass", Vector3(px, 0, sz * 40.1), Vector3(0, 0, sz), 4.2, 5.5, 3.4)
		LandmarkWhKit.lancet(lm, "Glass", Vector3(0, 21.0, sz * 32.2), Vector3(0, 0, sz), 3.0, 4.5, 2.4)
	# Apse (centre x = 36), ambulatory and radiating chapels.
	lm.lathe("Stone", Vector3(36, 0, 0), PackedVector2Array([Vector2(10, 0), Vector2(10, 36.0)]), 16,
		1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(36, 36.0, 0), PackedVector2Array([Vector2(10.3, 0), Vector2(0, 12.5)]), 16)
	lm.lathe("Stone", Vector3(36, 0, 0), PackedVector2Array([Vector2(19, 0), Vector2(19, 17.0)]), 20,
		1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(36, 17.2, 0), PackedVector2Array([Vector2(19.5, 0), Vector2(9.8, 7.3)]), 20,
		1.0, 1.0, 0.0, true, false)
	for k in 5:
		var a := deg_to_rad(-72.0 + 36.0 * float(k))
		var cp := Vector3(36.0 + cos(a) * 23.0, 0, sin(a) * 23.0)
		var cr := 5.5 if k == 2 else 4.5
		lm.frustum("Stone", cp, cr, cr, 13.0, 10)
		lm.lathe("Roof", cp + Vector3(0, 13.0, 0), PackedVector2Array([Vector2(cr + 0.4, 0), Vector2(0, 5.0)]), 10)
		LandmarkWhKit.lancet(lm, "Glass", cp + Vector3(cos(a), 0, sin(a)) * (cr + 0.1) + Vector3(0, 3.0, 0),
			Vector3(cos(a), 0, sin(a)), 1.8, 5.0, 2.0)
	# Windows on the aisle and clerestory walls, bay by bay.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for x0 in [-50.0, 11.0]:
			var bays := 6 if x0 < 0.0 else 4
			LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, sz * 19.0), Vector3(x0 + 6.2 * float(bays), 0, sz * 19.0),
				n, bays, 2.4, 7.5, 6.0, 2.4)
			LandmarkWhKit.lancet_row(lm, "Glass", Vector3(x0, 0, sz * 10.0), Vector3(x0 + 6.2 * float(bays), 0, sz * 10.0),
				n, bays * 2, 1.7, 7.5, 24.0, 2.2)
		# Double flying buttresses: pier, pinnacle, lower and upper flyers.
		for bx in [-50.0, -43.8, -37.6, -31.4, -25.2, -19.0, -12.8, 11.0, 17.2, 23.4, 29.6, 35.8]:
			LandmarkWestKit.blk(lm, "Stone", bx, 0, sz * 22.5, 1.8, 20.0, 2.6)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(bx, 20.0, sz * 22.5), 0.8, 2.0, 4.5)
			LandmarkWhKit.flyer(lm, "Stone", Vector3(bx, 21.0, sz * 21.2), Vector3(bx, 27.0, sz * 10.2), 1.0)
			LandmarkWhKit.flyer(lm, "Stone", Vector3(bx, 24.5, sz * 21.2), Vector3(bx, 32.0, sz * 10.2), 1.0)
	# West front between the towers: portals, Gallery of Kings, lancets, rose.
	var wn := Vector3(-1, 0, 0)
	for p in [[0.0, 4.4, 6.0], [-6.8, 3.4, 5.0], [6.8, 3.4, 5.0]]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-65.15, 0, p[0]), wn, p[1], p[2], p[1] * 0.8)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-65.1, 0, -9.0), Vector3(-65.1, 0, 9.0), wn, 16, 0.7, 1.4, 11.5, 0.8)
	for lz in [-5.4, 0.0, 5.4]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-65.15, 14.0, lz), wn, 2.4, 9.0 if lz == 0.0 else 8.0, 2.6)
	LandmarkWhKit.rose(lm, "Glass", "Stone", Vector3(-65.2, 31.0, 0), wn, 5.2, 16)
	for bz in [-10.2, -3.4, 3.4, 10.2]:
		LandmarkWestKit.blk(lm, "Stone", -65.4, 0, bz, 1.0, 36.0, 1.0)
	# West towers: the plain 105 m Romanesque south tower (+Z), the
	# 113 m Flamboyant north tower (-Z).
	for sz in [-1.0, 1.0]:
		var c := Vector3(-58.0, 0, sz * 17.5)
		var top := 70.0 if sz < 0.0 else 66.0
		LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 14.0, 30.0, 14.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 30.0, c.z, 13.2, top - 30.0, 13.2)
		LandmarkWestKit.blk(lm, "Stone", c.x, 30.0, c.z, 14.4, 0.8, 14.4)
		LandmarkWestKit.blk(lm, "Stone", c.x, top, c.z, 14.0, 0.8, 14.0)
		var faces := [Vector3(-1, 0, 0), Vector3(0, 0, sz), Vector3(1, 0, 0)]
		for f in faces:
			var fn: Vector3 = f
			var fp := c + fn * 6.7
			var half := LandmarkWhKit.along(fn) * 3.6
			LandmarkWhKit.lancet_row(lm, "Glass", fp - half, fp + half, fn, 3, 1.1, 5.0, 14.0, 1.3)
			LandmarkWhKit.lancet_row(lm, "Glass", fp - half, fp + half, fn, 3, 1.1, 6.0, 38.0, 1.3)
			var bell := top - 12.0
			LandmarkWhKit.lancet_row(lm, "Glass", fp - half * 0.9, fp + half * 0.9, fn, 2, 2.4, 6.5, bell, 3.0)
		for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
			LandmarkWhKit.pinnacle(lm, "Stone", c + Vector3(q.x * 6.4, top + 0.8, q.y * 6.4), 0.7,
				3.0 if sz > 0.0 else 8.0, 3.5 if sz > 0.0 else 7.0)
	var south := Vector3(-58.0, 66.8, 17.5)
	lm.spire("Stone", south, 5.6, 37.7, 0.0, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkWhKit.lancet(lm, "Glass", south + Vector3(cos(a), 0, sin(a)) * 5.5 + Vector3(0, 6.0, 0),
			Vector3(cos(a), 0, sin(a)), 1.0, 5.0, 1.4)
	LandmarkWhKit.ball(lm, "Gilt", south + Vector3(0, 37.6, 0), 0.5)
	var north := Vector3(-58.0, 70.8, -17.5)
	LandmarkWhKit.open_spire(lm, "Core", "Stone", north, 5.4, 41.2, 8, 7)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.gable("Stone", north + d * 4.4 + Vector3(0, 8.0, 0), 2.2, 1.6, 4.5,
			Basis(Vector3.UP, atan2(d.x, d.z)), 0.0, "Stone")
	LandmarkWestKit.cross(lm, "Gilt", north + Vector3(0, 41.1, 0), 1.2)
	lm.commit(model)

## Strasbourg Cathedral (142 m): red Vosges sandstone. The 66 m west
## front screened by its lacework of slender mullions over the three
## portals and the great rose, the platform joining the one finished
## north tower to the stump of the south tower, the octagonal belfry
## with its four stair turrets and the openwork pyramid spire of
## eight stages; behind it the nave, the short transept with the
## Romanesque crossing lantern, and the round-ended choir.
static func strasbourg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#B77C66", 3.5))
	lm.use("Core", LandmarkMaterials.pbr("stone", "#7B4F40", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6D9C84", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#27385A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Nave (62 m), aisles, short transept, choir and its Romanesque apse.
	LandmarkWestKit.blk(lm, "Pink", -25.0, 0, 0, 62.0, 33.0, 17.0)
	LandmarkWestKit.blk(lm, "Pink", -25.0, 0, 0, 62.0, 16.0, 34.0)
	lm.gable("Roof", Vector3(-25.0, 33.0, 0), 17.0, 62.0, 13.0, rot, 0.3, "Pink")
	LandmarkWestKit.blk(lm, "Pink", 15.0, 0, 0, 18.0, 33.0, 44.0)
	lm.gable("Roof", Vector3(15.0, 33.0, 0), 18.0, 44.0, 12.0, Basis(), 0.3, "Pink")
	LandmarkWestKit.blk(lm, "Pink", 35.0, 0, 0, 22.0, 28.0, 17.0)
	lm.gable("Roof", Vector3(35.0, 28.0, 0), 17.0, 22.0, 11.0, rot, 0.3, "Pink")
	lm.lathe("Pink", Vector3(46, 0, 0), PackedVector2Array([Vector2(8.5, 0), Vector2(8.5, 28.0)]), 14,
		1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(46, 28.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(0, 11.0)]), 14)
	for sx in [-25.0, 3.0]:
		var half := 31.0 if sx < 0.0 else 3.0
		for sz in [-1.0, 1.0]:
			lm.quad("Roof", Vector3(sx - half, 16.4, sz * 17.4), Vector3(sx + half, 16.4, sz * 17.4),
				Vector3(sx + half, 23.0, sz * 8.5), Vector3(sx - half, 23.0, sz * 8.5),
				Vector3(0, 8.9, sz * 6.6).normalized())
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.rose(lm, "Glass", "Pink", Vector3(15.0, 24.0, sz * 22.2), Vector3(0, 0, sz), 3.6, 12)
		var n := Vector3(0, 0, sz)
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-55, 0, sz * 17.0), Vector3(4, 0, sz * 17.0), n, 9, 2.2, 6.5, 5.0, 2.2)
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-55, 0, sz * 8.5), Vector3(4, 0, sz * 8.5), n, 18, 1.5, 7.0, 21.0, 2.0)
		for bx in [-48.0, -41.0, -34.0, -27.0, -20.0, -13.0, -6.0, 1.0]:
			LandmarkWestKit.blk(lm, "Pink", bx, 0, sz * 20.0, 1.6, 18.0, 2.4)
			LandmarkWhKit.pinnacle(lm, "Pink", Vector3(bx, 18.0, sz * 20.0), 0.7, 2.0, 4.0)
			LandmarkWhKit.flyer(lm, "Pink", Vector3(bx, 19.0, sz * 19.0), Vector3(bx, 26.0, sz * 8.6), 0.9)
	# Crossing lantern (Romanesque octagon with its copper cap).
	lm.lathe("Pink", Vector3(15, 33.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(6.2, 14.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	lm.lathe("Roof", Vector3(15, 47.0, 0), PackedVector2Array([Vector2(6.8, 0), Vector2(5.2, 3.0),
		Vector2(0.0, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	# West front: a 51 m screen up to the platform at 66 m.
	LandmarkWestKit.blk(lm, "Pink", -52.0, 0, 0, 12.0, 66.0, 51.0)
	var wn := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Pink", -58.1, 66.0, 0, 0.6, 1.2, 51.0)
	for p in [[0.0, 6.0, 6.5], [-10.0, 4.6, 5.5], [10.0, 4.6, 5.5]]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-58.1, 0, p[0]), wn, p[1], p[2], p[1] * 0.9)
		lm.gable("Pink", Vector3(-58.4, 9.0, p[0]), p[1] + 1.0, 1.4, 5.0, Basis(), 0.0, "Pink")
	for lz in [-21.0, -16.0, 16.0, 21.0]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-58.1, 14.0, lz), wn, 2.6, 11.0, 3.0)
	LandmarkWhKit.rose(lm, "Glass", "Pink", Vector3(-58.15, 33.0, 0), wn, 7.5, 16)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-58.1, 0, -9.0), Vector3(-58.1, 0, 9.0), wn, 5, 1.8, 11.0, 43.0, 2.4)
	# The screen of slender mullions standing before the wall.
	for k in 29:
		var z := -24.5 + 1.75 * float(k)
		LandmarkWestKit.blk(lm, "Pink", -58.7, 11.0 + 2.0 * absf(z) * 0.05, z, 0.4, 53.0, 0.4)
	for y in [24.0, 43.0, 62.0]:
		LandmarkWestKit.blk(lm, "Pink", -58.7, y, 0, 0.7, 0.6, 50.0)
	# North tower: square base to the platform, octagonal belfry, turrets, spire.
	var c := Vector3(-47.0, 66.0, -15.5)
	LandmarkWestKit.blk(lm, "Pink", c.x, 0, c.z, 20.0, 66.0, 20.0)
	lm.lathe("Pink", c, PackedVector2Array([Vector2(8.6, 0), Vector2(8.0, 28.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhKit.lancet(lm, "Glass", c + d * 7.9 + Vector3(0, 4.0, 0), d, 2.6, 12.0, 3.2)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tp := c + Vector3(q.x * 8.6, 0, q.y * 8.6)
		lm.frustum("Pink", tp, 2.0, 1.7, 34.0, 10)
		lm.lathe("Pink", tp + Vector3(0, 34.0, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.2, 6.0),
			Vector2(0.0, 14.0)]), 10)
	var sb := c + Vector3(0, 28.0, 0)
	lm.lathe("Pink", sb, PackedVector2Array([Vector2(8.4, 0), Vector2(7.0, 6.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.gable("Pink", sb + d * 6.4 + Vector3(0, 5.0, 0), 4.0, 2.4, 5.0, Basis(Vector3.UP, atan2(d.x, d.z)), 0.0, "Pink")
	LandmarkWhKit.open_spire(lm, "Core", "Pink", sb + Vector3(0, 6.0, 0), 5.8, 41.0, 8, 8)
	LandmarkWestKit.cross(lm, "Gilt", sb + Vector3(0, 47.0, 0), 1.2)
	# South tower: the unfinished stump, closed at platform level.
	LandmarkWestKit.blk(lm, "Pink", -47.0, 0, 15.5, 20.0, 66.0, 20.0)
	LandmarkWestKit.blk(lm, "Pink", -47.0, 66.0, 15.5, 20.6, 1.0, 20.6)
	lm.commit(model)
