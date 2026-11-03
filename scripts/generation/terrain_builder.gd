class_name TerrainBuilder
extends RefCounted

## Builds renderable 3D from a LocationData height grid.
## Unit conversions live in WorldScale (contract §1, T1.2): 1 unit = 1 m
## since the T7.0 metre cutover (2400 m detailed extent).
## Visual target: visual-plan/PRD.md Fidelity 3 photoreal PBR scenery,
## golden-hour grade, aerial haze.

## Fallback cap when data carries no preset; RenderSettings owns the
## per-preset building/tree budgets actually used below.
const MAX_REAL_BUILDINGS := 340
## Fallback landmark offset (metres) for data without a real site
## (hand-built fixtures): ENE of the viewpoint, the v1 (18, -14) units.
const LANDMARK_POS := Vector2(72, -56)
## Landmarks (registry + OSM archetypes) are placed at their true site
## out to the mid far-terrain ring; past it the haze owns the view.
const LANDMARK_MAX_M := 9000.0

## Debug toggle for the Phase 3 exit gate (T3.1): when true,
## build_world skips BuildingBuilder so terrain + water alone can be
## judged for place-shape in side-by-side review. Default false.
static var debug_hide_buildings := false

static var _unit_box: BoxMesh

static func _range_of(values: PackedFloat32Array) -> Vector2:
	var mn := INF
	var mx := -INF
	for v in values:
		mn = minf(mn, v)
		mx = maxf(mx, v)
	return Vector2(mn, mx)

static func _polys(data: LocationData, classes: Array) -> Array:
	var out: Array = []
	for poly in data.land_polygons:
		if str(poly.get("class", "")) in classes:
			out.append(poly["points"])
	return out

static func _colored_mesh(verts: PackedVector3Array, normals: PackedVector3Array,
		colors: PackedColorArray, indices: PackedInt32Array,
		roughness: float = 1.0, cull_disabled: bool = false,
		uvs: PackedVector2Array = PackedVector2Array(),
		tex: Texture2D = null, capped_drape: bool = false) -> MeshInstance3D:
	if normals.is_empty():
		for i in verts.size():
			normals.append(Vector3.UP)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat: StandardMaterial3D
	if capped_drape and tex != null:
		# Satellite drape (T3.2): the shared drape material carries
		# the PRD §4.4 0.85 cap; the texture stays unmodified.
		mat = MaterialLibrary.satellite_ground_material(tex)
	else:
		mat = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		if tex != null:
			# Imagery carries the albedo; vertex colour becomes a slope
			# shade multiplied over it (see _terrain_mesh).
			mat.albedo_texture = tex
	mat.roughness = roughness
	if cull_disabled:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _add(null, mesh, mat)

static func _cyl(top_r: float, bottom_r: float, height: float, segments: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = height
	c.radial_segments = segments
	return c

static func _add(parent: Node, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	return mi

static func _box_mesh() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box

## `abort` (optional) stops the build at the next stage boundary: it
## returns what it has, and View360.build_location drops it.
static func build_world(data: LocationData, ground: GroundTruth = null,
		abort: BuildAbort = null) -> Node3D:
	# Transitional: the pipeline constructs GroundTruth once in stage 3
	# (contract §3); direct callers get a fresh surface here instead.
	if ground == null:
		ground = GroundTruth.new(data)
	MaterialLibrary.hi_res = RenderQuality.ultra_desktop(data.quality_preset)
	# WorldBuildGraph runs the stages concurrently (serial on the main
	# thread, or with WorldBuildGraph.force_serial).
	# load() breaks the TerrainBuilder <-> WorldBuildGraph class cycle.
	var wbg = load("res://scripts/generation/world_build_graph.gd") as GDScript
	if wbg.force_serial:
		return _build_serial(data, ground, abort)
	return wbg.build(data, ground, abort)

## The serial build, stage by stage; per-stage ms land in abort.ms.
static func _build_serial(data: LocationData, ground: GroundTruth,
		abort: BuildAbort = null) -> Node3D:
	var t0 := Time.get_ticks_msec()
	var root := Node3D.new()
	root.name = "GeneratedWorld"
	BuildAbort.mark(abort, BuildAbort.Step.FAR)
	root.add_child(FarTerrainBuilder.build_far(data, ground, abort))
	_stage_ms(abort, BuildAbort.Step.FAR, t0)
	if abort != null and abort.requested:
		return root
	var t := Time.get_ticks_msec()
	BuildAbort.mark(abort, BuildAbort.Step.GROUND)
	root.add_child(_terrain_mesh(data, ground, abort))
	root.add_child(WaterBuilder.build_water(data, ground, abort))
	_stage_ms(abort, BuildAbort.Step.GROUND, t)
	if abort != null and abort.requested:
		return root
	t = Time.get_ticks_msec()
	BuildAbort.mark(abort, BuildAbort.Step.BUILDINGS)
	if not debug_hide_buildings:
		_adopt_flat(root, BuildingBuilder.build_buildings(data, ground, abort))
	_stage_ms(abort, BuildAbort.Step.BUILDINGS, t)
	if abort != null and abort.requested:
		return root
	t = Time.get_ticks_msec()
	BuildAbort.mark(abort, BuildAbort.Step.ROADS)
	if not data.buildings.is_empty():
		_adopt_flat(root, RoadBuilder.build_roads(data, ground, abort))
	if data.landmark_type != "none":
		root.add_child(_landmark(data, ground))
	_landmark_candidates(root, data, ground)
	_stage_ms(abort, BuildAbort.Step.ROADS, t)
	if abort != null and abort.requested:
		return root
	t = Time.get_ticks_msec()
	BuildAbort.mark(abort, BuildAbort.Step.VEGETATION)
	_adopt_flat(root, VegetationBuilder.build_vegetation(data, ground, abort))
	_stage_ms(abort, BuildAbort.Step.VEGETATION, t)
	if abort != null:
		print("%s total=%d serial" % [abort.timings_line(), Time.get_ticks_msec() - t0])
	return root

static func _stage_ms(abort: BuildAbort, s: BuildAbort.Step, since: int) -> void:
	if abort != null:
		abort.set_ms(s, Time.get_ticks_msec() - since)

## Transitional (T1.4): the T1.1c builders already return contract §4
## subtrees, but scenery/settings tests scan world children flat, so
## each subtree's children are adopted directly until F updates the
## tests to the subtree shape.
static func _adopt_flat(root: Node3D, subtree: Node3D) -> void:
	for c in subtree.get_children():
		subtree.remove_child(c)
		# LodRing (T7.1) reads the layer a flat child came from.
		if not c.has_meta("lod_layer"):
			c.set_meta("lod_layer", str(subtree.name))
		root.add_child(c)
	subtree.free()

## Landmark candidates (LandmarkSites: registry extras, then OSM
## features) near the viewpoint: a registry `type` builds its hand-made
## model, an OSM feature its archetype, and a mapped landmark nothing
## (BuildingBuilder draws it from its own parts). True
## metre position (T5.2): no framing cut — the v1 ±105-unit window is
## gone; only the LANDMARK_MAX_M haze limit applies.
static func _landmark_candidates(root: Node3D, data: LocationData, ground: GroundTruth) -> void:
	for c in data.landmark_candidates:
		if bool(c.get("mapped", false)):
			continue
		var cx := float(c.get("x", 0.0))
		var cz := float(c.get("z", 0.0))
		if Vector2(cx, cz).length() > LANDMARK_MAX_M:
			continue
		if c.has("type"):
			var hero := LandmarkBuilder.build(str(c["type"]))
			if RenderQuality.ultra_desktop(data.quality_preset):
				LandmarkLights.dress(hero, str(c["type"]))
				LandmarkShader.upgrade(hero)
			var entry := LocationData.entry_for_type(str(c["type"]))
			var half := minf(LandmarkSites.clear_m(entry) * 0.5, 45.0) if entry.has("clear_m") else 20.0
			hero.position = Vector3(cx, _hero_y(data, ground, cx, cz, entry, half), cz)
			hero.rotation.y = -deg_to_rad(float(c.get("yaw_deg", 0.0)))
			LandmarkTerrain.stitch(hero, ground, str(c["type"]))
			hero.set_meta("lod_layer", "Landmarks")
			root.add_child(hero)
			continue
		var node := LandmarkBuilder.build_archetype(
			str(c.get("archetype", "tower")), float(c.get("height", 30.0)),
			Vector2(float(c.get("size_x", 12.0)), float(c.get("size_z", 12.0))),
			ArchitectureStyle.region_for(data.latitude, data.longitude, data.country))
		if LandmarkShader.enabled(data.quality_preset):
			LandmarkShader.upgrade(node)
		node.position = Vector3(cx, site_ground_y(data, ground, cx, cz,
			float(c.get("size_x", 12.0)) * 0.5) - 0.3, cz)
		node.rotation.y = float(c.get("yaw", 0.0))
		node.set_meta("lod_layer", "Landmarks")
		root.add_child(node)

static func _mat(color: Color, roughness: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func _hash(x: float, z: float) -> float:
	return fmod(absf(sin(x * 12.9898 + z * 78.233) * 43758.5453), 1.0)

# Texture + material construction moved to MaterialLibrary in T1.1a;
# the wrappers below keep the old call sites (incl. tests) working.

## Moved to MaterialLibrary.leaves; thin wrapper for existing callers.
static func _leaves(season: int = LocationData.Season.SUMMER) -> Array:
	return MaterialLibrary.leaves(season)

## Mosaic width in tiles for UV math (T3.2, span-aware): the stitched
## span recorded on the data at fetch time (contract §2.3
## satellite_source.source_span), so fallback mosaics (z18→z17s7) and
## mixed-preset sessions project onto the right pixels. Fixtures and
## pre-source runs predate the record and keep the v1 3x3 window. This
## ends the T2.2 transitional SatelliteFetcher.SPAN read (process-global
## and stale across places/presets); that var is now write-only for A.
static func satellite_span_tiles(data: LocationData) -> int:
	if not data.satellite_source.is_empty():
		return maxi(1, int(data.satellite_source.get("source_span", 3)))
	return 3

## World XZ -> satellite mosaic UV (north is -Z). Reprojects through the
## WorldScale metre frame — internal units to true metres, metres to
## lat/lon about the viewpoint (the render origin the pipeline sets),
## lat/lon to mercator pixels at the stitched zoom — so the drape sits
## on the mesh identically before and after the T1.2 metre cutover
## (identity then). Mosaic width comes from satellite_span_tiles above.
static func satellite_uv(data: LocationData, wx: float, wz: float) -> Vector2:
	var ll := WorldScale.latlon_from_xz(wx, wz, data.latitude, data.longitude)
	var zoom := data.satellite_zoom
	if not data.satellite_source.is_empty():
		zoom = int(data.satellite_source.get("source_zoom", zoom))
	var px := TileFetcher.global_pixel(ll.x, ll.y, zoom)
	var mosaic_px := float(satellite_span_tiles(data) * SatelliteFetcher.TILE_PX)
	return (px - data.satellite_origin_px) / mosaic_px

## `abort` stops it between rows / items; a stopped result is dropped.
static func _terrain_mesh(data: LocationData, ground: GroundTruth = null, abort: BuildAbort = null) -> MeshInstance3D:
	var shore_started := Time.get_ticks_msec()
	if ground == null:
		ground = GroundTruth.new(data)
	# Mesh density is the preset's LOD knob over the preset-independent
	# GroundTruth (T7.1, AC-12): at full density the posts coincide
	# exactly; coarser meshes sample the same surface bilinearly.
	var size := mini(RenderSettings.terrain_mesh_posts_for(data.quality_preset),
		data.grid_size)
	# Shoreline cells carry canonical constraints at every quality level.
	# Flat cells away from those constraints are simplified by ShoreLod.
	var shore: bool = ground.shoreline != null and ground.shoreline.ready
	if shore:
		size = data.grid_size
	var exact := size == data.grid_size
	var step := ground._step_units if shore else WorldScale.detailed_extent_units() / float(size - 1)
	# Read corrected posts once: neighbouring normals reuse the same
	# values rather than repeating triangle searches five times per post.
	var post_heights := PackedFloat32Array()
	if shore and not ShoreGeometry.force_script and ground.shoreline.sampler != null \
			and ground.shoreline.sampler.has_method("grid_heights"):
		post_heights = ground.shoreline.sampler.grid_heights()
	elif shore:
		post_heights.resize(size * size)
		for z in size:
			if abort != null and abort.requested:
				return MeshInstance3D.new()
			for x in size:
				post_heights[z * size + x] = ground.surface_at_post(x, z)
	var mn := ground.surface_min
	var mx := ground.surface_max
	# True relief in metres (T1.3): the pipeline records source-tile
	# metres in relief_metres in BOTH vertical modes, while the local
	# grid range is squashed units in legacy mode and metres in
	# true-metre mode. Thresholds below preserve the v1 trigger points
	# (~63 m alpine tops, ~23 m winter snow line) in both modes;
	# hand-built fixtures without relief_metres fall back to the grid.
	var relief_m := data.relief_metres if data.relief_metres > 0.0 else mx - mn
	var urban := not data.buildings.is_empty()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var water_levels := PackedVector2Array()
	var has_sat := data.satellite_texture != null
	var tangents := PackedFloat32Array()
	var fallback: Image = null
	# Outer-ring bounds per land polygon (min at 2i, max at 2i+1) for the
	# no-imagery colour bake: a post outside them has no crossings, so
	# land_color_bboxes skips the full point-in-polygon scan exactly.
	var land_bboxes := PackedVector2Array()
	if not has_sat and not shore and not data.land_polygons.is_empty():
		land_bboxes.resize(data.land_polygons.size() * 2)
		for i in data.land_polygons.size():
			var pts: PackedVector2Array = (data.land_polygons[i] as Dictionary).get("points", PackedVector2Array())
			var bmin := Vector2(INF, INF)
			var bmax := Vector2(-INF, -INF)
			for p in pts:
				bmin = bmin.min(p)
				bmax = bmax.max(p)
			land_bboxes[i * 2] = bmin
			land_bboxes[i * 2 + 1] = bmax
	if not has_sat:
		fallback = Image.create(size, size, false, Image.FORMAT_RGB8)
	var grass := Color(0.35, 0.48, 0.24)  # PRD grass #5A7A3C
	var dry := Color(0.55, 0.50, 0.34)
	var rock := Color(0.43, 0.42, 0.38)  # PRD rock #6E6A62
	var urban_ground := Color(0.54, 0.51, 0.45)  # PRD pavement #8A8274
	if data.season == LocationData.Season.AUTUMN:
		grass = Color(0.55, 0.52, 0.30)
	elif data.season == LocationData.Season.WINTER:
		grass = Color(0.60, 0.62, 0.55)
	elif data.season == LocationData.Season.SPRING:
		grass = Color(0.48, 0.62, 0.36)
	# Climate once per mesh, not per post (far_albedo_at's ClimateModel
	# lookups cost seconds over the grid).
	var climate := FarSurface.climate_params(data)
	for z in size:
		if abort != null and abort.requested:
			return MeshInstance3D.new()  # partial rows: no mesh (dropped anyway)
		for x in size:
			var wx := (x - size / 2.0) * step
			var wz := (z - size / 2.0) * step
			if shore:
				var snapped := ShoreGeometry.snap(Vector2(wx, wz))
				wx = snapped.x
				wz = snapped.y
			var h := post_heights[z * size + x] if shore else ground.surface_at_post(x, z) if exact \
				else ground.height_at_world(wx, wz)
			verts.append(Vector3(wx, h, wz))
			water_levels.append(Vector2(ground.water_level_at(wx, wz), 0.0))
			var hx0 := post_heights[z * size + maxi(0, x - 1)] if shore else ground.surface_at_post(x - 1, z) if exact \
				else ground.height_at_world(wx - step, wz)
			var hx1 := post_heights[z * size + mini(size - 1, x + 1)] if shore else ground.surface_at_post(x + 1, z) if exact \
				else ground.height_at_world(wx + step, wz)
			var hz0 := post_heights[maxi(0, z - 1) * size + x] if shore else ground.surface_at_post(x, z - 1) if exact \
				else ground.height_at_world(wx, wz - step)
			var hz1 := post_heights[mini(size - 1, z + 1) * size + x] if shore else ground.surface_at_post(x, z + 1) if exact \
				else ground.height_at_world(wx, wz + step)
			# Normals from the rendered geometry itself: GroundTruth
			# Y is in render units at the same scale as XZ, so the
			# central-difference run is 2 posts in render units and
			# lighting agrees with the mesh (no 4x-steep geometry
			# lit as if it were flat).
			var slope_x := (hx1 - hx0) / (2.0 * step)
			var slope_z := (hz1 - hz0) / (2.0 * step)
			var normal := Vector3(-slope_x, 1.0, -slope_z).normalized()
			normals.append(normal)
			var base_color := Color(0, 0, 0, 0)
			if shore and not has_sat:
				base_color = land_class_color(ground.land_class_at(wx, wz), base_color)
			if not has_sat and base_color.a < 0.5:
				var t := clampf((h - mn) / maxf(mx - mn, 0.001), 0.0, 1.0)
				base_color = grass.lerp(dry, clampf(t * 1.4, 0.0, 1.0))
				if t > 0.72:
					base_color = dry.lerp(rock, (t - 0.72) / 0.28)
				var steep := clampf(1.0 - normal.y, 0.0, 1.0) * 3.2
				base_color = base_color.lerp(rock, clampf(steep, 0.0, 0.75))
				if relief_m > 60.0 and t > 0.84 and steep < 0.35:
					base_color = base_color.lerp(Color(0.90, 0.91, 0.92), 0.6)  # alpine tops only
				elif data.season == LocationData.Season.WINTER \
						and relief_m > 20.0 and t > 0.50 and steep < 0.40:
					base_color = base_color.lerp(Color(0.88, 0.89, 0.90), 0.55)  # winter snow line
				# Settled ground reads as warm pavement, never bleached:
				# real OSM cities, and any low-relief place in real metres
				# (its procedural dressing is a town too). Alpine valleys
				# keep meadow green even where the floor is flat.
				if urban or data.relief_metres < 120.0:
					base_color = urban_ground.lerp(grass, _hash(x * 0.7, z * 0.7) * 0.25)
				var shade := 0.94 + _hash(x * 1.3, z * 1.7) * 0.10
				# PRD §4.4: never bleached (max luminance 0.85 under the
				# golden sun) but never the near-black of the old grade.
				base_color = Color(base_color.r * shade * 0.96,
					base_color.g * shade * 0.96, base_color.b * shade * 0.96)
			# T3.6 (GroundMaterial): COLOR.a = achromatic slope shade
			# (≤15%, never above 1.0), COLOR.rgb = the far terrain's
			# own colour here, which the shader fades to in the edge
			# band so the near/far hand-off has no colour seam.
			var s := 0.85 + 0.15 * clampf(normal.y, 0.0, 1.0)
			var fc := FarTerrainBuilder.far_albedo_at_cached(climate, data, normal,
				ground.asl_y(h), ground.water_at(wx, wz) > 0.05, wx, wz)
			colors.append(Color(fc.r, fc.g, fc.b, s))
			tangents.append_array([1.0, 0.0, 0.0, 1.0])
			if has_sat:
				# The mosaic is the low-frequency tint + distance
				# albedo, never the near-field albedo (GroundMaterial).
				uvs.append(satellite_uv(data, wx, wz))
			else:
				# No imagery: the v1 land/height colour, baked as a
				# per-post "photo" over the extent (linear → sRGB so
				# the shader's source_color decode restores it).
				uvs.append(Vector2(float(x) + 0.5, float(z) + 0.5) / float(size))
				var lc := base_color
				if shore:
					lc = base_color
				elif not land_bboxes.is_empty():
					lc = land_color_bboxes(Vector2(wx, wz), data.land_polygons, land_bboxes, base_color)
				else:
					lc = land_color(Vector2(wx, wz), data.land_polygons, base_color)
				fallback.set_pixel(x, z, lc.linear_to_srgb())
	if shore:
		print("SHORE TERRAIN vertices_ms=", Time.get_ticks_msec() - shore_started)
	if not shore:
		for z in size - 1:
			for x in size - 1:
				var a := z * size + x
				var b := a + 1
				var c := a + size
				var d := c + 1
				indices.append_array([a, b, c, b, d, c])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = water_levels
	arrays[Mesh.ARRAY_INDEX] = indices
	if shore:
		arrays = ShoreSurface.mesh_arrays(ground.shoreline, arrays, data.quality_preset, abort)
		if arrays.is_empty():
			return MeshInstance3D.new()
		print("SHORE TERRAIN arrays_ms=", Time.get_ticks_msec() - shore_started, " vertices=", (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	arrays[Mesh.ARRAY_INDEX] = LandmarkTerrain.cut_indices(data, arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_INDEX])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var photo: Texture2D = data.satellite_texture
	var rect := Rect2(0, 0, 1, 1)
	if has_sat:
		var half := WorldScale.detailed_extent_units() * 0.5
		var c0 := satellite_uv(data, -half, -half)
		var c1 := satellite_uv(data, half, half)
		rect = Rect2(c0, c1 - c0).abs()
	else:
		fallback.generate_mipmaps()
		photo = ImageTexture.create_from_image(fallback)
	var terrain := _add(null, mesh, GroundMaterial.build(data, photo, rect, has_sat))
	terrain.name = "Terrain"
	if shore:
		print("SHORE TERRAIN total_ms=", Time.get_ticks_msec() - shore_started)
	return terrain

## Moved to FarTerrainBuilder._far_terrain; thin wrapper for
## existing callers (tests). build_world uses build_far instead.
static func _far_terrain(data: LocationData, ground: GroundTruth = null) -> MeshInstance3D:
	return FarTerrainBuilder._far_terrain(data, ground)

static func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	return WorldScale.point_in_polygon(point, polygon)

static func land_color(point: Vector2, land: Array, fallback: Color) -> Color:
	for poly in land:
		if point_in_polygon(point, poly["points"]):
			match str(poly["class"]):
				"water": return Color(0.30, 0.50, 0.60)
				"forest": return Color(0.27, 0.41, 0.25)
				"grass": return Color(0.47, 0.60, 0.37)
				"field": return Color(0.70, 0.63, 0.43)
				"urban": return Color(0.64, 0.61, 0.55)
	return fallback

static func land_class_color(cls: String, fallback: Color) -> Color:
	match cls:
		"water": return Color(0.30, 0.50, 0.60)
		"forest": return Color(0.27, 0.41, 0.25)
		"grass": return Color(0.47, 0.60, 0.37)
		"field": return Color(0.70, 0.63, 0.43)
		"urban": return Color(0.64, 0.61, 0.55)
	return fallback

## land_color with each polygon's outer-ring bounds (`bounds`: min at
## 2i, max at 2i+1) tested first, inclusively, so the answer is the same.
static func land_color_bboxes(point: Vector2, land: Array, bounds: PackedVector2Array,
		fallback: Color) -> Color:
	for i in land.size():
		var poly: Dictionary = land[i]
		var lo := bounds[i * 2]
		var hi := bounds[i * 2 + 1]
		if point.x < lo.x or point.x > hi.x or point.y < lo.y or point.y > hi.y:
			continue
		if point_in_polygon(point, poly["points"]):
			match str(poly["class"]):
				"water": return Color(0.30, 0.50, 0.60)
				"forest": return Color(0.27, 0.41, 0.25)
				"grass": return Color(0.47, 0.60, 0.37)
				"field": return Color(0.70, 0.63, 0.43)
				"urban": return Color(0.64, 0.61, 0.55)
	return fallback

## Moved to MaterialLibrary.sampled_roof_color; thin wrapper for
## existing callers (tests). Projects samples via satellite_uv.
static func sampled_roof_color(data: LocationData, wx: float, wz: float,
		size_x: float, size_z: float) -> Color:
	return MaterialLibrary.sampled_roof_color(data, wx, wz, size_x, size_z,
		Callable(TerrainBuilder, "satellite_uv"))

## True offset (metres, viewpoint at origin) of the landmark's real
## site. Falls back to LANDMARK_POS when the data carries no site
## (older tests, hand-built LocationData).
static func landmark_site_xz(data: LocationData) -> Vector2:
	if data.has_landmark_site:
		return WorldScale.xz_from_latlon(data.landmark_lat, data.landmark_lon,
			data.latitude, data.longitude)
	return LANDMARK_POS

## Where the model stands: its true site (T5.2). The v1 framing clamp
## (pulled into ≤95 units, pushed out to 38) and the sqrt apparent-size
## rescale are deleted — View360 frames the landmark by camera spawn
## and initial look instead (View360.spawn_for).
static func landmark_world_pos(data: LocationData) -> Vector2:
	return landmark_site_xz(data)

## Ground Y under a landmark footprint anywhere out to the far rings:
## GroundTruth inside the detailed extent, the far-terrain blend surface
## outside it (the lowest of centre + 4 footprint corners, so a base on
## the coarse ring never floats).
static func site_ground_y(data: LocationData, ground: GroundTruth,
		x: float, z: float, half: float = 0.0) -> float:
	var surf := {}
	var lo := INF
	for o in [Vector2.ZERO, Vector2(half, half), Vector2(-half, half),
			Vector2(half, -half), Vector2(-half, -half)]:
		var p := Vector2(x, z) + (o as Vector2)
		if ground.is_inside(p.x, p.y) or data.far_heights.size() != data.far_grid_size * data.far_grid_size:
			lo = minf(lo, ground.height_at_world(p.x, p.y))
		else:
			if surf.is_empty():
				surf = FarTerrainBuilder._surface(data)
			lo = minf(lo, FarTerrainBuilder._blend_height(data, ground, surf, p.x, p.y))
	return lo

static func _landmark(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var pos := landmark_world_pos(data)
	var root := LandmarkBuilder.build(data.landmark_type)
	if RenderQuality.ultra_desktop(data.quality_preset):
		LandmarkLights.dress(root, data.landmark_type)
		LandmarkShader.upgrade(root)
	var entry := LocationData.entry_for_type(data.landmark_type)
	var half := minf(LandmarkSites.clear_m(entry) * 0.5, 45.0) if entry.has("clear_m") else 20.0
	root.position = Vector3(pos.x, _hero_y(data, ground, pos.x, pos.y, entry, half), pos.y)
	root.rotation.y = -deg_to_rad(float(entry.get("yaw_deg", 0.0)))
	LandmarkTerrain.stitch(root, ground, data.landmark_type)
	root.set_meta("lod_layer", "Landmarks")
	return root

## Base Y: `absolute` uses base_asl_m, `sea` uses ASL zero, `water` uses
## mapped water (local DEM when absent), else the lowest footprint ground,
## raised by `base_drop_m` for a model hung below its origin (a dam
## whose crest is y = 0 but whose toe stands on the canyon floor).
static func _hero_y(data: LocationData, ground: GroundTruth, x: float, z: float,
		entry: Dictionary, half: float) -> float:
	if entry.has("base_half_m"):
		half = float(entry["base_half_m"]) * WorldScale.metres_to_units()
	if str(entry.get("base", "")) == "absolute":
		return ground.render_y(float(entry["base_asl_m"]))
	if str(entry.get("base", "")) == "sea":
		return ground.render_y(0.0)
	if str(entry.get("base", "")) == "water":
		if is_equal_approx(ground.water_level_m, -3.0):
			return ground.water_level_at(x, z)
		var fallback := site_ground_y(data, ground, x, z, half)
		return ground.water_level_at(x, z, fallback) if ground.is_inside(x, z) else fallback
	return site_ground_y(data, ground, x, z, half) - 0.3 + float(entry.get("base_drop_m", 0.0))

static func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var mi := _add(parent, _cyl(radius * 0.8, radius, 1.0, 6), mat)
	var dir := to - from
	var length := dir.length()
	var y_axis := dir / length
	var x_axis := Vector3.UP.cross(y_axis).normalized()
	if x_axis.length() < 0.01:
		x_axis = Vector3.RIGHT
	var z_axis := x_axis.cross(y_axis).normalized()
	x_axis = y_axis.cross(z_axis).normalized()
	mi.transform = Transform3D(
		Basis(x_axis * radius, y_axis * length, z_axis * radius),
		(from + to) / 2.0)

## Moved to MaterialLibrary.leaf_card_texture; thin wrapper.
static func _leaf_card_texture() -> Texture2D:
	return MaterialLibrary.leaf_card_texture()

## Moved to VegetationBuilder._broadleaf; thin wrapper for the
## WaterBuilder quay rows (water_builder.gd is untouched by T1.1c).
static func _broadleaf(root: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		leaves: Array, trunk_mat: Material, season: int = LocationData.Season.SUMMER) -> void:
	VegetationBuilder._broadleaf(root, pos, rng, leaves, trunk_mat, season)
