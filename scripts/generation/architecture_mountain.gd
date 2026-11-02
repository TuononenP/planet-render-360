class_name ArchitectureMountain
extends RefCounted

## Mountain and wild-coast town style ("mountain_lodge"): the Canadian
## Rockies (Banff, Canmore, Jasper), Whistler, the Sierra / Rocky
## Mountain resorts (Tahoe, Aspen, Jackson) and Big Sur. These read as
## timber and fieldstone lodges under steep, wide-eaved roofs of dark
## green, brown or charcoal metal, not as the red-brick `north_america`
## suburbs the country box would give them. Inherits unlisted kinds
## (industrial, ...) from north_america. Same key legend as
## ArchitectureData; boxes live in ArchitectureData.BOXES, kind mix in
## INFILL_MIX, documented in docs/architecture-styles.md. Banff town
## has its own city zone (CityStyles) and era rows below.
const BASE := {"mountain_lodge": "north_america", "banff": "mountain_lodge",
	"banff_heritage": "banff", "banff_house": "banff"}

## Cedar and weathered log browns; stained greys for newer cladding.
const TIMBER := ["#8a6a48", "#7a5a3a", "#6b4a2f", "#a08060", "#5e4632", "#8c7a68"]
## Standing-seam metal: forest green, charcoal, barn brown, rust.
const METAL := [["slate", ["#3d5a48", "#445a4a", "#35503f"]],
	["slate", ["#4a4f4d", "#40454a"]], ["slate", ["#5a4636", "#664d3a"]],
	["slate", ["#7a3f2e"]]]
## Grey fieldstone (the stone photo is a sandstone block; untinted it reads
## as tan brick). Listed once beside two timber entries so wood dominates.
const FIELDSTONE := ["#9a948a", "#8a857c", "#a39d92"]
## Stained cladding greys and browns.
const STAIN := ["#6a6258", "#5a5048", "#7a6e60", "#4e4a44"]
## Banff-style earth tones for stucco and painted fronts.
const EARTH := ["#d8c8a8", "#cdb894", "#c2ae8c", "#b9a98a", "#d4c0a0"]
## Rundle stone (the grey local limestone of the Banff Springs and the
## Park Administration Building) and the verdigris copper roofs over it.
const RUNDLE := ["#8e8a84", "#9a958c", "#7f7b75", "#a39e94"]
const VERDIGRIS := [["slate", ["#5f8f7f", "#6a9a88", "#57867a"]]]
const REGIONS := {
	"mountain_lodge": {
		"house": {"w": [["wood", TIMBER], ["wood", STAIN], ["stone", FIELDSTONE]],
			"p": "clapboard", "bay": 3.0, "fr": "#efe6d2",
			"sh": ["#3f5f3a", "#4a3a2a", "#2f3a2a"], "sp": 0.3, "wn": "small",
			"r": [["gabled", 6], ["half-hipped", 1]], "pitch": 0.95,
			"rf": METAL, "fh": 2.9, "st": [1, 2], "ch": 0.7, "dm": 0.5,
			"ev": 0.9, "rv": {"deep_balcony": 0.3}},
		# Hotels, lodges and condos: 2-4 storeys of timber and stone.
		"apartments": {"w": [["wood", TIMBER], ["wood", STAIN], ["render", EARTH], ["stone", FIELDSTONE]],
			"p": [["punched", 3], ["balcony", 3]], "bay": 3.0, "fr": "#efe6d2",
			"sh": ["#3f5f3a", "#4a3a2a"], "sp": 0.3, "wn": "small", "rl": 0.2,
			"r": [["gabled", 5], ["hipped", 1]], "pitch": 0.9,
			"rf": METAL, "fh": 3.0, "st": [2, 4], "fix": true, "ch": 0.5, "dm": 0.5,
			"eq": 0.05, "g": [["none", 2], ["shop", 1]], "ev": 0.9,
			"rv": {"deep_balcony": 0.5, "balconette": 0.1}},
		# Main-street fronts: timber, stone and stucco, one to three storeys.
		"commercial": {"w": [["wood", TIMBER], ["wood", STAIN], ["render", EARTH], ["stone", FIELDSTONE]],
			"p": [["punched", 3], ["clapboard", 2]], "bay": 3.2, "fr": "#efe6d2",
			"sh": ["#3f5f3a", "#4a3a2a"], "sp": 0.2, "wn": "small",
			"r": [["gabled", 4], ["flat", 1]], "pitch": 0.85,
			"rf": METAL, "fh": 3.4, "st": [1, 3], "fix": true, "ch": 0.2, "dm": 0.3,
			"eq": 0.2, "g": [["shop", 3], ["none", 1]], "gc": ["#2e3b34", "#4a3a2a", "#283428"],
			"ev": 0.7, "rv": {"awning": 0.3, "awning_colours": ["#2e3b34", "#7a1f24", "#4a3a2a"]}},
		"civic": {"w": [["stone", FIELDSTONE], ["wood", TIMBER]], "p": "punched", "bay": 3.4,
			"fr": "#efe6d2", "sp": 0.0, "wn": "small",
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.8, "rf": METAL,
			"st": [1, 2], "ch": 0.3, "dm": 0.2, "ev": 0.8},
		"religious": {"w": [["wood", ["#e8e2d4", "#d8cfbc", "#8a6a48"]], ["stone", FIELDSTONE]],
			"p": "clapboard", "r": [["gabled", 1]], "pitch": 1.4,
			"rf": METAL, "tw": "spire", "ev": 0.5},
		"farm": {"w": [["wood", ["#6b4a2f", "#5e4632", "#7a5a3a"]]], "p": "clapboard",
			"r": [["gabled", 3], ["gambrel", 1]], "pitch": 0.8, "rf": METAL, "ev": 0.6},
		"outbuilding": {"w": [["wood", TIMBER]], "p": "clapboard",
			"r": [["gabled", 3], ["skillion", 1]], "pitch": 0.7, "rf": METAL},
	},
	# Banff Avenue: two- and three-storey fronts of log, river rock and
	# Rundle stone under steep gables, signage and awnings over the shops.
	"banff": {
		"commercial": {"w": [["wood", TIMBER], ["stone", RUNDLE], ["wood", STAIN], ["stone", FIELDSTONE]],
			"p": [["punched", 3], ["clapboard", 1]], "bay": 3.0, "fr": "#efe6d2",
			"sh": ["#3f5f3a", "#4a3a2a"], "sp": 0.2, "wn": "small",
			"r": [["gabled", 5], ["hipped", 1]], "pitch": 0.95,
			"rf": METAL, "fh": 3.4, "st": [2, 3], "fix": true, "ch": 0.3, "dm": 0.5,
			"eq": 0.1, "g": [["shop", 3], ["stone", 1]], "gc": ["#2e3b34", "#4a3a2a", "#283428", "#7a1f24"],
			"ev": 0.8, "rv": {"awning": 0.35, "signage": 0.3,
				"awning_colours": ["#2e3b34", "#7a1f24", "#4a3a2a"]}},
		"apartments": {"w": [["wood", TIMBER], ["stone", RUNDLE], ["render", EARTH]],
			"p": [["balcony", 3], ["punched", 2]], "bay": 3.0, "fr": "#efe6d2",
			"sh": ["#3f5f3a", "#4a3a2a"], "sp": 0.3, "wn": "small",
			"r": [["gabled", 5], ["hipped", 1]], "pitch": 0.95, "rf": METAL,
			"fh": 3.0, "st": [2, 4], "fix": true, "ch": 0.4, "dm": 0.6, "ev": 1.0,
			"rv": {"deep_balcony": 0.6}},
	},
	# Heritage stone (1886–1940: the Banff Springs, Cave and Basin, the Park
	# Administration Building): Rundle stone walls, steep verdigris copper
	# roofs with dormers.
	"banff_heritage": {
		"commercial": {"w": [["stone", RUNDLE]], "p": "punched", "bay": 3.0, "fr": "#efe6d2",
			"sp": 0.0, "wn": "casement", "r": [["hipped", 3], ["gabled", 2]], "pitch": 1.2,
			"rf": VERDIGRIS, "fh": 3.4, "st": [2, 5], "fix": true, "ch": 0.6, "dm": 0.8,
			"g": [["stone", 1]], "ev": 0.4, "rv": {"string_course": true}},
		"civic": {"w": [["stone", RUNDLE]], "p": "punched", "bay": 3.0, "fr": "#efe6d2", "sp": 0.0,
			"wn": "casement", "r": [["hipped", 2], ["gabled", 1]], "pitch": 1.1, "rf": VERDIGRIS,
			"st": [2, 3], "fix": true, "ch": 0.5, "dm": 0.6, "ev": 0.4, "rv": {"string_course": true}},
		"apartments": {"w": [["stone", RUNDLE], ["wood", TIMBER]], "p": "punched", "bay": 3.0,
			"fr": "#efe6d2", "wn": "casement", "r": [["gabled", 2], ["hipped", 1]], "pitch": 1.1,
			"rf": VERDIGRIS, "st": [2, 4], "fix": true, "dm": 0.6, "ev": 0.5, "rv": {}},
	},
	# Timber cottages on the residential grid: clapboard, steep gables,
	# porches, one and a half storeys.
	"banff_house": {
		"house": {"w": [["wood", TIMBER], ["wood", ["#e8e2d4", "#d8cfbc", "#c8b89a", "#7a8a7a"]]],
			"p": "clapboard", "bay": 2.8, "fr": "#efe6d2", "sh": ["#3f5f3a", "#4a3a2a", "#7a1f24"],
			"sp": 0.4, "wn": "small", "r": [["gabled", 6], ["hipped", 1]], "pitch": 1.0,
			"rf": METAL, "fh": 2.8, "st": [1, 2], "fix": true, "ch": 0.7, "dm": 0.6, "ev": 0.7,
			"rv": {"deep_balcony": 0.2}},
	},
}
