class_name MarineLayer
extends MeshInstance3D

## Coastal fog as a layer lying on the sea (San Francisco's marine layer):
## thick over the water and the low streets, thinning toward TOP_M, clear
## above it, so hilltops, towers and the bridge towers stand out of it.
## Godot's height fog fogs every pixel below its height by the same
## amount at any distance (it greyed the kerb at the eye) and the
## volumetric medium stops at RenderQuality.VOLUME_LENGTH_M (never the
## bay), so the layer is drawn here: an inside-out box kept round the
## camera whose shader measures, per pixel, the stretch of the view ray
## inside the slab before it meets the scene (the depth buffer) and fogs
## by that length, a little patchy and drifting. AtmosphereRig shows it in
## fog weather at a coastal place, in place of the uniform fog.
## Forward+ / Mobile only (it reads the depth texture).

## Layer top above sea level (m), the thinning band under it, and the
## visibility inside it (m): Alcatraz, 2.8 km out, fades but stays a shape.
const TOP_M := 160.0
const SOFT_M := 70.0
const VISIBILITY_M := 1500.0

const CODE := """
shader_type spatial;
render_mode unshaded, cull_front, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float sea_y = 0.0;
uniform float top_y = 160.0;
uniform float soft = 70.0;
uniform float density = 0.002;
uniform float far_m = 20000.0;
uniform float amount = 0.0;
uniform vec3 fog_col : source_color = vec3(0.78, 0.80, 0.82);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Length of the ray (origin height y, direction dy) inside [lo, hi] before t_max.
float seg(float y, float dy, float lo, float hi, float t_max) {
	if (abs(dy) < 1e-5) {
		return (y >= lo && y <= hi) ? t_max : 0.0;
	}
	float ta = (lo - y) / dy;
	float tb = (hi - y) / dy;
	float t0 = max(min(ta, tb), 0.0);
	float t1 = min(max(ta, tb), t_max);
	return max(t1 - t0, 0.0);
}

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, max(depth, 1e-7), 1.0);
	view.xyz /= view.w;
	// Reverse-Z: the sky is at depth 0.
	float t_scene = depth <= 1e-6 ? far_m : min(length(view.xyz), far_m);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 dir = normalize((INV_VIEW_MATRIX * vec4(view.xyz, 0.0)).xyz);
	float core = seg(cam.y, dir.y, sea_y - 200.0, top_y - soft, t_scene);
	float thin = seg(cam.y, dir.y, top_y - soft, top_y, t_scene);
	// Patchy, drifting: one noise sample a third of the way along.
	vec2 at = (cam + dir * min(t_scene, 1500.0) * 0.33).xz;
	float n = noise(at / 700.0 + vec2(TIME * 0.004, TIME * 0.0015));
	float k = density * mix(0.65, 1.35, n);
	float a = 1.0 - exp(-k * (core + 0.4 * thin));
	ALBEDO = fog_col;
	ALPHA = clamp(a * amount, 0.0, 1.0);
}
"""

var _mat: ShaderMaterial

func _init() -> void:
	name = "MarineLayer"
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 2.0
	mesh = box
	var sh := Shader.new()
	sh.code = CODE
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 16384.0
	visible = false

## Sea level in render Y (GroundTruth.render_y(0)) and units per metre.
func set_sea(sea_y: float, units_per_metre: float) -> void:
	_mat.set_shader_parameter("sea_y", sea_y)
	_mat.set_shader_parameter("top_y", sea_y + TOP_M * units_per_metre)
	_mat.set_shader_parameter("soft", SOFT_M * units_per_metre)
	_mat.set_shader_parameter("density", 3.0 / (VISIBILITY_M * units_per_metre))

## Shown (0..1) in the haze colour; hidden at 0.
func set_amount(amount: float, colour: Color) -> void:
	visible = amount > 0.0 and RenderingServer.get_current_rendering_method() != "gl_compatibility"
	_mat.set_shader_parameter("amount", amount)
	_mat.set_shader_parameter("fog_col", colour)

## The box stays round the camera, inside its far plane.
func _process(_delta: float) -> void:
	if not visible:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var half := cam.far * 0.5
	global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * half), cam.global_position)
	_mat.set_shader_parameter("far_m", half)
