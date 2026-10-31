class_name OsmApiFallback
extends RefCounted

## Last-resort OSM source when every Overpass instance fails: the main
## OSM API's bbox endpoint (a different server farm, same data, same ODbL
## licence). It answers XML and caps a request at 50 000 nodes (HTTP 400),
## so callers step down RADII_M. to_overpass_json converts the XML into
## Overpass `out geom` JSON so OsmParser consumes it unchanged.

const URL := "https://api.openstreetmap.org/api/0.6/map"
## Bbox half-widths tried in order; 400 (too many nodes) steps down.
const RADII_M: Array[int] = [1200, 800, 400]
## Responses after which a smaller box can still succeed: 400 (over the
## node cap), 429 (rate limited) and 509 (bandwidth limit exceeded).
const STEP_DOWN_CODES: Array[int] = [400, 429, 509]
## Seconds one extra step down may add to the fetch budget: these
## answers arrive in about a second, so a step is cheap.
const STEP_BUDGET_S := 15.0
const M_PER_DEG := 111320.0

static func steps_down(result: int, code: int) -> bool:
	return result == HTTPRequest.RESULT_SUCCESS and code in STEP_DOWN_CODES

static func extra_budget_seconds() -> float:
	return (RADII_M.size() - 1) * STEP_BUDGET_S

## `building=no` marks a non-building, and a way with fewer than three
## resolved nodes (a relation with no such member) is no footprint;
## neither counts as a building.
static func names_building(tags: Dictionary) -> bool:
	return tags.has("building") and str(tags["building"]) != "no"

static func url_for(lat: float, lon: float, radius_m: int) -> String:
	var dlat := radius_m / M_PER_DEG
	var dlon := radius_m / (M_PER_DEG * maxf(cos(deg_to_rad(lat)), 0.01))
	return "%s?bbox=%.6f,%.6f,%.6f,%.6f" % [URL, lon - dlon, lat - dlat,
		lon + dlon, lat + dlat]

## {"json": Overpass-shaped payload, "buildings": count}. Thread-safe.
## The API lists nodes, then ways, then relations, so geometry resolves
## in one pass. Only tagged nodes/ways and multipolygon relations are
## emitted; untagged ways are kept just for relation member geometry.
static func to_overpass_json(xml: PackedByteArray) -> Dictionary:
	var parser := XMLParser.new()
	if xml.is_empty() or parser.open_buffer(xml) != OK:
		return {"json": "", "buildings": 0}
	# Two float64 maps: Vector2 is float32 (≈0.4 m at these latitudes).
	var lats := {}
	var lons := {}
	var way_geom := {}
	var elements: Array = []
	var buildings := 0
	var cur := ""
	var id := 0
	var tags := {}
	var nds: Array = []
	var members: Array = []
	var lat := 0.0
	var lon := 0.0
	while parser.read() == OK:
		var kind := parser.get_node_type()
		if kind != XMLParser.NODE_ELEMENT and kind != XMLParser.NODE_ELEMENT_END:
			continue
		var name := parser.get_node_name()
		if kind == XMLParser.NODE_ELEMENT:
			match name:
				"node", "way", "relation":
					cur = name
					id = parser.get_named_attribute_value_safe("id").to_int()
					tags = {}
					nds = []
					members = []
					if name == "node":
						lat = parser.get_named_attribute_value_safe("lat").to_float()
						lon = parser.get_named_attribute_value_safe("lon").to_float()
						lats[id] = lat
						lons[id] = lon
				"tag":
					tags[parser.get_named_attribute_value_safe("k")] = \
						parser.get_named_attribute_value_safe("v")
				"nd":
					nds.append(parser.get_named_attribute_value_safe("ref").to_int())
				"member":
					members.append({
						"type": parser.get_named_attribute_value_safe("type"),
						"ref": parser.get_named_attribute_value_safe("ref").to_int(),
						"role": parser.get_named_attribute_value_safe("role")})
			if not (parser.is_empty() and cur == name):
				continue
		elif name != cur:
			continue
		# End of a node/way/relation (or a self-closing one).
		match cur:
			"node":
				if not tags.is_empty():
					elements.append({"type": "node", "id": id, "lat": lat,
						"lon": lon, "tags": tags})
			"way":
				var geom: Array = []
				for ref in nds:
					if lats.has(ref):
						geom.append({"lat": lats[ref], "lon": lons[ref]})
				way_geom[id] = geom
				if not tags.is_empty():
					elements.append({"type": "way", "id": id, "tags": tags,
						"geometry": geom})
					buildings += int(geom.size() >= 3 and names_building(tags))
			"relation":
				if str(tags.get("type", "")) == "multipolygon":
					var out_members: Array = []
					var with_geometry := 0
					for m in members:
						if str(m["type"]) == "way":
							var mg: Array = way_geom.get(m["ref"], [])
							with_geometry += int(mg.size() >= 3)
							out_members.append({"type": "way", "ref": m["ref"],
								"role": m["role"], "geometry": mg})
					if not out_members.is_empty() and not tags.is_empty():
						elements.append({"type": "relation", "id": id,
							"tags": tags, "members": out_members})
						buildings += int(with_geometry > 0 and names_building(tags))
		cur = ""
	return {"json": JSON.stringify({"elements": elements}), "buildings": buildings}
