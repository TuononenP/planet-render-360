class_name HelsinkiTrees
extends RefCounted

## The City of Helsinki's tree register (Puurekisteri; street and park
## trees the city maintains, CC BY 4.0), from the city's WFS: genus,
## species and trunk-diameter class per tree. `merge` names and sizes the
## OSM trees it finds within MATCH_M and, where `add_new`, plants the
## register trees the map lacks (High and Ultra: CityDetail.extra_trees).

const URL := "https://kartta.hel.fi/ws/geoserver/avoindata/wfs"
const LAYER := "avoindata:Puurekisteri_piste"
const CREDIT := "Trees: © City of Helsinki, tree register (CC BY 4.0)"
const HALF_M := 1450.0
const MAX_FEATURES := 30000
const MATCH_M := 3.0
## The register's year, for young plantings (deterministic, not "now").
const DATA_YEAR := 2026
## Recent plantings are nursery stock, whatever the class says.
const YOUNG_YEARS := 5
const YOUNG_MAX_M := 5.0
const UNKNOWN_GENUS := "määrittelemättä"
## Trunk-diameter class → typical height (m) of an urban Nordic tree.
const HEIGHT_BY_CLASS := {
	"0 - 10 cm": 4.5, "10 - 20 cm": 7.0, "20 - 30 cm": 10.0,
	"30 - 50 cm": 14.0, "50 - 70 cm": 18.0, "70 cm -": 22.0,
}
const SOURCE := "hel_register"

static func covers(lat: float, lon: float) -> bool:
	return HelsinkiRegister.covers(lat, lon)

## GetFeature URL for the window round (lat, lon); geometry stays in GK25.
static func request_url(lat: float, lon: float) -> String:
	var p := Gk25.forward(lat, lon)
	var e := roundf(p[0])
	var n := roundf(p[1])
	return "%s?service=WFS&version=2.0.0&request=GetFeature&typeNames=%s&outputFormat=application/json&count=%d&propertyName=suku,laji,kokoluokka,paatyyppi,istutusvuosi,geom&bbox=%d,%d,%d,%d,EPSG:3879" % [
		URL, LAYER, MAX_FEATURES,
		int(e - HALF_M), int(n - HALF_M), int(e + HALF_M), int(n + HALF_M)]

## Rows {e, n, genus, species, height_m, street}; null when the text is
## no feature collection.
static func decode(text: String) -> Variant:
	if not text.strip_edges().begins_with("{"):
		return null  # a WFS exception (XML) or an error page
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("features"):
		return null
	var rows: Array = []
	for f in (parsed as Dictionary)["features"]:
		if not (f is Dictionary):
			continue
		var g: Variant = (f as Dictionary).get("geometry")
		if not (g is Dictionary) or not ((g as Dictionary).get("coordinates") is Array):
			continue
		var c: Array = (g as Dictionary)["coordinates"]
		if c.size() < 2:
			continue
		var p: Dictionary = (f as Dictionary).get("properties", {})
		var genus := _str(p.get("suku")).to_lower()
		if genus == UNKNOWN_GENUS:
			genus = ""
		var species := _str(p.get("laji")).to_lower()
		var planted := int(p.get("istutusvuosi")) if (p.get("istutusvuosi") is float or p.get("istutusvuosi") is int) else 0
		rows.append({"e": float(c[0]), "n": float(c[1]), "genus": genus,
			"species": (genus + " " + species).strip_edges() if genus != "" else "",
			"height_m": height_for(_str(p.get("kokoluokka")), planted),
			"street": _str(p.get("paatyyppi")) == "Katu"})
	return rows

static func _str(v: Variant) -> String:
	return "" if v == null else str(v).strip_edges()

## Height (m) from the trunk class; 0 when unknown. Young plantings cap.
static func height_for(size_class: String, planted: int) -> float:
	var h: float = HEIGHT_BY_CLASS.get(size_class, 0.0)
	if planted > 0 and DATA_YEAR - planted <= YOUNG_YEARS:
		h = YOUNG_MAX_M if h <= 0.0 else minf(h, YOUNG_MAX_M)
	return h

## Merges register `rows` into `trees` (local metres round c_lat,
## c_lon). OSM trees within MATCH_M get the missing genus / species /
## height; with `add_new` the unmatched register trees are appended.
## Returns the new tree array (the input array is not grown in place:
## it may be shared with a parse cache) and fills `stats`.
static func merge(trees: Array, c_lat: float, c_lon: float, rows: Array,
		add_new: bool, stats: Dictionary = {}) -> Array:
	var out := trees.duplicate()
	var grid := {}
	for i in out.size():
		var t: Variant = out[i]
		if t is Dictionary:
			var key := Vector2i(floori(float(t["x"]) / MATCH_M), floori(float(t["z"]) / MATCH_M))
			if not grid.has(key):
				grid[key] = []
			(grid[key] as Array).append(i)
	var matched := 0
	var added := 0
	var half := WorldScale.DETAILED_EXTENT_M * 0.5
	var f := Gk25.frame(c_lat, c_lon)
	for r in rows:
		var p := Gk25.frame_xz(f, float(r["e"]), float(r["n"]))
		if absf(p.x) > half or absf(p.y) > half:
			continue
		var hit := _nearest(out, grid, p)
		if hit >= 0:
			_fill(out[hit], r)
			matched += 1
		elif add_new:
			var t := {"x": p.x, "z": p.y, "source": SOURCE}
			_fill(t, r)
			out.append(t)
			added += 1
	stats["rows"] = rows.size()
	stats["matched"] = matched
	stats["added"] = added
	return out

static func _nearest(trees: Array, grid: Dictionary, p: Vector2) -> int:
	var key := Vector2i(floori(p.x / MATCH_M), floori(p.y / MATCH_M))
	var best := -1
	var best_d := MATCH_M
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for i in grid.get(key + Vector2i(dx, dz), []):
				var t: Dictionary = trees[i]
				var d := p.distance_to(Vector2(float(t["x"]), float(t["z"])))
				if d < best_d:
					best_d = d
					best = i
	return best

## Fill-only: mapped OSM tags win.
static func _fill(t: Dictionary, r: Dictionary) -> void:
	if str(t.get("genus", "")) == "" and str(r["genus"]) != "":
		t["genus"] = r["genus"]
	if str(t.get("species", "")) == "" and str(r["species"]) != "":
		t["species"] = r["species"]
	if float(t.get("height_m", 0.0)) <= 0.0 and float(r["height_m"]) > 0.0:
		t["height_m"] = r["height_m"]
	if bool(r["street"]):
		t["street"] = true
