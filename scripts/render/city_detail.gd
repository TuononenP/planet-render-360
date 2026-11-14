class_name CityDetail
extends RefCounted

## Per-city detail profile: places with city open data behind them
## (Helsinki, Espoo: orthophoto, building and tree registers, canopy
## bands, a 1 m elevation model) get wider detail rings and denser
## budgets on High and Ultra. Fast and Balanced keep the shared values,
## so low-end devices see no change.
##
## Every knob is a level-of-detail range or cost, never a choice of which
## real objects exist: past a cap buildings still become impostors, so
## the layout stays the same across presets (AC-12).

## Bumped whenever a knob's value changes (WorldCache.key).
const VERSION := 1

const CITIES := ["helsinki", "espoo"]

## The detail city at (lat, lon): "helsinki", "espoo" or "".
static func city_at(lat: float, lon: float) -> String:
	var z := CityStyles.zone_at(lat, lon)
	if z.is_empty():
		return ""
	var city := str(z[0])
	return city if city in CITIES else ""

## Whether `preset` at (lat, lon) gets the raised budgets.
static func boosted(preset: int, lat: float, lon: float) -> bool:
	return RenderSettings.clamp_preset(preset) >= RenderSettings.Preset.HIGH \
		and city_at(lat, lon) != ""

static func for_data(data: LocationData) -> bool:
	return data != null and boosted(data.quality_preset, data.latitude, data.longitude)

## Real buildings fully extruded (RenderSettings.max_buildings_for).
static func max_buildings(data: LocationData, forward_plus: bool = RenderQuality.is_forward_plus()) -> int:
	var base := RenderSettings.max_buildings_for(data.quality_preset, forward_plus)
	if not for_data(data):
		return base
	if RenderSettings.clamp_preset(data.quality_preset) == RenderSettings.Preset.HIGH:
		return 4000
	return 14000 if forward_plus else 8000

## Roofline detail ring (BuildingDetail): `base` raised in a detail city.
static func near_radius(data: LocationData, base: float) -> float:
	if not for_data(data):
		return base
	if RenderSettings.clamp_preset(data.quality_preset) == RenderSettings.Preset.HIGH:
		return maxf(base, 450.0)
	return maxf(base, 900.0)

## Terrain mesh posts (terrain AND road drape must agree).
static func terrain_mesh_posts(data: LocationData) -> int:
	var base := RenderSettings.terrain_mesh_posts_for(data.quality_preset)
	return RenderSettings.GROUND_POSTS if for_data(data) else base

## Ultra-desktop street extras (kerbs, tree pits, furniture, decals):
## also on High desktop in a detail city.
static func street_extras(data: LocationData, forward_plus: bool = RenderQuality.is_forward_plus()) -> bool:
	if RenderQuality.ultra_desktop(data.quality_preset, forward_plus):
		return true
	return forward_plus and for_data(data)

## Inner aerial mosaic (zoom, span) for the city orthophoto; (0, 0) when
## none. Ultra desktop z19 (≈0.15 m/px over ~570 m), else z18.
static func inner_imagery(preset: int, lat: float, lon: float,
		forward_plus: bool = RenderQuality.is_forward_plus()) -> Vector2i:
	if not boosted(preset, lat, lon):
		return Vector2i.ZERO
	var ultra := RenderSettings.clamp_preset(preset) == RenderSettings.Preset.ULTRA
	if ultra:
		return Vector2i(19, 15) if forward_plus else Vector2i(18, 9)
	return Vector2i(18, 11) if forward_plus else Vector2i(18, 7)

## Whether register-only trees (no OSM node) are planted: High and Ultra.
static func extra_trees(data: LocationData) -> bool:
	return for_data(data)
