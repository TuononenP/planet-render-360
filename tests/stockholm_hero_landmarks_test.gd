extends SceneTree

## Offline contract for the Stockholm landmarks. No world/cache build.
## Every type of LandmarkRegistrySwedenStockholm builds a merged textured
## model of 2..16 parts and 1k..150k triangles that stands its registry
## height (±1 m) and never below its ground anchor, and its first alias
## resolves to it. At the Monteliusvägen preset Ultra keeps every skyline
## item (`skyline_priority`, kept for tall things only) and fills the rest
## nearest-first.

const MIN_TRIANGLES := 1000
const MAX_TRIANGLES := 150000
## Only things that stand on the skyline may jump the nearest-first queue.
const SKYLINE_MIN_M := 40.0
const PRESET := Vector2(59.3207, 18.0604)

func _init() -> void:
	var failures: Array[String] = []
	var entries := LandmarkRegistrySwedenStockholm.entries()
	if entries.size() < 25:
		failures.append("Stockholm registry lost entries: %d" % entries.size())
	var seen := {}
	for entry in entries:
		var type := str(entry["type"])
		if seen.has(type):
			failures.append("%s is registered twice" % type)
		seen[type] = true
		var height := float(entry.get("height_m", 0.0))
		var aliases: Array = entry.get("aliases", [])
		if aliases.is_empty() or LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), str(aliases[0])) != type:
			failures.append("%s alias did not resolve" % type)
		if int(entry.get("skyline_priority", 0)) > 0 and height < SKYLINE_MIN_M:
			failures.append("%s is %.0f m: too low for skyline_priority" % [type, height])
		var root := LandmarkBuilder.build(type)
		if root == null:
			failures.append("%s has no builder" % type)
			continue
		var parts := LandmarkBuilder.parts(root)
		var top := 0.0
		var triangles := 0
		var on_water := str(entry.get("base", "ground")) in ["water", "sea"]
		for part in parts:
			var bounds := part.transform * part.mesh.get_aabb()
			top = maxf(top, bounds.end.y)
			# Sergels torg's fountain rim skirts 2 m into the carved dish (sto_kulturhuset.gd SKIRT_Y).
			var floor_y := -2.05 if type == "kulturhuset_sergels_torg" else -0.05
			if bounds.position.y < floor_y and not on_water:
				failures.append("%s extends below its ground anchor (%.2f m)" % [type, bounds.position.y])
			for s in part.mesh.get_surface_count():
				var arrays := part.mesh.surface_get_arrays(s)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				triangles += (idx.size() if idx.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
			var material := part.mesh.surface_get_material(0) as StandardMaterial3D
			if material == null or material.albedo_texture == null:
				failures.append("%s contains an untextured part" % type)
		if parts.size() < 2 or parts.size() > 16 or absf(top - height) > 1.0:
			failures.append("%s has %d parts and %.1f m top, expected %.1f m" % [type, parts.size(), top, height])
		if triangles < MIN_TRIANGLES or triangles > MAX_TRIANGLES:
			failures.append("%s has %d triangles, expected %d..%d" % [type, triangles, MIN_TRIANGLES, MAX_TRIANGLES])
		root.free()
	_check_selection(failures)
	_check_r7_landmarks(failures)
	if failures.is_empty():
		print("STOCKHOLM HERO LANDMARKS OK: %d types" % entries.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

## Ultra at the preset: every skyline item in range is chosen, and the low
## landmarks chosen are the nearest of their kind.
func _check_selection(failures: Array[String]) -> void:
	var data := LocationData.new()
	data.latitude = PRESET.x
	data.longitude = PRESET.y
	data.landmark_type = "stockholm_city_hall"
	data.quality_preset = 3
	var selected := LandmarkSites.select(data, []).map(
		func(e: Dictionary) -> String: return str(e["type"]))
	var extras := LocationData.registry_extras(PRESET.x, PRESET.y, "stockholm_city_hall").filter(
		func(e: Dictionary) -> bool: return not (bool(e.get("secondary", false)) and str(e.get("kind", "")) == "Bridge"))
	var skyline := extras.filter(func(e: Dictionary) -> bool: return int(e.get("skyline_priority", 0)) > 0)
	for e in skyline:
		if not selected.has(str(e["type"])):
			failures.append("Stockholm Ultra selection should include skyline item %s" % e["type"])
	for type in ["riddarholmen", "royal_palace_stockholm", "riksdag_building", "wrangel_palace"]:
		if not selected.has(type):
			failures.append("Stockholm Ultra selection should include nearby %s" % type)
	# Nearest-first among the rest: no unchosen low landmark is nearer than
	# the farthest chosen one.
	var dist := func(e: Dictionary) -> float:
		return LocationData.distance_m(PRESET.x, PRESET.y, float(e["lat"]), float(e["lon"]))
	var farthest := 0.0
	var low := extras.filter(func(e: Dictionary) -> bool:
		return int(e.get("skyline_priority", 0)) == 0)
	for e in low:
		if selected.has(str(e["type"])):
			farthest = maxf(farthest, dist.call(e))
	for e in low:
		if not selected.has(str(e["type"])) and dist.call(e) < farthest - 1.0:
			failures.append("%s (%.0f m) was skipped for a farther low landmark (%.0f m)" % [e["type"], dist.call(e), farthest])
	var budget := int(LocationData.entry_for_type("stockholm_city_hall").get("ultra_total_limit", LandmarkSites.MAX_BY_PRESET[3]))
	if selected.size() > budget:
		failures.append("Stockholm Ultra selection (%d) exceeds its budget (%d)" % [selected.size(), budget])
	data.quality_preset = 2
	if _icons(LandmarkSites.select(data, [])) > LandmarkSites.MAX_REGISTRY_EXTRAS_BY_PRESET[2]:
		failures.append("Stockholm's extra Ultra slots should not affect High")
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.landmark_type = "eiffel"
	data.quality_preset = 3
	if _icons(LandmarkSites.select(data, [])) > LandmarkSites.MAX_REGISTRY_EXTRAS_BY_PRESET[3]:
		failures.append("Other Ultra presets should retain the normal registry budget")

## Registry candidates that are landmarks, not capital bridges (those fill the
## room the icons leave, see LandmarkSites.MAX_BRIDGES_BY_PRESET).
func _icons(selected: Array) -> int:
	return selected.filter(func(c: Dictionary) -> bool:
		return not str(c["type"]).begins_with("br_") and str(c.get("archetype", "")) != "Bridge").size()


## sto-r7: Sergels torg's translucent curtain wall, readable neon and paving
## above the held terrain, the Strömbron balustrade and lamps, and Gustav II
## Adolf's horse.
func _check_r7_landmarks(failures: Array[String]) -> void:
	var kh := LandmarkBuilder.build("kulturhuset_sergels_torg")
	var glass := _part(kh, "GlassLamp")
	if glass == null or (glass.mesh.surface_get_material(0) as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
		failures.append("Kulturhuset's curtain wall should be translucent")
	if _part(kh, "Interior") == null:
		failures.append("Kulturhuset lost the back wall behind its glass")
	if _tris(_part(kh, "NeonLamp")) < 600:
		failures.append("Kulturhuset's neon should be stroke letters, got %d triangles" % _tris(_part(kh, "NeonLamp")))
	var tri := _part(kh, "Tri")
	if tri == null or (tri.transform * tri.mesh.get_aabb()).position.y < 0.3:
		failures.append("the triangle paving should lie over the held terrain (y >= 0.3)")
	kh.free()
	var br := LandmarkBuilder.build("br_stockholm_stromsbron")
	var row := BridgeSpecs.row_for("br_stockholm_stromsbron")
	var half_w := float(row["width"]) * 0.5
	for side in [-1.0, 1.0]:
		var rail := false
		for v in _part(br, "Rail").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if absf(v.z - side * (half_w - 0.2)) < 0.3 and v.y > float(row["clear"]) + 1.0:
				rail = true
				break
		if not rail:
			failures.append("Strömbron has no balustrade on side %.0f" % side)
	if _part(br, "Lamp") == null or _tris(_part(br, "Pole")) < 400:
		failures.append("Strömbron lost its lamp standards")
	if _tris(_part(br, "Band")) < 100:
		failures.append("Strömbron's piers lost their waterline band")
	var pole_top := -INF
	for v in _part(br, "Pole").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		pole_top = maxf(pole_top, v.y)
	if absf(pole_top - BridgeSpec.model_top(row)) > 0.3:
		failures.append("Strömbron's lamps top out at %.2f m, the row says %.2f m" % [pole_top, BridgeSpec.model_top(row)])
	br.free()
	var gus := LandmarkBuilder.build("gustav_ii_adolf_statue")
	var bronze := _part(gus, "Gustav_adolf_Bronze")
	var box := bronze.transform * bronze.mesh.get_aabb()
	if _tris(bronze) < 4000 or box.size.x < 3.8:
		failures.append("Gustav II Adolf's horse should be a built horse (>= 4k triangles, >= 3.8 m long), got %d tris, %.1f m" % [_tris(bronze), box.size.x])
	gus.free()

func _part(root: Node3D, key: String) -> MeshInstance3D:
	for m in LandmarkBuilder.parts(root):
		if str(m.name).ends_with(key):
			return m
	return null

func _tris(m: MeshInstance3D) -> int:
	return 0 if m == null else m.mesh.surface_get_array_len(0) / 3
