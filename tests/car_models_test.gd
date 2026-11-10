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
			if not car.surface_get_material(0) is ShaderMaterial \
					or (car.surface_get_material(0) as ShaderMaterial).shader != CarPaint.shader():
				failures.append("%s paint must use instance color (CarPaint)" % kind)
			for i in range(1, 4):
				if not car.surface_get_material(i) is StandardMaterial3D:
					failures.append("%s non-paint surface %d must not use paint color" % [kind, i])
				else:
					_check_finish(kind, car.surface_get_material(i) as StandardMaterial3D, failures)
		if Models.mesh(kind) != car:
			failures.append("%s should share its mesh" % kind)
		_check_body_texture(kind, failures)
	for name in ["wheel", "lights"]:
		var texture := load("res://assets/vehicles/%s.jpg" % name) as Texture2D
		if texture == null or not texture.get_image().has_mipmaps():
			failures.append("%s texture should have mipmaps" % name)
	if failures.is_empty():
		print("CAR MODELS OK: five grounded, scaled models with paint and shared materials")
		quit(0)
	else:
		for failure in failures:
			printerr("CAR MODELS FAIL: ", failure)
		quit(1)

## Glass mirrors at a grazing look; rims are metal where the wheel map is bright.
func _check_finish(kind: String, m: StandardMaterial3D, failures: Array[String]) -> void:
	if m.albedo_texture == null and m.roughness > 0.06:
		failures.append("%s glass should be smooth enough to mirror the street" % kind)
	elif m.albedo_texture != null and m.albedo_texture.resource_path.ends_with("wheel.jpg") \
			and m.metallic_texture == null:
		failures.append("%s wheel rims should read metal from the wheel map" % kind)

func _check_body_texture(kind: String, failures: Array[String]) -> void:
	var path := "res://assets/vehicles/%s_body.png" % kind
	var source := Image.load_from_file(path)
	var texture := load(path) as Texture2D
	if source == null or texture == null:
		failures.append("%s paint texture is missing" % kind)
		return
	var imported := texture.get_image()
	if not imported.has_mipmaps():
		failures.append("%s paint texture should have mipmaps" % kind)
		return
	# Alpha is a paint mask, not transparency: RGB outside it must survive import.
	var samples := 0
	for y in range(0, source.get_height(), 13):
		for x in range(0, source.get_width(), 13):
			var before := source.get_pixel(x, y)
			if before.a > 0.0:
				continue
			var after := imported.get_pixel(x, y)
			if absf(before.r - after.r) + absf(before.g - after.g) + absf(before.b - after.b) > 0.02:
				failures.append("%s paint mask import changed unpainted RGB" % kind)
				return
			samples += 1
	if samples == 0:
		failures.append("%s paint mask has no unpainted samples" % kind)
