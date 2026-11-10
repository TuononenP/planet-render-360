class_name RoadPaint
extends RefCounted

## Road paint as its own blended layer over the road surface: lane, centre
## and edge lines, crossings and stop lines. The asphalt below stays one
## continuous surface, and paint can lie on any finish (a zebra on setts
## no longer brings a band of asphalt with it).
##
## Lines are narrow carrier strips laid from each street's lane layout,
## with the line itself drawn at exact pixel coverage inside the carrier
## (a 12 cm strip of its own would drop out of rasterisation at range).
## Ways that run on in line with the same layout are joined first, so a
## dash pattern survives OSM's splits. Paint wears: aggregate shows through
## it, wheels scuff crossings and stop lines, older streets have less left.
##
## Vertex data on a line strip: UV = (across, along) in 4 m units, UV2.x
## the strip width in metres, UV2.y its depth layer, COLOR = (half width /
## HALF_MAX_M, line_code / 15, wear seed, distance to the nearest junction
## / RoadSurface.JUNCTION_M). Crossings use the ribbon's own coordinates.

const CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 paint_col = vec3(0.70, 0.69, 0.65);
// The line between opposing traffic: white, or yellow (RoadSurface.YELLOW_CENTRE).
uniform vec3 centre_col = vec3(0.70, 0.69, 0.65);
uniform float junction_m = 30.0;
uniform float half_max_m = 0.5;
// Dash (on, off) in metres, by pattern: urban, rural, motorway.
uniform vec2 dash_urban = vec2(3.0, 6.0);
uniform vec2 dash_rural = vec2(3.0, 6.0);
uniform vec2 dash_motorway = vec2(3.0, 6.0);
// RoadSurface.CROSSING_KINDS; 0 = a line strip.
uniform float crossing_kind = 0.0;
// @SNOW
varying vec3 wpos;
varying vec4 attr;
varying float width_m;

void vertex() {
	wpos = VERTEX;
	attr = COLOR;
	width_m = UV2.x;
// @DEPTH
}

// @LINE_MATH

void fragment() {
	vec2 m = UV * 4.0;
	float x = m.x;
	float y = m.y;
	float w = max(width_m, 0.05);
	float aa = max(fwidth(x), 0.004);
	float faa = max(fwidth(y), 0.004);
	float foot = max(aa, faa);
	vec2 g = wpos.xz;
	float paint = 0.0;
	float age = 0.0;
	float scuff = 0.0;
	bool yellow = false;
	if (crossing_kind > 0.5) {
		age = r_noise(g / 31.0 + 3.7);
		// Bars span the ribbon and repeat along the walking line (y);
		// rails run along its two edges.
		float bars = runs(y - 0.25, 1.0, 0.5, faa) * band(x, w * 0.5, w * 0.5 - 0.25, aa);
		float rails = band(x, 0.15, 0.15, aa) + band(x, w - 0.15, 0.15, aa);
		if (crossing_kind < 1.5) {
			paint = bars;
		} else if (crossing_kind < 2.5) {
			paint = bars * band(x, w * 0.5, w * 0.5 - 0.45, aa) + rails;
		} else if (crossing_kind < 3.5) {
			paint = rails;
		} else if (crossing_kind < 4.5) {
			paint = rails * runs(y - 0.25, 1.0, 0.5, faa);
		} else {
			paint = 1.0;
		}
		// Traffic crosses this paint: two wheel paths per lane, along y.
		float lane = mod(y + r_noise(g * 0.02) * 3.4, 3.4) - 1.7;
		float tk = (abs(lane) - 0.85) / 0.4;
		scuff = exp(-tk * tk) * (0.25 + 0.35 * age);
	} else {
		int code = int(attr.g * 15.0 + 0.5);
		int pattern = code & 3;
		yellow = (code & 4) != 0;
		age = attr.b;
		float half_w = attr.r * half_max_m;
		float ragged = (r_noise(vec2(y * 9.0, age * 50.0)) - 0.5) * 0.02;
		float dash = 1.0;
		if (pattern > 0) {
			vec2 d = pattern == 1 ? dash_urban : (pattern == 2 ? dash_rural : dash_motorway);
			dash = runs(y + ragged, d.x + d.y, d.x, faa);
		}
		paint = band(x + ragged, w * 0.5, half_w, aa) * dash;
		paint *= smoothstep(2.5, 5.0, attr.a * junction_m);
		// A strip narrower than a pixel starts to drop out: lines fade before it.
		paint *= 1.0 - smoothstep(350.0, 650.0, length(VERTEX));
	}
	// The binder wears off the aggregate's peaks first. Past what a pixel
	// can show, that becomes its mean.
	float fine = r_noise(g * 37.0) * 0.55 + r_noise(g * 83.0) * 0.45;
	float bare = 0.08 + 0.2 * age;
	float detail = 1.0 - smoothstep(0.015, 0.1, foot);
	// A worn pit keeps a film of paint: it dims, it never punches through.
	float pits = mix(0.5, 1.0, smoothstep(bare - 0.12, bare + 0.12, fine));
	float body = mix(1.0 - bare * 0.5, pits, detail);
	float patchy = 0.78 + 0.22 * smoothstep(0.22, 0.55, r_noise(g * 2.3 + age * 7.0));
	float kept = body * patchy * (1.0 - 0.22 * age) * (1.0 - scuff);
	vec3 col = (yellow ? centre_col : paint_col) * (0.9 + 0.15 * r_noise(g / 2.1));
	float wet = climate_wetness;
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = col * mix(1.0, 0.82, wet);
	ALPHA = clamp(paint, 0.0, 1.0) * kept * (1.0 - sc);
	ROUGHNESS = mix(0.6, 0.25, wet);
	SPECULAR = 0.4;
	// Thermoplastic stands a little proud of the road: its edges catch the
	// light up close. The coverage's own gradient is the slope.
	if (detail > 0.0) {
		vec3 sx = dFdx(VERTEX);
		vec3 sy = dFdy(VERTEX);
		vec3 slope = dFdx(paint) * sx / max(dot(sx, sx), 1e-8) + dFdy(paint) * sy / max(dot(sy, sy), 1e-8);
		NORMAL = normalize(NORMAL - slope * 0.02 * detail);
	}
}
"""

## Width of a line's carrier strip (m), its widest line half width (m).
const CARRIER_M := 0.6
const HALF_MAX_M := 0.5
const MIN_LINED_M := 5.0
## Narrower lanes than this leave no room for a marked parking or bike lane.
const MIN_LANE_M := 2.2
const CYCLE_LANE_M := 1.5
const EDGE_EXTRA_M := 0.01
## Pattern ids in line_code's low two bits, and its yellow bit.
const SOLID := 0
const PATTERN := {"urban": 1, "rural": 2, "motorway": 3}
const YELLOW_BIT := 4
## Depth steps stay inside the crossing band, above every carriageway.
const LAYER := 6.9

## Dashes [on m, off m, line width m] by country and road kind, from
## published standards. Countries without a verified source use "". Unverified
## and deliberately left at the default: DE, FI, GB.
## US: MUTCD part 3A, 10 ft line, 30 ft gap, 4-6 in wide.
## JP: MLIT 1974 demarcation standard, 5 m, 5 m, 0.15 m.
## FR: IISR part 7, T1 3 m, 10 m (line width not established; default kept).
## AT: Bodenmarkierungsverordnung: built-up 3 m, 3 m; rural 6 m, 9 m at
## least 10 cm; motorways 6 m, 12 m at least 15 cm.
const STYLES := {
	"": {"urban": [3.0, 6.0, 0.12], "rural": [3.0, 6.0, 0.12], "motorway": [3.0, 6.0, 0.12]},
	"US": {"urban": [3.05, 9.14, 0.125], "rural": [3.05, 9.14, 0.125], "motorway": [3.05, 9.14, 0.125]},
	"JP": {"urban": [5.0, 5.0, 0.15], "rural": [5.0, 5.0, 0.15], "motorway": [5.0, 5.0, 0.15]},
	"FR": {"urban": [3.0, 10.0, 0.12], "rural": [3.0, 10.0, 0.12], "motorway": [3.0, 10.0, 0.12]},
	"AT": {"urban": [3.0, 3.0, 0.12], "rural": [6.0, 9.0, 0.10], "motorway": [6.0, 12.0, 0.15]},
}

static var _mat: ShaderMaterial
static var _centre := Color(0.70, 0.69, 0.65)
static var _shader: Shader
static var _dashes := {}

static func _shader_for_paint() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL) \
			.replace("// @DEPTH", RoadSurface.DEPTH_GLSL) \
			.replace("// @LINE_MATH", RoadSurface.LINE_GLSL)
	return _shader

## The shared material of the line strips.
static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = _shader_for_paint()
		_mat.render_priority = -1
		_apply(_mat)
	return _mat

## The paint of a crossing or stop line (RoadSurface.CROSSING_KINDS).
static func crossing_material(kind: float) -> ShaderMaterial:
	var m := material().duplicate() as ShaderMaterial
	m.render_priority = -1
	m.set_shader_parameter("crossing_kind", kind)
	return m

static func _apply(m: ShaderMaterial) -> void:
	m.set_shader_parameter("centre_col", _centre)
	m.set_shader_parameter("junction_m", RoadSurface.JUNCTION_M)
	m.set_shader_parameter("half_max_m", HALF_MAX_M)
	for kind: String in PATTERN:
		m.set_shader_parameter("dash_" + kind, _dashes.get(kind, Vector2(3.0, 6.0)))

## Sets the centre-line colour and dash patterns for `data`'s place.
static func set_place(data: LocationData) -> void:
	_centre = RoadSurface.YELLOW if RoadSurface.yellow_centre(data) else Color(0.70, 0.69, 0.65)
	for kind: String in PATTERN:
		var s: Array = style_for(data.country, kind)
		_dashes[kind] = Vector2(float(s[0]), float(s[1]))
	if _mat != null:
		_apply(_mat)

## [on m, off m, width m] of a country's lines on `kind` roads.
static func style_for(country: String, kind: String) -> Array:
	var row: Dictionary = STYLES.get(country.to_upper(), STYLES[""])
	return row[kind]

static func kind_of(cls: String, urban: bool) -> String:
	if cls in ["motorway", "trunk", "motorway_link", "trunk_link"]:
		return "motorway"
	return "urban" if urban else "rural"

## The kerbside strips a road's lanes keep clear of: x left, y right (m).
static func parking_strips(road: Dictionary) -> Vector2:
	var sides := int(road.get("parking", -1))
	if sides > 0:
		return Vector2(OsmTags.PARKING_LANE_M if sides & 1 else 0.0, OsmTags.PARKING_LANE_M if sides & 2 else 0.0)
	var extra := float(road.get("parking_m", 0.0))
	if sides < 0 and extra > 0.0:
		# This room is inferred: a mapped bike lane keeps its kerb instead.
		var cycle := int(road.get("cycle_lane", 0))
		return Vector2(0.0 if cycle & 1 else extra * 0.5, 0.0 if cycle & 2 else extra * 0.5)
	return Vector2.ZERO

## The painted lines of a road `w` metres wide. Each is {x: offset from the
## centre line (left of travel positive), half: half width, solid, centre}.
static func lane_lines(w: float, lanes: int, oneway: bool, rank: int, urban: bool, line_w: float,
		parking: Vector2 = Vector2.ZERO, cycle: int = 0) -> Array:
	var out: Array = []
	if rank < 1 or w < MIN_LINED_M:
		return out
	var n := lanes if lanes > 0 else (2 if w >= 5.5 else 1)
	var cycle_l := CYCLE_LANE_M if cycle & 1 else 0.0
	var cycle_r := CYCLE_LANE_M if cycle & 2 else 0.0
	var left := w * 0.5 - parking.x - cycle_l
	var right := -w * 0.5 + parking.y + cycle_r
	if left - right < float(n) * MIN_LANE_M:
		left = w * 0.5
		right = -w * 0.5
		parking = Vector2.ZERO
		cycle_l = 0.0
		cycle_r = 0.0
	var half := line_w * 0.5
	var mid := (left + right) * 0.5
	if not oneway and rank >= 2 and w >= 9.0:
		out.append({"x": mid + 0.14, "half": half, "solid": true, "centre": true})
		out.append({"x": mid - 0.14, "half": half, "solid": true, "centre": true})
	elif not oneway and n >= 2:
		out.append({"x": mid, "half": half, "solid": false, "centre": true})
	var lane := (left - right) / float(n)
	for k in range(1, mini(n, 8)):
		var x := left - lane * float(k)
		if oneway or absf(x - mid) > 0.5:
			out.append({"x": x, "half": half, "solid": false, "centre": false})
	var inset := 0.65 if urban else 0.35
	for side: Array in [[left, parking.x + cycle_l, 1.0], [right, parking.y + cycle_r, -1.0]]:
		var kept := float(side[1]) > 0.0
		if kept:
			out.append({"x": float(side[0]), "half": half + EDGE_EXTRA_M, "solid": true, "centre": false})
		elif rank >= 2:
			out.append({"x": float(side[0]) - float(side[2]) * inset, "half": half + EDGE_EXTRA_M, "solid": true, "centre": false})
	return out

## Roads that take line paint: asphalt carriageways on the ground.
static func _paintable(line: Variant, surf: RoadBuilder._Surface, m2u: float) -> bool:
	if not RoadSurface.is_carriageway(line):
		return false
	var r := RoadBuilder._parse(line, m2u)
	return not r.is_empty() and not bool(r["bridge"]) and RoadBuilder.finish_of(line, surf, m2u) == "asphalt" \
		and RoadSurface._points(line).size() >= 2

static func _layout_key(line: Variant) -> String:
	if not (line is Dictionary):
		return "plain"
	var r: Dictionary = line
	return "%s|%d|%d|%.1f|%d|%.1f|%d" % [str(r.get("class", "")), int(r.get("lanes", 0)), int(r.get("oneway", 0)),
		float(r.get("width_m", 0.0)), int(r.get("parking", -1)), float(r.get("parking_m", 0.0)), int(r.get("cycle_lane", 0))]

## Ways of `ids` joined head to tail where they run on in line with one
## layout: [[road index, ...], ...]. Dashes then run through the splits.
static func line_chains(data: LocationData, ids: PackedInt32Array) -> Array:
	var starts := {}
	for i in ids:
		var k := RoadSurface.node_key(RoadSurface._points(data.roads[i])[0])
		var at: PackedInt32Array = starts.get(k, PackedInt32Array())
		at.append(i)
		starts[k] = at
	var next := {}
	var taken := {}
	for i in ids:
		var pts := RoadSurface._points(data.roads[i])
		var end := RoadSurface.node_key(pts[pts.size() - 1])
		for j in starts.get(end, PackedInt32Array()) as PackedInt32Array:
			if j != i and not taken.has(j) and _layout_key(data.roads[i]) == _layout_key(data.roads[j]) \
					and RoadMarkings._in_line(pts, RoadSurface._points(data.roads[j]), end):
				next[i] = j
				taken[j] = true
				break
	var out: Array = []
	var seen := {}
	for pass_rings: bool in [false, true]:
		for i in ids:
			if seen.has(i) or (taken.has(i) and not pass_rings):
				continue
			var chain: Array = []
			var at := i
			while at >= 0 and not seen.has(at):
				seen[at] = true
				chain.append(at)
				at = int(next.get(at, -1))
			out.append(chain)
	return out

## Adds every street's lines to `batches` as the "paint" finish.
static func lay(batches: Dictionary, data: LocationData, surf: RoadBuilder._Surface, junc: Dictionary,
		seeds: PackedFloat32Array, m2u: float) -> void:
	var ids := PackedInt32Array()
	for i in data.roads.size():
		if _paintable(data.roads[i], surf, m2u):
			ids.append(i)
	var yellow := RoadSurface.yellow_centre(data)
	var lift := RoadBuilder.lift_for_layer(LAYER) * m2u
	for chain: Array in line_chains(data, ids):
		var line: Variant = data.roads[int(chain[0])]
		var r := RoadBuilder._parse(line, m2u)
		var pts := PackedVector2Array()
		for road: int in chain:
			var part := RoadSurface._points(data.roads[road])
			pts.append_array(part.slice(0 if pts.is_empty() else 1))
		var mid := pts[pts.size() / 2]
		var urban := int(r["rank"]) >= 1 and surf.ground.land_class_at(mid.x, mid.y) == "urban"
		var kind := kind_of(str(r["class"]), urban)
		var style := style_for(data.country, kind)
		var road_dict: Dictionary = line if line is Dictionary else {}
		var lines := lane_lines(float(r["width_u"]) / m2u, int(r["lanes"]), int(r.get("oneway", 0)) != 0, int(r["rank"]), urban,
			float(style[2]), parking_strips(road_dict), int(road_dict.get("cycle_lane", 0)))
		if lines.is_empty():
			continue
		var dense := RoadBuilder._resample(pts, surf.step * 0.34)
		for run: PackedVector2Array in RoadBuilder._dry_runs(dense, surf):
			var straight := RoadBuilder._straighten(run, surf.step)
			for l: Dictionary in lines:
				var code := SOLID if bool(l["solid"]) else int(PATTERN[kind])
				if bool(l["centre"]) and yellow:
					code |= YELLOW_BIT
				var attr := Color(float(l["half"]) / HALF_MAX_M, float(code) / 15.0, seeds[int(chain[0])], 1.0)
				_strip(batches, straight, float(l["x"]) * m2u, attr, surf, lift, junc)

## One line's carrier, `offset` to the left of the polyline's travel.
static func _strip(batches: Dictionary, pts: PackedVector2Array, offset: float, attr: Color,
		surf: RoadBuilder._Surface, lift: float, junc: Dictionary) -> void:
	var strip := PackedVector2Array()
	strip.resize(pts.size())
	for k in pts.size():
		# RoadBuilder._side points to the right of travel.
		strip[k] = pts[k] - RoadBuilder._side(pts, k) * offset
	RoadBuilder._ribbon(RoadBuilder._batch(batches, "paint"), strip, CARRIER_M * WorldScale.metres_to_units(),
		surf, lift, attr, junc, LAYER)
