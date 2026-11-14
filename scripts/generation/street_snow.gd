class_name StreetSnow
extends RefCounted

## Live, upward-facing snow on cars, furniture and kerbs. Uses the same
## climate globals as terrain, preserving the original material's colour,
## texture and roughness. Instance colour keeps the parked-car paint.
const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
// @SNOW
uniform vec4 base_col : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color;
uniform sampler2D normal_tex : hint_normal;
uniform sampler2D rough_tex;
uniform bool use_normal = false;
uniform bool use_rough = false;
uniform float normal_scale = 1.0;
uniform vec2 uv_scale = vec2(1.0);
uniform bool use_tex = false;
uniform bool use_vertex = false;
uniform float base_roughness = 0.7;
uniform float base_metallic = 0.0;
// 0 fresh snow .. 1 grey, ploughed or trodden (StreetSnow.material).
uniform float age = 0.0;
varying vec3 wpos;
varying vec3 wnormal;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 col = base_col.rgb;
	if (use_tex) { col *= texture(albedo_tex, uv).rgb; }
	if (use_vertex) { col *= COLOR.rgb; }
	float snow = snow_cover(wpos, normalize(wnormal).y);
	// A cap a few centimetres thick ends in a rounded lip on a car roof
	// or a bench (derivatives first).
	vec3 lip = snow_edge(snow, wpos, 0.04);
	float px = max(fwidth(wpos.x), fwidth(wpos.z));
	// Older snow (kerbs, ploughed banks) carries road grit.
	// The street's slush and salt up the sides of kerbs, plinths and cars.
	col = apply_splash(col, snow_splash(wpos) * (1.0 - smoothstep(0.3, 0.6, abs(normalize(wnormal).y))));
	ALBEDO = mix(col, snow_grit(snow_albedo(wpos.xz, px, age), wpos.xz, px, age), snow);
	float roughness = base_roughness;
	if (use_rough) { roughness *= texture(rough_tex, uv).r; }
	ROUGHNESS = mix(roughness, SNOW_ROUGH, snow);
	if (use_normal) {
		NORMAL_MAP = mix(texture(normal_tex, uv).rgb, vec3(0.5, 0.5, 1.0), snow);
		NORMAL_MAP_DEPTH = normal_scale;
	}
	vec3 wn = normalize(wnormal);
	if (snow > 0.0 && wn.y > 0.4) {
		// Wind-sculpted, never a moulded shell: drift relief near by.
		vec2 dr = snow_drift(wpos.xz * 2.5) * 0.12 * (1.0 - smoothstep(0.02, 0.2, px));
		vec3 sn = normalize(wn - vec3(lip.x + dr.x, 0.0, lip.y + dr.y));
		NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(sn, 0.0)).xyz, snow));
	}
	METALLIC = base_metallic * (1.0 - snow);
	SPECULAR = mix(0.5, SNOW_SPEC, snow);
	RIM = SNOW_RIM * snow;
	RIM_TINT = SNOW_RIM_TINT;
}
"""
static var _shader: Shader

static func material(source: StandardMaterial3D, age: float = 0.0) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("base_col", source.albedo_color)
	mat.set_shader_parameter("use_tex", source.albedo_texture != null)
	if source.albedo_texture != null:
		mat.set_shader_parameter("albedo_tex", source.albedo_texture)
	mat.set_shader_parameter("uv_scale", Vector2(source.uv1_scale.x, source.uv1_scale.y))
	mat.set_shader_parameter("use_normal", source.normal_enabled and source.normal_texture != null)
	if source.normal_enabled and source.normal_texture != null:
		mat.set_shader_parameter("normal_tex", source.normal_texture)
		mat.set_shader_parameter("normal_scale", source.normal_scale)
	mat.set_shader_parameter("use_rough", source.roughness_texture != null)
	if source.roughness_texture != null:
		mat.set_shader_parameter("rough_tex", source.roughness_texture)
	mat.set_shader_parameter("use_vertex", source.vertex_color_use_as_albedo)
	mat.set_shader_parameter("base_roughness", source.roughness)
	mat.set_shader_parameter("base_metallic", source.metallic)
	mat.set_shader_parameter("age", age)
	return mat
