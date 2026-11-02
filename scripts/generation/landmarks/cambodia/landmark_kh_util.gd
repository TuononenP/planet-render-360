class_name LandmarkKhUtil
extends RefCounted

## Shared Khmer parts of the Cambodia landmark batch, in true metres on
## LandmarkMesh: lotus-bud crowns, redented prasat towers with false doors
## and pediments, face towers, naga balustrades, steep stairs, colonettes
## and tiered pavilion roofs with chofa finials. Every part takes the
## material KEYS to draw with (registered by the caller with lm.use) and
## builds upward from `base`.

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
## the middle, each ending in a snouted head, on a swollen neck, with the
## flaming halo arc that frames the fan.
static func naga_fan(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, heads: int,
		h: float) -> void:
	lm.box(key, base + basis * Vector3(0, h * 0.12, 0), Vector3(h * 0.46, h * 0.24, h * 0.34), basis)
	var amax := 0.5 + 0.06 * float(heads)
	var pivot := base + basis * Vector3(0, h * 0.2, 0)
	for i in heads:
		var t := (float(i) / float(heads - 1)) * 2.0 - 1.0
		var a := t * amax
		var reach := h * (1.0 - 0.3 * absf(t))
		var tip := pivot + basis * Vector3(sin(a) * reach, cos(a) * reach, 0.0)
		lm.beam(key, pivot, tip, h * 0.2, h * 0.07, basis * Vector3.RIGHT)
		lm.box(key, tip + basis * Vector3(0, h * 0.02, h * 0.06), Vector3(h * 0.17, h * 0.2, h * 0.2), basis)
		lm.box(key, tip + basis * Vector3(0, -h * 0.03, h * 0.18), Vector3(h * 0.08, h * 0.09, h * 0.14), basis)
	# Halo: a band of short segments round the heads.
	var segs := 7
	for i in segs:
		var a0 := (float(i) / float(segs) * 2.0 - 1.0) * (amax + 0.25)
		var a1 := (float(i + 1) / float(segs) * 2.0 - 1.0) * (amax + 0.25)
		var r0 := h * (1.14 - 0.26 * absf(a0) / amax)
		var r1 := h * (1.14 - 0.26 * absf(a1) / amax)
		lm.beam(key, pivot + basis * Vector3(sin(a0) * r0, cos(a0) * r0, -h * 0.04),
			pivot + basis * Vector3(sin(a1) * r1, cos(a1) * r1, -h * 0.04), h * 0.08, h * 0.06,
			basis * Vector3.BACK)

## Naga balustrade down a stair: the body runs from local (0, top_y, 0) down
## to (0, low_y, length) along basis +Z on short posts, ends in a raised fan
## of heads and curls up at the top. `w` is the body thickness.
static func naga_rail(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, length: float,
		top_y: float, low_y: float, w: float, heads: int = 5) -> void:
	var a := base + basis * Vector3(0, top_y + w * 0.5 + w * 0.6, 0)
	var b := base + basis * Vector3(0, low_y + w * 0.5 + w * 0.6, length)
	lm.beam(key, a, b, w, w, basis * Vector3.RIGHT, true)
	# Scale ridge along the back and the posts carrying the body.
	lm.beam(key, a + basis * Vector3(0, w * 0.5, 0), b + basis * Vector3(0, w * 0.5, 0), w * 0.3,
		w * 0.2, basis * Vector3.RIGHT)
	var posts := maxi(int(length / (w * 3.0)), 2)
	for i in posts:
		var t := (float(i) + 0.5) / float(posts)
		var p := a.lerp(b, t)
		lm.box(key, p - Vector3(0, w * 0.55, 0), Vector3(w * 0.7, w * 0.6, w * 0.7), basis, 0.0)
	lm.beam(key, a, a + basis * Vector3(0, w * 1.6, -w * 0.9), w * 0.7, w * 0.7, basis * Vector3.RIGHT)
	naga_fan(lm, key, b + basis * Vector3(0, -w * 0.9, 0), basis, heads, w * 2.6)

## Octagonal Khmer colonette of height h and radius r: moulded base, shaft
## ringed by two carved bands and a spreading capital.
static func colonette(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 8) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.35, 0), Vector2(r * 1.35, h * 0.06),
		Vector2(r, h * 0.1), Vector2(r, h * 0.3), Vector2(r * 1.2, h * 0.33), Vector2(r, h * 0.36),
		Vector2(r, h * 0.62), Vector2(r * 1.2, h * 0.65), Vector2(r, h * 0.68), Vector2(r, h * 0.88),
		Vector2(r * 1.4, h * 0.94), Vector2(r * 1.4, h)]), seg, 1.0, 1.0, PI / float(seg))

## Khmer doorway on a wall face: `base` is the sill centre on the face,
## the basis +Z points out of the wall. Jambs, octagonal colonettes, a
## carved lintel, the recessed (dark) door leaf or a sculpted false door,
## and the pediment above with its raking frame, upturned naga ends and a
## finial. w x h is the opening.
static func false_door(lm: LandmarkMesh, wall: String, dark: String, base: Vector3, b: Basis,
		w: float, h: float) -> void:
	var t := clampf(w * 0.14, 0.06, 0.5)
	lm.box(dark, base + b * Vector3(0, h * 0.5, 0.02), Vector3(w, h, 0.04), b, 0.0)
	for s in [-1.0, 1.0]:
		lm.box(wall, base + b * Vector3(s * (w * 0.5 + t * 0.5), h * 0.5, t * 0.5),
			Vector3(t, h, t), b, 0.0)
		colonette(lm, wall, base + b * Vector3(s * (w * 0.5 + t * 1.3), 0, t * 1.2), t * 0.45,
			h * 0.98, 6)
	var lt := h * 0.14
	lm.box(wall, base + b * Vector3(0, h + lt * 0.5, t * 0.7), Vector3(w + t * 4.4, lt, t * 1.4), b, 0.0)
	# Pediment: tympanum, raking frame, ends curling up, finial.
	var pw := w + t * 5.0
	var ph := h * 0.5
	var py := h + lt
	var c := base + b * Vector3(0, py, t * 0.6)
	lm.gable(wall, c, pw, t * 0.8, ph, b, 0.0, wall)
	for s in [-1.0, 1.0]:
		var lo := c + b * Vector3(s * pw * 0.5, 0, t * 0.3)
		var hi := c + b * Vector3(0, ph, t * 0.3)
		lm.beam(wall, lo, hi, t * 0.7, t * 0.6, b * Vector3.BACK)
		lm.beam(wall, lo, lo + b * Vector3(s * t * 1.4, t * 2.2, 0), t * 0.6, t * 0.5, b * Vector3.BACK)
	lm.spire(wall, c + b * Vector3(0, ph, t * 0.3), t * 0.5, t * 2.2, 0.0)

## Pediment of a hall gable end: the closed tympanum (wall), a raking frame
## of naga bodies (trim) ending in up-curled heads and a chofa horn at the
## apex. `c` is the eave-line centre of the gable end, basis +Z out of it,
## w the gable width, rise its height.
static func pediment(lm: LandmarkMesh, trim: String, c: Vector3, b: Basis, w: float,
		rise: float) -> void:
	for s in [-1.0, 1.0]:
		var lo := c + b * Vector3(s * w * 0.5, 0, 0.15)
		var hi := c + b * Vector3(0, rise, 0.15)
		lm.beam(trim, lo, hi, 0.28, 0.24, b * Vector3.BACK)
		# Hang hong: the naga tail-hooks along the rake.
		for k in 3:
			var p := lo.lerp(hi, 0.22 + 0.24 * float(k))
			lm.beam(trim, p, p + b * Vector3(s * 0.2, 0.55, 0.0), 0.16, 0.14, b * Vector3.BACK)
		lm.beam(trim, lo, lo + b * Vector3(s * 0.5, 0.8, 0.1), 0.22, 0.2, b * Vector3.BACK)
	var apex := c + b * Vector3(0, rise, 0.15)
	lm.beam(trim, apex, apex + b * Vector3(0, rise * 0.28 + 0.6, 0.5), 0.24, 0.22, b * Vector3.RIGHT)

## Lotus-bud sanctuary tower of total height h: a moulded plinth, `tiers`
## receding redented storeys (projecting avant-corps with false doors and
## pediments, stepped corner pilasters, antefixes along each eave) and the
## lotus-bud crown taking `crown` of the height. `hw` is the half-width of
## the lowest storey. `nagas` puts a hooded naga on every storey corner
## instead of a pinnacle.
static func prasat(lm: LandmarkMesh, wall: String, roof: String, dark: String, base: Vector3,
		hw: float, h: float, tiers: int = 4, crown: float = 0.26, shrink: float = 0.8,
		nagas: bool = false) -> void:
	var crown_h := h * crown
	var body_h := h - crown_h
	var plinth_h := body_h * 0.12
	# Plinth: base, recessed die, cornice.
	lm.box(wall, base + Vector3(0, plinth_h * 0.15, 0), Vector3(hw * 2.45, plinth_h * 0.3, hw * 2.45))
	lm.box(wall, base + Vector3(0, plinth_h * 0.55, 0), Vector3(hw * 2.25, plinth_h * 0.5, hw * 2.25))
	lm.box(roof, base + Vector3(0, plinth_h * 0.9, 0), Vector3(hw * 2.4, plinth_h * 0.2, hw * 2.4))
	var storey_h := (body_h - plinth_h) / float(tiers)
	var y := plinth_h
	var w := hw
	for k in tiers:
		var wall_h := storey_h * 0.62
		lm.box(wall, base + Vector3(0, y + wall_h * 0.5, 0), Vector3(w * 2.0, wall_h, w * 2.0))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			# Avant-corps carrying the door, stepped corner pilasters.
			lm.box(wall, base + b * Vector3(0, y + wall_h * 0.5, w + w * 0.06),
				Vector3(w * 0.9, wall_h, w * 0.12), b)
			for sx in [-1.0, 1.0]:
				lm.box(wall, base + b * Vector3(sx * w * 0.86, y + wall_h * 0.5, w + w * 0.03),
					Vector3(w * 0.2, wall_h, w * 0.06), b, 0.0)
			var dw := w * 0.42
			var dh := wall_h * 0.56
			if k == 0 or dh > 0.6:
				false_door(lm, wall, dark, base + b * Vector3(0, y + wall_h * 0.05, w + w * 0.12), b,
					dw, dh)
			else:
				lm.box(dark, base + b * Vector3(0, y + wall_h * 0.38, w + w * 0.13),
					Vector3(dw, dh, 0.06), b, 0.0)
			# Antefixes along the eave between the corners.
			for t in [-0.55, 0.55]:
				lm.spire(roof, base + b * Vector3(t * w, y + wall_h + storey_h * 0.08, w * 0.98),
					w * 0.09, storey_h * 0.26, 0.0)
		var ce := y + wall_h
		lm.box(wall, base + Vector3(0, ce + storey_h * 0.04, 0),
			Vector3(w * 2.2, storey_h * 0.08, w * 2.2))
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
					lm.frustum(roof, cp, w * 0.13, w * 0.1, sh * 0.25, 8)
					lotus_bud(lm, roof, cp + Vector3(0, sh * 0.25, 0), w * 0.11, sh * 0.5, 6)
		y += storey_h
		w *= shrink
	lotus_bud(lm, roof, base + Vector3(0, y, 0), w * 1.02, crown_h, 16)

## Four-faced Bayon-style tower of total height h and width w: moulded
## plinth, a redented face block carrying on every side the serene smiling
## face (diadem with pendants, brows, lidded eyes, nose, full lips, long
## earlobes), a three-step headdress with antefixes and the lotus-bud top.
static func face_tower(lm: LandmarkMesh, stone: String, dark: String, base: Vector3, w: float,
		h: float) -> void:
	var plinth := h * 0.26
	var face_h := h * 0.36
	var hat_h := h - plinth - face_h
	lm.box(stone, base + Vector3(0, plinth * 0.12, 0), Vector3(w * 1.18, plinth * 0.24, w * 1.18))
	lm.box(stone, base + Vector3(0, plinth * 0.55, 0), Vector3(w * 1.06, plinth * 0.62, w * 1.06))
	lm.box(stone, base + Vector3(0, plinth * 0.93, 0), Vector3(w * 1.14, plinth * 0.14, w * 1.14))
	var fy := plinth
	lm.box(stone, base + Vector3(0, fy + face_h * 0.5, 0), Vector3(w * 0.92, face_h, w * 0.92))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var z := w * 0.46
		# Face panel standing proud of the redented block.
		lm.box(stone, base + b * Vector3(0, fy + face_h * 0.5, z + w * 0.03),
			Vector3(w * 0.8, face_h * 0.96, w * 0.06), b, 0.0)
		var fz := z + w * 0.06
		var fp := func(x: float, yy: float, dz: float) -> Vector3:
			return base + b * Vector3(x, fy + face_h * yy, fz + dz)
		# Diadem band with jewel pendants.
		lm.box(stone, fp.call(0.0, 0.84, w * 0.02), Vector3(w * 0.78, face_h * 0.08, w * 0.05), b, 0.0)
		for j in 5:
			var jx := (float(j) - 2.0) * w * 0.15
			lm.box(stone, fp.call(jx, 0.78, w * 0.035), Vector3(w * 0.06, face_h * 0.06, w * 0.04), b, 0.0)
		# Brows, lidded eyes, nose, lips, chin and the long earlobes.
		for sx in [-1.0, 1.0]:
			lm.beam(stone, fp.call(sx * w * 0.05, 0.68, w * 0.03), fp.call(sx * w * 0.3, 0.64, w * 0.02),
				face_h * 0.04, w * 0.04, b * Vector3.BACK)
			lm.box(dark, fp.call(sx * w * 0.17, 0.6, w * 0.005), Vector3(w * 0.17, face_h * 0.05, 0.04), b, 0.0)
			lm.beam(stone, fp.call(sx * w * 0.09, 0.62, w * 0.025), fp.call(sx * w * 0.26, 0.62, w * 0.02),
				face_h * 0.035, w * 0.03, b * Vector3.BACK)
			lm.box(stone, fp.call(sx * w * 0.39, 0.42, w * 0.0), Vector3(w * 0.05, face_h * 0.36, w * 0.05), b, 0.0)
			lm.box(stone, fp.call(sx * w * 0.2, 0.36, w * 0.015), Vector3(w * 0.12, face_h * 0.16, w * 0.03), b, 0.0)
			lm.beam(stone, fp.call(sx * w * 0.02, 0.23, w * 0.05), fp.call(sx * w * 0.12, 0.25, w * 0.035),
				face_h * 0.03, w * 0.03, b * Vector3.BACK)
		lm.beam(stone, fp.call(0.0, 0.63, w * 0.02), fp.call(0.0, 0.38, w * 0.08), w * 0.07, w * 0.05,
			b * Vector3.RIGHT)
		lm.box(stone, fp.call(0.0, 0.37, w * 0.06), Vector3(w * 0.12, face_h * 0.05, w * 0.06), b, 0.0)
		lm.box(stone, fp.call(0.0, 0.25, w * 0.045), Vector3(w * 0.16, face_h * 0.035, w * 0.04), b, 0.0)
		lm.box(stone, fp.call(0.0, 0.2, w * 0.04), Vector3(w * 0.14, face_h * 0.035, w * 0.035), b, 0.0)
		lm.box(dark, fp.call(0.0, 0.225, w * 0.035), Vector3(w * 0.15, face_h * 0.012, w * 0.03), b, 0.0)
		lm.box(stone, fp.call(0.0, 0.1, w * 0.02), Vector3(w * 0.18, face_h * 0.08, w * 0.04), b, 0.0)
		# Headdress antefix above the diadem.
		lm.spire(stone, base + b * Vector3(0, fy + face_h, z + w * 0.02), w * 0.12, hat_h * 0.18, 0.0)
	# Headdress: three receding steps, corner petals, lotus top.
	var hy := fy + face_h
	for q in 3:
		var sw := w * (1.08 - 0.14 * float(q))
		lm.box(stone, base + Vector3(0, hy + hat_h * (0.03 + 0.06 * float(q)), 0),
			Vector3(sw, hat_h * 0.06, sw))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.spire(stone, base + Vector3(sx * w * 0.4, hy + hat_h * 0.06, sz * w * 0.4), w * 0.08,
				hat_h * 0.2, 0.0)
	lotus_bud(lm, stone, base + Vector3(0, hy + hat_h * 0.18, 0), w * 0.42, hat_h * 0.82, 10)

## Tiered Khmer pavilion roof over a w x l footprint (ridge along the basis
## Z): `tiers` stacked gables, each narrower and higher, ridge caps, the
## naga-framed pediment and a chofa horn at both gable ends of every tier.
## `c` is the eave centre.
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
			var eb := Basis(basis.y.normalized(), PI if s < 0.0 else 0.0) * basis
			pediment(lm, trim, yk + basis * Vector3(0, 0, lk * 0.5 * s), eb, wk, rk)
			# Eave fascia along both long sides.
			lm.beam(trim, yk + basis * Vector3(s * (wk * 0.5 + 0.8), 0, -lk * 0.5 - 0.4),
				yk + basis * Vector3(s * (wk * 0.5 + 0.8), 0, lk * 0.5 + 0.4), 0.12, 0.3, basis * Vector3.UP)

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

## Raised Khmer hall along the basis Z: moulded plinth, walls with framed
## windows under small pediments, `cols` lotus-capital posts a side with
## eave brackets, and a tiered roof with naga pediments and chofa.
## Returns the y of the highest ridge cap.
static func hall(lm: LandmarkMesh, wall: String, trim: String, roof: String, post: String,
		base: Vector3, basis: Basis, w: float, l: float, plinth: float, wall_h: float,
		rise: float, tiers: int = 2, cols: int = 0) -> float:
	if plinth > 0.0:
		lm.box(trim, base + basis * Vector3(0, plinth * 0.5, 0), Vector3(w + 3.0, plinth, l + 3.0), basis)
		lm.box(trim, base + basis * Vector3(0, plinth * 0.12, 0), Vector3(w + 3.4, plinth * 0.24, l + 3.4), basis)
		lm.box(trim, base + basis * Vector3(0, plinth * 0.92, 0), Vector3(w + 3.3, plinth * 0.16, l + 3.3), basis)
	lm.box(wall, base + basis * Vector3(0, plinth + wall_h * 0.5, 0), Vector3(w, wall_h, l), basis)
	lm.box(trim, base + basis * Vector3(0, plinth + 0.25, 0), Vector3(w + 0.3, 0.5, l + 0.3), basis)
	# Windows down both long walls, a doorway in each end.
	var nwin := maxi(int(l / 3.6), 1)
	var wh := minf(wall_h * 0.5, 2.6)
	var ww := minf(wh * 0.55, 1.3)
	for s in [-1.0, 1.0]:
		var sb := Basis(basis.y.normalized(), PI * 0.5 * s) * basis
		for i in nwin:
			var z := -l * 0.5 + l * (float(i) + 0.5) / float(nwin)
			var c := base + basis * Vector3(s * w * 0.5, plinth + wall_h * 0.28, z)
			lm.box(post, c + sb * Vector3(0, wh * 0.5, 0.02), Vector3(ww, wh, 0.1), sb, 0.0)
			lm.box(trim, c + sb * Vector3(0, -0.08, 0.1), Vector3(ww + 0.4, 0.16, 0.24), sb, 0.0)
			lm.box(trim, c + sb * Vector3(0, wh + 0.08, 0.1), Vector3(ww + 0.4, 0.16, 0.24), sb, 0.0)
			lm.gable(trim, c + sb * Vector3(0, wh + 0.16, 0.1), ww + 0.5, 0.2, 0.45, sb, 0.0, trim)
		var eb := Basis(basis.y.normalized(), 0.0 if s > 0.0 else PI) * basis
		var dc := base + basis * Vector3(0, plinth, s * l * 0.5)
		false_door(lm, trim, post, dc, eb, minf(w * 0.18, 1.8), minf(wall_h * 0.62, 3.4))
	for s in [-1.0, 1.0]:
		for i in cols:
			var z := -l * 0.5 + 1.0 + (l - 2.0) * float(i) / float(maxi(cols - 1, 1))
			var pb := base + basis * Vector3(s * (w * 0.5 + 0.7), plinth, z)
			colonette(lm, post, pb, 0.32, wall_h, 8)
			# Kbach bracket from the capital up to the eave.
			lm.beam(post, pb + Vector3(0, wall_h * 0.82, 0), pb + basis * Vector3(s * 0.7, wall_h + 0.2, 0),
				0.16, 0.24, basis * Vector3.BACK)
	var eave := plinth + wall_h
	lm.box(trim, base + basis * Vector3(0, eave + 0.2, 0), Vector3(w + 2.0, 0.4, l + 2.0), basis)
	tiered_roof(lm, roof, trim, wall, base + basis * Vector3(0, eave + 0.4, 0), basis, w + 1.0,
		l + 1.0, rise, tiers)
	return base.y + eave + 0.4 + rise * (0.62 * float(tiers - 1) \
		+ (1.0 - 0.22 * float(tiers - 1)))

## Bell stupa of total height h on a three-step redented base, a moulded
## bell, the harmika box, ringed spire and a gilded tip; `bell` draws the
## body, `gold` the finial.
static func stupa(lm: LandmarkMesh, bell: String, gold: String, base: Vector3, r: float,
		h: float) -> void:
	for q in 3:
		var bw := r * (2.8 - 0.3 * float(q))
		lm.box(bell, base + Vector3(0, h * (0.025 + 0.04 * float(q)), 0), Vector3(bw, h * 0.04, bw))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box(bell, base + b * Vector3(0, h * (0.025 + 0.04 * float(q)), bw * 0.5 + r * 0.06),
				Vector3(bw * 0.5, h * 0.04, r * 0.12), b, 0.0)
	lm.lathe(bell, base + Vector3(0, h * 0.125, 0), PackedVector2Array([Vector2(r * 0.95, 0),
		Vector2(r * 1.0, h * 0.02), Vector2(r * 0.92, h * 0.035), Vector2(r * 0.98, h * 0.06),
		Vector2(r * 0.88, h * 0.1), Vector2(r * 0.8, h * 0.2), Vector2(r * 0.66, h * 0.26),
		Vector2(r * 0.55, h * 0.3), Vector2(r * 0.62, h * 0.32), Vector2(r * 0.6, h * 0.34),
		Vector2(r * 0.4, h * 0.42), Vector2(r * 0.44, h * 0.44), Vector2(r * 0.32, h * 0.5),
		Vector2(r * 0.36, h * 0.52), Vector2(r * 0.22, h * 0.555), Vector2(r * 0.1, h * 0.575)]), 20)
	# Ringed spire (the stacked parasols).
	var sy := h * 0.7
	for q in 5:
		var rr := r * (0.22 - 0.03 * float(q))
		lm.frustum(bell, base + Vector3(0, h * (0.58 + 0.025 * float(q)), 0), rr * 1.15, rr, h * 0.022, 12)
	lm.lathe(gold, base + Vector3(0, sy, 0), PackedVector2Array([Vector2(r * 0.12, 0),
		Vector2(r * 0.3, h * 0.05), Vector2(r * 0.1, h * 0.1), Vector2(r * 0.2, h * 0.17),
		Vector2(r * 0.08, h * 0.2), Vector2(r * 0.12, h * 0.23), Vector2(0.0, h * 0.3)]), 10)

## Small shrine tower (moulded plinth, body with doors on four sides,
## two-step spire, finial) of total height h and half-width hw: the many
## minor towers of temple-mountain terraces.
static func small_tower(lm: LandmarkMesh, key: String, base: Vector3, hw: float, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.06, 0), Vector3(hw * 2.6, h * 0.12, hw * 2.6))
	lm.box(key, base + Vector3(0, h * 0.21, 0), Vector3(hw * 2.3, h * 0.18, hw * 2.3))
	lm.box(key, base + Vector3(0, h * 0.45, 0), Vector3(hw * 2.0, h * 0.3, hw * 2.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box(key, base + b * Vector3(0, h * 0.44, hw + 0.05), Vector3(hw * 0.8, h * 0.24, 0.1), b, 0.0)
	lm.box(key, base + Vector3(0, h * 0.62, 0), Vector3(hw * 2.25, h * 0.04, hw * 2.25), Basis(), 0.0)
	lm.spire(key, base + Vector3(0, h * 0.64, 0), hw * 1.1, h * 0.22, hw * 0.65)
	lm.spire(key, base + Vector3(0, h * 0.86, 0), hw * 0.65, h * 0.14, 0.0)
