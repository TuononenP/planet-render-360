class_name LandmarkShader
extends RefCounted

## Desktop-Ultra landmark surfaces. On Forward+ Ultra every calibrated
## landmark material (LandmarkMaterials.pbr, meta META) is swapped for a
## shader reading the same photo set and tint and adding what a tiled
## photo cannot hold, in the model's own metres (y = 0 at its ground):
##   - weathering: a damp, dirty band at the foot with a ragged top edge,
##     rain streaks down the walls, dirt and lichen on ledges and other
##     upward faces, darker soffits and arch vaults (sky occlusion);
##   - tone: monument-scale hue and value drift and metre-scale blotches,
##     so a 100 m wall does not repeat its tile; featureless sets are
##     also blended with a turned, rescaled copy of themselves;
##   - ashlar: limestone (a near-flat photo) is coursed into blocks, each
##     with its own tone, with sunk joints that fade before they alias;
##   - metal: the concrete grain under painted iron and copper loses its
##     formwork boards, gains pitting, and runs with rust or verdigris;
##   - millimetre detail: a second, finer normal sample up close.
## Glass, glow and the hand-made tile maps keep their standard materials,
## as do lower tiers and Mobile (enabled()).

const META := "landmark_set"

## Photo sets with no pattern of their own: blending a turned copy breaks
## their repeat (on brick, slate or boards it would cross the courses).
const ANTI_TILE: Array[String] = ["limestone", "render", "sand", "gravel", "lawn", "grass",
	"rock", "cliff", "forest", "asphalt", "membrane"]
## Ground covers inside a landmark's site: tone only, no weathering.
const GROUND: Array[String] = ["lawn", "grass", "sand", "gravel", "rock", "cliff", "forest",
	"asphalt", "pavement"]

## Surface kinds (the shader's `kind`).
enum Kind { BUILT, ASHLAR, METAL, GROUND }

const SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_rough_tex = true;
uniform float roughness = 1.0;
uniform float metallic = 0.0;
// UVs are metres (LandmarkMesh); one photo tile every 1 / uv_scale m.
uniform float uv_scale = 0.25;
uniform int kind = 0;
uniform bool anti_tile = false;
uniform float grime = 1.0;
// Linear colour of the runs down a metal (rust, verdigris, soot).
uniform vec3 runs = vec3(0.1);
// A part's height above the model's ground when its node is lifted.
instance uniform float lift = 0.0;

varying vec3 lpos;
varying vec3 wnrm;

float h12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float h13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h12(i), h12(i + vec2(1.0, 0.0)), u.x),
		mix(h12(i + vec2(0.0, 1.0)), h12(i + vec2(1.0, 1.0)), u.x), u.y);
}
float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h13(i), h13(i + vec3(1.0, 0.0, 0.0)), u.x),
		mix(h13(i + vec3(0.0, 1.0, 0.0)), h13(i + vec3(1.0, 1.0, 0.0)), u.x), u.y);
	float b = mix(mix(h13(i + vec3(0.0, 0.0, 1.0)), h13(i + vec3(1.0, 0.0, 1.0)), u.x),
		mix(h13(i + vec3(0.0, 1.0, 1.0)), h13(i + vec3(1.0, 1.0, 1.0)), u.x), u.y);
	return mix(a, b, u.z);
}
float fbm3(vec3 p) {
	return 0.5 * vnoise3(p) + 0.3 * vnoise3(p * 2.03 + 17.1) + 0.2 * vnoise3(p * 4.11 + 3.7);
}

void vertex() {
	lpos = VERTEX + vec3(0.0, lift, 0.0);
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uvm = UV;
	vec2 uv = uvm * uv_scale;
	vec3 p = lpos;
	vec3 n = normalize(wnrm);
	float up = n.y;
	bool ground = kind == 3;
	bool metal = kind == 2;

	vec3 tex = texture(albedo_tex, uv).rgb;
	// The tile's mean (its last mip), for re-centring grain on the tint.
	vec3 mean = max(textureLod(albedo_tex, vec2(0.5), 14.0).rgb, vec3(0.01));
	if (anti_tile) {
		vec2 uv2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * uv * 0.43 + vec2(0.37, 0.71);
		float w = smoothstep(0.3, 0.7, fbm3(p * 0.21));
		tex = mix(tex, texture(albedo_tex, uv2).rgb, w);
		// The whole set again at a tenth of its tile: patches of one
		// tile's darker and lighter areas, a few metres across.
		vec3 macro = textureLod(albedo_tex, uv * 0.11 + 0.5, 3.0).rgb / mean;
		tex *= mix(vec3(1.0), clamp(macro, vec3(0.75), vec3(1.3)), 0.6);
	}
	if (metal) {
		// Concrete grain stands in for paint over iron: keep its pitting,
		// not its board marks.
		tex = mix(mean, tex, 0.3) * mix(0.9, 1.07, vnoise3(p * 3.1));
	}
	vec3 alb = tex * tint.rgb;

	// Tone: monument-scale drift, metre-scale blotches, a warm/cool swing.
	float m1 = fbm3(p * 0.06);
	float m2 = vnoise3(p * 0.55 + 9.0);
	float m3 = vnoise3(p * 0.045 + 41.0);
	float spread = ground ? 0.6 : 1.0;
	alb *= mix(1.0, mix(0.8, 1.12, m1) * mix(0.9, 1.06, m2), spread);
	alb *= mix(vec3(1.035, 1.0, 0.955), vec3(0.97, 1.0, 1.03), m3);

	vec2 joint_n = vec2(0.0);
	float joint = 0.0;
	float block = 0.5;
	if (kind == 1) {
		// Ashlar: courses 0.55 m, blocks 1.0-1.6 m, each course shifted.
		vec2 b = uvm / vec2(1.25, 0.55);
		float row = floor(b.y);
		b.x += h12(vec2(row, 3.0)) * 0.9 + row * 0.5;
		vec2 cell = floor(b);
		vec2 f = fract(b);
		block = h12(cell + 0.5);
		alb *= mix(0.9, 1.08, block) * mix(vec3(1.0), vec3(1.03, 1.0, 0.96), h12(cell + 7.3));
		vec2 fw = max(fwidth(b), vec2(1e-5));
		vec2 jw = vec2(0.012 / 1.25, 0.012 / 0.55);
		vec2 d = min(f, 1.0 - f);
		vec2 j = vec2(1.0) - smoothstep(jw, jw + fw, d);
		// Joints fade out below ~3 px a block, before they alias.
		float keep = 1.0 - smoothstep(0.12, 0.35, max(fw.x, fw.y));
		joint = max(j.x, j.y) * keep;
		alb *= 1.0 - 0.3 * joint;
		// Arrises dip into the joint: a narrow bevel either side.
		vec2 bev = (vec2(1.0) - smoothstep(jw, jw * 3.5 + fw, d)) * keep;
		joint_n = vec2(sign(0.5 - f.x) * bev.x, -sign(0.5 - f.y) * bev.y) * 0.35;
	}

	float vert = 1.0 - smoothstep(0.35, 0.75, abs(up));
	vec2 along_v = vec2(-n.z, n.x);
	float along = dot(p.xz, along_v / max(length(along_v), 1e-3));
	float dirt = 0.0;
	float ao = 1.0;
	if (!ground) {
		// Rising damp and splash dirt at the foot, ragged top edge.
		float edge = 2.0 + 3.5 * vnoise3(vec3(p.x, 0.0, p.z) * 0.3 + 5.0);
		float foot = 1.0 - smoothstep(0.0, edge, p.y);
		alb = mix(alb, alb * vec3(0.55, 0.53, 0.48), foot * 0.8 * grime);
		// Soot and traffic dirt thin out with height; tops weather paler.
		alb *= mix(0.84, 1.03, smoothstep(0.0, 35.0, p.y) * (0.7 + 0.3 * m1));
		dirt += foot;
		// Rain runs: broad streaks a metre or two across, finer ones in them.
		float s1 = vnoise(vec2(along * 0.38, p.y * 0.03 + 3.0));
		float s2 = vnoise(vec2(along * 2.3, p.y * 0.12 + 11.0));
		float streak = smoothstep(0.5, 0.92, s1) * 0.6 + smoothstep(0.55, 0.95, s2) * 0.5;
		streak *= vert;
		if (metal) {
			alb = mix(alb, runs, clamp(streak, 0.0, 1.0) * 0.55 * grime);
		} else {
			alb *= 1.0 - 0.36 * clamp(streak, 0.0, 1.0) * grime;
		}
		dirt += streak * 0.5;
		// Dirt and lichen settle on ledges, copings and gentle roofs.
		float top = smoothstep(0.5, 0.9, up);
		float lich = fbm3(p * 0.8 + 2.0);
		vec3 settled = metal ? alb * 0.82 : alb * vec3(0.74, 0.77, 0.66);
		alb = mix(alb, settled, top * (0.25 + 0.5 * lich) * grime);
		dirt += top * lich;
		// Soffits, vaults and the undersides of cornices see little sky.
		ao = 1.0 - 0.5 * smoothstep(-0.15, -0.8, up);
		// Deep in a big monument the walls see less sky than at its top.
		ao *= mix(0.82, 1.0, smoothstep(0.0, 12.0, p.y));
	}
	ALBEDO = clamp(alb, vec3(0.0), vec3(1.0));
	AO = ao;
	AO_LIGHT_AFFECT = 0.0;

	float r = has_rough_tex ? texture(rough_tex, uv).r : roughness;
	r *= mix(0.88, 1.12, m2);
	r += 0.1 * clamp(dirt, 0.0, 1.0) * grime + 0.15 * joint + (block - 0.5) * 0.06;
	ROUGHNESS = clamp(r, 0.05, 1.0);
	METALLIC = metallic * (1.0 - 0.5 * clamp(dirt, 0.0, 1.0) * grime);

	vec3 nm = texture(normal_tex, uv).rgb;
	vec2 nxy = nm.xy * 2.0 - 1.0;
	if (metal) {
		nxy *= 0.35;
	}
	// Millimetre grain up close; the mip chain flattens it with distance.
	vec2 fine = texture(normal_tex, uv * 3.7 + vec2(0.21, 0.63)).rg * 2.0 - 1.0;
	nxy += fine * (metal ? 0.15 : 0.45) + joint_n;
	// Godot rebuilds z from xy: keep the sum inside the unit disc.
	nxy *= min(1.0, 0.92 / max(length(nxy), 1e-4));
	NORMAL_MAP = vec3(nxy * 0.5 + 0.5, 1.0);
}
"""

static var _shader: Shader
static var _swapped: Dictionary = {}
static var _mutex := Mutex.new()

static func shader() -> Shader:
	_mutex.lock()
	if _shader == null:
		var sh := Shader.new()
		sh.code = SHADER
		_shader = sh
	var ret := _shader
	_mutex.unlock()
	return ret

## Ultra on Forward+ only, like FacadeShader.
static func enabled(preset: int, forward_plus: bool = RenderQuality.is_forward_plus()) -> bool:
	return RenderQuality.ultra_desktop(preset, forward_plus)

## Swaps every calibrated landmark material under `root` (a
## LandmarkBuilder model) for its shader counterpart, as a surface
## override so the meshes stay untouched. Surfaces that already carry an
## override (LandmarkLights' night glow) keep it. Returns the number of
## surfaces swapped.
static func upgrade(root: Node3D) -> int:
	var count := 0
	for mi in LandmarkBuilder.parts(root):
		if mi.mesh == null:
			continue
		var lift := _lift(mi)
		var used := false
		for s in mi.mesh.get_surface_count():
			if mi.get_surface_override_material(s) != null:
				continue
			var m := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if m == null or not m.has_meta(META) or m.emission_enabled:
				continue
			mi.set_surface_override_material(s, swap(m))
			used = true
			count += 1
		if used and absf(lift) > 0.001:
			mi.set_instance_shader_parameter("lift", lift)
	return count

## The shared shader material for landmark material `m`.
static func swap(m: StandardMaterial3D) -> ShaderMaterial:
	_mutex.lock()
	var s: ShaderMaterial = _swapped.get(m)
	if s == null:
		s = from_standard(m)
		_swapped[m] = s
	_mutex.unlock()
	return s

static func from_standard(m: StandardMaterial3D) -> ShaderMaterial:
	var s := ShaderMaterial.new()
	s.shader = shader()
	var set_name := str(m.get_meta(META))
	s.set_shader_parameter("albedo_tex", m.albedo_texture)
	s.set_shader_parameter("tint", m.albedo_color)
	s.set_shader_parameter("normal_tex", m.normal_texture)
	s.set_shader_parameter("has_rough_tex", m.roughness_texture != null)
	if m.roughness_texture != null:
		s.set_shader_parameter("rough_tex", m.roughness_texture)
	s.set_shader_parameter("roughness", m.roughness)
	s.set_shader_parameter("metallic", m.metallic)
	s.set_shader_parameter("uv_scale", m.uv1_scale.x)
	s.set_shader_parameter("anti_tile", set_name in ANTI_TILE)
	var colour := Color(str(m.get_meta("landmark_hex", "#808080")))
	var kind := kind_for(set_name, m.metallic)
	s.set_shader_parameter("kind", kind)
	# Gilding and polished metal stay bright; the rest weathers fully.
	s.set_shader_parameter("grime", 0.3 if m.metallic > 0.6 else 1.0)
	s.set_shader_parameter("runs", _runs(colour))
	s.set_meta(META, set_name)
	return s

static func kind_for(set_name: String, metallic: float) -> Kind:
	if set_name in GROUND:
		return Kind.GROUND
	if metallic > 0.1:
		return Kind.METAL
	if set_name == "limestone":
		return Kind.ASHLAR
	return Kind.BUILT

## Colour (linear) of the runs down a metal of sRGB `c`: pale verdigris
## blooms on green copper, rust on painted iron, soot on the rest.
static func _runs(c: Color) -> Color:
	if c.g > c.r * 1.1 and c.g >= c.b:
		return Color("#8DB8A4").srgb_to_linear()
	if c.r > c.b * 1.3:
		return Color("#5E3B26").srgb_to_linear()
	return (c * 0.55).srgb_to_linear()

## A part's height above the model's ground (its offset under "Model").
static func _lift(mi: MeshInstance3D) -> float:
	var y := 0.0
	var n: Node = mi
	while n is Node3D and n.name != "Model":
		y += (n as Node3D).position.y
		n = n.get_parent()
	return y
