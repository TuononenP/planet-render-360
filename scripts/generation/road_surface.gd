class_name RoadSurface
extends RefCounted

## The asphalt look for RoadBuilder: one ShaderMaterial that paints a
## road from its own coordinates instead of separate marking meshes
## (which were Ultra-only and ignored lanes and junctions):
## - markings on every tier: dashed centre line (yellow in the Americas,
##   Norway and Finland), a double solid line on
##   wide main roads, lane dividers from the OSM lane count, edge lines
##   on main roads, zebra crossings on urban streets near junctions;
##   paint stops short of junctions and wears in patches;
## - wear: the asphalt photo without visible repetition, darker polished
##   tyre tracks per lane, crack lines, repaired patches, age blotches;
## - kerb and gutter along urban streets (a pale stone band with a
##   bevelled edge and a dark gutter beside it);
## - live weather: rain darkens and glosses the surface with puddles in
##   the low spots, snow settles except in the tyre tracks.
##
## Vertex data (RoadBuilder): UV = (across, along) in 4 m units, UV2.x
## the ribbon width in metres, UV2.y its depth layer, COLOR = (lanes / 8,
## rank / 2, urban kerb flag, distance to the nearest junction / JUNCTION_M).

const JUNCTION_M := 30.0
## Junction nodes are matched on a 0.5 m grid (OSM shares node coords).
const NODE_SNAP := 2.0

## Vertex-stage depth bias by layer (UV2.y, RoadBuilder.depth_layer):
## clip z scaled up by DEPTH_EPS per layer reads as the surface drawn a
## fraction of its distance nearer (reverse Z), on screen where it was.
## A fixed lift can't hold the order at every range; this does at any
## depth precision. Off in the orthographic (sun shadow) pass. Kept small:
## the top layer (~6.8) reads ~0.14 m nearer at 1 km, so a road just
## behind a crest or a kerb stays hidden, while one step (0.11 layer) is
## still ~40 steps of the 32-bit float depth buffer.
const DEPTH_EPS := 0.00002
const DEPTH_GLSL := """
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (PROJECTION_MATRIX[3][3] < 0.5) {
		POSITION.z *= 1.0 + %f * UV2.y;
	}
""" % DEPTH_EPS

## Paving, setts and gravel: StandardMaterial3D's tinted PBR set on the
## ribbon UV, with the same depth bias and weather as the asphalt (rain
## darkens and glosses it, snow settles). The ribbons carry no tangents
## and turn with the road, so the normal map's frame is taken from the
## UV's screen derivatives.
const PAVED_CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D alb_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint = vec3(1.0);
uniform float metallic = 0.0;
// @SNOW
varying vec3 wpos;

void vertex() {
	wpos = VERTEX;
// @DEPTH
}

void fragment() {
	vec3 dp1 = dFdx(VERTEX);
	vec3 dp2 = dFdy(VERTEX);
	vec2 duv1 = dFdx(UV);
	vec2 duv2 = dFdy(UV);
	vec3 dp2perp = cross(dp2, NORMAL);
	vec3 dp1perp = cross(NORMAL, dp1);
	vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
	vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;
	float inv = inversesqrt(max(max(dot(t, t), dot(b, b)), 1e-20));
	TANGENT = t * inv;
	BINORMAL = b * inv;
	vec3 col = tint * texture(alb_tex, UV).rgb;
	float rough = texture(rough_tex, UV).r;
	float wet = climate_wetness;
	col *= mix(1.0, 0.75, wet);
	rough = mix(rough, 0.18, wet);
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(col, snow_col, sc * 0.9);
	NORMAL_MAP = mix(texture(nor_tex, UV).rgb, vec3(0.5, 0.5, 1.0), sc);
	ROUGHNESS = mix(rough, 0.7, sc);
	METALLIC = metallic;
}
"""

const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D alb_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint = vec3(1.0);
uniform vec3 paint_col = vec3(0.70, 0.69, 0.65);
// The line between opposing traffic: white, or yellow (YELLOW_CENTRE).
uniform vec3 centre_col = vec3(0.70, 0.69, 0.65);
uniform vec3 kerb_col = vec3(0.36, 0.35, 0.33);
uniform float junction_m = 30.0;
// 1 on a marked crossing's ribbon: zebra bars along its whole length.
uniform float zebra_all = 0.0;
// @SNOW
varying vec3 wpos;
varying vec4 attr;
varying float width_m;

void vertex() {
	wpos = VERTEX;
	attr = COLOR;
	width_m = UV2.x;
	TANGENT = normalize(vec3(1.0, 0.0, 0.0) - NORMAL * NORMAL.x);
	BINORMAL = normalize(cross(TANGENT, NORMAL));
// @DEPTH
}

float r_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float r_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(r_hash(i), r_hash(i + vec2(1.0, 0.0)), f.x),
		mix(r_hash(i + vec2(0.0, 1.0)), r_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Anti-aliased band |x - c| < hw.
float band(float x, float c, float hw, float aa) {
	return 1.0 - smoothstep(hw - aa, hw + aa, abs(x - c));
}

void fragment() {
	vec2 m = UV * 4.0;
	float x = m.x;
	float y = m.y;
	float w = max(width_m, 0.5);
	float aa = max(fwidth(x), 0.004);
	float faa = max(fwidth(y), 0.004);
	vec2 g = wpos.xz;
	int lanes = int(attr.r * 8.0 + 0.5);
	int rank = int(attr.g * 2.0 + 0.5);
	if (lanes <= 0) {
		lanes = w >= 5.5 ? 2 : 1;
	}
	float jd = attr.a * junction_m;
	// Photo grain at two scales blended on noise: no visible repeat.
	vec3 a1 = texture(alb_tex, g / 4.0).rgb;
	vec3 a2 = texture(alb_tex, mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * g / 9.3 + 0.37).rgb;
	float bl = smoothstep(0.3, 0.7, r_noise(g / 13.0));
	vec3 col = tint * mix(a1, a2, bl);
	float rough = mix(texture(rough_tex, g / 4.0).r, texture(rough_tex, g / 9.3).r, bl);
	vec3 nm = mix(texture(nor_tex, g / 4.0).rgb, vec3(0.5, 0.5, 1.0), bl * 0.5);
	// Age: blotches, repaired rectangles, cracks.
	col *= 0.88 + 0.24 * r_noise(g / 21.0);
	vec2 pc = floor(g / vec2(5.5, 3.5));
	float patch = step(0.9, r_hash(pc + 4.7));
	col *= mix(1.0, 0.78, patch);
	float near = 1.0 - smoothstep(60.0, 220.0, length(VERTEX));
	float crack = 1.0 - smoothstep(0.0, 0.025 + aa * 0.4, abs(r_noise(g / 2.7) - 0.5));
	crack *= smoothstep(0.55, 0.8, r_noise(g / 17.0 + 3.0)) * near;
	col *= 1.0 - 0.35 * crack;
	// Tyre tracks: two polished, darker bands per lane.
	float lw = w / float(lanes);
	float xl = mod(x, lw) - lw * 0.5;
	float track = exp(-pow((abs(xl) - 0.85) / 0.3, 2.0)) * (rank >= 1 ? 1.0 : 0.3);
	col *= 1.0 - 0.08 * track;
	rough -= 0.10 * track;
	// Kerb stone and gutter on urban streets.
	float kerb = 0.0;
	if (attr.b > 0.5 && rank >= 1) {
		float ex = min(x, w - x);
		kerb = 1.0 - smoothstep(0.24 - aa, 0.24 + aa, ex);
		float gut = band(ex, 0.42, 0.18, aa);
		col = mix(col, col * 0.7, gut);
		col = mix(col, kerb_col * (0.9 + 0.2 * r_noise(g * 1.3)), kerb);
		// Bevelled kerb edge: the normal tips toward the carriageway.
		float edge = band(ex, 0.24, 0.05, aa);
		nm = mix(nm, vec3(x < w * 0.5 ? 0.25 : 0.75, 0.5, 0.9), edge);
	}
	// Markings.
	float paint = 0.0;
	float centre = 0.0;
	float jfade = smoothstep(6.0, 9.0, jd);
	float dash = band(mod(y, 9.0), 1.5, 1.5, faa);
	if (rank >= 1 && w >= 5.0) {
		if (rank >= 2 && w >= 9.0) {
			centre = band(x, w * 0.5 - 0.14, 0.06, aa) + band(x, w * 0.5 + 0.14, 0.06, aa);
		} else if (lanes >= 2) {
			centre = band(x, w * 0.5, 0.06, aa) * dash;
		}
		paint += centre;
		for (int k = 1; k < 8; k++) {
			if (k >= lanes) {
				break;
			}
			float px = w * float(k) / float(lanes);
			if (abs(px - w * 0.5) > 0.5) {
				paint += band(x, px, 0.06, aa) * dash;
			}
		}
		if (rank >= 2) {
			float inset = attr.b > 0.5 ? 0.65 : 0.35;
			paint += band(x, inset, 0.07, aa) + band(x, w - inset, 0.07, aa);
		}
		paint *= jfade;
		if (attr.b > 0.5) {
			// Zebra crossing a few metres before the junction.
			float zb = band(jd, 5.0, 1.6, faa) * band(mod(x, 1.0), 0.25, 0.25, aa);
			paint += zb * step(0.6, x) * step(x, w - 0.6);
		}
	}
	if (zebra_all > 0.5) {
		paint = band(mod(x, 1.0), 0.25, 0.25, aa) * step(0.25, x) * step(x, w - 0.25);
	}
	paint = clamp(paint, 0.0, 1.0) * (1.0 - kerb);
	paint *= 0.55 + 0.45 * smoothstep(0.25, 0.6, r_noise(g * 2.3));
	float yel = clamp(centre * jfade / max(paint, 0.001), 0.0, 1.0) * step(0.001, paint);
	col = mix(col, mix(paint_col, centre_col, yel), paint);
	rough = mix(rough, 0.6, paint);
	nm = mix(nm, vec3(0.5, 0.5, 1.0), paint * 0.7);
	// Rain: darker, glossy, puddles in the low spots.
	float wet = climate_wetness;
	float puddle = smoothstep(0.6, 0.7, r_noise(g / 3.5) * 0.7 + r_noise(g / 11.0) * 0.3) * wet;
	col *= mix(1.0, 0.72, wet);
	col = mix(col, col * 0.55, puddle);
	rough = mix(rough, 0.2, wet * 0.85);
	rough = mix(rough, 0.03, puddle);
	nm = mix(nm, vec3(0.5, 0.5, 1.0), puddle);
	// Snow settles except where the tyres run.
	float sc = snow_cover(wpos, 1.0) * (1.0 - 0.75 * track);
	col = mix(col, snow_col, sc * 0.9);
	rough = mix(rough, 0.7, sc);
	ALBEDO = col;
	ROUGHNESS = clamp(rough, 0.02, 1.0);
	NORMAL_MAP = mix(nm, vec3(0.5, 0.5, 1.0), sc);
	NORMAL_MAP_DEPTH = 1.0;
	SPECULAR = 0.4;
}
"""

## Countries whose line between opposing traffic is yellow (MUTCD and
## its Latin American kin; Norway and Finland). Unknown country: the
## Americas by longitude.
const YELLOW_CENTRE := ["US", "CA", "MX", "GT", "BZ", "HN", "SV", "NI", "CR", "PA",
	"CO", "VE", "EC", "PE", "BO", "CL", "AR", "UY", "PY", "BR", "PR", "NO", "FI"]
## Worn traffic yellow (linear albedo).
const YELLOW := Color(0.62, 0.40, 0.05)

static var _mat: ShaderMaterial
static var _centre := Color(0.70, 0.69, 0.65)
## Painted kerb band: granite or concrete by region (KerbBuilder.stone_for).
static var _kerb := Color(0.36, 0.35, 0.33)
static var _paved_shader: Shader
static var _texs: Dictionary = {}

## The shared asphalt material, calibrated to `target` (linear albedo).
static func material(target: Color) -> ShaderMaterial:
	if _mat != null:
		return _mat
	var sh := Shader.new()
	sh.code = CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL).replace("// @DEPTH", DEPTH_GLSL)
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	var mean: Color = (MaterialLibrary.PBR_SETS["asphalt"] as Dictionary)["mean"]
	var t := MaterialLibrary._calib_tint(mean, target)
	_mat.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	_mat.set_shader_parameter("alb_tex", _tex("diff"))
	_mat.set_shader_parameter("nor_tex", _tex("nor"))
	_mat.set_shader_parameter("rough_tex", _tex("rough"))
	_mat.set_shader_parameter("junction_m", JUNCTION_M)
	_mat.set_shader_parameter("centre_col", _centre)
	_mat.set_shader_parameter("kerb_col", _kerb)
	return _mat

## The asphalt material with zebra bars over the whole ribbon: RoadBuilder's
## "crossing" finish (marked crossing ways, drawn over the carriageways).
static func crossing_material(target: Color) -> ShaderMaterial:
	var m := material(target).duplicate() as ShaderMaterial
	m.set_shader_parameter("zebra_all", 1.0)
	return m

## True where the place paints its centre line yellow.
static func yellow_centre(data: LocationData) -> bool:
	if data.country != "":
		return YELLOW_CENTRE.has(data.country.to_upper())
	return data.longitude > -170.0 and data.longitude < -30.0

## Sets the centre-line and kerb colours for `data`'s place (RoadBuilder,
## per build).
static func set_place(data: LocationData) -> void:
	_centre = YELLOW if yellow_centre(data) else Color(0.70, 0.69, 0.65)
	_kerb = KerbBuilder.stone_for(data)
	if _mat != null:
		_mat.set_shader_parameter("centre_col", _centre)
		_mat.set_shader_parameter("kerb_col", _kerb)

## A paved finish's material: PBR set `set_name` calibrated to `target`
## (linear albedo), one per call (RoadBuilder caches per finish).
static func paved_material(set_name: String, target: Color) -> ShaderMaterial:
	if _paved_shader == null:
		_paved_shader = Shader.new()
		_paved_shader.code = PAVED_CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL) \
			.replace("// @DEPTH", DEPTH_GLSL)
	var row: Dictionary = MaterialLibrary.PBR_SETS[set_name]
	var t := MaterialLibrary._calib_tint(row["mean"], target)
	var m := ShaderMaterial.new()
	m.shader = _paved_shader
	m.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	m.set_shader_parameter("metallic", float(row["metal"]))
	m.set_shader_parameter("alb_tex", PbrTextures._set_tex(set_name, "diff"))
	m.set_shader_parameter("nor_tex", PbrTextures._set_tex(set_name, "nor"))
	m.set_shader_parameter("rough_tex", PbrTextures._set_tex(set_name, "rough"))
	return m

static func _tex(map_name: String) -> Texture2D:
	# Keyed by resolution too: desktop Ultra builds read the 2K asphalt.
	var key := map_name + (":2k" if MaterialLibrary.hi_res else "")
	if _texs.has(key):
		return _texs[key]
	var img := (MaterialLibrary._set_image("asphalt", map_name) as Image).duplicate() as Image
	if not img.has_mipmaps():
		img.generate_mipmaps(map_name == "nor")
	_texs[key] = ImageTexture.create_from_image(img)
	return _texs[key]

static func _points(line: Variant) -> PackedVector2Array:
	return line if line is PackedVector2Array \
		else (line as Dictionary).get("points", PackedVector2Array()) if line is Dictionary \
		else PackedVector2Array()

## Depth steps a road can take inside its rank and finish (RoadBuilder.depth_layer).
const DEPTH_STEPS := 8

## Depth step per road (0 .. DEPTH_STEPS - 1): greedy, in road order, so
## roads that share a node (meet at a junction) take different steps and
## never draw at the same depth. Only a road meeting more than
## DEPTH_STEPS - 1 others can repeat a neighbour's step.
static func depth_steps(data: LocationData) -> PackedByteArray:
	var n := data.roads.size()
	var at := {}  # snapped node -> roads through it
	for i in n:
		for p in _points(data.roads[i]):
			var k := Vector2i(roundi(p.x * NODE_SNAP), roundi(p.y * NODE_SNAP))
			var roads: PackedInt32Array = at.get(k, PackedInt32Array())
			if roads.is_empty() or roads[roads.size() - 1] != i:
				roads.append(i)
				at[k] = roads
	var steps := PackedByteArray()
	steps.resize(n)
	steps.fill(255)
	for i in n:
		var used := 0
		for p in _points(data.roads[i]):
			var roads: PackedInt32Array = at[Vector2i(roundi(p.x * NODE_SNAP), roundi(p.y * NODE_SNAP))]
			if roads.size() < 2:
				continue
			for j in roads:
				if j != i and steps[j] != 255:
					used |= 1 << steps[j]
		var s := i % DEPTH_STEPS
		for c in DEPTH_STEPS:
			if used & (1 << c) == 0:
				s = c
				break
		steps[i] = s
	return steps

## Junction nodes of the road network, bucketed by JUNCTION_M cells:
## coordinates (snapped to 1 / NODE_SNAP m) shared by two or more ways.
static func junctions(data: LocationData) -> Dictionary:
	var owner := {}
	var count := {}
	for i in data.roads.size():
		for p in _points(data.roads[i]):
			var k := Vector2i(roundi(p.x * NODE_SNAP), roundi(p.y * NODE_SNAP))
			if owner.get(k, -1) != i:
				count[k] = int(count.get(k, 0)) + 1
				owner[k] = i
	var out := {}
	for k in count:
		if int(count[k]) < 2:
			continue
		var p := Vector2(k) / NODE_SNAP
		var cell := Vector2i(floori(p.x / JUNCTION_M), floori(p.y / JUNCTION_M))
		if not out.has(cell):
			out[cell] = PackedVector2Array()
		var arr: PackedVector2Array = out[cell]
		arr.append(p)
		out[cell] = arr
	return out

## Distance to the nearest junction over JUNCTION_M (capped at 1).
static func junction_frac(buckets: Dictionary, p: Vector2) -> float:
	var c := Vector2i(floori(p.x / JUNCTION_M), floori(p.y / JUNCTION_M))
	var best := JUNCTION_M
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var k := c + Vector2i(dx, dz)
			if buckets.has(k):
				for q in buckets[k] as PackedVector2Array:
					best = minf(best, q.distance_to(p))
	return best / JUNCTION_M
