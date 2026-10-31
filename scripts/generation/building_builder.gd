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
## Last build's census: {real, impostors, infill, far_blocks, far_towers}.
static var last_stats: Dictionary = {}

## Buildings subtree: real OSM extrusions (+ impostors past the cap),
## absence-only infill, and the real-data far city.
static func build_buildings(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	FacadeMaterials.begin_build()
	BuildingMasses.begin_build()
	last_stats = {"real": 0, "impostors": 0, "infill": 0}
	var root := Node3D.new()
	root.name = "Buildings"
	var smap := SettlementMap.build(data)
	if not data.buildings.is_empty():
		_real_buildings(root, data, ground)
	# Absence-only (T4.5): fills only where OSM has no buildings and the
	# imagery / land cover says settlement; 0 in a fully mapped city.
	_buildings(root, data, ground, smap)
	FarCityBuilder.build(root, data, ground, smap)
	print("BUILDINGS census %s (settlement=%s)" % [str(last_stats), smap.source])
	return root

static func _buildings(root: Node3D, data: LocationData, ground: GroundTruth,
		smap: SettlementMap = null) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 7
	var ctx := _height_context(data)
	var plan := InfillPlanner.new(data, ground, smap, ctx)
	var m2u := WorldScale.metres_to_units()
	# 2x the preset count, in a 9-98 ring: the foreground roofscape
	# must reach the frame bottom (PRD §4.2), not start past a hole.
	for i in RenderSettings.procedural_buildings_for(data.quality_preset) * 2:
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
static func _real_buildings(root: Node3D, data: LocationData, ground: GroundTruth) -> void:
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
	# The landmark's own OSM footprint (e.g. the cathedral as one beige
	# box) must not duplicate the procedural landmark model.
	var site := TerrainBuilder.landmark_site_xz(data)
	# Real footprints out to just inside the detailed extent edge (the
	# v1 ±105 of 110 units, now metres of the 2400 m extent).
	var edge := WorldScale.detailed_extent_units() * 0.5 * 0.98
	# Shared walls between every mass that will stand (same skip rules).
	_party = PartyWalls.build(data, ground, ctx,
		func(b: Dictionary) -> bool: return _accepted(data, b, site, edge))
	for b in sorted:
		var pos := Vector3(float(b["x"]), 0, float(b["z"]))
		if not _accepted(data, b, site, edge):
			continue
		if placed >= cap:
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
			pos.y = ground.height_at_world(pos.x, pos.z) - 0.6
			var look := _look_for(b, ctx)
			var res := _resolve_total(b, b, ctx, {}, look)
			var legacy: bool = not (b as Dictionary).has("height_source")
			var shape := _effective_shape(str(b.get("roof_shape", "")),
				str(look["roof_shape"]), legacy)
			var span_m := minf(float(b["size_x"]), float(b["size_z"])) \
				/ WorldScale.metres_to_units()
			var rh_m := minf(_roof_height_m(shape, span_m,
				float(b.get("roof_height_m", 0.0)), float(look["pitch"])),
				maxf(float(res["total_m"]) - 0.5, 0.0))
			var wall_w := (float(res["total_m"]) - rh_m) * WorldScale.metres_to_units()
			if legacy:
				wall_w = clampf(wall_w, 7.2, 76.0)
			LegacyBoxBuilder.building(root, pos, float(b["size_x"]), float(b["size_z"]),
				wall_w, TerrainBuilder._hash(pos.x, pos.z), data, shape,
				rh_m * WorldScale.metres_to_units(), b)
		placed += 1
	last_stats["real"] = placed
	_party = null
	impostor.commit(root, "Impostor")
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
	for m in BuildingMasses.plan(b, ctx):
		var md := m as Dictionary
		if _extrude_polygon(root, data, ground, md["ring"], float(md["wall_m"]) * m2u,
				md["centre"], str(md["shape"]), float(md["rh_m"]) * m2u, md["b_eff"], ctx,
				int(md["storeys"]), md["look"], bool(md["main"]), md):
			done = true
	if done and _batch == null:
		RoofVariety.tint(root, first, float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	return done

## True for a real building that stands: not the landmark's own footprint
## (the procedural model stands there), not an archetype candidate, and
## inside the detailed extent.
static func _accepted(data: LocationData, b: Dictionary, site: Vector2, edge: float) -> bool:
	var x := float(b["x"])
	var z := float(b["z"])
	if data.landmark_type != "none" and Vector2(x, z).distance_to(site) < 68.0:
		return false
	return not _near_landmark_candidate(data, x, z) and absf(x) <= edge and absf(z) <= edge

## One footprint ring as vertical walls (facade) plus a triangulated
## roof cap: rotation, L/T/concave shapes, and party-wall adjacency
## survive because the ring is meshed as drawn — nothing is re-squared.
## The base is the lowest ground under the ring minus a 0.6 m sink,
## so walls never float on slopes. height_world is the WALL height; a
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
	var base := ground.height_at_world(centre.x, centre.y)
	for p in ring:
		base = minf(base, ground.height_at_world(p.x, p.y))
	# Walls sink 0.6 m below the lowest ground (no floating on slopes);
	# the real height stands above that ground, not above the sunk base.
	var sink := 0.6 * WorldScale.metres_to_units()
	var top := base + height_world
	base -= sink
	if float(mass.get("min_m", 0.0)) > 0.0:
		base += sink + float(mass["min_m"]) * WorldScale.metres_to_units()
	# Party walls: hidden stretches skipped, firewalls above lower
	# neighbours, gables (not slopes) and no cornice on shared edges.
	var cover: Array = []
	var party := PackedByteArray()
	var fire: Material = null
	if _party != null and mass.has("key"):
		cover = _party.ring_cover(ring, str(mass["key"]))
		party = PartyWalls.party_flags(cover)
		fire = PartyWalls.firewall(look)
	# T4.3: tags → satellite → regional resolution with real storey
	# rows; past the fidelity radius the ≤6 distant set is shared.
	var region := str(ctx.get("region", "generic"))
	var fidelity := int(ctx.get("fidelity", 2))
	var seed_v := TerrainBuilder._hash(centre.x, centre.y)
	var distant := _batch != null or centre.length() / WorldScale.metres_to_units() \
		> MaterialLibrary.full_detail_radius_m(fidelity)
	var facade := FacadeMaterials.facade_for_building(b, region, storeys,
		fidelity, distant, seed_v, look)
	# Roof sampling spans the ring's AABB so the mosaic read covers it.
	var bb := RingGeometry.aabb(ring)
	var hint := MaterialLibrary.sampled_roof_color(data,
		centre.x, centre.y, bb.size.x, bb.size.y,
		Callable(TerrainBuilder, "satellite_uv"))
	var roof_mat := FacadeMaterials.roof_for_building(b, region, shape,
		hint, fidelity, distant, seed_v, look)
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
	# A raised part (min_height) has no street storey of its own.
	var raised := float(mass.get("min_m", 0.0)) > 0.0
	if FacadeMaterials.facade_uv(facade).z > 0.0 and v_rep >= 2.0 and _batch == null and not raised:
		ground_mat = FacadeMaterials.ground_for_building(b, fidelity, distant, look)
	if ground_mat != null:
		var m2u := WorldScale.metres_to_units()
		var fh_u := float(look["floor_h"]) * m2u
		var gh_u := fh_u * (1.15 if str(look.get("ground", "")) in ["shop", "signage"] else 1.0)
		var g_top := minf(ground.height_at_world(centre.x, centre.y) + gh_u,
			top - fh_u * 0.6)
		_walls(root, ring, base, g_top, ground_mat, (g_top - base) / gh_u, cover, fire)
		_walls(root, ring, g_top, top, facade, maxf(1.0, v_rep - 1.0), cover, fire)
	else:
		_walls(root, ring, base, top, facade, v_rep, cover, fire)
	for h in holes:
		var hc: Array = _party.ring_cover(h, str(mass["key"]), true) if _party != null else []
		_walls(root, h, base, top, facade, v_rep, hc, fire, true)
	_roof_cap(root, ring, idx, top, roof_mat, BuildingTrim.kind(shape,
		centre.length() / WorldScale.metres_to_units()), cap, party)
	var gable_front := str((look.get("relief", {}) as Dictionary).get("gable", "")) != ""
	if shape != "flat" and roof_h_world > 0.01:
		# Eave overhang (style metres) for gabled/hipped/pyramidal roofs:
		# the eave line drops by the roof's own slope so the pitch is kept.
		# A terrace keeps its eaves flush (no overhang into the neighbour).
		var eave_u := float(look.get("eave", 0.0)) * WorldScale.metres_to_units()
		if eave_u > 0.0 and shape in ["gabled", "hipped", "pyramidal"] \
				and not party.has(1) and holes.is_empty():
			var half := maxf(_ring_span_m(ring) * WorldScale.metres_to_units() * 0.5, 0.01)
			var drop := minf(eave_u * roof_h_world / half, height_world * 0.25)
			_roof_form(root, RoofGeometry.offset_ring(ring, eave_u), top - drop,
				roof_h_world + drop, shape, roof_mat, party, gable_front)
		else:
			_roof_form(root, ring, top, roof_h_world, shape, roof_mat, party, gable_front, holes)
	if not distant and _batch == null and not look.is_empty() \
			and centre.length() < FacadeRelief.RADIUS_M * WorldScale.metres_to_units():
		var g_y := base if ground_mat == null else minf(ground.height_at_world(centre.x, centre.y)
			+ float(look["floor_h"]) * WorldScale.metres_to_units()
			* (1.15 if str(look.get("ground", "")) in ["shop", "signage"] else 1.0),
			top - float(look["floor_h"]) * WorldScale.metres_to_units() * 0.6)
		FacadeRelief.add(root, {"ring": ring, "cover": cover, "base": base, "g_top": g_y,
			"top": top, "v_rep": v_rep, "storeys": storeys, "look": look, "facade": facade,
			"seed": seed_v, "party": _party, "b": b, "ground_y": base + sink,
			"roof_h": roof_h_world, "shape": shape, "gable_front": gable_front, "raised": raised,
			"party_flags": party})
	if with_detail and not distant and _batch == null and not look.is_empty():
		var before := root.get_child_count()
		BuildingDetail.add(root, ring, top, height_world, shape, roof_h_world,
			look, facade, roof_mat, seed_v, centre.length() < BuildingDetail.NEAR_RADIUS,
			party, gable_front)
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
		fire: Material = null, invert: bool = false) -> void:
	BuildingWalls._walls(root, ring, base, top, mat, v_repeat, cover, fire, invert)

static func _roof_cap(root: Node3D, ring: PackedVector2Array, idx: PackedInt32Array,
		top: float, mat: Material, trim: int = 0, cap: PackedVector2Array = PackedVector2Array(),
		party: PackedByteArray = PackedByteArray()) -> void:
	BuildingWalls._roof_cap(root, ring, idx, top, mat, trim, cap, party)

static func _roof_form(root: Node3D, ring: PackedVector2Array, top: float,
		rh: float, shape: String, mat: Material, party: PackedByteArray = PackedByteArray(),
		gable_front: bool = false, holes: Array = []) -> void:
	var mesh := RoofGeometry.form_mesh(ring, top, rh, shape, party, gable_front, holes)
	if mesh != null and _batch != null:
		_batch.add_mesh(_batch_key, mat, mesh)
	elif mesh != null:
		TerrainBuilder._add(root, mesh, mat)

static func _near_landmark_candidate(data: LocationData, x: float, z: float) -> bool:
	for c in data.landmark_candidates:
		if Vector2(x - float(c.get("x", 0.0)), z - float(c.get("z", 0.0))).length() < 36.0:
			return true
	return false

static func _rect_ring(c: Vector2, size: Vector2, yaw: float) -> PackedVector2Array:
	return BuildingWalls._rect_ring(c, size, yaw)

static func _aabb_footprint(b: Dictionary) -> Dictionary:
	return BuildingWalls._aabb_footprint(b)
