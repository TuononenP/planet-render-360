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
	var floor_h := float((LEGACY_BOX[region] as Dictionary)["floor_h"])
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
		str((LEGACY_BOX[region] as Dictionary)["default_roof"]), false)
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
static func _rect_ring(c: Vector2, size: Vector2, yaw: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		ring.append(c + (corner * size * 0.5).rotated(yaw))
	return ring

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
static func _aabb_footprint(b: Dictionary) -> Dictionary:
	var out := b.duplicate()
	out.erase("parts")
	out["footprint"] = _rect_ring(Vector2(float(b["x"]), float(b["z"])),
		Vector2(float(b["size_x"]), float(b["size_z"])), 0.0)
	return out

## True-footprint masses for one §2.4 building: its building:part
## sub-polygons when present (OSM parts tile the parent outline, each
## with its own height, so the parent shell is skipped — extruding
## both would double coplanar walls), else the parent footprint alone.
## Returns true when at least one mass extruded; false routes to the
## logged AABB fallback in _real_buildings.
static func _extrude_masses(root: Node3D, data: LocationData,
		ground: GroundTruth, b: Dictionary, ctx: Dictionary) -> bool:
	# One look per building: parts inherit the parent's kind, finish and
	# roof, as they inherit its tags.
	var look := _look_for(b, ctx)
	var parent_res := _resolve_total(b, b, ctx, {}, look)
	var legacy := not b.has("height_source")
	# Parts carry no roof keys (fetcher §2.4), so they inherit the
	# parent's roof; each part's roof height is recomputed from its
	# own span below.
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
	base -= 0.6
	var top := base + height_world
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
	_roof_cap(root, ring, idx, top, roof_mat)
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
static func _clean_ring(raw: PackedVector2Array) -> PackedVector2Array:
	var ring := PackedVector2Array(raw)
	while ring.size() > 1 \
			and ring[0].distance_to(ring[ring.size() - 1]) < 0.01:
		ring.remove_at(ring.size() - 1)
	if ring.size() < 3:
		return PackedVector2Array()
	if absf(RingGeometry.signed_area(ring)) < 0.01:
		return PackedVector2Array()
	return ring

## Vertical wall quads, one per ring edge. Outward normals come from
## the winding (exact for simple rings however concave — a centroid
## test can flip inside deep notches). Triangle order is picked per
## edge so the Godot front face (clockwise viewed from outside) lands
## on the outward normal. Wall UVs match BoxMesh (v = 1 at the base),
## so the facade grime stays at the ground and cornices stay upright.
static func _walls(root: Node3D, ring: PackedVector2Array, base: float,
		top: float, mat: Material, v_repeat: float = 1.0) -> void:
	var ccw := RingGeometry.signed_area(ring) > 0.0
	# Style facades map UVs in real window bays (and, for tiled patterns,
	# real storeys) so windows keep their size on any wall; legacy
	# materials stretch 0..1 over the edge.
	var uvp := FacadeMaterials.facade_uv(mat)
	var m2u := WorldScale.metres_to_units()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var e := b - a
		if e.length() < 0.001:
			continue
		var n := Vector2(e.y, -e.x).normalized() if ccw \
			else Vector2(-e.y, e.x).normalized()
		var n3 := Vector3(n.x, 0.0, n.y)
		var k := verts.size()
		verts.append_array([Vector3(a.x, base, a.y), Vector3(b.x, base, b.y),
			Vector3(b.x, top, b.y), Vector3(a.x, top, a.y)])
		for j in 4:
			normals.append(n3)
		var u1 := 1.0
		var v0 := 1.0
		if uvp.x > 0.0:
			var len_m := e.length() / m2u
			# An edge under half a bay shows only the blank margin left of
			# the first window (a pillar must not become a zebra).
			u1 = 0.03 if len_m < uvp.x * 0.5 else maxf(1.0, roundf(len_m / uvp.x)) / uvp.y
			if uvp.z > 0.0:
				v0 = v_repeat
		uvs.append_array([Vector2(0, v0), Vector2(u1, v0),
			Vector2(u1, 0), Vector2(0, 0)])
		# Forward order faces (e.y, -e.x): with s < 0 that is the
		# outward normal already, else the reversed order is emitted.
		var s := e.x * n.y - e.y * n.x
		if s > 0.0:
			indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])
		else:
			indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	if indices.is_empty():
		return
	if _batch != null:
		_batch.add(_batch_key, mat, verts, normals, uvs, indices)
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	TerrainBuilder._add(root, mesh, mat)

## Flat roof cap over the triangulated ring: the whole roof for flat
## shapes, the eave-level seal under pitched T4.2 forms (it closes the
## gaps concave rings leave in apex fans). Triplets flip when the
## emitted triangle faces down, so the front face points up — the same
## convention as the terrain mesh.
static func _roof_cap(root: Node3D, ring: PackedVector2Array,
		idx: PackedInt32Array, top: float, mat: Material) -> void:
	# triangulate_polygon normalizes its output winding (a CW input
	# still yields CCW triplets), so the flip is read off the first
	# emitted triangle, not the ring: front.y equals its 2D cross.
	var flip := false
	if idx.size() >= 3:
		var p0 := ring[idx[0]]
		var p1 := ring[idx[1]]
		var p2 := ring[idx[2]]
		flip = (p1.x - p0.x) * (p2.y - p0.y) \
			- (p1.y - p0.y) * (p2.x - p0.x) < 0.0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for p in ring:
		verts.append(Vector3(p.x, top, p.y))
		normals.append(Vector3.UP)
		uvs.append(p * 0.05)
	var indices := PackedInt32Array()
	for t in idx.size() / 3:
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		if flip:
			indices.append_array([i0, i2, i1])
		else:
			indices.append_array([i0, i1, i2])
	if _batch != null:
		_batch.add(_batch_key, mat, verts, normals, uvs, indices)
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	TerrainBuilder._add(root, mesh, mat)

## Floor height / default roof for the legacy box-mesh fallback only
## (corrupt footprints, AABB-only v1 dicts): box UVs cannot tile, so that
## path keeps the original Paris-vs-everywhere-else defaults. Every other
## building takes its numbers from ArchitectureStyle (T4.2 heights and
## roofs, now by region and kind).
const LEGACY_BOX = {
	"haussmann": {"floor_h": 3.1, "default_roof": "mansard"},
	"urban": {"floor_h": 3.0, "default_roof": "flat"},
}

static func _legacy_region(data: LocationData) -> String:
	if data != null and ArchitectureStyle.region_for(
			data.latitude, data.longitude) == "haussmann":
		return "haussmann"
	return "urban"

## Settlement density by buildings within 400 m of the viewpoint:
## ≥120 dense, ≥25 mid, else rural (what kind_for and the storey ranges
## key off when the map does not say).
static func _density(data: LocationData) -> String:
	var r := 400.0 * WorldScale.metres_to_units()
	var n := 0
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var bd := b as Dictionary
		if Vector2(float(bd.get("x", 1e9)), float(bd.get("z", 1e9))).length() <= r:
			n += 1
	if n >= 120:
		return "dense"
	if n >= 25:
		return "mid"
	return "rural"

## Footprint area in m² (ring area when present, else the AABB keys).
static func _area_m2(b: Dictionary) -> float:
	var m2u := WorldScale.metres_to_units()
	var fp: Variant = b.get("footprint", null)
	if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3:
		return absf(RingGeometry.signed_area(fp as PackedVector2Array)) / (m2u * m2u)
	return float(b.get("size_x", 0.0)) * float(b.get("size_z", 0.0)) / (m2u * m2u)

## One building's ArchitectureStyle look, seeded by its position.
static func _look_for(b: Dictionary, ctx: Dictionary) -> Dictionary:
	var seed_v := TerrainBuilder._hash(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	return ArchitectureStyle.resolve(b, str(ctx["region"]), str(ctx["density"]),
		seed_v, _area_m2(b))

## Per-build context: the style region and settlement density, plus the
## tagged heights (tag/levels resolved, in a 150 m spatial hash keyed by
## building kind) that feed the neighbour estimate — a house is judged
## against nearby houses, never against a tagged tower.
static func _height_context(data: LocationData) -> Dictionary:
	var region := ArchitectureStyle.region_for(data.latitude, data.longitude)
	var density := _density(data)
	var m2u := WorldScale.metres_to_units()
	var cell := 150.0 * m2u
	var cells := {}
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var bd := b as Dictionary
		var src := str(bd.get("height_source", ""))
		if src != "tag_height" and not (src == "levels" and int(bd.get("levels", 0)) > 0):
			continue
		var kind := ArchitectureStyle.kind_for(bd, density, _area_m2(bd))
		var h := float(bd.get("height", 0.0))
		if src == "levels":
			h = float(int(bd.get("levels", 0))) \
				* float(ArchitectureStyle.profile(region, kind)["fh"])
		if h <= 0.0:
			continue
		var p := Vector3(float(bd.get("x", 0.0)), float(bd.get("z", 0.0)), h)
		var key := Vector3i(int(floor(p.x / cell)), int(floor(p.y / cell)),
			ArchitectureStyle.KINDS.find(kind))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(p)
	return {"region": region, "density": density,
		"fidelity": MaterialLibrary.fidelity_for_preset(data.quality_preset),
		"cells": cells, "cell": cell, "radius_u": 150.0 * m2u}

## T4.2 height priority (contract §2.4): `height` tag → `building:levels`
## × the kind's regional floor height → same-kind local estimate →
## the kind's regional default (a seeded storey count, never one global
## figure). `m` is the mass (part or parent), `b` the parent; parts
## without own tags inherit parent_res. Dicts without height_source
## predate v2 (fixtures) and keep their carried height verbatim. Returns
## {total_m, source}; total includes the roof (OSM `height` semantics),
## the caller splits wall/roof from the shape.
static func _resolve_total(m: Dictionary, b: Dictionary, ctx: Dictionary,
		parent_res: Dictionary, look: Dictionary) -> Dictionary:
	var src := str(m.get("height_source", b.get("height_source", "")))
	var levels := int(m.get("levels", b.get("levels", 0)))
	# A part echoes its parent's source when it carries no tags of its
	# own ("levels" with levels 0 included), so it inherits the
	# resolved parent mass instead of re-inferring at its centroid.
	if not parent_res.is_empty() \
			and src != "tag_height" and not (src == "levels" and levels > 0):
		return {"total_m": float(parent_res["total_m"]),
			"source": str(parent_res["source"])}
	if src == "tag_height":
		return {"total_m": float(m.get("height", b.get("height", 0.0))),
			"source": "tag_height"}
	if src == "levels" and levels > 0:
		return {"total_m": float(levels) * float(look["floor_h"]),
			"source": "levels"}
	if src == "":
		var h := float(m.get("height", b.get("height", 0.0)))
		if h > 0.0:
			return {"total_m": h, "source": "tag_height"}
		if levels > 0:
			return {"total_m": float(levels) * float(look["floor_h"]),
				"source": "levels"}
	return _inferred_total(float(m.get("x", b.get("x", 0.0))),
		float(m.get("z", b.get("z", 0.0))), ctx, look)

## Step 3 of the priority: the data-derived local estimate. The plan
## names a satellite/DEM-derived estimate; what is honest today is the
## same-kind neighbour median (tagged heights within 150 m, ≥3 samples,
## ±15% seeded so a street is not a row of clones), because the T2.1 DEM
## is bare-earth (~6 m/px, buildings unresolved) and the Esri mosaic's
## capture sun geometry is unknown, so shadow extrusion would be
## guesswork. With 1–2 tagged neighbours the kind's default is clamped
## within 1.95× of their median (neighbour-guard-safe by construction);
## with none the kind's regional default applies.
static func _inferred_total(x: float, z: float, ctx: Dictionary,
		look: Dictionary) -> Dictionary:
	var near := _tagged_within(ctx, x, z, str(look["kind"]))
	var reg := float(look["default_h"])
	if near.size() >= 3:
		var jitter := 0.85 + 0.3 * ArchitectureStyle._h(x * 0.37 + z * 0.91, 8)
		return {"total_m": _median(near) * jitter, "source": "estimate"}
	if near.size() >= 1:
		var med := _median(near)
		return {"total_m": clampf(reg, med / 1.95, med * 1.95),
			"source": "default"}
	return {"total_m": reg, "source": "default"}

static func _tagged_within(ctx: Dictionary, x: float, z: float, kind: String) -> Array:
	var out: Array = []
	var cell := float(ctx["cell"])
	var r := float(ctx["radius_u"])
	var cx := int(floor(x / cell))
	var cz := int(floor(z / cell))
	var k := ArchitectureStyle.KINDS.find(kind)
	var cells := ctx["cells"] as Dictionary
	for ix in range(cx - 1, cx + 2):
		for iz in range(cz - 1, cz + 2):
			var bucket: Variant = cells.get(Vector3i(ix, iz, k), [])
			if not (bucket is Array):
				continue
			for p in (bucket as Array):
				var pv: Vector3 = p
				if Vector2(pv.x - x, pv.y - z).length() <= r:
					out.append(pv.z)
	return out

static func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	a.sort()
	var n := a.size()
	if n % 2 == 1:
		return float(a[n / 2])
	return (float(a[n / 2 - 1]) + float(a[n / 2])) * 0.5

## Canonical roof shape from the raw `roof:shape` tag. Pitched-family
## aliases map to their nearest modelled form (skillion/gambrel read
## as gabled, cone as pyramidal, round/onion as dome); anything else
## unknown reads as flat. Untagged ("") takes the regional default —
## except legacy dicts without height_source, which keep the flat cap
## their wall heights were pinned against.
static func _effective_shape(raw: String, default_roof: String, legacy: bool) -> String:
	match raw.strip_edges().to_lower():
		"flat":
			return "flat"
		"gabled", "gambrel", "skillion", "saltbox", "shed":
			return "gabled"
		"hipped":
			return "hipped"
		"mansard":
			return "mansard"
		"pyramidal", "pyramid", "cone":
			return "pyramidal"
		"dome", "round", "onion":
			return "dome"
		"":
			return "flat" if legacy else default_roof
		_:
			return "flat"

## Roof rise in metres: the `roof:height` tag when present, else a
## shape default scaled by the footprint's short span and the style's
## regional pitch (steep alpine/German roofs, low Nordic/Australian ones;
## flat reads 0 — the cap is the roof). The caller additionally caps the
## rise below the total height so the wall keeps ≥0.5 m.
static func _roof_height_m(shape: String, span_m: float, tag_m: float,
		pitch: float = 1.0) -> float:
	if tag_m > 0.0:
		return tag_m
	# Clamps scale with the pitch so a steep alpine roof is not flattened
	# back to the default cap (identical to the old clamps at pitch 1).
	var lo := minf(pitch, 1.0)
	var hi := maxf(pitch, 1.0)
	match shape:
		"gabled":
			return clampf(span_m * 0.28 * pitch, 1.2 * lo, 4.5 * hi)
		"hipped":
			return clampf(span_m * 0.25 * pitch, 1.2 * lo, 4.0 * hi)
		"mansard":
			return clampf(span_m * 0.24 * pitch, 1.5 * lo, 3.2 * hi)
		"pyramidal":
			return clampf(span_m * 0.32 * pitch, 1.0 * lo, 5.0 * hi)
		"dome":
			return clampf(span_m * 0.30 * pitch, 1.0 * lo, 6.0 * hi)
	return 0.0

static func _ring_span_m(ring: PackedVector2Array) -> float:
	var bb := RingGeometry.aabb(ring)
	return minf(bb.size.x, bb.size.y) / WorldScale.metres_to_units()

## Pitched roof over a cleaned ring, rising rh from the eave level top
## (RoofGeometry builds the mesh; rings whose centroid falls outside keep
## the flat seal cap only).
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
