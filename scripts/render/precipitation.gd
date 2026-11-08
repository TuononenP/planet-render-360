class_name Precipitation
extends GPUParticles3D

## Falling rain and snow around the viewpoint, for ViewConditions.
##
## Near field: GPU particles at real fall speeds (rain 3.5-9 m/s, snow
## about 1 m/s, no acceleration: both fall at terminal velocity) with a
## shader that turns each one to the camera about its own fall line.
## Streaks narrower than a pixel are widened and dimmed by the same
## ratio, so distant rain keeps its brightness instead of crawling.
## Each one lives for a few metres of fall and fades in and out, so none
## pops in view and few are spent underground.
## Depth: two cylinders of scrolling streaks or flakes further out give
## the sheets of weather a particle box cannot reach (High and Ultra).
##
## The camera rig turns with the view, but weather does not: the system
## follows the eye's position only, so drops keep falling down the world
## and the far sheets stay put as the view pans.
##
## Fall speed, drop size and density follow WeatherLook.particle_params.
## Rain and snow take the sky's horizon colour, so they stay the level of
## the light they scatter: bright in a pale deck, faint at night.

## Particle budget per preset: Fast, Balanced, High, Ultra.
const AMOUNT := [800, 1300, 2400, 3600]
## Half-extents (m) of the emission box around the eye.
const RAIN_BOX := Vector3(18.0, 12.0, 18.0)
const SNOW_BOX := Vector3(20.0, 9.0, 20.0)
## Metres each particle falls before it fades out.
const RAIN_TRAVEL_M := 8.0
const SNOW_TRAVEL_M := 7.0
## The box stands this far above the eye: weather comes from above.
const BOX_UP_M := 8.0
## Veil cylinders: radius (m), streak columns per metre of circumference.
const VEILS := [[14.0, 16.0], [38.0, 7.0]]
const VEIL_HEIGHT_M := 70.0
const VEIL_MIN_PRESET := 2
## Wind direction: the water's own (WaterShader.WIND).
const WIND := WaterShader.WIND

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.8);
uniform float opacity = 0.4;
uniform bool snow = false;
uniform vec2 quad_m = vec2(0.006, 0.45);
uniform vec3 fall_dir = vec3(0.0, -1.0, 0.0);
uniform float reach_m = 18.0;

varying float fade;

void vertex() {
	vec3 c = MODEL_MATRIX[3].xyz;
	// The particle's random scale doubles as its seed.
	float s = length(MODEL_MATRIX[0].xyz);
	if (snow) {
		// Flakes wander as they fall: a path that is a function of height.
		float seed = fract(s * 41.3) * 6.2831853;
		c.x += sin(c.y * 1.1 + seed) * 0.35 + sin(c.y * 2.9 + seed * 2.0) * 0.1;
		c.z += cos(c.y * 0.9 + seed * 1.7) * 0.35;
	}
	vec3 to_cam = CAMERA_POSITION_WORLD - c;
	float dist = max(length(to_cam), 0.05);
	vec3 v = to_cam / dist;
	vec3 up = snow ? normalize(INV_VIEW_MATRIX[1].xyz) : normalize(-fall_dir);
	// Looking along the fall line leaves no side: take any other axis.
	vec3 side = cross(up, v);
	side = length(side) > 1e-3 ? normalize(side)
		: normalize(cross(up, abs(up.x) < 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0)));
	vec3 back = cross(side, up);
	// One pixel's width in metres at this distance.
	float px = dist * 2.0 / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	vec2 size = quad_m * s;
	float min_w = px * (snow ? 1.6 : 1.2);
	float energy = min(1.0, size.x / min_w);
	size.x = max(size.x, min_w);
	if (snow) {
		size.y = size.x;
	}
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(side * size.x, 0.0), vec4(up * size.y, 0.0),
		vec4(back, 0.0), vec4(c, 1.0));
	// No huge smears against the lens; no visible edge at the box's reach.
	fade = energy * smoothstep(0.4, 2.2, dist) * (1.0 - smoothstep(reach_m * 0.7, reach_m * 1.15, dist));
	// Age 0..1 from the particle process: no birth or death in one frame.
	float age = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	fade *= smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.85, 1.0, age));
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float a;
	if (snow) {
		a = 1.0 - smoothstep(0.35, 1.0, length(q));
	} else {
		// Sharp across, tapering along the fall line.
		a = (1.0 - abs(q.x)) * (1.0 - smoothstep(0.1, 1.0, abs(q.y)));
	}
	ALBEDO = tint;
	ALPHA = clamp(a * opacity * fade, 0.0, 1.0);
}
"""

const VEIL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.8);
uniform float opacity = 0.1;
uniform bool snow = false;
uniform float columns = 200.0;
// Flake cells per metre, so round flakes stay round at either radius.
uniform float cells_per_m = 4.0;
uniform float height_m = 70.0;
uniform float fall_mps = 8.0;
uniform float seed = 0.0;

// Height along the cylinder, 0 at its top rim to 1 at the bottom:
// CylinderMesh's own V covers only part of the texture range.
varying float down;

void vertex() {
	down = clamp(0.5 - VERTEX.y / height_m, 0.0, 1.0);
}

float v_hash(float x) { return fract(sin(x * 91.17 + seed) * 43758.5453); }

float rain_layer(vec2 uv, float t) {
	float x = uv.x * columns;
	float id = floor(x);
	float h = v_hash(id);
	// Streaks a few metres long sliding down their own column.
	float y = fract(uv.y * height_m / (2.5 + h * 3.0) - t * fall_mps * (0.8 + h * 0.4) / 4.0 + h * 13.0);
	float body = smoothstep(0.0, 0.06, y) * (1.0 - smoothstep(0.06, 0.34, y));
	float across = 1.0 - abs(fract(x) * 2.0 - 1.0);
	return body * smoothstep(0.35, 1.0, across) * step(h, 0.8);
}

float snow_layer(vec2 uv, float t) {
	vec2 g = vec2(uv.x * round(columns * 0.25), (uv.y * height_m - t * fall_mps) * cells_per_m);
	vec2 id = floor(g);
	float h = v_hash(id.x * 7.0 + id.y * 113.0);
	vec2 c = fract(g) - 0.5 - vec2(sin(t * 0.7 + h * 40.0) * 0.18, (h - 0.5) * 0.5);
	return (1.0 - smoothstep(0.02, 0.11, length(c))) * step(h, 0.35);
}

void fragment() {
	vec2 uv = vec2(UV.x, down);
	float a = snow ? snow_layer(uv, TIME) : rain_layer(uv, TIME);
	// Fades out above and below the band of air around the eye.
	float band = smoothstep(0.0, 0.2, down) * (1.0 - smoothstep(0.8, 1.0, down));
	ALBEDO = tint;
	ALPHA = clamp(a * opacity * band, 0.0, 1.0);
}
"""

static var _shader: Shader
static var _veil_shader: Shader

static func _compiled(cached: Shader, code: String) -> Shader:
	if cached != null:
		return cached
	var sh := Shader.new()
	sh.code = code
	return sh

## The particle system (and its veils) under `parent`, the camera rig.
static func build(parent: Node3D, preset: int) -> GPUParticles3D:
	_shader = _compiled(_shader, SHADER)
	_veil_shader = _compiled(_veil_shader, VEIL_SHADER)
	var p := Precipitation.new()
	p.name = "Precipitation"
	p.top_level = true
	p.amount = int(AMOUNT[RenderSettings.clamp_preset(preset)])
	p.lifetime = 2.5
	p.emitting = false
	p.visible = false
	# Rain is out to a box's reach of the eye: never culled as one object.
	p.visibility_aabb = AABB(Vector3(-70.0, -60.0, -70.0), Vector3(140.0, 100.0, 140.0))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.gravity = Vector3.ZERO
	p.process_material = mat
	var quad := QuadMesh.new()
	var qm := ShaderMaterial.new()
	qm.shader = _shader
	quad.material = qm
	p.draw_pass_1 = quad
	parent.add_child(p)
	p.position = Vector3(0.0, BOX_UP_M, 0.0)
	p.set_process(false)
	for i in VEILS.size():
		p.add_child(_veil(i))
	_set_veils(p, RenderSettings.clamp_preset(preset) >= VEIL_MIN_PRESET)
	return p

## Follows the eye while it falls; idle (not even processed) in clear weather.
func _process(_delta: float) -> void:
	var rig := get_parent() as Node3D
	if rig != null:
		position = rig.global_position + Vector3(0.0, BOX_UP_M, 0.0)

static func _veil(i: int) -> MeshInstance3D:
	var radius := float(VEILS[i][0])
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = VEIL_HEIGHT_M
	cyl.radial_segments = 48
	cyl.rings = 1
	cyl.cap_top = false
	cyl.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.name = "Veil%d" % i
	mi.mesh = cyl
	mi.position = Vector3(0.0, -BOX_UP_M, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = _veil_shader
	m.set_shader_parameter("columns", round(TAU * radius * float(VEILS[i][1])))
	m.set_shader_parameter("cells_per_m", float(VEILS[i][1]) * 0.25)
	m.set_shader_parameter("height_m", VEIL_HEIGHT_M)
	m.set_shader_parameter("seed", float(i) * 3.7)
	mi.material_override = m
	return mi

static func _veil_nodes(p: GPUParticles3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for c in p.get_children():
		if c is MeshInstance3D:
			out.append(c)
	return out

static func _set_veils(p: GPUParticles3D, on: bool) -> void:
	for mi in _veil_nodes(p):
		mi.visible = on

## A preset change re-budgets the particles; the veils are High and up.
static func set_quality(p: GPUParticles3D, preset: int) -> void:
	if p == null:
		return
	var tier := RenderSettings.clamp_preset(preset)
	p.amount = int(AMOUNT[tier])
	_set_veils(p, tier >= VEIL_MIN_PRESET)
	# A new count empties the particles: dress it again, preroll and all,
	# so the air is not bare for a lifetime.
	if p.emitting and p.has_meta("look"):
		p.set_meta("dressed", "")
		apply(p, p.get_meta("look"))

## Dresses the system for `look` (WeatherLook): none hides it.
static func apply(p: GPUParticles3D, look: Dictionary) -> void:
	if p == null:
		return
	var kind := str(look.get("precip", "none"))
	var on := kind != "none"
	p.visible = on
	p.emitting = on
	p.set_process(on)
	p.set_meta("look", look)
	if on:
		p._process(0.0)
	# Weather refreshes must not restart a fall that is already this one.
	var key := "%s:%.2f" % [kind, float(look.get("intensity", 0.0))] if on else ""
	if str(p.get_meta("dressed", "")) == key:
		return
	p.set_meta("dressed", key)
	if not on:
		return
	var snow := kind == "snow"
	var pp := WeatherLook.particle_params(look)
	var box: Vector3 = SNOW_BOX if snow else RAIN_BOX
	var speed := float(pp["speed"])
	var slant := float(pp["slant"])
	var fall := Vector3(WIND.x * slant, -1.0, WIND.y * slant).normalized()
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_box_extents = box
	pm.direction = fall
	pm.spread = 10.0 if snow else 2.5
	pm.initial_velocity_min = speed * 0.85
	pm.initial_velocity_max = speed * 1.15
	pm.scale_min = 0.5 if snow else 0.7
	pm.scale_max = 1.7 if snow else 1.3
	p.amount_ratio = float(pp["amount_ratio"])
	p.lifetime = (SNOW_TRAVEL_M if snow else RAIN_TRAVEL_M) / speed
	# The air is already full when the weather starts. Slow flakes need
	# few simulation steps: this preroll runs inside one frame.
	p.fixed_fps = 15 if snow else 30
	p.preprocess = p.lifetime
	var qm := (p.draw_pass_1 as QuadMesh).material as ShaderMaterial
	qm.set_shader_parameter("snow", snow)
	qm.set_shader_parameter("quad_m", pp["size"])
	qm.set_shader_parameter("opacity", float(pp["alpha"]))
	qm.set_shader_parameter("fall_dir", fall)
	qm.set_shader_parameter("reach_m", box.x)
	for mi in _veil_nodes(p):
		var m := mi.material_override as ShaderMaterial
		m.set_shader_parameter("snow", snow)
		m.set_shader_parameter("fall_mps", speed)
		m.set_shader_parameter("opacity", float(pp["veil"]))
	p.restart()

## Takes the level of the sky's light. `sky` is sRGB (AtmosphereRig).
static func set_light(p: GPUParticles3D, sky: Color, snowing: bool) -> void:
	if p == null:
		return
	# Snow scatters nearly all the light, rain is mostly clear water;
	# both go dark with the sky.
	var c := (Color(sky.r * 1.3, sky.g * 1.3, sky.b * 1.3)).clamp() if snowing else sky
	((p.draw_pass_1 as QuadMesh).material as ShaderMaterial).set_shader_parameter("tint", c)
	for mi in _veil_nodes(p):
		(mi.material_override as ShaderMaterial).set_shader_parameter("tint", c)
