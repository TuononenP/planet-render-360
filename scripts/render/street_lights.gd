class_name StreetLights
extends RefCounted

## Real light from the street lamps (desktop Ultra, Phase 5 of the Ultra
## pass). StreetProps places a lamppost every 25 m; here the nearest
## MAX_LIGHTS of them also get a light: an omni under each lantern head, a
## downward spot under each cobra-head arm. Shadowless, faded out by
## distance so only the street around the eye pays, off by day, and
## driven at night by CityLights.apply. Colour follows the region:
## sodium orange where it still lines the streets, warm LED in the
## lantern towns, neutral LED elsewhere.

const META := "street_light"
const MAX_LIGHTS := 320
## Light energy at full night (Godot units, not physical).
const ENERGY := 3.0
const LANTERN_RANGE_M := 14.0
const SPOT_RANGE_M := 20.0
const SPOT_ANGLE_DEG := 62.0
const FADE_BEGIN_M := 170.0
const FADE_LENGTH_M := 60.0
## Dynamic shadow budget for the closest active street lamps on desktop Ultra.
const HERO_SHADOW_MAX := 12
const HERO_SHADOW_RADIUS_M := 55.0
const VOLUMETRIC_FOG_ENERGY := 2.4
const HALO_SIZE_M := 1.5

## Soft misty inverse-square glow halo around each lamp head at night;
## scales with street_lamp_glow and blooms softly in rain.
const HALO_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, world_vertex_coords;
global uniform float street_lamp_glow;
global uniform float climate_rain;
uniform float halo_size = 1.5;
varying vec3 lamp_col;
varying float dist_fade;

void vertex() {
	lamp_col = COLOR.rgb;
	vec3 centre = MODEL_MATRIX[3].xyz;
	float d = length(CAMERA_POSITION_WORLD - centre);
	// Fade out very close (avoids blinding wash) and past FADE_BEGIN_M + FADE_LENGTH_M.
	dist_fade = smoothstep(2.5, 9.0, d) * (1.0 - smoothstep(140.0, 240.0, d));
	float scale = halo_size * mix(1.0, 1.55, clamp(climate_rain, 0.0, 1.0)) * mix(1.0, 1.35, smoothstep(40.0, 180.0, d));
	vec3 cam_right = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_up = INV_VIEW_MATRIX[1].xyz;
	vec2 corner = vec2(UV.x - 0.5, 0.5 - UV.y);
	VERTEX = centre + (cam_right * corner.x + cam_up * corner.y) * scale;
}

void fragment() {
	float glow = clamp(street_lamp_glow, 0.0, 1.0) * dist_fade;
	if (glow < 0.005) {
		discard;
	}
	vec2 q = (UV - 0.5) * 2.0;
	float r2 = dot(q, q);
	if (r2 >= 1.0) {
		discard;
	}
	// A faint gaussian bloom that fades to nothing well inside the quad, so
	// no disc edge or flat plate shows; the lamp head itself carries the core.
	float falloff = exp(-r2 * 7.0) * (1.0 - r2);
	float rain = clamp(climate_rain, 0.0, 1.0);
	ALBEDO = lamp_col * falloff * mix(0.17, 0.30, rain) * glow;
}
"""

static var _halo_mesh: QuadMesh

static func _get_halo_mesh() -> QuadMesh:
	if _halo_mesh == null:
		var sh := Shader.new()
		sh.code = HALO_CODE
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.render_priority = 2
		mat.set_shader_parameter("halo_size", HALO_SIZE_M)
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		q.material = mat
		_halo_mesh = q
	return _halo_mesh
## Lamp heads in the lamp meshes' own metres (StreetProps._lamp_mesh).
const LANTERN_HEAD := Vector3(0.0, 4.1, 0.0)
const COBRA_HEAD := Vector3(1.85, 8.0, 0.0)
## Spot heads of the regional arm styles (the rest use COBRA_HEAD).
## "span": a Nordic luminaire hung on a span wire over the street
## (OverheadWires), its transform already at the lamp.
const HEADS := {"span": Vector3.ZERO, "post_top": Vector3(0, 4.4, 0), "nyc_f": Vector3(1.45, 7.0, 0), "nyc_crook": Vector3(1.45, 5.2, 0), "cobra": Vector3(2.6, 8.85, 0.0), "utility": Vector3(1.15, 5.58, 0.0)}
const SODIUM_REGIONS := ["eastern_europe", "middle_east", "south_asia", "latin_america",
	"sub_saharan_africa"]

static func colour_for(style: String, region: String) -> Color:
	if region in SODIUM_REGIONS:
		return Color(1.0, 0.62, 0.30)   # ~2000 K high-pressure sodium
	if style == "lantern" or style == "heritage":
		return Color(1.0, 0.78, 0.52)   # ~2700 K warm LED / gas look
	return Color(1.0, 0.90, 0.78)       # ~4000 K LED

## Adds the lights for `placed` (StreetProps: style -> lamp transforms)
## under one "StreetLights" node of `root`. Returns the number added.
## Later calls (the span-wire lamps) join the same node and share its
## MAX_LIGHTS budget with the lamps already there.
static func add(root: Node3D, placed: Dictionary, region: String, m2u: float, centre: Vector2 = Vector2.ZERO) -> int:
	var all: Array = []
	for style in placed:
		for xf in (placed[style] as Array):
			var t: Transform3D = xf
			all.append([(Vector2(t.origin.x, t.origin.z) - centre).length_squared(), t, str(style)])
	if all.is_empty():
		return 0
	all.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var holder := root.get_node_or_null("StreetLights") as Node3D
	var fresh := holder == null
	if fresh:
		holder = Node3D.new()
		holder.name = "StreetLights"
	var before := holder.get_child_count()
	for i in mini(all.size(), MAX_LIGHTS - before):
		var t: Transform3D = all[i][1]
		var style: String = all[i][2]
		var light: Light3D
		if style == "lantern" or style == "heritage":
			var omni := OmniLight3D.new()
			omni.omni_range = LANTERN_RANGE_M * m2u
			omni.omni_attenuation = 1.3
			omni.position = t * LANTERN_HEAD
			light = omni
		else:
			var spot := SpotLight3D.new()
			spot.spot_range = SPOT_RANGE_M * m2u
			spot.spot_angle = SPOT_ANGLE_DEG
			spot.spot_attenuation = 0.9
			# SpotLight3D shines down its -Z; turn that to -Y.
			spot.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), t * (HEADS.get(style, COBRA_HEAD) as Vector3))
			light = spot
		light.light_color = colour_for(style, region)
		light.light_energy = 0.0
		light.light_volumetric_fog_energy = VOLUMETRIC_FOG_ENERGY
		light.shadow_enabled = false
		light.shadow_blur = 2.0
		light.shadow_bias = 0.08
		light.shadow_normal_bias = 1.2
		light.distance_fade_enabled = true
		light.distance_fade_begin = FADE_BEGIN_M * m2u
		light.distance_fade_length = FADE_LENGTH_M * m2u
		light.visible = false
		light.set_meta(META, ENERGY)
		holder.add_child(light)
	if fresh:
		root.add_child(holder)
	return holder.get_child_count() - before

## Lazily builds a batched misty glare MultiMesh for every lamp in `holder`,
## attached to `world`'s parent (world_root) when live so the cached world
## subtree stays immutable, or directly to `world` in standalone tests.
static func ensure_halos(world: Node, holder: Node3D) -> MultiMeshInstance3D:
	var host: Node = world.get_parent() if world.get_parent() != null else world
	var wid := world.get_instance_id()
	var existing := host.get_node_or_null("StreetLampHalos") as MultiMeshInstance3D
	if existing != null:
		if int(existing.get_meta("halo_world", 0)) == wid:
			return existing
		host.remove_child(existing)
		existing.queue_free()
	var n := holder.get_child_count()
	if n <= 0:
		return null
	var m2u := WorldScale.metres_to_units()
	var halo_mesh := _get_halo_mesh()
	var halo_mat := halo_mesh.material as ShaderMaterial
	if halo_mat != null:
		halo_mat.set_shader_parameter("halo_size", HALO_SIZE_M * m2u)
	var to_host := Transform3D.IDENTITY
	var cur: Node = holder
	while cur != null and cur != host:
		if cur is Node3D:
			to_host = (cur as Node3D).transform * to_host
		cur = cur.get_parent()
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "StreetLampHalos"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta("lod_own", true)
	mmi.set_meta("halo_world", wid)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = halo_mesh
	mm.instance_count = n
	for i in n:
		var light := holder.get_child(i) as Light3D
		if light == null:
			continue
		mm.set_instance_transform(i, Transform3D(Basis(), to_host * light.position))
		mm.set_instance_color(i, light.light_color)
	mmi.multimesh = mm
	host.add_child(mmi)
	return mmi

## Enables real shadows on the nearest HERO_SHADOW_MAX visible street lamps
## around `eye` on desktop Ultra at night, and ensures lamp halos are present.
## Returns the number of shadow-casting street lamps active.
static func update_shadows(world: Node, eye: Vector3, night: float, preset: int,
		forward_plus: bool = RenderQuality.is_forward_plus()) -> int:
	if world == null:
		return 0
	var host: Node = world.get_parent() if world.get_parent() != null else world
	var wid := world.get_instance_id()
	var halos := host.get_node_or_null("StreetLampHalos") as MultiMeshInstance3D
	if halos != null and int(halos.get_meta("halo_world", 0)) != wid:
		host.remove_child(halos)
		halos.queue_free()
		halos = null
	var holder := world.find_child("StreetLights", true, false) as Node3D
	if holder == null:
		if halos != null:
			halos.visible = false
		return 0
	if night > 0.02:
		halos = ensure_halos(world, holder)
	if halos != null:
		halos.visible = night > 0.02 and int(halos.get_meta("halo_world", 0)) == wid
	var allow := RenderQuality.ultra_desktop(preset, forward_plus) and night > 0.15
	var max_r2 := pow(HERO_SHADOW_RADIUS_M * WorldScale.metres_to_units(), 2.0)
	var near: Array = []
	for c in holder.get_children():
		var light := c as Light3D
		if light == null:
			continue
		light.shadow_enabled = false
		if allow and light.visible:
			var d2 := light.global_position.distance_squared_to(eye) if light.is_inside_tree() \
				else light.position.distance_squared_to(eye)
			if d2 <= max_r2:
				near.append([d2, light])
	if near.is_empty():
		return 0
	near.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var count := mini(near.size(), HERO_SHADOW_MAX)
	for i in count:
		(near[i][1] as Light3D).shadow_enabled = true
	return count

## Night share `amount` (CityLights.amount_for) on one marked light.
static func apply(light: Light3D, amount: float) -> void:
	light.light_energy = float(light.get_meta(META)) * amount
	light.visible = amount > 0.02
	if not light.visible:
		light.shadow_enabled = false
