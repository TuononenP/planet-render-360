extends SceneTree

## Headless: every vessel model builds at its length with an immersed hull,
## stays inside a triangle budget, and its far prototype is cheaper.
var failures: Array[String] = []

func _init() -> void:
	var hull := VesselMaterials.paint("#2d3b4a")
	# model, length, beam, height, max triangles
	for c in [["liner", 250.0, 31.0, 50.0, 40000], ["passenger", 50.0, 8.0, 12.0, 8000],
			["tall_ship", 60.0, 9.5, 32.0, 6000], ["houseboat", 14.0, 4.2, 4.5, 2000],
			["motor_yacht", 24.0, 0.0, 0.0, 3000], ["motor_yacht", 11.0, 0.0, 0.0, 2500],
			["sail_yacht", 12.0, 0.0, 0.0, 3000], ["runabout", 7.0, 0.0, 0.0, 2000]]:
		var near := VesselPrototypes.geometry(c[0], c[1], c[2], c[3], hull, true, true, 0.9)
		var far := VesselPrototypes.geometry(c[0], c[1], c[2], c[3], hull, false, true, 0.9)
		_check(near.triangle_count() > 200 and near.triangle_count() <= int(c[4]), "%s %s m: %d triangles outside budget" % [c[0], c[1], near.triangle_count()])
		_check(far.triangle_count() < near.triangle_count(), "%s far geometry must be cheaper" % c[0])
		var root := Node3D.new()
		var box := AABB()
		for part in near.commit(root):
			box = box.merge(part.mesh.get_aabb()) if box.size != Vector3.ZERO else part.mesh.get_aabb()
		_check(box.position.y < -0.05, "%s must have an immersed hull" % c[0])
		_check(absf(box.size.x - float(c[1])) / float(c[1]) < 0.02 or box.size.x >= float(c[1]) * 0.98, "%s length %.1f vs %.1f" % [c[0], box.size.x, c[1]])
		root.free()
	for kind in VesselPrototypes.KINDS:
		var near_mesh := VesselPrototypes.mesh(kind)
		var far_mesh := VesselPrototypes.mesh(kind + "_far")
		_check(near_mesh.get_surface_count() >= 3 and far_mesh.get_surface_count() <= near_mesh.get_surface_count(), "%s prototype surfaces" % kind)
	if failures.is_empty():
		print("VESSEL MODELS OK: lengths, drafts, budgets, far prototypes")
		quit(0)
	else:
		for f in failures:
			printerr("VESSEL MODELS FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
