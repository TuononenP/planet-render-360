extends SceneTree

## Standalone asset test, also works when the rest of the project cannot compile.
const Models = preload("res://scripts/generation/car_models.gd")

func _init() -> void:
	var failures: Array[String] = []
	for kind in ["sedan", "hatch", "wagon", "suv", "van"]:
		var car := Models.mesh(kind)
		if car == null:
			failures.append("%s asset is missing" % kind)
			continue
		var box := car.get_aabb()
		if box.size.x < 3.8 or box.size.x > 5.1 or box.size.z < 1.5 or box.size.z > 2.2 \
				or box.size.y < 1.2 or box.size.y > 2.1 or absf(box.position.y) > 0.01:
			failures.append("%s bounds are not a grounded, +X car: %s" % [kind, box])
		if car.get_surface_count() != 4:
			failures.append("%s must have body, glass, lights and wheels" % kind)
		else:
			if not car.surface_get_material(0) is ShaderMaterial:
				failures.append("%s paint must use instance color" % kind)
			for i in range(1, 4):
				if not car.surface_get_material(i) is StandardMaterial3D:
					failures.append("%s non-paint surface %d must not use paint color" % [kind, i])
		if Models.mesh(kind) != car:
			failures.append("%s should share its mesh" % kind)
	if failures.is_empty():
		print("CAR MODELS OK: five grounded, scaled models with paint and shared materials")
		quit(0)
	else:
		for failure in failures:
			printerr("CAR MODELS FAIL: ", failure)
		quit(1)
