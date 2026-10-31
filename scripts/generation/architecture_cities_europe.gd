class_name ArchitectureCitiesEurope
extends RefCounted

## European city rows (CityStyles zones) and their era rows
## (BuildingEra): London, Amsterdam, Berlin, Barcelona, Rome. Each city
## row inherits from its country row; eras inherit from the city. Same
## key legend as ArchitectureData; `rv` = 3D relief (replaces parent's).

## London stock brick (yellow-grey) and red brick; Welsh slate.
const LONDON_STOCK := ["#b59d6e", "#c2a878", "#a88d60", "#b8a070"]
const LONDON_RED := ["#9c4a35", "#8a3f30", "#a0452f"]
const WELSH := ["#4f5760", "#5a626b", "#555c66"]
## Dutch canal brick: dark red, brown, near-black.
const DUTCH := ["#5a2a22", "#4a2420", "#6a3428", "#3a2a26", "#7a3a2a", "#2f2624"]
## Berlin Gründerzeit pastel render.
const BERLIN := ["#e8dcc0", "#e6d2b0", "#d9c9a8", "#e8c9a8", "#d8d0b8", "#c8c0a8", "#e8d8a0", "#d0bca0"]
## Roman ochre / terracotta / sienna render.
const ROMAN := ["#d8a060", "#c8783c", "#b8603a", "#e0b070", "#d89058", "#c06a40", "#e8c088"]
const SHOP_DARK := ["#1f2a3a", "#3a1c20", "#20302a", "#2a2a2a", "#5a1a1a"]
const STRIPES := ["#1f3b2c", "#7a1f24", "#2a2f4a", "#c8a24a", "#e8e4da"]

const BASE := {
	"london": "west_europe_brick", "london_georgian": "london", "london_stucco": "london",
	"london_mansion": "london", "london_council": "london", "london_modern": "london",
	"amsterdam": "west_europe_brick", "amsterdam_school": "amsterdam",
	"amsterdam_modern": "amsterdam",
	"berlin": "central_europe", "berlin_plattenbau": "berlin", "berlin_modern": "berlin",
	"barcelona": "mediterranean", "barcelona_gothic": "barcelona",
	"barcelona_modern": "barcelona",
	"rome": "mediterranean", "rome_palazzina": "rome", "rome_modern": "rome",
}

const REGIONS := {
	# Victorian / Edwardian terraces: stock or red brick, sash windows,
	# bay windows, slate, front steps; shops on the high streets.
	"london": {
		"house": {"w": [["brick", LONDON_STOCK + LONDON_RED]], "p": "punched", "wn": "sash",
			"bay": 2.6, "fr": "#f4f1ea", "sh": "#2a2a2a", "sp": 0.0,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.9, "rf": [["slate", WELSH]],
			"fh": 3.0, "st": [2, 3], "fix": true, "ch": 0.95, "dm": 0.25, "ev": 0.2,
			"g": [["none", 4], ["render", 1]],
			"rv": {"oriel": 0.6, "stoop": 0.5, "string_course": true, "balconette": 0.1}},
		"apartments": {"w": [["brick", LONDON_STOCK + LONDON_RED]], "p": [["punched", 4], ["ornate", 2]],
			"wn": "sash", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["gabled", 2], ["flat", 2], ["hipped", 1]], "pitch": 0.9, "rf": [["slate", WELSH]],
			"fh": 3.0, "st": [3, 5], "fix": true, "ch": 0.8, "dm": 0.2,
			"g": [["shop", 2], ["none", 2]], "gc": SHOP_DARK, "ev": 0.1,
			"rv": {"oriel": 0.35, "stoop": 0.3, "string_course": true, "awning": 0.25,
				"awning_colours": STRIPES}},
		"commercial": {"w": [["brick", LONDON_STOCK + LONDON_RED]], "p": [["ornate", 2], ["punched", 2]],
			"wn": "sash", "bay": 2.8, "fr": "#f4f1ea", "r": [["flat", 2], ["gabled", 1]],
			"rf": [["slate", WELSH], ["membrane", []]], "fh": 3.3, "st": [3, 5], "fix": true,
			"g": [["shop", 1]], "gc": SHOP_DARK,
			"rv": {"string_course": true, "awning": 0.35, "awning_colours": STRIPES}},
	},
	# Georgian (1714–1839): plain brown brick, tall sash windows, stucco
	# ground floor, parapet hiding the roof, iron balconettes.
	"london_georgian": {
		"house": {"w": [["brick", ["#8a5a40", "#7b4a3a", "#9a6a48", "#a8805a"]]], "p": "punched",
			"wn": "sash", "bay": 2.8, "fr": "#f4f1ea", "sp": 0.0, "r": [["flat", 2], ["gabled", 1]],
			"rf": [["slate", WELSH]], "fh": 3.2, "st": [3, 5], "fix": true, "ch": 0.95, "dm": 0.4,
			"g": [["render", 3], ["none", 1]], "ev": 0.0,
			"rv": {"balconette": 0.35, "stoop": 0.6, "string_course": true}},
		"apartments": {"w": [["brick", ["#8a5a40", "#7b4a3a", "#9a6a48"]]], "p": "punched", "wn": "sash",
			"bay": 2.8, "r": [["flat", 1]], "rf": [["slate", WELSH]], "fh": 3.2, "st": [4, 5],
			"fix": true, "dm": 0.4, "g": [["render", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"balconette": 0.35, "stoop": 0.4, "string_course": true}},
		"commercial": {"w": [["brick", ["#8a5a40", "#9a6a48"]]], "p": "punched", "wn": "sash",
			"bay": 2.8, "r": [["flat", 1]], "fh": 3.2, "st": [3, 5], "fix": true,
			"g": [["shop", 1]], "ev": 0.0,
			"rv": {"balconette": 0.3, "string_course": true, "awning": 0.3,
				"awning_colours": STRIPES}},
	},
	# White stucco terraces (Belgravia, Kensington, Notting Hill):
	# porticos, first-floor balconies, rusticated ground floor.
	"london_stucco": {
		"house": {"w": [["render", ["#f2eee4", "#efe9dc", "#ece6d8", "#f4f0e8"]]],
			"p": [["ornate", 3], ["punched", 1]], "wn": "sash", "bay": 2.8, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["slate", WELSH]], "fh": 3.4, "st": [4, 5],
			"fix": true, "ch": 0.9, "dm": 0.5, "g": [["stone", 1]], "ev": 0.0,
			"rv": {"balcony_rows": [1], "balconette": 0.4, "stoop": 0.7,
				"string_course": true, "quoins": true}},
		"apartments": {"w": [["render", ["#f2eee4", "#efe9dc", "#ece6d8"]]], "p": "ornate", "wn": "sash",
			"bay": 2.8, "r": [["flat", 1]], "fh": 3.4, "st": [4, 6], "fix": true, "dm": 0.5,
			"g": [["stone", 1]], "ev": 0.0,
			"rv": {"balcony_rows": [1], "balconette": 0.4, "stoop": 0.6,
				"string_course": true, "quoins": true}},
		"commercial": {"w": [["render", ["#f2eee4", "#efe9dc"]]], "p": "ornate", "wn": "sash",
			"bay": 2.8, "r": [["flat", 1]], "fh": 3.4, "st": [4, 5], "fix": true,
			"g": [["shop", 1]], "ev": 0.0,
			"rv": {"balcony_rows": [1], "string_course": true, "awning": 0.3,
				"awning_colours": STRIPES}},
	},
	# Mansion blocks (1880–1914): red brick banded with stone, gables,
	# bay windows, 5–7 storeys.
	"london_mansion": {
		"apartments": {"w": [["brick", ["#a0452f", "#b0503a", "#983e2c"]]],
			"p": [["ornate", 3], ["punched", 1]], "wn": "sash", "bay": 3.0, "fr": "#f4f1ea",
			"r": [["gabled", 2], ["hipped", 2], ["mansard", 1]], "pitch": 0.9, "rf": [["slate", WELSH]],
			"fh": 3.1, "st": [5, 7], "fix": true, "ch": 0.8, "dm": 0.6,
			"g": [["shop", 2], ["stone", 1], ["none", 1]], "gc": SHOP_DARK, "ev": 0.1,
			"rv": {"oriel": 0.4, "string_course": true, "quoins": true, "balconette": 0.2,
				"awning": 0.2, "awning_colours": STRIPES}},
	},
	# Post-war council estates: brown brick or concrete slabs, deck
	# access and balconies, flat roofs.
	"london_council": {
		"apartments": {"w": [["brick", ["#7a5a4a", "#8a6a58", "#6a4a3a"]], ["concrete", ["#b6b1a7", "#a7a296"]]],
			"p": [["balcony", 3], ["panel", 2], ["strip", 1]], "wn": "wide", "bay": 3.0,
			"fr": "#e8e8e4", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.7, "st": [5, 14], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.4,
			"g": [["none", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.6}},
	},
	# Contemporary London: glass in the City and Canary Wharf.
	"london_modern": {
		"apartments": {"w": [["glass", []], ["concrete", ["#d0ccc4", "#c0bcb4"]], ["brick", ["#8a6a58"]]],
			"p": [["balcony", 2], ["strip", 2], ["curtain", 1]], "wn": "wide", "bay": 3.0,
			"fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1,
			"st": [8, 24], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.7,
			"g": [["shop", 1], ["none", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.3}},
		"commercial": {"w": [["glass", []], ["concrete", ["#d0ccc4"]]], "p": [["curtain", 3], ["strip", 1]],
			"bay": 3.0, "fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8,
			"st": [10, 40], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.9, "g": [["shop", 1]],
			"ev": 0.0, "rv": {}},
		"civic": {"w": [["concrete", ["#d0ccc4"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [3, 8], "fix": true, "rv": {}},
	},
	# Canal houses: narrow, tall, dark brick, white frames, big windows,
	# steep roofs behind step / neck / bell gables, hoist beams.
	"amsterdam": {
		"house": {"w": [["brick", DUTCH]], "p": "punched", "wn": "sash", "bay": 2.2,
			"fr": "#f4f1ea", "sh": "#1f3a2c", "sp": 0.1, "r": [["gabled", 5], ["hipped", 1]],
			"pitch": 1.4, "rf": [["slate", ["#4a4f55", "#3f4448"]], ["terracotta", ["#8a3f30", "#7a3a2a"]]],
			"fh": 3.2, "st": [3, 5], "fix": true, "ch": 0.5, "dm": 0.2, "ev": 0.05,
			"g": [["none", 3], ["stone", 1]],
			"rv": {"gable": [["neck", 3], ["bell", 3], ["step", 2], ["", 2]], "stoop": 0.4,
				"oriel": 0.05, "string_course": false}},
		"apartments": {"w": [["brick", DUTCH], ["render", ["#f2eee4", "#e8e4da"]]], "p": "punched",
			"wn": "sash", "bay": 2.2, "fr": "#f4f1ea", "sp": 0.1, "sh": "#1f3a2c",
			"r": [["gabled", 5], ["hipped", 1]], "pitch": 1.4,
			"rf": [["slate", ["#4a4f55", "#3f4448"]], ["terracotta", ["#8a3f30"]]],
			"fh": 3.2, "st": [3, 5], "fix": true, "ch": 0.4, "dm": 0.2,
			"g": [["none", 2], ["shop", 2]], "gc": ["#1f2a24", "#2a2a2a", "#3a1c20"], "ev": 0.05,
			"rv": {"gable": [["neck", 3], ["bell", 3], ["step", 2], ["", 3]], "stoop": 0.3,
				"awning": 0.1, "awning_colours": ["#1f3b2c", "#2a2f4a", "#7a1f24"]}},
		"commercial": {"w": [["brick", DUTCH]], "p": "punched", "wn": "sash", "bay": 2.4,
			"r": [["gabled", 3], ["flat", 1]], "pitch": 1.3, "st": [3, 5], "fix": true,
			"g": [["shop", 1]], "gc": ["#1f2a24", "#2a2a2a", "#3a1c20"],
			"rv": {"gable": [["neck", 2], ["bell", 2], ["step", 1], ["", 3]], "awning": 0.2,
				"awning_colours": ["#1f3b2c", "#2a2f4a", "#7a1f24"]}},
	},
	# Amsterdam School (1910–1940): sculpted brick blocks, steep tiled
	# roofs, small-paned windows, bay windows.
	"amsterdam_school": {
		"apartments": {"w": [["brick", ["#8a4a35", "#7a3f2e", "#9a5a40", "#6a3a2a"]]],
			"p": [["ornate", 2], ["punched", 2]], "wn": "casement", "bay": 2.6, "fr": "#f4f1ea",
			"r": [["gabled", 2], ["hipped", 2], ["flat", 1]], "pitch": 1.1,
			"rf": [["terracotta", ["#7a3a2a", "#8a4030", "#5a3028"]], ["slate", ["#4a4f55"]]],
			"fh": 2.9, "st": [4, 5], "fix": true, "ch": 0.3, "dm": 0.3, "g": [["none", 1]],
			"rv": {"oriel": 0.3, "string_course": true}},
		"commercial": {"w": [["brick", ["#8a4a35", "#7a3f2e"]]], "p": "ornate", "wn": "casement",
			"st": [3, 5], "fix": true, "rv": {"string_course": true}},
		"civic": {"w": [["brick", ["#8a4a35", "#7a3f2e"]]], "p": "ornate", "wn": "casement",
			"rv": {"string_course": true}},
	},
	"amsterdam_modern": {
		"apartments": {"w": [["brick", ["#6a5a50", "#5a4a40", "#8a7a6a"]], ["concrete", ArchitectureData.CONCRETE],
				["glass", []]],
			"p": [["strip", 2], ["balcony", 2], ["panel", 1]], "wn": "wide", "bay": 3.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.9, "st": [5, 12], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.5, "g": [["none", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.5}},
		"commercial": {"w": [["glass", []], ["concrete", ArchitectureData.CONCRETE]], "p": "curtain",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [6, 20], "fix": true,
			"g": [["shop", 1]], "rv": {}},
		"civic": {"w": [["concrete", ArchitectureData.CONCRETE], ["glass", []]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "rv": {}},
		"house": {"w": [["brick", ["#6a5a50", "#5a4a40"]], ["wood", ["#4a4440", "#8a7a6a"]]],
			"p": "strip", "r": [["flat", 2], ["skillion", 1]], "rf": [["membrane", []]],
			"st": [2, 3], "fix": true, "rv": {}},
	},
	# Gründerzeit Mietskasernen: five storeys of pastel render with
	# stucco surrounds, Erker and balconies, Berliner Dach.
	"berlin": {
		"apartments": {"w": [["render", BERLIN]], "p": [["ornate", 4], ["punched", 1], ["balcony", 1]],
			"wn": "casement", "bay": 2.5, "fr": "#f1ede4", "sp": 0.0,
			"r": [["mansard", 2], ["flat", 2], ["hipped", 1]], "pitch": 0.8,
			"rf": [["slate", ["#55606a", "#4f5760"]], ["membrane", []], ["terracotta", ["#8a3f30"]]],
			"fh": 3.4, "st": [4, 5], "fix": true, "ch": 0.8, "dm": 0.4, "eq": 0.0,
			"g": [["shop", 3], ["none", 1]], "gc": ["#2e3b34", "#4a1c22", "#283040", "#3a3a3a"], "ev": 0.1,
			"rv": {"deep_balcony": 0.35, "oriel": 0.35, "balconette": 0.2,
				"string_course": true, "awning": 0.25,
				"awning_colours": ["#3a4a3a", "#7a1f24", "#2a2f4a", "#e8e4da"]}},
		"commercial": {"w": [["render", BERLIN]], "p": [["ornate", 2], ["punched", 1]], "wn": "casement",
			"bay": 2.6, "r": [["flat", 2], ["mansard", 1]], "fh": 3.6, "st": [4, 5], "fix": true,
			"g": [["shop", 1]], "rv": {"oriel": 0.2, "string_course": true, "awning": 0.3,
				"awning_colours": ["#3a4a3a", "#7a1f24", "#2a2f4a"]}},
		"house": {"w": [["render", BERLIN]], "p": "ornate", "wn": "casement", "r": [["hipped", 3], ["half-hipped", 1]],
			"st": [2, 3], "fix": true, "rv": {"string_course": true}},
	},
	# Plattenbau (WBS 70 etc.): prefab concrete panels, loggias, flat.
	"berlin_plattenbau": {
		"apartments": {"w": [["concrete", ["#c8c4b8", "#d8cfb8", "#b8c0b8", "#d8c8a8", "#c0b8a8"]]],
			"p": [["panel", 4], ["balcony", 2]], "wn": "casement", "bay": 3.0, "fr": "#e8e8e4",
			"sh": "#8a9a8a", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.8, "st": [6, 11], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.3,
			"g": [["none", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.7}},
	},
	"berlin_modern": {
		"apartments": {"w": [["render", ["#ecebe6", "#d8d6d0"]], ["glass", []], ["concrete", ["#c8c4bc"]]],
			"p": [["punched", 2], ["strip", 2], ["balcony", 1]], "wn": "wide", "bay": 3.0,
			"fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2,
			"st": [6, 8], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.5,
			"g": [["shop", 1], ["none", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.25}},
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc"]]], "p": [["curtain", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [6, 18], "fix": true,
			"g": [["shop", 1]], "rv": {}},
		"civic": {"w": [["concrete", ["#c8c4bc"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "rv": {}},
		"house": {"w": [["render", ["#ecebe6", "#d8d6d0"]]], "p": "strip",
			"r": [["flat", 2], ["skillion", 1]], "rf": [["membrane", []]], "st": [2, 3], "fix": true, "rv": {}},
	},
	# Eixample: ochre / cream stone and render, an iron balcony on every
	# bay, persianas, chamfered blocks, flat roofs behind parapets.
	"barcelona": {
		"apartments": {"w": [["stone", ["#d8c8a8", "#d0bc98", "#e0d0b0"]],
				["render", ["#e8c898", "#e8d4b0", "#d8b888", "#e0c0a0", "#efe0c4"]]],
			"p": "punched", "wn": "french", "bay": 2.6, "fr": "#e8e4d8", "sh": "#3f5a46",
			"sp": 0.6, "rl": 0.9, "r": [["flat", 1]], "rf": [["concrete", ["#b87050", "#a86848"]]],
			"fh": 3.3, "st": [5, 7], "fix": true, "ch": 0.1, "eq": 0.3,
			"g": [["shop", 3], ["none", 1]], "ev": 0.0,
			"rv": {"balcony_rows": [1], "balconette": 0.9, "oriel": 0.15,
				"string_course": true, "awning": 0.35,
				"awning_colours": ["#2a4a3a", "#8a2a1a", "#c8a24a", "#e8e4da"]}},
		"commercial": {"w": [["stone", ["#d8c8a8", "#d0bc98"]], ["render", ["#e8c898", "#efe0c4"]]],
			"p": "punched", "wn": "french", "bay": 2.6, "sh": "#3f5a46", "sp": 0.4, "rl": 0.8,
			"r": [["flat", 1]], "rf": [["concrete", ["#b87050"]]], "fh": 3.4, "st": [5, 7], "fix": true,
			"g": [["shop", 1]],
			"rv": {"balcony_rows": [1], "balconette": 0.8, "string_course": true, "awning": 0.45,
				"awning_colours": ["#2a4a3a", "#8a2a1a", "#c8a24a"]}},
		"house": {"w": [["render", ["#e8c898", "#e8d4b0", "#efe0c4"]]], "wn": "french", "sh": "#3f5a46",
			"sp": 0.6, "rl": 0.6, "r": [["flat", 2], ["gabled", 1]], "st": [2, 4], "fix": true,
			"rv": {"balconette": 0.6}},
	},
	# Ciutat Vella: narrow old stone / render, deep streets.
	"barcelona_gothic": {
		"apartments": {"w": [["stone", ["#b8a888", "#a89878", "#c0b090"]], ["render", ["#d8c0a0", "#c8a880", "#e0c8a8"]]],
			"p": "punched", "wn": "french", "bay": 2.2, "sh": "#4a5a3a", "sp": 0.5, "rl": 0.6,
			"r": [["flat", 2], ["gabled", 1]], "rf": [["terracotta", ArchitectureData.TERRA]],
			"fh": 3.0, "st": [4, 6], "fix": true, "g": [["shop", 2], ["none", 1]],
			"rv": {"balconette": 0.6, "awning": 0.2,
				"awning_colours": ["#2a4a3a", "#8a2a1a", "#c8a24a"]}},
		"commercial": {"w": [["stone", ["#b8a888", "#a89878"]]], "p": "punched", "wn": "french",
			"bay": 2.2, "rl": 0.5, "r": [["flat", 1]], "st": [3, 5], "fix": true, "g": [["shop", 1]],
			"rv": {"balconette": 0.5, "awning": 0.3, "awning_colours": ["#2a4a3a", "#8a2a1a"]}},
		"house": {"w": [["stone", ["#b8a888", "#a89878"]]], "wn": "french", "rl": 0.4,
			"r": [["gabled", 1], ["flat", 1]], "rf": [["terracotta", ArchitectureData.TERRA]],
			"st": [2, 4], "fix": true, "rv": {"balconette": 0.4}},
	},
	"barcelona_modern": {
		"apartments": {"w": [["render", ["#f2f0ea", "#e8e4dc"]], ["concrete", ArchitectureData.CONCRETE], ["glass", []]],
			"p": [["balcony", 3], ["strip", 1], ["panel", 1]], "wn": "wide", "bay": 3.0, "sp": 0.0,
			"rl": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.9, "st": [6, 14],
			"fix": true, "eq": 0.5, "g": [["shop", 1], ["none", 1]], "rv": {"deep_balcony": 0.5}},
		"commercial": {"w": [["glass", []], ["concrete", ArchitectureData.CONCRETE]], "p": "curtain",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 24], "fix": true, "rv": {}},
		"civic": {"w": [["concrete", ArchitectureData.CONCRETE], ["glass", []]], "p": "strip", "rv": {}},
		"house": {"w": [["render", ["#f2f0ea"]]], "p": "strip", "r": [["flat", 1]], "st": [2, 3],
			"fix": true, "rv": {}},
	},
	# Centro storico: ochre / terracotta / sienna render, green shutters,
	# hipped terracotta roofs with deep cornices, travertine plinths.
	"rome": {
		"apartments": {"w": [["render", ROMAN]], "p": "punched", "wn": "french", "bay": 2.8,
			"fr": "#e8e0cc", "sh": ["#3f5a3a", "#4a5f3e", "#5a4a32"], "sp": 0.8, "rl": 0.3,
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.55,
			"rf": [["terracotta", ["#b5542f", "#a8482a", "#c0643a", "#9a4a2c"]]],
			"fh": 3.3, "st": [4, 6], "fix": true, "ch": 0.3, "eq": 0.2,
			"g": [["shop", 2], ["stone", 1], ["none", 1]], "gc": ["#2e3b34", "#5a2a1a", "#283040", "#6a4a2a"],
			"ev": 0.5,
			"rv": {"balconette": 0.3, "string_course": true, "quoins": true, "awning": 0.4,
				"awning_colours": ["#e8e4da", "#2a4a3a", "#8a2a1a", "#c8a24a"]}},
		"commercial": {"w": [["render", ROMAN]], "p": "punched", "wn": "french", "bay": 2.8,
			"sh": ["#3f5a3a", "#4a5f3e"], "sp": 0.6, "rl": 0.2, "r": [["hipped", 1]], "pitch": 0.55,
			"rf": [["terracotta", ["#b5542f", "#a8482a"]]], "fh": 3.4, "st": [3, 5], "fix": true,
			"g": [["shop", 1]], "ev": 0.5,
			"rv": {"balconette": 0.2, "string_course": true, "awning": 0.55,
				"awning_colours": ["#e8e4da", "#2a4a3a", "#8a2a1a"]}},
		"house": {"w": [["render", ROMAN]], "wn": "french", "sh": ["#3f5a3a", "#4a5f3e"], "sp": 0.8,
			"r": [["hipped", 2], ["gabled", 1]], "pitch": 0.5,
			"rf": [["terracotta", ["#b5542f", "#a8482a"]]], "st": [2, 3], "fix": true, "ev": 0.5,
			"rv": {"string_course": true}},
		"civic": {"w": [["limestone", ["#e8e0cc", "#ddd4bc"]], ["render", ROMAN]], "wn": "french",
			"r": [["hipped", 2], ["flat", 1]], "rf": [["terracotta", ["#b5542f"]]],
			"rv": {"string_course": true, "quoins": true}},
	},
	# Palazzine (1950–1980): cream / brick blocks wrapped in deep
	# balconies with roller shutters and big awnings.
	"rome_palazzina": {
		"apartments": {"w": [["render", ["#e8dcc4", "#e0c8a0", "#d8c0a8", "#ece4d4"]], ["brick", ["#b8805a", "#a87048"]]],
			"p": [["balcony", 4], ["punched", 1]], "wn": "wide", "bay": 3.2, "fr": "#6a6e72",
			"sh": "#7a6a4a", "sp": 0.3, "rl": 0.0, "r": [["flat", 3], ["hipped", 1]],
			"rf": [["membrane", []], ["terracotta", ["#b5542f"]]], "fh": 3.0, "st": [5, 8],
			"fix": true, "eq": 0.4, "g": [["none", 2], ["shop", 1]], "ev": 0.3,
			"rv": {"deep_balcony": 0.75, "awning": 0.2,
				"awning_colours": ["#2a4a3a", "#c8a24a", "#e8e4da"]}},
	},
	"rome_modern": {
		"apartments": {"w": [["concrete", ArchitectureData.CONCRETE], ["limestone", ["#e8e0cc"]]],
			"p": [["strip", 2], ["balcony", 1]], "wn": "wide", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [6, 12], "fix": true, "rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["limestone", ["#e8e0cc", "#ddd4bc"]], ["glass", []]],
			"p": [["strip", 2], ["punched", 2]], "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [4, 10], "fix": true, "rv": {}},
		"civic": {"w": [["limestone", ["#e8e0cc", "#ddd4bc"]]], "p": [["punched", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "rv": {"string_course": true}},
	},
}
