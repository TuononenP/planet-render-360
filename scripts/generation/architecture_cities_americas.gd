class_name ArchitectureCitiesAmericas
extends RefCounted

## North American city rows (CityStyles zones) and their era rows
## (BuildingEra): New York, Chicago, San Francisco. City rows inherit
## from north_america; eras from their city. Same key legend as
## ArchitectureData; `rv` = 3D relief (replaces the parent's).

const NYC_BRICK := ["#9c4a35", "#8a3f30", "#a8553a", "#7a3a2a", "#b0634a", "#8a5a40"]
const BROWNSTONE := ["#6a4a38", "#7a5640", "#5e4232", "#82604a"]
const DELI := ["#1f2a3a", "#7a1a1a", "#20302a", "#2a2a2a", "#1a3a6a"]
const AWNINGS := ["#1f3b2c", "#7a1f24", "#1a3a6a", "#2a2a2a", "#c8a24a"]
## Chicago common brick (cream to red) and Bedford limestone.
const CHI_BRICK := ["#9c4a35", "#8a3f30", "#b0805a", "#a86a48", "#c09a6a"]
const GREYSTONE := ["#b8b0a0", "#a8a090", "#c0b8a8"]
## San Francisco "painted ladies".
const PAINTED := ["#e8a0a8", "#a8c8d8", "#e8d080", "#b8d0a8", "#c8a8d0", "#f0c8a0", "#8ab0c8", "#e88a6a"]
## Edwardian flats: cream, sand, butter, blush and pale blue-grey paint.
const EDWARDIAN := ["#f0ece0", "#e8dcc0", "#d8e0e0", "#ecd8c8", "#d0d8c8", "#e6d4b8", "#c8d4dc", "#f2e6cc"]
## Marina / Sunset stucco rowhouses: pastel stucco.
const SF_STUCCO := ["#f2ead8", "#e8d8c0", "#d8e4e0", "#f0dcd0", "#e6e2c4", "#dcd4e2", "#f4e8c8", "#cce0d4"]
## Mission-revival tile accents and pre-war buff brick and terracotta.
const SF_TILE := ["#a8553a", "#b4623e", "#9a4a32"]
const SF_BUFF := ["#c8a880", "#b89870", "#a88060", "#d0b890"]
const CHINATOWN := ["#b8202a", "#1f5a3a", "#c8a030"]

const BASE := {
	"new_york": "north_america", "nyc_brownstone": "new_york", "nyc_prewar": "new_york",
	"nyc_glass": "new_york", "nyc_castiron": "new_york", "nyc_loft": "new_york",
	"nyc_nycha": "new_york", "nyc_pencil": "new_york", "nyc_international": "new_york",
	"chicago": "north_america", "chicago_greystone": "chicago", "chicago_tower": "chicago",
	"san_francisco": "north_america", "sf_victorian": "san_francisco", "sf_tower": "san_francisco",
	"sf_stucco": "san_francisco", "sf_prewar": "san_francisco", "sf_chinatown": "san_francisco",
}

const REGIONS := {
	# Tenements / walk-ups: red brick, 5–6 storeys, fire escapes, bracket
	# cornice, rooftop water tanks, shops and deli awnings below.
	"new_york": {
		"apartments": {"w": [["brick", NYC_BRICK]], "p": [["punched", 4], ["ornate", 1]], "wn": "sash",
			"bay": 2.6, "fr": "#efece4", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.0, "st": [5, 6], "fix": true, "ch": 0.3, "eq": 0.5,
			"g": [["shop", 3], ["none", 1]], "gc": DELI, "ev": 0.0,
			"rv": {"fire_escape": 0.8, "stoop": 0.3, "string_course": true, "awning": 0.45,
				"awning_colours": AWNINGS}},
		"commercial": {"w": [["brick", NYC_BRICK]], "p": [["punched", 2], ["ornate", 1]], "wn": "sash",
			"bay": 2.8, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.4, "st": [4, 6],
			"fix": true, "eq": 0.5, "g": [["shop", 1]], "gc": DELI, "ev": 0.0,
			"rv": {"fire_escape": 0.5, "string_course": true, "awning": 0.6,
				"awning_colours": AWNINGS}},
		"house": {"w": [["brick", NYC_BRICK]], "p": "punched", "wn": "sash", "bay": 2.4,
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 4], "fix": true,
			"rv": {"stoop": 0.7, "string_course": true}},
	},
	# Brownstones: brown sandstone row houses, high stoops, tall narrow
	# windows with heavy lintels, bracketed cornice, flat roof.
	"nyc_brownstone": {
		"house": {"w": [["stone", BROWNSTONE]], "p": "brownstone", "wn": "sash", "bay": 2.1,
			"fr": "#2f2a26", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.3, "st": [3, 5], "fix": true, "ch": 0.6, "eq": 0.1, "g": [["none", 1]], "ev": 0.0,
			"rv": {"stoop": 0.95, "string_course": true, "oriel": 0.1, "fire_escape": 0.05}},
		"apartments": {"w": [["stone", BROWNSTONE]], "p": "brownstone", "wn": "sash", "bay": 2.1,
			"fr": "#2f2a26", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.3, "st": [4, 5],
			"fix": true, "ch": 0.5, "g": [["none", 3], ["shop", 1]], "ev": 0.0,
			"rv": {"stoop": 0.85, "string_course": true, "fire_escape": 0.1}},
	},
	# Pre-war masonry towers and art deco setbacks: buff brick and
	# limestone, ornate bands, 10–22 storeys.
	"nyc_prewar": {
		"apartments": {"w": [["brick", ["#b08a60", "#c09a70", "#a07850", "#9c4a35"]], ["limestone", ["#d8ccb0", "#cfc0a0"]]],
			"p": [["ornate", 3], ["punched", 2]], "wn": "sash", "bay": 2.8, "fr": "#efece4",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2, "st": [10, 22], "fix": true,
			"ch": 0.1, "eq": 0.7, "g": [["stone", 2], ["shop", 2]], "ev": 0.0,
			"rv": {"string_course": true, "fire_escape": 0.1, "awning": 0.3,
				"awning_colours": ["#1f3b2c", "#2a2a2a", "#7a1f24"]}},
		"commercial": {"w": [["limestone", ["#d8ccb0", "#cfc0a0"]], ["brick", ["#b08a60", "#c09a70"]]],
			"p": [["ornate", 2], ["punched", 2]], "wn": "sash", "bay": 2.8, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.6, "st": [12, 40], "fix": true, "eq": 0.8,
			"g": [["stone", 1], ["shop", 1]], "rv": {"string_course": true}},
		"civic": {"w": [["limestone", ["#d8ccb0", "#cfc0a0"]]], "p": "ornate", "wn": "sash",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 10], "fix": true,
			"g": [["stone", 1]], "rv": {"string_course": true, "quoins": true}},
	},
	# Glass towers (Midtown, Downtown, Hudson Yards).
	"nyc_glass": {
		"apartments": {"w": [["glass", []], ["concrete", ["#c8c4bc", "#b8b4ac"]]], "p": [["curtain", 3], ["balcony", 1]],
			"wn": "wide", "bay": 3.0, "fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.2, "st": [20, 50], "fix": true, "ch": 0.0, "eq": 0.9,
			"g": [["shop", 1], ["none", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.15, "mullion": true, "string_course": true}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "bay": 3.0, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.9, "st": [25, 60], "fix": true, "eq": 0.9,
			"g": [["shop", 1]], "rv": {"string_course": true, "mullion": true}},
		"civic": {"w": [["glass", []], ["concrete", ["#c8c4bc"]]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [6, 20], "fix": true, "rv": {}},
	},
	# SoHo and Tribeca: iron-framed loft facades, pale painted metal and
	# tall closely spaced windows under a pronounced bracketed cornice.
	"nyc_castiron": {
		"commercial": {"w": [["render", ["#d9d5c9", "#c9c7bd", "#e0dbcf"]]], "p": "ornate", "wn": "wide",
			"bay": 2.4, "fr": "#ccc9bf", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.8, "st": [4, 7], "fix": true, "g": [["shop", 1]],
			"rv": {"cornice": 0.9, "string_course": true}},
		"apartments": {"w": [["render", ["#d9d5c9", "#c9c7bd"]]], "p": "ornate", "wn": "wide",
			"bay": 2.4, "fr": "#ccc9bf", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.6, "st": [4, 7], "fix": true, "g": [["shop", 1]],
			"rv": {"cornice": 0.9, "string_course": true}},
	},
	# DUMBO's former factories and warehouses: dark brick and large sash bays.
	"nyc_loft": {
		"commercial": {"w": [["brick", ["#824b3c", "#98604b", "#a0684f"]]], "p": "punched", "wn": "wide",
			"bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.7, "st": [5, 9],
			"fix": true, "g": [["shop", 1]], "rv": {"cornice": 0.6, "string_course": true, "fire_escape": 0.25}},
		"apartments": {"w": [["brick", ["#824b3c", "#98604b"]]], "p": "punched", "wn": "wide",
			"bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.5, "st": [5, 9],
			"fix": true, "rv": {"cornice": 0.5, "string_course": true, "fire_escape": 0.3}},
	},
	"nyc_nycha": {
		"apartments": {"w": [["brick", ["#934d3d", "#a05743", "#8a4a3b"]]], "p": "punched", "wn": "sash",
			"bay": 2.8, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0,
			"st": [10, 20], "fix": true, "g": [["none", 1]], "rv": {}},
	},
	"nyc_pencil": {
		"apartments": {"w": [["glass", []]], "p": "curtain", "wn": "wide", "bay": 2.8, "fr": "#a3a39e",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [55, 90], "fix": true,
			"g": [["none", 1]], "rv": {"string_course": true}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "bay": 2.8, "fr": "#a3a39e",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8, "st": [55, 90], "fix": true,
			"g": [["shop", 1]], "rv": {"string_course": true, "mullion": true}},
	},
	"nyc_international": {
		"commercial": {"w": [["glass", ["#333b40", "#43484a"]]], "p": "curtain", "bay": 3.2,
			"fr": "#272b2d", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8,
			"st": [20, 45], "fix": true, "g": [["stone", 1]], "rv": {"string_course": true, "mullion": true}},
	},
	# Chicago two- and three-flats: common brick, bay fronts, flat roofs
	# with parapets, back porches.
	"chicago": {
		"apartments": {"w": [["brick", CHI_BRICK]], "p": "punched", "wn": "sash", "bay": 2.6,
			"fr": "#efece4", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1,
			"st": [2, 4], "fix": true, "ch": 0.4, "eq": 0.3, "g": [["none", 3], ["shop", 1]], "ev": 0.0,
			"rv": {"oriel": 0.45, "stoop": 0.5, "fire_escape": 0.2, "string_course": true}},
		"house": {"w": [["brick", CHI_BRICK], ["wood", ["#e8e4da", "#a8b4b8", "#c9b898"]]], "p": "punched",
			"wn": "sash", "bay": 2.6, "r": [["gabled", 3], ["flat", 2], ["hipped", 1]], "pitch": 0.8,
			"st": [1, 2], "fix": true, "rv": {"stoop": 0.6, "oriel": 0.2}},
		"commercial": {"w": [["brick", CHI_BRICK]], "p": [["punched", 2], ["ornate", 1]], "wn": "sash",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [2, 5], "fix": true,
			"g": [["shop", 1]], "rv": {"string_course": true, "awning": 0.4, "awning_colours": AWNINGS}},
	},
	# Greystones: Bedford limestone fronts, heavy lintels, bay windows.
	"chicago_greystone": {
		"house": {"w": [["limestone", GREYSTONE]], "p": "brownstone", "wn": "sash", "bay": 2.4,
			"fr": "#2f2a26", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2, "st": [2, 3],
			"fix": true, "ch": 0.5, "g": [["none", 1]], "ev": 0.0,
			"rv": {"stoop": 0.85, "oriel": 0.5, "string_course": true}},
		"apartments": {"w": [["limestone", GREYSTONE]], "p": "brownstone", "wn": "sash", "bay": 2.4,
			"fr": "#2f2a26", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2, "st": [2, 3],
			"fix": true, "g": [["none", 1]], "ev": 0.0,
			"rv": {"stoop": 0.8, "oriel": 0.5, "string_course": true}},
	},
	# Loop towers: dark steel-and-glass (Mies) and glass.
	"chicago_tower": {
		"apartments": {"w": [["glass", []], ["concrete", ["#4a4c50", "#3e4044", "#c8c4bc"]]],
			"p": [["curtain", 3], ["strip", 2]], "wn": "wide", "bay": 3.0, "fr": "#2a2c30",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [15, 50], "fix": true,
			"ch": 0.0, "eq": 0.9, "g": [["shop", 1], ["none", 1]], "rv": {"deep_balcony": 0.1}},
		"commercial": {"w": [["glass", []], ["concrete", ["#4a4c50", "#3e4044"]]], "p": [["curtain", 3], ["strip", 1]],
			"bay": 3.0, "fr": "#2a2c30", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8,
			"st": [15, 60], "fix": true, "eq": 0.9, "g": [["shop", 1]], "rv": {}},
		"civic": {"w": [["concrete", ["#4a4c50", "#c8c4bc"]], ["glass", []]], "p": "strip",
			"r": [["flat", 1]], "rf": [["membrane", []]], "rv": {}},
	},
	# Edwardian flats (post-1906): pastel paint over stucco or smooth siding
	# (the plank photo with punched windows read as grime), stacked bay
	# windows, bracketed cornices, flat roofs, garages under.
	"san_francisco": {
		"apartments": {"w": [["render", EDWARDIAN]],
			"p": "punched", "wn": "sash", "bay": 2.5, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [3, 4],
			"fix": true, "ch": 0.2, "eq": 0.2, "g": [["none", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"oriel": 0.85, "stoop": 0.6, "fire_escape": 0.15, "string_course": true,
				"cornice": 0.7, "garage": 0.35}},
		"house": {"w": [["render", EDWARDIAN]],
			"p": "punched", "wn": "sash", "bay": 2.5, "fr": "#f4f1ea", "r": [["flat", 2], ["gabled", 1]],
			"rf": [["membrane", []], ["slate", ["#5a5652"]]], "st": [2, 3], "fix": true,
			"rv": {"oriel": 0.8, "stoop": 0.7, "cornice": 0.5, "garage": 0.5}},
		"commercial": {"w": [["render", ["#f0ece0", "#e8e0c8"]], ["brick", ["#9c4a35"]]], "p": "punched",
			"wn": "sash", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 5], "fix": true,
			"g": [["shop", 1]], "rv": {"awning": 0.4, "awning_colours": AWNINGS}},
	},
	# Victorian "painted ladies": bright painted timber, bay windows,
	# steep gable fronts, high stoops.
	"sf_victorian": {
		"house": {"w": [["wood", PAINTED]], "p": "clapboard", "wn": "sash", "bay": 2.3, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["gabled", 3], ["flat", 2]], "pitch": 1.2,
			"rf": [["slate", ["#5a5652", "#625c56"]]], "fh": 3.2, "st": [2, 3], "fix": true,
			"ch": 0.4, "dm": 0.2, "g": [["none", 1]], "ev": 0.3,
			"rv": {"oriel": 0.9, "stoop": 0.9, "string_course": true, "cornice": 0.6, "garage": 0.25}},
		"apartments": {"w": [["wood", PAINTED]], "p": "clapboard", "wn": "sash", "bay": 2.3,
			"fr": "#f4f1ea", "r": [["flat", 2], ["gabled", 1]], "pitch": 1.1,
			"rf": [["slate", ["#5a5652"]], ["membrane", []]], "fh": 3.2, "st": [2, 3], "fix": true,
			"g": [["none", 1]], "ev": 0.2, "rv": {"oriel": 0.85, "stoop": 0.8, "string_course": true,
				"cornice": 0.7, "garage": 0.2}},
	},
	# Marina / Sunset / Richmond rowhouses (1920s–50s): pastel stucco over a
	# garage, the entry stair at the side, a picture window or a shallow bay,
	# flat roofs behind a parapet, some Mission-revival tile.
	"sf_stucco": {
		"house": {"w": [["render", SF_STUCCO]], "p": "punched", "wn": "wide", "bay": 2.6, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["flat", 4], ["gabled", 1]], "pitch": 0.45,
			"rf": [["membrane", []], ["terracotta", SF_TILE]], "fh": 3.0, "st": [2, 3], "fix": true,
			"ch": 0.1, "g": [["none", 1]], "ev": 0.1,
			"rv": {"garage": 0.9, "oriel": 0.35, "cornice": 0.3}},
		"apartments": {"w": [["render", SF_STUCCO]], "p": "punched", "wn": "wide", "bay": 2.6,
			"fr": "#f4f1ea", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [3, 4],
			"fix": true, "ch": 0.1, "eq": 0.2, "g": [["none", 1]], "ev": 0.0,
			"rv": {"garage": 0.6, "oriel": 0.5, "cornice": 0.4, "string_course": true}},
	},
	# Pre-war masonry high-rises (1906–1940s): Nob Hill hotels and flats,
	# the old downtown's buff brick, terracotta and granite, 9–30 storeys.
	"sf_prewar": {
		"apartments": {"w": [["brick", SF_BUFF], ["render", ["#e8e0d0", "#d8d0c0"]], ["limestone", ["#d8ccb0"]]],
			"p": [["ornate", 3], ["punched", 2]], "wn": "sash", "bay": 2.8, "fr": "#efece4",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1, "st": [9, 18], "fix": true,
			"ch": 0.1, "eq": 0.6, "g": [["stone", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"string_course": true, "awning": 0.3, "awning_colours": ["#1f3b2c", "#2a2a2a", "#7a1f24"]}},
		"commercial": {"w": [["limestone", ["#d8ccb0", "#cfc0a0", "#e0d8c8"]], ["brick", SF_BUFF]],
			"p": [["ornate", 2], ["punched", 2]], "wn": "sash", "bay": 2.8, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.6, "st": [10, 30], "fix": true, "eq": 0.8,
			"g": [["stone", 1], ["shop", 1]], "rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["limestone", ["#d8ccb0", "#e0d8c8"]]], "p": "ornate", "wn": "sash",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 10], "fix": true,
			"g": [["stone", 1]], "rv": {"string_course": true, "quoins": true}},
	},
	# Chinatown (rebuilt after 1906): brick and render walk-ups over shops,
	# fire escapes, red, green and gold awnings and signs.
	"sf_chinatown": {
		"apartments": {"w": [["brick", ["#9c4a35", "#8a5a40", "#a86a48"]], ["render", ["#e8e0d0", "#d8d0b8", "#c8d0c0"]]],
			"p": "punched", "wn": "sash", "bay": 2.6, "fr": "#e8e4d8", "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.1, "st": [3, 5], "fix": true, "ch": 0.1, "eq": 0.4,
			"g": [["shop", 1]], "gc": CHINATOWN, "ev": 0.0,
			"rv": {"fire_escape": 0.5, "awning": 0.6, "awning_colours": CHINATOWN, "signage": 0.5,
				"balconette": 0.3, "string_course": true}},
		"commercial": {"w": [["brick", ["#9c4a35", "#8a5a40"]], ["render", ["#e8e0d0", "#d8d0b8"]]],
			"p": "punched", "wn": "sash", "bay": 2.6, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.4, "st": [2, 4], "fix": true, "g": [["shop", 1]], "gc": CHINATOWN,
			"rv": {"awning": 0.7, "awning_colours": CHINATOWN, "signage": 0.6}},
	},
	"sf_tower": {
		"apartments": {"w": [["glass", []], ["concrete", ["#d8d4cc", "#c8c4bc"]]], "p": [["curtain", 2], ["strip", 1]],
			"wn": "wide", "bay": 3.0, "fr": "#3a3d42", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.1, "st": [12, 40], "fix": true, "eq": 0.9, "g": [["shop", 1]], "rv": {"deep_balcony": 0.15}},
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": "curtain", "bay": 3.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.8, "st": [12, 50], "fix": true,
			"eq": 0.9, "g": [["shop", 1]], "rv": {}},
		"civic": {"w": [["concrete", ["#d8d4cc"]], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "rv": {}},
	},
}
