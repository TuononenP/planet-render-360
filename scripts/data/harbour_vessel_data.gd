class_name HarbourVesselData
extends RefCounted

## Real harbour traffic as data rows: commuter ferry routes, cruise ferry
## liveries by terminal, moored fleets (icebreakers, market boats) and
## small-boat fleet profiles. Points are WGS84 [lat, lon]; a row whose
## points fall outside the built square is simply skipped, so each city's
## vessels are rows here rather than code paths in the builders.
## Scenery, not live positions: ships stand where the route or quay puts
## them, never where AIS says they are.

## Commuter ferries. A "terminal" row berths beside the mapped terminal
## building whose name contains `terminal_name` (HarbourFerries.berth);
## a "route" row puts one vessel per `ships` entry on the OSM route=ferry
## polyline: `at` is the share of the route from its first point, and a
## berthed vessel lies at the first stretch from `at` where its whole hull
## is clear water. Routes: OSM ways, fetched 2026-11-19 from
## overpass.openstreetmap.fr (ODbL); the first point is the city pier.
const FERRY_ROUTES := [
	{"id": "staten_island", "kind": "terminal", "terminal_name": "staten island ferry",
		"model": "staten_island", "length_m": 94.5, "beam_m": 21.3},
	# HSL line 19 (Suomenlinnan Liikenne): OSM way 123403659 in route
	# relation 155054, Kauppatori pier (Keisarinluoto) to the Suomenlinna
	# main quay (päälaituri). M/S Suomenlinna II class: about 38 x 10 m,
	# white hull with the HSL blue band, "SUOMENLINNA – SVEABORG".
	{"id": "hsl_19", "kind": "route", "model": "suomenlinna", "osm": "way/123403659",
		"name": "19 Kauppatori–Suomenlinna", "length_m": 38.0, "beam_m": 10.0,
		"lettering": "SUOMENLINNA – SVEABORG", "hull": "#f2f1ec", "band": "#0072c6",
		"route": [[60.16726, 24.95584], [60.16726, 24.95611], [60.16637, 24.95625], [60.16301, 24.96633],
			[60.16208, 24.97009], [60.15875, 24.98196], [60.14930, 24.98385], [60.14927, 24.98394]],
		"ships": [{"at": 0.0, "berthed": true}, {"at": 0.62}]},
	# JT-Line water bus, Kauppatori (Kolera-allas) to Lonna and on to
	# Suomenlinna: OSM way 1273138416 (in route relation 14275018),
	# reversed so it starts at the market square.
	{"id": "jt_lonna", "kind": "route", "model": "water_bus", "osm": "way/1273138416",
		"name": "Kauppatori–Lonna–Suomenlinna", "length_m": 23.0, "beam_m": 6.4,
		"lettering": "JT-LINE", "hull": "#f2f1ec", "band": "#1c2b46",
		"route": [[60.16688, 24.95543], [60.16675, 24.95527], [60.16644, 24.95530], [60.16486, 24.95979],
			[60.16269, 24.96599], [60.16175, 24.96948], [60.15805, 24.98117], [60.15379, 24.98671],
			[60.15377, 24.98923]],
		"ships": [{"at": 0.0, "berthed": true}, {"at": 0.34}]},
	# JT-Line water bus to Korkeasaari (the zoo) round Katajanokka: OSM way
	# 26317836 (operator=JT-Line).
	{"id": "jt_korkeasaari", "kind": "route", "model": "water_bus", "osm": "way/26317836",
		"name": "Kauppatori–Korkeasaari", "length_m": 21.0, "beam_m": 6.0,
		"lettering": "JT-LINE", "hull": "#f2f1ec", "band": "#1c2b46",
		"route": [[60.16687, 24.95490], [60.16676, 24.95508], [60.16654, 24.95557], [60.16389, 24.96353],
			[60.16292, 24.96644], [60.16192, 24.97048], [60.16412, 24.97699], [60.16570, 24.98195],
			[60.16668, 24.98283], [60.16730, 24.98311], [60.16808, 24.98309], [60.17028, 24.97938],
			[60.17098, 24.97871], [60.17185, 24.97814], [60.17359, 24.97658], [60.17515, 24.97921]],
		"ships": [{"at": 0.47}]},
	# Föli Water Bus (Vesibussi): Martinsilta pier (OSM way 719629408) down
	# Aurajoki past Forum Marinum to Ruissalo Kansanpuisto. White hull with
	# Föli saffron-yellow band (#F5A800).
	{"id": "foli_water_bus", "kind": "route", "model": "water_bus",
		"name": "Föli Vesibussi Martinsilta–Ruissalo", "length_m": 20.0, "beam_m": 5.5,
		"lettering": "FÖLI", "hull": "#f2f1ec", "band": "#f5a800",
		"route": [[60.44391, 22.25502], [60.44315, 22.25285], [60.44140, 22.24850], [60.43920, 22.24350],
			[60.43680, 22.23700], [60.43450, 22.23150], [60.43220, 22.22800], [60.42950, 22.22250],
			[60.42720, 22.21650]],
		"ships": [{"at": 0.0, "berthed": true}, {"at": 0.55}]},
	# S/S Ukkopekka (1938 steamship): Aurajoki Martinsilta out through the
	# Aura mouth and Airisto channel toward Ruissalo and Naantali.
	{"id": "ss_ukkopekka", "kind": "route", "model": "suomenlinna",
		"name": "S/S Ukkopekka Turku–Naantali", "length_m": 31.2, "beam_m": 6.4,
		"lettering": "S/S UKKOPEKKA", "hull": "#f4f3ee", "band": "#1c2b46",
		"route": [[60.44350, 22.25400], [60.44080, 22.24760], [60.43750, 22.23920], [60.43420, 22.23120],
			[60.43160, 22.22650], [60.42750, 22.21400], [60.42400, 22.19500], [60.42500, 22.15500]],
		"ships": [{"at": 0.35}]},
]

## Cruise ferry liveries by terminal: a procedural ferry berthed within
## `radius_m` of `terminal` wears the nearest row's colours. Hull and
## superstructure white throughout; `band` paints the hull band
## (`band_style` "sweep" rises toward the bow, "waterline" runs along the
## boot top), `trim` a second, thinner stripe, `funnel` / `funnel_band`
## the funnel and its upper band, `mark` an emblem disc on the funnel
## (Silja's seal), `lettering` the line's name on the hull in `letters`.
## Colours are matched to the companies' published ship photographs.
const CRUISE_LIVERIES := [
	{"id": "silja", "line": "Silja Line", "terminal": [60.1606, 24.9588], "terminal_name": "Olympiaterminaali",
		"radius_m": 700.0, "hull": "#f4f3ee", "band": "#16295a", "band_style": "waterline",
		"trim": "#3d8fd1", "funnel": "#f4f3ee", "funnel_band": "#16295a", "mark": "#16295a",
		"lettering": "SILJA LINE", "letters": "#16295a"},
	{"id": "viking", "line": "Viking Line", "terminal": [60.1639, 24.9684], "terminal_name": "Katajanokan terminaali",
		"radius_m": 700.0, "hull": "#f4f3ee", "band": "#c8102e", "band_style": "waterline",
		"trim": "", "funnel": "#f4f3ee", "funnel_band": "#c8102e", "mark": "",
		"lettering": "VIKING LINE", "letters": "#c8102e"},
	{"id": "tallink", "line": "Tallink", "terminal": [60.1496, 24.9143], "terminal_name": "Länsiterminaali 2",
		"radius_m": 700.0, "hull": "#f4f3ee", "band": "#1d3f8f", "band_style": "sweep",
		"trim": "#3aa66a", "funnel": "#f4f3ee", "funnel_band": "#1d3f8f", "mark": "#3aa66a",
		"lettering": "TALLINK", "letters": "#1d3f8f"},
	{"id": "eckero", "line": "Eckerö Line", "terminal": [60.1531, 24.9176], "terminal_name": "Länsiterminaali 1",
		"radius_m": 500.0, "hull": "#f4f3ee", "band": "#0f3c78", "band_style": "waterline",
		"trim": "#f2c200", "funnel": "#0f3c78", "funnel_band": "#f4f3ee", "mark": "",
		"lettering": "ECKERÖ LINE", "letters": "#0f3c78"},
	# Linnansatama, Port of Turku: Viking Line & Tallink Silja passenger ferry terminals.
	{"id": "turku_viking", "line": "Viking Line", "terminal": [60.4352, 22.2195],
		"terminal_name": "Viking Line terminaali",
		"radius_m": 600.0, "hull": "#f4f3ee", "band": "#c8102e", "band_style": "waterline",
		"trim": "", "funnel": "#f4f3ee", "funnel_band": "#c8102e", "mark": "",
		"lettering": "VIKING LINE", "letters": "#c8102e"},
	{"id": "turku_silja", "line": "Silja Line", "terminal": [60.4338, 22.2235],
		"terminal_name": "Tallink Silja terminaali",
		"radius_m": 600.0, "hull": "#f4f3ee", "band": "#16295a", "band_style": "waterline",
		"trim": "#3d8fd1", "funnel": "#f4f3ee", "funnel_band": "#16295a", "mark": "#16295a",
		"lettering": "SILJA LINE", "letters": "#16295a"},
]

## Moored fleets along a quay. `quay` runs along the shore (the ships lie
## on its water side, bows toward its last point), `ships` from the first
## point on; a ship with "raft": true lies outboard of the one before it.
## Finnish state icebreakers winter at Katajanokka's north quay
## (Katajanokanlaituri), across from Pohjoisranta, by the "Icebreakers"
## viewpoint board (OSM node 6668120685). Dimensions: Urho class
## 104.6 x 23.8 m, Otso class 98.6 x 24.2 m, Voima 83.5 x 19.4 m.
const MOORED_FLEETS := [
	{"id": "helsinki_icebreakers", "kind": "icebreaker",
		"quay": [[60.16928, 24.96820], [60.16930, 24.97770]],
		"ships": [
			{"name": "URHO", "class": "urho", "length_m": 104.6, "beam_m": 23.8, "at": 0.12},
			{"name": "SISU", "class": "urho", "length_m": 104.6, "beam_m": 23.8, "at": 0.12, "raft": true},
			{"name": "OTSO", "class": "otso", "length_m": 98.6, "beam_m": 24.2, "at": 0.42},
			{"name": "KONTIO", "class": "otso", "length_m": 98.6, "beam_m": 24.2, "at": 0.42, "raft": true},
			{"name": "VOIMA", "class": "voima", "length_m": 83.5, "beam_m": 19.4, "at": 0.71}]},
]

## Market boats: wooden fishing boats moored alongside the market quay,
## selling fish and produce under canvas awnings. The Cholera Basin
## (Kolera-allas) north and east edges at Kauppatori, from the OSM
## coastline way 499729181. Boats lie on the quay's water side.
const MARKET_BOATS := [
	{"id": "kauppatori", "quay": [[60.16744, 24.95345], [60.16745, 24.95400], [60.16722, 24.95403],
			[60.16704, 24.95436]],
		"count": 7, "length_m": [7.5, 11.5]},
]

## Small-boat fleet profiles for MarinaBuilder by ISO country: hull
## colours (repeats weight them), the sailboat share, and the share of
## motor boats that are big flybridge yachts. Countries without a row
## keep MarinaBuilder's own defaults. Finland: varnished wooden launches
## and day boats, many cruising sailboats, few large white motor yachts.
const FLEET_PROFILES := {
	"FI": {"hulls": ["#e2e2dd", "#e2e2dd", "#e2e2dd", "#e2e2dd", "#7a4a26", "#6a3d1f", "#8b5a2b",
			"#1c2b46", "#2f4a3a", "#d8d2bd", "#9b2a22"],
		"sail_share": 0.5, "yacht_share": 0.25},
}

## The row for `id` in `rows`, or {}.
static func row(rows: Array, id: String) -> Dictionary:
	for r in rows:
		if str((r as Dictionary).get("id", "")) == id:
			return r
	return {}

## `points` ([lat, lon] pairs) in world xz around `lat`, `lon`.
static func to_world(points: Array, lat: float, lon: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(WorldScale.xz_from_latlon(float(p[0]), float(p[1]), lat, lon))
	return out
