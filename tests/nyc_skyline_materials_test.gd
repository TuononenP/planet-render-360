extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	FacadeMaterials.begin_build()
	var glass := ArchitectureStyle.resolve({"kind": "commercial", "levels": 40, "start_year": 2010},
		"nyc_glass", "dense", 0.2, 1200.0)
	glass["wall_set"] = "glass"
	var historic := ArchitectureStyle.resolve({"kind": "commercial", "levels": 30, "start_year": 1930},
		"nyc_prewar", "dense", 0.2, 1200.0)
	historic["era"] = "nyc_prewar"
	historic["wall_set"] = "limestone"
	for fidelity in [1, 2, 3]:
		var mat := FacadeMaterials.facade_for_building({}, "new_york", 40, fidelity, true, 0.2, glass)
		if str(mat.get_meta("facade_set", "")) != "glass":
			errors.append("resolved glass tower became masonry at fidelity %d" % fidelity)
		mat = FacadeMaterials.facade_for_building({}, "new_york", 30, fidelity, true, 0.2, historic)
		if str(mat.get_meta("facade_set", "")) != "limestone":
			errors.append("prewar stone tower became generic brick at fidelity %d" % fidelity)
		mat = FacadeMaterials.facade_for_building({"material": "concrete"}, "new_york", 30,
			fidelity, true, 0.2, glass)
		if str(mat.get_meta("facade_set", "")) != "concrete":
			errors.append("explicit concrete must override inferred glass")
	if errors.is_empty():
		print("NYC SKYLINE MATERIALS OK: resolved glass, prewar stone, mapped overrides across fidelity tiers")
		quit(0)
	else:
		for error in errors:
			printerr("NYC SKYLINE MATERIALS FAIL: ", error)
		quit(1)
