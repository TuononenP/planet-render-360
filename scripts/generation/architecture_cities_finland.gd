class_name ArchitectureCitiesFinland
extends RefCounted

## Finnish fabric: historical centre, wooden districts, forest suburbs,
## concrete element construction and the modern courtyard/tower districts.
## Same row schema as ArchitectureData. Real tags always take precedence.
const ALL := ["house", "apartments", "commercial", "civic"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const NORDIC_WOOD := ArchitectureCitiesNorth.NORDIC_WOOD
const EMPIRE := ArchitectureCitiesNorth.EMPIRE
const JUGEND := ArchitectureCitiesNorth.JUGEND
const SHEET_METAL := ArchitectureCitiesNorth.SHEET_METAL
const RED_TILE := ArchitectureCitiesNorth.RED_TILE
const PASTEL := ["#e6d8be", "#d6b6a2", "#d8d5b7", "#e8d6a4", "#ccd2c5"]
const WHITE := ["#eeeae0", "#dcd8cc", "#e6d9ae"]
const PANEL := ["#c4bdb1", "#d4cec2", "#b6b3a9", "#ded6c7"]
const COMMERCIAL_STONE := ["#a6a7a4", "#acaaa5", "#9fa09e", "#a9a8a3", "#b2aea4"]

const BASE := {
	"helsinki": "nordic", "helsinki_empire": "helsinki", "helsinki_functional": "helsinki",
	"helsinki_modern": "helsinki", "helsinki_classicism": "helsinki", "helsinki_wood": "helsinki",
	"helsinki_suburb": "helsinki", "helsinki_element": "helsinki", "helsinki_midrise": "helsinki",
	"helsinki_villa": "helsinki", "espoo": "nordic", "tapiola": "espoo", "otaniemi": "espoo", "espoo_modern": "espoo",
	"kauniainen": "espoo",
	"turku": "nordic", "turku_empire": "turku", "turku_wood": "turku", "turku_functional": "turku",
	"turku_commercial": "turku", "turku_jugend": "turku", "turku_campus": "turku",
	"turku_suburb": "turku", "turku_element": "turku", "turku_midrise": "turku", "turku_villa": "turku",
}

## Turku eras a building takes only inside one of their own district circles.
const DISTRICT_ONLY := ["turku_commercial", "turku_campus"]

const ERAS := {
	"helsinki": [
		["helsinki_empire", ALL, 1700, 1880, ["empire", "neoclassical", "neoclassicism"], 0.4, 0.0, 1.2],
		["helsinki", AC, 1881, 1919, ["jugendstil", "art_nouveau", "national_romantic", "national_romanticism"], 4.0, 0.0, 4.0],
		["helsinki_classicism", ALL, 1920, 1934, ["nordic_classicism", "classicism", "classical"], 2.0, 1.0, 6.0],
		["helsinki_functional", ACC, 1935, 1964, ["functionalism", "functionalist"], 2.0, 0.5, 6.0],
		["helsinki_wood", ["house", "apartments"], 1800, 1940, ["wooden", "vernacular"], 1.0, 2.0, 99.0],
		["helsinki_suburb", ALL, 1945, 1964, [], 3.0, 3.0, 99.0],
		["helsinki_element", ACC, 1965, 1989, ["prefab", "element", "brutalist"], 3.0, 2.0, 99.0],
		["helsinki_midrise", ALL, 1990, 2100, ["contemporary"], 2.0, 1.0, 99.0],
		["helsinki_modern", ACC, 1990, 2100, ["skyscraper", "high-tech"], 0.5, 0.0, 99.0],
		["helsinki_villa", ["house"], 1900, 1975, ["villa"], 0.5, 4.0, 99.0],
	],
	"espoo": [
		["tapiola", ALL, 1950, 1989, ["modernism", "functionalism", "garden_city"], 5.0, 0.0, 99.0],
		["otaniemi", ALL, 1949, 1980, ["aalto", "regional_modernism"], 1.0, 0.0, 99.0],
		["espoo_modern", ALL, 1990, 2100, ["contemporary", "high-tech", "skyscraper"], 3.0, 0.0, 99.0],
		["kauniainen", ["house"], 1800, 1949, ["vernacular", "villa", "national_romantic"], 2.0, 0.0, 99.0],
	],
	"turku": [
		["turku_empire", ALL, 1700, 1885, ["empire", "neoclassical", "neoclassicism"], 0.8, 0.0, 1.8],
		["turku", AC, 1886, 1929, ["jugendstil", "art_nouveau", "national_romantic", "national_romanticism", "nordic_classicism"], 3.5, 0.0, 3.5],
		["turku_wood", ["house", "apartments"], 1800, 1945, ["wooden", "vernacular"], 2.5, 0.3, 99.0],
		["turku_functional", ACC, 1930, 1969, ["functionalism", "functionalist", "modernism"], 2.5, 0.0, 5.0],
		["turku_suburb", ALL, 1945, 1964, [], 2.5, 2.5, 99.0],
		["turku_element", ACC, 1965, 1989, ["prefab", "element", "brutalist"], 3.0, 2.0, 99.0],
		["turku_midrise", ALL, 1990, 2100, ["contemporary", "high-tech"], 2.5, 0.8, 99.0],
		["turku_villa", ["house"], 1850, 1960, ["villa"], 1.0, 3.0, 99.0],
		# District fabrics (DISTRICT_ONLY): only inside their CityStyles circles.
		["turku_commercial", ACC, 1920, 2100, [], 0.3, 0.0, 1.0],
		["turku_jugend", ACC, 1885, 1920, ["jugendstil", "art_nouveau", "national_romantic"], 0.4, 0.0, 1.5],
		["turku_campus", ACC, 1935, 2100, [], 0.3, 0.5, 2.5],
	],
}

const REGIONS := {
	"helsinki": {
		"apartments": {"w": [["render", JUGEND], ["render", EMPIRE]], "p": [["ornate", 2], ["punched", 2]],
			"wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["hipped", 3], ["gabled", 2], ["mansard", 1]], "pitch": 1.15,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "fh": 3.2, "st": [5, 6], "fix": true,
			"ch": 0.4, "dm": 0.4, "g": [["stone", 2], ["shop", 1]], "ev": 0.2,
			"rv": {"string_course": true, "balconette": 0.25, "oriel": 0.2, "granite_plinth": true, "turret": 0.35}},
		"commercial": {"w": [["render", JUGEND], ["stone", ["#9a948a", "#a8a090"]]], "p": [["ornate", 2], ["punched", 1]],
			"wn": "casement", "r": [["hipped", 2], ["flat", 1]], "rf": SHEET_METAL, "st": [4, 7],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "granite_plinth": true, "turret": 0.2}},
	},
	"helsinki_empire": {
		"apartments": {"w": [["render", EMPIRE]], "p": "punched", "wn": "casement", "bay": 2.8,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL,
			"fh": 3.4, "st": [2, 4], "fix": true, "ch": 0.5, "g": [["none", 1], ["shop", 1]],
			"rv": {"string_course": true, "quoins": true}},
		"house": {"w": [["render", EMPIRE], ["wood", ["#e8c878", "#d8b070"]]], "p": "punched", "wn": "casement",
			"fr": "#f4f1ea", "r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL, "st": [1, 2],
			"fix": true, "rv": {"string_course": true}},
		"civic": {"w": [["render", EMPIRE], ["render", ["#f2ede0"]]], "p": "punched", "wn": "casement",
			"r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL, "st": [2, 4], "fix": true,
			"rv": {"string_course": true, "quoins": true}},
	},
	"helsinki_functional": {
		"apartments": {"w": [["render", ["#ece8dc", "#e0d8c0", "#d8d0c0"]], ["brick", ["#9a4a35", "#a86048"]]],
			"p": [["strip", 2], ["punched", 2], ["balcony", 2]], "wn": "wide", "bay": 3.0,
			"r": [["flat", 3], ["hipped", 1]], "pitch": 0.4, "rf": [["membrane", []], ["slate", ["#3a3e44"]]],
			"st": [5, 8], "fix": true, "rv": {"deep_balcony": 0.3}},
		"commercial": {"w": [["render", ["#ece8dc"]], ["concrete", ["#c8c4bc"]]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 8], "fix": true, "rv": {}},
	},
	"helsinki_modern": {
		"apartments": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["balcony", 2], ["curtain", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [10, 30], "fix": true,
			"rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [8, 30], "fix": true, "rv": {}},
	},
	"helsinki_classicism": {
		"apartments": {"w": [["render", PASTEL]], "p": "punched", "wn": "casement", "bay": 2.7,
			"fr": "#eee9dc", "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.65, "rf": SHEET_METAL,
			"st": [4, 6], "fix": true, "rv": {"string_course": true, "granite_plinth": true}},
	},
	"helsinki_wood": {
		"house": {"w": [["wood", NORDIC_WOOD]], "p": "clapboard", "wn": "casement", "bay": 2.6,
			"fr": "#f2ede0", "r": [["gabled", 3], ["hipped", 1]], "pitch": 0.75, "rf": SHEET_METAL,
			"st": [1, 2], "fix": true, "rv": {}},
		"apartments": {"w": [["wood", NORDIC_WOOD]], "p": "clapboard", "wn": "casement",
			"r": [["gabled", 1]], "rf": SHEET_METAL, "st": [2, 2], "fix": true, "rv": {}},
	},
	"helsinki_suburb": {
		"apartments": {"w": [["render", WHITE]], "p": [["punched", 3], ["balcony", 1]], "wn": "wide",
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.35, "rf": SHEET_METAL,
			"st": [3, 4], "fix": true, "rv": {"glazed_balcony": 0.35}},
		"house": {"w": [["render", WHITE], ["wood", NORDIC_WOOD]], "p": "punched", "wn": "casement",
			"r": [["gabled", 1]], "pitch": 0.7, "rf": SHEET_METAL, "st": [1, 2], "fix": true,
			"rv": {}},
	},
	"helsinki_element": {
		"apartments": {"w": [["concrete", PANEL]], "p": "panel", "wn": "wide", "bay": 3.6,
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 9], "fix": true,
			"rv": {"glazed_balcony": 0.8}},
		"commercial": {"w": [["concrete", PANEL]], "p": "panel", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [3, 7], "fix": true, "rv": {}},
	},
	"helsinki_midrise": {
		"commercial": {"w": [["render", WHITE], ["brick", ["#ab795a"]]], "p": [["strip", 1], ["punched", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 6], "fix": true, "rv": {}},
		"apartments": {"w": [["brick", ["#965640", "#ba8a68"]], ["render", WHITE], ["concrete", PANEL]],
			"p": [["punched", 2], ["panel", 1]], "wn": "wide", "bay": 3.2, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [6, 8], "fix": true, "rv": {"glazed_balcony": 0.65}},
	},
	# Kuusisaari and Lehtisaari: large-lot villas of the 1910s–60s, pale
	# render or timber, hipped tile or metal roofs, or flat modernist ones.
	"helsinki_villa": {
		"house": {"w": [["render", PASTEL], ["render", WHITE], ["wood", NORDIC_WOOD]], "p": "punched",
			"wn": "casement", "bay": 3.0, "fr": "#f2ede0", "r": [["hipped", 3], ["flat", 2], ["gabled", 1]],
			"pitch": 0.55, "rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [1, 2], "fix": true,
			"rv": {"granite_plinth": true}},
	},
	"espoo": {
		"apartments": {"w": [["render", WHITE], ["concrete", WHITE]], "p": "punched", "wn": "wide",
			"bay": 3.6, "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 5], "fix": true,
			"rv": {"glazed_balcony": 0.55, "modern": {"fascia": [["metal", 2], ["render", 1]], "core": 0.6}}},
		"house": {"w": [["wood", ["#e8d6ae", "#eee9df", "#b6c0b2"]], ["render", WHITE]], "p": "punched",
			"r": [["gabled", 2], ["flat", 1]], "pitch": 0.45, "rf": SHEET_METAL, "st": [1, 2], "fix": true,
			"rv": {}},
	},
	"tapiola": {
		"apartments": {"w": [["render", ["#efeee6", "#e1dfd3"]], ["concrete", WHITE]],
			"p": [["punched", 3], ["strip", 1]], "wn": "wide", "bay": 3.6, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [3, 4], "fix": true,
			"rv": {"glazed_balcony": 0.45, "modern": {"fascia": [["render", 2], ["metal", 1]], "core": 0.35, "base": 0.9}}},
	},
	"otaniemi": {
		"civic": {"w": [["brick", ["#9a4932", "#ad593e"]]], "p": "strip", "bay": 3.0,
			"r": [["flat", 3], ["skillion", 1]], "rf": [["copper", ["#538472", "#426a5c"]]],
			"st": [2, 4], "fix": true, "rv": {"granite_plinth": true}},
		"apartments": {"w": [["brick", ["#9a4932", "#ad593e"]]], "p": "punched", "wn": "wide",
			"r": [["flat", 1]], "rf": [["copper", ["#538472"]]], "st": [3, 5], "fix": true,
			"rv": {"glazed_balcony": 0.3}},
	},
	"espoo_modern": {
		"commercial": {"w": [["glass", []], ["render", WHITE], ["stone", ["#d8d4c8", "#c9c5ba"]]],
			"p": [["curtain", 2], ["strip", 1]], "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [8, 22], "fix": true,
			"rv": {"modern": {"fins": 0.7, "fascia": [["metal", 3], ["alu", 1]]}}},
		"apartments": {"w": [["render", WHITE], ["brick", ["#b67b57"]]], "p": [["panel", 1], ["punched", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 16], "fix": true,
			"rv": {"glazed_balcony": 0.85, "modern": {"fascia": [["metal", 1]], "core": 0.7,
				"entrance_kind": [["portal", 1]]}}},
	},
	"kauniainen": {
		"house": {"w": [["wood", NORDIC_WOOD], ["render", PASTEL]], "p": "punched", "wn": "casement",
			"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.8, "rf": SHEET_METAL, "st": [1, 2],
			"fix": true, "rv": {"granite_plinth": true}},
	},
	# Turku: post-1827 Engel Empire grid, 1890s–1910s Jugendstil & National
	# Romantic stone/plaster blocks, iconic timber districts (Port Arthur,
	# Luostarinmäki, Martti), mid-century functionalism, concrete-panel
	# suburbs (Varissuo, Runosmäki), Kupittaa/Telakkaranta midrise and
	# Ruissalo seaside villas.
	"turku": {
		"apartments": {"w": [["render", JUGEND], ["render", EMPIRE], ["brick", ["#9a523c", "#b07452"]]],
			"p": [["punched", 3], ["ornate", 2]], "wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["hipped", 3], ["gabled", 2], ["flat", 1]], "pitch": 0.85,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "fh": 3.1, "st": [4, 6], "fix": true,
			"ch": 0.35, "dm": 0.3, "g": [["stone", 2], ["shop", 2]], "ev": 0.25,
			"rv": {"string_course": true, "balconette": 0.2, "granite_plinth": true, "turret": 0.18}},
		"commercial": {"w": [["render", EMPIRE], ["render", JUGEND], ["stone", ["#9a948a", "#b0a898"]]],
			"p": [["punched", 2], ["ornate", 1], ["strip", 1]], "wn": "casement",
			"r": [["hipped", 2], ["flat", 2]], "rf": SHEET_METAL + [["membrane", []]], "st": [3, 6],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "granite_plinth": true}},
		"civic": {"w": [["render", EMPIRE], ["brick", ["#944835"]], ["stone", ["#9a948a"]]],
			"p": "punched", "wn": "casement", "r": [["hipped", 2], ["gabled", 1]], "pitch": 0.55,
			"rf": SHEET_METAL, "st": [2, 4], "fix": true, "rv": {"string_course": true, "granite_plinth": true}},
		"house": {"w": [["wood", ["#d9b56c", "#c98b70", "#a6b89e", "#e6dec8", "#8e3426", "#e8d294"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.5, "fr": "#f4f0e6",
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.72,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [1, 2], "fix": true, "rv": {}},
	},
	"turku_empire": {
		"apartments": {"w": [["render", EMPIRE]], "p": "punched", "wn": "casement", "bay": 2.8,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL,
			"fh": 3.3, "st": [2, 3], "fix": true, "ch": 0.45, "g": [["none", 1], ["shop", 1]],
			"rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["render", EMPIRE], ["render", ["#f2ede0"]]], "p": "punched", "wn": "casement",
			"r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL, "st": [2, 3], "fix": true,
			"rv": {"string_course": true, "quoins": true}},
		"house": {"w": [["wood", ["#e5c474", "#d9b474", "#e8dfc6", "#c8a088"]], ["render", EMPIRE]],
			"p": "clapboard", "wn": "casement", "fr": "#f4f1ea", "r": [["hipped", 2], ["gabled", 1]],
			"pitch": 0.45, "rf": SHEET_METAL, "st": [1, 2], "fix": true, "rv": {}},
	},
	"turku_wood": {
		"house": {"w": [["wood", ["#d9b56c", "#c98b70", "#a6b89e", "#e6dec8", "#8e3426", "#e5d090", "#b8a898"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.5, "fr": "#f4f0e4",
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.72,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [1, 2], "fix": true,
			"rv": {"granite_plinth": true}},
		"apartments": {"w": [["wood", ["#d9b56c", "#c98b70", "#a6b89e", "#e6dec8", "#e5d090"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.6, "fr": "#f4f0e4",
			"r": [["gabled", 2], ["hipped", 1]], "pitch": 0.65,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [2, 2], "fix": true,
			"rv": {"granite_plinth": true}},
	},
	"turku_functional": {
		"apartments": {"w": [["render", WHITE], ["render", PASTEL], ["brick", ["#9a503a", "#b07654"]]],
			"p": [["strip", 2], ["punched", 2], ["balcony", 2]], "wn": "wide", "bay": 3.0,
			"r": [["flat", 3], ["hipped", 1]], "pitch": 0.35, "rf": [["membrane", []], ["slate", ["#3a3e44"]]],
			"st": [5, 7], "fix": true, "rv": {"glazed_balcony": 0.45}},
		"commercial": {"w": [["render", WHITE], ["concrete", PANEL]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 7], "fix": true, "rv": {}},
	},
	"turku_suburb": {
		"apartments": {"w": [["render", WHITE], ["brick", ["#a87054"]]], "p": [["punched", 3], ["balcony", 1]],
			"wn": "wide", "r": [["gabled", 2], ["hipped", 1], ["flat", 1]], "pitch": 0.35,
			"rf": SHEET_METAL, "st": [3, 4], "fix": true, "rv": {"glazed_balcony": 0.4}},
		"house": {"w": [["wood", NORDIC_WOOD], ["render", WHITE]], "p": "clapboard", "wn": "casement",
			"r": [["gabled", 1]], "pitch": 0.65, "rf": SHEET_METAL, "st": [1, 2], "fix": true, "rv": {}},
	},
	"turku_element": {
		"apartments": {"w": [["concrete", PANEL]], "p": "panel", "wn": "wide", "bay": 3.6,
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 8], "fix": true,
			"rv": {"glazed_balcony": 0.8}},
		"commercial": {"w": [["concrete", PANEL]], "p": "panel", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [2, 6], "fix": true, "rv": {}},
	},
	"turku_midrise": {
		"apartments": {"w": [["brick", ["#965640", "#ba8a68"]], ["render", WHITE], ["concrete", PANEL]],
			"p": [["punched", 2], ["panel", 1]], "wn": "wide", "bay": 3.2, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 8], "fix": true, "rv": {"glazed_balcony": 0.7}},
		"commercial": {"w": [["glass", []], ["render", WHITE], ["brick", ["#ab795a"]]],
			"p": [["curtain", 1], ["strip", 2], ["punched", 1]], "wn": "wide",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 9], "fix": true, "rv": {}},
	},
	"turku_villa": {
		"house": {"w": [["wood", ["#efe7d4", "#e6d2a2", "#d8c4b0", "#c2d0be", "#f2eee4"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.8, "fr": "#f6f3ea",
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.85,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [1, 2], "fix": true,
			"rv": {"granite_plinth": true}},
	},
	# VI-VII Commercial Core around Kauppatori, Yliopistonkatu, Aurakatu & Eerikinkatu:
	# postwar stone/render/brick commercial blocks contrasting with surviving Jugend palaces.
	"turku_commercial": {
		"commercial": {"w": [["stone", COMMERCIAL_STONE], ["render", ["#e2dcd0", "#d6d0c4", "#e8e4da"]],
				["brick", ["#9a523c", "#b07452"]], ["glass", []]],
			"p": [["strip", 2], ["punched", 2], ["curtain", 1]], "wn": ["wide", "casement"], "bay": 3.0,
			"fr": "#eef0ec", "r": [["flat", 3], ["hipped", 1]], "pitch": 0.3,
			"rf": [["membrane", []], ["sheet_metal", ["#3a3e44", "#45494e"]]], "fh": 3.5,
			"st": [4, 7], "fix": true, "g": [["shop", 4], ["stone", 1]],
			"rv": {"string_course": true, "granite_plinth": true}},
		"apartments": {"w": [["render", ["#e2dcd0", "#d8ceb8", "#cdc4b2"]], ["brick", ["#9a523c", "#a8684c"]],
				["concrete", PANEL]],
			"p": [["punched", 2], ["strip", 2], ["balcony", 1]], "wn": ["wide", "casement"], "bay": 2.9,
			"fr": "#f0ece4", "r": [["flat", 2], ["hipped", 2]], "pitch": 0.35,
			"rf": [["sheet_metal", ["#3a3e44", "#45494e"]], ["membrane", []]], "fh": 3.2,
			"st": [5, 7], "fix": true, "g": [["shop", 3], ["stone", 1]],
			"rv": {"string_course": true, "granite_plinth": true, "glazed_balcony": 0.35}},
		"civic": {"w": [["stone", COMMERCIAL_STONE], ["render", ["#dcd4c2", "#e6e0d2"]]],
			"p": "punched", "wn": ["casement", "wide"], "r": [["flat", 2], ["hipped", 1]], "pitch": 0.3,
			"rf": SHEET_METAL, "st": [3, 6], "fix": true,
			"rv": {"string_course": true, "granite_plinth": true}},
	},
	# Puolalanmäki, Humalistonkatu & Kaskenmäki: 1890s-1915 Strandell / National Romantic
	# Jugendstil apartment palaces with rough granite plinths, asymmetric gables & turrets.
	"turku_jugend": {
		"apartments": {"w": [["render", JUGEND], ["stone", ["#9a948a", "#a89e92"]], ["brick", ["#964836", "#8c4230"]]],
			"p": [["ornate", 3], ["punched", 2]], "wn": ["casement", "casement", "french"], "bay": 2.6,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 3], ["gabled", 2], ["mansard", 1]], "pitch": 0.9,
			"rf": SHEET_METAL + [["copper", COPPER], ["terracotta", RED_TILE]], "fh": 3.3,
			"st": [4, 6], "fix": true, "ch": 0.4, "dm": 0.35, "g": [["stone", 3], ["shop", 2]], "ev": 0.28,
			"rv": {"string_course": true, "granite_plinth": true, "balconette": 0.25, "turret": 0.3}},
		"commercial": {"w": [["render", JUGEND], ["stone", ["#9a948a", "#a89e92"]]],
			"p": [["ornate", 2], ["punched", 1]], "wn": "casement", "r": [["hipped", 2], ["gabled", 1]],
			"pitch": 0.75, "rf": SHEET_METAL + [["copper", COPPER]], "fh": 3.4, "st": [4, 6],
			"fix": true, "g": [["shop", 2], ["stone", 1]],
			"rv": {"string_course": true, "granite_plinth": true, "turret": 0.2}},
		"civic": {"w": [["stone", ["#9a948a", "#a89e92"]], ["render", JUGEND]], "p": "ornate",
			"wn": "casement", "r": [["hipped", 2], ["gabled", 1]], "pitch": 0.7, "rf": SHEET_METAL,
			"st": [2, 4], "fix": true, "rv": {"string_course": true, "granite_plinth": true}},
	},
	# Yliopistonmäki, TYKS Hospital Area & Kupittaa Science Park: crisp white/light-metal
	# functionalist & contemporary university, clinical, research & glass atrium blocks.
	"turku_campus": {
		"civic": {"w": [["render", WHITE], ["concrete", ["#e4e2da", "#d8d6ce"]], ["glass", []],
				["brick", ["#9c543e", "#b07656"]]],
			"p": [["strip", 2], ["curtain", 2], ["punched", 1]], "wn": "wide", "bay": 3.2,
			"fr": "#eef2f4", "r": [["flat", 4], ["skillion", 1]], "pitch": 0.2,
			"rf": [["membrane", []], ["sheet_metal", ["#464a50"]]], "fh": 3.6,
			"st": [3, 7], "fix": true, "rv": {"modern": {"fins": 0.45, "fascia": [["metal", 2], ["alu", 1]]}}},
		"commercial": {"w": [["glass", []], ["render", WHITE], ["brick", ["#a05840", "#b27858"]]],
			"p": [["curtain", 2], ["strip", 2]], "wn": "wide", "bay": 3.2,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.5, "st": [4, 8], "fix": true,
			"rv": {"modern": {"fins": 0.5, "fascia": [["metal", 2], ["alu", 1]]}}},
		"apartments": {"w": [["render", WHITE], ["brick", ["#9e5a42", "#b48262"]]],
			"p": [["punched", 2], ["strip", 1]], "wn": "wide", "bay": 3.2, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [4, 7], "fix": true, "rv": {"glazed_balcony": 0.55}},
	},
	"turku_empire": {
		"apartments": {"w": [["render", EMPIRE]], "p": "punched", "wn": "casement", "bay": 2.8,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL,
			"fh": 3.3, "st": [2, 3], "fix": true, "ch": 0.45, "g": [["none", 1], ["shop", 1]],
			"rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["render", EMPIRE], ["render", ["#f2ede0"]]], "p": "punched", "wn": "casement",
			"r": [["hipped", 1]], "pitch": 0.4, "rf": SHEET_METAL, "st": [2, 3], "fix": true,
			"rv": {"string_course": true, "quoins": true}},
		"house": {"w": [["wood", ["#e5c474", "#d9b474", "#e8dfc6", "#c8a088"]], ["render", EMPIRE]],
			"p": "clapboard", "wn": "casement", "fr": "#f4f1ea", "r": [["hipped", 2], ["gabled", 1]],
			"pitch": 0.45, "rf": SHEET_METAL, "st": [1, 2], "fix": true, "rv": {}},
	},
	"turku_wood": {
		"house": {"w": [["wood", ["#d9b56c", "#c98b70", "#a6b89e", "#e6dec8", "#8e3426", "#e5d090", "#b8a898"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.5, "fr": "#f4f0e4",
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.72,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [1, 2], "fix": true,
			"rv": {"granite_plinth": true}},
		"apartments": {"w": [["wood", ["#d9b56c", "#c98b70", "#a6b89e", "#e6dec8", "#e5d090"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.6, "fr": "#f4f0e4",
			"r": [["gabled", 2], ["hipped", 1]], "pitch": 0.65,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [2, 2], "fix": true,
			"rv": {"granite_plinth": true}},
	},
	"turku_functional": {
		"apartments": {"w": [["render", WHITE], ["render", PASTEL], ["brick", ["#9a503a", "#b07654"]]],
			"p": [["strip", 2], ["punched", 2], ["balcony", 2]], "wn": "wide", "bay": 3.0,
			"r": [["flat", 3], ["hipped", 1]], "pitch": 0.35, "rf": [["membrane", []], ["slate", ["#3a3e44"]]],
			"st": [5, 7], "fix": true, "rv": {"glazed_balcony": 0.45}},
		"commercial": {"w": [["render", WHITE], ["concrete", PANEL]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 7], "fix": true, "rv": {}},
	},
	"turku_suburb": {
		"apartments": {"w": [["render", WHITE], ["brick", ["#a87054"]]], "p": [["punched", 3], ["balcony", 1]],
			"wn": "wide", "r": [["gabled", 2], ["hipped", 1], ["flat", 1]], "pitch": 0.35,
			"rf": SHEET_METAL, "st": [3, 4], "fix": true, "rv": {"glazed_balcony": 0.4}},
		"house": {"w": [["wood", NORDIC_WOOD], ["render", WHITE]], "p": "clapboard", "wn": "casement",
			"r": [["gabled", 1]], "pitch": 0.65, "rf": SHEET_METAL, "st": [1, 2], "fix": true, "rv": {}},
	},
	"turku_element": {
		"apartments": {"w": [["concrete", PANEL]], "p": "panel", "wn": "wide", "bay": 3.6,
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 8], "fix": true,
			"rv": {"glazed_balcony": 0.8}},
		"commercial": {"w": [["concrete", PANEL]], "p": "panel", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [2, 6], "fix": true, "rv": {}},
	},
	"turku_midrise": {
		"apartments": {"w": [["brick", ["#965640", "#ba8a68"]], ["render", WHITE], ["concrete", PANEL]],
			"p": [["punched", 2], ["panel", 1]], "wn": "wide", "bay": 3.2, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 8], "fix": true, "rv": {"glazed_balcony": 0.7}},
		"commercial": {"w": [["glass", []], ["render", WHITE], ["brick", ["#ab795a"]]],
			"p": [["curtain", 1], ["strip", 2], ["punched", 1]], "wn": "wide",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 9], "fix": true, "rv": {}},
	},
	"turku_villa": {
		"house": {"w": [["wood", ["#efe7d4", "#e6d2a2", "#d8c4b0", "#c2d0be", "#f2eee4"]]],
			"p": "clapboard", "wn": "casement", "bay": 2.8, "fr": "#f6f3ea",
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.85,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "st": [1, 2], "fix": true,
			"rv": {"granite_plinth": true}},
	},
}
