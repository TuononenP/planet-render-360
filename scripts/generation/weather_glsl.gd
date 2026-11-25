class_name WeatherGlsl
extends RefCounted

## Shared weather-dressing GLSL snippets spliced into built shaders:
##   - "// @FROST"  -> FROST_GLSL (window rime / hoarfrost crystals)
##   - "// @AUTUMN" -> AUTUMN_GLSL (continuous foliage & hillside autumn shift)
## Kept in its own class so FacadeShader, TreeMeshLibrary, FarSurface and
## ClimateModel stay compact and well under the 1000-line class limit.

## Window frost / rime crystals (FacadeShader). Expects snow_hash / snow_noise
## (from ClimateModel.SNOW_GLSL) and cloud_sun_dir (from TerrainGlsl).
## Returns vec4(cover, normal_x, normal_y, crystal_glint).
## Every high-frequency crystal octave settles to its mean via `pane_px`
## before it can alias on distant facades.
const FROST_GLSL := """
global uniform float climate_frost;

float frost_ridge(vec2 p) {
	float n = snow_noise(p);
	return 1.0 - abs(n * 2.0 - 1.0);
}

vec4 window_frost(vec2 cuv, float pane_px, float seed, float lit, bool curtain, vec3 wall_n) {
	if (climate_frost <= 0.005) { return vec4(0.0); }
	float f = climate_frost;
	// Modern triple-glazed curtain walls frost less; warmly lit rooms thaw a
	// clear oval at the pane centre; sunlit faces ease frost gently.
	f *= curtain ? 0.45 : 1.0;
	f *= mix(1.0, 0.65, clamp(lit, 0.0, 1.0));
	float sun_face = smoothstep(0.20, 0.65, dot(normalize(wall_n), cloud_sun_dir)) * smoothstep(0.12, 0.35, cloud_sun_dir.y);
	f *= 1.0 - 0.32 * sun_face;
	if (f <= 0.005) { return vec4(0.0); }
	// Cold perimeter & bottom-sill condensation gradient (0 at edge .. 1 centre).
	vec2 ed = min(cuv, 1.0 - cuv);
	float edge_d = min(ed.x, ed.y);
	// Bottom corners (cuv.y near 1) pool condensation and freeze further inward.
	float corner = length(ed) * 0.85;
	float rim = mix(edge_d, corner, 0.45) - 0.06 * smoothstep(0.55, 1.0, cuv.y);
	// Domain-warped dendritic / fern-like crystal fronts, anti-aliased by pane_px.
	float near_c = 1.0 - smoothstep(0.015, 0.065, pane_px);
	vec2 q = cuv * vec2(7.5, 9.5) + vec2(seed * 19.3, seed * 7.1);
	vec2 warp = vec2(snow_noise(q * 0.7 + 3.1), snow_noise(q * 0.7 + 11.7)) - 0.5;
	float dend = frost_ridge(q + warp * 1.4) * 0.65 + frost_ridge(q * 2.4 - warp * 0.9) * 0.35;
	float pat = mix(0.55, dend, near_c);
	// Reach inward grows smoothly from 6% of pane at light frost to ~46% at heavy frost.
	float reach = mix(0.05, 0.44, f) * (0.65 + 0.70 * pat);
	float cover = (1.0 - smoothstep(reach - 0.09, reach + 0.04, rim)) * smoothstep(0.0, 0.25, f);
	// Micro-crystal facet normal & ice sparkle up close only.
	float fine_c = 1.0 - smoothstep(0.006, 0.025, pane_px);
	vec2 fq = cuv * 28.0 + vec2(seed * 31.7, seed * 13.3);
	float fx = snow_noise(fq + vec2(0.4, 0.0)) - snow_noise(fq - vec2(0.4, 0.0));
	float fy = snow_noise(fq + vec2(0.0, 0.4)) - snow_noise(fq - vec2(0.0, 0.4));
	float glint = smoothstep(0.84, 0.97, frost_ridge(fq * 1.3)) * fine_c * cover;
	return vec4(clamp(cover, 0.0, 1.0), fx * fine_c * cover, fy * fine_c * cover, glint);
}
"""

## Continuous autumn foliage color shift (TreeMeshLibrary + FarSurface).
## Expects snow_hash (ClimateModel.SNOW_GLSL) and world_origin_m (where used).
const AUTUMN_GLSL := """
global uniform float climate_autumn;
global uniform float climate_autumn_lapse;

float autumn_at_y(float wy) {
	if (climate_autumn <= 0.005) { return 0.0; }
	return clamp(climate_autumn + max(wy, 0.0) * climate_autumn_lapse, 0.0, 1.0);
}

// Shifts deciduous tree tint smoothly across green -> early gold -> peak
// autumn_tint/crimson -> late russet, with per-tree jitter and sunlit-crown
// lead. `meta`: x = deciduous (0/1), y = species onset (-0.15..+0.15),
// z = crimson accent weight (0..1).
vec3 autumn_tree_tint(vec3 summer_c, vec3 autumn_c, vec3 meta, vec2 tree_xz, float wy, float sun_up) {
	if (climate_autumn <= 0.005 || meta.x <= 0.01) { return summer_c; }
	float h = snow_hash(floor(tree_xz * 0.5));
	float h2 = snow_hash(floor(tree_xz * 0.5) + vec2(17.3, 9.1));
	float prog = autumn_at_y(wy) + meta.y + (h - 0.5) * 0.30 + clamp(sun_up, 0.0, 1.0) * 0.08;
	prog = clamp(prog, 0.0, 1.0);
	vec3 early_gold = mix(summer_c, vec3(0.76, 0.68, 0.24), 0.72);
	vec3 crimson = vec3(0.74, 0.24, 0.14);
	vec3 peak_c = mix(autumn_c, crimson, meta.z * (0.45 + 0.55 * h2));
	vec3 late_russet = vec3(0.46, 0.27, 0.14) * (0.88 + 0.24 * h2);
	vec3 out_c = mix(summer_c, early_gold, smoothstep(0.05, 0.38, prog));
	out_c = mix(out_c, peak_c, smoothstep(0.32, 0.72, prog));
	out_c = mix(out_c, late_russet, smoothstep(0.76, 1.0, prog));
	return mix(summer_c, out_c, meta.x);
}

// Shifts distant summer-satellite forested slopes (FarSurface) toward mottled
// autumn stands, preserving luminance so hillsides keep their relief.
vec3 autumn_far_forest(vec3 c, float wy, float stands, float crowns, float deciduous_share) {
	if (climate_autumn <= 0.005 || deciduous_share <= 0.01) { return c; }
	float prog = autumn_at_y(wy);
	float dec = smoothstep(1.0 - deciduous_share, min(1.0 - deciduous_share + 0.35, 1.02), stands * 0.75 + crowns * 0.25);
	float w = dec * smoothstep(0.05, 0.70, prog);
	if (w <= 0.005) { return c; }
	float lum_c = max(dot(c, vec3(0.2126, 0.7152, 0.0722)), 0.005);
	vec3 gold = vec3(0.68, 0.48, 0.16);
	vec3 russet = vec3(0.54, 0.26, 0.12);
	vec3 target = mix(gold, russet, clamp(smoothstep(0.35, 0.85, crowns) * 0.7 + smoothstep(0.65, 1.0, prog) * 0.4, 0.0, 1.0));
	float lum_t = max(dot(target, vec3(0.2126, 0.7152, 0.0722)), 0.005);
	vec3 matched = target * (lum_c / lum_t) * mix(1.0, 1.18, smoothstep(0.2, 0.7, prog));
	return mix(c, matched, w * 0.85);
}
"""
