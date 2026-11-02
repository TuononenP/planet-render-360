class_name SEuPisa
extends RefCounted

## Piazza dei Miracoli in true metres, origin at the foot of the Leaning
## Tower: the 56 m campanile of eight cylindrical storeys (blind-arcaded
## base, six open colonnaded galleries, the smaller bell chamber) leaning
## 3.97° to the south (+Z); the Romanesque cathedral (west facade of four
## arcade tiers, nave, transept, apse, oval dome) to the north-west and
## the round Baptistery with its pointed dome 130 m to the west.

## tan of the 3.97° lean: the axis shifts this far south per metre of height.
const LEAN := 0.0694
const TOWER_R := 7.75
const CATHEDRAL := Vector3(-40.0, 0.0, -38.0)
const BAPTISTERY := Vector3(-132.0, 0.0, -36.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE4D6", 3.0))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#A9ADA6", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F483E", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("concrete", "#8E9094", 2.0, 0.5, 0.4))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	_tower(lm)
	_cathedral(lm)
	_baptistery(lm)
	lm.commit(model)

## A point on the leaning axis at height y.
static func _ax(y: float) -> Vector3:
	return Vector3(0, y, y * LEAN)

static func _tower(lm: LandmarkMesh) -> void:
	lm.frustum("Grey", Vector3(0, -3.0, 0), TOWER_R + 1.0, TOWER_R + 0.6, 3.0, 24)
	# Ground storey: marble drum with a blind arcade of fifteen arches.
	lm.frustum("Marble", _ax(0.0), TOWER_R, TOWER_R, 8.6, 24)
	lm.frustum("Grey", _ax(0.0), TOWER_R + 0.35, TOWER_R + 0.2, 0.8, 24)
	SEuUtil.ring_openings(lm, "Shadow", _ax(0.0), TOWER_R, 24, 15, 1.2, 1.9, 5.6)
	# Six galleries: dark core, a ring of thirty columns, floor slab above.
	for f in 6:
		var y0 := 8.6 + 5.9 * float(f)
		var c := _ax(y0)
		lm.frustum("Marble", c, TOWER_R, TOWER_R, 0.7, 24)
		lm.frustum("Shadow", c + Vector3(0, 0.7, 0), TOWER_R - 1.5, TOWER_R - 1.5, 4.5, 24)
		SEuUtil.column_ring(lm, "Marble", c + Vector3(0, 0.7, 0), TOWER_R - 0.55, 30, 4.5, 0.32, 8)
		lm.frustum("Marble", c + Vector3(0, 5.2, 0), TOWER_R + 0.1, TOWER_R, 0.7, 24)
	# Bell chamber: narrower drum, arched openings, cornice, flat lead roof.
	var by := 44.0
	lm.frustum("Marble", _ax(by), 6.0, 6.0, 9.0, 20)
	SEuUtil.ring_openings(lm, "Shadow", _ax(by), 6.0, 20, 12, 3.0, 1.5, 4.2, false, 0.2)
	lm.frustum("Grey", _ax(by + 9.0), 6.7, 6.4, 1.2, 20)
	lm.lathe("Lead", _ax(by + 10.2), PackedVector2Array([Vector2(5.6, 0), Vector2(4.4, 1.0),
		Vector2(0.0, 1.8)]), 20)

static func _cathedral(lm: LandmarkMesh) -> void:
	var c := CATHEDRAL
	var along := Basis(Vector3.UP, PI * 0.5)
	# Nave (five aisles read as a tall centre plus two lower sides).
	lm.box("Marble", c + Vector3(0, 12.0, 0), Vector3(92.0, 24.0, 20.0))
	lm.gable("Lead", c + Vector3(0, 24.0, 0), 20.0, 92.0, 7.0, along, 0.6, "Marble")
	for s in [-1.0, 1.0]:
		lm.box("Marble", c + Vector3(0, 7.0, s * 15.0), Vector3(92.0, 14.0, 10.0))
		lm.gable("Lead", c + Vector3(0, 14.0, s * 15.0), 10.0, 92.0, 2.4, along, 0.3)
	# Transept across the east end, apse beyond it.
	lm.box("Marble", c + Vector3(14.0, 12.0, 0), Vector3(20.0, 24.0, 54.0))
	lm.gable("Lead", c + Vector3(14.0, 24.0, 0), 20.0, 54.0, 6.0, Basis(), 0.6, "Marble")
	lm.frustum("Marble", c + Vector3(46.0, 0, 0), 11.0, 11.0, 20.0, 12)
	lm.lathe("Lead", c + Vector3(46.0, 20.0, 0), SEuUtil.dome(11.4, 6.0, 6), 12)
	# Striped bands of grey marble along the long walls.
	for s in [-1.0, 1.0]:
		for k in 3:
			lm.box("Grey", c + Vector3(0, 3.0 + 4.0 * float(k), s * 20.05), Vector3(92.0, 0.5, 0.2))
		SEuUtil.face_row(lm, "Shadow", c + Vector3(0, 0, s * 20.1), Vector3.RIGHT, Vector3(0, 0, s),
			1.5, 20, 4.4, 1.6, 4.5)
	# Crossing dome (egg-shaped) on its drum.
	LandmarkKits.dome_on_drum(lm, "Marble", "Lead", c + Vector3(14.0, 24.0, 0), 7.5, 5.0, 8.0,
		4.0, 20)
	# West facade: four tiers of arcades under a stepped gable.
	var fx := c.x - 46.5
	lm.box("Marble", Vector3(fx, 15.0, c.z), Vector3(4.0, 30.0, 36.0))
	lm.gable("Marble", Vector3(fx, 30.0, c.z), 36.0, 4.0, 6.0, along, 0.0, "Marble")
	var face := Vector3(fx - 2.0, 0, c.z)
	var counts := [7, 9, 11, 13]
	var ys := [1.5, 8.0, 14.0, 20.0]
	for t in 4:
		SEuUtil.face_row(lm, "Shadow", face, Vector3(0, 0, 1), Vector3(-1, 0, 0), float(ys[t]),
			int(counts[t]), 36.0 / float(counts[t]) * 0.95, 36.0 / float(counts[t]) * 0.55,
			6.0 if t == 0 else 4.8)
		lm.box("Grey", face + Vector3(0.05, float(ys[t]) + (7.0 if t == 0 else 5.8), 0),
			Vector3(0.3, 0.6, 36.0))

static func _baptistery(lm: LandmarkMesh) -> void:
	var c := BAPTISTERY
	lm.frustum("Grey", c + Vector3(0, -2.0, 0), 18.8, 18.4, 2.0, 24)
	lm.frustum("Marble", c, 17.7, 17.7, 15.0, 24)
	SEuUtil.ring_openings(lm, "Shadow", c, 17.7, 24, 20, 1.2, 2.1, 8.0, false)
	lm.frustum("Grey", c + Vector3(0, 15.0, 0), 18.0, 17.8, 0.8, 24)
	lm.frustum("Marble", c + Vector3(0, 15.8, 0), 17.0, 17.0, 8.0, 24)
	SEuUtil.ring_openings(lm, "Shadow", c, 17.0, 24, 20, 17.2, 1.6, 5.0, true, 0.1)
	lm.frustum("Grey", c + Vector3(0, 23.8, 0), 17.4, 17.2, 0.8, 24)
	lm.frustum("Marble", c + Vector3(0, 24.6, 0), 14.2, 14.2, 9.4, 24)
	SEuUtil.ring_openings(lm, "Shadow", c, 14.2, 24, 12, 26.4, 1.8, 5.6, true)
	lm.lathe("Tile", c + Vector3(0, 34.0, 0), PackedVector2Array([Vector2(14.0, 0), Vector2(13.2, 3.5),
		Vector2(10.6, 8.5), Vector2(6.6, 13.2), Vector2(3.2, 16.0), Vector2(2.4, 17.0)]), 24)
	lm.frustum("Marble", c + Vector3(0, 51.0, 0), 2.4, 1.6, 2.8, 12)
	SEuUtil.finial(lm, "Gold", c + Vector3(0, 53.8, 0), 1.1)
