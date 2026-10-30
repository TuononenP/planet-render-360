class_name ClimateModel
extends RefCounted

## Place climate → what the ground and vegetation should look like
## (CHELSA normals in LocationData.climate; latitude rules otherwise).
## CHELSA's 1 km cells carry the temperature of their own mean
## elevation, taken here as the viewpoint's (centre_elevation_m), and a
## standard lapse rate carries it up and down the relief, so the snow
## line and treeline are isotherms of the real place instead of
## latitude bands. Calibrated on the golden locations (CHELSA values,
## 2026-10-30): Interlaken winter snow ≈ 1000 m, April ≈ 1850 m,
## permanent snow ≈ 3000 m, treeline ≈ 2200 m; Banff treeline ≈ 2270 m;
## Paris never snowy; Big Sur summer-dry (golden hills); Cairo arid.

const LAPSE_C_PER_M := 0.0065
## Seasonal mean (°C) at which ground snow holds: winter / spring use
## colder thresholds than the persistent summer firn line.
const SNOW_C := [1.5, 2.5, -1.0, -1.5]  # spring, summer, autumn, winter
## Warmest-quarter mean at the climatic treeline (Körner's 6.4 °C
## growing-season isotherm sits near a 7.5 °C warmest quarter).
const TREELINE_C := 7.5
## Warmest-quarter share of annual precipitation below which summers
## are dry (Köppen Cs-like): grass reads golden, not green, in summer.
const SUMMER_DRY_SHARE := 0.12

static func has(data: LocationData) -> bool:
	return data != null and data.climate.has("t_warm_c") and data.climate.has("t_cold_c")

## Seasonal mean temperature (°C) at the viewpoint elevation.
static func season_temp_c(data: LocationData, season: int) -> float:
	var w := float(data.climate["t_warm_c"])
	var c := float(data.climate["t_cold_c"])
	match LocationData.clamp_season(season):
		LocationData.Season.SUMMER:
			return w
		LocationData.Season.WINTER:
			return c
	return (w + c) * 0.5

## Elevation (m ASL) where `temp_c` at the viewpoint cools to `target_c`.
static func isotherm_m(data: LocationData, temp_c: float, target_c: float) -> float:
	return data.centre_elevation_m + (temp_c - target_c) / LAPSE_C_PER_M

## Latitude fallbacks (no climate data). Treeline ~3900 m in the
## tropics, ~2100 m at 45° (Alps), ~650 m at 65°, sea level past ~74°;
## permanent summer snow ~900 m above it, winter snow well below.
static func latitude_treeline_m(lat: float) -> float:
	var a := absf(lat)
	return clampf(3900.0 - 72.0 * maxf(a - 20.0, 0.0), 0.0, 3900.0)

static func latitude_snowline_m(lat: float, season: int) -> float:
	var offs := [350.0, 900.0, 600.0, -900.0]  # spring, summer, autumn, winter
	return maxf(latitude_treeline_m(lat) + float(offs[clampi(season, 0, 3)]), 0.0)

## Snow line (m ASL) for the season: CHELSA isotherm, else latitude.
static func snowline_m(data: LocationData, season: int) -> float:
	if not has(data):
		return latitude_snowline_m(data.latitude, season)
	var s := LocationData.clamp_season(season)
	return isotherm_m(data, season_temp_c(data, s), float(SNOW_C[s]))

## Climatic treeline (m ASL): CHELSA isotherm, else latitude.
static func treeline_m(data: LocationData) -> float:
	if not has(data):
		return latitude_treeline_m(data.latitude)
	return maxf(isotherm_m(data, float(data.climate["t_warm_c"]), TREELINE_C), 0.0)

## 0..1 snow cover at elevation `h_asl` (soft ±band metres).
static func snow_at(data: LocationData, season: int, h_asl: float, band: float = 200.0) -> float:
	var sl := snowline_m(data, season)
	return smoothstep(sl - band, sl + band, h_asl)

## Whether the viewpoint itself lies under seasonal snow (vegetation
## snow loads, valley-floor snow): its own elevation above the snow line.
static func snowy_at_viewpoint(data: LocationData, season: int) -> bool:
	return snowline_m(data, season) <= data.centre_elevation_m

## Dry summers (Mediterranean-type): little of the year's rain falls in
## the warmest quarter.
static func summer_dry(data: LocationData) -> bool:
	if not has(data):
		return false
	var p := float(data.climate.get("precip_mm", 0.0))
	return p > 0.0 and float(data.climate.get("precip_warm_mm", p)) / p < SUMMER_DRY_SHARE

## Köppen-B aridity: annual precipitation under 20 × (mean °C + 7) mm.
static func arid(data: LocationData) -> bool:
	if not has(data):
		return false
	var t := (float(data.climate["t_warm_c"]) + float(data.climate["t_cold_c"])) * 0.5
	return float(data.climate.get("precip_mm", 1e9)) < 20.0 * (t + 7.0)

## Vegetation biome from climate (TreeSpecies vocabulary), "" without
## climate data so the caller keeps its regional rule. Regional flavour
## (east Asian species) is the caller's; this decides the climate class.
static func biome(data: LocationData) -> String:
	if not has(data):
		return ""
	var w := float(data.climate["t_warm_c"])
	var c := float(data.climate["t_cold_c"])
	if arid(data):
		return "arid"
	if c >= 18.0:
		return "tropical"
	if data.centre_elevation_m > treeline_m(data) - 700.0:
		return "alpine"
	if c < -3.0 and w < 17.0:
		return "boreal"
	if summer_dry(data) and c > -3.0:
		return "mediterranean"
	return "temperate"

## Ground-cover tint for vegetation-class ground: green, the golden
## grass of a dry summer, or sparse arid ground (linear colours; null
## alpha 0 means "keep the caller's season palette").
static func grass_tint(data: LocationData, season: int) -> Color:
	if arid(data):
		return Color(0.42, 0.33, 0.20, 1.0)
	if summer_dry(data) and LocationData.clamp_season(season) in [LocationData.Season.SUMMER, LocationData.Season.AUTUMN]:
		return Color(0.47, 0.38, 0.19, 1.0)
	return Color(0, 0, 0, 0)

## Live surface state shared by every draped / vegetation / water
## shader through Godot global shader parameters (project.godot
## [shader_globals]): one place is shown at a time, and a season change
## or live weather (snowfall, rain) then updates the world instantly,
## without a rebuild — and cached worlds carry no place's snow line.
##  - snow: satellite mosaics are mostly summer captures, so outside
##    summer the climate snow above the snow line is painted over them
##    (in summer the imagery shows the real glaciers); trees load snow
##    by their own height against the same line;
##  - wetness: rain/drizzle darkens and glosses the ground;
##  - ice: still water freezes in cold-winter climates.
## Spliced into shaders at "// @SNOW".
const SNOW_GLSL := """
global uniform float climate_snow_on;
global uniform float climate_snow_y;
global uniform float climate_snow_band;
global uniform float climate_wetness;
global uniform float climate_water_ice;
uniform vec3 snow_col : source_color = vec3(0.90, 0.92, 0.95);
float snow_line(vec3 p) {
	if (climate_snow_on <= 0.0) { return 0.0; }
	float wob = sin(p.x * 0.011 + sin(p.z * 0.017) * 2.0) * 0.5
		+ sin(p.z * 0.029 + p.x * 0.007) * 0.3;
	float h = p.y + wob * climate_snow_band * 0.8;
	return climate_snow_on * smoothstep(climate_snow_y - climate_snow_band,
		climate_snow_y + climate_snow_band, h);
}
float snow_cover(vec3 p, float ny) {
	return snow_line(p) * smoothstep(0.45, 0.72, ny);
}
"""

const GLOBALS := ["climate_snow_on", "climate_snow_y", "climate_snow_band",
	"climate_wetness", "climate_water_ice"]
## Open-Meteo WMO codes: falling snow / rain (incl. showers, storms).
const SNOWING := [71, 73, 75, 77, 85, 86]
const RAINING := [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]
## Coldest-quarter mean (°C) below which still water freezes over.
const ICE_C := -4.0

## Snow parameters: snow line in render Y (the viewpoint elevation is
## Y = 0, GroundTruth's datum). Falling snow at a place cold enough to
## settle (season temperature ≤ 2 °C at the viewpoint) brings the line
## down to the viewpoint whatever the season.
static func snow_uniforms(data: LocationData, weather_code: int = -1) -> Dictionary:
	var s := LocationData.clamp_season(data.season)
	var m2u := WorldScale.metres_to_units()
	var on := 0.0 if s == LocationData.Season.SUMMER else 1.0
	var line := (snowline_m(data, s) - data.centre_elevation_m) * m2u
	if weather_code in SNOWING and (not has(data) or season_temp_c(data, s) <= 2.0):
		on = 1.0
		line = minf(line, -30.0 * m2u)
	return {"climate_snow_on": on, "climate_snow_y": line, "climate_snow_band": 150.0 * m2u}

## Whether still water is frozen this season: winter where the coldest
## quarter averages ≤ ICE_C (CHELSA), else winter above 60° latitude.
static func water_frozen(data: LocationData) -> bool:
	if LocationData.clamp_season(data.season) != LocationData.Season.WINTER:
		return false
	if has(data):
		return float(data.climate["t_cold_c"]) <= ICE_C
	return absf(data.latitude) >= 60.0

## Every global for `data` under live weather `weather_code` (-1 none).
static func globals_for(data: LocationData, weather_code: int = -1) -> Dictionary:
	var g := snow_uniforms(data, weather_code)
	g["climate_wetness"] = 1.0 if weather_code in RAINING else 0.0
	g["climate_water_ice"] = 1.0 if water_frozen(data) else 0.0
	return g

static func apply_globals(data: LocationData, weather_code: int = -1) -> void:
	var g := globals_for(data, weather_code)
	for k in g:
		RenderingServer.global_shader_parameter_set(k, g[k])
