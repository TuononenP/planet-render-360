class_name HsyRegister
extends RefCounted

## HSY's capital-region building register (pks_rakennukset_paivittyva:
## Espoo, Vantaa, Kauniainen and Helsinki, from the population register,
## CC BY 4.0) from HSY's WFS: one footprint per building with its
## completion year, floor count (withheld for detached houses), facade
## and frame material, in the same VTJ codes as Helsinki's own register.
## Rows decode to HelsinkiRegister's shape (a point per building, the
## footprint's centroid) and fill OSM buildings through its `apply`, so
## Espoo's blocks get real years, eras and facade materials. Helsinki's
## buildings are dropped: the city's richer register covers them.

const URL := "https://kartta.hsy.fi/geoserver/wfs"
const LAYER := "asuminen_ja_maankaytto:pks_rakennukset_paivittyva"
const CREDIT := "Buildings: © HSY, capital region buildings (CC BY 4.0)"
const PROPERTIES := "kunta,kavu,kerrosten_lkm,julkisivu,rakennusaine,kerala,geom"
const HALF_M := HelsinkiRegister.HALF_M
const MAX_FEATURES := 20000
## Helsinki's municipality code.
const HELSINKI := "091"
## Helsinki's land, roughly (GK25): a window reaching past it toward
## Espoo (west), Vantaa (north) or Vantaa and Sipoo (east) asks HSY; one
## inside asks nothing (the window filter is all the WFS accepts).
const CITY_WEST_E := 25490500.0
const CITY_NORTH_N := 6681000.0
const CITY_EAST_E := 25508000.0

static func covers(lat: float, lon: float) -> bool:
	if not HsyCanopy.covers(lat, lon):
		return false
	var p := Gk25.from_latlon(lat, lon)
	return p.x - HALF_M < CITY_WEST_E or p.y + HALF_M > CITY_NORTH_N or p.x + HALF_M > CITY_EAST_E

static func request_url(lat: float, lon: float) -> String:
	var p := Gk25.forward(lat, lon)
	var e := roundf(p[0])
	var n := roundf(p[1])
	return "%s?service=WFS&version=2.0.0&request=GetFeature&typeNames=%s&outputFormat=application/json&count=%d&propertyName=%s&bbox=%d,%d,%d,%d,EPSG:3879" % [
		URL, LAYER, MAX_FEATURES, PROPERTIES,
		int(e - HALF_M), int(n - HALF_M), int(e + HALF_M), int(n + HALF_M)]

## HelsinkiRegister rows {e, n, floors, year, facade, structure, use, rl,
## basement, area} for the buildings outside Helsinki; null when the text
## is no feature collection.
static func decode(text: String) -> Variant:
	if not text.strip_edges().begins_with("{"):
		return null
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("features"):
		return null
	var rows: Array = []
	for f in (parsed as Dictionary)["features"]:
		if not (f is Dictionary):
			continue
		var p: Dictionary = (f as Dictionary).get("properties", {})
		if HelsinkiRegister._str(p.get("kunta")) == HELSINKI:
			continue
		var c := _centroid((f as Dictionary).get("geometry"))
		if c.is_empty():
			continue
		var year := int(HelsinkiRegister._num(p.get("kavu")))
		rows.append({"e": c[0], "n": c[1],
			"floors": int(_value(p.get("kerrosten_lkm"), 200.0)),
			"year": year if year >= 1700 and year <= 2100 else 0,
			"facade": _code(p.get("julkisivu")),
			"structure": _code(p.get("rakennusaine")),
			"use": "", "rl": "", "basement": 0.0,
			"area": _value(p.get("kerala"), 1.0e6)})
	return rows

## A count or area; 0 when absent or withheld (the register writes
## 999999999 for values it does not publish, detached houses' floors).
static func _value(v: Variant, limit: float) -> float:
	var x := HelsinkiRegister._num(v)
	return x if x > 0.0 and x < limit else 0.0

## A numeric code as the register's string ("1"); "" when absent.
static func _code(v: Variant) -> String:
	return str(int(v)) if (v is float or v is int) and v > 0 and v < 100 else ""

## Area-weighted centroid [E, N] of a Polygon / MultiPolygon's largest
## outer ring (64-bit: GK25 coordinates are ~2.5e7, past Vector2's
## precision); empty when there is none.
static func _centroid(g: Variant) -> PackedFloat64Array:
	var best := PackedFloat64Array()
	if not (g is Dictionary):
		return best
	var polys: Array = []
	match str((g as Dictionary).get("type", "")):
		"Polygon":
			polys = [(g as Dictionary)["coordinates"]]
		"MultiPolygon":
			polys = (g as Dictionary)["coordinates"]
	var best_a := 0.0
	for poly in polys:
		if not (poly is Array) or (poly as Array).is_empty():
			continue
		var ring: Array = poly[0]
		if ring.size() < 4:
			continue
		var oe := float(ring[0][0])
		var on := float(ring[0][1])
		var a := 0.0
		var ce := 0.0
		var cn := 0.0
		for i in ring.size() - 1:
			var e0 := float(ring[i][0]) - oe
			var n0 := float(ring[i][1]) - on
			var e1 := float(ring[i + 1][0]) - oe
			var n1 := float(ring[i + 1][1]) - on
			var cr := e0 * n1 - e1 * n0
			a += cr
			ce += (e0 + e1) * cr
			cn += (n0 + n1) * cr
		if absf(a) > best_a:
			best_a = absf(a)
			best = PackedFloat64Array([oe + ce / (3.0 * a), on + cn / (3.0 * a)])
	return best
