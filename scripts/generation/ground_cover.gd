class_name GroundCover
extends RefCounted

## Low ground cover on mapped green land around the viewpoint: grass
## tufts, meadow seed heads, wildflower clumps and low shrubs as MultiMesh
## cards (GrassCards; alpha to coverage, swaying in the wind). Lawns and meadows were a
## flat texture under the trees; from 30 m up the tufts break them into
## the dappled, tufted surface a real park or alpine meadow shows, and
## shrubs give hedgerows and park edges their mass. A mown lawn (the
## polygon's `sward`) keeps its tufts short, in clumps, and lets them grow
## long only along walls, fences and water; a wild meadow stands knee-high
## with seed heads. Cover takes its colour
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
const PHOTO_MIN_LUM := 0.06
const PHOTO_NEIGHBOUR_M := 4.0
const PHOTO_NEIGHBOURS := 3
## Cover keeps this far from hard edges: the strip GroundShader wears to earth.
const EDGE_CLEAR_M := 1.1
const KINDS := ["tuft", "seedhead", "flower", "shrub"]
## Unmown grass is left standing this far (m) from walls and water.
const EDGE_TALL_M := 3.0
## Height scale ranges of a tuft card (0.45 m): mown lawn, its uncut
## edges, and wild meadow.
const MOWN_H := Vector2(0.3, 0.55)
const EDGE_H := Vector2(0.8, 1.3)
const WILD_H := Vector2(0.9, 1.9)
## Share of a summer or autumn meadow's tufts that carry seed heads.
const SEEDHEAD_SHARE := 0.3
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
	vec3 root = MODEL_MATRIX[3].xyz;
	float eye = length(root - CAMERA_POSITION_WORLD);
	// Thin out by whole tufts with distance, shrinking a little too, so
	// the cover dissolves into the lawn instead of all shrinking at once.
	float keep = 1.0 - smoothstep(fade_m * 0.5, fade_m, eye);
	float pick = fract(sin(dot(root.xz, vec2(12.9898, 78.233))) * 43758.5453);
	VERTEX *= (pick < keep ? 1.0 : 0.0) * mix(1.0, 0.65, smoothstep(fade_m * 0.4, fade_m, eye));
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Snow buries a tuft by degrees: it sinks, it never pops at an edge.
	VERTEX.y *= 1.0 - 0.95 * buried_by_snow * snow_bury(root);
	// Wind: tops sway, bases stay planted; a slow gust front travels.
	float h = clamp(VERTEX.y, 0.0, 1.0);
	float gust = sin(wpos.x * 0.07 + wpos.z * 0.05 - TIME * 1.3) * 0.5 + 0.5;
	float ph = TIME * 2.3 + wpos.x * 0.9 + wpos.z * 0.7;
	VERTEX.x += sin(ph) * sway * h * h * (0.4 + gust);
	VERTEX.z += cos(ph * 0.83) * sway * 0.6 * h * h * (0.4 + gust);
}
void fragment() {
	vec4 t = texture(tex, UV);
	// Alpha to coverage under MSAA: soft blade edges, no shimmer.
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA_ANTIALIASING_EDGE = 0.35;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(tex, 0));
	// Mostly up-facing normals: cards shade like the ground they stand
	// on, with a little of their own form. Set here, after the back-face
	// flip, or a card seen from behind faces down and goes black in the sun.
	vec3 up = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	NORMAL = normalize(mix(NORMAL, up, 0.7));
	vec3 c = t.rgb * COLOR.rgb;
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(c, snow_col, sc * 0.8);
	// Thin leaves glow yellow-green when lit from behind.
	BACKLIGHT = c * vec3(0.4, 0.36, 0.2);
	// Blade tips catch a grazing sun: a little glossier than the bases.
	float tip = 1.0 - UV.y;
	ROUGHNESS = mix(0.88, 0.62, tip);
	SPECULAR = mix(0.2, 0.42, tip);
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
			root.add_child(_chunk(kind, cells[c], c, chunk, data.season, fade, _dry(data)))
		total += list.size()
	return total

## How far (m) the eye may move from where cover was laid before the
## view runs short of it: the walking reach laid beyond the view radius.
static func spare_m(preset: int) -> float:
	return float(WALK_EXTRA_M[RenderSettings.clamp_preset(preset)]) if _desktop() else 0.0

## Lays the cover of a (detached) world afresh around the eye `data`
## opens at, replacing the chunks laid around another eye (a cached world
## reopened at a later camera). Returns the instance count.
static func recentre(world: Node3D, data: LocationData, ground: GroundTruth) -> int:
	for c in world.get_children():
		if c.get_meta("lod_layer", "") == "GroundCover":
			world.remove_child(c)
			c.free()
	return build(world, data, ground, VegetationMask.new(data, ground))

## The distance (units) at which `kind` has shrunk away for a view radius.
static func fade_for(kind: String, radius: float) -> float:
	return radius * (0.5 if kind == "tuft" or kind == "seedhead" else 1.0)

## Whether the place's grass is summer-dry (ClimateModel.grass_tint).
static func _dry(data: LocationData) -> bool:
	return ClimateModel.grass_tint(data, data.season).a > 0.0

static func _chunk(kind: String, list: Array, cell: Vector2i, chunk: float, season: int, fade: float,
		dry: bool) -> MultiMeshInstance3D:
	var first: Vector3 = (list[0] as Array)[0]
	var origin := Vector3((float(cell.x) + 0.5) * chunk, first.y, (float(cell.y) + 0.5) * chunk)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = GrassCards.card(kind)
	mm.instance_count = list.size()
	for n in list.size():
		var e: Array = list[n]
		var s := float(e[1])
		var b := Basis(Vector3.UP, float(e[2])).scaled(Vector3(s, s * float(e[4]), s))
		mm.set_instance_transform(n, Transform3D(b, (e[0] as Vector3) - origin))
		mm.set_instance_color(n, e[3])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GroundCover_%s_%d_%d" % [kind, cell.x, cell.y]
	mmi.position = origin
	mmi.multimesh = mm
	mmi.material_override = _material(kind, season, fade, dry)
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

## Whether a linear photo colour is really vegetation. On dark ground the
## index is noise (shadowed asphalt can read as green), so it needs light too.
static func photo_green(c: Color) -> bool:
	if c.a <= 0.0:
		return false
	return green_index(c) >= PHOTO_GREEN and c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722 >= PHOTO_MIN_LUM

## Whether the ground around (x, z) is green too: one green photo pixel
## can be a tree top or a stray tint over asphalt, a lawn is green all round.
static func _green_around(data: LocationData, x: float, z: float) -> bool:
	var r := PHOTO_NEIGHBOUR_M * WorldScale.metres_to_units()
	var green := 0
	for o: Vector2 in [Vector2(r, 0.0), Vector2(-r, 0.0), Vector2(0.0, r), Vector2(0.0, -r)]:
		if photo_green(_photo_at(data, x + o.x, z + o.y)):
			green += 1
	return green >= PHOTO_NEIGHBOURS

## Excess-green index of a linear colour.
static func green_index(c: Color) -> float:
	return (2.0 * c.g - c.r - c.b) / maxf(c.r + c.g + c.b, 0.001)

## Placements per kind: [position, scale, yaw, colour, height factor] lists.
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
	var u2m := 1.0 / WorldScale.metres_to_units()
	var seeds := data.season == LocationData.Season.SUMMER or data.season == LocationData.Season.AUTUMN
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
			var sward := ""
			var photo := Color(0, 0, 0, 0)
			if id >= 0:
				cls = str((mask.green[id] as Dictionary).get("class", ""))
				sward = str((mask.green[id] as Dictionary).get("sward", ""))
			else:
				if not photo_cover:
					continue
				photo = _photo_at(data, x, z)
				if not photo_green(photo) or ground.land_class_at(x, z) == "urban" \
						or not _green_around(data, x, z):
					continue
				# Unmapped green among houses is a garden; out of town, a meadow.
				sward = "mown" if mask.built_fraction(x, z) > 0.04 else "wild"
			if not CLASSES.has(cls) or mask.blocked(x, z,
					VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.ROAD_EDGE
					| VegetationMask.WATER, EDGE_CLEAR_M * WorldScale.metres_to_units()):
				continue
			if sward == "":
				sward = VegetationMask.sward_of(cls)
			var wild := sward == "wild"
			var w: Array = CLASSES[cls]
			var h3 := _hash(float(i), float(j), 3.0)
			var kind := "tuft"
			if h3 > float(w[0]) + float(w[1]):
				kind = "shrub"
			elif h3 > float(w[0]):
				kind = "flower"
			elif wild and seeds and _hash(float(i), float(j), 9.0) < SEEDHEAD_SHARE:
				kind = "seedhead"
			# With no walking reach, tufts stop halfway: past that they are specks.
			var short := kind == "tuft" or kind == "seedhead"
			var r_kind := reach * (0.5 if short and not full_reach else 1.0)
			if d > r_kind:
				continue
			# Grass grows in clumps: patches thick and thin over ~6-20 m.
			var clump := _vnoise(x * u2m / 6.0, z * u2m / 6.0) * 0.6 \
				+ _vnoise(x * u2m / 19.0 + 7.0, z * u2m / 19.0) * 0.4
			var keep := (1.0 - smoothstep(r_kind * 0.85, r_kind, d)) \
				* (0.75 + 0.5 * clump if wild else 0.35 + 0.8 * clump)
			if _hash(float(i), float(j), 4.0) > keep \
					or (kind == "shrub" and _hash(float(i), float(j), 5.0) > 0.5):
				continue
			var s := 0.7 + 0.6 * _hash(float(i), float(j), 6.0)
			var hr := MOWN_H
			if wild:
				hr = WILD_H
			elif short and mask.blocked(x, z, VegetationMask.BUILDING | VegetationMask.WATER, EDGE_TALL_M):
				hr = EDGE_H
			var hs := 1.0
			if short:
				hs = lerpf(hr.x, hr.y, clampf(clump * 0.7 + _hash(float(i), float(j), 10.0) * 0.5, 0.0, 1.0))
			var v := 0.88 + 0.24 * _hash(float(i), float(j), 7.0)
			if photo.a <= 0.0 and photo_cover:
				photo = _photo_at(data, x, z)
			var root := rooted(grass, photo)
			var col := _turf(Color(root.r * v, root.g * v * (0.95 + 0.1 * h1), root.b * v)) * TUFT_VALUE
			if wild:
				# Standing grass goes a little to straw at the tips.
				col = col.lerp(Color(col.g * 0.95, col.g * 0.9, col.g * 0.45), 0.12 * clump)
			if kind == "flower":
				col = Color(v, v, v)
			elif kind == "shrub":
				col = Color(root.r * v * 0.7, root.g * v * 0.8, root.b * v * 0.6)
			(per[kind] as Array).append([Vector3(x, ground.height_at_world(x, z), z),
				s, _hash(float(i), float(j), 8.0) * TAU, col, hs])

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

## Smooth value noise in [0, 1] over unit cells.
static func _vnoise(x: float, z: float) -> float:
	var ix := floorf(x)
	var iz := floorf(z)
	var fx := x - ix
	var fz := z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	var a := lerpf(_hash(ix, iz, 11.0), _hash(ix + 1.0, iz, 11.0), fx)
	var b := lerpf(_hash(ix, iz + 1.0, 11.0), _hash(ix + 1.0, iz + 1.0, 11.0), fx)
	return lerpf(a, b, fz)

static func _material(kind: String, season: int, fade: float, dry: bool = false) -> ShaderMaterial:
	var key := "%s|%d|%.1f|%s" % [kind, season, fade, dry]
	if _mats.has(key):
		return _mats[key]
	var sh := Shader.new()
	sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", ImageTexture.create_from_image(GrassCards.paint(kind, season, dry)))
	m.set_shader_parameter("buried_by_snow", 0.0 if kind == "shrub" else 1.0)
	m.set_shader_parameter("sway", 0.05 if kind == "shrub" else 0.12)
	m.set_shader_parameter("fade_m", fade)
	_mats[key] = m
	return m
