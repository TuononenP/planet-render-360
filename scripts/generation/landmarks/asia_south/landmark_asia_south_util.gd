class_name LandmarkAsiaSouthUtil
extends RefCounted

## Shared parts of the south and south-east Asian landmark batch, in true
## metres on LandmarkMesh: domes, onion domes, finials, kiosks (chhatri),
## arched wall blocks and fluted tapering shafts. Every part takes the
## material KEYS to draw with (registered by the caller with lm.use).

## Hemispherical (or flattened, h < r) dome on `base`, `seg` sides.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 24, steps: int = 8) -> void:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * cos(a), h * sin(a)))
	lm.lathe(key, base, p, seg)

## Mughal onion (bulbous) dome: neck, widest belly, tapering to the tip.
static func onion(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 24) -> void:
	var t := [[0.74, 0.0], [0.97, 0.1], [1.0, 0.26], [0.9, 0.43], [0.62, 0.6],
		[0.34, 0.76], [0.13, 0.9], [0.0, 1.0]]
	var p := PackedVector2Array()
	for e in t:
		p.append(Vector2(r * float(e[0]), h * float(e[1])))
	lm.lathe(key, base, p, seg)

## Slim ringed finial (kalash / mast): bulbs up a thin stem, height h.
static func finial(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float = 0.4) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.6, 0), Vector2(r * 1.2, h * 0.12),
		Vector2(r * 0.5, h * 0.2), Vector2(r * 1.5, h * 0.38), Vector2(r * 0.4, h * 0.5),
		Vector2(r * 0.9, h * 0.66), Vector2(r * 0.25, h * 0.8), Vector2(r * 0.12, h)]), 10)

## Open dome-roofed kiosk: four pillars, a slab and an onion dome.
## Height = pillar_h + 0.5 + dome_h.
static func chhatri(lm: LandmarkMesh, wall: String, roof: String, base: Vector3, w: float,
		pillar_h: float, dome_h: float) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(wall, base + Vector3(sx * w * 0.4, pillar_h * 0.5, sz * w * 0.4),
				Vector3(w * 0.14, pillar_h, w * 0.14))
	lm.box(wall, base + Vector3(0, pillar_h + 0.25, 0), Vector3(w, 0.5, w))
	onion(lm, roof, base + Vector3(0, pillar_h + 0.5, 0), w * 0.46, dome_h, 14)

## Wall block facing local +Z (basis turns it), floor centre at `base`:
## width x height x depth with a round-headed passage open_w wide and
## open_h tall through it (front and back faces, jambs, soffit).
static func arch_wall(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, width: float,
		height: float, depth: float, open_w: float, open_h: float, steps: int = 10) -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var r := open_w * 0.5
	var spring := open_h - r
	var curve: Array[Vector2] = []
	for i in steps + 1:
		var a := PI * (1.0 - float(i) / steps)
		curve.append(Vector2(r * cos(a), spring + r * sin(a)))
	for side in [1.0, -1.0]:
		var z: float = hd * side
		var n: Vector3 = basis * Vector3(0, 0, side)
		_q(lm, key, base, basis, Vector3(-hw, 0, z), Vector3(-r, 0, z), Vector3(-r, height, z),
			Vector3(-hw, height, z), n)
		_q(lm, key, base, basis, Vector3(r, 0, z), Vector3(hw, 0, z), Vector3(hw, height, z),
			Vector3(r, height, z), n)
		for i in steps:
			var c0 := curve[i]
			var c1 := curve[i + 1]
			_q(lm, key, base, basis, Vector3(c0.x, c0.y, z), Vector3(c1.x, c1.y, z),
				Vector3(c1.x, height, z), Vector3(c0.x, height, z), n)
	# Jambs and the arched soffit between front and back faces.
	for sx in [-1.0, 1.0]:
		var n: Vector3 = basis * Vector3(-sx, 0, 0)
		_q(lm, key, base, basis, Vector3(sx * r, 0, -hd), Vector3(sx * r, 0, hd),
			Vector3(sx * r, spring, hd), Vector3(sx * r, spring, -hd), n)
		_q(lm, key, base, basis, Vector3(sx * hw, 0, -hd), Vector3(sx * hw, 0, hd),
			Vector3(sx * hw, height, hd), Vector3(sx * hw, height, -hd), -n)
	for i in steps:
		var c0 := curve[i]
		var c1 := curve[i + 1]
		var mid := (c0 + c1) * 0.5
		var n := basis * Vector3(-mid.x, spring - mid.y, 0).normalized()
		_q(lm, key, base, basis, Vector3(c0.x, c0.y, -hd), Vector3(c0.x, c0.y, hd),
			Vector3(c1.x, c1.y, hd), Vector3(c1.x, c1.y, -hd), n)
	_q(lm, key, base, basis, Vector3(-hw, height, -hd), Vector3(-hw, height, hd),
		Vector3(hw, height, hd), Vector3(hw, height, -hd), basis * Vector3.UP)

## One local-frame quad placed at `base` turned by `basis`.
static func _q(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3, n: Vector3) -> void:
	lm.quad(key, base + basis * a, base + basis * b, base + basis * c, base + basis * d, n)

## Tapering shaft of `flutes` rounded ribs from radius r0 at base to r1
## at the top, `seg` facets per flute; depth is the rib relief (m).
static func fluted_shaft(lm: LandmarkMesh, key: String, base: Vector3, r0: float, r1: float,
		h: float, flutes: int, relief: float, rings: int = 2, seg: int = 3) -> void:
	var n := flutes * seg
	for j in rings:
		var t0 := float(j) / rings
		var t1 := float(j + 1) / rings
		var ra := lerpf(r0, r1, t0)
		var rb := lerpf(r0, r1, t1)
		for i in n:
			var a0 := TAU * float(i) / n
			var a1 := TAU * float(i + 1) / n
			var q0 := ra + relief * 0.5 * (1.0 + cos(a0 * flutes))
			var q1 := ra + relief * 0.5 * (1.0 + cos(a1 * flutes))
			var q2 := rb + relief * 0.5 * (1.0 + cos(a1 * flutes))
			var q3 := rb + relief * 0.5 * (1.0 + cos(a0 * flutes))
			var am := (a0 + a1) * 0.5
			var nn := Vector3(cos(am), (r0 - r1) / h, sin(am)).normalized()
			lm.quad(key, base + Vector3(cos(a0) * q0, h * t0, sin(a0) * q0),
				base + Vector3(cos(a1) * q1, h * t0, sin(a1) * q1),
				base + Vector3(cos(a1) * q2, h * t1, sin(a1) * q2),
				base + Vector3(cos(a0) * q3, h * t1, sin(a0) * q3), nn)

## Row of small dark recesses (windows, Buddha niches) on the four sides
## of a square block of half-width hw, `count` per side from y0..y1.
static func niche_rows(lm: LandmarkMesh, key: String, c: Vector3, hw: float, y: float,
		size: Vector3, count: int) -> void:
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in count:
			var x := -hw * 0.82 + hw * 1.64 * (float(k) + 0.5) / count
			lm.box(key, c + b * Vector3(x, y, hw + size.z * 0.4), size, b)
