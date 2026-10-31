class_name ArchitectureCitiesAsia
extends RefCounted

## Asian city rows (CityStyles zones) and their era rows (BuildingEra):
## Tokyo, Hong Kong, Singapore. City rows inherit from japan /
## east_asia / southeast_asia; eras from their city. Same key legend as
## ArchitectureData; `rv` = 3D relief (replaces the parent's).

const TOKYO_FRONT := ["#e4e2dc", "#d8d6d0", "#cfccc4", "#e6e0d2", "#c8c0b0", "#b8b4ac"]
## Dark kawara (fired clay) roof tiles; the roof floor keeps them off black.
const KAWARA := ["#3a3e44", "#454a52", "#2f343a"]
const HK_TOWER := ["#e8e0d0", "#d8d0c0", "#e0d8c8", "#c8d0d8", "#e8d8c8", "#d0c8b8"]
const HK_SIGNS := ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a", "#8a1a5a"]
## Shophouse pastels and lacquered shutters.
const SHOPHOUSE := ["#e8c070", "#a8c8b0", "#e8a8a0", "#b0c8e0", "#f0e0b0", "#d8e8c8", "#e8b8c8", "#c8d8e8"]
const SHUTTERS := ["#2f5a46", "#7a3a2a", "#2a4a6a", "#5a3a5a", "#3f6a5a"]
## HDB block colour bands (painted spandrel bands on the panel pattern).
const HDB_BANDS := ["#c84a3a", "#3a6a9a", "#e8a030", "#4a8a5a", "#8a5a9a", "#d87a4a"]

const BASE := {
	"tokyo": "japan", "tokyo_house": "tokyo", "tokyo_tower": "tokyo",
	"hong_kong": "east_asia", "hk_tenement": "hong_kong", "hk_office": "hong_kong",
	"singapore": "southeast_asia", "sg_shophouse": "singapore", "sg_tower": "singapore",
}

const REGIONS := {
	# Dense, small 3–8 storey mixed buildings: tiled or concrete fronts,
	# aluminium sliders, balconies, vertical signs, rooftop plant.
	"tokyo": {
		"apartments": {"w": [["render", TOKYO_FRONT], ["concrete", ["#c8c4bc", "#bdb8ac"]]],
			"p": [["balcony", 3], ["tiles", 3], ["punched", 2], ["strip", 1]], "wn": "wide",
			"bay": 2.6, "fr": "#9a9c9e", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.0, "st": [3, 8], "fix": true, "ch": 0.0, "eq": 0.85,
			"g": [["signage", 2], ["none", 2]], "ev": 0.0,
			"rv": {"signage": 0.45, "deep_balcony": 0.45, "awning": 0.1,
				"awning_colours": ["#2a4a6a", "#8a2a1a", "#e8e4da"]}},
		"commercial": {"w": [["render", TOKYO_FRONT], ["concrete", ["#c8c4bc"]], ["glass", []]],
			"p": [["tiles", 3], ["strip", 2], ["punched", 2]], "wn": "wide", "bay": 2.6,
			"fr": "#8a8c8e", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2,
			"st": [3, 9], "fix": true, "eq": 0.9, "g": [["signage", 1]], "ev": 0.0,
			"rv": {"signage": 0.75, "awning": 0.15,
				"awning_colours": ["#2a4a6a", "#8a2a1a", "#e8e4da"]}},
	},
	# Low houses: render or dark timber, dark kawara tile roofs, eaves.
	"tokyo_house": {
		"house": {"w": [["render", ["#e8e4dc", "#d8d0c0", "#c8c0b0"]], ["wood", ["#5a4a3a", "#6b5a48", "#4a3a2e"]]],
			"p": "punched", "wn": "wide", "bay": 2.0, "fr": "#8a8c8e", "sp": 0.0,
			"r": [["gabled", 3], ["hipped", 3]], "pitch": 0.65, "rf": [["slate", KAWARA]],
			"fh": 2.8, "st": [2, 2], "fix": true, "ch": 0.0, "eq": 0.3, "g": [["none", 1]], "ev": 0.6,
			"rv": {"signage": 0.05, "deep_balcony": 0.1}},
	},
	"tokyo_tower": {
		"apartments": {"w": [["concrete", ["#d8d6d0", "#cfccc4"]], ["glass", []]],
			"p": [["balcony", 3], ["strip", 1]], "wn": "wide", "bay": 3.0, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.1, "st": [15, 45], "fix": true, "eq": 0.9,
			"g": [["none", 1], ["shop", 1]], "rv": {"deep_balcony": 0.7}},
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d6d0"]]], "p": [["curtain", 3], ["strip", 2], ["tiles", 1]],
			"bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8, "st": [15, 50],
			"fix": true, "eq": 0.9, "g": [["signage", 1], ["shop", 1]], "rv": {"signage": 0.2}},
		"civic": {"w": [["concrete", ["#d8d6d0"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [6, 20], "fix": true, "rv": {}},
	},
	# Slender 20–40 storey residential towers: pale tiled or painted
	# concrete, bay windows, plant on top, signage below.
	"hong_kong": {
		"apartments": {"w": [["concrete", HK_TOWER], ["render", ["#ecebe6", "#e0e4e8"]]],
			"p": [["tiles", 3], ["balcony", 2], ["punched", 2]], "wn": "wide", "bay": 2.6,
			"fr": "#8a8c8e", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.9, "st": [20, 40], "fix": true, "ch": 0.0, "eq": 0.6,
			"g": [["signage", 2], ["shop", 1]], "gc": HK_SIGNS, "ev": 0.0,
			"rv": {"oriel": 0.5, "deep_balcony": 0.2, "signage": 0.3}},
		"commercial": {"w": [["concrete", HK_TOWER], ["glass", []]], "p": [["tiles", 2], ["strip", 2]],
			"wn": "wide", "bay": 2.8, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.4,
			"st": [8, 25], "fix": true, "eq": 0.8, "g": [["signage", 1]], "gc": HK_SIGNS,
			"rv": {"signage": 0.8}},
	},
	# Tong lau tenements: 4–8 storey, verandahs, shuttered windows,
	# dense vertical signs over shopfronts.
	"hk_tenement": {
		"apartments": {"w": [["render", ["#d8c8a8", "#c8b898", "#e0d0b8", "#b8b0a0", "#d0c0a0", "#a8b0a8"]], ["concrete", ["#c0b8a8"]]],
			"p": [["shophouse", 2], ["balcony", 2], ["punched", 1]], "wn": "french", "bay": 3.0,
			"fr": "#5a5e62", "sh": ["#4a6a5a", "#5a4a3a", "#3a4a6a"], "sp": 0.3, "rl": 0.3,
			"r": [["flat", 1]], "rf": [["concrete", []]], "fh": 3.2, "st": [4, 8], "fix": true,
			"eq": 0.7, "g": [["signage", 3], ["shop", 1]], "gc": HK_SIGNS, "ev": 0.0,
			"rv": {"signage": 0.85, "deep_balcony": 0.4, "awning": 0.4,
				"awning_colours": ["#2a4a6a", "#8a2a1a", "#e8b820", "#2a7a3a"]}},
		"commercial": {"w": [["render", ["#d8c8a8", "#c8b898", "#e0d0b8"]]], "p": [["shophouse", 2], ["punched", 1]],
			"wn": "french", "bay": 3.0, "sh": ["#4a6a5a", "#5a4a3a"], "sp": 0.3, "r": [["flat", 1]],
			"rf": [["concrete", []]], "fh": 3.3, "st": [3, 7], "fix": true, "g": [["signage", 1]],
			"gc": HK_SIGNS, "rv": {"signage": 0.9, "awning": 0.5,
				"awning_colours": ["#2a4a6a", "#8a2a1a", "#e8b820"]}},
	},
	"hk_office": {
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["curtain", 4], ["strip", 1]],
			"bay": 3.0, "fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.0,
			"st": [20, 60], "fix": true, "eq": 0.9, "g": [["shop", 1]], "rv": {}},
		"civic": {"w": [["concrete", ["#d8d4cc"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 15], "fix": true, "rv": {}},
	},
	# HDB slabs: white render, painted colour bands, panel grid windows,
	# void deck below, water tanks on the roof.
	"singapore": {
		"apartments": {"w": [["render", ["#ecebe6", "#e8e4dc", "#f0ece4", "#e4e0d8"]], ["concrete", ["#d8d4cc"]]],
			"p": [["panel", 3], ["balcony", 2]], "wn": "wide", "bay": 3.0, "fr": "#8a8c8e",
			"sh": HDB_BANDS, "sp": 1.0, "rl": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.8, "st": [10, 25], "fix": true, "ch": 0.0, "eq": 0.5,
			"g": [["none", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.3, "signage": 0.05}},
		"commercial": {"w": [["render", ["#ecebe6", "#e8e4dc"]], ["glass", []]], "p": [["strip", 2], ["panel", 1]],
			"wn": "wide", "sh": HDB_BANDS, "sp": 1.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [3, 8], "fix": true, "g": [["shop", 1]], "rv": {"signage": 0.3}},
	},
	# Shophouses: 2–3 storey, colourful plaster, tall shuttered windows
	# between pilasters, five-foot way under a tiled roof.
	"sg_shophouse": {
		"commercial": {"w": [["render", SHOPHOUSE]], "p": "shophouse", "wn": "french", "bay": 2.4,
			"fr": "#f4f1ea", "sh": SHUTTERS, "sp": 0.9, "rl": 0.4,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.6,
			"rf": [["terracotta", ["#b5542f", "#a8482a", "#c0643a"]]], "fh": 3.4, "st": [2, 3],
			"fix": true, "ch": 0.0, "eq": 0.2, "g": [["shop", 3], ["signage", 1]],
			"gc": ["#2e3b34", "#7a1a1a", "#283040", "#c8901a"], "ev": 0.5,
			"rv": {"signage": 0.4, "awning": 0.2, "balconette": 0.4, "string_course": true,
				"awning_colours": ["#2f5a46", "#7a3a2a", "#c8901a"]}},
		"apartments": {"w": [["render", SHOPHOUSE]], "p": "shophouse", "wn": "french", "bay": 2.4,
			"fr": "#f4f1ea", "sh": SHUTTERS, "sp": 0.9, "rl": 0.4, "r": [["gabled", 3], ["hipped", 1]],
			"pitch": 0.6, "rf": [["terracotta", ["#b5542f", "#a8482a"]]], "fh": 3.4, "st": [2, 4],
			"fix": true, "g": [["shop", 2], ["none", 1]], "ev": 0.5,
			"rv": {"signage": 0.25, "balconette": 0.4, "string_course": true}},
		"house": {"w": [["render", SHOPHOUSE]], "p": "shophouse", "wn": "french", "bay": 2.4,
			"sh": SHUTTERS, "sp": 0.9, "r": [["gabled", 1]], "pitch": 0.6,
			"rf": [["terracotta", ["#b5542f", "#a8482a"]]], "fh": 3.4, "st": [2, 3], "fix": true,
			"ev": 0.5, "rv": {"string_course": true, "balconette": 0.3}},
	},
	"sg_tower": {
		"apartments": {"w": [["glass", []], ["render", ["#f0f0ec", "#e0e4e8"]], ["concrete", ["#d8d4cc"]]],
			"p": [["balcony", 2], ["curtain", 2], ["strip", 1]], "wn": "wide", "bay": 3.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1, "st": [25, 50], "fix": true,
			"eq": 0.8, "g": [["none", 1]], "rv": {"deep_balcony": 0.35}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "bay": 3.0, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 4.0, "st": [20, 60], "fix": true, "eq": 0.9,
			"g": [["shop", 1]], "rv": {}},
		"civic": {"w": [["concrete", ["#d8d4cc"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "rv": {}},
	},
}
