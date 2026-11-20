class_name AmbientLife
extends RefCounted

## Subtle GPU-driven living accents for High/Ultra views:
## - Distant soaring birds / coastal gulls wheeling smoothly on thermals
##   above parks, rivers and harbours (hidden at night and in storms).
## - Soft winter chimney smoke / district-heating steam plumes drifting
##   downwind from mapped stacks and cold-weather residential roofs.
## Both run in a single MultiMesh draw call each with zero per-frame CPU work.

const BIRD_COUNT_INLAND := 24
const BIRD_COUNT_COASTAL := 36
const MAX_CHIMNEYS := 16
const WISPS_PER_CHIMNEY := 8
const CHIMNEY_RADIUS_M := 420.0

## Flapping/gliding soaring bird shader: INSTANCE_CUSTOM packs
## (orbit_radius_m, angular_speed, phase, flap_rate). UV.x = 0 body .. 1 wingtip.
const BIRD_CODE := """
shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_disabled, world_vertex_coords;
uniform float visibility = 1.0;
uniform vec3 bird_tint : source_color = vec3(0.18, 0.19, 0.21);
varying float alpha_fade;

void vertex() {
	float radius = INSTANCE_CUSTOM.r;
	float speed = INSTANCE_CUSTOM.g;
	float phase = INSTANCE_CUSTOM.b;
	float flap_hz = INSTANCE_CUSTOM.a;
	float dir_sign = speed >= 0.0 ? 1.0 : -1.0;
	float ang = TIME * speed + phase;
	// Gentle figure-8 wobble so orbits never look mechanical.
	float r = radius * (1.0 + 0.12 * sin(ang * 2.0 + phase));
	vec3 offset = vec3(cos(ang) * r, sin(ang * 1.5 + phase) * 3.5, sin(ang) * r);
	vec2 tangent = normalize(vec2(-sin(ang), cos(ang)) * dir_sign + vec2(1e-6));
	vec3 origin = MODEL_MATRIX[3].xyz;
	float span = max(length(MODEL_MATRIX[0].xyz), 0.01);
	// Periodic flapping alternating with calm gliding.
	float glide = smoothstep(0.15, 0.65, sin(TIME * 0.45 + phase * 3.7));
	float flap = sin(TIME * flap_hz + phase * 6.0) * glide * UV.x * 0.32 * span;
	vec3 local = VERTEX - origin;
	local.y += flap;
	// Bank gently into the turn.
	float bank = -0.22 * dir_sign;
	float cb = cos(bank);
	float sb = sin(bank);
	local.xy = vec2(local.x * cb - local.y * sb, local.x * sb + local.y * cb);
	// Orient local +Z along tangent (heading), +X to wing axis.
	vec3 fwd = vec3(tangent.x, 0.0, tangent.y);
	vec3 right = vec3(-tangent.y, 0.0, tangent.x);
	vec3 wpos = origin + offset + right * local.x + vec3(0.0, local.y, 0.0) + fwd * local.z;
	VERTEX = wpos;
	float d = length(wpos - CAMERA_POSITION_WORLD);
	alpha_fade = visibility * smoothstep(18.0, 42.0, d) * (1.0 - smoothstep(420.0, 750.0, d));
}

void fragment() {
	if (alpha_fade < 0.02) {
		discard;
	}
	// The mesh winds downward, so seen from above the back face turns the
	// normal down and the bird goes black against water. Light both faces as top.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = bird_tint * COLOR.rgb;
	ALPHA = alpha_fade;
	ROUGHNESS = 0.9;
}
"""

## Rising, wind-drifting, expanding smoke/steam wisps from chimney tops.
## INSTANCE_CUSTOM packs (phase_0_1, rise_m, base_width_m, drift_scale).
const SMOKE_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, unshaded, world_vertex_coords;
uniform vec3 smoke_tint : source_color = vec3(0.84, 0.86, 0.89);
uniform float smoke_opacity = 0.28;
uniform vec2 wind = vec2(0.86, 0.51);
varying float life_fade;
varying float seed_v;

float sm_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float sm_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(sm_hash(i), sm_hash(i + vec2(1.0, 0.0)), f.x),
		mix(sm_hash(i + vec2(0.0, 1.0)), sm_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	float phase = INSTANCE_CUSTOM.r;
	float rise_m = INSTANCE_CUSTOM.g;
	float base_w = INSTANCE_CUSTOM.b;
	float drift_k = INSTANCE_CUSTOM.a;
	float age = fract(TIME * 0.085 + phase);
	seed_v = phase * 19.7;
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec2 wd = normalize(wind);
	vec2 wn = vec2(-wd.y, wd.x);
	float sway = sin(TIME * 0.7 + phase * 12.0 + age * 5.0) * age * 1.4;
	vec3 puff = origin + vec3(wd.x * age * rise_m * drift_k + wn.x * sway,
		age * rise_m, wd.y * age * rise_m * drift_k + wn.y * sway);
	float sz = base_w * (0.6 + age * 2.8);
	vec3 cam_r = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_u = INV_VIEW_MATRIX[1].xyz;
	vec2 corner = vec2(UV.x - 0.5, 0.5 - UV.y);
	VERTEX = puff + (cam_r * corner.x + cam_u * corner.y) * sz;
	float d = length(puff - CAMERA_POSITION_WORLD);
	float dfade = smoothstep(8.0, 22.0, d) * (1.0 - smoothstep(320.0, 620.0, d));
	life_fade = smoothstep(0.0, 0.16, age) * (1.0 - smoothstep(0.35, 1.0, age)) * dfade;
}

void fragment() {
	if (life_fade < 0.005 || smoke_opacity < 0.005) {
		discard;
	}
	vec2 q = (UV - 0.5) * 2.0;
	float r2 = dot(q, q);
	if (r2 >= 1.0) {
		discard;
	}
	float n = sm_noise(UV * 3.5 + vec2(seed_v, -TIME * 0.18)) * 0.65
		+ sm_noise(UV * 7.2 - vec2(TIME * 0.12, seed_v)) * 0.35;
	float puff = pow(1.0 - r2, 1.8) * smoothstep(0.22, 0.82, n);
	float a = puff * life_fade * smoke_opacity;
	if (a < 0.005) {
		discard;
	}
	ALBEDO = smoke_tint;
	ALPHA = a;
}
"""

static var _bird_mat: ShaderMaterial
static var _smoke_mat: ShaderMaterial
static var _bird_geo: ArrayMesh
static var _smoke_quad: QuadMesh

## Builds or updates ambient birds and winter chimney smoke for `world`
## (hosted on `world`'s parent when live so cached world subtrees stay untouched).
static func sync(world: Node, data: LocationData, ground: GroundTruth,
		atmos: AtmosphereRig, preset: int) -> void:
	if world == null or data == null or ground == null:
		return
	var host: Node = world.get_parent() if world.get_parent() != null else world
	var wid := world.get_instance_id()
	var allow := RenderSettings.clamp_preset(preset) >= RenderSettings.Preset.HIGH
	_sync_birds(host, wid, data, ground, atmos, allow)
	_sync_smoke(host, wid, data, ground, atmos, allow)

static func _sync_birds(host: Node, wid: int, data: LocationData, ground: GroundTruth,
		atmos: AtmosphereRig, allow: bool) -> void:
	var mmi := host.get_node_or_null("AmbientBirds") as MultiMeshInstance3D
	if mmi != null and int(mmi.get_meta("ambient_world", 0)) != wid:
		host.remove_child(mmi)
		mmi.queue_free()
		mmi = null
	if not allow:
		if mmi != null:
			mmi.visible = false
		return
	var coastal := WaterBuilder._has_coastline(data) or LandmarkTerrain.has_sea(data)
	if mmi == null:
		mmi = _build_birds(data, ground, coastal)
		mmi.set_meta("ambient_world", wid)
		host.add_child(mmi)
	var day := 1.0 - (atmos.night_amount if atmos != null else 0.0)
	var stormy := atmos != null and (str(atmos.weather_look.get("precip", "none")) != "none" or atmos.is_foggy())
	var vis := 0.0 if stormy else clampf(day * 1.25 - 0.15, 0.0, 1.0)
	mmi.visible = vis > 0.02
	var mat := mmi.material_override as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("visibility", vis)
		mat.set_shader_parameter("bird_tint", Color(0.84, 0.85, 0.86) if coastal else Color(0.18, 0.19, 0.21))

static func _build_birds(data: LocationData, ground: GroundTruth, coastal: bool) -> MultiMeshInstance3D:
	var m2u := WorldScale.metres_to_units()
	var count := BIRD_COUNT_COASTAL if coastal else BIRD_COUNT_INLAND
	var centre := View360.spawn_xz(data)
	var base_y := ground.height_at_world(centre.x, centre.y)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _get_bird_mesh()
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(data.latitude * 1000.0), int(data.longitude * 1000.0))) ^ 0x51a7
	for i in count:
		var ox := centre.x + rng.randf_range(-190.0, 190.0) * m2u
		var oz := centre.y + rng.randf_range(-190.0, 190.0) * m2u
		var oy := maxf(ground.height_at_world(ox, oz), base_y) + rng.randf_range(38.0, 96.0) * m2u
		var span := rng.randf_range(0.85, 1.35) * m2u
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * span), Vector3(ox, oy, oz)))
		var shade := rng.randf_range(0.82, 1.08)
		mm.set_instance_color(i, Color(shade, shade, shade))
		var r := rng.randf_range(22.0, 78.0) * m2u
		var spd := rng.randf_range(0.09, 0.19) * (1.0 if i % 2 == 0 else -1.0)
		mm.set_instance_custom_data(i, Color(r, spd, rng.randf_range(0.0, TAU), rng.randf_range(5.5, 8.5)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "AmbientBirds"
	mmi.multimesh = mm
	mmi.material_override = _get_bird_material().duplicate()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(centre.x - 360.0 * m2u, base_y - 20.0 * m2u, centre.y - 360.0 * m2u),
		Vector3(720.0 * m2u, 220.0 * m2u, 720.0 * m2u))
	mmi.set_meta("lod_own", true)
	return mmi

static func _sync_smoke(host: Node, wid: int, data: LocationData, ground: GroundTruth,
		atmos: AtmosphereRig, allow: bool) -> void:
	var mmi := host.get_node_or_null("ChimneySmoke") as MultiMeshInstance3D
	if mmi != null and int(mmi.get_meta("ambient_world", 0)) != wid:
		host.remove_child(mmi)
		mmi.queue_free()
		mmi = null
	var cold := data.season == LocationData.Season.WINTER \
		or (atmos != null and atmos.snow_ground) \
		or (ClimateModel.has(data) and ClimateModel.season_temp_c(data, data.season) <= 5.0)
	if not allow or not cold:
		if mmi != null:
			mmi.visible = false
		return
	if mmi == null:
		mmi = _build_smoke(data, ground)
		if mmi == null:
			return
		mmi.set_meta("ambient_world", wid)
		host.add_child(mmi)
	mmi.visible = true
	var mat := mmi.material_override as ShaderMaterial
	if mat != null and atmos != null:
		var tint := atmos.sky_horizon_color.lerp(Color(0.92, 0.93, 0.95), 0.35)
		var night := atmos.night_amount
		mat.set_shader_parameter("smoke_tint", tint.lerp(Color(0.24, 0.24, 0.28), night * 0.8))
		mat.set_shader_parameter("smoke_opacity", lerpf(0.28, 0.14, night))
		mat.set_shader_parameter("wind", WaterShader.WIND)

static func _build_smoke(data: LocationData, ground: GroundTruth) -> MultiMeshInstance3D:
	var m2u := WorldScale.metres_to_units()
	var centre := View360.spawn_xz(data)
	var r2 := pow(CHIMNEY_RADIUS_M * m2u, 2.0)
	var stacks: Array = []  # [d2, Vector3 top, rise_m, base_w_m]
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var bd: Dictionary = b
		var p := Vector2(float(bd.get("x", 0.0)), float(bd.get("z", 0.0)))
		var d2 := (p - centre).length_squared()
		if d2 > r2:
			continue
		if ChimneyBuilder.accepts(bd):
			var sh := ChimneyBuilder.shape(bd)
			var y := ground.height_at_world(p.x, p.y) + float(sh["height"])
			stacks.append([d2 * 0.1, Vector3(p.x, y, p.y), 24.0 * m2u, clampf(float(sh["r1"]) * 2.2, 1.4 * m2u, 4.5 * m2u)])
		else:
			var h := float(bd.get("height", 0.0))
			var kind := str(bd.get("kind", ""))
			if h >= 5.0 and h <= 24.0 and kind in ["house", "detached", "residential", "apartments", "terrace", "yes"]:
				var pick := fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)
				if pick < 0.08:
					var y := ground.height_at_world(p.x, p.y) + (h + 2.2) * m2u
					stacks.append([d2, Vector3(p.x, y, p.y), 11.0 * m2u, 0.9 * m2u])
	if stacks.is_empty():
		return null
	stacks.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var kept := mini(stacks.size(), MAX_CHIMNEYS)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _get_smoke_quad()
	mm.instance_count = kept * WISPS_PER_CHIMNEY
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var idx := 0
	for i in kept:
		var st: Array = stacks[i]
		var top: Vector3 = st[1]
		var rise: float = st[2]
		var bw: float = st[3]
		lo = lo.min(top - Vector3(rise, 2.0 * m2u, rise))
		hi = hi.max(top + Vector3(rise, rise * 1.2, rise))
		for w in WISPS_PER_CHIMNEY:
			mm.set_instance_transform(idx, Transform3D(Basis(), top))
			var phase := fposmod(float(w) / float(WISPS_PER_CHIMNEY) + float(i) * 0.137, 1.0)
			mm.set_instance_custom_data(idx, Color(phase, rise, bw, 0.75))
			idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ChimneySmoke"
	mmi.multimesh = mm
	mmi.material_override = _get_smoke_material().duplicate()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(lo, (hi - lo).max(Vector3.ONE))
	mmi.set_meta("lod_own", true)
	return mmi

## Simple 4-triangle swept V-wing silhouette (UV.x = 0 at body .. 1 at wingtip).
static func _get_bird_mesh() -> ArrayMesh:
	if _bird_geo != null:
		return _bird_geo
	var verts := PackedVector3Array([
		Vector3(0.0, 0.0, 0.22),    # 0 beak/nose
		Vector3(0.0, 0.0, -0.26),   # 1 tail
		Vector3(-0.34, 0.06, 0.04), # 2 left mid-wing
		Vector3(-0.68, 0.02, -0.10),# 3 left tip
		Vector3(0.34, 0.06, 0.04),  # 4 right mid-wing
		Vector3(0.68, 0.02, -0.10), # 5 right tip
	])
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	norms.fill(Vector3.UP)
	var uvs := PackedVector2Array([
		Vector2(0.0, 0.5), Vector2(0.0, 0.0),
		Vector2(0.5, 0.5), Vector2(1.0, 0.5),
		Vector2(0.5, 0.5), Vector2(1.0, 0.5),
	])
	var idx := PackedInt32Array([0, 2, 1, 2, 3, 1, 0, 1, 4, 4, 1, 5])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	_bird_geo = ArrayMesh.new()
	_bird_geo.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _bird_geo

static func _get_bird_material() -> ShaderMaterial:
	if _bird_mat == null:
		var sh := Shader.new()
		sh.code = BIRD_CODE
		_bird_mat = ShaderMaterial.new()
		_bird_mat.shader = sh
	return _bird_mat

static func _get_smoke_quad() -> QuadMesh:
	if _smoke_quad == null:
		_smoke_quad = QuadMesh.new()
		_smoke_quad.size = Vector2.ONE
	return _smoke_quad

static func _get_smoke_material() -> ShaderMaterial:
	if _smoke_mat == null:
		var sh := Shader.new()
		sh.code = SMOKE_CODE
		_smoke_mat = ShaderMaterial.new()
		_smoke_mat.shader = sh
		_smoke_mat.render_priority = 1
	return _smoke_mat
