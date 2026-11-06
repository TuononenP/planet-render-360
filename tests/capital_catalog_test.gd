extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var names := {}
	var country_codes := {}
	for row in CapitalCatalog.ROWS:
		var code := str(row[0])
		var label := str(row[1])
		var key := code + ":" + label.to_lower()
		if names.has(key):
			errors.append("duplicate capital " + key)
		names[key] = true
		country_codes[code] = true
		if absf(float(row[3])) > 90.0 or absf(float(row[4])) > 180.0:
			errors.append("invalid coordinates " + key)
	if country_codes.size() < 190:
		errors.append("capital catalog does not cover enough countries")
	for key in ["BI:gitega", "TZ:dodoma", "GQ:ciudad de la paz", "PW:ngerulmud",
			"ZA:pretoria", "ZA:cape town", "ZA:bloemfontein", "BO:sucre", "BO:la paz",
			"SZ:lobamba", "LK:sri jayewardenepura kotte"]:
		if not names.has(key):
			errors.append("missing " + key)
	for term in ["Gitega", "Ngerulmud", "Ciudad de la Paz", "Dodoma"]:
		if LocationData.suggestions_for(term).is_empty():
			errors.append("capital is not searchable: " + term)
	var picks := LocationData.quick_picks()
	if picks.size() != PresetViews.ROWS.size() + CapitalCatalog.additional_places().size():
		errors.append("capital quick picks are missing")
	var places := {}
	for place in LocationData.known_places():
		places[str(place["name"]).to_lower()] = place
	for pick in picks:
		var place: Dictionary = places.get(str(pick[1]).to_lower(), {})
		if not place.is_empty() and Vector2(float(pick[2]), float(pick[3])) != Vector2(float(place["lat"]), float(place["lon"])):
			errors.append("search and quick pick coordinates differ: " + str(pick[1]))
	if errors.is_empty():
		print("CAPITAL CATALOG OK: %d locations across %d country/territory codes" % [CapitalCatalog.ROWS.size(), country_codes.size()])
		quit(0)
	else:
		for error in errors:
			printerr("CAPITAL CATALOG FAIL: ", error)
		quit(1)
