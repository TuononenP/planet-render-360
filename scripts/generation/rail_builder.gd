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
## (m) and depth layer (over every carriageway, under the rails).
const CABLE_SLOT_M := 0.03
const CABLE_BED_M := 1.2
const CABLE_BED_LAYER := 7.0
const TRACK_BED_HEX := "#a39d92"

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

void vertex() {
// @DEPTH
}

void fragment() {
	ALBEDO = steel;
	METALLIC = 0.8;
	ROUGHNESS = mix(0.5, 0.25, clamp(NORMAL.y, 0.0, 1.0));
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
	var spans := LandmarkSites.bridge_spans(data)
	var batches := {}
	for w in data.railways:
		if abort != null and abort.requested:
			return
		_way(batches, w, surf, spans, m2u)
	for key in batches:
		var b: RoadBuilder._Batch = batches[key]
		if b.indices.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Rail_" + str(key)
		mi.mesh = b.mesh()
		mi.material_override = _material(str(key))
		if str(key) != "deck":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)

static func _way(batches: Dictionary, w: Variant, surf: RoadBuilder._Surface,
		spans: Array, m2u: float) -> void:
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
		for piece in LandmarkSites.outside_spans(dense, spans):
			_bridge(batches, piece, gauge, bed, surf, m2u)
		return
	var embedded := bool(way.get("embedded", false))
	for run in RoadBuilder._dry_runs(dense, surf):
		var ys := PackedFloat32Array()
		var lift := (STREET_RAIL_LIFT_M if embedded else BED_LIFT_M + RAIL_HEIGHT_M) * m2u
		for p in run:
			ys.append(surf.height(p.x, p.y) + lift)
		if embedded:
			_rails(RoadBuilder._batch(batches, "rail"), run, ys, gauge, 0.0, m2u, RAIL_LAYER)
			if bool(way.get("cable", false)):
				# A concrete track bed in the asphalt, and the cable slot:
				# two steel slot rails either side of a gap.
				RoadBuilder._ribbon(RoadBuilder._batch(batches, "track_bed"),
					RoadBuilder._straighten(run, surf.step), gauge + CABLE_BED_M * m2u, surf,
					STREET_RAIL_LIFT_M * 0.6 * m2u, Color(0, 0, 0, 1), {}, CABLE_BED_LAYER)
				_rails(RoadBuilder._batch(batches, "rail"), run, ys, CABLE_SLOT_M * m2u, 0.0, m2u, RAIL_LAYER)
		else:
			RoadBuilder._ribbon(RoadBuilder._batch(batches, "ballast"),
				RoadBuilder._straighten(run, surf.step), bed, surf, BED_LIFT_M * m2u,
				Color(0, 0, 0, 1), {}, BED_LAYER)
			_rails(RoadBuilder._batch(batches, "rail"), run, ys, gauge,
				RAIL_HEIGHT_M * m2u, m2u, BED_LAYER + 0.1)

## Deck (RoadBuilder's slab, fascias and parapets) with a ballast top,
## and the rails on it.
static func _bridge(batches: Dictionary, pts: PackedVector2Array, gauge: float,
		bed: float, surf: RoadBuilder._Surface, m2u: float) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	var top := RoadBuilder._batch(batches, "rail_deck")
	top.pad()
	var k0 := top.verts.size()
	RoadBuilder._bridge(batches, inside, bed, surf, m2u, "rail_deck")
	top.pad()
	for i in range(k0, top.verts.size()):
		top.uv2s[i] = Vector2(bed / m2u, BED_LAYER)
	var deck := RoadBuilder.deck_profile(inside, surf, m2u, bed * 0.5)
	if deck.size() != inside.size():
		return
	var ys := PackedFloat32Array()
	for d in deck:
		ys.append(d + RAIL_HEIGHT_M * m2u)
	_rails(RoadBuilder._batch(batches, "rail"), inside, ys, gauge,
		RAIL_HEIGHT_M * m2u, m2u, BED_LAYER + 0.1)

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
		"track_bed":
			# Depth-layered like the road ribbons (a plain PBR deck would
			# z-fight the asphalt it is set in).
			m = RoadSurface.paved_material("pavement", Color.html(TRACK_BED_HEX).srgb_to_linear())
		"rail":
			var rsh := Shader.new()
			rsh.code = RAIL_CODE.replace("// @DEPTH", RoadSurface.DEPTH_GLSL)
			var rm := ShaderMaterial.new()
			rm.shader = rsh
			rm.set_shader_parameter("steel", Color.html(STEEL_HEX))
			m = rm
		_:
			m = RoadBuilder._material(key)
	_mats[key] = m
	return m
