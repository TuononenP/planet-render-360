class_name GroundShader
extends RefCounted

## GroundMaterial's spatial shader (split out of ground_material.gd to
## keep that class under the size limit). "// @SNOW" is replaced with
## ClimateModel.SNOW_GLSL and "// @TERRAIN" with TerrainGlsl.CODE at
## build time.
##
## Per pixel: land-cover classes pick up to eight photographic layers
## (TerrainTextures) by palette weight, sampled without visible
## repetition; steep ground turns to cliff rock (biplanar, so faces do
## not streak) with strata and scree, and its lighting gets crag relief
## from noise gradients; snow takes its own texture and sheds off
## cliffs. `ground_quality` (0 Fast … 3 Ultra) trims the cost on phones:
## no offset variation, no biplanar cliffs, fewer relief octaves.
const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D photo : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D class_map : filter_nearest, repeat_disable;
uniform sampler2D palette : filter_nearest, repeat_disable;
uniform float class_n = 1024.0;
uniform int max_id = 16;
uniform float extent_u = 220.0;
uniform float u2m = 1.0;
uniform float near_m = 140.0;
uniform float far_m = 900.0;
uniform float photo_gain = 1.0;
uniform float lf_lod = 0.0;
uniform float lum_floor = 0.055;
uniform float urban_unknown = 1.0;
uniform float unknown_trust = 0.3;
uniform vec3 unknown_bare : source_color = vec3(0.54, 0.51, 0.45);
uniform vec3 unknown_veg : source_color = vec3(0.35, 0.48, 0.24);
uniform int ground_quality = 2;

// @SNOW
// @TERRAIN
varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = VERTEX;
	wnrm = NORMAL;
	TANGENT = normalize(vec3(1.0, 0.0, 0.0) - NORMAL * NORMAL.x);
	BINORMAL = normalize(cross(TANGENT, NORMAL));
}

float lum(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Luminance into [lum_floor, 0.85] without changing chromaticity.
vec3 value_clamp(vec3 c) {
	float l = max(lum(c), 1e-4);
	float t = clamp(l, lum_floor, 0.85);
	return min(c * (t / l), vec3(1.0));
}

vec3 srgb_lin(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// PAVING (T4.7): achromatic value gain for laid urban ground at metre
// coords g. ±8% patches over 6–25 m (wear, cleaning, repairs) plus
// 2 x 1.4 m running-bond flagstones with ±4% per-slab value and 3 cm
// darker joints; the slab layer fades with its screen footprint so it
// never aliases. Multiplies value only, so hue is preset-stable.
float paving(vec2 g) {
	float big = (t_noise(g / 23.0) - 0.5) * 0.11 + (t_noise(g / 6.5 + 17.0) - 0.5) * 0.06;
	vec2 slab = vec2(2.0, 1.4);
	vec2 su = g / slab;
	su.x += 0.5 * mod(floor(su.y), 2.0);
	vec2 fw = fwidth(g) / slab;
	float vis = 1.0 - smoothstep(0.08, 0.35, max(fw.x, fw.y));
	float jit = (t_hash(floor(su) + 3.1) - 0.5) * 0.08;
	vec2 e = min(fract(su), 1.0 - fract(su)) * slab;
	vec2 fm = max(fwidth(g), vec2(1e-4));
	vec2 jl = smoothstep(vec2(0.015), vec2(0.015) + fm, e);
	float joint = -0.10 * (1.0 - min(jl.x, jl.y));
	return 1.0 + big + vis * (jit + joint);
}

void fragment() {
	float dist_m = length(VERTEX) * u2m;
	vec3 lf = t_dehaze(textureLod(photo, UV, lf_lod).rgb * photo_gain);
	vec3 hf = t_dehaze(texture(photo, UV).rgb * photo_gain);
	float exg = (2.0 * lf.g - lf.r - lf.b) / max(lf.r + lf.g + lf.b, 1e-3);
	float veg = smoothstep(0.03, 0.12, exg);
	vec2 g = wpos.xz * u2m;
	vec3 pm = wpos * u2m;
	// Screen gradients, taken before any branch (layer fetches use them).
	vec4 dg = vec4(dFdx(g), dFdy(g));
	vec3 dpx = dFdx(pm);
	vec3 dpy = dFdy(pm);
	// Manual bilinear over class ids (ids never filter).
	vec2 cuv = (wpos.xz / extent_u + 0.5) * class_n - 0.5;
	vec2 f = fract(cuv);
	ivec2 c0 = ivec2(floor(cuv));
	ivec2 cmax = ivec2(int(class_n) - 1);
	vec4 W0 = vec4(0.0);
	vec4 W1 = vec4(0.0);
	vec3 col = vec3(0.0);
	float trust = 0.0;
	float farc = 0.0;
	float rough = 0.0;
	float hfk = 0.0;
	float pave = 0.0;
	for (int k = 0; k < 4; k++) {
		ivec2 o = ivec2(k & 1, k >> 1);
		float bw = (o.x == 1 ? f.x : 1.0 - f.x) * (o.y == 1 ? f.y : 1.0 - f.y);
		int id = int(texelFetch(class_map, clamp(c0 + o, ivec2(0), cmax), 0).r * 255.0 + 0.5);
		// Ids past the palette (an unbound/white class map reads 255)
		// fall back to unmapped ground; texelFetch past the 32-texel
		// palette is undefined (Metal returned the red fill).
		if (id == 0 || id > max_id) {
			float wild = (1.0 - veg) * (1.0 - urban_unknown);
			W0 += bw * vec4((1.0 - veg) * urban_unknown, veg * 0.7, wild * 0.5, 0.0);
			W1 += bw * vec4(0.0, veg * 0.3, wild * 0.5, 0.0);
			col += bw * mix(unknown_bare, unknown_veg, veg);
			trust += bw * unknown_trust;
			farc += bw;
			rough += bw * 0.96;
			hfk += bw * 0.35;
			pave += bw * (1.0 - veg) * urban_unknown * 0.7;
		} else {
			W0 += bw * texelFetch(palette, ivec2(id, 0), 0);
			W1 += bw * texelFetch(palette, ivec2(id, 3), 0);
			vec4 p1 = texelFetch(palette, ivec2(id, 1), 0);
			vec4 p2 = texelFetch(palette, ivec2(id, 2), 0);
			col += bw * srgb_lin(p1.rgb);
			trust += bw * p1.a;
			farc += bw * p2.r;
			rough += bw * p2.g;
			hfk += bw * p2.b;
			pave += bw * p2.a;
		}
	}
	// Crag relief: noise gradients bend the lighting normal on steep and
	// rocky ground, so DEM slabs read as ribbed rock faces.
	vec3 nw = normalize(wnrm);
	float steep0 = smoothstep(0.86, 0.6, nw.y);
	// Forested and grassy slopes keep their own shading: only bare ground
	// takes the rock relief (it frosted wooded mountainsides).
	float rocky = clamp(steep0 + W0.z + W1.x * 0.8 + W1.z * 0.4, 0.0, 1.0) * (1.0 - 0.8 * veg);
	float relief_fade = 1.0 - smoothstep(600.0, 2400.0, dist_m);
	if (rocky * relief_fade > 0.01) {
		vec2 gr = t_relief(g, 26.0, ground_quality >= 2 ? 4 : 2);
		nw = normalize(nw - vec3(gr.x, 0.0, gr.y) * 9.0 * rocky * relief_fade);
	}
	// Very steep ground (past ~45°) is cliff rock and scree whatever the
	// cover says; grass and scrub hold on gentler slopes.
	float steep = smoothstep(0.76, 0.52, nw.y) * (1.0 - 0.7 * veg);
	W0 *= 1.0 - steep * 0.9;
	W1 = W1 * (1.0 - steep * 0.9) + vec4(0.75, 0.0, 0.25, 0.0) * steep * 0.9;
	float wsum = W0.x + W0.y + W0.z + W0.w + W1.x + W1.y + W1.z + W1.w;
	W0 /= max(wsum, 1e-3);
	W1 /= max(wsum, 1e-3);
	// Macro variation (~40 m patches) from the photo's own value, so
	// wide pavement and lawns are never a flat slab; plus noise-driven
	// patches the photo cannot carry at grazing angles.
	float big = lum(t_dehaze(textureLod(photo, UV, lf_lod + 3.0).rgb * photo_gain));
	float macro = clamp(lum(lf) / max(big, 1e-3), 0.72, 1.3);
	macro *= 0.92 + 0.16 * t_noise(g / 47.0);
	vec3 base = mix(col, lf, trust);
	// Rock colour: neutral stone carrying some of the photo's tint.
	float l_lf = max(lum(lf), 1e-3);
	vec3 rock_c = mix(vec3(0.34, 0.32, 0.29), lf * (0.33 / l_lf), 0.5);
	base = mix(base, rock_c, steep * 0.85);
	base = value_clamp(base * mix(1.0, macro, 0.8));
	// Meadows are never one green: broad patches of lush, deep and
	// sun-dried grass, and finer mottling near the eye. Multiplies the
	// class colour only where lawn / forest-floor weight sits.
	float meadow = clamp(W0.y + W1.y * 0.5, 0.0, 1.0) * (1.0 - steep);
	if (meadow > 0.01) {
		float m_big = t_noise(g / 71.0) * 0.6 + t_noise(g / 23.0 + 5.3) * 0.4;
		float m_fine = t_noise(g / 5.1 + 11.0) * 0.6 + t_noise(g / 1.7 + 3.0) * 0.4;
		vec3 lush = vec3(0.50, 0.64, 0.36);
		vec3 dried = vec3(0.78, 0.68, 0.34);
		vec3 tone = mix(lush, dried, smoothstep(0.32, 0.72, m_big));
		tone *= 0.88 + 0.24 * mix(0.5, m_fine, 1.0 - smoothstep(120.0, 600.0, dist_m));
		base *= mix(vec3(1.0), tone, meadow * 0.85);
	}
	// Photographic layers by weight, each normalised by its mean so the
	// class colour sets the value and the texture only adds structure.
	float w[8] = float[8](W0.x, W0.y, W0.z, W0.w, W1.x, W1.y, W1.z, W1.w);
	bool vary = ground_quality >= 1;
	vec3 det = vec3(0.0);
	vec4 nm = vec4(0.0);
	float wt = 0.0;
	for (int i = 0; i < 8; i++) {
		if (w[i] < 0.02) {
			continue;
		}
		vec4 a;
		vec4 n;
		if (i == 4 && ground_quality >= 2 && steep > 0.05) {
			det_side(4, pm, dpx, dpy, nw, a, n);
		} else {
			det_sample(i, g, dg, vary, a, n);
		}
		det += w[i] * a.rgb / det_mean[i];
		nm += w[i] * n;
		wt += w[i];
	}
	det = clamp(det / max(wt, 1e-3), vec3(0.3), vec3(2.0));
	nm /= max(wt, 1e-3);
	// Strata on cliffs: bands of stone by height, wobbling along the face.
	float strata = t_noise(vec2(pm.y / 2.3 + t_noise(g / 60.0) * 3.0, 0.5));
	det *= 1.0 + (strata - 0.5) * 0.3 * steep;
	float ratio = clamp(lum(hf) / max(lum(lf), 1e-3), 0.55, 1.45);
	// Photo fine structure only where a photo pixel is no bigger
	// than a few screen pixels; close up it is blur, so PBR carries.
	float hf_on = smoothstep(60.0, 260.0, dist_m);
	vec3 near_c = base * det * mix(1.0, ratio, hfk * hf_on);
	near_c *= mix(1.0, paving(g), pave * (1.0 - steep));
	// Cliffs keep their rock detail further out than flat cover.
	float wf = smoothstep(near_m, far_m, dist_m) * farc * (1.0 - 0.6 * steep);
	vec3 alb = mix(near_c, mix(base, hf, 0.6), wf);
	alb *= COLOR.a;
	// Edge band: hand off to the far terrain's rendered albedo
	// (COLOR.rgb = FarTerrainBuilder.far_albedo_at: drape or ramp).
	float half_e = extent_u * 0.5;
	float cheb = max(abs(wpos.x), abs(wpos.z));
	float edge = smoothstep(half_e * 0.90, half_e * 0.985, cheb);
	alb = mix(alb, t_dehaze(COLOR.rgb), edge);
	// Contact shading: ground at a building's foot sees less sky.
	// Eight class-map taps 1–2 texels (2.3–4.7 m) out; fades with
	// distance like the near detail. Ambient mostly (AO), a little on
	// the sun term — the shadow map draws the rest.
	ivec2 cc = ivec2(floor(cuv + 0.5));
	float occ = 0.0;
	for (int k = 0; k < 8; k++) {
		float ang = float(k) * 0.7853982;
		float rad = (k % 2 == 0) ? 2.0 : 1.4;
		ivec2 o = ivec2(round(vec2(cos(ang), sin(ang)) * rad));
		int nid = int(texelFetch(class_map, clamp(cc + o, ivec2(0), cmax), 0).r * 255.0 + 0.5);
		occ += nid == 1 ? 1.0 : 0.0;
	}
	float contact = 1.0 - 0.45 * (occ / 8.0) * (1.0 - wf);
	// Bare ground is never brighter than light dry soil or old paving
	// (~0.38 albedo: the sunlit grade lifts it ~1.6x, so more reads as
	// white); only the snow layer below goes brighter, and high slopes
	// keep the imagery's own permanent snow and ice.
	float ground_max = mix(0.38, 0.85, smoothstep(350.0, 1000.0, pm.y));
	alb *= min(1.0, ground_max / max(lum(alb), 1e-4));
	// Seasonal climate snow over the (summer) imagery, after the edge
	// hand-off so near and far carry the same line (ClimateModel); it
	// slides off cliffs (relief normal) and takes its own texture.
	float sc = snow_cover(wpos, nw.y);
	vec4 sa = vec4(0.0);
	vec4 sn = vec4(0.5, 0.5, 1.0, 0.7);
	if (sc > 0.01) {
		det_sample(8, g, dg, vary, sa, sn);
		alb = mix(alb, snow_col * clamp(sa.rgb / det_mean[8], vec3(0.75), vec3(1.2)), sc);
	}
	// Live rain: wet ground darkens and turns glossy (not under snow).
	float wet = climate_wetness * (1.0 - sc);
	alb *= mix(1.0, 0.72, wet);
	ALBEDO = value_clamp(alb);
	// Lighting normal: relief-bent world normal into view space.
	vec3 tw = normalize(vec3(1.0, 0.0, 0.0) - nw * nw.x);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	TANGENT = normalize((VIEW_MATRIX * vec4(tw, 0.0)).xyz);
	BINORMAL = normalize((VIEW_MATRIX * vec4(cross(tw, nw), 0.0)).xyz);
	vec3 nmap = mix(nm.rgb, sn.rgb, sc);
	NORMAL_MAP = mix(nmap, vec3(0.5, 0.5, 1.0), max(wf, edge));
	NORMAL_MAP_DEPTH = 0.9;
	AO = contact;
	AO_LIGHT_AFFECT = 0.2;
	// The layers' own roughness maps carry gloss variation near by.
	float rmap = mix(nm.a, sn.a, sc);
	float r = mix(rough, clamp(rmap, 0.62, 1.0), 0.5 * (1.0 - wf));
	ROUGHNESS = mix(r, 0.22, wet * 0.85);
	SPECULAR = mix(0.28, 0.5, wet);
}
"""
