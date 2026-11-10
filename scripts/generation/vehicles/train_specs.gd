class_name TrainSpecs
extends RefCounted

## Passenger trains as data, in TramSpecs' vocabulary (TramModel builds
## them, StationTrains stands them at a station): electric multiple
## units of two to four cars, each car on its own two bogies, a cab at
## both ends of the train and a gangway between cars. Generic shapes and
## colour blocks only: no operator's lettering, logo or exact product.
##
## On top of a tram section a train's may carry "under" (underfloor
## equipment cases, [centre x, length]) and its kind a "gangway" (width
## and height of the bellows between cars, m). A livery may add "door"
## (door leaves are painted, with a window, not glazed full height) and
## "cab" (the colour of a cab end, a warning yellow in Britain).
## A section id ending in "p" is the same car with a pantograph.

const KINDS: Array[String] = ["emu", "emu_uk", "intercity"]
const MIN_CARS := 2
const MAX_CARS := 4

const WHITE := Color(0.9, 0.9, 0.88)
const ROOF := Color(0.36, 0.37, 0.38)
const YELLOW := Color(0.93, 0.74, 0.04)

## Livery colours by role (TramSpecs.LIVERIES) and the gauge the fleet
## runs on (Finland's is 1524 mm).
const LIVERIES := {
	# White commuter unit, violet doors and waist band.
	"helsinki_commuter": {"lower": WHITE, "band": Color(0.42, 0.16, 0.56), "upper": WHITE,
		"door": Color(0.42, 0.16, 0.56), "pillar": TramSpecs.DARK, "roof": ROOF, "inner": WHITE, "gauge": 1.524},
	# White long-distance unit with a green band.
	"finland_long": {"lower": WHITE, "band": Color(0.0, 0.48, 0.2), "upper": WHITE,
		"door": Color(0.0, 0.48, 0.2), "pillar": TramSpecs.DARK, "roof": ROOF, "inner": WHITE, "gauge": 1.524},
	# Blue with a red-orange band.
	"london_blue": {"lower": Color(0.05, 0.16, 0.42), "band": Color(0.86, 0.22, 0.06), "upper": Color(0.05, 0.16, 0.42),
		"door": Color(0.86, 0.22, 0.06), "cab": YELLOW, "pillar": TramSpecs.DARK, "roof": ROOF, "inner": WHITE,
		"gauge": 1.435},
	# Dark blue-grey, pale doors, yellow cab ends.
	"london_grey": {"lower": Color(0.18, 0.23, 0.31), "band": Color(0.18, 0.23, 0.31), "upper": Color(0.18, 0.23, 0.31),
		"door": Color(0.66, 0.69, 0.72), "cab": YELLOW, "pillar": TramSpecs.DARK, "roof": ROOF, "inner": WHITE,
		"gauge": 1.435},
	# White over a blue skirt, blue doors.
	"london_white": {"lower": Color(0.07, 0.2, 0.5), "band": WHITE, "upper": WHITE,
		"door": Color(0.07, 0.2, 0.5), "cab": YELLOW, "pillar": TramSpecs.DARK, "roof": ROOF, "inner": WHITE,
		"gauge": 1.435},
}
const LONDON_LIVERIES: Array[String] = ["london_blue", "london_grey", "london_white"]
## Share of Helsinki's trains that are the long-distance unit.
const HELSINKI_LONG := 0.3

const PROF_EMU := [[0.95, 0.0, "under"], [0.95, 0.9, "skirt"], [1.08, 0.97, "lower"], [1.32, 1.0, "lamp"],
	[1.5, 1.0, "lower"], [1.72, 1.0, "band"], [1.95, 1.0, "win"], [2.95, 0.985, "upper"],
	[3.4, 0.94, "roof"], [3.74, 0.8, "roof"], [3.9, 0.45, "roof"], [3.95, 0.0, ""]]
const PROF_LONG := [[0.95, 0.0, "under"], [0.95, 0.9, "skirt"], [1.08, 0.97, "lower"], [1.32, 1.0, "lamp"],
	[1.5, 1.0, "lower"], [1.8, 1.0, "band"], [2.05, 1.0, "win"], [2.9, 0.985, "upper"],
	[3.5, 0.94, "roof"], [3.9, 0.8, "roof"], [4.08, 0.45, "roof"], [4.14, 0.0, ""]]

const NOSE_EMU := {"len": 1.5, "rake": 0.62, "pow": 2.6, "lamps": "pair", "board": true}
const NOSE_UK := {"len": 0.7, "rake": 0.2, "pow": 3.2, "lamps": "pair", "board": true}
const NOSE_LONG := {"len": 2.8, "rake": 1.15, "pow": 2.2, "lamps": "pair"}

const KIND := {
	# A modern commuter unit: raked cabs, strip glazing, two doorways a side.
	"emu": {"w": 2.9, "gap": 0.6, "wheel_r": 0.42, "gangway": Vector2(1.7, 2.3),
		"sections": {
			"cab": {"len": 20.6, "prof": PROF_EMU, "front": NOSE_EMU, "rear": {}, "doors": [-5.2, 3.6],
				"pitch": 1.5, "axle": 1.25, "bogies": [5.9, -7.3], "boxes": [[-2.0, 4.2], [4.2, 2.4]],
				"under": [[-0.7, 6.6]], "panto": -6.4},
			"mid": {"len": 19.0, "prof": PROF_EMU, "front": {}, "rear": {}, "doors": [-4.7, 4.7],
				"pitch": 1.5, "axle": 1.25, "bogies": [6.5, -6.5], "boxes": [[0.0, 4.6]],
				"under": [[-1.9, 3.4], [2.2, 2.6]], "panto": -5.6}}},
	# The older British unit: an upright, rounded cab; third rail, no pantograph.
	"emu_uk": {"w": 2.82, "gap": 0.6, "wheel_r": 0.42, "gangway": Vector2(1.6, 2.2),
		"sections": {
			"cab": {"len": 20.3, "prof": PROF_EMU, "front": NOSE_UK, "rear": {}, "doors": [-5.4, 4.0],
				"pitch": 1.35, "axle": 1.3, "bogies": [6.6, -7.2], "boxes": [[-1.0, 3.0]],
				"under": [[-0.4, 7.0]], "panto": -6.2},
			"mid": {"len": 19.8, "prof": PROF_EMU, "front": {}, "rear": {}, "doors": [-4.9, 4.9],
				"pitch": 1.35, "axle": 1.3, "bogies": [6.9, -6.9], "boxes": [[0.0, 3.0]],
				"under": [[-2.0, 3.6], [2.4, 2.8]], "panto": -5.8}}},
	# A long-distance unit: longer cars, a long nose, doors at the car ends.
	"intercity": {"w": 3.0, "gap": 0.6, "wheel_r": 0.44, "gangway": Vector2(1.7, 2.3),
		"sections": {
			"cab": {"len": 25.4, "prof": PROF_LONG, "front": NOSE_LONG, "rear": {}, "doors": [-10.9, 6.0],
				"pitch": 1.7, "axle": 1.35, "bogies": [6.6, -9.0], "boxes": [[-3.0, 5.0], [3.6, 3.0]],
				"under": [[-1.2, 9.0]], "panto": -8.2},
			"mid": {"len": 24.6, "prof": PROF_LONG, "front": {}, "rear": {}, "doors": [-10.6, 10.6],
				"pitch": 1.7, "axle": 1.35, "bogies": [8.7, -8.7], "boxes": [[0.0, 6.0]],
				"under": [[-2.6, 4.6], [3.0, 4.0]], "panto": -7.6}}},
}

## Whether passenger trains run on `rail`: mapped heavy rail.
static func carries(rail: Dictionary) -> bool:
	return str(rail.get("class", "")) == "rail"

## Whether `rail` is wired overhead: a train on it raises a pantograph.
## Third-rail track ("rail", London's southern lines) and unwired track
## carry none.
static func overhead(rail: Dictionary) -> bool:
	return str(rail.get("electrified", "")).strip_edges().to_lower() == "contact_line"

## The train that stands on `rail` in CityStyles region `region` of
## country `country` (ISO alpha-2): {"kind", "livery", "cars" (2..4),
## "panto"}, or {} when none does. `h` (0..1) mixes a city's fleet and
## its train lengths.
static func pick(region: String, country: String, rail: Dictionary, h: float) -> Dictionary:
	if not carries(rail):
		return {}
	var wired := overhead(rail)
	# A second, independent draw from the one hash: the train's length.
	var cars := 3 + int(fposmod(h * 7.0, 1.0) * 2.0)
	if region in ["helsinki", "espoo"]:
		if h < HELSINKI_LONG:
			return {"kind": "intercity", "livery": "finland_long", "cars": 4, "panto": wired}
		return {"kind": "emu", "livery": "helsinki_commuter", "cars": 4, "panto": wired}
	if region == "london":
		var i := mini(int(h * LONDON_LIVERIES.size()), LONDON_LIVERIES.size() - 1)
		return {"kind": "emu_uk", "livery": LONDON_LIVERIES[i], "cars": 4, "panto": false}
	if country.to_upper() == "FI":
		return {"kind": "intercity" if h < 0.5 else "emu", "livery": "finland_long", "cars": cars, "panto": wired}
	if country.to_upper() == "GB":
		return {"kind": "emu_uk", "livery": LONDON_LIVERIES[mini(int(h * LONDON_LIVERIES.size()), LONDON_LIVERIES.size() - 1)],
			"cars": cars, "panto": wired}
	# One band colour per country, not per train.
	var band := absi(hash(country.to_upper())) % TramSpecs.GENERIC_BANDS.size()
	return {"kind": "emu", "livery": "rail%d" % band, "cars": cars, "panto": wired}

## Colours and gauge of `livery` ("rail0" ..: the generic white unit
## with a palette band and doors).
static func livery(id: String) -> Dictionary:
	if id.begins_with("rail"):
		var band: Color = TramSpecs.GENERIC_BANDS[posmod(int(id.trim_prefix("rail")), TramSpecs.GENERIC_BANDS.size())]
		return {"lower": WHITE, "band": band, "upper": WHITE, "door": band, "pillar": TramSpecs.DARK, "roof": ROOF,
			"inner": WHITE, "gauge": 1.435}
	return LIVERIES[id]

static func has_livery(id: String) -> bool:
	return LIVERIES.has(id) or (id.begins_with("rail") and id.trim_prefix("rail").is_valid_int())

## Section `id` of `kind`: "cab" or "mid", bare or with the pantograph
## ("cabp", "midp").
static func section(kind: String, id: String) -> Dictionary:
	var sections: Dictionary = KIND[kind]["sections"]
	if sections.has(id):
		var bare: Dictionary = (sections[id] as Dictionary).duplicate()
		bare.erase("panto")
		return bare
	return sections[id.trim_suffix("p")]

## Buffer to buffer length of a `kind` train of `cars` cars (m).
static func length_m(kind: String, cars: int) -> float:
	var n := clampi(cars, MIN_CARS, MAX_CARS)
	return 2.0 * float(section(kind, "cab")["len"]) + float(n - 2) * float(section(kind, "mid")["len"]) \
		+ float(KIND[kind]["gap"]) * float(n - 1)

static func width_m(kind: String) -> float:
	return float(KIND[kind]["w"])

## The cars of a `kind` train, front first, as TramSpecs.train rows for
## TramRoute.place_train: a cab car at each end (the rear one turned),
## middle cars between. Each car stands on its own outer bogies. With
## `panto` the second car (a two-car train's first) carries the
## pantograph.
static func train(kind: String, cars: int, panto: bool) -> Array:
	var n := clampi(cars, MIN_CARS, MAX_CARS)
	var gap := float(KIND[kind]["gap"])
	var out: Array = []
	var x := length_m(kind, n) * 0.5
	var wired := 1 if n > 2 else 0
	for i in n:
		var base := "cab" if i == 0 or i == n - 1 else "mid"
		var id := base + ("p" if panto and i == wired else "")
		var flip := i == n - 1
		var sec := section(kind, id)
		var len := float(sec["len"])
		var bogies: Array = sec["bogies"]
		var sup := Vector2(minf(float(bogies[0]), float(bogies[1])), maxf(float(bogies[0]), float(bogies[1])))
		if flip:
			sup = Vector2(-sup.y, -sup.x)
		out.append({"id": id, "flip": flip, "tail": flip, "len": len, "at": x - len * 0.5, "sup": sup})
		x -= len + gap
	return out
