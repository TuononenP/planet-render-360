class_name FarSampler
extends RefCounted

## Far-terrain sampling for FarTerrainBuilder: DEM height blending,
## OSM water index and far colour/albedo queries. Mesh building
## (rings, bands, skirt) stays in FarTerrainBuilder.
static func _tile_uv(data: LocationData, span_u: float, wx: float, wz: float) -> Vector2:
	return Vector2(data.far_centre_frac.x + wx / span_u,
		data.far_centre_frac.y + wz / span_u)

## Bilinear DEM sample at tile fractions; outside clamps to the edge
## (flat extension past the tile, never NaN).
static func _sample_far_dem(data: LocationData, u: float, v: float) -> float:
	var grid := data.far_grid_size
	var fu := clampf(u, 0.0, 1.0) * float(grid - 1)
	var fv := clampf(v, 0.0, 1.0) * float(grid - 1)
	var x0 := clampi(int(fu), 0, grid - 2)
	var z0 := clampi(int(fv), 0, grid - 2)
	var tx := fu - float(x0)
	var tz := fv - float(z0)
	var a := lerpf(data.far_heights[z0 * grid + x0],
		data.far_heights[z0 * grid + x0 + 1], tx)
	var b := lerpf(data.far_heights[(z0 + 1) * grid + x0],
		data.far_heights[(z0 + 1) * grid + x0 + 1], tx)
	return lerpf(a, b, tz)

## Ring DEM value at world XZ (T3.7): the far-field DEM rings
## (bilinear, finest wins, edge-faded) over the z8 far grid, with the
## outermost stretch handed back to the z8 grid so the OuterRing edge
## meets the far mesh. No rings (procedural / offline / legacy squash)
## -> the z8 grid alone, as in T3.3.
static func _mid_dem_height(data: LocationData, ground: GroundTruth, span_u: float, x: float, z: float) -> float:
	var uv := _tile_uv(data, span_u, x, z)
	var far_m := _sample_far_dem(data, uv.x, uv.y)
	if data.dem_rings.is_empty():
		return ground.render_y(_sea_floor(ground, far_m))
	var m2u := WorldScale.metres_to_units()
	var d_m := maxf(absf(x), absf(z)) / m2u
	var fade := 1.0 - smoothstep(FarTerrainBuilder.OUTER_RADIUS_M * FarTerrainBuilder.OUTER_FADE, FarTerrainBuilder.OUTER_RADIUS_M, d_m)
	return ground.render_y(_sea_floor(ground,
		FarSurface.height_m(data, x / m2u, z / m2u, far_m, fade)))

## UV-cached variant: caller computed U/V once per vertex for ring sampling.
static func _mid_dem_height_uv(data: LocationData, ground: GroundTruth, span_u: float, x: float, z: float, u: float, v: float) -> float:
	var uv := _tile_uv(data, span_u, x, z)
	var far_m := _sample_far_dem(data, uv.x, uv.y)
	if data.dem_rings.is_empty():
		return ground.render_y(_sea_floor(ground, far_m))
	var m2u := WorldScale.metres_to_units()
	var d_m := maxf(absf(x), absf(z)) / m2u
	var fade := 1.0 - smoothstep(FarTerrainBuilder.OUTER_RADIUS_M * FarTerrainBuilder.OUTER_FADE, FarTerrainBuilder.OUTER_RADIUS_M, d_m)
	return ground.render_y(_sea_floor(ground,
		FarSurface.height_m_uv(data, u, v, far_m, fade)))

## Terrarium encodes ocean BATHYMETRY (Big Sur's shelf reads -2400 m):
## past the detailed sea plane the far surface IS the sea, so heights
## clamp to sea level (T3.7). Legacy-squash/procedural data (the -3.0
## sentinel) passes through. Gap: land below sea level (Dead Sea)
## flattens to 0 m in the far field.
static func _sea_floor(ground: GroundTruth, h_m: float) -> float:
	if is_equal_approx(ground.water_level_m, -3.0):
		return h_m
	return maxf(h_m, 0.0)

## The continuous far surface both rings share: GroundTruth at the
## detailed edge, blending to bilinear DEM over FarTerrainBuilder.BLEND_M, pure DEM past
## that, tucked a lip under the detailed mesh in the overlap. Heights
## are raw (m ASL in true-metre mode, squashed units under the
## pipeline's legacy A/B flag) — the same space the detailed mesh
## renders in, so no datum shift is needed to align the seam.
static func _blend_height(data: LocationData, ground: GroundTruth,
		surf: Dictionary, x: float, z: float) -> float:
	var d := maxf(absf(x), absf(z))
	var s_0: float = surf["s_0"]
	var w := smoothstep(s_0, s_0 + float(surf["blend_u"]), d)
	var dem := _mid_dem_height(data, ground, float(surf["span_u"]), x, z)
	if w >= 1.0:
		return dem  # past the blend band: no ground sample, no lip
	# Carved water channels (GroundTruth waterway carve) are NOT ground
	# the ring may inherit: past the extent the carve clamps outward
	# and the blend turned it into a 190 m cyan trench beside the Aare
	# at Interlaken (water surfaces stop at the extent). Ground deeper
	# than the DEM by more than FarTerrainBuilder.CARVE_TOL_M is lifted to it.
	var g := maxf(ground.height_at_world(x, z),
		dem - FarTerrainBuilder.CARVE_TOL_M * WorldScale.metres_to_units())
	var h := lerpf(g, dem, w)
	var edge_hi: float = surf["edge_hi"]
	var lip := FarTerrainBuilder.INNER_TUCK_M * WorldScale.metres_to_units() \
		* (1.0 - smoothstep(s_0, edge_hi + (edge_hi - s_0), d))
	return h - lip

## UV-cached blend: same but U/V computed once per vertex.
static func _blend_height_uv(data: LocationData, ground: GroundTruth,
		surf: Dictionary, x: float, z: float, u: float, v: float) -> float:
	var d := maxf(absf(x), absf(z))
	var s_0: float = surf["s_0"]
	var w := smoothstep(s_0, s_0 + float(surf["blend_u"]), d)
	var dem := _mid_dem_height_uv(data, ground, float(surf["span_u"]), x, z, u, v)
	if w >= 1.0:
		return dem
	# Carved water channels (GroundTruth waterway carve) are NOT ground
	# the ring may inherit: past the extent the carve clamps outward
	# and the blend turned it into a 190 m cyan trench beside the Aare
	# at Interlaken (water surfaces stop at the extent). Ground deeper
	# than the DEM by more than FarTerrainBuilder.CARVE_TOL_M is lifted to it.
	var g := maxf(ground.height_at_world(x, z),
		dem - FarTerrainBuilder.CARVE_TOL_M * WorldScale.metres_to_units())
	var h := lerpf(g, dem, w)
	var edge_hi: float = surf["edge_hi"]
	var lip := FarTerrainBuilder.INNER_TUCK_M * WorldScale.metres_to_units() \
		* (1.0 - smoothstep(s_0, edge_hi + (edge_hi - s_0), d))
	return h - lip

## OSM water polygons (+ hole rings) as edge-banded PolygonIndex
## entries: far rings test thousands of vertices, and one lagoon polygon
## (Venice: ~15k vertices, a thousand island holes) made a plain
## per-vertex point-in-polygon walk take minutes. Covers lakes/rivers/sea
## inside OSM range; past that the DEM sea rule in _far_water applies.
static func _water_index(data: LocationData) -> Array:
	var out: Array = []
	for poly in data.land_polygons:
		if not (poly is Dictionary):
			continue
		if str(poly.get("class", "")) != "water":
			continue
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		out.append(PolygonIndex.new(pts, poly.get("holes", [])))
	return out

## GroundTruth reuse (1.4b): GroundTruth._land_index already holds a
## PolygonIndex per data.land_polygons entry in the same order, built from
## the same points/holes. Filtering it to class=="water" yields the identical
## Array (same objects, same order, same priority) without rebuilding the
## banded index, and GroundTruth is read-only after _init so sharing is
## thread-safe. Falls back to _water_index(data) when ground is null or has
## no land_index to preserve fingerprint on standalone / test paths.
static func _water_index_from_ground(ground) -> Array:
	if ground == null:
		return []
	# ground is GroundTruth — untyped to avoid load cycle.
	var land: Array = ground._land
	var idx: Array = ground._land_index
	if land.is_empty() or idx.is_empty() or land.size() != idx.size():
		return []
	var out: Array = []
	for k in land.size():
		var poly: Dictionary = land[k] if land[k] is Dictionary else {}
		if str(poly.get("class", "")) != "water":
			continue
		var pi = idx[k]
		if pi != null and not (pi as PolygonIndex).is_empty():
			out.append(pi)
		else:
			# Defensive: skip degenerate (should match _water_index's <3 guard).
			continue
	return out

## Metres ASL reading as open water in true-metre mode (Terrarium
## sea pixels decode to ~0 m). The v1 below-datum rule floods every
## far valley below the viewpoint in true-metre mode (and misses the
## sea entirely at flat coastal sites), so it survives only under the
## pipeline's legacy squash — which compresses all heights toward 3.0
## and marks the water datum exactly -3.0 — where it still applies.
## T3.4 (real water bodies) replaces this whole heuristic.

static func _far_water(h: float, water_level_m: float, in_osm: bool) -> bool:
	if in_osm:
		return true
	if water_level_m == -3.0:
		return h < water_level_m + 1.0
	return h < FarTerrainBuilder.SEA_LEVEL_M

static func _in_osm_water(p: Vector2, index: Array, bounds: Rect2 = Rect2()) -> bool:
	# Early reject via union bounds: saves thousands of polygon_index checks far from water.
	if bounds.has_area() and not bounds.has_point(p):
		return false
	for entry in index:
		if (entry as PolygonIndex).contains(p):
			return true
	return false

## Far colour (T3.7): FarSurface's mountain ramp — by altitude ASL,
## latitude and season, slope rock, OSM/sea water — returned linear.
## Shown only where no imagery drape covers the vertex.
static func far_color_at(data: LocationData, nrm: Vector3, h_asl: float,
		water: bool, x: float, z: float) -> Color:
	return FarSurface.ramp_color(data, nrm, h_asl, water,
		TerrainBuilder._hash(x * 1.3, z * 1.7))

## Cached variant uses precomputed climate_params to avoid per-vertex CHELSA lookups.
static func far_color_at_cached(climate: Dictionary, data: LocationData, nrm: Vector3, h_asl: float,
		water: bool, x: float, z: float) -> Color:
	return FarSurface.ramp_color_cached(climate, nrm, h_asl, water,
		TerrainBuilder._hash(x * 1.3, z * 1.7))

## Seam hook (T3.6/T3.7): the far albedo the rings render at world XZ
## (internal units) — the finest imagery drape covering it, else the
## mountain ramp — LINEAR. GroundMaterial's edge band fades the
## detailed terrain to this (via TerrainBuilder's COLOR.rgb), so the
## near/far hand-off matches the drape, not a separate colour scheme.
static func far_albedo_at(data: LocationData, nrm: Vector3, h_asl: float,
		water: bool, x: float, z: float) -> Color:
	var m2u := WorldScale.metres_to_units()
	var c := FarSurface.drape_albedo(data, x / m2u, z / m2u)
	if c.a > 0.0:
		return c
	return far_color_at(data, nrm, h_asl, water, x, z)

## Union bbox of the water index, for a one-test reject far from OSM.
static func _water_bounds(index: Array) -> Rect2:
	if index.is_empty():
		return Rect2()
	var r: Rect2 = (index[0] as PolygonIndex).bounds()
	for entry in index:
		r = r.merge((entry as PolygonIndex).bounds())
	return r

static func _is_wet(ground: GroundTruth, h_render: float, p: Vector2,
		index: Array, bounds: Rect2) -> bool:
	var in_osm := _in_osm_water(p, index, bounds)
	return _far_water(ground.asl_y(h_render),
		ground.asl_y(ground.water_level_m), in_osm)

## Drape pair (fine, coarse) for a band whose outer radius is reach_m:
## fine = the finest drape fully covering it (else the finest at all),
## coarse = the next coarser one. Drapes are finest-first.
