class_name ViewConditions
extends RefCounted

## Season, weather, precipitation and time-of-day for View360:
## drives the AtmosphereRig and the time UI. World rebuilds stay
## in View360 (called back via `v`).
static func _on_season_selected(v: View360, index: int) -> void:
	if v._data == null:
		return
	v._data.season = LocationData.clamp_season(index)
	if v._season_btn != null:
		v._season_btn.select(v._data.season)
	v._atmos.set_season(v._data.season)
	# Climate snow / ice follow the season at once (shader globals); the
	# rebuild below re-applies them to the new world's roads.
	apply_surface_state(v)
	# Colours bake per season, so the world rebuilds (threaded, the old
	# world stays up meanwhile); the ground surface is season-free and
	# reused.
	if v._season_building:
		v._season_dirty = true
		return
	v._season_building = true
	while true:
		v._season_dirty = false
		var data := v._data
		var built := await v.build_location(data, v._ground)
		if data != v._data or v._season_dirty:
			(built[1] as Node3D).free()
			if data != v._data:
				break  # another place opened meanwhile
			continue
		v._rebuild_world(built[1])
		break
	v._season_building = false

## Rain/snow dressing from the live weather code: one particle system
## around the camera, off unless the place is actually precipitating.
static func _build_precip(v: View360) -> void:
	v._precip = GPUParticles3D.new()
	v._precip.amount = 900
	v._precip.lifetime = 1.6
	v._precip.emitting = false
	v._precip.visible = false
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(28, 16, 28)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 6.0
	mat.gravity = Vector3(0, -22, 0)
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 7.0
	v._precip.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.5)
	var qm := StandardMaterial3D.new()
	qm.albedo_color = Color(0.75, 0.85, 0.95, 0.55)
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = qm
	v._precip.draw_pass_1 = quad
	v._rig.add_child(v._precip)
	v._precip.position = Vector3(0, 10, 0)

## Density, size and fall speed follow the intensity (WeatherLook):
## drizzle is a sparse fine mist, a downpour dense long streaks.
static func _apply_precip(v: View360, code: int) -> void:
	if v._precip == null:
		return
	var look := WeatherLook.for_code(code, v._atmos.cloud_cover if v._atmos != null else 100.0)
	var kind := str(look["precip"])
	v._precip.visible = kind != "none"
	v._precip.emitting = kind != "none"
	if kind == "none":
		return
	var pp := WeatherLook.particle_params(look)
	v._precip.amount_ratio = float(pp["amount_ratio"])
	(v._precip.process_material as ParticleProcessMaterial).gravity = Vector3(0, float(pp["gravity"]), 0)
	(v._precip.draw_pass_1 as QuadMesh).size = pp["size"]
	v._precip.set_meta("precip_base", Color(0.95, 0.96, 1.0, float(pp["alpha"])) if kind == "snow"
		else Color(0.75, 0.85, 0.95, float(pp["alpha"])))
	_precip_tint(v)

## Unshaded particles take the scene's light level, so night rain is a
## faint shimmer, not glowing streaks.
static func _precip_tint(v: View360) -> void:
	if v._precip == null or v._atmos == null or not v._precip.has_meta("precip_base"):
		return
	var base: Color = v._precip.get_meta("precip_base")
	var light := lerpf(0.12, 1.0, clampf(v._atmos.sun.light_energy / 1.5, 0.0, 1.0))
	var qm := (v._precip.draw_pass_1 as QuadMesh).material as StandardMaterial3D
	qm.albedo_color = Color(base.r * light, base.g * light, base.b * light, base.a)

## `prebuilt` is a build_location result; empty builds synchronously.
static func _on_weather(v: View360, temp_c: float, label: String, cloud_cover: float, code: int) -> void:
	if v._weather_label != null:
		v._weather_label.text = "%.0f°C · %s" % [temp_c, label]
		v._weather_label.visible = true
	v._atmos.set_weather(code, cloud_cover)
	_apply_precip(v, code)
	apply_surface_state(v)
	if v._weather != null and v._weather.has_utc_offset:
		_apply_utc_offset(v, float(v._weather.utc_offset_s) / 3600.0)

## The real local clock arrived: keep the spawn at the place's golden
## hour and live time on the real clock; a picked hour keeps its label
## and the sun moves to that hour's true position.
static func _apply_utc_offset(v: View360, hours: float) -> void:
	if v._atmos == null or (v._atmos.utc_offset_known and is_equal_approx(v._atmos.utc_offset_h, hours)):
		return
	var at_spawn := not v._live_time and v._spawn_golden
	v._atmos.set_utc_offset(hours)
	if v._live_time:
		_apply_current_time(v)
	elif at_spawn:
		spawn_golden_hour(v)
	else:
		_apply_time(v, v._time_hour)

## Climate snow / rain / ice for the shown place and its live weather:
## shader globals (ClimateModel) plus wet road materials, which are
## standard materials and so take the wetness here.
static func apply_surface_state(v: View360) -> void:
	if v._data == null:
		return
	var code := v._atmos.weather_code if v._atmos != null else -1
	ClimateModel.apply_globals(v._data, code)
	if v._atmos != null:
		# Snow underfoot brightens the bounce light; bolts land on terrain.
		v._atmos.set_snow_ground(ClimateModel.has(v._data)
			and ClimateModel.snowy_at_viewpoint(v._data, v._data.season))
		if v._ground != null:
			v._atmos.lightning.ground_height = v._ground.height_at_world
	if v._generated != null and is_instance_valid(v._generated):
		_wet_roads(v._generated, 1.0 if code in ClimateModel.RAINING else 0.0)
		RoofSnow.apply(v._generated, float(ClimateModel.globals_for(v._data, code)["climate_snow_on"]) > 0.0)
		_city_lights(v)

## Wet asphalt: lower roughness (a multiplier over the PBR map) and a
## darker albedo. Dry values are kept on the shared material, so the
## change is reversible and applies once per material.
static func _wet_roads(world: Node, wet: float) -> void:
	var seen := {}
	for c in world.get_children():
		if not (c is MeshInstance3D) or str(c.get_meta("lod_layer", "")) != "Roads":
			continue
		var mi := c as MeshInstance3D
		var mats: Array = [mi.material_override]
		for s in (mi.mesh.get_surface_count() if mi.mesh != null else 0):
			mats.append(mi.mesh.surface_get_material(s))
		for m in mats:
			if not (m is StandardMaterial3D) or seen.has(m):
				continue
			seen[m] = true
			var sm := m as StandardMaterial3D
			if not sm.has_meta("dry_rough"):
				sm.set_meta("dry_rough", sm.roughness)
				sm.set_meta("dry_albedo", sm.albedo_color)
			sm.roughness = lerpf(float(sm.get_meta("dry_rough")), 0.18, wet)
			var a: Color = sm.get_meta("dry_albedo")
			sm.albedo_color = a.darkened(0.25 * wet)

static func spawn_golden_hour(v: View360) -> void:
	# An hour slot uses the season's date, so the golden hour must be
	# found on that date too, not on a live-time date still held.
	v._atmos.date = {}
	set_time_of_day(v, wrapi(roundi(v._atmos.golden_hour()), 0, 24))
	v._spawn_golden = true

# --- Time of day: 24 hourly slots, or live current time ---

static func set_time_of_day(v: View360, hour: int) -> void:
	v._live_time = false
	v._spawn_golden = false
	v._time_hour = float(clampi(hour, 0, 23))
	_apply_time(v, v._time_hour)
	_sync_time_ui(v)

static func use_live_time(v: View360) -> void:
	v._live_time = true
	_apply_current_time(v)

## Live time is the place's own clock and date (UTC + its offset), not
## the device's.
static func _apply_current_time(v: View360) -> void:
	var offset_h := v._atmos.utc_offset_h if v._atmos != null else 0.0
	var now := Time.get_datetime_dict_from_unix_time(
		int(Time.get_unix_time_from_system() + offset_h * 3600.0))
	v._time_hour = float(now.get("hour", 12)) + float(now.get("minute", 0)) / 60.0
	if v._atmos != null:
		var lat := v._data.latitude if v._data != null else v._atmos.latitude
		v._atmos.set_time(v._time_hour, lat, {"year": int(now.get("year", 2026)),
			"month": int(now.get("month", 1)), "day": int(now.get("day", 1))})
		AccentSun.follow_atmos(v._atmos, v._time_hour)
	_city_lights(v)
	_precip_tint(v)
	_sync_time_ui(v)

static func _on_time_slider_changed(v: View360, value: float) -> void:
	if v._setting_time:
		return
	set_time_of_day(v, int(value))

static func _sync_time_ui(v: View360) -> void:
	if v._sun_slider == null:
		return
	v._setting_time = true
	v._sun_slider.value = floor(v._time_hour)
	v._setting_time = false
	if v._live_time:
		v._time_label.text = "%02d:%02d" % [int(v._time_hour), int(fmod(v._time_hour, 1.0) * 60.0 + 0.001)]
		v._now_btn.text = "●  Live"
	else:
		v._time_label.text = "%02d:00" % int(v._time_hour)
		v._now_btn.text = "↺  Now"
	HudStyle.apply_live_chip(v._now_btn, v._live_time)

static func _apply_time(v: View360, hour_f: float) -> void:
	if v._atmos == null:
		return
	var lat := v._data.latitude if v._data != null else v._atmos.latitude
	v._atmos.set_time(hour_f, lat)
	AccentSun.follow_atmos(v._atmos, hour_f)
	_city_lights(v)
	_precip_tint(v)

## Lit windows follow the sky's darkness (CityLights).
static func _city_lights(v: View360) -> void:
	if v._atmos != null and v._generated != null and is_instance_valid(v._generated):
		CityLights.apply(v._generated, CityLights.amount_for(v._atmos.night_amount, v._atmos.twilight_amount))

