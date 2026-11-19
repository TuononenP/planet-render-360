class_name TurkuTrees
extends RefCounted

## The City of Turku's urban tree register (Puut, CC BY 4.0) from the
## city's open WFS (`turku.asiointi.fi/TeklaOGCWeb/WFS.ashx`, EPSG:3877):
## botanical species, broadleaf/conifer group and planting year per tree.
## `merge` names and sizes OSM trees within MATCH_M and, where `add_new`,
## plants the register trees the map lacks (High and Ultra).

const URL := "https://turku.asiointi.fi/TeklaOGCWeb/WFS.ashx"
const LAYER := "GIS:Puut"
const CREDIT := "Trees: © City of Turku, tree register (CC BY 4.0)"
const HALF_M := 1450.0
const MAX_FEATURES := 20000
const MATCH_M := 3.0
const DATA_YEAR := 2026
const YOUNG_YEARS := 5
const YOUNG_MAX_M := 5.0
const SOURCE := "turku_register"

## Coarse bounding box of Turku's open-data municipal area (WGS84).
const MIN_LAT := 60.34
const MAX_LAT := 60.62
const MIN_LON := 22.05
const MAX_LON := 22.52

static func covers(lat: float, lon: float) -> bool:
	return lat >= MIN_LAT and lat <= MAX_LAT and lon >= MIN_LON and lon <= MAX_LON

## GetFeature URL (WFS 1.1.0 GML, EPSG:3877 easting-first bbox).
static func request_url(lat: float, lon: float) -> String:
	var p := Gk23.forward(lat, lon)
	var e := roundf(p[0])
	var n := roundf(p[1])
	return "%s?service=WFS&version=1.1.0&request=GetFeature&typeName=%s&maxFeatures=%d&bbox=%d,%d,%d,%d" % [
		URL, LAYER, MAX_FEATURES,
		int(e - HALF_M), int(n - HALF_M), int(e + HALF_M), int(n + HALF_M)]

## Parses the GML FeatureCollection into rows {e, n, genus, species,
## leaf_type, height_m, street}; null when the text is not a feature
## collection (e.g. a WFS exception or HTML error).
static func decode(text: String) -> Variant:
	if text.find("FeatureCollection") < 0:
		return null
	var xml := XMLParser.new()
	if xml.open_buffer(text.to_utf8_buffer()) != OK:
		return null
	var rows: Array = []
	var in_item := false
	var tag := ""
	var group := ""
	var species_raw := ""
	var planted := 0
	var pos_str := ""
	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var name := _local_name(xml.get_node_name())
				if name == "Puut":
					in_item = true
					group = ""
					species_raw = ""
					planted = 0
					pos_str = ""
				elif in_item:
					tag = name
			XMLParser.NODE_TEXT:
				if in_item and tag != "":
					var val := xml.get_node_data().strip_edges()
					match tag:
						"Kasviryhma":
							group = val
						"Kasvilaji":
							species_raw = val
						"Istutusvuosi":
							if val.is_valid_int():
								planted = int(val)
						"pos":
							pos_str = val
			XMLParser.NODE_ELEMENT_END:
				var name := _local_name(xml.get_node_name())
				if name == tag:
					tag = ""
				if name == "Puut" and in_item:
					in_item = false
					var parts := pos_str.split(" ", false)
					if parts.size() >= 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
						var parsed := _parse_species(species_raw)
						rows.append({
							"e": float(parts[0]),
							"n": float(parts[1]),
							"genus": parsed[0],
							"species": parsed[1],
							"leaf_type": "needleleaved" if group.to_lower().begins_with("havu") else ("broadleaved" if group.to_lower().begins_with("lehti") else ""),
							"height_m": height_for(planted),
							"street": false,
						})
	return rows

static func _local_name(raw: String) -> String:
	var idx := raw.rfind(":")
	return raw.substr(idx + 1) if idx >= 0 else raw

## Extracts [genus, species] from "Malus baccata (marjaomenapuu)" → ["malus", "malus baccata"].
static func _parse_species(raw: String) -> Array:
	var s := raw.strip_edges()
	var paren := s.find("(")
	if paren >= 0:
		s = s.substr(0, paren).strip_edges()
	if s == "" or s.to_lower().begins_with("tuntematon") or s.to_lower().begins_with("ei tietoa"):
		return ["", ""]
	var words := s.split(" ", false)
	if words.is_empty():
		return ["", ""]
	var genus := words[0].to_lower()
	if genus == "x" and words.size() > 1:
		genus = words[1].to_lower()
	var species := (genus + " " + words[1].to_lower()) if words.size() >= 2 and not words[1].begins_with("'") else genus
	return [genus, species]

## Height estimate (m) from planting year; 0 when unknown (falls back to
## species/regional default).
static func height_for(planted: int) -> float:
	if planted <= 1800 or planted > DATA_YEAR:
		return 0.0
	var age := DATA_YEAR - planted
	if age <= YOUNG_YEARS:
		return YOUNG_MAX_M
	if age <= 15:
		return 8.0
	if age <= 35:
		return 13.0
	return 17.0

## Merges register `rows` into `trees` (local metres round c_lat, c_lon).
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
	var f := Gk23.frame(c_lat, c_lon)
	for r in rows:
		var p := Gk23.frame_xz(f, float(r["e"]), float(r["n"]))
		if absf(p.x) > half or absf(p.y) > half:
			continue
		var hit := HelsinkiTrees._nearest(out, grid, p)
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

static func _fill(t: Dictionary, r: Dictionary) -> void:
	if str(t.get("genus", "")) == "" and str(r["genus"]) != "":
		t["genus"] = r["genus"]
	if str(t.get("species", "")) == "" and str(r["species"]) != "":
		t["species"] = r["species"]
	if str(t.get("leaf_type", "")) == "" and str(r.get("leaf_type", "")) != "":
		t["leaf_type"] = r["leaf_type"]
	if float(t.get("height_m", 0.0)) <= 0.0 and float(r["height_m"]) > 0.0:
		t["height_m"] = r["height_m"]
