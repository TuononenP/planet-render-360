class_name LandmarkIndUtil
extends RefCounted

## Shared parts of the india_historic landmark batch, in true metres on
## LandmarkMesh: flat arched facade panels, striped marble domes, wall
## runs with merlons, stairs and Mughal gate blocks. Every part takes the
## material KEYS to draw with (registered by the caller with lm.use).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
## (radius factor, height factor) of the Mughal onion dome, as U.onion.
const ONION: Array = [[0.74, 0.0], [0.97, 0.1], [1.0, 0.26], [0.9, 0.43], [0.62, 0.6],
	[0.34, 0.76], [0.13, 0.9]]

## Horizontal (x, z) of a point.
static func xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## Flat arched panel facing local +Z (basis turns it), floor centre at
## `base`: w wide, h tall, pointed (Mughal) or round-headed.
static func arch_panel(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, w: float,
		h: float, pointed: bool = true, steps: int = 6) -> void:
	var r := w * 0.5
	var spring := h - r * (1.4 if pointed else 1.0)
	var right := PackedVector2Array()
	for i in steps + 1:
		var s := float(i) / float(steps)
		if pointed:
			right.append(Vector2(r * (1.0 - pow(s, 1.7)), spring + (h - spring) * s))
		else:
			right.append(Vector2(r * cos(s * PI * 0.5), spring + r * sin(s * PI * 0.5)))
	var pts := PackedVector2Array([Vector2(-r, 0.0), Vector2(r, 0.0)])
	pts.append_array(right)
	for i in range(steps - 1, -1, -1):
		pts.append(Vector2(-right[i].x, right[i].y))
	var idx := Geometry2D.triangulate_polygon(pts)
	var n := basis * Vector3(0, 0, 1)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		lm.tri(key, base + basis * Vector3(a.x, a.y, 0), base + basis * Vector3(b.x, b.y, 0),
			base + basis * Vector3(c.x, c.y, 0), n, n, n, Vector2(a.x, -a.y), Vector2(b.x, -b.y),
			Vector2(c.x, -c.y))

## Row of `count` arch panels at `pitch` centred on `base` along local X.
static func arcade(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, count: int,
		pitch: float, w: float, h: float, pointed: bool = true) -> void:
	for k in count:
		arch_panel(lm, key, base + basis * Vector3((float(k) - float(count - 1) * 0.5) * pitch, 0, 0),
			basis, w, h, pointed)

## Onion dome with `stripes` black marble stripes (needs seg = 2 x stripes).
static func striped_onion(lm: LandmarkMesh, white: String, black: String, base: Vector3,
		r: float, h: float, stripes: int = 16) -> void:
	U.onion(lm, white, base, r, h, stripes * 2)
	var da := TAU / float(stripes * 2)
	for s in stripes:
		var a0 := TAU * float(s) / float(stripes)
		var rows: Array = []
		for e in ONION:
			var rr := r * float(e[0]) * 1.012
			var y := h * float(e[1])
			rows.append(PackedVector3Array([base + Vector3(cos(a0) * rr, y, sin(a0) * rr),
				base + Vector3(cos(a0 + da) * rr, y, sin(a0 + da) * rr)]))
		lm.grid(black, rows, base + Vector3(0, h * 0.3, 0), true)

## Thick straight wall between two XZ points from y0 to y1.
static func wall_run(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, y0: float, y1: float,
		thick: float) -> void:
	var d := b - a
	var c := (a + b) * 0.5
	lm.box(key, Vector3(c.x, (y0 + y1) * 0.5, c.y), Vector3(d.length() + thick * 0.6, y1 - y0, thick),
		Basis(Vector3.UP, atan2(-d.y, d.x)))

## Row of merlons along a wall top at height y, one per `pitch` metres.
static func merlons(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, y: float,
		pitch: float, w: float, h: float, d: float) -> void:
	var n := maxi(int(a.distance_to(b) / pitch), 1)
	var bas := Basis(Vector3.UP, atan2(-(b - a).y, (b - a).x))
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box(key, Vector3(p.x, y + h * 0.5, p.y), Vector3(w, h, d), bas)

## Flight of `n` steps rising toward local -Z from `base` (ground level at
## the foot), w wide: the top step meets a platform n x rise high.
static func stairs(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, w: float,
		n: int, rise: float, run: float) -> void:
	for k in n:
		var hh := float(n - k) * rise
		lm.box(key, base + basis * Vector3(0, hh * 0.5, (float(k) + 0.5) * run),
			Vector3(w, hh, run), basis)

## Light kiosk for long walls: four pillars, a slab and an 8-sided dome
## (height pillar_h + 0.5 + dome_h).
static func kiosk(lm: LandmarkMesh, key: String, base: Vector3, w: float, pillar_h: float,
		dome_h: float) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(key, base + Vector3(sx * w * 0.4, pillar_h * 0.5, sz * w * 0.4),
				Vector3(w * 0.14, pillar_h, w * 0.14))
	lm.box(key, base + Vector3(0, pillar_h + 0.25, 0), Vector3(w, 0.5, w))
	U.dome(lm, key, base + Vector3(0, pillar_h + 0.5, 0), w * 0.46, dome_h, 8, 3)

## Round bastion: tapered tower of height h with a kiosk on top
## (total h + 2.7 + dome_h).
static func bastion(lm: LandmarkMesh, wall: String, cap: String, p: Vector3, r: float, h: float,
		dome_h: float = 2.4) -> void:
	lm.frustum(wall, p, r * 1.1, r, h, 8)
	lm.frustum(cap, p + Vector3(0, h, 0), r * 1.25, r * 1.25, 0.5, 8)
	kiosk(lm, cap, p + Vector3(0, h + 0.5, 0), r * 1.1, 1.7, dome_h)

## Mughal gate on `base` facing local +Z: arched block w x h x d with a
## passage open_w x open_h, a cornice, an octagonal turret with a kiosk at
## each end (turret_h) and `kiosks` small domed kiosks along the parapet.
static func gate(lm: LandmarkMesh, wall: String, trim: String, base: Vector3, basis: Basis,
		w: float, h: float, d: float, open_w: float, open_h: float, turret_r: float,
		turret_h: float, kiosks: int = 3) -> void:
	U.arch_wall(lm, wall, base, basis, w, h, d, open_w, open_h)
	lm.box(trim, base + basis * Vector3(0, h + 0.3, 0), Vector3(w + 0.8, 0.6, d + 0.8), basis)
	for sx in [-1.0, 1.0]:
		var p: Vector3 = base + basis * Vector3(sx * w * 0.5, 0, 0)
		lm.frustum(wall, p, turret_r * 1.1, turret_r, turret_h, 8)
		lm.frustum(trim, p + Vector3(0, turret_h - 0.5, 0), turret_r * 1.3, turret_r * 1.3, 0.5, 8)
		U.chhatri(lm, trim, trim, p + Vector3(0, turret_h, 0), turret_r * 1.3, 2.0, 2.5)
	for k in kiosks:
		var x := (float(k) - float(kiosks - 1) * 0.5) * w * 0.7 / float(maxi(kiosks - 1, 1))
		U.chhatri(lm, trim, trim, base + basis * Vector3(x, h + 0.6, 0), 2.4, 1.6, 1.8)

## Dravida gopura on `base` facing local +Z: an arched granite gate block
## (w x d, stone_h tall, passage open_w x open_h), `n` receding painted
## tiers of tier_h cycling through the `tiers` keys, a barrel (shala) roof
## and gilded finials along the ridge. Returns the height of the top.
static func gopura(lm: LandmarkMesh, stone: String, tiers: Array[String], gold: String, base: Vector3,
		basis: Basis, w: float, d: float, stone_h: float, n: int, tier_h: float, open_w: float,
		open_h: float) -> float:
	U.arch_wall(lm, stone, base, basis, w, stone_h, d, open_w, open_h)
	lm.box(stone, base + basis * Vector3(0, stone_h + 0.25, 0), Vector3(w + 1.0, 0.5, d + 1.0), basis)
	var y := stone_h + 0.5
	var f := 0.9
	for i in n:
		f = lerpf(0.9, 0.42, pow(float(i) / float(maxi(n - 1, 1)), 0.85))
		var key := tiers[i % tiers.size()]
		lm.box(key, base + basis * Vector3(0, y + tier_h * 0.5 - 0.2, 0),
			Vector3(w * f, tier_h - 0.4, d * f), basis)
		lm.box(stone, base + basis * Vector3(0, y + tier_h - 0.2, 0),
			Vector3(w * f + 1.0, 0.4, d * f + 1.0), basis)
		for sz in [-1.0, 1.0]:
			lm.box("Dark", base + basis * Vector3(0, y + tier_h * 0.45, sz * (d * f * 0.5 + 0.05)),
				Vector3(w * f * 0.8, tier_h * 0.35, 0.2), basis)
		y += tier_h
	var rise := d * f * 0.45
	lm.gable(tiers[(n + 1) % tiers.size()], base + basis * Vector3(0, y, 0), d * f, w * f, rise,
		basis * Basis(Vector3.UP, PI * 0.5), 0.4, tiers[(n + 1) % tiers.size()])
	for k in 7:
		U.finial(lm, gold, base + basis * Vector3((float(k) - 3.0) * w * f * 0.14, y + rise, 0), 2.4, 0.35)
	return y + rise + 2.4
