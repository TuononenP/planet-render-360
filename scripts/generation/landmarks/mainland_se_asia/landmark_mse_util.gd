class_name LandmarkMseUtil
extends RefCounted

## Shared parts of the mainland south-east Asia landmark batch, in true
## metres on LandmarkMesh: up-swept gabled roofs, stacked Thai roof tiers,
## tiered prasat spires, bell chedis, Khmer-style prangs, crenellated wall
## runs, stairs and covered cloisters. Every part takes the material KEYS
## to draw with (registered by the caller with lm.use) and builds upward
## from its base point; a Basis turns the part about the vertical.

## Roof height at across-ridge t and along-ridge s (both -1..1): a concave
## slope, steep under the ridge and flat at the eaves, the eave ends and
## the ridge ends swept up by `lift`.
static func _roof_y(t: float, s: float, rise: float, lift: float) -> float:
	return rise * pow(1.0 - absf(t), 1.5) + lift * pow(absf(s), 3.0) * (0.2 + absf(t))

## Up-swept gabled roof over a w x l footprint centred on `c` (eave level),
## ridge along basis Z, `rise` high, eave overhang `over`. `trim` (if set)
## draws the ridge cap and the up-curled horns (`horn` m high) at the ridge ends,
## `gable_key` (if set) closes the two end walls.
static func swept_roof(lm: LandmarkMesh, key: String, trim: String, gable_key: String, c: Vector3,
		basis: Basis, w: float, l: float, rise: float, lift: float = 0.0, over: float = 0.8,
		horn: float = 1.8) -> void:
	var hx := w * 0.5 + over
	var hz := l * 0.5 + over * 0.5
	var rows: Array = []
	for j in 9:
		var t := float(j) / 4.0 - 1.0
		var row := PackedVector3Array()
		for i in 7:
			var s := float(i) / 3.0 - 1.0
			row.append(c + basis * Vector3(t * hx, _roof_y(t, s, rise, lift), s * hz))
		rows.append(row)
	lm.grid(key, rows, basis.y)
	# Soffit slab so the eaves read solid from below.
	lm.box(key, c + basis * Vector3(0, -0.12, 0), Vector3(hx * 2.0, 0.24, hz * 2.0), basis)
	if gable_key != "":
		var tm := (w * 0.5) / hx
		for sgn in [-1.0, 1.0]:
			var z: float = sgn * l * 0.5
			var s: float = z / hz
			for j in 8:
				var t0 := -tm + 2.0 * tm * float(j) / 8.0
				var t1 := -tm + 2.0 * tm * float(j + 1) / 8.0
				lm.quad(gable_key, c + basis * Vector3(t0 * hx, 0, z), c + basis * Vector3(t1 * hx, 0, z),
					c + basis * Vector3(t1 * hx, _roof_y(t1, s, rise, lift) - 0.1, z),
					c + basis * Vector3(t0 * hx, _roof_y(t0, s, rise, lift) - 0.1, z), basis * Vector3(0, 0, sgn))
	if trim != "":
		var ry := rise + lift * 0.1
		lm.beam(trim, c + basis * Vector3(0, ry, -hz), c + basis * Vector3(0, ry, hz), 0.5, 0.5, basis.x)
		for sgn in [-1.0, 1.0]:
			var e: Vector3 = c + basis * Vector3(0, ry, hz * sgn)
			lm.beam(trim, e, e + basis * Vector3(0, horn + lift, 0.9 * sgn), 0.4, 0.4, basis.x)

## Row of slim spikes (flame finials) along both eave edges of a swept
## roof built with the same arguments, one every `step` metres, `h` tall.
static func eave_spikes(lm: LandmarkMesh, key: String, c: Vector3, basis: Basis, w: float, l: float,
		rise: float, lift: float, over: float, step: float, h: float) -> void:
	var hx := w * 0.5 + over
	var hz := l * 0.5 + over * 0.5
	var n := maxi(int(l / step), 1)
	for sgn in [-1.0, 1.0]:
		for i in n + 1:
			var s := -1.0 + 2.0 * float(i) / float(n)
			lm.spire(key, c + basis * Vector3(sgn * hx, _roof_y(sgn, s, rise, lift), s * hz), 0.2, h, 0.0)

## Stacked Thai roof: `tiers` swept roofs, each narrower and set higher on
## a short clerestory wall. `c` is the lowest eave centre. Returns the y
## (relative to c) of the highest ridge.
static func tiered_roof(lm: LandmarkMesh, wall: String, tile: String, trim: String, c: Vector3,
		basis: Basis, w: float, l: float, rise: float, tiers: int, lift: float = 1.0) -> float:
	var y := 0.0
	for k in tiers:
		var f := 1.0 - 0.2 * float(k)
		var wk := w * f
		var lk := l * (1.0 - 0.12 * float(k))
		swept_roof(lm, tile, trim, wall, c + basis * Vector3(0, y, 0), basis, wk, lk, rise * f, lift, 1.0)
		var gap := 1.6
		if k < tiers - 1:
			var wn := w * (f - 0.2)
			var ln := l * (1.0 - 0.12 * float(k + 1))
			lm.box(wall, c + basis * Vector3(0, y + (rise * f + gap) * 0.5, 0),
				Vector3(wn, rise * f + gap, ln), basis)
			y += rise * f + gap
		else:
			y += rise * f
	return y

## Thai multi-tier prasat spire of total height h: `tiers` receding square
## storeys under swept pyramid roofs, a small corner spike on each, and
## the gilded crown bud with its needle taking the top 22% of the height.
static func prasat_spire(lm: LandmarkMesh, wall: String, tile: String, gold: String, base: Vector3,
		hw: float, h: float, tiers: int) -> void:
	var body := h * 0.78
	var th := body / float(tiers)
	var f := pow(0.34, 1.0 / float(tiers))
	var w := hw
	for k in tiers:
		var y := th * float(k)
		var wn := w * f
		lm.box(wall, base + Vector3(0, y + th * 0.18, 0), Vector3(w * 1.76, th * 0.36, w * 1.76))
		lm.spire(tile, base + Vector3(0, y + th * 0.36, 0), w * 0.98, th * 0.64, wn * 0.88)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.spire(gold, base + Vector3(sx * w * 0.9, y + th * 0.36, sz * w * 0.9), w * 0.07,
					th * 0.5, 0.0)
		w = wn
	var ch := h * 0.22
	lm.lathe(gold, base + Vector3(0, body, 0), PackedVector2Array([Vector2(w * 0.9, 0),
		Vector2(w * 1.0, ch * 0.12), Vector2(w * 0.7, ch * 0.34), Vector2(w * 0.38, ch * 0.5),
		Vector2(w * 0.3, ch * 0.62), Vector2(w * 0.14, ch * 0.8), Vector2(0.0, ch)]), 8)

## Bell chedi of total height h and bell radius r: two square plinths,
## two octagonal terraces, the bell, the harmika and a ringed spire to a
## needle. `body` draws bell and spire, `base` the plinths, `gold` the tip.
static func bell_chedi(lm: LandmarkMesh, body: String, base_key: String, gold: String,
		base: Vector3, r: float, h: float) -> void:
	lm.box(base_key, base + Vector3(0, 0.04 * h, 0), Vector3(r * 3.0, 0.08 * h, r * 3.0))
	lm.box(base_key, base + Vector3(0, 0.11 * h, 0), Vector3(r * 2.5, 0.06 * h, r * 2.5))
	lm.frustum(base_key, base + Vector3(0, 0.14 * h, 0), r * 1.3, r * 1.22, 0.05 * h, 8, PI / 8.0)
	lm.frustum(base_key, base + Vector3(0, 0.19 * h, 0), r * 1.15, r * 1.08, 0.04 * h, 8, PI / 8.0)
	lm.lathe(body, base + Vector3(0, 0.23 * h, 0), PackedVector2Array([Vector2(r * 1.0, 0),
		Vector2(r * 1.05, 0.025 * h), Vector2(r * 0.98, 0.07 * h), Vector2(r * 0.82, 0.12 * h),
		Vector2(r * 0.58, 0.16 * h), Vector2(r * 0.42, 0.185 * h)]), 24)
	lm.box(body, base + Vector3(0, 0.43 * h, 0), Vector3(r * 0.8, 0.04 * h, r * 0.8))
	var prof := PackedVector2Array()
	for i in 9:
		var rr := r * 0.34 * (1.0 - float(i) / 10.0)
		var y := 0.45 * h + 0.05 * h * float(i)
		prof.append(Vector2(rr, y - 0.45 * h))
		prof.append(Vector2(rr * 1.28, y - 0.45 * h + 0.012 * h))
		prof.append(Vector2(rr * 1.1, y - 0.45 * h + 0.035 * h))
	lm.lathe(body, base + Vector3(0, 0.45 * h, 0), prof, 12)
	lm.lathe(gold, base + Vector3(0, 0.9 * h, 0), PackedVector2Array([Vector2(r * 0.07, 0),
		Vector2(r * 0.12, 0.02 * h), Vector2(r * 0.04, 0.05 * h), Vector2(0.0, 0.1 * h)]), 8)

## Khmer-style prang of total height h and base half-width hw: plinth,
## `tiers` receding square storeys with porches and pediments on all four
## faces, then the tall ridged corn-cob crown. `dark` draws the doorways.
static func prang(lm: LandmarkMesh, wall: String, dark: String, base: Vector3, hw: float, h: float,
		tiers: int = 3) -> void:
	lm.box(wall, base + Vector3(0, h * 0.04, 0), Vector3(hw * 2.4, h * 0.08, hw * 2.4))
	var y := h * 0.08
	var w := hw
	var sh := h * 0.34 / float(tiers)
	for k in tiers:
		lm.box(wall, base + Vector3(0, y + sh * 0.5, 0), Vector3(w * 2.0, sh, w * 2.0))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box(wall, base + b * Vector3(0, y + sh * 0.46, w + w * 0.16), Vector3(w * 0.7, sh * 0.9, w * 0.34), b)
			lm.box(dark, base + b * Vector3(0, y + sh * 0.38, w + w * 0.34), Vector3(w * 0.3, sh * 0.6, 0.12), b)
			lm.gable(wall, base + b * Vector3(0, y + sh * 0.88, w + w * 0.16), w * 0.7, w * 0.34, sh * 0.5, b, 0.0, wall)
		lm.box(wall, base + Vector3(0, y + sh + 0.12, 0), Vector3(w * 2.2, 0.24, w * 2.2))
		y += sh + 0.24
		w *= 0.8
	var prof := PackedVector2Array([Vector2(w * 1.05, 0)])
	var top := h - y
	var t := [[1.1, 0.05], [0.96, 0.1], [1.04, 0.17], [0.86, 0.25], [0.9, 0.31], [0.7, 0.42],
		[0.74, 0.47], [0.52, 0.6], [0.54, 0.65], [0.34, 0.78], [0.2, 0.9], [0.1, 0.96], [0.0, 1.0]]
	for e in t:
		prof.append(Vector2(w * float(e[0]), top * float(e[1])))
	lm.lathe(wall, base + Vector3(0, y, 0), prof, 12)

## Crenellated wall run along the ground points a..b: `h` tall, `t` thick,
## merlons every `step` metres.
static func crenel_run(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, t: float,
		step: float = 2.0) -> void:
	var d := b - a
	var length := d.length()
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	lm.box(key, (a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(t, h, length), basis)
	var n := int(length / step)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box(key, p + Vector3(0, h + 0.5, 0), Vector3(t * 1.15, 1.0, step * 0.5), basis)

## Closed rectangle of crenellated wall, corners (cx +- hx, cz +- hz).
static func crenel_ring(lm: LandmarkMesh, key: String, c: Vector3, hx: float, hz: float, h: float,
		t: float, step: float = 2.0) -> void:
	var p := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		crenel_run(lm, key, c + (p[i] as Vector3), c + (p[(i + 1) % 4] as Vector3), h, t, step)

## Flight of `n` box steps whose top step meets local (0, top, 0) of
## `base`, running out along basis +Z.
static func stairs(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, width: float,
		n: int, tread: float, riser: float) -> void:
	for k in n:
		var hgt := riser * float(n - k)
		lm.box(key, base + basis * Vector3(0, hgt * 0.5, tread * (float(k) + 0.5)),
			Vector3(width, hgt, tread), basis)

## Rectangular covered cloister (wall ranges under pitched roofs) round `c`
## with outer half-sizes hx, hz.
static func cloister(lm: LandmarkMesh, wall: String, roof: String, c: Vector3, hx: float, hz: float,
		thick: float, wall_h: float, rise: float) -> void:
	for s in [-1.0, 1.0]:
		var zc: float = s * (hz - thick * 0.5)
		lm.box(wall, c + Vector3(0, wall_h * 0.5, zc), Vector3(hx * 2.0, wall_h, thick))
		lm.gable(roof, c + Vector3(0, wall_h, zc), thick, hx * 2.0, rise, Basis(Vector3.UP, PI * 0.5), 0.5, wall)
		var xc: float = s * (hx - thick * 0.5)
		lm.box(wall, c + Vector3(xc, wall_h * 0.5, 0), Vector3(thick, wall_h, hz * 2.0 - thick * 2.0))
		lm.gable(roof, c + Vector3(xc, wall_h, 0), thick, hz * 2.0 - thick * 2.0, rise, Basis(), 0.5, wall)

## Row of `n` posts of `size` between the ground points a..b, `h` tall.
static func posts(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, h: float,
		size: float) -> void:
	for i in n:
		lm.box(key, a.lerp(b, float(i) / float(maxi(n - 1, 1))) + Vector3(0, h * 0.5, 0),
			Vector3(size, h, size))
