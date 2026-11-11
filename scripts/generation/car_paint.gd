class_name CarPaint
extends RefCounted

## Paint for the parked cars (CarModel), and the soft contact shadow
## under every one.
## * Colour: the instance colour, flat; UV.x carries the occlusion the
##   body loft baked into its sills and arches (VehicleKit).
## * Shut lines: door, bonnet and boot gaps are drawn, not modelled: the
##   body's material lists them as segments in the car's own frame (side
##   view x/y, plan x/|z|), a few millimetres wide and antialiased.
## * End faces: the grille and intake slats, the lamp bezels, the plate
##   recess and the bumper and bonnet lines are drawn the same way, from
##   the car's `face` rows (front 0-4, rear 5-9; see CarModel), so the
##   far mesh has them too.
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
uniform vec4 face[10];
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
float cov(float d, float px) {
	return clamp(0.5 - d / px, 0.0, 1.0);
}
// Rounded box: distance to its edge, metres, negative inside.
float sd_box(vec2 p, vec2 c, vec2 h, float r) {
	vec2 q = abs(p - c) - h + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
// Slats `pitch` apart from y0: the share of a pixel on a slat, evened out
// where they are finer than the screen can show.
float slats(float y, float y0, float pitch, float duty, float px) {
	float v = (y - y0) / pitch;
	float line = cov((abs(fract(v) - 0.5) - 0.5 * duty) * pitch, px);
	return mix(duty, line, clamp(pitch / px * 0.25 - 0.5, 0.0, 1.0));
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
	// End faces: dark openings with slats, bezels, plate recess, and split lines.
	float opening = 0.0;
	float slat = 0.0;
	float mesh_bars = 0.0;
	if (abs(body_n.x) > 0.5) {
		int o = body_n.x > 0.0 ? 0 : 5;
		vec2 q = vec2(abs(body_pos.z), body_pos.y);
		vec4 lamp = face[o];
		vec4 grille = face[o + 1];
		vec4 intake = face[o + 2];
		vec4 plate = face[o + 3];
		vec4 lines = face[o + 4];
		vec2 lc = vec2(lamp.x + lamp.w, lamp.y + lamp.z) * 0.5;
		vec2 lh = vec2(lamp.w - lamp.x, lamp.z - lamp.y) * 0.5;
		opening = max(opening, cov(sd_box(q, lc, lh, 0.02) - 0.012, px));
		if (grille.x > 0.0) {
			vec2 gc = vec2(0.0, (grille.y + grille.z) * 0.5);
			vec2 gh = vec2(grille.x, (grille.z - grille.y) * 0.5);
			float g = cov(sd_box(q, gc, gh, 0.012), px);
			opening = max(opening, g);
			slat = max(slat, g * slats(q.y, grille.y, (grille.z - grille.y) / grille.w, 0.4, px));
		}
		if (intake.x > 0.0) {
			vec2 ic = vec2(0.0, (intake.y + intake.z) * 0.5);
			vec2 ih = vec2(intake.x, (intake.z - intake.y) * 0.5);
			float g = cov(sd_box(q, ic, ih, 0.02), px);
			opening = max(opening, g);
			float cell = (intake.z - intake.y) / intake.w;
			mesh_bars = g * max(slats(q.y, intake.y, cell, 0.22, px),
				slats(q.x, 0.0, cell * 1.3, 0.16, px));
		}
		opening = max(opening, cov(sd_box(q, vec2(0.0, plate.x), plate.zy, 0.012), px));
		d = min(d, abs(q.y - lines.x));
		if (q.x < lines.z) {
			d = min(d, abs(q.y - lines.y));
		}
	}
	float seam = clamp((0.004 - d) / px + 0.5, 0.0, 1.0) * clamp(0.012 / px, 0.0, 1.0);
	vec3 col = (body_pos.y > livery_y ? livery_col : instance_paint.rgb) * (1.0 - 0.85 * seam);
	col = mix(col, vec3(0.012, 0.012, 0.014), opening);
	col = mix(col, vec3(0.2, 0.21, 0.22), max(slat, mesh_bars * 0.5));
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
	ROUGHNESS = mix(mix(rough, 0.45, opening), 0.86, snow);
	METALLIC = mix(0.7 * metal, 0.8, max(slat, mesh_bars)) * (1.0 - snow);
	SPECULAR = 0.65;
	AO = mix(1.0, clamp(UV.x, 0.0, 1.0), 0.8) * (1.0 - 0.6 * seam);
	CLEARCOAT = (1.0 - grime * 0.85) * (1.0 - snow) * (1.0 - seam) * (1.0 - opening);
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
