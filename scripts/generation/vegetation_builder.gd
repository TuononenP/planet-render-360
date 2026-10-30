class_name VegetationBuilder
extends RefCounted

## Vegetation subtree (T5.1 + the vegetation half of T7.2).
## Real data first: every OSM `natural=tree` node is planted at its true
## position; OSM forest polygons fill as continuous canopy; parks /
## grass / orchards / cemeteries / wetland get class-specific density.
## The procedural random scatter survives only as the absence fallback
## (no tree nodes and no green polygons — plan §2.2 no-faked-fidelity).
## Exclusion: VegetationMask footprint/road/water rasters + GroundTruth
## water depth, so no trunk stands in a building, carriageway or water.
## Species mix from TreeSpecies.biome_for (region, latitude, altitude)
## and the setting; season tints/bare deciduous from data.season.
## Rendering: one MultiMeshInstance3D per species x LOD x 45° sector
## (sectors give frustum culling in the 360 view), LOD by distance from
## the fixed viewpoint at build time: full mesh / mid mesh / cross-card
## impostor. Budgets follow PRD §3.4 (F1 800 / F2 2,500 / F3 6,000
## mesh trees; impostors IMPOSTOR_FACTOR x). Street props: StreetProps.
## Contract: docs/world-model-contract.md §4. Sizes in true metres via
## WorldScale.metres_to_units().

const SECTORS := 8
## [Fast, Balanced, High, Ultra] ring radii (m) and mesh-tree budgets.
const FULL_R := [60.0, 120.0, 140.0, 220.0]
const MID_R := [150.0, 300.0, 300.0, 600.0]
const MESH_BUDGET := [800, 2500, 2500, 6000]
const FOREST_SPACING_M := 6.0
## Impostor cap = mesh budget x this (4 tris each, one draw per
## species/sector): far forests must read as continuous canopy.
const IMPOSTOR_FACTOR := 6

static var last_stats: Dictionary = {}

## Vegetation subtree: real trees + land-cover fill + street props.
static func build_vegetation(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var t0 := Time.get_ticks_msec()
	var root := Node3D.new()
	root.name = "Vegetation"
	var ctx := _context(data, ground)
	var mask := VegetationMask.new(data, ground)
	var plan := {"pos": [], "sp": [], "scale": [], "real": []}
	_plant_osm_trees(plan, data, ground, mask, ctx)
	_fill_cover(plan, data, ground, mask, ctx)
	var fallback := data.trees.is_empty() and mask.green.is_empty()
	if fallback:
		_fallback_scatter(plan, data, ground, mask, ctx)
	var stats := _emit(root, plan, ctx)
	stats["fallback"] = fallback
	stats["props"] = StreetProps.build(root, data, ground, mask, ctx)
	stats["ms"] = Time.get_ticks_msec() - t0
	last_stats = stats
	root.set_meta("stats", stats)
	return root

static func _context(data: LocationData, ground: GroundTruth) -> Dictionary:
	var p := clampi(data.quality_preset, 0, 3)
	var biome := TreeSpecies.biome_for_data(data)
	var winter := data.season == LocationData.Season.WINTER
	var cold := biome in ["alpine", "boreal"]
	var noise := FastNoiseLite.new()
	noise.seed = data.seed_value + 77
	noise.frequency = 0.012 / WorldScale.metres_to_units()
	return {
		"preset": p, "fidelity": MaterialLibrary.fidelity_for_preset(p),
		"m2u": WorldScale.metres_to_units(), "biome": biome, "season": data.season,
		# Snow loads where the viewpoint sits above the season's CHELSA
		# snow line; without climate data, winter in a cold biome.
		"snow": 0.55 if (ClimateModel.snowy_at_viewpoint(data, data.season) if ClimateModel.has(data) \
			else winter and cold) else 0.0,
		"sway": 0.0035 if p == 3 else 0.0,
		"full_r": float(FULL_R[p]), "mid_r": float(MID_R[p]),
		"budget": int(MESH_BUDGET[p]), "noise": noise,
		"treeline": ClimateModel.treeline_m(data) if ClimateModel.has(data) else TreeSpecies.treeline_m(data.latitude),
		"landmark": TerrainBuilder.landmark_world_pos(data) if data.landmark_type != "none" else Vector2(INF, INF),
	}

static func _hash(x: float, z: float, salt: float) -> float:
	var v := sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	return v - floor(v)

## Ground ok for a trunk at XZ (units): extent, water, exclusion bits.
static func _site_ok(x: float, z: float, ground: GroundTruth, mask: VegetationMask,
		bits: int, margin_m: float, ctx: Dictionary) -> bool:
	if mask.blocked(x, z, bits, margin_m):
		ctx["rej_mask"] = int(ctx.get("rej_mask", 0)) + 1
		return false
	if ground.water_at(x, z) > 0.0:
		ctx["rej_water"] = int(ctx.get("rej_water", 0)) + 1
		return false
	var lm: Vector2 = ctx["landmark"]
	if Vector2(x, z).distance_to(lm) < 48.0 * float(ctx["m2u"]):
		return false
	return true

static func _add(plan: Dictionary, x: float, z: float, ground: GroundTruth, sp: String,
		size: float, spread: float, real: bool) -> void:
	# Plan columns are plain Arrays (Packed arrays in a Dictionary are
	# copied on read, so appends would be lost).
	(plan["pos"] as Array).append(Vector3(x, ground.height_at_world(x, z), z))
	(plan["sp"] as Array).append(sp)
	(plan["scale"] as Array).append(Vector2(size, spread))
	(plan["real"] as Array).append(1 if real else 0)

## Species for a site: biome mix for the setting, patchy (low-frequency
## noise) so forests form stands rather than salt-and-pepper; near the
## treeline conifers take over and shrink.
static func _species_at(x: float, z: float, setting: String, ground: GroundTruth,
		ctx: Dictionary) -> Array:
	var noise: FastNoiseLite = ctx["noise"]
	var u := clampf(0.5 + noise.get_noise_2d(x, z) * 0.9 + (_hash(x, z, 3.1) - 0.5) * 0.45, 0.0, 0.999)
	var sp := TreeSpecies.pick(TreeSpecies.mix(str(ctx["biome"]), setting), u)
	var size := 1.0
	var asl := ground.asl_y(ground.height_at_world(x, z))
	var tl: float = ctx["treeline"]
	if asl > tl - 350.0 and str(ctx["biome"]) in ["alpine", "boreal", "temperate", "dry_coast"]:
		sp = "spruce" if _hash(x, z, 5.5) < 0.75 else "scots_pine"
		size = clampf((tl - asl) / 350.0, 0.35, 1.0)
	return [sp, size]

# --- Real OSM trees ------------------------------------------------------

static func _plant_osm_trees(plan: Dictionary, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> void:
	for t in data.trees:
		if not (t is Dictionary):
			continue
		var x := float(t.get("x", 0.0))
		var z := float(t.get("z", 0.0))
		# Real trees are trusted: only a footprint, the carriageway core,
		# or water rejects them (pavement trees sit near both).
		if not _site_ok(x, z, ground, mask,
				VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, 0.0, ctx):
			continue
		var gid := mask.cover_at(x, z)
		if gid >= 0:
			mask.green[gid]["real_trees"] = int(mask.green[gid]["real_trees"]) + 1
		var setting := "street" if mask.built_fraction(x, z) > 0.04 else "park"
		var pick := _species_at(x, z, setting, ground, ctx)
		# Street trees are pollarded/younger than open-grown ones.
		var size: float = float(pick[1]) * (0.85 if setting == "street" else 1.0)
		_add(plan, x, z, ground, pick[0], size, 1.0, true)

# --- Land-cover fill -----------------------------------------------------

## Jittered-grid fill per distance band. The near band (≤ mid ring)
## uses FOREST_SPACING_M (closed canopy, Ø 6-9 m crowns) unless the
## mesh budget forces wider spacing; the far band is sized to the
## impostor budget with proportionally broader crowns so the canopy
## still reads closed.
static func _fill_cover(plan: Dictionary, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> void:
	if mask.green.is_empty():
		return
	var m2u: float = ctx["m2u"]
	var mid_u := float(ctx["mid_r"]) * m2u
	var cell_m2 := VegetationMask.CELL_M * VegetationMask.CELL_M
	# Forest area per band (m²) from the cover raster (sampled stride 2).
	var near_a := 0.0
	var far_a := 0.0
	var stride := 2
	for cz in range(0, mask.n, stride):
		for cx in range(0, mask.n, stride):
			var gid := mask.cover[cz * mask.n + cx] - 1
			if gid < 0 or str(mask.green[gid]["class"]) != "forest":
				continue
			var x := (float(cx) + 0.5) * mask.cell - mask.half
			var z := (float(cz) + 0.5) * mask.cell - mask.half
			if Vector2(x, z).length() <= mid_u:
				near_a += cell_m2 * stride * stride
			else:
				far_a += cell_m2 * stride * stride
	var budget: int = ctx["budget"]
	var real_n := (plan["pos"] as Array).size()
	var near_cap := maxf(float(budget - real_n) * 0.8, float(budget) * 0.3)
	var s_near := maxf(FOREST_SPACING_M, sqrt(near_a / near_cap)) if near_a > 0.0 else FOREST_SPACING_M
	var s_far := maxf(FOREST_SPACING_M * 1.3, sqrt(far_a / (float(budget * IMPOSTOR_FACTOR) * 0.8))) if far_a > 0.0 else 12.0
	ctx["forest_spacing"] = [s_near, s_far]
	_fill_band(plan, ground, mask, ctx, s_near, 0.0, mid_u)
	_fill_band(plan, ground, mask, ctx, s_far, mid_u, INF)

static func _fill_band(plan: Dictionary, ground: GroundTruth, mask: VegetationMask,
		ctx: Dictionary, spacing_m: float, r_in: float, r_out: float) -> void:
	var m2u: float = ctx["m2u"]
	var s := spacing_m * m2u
	var lim := minf(r_out, mask.half * 1.42)
	var steps := int(ceil(minf(lim, mask.half) / s))
	var crown := clampf(spacing_m / FOREST_SPACING_M, 1.0, 2.0)
	var dens_scale := (spacing_m / FOREST_SPACING_M) * (spacing_m / FOREST_SPACING_M)
	var noise: FastNoiseLite = ctx["noise"]
	for gz in range(-steps, steps + 1):
		for gx in range(-steps, steps + 1):
			var x := (float(gx) + (_hash(gx, gz, 1.0) - 0.5) * 0.8) * s
			var z := (float(gz) + (_hash(gx, gz, 2.0) - 0.5) * 0.8) * s
			var d := Vector2(x, z).length()
			if d < r_in or d > r_out:
				continue
			var gid := mask.cover_at(x, z)
			if gid < 0:
				continue
			var g: Dictionary = mask.green[gid]
			var cls := str(g["class"])
			var p := 1.0
			var setting := "forest"
			var size := 1.0
			var spread := crown
			match cls:
				"forest":
					p = 0.92
				"orchard":
					p = 0.55
					size = 0.4
					spread = 1.0
					setting = "orchard"
				"cemetery":
					p = 0.07 * dens_scale
					setting = "park"
				"wetland":
					p = 0.04 * dens_scale
					setting = "rural"
				_:
					# Grass: real tree nodes win — a park already mapped
					# tree by tree gets no synthetic additions.
					var cells := maxf(float(g["cells"]), 1.0)
					var mapped := float(g["real_trees"]) / (cells * 2.25)
					if mapped > 1.0 / 2500.0:
						continue
					var town := mask.built_fraction(x, z) > 0.03
					setting = "park" if town else "rural"
					# Clumped: groves where the noise is high, open lawn
					# / meadow elsewhere.
					var grove := noise.get_noise_2d(x * 1.7, z * 1.7)
					p = (0.32 if grove > 0.25 else 0.025) if town else (0.2 if grove > 0.45 else 0.006)
					p *= dens_scale
					spread = 1.0
			if _hash(x, z, 9.0) > p:
				continue
			if not _site_ok(x, z, ground, mask, VegetationMask.BUILDING
					| VegetationMask.ROAD_EDGE | VegetationMask.WATER, 0.8, ctx):
				continue
			if ground.slope_at(x, z) > 1.25:
				continue
			var pick := _species_at(x, z, setting if setting != "orchard" else "rural", ground, ctx)
			var sp: String = pick[0]
			if setting == "orchard":
				sp = "olive" if str(ctx["biome"]) in ["mediterranean", "arid"] else "oak"
			if ground.asl_y(ground.height_at_world(x, z)) > float(ctx["treeline"]):
				continue
			# Broader far crowns: part taller, part wider (no squat blobs).
			_add(plan, x, z, ground, sp, size * float(pick[1]) * pow(spread, 0.35),
				pow(spread, 0.65), false)

## Absence fallback (no OSM trees and no green land cover at all): the
## v1 count of trees scattered off buildings/roads/water.
static func _fallback_scatter(plan: Dictionary, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 21
	var urban := not data.buildings.is_empty() or data.relief_metres < 120.0
	var count := RenderSettings.vegetation_count_for(data.quality_preset, urban)
	var m2u: float = ctx["m2u"]
	var r_max := ground.extent_m * 0.93 * m2u
	for i in count:
		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(60.0 * m2u, r_max)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		if not _site_ok(x, z, ground, mask, VegetationMask.BUILDING
				| VegetationMask.ROAD_EDGE | VegetationMask.WATER, 1.0, ctx):
			continue
		if ground.asl_y(ground.height_at_world(x, z)) > float(ctx["treeline"]):
			continue
		var pick := _species_at(x, z, "street" if urban else "rural", ground, ctx)
		_add(plan, x, z, ground, pick[0], pick[1], 1.0, false)

# --- Instancing ----------------------------------------------------------

## LOD by distance (budget-demoted farthest-first), then one MultiMesh
## per species/LOD/sector. Returns counts for tests/captures.
static func _emit(root: Node3D, plan: Dictionary, ctx: Dictionary) -> Dictionary:
	var pos: Array = plan["pos"]
	var sps: Array = plan["sp"]
	var scl: Array = plan["scale"]
	var real: Array = plan["real"]
	var m2u: float = ctx["m2u"]
	var full_u := float(ctx["full_r"]) * m2u
	var mid_u := float(ctx["mid_r"]) * m2u
	var budget: int = ctx["budget"]
	var order: Array = range(pos.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var pa: Vector3 = pos[a]
		var pb: Vector3 = pos[b]
		return pa.x * pa.x + pa.z * pa.z < pb.x * pb.x + pb.z * pb.z)
	var groups := {}
	var mesh_trees := 0
	var imp_trees := 0
	var dropped := 0
	var lod_counts := [0, 0, 0]
	for i in order:
		var p: Vector3 = pos[i]
		var d := Vector2(p.x, p.z).length()
		var lod := 0 if d <= full_u else (1 if d <= mid_u else 2)
		if lod < 2 and mesh_trees >= budget:
			lod = 2
		if lod == 2 and imp_trees >= budget * IMPOSTOR_FACTOR:
			dropped += 1
			continue
		if lod < 2:
			mesh_trees += 1
		else:
			imp_trees += 1
		lod_counts[lod] += 1
		var sector := int(floor((atan2(p.z, p.x) + PI) / TAU * float(SECTORS))) % SECTORS
		var key := "%s|%d|%d" % [str(sps[i]), lod, sector]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(i)
	var season: int = ctx["season"]
	var nodes := 0
	for key in groups:
		var parts: PackedStringArray = (key as String).split("|")
		var sp := parts[0]
		var lod := int(parts[1])
		var ids: Array = groups[key]
		var spec := TreeSpecies.spec(sp)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = TreeMeshLibrary.mesh(sp, lod, season, float(ctx["snow"]), float(ctx["sway"]))
		mm.instance_count = ids.size()
		var origins := PackedVector3Array()
		for k in ids.size():
			var i: int = ids[k]
			var p: Vector3 = pos[i]
			var h1 := _hash(p.x, p.z, 11.0)
			var h2 := _hash(p.x, p.z, 12.0)
			var h3 := _hash(p.x, p.z, 13.0)
			var hv := float(spec.get("h_var", 0.2))
			var sc: Vector2 = scl[i]
			var sy := sc.x * (1.0 + (h1 - 0.5) * 2.0 * hv)
			var sxz := sy * sc.y * (0.9 + h2 * 0.2)
			var basis := Basis(Vector3.UP, h3 * TAU)
			var tilt_axis := Vector3(cos(h1 * 9.0), 0, sin(h1 * 9.0))
			basis = Basis(tilt_axis, (h2 - 0.5) * 0.06) * basis
			basis = basis.scaled(Vector3(sxz, sy, sxz) * m2u)
			mm.set_instance_transform(k, Transform3D(basis, p))
			origins.append(p)
			mm.set_instance_color(k, _instance_tint(sp, season, h1, h2, h3))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "VegTrees_%s_lod%d_s%s" % [sp, lod, parts[2]]
		# Trunk-base origins for tests/captures (headless MultiMesh
		# storage is a dummy that keeps no transforms).
		mmi.set_meta("origins", origins)
		if lod == 2:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)
		nodes += 1
	var real_n := 0
	for r in real:
		real_n += int(r)
	return {"trees": lod_counts[0] + lod_counts[1] + lod_counts[2], "real": real_n,
		"lod": lod_counts, "dropped": dropped, "nodes": nodes,
		"biome": ctx["biome"], "spacing": ctx.get("forest_spacing", []),
		"rejected": [ctx.get("rej_mask", 0), ctx.get("rej_water", 0)]}

## ±10% hue/value variance (PRD §4.4); autumn deciduous crowns spread
## from yellow to russet; spring slightly lighter.
static func _instance_tint(sp: String, season: int, h1: float, h2: float, h3: float) -> Color:
	var v := 0.9 + h1 * 0.2
	var c := Color(v * (0.95 + h2 * 0.1), v, v * (0.95 + h3 * 0.1))
	if season == LocationData.Season.AUTUMN and not TreeSpecies.is_evergreen(sp):
		if h2 < 0.3:
			c = Color(1.0, 0.62 + h3 * 0.15, 0.55)  # russet
		elif h2 > 0.75:
			c = Color(0.92, 1.05, 0.8)  # late green-yellow
	return c

# --- v1 compatibility ----------------------------------------------------

static var _canopy_mesh: SphereMesh
static var _card_mats_by_season: Dictionary = {}
static var _card_mesh: QuadMesh

static func _canopy() -> SphereMesh:
	if _canopy_mesh == null:
		_canopy_mesh = SphereMesh.new()
		_canopy_mesh.radial_segments = 14
		_canopy_mesh.rings = 10
		_canopy_mesh.radius = 1.0
		_canopy_mesh.height = 2.0
	return _canopy_mesh

static func _card_mat(season: int, variant: int) -> Material:
	var key := LocationData.clamp_season(season)
	if not _card_mats_by_season.has(key):
		var mats: Array = []
		for b in (MaterialLibrary.leaves(key) as Array).slice(0, 3):
			var m := StandardMaterial3D.new()
			m.albedo_texture = MaterialLibrary.leaf_card_texture()
			m.albedo_color = (b as StandardMaterial3D).albedo_color
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.42
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.95
			mats.append(m)
		_card_mats_by_season[key] = mats
	var mats2: Array = _card_mats_by_season[key]
	return mats2[variant % mats2.size()]

## DEPRECATED single-tree node helper (v1 shape), kept only for the
## TerrainBuilder._broadleaf wrapper signature; the world uses the
## instanced species above.
static func _broadleaf(root: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		leaves: Array, trunk_mat: Material, season: int = LocationData.Season.SUMMER) -> void:
	var trunk := TerrainBuilder._add(root, TerrainBuilder._cyl(0.09, 0.17, 1.15, 8), trunk_mat)
	trunk.position = pos + Vector3(0, 0.57, 0)
	var r := rng.randf_range(0.72, 1.12)
	var centre := pos + Vector3(0, 1.15 + r * 0.85, 0)
	var core := TerrainBuilder._add(root, _canopy(), leaves[rng.randi_range(0, leaves.size() - 1)])
	core.scale = Vector3(r * 0.40, r * 0.33, r * 0.40)
	core.position = centre
	if _card_mesh == null:
		_card_mesh = QuadMesh.new()
		_card_mesh.size = Vector2(3.6, 3.1)
	var mat := _card_mat(season, rng.randi_range(0, 2))
	for k in 3:
		var card := TerrainBuilder._add(root, _card_mesh, mat)
		card.scale = Vector3(r, r, r)
		card.rotation.y = float(k) * PI / 3.0 + rng.randf_range(-0.2, 0.2)
		card.position = centre + Vector3(0, (float(k) - 1.0) * 0.22, 0)
