class_name LandmarkSfAlcatrazSurface
extends RefCounted

## Continuous PBR transitions on the authored rock: slope blends grass
## into cliff, and level summit ground into gravel. Triplanar cliff
## mapping avoids stretched textures and triangle-shaped material seams.

const CODE := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D yard_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_rough : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_rough : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 grass_tint : source_color;
uniform vec4 rock_tint : source_color;
uniform vec4 yard_tint : source_color;
varying vec3 model_pos;
varying vec3 model_normal;
void vertex() {
	model_pos = VERTEX;
	model_normal = NORMAL;
}
void fragment() {
	vec3 n = normalize(model_normal);
	vec3 weights = pow(abs(n), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec2 gx = model_pos.xz / 4.0;
	vec2 rx = model_pos.zy / 6.0;
	vec2 ry = model_pos.xz / 6.0;
	vec2 rz = model_pos.xy / 6.0;
	vec3 rock = (texture(rock_albedo, rx).rgb * weights.x
		+ texture(rock_albedo, ry).rgb * weights.y
		+ texture(rock_albedo, rz).rgb * weights.z) * rock_tint.rgb;
	vec3 grass = texture(grass_albedo, gx).rgb * grass_tint.rgb;
	vec3 yard = texture(yard_albedo, model_pos.xz / 3.0).rgb * yard_tint.rgb;
	float cliff = 1.0 - smoothstep(0.55, 0.92, n.y);
	float summit = smoothstep(-99.0, -93.0, model_pos.x)
		* (1.0 - smoothstep(98.0, 104.0, model_pos.x))
		* (1.0 - smoothstep(48.0, 54.0, abs(model_pos.z)))
		* smoothstep(31.0, 37.0, model_pos.y) * smoothstep(0.88, 0.98, n.y);
	ALBEDO = mix(mix(grass, yard, summit), rock, cliff);
	float rr = texture(rock_rough, rx).r * weights.x
		+ texture(rock_rough, ry).r * weights.y
		+ texture(rock_rough, rz).r * weights.z;
	ROUGHNESS = clamp(mix(texture(grass_rough, gx).r, rr, cliff), 0.65, 1.0);
	NORMAL_MAP = mix(texture(grass_normal, gx).rgb, texture(rock_normal, rx).rgb, cliff);
	NORMAL_MAP_DEPTH = 0.65;
	SPECULAR = 0.2;
}
"""

static var _material: ShaderMaterial

static func material() -> ShaderMaterial:
	if _material != null:
		return _material
	var shader := Shader.new()
	shader.code = CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	for entry in [["grass", "grass", "#666A43"], ["rock", "cliff", "#7B7165"], ["yard", "gravel", "#85816F"]]:
		var key: String = entry[0]
		var set_name: String = entry[1]
		mat.set_shader_parameter(key + "_albedo", LandmarkMaterials.tex(set_name, "diff"))
		mat.set_shader_parameter(key + "_tint", LandmarkMaterials.tint(set_name, entry[2]))
		if key != "yard":
			mat.set_shader_parameter(key + "_normal", LandmarkMaterials.tex(set_name, "nor"))
			mat.set_shader_parameter(key + "_rough", LandmarkMaterials.tex(set_name, "rough"))
	_material = mat
	return mat
