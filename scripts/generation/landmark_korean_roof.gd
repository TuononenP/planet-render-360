class_name LandmarkKoreanRoof
extends RefCounted

## Joseon timber-hall kit shared by Gwanghwamun, Heungnyemun, Geunjeongmun
## and Geunjeongjeon, in true metres on LandmarkMesh: round red columns on
## granite bases, paper-backed lattice doors, dancheong bracket sets
## (dapo), twin rafter layers, concave tiled roofs with upswept corners,
## hip ridges carrying japsang figures, and the main ridge with its chimi
## ridge-end ornaments. Every piece is built about the hall's centre on
## the surface keys of `materials`. `bays` is the column grid (front x
## side); the default 3 x 2 is the gatehouse plan.

## The kit's surface keys: Granite, Timber, Dancheong, Tiles, Shadow and
## Plaster.
static func materials(lm: LandmarkMesh) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B4ADA2", 3.0))
	lm.use("Timber", LandmarkMaterials.paint("#8E2B20", 0.7, 0.0))
	lm.use("Dancheong", LandmarkMaterials.paint("#3F7A66", 0.65, 0.0))
	lm.use("Tiles", LandmarkMaterials.pbr("slate", "#4A4E52", 1.5))
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E8E2D6", 3.0))

## A two-storey gate pavilion (junggak) standing at y1: the lower storey
## of `low` columns `low_h` tall under its skirt roof, the upper storey of
## `up` columns `up_h` tall under the hipped-and-gabled roof whose chimi
## reach `top_m`.
static func two_storey(lm: LandmarkMesh, y1: float, low: Vector2, up: Vector2, low_h: float, up_h: float,
		top_m: float, bays: Vector2i = Vector2i(3, 2)) -> void:
	# Lower storey: red columns round a plastered core with lattice doors.
	lm.box("Plaster", Vector3(0, y1 + (low_h - 0.2) * 0.5, 0), Vector3(low.x - 1.0, low_h - 0.2, low.y - 1.0))
	columns(lm, y1, low, low_h, 0.34, bays)
	lattice(lm, y1, low, low_h - 0.4, bays)
	brackets(lm, y1 + low_h, low, 3, bays)
	# Skirt roof round the lower storey.
	rafters(lm, y1 + low_h + 0.9, low + Vector2(1.6, 1.6), 2.0)
	roof(lm, y1 + low_h + 0.9, low + Vector2(5.0, 5.0), low + Vector2(-1.0, -1.0), 1.4, false)
	# Upper storey: columns, lattice wall and the hipped-and-gabled roof.
	var y2 := y1 + low_h + 1.6
	lm.box("Timber", Vector3(0, y2 + 0.2, 0), Vector3(up.x + 0.6, 0.4, up.y + 0.6))
	lm.box("Plaster", Vector3(0, y2 + up_h * 0.5, 0), Vector3(up.x - 0.6, up_h, up.y - 0.6))
	columns(lm, y2, up, up_h, 0.28, bays)
	lattice(lm, y2 + 0.2, up, up_h - 0.4, bays)
	brackets(lm, y2 + up_h, up, 3, bays)
	var ridge_y := top_m - 1.2
	var eave_y := y2 + up_h + 0.7
	rafters(lm, eave_y, up + Vector2(1.6, 1.6), 2.6)
	var eave := up + Vector2(6.6, 6.0)
	var top := Vector2(up.x * 0.62, 0.8)
	roof(lm, eave_y, eave, top, ridge_y - eave_y, true)
	hips(lm, eave_y, eave, top, ridge_y - eave_y)
	ridge(lm, ridge_y, top.x, top_m)

## A single-storey gate or hall of `size` columns `h` tall standing at y,
## under a hipped-and-gabled roof whose chimi reach `top_m`.
static func one_storey(lm: LandmarkMesh, y: float, size: Vector2, h: float, top_m: float,
		bays: Vector2i = Vector2i(3, 2)) -> void:
	lm.box("Plaster", Vector3(0, y + (h - 0.2) * 0.5, 0), Vector3(size.x - 1.0, h - 0.2, size.y - 1.0))
	columns(lm, y, size, h, 0.3, bays)
	brackets(lm, y + h, size, 1, bays)
	var eave_y := y + h + 0.9
	rafters(lm, eave_y, size + Vector2(1.6, 1.6), 1.8)
	var eave := size + Vector2(4.4, 4.0)
	var top := Vector2(size.x * 0.6, 0.6)
	var ridge_y := top_m - 1.2
	roof(lm, eave_y, eave, top, ridge_y - eave_y, true)
	hips(lm, eave_y, eave, top, ridge_y - eave_y)
	ridge(lm, ridge_y, top.x, top_m)

## Appends every surface of `src` (built about its own centre) to the same
## keys of `dst`, turned by `basis` and moved to `at`: how a composite
## (a throne hall and its cloister gates) places kit buildings that are
## each built about the origin. `dst` must use every key `src` does.
static func place(dst: LandmarkMesh, src: LandmarkMesh, at: Vector3, basis: Basis = Basis()) -> void:
	for key in src._order:
		var s: LandmarkMesh.Surf = src._surfs[key]
		var d: LandmarkMesh.Surf = dst._surfs[key]
		for i in s.v.size():
			d.v.append(at + basis * s.v[i])
			d.n.append(basis * s.n[i])
		d.uv.append_array(s.uv)

## Main ridge at ridge_y over a `top_x` long ridge, its tiled flanks and
## the chimi ridge-end ornaments rising to `top_m`.
static func ridge(lm: LandmarkMesh, ridge_y: float, top_x: float, top_m: float) -> void:
	lm.box("Tiles", Vector3(0, ridge_y + 0.4, 0), Vector3(top_x + 1.0, 0.8, 0.9))
	lm.box("Plaster", Vector3(0, ridge_y + 0.05, 0), Vector3(top_x + 0.8, 0.12, 1.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var e := Vector3(s * (top_x * 0.5 + 0.6), ridge_y, 0)
		lm.box("Tiles", e + Vector3(0, 0.6, 0), Vector3(0.8, top_m - ridge_y, 0.9))
		lm.box("Tiles", e + Vector3(-s * 0.4, top_m - ridge_y - 0.3, 0), Vector3(0.6, 0.6, 0.6))
		lm.beam("Tiles", e + Vector3(s * 0.3, top_m - ridge_y - 0.6, 0), e + Vector3(s * 0.7, top_m - ridge_y - 0.1, 0), 0.3, 0.5)

## Round red columns on stone bases round a `size` rectangle: the
## (bays.x + 1) x (bays.y + 1) grid, with the interior ones left out.
static func columns(lm: LandmarkMesh, y: float, size: Vector2, h: float, r: float,
		bays: Vector2i = Vector2i(3, 2)) -> void:
	for i in bays.x + 1:
		for j in bays.y + 1:
			if j > 0 and j < bays.y and i > 0 and i < bays.x:
				continue
			var p := Vector3(-size.x * 0.5 + size.x * i / float(bays.x), y, -size.y * 0.5 + size.y * j / float(bays.y))
			lm.frustum("Granite", p, r * 1.5, r * 1.3, 0.25, 8)
			lm.lathe("Timber", p + Vector3(0, 0.25, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 1.04, h * 0.35),
				Vector2(r * 0.9, h - 0.25)]), 12)

## Lattice doors in each bay: a frame and a grid of thin muntins over
## the plaster (paper-backed changhoji), each bay split into four leaves.
static func lattice(lm: LandmarkMesh, y: float, size: Vector2, h: float, bays: Vector2i = Vector2i(3, 2)) -> void:
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var depth := (size.y if side % 2 == 0 else size.x) * 0.5 - 0.45
		var n_bays := bays.x if side % 2 == 0 else bays.y
		for b in n_bays:
			var x0 := -span * 0.5 + span * b / n_bays + 0.4
			var x1 := -span * 0.5 + span * (b + 1) / n_bays - 0.4
			var cx := (x0 + x1) * 0.5
			var w := x1 - x0
			lm.box("Timber", r * Vector3(cx, y + 0.25, depth), Vector3(w, 0.3, 0.12), r, 0.0)
			lm.box("Timber", r * Vector3(cx, y + h - 0.15, depth), Vector3(w, 0.3, 0.12), r, 0.0)
			for k in 5:
				lm.box("Timber", r * Vector3(x0 + w * k / 4.0, y + h * 0.5, depth), Vector3(0.12, h, 0.12), r, 0.0)
			var rows := int(h / 0.35)
			for k in range(1, rows):
				lm.box("Timber", r * Vector3(cx, y + 0.4 + (h - 0.55) * k / rows, depth + 0.02),
					Vector3(w, 0.05, 0.04), r, 0.0)
			for k in range(1, int(w / 0.35)):
				lm.box("Timber", r * Vector3(x0 + k * 0.35, y + h * 0.5, depth + 0.02), Vector3(0.05, h - 0.5, 0.04),
					r, 0.0)

## Dancheong bracket band under an eave: the painted beam, then bracket
## sets (dapo) on and between the columns, each three tiers of red
## bearing blocks and green arms stepping outward.
static func brackets(lm: LandmarkMesh, y: float, size: Vector2, between: int, bays: Vector2i = Vector2i(3, 2)) -> void:
	lm.box("Timber", Vector3(0, y + 0.15, 0), Vector3(size.x + 0.6, 0.3, size.y + 0.6))
	lm.box("Dancheong", Vector3(0, y + 0.45, 0), Vector3(size.x + 0.4, 0.3, size.y + 0.4))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var depth := (size.y if side % 2 == 0 else size.x) * 0.5
		var n_bays := bays.x if side % 2 == 0 else bays.y
		var sets := n_bays * (between + 1)
		for k in sets + 1:
			var x := -span * 0.5 + span * k / sets
			for t in 3:
				var reach := 0.3 + 0.35 * t
				lm.box("Timber", r * Vector3(x, y + 0.7 + 0.25 * t, depth + reach - 0.1), Vector3(0.3, 0.14, 0.3), r, 0.0)
				lm.box("Dancheong", r * Vector3(x, y + 0.82 + 0.25 * t, depth + reach * 0.5),
					Vector3(0.18, 0.12, reach + 0.2), r, 0.0)
				lm.box("Dancheong", r * Vector3(x, y + 0.82 + 0.25 * t, depth + reach - 0.1),
					Vector3(0.9 + 0.2 * t, 0.12, 0.16), r, 0.0)
	lm.box("Dancheong", Vector3(0, y + 1.5, 0), Vector3(size.x + 2.2, 0.2, size.y + 2.2))

## Two rafter layers under an eave round a `size` rectangle: round
## rafters (seokkarae) every 0.45 m and the square flying rafters
## (buyeon) above them reaching further out, all `reach` long.
static func rafters(lm: LandmarkMesh, y: float, size: Vector2, reach: float) -> void:
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var depth := (size.y if side % 2 == 0 else size.x) * 0.5
		var n := int(span / 0.45)
		for k in n:
			var x := -span * 0.5 + span * (k + 0.5) / n
			lm.beam("Timber", r * Vector3(x, y - 0.35, depth - 0.2), r * Vector3(x, y - 0.05, depth + reach * 0.75),
				0.16, 0.16)
			lm.beam("Dancheong", r * Vector3(x, y - 0.12, depth + reach * 0.6), r * Vector3(x, y + 0.02, depth + reach),
				0.13, 0.13)

## Concave hipped roof from an eave rectangle `eave` up to a ridge
## rectangle `top` (a point-like top when tiny), `rise` high, with
## upswept corners and tile rows (sugiwa ribs) down every slope;
## `gabled` closes the ridge ends with gable boards.
static func roof(lm: LandmarkMesh, y: float, eave: Vector2, top: Vector2, rise: float,
		gabled: bool) -> void:
	var rows: Array = []
	for k in 7:
		var t := float(k) / 6.0
		# Concave slope: steep near the ridge, flattening to the eave.
		var f := 1.0 - pow(1.0 - t, 1.8)
		var hx := lerpf(eave.x * 0.5, top.x * 0.5, f)
		var hz := lerpf(eave.y * 0.5, top.y * 0.5, f)
		var lift := (1.0 - t) * (1.0 - t) * 0.9
		var yy := y + rise * t
		var ring: Array = []
		for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			var cv := c as Vector2
			ring.append(Vector3(cv.x * hx, yy + lift, cv.y * hz))
		rows.append(ring)
	# Four slopes between consecutive corners, each a grid strip facing
	# away from a point deep under the roof.
	var res := 12
	for side in 4:
		var strip: Array = []
		for k in rows.size():
			var r := rows[k] as Array
			var a: Vector3 = r[side]
			var b: Vector3 = r[side + 1]
			var line := PackedVector3Array()
			for q in res + 1:
				var p := a.lerp(b, float(q) / res)
				line.append(p + Vector3(0, sweep(float(q) / res, float(k) / 6.0), 0))
			strip.append(line)
		lm.grid("Tiles", strip, Vector3(0, y - 50.0, 0), true)
		# Tile rows: a convex roll every 0.55 m down the slope, from the
		# eave line up toward the top.
		var e0: Vector3 = (rows[0] as Array)[side]
		var e1: Vector3 = (rows[0] as Array)[side + 1]
		var n_rows := int(e0.distance_to(e1) / 0.55)
		for q in range(1, n_rows):
			var u := float(q) / n_rows
			var prev := Vector3.ZERO
			for k in rows.size():
				var a: Vector3 = (rows[k] as Array)[side]
				var b: Vector3 = (rows[k] as Array)[side + 1]
				var mid_t := 0.5 + (u - 0.5) * a.distance_to(b) / maxf(e0.distance_to(e1), 0.01)
				if mid_t < 0.02 or mid_t > 0.98:
					prev = Vector3.ZERO
					continue
				var p := a.lerp(b, mid_t) + Vector3(0, sweep(mid_t, float(k) / 6.0) + 0.08, 0)
				if prev != Vector3.ZERO:
					lm.beam("Tiles", prev, p, 0.16, 0.12)
				prev = p
	var last: Array = rows[rows.size() - 1]
	var cap := PackedVector2Array()
	for i in 4:
		var v: Vector3 = last[i]
		cap.append(Vector2(v.x, v.z))
	lm.poly_prism("Tiles", cap, (last[0] as Vector3).y - 0.2, (last[0] as Vector3).y)
	if gabled:
		for s in [-1.0, 1.0]:
			var v0: Vector3 = last[0]
			lm.box("Timber", Vector3(s * absf(v0.x), v0.y + 0.4, 0), Vector3(0.2, 0.8, absf(v0.z) * 2.0 + 0.6))

## Corner upsweep of a roof slope at u along the eave (0..1) and t up
## the slope (0 eave, 1 top).
static func sweep(u: float, t: float) -> float:
	var edge := absf(u - 0.5) * 2.0
	return pow(edge, 3.0) * 0.6 * (1.0 - t)

## Hip ridges from the four upswept eave corners to the ridge ends, each
## with a row of japsang guardian figures near its foot.
static func hips(lm: LandmarkMesh, y: float, eave: Vector2, top: Vector2, rise: float) -> void:
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var cv := c as Vector2
		var prev := Vector3.ZERO
		for k in 7:
			var t := float(k) / 6.0
			var f := 1.0 - pow(1.0 - t, 1.8)
			var p := Vector3(cv.x * lerpf(eave.x * 0.5, top.x * 0.5, f), y + rise * t + (1.0 - t) * (1.0 - t) * 0.9
				+ 0.6 * (1.0 - t) + 0.3, cv.y * lerpf(eave.y * 0.5, top.y * 0.5, f))
			if k > 0:
				lm.beam("Tiles", prev, p, 0.55, 0.5)
				if k >= 1 and k <= 3:
					for m in 2:
						var q := prev.lerp(p, 0.3 + 0.4 * m)
						lm.box("Tiles", q + Vector3(0, 0.38, 0), Vector3(0.22, 0.32, 0.22), Basis(), 0.0)
						lm.box("Tiles", q + Vector3(0, 0.6, 0), Vector3(0.16, 0.14, 0.16), Basis(), 0.0)
			prev = p
