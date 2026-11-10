class_name RoadSurface
extends RefCounted

## The asphalt look for RoadBuilder: one ShaderMaterial that paints a
## road's surface from its own coordinates (RoadPaint lays the markings):
## - wear: the asphalt photo without visible repetition, polished tyre
##   tracks per lane, cracks and repairs along the road, age blotches;
## - kerb and gutter along urban streets (a pale stone band with a
##   bevelled edge and a dark gutter beside it);
## - live weather: rain darkens and glosses the surface with puddles in
##   the low spots, snow settles except in the tyre tracks.
##
## Vertex data (RoadBuilder): UV = (across, along) in 4 m units, UV2.x
## the ribbon width in metres, UV2.y its depth layer, COLOR = ((lanes + 16 for one-way) / 32,
## rank / 2, wear_attr (urban kerb flag + chain wear seed), distance to
## the nearest junction / JUNCTION_M).

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
	rough = mix(rough, 0.3, wet);
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(col, snow_col, sc * 0.9);
	NORMAL_MAP = mix(texture(nor_tex, UV).rgb, vec3(0.5, 0.5, 1.0), sc);
	ROUGHNESS = mix(rough, 0.7, sc);
	METALLIC = metallic;
}
"""

## Noise and exact-coverage line filters, shared with RoadPaint.
const LINE_GLSL := """
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

// Exact coverage of |x - c| < hw over a pixel `aa` wide: a line filling a
// quarter of a pixel reads a quarter as strong, at any range.
float band(float x, float c, float hw, float aa) {
	float h = max(aa * 0.5, 1e-4);
	return clamp((min(x + h, c + hw) - max(x - h, c - hw)) / (2.0 * h), 0.0, 1.0);
}

float run_integral(float t, float period, float on) {
	return floor(t / period) * on + min(mod(t, period), on);
}

// Exact coverage of a repeating run [0, on) over a pixel `aa` wide: dashes
// and bars settle to their duty cycle with distance instead of shimmering.
float runs(float t, float period, float on, float aa) {
	float h = max(aa * 0.5, 1e-4);
	return clamp((run_integral(t + h, period, on) - run_integral(t - h, period, on)) / (2.0 * h), 0.0, 1.0);
}
"""

const CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D alb_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint = vec3(1.0);
uniform vec3 kerb_col = vec3(0.36, 0.35, 0.33);
uniform float junction_m = 30.0;
// Range (m) at which fine cracking has faded out, by preset (DETAIL_M).
uniform float detail_m = 220.0;
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

// @LINE_MATH

// Merges one road-aligned repair into o = (fill, sealant rim, tone).
// d is its signed distance; the outline is roughened, as a hand-cut edge is.
void add_repair(inout vec3 o, float d, float tone, float rim, float x, float y, float a) {
	d += (r_noise(vec2(x, y) * 2.3 + 9.1) - 0.5) * 0.07;
	float fill = 1.0 - smoothstep(-a, a, d);
	o.x = max(o.x, fill);
	o.y = max(o.y, rim * band(d, 0.0, 0.035, a));
	o.z = mix(o.z, tone, fill);
}

// Repairs follow the road, as real ones do. One candidate per cell along
// it: a resurfaced lane, a utility trench, a cut across half the road, a
// small patch. Older chains (age) carry more of them.
vec3 road_repairs(float x, float y, float w, float lw, int lanes, float age, float s, float a) {
	vec3 o = vec3(0.0, 0.0, 1.0);
	float cell = floor(y / 97.0);
	if (r_hash(vec2(cell, s + 11.0)) < 0.25) {
		float hy = mix(18.0, 44.0, r_hash(vec2(cell, s + 12.0)));
		float cy = (cell + 0.5) * 97.0 + (r_hash(vec2(cell, s + 13.0)) - 0.5) * (95.0 - 2.0 * hy);
		float cx = (floor(r_hash(vec2(cell, s + 14.0)) * float(lanes)) + 0.5) * lw;
		float tone = r_hash(vec2(cell, s + 15.0)) < 0.5 ? 0.93 : 1.05;
		add_repair(o, max(abs(x - cx) - lw * 0.5, abs(y - cy) - hy), tone, 0.0, x, y, a);
	}
	cell = floor(y / 61.0);
	if (r_hash(vec2(cell, s + 1.0)) < 0.18 + 0.22 * age) {
		float hy = mix(8.0, 26.0, r_hash(vec2(cell, s + 2.0)));
		float cy = (cell + 0.5) * 61.0 + (r_hash(vec2(cell, s + 3.0)) - 0.5) * (59.0 - 2.0 * hy);
		float cx = mix(0.7, w - 0.7, r_hash(vec2(cell, s + 4.0)));
		float hx = mix(0.25, 0.55, r_hash(vec2(cell, s + 5.0)));
		float tone = mix(0.80, 0.93, r_hash(vec2(cell, s + 6.0)));
		add_repair(o, max(abs(x - cx) - hx, abs(y - cy) - hy), tone, 1.0, x, y, a);
	}
	cell = floor(y / 43.0);
	if (r_hash(vec2(cell, s + 21.0)) < 0.10 + 0.16 * age) {
		float hy = mix(0.3, 0.6, r_hash(vec2(cell, s + 22.0)));
		float cy = (cell + 0.5) * 43.0 + (r_hash(vec2(cell, s + 23.0)) - 0.5) * 38.0;
		float cx = r_hash(vec2(cell, s + 24.0)) < 0.5 ? w * 0.25 : w * 0.75;
		add_repair(o, max(abs(x - cx) - w * 0.25 - 0.1, abs(y - cy) - hy), 0.86, 1.0, x, y, a);
	}
	cell = floor(y / 13.0);
	if (r_hash(vec2(cell, s + 31.0)) < 0.06 + 0.16 * age) {
		float hy = mix(0.6, 2.6, r_hash(vec2(cell, s + 32.0)));
		float cy = (cell + 0.5) * 13.0 + (r_hash(vec2(cell, s + 33.0)) - 0.5) * (12.0 - 2.0 * hy);
		float cx = (floor(r_hash(vec2(cell, s + 34.0)) * float(lanes)) + 0.5) * lw;
		float hx = min(0.35 * lw, mix(0.6, 1.6, r_hash(vec2(cell, s + 35.0))));
		float tone = mix(0.80, 0.95, r_hash(vec2(cell, s + 36.0)));
		add_repair(o, max(abs(x - cx) - hx, abs(y - cy) - hy), tone, 1.0, x, y, a);
	}
	return o;
}

// Distance from the second-nearest to the nearest cell point: small on
// the borders between cells, which is where fatigue cracks run.
float crack_cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float f1 = 8.0;
	float f2 = 8.0;
	for (int v = -1; v <= 1; v++) {
		for (int u = -1; u <= 1; u++) {
			vec2 o = vec2(float(u), float(v));
			vec2 c = i + o;
			float d = length(o + vec2(r_hash(c + 0.7), r_hash(c + 13.1)) - f);
			if (d < f1) {
				f2 = f1;
				f1 = d;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return f2 - f1;
}

// Fatigue ("alligator") cracking over `region`, in metres p.
float cell_cracks(vec2 p, float region, float a) {
	if (region < 0.02) {
		return 0.0;
	}
	vec2 warp = vec2(r_noise(p * 0.7), r_noise(p * 0.7 + 7.0)) * 0.5;
	// The line thins with its pixel footprint instead of widening into a
	// dark net at range.
	float line_w = 0.06;
	float px = a / 0.42;
	return region * (line_w / (line_w + px)) * (1.0 - smoothstep(0.0, line_w + px, crack_cells(p / 0.42 + warp)));
}

// Road-aligned cracks: x hairline coverage, y sealed (tar-filled)
// coverage. Long ones wander along lane joints and the road edges;
// thermal ones cross part of the road every so often.
vec2 road_cracks(float x, float y, float w, float lw, int lanes, float age, float s, float aa, float faa) {
	float last = float(lanes);
	float k = clamp(floor(x / lw + 0.5), 0.0, last);
	float inset = k < 0.5 ? 0.3 : (k > last - 0.5 ? -0.3 : 0.0);
	float wob = (r_noise(vec2(y / 7.3, k + s)) - 0.5) * 0.8 + (r_noise(vec2(y / 1.1, k * 2.0 + s)) - 0.5) * 0.13;
	float line = x - k * lw - inset - wob;
	float on = smoothstep(0.62 - 0.14 * age, 0.74 - 0.14 * age, r_noise(vec2(y / 23.0, k * 3.1 + s * 0.7)));
	vec2 c = vec2(0.0);
	if (r_hash(vec2(floor(y / 31.0), k + s + 41.0)) < 0.35) {
		c.y = on * band(line, 0.0, 0.035, aa);
	} else {
		c.x = on * band(line, 0.0, 0.010 + 0.006 * r_noise(vec2(y * 1.7, s)), aa);
	}
	float cell = floor(y / 17.0);
	if (r_hash(vec2(cell, s + 51.0)) < 0.18 + 0.4 * age) {
		float cy = (cell + 0.5) * 17.0 + (r_hash(vec2(cell, s + 52.0)) - 0.5) * 9.0;
		float bend = (r_noise(vec2(x / 2.3, cell + s)) - 0.5) * 0.9 + (r_noise(vec2(x / 0.7, cell)) - 0.5) * 0.1;
		float cx = mix(0.0, w, r_hash(vec2(cell, s + 53.0)));
		float reach = mix(0.35, 0.7, r_hash(vec2(cell, s + 54.0))) * w;
		c.x = max(c.x, band(y - bend, cy, 0.012, faa) * band(x, cx, reach, aa));
	}
	return c;
}

void fragment() {
	vec2 m = UV * 4.0;
	float x = m.x;
	float y = m.y;
	float w = max(width_m, 0.5);
	float aa = max(fwidth(x), 0.004);
	float faa = max(fwidth(y), 0.004);
	vec2 g = wpos.xz;
	int encoded_lanes = int(attr.r * 32.0 + 0.5);
	bool oneway = encoded_lanes >= 16;
	int lanes = encoded_lanes % 16;
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
	// Age: slow blotches and a finer mottling of binder and aggregate.
	col *= 0.90 + 0.20 * r_noise(g / 21.0);
	col *= 0.96 + 0.08 * r_noise(g / 2.7 + 5.1);
	// Wear reads along a road, so it needs across/along coordinates, and
	// aprons have no width.
	// The chain's seed changes how much wear it has, not its colour, so
	// ways that meet still match.
	bool urban = attr.b >= 0.5;
	bool lane_coords = width_m >= 2.0;
	float age = lane_coords ? clamp((urban ? attr.b - 0.5 : attr.b) / 0.45, 0.0, 1.0) : r_noise(g / 40.0);
	float s = age * 97.0;
	float jfade = smoothstep(2.5, 5.0, jd);
	float lw = w / float(lanes);
	float xl = mod(x, lw) - lw * 0.5;
	float near = 1.0 - smoothstep(detail_m * 0.27, detail_m, length(VERTEX));
	float crack = 0.0;
	float sealed = 0.0;
	if (lane_coords) {
		// Tyre tracks: two polished bands per lane that wander with the traffic.
		float lane_id = floor(x / lw);
		float wander = (r_noise(vec2(lane_id * 3.7 + s, y / 23.0)) - 0.5) * 0.28;
		float polish = 0.55 + 0.45 * r_noise(vec2(lane_id + s, y / 31.0));
		float tk = (abs(xl + wander) - 0.85) / 0.32;
		float track = exp(-tk * tk) * (rank >= 1 ? polish : 0.3 * polish) * jfade;
		col *= 1.0 - 0.08 * track;
		rough -= 0.10 * track;
		// Oil drips down the middle of a lane, thickest where cars queue.
		if (rank >= 1) {
			float ox = xl / 0.42;
			float oil = exp(-ox * ox) * smoothstep(0.35, 0.75, r_noise(vec2(x * 0.9, y / 3.4 + s)));
			col *= 1.0 - (0.05 + 0.09 * (1.0 - smoothstep(6.0, 28.0, jd))) * oil;
			rough -= 0.06 * oil;
			// The paving joint between lanes.
			if (lanes >= 2) {
				float joint = clamp(floor(x / lw + 0.5), 1.0, float(lanes) - 1.0) * lw;
				float jw = (r_noise(vec2(y / 13.0, s)) - 0.5) * 0.1;
				col *= 1.0 - 0.07 * band(x + jw, joint, 0.02, aa) * jfade;
			}
		}
		vec3 rep = road_repairs(x, y, w, lw, lanes, age, s, max(aa, faa));
		col *= mix(1.0, rep.z, rep.x * jfade);
		col *= 1.0 - 0.38 * rep.y * jfade;
		rough += 0.05 * rep.x * jfade;
		if (near > 0.0) {
			vec2 cr = road_cracks(x, y, w, lw, lanes, age, s, aa, faa);
			crack = cr.x;
			sealed = cr.y;
			crack = max(crack, cell_cracks(vec2(x, y), clamp(track * smoothstep(0.6, 0.76, r_noise(g / 9.0 + s)) * age * 1.4, 0.0, 1.0), max(aa, faa)));
		}
	} else if (near > 0.0) {
		crack = cell_cracks(g, smoothstep(0.74, 0.9, r_noise(g / 11.0)) * 0.35, max(aa, faa));
	}
	col *= 1.0 - (0.5 * crack + 0.4 * sealed) * near;
	rough -= 0.15 * sealed * near;
	// Kerb stone and gutter on urban streets, open across junction mouths.
	float kerb = 0.0;
	if (urban && rank >= 1) {
		float ex = min(x, w - x);
		kerb = (1.0 - smoothstep(0.24 - aa, 0.24 + aa, ex)) * jfade;
		float gut = band(ex, 0.42, 0.18, aa) * jfade;
		col = mix(col, col * 0.7, gut);
		col = mix(col, kerb_col * (0.9 + 0.2 * r_noise(g * 1.3)), kerb);
		// Bevelled kerb edge: the normal tips toward the carriageway.
		float edge = band(ex, 0.24, 0.05, aa);
		nm = mix(nm, vec3(x < w * 0.5 ? 0.25 : 0.75, 0.5, 0.9), edge);
	}
	// Rain: darker with a soft sheen. Water lies in the low spots and
	// along the kerbs, never as one sheet, and rain rings it.
	float wet = climate_wetness;
	float pixel_m = length(fwidth(g));
	// The gutter beside a kerb collects the most; never the kerb itself.
	float gutter = (urban && rank >= 1) ? smoothstep(0.24, 0.4, min(x, w - x)) * (1.0 - smoothstep(0.6, 1.8, min(x, w - x))) : 0.0;
	vec2 mask = puddle_mask(puddle_low(g, pixel_m) + 0.18 * gutter) * wet * (1.0 - kerb);
	float puddle = mask.x;
	col = puddle_albedo(col * mix(1.0, 0.76, wet), mask);
	rough = puddle_roughness(rough, wet, mask);
	nm = mix(nm, vec3(0.5, 0.5, 1.0), max(mask.y * 0.4, puddle));
	if (puddle > 0.01 && near > 0.0) {
		nm.xy += rain_ripples(g, TIME, pixel_m) * 0.25 * puddle;
	}
	// Snow packs on the carriageway. Tyres grind it to grey slush that
	// wanders with the traffic instead of ruling straight lines.
	float sc = snow_cover(wpos, 1.0);
	if (sc > 0.0) {
		float wander = (r_noise(vec2(x * 0.4, y / 16.0)) - 0.5) * 0.7;
		float tk = (abs(xl + wander) - 0.85) / 0.34;
		float grind = 0.7 * exp(-tk * tk) * (rank >= 1 ? 1.0 : 0.3)
			* (0.55 + 0.45 * smoothstep(0.3, 0.7, r_noise(g * 1.6) * 0.6 + r_noise(g * 5.0) * 0.4));
		vec3 slush = vec3(0.46, 0.47, 0.49) * (0.85 + 0.3 * r_noise(g / 1.3));
		col = mix(col, mix(snow_col, slush, grind), sc * 0.95);
		rough = mix(rough, mix(0.7, 0.42, grind), sc);
	}
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
## Painted kerb band: granite or concrete by region (KerbBuilder.stone_for).
static var _kerb := Color(0.36, 0.35, 0.33)
## Crack range (m) per preset: Fast, Balanced, High, Ultra.
const DETAIL_M := [90.0, 130.0, 180.0, 220.0]
static var _detail_m := 220.0
static var _paved_shader: Shader
static var _texs: Dictionary = {}

## The shared asphalt material, calibrated to `target` (linear albedo).
static func material(target: Color) -> ShaderMaterial:
	if _mat != null:
		return _mat
	var sh := Shader.new()
	sh.code = CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL).replace("// @DEPTH", DEPTH_GLSL) \
		.replace("// @LINE_MATH", LINE_GLSL)
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	var mean: Color = (MaterialLibrary.PBR_SETS["asphalt"] as Dictionary)["mean"]
	var t := MaterialLibrary._calib_tint(mean, target)
	_mat.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	_mat.set_shader_parameter("alb_tex", _tex("diff"))
	_mat.set_shader_parameter("nor_tex", _tex("nor"))
	_mat.set_shader_parameter("rough_tex", _tex("rough"))
	_mat.set_shader_parameter("junction_m", JUNCTION_M)
	_mat.set_shader_parameter("kerb_col", _kerb)
	_mat.set_shader_parameter("detail_m", _detail_m)
	return _mat

## RoadBuilder finish of a crossing's style; "auto" takes the country's
## usual paint for a signalled crossing, zebra otherwise.
static func crossing_finish(style: String, signalled: bool, data: LocationData) -> String:
	var resolved := style
	if resolved == "auto":
		resolved = "zebra"
		if signalled and data.country.to_upper() == "DE":
			resolved = "dashes"
		elif signalled and data.country.to_upper() in ["US", "CA"]:
			resolved = "lines"
	return "crossing" if resolved == "zebra" else "crossing_" + resolved

## True where the place paints its centre line yellow.
static func yellow_centre(data: LocationData) -> bool:
	if data.country != "":
		return YELLOW_CENTRE.has(data.country.to_upper())
	return data.longitude > -170.0 and data.longitude < -30.0

## True where a town street's centre line is a solid double line (the
## MUTCD's no-passing marking and its Latin American kin), not dashes.
static func double_centre(data: LocationData) -> bool:
	return yellow_centre(data) and not data.country.to_upper() in ["NO", "FI"]

## Sets the kerb colour, the crack range and the paint's style for
## `data`'s place (RoadBuilder, per build).
static func set_place(data: LocationData) -> void:
	RoadPaint.set_place(data)
	_kerb = KerbBuilder.stone_for(data)
	_detail_m = float(DETAIL_M[RenderSettings.clamp_preset(data.quality_preset)])
	if _mat != null:
		_mat.set_shader_parameter("kerb_col", _kerb)
		_mat.set_shader_parameter("detail_m", _detail_m)

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
## crossing_kind of each painted finish (the shader's branches).
const CROSSING_KINDS := {"zebra": 1.0, "ladder": 2.0, "lines": 3.0, "dashes": 4.0, "solid": 5.0}

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

## COLOR.b of a ribbon: the urban kerb flag in the top half (0.5 and up),
## the chain's wear seed (0..1) scaled into the rest.
static func wear_attr(urban: bool, seed_01: float) -> float:
	return (0.5 if urban else 0.0) + clampf(seed_01, 0.0, 1.0) * 0.45

## A wear seed (0..1) per road. OSM splits a street into many ways, so ways
## that run on in line at a shared end form one chain with one seed, and
## the street ages as a whole. Taken from the chain's lowest end node, so
## it does not depend on the order of the road list.
static func wear_seeds(data: LocationData) -> PackedFloat32Array:
	var n := data.roads.size()
	var parent := PackedInt32Array()
	parent.resize(n)
	var ends := {}
	for i in n:
		parent[i] = i
		if not is_carriageway(data.roads[i]):
			continue
		var pts := _points(data.roads[i])
		if pts.size() < 2:
			continue
		for k: Vector2i in [node_key(pts[0]), node_key(pts[pts.size() - 1])]:
			var ids: PackedInt32Array = ends.get(k, PackedInt32Array())
			ids.append(i)
			ends[k] = ids
	for k: Vector2i in ends:
		var ids: PackedInt32Array = ends[k]
		for a in ids.size():
			for b in range(a + 1, ids.size()):
				if RoadMarkings._in_line(_points(data.roads[ids[a]]), _points(data.roads[ids[b]]), k):
					parent[RoadMarkings._find(parent, ids[a])] = RoadMarkings._find(parent, ids[b])
	var lowest := {}
	for i in n:
		var pts := _points(data.roads[i])
		if pts.is_empty():
			continue
		var root := RoadMarkings._find(parent, i)
		for k: Vector2i in [node_key(pts[0]), node_key(pts[pts.size() - 1])]:
			if not lowest.has(root) or k < (lowest[root] as Vector2i):
				lowest[root] = k
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var root := RoadMarkings._find(parent, i)
		if lowest.has(root):
			out[i] = float(hash(lowest[root]) & 0xFFFF) / 65535.0
	return out

## `highway` values that are no road traffic uses: planned or being
## built, a stop's platform, a race track.
const NOT_ROADS := ["proposed", "construction", "platform", "raceway", "rest_area", "services", "elevator"]

## A road cars drive on as far as junction paint is concerned: not paths,
## crossings or areas, not driveways, not underground.
static func is_carriageway(line: Variant) -> bool:
	if line is PackedVector2Array:
		return true
	if not (line is Dictionary):
		return false
	var r: Dictionary = line
	if str(r.get("crossing_style", "")) != "" or bool(r.get("area", false)) or bool(r.get("tunnel", false)):
		return false
	var cls := str(r.get("class", "unclassified"))
	return cls != "service" and not cls in NOT_ROADS and RoadBuilder._rank(cls) >= 1

static func node_key(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x * NODE_SNAP), roundi(p.y * NODE_SNAP))

## Nodes where carriageways really meet: {node_key: true} with branch
## degree of at least 3 (a way through counts 2, a way ending 1) from at
## least two ways, so a way merely split in two is no junction.
static func carriageway_nodes(data: LocationData) -> Dictionary:
	var degree := {}
	var ways := {}
	var last := {}
	for i in data.roads.size():
		if not is_carriageway(data.roads[i]):
			continue
		var pts := _points(data.roads[i])
		for j in pts.size():
			var k := node_key(pts[j])
			degree[k] = int(degree.get(k, 0)) + (1 if j == 0 or j == pts.size() - 1 else 2)
			if int(last.get(k, -1)) != i:
				last[k] = i
				ways[k] = int(ways.get(k, 0)) + 1
	var out := {}
	for k: Vector2i in degree:
		if int(degree[k]) >= 3 and int(ways[k]) >= 2:
			out[k] = true
	return out

## carriageway_nodes bucketed like junctions, for lane and kerb paint.
static func carriageway_junctions(data: LocationData) -> Dictionary:
	var out := {}
	for k: Vector2i in carriageway_nodes(data):
		var p := Vector2(k) / NODE_SNAP
		var cell := Vector2i(floori(p.x / JUNCTION_M), floori(p.y / JUNCTION_M))
		var arr: PackedVector2Array = out.get(cell, PackedVector2Array())
		arr.append(p)
		out[cell] = arr
	return out

## Junction nodes of the road network, bucketed by JUNCTION_M cells:
## coordinates (snapped to 1 / NODE_SNAP m) shared by two or more ways.
## Includes footways and crossings on purpose: kerbs are cut and cars
## kept clear at those too. Lane paint uses carriageway_junctions.
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

## Countries driving on the left (ISO 3166-1); shared with parked vehicles.
const LEFT_TRAFFIC := ["GB", "IE", "MT", "CY", "AU", "NZ", "JP", "IN", "PK", "BD", "LK", "NP", "BT",
	"TH", "MY", "SG", "ID", "BN", "TL", "HK", "MO", "ZA", "NA", "BW", "LS", "SZ", "ZW", "ZM", "MW",
	"MZ", "TZ", "KE", "UG", "MU", "SC", "MV", "JM", "BB", "BS", "TT", "AG", "DM", "GD", "KN", "LC",
	"VC", "GY", "SR", "FJ", "PG", "SB", "TO", "WS", "KI", "TV", "NR", "CK", "NU", "IM", "JE", "GG",
	"BM", "KY", "TC", "VG", "VI", "AI", "MS", "FK", "SH", "IO", "PN"]

static func left_traffic(data: LocationData) -> bool:
	return data.country.to_upper() in LEFT_TRAFFIC
