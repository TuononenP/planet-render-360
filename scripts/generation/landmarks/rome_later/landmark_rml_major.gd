class_name LandmarkRmLMajor
extends RefCounted

## Santa Maria Maggiore and St John Lateran, two of Rome's four major
## basilicas, in true metres.

# --- Santa Maria Maggiore -------------------------------------------------

## Origin at the middle of the basilica (92 x 80 m, 75 m high), Fuga's
## travertine facade (1743) facing +Z toward Piazza Santa Maria Maggiore
## (south-east; yaw_deg turns it): a five-bay portico of Ionic columns
## under the three-arched Loggia of the Blessings with the medieval gold
## mosaics glinting behind it, a balustrade with statues and the broken
## pediment; the two matching palazzi (Ponzio's on the right, Fuga's on
## the left) flank it. Behind: the nave with 21 clerestory windows a
## side, the domes of the Sistine and Pauline chapels, Rainaldi's apse
## front over its flight of steps toward Piazza dell'Esquilino with the
## Esquiline obelisk, and the 75 m Romanesque campanile, the tallest in
## Rome, rising behind the right wing.
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
		var n := Vector3(s, 0, 0)
		var r := Vector3.UP.cross(n)
		lm.box("Trim", Vector3(s * 23.0, 18.2, -2.0), Vector3(1.6, 0.8, 86.0))
		lm.quad("Tile", Vector3(s * 23.4, 18.4, 41.0), Vector3(s * 23.4, 18.4, -45.0), Vector3(s * 10.5, 21.0, -45.0),
			Vector3(s * 10.5, 21.0, 41.0), Vector3(s * 0.2, 1.0, 0).normalized())
		LandmarkDetail.pierced_face(lm, "Plaster", "Shadow", Vector3(s * 10.5, 21.0, -2.0) - r * 43.0, r, n, 86.0, 9.0,
			21, 1, Vector2(1.8, 4.6), 2.0, 9.0)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 10.85, 29.4, 41.0), Vector3(s * 10.85, 29.4, -45.0), n, 0.6, false)
		LandmarkDetail.pierced_face(lm, "Plaster", "Shadow", Vector3(s * 23.0, 0.0, -2.0) - r * 43.0, r, n, 86.0, 17.6,
			9, 1, Vector2(2.4, 5.4), 7.0, 9.0)
	_maggiore_facade(lm)
	# Rear: Rainaldi's apse front over its steps, the Esquiline obelisk,
	# and the Sistine (left) and Pauline (right) chapels with domes.
	lm.box("Plaster", Vector3(0, 13.0, -48.0), Vector3(50.0, 26.0, 8.0))
	var rn := Vector3(0, 0, -1)
	var rr := Vector3.UP.cross(rn)
	LandmarkRmLKit.pilaster_row(lm, "Trim", Vector3(0, 0, -52.0) - rr * 20.0, rr, rn, 40.0, 6, 1.4, 22.0, 0.7)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(0, 22.0, -52.0) - rr * 25.0, Vector3(0, 22.0, -52.0) + rr * 25.0, rn, 2.0, 0.8, true)
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, 24.0, -52.0), rr, rn, 24.0, 4.0, 1.2, true)
	LandmarkRmLKit.windows(lm, "Plaster", "Shadow", "Trim", Vector3(0, 0, -52.0) - rr * 20.0, rr, rn, 40.0, 21.0, 5, 2,
		Vector2(2.2, 4.6), 3.0, 9.5, 1)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, -52.0), rn, 54.0, 0.7, 0.22, 10)
	LandmarkRmLKit.obelisk(lm, "Stone", "Trim", "Gold", Vector3(0, 0, -78.0), 8.0, 14.75, 0.75, 2.0)
	for s in [-1.0, 1.0]:
		lm.box("Plaster", Vector3(s * 27.0, 11.0, -32.0), Vector3(16.0, 22.0, 20.0))
		LandmarkRmLKit.pilaster_row(lm, "Trim", Vector3(s * 35.0, 0, -41.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 18.0, 4, 1.2, 21.0, 0.5)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 35.0, 21.0, -42.0), Vector3(s * 35.0, 21.0, -22.0), Vector3(s, 0, 0), 1.0, false)
		LandmarkRmLUtil.dome_stack(lm, Vector3(s * 27.0, 22.0, -32.0), 7.0 if s < 0.0 else 8.0,
			5.0, 8.0, 4.0, 20.5, 8, 8)
	# Romanesque campanile in brick bands, pyramidal tiled spire and cross.
	var tiers := PackedVector2Array([Vector2(22.0, 5.4), Vector2(8.5, 5.2), Vector2(8.5, 5.0),
		Vector2(8.5, 4.8), Vector2(8.5, 4.6), Vector2(8.0, 4.4)])
	LandmarkRmLUtil.tower(lm, "Brick", Vector3(31.0, 0, 8.0), tiers, 73.5, "Tile")
	SEuUtil.finial(lm, "Gold", Vector3(31.0, 73.5, 8.0), 1.5)
	lm.commit(model)

## Fuga's facade between the palazzi: 37 m wide at z = 48, portico 3 m
## deep below, loggia above, 28 m to the balustrade.
static func _maggiore_facade(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, 14.0, 44.5), Vector3(37.0, 28.0, 4.0))
	var o := Vector3(-18.5, 0.6, 46.5)
	# Portico: five openings (the centre one arched) on Ionic columns.
	LandmarkRmLKit.arcade(lm, "Stone", "Shadow", o, r, n, 37.0, 11.0, 5, 5.0, 5.6, 3.0)
	LandmarkRmLKit.archivolts(lm, "Trim", o, r, n, 37.0, 5, 5.0, 5.6, 3.0, 0.5)
	for i in 6:
		var x := -18.5 + 37.0 / 5.0 * float(i)
		LandmarkRmLKit.column_ionic(lm, "Trim", Vector3(x, 0.6, 50.2), 0.6, 10.4, n)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-19.0, 11.0, 49.5), Vector3(19.0, 11.0, 49.5), n, 1.8, 1.2)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-18.5, 12.8, 50.6), Vector3(-6.0, 12.8, 50.6), 1.1, 3.1)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(6.0, 12.8, 50.6), Vector3(18.5, 12.8, 50.6), 1.1, 3.1)
	# Loggia of the Blessings: three arches on Corinthian columns over the
	# central bays, the gold mosaics behind.
	var lo := Vector3(-11.1, 13.0, 46.5)
	LandmarkRmLKit.arcade(lm, "Stone", "Gold", lo, r, n, 22.2, 11.0, 3, 5.6, 4.6, 2.0)
	LandmarkRmLKit.archivolts(lm, "Trim", lo, r, n, 22.2, 3, 5.6, 4.6, 2.0, 0.5)
	for i in 4:
		var x := -11.1 + 7.4 * float(i)
		LandmarkDetail.column(lm, "Trim", Vector3(x, 13.0, 49.1), 0.55, 9.6, "corinthian", 0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 14.8, 18.0, 46.5), Vector3(7.4, 10.0, 0.6))
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(s * 17.8, 13.0, 46.8), r, n, 1.2, 9.6, 0.5)
		lm.box("Shadow", Vector3(s * 14.8, 17.8, 46.85), Vector3(2.0, 3.6, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(s * 14.8, 16.0, 46.9), r, n, 2.0, 3.6, 1)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-18.8, 22.6, 48.5), Vector3(18.8, 22.6, 48.5), n, 1.8, 1.0, true)
	# Broken pediment over the loggia, statues along the balustrade.
	for s in [-1.0, 1.0]:
		var a := Vector3(s * 11.6, 24.4, 48.6)
		var b := Vector3(s * 3.0, 27.4, 48.6)
		lm.beam("Trim", a, b, 0.9, 1.4, n)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-18.5, 24.4, 47.4), Vector3(18.5, 24.4, 47.4), 1.4, 3.7)
	LandmarkRmLKit.statue_row(lm, "Trim", Vector3(-17.5, 25.8, 47.4), Vector3(17.5, 25.8, 47.4), 6, 3.6)
	LandmarkKits.statue_figure(lm, "Trim", Vector3(0, 27.4, 48.4), 4.4, true)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, 50.6), n, 40.0, 0.7, 0.2, 3)
	# Ponzio's and Fuga's palazzi either side.
	for s in [-1.0, 1.0]:
		LandmarkRmLUtil.block(lm, "Plaster", Vector3(s * 28.5, 0, 38.0), 19.0, 24.0, 20.0, n, 4, 4, 1.6, 2.8, "Tile", 2)

# --- St John Lateran ----------------------------------------------------------

## Origin at the middle of the basilica (140 x 73 m), Galilei's facade
## (1732-35) facing +Z (east; yaw_deg turns it): a 60 m travertine
## front in one giant Composite order (paired columns at the centre
## carrying the pediment, pilasters on the outer bays) over five portals
## and the five arches of the Loggia of the Blessings; on the attic
## balustrade fifteen 7 m statues with Christ at the centre (39 m to his
## hand). Behind: the 124 m nave and double aisles under tile with their
## clerestory windows, the transept with Fontana's two-storey loggia on
## its north end, the apse, Fontana's Lateran Palace beside it, and the
## octagonal baptistery with its drum and lantern.
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
	for k in 9:
		var a := PI * 0.15 + PI * 0.7 * float(k) / 8.0
		var d := Vector3(cos(a), 0, -sin(a))
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(0, 0, -63.0) + d * 14.9, Vector3.UP.cross(d), d, 1.0, 29.0, 0.5)
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		_clerestory(lm, s)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 28.0, 21.2, 60.0), Vector3(s * 28.0, 21.2, -17.0), n, 0.8, false)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 15.0, 30.2, 60.0), Vector3(s * 15.0, 30.2, -17.0), n, 0.8, false)
		lm.quad("Tile", Vector3(s * 28.4, 22.0, 60.0), Vector3(s * 28.4, 22.0, -17.0), Vector3(s * 15.0, 23.4, -17.0),
			Vector3(s * 15.0, 23.4, 60.0), Vector3(s * 0.1, 1.0, 0).normalized())
	_fontana_loggia(lm)
	_galilei_facade(lm)
	# Lateran Palace to the north-east and the baptistery behind the apse.
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(76.0, 0, 18.0), 60.0, 30.0, 34.0, Vector3(-1, 0, 0), 4, 10, 1.8, 3.2, "Tile", 2)
	_baptistery(lm, Vector3(50.0, 0, -99.0))
	lm.commit(model)

## Clerestory and aisle windows down one side (s = -1 / +1).
static func _clerestory(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(s, 0, 0)
	var r := Vector3.UP.cross(n)
	LandmarkDetail.pierced_face(lm, "Plaster", "Shadow", Vector3(s * 15.0, 22.0, 21.5) - r * 38.5, r, n, 77.0, 8.6,
		7, 1, Vector2(3.0, 5.0), 1.8, 8.0)
	LandmarkDetail.pierced_face(lm, "Plaster", "Shadow", Vector3(s * 28.0, 0.0, 21.5) - r * 38.5, r, n, 77.0, 21.0,
		7, 1, Vector2(3.0, 6.4), 9.0, 9.0)

## Galilei's facade: 60 m wide, front of the wall at z = 66.
static func _galilei_facade(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, 13.55, 62.0), Vector3(60.0, 27.1, 4.0))
	var o := Vector3(-30.0, 0.8, 64.0)
	# Five portals and the five arches of the benediction loggia, in deep
	# porticoes behind the giant order.
	LandmarkDetail.pierced_face(lm, "Stone", "Shadow", o, r, n, 60.0, 11.6, 5, 1, Vector2(6.6, 9.4), 0.0, 11.6, 2.0)
	LandmarkRmLKit.arcade(lm, "Stone", "Shadow", o + Vector3(0, 11.6, 0), r, n, 60.0, 13.6, 5, 6.0, 6.2, 2.0, 1.4)
	LandmarkRmLKit.archivolts(lm, "Trim", o + Vector3(0, 11.6, 0), r, n, 60.0, 5, 6.0, 6.2, 2.0, 0.5)
	for x in [-24.0, -12.0, 0.0, 12.0, 24.0]:
		LandmarkRmLKit.balustrade(lm, "Trim", Vector3(float(x) - 3.0, 12.4, 66.1), Vector3(float(x) + 3.0, 12.4, 66.1), 1.2, 3.0)
		lm.box("Trim", Vector3(float(x), 11.3, 66.4), Vector3(7.4, 0.8, 1.2))
		lm.box("Shadow", Vector3(float(x), 4.4, 64.1), Vector3(3.2, 6.4, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(float(x), 1.2, 64.15), r, n, 3.2, 6.4, 1 if absf(float(x)) < 1.0 else 4)
	# Giant order: paired columns at the centre on pedestals, pilasters
	# on the outer bays, all to the 27 m entablature.
	for x in [-6.6, -4.4, 4.4, 6.6]:
		lm.box("Stone", Vector3(float(x), 2.25, 67.4), Vector3(2.8, 4.5, 2.8))
		LandmarkDetail.column(lm, "Trim", Vector3(float(x), 4.5, 67.4), 1.05, 20.4, "corinthian", 0)
	for x in [-29.0, -27.0, -19.0, -17.0, 17.0, 19.0, 27.0, 29.0]:
		lm.box("Stone", Vector3(float(x), 2.25, 66.6), Vector3(2.0, 4.5, 1.4))
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(float(x), 4.5, 66.0), r, n, 1.6, 20.4, 0.7)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-30.6, 24.9, 66.0), Vector3(30.6, 24.9, 66.0), n, 2.6, 1.0, true)
	lm.box("Trim", Vector3(0, 26.2, 68.0), Vector3(16.6, 2.6, 1.8))
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, 27.5, 66.4), r, n, 17.0, 4.6, 2.6, true)
	# Attic, balustrade and the fifteen statues.
	lm.box("Stone", Vector3(0, 29.0, 63.5), Vector3(60.0, 3.8, 3.0))
	lm.box("Trim", Vector3(0, 31.2, 63.6), Vector3(61.6, 0.6, 3.6))
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-30.0, 31.5, 64.8), Vector3(30.0, 31.5, 64.8), 1.2, 4.2)
	for i in 15:
		var central := i == 7
		var p := Vector3(-29.4 + 4.2 * float(i), 32.7, 64.2)
		if central:
			p = Vector3(0, 32.7, 66.6)
			lm.box("Trim", p - Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 2.0))
		LandmarkKits.statue_figure(lm, "Marble", p, 6.3 if central else 5.6, central)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, 68.8), n, 62.0, 0.8, 0.25, 4)

## Fontana's loggia (1586) on the north transept end (+X): two storeys
## of five arches between pilasters, a balustrade and pediment.
static func _fontana_loggia(lm: LandmarkMesh) -> void:
	var n := Vector3(1, 0, 0)
	var r := Vector3.UP.cross(n)
	var o := Vector3(46.0, 0, -30.0) - r * 11.0
	for f in 2:
		var fo := o + Vector3(0, 13.0 * float(f), 0)
		LandmarkRmLKit.arcade(lm, "Stone", "Shadow", fo, r, n, 22.0, 13.0, 5, 3.0, 6.0 if f == 0 else 5.4, 2.0,
			0.0 if f == 0 else 1.2)
		LandmarkRmLKit.archivolts(lm, "Trim", fo, r, n, 22.0, 5, 3.0, 6.0 if f == 0 else 5.4, 2.0, 0.35)
		LandmarkRmLKit.pilaster_row(lm, "Trim", fo + n * 2.0, r, n, 22.0, 6, 0.9, 12.0, 0.4)
		LandmarkRmLKit.entablature(lm, "Trim", fo + n * 2.0 + Vector3(0, 12.0, 0) - r * 0.6, fo + n * 2.0 + r * 22.6 + Vector3(0, 12.0, 0), n, 1.0, 0.6)
	LandmarkRmLKit.balustrade(lm, "Trim", o + n * 2.4 + Vector3(0, 26.0, 0), o + n * 2.4 + r * 22.0 + Vector3(0, 26.0, 0), 1.1, 4.4)
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(47.2, 26.0, -30.0), r, n, 10.0, 3.0, 1.2, true)

## Lateran baptistery: octagon with pilastered angles, windows,
## cornice, the tiled roof, the drum of the lantern and a cupola.
static func _baptistery(lm: LandmarkMesh, bp: Vector3) -> void:
	lm.frustum("Plaster", bp, 11.4, 11.4, 14.0, 8, PI / 8.0)
	lm.frustum("Trim", bp + Vector3(0, 14.0, 0), 12.2, 12.2, 0.9, 8, PI / 8.0)
	lm.frustum("Trim", bp, 11.9, 11.9, 0.8, 8, PI / 8.0)
	var cone := PackedVector2Array([Vector2(11.8, 0.0), Vector2(9.0, 4.2), Vector2(5.5, 8.2), Vector2(2.8, 10.5)])
	lm.lathe("Tile", bp + Vector3(0, 14.9, 0), cone, 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Stone", bp + Vector3(0, 25.4, 0), 2.8, 2.6, 3.2, 8, PI / 8.0)
	lm.lathe("Dome", bp + Vector3(0, 28.6, 0), SEuUtil.dome(2.9, 1.4, 4), 8)
	SEuUtil.finial(lm, "Gold", bp + Vector3(0, 30.0, 0), 2.2)
	var ap := 11.4 * cos(PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var fr := Vector3.UP.cross(d)
		lm.box("Shadow", bp + d * (ap + 0.05) + Vector3(0, 9.0, 0), Vector3(2.2, 4.2, 0.1), Basis(fr, Vector3.UP, d), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", bp + d * (ap + 0.1) + Vector3(0, 6.9, 0), fr, d, 2.2, 4.2, 1)
		var a2 := a + PI / 8.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		LandmarkRmLKit.pilaster(lm, "Trim", bp + d2 * 11.3, Vector3.UP.cross(d2), d2, 1.0, 14.0, 0.4, true)
