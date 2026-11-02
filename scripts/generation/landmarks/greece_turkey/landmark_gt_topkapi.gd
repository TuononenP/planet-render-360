class_name LandmarkGtTopkapi
extends RefCounted

## The Topkapi Palace in Istanbul in true metres, origin in the middle
## of the Second Court (Divan Square), the way in from the Gate of
## Salutation at +Z and the Gate of Felicity at -Z.

const TOPKAPI_TOP := 38.0

## Topkapi Palace (from 1459): the Gate of Salutation between its two
## octagonal towers under tall lead cones, with the crenellated walls;
## the Imperial Council hall of three domes behind its columned portico
## and broad eaves, and the Tower of Justice (the tallest structure of
## the palace) with its arcaded belvedere and spire; the Harem's
## rambling blocks, chimneys and domes behind them; the kitchens' arcade,
## ten domes and twenty chimneys on the right; the Gate of Felicity with
## its columns, canopy and dome; the Audience Chamber in its colonnade of
## 22 columns, the Conqueror's Pavilion (the Treasury) with its arcade
## and Ahmed III's cruciform library in the Third Court; the Baghdad and
## Revan kiosks of the Fourth.
static func topkapi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5CAB0", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E8E2D2", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#70777E", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A35B3C", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B38465", 3.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#B8AE98", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#34302B", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2A3238"))
	LandmarkGtUtil.block(lm, "Court", -36.0, 36.0, 0.0, 0.15, -56.0, 56.0)
	LandmarkGtUtil.block(lm, "Court", -36.0, 36.0, 0.0, 2.5, -105.0, -56.0)
	_salutation(lm, Vector3(0, 0, 58.0))
	_council(lm)
	_justice(lm, Vector3(-43.5, 0, -43.0))
	_harem(lm)
	_kitchens(lm)
	_felicity(lm, Vector3(0, 0, -51.0))
	_audience(lm, Vector3(0, 2.5, -66.0))
	_treasury(lm)
	_library(lm, Vector3(15.5, 2.5, -86.5))
	_kiosk(lm, Vector3(16.0, 2.5, -100.0), 1.0)
	_kiosk(lm, Vector3(-20.0, 2.5, -98.0), 0.8)
	lm.commit(model)

# --- Shared parts ------------------------------------------------------------

## A small framed window: dark recess, stone sill and lintel, on a wall
## face at `c` (opening centre) facing `n`.
static func _win(lm: LandmarkMesh, c: Vector3, n: Vector3, w: float, h: float) -> void:
	var bas := Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n)
	lm.box("Glass", c - n * 0.05, Vector3(w, h, 0.2), bas, 0.0)
	lm.box("Marble", c - Vector3(0, h * 0.5 + 0.08, 0) + n * 0.08, Vector3(w + 0.3, 0.16, 0.3), bas, 0.0)
	lm.box("Marble", c + Vector3(0, h * 0.5 + 0.1, 0) + n * 0.06, Vector3(w + 0.4, 0.2, 0.24), bas, 0.0)

## Hipped roof over a w (x) by l (z) rectangle at eave level `c`, `rise`
## high, eaves overhanging by `over`.
static func _hip(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float, rise: float, over: float) -> void:
	var hx := w * 0.5 + over
	var hz := l * 0.5 + over
	var ridge := maxf(hz - hx, 0.0)
	var rx := maxf(hx - hz, 0.0)
	var t := c + Vector3(0, rise, 0)
	var p := [c + Vector3(-hx, 0, -hz), c + Vector3(hx, 0, -hz), c + Vector3(hx, 0, hz), c + Vector3(-hx, 0, hz)]
	var r0 := t + Vector3(-rx, 0, -ridge)
	var r1 := t + Vector3(rx, 0, ridge)
	lm.quad(key, p[0], p[1], t + Vector3(rx, 0, -ridge), r0, Vector3(0, hz, -rise).normalized())
	lm.quad(key, p[2], p[3], t + Vector3(-rx, 0, ridge), r1, Vector3(0, hz, rise).normalized())
	lm.quad(key, p[1], p[2], r1, t + Vector3(rx, 0, -ridge), Vector3(rise, hx, 0).normalized())
	lm.quad(key, p[3], p[0], r0, t + Vector3(-rx, 0, ridge), Vector3(-rise, hx, 0).normalized())
	lm.quad(key, p[0], p[1], p[2], p[3], Vector3.DOWN)

## Colonnade: `n` columns from a to b (bases) of height h under pointed
## arches, with the beam over them.
static func _arcade(lm: LandmarkMesh, a: Vector3, b: Vector3, n: int, h: float, r: float) -> void:
	for k in n:
		LandmarkGtOttoman.column(lm, "Marble", a.lerp(b, float(k) / float(n - 1)), r, h)
	for k in n - 1:
		var pa := a.lerp(b, float(k) / float(n - 1)) + Vector3(0, h, 0)
		var pb := a.lerp(b, float(k + 1) / float(n - 1)) + Vector3(0, h, 0)
		LandmarkGtOttoman.pointed_arch(lm, "Marble", pa, pb, pa.distance_to(pb) * 0.52, 0.3, r * 2.2)

# --- Second Court --------------------------------------------------------------

## Gate of Salutation at `c` (the middle of its court face): crenellated
## gate block with pointed portals and the inscription panels, two
## octagonal towers with slit windows, a corbelled ring and tall lead
## cones with gilt finials, and the crenellated walls running out.
static func _salutation(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Stone", c.x - 9.0, c.x + 9.0, 0.0, 11.0, c.z - 5.0, c.z + 5.0)
	for sz in [-1.0, 1.0]:
		var zf: float = c.z + sz * 5.0
		var o := Vector3(0, 0, sz)
		LandmarkGtUtil.block(lm, "Dark", c.x - 2.5, c.x + 2.5, 0.0, 5.5, zf - sz * 0.3, zf + sz * 0.02)
		LandmarkGtOttoman.pointed_arch(lm, "Marble", Vector3(c.x - 2.5, 5.5, zf) + o * 0.1, Vector3(c.x + 2.5, 5.5, zf) + o * 0.1,
			2.8, 0.5, 0.35)
		LandmarkGtUtil.block(lm, "Marble", c.x - 3.3, c.x + 3.3, 0.0, 5.5, zf - sz * 0.0, zf + sz * 0.12)
		LandmarkGtUtil.block(lm, "Dark", c.x - 2.4, c.x + 2.4, 0.0, 5.5, zf + sz * 0.1, zf + sz * 0.13)
		LandmarkGtUtil.block(lm, "Gilt", c.x - 2.2, c.x + 2.2, 9.0, 9.8, zf, zf + sz * 0.1)
		LandmarkCeParts.merlons(lm, "Stone", Vector3(c.x - 9.0, 11.0, zf - sz * 0.3), Vector3(c.x + 9.0, 11.0, zf - sz * 0.3),
			1.8, 0.9, 1.1, 0.8)
	for sx in [-1.0, 1.0]:
		var tp := Vector3(c.x + sx * 12.5, 0, c.z)
		lm.frustum("Stone", tp, 4.6, 4.3, 17.0, 8, PI / 8.0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Stone", tp + d * 4.15 + Vector3(0, 16.2, 0), Vector3(1.2, 0.6, 0.7), Basis(Vector3.UP, PI * 0.5 - a))
			if k % 2 == 0:
				_win(lm, tp + d * 4.2 + Vector3(0, 7.0 + 3.5 * float(k % 4) * 0.5, 0), d, 0.35, 1.4)
		lm.frustum("Marble", tp + Vector3(0, 16.5, 0), 4.9, 4.9, 1.5, 8, PI / 8.0)
		lm.spire("Lead", tp + Vector3(0, 18.0, 0), 4.9 * cos(PI / 8.0), 10.0, 0.0, 8)
		lm.frustum("Gilt", tp + Vector3(0, 27.6, 0), 0.12, 0.08, 1.4, 6)
		LandmarkGtUtil.block(lm, "Stone", c.x + sx * 22.0 - 11.0, c.x + sx * 22.0 + 11.0, 0.0, 7.0, c.z - 1.5, c.z + 1.5)
		LandmarkCeParts.merlons(lm, "Stone", Vector3(c.x + sx * 17.0, 7.0, c.z), Vector3(c.x + sx * 33.0, 7.0, c.z),
			2.0, 1.0, 1.0, 1.2)

## Imperial Council (Kubbealti): a hall of three domes on drums beside
## the court, its windows, the portico of eight columns under pointed
## arches and the broad lead eaves.
static func _council(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Stone", -49.0, -37.0, 0.0, 8.0, -36.0, -6.0)
	for i in 3:
		var z := -31.0 + 10.0 * float(i)
		LandmarkGtOttoman.small_dome(lm, "Stone", "Lead", "Gilt", Vector3(-43.0, 8.0, z), 4.2, 1.2, 18)
		for k in 2:
			_win(lm, Vector3(-37.0, 2.6 + 3.2 * float(k), z), Vector3.RIGHT, 1.2, 1.8)
			_win(lm, Vector3(-49.0, 2.6 + 3.2 * float(k), z), Vector3.LEFT, 1.2, 1.8)
	LandmarkGtUtil.block(lm, "Gilt", -36.95, -36.9, 2.2, 4.0, -21.6, -19.4)
	_arcade(lm, Vector3(-34.6, 0.15, -34.0), Vector3(-34.6, 0.15, -8.0), 8, 4.4, 0.3)
	LandmarkGtUtil.block(lm, "Marble", -35.2, -37.0, 6.0, 6.6, -35.0, -7.0)
	var eave := [Vector3(-37.0, 8.2, -36.0), Vector3(-37.0, 8.2, -6.0), Vector3(-32.4, 6.4, -6.0), Vector3(-32.4, 6.4, -36.0)]
	lm.quad("Lead", eave[0], eave[1], eave[2], eave[3], Vector3(1.8, 4.6, 0).normalized())
	lm.quad("Lead", eave[0], eave[1], eave[2], eave[3], Vector3(-1.8, -4.6, 0).normalized())

## Tower of Justice at `tc`: the square stone shaft with windows in three
## storeys, a cornice, the belvedere of twelve columns and arches, the
## tall lead spire and the gilt finial at 38 m.
static func _justice(lm: LandmarkMesh, tc: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Stone", tc.x - 4.5, tc.x + 4.5, 0.0, 22.0, tc.z - 4.5, tc.z + 4.5)
	for y in [8.0, 15.0]:
		LandmarkGtUtil.block(lm, "Marble", tc.x - 4.65, tc.x + 4.65, float(y), float(y) + 0.3, tc.z - 4.65, tc.z + 4.65)
	for k in 4:
		var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
		var side := Vector3.UP.cross(out)
		for y2 in [5.0, 11.5, 18.2]:
			for s in [-1.0, 1.0]:
				LandmarkGtOttoman.window(lm, "Marble", "Glass", tc + out * 4.5 + side * 1.6 * float(s) + Vector3(0, float(y2) - 1.3, 0),
					out, 0.9, 2.6, 0.25)
	LandmarkDetail.cornice(lm, "Marble", tc + Vector3(-4.5, 22.0, 4.5), tc + Vector3(4.5, 22.0, 4.5), Vector3.BACK, 0.7, false)
	LandmarkDetail.cornice(lm, "Marble", tc + Vector3(4.5, 22.0, -4.5), tc + Vector3(-4.5, 22.0, -4.5), Vector3.FORWARD, 0.7,
		false)
	LandmarkDetail.cornice(lm, "Marble", tc + Vector3(4.5, 22.0, 4.5), tc + Vector3(4.5, 22.0, -4.5), Vector3.RIGHT, 0.7, false)
	LandmarkDetail.cornice(lm, "Marble", tc + Vector3(-4.5, 22.0, -4.5), tc + Vector3(-4.5, 22.0, 4.5), Vector3.LEFT, 0.7, false)
	LandmarkGtUtil.block(lm, "Marble", tc.x - 5.0, tc.x + 5.0, 22.0, 22.7, tc.z - 5.0, tc.z + 5.0)
	# Belvedere: columns on all four sides and the arches between them.
	for side_i in 4:
		var o := Vector3(sin(PI * 0.5 * float(side_i)), 0, cos(PI * 0.5 * float(side_i)))
		var sd := Vector3.UP.cross(o)
		var a := tc + o * 3.7 - sd * 3.7 + Vector3(0, 22.7, 0)
		var b := tc + o * 3.7 + sd * 3.7 + Vector3(0, 22.7, 0)
		for j in 4:
			if side_i % 2 == 1 and (j == 0 or j == 3):
				continue
			LandmarkGtOttoman.column(lm, "Marble", a.lerp(b, float(j) / 3.0), 0.26, 2.4)
		for j2 in 3:
			var pa := a.lerp(b, float(j2) / 3.0) + Vector3(0, 2.4, 0)
			var pb := a.lerp(b, float(j2 + 1) / 3.0) + Vector3(0, 2.4, 0)
			LandmarkGtOttoman.pointed_arch(lm, "Marble", pa, pb, 1.35, 0.25, 0.5)
		lm.box("Stone", (a + b) * 0.5 + Vector3(0, 4.25, 0), Vector3(7.9, 0.6, 0.6), Basis(sd, Vector3.UP, o))
	LandmarkGtUtil.block(lm, "Marble", tc.x - 5.0, tc.x + 5.0, 26.6, 27.3, tc.z - 5.0, tc.z + 5.0)
	lm.spire("Lead", tc + Vector3(0, 27.3, 0), 5.2, 9.7, 0.0, 4)
	lm.frustum("Gilt", tc + Vector3(0, 36.6, 0), 0.14, 0.08, TOPKAPI_TOP - 36.6 - 0.3, 6)
	lm.lathe("Gilt", tc + Vector3(0, TOPKAPI_TOP - 0.45, 0), SEuUtil.dome(0.22, 0.45, 3), 8)

## The Harem: a rambling mass of tile-roofed blocks of varied height
## behind the council hall, with windows, chimneys and lead domes.
static func _harem(lm: LandmarkMesh) -> void:
	for ix in 4:
		for iz in 6:
			if (ix == 0 and iz == 5) or (ix == 3 and iz == 0):
				continue
			var n := ix * 6 + iz
			var h := 6.5 + 4.0 * LandmarkGtUtil.hash01(n, 4)
			var c := Vector3(-92.0 + 10.2 * float(ix), 0, -38.0 + 9.4 * float(iz))
			LandmarkGtUtil.block(lm, "Stone", c.x - 5.0, c.x + 5.0, 0.0, h, c.z - 4.5, c.z + 4.5)
			LandmarkGtUtil.block(lm, "Marble", c.x - 5.15, c.x + 5.15, h - 0.35, h, c.z - 4.65, c.z + 4.65)
			for k in 3:
				var off := -3.0 + 3.0 * float(k)
				_win(lm, Vector3(c.x + off, h - 2.2, c.z + 4.5), Vector3.BACK, 0.9, 1.5)
				_win(lm, Vector3(c.x + off, h - 2.2, c.z - 4.5), Vector3.FORWARD, 0.9, 1.5)
				_win(lm, Vector3(c.x + 5.0, h - 2.2, c.z + off), Vector3.RIGHT, 0.9, 1.5)
			if LandmarkGtUtil.hash01(n, 8) > 0.72:
				LandmarkGtOttoman.small_dome(lm, "Stone", "Lead", "", c + Vector3(0, h, 0), 3.4, 0.6, 16)
			else:
				var turn := Basis(Vector3.UP, PI * 0.5) if LandmarkGtUtil.hash01(n, 6) > 0.5 else Basis()
				lm.gable("Tile", c + Vector3(0, h, 0), 9.0, 10.0, 2.6, turn, 0.6, "Stone")
				var cp := c + Vector3(2.5, 0, 2.0 - 4.0 * LandmarkGtUtil.hash01(n, 9))
				lm.box("Stone", cp + Vector3(0, h + 1.8, 0), Vector3(0.8, 3.6, 0.8))
				lm.frustum("Lead", cp + Vector3(0, h + 3.6, 0), 0.6, 0.0, 0.9, 8)

## The kitchens along the court's east side: the arcade of 19 columns
## under its eave, ten domed kitchens and their twenty tall chimneys.
static func _kitchens(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Brick", 34.0, 46.0, 0.0, 6.5, -38.0, 38.0)
	LandmarkGtUtil.block(lm, "Stone", 33.6, 46.4, 6.5, 6.9, -38.4, 38.4)
	_arcade(lm, Vector3(31.8, 0.15, -36.0), Vector3(31.8, 0.15, 36.0), 19, 3.6, 0.28)
	var eave := [Vector3(34.0, 6.0, -38.0), Vector3(34.0, 6.0, 38.0), Vector3(30.6, 5.0, 38.0), Vector3(30.6, 5.0, -38.0)]
	lm.quad("Lead", eave[0], eave[1], eave[2], eave[3], Vector3(-1.0, 3.4, 0).normalized())
	lm.quad("Lead", eave[0], eave[1], eave[2], eave[3], Vector3(1.0, -3.4, 0).normalized())
	for i in 10:
		var z := -34.2 + 7.6 * float(i)
		LandmarkGtOttoman.small_dome(lm, "Brick", "Lead", "", Vector3(40.0, 6.9, z), 3.2, 0.9, 16)
		for cx in [36.4, 43.6]:
			lm.frustum("Brick", Vector3(cx, 6.9, z), 0.95, 0.8, 4.4, 10)
			lm.frustum("Stone", Vector3(cx, 11.3, z), 1.0, 1.0, 0.3, 10)
			lm.frustum("Lead", Vector3(cx, 11.6, z), 1.1, 0.0, 2.0, 10)
		_win(lm, Vector3(46.0, 3.5, z), Vector3.RIGHT, 1.0, 1.6)

## Gate of Felicity at `c`: marble gate hall with the gilt-framed door,
## the slender columns carrying its broad canopy and the dome over it.
static func _felicity(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 12.0, c.x + 12.0, 0.0, 6.5, c.z - 5.0, c.z + 4.0)
	LandmarkGtUtil.block(lm, "Dark", c.x - 2.2, c.x + 2.2, 0.0, 5.0, c.z + 3.95, c.z + 4.1)
	LandmarkGtUtil.block(lm, "Gilt", c.x - 2.7, c.x + 2.7, 5.0, 5.4, c.z + 4.0, c.z + 4.15)
	for s in [-1.0, 1.0]:
		LandmarkGtUtil.block(lm, "Gilt", c.x + s * 2.45 - 0.25, c.x + s * 2.45 + 0.25, 0.0, 5.0, c.z + 4.0, c.z + 4.15)
	_arcade(lm, Vector3(c.x - 10.0, 0.15, c.z + 6.8), Vector3(c.x + 10.0, 0.15, c.z + 6.8), 6, 5.0, 0.3)
	_hip(lm, "Lead", c + Vector3(0, 6.9, 0.9), 24.0, 12.0, 3.0, 2.2)
	LandmarkGtOttoman.small_dome(lm, "Marble", "Lead", "Gilt", c + Vector3(0, 8.6, 3.2), 2.6, 0.8, 16)

# --- Third and Fourth Courts ---------------------------------------------------

## Audience Chamber (Arz Odasi) at `c`: the marble hall inside a portico
## of 22 columns under a broad hipped lead roof.
static func _audience(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 8.0, c.x + 8.0, c.y, c.y + 6.0, c.z - 5.0, c.z + 5.0)
	for k in 3:
		_win(lm, Vector3(c.x - 5.0 + 5.0 * float(k), c.y + 3.0, c.z + 5.0), Vector3.BACK, 1.2, 2.0)
	var hx := 10.8
	var hz := 7.8
	for k2 in 7:
		var x := -hx + 2.0 * hx * float(k2) / 6.0
		for sz in [-1.0, 1.0]:
			LandmarkGtOttoman.column(lm, "Marble", c + Vector3(x, 0, sz * hz), 0.26, 4.6)
	for k3 in 4:
		var z := -hz + 2.0 * hz * float(k3 + 1) / 5.0
		for sx in [-1.0, 1.0]:
			LandmarkGtOttoman.column(lm, "Marble", c + Vector3(sx * hx, 0, z), 0.26, 4.6)
	LandmarkGtUtil.block(lm, "Marble", c.x - hx - 0.4, c.x + hx + 0.4, c.y + 4.6, c.y + 5.2, c.z - hz - 0.4, c.z + hz + 0.4)
	_hip(lm, "Lead", c + Vector3(0, 6.0, 0), 2.0 * hx, 2.0 * hz, 3.6, 1.8)

## The Conqueror's Pavilion (the Treasury) on the Third Court: its domed
## rooms, the arcaded loggia along the court front.
static func _treasury(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Stone", -34.0, -10.0, 2.5, 8.0, -90.0, -80.0)
	for i in 4:
		LandmarkGtOttoman.small_dome(lm, "Stone", "Lead", "Gilt", Vector3(-31.0 + 6.0 * float(i), 8.0, -85.0), 2.6, 0.8, 14)
	_arcade(lm, Vector3(-33.6, 2.5, -77.4), Vector3(-10.4, 2.5, -77.4), 9, 3.4, 0.26)
	LandmarkGtUtil.block(lm, "Stone", -34.0, -10.0, 7.2, 8.0, -80.0, -76.8)

## Ahmed III's library at `c`: a Greek cross on a raised basement, the
## central dome on its drum, the front portico with its four columns and
## the fountain beneath the stair.
static func _library(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 7.0, c.x + 7.0, c.y, c.y + 1.6, c.z - 7.0, c.z + 7.0)
	var y := c.y + 1.6
	LandmarkGtUtil.block(lm, "Marble", c.x - 6.5, c.x + 6.5, y, y + 6.0, c.z - 2.8, c.z + 2.8)
	LandmarkGtUtil.block(lm, "Marble", c.x - 2.8, c.x + 2.8, y, y + 6.0, c.z - 6.5, c.z + 6.5)
	for s in [-1.0, 1.0]:
		_win(lm, Vector3(c.x + s * 6.5, y + 3.0, c.z), Vector3(s, 0, 0), 1.0, 2.0)
		_win(lm, Vector3(c.x, y + 3.0, c.z - 6.5), Vector3.FORWARD, 1.0, 2.0)
		lm.gable("Lead", c + Vector3(s * 4.65, y - c.y + 6.0, 0), 5.6, 3.7, 1.2, Basis(Vector3.UP, PI * 0.5), 0.3, "Marble")
		lm.gable("Lead", c + Vector3(0, y - c.y + 6.0, s * 4.65), 5.6, 3.7, 1.2, Basis(), 0.3, "Marble")
	LandmarkGtOttoman.small_dome(lm, "Marble", "Lead", "Gilt", c + Vector3(0, y - c.y + 6.0, 0), 3.4, 1.4, 18)
	_arcade(lm, Vector3(c.x - 3.6, y, c.z + 8.6), Vector3(c.x + 3.6, y, c.z + 8.6), 4, 3.4, 0.24)
	LandmarkGtUtil.block(lm, "Marble", c.x - 4.2, c.x + 4.2, y, y + 0.2, c.z + 6.5, c.z + 9.2)
	_hip(lm, "Lead", c + Vector3(0, y - c.y + 5.2, 7.9), 8.0, 2.8, 0.9, 0.5)
	LandmarkGtUtil.block(lm, "Marble", c.x - 1.6, c.x + 1.6, c.y, c.y + 1.4, c.z + 9.2, c.z + 9.7)
	LandmarkGtUtil.block(lm, "Dark", c.x - 0.4, c.x + 0.4, c.y + 0.4, c.y + 1.1, c.z + 9.7, c.z + 9.72)

## Cruciform kiosk at `c`, scaled by `s` (1 = the Baghdad Kiosk): four
## iwans round a square domed hall, tiled with windows in each arm, the
## colonnaded gallery round it under broad eaves.
static func _kiosk(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 4.5 * s, c.x + 4.5 * s, c.y, c.y + 7.0 * s, c.z - 4.5 * s, c.z + 4.5 * s)
	LandmarkGtUtil.block(lm, "Marble", c.x - 6.8 * s, c.x + 6.8 * s, c.y, c.y + 5.0 * s, c.z - 2.4 * s, c.z + 2.4 * s)
	LandmarkGtUtil.block(lm, "Marble", c.x - 2.4 * s, c.x + 2.4 * s, c.y, c.y + 5.0 * s, c.z - 6.8 * s, c.z + 6.8 * s)
	for k in 4:
		var o := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
		_win(lm, c + o * 6.8 * s + Vector3(0, 2.6 * s, 0), o, 1.0 * s, 2.0 * s)
		LandmarkGtUtil.block(lm, "Glass", c.x + o.x * 5.0 * s - 0.1, c.x + o.x * 5.0 * s + 0.1, c.y + 5.3 * s, c.y + 6.4 * s,
			c.z + o.z * 5.0 * s - 0.1, c.z + o.z * 5.0 * s + 0.1)
	# Gallery of columns at the four inner corners of the cross, broad eaves.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for t in 2:
				var p := c + Vector3(sx * (6.8 if t == 0 else 4.5) * s, 0, sz * (4.5 if t == 0 else 6.8) * s)
				LandmarkGtOttoman.column(lm, "Marble", p, 0.22 * s, 4.4 * s)
	_hip(lm, "Lead", c + Vector3(0, 4.9 * s, 0), 14.4 * s, 5.0 * s, 1.0 * s, 1.0 * s)
	_hip(lm, "Lead", c + Vector3(0, 4.9 * s, 0), 5.0 * s, 14.4 * s, 1.0 * s, 1.0 * s)
	LandmarkGtOttoman.small_dome(lm, "Marble", "Lead", "Gilt", c + Vector3(0, 7.0 * s, 0), 4.4 * s, 0.8 * s, 20)
