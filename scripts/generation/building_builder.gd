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
## Last build's census: {real, impostors, infill, far_blocks, far_towers}.
static var last_stats: Dictionary = {}

## Buildings subtree: real OSM extrusions (+ impostors past the cap),
## absence-only infill, and the real-data far city.
static func build_buildings(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	FacadeMaterials.begin_build()
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

static func _box_mat(root: Node3D, pos: Vector3, scl: Vector3, mat: Material) -> void:
	var mi := TerrainBuilder._add(root, TerrainBuilder._box_mesh(), mat)
	mi.position = pos
	mi.scale = scl

static func _box(root: Node3D, pos: Vector3, scl: Vector3, color: Color) -> void:
	_box_mat(root, pos, scl, TerrainBuilder._mat(color))

static func _mansard(root: Node3D, cx: float, base_y: float, cz: float,
		size_x: float, size_z: float, roof_h: float, seed_v: float,
		mat: Material = null) -> void:
	var mi := TerrainBuilder._add(root, TerrainBuilder._cyl(0.52, 1.0, 1.0, 4),
		mat if mat != null else MaterialLibrary.slate())
	mi.rotation.y = PI / 4.0
	mi.position = Vector3(cx, base_y + roof_h / 2.0, cz)
	mi.scale = Vector3(size_x * 0.48, roof_h, size_z * 0.48)

static func _building(root: Node3D, pos: Vector3, size_x: float, size_z: float,
		height_world: float, seed_v: float, data: LocationData = null,
		roof_shape: String = "", roof_h_world: float = -1.0,
		b: Dictionary = {}) -> void:
	# T4.3: wall/roof resolve from OSM tags → satellite sample →
	# regional defaults, with one window row per real storey; blocks
	# past the fidelity radius share the ≤6 distant materials.
	# Box-mesh fallback (corrupt footprints, AABB-only v1 dicts): box UVs
	# cannot tile, so it keeps the legacy one-texture-per-wall materials.
	var region := _legacy_region(data)
	var fidelity := MaterialLibrary.fidelity_for_preset(
		data.quality_preset) if data != null else 2
	var m2u := WorldScale.metres_to_units()
	var distant := data != null and pos.length() / m2u \
		> MaterialLibrary.full_detail_radius_m(fidelity)
	var floor_h := float((BuildingWalls.LEGACY_BOX[region] as Dictionary)["floor_h"])
	var storeys := int(b.get("levels", 0))
	if storeys <= 0:
		storeys = maxi(1, roundi(height_world / m2u / floor_h))
	var facade := FacadeMaterials.facade_for_building(b, region, storeys,
		fidelity, distant, seed_v)
	_box_mat(root, pos + Vector3(0, height_world / 2.0, 0),
		Vector3(size_x, height_world, size_z), facade)
	# T4.2: the v1 "everything gets a mansard" default is gone — an
	# untagged roof takes the regional default (mansard only where the
	# tag or the Haussmann region says so). height_world is the WALL
	# height; the roof rises above it by roof_h_world (explicit from
	# real-data callers, v1-auto when negative).
	var shape := _effective_shape(roof_shape,
		str((BuildingWalls.LEGACY_BOX[region] as Dictionary)["default_roof"]), false)
	var hint := Color(0, 0, 0, 0)
	if data != null:
		hint = MaterialLibrary.sampled_roof_color(data, pos.x, pos.z,
			size_x, size_z, Callable(TerrainBuilder, "satellite_uv"))
	var roof_mat := FacadeMaterials.roof_for_building(b, region, shape,
		hint, fidelity, distant, seed_v)
	var rh := roof_h_world
	if rh < 0.0:
		if shape == "flat":
			rh = 0.0
		elif shape == "mansard":
			rh = clampf(minf(size_x, size_z) * 0.22, 2.8, 8.0)
		else:
			var span_m := minf(size_x, size_z) / WorldScale.metres_to_units()
			rh = _roof_height_m(shape, span_m, 0.0) * WorldScale.metres_to_units()
	if shape == "flat":
		_box_mat(root, pos + Vector3(0, height_world + 0.72, 0),
			Vector3(size_x * 1.02, 1.44, size_z * 1.02), roof_mat)
		return
	if shape == "mansard":
		_mansard(root, pos.x, pos.y + height_world, pos.z, size_x, size_z, rh, seed_v, roof_mat)
	else:
		var hx := size_x * 0.5
		var hz := size_z * 0.5
		var rect := PackedVector2Array([Vector2(pos.x - hx, pos.z - hz),
			Vector2(pos.x + hx, pos.z - hz), Vector2(pos.x + hx, pos.z + hz),
			Vector2(pos.x - hx, pos.z + hz)])
		_roof_form(root, rect, pos.y + height_world, rh, shape, roof_mat)
	# Dormers + chimneys break the roofline (PRD §4.2); near blocks only.
	# (metres since the T7.0 cutover; v1 unit values x4)
	if pos.length() < BuildingDetail.NEAR_RADIUS and height_world > 12.8:
		var n_d := clampi(int(size_x / 6.4), 1, 4)
		for di in n_d:
			var dx := (float(di) - float(n_d - 1) / 2.0) * 6.0
			_box_mat(root, pos + Vector3(dx, height_world + rh * 0.52, size_z * 0.30),
				Vector3(1.68, 2.08, 1.2), roof_mat)
		_box_mat(root, pos + Vector3(size_x * 0.28, height_world + rh + 0.88, 0),
			Vector3(1.36, 2.2, 1.36), MaterialLibrary.pbr_material("brick"))

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
	for b in sorted:
		var pos := Vector3(float(b["x"]), 0, float(b["z"]))
		if data.landmark_type != "none" \
				and Vector2(pos.x, pos.z).distance_to(site) < 68.0:
			continue
		if _near_landmark_candidate(data, pos.x, pos.z):
			continue  # the archetype model stands here instead
		if absf(pos.x) > edge or absf(pos.z) > edge:
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
			_building(root, pos, float(b["size_x"]), float(b["size_z"]),
				wall_w, TerrainBuilder._hash(pos.x, pos.z), data, shape,
				rh_m * WorldScale.metres_to_units(), b)
		placed += 1
	last_stats["real"] = placed
	impostor.commit(root, "Impostor")
	if aabb_fallbacks > 0:
		push_warning("BuildingBuilder: %d of %d real buildings used the AABB fallback (missing/corrupt footprint, extruded as a rectangle)."
			% [aabb_fallbacks, placed])

## A building whose own footprint/parts failed, re-shaped as its AABB
## rectangle (axis-aligned: the keys carry no rotation).
static func _extrude_masses(root: Node3D, data: LocationData,
		ground: GroundTruth, b: Dictionary, ctx: Dictionary) -> bool:
	# One look per building: parts inherit the parent's kind, finish and
	# roof, as they inherit its tags (and one RoofVariety tint).
	var first := root.get_child_count()
	var look := _look_for(b, ctx)
	var parent_res := _resolve_total(b, b, ctx, {}, look)
	var legacy := not b.has("height_source")
	# Parts carry no roof keys (fetcher §2.4), so they inherit the
	# parent's roof; each part's roof height comes from its own span.
	var shape := _effective_shape(str(b.get("roof_shape", "")),
		str(look["roof_shape"]), legacy)
	var roof_tag := float(b.get("roof_height_m", 0.0))
	var masses: Array = b.get("parts", [])
	var single := masses.is_empty()
	if single:
		masses = [b]
	var done := false
	# Roofline detail (chimneys, towers, rooftop plant) goes on the largest
	# mass only: a church of five parts has one tower, not five.
	var main_mass := 0
	var main_area := -1.0
	for i in masses.size():
		var mfp: Variant = (masses[i] as Dictionary).get("footprint", null) \
			if masses[i] is Dictionary else null
		if mfp is PackedVector2Array and (mfp as PackedVector2Array).size() >= 3:
			var ar := absf(RingGeometry.signed_area(mfp as PackedVector2Array))
			if ar > main_area:
				main_area = ar
				main_mass = i
	for mi in masses.size():
		var m: Variant = masses[mi]
		if not (m is Dictionary):
			continue
		var md := m as Dictionary
		var fp: Variant = md.get("footprint", PackedVector2Array())
		if not (fp is PackedVector2Array):
			continue
		var ring := _clean_ring(fp)
		if ring.size() < 3:
			continue
		var res := parent_res if single \
			else _resolve_total(md, b, ctx, parent_res, look)
		# T4.3: storeys drive the window rows (tagged levels, else the
		# resolved total over the regional floor height); each mass
		# resolves its own material tags with parent fallback.
		var storeys := int(md.get("levels", b.get("levels", 0)))
		if storeys <= 0:
			storeys = maxi(1, roundi(float(res["total_m"]) \
				/ float(look["floor_h"])))
		var b_eff := (b as Dictionary).duplicate()
		for k in md:
			b_eff[k] = md[k]
		var span_m := _ring_span_m(ring)
		var rh_m := minf(_roof_height_m(shape, span_m, roof_tag,
			float(look["pitch"])), maxf(float(res["total_m"]) - 0.5, 0.0))
		var wall_w := (float(res["total_m"]) - rh_m) * WorldScale.metres_to_units()
		if legacy:
			wall_w = clampf(wall_w, 7.2, 76.0)
		var centre := Vector2(float(md.get("x", 0.0)), float(md.get("z", 0.0)))
		if _extrude_polygon(root, data, ground, ring, wall_w, centre,
				shape, rh_m * WorldScale.metres_to_units(), b_eff, ctx,
				storeys, look, mi == main_mass):
			done = true
	if done and _batch == null:
		RoofVariety.tint(root, first, float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	return done

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
		look: Dictionary = {}, with_detail: bool = true) -> bool:
	var idx := Geometry2D.triangulate_polygon(ring)
	if idx.size() < 3:
		return false
	var base := ground.height_at_world(centre.x, centre.y)
	for p in ring:
		base = minf(base, ground.height_at_world(p.x, p.y))
	# Walls sink 0.6 m below the lowest ground (no floating on slopes);
	# the real height stands above that ground, not above the sunk base.
	var sink := 0.6 * WorldScale.metres_to_units()
	base -= sink
	var top := base + sink + height_world
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
	if FacadeMaterials.facade_uv(facade).z > 0.0 and v_rep >= 2.0 and _batch == null:
		ground_mat = FacadeMaterials.ground_for_building(b, fidelity, distant, look)
	if ground_mat != null:
		var m2u := WorldScale.metres_to_units()
		var fh_u := float(look["floor_h"]) * m2u
		var gh_u := fh_u * (1.15 if str(look.get("ground", "")) in ["shop", "signage"] else 1.0)
		var g_top := minf(ground.height_at_world(centre.x, centre.y) + gh_u,
			top - fh_u * 0.6)
		_walls(root, ring, base, g_top, ground_mat, (g_top - base) / gh_u)
		_walls(root, ring, g_top, top, facade, maxf(1.0, v_rep - 1.0))
	else:
		_walls(root, ring, base, top, facade, v_rep)
	_roof_cap(root, ring, idx, top, roof_mat, BuildingTrim.kind(shape, centre.length() / WorldScale.metres_to_units()))
	if shape != "flat" and roof_h_world > 0.01:
		# Eave overhang (style metres) for gabled/hipped/pyramidal roofs:
		# the eave line drops by the roof's own slope so the pitch is kept.
		var eave_u := float(look.get("eave", 0.0)) * WorldScale.metres_to_units()
		if eave_u > 0.0 and shape in ["gabled", "hipped", "pyramidal"]:
			var half := maxf(_ring_span_m(ring) * WorldScale.metres_to_units() * 0.5, 0.01)
			var drop := minf(eave_u * roof_h_world / half, height_world * 0.25)
			_roof_form(root, RoofGeometry.offset_ring(ring, eave_u), top - drop,
				roof_h_world + drop, shape, roof_mat)
		else:
			_roof_form(root, ring, top, roof_h_world, shape, roof_mat)
	if with_detail and not distant and _batch == null and not look.is_empty():
		var before := root.get_child_count()
		BuildingDetail.add(root, ring, top, height_world, shape, roof_h_world,
			look, facade, roof_mat, seed_v, centre.length() < BuildingDetail.NEAR_RADIUS)
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
		top: float, mat: Material, v_repeat: float = 1.0) -> void:
	BuildingWalls._walls(root, ring, base, top, mat, v_repeat)

static func _roof_cap(root: Node3D, ring: PackedVector2Array, idx: PackedInt32Array, top: float, mat: Material, trim: int = 0) -> void:
	BuildingWalls._roof_cap(root, ring, idx, top, mat, trim)

static func _roof_form(root: Node3D, ring: PackedVector2Array, top: float,
		rh: float, shape: String, mat: Material) -> void:
	var mesh := RoofGeometry.form_mesh(ring, top, rh, shape)
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
