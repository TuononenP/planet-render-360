class_name PavingGlsl
extends RefCounted

## The stone pattern the ground (GroundShader) and the paved ribbons
## (RoadSurface.PAVED_CODE) both lay, spliced into each at "// @PAVING", so
## a square and the walk across it carry one structure and stay matched.
##
## `paving_look(g, sett, rgh)` at metre coords g gives the value gain of
## laid stone (about 1, so the finish's own colour stays) and its roughness:
## 2 x 1.4 m running-bond flagstones, or with `sett` > 0.5 13 x 11 cm
## granite setts. Close up it is the slabs' own tone (+-10%, setts +-9%)
## and dark joints; as the eye draws back it settles instead of fading:
## - a joint narrower than a pixel keeps the share of the pixel it covers
##   (the exact-coverage filter of RoadSurface.LINE_GLSL's band(), per axis:
##   a joint running along the view stays crisp while the ones across it
##   merge), so it darkens the mean by a few percent rather than vanishing;
## - a slab's tone loses strength as many slabs share a pixel (1/sqrt), and
##   a laying patch of setts (0.6 m, +-6%) takes over once stones are
##   sub-pixel;
## - age: the asphalt's slow blotches and finer mottling (mean 1), so open
##   paving reads as worn stone, not one slab.
## The gain is divided by the joints' mean darkening, so the base colour is
## kept. Roughness varies by slab (0.80-0.95), joints 0.98.
const CODE := """
float pv_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float pv_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(pv_hash(i), pv_hash(i + vec2(1.0, 0.0)), f.x),
		mix(pv_hash(i + vec2(0.0, 1.0)), pv_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Exact coverage of |x - c| < hw over a pixel `aa` wide (RoadSurface
// LINE_GLSL band()).
float pv_band(float x, float c, float hw, float aa) {
	float h = max(aa * 0.5, 1e-4);
	return clamp((min(x + h, c + hw) - max(x - h, c - hw)) / (2.0 * h), 0.0, 1.0);
}

// Coverage of a joint repeating every `period` m (half width `hw`) at x over
// a pixel `aa` wide; past a third of a period a pixel sees the mean.
float pv_joint(float x, float period, float hw, float aa) {
	float d = (fract(x / period + 0.5) - 0.5) * period;
	return mix(pv_band(d, 0.0, hw, aa), 2.0 * hw / period, smoothstep(0.2, 0.5, aa / period));
}

float paving_look(vec2 g, float sett, out float rgh) {
	float s = step(0.5, sett);
	vec2 fm = max(fwidth(g), vec2(1e-4));
	// Age: blotches over ~21 m and a finer mottling, as the asphalt's; the
	// fine one settles to its mean before it can shimmer.
	float fine = mix(pv_noise(g / 2.7 + 5.1), 0.5, smoothstep(0.2, 0.6, max(fm.x, fm.y) / 2.7));
	float age = (0.92 + 0.16 * pv_noise(g / 21.0)) * (0.97 + 0.06 * fine);
	vec2 slab = mix(vec2(2.0, 1.4), vec2(0.13, 0.11), s);
	vec2 su = g / slab;
	// Running bond: every other row shifted half a slab.
	su.x += 0.5 * mod(floor(su.y), 2.0);
	vec2 cell = floor(su);
	// Tone per slab; many slabs to a pixel average out.
	float cells = fm.x / slab.x * fm.y / slab.y;
	float vis = inversesqrt(max(1.0, cells * 2.0)) * (1.0 - smoothstep(1.0, 6.0, cells));
	float tone = (pv_hash(cell + 3.1) - 0.5) * mix(0.20, 0.18, s);
	// Setts are laid in patches that outlast the single stone.
	float patch_fade = 1.0 - smoothstep(0.15, 0.6, max(fm.x, fm.y) / 0.6);
	tone = tone * vis + s * (pv_hash(floor(g / 0.6) + 7.7) - 0.5) * 0.12 * patch_fade;
	float hw = mix(0.015, 0.012, s);
	float cx = pv_joint(su.x * slab.x, slab.x, hw, fm.x);
	float cy = pv_joint(su.y * slab.y, slab.y, hw, fm.y);
	float joint = 1.0 - (1.0 - cx) * (1.0 - cy);
	// What the joints take off the mean (the two axes' coverage and depth),
	// given back so the finish keeps its colour.
	float depth = mix(0.35, 0.22, s);
	float cover = 1.0 - (1.0 - 2.0 * hw / slab.x) * (1.0 - 2.0 * hw / slab.y);
	float gain = age * (1.0 + tone) * (1.0 - depth * joint) / (1.0 - depth * cover);
	float stone = mix(0.80 + 0.15 * pv_hash(cell + 11.3), 0.875, 1.0 - vis);
	rgh = mix(stone, 0.98, joint);
	return gain;
}
"""
