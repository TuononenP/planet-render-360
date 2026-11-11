extends SceneTree

## Offline contract for the Tokyo (Shibuya Crossing) and Seoul (Gwanghwamun
## Square) landmark batch. No world/cache build: names resolve, registry
## heights are the true metres, every model builds merged and textured to
## that height, and each preset's extras include its batch within radius
## of the preset origin, with the core icon still primary.

const TOKYO := [
	["shibuya_scramble_square", "shibuya scramble square", 229.7],
	["shibuya_hikarie", "shibuya hikarie", 182.5],
	["shibuya_stream", "shibuya stream", 180.0],
	["shibuya_109", "shibuya 109", 33.6],
	["qfront", "qfront", 45.9],
]
const SEOUL := [
	["king_sejong_statue", "statue of king sejong", 10.4],
	["yi_sun_sin_statue", "statue of admiral yi sun-sin", 17.0],
	["gyeongbokgung_walls", "gyeongbokgung palace walls", 4.0],
	["heungnyemun", "heungnyemun gate", 15.0],
	["geunjeongjeon", "geunjeongjeon", 27.8],
]

var failures: Array[String] = []

func _init() -> void:
	_preset("tokyo", "tokyo", TOKYO)
	_preset("seoul", "gwanghwamun", SEOUL)
	for item in TOKYO + SEOUL:
		_model(str(item[0]), str(item[1]), float(item[2]))
	# Gwanghwamun now builds from the shared Korean roof kit: still its
	# 19 m gate in the same merged parts.
	var gate := LandmarkBuilder.build("gwanghwamun")
	var names: Array = LandmarkBuilder.parts(gate).map(func(m: MeshInstance3D) -> String: return str(m.name))
	names.sort()
	if names != ["Dancheong", "Granite", "Plaster", "Shadow", "Tiles", "Timber"] or absf(_top(gate) - 19.0) > 0.1:
		failures.append("Gwanghwamun changed: parts %s, top %.2f m" % [names, _top(gate)])
	gate.free()
	if failures.is_empty():
		print("TOKYO SEOUL LANDMARKS OK: %d models" % (TOKYO.size() + SEOUL.size()))
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

## The preset `id` keeps `primary` and lists every batch type as an extra
## standing within its radius of the preset origin.
func _preset(id: String, primary: String, items: Array) -> void:
	var rows: Array = PresetViews.ROWS.filter(func(row: Dictionary) -> bool: return str(row.get("id", "")) == id)
	if rows.is_empty():
		failures.append("PresetViews has no %s row" % id)
		return
	var lat := float((rows[0] as Dictionary)["lat"])
	var lon := float((rows[0] as Dictionary)["lon"])
	var got := LocationData.landmark_for(lat, lon, "")
	if got != primary:
		failures.append("%s preset primary should stay %s, got %s" % [id, primary, got])
	var extras := LocationData.registry_extras(lat, lon, got).map(func(e: Dictionary) -> String: return str(e["type"]))
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.landmark_type = got
	data.quality_preset = 0
	var selected := LandmarkSites.select(data, []).map(func(e: Dictionary) -> String: return str(e["type"]))
	for item in items:
		var type := str(item[0])
		var entry := LocationData.entry_for_type(type)
		var d := LocationData.distance_m(lat, lon, float(entry.get("lat", 0.0)), float(entry.get("lon", 0.0)))
		if not extras.has(type) or d > float(entry.get("radius_m", 0.0)) or d > 700.0:
			failures.append("%s preset extras should include %s within radius (%.0f m)" % [id, type, d])
		if not selected.has(type):
			failures.append("%s preset's Fast selection should build %s, got %s" % [id, type, selected])

## Name lookup, registry height, and a merged, textured model at that height.
func _model(type: String, alias: String, height: float) -> void:
	if LocationData.landmark_for(0.0, 0.0, alias) != type:
		failures.append("%s alias '%s' did not resolve" % [type, alias])
	var entry := LocationData.entry_for_type(type)
	if entry.is_empty() or not is_equal_approx(float(entry.get("height_m", 0.0)), height):
		failures.append("%s registry height should be %.1f m" % [type, height])
	if not LandmarkBuilder.is_bespoke(type):
		failures.append("%s has no bespoke builder" % type)
		return
	var root := LandmarkBuilder.build(type)
	var parts := LandmarkBuilder.parts(root)
	for part in parts:
		var material := part.mesh.surface_get_material(0) as StandardMaterial3D
		if material == null or material.albedo_texture == null:
			failures.append("%s part %s is untextured" % [type, part.name])
	var top := _top(root)
	if parts.size() < 2 or parts.size() > 16 or absf(top - height) > maxf(1.0, height * 0.01):
		failures.append("%s has %d parts and a %.2f m top, expected %.1f m" % [type, parts.size(), top, height])
	root.free()

func _top(root: Node3D) -> float:
	var top := 0.0
	for part in LandmarkBuilder.parts(root):
		top = maxf(top, (part.transform * part.mesh.get_aabb()).end.y)
	return top
