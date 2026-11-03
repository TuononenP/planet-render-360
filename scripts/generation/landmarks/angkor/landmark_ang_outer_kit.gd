class_name LandmarkAngOuterKit
extends RefCounted

## Parts shared by the outer Siem Reap temples (Roluos group, Beng Mealea,
## Phnom Krom, West Mebon) on top of LandmarkKhUtil: wall rings with gaps,
## roofed and tower gates, libraries, collapsed gallery runs and rubble,
## minor shrines, elephants, Nandi bulls and strangler-fig trees. Every part
## takes material KEYS registered by the caller with lm.use.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Walled rectangle of half-sizes hx, hz at height y; `gap_x` / `gap_z` are
## the half-widths of the openings in the middle of the east-west and the
## north-south walls (0 = closed).
static func ring(lm: LandmarkMesh, key: String, cap: String, hx: float, hz: float, h: float,
		t: float, gap_x: float = 0.0, gap_z: float = 0.0, y: float = 0.0) -> void:
	for s in [-1.0, 1.0]:
		var sg: float = s
		_run(lm, key, cap, Vector3(-hx, y, sg * hz), Vector3(hx, y, sg * hz), h, t, gap_z)
		_run(lm, key, cap, Vector3(sg * hx, y, -hz), Vector3(sg * hx, y, hz), h, t, gap_x)

## Capped wall a..b with a gap of half-width `gap` at its middle.
static func _run(lm: LandmarkMesh, key: String, cap: String, a: Vector3, b: Vector3, h: float,
		t: float, gap: float) -> void:
	if gap <= 0.0:
		U.wall_run(lm, key, cap, a, b, h, t)
		return
	var m := (a + b) * 0.5
	var u := (b - a).normalized()
	U.wall_run(lm, key, cap, a, m - u * gap, h, t)
	U.wall_run(lm, key, cap, m + u * gap, b, h, t)

## Gate pavilion at `base`: a w x l block (passage along the basis Z,
## dark doorways at both ends) under a two-tier gabled roof of rise `rise`.
static func gopura_roofed(lm: LandmarkMesh, wall: String, roof: String, dark: String, base: Vector3,
		b: Basis, w: float, l: float, h: float, rise: float) -> void:
	lm.box(roof, base + b * Vector3(0, 0.2, 0), Vector3(w + 0.8, 0.4, l + 0.8), b)
	lm.box(wall, base + b * Vector3(0, h * 0.5, 0), Vector3(w, h, l), b)
	for s in [-1.0, 1.0]:
		lm.box(dark, base + b * Vector3(0, h * 0.38, s * (l * 0.5 + 0.03)),
			Vector3(w * 0.34, h * 0.76, 0.1), b, 0.0)
	lm.box(roof, base + b * Vector3(0, h + 0.15, 0), Vector3(w + 0.8, 0.3, l + 0.8), b)
	U.tiered_roof(lm, roof, wall, wall, base + b * Vector3(0, h + 0.3, 0), b, w, l, rise, 2)

## Gate block of height h (passage along the basis Z, dark doorways at both
## ends) carrying a redented prasat tower of `tower_h` (top at base + h +
## tower_h).
static func gopura_tower(lm: LandmarkMesh, wall: String, dark: String, base: Vector3, b: Basis,
		w: float, l: float, h: float, tower_h: float, tiers: int = 2) -> void:
	lm.box(wall, base + b * Vector3(0, 0.25, 0), Vector3(w + 0.8, 0.5, l + 0.8), b)
	lm.box(wall, base + b * Vector3(0, h * 0.5, 0), Vector3(w, h, l), b)
	lm.box(wall, base + b * Vector3(0, h - 0.2, 0), Vector3(w + 0.6, 0.4, l + 0.6), b)
	for s in [-1.0, 1.0]:
		lm.box(dark, base + b * Vector3(0, h * 0.36, s * (l * 0.5 + 0.03)),
			Vector3(w * 0.3, h * 0.72, 0.1), b, 0.0)
	light_tower(lm, wall, dark, base + Vector3(0, h, 0), minf(w, l) * 0.3, tower_h, tiers + 1)

## Plain stepped tower (plinth, `tiers` receding storeys with a dark
## doorway on every face and an eave each, lotus-bud top) of total height h
## and half-width hw: the cheap stand-in for a prasat on minor towers.
static func light_tower(lm: LandmarkMesh, key: String, dark: String, base: Vector3, hw: float,
		h: float, tiers: int = 3) -> void:
	var plinth := h * 0.1
	lm.box(key, base + Vector3(0, plinth * 0.5, 0), Vector3(hw * 2.5, plinth, hw * 2.5), Basis(), 0.0)
	var sh := (h * 0.78 - plinth) / float(tiers)
	var y := plinth
	var w := hw
	for k in tiers:
		lm.box(key, base + Vector3(0, y + sh * 0.425, 0), Vector3(w * 2.0, sh * 0.85, w * 2.0), Basis(), 0.0)
		lm.box(key, base + Vector3(0, y + sh * 0.9, 0), Vector3(w * 2.3, sh * 0.2, w * 2.3), Basis(), 0.0)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box(dark, base + b * Vector3(0, y + sh * 0.35, w + 0.03), Vector3(w * 0.5, sh * 0.6, 0.06),
				b, 0.0)
		y += sh
		w *= 0.8
	U.lotus_bud(lm, key, base + Vector3(0, y, 0), w * 1.1, h - y, 8)

## Gate tower of the island temple: a w x l block (passage along the basis
## Z) under a cornice and a stone lotus bud of height `lotus_h`.
static func lotus_gate(lm: LandmarkMesh, wall: String, trim: String, dark: String, base: Vector3,
		b: Basis, w: float, l: float, h: float, lotus_h: float) -> void:
	lm.box(trim, base + b * Vector3(0, 0.2, 0), Vector3(w + 0.7, 0.4, l + 0.7), b)
	lm.box(wall, base + b * Vector3(0, h * 0.5, 0), Vector3(w, h, l), b)
	for s in [-1.0, 1.0]:
		lm.box(dark, base + b * Vector3(0, h * 0.36, s * (l * 0.5 + 0.03)),
			Vector3(w * 0.34, h * 0.7, 0.1), b, 0.0)
	lm.box(trim, base + b * Vector3(0, h - 0.15, 0), Vector3(w + 0.6, 0.3, l + 0.6), b)
	lm.box(trim, base + Vector3(0, h + 0.15, 0), Vector3(w * 0.8, 0.3, l * 0.8))
	U.lotus_bud(lm, trim, base + Vector3(0, h + 0.3, 0), minf(w, l) * 0.4, lotus_h - 0.3, 10)

## Library: a plinth, a w x l block (door at the +Z end) and a gabled stone
## roof of the same stone.
static func library(lm: LandmarkMesh, wall: String, trim: String, dark: String, base: Vector3,
		b: Basis, w: float, l: float, h: float) -> void:
	lm.box(trim, base + b * Vector3(0, 0.3, 0), Vector3(w + 0.8, 0.6, l + 0.8), b)
	lm.box(wall, base + b * Vector3(0, 0.6 + h * 0.5, 0), Vector3(w, h, l), b)
	lm.box(trim, base + b * Vector3(0, 0.6 + h + 0.15, 0), Vector3(w + 0.5, 0.3, l + 0.5), b)
	lm.gable(wall, base + b * Vector3(0, 0.6 + h + 0.3, 0), w + 0.3, l + 0.3, h * 0.55, b, 0.2, wall)
	lm.box(dark, base + b * Vector3(0, 0.6 + h * 0.4, l * 0.5 + 0.03), Vector3(w * 0.3, h * 0.7, 0.1),
		b, 0.0)

## Minor brick shrine: plinth, body with an east doorway, stepped cornice
## and a spire. Total height h, half-width hw.
static func shrine(lm: LandmarkMesh, key: String, dark: String, base: Vector3, hw: float,
		h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.08, 0), Vector3(hw * 2.5, h * 0.16, hw * 2.5), Basis(), 0.0)
	lm.box(key, base + Vector3(0, h * 0.44, 0), Vector3(hw * 2.0, h * 0.56, hw * 2.0), Basis(), 0.0)
	lm.box(key, base + Vector3(0, h * 0.74, 0), Vector3(hw * 2.3, h * 0.04, hw * 2.3), Basis(), 0.0)
	lm.spire(key, base + Vector3(0, h * 0.76, 0), hw, h * 0.24, 0.0)
	lm.box(dark, base + Vector3(hw + 0.02, h * 0.33, 0), Vector3(0.06, h * 0.34, hw * 0.8),
		Basis(), 0.0)

## Temple elephant (2.2 m at the back) at `base`, facing the heading `yaw`
## (0 = +Z).
static func elephant(lm: LandmarkMesh, key: String, base: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	lm.box(key, base + b * Vector3(0, 1.45, -0.1), Vector3(1.3, 1.5, 2.6), b, 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(key, base + b * Vector3(sx * 0.45, 0.5, sz * 0.85 - 0.1), Vector3(0.45, 1.0, 0.5), b, 0.0)
		lm.box(key, base + b * Vector3(sx * 0.62, 1.95, 1.05), Vector3(0.1, 0.8, 0.7), b, 0.0)
	lm.box(key, base + b * Vector3(0, 1.95, 1.25), Vector3(0.95, 1.1, 1.0), b, 0.0)
	lm.beam(key, base + b * Vector3(0, 1.7, 1.8), base + b * Vector3(0, 0.35, 2.05), 0.4, 0.35,
		b * Vector3.RIGHT)

## Recumbent Nandi bull on a pedestal at `base`, facing the basis +Z.
static func nandi(lm: LandmarkMesh, key: String, base: Vector3, b: Basis) -> void:
	lm.box(key, base + b * Vector3(0, 0.25, 0), Vector3(1.8, 0.5, 2.9), b, 0.0)
	lm.box(key, base + b * Vector3(0, 0.95, -0.1), Vector3(1.0, 0.9, 1.9), b, 0.0)
	lm.box(key, base + b * Vector3(0, 1.5, 0.45), Vector3(0.7, 0.5, 0.7), b, 0.0)
	lm.box(key, base + b * Vector3(0, 1.25, 1.15), Vector3(0.55, 0.6, 0.75), b, 0.0)
	for sx in [-1.0, 1.0]:
		lm.beam(key, base + b * Vector3(sx * 0.2, 1.5, 1.2), base + b * Vector3(sx * 0.45, 1.75, 1.1),
			0.1, 0.1, b * Vector3.RIGHT)

## Heap of fallen blocks of radius r at `c`, `n` blocks, `peak` tall in the
## middle. Blocks are yawed and slightly tilted, never below c.y.
static func rubble(lm: LandmarkMesh, key: String, c: Vector3, r: float, n: int,
		rng: RandomNumberGenerator, peak: float = 1.0) -> void:
	for i in n:
		var a := rng.randf() * TAU
		var d := r * sqrt(rng.randf())
		var s := Vector3(rng.randf_range(0.5, 1.7), rng.randf_range(0.35, 1.0), rng.randf_range(0.5, 1.7))
		var mound := peak * (1.0 - d / r) * 1.2
		var bs := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
		lm.box(key, c + Vector3(cos(a) * d, mound + s.y * 0.5 + 0.1, sin(a) * d), s, bs, 0.0)

## Gallery run a..b (ground points) of thickness t and height h, cut into
## ~`seg_len` m bays. Each bay is intact (pitched stone roof, dark windows
## on both faces), broken (a ragged stump) or fallen (a stub and a heap).
static func gallery_run(lm: LandmarkMesh, wall: String, dark: String, a: Vector3, b: Vector3,
		t: float, h: float, rng: RandomNumberGenerator, seg_len: float = 11.0) -> void:
	var d := b - a
	var n := maxi(int(round(d.length() / seg_len)), 1)
	var step := d.length() / float(n)
	var bs := Basis(Vector3.UP, atan2(d.x, d.z))
	for i in n:
		var c := a + d * ((float(i) + 0.5) / float(n))
		var roll := rng.randf()
		if roll < 0.6:
			lm.box(wall, c + Vector3(0, h * 0.5, 0), Vector3(t, h, step), bs)
			lm.box(wall, c + Vector3(0, h + 0.2, 0), Vector3(t + 0.5, 0.4, step + 0.1), bs)
			lm.gable(wall, c + Vector3(0, h + 0.4, 0), t + 0.5, step, 1.5, bs, 0.1)
			for s in [-1.0, 1.0]:
				for k in 3:
					var z := step * ((float(k) + 0.5) / 3.0 - 0.5)
					lm.box(dark, c + bs * Vector3(s * (t * 0.5 + 0.02), h * 0.55, z),
						Vector3(0.1, h * 0.34, 1.1), bs, 0.0)
		elif roll < 0.85:
			var bh := h * rng.randf_range(0.35, 0.7)
			lm.box(wall, c + Vector3(0, bh * 0.5, 0), Vector3(t, bh, step), bs)
			rubble(lm, wall, c, t * 0.9, 4, rng, 0.5)
		else:
			lm.box(wall, c + Vector3(0, 0.45, 0), Vector3(t, 0.9, step), bs)
			rubble(lm, wall, c + Vector3(0, 0.6, 0), t * 1.1, 8, rng, 1.0)

## Strangler-fig mass: a swollen dark trunk of radius r and height h with
## buttress roots spreading to the ground and a mossy bulge.
static func tree(lm: LandmarkMesh, root: String, moss: String, base: Vector3, r: float,
		h: float) -> void:
	lm.lathe(root, base, PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r, h * 0.25),
		Vector2(r * 1.15, h * 0.5), Vector2(r * 0.8, h * 0.75), Vector2(r * 1.0, h * 0.9),
		Vector2(r * 0.4, h)]), 9)
	for i in 7:
		var a := TAU * float(i) / 7.0 + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam(root, base + d * r * 0.5 + Vector3(0, h * 0.42, 0), base + d * r * 3.4 + Vector3(0, r * 0.32, 0),
			r * 0.5, r * 0.4, Vector3.UP)
	lm.lathe(moss, base + Vector3(0, h * 0.6, 0), PackedVector2Array([Vector2(r * 0.9, 0),
		Vector2(r * 1.8, h * 0.12), Vector2(r * 1.4, h * 0.26), Vector2(r * 0.6, h * 0.34)]), 9)
