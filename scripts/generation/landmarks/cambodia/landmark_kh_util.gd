class_name LandmarkKhUtil
extends RefCounted

## Shared Khmer parts of the Cambodia landmark batch, in true metres on
## LandmarkMesh: lotus-bud crowns, stepped prasat towers, face towers,
## naga balustrades, steep stairs and tiered pavilion roofs. Every part
## takes the material KEYS to draw with (registered by the caller with
## lm.use) and builds upward from `base`.

## Lotus-bud crown (ribbed receding rings, then the bud) of radius r, height h.
static func lotus_bud(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 12) -> void:
	var t := [[0.9, 0.0], [1.0, 0.05], [0.84, 0.11], [1.0, 0.19], [0.82, 0.29], [0.94, 0.37],
		[0.68, 0.5], [0.78, 0.56], [0.5, 0.72], [0.55, 0.76], [0.26, 0.9], [0.1, 0.97], [0.0, 1.0]]
	var p := PackedVector2Array()
	for e in t:
		p.append(Vector2(r * float(e[0]), h * float(e[1])))
	lm.lathe(key, base, p, seg)

## Steep stair whose top step meets local (0, top, 0) of `base`, running out
## along the basis +Z; `n` boxes of depth `tread`, `riser` high each.
static func stair(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, width: float,
		n: int, tread: float, riser: float) -> void:
	for k in n:
		var hgt := riser * float(n - k)
		lm.box(key, base + basis * Vector3(0, hgt * 0.5, tread * (float(k) + 0.5)),
			Vector3(width, hgt, tread), basis)

## Fan of hooded naga heads rising from `base` (spread across local X,
## facing local +Z): `heads` flat hoods fanned up to +-0.9 rad, tallest in
## the middle, each ending in a snouted head, on a swollen neck.
static func naga_fan(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, heads: int,
		h: float) -> void:
	lm.box(key, base + basis * Vector3(0, h * 0.12, 0), Vector3(h * 0.46, h * 0.24, h * 0.34), basis)
	var amax := 0.5 + 0.06 * float(heads)
	for i in heads:
		var t := (float(i) / float(heads - 1)) * 2.0 - 1.0
		var a := t * amax
		var reach := h * (1.0 - 0.3 * absf(t))
		var pivot := base + basis * Vector3(0, h * 0.2, 0)
		var tip := pivot + basis * Vector3(sin(a) * reach, cos(a) * reach, 0.0)
		lm.beam(key, pivot, tip, h * 0.2, h * 0.07, basis * Vector3.RIGHT)
		lm.box(key, tip + basis * Vector3(0, h * 0.02, h * 0.06), Vector3(h * 0.17, h * 0.2, h * 0.2), basis)
		lm.box(key, tip + basis * Vector3(0, -h * 0.03, h * 0.18), Vector3(h * 0.08, h * 0.09, h * 0.14), basis)

## Naga balustrade down a stair: the body runs from local (0, top_y, 0) down
## to (0, low_y, length) along basis +Z, ends in a raised fan of heads and
## curls up at the top. `w` is the body thickness.
static func naga_rail(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, length: float,
		top_y: float, low_y: float, w: float, heads: int = 5) -> void:
	var a := base + basis * Vector3(0, top_y + w * 0.5, 0)
	var b := base + basis * Vector3(0, low_y + w * 0.5, length)
	lm.beam(key, a, b, w, w, basis * Vector3.RIGHT, true)
	lm.beam(key, a, a + basis * Vector3(0, w * 1.6, -w * 0.9), w * 0.7, w * 0.7, basis * Vector3.RIGHT)
	naga_fan(lm, key, b + basis * Vector3(0, -w * 0.3, 0), basis, heads, w * 2.6)

## Lotus-bud sanctuary tower of total height h: a plinth, `tiers` receding
## storeys (false doors, pediments, eave slabs, corner spires) and the
## lotus-bud crown taking `crown` of the height. `hw` is the half-width of
## the lowest storey. `nagas` puts a hooded naga on every storey corner
## instead of a pinnacle.
static func prasat(lm: LandmarkMesh, wall: String, roof: String, dark: String, base: Vector3,
		hw: float, h: float, tiers: int = 4, crown: float = 0.26, shrink: float = 0.8,
		nagas: bool = false) -> void:
	var crown_h := h * crown
	var body_h := h - crown_h
	var plinth_h := body_h * 0.12
	lm.box(wall, base + Vector3(0, plinth_h * 0.5, 0), Vector3(hw * 2.3, plinth_h, hw * 2.3))
	var storey_h := (body_h - plinth_h) / float(tiers)
	var y := plinth_h
	var w := hw
	for k in tiers:
		var wall_h := storey_h * 0.62
		lm.box(wall, base + Vector3(0, y + wall_h * 0.5, 0), Vector3(w * 2.0, wall_h, w * 2.0))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box(wall, base + b * Vector3(0, y + wall_h * 0.42, w + 0.12),
				Vector3(w * 0.6, wall_h * 0.76, 0.3), b)
			lm.box(dark, base + b * Vector3(0, y + wall_h * 0.38, w + 0.3),
				Vector3(w * 0.36, wall_h * 0.62, 0.12), b)
			lm.gable(roof, base + b * Vector3(0, y + wall_h * 0.78, w + 0.12), w * 0.6, 0.3,
				wall_h * 0.32, b, 0.0, wall)
		var ce := y + wall_h
		lm.box(wall, base + Vector3(0, ce + storey_h * 0.04, 0),
			Vector3(w * 2.16, storey_h * 0.08, w * 2.16))
		var sh := storey_h * 0.3
		var step_w := [1.07, 0.98, 0.9]
		for q in 3:
			var sw: float = w * float(step_w[q]) * 2.0
			lm.box(roof, base + Vector3(0, ce + storey_h * 0.08 + sh * (float(q) + 0.5) / 3.0, 0),
				Vector3(sw, sh / 3.0, sw))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var cp := base + Vector3(sx * w * 0.92, ce + storey_h * 0.08 + sh / 3.0, sz * w * 0.92)
				if nagas:
					naga_fan(lm, roof, cp, Basis(Vector3.UP, atan2(sx, sz)), 3, sh * 1.7)
				else:
					lm.spire(roof, cp, w * 0.12, sh * 0.5, 0.0)
		y += storey_h
		w *= shrink
	lotus_bud(lm, roof, base + Vector3(0, y, 0), w * 1.02, crown_h)

## Four-faced Bayon-style tower of total height h and width w: plinth, a
## face block (brows, noses, eye slits, smile on every side), a headdress
## tier and the lotus-bud top. `dark` draws the recesses.
static func face_tower(lm: LandmarkMesh, stone: String, dark: String, base: Vector3, w: float,
		h: float) -> void:
	var plinth := h * 0.26
	var face_h := h * 0.36
	var hat_h := h - plinth - face_h
	lm.box(stone, base + Vector3(0, plinth * 0.5, 0), Vector3(w * 1.12, plinth, w * 1.12))
	var fy := plinth
	lm.box(stone, base + Vector3(0, fy + face_h * 0.5, 0), Vector3(w, face_h, w))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var z := w * 0.5
		lm.box(stone, base + b * Vector3(0, fy + face_h * 0.5, z + w * 0.07),
			Vector3(w * 0.12, face_h * 0.4, w * 0.14), b)
		lm.box(stone, base + b * Vector3(0, fy + face_h * 0.74, z + w * 0.03),
			Vector3(w * 0.72, face_h * 0.1, w * 0.07), b)
		for sx in [-1.0, 1.0]:
			lm.box(dark, base + b * Vector3(sx * w * 0.22, fy + face_h * 0.6, z + 0.02),
				Vector3(w * 0.2, face_h * 0.11, 0.12), b)
		lm.box(dark, base + b * Vector3(0, fy + face_h * 0.26, z + 0.02),
			Vector3(w * 0.34, face_h * 0.07, 0.12), b)
	lm.box(stone, base + Vector3(0, fy + face_h + hat_h * 0.06, 0),
		Vector3(w * 1.08, hat_h * 0.12, w * 1.08))
	lotus_bud(lm, stone, base + Vector3(0, fy + face_h + hat_h * 0.12, 0), w * 0.44, hat_h * 0.88, 8)

## Tiered Khmer pavilion roof over a w x l footprint (ridge along the basis
## Z): `tiers` stacked gables, each narrower and higher, ridge caps and
## up-swept naga-horn finials at the ridge ends. `c` is the eave centre.
static func tiered_roof(lm: LandmarkMesh, roof: String, trim: String, gable_key: String,
		c: Vector3, basis: Basis, w: float, l: float, rise: float, tiers: int = 2) -> void:
	for k in tiers:
		var f := 1.0 - 0.22 * float(k)
		var wk := w * f
		var lk := l * (1.0 - 0.1 * float(k))
		var yk := c + basis * Vector3(0, rise * 0.62 * float(k), 0)
		var rk := rise * (0.62 if k < tiers - 1 else 1.0) * f
		lm.gable(roof, yk, wk, lk, rk, basis, 0.8, gable_key)
		var ridge := yk + basis * Vector3(0, rk, 0)
		lm.beam(trim, ridge - basis * Vector3(0, 0, lk * 0.5), ridge + basis * Vector3(0, 0, lk * 0.5),
			0.3, 0.3, basis * Vector3.RIGHT)
		for s in [-1.0, 1.0]:
			var e := ridge + basis * Vector3(0, 0, lk * 0.5 * s)
			lm.beam(trim, e, e + basis * Vector3(0, rk * 0.5, 0.9 * s), 0.3, 0.3, basis * Vector3.RIGHT)

## Row of square columns along a..b at `n` points, `h` tall.
static func columns(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, h: float,
		w: float) -> void:
	for i in n:
		var p := a.lerp(b, float(i) / float(maxi(n - 1, 1)))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(w, h, w))

## Capped wall run along a..b (ground points): `h` tall, `t` thick, with a
## cap slab that overhangs by `cap`.
static func wall_run(lm: LandmarkMesh, key: String, cap_key: String, a: Vector3, b: Vector3,
		h: float, t: float, cap: float = 0.1) -> void:
	var d := b - a
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	var m := (a + b) * 0.5
	lm.box(key, m + Vector3(0, h * 0.5, 0), Vector3(t, h, d.length()), basis)
	lm.box(cap_key, m + Vector3(0, h + 0.1, 0), Vector3(t + cap * 2.0, 0.2, d.length() + cap), basis)

## Raised Khmer hall along the basis Z: plinth, walls, `cols` posts a side
## and a tiered gabled roof. Returns the y of the highest ridge cap.
static func hall(lm: LandmarkMesh, wall: String, trim: String, roof: String, post: String,
		base: Vector3, basis: Basis, w: float, l: float, plinth: float, wall_h: float,
		rise: float, tiers: int = 2, cols: int = 0) -> float:
	lm.box(trim, base + basis * Vector3(0, plinth * 0.5, 0), Vector3(w + 3.0, plinth, l + 3.0), basis)
	lm.box(wall, base + basis * Vector3(0, plinth + wall_h * 0.5, 0), Vector3(w, wall_h, l), basis)
	for s in [-1.0, 1.0]:
		for i in cols:
			var z := -l * 0.5 + 1.0 + (l - 2.0) * float(i) / float(maxi(cols - 1, 1))
			lm.box(post, base + basis * Vector3(s * (w * 0.5 + 0.7), plinth + wall_h * 0.5, z),
				Vector3(0.7, wall_h, 0.7), basis)
	var eave := plinth + wall_h
	lm.box(trim, base + basis * Vector3(0, eave + 0.2, 0), Vector3(w + 2.0, 0.4, l + 2.0), basis)
	tiered_roof(lm, roof, trim, wall, base + basis * Vector3(0, eave + 0.4, 0), basis, w + 1.0,
		l + 1.0, rise, tiers)
	return base.y + eave + 0.4 + rise * (0.62 * float(tiers - 1) \
		+ (1.0 - 0.22 * float(tiers - 1)))

## Bell stupa of total height h on a two-step square base, a ringed spire
## and a gilded tip; `bell` draws the body, `gold` the finial.
static func stupa(lm: LandmarkMesh, bell: String, gold: String, base: Vector3, r: float,
		h: float) -> void:
	lm.box(bell, base + Vector3(0, h * 0.04, 0), Vector3(r * 2.8, h * 0.08, r * 2.8))
	lm.box(bell, base + Vector3(0, h * 0.1, 0), Vector3(r * 2.2, h * 0.08, r * 2.2))
	lm.lathe(bell, base + Vector3(0, h * 0.14, 0), PackedVector2Array([Vector2(r * 0.95, 0),
		Vector2(r * 1.0, h * 0.06), Vector2(r * 0.8, h * 0.2), Vector2(r * 0.55, h * 0.3),
		Vector2(r * 0.6, h * 0.34), Vector2(r * 0.4, h * 0.42), Vector2(r * 0.32, h * 0.5),
		Vector2(r * 0.1, h * 0.56)]), 14)
	lm.lathe(gold, base + Vector3(0, h * 0.7, 0), PackedVector2Array([Vector2(r * 0.12, 0),
		Vector2(r * 0.3, h * 0.05), Vector2(r * 0.1, h * 0.1), Vector2(r * 0.2, h * 0.17),
		Vector2(0.0, h * 0.3)]), 8)

## Small shrine tower (plinth, body, two-step spire) of total height h and
## half-width hw: the many minor towers of temple-mountain terraces.
static func small_tower(lm: LandmarkMesh, key: String, base: Vector3, hw: float, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.15, 0), Vector3(hw * 2.4, h * 0.3, hw * 2.4))
	lm.box(key, base + Vector3(0, h * 0.45, 0), Vector3(hw * 2.0, h * 0.3, hw * 2.0))
	lm.spire(key, base + Vector3(0, h * 0.6, 0), hw * 1.1, h * 0.26, hw * 0.65)
	lm.spire(key, base + Vector3(0, h * 0.86, 0), hw * 0.65, h * 0.14, 0.0)
