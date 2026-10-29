class_name LodRing
extends RefCounted

## T7.1 — LOD rings over the true 2400 m extent (plan Open Q1: one
## extent on every preset; presets differ only in the ring radii below).
##
## Rings, in metres from the viewpoint:
##  - near (0 .. DETAIL_M[preset]): full geometry — roofline detail
##    (BuildingDetail chimneys / dormers / rooftop plant) is drawn.
##  - mid (.. the 1200 m extent edge): building masses, merged at build
##    time per material and MERGE_CELL_M cell (merge_buildings), with
##    FacadeMaterials' shared distant set past full_detail_radius_m;
##    vegetation to TREES_M[preset].
##  - far (past the extent): FarTerrainBuilder rings (RING_SEGS per
##    preset) and the real-data far city (FarCityBuilder, T5.4/T7.3:
##    batched textured masses per octant x distance band, shown up to
##    FAR_CITY_M[preset]); real buildings past the preset cap are
##    batched impostor masses (lod_impostor), never dropped.
##
## The 360 camera never translates, so ring assignment is static: it is
## written once per build as GeometryInstance3D visibility ranges with a
## FADE_FRAC hysteresis margin (fade-self where the renderer supports
## it). A preset switch only re-runs apply(): nothing is rebuilt, moved
## or recoloured (PRD AC-12) — the merge is preset-independent.

## Roofline-detail reach per preset (Fast, Balanced, High, Ultra).
const DETAIL_M: Array[float] = [200.0, 300.0, 450.0, 700.0]
## Vegetation reach per preset; Ultra keeps every tree in the extent.
const TREES_M: Array[float] = [600.0, 800.0, 1100.0, 1700.0]
## Far-city reach per preset: bands whose inner radius (meta far_r0)
## lies past it are hidden. Built identically on every preset.
const FAR_CITY_M: Array[float] = [4500.0, 7500.0, 12001.0, 12001.0]
## Build-time merge cell for building masses (frustum culling still
## works per cell; draw calls scale with cells × materials, not
## buildings).
const MERGE_CELL_M := 400.0
## Hysteresis band as a fraction of each ring radius.
const FADE_FRAC := 0.12
## Area batches larger than this (merged scatters, MultiMesh fields)
## have no meaningful single distance; they are never ranged.
const MAX_RANGED_SIZE_M := 2.0 * MERGE_CELL_M

static func detail_m(preset: int) -> float:
	return DETAIL_M[RenderSettings.clamp_preset(preset)]

static func trees_m(preset: int) -> float:
	return TREES_M[RenderSettings.clamp_preset(preset)]

static func far_city_m(preset: int) -> float:
	return FAR_CITY_M[RenderSettings.clamp_preset(preset)]

## Build time (preset-independent): every building mesh adopted flat
## into `root` (meta lod_layer == "Buildings") is appended into one
## mesh per (cell, detail flag, material, shadow mode, vertex format),
## baking its transform into the vertices, and the originals are freed.
## Returns the number of meshes merged away.
static func merge_buildings(root: Node3D) -> int:
	var groups := {}
	var merged: Array[MeshInstance3D] = []
	for c in root.get_children():
		if not (c is MeshInstance3D) or str(c.get_meta("lod_layer", "")) != "Buildings":
			continue
		var mi := c as MeshInstance3D
		if mi.mesh == null or mi.get_child_count() > 0:
			continue
		var centre := mi.transform * mi.mesh.get_aabb().get_center()
		var cell := Vector2i(floori(centre.x / MERGE_CELL_M), floori(centre.z / MERGE_CELL_M))
		var detail := bool(mi.get_meta("lod_detail", false))
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			var fmt := str(mi.mesh.surface_get_format(s)) if mi.mesh is ArrayMesh \
				else mi.mesh.get_class()
			var key := "%d,%d|%s|%d|%d|%s" % [cell.x, cell.y, detail,
				mat.get_instance_id() if mat != null else 0, mi.cast_shadow, fmt]
			if not groups.has(key):
				var st := SurfaceTool.new()
				groups[key] = {"st": st, "mat": mat, "cell": cell,
					"detail": detail, "shadow": mi.cast_shadow}
			(groups[key]["st"] as SurfaceTool).append_from(mi.mesh, s, mi.transform)
		merged.append(mi)
	var n := 0
	for key in groups:
		var g: Dictionary = groups[key]
		var mesh := (g["st"] as SurfaceTool).commit()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var out := MeshInstance3D.new()
		out.name = "LodCell_%d_%d_%d" % [g["cell"].x, g["cell"].y, n]
		out.mesh = mesh
		out.material_override = g["mat"]
		out.cast_shadow = g["shadow"]
		out.set_meta("lod_layer", "Buildings")
		out.set_meta("lod_detail", g["detail"])
		root.add_child(out)
		n += 1
	for mi in merged:
		root.remove_child(mi)
		mi.free()
	return merged.size()

## Any time, incl. a live preset switch: visibility ranges per layer.
## Only ranges change — transforms and materials are untouched.
## Layers are the builders' subtree names (meta lod_layer on children
## adopted flat, else the world child's own name: FarTerrain, Water).
static func apply(root: Node, preset: int) -> void:
	for c in root.get_children():
		_apply(c, preset, str(c.get_meta("lod_layer", c.name)))

static func _apply(node: Node, preset: int, layer: String) -> void:
	var l := str(node.get_meta("lod_layer", layer))
	if node is GeometryInstance3D:
		_range(node as GeometryInstance3D, preset, l)
		_shadow(node as GeometryInstance3D, preset, l)
	for c in node.get_children():
		_apply(c, preset, l)

## Shadow casters per ring (a §3.4 shadow column, never layout/hue):
## flush roads and water never cast (they were ~40% of Paris shadow-
## pass triangles); far terrain casts valley-wall shadows on High+.
static func _shadow(gi: GeometryInstance3D, preset: int, layer: String) -> void:
	if layer == "Roads" or layer == "Water" or layer == "FarCity":
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif layer == "FarTerrain":
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON \
			if preset >= RenderSettings.Preset.HIGH \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _range(gi: GeometryInstance3D, preset: int, layer: String) -> void:
	if layer == "FarCity":
		# A whole band in or out (its AABB centre is no distance): a
		# 1 m range end hides it, 0 shows it.
		var shown := float(gi.get_meta("far_r0", 0.0)) < far_city_m(preset)
		gi.visibility_range_begin = 0.0
		gi.visibility_range_end = 0.0 if shown else 1.0
		gi.visibility_range_end_margin = 0.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		return
	var end := 0.0
	if layer == "Buildings" and bool(gi.get_meta("lod_detail", false)):
		end = detail_m(preset)
	elif layer == "Vegetation":
		var size := gi.get_aabb().size
		if maxf(size.x, size.z) <= MAX_RANGED_SIZE_M:
			end = trees_m(preset)
	gi.visibility_range_begin = 0.0
	gi.visibility_range_end = end
	gi.visibility_range_end_margin = end * FADE_FRAC
	gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF \
		if end > 0.0 else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

## Per-frame render counters for perf evidence (T7.1 validation).
static func frame_stats() -> Dictionary:
	return {
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"fps": Performance.get_monitor(Performance.TIME_FPS),
	}
