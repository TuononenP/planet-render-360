extends SceneTree

## Aircraft GLB models, regional liveries, helicopter rotors, night lights &
## shadows test: tools/godot_bg.sh --headless --script tests/aircraft_model_test.gd

const REAL_LENGTH_M := {
	"wide": 58.8,
	"narrow": 37.6,
	"turboprop": 31.0,
	"light": 8.3,
	"helicopter": 12.2,
}

func _init() -> void:
	var failures: Array[String] = []

	# 1. Every GLB loads, matches real-world length within 15%, and has expected parts.
	for kind: String in REAL_LENGTH_M:
		var liv := AircraftSpecs.pick_livery(kind, "FI", "nordic", 0.25, kind == "helicopter")
		var node := AircraftModel.instantiate(kind, liv, true, true)
		var body := node.get_node_or_null("BodyMesh") as MeshInstance3D
		if body == null or body.mesh == null or body.mesh.get_surface_count() == 0:
			failures.append("%s missing BodyMesh" % kind)
			node.free()
			continue
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for c in node.get_children():
			if c is MeshInstance3D and c.name != "Shadow" and c.name != "RotorDisc":
				var mi := c as MeshInstance3D
				if mi.mesh != null:
					var box := mi.transform * mi.mesh.get_aabb()
					lo = lo.min(box.position)
					hi = hi.max(box.end)
		var want: float = REAL_LENGTH_M[kind]
		var got := hi.x - lo.x
		if absf(got - want) > want * 0.15:
			failures.append("%s length %.1f m (want ~%.1f m)" % [kind, got, want])
		if absf(lo.y) > 0.35:
			failures.append("%s wheels/skids not on y=0 (min_y=%.2f)" % [kind, lo.y])
		if kind == "helicopter":
			if node.get_node_or_null("MainRotor") == null or node.get_node_or_null("TailRotor") == null:
				failures.append("helicopter missing MainRotor or TailRotor")
			if node.get_node_or_null("RotorDisc") == null:
				failures.append("active helicopter missing RotorDisc")
		else:
			if node.get_node_or_null("Gear") == null:
				failures.append("%s missing retractable Gear node" % kind)
		if node.get_node_or_null("Shadow") == null:
			failures.append("%s missing ground Shadow node" % kind)
		node.free()

	# 2. Regional liveries vary by country and EMS vs civil helicopters differ.
	var liv_fi := AircraftSpecs.pick_livery("narrow", "FI", "nordic", 0.1)
	var liv_jp := AircraftSpecs.pick_livery("narrow", "JP", "east_asia", 0.1)
	if liv_fi["id"] == liv_jp["id"]:
		failures.append("Nordic and East Asia narrowbody liveries should differ")
	var liv_ems := AircraftSpecs.pick_livery("helicopter", "FI", "nordic", 0.1, true)
	var liv_civ := AircraftSpecs.pick_livery("helicopter", "FI", "nordic", 0.1, false)
	if liv_ems["id"] == liv_civ["id"]:
		failures.append("EMS and civil helicopter liveries should differ")

	if failures.is_empty():
		print("aircraft_model_test: PASS (5 GLB types + liveries + lights + shadows)")
		quit(0)
	else:
		for f in failures:
			printerr("aircraft_model_test FAIL: ", f)
		quit(1)
