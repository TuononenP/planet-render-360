extends SceneTree

## Vatican City landmark batch: godot --headless --script tests/vatican_landmarks_test.gd
## Offline. Each type is registered, found by its name, builds a bespoke
## model of 2..16 textured parts within its registry height, and stays
## inside its clearing radius (clear_m).

const TYPES := ["apostolic_palace", "paul_vi_audience_hall", "governorate_palace", "vatican_gardens",
	"leonine_wall"]
const MAX_TRIS := 150000

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	for type in TYPES:
		var entry := LocationData.entry_for_type(type)
		_check(not entry.is_empty(), "%s is not registered" % type)
		if entry.is_empty():
			continue
		_check(LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), str(entry["name"])) == type,
			"searching '%s' should give %s" % [entry["name"], type])
		_check(LandmarkBuilder.is_bespoke(type), "%s has no bespoke builder" % type)
		var root := LandmarkBuilder.build(type)
		var parts := LandmarkBuilder.parts(root)
		_check(parts.size() >= 2 and parts.size() <= 16, "%s should be 2..16 parts, got %d" % [type, parts.size()])
		var top := 0.0
		var reach := 0.0
		var tris := 0
		for m in parts:
			var mat := m.mesh.surface_get_material(0) as StandardMaterial3D
			_check(mat != null and mat.albedo_texture != null, "%s part %s should use a textured PBR material" % [type, m.name])
			var box := m.transform * m.mesh.get_aabb()
			top = maxf(top, box.end.y)
			for corner in [box.position, box.end, Vector3(box.position.x, 0, box.end.z), Vector3(box.end.x, 0, box.position.z)]:
				reach = maxf(reach, Vector2(corner.x, corner.z).length())
			tris += m.mesh.surface_get_array_len(0) / 3
		_check(tris <= MAX_TRIS, "%s has %d triangles" % [type, tris])
		var want := float(entry["height_m"])
		_check(absf(top - want) <= maxf(2.0, want * 0.03), "%s should stand %.1f m tall, got %.1f m" % [type, want, top])
		var clear := float(entry.get("clear_m", 0.0))
		_check(reach <= clear + 15.0, "%s reaches %.0f m but clears only %.0f m" % [type, reach, clear])
		print("  %s: top %.1f m, reach %.0f m, %d parts, %d tris" % [type, top, reach, parts.size(), tris])
		root.free()
	# The Sistine entry no longer claims the palace's and museums' names.
	var sistine := LocationData.entry_for_type("sistine_chapel")
	for alias in sistine.get("aliases", []):
		_check(str(alias) != "vatican museums" and str(alias) != "apostolic palace",
			"the Sistine Chapel should not claim '%s'" % alias)
	if failures.is_empty():
		print("VATICAN LANDMARKS OK: %d types" % TYPES.size())
		quit(0)
	else:
		for f in failures:
			printerr("VATICAN LANDMARKS FAIL: ", f)
		quit(1)
