class_name LandmarkNaMonuments
extends RefCounted

## Three commemorative monuments in true metres: the Washington
## Monument and Lincoln Memorial on the National Mall, and Mexico City's
## Angel of Independence.

const WASHINGTON_TOP_M := 169.0
const LINCOLN_TOP_M := 30.0
const ANGEL_TOP_M := 36.0

## Washington Monument: the 169 m white-marble obelisk, 16.8 m square at
## the foot narrowing to 10.5 m under the 16 m pyramidion, its eight
## small observation windows and the aluminium apex, on a low mound.
static func washington_monument(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6E3DB", 3.0))
	lm.use("Cap", LandmarkMaterials.paint("#D8DCE0", 0.25, 0.9))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9C968B", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.spire("Marble", Vector3.ZERO, 8.4, 152.2, 5.25)
	lm.spire("Marble", Vector3(0, 152.2, 0), 5.25, 16.2, 0.35)
	lm.spire("Cap", Vector3(0, 168.4, 0), 0.35, WASHINGTON_TOP_M - 168.4, 0.0)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		for x in [-1.3, 1.3]:
			lm.box("Windows", r * Vector3(x, 154.0, 4.72), Vector3(0.8, 1.3, 0.2), r)
	lm.frustum("Granite", Vector3(0, -1.0, 0), 30.0, 26.0, 1.4, 32)
	lm.box("Granite", Vector3(0, 0.6, 0), Vector3(19.5, 1.2, 19.5))
	lm.commit(model)

## Lincoln Memorial: the Doric temple of 36 Colorado Yule marble
## columns (12 on each long side, 8 on each end, one per state then),
## the entablature and attic with their festoons, the cella behind and
## the low skylit roof to 30 m, on three terraces with the broad flight
## of steps down the east front toward the Reflecting Pool (+X).
static func lincoln_memorial(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2DFD7", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CBC6BB", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8C9192", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	lm.box("Steps", Vector3(0, 0.8, 0), Vector3(72.0, 1.6, 48.0))
	lm.box("Steps", Vector3(0, 2.4, 0), Vector3(66.0, 1.6, 44.0))
	lm.box("Marble", Vector3(0, 3.85, 0), Vector3(62.0, 1.3, 41.0))
	for k in 6:
		var top := 4.5 - 0.7 * float(k + 1)
		lm.box("Steps", Vector3(31.6 + 1.2 * k, top * 0.5, 0), Vector3(1.2, top, 32.0 - 2.0 * k))
	# Peristyle: 12 columns per long side, 6 inner columns per end.
	var cy := 4.5
	for sx in [-1.0, 1.0]:
		LandmarkNaParts.columns(lm, "Marble", Vector3(sx * 16.5, cy, -27.5),
			Vector3(sx * 16.5, cy, 27.5), 12, 1.15, 0.95, 13.4, 12)
	for sz in [-1.0, 1.0]:
		LandmarkNaParts.columns(lm, "Marble", Vector3(-16.5 + 33.0 / 7.0, cy, sz * 27.5),
			Vector3(16.5 - 33.0 / 7.0, cy, sz * 27.5), 6, 1.15, 0.95, 13.4, 12)
	lm.box("Marble", Vector3(0, 19.6, 0), Vector3(35.6, 3.4, 58.6))
	lm.box("Marble", Vector3(0, 12.9, 0), Vector3(27.0, 16.8, 44.0))
	lm.box("Door", Vector3(13.6, 9.3, 0), Vector3(0.4, 9.6, 11.0))
	lm.box("Marble", Vector3(0, 23.6, 0), Vector3(31.0, 4.6, 51.0))
	lm.box("Marble", Vector3(0, 25.6, 0), Vector3(32.0, 0.6, 52.0))
	lm.box("Roof", Vector3(0, 27.95, 0), Vector3(25.0, 4.1, 43.0))
	# Festoon panels along the attic faces.
	var spans := [28.0, 46.0, 28.0, 46.0]
	var outs := [25.7, 15.7, 25.7, 15.7]
	for q in 4:
		LandmarkNaParts.windows(lm, "Steps", Vector3.ZERO, Basis(Vector3.UP, PI * 0.5 * q),
			float(spans[q]), 22.2, 25.0, 1, 8 if q % 2 == 0 else 12, Vector2(2.6, 1.8), float(outs[q]))
	lm.commit(model)

## Angel of Independence: the stepped base with its four corner
## sculpture groups, the 17 m fluted Corinthian column and capital, and
## the gilded winged Victory (6.7 m) with her laurel wreath held aloft,
## to 36 m.
static func angel_of_independence(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5CDBB", 3.0))
	lm.use("Column", LandmarkMaterials.pbr("limestone", "#E3DCCB", 2.5))
	lm.use("Bronze", LandmarkMaterials.paint("#4B4033", 0.5, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	for k in 3:
		lm.box("Stone", Vector3(0, 0.3 + 0.6 * k, 0), Vector3(26.0 - 3.0 * k, 0.6, 26.0 - 3.0 * k))
	lm.box("Stone", Vector3(0, 4.65, 0), Vector3(14.0, 5.7, 14.0))
	lm.box("Stone", Vector3(0, 7.7, 0), Vector3(11.0, 0.8, 11.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(sx * 8.8, 2.8, sz * 8.8), Vector3(3.2, 2.2, 3.2))
			LandmarkKits.statue_figure(lm, "Bronze", Vector3(sx * 8.8, 3.9, sz * 8.8), 4.2)
	lm.frustum("Column", Vector3(0, 8.1, 0), 2.0, 1.6, 17.4, 16)
	lm.frustum("Column", Vector3(0, 25.5, 0), 1.6, 2.6, 1.8, 16)
	lm.frustum("Stone", Vector3(0, 27.3, 0), 3.0, 3.0, 0.8, 4, PI / 4.0)
	lm.frustum("Stone", Vector3(0, 28.1, 0), 1.3, 1.0, 1.2, 12)
	var b := Vector3(0, 29.3, 0)
	lm.lathe("Gold", b, PackedVector2Array([Vector2(0.95, 0.0), Vector2(0.7, 1.8), Vector2(0.55, 3.4),
		Vector2(0.65, 4.3), Vector2(0.3, 4.9), Vector2(0.22, 5.1)]), 12)
	lm.lathe("Gold", b + Vector3(0, 5.1, 0), PackedVector2Array([Vector2(0.25, 0.0), Vector2(0.4, 0.25),
		Vector2(0.4, 0.6), Vector2(0.2, 0.9), Vector2(0.0, 1.0)]), 10)
	lm.beam("Gold", b + Vector3(0.25, 4.6, 0), b + Vector3(1.4, 6.3, 0), 0.35, 0.35)
	lm.frustum("Gold", b + Vector3(1.4, 6.5, 0), 0.5, 0.5, 0.2, 10)
	# Wings swept back (-Z) from the shoulders, drawn from both sides.
	for s in [-1.0, 1.0]:
		var pts := [b + Vector3(s * 0.2, 3.2, -0.5), b + Vector3(s * 0.2, 4.8, -0.5),
			b + Vector3(s * 3.0, 6.2, -0.8), b + Vector3(s * 3.2, 3.6, -0.8)]
		for nz in [-1.0, 1.0]:
			lm.quad("Gold", pts[0], pts[1], pts[2], pts[3], Vector3(0, 0, nz))
	lm.commit(model)
