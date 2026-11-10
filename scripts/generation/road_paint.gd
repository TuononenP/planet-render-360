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
## dash pattern survives OSM's splits, and each street's lines are cut at
## its junctions, crossings and stop lines (RoadPaintCut). Paint wears: aggregate shows through
## it, wheels scuff crossings and stop lines, older streets have less left.
##
## Vertex data on a line strip: UV = (across, along) in 4 m units, UV2.x
## the strip width in metres, UV2.y its depth layer, COLOR = (half width /
## HALF_MAX_M, line_code / 15, wear seed, 1). Crossings use the ribbon's
## own coordinates.

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
## Streets that carry no lines unless their lanes are tagged.
const UNLINED := ["residential", "unclassified", "living_street", "road"]
## An untagged one-way main road this wide has more than one lane, each this wide.
const ONEWAY_LANES_M := 6.5
const ONEWAY_LANE_M := 3.3
## Paint keeps this clear of a rail set in the street; a track counts as
## running along a street when it is this parallel, this near a probe.
const RAIL_CLEAR_M := 0.45
const RAIL_PARALLEL_COS := 0.94
const RAIL_ALONG_M := 3.0
## A building this near a street puts it in town.
const BUILT_UP_M := 30.0
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
		_mat.render_priority = -3
		_apply(_mat)
	return _mat

## The paint of a crossing or stop line (RoadSurface.CROSSING_KINDS).
static func crossing_material(kind: float) -> ShaderMaterial:
	var m := material().duplicate() as ShaderMaterial
	# Lines, then crossings, then stop lines and glyphs: the order never
	# depends on how the meshes happen to sort.
	m.render_priority = -1 if kind >= float(RoadSurface.CROSSING_KINDS["solid"]) else -2
	m.set_shader_parameter("crossing_kind", kind)
	return m

static func _apply(m: ShaderMaterial) -> void:
	# A Color does not convert to a vec3 uniform: the line stayed white.
	m.set_shader_parameter("centre_col", Vector3(_centre.r, _centre.g, _centre.b))
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
## `opts` (RoadPaint.layout_opts) carries what the tags say beyond that:
## class, unmarked, inferred_parking, forward and backward lane counts,
## double_centre (the place paints a solid double line between opposing
## traffic in town), left_traffic, and rails ([offset, half width] of
## track set in the street).
static func lane_lines(w: float, lanes: int, oneway: bool, rank: int, urban: bool, line_w: float,
		parking: Vector2 = Vector2.ZERO, cycle: int = 0, opts: Dictionary = {}) -> Array:
	var out: Array = []
	if rank < 1 or w < MIN_LINED_M or bool(opts.get("unmarked", false)):
		return out
	# A side street nobody counted lanes on has none painted.
	if lanes <= 0 and str(opts.get("class", "")) in UNLINED:
		return out
	var cycle_l := CYCLE_LANE_M if cycle & 1 else 0.0
	var cycle_r := CYCLE_LANE_M if cycle & 2 else 0.0
	var left := w * 0.5 - parking.x - cycle_l
	var right := -w * 0.5 + parking.y + cycle_r
	var n := _lane_count(left - right, lanes, oneway, rank)
	if left - right < float(n) * MIN_LANE_M:
		left = w * 0.5
		right = -w * 0.5
		parking = Vector2.ZERO
		cycle_l = 0.0
		cycle_r = 0.0
		n = _lane_count(w, lanes, oneway, rank)
	var half := line_w * 0.5
	var lane := (left - right) / float(n)
	# Opposing traffic meets where the forward lanes end: off the middle
	# of a road with an odd lane count.
	var fwd := int(opts.get("forward", 0))
	if fwd <= 0 or fwd >= n or fwd + int(opts.get("backward", 0)) != n:
		fwd = (n + 1) / 2
	var mid := left - lane * float(fwd) if bool(opts.get("left_traffic", false)) else right + lane * float(fwd)
	if not oneway and n >= 2:
		if (rank >= 2 and w >= 9.0) or (urban and bool(opts.get("double_centre", false))):
			out.append({"x": mid + 0.14, "half": half, "solid": true, "centre": true})
			out.append({"x": mid - 0.14, "half": half, "solid": true, "centre": true})
		else:
			out.append({"x": mid, "half": half, "solid": false, "centre": true})
	for k in range(1, mini(n, 8)):
		var x := left - lane * float(k)
		if oneway or absf(x - mid) > 0.5:
			out.append({"x": x, "half": half, "solid": false, "centre": false})
	var inset := 0.65 if urban else 0.35
	var marked_parking := rank >= 2 and not bool(opts.get("inferred_parking", false))
	# A kerb is a town street's edge; only open roads and motorways paint one.
	var edged := rank >= 2 and (not urban or kind_of(str(opts.get("class", "")), urban) == "motorway")
	for side: Array in [[left, parking.x, cycle_l, 1.0], [right, parking.y, cycle_r, -1.0]]:
		if float(side[2]) > 0.0 or (float(side[1]) > 0.0 and marked_parking):
			out.append({"x": float(side[0]), "half": half + EDGE_EXTRA_M, "solid": true, "centre": false})
		elif float(side[1]) <= 0.0 and edged:
			out.append({"x": float(side[0]) - float(side[3]) * inset, "half": half + EDGE_EXTRA_M, "solid": true, "centre": false})
	var rails: Array = opts.get("rails", [])
	if rails.is_empty():
		return out
	return out.filter(func(l: Dictionary) -> bool:
		for rail: Array in rails:
			if absf(float(l["x"]) - float(rail[0])) < float(rail[1]):
				return false
		return true)

## Traffic lanes across `travel` metres: the tagged count, else two on a
## two-way road with the room, and one on a one-way street unless it is
## a main road wide enough for more.
static func _lane_count(travel: float, lanes: int, oneway: bool, rank: int) -> int:
	if lanes > 0:
		return lanes
	if not oneway:
		return 2 if travel >= 5.5 else 1
	if rank >= 2 and travel >= ONEWAY_LANES_M:
		return clampi(int(travel / ONEWAY_LANE_M), 2, 4)
	return 1

## lane_lines' `opts` for `road` as travelled (`flip`: against its points).
static func layout_opts(road: Dictionary, flip: bool, data: LocationData) -> Dictionary:
	var fwd := int(road.get("lanes_forward", 0))
	var bwd := int(road.get("lanes_backward", 0))
	return {"class": str(road.get("class", "")), "unmarked": bool(road.get("unmarked", false)),
		"inferred_parking": int(road.get("parking", -1)) < 0,
		"forward": bwd if flip else fwd, "backward": fwd if flip else bwd,
		"double_centre": RoadSurface.double_centre(data), "left_traffic": RoadSurface.left_traffic(data)}

## True for a street that says it runs through a built-up place, whatever
## the land-use map knows: it has sidewalks, or room measured between them.
static func in_town(road: Dictionary) -> bool:
	return int(road.get("sidewalk", 0)) != 0 or int(road.get("sidewalk_separate", 0)) != 0 \
		or float(road.get("parking_m", 0.0)) > 0.0

## True when a building stands within BUILT_UP_M of the quarter points
## of `pts`: a street between houses is in town whether or not anyone
## mapped the land use or its sidewalks. `grid` is RoadMarkings'
## building grid.
static func built_up(pts: PackedVector2Array, grid: Dictionary, m2u: float) -> bool:
	if grid.is_empty() or pts.size() < 2:
		return false
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var reach := BUILT_UP_M * m2u
	for frac: float in [0.25, 0.5, 0.75]:
		var p: Vector2 = RoadMarkings._point_at(pts, total * frac)[0]
		for ring: PackedVector2Array in RoadMarkings._grid_near(grid, p, reach, m2u):
			for k in ring.size():
				if Geometry2D.get_closest_point_to_segment(p, ring[k], ring[(k + 1) % ring.size()]).distance_to(p) <= reach:
					return true
	return false

## Roads that take line paint: asphalt carriageways on the ground.
static func _paintable(line: Variant, surf: RoadBuilder._Surface, m2u: float) -> bool:
	if not RoadSurface.is_carriageway(line):
		return false
	var r := RoadBuilder._parse(line, m2u)
	return not r.is_empty() and not bool(r["bridge"]) and RoadBuilder.finish_of(line, surf, m2u) == "asphalt" \
		and RoadSurface._points(line).size() >= 2

## The lane layout a way shows when travelled (`flip`: against its
## points). Width and kerbside room are left out: they are measured per
## way and change at every split of one street.
static func _layout_key(line: Variant, flip: bool = false) -> String:
	if not (line is Dictionary):
		return "plain"
	var r: Dictionary = line
	var cycle := int(r.get("cycle_lane", 0))
	var fwd := int(r.get("lanes_forward", 0))
	var bwd := int(r.get("lanes_backward", 0))
	var oneway := int(r.get("oneway", 0))
	if flip:
		cycle = ((cycle & 1) << 1) | ((cycle & 2) >> 1)
		oneway = -oneway
		var swap := fwd
		fwd = bwd
		bwd = swap
	return "%s|%d|%d|%d|%d|%d|%d" % [str(r.get("class", "")), int(r.get("lanes", 0)), oneway, cycle, fwd, bwd,
		int(bool(r.get("unmarked", false)))]

## Ways of `ids` joined end to end where they run on in line with one
## layout: [[road index, ...], ...] in travel order, a way travelled
## against its points as ~index (negative). Dashes then run through the
## splits, whichever way each piece was drawn.
static func line_chains(data: LocationData, ids: PackedInt32Array) -> Array:
	# Way ends at each node: [road, 1 for the way's end, 0 for its start].
	var ends := {}
	for i in ids:
		var pts := RoadSurface._points(data.roads[i])
		for e in 2:
			var k := RoadSurface.node_key(pts[pts.size() - 1] if e == 1 else pts[0])
			if not ends.has(k):
				ends[k] = []
			(ends[k] as Array).append([i, e])
	# link[road * 2 + end] = [road, end] of the way that runs on from there.
	var link := {}
	for k: Vector2i in ends:
		var here: Array = ends[k]
		for a in here.size():
			var ia: int = here[a][0]
			var ea: int = here[a][1]
			if link.has(ia * 2 + ea):
				continue
			for b in range(a + 1, here.size()):
				var ib: int = here[b][0]
				var eb: int = here[b][1]
				# Travelling a into the node and b out of it.
				if ib == ia or link.has(ib * 2 + eb) \
						or _layout_key(data.roads[ia], ea == 0) != _layout_key(data.roads[ib], eb == 1) \
						or not RoadMarkings._in_line(RoadSurface._points(data.roads[ia]), RoadSurface._points(data.roads[ib]), k):
					continue
				link[ia * 2 + ea] = [ib, eb]
				link[ib * 2 + eb] = [ia, ea]
				break
	var out: Array = []
	var seen := {}
	for pass_rings: bool in [false, true]:
		for i in ids:
			if seen.has(i):
				continue
			# A chain starts at an end nothing runs into; a ring anywhere.
			var from := 0 if not link.has(i * 2) else (1 if not link.has(i * 2 + 1) else -1)
			if from < 0 and not pass_rings:
				continue
			var chain: Array = []
			var at := i
			var entry := maxi(from, 0)
			while at >= 0 and not seen.has(at):
				seen[at] = true
				chain.append(at if entry == 0 else ~at)
				var next: Array = link.get(at * 2 + (1 - entry), [])
				at = int(next[0]) if not next.is_empty() else -1
				entry = int(next[1]) if not next.is_empty() else 0
			out.append(chain)
	return out

## Length-weighted median of column `col` of `rows` ([length, ...]).
static func _median(rows: Array, col: int) -> float:
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return float(a[col]) < float(b[col]))
	var total := 0.0
	for row: Array in sorted:
		total += float(row[0])
	var run := 0.0
	for row: Array in sorted:
		run += float(row[0])
		if run >= total * 0.5:
			return float(row[col])
	return float(sorted[sorted.size() - 1][col]) if not sorted.is_empty() else 0.0

## Track set in the street, bucketed: [a, b, way index, half bed width].
static func _rail_grid(data: LocationData, m2u: float) -> Dictionary:
	var grid := {}
	for i in data.railways.size():
		var raw: Variant = data.railways[i]
		if not (raw is Dictionary) or not bool((raw as Dictionary).get("embedded", false)) \
				or bool((raw as Dictionary).get("tunnel", false)) or bool((raw as Dictionary).get("bridge", false)):
			continue
		var way: Dictionary = raw
		var pts: PackedVector2Array = way.get("points", PackedVector2Array())
		var half := float(way.get("gauge_m", 1.435)) * 0.5 + RAIL_CLEAR_M
		for j in pts.size() - 1:
			RoadMarkings._grid_add(grid, pts[j], pts[j + 1], [pts[j], pts[j + 1], i, half], m2u)
	return grid

## [offset left of travel, half width] (m) of each track running along
## `pts` within `reach` metres of it: seen at two of its three probes.
static func rails_along(pts: PackedVector2Array, grid: Dictionary, reach: float, m2u: float) -> Array:
	var out: Array = []
	if grid.is_empty() or pts.size() < 2:
		return out
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var seen := {}
	for frac: float in [0.25, 0.5, 0.75]:
		var pose: Array = RoadMarkings._point_at(pts, total * frac)
		var p: Vector2 = pose[0]
		var d: Vector2 = pose[1]
		var left := Vector2(d.y, -d.x)
		var here := {}
		for seg: Array in RoadMarkings._grid_near(grid, p, reach * m2u, m2u):
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			var q := Geometry2D.get_closest_point_to_segment(p, a, b)
			if a.distance_to(b) < 0.00001 or absf((b - a).normalized().dot(d)) < RAIL_PARALLEL_COS \
					or absf((q - p).dot(d)) > RAIL_ALONG_M * m2u or absf((q - p).dot(left)) > reach * m2u:
				continue
			here[int(seg[2])] = [(q - p).dot(left) / m2u, float(seg[3])]
		for way: int in here:
			if not seen.has(way):
				seen[way] = []
			(seen[way] as Array).append(here[way])
	for way: int in seen:
		var hits: Array = seen[way]
		if hits.size() >= 2:
			hits.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
			out.append(hits[hits.size() / 2])
	return out

## Adds every street's lines to `batches` as the "paint" finish, cut
## where `plan`'s junctions, crossings and stop lines lie.
static func lay(batches: Dictionary, data: LocationData, surf: RoadBuilder._Surface, plan: RoadMarkings.Plan,
		seeds: PackedFloat32Array, m2u: float) -> void:
	var ids := PackedInt32Array()
	for i in data.roads.size():
		if _paintable(data.roads[i], surf, m2u):
			ids.append(i)
	var yellow := RoadSurface.yellow_centre(data)
	var lift := RoadBuilder.lift_for_layer(LAYER) * m2u
	var cuts := RoadPaintCut.zones(plan, m2u)
	var rails := _rail_grid(data, m2u)
	var buildings := RoadMarkings._building_grid(data, m2u)
	for chain: Array in line_chains(data, ids):
		var lead_flip := int(chain[0]) < 0
		var lead := ~int(chain[0]) if lead_flip else int(chain[0])
		var line: Variant = data.roads[lead]
		var r := RoadBuilder._parse(line, m2u)
		var pts := PackedVector2Array()
		# Per way: [length, width m, kerbside room left, right of travel].
		var rows: Array = []
		for entry: int in chain:
			var flip := entry < 0
			var road := ~entry if flip else entry
			var part := RoadSurface._points(data.roads[road]).duplicate()
			if flip:
				part.reverse()
			var length := 0.0
			for k in part.size() - 1:
				length += part[k].distance_to(part[k + 1])
			var way: Variant = data.roads[road]
			var strips := parking_strips(way) if way is Dictionary else Vector2.ZERO
			rows.append([length, float(RoadBuilder._parse(way, m2u)["width_u"]) / m2u,
				strips.y if flip else strips.x, strips.x if flip else strips.y])
			pts.append_array(part.slice(0 if pts.is_empty() else 1))
		var mid := pts[pts.size() / 2]
		var road_dict: Dictionary = line if line is Dictionary else {}
		var urban := int(r["rank"]) >= 1 and (surf.ground.land_class_at(mid.x, mid.y) == "urban" or in_town(road_dict)
			or built_up(pts, buildings, m2u))
		var kind := kind_of(str(r["class"]), urban)
		var style := style_for(data.country, kind)
		var w := _median(rows, 1)
		var opts := layout_opts(road_dict, lead_flip, data)
		opts["rails"] = rails_along(pts, rails, w * 0.5, m2u)
		var cycle := int(road_dict.get("cycle_lane", 0))
		if lead_flip:
			cycle = ((cycle & 1) << 1) | ((cycle & 2) >> 1)
		var lines := lane_lines(w, int(r["lanes"]), int(r.get("oneway", 0)) != 0, int(r["rank"]), urban,
			float(style[2]), Vector2(_median(rows, 2), _median(rows, 3)), cycle, opts)
		if lines.is_empty():
			continue
		var dense := RoadBuilder._resample(pts, surf.step * 0.34)
		for run: PackedVector2Array in RoadBuilder._dry_runs(dense, surf):
			for piece: PackedVector2Array in RoadPaintCut.keep(run, cuts, m2u):
				var straight := RoadBuilder._straighten(piece, surf.step)
				for l: Dictionary in lines:
					var code := SOLID if bool(l["solid"]) else int(PATTERN[kind])
					if bool(l["centre"]) and yellow:
						code |= YELLOW_BIT
					var attr := Color(float(l["half"]) / HALF_MAX_M, float(code) / 15.0, seeds[lead], 1.0)
					_strip(batches, straight, float(l["x"]) * m2u, attr, surf, lift)

## One line's carrier, `offset` to the left of the polyline's travel.
static func _strip(batches: Dictionary, pts: PackedVector2Array, offset: float, attr: Color,
		surf: RoadBuilder._Surface, lift: float) -> void:
	var strip := PackedVector2Array()
	strip.resize(pts.size())
	for k in pts.size():
		# RoadBuilder._side points to the right of travel.
		strip[k] = pts[k] - RoadBuilder._side(pts, k) * offset
	RoadBuilder._ribbon(RoadBuilder._batch(batches, "paint"), strip, CARRIER_M * WorldScale.metres_to_units(),
		surf, lift, attr, {}, LAYER)
