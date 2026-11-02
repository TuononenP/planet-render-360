class_name LandmarkItlUtil
extends RefCounted

## Helpers shared by the Italian historic-town builders (true metres on
## LandmarkMesh): square or leaning tower shafts with arrow-slit rows,
## Guelph (square) and Ghibelline (swallow-tail) merlons, corbelled
## machicolated galleries, bulbous domes and ragged ruin walls.

## Square shaft from bottom centre c0 (half-width h0) to top centre c1
## (half-width h1), faces turned by `rot` about Y. c1 may be offset from
## above c0, which leans the whole shaft (Garisenda, Asinelli).
static func shaft(lm: LandmarkMesh, key: String, c0: Vector3, h0: float, c1: Vector3, h1: float,
		rot: float = 0.0, cap: bool = true) -> void:
	var tops: Array[Vector3] = []
	for k in 4:
		var b := Basis(Vector3.UP, rot + PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		var a0 := c0 + n * h0 - r * h0
		var a1 := c0 + n * h0 + r * h0
		var b1 := c1 + n * h1 + r * h1
		var b0 := c1 + n * h1 - r * h1
		var fn := (a1 - a0).cross(b0 - a0).normalized()
		lm.quad(key, a0, a1, b1, b0, fn if fn.dot(n) > 0.0 else -fn)
		tops.append(b0)
	if cap:
		lm.quad(key, tops[0], tops[1], tops[2], tops[3], Vector3.UP)

## Shaft with rows of arrow-slit / window openings on all four faces.
## rows: [y, width, height, count, pitch, pointed]. Openings tilt with a
## leaning shaft so they lie flat on the wall.
static func tower(lm: LandmarkMesh, key: String, dark: String, c0: Vector3, h0: float, c1: Vector3,
		h1: float, rot: float, rows: Array) -> void:
	shaft(lm, key, c0, h0, c1, h1, rot)
	var span := c1.y - c0.y
	for k in 4:
		var b := Basis(Vector3.UP, rot + PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		var up := ((c1 + n * h1) - (c0 + n * h0)).normalized()
		for row in rows:
			var y: float = row[0]
			var t := clampf((y - c0.y) / span, 0.0, 1.0)
			var mid := c0.lerp(c1, t) + n * (lerpf(h0, h1, t) + 0.06)
			var count: int = row[3]
			for i in count:
				var s := (float(i) - float(count - 1) * 0.5) * float(row[4])
				SEuUtil.opening(lm, dark, mid + r * s, r, up, float(row[1]), float(row[2]), bool(row[5]))

## One merlon centred at c (wall-top point), its width along d, `t` thick,
## `h` tall; swallow-tail (Ghibelline) notches the top into two horns.
static func merlon(lm: LandmarkMesh, key: String, c: Vector3, d: Vector3, w: float, h: float,
		t: float, swallow: bool = false) -> void:
	var ang := atan2(d.x, d.z)
	if not swallow:
		lm.box(key, c + Vector3(0, h * 0.5, 0), Vector3(t, h, w), Basis(Vector3.UP, ang))
		return
	var n := d.cross(Vector3.UP).normalized()
	var prof := [Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5, h),
		Vector2(0, h * 0.7), Vector2(-w * 0.5, h)]
	for sgn in [-1.0, 1.0]:
		var nn: Vector3 = n * float(sgn)
		var p: Array[Vector3] = []
		for v in prof:
			p.append(c + d * (v as Vector2).x + Vector3(0, (v as Vector2).y, 0) + nn * t * 0.5)
		for tri_i in [[0, 1, 2], [0, 2, 3], [0, 3, 4]]:
			lm.tri(key, p[tri_i[0]], p[tri_i[1]], p[tri_i[2]], nn, nn, nn, Vector2.ZERO, Vector2(w, 0), Vector2(w, -h))
	for i in 5:
		var v0: Vector2 = prof[i]
		var v1: Vector2 = prof[(i + 1) % 5]
		var e := v1 - v0
		var out := d * e.y + Vector3.UP * (-e.x)
		var p0 := c + d * v0.x + Vector3(0, v0.y, 0)
		var p1 := c + d * v1.x + Vector3(0, v1.y, 0)
		lm.quad(key, p0 + n * t * 0.5, p1 + n * t * 0.5, p1 - n * t * 0.5, p0 - n * t * 0.5, out.normalized())

## Merlons every `pitch` metres along a..b (wall-top points).
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float, pitch: float,
		h: float, t: float, swallow: bool = false) -> void:
	var span := b - a
	var count := maxi(int(round(span.length() / pitch)), 1)
	var d := span.normalized()
	for i in count:
		merlon(lm, key, a + span * ((float(i) + 0.5) / float(count)), d, w, h, t, swallow)

## Battlement round a rectangle (centre c on the wall top, half-extents
## hx, hz, turned by rot).
static func crown(lm: LandmarkMesh, key: String, c: Vector3, hx: float, hz: float, rot: float,
		w: float, pitch: float, h: float, t: float, swallow: bool = false) -> void:
	var b := Basis(Vector3.UP, rot)
	var corners := [Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz)]
	for i in 4:
		var a: Vector3 = c + b * (corners[i] as Vector3)
		var e: Vector3 = c + b * (corners[(i + 1) % 4] as Vector3)
		merlons(lm, key, a, e, w, pitch, h, t, swallow)

## Corbelled machicolated gallery round a rectangle: a row of corbels
## `drop` deep, the projecting deck, a parapet and the merlons. The wall
## top is at c.y; the gallery stands `proj` out from half-extents hx, hz.
## Returns the top of the merlons.
static func gallery(lm: LandmarkMesh, stone: String, dark: String, c: Vector3, hx: float,
		hz: float, rot: float, proj: float, drop: float, mer_h: float, swallow: bool = false,
		mer_w: float = 1.3, spacing: float = 1.7) -> float:
	var b := Basis(Vector3.UP, rot)
	var ox := hx + proj
	var oz := hz + proj
	lm.box(stone, c + Vector3(0, 0.4, 0), Vector3(ox * 2.0, 0.8, oz * 2.0), b)
	for side in 4:
		var horizontal := side < 2
		var sgn := 1.0 if side % 2 == 0 else -1.0
		var length := (ox if horizontal else oz) * 2.0
		var n := int(length / spacing)
		for i in n:
			var s := (float(i) + 0.5) / float(n) * length - length * 0.5
			var local := Vector3(s, -drop * 0.5, sgn * (hz + proj * 0.5)) if horizontal \
				else Vector3(sgn * (hx + proj * 0.5), -drop * 0.5, s)
			lm.box(stone, c + b * local, Vector3(0.7, drop, proj) if horizontal else Vector3(proj, drop, 0.7), b)
		var shade := Vector3(0, -drop * 0.5, sgn * (hz + 0.05)) if horizontal \
			else Vector3(sgn * (hx + 0.05), -drop * 0.5, 0)
		lm.box(dark, c + b * shade, Vector3(length * 0.96, drop * 0.9, 0.1) if horizontal \
			else Vector3(0.1, drop * 0.9, length * 0.96), b)
	var parapet := 0.9
	lm.box(stone, c + b * Vector3(0, 0.8 + parapet * 0.5, oz - 0.25), Vector3(ox * 2.0, parapet, 0.5), b)
	lm.box(stone, c + b * Vector3(0, 0.8 + parapet * 0.5, -oz + 0.25), Vector3(ox * 2.0, parapet, 0.5), b)
	lm.box(stone, c + b * Vector3(ox - 0.25, 0.8 + parapet * 0.5, 0), Vector3(0.5, parapet, oz * 2.0 - 1.0), b)
	lm.box(stone, c + b * Vector3(-ox + 0.25, 0.8 + parapet * 0.5, 0), Vector3(0.5, parapet, oz * 2.0 - 1.0), b)
	crown(lm, stone, c + Vector3(0, 0.8 + parapet, 0), ox - 0.25, oz - 0.25, rot, mer_w, mer_w * 2.0,
		mer_h, 0.5, swallow)
	return c.y + 0.8 + parapet + mer_h

## Bulbous (onion) dome profile (radius, y) of base radius r, height h:
## swells past the drum then draws to a point.
static func bulb(r: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r, 0), Vector2(r * 1.12, h * 0.14), Vector2(r * 1.2, h * 0.32),
		Vector2(r * 1.1, h * 0.54), Vector2(r * 0.78, h * 0.76), Vector2(r * 0.38, h * 0.92),
		Vector2(r * 0.12, h)])

## Ragged ruined wall ring: boxes of broken height with doorway gaps.
## Walls stand on a rectangle (centre c, size w x d, thickness t); heights
## vary between h * 0.45 and h.
static func ruin_ring(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, h: float,
		t: float, seed_v: float) -> void:
	var sides := [[Vector3(0, 0, d * 0.5), w, true], [Vector3(0, 0, -d * 0.5), w, true],
		[Vector3(w * 0.5, 0, 0), d, false], [Vector3(-w * 0.5, 0, 0), d, false]]
	var idx := 0
	for s in sides:
		var length: float = s[1]
		var n := maxi(int(length / 7.5), 2)
		for i in n:
			idx += 1
			if (idx + int(seed_v)) % 5 == 0:
				continue
			var seg := length / float(n)
			var hh := h * (0.45 + 0.55 * absf(sin(float(idx) * 1.9 + seed_v)))
			var off := -length * 0.5 + seg * (float(i) + 0.5)
			var p := c + (s[0] as Vector3) + (Vector3(off, 0, 0) if bool(s[2]) else Vector3(0, 0, off))
			var size := Vector3(seg * 0.82, hh, t) if bool(s[2]) else Vector3(t, hh, seg * 0.82)
			lm.box(key, p + Vector3(0, hh * 0.5, 0), size)

## Dark patch at sprung height: a mosaic lunette (semicircle) of width w
## on a wall face whose bottom centre is o.
static func lunette(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, w: float) -> void:
	SEuUtil.opening(lm, key, o, right, Vector3.UP, w, w * 0.5)

## Flat five-pointed star in the plane facing +Z, outer radius r, at c.
static func star(lm: LandmarkMesh, key: String, c: Vector3, r: float) -> void:
	for face in [1.0, -1.0]:
		var n := Vector3(0, 0, face)
		for i in 5:
			var a0 := PI * 0.5 + TAU * float(i) / 5.0
			var a1 := a0 + TAU / 10.0
			var a2 := a0 + TAU / 5.0
			var p0 := c + Vector3(cos(a0), sin(a0), 0) * r
			var p1 := c + Vector3(cos(a1), sin(a1), 0) * r * 0.42
			var p2 := c + Vector3(cos(a2), sin(a2), 0) * r
			var pm := c + n * 0.15 * r
			lm.tri(key, p0, p1, pm, n, n, n, Vector2.ZERO, Vector2(r, 0), Vector2(0, r))
			lm.tri(key, p1, p2, pm, n, n, n, Vector2.ZERO, Vector2(r, 0), Vector2(0, r))
