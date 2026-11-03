class_name VesselKit
extends RefCounted

## Small reusable vessel parts (metres, +X bow): window bands, lifeboats,
## outboards, masts, funnels. Every part writes the standard surface keys
## registered by VesselMaterials.register (Hull, White, Glass, Steel, Dark,
## Canvas, Deck) plus Orange / Funnel / Pool where a model registers them.

## A dark window band on both sides of a deckhouse wall. `x0..x1` is the
## wall, `z` its half-width, `y0..y1` the band; mullions every `pitch`.
static func windows(lm: LandmarkMesh, x0: float, x1: float, z: float, y0: float, y1: float,
		pitch: float = 0.0, key: String = "Glass", post_key: String = "White") -> void:
	for s in [-1.0, 1.0]:
		lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, float(s) * (z + 0.01)),
			Vector3(x1 - x0, y1 - y0, 0.02), Basis(), 0.0)
		if pitch > 0.0:
			var n := maxi(int((x1 - x0) / pitch), 1)
			for i in n + 1:
				var x := lerpf(x0, x1, float(i) / float(n))
				lm.box(post_key, Vector3(x, (y0 + y1) * 0.5, float(s) * (z + 0.02)),
					Vector3(0.07, y1 - y0 + 0.02, 0.04), Basis(), 0.0)

## A deckhouse: walls, an overhanging roof slab and (optionally) windows.
## Returns the roof's top y.
static func house(lm: LandmarkMesh, centre_x: float, len: float, wid: float, y: float,
		h: float, win: bool, pitch: float, over: float = 0.12, wall_key: String = "White") -> float:
	lm.box(wall_key, Vector3(centre_x, y + h * 0.5, 0), Vector3(len, h, wid), Basis(), 0.03)
	lm.box("White", Vector3(centre_x, y + h + 0.04, 0), Vector3(len + over * 2.0, 0.08, wid + over * 2.0), Basis(), 0.0)
	if win:
		windows(lm, centre_x - len * 0.5 + 0.35, centre_x + len * 0.5 - 0.35, wid * 0.5,
			y + h * 0.3, y + h * 0.82, pitch)
	return y + h + 0.08

## Mast: tapered round spar from `base` up `h`.
static func mast(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.55, h)]), 6, 1.0, 1.0, 0.0, false)

## Raked oval funnel: a lathe stretched along the hull with a dark top.
static func funnel(lm: LandmarkMesh, base: Vector3, h: float, r: float, stretch: float,
		body_key: String = "Funnel", top_key: String = "Black") -> void:
	var split := h * 0.8
	lm.lathe(body_key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.9, split)]), 12, stretch, 1.0, 0.0, true, false)
	lm.lathe(top_key, base + Vector3(0, split, 0),
		PackedVector2Array([Vector2(r * 0.9, 0), Vector2(r * 0.86, h - split)]), 12, stretch, 1.0, 0.0, true, true)

## Open lifeboat of `len` metres sitting on its keel at `at` (orange hull,
## dark interior), +X bow.
static func lifeboat(lm: LandmarkMesh, at: Vector3, len: float) -> void:
	var spec := {"length": len, "beam": len * 0.32, "freeboard": len * 0.14, "draft": len * 0.04,
		"entry": 0.35, "flare": 0.1, "stern_w": 0.5, "bow_rise": len * 0.04, "lod": 1}
	var keys := {"hull": "Orange", "boot": "Orange", "bottom": "Orange", "deck": "Dark"}
	HullLoft.loft(lm, spec, keys, at + Vector3(0, len * 0.04, 0))

## Outboard motor with its cowl at the transom (x = stern), `s` metres tall.
static func outboard(lm: LandmarkMesh, stern: Vector3, s: float) -> void:
	lm.box("Dark", stern + Vector3(-s * 0.16, s * 0.12, 0), Vector3(s * 0.34, s * 0.5, s * 0.26), Basis(), 0.02)
	lm.box("White", stern + Vector3(-s * 0.16, s * 0.40, 0), Vector3(s * 0.38, s * 0.12, s * 0.28), Basis(), 0.02)
	HullLoft.fin(lm, "Dark", PackedVector2Array([Vector2(stern.x - s * 0.22, stern.y - s * 0.12),
		Vector2(stern.x - s * 0.08, stern.y - s * 0.12), Vector2(stern.x - s * 0.04, stern.y - s * 0.55),
		Vector2(stern.x - s * 0.26, stern.y - s * 0.5)]), s * 0.04, stern.z)

## Chrome stanchions + rail around the deck between x ranges (both sides).
static func guard(lm: LandmarkMesh, spec: Dictionary, xa: float, xb: float, h: float,
		step: float, w: float = 0.03) -> void:
	HullLoft.rail(lm, "Steel", spec, xa, xb, h, step, 0.0, 0.05, w)
