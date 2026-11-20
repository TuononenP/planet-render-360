class_name ArchitectureCitiesWaterfront
extends RefCounted

## Waterfront capitals with a look of their own: Venice (pastel stucco
## palazzi and tall shuttered windows over a canal city's terracotta
## roofs) and Stockholm (Gamla stan ochre, rust and cream plaster under
## painted sheet metal, plus its district fabrics). Zones live in CityStyles; same key
## legend as ArchitectureData, documented in docs/architecture-styles.md.
## Rows only override what differs from the country row they inherit.

## Faded lagoon stucco: salmon, ochre, rust, pink, cream.
const VENETIAN := ["#d89a78", "#c8844f", "#b86a4a", "#e0b4a0", "#d8b878", "#e6d2a8", "#c98a6a", "#dcc59a"]
const ISTRIAN := ["#e8e2d2", "#ddd5c0", "#d4ccb8"]
const VENETIAN_ROOF := ["#8f5b47", "#85503d", "#9b6349", "#7a4b3b", "#a27258"]
const VENETIAN_SHUTTER := ["#3f5a3a", "#4a5f3e", "#2f4a3a", "#5a3a2a"]

## Gamla stan plaster and the Östermalm / Södermalm blocks around it.
## Walls in shade take the cool sky light (the shared lighting is blue-grey there): any plaster that
## leans yellow or green multiplied by it turns olive, one that leans red or orange stays warm. So every
## plaster here is orange ochre, ochre, terracotta, rust (a minority), peach or warm cream; the pale yellows and the
## grey-green render read as dark green-grey walls in shade and are left out.
const STOCKHOLM_PLASTER := ["#e0a45a", "#dcb066", "#d08a52", "#c4684f", "#ead0a4", "#e6c890", "#d9a07a", "#c98a5a"]
const STOCKHOLM_PALE := ["#ecd2b0", "#e8c9a0", "#eed8bc", "#e6c48a", "#e8cc9c"]
const COPPER := ["#6f9a86", "#5f8a76", "#7aa592"]
const STOCKHOLM_ROOF := [["sheet_metal", ["#403f3e", "#5a5a58", "#854d40"]]]
## Gamla stan roofscape: black and dark-grey painted sheet metal with
## red-painted (rödfärg) roofs among them.
const GAMLA_ROOF := [["sheet_metal", ["#2c2b2a", "#3a3938", "#4c4b49", "#7a3a2e", "#8a4434"]]]
## Painted villa and lamella render: pale yellow, cream, off-white, grey.
const STOCKHOLM_VILLA := ["#ecd2b0", "#eed8bc", "#ddc8b0", "#e0b98f", "#e4ded4", "#d8cfc4"]
## 1950s-60s Klara: pale stone cladding, dark granite, light concrete.
const KLARA_STONE := ["#cfc8b8", "#bdb6a6", "#8e8b85", "#d8d2c4"]

## Paint weight of Stockholm's plaster and boarding (WallVariety): the palette carries the colours, the
## per-building family only nudges them. Full weight stacked ochre on ochre into a dark mustard.
const STOCKHOLM_PAINT := 0.35

const BASE := {
	"venice": "mediterranean", "venice_modern": "venice",
	"stockholm": "nordic", "stockholm_modern": "stockholm",
	"stockholm_medieval": "stockholm", "stockholm_wood": "stockholm", "stockholm_stone": "stockholm",
	"stockholm_grace": "stockholm", "stockholm_funkis": "stockholm", "stockholm_miljon": "stockholm_modern",
	"stockholm_eco": "stockholm_modern", "stockholm_stenstad": "stockholm",
	"stockholm_postwar": "stockholm_modern", "stockholm_villa": "stockholm",
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
		"apartments": {"vt": STOCKHOLM_PAINT, "w": [["render", STOCKHOLM_PLASTER], ["render", STOCKHOLM_PALE]],
			"p": [["punched", 5], ["balcony", 1]], "wn": "casement", "bay": 2.9,
			"fr": "#efece4", "sh": "#efece4", "sp": 0.0, "rl": 0.15,
			"r": [["gabled", 3], ["hipped", 2], ["mansard", 1]], "pitch": 0.75,
			"rf": STOCKHOLM_ROOF, "fh": 3.2, "st": [4, 6], "fix": true,
			"ch": 0.45, "dm": 0.1, "eq": 0.1, "g": [["render", 2], ["shop", 2], ["none", 1]],
			"gc": ["#2e3b34", "#4a1c22", "#283040", "#4a3a2a"], "ev": 0.3,
			"rv": {"balconette": 0.3, "string_course": true, "quoins": true, "awning": 0.15}},
		"house": {"vt": STOCKHOLM_PAINT, "w": [["render", STOCKHOLM_PALE], ["wood", ["#d88f5a", "#e8cfa8", "#efe6dc", "#c8873a", "#a8442f"]]],
			"p": "punched", "wn": "casement", "fr": "#efece4", "sp": 0.0,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.9,
			"rf": STOCKHOLM_ROOF,
			"fh": 2.9, "st": [1, 2], "ch": 0.5, "ev": 0.45},
		"commercial": {"vt": STOCKHOLM_PAINT, "w": [["render", STOCKHOLM_PALE], ["stone", ["#c8c0ae", "#bdb5a2"]], ["glass", []]],
			"p": [["punched", 3], ["strip", 1]], "wn": "casement", "bay": 3.2,
			"r": [["hipped", 2], ["flat", 2]], "pitch": 0.6, "rf": STOCKHOLM_ROOF,
			"fh": 3.6, "st": [3, 5], "fix": true, "g": [["shop", 3], ["render", 1]], "ev": 0.3,
			"rv": {"string_course": true, "awning": 0.2}},
		"civic": {"vt": STOCKHOLM_PAINT, "w": [["render", STOCKHOLM_PLASTER], ["stone", ["#c8c0ae", "#bdb5a2"]]],
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
	# Narrow plots under a varied roofscape: steep black or red-painted sheet
	# metal, gabled, hipped and half-hipped ridges at differing heights,
	# dormers and chimney stacks.
	"stockholm_medieval": {
		"apartments": {"w": [["render", STOCKHOLM_PLASTER]], "p": "punched", "bay": 2.5,
			"r": [["gabled", 5], ["hipped", 2], ["half-hipped", 1], ["mansard", 1]], "pitch": 1.1, "rf": GAMLA_ROOF,
			"st": [3, 5], "fix": true, "ch": 0.75, "dm": 0.45,
			"rv": {"gable": [["step", 2], ["bell", 1], ["", 2]], "string_course": true, "wall_lantern": 0.4}},
		"commercial": {"w": [["render", STOCKHOLM_PLASTER]], "r": [["gabled", 3], ["hipped", 1], ["half-hipped", 1]],
			"pitch": 1.1, "rf": GAMLA_ROOF, "st": [3, 5], "fix": true, "ch": 0.7, "dm": 0.4,
			"rv": {"gable": [["step", 2], ["bell", 1], ["", 2]], "string_course": true, "wall_lantern": 0.4}},
		"house": {"w": [["render", STOCKHOLM_PLASTER]], "p": "punched", "r": [["gabled", 3], ["half-hipped", 1]],
			"pitch": 1.1, "rf": GAMLA_ROOF, "st": [2, 3], "fix": true, "ch": 0.75, "dm": 0.4},
	},
	"stockholm_wood": {
		"house": {"w": [["wood", ["#8c4739", "#a35e49", "#d98a52"]]], "p": "clapboard",
			"r": [["gabled", 1]], "pitch": 0.8, "rf": STOCKHOLM_ROOF, "st": [1, 2], "fix": true},
		"apartments": {"w": [["wood", ["#8c4739", "#a35e49", "#d98a52"]]], "p": "clapboard",
			"r": [["gabled", 1]], "pitch": 0.8, "rf": STOCKHOLM_ROOF, "st": [1, 2], "fix": true},
	},
	# Östermalm and Strandvägen, 1880-1919: ornate stone and render blocks,
	# oriels and the copper corner domes.
	"stockholm_stone": {
		"apartments": {"w": [["render", STOCKHOLM_PALE], ["stone", ["#c8c0ae", "#bdb5a2"]]],
			"p": "ornate", "r": [["hipped", 3], ["mansard", 1]], "rf": STOCKHOLM_ROOF,
			"st": [4, 6], "fix": true, "g": [["stone", 2], ["shop", 1]],
			"rv": {"oriel": 0.3, "corner_dome": 0.35, "granite_plinth": true, "string_course": true}},
	},
	# Kungsholmen and Södermalm stone city, 1880-1930: rendered stone
	# blocks over a shop or granite ground floor, sheet-metal roofs, a few
	# oriels; no copper corner domes (those are Östermalm's).
	"stockholm_stenstad": {
		"apartments": {"w": [["render", STOCKHOLM_PLASTER], ["render", STOCKHOLM_PALE]],
			"p": [["punched", 4], ["ornate", 1], ["balcony", 1]], "r": [["hipped", 3], ["gabled", 2], ["mansard", 1]],
			"pitch": 0.6, "rf": STOCKHOLM_ROOF, "st": [5, 6], "fix": true, "ch": 0.45, "dm": 0.2,
			"g": [["shop", 3], ["render", 1], ["stone", 1]],
			"rv": {"oriel": 0.1, "balconette": 0.2, "granite_plinth": true, "string_course": true, "awning": 0.15}},
		"commercial": {"w": [["render", STOCKHOLM_PALE], ["stone", ["#c8c0ae", "#bdb5a2"]]],
			"p": [["punched", 3], ["ornate", 1]], "r": [["hipped", 3], ["mansard", 1]], "pitch": 0.6,
			"rf": STOCKHOLM_ROOF, "st": [4, 6], "fix": true, "g": [["shop", 3], ["stone", 1]],
			"rv": {"granite_plinth": true, "string_course": true, "awning": 0.2}},
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
	# Norrmalm / Klara 1950s-60s modernism (Hötorgscity, Sergels torg):
	# glass-and-stone commercial slabs on shop podiums, flat roofs; the
	# same post-war idiom carries rendered and brick apartment slabs.
	"stockholm_postwar": {
		"apartments": {"w": [["render", ["#e3dccb", "#d8cfb8", "#cbbfa4", "#e6e2d7"]], ["brick", ["#b8823a", "#9a5a3e", "#c49a5c"]]],
			"p": [["punched", 2], ["strip", 1], ["balcony", 1]], "wn": "wide", "r": [["flat", 4], ["hipped", 1]],
			"pitch": 0.3, "rf": [["membrane", []], ["sheet_metal", ["#484a49"]]], "st": [5, 9], "fix": true,
			"ch": 0.0, "eq": 0.4, "rv": {"glazed_balcony": 0.2}},
		"commercial": {"vt": 0.1, "w": [["glass", []], ["stone", KLARA_STONE], ["concrete", ArchitectureData.CONCRETE]],
			"p": [["curtain", 2], ["strip", 3]], "wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.6, "st": [5, 9], "fix": true, "ch": 0.0, "eq": 0.6, "g": [["shop", 3], ["stone", 1]]},
		"civic": {"vt": 0.1, "w": [["stone", KLARA_STONE], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [3, 6], "fix": true},
	},
	# Djurgården villas in parkland and the city's detached houses:
	# painted render and boarding in pale yellows, cream and grey (falu
	# red belongs to the cottage districts), hipped and gabled metal roofs.
	"stockholm_villa": {
		"house": {"w": [["render", STOCKHOLM_VILLA], ["wood", ["#ecd2b0", "#eed8bc", "#ddc8b0", "#d99a6a", "#e0a878", "#c8873a"]]], "p": "punched",
			"wn": "casement", "fr": "#efece4", "sp": 0.0, "r": [["hipped", 2], ["gabled", 2], ["mansard", 1]],
			"pitch": 0.85, "rf": [["sheet_metal", ["#403f3e", "#5a5a58", "#4a5a50"]]], "fh": 3.1, "st": [2, 3],
			"fix": true, "ch": 0.6, "dm": 0.3, "ev": 0.45},
		"apartments": {"w": [["render", STOCKHOLM_VILLA]], "p": "punched", "wn": "casement",
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.75, "rf": [["sheet_metal", ["#403f3e", "#5a5a58"]]],
			"fh": 3.1, "st": [2, 4], "fix": true, "ch": 0.5, "dm": 0.25, "ev": 0.4, "rv": {"string_course": true}},
		"commercial": {"w": [["render", STOCKHOLM_VILLA], ["wood", STOCKHOLM_VILLA]], "p": "punched",
			"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.75, "rf": [["sheet_metal", ["#403f3e", "#5a5a58"]]],
			"fh": 3.2, "st": [1, 3], "fix": true, "ch": 0.4, "ev": 0.45, "g": [["render", 1]]},
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
	# Base of the post-war rows (postwar, miljon, eco): panel and render
	# slabs and glass offices.
	"stockholm_modern": {
		"apartments": {"w": [["render", ["#d8d0bc", "#c8bca8", "#b8a890", "#a8442f"]], ["concrete", ArchitectureData.CONCRETE]],
			"p": [["punched", 3], ["balcony", 2]], "r": [["flat", 4], ["gabled", 1]], "pitch": 0.4,
			"rf": [["membrane", []]], "st": [4, 8], "ch": 0.1, "eq": 0.35, "ev": 0.2},
		"commercial": {"vt": 0.1, "w": [["glass", []], ["concrete", ArchitectureData.CONCRETE]],
			"p": [["curtain", 2], ["strip", 2]], "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [4, 10], "ch": 0.0, "eq": 0.6, "g": [["shop", 1]]},
		"civic": {"vt": 0.1, "w": [["concrete", ArchitectureData.CONCRETE], ["glass", []]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 5]},
	},
}
