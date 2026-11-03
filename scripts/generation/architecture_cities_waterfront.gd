class_name ArchitectureCitiesWaterfront
extends RefCounted

## Waterfront capitals with a look of their own: Venice (pastel stucco
## palazzi and tall shuttered windows over a canal city's terracotta
## roofs) and Stockholm (Gamla stan ochre, rust and cream plaster under
## copper-green and slate roofs). Zones live in CityStyles; same key
## legend as ArchitectureData, documented in docs/architecture-styles.md.
## Rows only override what differs from the country row they inherit.

## Faded lagoon stucco: salmon, ochre, rust, pink, cream.
const VENETIAN := ["#d89a78", "#c8844f", "#b86a4a", "#e0b4a0", "#d8b878", "#e6d2a8", "#c98a6a", "#dcc59a"]
const ISTRIAN := ["#e8e2d2", "#ddd5c0", "#d4ccb8"]
const VENETIAN_ROOF := ["#8f5b47", "#85503d", "#9b6349", "#7a4b3b", "#a27258"]
const VENETIAN_SHUTTER := ["#3f5a3a", "#4a5f3e", "#2f4a3a", "#5a3a2a"]

## Gamla stan plaster and the Östermalm / Södermalm blocks around it.
const STOCKHOLM_PLASTER := ["#c7a365", "#bd8d5b", "#a76c59", "#d0bf91", "#ddd3b4", "#985e4e", "#c4a783", "#d8c9ac"]
const STOCKHOLM_PALE := ["#e8d9a8", "#e2cf98", "#efe6c8", "#d9c28a", "#ead5b0"]
const COPPER := ["#6f9a86", "#5f8a76", "#7aa592"]
const STOCKHOLM_ROOF := [["sheet_metal", ["#403f3e", "#5a5a58", "#854d40"]]]

const BASE := {
	"venice": "mediterranean", "venice_modern": "venice",
	"stockholm": "nordic", "stockholm_modern": "stockholm",
	"stockholm_medieval": "stockholm", "stockholm_wood": "stockholm", "stockholm_stone": "stockholm",
	"stockholm_grace": "stockholm", "stockholm_funkis": "stockholm", "stockholm_miljon": "stockholm_modern",
	"stockholm_eco": "stockholm_modern",
}

const REGIONS := {
	# Canal-front palazzi and townhouses: 3 to 4 storeys of tinted stucco,
	# tall french windows, terracotta pitched roofs with many chimneys.
	"venice": {
		"apartments": {"w": [["render", VENETIAN], ["stone", ISTRIAN]], "p": [["ornate", 3], ["punched", 3]],
			"wn": "gothic", "bay": 2.6, "fr": "#e8e2d2", "sh": VENETIAN_SHUTTER, "sp": 0.5, "rl": 0.3,
			"r": [["hipped", 3], ["gabled", 2]], "pitch": 0.45,
			"rf": [["terracotta", VENETIAN_ROOF]], "fh": 3.7, "st": [3, 4], "fix": true,
			"ch": 0.65, "dm": 0.0, "eq": 0.1, "g": [["render", 3], ["shop", 2], ["none", 1]],
			"gc": ["#2e3b34", "#5a2a1a", "#283040"], "ev": 0.35,
			"rv": {"balconette": 0.3, "string_course": true, "awning": 0.2, "chimney_cap": "bell", "altana": 0.3,
				"awning_colours": ["#e8e4da", "#2a4a3a", "#8a2a1a"]}},
		"house": {"w": [["render", VENETIAN]], "p": "punched", "wn": "gothic", "bay": 2.6,
			"fr": "#e8e2d2", "sh": VENETIAN_SHUTTER, "sp": 0.7,
			"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.45,
			"rf": [["terracotta", VENETIAN_ROOF]], "fh": 3.3, "st": [2, 3], "fix": true,
			"ch": 0.7, "ev": 0.35, "rv": {"string_course": true, "chimney_cap": "bell", "altana": 0.35}},
		"commercial": {"w": [["render", VENETIAN], ["stone", ISTRIAN]], "p": [["ornate", 2], ["punched", 2]],
			"wn": "gothic", "bay": 2.8, "fr": "#e8e2d2", "sh": VENETIAN_SHUTTER, "sp": 0.4,
			"r": [["hipped", 2], ["flat", 1]], "pitch": 0.45,
			"rf": [["terracotta", VENETIAN_ROOF]], "fh": 3.7, "st": [3, 4], "fix": true,
			"ch": 0.4, "g": [["shop", 3], ["render", 1]], "ev": 0.35,
			"rv": {"string_course": true, "awning": 0.4, "chimney_cap": "bell", "altana": 0.2,
				"awning_colours": ["#e8e4da", "#2a4a3a", "#8a2a1a", "#c8a24a"]}},
		"civic": {"w": [["stone", ISTRIAN], ["render", VENETIAN]], "p": "ornate", "wn": "gothic",
			"r": [["hipped", 2], ["gabled", 1]], "pitch": 0.5,
			"rf": [["terracotta", VENETIAN_ROOF]], "st": [3, 4], "fix": true, "fh": 4.2,
			"rv": {"string_course": true, "quoins": true}},
		"religious": {"w": [["stone", ISTRIAN], ["render", ["#e0d2b0", "#d8c8a0"]]], "p": "punched",
			"r": [["gabled", 2], ["hipped", 1]], "pitch": 0.55,
			"rf": [["terracotta", VENETIAN_ROOF], ["slate", ["#8a8f90", "#7a8082"]]], "tw": "bell"},
	},
	# Old-town blocks (Gamla stan, Södermalm, Östermalm): 4-5 storeys of
	# ochre / rust / cream plaster with copper, slate or tile pitched roofs
	# and a stone-faced ground floor.
	"stockholm": {
		"apartments": {"w": [["render", STOCKHOLM_PLASTER], ["render", STOCKHOLM_PALE]],
			"p": [["punched", 5], ["balcony", 1]], "wn": "casement", "bay": 2.9,
			"fr": "#efece4", "sh": "#efece4", "sp": 0.0, "rl": 0.15,
			"r": [["gabled", 3], ["hipped", 2], ["mansard", 1]], "pitch": 0.75,
			"rf": STOCKHOLM_ROOF, "fh": 3.2, "st": [4, 6], "fix": true,
			"ch": 0.45, "dm": 0.1, "eq": 0.1, "g": [["render", 2], ["shop", 2], ["none", 1]],
			"gc": ["#2e3b34", "#4a1c22", "#283040", "#4a3a2a"], "ev": 0.3,
			"rv": {"balconette": 0.3, "string_course": true, "quoins": true, "awning": 0.15}},
		"house": {"w": [["render", STOCKHOLM_PLASTER], ["wood", ["#a8442f", "#c8873a", "#d9c28a", "#b5523b"]]],
			"p": "punched", "wn": "casement", "fr": "#efece4", "sp": 0.0,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.9,
			"rf": STOCKHOLM_ROOF,
			"fh": 2.9, "st": [1, 2], "ch": 0.5, "ev": 0.45},
		"commercial": {"w": [["render", STOCKHOLM_PALE], ["stone", ["#c8c0ae", "#bdb5a2"]], ["glass", []]],
			"p": [["punched", 3], ["strip", 1]], "wn": "casement", "bay": 3.2,
			"r": [["hipped", 2], ["flat", 2]], "pitch": 0.6, "rf": STOCKHOLM_ROOF,
			"fh": 3.6, "st": [3, 5], "fix": true, "g": [["shop", 3], ["render", 1]], "ev": 0.3,
			"rv": {"string_course": true, "awning": 0.2}},
		"civic": {"w": [["render", STOCKHOLM_PLASTER], ["stone", ["#c8c0ae", "#bdb5a2"]]],
			"p": "punched", "wn": "casement", "r": [["hipped", 3], ["mansard", 1]], "pitch": 0.65,
			"rf": [["copper", COPPER], ["sheet_metal", ["#5a4a44", "#4a4a50"]]],
			"fh": 4.0, "st": [3, 5], "fix": true, "rv": {"string_course": true, "quoins": true}},
		"religious": {"w": [["stone", ["#c8c0ae", "#d8cfbc"]], ["render", STOCKHOLM_PALE]], "p": "punched",
			"r": [["gabled", 2]], "pitch": 1.1, "rf": [["copper", COPPER]], "tw": "spire"},
	},	# Post-war blocks on the lagoon edge (Santa Marta, Tronchetto).
	"venice_modern": {
		"apartments": {"w": [["render", ["#d8d0bc", "#cfc4a8", "#c8b8a0"]], ["concrete", ArchitectureData.CONCRETE]],
			"p": [["punched", 3], ["strip", 1]], "r": [["flat", 3], ["hipped", 1]], "pitch": 0.35,
			"rf": [["membrane", []], ["terracotta", VENETIAN_ROOF]], "st": [4, 6], "ch": 0.1, "eq": 0.3},
		"commercial": {"w": [["concrete", ArchitectureData.CONCRETE], ["glass", []]],
			"p": [["strip", 2], ["curtain", 1]], "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [2, 4], "ch": 0.0, "eq": 0.5, "g": [["shop", 1]]},
		"civic": {"w": [["concrete", ArchitectureData.CONCRETE], ["render", ISTRIAN]], "p": "strip",
			"r": [["flat", 2], ["hipped", 1]], "rf": [["membrane", []]], "st": [2, 4]},
	},
	# Distinct district fabrics; inherited fields retain the city defaults.
	"stockholm_medieval": {
		"apartments": {"w": [["render", STOCKHOLM_PLASTER]], "p": "punched", "bay": 2.5,
			"r": [["gabled", 4], ["hipped", 1]], "pitch": 1.1, "rf": STOCKHOLM_ROOF,
			"st": [3, 5], "fix": true, "rv": {"gable": [["step", 2], ["bell", 1]], "string_course": true, "wall_lantern": 0.4}},
		"commercial": {"w": [["render", STOCKHOLM_PLASTER]], "r": [["gabled", 1]], "pitch": 1.1,
			"rf": STOCKHOLM_ROOF, "st": [3, 5], "fix": true,
			"rv": {"gable": [["step", 2], ["bell", 1]], "string_course": true, "wall_lantern": 0.4}},
	},
	"stockholm_wood": {
		"house": {"w": [["wood", ["#8c4739", "#a35e49", "#c1a16c"]]], "p": "clapboard",
			"r": [["gabled", 1]], "pitch": 0.8, "rf": STOCKHOLM_ROOF, "st": [1, 2], "fix": true},
		"apartments": {"w": [["wood", ["#8c4739", "#a35e49", "#c1a16c"]]], "p": "clapboard",
			"r": [["gabled", 1]], "pitch": 0.8, "rf": STOCKHOLM_ROOF, "st": [1, 2], "fix": true},
	},
	"stockholm_stone": {
		"apartments": {"w": [["render", STOCKHOLM_PALE], ["stone", ["#c8c0ae", "#bdb5a2"]]],
			"p": "ornate", "r": [["hipped", 3], ["mansard", 1]], "rf": STOCKHOLM_ROOF,
			"st": [4, 6], "fix": true, "g": [["stone", 2], ["shop", 1]],
			"rv": {"oriel": 0.3, "corner_dome": 0.35, "granite_plinth": true, "string_course": true}},
	},
	"stockholm_grace": {
		"apartments": {"w": [["render", STOCKHOLM_PALE]], "p": "punched", "r": [["hipped", 3], ["gabled", 1]],
			"pitch": 0.6, "rf": STOCKHOLM_ROOF, "st": [4, 6], "fix": true, "rv": {"string_course": true}},
	},
	"stockholm_funkis": {
		"apartments": {"w": [["render", ["#e6e2d7", "#d9d7ca", "#e5ddcb"]]],
			"p": [["punched", 2], ["balcony", 1]], "wn": "wide", "r": [["flat", 3], ["hipped", 1]],
			"rf": [["membrane", []], ["sheet_metal", ["#484a49"]]], "st": [3, 6], "fix": true,
			"rv": {"deep_balcony": 0.3}},
	},
	"stockholm_miljon": {
		"apartments": {"w": [["concrete", ["#c6c1b7", "#d1cdc3", "#bdbab0"]]], "p": "panel", "wn": "wide",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 9], "fix": true,
			"rv": {"glazed_balcony": 0.5}},
	},
	"stockholm_eco": {
		"apartments": {"w": [["render", ["#e7e5dc", "#d9d9d2"]], ["wood", ["#af9479"]], ["glass", []]],
			"p": [["punched", 2], ["balcony", 2]], "wn": "wide", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 8], "fix": true,
			"rv": {"deep_balcony": 0.6, "glazed_balcony": 0.5}},
	},
	# Million Programme slabs and glass offices (Hammarby, Kista, Norrmalm).
	"stockholm_modern": {
		"apartments": {"w": [["render", ["#d8d0bc", "#c8bca8", "#b8a890", "#a8442f"]], ["concrete", ArchitectureData.CONCRETE]],
			"p": [["punched", 3], ["balcony", 2]], "r": [["flat", 4], ["gabled", 1]], "pitch": 0.4,
			"rf": [["membrane", []]], "st": [4, 8], "ch": 0.1, "eq": 0.35, "ev": 0.2},
		"commercial": {"w": [["glass", []], ["concrete", ArchitectureData.CONCRETE]],
			"p": [["curtain", 2], ["strip", 2]], "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [4, 10], "ch": 0.0, "eq": 0.6, "g": [["shop", 1]]},
		"civic": {"w": [["concrete", ArchitectureData.CONCRETE], ["glass", []]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 5]},
	},
}
