class_name LandmarkLondonHeritage
extends RefCounted

## Four London landmarks in true metres, y = 0 at street level: St Paul's
## Cathedral, the Tower of London, Buckingham Palace and Westminster
## Abbey.

## St Paul's Cathedral (111 m): cruciform Portland-stone church (nave
## along X, west front at -X) behind its screen walls, the two-storey
## west portico with pediment, the 68 m Baroque west towers, and Wren's
## great dome — peristyle of 32 columns, lead dome, stone lantern, gilt
## ball and cross.
static func st_pauls(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2CCBF", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8A9195", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Cross-plan walls under flat lead roofs, apse, string course.
	LandmarkWestKit.blk(lm, "Stone", -4.0, 0, 0, 132.0, 30.0, 50.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 50.0, 30.0, 75.0)
	LandmarkWestKit.blk(lm, "Lead", -4.0, 30.0, 0, 131.0, 0.8, 49.0)
	LandmarkWestKit.blk(lm, "Lead", 0, 30.0, 0, 49.0, 0.8, 74.0)
	lm.lathe("Stone", Vector3(62, 0, 0), PackedVector2Array([Vector2(13, 0), Vector2(13, 30.8)]), 14,
		1.0, 1.0, 0.0, false)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", -4.0, 14.0, sz * 25.1, 133.0, 1.0, 0.5)
		LandmarkWestKit.win_line(lm, "Glass", Vector3(-66, 0, sz * 25.2), Vector3(62, 0, sz * 25.2),
			Vector3(0, 0, sz), 6.0, 1.6, 4.5, [8.0, 21.0])
		# Transept portico: six columns and a pediment.
		LandmarkWestKit.col_row(lm, "Stone", Vector3(-9.0, 0, sz * 40.0), Vector3(9.0, 0, sz * 40.0),
			6, 0.8, 0.7, 20.0, 12)
		LandmarkWestKit.blk(lm, "Stone", 0, 20.0, sz * 38.5, 22.0, 2.0, 6.0)
		lm.gable("Stone", Vector3(0, 22.0, sz * 38.5), 22.0, 6.0, 4.0, Basis(), 0.0, "Stone")
	# West portico: 12 lower + 8 upper columns, entablatures, pediment.
	for k in 4:
		LandmarkWestKit.blk(lm, "Stone", -86.5 - 1.5 * float(3 - k), 0, 0, 3.0, 1.0 * float(k + 1),
			40.0 - 2.0 * float(3 - k))
	LandmarkWestKit.blk(lm, "Stone", -78.0, 0, 0, 14.0, 4.0, 38.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-82.0, 4.0, -17.0), Vector3(-82.0, 4.0, 17.0), 12,
		0.8, 0.7, 11.0, 12)
	LandmarkWestKit.blk(lm, "Stone", -78.0, 15.0, 0, 12.0, 2.0, 38.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-80.0, 17.0, -13.0), Vector3(-80.0, 17.0, 13.0), 8,
		0.7, 0.6, 8.0, 12)
	LandmarkWestKit.blk(lm, "Stone", -78.0, 25.0, 0, 12.0, 2.0, 30.0)
	lm.gable("Stone", Vector3(-78.0, 27.0, 0), 30.0, 12.0, 7.0, rot, 0.0, "Stone")
	# West towers: square, clock stage, columned lantern, ogee dome.
	for sz in [-1.0, 1.0]:
		var c := Vector3(-70.0, 0, sz * 22.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 12.0, 42.0, 12.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 42.0, c.z, 9.0, 8.0, 9.0)
		lm.frustum("Stone", c + Vector3(0, 50, 0), 4.4, 4.0, 6.0, 8, PI / 8.0)
		LandmarkWestKit.col_ring(lm, "Stone", c + Vector3(0, 50, 0), 4.5, 8, 0.3, 0.28, 6.0)
		lm.lathe("Lead", c + Vector3(0, 56, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(5.0, 1.5),
			Vector2(4.0, 3.5), Vector2(2.0, 6.0), Vector2(0.6, 9.0), Vector2(0.0, 11.0)]), 8)
		lm.lathe("Gilt", c + Vector3(0, 66, 0), LandmarkWestKit.ball(0.7), 8)
	# The dome (111 m to the cross tip).
	var d := Vector3(0, 30.8, 0)
	lm.frustum("Stone", d, 22.5, 22.5, 4.2, 28)
	lm.frustum("Stone", d + Vector3(0, 4.2, 0), 16.5, 16.5, 16.0, 28)
	LandmarkWestKit.col_ring(lm, "Stone", d + Vector3(0, 5.0, 0), 18.3, 32, 0.55, 0.5, 13.0)
	lm.frustum("Stone", d + Vector3(0, 18.2, 0), 19.3, 19.3, 2.0, 32)
	lm.frustum("Stone", d + Vector3(0, 20.2, 0), 16.5, 16.5, 6.0, 28)
	lm.lathe("Lead", d + Vector3(0, 26.2, 0), LandmarkWestKit.dome_prof(16.8, 30.0, 14, 1.05), 28)
	lm.frustum("Gilt", d + Vector3(0, 55.0, 0), 5.8, 5.6, 0.8, 20)
	lm.frustum("Stone", d + Vector3(0, 56.2, 0), 4.6, 4.2, 12.0, 12)
	LandmarkWestKit.col_ring(lm, "Stone", d + Vector3(0, 56.2, 0), 4.8, 8, 0.3, 0.28, 12.0)
	lm.lathe("Lead", d + Vector3(0, 68.2, 0), LandmarkWestKit.dome_prof(4.4, 3.5, 6, 1.8), 12)
	lm.lathe("Gilt", d + Vector3(0, 71.7, 0), LandmarkWestKit.ball(1.5), 10)
	LandmarkWestKit.cross(lm, "Gilt", Vector3(0, 105.0, 0), 6.0)
	lm.commit(model)

## Tower of London (27.5 m): the White Tower with its four turrets and
## apsidal chapel, the inner ward ringed by a curtain wall and towers,
## and the lower outer wall with its round towers.
static func tower_of_london(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#CFC6B2", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9B8F7C", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# White Tower: 36 x 32 m keep, merlons, turrets, chapel apse.
	LandmarkWestKit.blk(lm, "White", 0, 0, 0, 36.0, 25.0, 32.0)
	for s in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var t := Vector3(s.x * 15.0, 0, s.y * 13.0)
		LandmarkWestKit.blk(lm, "White", t.x, 25.0, t.z, 7.0, 1.2, 7.0)
		LandmarkWestKit.hip(lm, "Slate", t + Vector3(0, 26.2, 0), 7.0, 7.0, 1.0, 0.0)
		LandmarkWestKit.blk(lm, "Gilt", t.x, 27.2, t.z, 0.3, 0.3, 0.3)
	lm.frustum("White", Vector3(15, 0, -13), 4.6, 4.6, 26.2, 14)
	lm.lathe("Slate", Vector3(15, 26.2, -13), PackedVector2Array([Vector2(4.8, 0), Vector2(0.0, 1.0)]), 14)
	LandmarkWestKit.blk(lm, "Gilt", 15.0, 27.2, -13.0, 0.3, 0.3, 0.3)
	lm.lathe("White", Vector3(17, 0, 10), PackedVector2Array([Vector2(5.8, 0), Vector2(5.8, 17.0)]), 12,
		1.0, 1.0, 0.0, false)
	var keep: Array[Vector2] = [Vector2(-18, -16), Vector2(18, -16), Vector2(18, 16), Vector2(-18, 16)]
	for i in 4:
		LandmarkWestKit.merlons(lm, "White", Vector3(keep[i].x, 25.0, keep[i].y),
			Vector3(keep[(i + 1) % 4].x, 25.0, keep[(i + 1) % 4].y), 2.6, 1.4, 1.0, 0.8)
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-15, 0, -16.2), Vector3(15, 0, -16.2), Vector3(0, 0, -1),
		7.5, 1.1, 3.0, [7.0, 15.0, 21.0])
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-15, 0, 16.2), Vector3(15, 0, 16.2), Vector3(0, 0, 1),
		7.5, 1.1, 3.0, [7.0, 15.0, 21.0])
	# Inner ward (curtain wall 9 m, towers 15 m) and outer ward (6.5 m / 11 m).
	var inner: Array[Vector2] = [Vector2(-100, -55), Vector2(-35, -62), Vector2(45, -58), Vector2(62, -20),
		Vector2(62, 38), Vector2(10, 45), Vector2(-60, 40), Vector2(-100, 10)]
	var outer: Array[Vector2] = [Vector2(-135, -100), Vector2(0, -108), Vector2(110, -95), Vector2(120, -10),
		Vector2(112, 60), Vector2(40, 84), Vector2(-70, 86), Vector2(-130, 40)]
	lm.poly_prism("Lawn", PackedVector2Array(inner), -0.5, 0.05)
	_ring(lm, inner, 9.0, 3.0, 9.0, 15.0, false)
	_ring(lm, outer, 6.5, 2.5, 9.0, 11.0, true)
	lm.commit(model)

## Curtain wall round `pts` with a tower at every corner.
static func _ring(lm: LandmarkMesh, pts: Array[Vector2], wall_h: float, thick: float,
		tower: float, tower_h: float, round: bool) -> void:
	for i in pts.size():
		var a := Vector3(pts[i].x, 0, pts[i].y)
		var b := Vector3(pts[(i + 1) % pts.size()].x, 0, pts[(i + 1) % pts.size()].y)
		var d := b - a
		lm.box("Wall", (a + b) * 0.5 + Vector3(0, wall_h * 0.5, 0), Vector3(thick, wall_h, d.length()),
			Basis(Vector3.UP, atan2(d.x, d.z)))
		LandmarkWestKit.merlons(lm, "Wall", a + Vector3(0, wall_h, 0), b + Vector3(0, wall_h, 0), 2.4, 1.2, 1.0,
			thick * 0.9)
		if round:
			lm.frustum("Wall", a, tower * 0.5, tower * 0.5, tower_h, 12)
			lm.lathe("Slate", a + Vector3(0, tower_h, 0), PackedVector2Array([Vector2(tower * 0.58, 0),
				Vector2(0.0, tower * 0.6)]), 12)
		else:
			LandmarkWestKit.blk(lm, "Wall", a.x, 0, a.z, tower, tower_h, tower)
			LandmarkWestKit.hip(lm, "Slate", a + Vector3(0, tower_h, 0), tower + 1.0, tower + 1.0, 4.0, 0.0)

## Buckingham Palace (24 m): the Portland-stone quadrangle, 108 m east
## front (+X, facing The Mall) with its central balcony pavilion and
## pediment, corner pavilions, garden front to the west, and the gilded
## forecourt railings.
static func buckingham(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D0C8B2", 3.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#5A6168", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#BBB3A1", 5.0))
	for r in [[49.0, 0.0, 22.0, 108.0], [-49.0, 0.0, 22.0, 108.0], [0.0, 43.0, 120.0, 22.0],
			[0.0, -43.0, 120.0, 22.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 19.0, r[3])
		LandmarkWestKit.blk(lm, "Stone", r[0], 19.0, r[1], r[2] + 0.8, 1.0, r[3] + 0.8)
		LandmarkWestKit.blk(lm, "Slate", r[0], 20.0, r[1], r[2] - 2.0, 0.8, r[3] - 2.0)
	LandmarkWestKit.blk(lm, "Court", 0, 0, 0, 76.0, 0.3, 64.0)
	# East front: corner pavilions, columned centre pavilion, pediment.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", 61.0, 0, sz * 46.0, 3.0, 21.0, 16.0)
		LandmarkWestKit.blk(lm, "Stone", 61.0, 21.0, sz * 46.0, 4.0, 1.0, 17.0)
	LandmarkWestKit.blk(lm, "Stone", 62.0, 0, 0, 4.0, 20.0, 36.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(65.0, 0, -15.0), Vector3(65.0, 0, 15.0), 6, 0.7, 0.6, 16.0, 12)
	LandmarkWestKit.blk(lm, "Stone", 62.0, 8.0, 0, 6.0, 0.8, 36.0)
	LandmarkWestKit.blk(lm, "Stone", 62.0, 16.0, 0, 6.0, 4.0, 36.0)
	lm.gable("Stone", Vector3(62.0, 20.0, 0), 34.0, 6.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	LandmarkWestKit.win_line(lm, "Glass", Vector3(60.2, 0, -52), Vector3(60.2, 0, 52), Vector3(1, 0, 0),
		4.5, 1.6, 3.4, [5.0, 12.0])
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-60.2, 0, -52), Vector3(-60.2, 0, 52), Vector3(-1, 0, 0),
		4.5, 1.6, 3.4, [5.0, 12.0])
	# Garden-front bow and forecourt railings with gilded gates.
	lm.lathe("Stone", Vector3(-60, 0, 0), PackedVector2Array([Vector2(12, 0), Vector2(12, 19)]), 14, 0.5, 1.0)
	LandmarkWestKit.merlons(lm, "Gilt", Vector3(92, 0, -62), Vector3(92, 0, 62), 1.6, 0.2, 3.0, 0.2)
	LandmarkWestKit.blk(lm, "Stone", 92.0, 0, 0, 1.2, 1.0, 124.0)
	lm.commit(model)

## Westminster Abbey (69 m): the Gothic coronation church — nave along
## X with the Hawksmoor west towers (-X), flying buttresses, transept
## gables with rose windows, the crossing lantern, the apse and Henry
## VII's Lady Chapel with its turrets at the east end.
static func westminster_abbey(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDAF8F", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6E757A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	var rot := Basis(Vector3.UP, PI * 0.5)
	LandmarkWestKit.blk(lm, "Stone", -1.5, 0, 0, 127.0, 20.0, 34.0)
	LandmarkWestKit.blk(lm, "Lead", -1.5, 20.0, 0, 126.0, 0.6, 33.0)
	LandmarkWestKit.blk(lm, "Stone", -1.5, 20.0, 0, 127.0, 11.0, 17.0)
	lm.gable("Lead", Vector3(-1.5, 31.0, 0), 17.0, 127.0, 9.0, rot, 0.8, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 8.0, 0, 0, 18.0, 31.0, 62.0)
	lm.gable("Lead", Vector3(8.0, 31.0, 0), 18.0, 62.0, 9.0, Basis(), 0.8, "Stone")
	for sz in [-1.0, 1.0]:
		lm.disc("Glass", Vector3(8.0, 27.0, sz * 31.1), Vector3(0, 0, sz), 3.6)
		LandmarkWestKit.win_line(lm, "Glass", Vector3(-58, 0, sz * 17.1), Vector3(54, 0, sz * 17.1),
			Vector3(0, 0, sz), 6.0, 2.0, 8.0, [10.0])
		for k in 14:
			var x := -60.0 + 8.6 * float(k)
			lm.box("Stone", Vector3(x, 12.0, sz * 17.8), Vector3(1.6, 24.0, 1.6))
			lm.spire("Stone", Vector3(x, 24.0, sz * 17.8), 0.9, 4.0)
			lm.beam("Stone", Vector3(x, 23.5, sz * 17.4), Vector3(x, 28.5, sz * 8.6), 1.2, 1.0)
	# Crossing lantern, apse and Henry VII Chapel with turrets.
	LandmarkWestKit.blk(lm, "Stone", 8.0, 38.0, 0, 9.0, 8.0, 9.0)
	LandmarkWestKit.hip(lm, "Lead", Vector3(8.0, 46.0, 0), 10.0, 10.0, 5.0, 0.0)
	lm.lathe("Stone", Vector3(60, 0, 0), PackedVector2Array([Vector2(13, 0), Vector2(13, 20)]), 12,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(60, 20, 0), PackedVector2Array([Vector2(14, 0), Vector2(8.0, 5.0),
		Vector2(0.0, 16.0)]), 12, 1.0, 1.0, 0.0, false)
	LandmarkWestKit.blk(lm, "Stone", 72.0, 0, 0, 16.0, 22.0, 17.0)
	LandmarkWestKit.hip(lm, "Lead", Vector3(72.0, 22.0, 0), 17.0, 18.0, 3.5, 0.6)
	for sx in [64.5, 79.5]:
		for sz in [-8.5, 8.5]:
			lm.frustum("Stone", Vector3(sx, 0, sz), 1.8, 1.6, 25.0, 8)
			lm.lathe("Lead", Vector3(sx, 25.0, sz), PackedVector2Array([Vector2(2.1, 0), Vector2(1.4, 1.5),
				Vector2(0.0, 3.5)]), 8)
	# West front: centre gable with the great window, portals, towers.
	LandmarkWestKit.blk(lm, "Stone", -71.5, 0, 0, 13.0, 31.0, 11.0)
	lm.gable("Stone", Vector3(-71.5, 31.0, 0), 11.0, 13.0, 9.0, rot, 0.0, "Stone")
	lm.box("Glass", Vector3(-78.1, 24.0, 0), Vector3(0.3, 12.0, 5.0))
	lm.box("Glass", Vector3(-78.1, 4.5, 0), Vector3(0.3, 9.0, 4.5))
	for sz in [-1.0, 1.0]:
		var c := Vector3(-71.5, 0, sz * 11.25)
		LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 13.0, 60.0, 11.5)
		LandmarkWestKit.blk(lm, "Stone", c.x, 60.0, c.z, 11.0, 6.0, 10.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 66.0, c.z, 12.0, 0.6, 11.0)
		for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
			lm.spire("Stone", c + Vector3(q.x * 5.2, 66.6, q.y * 4.6), 0.7, 2.4, 0.0)
		for s in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(s))
			lm.box("Glass", c + r * Vector3(0, 40.0, 5.8 if s % 2 == 0 else 6.55), Vector3(2.2, 14.0, 0.3), r)
			lm.box("Glass", c + r * Vector3(0, 63.0, 5.1 if s % 2 == 0 else 5.55), Vector3(2.4, 4.0, 0.3), r)
	lm.commit(model)
