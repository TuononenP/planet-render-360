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
## Fog / drizzle / snow weather: ~1 km visibility.
const FOG_PER_M := 2.0e-3
const FOGGY_CODES := [45, 48, 51, 53, 55, 61, 63, 65, 71, 73, 75]
## Seconds between cloud-drift uniform steps. Drift is slow enough
## that 4 Hz steps are invisible, and the sky radiance map is only
## re-filtered when a uniform changes (TIME would dirty it per frame).
const DRIFT_STEP_S := 0.25

const SKY_SHADER := """
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.50, 0.66, 0.80);
uniform vec3 horizon_color : source_color = vec3(0.86, 0.84, 0.80);
uniform vec3 glow_color : source_color = vec3(0.96, 0.76, 0.52);
uniform vec3 ground_color : source_color = vec3(0.42, 0.38, 0.33);
uniform vec3 cloud_lit : source_color = vec3(0.95, 0.85, 0.70);
uniform vec3 cloud_shade : source_color = vec3(0.55, 0.58, 0.64);
uniform float glow_amount = 1.0;
uniform float sun_disc = 1.0;
uniform float cloud_cover = 0.3;
uniform float overcast = 0.0;
uniform int octaves = 5;
uniform float drift = 0.0;
uniform vec2 wind = vec2(0.8, 0.6);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Normalised FBM; `low` returns the 2-octave base for cheap lighting.
float fbm(vec2 p, int n, out float low) {
	float v = 0.0;
	float a = 0.5;
	float norm = 0.0;
	low = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 6; i++) {
		if (i >= n) {
			break;
		}
		v += a * vnoise(p);
		norm += a;
		if (i == 1) {
			low = v / norm;
		}
		p = r * p * 2.03 + vec2(17.1, 5.3);
		a *= 0.5;
	}
	return v / norm;
}

float fbm2(vec2 p) {
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	return (0.5 * vnoise(p) + 0.25 * vnoise(r * p * 2.03 + vec2(17.1, 5.3))) / 0.75;
}

void sky() {
	vec3 d = EYEDIR;
	float y = d.y;
	float hy = max(y, 0.0);
	vec3 sun_dir = LIGHT0_DIRECTION;
	float mu = dot(d, sun_dir);
	float m = max(mu, 0.0);

	// Rayleigh-ish: optical depth grows toward the horizon, so the
	// pale band is thin and the zenith keeps its blue.
	vec3 col = mix(horizon_color, zenith_color, pow(hy, 0.35));
	// Warm sun-side band (golden hour) and Mie-ish halo.
	float side = pow(mu * 0.5 + 0.5, 3.0);
	float band = exp(-hy * 9.0);
	col = mix(col, glow_color, clamp(band * side * glow_amount, 0.0, 1.0));
	col += glow_color * (pow(m, 24.0) * 0.12 + pow(m, 400.0) * 0.5) * glow_amount;
	// Below the horizon: haze first (aerial perspective samples here),
	// darkening to ground bounce only well below the horizon line.
	col = mix(col, ground_color, smoothstep(-0.12, -0.6, y));

	float alpha = 0.0;
	if (y > -0.02) {
		// Dome projection keeps the horizon finite and compresses the
		// deck into a band toward the horizon, like a real cloud layer.
		vec2 uv = d.xz / (y + 0.10) * 1.3 + wind * drift;
		// Low-frequency domain warp breaks the FBM into billowed
		// heaps instead of uniform streaks (two extra lookups).
		uv += 0.45 * vec2(vnoise(uv * 0.35), vnoise(uv * 0.35 + vec2(7.3, 2.1))) - 0.225;
		int n = AT_CUBEMAP_PASS ? 2 : octaves;
		float low;
		float den = fbm(uv, n, low);
		// Value-noise FBM clusters around 0.5, so cover maps onto a
		// narrow threshold range to give the matching sky fraction.
		float thr = 0.5 + (0.5 - cloud_cover) * 0.36;
		float c = smoothstep(thr - 0.02, thr + 0.12, den);
		// Overcast: the gaps close into a continuous grey deck.
		c = max(c, overcast * (0.80 + 0.20 * den));
		// One offset lookup toward the sun: denser sunward = shaded.
		vec2 sxz = normalize(sun_dir.xz + vec2(1e-4)) * 0.09;
		float toward = fbm2(uv + sxz);
		float lit = clamp(0.5 + (low - toward) * 5.0, 0.0, 1.0);
		float thick = smoothstep(thr, thr + 0.3, den);
		vec3 cc = mix(cloud_shade, cloud_lit, lit * (1.0 - 0.55 * thick));
		// Silver lining: thin cloud edges near the sun glow.
		cc += LIGHT0_COLOR * pow(m, 6.0) * (1.0 - thick) * 0.6 * (1.0 - overcast);
		// Distant clouds sink into the horizon haze.
		cc = mix(cc, mix(horizon_color, glow_color, band * side * glow_amount), exp(-hy * 9.0) * 0.65);
		alpha = c * smoothstep(-0.01, 0.10, y) * 0.96;
		col = mix(col, cc, alpha);
	}
	// Sun disc (~0.8 deg) behind the clouds.
	float disc = smoothstep(0.99985, 0.99994, mu) * sun_disc;
	col += LIGHT0_COLOR * LIGHT0_ENERGY * disc * 6.0 * (1.0 - alpha);
	COLOR = col;
}
"""

var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var environment: Environment
var sky_material: ShaderMaterial
## Render units per metre of the generated world (WorldScale; identity
## since the T7.0 metre cutover); haze density is defined per metre.
var units_per_metre := WorldScale.metres_to_units()
var hour := 17.0
var latitude := 48.8566
var date := {}
var cloud_cover := DEFAULT_COVER
var weather_code := -1
var season: int = LocationData.Season.SUMMER
## Current zenith / anti-sun horizon / haze colours (sRGB), exposed so
## tests and callers can read the state without the shader.
var sky_top_color := Color(0.50, 0.66, 0.80)
var sky_horizon_color := Color(0.86, 0.84, 0.80)
var haze_color := Color(0.80, 0.82, 0.84)
var _preset: int = RenderSettings.Preset.HIGH
var _drift := 0.0
var _drift_accum := 0.0

func _init(preset: int = RenderSettings.Preset.HIGH) -> void:
	name = "AtmosphereRig"
	_build_sun()
	_build_environment()
	set_quality(preset)
	_apply()

func _process(delta: float) -> void:
	_drift_accum += delta
	if _drift_accum < DRIFT_STEP_S:
		return
	# Wind speed scales gently with cover: fair-weather cumulus creep,
	# frontal decks move a little faster.
	_drift = fmod(_drift + _drift_accum * lerpf(0.004, 0.008, cloud_cover / 100.0), 1000.0)
	_drift_accum = 0.0
	sky_material.set_shader_parameter("drift", _drift)

# --- State API ---

## Hour of day (0-24, fractional); latitude and date are stored for the
## true solar position (T6.2) and do not move the sun yet.
func set_time(hour_f: float, lat: float = latitude, on_date: Dictionary = {}) -> void:
	hour = fposmod(hour_f, 24.0)
	latitude = lat
	date = on_date
	_apply()

## Open-Meteo weather code + cloud cover %. Coverage drives the cloud
## deck itself, not just the light level.
func set_weather(code: int, cover: float) -> void:
	weather_code = code
	cloud_cover = clampf(cover, 0.0, 100.0)
	_apply()

func set_season(value: int) -> void:
	season = LocationData.clamp_season(value)
	_apply()

## Shadow reach/softness and cloud octaves for a RenderSettings preset.
func set_quality(preset: int) -> void:
	_preset = RenderSettings.clamp_preset(preset)
	sun.directional_shadow_max_distance = RenderSettings.shadow_distance_for(_preset)
	sun.shadow_blur = RenderSettings.shadow_blur_for(_preset)
	sky_material.set_shader_parameter("octaves", RenderSettings.cloud_octaves_for(_preset))

func is_foggy() -> bool:
	return weather_code in FOGGY_CODES

# --- Construction ---

func _build_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-10, 65, 0)
	sun.light_color = Color(1.0, 0.85, 0.64)  # #FFD9A3
	sun.light_energy = 3.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.06
	add_child(sun)

func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var shader := Shader.new()
	shader.code = SKY_SHADER
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
	# Ambient comes from the sky so materials stay grounded in it.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.73, 0.80, 0.85)  # #B9CBD8
	# Lifted from 0.52: shadowed DEM slopes read near-black, not skylit.
	environment.ambient_light_energy = 0.62
	environment.ambient_light_sky_contribution = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.94
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.12
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_energy = 1.0
	environment.fog_sun_scatter = 0.25
	# The sky shader draws its own horizon haze; fog stays off it so
	# the cloud deck is not double-hazed.
	environment.fog_sky_affect = 0.0
	# Far geometry picks up the sky's directional colour: warm toward
	# the sun, blue-grey away from it.
	environment.fog_aerial_perspective = 0.55
	environment.glow_enabled = true
	environment.glow_bloom = 0.10
	environment.glow_intensity = 0.4
	environment.glow_strength = 1.0
	world_environment.environment = environment
	add_child(world_environment)

# --- State -> light / sky / fog ---

func _apply() -> void:
	var cover := cloud_cover / 100.0
	var overcast := smoothstep(0.7, 1.0, cover)
	var dim := lerpf(1.0, 0.55, cover)
	var arc := sin(PI * (hour - 6.0) / 12.0)  # >0 by day, <0 at night
	var night := arc <= -0.08
	if not night:
		var day_t := clampf((hour - 6.0) / 12.0, 0.0, 1.0)
		# Elevation follows the sun arc but floors at the PRD golden
		# band: at 17:00 the sun sits ~10° up, warm #FFD9A3.
		var elev := clampf(maxf(arc, 0.02) * 48.0, 8.0, 50.0)
		sun.rotation_degrees = Vector3(-elev, lerpf(-95.0, 95.0, day_t), 0)
		sun.light_energy = (0.75 + 1.35 * clampf(arc * 2.2, 0.0, 1.0)) * dim
		sun.light_color = Color(1.0, 0.85, 0.64).lerp(
			Color(1, 0.97, 0.92), clampf(arc * 1.7, 0.0, 1.0))
	else:
		# Moonlight: fixed cool light so night scenes stay readable.
		sun.rotation_degrees = Vector3(-38, 35, 0)
		sun.light_energy = 0.12 * dim
		sun.light_color = Color(0.62, 0.72, 0.95)
	var zenith := _keyframed(hour, [
		[0.0, Color(0.03, 0.05, 0.12)], [5.0, Color(0.06, 0.09, 0.19)],
		[6.5, Color(0.24, 0.38, 0.62)], [8.0, Color(0.30, 0.50, 0.78)],
		[12.0, Color(0.24, 0.45, 0.80)], [16.0, Color(0.33, 0.54, 0.82)],
		[17.0, Color(0.44, 0.62, 0.82)], [18.0, Color(0.38, 0.47, 0.66)],
		[19.0, Color(0.13, 0.16, 0.31)], [20.5, Color(0.05, 0.07, 0.15)],
		[24.0, Color(0.03, 0.05, 0.12)]])
	# Anti-sun horizon: the haze base. Pale blue by day, never cream.
	var horizon := _keyframed(hour, [
		[0.0, Color(0.07, 0.09, 0.16)], [5.0, Color(0.12, 0.13, 0.21)],
		[6.5, Color(0.62, 0.60, 0.66)], [8.0, Color(0.76, 0.81, 0.87)],
		[12.0, Color(0.70, 0.80, 0.91)], [16.0, Color(0.74, 0.80, 0.88)],
		[17.0, Color(0.76, 0.80, 0.86)], [18.0, Color(0.72, 0.62, 0.62)],
		[19.0, Color(0.30, 0.25, 0.33)], [20.5, Color(0.09, 0.10, 0.18)],
		[24.0, Color(0.07, 0.09, 0.16)]])
	# Sun-side horizon glow: PRD #F0C48F at 17:00.
	var glow := _keyframed(hour, [
		[0.0, Color(0.08, 0.10, 0.18)], [5.0, Color(0.26, 0.19, 0.24)],
		[6.5, Color(1.00, 0.64, 0.40)], [8.0, Color(1.00, 0.84, 0.66)],
		[12.0, Color(0.96, 0.95, 0.91)], [16.0, Color(1.00, 0.88, 0.70)],
		[17.0, Color(0.94, 0.77, 0.56)], [18.0, Color(1.00, 0.55, 0.32)],
		[19.0, Color(0.52, 0.30, 0.30)], [20.5, Color(0.10, 0.11, 0.19)],
		[24.0, Color(0.08, 0.10, 0.18)]])
	var low_sun := 0.0 if night else 1.0 - clampf((arc - 0.15) * 2.0, 0.0, 0.75)
	if season == LocationData.Season.WINTER and not night:
		# Cold dry air: paler, cooler horizon.
		horizon = horizon.lerp(Color(0.84, 0.87, 0.92), 0.25)
	# Overcast greys the whole dome; brightness follows the day level.
	var day_level := 0.12 if night else clampf(0.55 + arc * 1.0, 0.55, 1.0)
	var grey := Color(0.66, 0.69, 0.73) * day_level
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
		lit = Color(0.16, 0.18, 0.25)
		shade = Color(0.05, 0.06, 0.10)
	lit = lit.lerp(grey * 1.15, overcast)
	shade = shade.lerp(grey * 0.82, overcast)
	var p := sky_material
	p.set_shader_parameter("zenith_color", zenith)
	p.set_shader_parameter("horizon_color", horizon)
	p.set_shader_parameter("glow_color", glow)
	p.set_shader_parameter("ground_color", Color(0.42, 0.38, 0.33) * day_level)
	p.set_shader_parameter("cloud_lit", lit)
	p.set_shader_parameter("cloud_shade", shade)
	p.set_shader_parameter("glow_amount", low_sun * (1.0 - overcast))
	p.set_shader_parameter("sun_disc", (0.25 if night else 1.0) * (1.0 - overcast))
	p.set_shader_parameter("cloud_cover", cover)
	p.set_shader_parameter("overcast", overcast)
	environment.fog_light_color = haze_color
	var per_m := FOG_PER_M if is_foggy() else HAZE_PER_M * lerpf(1.0, 1.6, overcast)
	environment.fog_density = per_m / maxf(units_per_metre, 1e-4)
	environment.fog_sun_scatter = 0.25 * low_sun * (1.0 - overcast)

static func _keyframed(hour_f: float, keys: Array) -> Color:
	for i in keys.size() - 1:
		var h0 := float(keys[i][0])
		var h1 := float(keys[i + 1][0])
		if hour_f >= h0 and hour_f <= h1:
			var t := 0.0 if h1 == h0 else (hour_f - h0) / (h1 - h0)
			return (keys[i][1] as Color).lerp(keys[i + 1][1], t)
	return keys[keys.size() - 1][1]
