class_name BuildingBuilder
extends RefCounted

## Real OSM building extrusions plus absence-only infill and the
## real-data far city (FarCityBuilder, T5.4). Split out of TerrainBuilder in T1.1c
## with identical (v1) outputs; TerrainBuilder.build_world calls
## build_buildings and adopts the children flat (see _adopt_flat).
## Contract: docs/world-model-contract.md §4. True footprints landed in
## T4.1 (_extrude_polygon: walls + roof cap from the real OSM ring, AABB
## only as the logged corrupt-geometry fallback); the ground parameter
## landed with GroundTruth in T1.4 (the mats parameter lands with its C
## owner later). T4.2: real heights (tag → levels × regional floor →
## neighbour estimate → documented regional default, never a global
## 10 m) and roof forms from roof:shape + roof:height (flat/gabled/
## hipped/mansard/pyramidal/dome); mansard only where tagged or
## Haussmann-regional. T4.3: walls/roofs resolve through
## MaterialLibrary (OSM tags → satellite → regional defaults) with
## real-storey window rows; distant blocks share ≤6 materials.
## Style pass: every building gets an ArchitectureStyle look (region from
## the viewpoint's country, kind from the OSM `building` value / use /
## levels / footprint) that fills what the map leaves untagged — wall
## finish and window pattern (tiled per real storey and bay), roof shape
## and finish, floor height and storeys — and BuildingDetail adds the
## kind- and region-specific roofline (chimneys, dormers, rooftop plant,
## steeples). OSM tags and the satellite roof sample always win.
## T4.5: procedural infill is absence-only and style-matched
## (InfillPlanner). T7.3: real buildings past the preset cap are never
## dropped — they extrude as batched low-poly impostor masses with the
## shared distant materials (same footprint and heights on every
## preset). T5.4: the random silhouette ring is gone; FarCityBuilder
## continues the city past the extent from real data (SettlementMap).

## T7.3 batch sink: while set, _walls/_roof_cap/_roof_form append into
## it under _batch_key instead of adding one node per mesh.
static var _batch: MassBatch = null
static var _batch_key := ""
## Shared-wall index of the real buildings while they extrude (null for
## infill and the far city, which never abut mapped parcels).
static var _party: PartyWalls = null
## Native roof forms computed up front (_prepare_roofs), keyed by their
## exact form inputs, and the ring covers that pass computed, by mass key.
static var _roofs: Dictionary = {}
static var _covers: Dictionary = {}
## Last build's census: {real, impostors, infill, far_blocks, far_towers}.
static var last_stats: Dictionary = {}

## Set by WorldBuildGraph, which clears the facade/mass caches itself
## before its tasks start, so no task's cache entries are lost mid-build.
static var _suppress_begin_build := false

## Buildings subtree: real OSM extrusions (+ impostors past the cap),
## absence-only infill, and the real-data far city.
static func build_buildings(data: LocationData, ground: GroundTruth = null,
		abort: BuildAbort = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	if not _suppress_begin_build:
		FacadeMaterials.begin_build()
		BuildingMasses.begin_build()
	last_stats = {"real": 0, "impostors": 0, "infill": 0}
	ShopLights.begin_build()
	var root := Node3D.new()
	root.name = "Buildings"
	var timings := {}
	var t0 := Time.get_ticks_msec()
	var smap := SettlementMap.build(data)
	timings["settlement"] = Time.get_ticks_msec() - t0
	if not data.buildings.is_empty():
		_real_buildings(root, data, ground, abort, timings)
		if abort != null and abort.requested:
			ShopLights.discard()
			return root
	# Absence-only (T4.5): fills only where OSM has no buildings and the
	# imagery / land cover says settlement; 0 in a fully mapped city.
	t0 = Time.get_ticks_msec()
	_buildings(root, data, ground, smap, abort)
	timings["infill"] = Time.get_ticks_msec() - t0
	if abort != null and abort.requested:
		ShopLights.discard()
		return root
	t0 = Time.get_ticks_msec()
	FarCityBuilder.build(root, data, ground, smap)
	timings["far_city"] = Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	ShopLights.add(root)
	if FacadeShader.enabled(data.quality_preset):
		FacadeShader.upgrade(root)
	FacadeTextures.end_build()
	timings["finishing"] = Time.get_ticks_msec() - t0
	print("BUILDINGS timings ms ", timings)
	print("BUILDINGS census %s (settlement=%s)" % [str(last_stats), smap.source])
	return root

static func _buildings(root: Node3D, data: LocationData, ground: GroundTruth,
		smap: SettlementMap = null, abort: BuildAbort = null) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 7
	var ctx := _height_context(data)
	var plan := InfillPlanner.new(data, ground, smap, ctx)
	var m2u := WorldScale.metres_to_units()
	# 2x the preset count, in a 9-98 ring: the foreground roofscape
	# must reach the frame bottom (PRD §4.2), not start past a hole.
	for i in RenderSettings.procedural_buildings_for(data.quality_preset) * 2:
		if abort != null and abort.requested:
			break
		var angle := rng.randf_range(0.0, TAU)
		var dist := 60.0 + pow(rng.randf(), 0.75) * 332.0
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		# Fixed RNG call count per iteration keeps the stream (and so every
		# later building) stable whichever branch skips this one.
		var ra := rng.randf()
		var rb := rng.randf()
		var rs := rng.randf()
		if data.landmark_type != "none" and Vector2(pos.x, pos.z).distance_to(
				TerrainBuilder.landmark_world_pos(data)) < 56.0:
			continue
		if ground.is_built_at(pos.x, pos.z):
			continue
		# T3.4 handoff (T4.1): siting excludes real water via
		# GroundTruth — the deprecated WaterBuilder._river_path stub
		# is no longer called from anywhere.
		if ground.water_at(pos.x, pos.z) > 0.0:
			continue
		var gy := ground.height_at_world(pos.x, pos.z)
		if gy < ground.water_level_m + 0.5:
			continue
		if not plan.allows(pos.x, pos.z):
			continue
		# OSM is silent here: the nearest real buildings' kinds and
		# heights (else the region's own mix), sized and rotated per
		# kind, not one box.
		var style := plan.style(pos.x, pos.z, rs)
		var kind := str(style["kind"])
		var size_u := ArchitectureStyle.infill_size_m(kind, ra, rb) * m2u
		var yaw := floorf(rs * 977.0) * PI / 2.0 + (ra - 0.5) * 0.3
		var b := {"kind": kind}
		var look := ArchitectureStyle.resolve(b, str(ctx["region"]),
			str(ctx["density"]), rs, size_u.x * size_u.y / (m2u * m2u))
		var ring := _rect_ring(Vector2(pos.x, pos.z), size_u, yaw)
		var matched := float(style["total_m"]) > 0.0
		var total_m := float(style["total_m"]) if matched else float(look["default_h"])
		var shape := str(look["roof_shape"])
		var rh_m := minf(_roof_height_m(shape, minf(size_u.x, size_u.y) / m2u, 0.0,
			float(look["pitch"])), maxf(total_m - 0.5, 0.0))
		_extrude_polygon(root, data, ground, ring, (total_m - rh_m) * m2u,
			Vector2(pos.x, pos.z), shape, rh_m * m2u, b, ctx,
			maxi(1, roundi(total_m / float(look["floor_h"]))) if matched \
				else int(look["storeys"]), look)
		last_stats["infill"] = int(last_stats.get("infill", 0)) + 1

## Rotated rectangle footprint (internal units) for procedural masses.
static func _real_buildings(root: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort,
		timings: Dictionary) -> void:
	var t0 := Time.get_ticks_msec()
	var sorted := data.buildings.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (float(a["x"]) ** 2 + float(a["z"]) ** 2) \
			< (float(b["x"]) ** 2 + float(b["z"]) ** 2))
	var placed := 0
	var aabb_fallbacks := 0
	var impostor := MassBatch.new()
	impostor.meta = {"lod_layer": "Buildings", "lod_impostor": true}
	var cap := RenderSettings.max_buildings_for(data.quality_preset)
	var ctx := _height_context(data)
	ctx["poi_index"] = PoiFacadeIndex.new(data.pois)
	if data.buildings.any(func(b: Dictionary) -> bool: return bool(b.get("suomenlinna", false))):
		ctx["fortress_mesh"] = SuomenlinnaFortress.accumulator()
	ctx["sea_y"] = ground.render_y(WaterBuilder.SEA_LEVEL_M) if WaterBuilder._has_coastline(data) or LandmarkTerrain.has_sea(data) else -INF
	# The landmark's own OSM footprint (e.g. the cathedral as one beige
	# box) must not duplicate the procedural landmark model.
	var site := TerrainBuilder.landmark_site_xz(data)
	# Real footprints out to just inside the detailed extent edge (the
	# v1 ±105 of 110 units, now metres of the 2400 m extent).
	var edge := WorldScale.detailed_extent_units() * 0.5 * 0.98
	# Shared walls between every mass that will stand (same skip rules).
	_party = PartyWalls.build(data, ground, ctx,
		func(b: Dictionary) -> bool:
			return not ShipBuilder.accepts(b) and _accepted(data, b, site, edge) and not _in_open_water(ground, b))
	timings["shared_walls_setup"] = Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	if RoofGeometry._native:
		_prepare_roofs(data, ground, ctx, sorted, site, edge)
	timings["roof_setup"] = Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	for b in sorted:
		if abort != null and abort.requested:
			break
		var pos := Vector3(float(b["x"]), 0, float(b["z"]))
		if not _accepted(data, b, site, edge) or _in_open_water(ground, b):
			continue
		if ShipBuilder.build(root, b, data, ground):
			placed += 1
			continue
		if placed >= cap and not bool(b.get("mapped_landmark", false)):
			# T7.3: past the preset cap a real building is never dropped:
			# the same footprint/height/roof resolve, extruded as a
			# batched impostor mass (shared distant materials, no ground
			# storey or roofline detail) merged per LodRing cell.
			_batch = impostor
			_batch_key = "%d,%d" % [floori(pos.x / LodRing.MERGE_CELL_M),
				floori(pos.z / LodRing.MERGE_CELL_M)]
			var ok := _extrude_masses(root, data, ground, b, ctx)
			_batch = null
			if ok:
				last_stats["impostors"] = int(last_stats["impostors"]) + 1
				continue
		if not _extrude_masses(root, data, ground, b, ctx):
			# Corrupt-geometry fallback (contract §7 V14): the AABB
			# keys stay only for footprints that cannot be extruded.
			aabb_fallbacks += 1
			# Its AABB as a rectangle footprint first, so it still gets
			# tiled storeys, a roof form and roofline detail.
			if _extrude_masses(root, data, ground, _aabb_footprint(b), ctx):
				placed += 1
				continue
			var fallback_ring := _rect_ring(Vector2(pos.x, pos.z), Vector2(b["size_x"], b["size_z"]), 0.0)
			var footing := BuildingFoundation.sample(ground, fallback_ring, Vector2(pos.x, pos.z), float(ctx["sea_y"]))
			pos.y = float(footing["floor"]) - (0.0 if bool(footing["raised"]) else 0.6)
			BuildingFoundation.build(root, fallback_ring, [], footing, b)
			var look := _look_for(b, ctx)
			var res := _resolve_total(b, b, ctx, {}, look)
			var legacy: bool = not (b as Dictionary).has("height_source")
			var shape := _effective_shape(str(b.get("roof_shape", "")),
				str(look["roof_shape"]), legacy)
			var span_m := minf(float(b["size_x"]), float(b["size_z"])) \
				/ WorldScale.metres_to_units()
			var rh_m := _roof_height_m(shape, span_m,
				float(b.get("roof_height_m", 0.0)), float(look["pitch"]))
			# As BuildingMasses.plan: tagged levels are the storeys under the
			# roof, which stands on top; other totals include the roof.
			var wall_m := float(res["total_m"])
			if str(res["source"]) != "levels" or legacy:
				rh_m = minf(rh_m, maxf(wall_m - 0.5, 0.0))
				wall_m -= rh_m
			var wall_w := wall_m * WorldScale.metres_to_units()
			if legacy:
				wall_w = clampf(wall_w, 7.2, 76.0)
			LegacyBoxBuilder.building(root, pos, float(b["size_x"]), float(b["size_z"]),
				wall_w, TerrainBuilder._hash(pos.x, pos.z), data, shape,
				rh_m * WorldScale.metres_to_units(), b)
		placed += 1
	timings["mapped"] = Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	last_stats["real"] = placed
	_party = null
	_roofs.clear()
	_covers.clear()
	BuildingMasses.end_build()
	impostor.commit(root, "Impostor")
	if ctx.has("fortress_mesh"):
		SuomenlinnaFortress.add_walls(ctx["fortress_mesh"], data, ground)
		SuomenlinnaFortress.finish(ctx["fortress_mesh"], root, data.quality_preset)
	timings["batching"] = Time.get_ticks_msec() - t0
	if aabb_fallbacks > 0:
		push_warning("BuildingBuilder: %d of %d real buildings used the AABB fallback (missing/corrupt footprint, extruded as a rectangle)."
			% [aabb_fallbacks, placed])

## A building's planned masses (BuildingMasses: parts or the footprint,
## heights, roof) extruded; false routes to the logged AABB fallback.
static func _extrude_masses(root: Node3D, data: LocationData,
		ground: GroundTruth, b: Dictionary, ctx: Dictionary) -> bool:
	# One look per building: parts inherit the parent's kind, finish and
	# roof, as they inherit its tags (and one RoofVariety tint).
	var first := root.get_child_count()
	var m2u := WorldScale.metres_to_units()
	var done := false
	var masses := BuildingMasses.plan(b, ctx)
	# The building's paint weight (its main mass's look) and its place's tone
	# feed the vertex tint; a distant building's residual (_extrude_polygon)
	# starts from none.
	var chroma := 0.0
	if not masses.is_empty():
		chroma = float(((masses[0] as Dictionary).get("look", {}) as Dictionary).get("vt", 0.0))
	var tone := float(ctx.get("tone", 0.0))
	ctx["wall_vt"] = Color.WHITE
	ctx["roof_vt"] = Color.WHITE
	if _batch != null:
		_batch.chroma = chroma
		_batch.tone = tone
		_batch.wall_vt = Color.WHITE
		_batch.roof_vt = Color.WHITE
	# Its meshes upload once, tinted (RoofVariety), not twice.
	if _batch == null:
		MeshArrays.hold()
	for m in masses:
		var md := m as Dictionary
		if ctx.has("fortress_mesh") and SuomenlinnaFortress.build_mass(ctx["fortress_mesh"], md, data, ground):
			done = true
			continue
		if RenderQuality.ultra_desktop(data.quality_preset) and NycCrownMaterials.is_civic_fame(b, md):
			var footing := BuildingFoundation.sample(ground, md["ring"], md["centre"], float(ctx.get("sea_y", -INF)))
			NycCrownMaterials.civic_fame(root, md["centre"], float(footing["floor"]) + float(md["min_m"]) * m2u)
			done = true
			continue
		if _extrude_polygon(root, data, ground, md["ring"], float(md["wall_m"]) * m2u,
				md["centre"], str(md["shape"]), float(md["rh_m"]) * m2u, md["b_eff"], ctx,
				int(md["storeys"]), md["look"], bool(md["main"]), md):
			done = true
			if RenderQuality.ultra_desktop(data.quality_preset) and _batch == null \
					and str(b.get("osm_id", "")) in ["way:75363809", "way:278042253", "way:278069587"]:
				var footing := BuildingFoundation.sample(ground, md["ring"], md["centre"], float(ctx.get("sea_y", -INF)))
				NycCrownMaterials.crown_details(root, b, md, float(footing["floor"]))
	if done and _batch == null:
		RoofVariety.tint(root, first, float(b.get("x", 0.0)), float(b.get("z", 0.0)),
			chroma, tone, ctx["wall_vt"], ctx["roof_vt"])
	if _batch == null:
		MeshArrays.release()
	return done

## True for a real building that stands: not the landmark's own footprint
## (the procedural model stands there), not an archetype candidate, and
## inside the detailed extent.
static func _accepted(data: LocationData, b: Dictionary, site: Vector2, edge: float) -> bool:
	var x := float(b["x"])
	var z := float(b["z"])
	if data.landmark_type != "none":
		var entry := LocationData.entry_for_type(data.landmark_type)
		if LandmarkSites.span_dist(Vector2(x, z), site, entry) < LandmarkSites.clear_m(entry):
			return false
	return not _near_landmark_candidate(data, x, z) and absf(x) <= edge and absf(z) <= edge

## A mapped building whose centre and four corner probes all stand in
## water is a polygon mismatch against the canal, not a building in the
## water. Landing-stage canopies (building=roof, use=pier: open roofs on
## posts) would be drawn as walled, windowed houses standing in the canal,
## so they go too. Named buildings, other tagged uses (lighthouses,
## monitoring stations) and boats, bridges, stations and churches are meant
## to sit on or by water.
const WATER_OK_KINDS: Array[String] = ["boat", "houseboat", "boathouse", "bridge",
	"ship", "train_station", "transportation", "church", "cathedral", "chapel"]

static func _in_open_water(ground: GroundTruth, b: Dictionary) -> bool:
	var canopy := str(b.get("kind", "")) == "roof" or str(b.get("use", "")) == "pier"
	if not canopy and (str(b.get("kind", "")) in WATER_OK_KINDS \
			or str(b.get("name", "")) != "" or str(b.get("use", "")) != ""):
		return false
	var x := float(b["x"])
	var z := float(b["z"])
	var hx := float(b.get("size_x", 0.0)) * 0.35
	var hz := float(b.get("size_z", 0.0)) * 0.35
	var probes: Array[Vector2] = [Vector2.ZERO, Vector2(hx, hz), Vector2(-hx, hz),
		Vector2(hx, -hz), Vector2(-hx, -hz)]
	for o in probes:
		if ground.water_at(x + o.x, z + o.y) <= 0.0:
			return false
	return true

## One footprint ring as vertical walls (facade) plus a triangulated
## roof cap: rotation, L/T/concave shapes, and party-wall adjacency
## survive because the ring is meshed as drawn — nothing is re-squared.
## Dry walls sink 0.6 m into the lowest ground. Low waterfront walls
## stand on a supported floor above wave crests. height_world is the WALL height; a
## pitched shape rises roof_h_world above the wall top (T4.2). Returns
## false when the ring cannot be triangulated (the caller falls back
## to AABB).
static func _extrude_polygon(root: Node3D, data: LocationData,
		ground: GroundTruth, ring: PackedVector2Array, height_world: float,
		centre: Vector2, shape: String = "flat", roof_h_world: float = 0.0,
		b: Dictionary = {}, ctx: Dictionary = {}, storeys: int = 0,
		look: Dictionary = {}, with_detail: bool = true, mass: Dictionary = {}) -> bool:
	# Courtyards: the cap triangulates a keyhole ring (no hole support).
	var holes: Array = mass.get("holes", [])
	var cap := RingGeometry.bridge_holes(ring, holes) if not holes.is_empty() else PackedVector2Array()
	var idx := Geometry2D.triangulate_polygon(cap if not holes.is_empty() else ring)
	if not holes.is_empty():
		idx = RingGeometry.drop_hole_triangles(cap, idx, holes)
	if idx.size() < 3:
		return false
	var footing := BuildingFoundation.sample(ground, ring, centre, float(ctx.get("sea_y", -INF)))
	var base := float(footing["floor"])
	# Walls sink 0.6 m below the lowest ground (no floating on slopes);
	# the real height stands above that ground, not above the sunk base.
	var sink := 0.0 if bool(footing["raised"]) else 0.6 * WorldScale.metres_to_units()
	var top := base + height_world
	base -= sink
	if float(mass.get("min_m", 0.0)) > 0.0:
		base += sink + float(mass["min_m"]) * WorldScale.metres_to_units()
	else:
		BuildingFoundation.build(root, ring, holes, footing, b)
	# Party walls: hidden stretches skipped, firewalls above lower
	# neighbours, gables (not slopes) and no cornice on shared edges.
	var cover: Array = []
	var party := PackedByteArray()
	var fire: Material = null
	if _party != null and mass.has("key"):
		cover = _cover_for(ring, str(mass["key"]), true)
		party = PartyWalls.party_flags(cover)
		fire = PartyWalls.firewall(look)
	# T4.3: tags → satellite → regional resolution with real storey
	# rows; past the fidelity radius the ≤6 distant set is shared.
	var region := str(ctx.get("region", "generic"))
	var fidelity := int(ctx.get("fidelity", 2))
	var seed_v := TerrainBuilder._hash(centre.x, centre.y)
	# A mapped landmark keeps full detail at any distance: it is the skyline.
	var distant := _batch != null or (not bool(b.get("mapped_landmark", false)) \
		and centre.length() / WorldScale.metres_to_units() > MaterialLibrary.full_detail_radius_m(fidelity))
	var facade := FacadeMaterials.facade_for_building(b, region, storeys,
		fidelity, distant, seed_v, look)
	# Roof sampling spans the ring's AABB. A distant building reads it too: its
	# roof colour (a residual on the shared roofs) then follows the imagery.
	var hint := Color(0, 0, 0, 0)
	var bb := RingGeometry.aabb(ring)
	hint = MaterialLibrary.sampled_roof_color(data,
		centre.x, centre.y, bb.size.x, bb.size.y,
		Callable(TerrainBuilder, "satellite_uv"))
	var roof_mat := FacadeMaterials.roof_for_building(b, region, shape,
		hint, fidelity, distant, seed_v, look)
	if bool(b.get("mapped_landmark", false)) and not distant:
		roof_mat = HeroLook.roof(b, roof_mat)
	# A distant building keeps its own colour on the shared materials: the
	# residual against them rides in its vertex tint (an impostor's batch, or
	# RoofVariety.tint through the build context).
	if distant and with_detail:
		var wall_vt := FacadeMaterials.wall_residual(facade, b, look, seed_v)
		var roof_vt := FacadeMaterials.roof_residual(roof_mat, b, look, hint)
		if _batch != null:
			_batch.wall_vt = wall_vt
			_batch.roof_vt = roof_vt
		else:
			ctx["wall_vt"] = wall_vt
			ctx["roof_vt"] = roof_vt
	# Tile repeats follow the real storey count, kept within ~30% of the
	# style's floor height so a roof carved out of the total never squashes
	# the windows (a mansard eats most of an attic floor).
	var v_rep := float(maxi(storeys, 1))
	if not look.is_empty():
		var wall_m := height_world / WorldScale.metres_to_units()
		var fh := float(look["floor_h"])
		v_rep = roundf(clampf(v_rep, maxf(1.0, wall_m / (fh * 1.35)),
			maxf(1.0, wall_m / (fh * 0.75))))
	# T4.6: a ground storey of its own (shopfront, signage band, a
	# chalet's rendered base) under the tiled storeys when the look has one.
	var ground_mat: Material = null
	var shop_materials := {}
	# A raised part (min_height) has no street storey of its own.
	var raised := float(mass.get("min_m", 0.0)) > 0.0
	if FacadeMaterials.facade_uv(facade).z > 0.0 and v_rep >= 2.0 and _batch == null and not raised:
		ground_mat = FacadeMaterials.ground_for_building(b, fidelity, distant, look)
		var poi_index: PoiFacadeIndex = ctx.get("poi_index", null)
		if poi_index != null and not distant and fidelity > 1 and not look.is_empty():
			var shops := poi_index.for_ring(ring)
			for edge in shops:
				# A shared look bounds POI materials to the six fascia colours,
				# rather than multiplying them by every building's wall variant.
				var shop_look := {"wall_set": "concrete", "ground": "shop", "bay_m": 3.2,
					"floor_h": 3.3, "ground_colour": PoiFacadeIndex.colour(shops[edge])}
				var shop_mat := FacadeMaterials.ground_for_building({}, fidelity, false, shop_look)
				if shop_mat != null:
					shop_materials[edge] = shop_mat
			if not shop_materials.is_empty() and ground_mat == null:
				ground_mat = facade
	if top - base < 0.05 * WorldScale.metres_to_units():
		pass  # a part that is only roof (a dome on its drum) has no walls
	elif ground_mat != null:
		var m2u := WorldScale.metres_to_units()
		var fh_u := float(look["floor_h"]) * m2u
		var gh_u := fh_u * (1.15 if not shop_materials.is_empty() or str(look.get("ground", "")) in ["shop", "signage"] else 1.0)
		var g_top := minf(base + sink + gh_u,
			top - fh_u * 0.6)
		_walls(root, ring, base, g_top, ground_mat, (g_top - base) / gh_u, cover, fire, false, shop_materials)
		_walls(root, ring, g_top, top, facade, maxf(1.0, v_rep - 1.0), cover, fire)
	else:
		_walls(root, ring, base, top, facade, v_rep, cover, fire)
	for h in holes:
		var hc: Array = _party.ring_cover(h, str(mass["key"]), true) if _party != null else []
		_walls(root, h, base, top, facade, v_rep, hc, fire, true)
	var preset := data.quality_preset if data != null else int(RenderSettings.Preset.HIGH)
	_roof_cap(root, ring, idx, top, roof_mat, BuildingTrim.kind(shape,
		centre.length() / WorldScale.metres_to_units(), BuildingTrim.radius_m(preset)), cap, party)
	var gable_front := str((look.get("relief", {}) as Dictionary).get("gable", "")) != ""
	var roofed := false
	var job := _roof_job(ring, top, height_world, shape, roof_h_world, look, party, holes)
	if not job.is_empty():
		roofed = _roof_form(root, job[0], job[1], job[2], shape, roof_mat, party, gable_front, job[6])
	if not roofed:
		# No pitched roof built (flat, or no form fits): dormers, stacks and
		# gables must not stand on a roof that is not there.
		shape = "flat"
		roof_h_world = 0.0
	if not distant and _batch == null and not look.is_empty() \
			and centre.length() < FacadeRelief.radius_m(preset) * WorldScale.metres_to_units():
		var g_y := base if ground_mat == null else minf(base + sink
			+ float(look["floor_h"]) * WorldScale.metres_to_units()
			* (1.15 if str(look.get("ground", "")) in ["shop", "signage"] else 1.0),
			top - float(look["floor_h"]) * WorldScale.metres_to_units() * 0.6)
		FacadeRelief.add(root, {"ring": ring, "cover": cover, "base": base, "g_top": g_y,
			"top": top, "v_rep": v_rep, "storeys": storeys, "look": look, "facade": facade,
			"seed": seed_v, "party": _party, "b": b, "ground_y": base + sink,
			"roof_h": roof_h_world, "shape": shape, "gable_front": gable_front, "raised": raised,
			"party_flags": party, "screens": RenderQuality.ultra_desktop(preset),
			"wall_lanterns": RenderQuality.ultra_desktop(preset),
			"shop_lights": RenderQuality.ultra_desktop(preset)
				and centre.length() < ShopLights.SHOP_RADIUS_M * WorldScale.metres_to_units()})
	if with_detail and not distant and _batch == null and not look.is_empty():
		var before := root.get_child_count()
		BuildingDetail.add(root, ring, top, height_world, shape, roof_h_world,
			look, facade, roof_mat, seed_v, centre.length() < BuildingDetail.near_radius(preset),
			party, gable_front, RenderQuality.ultra_desktop(preset), data.country if data != null else "")
		# Roofline detail is the near LOD ring (LodRing.DETAIL_M); church
		# towers are skyline and stay in every ring.
		if str(look.get("kind", "")) != "religious":
			for k in range(before, root.get_child_count()):
				root.get_child(k).set_meta("lod_detail", true)
	return true

## Ring without its OSM closing duplicate (the fetcher keeps every
## node), requiring three distinct corners and a non-degenerate area.

# --- Delegators: implementation in BuildingHeights / BuildingWalls. ---
static func _legacy_region(data: LocationData) -> String:
	return BuildingHeights._legacy_region(data)

static func _density(data: LocationData) -> String:
	return BuildingHeights._density(data)

static func _area_m2(b: Dictionary) -> float:
	return BuildingHeights._area_m2(b)

static func _look_for(b: Dictionary, ctx: Dictionary) -> Dictionary:
	return BuildingHeights._look_for(b, ctx)

static func _height_context(data: LocationData) -> Dictionary:
	return BuildingHeights._height_context(data)

static func _resolve_total(m: Dictionary, b: Dictionary, ctx: Dictionary,
		parent_res: Dictionary, look: Dictionary) -> Dictionary:
	return BuildingHeights._resolve_total(m, b, ctx, parent_res, look)

static func _inferred_total(x: float, z: float, ctx: Dictionary,
		look: Dictionary) -> Dictionary:
	return BuildingHeights._inferred_total(x, z, ctx, look)

static func _tagged_within(ctx: Dictionary, x: float, z: float, kind: String) -> Array:
	return BuildingHeights._tagged_within(ctx, x, z, kind)

static func _median(a: Array) -> float:
	return BuildingHeights._median(a)

static func _effective_shape(raw: String, default_roof: String, legacy: bool) -> String:
	return BuildingHeights._effective_shape(raw, default_roof, legacy)

static func _roof_height_m(shape: String, span_m: float, tag_m: float, pitch: float = 1.0) -> float:
	return BuildingHeights._roof_height_m(shape, span_m, tag_m, pitch)

static func _ring_span_m(ring: PackedVector2Array) -> float:
	return BuildingHeights._ring_span_m(ring)

static func _clean_ring(raw: PackedVector2Array) -> PackedVector2Array:
	return BuildingWalls._clean_ring(raw)

static func _walls(root: Node3D, ring: PackedVector2Array, base: float,
		top: float, mat: Material, v_repeat: float = 1.0, cover: Array = [],
		fire: Material = null, invert: bool = false, edge_materials: Dictionary = {}) -> void:
	BuildingWalls._walls(root, ring, base, top, mat, v_repeat, cover, fire, invert, edge_materials)

static func _roof_cap(root: Node3D, ring: PackedVector2Array, idx: PackedInt32Array,
		top: float, mat: Material, trim: int = 0, cap: PackedVector2Array = PackedVector2Array(),
		party: PackedByteArray = PackedByteArray()) -> void:
	BuildingWalls._roof_cap(root, ring, idx, top, mat, trim, cap, party)

static func _roof_form(root: Node3D, ring: PackedVector2Array, top: float,
		rh: float, shape: String, mat: Material, party: PackedByteArray = PackedByteArray(),
		gable_front: bool = false, holes: Array = []) -> bool:
	var key := [ring, top, rh, shape, party, gable_front, holes] if not _roofs.is_empty() else []
	var mesh := RoofGeometry.mesh_of(_roofs[key]) if _roofs.has(key) \
		else RoofGeometry.form_mesh(ring, top, rh, shape, party, gable_front, holes)
	if mesh != null and _batch != null:
		_batch.add_mesh(_batch_key, mat, mesh)
	elif mesh != null:
		TerrainBuilder._add(root, mesh, mat)
	return mesh != null

## Floor under a mass, clearing the visible water for accepted
## waterfront buildings (shrines, boathouses, named pier structures).
## The carved seabed is not their floor datum.
static func _mass_base(ground: GroundTruth, ring: PackedVector2Array, centre: Vector2,
		sea_y: float = -INF) -> float:
	return float(BuildingFoundation.sample(ground, ring, centre, sea_y)["floor"])

## The roof form's inputs [ring, top, rh, shape, party, gable_front,
## holes] for a pitched mass, or [] when it has none. Eave overhang (style
## metres) for gabled/hipped/pyramidal roofs: the eave line drops by the
## roof's own slope so the pitch is kept. A terrace keeps its eaves flush
## (no overhang into the neighbour).
static func _roof_job(ring: PackedVector2Array, top: float, height_world: float,
		shape: String, roof_h_world: float, look: Dictionary, party: PackedByteArray,
		holes: Array) -> Array:
	if shape == "flat" or roof_h_world <= 0.01:
		return []
	var gable_front := str((look.get("relief", {}) as Dictionary).get("gable", "")) != ""
	var eave_u := float(look.get("eave", 0.0)) * WorldScale.metres_to_units()
	if eave_u > 0.0 and shape in ["gabled", "hipped", "pyramidal"] \
			and not party.has(1) and holes.is_empty():
		var half := maxf(_ring_span_m(ring) * WorldScale.metres_to_units() * 0.5, 0.01)
		var drop := minf(eave_u * roof_h_world / half, height_world * 0.25)
		return [RoofGeometry.offset_ring(ring, eave_u), top - drop, roof_h_world + drop,
			shape, party, gable_front, []]
	return [ring, top, roof_h_world, shape, party, gable_front, holes]

## _party.ring_cover, reusing the one _prepare_roofs computed for this
## mass (`take` hands it over: the walls may read it, nothing reuses it).
static func _cover_for(ring: PackedVector2Array, key: String, take: bool = false) -> Array:
	var hit: Array = _covers.get(key, [])
	if not hit.is_empty() and hit[0] == ring:
		if take:
			_covers.erase(key)
		return hit[1]
	var cover := _party.ring_cover(ring, key)
	if not take:
		_covers[key] = [ring, cover]
	return cover

## Every standing mass's roof form, computed up front on every core
## (RoofKernels.form_many) with _extrude_polygon's own inputs: _roof_form
## takes a result only when its call matches it exactly.
static func _prepare_roofs(data: LocationData, ground: GroundTruth, ctx: Dictionary,
		sorted: Array, site: Vector2, edge: float) -> void:
	var m2u := WorldScale.metres_to_units()
	var jobs: Array = []
	for b in sorted:
		if ShipBuilder.accepts(b) or not _accepted(data, b, site, edge) or _in_open_water(ground, b):
			continue
		for m in BuildingMasses.plan(b, ctx):
			var md := m as Dictionary
			if SuomenlinnaSite.fortress(md["b_eff"]):
				continue
			var ring: PackedVector2Array = md["ring"]
			var height_world := float(md["wall_m"]) * m2u
			var party := PackedByteArray()
			if _party != null and md.has("key"):
				party = PartyWalls.party_flags(_cover_for(ring, str(md["key"])))
			var job := _roof_job(ring, _mass_base(ground, ring, md["centre"], float(ctx.get("sea_y", -INF))) + height_world,
				height_world, str(md["shape"]), float(md["rh_m"]) * m2u, md["look"], party,
				md.get("holes", []))
			if not job.is_empty():
				jobs.append(job)
	var res: Array = ClassDB.class_call_static("RoofKernels", "form_many", jobs)
	for i in jobs.size():
		_roofs[jobs[i]] = res[i]

## A mapped landmark candidate clears nothing: its own building is the model.
static func _near_landmark_candidate(data: LocationData, x: float, z: float) -> bool:
	for c in data.landmark_candidates:
		if bool(c.get("mapped", false)):
			continue
		if LandmarkSites.span_dist(Vector2(x, z), Vector2(float(c.get("x", 0.0)), float(c.get("z", 0.0))),
				c) < float(c.get("clear_m", LandmarkSites.OSM_CLEAR_M)):
			return true
	return false

static func _rect_ring(c: Vector2, size: Vector2, yaw: float) -> PackedVector2Array:
	return BuildingWalls._rect_ring(c, size, yaw)

static func _aabb_footprint(b: Dictionary) -> Dictionary:
	return BuildingWalls._aabb_footprint(b)
