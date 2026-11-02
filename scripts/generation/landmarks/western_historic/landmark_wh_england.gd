class_name LandmarkWhEngland
extends RefCounted

## Three English landmarks in true metres, y = 0 at the ground,
## churches with the nave along X and the west front at -X: Canterbury
## Cathedral, York Minster and Windsor Castle.

## Canterbury Cathedral (72 m to the pinnacle tips of Bell Harry): the
## Perpendicular nave and the Gothic quire under low lead roofs, the
## main and eastern transepts, the east end of Trinity Chapel and the
## round Corona, the two west towers beside the great west window, the
## great cloister to the north and the crossing tower of Bell Harry
## with its pinnacled parapet.
static func canterbury(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D4C9A8", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#767E83", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#27385A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	LandmarkWhKit.aisled_body(lm, "Stone", "Lead", "Glass", -78.0, -24.0, 8.0, 26.0, 12.5, 14.0, 6.0, 6)
	LandmarkWhKit.aisled_body(lm, "Stone", "Lead", "Glass", -9.0, 34.0, 8.0, 26.0, 12.5, 14.0, 6.0, 5)
	# Main transept (47 m) and the eastern transept, with gable windows.
	LandmarkWestKit.blk(lm, "Stone", -16.5, 0, 0, 15.0, 23.0, 47.0)
	lm.gable("Lead", Vector3(-16.5, 23.0, 0), 15.0, 47.0, 5.0, Basis(), 0.3, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 38.5, 0, 0, 9.0, 23.0, 36.0)
	lm.gable("Lead", Vector3(38.5, 23.0, 0), 9.0, 36.0, 4.0, Basis(), 0.3, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-16.5, 5.0, sz * 23.6), Vector3(0, 0, sz), 5.0, 12.0, 3.0)
		LandmarkWhKit.lancet(lm, "Glass", Vector3(38.5, 7.0, sz * 18.1), Vector3(0, 0, sz), 3.2, 9.0, 2.0)
		for px in [-23.5, -9.5]:
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(px, 23.0, sz * 23.4), 0.7, 1.8, 3.6)
	# Trinity Chapel, the round Corona at the east end, and the east gable.
	LandmarkWestKit.blk(lm, "Stone", 52.5, 0, 0, 19.0, 24.0, 18.0)
	lm.gable("Lead", Vector3(52.5, 24.0, 0), 18.0, 19.0, 5.5, rot, 0.3, "Stone")
	lm.lathe("Stone", Vector3(62, 0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(8.0, 22.0)]), 10,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(62, 22.0, 0), PackedVector2Array([Vector2(8.6, 0), Vector2(0, 6.0)]), 10)
	for a in [-0.9, -0.3, 0.3, 0.9]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(62.0 + cos(a) * 8.1, 6.0, sin(a) * 8.1),
			Vector3(cos(a), 0, sin(a)), 2.2, 9.0, 2.0)
	# West front: great window, portal, the two towers (58 m with pinnacles).
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-78.1, 7.0, 0), Vector3(-1, 0, 0), 7.0, 14.0, 4.0)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-78.1, 0, 0), Vector3(-1, 0, 0), 3.6, 4.2, 2.4)
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(-72.5, 0, sz * 15.0), 11.0, 52.5, 14.0,
			[Vector3(-1, 0, 0), Vector3(0, 0, sz), Vector3(1, 0, 0)])
	# Bell Harry over the crossing, 15.5 m square, to 72 m.
	var top := LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(-16.5, 0, 0), 15.5, 64.0, 26.0,
		[Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)], 3.4, 3.8)
	for q in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		LandmarkWhKit.pinnacle(lm, "Stone", Vector3(-16.5 + q.x * 3.5, 64.8, q.y * 3.5), 0.55, 1.4, 2.4)
	lm.spire("Stone", Vector3(-16.5, 64.8, 0), 2.2, 7.0, 0.0, 8)
	LandmarkWhKit.ball(lm, "Gilt", Vector3(-16.5, top - 0.5, 0), 0.3)
	# Great cloister north of the nave.
	for r in [[-52.0, -54.0, 40.0, 5.0], [-52.0, -16.0, 40.0, 5.0], [-70.5, -35.0, 5.0, 33.0],
			[-33.5, -35.0, 5.0, 33.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 7.0, r[3])
		LandmarkWestKit.blk(lm, "Lead", r[0], 7.0, r[1], r[2] + 0.6, 0.6, r[3] + 0.6)
	lm.commit(model)

## York Minster (72 m to the pinnacles of the central tower): the
## largest Gothic church in northern Europe, nave along X with the two
## 60 m west towers and the Heart of Yorkshire window, the broad
## transepts, the central lantern tower, the square-ended choir under
## the great east window and the octagonal chapter house to the north.
static func york_minster(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC4A6", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6E767B", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#27385A"))
	LandmarkWhKit.aisled_body(lm, "Stone", "Lead", "Glass", -77.0, -17.0, 9.5, 27.0, 16.5, 16.0, 5.0, 8)
	LandmarkWhKit.aisled_body(lm, "Stone", "Lead", "Glass", 1.0, 62.0, 9.5, 27.0, 16.5, 16.0, 5.0, 8)
	# Transepts: the south rose and the north Five Sisters lancets.
	LandmarkWestKit.blk(lm, "Stone", -8.0, 0, 0, 18.0, 27.0, 68.0)
	lm.gable("Lead", Vector3(-8.0, 27.0, 0), 18.0, 68.0, 5.0, Basis(), 0.3, "Stone")
	LandmarkWhKit.rose(lm, "Glass", "Stone", Vector3(-8.0, 22.0, 34.1), Vector3(0, 0, 1), 3.8, 16)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-14.0, 0, 34.1), Vector3(-2.0, 0, 34.1), Vector3(0, 0, 1),
		3, 2.2, 8.0, 5.0, 2.4)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-15.0, 0, -34.1), Vector3(-1.0, 0, -34.1), Vector3(0, 0, -1),
		5, 1.4, 14.0, 6.0, 2.0)
	for sz in [-1.0, 1.0]:
		for px in [-16.4, 0.4]:
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(px, 27.0, sz * 33.6), 0.8, 2.0, 4.0)
	# East end: the great east window between pinnacled buttresses.
	LandmarkWhKit.lancet(lm, "Glass", Vector3(62.1, 5.0, 0), Vector3(1, 0, 0), 9.0, 18.0, 5.5)
	for sz in [-1.0, 1.0]:
		for ez in [10.0, 17.8]:
			LandmarkWestKit.blk(lm, "Stone", 62.8, 0, sz * ez, 2.0, 30.0, 1.8)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(62.8, 30.0, sz * ez), 0.8, 1.6, 3.4)
	# West front, the Heart of Yorkshire window and the two towers.
	LandmarkWestKit.blk(lm, "Stone", -79.5, 0, 0, 5.0, 27.0, 18.0)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-82.1, 9.0, 0), Vector3(-1, 0, 0), 7.0, 15.0, 5.0)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-82.1, 0, 0), Vector3(-1, 0, 0), 4.0, 5.0, 3.0)
	lm.gable("Stone", Vector3(-79.5, 27.0, 0), 18.0, 5.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(-76.0, 0, sz * 15.0), 12.0, 53.2, 12.0,
			[Vector3(-1, 0, 0), Vector3(0, 0, sz), Vector3(1, 0, 0)])
	# Central lantern tower, 18 m square, to 72 m.
	LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(-8.0, 0, 0), 18.0, 64.0, 27.0,
		[Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)], 3.5, 3.7)
	for q in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		LandmarkWhKit.pinnacle(lm, "Stone", Vector3(-8.0 + q.x * 3.5, 64.8, q.y * 3.5), 0.6, 1.6, 2.6)
	# Octagonal chapter house with its conical roof, joined by a vestibule.
	lm.lathe("Stone", Vector3(14, 0, -33.0), PackedVector2Array([Vector2(13.0, 0), Vector2(13.0, 19.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	lm.lathe("Lead", Vector3(14, 19.0, -33.0), PackedVector2Array([Vector2(13.6, 0), Vector2(0, 14.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	LandmarkWestKit.blk(lm, "Stone", 14.0, 0, -22.0, 8.0, 14.0, 10.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhKit.lancet(lm, "Glass", Vector3(14.0, 6.0, -33.0) + d * 12.05, d, 3.8, 8.0, 3.0)
		var vd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWestKit.blk(lm, "Stone", 14.0 + vd.x * 13.4, 0, -33.0 + vd.z * 13.4, 1.4, 19.0, 1.4)
		LandmarkWhKit.pinnacle(lm, "Stone", Vector3(14.0 + vd.x * 13.4, 19.0, -33.0 + vd.z * 13.4), 0.5, 1.2, 2.4)
	lm.commit(model)

## Windsor Castle (45 m to the top of the Round Tower): the royal
## fortress on its chalk bluff, long axis along X. The Round Tower on
## its 15 m motte at the centre, the Upper Ward quadrangle of ranges
## and corner towers to the east, the Lower Ward with St George's
## Chapel and the Curfew Tower to the west, and the crenellated
## curtain wall joining them.
static func windsor_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDB5A0", 4.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#5A636A", 2.5))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	# Curtain wall round the whole castle, a tower at each corner.
	var pts: Array[Vector2] = [Vector2(-250, -44), Vector2(-120, -48), Vector2(-45, -50), Vector2(45, -56),
		Vector2(190, -62), Vector2(192, 60), Vector2(45, 56), Vector2(-45, 52), Vector2(-120, 48), Vector2(-250, 44)]
	for i in pts.size():
		var a := Vector3(pts[i].x, -6.0, pts[i].y)
		var b := Vector3(pts[(i + 1) % pts.size()].x, -6.0, pts[(i + 1) % pts.size()].y)
		LandmarkWhKit.crenel_wall(lm, "Stone", a, b, 16.0, 3.0, 3.0)
		lm.frustum("Stone", a, 5.4, 5.0, 24.0, 12)
		LandmarkWhKit.crenel_ring(lm, "Stone", a + Vector3(0, 24.0, 0), 5.0, 9, 2.0, 1.3, 1.0)
	# The Round Tower on its motte (45 m): revetted slope, tower, turret.
	lm.lathe("Lawn", Vector3(0, 0, 0), PackedVector2Array([Vector2(56, 0), Vector2(44, 5), Vector2(34, 10),
		Vector2(26.5, 15.0)]), 24)
	lm.frustum("Stone", Vector3(0, 12.0, 0), 27.0, 25.0, 3.5, 24)
	lm.frustum("Stone", Vector3(0, 15.0, 0), 14.2, 13.4, 21.0, 24)
	lm.frustum("Stone", Vector3(0, 34.5, 0), 13.4, 14.6, 2.5, 24)
	LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(0, 37.0, 0), 14.2, 26, 2.0, 1.4, 1.2)
	lm.frustum("Stone", Vector3(9.0, 15.0, -9.0), 2.8, 2.5, 26.0, 10)
	LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(9.0, 41.0, -9.0), 2.6, 7, 1.2, 1.2, 0.7)
	lm.lathe("Slate", Vector3(9.0, 41.0, -9.0), PackedVector2Array([Vector2(2.6, 0), Vector2(0, 4.0)]), 10)
	for k in 9:
		var a := TAU * float(k) / 9.0
		lm.box("Glass", Vector3(cos(a) * 13.7, 27.0, sin(a) * 13.7), Vector3(0.9, 3.0, 0.3), Basis(Vector3.UP, -a + PI * 0.5))
	# Upper Ward: four ranges round the quadrangle with parapets and towers.
	for r in [[126.0, -50.0, 128.0, 20.0, 22.0], [126.0, 48.0, 128.0, 20.0, 20.0], [70.0, 0.0, 16.0, 80.0, 18.0],
			[182.0, 0.0, 16.0, 80.0, 22.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], r[4], r[3])
		LandmarkWestKit.blk(lm, "Stone", r[0], r[4], r[1], r[2] + 0.8, 1.0, r[3] + 0.8)
	LandmarkWestKit.win_line(lm, "Glass", Vector3(66, 0, -39.9), Vector3(186, 0, -39.9), Vector3(0, 0, 1),
		6.0, 1.6, 3.4, [5.0, 13.0])
	LandmarkWestKit.win_line(lm, "Glass", Vector3(66, 0, 38.1), Vector3(186, 0, 38.1), Vector3(0, 0, -1),
		6.0, 1.6, 3.4, [5.0, 12.0])
	LandmarkWestKit.win_line(lm, "Glass", Vector3(78.1, 0, -36), Vector3(78.1, 0, 36), Vector3(1, 0, 0),
		6.0, 1.6, 3.4, [5.0, 12.0])
	LandmarkWestKit.win_line(lm, "Glass", Vector3(173.9, 0, -36), Vector3(173.9, 0, 36), Vector3(-1, 0, 0),
		6.0, 1.6, 3.4, [5.0, 13.0])
	for t in [[66.0, -56.0, 28.0], [188.0, -58.0, 30.0], [188.0, 56.0, 26.0], [66.0, 52.0, 24.0], [126.0, -62.0, 27.0]]:
		LandmarkWestKit.blk(lm, "Stone", t[0], 0, t[1], 12.0, t[2], 12.0)
		LandmarkWestKit.blk(lm, "Stone", t[0], t[2], t[1], 13.4, 1.4, 13.4)
		LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(t[0], t[2] + 1.4, t[1]), 6.2, 8, 2.4, 1.2, 1.0)
	# Norman Gate between the wards, two towers over the passage.
	for sz in [-1.0, 1.0]:
		lm.frustum("Stone", Vector3(-50.0, 0, sz * 9.0), 5.6, 5.2, 18.0, 12)
		LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(-50.0, 18.0, sz * 9.0), 5.4, 9, 2.0, 1.2, 1.0)
	# Lower Ward: St George's Chapel (nave, chancel, crossing tower) and ranges.
	LandmarkWhKit.aisled_body(lm, "Stone", "Slate", "Glass", -168.0, -100.0, 8.0, 21.0, 11.5, 13.0, 3.0, 8)
	LandmarkWestKit.blk(lm, "Stone", -125.0, 21.0, 0, 11.0, 12.0, 11.0)
	LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(-125.0, 33.0, 0), 5.6, 8, 2.2, 1.2, 1.0)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-168.1, 5.0, 0), Vector3(-1, 0, 0), 6.0, 11.0, 3.5)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", -150.0, 0, sz * 38.0, 120.0, 9.0, 8.0)
		lm.gable("Slate", Vector3(-150.0, 9.0, sz * 38.0), 8.0, 120.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
	LandmarkWhKit.round_tower(lm, "Stone", "Slate", Vector3(-243.0, 0, 28.0), 7.0, 6.5, 24.0, 9.0, 14)
	LandmarkWestKit.blk(lm, "Stone", -246.0, 0, 0, 8.0, 14.0, 12.0)
	lm.commit(model)
