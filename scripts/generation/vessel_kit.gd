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
	if pitch > 0.0:
		VesselForms.cabin(lm, centre_x, len, wid, y, h, pitch, wall_key, 0.12)
		VesselForms.slab(lm, "White", Vector3(centre_x - h * 0.03, y + h + 0.04, 0),
			Vector3(len + over * 2.0, 0.08, wid + over * 2.0), minf(wid * 0.12, h * 0.45))
		return y + h + 0.08
	lm.box(wall_key, Vector3(centre_x, y + h * 0.5, 0), Vector3(len, h, wid), Basis(), 0.03)
	lm.box("White", Vector3(centre_x, y + h + 0.04, 0), Vector3(len + over * 2.0, 0.08, wid + over * 2.0), Basis(), 0.0)
	if win:
		windows(lm, centre_x - len * 0.5 + 0.35, centre_x + len * 0.5 - 0.35, wid * 0.5,
			y + h * 0.3, y + h * 0.82, pitch)
	return y + h + 0.08

## Mast: tapered round spar from `base` up `h`.
static func mast(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float, detail: bool = false) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.55, h)]), 12 if detail else 6, 1.0, 1.0, 0.0, detail)

## Raked oval funnel: a lathe stretched along the hull with a dark top.
static func funnel(lm: LandmarkMesh, base: Vector3, h: float, r: float, stretch: float,
		body_key: String = "Funnel", top_key: String = "Black", detail: bool = false) -> void:
	var split := h * 0.8
	lm.lathe(body_key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.9, split)]), 20 if detail else 12, stretch, 1.0, 0.0, true, false)
	lm.lathe(top_key, base + Vector3(0, split, 0),
		PackedVector2Array([Vector2(r * 0.9, 0), Vector2(r * 0.86, h - split)]), 20 if detail else 12, stretch, 1.0, 0.0, true, true)

## Open lifeboat of `len` metres sitting on its keel at `at` (orange hull,
## dark interior), +X bow.
static func lifeboat(lm: LandmarkMesh, at: Vector3, len: float) -> void:
	var spec := {"length": len, "beam": len * 0.32, "freeboard": len * 0.14, "draft": len * 0.04,
		"entry": 0.35, "flare": 0.1, "stern_w": 0.5, "bow_rise": len * 0.04, "lod": 1,
		"cockpit": Rect2(-len * 0.35, 0, len * 0.57, len * 0.09), "cockpit_y": len * 0.045}
	var keys := {"hull": "Orange", "boot": "Orange", "bottom": "Orange", "deck": "Dark"}
	HullLoft.loft(lm, spec, keys, at + Vector3(0, len * 0.04, 0))
	for x in [-0.24, -0.02, 0.16]:
		lm.box("White", at + Vector3(len * float(x), len * 0.13, 0), Vector3(len * 0.06, 0.05, len * 0.18), Basis(), 0.0)

## Outboard motor with its cowl at the transom (x = stern), `s` metres tall.
static func outboard(lm: LandmarkMesh, stern: Vector3, s: float, detail: bool = false) -> void:
	if detail:
		VesselForms.slab(lm, "Dark", stern + Vector3(-s * 0.16, s * 0.12, 0), Vector3(s * 0.34, s * 0.5, s * 0.26), s * 0.09)
	else:
		lm.box("Dark", stern + Vector3(-s * 0.16, s * 0.12, 0), Vector3(s * 0.34, s * 0.5, s * 0.26), Basis(), 0.02)
	lm.box("White", stern + Vector3(-s * 0.16, s * 0.40, 0), Vector3(s * 0.38, s * 0.12, s * 0.28), Basis(), 0.02)
	HullLoft.fin(lm, "Dark", PackedVector2Array([Vector2(stern.x - s * 0.22, stern.y - s * 0.12),
		Vector2(stern.x - s * 0.08, stern.y - s * 0.12), Vector2(stern.x - s * 0.04, stern.y - s * 0.55),
		Vector2(stern.x - s * 0.26, stern.y - s * 0.5)]), s * 0.04, stern.z)

	if detail:
		var prop := stern + Vector3(-s * 0.2, -s * 0.43, 0)
		HullLoft.tube(lm, "Steel", [prop - Vector3(s * 0.09, 0, 0), prop + Vector3(s * 0.05, 0, 0)], s * 0.045, 12, true)
		for i in 3:
			var a := TAU * float(i) / 3.0
			var end := prop + Vector3(-s * 0.02, cos(a) * s * 0.14, sin(a) * s * 0.14)
			lm.beam("Steel", prop, end, s * 0.05, s * 0.018)

## Chrome stanchions + rail around the deck between x ranges (both sides).
static func guard(lm: LandmarkMesh, spec: Dictionary, xa: float, xb: float, h: float,
		step: float, w: float = 0.03) -> void:
	HullLoft.rail(lm, "Steel", spec, xa, xb, h, step, 0.0, 0.05, w)
