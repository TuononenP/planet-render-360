class_name RoadSurface
extends RefCounted

## The asphalt look for RoadBuilder: one ShaderMaterial that paints a
## road from its own coordinates instead of separate marking meshes
## (which were Ultra-only and ignored lanes and junctions):
## - markings on every tier: dashed centre line, a double solid line on
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
## the ribbon width in metres, COLOR = (lanes / 8, rank / 2, urban kerb
## flag, distance to the nearest junction / JUNCTION_M).

const JUNCTION_M := 30.0
## Junction nodes are matched on a 0.5 m grid (OSM shares node coords).
const NODE_SNAP := 2.0

const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D alb_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint = vec3(1.0);
uniform vec3 paint_col = vec3(0.70, 0.69, 0.65);
uniform vec3 kerb_col = vec3(0.36, 0.35, 0.33);
uniform float junction_m = 30.0;
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
	float jfade = smoothstep(6.0, 9.0, jd);
	float dash = band(mod(y, 9.0), 1.5, 1.5, faa);
	if (rank >= 1 && w >= 5.0) {
		if (rank >= 2 && w >= 9.0) {
			paint += band(x, w * 0.5 - 0.14, 0.06, aa) + band(x, w * 0.5 + 0.14, 0.06, aa);
		} else if (lanes >= 2) {
			paint += band(x, w * 0.5, 0.06, aa) * dash;
		}
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
	paint = clamp(paint, 0.0, 1.0) * (1.0 - kerb);
	paint *= 0.55 + 0.45 * smoothstep(0.25, 0.6, r_noise(g * 2.3));
	col = mix(col, paint_col, paint);
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

static var _mat: ShaderMaterial
static var _texs: Dictionary = {}

## The shared asphalt material, calibrated to `target` (linear albedo).
static func material(target: Color) -> ShaderMaterial:
	if _mat != null:
		return _mat
	var sh := Shader.new()
	sh.code = CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	var mean: Color = (MaterialLibrary.PBR_SETS["asphalt"] as Dictionary)["mean"]
	var t := MaterialLibrary._calib_tint(mean, target)
	_mat.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	_mat.set_shader_parameter("alb_tex", _tex("diff"))
	_mat.set_shader_parameter("nor_tex", _tex("nor"))
	_mat.set_shader_parameter("rough_tex", _tex("rough"))
	_mat.set_shader_parameter("junction_m", JUNCTION_M)
	return _mat

static func _tex(map_name: String) -> Texture2D:
	if _texs.has(map_name):
		return _texs[map_name]
	var img := (MaterialLibrary._set_image("asphalt", map_name) as Image).duplicate() as Image
	if not img.has_mipmaps():
		img.generate_mipmaps(map_name == "nor")
	_texs[map_name] = ImageTexture.create_from_image(img)
	return _texs[map_name]

## Junction nodes of the road network, bucketed by JUNCTION_M cells:
## coordinates (snapped to 1 / NODE_SNAP m) shared by two or more ways.
static func junctions(data: LocationData) -> Dictionary:
	var owner := {}
	var count := {}
	for i in data.roads.size():
		var line: Variant = data.roads[i]
		var pts: PackedVector2Array = line if line is PackedVector2Array \
			else (line as Dictionary).get("points", PackedVector2Array()) if line is Dictionary \
			else PackedVector2Array()
		for p in pts:
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
