class_name ArchitectureCitiesCentral
extends RefCounted

## Central European city rows (CityStyles zones) and their era rows
## (BuildingEra): Vienna, Prague, Budapest, Munich. City rows inherit
## from central_europe; eras from their city. Same key legend as
## ArchitectureData; `rv` = 3D relief (replaces the parent's). ERAS rows
## carry a storey band and a heritage flag (BuildingEra._banded).

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]

const RED_TILE := ["#a8482a", "#b5542f", "#9a4a2c", "#8a4032"]
const COPPER := [["slate", ["#5f8f7f", "#6a9a88"]]]
const SHEET := [["slate", ["#4a4e54", "#55595e", "#5a6066"]]]
## Vienna Gründerzeit: cream, Schönbrunn yellow, grey and stone render.
const VIENNA := ["#e8dcc0", "#e8d090", "#d8d0c0", "#c8c0b0", "#efe6d2", "#d8c8a8"]
const GEMEINDEBAU := ["#e0c8a0", "#d8b890", "#c8a080", "#e8d8b8"]
## Prague: pastel Baroque render and the stone of the historicist blocks.
const PRAGUE := ["#e8d090", "#e8c0a0", "#f0e0c0", "#c8d8c0", "#e0b890", "#efe6d2", "#d8c0c8"]
const PANEL := ["#c8c4bc", "#d8d4cc", "#b8b4ac"]
## Budapest eclectic: grey, ochre and buff render, soot-darkened stone.
const BUDAPEST := ["#c8c0b0", "#d8c8a8", "#b8b0a0", "#e0d0b0", "#c8b898", "#a8a090"]
## Munich: pastel Altstadt render; ochre and white Schwabing Jugend.
const MUNICH := ["#f0e8d8", "#e8d8b0", "#e8c8b0", "#d8e0d0", "#efe6d2", "#e8d0a0"]

const BASE := {
	"vienna": "central_europe", "vienna_baroque": "vienna", "vienna_gemeindebau": "vienna",
	"vienna_modern": "vienna",
	"prague": "central_europe", "prague_old": "prague", "prague_panel": "prague",
	"budapest": "central_europe", "budapest_castle": "budapest", "budapest_panel": "budapest",
	"munich": "central_europe", "munich_altstadt": "munich", "munich_modern": "munich",
}

## [era, kinds, from, to, building:architecture, weight, km from, km to,
## storey band, heritage era] (BuildingEra.ERAS).
const ERAS := {
	"vienna": [
		["vienna_baroque", ALL, 1600, 1847, ["baroque", "biedermeier", "classicism",
			"neoclassicism", "rococo"], 1.0, 0.0, 1.5, [2, 4], true],
		["vienna", HAC, 1848, 1918, ["historicism", "gruenderzeit", "gründerzeit", "ringstrasse",
			"secession", "jugendstil", "art_nouveau"], 5.0, 0.0, 99.0, [4, 6]],
		["vienna_gemeindebau", APT, 1919, 1934, ["red_vienna", "gemeindebau", "expressionism"],
			1.0, 1.5, 99.0, [5, 7]],
		["vienna_modern", ACC, 1950, 2100, [], 1.0, 0.0, 99.0, [8, 99]],
	],
	"prague": [
		["prague_old", ALL, 1200, 1849, ["baroque", "gothic", "renaissance", "romanesque",
			"rococo", "classicism"], 1.5, 0.0, 1.5, [2, 5], true],
		["prague", HAC, 1850, 1949, ["historicism", "art_nouveau", "secession", "cubism",
			"rondocubism", "functionalism", "neo-renaissance"], 5.0, 0.0, 99.0, [4, 6]],
		["prague_panel", APT, 1955, 1995, ["panelak", "panelák", "socialist_modernism", "prefab",
			"brutalism"], 1.5, 3.5, 99.0, [7, 99]],
	],
	"budapest": [
		["budapest_castle", ALL, 1686, 1849, ["baroque", "classicism", "neoclassicism",
			"copf", "zopf"], 0.8, 0.0, 99.0, [1, 3], true],
		["budapest", HAC, 1850, 1944, ["eclectic", "historicism", "art_nouveau", "secession",
			"hungarian_secession", "neo-renaissance", "art_deco"], 5.0, 0.0, 99.0, [3, 6]],
		["budapest_panel", APT, 1955, 1995, ["panelhaz", "panelház", "socialist_modernism",
			"socialist_realism", "prefab"], 1.5, 3.5, 99.0, [7, 99]],
	],
	"munich": [
		["munich_altstadt", ALL, 1300, 1859, ["gothic", "baroque", "renaissance", "classicism",
			"neoclassicism", "rococo"], 1.5, 0.0, 1.2, [2, 5], true],
		["munich", HAC, 1860, 1960, ["historicism", "jugendstil", "art_nouveau", "gruenderzeit",
			"gründerzeit", "reconstruction"], 5.0, 0.0, 99.0, [3, 6]],
		["munich_modern", ACC, 1961, 2100, [], 1.0, 0.0, 99.0, [7, 99]],
	],
}

const REGIONS := {
	# Gründerzeit Zinshäuser on the Ring and in the inner districts:
	# five storeys of cream, yellow and grey render or stone-faced
	# Ringstraße fronts, heavy cornices and
	# window aedicules, tiled or sheet-metal roofs with dormers.
	"vienna": {
		"apartments": {"w": [["render", VIENNA], ["limestone", ["#e0d8c4", "#d8ccb4", "#e8e0cc"]]],
			"p": [["ornate", 3], ["punched", 2]], "wn": "casement",
			"bay": 2.6, "fr": "#f4f1ea", "sp": 0.0, "rl": 0.2, "r": [["gabled", 3], ["hipped", 2], ["mansard", 1]],
			"pitch": 0.7, "rf": [["terracotta", RED_TILE]] + SHEET, "fh": 3.6, "st": [5, 6], "fix": true,
			"ch": 0.5, "dm": 0.5, "eq": 0.1, "g": [["stone", 1], ["shop", 1]], "ev": 0.2,
			"rv": {"string_course": true, "balconette": 0.3, "quoins": true}},
		"commercial": {"w": [["render", VIENNA], ["limestone", ["#e8e0cc", "#d8ccb4"]]], "p": [["ornate", 2], ["punched", 1]],
			"wn": "casement", "r": [["hipped", 2], ["mansard", 1]], "rf": SHEET + COPPER, "fh": 3.8, "st": [4, 6],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "quoins": true}},
	},
	"vienna_baroque": {
		"apartments": {"w": [["render", VIENNA]], "p": "ornate", "wn": "casement", "bay": 2.8, "fr": "#f4f1ea",
			"r": [["hipped", 2], ["mansard", 1]], "pitch": 0.9, "rf": [["terracotta", RED_TILE]] + COPPER,
			"fh": 3.8, "st": [3, 4], "fix": true, "dm": 0.5, "g": [["stone", 1], ["shop", 1]],
			"rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["render", VIENNA]], "p": "ornate", "wn": "casement", "bay": 3.0, "fr": "#f4f1ea",
			"r": [["hipped", 1], ["mansard", 1]], "pitch": 0.8, "rf": COPPER + SHEET, "fh": 4.5,
			"st": [2, 4], "fix": true, "rv": {"string_course": true, "quoins": true}},
	},
	# Red Vienna superblocks: ochre render round courtyards, flat or low
	# roofs, loggias and corner towers.
	"vienna_gemeindebau": {
		"apartments": {"w": [["render", GEMEINDEBAU]], "p": [["punched", 3], ["balcony", 1]], "wn": "casement",
			"bay": 2.8, "fr": "#f4f1ea", "r": [["hipped", 2], ["flat", 1]], "pitch": 0.5,
			"rf": [["terracotta", RED_TILE]], "fh": 3.0, "st": [5, 6], "fix": true,
			"rv": {"deep_balcony": 0.3, "string_course": true}},
	},
	"vienna_modern": {
		"apartments": {"w": [["render", ["#ece8dc", "#e0d8c8"]], ["glass", []]], "p": [["punched", 2], ["strip", 2], ["balcony", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [7, 14], "fix": true,
			"rv": {"deep_balcony": 0.3}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [8, 40], "fix": true, "rv": {}},
	},
	# Vinohrady and Nové Město: historicist and Art Nouveau blocks of
	# five storeys, ornate stucco, steep red tile with towers and dormers.
	"prague": {
		"apartments": {"w": [["render", PRAGUE]], "p": [["ornate", 3], ["punched", 2]], "wn": "casement",
			"bay": 2.6, "fr": "#f4f1ea", "sp": 0.0, "rl": 0.2, "r": [["hipped", 2], ["mansard", 2], ["gabled", 1]],
			"pitch": 0.9, "rf": [["terracotta", RED_TILE]] + SHEET, "fh": 3.5, "st": [5, 6], "fix": true,
			"ch": 0.5, "dm": 0.6, "g": [["shop", 1], ["stone", 1]],
			"rv": {"string_course": true, "balconette": 0.3, "oriel": 0.25}},
		"commercial": {"w": [["render", PRAGUE], ["stone", ["#b8a888", "#a89878"]]], "p": [["ornate", 2], ["punched", 1]],
			"wn": "casement", "r": [["mansard", 1], ["hipped", 1]], "rf": [["terracotta", RED_TILE]] + COPPER,
			"st": [4, 6], "fix": true, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	# Staré Město and Malá Strana: Baroque pastel houses on Gothic cellars,
	# steep red tile with dormers, gables to the street.
	"prague_old": {
		"apartments": {"w": [["render", PRAGUE]], "p": [["punched", 2], ["ornate", 1]], "wn": "casement",
			"bay": 2.4, "fr": "#f4f1ea", "sp": 0.0, "r": [["gabled", 2], ["hipped", 2], ["mansard", 1]],
			"pitch": 1.1, "rf": [["terracotta", RED_TILE]], "fh": 3.3, "st": [3, 5], "fix": true, "ch": 0.5,
			"dm": 0.8, "g": [["shop", 1], ["none", 1]], "rv": {"gable": [["bell", 2], ["", 1]], "string_course": true}},
		"house": {"w": [["render", PRAGUE]], "p": "punched", "wn": "casement", "bay": 2.4, "fr": "#f4f1ea",
			"r": [["gabled", 2], ["hipped", 1]], "pitch": 1.1, "rf": [["terracotta", RED_TILE]], "st": [2, 4],
			"fix": true, "dm": 0.7, "rv": {"gable": [["bell", 1], ["", 1]]}},
		"commercial": {"w": [["render", PRAGUE]], "p": [["punched", 2], ["ornate", 1]], "wn": "casement",
			"r": [["gabled", 1], ["hipped", 1]], "pitch": 1.1, "rf": [["terracotta", RED_TILE]],
			"st": [3, 5], "fix": true, "dm": 0.7, "g": [["shop", 1]], "rv": {"gable": [["bell", 1], ["", 1]]}},
	},
	"prague_panel": {
		"apartments": {"w": [["concrete", PANEL], ["render", ["#e0c8a0", "#c8d8c0", "#d8b8a8"]]],
			"p": [["panel", 3], ["balcony", 1]], "wn": "wide", "bay": 3.0, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 2.8, "st": [8, 13], "fix": true, "rv": {"deep_balcony": 0.2}},
	},
	# Eclectic bérházak round courtyards (Pest's inner districts): four
	# to six storeys of grey and ochre render, heavy cornices, balconies,
	# tile and sheet-metal roofs.
	"budapest": {
		"apartments": {"w": [["render", BUDAPEST], ["stone", ["#a8a090", "#9a9284"]]], "p": [["ornate", 3], ["punched", 2]],
			"wn": "casement", "bay": 2.8, "fr": "#d8d0c0", "sp": 0.0, "rl": 0.3,
			"r": [["hipped", 3], ["mansard", 1]], "pitch": 0.6, "rf": [["terracotta", RED_TILE]] + SHEET,
			"fh": 3.7, "st": [4, 5], "fix": true, "ch": 0.4, "dm": 0.3, "g": [["shop", 1], ["stone", 1]],
			"rv": {"string_course": true, "balconette": 0.4, "oriel": 0.15}},
		"commercial": {"w": [["render", BUDAPEST], ["stone", ["#b8b0a0"]]], "p": "ornate", "wn": "casement",
			"r": [["hipped", 1], ["mansard", 1]], "rf": SHEET + COPPER, "fh": 3.9, "st": [4, 6], "fix": true,
			"g": [["shop", 1]], "rv": {"string_course": true}},
	},
	# The Castle District: Baroque and Zopf houses of one to three
	# storeys, pastel render, steep tile.
	"budapest_castle": {
		"house": {"w": [["render", ["#e8d090", "#efe6d2", "#e8c0a0", "#c8d8c0"]]], "p": "punched",
			"wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "r": [["hipped", 2], ["gabled", 1]], "pitch": 0.9,
			"rf": [["terracotta", RED_TILE]], "fh": 3.3, "st": [1, 2], "fix": true, "rv": {"string_course": true}},
		"apartments": {"w": [["render", ["#e8d090", "#efe6d2", "#e8c0a0"]]], "p": "punched", "wn": "casement",
			"r": [["hipped", 2], ["gabled", 1]], "pitch": 0.9, "rf": [["terracotta", RED_TILE]], "st": [2, 3],
			"fix": true, "rv": {"string_course": true}},
	},
	"budapest_panel": {
		"apartments": {"w": [["concrete", PANEL]], "p": [["panel", 3], ["balcony", 1]], "wn": "wide",
			"bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.8, "st": [10, 15],
			"fix": true, "rv": {"deep_balcony": 0.2}},
	},
	# Schwabing, Maxvorstadt, Haidhausen: Gründerzeit and Jugendstil
	# blocks and their post-war rebuilds, pastel render, steep red tile.
	"munich": {
		"apartments": {"w": [["render", MUNICH]], "p": [["punched", 3], ["ornate", 1]], "wn": "casement",
			"bay": 2.6, "fr": "#f4f1ea", "sh": "#3f5a3a", "sp": 0.2, "r": [["gabled", 3], ["hipped", 2], ["mansard", 1]],
			"pitch": 0.9, "rf": [["terracotta", RED_TILE]], "fh": 3.2, "st": [4, 5], "fix": true, "ch": 0.4,
			"dm": 0.6, "g": [["none", 1], ["shop", 1]], "ev": 0.3, "rv": {"string_course": true, "oriel": 0.2}},
		"commercial": {"w": [["render", MUNICH]], "p": "punched", "wn": "casement", "r": [["gabled", 2], ["hipped", 1]],
			"pitch": 0.9, "rf": [["terracotta", RED_TILE]], "st": [3, 5], "fix": true, "g": [["shop", 1]],
			"rv": {"string_course": true}},
	},
	# The Altstadt: gabled burgher houses (rebuilt after 1945 on the old
	# plots), pastel render, steep red tile.
	"munich_altstadt": {
		"apartments": {"w": [["render", MUNICH]], "p": "punched", "wn": "casement", "bay": 2.4, "fr": "#f4f1ea",
			"r": [["gabled", 4], ["hipped", 1]], "pitch": 1.1, "rf": [["terracotta", RED_TILE]], "fh": 3.2,
			"st": [4, 5], "fix": true, "dm": 0.7, "g": [["shop", 1]], "rv": {"string_course": true}},
		"commercial": {"w": [["render", MUNICH]], "p": "punched", "wn": "casement", "bay": 2.4,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 1.1, "rf": [["terracotta", RED_TILE]], "st": [3, 5],
			"fix": true, "dm": 0.6, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	"munich_modern": {
		"apartments": {"w": [["render", ["#ece8dc", "#e0d8c8"]], ["concrete", ["#c8c4bc"]]],
			"p": [["balcony", 3], ["strip", 1]], "wn": "wide", "r": [["flat", 2], ["gabled", 1]], "pitch": 0.5,
			"rf": [["membrane", []], ["terracotta", RED_TILE]], "st": [6, 12], "fix": true, "rv": {"deep_balcony": 0.5}},
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc"]]], "p": [["curtain", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 25], "fix": true, "rv": {}},
	},
}
