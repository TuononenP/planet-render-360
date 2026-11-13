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
// The fine class map around the viewpoint (GroundMaterial.near_class_map):
// near_rect = centre x, centre z, half side, hand-over band; near_n 0 = none.
uniform sampler2D near_class : filter_nearest, repeat_disable;
uniform float near_n = 0.0;
uniform vec4 near_rect = vec4(0.0);
uniform int max_id = 17;
uniform float extent_u = 220.0;
uniform float u2m = 1.0;
uniform float near_m = 140.0;
uniform float far_m = 900.0;
uniform float photo_gain = 1.0;
// Desktop Ultra's z18 inner mosaic: uv = UV * inner_map.xy +
// inner_map.zw (exact: a z18 pixel is the main zoom's pixel × 2^dz);
// inner_map.x 0 = none. Sharpens the photo's fine
// structure only (the low-frequency class signal stays the main photo's).
uniform sampler2D photo_inner : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 inner_map = vec4(0.0);
// A city orthophoto's colour matched to the main mosaic (linear).
uniform vec3 inner_gain = vec3(1.0);
uniform vec3 inner_bias = vec3(0.0);
uniform float lf_lod = 0.0;
// DemRelief: residual slopes of a 1 m elevation model (RG8, ±1) over
// relief_rect (centre xz, half xz, units); relief_rect.z 0 = none.
uniform sampler2D dem_relief : filter_linear, repeat_disable;
uniform vec4 relief_rect = vec4(0.0);
uniform float ground_max_low = 0.38;
uniform float lum_floor = 0.055;
uniform float urban_unknown = 1.0;
uniform float unknown_trust = 0.3;
uniform vec3 unknown_bare : source_color = vec3(0.54, 0.51, 0.45);
uniform vec3 unknown_veg : source_color = vec3(0.35, 0.48, 0.24);
// Excess-green window that reads as vegetation on unmapped ground. Dry
// ground (sand, dust) scores ~0.06 on a green index, so arid places raise
// it to keep desert from being painted as lawn (ground_material.gd).
uniform float veg_lo = 0.03;
uniform float veg_hi = 0.12;
uniform int ground_quality = 2;
// 1 = a finer sample of the main layer close to the eye (micro_detail).
uniform float micro_detail = 0.0;
// Mowing direction of this place's lawns (radians from +x): stripes run
// along it and alternate light and dark with the view.
uniform float stripe_angle = 0.6;

// @SNOW
// @TERRAIN
varying vec3 wpos;
varying vec3 wnrm;
varying float water_level;
varying float bank_paving;

void vertex() {
	wpos = VERTEX;
	wnrm = NORMAL;
	water_level = UV2.x;
	bank_paving = UV2.y;
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

// One class-map tap's share of the ground's material weights.
void class_tap(int id, float bw, float veg, inout vec4 W0, inout vec4 W1, inout vec3 col,
		inout float trust, inout float farc, inout float rough, inout float hfk, inout float pave) {
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
		vec4 p0 = texelFetch(palette, ivec2(id, 0), 0);
		vec4 p1 = texelFetch(palette, ivec2(id, 1), 0);
		vec4 p2 = texelFetch(palette, ivec2(id, 2), 0);
		vec4 p3 = texelFetch(palette, ivec2(id, 3), 0);
		W0 += bw * p0;
		W1 += bw * p3;
		col += bw * srgb_lin(p1.rgb);
		trust += bw * p1.a;
		farc += bw * p2.r;
		rough += bw * p2.g;
		hfk += bw * p2.b;
		pave += bw * p2.a;
	}
}

void fragment() {
	float dist_m = length(VERTEX) * u2m;
	vec3 lf = t_dehaze(textureLod(photo, UV, lf_lod).rgb * photo_gain);
	vec3 hf = t_dehaze(texture(photo, UV).rgb * photo_gain);
	if (inner_map.x > 0.0) {
		vec2 iuv = UV * inner_map.xy + inner_map.zw;
		vec2 ie = min(iuv, 1.0 - iuv);
		float inside = smoothstep(0.0, 0.1, min(ie.x, ie.y));
		vec3 inner = max(texture(photo_inner, iuv).rgb * inner_gain + inner_bias, vec3(0.0));
		hf = mix(hf, t_dehaze(inner * photo_gain), inside);
	}
	float exg = (2.0 * lf.g - lf.r - lf.b) / max(lf.r + lf.g + lf.b, 1e-3);
	float veg = smoothstep(veg_lo, veg_hi, exg);
	// Teal shallows and wet flats (Venice's lagoon) are green-ish too, but
	// carry far more blue than grass does: not vegetation.
	veg *= 1.0 - smoothstep(0.55, 0.8, lf.b / max(lf.g, 1e-3));
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
	// Share of unmown meadow (class 17) among the taps.
	float wildw = 0.0;
	// Around the viewpoint the fine map decides. Its borders wander a
	// little, as grass overgrowing a path edge does, and unmapped texels
	// leave their share to the extent map below.
	float coarse = 1.0;
	if (near_n > 0.5) {
		vec2 ed = abs(wpos.xz - near_rect.xy);
		float nw = 1.0 - smoothstep(near_rect.z - near_rect.w, near_rect.z, max(ed.x, ed.y));
		coarse = 1.0 - nw;
		if (nw > 0.0) {
			vec2 warp = (vec2(t_noise(g * 0.9 + 3.1), t_noise(g * 0.9 + 11.7)) - 0.5) * 0.7
				+ (vec2(t_noise(g * 3.7 + 5.3), t_noise(g * 3.7 + 19.1)) - 0.5) * 0.18;
			vec2 nuv = ((wpos.xz + warp / u2m - near_rect.xy) / (2.0 * near_rect.z) + 0.5) * near_n - 0.5;
			vec2 nf = fract(nuv);
			ivec2 n0 = ivec2(floor(nuv));
			ivec2 nmax = ivec2(int(near_n) - 1);
			for (int k = 0; k < 4; k++) {
				ivec2 o = ivec2(k & 1, k >> 1);
				float bw = nw * (o.x == 1 ? nf.x : 1.0 - nf.x) * (o.y == 1 ? nf.y : 1.0 - nf.y);
				int id = int(texelFetch(near_class, clamp(n0 + o, ivec2(0), nmax), 0).r * 255.0 + 0.5);
				if (bank_paving > 0.5) {
					id = 3;
				}
				if (id == 0) {
					coarse += bw;
				} else {
					class_tap(id, bw, veg, W0, W1, col, trust, farc, rough, hfk, pave);
					wildw += id == 17 ? bw : 0.0;
				}
			}
			// Grass beside anything hard is trodden to bare earth, in
			// patches: a kerb, a path or a wall looks for it within about a metre.
			float lawn = W0.y;
			if (lawn > 0.3 && dist_m < 350.0) {
				float texel_m = 2.0 * near_rect.z * u2m / near_n;
				ivec2 cc0 = ivec2(floor(nuv + 0.5));
				float hard = 0.0;
				for (int k = 0; k < 8; k++) {
					float ang = float(k) * 0.7853982;
					float rad = (k % 2 == 0 ? 0.55 : 1.15) / texel_m;
					ivec2 o = ivec2(round(vec2(cos(ang), sin(ang)) * rad));
					int nid = int(texelFetch(near_class, clamp(cc0 + o, ivec2(0), nmax), 0).r * 255.0 + 0.5);
					hard += (nid == 1 || nid == 2 || nid == 3 || nid == 16) ? 1.0 : 0.0;
				}
				float worn = clamp(hard / 3.0, 0.0, 1.0)
					* smoothstep(0.3, 0.7, t_noise(g * 1.1) * 0.7 + t_noise(g * 4.3 + 9.0) * 0.3)
					* (1.0 - smoothstep(150.0, 350.0, dist_m)) * nw * 0.85;
				W0.w += W0.y * worn;
				W0.y *= 1.0 - worn;
				col = mix(col, vec3(0.22, 0.17, 0.12), worn * clamp(lawn, 0.0, 1.0));
				trust *= 1.0 - 0.6 * worn;
			}
		}
	}
	if (coarse > 0.0005) {
		for (int k = 0; k < 4; k++) {
			ivec2 o = ivec2(k & 1, k >> 1);
			float bw = coarse * (o.x == 1 ? f.x : 1.0 - f.x) * (o.y == 1 ? f.y : 1.0 - f.y);
			int id = int(texelFetch(class_map, clamp(c0 + o, ivec2(0), cmax), 0).r * 255.0 + 0.5);
			if (bank_paving > 0.5) {
				id = 3;
			}
			class_tap(id, bw, veg, W0, W1, col, trust, farc, rough, hfk, pave);
			wildw += id == 17 ? bw : 0.0;
		}
	}
	// Crag relief: noise gradients bend the lighting normal on steep and
	// rocky ground, so DEM slabs read as ribbed rock faces.
	vec3 nw = normalize(wnrm);
	if (relief_rect.z > 0.0 && dist_m < 600.0) {
		vec2 ruv = (wpos.xz - relief_rect.xy) / (2.0 * relief_rect.zw) + 0.5;
		vec2 re = min(ruv, 1.0 - ruv);
		float rf = smoothstep(0.0, 0.06, min(re.x, re.y)) * (1.0 - smoothstep(250.0, 600.0, dist_m));
		if (rf > 0.0) {
			vec2 sl = texture(dem_relief, ruv).rg * 2.0 - 1.0;
			nw = normalize(nw - vec3(sl.x, 0.0, sl.y) * rf);
		}
	}
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
	float macro = clamp(lum(lf) / max(big, 1e-3), 0.72, 1.18);
	macro *= 0.92 + 0.16 * t_noise(g / 47.0);
	vec3 base = mix(col, lf, trust);
	// Rock colour: neutral stone carrying some of the photo's tint.
	float l_lf = max(lum(lf), 1e-3);
	vec3 rock_c = mix(vec3(0.34, 0.32, 0.29), lf * (0.33 / l_lf), 0.5);
	base = mix(base, rock_c, steep * 0.85);
	// Exposed granite: feldspar pink-grey with cool, pale lichen patches.
	float granite = clamp(W0.z + W1.x * 0.45, 0.0, 1.0) * (1.0 - veg);
	vec3 granite_c = mix(vec3(0.37, 0.32, 0.30), vec3(0.42, 0.43, 0.37),
		smoothstep(0.48, 0.7, t_noise(g / 1.7)));
	base = mix(base, granite_c * (0.88 + 0.2 * t_noise(g * 5.0)), granite * 0.55);
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
		float wild = clamp(wildw, 0.0, 1.0);
		// Unmown meadow dries in bigger, bolder patches than a watered lawn.
		vec3 tone = mix(lush, dried, smoothstep(mix(0.32, 0.22, wild), mix(0.72, 0.62, wild), m_big));
		float near_fine = 1.0 - smoothstep(120.0, 600.0, dist_m);
		tone *= 0.88 + mix(0.24, 0.34, wild) * mix(0.5, m_fine, near_fine);
		// Close by, grass is blades, not felt: streaky light and dark grain
		// (and in a meadow the odd pale seed head) at the scale of a tuft.
		if (ground_quality >= 1 && dist_m < 45.0) {
			float near_b = 1.0 - smoothstep(18.0, 45.0, dist_m);
			float grain = t_noise(g * vec2(6.3, 2.1) + 31.0) * 0.6 + t_noise(g * 13.0 + 7.0) * 0.4;
			tone *= 1.0 + (grain - 0.5) * 0.22 * near_b;
			float seed = smoothstep(0.80, 0.9, t_noise(g * 2.7 + 41.0)) * wild * near_b;
			tone = mix(tone, dried * 1.15, seed * 0.35);
		}
		base *= mix(vec3(1.0), tone, meadow * 0.85);
		// Mown lawns carry the mower's stripes: blades leaning away from
		// the eye show their lit sides, those leaning toward it their
		// shadowed bases, so the bands swap as the view turns.
		float mown = meadow * (1.0 - wild) * (1.0 - smoothstep(90.0, 170.0, dist_m));
		if (ground_quality >= 1 && mown > 0.01) {
			vec2 sd = vec2(cos(stripe_angle), sin(stripe_angle));
			float sc_m = dot(g, vec2(-sd.y, sd.x)) / 1.3;
			float aa = 1.0 - smoothstep(0.25, 0.6, fwidth(sc_m));
			float band = smoothstep(-0.12, 0.12, sin(sc_m * 3.14159265)) * 2.0 - 1.0;
			vec2 to_eye = normalize(CAMERA_POSITION_WORLD.xz - wpos.xz + vec2(1e-4));
			base *= 1.0 + 0.075 * band * dot(sd, to_eye) * mown * aa;
		}
		// Seen low, mown turf shows blade sides: paler and a touch silvery.
		// Standing meadow hides its soil behind shaded blades instead: it
		// deepens toward the horizon, as the blade carpet under the eye
		// does, so the carpet's rim does not read as a lawn's edge.
		float ndv = clamp(dot(normalize(CAMERA_POSITION_WORLD - wpos), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
		float graze = pow(1.0 - ndv, 3.0) * meadow * (1.0 - steep);
		base = mix(base, vec3(lum(base)) * 1.12, 0.16 * graze * (1.0 - wild));
		float stand = pow(1.0 - ndv, 1.5) * meadow * wild * (1.0 - steep);
		base = mix(base, base * vec3(0.6, 0.7, 0.48), 0.85 * stand);
		// Sunlit turf is a deep, slightly grey green, never poster green.
		float turf = lum(base);
		base = mix(base, vec3(turf), 0.18 * meadow) * mix(1.0, 0.93, meadow);
		// A lawn is never a plane: slow swells catch the light.
		if (ground_quality >= 1 && dist_m < 260.0) {
			vec2 swell = t_relief(g, 7.0, 2);
			nw = normalize(nw - vec3(swell.x, 0.0, swell.y) * 0.35 * meadow * (1.0 - smoothstep(120.0, 260.0, dist_m)));
		}
	}
	// Photographic layers by weight, each normalised by its mean so the
	// class colour sets the value and the texture only adds structure.
	float w[8] = float[8](W0.x, W0.y, W0.z, W0.w, W1.x, W1.y, W1.z, W1.w);
	bool vary = ground_quality >= 1;
	vec3 det = vec3(0.0);
	vec4 nm = vec4(0.0);
	float wt = 0.0;
	int main_layer = -1;
	float main_w = 0.0;
	for (int i = 0; i < 8; i++) {
		if (w[i] < 0.02) {
			continue;
		}
		if (w[i] > main_w) {
			main_w = w[i];
			main_layer = i;
		}
		vec4 a;
		vec4 n;
		// Rock and cliff layers wrap steep faces (biplanar), so they do not streak.
		if ((i == 4 || i == 2) && ground_quality >= 2 && steep > 0.05) {
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
	// Close to the eye one repeat of a layer is too coarse: the main layer
	// again at about a quarter the size gives the surface its fine grain.
	if (micro_detail > 0.5 && dist_m < 90.0 && main_layer >= 0) {
		float mf = (1.0 - smoothstep(30.0, 90.0, dist_m)) * main_w;
		vec4 ma;
		vec4 mn;
		det_sample(main_layer, g * 3.7, dg * 3.7, false, ma, mn);
		det *= mix(vec3(1.0), clamp(ma.rgb / det_mean[main_layer], vec3(0.6), vec3(1.5)), 0.3 * mf);
		nm.rg += (mn.rg - vec2(0.5)) * 0.6 * mf;
	}
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
	// Natural shore wetness is painted on the canonical dry surface.
	// Negative bank attributes never replace the adjacent land material.
	alb *= mix(1.0, 0.7, clamp(-bank_paving, 0.0, 1.0));
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
	float ground_max = mix(ground_max_low, 0.85, smoothstep(350.0, 1000.0, pm.y));
	alb *= min(1.0, ground_max / max(lum(alb), 1e-4));
	// Seasonal climate snow over the (summer) imagery, after the edge
	// hand-off so near and far carry the same line (ClimateModel); it
	// slides off cliffs (relief normal) and takes its own texture.
	float pixel_m = max(length(dg.xy), length(dg.zw));
	float sc = snow_cover(wpos, nw.y);
	vec4 sa = vec4(0.0);
	vec4 sn = vec4(0.5, 0.5, 1.0, 0.7);
	float glint = 0.0;
	if (sc > 0.01) {
		det_sample(8, g, dg, vary, sa, sn);
		// Wind relief, hollows a touch bluer (they see sky, not sun),
		// and ice crystals that catch a direct sun.
		float near_snow = 1.0 - smoothstep(150.0, 700.0, dist_m);
		vec3 hollow = vec3(1.0);
		if (near_snow > 0.0 && ground_quality >= 1) {
			vec2 dr = snow_drift(g);
			nw = normalize(nw - vec3(dr.x, 0.0, dr.y) * 0.22 * sc * near_snow);
			float shade = smoothstep(0.3, 0.7, snow_noise(g / 5.5));
			hollow = mix(mix(vec3(0.86, 0.92, 1.0), vec3(1.0), shade), vec3(1.0), 1.0 - near_snow);
		}
		// The layer gives snow its grain; it must not tint or scar it.
		alb = mix(alb, snow_col * hollow * clamp(lum(sa.rgb / det_mean[8]), 0.9, 1.08), sc);
		sn.rgb = mix(vec3(0.5, 0.5, 1.0), sn.rgb, 0.45);
		if (ground_quality >= 2) {
			vec4 facet = snow_facet(g, pixel_m);
			glint = facet.w * sc;
			nw = normalize(mix(nw, facet.xyz, glint));
		}
	}
	// Live rain: wet ground darkens and turns glossy (not under snow).
	float wet = climate_wetness * (1.0 - sc);
	alb *= mix(1.0, 0.76, wet);
	// Water in the low spots of flat paving (squares, pavements), as on
	// the roads (RoadSurface): small, scattered and ringed by damp.
	vec2 mask = puddle_mask(puddle_low(g, pixel_m)) * wet * pave * (1.0 - steep) * (1.0 - wf);
	float puddle = mask.x;
	alb = puddle_albedo(alb, mask);
	vec2 ripple = vec2(0.0);
	if (puddle > 0.01) {
		ripple = rain_ripples(g, TIME, pixel_m) * 0.25;
	}
	ALBEDO = value_clamp(alb);
	// Lighting normal: relief-bent world normal into view space.
	vec3 tw = normalize(vec3(1.0, 0.0, 0.0) - nw * nw.x);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	TANGENT = normalize((VIEW_MATRIX * vec4(tw, 0.0)).xyz);
	BINORMAL = normalize((VIEW_MATRIX * vec4(cross(tw, nw), 0.0)).xyz);
	vec3 nmap = mix(nm.rgb, sn.rgb, sc);
	NORMAL_MAP = mix(nmap, vec3(0.5 + ripple.x, 0.5 + ripple.y, 1.0), max(max(wf, edge), max(puddle, glint)));
	NORMAL_MAP_DEPTH = 0.9;
	AO = contact;
	AO_LIGHT_AFFECT = 0.2;
	// The layers' own roughness maps carry gloss variation near by.
	float rmap = mix(nm.a, sn.a, sc);
	float r = mix(rough, clamp(rmap, 0.62, 1.0), 0.5 * (1.0 - wf));
	ROUGHNESS = mix(puddle_roughness(r, wet, mask), 0.1, glint);
	SPECULAR = mix(mix(0.28, 0.5, wet), 1.0, glint);
}
"""
