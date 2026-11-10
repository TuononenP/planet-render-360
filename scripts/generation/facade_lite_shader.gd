class_name FacadeLiteShader
extends RefCounted

## Per-floor night lights on Forward+ Balanced and High. The facade tile
## covers one storey and StandardMaterial3D's emission shares its UVs, so a
## lit bay repeated up the whole wall as a vertical stripe. This material
## keeps the Standard emit map but switches it per bay and storey, with a
## mask that averages 1: the same windows, the same mean glow, no stripes.
##
## By day it must match the StandardMaterial3D it replaces (AC-12): paint
## mixes over the tint and vertex colour, the order Godot's own material uses,
## which is not FacadeShader's order. It adds the night mask and nothing else:
## no parallax, rooms or weathering, those stay Ultra's.

## Share of window cells left lit, and the glow an unlit cell keeps (a lamp
## deeper in the room). The mask is normalised so its mean is 1.
const LIT_SHARE := 0.55
const DARK_GLOW := 0.12

const CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paint_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D emit_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool has_paint = false;
uniform bool has_normal = false;
uniform bool has_depth = false;
uniform bool has_emit = false;
uniform float normal_depth = 0.7;
uniform float roughness_value = 0.9;
uniform float metallic_value = 0.0;
uniform float specular_value = 0.5;
uniform bool curtain_wall = false;
uniform vec2 cells = vec2(4.0, 1.0);
uniform float night_energy = 0.0;
varying vec3 wpos;

float h13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb * tint.rgb * COLOR.rgb;
	if (has_paint) {
		vec4 p = texture(paint_tex, UV);
		base = mix(base, p.rgb, p.a);
	}
	ALBEDO = base;
	float rough = roughness_value;
	if (has_normal) {
		rough = texture(rough_tex, UV).r * roughness_value;
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_depth;
	}
	ROUGHNESS = rough;
	METALLIC = metallic_value;
	SPECULAR = specular_value;
	if (has_emit && night_energy > 0.001) {
		// Shared walls have few tints, so the seed also takes the ground cell.
		float bld = floor(wpos.x / 37.0) * 7.0 + floor(wpos.z / 37.0) * 13.0 + floor(COLOR.g * 31.0);
		vec2 cg = UV * cells;
		float bay_px = max(length(dFdx(cg)), length(dFdy(cg)));
		vec2 cell = floor(cg);
		// Offices light a floor in stretches of five bays, homes room by room.
		vec2 lc = curtain_wall ? vec2(floor(cell.x / 5.0), cell.y) : cell;
		float on = step(h13(vec3(lc + 0.37, bld + 11.0)), 0.55);
		float k = mix(0.12, 1.0, on) / mix(0.12, 1.0, 0.55);
		// Windows under about two pixels keep the map's own glow: picked one
		// by one they alias to speckle on the skyline.
		k = mix(k, 1.0, smoothstep(0.25, 0.7, bay_px));
		EMISSION = texture(emit_tex, UV).rgb * night_energy * k;
	}
}
"""

static var _shader: Shader
static var _mutex := Mutex.new()

## Forward+ below Ultra, which has its own facade shader. Headless builds
## (the dummy renderer reports forward_plus) keep StandardMaterial3D: they draw
## nothing and cache nothing (WorldCache), and their tests read Standard facades.
static func enabled(preset: int,
		forward_plus: bool = RenderQuality.is_forward_plus() and DisplayServer.get_name() != "headless") -> bool:
	var p := RenderSettings.clamp_preset(preset)
	return forward_plus and p in [RenderSettings.Preset.BALANCED, RenderSettings.Preset.HIGH]

static func shader() -> Shader:
	_mutex.lock()
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var s := _shader
	_mutex.unlock()
	return s

## Swaps every lit facade material under `root`, once per material.
static func upgrade(root: Node) -> int:
	var done := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if eligible(mi.material_override):
			mi.material_override = _swap(mi.material_override as StandardMaterial3D, done)
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			if eligible(m):
				mi.mesh.surface_set_material(s, _swap(m as StandardMaterial3D, done))
	return done.size()

## The night mask's weight for a lit (`on`) or unlit cell; LIT_SHARE of
## cells lit, so the weights average 1 (the shader's k).
static func mask(on: bool) -> float:
	return (1.0 if on else DARK_GLOW) / lerpf(DARK_GLOW, 1.0, LIT_SHARE)

## A facade with a night map: the albedo-only tier has none to replace.
static func eligible(m: Material) -> bool:
	return m is StandardMaterial3D and m.has_meta("facade_set") and m.has_meta(CityLights.META)

static func _swap(m: StandardMaterial3D, done: Dictionary) -> ShaderMaterial:
	if done.has(m):
		return done[m] as ShaderMaterial
	var s := from_standard(m)
	done[m] = s
	return s

static func from_standard(m: StandardMaterial3D) -> ShaderMaterial:
	var s := ShaderMaterial.new()
	s.shader = shader()
	s.set_shader_parameter("albedo_tex", m.albedo_texture)
	s.set_shader_parameter("tint", m.albedo_color)
	s.set_shader_parameter("has_paint", m.detail_enabled and m.detail_albedo != null)
	if m.detail_enabled and m.detail_albedo != null:
		s.set_shader_parameter("paint_tex", m.detail_albedo)
	var has_normal := m.normal_enabled and m.normal_texture != null and m.roughness_texture != null
	s.set_shader_parameter("has_normal", has_normal)
	# No reveals here; set, so readers that test it get false, not null.
	s.set_shader_parameter("has_depth", false)
	if has_normal:
		s.set_shader_parameter("normal_tex", m.normal_texture)
		s.set_shader_parameter("rough_tex", m.roughness_texture)
		s.set_shader_parameter("normal_depth", m.normal_scale)
	# Standard's multiply emission with a white colour: the map x energy.
	var has_emit := m.emission_enabled and m.emission_texture != null
	s.set_shader_parameter("has_emit", has_emit)
	if has_emit:
		s.set_shader_parameter("emit_tex", m.emission_texture)
	s.set_shader_parameter("roughness_value", m.roughness)
	s.set_shader_parameter("metallic_value", m.metallic)
	s.set_shader_parameter("specular_value", m.metallic_specular)
	var set_name := str(m.get_meta("facade_set"))
	s.set_shader_parameter("curtain_wall", set_name == "glass")
	s.set_shader_parameter("cells", grid_for(m))
	s.set_shader_parameter("night_energy", 0.0)
	for k in m.get_meta_list():
		if k != "facade_set":
			s.set_meta(k, m.get_meta(k))
	s.set_meta("facade_lite", set_name)
	return s

## Window cells across one texture repeat: bays by storeys. A tiled look holds
## one storey; the Paris facade its rows of bays; legacy glass an 8 x 8 grid.
static func grid_for(m: StandardMaterial3D) -> Vector2:
	var uvp := FacadeTextures.facade_uv(m)
	if uvp.z > 0.0:
		return Vector2(uvp.y, 1.0)
	if int(m.get_meta("facade_rows", 0)) <= 0:
		return Vector2(8.0, 8.0)
	return Vector2(float(StoreyComposer.PARIS_BAYS), float(m.get_meta("facade_rows")))
