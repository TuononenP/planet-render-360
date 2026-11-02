class_name LandmarkGtOttoman
extends RefCounted

## Classical Ottoman parts for the Istanbul landmarks (true metres on
## LandmarkMesh): columns with muqarnas capitals, pointed arches, framed
## pointed windows, small domes on octagonal drums with their alem, and
## minarets with muqarnas-corbelled balconies. Each takes the material
## KEYS to draw with.

## Column of total height h, shaft radius r, at `base`: a moulded base,
## the plain shaft, a ring, the muqarnas (stalactite) capital as three
## corbelled octagonal tiers, and the square impost block.
static func column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float) -> void:
	var cap := r * 2.4
	lm.frustum(key, base, r * 1.45, r * 1.4, r * 0.35, 8, PI / 8.0)
	lm.lathe(key, base + Vector3(0, r * 0.35, 0), PackedVector2Array([Vector2(r * 1.2, 0), Vector2(r * 1.05, r * 0.25),
		Vector2(r, r * 0.4), Vector2(r * 0.93, h - cap - r * 0.35)]), 14)
	var cb := base + Vector3(0, h - cap, 0)
	lm.frustum(key, cb, r * 1.02, r * 1.02, r * 0.18, 14)
	for t in 3:
		var y := r * 0.18 + cap * 0.22 * float(t)
		lm.frustum(key, cb + Vector3(0, y, 0), r * (1.0 + 0.18 * float(t)), r * (1.18 + 0.18 * float(t)), cap * 0.22, 8,
			PI / 8.0 * float(t % 2))
	lm.box(key, base + Vector3(0, h - cap * 0.17, 0), Vector3(r * 3.0, cap * 0.34, r * 3.0))

## Pointed (two-centred) arch from springing point a to b, rising `rise`
## above them: a band of voussoir blocks `band` deep in the wall plane
## and `d` thick across it, with a keystone.
static func pointed_arch(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, rise: float, band: float,
		d: float) -> void:
	var dir := (b - a).normalized()
	var n := dir.cross(Vector3.UP).normalized()
	var pts := arch_points(a, b, rise, 6)
	for i in pts.size() - 1:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var m := (p0 + p1) * 0.5
		var tng := (p1 - p0).normalized()
		var up := n.cross(tng).normalized()
		if up.dot(m - (a + b) * 0.5) < 0.0:
			up = -up
		lm.box(key, m + up * band * 0.5, Vector3(p0.distance_to(p1) + 0.03, band, d), Basis(tng, up, tng.cross(up)), 0.0)
	lm.box(key, (a + b) * 0.5 + Vector3(0, rise + band * 0.55, 0), Vector3(band * 0.5, band * 1.1, d * 1.06),
		Basis(dir, Vector3.UP, n), 0.0)

## Points along a pointed arch a..b of `rise`, `per` points per side
## (springing to apex), each side a circular arc.
static func arch_points(a: Vector3, b: Vector3, rise: float, per: int) -> Array:
	var span := a.distance_to(b)
	var dir := (b - a).normalized()
	var half := span * 0.5
	# Each side is an arc through the springing and the apex, centred on
	# the springing line: radius from the chord.
	var rad := (half * half + rise * rise) / (2.0 * half)
	var out: Array = []
	for side in [0, 1]:
		for i in per + 1:
			if side == 1 and i == 0:
				continue
			var t := float(i) / float(per)
			if side == 1:
				t = 1.0 - t
			var spring: Vector3 = a if side == 0 else b
			var sgn := 1.0 if side == 0 else -1.0
			var ctr := spring + dir * rad * sgn
			var ang := asin(clampf(rise / rad, 0.0, 1.0)) * t
			out.append(ctr - dir * cos(ang) * rad * sgn + Vector3(0, sin(ang) * rad, 0))
	return out

## Pointed-arched window w x h (bottom-centre `c` on the wall face whose
## outward normal is `n`): glass recessed `depth`, stone jambs, the
## pointed arch head and a sill.
static func window(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, normal: Vector3, w: float,
		h: float, depth: float = 0.3) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var bas := Basis(r, Vector3.UP, n)
	var rise := w * 0.62
	var sh := h - rise
	var g := c - n * depth
	lm.quad(glass, g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + Vector3(0, sh, 0), g - r * w * 0.5 + Vector3(0, sh, 0), n)
	var pts := arch_points(g - r * w * 0.5 + Vector3(0, sh, 0), g + r * w * 0.5 + Vector3(0, sh, 0), rise, 4)
	var mid := g + Vector3(0, sh, 0)
	for i in pts.size() - 1:
		lm.tri(glass, mid, pts[i], pts[i + 1], n, n, n, Vector2.ZERO, Vector2(0.5, 0.5), Vector2(1, 0))
	var fw := clampf(w * 0.16, 0.12, 0.45)
	for s in [-1.0, 1.0]:
		lm.box(frame, c + r * (w * 0.5 + fw * 0.5) * float(s) + Vector3(0, sh * 0.5, 0) - n * depth * 0.5 + n * 0.04,
			Vector3(fw, sh, depth + 0.08), bas)
	pointed_arch(lm, frame, c - r * w * 0.5 + Vector3(0, sh, 0) + n * 0.04 - n * depth * 0.5,
		c + r * w * 0.5 + Vector3(0, sh, 0) + n * 0.04 - n * depth * 0.5, rise, fw, depth + 0.08)
	lm.box(frame, c + Vector3(0, -fw * 0.25, 0) - n * depth * 0.4, Vector3(w + fw * 2.4, fw * 0.5, depth + 0.2), bas)
	# Grille bars across the lower light.
	var bar := clampf(w * 0.04, 0.03, 0.08)
	for k in 2:
		lm.box(frame, g + r * w * (float(k) - 0.5) * 0.34 + Vector3(0, sh * 0.5, 0) + n * 0.03, Vector3(bar, sh, bar), bas, 0.0)
	lm.box(frame, g + Vector3(0, sh * 0.5, 0) + n * 0.03, Vector3(w, bar, bar), bas, 0.0)

## Small dome of radius r on a low octagonal drum (`drum_h`) with a
## cornice, set on `base`; a gilt alem on top when `alem` is set.
static func small_dome(lm: LandmarkMesh, wall: String, lead: String, alem: String, base: Vector3, r: float,
		drum_h: float, seg: int = 16) -> void:
	var k := 1.0 / cos(PI / 8.0)
	if drum_h > 0.0:
		lm.frustum(wall, base, r * 1.06 * k, r * 1.04 * k, drum_h, 8, PI / 8.0)
		lm.frustum(wall, base + Vector3(0, drum_h - r * 0.08, 0), r * 1.1 * k, r * 1.1 * k, r * 0.08, 8, PI / 8.0)
	var db := base + Vector3(0, drum_h, 0)
	lm.lathe(lead, db, SEuUtil.dome(r, r * 0.92, 6), seg)
	if alem != "":
		lm.frustum(alem, db + Vector3(0, r * 0.9, 0), r * 0.05, r * 0.03, r * 0.3, 6)
		lm.lathe(alem, db + Vector3(0, r * 1.18, 0), SEuUtil.dome(r * 0.07, r * 0.07, 3), 8)

## Ottoman minaret `h` tall to the finial tip on `base`: square base with
## a moulded transition, a fluted sixteen-sided shaft, balconies at the
## given fractions of h on three tiers of muqarnas corbels with a
## panelled parapet, a slimmer drum above the top balcony, the lead cone
## and the gilt alem. Stone, lead and gilt keys.
static func minaret(lm: LandmarkMesh, stone: String, lead: String, gilt: String, base: Vector3, r: float,
		h: float, balconies: Array) -> void:
	var plinth := h * 0.12
	var cap_h := h * 0.15
	var top := h - cap_h
	lm.box(stone, base + Vector3(0, plinth * 0.5, 0), Vector3(r * 3.0, plinth, r * 3.0))
	lm.box(stone, base + Vector3(0, plinth + r * 0.15, 0), Vector3(r * 3.2, r * 0.3, r * 3.2))
	lm.spire(stone, base + Vector3(0, plinth + r * 0.3, 0), r * 1.5, r * 1.2, r * 1.15, 8)
	var s0 := plinth + r * 1.5
	# Fluted shaft: sixteen sides, each with a shallow flute.
	var rows: Array = []
	for y in [s0, top - r * 2.0]:
		var rr := lerpf(r * 1.12, r * 0.92, (float(y) - s0) / (top - s0))
		var ring := PackedVector3Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			var dd := rr * (1.0 - 0.05 * sin(PI * float(i % 3) / 3.0))
			ring.append(base + Vector3(cos(a) * dd, float(y), sin(a) * dd))
		rows.append(ring)
	lm.grid(stone, rows, base + Vector3(0, s0, 0) + Vector3.UP * (top - s0) * 0.5, true)
	for f in balconies:
		var y: float = h * float(f)
		var rb := lerpf(r * 1.12, r * 0.92, (y - s0) / (top - s0))
		var b := base + Vector3(0, y, 0)
		for t in 3:
			lm.frustum(stone, b - Vector3(0, r * (1.2 - 0.4 * float(t)), 0), rb + r * 0.2 * float(t),
				rb + r * 0.2 * float(t + 1), r * 0.4, 16, PI / 16.0 * float(t % 2))
		lm.frustum(stone, b, r * 1.75, r * 1.75, r * 0.14, 24)
		for k in 16:
			var a := TAU * float(k) / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box(stone, b + d * r * 1.68 + Vector3(0, r * 0.14 + r * 0.42, 0), Vector3(r * 0.62, r * 0.84, r * 0.12),
				Basis(Vector3.UP, PI * 0.5 - a), 0.0)
		lm.frustum(stone, b + Vector3(0, r * 0.98, 0), r * 1.8, r * 1.8, r * 0.1, 24)
	lm.frustum(stone, base + Vector3(0, top - r * 2.0, 0), r * 0.92, r * 0.85, r * 2.0, 16)
	lm.lathe(lead, base + Vector3(0, top, 0), PackedVector2Array([Vector2(r * 1.0, 0),
		Vector2(r * 0.85, cap_h * 0.05), Vector2(r * 0.62, cap_h * 0.2), Vector2(r * 0.38, cap_h * 0.55),
		Vector2(r * 0.12, cap_h * 0.88), Vector2(0, cap_h * 0.94)]), 16)
	lm.frustum(gilt, base + Vector3(0, h - cap_h * 0.08, 0), r * 0.05, r * 0.03, cap_h * 0.08, 6)
	lm.lathe(gilt, base + Vector3(0, h - cap_h * 0.05, 0), SEuUtil.dome(r * 0.1, cap_h * 0.05, 3), 8)
