extends SceneTree

## Landmark catalog test: godot --headless --script tests/landmark_catalog_test.gd
## Offline. Guards every registry entry (core and region batches):
## complete fields, unique type, name lookup returns the entry itself
## (no alias shadowing), a bespoke model (not the archetype fallback)
## that is merged, textured, bounded in triangles, and within 3% (or
## 2 m) of its registry height_m.

const REQUIRED := ["type", "name", "lat", "lon", "radius_m", "aliases", "wiki_title", "height_m"]
const MAX_TRIS := 60000

func _run() -> void:
	var failures: Array[String] = []
	var seen := {}
	var entries := LocationData.landmarks()
	for entry in entries:
		var type := str(entry.get("type", "?"))
		for key in REQUIRED:
			if not entry.has(key):
				failures.append("%s lacks %s" % [type, key])
		if not entry.has("type") or not entry.has("lat") or not entry.has("aliases"):
			continue
		if seen.has(type):
			failures.append("duplicate type %s" % type)
		seen[type] = true
		if entry.has("icon") and entry["icon"] != true:
			failures.append("%s icon should be true or absent" % type)
		var lat := float(entry["lat"])
		var lon := float(entry["lon"])
		if absf(lat) > 90.0 or absf(lon) > 180.0:
			failures.append("%s has out-of-range coordinates" % type)
		var core := _is_core(type)
		# The 23 core landmarks predate these rules (checked by landmark_test).
		for alias in ([] if core else entry["aliases"]):
			if str(alias) != str(alias).to_lower() or str(alias).length() < 5:
				failures.append("%s alias '%s' should be lower case and >= 5 characters" % [type, alias])
		var got := LocationData.landmark_for(lat, lon, str(entry.get("name", "")))
		if got != type:
			failures.append("searching '%s' should give %s, got %s" % [entry.get("name"), type, got])
		if not core and not LandmarkBuilder.is_bespoke(type):
			failures.append("%s has no bespoke builder (would fall back to a generic tower)" % type)
			continue
		var model := LandmarkBuilder.build(type)
		_check_model(failures, type, model, 0.0 if core else float(entry.get("height_m", 0.0)))
		model.free()
	if failures.is_empty():
		print("LANDMARK CATALOG OK: %d registry landmarks" % entries.size())
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK CATALOG FAIL: ", f)
		quit(1)

## The 23 landmarks built by LandmarkBuilder's own match.
func _is_core(type: String) -> bool:
	for e in LocationData._core_landmarks():
		if str(e["type"]) == type:
			return true
	return false

func _check_model(failures: Array[String], label: String, root: Node3D, height_m: float) -> void:
	var model := root.get_node_or_null("Model") as Node3D
	if model == null or not model.scale.is_equal_approx(Vector3.ONE * WorldScale.metres_to_units()):
		failures.append("%s should build under a Model node scaled metres_to_units" % label)
		return
	var parts := LandmarkBuilder.parts(root)
	if parts.size() < 2 or parts.size() > 16:
		failures.append("%s should be 2..16 merged parts, got %d" % [label, parts.size()])
	var top := 0.0
	var tris := 0
	for m in parts:
		var mat := m.mesh.surface_get_material(0) as StandardMaterial3D
		if mat == null or mat.albedo_texture == null:
			failures.append("%s part %s should use a textured PBR material" % [label, m.name])
		top = maxf(top, (m.transform * m.mesh.get_aabb()).end.y)
		tris += m.mesh.surface_get_array_len(0) / 3
	if tris > MAX_TRIS:
		failures.append("%s has %d triangles (max %d)" % [label, tris, MAX_TRIS])
	if height_m > 0.0 and absf(top - height_m) > maxf(2.0, height_m * 0.03):
		failures.append("%s should stand %.1f m tall, got %.1f m" % [label, height_m, top])

func _init() -> void:
	_run()
