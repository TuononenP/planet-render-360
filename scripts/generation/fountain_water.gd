class_name FountainWater
extends RefCounted

## GPU-animated fountain water shaders, cached materials and landmark/plaza
## upgrade pass:
## - Basin surface (opaque, preserves Forward+ SSR): animated capillary ripples,
##   refracted moving caustics over a shallow stone floor, Beer-Lambert depth
##   tint, micro-facet sun glints, live rain rings and winter freeze.
## - Flowing water (jets, parabolic arcs, bowl overflow curtains, reef/weir
##   cascades): accelerating dual-octave aerated filaments, subtle vertex wind
##   wobble, laminar-to-frothy transition (COLOR.r), speed (COLOR.g) and soft
##   feathered edges (COLOR.b).
## - Basin splash boil & concentric ripple rings (radial discs + plunge strips).
## - Rising spray mist billboards (single MultiMeshInstance3D, zero CPU work).

const BASIN_META := "fountain_basin"
const FLOW_META := "fountain_flow"
const FOAM_META := "fountain_foam"
const IMPOSTOR_SKIP_META := "impostor_skip"
const MIST_NODE_PREFIX := "FountainMist"

const BASIN_CODE := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;
""" + WaterShader.FILTER_GLSL + """

uniform vec4 shallow_color : source_color = vec4(0.18, 0.42, 0.48, 1.0);
uniform vec4 deep_color : source_color = vec4(0.08, 0.24, 0.30, 1.0);
uniform float base_rough = 0.06;
uniform float units_per_metre = 1.0;
uniform vec2 wind = vec2(0.86, 0.51);
uniform int water_quality = 2;

// @SNOW
// @CLOUD_SHADOW

varying vec3 wpos;

float fw_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float fw_noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(fw_hash(i), fw_hash(i + vec2(1.0, 0.0)), u.x),
		mix(fw_hash(i + vec2(0.0, 1.0)), fw_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec2 fw_grad(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec2 du = 6.0 * f * (1.0 - f);
	float a = fw_hash(i);
	float b = fw_hash(i + vec2(1.0, 0.0));
	float c = fw_hash(i + vec2(0.0, 1.0));
	float d = fw_hash(i + vec2(1.0, 1.0));
	return du * (vec2(b - a, c - a) + (a - b - c + d) * u.yx);
}

vec2 fw_wave(vec2 p, vec2 dir, float len, float steep, float t, float pixel_m) {
	float k = 6.2831853 / len;
	float ph = dot(dir, p) * k - t * sqrt(9.81 * k) * 0.85;
	return dir * (steep * cos(ph)) * water_wave_weight(pixel_m, len);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 pm = wpos.xz / max(units_per_metre, 0.001);
	float pixel_m = max(length(dFdx(pm)), length(dFdy(pm)));
	float dist_m = length(wpos - CAMERA_POSITION_WORLD) / max(units_per_metre, 0.001);
	float t = TIME;
	vec2 wd = normalize(wind);

	// Multi-scale fountain basin capillary ripples + gentle wind chop.
	vec2 s = vec2(0.0);
	s += fw_wave(pm, normalize(vec2(0.84, 0.54)), 0.78, 0.054, t, pixel_m);
	s += fw_wave(pm, normalize(vec2(-0.52, 0.85)), 0.50, 0.044, t * 1.12, pixel_m);
	s += fw_wave(pm, normalize(vec2(0.95, -0.31)), 0.30, 0.032, t * 1.28, pixel_m);
	s += fw_wave(pm, normalize(vec2(-0.74, -0.67)), 0.19, 0.024, t * 1.45, pixel_m);
	s += fw_grad(pm * 2.1 + wd * t * 0.42) * 0.068 * water_wave_weight(pixel_m, 0.48);
	s += fw_grad(pm * 4.7 - wd.yx * t * 0.65) * 0.038 * water_wave_weight(pixel_m, 0.21);
	s /= (1.0 + dist_m / 65.0);

	if (climate_rain > 0.0 && water_quality >= 2) {
		s += rain_ripples(pm * 1.3, t, pixel_m * 1.3) * 0.18;
		s *= 1.0 + 0.35 * climate_rain;
	}

	float ice = clamp(climate_water_ice, 0.0, 1.0);
	s *= (1.0 - ice);

	vec3 n_world = normalize(vec3(-s.x, 1.0, -s.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	float csh = cloud_shadow_at(wpos / max(units_per_metre, 0.001));
	float sun_up = smoothstep(0.04, 0.28, cloud_sun_dir.y);
	float direct_sun = sun_up * clamp(climate_snow_glint, 0.0, 1.0);

	// Simulated shallow stone basin floor with refracted animated caustics.
	float floor_mottle = fw_noise(pm * 0.85) * 0.55 + fw_noise(pm * 2.6 + 3.7) * 0.45;
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, 0.35 + 0.45 * floor_mottle);
	if (water_quality >= 2 && ice < 0.85) {
		vec2 bed_p = pm + s * 0.45;
		float stone_v = fw_noise(bed_p * 2.8) * 0.55 + fw_noise(bed_p * 8.5 + 1.9) * 0.45;
		vec3 bed_col = mix(shallow_color.rgb * 1.15, vec3(0.42, 0.44, 0.38), 0.35) * mix(0.84, 1.16, stone_v);
		float caust_w = (1.0 - smoothstep(45.0, 180.0, dist_m)) * (1.0 - ice)
			* water_wave_weight(pixel_m, 0.18) * (0.35 + 0.65 * direct_sun * (1.0 - csh));
		if (caust_w > 0.01) {
			vec2 cp = bed_p * 2.6 - cloud_sun_dir.xz * 0.28;
			float c1 = 1.0 - abs(2.0 * fw_noise(cp + vec2(t * 0.62, -t * 0.48)) - 1.0);
			float c2 = 1.0 - abs(2.0 * fw_noise(cp * 1.42 - vec2(t * 0.51, t * 0.67) + 4.3) - 1.0);
			float caust = pow(clamp(c1 * c2, 0.0, 1.0), 2.2) * 2.25;
			bed_col += vec3(0.42, 0.50, 0.48) * caust * caust_w;
		}
		// Beer-Lambert shallow pool absorption (~0.55 m depth).
		vec3 trans = exp(-0.55 * vec3(1.15, 0.42, 0.34));
		col = mix(col, bed_col * trans + shallow_color.rgb * (vec3(1.0) - trans), 0.68 * (1.0 - ice));
	}

	// Subtle translucent turquoise brightening on ripple crests.
	col += vec3(0.014, 0.042, 0.044) * smoothstep(0.02, 0.14, length(s)) * (1.0 - ice) * (1.0 - 0.5 * csh);
	col *= 1.0 - 0.22 * csh * sun_up;

	if (ice > 0.01) {
		float snowy = snow_line(wpos);
		vec3 bare_ice = vec3(0.56, 0.64, 0.70) * (0.92 + 0.14 * fw_noise(pm * 1.4));
		vec3 ice_c = mix(bare_ice, snow_albedo(pm, pixel_m, 0.0), snowy * 0.75);
		col = mix(col, ice_c, ice);
	}

	ALBEDO = col;

	// Clamped sun sparkle glints on capillary ripples.
	vec3 glint = vec3(0.0);
	if (water_quality >= 2 && direct_sun > 0.01 && ice < 0.5) {
		vec3 view_w = normalize(CAMERA_POSITION_WORLD - wpos);
		vec3 half_w = normalize(view_w + normalize(cloud_sun_dir));
		vec2 gn = fw_grad(pm * 5.2 + wd * t * 0.75) * 0.16 * water_wave_weight(pixel_m, 0.16);
		vec3 n_g = normalize(vec3(-(s.x + gn.x), 1.0, -(s.y + gn.y)));
		float ndh = max(dot(n_g, half_w), 0.0);
		float spk = pow(ndh, 240.0) * (1.0 - ice) * (1.0 - csh) * (1.0 - 0.8 * climate_rain) * direct_sun;
		vec3 gcol = mix(vec3(1.0, 0.80, 0.52), vec3(1.0, 0.97, 0.92), smoothstep(0.12, 0.5, cloud_sun_dir.y));
		glint = gcol * min(spk * 0.85, 0.78);
	}
	EMISSION = glint;

	float rough = mix(base_rough, 0.12, smoothstep(40.0, 320.0, dist_m));
	rough = mix(rough, 0.38, ice);
	ROUGHNESS = water_roughness(rough, n_world);
	SPECULAR = mix(0.42, 0.25, ice);
	METALLIC = 0.0;
}
"""

## Flowing water streams: vertical plumes, parabolic arcs, bowl overflow curtains,
## and reef/weir cascades.
## UV.x = 0..1 across width (soft edge feather); UV.y = distance along flow (m).
## COLOR.r = aeration (0 glassy .. 1 frothy white), COLOR.g = flow speed (m/s / 6),
## COLOR.b = edge/end opacity multiplier.
const FLOW_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_tint : source_color = vec4(0.68, 0.85, 0.89, 1.0);
uniform vec4 foam_tint : source_color = vec4(0.95, 0.97, 0.99, 1.0);
uniform float units_per_metre = 1.0;

// @SNOW
// @CLOUD_SHADOW

varying vec3 wpos;
varying vec3 vcol;

float fl_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float fl_noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(fl_hash(i), fl_hash(i + vec2(1.0, 0.0)), u.x),
		mix(fl_hash(i + vec2(0.0, 1.0)), fl_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	vcol = COLOR.rgb;
	vec3 pos = VERTEX;
	float flow_m = UV.y;
	float aero = COLOR.r;
	// Gentle aerodynamic flutter along the falling/rising stream.
	float flutter = sin(flow_m * 3.8 - TIME * 7.2 + pos.x * 2.1 + pos.z * 1.9) * 0.022
		+ cos(flow_m * 7.5 - TIME * 11.4 + pos.z * 3.3) * 0.011;
	pos += NORMAL * flutter * smoothstep(0.0, 0.45, flow_m) * (0.4 + 0.6 * aero);
	VERTEX = pos;
	wpos = (MODEL_MATRIX * vec4(pos, 1.0)).xyz;
}

void fragment() {
	float ice = smoothstep(0.35, 0.72, climate_water_ice);
	float dist_m = length(wpos - CAMERA_POSITION_WORLD) / max(units_per_metre, 0.001);
	float dfade = (1.0 - smoothstep(220.0, 520.0, dist_m)) * (1.0 - ice);
	if (dfade < 0.01) {
		discard;
	}
	float across = UV.x;
	float along = UV.y;
	float aero = clamp(vcol.r, 0.0, 1.0);
	float spd = max(vcol.g * 6.0, 1.2);
	float mask_end = clamp(vcol.b, 0.0, 1.0);

	// Soft ribbon edge feathering so crossed planes never show sharp cuts.
	float edge = smoothstep(0.0, 0.24, across) * (1.0 - smoothstep(0.76, 1.0, across));
	float core = exp(-pow((across - 0.5) * 2.5, 2.0));

	// Dual-octave elongated flowing water filaments scrolling with gravity.
	float t = TIME;
	vec2 uv1 = vec2(across * 4.2 + sin(along * 1.4 - t * 2.4) * 0.18, along * 1.35 - t * spd * 0.75);
	vec2 uv2 = vec2(across * 10.5 - sin(along * 2.6 - t * 3.5) * 0.22, along * 3.1 - t * spd * 1.25);
	float n1 = fl_noise(uv1);
	float n2 = fl_noise(uv2);
	float streak = smoothstep(0.24, 0.84, n1 * 0.62 + n2 * 0.38);
	// Fine broken droplets appear as aeration rises.
	float drops = smoothstep(0.42, 0.88, fl_noise(vec2(across * 18.0, along * 5.8 - t * spd * 1.65)));

	float body = mix(0.45 + 0.55 * streak, streak * 0.75 + drops * 0.45, aero);
	float alpha = clamp((edge * 0.72 + core * 0.38) * body * mask_end * mix(0.68, 0.86, aero), 0.0, 0.88) * dfade;
	if (alpha < 0.015) {
		discard;
	}

	float csh = cloud_shadow_at(wpos / max(units_per_metre, 0.001));
	float sun_up = smoothstep(0.04, 0.28, cloud_sun_dir.y);
	vec3 view_d = normalize(CAMERA_POSITION_WORLD - wpos);
	float fres = pow(1.0 - abs(dot(NORMAL, view_d)), 2.2);
	float foam_w = clamp(aero * 0.75 + streak * 0.35 + drops * 0.25, 0.0, 1.0);
	vec3 col = mix(water_tint.rgb, foam_tint.rgb, foam_w);
	// Subtle sunlit forward/rim scatter on water droplets (no night self-glow).
	float fwd = pow(max(dot(-view_d, normalize(cloud_sun_dir)), 0.0), 3.0) * sun_up * (1.0 - csh);
	col = mix(col, vec3(1.0, 0.99, 0.96), clamp(fres * 0.35 + fwd * 0.28, 0.0, 0.55));
	col *= 1.0 - 0.18 * csh * sun_up;

	// Bias normal upward and enable translucent BACKLIGHT so aerated spray
	// scatters sunlight/floodlights from every viewing azimuth instead of
	// shading dark grey on the shadow side of vertical ribbon fins.
	vec3 up_v = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	NORMAL = normalize(mix(NORMAL, up_v, 0.72));
	ALBEDO = col;
	BACKLIGHT = col * mix(0.48, 0.78, foam_w);
	ALPHA = alpha;
	ROUGHNESS = mix(0.14, 0.40, foam_w);
	SPECULAR = mix(0.55, 0.30, foam_w);
	METALLIC = 0.0;
}
"""

## Basin impact splash boil & expanding concentric ripple rings.
## COLOR.r = intensity (0..1), COLOR.g < 0.5 = radial splash ring (UV 0..1 disc),
## COLOR.g >= 0.5 = linear cascade plunge strip (UV.x metres along strip, UV.y 0..1 across).
const FOAM_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, diffuse_burley;

uniform float units_per_metre = 1.0;

// @SNOW
// @CLOUD_SHADOW

varying vec3 wpos;
varying vec3 vcol;

float fm_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float fm_noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(fm_hash(i), fm_hash(i + vec2(1.0, 0.0)), u.x),
		mix(fm_hash(i + vec2(0.0, 1.0)), fm_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	vcol = COLOR.rgb;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ice = smoothstep(0.35, 0.72, climate_water_ice);
	float dist_m = length(wpos - CAMERA_POSITION_WORLD) / max(units_per_metre, 0.001);
	float dfade = (1.0 - smoothstep(200.0, 480.0, dist_m)) * (1.0 - ice);
	if (dfade < 0.01) {
		discard;
	}
	float t = TIME;
	float intensity = clamp(vcol.r, 0.1, 1.0);
	bool is_strip = vcol.g >= 0.5;
	float alpha = 0.0;
	if (!is_strip) {
		vec2 q = (UV - 0.5) * 2.0;
		float r = length(q);
		if (r >= 1.0) {
			discard;
		}
		float ang = atan(q.y, q.x);
		float n_boil = fm_noise(vec2(cos(ang) * 3.2 + r * 5.2 - t * 2.4, sin(ang) * 3.2 + r * 5.2 - t * 2.1)) * 0.55
			+ fm_noise(wpos.xz * 3.2 + vec2(t * 1.1, -t * 0.9)) * 0.45;
		float boil = exp(-pow(r / 0.38, 2.0)) * smoothstep(0.22, 0.76, n_boil);
		// Organic broken concentric ripple crests radiating outward from impact.
		float ring_wave = pow(0.5 + 0.5 * sin(r * 19.0 - t * 6.0 + n_boil * 4.4), 3.2);
		float ring_break = smoothstep(0.26, 0.84, fm_noise(vec2(cos(ang) * 2.4, sin(ang) * 2.4) + wpos.xz * 1.8 - t * 0.4));
		float rings = ring_wave * smoothstep(0.18, 0.40, r) * (1.0 - smoothstep(0.46, 1.0, r)) * (0.28 + 0.72 * ring_break);
		alpha = (boil * 0.86 + rings * 0.40) * intensity * dfade;
	} else {
		float v = UV.y;
		float u = UV.x;
		float env = smoothstep(0.0, 0.22, v) * (1.0 - smoothstep(0.55, 1.0, v));
		float n1 = fm_noise(vec2(u * 1.8, v * 5.5 - t * 2.6));
		float n2 = fm_noise(vec2(u * 4.5 + 2.3, v * 10.0 - t * 3.8));
		float lace = smoothstep(0.26, 0.82, n1 * 0.6 + n2 * 0.4);
		float boil = smoothstep(0.0, 0.25, v) * (1.0 - smoothstep(0.25, 0.68, v)) * lace;
		float wave = pow(0.5 + 0.5 * sin(v * 20.0 - t * 6.2 + n1 * 2.6), 3.0) * smoothstep(0.25, 0.45, v) * (1.0 - smoothstep(0.55, 1.0, v));
		alpha = (boil * 0.86 + wave * 0.42) * env * intensity * dfade;
	}
	if (alpha < 0.015) {
		discard;
	}
	float csh = cloud_shadow_at(wpos / max(units_per_metre, 0.001));
	float sun_up = smoothstep(0.04, 0.28, cloud_sun_dir.y);
	ALBEDO = vec3(0.93, 0.96, 0.98) * (1.0 - 0.16 * csh * sun_up);
	BACKLIGHT = ALBEDO * 0.38;
	ALPHA = clamp(alpha, 0.0, 0.86);
	ROUGHNESS = 0.46;
	SPECULAR = 0.28;
}
"""

## Rising, softly wind-drifting spray mist puffs at energetic fountain splashes.
## INSTANCE_CUSTOM packs (phase_0_1, rise_m, puff_radius_m, drift_scale).
const MIST_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, diffuse_burley, world_vertex_coords;

uniform vec2 wind = vec2(0.86, 0.51);
uniform float units_per_metre = 1.0;

// @SNOW
// @CLOUD_SHADOW

varying float life_fade;
varying float seed_v;
varying vec3 wpos;

float ms_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float ms_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(ms_hash(i), ms_hash(i + vec2(1.0, 0.0)), f.x),
		mix(ms_hash(i + vec2(0.0, 1.0)), ms_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	float phase = INSTANCE_CUSTOM.r;
	float rise = INSTANCE_CUSTOM.g;
	float rad = INSTANCE_CUSTOM.b;
	float drift_k = INSTANCE_CUSTOM.a;
	float age = fract(TIME * 0.34 + phase);
	seed_v = phase * 23.1;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float sc = max(length(MODEL_MATRIX[0].xyz), 0.001);
	vec2 wd = normalize(wind);
	vec2 wn = vec2(-wd.y, wd.x);
	float sway = sin(TIME * 1.4 + phase * 14.0 + age * 4.5) * age * 0.32 * sc;
	vec3 puff = origin + vec3(wd.x * age * rise * drift_k * sc + wn.x * sway,
		age * rise * sc, wd.y * age * rise * drift_k * sc + wn.y * sway);
	float sz = rad * sc * (0.75 + age * 1.65);
	vec3 cam_r = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_u = INV_VIEW_MATRIX[1].xyz;
	vec2 corner = vec2(UV.x - 0.5, 0.5 - UV.y);
	VERTEX = puff + (cam_r * corner.x + cam_u * corner.y) * sz;
	NORMAL = normalize(CAMERA_POSITION_WORLD - puff);
	wpos = puff;
	float dist_m = length(puff - CAMERA_POSITION_WORLD) / max(units_per_metre, 0.001);
	float ice = smoothstep(0.35, 0.72, climate_water_ice);
	float dfade = smoothstep(1.5, 5.0, dist_m) * (1.0 - smoothstep(140.0, 320.0, dist_m)) * (1.0 - ice);
	life_fade = smoothstep(0.0, 0.22, age) * (1.0 - smoothstep(0.42, 1.0, age)) * dfade;
}

void fragment() {
	if (life_fade < 0.008) {
		discard;
	}
	vec2 q = (UV - 0.5) * 2.0;
	float r2 = dot(q, q);
	if (r2 >= 1.0) {
		discard;
	}
	float n = ms_noise(UV * 3.8 + vec2(seed_v, -TIME * 0.45)) * 0.65
		+ ms_noise(UV * 7.5 - vec2(TIME * 0.35, seed_v)) * 0.35;
	float puff = pow(1.0 - r2, 1.9) * smoothstep(0.20, 0.84, n);
	float a = puff * life_fade * 0.24;
	if (a < 0.008) {
		discard;
	}
	float csh = cloud_shadow_at(wpos / max(units_per_metre, 0.001));
	float sun_up = smoothstep(0.04, 0.28, cloud_sun_dir.y);
	ALBEDO = vec3(0.94, 0.97, 0.99) * (1.0 - 0.16 * csh * sun_up);
	ALPHA = a;
	ROUGHNESS = 0.85;
	SPECULAR = 0.12;
}
"""

static var _basin_mats: Dictionary = {}
static var _flow_mat: ShaderMaterial
static var _foam_mat: ShaderMaterial
static var _mist_mat: ShaderMaterial
static var _flow_fallback: StandardMaterial3D
static var _foam_fallback: StandardMaterial3D
static var _mutex := Mutex.new()

static func _splice(code: String) -> String:
	return code.replace("// @SNOW", ClimateModel.SNOW_GLSL) \
		.replace("// @CLOUD_SHADOW", TerrainGlsl.CLOUD_SHADOW_GLSL)

static func basin_shader() -> Shader:
	return SharedShader.of(_splice(BASIN_CODE))

static func flow_shader() -> Shader:
	return SharedShader.of(_splice(FLOW_CODE))

static func foam_shader() -> Shader:
	return SharedShader.of(_splice(FOAM_CODE))

static func mist_shader() -> Shader:
	return SharedShader.of(_splice(MIST_CODE))

## Cached animated basin ShaderMaterial calibrated to `hex` and `roughness`.
static func basin_material(hex: String = "#386878", roughness: float = 0.08,
		preset: int = RenderSettings.Preset.ULTRA) -> ShaderMaterial:
	var q := 2 if RenderSettings.clamp_preset(preset) >= RenderSettings.Preset.HIGH else 1
	var m2u := WorldScale.metres_to_units()
	var key := "%s|%.2f|%d|%.3f" % [hex, roughness, q, m2u]
	_mutex.lock()
	var mat: ShaderMaterial = _basin_mats.get(key)
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = basin_shader()
		var base := Color(hex)
		var deep := Color(base.r * 0.56, base.g * 0.64, base.b * 0.72, 1.0)
		var shallow := base.lightened(0.10)
		mat.set_shader_parameter("shallow_color", shallow)
		mat.set_shader_parameter("deep_color", deep)
		mat.set_shader_parameter("base_rough", clampf(roughness, 0.04, 0.25))
		mat.set_shader_parameter("units_per_metre", m2u)
		mat.set_shader_parameter("wind", WaterShader.WIND)
		mat.set_shader_parameter("water_quality", q)
		mat.set_meta("landmark_hex", hex)
		_basin_mats[key] = mat
	_mutex.unlock()
	return mat

static func flow_material() -> ShaderMaterial:
	_mutex.lock()
	if _flow_mat == null:
		_flow_mat = ShaderMaterial.new()
		_flow_mat.shader = flow_shader()
		_flow_mat.render_priority = 2
	_flow_mat.set_shader_parameter("units_per_metre", WorldScale.metres_to_units())
	var ret := _flow_mat
	_mutex.unlock()
	return ret

static func foam_material() -> ShaderMaterial:
	_mutex.lock()
	if _foam_mat == null:
		_foam_mat = ShaderMaterial.new()
		_foam_mat.shader = foam_shader()
		_foam_mat.render_priority = 1
	_foam_mat.set_shader_parameter("units_per_metre", WorldScale.metres_to_units())
	var ret := _foam_mat
	_mutex.unlock()
	return ret

static func mist_material() -> ShaderMaterial:
	_mutex.lock()
	if _mist_mat == null:
		_mist_mat = ShaderMaterial.new()
		_mist_mat.shader = mist_shader()
		_mist_mat.render_priority = 3
	_mist_mat.set_shader_parameter("units_per_metre", WorldScale.metres_to_units())
	_mist_mat.set_shader_parameter("wind", WaterShader.WIND)
	var ret := _mist_mat
	_mutex.unlock()
	return ret

## Textured translucent StandardMaterial3D base for FountainFlow (FAST fallback &
## landmark_test PBR contract); Balanced+ overrides it with flow_material().
static func flow_fallback_material() -> StandardMaterial3D:
	_mutex.lock()
	if _flow_fallback == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.92, 0.96, 0.98, 0.45)
		m.albedo_texture = LandmarkMaterials.pool_water().albedo_texture
		m.roughness = 0.25
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.set_meta(FLOW_META, true)
		_flow_fallback = m
	var ret := _flow_fallback
	_mutex.unlock()
	return ret

## Textured translucent StandardMaterial3D base for FountainFoam (FAST fallback &
## landmark_test PBR contract); Balanced+ overrides it with foam_material().
static func foam_fallback_material() -> StandardMaterial3D:
	_mutex.lock()
	if _foam_fallback == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.94, 0.97, 0.99, 0.38)
		m.albedo_texture = LandmarkMaterials.pool_water().albedo_texture
		m.roughness = 0.45
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.set_meta(FOAM_META, true)
		_foam_fallback = m
	var ret := _foam_fallback
	_mutex.unlock()
	return ret

## Upgrades every tagged fountain/pool basin under `root` to the animated
## basin shader on Balanced+, sets flow/foam shader overrides (or falls back
## to lightweight textured StandardMaterial3D on Fast), and tunes FountainMist
## visibility to High+. Idempotent and safe with LandmarkShader.upgrade().
static func upgrade(root: Node3D, preset: int = RenderSettings.Preset.ULTRA) -> int:
	if root == null:
		return 0
	var p := RenderSettings.clamp_preset(preset)
	var allow_anim := p >= RenderSettings.Preset.BALANCED
	var allow_mist := p >= RenderSettings.Preset.HIGH
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MultiMeshInstance3D and n.name.begins_with(MIST_NODE_PREFIX):
			(n as MultiMeshInstance3D).visible = allow_mist
		elif n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				for s in mi.mesh.get_surface_count():
					var base := mi.mesh.surface_get_material(s)
					if base == null:
						continue
					if base.has_meta(FLOW_META):
						var want: Material = flow_material() if allow_anim else null
						if mi.get_surface_override_material(s) != want:
							mi.set_surface_override_material(s, want)
					elif base.has_meta(FOAM_META):
						var want: Material = foam_material() if allow_anim else null
						if mi.get_surface_override_material(s) != want:
							mi.set_surface_override_material(s, want)
					elif allow_anim and base.has_meta(BASIN_META) and mi.get_surface_override_material(s) == null:
						var cfg: Dictionary = base.get_meta(BASIN_META)
						var hex := str(cfg.get("hex", "#386878"))
						var rough := float(cfg.get("roughness", 0.08))
						mi.set_surface_override_material(s, basin_material(hex, rough, p))
						count += 1
		stack.append_array(n.get_children())
	return count
