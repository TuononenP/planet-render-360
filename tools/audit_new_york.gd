extends SceneTree

## Reproducible mapped-identity and query audit; headless, no rendering.
## tools/godot_bg.sh --headless --path . --script tools/audit_new_york.gd
const LAT := 40.706
const LON := -74.004

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	CacheStore.eviction_suppressed = true
	var out := "res://visual-plan/reviews/nyc-r21-2026-11-04"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	var query := FileAccess.open(out.path_join("detailed-query.txt"), FileAccess.WRITE)
	query.store_string(OsmQuery.build_query(LAT, LON, 1200))
	query.close()
	var raw := OsmFetcher._read_cache(CacheStore.osm_path(LAT, LON, 1200))
	if raw == "":
		for path in OsmNearbyCache.candidates(LAT, LON, OsmFetcher.SAME_PLACE_M):
			raw = OsmFetcher._read_cache(path)
			if raw != "":
				break
	var parsed := OsmFetcher.parse_features(raw, LAT, LON)
	var far_raw := OsmFetcher._read_cache(FarCityFetcher.cache_path(LAT, LON))
	var far := FarCityFetcher.parse(far_raw, LAT, LON)
	var data := LocationData.new()
	data.latitude = LAT
	data.longitude = LON
	data.country = "US"
	data.quality_preset = 3
	data.buildings = parsed["buildings"]
	data.buildings = FarCityFetcher.complete_buildings(data.buildings, far["towers"])
	var ctx := BuildingHeights._height_context(data)
	BuildingMasses.begin_build()
	var report := {"detailed_error": OverpassRequest.payload_error(raw), "detailed_current": OsmQuery.is_current(raw),
		"far_error": OverpassRequest.payload_error(far_raw), "buildings": data.buildings.size(),
		"far_towers": far["towers"].size(), "targets": [], "opening_bearings": []}
	for layer in [data.buildings, far["towers"]]:
		for b in layer:
			var name := str(b.get("name", ""))
			var target := str(b.get("osm_id", "")) in ["way:278069587", "way:278042253", "way:259686624", "way:1252090828", "way:1039403183"]
			for part in b.get("parts", []):
				if str(part.get("osm_id", "")) in ["way:1252090828", "way:1039403183"]:
					target = true
			for key in ["Woolworth", "40 Wall", "Trump Building", "70 Pine", "Municipal",
					"Vesey", "Brookfield", "Goldman", "99 Hudson", "Brooklyn Tower", "Whitehall Terminal", "Carousel"]:
				if name.to_lower().contains(key.to_lower()):
					target = true
			if not target:
				continue
			var look := BuildingHeights._look_for(b, ctx)
			var parts: Array = []
			for part in b.get("parts", []):
				parts.append(_mass(part))
			var entry := _mass(b)
			if str(b.get("osm_id", "")) == "way:278069587" and layer == data.buildings:
				var planned: Array = []
				for mass in BuildingMasses.plan(b, ctx):
					if float(mass["wall_m"]) >= 242.0:
						planned.append({"min_m": mass["min_m"], "wall_m": mass["wall_m"],
							"shape": mass["shape"], "material": mass["b_eff"].get("material", ""),
							"source": mass["b_eff"].get("osm_id", "")})
				entry["planned_crown"] = planned
			entry.merge({"name": name, "osm_id": b.get("osm_id", ""), "x": b.get("x", 0),
				"z": b.get("z", 0), "era": look.get("era", ""), "wall_set": look.get("wall_set", ""),
				"parts": parts, "layer": "detailed" if layer == data.buildings else "far"})
			report["targets"].append(entry)
	var eye := WorldScale.xz_from_latlon(40.70265, -73.99686, LAT, LON)
	for bearing in range(293, 299):
		var subjects := {}
		for type in ["statue_liberty", "one_wtc"]:
			var entry := LocationData.entry_for_type(type)
			if entry.is_empty():
				continue
			var pos := WorldScale.xz_from_latlon(entry["lat"], entry["lon"], LAT, LON) - eye
			var direction := fposmod(rad_to_deg(atan2(pos.x, -pos.y)), 360.0)
			var half_fov := rad_to_deg(atan(tan(deg_to_rad(35.0)) * 1.6))
			subjects[type] = {"bearing": direction, "margin_deg": half_fov - absf(wrapf(direction - bearing, -180.0, 180.0))}
		report["opening_bearings"].append({"bearing": bearing, "subjects": subjects})
	var file := FileAccess.open(out.path_join("mapped-audit.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("NYC AUDIT: buildings=%d far=%d targets=%d error=%s" % [data.buildings.size(),
		far["towers"].size(), report["targets"].size(), report["detailed_error"]])
	BuildingMasses.end_build()
	CacheStore.finish()
	quit(0)

func _mass(b: Dictionary) -> Dictionary:
	var out := {}
	for key in ["osm_id", "height", "min_height_m", "levels", "roof_shape", "roof_height_m", "roof_material", "material", "colour", "start_year"]:
		out[key] = b.get(key, "")
	return out
