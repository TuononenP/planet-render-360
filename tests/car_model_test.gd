extends SceneTree

## Headless: godot --headless --script tests/car_model_test.gd
## Procedural cars (CarModel): every kind builds near and far, grounded
## and facing +X at its spec's size, with outward faces, the paint on
## CarPaint and the far mesh a fraction of the near one.

func _init() -> void:
	var failures: Array[String] = []
	for kind: String in CarSpecs.KINDS:
		var s := CarSpecs.spec(kind)
		var near := CarModel.mesh(kind)
		var far := CarModel.mesh(kind, true)
		if CarModel.mesh(kind) != near:
			failures.append("%s should share its mesh" % kind)
		var counts: Array[int] = []
		for car: ArrayMesh in [near, far]:
			var box := car.get_aabb()
			if absf(box.size.x - float(s["len"])) > 0.06 or absf(box.position.y) > 0.01 \
					or absf(box.size.y - float(s["h"])) > 0.08 or box.size.z < float(s["wid"]) - 0.12 \
					or box.size.z > float(s["wid"]) + 0.4 or absf(box.get_center().x) > 0.05:
				failures.append("%s bounds are not a grounded, +X car of its spec: %s" % [kind, box])
			var names := {}
			var tris := 0
			for si in car.get_surface_count():
				names[car.surface_get_name(si)] = car.surface_get_material(si)
				var arr := car.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				tris += v.size() / 3
				for t in range(0, v.size(), 3):
					# Front faces as Godot winds them: clockwise about the normal.
					if (v[t + 1] - v[t]).cross(v[t + 2] - v[t]).dot(n[t] + n[t + 1] + n[t + 2]) > 0.0:
						failures.append("%s surface %s has a back-facing triangle" % [kind, car.surface_get_name(si)])
						break
			counts.append(tris)
			for key in ["Paint", "Glass", "Rubber", "Rim", "HeadLamp", "TailLamp"]:
				if not names.has(key):
					failures.append("%s is missing its %s surface" % [kind, key])
			var paint := names.get("Paint") as ShaderMaterial
			if paint == null or paint.shader != CarPaint.shader():
				failures.append("%s paint must use the instance colour (CarPaint)" % kind)
			var glass := names.get("Glass") as StandardMaterial3D
			if glass == null or glass.roughness > 0.06:
				failures.append("%s glass should be smooth enough to mirror the street" % kind)
		if counts[0] > 12000 or counts[1] > 1600 or counts[1] * 4 > counts[0]:
			failures.append("%s triangle budget: near %d, far %d" % [kind, counts[0], counts[1]])
	if failures.is_empty():
		print("CAR MODEL OK: every kind lofts a grounded body near and far, faces outward, paint on CarPaint")
		quit(0)
	else:
		for failure in failures:
			printerr("CAR MODEL FAIL: ", failure)
		quit(1)
