extends SceneTree

## The Oculus replaces its own mapped dome without removing adjacent towers.
func _init() -> void:
	var entry := LocationData.entry_for_type("wtc_oculus")
	var errors: Array[String] = []
	if entry.is_empty() or float(entry.get("clear_m", INF)) >= 30.0:
		errors.append("Oculus needs a small, registered clearance")
	if not LandmarkBuilder.is_bespoke("wtc_oculus"):
		errors.append("Oculus needs its bespoke model")
	var root := LandmarkBuilder.build("wtc_oculus")
	var parts := LandmarkBuilder.parts(root)
	if parts.size() < 2:
		errors.append("Oculus glass and ribs must be merged by material")
	var bounds := AABB()
	for part in parts:
		bounds = bounds.merge(part.mesh.get_aabb())
	if bounds.size.x < 100.0 or bounds.size.x > 115.0 or bounds.size.z < 30.0 \
			or bounds.size.z > 50.0 or bounds.end.y < 28.0 or bounds.end.y > 32.0:
		errors.append("Oculus model dimensions are incorrect: %s" % bounds)
	root.free()
	if errors.is_empty():
		print("NYC OCULUS OK: registered, merged and bounded")
		quit(0)
	else:
		for error in errors:
			printerr("NYC OCULUS FAIL: ", error)
		quit(1)
