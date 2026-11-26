class_name WeatherDressing
extends RefCounted

## Unified weather- and climate-driven surface dressing solver.
## Combines CHELSA V2.1 climatology (LocationData.climate), live Open-Meteo
## telemetry (or synthesized Conditions sheet presets), calendar date, and
## solar elevation into continuous Godot global shader parameters:
##   - climate_snow_depth / climate_snow_thaw (roofs, landmarks, ground)
##   - climate_frost (window rime/hoarfrost with diurnal & moisture gating)
##   - climate_autumn / climate_autumn_lapse (continuous foliage phenology)
## All live dressing updates instantaneously with zero world rebuild and never
## mutates shared StandardMaterial3D resources (WorldCache-safe).

const MONTH_DOY := [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
## Open-Meteo WMO codes that deposit rime/glaze frost directly on glass.
const FREEZING_CODES := [48, 56, 57, 66, 67]

## Synthesizes physically coherent weather telemetry for a Conditions sheet
## preset (DatePicker.WEATHER index 1..7), anchored to the place's CHELSA
## or seasonal temperature so presets never leak stale live summer/winter temp.
static func weather_for_pick(pick: int, data: LocationData, date: Dictionary = {}) -> Dictionary:
	var row: Array = DatePicker.WEATHER[clampi(pick, 0, DatePicker.WEATHER.size() - 1)]
	var code := int(row[2])
	var cover := float(row[3])
	var base_t := _seasonal_temp_c(data, date)
	var arid := data != null and ClimateModel.arid(data)
	var out := {"code": code, "cloud": cover, "has_temp": true, "temp": base_t, "preset": true}
	match code:
		0:  # Clear
			out["rh"] = 22.0 if arid else 48.0
			out["dew_point_c"] = base_t - (16.0 if arid else 9.0)
			out["visibility_m"] = 28000.0
		3:  # Cloudy
			out["rh"] = 38.0 if arid else 72.0
			out["dew_point_c"] = base_t - (11.0 if arid else 4.5)
			out["visibility_m"] = 18000.0
		45:  # Fog (becomes freezing rime fog when sub-zero)
			var fog_code := 48 if base_t <= -1.0 else 45
			out["code"] = fog_code
			out["rh"] = 98.0
			out["dew_point_c"] = base_t - 0.3
			out["visibility_m"] = 400.0 if fog_code == 48 else 550.0
		61:  # Rain
			out["rh"] = 88.0
			out["dew_point_c"] = base_t - 1.8
			out["visibility_m"] = 9000.0
		65:  # Heavy rain
			out["rh"] = 95.0
			out["dew_point_c"] = base_t - 0.8
			out["visibility_m"] = 2000.0
		73:  # Snow
			var snow_t := minf(base_t, -2.5)
			out["temp"] = snow_t
			out["rh"] = 88.0
			out["dew_point_c"] = snow_t - 1.5
			var clim_pack := ClimateModel.snowpack_index(data, data.season, date) if data != null else 0.4
			out["snow_depth_m"] = maxf(clim_pack * 0.50, 0.22)
			out["snowfall_cm"] = 1.8
			out["visibility_m"] = 800.0
		95:  # Storm
			out["rh"] = 93.0
			out["dew_point_c"] = base_t - 1.2
			out["visibility_m"] = 3000.0
	return out

## Effective temperature (°C) from live weather when reported, else CHELSA
## monthly/seasonal mean, else latitude fallback.
static func effective_temp_c(data: LocationData, weather: Dictionary, date: Dictionary = {}) -> float:
	if bool(weather.get("has_temp", false)):
		return float(weather["temp"])
	return _seasonal_temp_c(data, date)

static func _seasonal_temp_c(data: LocationData, date: Dictionary = {}) -> float:
	if data == null:
		return 12.0
	if ClimateModel.has(data):
		if not date.is_empty() and date.has("month"):
			var mt := ClimateModel.month_temp_c(data, int(date["month"]))
			if is_finite(mt):
				return mt
		return ClimateModel.season_temp_c(data, data.season)
	var lat := absf(data.latitude)
	var s := LocationData.clamp_season(data.season)
	var winter_t := clampf(26.0 - maxf(lat - 15.0, 0.0) * 0.72, -16.0, 26.0)
	var summer_t := clampf(28.0 - maxf(lat - 25.0, 0.0) * 0.35, 8.0, 30.0)
	match s:
		LocationData.Season.WINTER:
			return winter_t
		LocationData.Season.SUMMER:
			return summer_t
	return (winter_t + summer_t) * 0.5

## Snow line + continuous accumulation depth (0..1) and thaw/slush (0..1).
static func snow_state(data: LocationData, weather: Dictionary, date: Dictionary = {}) -> Dictionary:
	var code := int(weather.get("code", -1))
	var base := ClimateModel.snow_uniforms(data, code)
	var on := float(base["climate_snow_on"]) > 0.0
	var line_y := float(base["climate_snow_y"])
	var band := float(base["climate_snow_band"])
	var m2u := WorldScale.metres_to_units()
	var t_eff := effective_temp_c(data, weather, date)
	var s := LocationData.clamp_season(data.season)
	var snowing := code in ClimateModel.SNOWING or float(weather.get("snowfall_cm", 0.0)) > 0.05
	var has_live_depth := weather.has("snow_depth_m")
	var live_depth_m := float(weather.get("snow_depth_m", 0.0))

	# Live snow on the ground (or falling below freezing) brings the snow line
	# down to the viewpoint even outside winter; warm summer snowfall stays off.
	if has_live_depth and live_depth_m > 0.01 and t_eff <= 5.0:
		on = true
		var settled := ClimateModel.settled_line(-ClimateModel.SNOWY_RAMP_M)
		line_y = minf(line_y, settled.x * m2u)
		band = minf(band, settled.y * m2u)
	elif snowing and t_eff <= 2.0 and s != LocationData.Season.SUMMER:
		on = true
		var settled := ClimateModel.settled_line(-ClimateModel.SNOWY_RAMP_M)
		line_y = minf(line_y, settled.x * m2u)
		band = minf(band, settled.y * m2u)

	var depth := 0.0
	if on:
		var clim_d := ClimateModel.snowpack_index(data, s, date)
		if has_live_depth:
			var live_d := smoothstep(0.01, 0.50, live_depth_m)
			# If live snow_depth is 0 at the valley floor, preserve high-altitude
			# mountain pack above the snow line while keeping valley roofs bare.
			if live_depth_m <= 0.005 and line_y > 0.0:
				depth = clim_d
			else:
				depth = live_d
		else:
			depth = clim_d
		if snowing and t_eff <= 2.0:
			var inten := float(WeatherLook.for_code(code, 100.0)["intensity"]) if code in ClimateModel.SNOWING \
				else clampf(float(weather.get("snowfall_cm", 0.0)) / 3.0, 0.15, 1.0)
			depth = maxf(depth, clampf(0.12 + 0.35 * inten, 0.12, 0.55))
		# Ensure alpine snow above the snow line stays visible when on.
		if depth < 0.05 and line_y > 0.0:
			depth = maxf(depth, 0.35)

	var thaw := 0.0
	if depth > 0.02:
		var warm_thaw := smoothstep(-0.5, 3.5, t_eff)
		var rain_thaw := 0.75 if code in ClimateModel.RAINING else 0.0
		thaw = clampf(maxf(warm_thaw, rain_thaw), 0.0, 1.0)

	return {
		"climate_snow_on": 1.0 if on else 0.0,
		"climate_snow_y": line_y,
		"climate_snow_band": band,
		"climate_snow_depth": clampf(depth, 0.0, 1.0),
		"climate_snow_thaw": thaw,
	}

## Window frost / rime potential (0..1) from temperature, humidity / dew-point
## spread, freezing weather codes, and diurnal solar warming.
static func frost_amount(data: LocationData, weather: Dictionary,
		date: Dictionary = {}, solar_elev: float = 15.0) -> float:
	if data == null:
		return 0.0
	var t_eff := effective_temp_c(data, weather, date)
	var cold_k := smoothstep(1.5, -7.0, t_eff)
	if cold_k <= 0.001:
		return 0.0
	var code := int(weather.get("code", -1))
	var moist_k := 0.0
	if code in FREEZING_CODES:
		moist_k = 1.0
	elif weather.has("rh") or weather.has("dew_point_c"):
		var rh := float(weather.get("rh", 70.0))
		var spread := maxf(t_eff - float(weather.get("dew_point_c", t_eff - 4.0)), 0.0)
		moist_k = maxf(smoothstep(6.0, 0.5, spread), smoothstep(62.0, 92.0, rh) * 0.85)
		if code in ClimateModel.SNOWING:
			moist_k = maxf(moist_k, 0.55)
	else:
		moist_k = ClimateModel.moisture_index(data) * 0.85
		if ClimateModel.arid(data):
			moist_k = minf(moist_k, 0.12)
		if code in ClimateModel.SNOWING or code == 45:
			moist_k = maxf(moist_k, 0.75)
	# Radiative cooling peaks overnight and at dawn; high sun softens frost.
	var diurnal_k := lerpf(0.55, 1.0, smoothstep(24.0, 6.0, solar_elev))
	return clampf(cold_k * moist_k * diurnal_k, 0.0, 1.0)

## Continuous autumn foliage progress (0..1) and elevation advance per render Y.
static func autumn_state(data: LocationData, weather: Dictionary, date: Dictionary = {}) -> Dictionary:
	if data == null:
		return {"climate_autumn": 0.0, "climate_autumn_lapse": 0.0}
	if ClimateModel.arid(data):
		return {"climate_autumn": 0.0, "climate_autumn_lapse": 0.0}
	if ClimateModel.has(data) and float(data.climate["t_cold_c"]) >= 13.0:
		return {"climate_autumn": 0.0, "climate_autumn_lapse": 0.0}
	if not ClimateModel.has(data) and absf(data.latitude) < 23.5:
		return {"climate_autumn": 0.0, "climate_autumn_lapse": 0.0}

	var s := LocationData.clamp_season(data.season)
	if s == LocationData.Season.SPRING or s == LocationData.Season.WINTER:
		return {"climate_autumn": 0.0, "climate_autumn_lapse": 0.0}

	# Boreal/alpine peaks early (~Oct 5, doy 278); warm temperate peaks late (~Nov 16, doy 320).
	var peak_doy := 295.0
	var half_win := 52.0
	if ClimateModel.has(data):
		var tc := float(data.climate["t_cold_c"])
		peak_doy = clampf(lerpf(276.0, 322.0, smoothstep(-6.0, 10.0, tc)), 272.0, 326.0)
	else:
		peak_doy = clampf(lerpf(318.0, 276.0, smoothstep(32.0, 62.0, absf(data.latitude))), 274.0, 322.0)

	var progress := 0.0
	if date.is_empty():
		# Mid-season default: Autumn button shows rich peak colour; Summer stays green.
		progress = 0.68 if s == LocationData.Season.AUTUMN else 0.0
	else:
		var doy := _hemisphere_doy(date, data.latitude)
		var start_doy := peak_doy - half_win
		var end_doy := peak_doy + half_win * 0.85
		if doy <= start_doy:
			progress = 0.0
		elif doy <= peak_doy:
			progress = 0.70 * smoothstep(start_doy, peak_doy, doy)
		elif doy <= end_doy:
			progress = lerpf(0.70, 1.0, smoothstep(peak_doy, end_doy, doy))
		else:
			progress = 1.0 if doy < end_doy + 25.0 else 0.0

	# Live chill nudge (strictly inside the autumn phenological window).
	if progress > 0.05 and bool(weather.get("has_temp", false)) and ClimateModel.has(data):
		var m := int(date.get("month", 10))
		var norm := ClimateModel.month_temp_c(data, m)
		if is_finite(norm):
			progress = clampf(progress + clampf((norm - float(weather["temp"])) * 0.015, -0.06, 0.12), 0.0, 1.0)

	# Elevation advance: higher slopes turn ~3.5 days earlier per 100 m.
	var u2m := 1.0 / maxf(WorldScale.metres_to_units(), 1e-4)
	var lapse := (0.00055 * u2m) if progress > 0.02 else 0.0
	return {"climate_autumn": clampf(progress, 0.0, 1.0), "climate_autumn_lapse": lapse}

static func _hemisphere_doy(date: Dictionary, lat: float) -> float:
	var m := clampi(int(date.get("month", 7)), 1, 12)
	var d := clampi(int(date.get("day", 15)), 1, 31)
	var doy := float(MONTH_DOY[m - 1] + d)
	if lat < 0.0:
		doy = fposmod(doy + 182.5 - 1.0, 365.0) + 1.0
	return doy

## Computes every surface-dressing global uniform for the current view state.
static func solve(data: LocationData, weather: Dictionary = {},
		date: Dictionary = {}, solar_elev: float = 15.0) -> Dictionary:
	var code := int(weather.get("code", -1))
	var sn := snow_state(data, weather, date)
	var aut := autumn_state(data, weather, date)
	var out := {
		"climate_snow_on": sn["climate_snow_on"],
		"climate_snow_y": sn["climate_snow_y"],
		"climate_snow_band": sn["climate_snow_band"],
		"climate_snow_depth": sn["climate_snow_depth"],
		"climate_snow_thaw": sn["climate_snow_thaw"],
		"climate_wetness": 1.0 if code in ClimateModel.RAINING else 0.0,
		"climate_rain": float(WeatherLook.for_code(code, 100.0)["intensity"]) if code in ClimateModel.RAINING else 0.0,
		"climate_water_ice": ClimateModel.ice_amount(data),
		"climate_frost": frost_amount(data, weather, date, solar_elev),
		"climate_autumn": aut["climate_autumn"],
		"climate_autumn_lapse": aut["climate_autumn_lapse"],
		"valley_haze_y": ClimateModel.valley_y(data),
	}
	return out

static func apply_globals(state: Dictionary) -> void:
	for k in state:
		RenderingServer.global_shader_parameter_set(k, state[k])

## Blowing-snow ground spindrift intensity (0..1) when snow lies on the ground
## and wind exceeds 25 km/h. Pure.
static func blowing_snow_strength(snow_depth: float, wind_kmh: float) -> float:
	if wind_kmh <= 25.0 or snow_depth <= 0.25:
		return 0.0
	return clampf((wind_kmh - 25.0) / 35.0, 0.0, 1.0) * smoothstep(0.25, 0.65, snow_depth)
