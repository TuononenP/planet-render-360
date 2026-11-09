extends SceneTree

## Offline contract for the Stockholm hero landmarks. No world/cache build.
func _init() -> void:
	var failures: Array[String] = []
	var expected := [
		["hotorg_1", "hötorgsskrapa 1", 61.0],
		["hotorg_2", "hötorgsskrapa 2", 61.0],
		["hotorg_3", "hötorgsskrapa 3", 61.0],
		["hotorg_4", "hötorgsskrapa 4", 61.0],
		["hotorg_5", "hötorgsskrapa 5", 61.0],
		["katarinahissen", "katarinahissen", 42.5],
		["grona_lund_eclipse", "eclipse, gröna lund", 121.0],
		["kastellet_stockholm", "kastellet, stockholm", 20.0],
		["royal_opera_stockholm", "royal swedish opera", 41.5],
		["grand_hotel_stockholm", "grand hôtel stockholm", 30.0],
		["soder_torn", "söder torn", 86.0],
		["riddarhuset_stockholm", "riddarhuset", 25.5],
		["wrangel_palace", "wrangelska palatset", 32.5],
		["bonde_palace", "bondeska palatset", 23.5],
		["nationalmuseum_stockholm", "nationalmuseum stockholm", 33.5],
		["klara_church", "klara kyrka", 116.0],
		["sofia_church_stockholm", "sofia kyrka stockholm", 78.0],
	]
	var extras := LocationData.registry_extras(59.3207, 18.0604, "stockholm_city_hall").map(
		func(e: Dictionary) -> String: return str(e["type"]))
	for item in expected:
		var type := str(item[0])
		var height := float(item[2])
		if LocationData.landmark_for(0.0, 0.0, str(item[1])) != type:
			failures.append("%s alias did not resolve" % type)
		var entry := LocationData.entry_for_type(type)
		if entry.is_empty() or not extras.has(type) or not is_equal_approx(float(entry.get("height_m", 0.0)), height):
			failures.append("%s missing from the preset or has a wrong registry height" % type)
		var root := LandmarkBuilder.build(type)
		var parts := LandmarkBuilder.parts(root)
		var top := 0.0
		for part in parts:
			var bounds := part.transform * part.mesh.get_aabb()
			top = maxf(top, bounds.end.y)
			if bounds.position.y < -0.05:
				failures.append("%s extends below its ground anchor" % type)
			var material := part.mesh.surface_get_material(0) as StandardMaterial3D
			if material == null or material.albedo_texture == null:
				failures.append("%s contains an untextured part" % type)
		if parts.size() < 2 or parts.size() > 16 or absf(top - height) > 1.0:
			failures.append("%s has %d parts and %.1f m top, expected %.1f m" % [type, parts.size(), top, height])
		root.free()
	# Ultra's bounded registry selection must keep the distant visible
	# landmarks even when nearby buildings would otherwise fill the cap.
	var data := LocationData.new()
	data.latitude = 59.3207
	data.longitude = 18.0604
	data.landmark_type = "stockholm_city_hall"
	data.quality_preset = 3
	var selected := LandmarkSites.select(data, []).map(
		func(e: Dictionary) -> String: return str(e["type"]))
	var skyline_types: Array[String] = ["vasterbron", "tyska_kyrkan", "riddarholmen",
		"storkyrkan", "royal_palace_stockholm", "riksdag_building"]
	for item in expected:
		skyline_types.append(str(item[0]))
	for type in skyline_types:
		if not selected.has(type):
			failures.append("Stockholm Ultra selection should include %s" % type)
	if selected.size() > LandmarkSites.MAX_BY_PRESET[3]:
		failures.append("Stockholm Ultra selection exceeds the registry budget")
	data.quality_preset = 2
	if _icons(LandmarkSites.select(data, [])) > LandmarkSites.MAX_REGISTRY_EXTRAS_BY_PRESET[2]:
		failures.append("Stockholm's extra Ultra slots should not affect High")
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.landmark_type = "eiffel"
	data.quality_preset = 3
	if _icons(LandmarkSites.select(data, [])) > LandmarkSites.MAX_REGISTRY_EXTRAS_BY_PRESET[3]:
		failures.append("Other Ultra presets should retain the normal registry budget")
	if failures.is_empty():
		print("STOCKHOLM HERO LANDMARKS OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

## Registry candidates that are landmarks, not capital bridges (those fill the
## room the icons leave, see LandmarkSites.MAX_BRIDGES_BY_PRESET).
func _icons(selected: Array) -> int:
	return selected.filter(func(c: Dictionary) -> bool: return not str(c["type"]).begins_with("br_")).size()
