class_name LandmarkWestminsterRanges
extends RefCounted

## The ranges of the Palace of Westminster (Barry and Pugin, 1840-70)
## round its eleven courts, built from LandmarkWestminsterPlan: slate
## roofs with iron cresting and chimney stacks, and on every exposed
## wall face a skin of real window openings (three storeys of mullioned
## lights), a panelled parapet and, along the outer fronts, a pinnacled
## octagonal turret at every bay. Faces that look into a court get the
## windows and parapet only. The river front takes the east edge.

const CELL := 2.0
const MIN_SIDE := 4.0
const TURRET_R := 0.5
const GRID_X0 := -90.0
const GRID_Z0 := -20.0
const GRID_W := 90
const GRID_H := 160

static func build(lm: LandmarkMesh) -> void:
	var rects := _rects()
	var grid := _occupancy(LandmarkWestminsterPlan.solids())
	var outer := _flood(grid)
	for r in rects:
		var rr: Rect2 = r[0]
		var h: float = r[1]
		if minf(rr.size.x, rr.size.y) < MIN_SIDE:
			lm.box("Palace", Vector3(rr.get_center().x, minf(h, 20.0) * 0.5, rr.get_center().y),
				Vector3(rr.size.x, minf(h, 20.0), rr.size.y), Basis(), 0.0)
			continue
		lm.box("Palace", Vector3(rr.get_center().x, h * 0.5, rr.get_center().y), Vector3(rr.size.x, h, rr.size.y),
			Basis(), 0.0)
		_roof(lm, rr, h)
		_faces(lm, rr, h, grid, outer)
	_pavilions(lm)

static func _rects() -> Array:
	var out: Array = []
	var d := LandmarkWestminsterPlan.RANGES
	for i in range(0, d.size(), 5):
		out.append([Rect2(d[i], d[i + 1], d[i + 2] - d[i], d[i + 3] - d[i + 1]), d[i + 4]])
	return out

static func _cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor((p.x - GRID_X0) / CELL)), int(floor((p.y - GRID_Z0) / CELL)))

static func _occupancy(solids: Array[Rect2]) -> PackedByteArray:
	var g := PackedByteArray()
	g.resize(GRID_W * GRID_H)
	for s in solids:
		var a := _cell(s.position + Vector2(0.1, 0.1))
		var b := _cell(s.end - Vector2(0.1, 0.1))
		for j in range(maxi(a.y, 0), mini(b.y, GRID_H - 1) + 1):
			for i in range(maxi(a.x, 0), mini(b.x, GRID_W - 1) + 1):
				g[j * GRID_W + i] = 1
	return g

## Empty cells reachable from the grid border (the streets and gardens);
## the rest are courts.
static func _flood(grid: PackedByteArray) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(GRID_W * GRID_H)
	var stack: Array[Vector2i] = [Vector2i(0, 0)]
	seen[0] = 1
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= GRID_W or n.y >= GRID_H:
				continue
			var k := n.y * GRID_W + n.x
			if seen[k] == 0 and grid[k] == 0:
				seen[k] = 1
				stack.append(n)
	return seen

## 1 for open ground reached from outside, 0 for a court, -1 for solid.
static func _kind(p: Vector2, grid: PackedByteArray, outer: PackedByteArray) -> int:
	var c := _cell(p)
	if c.x < 0 or c.y < 0 or c.x >= GRID_W or c.y >= GRID_H:
		return 1
	var k := c.y * GRID_W + c.x
	if grid[k] == 1:
		return -1
	return 1 if outer[k] == 1 else 0

## Pitched slate roof over a range, ridge along its long side, with
## cresting and chimney stacks; the narrow ones get a flat leads roof.
static func _roof(lm: LandmarkMesh, r: Rect2, h: float) -> void:
	var c := r.get_center()
	var short := minf(r.size.x, r.size.y)
	if short < 9.0:
		lm.box("Roof", Vector3(c.x, h + 0.2, c.y), Vector3(r.size.x, 0.4, r.size.y), Basis(), 0.0)
		return
	var along_x := r.size.x > r.size.y
	var basis := Basis(Vector3.UP, PI * 0.5) if along_x else Basis()
	var w := r.size.y if along_x else r.size.x
	var l := r.size.x if along_x else r.size.y
	var rise := clampf(w * 0.34, 3.0, 8.0)
	lm.gable("Roof", Vector3(c.x, h, c.y), w - 0.4, l - 0.4, rise, basis, 0.3, "Palace")
	lm.box("Iron", Vector3(c.x, h + rise + 0.3, c.y), Vector3(l - 0.4, 0.6, 0.18) if along_x else Vector3(0.18, 0.6, l - 0.4),
		Basis(), 0.0)
	var n := int(l / 16.0)
	for k in n:
		var t := (float(k) + 0.5) / float(n) - 0.5
		var s := -1.0 if k % 2 == 0 else 1.0
		var off := basis * Vector3(s * w * 0.18, 0, t * l)
		var base := Vector3(c.x + off.x, h + rise * 0.62, c.y + off.z)
		lm.box("Palace", base + Vector3(0, 2.2, 0), Vector3(1.6, 4.4, 2.2), basis, 0.0)
		lm.box("Palace", base + Vector3(0, 4.55, 0), Vector3(1.9, 0.3, 2.5), basis, 0.0)
		for kk in 2:
			lm.frustum("Roof", base + basis * Vector3(0, 4.7, -0.5 + float(kk)), 0.22, 0.2, 0.9, 6)

## Faces of the range: step along each side, group the stretches that
## look onto open ground or a court, and dress each one.
static func _faces(lm: LandmarkMesh, r: Rect2, h: float, grid: PackedByteArray, outer: PackedByteArray) -> void:
	# [start, along (viewer's right, UP x out), outward normal, side length]
	var sides := [
		[Vector2(r.end.x, r.position.y), Vector2(-1, 0), Vector2(0, -1), r.size.x],
		[Vector2(r.end.x, r.end.y), Vector2(0, -1), Vector2(1, 0), r.size.y],
		[Vector2(r.position.x, r.end.y), Vector2(1, 0), Vector2(0, 1), r.size.x],
		[Vector2(r.position.x, r.position.y), Vector2(0, 1), Vector2(-1, 0), r.size.y],
	]
	for s in sides:
		var p0: Vector2 = s[0]
		var t: Vector2 = s[1]
		var n: Vector2 = s[2]
		var length: float = s[3]
		var step := 1.0
		var count := int(length / step)
		var run_start := -1
		var run_kind := -1
		for i in count + 1:
			var kind := -1
			if i < count:
				kind = _kind(p0 + t * (float(i) + 0.5) * step + n * 1.0, grid, outer)
			if kind != run_kind:
				if run_kind >= 0 and float(i - run_start) * step >= 3.5:
					_face(lm, p0 + t * float(run_start) * step, t, n, float(i - run_start) * step, h, run_kind == 1)
				run_start = i
				run_kind = kind

## One exposed stretch from `a` along `t` (viewer's left to right looking
## at the face), facing `n`, `len` long.
static func _face(lm: LandmarkMesh, a: Vector2, t: Vector2, n: Vector2, length: float, h: float, outer: bool) -> void:
	var out := Vector3(n.x, 0, n.y)
	var right := Vector3(t.x, 0, t.y)
	var origin := Vector3(a.x, 0, a.y)
	var bays := maxi(int(round(length / 3.9)), 1)
	var rows := 4 if h >= 28.0 else 3
	var storey := 6.9 if h >= 24.0 else 5.8
	var win := Vector2(2.3, 4.1) if h >= 24.0 else Vector2(2.1, 3.5)
	LandmarkDetail.pierced_face(lm, "Palace", "Windows", origin, right, out, length, h, bays, rows, win,
		2.3 if h >= 24.0 else 1.9, storey, 0.45)
	var pitch := length / float(bays)
	if outer:
		for b in bays:
			var x := pitch * (float(b) + 0.5)
			for row in rows:
				var y := (2.3 if h >= 24.0 else 1.9) + storey * float(row)
				if y + win.y > h - 0.05:
					continue
				var c := origin + right * x + out * 0.5 + Vector3(0, y + win.y * 0.5, 0)
				lm.box("Palace", c, Vector3(0.14, win.y, 0.1) if absf(out.x) < 0.5 else Vector3(0.1, win.y, 0.14),
					Basis(), 0.0)
	_parapet(lm, origin + Vector3(0, h, 0) + out * 0.2, right, out, length, pitch)
	if not outer:
		return
	for b in bays + 1:
		_turret(lm, origin + right * pitch * float(b) + out * 0.5, h)

## Panelled parapet with a pier at every bay (flat-sided boxes: it runs
## for hundreds of metres).
static func _parapet(lm: LandmarkMesh, a: Vector3, right: Vector3, out: Vector3, length: float, pitch: float) -> void:
	var basis := Basis(right, Vector3.UP, out)
	var c := a + right * length * 0.5
	lm.box("Palace", c + Vector3(0, 0.55, 0), Vector3(length, 1.1, 0.5), basis, 0.0)
	lm.box("Palace", c + Vector3(0, 1.2, 0) + out * 0.05, Vector3(length + 0.1, 0.2, 0.75), basis, 0.0)
	var n := maxi(int(round(length / pitch)), 1)
	for i in n + 1:
		lm.box("Palace", a + right * pitch * float(i) + Vector3(0, 0.9, 0), Vector3(0.5, 1.8, 0.7), basis, 0.0)

## Octagonal turret shaft rising past the parapet to a slim stone spirelet.
static func _turret(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.frustum("Palace", base, TURRET_R + 0.05, TURRET_R, h + 1.6, 8, PI / 8.0)
	lm.spire("Palace", base + Vector3(0, h + 1.6, 0), 0.62, 3.8, 0.0, 4)

## Corner and river-front pavilions: a storey taller, under steep
## pyramidal slate roofs with iron cresting and gilt finials.
static func _pavilions(lm: LandmarkMesh) -> void:
	var d := LandmarkWestminsterPlan.PAVILIONS
	for i in range(0, d.size(), 5):
		var c := Vector3(d[i], 0, d[i + 1])
		var hw: float = d[i + 2]
		var wh: float = d[i + 3]
		var rise: float = d[i + 4]
		lm.box("Palace", c + Vector3(0, wh * 0.5, 0), Vector3(hw * 2.0, wh, hw * 2.0), Basis(), 0.0)
		lm.box("Palace", c + Vector3(0, wh + 0.4, 0), Vector3(hw * 2.0 + 0.8, 0.8, hw * 2.0 + 0.8), Basis(), 0.0)
		lm.spire("Roof", c + Vector3(0, wh + 0.8, 0), hw + 0.2, rise, 0.5)
		lm.frustum("Gilt", c + Vector3(0, wh + 0.8 + rise, 0), 0.12, 0.05, 2.2, 6)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p := c + Vector3(float(sx) * hw, 0, float(sz) * hw)
				lm.frustum("Palace", p, 0.8, 0.7, wh + 1.5, 8, PI / 8.0)
				lm.spire("Palace", p + Vector3(0, wh + 1.5, 0), 0.85, 5.0, 0.0, 4)
