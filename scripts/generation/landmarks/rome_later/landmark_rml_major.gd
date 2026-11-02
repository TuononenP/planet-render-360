class_name LandmarkRmLMajor
extends RefCounted

## Santa Maria Maggiore and St John Lateran, two of Rome's four major
## basilicas, in true metres.

# --- Santa Maria Maggiore -------------------------------------------------

## Origin at the middle of the basilica, Fuga's facade facing +Z toward
## Piazza Santa Maria Maggiore (yaw_deg turns it onto the real bearing):
## the 70 m facade of a five-arched portico under a gold-mosaic loggia,
## statues on the balustrade and the two domed corner pavilions; the
## long nave and aisles with the tiled ridge; at the rear Rainaldi's apse
## front and the two domed chapels; and the 75 m Romanesque campanile,
## the tallest in Rome, beside the right aisle.
static func maggiore(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#CDB48A", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D4C5A2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DCC4", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A06C4C", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CFC2A6", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# Nave with clerestory, aisles, and the tiled ridge.
	lm.box("Plaster", Vector3(0, 9.0, -2.0), Vector3(46.0, 18.0, 86.0))
	lm.box("Plaster", Vector3(0, 24.0, -2.0), Vector3(21.0, 12.0, 86.0))
	lm.gable("Tile", Vector3(0, 30.0, -2.0), 21.0, 86.0, 4.5, Basis(), 0.5, "Plaster")
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(s * 23.0, 18.2, -2.0), Vector3(1.6, 0.8, 86.0))
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 10.5, 0, -2.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			20.0, 7, 11.0, 2.0, 5.5)
	# Fuga's facade: portico, loggia, balustrade, statues and pavilions.
	lm.box("Stone", Vector3(0, 14.0, 45.5), Vector3(37.0, 28.0, 5.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 48.0), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 5, 7.4, 5.4, 10.5)
	SEuUtil.column_row(lm, "Trim", Vector3(-11.1, 0, 48.6), Vector3(11.1, 0, 48.6), 4, 11.5, 0.9, 14)
	lm.box("Trim", Vector3(0, 12.0, 47.5), Vector3(38.0, 1.4, 5.8))
	for x in [-7.8, 0.0, 7.8]:
		SEuUtil.opening(lm, "Gold", Vector3(float(x), 13.2, 48.06), Vector3.RIGHT, Vector3.UP, 6.0, 9.6)
	for x in [-11.7, -3.9, 3.9, 11.7]:
		lm.box("Trim", Vector3(float(x), 18.0, 48.3), Vector3(1.2, 11.0, 0.8))
	lm.box("Trim", Vector3(0, 24.6, 46.0), Vector3(38.6, 1.2, 6.6))
	lm.box("Trim", Vector3(0, 26.3, 46.6), Vector3(37.6, 2.2, 0.8))
	for i in 5:
		LandmarkKits.statue_figure(lm, "Trim", Vector3(-14.0 + 7.0 * float(i), 27.4, 46.6), 4.4)
	for s in [-1.0, 1.0]:
		var wx: float = s * 26.8
		lm.box("Plaster", Vector3(wx, 12.5, 45.5), Vector3(16.6, 25.0, 5.0))
		lm.box("Trim", Vector3(wx, 25.4, 45.5), Vector3(17.6, 0.8, 6.0))
		for y in [3.2, 11.4, 18.6]:
			SEuUtil.face_row(lm, "Shadow", Vector3(wx, 0, 48.0), Vector3.RIGHT, Vector3(0, 0, 1),
				float(y), 2, 6.0, 1.8, 3.6)
		LandmarkKits.dome_on_drum(lm, "Plaster", "Dome", Vector3(wx, 25.8, 44.0), 4.4, 2.5, 5.0, 2.8, 16)
		SEuUtil.finial(lm, "Gold", Vector3(wx, 36.1, 44.0), 2.0)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, 48.6), Vector3(0, 0, 1), 40.0, 0.7, 0.22, 4)
	# Rear: apse front between the two domed chapels.
	lm.box("Plaster", Vector3(0, 13.0, -48.0), Vector3(50.0, 26.0, 8.0))
	LandmarkRmLUtil.pilasters(lm, "Trim", Vector3(0, 0, -52.0), Vector3(0, 0, -1), 6, 8.0, 24.0, 1.4, 0.7)
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(0, 26.0, -52.0), 24.0, 4.0, 2.0)
	for s in [-1.0, 1.0]:
		lm.box("Plaster", Vector3(s * 27.0, 11.0, -32.0), Vector3(16.0, 22.0, 20.0))
		LandmarkRmLUtil.dome_stack(lm, Vector3(s * 27.0, 22.0, -32.0), 7.0 if s < 0.0 else 8.0,
			5.0, 8.0, 4.0, 20.5, 8, 8)
	# Romanesque campanile in brick bands, pyramidal tiled spire and cross.
	var tiers := PackedVector2Array([Vector2(22.0, 5.4), Vector2(8.5, 5.2), Vector2(8.5, 5.0),
		Vector2(8.5, 4.8), Vector2(8.5, 4.6), Vector2(8.0, 4.4)])
	LandmarkRmLUtil.tower(lm, "Brick", Vector3(31.0, 0, 8.0), tiers, 73.5, "Tile")
	SEuUtil.finial(lm, "Gold", Vector3(31.0, 73.5, 8.0), 1.5)
	lm.commit(model)

# --- St John Lateran ----------------------------------------------------------

## Origin at the middle of the basilica, Galilei's facade facing +Z (east
## by the Lateran; yaw_deg turns it): the 60 m travertine front of a
## giant composite order over five portals, an attic with fifteen
## colossal statues (Christ 6.3 m at the centre, 39 m to his hand), the
## 124 m nave and double aisles under the tiled roof, the transept with
## Fontana's north loggia, the apse, the Lateran Palace beside it, and,
## 99 m behind the apse, the octagonal baptistery with its pyramidal
## dome and lantern.
static func lateran(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#CDB48A", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C8A7", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DFC8", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CFC2A6", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	# Aisles, clerestory and roof, transept, apse.
	lm.box("Plaster", Vector3(0, 11.0, -1.0), Vector3(56.0, 22.0, 124.0))
	lm.box("Plaster", Vector3(0, 26.5, -1.0), Vector3(30.0, 9.0, 124.0))
	lm.gable("Tile", Vector3(0, 31.0, -1.0), 30.0, 124.0, 4.5, Basis(), 0.5, "Plaster")
	lm.box("Plaster", Vector3(0, 16.0, -30.0), Vector3(92.0, 32.0, 26.0))
	lm.gable("Tile", Vector3(0, 32.0, -30.0), 26.0, 92.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	lm.frustum("Plaster", Vector3(0, 0, -63.0), 15.0, 15.0, 30.0, 24)
	lm.lathe("Tile", Vector3(0, 30.0, -63.0), SEuUtil.dome(15.3, 6.0, 6), 24)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 15.0, 0, -1.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			24.0, 9, 12.0, 2.4, 4.4)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 28.0, 0, -1.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			6.0, 9, 12.0, 2.4, 5.8)
	# Fontana's north loggia on the transept end (+X).
	lm.box("Stone", Vector3(46.8, 14.0, -30.0), Vector3(2.0, 28.0, 22.0))
	LandmarkRmLUtil.pilasters(lm, "Trim", Vector3(47.8, 0, -30.0), Vector3(1, 0, 0), 6, 4.0, 26.0, 1.0, 0.6)
	SEuUtil.face_row(lm, "Shadow", Vector3(47.8, 0, -30.0), Vector3(0, 0, 1), Vector3(1, 0, 0), 0.0, 5, 4.0, 2.6, 8.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(47.8, 0, -30.0), Vector3(0, 0, 1), Vector3(1, 0, 0), 13.0, 3, 6.0, 3.0, 7.0)
	lm.box("Trim", Vector3(47.2, 28.4, -30.0), Vector3(3.0, 1.0, 23.0))
	lm.gable("Trim", Vector3(47.2, 28.9, -30.0), 22.0, 2.4, 4.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Trim")
	# Galilei's facade.
	lm.box("Stone", Vector3(0, 13.55, 63.0), Vector3(60.0, 27.1, 6.0))
	for x in [-16.5, -5.5, 5.5, 16.5]:
		lm.box("Stone", Vector3(float(x), 2.25, 66.9), Vector3(3.6, 4.5, 3.6))
		lm.frustum("Trim", Vector3(float(x), 4.5, 66.9), 1.25, 1.1, 20.0, 14)
		lm.box("Trim", Vector3(float(x), 24.8, 66.9), Vector3(3.0, 0.7, 3.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 28.2, 2.25, 66.6), Vector3(3.4, 4.5, 2.2))
		lm.box("Trim", Vector3(s * 28.2, 14.5, 66.6), Vector3(2.8, 20.0, 1.2))
	lm.box("Trim", Vector3(0, 25.8, 66.0), Vector3(62.0, 2.6, 2.8))
	lm.box("Stone", Vector3(0, 29.0, 64.5), Vector3(60.0, 3.8, 3.0))
	lm.box("Trim", Vector3(0, 31.2, 64.6), Vector3(61.6, 0.6, 3.6))
	lm.box("Trim", Vector3(0, 32.1, 63.8), Vector3(60.0, 1.2, 0.6))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 66.0), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 5, 11.0, 5.0, 9.5)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 66.0), Vector3.RIGHT, Vector3(0, 0, 1), 13.0, 5, 11.0, 3.6, 6.0)
	for x in [-22.0, -11.0, 0.0, 11.0, 22.0]:
		lm.box("Trim", Vector3(float(x), 11.3, 66.5), Vector3(5.4, 0.6, 1.4))
	for i in 15:
		var central := i == 7
		LandmarkKits.statue_figure(lm, "Marble", Vector3(-29.4 + 4.2 * float(i), 32.7, 64.2),
			6.3 if central else 5.6, central)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, 68.6), Vector3(0, 0, 1), 62.0, 0.8, 0.25, 4)
	# Lateran Palace to the north-east and the baptistery behind the apse.
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(76.0, 0, 18.0), 60.0, 30.0, 34.0, Vector3(-1, 0, 0), 5, 10, 1.6, 3.0)
	var bp := Vector3(50.0, 0, -99.0)
	lm.frustum("Plaster", bp, 11.4, 11.4, 14.0, 8, PI / 8.0)
	lm.frustum("Trim", bp + Vector3(0, 14.0, 0), 12.2, 12.2, 0.9, 8, PI / 8.0)
	var cone := PackedVector2Array([Vector2(11.8, 0.0), Vector2(9.0, 4.2), Vector2(5.5, 8.2), Vector2(2.8, 10.5)])
	lm.lathe("Tile", bp + Vector3(0, 14.9, 0), cone, 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Stone", bp + Vector3(0, 25.4, 0), 2.8, 2.6, 3.2, 8, PI / 8.0)
	lm.lathe("Dome", bp + Vector3(0, 28.6, 0), SEuUtil.dome(2.9, 1.4, 4), 8)
	SEuUtil.finial(lm, "Gold", bp + Vector3(0, 30.0, 0), 2.2)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0 + PI / 8.0
		SEuUtil.opening(lm, "Shadow", bp + Vector3(cos(a), 0, sin(a)) * 10.55 + Vector3(0, 5.0, 0),
			Vector3.UP.cross(Vector3(cos(a), 0, sin(a))), Vector3.UP, 2.2, 5.0)
	lm.commit(model)
