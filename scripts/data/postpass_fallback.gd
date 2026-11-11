class_name PostpassFallback
extends RefCounted

## Live OSM source for when Overpass fails, tried before OsmApiFallback:
## Postpass (FOSSGIS / Geofabrik) runs SQL against a public PostGIS copy
## of the whole planet, kept minutes behind OSM, and answers GeoJSON. It is
## a separate server and operator from overpass-api.de. A live probe
## (2026-11-11, Helsinki 1200 m) answered in under 2 s with every building
## the bundled snapshot has and the same height and roof tags.
## The query mirrors OsmQuery.build_query: the same layers, street furniture
## only near the eye, each group capped like its Overpass statements
## (nearest first rather than in id order), the country the place stands in,
## and Suomenlinna's defensive works. to_overpass_json converts the answer
## to Overpass `out geom` JSON, so OsmParser consumes it unchanged.
## RemoteConfig `postpass_endpoint` can replace the address without an app
## update.

const URL := "https://postpass.geofabrik.de/api/interpreter"
## Seconds the request may take before the OSM API is tried instead.
const TIMEOUT_S := 30.0
const M_PER_DEG := 111320.0
const FROM := "SELECT osm_type, osm_id, tags, geom FROM postpass_pointlinepolygon WHERE "
## Way and relation tests for the layers after buildings, parts and streets.
const OTHER_AREAS := ("(tags ?| ARRAY['waterway','natural','landuse','leisure','barrier','embankment',"
	+ "'defensive_works'] OR tags->>'railway' IN (%s) OR tags->>'amenity' = 'parking'"
	+ " OR tags->>'place' = 'square'"
	+ " OR tags->>'man_made' IN ('tower','lighthouse','windmill','pier','quay','embankment')"
	+ " OR (tags->>'public_transport' = 'platform' AND tags->>'train' = 'yes'))")
## The Overpass caps of those layers' statements, summed.
const CAP_OTHER_AREAS := OsmQuery.CAP_WATERWAYS + OsmQuery.CAP_NATURAL + OsmQuery.CAP_LANDUSE \
	+ OsmQuery.CAP_LEISURE + 2 * OsmQuery.CAP_BARRIERS + OsmQuery.CAP_RAILWAYS \
	+ 2 * OsmQuery.CAP_SQUARES + OsmQuery.CAP_PLATFORMS + 150 + 4 * OsmQuery.CAP_RELATIONS + 300

static func endpoint() -> String:
	return str(RemoteConfig.value("postpass_endpoint", URL))

static func _sql_list(values: Array) -> String:
	var quoted: PackedStringArray = []
	for v in values:
		quoted.append("'%s'" % str(v).replace("'", "''"))
	return ",".join(quoted)

static func _point(lat: float, lon: float) -> String:
	return "ST_SetSRID(ST_MakePoint(%.6f,%.6f),4326)" % [lon, lat]

## Features within radius_m of the point: the bbox test lets the server use
## its spatial index, the distance test keeps Overpass's circle.
static func _near(lat: float, lon: float, radius_m: int) -> String:
	var dlat := radius_m / M_PER_DEG
	var dlon := radius_m / (M_PER_DEG * maxf(cos(deg_to_rad(lat)), 0.01))
	return "geom && ST_MakeEnvelope(%.6f,%.6f,%.6f,%.6f,4326) AND ST_DWithin(geom::geography, %s::geography, %d)" \
		% [lon - dlon, lat - dlat, lon + dlon, lat + dlat, _point(lat, lon), radius_m]

## One capped group, nearest to (lat, lon) first.
static func _part(where: String, lat: float, lon: float, cap: int) -> String:
	return "(%s%s ORDER BY geom <-> %s LIMIT %d)" % [FROM, where, _point(lat, lon), cap]

## The POST body: OsmQuery.build_query's selection as one SQL query.
static func build_body(lat: float, lon: float, radius_m: int) -> String:
	var view := PresetViews.for_pin(lat, lon)
	var eye_lat := float(view.get("eye_lat", lat))
	var eye_lon := float(view.get("eye_lon", lon))
	var near := _near(lat, lon, radius_m)
	var rail: Array = OsmTags.RAIL_CLASSES.duplicate()
	rail.append("platform")
	var parts: PackedStringArray = [
		_part(_near(eye_lat, eye_lon, OsmQuery.FURNITURE_RADIUS_M) + " AND osm_type = 'N' AND ("
			+ "tags->>'amenity' IN ('bench','waste_basket') OR tags->>'highway' = 'traffic_signals'"
			+ " OR tags->>'barrier' = 'bollard' OR tags->>'railway' = 'subway_entrance')",
			eye_lat, eye_lon, OsmQuery.CAP_FURNITURE),
		_part(near + " AND osm_type = 'N' AND tags->>'natural' = 'tree'", lat, lon, OsmQuery.CAP_TREE_NODES),
		_part(near + " AND osm_type = 'N' AND (tags->>'railway' IN ('tram_stop','station','halt')"
			+ " OR tags->>'highway' = 'bus_stop'"
			+ " OR (tags->>'public_transport' = 'stop_position' AND tags->>'tram' = 'yes')"
			+ " OR tags->>'man_made' IN ('tower','lighthouse','windmill'))",
			lat, lon, OsmQuery.CAP_STOPS + OsmQuery.CAP_PLATFORMS + 100),
		_part(near + " AND osm_type <> 'N' AND tags ? 'building'", lat, lon,
			OsmQuery.CAP_BUILDINGS_CORE + OsmQuery.CAP_BUILDINGS + OsmQuery.CAP_BUILDING_RELATIONS),
		_part(near + " AND osm_type <> 'N' AND tags ? 'building:part' AND NOT tags ? 'building'",
			lat, lon, OsmQuery.CAP_PARTS + OsmQuery.CAP_LANDMARK_PARTS),
		_part(near + " AND osm_type <> 'N' AND tags ?| ARRAY['highway','area:highway']"
			+ " AND NOT tags ?| ARRAY['building','building:part']",
			lat, lon, OsmQuery.CAP_HIGHWAYS + OsmQuery.CAP_SQUARES),
		_part(near + " AND osm_type <> 'N' AND NOT tags ?| ARRAY['building','building:part','highway','area:highway']"
			+ " AND " + OTHER_AREAS % _sql_list(rail), lat, lon, CAP_OTHER_AREAS),
		# The country (Overpass is_in): tags only, at the place's own point.
		"(SELECT osm_type, osm_id, tags, %s AS geom FROM postpass_polygon WHERE osm_type = 'R'" % _point(lat, lon)
			+ " AND tags->>'admin_level' = '2' AND tags ? 'ISO3166-1'"
			+ " AND ST_Intersects(geom, %s) LIMIT 4)" % _point(lat, lon),
	]
	return "data=" + " UNION ALL ".join(parts).uri_encode()

static func _points(coords: Variant) -> Array:
	var out: Array = []
	if coords is Array:
		for c in coords:
			if c is Array and (c as Array).size() >= 2:
				out.append({"lat": float(c[1]), "lon": float(c[0])})
	return out

## {"json": Overpass-shaped payload, "buildings": count}. Thread-safe.
## Postpass gives a way as a one-part Multi* geometry and an assembled
## relation area as a MultiPolygon whose `type` tag osm2pgsql dropped:
## a way keeps its line or outer ring, an area relation comes back as a
## multipolygon with one closed member per ring, and the country lookup
## (a relation answered as a point) becomes an Overpass `area` with its tags.
## Other relations (routes, lines) are left out, as the detailed query asks
## for areas only.
static func to_overpass_json(body: PackedByteArray) -> Dictionary:
	# A JSON instance, not JSON.parse_string: a plain-text error answer is
	# expected here and should not print an engine error.
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return {"json": "", "buildings": 0}
	var parsed: Variant = json.data
	if not (parsed is Dictionary and (parsed as Dictionary).get("features") is Array):
		return {"json": "", "buildings": 0}
	var elements: Array = []
	var buildings := 0
	for f in parsed["features"]:
		if not (f is Dictionary and f.get("properties") is Dictionary \
				and f.get("geometry") is Dictionary):
			continue
		var props: Dictionary = f["properties"]
		var geometry: Dictionary = f["geometry"]
		var tags: Dictionary = props.get("tags", {}) if props.get("tags") is Dictionary else {}
		if tags.is_empty():
			continue
		var id := int(props.get("osm_id", 0))
		var kind := str(geometry.get("type", ""))
		var coords: Variant = geometry.get("coordinates", [])
		match str(props.get("osm_type", "")):
			"N":
				if kind == "Point" and coords is Array and (coords as Array).size() >= 2:
					elements.append({"type": "node", "id": id, "lat": float(coords[1]),
						"lon": float(coords[0]), "tags": tags})
			"W":
				var geom: Array = []
				if kind == "LineString":
					geom = _points(coords)
				elif kind == "MultiLineString" or kind == "Polygon":
					geom = _points((coords as Array)[0]) if coords is Array and not (coords as Array).is_empty() else []
				elif kind == "MultiPolygon" and coords is Array and not (coords as Array).is_empty() \
						and coords[0] is Array and not (coords[0] as Array).is_empty():
					geom = _points(coords[0][0])
				if geom.size() >= 2:
					elements.append({"type": "way", "id": id, "tags": tags, "geometry": geom})
					buildings += int(geom.size() >= 3 and OsmApiFallback.names_building(tags))
			"R":
				# The country lookup: tags at a point, as Overpass prints an area.
				if kind == "Point" and tags.has("ISO3166-1"):
					elements.append({"type": "area", "id": 3600000000 + id, "tags": tags})
					continue
				if kind != "MultiPolygon" or not coords is Array:
					continue
				var members: Array = []
				for polygon in coords:
					if not polygon is Array:
						continue
					for i in (polygon as Array).size():
						var ring := _points(polygon[i])
						if ring.size() >= 3:
							members.append({"type": "way", "ref": 0,
								"role": "outer" if i == 0 else "inner", "geometry": ring})
				if not members.is_empty():
					var rel_tags := tags.duplicate()
					rel_tags["type"] = "multipolygon"
					elements.append({"type": "relation", "id": id, "tags": rel_tags,
						"members": members})
					buildings += int(OsmApiFallback.names_building(rel_tags))
	return {"json": JSON.stringify({"elements": elements}), "buildings": buildings}
