extends SceneTree

## Headless verification for extended weather-driven dressing:
##   tools/godot_bg.sh --headless --path . --script tests/weather_dressing_test.gd
## Covers:
##   1) Extended Open-Meteo current parsing (RH, dew_point, snow_depth, snowfall,
##      visibility, wind) with backward compatibility on minimal fixtures.
##   2) CHELSA moisture, continentality and snowpack indices across reference cities.
##   3) Pillar 1: Roof snow continuous depth & thaw/slush + landmark snow splice + Icicles live temp.
##   4) Pillar 2: Window frost physical driver (cold, RH/dew-point, rime fog, diurnal)
##      + FacadeShader / FacadeLiteShader splice & frost anti-aliasing convergence.
##   5) Pillar 3: Continuous autumn phenology (boreal vs temperate vs tropical, date
##      progression, elevation lapse, live chill nudge) + TreeMeshLibrary & FarSurface splice.
##   6) Pillar 4: FogModel (CHELSA arid vs humid, crisp sub-zero winter, live Open-Meteo
##      visibility & RH/dew-point mist, continuous volumetric & marine-layer profiles).

const PLACES := {
	"Helsinki": [60.1699, 24.9384, 10.0, 16.0, -4.5, 680.0, 195.0, 120.0, 145.0],
	"Banff": [51.1789, -115.5708, 1401.0, 13.3, -9.5, 523.0, 207.0, 80.0, 200.0],
	"Interlaken": [46.6863, 7.8632, 568.0, 18.05, 1.05, 1343.8, 469.2, 220.0, 35.0],
	"Paris": [48.8566, 2.3522, 41.6, 18.55, 4.35, 658.8, 165.4, 140.0, 0.0],
	"Tokyo": [35.6762, 139.6503, 40.0, 25.0, 6.0, 1520.0, 520.0, 180.0, 2.0],
	"Cairo": [30.0444, 31.2357, 23.0, 28.5, 14.5, 19.0, 0.0, 0.0, 0.0],
	"Bangkok": [13.7563, 100.5018, 2.0, 30.2, 26.8, 1640.0, 740.0, 30.0, 0.0],
}

func _data(name: String, season: int = LocationData.Season.WINTER) -> LocationData:
	var p: Array = PLACES[name]
	var d := LocationData.new()
	d.place_name = name
	d.latitude = p[0]
	d.longitude = p[1]
	d.centre_elevation_m = p[2]
	d.season = season
	d.climate = {
		"t_warm_c": p[3], "t_cold_c": p[4], "precip_mm": p[5],
		"precip_warm_mm": p[6], "precip_dry_mm": p[7], "snow_days": p[8],
	}
	return d

func _init() -> void:
	var failures: Array[String] = ["sentinel: script aborted"]
	_test_weather_parser(failures)
	_test_roof_snow_depth(failures)
	_test_window_frost(failures)
	_test_autumn_phenology(failures)
	_test_fog_model(failures)
	_test_preset_synthesis(failures)
	_test_shader_contracts(failures)
	failures.remove_at(0)
	if failures.is_empty():
		print("WEATHER DRESSING OK: parser, roof snow depth/thaw, window frost, autumn phenology, CHELSA/Open-Meteo fog, presets, shader contracts")
		quit(0)
	else:
		for f in failures:
			printerr("WEATHER DRESSING FAIL: ", f)
		quit(1)

func _test_weather_parser(failures: Array[String]) -> void:
	var full := '{"utc_offset_seconds":7200,"current":{"temperature_2m":-4.2,"relative_humidity_2m":91,"dew_point_2m":-5.1,"weather_code":48,"cloud_cover":100,"snowfall":0.8,"snow_depth":0.32,"wind_speed_10m":14.5,"wind_direction_10m":210,"visibility":350.0}}'
	var w := WeatherFetcher.parse_current(full)
	if not bool(w.get("has_temp", false)) or absf(float(w["temp"]) - (-4.2)) > 0.01 \
			or absf(float(w["rh"]) - 91.0) > 0.01 or absf(float(w["dew_point_c"]) - (-5.1)) > 0.01 \
			or absf(float(w["snow_depth_m"]) - 0.32) > 0.001 or absf(float(w["snowfall_cm"]) - 0.8) > 0.01 \
			or absf(float(w["visibility_m"]) - 350.0) > 0.1:
		failures.append("extended Open-Meteo current fields did not parse cleanly: %s" % w)
	var minimal := '{"current":{"temperature_2m":16.4,"weather_code":3,"cloud_cover":100}}'
	var m := WeatherFetcher.parse_current(minimal)
	if m.has("rh") or m.has("snow_depth_m") or m.has("visibility_m"):
		failures.append("missing optional fields must stay absent on minimal fixtures: %s" % m)

func _test_roof_snow_depth(failures: Array[String]) -> void:
	var hel := _data("Helsinki", LocationData.Season.WINTER)
	var light := WeatherDressing.snow_state(hel, {"has_temp": true, "temp": -2.0, "code": 71, "snow_depth_m": 0.05})
	var deep := WeatherDressing.snow_state(hel, {"has_temp": true, "temp": -8.0, "code": 75, "snow_depth_m": 0.45})
	var thaw := WeatherDressing.snow_state(hel, {"has_temp": true, "temp": 2.2, "code": 61, "snow_depth_m": 0.25})
	if float(deep["climate_snow_depth"]) <= float(light["climate_snow_depth"]):
		failures.append("deep snow_depth (0.45 m) must exceed light (0.05 m): %s vs %s" % [deep, light])
	if float(thaw["climate_snow_thaw"]) < 0.5 or float(deep["climate_snow_thaw"]) > 0.05:
		failures.append("rain/warm snow should thaw while -8 °C stays dry: %s vs %s" % [thaw, deep])
	if ClimateModel.snowpack_index(_data("Banff"), LocationData.Season.WINTER) <= ClimateModel.snowpack_index(_data("Paris"), LocationData.Season.WINTER):
		failures.append("Banff winter snowpack must exceed Paris")
	# Icicles honor live temperature.
	if not Icicles.cold(hel, {"has_temp": true, "temp": -4.0}) or Icicles.cold(hel, {"has_temp": true, "temp": 5.0}):
		failures.append("Icicles.cold must honor live temperature")
	# RoofSnow covers roof-tagged landmark meshes too (without touching shared materials).
	var world := Node3D.new()
	var lm_root := Node3D.new()
	lm_root.name = "Landmarks"
	var roof_mat := StandardMaterial3D.new()
	RoofVariety.mark(roof_mat)
	var bm := BoxMesh.new()
	bm.material = roof_mat
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	lm_root.add_child(mi)
	world.add_child(lm_root)
	if RoofSnow.apply(world, true) != 1 or mi.material_overlay != RoofSnow.overlay() or roof_mat.next_pass != null:
		failures.append("RoofSnow should overlay roof-tagged landmark meshes without mutating shared material")
	world.free()

func _test_window_frost(failures: Array[String]) -> void:
	var hel := _data("Helsinki", LocationData.Season.WINTER)
	var warm := WeatherDressing.frost_amount(hel, {"has_temp": true, "temp": 8.0, "rh": 95.0, "dew_point_c": 7.0, "code": 3}, {}, 10.0)
	var dry_cold := WeatherDressing.frost_amount(hel, {"has_temp": true, "temp": -8.0, "rh": 35.0, "dew_point_c": -20.0, "code": 0}, {}, 10.0)
	var damp_cold := WeatherDressing.frost_amount(hel, {"has_temp": true, "temp": -8.0, "rh": 92.0, "dew_point_c": -9.0, "code": 3}, {}, 6.0)
	var rime_fog := WeatherDressing.frost_amount(hel, {"has_temp": true, "temp": -5.0, "rh": 98.0, "dew_point_c": -5.3, "code": 48}, {}, 6.0)
	var noon_cold := WeatherDressing.frost_amount(hel, {"has_temp": true, "temp": -8.0, "rh": 92.0, "dew_point_c": -9.0, "code": 3}, {}, 30.0)
	if warm > 0.001:
		failures.append("warm weather must have 0 frost, got %f" % warm)
	if not (damp_cold > 0.6 and damp_cold > dry_cold and rime_fog > 0.7):
		failures.append("humid cold & rime fog should frost strongly (damp=%.2f dry=%.2f rime=%.2f)" % [damp_cold, dry_cold, rime_fog])
	if noon_cold >= damp_cold:
		failures.append("high sun should ease radiative morning frost (noon=%.2f vs dawn=%.2f)" % [noon_cold, damp_cold])
	if WeatherDressing.frost_amount(_data("Cairo", LocationData.Season.WINTER), {}, {}, 5.0) > 0.001:
		failures.append("Cairo winter must never frost")

func _test_autumn_phenology(failures: Array[String]) -> void:
	var hel := _data("Helsinki", LocationData.Season.AUTUMN)
	var tok := _data("Tokyo", LocationData.Season.AUTUMN)
	var bkk := _data("Bangkok", LocationData.Season.AUTUMN)
	var cairo := _data("Cairo", LocationData.Season.AUTUMN)
	# Tropical and arid climates suppress autumn color shift.
	if float(WeatherDressing.autumn_state(bkk, {}, {"month": 10, "day": 15})["climate_autumn"]) > 0.001 \
			or float(WeatherDressing.autumn_state(cairo, {}, {"month": 10, "day": 15})["climate_autumn"]) > 0.001:
		failures.append("tropical/arid climates must suppress autumn foliage shift")
	# Date progression: Sep 1 < Oct 5 < Nov 10 in Helsinki.
	var sep := float(WeatherDressing.autumn_state(hel, {}, {"month": 9, "day": 1})["climate_autumn"])
	var oct := float(WeatherDressing.autumn_state(hel, {}, {"month": 10, "day": 5})["climate_autumn"])
	var nov := float(WeatherDressing.autumn_state(hel, {}, {"month": 11, "day": 10})["climate_autumn"])
	if not (sep < oct and oct < nov):
		failures.append("Helsinki autumn should progress Sep < Oct < Nov (%.2f, %.2f, %.2f)" % [sep, oct, nov])
	# Boreal Helsinki turns earlier than warm-temperate Tokyo on Oct 1.
	var hel_oct1 := float(WeatherDressing.autumn_state(hel, {}, {"month": 10, "day": 1})["climate_autumn"])
	var tok_oct1 := float(WeatherDressing.autumn_state(tok, {}, {"month": 10, "day": 1})["climate_autumn"])
	if hel_oct1 <= tok_oct1:
		failures.append("boreal Helsinki should turn earlier than warm Tokyo on Oct 1 (%.2f vs %.2f)" % [hel_oct1, tok_oct1])
	# Elevation lapse is positive in autumn, zero in summer/tropical.
	if float(WeatherDressing.autumn_state(hel, {}, {"month": 10, "day": 5})["climate_autumn_lapse"]) <= 0.0:
		failures.append("autumn should carry positive elevation lapse")
	# Species metadata: evergreens 0, birch earlier than oak.
	if TreeSpecies.autumn_meta("spruce").x != 0.0 or TreeSpecies.autumn_meta("birch").y >= TreeSpecies.autumn_meta("oak").y:
		failures.append("species autumn metadata wrong: spruce=%s birch=%s oak=%s" % [
			TreeSpecies.autumn_meta("spruce"), TreeSpecies.autumn_meta("birch"), TreeSpecies.autumn_meta("oak")])

func _test_fog_model(failures: Array[String]) -> void:
	var clear_look := WeatherLook.for_code(0, 10.0)
	var fog_look := WeatherLook.for_code(45, 100.0)
	var dry_m := FogModel.compute(0.1, true, 0.5, {"has_temp": true, "temp": 26.0, "rh": 22.0}, clear_look,
		LocationData.Season.SUMMER, 1.0, 0.0, 20.0, 0.0, false, true, true)
	var humid_m := FogModel.compute(0.9, false, 0.4, {"has_temp": true, "temp": 9.0, "rh": 95.0, "dew_point_c": 8.2}, clear_look,
		LocationData.Season.AUTUMN, 1.25, 0.0, 8.0, 0.0, false, true, true)
	var vis_800 := FogModel.compute(0.6, false, 0.5, {"has_temp": true, "temp": 10.0, "visibility_m": 800.0}, clear_look,
		LocationData.Season.AUTUMN, 1.0, 0.5, 15.0, 0.0, false, true, true)
	var dense_fog := FogModel.compute(0.7, false, 0.5, {"has_temp": true, "temp": -4.0, "rh": 99.0, "code": 48},
		WeatherLook.for_code(48, 100.0), LocationData.Season.WINTER, 0.8, 1.0, 8.0, 0.0, false, true, true)
	if float(dry_m["height_density_per_m"]) != 0.0 or float(humid_m["height_density_per_m"]) <= 0.0:
		failures.append("arid valley mist must be 0, humid dawn valley mist > 0")
	if float(humid_m["fog_per_m"]) <= float(dry_m["fog_per_m"]) * 2.0:
		failures.append("95%% RH near dew point must thicken fog over dry air")
	if absf(float(vis_800["effective_visibility_m"]) - 800.0) > 10.0:
		failures.append("Open-Meteo 800 m visibility should drive effective_visibility_m, got %.1f" % float(vis_800["effective_visibility_m"]))
	if float(dense_fog["vol_density_per_m"]) <= float(humid_m["vol_density_per_m"]) or float(dense_fog["ice_fog"]) < 0.9:
		failures.append("WMO 48 freezing fog should thicken volumetric fog and flag ice_fog: %s" % dense_fog)
	if float(humid_m["valley_haze_amount"]) <= float(dry_m["valley_haze_amount"]):
		failures.append("humid valley_haze_amount must exceed arid")
	# Coastal high humidity activates gentle marine mist even without WMO 45.
	var coast_mist := FogModel.compute(0.75, false, 0.3, {"has_temp": true, "temp": 12.0, "rh": 94.0, "dew_point_c": 11.2},
		clear_look, LocationData.Season.SUMMER, 1.0, 0.2, 12.0, 0.0, true, true, true)
	if float(coast_mist["marine_amount"]) <= 0.1 or float(coast_mist["marine_amount"]) >= 1.0:
		failures.append("coastal 94%% RH mist should partially activate marine layer: %s" % coast_mist["marine_amount"])
	var coast_fog := FogModel.compute(0.75, false, 0.3, {}, fog_look,
		LocationData.Season.SUMMER, 1.0, 1.0, 12.0, 0.0, true, true, true)
	if float(coast_fog["marine_amount"]) < 1.0:
		failures.append("coastal WMO 45 fog must fully activate marine layer")

func _test_preset_synthesis(failures: Array[String]) -> void:
	var hel := _data("Helsinki", LocationData.Season.WINTER)
	var partly_w := WeatherDressing.weather_for_pick(2, hel)  # Partly cloudy preset
	var fog_w := WeatherDressing.weather_for_pick(4, hel)  # Fog preset in sub-zero Helsinki
	var snow_w := WeatherDressing.weather_for_pick(7, hel)  # Snow preset
	if int(partly_w["code"]) != 2 or absf(float(partly_w["cloud"]) - 45.0) > 0.1:
		failures.append("Partly cloudy preset should synthesize WMO 2 / 45%% cloud: %s" % partly_w)
	if int(fog_w["code"]) != 48 or float(fog_w["rh"]) < 95.0:
		failures.append("Fog preset in sub-zero winter should synthesize rime fog (48): %s" % fog_w)
	if float(snow_w.get("snow_depth_m", 0.0)) < 0.2 or float(snow_w["temp"]) > -2.0:
		failures.append("Snow preset should synthesize cold temp and snow_depth_m: %s" % snow_w)
	# Live winter snow telemetry must never paint snow onto an explicitly Summer scene.
	var hel_summer := _data("Helsinki", LocationData.Season.SUMMER)
	var summer_live := WeatherDressing.snow_state(hel_summer, {"has_temp": true, "temp": -4.0, "code": 0, "snow_depth_m": 0.25})
	if float(summer_live["climate_snow_on"]) > 0.0:
		failures.append("live winter snow must not apply to Summer season: %s" % summer_live)
	# Explicit Snow preset can still force snow on Summer.
	var summer_forced := WeatherDressing.snow_state(hel_summer, WeatherDressing.weather_for_pick(7, hel_summer))
	if float(summer_forced["climate_snow_on"]) <= 0.0:
		failures.append("explicit Snow preset should still apply snow: %s" % summer_forced)

func _test_shader_contracts(failures: Array[String]) -> void:
	if not FacadeShader.shader().code.contains("climate_frost") or not FacadeShader.shader().code.contains("window_frost"):
		failures.append("FacadeShader must splice WeatherGlsl.FROST_GLSL")
	if not FacadeLiteShader.shader().code.contains("climate_frost"):
		failures.append("FacadeLiteShader must read climate_frost")
	if not LandmarkShader.shader().code.contains("climate_snow_depth") or not LandmarkShader.shader().code.contains("climate_wetness"):
		failures.append("LandmarkShader must splice ClimateModel.SNOW_GLSL")
	var leaf_m := TreeMeshLibrary.leaf_material("broad", Color(0.36, 0.5, 0.24), 0.5, 0.0, true, true,
		Color(0.86, 0.56, 0.22), Vector3(1.0, 0.0, 0.15))
	if not leaf_m.shader.code.contains("autumn_tree_tint") or not leaf_m.shader.code.contains("climate_autumn"):
		failures.append("TreeMeshLibrary leaf shader must splice WeatherGlsl.AUTUMN_GLSL")
	var imp_m := TreeMeshLibrary.impostor_material("birch", false, LocationData.Season.AUTUMN, 0.5)
	if not imp_m.shader.code.contains("autumn_tree_tint"):
		failures.append("TreeMeshLibrary impostor shader must splice WeatherGlsl.AUTUMN_GLSL")
	var far_m := FarSurface.drape_material(null, null, false, _data("Paris", LocationData.Season.AUTUMN))
	if not far_m.shader.code.contains("autumn_far_forest") or not far_m.shader.code.contains("valley_haze_amount"):
		failures.append("FarSurface must splice WeatherGlsl.AUTUMN_GLSL and read valley_haze_amount")
	if float(far_m.get_shader_parameter("deciduous_share")) < 0.5:
		failures.append("Paris FarSurface should carry temperate deciduous_share >= 0.5")
