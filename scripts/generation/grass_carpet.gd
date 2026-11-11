class_name GrassCarpet
extends RefCounted

## A dense carpet of real grass blades under the eye (desktop High and
## Ultra). Up close a lawn is thousands of blades, not a texture: a single
## MultiMesh of small blade clumps on a fixed grid that follows the camera
## (snapped to whole grid steps, so clumps never swim). The vertex shader
## asks the terrain's fine land-cover map (GroundMaterial.near_class_map,
## kept under the eye by NearGroundWindow) what each clump stands on. Mown
## lawn grows short blades with the mower's stripes, meadow grows long
## ones, and clumps keep about a metre from paving, roads, walls and water
## (GroundShader wears that strip to earth). Heights come from a small
## height texture baked around the eye on a worker. The carpet thins out by
## whole clumps toward its rim, where GroundCover and the ground shader
## take over.

## Grid side (clumps) and spacing (m) per preset: Fast, Balanced, High, Ultra.
const SIDE := [0, 0, 120, 160]
const SPACING_M := [0.0, 0.0, 0.34, 0.30]
## Blades per clump and segments per blade.
const BLADES := 14
const SEGMENTS := 3
## Height texture: texels a side, span (m), and how far the eye may move
## from its centre (m) before it is baked again.
const HEIGHT_TEXELS := 128
const HEIGHT_SPAN_M := 72.0
const HEIGHT_REFRESH_M := 10.0
## Land-cover ids (GroundMaterial.ID) the carpet grows on, and the hard
## ones it keeps clear of.
const MOWN_IDS := [4, 8]
## Land classes the carpet can grow on, and the probes (a side) that look
## for them around the eye.
const GRASS_CLASSES := ["grass", "cemetery", "wetland"]
const GRASS_PROBES := 13
const WILD_IDS := [10, 17]

const SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, world_vertex_coords;
uniform sampler2D near_class : filter_nearest, repeat_disable;
uniform float near_n = 0.0;
uniform vec4 near_rect = vec4(0.0);
uniform sampler2D heights : filter_linear, repeat_disable;
// Height texture centre (x, z), half side, and 1 once baked.
uniform vec4 h_rect = vec4(0.0);
uniform float spacing_u = 0.3;
uniform float radius_u = 24.0;
uniform float blade_count = 14.0;
uniform float u2m = 1.0;
// Linear already (GroundCover's tuft colour): no source_color hint.
uniform vec3 lawn = vec3(0.17, 0.27, 0.07);
uniform float stripe_angle = 0.6;
uniform float sway = 0.1;
// @SNOW
varying vec3 tint;
varying float tipv;
varying vec3 wpos;

// Sine-free hash: sin() of large grid coordinates loses precision on the
// GPU and repeats down whole grid columns (the meadow grew in rows).
float h21(vec2 p, float s) {
	vec3 p3 = fract(vec3(p.xyx + s * 17.13) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Smooth value noise in [0, 1] over unit cells (clumps fade into each
// other; a per-cell hash stepped into rows).
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i, 9.0), h21(i + vec2(1.0, 0.0), 9.0), f.x),
		mix(h21(i + vec2(0.0, 1.0), 9.0), h21(i + vec2(1.0, 1.0), 9.0), f.x), f.y);
}

int class_at(vec2 xz) {
	vec2 t = ((xz - near_rect.xy) / (2.0 * near_rect.z) + 0.5) * near_n;
	ivec2 i = ivec2(floor(t));
	if (i.x < 0 || i.y < 0 || i.x >= int(near_n) || i.y >= int(near_n)) {
		return 0;
	}
	return int(texelFetch(near_class, i, 0).r * 255.0 + 0.5);
}

bool hard(int id) {
	return id == 1 || id == 2 || id == 3 || id == 15 || id == 16;
}

void vertex() {
	// MODEL_MATRIX carries the instance transform: its origin is the clump's.
	vec3 o = MODEL_MATRIX[3].xyz;
	vec3 local = VERTEX - o;
	// Stable per-clump hash. Clumps sit on half steps of the snapped grid,
	// so floor (not round): rounding a value at exactly .5 flipped whole
	// columns onto their neighbour's cell and the meadow grew in rows.
	vec2 cell = floor(o.xz / spacing_u);
	vec2 root = (cell + vec2(h21(cell, 1.0), h21(cell, 2.0)) - 0.5) * spacing_u;
	float m = 1.0 / u2m;
	float d = length(root - CAMERA_POSITION_WORLD.xz);
	float fade = 1.0 - smoothstep(radius_u * 0.4, radius_u, d);
	float pick = h21(cell, 3.0);
	// Past mid-radius a clump keeps fewer, wider blades: there a blade is
	// a pixel or two, so under half as many cover the ground as well.
	float thin = smoothstep(radius_u * 0.3, radius_u * 0.55, d);
	bool dropped = UV.y >= blade_count * mix(1.0, 0.43, thin);
	// Clumps behind the eye are never seen: skip them before any lookup.
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	bool behind = dot(vec3(root.x, CAMERA_POSITION_WORLD.y, root.y) - CAMERA_POSITION_WORLD, fwd) < -1.5 * m;
	bool live = !(pick > fade || dropped || behind);
	int id = live && near_n > 0.5 && h_rect.w > 0.5 ? class_at(root) : 0;
	bool mown = id == 4 || id == 8;
	bool wild = id == 10 || id == 17;
	// Keep clear of paving, roads, walls and water: ~1 m, as the ground wears.
	float r1 = 0.9 * m;
	bool clear = (mown || wild) && !hard(class_at(root + vec2(r1, 0.0))) && !hard(class_at(root - vec2(r1, 0.0)))
		&& !hard(class_at(root + vec2(0.0, r1))) && !hard(class_at(root - vec2(0.0, r1)));
	if (!clear) {
		VERTEX = o;
		tint = vec3(0.0);
		tipv = 0.0;
		wpos = o;
	} else {
		// Mown blades 7-13 cm; meadow 28-60 cm, in clumps. Clumps overlap
		// their neighbours, so the blades close into one sward.
		vec2 rm = root * u2m;
		float clump = vnoise(rm / 2.3) * 0.6 + vnoise(rm / 7.0 + 13.0) * 0.4;
		float hgt = (mown ? mix(0.07, 0.13, h21(cell, 5.0)) : mix(0.28, 0.6, 0.5 * h21(cell, 5.0) + 0.5 * clump)) * m;
		float foot = (mown ? 0.45 : 0.7) * m;
		// Blades stay at least about a pixel wide as they recede.
		float widen = 1.0 + d * u2m / 9.0;
		float yaw = h21(cell, 6.0) * 6.2831853;
		mat2 rot = mat2(vec2(cos(yaw), sin(yaw)), vec2(-sin(yaw), cos(yaw)));
		vec2 side = rot * UV2 * foot * widen * mix(1.0, 1.6, thin);
		// Roots spread over the clump's footprint; the lean scales with
		// the blade's height, so short turf stands up.
		vec2 lean = (COLOR.rg - 0.5) * 2.0;
		vec2 xz = rot * (local.xz * foot + lean * hgt);
		float t = UV.x;
		vec2 hu = (root - h_rect.xy) / (2.0 * h_rect.z) + 0.5;
		float y = texture(heights, hu).r;
		// Toward the rim blades shorten as well as thin, so the carpet
		// tapers into the ground instead of ending in a line.
		float s = mix(0.25, 1.0, fade);
		float bury = 1.0 - 0.95 * snow_bury(vec3(root.x, y, root.y));
		vec3 p = vec3(root.x + (xz.x + side.x) * s, y + local.y * hgt * s * bury, root.y + (xz.y + side.y) * s);
		// Wind: tips sway, a slow gust front travels; short turf barely moves.
		float gust = sin(p.x * 0.07 + p.z * 0.05 - TIME * 1.3) * 0.5 + 0.5;
		float ph = TIME * 2.3 + p.x * 0.9 + p.z * 0.7;
		float amp = sway * hgt * t * t * (0.4 + gust) * 2.0;
		p.x += sin(ph) * amp;
		p.z += cos(ph * 0.83) * amp * 0.6;
		VERTEX = p;
		wpos = p;
		vec3 n = normalize(vec3(-side.y, 0.0, side.x) + 1e-5);
		NORMAL = normalize(mix(n, vec3(0.0, 1.0, 0.0), 0.65));
		// Each blade its own shade and hue, straw creeping into a meadow.
		float bh = h21(cell + vec2(UV.y * 7.31, UV.y * 3.17), 7.0);
		vec3 c = lawn * mix(0.82, 1.14, bh);
		c *= mix(vec3(1.06, 1.0, 0.82), vec3(0.92, 1.0, 1.08), h21(cell, 8.0));
		if (wild) {
			// Standing meadow grass is lighter and yellower than turf, and
			// goes to straw toward the tips in its drier patches.
			c *= vec3(1.45, 1.32, 1.05);
			c = mix(c, vec3(c.g * 1.0, c.g * 0.92, c.g * 0.5), (0.15 + 0.35 * clump) * t);
		} else {
			// Mower's stripes, as on the ground beneath.
			vec2 sd = vec2(cos(stripe_angle), sin(stripe_angle));
			float sc = dot(root * u2m, vec2(-sd.y, sd.x)) / 1.3;
			float band = smoothstep(-0.12, 0.12, sin(sc * 3.14159265)) * 2.0 - 1.0;
			vec2 to_eye = normalize(CAMERA_POSITION_WORLD.xz - root + vec2(1e-4));
			c *= 1.0 + 0.09 * band * dot(sd, to_eye);
		}
		tint = c;
		tipv = t;
	}
}

void fragment() {
	// Dark at the root (the sward shades itself), light at the tip.
	vec3 c = tint * mix(0.65, 1.1, pow(tipv, 0.8));
	// Double-sided blades: a back face's flipped normal points down and
	// goes black in the sun, so keep every normal on the sky's side.
	vec3 up = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec3 nn = dot(NORMAL, up) < 0.0 ? -NORMAL : NORMAL;
	NORMAL = normalize(mix(nn, up, 0.5));
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(c, snow_col, sc * 0.8);
	BACKLIGHT = c * vec3(0.4, 0.36, 0.2);
	ROUGHNESS = mix(0.9, 0.6, tipv);
	SPECULAR = mix(0.18, 0.45, tipv);
	AO = mix(0.55, 1.0, tipv);
	AO_LIGHT_AFFECT = 0.25;
}
"""

var _mmi: MultiMeshInstance3D
var _mat: ShaderMaterial
var _terrain: ShaderMaterial
var _ground: GroundTruth
var _tex: ImageTexture
var _spacing := 0.3
var _cover: Image
var _grass := true
var _h_centre := Vector2(INF, INF)
var _task := -1
var _box := {}

## Whether this device and tier grow the carpet.
static func enabled(preset: int) -> bool:
	return not OS.has_feature("mobile") and RenderSettings.clamp_preset(preset) >= RenderSettings.Preset.HIGH

## Adds the (idle) carpet node to `root`; null when this tier has none.
## It shows nothing until `attach`ed and ticked.
static func build(root: Node3D, data: LocationData) -> MultiMeshInstance3D:
	if not enabled(data.quality_preset):
		return null
	var p := RenderSettings.clamp_preset(data.quality_preset)
	var m2u := WorldScale.metres_to_units()
	var side := int(SIDE[p])
	var sp := float(SPACING_M[p]) * m2u
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = clump_mesh()
	mm.instance_count = side * side
	var h := float(side - 1) * 0.5
	for j in side:
		for i in side:
			mm.set_instance_transform(j * side + i, Transform3D(Basis(), Vector3((float(i) - h) * sp, 0.0, (float(j) - h) * sp)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassCarpet"
	mmi.multimesh = mm
	var r := h * sp
	# Blades sit wherever the terrain is: cull by a tall box around the grid.
	mmi.custom_aabb = AABB(Vector3(-r - 1.0, -5000.0, -r - 1.0), Vector3(2.0 * r + 2.0, 15000.0, 2.0 * r + 2.0))
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.material_override = material(data, sp, r)
	mmi.set_meta("spacing_u", sp)
	# Its own LodRing layer: it sits at the eye and takes no range.
	mmi.set_meta("lod_layer", "GrassCarpet")
	mmi.visible = false
	root.add_child(mmi)
	return mmi

## The carpet's material; blank land-cover and height inputs until ticked.
static func material(data: LocationData, spacing_u: float, radius_u: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("spacing_u", spacing_u)
	m.set_shader_parameter("radius_u", radius_u)
	m.set_shader_parameter("blade_count", float(BLADES))
	m.set_shader_parameter("u2m", 1.0 / WorldScale.metres_to_units())
	m.set_shader_parameter("lawn", lawn_colour(data))
	return m

## The blades' linear base colour: GroundCover's tuft colour for the place.
static func lawn_colour(data: LocationData) -> Color:
	return GroundCover._turf(GroundCover._grass_colour(data)) * GroundCover.TUFT_VALUE

## One clump in unit space (1 wide, 1 tall): BLADES tapered, curving blades
## of SEGMENTS segments. VERTEX holds the blade's root and height,
## COLOR.rg its lean offset (0.5 + offset / 2, in blade heights), UV2 the
## horizontal half-width offset (the shader widens it with distance),
## UV.x the height along the blade and UV.y the blade's index.
static func clump_mesh() -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var verts := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for b in BLADES:
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * 0.45
		var base := Vector2(cos(a), sin(a)) * rr
		var lean_dir := Vector2.from_angle(rng.randf() * TAU)
		var lean := rng.randf_range(0.08, 0.5)
		var blen := rng.randf_range(0.65, 1.0)
		var w := rng.randf_range(0.022, 0.034)
		var across := Vector2.from_angle(rng.randf() * TAU)
		var k0 := verts.size()
		for sgm in SEGMENTS + 1:
			var t := float(sgm) / float(SEGMENTS)
			var lo := lean_dir * lean * t * t
			var y := blen * (t - 0.18 * lean * t * t)
			var half := w * (1.0 - t * 0.92) * 0.5
			for sd: float in [-1.0, 1.0]:
				verts.append(Vector3(base.x, y, base.y))
				cols.append(Color(0.5 + lo.x * 0.5, 0.5 + lo.y * 0.5, 0.0, 1.0))
				uv.append(Vector2(t, float(b)))
				uv2.append(across * half * sd)
		for sgm in SEGMENTS:
			var k := k0 + sgm * 2
			idx.append_array([k, k + 1, k + 3, k, k + 3, k + 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## A driver for the carpet under `root`, fed by its terrain's land-cover
## map; null when the world has no carpet or no fine map.
static func attach(root: Node, ground: GroundTruth, data: LocationData = null) -> GrassCarpet:
	if root == null or ground == null:
		return null
	var mmi := root.find_child("GrassCarpet", true, false) as MultiMeshInstance3D
	var terrain := root.find_child("Terrain", true, false) as MeshInstance3D
	if mmi == null or terrain == null or not (terrain.material_override is ShaderMaterial) \
			or not (mmi.material_override is ShaderMaterial):
		return null
	var tm := terrain.material_override as ShaderMaterial
	var n_value: Variant = tm.get_shader_parameter("near_n")
	if n_value == null or float(n_value) < 1.0 or tm.get_shader_parameter("near_class") == null:
		return null
	var c := GrassCarpet.new()
	c._mmi = mmi
	c._mat = mmi.material_override as ShaderMaterial
	c._terrain = tm
	c._ground = ground
	c._cover = data.landcover_image if data != null else null
	c._spacing = float(mmi.get_meta("spacing_u", 0.3))
	c._mat.set_shader_parameter("near_class", tm.get_shader_parameter("near_class"))
	c._mat.set_shader_parameter("near_n", float(n_value))
	var angle: Variant = tm.get_shader_parameter("stripe_angle")
	if angle != null:
		c._mat.set_shader_parameter("stripe_angle", float(angle))
	return c

## Once a frame: follows the eye, bakes heights when it has moved on, and
## hides the carpet from high up or where no grass lies within reach (its
## clumps would all collapse, yet still cost their vertices).
## `agl_u` is the eye's height over the ground.
func tick(eye: Vector3, agl_u: float) -> void:
	if not is_instance_valid(_mmi):
		return
	var m2u := WorldScale.metres_to_units()
	_mmi.visible = agl_u < NearGroundWindow.MAX_AGL_M * m2u and _tex != null and _grass
	_mmi.global_position = Vector3(roundf(eye.x / _spacing) * _spacing, 0.0, roundf(eye.z / _spacing) * _spacing)
	# The window moves the shared map in place; only its rect changes.
	_mat.set_shader_parameter("near_rect", _terrain.get_shader_parameter("near_rect"))
	if _task >= 0:
		if WorkerThreadPool.is_task_completed(_task):
			WorkerThreadPool.wait_for_task_completion(_task)
			_task = -1
			_apply()
		return
	var e := Vector2(eye.x, eye.z)
	if e.distance_to(_h_centre) > HEIGHT_REFRESH_M * m2u:
		_box = {"centre": e}
		_task = WorkerThreadPool.add_task(_bake.bind(_ground, _cover, _box, HEIGHT_SPAN_M * m2u), false, "GrassCarpet")

## Waits for a bake in progress (the world is about to go).
func stop() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1

## A carpet dropped with a bake in progress still joins its task.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1

## Ground heights (units) on a HEIGHT_TEXELS grid of `span` around the
## box's centre; static, so a running job holds nothing of a gone carpet.
static func _bake(ground: GroundTruth, cover: Image, box: Dictionary, span: float) -> void:
	box["image"] = height_image(ground, box["centre"], span)
	box["grass"] = grass_near(ground, cover, box["centre"], span * 0.5)

## Whether lawn or meadow lies within `reach` (units) of `centre`: mapped
## green polygons, or WorldCover grassland and shrubland (`cover`, the
## extent's land-cover codes) where nothing is mapped, as the ground's
## class map paints them. A GRASS_PROBES² grid of samples.
static func grass_near(ground: GroundTruth, cover: Image, centre: Vector2, reach: float) -> bool:
	var ext := WorldScale.detailed_extent_units()
	var can_cover := cover != null and not cover.is_empty() and not cover.is_compressed()
	for j in GRASS_PROBES:
		for i in GRASS_PROBES:
			var p := centre + (Vector2(float(i), float(j)) / float(GRASS_PROBES - 1) - Vector2(0.5, 0.5)) * 2.0 * reach
			var cls := ground.land_class_at(p.x, p.y)
			if cls in GRASS_CLASSES:
				return true
			if cls == "" and can_cover:
				var u := p / ext + Vector2(0.5, 0.5)
				if u.x >= 0.0 and u.y >= 0.0 and u.x < 1.0 and u.y < 1.0:
					var code := roundi(cover.get_pixel(int(u.x * float(cover.get_width())),
						int(u.y * float(cover.get_height()))).r * 255.0)
					if code == 20 or code == 30:
						return true
	return false

## Texel centres at centre + ((i + 0.5) / N - 0.5) * span, as the shader reads them.
static func height_image(ground: GroundTruth, centre: Vector2, span: float) -> Image:
	var n := HEIGHT_TEXELS
	var data := PackedFloat32Array()
	data.resize(n * n)
	for j in n:
		var z := centre.y + ((float(j) + 0.5) / float(n) - 0.5) * span
		for i in n:
			data[j * n + i] = ground.height_at_world(centre.x + ((float(i) + 0.5) / float(n) - 0.5) * span, z)
	return Image.create_from_data(n, n, false, Image.FORMAT_RF, data.to_byte_array())

func _apply() -> void:
	var img: Image = _box.get("image", null)
	if img == null:
		return
	if _tex == null:
		_tex = ImageTexture.create_from_image(img)
		_mat.set_shader_parameter("heights", _tex)
	else:
		_tex.update(img)
	_h_centre = _box["centre"]
	_grass = bool(_box.get("grass", true))
	_mat.set_shader_parameter("h_rect", Vector4(_h_centre.x, _h_centre.y, HEIGHT_SPAN_M * WorldScale.metres_to_units() * 0.5, 1.0))
