extends SceneTree

## Each New York icon replaces only its own building: no other tall building
## from the bundled snapshots stands inside its cleared circle, and its model
## stays within the skyline's triangle budget.

const LAT := 40.7060
const LON := -74.0040
## Above this a building lost to a clearing would leave a hole in the skyline.
const TALL_M := 40.0
const MAX_TRIS := 15000
## How far outside its model a part of the icon's own lot may sit.
const LOT_MARGIN_M := 8.0

func _init() -> void:
	var failures: Array[String] = []
	var tall: Array = []
	for b in OsmParser.parse_features(BundledOsm.read("new_york_detailed"), LAT, LON)["buildings"]:
		tall.append(b)
	for t in FarCityFetcher.parse(BundledOsm.read("new_york_far"), LAT, LON).get("towers", []):
		tall.append(t)
	for entry in LandmarkRegistryNyc.entries():
		var type := str(entry["type"])
		var model := LandmarkBuilder.build(type)
		var bounds := AABB()
		var tris := 0
		for m in LandmarkBuilder.parts(model):
			bounds = bounds.merge(m.mesh.get_aabb())
			tris += m.mesh.surface_get_array_len(0) / 3
		model.free()
		if tris > MAX_TRIS:
			failures.append("%s costs %d triangles (budget %d)" % [type, tris, MAX_TRIS])
		var site := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]), LAT, LON)
		var axis := LandmarkSites.axis(entry)
		var perp := Vector2(-axis.y, axis.x)
		var clear := LandmarkSites.clear_m(entry)
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
		printerr("NYC SKYSCRAPER SITES FAIL: ", f)
	print("nyc_skyscraper_sites_test: %s" % ("FAIL" if not failures.is_empty() else "PASS"))
	quit(1 if not failures.is_empty() else 0)
