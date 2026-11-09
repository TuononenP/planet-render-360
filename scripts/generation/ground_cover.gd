class_name GroundCover
extends RefCounted

## Low ground cover on mapped green land around the viewpoint: grass
## tufts, wildflower clumps and low shrubs as MultiMesh crossed cards
## (alpha-scissored, swaying in the wind). Lawns and meadows were a
## flat texture under the trees; from 30 m up the tufts break them into
## the dappled, tufted surface a real park or alpine meadow shows, and
## shrubs give hedgerows and park edges their mass. Cover takes its colour
## from the ground photo under its root, so it belongs to the lawn it
## stands on, and shrinks away with distance from the eye.
##
## Placement: jittered grid over the green polygons VegetationMask
## rasterised (grass, cemetery, orchard; forest gets ferny shrubs),
## never on buildings, water, carriageways and their verges, mapped
## squares or footpaths (ROAD_EDGE: a square mapped over a grass polygon,
## like the Trocadéro terrace, is paving), inside a radius per tier
## (Fast none). On desktop it reaches on for walking, and also grows on
## unmapped ground the photo shows as green. Chunks keep the far ones
## out of the frame.

## Radius (m) and grid spacing (m) per preset: Fast, Balanced, High, Ultra.
const RADIUS_M := [0.0, 90.0, 170.0, 260.0]
const SPACING_M := [0.0, 3.2, 2.6, 2.1]
## Desktop only: how much further than the view radius cover is laid, so a
## walk finds it.
const WALK_EXTRA_M := [0.0, 0.0, 200.0, 240.0]
## Side of a chunk, and the green index (excess green) unmapped ground needs.
const CHUNK_M := 128.0
const PHOTO_GREEN := 0.07
## Cover keeps this far from hard edges: the strip GroundShader wears to earth.
const EDGE_CLEAR_M := 1.1
const KINDS := ["tuft", "flower", "shrub"]
const CLASSES := {"grass": [0.95, 0.035, 0.015], "cemetery": [0.85, 0.05, 0.10],
	"orchard": [0.80, 0.12, 0.08], "forest": [0.45, 0.0, 0.55], "wetland": [0.9, 0.05, 0.05]}

const SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float sway = 0.12;
// 1 = low enough for lying snow to bury (tufts, flowers), 0 = shrubs.
uniform float buried_by_snow = 1.0;
// Distance from the eye at which this kind has shrunk away.
uniform float fade_m = 260.0;
// @SNOW
varying vec3 wpos;
void vertex() {
	float eye = length(MODEL_MATRIX[3].xyz - CAMERA_POSITION_WORLD);
	VERTEX *= 1.0 - smoothstep(fade_m * 0.7, fade_m, eye);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Snow buries a tuft by degrees: it sinks, it never pops at an edge.
	VERTEX.y *= 1.0 - 0.95 * buried_by_snow * snow_bury(MODEL_MATRIX[3].xyz);
	// Wind: tops sway, bases stay planted; a slow gust front travels.
	float h = clamp(VERTEX.y, 0.0, 1.0);
	float gust = sin(wpos.x * 0.07 + wpos.z * 0.05 - TIME * 1.3) * 0.5 + 0.5;
	float ph = TIME * 2.3 + wpos.x * 0.9 + wpos.z * 0.7;
	VERTEX.x += sin(ph) * sway * h * h * (0.4 + gust);
	VERTEX.z += cos(ph * 0.83) * sway * 0.6 * h * h * (0.4 + gust);
}
void fragment() {
	vec4 t = texture(tex, UV);
	if (t.a < 0.5) {
		discard;
	}
	// Up-facing normals: cards shade like the ground they stand on. Set
	// here, after the back-face flip, or a card seen from behind faces
	// down and goes black in the sun.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec3 c = t.rgb * COLOR.rgb;
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(c, snow_col, sc * 0.8);
	// Thin leaves glow when lit from behind.
	BACKLIGHT = c * 0.3;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	AO = mix(0.8, 1.0, 1.0 - UV.y);
	AO_LIGHT_AFFECT = 0.15;
}
"""

## A tuft's value against the palette: near the lawn it stands on (at 1.2
## the blades were about three times its brightness and read as clip art).
const TUFT_VALUE := 0.8
const TURF_GREY := 0.18
static var _mats: Dictionary = {}

## Adds the cover MultiMeshes to `root` in chunks; returns the instance count.
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask) -> int:
	var p := RenderSettings.clamp_preset(data.quality_preset)
	var radius := float(RADIUS_M[p]) * WorldScale.metres_to_units()
	var chunk := CHUNK_M * WorldScale.metres_to_units()
	var per := plan(data, ground, mask)
	var total := 0
	for kind: String in KINDS:
		var list: Array = per.get(kind, [])
		var cells := {}
		for e: Array in list:
			var o: Vector3 = e[0]
			var c := Vector2i(floori(o.x / chunk), floori(o.z / chunk))
			if not cells.has(c):
				cells[c] = []
			(cells[c] as Array).append(e)
		var fade := fade_for(kind, radius)
		for c: Vector2i in cells:
			root.add_child(_chunk(kind, cells[c], c, chunk, data.season, fade))
		total += list.size()
	return total

## The distance (units) at which `kind` has shrunk away for a view radius.
static func fade_for(kind: String, radius: float) -> float:
	return radius * (0.5 if kind == "tuft" else 1.0)

static func _chunk(kind: String, list: Array, cell: Vector2i, chunk: float, season: int, fade: float) -> MultiMeshInstance3D:
	var first: Vector3 = (list[0] as Array)[0]
	var origin := Vector3((float(cell.x) + 0.5) * chunk, first.y, (float(cell.y) + 0.5) * chunk)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _card(kind)
	mm.instance_count = list.size()
	for n in list.size():
		var e: Array = list[n]
		var b := Basis(Vector3.UP, float(e[2])).scaled(Vector3.ONE * float(e[1]))
		mm.set_instance_transform(n, Transform3D(b, (e[0] as Vector3) - origin))
		mm.set_instance_color(n, e[3])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GroundCover_%s_%d_%d" % [kind, cell.x, cell.y]
	mmi.position = origin
	mmi.multimesh = mm
	mmi.material_override = _material(kind, season, fade)
	# Only low shrubs close to the eye would show a shadow; none is drawn.
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = fade + chunk
	mmi.set_meta("lod_layer", "GroundCover")
	mmi.set_meta("cover_end", fade + chunk)
	return mmi

## Whether this device lays the walking reach, near scatter and photo cover.
static func _desktop() -> bool:
	return not OS.has_feature("mobile")

## Linear photo colour under world (x, z); alpha 0 when there is none.
static func _photo_at(data: LocationData, x: float, z: float) -> Color:
	var img := data.satellite_image
	if img == null or img.is_empty() or img.is_compressed():
		return Color(0, 0, 0, 0)
	var uv := TerrainBuilder.satellite_uv(data, x, z)
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return Color(0, 0, 0, 0)
	var c := img.get_pixel(int(uv.x * float(img.get_width())), int(uv.y * float(img.get_height()))).srgb_to_linear()
	return Color(c.r, c.g, c.b, 1.0)

## The palette colour at its own brightness, taking most of its hue from
## the ground photo under the root.
static func rooted(base: Color, photo: Color) -> Color:
	if photo.a <= 0.0:
		return base
	var lb := base.r * 0.2126 + base.g * 0.7152 + base.b * 0.0722
	var lp := maxf(photo.r * 0.2126 + photo.g * 0.7152 + photo.b * 0.0722, 0.005)
	return base.lerp(Color(photo.r * lb / lp, photo.g * lb / lp, photo.b * lb / lp), 0.6)

## The lawn's calm green (GroundShader takes the same share of grey out).
static func _turf(c: Color) -> Color:
	var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	return c.lerp(Color(l, l, l), TURF_GREY)

## Excess-green index of a linear colour.
static func green_index(c: Color) -> float:
	return (2.0 * c.g - c.r - c.b) / maxf(c.r + c.g + c.b, 0.001)

## Placements per kind: [position, scale, yaw, colour] lists.
static func plan(data: LocationData, ground: GroundTruth, mask: VegetationMask) -> Dictionary:
	var p := RenderSettings.clamp_preset(data.quality_preset)
	var m := WorldScale.metres_to_units()
	var radius := float(RADIUS_M[p]) * m
	if radius <= 0.0:
		return {}
	var desktop := _desktop()
	var photo_cover := desktop and p >= RenderSettings.Preset.HIGH and data.satellite_image != null
	if mask.green.is_empty() and not photo_cover:
		return {}
	var per: Dictionary = {}
	for k in KINDS:
		per[k] = []
	var extra := float(WALK_EXTRA_M[p]) * m if desktop else 0.0
	var reach := radius + extra
	_scatter(per, data, ground, mask, reach, extra > 0.0, float(SPACING_M[p]) * m, photo_cover)
	return per

## One jittered grid of placements out to `reach`.
static func _scatter(per: Dictionary, data: LocationData, ground: GroundTruth, mask: VegetationMask, reach: float,
		full_reach: bool, sp: float, photo_cover: bool) -> void:
	var centre := View360.spawn_xz(data)
	var grass := _grass_colour(data)
	var steps := int(ceil(reach / sp))
	for j in range(-steps, steps + 1):
		for i in range(-steps, steps + 1):
			var h1 := _hash(float(i), float(j), 1.0)
			var h2 := _hash(float(i), float(j), 2.0)
			var x := centre.x + (float(i) + h1 - 0.5) * sp
			var z := centre.y + (float(j) + h2 - 0.5) * sp
			var d := Vector2(x - centre.x, z - centre.y).length()
			if d > reach:
				continue
			var id := mask.cover_at(x, z) if not mask.green.is_empty() else -1
			var cls := "grass"
			var photo := Color(0, 0, 0, 0)
			if id >= 0:
				cls = str((mask.green[id] as Dictionary).get("class", ""))
			else:
				if not photo_cover:
					continue
				photo = _photo_at(data, x, z)
				if photo.a <= 0.0 or green_index(photo) < PHOTO_GREEN:
					continue
			if not CLASSES.has(cls) or mask.blocked(x, z,
					VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.ROAD_EDGE
					| VegetationMask.WATER, EDGE_CLEAR_M * WorldScale.metres_to_units()):
				continue
			var w: Array = CLASSES[cls]
			var h3 := _hash(float(i), float(j), 3.0)
			var kind := "tuft"
			if h3 > float(w[0]) + float(w[1]):
				kind = "shrub"
			elif h3 > float(w[0]):
				kind = "flower"
			# With no walking reach, tufts stop halfway: past that they are specks.
			var r_kind := reach * (0.5 if kind == "tuft" and not full_reach else 1.0)
			if d > r_kind:
				continue
			var keep := 1.0 - smoothstep(r_kind * 0.85, r_kind, d)
			if _hash(float(i), float(j), 4.0) > keep \
					or (kind == "shrub" and _hash(float(i), float(j), 5.0) > 0.5):
				continue
			var s := 0.7 + 0.6 * _hash(float(i), float(j), 6.0)
			var v := 0.88 + 0.24 * _hash(float(i), float(j), 7.0)
			if photo.a <= 0.0 and photo_cover:
				photo = _photo_at(data, x, z)
			var root := rooted(grass, photo)
			var col := _turf(Color(root.r * v, root.g * v * (0.95 + 0.1 * h1), root.b * v)) * TUFT_VALUE
			if kind == "flower":
				col = Color(v, v, v)
			elif kind == "shrub":
				col = Color(root.r * v * 0.7, root.g * v * 0.8, root.b * v * 0.6)
			(per[kind] as Array).append([Vector3(x, ground.height_at_world(x, z), z),
				s, _hash(float(i), float(j), 8.0) * TAU, col])

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

static func _material(kind: String, season: int, fade: float) -> ShaderMaterial:
	var key := "%s|%d|%.1f" % [kind, season, fade]
	if _mats.has(key):
		return _mats[key]
	var sh := Shader.new()
	sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", ImageTexture.create_from_image(_paint(kind, season)))
	m.set_shader_parameter("buried_by_snow", 0.0 if kind == "shrub" else 1.0)
	m.set_shader_parameter("sway", 0.05 if kind == "shrub" else 0.12)
	m.set_shader_parameter("fade_m", fade)
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
