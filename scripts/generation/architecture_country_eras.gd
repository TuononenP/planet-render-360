class_name ArchitectureCountryEras
extends RefCounted

## Period rows for places outside every city zone, so a town is not one
## period repeated: an old core, the country row itself as the main fabric,
## post-war slabs and contemporary mid-rise. Apartments and commercial only;
## houses, religious, farm and industrial buildings keep the country row. Rows
## inherit from their country region (BASE). BuildingEra._country picks one.

## Size (m) of the patch an untagged building's period follows: no city core
## exists out here to give a distance cue, so neighbourhoods carry the pattern.
const CELL_M := 160.0

const AC := ["apartments", "commercial"]
const OLD_TAGS := ["baroque", "classicism", "classical", "neoclassicism", "neoclassical", "gothic",
	"gothic_revival", "renaissance", "medieval", "vernacular", "colonial", "historicism",
	"art_nouveau", "jugendstil", "victorian", "edwardian", "georgian", "federation"]
const POSTWAR_TAGS := ["brutalist", "brutalism", "modernism", "modernist", "international_style",
	"functionalism", "functionalist", "socialist_modernism"]
const NEW_TAGS := ["contemporary", "postmodern", "postmodernism", "high-tech", "high_tech",
	"deconstructivism", "neo-futurism", "skyscraper"]

const SHOPS := [["shop", 2], ["none", 1]]
const CE_OLD := {"w": [["render", ["#e6d3a8", "#d9c08c", "#cfd8c8", "#e0c8b0", "#efe2c4"]]],
	"p": [["ornate", 3], ["punched", 1]], "wn": ["casement", "french"], "bay": 2.6, "fr": "#f1ede4", "sp": 0.0,
	"r": [["hipped", 3], ["mansard", 1], ["gabled", 1]], "pitch": 0.9, "fh": 3.4, "st": [3, 5], "ch": 0.7, "dm": 0.4,
	"rf": [["terracotta", ArchitectureData.TERRA], ["slate", ArchitectureData.SLATE]], "g": SHOPS,
	"rv": {"string_course": true, "quoins": true, "oriel": 0.1}}
const WE_OLD := {"w": [["brick", ["#7b4a3a", "#8a3f30", "#6e3f30", "#9c4a35"]]],
	"p": [["punched", 3], ["ornate", 1]], "wn": "sash", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
	"r": [["gabled", 3], ["hipped", 1]], "pitch": 1.0, "fh": 3.2, "st": [2, 4], "ch": 0.9, "dm": 0.2,
	"rf": [["slate", ArchitectureData.SLATE]], "g": SHOPS, "rv": {"string_course": true, "oriel": 0.2}}
const NORDIC_OLD := {"w": [["render", ["#d9b765", "#e3c98a", "#c9d4b4", "#b8664a", "#efe2b0"]]],
	"p": "punched", "wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
	"r": [["hipped", 3], ["gabled", 2]], "pitch": 0.8, "fh": 3.2, "st": [2, 4], "ch": 0.6, "dm": 0.2,
	"rf": [["sheet_metal", ["#4b5560", "#7a2f2a", "#5d6670"]], ["terracotta", ["#9a4a2c"]]], "g": SHOPS,
	"rv": {"string_course": true}}
const MED_OLD := {"w": [["render", ["#e6c9a0", "#d9a878", "#efe3c8", "#c9a070"]], ["stone", []]],
	"p": "punched", "wn": "french", "bay": 2.4, "fr": "#efe6d2", "sh": "#4f6a4a", "sp": 0.7, "rl": 0.5,
	"r": [["hipped", 3], ["gabled", 2]], "pitch": 0.5, "fh": 3.2, "st": [3, 5], "ch": 0.2,
	"rf": [["terracotta", ArchitectureData.TERRA]], "g": SHOPS, "rv": {"balconette": 0.5, "string_course": true}}
const FR_OLD := {"w": [["limestone", []], ["render", ["#e8dcc0", "#e0d0b0"]]],
	"p": [["punched", 2], ["ornate", 1]], "wn": "french", "bay": 2.5, "fr": "#e8e4d8", "sh": "#5a6a72", "sp": 0.5, "rl": 0.4,
	"r": [["mansard", 2], ["hipped", 2]], "pitch": 0.9, "fh": 3.2, "st": [3, 5], "ch": 0.6, "dm": 0.5,
	"rf": [["slate", ArchitectureData.SLATE]], "g": SHOPS, "rv": {"balconette": 0.4, "string_course": true}}
const EE_OLD := {"w": [["render", ["#e8d890", "#d8c07a", "#c8d4c0", "#e0c8b0", "#e8e4dc"]]],
	"p": [["ornate", 2], ["punched", 2]], "wn": "casement", "bay": 2.6, "fr": "#efece4", "sp": 0.0,
	"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.7, "fh": 3.4, "st": [3, 5], "ch": 0.6, "dm": 0.2,
	"rf": [["slate", ["#6b6e72", "#7c4a38", "#5a626b"]]], "g": SHOPS, "rv": {"string_course": true, "quoins": true}}
const NA_OLD := {"w": [["brick", ["#9c4a35", "#8a3f30", "#7b4a3a", "#a05a3a"]]],
	"p": [["punched", 3], ["brownstone", 1]], "wn": "sash", "bay": 2.6, "fr": "#f1ede4", "sp": 0.0,
	"r": [["flat", 1]], "fh": 3.4, "st": [2, 5], "ch": 0.3, "eq": 0.2, "rf": [["membrane", []]], "g": SHOPS,
	"rv": {"string_course": true, "fire_escape": 0.2, "awning": 0.3, "awning_colours": ["#1f3b2c", "#7a1f24", "#1a3a6a"]}}
const LA_OLD := {"w": [["render", ["#e8c070", "#e08a68", "#a8c8b0", "#e8a8a0", "#f0e0b0"]]],
	"p": "punched", "wn": "french", "bay": 2.6, "fr": "#3a3d42", "sh": "#3f5f6f", "sp": 0.2, "rl": 0.6,
	"r": [["flat", 2], ["gabled", 1]], "pitch": 0.5, "fh": 3.6, "st": [1, 3], "ch": 0.0, "eq": 0.2,
	"rf": [["terracotta", ArchitectureData.TERRA], ["concrete", []]], "g": SHOPS, "rv": {"balconette": 0.5}}
const ME_OLD := {"w": [["render", ["#d8c6a0", "#cdb88e", "#c9b090"]], ["stone", []]],
	"p": "adobe", "wn": "small", "bay": 3.0, "fr": "#5a4a3a", "sp": 0.0,
	"r": [["flat", 1]], "fh": 3.0, "st": [2, 4], "ch": 0.0, "eq": 0.5, "rf": [["concrete", ["#c8b898", "#b8aa90"]]],
	"g": SHOPS, "rv": {"awning": 0.25, "awning_colours": ["#5a4a3a", "#2a3a4a", "#8a6a3a"]}}
const SA_OLD := {"w": [["render", ["#e0a878", "#e8d098", "#c8b8a0", "#e8dcc4"]], ["stone", []]],
	"p": "punched", "wn": "french", "bay": 2.8, "fr": "#3a3d42", "sh": "#3f5f4a", "sp": 0.4, "rl": 0.5,
	"r": [["flat", 1]], "fh": 3.4, "st": [2, 4], "ch": 0.0, "eq": 0.5, "rf": [["concrete", []]], "g": SHOPS,
	"rv": {"balconette": 0.3, "awning": 0.3, "awning_colours": ["#8a2a1a", "#1a4a6a", "#c8901a"]}}
const SEA_OLD := {"w": [["render", ["#e8d8b0", "#c8d8c0", "#e8c0b0", "#b8c8d8"]]],
	"p": "shophouse", "wn": "french", "bay": 2.8, "fr": "#efece4", "sh": "#4f6a5a", "sp": 0.6,
	"r": [["hipped", 2], ["gabled", 1]], "pitch": 0.7, "fh": 3.4, "st": [2, 3], "ch": 0.0, "eq": 0.3, "ev": 0.7,
	"rf": [["terracotta", ["#b5542f", "#9a4a2c"]]], "g": [["shop", 1]],
	"rv": {"awning": 0.3, "signage": 0.3, "awning_colours": ["#2a4a6a", "#8a2a1a", "#c8901a"]}}
const AFRICA_OLD := {"w": [["render", ["#e0d0b8", "#d8c8a8", "#e8dcc4", "#c8d0c0"]]],
	"p": "punched", "wn": "casement", "bay": 3.0, "fr": "#efece4", "sh": "#3f5f4a", "sp": 0.3,
	"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.45, "fh": 3.2, "st": [2, 3], "ch": 0.0, "eq": 0.2, "ev": 0.7,
	"rf": [["slate", ["#8d8a86", "#7c4a38"]]], "g": SHOPS,
	"rv": {"awning": 0.3, "awning_colours": ["#c8301a", "#1a5a9a", "#e8b820"]}}
const EA_OLD := {"w": [["brick", ["#9c4a35", "#7b5a4a", "#8a6a58"]], ["concrete", ["#c8c0b0", "#b8b0a0"]]],
	"p": "punched", "wn": "wide", "bay": 2.8, "fr": "#6a6e72", "sp": 0.0,
	"r": [["flat", 2], ["gabled", 1]], "pitch": 0.6, "fh": 2.8, "st": [3, 6], "ch": 0.0, "eq": 0.5,
	"rf": [["membrane", []], ["terracotta", ["#7c4a38"]]], "g": [["shop", 1], ["none", 1]], "rv": {"signage": 0.3}}
const JP_OLD := {"w": [["wood", ["#6b5a48", "#8a7a64", "#5a4a3a"]], ["render", ["#d8d0c0", "#c8c0b0"]]],
	"p": "punched", "wn": "small", "bay": 2.4, "fr": "#6a5a48", "sp": 0.0,
	"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.6, "fh": 2.7, "st": [2, 3], "ch": 0.0, "eq": 0.3, "ev": 0.8,
	"rf": [["slate", ["#4d555c", "#5a6068"]]], "g": [["shop", 1], ["none", 1]], "rv": {"signage": 0.2}}
const AU_OLD := {"w": [["brick", ["#a05a3a", "#8a4a35", "#b0805a"]]],
	"p": "punched", "wn": "sash", "bay": 2.7, "fr": "#f4f1ea", "sp": 0.0,
	"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.7, "fh": 3.3, "st": [2, 4], "ch": 0.5, "ev": 0.5,
	"rf": [["terracotta", ["#b5542f", "#9a4a2c"]], ["slate", ["#6e7a73", "#5a626b"]]], "g": SHOPS,
	"rv": {"string_course": true, "awning": 0.3, "awning_colours": ["#1f3b2c", "#7a1f24", "#2a2f4a"]}}

## Slabs and walk-ups, 1950-89: pale concrete or render, or brick where the
## country built in it; flat roofs, ribbons and balconies.
const POSTWAR := {"w": [["concrete", ArchitectureData.CONCRETE], ["render", ["#d8d4c8", "#c8c8c0", "#e0dcc8"]]],
	"p": [["balcony", 3], ["strip", 2], ["panel", 1]], "wn": "wide", "bay": 3.0, "fr": "#7a7e82", "sp": 0.0, "rl": 0.0,
	"r": [["flat", 1]], "fh": 2.8, "st": [4, 9], "ch": 0.0, "dm": 0.0, "eq": 0.4,
	"rf": [["membrane", []]], "g": [["none", 2], ["shop", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.4}}
const POSTWAR_BRICK := {"w": [["brick", ["#8a6a58", "#7a5a48", "#9a7a60"]], ["concrete", ArchitectureData.CONCRETE]],
	"p": [["strip", 2], ["balcony", 2], ["punched", 1]], "wn": "wide", "bay": 3.0, "fr": "#7a7e82", "sp": 0.0, "rl": 0.0,
	"r": [["flat", 1]], "fh": 2.8, "st": [3, 8], "ch": 0.0, "dm": 0.0, "eq": 0.4,
	"rf": [["membrane", []]], "g": [["none", 2], ["shop", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.3}}
## Nordic apartment slabs stay mostly punched: ribbons here read as stripes.
const NORDIC_POSTWAR := {"w": [["brick", ["#8a6a58", "#7a5a48", "#9a7a60"]], ["concrete", ArchitectureData.CONCRETE]],
	"p": [["punched", 3], ["balcony", 2], ["strip", 1]], "wn": "wide", "bay": 3.0, "fr": "#7a7e82", "sp": 0.0, "rl": 0.0,
	"r": [["flat", 1]], "fh": 2.8, "st": [3, 8], "ch": 0.0, "dm": 0.0, "eq": 0.4,
	"rf": [["membrane", []]], "g": [["none", 2], ["shop", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.3}}

## Contemporary, 1990 on. Apartments keep a masonry or rendered face; offices
## go to glass. Warm climates keep deeper balconies and paler walls.
const NEW_APT := {"w": [["render", ["#e8e4dc", "#c8c8c4", "#8a8c8e"]], ["brick", ["#6a5a50", "#8a7a6a"]], ["glass", []]],
	"p": [["balcony", 2], ["strip", 2], ["punched", 1]], "wn": "wide", "bay": 3.0, "fr": "#44484c", "sp": 0.0, "rl": 0.0,
	"r": [["flat", 1]], "fh": 3.0, "st": [5, 10], "ch": 0.0, "dm": 0.0, "eq": 0.5,
	"rf": [["membrane", []]], "g": [["none", 1], ["shop", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.4}}
const NEW_WARM_APT := {"w": [["render", ["#f0ece0", "#e8dcc4", "#d8d0c0"]], ["concrete", ArchitectureData.CONCRETE], ["glass", []]],
	"p": [["balcony", 3], ["strip", 1]], "wn": "wide", "bay": 3.2, "fr": "#44484c", "sp": 0.0, "rl": 0.0,
	"r": [["flat", 1]], "fh": 3.0, "st": [6, 14], "ch": 0.0, "dm": 0.0, "eq": 0.7,
	"rf": [["concrete", []], ["membrane", []]], "g": [["none", 1], ["shop", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.6}}
const NEW_COM := {"w": [["glass", []], ["concrete", ArchitectureData.CONCRETE]],
	"p": "curtain", "bay": 3.2, "fr": "#44484c", "sp": 0.0, "r": [["flat", 1]], "fh": 3.8, "st": [4, 14],
	"ch": 0.0, "dm": 0.0, "eq": 0.8, "rf": [["membrane", []]], "g": [["shop", 1]], "ev": 0.0, "rv": {}}

const REGIONS := {
	"central_europe_old": {"apartments": CE_OLD, "commercial": CE_OLD},
	"central_europe_postwar": {"apartments": POSTWAR, "commercial": POSTWAR},
	"central_europe_new": {"apartments": NEW_APT, "commercial": NEW_COM},
	"west_europe_brick_old": {"apartments": WE_OLD, "commercial": WE_OLD},
	"west_europe_brick_postwar": {"apartments": POSTWAR_BRICK, "commercial": POSTWAR_BRICK},
	"west_europe_brick_new": {"apartments": NEW_APT, "commercial": NEW_COM},
	"nordic_old": {"apartments": NORDIC_OLD, "commercial": NORDIC_OLD},
	"nordic_postwar": {"apartments": NORDIC_POSTWAR, "commercial": POSTWAR_BRICK},
	"nordic_new": {"apartments": NEW_APT, "commercial": NEW_COM},
	"mediterranean_old": {"apartments": MED_OLD, "commercial": MED_OLD},
	"mediterranean_postwar": {"apartments": POSTWAR, "commercial": POSTWAR},
	"mediterranean_new": {"apartments": NEW_WARM_APT, "commercial": NEW_COM},
	"france_old": {"apartments": FR_OLD, "commercial": FR_OLD},
	"france_postwar": {"apartments": POSTWAR, "commercial": POSTWAR},
	"france_new": {"apartments": NEW_APT, "commercial": NEW_COM},
	"north_america_old": {"apartments": NA_OLD, "commercial": NA_OLD},
	"north_america_postwar": {"apartments": POSTWAR_BRICK, "commercial": POSTWAR_BRICK},
	"north_america_new": {"apartments": NEW_APT, "commercial": NEW_COM},
	"eastern_europe_old": {"apartments": EE_OLD, "commercial": EE_OLD},
	"eastern_europe_new": {"apartments": NEW_APT, "commercial": NEW_COM},
	"latin_america_old": {"apartments": LA_OLD, "commercial": LA_OLD},
	"latin_america_new": {"apartments": NEW_WARM_APT, "commercial": NEW_COM},
	"middle_east_old": {"apartments": ME_OLD, "commercial": ME_OLD},
	"middle_east_new": {"apartments": NEW_WARM_APT, "commercial": NEW_COM},
	"south_asia_old": {"apartments": SA_OLD, "commercial": SA_OLD},
	"south_asia_new": {"apartments": NEW_WARM_APT, "commercial": NEW_COM},
	"southeast_asia_old": {"apartments": SEA_OLD, "commercial": SEA_OLD},
	"southeast_asia_new": {"apartments": NEW_WARM_APT, "commercial": NEW_COM},
	"sub_saharan_africa_old": {"apartments": AFRICA_OLD, "commercial": AFRICA_OLD},
	"sub_saharan_africa_new": {"apartments": NEW_WARM_APT, "commercial": NEW_COM},
	"east_asia_old": {"apartments": EA_OLD, "commercial": EA_OLD},
	"japan_old": {"apartments": JP_OLD, "commercial": JP_OLD},
	"australia_old": {"apartments": AU_OLD, "commercial": AU_OLD},
	"australia_new": {"apartments": NEW_APT, "commercial": NEW_COM},
}

static var BASE: Dictionary = _base()

## Each row inherits from the country region named before its period suffix.
static func _base() -> Dictionary:
	var out := {}
	for key: String in REGIONS:
		out[key] = key.substr(0, key.rfind("_"))
	return out

## Rows as BuildingEra's: [era, kinds, year from, year to, building:architecture
## values, weight, distance band km (unused here)]. Where the country row is
## itself the post-war stock (eastern_europe, the Asian and southern rows) it
## spans those years and no separate _postwar row exists.
const ERAS := {
	"central_europe": [["central_europe_old", AC, 1000, 1918, OLD_TAGS, 2.5, 0.0, 99.0],
		["central_europe", AC, 1919, 1949, ["interwar", "art_deco"], 3.0, 0.0, 99.0],
		["central_europe_postwar", AC, 1950, 1989, POSTWAR_TAGS, 3.0, 0.0, 99.0],
		["central_europe_new", AC, 1990, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"west_europe_brick": [["west_europe_brick_old", AC, 1000, 1899, OLD_TAGS, 2.5, 0.0, 99.0],
		["west_europe_brick", AC, 1900, 1949, ["interwar", "art_deco"], 3.0, 0.0, 99.0],
		["west_europe_brick_postwar", AC, 1950, 1989, POSTWAR_TAGS, 2.5, 0.0, 99.0],
		["west_europe_brick_new", AC, 1990, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"nordic": [["nordic_old", AC, 1000, 1918, OLD_TAGS, 1.5, 0.0, 99.0],
		["nordic", AC, 1919, 1949, ["interwar", "art_deco"], 3.0, 0.0, 99.0],
		["nordic_postwar", AC, 1950, 1989, POSTWAR_TAGS, 3.0, 0.0, 99.0],
		["nordic_new", AC, 1990, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"mediterranean": [["mediterranean_old", AC, 1000, 1918, OLD_TAGS, 2.5, 0.0, 99.0],
		["mediterranean", AC, 1919, 1959, ["interwar", "art_deco"], 3.0, 0.0, 99.0],
		["mediterranean_postwar", AC, 1960, 1989, POSTWAR_TAGS, 3.0, 0.0, 99.0],
		["mediterranean_new", AC, 1990, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"france": [["france_old", AC, 1000, 1918, OLD_TAGS, 2.5, 0.0, 99.0],
		["france", AC, 1919, 1949, ["interwar", "art_deco"], 2.5, 0.0, 99.0],
		["france_postwar", AC, 1950, 1989, POSTWAR_TAGS, 3.0, 0.0, 99.0],
		["france_new", AC, 1990, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"north_america": [["north_america_old", AC, 1000, 1929, OLD_TAGS, 2.5, 0.0, 99.0],
		["north_america", AC, 1930, 1959, ["interwar", "art_deco"], 2.5, 0.0, 99.0],
		["north_america_postwar", AC, 1960, 1989, POSTWAR_TAGS, 2.5, 0.0, 99.0],
		["north_america_new", AC, 1990, 2100, NEW_TAGS, 2.0, 0.0, 99.0]],
	"eastern_europe": [["eastern_europe_old", AC, 1000, 1944, OLD_TAGS, 2.0, 0.0, 99.0],
		["eastern_europe", AC, 1945, 1991, POSTWAR_TAGS, 5.0, 0.0, 99.0],
		["eastern_europe_new", AC, 1992, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"latin_america": [["latin_america_old", AC, 1000, 1939, OLD_TAGS, 2.0, 0.0, 99.0],
		["latin_america", AC, 1940, 1994, POSTWAR_TAGS, 5.0, 0.0, 99.0],
		["latin_america_new", AC, 1995, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"middle_east": [["middle_east_old", AC, 1000, 1949, OLD_TAGS, 2.0, 0.0, 99.0],
		["middle_east", AC, 1950, 1999, POSTWAR_TAGS, 5.0, 0.0, 99.0],
		["middle_east_new", AC, 2000, 2100, NEW_TAGS, 2.0, 0.0, 99.0]],
	"south_asia": [["south_asia_old", AC, 1000, 1949, OLD_TAGS, 1.5, 0.0, 99.0],
		["south_asia", AC, 1950, 2004, POSTWAR_TAGS, 5.0, 0.0, 99.0],
		["south_asia_new", AC, 2005, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"southeast_asia": [["southeast_asia_old", AC, 1000, 1959, OLD_TAGS, 2.0, 0.0, 99.0],
		["southeast_asia", AC, 1960, 2004, POSTWAR_TAGS, 5.0, 0.0, 99.0],
		["southeast_asia_new", AC, 2005, 2100, NEW_TAGS, 2.0, 0.0, 99.0]],
	"sub_saharan_africa": [["sub_saharan_africa_old", AC, 1000, 1959, OLD_TAGS, 1.5, 0.0, 99.0],
		["sub_saharan_africa", AC, 1960, 2004, POSTWAR_TAGS, 5.0, 0.0, 99.0],
		["sub_saharan_africa_new", AC, 2005, 2100, NEW_TAGS, 1.5, 0.0, 99.0]],
	"east_asia": [["east_asia_old", AC, 1000, 1984, OLD_TAGS + POSTWAR_TAGS, 2.0, 0.0, 99.0],
		["east_asia", AC, 1985, 2100, NEW_TAGS, 6.0, 0.0, 99.0]],
	"japan": [["japan_old", AC, 1000, 1969, OLD_TAGS, 1.5, 0.0, 99.0],
		["japan", AC, 1970, 2100, NEW_TAGS + POSTWAR_TAGS, 6.0, 0.0, 99.0]],
	"australia": [["australia_old", AC, 1000, 1939, OLD_TAGS, 2.0, 0.0, 99.0],
		["australia", AC, 1940, 1994, POSTWAR_TAGS, 4.0, 0.0, 99.0],
		["australia_new", AC, 1995, 2100, NEW_TAGS, 2.0, 0.0, 99.0]],
}
