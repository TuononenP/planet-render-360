class_name ArchitectureParis
extends RefCounted

## Paris era rows (BuildingEra picks one per building; all inherit from
## the "haussmann" city row in ArchitectureRegions, then france).
## Same key legend as ArchitectureData. `rv` is the 3D relief schema
## (docs/architecture-styles.md); a row's rv replaces its parent's.

## Zinc / slate mansard family (PRD §4.2, #46525E).
const ZINC := ["#46525e", "#4f5b66", "#56616b", "#4a5560"]
## Haussmann limestone (around PRD #D6C5A3). Post-Haussmann rows use the
## same palette, bay and pattern so both eras share facade materials
## (they differ in relief and storeys): the per-place budget (T7.2).
const STONE := ["#d6c5a3", "#dccbaa", "#cfbf9e"]
## Café awnings: oxblood, bottle green, mustard, navy, brick red.
const CAFE := ["#7a1f24", "#1f3b2c", "#c8a24a", "#2a2f4a", "#8a2a1a"]

const BASE := {
	"paris_post_haussmann": "haussmann", "paris_faubourg": "haussmann",
	"paris_hbm": "haussmann", "paris_modern": "haussmann", "paris_pavillon": "haussmann",
}

const REGIONS := {
	# Belle Époque (1895–1914): taller (the 1902 code
	# allowed bow windows and higher rooflines), more balconies.
	"paris_post_haussmann": {
		"apartments": {"w": [["limestone", STONE]], "p": "haussmann",
			"bay": 2.4, "r": [["mansard", 1]], "pitch": 1.1, "rf": [["slate", ZINC]],
			"fh": 3.2, "st": [6, 8], "fix": true, "ch": 0.8, "dm": 1.0, "eq": 0.0, "g": [], "ev": 0.0,
			"rv": {"balcony_rows": [2, 5, 6], "balconette": 0.75, "oriel": 0.35,
				"string_course": true, "awning": 0.45, "awning_colours": CAFE}},
		"commercial": {"w": [["limestone", STONE]], "p": "haussmann", "bay": 2.4,
			"r": [["mansard", 1]], "rf": [["slate", ZINC]], "fh": 3.3, "st": [5, 7], "fix": true,
			"ch": 0.6, "dm": 1.0, "eq": 0.1, "g": [], "ev": 0.0,
			"rv": {"balcony_rows": [2, 5], "balconette": 0.7, "oriel": 0.3,
				"string_course": true, "awning": 0.6, "awning_colours": CAFE}},
	},
	# Pre-1850 faubourg / Marais houses: rendered walls, shutters, steep
	# tiled or slate roofs with dormers, narrow bays, low storeys.
	"paris_faubourg": {
		"apartments": {"w": [["render", ["#e8dcc4", "#e2d2b4", "#d9c7a4", "#ebe3d2", "#d8c0a0"]],
				["limestone", ["#e0d0b0", "#d8c8a8"]]],
			"p": "punched", "wn": "french", "bay": 2.0, "fr": "#f1ede4",
			"sh": ["#6b7a72", "#8a8f88", "#5b6b5f", "#7a6a58"], "sp": 0.7, "rl": 0.25,
			"r": [["gabled", 3], ["mansard", 2], ["hipped", 1]], "pitch": 1.25,
			"rf": [["slate", ZINC], ["terracotta", ["#9a4a2c", "#a8552f", "#8a4030"]]],
			"fh": 2.8, "st": [3, 5], "fix": true, "ch": 0.9, "dm": 0.7, "eq": 0.0,
			"g": [["shop", 3], ["none", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.15,
			"rv": {"balconette": 0.25, "string_course": true, "awning": 0.3,
				"awning_colours": CAFE}},
		"commercial": {"w": [["render", ["#e8dcc4", "#e2d2b4", "#d9c7a4"]]], "p": "punched",
			"wn": "french", "bay": 2.0, "sh": ["#6b7a72", "#5b6b5f"], "sp": 0.6, "rl": 0.2,
			"r": [["gabled", 2], ["mansard", 1]], "pitch": 1.2, "rf": [["slate", ZINC]],
			"fh": 2.9, "st": [3, 5], "fix": true, "ch": 0.8, "dm": 0.6,
			"g": [["shop", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.15,
			"rv": {"balconette": 0.2, "string_course": true, "awning": 0.55,
				"awning_colours": CAFE}},
		"house": {"w": [["render", ["#e8dcc4", "#e2d2b4", "#d9c7a4"]], ["stone", ["#c8b08a", "#bfa27a"]]],
			"p": "punched", "wn": "french", "bay": 2.2, "sh": ["#6b7a72", "#7a6a58"], "sp": 0.8,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 1.3,
			"rf": [["terracotta", ["#9a4a2c", "#a8552f"]], ["slate", ZINC]],
			"fh": 2.7, "st": [2, 3], "fix": true, "ch": 0.9, "dm": 0.6, "ev": 0.25,
			"rv": {"string_course": false, "quoins": true}},
	},
	# HBM ring (1919–1939, by the Périphérique): red / ochre brick, bow
	# windows, brick string courses, flat or low roofs.
	"paris_hbm": {
		"apartments": {"w": [["brick", ["#a8553a", "#b8683f", "#c27a4a", "#9a4a33", "#b8865a"]]],
			"p": [["punched", 3], ["ornate", 2]], "wn": "casement", "bay": 2.8, "fr": "#f1ede4",
			"sh": "#5b6b4f", "sp": 0.0, "rl": 0.1,
			"r": [["flat", 3], ["hipped", 1]], "pitch": 0.5,
			"rf": [["membrane", []], ["terracotta", ["#9a4a2c", "#8a4030"]]],
			"fh": 2.8, "st": [6, 8], "fix": true, "ch": 0.3, "dm": 0.1, "eq": 0.2,
			"g": [["none", 3], ["shop", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.2,
			"rv": {"deep_balcony": 0.15, "oriel": 0.25, "string_course": true,
				"awning": 0.1, "awning_colours": CAFE}},
	},
	# Post-war Paris (1950+): concrete / glass slabs and towers, ribbon or
	# panel windows, deep balconies, flat roofs (Front de Seine, 13e).
	"paris_modern": {
		"apartments": {"w": [["concrete", ["#c8c4bc", "#b8b4ac", "#d8d4cc"]],
				["render", ["#ecebe6", "#e0ddd6"]]],
			"p": [["balcony", 3], ["strip", 2], ["panel", 2]], "wn": "wide", "bay": 3.0,
			"fr": "#5a5e62", "sh": "#5a5e62", "sp": 0.0, "rl": 0.0,
			"r": [["flat", 1]], "pitch": 1.0, "rf": [["membrane", []]],
			"fh": 2.8, "st": [8, 16], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.6,
			"g": [["none", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.55, "awning": 0.15, "awning_colours": CAFE}},
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc", "#b8b4ac"]]],
			"p": [["strip", 2], ["curtain", 1]], "bay": 3.2, "fr": "#3a3d42",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [6, 20], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.8, "g": [["shop", 1]], "ev": 0.0, "rv": {}},
		"civic": {"w": [["concrete", ["#c8c4bc", "#d8d4cc"]], ["glass", []]], "p": "strip",
			"bay": 3.4, "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 6], "fix": true,
			"ch": 0.0, "dm": 0.0, "g": [["none", 1]], "ev": 0.0, "rv": {}},
		"house": {"w": [["render", ["#ecebe6", "#e0ddd6"]], ["concrete", ["#c8c4bc"]]],
			"p": "strip", "r": [["flat", 2], ["skillion", 1]], "rf": [["membrane", []]],
			"st": [2, 3], "fix": true, "ch": 0.0, "dm": 0.0, "ev": 0.2, "rv": {}},
	},
	# Pavillons (outer arrondissements / petite couronne): millstone
	# (meulière) or render with brick quoins, tiled roofs.
	"paris_pavillon": {
		"house": {"w": [["stone", ["#c8b08a", "#bfa27a", "#d0bc98"]], ["render", ["#e8dcc4", "#efe6d4"]]],
			"p": "punched", "wn": "french", "bay": 2.6, "fr": "#f1ede4",
			"sh": ["#7a8a9a", "#5b6b4f", "#8a7a68"], "sp": 0.6,
			"r": [["gabled", 3], ["hipped", 3]], "pitch": 1.2,
			"rf": [["terracotta", ["#a8482a", "#b5542f", "#9a4a2c"]], ["slate", ArchitectureData.SLATE]],
			"fh": 2.9, "st": [2, 3], "fix": true, "ch": 0.8, "dm": 0.3, "ev": 0.4,
			"rv": {"balconette": 0.1, "quoins": true}},
	},
}
