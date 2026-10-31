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
## INFILL_MIX, documented in docs/architecture-styles.md.
const BASE := {"mountain_lodge": "north_america"}

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
}
