class_name GroundCover
extends RefCounted

## Low ground cover on mapped green land around the viewpoint: grass
## tufts, wildflower clumps and low shrubs as MultiMesh crossed cards
## (alpha-scissored, swaying in the wind). Lawns and meadows were a
## flat texture under the trees; from 30 m up the tufts break them into
## the dappled, tufted surface a real park or alpine meadow shows, and
## shrubs give hedgerows and park edges their mass.
##
## Placement: jittered grid over the green polygons VegetationMask
## rasterised (grass, cemetery, orchard; forest gets ferny shrubs),
## never on buildings, carriageways or water, inside a radius per tier
## (Fast none). Colours follow the season's grass palette and the
## climate's dry-summer tint, ±12% per instance. Instances fade out
## toward the radius so the edge never shows.

## Radius (m) and grid spacing (m) per preset: Fast, Balanced, High, Ultra.
const RADIUS_M := [0.0, 90.0, 170.0, 260.0]
const SPACING_M := [0.0, 3.2, 2.6, 2.1]
const KINDS := ["tuft", "flower", "shrub"]
const CLASSES := {"grass": [0.86, 0.125, 0.015], "cemetery": [0.85, 0.05, 0.10],
	"orchard": [0.80, 0.12, 0.08], "forest": [0.45, 0.0, 0.55], "wetland": [0.9, 0.05, 0.05]}

const SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float sway = 0.12;
// @SNOW
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Wind: tops sway, bases stay planted; a slow gust front travels.
	float h = clamp(VERTEX.y, 0.0, 1.0);
	float gust = sin(wpos.x * 0.07 + wpos.z * 0.05 - TIME * 1.3) * 0.5 + 0.5;
	float ph = TIME * 2.3 + wpos.x * 0.9 + wpos.z * 0.7;
	VERTEX.x += sin(ph) * sway * h * h * (0.4 + gust);
	VERTEX.z += cos(ph * 0.83) * sway * 0.6 * h * h * (0.4 + gust);
	// Up-facing normals: cards shade like the ground they stand on.
	NORMAL = (inverse(MODEL_MATRIX) * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}
void fragment() {
	vec4 t = texture(tex, UV);
	if (t.a < 0.5) {
		discard;
	}
	vec3 c = t.rgb * COLOR.rgb;
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(c, snow_col, sc * 0.8);
	// Thin leaves glow when lit from behind.
	BACKLIGHT = c * 0.6;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	AO = mix(0.8, 1.0, 1.0 - UV.y);
	AO_LIGHT_AFFECT = 0.15;
}
"""

static var _mats: Dictionary = {}

## Adds the cover MultiMeshes to `root`; returns the instance count.
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask) -> int:
	var p := RenderSettings.clamp_preset(data.quality_preset)
	var radius := float(RADIUS_M[p]) * WorldScale.metres_to_units()
	var per := plan(data, ground, mask)
	var total := 0
	for kind in KINDS:
		var list: Array = per.get(kind, [])
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _card(kind)
		mm.instance_count = list.size()
		for n in list.size():
			var e: Array = list[n]
			var b := Basis(Vector3.UP, float(e[2])).scaled(Vector3.ONE * float(e[1]))
			mm.set_instance_transform(n, Transform3D(b, e[0]))
			mm.set_instance_color(n, e[3])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "GroundCover_" + kind
		mmi.multimesh = mm
		mmi.material_override = _material(kind, data.season)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind == "shrub" and p >= 3 \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = radius * 1.05
		mmi.set_meta("lod_layer", "Vegetation")
		root.add_child(mmi)
		total += list.size()
	return total

## Placements per kind: [position, scale, yaw, colour] lists.
static func plan(data: LocationData, ground: GroundTruth, mask: VegetationMask) -> Dictionary:
	var p := RenderSettings.clamp_preset(data.quality_preset)
	var radius := float(RADIUS_M[p]) * WorldScale.metres_to_units()
	if radius <= 0.0 or mask.green.is_empty():
		return {}
	var sp := float(SPACING_M[p]) * WorldScale.metres_to_units()
	var centre := View360.spawn_xz(data)
	var grass := _grass_colour(data)
	var per: Dictionary = {}
	for k in KINDS:
		per[k] = []
	var steps := int(ceil(radius / sp))
	for j in range(-steps, steps + 1):
		for i in range(-steps, steps + 1):
			var h1 := _hash(float(i), float(j), 1.0)
			var h2 := _hash(float(i), float(j), 2.0)
			var x := centre.x + (float(i) + h1 - 0.5) * sp
			var z := centre.y + (float(j) + h2 - 0.5) * sp
			var d := Vector2(x - centre.x, z - centre.y).length()
			if d > radius:
				continue
			var id := mask.cover_at(x, z)
			if id < 0:
				continue
			var cls := str((mask.green[id] as Dictionary).get("class", ""))
			if not CLASSES.has(cls) or mask.blocked(x, z,
					VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, 0.6):
				continue
			var w: Array = CLASSES[cls]
			var h3 := _hash(float(i), float(j), 3.0)
			var kind := "tuft"
			if h3 > float(w[0]) + float(w[1]):
				kind = "shrub"
			elif h3 > float(w[0]):
				kind = "flower"
			# Thin out toward the radius; shrubs stay sparser.
			# Tufts only near by: from 30 m up, farther ones are specks.
			var r_kind := radius * (0.5 if kind == "tuft" else 1.0)
			if d > r_kind:
				continue
			var keep := 1.0 - smoothstep(r_kind * 0.7, r_kind, d)
			if _hash(float(i), float(j), 4.0) > keep or (kind == "shrub" and _hash(float(i), float(j), 5.0) > 0.5):
				continue
			var s := (0.7 + 0.6 * _hash(float(i), float(j), 6.0)) * (0.6 + 0.4 * keep)
			var v := 0.88 + 0.24 * _hash(float(i), float(j), 7.0)
			# Near the (dehazed, darkened) lawn's own value: the blades
			# darken toward the base in the texture.
			var col := Color(grass.r * v, grass.g * v * (0.95 + 0.1 * h1), grass.b * v) * 1.2
			if kind == "flower":
				col = Color(v, v, v)
			elif kind == "shrub":
				col = Color(grass.r * v * 0.7, grass.g * v * 0.8, grass.b * v * 0.6)
			(per[kind] as Array).append([Vector3(x, ground.height_at_world(x, z), z),
				s, _hash(float(i), float(j), 8.0) * TAU, col])
	return per

static func _grass_colour(data: LocationData) -> Color:
	var dry := ClimateModel.grass_tint(data, data.season)
	if dry.a > 0.0:
		return Color(dry.r, dry.g, dry.b) * 1.4
	match data.season:
		LocationData.Season.AUTUMN:
			return Color(0.42, 0.40, 0.16)
		LocationData.Season.WINTER:
			return Color(0.40, 0.42, 0.30)
		LocationData.Season.SPRING:
			return Color(0.30, 0.50, 0.14)
	return Color(0.26, 0.42, 0.11)

static func _hash(x: float, z: float, salt: float) -> float:
	var v := sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	return v - floor(v)

## Two crossed vertical quads, base on the ground, 1 unit = metres.
static func _card(kind: String) -> ArrayMesh:
	var w := 0.7 if kind == "tuft" else (0.6 if kind == "flower" else 1.4)
	var h := 0.45 if kind == "tuft" else (0.5 if kind == "flower" else 1.1)
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for a in [0.0, PI * 0.5]:
		var dx := Vector3(cos(a), 0.0, sin(a)) * w * 0.5
		var k := verts.size()
		# Tops flare outward so the tuft reads from above, not as a sliver.
		var flare := Vector3(sin(a), 0.0, -cos(a)) * h * 0.35
		verts.append_array([-dx, dx, dx + Vector3(0, h, 0) + flare, -dx + Vector3(0, h, 0) + flare])
		uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m

static func _material(kind: String, season: int) -> ShaderMaterial:
	var key := "%s|%d" % [kind, season]
	if _mats.has(key):
		return _mats[key]
	var sh := Shader.new()
	sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", ImageTexture.create_from_image(_paint(kind, season)))
	m.set_shader_parameter("sway", 0.05 if kind == "shrub" else 0.12)
	_mats[key] = m
	return m

## 128 px card: tapered blades from the base (tuft), blades with
## coloured blossom dots (flower), a rounded leafy mass (shrub).
static func _paint(kind: String, season: int) -> Image:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.4, 0.2, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) + season
	if kind == "shrub":
		for k in 420:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * 0.46
			var cx := 64.0 + cos(a) * r * 128.0
			var cy := 74.0 + sin(a) * r * 100.0 * 0.9
			var v := 0.55 + 0.45 * rng.randf() * (1.0 - (cy / 128.0) * 0.4)
			_disc(img, cx, cy, 3.0 + rng.randf() * 3.0, Color(v * 0.9, v, v * 0.75, 1.0))
		img.generate_mipmaps()
		return img
	var blades := 46 if kind == "tuft" else 30
	for b in blades:
		var bx := 64.0 + rng.randf_range(-40.0, 40.0)
		var lean := rng.randf_range(-0.6, 0.6)
		var ln := rng.randf_range(60.0, 124.0)
		var v := rng.randf_range(0.6, 1.1)
		for t in int(ln):
			var f := float(t) / ln
			var y := 127.0 - float(t)
			var x := bx + lean * float(t) * f
			var wd := maxf(2.2 * (1.0 - f), 0.6)
			var shade := v * (0.78 + 0.32 * f)
			for dx in range(int(floor(x - wd)), int(ceil(x + wd)) + 1):
				if dx >= 0 and dx < n and y >= 0.0:
					img.set_pixel(dx, int(y), Color(shade * 0.85, shade, shade * 0.6, 1.0))
	if kind == "flower":
		var palette := [Color(1.0, 0.92, 0.3), Color(1.0, 1.0, 0.95), Color(0.75, 0.45, 0.95),
			Color(0.95, 0.35, 0.35)]
		for k in 9:
			var c: Color = palette[rng.randi() % palette.size()]
			_disc(img, rng.randf_range(24.0, 104.0), rng.randf_range(8.0, 50.0), 4.5, c)
	img.generate_mipmaps()
	return img

static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r), int(cy + r) + 1):
		for x in range(int(cx - r), int(cx + r) + 1):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() \
					and Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, c)
