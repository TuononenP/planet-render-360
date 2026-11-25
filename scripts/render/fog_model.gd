class_name FogModel
extends RefCounted

## Atmospheric fog, mist, volumetric density and coastal marine-layer model
## driven jointly by CHELSA climatology and live Open-Meteo telemetry.
## Pure static math (headless-testable without a scene tree).

const MIN_VIS_M := 150.0
const MAX_VIS_M := 50000.0
const VOL_CLEAR_PER_M := 0.00022
const VOL_MIST_PER_M := 0.00085
const VOL_FOG_PER_M := 0.0032

## Computes continuous atmospheric extinction and layer parameters:
##   fog_per_m, height_density_per_m, vol_density_per_m,
##   marine_amount, marine_vis_m, marine_top_m, marine_soft_m,
##   valley_haze_amount, valley_haze_scale, effective_visibility_m,
##   ice_fog, dust_haze
static func compute(moisture: float, arid: bool, continentality: float,
		weather: Dictionary, look: Dictionary, season: int, season_haze: float,
		overcast: float, solar_elev: float, night_amount: float,
		coastal: bool, marine_supported: bool, has_valley_floor: bool) -> Dictionary:
	var code := int(look.get("code", -1))
	var precip := str(look.get("precip", "none"))
	var wmo_vis := float(look.get("visibility_m", 0.0))
	var has_temp := bool(weather.get("has_temp", false))
	var temp_c := float(weather.get("temp", 12.0))
	var has_rh := weather.has("rh")
	var rh := float(weather.get("rh", 60.0))
	var has_dew := weather.has("dew_point_c")
	var spread := maxf(temp_c - float(weather.get("dew_point_c", temp_c - 6.0)), 0.0) if (has_temp and has_dew) else 6.0

	# 1. CHELSA climatological clear-air baseline.
	var clim_haze := lerpf(0.88, 1.32, clampf(moisture, 0.0, 1.0))
	var dust_haze := 0.0
	if arid:
		clim_haze = 1.25
		dust_haze = clampf(1.0 - smoothstep(45.0, 80.0, rh) if has_rh else 0.75, 0.0, 1.0)
	elif has_temp and temp_c <= -4.0 and overcast < 0.5 and (not has_rh or rh < 78.0):
		# Crisp sub-zero continental/boreal winter air.
		clim_haze *= lerpf(0.85, 0.65, clampf(continentality, 0.0, 1.0))
	var base_haze := AtmosphereRig.HAZE_PER_M * lerpf(1.0, 1.6, overcast) * season_haze * clim_haze

	# 2. Live Open-Meteo visibility + hygroscopic humidity / dew-point mist.
	var ext := WeatherLook.fog_per_m(look, base_haze)
	var live_vis := float(weather.get("visibility_m", 0.0))
	if live_vis > 0.0:
		var clamped_vis := clampf(live_vis, MIN_VIS_M, MAX_VIS_M)
		var vis_ext := 3.0 / clamped_vis
		if wmo_vis > 0.0:
			# Active precip/fog: refine WMO extinction within [0.4x, 2.5x].
			var wmo_ext := 3.0 / wmo_vis
			ext = maxf(base_haze, clampf(vis_ext, wmo_ext * 0.4, wmo_ext * 2.5))
		else:
			ext = maxf(base_haze, vis_ext)
	elif has_rh or has_dew:
		var rh_factor := 1.0 + 4.5 * pow(smoothstep(70.0, 99.0, rh), 1.6)
		var dew_ext := (3.0 / lerpf(1200.0, 6000.0, smoothstep(0.5, 3.0, spread))) * smoothstep(3.5, 0.5, spread)
		ext = maxf(ext, maxf(base_haze * rh_factor, dew_ext))

	# 3. Freezing / ice fog detection (WMO 48 or sub-zero near saturation).
	var ice_fog := 0.0
	if code == 48:
		ice_fog = 1.0
	elif has_temp and temp_c <= -5.0 and ((has_rh and rh >= 90.0) or (has_dew and spread <= 1.5)):
		ice_fog = smoothstep(-5.0, -12.0, temp_c) * smoothstep(88.0, 97.0, rh)
		ext = maxf(ext, 3.0 / lerpf(2500.0, 500.0, ice_fog))

	var eff_vis := 3.0 / maxf(ext, 1e-6)
	var foggy := eff_vis < WeatherLook.FOGGY_BELOW_M or WeatherLook.is_foggy(look)

	# 4. Continuous coastal marine layer (sea fog + humid harbour mist).
	var marine_amount := 0.0
	var marine_vis_m := MarineLayer.VISIBILITY_M
	var marine_top_m := MarineLayer.TOP_M
	var marine_soft_m := MarineLayer.SOFT_M
	if coastal and marine_supported:
		if WeatherLook.is_foggy(look):
			marine_amount = 1.0
			marine_vis_m = clampf(eff_vis * 2.2, 450.0, MarineLayer.VISIBILITY_M)
			marine_top_m = MarineLayer.TOP_M
		elif (has_rh and rh >= 85.0) or (has_dew and spread <= 2.5):
			var humid_k := maxf(smoothstep(85.0, 98.0, rh) if has_rh else 0.0,
				smoothstep(2.5, 0.4, spread) if has_dew else 0.0)
			if humid_k > 0.05 and not arid:
				marine_amount = humid_k * 0.65
				marine_vis_m = lerpf(4200.0, 1600.0, humid_k)
				marine_top_m = lerpf(95.0, MarineLayer.TOP_M, humid_k)
				marine_soft_m = lerpf(45.0, MarineLayer.SOFT_M, humid_k)

	# When the marine layer carries the fog, the air above it stays hazy.
	var fog_per_m := lerpf(ext, base_haze * 2.0, marine_amount) if marine_amount > 0.5 else ext

	# 5. Inland height-based valley mist & FarSurface valley air.
	var low_sun := 1.0 - clampf((solar_elev / AtmosphereRig.DAY_DEG - 0.15) * 2.0, 0.0, 0.75)
	if solar_elev <= -3.0:
		low_sun = 1.0 - smoothstep(0.08, 0.5, -solar_elev / AtmosphereRig.NIGHT_DEG)
	var humid_mist := 0.0
	if has_rh or has_dew:
		humid_mist = maxf(smoothstep(74.0, 96.0, rh) if has_rh else 0.0,
			smoothstep(4.5, 0.5, spread) if has_dew else 0.0)
	var height_density := 0.0
	if has_valley_floor and not arid and not coastal and marine_amount <= 0.02 and not WeatherLook.is_foggy(look):
		var damp := 0.35 if precip != "none" else 0.0
		var season_mist := 0.35 if season == LocationData.Season.AUTUMN else (0.2 if season == LocationData.Season.SPRING else 0.0)
		var m_gain := lerpf(0.55, 1.25, clampf(moisture, 0.0, 1.0))
		# Ease height fog as uniform extinction rises so the detailed-extent
		# terrain and FarSurface (custom FOG) never diverge at the 2.4 km seam.
		var seam_guard := lerpf(1.0, 0.18, smoothstep(0.0003, 0.0015, ext))
		height_density = minf((0.000025 + 0.000085 * low_sun + 0.000075 * maxf(maxf(damp, season_mist), humid_mist)) \
			* m_gain * seam_guard * (1.0 - 0.65 * night_amount), 0.00014)

	# FarSurface valley air fill & exponential scale height.
	var valley_haze_amount := 0.10 if arid else clampf(
		lerpf(0.24, 0.52, clampf(moisture, 0.0, 1.0)) + 0.18 * humid_mist, 0.10, 0.68)
	var valley_haze_scale := 3200.0 if arid else clampf(
		lerpf(2900.0, 1350.0, maxf(humid_mist, smoothstep(5000.0, 600.0, eff_vis))), 1200.0, 3200.0)

	# 6. Continuous volumetric fog density (respects clear golden-hour ceiling).
	var t_mist := smoothstep(AtmosphereRig.HAZE_PER_M * 1.5, 3.0 / 3000.0, ext)
	var t_fog := smoothstep(3.0 / 3000.0, 3.0 / 400.0, ext)
	var vol_density := lerpf(VOL_CLEAR_PER_M, VOL_MIST_PER_M, t_mist)
	vol_density = lerpf(vol_density, VOL_FOG_PER_M, t_fog)
	if marine_amount > 0.5:
		vol_density = lerpf(vol_density, VOL_MIST_PER_M, 0.5)

	return {
		"fog_per_m": fog_per_m,
		"height_density_per_m": height_density,
		"vol_density_per_m": vol_density,
		"marine_amount": marine_amount,
		"marine_vis_m": marine_vis_m,
		"marine_top_m": marine_top_m,
		"marine_soft_m": marine_soft_m,
		"valley_haze_amount": valley_haze_amount,
		"valley_haze_scale": valley_haze_scale,
		"effective_visibility_m": eff_vis,
		"foggy": foggy,
		"ice_fog": ice_fog,
		"dust_haze": dust_haze,
	}
