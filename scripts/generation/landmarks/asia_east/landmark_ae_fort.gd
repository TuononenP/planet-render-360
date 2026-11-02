class_name LandmarkAeFort
extends RefCounted

## Ramparts and the palace-fortress of China in true metres: a 400 m
## piece of the Great Wall at Badaling (Ming, 1505: granite footing,
## brick rampart 6.5 m wide at the base and 5.8 m at the top, a
## crenellated outer parapet with peep holes, a low inner parapet,
## stone drain spouts, and two-storey watchtowers with arched windows,
## a crenellated deck and a tiled guardhouse, 12 m) and the Potala
## Palace (117 m: battered White Palace plinth and wings, the Red
## Palace, hundreds of Tibetan windows in black trapezoid surrounds
## under their pleated awnings, maroon penbe friezes with gilt mirrors,
## zigzag stairways and gilded roofs with victory banners). The wall
## runs along +X with its outer (enemy) side at -Z; the palace faces
## south (+Z).

# --- Great Wall at Badaling ---

const WALL_HALF := 200.0
const WALL_TOWERS := [-165.0, -55.0, 55.0, 165.0]
const WALK_Y := 6.15

static func great_wall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F8A82", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9C968C", 3.0))
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#5A5D60", 2.0))
	var len_m := WALL_HALF * 2.0
	# Granite footing courses, battered brick rampart, coping course and
	# the paved walkway.
	LandmarkAeParts.batter(lm, "Stone", 0, 0, len_m, 6.9, len_m, 6.7, 0.0, 2.0)
	LandmarkAeParts.batter(lm, "Brick", 0, 0, len_m, 6.7, len_m, 6.0, 2.0, 6.0)
	lm.box("Stone", Vector3(0, 6.05, 0), Vector3(len_m, 0.1, 6.2), Basis(), 0.0)
	# Outer parapet: a breast wall pierced by a shooting hole under each
	# merlon, the merlons each pierced by a peep hole.
	var x := -WALL_HALF + 1.2
	while x < WALL_HALF - 1.0:
		if not _in_tower(x, 6.5):
			_breast(lm, x, 2.4)
			_merlon(lm, Vector3(x, WALK_Y + 0.9, -2.75), 1.4, 1.3, 0.6)
		x += 2.4
	# Inner parapet (yuqiang) with its coping, and drain spouts below it.
	lm.box("Brick", Vector3(0, WALK_Y + 0.5, 2.8), Vector3(len_m, 1.0, 0.5))
	lm.box("Stone", Vector3(0, WALK_Y + 1.05, 2.8), Vector3(len_m, 0.1, 0.62), Basis(), 0.0)
	x = -WALL_HALF + 6.0
	while x < WALL_HALF:
		if not _in_tower(x, 7.0):
			lm.beam("Stone", Vector3(x, 5.6, 2.9), Vector3(x, 5.5, 4.0), 0.4, 0.3)
			lm.beam("Stone", Vector3(x, 5.6, -2.9), Vector3(x, 5.5, -4.0), 0.4, 0.3)
		x += 12.0
	for tx in WALL_TOWERS:
		_tower(lm, float(tx))
	lm.commit(model)

static func _in_tower(x: float, half: float) -> bool:
	for tx in WALL_TOWERS:
		if absf(x - float(tx)) < half:
			return true
	return false

## One 2.4 m bay of the outer breast wall centred on x (0.9 m high,
## 0.6 m thick), with the low shooting hole through it.
static func _breast(lm: LandmarkMesh, x: float, bay: float) -> void:
	var hole := Vector2(0.25, 0.3)
	var side := (bay - hole.x) * 0.5
	for s in [-1.0, 1.0]:
		lm.box("Brick", Vector3(x + s * (hole.x + side) * 0.5, WALK_Y + 0.45, -2.75), Vector3(side, 0.9, 0.6), Basis(), 0.0)
	lm.box("Brick", Vector3(x, WALK_Y + 0.175, -2.75), Vector3(hole.x, 0.35, 0.6), Basis(), 0.0)
	lm.box("Brick", Vector3(x, WALK_Y + 0.775, -2.75), Vector3(hole.x, 0.25, 0.6), Basis(), 0.0)

## Merlon w wide, h tall on a breast wall at `base` (bottom centre),
## `d` thick: two cheeks, a sill and a head round a square peep hole,
## and a stone coping.
static func _merlon(lm: LandmarkMesh, base: Vector3, w: float, h: float, d: float) -> void:
	var hole := Vector2(0.3, 0.35)
	var cheek := (w - hole.x) * 0.5
	var hy := h * 0.45
	for s in [-1.0, 1.0]:
		lm.box("Brick", base + Vector3(s * (hole.x + cheek) * 0.5, h * 0.5, 0), Vector3(cheek, h, d), Basis(), 0.0)
	lm.box("Brick", base + Vector3(0, hy * 0.5, 0), Vector3(hole.x, hy, d), Basis(), 0.0)
	var top := hy + hole.y
	lm.box("Brick", base + Vector3(0, (top + h) * 0.5, 0), Vector3(hole.x, h - top, d), Basis(), 0.0)
	lm.box("Stone", base + Vector3(0, h + 0.05, 0), Vector3(w + 0.1, 0.1, d + 0.1), Basis(), 0.0)

## Watchtower astride the wall at x: battered brick base, a hollow
## storey with three arched windows a side (real openings), a corbelled
## deck, crenellated parapet and a guardhouse under a gabled tile roof
## (12 m).
static func _tower(lm: LandmarkMesh, x: float) -> void:
	var hw := 5.7
	LandmarkAeParts.batter(lm, "Stone", x, 0, 12.4, 12.4, 12.2, 12.2, 0.0, 2.0)
	LandmarkAeParts.batter(lm, "Brick", x, 0, 12.2, 12.2, hw * 2.0 + 0.7, hw * 2.0 + 0.7, 2.0, WALK_Y)
	var sh := 3.05
	lm.box("Brick", Vector3(x, WALK_Y + sh * 0.5, 0), Vector3(hw * 2.0, sh, hw * 2.0))
	for f in 4:
		var a := PI * 0.5 * f
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3.UP.cross(n).normalized() * -1.0
		var origin := Vector3(x, WALK_Y, 0) + n * hw - r * hw
		LandmarkDetail.pierced_face(lm, "Brick", "Shadow", origin, r, n, hw * 2.0, sh, 3, 1,
			Vector2(1.1, 1.6), 0.55, 3.0, 0.35)
		for i in 3:
			var c := origin + r * (hw * 2.0 * (float(i) + 0.5) / 3.0) + Vector3(0, 0.55 + 1.6, 0) + n * 0.35
			LandmarkDetail.arch(lm, "Brick", c, n, 1.1, 0.24, 0.12)
	# Corbelled cornice, deck, merlons round the edge.
	var yd := WALK_Y + sh
	lm.box("Stone", Vector3(x, yd + 0.12, 0), Vector3(12.4, 0.24, 12.4))
	lm.box("Brick", Vector3(x, yd + 0.33, 0), Vector3(12.8, 0.18, 12.8), Basis(), 0.0)
	var top := yd + 0.42
	for s in [-1.0, 1.0]:
		lm.box("Brick", Vector3(x, top + 0.3, s * 6.1), Vector3(12.8, 0.6, 0.6))
		lm.box("Brick", Vector3(x + s * 6.1, top + 0.3, 0), Vector3(0.6, 0.6, 11.6))
		for i in 5:
			var o := -5.0 + 2.5 * i
			_merlon(lm, Vector3(x + o, top + 0.6, s * 6.1), 1.2, 1.0, 0.6)
			lm.box("Brick", Vector3(x + s * 6.1, top + 1.1, o), Vector3(0.6, 1.0, 1.2), Basis(), 0.0)
	# Guardhouse: brick walls with a door, gabled tile roof to 12 m.
	var gw := Vector2(6.0, 4.6)
	var gh := 12.0 - 1.0 - top
	lm.box("Brick", Vector3(x, top + gh * 0.5, 0), Vector3(gw.x, gh, gw.y))
	lm.box("Shadow", Vector3(x, top + 0.9, gw.y * 0.5 + 0.01), Vector3(1.0, 1.8, 0.04), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Brick", Vector3(x, top + 1.8, gw.y * 0.5), Vector3.BACK, 1.0, 0.2, 0.1)
	lm.gable("Tile", Vector3(x, top + gh, 0), gw.y, gw.x, 0.9, Basis(Vector3.UP, PI * 0.5), 0.6, "Brick")
	lm.box("Tile", Vector3(x, 12.0 - 0.1, 0), Vector3(gw.x + 1.0, 0.2, 0.3), Basis(), 0.0)

# --- Potala Palace ---

static func potala(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE8DE", 4.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#8E2F25", 4.0))
	lm.use("Maroon", LandmarkMaterials.paint("#5A2B22", 0.8, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	# Battered plinth climbing the Marpo Ri and the two White Palace wings.
	LandmarkAeParts.batter(lm, "White", 0, 0, 330.0, 66.0, 306.0, 58.0, 0.0, 45.0)
	_window_rows(lm, 0.0, 140.0, 7.0, [6.0, 14.0, 22.0, 30.0, 38.0], Vector4(33.0, 29.0, 0.0, 45.0), "White")
	_stairs(lm)
	for s in [-1.0, 1.0]:
		var wx: float = s * 102.0
		LandmarkAeParts.batter(lm, "White", wx, 0, 96.0, 50.0, 90.0, 46.0, 44.0, 80.0)
		_penbe(lm, Vector3(wx, 80.0, 0), Vector2(92.0, 48.0), 3.0)
		_window_rows(lm, wx, 40.0, 5.0, [52.0, 62.0, 72.0], Vector4(25.0, 23.0, 44.0, 80.0), "White")
		# End faces of each wing.
		for row in [56.0, 68.0]:
			for z in [-14.0, -4.0, 6.0, 16.0]:
				var fx: float = wx + s * lerpf(48.0, 45.0, (row - 44.0) / 36.0)
				_tib_window(lm, Vector3(fx, row, z), 1.8, 2.8, Vector3(s, 0, 0), "White")
	# Red Palace: white base course, red storeys, maroon penbe, top storey.
	LandmarkAeParts.batter(lm, "White", 0, 0, 112.0, 52.0, 108.0, 50.0, 44.0, 62.0)
	LandmarkAeParts.batter(lm, "Red", 0, 0, 108.0, 50.0, 102.0, 46.0, 62.0, 96.0)
	_window_rows(lm, 0.0, 36.0, 4.5, [52.0], Vector4(26.0, 25.0, 44.0, 62.0), "White")
	_window_rows(lm, 0.0, 36.0, 4.5, [68.0, 76.0, 84.0, 91.0], Vector4(25.0, 23.0, 62.0, 96.0), "Red")
	for s in [-1.0, 1.0]:
		for row in [70.0, 82.0]:
			for z in [-15.0, -7.5, 0.0, 7.5, 15.0]:
				_tib_window(lm, Vector3(s * lerpf(54.0, 51.0, (row - 62.0) / 34.0), row, z), 1.8, 2.8,
					Vector3(s, 0, 0), "Red")
	_penbe(lm, Vector3(0, 96.0, 0), Vector2(106.0, 48.0), 6.0)
	lm.box("Red", Vector3(0, 104.5, 0), Vector3(84.0, 5.0, 36.0))
	_window_rows(lm, 0.0, 32.0, 4.0, [104.3], Vector4(18.05, 18.05, 102.0, 107.0), "Red")
	# Gilded roofs: the great central one and two pairs of stupa-hall
	# pavilions, with ridge ornaments and victory banners.
	var rc := Vector3(0, 107.0, 0)
	LandmarkAeParts.hip_roof(lm, "Gold", rc, Vector2(64.0, 32.0), Vector2(34.0, 3.0), 7.6, 1.0)
	LandmarkAeParts.hip_ridges(lm, "Gold", rc, Vector2(64.0, 32.0), Vector2(34.0, 3.0), 7.6, 1.0, 0.6)
	lm.box("Gold", Vector3(0, 115.0, 0), Vector3(36.0, 0.8, 1.4))
	for s in [-1.0, 1.0]:
		_banner(lm, Vector3(s * 17.0, 115.4, 0), 1.6)
		_banner(lm, Vector3(s * 41.0, 107.0, 17.0), 2.6)
		_banner(lm, Vector3(s * 52.0, 102.0, 23.0), 3.0)
		for p in [Vector2(47.0, 0.0), Vector2(30.0, -12.0)]:
			var pc := Vector3(s * p.x, 107.0, p.y)
			lm.box("Red", pc + Vector3(0, -1.5, 0), Vector3(10.0, 3.0, 10.0))
			LandmarkAeParts.hip_roof(lm, "Gold", pc, Vector2(16.0, 16.0), Vector2(6.0, 2.0), 5.5, 0.8)
			LandmarkAeParts.hip_ridges(lm, "Gold", pc, Vector2(16.0, 16.0), Vector2(6.0, 2.0), 5.5, 0.8, 0.35)
			lm.box("Gold", pc + Vector3(0, 5.8, 0), Vector3(6.4, 0.5, 0.6))
			lm.lathe("Gold", pc + Vector3(0, 6.0, 0), PackedVector2Array([Vector2(0.7, 0), Vector2(0.9, 0.5),
				Vector2(0.4, 1.2), Vector2(0.05, 2.4)]), 12)
	lm.commit(model)

## Rows of Tibetan windows across x = cx +- half every `pitch` m at the
## heights `ys` on the battered south face; `face` = (z at the bottom, z
## at the top, bottom y, top y) of the wall.
static func _window_rows(lm: LandmarkMesh, cx: float, half: float, pitch: float, ys: Array, face: Vector4,
		wall: String) -> void:
	for y in ys:
		var z := lerpf(face.x, face.y, (float(y) - face.z) / (face.w - face.z))
		var x := cx - half
		while x <= cx + half + 0.01:
			_tib_window(lm, Vector3(x, float(y), z), 1.8, 2.8, Vector3.BACK, wall)
			x += pitch

## Tibetan window of opening w x h centred at c on a wall facing n: the
## black trapezoid surround (wider at the foot), a timber frame round a
## dark recess, the lintel and its pleated shambu awning.
static func _tib_window(lm: LandmarkMesh, c: Vector3, w: float, h: float, n: Vector3, wall: String) -> void:
	var r := Vector3.UP.cross(n).normalized() * -1.0
	var basis := Basis(r, Vector3.UP, n)
	var f := c + n * 0.05
	var yb := -h * 0.5 - 0.45
	var yt := h * 0.5 + 0.15
	lm.quad("Shadow", f + r * (w * 0.5 + 0.55) + Vector3(0, yb, 0), f - r * (w * 0.5 + 0.55) + Vector3(0, yb, 0),
		f - r * (w * 0.5 + 0.25) + Vector3(0, yt, 0), f + r * (w * 0.5 + 0.25) + Vector3(0, yt, 0), n)
	var d := 0.3
	for s in [-1.0, 1.0]:
		lm.box("Maroon", c + r * s * (w * 0.5 + 0.08) + n * d * 0.5, Vector3(0.16, h, d), basis, 0.0)
	lm.box("Maroon", c + Vector3(0, -h * 0.5 - 0.08, 0) + n * d * 0.5, Vector3(w + 0.32, 0.16, d + 0.1), basis, 0.0)
	lm.box("Maroon", c + n * d * 0.5, Vector3(0.1, h, 0.08), basis, 0.0)
	# Lintel with its rafter ends, then the awning hanging from it.
	lm.box("Maroon", c + Vector3(0, h * 0.5 + 0.2, 0) + n * 0.3, Vector3(w + 0.9, 0.3, 0.6), basis, 0.0)
	var a0 := c + Vector3(0, h * 0.5 + 0.05, 0) + n * 0.55
	var a1 := c + Vector3(0, h * 0.5 - 0.55, 0) + n * 0.9
	lm.quad(wall, a0 - r * (w * 0.5 + 0.3), a0 + r * (w * 0.5 + 0.3), a1 + r * (w * 0.5 + 0.2), a1 - r * (w * 0.5 + 0.2),
		(n + Vector3.UP).normalized())
	lm.quad("Shadow", a1 - r * (w * 0.5 + 0.2), a1 + r * (w * 0.5 + 0.2), a1 + r * (w * 0.5 + 0.2) + Vector3(0, -0.12, 0),
		a1 - r * (w * 0.5 + 0.2) + Vector3(0, -0.12, 0), n)

## Maroon penbe frieze (stacked tamarisk twigs) round a block of plan
## `size` at height y, `h` tall, studded with gilt mirrors, a white
## coping above.
static func _penbe(lm: LandmarkMesh, base: Vector3, size: Vector2, h: float) -> void:
	lm.box("Maroon", base + Vector3(0, h * 0.5, 0), Vector3(size.x, h, size.y))
	lm.box("White", base + Vector3(0, h + 0.2, 0), Vector3(size.x + 0.6, 0.4, size.y + 0.6))
	var n := int(size.x / 9.0)
	for i in n:
		var x := base.x + size.x * ((float(i) + 0.5) / float(n) - 0.5)
		lm.disc("Gold", Vector3(x, base.y + h * 0.5, base.z + size.y * 0.5 + 0.03), Vector3.BACK, minf(h * 0.3, 1.1), 16)

## Gilt victory banner (gyaltsen) standing on a roof or parapet at
## `base`, `h` tall.
static func _banner(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.lathe("Gold", base, PackedVector2Array([Vector2(h * 0.18, 0), Vector2(h * 0.3, h * 0.12),
		Vector2(h * 0.3, h * 0.55), Vector2(h * 0.36, h * 0.62), Vector2(h * 0.2, h * 0.7),
		Vector2(h * 0.14, h * 0.85), Vector2(0.02, h)]), 12)

## Whitewashed zigzag stairways climbing the south face of the plinth.
static func _stairs(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var pts := [Vector2(150.0, 0.0), Vector2(96.0, 15.0), Vector2(130.0, 30.0), Vector2(70.0, 44.0)]
		for i in pts.size() - 1:
			var p: Vector2 = pts[i]
			var q: Vector2 = pts[i + 1]
			var a := Vector3(s * p.x, p.y + 1.2, lerpf(33.0, 29.0, p.y / 45.0) + 1.4)
			var b := Vector3(s * q.x, q.y + 1.2, lerpf(33.0, 29.0, q.y / 45.0) + 1.4)
			lm.beam("White", a, b, 2.2, 3.0, Vector3.UP)
			lm.beam("Maroon", a + Vector3(0, 1.15, 0.4), b + Vector3(0, 1.15, 0.4), 0.3, 2.4, Vector3.UP)
