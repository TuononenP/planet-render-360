class_name ArchitectureCitiesSouth
extends RefCounted

## Southern European and Bosphorus city rows (CityStyles zones) and their
## era rows (BuildingEra): Madrid, Lisbon, Milan, Florence, Istanbul,
## Athens. City rows inherit from their country row; eras from their
## city. Same key legend as ArchitectureData; `rv` = 3D relief (replaces
## the parent's). ERAS rows carry a storey band and a heritage flag
## (BuildingEra._banded) instead of hand-written rules.

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]

const TERRA := ["#b5542f", "#a8482a", "#c0643a", "#9a4a2c"]
const ZINC := [["slate", ["#5a6066", "#646a70", "#50565c"]]]
## Madrid ensanche: rose and ochre render with red brick, white
## miradores, black iron balconies; Austrias red brick and granite.
const MADRID := ["#e8c8a8", "#e0b890", "#f0dcc0", "#d8a888", "#e8d8c0", "#c8a080"]
const MADRID_BRICK := ["#a8503a", "#9a4a35", "#b8603f"]
## Lisbon: pastel render and azulejo fronts, ochre Pombaline Baixa.
const LISBON := ["#e8c060", "#f0d8a0", "#e8a890", "#a8c8d8", "#f2ede0", "#d8b0c0", "#c8d8b8"]
const POMBALINE := ["#e8c878", "#f0d8a0", "#e8d0b0"]
## Milan: ochre, grey and rose render over ceppo stone; klinker and
## brick on the rationalist blocks.
const MILAN := ["#e0c8a0", "#d8c0a8", "#c8c0b0", "#e8d0b0", "#d0b090", "#e0b8a0"]
## Florence: pietra forte, cream and ochre intonaco, green shutters.
const FLORENCE := ["#e8d8b8", "#e0c890", "#d8b880", "#efe6d2", "#d0b890", "#c8a878"]
const PIETRA_FORTE := ["#a89070", "#9a8466", "#b09878"]
## Istanbul: pastel concrete blocks, Pera stone and the painted timber
## of the old wooden houses.
const ISTANBUL := ["#e8dcc4", "#e0d0b8", "#f0e8d8", "#d8c8b0", "#e8c8b0", "#c8d0c8"]
const PERA := ["#d8c8a8", "#c8b898", "#e0d0b0", "#b8a890"]
const OTTOMAN_WOOD := ["#c8503a", "#e8d070", "#a8c0b8", "#8a5a3a", "#d8a878", "#e8e0d0"]
## Athens: white and cream polykatoikia; neoclassical ochre and pastel.
const ATHENS := ["#f2efe8", "#ece6da", "#e8e0d0", "#f0ece4", "#e4dccc"]
const NEOCLASSICAL := ["#e8c890", "#e8b8a0", "#f0dcc0", "#d8c0a0", "#c8d0c0"]

const BASE := {
	"madrid": "mediterranean", "madrid_austrias": "madrid", "madrid_modern": "madrid",
	"lisbon": "mediterranean", "lisbon_pombaline": "lisbon", "lisbon_alfama": "lisbon",
	"lisbon_modern": "lisbon",
	"milan": "mediterranean", "milan_rational": "milan", "milan_modern": "milan",
	"florence": "mediterranean", "florence_umbertino": "florence", "florence_modern": "florence",
	"istanbul": "middle_east", "istanbul_pera": "istanbul", "istanbul_wood": "istanbul",
	"istanbul_tower": "istanbul",
	"athens": "mediterranean", "athens_neoclassical": "athens",
}

## [era, kinds, from, to, building:architecture, weight, km from, km to,
## storey band, heritage era] (BuildingEra.ERAS).
const ERAS := {
	"madrid": [
		["madrid_austrias", ALL, 1500, 1859, ["baroque", "herrerian", "habsburg", "neoclassicism",
			"churrigueresque"], 1.0, 0.0, 1.2, [2, 4], true],
		["madrid", HAC, 1860, 1949, ["eclectic", "historicism", "neo_mudejar", "art_nouveau",
			"modernisme", "art_deco"], 5.0, 0.0, 99.0, [5, 8]],
		["madrid_modern", ACC, 1950, 2100, [], 1.5, 0.0, 99.0, [9, 99]],
	],
	"lisbon": [
		["lisbon_alfama", HAC, 1100, 1755, ["medieval", "vernacular", "manueline", "moorish"],
			0.6, 0.0, 2.0, [2, 3], true],
		["lisbon_pombaline", AC, 1756, 1830, ["pombaline", "pombalino", "neoclassicism"],
			1.0, 0.0, 1.0, [4, 5]],
		["lisbon", HAC, 1831, 1959, ["romanticism", "eclectic", "art_nouveau", "art_deco",
			"estado_novo", "português_suave"], 5.0, 0.0, 99.0, [1, 6]],
		["lisbon_modern", ACC, 1960, 2100, [], 1.0, 0.0, 99.0, [7, 99]],
	],
	"milan": [
		["milan", HAC, 1700, 1929, ["neoclassicism", "eclectic", "liberty", "art_nouveau",
			"umbertino", "baroque"], 5.0, 0.0, 99.0, [3, 7], true],
		["milan_rational", ACC, 1930, 1979, ["rationalism", "rationalist", "razionalismo",
			"novecento", "brutalism", "modernism"], 2.0, 0.0, 99.0, [8, 14]],
		["milan_modern", ACC, 1980, 2100, [], 0.8, 0.0, 99.0, [15, 99]],
	],
	"florence": [
		["florence", ALL, 1200, 1864, ["renaissance", "medieval", "gothic", "baroque",
			"mannerism"], 6.0, 0.0, 2.0, [1, 6], true],
		["florence_umbertino", AC, 1865, 1949, ["umbertino", "eclectic", "liberty",
			"historicism"], 2.0, 1.0, 99.0, [4, 6]],
		["florence_modern", ACC, 1950, 2100, [], 0.6, 2.0, 99.0, [7, 99]],
	],
	"istanbul": [
		["istanbul_wood", ["house", "apartments"], 1700, 1923, ["ottoman", "ottoman_vernacular",
			"vernacular", "wooden"], 0.4, 0.0, 99.0, [1, 3], true],
		["istanbul_pera", AC, 1860, 1949, ["eclectic", "levantine", "art_nouveau", "neoclassicism",
			"first_national", "art_deco"], 1.5, 0.0, 3.0, [4, 7]],
		["istanbul", HAC, 1950, 2100, ["modernism"], 5.0, 0.0, 99.0, [4, 12]],
		["istanbul_tower", ACC, 1990, 2100, [], 0.8, 0.0, 99.0, [13, 99]],
	],
	"athens": [
		["athens_neoclassical", ALL, 1834, 1940, ["neoclassicism", "neoclassical", "eclectic",
			"ottoman"], 0.8, 0.0, 2.5, [1, 3], true],
		["athens", HAC, 1941, 2100, ["polykatoikia", "modernism", "modernist"], 6.0, 0.0, 99.0, [4, 12]],
	],
}

const REGIONS := {
	# Ensanche blocks (Salamanca, Chamberí): five to seven storeys of
	# render and brick, an iron balcony at every French window, white
	# glazed miradores, zinc and slate mansard tops.
	"madrid": {
		"apartments": {"w": [["render", MADRID], ["brick", MADRID_BRICK]], "p": [["punched", 3], ["ornate", 1]],
			"wn": "french", "bay": 2.6, "fr": "#f4f1ea", "sh": "#3a3d42", "sp": 0.4, "rl": 0.9,
			"r": [["mansard", 2], ["hipped", 2], ["flat", 1]], "pitch": 0.6,
			"rf": ZINC + [["terracotta", TERRA]], "fh": 3.3, "st": [5, 7], "fix": true, "ch": 0.2,
			"dm": 0.4, "eq": 0.5, "g": [["shop", 2], ["stone", 1]], "ev": 0.3,
			"rv": {"balconette": 0.9, "oriel": 0.25, "string_course": true, "awning": 0.25,
				"awning_colours": ["#2a4a3a", "#7a1f24", "#c8a24a", "#e8e4da"]}},
		"commercial": {"w": [["render", MADRID], ["limestone", ["#e8e0cc", "#d8ccb4"]]], "p": [["ornate", 2], ["punched", 2]],
			"wn": "french", "rl": 0.8, "r": [["mansard", 2], ["flat", 1]], "rf": ZINC, "st": [5, 8],
			"fix": true, "g": [["shop", 1]], "rv": {"balconette": 0.8, "string_course": true}},
	},
	# Madrid de los Austrias: red brick framed in granite, slate spires,
	# green shutters, three or four storeys.
	"madrid_austrias": {
		"apartments": {"w": [["brick", MADRID_BRICK], ["render", MADRID]], "p": "punched", "wn": "french",
			"bay": 2.6, "fr": "#f4f1ea", "sh": "#3f5a3a", "sp": 0.5, "rl": 0.8, "r": [["hipped", 2], ["gabled", 1]],
			"pitch": 0.6, "rf": [["terracotta", TERRA]] + ZINC, "fh": 3.3, "st": [3, 4], "fix": true,
			"g": [["shop", 1], ["stone", 1]], "rv": {"balconette": 0.8, "quoins": true, "string_course": true}},
		"civic": {"w": [["brick", MADRID_BRICK]], "p": "punched", "wn": "french", "r": [["hipped", 1]],
			"pitch": 0.9, "rf": ZINC, "st": [3, 4], "fix": true, "rv": {"quoins": true, "string_course": true}},
	},
	"madrid_modern": {
		"apartments": {"w": [["brick", ["#b8805a", "#a87048"]], ["concrete", ["#d8d0c0"]]], "p": [["balcony", 3], ["strip", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 14], "fix": true,
			"rv": {"deep_balcony": 0.6, "awning": 0.3, "awning_colours": ["#2a4a3a", "#c8a24a"]}},
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d0c0"]]], "p": [["curtain", 3], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [10, 45], "fix": true, "rv": {}},
	},
	# Azulejo and pastel render fronts, four and five storeys, iron
	# balconies, terracotta hipped roofs with mansard attics.
	"lisbon": {
		"apartments": {"w": [["render", LISBON]], "p": [["tiles", 2], ["punched", 3]], "wn": "french",
			"bay": 2.4, "fr": "#f4f1ea", "sh": "#3f5a3a", "sp": 0.3, "rl": 0.8,
			"r": [["hipped", 3], ["mansard", 1]], "pitch": 0.55, "rf": [["terracotta", TERRA]],
			"fh": 3.2, "st": [3, 5], "fix": true, "ch": 0.2, "dm": 0.4, "eq": 0.2,
			"g": [["shop", 1], ["none", 1]], "ev": 0.3, "rv": {"balconette": 0.8, "string_course": true}},
		"house": {"w": [["render", LISBON]], "p": [["tiles", 1], ["punched", 2]], "wn": "french", "bay": 2.4,
			"fr": "#f4f1ea", "rl": 0.6, "r": [["hipped", 2], ["gabled", 1]], "pitch": 0.55,
			"rf": [["terracotta", TERRA]], "st": [2, 3], "fix": true, "rv": {"balconette": 0.5}},
	},
	"lisbon_pombaline": {
		"apartments": {"w": [["render", POMBALINE]], "p": "punched", "wn": "french", "bay": 2.4, "fr": "#f4f1ea",
			"sp": 0.0, "rl": 0.9, "r": [["mansard", 2], ["hipped", 1]], "pitch": 0.6,
			"rf": [["terracotta", TERRA]], "fh": 3.3, "st": [4, 5], "fix": true, "dm": 0.6,
			"g": [["shop", 1]], "rv": {"balconette": 0.9, "string_course": true}},
		"commercial": {"w": [["render", POMBALINE]], "p": "punched", "wn": "french", "bay": 2.4, "rl": 0.9,
			"r": [["mansard", 1]], "rf": [["terracotta", TERRA]], "st": [4, 5], "fix": true,
			"g": [["shop", 1]], "rv": {"balconette": 0.9, "string_course": true}},
	},
	# Alfama and Mouraria: small pastel houses stacked up the hill,
	# tiled or plain render, terracotta, laundry balconies.
	"lisbon_alfama": {
		"house": {"w": [["render", LISBON]], "p": "punched", "wn": "casement", "bay": 2.2, "fr": "#f4f1ea",
			"sh": "#3f5a3a", "sp": 0.4, "r": [["hipped", 2], ["gabled", 2]], "pitch": 0.5,
			"rf": [["terracotta", TERRA]], "fh": 2.9, "st": [2, 3], "fix": true, "ev": 0.3,
			"rv": {"balconette": 0.4}},
		"apartments": {"w": [["render", LISBON]], "p": "punched", "wn": "casement", "bay": 2.2,
			"r": [["hipped", 2], ["gabled", 1]], "pitch": 0.5, "rf": [["terracotta", TERRA]],
			"st": [3, 4], "fix": true, "rv": {"balconette": 0.4}},
	},
	"lisbon_modern": {
		"apartments": {"w": [["render", ["#f2efe8", "#ece6da"]], ["concrete", ["#d8d0c0"]]],
			"p": [["balcony", 2], ["strip", 2]], "wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [7, 14], "fix": true, "rv": {"deep_balcony": 0.5}},
		"commercial": {"w": [["glass", []], ["concrete", ["#e8e4dc"]]], "p": [["curtain", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 20], "fix": true, "rv": {}},
	},
	# Eclectic and Liberty palazzi round courtyards (case di ringhiera
	# behind): ochre and grey render over ceppo stone, five to seven
	# storeys, low tiled roofs.
	"milan": {
		"apartments": {"w": [["render", MILAN], ["stone", ["#a8a090", "#9a9284"]]], "p": [["punched", 3], ["ornate", 2]],
			"wn": "french", "bay": 2.6, "fr": "#5a4a3a", "sh": "#4a3a2a", "sp": 0.7, "rl": 0.5,
			"r": [["hipped", 3], ["flat", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]], "fh": 3.4,
			"st": [5, 7], "fix": true, "ch": 0.1, "eq": 0.3, "g": [["shop", 1], ["stone", 1]],
			"rv": {"balconette": 0.5, "string_course": true}},
		"commercial": {"w": [["render", MILAN], ["limestone", ["#e8e0cc"]]], "p": [["ornate", 2], ["punched", 1]],
			"wn": "french", "r": [["hipped", 1], ["flat", 1]], "rf": [["terracotta", TERRA]], "st": [5, 7],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	"milan_rational": {
		"apartments": {"w": [["brick", ["#a8603f", "#b87050"]], ["stone", ["#c8c0b0", "#b8b0a0"]], ["render", MILAN]],
			"p": [["strip", 2], ["balcony", 2], ["punched", 1]], "wn": "wide", "bay": 3.0, "sh": "#6a5a4a",
			"sp": 0.4, "r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 12], "fix": true,
			"rv": {"deep_balcony": 0.5}},
		"commercial": {"w": [["stone", ["#c8c0b0"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [6, 14], "fix": true, "rv": {}},
	},
	"milan_modern": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [15, 50], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["balcony", 2], ["curtain", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 30], "fix": true,
			"rv": {"deep_balcony": 0.6}},
	},
	# Renaissance palazzi and tower houses: cream and ochre intonaco over
	# a rusticated pietra forte base, green shutters, deep eaves under
	# low terracotta hips.
	"florence": {
		"apartments": {"w": [["render", FLORENCE], ["stone", PIETRA_FORTE]], "p": "punched", "wn": "casement",
			"bay": 2.8, "fr": "#5a4a3a", "sh": "#3f5a3a", "sp": 0.9, "rl": 0.1,
			"r": [["hipped", 4], ["gabled", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]], "fh": 3.8,
			"st": [3, 5], "fix": true, "ch": 0.3, "eq": 0.1, "g": [["stone", 2], ["shop", 1]], "ev": 1.0,
			"rv": {"string_course": true, "quoins": true}},
		"house": {"w": [["render", FLORENCE], ["stone", PIETRA_FORTE]], "p": "punched", "wn": "casement",
			"bay": 2.6, "fr": "#5a4a3a", "sh": "#3f5a3a", "sp": 0.9, "r": [["hipped", 3], ["gabled", 1]],
			"pitch": 0.45, "rf": [["terracotta", TERRA]], "st": [2, 3], "fix": true, "ev": 0.8, "rv": {}},
		"commercial": {"w": [["stone", PIETRA_FORTE], ["render", FLORENCE]], "p": "punched", "wn": "casement",
			"sh": "#3f5a3a", "sp": 0.7, "r": [["hipped", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]],
			"st": [3, 5], "fix": true, "g": [["shop", 1]], "ev": 1.0, "rv": {"string_course": true}},
	},
	"florence_umbertino": {
		"apartments": {"w": [["render", FLORENCE]], "p": [["punched", 2], ["ornate", 1]], "wn": "french",
			"fr": "#5a4a3a", "sh": "#3f5a3a", "sp": 0.9, "rl": 0.4, "r": [["hipped", 1]], "pitch": 0.45,
			"rf": [["terracotta", TERRA]], "fh": 3.5, "st": [4, 6], "fix": true, "ev": 0.6,
			"rv": {"balconette": 0.4, "string_course": true}},
	},
	"florence_modern": {
		"apartments": {"w": [["render", ["#ece4d4", "#e0d4bc"]], ["concrete", ["#d8d0c0"]]],
			"p": [["balcony", 2], ["strip", 1]], "wn": "wide", "sh": "#3f5a3a", "sp": 0.5,
			"r": [["flat", 1], ["hipped", 1]], "pitch": 0.4, "rf": [["membrane", []], ["terracotta", TERRA]],
			"st": [6, 10], "fix": true, "rv": {"deep_balcony": 0.4}},
	},
	# Post-1950 apartment blocks (the city's bulk): five to ten storeys of
	# pastel render, balconies on every flat, shops below.
	"istanbul": {
		"apartments": {"w": [["render", ISTANBUL], ["concrete", ["#d8d0c0", "#c8c0b0"]]],
			"p": [["balcony", 3], ["punched", 2]], "wn": "wide", "bay": 3.0, "fr": "#8a8c8e", "sp": 0.0,
			"r": [["flat", 2], ["hipped", 2]], "pitch": 0.4, "rf": [["membrane", []], ["terracotta", TERRA]],
			"fh": 2.9, "st": [5, 9], "fix": true, "ch": 0.1, "eq": 0.6,
			"g": [["shop", 2], ["none", 1]], "gc": ["#2a3a4a", "#5a2a1a", "#20302a", "#3a3020"], "ev": 0.3,
			"rv": {"deep_balcony": 0.5, "awning": 0.3, "signage": 0.25,
				"awning_colours": ["#7a1f24", "#2a4a6a", "#c8a24a", "#e8e4da"]}},
		"commercial": {"w": [["render", ISTANBUL], ["concrete", ["#d8d0c0"]], ["glass", []]], "p": [["strip", 2], ["punched", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 8], "fix": true,
			"g": [["signage", 2], ["shop", 1]], "rv": {"signage": 0.5, "awning": 0.3,
				"awning_colours": ["#7a1f24", "#2a4a6a", "#c8a24a"]}},
	},
	# Pera / Beyoğlu: Levantine stone and render apartments with ornate
	# bay windows (cumba), iron balconies, five to seven storeys.
	"istanbul_pera": {
		"apartments": {"w": [["stone", PERA], ["render", PERA]], "p": [["ornate", 3], ["punched", 1]],
			"wn": "french", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0, "rl": 0.6,
			"r": [["hipped", 2], ["flat", 1]], "pitch": 0.4, "rf": [["terracotta", TERRA]], "fh": 3.5,
			"st": [5, 7], "fix": true, "g": [["shop", 1]], "rv": {"oriel": 0.6, "balconette": 0.5,
				"string_course": true}},
		"commercial": {"w": [["stone", PERA]], "p": "ornate", "wn": "french", "rl": 0.5, "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [4, 6], "fix": true, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	# Ottoman wooden houses (Fener, Balat, Arnavutköy): painted timber,
	# projecting upper storeys, shallow tiled hips.
	"istanbul_wood": {
		"house": {"w": [["wood", OTTOMAN_WOOD]], "p": "clapboard", "wn": "sash", "bay": 2.2, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]],
			"fh": 2.9, "st": [2, 3], "fix": true, "ev": 0.6, "rv": {"oriel": 0.6}},
		"apartments": {"w": [["wood", OTTOMAN_WOOD], ["render", ISTANBUL]], "p": "clapboard", "wn": "sash",
			"bay": 2.2, "r": [["hipped", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]], "st": [3, 3],
			"fix": true, "rv": {"oriel": 0.5}},
	},
	"istanbul_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [15, 55], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", ["#e0d8c8"]]], "p": [["balcony", 2], ["curtain", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 40], "fix": true, "rv": {}},
	},
	# Polykatoikia: six- and seven-storey white concrete blocks, a deep
	# balcony along every floor under striped awnings, solar heaters and
	# tanks on the flat roofs.
	"athens": {
		"apartments": {"w": [["render", ATHENS], ["concrete", ["#e8e4dc", "#d8d4cc"]]],
			"p": [["balcony", 5], ["strip", 1]], "wn": "wide", "bay": 3.2, "fr": "#8a8c8e", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["concrete", ["#d8d4cc", "#c8c4bc"]]], "fh": 3.0, "st": [5, 7],
			"fix": true, "ch": 0.0, "eq": 0.9, "g": [["shop", 2], ["none", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.95, "awning": 0.55,
				"awning_colours": ["#e8e4da", "#2a4a6a", "#c8a24a", "#4a6a4a"]}},
		"commercial": {"w": [["render", ATHENS], ["glass", []]], "p": [["strip", 2], ["balcony", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["concrete", ["#d8d4cc"]]], "st": [4, 7], "fix": true,
			"eq": 0.8, "g": [["shop", 1]], "rv": {"deep_balcony": 0.5, "awning": 0.4,
				"awning_colours": ["#e8e4da", "#2a4a6a"]}},
	},
	# Neoclassical houses (Plaka, Thiseio): two or three storeys in ochre
	# and pastel render, pilasters and pediments, iron balconettes, tiled
	# hips with antefixes.
	"athens_neoclassical": {
		"house": {"w": [["render", NEOCLASSICAL]], "p": [["ornate", 2], ["punched", 1]], "wn": "french",
			"bay": 2.6, "fr": "#f4f1ea", "sh": "#3f5a3a", "sp": 0.7, "rl": 0.7,
			"r": [["hipped", 3], ["flat", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]], "fh": 3.6,
			"st": [2, 3], "fix": true, "ev": 0.3, "rv": {"balconette": 0.7, "string_course": true, "quoins": true}},
		"apartments": {"w": [["render", NEOCLASSICAL]], "p": "ornate", "wn": "french", "bay": 2.6,
			"sh": "#3f5a3a", "sp": 0.7, "rl": 0.7, "r": [["hipped", 1]], "pitch": 0.45,
			"rf": [["terracotta", TERRA]], "st": [2, 3], "fix": true, "rv": {"balconette": 0.7, "string_course": true}},
		"commercial": {"w": [["render", NEOCLASSICAL]], "p": "ornate", "wn": "french", "rl": 0.6,
			"r": [["hipped", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]], "st": [2, 3], "fix": true,
			"g": [["shop", 1]], "rv": {"balconette": 0.6, "string_course": true}},
	},
}
