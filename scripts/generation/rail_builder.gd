class_name RailBuilder
extends RefCounted

## OSM railway track (rail, tram, light rail, metro above ground) on the
## drawn terrain, beside RoadBuilder's ribbons. Track on its own bed is
## a ballast ribbon (sleepers painted by BALLAST_CODE from the ribbon UV,
## no per-sleeper geometry) under two steel rails at the way's gauge;
## street tram track is only its two rails, flush in the carriageway and
## depth-biased over it (a cable car's sits in a concrete bed and adds
## the slot rails between them). Bridges get RoadBuilder's deck with a ballast
## top; tunnels and covered track are skipped.

const BED_LIFT_M := 0.025
## Depth layer of the bed (RoadSurface.DEPTH_GLSL): under every road
## ribbon, so a level crossing reads as road.
const BED_LAYER := 0.8
const RAIL_HEAD_M := 0.07
const RAIL_HEIGHT_M := 0.16
## Street rails: a hair above the carriageway, drawn over it.
const STREET_RAIL_LIFT_M := 0.05
const RAIL_LAYER := 7.5
## Sleeper pitch and the part of the bed past each sleeper end (metres).
const SLEEPER_PITCH_M := 0.6
const SLEEPER_INSET_M := 0.35
const BALLAST_HEX := "#6f6a63"
const SLEEPER_HEX := "#8c8984"
const STEEL_HEX := "#77736f"
## Gap between the slot rails over a cable car's cable (m), and the
## concrete bed the cable-car track is set in: its width past the rails
## (m) and depth layer: over every carriageway (rank 2 asphalt tops out
## near 6.8), under the road paint (RoadPaint.LAYER) and the rails. Its
## lift follows its layer, as a road ribbon's does: lower than the
## asphalt it is set in, it showed through only in patches.
const CABLE_SLOT_M := 0.03
const CABLE_BED_M := 1.2
const CABLE_BED_LAYER := 6.85
## Worn concrete, a shade lighter than the asphalt beside it; the rails
## stand this far over the bed so its drape never swallows them.
const CABLE_BED_HEX := "#7f7b74"
const CABLE_RAIL_CLEAR_M := 0.02
const TRACK_BED_HEX := "#a39d92"
## Bridge tracks this close side by side (centre to centre) share one
## deck edge: no parapet stands between them.
const BESIDE_M := 32.0
const BESIDE_MIN_M := 0.3
## A viaduct's fascias: soot-darkened London stock brick.
const VIADUCT_BRICK_HEX := "#4a3b33"
const BESIDE_CELL_M := 32.0

## Ballast bed: speckled stone, concrete sleepers across it (UV.y along
## in 4 m units, UV2.x the bed width in metres), anti-aliased into their
## average where a pitch is under a pixel; rain darkens, snow settles.
const BALLAST_CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 ballast_col : source_color;
uniform vec3 sleeper_col : source_color;
uniform float pitch = 0.6;
uniform float inset = 0.35;
// @SNOW
varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = VERTEX;
// @DEPTH
}

void fragment() {
	float w = max(UV2.x, 1.0);
	float across = UV.x * 4.0;
	float along = UV.y * 4.0;
	float grain = mix(0.72, 1.18, hash(floor(vec2(across, along) * 16.0)));
	vec3 col = ballast_col * grain;
	float t = along / pitch;
	float aa = fwidth(t);
	float f = abs(fract(t) - 0.5);
	float band = smoothstep(0.32 - aa, 0.32 + aa, f);
	band = mix(band, 0.36, clamp(aa * 2.0 - 0.5, 0.0, 1.0));
	float ends = step(inset, across) * step(across, w - inset);
	float sl = band * ends;
	col = mix(col, sleeper_col * mix(0.9, 1.08, hash(vec2(floor(t), 7.0))), sl);
	float wet = climate_wetness;
	col *= mix(1.0, 0.7, wet);
	float sc = snow_cover(wpos, 1.0);
	ALBEDO = mix(col, snow_col, sc * 0.85);
	ROUGHNESS = mix(mix(0.95, 0.4, wet), 0.7, sc);
}
"""

const RAIL_CODE := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 steel : source_color;
// @SNOW
varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = VERTEX;
	wnrm = NORMAL;
// @DEPTH
}

void fragment() {
	// In winter the head stays bare but dulled by grit and brine, never
	// a mirror of the sky; snow packs against the sides.
	float winter = snow_line(wpos);
	float up = clamp(wnrm.y, 0.0, 1.0);
	float side = snow_cover(wpos, 1.0) * (1.0 - smoothstep(0.8, 0.95, up));
	vec3 head = mix(steel, steel * vec3(0.55, 0.52, 0.5), winter);
	ALBEDO = mix(head, snow_albedo(wpos.xz, max(fwidth(wpos.x), fwidth(wpos.z)), 0.4), side);
	METALLIC = mix(0.8, 0.45, winter) * (1.0 - side);
	ROUGHNESS = mix(mix(0.5, 0.25, up), 0.55, max(winter, side));
}
"""

static var _mats: Dictionary = {}

## Railways subtree under `root` (RoadBuilder.build_roads' Roads node).
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		abort: BuildAbort = null) -> void:
	if data.railways.is_empty():
		return
	var m2u := WorldScale.metres_to_units()
	var surf := RoadBuilder._Surface.new(data, ground)
	surf.use_native()
	var road_index := RoadIndex.new(data, m2u)
	var spans := LandmarkSites.bridge_spans(data)
	var batches := {}
	var beside := deck_index(data.railways, m2u)
	if not beside.is_empty():
		beside["decks"] = RailDecks.of(data, surf, m2u)
	for w in data.railways:
		if abort != null and abort.requested:
			return
		_way(batches, w, surf, spans, m2u, data, road_index, beside)
	for key in batches:
		var b: RoadBuilder._Batch = batches[key]
		if b.indices.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Rail_" + str(key)
		mi.mesh = b.mesh()
		mi.material_override = _material(str(key))
		if not str(key) in ["deck", "deck_brick"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)

static func _way(batches: Dictionary, w: Variant, surf: RoadBuilder._Surface,
		spans: Array, m2u: float, data: LocationData = null, road_index = null, beside: Dictionary = {}) -> void:
	if not (w is Dictionary) or bool((w as Dictionary).get("tunnel", false)):
		return
	var way: Dictionary = w
	var pts: PackedVector2Array = way.get("points", PackedVector2Array())
	if pts.size() < 2:
		return
	var gauge := float(way.get("gauge_m", 1.435)) * m2u
	var bed := float(way.get("width_m", 3.3)) * m2u
	var dense := RoadBuilder._resample(pts, surf.step * 0.34)
	if bool(way.get("bridge", false)):
		if data != null and str(way.get("class", "")) == "tram" and _on_road(pts[pts.size() / 2], data, m2u, road_index):
			# The carriageway bridge owns the slab; the tram adds rails only.
			var deck := RoadBuilder.deck_profile(dense, surf, m2u, bed * 0.5)
			if deck.size() == dense.size():
				for i in deck.size():
					deck[i] += STREET_RAIL_LIFT_M * m2u
				_rails(RoadBuilder._batch(batches, "rail"), dense, deck, gauge, 0.0, m2u, RAIL_LAYER)
			return
		for piece in LandmarkSites.outside_spans(dense, spans):
			_bridge(batches, BridgeLandings.landed(piece, dense, surf, m2u), gauge, bed, surf, m2u, beside)
		return
	var embedded := bool(way.get("embedded", false))
	for run in RoadBuilder._dry_runs(dense, surf):
		var ys := PackedFloat32Array()
		var lift := (STREET_RAIL_LIFT_M if embedded else BED_LIFT_M + RAIL_HEIGHT_M) * m2u
		if embedded and bool(way.get("cable", false)):
			lift = (RoadBuilder.lift_for_layer(CABLE_BED_LAYER) + CABLE_RAIL_CLEAR_M) * m2u
		for p in run:
			ys.append(surf.height(p.x, p.y) + lift)
		if embedded:
			# Mapped trams default to embedded, including reservations outside
			# the road. Give those pieces paving or grass under the rails.
			if data != null:
				for j in run.size() - 1:
					var mid: Vector2 = (run[j] + run[j + 1]) * 0.5
					if not _on_road(mid, data, m2u, road_index):
						var bed_key := "grass_track" if surf.ground.land_class_at(mid.x, mid.y) == "grass" else "track_bed"
						RoadBuilder._ribbon(RoadBuilder._batch(batches, bed_key),
							PackedVector2Array([run[j], run[j + 1]]), gauge + 1.2 * m2u, surf,
							BED_LIFT_M * m2u, Color(0, 0, 0, 1), {}, BED_LAYER)
			_rails(RoadBuilder._batch(batches, "rail"), run, ys, gauge, 0.0, m2u, RAIL_LAYER)
			if bool(way.get("cable", false)):
				# A concrete track bed in the asphalt, and the cable slot:
				# two steel slot rails either side of a gap.
				RoadBuilder._ribbon(RoadBuilder._batch(batches, "cable_bed"),
					RoadBuilder._straighten(run, surf.step), gauge + CABLE_BED_M * m2u, surf,
					RoadBuilder.lift_for_layer(CABLE_BED_LAYER) * m2u, Color(0, 0, 0, 1), {}, CABLE_BED_LAYER)
				_rails(RoadBuilder._batch(batches, "rail"), run, ys, CABLE_SLOT_M * m2u, 0.0, m2u, RAIL_LAYER)
		else:
			RoadBuilder._ribbon(RoadBuilder._batch(batches, "ballast"),
				RoadBuilder._straighten(run, surf.step), bed, surf, BED_LIFT_M * m2u,
				Color(0, 0, 0, 1), {}, BED_LAYER)
			_rails(RoadBuilder._batch(batches, "rail"), run, ys, gauge,
				RAIL_HEIGHT_M * m2u, m2u, BED_LAYER + 0.1)

## Points along every bridge track, by BESIDE_CELL_M cell: a station's
## viaduct is mapped a bridge way per track, and each drawn with its own
## parapets stood a wall between every pair of tracks.
static func deck_index(railways: Array, m2u: float) -> Dictionary:
	var index := {}
	for w in railways:
		if not (w is Dictionary) or not bool((w as Dictionary).get("bridge", false)) \
				or bool((w as Dictionary).get("tunnel", false)):
			continue
		var pts: PackedVector2Array = (w as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		for p in RoadBuilder._resample(pts, 2.0 * m2u):
			var cell := Vector2i((p / (BESIDE_CELL_M * m2u)).floor())
			if not index.has(cell):
				index[cell] = PackedVector2Array()
			var cell_pts: PackedVector2Array = index[cell]
			cell_pts.append(p)
			index[cell] = cell_pts
	return index

## Whether another bridge track runs within BESIDE_M of `mid` on the
## side `out` points to (unit; `along` the track there).
static func deck_beside(index: Dictionary, mid: Vector2, out: Vector2, m2u: float) -> bool:
	var along := Vector2(out.y, -out.x)
	var cell := Vector2i((mid / (BESIDE_CELL_M * m2u)).floor())
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var cell_pts: PackedVector2Array = index.get(cell + Vector2i(dx, dz), PackedVector2Array())
			for q in cell_pts:
				var v := q - mid
				var side := v.dot(out)
				if side > BESIDE_MIN_M * m2u and side < BESIDE_M * m2u and absf(v.dot(along)) < 3.0 * m2u:
					return true
	return false

## Deck (RoadBuilder's slab, fascias and parapets) with a ballast top,
## and the rails on it. An edge another bridge track runs beside
## (`beside`, deck_index) carries no parapet.
static func _bridge(batches: Dictionary, pts: PackedVector2Array, gauge: float,
		bed: float, surf: RoadBuilder._Surface, m2u: float, beside: Dictionary = {}) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	var top := RoadBuilder._batch(batches, "rail_deck")
	top.pad()
	var k0 := top.verts.size()
	var deck := RoadBuilder.deck_profile(inside, surf, m2u, bed * 0.5, 0, false)
	if deck.size() != inside.size():
		return
	var fit := {"deck": deck, "side": "deck_brick", "metric_v": true}
	if beside.has("decks"):
		# Level with the tracks alongside; the fascia still reaches down to
		# where the deck stood on its own.
		var low := PackedFloat32Array()
		for d in deck:
			low.append(d - RoadBuilder.DECK_DEPTH_M * m2u)
		deck = (beside["decks"] as RailDecks).level(inside, deck)
		fit["deck"] = deck
		fit["low"] = low
	if not beside.is_empty():
		var left := PackedByteArray()
		var right := PackedByteArray()
		for i in inside.size() - 1:
			var mid := (inside[i] + inside[i + 1]) * 0.5
			var out := RoadBuilder._side(inside, i).normalized()
			left.append(1 if deck_beside(beside, mid, out, m2u) else 0)
			right.append(1 if deck_beside(beside, mid, -out, m2u) else 0)
		fit["open"] = [left, right]
	RoadBuilder._bridge(batches, inside, bed, surf, m2u, "rail_deck", "unknown", 0, fit)
	top.pad()
	for i in range(k0, top.verts.size()):
		top.uv2s[i] = Vector2(bed / m2u, BED_LAYER)
	if beside.has("decks"):
		_fill(top, inside, deck, bed, beside["decks"], m2u)
	var ys := PackedFloat32Array()
	for d in deck:
		ys.append(d + RAIL_HEIGHT_M * m2u)
	_rails(RoadBuilder._batch(batches, "rail"), inside, ys, gauge,
		RAIL_HEIGHT_M * m2u, m2u, BED_LAYER + 0.1)

## The slab between a viaduct's track groups: along `pts` (deck heights
## `deck`), where a track `decks.across` stands FILL_MIN_M to LEVEL_M off
## to the left, a ballast strip from this deck's left edge to that
## track's near edge, on the deck level. One track of each pair fills (the
## left one sees its neighbour on its left, the other sees none there),
## so no gap is laid twice. Both ends of a segment must have a neighbour
## and the one level, or the strip is left out (a viaduct's ends).
static func _fill(top: RoadBuilder._Batch, pts: PackedVector2Array, deck: PackedFloat32Array,
		bed: float, decks: RailDecks, m2u: float) -> void:
	var half := bed * 0.5
	var rows: Array = []
	for i in pts.size():
		var dir := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var hit := decks.across(pts[i], dir)
		if hit.is_empty() or absf(float(hit["h"]) - deck[i]) > 0.05 * m2u:
			rows.append([])
			continue
		var out := Vector2(-dir.y, dir.x)
		var near_edge: Vector2 = pts[i] + out * half
		var far_edge: Vector2 = (hit["at"] as Vector2) - out * half
		rows.append([near_edge, far_edge])
	var along := 0.0
	for i in pts.size() - 1:
		var seg := pts[i].distance_to(pts[i + 1])
		var a: Array = rows[i]
		var b: Array = rows[i + 1]
		if not a.is_empty() and not b.is_empty():
			var k := top.verts.size()
			var span_a: float = (a[0] as Vector2).distance_to(a[1])
			var span_b: float = (b[0] as Vector2).distance_to(b[1])
			if span_a > 0.2 * m2u and span_b > 0.2 * m2u:
				var ends := [[a[0], deck[i], 0.0, span_a, along], [a[1], deck[i], span_a, span_a, along],
					[b[0], deck[i + 1], 0.0, span_b, along + seg], [b[1], deck[i + 1], span_b, span_b, along + seg]]
				for e: Array in ends:
					var q: Vector2 = e[0]
					top.verts.append(Vector3(q.x, float(e[1]), q.y))
					top.normals.append(Vector3.UP)
					top.uvs.append(Vector2(float(e[2]) / m2u / 4.0, float(e[4]) / m2u / 4.0))
					top.colors.append(Color(0, 0.5, 0, 1))
					top.uv2s.append(Vector2(float(e[3]) / m2u, BED_LAYER))
				RoadBuilder._quad_up(top, k, k + 1, k + 2, k + 3)
		along += seg

## Two rails `gauge` apart along `line`, head tops at `ys`: a flat head
## strip, plus side walls `height` deep for rails standing on a bed.
static func _rails(b: RoadBuilder._Batch, line: PackedVector2Array, ys: PackedFloat32Array,
		gauge: float, height: float, m2u: float, layer: float) -> void:
	b.pad()
	var k_start := b.verts.size()
	var head := RAIL_HEAD_M * m2u
	for sgn in [-1.0, 1.0]:
		var off: float = (gauge + head) * 0.5 * sgn
		var k0 := b.verts.size()
		var along := 0.0
		for i in line.size():
			if i > 0:
				along += line[i].distance_to(line[i - 1])
			var s := RoadBuilder._side(line, i)
			var c := line[i] + s * off
			var e := s * head * 0.5
			var l := c + e
			var r := c - e
			b.verts.append(Vector3(l.x, ys[i], l.y))
			b.verts.append(Vector3(r.x, ys[i], r.y))
			b.normals.append(Vector3.UP)
			b.normals.append(Vector3.UP)
			b.uvs.append(Vector2(0.0, along / m2u))
			b.uvs.append(Vector2(1.0, along / m2u))
		for i in line.size() - 1:
			var a := k0 + i * 2
			RoadBuilder._quad_up(b, a, a + 1, a + 2, a + 3)
		if height <= 0.0:
			continue
		for i in line.size() - 1:
			var sa := RoadBuilder._side(line, i).normalized()
			var sb := RoadBuilder._side(line, i + 1).normalized()
			for side in [1.0, -1.0]:
				var pa: Vector2 = line[i] + RoadBuilder._side(line, i) * off + sa * head * 0.5 * side
				var pb: Vector2 = line[i + 1] + RoadBuilder._side(line, i + 1) * off \
					+ sb * head * 0.5 * side
				RoadBuilder._wall(b, pa, pb, ys[i] - height, ys[i + 1] - height,
					ys[i], ys[i + 1], sa * side)
	b.pad()
	for i in range(k_start, b.verts.size()):
		b.uv2s[i] = Vector2(0.0, layer)

static func _material(key: String) -> Material:
	if _mats.has(key):
		return _mats[key] as Material
	var m: Material
	match key:
		"ballast", "rail_deck":
			var sh := Shader.new()
			sh.code = BALLAST_CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL) \
				.replace("// @DEPTH", RoadSurface.DEPTH_GLSL)
			var bm := ShaderMaterial.new()
			bm.shader = sh
			bm.set_shader_parameter("ballast_col", Color.html(BALLAST_HEX))
			bm.set_shader_parameter("sleeper_col", Color.html(SLEEPER_HEX))
			bm.set_shader_parameter("pitch", SLEEPER_PITCH_M)
			bm.set_shader_parameter("inset", SLEEPER_INSET_M)
			m = bm
		"grass_track":
			m = RoadSurface.paved_material("grass", Color(0.20, 0.28, 0.12))
		"track_bed":
			# Depth-layered like the road ribbons (a plain PBR deck would
			# z-fight the asphalt it is set in).
			m = RoadSurface.paved_material("pavement", Color.html(TRACK_BED_HEX).srgb_to_linear())
		"cable_bed":
			# Poured concrete: paving slabs read as a footway down the middle of the street.
			m = RoadSurface.paved_material("concrete", Color.html(CABLE_BED_HEX).srgb_to_linear())
		"rail":
			var rsh := Shader.new()
			rsh.code = RAIL_CODE.replace("// @DEPTH", RoadSurface.DEPTH_GLSL).replace("// @SNOW", ClimateModel.SNOW_GLSL)
			var rm := ShaderMaterial.new()
			rm.shader = rsh
			rm.set_shader_parameter("steel", Color.html(STEEL_HEX))
			m = rm
		"deck_brick":
			m = RoadBuilder._pbr("brick", VIADUCT_BRICK_HEX)
		_:
			m = RoadBuilder._material(key)
	_mats[key] = m
	return m

## Exact local road coverage, indexed once per build for the many tram probes.
class RoadIndex:
	var cells := {}
	var cell_size := 64.0

	func _init(data: LocationData, m2u: float) -> void:
		cell_size *= m2u
		for road in data.roads:
			if not (road is Dictionary) or str(road.get("class", "")) not in StreetProps.LIT \
					or bool(road.get("area", false)) or bool(road.get("tunnel", false)):
				continue
			var pts: PackedVector2Array = road.get("points", PackedVector2Array())
			var half := float(road.get("width_m", 6.0)) * 0.5 * m2u
			for i in pts.size() - 1:
				var a := pts[i]
				var b := pts[i + 1]
				var lo := (a.min(b) - Vector2.ONE * half) / cell_size
				var hi := (a.max(b) + Vector2.ONE * half) / cell_size
				for x in range(floori(lo.x), floori(hi.x) + 1):
					for z in range(floori(lo.y), floori(hi.y) + 1):
						var key := Vector2i(x, z)
						if not cells.has(key):
							cells[key] = []
						(cells[key] as Array).append([a, b, half])

	func contains(p: Vector2) -> bool:
		var key := Vector2i(floori(p.x / cell_size), floori(p.y / cell_size))
		for segment in cells.get(key, []):
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, segment[0], segment[1])) <= float(segment[2]):
				return true
		return false

static func _on_road(p: Vector2, data: LocationData, m2u: float, index = null) -> bool:
	if index != null:
		return index.contains(p)
	for road in data.roads:
		if not (road is Dictionary) or str(road.get("class", "")) not in StreetProps.LIT \
				or bool(road.get("area", false)) or bool(road.get("tunnel", false)):
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		var half := float(road.get("width_m", 6.0)) * 0.5 * m2u
		for i in pts.size() - 1:
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])) <= half:
				return true
	return false
