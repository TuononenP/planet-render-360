extends RefCounted

## Small shared parts for the Norrmalm waterfront models (Rosenbad, Sagerska
## huset, Arvfurstens palats), in true metres on LandmarkMesh. Parts are
## built once facing +Z with their foot at the origin and placed on a wall
## with StoBaroqueKit.put. Every part takes material KEYS the caller
## registered with lm.use.

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")

## Cheap framed window `w` x `h`, its sill at the origin: a pale surround
## slab, a dark pane and a mullion and transom. About 40 triangles.
static func window(mats: Dictionary, frame: String, w: float, h: float) -> LandmarkMesh:
	var p := Kit.fresh(mats)
	p.box(frame, Vector3(0, (h + 0.05) * 0.5, 0.06), Vector3(w + 0.5, h + 0.45, 0.12), Basis(), 0.0)
	p.quad("Glass", Vector3(-w * 0.5, 0, 0.13), Vector3(w * 0.5, 0, 0.13), Vector3(w * 0.5, h, 0.13),
		Vector3(-w * 0.5, h, 0.13), Vector3(0, 0, 1))
	p.box(frame, Vector3(0, h * 0.5, 0.15), Vector3(0.07, h, 0.05), Basis(), 0.0)
	p.box(frame, Vector3(0, h * 0.68, 0.15), Vector3(w, 0.07, 0.05), Basis(), 0.0)
	p.box(frame, Vector3(0, -0.12, 0.14), Vector3(w + 0.7, 0.16, 0.28), Basis(), 0.0)
	return p

## Roofed dormer facing +Z, `w` wide, standing on the origin: cheeks and a
## gable in `key`, a pane in front.
static func dormer(mats: Dictionary, key: String, w: float = 1.8, h: float = 1.9) -> LandmarkMesh:
	var p := Kit.fresh(mats)
	p.box(key, Vector3(0, h * 0.5, -0.8), Vector3(w, h, 1.6), Basis(), 0.0)
	p.quad("Glass", Vector3(-w * 0.32, h * 0.2, 0.02), Vector3(w * 0.32, h * 0.2, 0.02),
		Vector3(w * 0.32, h * 0.86, 0.02), Vector3(-w * 0.32, h * 0.86, 0.02), Vector3(0, 0, 1))
	p.gable(key, Vector3(0, h, -0.8), w, 1.8, w * 0.42, Basis(), 0.18, key)
	return p

## Basis for a part on a sloping roof face: facing `out`, its normal tipped
## up by `tilt` radians (a mansard lower slope is about 25 degrees off
## vertical).
static func tilted(out: Vector3, tilt: float) -> Basis:
	return Kit.face(out) * Basis(Vector3.RIGHT, -tilt)

## Merges a part onto a sloping face at `pos`.
static func put_tilted(lm: LandmarkMesh, part: LandmarkMesh, pos: Vector3, out: Vector3, tilt: float) -> void:
	lm.merge(part, Transform3D(tilted(out, tilt), pos))

## Brick chimney stack with a stone cap, standing on `base`.
static func chimney(lm: LandmarkMesh, brick: String, cap: String, base: Vector3, w: float, d: float, h: float) -> void:
	lm.box(brick, base + Vector3(0, h * 0.5, 0), Vector3(w, h, d), Basis(), 0.0)
	lm.box(cap, base + Vector3(0, h + 0.1, 0), Vector3(w + 0.3, 0.2, d + 0.3), Basis(), 0.0)

## Four bands round the outside of an axis box centred at (cx, cz): y up
## `h` tall, standing `proj` proud. Courtyard-safe (no slab across the middle).
static func ring(lm: LandmarkMesh, key: String, cx: float, cz: float, w: float, d: float, y: float,
		h: float, proj: float) -> void:
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box(key, Vector3(cx, y + h * 0.5, cz + sg * (d * 0.5 + proj * 0.5)), Vector3(w + proj * 2.0, h, proj),
			Basis(), 0.0)
		lm.box(key, Vector3(cx + sg * (w * 0.5 + proj * 0.5), y + h * 0.5, cz), Vector3(proj, h, d), Basis(), 0.0)

## Square pinnacle turret: shaft `w` wide from y0 up `h`, a corbelled cap
## and a pyramid cap of `cap_h` in `roof`.
static func turret(lm: LandmarkMesh, stone: String, roof: String, c: Vector3, w: float, h: float,
		cap_h: float) -> void:
	lm.box(stone, c + Vector3(0, h * 0.5, 0), Vector3(w, h, w), Basis(), 0.0)
	lm.box(stone, c + Vector3(0, h - 0.15, 0), Vector3(w + 0.4, 0.3, w + 0.4), Basis(), 0.0)
	lm.spire(roof, c + Vector3(0, h, 0), w * 0.5 + 0.15, cap_h, 0.0, 4)
