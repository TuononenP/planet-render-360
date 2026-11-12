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
## is RoadSurface's shader: kerbs, wear and weather on every tier, from
## the per-vertex rank / urban flag / junction distance written here.
## Lines, crossings, stop lines and symbols are a paint layer of their
## own over it (RoadMarkings, RoadPaint, RoadGlyphs). v1 bare centrelines
## are still accepted as {width 1.7 units, class unclassified}.
## TerrainBuilder.build_world adopts the children flat.

## Ribbon lift above the surface in metres rises with the depth layer
## (lift_for_layer), so the two can never disagree: at street-level eye
## heights a 1 cm lift outweighs the depth bias, and a crossing lifted
## less than the road it lies on vanished under it.
const LIFT_MIN_M := 0.03
const LIFT_MAX_M := 0.05
const LIFT_TOP_LAYER := 7.7
## Paved areas (squares) lie under every ribbon, paths included.
const AREA_LIFT_M := 0.02
const AREA_LAYER := 0.5
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
## Ramp of an elevated land bridge up from its ends: a road's grade, and
## a path's (stairs and ramps; up to PATH_WIDTH_M wide).
const PATH_RAMP_GRADE := 0.35
const PATH_WIDTH_M := 4.0
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
## A marked crossing is at least this wide (m), and drawn over the
## carriageways (rank 2 asphalt tops out at layer ~6.8).
const CROSSING_MIN_M := 4.0
const CROSSING_LAYER := 6.9
## A crossing's band or a stop line is laid as its own wide ribbon, flat
## between its edges, over road ribbons flat between theirs: where the
## ground curves the road stood proud of the paint and bit a ragged notch
## out of it, centimetres on a gentle street and more across a steep
## one. Bands lie this much higher, with a row every BAND_ROW_M.
const BAND_LIFT_M := 0.1
const BAND_ROW_M := 1.0
static var _mats: Dictionary = {}

## Roads subtree: draped ribbons on the ground, bridge decks over water.
## `abort` stops it between rows / items; a stopped result is dropped.
static func build_roads(data: LocationData, ground: GroundTruth = null, abort: BuildAbort = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	RoadSurface.set_place(data)
	var root := Node3D.new()
	root.name = "Roads"
	_roads(root, data, ground, abort)
	RoadDecals.build(root, data, ground)
	KerbBuilder.build(root, data, ground)
	RailBuilder.build(root, data, ground, abort)
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
	# A footway mapped below ground (a station concourse, a subway under
	# the street) with no tunnel tag is still not on the surface.
	if int(road.get("layer", 0)) < 0 and _rank(cls) == 0 and not bool(road.get("crossing", false)):
		return {}
	var crossing := bool(road.get("crossing", false))
	return {"points": road.get("points", PackedVector2Array()),
		"width_u": maxf(maxf(float(road.get("width_m", 0.0)), CROSSING_MIN_M if crossing else 0.0) * m2u, 0.4),
		"finish": "crossing" if crossing else _finish(cls, str(road.get("surface", "")).to_lower()),
		"rank": _rank(cls), "bridge": bool(road.get("bridge", false)),
		"bridge_structure": BridgeArches.structure(road), "layer": int(road.get("layer", 0)),
		"class": cls, "lanes": int(road.get("lanes", 0)), "oneway": int(road.get("oneway", 0))}

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

## In historic districts, an unmapped surface defaults to local setts;
## mapped surfaces, crossings and bridges always retain their own finish.
static func _district_finish(road: Dictionary, districts: Array, m2u: float) -> String:
	var cls := str(road.get("class", "unclassified"))
	var finish := "crossing" if bool(road.get("crossing", false)) else _finish(cls, str(road.get("surface", "")).to_lower())
	if str(road.get("surface", "")) != "" or bool(road.get("crossing", false)) or bool(road.get("bridge", false)):
		return finish
	var pts: PackedVector2Array = road.get("points", PackedVector2Array())
	if pts.is_empty():
		return finish
	var mid := pts[pts.size() / 2]
	if pts.size() % 2 == 0:
		mid = (mid + pts[pts.size() / 2 - 1]) * 0.5
	mid /= m2u
	for district in districts:
		if str(district[0]) == "stockholm_medieval" and mid.distance_to(district[1]) <= float(district[2]):
			return "sett"
	return finish

## The surface finish `line` is laid with, its district's included.
static func finish_of(line: Variant, surf: _Surface, m2u: float) -> String:
	var r := _parse(line, m2u)
	if r.is_empty():
		return "asphalt"
	if line is Dictionary and not surf.districts.is_empty():
		return _district_finish(line, surf.districts, m2u)
	return str(r["finish"])

static func _material(finish: String) -> Material:
	if _mats.has(finish):
		return _mats[finish] as Material
	var m: Material
	match finish:
		"paving", "sett", "gravel":
			m = RoadSurface.paved_material("pavement", Color.html(FINISH_HEX[finish]).srgb_to_linear())
		"deck":
			m = _pbr("concrete", FINISH_HEX["deck"])
		"crossing", "crossing_ladder", "crossing_lines", "crossing_dashes", "marking":
			var kind := "solid" if finish == "marking" else ("zebra" if finish == "crossing" else finish.trim_prefix("crossing_"))
			m = RoadPaint.crossing_material(float(RoadSurface.CROSSING_KINDS[kind]))
		"paint":
			m = RoadPaint.material()
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
	surf.use_native()
	var plan := RoadMarkings.plan(data, ground)
	var junc := plan.junctions
	surf.aprons = RoadMarkings._apron_grid(plan.aprons, m2u)
	for ring: PackedVector2Array in plan.aprons:
		surf.apron_rings.append([ring, RingGeometry.aabb(ring)])
	var steps := RoadSurface.depth_steps(data)
	var seeds := RoadSurface.wear_seeds(data)
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
			_road(own, data.roads[i], steps[i], m2u, surf, ground, junc, spans, abort, plan.by_road.get(i, {}), seeds[i])
		parts[c] = own
	var group := WorkerThreadPool.add_group_task(job, CHUNKS, -1, false, "Roads")
	WorkerThreadPool.wait_for_group_task_completion(group)
	var batches := {}
	for own in parts:
		for finish in own:
			_batch(batches, finish).join(own[finish])
	RoadMarkings.lay(plan, batches, surf, m2u, data)
	RoadPaint.lay(batches, data, surf, plan, seeds, m2u)
	RoadGlyphs.lay(batches, data, surf, m2u, plan)
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
		ground: GroundTruth, junc: Dictionary, spans: Array, abort: BuildAbort, marking: Dictionary = {},
		wear_seed: float = 0.5) -> void:
	var r := _parse(line, m2u)
	if r.is_empty():
		return
	if marking.has("runs"):
		# A crossing paints only where it is over the road.
		var whole := marking.duplicate()
		whole.erase("runs")
		for piece: PackedVector2Array in marking["runs"]:
			var part: Dictionary = (line as Dictionary).duplicate()
			part["points"] = piece
			_road(batches, part, step, m2u, surf, ground, junc, spans, abort, whole, wear_seed)
		return
	if not marking.is_empty():
		r["finish"] = marking["finish"]
		r["width_u"] = float(marking["width_m"]) * m2u
	var pts: PackedVector2Array = r["points"]
	if pts.size() < 2:
		return
	if line is Dictionary and bool((line as Dictionary).get("area", false)):
		_area(_batch(batches, str(r["finish"])), pts, (line as Dictionary).get("holes", []),
			surf, AREA_LIFT_M * m2u, m2u)
		return
	var dense := _resample(pts, surf.step * 0.34)
	var finish := str(r["finish"])
	if line is Dictionary and not surf.districts.is_empty() and marking.is_empty():
		finish = _district_finish(line, surf.districts, m2u)
	if bool(r["bridge"]):
		for piece in LandmarkSites.outside_spans(dense, spans):
			RoadBridgeDecks.build(batches, BridgeLandings.landed(piece, dense, surf, m2u), float(r["width_u"]), surf, m2u,
				str(r.get("bridge_structure", "unknown")), int(r.get("layer", 0)), pts, str(r.get("class", "")), r)
		return
	var layer := depth_layer(int(r["rank"]), finish, step)
	var lift := (lift_for_layer(layer) + (BAND_LIFT_M if finish.begins_with("crossing") else 0.0)) * m2u
	# RoadSurface attributes: lanes, rank, kerbed urban street + wear seed.
	var mid := dense[dense.size() / 2]
	var urban := int(r["rank"]) >= 1 and ground.land_class_at(mid.x, mid.y) == "urban"
	var attr := Color((clampf(float(r["lanes"]), 0.0, 8.0) + (16.0 if int(r.get("oneway", 0)) != 0 else 0.0)) / 32.0, float(r["rank"]) / 2.0,
		RoadSurface.wear_attr(urban, wear_seed), 1.0)
	for run in _dry_runs(dense, surf):
		if abort != null and abort.requested:
			break
		var pieces: Array = [run]
		if int(r["rank"]) == 0 and not finish.begins_with("crossing") and not surf.aprons.is_empty():
			pieces = RoadCrossingClip.on_road_runs(run, {}, surf.aprons, m2u, false)
		for piece: PackedVector2Array in pieces:
			_ribbon(_batch(batches, finish), band_rows(piece, m2u) if finish.begins_with("crossing") \
				else _straighten(piece, surf.step), float(r["width_u"]), surf, lift, attr, junc, layer)

## Paved area (a square) filled flat on the drawn terrain: the outer
## ring ear-clipped, triangles over its holes, open water or past the
## drawn mesh dropped, the rest cut and laid like ribbon pieces under
## every ribbon (AREA_LAYER). An outline ribbon only drew its edge.
static func _area(b: _Batch, ring: PackedVector2Array, holes: Array, surf: _Surface,
		lift: float, m2u: float, layer: float = AREA_LAYER) -> void:
	if ring.size() < 3:
		return
	# A junction's apron comes out of a paved area (a square whose corner
	# reaches into the junction): the carriageway is the apron's, and the
	# square's thin triangles showed through it as pale streaks. Aprons
	# and glyphs are laid through here too, on their own layers.
	var pieces: Array = [ring]
	if layer == AREA_LAYER and not surf.apron_rings.is_empty():
		holes = holes.duplicate()
		var box := RingGeometry.aabb(ring)
		for apron: Array in surf.apron_rings:
			if not box.intersects(apron[1]):
				continue
			var next: Array = []
			for piece: PackedVector2Array in pieces:
				for cut: PackedVector2Array in Geometry2D.clip_polygons(piece, apron[0]):
					if Geometry2D.is_polygon_clockwise(cut):
						holes.append(cut)
					else:
						next.append(cut)
			pieces = next
	var eligible := PackedVector2Array()
	for piece: PackedVector2Array in pieces:
		var idx := Geometry2D.triangulate_polygon(piece)
		for t in range(0, idx.size(), 3):
			var tri := PackedVector2Array([piece[idx[t]], piece[idx[t + 1]], piece[idx[t + 2]]])
			var c := (tri[0] + tri[1] + tri[2]) / 3.0
			if not (surf.inside(tri[0]) and surf.inside(tri[1]) and surf.inside(tri[2])):
				continue
			if surf.ground.water_at(c.x, c.y) > 0.0:
				continue
			var in_hole := false
			for h in holes:
				if h is PackedVector2Array and Geometry2D.is_point_in_polygon(c, h):
					in_hole = true
					break
			if not in_hole:
				eligible.append_array(tri)
	if eligible.is_empty():
		return
	b.pad()
	var attr := Color(0.0, 0.0, 0.0, 1.0)
	var w2 := Vector2(0.0, layer)
	var weld := {}
	if surf.native != null and surf.native.has_method("area") \
			and (surf.native_shore or not surf.near_shore(eligible, 0.0)):
		b.append(surf.native.area(eligible, lift, attr, layer, m2u, b.verts.size()))
	else:
		for t in range(0, eligible.size(), 3):
			RoadDrape.tri(b, surf, lift, attr, w2, weld, eligible.slice(t, t + 3), m2u)

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
	if finish.begins_with("crossing"):
		return CROSSING_LAYER + float(step) * 0.11  # above every carriageway
	return 1.0 + float(rank) * 2.0 + (1.0 if finish == "asphalt" else 0.0) + float(step) * 0.11

## Lift above the surface (m) for a depth layer.
static func lift_for_layer(layer: float) -> float:
	return lerpf(LIFT_MIN_M, LIFT_MAX_M, clampf((layer - 1.0) / (LIFT_TOP_LAYER - 1.0), 0.0, 1.0))

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

## The rows of a crossing band or stop line: every BAND_ROW_M. The
## ground a ribbon is laid on swells between its grid posts on a steep,
## twisted cell, and only a ribbon with rows on the swell rides it; a
## band left with a row at each end cut under the street it crosses, and
## the street hid its stripes (Lombard Street's brow at Hyde).
static func band_rows(pts: PackedVector2Array, m2u: float) -> PackedVector2Array:
	return _resample(pts, BAND_ROW_M * m2u)

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
	if surf.native != null and (surf.native_shore or not surf.near_shore(pts, half)):
		var jf := PackedFloat64Array()
		for p in pts:
			jf.append(RoadSurface.junction_frac(junc, p) if not junc.is_empty() else 1.0)
		b.append(surf.native.ribbon(pts, width, lift, attr, jf, layer, m2u, b.verts.size()))
		return
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
## (a bank sloping across the way), lifted like a ribbon. Without
## `arch` a deck over land alone runs straight from bank to bank: a
## railway's track does not hump over every bridge way it is mapped in.
static func deck_profile(pts: PackedVector2Array, surf: _Surface, m2u: float,
		half: float = 0.0, layer: int = 0, arch: bool = true) -> PackedFloat32Array:
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
	if not arch and _land_bridge(pts, surf):
		rise = 0.0
	# Lift over the arch where the slab would touch the water, eased out
	# at RAMP_GRADE both ways so it reads as a ramp, not a step.
	var lift := PackedFloat32Array()
	for i in n:
		var t := dist[i] / total
		var arched := lerpf(h0, h1, t) + 0.05 * m2u + rise * sin(PI * t)
		deck.append(arched)
		lift.append(maxf(_deck_floor(pts, i, surf, slab, half) + 0.05 * m2u - arched, 0.0))
	for i in range(1, n):
		lift[i] = maxf(lift[i], lift[i - 1] - RAMP_GRADE * (dist[i] - dist[i - 1]))
	for i in range(n - 2, -1, -1):
		lift[i] = maxf(lift[i], lift[i + 1] - RAMP_GRADE * (dist[i + 1] - dist[i]))
	for i in n:
		deck[i] += lift[i]
	# A mapped elevated way over land is a viaduct, not a ground ribbon.
	# A mostly-water crossing keeps its bank-to-bank water profile.
	# It climbs from the ground at both ends at a ramp grade (steeper
	# for a path, which takes steps) up to the layer's clearance, so a
	# short bridge peaks lower instead of hovering flat at both ends.
	if layer > 0 and RoadBridgeDecks.mostly_land(pts, surf):
		var grade := PATH_RAMP_GRADE if half * 2.0 <= PATH_WIDTH_M * m2u else RAMP_GRADE
		# An end that joins another bridge way is a joint in mid-air, not a
		# bank: the deck stays up there. Ramped to the ground at every joint,
		# a viaduct mapped in pieces rose and fell piece by piece.
		var up := float(layer) * 5.0 * m2u
		var joint0 := surf.bridge_joint(pts[0], (pts[0] - pts[1]).normalized())
		var joint1 := surf.bridge_joint(pts[n - 1], (pts[n - 1] - pts[n - 2]).normalized())
		var end0 := surf.height(pts[0].x, pts[0].y) + up if joint0 else deck[0]
		var end1 := surf.height(pts[n - 1].x, pts[n - 1].y) + up if joint1 else deck[n - 1]
		# An end on a landmark roof starts there, joint or not: the
		# mapped park/concourse network leaves the roof at its edge.
		var roof0 := surf.landmark_roof_y(pts[0])
		var roof1 := surf.landmark_roof_y(pts[n - 1])
		if roof0 > -INF:
			end0 = roof0
		if roof1 > -INF:
			end1 = roof1
		for i in n:
			var ramp := minf(INF if joint0 and roof0 <= -INF else end0 + grade * dist[i],
				INF if joint1 and roof1 <= -INF else end1 + grade * (total - dist[i]))
			var high := _deck_floor(pts, i, surf, 0.0, half) + up
			var roof_y := surf.landmark_roof_y(pts[i])
			if roof_y > -INF:
				high = roof_y + 0.05 * m2u
			deck[i] = maxf(deck[i], minf(high, ramp))
		deck[0] = maxf(deck[0], end0)
		deck[n - 1] = maxf(deck[n - 1], end1)
		_straighten_deck(deck, dist)
	return deck

## Raises `deck` to the straight lines over its high points (its upper
## hull along `dist`): a deck is a girder, and one that followed every
## rise and hollow of the ground under it was a wavy ribbon on piers.
static func _straighten_deck(deck: PackedFloat32Array, dist: PackedFloat32Array) -> void:
	var hull := PackedInt32Array()
	for i in deck.size():
		while hull.size() >= 2:
			var a := hull[hull.size() - 2]
			var b := hull[hull.size() - 1]
			# Drop b when it lies on or under the line a-i.
			if (deck[b] - deck[a]) * (dist[i] - dist[a]) <= (deck[i] - deck[a]) * (dist[b] - dist[a]):
				hull.remove_at(hull.size() - 1)
			else:
				break
		hull.append(i)
	for k in hull.size() - 1:
		var a := hull[k]
		var b := hull[k + 1]
		for i in range(a + 1, b):
			deck[i] = lerpf(deck[a], deck[b], (dist[i] - dist[a]) / maxf(dist[b] - dist[a], 0.00001))

static func _land_bridge(pts: PackedVector2Array, surf: _Surface) -> bool:
	for p in pts:
		if surf.ground.water_at(p.x, p.y) > 0.0:
			return false
	return true

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
## with slab fascias on both sides and parapets; the deck top goes to
## the `top_finish` batch (RailBuilder lays ballast there). `fit` is a
## deck among others (RailBuilder): "open" names the edges with no
## parapet, a byte per segment for the left and for the right side
## (another deck runs alongside there); "deck" gives the heights in
## place of the profile, "low" the fascias' foot under them, "side" the
## batch the fascias, parapets and underside go to (default "deck") and
## "metric_v" a fascia texture tiled by its height in metres.
static func _bridge(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: _Surface, m2u: float, top_finish: String = "bridge", structure: String = "unknown", layer: int = 0,
		fit: Dictionary = {}) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	pts = inside
	var n := pts.size()
	var deck: PackedFloat32Array = fit.get("deck", PackedFloat32Array())
	if deck.size() != n:
		deck = deck_profile(pts, surf, m2u, width * 0.5, layer)
	if deck.is_empty():
		return
	var open: Array = fit.get("open", [])
	var low: PackedFloat32Array = fit.get("low", PackedFloat32Array())
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		dist.append(dist[i - 1] + pts[i].distance_to(pts[i - 1]))
	var top := _batch(batches, top_finish)
	var side := _batch(batches, str(fit.get("side", "deck")))
	var metric := bool(fit.get("metric_v", false))
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
			var foot_a := low[i] if low.size() == n else deck[i] - depth
			var foot_b := low[i + 1] if low.size() == n else deck[i + 1] - depth
			if not open.is_empty() and (open[0 if sgn > 0.0 else 1] as PackedByteArray)[i] != 0:
				# A hair under the deck, so it never shows along a slab laid beside it.
				_wall(side, oa, ob, foot_a, foot_b, deck[i] - 0.02 * m2u, deck[i + 1] - 0.02 * m2u,
					sa.normalized(), metric)
				continue
			_wall(side, oa, ob, foot_a, foot_b, deck[i] + para, deck[i + 1] + para, sa.normalized(), metric)
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
	if layer > 0 and top_finish == "bridge" and RoadBridgeDecks.mostly_land(pts, surf):
		_land_piers(side, pts, dist, deck, surf, m2u)
	# A long crossing stands on piers under arched spandrels.
	if top_finish == "bridge" and structure == "masonry":
		BridgeArches.add(side, pts, dist, deck, half, depth, surf.ground, m2u)

## Simple concrete columns beneath land viaducts, spaced along the
## mapped way. Their tops meet the deck and bottoms follow the terrain.
static func _land_piers(side: _Batch, pts: PackedVector2Array, dist: PackedFloat32Array,
		deck: PackedFloat32Array, surf: _Surface, m2u: float) -> void:
	var next := 15.0 * m2u
	for i in range(1, pts.size() - 1):
		if dist[i] < next:
			continue
		next = dist[i] + 30.0 * m2u
		var p := pts[i]
		if surf.ground.water_at(p.x, p.y) > 0.0:
			continue  # No column stands in the ditch or brook under it.
		var low := surf.height(p.x, p.y) - 0.1 * m2u
		var high := deck[i] - DECK_DEPTH_M * m2u
		if high <= low + 0.2 * m2u:
			continue
		var d := (pts[i + 1] - pts[i - 1]).normalized()
		var n := Vector2(-d.y, d.x)
		var x := d * 1.25 * m2u
		var z := n * 1.25 * m2u
		var corners := [p - x - z, p + x - z, p + x + z, p - x + z]
		for k in 4:
			var a: Vector2 = corners[k]
			var b: Vector2 = corners[(k + 1) % 4]
			_wall(side, a, b, low, low, high, high, ((a + b) * 0.5 - p).normalized())

## Vertical quad a→b between bottom (ya0, yb0) and top (ya1, yb1),
## front face toward `out`.
## `metric_v` runs the texture's V in metres of wall height, not once
## over the whole wall.
static func _wall(b: _Batch, a: Vector2, c: Vector2, ya0: float, yc0: float,
		ya1: float, yc1: float, out: Vector2, metric_v: bool = false) -> void:
	var k := b.verts.size()
	b.verts.push_back(Vector3(a.x, ya0, a.y)); b.verts.push_back(Vector3(c.x, yc0, c.y))
	b.verts.push_back(Vector3(c.x, yc1, c.y)); b.verts.push_back(Vector3(a.x, ya1, a.y))
	var n3 := Vector3(out.x, 0.0, out.y)
	for q in 4:
		b.normals.append(n3)
	var len_u := a.distance_to(c)
	var va := maxf(ya1 - ya0, 0.0) if metric_v else 1.0
	var vc := maxf(yc1 - yc0, 0.0) if metric_v else 1.0
	b.uvs.push_back(Vector2(0, va)); b.uvs.push_back(Vector2(len_u, vc))
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

	## Appends RibbonDraper.ribbon's arrays (indices already offset).
	func append(a: Array) -> void:
		verts.append_array(a[0])
		normals.append_array(a[1])
		uvs.append_array(a[2])
		colors.append_array(a[3])
		uv2s.append_array(a[4])
		indices.append_array(a[5])

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
	var districts: Array = []
	var size := 0
	var step := 1.0
	## The preset's terrain mesh (TerrainBuilder._terrain_mesh): coarser
	## than the post grid below Ultra, its posts sampled bilinearly. Its
	## chords sit above GroundTruth in every hollow, so a ribbon draped
	## on the full grid alone vanishes under it in patches.
	var mesh_size := 0
	var mesh_step := 1.0
	## RibbonDraper (native/, tools/build_native.sh) set up on this
	## surface by use_native(), else null: _ribbon lays its ribbons.
	var native: Object = null
	var native_shore := false
	## Ends of bridge ways by node, and how many bridge ways end there.
	var _bridge_ends := {}
	## Non-bridge ways by vertex node ([points, index]): approaches.
	var _way_nodes := {}
	## Bridge way end points: a joint may sit metres off the node.
	var _bridge_end_pts := PackedVector2Array()
	var _bridge_lines: Array = []  ## Bridge polylines (beside-joints).
	var road_bridges: RoadBridgeDecks.Index = null  ## Road bridge ways sharing structures.
	var _pier_lines: Array = []  ## Pier polylines (landings).
	var roof_sites: Array = []  ## Registry landmark roofs (LandmarkRoofs).

	static func _node(p: Vector2) -> Vector2i:
		var m := WorldScale.metres_to_units()
		return Vector2i(roundi(p.x * 100.0 / m), roundi(p.y * 100.0 / m))

	## True where two bridge ways meet (BridgeLandings.joint).
	func bridge_joint(p: Vector2, outward: Vector2 = Vector2.ZERO) -> bool:
		return BridgeLandings.joint(self, p, outward)

	func landmark_roof_y(p: Vector2) -> float:  ## Roof Y covering `p`.
		return LandmarkRoofs.roof_y(roof_sites, p, height)

	## Junction aprons ({cell: [rings]}, RoadMarkings' grid): a footway
	## (and the plain paving of a crossing's stub) stops at their edge, as
	## at a kerb. Laid on into the junction it poked through the apron
	## wherever their two drapes disagree.
	var aprons: Dictionary = {}
	## The same aprons as [ring, bounds]: they are cut out of paved areas.
	var apron_rings: Array = []

	func _init(data: LocationData, g: GroundTruth) -> void:
		ground = g
		for pier in data.piers:
			if pier is Dictionary:
				_pier_lines.append((pier as Dictionary).get("points", PackedVector2Array()))
		road_bridges = RoadBridgeDecks.Index.new(data.roads)
		roof_sites = LandmarkRoofs.collect(data)
		for w: Variant in data.roads + data.railways:
			if not (w is Dictionary):
				continue
			var ends: PackedVector2Array = (w as Dictionary).get("points", PackedVector2Array())
			if ends.size() < 2:
				continue
			if bool((w as Dictionary).get("bridge", false)):
				_bridge_lines.append(ends)
				for e: Vector2 in [ends[0], ends[ends.size() - 1]]:
					_bridge_ends[_node(e)] = int(_bridge_ends.get(_node(e), 0)) + 1
					_bridge_end_pts.append(e)
			elif not bool((w as Dictionary).get("tunnel", false)) \
					and not bool((w as Dictionary).get("area", false)):
				for vi in ends.size():
					var node := _node(ends[vi])
					if not _way_nodes.has(node):
						_way_nodes[node] = []
					(_way_nodes[node] as Array).append([ends, vi])

		var region := CityStyles.region_at(data.latitude, data.longitude)
		districts = CityStyles.local_frame(region, data.latitude, data.longitude).get("districts", [])
		size = data.grid_size
		step = WorldScale.detailed_extent_units() / float(maxi(size - 1, 1))
		mesh_size = mini(RenderSettings.terrain_mesh_posts_for(data.quality_preset), size)
		if ground.shoreline != null and ground.shoreline.ready:
			mesh_size = size
			step = ground._step_units
		mesh_step = WorldScale.detailed_extent_units() / float(maxi(mesh_size - 1, 1))
		if ground.shoreline != null and ground.shoreline.ready:
			mesh_step = step

	func use_native() -> void:
		if ClassDB.class_exists("RibbonDraper"):
			native = ClassDB.instantiate("RibbonDraper")
			native.setup(ground._surface, ground._size, ground._step_units, ground.water_level_m,
				size, step, mesh_size, mesh_step)
			if ground.shoreline != null and ground.shoreline.ready and ground.shoreline.sampler != null \
					and native.has_method("set_shore_sampler"):
				native.set_shore_sampler(ground.shoreline.sampler)
				native_shore = true

	func near_shore(points: PackedVector2Array, radius: float) -> bool:
		if ground.shoreline == null or not ground.shoreline.ready:
			return false
		var model: ShorelineModel = ground.shoreline
		for p in points:
			var lo := model.cell_at(p - Vector2.ONE * radius)
			var hi := model.cell_at(p + Vector2.ONE * radius)
			for x in range(lo.x, hi.x + 1):
				for z in range(lo.y, hi.y + 1):
					if model.patches.has(Vector2i(x, z)):
						return true
		return false

	## True inside the drawn mesh, EDGE_M clear of its edge.
	func inside(p: Vector2) -> bool:
		var lo := -float(mesh_size) * 0.5 * mesh_step + EDGE_M
		var hi := (float(mesh_size) * 0.5 - 1.0) * mesh_step - EDGE_M
		return p.x >= lo and p.x <= hi and p.y >= lo and p.y <= hi

	func height(x: float, z: float) -> float:
		if ground.shoreline != null and ground.shoreline.ready \
				and ground.shoreline.patches.has(ground.shoreline.cell_at(Vector2(x, z))):
			return ground.height_at_world(x, z)
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
