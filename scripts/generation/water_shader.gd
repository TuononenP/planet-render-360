class_name WaterShader
extends RefCounted

## The water surface GLSL for WaterSurface (split out to keep that class
## about geometry). PRD §4.3 colours, now with:
## - waves at three scales: metre-scale chop, 5–15 m wind waves and, on
##   the sea, 25–60 m swell. Chop fades with distance, the larger scales
##   stay, so far water carries reflection streaks instead of going to a
##   uniform sheen (v1 faded every normal and raised roughness);
## - Gerstner swell displacing the sea grid (High/Ultra), damped toward
##   the shore;
## - flow: river ribbons carry their downstream direction (UV2), and
##   their chop and foam streaks travel with the current;
## - shore foam: an animated broken band along shorelines, banks and
##   beaches (COLOR.b = shore distance), stronger on the sea;
## - absorption: shallow water warmer/greener, open water deeper teal;
## - rain rings: jittered drop rings, as many as the rain is hard, and
##   hard rain raises the sea and breaks it into whitecaps.
## Opaque on every tier (SSR still refines the probe reflection on
## Forward+), so the shoreline softness comes from colour and foam.
##
## Vertex data: COLOR.r openness (0 at the rim → 1 OPEN_RAMP_M out),
## COLOR.g 1 on sea surfaces (swell, surf), COLOR.b shore distance /
## SHORE_M (0..1), UV2 the flow direction × speed (m/s) on rivers.
## Shared with FarSurface so the near and far water filter at the same
## screen footprint, including grazing views where distance is insufficient.
const FILTER_GLSL := """
float water_wave_weight(float pixel_m, float scale_m) {
	// Fade from eight to two pixels per feature, before it aliases.
	return 1.0 - smoothstep(0.125, 0.5, pixel_m / scale_m);
}

float water_roughness(float rough, vec3 normal_world) {
	// Broaden glints where neighbouring pixels have different normals.
	vec3 dx = dFdx(normal_world);
	vec3 dy = dFdy(normal_world);
	float variance = max(dot(dx, dx), dot(dy, dy));
	return sqrt(clamp(rough * rough + variance, 0.0, 1.0));
}
"""

## Wind direction for waves, whitecaps and the rain that leans with it:
## water_surface.gd feeds it to the `wind` uniform, Precipitation reads it.
const WIND := Vector2(0.86, 0.51)

const CODE := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;
""" + FILTER_GLSL + """

uniform vec4 deep_color : source_color = vec4(0.150, 0.262, 0.250, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.235, 0.300, 0.250, 1.0);
uniform vec4 foam_color : source_color = vec4(0.86, 0.88, 0.88, 1.0);
uniform float units_per_metre = 1.0;
uniform float wave_amp = 1.0;
uniform float swell_lift = 1.3;
uniform float near_rough = 0.05;
uniform float far_rough = 0.09;
uniform float spec = 0.34;
uniform vec2 wind = vec2(0.86, 0.51);
uniform int water_quality = 2;
uniform float shore_m = 40.0;
uniform float brackish = 0.0;
uniform float temperate_sea = 0.0;
// Linear RGB absorption values selected per water region.
uniform vec3 sea_shallow = vec3(0.020, 0.185, 0.190);
uniform vec3 sea_deep = vec3(0.004, 0.034, 0.088);
uniform float harbour = 0.0;

// @SNOW
varying vec3 wpos;
varying float openv;
varying float seav;
varying float shorev;
varying vec2 flowv;

float w_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float w_noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(w_hash(i), w_hash(i + vec2(1.0, 0.0)), u.x),
		mix(w_hash(i + vec2(0.0, 1.0)), w_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Value noise derivative (iq): returns d/dx, d/dy.
vec2 noise_grad(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec2 du = 6.0 * f * (1.0 - f);
	float a = w_hash(i);
	float b = w_hash(i + vec2(1.0, 0.0));
	float c = w_hash(i + vec2(0.0, 1.0));
	float d = w_hash(i + vec2(1.0, 1.0));
	return du * (vec2(b - a, c - a) + (a - b - c + d) * u.yx);
}

// Slope of one travelling sine wave (deep-water dispersion).
vec2 wave_slope(vec2 p, vec2 dir, float len, float steep, float t, float pixel_m) {
	float k = 6.2831853 / len;
	float ph = dot(dir, p) * k - t * sqrt(9.81 * k);
	return dir * (steep * cos(ph)) * water_wave_weight(pixel_m, len);
}

// Gerstner swell: (dx, dy, dz) displacement in metres.
vec3 gerstner(vec2 p, vec2 dir, float len, float amp, float t) {
	float k = 6.2831853 / len;
	float ph = dot(dir, p) * k - t * sqrt(9.81 * k);
	return vec3(dir.x * amp * 0.6 * cos(ph), amp * sin(ph), dir.y * amp * 0.6 * cos(ph));
}

// Fast ice holds near banks and in shallow sheltered bays. Openness is
// the bathymetry proxy where the source DEM has no seabed soundings.
float local_ice(float sea, float shore_distance, float openness) {
	float fast = (1.0 - smoothstep(5.0, 35.0, shore_distance))
		* (1.0 - smoothstep(0.12, 0.7, openness));
	return climate_water_ice * mix(1.0, fast, sea);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	openv = COLOR.r;
	seav = COLOR.g;
	shorev = COLOR.b;
	flowv = UV2;
	if (water_quality >= 2 && seav > 0.5) {
		vec2 pm = wpos.xz / units_per_metre;
		vec2 wd = normalize(wind);
		float damp = smoothstep(0.0, 0.6, shorev) * (1.0 - local_ice(seav, shorev * shore_m, openv));
		// Wavelengths of at least ~6 grid cells (the sea grid is 12.5 m):
		// shorter swell aliased into rows of dashes toward the horizon.
		vec3 d = gerstner(pm, wd, 118.0, 0.75, TIME)
			+ gerstner(pm, normalize(wd + vec2(0.4, -0.3)), 74.0, 0.38, TIME * 1.1);
		float storm = 1.0 + 0.4 * climate_rain;
		d *= storm;
		// Legacy sea grids have no carved bed: lift their troughs above
		// the DEM. Shoreline meshes have a bed and use zero mean swell.
		d.y += swell_lift * storm;
		VERTEX += d * damp * units_per_metre * mix(1.0, 0.2, max(brackish, harbour));
	}
}

void fragment() {
	vec2 pm = wpos.xz / units_per_metre;
	float pixel_m = max(length(dFdx(pm)), length(dFdy(pm)));
	float dist_m = length(wpos - CAMERA_POSITION_WORLD) / units_per_metre;
	float t = TIME;
	vec2 wd = normalize(wind);
	// Rivers: the surface pattern rides the current downstream.
	vec2 adv = flowv * t;
	vec2 pf = pm - adv;
	vec2 chop = vec2(0.0);
	// Low sine steepness: alone they band into visible stripes; the
	// value-noise octaves break them into irregular chop.
	chop += wave_slope(pf, normalize(vec2(0.86, 0.51)), 3.7, 0.032, t, pixel_m);
	chop += wave_slope(pf, normalize(vec2(-0.42, 0.91)), 2.3, 0.026, t, pixel_m);
	chop += wave_slope(pf, normalize(vec2(0.97, -0.24)), 1.3, 0.020, t, pixel_m);
	chop += wave_slope(pf, normalize(vec2(-0.71, -0.70)), 0.8, 0.016, t, pixel_m);
	chop += noise_grad(pf * 0.55 + wd * t * 0.18) * 0.070 * water_wave_weight(pixel_m, 1.0 / 0.55);
	chop += noise_grad(pf * 1.9 - wd.yx * t * 0.29) * 0.040 * water_wave_weight(pixel_m, 1.0 / 1.9);
	// Metre chop fades with distance (it would shimmer); wind waves and
	// swell keep the far surface broken into reflection streaks.
	vec2 s = chop / (1.0 + dist_m / 70.0);
	vec2 wv = noise_grad(pf / 9.0 + wd * t * 0.06) * 0.11 * water_wave_weight(pixel_m, 9.0)
		+ noise_grad(pf / 4.3 - wd * t * 0.09) * 0.06 * water_wave_weight(pixel_m, 4.3);
	s += wv * (0.45 + 0.55 * smoothstep(40.0, 400.0, dist_m));
	if (seav > 0.5) {
		s += wave_slope(pm, wd, 46.0, 0.048, t, pixel_m) + wave_slope(pm, normalize(wd + vec2(0.4, -0.3)), 27.0, 0.042, t * 1.1, pixel_m);
	}
	// Live rain: drop rings near by. Wind comes with it, so it also
	// raises the whole wave field.
	if (climate_rain > 0.0) {
		// Near rings, wider ones that survive a coarser pixel, and past
		// both a fine stipple, so drizzle still marks the water from a quay.
		s += (rain_ripples(pm, t, pixel_m) + rain_ripples(pm * 0.3, t * 0.8, pixel_m * 0.3) * 0.5) * 0.16;
		s += noise_grad(pm * 2.2 + vec2(t * 1.1, -t * 0.8)) * 0.045 * sqrt(climate_rain) * water_wave_weight(pixel_m, 0.45);
	}
	s *= 1.0 + 0.5 * climate_rain;
	s *= wave_amp * mix(1.0, 0.55, brackish);
	// Frozen water: still, matte, white-grey ice (ClimateModel).
	float ice_cover = local_ice(seav, shorev * shore_m, openv);
	s *= 1.0 - ice_cover;
	vec3 n_world = normalize(vec3(-s.x, 1.0, -s.y));
	// Always the upward normal: water is only ever seen from above,
	// and its triangles wind either way (cull_disabled).
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	float open_w = smoothstep(0.0, 1.0, clamp(openv, 0.0, 1.0));
	vec3 deep_c = deep_color.rgb;
	vec3 shallow_c = shallow_color.rgb;
	if (seav > 0.5) {
		// The place supplies the sea body's absorption colour in linear RGB.
		deep_c = sea_deep;
		shallow_c = sea_shallow;
	}
	vec3 col = mix(shallow_c, deep_c, open_w);
	// Shore foam: a broken, breathing band along the rim; surf on the sea.
	float shore = clamp(shorev, 0.0, 1.0) * shore_m;
	float surf = seav > 0.5 ? mix(1.0, 0.12, harbour) : 0.35;
	float band = (1.0 - smoothstep(0.0, mix(2.5, 9.0, surf), shore));
	float pulse = 0.5 + 0.5 * sin(t * 0.8 - shore * 0.35 + w_noise(pm * 0.05) * 6.0);
	float brk = smoothstep(0.45, 0.85, w_noise(pf * 0.9 + vec2(t * 0.15, 0.0)) * 0.6
		+ w_noise(pf * 3.1 - t * 0.2) * 0.4);
	// Foam is lace, not blobs: thin connected filaments on warped noise.
	float lace = 0.0;
	if (band > 0.0 || climate_rain > 0.3) {
		vec2 warp = vec2(w_noise(pf * 0.7 + t * 0.05), w_noise(pf * 0.7 + 9.1 - t * 0.04)) * 1.2;
		lace = smoothstep(0.62, 0.92, 1.0 - abs(2.0 * w_noise((pf + warp) * 2.6) - 1.0));
	}
	float foam = band * mix(0.55, 1.0, pulse) * mix(brk, brk * lace, 0.65) * surf;
	// Current streaks: foam lines drawn out along the flow near banks.
	float fl = length(flowv);
	if (fl > 0.01) {
		vec2 fd = flowv / fl;
		vec2 q = vec2(dot(pf, fd) * 0.08, dot(pf, vec2(-fd.y, fd.x)) * 0.9);
		foam += smoothstep(0.72, 0.9, w_noise(q)) * (1.0 - open_w * 0.7) * 0.5 * min(fl, 1.0);
	}
	foam *= (1.0 - ice_cover) * (1.0 - smoothstep(300.0, 1200.0, dist_m)) * water_wave_weight(pixel_m, 1.0 / 3.1);
	// Whitecaps: rain's wind breaks the crests of open water, drawn out
	// downwind. Metres wide, so they outlast the fine foam with distance.
	if (climate_rain > 0.3 && open_w > 0.05) {
		vec2 cq = vec2(dot(pf, wd) * 0.05, dot(pf, wd.yx * vec2(-1.0, 1.0)) * 0.13) + wd * t * 0.05;
		float crest = w_noise(cq) * 0.7 + w_noise(cq * 2.7 + t * 0.07) * 0.3;
		float caps = smoothstep(0.76 - 0.1 * climate_rain, 0.86, crest)
			* mix(0.5, 1.0, lace) * smoothstep(0.3, 0.8, climate_rain) * open_w;
		foam += caps * (1.0 - ice_cover) * water_wave_weight(pixel_m, 2.0) * mix(0.5, 1.0, seav);
	}
	foam = clamp(foam, 0.0, 1.0);
	// Light through the thin tops of the waves: a faint green on slopes.
	col += vec3(0.010, 0.034, 0.028) * smoothstep(0.02, 0.14, length(s)) * (1.0 - ice_cover);
	col = mix(col, foam_color.rgb, foam);
	vec3 ice = mix(vec3(0.70, 0.76, 0.80), vec3(0.86, 0.89, 0.92), snow_line(wpos));
	ALBEDO = mix(col, ice, ice_cover);
	float rough = mix(near_rough, far_rough, smoothstep(60.0, 1500.0, dist_m));
	rough = mix(rough, 0.45, foam);
	rough = mix(rough, 0.12, sqrt(climate_rain) * (1.0 - smoothstep(150.0, 900.0, dist_m)));
	ROUGHNESS = water_roughness(mix(rough, 0.55, ice_cover), n_world);
	SPECULAR = mix(mix(spec, 0.2, foam), 0.25, ice_cover);
	METALLIC = 0.0;
}
"""
