class_name RmADetail
extends RefCounted

## Sculpture and ornament helpers for the ancient Rome models, in true
## metres on LandmarkMesh: figures in relief, flying Victories, tondi,
## framed panels, inscriptions, garlands and bucrania, rusticated
## columns and pedestals. Relief pieces are lathed and flattened toward
## the wall they stand out from (walls face along X or Z in the model's
## own frame), half buried in the face like carved work.

## Lathe stretch (sx, sz) that flattens a solid to `depth` of its width
## along the wall normal `n`.
static func _squash(n: Vector3, depth: float) -> Vector2:
	if absf(n.x) > absf(n.z):
		return Vector2(depth, 1.0)
	return Vector2(1.0, depth)

## A draped figure carved in relief on a wall facing `n`, feet at `base`,
## `h` tall: robe, torso and head lathed and flattened into the face.
static func relief_figure(lm: LandmarkMesh, key: String, base: Vector3, n: Vector3, h: float,
		depth: float = 0.45) -> void:
	var s := _squash(n, depth)
	lm.lathe(key, base, PackedVector2Array([Vector2(h * 0.15, 0), Vector2(h * 0.13, h * 0.25),
		Vector2(h * 0.1, h * 0.5), Vector2(h * 0.12, h * 0.68), Vector2(h * 0.07, h * 0.8)]), 8, s.x, s.y)
	lm.lathe(key, base + Vector3(0, h * 0.8, 0), PackedVector2Array([Vector2(h * 0.035, 0),
		Vector2(h * 0.06, h * 0.06), Vector2(h * 0.055, h * 0.14), Vector2(0, h * 0.2)]), 8, s.x, s.y)

## A row of `count` relief figures from a to b (feet line) on a wall
## facing `n`; heights vary a little like a procession.
static func figure_row(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: Vector3, h: float,
		count: int, depth: float = 0.45) -> void:
	for i in count:
		var t := (float(i) + 0.5) / float(count)
		var f := 0.88 + 0.12 * absf(sin(float(i) * 2.7 + a.x))
		relief_figure(lm, key, a.lerp(b, t), n, h * f, depth)

## A winged Victory flying in an arch spandrel at `c` on a wall facing
## `n`, body tilted toward the arch crown (`toward` = -1 or 1 along the
## wall's right), `s` metres long: body, raised arm with a wreath, wings.
static func victory(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, toward: float, s: float) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var dir := (right * toward * 0.75 + Vector3.UP * 0.66).normalized()
	var foot := c - dir * s * 0.5 + nn * 0.06
	var head := c + dir * s * 0.42 + nn * 0.06
	lm.beam(key, foot, head, s * 0.2, s * 0.12, right, true)
	lm.beam(key, foot, foot - right * toward * s * 0.25 - Vector3.UP * s * 0.05, s * 0.12, s * 0.1, right, true)
	lm.beam(key, head, head + dir * s * 0.12, s * 0.1, s * 0.1, right, true)
	var hand := head + right * toward * s * 0.3 + Vector3.UP * s * 0.12
	lm.beam(key, head - dir * s * 0.08, hand, s * 0.06, s * 0.06, nn, true)
	for k in 8:
		var a0 := TAU * float(k) / 8.0
		var a1 := TAU * float(k + 1) / 8.0
		lm.beam(key, hand + (right * cos(a0) + Vector3.UP * sin(a0)) * s * 0.09,
			hand + (right * cos(a1) + Vector3.UP * sin(a1)) * s * 0.09, s * 0.035, s * 0.035, nn)
	var w0 := c + dir * s * 0.15 + nn * 0.1
	var tip := w0 - right * toward * s * 0.55 + Vector3.UP * s * 0.35
	var tail := w0 - dir * s * 0.25 - right * toward * s * 0.25
	for off in [0.0, 0.08]:
		var o := nn * float(off)
		lm.tri(key, w0 + o, tip + o, tail + o, nn, nn, nn, Vector2.ZERO, Vector2(s * 0.6, 0), Vector2(0, s * 0.4))

## A moulded ring frame `r` in radius on a wall facing `n` (a tondo or
## round window surround), `segs` voussoir-like segments.
static func ring_frame(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, r: float, w: float,
		depth: float, segs: int = 20) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	for k in segs:
		var a0 := TAU * float(k) / float(segs)
		var a1 := TAU * float(k + 1) / float(segs)
		lm.beam(key, c + (right * cos(a0) + Vector3.UP * sin(a0)) * r + nn * depth * 0.5,
			c + (right * cos(a1) + Vector3.UP * sin(a1)) * r + nn * depth * 0.5, w, depth, nn)

## A carved roundel: sunk field, moulded frame and two figures (a hunt
## or a sacrifice on the Arch of Constantine's Hadrianic tondi).
static func tondo(lm: LandmarkMesh, frame: String, field: String, c: Vector3, n: Vector3, r: float) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	lm.disc(field, c + nn * 0.02, nn, r, 20)
	ring_frame(lm, frame, c, nn, r + 0.08, 0.18, 0.22, 20)
	for s in [-1.0, 1.0]:
		relief_figure(lm, frame, c + right * float(s) * r * 0.35 - Vector3.UP * r * 0.65, nn, r * 1.25, 0.4)

## A rectangular framed panel w x h centred at `c` on a wall facing `n`:
## a field set `depth` proud and a moulded frame round it.
static func panel(lm: LandmarkMesh, frame: String, field: String, c: Vector3, n: Vector3, w: float,
		h: float, depth: float = 0.12, fw: float = 0.2) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var basis := Basis(right, Vector3.UP, nn)
	lm.box(field, c + nn * depth * 0.5, Vector3(w, h, depth), basis, 0.0)
	var corners := [c + (-right * w * 0.5 - Vector3.UP * h * 0.5), c + (right * w * 0.5 - Vector3.UP * h * 0.5),
		c + (right * w * 0.5 + Vector3.UP * h * 0.5), c + (-right * w * 0.5 + Vector3.UP * h * 0.5)]
	for k in 4:
		var p0: Vector3 = corners[k]
		var p1: Vector3 = corners[(k + 1) % 4]
		var d := (p1 - p0).normalized()
		lm.beam(frame, p0 - d * fw * 0.5 + nn * depth, p1 + d * fw * 0.5 + nn * depth, fw, fw * 0.8, nn)

## Incised lettering: `lines` rows of letters (dark inlay quads where the
## bronze letters sat) filling w x h at `c` on a wall facing `n`, with a
## word space every few letters.
static func inscription(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, w: float, h: float,
		lines: int, seed_v: float = 0.0) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var lh := h / (float(lines) * 1.5)
	var pitch := lh * 0.82
	for j in lines:
		var y := h * 0.5 - lh * 0.25 - (float(j) + 0.5) * h / float(lines)
		var cols := int(w * (0.92 - 0.12 * float(j % 2)) / pitch)
		var x0 := -float(cols) * pitch * 0.5
		for i in cols:
			if absf(sin(float(i) * 1.7 + float(j) * 3.1 + seed_v)) > 0.93:
				continue
			var p := c + right * (x0 + pitch * (float(i) + 0.5)) + Vector3.UP * y + nn * 0.015
			var hw := right * lh * 0.3
			var hh := Vector3.UP * lh * 0.5
			lm.quad(key, p - hw - hh, p + hw - hh, p + hw + hh, p - hw + hh, nn)

## A fruit garland hung from a to b, sagging `sag` and `r` thick at the
## middle, in `segs` tapering links.
static func garland(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: Vector3, sag: float,
		r: float, segs: int = 6) -> void:
	var prev := a
	for k in segs:
		var t := float(k + 1) / float(segs)
		var p := a.lerp(b, t) - Vector3.UP * sag * sin(PI * t)
		var th := r * (0.5 + 0.5 * sin(PI * (t - 0.5 / float(segs))))
		lm.beam(key, prev, p, th, th, n)
		prev = p

## An ox skull (bucranium) on a wall facing `n`, `s` high: skull, muzzle
## and the two curving horns.
static func bucranium(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, s: float) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var basis := Basis(right, Vector3.UP, nn)
	lm.box(key, c + nn * s * 0.12, Vector3(s * 0.45, s * 0.55, s * 0.25), basis, 0.0)
	lm.box(key, c + nn * s * 0.12 - Vector3.UP * s * 0.38, Vector3(s * 0.3, s * 0.25, s * 0.2), basis, 0.0)
	for sd in [-1.0, 1.0]:
		var h0 := c + right * float(sd) * s * 0.2 + Vector3.UP * s * 0.25 + nn * s * 0.12
		var h1 := h0 + right * float(sd) * s * 0.3 + Vector3.UP * s * 0.12
		var h2 := h1 + right * float(sd) * s * 0.05 + Vector3.UP * s * 0.25
		lm.beam(key, h0, h1, s * 0.09, s * 0.09, nn)
		lm.beam(key, h1, h2, s * 0.06, s * 0.06, nn)

## Classical pedestal w x d, h tall at `c` (ground centre): plinth, base
## moulding, die and a cap moulding (the column pedestals of the arches).
static func pedestal(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, h: float,
		basis: Basis = Basis()) -> void:
	lm.box(key, c + basis.y * h * 0.06, Vector3(w + 0.3, h * 0.12, d + 0.3), basis)
	lm.box(key, c + basis.y * h * 0.15, Vector3(w + 0.16, h * 0.06, d + 0.16), basis)
	lm.box(key, c + basis.y * h * 0.5, Vector3(w, h * 0.64, d), basis)
	lm.box(key, c + basis.y * h * 0.855, Vector3(w + 0.14, h * 0.07, d + 0.14), basis)
	lm.box(key, c + basis.y * h * 0.945, Vector3(w + 0.3, h * 0.11, d + 0.3), basis)

## Rusticated Tuscan column of Claudian work (Porta Maggiore): rough
## drums alternately bossed out, a plain torus base and a Tuscan cap.
static func rustic_column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		drums: int = 7) -> void:
	lm.box(key, base + Vector3(0, r * 0.2, 0), Vector3(r * 2.7, r * 0.4, r * 2.7))
	lm.lathe(key, base + Vector3(0, r * 0.4, 0), PackedVector2Array([Vector2(r * 1.25, 0),
		Vector2(r * 1.3, r * 0.2), Vector2(r * 1.1, r * 0.4)]), 16)
	var y0 := r * 0.8
	var sh := h - y0 - r * 1.1
	for k in drums:
		var rr := r * (1.12 if k % 2 == 0 else 0.98)
		lm.frustum(key, base + Vector3(0, y0 + sh * float(k) / float(drums), 0), rr, rr * 0.99,
			sh / float(drums), 12)
	var cb := base + Vector3(0, y0 + sh, 0)
	lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.95, 0), Vector2(r * 1.05, r * 0.25),
		Vector2(r * 1.3, r * 0.6)]), 16)
	lm.box(key, cb + Vector3(0, r * 0.8, 0), Vector3(r * 2.8, r * 0.4, r * 2.8))

## Swallowtail (Ghibelline) or square merlons along a..b at the wall top
## (y of a and b), `m` wide on a pitch of 2m, `h` tall, `thick` deep.
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, m: float, h: float,
		thick: float, swallow: bool = false) -> void:
	var d := b - a
	var count := maxi(int(d.length() / (m * 2.0)), 1)
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		lm.box(key, p + Vector3(0, h * 0.4, 0), Vector3(thick, h * 0.8, m), basis)
		if swallow:
			for s in [-1.0, 1.0]:
				lm.box(key, p + d.normalized() * float(s) * m * 0.32 + Vector3(0, h * 0.9, 0),
					Vector3(thick, h * 0.2, m * 0.36), basis, 0.0)
		else:
			lm.box(key, p + Vector3(0, h * 0.9, 0), Vector3(thick, h * 0.2, m), basis, 0.0)

## A spread-winged eagle perched at `c` facing `out`, `s` high (the
## pedestal corners of Trajan's Column).
static func eagle(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, s: float) -> void:
	var o := out.normalized()
	var side := Vector3.UP.cross(o).normalized()
	lm.lathe(key, c, PackedVector2Array([Vector2(s * 0.12, 0), Vector2(s * 0.2, s * 0.3),
		Vector2(s * 0.15, s * 0.6), Vector2(s * 0.08, s * 0.72)]), 8)
	lm.lathe(key, c + Vector3(0, s * 0.72, 0) + o * s * 0.05, PackedVector2Array([Vector2(s * 0.08, 0),
		Vector2(s * 0.09, s * 0.08), Vector2(0, s * 0.18)]), 8)
	lm.beam(key, c + Vector3(0, s * 0.82, 0) + o * s * 0.1, c + Vector3(0, s * 0.78, 0) + o * s * 0.24,
		s * 0.06, s * 0.05, side)
	for sd in [-1.0, 1.0]:
		var root := c + side * float(sd) * s * 0.12 + Vector3(0, s * 0.55, 0)
		var tip := root + side * float(sd) * s * 0.5 + Vector3(0, s * 0.3, 0) - o * s * 0.1
		lm.beam(key, root, tip, s * 0.3, s * 0.05, Vector3.UP.cross(tip - root))

## A round-headed niche or blind window `w` wide in a frame skin laid
## `depth` proud of a wall facing `n`: `c` is the sill centre on the wall
## face, the arch springs `hs` above it; the skin runs `fw` past the
## opening. Real reveals and soffit, the dark back at the wall face.
static func niche(lm: LandmarkMesh, wall: String, dark: String, c: Vector3, n: Vector3, w: float,
		hs: float, depth: float, fw: float, segs: int = 8) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var u := Vector3.UP
	var hw := w * 0.5
	var f := nn * depth
	var bk := nn * 0.01
	var top := hs + hw
	var hh := top + fw
	var ww := hw + fw
	lm.quad(wall, c - r * ww + f, c - r * hw + f, c - r * hw + u * hh + f, c - r * ww + u * hh + f, nn)
	lm.quad(wall, c + r * hw + f, c + r * ww + f, c + r * ww + u * hh + f, c + r * hw + u * hh + f, nn)
	lm.quad(wall, c - r * hw + u * top + f, c + r * hw + u * top + f, c + r * hw + u * hh + f,
		c - r * hw + u * hh + f, nn)
	var spring := c + u * hs
	for k in segs:
		var a0 := PI * float(k) / float(segs)
		var a1 := PI * float(k + 1) / float(segs)
		var am := (a0 + a1) * 0.5
		var p0 := spring + (r * cos(a0) + u * sin(a0)) * hw
		var p1 := spring + (r * cos(a1) + u * sin(a1)) * hw
		var corner := c + u * top + r * hw * (1.0 if am < PI * 0.5 else -1.0)
		lm.tri(wall, corner + f, p0 + f, p1 + f, nn, nn, nn, Vector2(corner.dot(r), -corner.y),
			Vector2(p0.dot(r), -p0.y), Vector2(p1.dot(r), -p1.y))
		lm.quad(wall, p0 + f, p1 + f, p1 + bk, p0 + bk, -(r * cos(am) + u * sin(am)))
		lm.tri(dark, spring + bk, p0 + bk, p1 + bk, nn, nn, nn, Vector2.ZERO,
			Vector2(cos(a0), sin(a0)) * hw, Vector2(cos(a1), sin(a1)) * hw)
	lm.quad(wall, c - r * hw + f, c - r * hw + u * hs + f, c - r * hw + u * hs + bk, c - r * hw + bk, r)
	lm.quad(wall, c + r * hw + f, c + r * hw + u * hs + f, c + r * hw + u * hs + bk, c + r * hw + bk, -r)
	lm.quad(wall, c - r * hw + f, c + r * hw + f, c + r * hw + bk, c - r * hw + bk, u)
	lm.quad(dark, c - r * hw + bk, c + r * hw + bk, spring + r * hw + bk, spring - r * hw + bk, nn)
	lm.quad(wall, c - r * ww, c - r * ww + f, c - r * ww + u * hh + f, c - r * ww + u * hh, -r)
	lm.quad(wall, c + r * ww, c + r * ww + f, c + r * ww + u * hh + f, c + r * ww + u * hh, r)
	lm.quad(wall, c - r * ww + u * hh, c + r * ww + u * hh, c + r * ww + u * hh + f, c - r * ww + u * hh + f, u)
	lm.quad(wall, c - r * ww, c + r * ww, c + r * ww + f, c - r * ww + f, -u)

## A broken column standing on a floor at `p`: square plinth (in
## `base_key`), Attic base and a shaft stump `h` tall of radius r.
static func broken_column(lm: LandmarkMesh, base_key: String, shaft_key: String, p: Vector3, r: float,
		h: float) -> void:
	lm.box(base_key, p + Vector3(0, r * 0.25, 0), Vector3(r * 2.7, r * 0.5, r * 2.7))
	lm.lathe(shaft_key, p + Vector3(0, r * 0.5, 0), PackedVector2Array([Vector2(r * 1.3, 0),
		Vector2(r * 1.32, r * 0.18), Vector2(r * 1.12, r * 0.32), Vector2(r * 1.15, r * 0.48),
		Vector2(r * 1.02, r * 0.6), Vector2(r, r * 0.7), Vector2(r * 0.99, r * 0.7 + h)]), 18)
