class_name ArchitectureCitiesNorth
extends RefCounted

## Northern European city rows (CityStyles zones) and their era rows
## (BuildingEra): Copenhagen, Oslo, Edinburgh, Dublin,
## Brussels, St Petersburg. City rows inherit from their country row;
## eras from their city. Same key legend as ArchitectureData; `rv` = 3D
## relief (replaces the parent's). ERAS rows carry a storey band and a
## heritage flag (BuildingEra._banded) instead of hand-written rules.

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]

## Copenhagen townhouse plaster: ochre, oxide red, yellow, pale blue.
const COPENHAGEN := ["#e0b050", "#c8603a", "#e8d080", "#a8c0c8", "#e8c8a0", "#d89060"]
const DANISH_BRICK := ["#a8503a", "#9a4a35", "#b86048", "#8a4232"]
const RED_TILE := ["#a8482a", "#b5542f", "#9a4a2c"]
## Oslo bygård pastels and the painted clapboard of the old wooden lanes.
const OSLO := ["#e8dcc0", "#d8c8a8", "#e0c8a0", "#c8b898", "#e8d8c8", "#d0b8a0"]
const NORDIC_WOOD := ["#c8503a", "#e8d070", "#f2ede0", "#8a3a2a", "#e8c070", "#a8c0b8"]
## Helsinki: Empire ochre and the grey-green render and granite of Jugend.
const EMPIRE := ["#e8c878", "#e0b860", "#f0d890", "#e8d0a0"]
const JUGEND := ["#b8b8a8", "#a8b0a0", "#c8c0a8", "#9aa098", "#d8d0b8", "#b0a890"]
const SHEET_METAL := [["sheet_metal", ["#3a3e44", "#45494e"]], ["sheet_metal", ["#5a2a24", "#6a3028"]]]
## Edinburgh sandstone: Craigleith blond-grey to darker Old Town rubble.
const SANDSTONE := ["#b8a888", "#a89878", "#c0b090", "#9a8a70", "#b0a080"]
const OLD_RUBBLE := ["#8a8070", "#7a7264", "#968c7a"]
const WELSH := ["#4f5760", "#5a626b", "#555c66"]
## Dublin red-orange Georgian brick and its painted doors.
const DUBLIN_BRICK := ["#a8503a", "#b8603f", "#9a4a35", "#c06a48"]
## Brussels: pale render and brick over Belgian bluestone trim.
const BRUSSELS := ["#ece4d4", "#e0d4c0", "#d8c8b0", "#f0e8dc", "#c8b8a0"]
const BRUSSELS_BRICK := ["#9a4a35", "#7a3a2c", "#a85a40"]
## St Petersburg stucco: yellow, ochre, pink, mint, blue, with white trim.
const PETERSBURG := ["#e8c860", "#e0a870", "#e8b8a8", "#b8d0b0", "#a8c0d8", "#f0d890", "#d8a080"]
const SOVIET_PANEL := ["#c8c4bc", "#d8d4cc", "#b8b4ac", "#e0d8c8"]
## Moscow: merchant-house ochre, peach and sage; Stalinist sand and buff
## stone; the white silicate brick of the khrushchyovki.
const MOSCOW := ["#e8d090", "#e8c8a0", "#efe6d2", "#d8d0c0", "#c8d0b8", "#e0b890"]
const STALINKA := ["#e8d8b0", "#e0c898", "#d8c8a8", "#efe6d2", "#d0b890"]
const SILICATE := ["#e0dcd0", "#d8d4c8", "#c8c0b0"]
## Reykjavik: painted corrugated-iron and clapboard (red, blue, green,
## yellow, white) over the grey and cream render of the post-war blocks.
const ICELAND_IRON := ["#c8503a", "#e8e0d0", "#3a5a8a", "#4a7a5a", "#e8c860", "#f2ede0", "#8a3a2a"]
const ICELAND_ROOF := [["sheet_metal", ["#a83a2a", "#2f4f8a", "#3f6f4a", "#5a5e62"]]]

const BASE := {
	"copenhagen": "west_europe_brick", "copenhagen_old": "copenhagen", "copenhagen_modern": "copenhagen",
	"oslo": "nordic", "oslo_wood": "oslo", "oslo_modern": "oslo",
	"edinburgh": "west_europe_brick", "edinburgh_georgian": "edinburgh", "edinburgh_old": "edinburgh",
	"edinburgh_modern": "edinburgh",
	"dublin": "west_europe_brick", "dublin_victorian": "dublin", "dublin_modern": "dublin",
	"brussels": "west_europe_brick", "brussels_old": "brussels", "brussels_modern": "brussels",
	"st_petersburg": "eastern_europe", "spb_imperial": "st_petersburg", "spb_soviet": "st_petersburg",
	"spb_modern": "st_petersburg",
	"moscow": "eastern_europe", "moscow_stalinka": "moscow", "moscow_panel": "moscow",
	"moscow_city": "moscow",
	"reykjavik": "nordic", "reykjavik_iron": "reykjavik", "reykjavik_modern": "reykjavik",
}

## [era, kinds, from, to, building:architecture, weight, km from, km to,
## storey band, heritage era] (BuildingEra.ERAS).
const ERAS := {
	"copenhagen": [
		["copenhagen_old", HAC, 1600, 1859, ["baroque", "rococo", "classicism", "neoclassicism"],
			1.5, 0.0, 2.0, [2, 4], true],
		["copenhagen", AC, 1860, 1959, ["historicism", "national_romantic", "art_nouveau",
			"nordic_classicism"], 5.0, 0.0, 99.0, [4, 6]],
		["copenhagen_modern", ACC, 1960, 2100, [], 1.0, 0.0, 99.0, [7, 99]],
	],
	"oslo": [
		["oslo_wood", ["house", "apartments"], 1700, 1899, ["vernacular", "swiss_style",
			"dragestil"], 1.0, 0.0, 99.0, [1, 2], true],
		["oslo", AC, 1860, 1949, ["historicism", "art_nouveau", "jugendstil", "functionalism",
			"functionalist"], 5.0, 0.0, 99.0, [3, 6]],
		["oslo_modern", ACC, 1950, 2100, [], 1.0, 0.0, 99.0, [7, 99]],
	],
	"edinburgh": [
		["edinburgh_old", AC, 1400, 1766, ["medieval", "scots_baronial", "vernacular",
			"renaissance"], 1.0, 0.0, 1.0, [6, 12], true],
		["edinburgh_georgian", HAC, 1767, 1850, ["georgian", "regency", "neoclassicism",
			"neoclassical", "palladian"], 2.0, 0.0, 2.5],
		["edinburgh", HAC, 1851, 1939, ["victorian", "edwardian", "tenement", "baronial"],
			5.0, 0.0, 99.0, [1, 5]],
		["edinburgh_modern", ACC, 1950, 2100, [], 0.6, 0.0, 99.0, [13, 99]],
	],
	"dublin": [
		["dublin", HAC, 1714, 1839, ["georgian", "palladian", "neoclassicism", "neoclassical"],
			4.0, 0.0, 3.0, [3, 5], true],
		["dublin_victorian", HAC, 1840, 1939, ["victorian", "edwardian", "artisan"],
			4.0, 0.5, 99.0, [1, 2]],
		["dublin_modern", ACC, 1960, 2100, [], 1.0, 0.0, 99.0, [6, 99]],
	],
	"brussels": [
		["brussels_old", ALL, 1500, 1859, ["baroque", "gothic", "renaissance", "flemish",
			"guild_house", "neoclassicism"], 1.0, 0.0, 0.8, [1, 5], true],
		["brussels", HAC, 1860, 1939, ["art_nouveau", "art_deco", "eclectic", "historicism",
			"maison_de_maitre", "beaux_arts"], 5.0, 0.0, 99.0, [2, 5]],
		["brussels_modern", ACC, 1950, 2100, [], 1.5, 0.0, 99.0, [6, 99]],
	],
	"st_petersburg": [
		["spb_imperial", ALL, 1703, 1839, ["baroque", "petrine_baroque", "classicism",
			"neoclassicism", "empire", "russian_empire"], 1.0, 0.0, 2.5, [2, 4], true],
		["st_petersburg", AC, 1840, 1917, ["eclectic", "historicism", "art_nouveau",
			"style_moderne", "neoclassical_revival"], 5.0, 0.0, 5.0, [5, 7]],
		["spb_soviet", APT, 1950, 1991, ["socialist_modernism", "khrushchyovka", "brezhnevka",
			"stalinist", "prefab", "panel"], 2.0, 4.0, 99.0, [8, 18]],
		["spb_modern", ACC, 1992, 2100, [], 0.6, 0.0, 99.0, [19, 99]],
	],
	"moscow": [
		["moscow", HAC, 1700, 1934, ["classicism", "empire", "eclectic", "historicism", "art_nouveau",
			"style_moderne", "constructivism", "merchant"], 3.0, 0.0, 99.0, [3, 6]],
		["moscow_stalinka", ACC, 1935, 1960, ["stalinist", "stalinist_neoclassicism",
			"socialist_realism", "stalinka"], 3.0, 0.5, 12.0, [7, 12]],
		["moscow_panel", APT, 1956, 1995, ["khrushchyovka", "brezhnevka", "panel", "prefab",
			"socialist_modernism", "brutalism"], 6.0, 3.5, 99.0, [5, 16]],
		["moscow_city", ACC, 1996, 2100, [], 1.5, 0.0, 99.0, [16, 99]],
	],
	"reykjavik": [
		["reykjavik_iron", ["house", "apartments", "commercial"], 1880, 1939, ["corrugated_iron",
			"vernacular", "timber"], 3.0, 0.0, 2.5, [1, 3], true],
		["reykjavik", HAC, 1940, 1999, [], 5.0, 0.0, 99.0, [2, 5]],
		["reykjavik_modern", ACC, 2000, 2100, [], 1.0, 0.0, 99.0, [4, 12]],
	],
}

const REGIONS := {
	# Indre By and the bridge quarters: brick and rendered 5-storey
	# blocks with dormered red-tile and slate roofs, white sashes.
	"copenhagen": {
		"apartments": {"w": [["render", COPENHAGEN], ["brick", DANISH_BRICK]], "p": "punched",
			"wn": "casement", "bay": 2.4, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["gabled", 3], ["mansard", 1], ["hipped", 1]], "pitch": 0.8,
			"rf": [["terracotta", RED_TILE], ["slate", WELSH]], "fh": 3.0, "st": [4, 6], "fix": true,
			"ch": 0.6, "dm": 0.6, "eq": 0.1, "g": [["none", 2], ["shop", 1]], "ev": 0.2,
			"rv": {"string_course": true, "balconette": 0.1}},
		"commercial": {"w": [["render", COPENHAGEN], ["brick", DANISH_BRICK]], "p": "punched",
			"wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "r": [["gabled", 2], ["mansard", 1]],
			"pitch": 0.8, "rf": [["terracotta", RED_TILE], ["slate", WELSH]], "st": [3, 6], "fix": true,
			"dm": 0.4, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	# Nyhavn and the old town: narrow painted plaster townhouses,
	# steep tile roofs with dormers and gable ends to the quay.
	"copenhagen_old": {
		"house": {"w": [["render", COPENHAGEN]], "p": "punched", "wn": "casement", "bay": 2.2,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["gabled", 4], ["hipped", 1]], "pitch": 1.1,
			"rf": [["terracotta", RED_TILE]], "fh": 2.9, "st": [3, 4], "fix": true, "ch": 0.7,
			"dm": 0.7, "ev": 0.2, "rv": {}},
		"apartments": {"w": [["render", COPENHAGEN]], "p": "punched", "wn": "casement", "bay": 2.2,
			"fr": "#f4f1ea", "r": [["gabled", 4], ["hipped", 1]], "pitch": 1.1,
			"rf": [["terracotta", RED_TILE]], "fh": 2.9, "st": [3, 5], "fix": true, "ch": 0.7,
			"dm": 0.7, "g": [["shop", 1], ["none", 1]], "rv": {"awning": 0.2,
				"awning_colours": ["#1f3b2c", "#7a1f24", "#e8e4da"]}},
	},
	"copenhagen_modern": {
		"apartments": {"w": [["concrete", ["#d8d4cc", "#c8c0b0"]], ["wood", ["#8a7a68", "#a08a70"]], ["glass", []]],
			"p": [["balcony", 3], ["strip", 2]], "wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [7, 12], "fix": true, "rv": {"deep_balcony": 0.5}},
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["curtain", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 15], "fix": true, "rv": {}},
	},
	# Bygårder (Grünerløkka, Frogner): 4–5 storey rendered and brick
	# blocks, ornamented cornices, hipped slate and tile roofs.
	"oslo": {
		"apartments": {"w": [["render", OSLO], ["brick", ["#9a4a35", "#8a5040"]]], "p": [["punched", 3], ["ornate", 1]],
			"wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["hipped", 3], ["gabled", 1], ["mansard", 1]], "pitch": 0.7,
			"rf": [["slate", ["#4a4e54", "#555960"]], ["terracotta", RED_TILE]], "fh": 3.1,
			"st": [4, 5], "fix": true, "ch": 0.4, "dm": 0.3, "g": [["none", 2], ["shop", 1]],
			"rv": {"string_course": true, "balconette": 0.2}},
		"commercial": {"w": [["render", OSLO], ["stone", ["#a89e8a", "#9a9080"]]], "p": [["punched", 2], ["ornate", 1]],
			"wn": "casement", "r": [["hipped", 2], ["flat", 1]], "rf": [["slate", ["#4a4e54"]]],
			"st": [4, 6], "fix": true, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	# Damstredet / Telthusbakken: painted clapboard cottages.
	"oslo_wood": {
		"house": {"w": [["wood", NORDIC_WOOD]], "p": "clapboard", "wn": "small", "bay": 2.6,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["gabled", 4]], "pitch": 0.8,
			"rf": [["terracotta", RED_TILE], ["slate", ["#4a4e54"]]], "fh": 2.7, "st": [1, 2],
			"fix": true, "ch": 0.6, "ev": 0.3, "rv": {}},
		"apartments": {"w": [["wood", NORDIC_WOOD]], "p": "clapboard", "wn": "small", "bay": 2.6,
			"fr": "#f4f1ea", "r": [["gabled", 1]], "pitch": 0.8, "rf": [["terracotta", RED_TILE]],
			"st": [2, 2], "fix": true, "rv": {}},
	},
	"oslo_modern": {
		"apartments": {"w": [["concrete", ["#d8d4cc"]], ["wood", ["#8a7a68"]], ["glass", []]],
			"p": [["balcony", 2], ["strip", 2]], "wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [6, 12], "fix": true, "rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["glass", []], ["stone", ["#c8c4bc"]]], "p": [["curtain", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 18], "fix": true, "rv": {}},
	},
	# Victorian and Edwardian sandstone tenements (Marchmont, Leith):
	# four storeys, bay windows, slate, chimney stacks along the ridge.
	"edinburgh": {
		"apartments": {"w": [["stone", SANDSTONE]], "p": "punched", "wn": "sash", "bay": 2.6,
			"fr": "#f4f1ea", "sh": "#2a2a2a", "sp": 0.0, "r": [["gabled", 3], ["hipped", 1]],
			"pitch": 0.9, "rf": [["slate", WELSH]], "fh": 3.2, "st": [4, 4], "fix": true, "ch": 0.95,
			"dm": 0.4, "g": [["none", 2], ["shop", 1]], "ev": 0.1,
			"rv": {"oriel": 0.3, "string_course": true}},
		"house": {"w": [["stone", SANDSTONE]], "p": "punched", "wn": "sash", "bay": 2.6, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["gabled", 2], ["hipped", 1]], "pitch": 0.9, "rf": [["slate", WELSH]],
			"fh": 3.0, "st": [2, 2], "fix": true, "ch": 0.95, "dm": 0.3, "rv": {"oriel": 0.4}},
		"commercial": {"w": [["stone", SANDSTONE]], "p": "punched", "wn": "sash", "fr": "#f4f1ea",
			"r": [["gabled", 2], ["flat", 1]], "rf": [["slate", WELSH]], "st": [3, 5], "fix": true,
			"ch": 0.8, "g": [["shop", 1]], "gc": ["#1e2a24", "#283040", "#4a1c22"], "rv": {"string_course": true}},
	},
	# The New Town: ashlar terraces of three or four storeys over a
	# basement, astragal sashes, slate behind a parapet.
	"edinburgh_georgian": {
		"apartments": {"w": [["stone", SANDSTONE]], "p": "punched", "wn": "sash", "bay": 2.4,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 2], ["flat", 1]], "pitch": 0.6,
			"rf": [["slate", WELSH]], "fh": 3.5, "st": [3, 4], "fix": true, "ch": 0.95, "dm": 0.5,
			"g": [["stone", 1]], "ev": 0.0, "rv": {"string_course": true}},
		"house": {"w": [["stone", SANDSTONE]], "p": "punched", "wn": "sash", "bay": 2.4, "fr": "#f4f1ea",
			"r": [["hipped", 1]], "pitch": 0.6, "rf": [["slate", WELSH]], "fh": 3.5, "st": [3, 4],
			"fix": true, "ch": 0.95, "dm": 0.5, "ev": 0.0, "rv": {"string_course": true}},
	},
	# Old Town lands on the Royal Mile: tall rubble tenements with
	# crow-stepped gables and harled walls.
	"edinburgh_old": {
		"apartments": {"w": [["stone", OLD_RUBBLE], ["render", ["#d8d0c0", "#c8c0b0"]]], "p": "punched",
			"wn": "sash", "bay": 2.2, "fr": "#f4f1ea", "sp": 0.0, "r": [["gabled", 1]], "pitch": 1.1,
			"rf": [["slate", WELSH]], "fh": 3.0, "st": [6, 9], "fix": true, "ch": 0.9, "dm": 0.3,
			"g": [["shop", 1]], "rv": {"gable": "step"}},
		"commercial": {"w": [["stone", OLD_RUBBLE]], "p": "punched", "wn": "sash", "bay": 2.2,
			"r": [["gabled", 1]], "pitch": 1.1, "rf": [["slate", WELSH]], "st": [4, 7], "fix": true,
			"g": [["shop", 1]], "rv": {"gable": "step"}},
	},
	"edinburgh_modern": {
		"apartments": {"w": [["concrete", ["#c8c4bc"]], ["stone", SANDSTONE]], "p": [["strip", 2], ["balcony", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 15], "fix": true, "rv": {}},
		"commercial": {"w": [["glass", []], ["stone", SANDSTONE]], "p": [["curtain", 1], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 10], "fix": true, "rv": {}},
	},
	# Georgian Dublin (Merrion, Fitzwilliam): red-brick terraces of four
	# storeys over a basement, tall sashes, slate behind a parapet.
	"dublin": {
		"apartments": {"w": [["brick", DUBLIN_BRICK]], "p": "punched", "wn": "sash", "bay": 2.6,
			"fr": "#f4f1ea", "sp": 0.0, "r": [["flat", 2], ["gabled", 1]], "pitch": 0.5,
			"rf": [["slate", WELSH]], "fh": 3.5, "st": [4, 4], "fix": true, "ch": 0.95, "dm": 0.1,
			"g": [["stone", 1], ["shop", 1]], "ev": 0.0, "rv": {"string_course": true, "balconette": 0.15}},
		"house": {"w": [["brick", DUBLIN_BRICK]], "p": "punched", "wn": "sash", "bay": 2.6, "fr": "#f4f1ea",
			"r": [["flat", 2], ["gabled", 1]], "pitch": 0.5, "rf": [["slate", WELSH]], "fh": 3.4,
			"st": [3, 4], "fix": true, "ch": 0.95, "ev": 0.0, "rv": {"string_course": true}},
		"commercial": {"w": [["brick", DUBLIN_BRICK], ["render", ["#e8e0d0", "#d8c8a8"]]], "p": "punched",
			"wn": "sash", "r": [["flat", 1], ["gabled", 1]], "rf": [["slate", WELSH]], "st": [3, 5],
			"fix": true, "g": [["shop", 1]], "gc": ["#1e2a24", "#4a1c22", "#283040", "#2e5a3a"], "rv": {}},
	},
	"dublin_victorian": {
		"house": {"w": [["brick", DUBLIN_BRICK], ["render", ["#e8e0d0", "#d8d0c0"]]], "p": "punched", "wn": "sash",
			"bay": 2.6, "fr": "#f4f1ea", "r": [["gabled", 3], ["hipped", 1]], "pitch": 0.8,
			"rf": [["slate", WELSH]], "fh": 3.0, "st": [1, 2], "fix": true, "ch": 0.9, "rv": {"oriel": 0.3}},
	},
	"dublin_modern": {
		"apartments": {"w": [["brick", ["#8a4a3a", "#6a4a3a"]], ["glass", []]], "p": [["balcony", 2], ["strip", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 12], "fix": true, "rv": {}},
		"commercial": {"w": [["glass", []], ["stone", ["#c8c4bc"]]], "p": [["curtain", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 15], "fix": true, "rv": {}},
	},
	# Maisons de maître and Art Nouveau fronts: narrow three- and
	# four-storey houses in pale render or brick over bluestone, French
	# windows with iron balconettes, slate mansards.
	"brussels": {
		"house": {"w": [["render", BRUSSELS], ["brick", BRUSSELS_BRICK]], "p": [["punched", 3], ["ornate", 1]],
			"wn": "french", "bay": 2.2, "fr": "#f4f1ea", "sp": 0.0, "rl": 0.6,
			"r": [["mansard", 2], ["gabled", 2]], "pitch": 0.9, "rf": [["slate", WELSH]], "fh": 3.4,
			"st": [3, 4], "fix": true, "ch": 0.6, "dm": 0.5, "g": [["stone", 1]],
			"rv": {"balconette": 0.6, "string_course": true, "oriel": 0.2}},
		"apartments": {"w": [["render", BRUSSELS], ["brick", BRUSSELS_BRICK]], "p": [["punched", 3], ["ornate", 1]],
			"wn": "french", "bay": 2.4, "fr": "#f4f1ea", "rl": 0.6, "r": [["mansard", 2], ["gabled", 1]],
			"pitch": 0.9, "rf": [["slate", WELSH]], "fh": 3.3, "st": [4, 5], "fix": true, "dm": 0.5,
			"g": [["stone", 1], ["shop", 1]], "rv": {"balconette": 0.6, "string_course": true}},
		"commercial": {"w": [["render", BRUSSELS], ["limestone", ["#e8e0cc"]]], "p": [["ornate", 2], ["punched", 1]],
			"wn": "french", "r": [["mansard", 1], ["flat", 1]], "rf": [["slate", WELSH]], "st": [3, 6],
			"fix": true, "g": [["shop", 1]], "rv": {"balconette": 0.4, "string_course": true}},
	},
	# Grand-Place guild houses: Baroque stone fronts with stepped and
	# bell gables.
	"brussels_old": {
		"commercial": {"w": [["limestone", ["#d8c8a8", "#c8b898"]], ["stone", ["#a89878"]]], "p": "ornate",
			"wn": "casement", "bay": 2.0, "fr": "#f4f1ea", "r": [["gabled", 1]], "pitch": 1.4,
			"rf": [["slate", WELSH]], "fh": 3.4, "st": [3, 5], "fix": true, "g": [["shop", 1]],
			"rv": {"gable": [["step", 1], ["bell", 1]], "string_course": true}},
		"apartments": {"w": [["render", BRUSSELS], ["brick", BRUSSELS_BRICK]], "p": "punched",
			"wn": "casement", "bay": 2.0, "r": [["gabled", 1]], "pitch": 1.3, "rf": [["slate", WELSH]],
			"st": [3, 5], "fix": true, "g": [["shop", 1]], "rv": {"gable": [["step", 1], ["neck", 1]]}},
		"house": {"w": [["brick", BRUSSELS_BRICK], ["render", BRUSSELS]], "p": "punched", "wn": "casement",
			"bay": 2.0, "r": [["gabled", 1]], "pitch": 1.3, "rf": [["slate", WELSH]], "st": [2, 4],
			"fix": true, "rv": {"gable": [["step", 1], ["neck", 1]]}},
	},
	"brussels_modern": {
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc", "#b8b4ac"]]], "p": [["curtain", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 20], "fix": true, "rv": {}},
		"apartments": {"w": [["concrete", ["#c8c4bc"]], ["brick", ["#8a5a48"]]], "p": [["strip", 2], ["balcony", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 14], "fix": true, "rv": {}},
	},
	# Dokhodny doma round the courtyard wells: five- and six-storey
	# stucco in yellow, ochre, rose and mint with white trim, low painted
	# sheet-metal roofs.
	"st_petersburg": {
		"apartments": {"w": [["render", PETERSBURG]], "p": [["ornate", 2], ["punched", 2]], "wn": "casement",
			"bay": 2.6, "fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.35,
			"rf": [["slate", ["#5a6066", "#4a6a5a", "#6a3a30"]]], "fh": 3.5, "st": [5, 6], "fix": true,
			"ch": 0.3, "dm": 0.1, "g": [["none", 1], ["shop", 1]], "ev": 0.2,
			"rv": {"string_course": true, "balconette": 0.2, "quoins": true}},
		"commercial": {"w": [["render", PETERSBURG]], "p": [["ornate", 2], ["punched", 1]], "wn": "casement",
			"r": [["hipped", 1]], "pitch": 0.35, "rf": [["slate", ["#5a6066", "#4a6a5a"]]], "st": [3, 6],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "quoins": true}},
	},
	# Baroque and Empire palaces: colonnades and pediments in strong
	# stucco colours with white columns.
	"spb_imperial": {
		"apartments": {"w": [["render", PETERSBURG]], "p": "ornate", "wn": "casement", "bay": 3.0,
			"fr": "#f4f1ea", "r": [["hipped", 1]], "pitch": 0.3, "rf": [["slate", ["#5a6066", "#4a6a5a"]]],
			"fh": 4.2, "st": [2, 4], "fix": true, "rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["render", PETERSBURG]], "p": "ornate", "wn": "casement", "bay": 3.0, "fr": "#f4f1ea",
			"r": [["hipped", 1]], "pitch": 0.3, "rf": [["slate", ["#5a6066", "#4a6a5a"]]], "fh": 4.5,
			"st": [2, 4], "fix": true, "rv": {"string_course": true, "quoins": true}},
		"commercial": {"w": [["render", PETERSBURG]], "p": "ornate", "wn": "casement", "r": [["hipped", 1]],
			"pitch": 0.3, "rf": [["slate", ["#5a6066"]]], "fh": 4.0, "st": [2, 4], "fix": true,
			"rv": {"string_course": true}},
		"house": {"w": [["render", PETERSBURG]], "p": "ornate", "wn": "casement", "r": [["hipped", 1]],
			"pitch": 0.3, "rf": [["slate", ["#5a6066"]]], "st": [2, 3], "fix": true, "rv": {"string_course": true}},
	},
	"spb_soviet": {
		"apartments": {"w": [["concrete", SOVIET_PANEL]], "p": [["panel", 3], ["balcony", 1]], "wn": "wide",
			"bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.8, "st": [9, 16], "fix": true,
			"g": [["none", 1]], "rv": {"deep_balcony": 0.2}},
	},
	"spb_modern": {
		"apartments": {"w": [["concrete", ["#d8d0c0", "#c8b8a0"]], ["glass", []]], "p": [["balcony", 2], ["strip", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 25], "fix": true, "rv": {}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [10, 40], "fix": true, "rv": {}},
	},
	# Tverskoy and the Garden Ring: merchant tenements and mansions of three
	# to six storeys, ochre and peach stucco (some brick), hipped and gabled
	# roofs in painted green, red and grey sheet metal.
	"moscow": {
		"apartments": {"w": [["render", MOSCOW], ["brick", ["#9a5040", "#8a4a3a"]]], "p": [["punched", 3], ["ornate", 1]],
			"wn": "casement", "bay": 2.6, "fr": "#f4f1ea", "sp": 0.0, "r": [["hipped", 2], ["gabled", 2]],
			"pitch": 0.5, "rf": [["slate", ["#5a6066", "#4a6a5a", "#6a3a30"]]], "fh": 3.5, "st": [4, 6],
			"fix": true, "ch": 0.3, "dm": 0.1, "g": [["shop", 1], ["none", 1]], "ev": 0.2,
			"rv": {"string_course": true, "balconette": 0.2}},
		"commercial": {"w": [["render", MOSCOW]], "p": [["ornate", 2], ["punched", 1]], "wn": "casement",
			"r": [["hipped", 1], ["gabled", 1]], "pitch": 0.5, "rf": [["slate", ["#5a6066", "#4a6a5a"]]], "st": [3, 6],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true}},
	},
	# The Stalinist "wedding cake" blocks and their ring-road neighbours:
	# seven to twelve storeys of sand and buff stone-faced render, ornate
	# fronts, tall hipped roofs in grey-green sheet metal.
	"moscow_stalinka": {
		"apartments": {"w": [["render", STALINKA], ["limestone", ["#d8ccb0", "#e0d4b8"]]],
			"p": [["ornate", 3], ["punched", 2]], "wn": "casement", "bay": 2.8, "fr": "#f4f1ea",
			"r": [["hipped", 3], ["flat", 1]], "pitch": 0.35, "rf": [["slate", ["#6a7a6a", "#5a6066"]]],
			"fh": 3.6, "st": [7, 12], "fix": true, "g": [["stone", 1], ["shop", 1]],
			"rv": {"string_course": true, "quoins": true}},
		"commercial": {"w": [["limestone", ["#d8ccb0", "#e0d4b8"]]], "p": "ornate", "wn": "casement",
			"r": [["hipped", 1]], "pitch": 0.35, "rf": [["slate", ["#6a7a6a"]]], "fh": 4.0, "st": [6, 10],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "quoins": true}},
	},
	# Khrushchyovki and brezhnevki: five-storey silicate brick and the
	# nine- to sixteen-storey panel slabs, flat roofs.
	"moscow_panel": {
		"apartments": {"w": [["concrete", SOVIET_PANEL], ["brick", SILICATE]], "p": [["panel", 3], ["balcony", 1]],
			"wn": "wide", "bay": 3.0, "r": [["flat", 3], ["gabled", 1]], "pitch": 0.3, "rf": [["membrane", []]],
			"fh": 2.8, "st": [5, 16], "fix": true, "g": [["none", 1]], "rv": {"deep_balcony": 0.2}},
	},
	"moscow_city": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 4.0, "st": [20, 60], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["curtain", 2], ["balcony", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [16, 50], "fix": true, "rv": {}},
	},
	# Painted corrugated-iron and clapboard houses of the old town, one to
	# three storeys, steep gabled roofs in red, blue and green sheet metal.
	"reykjavik_iron": {
		"house": {"w": [["wood", ICELAND_IRON]], "p": "clapboard", "wn": "casement", "bay": 2.4, "fr": "#f4f1ea",
			"r": [["gabled", 4], ["hipped", 1]], "pitch": 1.0, "rf": ICELAND_ROOF, "fh": 3.0, "st": [1, 3],
			"fix": true, "ch": 0.3, "dm": 0.1, "rv": {}},
		"apartments": {"w": [["wood", ICELAND_IRON]], "p": "clapboard", "wn": "casement", "bay": 2.4,
			"fr": "#f4f1ea", "r": [["gabled", 4], ["hipped", 1]], "pitch": 1.0, "rf": ICELAND_ROOF, "fh": 3.0,
			"st": [2, 3], "fix": true, "g": [["none", 1], ["shop", 1]], "rv": {}},
		"commercial": {"w": [["wood", ICELAND_IRON]], "p": "clapboard", "wn": "casement", "bay": 2.4,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 1.0, "rf": ICELAND_ROOF, "st": [2, 3], "fix": true,
			"g": [["shop", 1]], "rv": {}},
	},
	# The post-war city: grey and cream rendered concrete houses and blocks
	# of two to five storeys, flat and low gabled roofs in coloured sheet metal.
	"reykjavik": {
		"house": {"w": [["render", ["#e8e0d0", "#d8d0c0", "#c8d0d0", "#e8d8c0"]]], "p": [["punched", 3], ["strip", 1]],
			"wn": "casement", "bay": 2.8, "fr": "#f4f1ea", "r": [["flat", 2], ["gabled", 2]], "pitch": 0.5,
			"rf": ICELAND_ROOF, "fh": 2.9, "st": [1, 2], "fix": true, "rv": {}},
		"apartments": {"w": [["render", ["#e8e0d0", "#d8d0c0", "#c8d0d0"]], ["concrete", ["#c8c4bc"]]],
			"p": [["punched", 3], ["strip", 1]], "wn": "wide", "bay": 3.0, "r": [["flat", 2], ["gabled", 1]],
			"pitch": 0.5, "rf": ICELAND_ROOF, "fh": 2.9, "st": [3, 5], "fix": true, "rv": {"deep_balcony": 0.2}},
	},
	"reykjavik_modern": {
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc"]]], "p": [["curtain", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 12], "fix": true, "rv": {}},
		"apartments": {"w": [["render", ["#ece8dc", "#d8d4cc"]], ["glass", []]], "p": [["balcony", 2], ["strip", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 10], "fix": true, "rv": {"deep_balcony": 0.3}},
	},
}
