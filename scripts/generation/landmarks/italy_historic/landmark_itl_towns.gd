class_name LandmarkItlTowns
extends RefCounted

## Palazzo Vecchio (Florence, Arnolfo di Cambio, 1299-1314) in true
## metres: the rusticated pietraforte block of the Signoria under its
## corbelled gallery, with the 94 m Torre di Arnolfo rising off-centre.

const HX := 22.0
const HZ := 19.0
const TOP := 22.5

## Origin at the centre of Arnolfo's block, the Piazza della Signoria
## front facing +Z, the tower over the right (+X) half of it. The block
## (44 x 38 m to the gallery at 22.5 m) is three levels split by string
## courses: a rusticated ground floor with the marble frontispiece over
## the door, the David and Hercules and Cacus either side on the
## arengario, then two rows of marble two-light windows under round
## arches. The projecting gallery stands on corbels and round arches
## (painted arms of the Republic in the front ones) and carries square
## Guelph merlons. The tower's front is cantilevered over the gallery:
## shaft with the one-handed clock, its own corbelled crown with swallow-
## tail Ghibelline merlons, the open bell chamber on four columns with
## its three bells, the cusp, ball and Marzocco vane. Behind, the long
## Salone dei Cinquecento (52 x 23 m).
static func palazzo_vecchio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A88F68", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CDBB96", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C352D", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A5543A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6E1D6", 2.0))
	lm.box("Stone", Vector3(0, TOP * 0.5, 0), Vector3(HX * 2.0, TOP, HZ * 2.0))
	for side in 4:
		_face(lm, side)
	_front(lm)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", Vector3(0, TOP, 0), HX, HZ, 0.0, 1.3, 1.6, 2.1, false, 1.6)
	lm.gable("Tile", Vector3(0, TOP + 0.8, 0), HZ * 2.0 - 3.0, HX * 2.0 - 2.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	_salone(lm)
	_tower(lm, Vector3(8.0, 0, 14.0))
	lm.commit(model)

## One face (0 front +Z, 1 back, 2 +X, 3 -X): rusticated ground floor,
## string courses, two rows of bifore, hanging arches under the gallery.
static func _face(lm: LandmarkMesh, side: int) -> void:
	var out := Vector3(0, 0, 1)
	var length := HX * 2.0
	var dist := HZ
	if side == 1:
		out = Vector3(0, 0, -1)
	elif side >= 2:
		out = Vector3(1.0 if side == 2 else -1.0, 0, 0)
		length = HZ * 2.0
		dist = HX
	var right := Vector3.UP.cross(out)
	var p := out * dist
	var basis := Basis(right, Vector3.UP, out)
	var n := int(length / 7.4)
	for y in [7.4, 15.0]:
		lm.box("Trim", p + out * 0.2 + Vector3(0, y, 0), Vector3(length + 0.6, 0.5, 0.5), basis)
	for row in [8.4, 15.8]:
		for i in n:
			var s := (float(i) - float(n - 1) * 0.5) * 7.4
			LandmarkItlParts.gothic_window(lm, "Marble", "Shadow", p + right * s + Vector3(0, row, 0), out, 2.0, 4.6, 2,
				false, 0.25, 0.22)
	# Rusticated ground floor: staggered bossed blocks.
	if side != 1:
		var cw := 1.6
		for r in 11:
			var y := 0.35 + 0.66 * float(r)
			var off := 0.0 if r % 2 == 0 else cw * 0.5
			var count := int((length - off) / cw)
			for i in count:
				var s := -length * 0.5 + off + cw * (float(i) + 0.5)
				if side == 0 and absf(s - 0.6) < 2.4 and y < 7.0:
					continue
				lm.box("Stone", p + right * s + out * 0.09 + Vector3(0, y, 0), Vector3(cw * 0.92, 0.58, 0.18), basis, 0.0)
	# Small barred ground-floor windows.
	SEuUtil.face_row(lm, "Shadow", p + out * 0.14, right, out, 3.2, int(length / 8.4), 8.4, 1.2, 1.8)
	LandmarkItlParts.arch_frieze(lm, "Stone", p - right * (length * 0.5 + 1.3) + out * 1.3 + Vector3(0, TOP, 0),
		p + right * (length * 0.5 + 1.3) + out * 1.3 + Vector3(0, TOP, 0), out, 2.9, 1.5)
	LandmarkItlParts.quoins(lm, "Stone", p + right * length * 0.5, -right, -out, 0.0, TOP, 0.75, 1.5, 0.2)

## The Piazza front: arengario, door and frontispiece, the statues and the
## painted arms under the gallery.
static func _front(lm: LandmarkMesh) -> void:
	var z := HZ
	var out := Vector3(0, 0, 1)
	lm.box("Trim", Vector3(0, 0.5, z + 2.4), Vector3(HX * 2.0 - 6.0, 1.0, 4.8))
	SEuUtil.steps_up(lm, "Trim", Vector3(0, 0, z + 4.8), out, HX * 2.0 - 8.0, 0.4, 0.33, 3)
	# Door with the marble frontispiece (1528): pediment and monogram.
	lm.quad("Shadow", Vector3(-1.1, 1.0, z + 0.2), Vector3(2.3, 1.0, z + 0.2), Vector3(2.3, 6.4, z + 0.2),
		Vector3(-1.1, 6.4, z + 0.2), out)
	for sx in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0.6 + float(sx) * 2.0, 3.9, z + 0.35), Vector3(0.6, 5.8, 0.5))
	lm.box("Marble", Vector3(0.6, 7.0, z + 0.4), Vector3(4.8, 1.2, 0.6))
	lm.gable("Marble", Vector3(0.6, 7.6, z + 0.45), 4.6, 0.5, 1.2, Basis(Vector3.UP, PI * 0.5), 0.0, "Marble")
	lm.disc("Gold", Vector3(0.6, 8.0, z + 0.72), out, 0.45, 12)
	for sx in [-1.0, 1.0]:
		SEuUtil.blob(lm, "Marble", Vector3(0.6 + float(sx) * 1.6, 8.0, z + 0.6), 0.6, 0.4, 0.3, Vector3.ZERO, false, 4, 8)
	# David (copy) at the left of the door, Hercules and Cacus at the right.
	for sx in [-1.0, 1.0]:
		var bx := 0.6 + float(sx) * 4.6
		lm.box("Marble", Vector3(bx, 2.1, z + 2.0), Vector3(2.0, 2.2, 2.0))
		lm.box("Marble", Vector3(bx, 3.3, z + 2.0), Vector3(2.3, 0.3, 2.3))
		LandmarkKits.statue_figure(lm, "Marble", Vector3(bx, 3.45, z + 2.0), 5.2, sx < 0.0)
	SEuUtil.blob(lm, "Marble", Vector3(5.2, 4.2, z + 2.4), 0.5, 0.7, 0.45, Vector3.ZERO, false, 5, 8)
	# Marzocco, the heraldic lion, at the left corner of the arengario.
	lm.box("Marble", Vector3(-15.0, 2.0, z + 3.0), Vector3(1.4, 2.0, 1.4))
	SEuUtil.blob(lm, "Stone", Vector3(-15.0, 3.6, z + 3.0), 0.45, 0.6, 0.55, Vector3.ZERO, false, 5, 10)
	SEuUtil.blob(lm, "Stone", Vector3(-15.0, 4.4, z + 3.4), 0.3, 0.32, 0.3, Vector3.ZERO, false, 4, 8)
	# Painted arms of the Republic in the front arches of the gallery.
	for i in 9:
		var x := (float(i) - 4.0) * 4.6
		lm.box("Trim", Vector3(x, TOP - 1.1, z + 1.42), Vector3(1.2, 1.3, 0.1), Basis(), 0.0)
		lm.disc("Tile" if i % 2 == 0 else "Gold", Vector3(x, TOP - 1.05, z + 1.48), out, 0.42, 10)

## Salone dei Cinquecento: the long hall behind the palace.
static func _salone(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 10.0, -44.0), Vector3(24.0, 20.0, 50.0))
	lm.gable("Tile", Vector3(0, 20.0, -44.0), 24.0, 50.0, 3.8, Basis(), 0.4, "Stone")
	for sx in [-1.0, 1.0]:
		var out := Vector3(sx, 0, 0)
		for i in 6:
			var z := -44.0 + (float(i) - 2.5) * 7.6
			LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", Vector3(sx * 12.0, 8.0, z), out, 2.4, 6.0, 1, false, 0.2)
			LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", Vector3(sx * 12.0, 1.6, z), out, 1.2, 2.4, 1, false, 0.15)
		lm.box("Trim", Vector3(sx * 12.15, 19.6, -44.0), Vector3(0.4, 0.8, 50.0))
		lm.box("Trim", Vector3(sx * 12.1, 7.0, -44.0), Vector3(0.3, 0.4, 50.0))

## The Torre di Arnolfo standing on the gallery at `c` (ground point).
static func _tower(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkItlUtil.tower(lm, "Stone", "Shadow", c + Vector3(0, TOP, 0), 3.8, c + Vector3(0, 64.0, 0), 3.5, 0.0,
		[[31.0, 0.9, 3.2, 1, 0.0, true], [52.0, 0.9, 3.2, 1, 0.0, true], [57.0, 0.9, 3.2, 2, 2.6, true]])
	# Corbels carrying the cantilevered front over the gallery.
	for i in 4:
		lm.box("Stone", c + Vector3(-2.7 + 1.8 * float(i), TOP + 0.6, 3.9), Vector3(0.7, 1.6, 1.0))
	# Clock: dial ring, hour marks and the single hand.
	var cc := c + Vector3(0, 45.0, 3.72)
	lm.disc("Trim", cc, Vector3(0, 0, 1), 1.6, 24)
	lm.disc("Shadow", cc + Vector3(0, 0, 0.04), Vector3(0, 0, 1), 1.3, 24)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.box("Gold", cc + Vector3(cos(a) * 1.15, sin(a) * 1.15, 0.08), Vector3(0.12, 0.12, 0.05), Basis(), 0.0)
	lm.beam("Gold", cc + Vector3(0, 0, 0.1), cc + Vector3(0.6, 0.8, 0.1), 0.12, 0.05)
	LandmarkItlParts.quoins(lm, "Stone", c + Vector3(3.6, TOP + 2.0, 3.6), Vector3(-1, 0, 0), Vector3(0, 0, -1), 0.0,
		38.0, 0.9, 1.3, 0.12)
	# Crown: pointed hanging arches on corbels, swallow-tail merlons.
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		LandmarkItlParts.arch_frieze(lm, "Stone", c + n * 5.5 - r * 5.5 + Vector3(0, 64.0, 0),
			c + n * 5.5 + r * 5.5 + Vector3(0, 64.0, 0), n, 1.4, 2.0, true)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", c + Vector3(0, 64.0, 0), 3.5, 3.5, 0.0, 2.0, 2.4, 2.2, true, 1.3)
	# Bell chamber: four stout columns with round arches, three bells.
	var by := 65.2
	lm.box("Stone", c + Vector3(0, by - 0.2, 0), Vector3(6.4, 0.4, 6.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkItlParts.column(lm, "Trim", c + Vector3(float(sx) * 2.5, by, float(sz) * 2.5), 0.6, 9.0, 12)
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var arc := LandmarkItlParts.arch_pts(c + n * 2.5 + Vector3(0, by + 9.0, 0), b * Vector3(1, 0, 0), 2.5, false, 10)
		for j in arc.size() - 1:
			lm.beam("Trim", arc[j], arc[j + 1], 0.9, 0.6, n)
	var bell_y := [by + 1.0, by + 4.2, by + 1.2]
	for i in 3:
		var bp := c + Vector3(-1.2 + 1.2 * float(i), bell_y[i], 0.2 * float(i - 1))
		lm.lathe("Gold", bp, PackedVector2Array([Vector2(0.8, 0), Vector2(0.75, 0.15), Vector2(0.55, 0.5),
			Vector2(0.5, 1.0), Vector2(0.38, 1.3), Vector2(0.0, 1.4)]), 12)
	lm.box("Stone", c + Vector3(0, by + 12.5, 0), Vector3(6.6, 2.0, 6.6))
	lm.box("Trim", c + Vector3(0, by + 13.8, 0), Vector3(7.2, 0.6, 7.2))
	lm.box("Stone", c + Vector3(0, by + 14.8, 0), Vector3(5.8, 1.4, 5.8))
	lm.box("Trim", c + Vector3(0, 80.4, 0), Vector3(6.2, 0.8, 6.2))
	lm.spire("Tile", c + Vector3(0, 80.8, 0), 2.6, 9.6)
	# Ball, rod and the Marzocco vane holding the lily.
	var vb := c + Vector3(0, 90.4, 0)
	lm.lathe("Gold", vb, SEuUtil.dome(0.45, 0.45, 6), 10)
	lm.lathe("Gold", vb, PackedVector2Array([Vector2(0.45, 0), Vector2(0.3, -0.35), Vector2(0.0, -0.45)]), 10)
	lm.frustum("Gold", vb + Vector3(0, 0.4, 0), 0.06, 0.05, 1.2, 6)
	SEuUtil.blob(lm, "Gold", vb + Vector3(0, 2.1, 0), 0.25, 0.45, 0.4, Vector3.ZERO, false, 4, 8)
	SEuUtil.blob(lm, "Gold", vb + Vector3(0, 2.75, 0.2), 0.16, 0.18, 0.16, Vector3.ZERO, false, 3, 6)
	lm.beam("Gold", vb + Vector3(0.3, 1.8, 0.2), vb + Vector3(0.35, 3.4, 0.2), 0.05, 0.05)
	for k in 3:
		var a := PI * (0.25 + 0.25 * float(k))
		lm.beam("Gold", vb + Vector3(0.35, 3.4, 0.2), vb + Vector3(0.35 + cos(a) * 0.25, 3.4 + sin(a) * 0.25, 0.2), 0.05, 0.05)
