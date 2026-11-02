class_name LandmarkChParts
extends RefCounted

## Small shared parts for the central_historic landmark batch, in true
## metres on LandmarkMesh: pointed and round-arched openings drawn flat
## on a facade, wall segments between two plan points, corner turrets,
## sliding cornice bands and finials. Each takes the material KEY to
## draw with; `b` turns the part so its local +Z faces outwards.

## Point `x` along, `y` up and `z` out of a facade whose origin is `at`.
static func at(origin: Vector3, b: Basis, x: float, y: float, z: float = 0.0) -> Vector3:
	return origin + b * Vector3(x, y, z)

## Flat Gothic opening (pointed head) w wide, h tall to the apex,
## standing on `base` just proud of the wall.
static func pointed(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float,
		b: Basis = Basis(), lift: float = 0.08) -> void:
	var rise := minf(w * 0.9, h * 0.55)
	var sh := h - rise
	var n := b.z
	var hw := w * 0.5
	lm.quad(key, at(base, b, -hw, 0, lift), at(base, b, hw, 0, lift), at(base, b, hw, sh, lift),
		at(base, b, -hw, sh, lift), n)
	lm.tri(key, at(base, b, -hw, sh, lift), at(base, b, hw, sh, lift), at(base, b, 0, h, lift),
		n, n, n, Vector2(0, 0), Vector2(w, 0), Vector2(hw, rise))

## Flat round-arched opening (semicircular head) w wide, h tall.
static func round_arch(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float,
		b: Basis = Basis(), lift: float = 0.08) -> void:
	var rad := w * 0.5
	var sh := maxf(h - rad, 0.05)
	var n := b.z
	lm.quad(key, at(base, b, -rad, 0, lift), at(base, b, rad, 0, lift), at(base, b, rad, sh, lift),
		at(base, b, -rad, sh, lift), n)
	var c := at(base, b, 0, sh, lift)
	for i in 6:
		var a0 := PI * float(i) / 6.0
		var a1 := PI * float(i + 1) / 6.0
		lm.tri(key, c, at(base, b, cos(a0) * rad, sh + sin(a0) * rad, lift),
			at(base, b, cos(a1) * rad, sh + sin(a1) * rad, lift), n, n, n,
			Vector2(0, 0), Vector2(cos(a0) * rad, sin(a0) * rad), Vector2(cos(a1) * rad, sin(a1) * rad))

## A row of `count` openings along the facade, centred on `base`;
## `gothic` picks pointed over round heads.
static func row(lm: LandmarkMesh, key: String, base: Vector3, count: int, step: float, w: float,
		h: float, b: Basis = Basis(), gothic: bool = true, lift: float = 0.08) -> void:
	for i in count:
		var o := at(base, b, step * (float(i) - float(count - 1) * 0.5), 0.0, 0.0)
		if gothic:
			pointed(lm, key, o, w, h, b, lift)
		else:
			round_arch(lm, key, o, w, h, b, lift)

## Vertical wall slab between two plan points `p` and `q` (y ignored),
## from y0 to y1, `thick` metres through.
static func wall(lm: LandmarkMesh, key: String, p: Vector3, q: Vector3, y0: float, y1: float,
		thick: float) -> void:
	var d := q - p
	d.y = 0.0
	var l := d.length()
	if l < 0.01:
		return
	var mid := (p + q) * 0.5
	lm.box(key, Vector3(mid.x, (y0 + y1) * 0.5, mid.z), Vector3(l, y1 - y0, thick),
		Basis(Vector3.UP, atan2(-d.z, d.x)))

## Slender polygonal corner turret: shaft of radius r and height h with
## a pointed cap `cap_h` high (sides 8 unless set).
static func turret(lm: LandmarkMesh, wall_key: String, cap_key: String, base: Vector3, r: float,
		h: float, cap_h: float, sides: int = 8) -> void:
	lm.lathe(wall_key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.9, h)]), sides,
		1.0, 1.0, PI / float(sides), false)
	lm.lathe(cap_key, base + Vector3(0, h, 0), PackedVector2Array([Vector2(r * 1.15, 0),
		Vector2(0.0, cap_h)]), sides, 1.0, 1.0, PI / float(sides), false)

## Thin cornice or string course round a square plan of half-width hw.
static func band(lm: LandmarkMesh, key: String, y: float, hw_x: float, hw_z: float, h: float = 0.8,
		out: float = 0.5, c: Vector3 = Vector3.ZERO) -> void:
	lm.box(key, c + Vector3(0, y + h * 0.5, 0), Vector3(hw_x * 2.0 + out * 2.0, h, hw_z * 2.0 + out * 2.0))

## Ball and rod finial reaching `h` above `base`.
static func finial(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float = 0.5) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 0.6, 0), Vector2(r, h * 0.2),
		Vector2(r * 0.4, h * 0.34), Vector2(r * 0.12, h * 0.5), Vector2(0.04, h)]), 8)

## Stepped octagon-to-dome swell profile (radius, y) for copper domes.
static func swell(r: float, h: float, bulge: float = 1.12) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		var rr := r * (1.0 - t * t) + r * (bulge - 1.0) * sin(PI * minf(t * 2.0, 1.0))
		p.append(Vector2(maxf(rr, 0.0), h * sin(t * PI * 0.5)))
	return p
