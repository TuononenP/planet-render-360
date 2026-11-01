class_name MapStyle
extends RefCounted

## The design system's Map style as code: the `map-*` palettes (Night: a
## mid-tone dusk slate, lighter than panel glass; Day: cool paper) and the
## rules that turn OpenMapTiles features into fills, lines and labels.
## Zooms here are style zooms (MapLibre's, 512px tiles): the picker's
## 256px zoom level minus one. The reference style JSON lives in the design
## system (assets/Map/pr360-map-night.json, pr360-map-day.json); keep the
## two in step.

const NIGHT := {
	"land": Color("47515f"), "landuse": Color("4b5564"), "park": Color("4a5f55"),
	"wood": Color("465b51"), "ice": Color("6f7d93"), "sand": Color("555049"),
	"water": Color("263b55"), "waterway": Color("34507a"), "building": Color("555f6e"),
	"building_line": Color("616c7b"), "road_minor": Color("6e7989"),
	"road_service": Color("606b7b"), "road_secondary": Color("8e98a6"),
	"road_primary": Color("adb5c1"), "road_trunk": Color("c5ccd5"), "motorway": Color("dcc59a"),
	"motorway_casing": Color("3b4451"), "casing": Color("3b4451"), "path": Color("6f7a8a"),
	"rail": Color("7f8a9a"), "boundary": Color("a3acb9"), "boundary_state": Color("737e8e"),
	"graticule": Color(0.929, 0.945, 0.965, 0.08), "aeroway": Color("535d6c"),
	"label": Color("f2f5f8"), "label_minor": Color("d0d6de"), "label_halo": Color("353e4b"),
	"road_label": Color("c9d0d9"), "water_label": Color("9cc0e6"), "peak": Color("e6eaf0"),
	"peak_ele": Color("c3cad5"), "hillshade_shadow": Color("1c2431"),
	"hillshade_light": Color("7b879a"),
}
const DAY := {
	"land": Color("eef0ec"), "landuse": Color("e8eae5"), "park": Color("d6e6cf"),
	"wood": Color("d0e2c8"), "ice": Color("e2edf7"), "sand": Color("efe8d8"),
	"water": Color("a9cbe8"), "waterway": Color("93bce0"), "building": Color("e1e2dd"),
	"building_line": Color("cfd1cb"), "road_minor": Color("ffffff"),
	"road_service": Color("fbfbfa"), "road_secondary": Color("ffffff"),
	"road_primary": Color("ffffff"), "road_trunk": Color("fff6e3"), "motorway": Color("f7d79c"),
	"motorway_casing": Color("dcb46d"), "casing": Color("cfd3d8"), "path": Color("c4c9cf"),
	"rail": Color("b4b9c1"), "boundary": Color("8a7e9e"), "boundary_state": Color("b9b2c6"),
	"graticule": Color(0.051, 0.078, 0.125, 0.07), "aeroway": Color("e2e4e7"),
	"label": Color("1f2733"), "label_minor": Color("4a5463"), "label_halo": Color("f7f8f6"),
	"road_label": Color("4a5463"), "water_label": Color("24507a"), "peak": Color("2c3440"),
	"peak_ele": Color("5a6474"), "hillshade_shadow": Color("56607a"),
	"hillshade_light": Color("ffffff"),
}
## Hillshade opacity by style zoom (map-hillshade, tapering to a whisper).
const SHADE_NIGHT := [[3.0, 0.6], [8.0, 0.42], [11.0, 0.26], [15.0, 0.16]]
const SHADE_DAY := [[3.0, 0.6], [8.0, 0.45], [11.0, 0.3], [15.0, 0.18]]
## No DEM fetch from here up: at street level the relief is a whisper and
## not worth a second download per tile.
const SHADE_MAX_ZOOM := 12

const NAME_KEYS := ["name:en", "name:latin", "name"]
## Layers and the tag keys MvtReader keeps for each.
const WANTED := {
	"water": ["class", "brunnel"],
	"waterway": ["class", "brunnel", "name", "name:en", "name:latin"],
	"landcover": ["class"],
	"landuse": ["class"],
	"park": ["class"],
	"aeroway": ["class"],
	"building": [],
	"transportation": ["class", "brunnel"],
	"transportation_name": ["class", "name", "name:en", "name:latin"],
	"boundary": ["admin_level", "maritime", "disputed"],
	"place": ["class", "rank", "capital", "name", "name:en", "name:latin"],
	"water_name": ["class", "name", "name:en", "name:latin"],
	"mountain_peak": ["ele", "name", "name:en", "name:latin"],
	"poi": ["class", "rank", "name", "name:en", "name:latin"],
}

## Layers below these style zooms are never drawn, so they are not decoded
## (buildings fade in from 13, so at a whole zoom 13 they are still clear)
## (a dense city tile's poi layer alone is most of its bytes).
const LAYER_MIN_ZOOM := {
	"poi": 14.0, "building": 13.5, "transportation_name": 13.0, "aeroway": 11.0,
	"mountain_peak": 8.0, "waterway": 8.0,
}

## WANTED trimmed to what the style draws at `zoom`.
static func wanted(zoom: float) -> Dictionary:
	var out := {}
	for layer in WANTED:
		if zoom >= float(LAYER_MIN_ZOOM.get(layer, 0.0)):
			out[layer] = WANTED[layer]
	return out

## Draw order buckets. Everything below SHADE_ORDER draws under the
## hillshade, the rest above it.
const SHADE_ORDER := 10.0

## Road classes, bottom to top: [classes, minzoom, width stops, colour key, cased].
const ROADS := [
	[["path"], 14.0, [[14.0, 0.5], [18.0, 2.0]], "path", false],
	[["service", "track"], 14.0, [[14.0, 0.5], [18.0, 6.0]], "road_service", false],
	[["minor"], 12.0, [[12.0, 0.5], [14.0, 2.0], [18.0, 14.0]], "road_minor", true],
	[["tertiary"], 10.0, [[10.0, 0.5], [14.0, 3.0], [18.0, 18.0]], "road_secondary", true],
	[["secondary"], 9.0, [[9.0, 0.6], [14.0, 3.5], [18.0, 20.0]], "road_secondary", true],
	[["primary"], 7.0, [[7.0, 0.6], [14.0, 4.5], [18.0, 24.0]], "road_primary", true],
	[["trunk"], 5.0, [[5.0, 0.6], [14.0, 5.0], [18.0, 26.0]], "road_trunk", true],
	[["motorway"], 5.0, [[5.0, 0.8], [10.0, 2.0], [14.0, 5.5], [18.0, 28.0]], "motorway", true],
]
const CASING_STOPS := [[10.0, 0.5], [14.0, 1.0], [18.0, 2.0]]

static func colors() -> Dictionary:
	return DAY if UiTheme.is_day else NIGHT

static func shade_strength(zoom: float, day: bool) -> float:
	return linear(SHADE_DAY if day else SHADE_NIGHT, zoom)

## MapLibre's exponential interpolation (base 1.45) over [zoom, value] stops.
static func width(stops: Array, zoom: float) -> float:
	if zoom <= float(stops[0][0]):
		return float(stops[0][1])
	for i in range(1, stops.size()):
		var z1 := float(stops[i][0])
		if zoom <= z1:
			var z0 := float(stops[i - 1][0])
			var v0 := float(stops[i - 1][1])
			var v1 := float(stops[i][1])
			var t := (pow(1.45, zoom - z0) - 1.0) / (pow(1.45, z1 - z0) - 1.0)
			return lerpf(v0, v1, t)
	return float(stops[stops.size() - 1][1])

static func linear(stops: Array, zoom: float) -> float:
	if zoom <= float(stops[0][0]):
		return float(stops[0][1])
	for i in range(1, stops.size()):
		var z1 := float(stops[i][0])
		if zoom <= z1:
			var z0 := float(stops[i - 1][0])
			return lerpf(float(stops[i - 1][1]), float(stops[i][1]), (zoom - z0) / (z1 - z0))
	return float(stops[stops.size() - 1][1])

## Fill for a polygon feature: [order, colour] or [] to skip.
static func fill_for(layer: String, tags: Dictionary, zoom: float, c: Dictionary) -> Array:
	var cls := str(tags.get("class", ""))
	match layer:
		"landuse":
			if cls in ["residential", "suburb", "neighbourhood", "commercial", "industrial", "retail"]:
				if zoom < 10.0:
					return []
				return [1.0, Color(c["landuse"], clampf((zoom - 10.0) / 2.0, 0.0, 1.0))]
			if cls in ["cemetery", "pitch", "stadium", "playground", "garden"]:
				return [11.0, c["park"]]
		"landcover":
			match cls:
				"wood", "forest":
					return [2.0, Color(c["wood"], 0.9)]
				"grass", "farmland", "wetland":
					return [3.0, Color(c["park"], 0.45)]
				"sand":
					return [4.0, c["sand"]]
				"ice":
					return [5.0, Color(c["ice"], 0.9)]
		"park":
			return [6.0, Color(c["park"], clampf(0.5 + (zoom - 6.0) * 0.1, 0.5, 1.0))]
		"water":
			if str(tags.get("brunnel", "")) != "tunnel":
				return [12.0, c["water"]]
		"aeroway":
			if zoom >= 11.0:
				return [14.0, c["aeroway"]]
		"building":
			if zoom >= 13.0:
				return [15.0, Color(c["building"], clampf((zoom - 13.0) / 1.5, 0.0, 1.0))]
	return []

## Lines for a line feature: Array of [order, colour, width px, dash] where
## dash is [on, off] in multiples of the width, or [] for solid.
static func lines_for(layer: String, tags: Dictionary, zoom: float, c: Dictionary) -> Array:
	var cls := str(tags.get("class", ""))
	match layer:
		"waterway":
			if str(tags.get("brunnel", "")) != "tunnel" and zoom >= 8.0:
				return [[13.0, c["waterway"], width([[8.0, 0.5], [13.0, 1.5], [18.0, 6.0]], zoom), []]]
		"aeroway":
			if zoom >= 11.0 and cls in ["runway", "taxiway"]:
				return [[14.0, c["aeroway"], width([[11.0, 2.0], [17.0, 40.0]], zoom), []]]
		"transportation":
			return _road_lines(cls, str(tags.get("brunnel", "")), zoom, c)
		"boundary":
			var level := int(tags.get("admin_level", 0))
			if int(tags.get("maritime", 0)) == 1:
				return []
			if level == 4 and zoom >= 3.0:
				return [[51.0, c["boundary_state"], width([[3.0, 0.6], [10.0, 1.5]], zoom), [2.0, 2.0]]]
			if level == 2 and int(tags.get("disputed", 0)) != 1:
				return [[52.0, c["boundary"], width([[0.0, 0.6], [5.0, 1.2], [12.0, 2.5]], zoom), []]]
	return []

static func _road_lines(cls: String, brunnel: String, zoom: float, c: Dictionary) -> Array:
	if cls in ["rail", "transit"]:
		if zoom < 11.0:
			return []
		return [[50.0, c["rail"], width([[11.0, 0.6], [18.0, 2.5]], zoom), [3.0, 2.0]]]
	# Tunnels under surface roads under bridges; casings under fills.
	var base := 20.0 if brunnel == "tunnel" else (40.0 if brunnel == "bridge" else 30.0)
	var alpha := 0.55 if brunnel == "tunnel" else 1.0
	for i in ROADS.size():
		var road: Array = ROADS[i]
		if not (cls in (road[0] as Array)) or zoom < float(road[1]):
			continue
		var w := width(road[2], zoom)
		var fill_dash: Array = [1.0, 1.5] if cls == "path" else []
		var out := [[base + 1.0 + i * 0.01, Color(c[road[3]], alpha), w, fill_dash]]
		var casing_zoom := float(road[1]) + (1.0 if cls in ["minor", "tertiary"] else 0.0)
		if bool(road[4]) and zoom >= casing_zoom:
			var case_color: Color = c["motorway_casing"] if cls == "motorway" else c["casing"]
			var case_dash: Array = [0.6, 0.4] if brunnel == "tunnel" else []
			out.append([base + i * 0.01, Color(case_color, alpha),
				w + 2.0 * width(CASING_STOPS, zoom), case_dash])
		return out
	return []

## A label candidate for a point/line feature, or {} to skip. pos and the
## segment are filled in by the builder; this decides text and rank.
static func label_for(layer: String, tags: Dictionary, zoom: float) -> Dictionary:
	var name := label_name(tags)
	if name == "":
		return {}
	var cls := str(tags.get("class", ""))
	var rank := int(tags.get("rank", 10))
	match layer:
		"place":
			match cls:
				"country":
					if rank > 3 and zoom < 5.0:
						return {}
					if zoom >= 7.0:
						return {}
					return _label(name.to_upper(), "country", rank, lerpf(10.0, 15.0, clampf((zoom - 1.0) / 4.0, 0.0, 1.0)))
				"state":
					if zoom < 4.0 or zoom >= 7.0:
						return {}
					return _label(name.to_upper(), "state", 10 + rank, 11.0)
				"city":
					if zoom < 3.0:
						return {}
					return _label(name, "city", 20 + rank, 12.0 + clampf(zoom - 4.0, 0.0, 8.0))
				"town":
					return {} if zoom < 8.0 else _label(name, "town", 40 + rank, 13.0)
				"village", "hamlet":
					return {} if zoom < 10.0 else _label(name, "village", 50 + rank, 12.0)
				"suburb", "neighbourhood", "quarter":
					if zoom < 12.0:
						return {}
					return _label(name.to_upper(), "suburb", 60 + rank, 11.0)
		"water_name":
			if cls == "lake" and zoom < 11.0:
				return {}
			return _label(name, "water", 45, 13.0)
		"mountain_peak":
			if zoom < 8.0 or not tags.has("ele"):
				return {}
			var label := _label(name, "peak", 30, 12.0)
			label["sub"] = "%s m" % group_thousands(int(tags["ele"]))
			label["ele"] = int(tags["ele"])
			return label
		"poi":
			if zoom < 14.0 or rank > 2 or not (cls in ["attraction", "castle", "monument", "museum"]):
				return {}
			return _label(name, "landmark", 70 + rank, 12.0)
		"transportation_name":
			if zoom < 13.0 or not (cls in ["motorway", "trunk", "primary", "secondary", "tertiary", "minor"]):
				return {}
			return _label(name, "road", 80, 11.0 if zoom < 14.0 else 12.0)
		"waterway":
			if zoom < 12.0 or not (cls in ["river", "canal"]):
				return {}
			return _label(name, "river", 75, 12.0)
	return {}

static func _label(text: String, kind: String, priority: int, size: float) -> Dictionary:
	return {"text": text, "kind": kind, "priority": priority, "size": size}

static func label_name(tags: Dictionary) -> String:
	for key in NAME_KEYS:
		var v := str(tags.get(key, ""))
		if v != "":
			return v
	return ""

## "4478" -> "4,478" (design system data formatting).
static func group_thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
