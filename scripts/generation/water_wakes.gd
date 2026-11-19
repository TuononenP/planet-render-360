class_name WaterWakes
extends RefCounted

## Animated vessel V-wakes and hull waterline foam collars on water.
## Rendered as lightweight transparent quads just above the water plane
## (depth_draw_never, no shadows), so main water keeps depth_draw_opaque
## and full Forward+ SSR reflections. Fades out automatically on ice.

const LIFT_M := 0.04

## Kelvin V-wake + turbulent stern foam trail behind an underway vessel.
## Quad UV: x = 1 at bow (+X) .. 0 behind stern (-X); y = 0..1 across wake width.
const WAKE_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, diffuse_lambert;
// @SNOW
varying vec3 wpos;

float wk_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float wk_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(wk_hash(i), wk_hash(i + vec2(1.0, 0.0)), f.x),
		mix(wk_hash(i + vec2(0.0, 1.0)), wk_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dist = length(wpos - CAMERA_POSITION_WORLD);
	float dfade = (1.0 - smoothstep(450.0, 1400.0, dist)) * (1.0 - climate_water_ice);
	if (dfade < 0.01) {
		discard;
	}
	float u = 1.0 - UV.x;
	float v = abs(UV.y - 0.5) * 2.0;
	// Kelvin arm opens at ~19.5 deg behind the bow; stern boil fills the core.
	float arm_pos = clamp(0.14 + u * 0.78, 0.0, 0.96);
	float arm = exp(-pow((v - arm_pos) / (0.045 + u * 0.07), 2.0)) * smoothstep(0.04, 0.18, u);
	float crest = 0.55 + 0.45 * sin(u * 34.0 - TIME * 4.2 - v * 10.0);
	float core = exp(-pow(v / (0.14 + u * 0.16), 2.0)) * smoothstep(0.28, 0.40, u) * 0.65;
	vec2 flow = vec2(u * 14.0 - TIME * 1.4, UV.y * 8.0);
	float lace = smoothstep(0.32, 0.84, wk_noise(flow) * 0.65 + wk_noise(flow * 2.7 + 3.1) * 0.35);
	float fade_tail = (1.0 - smoothstep(0.55, 1.0, u)) * (1.0 - smoothstep(0.75, 1.0, v));
	float alpha = clamp((arm * crest + core) * lace * fade_tail * 0.78, 0.0, 0.82) * dfade;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = vec3(0.84, 0.87, 0.88);
	ALPHA = alpha;
	ROUGHNESS = 0.52;
	SPECULAR = 0.25;
}
"""

## Subtle lapping foam collar around a moored or slow vessel's hull.
const COLLAR_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, diffuse_lambert;
// @SNOW
varying vec3 wpos;

float cl_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float cl_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(cl_hash(i), cl_hash(i + vec2(1.0, 0.0)), f.x),
		mix(cl_hash(i + vec2(0.0, 1.0)), cl_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dist = length(wpos - CAMERA_POSITION_WORLD);
	float dfade = (1.0 - smoothstep(260.0, 850.0, dist)) * (1.0 - climate_water_ice);
	if (dfade < 0.01) {
		discard;
	}
	// Elliptical hull distance: 0.72 is the hull waterline, 1.0 outer ripple edge.
	vec2 q = (UV - 0.5) * 2.0;
	float r = length(q);
	float ring = smoothstep(0.58, 0.74, r) * (1.0 - smoothstep(0.76, 1.0, r));
	float pulse = 0.5 + 0.5 * sin(r * 22.0 - TIME * 1.8 + cl_noise(wpos.xz * 0.25) * 5.0);
	float brk = smoothstep(0.38, 0.82, cl_noise(wpos.xz * 0.8 + vec2(TIME * 0.12, -TIME * 0.09)) * 0.65
		+ cl_noise(wpos.xz * 2.4) * 0.35);
	float alpha = ring * mix(0.45, 1.0, pulse) * brk * 0.45 * dfade;
	if (alpha < 0.01) {
		discard;
	}
	ALBEDO = vec3(0.84, 0.87, 0.88);
	ALPHA = alpha;
	ROUGHNESS = 0.5;
	SPECULAR = 0.25;
}
"""

static var _wake_mat: ShaderMaterial
static var _collar_mat: ShaderMaterial

static func wake_material() -> ShaderMaterial:
	if _wake_mat == null:
		var sh := Shader.new()
		sh.code = WAKE_CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		_wake_mat = ShaderMaterial.new()
		_wake_mat.shader = sh
		_wake_mat.render_priority = 1
	return _wake_mat

static func collar_material() -> ShaderMaterial:
	if _collar_mat == null:
		var sh := Shader.new()
		sh.code = COLLAR_CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		_collar_mat = ShaderMaterial.new()
		_collar_mat.shader = sh
		_collar_mat.render_priority = 1
	return _collar_mat

## Adds an animated Kelvin V-wake behind an underway vessel (+X bow) at `pos`.
static func add_wake(root: Node3D, pos: Vector3, yaw: float, length_u: float, beam_u: float) -> MeshInstance3D:
	var wake_len := length_u * 2.4
	var wake_w := maxf(beam_u * 2.6, length_u * 0.55)
	var plane := PlaneMesh.new()
	plane.size = Vector2(wake_len, wake_w)
	# Vessel faces +X in its local frame; wake trails toward -X from near the bow.
	plane.center_offset = Vector3(length_u * 0.45 - wake_len * 0.5, LIFT_M * WorldScale.metres_to_units(), 0.0)
	var mi := MeshInstance3D.new()
	mi.name = "VesselWake"
	mi.mesh = plane
	mi.material_override = wake_material()
	mi.position = pos
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi

## Adds a subtle lapping waterline collar around a mapped vessel at `pos`.
static func add_collar(root: Node3D, pos: Vector3, yaw: float, length_u: float, beam_u: float) -> MeshInstance3D:
	var pad := clampf(beam_u * 0.35, 1.2, 5.0) * WorldScale.metres_to_units()
	var plane := PlaneMesh.new()
	plane.size = Vector2(length_u + pad * 2.0, beam_u + pad * 2.0)
	plane.center_offset = Vector3(0.0, LIFT_M * WorldScale.metres_to_units(), 0.0)
	var mi := MeshInstance3D.new()
	mi.name = "VesselCollar"
	mi.mesh = plane
	mi.material_override = collar_material()
	mi.position = pos
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi

## Adds waterline foam collars for every mapped vessel in `data` on High/Ultra.
static func build_mapped_collars(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if data == null or ground == null or data.quality_preset < RenderSettings.Preset.HIGH:
		return 0
	var sea := WaterBuilder._has_coastline(data) or LandmarkTerrain.has_sea(data)
	var count := 0
	for b in data.buildings:
		if not (b is Dictionary) or not ShipBuilder.accepts(b):
			continue
		var f := ShipBuilder.frame(b)
		var at: Vector2 = f["centre"]
		if not ground.is_inside(at.x, at.y):
			continue
		var fallback := ground.render_y(0.0) if sea else ground.height_at_world(at.x, at.y)
		var y := ground.water_level_at(at.x, at.y, fallback)
		var yaw := atan2(-(f["axis"] as Vector2).y, (f["axis"] as Vector2).x)
		add_collar(root, Vector3(at.x, y, at.y), yaw, float(f["length"]), float(f["beam"]))
		count += 1
	return count
