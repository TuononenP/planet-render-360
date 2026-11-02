extends SceneTree

## Headless: godot --headless --script tests/landmark_ultra_lod_test.gd
## Desktop Ultra's denser landmark LOD0 (LandmarkMesh.lathe under
## MaterialLibrary.hi_res): round forms take twice the segments, faceted
## ones keep their sides, and the model's bounds (true height and
## footprint) do not move.

func _init() -> void:
	var failures: Array[String] = []
	var tris := {}
	var boxes := {}
	for hi in [false, true]:
		MaterialLibrary.hi_res = hi
		var hero := LandmarkBuilder.build("salute")
		var n := 0
		for mi in LandmarkBuilder.parts(hero):
			for s in mi.mesh.get_surface_count():
				n += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		tris[hi] = n
		boxes[hi] = LandmarkLights.local_aabb(hero)
		hero.free()
	MaterialLibrary.hi_res = false
	if int(tris[true]) <= int(tris[false]) * 1.2:
		failures.append("Ultra's Salute should carry denser domes: %d vs %d vertices" % [tris[true], tris[false]])
	var a: AABB = boxes[false]
	var b: AABB = boxes[true]
	if absf(a.size.y - b.size.y) > 0.05 or absf(a.size.x - b.size.x) > a.size.x * 0.02 \
			or absf(a.size.z - b.size.z) > a.size.z * 0.02:
		failures.append("denser LOD0 must keep the true bounds: %s vs %s" % [a.size, b.size])
	var lm := LandmarkMesh.new()
	lm.use("K", StandardMaterial3D.new())
	MaterialLibrary.hi_res = true
	lm.spire("K", Vector3.ZERO, 2.0, 10.0)
	MaterialLibrary.hi_res = false
	var probe := Node3D.new()
	var mis := lm.commit(probe)
	# A 4-sided spire: 4 faces either way (the lathe's faceted path).
	if (mis[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 40:
		failures.append("a square spire must keep its four sides on Ultra")
	probe.free()
	if failures.is_empty():
		print("LANDMARK ULTRA LOD OK: %d -> %d Salute vertices, bounds kept, faceted forms untouched" % [tris[false], tris[true]])
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK ULTRA LOD FAIL: ", f)
		quit(1)
