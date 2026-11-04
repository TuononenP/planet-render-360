extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	if ArchitectureStyle.kind_for({"kind": "yes", "use": "ferry_terminal"}, "dense", 3000.0) != "civic":
		errors.append("a mapped ferry terminal must not be classified as apartments")
	var parent := {"osm_id": "way:38868195"}
	var hall := {}
	NycWaterfrontMaterials.apply(parent, {"osm_id": "way:213853440"}, hall)
	var slips := {}
	NycWaterfrontMaterials.apply(parent, {"osm_id": "way:213853441"}, slips)
	if hall.get("material", "") != "glass" or slips.get("material", "") != "metal":
		errors.append("Whitehall's mapped hall/slips must default to glass and steel")
	var mapped := {"material": "brick", "roof_material": "copper"}
	NycWaterfrontMaterials.apply(parent, mapped, mapped)
	if mapped["material"] != "brick" or mapped["roof_material"] != "copper":
		errors.append("explicit finishes must win")
	var other := {}
	NycWaterfrontMaterials.apply({"osm_id": "way:1"}, {}, other)
	if not other.is_empty():
		errors.append("terminal defaults must not affect other waterfront buildings")
	if errors.is_empty():
		print("NYC WATERFRONT MATERIALS OK: mapped hall/slips, explicit precedence, exact site")
		quit(0)
	else:
		for error in errors:
			printerr("NYC WATERFRONT MATERIALS FAIL: ", error)
		quit(1)
