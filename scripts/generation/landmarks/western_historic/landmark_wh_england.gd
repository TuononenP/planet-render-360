class_name LandmarkWhEngland
extends RefCounted

## Two English cathedrals in true metres, y = 0 at the ground, the nave
## along X with the west front at -X: Canterbury Cathedral and York
## Minster (Windsor Castle is LandmarkWhWindsor).

## Canterbury Cathedral (72 m to the pinnacle tips of Bell Harry; 160 m
## long): the Perpendicular nave (1377-1405) and the Gothic quire under
## low lead roofs behind pierced parapets, the main and eastern
## transepts, Trinity Chapel and the round Corona ("Becket's Crown") at
## the east end; the two Perpendicular west towers (the Oxford tower of
## 1424-34 and its 1834 twin, the Arundel tower) beside the great west
## window; the great cloister to the north; and Bell Harry over the
## crossing (1494-98), its pinnacles 36 m above the roofs, with two
## stages of paired traceried windows between octagonal corner turrets.
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
		var n := Vector3(0, 0, sz)
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-16.5, 5.0, sz * 23.5), n, 6.0, 11.0, 3.4, 5, 0.4)
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(38.5, 7.0, sz * 18.0), n, 3.6, 8.5, 2.2, 3, 0.35)
		for px in [-23.5, -9.5]:
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(px, 0, sz * 23.5), n, 1.6, 2.2, 22.0, 4)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(px, 23.0, sz * 23.9), 0.7, 1.8, 3.6)
		LandmarkWhGothic.parapet(lm, "Stone", Vector3(-24.0, 23.0, sz * 23.5), Vector3(-9.0, 23.0, sz * 23.5), n, 1.2)
	# Trinity Chapel and the Corona: a round two-storey chapel under a
	# flat lead roof behind its parapet.
	LandmarkWestKit.blk(lm, "Stone", 52.5, 0, 0, 19.0, 24.0, 18.0)
	lm.gable("Lead", Vector3(52.5, 24.0, 0), 18.0, 19.0, 5.5, rot, 0.3, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(44.0, 0, sz * 9.0), Vector3(61.0, 0, sz * 9.0),
			Vector3(0, 0, sz), 3, 2.6, 7.0, 12.0, 2.0, 2, 0.3)
	var cc := Vector3(66.0, 0, 0)
	lm.frustum("Stone", cc, 6.5, 6.5, 20.0, 16)
	lm.frustum("Lead", cc + Vector3(0, 20.0, 0), 6.3, 6.3, 0.4, 16)
	for k in 7:
		var a := deg_to_rad(-81.0 + 27.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWhGothic.window(lm, "Glass", "Stone", cc + d * 6.4 + Vector3(0, 3.0, 0), d, 1.6, 4.5, 1.2, 1, 0.3)
		LandmarkWhGothic.window(lm, "Glass", "Stone", cc + d * 6.4 + Vector3(0, 11.5, 0), d, 1.6, 4.5, 1.2, 1, 0.3)
		var bd := Vector3(cos(a + 0.23), 0, sin(a + 0.23))
		LandmarkWhGothic.buttress(lm, "Stone", cc + bd * 6.4, bd, 0.9, 1.2, 19.0, 3)
	LandmarkWhKit.crenel_ring(lm, "Stone", cc + Vector3(0, 20.0, 0), 6.3, 18, 1.0, 1.2, 0.5)
	# West front: great window, portal under its square label, two towers
	# of about 47 m to the pinnacles.
	var wn := Vector3(-1, 0, 0)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-78.1, 8.0, 0), wn, 7.0, 12.0, 4.5, 7, 0.45)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-78.1, 0.2, 0), wn, 3.6, 3.6, 2.0, 1, 0.5)
	lm.box("Stone", Vector3(-78.4, 6.4, 0), Vector3(0.5, 0.4, 6.4), Basis(), 0.0)
	lm.gable("Stone", Vector3(-78.3, 26.0, 0), 16.0, 0.6, 6.0, rot, 0.0, "Stone")
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-78.4, 26.0, -8.0), Vector3(-78.4, 26.0, 8.0), wn, 1.2)
	for sz in [-1.0, 1.0]:
		var fz := Vector3(0, 0, sz)
		LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(-72.5, 0, sz * 15.0), 11.0, 40.0, 14.0,
			[Vector3(-1, 0, 0), fz, Vector3(1, 0, 0)], 2.5, 3.2)
		for q in [Vector3(-1, 0, 0), fz]:
			var qv: Vector3 = q
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(-72.5, 40.8, sz * 15.0) + qv * 5.0, 0.45, 1.6, 2.4)
	_bell_harry(lm, Vector3(-16.5, 0, 0))
	# Great cloister north of the nave: four walks with traceried bays
	# on the garth, lead lean-to roofs and the chapter house to the east.
	for r in [[-52.0, -54.0, 40.0, 5.0, 1.0], [-52.0, -16.0, 40.0, 5.0, -1.0], [-70.5, -35.0, 5.0, 33.0, 1.0],
			[-33.5, -35.0, 5.0, 33.0, -1.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 7.0, r[3])
		LandmarkWestKit.blk(lm, "Lead", r[0], 7.0, r[1], r[2] + 0.6, 0.6, r[3] + 0.6)
		var wide: bool = float(r[2]) > float(r[3])
		var s: float = r[4]
		var n := Vector3(0, 0, s) if wide else Vector3(s, 0, 0)
		var half := Vector3(float(r[2]) * 0.5 - 2.5, 0, 0) if wide else Vector3(0, 0, float(r[3]) * 0.5 - 2.5)
		var face := Vector3(r[0], 0, r[1]) + n * 2.5
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", face - half, face + half, n, 7 if wide else 6, 2.6, 2.6, 1.2,
			1.6, 3, 0.25)
	LandmarkWestKit.blk(lm, "Stone", -26.0, 0, -42.0, 12.0, 16.0, 22.0)
	lm.gable("Lead", Vector3(-26.0, 16.0, -42.0), 12.0, 22.0, 4.0, Basis(), 0.3, "Stone")
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-19.95, 4.0, -42.0), Vector3(1, 0, 0), 5.0, 7.0, 3.0, 5, 0.35)
	lm.commit(model)

## Bell Harry at `c`: a 15.5 m square Perpendicular tower from the roofs
## to 64 m, octagonal corner turrets running up to crocketed pinnacles
## at 72 m, two stages of paired two-light windows on each face under
## their hood moulds, panelled string courses and a pierced parapet.
static func _bell_harry(lm: LandmarkMesh, c: Vector3) -> void:
	var s := 15.5
	var h := 64.0
	LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, s, h, s)
	for y in [26.0, 38.0, 51.0]:
		LandmarkWestKit.blk(lm, "Stone", c.x, y, c.z, s + 0.6, 0.6, s + 0.6)
	for f in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var fn: Vector3 = f
		var fp := c + fn * (s * 0.5)
		var half := LandmarkWhKit.along(fn) * 3.4
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 2, 2.6, 6.5, 28.5, 2.0, 2, 0.35)
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 2, 2.8, 8.0, 41.0, 2.2, 2, 0.35)
		# Blind panelling under the upper stage.
		for k in 6:
			var p := fp - LandmarkWhKit.along(fn) * 5.0 + LandmarkWhKit.along(fn) * 2.0 * float(k)
			LandmarkWhGothic.window(lm, "Stone", "Stone", p + Vector3(0, 52.2, 0), fn, 1.2, 6.5, 1.0, 1, 0.12, false)
		var hw := LandmarkWhKit.along(fn) * (s * 0.5 - 1.2)
		LandmarkWhGothic.parapet(lm, "Stone", fp - hw + Vector3(0, h, 0), fp + hw + Vector3(0, h, 0), fn, 1.6, 1.3)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tc := c + Vector3(q.x * (s * 0.5), 0, q.y * (s * 0.5))
		lm.lathe("Stone", tc + Vector3(0, 20.0, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.7, h - 18.5)]), 8,
			1.0, 1.0, PI / 8.0, false)
		for y in [26.0, 38.0, 51.0, h]:
			lm.frustum("Stone", tc + Vector3(0, y - 0.3, 0), 1.95, 1.95, 0.5, 8, PI / 8.0)
		LandmarkWhGothic.pinnacle(lm, "Stone", tc + Vector3(0, h + 1.5, 0), 1.0, 2.0, 3.9)
	LandmarkWhKit.ball(lm, "Gilt", c + Vector3(s * 0.5, h + 7.4, s * 0.5), 0.2)

## York Minster (72 m to the top of the central tower; 158 m long): the
## largest Gothic church in northern Europe, nave along X. The two
## 60 m Perpendicular west towers with their eight crocketed pinnacles
## each, the Decorated west front with the Heart of Yorkshire window
## over the portal gable, the broad transepts (the north with the Five
## Sisters, five 16 m lancets; the south with its rose), the flat-topped
## central lantern tower with its tall paired windows and pierced
## parapet, the square-ended choir under the great east window (23.7 x
## 9.5 m, the largest expanse of medieval glass), and the octagonal
## chapter house with its steep pyramid roof to the north.
static func york_minster(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC4A6", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6E767B", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#27385A"))
	LandmarkWhKit.aisled_body(lm, "Stone", "Lead", "Glass", -77.0, -17.0, 9.5, 27.0, 16.5, 16.0, 5.0, 8)
	LandmarkWhKit.aisled_body(lm, "Stone", "Lead", "Glass", 1.0, 62.0, 9.5, 27.0, 16.5, 16.0, 5.0, 8)
	# Transepts: the south rose over its lancets and portal; the north
	# Five Sisters under five stepped lancets in the gable.
	LandmarkWestKit.blk(lm, "Stone", -8.0, 0, 0, 18.0, 27.0, 68.0)
	lm.gable("Lead", Vector3(-8.0, 27.0, 0), 18.0, 68.0, 5.0, Basis(), 0.3, "Stone")
	LandmarkWhKit.rose(lm, "Glass", "Stone", Vector3(-8.0, 22.0, 34.1), Vector3(0, 0, 1), 3.8, 24)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-14.0, 0, 34.0), Vector3(-2.0, 0, 34.0), Vector3(0, 0, 1),
		3, 2.2, 8.0, 7.0, 2.4, 1, 0.3)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-8.0, 0.2, 34.0), Vector3(0, 0, 1), 3.0, 3.6, 2.0, 1, 0.5)
	lm.gable("Stone", Vector3(-8.0, 6.0, 34.6), 5.0, 1.0, 3.0, Basis(), 0.0, "Stone")
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-15.0, 0, -34.0), Vector3(-1.0, 0, -34.0),
		Vector3(0, 0, -1), 5, 1.5, 14.0, 4.0, 2.2, 1, 0.35)
	for k in 5:
		var lz := -12.0 + 2.0 * float(k)
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(lz, 23.0, -34.0), Vector3(0, 0, -1), 1.0,
			4.0 - absf(float(k) - 2.0) * 1.2, 0.9, 1, 0.25)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for px in [-16.4, 0.4]:
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(px, 0, sz * 34.0), n, 2.0, 2.6, 26.0, 4)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(px, 27.0, sz * 34.6), 0.8, 2.0, 4.0)
		LandmarkWhGothic.parapet(lm, "Stone", Vector3(-17.0, 27.0, sz * 34.0), Vector3(1.0, 27.0, sz * 34.0), n, 1.2)
	# East end: the great east window between pinnacled buttresses.
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(62.1, 4.0, 0), Vector3(1, 0, 0), 9.5, 15.0, 8.0, 9, 0.5)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(62.1, 0, 12.0), Vector3(62.1, 0, 16.0), Vector3(1, 0, 0),
		1, 2.4, 6.0, 5.0, 2.0, 2, 0.3)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(62.1, 0, -16.0), Vector3(62.1, 0, -12.0),
		Vector3(1, 0, 0), 1, 2.4, 6.0, 5.0, 2.0, 2, 0.3)
	lm.gable("Stone", Vector3(62.4, 27.0, 0), 19.0, 0.8, 5.0, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(62.5, 27.0, -9.5), Vector3(62.5, 27.0, 9.5), Vector3(1, 0, 0), 1.3)
	for sz in [-1.0, 1.0]:
		for ez in [10.0, 17.8]:
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(62.0, 0, sz * ez), Vector3(1, 0, 0), 2.0, 2.4, 29.0, 4)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(63.0, 30.0, sz * ez), 0.8, 1.6, 3.4)
	_york_west(lm)
	_york_central(lm, Vector3(-8.0, 0, 0))
	# Octagonal chapter house (1260-96) with its conical roof, joined by
	# the L-shaped vestibule; big six-light windows between buttresses.
	var ch := Vector3(14, 0, -33.0)
	lm.lathe("Stone", ch, PackedVector2Array([Vector2(13.0, 0), Vector2(13.0, 19.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	lm.lathe("Lead", ch + Vector3(0, 19.0, 0), PackedVector2Array([Vector2(13.6, 0), Vector2(0, 14.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	lm.frustum("Lead", ch + Vector3(0, 32.0, 0), 0.4, 0.1, 3.0, 6)
	LandmarkWestKit.blk(lm, "Stone", 14.0, 0, -22.0, 8.0, 14.0, 10.0)
	lm.gable("Lead", Vector3(14.0, 14.0, -22.0), 8.0, 10.0, 2.5, Basis(), 0.3, "Stone")
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.z > 0.8:
			continue
		LandmarkWhGothic.window(lm, "Glass", "Stone", ch + d * 12.0 + Vector3(0, 4.0, 0), d, 5.6, 9.0, 3.6, 5, 0.35)
		var vd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWhGothic.buttress(lm, "Stone", ch + vd * 13.0, vd, 1.6, 3.0, 18.0, 4)
		LandmarkWhKit.pinnacle(lm, "Stone", ch + vd * 14.0 + Vector3(0, 19.0, 0), 0.6, 1.4, 3.0)
	lm.commit(model)

## York's west front: the gabled central block with the Heart of
## Yorkshire window and the portal under its gable, and the two west
## towers (1433-74) to 60 m with eight crocketed pinnacles each.
static func _york_west(lm: LandmarkMesh) -> void:
	var wn := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Stone", -79.5, 0, 0, 5.0, 27.0, 18.0)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-82.1, 11.0, 0), wn, 7.5, 9.5, 6.0, 8, 0.5)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-82.1, 0.2, 0), wn, 4.0, 4.6, 2.6, 2, 0.6)
	lm.gable("Stone", Vector3(-82.5, 7.4, 0), 6.0, 0.8, 5.0, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	for s in [-1.0, 1.0]:
		LandmarkWhGothic.pinnacle(lm, "Stone", Vector3(-82.4, 7.4, s * 3.6), 0.4, 3.0, 2.4)
	lm.gable("Stone", Vector3(-79.5, 27.0, 0), 18.0, 5.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-82.1, 27.0, -9.0), Vector3(-82.1, 27.0, 9.0), wn, 1.2)
	for sz in [-1.0, 1.0]:
		var fz := Vector3(0, 0, sz)
		var c := Vector3(-76.0, 0, sz * 15.0)
		LandmarkWhKit.square_tower(lm, "Stone", "Glass", c, 12.0, 50.0, 12.0, [wn, fz, Vector3(1, 0, 0)], 3.6, 5.6)
		for q in [wn, fz, Vector3(1, 0, 0), -fz]:
			var qv: Vector3 = q
			LandmarkWhKit.pinnacle(lm, "Stone", c + qv * 5.6 + Vector3(0, 50.8, 0), 0.5, 2.6, 4.4)
		LandmarkWhGothic.window(lm, "Glass", "Stone", c + wn * 6.0 + Vector3(0, 1.0, 0), wn, 2.4, 6.0, 1.8, 2, 0.4)

## York's central tower at `c` (1407-72): 18 m square from the roofs to
## its flat top at 72 m, clasping buttresses, two stages of paired tall
## two-light windows a face, a panelled band and the pierced parapet.
static func _york_central(lm: LandmarkMesh, c: Vector3) -> void:
	var s := 18.0
	var h := 70.4
	LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, s, h, s)
	for y in [27.0, 44.0, 63.5]:
		LandmarkWestKit.blk(lm, "Stone", c.x, y, c.z, s + 0.6, 0.6, s + 0.6)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		for o in [Vector3(q.x, 0, 0), Vector3(0, 0, q.y)]:
			var ov: Vector3 = o
			var side := Vector3(0, 0, q.y) if ov.x != 0.0 else Vector3(q.x, 0, 0)
			LandmarkWhGothic.buttress(lm, "Stone", c + ov * s * 0.5 + side * (s * 0.5 - 0.8) + Vector3(0, 27.0, 0), ov,
				1.4, 1.4, h - 27.6, 3)
	for f in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var fn: Vector3 = f
		var fp := c + fn * (s * 0.5)
		var half := LandmarkWhKit.along(fn) * 4.0
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 2, 3.0, 12.0, 46.0, 2.6, 2, 0.4)
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", fp - half, fp + half, fn, 2, 2.6, 4.0, 34.5, 1.6, 2, 0.3)
		for k in 8:
			var p := fp - LandmarkWhKit.along(fn) * 7.0 + LandmarkWhKit.along(fn) * 2.0 * float(k)
			LandmarkWhGothic.window(lm, "Stone", "Stone", p + Vector3(0, 64.4, 0), fn, 1.2, 4.6, 0.9, 1, 0.12, false)
		var hw := LandmarkWhKit.along(fn) * (s * 0.5 + 0.3)
		LandmarkWhGothic.parapet(lm, "Stone", fp - hw + Vector3(0, h, 0), fp + hw + Vector3(0, h, 0), fn, 1.6, 1.2)
