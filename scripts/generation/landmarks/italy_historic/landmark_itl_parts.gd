class_name LandmarkItlParts
extends RefCounted

## Medieval and classical wall details shared by the Italian historic
## builders (true metres on LandmarkMesh): light columns for long
## colonnades, pointed and round framed windows (Gothic bifore and
## trifore with colonnettes), hanging-arch corbel friezes, quoins and
## rusticated piers, putlog-hole grids and a low railing. Openings are
## framed proud of the wall with a dark back so they read recessed.

## Light column for long runs: square plinth, torus base, tapered shaft,
## echinus and abacus; ~150 triangles. `seg` sides on the shaft.
static func column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 10,
		plinth: bool = true) -> void:
	var y := 0.0
	if plinth:
		lm.box(key, base + Vector3(0, r * 0.25, 0), Vector3(r * 2.6, r * 0.5, r * 2.6), Basis(), 0.0)
		y = r * 0.5
	lm.lathe(key, base + Vector3(0, y, 0), PackedVector2Array([Vector2(r * 1.25, 0), Vector2(r * 1.25, r * 0.2),
		Vector2(r * 1.05, r * 0.35), Vector2(r, r * 0.45)]), seg, 1.0, 1.0, 0.0, true, false)
	var sh := h - y - r * 1.25
	lm.lathe(key, base + Vector3(0, y + r * 0.45, 0), PackedVector2Array([Vector2(r, 0),
		Vector2(r * 0.97, sh * 0.5), Vector2(r * 0.86, sh - r * 0.45)]), seg, 1.0, 1.0, 0.0, true, false)
	var cy := base + Vector3(0, h - r * 0.8, 0)
	lm.lathe(key, cy - Vector3(0, r * 0.45, 0), PackedVector2Array([Vector2(r * 0.86, 0), Vector2(r * 0.95, r * 0.12),
		Vector2(r * 0.88, r * 0.24), Vector2(r * 1.0, r * 0.6), Vector2(r * 1.3, r * 0.85)]), seg, 1.0, 1.0, 0.0,
		true, false)
	lm.box(key, cy + Vector3(0, r * 0.6, 0), Vector3(r * 2.7, r * 0.4, r * 2.7), Basis(), 0.0)

## Points of an arch (pointed when `pointed`, else round) springing at
## `c` (centre of the springing line), half-span hw, `steps` segments
## from the left springer to the right one.
static func arch_pts(c: Vector3, right: Vector3, hw: float, pointed: bool, steps: int = 8) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for k in steps + 1:
		var t := float(k) / float(steps)
		if pointed:
			# Two arcs of radius 2 hw (equilateral pointed arch).
			var left_half := t <= 0.5
			var s := t * 2.0 if left_half else (1.0 - t) * 2.0
			var phi := PI / 3.0 * s
			var x := -hw + hw * 2.0 * (1.0 - cos(phi))
			var yv := hw * 2.0 * sin(phi)
			pts.append(c + right * (x if left_half else -x) + Vector3.UP * yv)
		else:
			var a := PI * (1.0 - t)
			pts.append(c + right * cos(a) * hw + Vector3.UP * sin(a) * hw)
	return pts

## A framed Gothic window on a wall face: `o` bottom centre on the face,
## `out` the face normal, opening w x h (h to the arch apex), `lights`
## lights split by colonnettes under small sub-arches, a moulded outer
## archivolt and a sill. Dark back panel on the face, frame `depth` proud.
static func gothic_window(lm: LandmarkMesh, frame: String, dark: String, o: Vector3, out: Vector3, w: float,
		h: float, lights: int = 2, pointed: bool = true, depth: float = 0.25, band: float = -1.0) -> void:
	var n := out.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var hw := w * 0.5
	var rise := w * 0.866 if pointed else hw
	var spring := maxf(h - rise, 0.2)
	var bw := band if band > 0.0 else clampf(w * 0.1, 0.12, 0.5)
	var c := o + Vector3.UP * spring + n * 0.03
	# Dark back: rectangle plus the arch fan.
	lm.quad(dark, o - r * hw + n * 0.03, o + r * hw + n * 0.03, c + r * hw, c - r * hw, n)
	var ap := arch_pts(c, r, hw, pointed, 8)
	for k in ap.size() - 1:
		lm.tri(dark, c, ap[k], ap[k + 1], n, n, n, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
	var basis := Basis(r, Vector3.UP, n)
	var fc := o + n * depth * 0.5
	# Jambs, archivolt, sill.
	for s in [-1.0, 1.0]:
		lm.box(frame, fc + r * (hw + bw * 0.5) * float(s) + Vector3(0, spring * 0.5, 0), Vector3(bw, spring, depth),
			basis, 0.0)
	var arc := arch_pts(o + Vector3.UP * spring + n * depth * 0.5, r, hw + bw * 0.5, pointed, 8)
	for k in arc.size() - 1:
		lm.beam(frame, arc[k], arc[k + 1], depth, bw, n)
	# Sill (doorways standing on the ground get none).
	if o.y >= bw * 0.6:
		lm.box(frame, fc + n * depth * 0.2 - Vector3(0, bw * 0.3, 0), Vector3(w + bw * 3.0, bw * 0.6, depth * 1.3),
			basis, 0.0)
	if lights < 2:
		return
	# Colonnettes and the small sub-arches of each light.
	var lw := w / float(lights)
	var cr := clampf(lw * 0.07, 0.05, 0.18)
	var sub_spring := spring - (lw * 0.433 if pointed else lw * 0.25)
	for i in range(1, lights):
		var p := o + r * (-hw + lw * float(i)) + n * depth * 0.5
		lm.frustum(frame, p, cr, cr * 0.9, sub_spring, 6)
		lm.box(frame, p + Vector3(0, sub_spring, 0), Vector3(cr * 3.0, cr * 1.2, cr * 3.0), basis, 0.0)
	for i in lights:
		var sc := o + r * (-hw + lw * (float(i) + 0.5)) + Vector3.UP * sub_spring + n * depth * 0.5
		var sp := arch_pts(sc, r, lw * 0.5, pointed, 6)
		for k in sp.size() - 1:
			lm.beam(frame, sp[k], sp[k + 1], depth * 0.6, cr * 1.6, n)
	# Tympanum oculus over the lights.
	if h - sub_spring > w * 0.6:
		lm.disc(frame, o + Vector3.UP * (spring + rise * 0.35) + n * depth * 0.5, n, minf(hw * 0.32, rise * 0.25), 10)

## Hanging-arch (archetti pensili) frieze along a..b on a wall face at
## the height of a/b: small corbels every `pitch` with round (or pointed)
## arches between them, `out` the face normal.
static func arch_frieze(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, pitch: float,
		drop: float, pointed: bool = false) -> void:
	var n := out.normalized()
	var d := b - a
	var count := maxi(int(round(d.length() / pitch)), 1)
	var r := d.normalized()
	var step := d.length() / float(count)
	var bw := clampf(pitch * 0.14, 0.1, 0.4)
	var basis := Basis(r, Vector3.UP, n)
	for i in count + 1:
		var p := a + r * step * float(i)
		lm.box(key, p + n * bw * 0.6 - Vector3(0, drop * 0.5, 0), Vector3(bw * 1.2, drop, bw * 1.2), basis, 0.0)
	for i in count:
		var c := a + r * step * (float(i) + 0.5) - Vector3(0, drop * 0.55, 0) + n * bw * 0.5
		var hw := step * 0.5 - bw * 0.6
		var pts := arch_pts(c, r, hw, pointed, 5)
		for k in pts.size() - 1:
			lm.beam(key, pts[k], pts[k + 1], bw, bw, n)
	lm.box(key, (a + b) * 0.5 + n * bw * 0.7 + Vector3(0, bw * 0.4, 0), Vector3(d.length() + bw * 2.0, bw * 0.8,
		bw * 1.6), basis, 0.0)

## Quoins up a building corner at `p` (corner on the ground), the two
## faces running along d1 and d2 (unit, away from the corner): long and
## short blocks alternating every `course`.
static func quoins(lm: LandmarkMesh, key: String, p: Vector3, d1: Vector3, d2: Vector3, y0: float, y1: float,
		course: float, long_m: float = 1.4, proud: float = 0.08) -> void:
	var k := 0
	var y := y0
	while y + course <= y1 + 0.01:
		var a_len := long_m if k % 2 == 0 else long_m * 0.55
		var b_len := long_m * 0.55 if k % 2 == 0 else long_m
		var cy := Vector3(0, y + course * 0.5, 0)
		lm.box(key, p + cy + d1 * (a_len * 0.5) - d2 * proud * 0.5,
			Vector3(a_len, course * 0.92, proud), Basis(d1, Vector3.UP, -d2), 0.0)
		lm.box(key, p + cy + d2 * (b_len * 0.5) - d1 * proud * 0.5,
			Vector3(b_len, course * 0.92, proud), Basis(d2, Vector3.UP, -d1), 0.0)
		y += course
		k += 1

## Grid of small dark putlog holes (scaffold sockets) on a face: `o`
## bottom-left on the face, rows from y0 every `dy`, holes every `dx`.
static func putlogs(lm: LandmarkMesh, dark: String, o: Vector3, right: Vector3, out: Vector3, w: float,
		y0: float, y1: float, dx: float, dy: float, s: float = 0.22) -> void:
	var n := out.normalized()
	var y := y0
	var row := 0
	while y <= y1:
		var x := dx * (0.5 if row % 2 == 0 else 1.0)
		while x < w - dx * 0.3:
			var c := o + right * x + Vector3.UP * y + n * 0.04
			lm.quad(dark, c - right * s * 0.5, c + right * s * 0.5, c + right * s * 0.5 + Vector3.UP * s,
				c - right * s * 0.5 + Vector3.UP * s, n)
			x += dx
		y += dy
		row += 1

## Simple railing along a..b: posts every `pitch`, top rail and mid rail.
static func railing(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, pitch: float,
		bar: float = 0.06) -> void:
	var d := b - a
	var count := maxi(int(round(d.length() / pitch)), 1)
	for i in count + 1:
		var p := a.lerp(b, float(i) / float(count))
		lm.beam(key, p, p + Vector3(0, h, 0), bar, bar)
	lm.beam(key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), bar * 1.4, bar)
	lm.beam(key, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), bar, bar)

## Rusticated pier: a stack of blocks with sunk joints (each course a
## slightly smaller-faced box over a recessed core) on a face.
static func rustic_pier(lm: LandmarkMesh, key: String, base: Vector3, right: Vector3, out: Vector3, w: float,
		h: float, course: float, proud: float = 0.25) -> void:
	var n := out.normalized()
	var basis := Basis(right.normalized(), Vector3.UP, n)
	var count := maxi(int(round(h / course)), 1)
	var ch := h / float(count)
	lm.box(key, base + Vector3(0, h * 0.5, 0) + n * proud * 0.3, Vector3(w * 0.94, h, proud * 0.6), basis, 0.0)
	for i in count:
		lm.box(key, base + Vector3(0, ch * (float(i) + 0.5), 0) + n * proud * 0.5,
			Vector3(w, ch * 0.84, proud), basis)
