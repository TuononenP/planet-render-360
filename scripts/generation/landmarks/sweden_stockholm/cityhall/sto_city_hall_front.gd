class_name StoCityHallFront
extends RefCounted

## City Hall's two long ranges that face open space: the water front of the
## south (Golden Hall) range and the Borgargården courtyard it closes.
##
## Water front, from the front photo: a loggia of 17 slender pale columns
## (x -18.8..48.6, 4.2 m apart, OSM) carrying 16 round arches 5.4 m above
## the terrace, solid end piers, the dark loggia back wall with its doors;
## above, plain brick to the tall Golden Hall windows (a 6 m range at about
## 6.3 m, the triple window with its balcony to the west), a stone string
## course, then two rows of 36 small windows under the cornice at 25 m.
## Courtyard side: a seven-bay arcade (columns at 4.2 m, OSM) over the
## ground storey, three window rows above, the north range's central
## portal, the west face of the east range, the east face of the Blue Hall
## block, and the gilt statuettes along the south range's parapet.

const Z_FACE := 35.2
const Z_BACK := 27.0
const SPRING := 5.4
const COL_X0 := -18.8
const COL_X1 := 48.6
const COLS := 17
const Z_COL := 34.6

static func south_front(lm: LandmarkMesh) -> void:
	var x0 := LandmarkStockholm.SOUTH_X0
	var x1 := LandmarkStockholm.SOUTH_X1
	var cx := (x0 + x1) * 0.5
	var z0 := LandmarkStockholm.COURT_Z1
	# Ground storey behind the loggia, the upper storeys on the arcade.
	lm.box("Brick", Vector3(cx, SPRING * 0.5, (z0 + Z_BACK) * 0.5), Vector3(x1 - x0, SPRING, Z_BACK - z0))
	lm.box("Brick", Vector3(cx, (SPRING + 25.0) * 0.5, (z0 + Z_FACE) * 0.5),
		Vector3(x1 - x0, 25.0 - SPRING, Z_FACE - z0))
	for pier in [[x0, COL_X0 - 0.9], [COL_X1 + 0.9, x1]]:
		var a: float = pier[0]
		var b: float = pier[1]
		lm.box("Brick", Vector3((a + b) * 0.5, SPRING * 0.5, (Z_BACK + Z_FACE) * 0.5), Vector3(b - a, SPRING, Z_FACE - Z_BACK))
		lm.box("Stone", Vector3((a + b) * 0.5, 0.6, (Z_BACK + Z_FACE) * 0.5 + 0.25), Vector3(b - a + 0.4, 1.2, Z_FACE - Z_BACK + 0.5))
	lm.box("Stone", Vector3(cx, 24.65, (z0 + Z_FACE) * 0.5 + 0.1), Vector3(x1 - x0 + 0.7, 0.7, Z_FACE - z0 + 0.8))
	lm.box("Stone", Vector3(cx, 18.3, Z_FACE + 0.2), Vector3(x1 - x0, 0.4, 0.8))
	_loggia(lm)
	_windows(lm)

## Columns, arches and the back wall of the loggia.
static func _loggia(lm: LandmarkMesh) -> void:
	var pitch := (COL_X1 - COL_X0) / float(COLS - 1)
	var shaft := PackedVector2Array([Vector2(0.62, 0.0), Vector2(0.5, 0.35), Vector2(0.42, 0.6),
		Vector2(0.4, 4.6), Vector2(0.52, 5.0), Vector2(0.6, 5.4)])
	var column := LandmarkMesh.new()
	column.use("Stone", null)
	column.lathe("Stone", Vector3.ZERO, shaft, 12)
	column.box("Stone", Vector3(0, 5.5, 0), Vector3(1.3, 0.2, 1.3), Basis(), 0.0)
	for k in COLS:
		lm.merge(column, Transform3D(Basis(), Vector3(COL_X0 + pitch * float(k), 0.0, Z_COL)))
	var n := Vector3(0, 0, 1)
	for k in COLS - 1:
		var xc := COL_X0 + pitch * (float(k) + 0.5)
		LandmarkDetail.arch(lm, "Stone", Vector3(xc, SPRING + 0.2, Z_FACE - 0.1), n, pitch - 1.6, 0.4, 0.35, 14)
		_lunette(lm, Vector3(xc, SPRING + 0.2, Z_FACE + 0.04), n, (pitch - 1.6) * 0.5)
		if k % 2 == 1:
			lm.box("BrickDark", Vector3(xc, 2.0, Z_BACK + 0.06), Vector3(2.2, 4.0, 0.1), Basis(), 0.0)
			_lunette(lm, Vector3(xc, 4.0, Z_BACK + 0.07), n, 1.1)

## Dark half-round fill under an arch (the shadowed vault).
static func _lunette(lm: LandmarkMesh, c: Vector3, n: Vector3, r: float) -> void:
	var right := Vector3.UP.cross(n).normalized()
	for i in 10:
		var t0 := PI * float(i) / 10.0
		var t1 := PI * float(i + 1) / 10.0
		lm.tri("BrickDark", c, c + (right * cos(t0) + Vector3.UP * sin(t0)) * r,
			c + (right * cos(t1) + Vector3.UP * sin(t1)) * r, n, n, n, Vector2.ZERO,
			Vector2(cos(t0), sin(t0)) * r, Vector2(cos(t1), sin(t1)) * r)

## The Golden Hall windows, the balcony triple window, the small windows.
static func _windows(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	var xs: Array[float] = [-22.0]
	for k in 9:
		xs.append(-2.2 + 6.35 * float(k))
	for x in xs:
		LandmarkDetail.window(lm, "Stone", "HallLamp", Vector3(x, 12.9, Z_FACE), n, 1.6, 6.2, false, 0.3)
	# The triple window over the balcony, west of centre.
	var ox := -10.5
	for dx in [-1.9, 0.0, 1.9]:
		LandmarkDetail.window(lm, "Stone", "HallLamp", Vector3(ox + float(dx), 12.9, Z_FACE), n, 1.3, 6.2, false, 0.3)
	lm.box("Stone", Vector3(ox, 9.55, Z_FACE + 0.75), Vector3(6.0, 0.4, 1.5))
	LandmarkDetail.balustrade(lm, "Stone", Vector3(ox - 2.8, 9.75, Z_FACE + 1.35), Vector3(ox + 2.8, 9.75, Z_FACE + 1.35), 0.95, 2.8)
	for sx in [-3.0, 3.0]:
		lm.box("Stone", Vector3(ox + sx, 8.9, Z_FACE + 0.5), Vector3(0.5, 1.2, 0.8))
	# Two rows of small windows under the cornice.
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(LandmarkStockholm.SOUTH_X0, 18.6, Z_FACE),
		Vector3(1, 0, 0), n, LandmarkStockholm.SOUTH_X1 - LandmarkStockholm.SOUTH_X0, 5.8, 36, 2,
		Vector2(0.9, 1.7), 0.9, 2.5, 0.4)

## Borgargården: paving, the arcade on the south range, the window rows of
## the other three sides, the north portal, the gilt statuettes.
static func courtyard(lm: LandmarkMesh) -> void:
	var x0 := LandmarkStockholm.COURT_X0
	var x1 := LandmarkStockholm.COURT_X1
	var z0 := LandmarkStockholm.COURT_Z0
	var z1 := LandmarkStockholm.COURT_Z1
	lm.box("Granite", Vector3((x0 + x1) * 0.5, 0.15, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.3, z1 - z0))
	# North range, south face: windows and the central portal.
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(x0, 0.3, z0), Vector3(1, 0, 0), Vector3(0, 0, 1),
		x1 - x0, 23.0, 12, 3, Vector2(1.4, 3.0), 4.4, 6.5, 0.4)
	lm.box("BrickDark", Vector3(19.0, 2.8, z0 + 0.45), Vector3(3.4, 5.0, 0.1))
	LandmarkDetail.arch(lm, "Stone", Vector3(19.0, 5.3, z0 + 0.45), Vector3(0, 0, 1), 3.4, 0.5, 0.4)
	_lunette(lm, Vector3(19.0, 5.3, z0 + 0.5), Vector3(0, 0, 1), 1.7)
	# East range, west face, and the Blue Hall block's east face.
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(x1, 0.3, z0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
		z1 - z0, 23.0, 10, 3, Vector2(1.4, 3.0), 4.4, 6.5, 0.4)
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(x0, 0.3, z1), Vector3(0, 0, -1), Vector3(1, 0, 0),
		z1 - z0, 23.0, 10, 3, Vector2(1.4, 3.0), 4.4, 6.5, 0.4)
	# South range, north face: windows over the arcade.
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(x1, 5.4, z1), Vector3(-1, 0, 0), Vector3(0, 0, -1),
		x1 - x0, 19.0, 12, 3, Vector2(1.4, 3.0), 1.5, 6.0, 0.4)
	_arcade(lm, z1)
	# Gilt statuettes along the south range's parapet.
	for k in 6:
		var x := 7.0 + 6.4 * float(k)
		lm.box("Stone", Vector3(x, 25.9, z1 + 0.2), Vector3(0.9, 1.0, 0.9))
		LandmarkKits.statue_figure(lm, "Gilt", Vector3(x, 26.4, z1 + 0.2), 2.4)

## The seven-bay arcade of the courtyard's south side: columns standing
## proud of a dark recess under round archivolts.
static func _arcade(lm: LandmarkMesh, z: float) -> void:
	var pitch := 4.23
	var n := Vector3(0, 0, -1)
	var shaft := PackedVector2Array([Vector2(0.5, 0.0), Vector2(0.4, 0.3), Vector2(0.34, 0.5),
		Vector2(0.32, 3.6), Vector2(0.42, 3.9), Vector2(0.5, 4.2)])
	var column := LandmarkMesh.new()
	column.use("Stone", null)
	column.lathe("Stone", Vector3.ZERO, shaft, 10)
	column.box("Stone", Vector3(0, 4.3, 0), Vector3(1.05, 0.2, 1.05), Basis(), 0.0)
	for k in 8:
		lm.merge(column, Transform3D(Basis(), Vector3(6.5 + pitch * float(k), 0.3, z - 0.4)))
	for k in 7:
		var xc := 6.5 + pitch * (float(k) + 0.5)
		lm.box("BrickDark", Vector3(xc, 2.4, z - 0.06), Vector3(pitch - 1.0, 4.2, 0.1), Basis(), 0.0)
		LandmarkDetail.arch(lm, "Stone", Vector3(xc, 4.5, z - 0.1), n, pitch - 1.0, 0.35, 0.3, 12)
		_lunette(lm, Vector3(xc, 4.5, z - 0.12), n, (pitch - 1.0) * 0.5)
