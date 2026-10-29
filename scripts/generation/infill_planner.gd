class_name InfillPlanner
extends RefCounted

## T4.5 — procedural infill is absence-only and style-matched.
## allows(x, z): infill may stand at XZ only when
##  - OSM buildings are ABSENT there (no real centroid within ABSENT_M),
##    not merely sparse — a fully mapped city gets 0 infill;
##  - and real evidence says settlement: SettlementMap (far imagery
##    drape + OSM built-up landuse) scores the cell ≥ MIN_SCORE and does
##    not block it as vegetation/water, or OSM land cover at XZ is
##    `urban`; any non-urban OSM land class (forest, grass, water,
##    field, …) or a slope over MAX_SLOPE refuses it.
##  With no OSM buildings AND no settlement source at all (offline, the
##  procedural DEM) nothing can be judged: the v1 regional fallback
##  runs (no-faked-fidelity rule: real data for the layer is absent).
## style(x, z, seed): the kind and total height of a real neighbour —
## the nearest NEAREST_K real buildings within STYLE_M, one picked by
## seed, so the infill's height histogram follows the local real one;
## with no neighbours, low regional houses where the settlement score
## is low (rural/coast), the region's mix where it is dense.

const ABSENT_M := 120.0
const STYLE_M := 700.0
const NEAREST_K := 12
const MIN_SCORE := 0.3
const MAX_SLOPE := 0.35
const HASH_CELL_M := 100.0

var _data: LocationData
var _ground: GroundTruth
var _smap: SettlementMap
var _ctx: Dictionary
var _hash := {}  # Vector2i cell -> Array of building dicts
## True when nothing can judge settlement (v1 fallback).
var fallback := false

func _init(data: LocationData, ground: GroundTruth, smap: SettlementMap,
		ctx: Dictionary) -> void:
	_data = data
	_ground = ground
	_smap = smap
	_ctx = ctx
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var c := _cell(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
		if not _hash.has(c):
			_hash[c] = []
		(_hash[c] as Array).append(b)
	var has_cover := false
	for poly in data.land_polygons:
		if poly is Dictionary and str((poly as Dictionary).get("class", "")) == "urban":
			has_cover = true
			break
	fallback = data.buildings.is_empty() and not has_cover \
		and (smap == null or smap.is_empty())

func _cell(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / HASH_CELL_M), floori(z / HASH_CELL_M))

## Real buildings within r of XZ, nearest first (at most k).
func _near(x: float, z: float, r: float, k: int) -> Array:
	var out: Array = []
	var c := _cell(x, z)
	var reach := int(ceil(r / HASH_CELL_M))
	for i in range(c.x - reach, c.x + reach + 1):
		for j in range(c.y - reach, c.y + reach + 1):
			for b in _hash.get(Vector2i(i, j), []):
				var d := Vector2(float(b["x"]) - x, float(b["z"]) - z).length()
				if d <= r:
					out.append([d, b])
	out.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return out.slice(0, k)

func allows(x: float, z: float) -> bool:
	if fallback:
		return true
	if not _near(x, z, ABSENT_M, 1).is_empty():
		return false  # OSM maps buildings here: present, maybe sparse
	if _ground.slope_at(x, z) > MAX_SLOPE:
		return false
	var cover := _ground.land_class_at(x, z)
	if cover == "urban":
		return true
	if cover != "":
		return false  # forest, grass, water, field, … are not settlement
	if _smap == null or _smap.is_empty():
		return false
	return _smap.blocked_at(x, z) == 0 and _smap.score_at(x, z) >= MIN_SCORE

## {kind, total_m}: total_m ≤ 0 means "the look's regional default".
func style(x: float, z: float, seed_v: float) -> Dictionary:
	var region := str(_ctx.get("region", "generic"))
	if fallback:
		return {"kind": ArchitectureStyle.infill_kind(region, seed_v), "total_m": -1.0}
	var near := _near(x, z, STYLE_M, NEAREST_K)
	if not near.is_empty():
		var pick: Dictionary = near[mini(int(seed_v * float(near.size())), near.size() - 1)][1]
		var area := BuildingBuilder._area_m2(pick)
		var kind := ArchitectureStyle.kind_for(pick, str(_ctx.get("density", "mid")), area)
		if kind in ["religious", "civic"]:
			kind = "house" if area < 250.0 else "apartments"
		var h := -1.0
		var src := str(pick.get("height_source", ""))
		if src == "tag_height" or src == "levels" or src == "":
			h = float(pick.get("height", -1.0)) * (0.92 + 0.16 * fmod(seed_v * 7.13, 1.0))
		return {"kind": kind, "total_m": h}
	# No real neighbour to match: low houses unless the imagery says dense.
	var s := _smap.score_at(x, z) if _smap != null else 0.0
	if s >= 0.6:
		return {"kind": ArchitectureStyle.infill_kind(region, seed_v), "total_m": -1.0}
	return {"kind": "house" if seed_v > 0.2 else "outbuilding", "total_m": -1.0}
