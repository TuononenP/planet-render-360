class_name OsmRail
extends RefCounted

## OSM railway tag interpretation for OsmParser: track ways, platform
## ways/areas and transit stop nodes (stations, subway entrances) ->
## LocationData.railways / rail_platforms / transit_stops entries.
## Pure functions over tag dictionaries, like OsmTags.

## railway=* values that are running track. Disused/abandoned/razed
## lines are not drawn (their rails are usually gone or overgrown).
const TRACK_CLASSES := ["rail", "subway", "light_rail", "tram", "narrow_gauge",
	"monorail", "funicular", "preserved"]
## railway=* point values kept as transit stops.
const STOP_CLASSES := ["station", "halt", "subway_entrance",
	"train_station_entrance", "tram_stop"]
## Default track gauge per class (metres) when no `gauge` tag is set.
const GAUGE_M := {"narrow_gauge": 1.0, "funicular": 1.0, "monorail": 0.0}
const STANDARD_GAUGE_M := 1.435

static func is_track(tags: Dictionary) -> bool:
	return str(tags.get("railway", "")) in TRACK_CLASSES

static func is_platform(tags: Dictionary) -> bool:
	return str(tags.get("railway", "")) == "platform"

static func is_stop(tags: Dictionary) -> bool:
	return str(tags.get("railway", "")) in STOP_CLASSES

## Below ground: a tunnel, a negative layer/level, or location=underground.
## Underground track and platforms are never drawn (no shards on the
## street over a subway line).
static func underground(tags: Dictionary) -> bool:
	if OsmTags._tag_truthy(tags.get("tunnel", "")) and str(tags.get("tunnel", "")) != "building_passage":
		return true
	var loc := str(tags.get("location", "")).to_lower()
	if loc in ["underground", "underwater"]:
		return true
	if str(tags.get("layer", "0")).strip_edges().is_valid_int() \
			and str(tags.get("layer", "0")).strip_edges().to_int() < 0:
		return true
	var level := str(tags.get("level", "")).split(";")[0].strip_edges()
	return level.is_valid_float() and level.to_float() < 0.0

## Track gauge in metres from the `gauge` tag (millimetres, possibly a
## "1435;1000" dual-gauge list: the first wins), else the class default.
static func gauge_m(tags: Dictionary, cls: String) -> float:
	var raw := str(tags.get("gauge", "")).split(";")[0].strip_edges()
	if raw.is_valid_int():
		var mm := raw.to_int()
		if mm >= 380 and mm <= 2000:
			return float(mm) / 1000.0
	return float(GAUGE_M.get(cls, STANDARD_GAUGE_M))

## One track dict: {points, class, gauge_m, service, bridge, tunnel,
## layer, electrified, embedded, name}. `embedded` marks track set
## flush into a street (trams unless embedded=no) — no ballast bed.
static func track_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	var cls := str(tags.get("railway", "rail"))
	var elec := str(tags.get("electrified", "")).to_lower()
	var embedded_tag := str(tags.get("embedded", "")).to_lower()
	var embedded := embedded_tag in ["yes", "partially"] \
		or (cls == "tram" and embedded_tag != "no")
	return {"points": pts, "class": cls, "gauge_m": gauge_m(tags, cls),
		"service": str(tags.get("service", "")),
		"bridge": OsmTags._tag_truthy(tags.get("bridge", "")),
		"tunnel": underground(tags),
		"layer": OsmTags._tag_int(tags.get("layer", 0), -10, 10),
		"electrified": "contact_line" if elec.begins_with("contact_line") \
			else ("rail" if elec.begins_with("rail") else ""),
		"embedded": embedded,
		"name": str(tags.get("name", ""))}

## One platform dict: {points, closed, height_m, width_m, covered,
## layer, tunnel, name}. `covered` is "yes" / "partial" / "no" / "".
static func platform_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	var covered := str(tags.get("covered", tags.get("shelter", ""))).to_lower()
	if covered in ["yes", "roof", "canopy", "arcade"]:
		covered = "yes"
	elif covered not in ["partial", "no"]:
		covered = ""
	var h := OsmTags._tag_metres(tags.get("height", ""), 0.1, 2.0)
	var w := OsmTags._tag_metres(tags.get("width", ""), 1.0, 30.0)
	return {"points": pts, "closed": OsmGeometry._is_closed(pts),
		"height_m": 0.0 if is_nan(h) else h,
		"width_m": 0.0 if is_nan(w) else w,
		"covered": covered,
		"layer": OsmTags._tag_int(tags.get("layer", tags.get("level", 0)), -10, 10),
		"tunnel": underground(tags),
		"name": str(tags.get("name", ""))}

## One transit stop dict: {x, z, kind, station, name, ref, direction,
## wheelchair, tunnel}. `kind` is the railway value; `station` the
## station= mode (subway, light_rail, train, ...); `direction` degrees
## clockwise from north when tagged (the way a subway stair descends),
## else NAN.
static func stop_entry(tags: Dictionary, p: Vector2) -> Dictionary:
	var dir_raw := str(tags.get("direction", "")).strip_edges()
	var dir := dir_raw.to_float() if dir_raw.is_valid_float() else _compass(dir_raw)
	return {"x": p.x, "z": p.y, "kind": str(tags.get("railway", "")),
		"station": str(tags.get("station", tags.get("subway", ""))),
		"name": str(tags.get("name", "")),
		"ref": str(tags.get("ref", "")),
		"direction": dir,
		"wheelchair": str(tags.get("wheelchair", "")),
		"elevator": str(tags.get("entrance", "")) == "elevator" \
			or str(tags.get("subway_entrance", "")) == "elevator",
		"tunnel": underground(tags)}

## Compass point ("N", "NE", "ssw") -> degrees, NAN when not one.
static func _compass(s: String) -> float:
	var pts := ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
		"S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
	var i := pts.find(s.to_upper())
	return NAN if i < 0 else float(i) * 22.5
