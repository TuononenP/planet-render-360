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

const BASE := {
	"helsinki": "nordic", "helsinki_empire": "helsinki", "helsinki_functional": "helsinki",
	"helsinki_modern": "helsinki", "helsinki_classicism": "helsinki", "helsinki_wood": "helsinki",
	"helsinki_suburb": "helsinki", "helsinki_element": "helsinki", "helsinki_midrise": "helsinki",
	"espoo": "nordic", "tapiola": "espoo", "otaniemi": "espoo", "espoo_modern": "espoo",
	"kauniainen": "espoo",
}

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
	],
	"espoo": [
		["tapiola", ALL, 1950, 1989, ["modernism", "functionalism", "garden_city"], 5.0, 0.0, 99.0],
		["otaniemi", ALL, 1949, 1980, ["aalto", "regional_modernism"], 1.0, 0.0, 99.0],
		["espoo_modern", ALL, 1990, 2100, ["contemporary", "high-tech", "skyscraper"], 3.0, 0.0, 99.0],
		["kauniainen", ["house"], 1800, 1949, ["vernacular", "villa", "national_romantic"], 2.0, 0.0, 99.0],
	],
}

const REGIONS := {
	"helsinki": {
		"apartments": {"w": [["render", JUGEND], ["render", EMPIRE]], "p": [["ornate", 2], ["punched", 2]],
			"wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["hipped", 3], ["gabled", 2], ["mansard", 1]], "pitch": 1.15,
			"rf": SHEET_METAL + [["terracotta", RED_TILE]], "fh": 3.2, "st": [5, 6], "fix": true,
			"ch": 0.4, "dm": 0.4, "g": [["stone", 2], ["shop", 1]], "ev": 0.2,
			"rv": {"string_course": true, "balconette": 0.25, "oriel": 0.2, "granite_plinth": true, "turret": 0.35, "snow_guard": true}},
		"commercial": {"w": [["render", JUGEND], ["stone", ["#9a948a", "#a8a090"]]], "p": [["ornate", 2], ["punched", 1]],
			"wn": "casement", "r": [["hipped", 2], ["flat", 1]], "rf": SHEET_METAL, "st": [4, 7],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "granite_plinth": true, "turret": 0.2, "snow_guard": true}},
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
			"st": [4, 6], "fix": true, "rv": {"string_course": true, "granite_plinth": true, "snow_guard": true}},
	},
	"helsinki_wood": {
		"house": {"w": [["wood", NORDIC_WOOD]], "p": "clapboard", "wn": "casement", "bay": 2.6,
			"fr": "#f2ede0", "r": [["gabled", 3], ["hipped", 1]], "pitch": 0.75, "rf": SHEET_METAL,
			"st": [1, 2], "fix": true, "rv": {"snow_guard": true}},
		"apartments": {"w": [["wood", NORDIC_WOOD]], "p": "clapboard", "wn": "casement",
			"r": [["gabled", 1]], "rf": SHEET_METAL, "st": [2, 2], "fix": true, "rv": {"snow_guard": true}},
	},
	"helsinki_suburb": {
		"apartments": {"w": [["render", WHITE]], "p": [["punched", 3], ["balcony", 1]], "wn": "wide",
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.35, "rf": SHEET_METAL,
			"st": [3, 4], "fix": true, "rv": {"glazed_balcony": 0.35, "snow_guard": true}},
		"house": {"w": [["render", WHITE], ["wood", NORDIC_WOOD]], "p": "punched", "wn": "casement",
			"r": [["gabled", 1]], "pitch": 0.7, "rf": SHEET_METAL, "st": [1, 2], "fix": true,
			"rv": {"snow_guard": true}},
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
	"espoo": {
		"apartments": {"w": [["render", WHITE], ["concrete", WHITE]], "p": "punched", "wn": "wide",
			"bay": 3.6, "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 5], "fix": true,
			"rv": {"glazed_balcony": 0.55}},
		"house": {"w": [["wood", ["#e8d6ae", "#eee9df", "#b6c0b2"]], ["render", WHITE]], "p": "punched",
			"r": [["gabled", 2], ["flat", 1]], "pitch": 0.45, "rf": SHEET_METAL, "st": [1, 2], "fix": true,
			"rv": {"snow_guard": true}},
	},
	"tapiola": {
		"apartments": {"w": [["render", ["#efeee6", "#e1dfd3"]], ["concrete", WHITE]],
			"p": [["punched", 3], ["strip", 1]], "wn": "wide", "bay": 3.6, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [3, 4], "fix": true, "rv": {"glazed_balcony": 0.45}},
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
		"commercial": {"w": [["glass", []], ["render", WHITE]], "p": "curtain", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [8, 22], "fix": true, "rv": {}},
		"apartments": {"w": [["render", WHITE], ["brick", ["#b67b57"]]], "p": [["panel", 1], ["punched", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 16], "fix": true,
			"rv": {"glazed_balcony": 0.85}},
	},
	"kauniainen": {
		"house": {"w": [["wood", NORDIC_WOOD], ["render", PASTEL]], "p": "punched", "wn": "casement",
			"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.8, "rf": SHEET_METAL, "st": [1, 2],
			"fix": true, "rv": {"granite_plinth": true, "snow_guard": true}},
	},
}
