class_name ArchitectureCitiesEastAsia
extends RefCounted

## Tokyo and Seoul sub-style rows beyond their city rows (which stay in
## ArchitectureCitiesAsia) and both cities' era rows (BuildingEra). Each
## row inherits from its city row. Same key legend as ArchitectureData;
## `rv` replaces the parent's. AsiaFronts builds the `danji_number`,
## `sign_bands` and `sign_stack` relief.
##
## Tokyo: zakkyo (narrow 6–12 storey "mixed tenant" towers clad in signs:
## Center Gai, Kabukicho, Ginza, Akihabara), mansions (tiled 4–14 storey
## condominium blocks with deep balcony slabs), modern houses (ceramic
## siding, galvalume roofs) beside the kawara-roofed older ones, and
## mokuchin (two-storey wooden rental flats).
## Seoul: danji (apartment-complex slabs with the painted block number on
## their ends), shopping streets (sign boards on every lower floor),
## officetels (glass-and-stone mixed towers, Gangnam, Mapo).

const TOKYO_SIGNS := ["#d8262e", "#f2c230", "#1f5fb8", "#1f9e5a", "#f4f1e8", "#e2531f", "#7a2a8a"]
## Tiled mansion fronts: brown and beige ceramic, grey-white panels.
const MANSION_TILE := ["#a8927a", "#b8a48c", "#8e7a66", "#c8bca8", "#d8d2c6", "#9a9690", "#7a6a5c"]
## Ceramic siding and painted mortar on post-1975 houses.
const SIDING := ["#e6e4de", "#d4d0c8", "#bdb8ae", "#8e8a84", "#6a6862", "#d8ccb4", "#c8b8a0"]
## Galvalume (zinc-aluminium) roofs, dark grey to near black.
const GALVALUME := ["#4a4e54", "#5a5e62", "#3a3e44", "#6a5a4a"]
const KAWARA := ["#3a3e44", "#454a52", "#2f343a"]
## Danji slabs: cream and white with a pale tinted spandrel.
const DANJI := ["#efede6", "#e8e4da", "#ecebe6", "#e2e0d8", "#e6e2d6", "#dfe2e2"]
const SEOUL_SIGNS := ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a", "#f2f2f2"]
const SHOP_FRONTS := ["#d8d6d0", "#c8c4bc", "#b8b4ac", "#e4e0d8", "#a8a49c"]

## Largest footprint (m²) a zakkyo district building counts as one.
const ZAKKYO_MAX_M2 := 900.0

## One profile for every palace kind (rows "seoul_palace").
const PALACE_HALL := {"w": [["render", ["#efebe2", "#e8e2d6"]], ["wood", ["#8e2b20", "#7a2a1e"]]],
	"p": "punched", "wn": "small", "bay": 3.0, "fr": "#8e2b20", "sp": 0.0,
	"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.75, "rf": [["slate", ["#4a4e54", "#55595e", "#3f444a"]]],
	"fh": 4.5, "st": [1, 1], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.0, "g": [["stone", 1]],
	"ev": 1.4, "rv": {}}

const BASE := {
	"tokyo_zakkyo": "tokyo", "tokyo_mansion": "tokyo", "tokyo_house_modern": "tokyo_house",
	"tokyo_mokuchin": "tokyo",
	"seoul_danji": "seoul", "seoul_shopping": "seoul", "seoul_officetel": "seoul",
	"seoul_palace": "seoul_hanok",
}

const REGIONS := {
	# Narrow mixed-tenant towers: every floor a different bar, clinic or
	# karaoke box, each announcing itself on the vertical sign column and
	# the boards across the front; tiled or panel fronts, big screens.
	"tokyo_zakkyo": {
		"commercial": {"w": [["render", ["#d8d6d0", "#cfccc4", "#b8b4ac", "#e4e2dc", "#9aa3a9"]], ["concrete", ["#c8c4bc"]], ["glass", []]],
			"p": [["tiles", 3], ["strip", 3], ["panel", 1]], "wn": "wide", "bay": 2.4, "fr": "#6a6c6e",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.3, "st": [6, 12], "fix": true,
			"eq": 0.95, "g": [["signage", 3], ["shop", 1]], "gc": TOKYO_SIGNS, "ev": 0.0,
			"rv": {"signage": 0.95, "sign_stack": 0.8, "sign_bands": 0.35, "screens": 0.8,
				"awning": 0.1, "awning_colours": ["#2a4a6a", "#8a2a1a", "#e8e4da"]}},
		"apartments": {"w": [["render", ["#d8d6d0", "#cfccc4", "#b8b4ac", "#e4e2dc", "#9aa3a9"]], ["concrete", ["#c8c4bc"]]],
			"p": [["tiles", 3], ["strip", 2], ["punched", 1]], "wn": "wide", "bay": 2.4, "fr": "#6a6c6e",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2, "st": [5, 10], "fix": true,
			"eq": 0.95, "g": [["signage", 3], ["shop", 1]], "gc": TOKYO_SIGNS, "ev": 0.0,
			"rv": {"signage": 0.85, "sign_stack": 0.6, "sign_bands": 0.25, "screens": 0.5}},
	},
	# Condominium "mansions": tiled fronts, a deep balcony slab with a
	# frosted or solid parapet on every floor, a tiled entrance hall.
	"tokyo_mansion": {
		"apartments": {"w": [["render", MANSION_TILE], ["concrete", ["#d8d6d0", "#cfccc4"]]],
			"p": [["balcony", 4], ["tiles", 2]], "wn": "wide", "bay": 3.0, "fr": "#8a8c8e", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [5, 14], "fix": true,
			"ch": 0.0, "eq": 0.85, "g": [["none", 3], ["stone", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.85, "signage": 0.05}},
	},
	# Post-1975 houses: ceramic siding or painted mortar, flat, mono-pitch
	# or low gabled galvalume roofs, tight to the plot line.
	"tokyo_house_modern": {
		"house": {"w": [["render", SIDING]], "p": "punched", "wn": "wide", "bay": 2.2, "fr": "#6a6c6e",
			"sp": 0.0, "r": [["gabled", 2], ["skillion", 2], ["flat", 2], ["hipped", 1]], "pitch": 0.45,
			"rf": [["sheet_metal", GALVALUME], ["slate", KAWARA]], "fh": 2.8, "st": [2, 3], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.4, "g": [["none", 1]], "ev": 0.35, "rv": {"deep_balcony": 0.15}},
	},
	# Two-storey wooden rental flats (mokuzō chintai): mortar or siding,
	# a low tin or tile roof, an open corridor and balcony rails.
	"tokyo_mokuchin": {
		"apartments": {"w": [["render", ["#d8d0c0", "#c8c0b0", "#e0d8c8", "#b8b0a0"]], ["wood", ["#6b5a48", "#5a4a3a"]]],
			"p": [["balcony", 2], ["punched", 2]], "wn": "wide", "bay": 2.4, "fr": "#8a8c8e", "sp": 0.0,
			"r": [["gabled", 2], ["hipped", 1]], "pitch": 0.4,
			"rf": [["sheet_metal", GALVALUME], ["slate", KAWARA]], "fh": 2.7, "st": [2, 2], "fix": true,
			"ch": 0.0, "eq": 0.3, "g": [["none", 1]], "ev": 0.4, "rv": {"deep_balcony": 0.4}},
	},
	# Apartment-complex slabs: 15–30 storeys of cream concrete, glazed
	# balcony bands, the block number painted on each end, rows of them.
	"seoul_danji": {
		"apartments": {"w": [["concrete", DANJI], ["render", DANJI]],
			"p": [["balcony", 3], ["panel", 2]], "wn": "wide", "bay": 3.2, "fr": "#9a9c9e", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.8, "st": [15, 30], "fix": true,
			"ch": 0.0, "eq": 0.5, "g": [["none", 3], ["stone", 1]], "ev": 0.0,
			"rv": {"danji_number": 0.95, "glazed_balcony": 0.6}},
	},
	# Shopping streets (Myeongdong, Hongdae, Jongno, Gangnam station): a
	# board across the front under every lower storey's windows, vertical
	# signs at the corners, a lit ground floor.
	"seoul_shopping": {
		"commercial": {"w": [["concrete", SHOP_FRONTS], ["render", SHOP_FRONTS], ["glass", []]],
			"p": [["strip", 3], ["tiles", 2], ["punched", 1]], "wn": "wide", "bay": 3.0, "fr": "#6a6c6e",
			"r": [["flat", 1]], "rf": [["concrete", ArchitectureCitiesAsia.GREEN_ROOF], ["membrane", []]],
			"fh": 3.3, "st": [3, 8], "fix": true, "eq": 0.9, "g": [["signage", 3], ["shop", 1]],
			"gc": SEOUL_SIGNS, "ev": 0.0,
			"rv": {"sign_bands": 0.9, "signage": 0.7, "sign_stack": 0.25, "screens": 0.3}},
		"apartments": {"w": [["concrete", SHOP_FRONTS], ["brick", ArchitectureCitiesAsia.SEOUL_BRICK]],
			"p": [["strip", 2], ["punched", 2]], "wn": "wide", "bay": 3.0, "fr": "#6a6c6e",
			"r": [["flat", 1]], "rf": [["concrete", ArchitectureCitiesAsia.GREEN_ROOF]], "fh": 3.1,
			"st": [4, 8], "fix": true, "eq": 0.8, "g": [["signage", 3], ["shop", 1]], "gc": SEOUL_SIGNS,
			"ev": 0.0, "rv": {"sign_bands": 0.8, "signage": 0.5}},
	},
	# Palace halls, gates and roofed corridors (Gyeongbokgung, Changdeokgung,
	# Changgyeonggung, Deoksugung, Jongmyo): red-lacquered posts and white
	# infill on a granite base, deep eaves, grey giwa hipped roofs. Every
	# kind, because the long corridor wings come through as large "yes"
	# footprints that would otherwise read as apartment blocks.
	"seoul_palace": {
		"house": PALACE_HALL, "apartments": PALACE_HALL, "commercial": PALACE_HALL,
		"civic": PALACE_HALL, "religious": PALACE_HALL,
	},
	# Officetels and mixed towers: glass with stone or metal bands.
	"seoul_officetel": {
		"apartments": {"w": [["glass", []], ["stone", ["#c8c4bc", "#b8b0a4"]], ["concrete", DANJI]],
			"p": [["curtain", 2], ["strip", 2]], "wn": "wide", "bay": 3.0, "fr": "#4a4e52",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [15, 30], "fix": true,
			"eq": 0.8, "g": [["shop", 1]], "ev": 0.0, "rv": {"signage": 0.15}},
		"commercial": {"w": [["glass", []], ["stone", ["#c8c4bc"]]], "p": [["curtain", 3], ["strip", 1]],
			"bay": 3.0, "fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8,
			"st": [15, 35], "fix": true, "eq": 0.9, "g": [["shop", 1]], "rv": {"sign_bands": 0.2}},
	},
}

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
## BuildingEra.MODERN's post-war modern `building:architecture` values.
const MODERN := ["modern", "modernism", "modernist", "brutalist", "brutalism",
	"contemporary", "international_style", "postmodern", "postmodernism",
	"high-tech", "high_tech", "functionalism", "functionalist",
	"deconstructivism", "neo-futurism", "metabolism", "skyscraper"]

## [era key, kinds, year from, year to, building:architecture values,
## weight, distance band from km, to km] (BuildingEra.CITY_ERAS format).
const ERAS := {
	"tokyo": [
		["tokyo", AC, 1950, 2100, [], 5.0, 0.0, 99.0],
		["tokyo_house", ["house"], 1000, 1974, ["minka", "machiya", "traditional",
			"sukiya"], 1.0, 0.0, 99.0],
		["tokyo_house_modern", ["house"], 1975, 2100, ["modern", "contemporary"], 1.4, 0.0, 99.0],
		["tokyo_mansion", APT, 1970, 2100, ["mansion", "condominium"], 2.5, 0.0, 99.0],
		["tokyo_mokuchin", APT, 1955, 1995, ["mokuchin", "apaato"], 0.8, 2.0, 99.0],
		["tokyo_zakkyo", AC, 1960, 2100, ["zakkyo"], 1.0, 0.0, 6.0],
		["tokyo_tower", ACC, 1990, 2100, ["high-tech", "metabolism", "skyscraper",
			"postmodern"], 0.6, 0.0, 99.0],
	],
	"seoul": [
		["seoul", APT, 1975, 2100, [], 3.0, 0.0, 99.0],
		["seoul_danji", APT, 1975, 2100, ["apartment_complex", "danji"], 4.0, 0.0, 99.0],
		["seoul_villa", HAC, 1970, 2005, ["villa", "dagagu", "dasedae", "multiplex"], 3.0, 0.0, 99.0],
		["seoul_hanok", ["house", "commercial"], 1300, 1960, ["hanok", "traditional", "joseon",
			"korean_traditional"], 0.25, 0.0, 99.0],
		["seoul_shopping", AC, 1970, 2100, ["commercial_street"], 1.0, 0.0, 99.0],
		["seoul_officetel", AC, 1995, 2100, ["officetel"], 0.6, 0.0, 99.0],
		["seoul_tower", ACC, 1985, 2100, MODERN, 1.0, 0.0, 99.0],
		["seoul_palace", ["house", "apartments", "commercial", "civic", "religious"], 1300, 1960,
			["palace", "joseon_palace"], 0.0, 0.0, 99.0],
	],
}

## Structural rules (BuildingEra._rules) for Tokyo; "" = undecided.
static func tokyo_rule(kind: String, c: Dictionary) -> String:
	var lv := int(c["lv"])
	var area := float(c["area"])
	var district := str(c["district"])
	var small := area > 0.0 and area <= 250.0
	if kind == "house":
		if bool(c["heritage"]):
			return "tokyo_house"
		if str(c["roof"]) in ["flat", "skillion"]:
			return "tokyo_house_modern"
		return ""
	if lv >= 15:
		return "tokyo_tower"
	# Zakkyo stand on narrow plots: a department store or mall block in the
	# same streets keeps the general mixed fabric.
	if district == "tokyo_zakkyo" and (lv >= 3 or lv <= 0):
		return "tokyo_zakkyo" if area <= ZAKKYO_MAX_M2 else "tokyo"
	if kind == "commercial" and small and lv >= 5:
		return "tokyo_zakkyo"
	if kind == "apartments":
		# Wooden rental flats belong to the residential ring (the era row's
		# 2 km band), not the commercial centre.
		if lv >= 1 and lv <= 2:
			return "tokyo" if float(c["dist"]) >= 0.0 and float(c["dist"]) < 2.0 else "tokyo_mokuchin"
		if district == "tokyo_mansion" and lv >= 4:
			return "tokyo_mansion"
		# An untyped mid-rise in the centre is an office or mixed block, not
		# a condominium: only a mapped residential tag makes it a mansion there.
		var central := float(c["dist"]) >= 0.0 and float(c["dist"]) < 1.5
		if lv >= 4 and not small and district == "" and (_residential(c) or not central):
			return "tokyo_mansion"
	if lv >= 1:
		return "tokyo"
	return ""

## Structural rules for Seoul; "" = undecided.
static func seoul_rule(kind: String, c: Dictionary) -> String:
	var lv := int(c["lv"])
	var district := str(c["district"])
	var old := bool(c["heritage"])
	# Inside a palace's walls a low building is a hall, gate or corridor,
	# as is a heritage-tagged one elsewhere, unless it is plainly not
	# (_palace_hall); a house in or by the walls is a hanok.
	if lv <= 2 and (district == "seoul_palace" or old) and _palace_hall(kind, c):
		return "seoul_palace"
	# Officetels say so in their name ("광화문시대 오피스텔").
	if str(c.get("name", "")).contains("오피스텔") and kind in ["apartments", "commercial"] and lv != 1:
		return "seoul_officetel"
	if kind == "apartments" and lv >= 10:
		# A block named "NNN동" is a complex's slab wherever it stands.
		if _dong(c) and lv < 40:
			return "seoul_danji" if lv >= 12 else "seoul"
		if district in ["seoul_tower", "seoul_officetel"]:
			return district
		if lv >= 40:
			return "seoul_tower"
		# Danji are mapped as apartments or named "NNN동"; an untyped tall
		# block near Jongno or Gangnam is an office tower.
		if district != "seoul_danji" and not _residential(c) \
				and float(c["dist"]) >= 0.0 and float(c["dist"]) < 2.5:
			return "seoul_tower"
		return "seoul_danji" if lv >= 12 else "seoul"
	if lv >= 20 or (kind != "apartments" and lv >= 10):
		return "seoul_officetel" if district == "seoul_officetel" else "seoul_tower"
	if kind == "house" and (old or (district in ["seoul_hanok", "seoul_palace"] and lv <= 1)):
		return "seoul_hanok"
	if district == "seoul_shopping" and kind in ["commercial", "apartments"] and lv <= 9:
		return "seoul_shopping"
	if district == "seoul_danji" and kind == "apartments" and (lv <= 0 or lv >= 8):
		return "seoul_danji"
	if lv >= 2 and lv <= 6:
		return "seoul_villa"
	return ""

## Words in a name that rule out a giwa palace hall: museum, gallery,
## church, cathedral, and 석조 (stone-built, Deoksugung's Seokjojeon).
const NOT_PALACE_NAMES := ["박물관", "미술관", "교회", "성당", "석조"]
## Architecture tags a palace hall may carry.
const PALACE_ARCH := ["", "hanok", "traditional", "joseon", "korean", "palace", "joseon_palace"]
## Largest footprint (m²) a palace hall has (Geunjeongjeon is ~1,000 m²).
const PALACE_MAX_M2 := 2500.0

## Whether a low Seoul building in a palace circle (or heritage-tagged)
## can be a palace hall: not a house (a hanok), a church, a flat-roofed
## or modern-architecture block, a large museum footprint, or a name
## that says it is one of those.
static func _palace_hall(kind: String, c: Dictionary) -> bool:
	# A shrine or temple (Jongmyo's halls) is giwa-roofed too; a church is not.
	if kind == "house" or str(c.get("tag", "")) in ["church", "cathedral", "chapel"]:
		return false
	if str(c.get("roof", "")) == "flat" or str(c.get("arch", "")) not in PALACE_ARCH:
		return false
	if float(c.get("area", 0.0)) > PALACE_MAX_M2:
		return false
	var name := str(c.get("name", ""))
	for word in NOT_PALACE_NAMES:
		if name.contains(word):
			return false
	return true

## The building's own OSM tag names it residential.
static func _residential(c: Dictionary) -> bool:
	return str(c.get("tag", "")) in ["apartments", "residential", "dormitory"]

## A Korean complex block name: "101동", "파크팰리스 103동".
static func _dong(c: Dictionary) -> bool:
	return AsiaFronts.dong_regex().search(str(c.get("name", ""))) != null
