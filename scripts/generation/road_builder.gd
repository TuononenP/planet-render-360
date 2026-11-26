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
## A way with a building centre this near (m) is a lit street; a major
## road or a square reaches further (boulevards and plazas stand wide of
## their buildings, and are lit all the same).
const LIT_BUILT_M := 35.0
const LIT_MAJOR_M := 120.0
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
const FINISH_HEX := {"asphalt": "#585552", "paving": "#8e887c",
	"sett": "#8a8478", "gravel": "#9a8c72", "deck": "#a39d92"}
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
## The sett and paving finishes' colours this build: Finnish granite where it applies.
static var _sett_hex: String = FINISH_HEX["sett"]
static var _paving_hex: String = FINISH_HEX["paving"]
static var _gravel_hex: String = FINISH_HEX["gravel"]
## The PBR set the gravel finish is laid with: Finland's is real gravel grain.
static var _gravel_set: String = "pavement"
## The bridges' concrete where the place's bridges are stone (else null).
static var _stone_deck: Material = null

## Roads subtree: draped ribbons on the ground, bridge decks over water.
## `abort` stops it between rows / items; a stopped result is dropped.
static func build_roads(data: LocationData, ground: GroundTruth = null, abort: BuildAbort = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	RoadSurface.set_place(data)
	var root := Node3D.new()
	root.name = "Roads"
	var timings := {}
	var t := Time.get_ticks_msec()
	_roads(root, data, ground, abort)
	t = StreetProps._lap(timings, "roads", t)
	RoadDecals.build(root, data, ground)
	t = StreetProps._lap(timings, "decals", t)
	KerbBuilder.build(root, data, ground)
	t = StreetProps._lap(timings, "kerbs", t)
	RailBuilder.build(root, data, ground, abort)
	t = StreetProps._lap(timings, "rails", t)
	print("ROADS timings ms ", timings)
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
	# A concrete footway or square is pale slabs, not a road's tarmac:
	# Gwanghwamun's forecourt read as a dark apron round the Woldae.
	if surface == "concrete" and cls in ["footway", "path", "pedestrian", "steps", "corridor"]:
		return "paving"
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

## In historic districts, an unmapped surface defaults to local setts, and
## an unsurfaced footway through a Finnish park (`parks`) to gravel;
## mapped surfaces, crossings and bridges always retain their own finish.
static func _district_finish(road: Dictionary, districts: Array, m2u: float, parks: Array = []) -> String:
	var cls := str(road.get("class", "unclassified"))
	var finish := "crossing" if bool(road.get("crossing", false)) else _finish(cls, str(road.get("surface", "")).to_lower())
	if ArchitectureParis.park_way(road, parks) and _gravel_hex == ArchitectureParis.PARK_GRAVEL_HEX:
		return "gravel"
	if str(road.get("surface", "")) != "" or bool(road.get("crossing", false)) or bool(road.get("bridge", false)):
		return finish
	if FinnishGranite.park_way(road, parks):
		return "gravel"
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
	if line is Dictionary and not (surf.districts.is_empty() and surf.parks.is_empty()):
		return _district_finish(line, surf.districts, m2u, surf.parks)
	return str(r["finish"])

static func _material(finish: String) -> Material:
	if _mats.has(finish):
		return _mats[finish] as Material
	var m: Material
	match finish:
		"paving", "sett", "gravel":
			# Setts and gravel carry traffic; footway paving does not.
			m = RoadSurface.paved_material(_gravel_set if finish == "gravel" else "pavement",
				Color.html(_sett_hex if finish == "sett" else (_paving_hex if finish == "paving" else _gravel_hex)).srgb_to_linear(),
				0.0 if finish == "paving" else (1.0 if finish == "sett" else 0.6), true, finish == "sett",
				finish != "gravel")
		"deck":
			# A Paris bridge is stone: its fascias in the quay walls' limestone
			# (board-formed concrete read as tan wooden planks beside them).
			m = _stone_deck if _stone_deck != null else _pbr("concrete", FINISH_HEX["deck"])
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

## Most open water under a mapped deck going on from a registry bridge's
## end that is still laid as road on its abutment, metres.
const LANDING_WET_M := 8.0

static func _roads(root: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort = null) -> void:
	var sub := {}
	var t0 := Time.get_ticks_msec()
	_mats.clear()
	var granite := FinnishGranite.applies(data)
	_sett_hex = FinnishGranite.SETT_HEX if granite else FINISH_HEX["sett"]
	_paving_hex = FinnishGranite.PAVING_HEX if granite else FINISH_HEX["paving"]
	_gravel_hex = FinnishGranite.GRAVEL_HEX if granite else FINISH_HEX["gravel"]
	_gravel_set = "gravel" if granite else "pavement"
	if ShoreApron.stockholm(data):
		# Stockholm's quays, squares and walks are grey granite.
		_sett_hex = ShoreApron.STOCKHOLM_SETT.to_html(false)
		_paving_hex = ShoreApron.STOCKHOLM_PAVING.to_html(false)
	elif AmsterdamCanalBridges.applies(data):
		# Amsterdam's historic squares & canal quays: weathered grey-brown Dutch porphyry setts.
		_sett_hex = "#847D75"
		_paving_hex = "#8B847B"
	elif ArchitectureParis.applies(data):
		_sett_hex = ArchitectureParis.SETT_HEX
		_paving_hex = ArchitectureParis.PAVING_HEX
		_gravel_hex = ArchitectureParis.PARK_GRAVEL_HEX
		_gravel_set = "gravel"
	_stone_deck = QuayBuilder.stone_material(data) if QuayBuilder.stone_quays(data) else null
	BridgeArches.stone_arches = QuayBuilder.stone_quays(data)
	var m2u := WorldScale.metres_to_units()
	var surf := _Surface.new(data, ground)
	surf.use_native()
	var plan := RoadMarkings.shared_plan(data, ground)
	var junc := plan.junctions
	if surf.native != null and not junc.is_empty() and surf.native.has_method("set_junctions"):
		surf.native.set_junctions(junc, RoadSurface.JUNCTION_M)
	surf.aprons = RoadMarkings._apron_grid(plan.aprons, m2u)
	for ring: PackedVector2Array in plan.aprons:
		surf.apron_rings.append([ring, RingGeometry.aabb(ring)])
	var steps := RoadSurface.depth_steps(data)
	var seeds := RoadSurface.wear_seeds(data)
	surf.wear_seeds = seeds
	surf.built = OverheadWires._centre_grid(data, LIT_BUILT_M * m2u)
	surf.built_major = OverheadWires._centre_grid(data, LIT_MAJOR_M * m2u)
	surf.ground_roads = StreetProps._road_grid(data, m2u, true)
	for w: Variant in data.roads:
		if w is Dictionary and bool((w as Dictionary).get("area", false)) and str((w as Dictionary).get("class", "")) == "pedestrian" \
				and int((w as Dictionary).get("layer", 0)) == 0:
			var ring: PackedVector2Array = (w as Dictionary).get("points", PackedVector2Array())
			if ring.size() >= 3:
				surf.squares.append([ring, RingGeometry.aabb(ring), (w as Dictionary).get("holes", [])])
	# A registry bridge's model carries its own deck over its span.
	var spans := LandmarkSites.bridge_spans(data)
	# Bridge structures are levelled once, before the chunks read them.
	surf.road_bridges.structures.exclude_spans(spans, surf.road_bridges, m2u)
	surf.road_bridges.structures.prepare(surf, m2u)
	# Fixed chunks of the road list, built at once and joined in order:
	# the same mesh whichever threads ran them.
	var n := data.roads.size()
	var parts: Array = []
	parts.resize(CHUNKS)
	# Flights of steps the ground was held to are drawn as stairs, not ribbons;
	# riverbank/quay-edge steps are omitted altogether.
	var stairs := StairBuilder.skipped_roads(ground)
	for ri: int in surf.skipped_bridges:
		stairs[ri] = true
	if ground.shoreline != null and not ground.shoreline.empty():
		var wall_segs := StepsGround._riverside_walls(data, ground.shoreline, m2u)
		for i in n:
			if stairs.has(i):
				continue
			var r_item: Variant = data.roads[i]
			if r_item is Dictionary and str((r_item as Dictionary).get("class", "")) == "steps" \
					and not bool((r_item as Dictionary).get("bridge", false)):
				var s_pts: PackedVector2Array = (r_item as Dictionary).get("points", PackedVector2Array())
				var s_area := bool((r_item as Dictionary).get("area", false))
				if StepsGround.near_shore(s_pts, ground.shoreline, m2u, s_area) \
						or StepsGround._near_wall(s_pts, wall_segs, StepsGround.WALL_STEP_MARGIN_M * m2u, s_area):
					stairs[i] = true
	t0 = StreetProps._lap(sub, "setup", t0)
	var job := func(c: int) -> void:
		var own := {}
		for i in range(n * c / CHUNKS, n * (c + 1) / CHUNKS):
			if abort != null and abort.requested:
				break
			if stairs.has(i):
				continue
			_road(own, data.roads[i], steps[i], m2u, surf, ground, junc, spans, abort, plan.by_road.get(i, {}), seeds[i])
		parts[c] = own
	var group := WorkerThreadPool.add_group_task(job, CHUNKS, -1, false, "Roads")
	WorkerThreadPool.wait_for_group_task_completion(group)
	t0 = StreetProps._lap(sub, "chunks", t0)
	var batches := {}
	for own in parts:
		for finish in own:
			_batch(batches, finish).join(own[finish])
	t0 = StreetProps._lap(sub, "join", t0)
	RoadTapers.lay(batches, data, surf, m2u)
	t0 = StreetProps._lap(sub, "tapers", t0)
	BridgeStructures.build(batches, surf, m2u)
	t0 = StreetProps._lap(sub, "bridges", t0)
	RoadMarkings.lay(plan, batches, surf, m2u, data)
	t0 = StreetProps._lap(sub, "markings", t0)
	RoadPaint.lay(batches, data, surf, plan, seeds, m2u)
	t0 = StreetProps._lap(sub, "paint", t0)
	RoadGlyphs.lay(batches, data, surf, m2u, plan)
	t0 = StreetProps._lap(sub, "glyphs", t0)
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
	t0 = StreetProps._lap(sub, "commit", t0)
	StairBuilder.lay(root, data, ground, surf, m2u)
	BangkokCanalBridges.build(root, data, ground, surf, m2u)
	AmsterdamCanalBridges.build(root, data, ground, surf, m2u)
	t0 = StreetProps._lap(sub, "stairs", t0)
	surf.release()
	print("ROADS sub ms ", sub)

## Paths a pedestrian square paves over (not steps, crossings, bridges,
## tunnels or a piece already clipped).
const SQUARE_PATHS := ["footway", "path", "pedestrian"]

static func _in_square_class(line: Variant) -> bool:
	if not (line is Dictionary):
		return false
	var d: Dictionary = line
	return str(d.get("class", "")) in SQUARE_PATHS and not bool(d.get("area", false)) \
		and not bool(d.get("crossing", false)) and not bool(d.get("bridge", false)) \
		and not bool(d.get("tunnel", false)) and not bool(d.get("square_clipped", false))

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
	if marking.is_empty() and _in_square_class(line) and not surf.squares.is_empty():
		# A footway mapped across a pedestrian square is its walking route:
		# the square's own paving shows there, the ribbon only outside it.
		var rpts: PackedVector2Array = r["points"]
		if rpts.size() >= 2 and surf.intersects_square(RingGeometry.aabb(rpts)):
			var outside := RoadCrossingClip._runs(rpts, m2u, func(p: Vector2) -> bool:
				return not surf.in_square(p))
			if outside.size() != 1 or (outside[0] as PackedVector2Array).size() != rpts.size():
				for piece: PackedVector2Array in outside:
					var part: Dictionary = (line as Dictionary).duplicate()
					part["points"] = piece
					part["square_clipped"] = true
					_road(batches, part, step, m2u, surf, ground, junc, spans, abort, {}, wear_seed)
				return
	if not marking.is_empty():
		r["finish"] = marking["finish"]
		r["width_u"] = float(marking["width_m"]) * m2u
	var pts: PackedVector2Array = r["points"]
	if pts.size() < 2:
		return
	if line is Dictionary and bool((line as Dictionary).get("area", false)):
		var af := str(r["finish"])
		var al := _area_layer(str(r.get("class", "")), af, step)
		_area(_batch(batches, af), pts, (line as Dictionary).get("holes", []),
			surf, _area_lift(al) * m2u, m2u, al, _square_axis_rg(pts, str(r.get("class", "")), m2u))
		return
	var dense := _resample(pts, surf.step * 0.34)
	var finish := str(r["finish"])
	if line is Dictionary and not (surf.districts.is_empty() and surf.parks.is_empty()) and marking.is_empty():
		finish = _district_finish(line, surf.districts, m2u, surf.parks)
	var lines: Array = [dense]
	if bool(r["bridge"]):
		lines = []
		for piece: PackedVector2Array in LandmarkSites.outside_spans(dense, spans):
			# A dry piece going on from a registry model's deck end is the
			# road on its abutment: a ribbon on the ground the model's deck
			# is built level with, not a deck of its own ramping up beside it.
			# A few wet metres at the model's end are under its deck's edge.
			if not spans.is_empty() and LandmarkSites.lands_at_span(piece, spans):
				var wet := 0
				for run: PackedVector2Array in _dry_runs(piece, surf):
					wet -= run.size()
				wet += piece.size()
				if float(wet) * surf.step * 0.34 <= LANDING_WET_M * m2u:
					lines.append(piece)
					continue
			RoadBridgeDecks.build(batches, BridgeLandings.landed(piece, dense, surf, m2u), float(r["width_u"]), surf, m2u,
				str(r.get("bridge_structure", "unknown")), int(r.get("layer", 0)), pts, str(r.get("class", "")), r, wear_seed)
		if lines.is_empty():
			return
	var layer := depth_layer(int(r["rank"]), finish, step)
	var lift := (lift_for_layer(layer) + (BAND_LIFT_M if finish.begins_with("crossing") else 0.0)) * m2u
	# RoadSurface attributes: lanes, rank, kerbed urban street + wear seed.
	var mid := dense[dense.size() / 2]
	var urban := int(r["rank"]) >= 1 and ground.land_class_at(mid.x, mid.y) == "urban"
	# Lit as StreetProps lines its streets with lamps: any way among
	# buildings, landuse polygon or not (central Helsinki has none).
	var lit := urban or _lit_way(dense, int(r["rank"]) >= 2, surf, m2u)
	var attr := Color((clampf(float(r["lanes"]), 0.0, 8.0) + (16.0 if int(r.get("oneway", 0)) != 0 else 0.0)) / 32.0, float(r["rank"]) / 2.0,
		RoadSurface.wear_attr(urban, wear_seed, lit), 1.0)
	var runs: Array = []
	for src: PackedVector2Array in lines:
		runs.append_array(_dry_runs(src, surf))
	for run in runs:
		if abort != null and abort.requested:
			break
		var pieces: Array = [run]
		if int(r["rank"]) == 0 and not finish.begins_with("crossing") and not surf.aprons.is_empty():
			pieces = RoadCrossingClip.off_apron_runs(run, surf.aprons, m2u)
		for piece: PackedVector2Array in pieces:
			var rows: PackedVector2Array = band_rows(piece, m2u) if finish.begins_with("crossing") \
				else (surf.native.straighten(piece, surf.step) if surf.native != null and surf.native.has_method("straighten") \
				else _straighten(piece, surf.step))
			_ribbon(_batch(batches, finish), rows, float(r["width_u"]), surf, lift, attr, junc, layer)

## Dominant edge axis of a civic pedestrian square (>= 350 m²), packed
## into COLOR.rg (`0.5 + 0.45 * u`) for RoadSurface's granite bay grid.
static func _square_axis_rg(ring: PackedVector2Array, cls: String, m2u: float) -> Vector2:
	if cls != "pedestrian" or ring.size() < 3 or absf(RingGeometry.signed_area(ring)) < 350.0 * m2u * m2u:
		return Vector2.ZERO
	var best_len := 1.0 * m2u
	var u := Vector2.ZERO
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		var el := e.length()
		if el > best_len:
			best_len = el
			u = e / el
	if u == Vector2.ZERO:
		return Vector2.ZERO
	if u.x < 0.0 or (is_equal_approx(u.x, 0.0) and u.y < 0.0):
		u = -u
	return Vector2(0.5 + 0.45 * u.x, 0.5 + 0.45 * u.y)

## Paved area (a square) filled flat on the drawn terrain: the outer
## ring ear-clipped, triangles over its holes, open water or past the
## drawn mesh dropped, the rest cut and laid like ribbon pieces under
## every ribbon (AREA_LAYER). An outline ribbon only drew its edge.
static func _area(b: _Batch, ring: PackedVector2Array, holes: Array, surf: _Surface,
		lift: float, m2u: float, layer: float = AREA_LAYER, axis_rg: Vector2 = Vector2.ZERO) -> void:
	if ring.size() < 3:
		return
	# A junction's apron comes out of a paved area (a square whose corner
	# reaches into the junction): the carriageway is the apron's, and the
	# square's thin triangles showed through it as pale streaks. Aprons
	# and glyphs are laid through here too, on their own layers.
	var pieces: Array = [ring]
	if layer < 1.0 and not surf.apron_rings.is_empty():
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
			var shore_ready: bool = surf.ground.shoreline != null and bool(surf.ground.shoreline.ready)
			if surf.ground.water_at(c.x, c.y) > 0.0:
				if not shore_ready or (surf.ground.water_at(tri[0].x, tri[0].y) > 0.0
						and surf.ground.water_at(tri[1].x, tri[1].y) > 0.0
						and surf.ground.water_at(tri[2].x, tri[2].y) > 0.0):
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
	var attr := Color(axis_rg.x, axis_rg.y, RoadSurface.wear_attr(false, 0.0, _lit_ring(ring, surf, m2u)), 1.0)
	var w2 := Vector2(0.0, layer)
	var weld := {}
	if surf.native != null and surf.native.has_method("area") \
			and (surf.native_shore or not surf.near_shore(eligible, 0.0)):
		b.append(surf.native.area(eligible, lift, attr, layer, m2u, b.verts.size()))
	else:
		for t in range(0, eligible.size(), 3):
			RoadDrape.tri(b, surf, lift, attr, w2, weld, eligible.slice(t, t + 3), m2u)

## A square or junction apron with a building near its outline is lit by
## the street lamps around it (StreetGlow).
static func _lit_ring(ring: PackedVector2Array, surf: _Surface, m2u: float) -> bool:
	return _lit_way(ring, true, surf, m2u)

## True when a building stands near any of up to 8 points along `pts`
## (LIT_MAJOR_M for a major road or square, else LIT_BUILT_M): a long
## way's midpoint alone can sit wide of every building beside it.
static func _lit_way(pts: PackedVector2Array, major: bool, surf: _Surface, m2u: float) -> bool:
	var grid: Dictionary = surf.built_major if major else surf.built
	var radius := (LIT_MAJOR_M if major else LIT_BUILT_M) * m2u
	var stride := maxi(1, pts.size() / 8)
	for i in range(0, pts.size(), stride):
		if OverheadWires._built(pts[i], grid, radius):
			return true
	return false

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

## Depth layer and lift for a paved area (stays strictly below every ribbon
## at layer >= 1.0 / LIFT_MIN_M, while parking/asphalt areas sit cleanly
## above enclosing pedestrian squares and overlapping areas never tie).
static func _area_layer(cls: String, finish: String, step: int) -> float:
	return AREA_LAYER + (0.25 if cls == "parking" or finish == "asphalt" else 0.0) \
		+ float(step % RoadSurface.DEPTH_STEPS) * 0.025

static func _area_lift(layer: float) -> float:
	return lerpf(AREA_LIFT_M, LIFT_MIN_M - 0.002, clampf((layer - AREA_LAYER) / (1.0 - AREA_LAYER), 0.0, 1.0))

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
	if surf.native != null and surf.native.has_method("dry_runs"):
		return surf.native.dry_runs(pts, 0.0)
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
		if surf.native.has_method("ribbon_junc"):
			b.append(surf.native.ribbon_junc(pts, width, lift, attr, not junc.is_empty(), layer, m2u, b.verts.size()))
			return
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

## Deck heights along a bridge polyline (RoadBridgeBuild.deck_profile).
static func deck_profile(pts: PackedVector2Array, surf: _Surface, m2u: float,
		half: float = 0.0, layer: int = 0, arch: bool = true) -> PackedFloat32Array:
	return RoadBridgeBuild.deck_profile(pts, surf, m2u, half, layer, arch)

## Lowest deck height at point i (RoadBridgeBuild._deck_floor).
static func _deck_floor(pts: PackedVector2Array, i: int, surf: _Surface, slab: float,
		half: float) -> float:
	return RoadBridgeBuild._deck_floor(pts, i, surf, slab, half)

## Bridge deck on a mapped bridge way (RoadBridgeBuild._bridge).
static func _bridge(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: _Surface, m2u: float, top_finish: String = "bridge", structure: String = "unknown", layer: int = 0,
		fit: Dictionary = {}) -> void:
	RoadBridgeBuild._bridge(batches, pts, width, surf, m2u, top_finish, structure, layer, fit)

## Piers under a land viaduct (RoadBridgeBuild._land_piers).
static func _land_piers(side: _Batch, pts: PackedVector2Array, dist: PackedFloat32Array,
		deck: PackedFloat32Array, surf: _Surface, m2u: float) -> void:
	RoadBridgeBuild._land_piers(side, pts, dist, deck, surf, m2u)

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

## Rendered ground surface sampler (extracted to RoadSurfaceSampler to keep
## RoadBuilder well under the 1000-line class limit).
class _Surface extends RoadSurfaceSampler:
	func _init(data: LocationData, g: GroundTruth) -> void:
		super(data, g)
