class_name AtmosphereRig
extends Node3D

## Sun, sky, aerial haze and clouds for the 360 view (T6.1 / T6.4).
## View360 owns the UI and drives this rig only through its state API
## (set_time / set_weather / set_season / set_quality); every light,
## sky, fog and cloud value lives here. Golden-hour Paris (PRD §3.3)
## is the 17:00 keyframe of that state, not a fixed grade.
##
## The sky is one cheap sky shader: a Rayleigh-ish zenith -> horizon
## gradient, a warm sun-side band and halo at low sun, a sun disc, and
## an FBM cloud deck projected on a dome whose coverage follows the
## live cloud-cover %. No cloud geometry exists, so nothing can facet
## (PRD AC-11). Octave count is tier-gated by RenderSettings.
## Twilight adds Earth's shadow and the Belt of Venus opposite the sun;
## night adds stars, the Milky Way and the real moon (position and
## phase; moonlight follows the lit fraction). Each season
## (SkyPalette.SEASON_SKY) shifts sky hues, haze and cloud shape.
##
## Weather (WeatherLook) sets more than the deck: visibility (fog, rain
## and snow at their real murk), how far the direct sun dims, how soft
## the shadows go as the diffuse sky takes over, ambient and exposure,
## and dark blue-green storm bases. Thunderstorms add LightningRig.
##
## The sun is the real one (T6.2): SolarPosition from latitude,
## longitude, date and UTC time. The hour is the place's local clock
## time (UTC offset from the weather service, else longitude / 15);
## without an explicit date the selected season's mid-month day is used
## (hemisphere-aware). Sky, haze and light key off the solar elevation:
## it maps onto the reference day arc (DAY_DEG / NIGHT_DEG) and that
## arc's equivalent hour picks the colour keyframes, so the Paris
## golden-hour grade (the 17:00 keyframes, sun 12.4° up in the
## afternoon) is one state any place reaches at its own golden hour.
##
## Aerial perspective: fog takes the sky's own horizon colour (cooler
## and bluer than the sun-side glow) plus Godot's aerial-perspective
## sampling of the sky radiance, so distant ridges fade to blue-grey
## while the sun side keeps a warm haze — never a cream wall.

## Fallback cover until live weather lands: fair-weather cumulus.
const DEFAULT_COVER := 30.0
## Clear-air haze extinction per metre: ~36% at 10 km, ~74% at 30 km,
## so ridges 5-30 km away stay legible as hazed silhouettes.
const HAZE_PER_M := 4.5e-5
## Seconds between cloud-drift uniform steps. Drift is slow enough
## that 4 Hz steps are invisible, and the sky radiance map is only
## re-filtered when a uniform changes (TIME would dirty it per frame).
const DRIFT_STEP_S := 0.25
## Solar elevation (deg) that maps to the full day arc (+1) and to the
## deepest night (-1). Full night sky (night_amount 1) sits at -9°.
const DAY_DEG := 48.0
const NIGHT_DEG := 20.0
## Afternoon solar elevation of the PRD golden-hour reference grade.
const GOLDEN_ELEV := 12.42
## Lowest pitch the sun light takes, so a sun on the horizon still
## lights the scene instead of grazing it black.
const MIN_LIGHT_PITCH := 6.0
## Top-of-atmosphere sun energy: with the extinction below it lights the
## golden-hour reference (12.4°) at the T6.1 grade's 1.5 and noon ~2.6.
const SUN_E0 := 3.0
## Effective wavelengths (µm) for the R/G/B light channels and the
## Rayleigh / aerosol optical depths at 0.55 µm, fitted so the 12.4° sun
## is the PRD #FFD9A3 (docs: AC-07); aerosol scales with season haze.
const SUN_LAMBDA := [0.62, 0.55, 0.48]
const TAU_RAYLEIGH := 0.07
const TAU_AEROSOL := 0.08

## Kasten–Young relative air mass for a sun `elev_deg` above the horizon.
static func air_mass(elev_deg: float) -> float:
	var e := maxf(elev_deg, -0.5)
	return 1.0 / (sin(deg_to_rad(e)) + 0.50572 * pow(e + 6.07995, -1.6364))

## Direct-beam transmittance per channel (Rayleigh λ⁻⁴ + aerosol λ⁻¹).
static func sun_transmittance(elev_deg: float, haze: float = 1.0) -> Color:
	var m := air_mass(elev_deg)
	var out: Array[float] = []
	for l in SUN_LAMBDA:
		var r := float(l) / 0.55
		out.append(exp(-(TAU_RAYLEIGH * pow(r, -4.0) + TAU_AEROSOL * haze * pow(r, -1.0)) * m))
	return Color(out[0], out[1], out[2])

var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var environment: Environment
var sky_material: ShaderMaterial
## Render units per metre of the generated world (WorldScale; identity
## since the T7.0 metre cutover); haze density is defined per metre.
var units_per_metre := WorldScale.metres_to_units()
var hour := 17.0
var latitude := 48.8566
var longitude := 2.3522
## Local clock offset from UTC (hours) and whether it came from a real
## source (the weather service) rather than longitude / 15.
var utc_offset_h := 0.0
var utc_offset_known := false
var date := {}
## Current true sun (degrees; azimuth clockwise from north).
var solar_elevation := 0.0
var solar_azimuth := 0.0
var cloud_cover := DEFAULT_COVER
var weather_code := -1
var season: int = LocationData.Season.SUMMER
## Current zenith / anti-sun horizon / haze colours (sRGB), exposed so
## tests and callers can read the state without the shader.
var sky_top_color := Color(0.50, 0.66, 0.80)
var sky_horizon_color := Color(0.86, 0.84, 0.80)
var haze_color := Color(0.80, 0.82, 0.84)
var cloud_shade_color := Color(0.55, 0.58, 0.64)
## 0 by day -> 1 in full night (stars, Milky Way); twilight peaks as the
## sun crosses the horizon (Earth's shadow, Belt of Venus).
var night_amount := 0.0
var twilight_amount := 0.0
## Live weather's effect on light, haze and particles (WeatherLook).
var weather_look := WeatherLook.for_code(-1, DEFAULT_COVER)
## The real moon at the current hour (SolarPosition.moon) and how far
## it has risen (0 set .. 1 up).
var moon_state := {}
var moon_up := 0.0
## Climate snow lying at the viewpoint (ViewConditions): bright bounce.
var snow_ground := false
var lightning: LightningRig
var _preset: int = RenderSettings.Preset.HIGH
var _drift := 0.0
var _drift_accum := 0.0
var _flash_on := false
var _flash_sky_gain := 1.0

## Night light: full-moon energy on top of a faint skyglow (airglow,
## starlight, distant towns) that keeps moonless nights readable.
const MOON_E := 0.14
const SKYGLOW_E := 0.025
const MOON_COLOR := Color(0.62, 0.72, 0.95)
## Exposure lift in full night: the eye adapts, the scene stays legible.
const NIGHT_EXPOSURE_LIFT := 0.12

func _init(preset: int = RenderSettings.Preset.HIGH) -> void:
	name = "AtmosphereRig"
	_build_sun()
	_build_environment()
	_build_probe()
	lightning = LightningRig.new()
	add_child(lightning)
	set_quality(preset)
	_apply()

func _process(delta: float) -> void:
	if _probe_due > 0.0:
		_probe_due -= delta
		if _probe_due <= 0.0:
			# Any property change re-queues an UPDATE_ONCE capture, which
			# Godot spreads over six frames (one cube face each).
			probe.intensity = 1.0 if probe.intensity < 1.0 else 0.9999
	# Lightning writes the sky only while a flash is lit (it dirties the
	# radiance map); flashes never re-capture the reflection probe.
	if lightning.active or _flash_on:
		lightning.step(delta)
		_push_flash()
	_drift_accum += delta
	if _drift_accum < DRIFT_STEP_S:
		return
	# Wind speed scales gently with cover: fair-weather cumulus creep,
	# frontal decks move a little faster.
	_drift = fmod(_drift + _drift_accum * lerpf(0.004, 0.008, cloud_cover / 100.0), 1000.0)
	_drift_accum = 0.0
	sky_material.set_shader_parameter("drift", _drift)
	RenderingServer.global_shader_parameter_set("cloud_shadow_drift", _drift)

# --- State API ---

## Centre of the reflection capture: the viewpoint (camera rig) — call
## once a place is shown; the probe re-renders there.
func set_probe_origin(pos: Vector3) -> void:
	probe.position = pos
	lightning.centre = pos
	_refresh_probe()

## Local clock hour (0-24, fractional) at the place; `on_date`
## ({year, month, day}) empty uses the season's mid-month day.
func set_time(hour_f: float, lat: float = latitude, on_date: Dictionary = {}) -> void:
	hour = fposmod(hour_f, 24.0)
	latitude = lat
	date = on_date
	_apply()

## Place for the solar position. Without a known UTC offset the clock
## is approximated from longitude until set_utc_offset lands.
func set_place(lat: float, lon: float) -> void:
	latitude = lat
	longitude = lon
	if not utc_offset_known:
		utc_offset_h = roundf(lon / 15.0)
	_apply()

func set_utc_offset(hours: float) -> void:
	utc_offset_h = hours
	utc_offset_known = true
	_apply()

## The date the sun is computed for: the explicit one, else the season's
## mid-month day this year (southern hemisphere six months on).
func solar_date() -> Dictionary:
	if not date.is_empty():
		return date
	var month: int = SkyPalette.SEASON_MONTH[season]
	if latitude < 0.0:
		month = (month + 5) % 12 + 1
	return {"year": int(Time.get_date_dict_from_system().get("year", 2026)),
		"month": month, "day": 15}

func solar_at(hour_f: float) -> Dictionary:
	return SolarPosition.compute(latitude, longitude, solar_date(), hour_f - utc_offset_h)

## Local hour (quarter-hour steps) at which the afternoon sun sinks
## through the golden-hour reference elevation; where it never does
## (polar day or night, low winter sun) the afternoon hour whose sun is
## closest to it.
func golden_hour() -> float:
	var best := 17.0
	var best_err := INF
	var prev := solar_at(12.0)
	for i in range(49, 97):
		var h := float(i) * 0.25
		var sp := solar_at(h)
		var err := absf(float(sp["elevation"]) - GOLDEN_ELEV)
		if float(prev["elevation"]) >= GOLDEN_ELEV and float(sp["elevation"]) < GOLDEN_ELEV \
				and float(sp["hour_angle"]) > 0.0:
			# The nearer of the two steps either side of the crossing.
			return h - 0.25 if float(prev["elevation"]) - GOLDEN_ELEV < err else h
		if err < best_err and float(sp["hour_angle"]) > 0.0:
			best_err = err
			best = h
		prev = sp
	return best

## Open-Meteo weather code + cloud cover %. Coverage drives the cloud
## deck itself; the code sets visibility, light and lightning.
func set_weather(code: int, cover: float) -> void:
	weather_code = code
	cloud_cover = clampf(cover, 0.0, 100.0)
	weather_look = WeatherLook.for_code(code, cloud_cover)
	_apply()

## Snow lying at the viewpoint brightens the ground bounce light.
func set_snow_ground(on: bool) -> void:
	if on != snow_ground:
		snow_ground = on
		_apply()

func set_season(value: int) -> void:
	season = LocationData.clamp_season(value)
	_apply()

## Shadow reach/softness, cloud octaves and the tier's renderer
## features (RenderQuality) for a RenderSettings preset.
func set_quality(preset: int) -> void:
	_preset = RenderSettings.clamp_preset(preset)
	sun.directional_shadow_max_distance = RenderSettings.shadow_distance_for(_preset)
	sun.shadow_blur = RenderSettings.shadow_blur_for(_preset)
	sky_material.set_shader_parameter("octaves", RenderSettings.cloud_octaves_for(_preset))
	sky_material.set_shader_parameter("cloud_quality", _preset)
	RenderQuality.apply_environment(environment, _preset)
	RenderQuality.apply_light(sun, _preset)
	sun.shadow_opacity = float(weather_look["shadow_opacity"])
	_update_lightning()
	if is_inside_tree():
		RenderQuality.apply_viewport(get_viewport(), _preset)

func _ready() -> void:
	RenderQuality.apply_viewport(get_viewport(), _preset)

func is_foggy() -> bool:
	return WeatherLook.is_foggy(weather_look)

# --- Construction ---

func _build_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-10, 65, 0)
	sun.light_color = Color(1.0, 0.85, 0.64)  # #FFD9A3
	sun.light_energy = 3.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	# Splits weighted to the near field (eye 30 m): cascades end at
	# ~4% / 15% / 42% of the shadow reach (≈100 / 360 / 1000 m on High)
	# instead of 10/20/50%, so street-level shadows get most texels.
	sun.directional_shadow_split_1 = 0.04
	sun.directional_shadow_split_2 = 0.15
	sun.directional_shadow_split_3 = 0.42
	sun.directional_shadow_blend_splits = true
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.2
	add_child(sun)

func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var shader := Shader.new()
	shader.code = SkyShader.CODE
	sky_material = ShaderMaterial.new()
	sky_material.shader = shader
	var sky := Sky.new()
	sky.sky_material = sky_material
	# Uniform-driven updates only (see DRIFT_STEP_S): spread the
	# radiance re-filter over frames, small map — it only feeds
	# ambient light and rough reflections.
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	environment.sky = sky
	# Ambient sky light, ACES grade, glow and haze model (every tier).
	PostGrade.apply(environment)
	world_environment.environment = environment
	add_child(world_environment)

# --- State -> light / sky / fog ---

## Reflections of the real surroundings for water, wet ground and
## glass (Mobile has no SSR; on Forward+ SSR refines it on screen):
## one cubemap rendered from the viewpoint,
## re-rendered only when the light changes (time, weather, season,
## place) — never per frame. No box projection: the reflected city and
## hills sit at their true (far) distance, which is what water and
## windows at street scale show.
var probe: ReflectionProbe
var _probe_due := 0.0
const PROBE_DEBOUNCE_S := 0.4

func _build_probe() -> void:
	probe = ReflectionProbe.new()
	probe.name = "ViewReflections"
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.size = Vector3(4800.0, 1600.0, 4800.0) * units_per_metre
	probe.max_distance = 30000.0 * units_per_metre
	probe.box_projection = false
	probe.enable_shadows = true
	probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	probe.mesh_lod_threshold = 4.0
	add_child(probe)

func _refresh_probe() -> void:
	if probe != null:
		_probe_due = PROBE_DEBOUNCE_S

func _apply() -> void:
	_refresh_probe()
	var look := weather_look
	var cover := cloud_cover / 100.0
	var overcast := smoothstep(0.7, 1.0, cover)
	var dim := float(look["sun_dim"])
	var darken := float(look["cloud_darken"])
	var s: Dictionary = SkyPalette.SEASON_SKY[season]
	var sp := solar_at(hour)
	solar_elevation = float(sp["elevation"])
	solar_azimuth = float(sp["azimuth"])
	# Day arc of the true sun: >0 by day, <0 at night.
	var arc := clampf(solar_elevation / (DAY_DEG if solar_elevation >= 0.0 else NIGHT_DEG), -1.0, 1.0)
	# Equivalent hour on the reference day for the colour keyframes.
	var arc_h := 12.0 * asin(arc) / PI
	var key_h := (18.0 - arc_h) if float(sp["hour_angle"]) > 0.0 else (6.0 + arc_h)
	var eff := arc
	var night := arc <= -0.08
	if not night:
		# The light pitch floors just above the horizon; its yaw is the
		# real azimuth (node -Z points from the sun to the ground).
		var pitch := clampf(solar_elevation, MIN_LIGHT_PITCH, 90.0)
		sun.rotation_degrees = Vector3(-pitch, 180.0 - solar_azimuth, 0)
		# Direct sun = top-of-atmosphere light × the real path's
		# extinction (air mass from the true elevation), so colour and
		# strength follow the actual sun: white-gold at noon, #FFD9A3 at
		# the golden-hour reference, orange-red at the horizon.
		var tr := sun_transmittance(solar_elevation, float(s["haze"]))
		var mx := maxf(tr.r, maxf(tr.g, tr.b))
		sun.light_color = Color(tr.r / mx, tr.g / mx, tr.b / mx)
		sun.light_energy = maxf(SUN_E0 * tr.g, 0.22) * dim
		moon_up = 0.0
	else:
		_moonlight(dim)
	# Cloud and rain soften shadows as the diffuse sky takes over.
	sun.shadow_opacity = float(look["shadow_opacity"])
	# The sky's sun keeps its true position below the horizon, so the
	# dusk glow slides down continuously instead of jumping to the moon.
	var solar_dir := SolarPosition.direction(solar_elevation, solar_azimuth)
	# Glow lingers after sunset and fades out by ~20:30.
	var dusk := 1.0 - smoothstep(0.08, 0.5, -arc)
	night_amount = smoothstep(0.12, 0.45, -arc)
	twilight_amount = exp(-pow((arc + 0.05) / 0.12, 2.0))
	var sky := SkyPalette.colors_at(key_h, season)
	var zenith: Color = sky["zenith"]
	var horizon: Color = sky["horizon"]
	var glow: Color = sky["glow"]
	var low_sun := dusk if night else 1.0 - clampf((eff - 0.15) * 2.0, 0.0, 0.75)
	# Overcast greys the whole dome; brightness follows the day level and
	# a storm deck darkens it further.
	var day_level := 0.12 if night else clampf(0.55 + arc * 1.0, 0.55, 1.0)
	var grey := Color(0.66, 0.69, 0.73) * day_level * (1.0 - 0.35 * darken)
	zenith = zenith.lerp(grey * 0.92, overcast * 0.9)
	horizon = horizon.lerp(grey * 1.08, overcast * 0.85)
	glow = glow.lerp(horizon, overcast * 0.9)
	sky_top_color = zenith
	sky_horizon_color = horizon
	# Haze is the horizon pulled toward the zenith: cooler and bluer
	# than the horizon line itself, so far ridges read blue-grey.
	haze_color = horizon.lerp(zenith, 0.22)
	var lit := sun.light_color * clampf(0.55 + sun.light_energy * 0.18, 0.4, 1.0)
	var shade := zenith.lerp(horizon, 0.55) * 0.82
	if night:
		# Afterglow: cloud undersides stay sunset-lit, then go moonlit.
		lit = Color(0.16, 0.18, 0.25).lerp(glow * 0.9, dusk * 0.8)
		shade = Color(0.05, 0.06, 0.10).lerp(shade, dusk * 0.6)
	lit = lit.lerp(grey * 1.15, overcast)
	shade = shade.lerp(grey * 0.82, overcast)
	# Storm bases: lower, darker and faintly blue-green underneath.
	shade = shade * (1.0 - 0.5 * darken) * (look["cloud_tint"] as Color)
	lit = lit.lerp(shade, 0.4 * darken)
	cloud_shade_color = shade
	# Ground bounce under the horizon: snow cover reflects most light.
	var ground := Color(0.80, 0.82, 0.86) if snow_ground or look["precip"] == "snow" \
		else Color(0.42, 0.38, 0.33)
	var p := sky_material
	p.set_shader_parameter("zenith_color", zenith)
	p.set_shader_parameter("horizon_color", horizon)
	p.set_shader_parameter("glow_color", glow)
	p.set_shader_parameter("ground_color", ground * day_level)
	p.set_shader_parameter("cloud_lit", lit)
	p.set_shader_parameter("cloud_shade", shade)
	p.set_shader_parameter("glow_amount", low_sun * (1.0 - overcast))
	p.set_shader_parameter("sun_disc", (0.0 if night else 1.0) * (1.0 - overcast))
	p.set_shader_parameter("moon", moon_up * (1.0 - overcast))
	p.set_shader_parameter("moon_illum", float(moon_state.get("illum", 1.0)))
	p.set_shader_parameter("cloud_cover", cover)
	p.set_shader_parameter("overcast", overcast)
	p.set_shader_parameter("cloud_stretch", float(s["stretch"]))
	p.set_shader_parameter("cloud_soft", float(s["soft"]))
	p.set_shader_parameter("solar_dir", solar_dir)
	p.set_shader_parameter("twilight", twilight_amount * (1.0 - overcast))
	p.set_shader_parameter("night_amount", night_amount)
	p.set_shader_parameter("star_gain", float(s["stars"]))
	p.set_shader_parameter("milky_gain", float(s["milky"]))
	var tilt := deg_to_rad(float(s["milky_tilt"]))
	var yaw := deg_to_rad(float(s["milky_yaw"]))
	p.set_shader_parameter("milky_normal", Vector3(sin(tilt) * cos(yaw), cos(tilt), sin(tilt) * sin(yaw)))
	# Far terrain's cloud shadows follow this deck (TerrainGlsl).
	RenderingServer.global_shader_parameter_set("cloud_shadow_cover", 0.0 if night else cover * (1.0 - overcast))
	RenderingServer.global_shader_parameter_set("cloud_shadow_stretch", float(s["stretch"]))
	RenderingServer.global_shader_parameter_set("cloud_sun_dir", solar_dir)
	environment.fog_light_color = haze_color.darkened(0.3 * darken)
	var haze := HAZE_PER_M * lerpf(1.0, 1.6, overcast) * float(s["haze"])
	environment.fog_density = WeatherLook.fog_per_m(look, haze) / maxf(units_per_metre, 1e-4)
	environment.fog_sun_scatter = 0.0 if night else 0.25 * low_sun * (1.0 - overcast)
	# Diffuse sky light takes over under cloud; the eye adapts to storms
	# and to the night.
	environment.ambient_light_energy = PostGrade.AMBIENT_ENERGY * float(look["ambient_gain"])
	environment.tonemap_exposure = PostGrade.EXPOSURE \
		* (1.0 + float(look["exposure_lift"]) + NIGHT_EXPOSURE_LIFT * night_amount)
	RenderQuality.update_volume(environment, haze_color, is_foggy(), units_per_metre)
	_update_lightning()

## Night light from the real moon while it is up, its strength
## following the lit fraction; once it sets only the skyglow remains.
func _moonlight(dim: float) -> void:
	moon_state = SolarPosition.moon(latitude, longitude, solar_date(), hour - utc_offset_h)
	var el := float(moon_state["elevation"])
	moon_up = smoothstep(-0.5, 4.0, el)
	if moon_up > 0.0:
		var pitch := clampf(el, MIN_LIGHT_PITCH, 90.0)
		sun.rotation_degrees = Vector3(-pitch, 180.0 - float(moon_state["azimuth"]), 0)
	else:
		# Skyglow has no source: a high, soft light.
		sun.rotation_degrees = Vector3(-70.0, 180.0 - solar_azimuth, 0)
	sun.light_energy = (SKYGLOW_E + MOON_E * pow(float(moon_state["illum"]), 0.7) * moon_up) * dim
	sun.light_color = MOON_COLOR

## Storm state for the lightning: flashes read strongest at night and
## under the darkest decks.
func _update_lightning() -> void:
	var daylight := smoothstep(-6.0, 15.0, solar_elevation) * float(weather_look["sun_dim"])
	_flash_sky_gain = lerpf(1.0, 0.25, daylight)
	lightning.set_conditions(weather_look, season, daylight, _preset,
		environment.fog_density * units_per_metre)
	if _flash_on and not lightning.active:
		_push_flash()

func _push_flash() -> void:
	_flash_on = lightning.flash_level > 0.0
	sky_material.set_shader_parameter("flash", lightning.flash_level * _flash_sky_gain)
	sky_material.set_shader_parameter("flash_dir", lightning.flash_dir)
	sky_material.set_shader_parameter("flash_spread", lightning.flash_spread)
