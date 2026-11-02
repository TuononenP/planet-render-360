class_name LandmarkRmLBaroque
extends RefCounted

## Piazza Navona, the Gesù and Sant'Ivo alla Sapienza in true metres.

# --- Piazza Navona ----------------------------------------------------

## Origin at the centre of Bernini's Fountain of the Four Rivers (the
## 30 m obelisk on its travertine rock above the round basin and the four
## river-god figures). The piazza's long axis is X (the church sits to
## the south, -X); Sant'Agnese in Agone stands on the -Z side facing +Z:
## the concave facade of four giant columns, two bell towers with domed
## belfries, and Borromini's high drum, dome and lantern (55 m) behind;
## palazzi of the Pamphilj and Collegio flank it, and the east side of
## the piazza is a row of ochre and rose houses.
static func navona(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5C5A2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DBC2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#B7AA8E", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9965F", 4.0))
	lm.use("Rose", LandmarkMaterials.pbr("render", "#C58468", 4.0))
	_four_rivers(lm)
	_agnese(lm)
	var cx := -12.0
	LandmarkRmLUtil.block(lm, "Rose", Vector3(cx - 27.2, 0, -37.5), 17.7, 22.0, 22.0, Vector3(0, 0, 1), 4, 4)
	LandmarkRmLUtil.block(lm, "Ochre", Vector3(cx + 32.1, 0, -37.5), 27.7, 22.0, 22.0, Vector3(0, 0, 1), 4, 6)
	var east: Array = [[-46.0, 28.0, 21.0, 0], [-17.0, 26.0, 24.0, 1], [11.0, 28.0, 22.0, 0], [40.0, 28.0, 23.0, 1]]
	for e in east:
		var wall := "Rose" if int(e[3]) == 1 else "Ochre"
		LandmarkRmLUtil.block(lm, wall, Vector3(float(e[0]), 0, 34.0), float(e[1]), float(e[2]),
			16.0, Vector3(0, 0, -1), 5, 6)
	lm.commit(model)

## Round basin, rock with four river gods, pedestal and obelisk.
static func _four_rivers(lm: LandmarkMesh) -> void:
	var rim := PackedVector2Array([Vector2(14.6, 0.0), Vector2(14.6, 1.0), Vector2(13.6, 1.0),
		Vector2(13.6, 0.7)])
	lm.lathe("Marble", Vector3.ZERO, rim, 40, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", Vector3(0, 0.85, 0), Vector3.UP, 13.7, 40)
	SEuUtil.blob(lm, "Rock", Vector3(0, 0.7, 0), 9.5, 9.0, 9.5, Vector3.ZERO, true, 8, 20)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var p := Vector3(cos(a) * 8.0, 2.8, sin(a) * 8.0)
		lm.box("Rock", p + Vector3(0, -0.6, 0), Vector3(3.2, 1.2, 3.2), Basis(Vector3.UP, -a))
		LandmarkKits.statue_figure(lm, "Marble", p, 4.4, k % 2 == 0)
	for k in 4:
		var g := PI * 0.5 * float(k)
		lm.box("Shadow", Vector3(cos(g) * 9.2, 2.6, sin(g) * 9.2), Vector3(1.6, 3.8, 3.4), Basis(Vector3.UP, -g))
	lm.box("Rock", Vector3(0, 9.85, 0), Vector3(4.4, 2.3, 4.4))
	LandmarkRmLUtil.obelisk(lm, "Marble", Vector3(0, 11.0, 0), 17.0, 0.95)
	SEuUtil.finial(lm, "Gold", Vector3(0, 28.0, 0), 2.0)

## Sant'Agnese in Agone: facade at z = -26.5, towers forward to -21.5.
static func _agnese(lm: LandmarkMesh) -> void:
	var cx := -12.0
	lm.box("Stone", Vector3(cx, 12.0, -44.5), Vector3(36.0, 24.0, 36.0))
	lm.box("Trim", Vector3(cx, 24.4, -44.5), Vector3(37.4, 0.8, 37.4))
	for s in [-1.0, 1.0]:
		var tx: float = cx + s * 14.6
		lm.box("Stone", Vector3(tx, 13.5, -28.0), Vector3(7.4, 27.0, 13.0))
		lm.box("Trim", Vector3(tx, 27.4, -28.0), Vector3(8.4, 0.8, 14.0))
		for y in [6.0, 13.0, 20.0]:
			SEuUtil.face_row(lm, "Shadow", Vector3(tx, 0, -21.5), Vector3.RIGHT, Vector3(0, 0, 1),
				float(y), 1, 4.0, 1.4, 3.6)
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", Vector3(tx, 27.8, -28.0), 3.2, 4.5, 4.4, 3.6, 16)
	# Concave centre: four Corinthian columns, entablature and pediment.
	SEuUtil.column_row(lm, "Trim", Vector3(cx - 7.5, 0, -24.8), Vector3(cx + 7.5, 0, -24.8), 4, 15.4, 0.8, 12)
	lm.box("Trim", Vector3(cx, 16.2, -25.0), Vector3(19.5, 1.6, 3.6))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(cx, 17.0, -25.0), 19.5, 3.4, 3.2)
	SEuUtil.opening(lm, "Shadow", Vector3(cx, 0, -26.44), Vector3.RIGHT, Vector3.UP, 4.2, 8.5)
	for s in [-1.0, 1.0]:
		SEuUtil.opening(lm, "Shadow", Vector3(cx + s * 7.0, 0, -26.44), Vector3.RIGHT, Vector3.UP, 2.4, 5.8)
	SEuUtil.face_row(lm, "Shadow", Vector3(cx, 0, -26.5), Vector3.RIGHT, Vector3(0, 0, 1), 20.6, 3, 6.0, 1.6, 2.8)
	# High drum, ribbed dome and lantern over the crossing.
	LandmarkRmLUtil.dome_stack(lm, Vector3(cx, 24.0, -45.0), 8.8, 9.5, 11.0, 5.5, 31.0, 8, 8)

# --- Il Gesù -----------------------------------------------------------

## Origin at the middle of the church, facade facing +Z (south-west,
## onto Piazza del Gesù; yaw_deg turns it): Della Porta's two-storey
## travertine facade (34 m wide, paired pilasters, central door under a
## small pediment, big pediment above, scroll volutes), the 21 m nave
## under its tiled roof, side chapels, transept, apse and Vignola's
## drum and dome over the crossing (52.5 m).
static func gesu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2C2A0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DBC2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#C79F6E", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Plaster", Vector3(0, 13.5, -1.5), Vector3(21.2, 27.0, 69.0))
	lm.gable("Tile", Vector3(0, 27.0, -1.5), 21.2, 69.0, 5.0, Basis(), 0.5, "Plaster")
	for s in [-1.0, 1.0]:
		lm.box("Plaster", Vector3(s * 13.9, 7.5, 1.5), Vector3(6.6, 15.0, 63.0))
		lm.box("Trim", Vector3(s * 13.9, 15.3, 1.5), Vector3(7.4, 0.6, 64.0))
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 10.6, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			19.5, 5, 12.0, 2.4, 4.6)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 17.2, 0, 3.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			5.0, 5, 11.0, 2.0, 5.0)
	# Transept and apse.
	lm.box("Plaster", Vector3(0, 14.0, -15.0), Vector3(41.0, 28.0, 22.0))
	lm.gable("Tile", Vector3(0, 28.0, -15.0), 22.0, 41.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	lm.frustum("Plaster", Vector3(0, 0, -36.0), 10.6, 10.6, 24.0, 20)
	lm.lathe("Tile", Vector3(0, 24.0, -36.0), SEuUtil.dome(10.8, 4.0, 4), 20)
	# Facade: lower order, upper order, volutes, pediment.
	lm.box("Stone", Vector3(0, 7.5, 35.0), Vector3(34.4, 15.0, 4.0))
	lm.box("Stone", Vector3(0, 21.5, 34.5), Vector3(21.2, 13.0, 3.0))
	lm.box("Trim", Vector3(0, 15.4, 35.2), Vector3(35.6, 0.8, 4.8))
	lm.box("Trim", Vector3(0, 28.4, 34.6), Vector3(22.6, 0.8, 4.0))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(0, 28.8, 34.6), 22.6, 5.0, 3.6)
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(s * 17.0, 15.6, 34.5), Vector3(s * 10.8, 27.4, 34.5), 3.2, 1.8, Vector3(0, 0, 1))
		for x in [16.2, 13.8, 8.6, 6.2]:
			lm.box("Trim", Vector3(s * float(x), 7.0, 37.35), Vector3(1.0, 14.0, 0.7))
		for x in [10.0, 7.6]:
			lm.box("Trim", Vector3(s * float(x), 21.9, 36.35), Vector3(0.9, 12.2, 0.7))
		SEuUtil.opening(lm, "Shadow", Vector3(s * 11.4, 0, 37.06), Vector3.RIGHT, Vector3.UP, 2.8, 6.2)
		SEuUtil.opening(lm, "Shadow", Vector3(s * 4.6, 17.0, 36.06), Vector3.RIGHT, Vector3.UP, 2.0, 4.8)
	SEuUtil.column_row(lm, "Trim", Vector3(-3.8, 0, 37.7), Vector3(3.8, 0, 37.7), 2, 12.0, 0.7, 12)
	lm.box("Trim", Vector3(0, 12.0, 37.5), Vector3(9.6, 0.8, 1.6))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(0, 12.4, 37.5), 9.6, 2.4, 1.6)
	SEuUtil.opening(lm, "Shadow", Vector3(0, 0, 37.06), Vector3.RIGHT, Vector3.UP, 4.4, 8.6)
	SEuUtil.opening(lm, "Shadow", Vector3(0, 17.0, 36.06), Vector3.RIGHT, Vector3.UP, 3.4, 6.2)
	SEuUtil.steps_up(lm, "Trim", Vector3(0, 0, 38.0), Vector3(0, 0, 1), 20.0, 0.6, 0.25, 3)
	LandmarkRmLUtil.dome_stack(lm, Vector3(0, 28.0, -15.0), 8.6, 7.5, 8.5, 5.0, 24.5, 8, 16)
	lm.commit(model)

# --- Sant'Ivo alla Sapienza --------------------------------------------

## Origin at the dome axis of Borromini's church; the concave facade
## faces +Z into the arcaded court of the Palazzo della Sapienza. Over
## the concave front rises the convex drum, the stepped dome and the
## spiral lantern ending in an iron crown (58 m).
static func ivo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBA96", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E4D8BE", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#BE9266", 4.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Iron", LandmarkMaterials.paint("#2C2C2C", 0.6, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Stone", Vector3(0, 13.0, -3.0), Vector3(27.0, 26.0, 24.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 11.25, 9.0, 12.0), Vector3(4.5, 18.0, 4.0))
		# Palazzo ranges beside the church and round the court.
		LandmarkRmLUtil.block(lm, "Plaster", Vector3(s * 18.75, 0, -0.5), 29.0, 22.0, 10.5, Vector3(s, 0, 0), 3, 6)
		LandmarkRmLUtil.block(lm, "Plaster", Vector3(s * 19.0, 0, 34.0), 40.0, 22.0, 10.0, Vector3(-s, 0, 0), 3, 8, 2.6, 4.6)
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(0, 0, 56.0), 48.0, 22.0, 8.0, Vector3(0, 0, -1), 3, 9, 2.6, 4.6)
	# Concave facade: pilasters, wall, windows and cornice on a 11 m arc.
	var prev := Vector3.ZERO
	for i in 9:
		var x := -9.0 + 2.25 * float(i)
		var p := Vector3(x, 0, 21.5 - sqrt(121.0 - x * x))
		var n := Vector3(-x, 0, 21.5 - p.z).normalized()
		lm.box("Trim", p + n * 0.35 + Vector3(0, 8.6, 0), Vector3(0.9, 17.2, 0.7), Basis(Vector3.UP, atan2(n.x, n.z)))
		if i > 0:
			lm.beam("Stone", prev + Vector3(0, 9.0, 0), p + Vector3(0, 9.0, 0), 18.0, 2.0, Vector3.UP)
			lm.beam("Trim", prev + Vector3(0, 18.4, 0), p + Vector3(0, 18.4, 0), 0.9, 2.8, Vector3.UP)
			var mid := (prev + p) * 0.5
			var mn := Vector3(-mid.x, 0, 21.5 - mid.z).normalized()
			for y in [2.2, 9.6]:
				SEuUtil.opening(lm, "Shadow", mid + mn * 0.06 + Vector3(0, float(y), 0),
					Vector3.UP.cross(mn), Vector3.UP, 1.4, 4.6)
		prev = p
	# Convex drum, cornice and the stepped dome.
	lm.frustum("Stone", Vector3(0, 18.0, -1.0), 8.6, 8.6, 10.0, 24)
	SEuUtil.column_ring(lm, "Trim", Vector3(0, 18.0, -1.0), 8.8, 12, 9.6, 0.5, 6, PI / 12.0)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 18.0, -1.0), 8.6, 24, 6, 3.0, 2.0, 4.6, false, 0.0)
	lm.frustum("Trim", Vector3(0, 28.0, -1.0), 9.4, 9.4, 0.9, 24)
	var steps := PackedVector2Array([Vector2(8.4, 0.0), Vector2(8.4, 1.2), Vector2(7.5, 1.2),
		Vector2(7.5, 2.6), Vector2(6.5, 2.6), Vector2(6.5, 4.0), Vector2(5.5, 4.0), Vector2(5.5, 5.4),
		Vector2(4.5, 5.4), Vector2(4.5, 6.8), Vector2(3.8, 6.8)])
	lm.lathe("Dome", Vector3(0, 28.9, -1.0), steps, 24, 1.0, 1.0, 0.0, false)
	# Lantern: buttressed drum, then a spiral ramp winding up to the crown.
	lm.frustum("Stone", Vector3(0, 35.7, -1.0), 3.6, 3.6, 4.0, 12)
	SEuUtil.column_ring(lm, "Trim", Vector3(0, 35.7, -1.0), 3.8, 6, 4.0, 0.4, 6)
	lm.frustum("Stone", Vector3(0, 39.7, -1.0), 2.5, 2.1, 6.0, 12)
	var q := Vector3.ZERO
	for k in 37:
		var t := float(k) / 36.0
		var a := 3.0 * TAU * t
		var r := lerpf(2.9, 0.6, t)
		var c := Vector3(cos(a) * r, 45.7 + 6.8 * t, -1.0 + sin(a) * r)
		if k > 0:
			lm.beam("Iron", q, c, 0.9, 0.6)
		q = c
	SEuUtil.finial(lm, "Gold", Vector3(0, 52.5, -1.0), 5.5)
	lm.commit(model)
