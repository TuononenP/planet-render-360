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
	_cut_terraces(surface, size, step, data)

## Basin and terrace ground holds for open-air sports venues whose pool
## basins or running tracks sit directly on the terrain grid.
static func terraces() -> Dictionary:
	return {
		"samppalinnan_maauimala": {"x0": -48.0, "x1": 44.0, "z0": -22.0, "z1": 25.0, "feather_m": 6.0},
		"paavo_nurmen_stadion": {"x0": -92.0, "x1": 92.0, "z0": -72.0, "z1": 46.0, "feather_m": 8.0},
		# Sergels torg: the elevation model has the sunken plaza 1-4 m under the
		# slab's street and bumps it up in places; the whole site is held level
		# at the ground of the model's origin ("flat": raised as well as cut).
		"kulturhuset_sergels_torg": {"x0": -84.0, "x1": 84.0, "z0": -72.0, "z1": 14.0, "feather_m": 8.0,
			"flat": true},
	}

static func _cut_terraces(surface: PackedFloat32Array, size: int, step: float, data: LocationData) -> void:
	var half := float(size) * 0.5
	var m2u := WorldScale.metres_to_units()
	var table := terraces()
	for site in LandmarkTerrain._sites(data, table.keys()):
		var entry: Dictionary = site[1]
		var type := str(entry["type"])
		var spec: Dictionary = table[type]
		var rect := Rect2(float(spec["x0"]), float(spec["z0"]),
			float(spec["x1"]) - float(spec["x0"]), float(spec["z1"]) - float(spec["z0"]))
		var feather := float(spec["feather_m"])
		var at: Vector2 = site[0]
		var axis := LandmarkSites.axis(entry)
		var side := Vector2(-axis.y, axis.x)
		var base: Array = entry.get("base_at_m", [0.0, 0.0])
		var root := _sample(surface, size, step, at + (axis * float(base[0]) + side * float(base[1])) * m2u) \
			+ (float(entry.get("base_drop_m", 0.0)) - SINK_M) * m2u
		var reach := (rect.size * 0.5 + rect.get_center().abs()).length() + feather
		var x0 := clampi(int(floor((at.x - reach * m2u) / step + half)), 0, size - 1)
		var x1 := clampi(int(ceil((at.x + reach * m2u) / step + half)), 0, size - 1)
		var z0 := clampi(int(floor((at.y - reach * m2u) / step + half)), 0, size - 1)
		var z1 := clampi(int(ceil((at.y + reach * m2u) / step + half)), 0, size - 1)
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var l := LandmarkTerrain.local_xz(Vector2((float(x) - half) * step, (float(z) - half) * step), site)
				var d := maxf(maxf(rect.position.x - l.x, l.x - rect.end.x), maxf(rect.position.y - l.y, l.y - rect.end.y))
				if d >= feather:
					continue
				var i := z * size + x
				var hold := root + terrace_hold_m(type, l) * m2u
				var target := hold if bool(spec.get("flat", false)) else minf(surface[i], hold)
				surface[i] = lerpf(target, surface[i], smoothstep(0.0, feather, maxf(d, 0.0)))

## Model-local ground hold (metres over y = 0) inside a venue's terrace rect.
## Evaluates to 0.0 at base_at_m so _hero_y reads the untouched ground datum.
static func terrace_hold_m(type: String, l: Vector2) -> float:
	if type == "samppalinnan_maauimala":
		if l.x >= -25.5 and l.x <= 26.5 and l.y >= -9.6 and l.y <= 9.6:
			return -1.2
		if l.y > 14.0:
			return lerpf(0.0, 2.0, clampf((l.y - 14.0) / 10.0, 0.0, 1.0))
		if l.x > 31.0 and l.y >= -16.0:
			return lerpf(0.0, 2.0, clampf((l.x - 31.0) / 12.0, 0.0, 1.0))
		return 0.0
	if type == "paavo_nurmen_stadion":
		if l.y < -53.5 and absf(l.x) <= 59.0:
			return lerpf(0.0, 5.2, clampf((-53.5 - l.y) / 17.5, 0.0, 1.0))
		return 0.0
	return 0.0

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
