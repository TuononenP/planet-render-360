class_name LandmarkRmLBaroque
extends RefCounted

## Piazza Navona and Sant'Agnese in Agone in true metres. The Gesù and
## Sant'Ivo alla Sapienza live in LandmarkRmLChurches.

# --- Piazza Navona ----------------------------------------------------

## Origin at the centre of Bernini's Fountain of the Four Rivers
## (1651): the 16.5 m granite obelisk on a pierced travertine rock with
## the four marble river gods, palm, lion and horse, over the round
## basin. The piazza (the 240 m long Stadium of Domitian) runs along X
## (north +X, yaw_deg turns it) with the Fontana del Nettuno 70 m to the
## north and the Fontana del Moro 70 m to the south. Sant'Agnese in
## Agone stands on the -Z (west) side facing +Z: Borromini's concave
## facade of giant Corinthian columns between two bell towers, an attic
## with statues and the high drum, dome and lantern (55 m) behind; the
## Palazzo Pamphilj to its south, the Collegio Innocenziano to its
## north, and rows of ochre and rose palazzi line both long sides.
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
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	_four_rivers(lm)
	_side_fountain(lm, Vector3(-70.0, 0, 0), true)
	_side_fountain(lm, Vector3(70.0, 0, 0), false)
	_agnese(lm)
	var cx := -12.0
	# Palazzo Pamphilj (south) and the Collegio Innocenziano (north).
	LandmarkRmLUtil.block(lm, "Rose", Vector3(cx - 27.2, 0, -37.5), 17.7, 22.0, 22.0, Vector3(0, 0, 1), 4, 4,
		1.3, 2.3, "Tile", 2)
	LandmarkRmLUtil.block(lm, "Ochre", Vector3(cx + 32.1, 0, -37.5), 27.7, 22.0, 22.0, Vector3(0, 0, 1), 4, 6,
		1.3, 2.3, "Tile", 2)
	var west: Array = [[-68.0, 26.0, 21.0, 0], [-46.0, 18.0, 23.0, 1], [40.0, 18.0, 20.0, 1], [64.0, 26.0, 22.0, 0]]
	for e in west:
		var wall := "Rose" if int(e[3]) == 1 else "Ochre"
		LandmarkRmLUtil.block(lm, wall, Vector3(float(e[0]), 0, -34.0), float(e[1]), float(e[2]),
			16.0, Vector3(0, 0, 1), 5, 6, 1.3, 2.3, "Tile")
	var east: Array = [[-68.0, 24.0, 20.0, 1], [-46.0, 20.0, 21.0, 0], [-17.0, 32.0, 24.0, 1], [11.0, 24.0, 22.0, 0],
		[40.0, 28.0, 23.0, 1], [66.0, 22.0, 20.0, 0]]
	for e in east:
		var wall := "Rose" if int(e[3]) == 1 else "Ochre"
		LandmarkRmLUtil.block(lm, wall, Vector3(float(e[0]), 0, 34.0), float(e[1]), float(e[2]),
			16.0, Vector3(0, 0, -1), 5, 6, 1.3, 2.3, "Tile")
	lm.commit(model)

## Round basin, pierced rock with four river gods, palm, lion and horse,
## the Pamphilj dove on the obelisk.
static func _four_rivers(lm: LandmarkMesh) -> void:
	var rim := PackedVector2Array([Vector2(14.6, 0.0), Vector2(14.7, 0.25), Vector2(14.55, 0.4),
		Vector2(14.6, 0.75), Vector2(14.75, 0.9), Vector2(14.6, 1.05), Vector2(13.6, 1.05), Vector2(13.6, 0.7)])
	lm.lathe("Marble", Vector3.ZERO, rim, 48, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", Vector3(0, 0.85, 0), Vector3.UP, 13.7, 48)
	SEuUtil.blob(lm, "Rock", Vector3(0, 0.7, 0), 9.5, 9.0, 9.5, Vector3.ZERO, true, 10, 24)
	# Boulders round the foot of the rock.
	for k in 10:
		var a := TAU * float(k) / 10.0 + 0.2
		SEuUtil.blob(lm, "Rock", Vector3(cos(a) * 8.4, 0.7, sin(a) * 8.4), 1.8, 1.6, 1.5, Vector3.ZERO, true, 4, 8)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var p := Vector3(cos(a) * 8.0, 2.8, sin(a) * 8.0)
		lm.box("Rock", p + Vector3(0, -0.6, 0), Vector3(3.2, 1.2, 3.2), Basis(Vector3.UP, -a))
		LandmarkKits.statue_figure(lm, "Marble", p, 4.4, k % 2 == 0)
	# The grotto: arched openings through the rock on the four axes.
	for k in 4:
		var g := PI * 0.5 * float(k)
		var d := Vector3(cos(g), 0, sin(g))
		lm.box("Shadow", d * 9.2 + Vector3(0, 2.6, 0), Vector3(1.6, 3.8, 3.4), Basis(Vector3.UP, -g))
		lm.lathe("Rock", d * 9.6 + Vector3(0, 4.5, 0), SEuUtil.dome(2.2, 1.3, 4), 8)
	# Palm (west), lion (east) and horse (south) on the rock.
	var palm := Vector3(-5.5, 2.0, -3.0)
	lm.beam("Marble", palm, palm + Vector3(0.8, 7.5, 0.4), 0.5, 0.5)
	for k in 7:
		var a := TAU * float(k) / 7.0
		var t := palm + Vector3(0.8, 7.5, 0.4)
		lm.beam("Marble", t, t + Vector3(cos(a) * 2.4, -0.9, sin(a) * 2.4), 0.6, 0.08, Vector3.UP)
	lm.box("Marble", Vector3(5.6, 3.2, -2.5), Vector3(1.0, 1.1, 2.4))
	lm.box("Marble", Vector3(5.6, 3.9, -1.2), Vector3(1.0, 1.0, 0.9))
	LandmarkRmLUtil.horse(lm, "Marble", Vector3(2.0, 2.4, 5.6))
	# Pedestal, obelisk and dove.
	lm.box("Rock", Vector3(0, 9.85, 0), Vector3(4.4, 2.3, 4.4))
	lm.box("Trim", Vector3(0, 11.2, 0), Vector3(3.6, 0.6, 3.6))
	LandmarkRmLUtil.obelisk(lm, "Marble", Vector3(0, 11.5, 0), 16.5, 0.95)
	lm.box("Gold", Vector3(0, 28.4, 0), Vector3(0.5, 0.6, 1.2))
	for s in [-1.0, 1.0]:
		lm.beam("Gold", Vector3(0, 28.6, 0), Vector3(s * 0.9, 29.2, 0.1), 0.6, 0.08, Vector3(0, 0, 1))

## Fontana del Moro (south, the Moor wrestling a dolphin) or del
## Nettuno (north, Neptune with the octopus): a lobed pink-marble basin,
## a rocky shell with the central figure and four tritons on the rim.
static func _side_fountain(lm: LandmarkMesh, c: Vector3, moro: bool) -> void:
	var rim := PackedVector2Array([Vector2(8.6, 0.0), Vector2(8.7, 0.5), Vector2(8.5, 0.8),
		Vector2(8.8, 1.0), Vector2(7.9, 1.0), Vector2(7.9, 0.6)])
	lm.lathe("Marble", c, rim, 40, 1.45, 1.0, 0.0, true, false)
	lm.lathe("Water", c + Vector3(0, 0.75, 0), PackedVector2Array([Vector2(8.0, 0.0), Vector2(0.0, 0.0)]),
		40, 1.45, 1.0)
	# Inner basin (the shell) on a rock.
	SEuUtil.blob(lm, "Rock", c + Vector3(0, 0.6, 0), 2.6, 2.0, 2.2, Vector3.ZERO, true, 5, 12)
	lm.lathe("Marble", c + Vector3(0, 1.8, 0), PackedVector2Array([Vector2(1.2, 0.0), Vector2(3.0, 0.7),
		Vector2(3.2, 0.9), Vector2(2.9, 0.9)]), 16)
	LandmarkKits.statue_figure(lm, "Marble", c + Vector3(0, 2.6, 0), 3.4 if moro else 4.2, not moro)
	if moro:
		lm.beam("Marble", c + Vector3(0.8, 2.8, 0.2), c + Vector3(1.6, 3.4, 0.6), 0.6, 0.5)
	else:
		for k in 6:
			var a := TAU * float(k) / 6.0
			lm.beam("Marble", c + Vector3(0, 2.9, 0), c + Vector3(cos(a) * 1.6, 2.7, sin(a) * 1.6), 0.25, 0.25)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var p := c + Vector3(cos(a) * 7.0 * 1.3, 1.0, sin(a) * 5.6)
		lm.box("Marble", p + Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 1.2))
		LandmarkKits.statue_figure(lm, "Marble", p + Vector3(0, 0.8, 0), 2.2)

## Sant'Agnese in Agone: concave facade on an arc between the towers
## (front of the towers at z = -21.5), church body and dome behind.
static func _agnese(lm: LandmarkMesh) -> void:
	var cx := -12.0
	lm.box("Stone", Vector3(cx, 12.0, -44.5), Vector3(36.0, 24.0, 36.0))
	LandmarkDetail.cornice(lm, "Trim", Vector3(cx - 18.0, 24.0, -26.5), Vector3(cx + 18.0, 24.0, -26.5), Vector3(0, 0, 1), 1.0)
	lm.box("Trim", Vector3(cx, 24.4, -44.5), Vector3(37.4, 0.8, 37.4))
	for s in [-1.0, 1.0]:
		_agnese_tower(lm, Vector3(cx + s * 14.6, 0, -28.0))
	# Concave centre: wall on an arc of radius 22 m bowing back 3 m.
	var rad := 22.0
	var ctr := Vector3(cx, 0, -26.5 + rad - 3.0)
	var prev := Vector3.ZERO
	var prev_n := Vector3.ZERO
	var steps := 10
	for i in steps + 1:
		var x := -10.6 + 21.2 * float(i) / float(steps)
		var p := Vector3(cx + x, 0, ctr.z - sqrt(rad * rad - x * x))
		var n := (ctr - p).normalized()
		n.y = 0.0
		if i > 0:
			lm.beam("Stone", prev + Vector3(0, 8.5, 0), p + Vector3(0, 8.5, 0), 17.0, 1.6, Vector3.UP)
			lm.beam("Trim", prev + Vector3(0, 16.0, 0) + prev_n * 0.6, p + Vector3(0, 16.0, 0) + n * 0.6, 1.6, 2.6, Vector3.UP)
			lm.beam("Trim", prev + Vector3(0, 16.9, 0) + prev_n * 0.9, p + Vector3(0, 16.9, 0) + n * 0.9, 0.5, 3.2, Vector3.UP)
			# Attic over the entablature, a balustrade on it.
			lm.beam("Stone", prev + Vector3(0, 19.0, 0), p + Vector3(0, 19.0, 0), 4.0, 1.2, Vector3.UP)
			LandmarkRmLKit.balustrade(lm, "Trim", prev + Vector3(0, 21.0, 0) + prev_n * 0.3, p + Vector3(0, 21.0, 0) + n * 0.3,
				1.1, 2.2)
		if i % 2 == 0:
			LandmarkRmLKit.pilaster(lm, "Trim", p, Vector3.UP.cross(n), n, 1.2, 15.5, 0.5)
		if i == 2 or i == 8:
			LandmarkKits.statue_figure(lm, "Marble", p + Vector3(0, 22.1, 0) + n * 0.3, 3.0)
		prev = p
		prev_n = n
	# Giant Corinthian columns flanking the portal, central pediment.
	for x in [-5.6, -3.6, 3.6, 5.6]:
		var zc := ctr.z - sqrt(rad * rad - float(x) * float(x)) + 1.6
		LandmarkDetail.column(lm, "Trim", Vector3(cx + float(x), 0.6, zc), 0.75, 15.0, "corinthian", 0)
		lm.box("Trim", Vector3(cx + float(x), 0.3, zc), Vector3(2.2, 0.6, 2.2))
	lm.box("Trim", Vector3(cx, 16.3, -24.6), Vector3(14.0, 1.6, 2.6))
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(cx, 17.1, -25.9), Vector3.RIGHT, Vector3(0, 0, 1), 14.0, 3.2, 2.8, true)
	# Portals and windows: central door under a pediment, side doors,
	# framed windows above.
	var front := Vector3(cx, 0, -26.5 + 0.8)
	lm.box("Shadow", front + Vector3(0, 4.2, 0.05), Vector3(3.6, 8.4, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", front + Vector3(0, 0.4, 0.1), Vector3.RIGHT, Vector3(0, 0, 1), 3.6, 8.4, 1)
	for s in [-1.0, 1.0]:
		var sx := float(s) * 7.6
		var zf := ctr.z - sqrt(rad * rad - sx * sx) + 0.8
		var sp := Vector3(cx + sx, 0, zf)
		var sn := Vector3(-sx, 0, rad).normalized()
		lm.box("Shadow", sp + Vector3(0, 3.0, 0) + sn * 0.05, Vector3(2.2, 6.0, 0.1), Basis(Vector3.UP.cross(sn), Vector3.UP, sn), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", sp + sn * 0.1 + Vector3(0, 0.4, 0), Vector3.UP.cross(sn), sn, 2.2, 6.0, 4)
		lm.box("Shadow", sp + Vector3(0, 11.2, 0) + sn * 0.05, Vector3(1.8, 3.0, 0.1), Basis(Vector3.UP.cross(sn), Vector3.UP, sn), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", sp + Vector3(0, 9.7, 0) + sn * 0.1, Vector3.UP.cross(sn), sn, 1.8, 3.0, 0)
	lm.box("Shadow", front + Vector3(0, 12.0, 0.05), Vector3(2.4, 3.0, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", front + Vector3(0, 10.5, 0.1), Vector3.RIGHT, Vector3(0, 0, 1), 2.4, 3.0, 4)
	LandmarkKits.statue_figure(lm, "Marble", Vector3(cx, 20.5, -25.3), 3.0)
	SEuUtil.steps_up(lm, "Trim", Vector3(cx, 0, -24.2), Vector3(0, 0, 1), 18.0, 0.55, 0.2, 3)
	# High drum ringed by paired columns, ribbed dome and lantern.
	var dc := Vector3(cx, 24.0, -45.0)
	LandmarkRmLUtil.dome_stack(lm, dc, 8.8, 9.5, 11.0, 5.5, 31.0, 8, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for s in [-1.0, 1.0]:
			var p := dc + d * 9.6 + Vector3.UP.cross(d) * float(s) * 0.75
			LandmarkRmLKit.column_lite(lm, "Trim", p, 0.32, 8.6)
		lm.box("Stone", dc + d * 9.6 + Vector3(0, 9.2, 0), Vector3(2.6, 1.2, 1.4), Basis(Vector3.UP, -a + PI * 0.5))

## One bell tower of Sant'Agnese centred on `c` (7.4 m wide): two
## storeys of the facade order, then the open belfry with corner
## columns, a balustrade and the curved cupola with its cross.
static func _agnese_tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 13.5, 0), Vector3(7.4, 27.0, 13.0))
	var n := Vector3(0, 0, 1)
	var f := c + Vector3(0, 0, 6.5)
	for y in [0.0, 16.2]:
		for s in [-1.0, 1.0]:
			LandmarkRmLKit.pilaster(lm, "Trim", f + Vector3(float(s) * 3.0, float(y), 0), Vector3.RIGHT, n, 1.0,
				15.5 if y == 0.0 else 10.4, 0.4)
	LandmarkRmLKit.entablature(lm, "Trim", f + Vector3(-3.8, 15.5, 0), f + Vector3(3.8, 15.5, 0), n, 1.4, 0.5)
	LandmarkDetail.cornice(lm, "Trim", f + Vector3(-4.0, 26.6, 0.3), f + Vector3(4.0, 26.6, 0.3), n, 0.9, false)
	for y in [5.0, 18.5]:
		lm.box("Shadow", f + Vector3(0, float(y) + 1.8, 0.05), Vector3(1.6, 3.6, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", f + Vector3(0, float(y), 0.1), Vector3.RIGHT, n, 1.6, 3.6, 1)
	lm.box("Trim", c + Vector3(0, 27.4, 0), Vector3(8.4, 0.8, 14.0))
	# Belfry: a square open stage with a column at each corner and
	# arched openings, then the cupola.
	var b := c + Vector3(0, 27.8, 0)
	lm.box("Stone", b + Vector3(0, 2.6, 0), Vector3(4.6, 5.2, 4.6))
	for f2 in 4:
		var d := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f2))
		SEuUtil.opening(lm, "Shadow", b + d * 2.32 + Vector3(0, 0.6, 0), Vector3.UP.cross(d), Vector3.UP, 1.8, 3.8)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkRmLKit.column_lite(lm, "Trim", b + Vector3(float(sx) * 2.9, 0, float(sz) * 2.9), 0.28, 5.0)
	lm.box("Trim", b + Vector3(0, 5.5, 0), Vector3(6.8, 0.7, 6.8))
	for f2 in 4:
		var d := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f2))
		var r := Vector3.UP.cross(d)
		LandmarkRmLKit.balustrade(lm, "Trim", b + Vector3(0, 5.85, 0) + d * 3.1 - r * 3.1, b + Vector3(0, 5.85, 0) + d * 3.1 + r * 3.1, 0.8, 3.0)
	lm.lathe("Dome", b + Vector3(0, 5.85, 0), PackedVector2Array([Vector2(2.5, 0.0), Vector2(2.6, 0.6),
		Vector2(2.1, 1.6), Vector2(1.2, 2.4), Vector2(0.9, 3.0), Vector2(1.0, 3.4), Vector2(0.4, 4.4),
		Vector2(0.0, 4.6)]), 16)
	SEuUtil.finial(lm, "Gold", b + Vector3(0, 10.4, 0), 2.0)
