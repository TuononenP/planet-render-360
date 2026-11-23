extends SceneTree

## Each Miami skyline spec tower replaces only its own building: no other tall
## building (> 40 m) from the bundled Miami snapshots stands inside its cleared
## circle, and its model stays within the 15,000-triangle skyline budget.

const CENTRES := [
	["miami", 25.7743, -80.1855],
	["miami_beach", 25.7810, -80.1300],
]
const TALL_M := 40.0
const MAX_TRIS := 15000
const LOT_MARGIN_M := 10.0

func _init() -> void:
	var failures: Array[String] = []
	var tall_by_centre: Array = []
	for c in CENTRES:
		var prefix := str(c[0])
		var lat := float(c[1])
		var lon := float(c[2])
		var det_raw := BundledOsm.read(prefix + "_detailed")
		var far_raw := BundledOsm.read(prefix + "_far")
		var tall: Array = []
		if det_raw != "":
			for b in OsmParser.parse_features(det_raw, lat, lon)["buildings"]:
				tall.append(b)
		if far_raw != "":
			for t in FarCityFetcher.parse(far_raw, lat, lon).get("towers", []):
				tall.append(t)
		tall_by_centre.append([lat, lon, tall])

	for entry in MiamiTowerSpecs.entries():
		var type := str(entry["type"])
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
		if tris > MAX_TRIS:
			failures.append("%s costs %d triangles (budget %d)" % [type, tris, MAX_TRIS])
		var axis := LandmarkSites.axis(entry)
		var perp := Vector2(-axis.y, axis.x)
		var clear := LandmarkSites.clear_m(entry)
		for pack in tall_by_centre:
			var clat := float(pack[0])
			var clon := float(pack[1])
			var tall: Array = pack[2]
			var site := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]), clat, clon)
			if site.length() > 11500.0:
				continue
			for b in tall:
				if float(b.get("height", 0.0)) <= TALL_M:
					continue
				var d := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))) - site
				if d.length() >= clear:
					continue
				if absf(d.dot(axis)) <= bounds.size.x * 0.5 + LOT_MARGIN_M \
						and absf(d.dot(perp)) <= bounds.size.z * 0.5 + LOT_MARGIN_M:
					continue
				failures.append("%s clears '%s' (%.0f m) at %.0f m inside its %.0f m circle" % [
					type, str(b.get("name", "unnamed")), float(b.get("height", 0.0)), d.length(), clear])

	for f in failures:
		printerr("MIAMI SKYSCRAPER SITES FAIL: ", f)
	print("miami_skyscraper_sites_test: %d towers %s" % [MiamiTowerSpecs.entries().size(),
		"FAIL" if not failures.is_empty() else "PASS"])
	quit(1 if not failures.is_empty() else 0)
