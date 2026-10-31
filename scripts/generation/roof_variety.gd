class_name RoofVariety
extends RefCounted

## Per-building roof variety. Roofs share a handful of materials (one per
## set and quantized tint), so a district of slate read as one sheet. Each
## real building's roof surfaces now carry one vertex colour, seeded by
## the building's position, that roof materials multiply into albedo:
## some roofs newer and darker, some weathered paler, some warmer (rust,
## lichen) or cooler (zinc). No extra material or draw call; impostor and
## far masses carry no colour (white). The same on every tier, and the
## tints average 1 so the roofscape's mean colour does not move (AC-12).

## ± lightness and ± warm/cool shift of a roof's tint.
const SPREAD := 0.18
const WARMTH := 0.05

## Tags `m` as a roof material: RoofSnow overlays it while snow lies, and
## it multiplies the per-building vertex tint into its albedo.
static func mark(m: BaseMaterial3D) -> void:
	m.set_meta("roof", true)
	m.vertex_color_use_as_albedo = true

static func is_roof(m: Material) -> bool:
	return m != null and m.has_meta("roof")

## Tint for the building at x/z (internal units); stable per building.
static func tint_for(x: float, z: float) -> Color:
	var l := 1.0 + (TerrainBuilder._hash(x * 0.37 + 5.0, z * 0.91) * 2.0 - 1.0) * SPREAD
	var w := (TerrainBuilder._hash(z * 1.7 + 11.0, x * 0.23) * 2.0 - 1.0) * WARMTH
	return Color(l * (1.0 + w), l, l * (1.0 - w))

## Tints the roof surfaces of `root`'s children from index `first` on (one
## building's meshes) with the building's colour, and its wall surfaces
## with WallVariety's.
static func tint(root: Node, first: int, x: float, z: float) -> void:
	var c := tint_for(x, z)
	for k in range(first, root.get_child_count()):
		var mi := root.get_child(k) as MeshInstance3D
		if mi == null or not (mi.mesh is ArrayMesh):
			continue
		var mesh := mi.mesh as ArrayMesh
		var hit := false
		for s in mesh.get_surface_count():
			var sm := mi.material_override if mi.material_override != null \
				else mesh.surface_get_material(s)
			hit = hit or is_roof(sm) or WallVariety.is_wall(sm)
		if hit:
			mi.mesh = _recoloured(mesh, mi.material_override, c,
				WallVariety.tint_for(x, z))

## `mesh` rebuilt with colour `c` on its roof surfaces, from its kept
## arrays (no server read-back on the build thread).
static func _recoloured(mesh: ArrayMesh, over: Material, c: Color, wall_c: Color) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var mat := mesh.surface_get_material(s)
		var arrays := MeshArrays.surface(mesh, s).duplicate()
		var active := over if over != null else mat
		if is_roof(active):
			var cols := PackedColorArray()
			cols.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
			cols.fill(c)
			arrays[Mesh.ARRAY_COLOR] = cols
		elif WallVariety.is_wall(active):
			arrays[Mesh.ARRAY_COLOR] = WallVariety.colours(arrays[Mesh.ARRAY_VERTEX], wall_c)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		if mat != null:
			out.surface_set_material(s, mat)
		MeshArrays.keep_surface(out, arrays)
	return out
