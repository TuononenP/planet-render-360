class_name CellBatches
extends RefCounted

## Shared parts of the per-cell MultiMesh batching that parked cars and
## marina boats use for their near/far model switch: bucketing by kind and
## square cell, the merged bounds both batches of a cell share, and the
## visibility range LodRing must leave alone.

## `items` bucketed as "<kind>_<cx>_<cz>" by `at_of(item) -> Vector3` and
## `kind_of(item) -> String`, in `cell`-unit squares; an INF cell gives
## one bucket per kind.
static func group(items: Array, cell: float, at_of: Callable, kind_of: Callable) -> Dictionary:
	var out := {}
	for item in items:
		var at: Vector3 = at_of.call(item)
		var cx := 0 if is_inf(cell) else floori(at.x / cell)
		var cz := 0 if is_inf(cell) else floori(at.z / cell)
		var key := "%s_%d_%d" % [kind_of.call(item), cx, cz]
		if not out.has(key):
			out[key] = []
		(out[key] as Array).append(item)
	return out

## Bounds of `local` placed at every transform. Visibility ranges measure
## from the AABB centre, so a cell's near and far batches share these to
## switch at the same distance.
static func bounds(transforms: Array, local: AABB) -> AABB:
	var out := AABB()
	for i in transforms.size():
		var box: AABB = (transforms[i] as Transform3D) * local
		out = box if i == 0 else out.merge(box)
	return out

## Draws `mmi` from `begin` to `end` (world units; 0 end = no limit).
static func ranged(mmi: MultiMeshInstance3D, begin: float, end: float) -> void:
	# LodRing would clear the ranges and draw both meshes at every distance.
	mmi.set_meta("lod_own", true)
	mmi.visibility_range_begin = begin
	mmi.visibility_range_end = end
