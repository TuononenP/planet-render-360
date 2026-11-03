extends SceneTree

## Headless shape, material, registry and geometry budgets for Espoo additions.
func _init() -> void:
	var failures: Array[String] = []
	for entry in LandmarkRegistryEspooHero.entries():
		var model := Node3D.new()
		var type := str(entry["type"])
		if not LandmarkBuilder.is_bespoke(type):
			failures.append(type + " has no registered bespoke builder")
		if LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), str(entry["name"])) != type:
			failures.append(type + " cannot be found by name")
		match type:
			"otaniemi_chapel": LandmarkFhEspoo.otaniemi_chapel(model)
			"aalto_university_main": LandmarkFhEspoo.aalto_main(model)
			"tapiola_church": LandmarkFhEspoo.tapiola_church(model)
			"tapiola_central_tower": LandmarkFhEspoo.keskustorni(model)
			"weegee": LandmarkFhEspoo.weegee(model)
		var bounds := AABB()
		var first := true
		var tris := 0
		if model.get_child_count() < 3 or model.get_child_count() > 10:
			failures.append(type + " must merge geometry by material")
		for part in model.get_children():
			var mesh := (part as MeshInstance3D).mesh
			var box := mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			var arrays := mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			tris += vertices.size() / 3
			for v in vertices:
				if not v.is_finite():
					failures.append(type + " has non-finite vertices")
			var mat := mesh.surface_get_material(0) as StandardMaterial3D
			if mat == null or mat.albedo_texture == null:
				failures.append(type + " lacks textured materials")
		if absf(bounds.end.y - float(entry["height_m"])) > 0.5:
			failures.append("%s height %.2f differs from registry %.2f" % [type, bounds.end.y, entry["height_m"]])
		if bounds.position.y < -0.1:
			failures.append(type + " sinks below ground")
		if maxf(absf(bounds.position.x), absf(bounds.end.x)) > float(entry["clear_m"]) \
				or maxf(absf(bounds.position.z), absf(bounds.end.z)) > float(entry["clear_m"]):
			failures.append(type + " extends beyond its clearance")
		if tris < 1000 or tris > 150000:
			failures.append("%s triangle count %d outside budget" % [type, tris])
		print("ESPOO MODEL %s: %.2f m, %d tris, %d merged parts" % [type, bounds.end.y, tris, model.get_child_count()])
		model.free()
	if failures.is_empty():
		print("ESPOO HERO LANDMARKS OK")
		quit(0)
	else:
		for f in failures:
			printerr("ESPOO HERO FAIL: ", f)
		quit(1)
