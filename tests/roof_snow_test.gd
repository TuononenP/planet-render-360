extends SceneTree

## Headless: godot --headless --script tests/roof_snow_test.gd
## Roof snow (RoofSnow): building meshes with a roof material take the
## snow overlay as their own material_overlay while snow lies and drop
## it after, other meshes never; the shared materials themselves are
## never changed (a world is saved to WorldCache on a thread meanwhile).

func _init() -> void:
	var failures: Array[String] = []
	var world := Node3D.new()
	var roof := StandardMaterial3D.new()
	RoofVariety.mark(roof)
	var wall := StandardMaterial3D.new()
	var meshes := []
	for mat in [roof, wall]:
		var bm := BoxMesh.new()
		bm.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = bm
		mi.set_meta("lod_layer", "Buildings")
		world.add_child(mi)
		meshes.append(mi)
	if RoofSnow.apply(world, true) != 1:
		failures.append("one building mesh carries a roof material")
	if (meshes[0] as MeshInstance3D).material_overlay != RoofSnow.overlay() \
			or (meshes[1] as MeshInstance3D).material_overlay != null:
		failures.append("snow should overlay the roofed mesh only")
	if roof.next_pass != null or wall.next_pass != null:
		failures.append("shared materials must stay untouched (the cache save reads them)")
	RoofSnow.apply(world, false)
	if (meshes[0] as MeshInstance3D).material_overlay != null:
		failures.append("the overlay should go when the snow does")
	world.free()
	if failures.is_empty():
		print("ROOF SNOW OK: per-instance overlay on roofed meshes, shared materials untouched")
		quit(0)
	else:
		for f in failures:
			printerr("ROOF SNOW FAIL: ", f)
		quit(1)
