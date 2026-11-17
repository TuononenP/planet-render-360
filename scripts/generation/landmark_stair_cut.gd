class_name LandmarkStairCut
extends RefCounted

## Ground under a landmark's built stair. A city elevation model records a
## monumental stair as a smooth ramp, and on the terrain grid that ramp
## stood over the treads (Helsinki Cathedral's 49 steps were buried up to
## the terrace lip). Every step box reaches its model's footing below the
## square, so the ground under the stair is held flat just under the foot:
## a grid post (9.4 m apart) cannot follow 0.6 m treads, but a chord from a
## post under the stair, rising more steeply than the treads fall, stays
## under them. Under the terrace behind it the ground is held under the
## deck, and past the foot a hair under the bottom tread. The rect reaches
## REACH_M past the stair on every side, so no chord to an untouched post
## crosses a tread, and is feathered over FEATHER_M beyond that. The model
## stands on the ground at its registry `base_at_m` point, on the square
## clear of the cut, so the cut reads that same point for its datum.

## Model-local front, metres: the terrace front it falls from across
## x0..x1 (out to the corner pavilions), the deck `top_m` over the foot at
## `top_z`, `risers` steps down to `foot_z`; behind the stair (|x| up to
## `deck_half`) the ground is held under the deck, behind the wings
## either side under their `wing_m` decks. Helsinki Cathedral's from
## LandmarkFhSenateFront.
static func stairs() -> Dictionary:
	return {
		"helsinki_cathedral": {"x0": -LandmarkFhSenateFront.PAV_OUT, "x1": LandmarkFhSenateFront.PAV_OUT,
			"top_m": 10.4, "top_z": LandmarkFhSenateFront.TOP_Z, "foot_z": LandmarkFhSenateFront.FOOT_Z,
			"risers": LandmarkFhSenateFront.RISERS, "deck_half": LandmarkFhSenateFront.STAIR_HALF,
			"wing_m": LandmarkFhSenateFront.WING_DECK},
	}

## Past the stair on every side: over one terrain post spacing.
const REACH_M := 10.0
const FEATHER_M := 6.0
## TerrainBuilder._hero_y sinks a model this far under its ground.
const SINK_M := 0.3
## Room kept under the treads for the bilinear chord between posts.
const CLEAR_M := 0.15

static func cut(surface: PackedFloat32Array, size: int, step: float, data: LocationData) -> void:
	if size < 2 or surface.size() != size * size:
		return
	var half := float(size) * 0.5
	var m2u := WorldScale.metres_to_units()
	var table := stairs()
	for site in LandmarkTerrain._sites(data, table.keys()):
		var entry: Dictionary = site[1]
		var spec: Dictionary = table[str(entry["type"])]
		var rect := rect_m(spec)
		var at: Vector2 = site[0]
		var axis := LandmarkSites.axis(entry)
		var side := Vector2(-axis.y, axis.x)
		var base: Array = entry.get("base_at_m", [0.0, float(spec["foot_z"])])
		var root := _sample(surface, size, step, at + (axis * float(base[0]) + side * float(base[1])) * m2u) \
			- SINK_M * m2u
		var reach := (rect.size * 0.5 + rect.get_center().abs()).length() + FEATHER_M
		var x0 := clampi(int(floor((at.x - reach * m2u) / step + half)), 0, size - 1)
		var x1 := clampi(int(ceil((at.x + reach * m2u) / step + half)), 0, size - 1)
		var z0 := clampi(int(floor((at.y - reach * m2u) / step + half)), 0, size - 1)
		var z1 := clampi(int(ceil((at.y + reach * m2u) / step + half)), 0, size - 1)
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var l := LandmarkTerrain.local_xz(Vector2((float(x) - half) * step, (float(z) - half) * step), site)
				var d := maxf(maxf(rect.position.x - l.x, l.x - rect.end.x), maxf(rect.position.y - l.y, l.y - rect.end.y))
				if d >= FEATHER_M:
					continue
				var i := z * size + x
				var target := minf(surface[i], root + hold_m(spec, l) * m2u)
				surface[i] = lerpf(target, surface[i], smoothstep(0.0, FEATHER_M, maxf(d, 0.0)))

## The cut's model-local rect (x, z), metres.
static func rect_m(spec: Dictionary) -> Rect2:
	var lo := Vector2(float(spec["x0"]) - REACH_M, float(spec["top_z"]) - REACH_M)
	var hi := Vector2(float(spec["x1"]) + REACH_M, float(spec["foot_z"]) + REACH_M)
	return Rect2(lo, hi - lo)

## Height over the model's y = 0, metres, the ground is held at, at
## model-local `l` (x, z): under the deck (or a wing's deck) behind the
## stair, under the foot below the steps, and just under the bottom tread
## on the square past it.
static func hold_m(spec: Dictionary, l: Vector2) -> float:
	if l.y < float(spec["top_z"]):
		return (float(spec["top_m"]) if absf(l.x) <= float(spec["deck_half"]) else float(spec["wing_m"])) - CLEAR_M
	if l.y <= float(spec["foot_z"]):
		return -CLEAR_M
	return float(spec["top_m"]) / (float(spec["risers"]) + 1.0) - CLEAR_M

## Bilinear surface height at world XZ (render units), as
## GroundTruth.height_at_world reads its posts.
static func _sample(surface: PackedFloat32Array, size: int, step: float, p: Vector2) -> float:
	var fx := clampf(p.x / step + float(size) * 0.5, 0.0, float(size - 1))
	var fz := clampf(p.y / step + float(size) * 0.5, 0.0, float(size - 1))
	var x0 := mini(int(fx), size - 2)
	var z0 := mini(int(fz), size - 2)
	var a := lerpf(surface[z0 * size + x0], surface[z0 * size + x0 + 1], fx - float(x0))
	var b := lerpf(surface[(z0 + 1) * size + x0], surface[(z0 + 1) * size + x0 + 1], fx - float(x0))
	return lerpf(a, b, fz - float(z0))
