extends RefCounted

## Detail parts of the india_historic batch, in true metres on
## LandmarkMesh: arcaded wall skins with real recessed (or open) pointed,
## cusped or round arches, chhajja eaves on brackets, pillared kiosks
## (chhatri) with lotus domes, pilaster rows and Dravida tiers lined with
## miniature kuta and shala pavilions. Every part takes the material KEYS
## to draw with (registered by the caller with lm.use).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Arch head outline from the left springing (-ow/2, spring) over the
## crown to the right springing: "pointed" (Mughal four-centred), "round"
## or "cusped" (engrailed: a pointed arch scalloped into `cusps` lobes).
static func arch_curve(ow: float, spring: float, kind: String = "pointed", steps: int = 8,
		cusps: int = 7) -> PackedVector2Array:
	var r := ow * 0.5
	var rise := r * (1.0 if kind == "round" else 1.3)
	var pts := PackedVector2Array()
	var n := steps * 2
	if kind == "cusped":
		n = maxi(n, cusps * 4)
	# Pointed: two arcs of radius R centred on the springing line, meeting
	# at the crown `rise` above it (R from 2 R r - r^2 = rise^2).
	var big_r := (rise * rise + r * r) / (2.0 * r)
	var a_top := acos(clampf((big_r - r) / big_r, -1.0, 1.0))
	for i in n + 1:
		var s := float(i) / float(n)
		var p: Vector2
		if kind == "round":
			var a := PI * (1.0 - s)
			p = Vector2(r * cos(a), spring + rise * sin(a))
		else:
			var u := absf(s * 2.0 - 1.0)
			var a := a_top * (1.0 - u)
			var x := (big_r * cos(a) - (big_r - r)) * signf(s * 2.0 - 1.0)
			p = Vector2(x, spring + big_r * sin(a))
		if kind == "cusped" and i > 0 and i < n:
			var c := Vector2(0, spring)
			var k := absf(sin(PI * float(cusps) * s))
			p = p + (c - p).normalized() * ow * 0.07 * k
		pts.append(p)
	return pts

## Arcaded wall skin `d` deep on local +Z (basis turns it, base = centre
## of its foot on the mass face): `count` bays across w, each with an
## opening open_w wide, its crown at open_h above `sill`. The front face
## is cut round each opening, reveals run back to the mass face and the
## back of each opening is filled with `back` (a dark recess); when
## `through`, the back face is cut too and the openings pass through
## (a free-standing arcade screen; then base is the back face's foot).
static func arcade_wall(lm: LandmarkMesh, key: String, back: String, base: Vector3, basis: Basis,
		w: float, h: float, d: float, count: int, open_w: float, open_h: float,
		kind: String = "pointed", sill: float = 0.0, through: bool = false, cusps: int = 7) -> void:
	var pitch := w / float(count)
	var rise := open_w * 0.5 * (1.0 if kind == "round" else 1.3)
	var spring := sill + open_h - rise
	var curve := arch_curve(open_w, spring, kind, 6, cusps)
	var nz := basis * Vector3(0, 0, 1)
	var P := func(x: float, y: float, z: float) -> Vector3:
		return base + basis * Vector3(x, y, z)
	for i in count:
		var xc := -w * 0.5 + pitch * (float(i) + 0.5)
		var x0 := xc - pitch * 0.5
		var xl := xc - open_w * 0.5
		# Front (and back) faces: the bay split down the middle into two
		# simple polygons that each wrap half the opening.
		var half := PackedVector2Array([Vector2(x0, 0)])
		if sill > 0.0:
			half.append(Vector2(xc, 0))
			half.append(Vector2(xc, sill))
		else:
			half.append(Vector2(xl, 0))
		half.append(Vector2(xl, sill))
		for k in curve.size() / 2 + 1:
			half.append(Vector2(curve[k].x + xc, curve[k].y))
		half.append(Vector2(xc, h))
		half.append(Vector2(x0, h))
		var mirrored := PackedVector2Array()
		for k in range(half.size() - 1, -1, -1):
			mirrored.append(Vector2(2.0 * xc - half[k].x, half[k].y))
		for poly in [half, mirrored]:
			_face(lm, key, P, poly, d, nz)
			if through:
				_face(lm, key, P, poly, 0.0, -nz)
		# Reveals round the opening.
		var outline := PackedVector2Array([Vector2(xl, sill)])
		for c in curve:
			outline.append(Vector2(c.x + xc, c.y))
		outline.append(Vector2(xc + open_w * 0.5, sill))
		if sill > 0.0:
			outline.append(Vector2(xl, sill))
		for k in outline.size() - 1:
			var a := outline[k]
			var b := outline[k + 1]
			var mid := (a + b) * 0.5
			var e := b - a
			var n2 := Vector2(e.y, -e.x).normalized()
			if n2.dot(Vector2(xc, clampf(mid.y, sill + 0.01, spring)) - mid) < 0.0:
				n2 = -n2
			var nn := basis * Vector3(n2.x, n2.y, 0)
			lm.quad(key, P.call(a.x, a.y, d), P.call(b.x, b.y, d), P.call(b.x, b.y, 0.0),
				P.call(a.x, a.y, 0.0), nn)
		if not through and back != "":
			var hole := PackedVector2Array([Vector2(xl, sill)])
			for c in curve:
				hole.append(Vector2(c.x + xc, c.y))
			hole.append(Vector2(xc + open_w * 0.5, sill))
			_face(lm, back, P, hole, 0.03, nz)
	# Top and end returns.
	var tn := basis * Vector3.UP
	lm.quad(key, P.call(-w * 0.5, h, 0.0), P.call(w * 0.5, h, 0.0), P.call(w * 0.5, h, d),
		P.call(-w * 0.5, h, d), tn)
	for s in [-1.0, 1.0]:
		var x: float = w * 0.5 * s
		lm.quad(key, P.call(x, 0.0, 0.0), P.call(x, 0.0, d), P.call(x, h, d), P.call(x, h, 0.0),
			basis * Vector3(s, 0, 0))

## One flat polygon (local x, y) at local depth z facing `n`.
static func _face(lm: LandmarkMesh, key: String, P: Callable, poly: PackedVector2Array, z: float,
		n: Vector3) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, P.call(a.x, a.y, z), P.call(b.x, b.y, z), P.call(c.x, c.y, z), n, n, n,
			Vector2(a.x, -a.y), Vector2(b.x, -b.y), Vector2(c.x, -c.y))

## Chhajja: a thin sloping stone eave along a-b (its root on the wall
## face), projecting `depth` along `out` and dropping `drop`, carried on a
## bracket every `pitch` metres.
static func chhajja(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3,
		depth: float, drop: float, pitch: float = 2.5) -> void:
	var o := out.normalized() * depth
	var dn := Vector3(0, -drop, 0)
	var t := Vector3(0, -0.18, 0)
	var nu := (o.normalized() * drop + Vector3.UP * depth).normalized()
	lm.quad(key, a, b, b + o + dn, a + o + dn, nu)
	lm.quad(key, a + t, a + o + dn + t, b + o + dn + t, b + t, -nu)
	lm.quad(key, a + o + dn, b + o + dn, b + o + dn + t, a + o + dn + t, out.normalized())
	var n := maxi(int(a.distance_to(b) / pitch), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.beam(key, p + t + Vector3(0, -depth * 0.7, 0), p + o * 0.75 + dn * 0.75 + t, 0.22, 0.3,
			(b - a).normalized())

## Chhajja round a w x l rectangle (centre c on the wall top line).
static func chhajja_ring(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float,
		depth: float, drop: float, pitch: float = 2.5) -> void:
	var hx := w * 0.5
	var hz := l * 0.5
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		var p0: Vector3 = corners[i]
		var p1: Vector3 = corners[(i + 1) % 4]
		var out := (p0 + p1).normalized()
		out = Vector3(signf(out.x) if absf(out.x) > 0.5 else 0.0, 0, signf(out.z) if absf(out.z) > 0.5 else 0.0)
		chhajja(lm, key, c + p0, c + p1, out, depth, drop, pitch)

## Pillared kiosk (chhatri) of `sides` (4, 6 or 8) slim columns on a
## moulded plinth, with lintels, a sloping chhajja, a drum with a lotus
## band, the dome (onion when `onion`, else a low Rajput dome) and a
## finial. Width w across the columns. Returns the height of the top.
static func chhatri(lm: LandmarkMesh, wall: String, roof: String, base: Vector3, w: float,
		pillar_h: float, dome_h: float, sides: int = 8, onion: bool = true, finial: String = "") -> float:
	var r := w * 0.5
	var seg := sides * 2 if w >= 4.0 else 12
	lm.frustum(wall, base, r * 1.12, r * 1.08, 0.35, sides, PI / float(sides))
	var y := 0.35
	var cr := clampf(w * 0.035, 0.09, 0.35)
	for i in sides:
		var a := TAU * float(i) / float(sides)
		var p := base + Vector3(cos(a) * r * 0.92, y, sin(a) * r * 0.92)
		# Square base, shaft, and a bracket capital flaring to the lintel.
		if w >= 4.0:
			lm.frustum(wall, p, cr * 1.5, cr * 1.4, pillar_h * 0.1, 4, PI * 0.25)
		lm.lathe(wall, p, PackedVector2Array([Vector2(cr, 0), Vector2(cr * 0.85, pillar_h * 0.86),
			Vector2(cr * 1.9, pillar_h)]), 6, 1.0, 1.0, 0.0, false, false)
	y += pillar_h
	lm.frustum(wall, base + Vector3(0, y, 0), r * 1.0, r * 1.0, r * 0.12, sides, PI / float(sides))
	y += r * 0.12
	# Chhajja: a flared eave ring.
	lm.lathe(wall, base + Vector3(0, y - r * 0.12, 0), PackedVector2Array([Vector2(r * 0.96, 0),
		Vector2(r * 1.3, -r * 0.12), Vector2(r * 1.32, -r * 0.05), Vector2(r * 1.0, r * 0.1)]), sides, 1.0, 1.0,
		PI / float(sides), false)
	lm.frustum(wall, base + Vector3(0, y, 0), r * 0.82, r * 0.8, r * 0.18, seg)
	y += r * 0.18
	if onion:
		lm.lathe(roof, base + Vector3(0, y, 0), PackedVector2Array([Vector2(r * 0.72, 0),
			Vector2(r * 0.82, dome_h * 0.08), Vector2(r * 0.86, dome_h * 0.25), Vector2(r * 0.78, dome_h * 0.45),
			Vector2(r * 0.55, dome_h * 0.65), Vector2(r * 0.28, dome_h * 0.82), Vector2(r * 0.1, dome_h * 0.94),
			Vector2(0.0, dome_h)]), seg)
	else:
		lm.lathe(roof, base + Vector3(0, y, 0), PackedVector2Array([Vector2(r * 0.8, 0),
			Vector2(r * 0.78, dome_h * 0.3), Vector2(r * 0.66, dome_h * 0.6), Vector2(r * 0.42, dome_h * 0.85),
			Vector2(r * 0.15, dome_h * 0.97), Vector2(0.0, dome_h)]), seg)
	# Lotus petals round the dome's foot.
	for i in sides:
		var a := TAU * (float(i) + 0.5) / float(sides)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam(roof, base + d * r * 0.8 + Vector3(0, y, 0), base + d * r * 0.7 + Vector3(0, y + dome_h * 0.14, 0),
			r * 0.2, r * 0.06, d.cross(Vector3.UP))
	y += dome_h
	var fk := roof if finial == "" else finial
	var fh := maxf(r * 0.35, 0.4)
	U.finial(lm, fk, base + Vector3(0, y - dome_h * 0.04, 0), fh, maxf(r * 0.05, 0.05))
	return y - dome_h * 0.04 + fh

## Total height chhatri() reaches for the same w, pillar_h and dome_h.
static func chhatri_height(w: float, pillar_h: float, dome_h: float) -> float:
	var r := w * 0.5
	return 0.35 + pillar_h + r * 0.3 + dome_h * 0.96 + maxf(r * 0.35, 0.4)

## Chhatri of width w sized to stand `total` metres tall: the pillars
## take 55% of what the plinth, eave, drum and finial leave, the dome the
## rest. Returns the height of the top.
static func chhatri_fit(lm: LandmarkMesh, wall: String, roof: String, base: Vector3, w: float,
		total: float, sides: int = 8, onion: bool = true, finial: String = "") -> float:
	var r := w * 0.5
	var rest := maxf(total - 0.35 - r * 0.3 - maxf(r * 0.35, 0.4), 0.6)
	return chhatri(lm, wall, roof, base, w, rest * 0.55, rest * 0.45 / 0.96, sides, onion, finial)

## Row of `n` pilasters along a-b (face points at y = a.y), each pw wide,
## `proj` proud of the face along `out`, h tall, with a base and capital.
static func pilasters(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, n: int,
		h: float, pw: float, proj: float) -> void:
	var dir := (b - a).normalized()
	var o := out.normalized()
	var bas := Basis(dir, Vector3.UP, o)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n)) + o * proj * 0.5
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(pw, h, proj), bas, 0.0)
		lm.box(key, p + Vector3(0, h * 0.04, 0) + o * proj * 0.2, Vector3(pw * 1.3, h * 0.08, proj * 1.4), bas, 0.0)
		lm.box(key, p + Vector3(0, h * 0.95, 0) + o * proj * 0.25, Vector3(pw * 1.5, h * 0.1, proj * 1.5), bas, 0.0)

## Dravida tier parapet (hara) round a w x l rectangle at height y on
## centre c: square domed kuta pavilions at the corners, barrel-roofed
## shala pavilions mid-side and small panjara niches between, all `s`
## high. Drawn in `key` with the domes and barrel roofs in `roof`.
static func hara(lm: LandmarkMesh, key: String, roof: String, c: Vector3, w: float, l: float, s: float,
		per_side: int = 3) -> void:
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var run := w if side % 2 == 0 else l
		var off := (l if side % 2 == 0 else w) * 0.5
		for k in per_side:
			var x := (float(k) - float(per_side - 1) * 0.5) * run / float(per_side)
			var p := c + b * Vector3(x, 0, off - s * 0.35)
			var shala := k == per_side / 2
			var pw := (run / float(per_side)) * (0.62 if shala else 0.4)
			lm.box(key, p + Vector3(0, s * 0.28, 0), Vector3(pw, s * 0.56, s * 0.6), b, 0.0)
			if shala:
				# Barrel (wagon) roof with gable ends facing out.
				lm.gable(roof, p + Vector3(0, s * 0.56, 0), s * 0.62, pw * 0.95, s * 0.4,
					b * Basis(Vector3.UP, PI * 0.5), 0.05, roof)
			else:
				U.dome(lm, roof, p + Vector3(0, s * 0.56, 0), s * 0.32, s * 0.38, 6, 2)
		# Kuta at the corner.
		var cp := c + b * Vector3(run * 0.5 - s * 0.35, 0, off - s * 0.35)
		lm.box(key, cp + Vector3(0, s * 0.3, 0), Vector3(s * 0.7, s * 0.6, s * 0.7), b, 0.0)
		U.dome(lm, roof, cp + Vector3(0, s * 0.6, 0), s * 0.4, s * 0.42, 8, 2)
