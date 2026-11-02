class_name LandmarkWhCathedrals
extends RefCounted

## Two great French Gothic cathedrals in true metres, y = 0 at the
## parvis, nave along X with the west front at -X: Chartres and
## Strasbourg.

## Chartres Cathedral (113 m to the cross of the Gothic north spire;
## 130 m long, transept 64 m): the west front with the Royal Portal
## (c. 1145) of three round-headed doorways in stepped archivolts and
## column statues, the three lancets, the 12 m rose and the Gallery of
## Kings under the gable, between the two unequal towers (the plain
## 105 m Romanesque south tower with its octagonal stone spire, the
## Flamboyant 113 m north spire of 1513); the nave and choir with their
## steep green copper roofs, paired clerestory lancets under a rose in
## every bay (plate tracery) and double flying buttresses on stepped
## piers; the deep three-bay transept porches under the 10.5 m roses;
## the apse ringed by the ambulatory and its radiating chapels.
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
		var n := Vector3(0, 0, sz)
		LandmarkWhKit.rose(lm, "Glass", "Stone", Vector3(0, 28.0, sz * 32.2), n, 5.2, 24)
		LandmarkWestKit.blk(lm, "Stone", 0, 0, sz * 36.0, 22.0, 14.0, 8.0)
		lm.gable("Stone", Vector3(0, 14.0, sz * 36.0), 22.0, 8.0, 7.0, Basis(), 0.0, "Stone")
		# The porch's three deep bays: pointed arches under gables with
		# column statues, pinnacles between.
		for px in [-7.0, 0.0, 7.0]:
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(px, 0.4, sz * 40.0), n, 4.2, 5.5, 3.4, 1, 0.6)
			lm.gable("Stone", Vector3(px, 10.5, sz * 40.2), 6.0, 0.8, 5.0, Basis(), 0.0, "Stone")
			for k in 2:
				LandmarkWhGothic.jamb_figure(lm, "Stone", Vector3(px - 2.7 + 5.4 * float(k), 1.2, sz * 40.5), 2.2)
		for px in [-10.5, -3.5, 3.5, 10.5]:
			LandmarkWhGothic.pinnacle(lm, "Stone", Vector3(px, 14.0, sz * 39.6), 0.7, 2.0, 4.0)
		for px in [-5.0, -1.7, 1.7, 5.0]:
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(px, 15.5, sz * 32.1), n, 1.5, 5.5, 1.2, 1, 0.3)
		LandmarkWhGothic.parapet(lm, "Stone", Vector3(-9.0, 36.0, sz * 32.0), Vector3(9.0, 36.0, sz * 32.0), n,
			1.2, 1.3)
		for px in [-9.0, 9.0]:
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(px, 0, sz * 32.0), n, 2.0, 3.0, 34.0, 4)
	_chartres_apse(lm)
	# Aisle lancets, the clerestory's paired lancets under a rose in every
	# bay, balustrades, and the double flyers on stepped piers.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for x0 in [-50.0, 11.0]:
			var bays := 6 if x0 < 0.0 else 4
			var x1: float = x0 + 6.2 * float(bays)
			var a0 := Vector3(x0, 0, sz * 19.0)
			LandmarkWhGothic.window_row(lm, "Glass", "Stone", a0, Vector3(x1, 0, sz * 19.0), n, bays, 2.4, 7.5, 6.0,
				2.4, 1, 0.3)
			LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(x0, 0, sz * 10.0), Vector3(x1, 0, sz * 10.0), n,
				bays, 4.4, 7.0, 24.0, 3.6, 2, 0.35)
			LandmarkWhGothic.parapet(lm, "Stone", Vector3(x0 - 3.0, 36.0, sz * 10.0), Vector3(x1 + 3.0, 36.0, sz * 10.0),
				n, 1.2, 1.4)
			LandmarkWhGothic.parapet(lm, "Stone", Vector3(x0 - 3.0, 17.0, sz * 19.0), Vector3(x1 + 3.0, 17.0, sz * 19.0),
				n, 1.0, 1.4)
		for bx in [-50.0, -43.8, -37.6, -31.4, -25.2, -19.0, -12.8, 11.0, 17.2, 23.4, 29.6, 35.8]:
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(bx, 0, sz * 19.0), n, 1.8, 4.8, 20.0, 3)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(bx, 20.0, sz * 22.5), 0.8, 2.0, 4.5)
			LandmarkWhKit.flyer(lm, "Stone", Vector3(bx, 21.0, sz * 21.2), Vector3(bx, 27.0, sz * 10.2), 1.0)
			LandmarkWhKit.flyer(lm, "Stone", Vector3(bx, 24.5, sz * 21.2), Vector3(bx, 32.0, sz * 10.2), 1.0)
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(bx, 17.0, sz * 10.0), n, 1.2, 1.0, 17.0, 2)
	_chartres_west(lm, rot)
	lm.commit(model)

## Apse (centre x = 36), ambulatory and the five radiating chapels.
static func _chartres_apse(lm: LandmarkMesh) -> void:
	lm.lathe("Stone", Vector3(36, 0, 0), PackedVector2Array([Vector2(10, 0), Vector2(10, 36.0)]), 16,
		1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(36, 36.0, 0), PackedVector2Array([Vector2(10.3, 0), Vector2(0, 12.5)]), 16)
	lm.lathe("Stone", Vector3(36, 0, 0), PackedVector2Array([Vector2(19, 0), Vector2(19, 17.0)]), 20,
		1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(36, 17.2, 0), PackedVector2Array([Vector2(19.5, 0), Vector2(9.8, 7.3)]), 20,
		1.0, 1.0, 0.0, true, false)
	for k in 7:
		var a := deg_to_rad(-67.5 + 22.5 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(36, 24.0, 0) + d * 9.95, d, 2.8, 7.0, 2.6, 2, 0.3)
		var bd := Vector3(cos(a + 0.2), 0, sin(a + 0.2))
		LandmarkWhKit.flyer(lm, "Stone", Vector3(36, 22.0, 0) + bd * 20.0, Vector3(36, 30.0, 0) + bd * 10.2, 0.9)
		LandmarkWhGothic.pinnacle(lm, "Stone", Vector3(36, 17.0, 0) + bd * 20.5, 0.7, 2.4, 4.0)
	for k in 5:
		var a := deg_to_rad(-72.0 + 36.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		var cp := Vector3(36.0 + cos(a) * 23.0, 0, sin(a) * 23.0)
		var cr := 5.5 if k == 2 else 4.5
		lm.frustum("Stone", cp, cr, cr, 13.0, 10)
		lm.lathe("Roof", cp + Vector3(0, 13.0, 0), PackedVector2Array([Vector2(cr + 0.4, 0), Vector2(0, 5.0)]), 10)
		for w in [-0.45, 0.45]:
			var wd := Vector3(cos(a + w), 0, sin(a + w))
			LandmarkWhGothic.window(lm, "Glass", "Stone", cp + wd * (cr - 0.05) + Vector3(0, 3.0, 0), wd, 1.4, 5.0,
				1.6, 1, 0.25)
		LandmarkWhGothic.buttress(lm, "Stone", cp + d * cr, d, 1.0, 1.4, 11.0, 2)

## West front between the towers, the two towers and their spires.
static func _chartres_west(lm: LandmarkMesh, rot: Basis) -> void:
	var wn := Vector3(-1, 0, 0)
	for p in [[0.0, 4.4, 6.0], [-6.8, 3.4, 5.0], [6.8, 3.4, 5.0]]:
		var pz: float = p[0]
		var pw: float = p[1]
		var ph: float = p[2]
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(-65.15, 0, pz), wn, pw, ph)
		for k in 4:
			LandmarkWhGothic.archivolt(lm, "Stone", Vector3(-65.1, ph, pz), wn, pw + 0.9 * float(k), 0.45,
				0.3 + 0.25 * float(k))
		for s2 in [-1.0, 1.0]:
			for k in 2:
				var sp := Vector3(-65.4 - 0.3 * float(k), 0, pz + s2 * (pw * 0.5 + 0.45 + 0.5 * float(k)))
				lm.frustum("Stone", sp, 0.16, 0.16, 1.4, 8)
				LandmarkWhGothic.jamb_figure(lm, "Stone", sp + Vector3(0, 1.4, 0), 2.6)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-65.1, 0, -9.0), Vector3(-65.1, 0, 9.0), wn, 16, 0.7, 1.4, 11.5, 0.8)
	LandmarkWestKit.blk(lm, "Stone", -65.5, 10.8, 0, 1.0, 0.6, 21.0)
	for lz in [-5.4, 0.0, 5.4]:
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-65.15, 14.0, lz), wn, 2.4, 9.0 if lz == 0.0 else 8.0,
			2.6, 1, 0.4)
	LandmarkWhGothic.rose(lm, "Glass", "Stone", Vector3(-65.2, 30.0, 0), wn, 6.0, 12)
	for bz in [-10.2, -3.4, 3.4, 10.2]:
		LandmarkWhGothic.buttress(lm, "Stone", Vector3(-65.0, 0, bz), wn, 1.0, 1.4, 36.0, 4)
	# The Gallery of Kings under the west gable.
	for k in 9:
		LandmarkWhGothic.niche_statue(lm, "Stone", Vector3(-65.3, 37.5, -6.4 + 1.6 * float(k)), wn, 2.2)
	lm.gable("Stone", Vector3(-65.6, 36.0, 0), 14.0, 1.0, 10.0, rot, 0.0, "Stone")
	# West towers: the plain 105 m Romanesque south tower (+Z), the
	# 113 m Flamboyant north tower (-Z).
	for sz in [-1.0, 1.0]:
		var c := Vector3(-58.0, 0, sz * 17.5)
		var top := 70.0 if sz < 0.0 else 66.0
		LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 14.0, 30.0, 14.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 30.0, c.z, 13.2, top - 30.0, 13.2)
		LandmarkWestKit.blk(lm, "Stone", c.x, 30.0, c.z, 14.4, 0.8, 14.4)
		LandmarkWestKit.blk(lm, "Stone", c.x, top, c.z, 14.0, 0.8, 14.0)
		# Flat Romanesque buttresses up the tower corners.
		for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
			for o in [Vector3(q.x, 0, 0), Vector3(0, 0, q.y)]:
				var ov: Vector3 = o
				var side := Vector3(0, 0, q.y) if ov.x != 0.0 else Vector3(q.x, 0, 0)
				LandmarkWhGothic.buttress(lm, "Stone", c + ov * 7.0 + side * 6.2, ov, 1.4, 1.6, top - 8.0, 4)
		var faces := [Vector3(-1, 0, 0), Vector3(0, 0, sz), Vector3(1, 0, 0)]
		for f in faces:
			var fn: Vector3 = f
			var fp := c + fn * 6.7
			var half := LandmarkWhKit.along(fn) * 3.6
			LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 3, 1.1, 5.0, 14.0, 1.3, 1, 0.3)
			LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 3, 1.1, 6.0, 38.0, 1.3, 1, 0.3)
			var bell := top - 12.0
			LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half * 0.9, fp + half * 0.9, fn, 2, 2.4, 6.5, bell,
				3.0, 2, 0.4)
		for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
			LandmarkWhKit.pinnacle(lm, "Stone", c + Vector3(q.x * 6.4, top + 0.8, q.y * 6.4), 0.7,
				3.0 if sz > 0.0 else 8.0, 3.5 if sz > 0.0 else 7.0)
	# The south spire: octagonal stone pyramid with lucarnes, scaled ribs.
	var south := Vector3(-58.0, 66.8, 17.5)
	lm.spire("Stone", south, 5.6, 37.7, 0.0, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhKit.lancet(lm, "Glass", south + d * 5.5 + Vector3(0, 6.0, 0), d, 1.0, 5.0, 1.4)
		lm.gable("Stone", south + d * 5.0 + Vector3(0, 9.6, 0), 1.8, 1.4, 3.2, Basis(Vector3.UP, atan2(d.x, d.z)),
			0.0, "Stone")
		var e := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * 6.06
		lm.beam("Stone", south + e, south + Vector3(0, 37.2, 0), 0.4, 0.4)
	LandmarkWhKit.ball(lm, "Gilt", south + Vector3(0, 37.6, 0), 0.5)
	# The north spire (Jehan de Beauce, 1507-13): an openwork Flamboyant
	# octagon ringed by gabled lucarnes and flying pinnacles.
	var north := Vector3(-58.0, 70.8, -17.5)
	LandmarkWhKit.open_spire(lm, "Core", "Stone", north, 5.4, 41.2, 8, 7)
	lm.frustum("Stone", north, 6.2, 6.0, 9.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhKit.lancet(lm, "Glass", north + d * 5.7 + Vector3(0, 1.5, 0), d, 1.6, 4.5, 1.4)
		lm.gable("Stone", north + d * 4.4 + Vector3(0, 8.0, 0), 2.2, 1.6, 4.5,
			Basis(Vector3.UP, atan2(d.x, d.z)), 0.0, "Stone")
		var pd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWhGothic.pinnacle(lm, "Stone", north + pd * 6.6, 0.45, 9.0, 4.0)
		LandmarkWhKit.flyer(lm, "Stone", north + pd * 6.6 + Vector3(0, 7.0, 0), north + pd * 5.0 + Vector3(0, 13.0, 0),
			0.35, 0.4)
	LandmarkWestKit.cross(lm, "Gilt", north + Vector3(0, 41.1, 0), 1.2)

## Strasbourg Cathedral (142 m; tallest building in the world 1647-
## 1874): red Vosges sandstone. The 66 m west front (Erwin von
## Steinbach, from 1277) screened by its "harp strings" of free-standing
## mullions over the three gabled portals and the 13.6 m rose, the
## Apostles' gallery, the belfry stage joining the one finished north
## tower to the stump of the south tower at the platform; the octagon
## (Ulrich von Ensingen, 1399-1419) with its four openwork stair
## turrets and Johann Hültz's spire (1439) climbed by tiers of small
## stair turrets up to the lantern and crown; behind it the aisled nave,
## the short transept with its roses, the Romanesque crossing lantern
## and the round-ended choir.
static func strasbourg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#B77C66", 3.5))
	lm.use("Core", LandmarkMaterials.pbr("stone", "#7B4F40", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6D9C84", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#27385A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Nave (seven bays), short transept, choir and its Romanesque apse.
	LandmarkWhKit.aisled_body(lm, "Pink", "Roof", "Glass", -46.0, 6.0, 8.5, 33.0, 17.0, 16.0, 13.0, 7)
	LandmarkWestKit.blk(lm, "Pink", 15.0, 0, 0, 18.0, 33.0, 44.0)
	lm.gable("Roof", Vector3(15.0, 33.0, 0), 18.0, 44.0, 12.0, Basis(), 0.3, "Pink")
	LandmarkWestKit.blk(lm, "Pink", 35.0, 0, 0, 22.0, 28.0, 17.0)
	lm.gable("Roof", Vector3(35.0, 28.0, 0), 17.0, 22.0, 11.0, rot, 0.3, "Pink")
	lm.lathe("Pink", Vector3(46, 0, 0), PackedVector2Array([Vector2(8.5, 0), Vector2(8.5, 28.0)]), 14,
		1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(46, 28.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(0, 11.0)]), 14)
	for k in 5:
		var a := deg_to_rad(-60.0 + 30.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(46, 14.0, 0) + d * 8.45, d, 1.8, 4.5)
		LandmarkWhGothic.archivolt(lm, "Pink", Vector3(46, 18.5, 0) + d * 8.45, d, 1.8, 0.35, 0.3)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		LandmarkWhKit.rose(lm, "Glass", "Pink", Vector3(15.0, 24.0, sz * 22.2), n, 3.6, 12)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(13.0, 1.0, sz * 22.1), n, 2.4, 3.6)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(17.0, 1.0, sz * 22.1), n, 2.4, 3.6)
		LandmarkWhGothic.window_row(lm, "Glass", "Pink", Vector3(26.0, 0, sz * 8.5), Vector3(44.0, 0, sz * 8.5), n, 3,
			2.2, 8.0, 12.0, 1.6, 2, 0.3)
		for px in [6.5, 23.5]:
			LandmarkWhGothic.buttress(lm, "Pink", Vector3(px, 0, sz * 22.0), n, 1.8, 2.0, 30.0, 3)
	# Crossing lantern (Romanesque octagon, arcaded, with its copper cap).
	lm.lathe("Pink", Vector3(15, 33.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(6.2, 14.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var fc := Vector3(15, 33.0, 0) + d * 5.73
		for s2 in [-1.0, 1.0]:
			LandmarkWhKit.arch_round(lm, "Glass", fc + LandmarkWhKit.along(d) * s2 * 1.1 + Vector3(0, 5.0, 0), d, 1.4, 4.0)
		LandmarkWhGothic.archivolt(lm, "Pink", fc + Vector3(0, 9.0, 0), d, 3.4, 0.3, 0.25)
	lm.frustum("Pink", Vector3(15, 46.4, 0), 6.7, 6.7, 0.6, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(15, 47.0, 0), PackedVector2Array([Vector2(6.8, 0), Vector2(5.2, 3.0),
		Vector2(0.0, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkWestKit.cross(lm, "Gilt", Vector3(15, 55.6, 0), 2.0)
	_strasbourg_front(lm)
	_strasbourg_tower(lm)
	lm.commit(model)

## The west front block: three portals under their wimpergs, the harp
## strings, the rose, the Apostles' gallery and the belfry stage.
static func _strasbourg_front(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "Pink", -52.0, 0, 0, 12.0, 66.0, 51.0)
	var wn := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Pink", -58.1, 66.0, 0, 0.6, 1.2, 51.0)
	for p in [[0.0, 6.0, 6.5], [-16.0, 4.6, 5.5], [16.0, 4.6, 5.5]]:
		var pz: float = p[0]
		var pw: float = p[1]
		var ph: float = p[2]
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-58.1, 0, pz), wn, pw, ph, pw * 0.9)
		for k in 4:
			LandmarkWhGothic._run(lm, "Pink", LandmarkWhGothic._arch_pts(Vector3(-58.2, 0, pz), Vector3(0, 0, -1),
				pw * 0.5 + 0.4 + 0.5 * float(k), ph, pw * 0.9 + 0.5 * float(k), 4), wn, 0.4, 0.4 + 0.3 * float(k))
		for s2 in [-1.0, 1.0]:
			for k in 3:
				LandmarkWhGothic.jamb_figure(lm, "Pink", Vector3(-58.8 - 0.3 * float(k), 1.4,
					pz + s2 * (pw * 0.5 + 0.6 + 0.55 * float(k))), 2.4)
		# The wimperg: a tall pierced gable over the portal with a statue.
		var gh := 14.0 if pz == 0.0 else 10.0
		lm.gable("Pink", Vector3(-59.2, ph + pw * 0.9, pz), pw + 3.0, 0.6, gh, Basis(Vector3.UP, PI * 0.5), 0.0, "Pink")
		LandmarkWhGothic.oculus(lm, "Glass", "Pink", Vector3(-59.55, ph + pw * 0.9 + gh * 0.35, pz), wn, pw * 0.28)
		LandmarkKits.statue_figure(lm, "Pink", Vector3(-59.2, ph + pw * 0.9 + gh, pz), 2.6)
		for s2 in [-1.0, 1.0]:
			LandmarkWhGothic.pinnacle(lm, "Pink", Vector3(-59.2, ph, pz + s2 * (pw * 0.5 + 1.8)), 0.5, 4.0 + gh * 0.5, 4.0)
	for lz in [-21.0, -11.0, 11.0, 21.0]:
		LandmarkWhGothic.window(lm, "Glass", "Pink", Vector3(-58.1, 22.0, lz), wn, 2.6, 11.0, 3.0, 2, 0.4)
	LandmarkWhGothic.rose(lm, "Glass", "Pink", Vector3(-58.15, 33.0, 0), wn, 6.8, 16)
	# Apostles' gallery over the rose, and the belfry stage's lancets.
	for k in 13:
		LandmarkWhGothic.niche_statue(lm, "Pink", Vector3(-58.6, 41.5, -9.0 + 1.5 * float(k)), wn, 2.0)
	LandmarkWhGothic.window_row(lm, "Glass", "Pink", Vector3(-58.1, 0, -9.0), Vector3(-58.1, 0, 9.0), wn, 3, 2.4,
		12.0, 46.0, 2.4, 2, 0.4)
	# The harp strings: free-standing mullions before the wall, tied by
	# horizontal bars and pointed heads.
	for k in 29:
		var z := -24.5 + 1.75 * float(k)
		LandmarkWestKit.blk(lm, "Pink", -58.9, 11.0 + 2.0 * absf(z) * 0.05, z, 0.35, 53.0, 0.35)
	for y in [24.0, 43.0, 62.0]:
		LandmarkWestKit.blk(lm, "Pink", -58.9, y, 0, 0.6, 0.6, 50.0)
		for k in 28:
			var z := -24.5 + 1.75 * (float(k) + 0.5)
			LandmarkWhGothic._run(lm, "Pink", LandmarkWhGothic._arch_pts(Vector3(-58.9, y - 2.2, z), Vector3(0, 0, -1),
				0.85, 0.0, 1.6, 2), wn, 0.2, 0.3)
	for bz in [-25.5, -9.5, 9.5, 25.5]:
		LandmarkWhGothic.buttress(lm, "Pink", Vector3(-58.0, 0, bz), wn, 1.6, 2.0, 64.0, 5)
	LandmarkWhGothic.parapet(lm, "Pink", Vector3(-58.3, 67.2, -5.5), Vector3(-58.3, 67.2, 25.5), wn, 1.3, 1.4)
	# South tower: the unfinished stump, closed at platform level, with the
	# watchman's lodge.
	LandmarkWestKit.blk(lm, "Pink", -47.0, 0, 15.5, 20.0, 66.0, 20.0)
	LandmarkWestKit.blk(lm, "Pink", -47.0, 66.0, 15.5, 20.6, 1.0, 20.6)
	LandmarkWestKit.blk(lm, "Pink", -44.0, 67.0, 18.0, 5.0, 3.0, 4.0)
	lm.gable("Roof", Vector3(-44.0, 70.0, 18.0), 5.0, 4.0, 2.0, Basis(), 0.3, "Pink")
	LandmarkWhGothic.parapet(lm, "Pink", Vector3(-57.3, 67.0, 25.6), Vector3(-36.7, 67.0, 25.6), Vector3(0, 0, 1),
		1.3, 1.4)
	LandmarkWhGothic.parapet(lm, "Pink", Vector3(-36.7, 67.0, 5.4), Vector3(-36.7, 67.0, 25.6), Vector3(1, 0, 0),
		1.3, 1.4)

## North tower: square base to the platform, the octagon with its four
## openwork stair turrets, Hültz's spire with its tiers of stair
## turrets, the lantern, the crown and the cross at 142 m.
static func _strasbourg_tower(lm: LandmarkMesh) -> void:
	var c := Vector3(-47.0, 66.0, -15.5)
	LandmarkWestKit.blk(lm, "Pink", c.x, 0, c.z, 20.0, 66.0, 20.0)
	lm.lathe("Pink", c, PackedVector2Array([Vector2(8.6, 0), Vector2(8.0, 28.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhGothic.window(lm, "Glass", "Pink", c + d * 7.9 + Vector3(0, 4.0, 0), d, 2.8, 15.0, 3.4, 2, 0.4)
		lm.gable("Pink", c + d * 7.6 + Vector3(0, 24.0, 0), 4.0, 1.0, 3.0, Basis(Vector3.UP, atan2(d.x, d.z)), 0.0,
			"Pink")
	# Openwork stair turrets: posts round an open newel, ringed at every
	# stage, each with its pierced pyramid top.
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tp := c + Vector3(q.x * 8.6, 0, q.y * 8.6)
		lm.frustum("Core", tp, 0.6, 0.6, 34.0, 8)
		for k in 6:
			var a := TAU * float(k) / 6.0
			lm.beam("Pink", tp + Vector3(cos(a), 0, sin(a)) * 1.8, tp + Vector3(cos(a), 0, sin(a)) * 1.6 + Vector3(0, 34.0, 0),
				0.3, 0.3)
		for j in 9:
			var y := 34.0 * float(j) / 8.0
			lm.frustum("Pink", tp + Vector3(0, y, 0), 1.95, 1.9, 0.35, 6)
		for k in 6:
			var a := TAU * float(k) / 6.0
			lm.beam("Pink", tp + Vector3(cos(a), 0, sin(a)) * 1.6 + Vector3(0, 34.0, 0), tp + Vector3(0, 46.0, 0), 0.25, 0.25)
		lm.frustum("Core", tp + Vector3(0, 34.0, 0), 0.9, 0.0, 12.0, 6)
	var sb := c + Vector3(0, 28.0, 0)
	lm.lathe("Pink", sb, PackedVector2Array([Vector2(8.4, 0), Vector2(7.0, 6.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.gable("Pink", sb + d * 6.4 + Vector3(0, 5.0, 0), 4.0, 2.4, 5.0, Basis(Vector3.UP, atan2(d.x, d.z)), 0.0, "Pink")
	var spb := sb + Vector3(0, 6.0, 0)
	LandmarkWhKit.open_spire(lm, "Core", "Pink", spb, 5.8, 41.0, 8, 8)
	# Tiers of small hexagonal stair turrets climbing the spire's ribs.
	var k8 := 1.0 / cos(PI / 8.0)
	for tier in 6:
		var f := 0.08 + 0.13 * float(tier)
		var rr := 5.8 * k8 * (1.0 - f) * 0.96
		for i in 8:
			var a := TAU * (float(i) + 0.5) / 8.0
			var tp := spb + Vector3(cos(a) * rr, 41.0 * f, sin(a) * rr)
			var th := 4.2 * (1.0 - f * 0.7)
			lm.frustum("Pink", tp, 0.5, 0.45, th, 6)
			lm.frustum("Pink", tp + Vector3(0, th, 0), 0.6, 0.0, th * 0.4, 6)
	# Lantern and crown under the cross.
	var lb := spb + Vector3(0, 33.0, 0)
	lm.frustum("Pink", lb, 1.6, 1.4, 3.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Pink", lb + Vector3(cos(a) * 1.7, 3.3, sin(a) * 1.7), Vector3(0.3, 1.0, 0.3), Basis(), 0.0)
	lm.frustum("Pink", lb + Vector3(0, 3.0, 0), 1.8, 1.8, 0.4, 8, PI / 8.0)
	LandmarkWhKit.ball(lm, "Gilt", sb + Vector3(0, 46.7, 0), 0.5)
	LandmarkWestKit.cross(lm, "Gilt", sb + Vector3(0, 47.0, 0), 1.2)
