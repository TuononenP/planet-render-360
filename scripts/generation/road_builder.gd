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
## ways become decks with fascia sides and parapets, gently arched bank to
## bank (grade and rise capped); non-bridge segments over water
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
## Deck camber limits: the arch is never steeper than BRIDGE_GRADE nor
## higher than BRIDGE_RISE_M above the line between its banks (city DEMs
## put a river at quay height, so full clearance would hump every deck).
const BRIDGE_GRADE := 0.05
const BRIDGE_RISE_M := 3.0
## Steepest ramp easing a deck lifted clear of the water.
const RAMP_GRADE := 0.08
## Margin inside the drawn terrain mesh's edge the roads are clipped to
## (metres). The mesh is not centred: its last post row stops one post
## short of the extent's +X / +Z edge, and past it only the far terrain
## lies under a ribbon.
const EDGE_M := 2.0
## Finish albedos (sRGB; calibrated in linear against each set's mean).
## T4.7: asphalt is a weathered #585552 albedo so lit asphalt renders
## at the PRD's #4C4C4E–#5C5A58 through the ACES grade (the #4C4C4E
## albedo itself rendered near-black); paving is the PRD #8A8274 and
## setts/gravel sit warmer and lighter than asphalt.
const FINISH_HEX := {"asphalt": "#585552", "paving": "#8a8274",
	"sett": "#837a6e", "gravel": "#9a8c72", "deck": "#a39d92"}
## Road-list chunks built in parallel (fixed, so the mesh never depends
## on the core count).
const CHUNKS := 4
static var _mats: Dictionary = {}

## Roads subtree: draped ribbons on the ground, bridge decks over water.
## `abort` stops it between rows / items; a stopped result is dropped.
static func build_roads(data: LocationData, ground: GroundTruth = null, abort: BuildAbort = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var root := Node3D.new()
	root.name = "Roads"
	_roads(root, data, ground, abort)
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
			m = RoadSurface.paved_material("pavement", Color.html(FINISH_HEX[finish]).srgb_to_linear())
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

static func _roads(root: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort = null) -> void:
	_mats.clear()
	var m2u := WorldScale.metres_to_units()
	var surf := _Surface.new(data, ground)
	var junc := RoadSurface.junctions(data)
	var steps := RoadSurface.depth_steps(data)
	# A registry bridge's model carries its own deck over its span.
	var spans := LandmarkSites.bridge_spans(data)
	# Fixed chunks of the road list, built at once and joined in order:
	# the same mesh whichever threads ran them.
	var n := data.roads.size()
	var parts: Array = []
	parts.resize(CHUNKS)
	var job := func(c: int) -> void:
		var own := {}
		for i in range(n * c / CHUNKS, n * (c + 1) / CHUNKS):
			if abort != null and abort.requested:
				break
			_road(own, data.roads[i], steps[i], m2u, surf, ground, junc, spans, abort)
		parts[c] = own
	var group := WorkerThreadPool.add_group_task(job, CHUNKS, -1, false, "Roads")
	WorkerThreadPool.wait_for_group_task_completion(group)
	var batches := {}
	for own in parts:
		for finish in own:
			_batch(batches, finish).join(own[finish])
	for finish in batches:
		var b: _Batch = batches[finish]
		if b.indices.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Road_" + str(finish)
		mi.mesh = b.mesh()
		mi.material_override = _material(str(finish))
		# Ribbons lie 3–5 cm proud of the ground: only decks cast (this
		# is the one place that decides; LodRing leaves roads alone).
		if not (str(finish) in ["bridge", "deck"]):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)

## One road element (at depth `step`, RoadSurface.depth_steps) into
## `batches`: draped ribbons on dry land, decks on its bridge spans.
static func _road(batches: Dictionary, line: Variant, step: int, m2u: float, surf: _Surface,
		ground: GroundTruth, junc: Dictionary, spans: Array, abort: BuildAbort) -> void:
	var r := _parse(line, m2u)
	if r.is_empty():
		return
	var pts: PackedVector2Array = r["points"]
	if pts.size() < 2:
		return
	var dense := _resample(pts, surf.step * 0.34)
	var finish := str(r["finish"])
	if bool(r["bridge"]):
		for piece in LandmarkSites.outside_spans(dense, spans):
			_bridge(batches, piece, float(r["width_u"]), surf, m2u)
		return
	var lift := float(LIFT_M[int(r["rank"])]) * m2u
	# RoadSurface attributes: lanes, rank, kerbed urban street.
	var mid := dense[dense.size() / 2]
	var urban := int(r["rank"]) >= 1 and ground.land_class_at(mid.x, mid.y) == "urban"
	var attr := Color(clampf(float(r["lanes"]) / 8.0, 0.0, 1.0), float(r["rank"]) / 2.0,
		1.0 if urban else 0.0, 1.0)
	for run in _dry_runs(dense, surf):
		if abort != null and abort.requested:
			break
		_ribbon(_batch(batches, finish), _straighten(run, surf.step), float(r["width_u"]),
			surf, lift, attr, junc, depth_layer(int(r["rank"]), finish, step))

## Height of the drawn terrain at XZ (what a ribbon is laid on), for
## tests and other flush-placed props.
static func surface_height(data: LocationData, ground: GroundTruth, x: float,
		z: float) -> float:
	return _Surface.new(data, ground).height(x, z)

## Depth layer a ribbon is drawn at (RoadSurface.DEPTH_GLSL, UV2.y):
## main roads over streets over paths, asphalt over the other finishes
## of its rank, and a step per road (RoadSurface.depth_steps) so two
## streets meeting at a junction never tie. A 1-5 cm lift alone is below
## the depth buffer's resolution a few hundred metres out, so they flickered.
static func depth_layer(rank: int, finish: String, step: int) -> float:
	return 1.0 + float(rank) * 2.0 + (1.0 if finish == "asphalt" else 0.0) + float(step) * 0.11

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

## Drops the resampled points that sit on a straight stretch, keeping
## rows at most `max_len` apart: RoadDrape cuts each quad along the
## terrain creases itself, so finer rows only cost vertices.
static func _straighten(pts: PackedVector2Array, max_len: float) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	for i in range(1, pts.size() - 1):
		var d0 := pts[i] - out[out.size() - 1]
		var d1 := pts[i + 1] - pts[i]
		var bend := absf(d0.normalized().cross(d1.normalized())) > 0.001
		if bend or (pts[i + 1] - out[out.size() - 1]).length() > max_len:
			out.append(pts[i])
	out.append(pts[pts.size() - 1])
	return out

## Maximal runs of the polyline that are on land and on the detailed
## surface (≥2 points each): a non-bridge way never lays shards on water.
static func _dry_runs(pts: PackedVector2Array, surf: _Surface) -> Array:
	var runs: Array = []
	var cur := PackedVector2Array()
	for p in pts:
		var ok := surf.inside(p) and surf.ground.water_at(p.x, p.y) <= 0.0
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

## Flat ribbon draped on the surface, cut along the drawn terrain's
## creases (RoadDrape) so no ridge pokes through it. UVs in metres/4 so
## the asphalt grain keeps its size.
static func _ribbon(b: _Batch, pts: PackedVector2Array, width: float,
		surf: _Surface, lift: float, attr: Color = Color(0, 0.5, 0, 1),
		junc: Dictionary = {}, layer: float = 1.0) -> void:
	var half := width * 0.5
	var along := 0.0
	var m2u := WorldScale.metres_to_units()
	b.pad()
	var u1 := width / m2u / 4.0
	var w2 := Vector2(width / m2u, layer)
	var weld := {}
	var prev: Array = []
	for i in pts.size():
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
		var s := _side(pts, i) * half
		var row: Array = [pts[i] + s, pts[i] - s, along / m2u / 4.0,
			RoadSurface.junction_frac(junc, pts[i]) if not junc.is_empty() else 1.0,
			surf.normal(pts[i].x, pts[i].y)]
		if i > 0:
			RoadDrape.quad(b, surf, lift, attr, w2, u1, weld, prev, row)
		prev = row

## Two triangles over left/right pairs (a,b) → (c,d), wound so the front
## face points up whichever way the polyline runs.
static func _quad_up(b: _Batch, a: int, bb: int, c: int, d: int) -> void:
	var va := b.verts[a]
	var front := (b.verts[c] - va).cross(b.verts[bb] - va)
	# Avoid Array literal alloc in hot loop: push indices individually.
	if front.y >= 0.0:
		b.indices.push_back(a); b.indices.push_back(bb); b.indices.push_back(c)
		b.indices.push_back(bb); b.indices.push_back(d); b.indices.push_back(c)
	else:
		b.indices.push_back(a); b.indices.push_back(c); b.indices.push_back(bb)
		b.indices.push_back(bb); b.indices.push_back(c); b.indices.push_back(d)

## Deck heights along a bridge polyline (world units, one per point):
## bank to bank, rising in a smooth arch toward BRIDGE_CLEAR_M over the
## water (0.6 m over ground) below, capped at BRIDGE_GRADE and
## BRIDGE_RISE_M so a short or low crossing stays nearly flat. The slab
## never dips into the water: an end the river carve reaches is lifted
## to the water, and every wet point keeps the slab above it. With a
## `half` width the flat deck also clears the ground under both edges
## (a bank sloping across the way), lifted like a ribbon.
static func deck_profile(pts: PackedVector2Array, surf: _Surface, m2u: float,
		half: float = 0.0) -> PackedFloat32Array:
	var n := pts.size()
	var total := 0.0
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		total += pts[i].distance_to(pts[i - 1])
		dist.append(total)
	var deck := PackedFloat32Array()
	if total <= 0.0:
		return deck
	var slab := (DECK_DEPTH_M + 0.5) * m2u
	var h0 := _deck_floor(pts, 0, surf, slab, half)
	var h1 := _deck_floor(pts, n - 1, surf, slab, half)
	var need := 0.0
	for i in n:
		var t := dist[i] / total
		var under := surf.height(pts[i].x, pts[i].y)
		var water := surf.ground.water_at(pts[i].x, pts[i].y) > 0.0
		var floor_y := maxf(under, surf.ground.water_level_at(pts[i].x, pts[i].y) if water else under)
		var clear := BRIDGE_CLEAR_M * m2u if water else 0.6 * m2u
		# Points by the banks would need a huge arch to clear the
		# water there; the middle two-thirds set the rise.
		need = maxf(need, (floor_y + clear - lerpf(h0, h1, t)) / maxf(sin(PI * t), 0.5))
	var rise := clampf(need, 0.0, minf(BRIDGE_GRADE * total / PI, BRIDGE_RISE_M * m2u))
	# Lift over the arch where the slab would touch the water, eased out
	# at RAMP_GRADE both ways so it reads as a ramp, not a step.
	var lift := PackedFloat32Array()
	for i in n:
		var t := dist[i] / total
		var arch := lerpf(h0, h1, t) + 0.05 * m2u + rise * sin(PI * t)
		deck.append(arch)
		lift.append(maxf(_deck_floor(pts, i, surf, slab, half) + 0.05 * m2u - arch, 0.0))
	for i in range(1, n):
		lift[i] = maxf(lift[i], lift[i - 1] - RAMP_GRADE * (dist[i] - dist[i - 1]))
	for i in range(n - 2, -1, -1):
		lift[i] = maxf(lift[i], lift[i + 1] - RAMP_GRADE * (dist[i + 1] - dist[i]))
	for i in n:
		deck[i] += lift[i]
	return deck

## Lowest deck height at point i: the drawn ground under its centre and
## both edges (`half` out), or over water the water surface plus `slab`
## (slab depth and a little air).
static func _deck_floor(pts: PackedVector2Array, i: int, surf: _Surface, slab: float,
		half: float) -> float:
	var p := pts[i]
	var h := surf.height(p.x, p.y)
	if half > 0.0:
		var s := _side(pts, i) * half
		h = maxf(h, maxf(surf.height(p.x + s.x, p.y + s.y), surf.height(p.x - s.x, p.y - s.y)))
	if surf.ground.water_at(p.x, p.y) > 0.0:
		h = maxf(h, surf.ground.water_level_at(p.x, p.y) + slab)
	return h

## Bridge deck on a real `bridge=yes` way (profile from deck_profile),
## with slab fascias on both sides and parapets.
static func _bridge(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: _Surface, m2u: float) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	pts = inside
	var n := pts.size()
	var deck := deck_profile(pts, surf, m2u, width * 0.5)
	if deck.is_empty():
		return
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		dist.append(dist[i - 1] + pts[i].distance_to(pts[i - 1]))
	var top := _batch(batches, "bridge")
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
			side.verts.push_back(Vector3(oa.x, deck[i] + para, oa.y))
			side.verts.push_back(Vector3(ia.x, deck[i] + para, ia.y))
			side.verts.push_back(Vector3(ob.x, deck[i + 1] + para, ob.y))
			side.verts.push_back(Vector3(ib.x, deck[i + 1] + para, ib.y))
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
			side.indices.push_back(a); side.indices.push_back(a + 1); side.indices.push_back(a + 2)
			side.indices.push_back(a + 1); side.indices.push_back(a + 3); side.indices.push_back(a + 2)
		else:
			side.indices.push_back(a); side.indices.push_back(a + 2); side.indices.push_back(a + 1)
			side.indices.push_back(a + 1); side.indices.push_back(a + 2); side.indices.push_back(a + 3)

## Vertical quad a→b between bottom (ya0, yb0) and top (ya1, yb1),
## front face toward `out`.
static func _wall(b: _Batch, a: Vector2, c: Vector2, ya0: float, yc0: float,
		ya1: float, yc1: float, out: Vector2) -> void:
	var k := b.verts.size()
	b.verts.push_back(Vector3(a.x, ya0, a.y)); b.verts.push_back(Vector3(c.x, yc0, c.y))
	b.verts.push_back(Vector3(c.x, yc1, c.y)); b.verts.push_back(Vector3(a.x, ya1, a.y))
	var n3 := Vector3(out.x, 0.0, out.y)
	for q in 4:
		b.normals.append(n3)
	var len_u := a.distance_to(c)
	b.uvs.push_back(Vector2(0, 1)); b.uvs.push_back(Vector2(len_u, 1))
	b.uvs.push_back(Vector2(len_u, 0)); b.uvs.push_back(Vector2(0, 0))
	var front := (b.verts[k + 2] - b.verts[k]).cross(b.verts[k + 1] - b.verts[k])
	if front.dot(n3) >= 0.0:
		b.indices.push_back(k); b.indices.push_back(k + 1); b.indices.push_back(k + 2)
		b.indices.push_back(k); b.indices.push_back(k + 2); b.indices.push_back(k + 3)
	else:
		b.indices.push_back(k); b.indices.push_back(k + 2); b.indices.push_back(k + 1)
		b.indices.push_back(k); b.indices.push_back(k + 3); b.indices.push_back(k + 2)

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

	## Appends `o`'s rows and triangles after this batch's own.
	func join(o: _Batch) -> void:
		pad()
		o.pad()
		var k := verts.size()
		verts.append_array(o.verts)
		normals.append_array(o.normals)
		uvs.append_array(o.uvs)
		colors.append_array(o.colors)
		uv2s.append_array(o.uv2s)
		for i in o.indices:
			indices.append(i + k)

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
	## The preset's terrain mesh (TerrainBuilder._terrain_mesh): coarser
	## than the post grid below Ultra, its posts sampled bilinearly. Its
	## chords sit above GroundTruth in every hollow, so a ribbon draped
	## on the full grid alone vanishes under it in patches.
	var mesh_size := 0
	var mesh_step := 1.0

	func _init(data: LocationData, g: GroundTruth) -> void:
		ground = g
		size = data.grid_size
		step = WorldScale.detailed_extent_units() / float(maxi(size - 1, 1))
		mesh_size = mini(RenderSettings.terrain_mesh_posts_for(data.quality_preset), size)
		mesh_step = WorldScale.detailed_extent_units() / float(maxi(mesh_size - 1, 1))

	## True inside the drawn mesh, EDGE_M clear of its edge.
	func inside(p: Vector2) -> bool:
		var lo := -float(mesh_size) * 0.5 * mesh_step + EDGE_M
		var hi := (float(mesh_size) * 0.5 - 1.0) * mesh_step - EDGE_M
		return p.x >= lo and p.x <= hi and p.y >= lo and p.y <= hi

	func height(x: float, z: float) -> float:
		if mesh_size >= 2 and mesh_size != size:
			return maxf(_mesh_tri(x, z), ground.height_at_world(x, z))
		# Fused bilinear + triangle height sample: read same
		# 4 posts once, do 3 lerps, compute tri and bil from same data, return
		# max. Bit-identical to the previous two separate reads: the 4 posts,
		# fx/fz/tx/tz and the lerp order are exactly as before.
		if size < 2:
			return ground.height_at_world(x, z)
		var fx := clampf(x / step + float(size) * 0.5, 0.0, float(size - 1))
		var fz := clampf(z / step + float(size) * 0.5, 0.0, float(size - 1))
		var x0 := mini(int(fx), size - 2)
		var z0 := mini(int(fz), size - 2)
		var tx := fx - float(x0)
		var tz := fz - float(z0)
		var ha: float = ground.surface_at_post(x0, z0)
		var hb: float = ground.surface_at_post(x0 + 1, z0)
		var hc: float = ground.surface_at_post(x0, z0 + 1)
		var hd: float = ground.surface_at_post(x0 + 1, z0 + 1)
		# Bilinear from same 4 posts (same 3 lerps as GroundTruth.height_at_world).
		var a := lerpf(ha, hb, tx)
		var b := lerpf(hc, hd, tx)
		var bil := lerpf(a, b, tz)
		var tri: float
		if tx + tz <= 1.0:
			tri = ha + (hb - ha) * tx + (hc - ha) * tz
		else:
			tri = hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz)
		return maxf(tri, bil)

	## Height of the coarse mesh's own triangle (split a-b-c / b-d-c).
	func _mesh_tri(x: float, z: float) -> float:
		var hs := float(mesh_size) * 0.5
		var fx := clampf(x / mesh_step + hs, 0.0, float(mesh_size - 1))
		var fz := clampf(z / mesh_step + hs, 0.0, float(mesh_size - 1))
		var x0 := mini(int(fx), mesh_size - 2)
		var z0 := mini(int(fz), mesh_size - 2)
		var tx := fx - float(x0)
		var tz := fz - float(z0)
		var px := (float(x0) - hs) * mesh_step
		var pz := (float(z0) - hs) * mesh_step
		var hb := ground.height_at_world(px + mesh_step, pz)
		var hc := ground.height_at_world(px, pz + mesh_step)
		if tx + tz <= 1.0:
			var ha := ground.height_at_world(px, pz)
			return ha + (hb - ha) * tx + (hc - ha) * tz
		var hd := ground.height_at_world(px + mesh_step, pz + mesh_step)
		return hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz)

	func normal(x: float, z: float) -> Vector3:
		var e := step * 0.5
		var dx := height(x + e, z) - height(x - e, z)
		var dz := height(x, z + e) - height(x, z - e)
		return Vector3(-dx, 2.0 * e, -dz).normalized()
