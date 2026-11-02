class_name LandmarkRmLModern
extends RefCounted

## The Palazzo della Civiltà Italiana, the Stadio Olimpico and the Sistine
## Chapel with the Vatican palaces around it, in true metres.

# --- Palazzo della Civiltà Italiana -------------------------------------------

## The "Square Colosseum" of EUR, origin at its centre: a 51.6 m cube
## of white travertine, 57.25 m to the cornice, with six arches along
## and nine tiers of arches up each of the four identical faces, on a
## three-tier stylobate of steps (68 m in all); the Dioscuri groups
## stand at the corners of the podium.
static func civilta(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4DABF", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE7D2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D6CDB4", 2.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	var y0 := 10.25
	for t in 3:
		var side := 69.6 - 6.0 * float(t)
		var tier_h := y0 / 3.0 * float(t + 1)
		lm.box("Steps", Vector3(0, tier_h * 0.5, 0), Vector3(side, tier_h, side))
	lm.box("Stone", Vector3(0, y0 + 28.625, 0), Vector3(51.6, 57.25, 51.6))
	lm.box("Trim", Vector3(0, y0 + 57.5, 0), Vector3(52.6, 0.5, 52.6))
	lm.box("Trim", Vector3(0, y0 + 0.4, 0), Vector3(52.2, 0.8, 52.2))
	var row_h := 57.25 / 9.0
	for f in 4:
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var o := Vector3(0, y0, 0) + out * 25.8
		for r in 9:
			SEuUtil.face_row(lm, "Shadow", o, Vector3.UP.cross(out), out, row_h * float(r) + 0.5,
				6, 8.6, 5.8, 5.4)
		for r in range(1, 9):
			var slab := Vector3(51.8, 0.4, 0.5) if absf(out.z) > 0.5 else Vector3(0.5, 0.4, 51.8)
			lm.box("Trim", Vector3(0, y0 + row_h * float(r) - 0.2, 0) + out * 25.85, slab)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(float(sx) * 31.5, 10.2, float(sz) * 31.5)
			lm.box("Marble", c + Vector3(0, 0.6, 0), Vector3(3.6, 1.2, 6.4))
			LandmarkRmLUtil.horse(lm, "Marble", c + Vector3(0, 1.2, 0.0))
			LandmarkKits.statue_figure(lm, "Marble", c + Vector3(1.6, 1.2, -0.8), 5.0)
	lm.commit(model)

# --- Stadio Olimpico ----------------------------------------------------------------

## The Foro Italico stadium, origin at the centre of the pitch, long axis
## along X (yaw_deg lays it on the real N-S axis): the 302 x 232 m oval
## of concrete stands round the 105 x 68 m pitch and athletics track, the
## outer wall with its slit windows, and the membrane roof cantilevered
## over the seats from 24 steel masts (36 m at the rim).
static func olimpico(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Grass", LandmarkMaterials.pbr("lawn", "#5E8F3E", 4.0))
	lm.use("Track", LandmarkMaterials.pbr("terracotta", "#B5553A", 3.0))
	lm.use("Seats", LandmarkMaterials.pbr("concrete", "#6F7F99", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#B8B4AA", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C3A36", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("render", "#EDEDED", 4.0, 0.7))
	lm.use("Steel", LandmarkMaterials.paint("#D9DADA", 0.5, 0.5))
	var sx := 1.3
	lm.box("Grass", Vector3(0, 0.1, 0), Vector3(105.0, 0.2, 68.0))
	lm.lathe("Track", Vector3(0, 0.12, 0), PackedVector2Array([Vector2(60.0, 0.0), Vector2(53.0, 0.0)]),
		48, sx, 1.0, 0.0, false, false)
	# Seating bowl: terraces from the outside in, then the concrete shell.
	lm.lathe("Seats", Vector3.ZERO, PackedVector2Array([Vector2(106.0, 27.0), Vector2(84.0, 14.0),
		Vector2(80.0, 14.0), Vector2(62.0, 1.5), Vector2(60.0, 1.5)]), 48, sx, 1.0, 0.0, false, false)
	lm.lathe("Wall", Vector3.ZERO, PackedVector2Array([Vector2(112.0, 0.0), Vector2(112.0, 23.0),
		Vector2(104.0, 28.0)]), 48, sx, 1.0, 0.0, false, false)
	for k in 72:
		var a := TAU * float(k) / 72.0
		var p := Vector3(cos(a) * 112.0 * sx, 0, sin(a) * 112.0)
		var n := Vector3(cos(a) / sx, 0, sin(a)).normalized()
		lm.box("Shadow", p + n * 0.1 + Vector3(0, 6.0, 0), Vector3(2.4, 7.0, 0.3), Basis(Vector3.UP, atan2(n.x, n.z)))
		lm.box("Shadow", p + n * 0.1 + Vector3(0, 16.0, 0), Vector3(2.4, 5.0, 0.3), Basis(Vector3.UP, atan2(n.x, n.z)))
	# Cantilever roof: top skin, soffit, rims and the supporting masts.
	lm.lathe("Roof", Vector3.ZERO, PackedVector2Array([Vector2(116.0, 36.0), Vector2(76.0, 30.0)]), 48,
		sx, 1.0, 0.0, false, false)
	lm.lathe("Roof", Vector3.ZERO, PackedVector2Array([Vector2(76.0, 29.0), Vector2(116.0, 35.0)]), 48,
		sx, 1.0, 0.0, false, false)
	lm.lathe("Roof", Vector3.ZERO, PackedVector2Array([Vector2(116.0, 35.0), Vector2(116.0, 36.0)]), 48,
		sx, 1.0, 0.0, false, false)
	lm.lathe("Roof", Vector3.ZERO, PackedVector2Array([Vector2(76.0, 30.0), Vector2(76.0, 29.0)]), 48,
		sx, 1.0, 0.0, false, false)
	for k in 24:
		var a := TAU * (float(k) + 0.5) / 24.0
		var foot := Vector3(cos(a) * 124.0 * sx, 0, sin(a) * 124.0)
		var tip := Vector3(cos(a) * 114.0 * sx, 35.0, sin(a) * 114.0)
		lm.beam("Steel", foot, tip, 1.4, 1.0)
		lm.beam("Steel", tip, Vector3(cos(a) * 80.0 * sx, 29.5, sin(a) * 80.0), 0.35, 0.35)
	lm.commit(model)

# --- Sistine Chapel ---------------------------------------------------------------------

## Origin at the middle of the chapel, long axis along X: Sixtus IV's
## plain brick hall (40.9 x 13.4 m, buttressed, 20.7 m to the ridge of
## its tiled roof) with the Vatican palaces closing the courts round it
## (Apostolic Palace to the east, the Museums' wings north and south).
static func sistine(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6A4C", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#CDB48A", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E1D6BC", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.box("Brick", Vector3(0, 8.6, 0), Vector3(40.9, 17.2, 13.4))
	lm.box("Trim", Vector3(0, 17.4, 0), Vector3(41.7, 0.5, 14.2))
	lm.gable("Tile", Vector3(0, 17.6, 0), 13.4, 40.9, 3.1, Basis(Vector3.UP, PI * 0.5), 0.4, "Brick")
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, s * 6.7), Vector3.RIGHT, Vector3(0, 0, s), 8.0, 6, 6.2, 1.8, 5.4, true)
		for i in 7:
			lm.box("Brick", Vector3(-18.6 + 6.2 * float(i), 8.6, s * 7.15), Vector3(1.0, 17.2, 0.9))
	SEuUtil.face_row(lm, "Shadow", Vector3(20.45, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 0), 9.0, 1, 4.0, 2.0, 6.0)
	# Palaces closing the courts: north and south wings, east palace, west range.
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(0, 0, -27.0), 52.0, 16.5, 16.0, Vector3(0, 0, 1), 4, 11, 1.6, 2.4)
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(0, 0, 28.0), 60.0, 16.0, 22.0, Vector3(0, 0, -1), 4, 12, 1.6, 2.4)
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(62.0, 0, 2.0), 90.0, 19.5, 24.0, Vector3(-1, 0, 0), 4, 12, 1.8, 2.5)
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(-42.0, 0, 2.0), 44.0, 15.5, 16.0, Vector3(1, 0, 0), 4, 8, 1.6, 2.4)
	lm.box("Plaster", Vector3(38.0, 8.25, -27.0), Vector3(24.0, 16.5, 16.0))
	lm.box("Plaster", Vector3(40.0, 8.0, 28.0), Vector3(20.0, 16.0, 22.0))
	lm.box("Trim", Vector3(38.0, 16.9, -27.0), Vector3(25.0, 0.8, 17.0))
	lm.box("Trim", Vector3(40.0, 16.4, 28.0), Vector3(21.0, 0.8, 23.0))
	lm.commit(model)
