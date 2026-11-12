extends SceneTree

## An offset preset eye receives the full tree mesh before the map origin.
func _init() -> void:
	var root := Node3D.new()
	var plan := {"pos": [Vector3.ZERO, Vector3(700, 0, 0)],
		"sp": ["plane", "plane"],
		"scale": [Vector2.ONE, Vector2.ONE], "real": [true, true]}
	var ctx := {"m2u": 1.0, "full_r": 100.0, "mid_r": 200.0, "budget": 1,
		"eye": Vector2(700, 0), "season": LocationData.Season.SUMMER,
		"snow": 0.0, "sway": 0.0, "biome": "temperate"}
	VegetationBuilder._emit(root, plan, ctx)
	var found := false
	for node in root.find_children("VegTrees_*", "MultiMeshInstance3D", true, false):
		if str(node.name).contains("_lod0_"):
			var origins: PackedVector3Array = node.get_meta("origins")
			found = origins.size() == 1 and origins[0] == Vector3(700, 0, 0)
	root.free()
	if not found:
		printerr("TREE EYE LOD FAIL: the eye-nearest tree did not receive the full mesh")
		quit(1)
	else:
		print("TREE EYE LOD OK")
		quit(0)
