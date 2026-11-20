class_name FinnishGranite
extends RefCounted

## Southern Finland's stone: pink-grey rapakivi granite and gneiss. Bedrock
## outcrops and shore rock, the setts and slabs of the centre's squares and
## the granite kerbs read warmer and lighter than the neutral stone the
## shared ground, road and kerb finishes assume. Everything here is gated
## on `applies`; other places keep their colours.

## Helsinki's metro area and Turku, with or without a country tag.
const CITIES := ["helsinki", "espoo", "turku"]
## Ground-paint colours (sRGB): bare rock, and the sett finish.
const ROCK := Color(0.54, 0.47, 0.45)
const SETT_HEX := "#807977"
## Granite slabs of the squares and esplanades (Senate Square, Kauppatori,
## Esplanadi footways): a pink-grey a little darker and warmer than the
## shared paving finish.
const PAVING_HEX := "#767070"
## Park gravel: the red-brown crushed-granite sand of Helsinki's park paths
## (Esplanadi, Kaivopuisto), warmer than the tan gravel the shared finish
## assumes. Laid on compacted/gravel ways and on unsurfaced park footways.
const GRAVEL_HEX := "#9c6e56"
## A raised granite kerb (linear-ish albedo, as KerbBuilder.GRANITE): paler
## than the dark kerb stone elsewhere.
const KERB := Color(0.40, 0.37, 0.36)

static func applies(data: LocationData) -> bool:
	if data == null:
		return false
	if data.country.to_upper() == "FI":
		return true
	return CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) in CITIES

## `rock` / `sett` / `path` / paving ground-palette overrides: a colour with alpha 1 per
## class id, an empty dictionary elsewhere.
static func palette_overrides(data: LocationData) -> Dictionary:
	if not applies(data):
		return {}
	var slab := Color.html(PAVING_HEX)
	return {"rock": ROCK, "sett": Color.html(SETT_HEX), "urban": slab, "building": slab,
		"path": Color.html(GRAVEL_HEX)}

## Whether a way is a park path laid in gravel: a footway or path with no
## surface tag lying in a green polygon (`parks`, GroundMaterial._grass_polys),
## judged at its middle vertex (units).
static func park_way(road: Dictionary, parks: Array) -> bool:
	if parks.is_empty() or str(road.get("surface", "")) != "" or bool(road.get("crossing", false)) \
			or bool(road.get("bridge", false)) or bool(road.get("kerb_line", false)) \
			or str(road.get("class", "")) not in ["footway", "path"]:
		return false
	var pts: PackedVector2Array = road.get("points", PackedVector2Array())
	return not pts.is_empty() and GroundMaterial._grass_at(pts[pts.size() / 2], parks)
