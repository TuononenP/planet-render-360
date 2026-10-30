class_name FarTerrainBuilder
extends RefCounted

## Distant-terrain backdrop: concentric DEM rings over a sub-horizon
## gap-filler apron (T3.3; contract docs/world-model-contract.md §4).
## build_far returns a "FarTerrain" subtree with four layers:
## - mid ring: a dense concentric-square annulus from the detailed
##   mesh edge out to MID_RADIUS_M, blending GroundTruth edge heights
##   into bilinear DEM, so the near/far seam is continuous;
## - far ring (_far_terrain): the full z8 tile as a grid mesh in TRUE
##   geometry (raw heights, true tile span — the v1 distance boost and
##   centre bury are gone), tucked under the mid ring where they
##   overlap, plus a separate perimeter skirt (_far_skirt) hanging
##   to the apron so the tile edge never reads as a disc;
## - apron (_far_ground): the flat v1 plane kept ONLY as a buried gap
##   filler below every ring (seam pinholes + past-tile-edge views).
## Real data first (plan invariant 3): the rings sample the DEM the
## pipeline fetched; the pipeline's procedural far grid (absence-only)
## flows through the same samplers, so no builder-side procedural
## fallback exists to fight real data. With no far data at all both
## rings are empty and only the apron builds (v1 behaviour).
## T3.7 (far terrain v2): the concentric rings now run from the
## detailed edge to OUTER_RADIUS_M (30 km) in two bands — MidRing (to
## MID_RADIUS_M) and OuterRing — sampling the far-field DEM rings
## (LocationData.dem_rings: ~25 m/px z12 to 9.5 km, ~100 m/px z10 to
## 33 km; FarSurface.height_m) instead of the ~1.7 km z8 grid, at a
## preset-driven density (RING_SEGS) so 2-30 km ridgelines read as
## crisp silhouettes. Albedo is the far imagery drapes
## (LocationData.far_drapes) with a mountain colour ramp
## (FarSurface.ramp_color: rock by slope, snow by altitude + latitude
## + season, forest/meadow below the treeline) only where imagery is
## absent. Past 30 km the z8 far ring takes over (the outer loops fade
## to it so the hand-off is continuous).

## Mid band outer edge (finest drape/DEM ring), metres from the
## viewpoint; the outer band continues to OUTER_RADIUS_M, where the z8
## far ring takes over. Both sit inside their FarFieldFetcher reach.
const MID_RADIUS_M := 9000.0
const OUTER_RADIUS_M := 30000.0
## Outermost ring stretch handed back to the z8 far grid (fraction of
## OUTER_RADIUS_M) so the ring edge meets the far mesh continuously.
const OUTER_FADE := 0.8
## Ground -> DEM blend width past the detailed edge, in metres.
const BLEND_M := 500.0
## Far-grid tuck below the mid surface where they overlap (metres).
const TUCK_M := 25.0
## Mid-ring skirt drop at the mid/far seam (metres). Kept shallow:
## a 150 m drop rendered as a visible beige wall around the city.
const SKIRT_M := 40.0
## Max depth (m) the blend band keeps GroundTruth below the ring DEM;
## deeper is a water carve, not terrain (see _blend_height).
const CARVE_TOL_M := 8.0
## Mid ring tucks this far under the detailed mesh where loop 0
## overlaps it: a subpixel lip that kills z-fighting structurally.
const INNER_TUCK_M := 0.15
## Ring density per preset (Fast..Ultra): segments per square side;
## loops grow geometrically with radial step = RADIAL_ASPECT x the
## tangential step, so cells stay near-square from 400 m to 30 km.
## A LOD knob only — heights come from the same DEM at every preset.
const RING_SEGS: Array[int] = [96, 128, 192, 256]
const RADIAL_ASPECT := 1.5
## Outer-edge skirt drop as a fraction of the ring radius (hides the
## ring/z8 interpolation crack; invisible at 30 km).
const OUTER_SKIRT_FRAC := 0.02

## Far-field subtree: gap-filler apron + mid ring + far ring + far skirt.
static func build_far(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var root := Node3D.new()
	root.name = "FarTerrain"
	root.add_child(_far_ground(data, ground))
	var t0 := Time.get_ticks_msec()
	var bands := _ring_bands(data, ground)
	for band in bands:
		root.add_child(band)
	var farring := _far_terrain(data, ground)
	farring.name = "FarRing"
	root.add_child(farring)
	var skirt := _far_skirt(data, ground)
	skirt.name = "FarSkirt"
	root.add_child(skirt)
	print("FAR-TERRAIN built in %d ms (rings=%d drapes=%d bands=%d)" % [
		Time.get_ticks_msec() - t0, data.dem_rings.size(),
		data.far_drapes.size(), bands.size()])
	return root

## True z8 tile span in metres at the viewpoint latitude. Pure tile
## math (DemFetcher.metres_per_px is a formula, not a fetch). The
## pipeline's far_extent_m (36000, from the v1 9000-unit far_extent)
## matches no real z8 footprint (60-156 km by latitude), so the rings
## derive the span here until the pipeline sets it truly (owner E,
## contract §2.2 far_extent_m). This file no longer reads the
## deprecated far_extent (contract §7 V9, consumer side).
static func far_span_m(data: LocationData) -> float:
	return DemFetcher.metres_per_px(data.latitude, DemFetcher.FAR_ZOOM) \
		* float(DemFetcher.TILE_PX)

## Shared ring geometry, in current internal units: the far-tile span,
## the mid annulus (inner loop one detailed post inside the edge so
## the blend starts under the detailed mesh, outer edge at
## MID_RADIUS_M), and the blend width.
static func _surface(data: LocationData) -> Dictionary:
	var m2u := WorldScale.metres_to_units()
	var extent_u := WorldScale.detailed_extent_units()
	var step_d := extent_u / float(maxi(data.grid_size - 1, 1))
	return {
		"span_u": far_span_m(data) * m2u,
		"s_0": extent_u * 0.5 - step_d,
		"edge_hi": extent_u * 0.5,
		"blend_u": BLEND_M * m2u,
		"r_mid": MID_RADIUS_M * m2u,
		"r1": OUTER_RADIUS_M * m2u,
	}

## World XZ (internal units, viewpoint at origin) -> z8 tile fractions.
## +X = east = tile +u, +Z = south = tile +v (contract §1.1).

const SEA_LEVEL_M := 0.5

# --- Delegators: implementation in FarSampler. ---
static func _tile_uv(data: LocationData, span_u: float, wx: float, wz: float) -> Vector2:
	return FarSampler._tile_uv(data, span_u, wx, wz)

static func _sample_far_dem(data: LocationData, u: float, v: float) -> float:
	return FarSampler._sample_far_dem(data, u, v)

static func _mid_dem_height(data: LocationData, ground: GroundTruth, span_u: float, x: float, z: float) -> float:
	return FarSampler._mid_dem_height(data, ground, span_u, x, z)

static func _sea_floor(ground: GroundTruth, h_m: float) -> float:
	return FarSampler._sea_floor(ground, h_m)

static func _blend_height(data: LocationData, ground: GroundTruth,
		surf: Dictionary, x: float, z: float) -> float:
	return FarSampler._blend_height(data, ground, surf, x, z)

static func _water_index(data: LocationData) -> Array:
	return FarSampler._water_index(data)

static func _far_water(h: float, water_level_m: float, in_osm: bool) -> bool:
	return FarSampler._far_water(h, water_level_m, in_osm)

static func _in_osm_water(p: Vector2, index: Array) -> bool:
	return FarSampler._in_osm_water(p, index)

static func far_color_at(data: LocationData, nrm: Vector3, h_asl: float,
		water: bool, x: float, z: float) -> Color:
	return FarSampler.far_color_at(data, nrm, h_asl, water, x, z)

static func far_albedo_at(data: LocationData, nrm: Vector3, h_asl: float,
		water: bool, x: float, z: float) -> Color:
	return FarSampler.far_albedo_at(data, nrm, h_asl, water, x, z)

static func _water_bounds(index: Array) -> Rect2:
	return FarSampler._water_bounds(index)

static func _is_wet(ground: GroundTruth, h_render: float, p: Vector2,
		index: Array, bounds: Rect2) -> bool:
	return FarSampler._is_wet(ground, h_render, p, index, bounds)

static func _drapes_for(data: LocationData, reach_m: float) -> Array:
	var d := data.far_drapes
	if d.is_empty():
		return [null, null]
	var k := 0
	while k < d.size() - 1 and float(d[k]["reach_m"]) < reach_m:
		k += 1
	return [d[k], d[k + 1] if k + 1 < d.size() else null]

## Apron level: below the lowest detailed-edge post and the lowest
## far post, so the gap filler never slices through real ground. The
## far perimeter skirt hangs to just above this (shared seam).
static func _apron_y(data: LocationData, ground: GroundTruth) -> float:
	var floor_h := INF
	var size := data.grid_size
	for i in size:
		for h in [ground.surface_at_post(i, 0),
				ground.surface_at_post(i, size - 1),
				ground.surface_at_post(0, i),
				ground.surface_at_post(size - 1, i)]:
			floor_h = minf(floor_h, h)
	for h in data.far_heights:
		floor_h = minf(floor_h, ground.render_y(h))
	if floor_h == INF:
		floor_h = ground.water_level_m
	return floor_h - 8.0

static func _far_ground(data: LocationData, ground: GroundTruth) -> MeshInstance3D:
	# Sub-horizon gap filler ONLY: a broad fog-tinted plane below every
	# ring (seam pinholes + past-tile-edge views), never a visible disc.
	var half_span := far_span_m(data) * WorldScale.metres_to_units()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_span * 2.0, half_span * 2.0)
	var mi := TerrainBuilder._add(null, plane,
		TerrainBuilder._mat(Color(0.52, 0.49, 0.39), 1.0))  # hazed apron, PRD §3.3
	mi.position.y = _apron_y(data, ground)
	return mi

## Ring bands (T3.7): concentric-square loops from inside the detailed
## edge to OUTER_RADIUS_M, heights from _blend_height (ground -> DEM
## rings -> z8), split into MidRing (to MID_RADIUS_M, finest drape) and
## OuterRing (coarser drapes) sharing their boundary loop exactly, plus
## a distance-scaled skirt at the outer edge. Normals come from the
## mesh neighbours (one height sample per vertex). Empty (no meshes)
## when there is no far data to blend toward.
static func _ring_bands(data: LocationData, ground: GroundTruth = null) -> Array:
	var grid := data.far_grid_size
	if data.far_heights.size() != grid * grid or grid < 2:
		return []
	if ground == null:
		ground = GroundTruth.new(data)
	var surf := _surface(data)
	var s_0: float = surf["s_0"]
	var r_out: float = surf["r1"]
	var r_mid: float = surf["r_mid"]
	if s_0 <= 0.0 or r_out <= s_0:
		return []
	var m2u := WorldScale.metres_to_units()
	var segs: int = RING_SEGS[clampi(data.quality_preset, 0, RING_SEGS.size() - 1)]
	var per := 4 * segs
	var q := 1.0 + RADIAL_ASPECT * 2.0 / float(segs)
	var radii: Array[float] = []
	var s := s_0
	while s < r_out:
		radii.append(s)
		s *= q
	radii.append(r_out)
	var k_mid := radii.size() - 1
	for k in radii.size():
		if radii[k] >= r_mid:
			k_mid = k
			break
	var loops := radii.size()
	var pos := PackedVector3Array()
	pos.resize(loops * per)
	for k in loops:
		var r := radii[k]
		for side in 4:
			for i in segs:
				var t := (float(i) / float(segs) - 0.5) * 2.0 * r
				var p := Vector2(t, -r)
				if side == 1:
					p = Vector2(r, t)
				elif side == 2:
					p = Vector2(-t, r)
				elif side == 3:
					p = Vector2(-r, -t)
				pos[k * per + side * segs + i] = Vector3(p.x,
					_blend_height(data, ground, surf, p.x, p.y), p.y)
	var normals := PackedVector3Array()
	normals.resize(pos.size())
	var colors := PackedColorArray()
	colors.resize(pos.size())
	var water := _water_index(data)
	var wbounds := _water_bounds(water)
	for k in loops:
		var ki := maxi(k - 1, 0) * per
		var ko := mini(k + 1, loops - 1) * per
		for j in per:
			var v := pos[k * per + j]
			var tan := pos[k * per + (j + 1) % per] - pos[k * per + (j - 1 + per) % per]
			var rad := pos[ko + j] - pos[ki + j]
			var nrm := tan.cross(rad).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			normals[k * per + j] = nrm
			colors[k * per + j] = far_color_at(data, nrm, ground.asl_y(v.y),
				_is_wet(ground, v.y, Vector2(v.x, v.z), water, wbounds), v.x, v.z)
	var out: Array = []
	var mid := _band_mesh(data, pos, normals, colors, per, 0, k_mid,
		_drapes_for(data, MID_RADIUS_M), 0.0)
	mid.name = "MidRing"
	out.append(mid)
	if k_mid < loops - 1:
		var outer := _band_mesh(data, pos, normals, colors, per, k_mid, loops - 1,
			_drapes_for(data, OUTER_RADIUS_M),
			maxf(SKIRT_M, OUTER_RADIUS_M * OUTER_SKIRT_FRAC) * m2u)
		outer.name = "OuterRing"
		out.append(outer)
	return out

## One band mesh over loops k0..k1 of the shared ring vertex arrays,
## with drape UVs (UV fine, UV2 coarse) and an optional outer skirt
## (skirt_u > 0) dropped from loop k1.
static func _band_mesh(data: LocationData, pos: PackedVector3Array,
		normals: PackedVector3Array, colors: PackedColorArray, per: int,
		k0: int, k1: int, drapes: Array, skirt_u: float) -> MeshInstance3D:
	var m2u := WorldScale.metres_to_units()
	var verts := pos.slice(k0 * per, (k1 + 1) * per)
	var nrms := normals.slice(k0 * per, (k1 + 1) * per)
	var cols := colors.slice(k0 * per, (k1 + 1) * per)
	var loops := k1 - k0 + 1
	var indices := PackedInt32Array()
	for k in range(1, loops):
		# Winding matches the shipped grid meshes (Godot front =
		# clockwise): outer-first order, verified against the
		# detailed mesh's geometric-normal sign in the T3.3 probe.
		var inner := (k - 1) * per
		var outer := k * per
		for j in per:
			var j1 := (j + 1) % per
			indices.append_array([outer + j, outer + j1, inner + j,
				outer + j1, inner + j1, inner + j])
	if skirt_u > 0.0:
		# Outer skirt: same XZ as the edge loop, dropped, so the
		# ring/far hand-off never shows a void sliver from any yaw.
		var edge := (loops - 1) * per
		var base := verts.size()
		for j in per:
			var top: Vector3 = verts[edge + j]
			verts.append(Vector3(top.x, top.y - skirt_u, top.z))
			nrms.append(nrms[edge + j])
			cols.append(cols[edge + j])
		for j in per:
			var j1 := (j + 1) % per
			indices.append_array([edge + j, base + j, edge + j1,
				edge + j1, base + j, base + j1])
	var fine: Dictionary = drapes[0] if drapes[0] != null else {}
	var coarse: Dictionary = drapes[1] if drapes[1] != null else {}
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	uvs.resize(verts.size())
	uv2s.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		if not fine.is_empty():
			uvs[i] = FarSurface.drape_uv(data, fine, v.x / m2u, v.z / m2u)
		if not coarse.is_empty():
			uv2s[i] = FarSurface.drape_uv(data, coarse, v.x / m2u, v.z / m2u)
	return FarSurface.drape_mesh(verts, nrms, cols, uvs, uv2s, indices,
		fine.get("texture", null), coarse.get("texture", null), false, data)

## Far ring: the whole z8 tile as a grid mesh in true geometry — raw
## heights at the true tile span, positioned by far_centre_frac (no
## boost, no bury, no datum shift: the heights already share the
## detailed mesh's space). Posts inside the mid ring tuck below the
## mid surface (hidden overlap, no z-fighting); the tile-edge skirt
## is the separate _far_skirt mesh.
## Keeps the v1 grid²-vertex shape (tests build a 16x16 mesh) and the
## empty-mesh-on-absence contract.
static func _far_terrain(data: LocationData, ground: GroundTruth = null) -> MeshInstance3D:
	var grid := data.far_grid_size
	if data.far_heights.size() != grid * grid or grid < 2:
		return MeshInstance3D.new()
	if ground == null:
		ground = GroundTruth.new(data)
	var surf := _surface(data)
	var span_u: float = surf["span_u"]
	var r1: float = surf["r1"]
	var water := _water_index(data)
	var m2u := WorldScale.metres_to_units()
	var step_m := far_span_m(data) / float(grid - 1)
	# Coarsest drape (widest reach) as the far ring's imagery.
	var drape: Dictionary = data.far_drapes[data.far_drapes.size() - 1] \
		if not data.far_drapes.is_empty() else {}
	var uvs := PackedVector2Array()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for z in grid:
		for x in grid:
			var wx := (float(x) / float(grid - 1) - data.far_centre_frac.x) * span_u
			var wz := (float(z) / float(grid - 1) - data.far_centre_frac.y) * span_u
			var raw := _sea_floor(ground, data.far_heights[z * grid + x])
			var h := ground.render_y(raw)
			if maxf(absf(wx), absf(wz)) < r1:
				h = _blend_height(data, ground, surf, wx, wz) - TUCK_M * m2u
			verts.append(Vector3(wx, h, wz))
			var hx0 := _sea_floor(ground, data.far_heights[z * grid + maxi(x - 1, 0)])
			var hx1 := _sea_floor(ground, data.far_heights[z * grid + mini(x + 1, grid - 1)])
			var hz0 := _sea_floor(ground, data.far_heights[maxi(z - 1, 0) * grid + x])
			var hz1 := _sea_floor(ground, data.far_heights[mini(z + 1, grid - 1) * grid + x])
			var run_m := 2.0 * step_m
			var nrm := Vector3(-(hx1 - hx0) / run_m, 1.0,
				-(hz1 - hz0) / run_m).normalized()
			normals.append(nrm)
			var wet := _far_water(raw,
				ground.asl_y(ground.water_level_m),
				_in_osm_water(Vector2(wx, wz), water))
			colors.append(far_color_at(data, nrm, ground.asl_y(ground.render_y(raw)),
				wet, float(x), float(z)))
			uvs.append(FarSurface.drape_uv(data, drape, wx / m2u, wz / m2u) \
				if not drape.is_empty() else Vector2(-1.0, -1.0))
	for z in grid - 1:
		for x in grid - 1:
			var a := z * grid + x
			var b := a + 1
			var c := a + grid
			var d := c + 1
			# T3.7: quads wholly under the rings are dropped — a 1.7 km
			# z8 facet between tucked posts still rose through concave
			# valleys of the 25 m ring surface (dark lumps mid-valley).
			if _inside(verts[a], r1) and _inside(verts[b], r1) \
					and _inside(verts[c], r1) and _inside(verts[d], r1):
				continue
			indices.append_array([a, b, c, b, d, c])
	return FarSurface.drape_mesh(verts, normals, colors, uvs, uvs, indices,
		drape.get("texture", null), null, false, data)

static func _inside(v: Vector3, r: float) -> bool:
	return maxf(absf(v.x), absf(v.z)) < r

## Perimeter skirt for the far ring (separate mesh so _far_terrain
## keeps its exact grid²-vertex shape): the tile edge hangs down to
## just above the apron. The edge can sit near the viewpoint on one
## side (viewpoint near a tile corner) and must read as falling
## ground, never a void band or disc edge. Double-sided: from inside,
## the sightline past a high edge meets the wall, not the void.
static func _far_skirt(data: LocationData, ground: GroundTruth = null) -> MeshInstance3D:
	var grid := data.far_grid_size
	if data.far_heights.size() != grid * grid or grid < 2:
		return MeshInstance3D.new()
	if ground == null:
		ground = GroundTruth.new(data)
	var span_u := far_span_m(data) * WorldScale.metres_to_units()
	var skirt_y := _apron_y(data, ground) + 0.5
	var per: Array[int] = []
	for x in grid:
		per.append(x)
	for z in range(1, grid - 1):
		per.append(z * grid + grid - 1)
	for x in range(grid - 1, -1, -1):
		per.append((grid - 1) * grid + x)
	for z in range(grid - 2, 0, -1):
		per.append(z * grid)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for vi in per:
		var x := vi % grid
		var z := vi / grid
		var wx := (float(x) / float(grid - 1) - data.far_centre_frac.x) * span_u
		var wz := (float(z) / float(grid - 1) - data.far_centre_frac.y) * span_u
		var raw := _sea_floor(ground, data.far_heights[vi])
		var top_y := ground.render_y(raw)
		verts.append(Vector3(wx, top_y, wz))
		verts.append(Vector3(wx, skirt_y, wz))
		var nrm := Vector3(0.0, 0.35, 0.0).normalized()
		normals.append(nrm)
		normals.append(nrm)
		var wet := _far_water(raw, ground.asl_y(ground.water_level_m), false)
		var c := far_color_at(data, Vector3.UP, ground.asl_y(top_y),
			wet, float(x), float(z))
		colors.append(c)
		colors.append(c.darkened(0.25))
	for j in per.size():
		var j1 := (j + 1) % per.size()
		indices.append_array([2 * j, 2 * j1, 2 * j + 1,
			2 * j1, 2 * j1 + 1, 2 * j + 1])
	return TerrainBuilder._colored_mesh(verts, normals, colors, indices, 1.0, true)
