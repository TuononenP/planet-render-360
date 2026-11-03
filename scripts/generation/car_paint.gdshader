shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D body_map : source_color, filter_linear_mipmap, repeat_disable;
varying vec4 instance_paint;
void vertex() {
	instance_paint = COLOR;
}
void fragment() {
	vec4 tex = texture(body_map, UV);
	ALBEDO = mix(tex.rgb, tex.rgb * instance_paint.rgb, tex.a);
	ROUGHNESS = mix(0.55, 0.3, tex.a);
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
