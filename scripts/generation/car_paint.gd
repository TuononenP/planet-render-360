class_name CarPaint
extends RefCounted

## Paint for the near (imported) parked cars, and the soft contact shadow
## under every parked car.
## * Panels: the body texture bakes a top light (side panels at a third
##   of the roof), which turned a white car's doors grey whatever the sun
##   did. Painted texels now take the instance paint flat; the bake keeps
##   only its dark creases (panel gaps, seals) and feeds ambient occlusion.
## * Finish: a clear coat over every paint; metallic paints (instance
##   custom .x) add a modest metal base with a faint flake. A fully
##   metallic body mirrored the sky and read as a glass case.
## * Grime: road spray darkens and dulls the sills and arches (instance
##   custom .y).
## * Snow settles on roofs and bonnets as on the distant cars (StreetSnow).
const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
// @SNOW
uniform sampler2D body_map : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
varying vec4 instance_paint;
varying vec4 finish;
varying float body_y;
varying vec3 wpos;
varying vec3 wnormal;
void vertex() {
	instance_paint = COLOR;
	finish = INSTANCE_CUSTOM;
	body_y = VERTEX.y;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec4 tex = texture(body_map, UV);
	float paint = tex.a;
	float crease = smoothstep(0.06, 0.28, dot(tex.rgb, vec3(1.0 / 3.0)));
	float metal = finish.x;
	vec3 col = mix(tex.rgb, instance_paint.rgb * mix(0.4, 1.0, crease), paint);
	// Flake: a per-texel roughness wobble, faded before it can shimmer.
	float fw = max(fwidth(UV.x), fwidth(UV.y)) * 2048.0;
	float flake = (snow_hash(floor(UV * 2048.0)) - 0.5) * (1.0 - smoothstep(0.5, 1.5, fw));
	float rough = mix(0.55, mix(0.36, 0.42, metal) + flake * 0.08 * metal, paint);
	float grime = finish.y * smoothstep(0.6, 0.12, body_y) * paint;
	col = mix(col, col * 0.62 + vec3(0.03, 0.026, 0.02), grime);
	rough = mix(rough, 0.72, grime);
	float snow = snow_cover(wpos, normalize(wnormal).y);
	ALBEDO = mix(col, snow_col, snow);
	ROUGHNESS = mix(rough, 0.86, snow);
	METALLIC = 0.45 * metal * paint * (1.0 - snow);
	SPECULAR = 0.5;
	AO = mix(1.0, mix(0.45, 1.0, crease), paint);
	CLEARCOAT = paint * (1.0 - grime * 0.8) * (1.0 - snow);
	CLEARCOAT_ROUGHNESS = 0.05 + grime * 0.35;
}
"""

## Ground darkening under a parked car: strongest under the floor pan,
## fading past the body's edges. Multiplies what is already drawn.
const SHADOW_CODE := """
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float strength = 0.5;
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
		sh.code = SHADOW_CODE
		_shadow = ShaderMaterial.new()
		_shadow.shader = sh
	return _shadow
