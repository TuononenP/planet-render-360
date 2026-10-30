class_name RoadBuilder
extends RefCounted

## OSM roads as draped ribbon meshes (T4.4). Each attributed §2.5
## centreline becomes a mitred ribbon of its real width (`width_m`, i.e.
## the `width` tag, else lanes × 3 m, else the class default) whose
## vertices sit on the rendered terrain surface — the exact triangle the
## terrain mesh draws, never below the GroundTruth bilinear surface — plus
## a few centimetres (PRD §4.4: flush, offset ≤ 0.05 m, 0 floating
## planks). Ribbons are resampled finer than the terrain grid so they
## follow its creases. `surface` picks the finish (asphalt, paving/sett,
## gravel), footways/paths read as pavement, and one merged
## surface per finish keeps draw calls to a handful. Real `bridge=yes`
## ways become decks with fascia sides and parapets, arched from bank to
## bank to clear the water/road beneath; non-bridge segments over water
## are dropped (no shards in the river); tunnels are skipped. Asphalt
## is RoadSurface's shader: lane markings, crossings, kerbs, wear and
## weather on every tier, from the per-vertex lanes / rank / urban flag
## / junction distance written here. v1 bare centrelines
## are still accepted as {width 1.7 units, class unclassified}.
## TerrainBuilder.build_world adopts the children flat.

## Ribbon lift above the surface in metres, by draw rank (paths under
## streets under main roads, so crossings do not z-fight): ≤ 0.05 m.
const LIFT_M := [0.03, 0.04, 0.05]
## Bridge deck: clearance over water/ground, slab depth, parapet height.
const BRIDGE_CLEAR_M := 5.0
const DECK_DEPTH_M := 0.9
const PARAPET_M := 1.0
## Half-extent of the detailed surface the ribbons are clipped to
## (metres; the v1 108 of a 110-unit half extent).
const EXTENT_U := WorldScale.DETAILED_EXTENT_M * 0.5 - 2.0
## Finish albedos (sRGB; calibrated in linear against each set's mean).
## T4.7: asphalt is a weathered #585552 albedo so lit asphalt renders
## at the PRD's #4C4C4E–#5C5A58 through the ACES grade (the #4C4C4E
## albedo itself rendered near-black); paving is the PRD #8A8274 and
## setts/gravel sit warmer and lighter than asphalt.
const FINISH_HEX := {"asphalt": "#585552", "paving": "#8a8274",
	"sett": "#837a6e", "gravel": "#9a8c72", "deck": "#a39d92"}
static var _mats: Dictionary = {}

## Roads subtree: draped ribbons on the ground, bridge decks over water.
static func build_roads(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var root := Node3D.new()
	root.name = "Roads"
	_roads(root, data, ground)
	return root

## {points, width_u, finish, rank, bridge} for one road element, or {}
## when it is skipped (tunnel, too short, unknown shape).
static func _parse(line: Variant, m2u: float) -> Dictionary:
	if line is PackedVector2Array:
		return {"points": line, "width_u": 6.8, "finish": "asphalt", "rank": 1,
			"bridge": false, "class": "unclassified", "lanes": 0}
	if not (line is Dictionary):
		return {}
	var road: Dictionary = line
	if bool(road.get("tunnel", false)):
		return {}
	var cls := str(road.get("class", "unclassified"))
	return {"points": road.get("points", PackedVector2Array()),
		"width_u": maxf(float(road.get("width_m", 0.0)) * m2u, 0.4),
		"finish": _finish(cls, str(road.get("surface", "")).to_lower()),
		"rank": _rank(cls), "bridge": bool(road.get("bridge", false)),
		"class": cls, "lanes": int(road.get("lanes", 0))}

static func _rank(cls: String) -> int:
	match cls:
		"footway", "path", "steps", "cycleway", "bridleway", "pedestrian", "track", "corridor":
			return 0
		"motorway", "trunk", "primary", "secondary", "motorway_link", "trunk_link", "primary_link":
			return 2
	return 1

## Surface finish from the `surface` tag, else the class.
static func _finish(cls: String, surface: String) -> String:
	match surface:
		"paving_stones", "sett", "cobblestone", "unhewn_cobblestone", "bricks", "concrete:plates", "stone":
			return "sett"
		"gravel", "fine_gravel", "compacted", "dirt", "earth", "ground", "unpaved", "grass", "sand", "pebblestone":
			return "gravel"
		"asphalt", "concrete", "paved", "chipseal":
			return "asphalt"
	match cls:
		"footway", "path", "pedestrian", "steps", "cycleway", "corridor":
			return "paving"
		"track", "bridleway":
			return "gravel"
	return "asphalt"

static func _material(finish: String) -> Material:
	if _mats.has(finish):
		return _mats[finish] as Material
	var m: Material
	match finish:
		"paving", "sett", "gravel":
			m = _pbr("pavement", FINISH_HEX[finish])
		"deck":
			m = _pbr("concrete", FINISH_HEX["deck"])
		_:
			m = RoadSurface.material(Color.html(FINISH_HEX["asphalt"]).srgb_to_linear())
	_mats[finish] = m
	return m

static func _pbr(set_name: String, hex: String) -> Material:
	var target := Color.html(hex).srgb_to_linear()
	var row: Dictionary = MaterialLibrary.PBR_SETS[set_name]
	var m := MaterialLibrary.pbr_material(set_name,
		MaterialLibrary._calib_tint(row["mean"], target), 1.0)
	return m

static func _roads(root: Node3D, data: LocationData, ground: GroundTruth) -> void:
	_mats.clear()
	var m2u := WorldScale.metres_to_units()
	var surf := _Surface.new(data, ground)
	var junc := RoadSurface.junctions(data)
	var urban_map := RoadSurface.urban_raster(data)
	var batches := {}
	for line in data.roads:
		var r := _parse(line, m2u)
		if r.is_empty():
			continue
		var pts: PackedVector2Array = r["points"]
		if pts.size() < 2:
			continue
		var dense := _resample(pts, surf.step * 0.34)
		var finish := str(r["finish"])
		if bool(r["bridge"]):
			_bridge(batches, dense, float(r["width_u"]), surf, m2u)
			continue
		var lift := float(LIFT_M[int(r["rank"])]) * m2u
		# RoadSurface attributes: lanes, rank, kerbed urban street.
		var mid := dense[dense.size() / 2]
		var urban := int(r["rank"]) >= 1 and RoadSurface.is_urban(urban_map, mid)
		var attr := Color(clampf(float(r["lanes"]) / 8.0, 0.0, 1.0), float(r["rank"]) / 2.0,
			1.0 if urban else 0.0, 1.0)
		for run in _dry_runs(dense, surf):
			# Junction distance only feeds markings (rank >= 1 asphalt).
			_ribbon(_batch(batches, finish), run, float(r["width_u"]), surf, lift, attr,
				junc if int(r["rank"]) >= 1 and finish == "asphalt" else {})
	for finish in batches:
		var b: _Batch = batches[finish]
		if b.indices.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Road_" + str(finish)
		mi.mesh = b.mesh()
		mi.material_override = _material(str(finish))
		root.add_child(mi)

## Height of the drawn terrain at XZ (what a ribbon is laid on), for
## tests and other flush-placed props.
static func surface_height(data: LocationData, ground: GroundTruth, x: float,
		z: float) -> float:
	return _Surface.new(data, ground).height(x, z)

static func _batch(batches: Dictionary, finish: String) -> _Batch:
	if not batches.has(finish):
		batches[finish] = _Batch.new()
	return batches[finish]

## Polyline resampled so no segment exceeds max_len (keeps the input
## vertices, so mitres stay at the real bends).
static func _resample(pts: PackedVector2Array, max_len: float) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var n := maxi(1, ceili(a.distance_to(b) / maxf(max_len, 0.05)))
		for k in range(1, n + 1):
			out.append(a.lerp(b, float(k) / float(n)))
	return out

## Maximal runs of the polyline that are on land and on the detailed
## surface (≥2 points each): a non-bridge way never lays shards on water.
static func _dry_runs(pts: PackedVector2Array, surf: _Surface) -> Array:
	var runs: Array = []
	var cur := PackedVector2Array()
	for p in pts:
		var ok := absf(p.x) <= EXTENT_U and absf(p.y) <= EXTENT_U \
			and surf.ground.water_at(p.x, p.y) <= 0.0
		if ok:
			cur.append(p)
		else:
			if cur.size() >= 2:
				runs.append(cur)
			cur = PackedVector2Array()
	if cur.size() >= 2:
		runs.append(cur)
	return runs

## Unit mitre offset at vertex i (miter length capped at 2.5x).
static func _side(pts: PackedVector2Array, i: int) -> Vector2:
	var n := pts.size()
	var d0 := (pts[i] - pts[maxi(i - 1, 0)])
	var d1 := (pts[mini(i + 1, n - 1)] - pts[i])
	if d0.length() < 0.00001:
		d0 = d1
	if d1.length() < 0.00001:
		d1 = d0
	var n0 := Vector2(-d0.y, d0.x).normalized()
	var n1 := Vector2(-d1.y, d1.x).normalized()
	var m := (n0 + n1)
	if m.length() < 0.001:
		return n1
	m = m.normalized()
	var k := 1.0 / maxf(m.dot(n1), 0.4)
	return m * k

## Flat ribbon draped on the surface: both edges sample the terrain at
## every vertex. UVs in metres/4 so the asphalt grain keeps its size.
static func _ribbon(b: _Batch, pts: PackedVector2Array, width: float,
		surf: _Surface, lift: float, attr: Color = Color(0, 0.5, 0, 1),
		junc: Dictionary = {}) -> void:
	var half := width * 0.5
	var along := 0.0
	var m2u := WorldScale.metres_to_units()
	b.pad()
	var k0 := b.verts.size()
	for i in pts.size():
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
		var s := _side(pts, i) * half
		var l := pts[i] + s
		var r := pts[i] - s
		b.verts.append(Vector3(l.x, surf.height(l.x, l.y) + lift, l.y))
		b.verts.append(Vector3(r.x, surf.height(r.x, r.y) + lift, r.y))
		var n := surf.normal(pts[i].x, pts[i].y)
		b.normals.append(n)
		b.normals.append(n)
		var v := along / m2u / 4.0
		b.uvs.append(Vector2(0.0, v))
		b.uvs.append(Vector2(width / m2u / 4.0, v))
		attr.a = RoadSurface.junction_frac(junc, pts[i]) if not junc.is_empty() else 1.0
		b.colors.append_array([attr, attr])
		b.uv2s.append_array([Vector2(width / m2u, 0.0), Vector2(width / m2u, 0.0)])
	for i in pts.size() - 1:
		var a := k0 + i * 2
		_quad_up(b, a, a + 1, a + 2, a + 3)

## Two triangles over left/right pairs (a,b) → (c,d), wound so the front
## face points up whichever way the polyline runs.
static func _quad_up(b: _Batch, a: int, bb: int, c: int, d: int) -> void:
	var va := b.verts[a]
	var front := (b.verts[c] - va).cross(b.verts[bb] - va)
	if front.y >= 0.0:
		b.indices.append_array([a, bb, c, bb, d, c])
	else:
		b.indices.append_array([a, c, bb, bb, c, d])

## Bridge deck on a real `bridge=yes` way: the deck runs bank to bank,
## rising in a smooth arch so its middle clears the water (or ground)
## below by BRIDGE_CLEAR_M; slab fascias on both sides and parapets.
static func _bridge(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: _Surface, m2u: float) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if absf(p.x) <= EXTENT_U and absf(p.y) <= EXTENT_U:
			inside.append(p)
	if inside.size() < 2:
		return
	pts = inside
	var n := pts.size()
	var total := 0.0
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		total += pts[i].distance_to(pts[i - 1])
		dist.append(total)
	if total <= 0.0:
		return
	var h0 := surf.height(pts[0].x, pts[0].y)
	var h1 := surf.height(pts[n - 1].x, pts[n - 1].y)
	var need := 0.0
	for i in n:
		var t := dist[i] / total
		var base := lerpf(h0, h1, t)
		var under := surf.height(pts[i].x, pts[i].y)
		var water := surf.ground.water_at(pts[i].x, pts[i].y) > 0.0
		var floor_y := maxf(under, surf.ground.water_level_at(pts[i].x, pts[i].y) if water else under)
		var clear := BRIDGE_CLEAR_M * m2u if water else 0.6 * m2u
		need = maxf(need, (floor_y + clear - base) / maxf(sin(PI * clampf(t, 0.02, 0.98)), 0.25))
	var deck := PackedFloat32Array()
	for i in n:
		var t := dist[i] / total
		deck.append(lerpf(h0, h1, t) + 0.05 * m2u + maxf(need, 0.0) * sin(PI * t))
	var top := _batch(batches, "asphalt")
	var side := _batch(batches, "deck")
	var half := width * 0.5
	var k0 := top.verts.size()
	for i in n:
		var s := _side(pts, i) * half
		var l := pts[i] + s
		var r := pts[i] - s
		top.verts.append(Vector3(l.x, deck[i], l.y))
		top.verts.append(Vector3(r.x, deck[i], r.y))
		top.normals.append(Vector3.UP)
		top.normals.append(Vector3.UP)
		top.uvs.append(Vector2(0.0, dist[i] / m2u / 4.0))
		top.uvs.append(Vector2(width / m2u / 4.0, dist[i] / m2u / 4.0))
	for i in n - 1:
		var a := k0 + i * 2
		_quad_up(top, a, a + 1, a + 2, a + 3)
	# Fascia + parapet walls along both edges (outer: slab bottom to
	# parapet top; inner: deck to parapet top), and the parapet cap.
	var depth := DECK_DEPTH_M * m2u
	var para := PARAPET_M * m2u
	var thick := 0.25 * m2u
	for sgn in [1.0, -1.0]:
		for i in n - 1:
			var sa: Vector2 = _side(pts, i) * half * sgn
			var sb: Vector2 = _side(pts, i + 1) * half * sgn
			var oa := pts[i] + sa
			var ob := pts[i + 1] + sb
			var ia := oa - sa.normalized() * thick
			var ib := ob - sb.normalized() * thick
			_wall(side, oa, ob, deck[i] - depth, deck[i + 1] - depth, deck[i] + para,
				deck[i + 1] + para, sa.normalized())
			_wall(side, ia, ib, deck[i], deck[i + 1], deck[i] + para, deck[i + 1] + para,
				-sa.normalized())
			var k := side.verts.size()
			side.verts.append_array([Vector3(oa.x, deck[i] + para, oa.y),
				Vector3(ia.x, deck[i] + para, ia.y), Vector3(ob.x, deck[i + 1] + para, ob.y),
				Vector3(ib.x, deck[i + 1] + para, ib.y)])
			for q in 4:
				side.normals.append(Vector3.UP)
				side.uvs.append(Vector2(float(q % 2), float(q / 2)))
			_quad_up(side, k, k + 1, k + 2, k + 3)
	# Slab underside (seen from the quay).
	var kb := side.verts.size()
	for i in n:
		var s := _side(pts, i) * half
		side.verts.append(Vector3(pts[i].x + s.x, deck[i] - depth, pts[i].y + s.y))
		side.verts.append(Vector3(pts[i].x - s.x, deck[i] - depth, pts[i].y - s.y))
		side.normals.append(Vector3.DOWN)
		side.normals.append(Vector3.DOWN)
		side.uvs.append(Vector2(0, dist[i] / m2u / 4.0))
		side.uvs.append(Vector2(1, dist[i] / m2u / 4.0))
	for i in n - 1:
		var a := kb + i * 2
		var va := side.verts[a]
		var front := (side.verts[a + 2] - va).cross(side.verts[a + 1] - va)
		if front.y <= 0.0:
			side.indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
		else:
			side.indices.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])

## Vertical quad a→b between bottom (ya0, yb0) and top (ya1, yb1),
## front face toward `out`.
static func _wall(b: _Batch, a: Vector2, c: Vector2, ya0: float, yc0: float,
		ya1: float, yc1: float, out: Vector2) -> void:
	var k := b.verts.size()
	b.verts.append_array([Vector3(a.x, ya0, a.y), Vector3(c.x, yc0, c.y),
		Vector3(c.x, yc1, c.y), Vector3(a.x, ya1, a.y)])
	var n3 := Vector3(out.x, 0.0, out.y)
	for q in 4:
		b.normals.append(n3)
	var len_u := a.distance_to(c)
	b.uvs.append_array([Vector2(0, 1), Vector2(len_u, 1), Vector2(len_u, 0), Vector2(0, 0)])
	var front := (b.verts[k + 2] - b.verts[k]).cross(b.verts[k + 1] - b.verts[k])
	if front.dot(n3) >= 0.0:
		b.indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		b.indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

## Mesh arrays of one finish (merged across every road).
class _Batch extends RefCounted:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()

	## Attribute rows for vertices added without them (bridge decks).
	func pad() -> void:
		while colors.size() < verts.size():
			colors.append(Color(0, 0.5, 0, 1))
		while uv2s.size() < verts.size():
			uv2s.append(Vector2.ZERO)

	func mesh() -> ArrayMesh:
		pad()
		var m := ArrayMesh.new()
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV2] = uv2s
		arrays[Mesh.ARRAY_INDEX] = indices
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m

## The rendered ground surface: the terrain mesh's own triangle under a
## point (TerrainBuilder._terrain_mesh splits each grid cell a-b-c /
## b-d-c), never below GroundTruth's bilinear surface, so a ribbon lies
## on what is drawn whichever way the cell is split.
class _Surface extends RefCounted:
	var ground: GroundTruth
	var size := 0
	var step := 1.0

	func _init(data: LocationData, g: GroundTruth) -> void:
		ground = g
		size = data.grid_size
		step = WorldScale.detailed_extent_units() / float(maxi(size - 1, 1))

	func height(x: float, z: float) -> float:
		var bil := ground.height_at_world(x, z)
		if size < 2:
			return bil
		var fx := clampf(x / step + float(size) * 0.5, 0.0, float(size - 1))
		var fz := clampf(z / step + float(size) * 0.5, 0.0, float(size - 1))
		var x0 := mini(int(fx), size - 2)
		var z0 := mini(int(fz), size - 2)
		var tx := fx - float(x0)
		var tz := fz - float(z0)
		var ha := ground.surface_at_post(x0, z0)
		var hb := ground.surface_at_post(x0 + 1, z0)
		var hc := ground.surface_at_post(x0, z0 + 1)
		var hd := ground.surface_at_post(x0 + 1, z0 + 1)
		var tri: float
		if tx + tz <= 1.0:
			tri = ha + (hb - ha) * tx + (hc - ha) * tz
		else:
			tri = hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz)
		return maxf(tri, bil)

	func normal(x: float, z: float) -> Vector3:
		var e := step * 0.5
		var dx := height(x + e, z) - height(x - e, z)
		var dz := height(x, z + e) - height(x, z - e)
		return Vector3(-dx, 2.0 * e, -dz).normalized()
