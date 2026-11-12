extends SceneTree

## Headless: godot --headless --script tests/snow_guard_test.gd
## Snow guards (Finnish eave rails and roof-ladder rungs) were removed:
## their rails spanned the centroid frame of concave roofs, hovering over
## courtyards and past walls. Pitched roofs must carry no eave-rail lead
## geometry, even when the data still carries the key.

func _init() -> void:
	_run()

## A U-block (40 x 30 m, 20 x 10 m courtyard opening south): the
## centroid sits in the base bar, but the old south eave rail ran past the
## courtyard mouth, off the roof.
func _ring() -> PackedVector2Array:
	var m := WorldScale.metres_to_units()
	var ring := PackedVector2Array()
	for p in [Vector2(-20, -15), Vector2(20, -15), Vector2(20, 15), Vector2(10, 15),
			Vector2(10, 5), Vector2(-10, 5), Vector2(-10, 15), Vector2(-20, 15)]:
		ring.append(p * m)
	return ring

func _look() -> Dictionary:
	return {"kind": "apartments", "region": "nordic", "tower": "", "chimney": 0.0,
		"dormer": 0.0, "equip": 0.0,
		"relief": {"snow_guard": true, "string_course": true, "granite_plinth": true}}

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var ring := _ring()
	if not RingGeometry.point_in_ring(RingGeometry.interior_point(ring), ring):
		failures.append("the U-block fixture bails BuildingDetail's in-ring check")
	var m := WorldScale.metres_to_units()
	var lead: Material = BuildingDetail._mat("lead")
	for shape in ["gabled", "hipped", "mansard"]:
		var root := Node3D.new()
		BuildingDetail.add(root, ring, 20.0 * m, 20.0 * m, shape, 4.0 * m,
			_look(), null, null, 0.3, true)
		for c in root.get_children():
			var mesh := (c as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				if mesh.surface_get_material(s) == lead:
					failures.append("%s roof carries snow-guard rails" % shape)
		root.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("SNOW GUARD OK: no eave rails on pitched roofs")
		quit(0)
	else:
		for f in failures:
			printerr("SNOW GUARD FAIL: ", f)
		quit(1)
