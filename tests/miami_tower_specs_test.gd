extends SceneTree

## Every Miami spec tower (MiamiTowerSpecs) is well formed and builds: a unique
## type, known finishes, ops and surfaces, a model whose top is within 2% of
## height_m, nothing below -0.5 m, and <= 15,000 triangles.

const TOP_TOLERANCE := 0.02
const MAX_TRIS := 15000

func _init() -> void:
	var failures: Array[String] = []
	var types := {}
	for e in LocationData.landmarks():
		var t := str(e["type"])
		if types.has(t):
			failures.append("type %s is registered twice" % t)
		types[t] = true
	for entry in MiamiTowerSpecs.entries():
		_check(entry as Dictionary, failures)
	if not MiamiTowerSpecs.entries().is_empty():
		_check_selection(failures)
	for f in failures:
		printerr("MIAMI TOWER SPECS FAIL: ", f)
	print("miami_tower_specs_test: %d towers %s" % [MiamiTowerSpecs.entries().size(),
		"FAIL" if not failures.is_empty() else "PASS"])
	quit(1 if not failures.is_empty() else 0)

func _check(entry: Dictionary, failures: Array[String]) -> void:
	var type := str(entry["type"])
	var spec: Dictionary = entry["tower_spec"]
	if not bool(entry.get("skyline", false)):
		failures.append("%s is not a skyline row" % type)
	if float(entry.get("clear_m", 0.0)) < 12.0:
		failures.append("%s clears only %.0f m" % [type, float(entry.get("clear_m", 0.0))])
	var lat := float(entry.get("lat", 0.0))
	var lon := float(entry.get("lon", 0.0))
	if lat < 25.60 or lat > 26.00 or lon < -80.45 or lon > -80.05:
		failures.append("%s outside Miami bounds: %.5f, %.5f" % [type, lat, lon])
	var finishes := [str(spec.get("finish", "clear_fin"))]
	for w in (spec.get("walls", {}) as Dictionary).values():
		finishes.append(str((w as Array)[0]))
	for f in finishes:
		if not FacadeCurtainKit.has(f) and not SkyKit.FINISHES.has(f):
			failures.append("%s: unknown finish %s" % [type, f])
	var surfaces := ["Facade", "Trim", "Roof", "Gap", "Louvre", "Slope", "Gold"]
	surfaces.append_array((spec.get("walls", {}) as Dictionary).keys())
	surfaces.append_array((spec.get("mats", {}) as Dictionary).keys())
	for o in spec.get("ops", []):
		var op := o as Array
		var name := str(op[0])
		if not name in TowerSpec.OPS:
			failures.append("%s: unknown op %s" % [type, name])
			continue
		if name == "shape" and not str(op[1]) in TowerSpec.SHAPES:
			failures.append("%s: unknown shape %s" % [type, str(op[1])])
		if name in ["pyramid", "hip", "solid", "steps", "spire", "box", "dome", "ribs", "use"] \
				and not str(op[1]) in surfaces:
			failures.append("%s: %s draws in undeclared surface %s" % [type, name, str(op[1])])
	var model := LandmarkBuilder.build(type)
	var bounds := AABB()
	var tris := 0
	var first := true
	for m in LandmarkBuilder.parts(model):
		var box := m.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		tris += m.mesh.surface_get_array_len(0) / 3
	model.free()
	if first:
		failures.append("%s builds no mesh" % type)
		return
	var height := float(entry["height_m"])
	if absf(bounds.end.y - height) > maxf(height * TOP_TOLERANCE, 1.5):
		failures.append("%s tops out at %.1f m, not its %.1f m" % [type, bounds.end.y, height])
	if bounds.position.y < -0.5:
		failures.append("%s reaches %.1f m below the ground" % [type, bounds.position.y])
	if tris > MAX_TRIS:
		failures.append("%s costs %d triangles (budget %d)" % [type, tris, MAX_TRIS])

func _check_selection(failures: Array[String]) -> void:
	for preset in range(LandmarkSites.MAX_BY_PRESET.size()):
		var data := LocationData.new()
		data.latitude = 25.7743
		data.longitude = -80.1855
		data.landmark_type = LocationData.landmark_for(25.7743, -80.1855, "Miami, United States")
		data.quality_preset = preset
		var picked := LandmarkSites.select(data, [])
		var sky := 0
		for c in picked:
			var e := LocationData.entry_for_type(str(c.get("type", "")))
			if bool(e.get("skyline", false)):
				sky += 1
		if sky == 0:
			failures.append("preset %d builds no skyline towers" % preset)
