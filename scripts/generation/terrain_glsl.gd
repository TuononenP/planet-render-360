class_name TerrainGlsl
extends RefCounted

## GLSL shared by the near ground (GroundShader) and far rings
## (FarSurface), spliced in at "// @TERRAIN":
## - hash / value noise and its analytic gradient, for crag relief:
##   DEM meshes are 9–70 m between posts, so a cliff is a smooth slab;
##   a few octaves of noise gradient on steep ground give it ribs,
##   gullies and ledges in the lighting (no geometry);
## - det_sample: a TerrainTextures layer without visible repetition
##   (Quilez's offset-variation technique: two fetches at per-region
##   random offsets, blended on a low-frequency noise), with explicit
##   gradients so it may sit in branches;
## - det_side: a layer projected on the two vertical planes (biplanar)
##   for cliffs, where a plan projection stretches into streaks;
## - t_dehaze: the satellite photo without its own baked haze.
const CODE := """
uniform sampler2DArray det_alb : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray det_nor : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 det_mean[9];
uniform float det_tile[9];

float t_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float t_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(t_hash(i), t_hash(i + vec2(1.0, 0.0)), f.x),
		mix(t_hash(i + vec2(0.0, 1.0)), t_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Satellite imagery carries its own blue-grey atmosphere; lit again
// under ours it read mint-teal. Lift the haze floor off and pull the
// cyan cast back toward natural greens (near photo, edge band and far
// drapes alike, so the hand-offs match).
vec3 t_dehaze(vec3 c) {
	c = max(c - vec3(0.010, 0.014, 0.022), vec3(0.0)) * 1.08;
	c.b *= 0.86;
	// Green-dominant pixels still lean cyan in shade: pull their blue
	// back toward the red, so lawns read leaf green, not mint.
	float leaf = smoothstep(0.0, 0.06, c.g - max(c.r, c.b));
	c.b = mix(c.b, min(c.b, c.r * 0.92), leaf * 0.45);
	// Sunlit leaf cover is far darker and richer than the aerial photo's
	// dehazed value (a lit meadow reflects ~0.2, not 0.5): without this
	// lawns glow neon lime next to stone and trees.
	float l0 = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l0), c, 1.0 + 0.22 * leaf) * mix(1.0, 0.66, leaf);
	// Dry grass, soil and sand come out of the dehaze chalky and too
	// bright: give warm ground its colour back and ease the brightest
	// values (a sunlit tan hill reflects ~0.35, not 0.7).
	float warm = smoothstep(0.0, 0.05, c.r - c.b) * (1.0 - leaf);
	float l1 = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l1), c, 1.0 + 0.32 * warm) * (1.0 - 0.24 * smoothstep(0.30, 0.65, l1));
	return max(mix(vec3(dot(c, vec3(0.2126, 0.7152, 0.0722))), c, 1.12), vec3(0.0));
}

// Cloud shadows (AtmosphereRig sets the globals): the deck's density
// where the ray from p toward the sun meets a cloud layer CLOUD_H up,
// mapped like the sky dome's deck (uv ≈ xz / H · 1.3) and drifting with
// it, so shadows sweep across far slopes under a broken sky.
global uniform float cloud_shadow_cover;
global uniform float cloud_shadow_drift;
global uniform float cloud_shadow_stretch;
global uniform vec3 cloud_sun_dir;
float t_cloud_shadow(vec3 p) {
	if (cloud_shadow_cover <= 0.02 || cloud_sun_dir.y <= 0.03) {
		return 0.0;
	}
	float h = 2200.0;
	vec2 q = p.xz + cloud_sun_dir.xz / cloud_sun_dir.y * max(h - p.y, 0.0);
	vec2 uv = q / h * 1.3;
	vec2 wd = vec2(0.8, 0.6);
	vec2 wn = vec2(-wd.y, wd.x);
	uv = wd * (dot(uv, wd) / max(cloud_shadow_stretch, 0.1)) + wn * dot(uv, wn) + wd * cloud_shadow_drift;
	uv += 0.45 * vec2(t_noise(uv * 0.35), t_noise(uv * 0.35 + vec2(7.3, 2.1))) - 0.225;
	float den = t_noise(uv) * 0.5 + t_noise(uv * 2.03 + vec2(17.1, 5.3)) * 0.3
		+ t_noise(uv * 4.1 + vec2(3.7, 9.2)) * 0.2;
	float thr = 0.5 + (0.5 - cloud_shadow_cover) * 0.36;
	return smoothstep(thr - 0.03, thr + 0.12, den);
}

// Value noise (x) with its gradient (yz), quintic-smoothed.
vec3 t_noised(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	vec2 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
	float a = t_hash(i);
	float b = t_hash(i + vec2(1.0, 0.0));
	float c = t_hash(i + vec2(0.0, 1.0));
	float d = t_hash(i + vec2(1.0, 1.0));
	float k1 = b - a;
	float k2 = c - a;
	float k4 = a - b - c + d;
	return vec3(a + k1 * u.x + k2 * u.y + k4 * u.x * u.y,
		du * vec2(k1 + k4 * u.y, k2 + k4 * u.x));
}

// Gradient (per metre) of an eroded-looking fBm height at metres g:
// ridged octaves damped where the slope is already high, as erosion
// smooths gullies. `oct` octaves from `scale_m` down by ~2.1x.
vec2 t_relief(vec2 g, float scale_m, int oct) {
	vec2 grad = vec2(0.0);
	float amp = 1.0;
	float s = 1.0 / scale_m;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	vec2 p = g * s;
	for (int i = 0; i < 4; i++) {
		if (i >= oct) {
			break;
		}
		vec3 n = t_noised(p);
		vec2 d = n.yz * s;
		grad += amp * d / (1.0 + dot(grad, grad) * 0.5);
		p = r * p * 2.1 + vec2(13.7, 7.1);
		s *= 2.1;
		amp *= 0.5;
	}
	return grad;
}

// Layer `l` at metre coords g with screen gradients dg (dFdx, dFdy of
// g taken outside any branch). Out: albedo (rgb), normal + rough (a).
void det_sample(int l, vec2 g, vec4 dg, bool vary, out vec4 a, out vec4 n) {
	float ts = 1.0 / det_tile[l];
	vec2 uv = g * ts;
	vec2 dx = dg.xy * ts;
	vec2 dy = dg.zw * ts;
	if (!vary) {
		a = textureGrad(det_alb, vec3(uv, float(l)), dx, dy);
		n = textureGrad(det_nor, vec3(uv, float(l)), dx, dy);
		return;
	}
	float k = t_noise(uv * 0.23 + float(l) * 7.3) * 7.0;
	float ia = floor(k);
	float f = fract(k);
	vec2 oa = sin(vec2(3.0, 7.0) * ia);
	vec2 ob = sin(vec2(3.0, 7.0) * (ia + 1.0));
	vec4 a1 = textureGrad(det_alb, vec3(uv + oa, float(l)), dx, dy);
	vec4 a2 = textureGrad(det_alb, vec3(uv + ob, float(l)), dx, dy);
	float b = smoothstep(0.2, 0.8, f - 0.1 * dot(a1.rgb - a2.rgb, vec3(1.0)));
	a = mix(a1, a2, b);
	n = mix(textureGrad(det_nor, vec3(uv + oa, float(l)), dx, dy),
		textureGrad(det_nor, vec3(uv + ob, float(l)), dx, dy), b);
}

// Biplanar: layer `l` on the X- and Z-facing vertical planes, weighted
// by the world normal; metre position p, its screen gradients dpx/dpy.
void det_side(int l, vec3 p, vec3 dpx, vec3 dpy, vec3 nw, out vec4 a, out vec4 n) {
	float ts = 1.0 / det_tile[l];
	vec2 ux = p.zy * ts;
	vec2 uz = p.xy * ts;
	float wx = pow(abs(nw.x), 3.0);
	float wz = pow(abs(nw.z), 3.0);
	float s = max(wx + wz, 1e-4);
	wx /= s;
	wz /= s;
	a = wx * textureGrad(det_alb, vec3(ux, float(l)), dpx.zy * ts, dpy.zy * ts)
		+ wz * textureGrad(det_alb, vec3(uz, float(l)), dpx.xy * ts, dpy.xy * ts);
	n = wx * textureGrad(det_nor, vec3(ux, float(l)), dpx.zy * ts, dpy.zy * ts)
		+ wz * textureGrad(det_nor, vec3(uz, float(l)), dpx.xy * ts, dpy.xy * ts);
}
"""

## Sets the shared uniforms on a terrain ShaderMaterial.
static func bind(m: ShaderMaterial, preset: int) -> void:
	var arr := TerrainTextures.arrays(TerrainTextures.size_for(preset))
	m.set_shader_parameter("det_alb", arr["albedo"])
	m.set_shader_parameter("det_nor", arr["normal"])
	m.set_shader_parameter("det_mean", TerrainTextures.means())
	m.set_shader_parameter("det_tile", TerrainTextures.tiles())
