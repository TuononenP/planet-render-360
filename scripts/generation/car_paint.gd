class_name CarPaint
extends RefCounted

## Paint for the parked cars (CarModel), and the soft contact shadow
## under every one.
## * Colour: the instance colour, flat; UV.x carries the occlusion the
##   body loft baked into its sills and arches (VehicleKit).
## * Shut lines: door, bonnet and boot gaps are drawn, not modelled: the
##   body's material lists them as segments in the car's own frame (side
##   view x/y, plan x/|z|), a few millimetres wide and antialiased.
## * Livery: a cab's roof colour, above the material's livery_y.
## * Finish: a sharp clear coat over every paint; metallic paints
##   (instance custom .x) add a strong metal base with a faint flake,
##   kept short of fully metallic (that mirrored the sky like a glass case).
## * Grime: road spray darkens and dulls the sills and arches (instance
##   custom .y).
## * Snow settles on roofs and bonnets (ClimateModel).
const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
// @SNOW
uniform vec4 seam_side[8];
uniform int seam_side_n = 0;
uniform vec4 seam_top[8];
uniform int seam_top_n = 0;
uniform float livery_y = 100.0;
uniform vec3 livery_col : source_color = vec3(1.0);
varying vec4 instance_paint;
varying vec4 finish;
varying vec3 body_pos;
varying vec3 body_n;
varying vec3 wpos;
varying vec3 wnormal;
void vertex() {
	instance_paint = COLOR;
	finish = INSTANCE_CUSTOM;
	body_pos = VERTEX;
	body_n = NORMAL;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
float seam_d(vec2 p, vec4 s) {
	vec2 ab = s.zw - s.xy;
	return distance(p, s.xy + ab * clamp(dot(p - s.xy, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0));
}
void fragment() {
	float metal = finish.x;
	// Metres across one pixel, in the body's frame.
	float px = max(max(fwidth(body_pos.x), fwidth(body_pos.y)), fwidth(body_pos.z)) + 1e-5;
	float d = 10.0;
	if (abs(body_n.z) > 0.5) {
		for (int i = 0; i < seam_side_n; i++) {
			d = min(d, seam_d(body_pos.xy, seam_side[i]));
		}
	}
	if (body_n.y > 0.5) {
		for (int i = 0; i < seam_top_n; i++) {
			d = min(d, seam_d(vec2(body_pos.x, abs(body_pos.z)), seam_top[i]));
		}
	}
	float seam = clamp((0.004 - d) / px + 0.5, 0.0, 1.0) * clamp(0.012 / px, 0.0, 1.0);
	vec3 col = (body_pos.y > livery_y ? livery_col : instance_paint.rgb) * (1.0 - 0.85 * seam);
	// Flake: a roughness wobble per millimetre, faded before it can shimmer.
	vec3 cell = floor(body_pos * 1500.0);
	float flake = (snow_hash(cell.xz + cell.y * 17.0) - 0.5) * (1.0 - smoothstep(0.5, 1.5, px * 1500.0));
	// Godot weighs the clear coat at a quarter of the base layer, so the
	// base carries most of the gloss: polished for solid paint, a softer
	// sheen under the flake for metallics.
	float rough = mix(0.14, 0.28, metal) + flake * 0.12 * metal;
	// Road spray: heaviest at the sills and arches, thinning up the doors.
	float grime = finish.y * smoothstep(0.75, 0.1, body_pos.y);
	col = mix(col, col * 0.45 + vec3(0.05, 0.042, 0.032), grime);
	rough = mix(rough, 0.78, grime);
	float snow = snow_cover(wpos, normalize(wnormal).y);
	ALBEDO = mix(col, snow_col, snow);
	ROUGHNESS = mix(rough, 0.86, snow);
	METALLIC = 0.7 * metal * (1.0 - snow);
	SPECULAR = 0.65;
	AO = mix(1.0, clamp(UV.x, 0.0, 1.0), 0.8) * (1.0 - 0.6 * seam);
	CLEARCOAT = (1.0 - grime * 0.85) * (1.0 - snow) * (1.0 - seam);
	CLEARCOAT_ROUGHNESS = 0.02 + grime * 0.4;
}
"""

## Ground darkening under a parked car: strongest under the floor pan,
## fading past the body's edges. Multiplies what is already drawn. Road
## ribbons are lifted (RoadBuilder LIFT_MAX_M) and depth-biased by layer
## (RoadSurface.DEPTH_GLSL), so a quad laid on the ground hid under the
## road: it sits above the top lift and one bias layer past the crossings.
const SHADOW_LAYER := 9.0
const SHADOW_CODE := """
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float strength = 0.72;
void vertex() {
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (PROJECTION_MATRIX[3][3] < 0.5) {
		POSITION.z *= 1.0 + %f;
	}
}
void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float under = 1.0 - smoothstep(0.3, 1.0, length(q * vec2(0.95, 0.9)));
	ALBEDO = vec3(1.0 - strength * under * under);
}
"""

static var _paint: Shader
static var _shadow: ShaderMaterial

## Built once on the main thread (startup): a first compile on the
## background loader fails with the Metal renderer.
static func shader() -> Shader:
	if _paint == null:
		_paint = Shader.new()
		_paint.code = CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	return _paint

static func shadow_material() -> ShaderMaterial:
	if _shadow == null:
		var sh := Shader.new()
		sh.code = SHADOW_CODE % (RoadSurface.DEPTH_EPS * SHADOW_LAYER)
		_shadow = ShaderMaterial.new()
		_shadow.shader = sh
	return _shadow
