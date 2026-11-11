extends SceneTree

## Helsinki coverage: Kalasatama towers, biggest malls and the Suomenlinna
## composite must be bespoke registry landmarks at documented heights,
## searchable by name, with clearance covering each model's own radius.
const NEW_TYPES := {
	"majakka": 134.0, "loisto": 124.0, "lumo_one": 120.0,
	"horisontti": 109.0, "visio": 98.0,
	"redi_shopping_centre": 20.0, "mall_of_tripla": 30.0,
	"itis_shopping_centre": 25.0, "iso_omena": 24.0,
	"sello_shopping_centre": 22.0, "jumbo_shopping_centre": 18.0,
	"suomenlinna_kings_gate": 12.0, "suomenlinna_dry_dock": 8.0,
	"suomenlinna_jetty_barracks": 14.0,
}

func _init() -> void:
	var failures: Array[String] = []
	for type in NEW_TYPES:
		var entry := LocationData.entry_for_type(type)
		if entry.is_empty():
			failures.append(type + " missing from registry")
			continue
		if absf(float(entry["height_m"]) - float(NEW_TYPES[type])) > 0.01:
			failures.append("%s height_m %s want %s" % [type, entry["height_m"], NEW_TYPES[type]])
		if not LandmarkBuilder.is_bespoke(type):
			failures.append(type + " must have a bespoke builder")
			continue
		var root := LandmarkBuilder.build(type)
		var bounds := AABB()
		var first := true
		var tris := 0
		for part in LandmarkBuilder.parts(root):
			bounds = (part.transform * part.mesh.get_aabb()) if first else bounds.merge(part.transform * part.mesh.get_aabb())
			first = false
			tris += part.mesh.surface_get_array_len(0) / 3
			var mat := part.mesh.surface_get_material(0) as StandardMaterial3D
			if mat == null or mat.albedo_texture == null:
				failures.append(type + " needs textured materials")
		if absf(bounds.end.y - float(NEW_TYPES[type])) > maxf(2.0, float(NEW_TYPES[type]) * 0.03):
			failures.append("%s built height %.2f want %.1f" % [type, bounds.end.y, NEW_TYPES[type]])
		if bounds.position.y < -0.1:
			failures.append(type + " sinks below base")
		var radius := 0.0
		for i in 8:
			var p := bounds.get_endpoint(i)
			radius = maxf(radius, Vector2(p.x, p.z).length())
		# A lone clearance circle must cover compact models; long malls and
		# the Redi podium spread clearance over subsite offsets instead.
		if entry.has("clear_offsets_m"):
			if (entry["clear_offsets_m"] as Array).is_empty():
				failures.append(type + " clear_offsets_m must not be empty")
		elif radius > float(entry.get("clear_m", 0.0)) + 1.0:
			failures.append("%s radius %.1f exceeds clear_m %s" % [type, radius, entry.get("clear_m")])
		if type == "redi_shopping_centre" and LandmarkBuilder.parts(root).size() < 6:
			failures.append("Redi roof must be a multi-part Bryga park deck (wall, deck, park, paths, pavilion, plant), got %d parts" % LandmarkBuilder.parts(root).size())
		var lookup := LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), str(entry["name"]))
		if lookup != type:
			failures.append("%s name resolves to %s" % [type, lookup])
		print("COVERAGE %s: %d tris, %.2f m, radius %.1f m" % [type, tris, bounds.end.y, radius])
		root.free()
	# Towers must not be so close that one tower's clearance swallows the
	# next tower's centre (they share the Redi podium).
	var towers := ["majakka", "loisto", "lumo_one", "horisontti", "visio"]
	for i in towers.size():
		for j in towers.size():
			if i == j:
				continue
			var a := LocationData.entry_for_type(towers[i])
			var b := LocationData.entry_for_type(towers[j])
			var d := LocationData.distance_m(float(a["lat"]), float(a["lon"]), float(b["lat"]), float(b["lon"]))
			if d < float(a.get("clear_m", 0.0)):
				failures.append("%s clearance %.0f m swallows %s centre %.0f m away" % [towers[i], a["clear_m"], towers[j], d])
	# Composite/cluster selection: neighbours of a primary must be offered
	# as registry extras so every component model gets built.
	var kal := LocationData.registry_extras(60.187531, 24.979657, "majakka").map(
		func(e: Dictionary) -> String: return str(e["type"]))
	for want in ["loisto", "lumo_one", "horisontti", "visio", "redi_shopping_centre"]:
		if not kal.has(want):
			failures.append("Kalasatama extras missing " + want)
	var suo := LocationData.registry_extras(60.14786, 24.98637, "suomenlinna_fortress").map(
		func(e: Dictionary) -> String: return str(e["type"]))
	for want in ["suomenlinna_kings_gate", "suomenlinna_dry_dock", "suomenlinna_jetty_barracks"]:
		if not suo.has(want):
			failures.append("Suomenlinna composite extras missing " + want)
	if failures.is_empty():
		print("HELSINKI COVERAGE OK: %d new bespoke landmarks" % NEW_TYPES.size())
		quit(0)
	else:
		for f in failures:
			printerr("HELSINKI COVERAGE FAIL: ", f)
		quit(1)
