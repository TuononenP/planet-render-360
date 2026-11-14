class_name HelsinkiRegister
extends RefCounted

## The City of Helsinki's open building register (Rakennukset, register
## attributes; CC BY 4.0), from the city's WFS: one point per building
## with its floor count, completion date, facade / frame material and
## use class. `apply` matches each point to the OSM footprint it falls in
## and fills only what the map leaves out (BuildingReferences.fill):
## real storeys and years drive BuildingEra and the dated Helsinki eras,
## facade codes FacadeMaterials. Helsinki only; Espoo has no open
## register (docs/data-source-register.md).

const URL := "https://kartta.hel.fi/ws/geoserver/avoindata/wfs"
const LAYER := "avoindata:Rakennukset_alue_rekisteritiedot"
const CREDIT := "Buildings: © City of Helsinki, building register (CC BY 4.0)"
const PROPERTIES := "i_ekoord,i_nkoord,i_kerrlkm,i_kerrosala,c_valmpvm,c_julkisivu,c_rakeaine,c_kayttark,c_rakennusluokka,i_kellarala,tila_koodi"
## Half width of the requested window (HelsinkiDem's, past the 2.4 km
## detailed extent).
const HALF_M := 1450.0
const MAX_FEATURES := 20000
## In-service buildings (tila "voimassa"); demolished ones are 3+.
const IN_SERVICE := 2
## A register point a little outside every footprint (a corner-placed
## point, a footprint drawn slightly small) still joins the nearest one.
const SNAP_M := 3.5
const CELL_M := 50.0
## Storey height when register floors give a missing height (the
## OSM `building:levels` rule, OsmTags._resolve_height).
const STOREY_M := 3.2
const PROVENANCE := "hel_register"

## Whether a window around (lat, lon) can hold register buildings: the
## city's grid extent (HelsinkiDem) grown by the window, so a viewpoint
## just over the border (Keilaniemi) still gets the Helsinki side.
static func covers(lat: float, lon: float) -> bool:
	if lat < 60.0 or lat > 60.4 or lon < 24.5 or lon > 25.3:
		return false
	var p := Gk25.from_latlon(lat, lon)
	return p.x + HALF_M >= HelsinkiDem.MIN_E and p.x - HALF_M <= HelsinkiDem.MAX_E \
		and p.y + HALF_M >= HelsinkiDem.MIN_N and p.y - HALF_M <= HelsinkiDem.MAX_N

## The GetFeature URL for the window round (lat, lon), snapped to whole
## metres so the same place asks for the same bytes. bbox is E,N order.
static func request_url(lat: float, lon: float) -> String:
	var p := Gk25.forward(lat, lon)
	var e := roundf(p[0])
	var n := roundf(p[1])
	return "%s?service=WFS&version=2.0.0&request=GetFeature&typeNames=%s&outputFormat=application/json&count=%d&propertyName=%s&bbox=%d,%d,%d,%d,EPSG:3879" % [
		URL, LAYER, MAX_FEATURES, PROPERTIES,
		int(e - HALF_M), int(n - HALF_M), int(e + HALF_M), int(n + HALF_M)]

## Rows from a GetFeature GeoJSON answer: {e, n, floors, year, facade,
## structure, use, rl, basement, area}; in-service buildings with a
## position only. null when the text is no feature collection.
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
		var p: Dictionary = (f as Dictionary).get("properties", {})
		if _num(p.get("tila_koodi")) != float(IN_SERVICE):
			continue
		var e := _num(p.get("i_ekoord"))
		var n := _num(p.get("i_nkoord"))
		if e <= 0.0 or n <= 0.0:
			continue
		rows.append({"e": e, "n": n,
			"floors": int(_num(p.get("i_kerrlkm"))),
			"year": _year(p.get("c_valmpvm")),
			"facade": _str(p.get("c_julkisivu")),
			"structure": _str(p.get("c_rakeaine")),
			"use": _str(p.get("c_kayttark")),
			"rl": _str(p.get("c_rakennusluokka")),
			"basement": _num(p.get("i_kellarala")),
			"area": _num(p.get("i_kerrosala"))})
	return rows

static func _num(v: Variant) -> float:
	return float(v) if v is float or v is int else 0.0

static func _str(v: Variant) -> String:
	return "" if v == null else str(v).strip_edges()

## Completion year from an ISO date ("1957-12-31T00:00:00+02:00"); 0 when
## absent or implausible.
static func _year(v: Variant) -> int:
	var s := _str(v)
	if s.length() < 4 or not s.substr(0, 4).is_valid_int():
		return 0
	var y := s.substr(0, 4).to_int()
	return y if y >= 1700 and y <= 2100 else 0

## Fills `buildings` (local metre footprints around c_lat, c_lon) from
## register `rows`, in place. Returns {rows, matched, filled}.
static func apply(buildings: Array, c_lat: float, c_lon: float, rows: Array) -> Dictionary:
	var stats := {"rows": rows.size(), "matched": 0, "filled": 0}
	if rows.is_empty() or buildings.is_empty():
		return stats
	var grid := _grid(buildings)
	var hits := {}  # building index -> [rows]
	var f := Gk25.frame(c_lat, c_lon)
	for r in rows:
		var p := Gk25.frame_xz(f, float(r["e"]), float(r["n"]))
		var i := _owner(buildings, grid, p)
		if i < 0:
			continue
		if not hits.has(i):
			hits[i] = []
		(hits[i] as Array).append(r)
		stats["matched"] = int(stats["matched"]) + 1
	for i in hits:
		if not _enrich(buildings[i], hits[i]).is_empty():
			stats["filled"] = int(stats["filled"]) + 1
	return stats

## Whether a building takes register facts: not a part-modelled
## landmark, a vessel or a fortification (their own builders).
static func _eligible(b: Dictionary) -> bool:
	return (b.get("parts", []) as Array).is_empty() \
		and not str(b.get("kind", "")) in ["ship", "boat", "houseboat"] \
		and not b.has("defensive_works") and not b.get("suomenlinna", false)

## Building index buckets per CELL_M cell of each footprint's AABB.
static func _grid(buildings: Array) -> Dictionary:
	var grid := {}
	for i in buildings.size():
		var b: Variant = buildings[i]
		if not (b is Dictionary) or not _eligible(b):
			continue
		var fp: PackedVector2Array = (b as Dictionary).get("footprint", PackedVector2Array())
		if fp.size() < 3:
			continue
		var lo := fp[0]
		var hi := fp[0]
		for q in fp:
			lo = lo.min(q)
			hi = hi.max(q)
		lo -= Vector2(SNAP_M, SNAP_M)
		hi += Vector2(SNAP_M, SNAP_M)
		for cx in range(floori(lo.x / CELL_M), floori(hi.x / CELL_M) + 1):
			for cz in range(floori(lo.y / CELL_M), floori(hi.y / CELL_M) + 1):
				var key := Vector2i(cx, cz)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(i)
	return grid

## The building containing `p`, else the nearest within SNAP_M; -1 none.
static func _owner(buildings: Array, grid: Dictionary, p: Vector2) -> int:
	var key := Vector2i(floori(p.x / CELL_M), floori(p.y / CELL_M))
	var near := -1
	var near_d := SNAP_M
	for i in grid.get(key, []):
		var b: Dictionary = buildings[i]
		var fp: PackedVector2Array = b["footprint"]
		if WorldScale.point_in_polygon(p, fp):
			var in_hole := false
			for h in b.get("holes", []):
				if WorldScale.point_in_polygon(p, h):
					in_hole = true
					break
			if not in_hole:
				return i
		var d := _edge_distance(p, fp)
		if d < near_d:
			near_d = d
			near = i
	return near

static func _edge_distance(p: Vector2, fp: PackedVector2Array) -> float:
	var best := INF
	for k in fp.size():
		var a := fp[k]
		var b := fp[(k + 1) % fp.size()]
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best

## Fills one building from its register rows (several buildings of one
## register entry can share an OSM outline): the most floors, and the
## year / materials / use of the largest by floor area. Returns the
## filled keys.
static func _enrich(b: Dictionary, rows: Array) -> Array:
	var floors := 0
	var main: Dictionary = rows[0]
	for r in rows:
		floors = maxi(floors, int(r["floors"]))
		if float(r["area"]) > float(main["area"]):
			main = r
	var year := int(main["year"])
	var fields: Array = []
	if floors > 0 and float(b.get("levels", 0.0)) <= 0.0:
		b["levels"] = float(floors)
		fields.append("levels")
		if str(b.get("height_source", "")) == "default":
			b["height"] = maxf(6.0, float(floors) * STOREY_M)
			b["height_source"] = "levels"
			fields.append("height")
	var values := {}
	if year > 0:
		values["start_year"] = year
	var material := RegisterCodes.facade_for(str(main["facade"]), str(main["structure"]),
		year, floors if floors > 0 else int(b.get("levels", 0.0)))
	if material != "":
		values["material"] = material
	if float(main["basement"]) > 0.0:
		values["basement_m2"] = float(main["basement"])
	fields.append_array(BuildingReferences.fill(b, values))
	var kind := RegisterCodes.kind_for(str(main["use"]), str(main["rl"]))
	if kind != "" and str(b.get("kind", "yes")) in ["yes", "residential", "building"]:
		b["kind"] = kind
		fields.append("kind")
	if not fields.is_empty():
		var enriched: Dictionary = b.get("enriched", {})
		enriched[PROVENANCE] = fields
		b["enriched"] = enriched
	return fields
