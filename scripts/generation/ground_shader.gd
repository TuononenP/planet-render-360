class_name GroundShader
extends RefCounted

## GroundMaterial's spatial shader (split out of ground_material.gd to
## keep that class under the size limit). "// @SNOW" is replaced with
## ClimateModel.SNOW_GLSL at build time.
const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D photo : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D class_map : filter_nearest, repeat_disable;
uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D d0 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d1 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d2 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d3 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n0 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n1 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n2 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n3 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 m0 = vec3(0.2);
uniform vec3 m1 = vec3(0.2);
uniform vec3 m2 = vec3(0.2);
uniform vec3 m3 = vec3(0.2);
uniform float class_n = 1024.0;
uniform int max_id = 16;
uniform float extent_u = 220.0;
uniform float u2m = 1.0;
uniform float tile_m = 3.0;
uniform float near_m = 140.0;
uniform float far_m = 900.0;
uniform float photo_gain = 1.0;
uniform float lf_lod = 0.0;
uniform float lum_floor = 0.055;
uniform float urban_unknown = 1.0;
uniform float unknown_trust = 0.3;
uniform vec3 unknown_bare : source_color = vec3(0.54, 0.51, 0.45);
uniform vec3 unknown_veg : source_color = vec3(0.35, 0.48, 0.24);

// @SNOW
varying vec3 wpos;
varying float wny;

void vertex() {
	wpos = VERTEX;
	wny = NORMAL.y;
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

vec3 tile(sampler2D t, vec2 a, vec2 b) {
	return 0.5 * (texture(t, a).rgb + texture(t, b).rgb);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

// PAVING (T4.7): achromatic value gain for laid urban ground at metre
// coords g. ±8% patches over 6–25 m (wear, cleaning, repairs) plus
// 2 x 1.4 m running-bond flagstones with ±4% per-slab value and 3 cm
// darker joints; the slab layer fades with its screen footprint so it
// never aliases. Multiplies value only, so hue is preset-stable.
float paving(vec2 g) {
	float big = (vnoise(g / 23.0) - 0.5) * 0.11 + (vnoise(g / 6.5 + 17.0) - 0.5) * 0.06;
	vec2 slab = vec2(2.0, 1.4);
	vec2 su = g / slab;
	su.x += 0.5 * mod(floor(su.y), 2.0);
	vec2 fw = fwidth(g) / slab;
	float vis = 1.0 - smoothstep(0.08, 0.35, max(fw.x, fw.y));
	float jit = (hash2(floor(su) + 3.1) - 0.5) * 0.08;
	vec2 e = min(fract(su), 1.0 - fract(su)) * slab;
	vec2 fm = max(fwidth(g), vec2(1e-4));
	vec2 jl = smoothstep(vec2(0.015), vec2(0.015) + fm, e);
	float joint = -0.10 * (1.0 - min(jl.x, jl.y));
	return 1.0 + big + vis * (jit + joint);
}

void fragment() {
	float dist_m = length(VERTEX) * u2m;
	vec3 lf = textureLod(photo, UV, lf_lod).rgb * photo_gain;
	vec3 hf = texture(photo, UV).rgb * photo_gain;
	float exg = (2.0 * lf.g - lf.r - lf.b) / max(lf.r + lf.g + lf.b, 1e-3);
	float veg = smoothstep(0.03, 0.12, exg);
	// Manual bilinear over class ids (ids never filter).
	vec2 cuv = (wpos.xz / extent_u + 0.5) * class_n - 0.5;
	vec2 f = fract(cuv);
	ivec2 c0 = ivec2(floor(cuv));
	ivec2 cmax = ivec2(int(class_n) - 1);
	vec4 W = vec4(0.0);
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
			W += bw * vec4((1.0 - veg) * urban_unknown, veg,
				(1.0 - veg) * (1.0 - urban_unknown), 0.0);
			col += bw * mix(unknown_bare, unknown_veg, veg);
			trust += bw * unknown_trust;
			farc += bw;
			rough += bw * 0.96;
			hfk += bw * 0.35;
			pave += bw * (1.0 - veg) * urban_unknown * 0.7;
		} else {
			W += bw * texelFetch(palette, ivec2(id, 0), 0);
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
	// Steep ground is bare rock/earth whatever the cover says.
	float steep = smoothstep(0.82, 0.62, wny);
	W = mix(W, vec4(0.0, 0.0, 1.0, 0.0), steep * 0.8);
	W /= max(W.x + W.y + W.z + W.w, 1e-3);
	// Macro variation (~40 m patches) from the photo's own value, so
	// wide pavement and lawns are never a flat slab.
	float big = lum(textureLod(photo, UV, lf_lod + 3.0).rgb * photo_gain);
	float macro = clamp(lum(lf) / max(big, 1e-3), 0.72, 1.3);
	vec3 base = value_clamp(mix(col, lf, trust) * mix(1.0, macro, 0.8));
	// Tiled PBR detail, normalised by each set's mean so the class
	// colour sets the value and the texture only adds structure.
	vec2 g = wpos.xz * u2m;
	vec2 ua = g / tile_m;
	vec2 ub = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * g / (tile_m * 3.7) + 0.37;
	vec3 det = W.x * tile(d0, ua, ub) / m0
		+ W.y * tile(d1, ua, ub) / m1
		+ W.z * tile(d2, ua, ub) / m2
		+ W.w * tile(d3, ua, ub) / m3;
	det = clamp(det, vec3(0.3), vec3(2.0));
	float ratio = clamp(lum(hf) / max(lum(lf), 1e-3), 0.55, 1.45);
	// Photo fine structure only where a photo pixel is no bigger
	// than a few screen pixels; close up it is blur, so PBR carries.
	float hf_on = smoothstep(60.0, 260.0, dist_m);
	vec3 near_c = base * det * mix(1.0, ratio, hfk * hf_on);
	near_c *= mix(1.0, paving(g), pave * (1.0 - steep));
	float wf = smoothstep(near_m, far_m, dist_m) * farc;
	vec3 alb = mix(near_c, mix(base, hf, 0.6), wf);
	alb *= COLOR.a;
	// Edge band: hand off to the far terrain's rendered albedo
	// (COLOR.rgb = FarTerrainBuilder.far_albedo_at: drape or ramp).
	float half_e = extent_u * 0.5;
	float cheb = max(abs(wpos.x), abs(wpos.z));
	float edge = smoothstep(half_e * 0.90, half_e * 0.985, cheb);
	alb = mix(alb, COLOR.rgb, edge);
	// Seasonal climate snow over the (summer) imagery, after the edge
	// hand-off so near and far carry the same line (ClimateModel).
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
	float sc = snow_cover(wpos, wny);
	alb = mix(alb, snow_col, sc);
	// Live rain: wet ground darkens and turns glossy (not under snow).
	float wet = climate_wetness * (1.0 - sc);
	alb *= mix(1.0, 0.72, wet);
	ALBEDO = value_clamp(alb);
	vec3 nm = W.x * tile(n0, ua, ub) + W.y * tile(n1, ua, ub)
		+ W.z * tile(n2, ua, ub) + W.w * tile(n3, ua, ub);
	NORMAL_MAP = mix(nm, vec3(0.5, 0.5, 1.0), max(wf, edge));
	NORMAL_MAP_DEPTH = 0.8;
	AO = contact;
	AO_LIGHT_AFFECT = 0.2;
	ROUGHNESS = mix(rough, 0.22, wet * 0.85);
	SPECULAR = mix(0.35, 0.5, wet);
}
"""
