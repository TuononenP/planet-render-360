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
	var nordic := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country) == "nordic"
	if (c < -3.0 and w < 17.0) or (nordic and c < -2.0 and w < 18.0):
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
##  - wetness: rain/drizzle darkens and glosses the ground; rain (0..1)
##    is how hard it falls: ripples, puddle reach, a rougher sea;
##  - ice: still water freezes in cold-winter climates.
## Spliced into shaders at "// @SNOW".
const SNOW_GLSL := """
global uniform float climate_snow_on;
global uniform float climate_snow_y;
global uniform float climate_snow_band;
global uniform float climate_wetness;
global uniform float climate_rain;
global uniform float climate_snow_glint;
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
float snow_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float snow_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(snow_hash(i), snow_hash(i + vec2(1.0, 0.0)), u.x),
		mix(snow_hash(i + vec2(0.0, 1.0)), snow_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
// Metre-scale mottling where snow thins (0..1).
float snow_patch(vec2 p) {
	return snow_noise(p / 7.0) * 0.5 + snow_noise(p / 1.9) * 0.35 + snow_noise(p / 0.55) * 0.15;
}
// How low the ground lies, for where rain collects. Each octave settles
// to its mean before the pixel footprint can alias it into shimmer.
float puddle_low(vec2 g, float pixel_m) {
	float fine = mix(snow_noise(g / 1.8), 0.5, smoothstep(0.3, 1.5, pixel_m));
	float broad = mix(snow_noise(g / 5.5), 0.5, smoothstep(1.5, 6.0, pixel_m));
	return fine * 0.65 + broad * 0.35;
}
// Where rain lies, from puddle_low: x standing water, y its damp rim.
vec2 puddle_mask(float low) {
	float th = 0.74 - 0.05 * climate_rain;
	return vec2(smoothstep(th, th + 0.06, low), smoothstep(th - 0.11, th, low));
}
vec3 puddle_albedo(vec3 c, vec2 mask) {
	vec3 damp = mix(c, c * 0.84, mask.y);
	return mix(damp, damp * 0.55, mask.x);
}
float puddle_roughness(float r, float wet, vec2 mask) {
	r = mix(r, 0.32, wet * 0.85);
	r = mix(r, 0.16, mask.y * 0.6);
	return mix(r, 0.03, mask.x);
}
// Fragment only. Thin snow lies in patches with real edges, instead of
// greying the whole ground; a full cover closes every gap.
float snow_cover(vec3 p, float ny) {
	// Derivatives first: every pixel of a quad must reach them.
	float px = max(fwidth(p.x), fwidth(p.z));
	float line = snow_line(p);
	if (line <= 0.0) { return 0.0; }
	float n = mix(snow_patch(p.xz), 0.5, smoothstep(0.8, 5.0, px));
	return smoothstep(n - 0.12, n + 0.12, line * 1.3) * smoothstep(0.45, 0.72, ny);
}
// Snow cover at a point with no derivatives, for vertex shaders: where
// lying snow buries low plants, whole instances at a time.
float snow_bury(vec3 p) {
	float line = snow_line(p);
	if (line <= 0.0) { return 0.0; }
	float n = snow_patch(p.xz);
	return smoothstep(n - 0.12, n + 0.12, line * 1.3);
}
// Slope of the wind-sculpted surface, for the lighting normal.
vec2 snow_drift(vec2 p) {
	float e = 0.35;
	float a = snow_noise(p / 5.5) + 0.45 * snow_noise(p / 1.6);
	float x = snow_noise((p + vec2(e, 0.0)) / 5.5) + 0.45 * snow_noise((p + vec2(e, 0.0)) / 1.6);
	float z = snow_noise((p + vec2(0.0, e)) / 5.5) + 0.45 * snow_noise((p + vec2(0.0, e)) / 1.6);
	return vec2(x - a, z - a) / e;
}
// Lying snow's surface response, shared so every snowy surface matches:
// glossier than chalk, and a soft forward-scatter sheen at grazing
// angles (RIM), which is most of what keeps snow from reading as matte
// white plastic.
const float SNOW_ROUGH = 0.72;
const float SNOW_SPEC = 0.35;
const float SNOW_RIM = 0.3;
const float SNOW_RIM_TINT = 0.65;
// Snow colour at metre coordinates p: never one flat white. Faint grain
// at two scales and wind hollows a touch bluer (they see sky, not sun),
// each settling to its mean before pixel_m can alias it; age (0 fresh,
// 1 trodden or ploughed) dulls it to a grey buff with grit in it.
vec3 snow_albedo(vec2 p, float pixel_m, float age) {
	float fine = mix(snow_noise(p / 0.4), 0.5, smoothstep(0.02, 0.12, pixel_m));
	float mid = mix(snow_noise(p / 2.6), 0.5, smoothstep(0.3, 2.0, pixel_m));
	float broad = mix(snow_noise(p / 11.0 + 3.7), 0.5, smoothstep(2.0, 10.0, pixel_m));
	vec3 c = snow_col * (0.95 + 0.05 * mid + 0.04 * fine);
	c *= mix(vec3(0.90, 0.95, 1.02), vec3(1.0), smoothstep(0.25, 0.65, broad));
	vec3 old = vec3(0.60, 0.59, 0.56) * (0.88 + 0.16 * mid + 0.08 * fine);
	return mix(c, old, clamp(age, 0.0, 1.0));
}
// Sand and fine gravel spread on trodden snow (Nordic towns grit their
// streets and walks): sparse brown specks in patches near by, settling
// into their average buff tint before they could shimmer.
vec3 snow_grit(vec3 c, vec2 p, float pixel_m, float amount) {
	float a = amount * smoothstep(0.2, 0.8, mix(snow_noise(p / 1.7 + 9.1), 0.5, smoothstep(0.3, 1.5, pixel_m)) + 0.15);
	// Round grains of 5-12 mm, jittered in 4 cm cells.
	vec2 q = p * 25.0;
	vec2 id = floor(q);
	vec2 ctr = vec2(snow_hash(id + 1.7), snow_hash(id + 4.3)) * 0.6 + 0.2;
	float r = 0.12 + 0.14 * snow_hash(id + 8.9);
	float aa = max(pixel_m * 25.0, 1e-3);
	float grain = (1.0 - smoothstep(r - aa, r + aa, length(fract(q) - ctr))) * step(snow_hash(id), 0.24 * a);
	// Further out, the grains' average (pi r^2 per live cell).
	float cover = mix(0.027 * a, grain, 1.0 - smoothstep(0.004, 0.015, pixel_m));
	return mix(c, vec3(0.40, 0.33, 0.25) * (0.8 + 0.4 * snow_hash(id + 5.3)), clamp(cover, 0.0, 1.0));
}
// Snow lies centimetres deep, so a patch ends in a rounded lip, not a
// stencil line. From the cover `sc` at world point p: xy the world-xz
// slope of that lip (bend the lighting normal by -slope), z how much of
// an edge this is (0..1, for a contact shade just outside it). Uses
// derivatives: call where every pixel of the quad runs it.
vec3 snow_edge(float sc, vec3 p, float depth_m) {
	float sx = dFdx(sc);
	float sy = dFdy(sc);
	float a = dFdx(p.x);
	float b = dFdx(p.z);
	float c = dFdy(p.x);
	float d = dFdy(p.z);
	float det = a * d - b * c;
	if (abs(det) < 1e-9) { return vec3(0.0); }
	vec2 g = vec2(d * sx - b * sy, a * sy - c * sx) / det * depth_m;
	float len = length(g);
	// At most ~40 degrees: a lip, never a wall.
	g *= min(1.0, 0.85 / max(len, 1e-5));
	return vec3(g, min(len * 2.0, 1.0));
}
// Ice crystals: rare cells whose tilted facet can throw the sun back.
// xyz facet normal (world), w strength; fades before a pixel can span
// several cells and strobe. Only under a direct sun: a cloud deck has
// nothing sharp to reflect.
vec4 snow_facet(vec2 p, float pixel_m) {
	float vis = climate_snow_glint * (1.0 - smoothstep(0.012, 0.045, pixel_m));
	if (vis <= 0.0) { return vec4(0.0, 1.0, 0.0, 0.0); }
	vec2 id = floor(p * 40.0);
	if (snow_hash(id) < 0.985) { return vec4(0.0, 1.0, 0.0, 0.0); }
	vec3 f = vec3(snow_hash(id + 3.1) - 0.5, 0.42, snow_hash(id + 7.7) - 0.5);
	return vec4(normalize(f), vis);
}
// Slope of rain rings on still water at metre coordinates: jittered
// cells at three scales, so no grid shows; rain sets how many are live.
// Rings are centimetres wide: gone before a pixel can alias them.
vec2 rain_ripples(vec2 m, float t, float pixel_m) {
	vec2 s = vec2(0.0);
	float vis = 1.0 - smoothstep(0.012, 0.05, pixel_m);
	if (climate_rain <= 0.0 || vis <= 0.0) { return s; }
	for (int l = 0; l < 3; l++) {
		float fl = float(l);
		vec2 p = m * (1.7 + fl * 0.9) + fl * vec2(7.3, 3.1);
		vec2 id = floor(p);
		float h = snow_hash(id + fl);
		if (h > 0.2 + 0.8 * climate_rain) { continue; }
		vec2 c = fract(p) - 0.5 - (vec2(snow_hash(id + 11.3), snow_hash(id + 5.7)) - 0.5) * 0.3;
		float age = fract(t * (0.75 + h * 0.6) + h * 9.0);
		float r = length(c);
		float front = r - age * 0.34;
		float fade = (1.0 - age) * (1.0 - age);
		s += c / max(r, 1e-3) * sin(front * 45.0) * exp(-front * front * 300.0) * fade;
	}
	return s * vis;
}
"""

const GLOBALS := ["climate_snow_on", "climate_snow_y", "climate_snow_band",
	"climate_wetness", "climate_rain", "climate_snow_glint", "climate_water_ice", "valley_haze_y"]
## Open-Meteo WMO codes: falling snow / rain (incl. showers, storms).
const SNOWING := [71, 73, 75, 77, 85, 86]
const RAINING := [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]
## Coldest-quarter mean (°C) below which still water freezes over.
const ICE_C := -4.0
## A viewpoint well under the snow line has white streets: a soft 150 m
## band centred on it left them at 55-65% cover, grey rather than white.
## Over SNOWY_RAMP_M under the line, the line eases to SNOWY_LINE_M and
## its band to SNOWY_BAND_M. A line already further down than
## SNOWY_DEEP_M covers the viewpoint anyway and keeps its soft band.
const SNOW_BAND_M := 150.0
const SNOWY_RAMP_M := 120.0
const SNOWY_LINE_M := -150.0
const SNOWY_BAND_M := 60.0
const SNOWY_DEEP_M := Vector2(150.0, 350.0)

## [line, band] in metres for a snow line `line_m` from the viewpoint
## (negative: the viewpoint is above it, under snow). Continuous in line_m.
static func settled_line(line_m: float) -> Vector2:
	var under := clampf(-line_m / SNOWY_RAMP_M, 0.0, 1.0)
	var narrow := under * (1.0 - smoothstep(SNOWY_DEEP_M.x, SNOWY_DEEP_M.y, -line_m))
	return Vector2(lerpf(line_m, minf(line_m, SNOWY_LINE_M), under), lerpf(SNOW_BAND_M, SNOWY_BAND_M, narrow))

## Snow parameters: snow line in render Y (the viewpoint elevation is
## Y = 0, GroundTruth's datum). Falling snow at a place cold enough to
## settle (season temperature ≤ 2 °C at the viewpoint) brings the line
## down to the viewpoint whatever the season.
static func snow_uniforms(data: LocationData, weather_code: int = -1) -> Dictionary:
	var s := LocationData.clamp_season(data.season)
	var m2u := WorldScale.metres_to_units()
	var on := 0.0 if s == LocationData.Season.SUMMER else 1.0
	var line_m := snowline_m(data, s) - data.centre_elevation_m
	if weather_code in SNOWING and (not has(data) or season_temp_c(data, s) <= 2.0):
		on = 1.0
		line_m = minf(line_m, -SNOWY_RAMP_M)
	var settled := settled_line(line_m) if on > 0.0 else Vector2(line_m, SNOW_BAND_M)
	return {"climate_snow_on": on, "climate_snow_y": settled.x * m2u, "climate_snow_band": settled.y * m2u}

## Whether still water is frozen this season: winter where the coldest
## quarter averages ≤ ICE_C (CHELSA), else winter above 60° latitude.
static func water_frozen(data: LocationData) -> bool:
	if LocationData.clamp_season(data.season) != LocationData.Season.WINTER:
		return false
	if has(data):
		return ice_amount(data) > 0.0
	return absf(data.latitude) >= 60.0

## Every global for `data` under live weather `weather_code` (-1 none).
static func globals_for(data: LocationData, weather_code: int = -1) -> Dictionary:
	var g := snow_uniforms(data, weather_code)
	g["climate_wetness"] = 1.0 if weather_code in RAINING else 0.0
	g["climate_rain"] = float(WeatherLook.for_code(weather_code, 100.0)["intensity"]) if weather_code in RAINING else 0.0
	g["climate_water_ice"] = ice_amount(data)
	g["valley_haze_y"] = valley_y(data)
	return g

## Valley floor around the viewpoint in render Y (the viewpoint is Y = 0).
static func valley_y(data: LocationData) -> float:
	return (DemStats.valley_asl_m(data) - data.centre_elevation_m) * WorldScale.metres_to_units()

static func apply_globals(data: LocationData, weather_code: int = -1) -> void:
	var g := globals_for(data, weather_code)
	for k in g:
		RenderingServer.global_shader_parameter_set(k, g[k])

## Freeze potential, with a soft cold-quarter band around ICE_C. It is
## localised to sheltered shallow water by WaterShader, not the open sea.
static func ice_amount(data: LocationData) -> float:
	if LocationData.clamp_season(data.season) != LocationData.Season.WINTER:
		return 0.0
	if has(data):
		return 1.0 - smoothstep(ICE_C - 2.0, ICE_C + 3.0, float(data.climate["t_cold_c"]))
	return 0.65 if absf(data.latitude) >= 60.0 else 0.0

## Monthly mean when provided by the climate source. CHELSA's quarterly
## normals otherwise give a smooth seasonal estimate (thermal lag into
## February/August); no climate keeps the calendar's ordinary seasons.
static func month_temp_c(data: LocationData, month: int) -> float:
	var monthly: Array = data.climate.get("t_monthly_c", [])
	if monthly.size() == 12:
		return float(monthly[clampi(month, 1, 12) - 1])
	if not has(data):
		return INF
	var cold_month := 2.0 if data.latitude >= 0.0 else 8.0
	var fraction := (1.0 - cos(TAU * (float(month) - cold_month) / 12.0)) * 0.5
	return lerpf(float(data.climate["t_cold_c"]), float(data.climate["t_warm_c"]), fraction)
