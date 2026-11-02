class_name ArchitectureCitiesAsia
extends RefCounted

## Asian city rows (CityStyles zones) and their era rows (BuildingEra):
## Tokyo, Hong Kong, Singapore, Seoul, Dubai. City rows inherit from
## japan / east_asia / southeast_asia / middle_east; eras from their
## city. Same key legend as ArchitectureData; `rv` = 3D relief (replaces
## the parent's).

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
## Seoul apartment-complex slabs: white and cream painted concrete.
const SEOUL_SLAB := ["#ecebe6", "#e4e2dc", "#e8e4da", "#dcdad4", "#d8dcdc"]
## 1970s–90s "villa" and dagagu houses: red and brown face brick.
const SEOUL_BRICK := ["#8a4232", "#7a3a2c", "#9a5040", "#6e3a30", "#a0604a"]
## The green waterproof coating painted on Seoul's flat roofs.
const GREEN_ROOF := ["#5f8f72", "#6a9a7c", "#55836a"]
## Hanok: grey giwa tile, white plaster between dark timber.
const GIWA := ["#4a4e54", "#55595e", "#3f444a"]
const SEOUL_SIGNS := ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a", "#f2f2f2"]
## Gulf sand render and the coral-stone / gypsum of the old quarters.
const GULF_SAND := ["#e2d2b2", "#d8c6a0", "#eadcc0", "#cdb68e", "#e8e0cc"]
const CORAL := ["#d8c8a8", "#cbb891", "#e0d4b8", "#c8b48e"]
const VILLA := ["#f0e8d8", "#e8dcc4", "#e2d2b2", "#f2eee6", "#e8d8c0"]

const BASE := {
	"tokyo": "japan", "tokyo_house": "tokyo", "tokyo_tower": "tokyo",
	"hong_kong": "east_asia", "hk_tenement": "hong_kong", "hk_office": "hong_kong",
	"singapore": "southeast_asia", "sg_shophouse": "singapore", "sg_tower": "singapore",
	"seoul": "east_asia", "seoul_villa": "seoul", "seoul_hanok": "seoul", "seoul_tower": "seoul",
	"dubai": "middle_east", "dubai_tower": "dubai", "dubai_heritage": "dubai",
	"dubai_villa": "dubai",
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
	# Apartment complexes (danji): 12–25 storey white slabs with glazed
	# balconies in long parallel rows; dense signed commercial streets.
	"seoul": {
		"apartments": {"w": [["concrete", SEOUL_SLAB], ["render", SEOUL_SLAB]],
			"p": [["panel", 3], ["balcony", 2]], "wn": "wide", "bay": 3.0, "fr": "#9a9c9e",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.8, "st": [12, 25],
			"fix": true, "ch": 0.0, "eq": 0.5, "g": [["none", 3], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.1}},
		"commercial": {"w": [["concrete", ["#d8d6d0", "#c8c4bc"]], ["glass", []], ["render", SEOUL_SLAB]],
			"p": [["strip", 3], ["tiles", 2], ["curtain", 1]], "wn": "wide", "bay": 3.0,
			"fr": "#8a8c8e", "r": [["flat", 1]], "rf": [["concrete", GREEN_ROOF], ["membrane", []]],
			"fh": 3.4, "st": [3, 9], "fix": true, "eq": 0.85, "g": [["signage", 3], ["shop", 1]],
			"gc": SEOUL_SIGNS, "ev": 0.0, "rv": {"signage": 0.8, "awning": 0.1,
				"awning_colours": ["#2a4a6a", "#8a2a1a", "#e8e4da"]}},
	},
	# Villas and dagagu: 3–5 storey red-brick walk-ups on small plots,
	# aluminium sliders, green-painted flat roofs with water tanks.
	"seoul_villa": {
		"apartments": {"w": [["brick", SEOUL_BRICK]], "p": "punched", "wn": "wide", "bay": 2.8,
			"fr": "#9a9c9e", "sp": 0.0, "r": [["flat", 1]], "rf": [["concrete", GREEN_ROOF]],
			"fh": 2.8, "st": [3, 5], "fix": true, "ch": 0.0, "eq": 0.7,
			"g": [["none", 2], ["shop", 1], ["signage", 1]], "gc": SEOUL_SIGNS, "ev": 0.0,
			"rv": {"signage": 0.3, "deep_balcony": 0.15}},
		"house": {"w": [["brick", SEOUL_BRICK], ["render", ["#e8e4dc", "#d8d0c0"]]], "p": "punched",
			"wn": "wide", "bay": 2.8, "fr": "#9a9c9e", "sp": 0.0, "r": [["flat", 3], ["gabled", 1]],
			"pitch": 0.5, "rf": [["concrete", GREEN_ROOF], ["slate", ["#5a626b", "#7a3a2c"]]],
			"fh": 2.8, "st": [2, 3], "fix": true, "ch": 0.0, "eq": 0.6, "ev": 0.2},
		"commercial": {"w": [["brick", SEOUL_BRICK], ["concrete", ["#d8d6d0"]]], "p": "punched",
			"wn": "wide", "bay": 2.8, "fr": "#9a9c9e", "r": [["flat", 1]], "rf": [["concrete", GREEN_ROOF]],
			"fh": 3.0, "st": [2, 5], "fix": true, "eq": 0.7, "g": [["signage", 2], ["shop", 1]],
			"gc": SEOUL_SIGNS, "rv": {"signage": 0.7}},
	},
	# Hanok: one storey, white plaster between dark timber posts on a
	# granite base, deep eaves under curved grey giwa roofs.
	"seoul_hanok": {
		"house": {"w": [["render", ["#efebe2", "#e8e2d6", "#f2efe8"]], ["wood", ["#6a4a32", "#5a3e2a"]]],
			"p": "punched", "wn": "small", "bay": 2.4, "fr": "#5a3e2a", "sp": 0.0,
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.75, "rf": [["slate", GIWA]],
			"fh": 3.2, "st": [1, 1], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.0,
			"g": [["stone", 1]], "ev": 1.1, "rv": {}},
		"commercial": {"w": [["render", ["#efebe2", "#e8e2d6"]], ["wood", ["#6a4a32"]]], "p": "punched",
			"wn": "small", "bay": 2.4, "fr": "#5a3e2a", "r": [["hipped", 1]], "pitch": 0.75,
			"rf": [["slate", GIWA]], "fh": 3.2, "st": [1, 2], "fix": true, "eq": 0.0,
			"g": [["shop", 1]], "ev": 1.0, "rv": {"signage": 0.2}},
	},
	"seoul_tower": {
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d6d0"]]], "p": [["curtain", 4], ["strip", 1]],
			"bay": 3.0, "fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.0,
			"st": [15, 45], "fix": true, "eq": 0.9, "g": [["shop", 1]], "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", SEOUL_SLAB]], "p": [["curtain", 2], ["balcony", 2]],
			"wn": "wide", "bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0,
			"st": [25, 50], "fix": true, "eq": 0.8, "g": [["none", 1]], "rv": {}},
		"civic": {"w": [["concrete", ["#d8d6d0"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 15], "fix": true, "rv": {}},
	},
	# Mid-rise 6–15 storey blocks (Karama, Al Barsha, Bur Dubai): sand
	# render, tinted glass, balconies, shops below, plant on every roof.
	"dubai": {
		"apartments": {"w": [["render", GULF_SAND], ["concrete", ["#d8ccb4", "#cfc2a8"]]],
			"p": [["balcony", 3], ["strip", 2], ["punched", 1]], "wn": "wide", "bay": 3.2,
			"fr": "#6a6e72", "sp": 0.0, "r": [["flat", 1]], "rf": [["concrete", ["#d8c8a8", "#c8b898"]]],
			"fh": 3.2, "st": [6, 15], "fix": true, "ch": 0.0, "eq": 0.9,
			"g": [["shop", 2], ["none", 1]], "gc": ["#20302a", "#3a3020", "#2a3a4a", "#5a4a3a"], "ev": 0.0,
			"rv": {"deep_balcony": 0.4, "awning": 0.1, "awning_colours": ["#5a4a3a", "#2a3a4a"]}},
		"commercial": {"w": [["glass", []], ["render", GULF_SAND]], "p": [["curtain", 2], ["strip", 2]],
			"bay": 3.4, "fr": "#4a4e52", "r": [["flat", 1]], "rf": [["concrete", ["#d8c8a8"]]],
			"fh": 3.8, "st": [4, 12], "fix": true, "eq": 0.9, "g": [["shop", 1]], "rv": {}},
	},
	# Sheikh Zayed Road, Downtown, Business Bay, the Marina: 30–80 storey
	# blue and silver curtain walls.
	"dubai_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "bay": 3.0, "fr": "#8a9098",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.0, "st": [30, 70], "fix": true,
			"eq": 0.6, "g": [["shop", 1]], "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", ["#e8e4dc", "#d8d4cc"]]],
			"p": [["curtain", 3], ["balcony", 2]], "wn": "wide", "bay": 3.0, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.3, "st": [30, 80], "fix": true, "eq": 0.6,
			"g": [["none", 1], ["shop", 1]], "rv": {"deep_balcony": 0.3}},
		"civic": {"w": [["glass", []], ["concrete", ["#e8e4dc"]]], "p": "curtain", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [6, 20], "fix": true, "rv": {}},
	},
	# Al Fahidi / Al Shindagha: 1–2 storey coral-stone and gypsum courtyard
	# houses, small openings behind timber screens, flat parapet roofs.
	"dubai_heritage": {
		"house": {"w": [["stone", CORAL], ["render", CORAL]], "p": "adobe", "wn": "small", "bay": 3.0,
			"fr": "#5a4030", "sh": "#6a4a30", "sp": 0.3, "r": [["flat", 1]],
			"rf": [["concrete", CORAL]], "fh": 3.6, "st": [1, 2], "fix": true, "ch": 0.0,
			"eq": 0.0, "ev": 0.0, "rv": {}},
		"commercial": {"w": [["stone", CORAL], ["render", CORAL]], "p": "adobe", "wn": "small",
			"bay": 3.0, "fr": "#5a4030", "sh": "#6a4a30", "sp": 0.3, "r": [["flat", 1]],
			"rf": [["concrete", CORAL]], "fh": 3.6, "st": [1, 2], "fix": true, "eq": 0.0,
			"g": [["shop", 1]], "ev": 0.0, "rv": {"awning": 0.3, "awning_colours": ["#8a6a3a", "#5a4a3a"]}},
	},
	# Villa compounds (Jumeirah, Emirates Hills): two storeys of pale
	# render, parapet flat roofs or hipped terracotta.
	"dubai_villa": {
		"house": {"w": [["render", VILLA]], "p": "punched", "wn": "wide", "bay": 3.4, "fr": "#6a6e72",
			"sp": 0.0, "r": [["flat", 3], ["hipped", 2]], "pitch": 0.5,
			"rf": [["concrete", ["#d8c8a8"]], ["terracotta", ArchitectureData.TERRA]],
			"fh": 3.4, "st": [2, 2], "fix": true, "ch": 0.0, "eq": 0.7, "ev": 0.3, "rv": {}},
	},
}
