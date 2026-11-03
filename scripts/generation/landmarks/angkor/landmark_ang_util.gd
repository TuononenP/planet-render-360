class_name LandmarkAngUtil
extends RefCounted

## Parts shared by the Angkor temple builders of the Siem Reap batch B, in
## true metres on LandmarkMesh: gapped enclosure walls, cross-shaped gopuras,
## gabled halls, stone elephants and lions and the strangler fig. Every part
## takes the material KEYS to draw with (registered by the caller).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Basis whose local +Z points out of side 0 south (+Z), 1 east (+X),
## 2 north (-Z), 3 west (-X).
static func face(side: int) -> Basis:
	return Basis(Vector3.UP, PI * 0.5 * float(side))

## Wall run a..b with an opening of half-width `gap` in the middle (none
## when gap <= 0).
static func _gapped(lm: LandmarkMesh, key: String, cap: String, a: Vector3, b: Vector3, gap: float,
		h: float, t: float) -> void:
	if gap <= 0.0:
		U.wall_run(lm, key, cap, a, b, h, t)
		return
	var dir := (b - a).normalized()
	var m := (a + b) * 0.5
	U.wall_run(lm, key, cap, a, m - dir * gap, h, t)
	U.wall_run(lm, key, cap, m + dir * gap, b, h, t)

## Walled rectangle with half-sizes hx, hz standing at height y, `h` tall and
## `t` thick, with a gate opening of half-width gap_ew in the middle of the
## east and west walls and gap_ns in the north and south walls.
static func ring(lm: LandmarkMesh, key: String, cap: String, hx: float, hz: float, y: float,
		h: float, t: float, gap_ew: float, gap_ns: float = 0.0) -> void:
	for s in [-1.0, 1.0]:
		var sg: float = s
		_gapped(lm, key, cap, Vector3(-hx, y, sg * hz), Vector3(hx, y, sg * hz), gap_ns, h, t)
		_gapped(lm, key, cap, Vector3(sg * hx, y, -hz), Vector3(sg * hx, y, hz), gap_ew, h, t)

## Plain framed doorway on a wall face (sill centre `base`, basis +Z out of
## the wall): the dark opening, jambs, lintel and a small pediment. The cheap
## cousin of LandmarkKhUtil.false_door for the many minor doors.
static func door(lm: LandmarkMesh, trim: String, dark: String, base: Vector3, b: Basis, w: float,
		h: float) -> void:
	lm.box(dark, base + b * Vector3(0, h * 0.5, 0.03), Vector3(w, h, 0.06), b, 0.0)
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box(trim, base + b * Vector3(sg * (w * 0.5 + 0.12), h * 0.5, 0.1), Vector3(0.24, h, 0.2), b, 0.0)
	lm.box(trim, base + b * Vector3(0, h + 0.15, 0.1), Vector3(w + 0.8, 0.3, 0.3), b, 0.0)
	lm.gable(trim, base + b * Vector3(0, h + 0.3, 0.1), w + 0.8, 0.2, h * 0.28, b, 0.0, trim)

## Cross-shaped gopura: the passage block (`wall`) of width 0.4 w and depth d
## with a dark door at both ends and a gabled roof, flanked by two side
## chambers (`trim`) with balustered windows, false doors and their own
## cross gables, on a moulded plinth. The passage runs along basis Z, `base`
## is the middle of the passage at ground level. Returns the y of the top of
## the passage block (where a tower stands).
static func gopura(lm: LandmarkMesh, wall: String, trim: String, roof: String, dark: String,
		base: Vector3, b: Basis, w: float, d: float, h: float) -> float:
	var cw := w * 0.4
	var ww := (w - cw) * 0.5
	var wx := (cw + ww) * 0.5
	var wing_d := d * 0.62
	lm.box(trim, base + b * Vector3(0, 0.25, 0), Vector3(w + 1.4, 0.5, d + 1.4), b)
	lm.box(trim, base + b * Vector3(0, 0.65, 0), Vector3(w + 0.8, 0.3, d + 0.8), b)
	var y := 0.8
	lm.box(wall, base + b * Vector3(0, y + h * 0.5, 0), Vector3(cw, h, d), b)
	lm.box(trim, base + b * Vector3(0, y + h + 0.1, 0), Vector3(cw + 0.5, 0.2, d + 0.5), b)
	for e in [-1.0, 1.0]:
		var eg: float = e
		lm.box(dark, base + b * Vector3(0, y + h * 0.36, eg * (d * 0.5 + 0.02)),
			Vector3(cw * 0.55, h * 0.72, 0.14), b, 0.0)
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box(trim, base + b * Vector3(sg * wx, y + h * 0.36, 0), Vector3(ww, h * 0.72, wing_d), b)
		lm.box(trim, base + b * Vector3(sg * wx, y + h * 0.74, 0), Vector3(ww + 0.4, 0.16, wing_d + 0.4), b)
		# Balustered window on the outer face of the chamber.
		lm.box(dark, base + b * Vector3(sg * (w * 0.5 + 0.02), y + h * 0.4, 0),
			Vector3(0.12, h * 0.36, wing_d * 0.5), b, 0.0)
		for k in 3:
			var bz := (float(k) - 1.0) * wing_d * 0.17
			lm.box(trim, base + b * Vector3(sg * (w * 0.5 + 0.1), y + h * 0.4, bz),
				Vector3(0.16, h * 0.36, 0.2), b, 0.0)
		for e in [-1.0, 1.0]:
			var eg: float = e
			var fb := b if eg > 0.0 else b * Basis(Vector3.UP, PI)
			door(lm, trim, dark, base + b * Vector3(sg * wx, y, eg * wing_d * 0.5), fb, ww * 0.42, h * 0.42)
		lm.gable(roof, base + b * Vector3(sg * wx, y + h * 0.74 + 0.16, 0), wing_d + 0.4, ww + 0.2,
			h * 0.3, b * Basis(Vector3.UP, PI * 0.5), 0.25, trim)
	lm.gable(roof, base + b * Vector3(0, y + h + 0.2, 0), cw + 0.5, d + 0.5, h * 0.42, b, 0.3, wall)
	return base.y + y + h + 0.2

## Gabled hall along basis Z (w across, l long, `h` to the eaves, `rise`
## of the roof) on a low plinth, `win` dark windows a side, one false door
## at the +Z end. Returns the y of the ridge.
static func hall(lm: LandmarkMesh, wall: String, trim: String, roof: String, dark: String,
		base: Vector3, b: Basis, w: float, l: float, h: float, rise: float, win: int = 0) -> float:
	lm.box(trim, base + b * Vector3(0, 0.3, 0), Vector3(w + 0.8, 0.6, l + 0.8), b)
	var y := 0.6
	lm.box(wall, base + b * Vector3(0, y + h * 0.5, 0), Vector3(w, h, l), b)
	lm.box(trim, base + b * Vector3(0, y + h + 0.12, 0), Vector3(w + 0.5, 0.24, l + 0.5), b)
	for s in [-1.0, 1.0]:
		var sg: float = s
		for i in win:
			var z := -l * 0.5 + l * (float(i) + 0.5) / float(win)
			lm.box(dark, base + b * Vector3(sg * (w * 0.5 + 0.02), y + h * 0.58, z),
				Vector3(0.1, h * 0.38, minf(0.7, l / float(win) * 0.4)), b, 0.0)
	door(lm, trim, dark, base + b * Vector3(0, y, l * 0.5), b, minf(w * 0.4, 1.4), h * 0.6)
	lm.gable(roof, base + b * Vector3(0, y + h + 0.24, 0), w + 0.5, l + 0.5, rise, b, 0.4, wall)
	return base.y + y + h + 0.24 + rise

## Free-standing stone elephant about 1.9 m tall (at scale 1) facing basis
## +Z: four legs, barrel body, head with tusks and trunk, flapping ears.
static func elephant(lm: LandmarkMesh, key: String, base: Vector3, b: Basis, s: float = 1.0) -> void:
	for sx in [-1.0, 1.0]:
		var sg: float = sx
		for sz in [-1.0, 1.0]:
			var zg: float = sz
			lm.box(key, base + b * Vector3(sg * 0.3 * s, 0.4 * s, zg * 0.6 * s),
				Vector3(0.36 * s, 0.8 * s, 0.4 * s), b)
		lm.box(key, base + b * Vector3(sg * 0.44 * s, 1.5 * s, 0.95 * s),
			Vector3(0.1 * s, 0.7 * s, 0.55 * s), b)
		lm.beam(key, base + b * Vector3(sg * 0.22 * s, 1.0 * s, 1.35 * s),
			base + b * Vector3(sg * 0.27 * s, 0.85 * s, 1.85 * s), 0.07 * s, 0.07 * s, b * Vector3.UP)
	lm.box(key, base + b * Vector3(0, 1.25 * s, -0.05 * s), Vector3(1.0 * s, 0.95 * s, 1.9 * s), b)
	lm.box(key, base + b * Vector3(0, 1.5 * s, 1.0 * s), Vector3(0.72 * s, 0.8 * s, 0.72 * s), b)
	lm.beam(key, base + b * Vector3(0, 1.3 * s, 1.4 * s), base + b * Vector3(0, 0.3 * s, 1.6 * s),
		0.3 * s, 0.26 * s, b * Vector3.RIGHT)

## Couchant guardian lion about 1.3 m tall (at scale 1) facing basis +Z on
## its plinth: haunches, chest, mane and head, forepaws.
static func lion(lm: LandmarkMesh, key: String, base: Vector3, b: Basis, s: float = 1.0) -> void:
	lm.box(key, base + b * Vector3(0, 0.15 * s, 0.1 * s), Vector3(1.0 * s, 0.3 * s, 1.7 * s), b)
	lm.box(key, base + b * Vector3(0, 0.62 * s, -0.25 * s), Vector3(0.74 * s, 0.7 * s, 0.9 * s), b)
	lm.box(key, base + b * Vector3(0, 0.85 * s, 0.3 * s), Vector3(0.6 * s, 1.0 * s, 0.5 * s), b)
	lm.box(key, base + b * Vector3(0, 1.3 * s, 0.5 * s), Vector3(0.72 * s, 0.7 * s, 0.58 * s), b)
	lm.box(key, base + b * Vector3(0, 1.18 * s, 0.84 * s), Vector3(0.3 * s, 0.26 * s, 0.24 * s), b)
	for sx in [-1.0, 1.0]:
		var sg: float = sx
		lm.box(key, base + b * Vector3(sg * 0.2 * s, 0.5 * s, 0.7 * s), Vector3(0.16 * s, 0.4 * s, 0.5 * s), b)

## Strangler fig of height h and trunk radius r: a swollen trunk, buttress
## roots draping to the ground from half height and a dark leafy crown.
static func fig_tree(lm: LandmarkMesh, root: String, leaf: String, base: Vector3, r: float,
		h: float, roots: int = 9) -> void:
	lm.lathe(root, base, PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r, h * 0.2),
		Vector2(r * 1.2, h * 0.42), Vector2(r * 0.85, h * 0.62), Vector2(r * 0.5, h * 0.8)]), 9)
	for i in roots:
		var a := TAU * float(i) / float(roots) + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam(root, base + d * r * 0.5 + Vector3(0, h * 0.5, 0), base + d * r * 3.2 + Vector3(0, r * 0.3, 0),
			r * 0.5, r * 0.4, Vector3.UP)
	lm.lathe(leaf, base + Vector3(0, h * 0.62, 0), PackedVector2Array([Vector2(r * 0.9, 0),
		Vector2(r * 3.2, h * 0.07), Vector2(r * 4.1, h * 0.17), Vector2(r * 3.4, h * 0.28),
		Vector2(r * 1.6, h * 0.36), Vector2(0.0, h * 0.38)]), 10)
