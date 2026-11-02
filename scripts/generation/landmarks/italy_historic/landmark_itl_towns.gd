class_name LandmarkItlTowns
extends RefCounted

## Palazzo Vecchio (Florence) and the Palazzo Pubblico with the Torre del
## Mangia (Siena) in true metres: the two great communal palaces of
## Tuscany, a crenellated block under a corbelled gallery with a slender
## tower rising off-centre.

# --- Palazzo Vecchio ------------------------------------------------------

## Origin at the centre of Arnolfo's block, the Piazza della Signoria
## front facing +Z, the 94 m tower over the right (+X) half of it. The
## rusticated pietraforte block (44 x 38 m, 22.5 m to the gallery) has
## two storeys of pointed two-light windows over a stout ground floor,
## a projecting gallery on corbels crowned with Guelph (square) merlons,
## the long Salone dei Cinquecento behind, and the tower: shaft,
## machicolated crown, arcaded belfry, red pyramid, ball and lion vane.
static func palazzo_vecchio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A88F68", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CDBB96", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C352D", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A5543A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var hx := 22.0
	var hz := 19.0
	lm.box("Stone", Vector3(0, 11.25, 0), Vector3(hx * 2.0, 22.5, hz * 2.0))
	lm.box("Trim", Vector3(0, 0.5, hz + 1.6), Vector3(hx * 2.0 - 6.0, 1.0, 3.2))
	for side in 4:
		var out := Vector3(0, 0, 1)
		var length := hx * 2.0
		var dist := hz
		if side == 1:
			out = Vector3(0, 0, -1)
		elif side >= 2:
			out = Vector3(1.0 if side == 2 else -1.0, 0, 0)
			length = hz * 2.0
			dist = hx
		var right := Vector3.UP.cross(out)
		var n := int(length / 7.4)
		var p := out * dist
		SEuUtil.face_row(lm, "Shadow", p, right, out, 9.0, n, 7.4, 1.9, 4.4, true)
		SEuUtil.face_row(lm, "Shadow", p, right, out, 16.2, n, 7.4, 1.9, 4.4, true)
		for y in [7.4, 15.0]:
			lm.box("Trim", p + out * 0.2 + Vector3(0, y, 0), Vector3(length + 0.6, 0.5, 0.5), Basis(Vector3.UP, atan2(out.x, out.z)))
		SEuUtil.face_row(lm, "Shadow", p, right, out, 1.8, int(length / 8.4), 8.4, 1.6, 3.4)
		SEuUtil.face_row(lm, "Shadow", p, right, out, 20.6, int(length / 3.4), 3.4, 1.0, 1.4, true)
	SEuUtil.opening(lm, "Shadow", Vector3(0.6, 0, hz + 0.06), Vector3.RIGHT, Vector3.UP, 3.4, 6.2)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", Vector3(0, 22.5, 0), hx, hz, 0.0, 1.3, 1.6, 2.1, false, 1.6)
	lm.gable("Tile", Vector3(0, 23.3, 0), hz * 2.0 - 3.0, hx * 2.0 - 2.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	# Salone dei Cinquecento: the long plain hall behind the palace.
	lm.box("Stone", Vector3(0, 10.0, -44.0), Vector3(24.0, 20.0, 50.0))
	lm.gable("Tile", Vector3(0, 20.0, -44.0), 24.0, 50.0, 3.8, Basis(), 0.4, "Stone")
	for sx in [-1.0, 1.0]:
		var out := Vector3(sx, 0, 0)
		SEuUtil.face_row(lm, "Shadow", out * 12.05 + Vector3(0, 0, -44.0), Vector3(0, 0, 1), out, 8.0, 6, 7.6, 2.2, 5.0, true)
	# The Arnolfo tower, off-centre to the right.
	var c := Vector3(8.0, 0, 14.0)
	LandmarkItlUtil.tower(lm, "Stone", "Shadow", c + Vector3(0, 22.5, 0), 3.8, c + Vector3(0, 64.0, 0), 3.5, 0.0,
		[[31.0, 0.9, 3.2, 1, 0.0, true], [40.0, 0.9, 3.2, 2, 2.6, true], [50.0, 0.9, 3.2, 1, 0.0, true],
		[57.0, 0.9, 3.2, 2, 2.6, true]])
	lm.disc("Trim", c + Vector3(0, 45.0, 3.75), Vector3(0, 0, 1), 1.5, 20)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", c + Vector3(0, 64.0, 0), 3.5, 3.5, 0.0, 2.0, 2.4, 2.2, false, 1.3)
	LandmarkItlUtil.tower(lm, "Trim", "Shadow", c + Vector3(0, 64.8, 0), 2.9, c + Vector3(0, 80.0, 0), 2.7, 0.0,
		[[68.2, 1.5, 6.4, 2, 2.8, false]])
	lm.box("Trim", c + Vector3(0, 80.4, 0), Vector3(6.6, 0.8, 6.6))
	lm.spire("Tile", c + Vector3(0, 80.8, 0), 2.6, 11.0)
	SEuUtil.finial(lm, "Gold", c + Vector3(0, 91.8, 0), 2.2)
	lm.commit(model)

# --- Torre del Mangia -----------------------------------------------------

const FACADE_TILT := 0.21

## Palazzo Pubblico of Siena, origin at the middle of the Campo front
## facing +Z; the building follows the curve of the Campo with a taller
## four-storey central block (travertine ground floor, brick above, three-
## light Gothic windows, swallow-tail merlons on a corbelled crown) and
## two lower wings swung forward. The 102 m Torre del Mangia stands at
## the left (-X) end on the marble Cappella di Piazza: a long red brick
## shaft, the flared stone corbel crown with battlements, the pale upper
## loggia and the marble cap.
static func torre_del_mangia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A24B2F", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC1A4", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DCCB", 2.0))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#BDB8AB", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E372F", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# Central block.
	lm.box("Stone", Vector3(0, 5.0, -18.0), Vector3(40.0, 10.0, 36.0))
	lm.box("Brick", Vector3(0, 20.5, -18.0), Vector3(40.0, 21.0, 36.0))
	lm.box("Marble", Vector3(0, 10.0, 0.2), Vector3(40.8, 0.7, 0.5))
	lm.box("Marble", Vector3(0, 18.6, 0.2), Vector3(40.8, 0.6, 0.5))
	var face := Vector3(0, 0, 0)
	SEuUtil.face_row(lm, "Shadow", face, Vector3.RIGHT, Vector3(0, 0, 1), 0.3, 5, 7.6, 2.6, 6.0, true)
	SEuUtil.face_row(lm, "Shadow", face, Vector3.RIGHT, Vector3(0, 0, 1), 11.6, 5, 7.6, 3.2, 5.8, true)
	SEuUtil.face_row(lm, "Shadow", face, Vector3.RIGHT, Vector3(0, 0, 1), 19.4, 5, 7.6, 3.2, 5.8, true)
	SEuUtil.face_row(lm, "Shadow", face, Vector3.RIGHT, Vector3(0, 0, 1), 26.6, 9, 4.2, 1.4, 2.6)
	LandmarkItlUtil.gallery(lm, "Marble", "Shadow", Vector3(0, 31.0, -18.0), 20.0, 18.0, 0.0, 0.9, 1.1, 2.0, true, 1.5)
	# Wings, swung forward round the curve of the Campo.
	for s in [-1.0, 1.0]:
		var a: float = FACADE_TILT if s < 0.0 else -FACADE_TILT
		var b := Basis(Vector3.UP, a)
		var wl := 18.0 if s < 0.0 else 16.0
		var inner := Vector3(s * 20.0, 0, 0)
		var mid := inner + b * Vector3(s * wl * 0.5, 0, -15.0)
		lm.box("Stone", mid + Vector3(0, 5.0, 0), Vector3(wl, 10.0, 30.0), b)
		lm.box("Brick", mid + Vector3(0, 17.5, 0), Vector3(wl, 15.0, 30.0), b)
		lm.box("Marble", inner + b * Vector3(s * wl * 0.5, 10.0, 0.2), Vector3(wl + 0.6, 0.6, 0.5), b)
		var fc := inner + b * Vector3(s * wl * 0.5, 0, 0)
		var right := b * Vector3(1, 0, 0)
		var out := b * Vector3(0, 0, 1)
		SEuUtil.face_row(lm, "Shadow", fc, right, out, 0.3, 2, 7.4, 2.4, 5.6, true)
		SEuUtil.face_row(lm, "Shadow", fc, right, out, 11.4, 2, 7.4, 2.8, 5.0, true)
		SEuUtil.face_row(lm, "Shadow", fc, right, out, 18.6, 2, 7.4, 2.8, 4.6, true)
		LandmarkItlUtil.gallery(lm, "Marble", "Shadow", mid + Vector3(0, 25.0, 0), wl * 0.5, 15.0, a, 0.8, 1.0, 1.8, true, 1.4)
	# Cappella di Piazza: the marble loggia at the tower foot.
	var t := Vector3(-31.5, 0, -1.4)
	lm.box("Marble", Vector3(t.x, 4.5, 5.4), Vector3(12.4, 9.0, 6.4))
	SEuUtil.face_row(lm, "Shadow", Vector3(t.x, 0, 8.6), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 3, 3.8, 3.0, 6.4, true)
	SEuUtil.face_row(lm, "Shadow", Vector3(t.x + 6.2, 0, 5.4), Vector3(0, 0, -1), Vector3(1, 0, 0), 0.0, 1, 1.0, 3.0, 6.4, true)
	lm.box("Marble", Vector3(t.x, 9.3, 5.4), Vector3(13.2, 0.7, 7.2))
	# The tower.
	var rows := [[16.0, 0.8, 2.8, 1, 0.0, false], [28.0, 0.8, 2.8, 1, 0.0, false], [40.0, 0.8, 2.8, 1, 0.0, false],
		[52.0, 0.8, 2.8, 1, 0.0, false], [64.0, 0.8, 2.8, 1, 0.0, false], [75.0, 0.8, 2.8, 2, 1.8, false]]
	LandmarkItlUtil.tower(lm, "Brick", "Shadow", t, 3.9, t + Vector3(0, 86.0, 0), 3.4, 0.0, rows)
	LandmarkItlUtil.shaft(lm, "Marble", t + Vector3(0, 86.0, 0), 3.4, t + Vector3(0, 90.2, 0), 4.1)
	LandmarkItlUtil.gallery(lm, "Marble", "Shadow", t + Vector3(0, 90.2, 0), 4.1, 4.1, 0.0, 1.2, 2.4, 1.9, false, 1.2)
	LandmarkItlUtil.tower(lm, "Grey", "Shadow", t + Vector3(0, 91.0, 0), 2.8, t + Vector3(0, 98.0, 0), 2.8, 0.0,
		[[92.4, 1.5, 4.6, 2, 1.9, false]])
	lm.box("Marble", t + Vector3(0, 98.3, 0), Vector3(6.6, 0.7, 6.6))
	lm.spire("Marble", t + Vector3(0, 98.65, 0), 2.9, 2.8)
	lm.frustum("Gold", t + Vector3(0, 101.45, 0), 0.18, 0.04, 0.55, 6)
	lm.commit(model)
