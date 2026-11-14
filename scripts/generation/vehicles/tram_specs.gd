class_name TramSpecs
extends RefCounted

## Tram types and liveries as data (TramModel builds them, TramRoute
## places them). Generic shapes and colour blocks only: no operator's
## lettering, logo or exact product.
##
## A kind is a train of body sections, front first. A section is lofted
## along +X from one cross section:
## * "prof": points up the half section, [height m, share of the half
##   width, role of the strip above it]. Roles: under, skirt, lower, lamp
##   (lower paint, the lamp cluster on a nose), band, win, stand (standee
##   glass over a window), upper, cler (clerestory glass), roof.
## * "front" / "rear": a nose {"len": how far it bows out, "rake": how
##   far the screen leans back per metre of height, "pow": plan corner
##   sharpness, "lamps": pair | single | none, "board": a destination
##   panel over the screen, "post": corner posts, "mullion": a post down
##   the middle of the screen, "open": no screen} or
##   {} for the flat end a bellows joins.
## * the side between the ends is cut into bays: "plan" lists them as
##   [type, metres] rear to front (scaled to fit), else they are laid out
##   around "doors" at "pitch" per window. Types: P panel, W window,
##   D door leaf, F door frame, O open bay (no wall), S step (no wall
##   below the roof).
## * "bogies": bogie centres along the section; a section without one at
##   an end rests on its neighbour's, under the joint.

const KINDS: Array[String] = ["modern3", "modern5", "modern2", "lrv", "heritage", "cable", "pcc"]

const DARK := Color(0.04, 0.04, 0.045)
const WHITE := Color(0.92, 0.92, 0.9)
const ROOF_GREY := Color(0.33, 0.34, 0.35)
const WOOD := Color(0.42, 0.27, 0.15)

## Livery colours by role, the wheel gauge (m) the fleet runs on, and
## the equipment colour on the roof.
const LIVERIES := {
	"helsinki": {"lower": Color(0.0, 0.45, 0.27), "band": Color(0.0, 0.45, 0.27), "upper": Color(0.93, 0.9, 0.78),
		"pillar": DARK, "roof": ROOF_GREY, "inner": WOOD, "gauge": 1.0},
	"lisbon_modern": {"lower": Color(0.96, 0.75, 0.05), "band": WHITE, "upper": Color(0.96, 0.75, 0.05),
		"pillar": DARK, "roof": ROOF_GREY, "inner": WOOD, "gauge": 1.435},
	"lisbon": {"lower": Color(0.95, 0.74, 0.06), "band": Color(0.95, 0.74, 0.06), "upper": Color(0.94, 0.93, 0.88),
		"pillar": Color(0.94, 0.93, 0.88), "roof": Color(0.42, 0.42, 0.41), "inner": WOOD, "gauge": 0.9},
	"porto": {"lower": Color(0.9, 0.81, 0.58), "band": Color(0.36, 0.1, 0.08), "upper": Color(0.36, 0.1, 0.08),
		"pillar": Color(0.36, 0.1, 0.08), "roof": Color(0.38, 0.37, 0.35), "inner": WOOD, "gauge": 1.435},
	"sf_cable": {"lower": Color(0.3, 0.035, 0.05), "band": Color(0.08, 0.18, 0.46), "upper": Color(0.93, 0.87, 0.7),
		"pillar": Color(0.93, 0.87, 0.7), "roof": Color(0.6, 0.57, 0.48), "inner": WOOD, "gauge": 1.067},
	"sf_lrv": {"lower": Color(0.66, 0.68, 0.7), "band": Color(0.74, 0.07, 0.09), "upper": Color(0.66, 0.68, 0.7),
		"pillar": DARK, "roof": Color(0.28, 0.29, 0.3), "inner": WOOD, "gauge": 1.435},
	"pcc_green": {"lower": Color(0.08, 0.36, 0.24), "band": Color(0.93, 0.88, 0.72), "upper": Color(0.93, 0.88, 0.72),
		"pillar": Color(0.93, 0.88, 0.72), "roof": Color(0.62, 0.6, 0.5), "inner": WOOD, "gauge": 1.435},
	"pcc_red": {"lower": Color(0.68, 0.09, 0.09), "band": Color(0.93, 0.88, 0.72), "upper": Color(0.93, 0.88, 0.72),
		"pillar": Color(0.93, 0.88, 0.72), "roof": Color(0.45, 0.45, 0.44), "inner": WOOD, "gauge": 1.435},
	"pcc_blue": {"lower": Color(0.08, 0.22, 0.52), "band": Color(0.85, 0.64, 0.14), "upper": WHITE,
		"pillar": WHITE, "roof": Color(0.45, 0.45, 0.44), "inner": WOOD, "gauge": 1.435},
	"pcc_orange": {"lower": Color(0.9, 0.44, 0.07), "band": Color(0.3, 0.1, 0.07), "upper": Color(0.93, 0.88, 0.72),
		"pillar": Color(0.93, 0.88, 0.72), "roof": Color(0.45, 0.45, 0.44), "inner": WOOD, "gauge": 1.435},
}
const PCC_LIVERIES: Array[String] = ["pcc_green", "pcc_red", "pcc_blue", "pcc_orange"]
## Band colours of the generic white tram ("generic0" ..), one per city.
const GENERIC_BANDS := [Color(0.05, 0.3, 0.62), Color(0.74, 0.08, 0.1), Color(0.0, 0.5, 0.5),
	Color(0.92, 0.5, 0.05), Color(0.36, 0.14, 0.5), Color(0.1, 0.5, 0.2)]

const PROF_LOW := [[0.28, 0.0, "under"], [0.28, 0.88, "skirt"], [0.4, 0.97, "lower"], [0.52, 0.99, "lamp"],
	[0.68, 1.0, "lower"], [0.84, 1.0, "band"], [1.0, 1.0, "win"], [2.2, 0.975, "upper"],
	[2.7, 0.95, "roof"], [3.2, 0.86, "roof"], [3.3, 0.5, "roof"], [3.32, 0.0, ""]]
const PROF_HIGH := [[0.45, 0.0, "under"], [0.45, 0.9, "skirt"], [0.6, 0.98, "lower"], [0.8, 1.0, "lamp"],
	[0.98, 1.0, "lower"], [1.22, 1.0, "band"], [1.38, 1.0, "win"], [2.3, 0.975, "upper"],
	[2.85, 0.93, "roof"], [3.05, 0.84, "roof"], [3.14, 0.5, "roof"], [3.16, 0.0, ""]]
const PROF_LRV := [[0.5, 0.0, "under"], [0.5, 0.9, "skirt"], [0.66, 0.98, "lower"], [0.86, 1.0, "lamp"],
	[1.04, 1.0, "lower"], [1.3, 1.0, "band"], [1.46, 1.0, "win"], [2.42, 0.975, "upper"],
	[3.0, 0.93, "roof"], [3.25, 0.84, "roof"], [3.36, 0.5, "roof"], [3.38, 0.0, ""]]
const PROF_PCC := [[0.3, 0.0, "under"], [0.3, 0.86, "skirt"], [0.44, 0.95, "lower"], [0.75, 0.99, "lower"],
	[1.02, 1.0, "band"], [1.16, 1.0, "win"], [1.95, 0.985, "upper"], [2.04, 0.98, "stand"],
	[2.24, 0.965, "upper"], [2.42, 0.93, "roof"], [2.78, 0.72, "roof"], [2.96, 0.38, "roof"], [3.0, 0.0, ""]]
const PROF_HERITAGE := [[0.7, 0.0, "under"], [0.7, 0.9, "skirt"], [0.78, 0.95, "lower"], [1.2, 1.0, "lower"],
	[1.55, 1.0, "band"], [1.63, 1.0, "win"], [2.45, 1.0, "upper"], [2.7, 1.0, "roof"], [2.74, 1.05, "roof"],
	[2.95, 0.52, "cler"], [3.13, 0.5, "roof"], [3.22, 0.0, ""]]
const PROF_CABLE := [[0.75, 0.0, "under"], [0.75, 0.92, "skirt"], [0.82, 0.97, "lower"], [1.2, 1.0, "lower"],
	[1.45, 1.0, "band"], [1.53, 1.0, "win"], [2.35, 1.0, "upper"], [2.58, 1.0, "roof"], [2.62, 1.06, "roof"],
	[2.8, 0.56, "upper"], [2.94, 0.52, "roof"], [3.0, 0.0, ""]]

const NOSE_MODERN := {"len": 1.3, "rake": 0.5, "pow": 3.0, "lamps": "pair", "board": true}
const NOSE_OLDER := {"len": 0.55, "rake": 0.2, "pow": 4.0, "lamps": "pair", "board": true}
const NOSE_LRV := {"len": 0.8, "rake": 0.3, "pow": 3.5, "lamps": "pair", "board": true}
const NOSE_DASH := {"len": 0.4, "rake": 0.0, "pow": 3.0, "lamps": "single", "post": true, "mullion": true}

const KIND := {
	# Low-floor articulated cars: raked cabs, strip glazing, Jacobs bogies
	# under the bellows, a pantograph and equipment boxes on the roof.
	"modern3": {"w": 2.4, "gap": 0.5, "wheel_r": 0.3, "train": [["cab", false], ["mid", false], ["cab", true]],
		"sections": {
			"cab": {"len": 9.4, "prof": PROF_LOW, "front": NOSE_MODERN, "rear": {}, "doors": [-2.6, 1.5],
				"pitch": 1.5, "bogies": [2.3, -4.95], "boxes": [[-1.0, 3.6]]},
			"mid": {"len": 7.8, "prof": PROF_LOW, "front": {}, "rear": {}, "doors": [0.0],
				"pitch": 1.5, "bogies": [], "boxes": [[-2.4, 1.6]], "panto": 1.0}}},
	"modern5": {"w": 2.65, "gap": 0.5, "wheel_r": 0.3,
		"train": [["cab", false], ["susp", false], ["mid", false], ["susp", false], ["cab", true]],
		"sections": {
			"cab": {"len": 7.0, "prof": PROF_LOW, "front": NOSE_MODERN, "rear": {}, "doors": [-1.9],
				"pitch": 1.5, "bogies": [1.3, -3.75], "boxes": [[-0.9, 2.6]]},
			"susp": {"len": 5.2, "prof": PROF_LOW, "front": {}, "rear": {}, "doors": [0.0],
				"pitch": 1.4, "bogies": [], "boxes": [[0.0, 3.0]]},
			"mid": {"len": 6.4, "prof": PROF_LOW, "front": {}, "rear": {}, "doors": [],
				"pitch": 1.45, "bogies": [3.45, -3.45], "boxes": [[-1.9, 1.4]], "panto": 0.8}}},
	# The older two-section car: boxier, a higher floor, one Jacobs bogie.
	"modern2": {"w": 2.3, "gap": 0.4, "wheel_r": 0.33, "train": [["a", false], ["b", true]],
		"sections": {
			"a": {"len": 9.9, "prof": PROF_HIGH, "front": NOSE_OLDER, "rear": {}, "doors": [2.6, -2.9],
				"pitch": 1.25, "bogies": [2.9, -5.15], "boxes": [[-2.6, 1.8]], "panto": 0.6},
			"b": {"len": 9.9, "prof": PROF_HIGH, "front": NOSE_OLDER, "rear": {}, "doors": [2.6, -2.9],
				"pitch": 1.25, "bogies": [2.9], "boxes": [[-1.5, 2.2]]}}},
	# High-floor light rail vehicle.
	"lrv": {"w": 2.7, "gap": 0.4, "wheel_r": 0.36, "train": [["a", false], ["b", true]],
		"sections": {
			"a": {"len": 11.3, "prof": PROF_LRV, "front": NOSE_LRV, "rear": {}, "doors": [2.7, -3.2],
				"pitch": 1.45, "bogies": [3.4, -5.85], "boxes": [[-3.4, 2.4]], "panto": 0.0},
			"b": {"len": 11.3, "prof": PROF_LRV, "front": NOSE_LRV, "rear": {}, "doors": [2.7, -3.2],
				"pitch": 1.45, "bogies": [3.4], "boxes": [[-0.6, 3.4]]}}},
	# Two-axle car: one truck, a saloon between open end platforms behind
	# a dash and screen, a clerestory roof and a trolley pole.
	"heritage": {"w": 2.38, "gap": 0.0, "wheel_r": 0.4, "train": [["car", false]],
		"sections": {
			"car": {"len": 8.4, "prof": PROF_HERITAGE, "front": NOSE_DASH, "rear": NOSE_DASH,
				"plan": [["P", 0.12], ["S", 0.95], ["P", 0.14], ["W", 0.92], ["P", 0.1], ["W", 0.92], ["P", 0.1],
					["W", 0.92], ["P", 0.1], ["W", 0.92], ["P", 0.1], ["W", 0.92], ["P", 0.14], ["S", 0.95], ["P", 0.12]],
				"truck": [-1.0, 1.0], "pole": 0.6, "open": true}}},
	# Cable car: open bench section in front (posts, outward benches, a
	# running board), a closed cabin behind it, an open rear platform.
	"cable": {"w": 2.4, "gap": 0.0, "wheel_r": 0.28, "train": [["car", false]],
		"sections": {
			"car": {"len": 8.4, "prof": PROF_CABLE,
				"front": {"len": 0.3, "rake": 0.0, "pow": 3.0, "lamps": "single", "post": true, "mullion": true},
				"rear": {"len": 0.3, "rake": 0.0, "pow": 3.0, "lamps": "none", "post": true, "open": true},
				"plan": [["P", 0.1], ["S", 0.95], ["P", 0.14], ["W", 0.52], ["P", 0.09], ["W", 0.52], ["P", 0.09],
					["W", 0.52], ["P", 0.09], ["W", 0.52], ["P", 0.09], ["W", 0.52], ["P", 0.14],
					["O", 0.78], ["P", 0.07], ["O", 0.78], ["P", 0.07], ["O", 0.78], ["P", 0.07], ["O", 0.78], ["P", 0.1]],
				"bogies": [2.5, -2.5], "axle": 0.6, "open": true}}},
	# Streamlined streetcar: a bowed, raked front, a rounded tail, skirts
	# over the trucks, standee windows and a trolley pole.
	"pcc": {"w": 2.54, "gap": 0.0, "wheel_r": 0.33, "train": [["car", false]],
		"sections": {
			"car": {"len": 14.2, "prof": PROF_PCC,
				"front": {"len": 1.0, "rake": 0.42, "pow": 2.6, "lamps": "single", "mullion": true},
				"rear": {"len": 1.1, "rake": 0.3, "pow": 2.2, "lamps": "tail"},
				"doors": [4.6, -1.2], "pitch": 0.82, "bogies": [3.45, -3.45], "pole": 1.2}}},
}

## Whether trams run on `rail`: mapped tram track, and in San Francisco
## the light rail too (its street-running metro).
static func carries(region: String, rail: Dictionary) -> bool:
	var cls := str(rail.get("class", ""))
	return cls == "tram" or (cls == "light_rail" and region == "san_francisco")

## The tram that runs on `rail` in CityStyles region `region` of
## country `country` (ISO alpha-2): {"kind", "livery"}, or {} when none
## does. `h` (0..1) mixes a city's fleet.
static func pick(region: String, country: String, rail: Dictionary, h: float) -> Dictionary:
	if not carries(region, rail):
		return {}
	var gauge := float(rail.get("gauge_m", 1.435))
	match region:
		"san_francisco":
			if bool(rail.get("cable", false)):
				return {"kind": "cable", "livery": "sf_cable"}
			if str(rail.get("class", "")) == "tram" and bool(rail.get("embedded", false)) and gauge > 1.3:
				return {"kind": "pcc", "livery": PCC_LIVERIES[mini(int(h * PCC_LIVERIES.size()), PCC_LIVERIES.size() - 1)]}
			return {"kind": "lrv", "livery": "sf_lrv"}
		"helsinki":
			return {"kind": "modern2" if h < 0.3 else "modern3", "livery": "helsinki"}
		"lisbon":
			if gauge <= 0.95:
				return {"kind": "heritage", "livery": "lisbon"}
			return {"kind": "modern3", "livery": "lisbon_modern"}
	if country.to_upper() == "PT":
		return {"kind": "heritage", "livery": "porto"}
	# One band colour per city, not per tram.
	var city := absi(hash(country.to_upper() + "|" + region)) % GENERIC_BANDS.size()
	return {"kind": "modern5", "livery": "generic%d" % city}

## Colours and gauge of `livery`.
static func livery(id: String) -> Dictionary:
	if id.begins_with("generic"):
		return {"lower": WHITE, "band": GENERIC_BANDS[posmod(int(id.trim_prefix("generic")), GENERIC_BANDS.size())],
			"upper": WHITE, "pillar": DARK, "roof": ROOF_GREY, "inner": WOOD, "gauge": 1.435}
	return LIVERIES[id]

static func section(kind: String, id: String) -> Dictionary:
	return KIND[kind]["sections"][id]

## Buffer to buffer length of a `kind` train (m).
static func length_m(kind: String) -> float:
	var k: Dictionary = KIND[kind]
	var train: Array = k["train"]
	var total := float(k["gap"]) * float(train.size() - 1)
	for t: Array in train:
		total += float(section(kind, str(t[0]))["len"])
	return total

static func width_m(kind: String) -> float:
	return float(KIND[kind]["w"])

## The sections of a `kind` train, front first, for TramRoute.place_train:
## {"id", "flip" (turned end for end), "tail" (red lamps), "len",
## "at" (metres from the train's middle to the section's origin),
## "sup" (rear and front support along the section's +X as placed)}.
static func train(kind: String) -> Array:
	var k: Dictionary = KIND[kind]
	var rows: Array = k["train"]
	var gap := float(k["gap"])
	var out: Array = []
	var x := length_m(kind) * 0.5
	for i in rows.size():
		var id := str(rows[i][0])
		var flip := bool(rows[i][1])
		var sec := section(kind, id)
		var len := float(sec["len"])
		var sup := _supports(sec, gap)
		if flip:
			sup = Vector2(-sup.y, -sup.x)
		out.append({"id": id, "flip": flip, "tail": flip and i == rows.size() - 1, "len": len,
			"at": x - len * 0.5, "sup": sup})
		x -= len + gap
	return out

## Rear and front support of a section as built (+X its front): the
## outermost bogie toward a nose, the middle of the joint at a flat end.
static func _supports(sec: Dictionary, gap: float) -> Vector2:
	var half := float(sec["len"]) * 0.5
	if sec.has("truck"):
		var truck: Array = sec["truck"]
		return Vector2(float(truck[0]), float(truck[1]))
	var rear := -half - gap * 0.5
	var front := half + gap * 0.5
	for b: float in sec.get("bogies", []):
		if not (sec["front"] as Dictionary).is_empty():
			front = b if front > half else maxf(front, b)
		if not (sec["rear"] as Dictionary).is_empty():
			rear = b if rear < -half else minf(rear, b)
	return Vector2(rear, front)
