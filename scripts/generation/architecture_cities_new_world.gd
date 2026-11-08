class_name ArchitectureCitiesNewWorld
extends RefCounted

## American and Australian city rows (CityStyles zones) and their era
## rows (BuildingEra): Toronto, Montreal, Boston, Washington, Los Angeles,
## Mexico City, Rio de Janeiro, Buenos Aires, Sydney, Melbourne. City
## rows inherit from their country row; eras from their city. Same key
## legend as ArchitectureData; `rv` = 3D relief (replaces the parent's).
## ERAS rows carry a storey band and a heritage flag
## (BuildingEra._banded); an era without a band is reached only by its
## year, style tag or district.

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]

const ASPHALT := [["slate", ["#4a4e54", "#5a5e62", "#3e4248"]]]
const TERRA := ["#b5542f", "#a8482a", "#c0643a", "#9a4a2c"]
## Toronto bay-and-gables: red and buff (yellow) brick.
const ONTARIO_BRICK := ["#9c4a35", "#a8553a", "#c8b088", "#b8a078", "#8a3f30"]
## Montreal plex brick and greystone.
const PLEX_BRICK := ["#8a3f30", "#9c4a35", "#7a3a2a", "#a86048"]
const GREYSTONE := ["#a8a49a", "#b8b4aa", "#98948a"]
## Boston brick and Back Bay brownstone.
const BOSTON_BRICK := ["#8a3f30", "#9c4a35", "#7a3a2a"]
const BROWNSTONE := ["#6a4a38", "#7a5640", "#5e4232"]
## Washington rowhouse paint and federal limestone.
const DC_ROW := ["#9c4a35", "#e8d8c0", "#c8d8e0", "#e8c8a0", "#d8e0c8", "#8a3f30", "#f0e8d8"]
const FEDERAL := ["#e0d8c8", "#d8d0c0", "#e8e0d0"]
## Los Angeles stucco: white, cream, sand, pastel.
const LA_STUCCO := ["#f2efe8", "#ece0c8", "#e8d8b8", "#e8c8b0", "#d8e0d8", "#f0e0c0"]
## Mexico City: tezontle red stone, chiluca grey, colonial render.
const TEZONTLE := ["#7a3a32", "#8a4038", "#6a342e"]
const CDMX := ["#e8c8a0", "#e0a890", "#f0dcc0", "#c8d8c8", "#e8b8a8", "#d8a878", "#f2ede0"]
## Rio: Copacabana whites and creams; Centro colonial pastels.
const COPACABANA := ["#f2efe8", "#ece6da", "#e8e0d0", "#e0d8c8", "#d8d4cc"]
const CARIOCA := ["#e8c060", "#e8a890", "#a8c8d8", "#f2ede0", "#c8d8b8", "#e8d0a0"]
## Buenos Aires: French academic stone and render, casas chorizo pastels.
const PORTENO := ["#d8ccb0", "#e0d4bc", "#c8bca0", "#e8dcc4", "#b8ac90"]
const CHORIZO := ["#e8d8b8", "#d8c0a8", "#c8d0c0", "#e8c8a8", "#f0e8d8"]
## Sydney sandstone and the terraces' render and brick.
const SYDNEY_SANDSTONE := ["#d0b080", "#c8a878", "#d8b888", "#b89868"]
const TERRACE := ["#e8e0d0", "#d8c8b0", "#c8d0c8", "#9c4a35", "#e8d0b8", "#d0c0a8"]
const MELB_BRICK := ["#9c4a35", "#7a5a48", "#c8b088", "#8a3f30"]
const BLUESTONE := ["#5a5e62", "#4e5256", "#666a6e"]
const CORRUGATED := [["slate", ["#8a8e90", "#7a7e80", "#6a3a2e"]]]
## Havana: sun-faded pastel stucco (pink, mint, yellow, sky, coral, cream).
const HAVANA := ["#e8b8c0", "#a8d8c8", "#e8d080", "#a8c8e0", "#f0d8b0", "#e8a890", "#c8d8a8"]
const SOVIET_PANEL_CU := ["#c8c4bc", "#d8d4cc", "#b8b4ac"]

const BASE := {
	"toronto": "north_america", "toronto_victorian": "toronto", "toronto_tower": "toronto",
	"montreal": "north_america", "montreal_old": "montreal", "montreal_tower": "montreal",
	"boston": "north_america", "boston_backbay": "boston", "boston_tripledecker": "boston",
	"boston_tower": "boston",
	"washington": "north_america", "washington_federal": "washington", "washington_modern": "washington",
	"los_angeles": "north_america", "la_spanish": "los_angeles", "la_tower": "los_angeles",
	"mexico_city": "latin_america", "cdmx_colonial": "mexico_city", "cdmx_modern": "mexico_city",
	"rio": "latin_america", "rio_colonial": "rio", "rio_tower": "rio",
	"buenos_aires": "latin_america", "ba_chorizo": "buenos_aires", "ba_tower": "buenos_aires",
	"sydney": "australia", "sydney_terrace": "sydney", "sydney_tower": "sydney",
	"melbourne": "australia", "melbourne_terrace": "melbourne", "melbourne_tower": "melbourne",
	"havana": "latin_america", "havana_colonial": "havana", "havana_soviet": "havana",
}

## [era, kinds, from, to, building:architecture, weight, km from, km to,
## (storey band), (heritage era)] (BuildingEra.ERAS).
const ERAS := {
	"toronto": [
		["toronto_victorian", HAC, 1850, 1929, ["victorian", "bay_and_gable", "edwardian",
			"romanesque_revival", "queen_anne"], 5.0, 0.0, 99.0, [1, 3], true],
		["toronto", AC, 1930, 1999, [], 2.0, 0.0, 99.0, [4, 14]],
		["toronto_tower", ACC, 1990, 2100, [], 2.0, 0.0, 99.0, [15, 99]],
	],
	"montreal": [
		["montreal_old", ALL, 1680, 1880, ["french_regime", "neoclassicism", "victorian",
			"second_empire", "greystone"], 0.8, 0.0, 1.5, [2, 6], true],
		["montreal", HAC, 1881, 1959, ["plex", "triplex", "duplex", "edwardian", "art_deco"],
			5.0, 0.0, 99.0, [1, 3]],
		["montreal_tower", ACC, 1960, 2100, [], 1.5, 0.0, 99.0, [7, 99]],
	],
	"boston": [
		["boston_backbay", HAC, 1800, 1899, ["federal", "greek_revival", "victorian",
			"second_empire", "brownstone", "rowhouse", "italianate"], 3.0, 0.0, 3.0, [3, 5], true],
		["boston_tripledecker", ["house", "apartments"], 1880, 1930, ["triple_decker",
			"three_decker", "queen_anne"], 2.0, 2.5, 99.0, [3, 3]],
		["boston", HAC, 1900, 1999, [], 3.0, 0.0, 99.0, [1, 8]],
		["boston_tower", ACC, 1960, 2100, [], 1.0, 0.0, 99.0, [9, 99]],
	],
	"washington": [
		["washington_federal", ["civic", "commercial"], 1790, 1959, ["neoclassicism", "beaux_arts",
			"federal", "greek_revival", "classical_revival"], 1.0, 0.0, 3.0],
		["washington", HAC, 1850, 1949, ["victorian", "rowhouse", "romanesque_revival",
			"italianate", "federal"], 5.0, 0.0, 99.0, [1, 4], true],
		["washington_modern", ACC, 1950, 2100, [], 2.0, 0.0, 99.0, [5, 99]],
	],
	"los_angeles": [
		["la_spanish", HAC, 1915, 1945, ["spanish_colonial_revival", "mission_revival",
			"mediterranean_revival", "craftsman", "art_deco"], 2.0, 0.0, 99.0],
		["los_angeles", HAC, 1946, 2100, ["dingbat", "mid_century_modern", "ranch",
			"modernism"], 5.0, 0.0, 99.0, [1, 6]],
		["la_tower", ACC, 1960, 2100, [], 1.0, 0.0, 99.0, [7, 99]],
	],
	"mexico_city": [
		["cdmx_colonial", ALL, 1521, 1880, ["colonial", "baroque", "churrigueresque",
			"neoclassicism", "viceregal"], 1.0, 0.0, 1.5, [1, 4], true],
		["mexico_city", HAC, 1881, 1979, ["porfirian", "art_deco", "art_nouveau", "functionalism",
			"neocolonial", "eclectic"], 5.0, 0.0, 99.0, [1, 7]],
		["cdmx_modern", ACC, 1980, 2100, [], 1.0, 0.0, 99.0, [8, 99]],
	],
	"rio": [
		["rio_colonial", ALL, 1600, 1899, ["colonial", "portuguese_colonial", "neoclassicism",
			"imperial", "eclectic"], 1.0, 0.0, 2.0, [1, 4], true],
		["rio", AC, 1930, 1979, ["art_deco", "modernism", "modernist", "brazilian_modernism"],
			5.0, 0.0, 99.0, [5, 14]],
		["rio_tower", ACC, 1980, 2100, [], 1.0, 0.0, 99.0, [15, 99]],
	],
	"buenos_aires": [
		["ba_chorizo", ["house", "commercial"], 1860, 1940, ["casa_chorizo", "italianate",
			"vernacular"], 2.0, 0.0, 99.0, [1, 2], true],
		["buenos_aires", AC, 1880, 1969, ["beaux_arts", "academic", "french_academic",
			"eclectic", "art_nouveau", "art_deco", "rationalism"], 5.0, 0.0, 99.0, [3, 12]],
		["ba_tower", ACC, 1970, 2100, [], 1.0, 0.0, 99.0, [13, 99]],
	],
	"sydney": [
		["sydney_terrace", HAC, 1840, 1914, ["victorian", "georgian", "terrace",
			"italianate", "federation"], 3.0, 0.0, 6.0, [1, 3], true],
		["sydney", HAC, 1915, 1989, ["federation", "inter_war", "art_deco", "functionalism"],
			4.0, 0.0, 99.0, [1, 8]],
		["sydney_tower", ACC, 1960, 2100, [], 1.5, 0.0, 99.0, [9, 99]],
	],
	"melbourne": [
		["melbourne_terrace", HAC, 1850, 1914, ["victorian", "boom_style", "italianate",
			"terrace", "federation"], 4.0, 0.0, 7.0, [1, 3], true],
		["melbourne", HAC, 1915, 1989, ["inter_war", "art_deco", "edwardian", "functionalism"],
			3.0, 0.0, 99.0, [1, 8]],
		["melbourne_tower", ACC, 1960, 2100, [], 1.5, 0.0, 99.0, [9, 99]],
	],
	"havana": [
		["havana_colonial", ALL, 1519, 1899, ["spanish_colonial", "colonial", "baroque",
			"neoclassicism", "cuban_baroque"], 1.5, 0.0, 2.0, [1, 3], true],
		["havana", HAC, 1900, 1959, ["art_deco", "eclectic", "neoclassicism", "modernism",
			"art_nouveau", "beaux_arts"], 5.0, 0.0, 99.0, [2, 6]],
		["havana_soviet", APT, 1960, 1991, ["soviet_modernism", "prefab", "microbrigada",
			"socialist_modernism"], 2.0, 4.0, 99.0, [5, 12]],
	],
}

const REGIONS := {
	# Mid-century and interwar Toronto: brick apartment blocks and
	# commercial strips of four to fourteen storeys.
	"toronto": {
		"apartments": {"w": [["brick", ONTARIO_BRICK], ["concrete", ["#c8c4bc"]]], "p": [["punched", 3], ["balcony", 2]],
			"wn": "wide", "bay": 3.0, "fr": "#8a8c8e", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [5, 12], "fix": true, "eq": 0.5, "g": [["none", 2], ["shop", 1]], "rv": {"deep_balcony": 0.3}},
		"commercial": {"w": [["brick", ONTARIO_BRICK], ["glass", []]], "p": [["punched", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 4], "fix": true, "g": [["shop", 1]],
			"rv": {"signage": 0.3, "awning": 0.3, "awning_colours": ["#1f3b2c", "#7a1f24", "#1a3a6a"]}},
	},
	# Bay-and-gable houses (the Annex, Cabbagetown): two and a half
	# storeys of red or buff brick, a bay window under a steep front gable.
	"toronto_victorian": {
		"house": {"w": [["brick", ONTARIO_BRICK]], "p": "punched", "wn": "sash", "bay": 2.6, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["gabled", 5], ["hipped", 1]], "pitch": 1.2, "rf": ASPHALT, "fh": 3.0,
			"st": [2, 3], "fix": true, "ch": 0.7, "dm": 0.3, "ev": 0.3, "rv": {"oriel": 0.6, "stoop": 0.3}},
		"commercial": {"w": [["brick", ONTARIO_BRICK]], "p": "punched", "wn": "sash", "fr": "#f4f1ea",
			"r": [["flat", 2], ["gabled", 1]], "rf": ASPHALT, "st": [2, 3], "fix": true, "g": [["shop", 1]],
			"rv": {"awning": 0.4, "awning_colours": ["#1f3b2c", "#7a1f24", "#1a3a6a"]}},
		"apartments": {"w": [["brick", ONTARIO_BRICK]], "p": "punched", "wn": "sash", "r": [["gabled", 2], ["flat", 1]],
			"pitch": 1.0, "rf": ASPHALT, "st": [3, 3], "fix": true, "rv": {"oriel": 0.4}},
	},
	"toronto_tower": {
		"apartments": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["curtain", 3], ["balcony", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [25, 60], "fix": true,
			"rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 4.0, "st": [20, 70], "fix": true, "rv": {}},
	},
	# Plexes (the Plateau, Rosemont): two- and three-storey brick
	# walk-ups with outside iron staircases and balconies, flat roofs
	# behind a cornice.
	"montreal": {
		"apartments": {"w": [["brick", PLEX_BRICK], ["stone", GREYSTONE]], "p": "punched", "wn": "casement",
			"bay": 2.6, "fr": "#f4f1ea", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0,
			"st": [2, 3], "fix": true, "ch": 0.2, "g": [["none", 1]],
			"rv": {"deep_balcony": 0.8, "fire_escape": 0.5, "string_course": true}},
		"house": {"w": [["brick", PLEX_BRICK], ["stone", GREYSTONE]], "p": "punched", "wn": "casement", "fr": "#f4f1ea",
			"r": [["flat", 2], ["mansard", 1]], "rf": [["membrane", []]] + ASPHALT, "st": [2, 3], "fix": true,
			"rv": {"deep_balcony": 0.7, "fire_escape": 0.4}},
		"commercial": {"w": [["brick", PLEX_BRICK]], "p": "punched", "wn": "casement", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [2, 3], "fix": true, "g": [["shop", 1]], "rv": {"signage": 0.3}},
	},
	# Vieux-Montréal: grey limestone warehouses and Second Empire fronts,
	# steep tin and slate roofs.
	"montreal_old": {
		"commercial": {"w": [["stone", GREYSTONE]], "p": [["punched", 2], ["ornate", 1]], "wn": "casement",
			"bay": 2.8, "fr": "#f4f1ea", "r": [["mansard", 2], ["gabled", 1], ["flat", 1]], "pitch": 1.0,
			"rf": [["slate", ["#8a8e90", "#5a626b"]]], "fh": 3.6, "st": [3, 6], "fix": true, "dm": 0.6,
			"g": [["shop", 1]], "rv": {"string_course": true}},
		"apartments": {"w": [["stone", GREYSTONE]], "p": "punched", "wn": "casement", "r": [["mansard", 1], ["gabled", 1]],
			"pitch": 1.0, "rf": [["slate", ["#8a8e90", "#5a626b"]]], "st": [3, 5], "fix": true, "dm": 0.6,
			"rv": {"string_course": true}},
	},
	"montreal_tower": {
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc"]]], "p": [["curtain", 3], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [10, 45], "fix": true, "rv": {}},
		"apartments": {"w": [["concrete", ["#c8c4bc"]], ["glass", []]], "p": [["balcony", 2], ["strip", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 30], "fix": true, "rv": {}},
	},
	"boston": {
		"apartments": {"w": [["brick", BOSTON_BRICK]], "p": "punched", "wn": "sash", "bay": 2.6, "fr": "#f4f1ea",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 6], "fix": true, "g": [["none", 2], ["shop", 1]],
			"rv": {"string_course": true}},
		"commercial": {"w": [["brick", BOSTON_BRICK], ["stone", ["#c8c0b0"]]], "p": "punched", "wn": "sash",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 6], "fix": true, "g": [["shop", 1]], "rv": {}},
	},
	# Back Bay and Beacon Hill: brick and brownstone rowhouses of four
	# storeys, bow fronts, mansards, stoops and black shutters.
	"boston_backbay": {
		"house": {"w": [["brick", BOSTON_BRICK], ["stone", BROWNSTONE]], "p": [["punched", 3], ["brownstone", 1]],
			"wn": "sash", "bay": 2.4, "fr": "#f4f1ea", "sh": "#1e2a24", "sp": 0.4,
			"r": [["mansard", 2], ["flat", 2]], "pitch": 1.0, "rf": [["slate", ["#4f5760", "#5a626b"]]],
			"fh": 3.3, "st": [4, 4], "fix": true, "ch": 0.8, "dm": 0.6,
			"rv": {"oriel": 0.5, "stoop": 0.6, "string_course": true}},
		"apartments": {"w": [["brick", BOSTON_BRICK], ["stone", BROWNSTONE]], "p": [["punched", 2], ["brownstone", 1]],
			"wn": "sash", "bay": 2.4, "fr": "#f4f1ea", "sh": "#1e2a24", "sp": 0.4, "r": [["mansard", 1], ["flat", 1]],
			"rf": [["slate", ["#4f5760"]]], "st": [4, 5], "fix": true, "dm": 0.5, "rv": {"oriel": 0.5, "stoop": 0.5}},
	},
	# Triple-deckers (Dorchester, Somerville): three stacked flats in
	# painted clapboard with full-width porches front and back.
	"boston_tripledecker": {
		"house": {"w": [["wood", ["#e8e2d4", "#c8d0d0", "#d8c8a8", "#a8b8c0", "#c8b8a8"]]], "p": "clapboard",
			"wn": "sash", "bay": 2.6, "fr": "#f4f1ea", "r": [["flat", 2], ["gabled", 2]], "pitch": 0.8,
			"rf": ASPHALT, "fh": 3.0, "st": [3, 3], "fix": true, "rv": {"deep_balcony": 0.9}},
		"apartments": {"w": [["wood", ["#e8e2d4", "#c8d0d0", "#d8c8a8"]]], "p": "clapboard", "wn": "sash",
			"r": [["flat", 1], ["gabled", 1]], "rf": ASPHALT, "st": [3, 3], "fix": true, "rv": {"deep_balcony": 0.9}},
	},
	"boston_tower": {
		"commercial": {"w": [["glass", []], ["stone", ["#c8c0b0"]]], "p": [["curtain", 3], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 60], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["brick", BOSTON_BRICK]], "p": [["curtain", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [10, 40], "fix": true, "rv": {}},
	},
	# Capitol Hill and Dupont Circle rowhouses: two to four storeys of
	# brick and painted brick, turrets and bays, under a 130 ft height cap.
	"washington": {
		"house": {"w": [["brick", DC_ROW]], "p": "punched", "wn": "sash", "bay": 2.4, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["flat", 3], ["mansard", 1]], "rf": [["membrane", []], ["slate", ["#4f5760"]]], "fh": 3.2,
			"st": [2, 3], "fix": true, "ch": 0.4, "rv": {"oriel": 0.6, "stoop": 0.5, "string_course": true}},
		"apartments": {"w": [["brick", DC_ROW], ["limestone", FEDERAL]], "p": [["punched", 3], ["ornate", 1]],
			"wn": "sash", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 8], "fix": true,
			"rv": {"oriel": 0.3, "string_course": true}},
		"commercial": {"w": [["limestone", FEDERAL], ["brick", DC_ROW]], "p": [["punched", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 8], "fix": true, "g": [["shop", 1]], "rv": {}},
	},
	"washington_federal": {
		"civic": {"w": [["limestone", FEDERAL]], "p": "ornate", "wn": "sash", "bay": 3.4, "fr": "#3a3d42",
			"r": [["flat", 3], ["dome", 1]], "rf": [["membrane", []]], "fh": 4.8, "st": [3, 7], "fix": true,
			"g": [["stone", 1]], "rv": {"string_course": true}},
		"commercial": {"w": [["limestone", FEDERAL]], "p": "ornate", "wn": "sash", "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 4.2, "st": [5, 10], "fix": true, "g": [["stone", 1]],
			"rv": {"string_course": true}},
	},
	"washington_modern": {
		"commercial": {"w": [["glass", []], ["limestone", FEDERAL]], "p": [["strip", 3], ["curtain", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 12], "fix": true, "rv": {}},
		"apartments": {"w": [["brick", ["#8a5a48", "#b8a088"]], ["glass", []]], "p": [["balcony", 2], ["strip", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [6, 12], "fix": true, "rv": {}},
	},
	# Post-war Los Angeles: stucco dingbats over carports, ranch houses,
	# palms; low and wide.
	"los_angeles": {
		"house": {"w": [["render", LA_STUCCO]], "p": "punched", "wn": "wide", "bay": 3.4, "fr": "#8a8c8e",
			"sp": 0.0, "r": [["hipped", 3], ["gabled", 2], ["flat", 1]], "pitch": 0.45,
			"rf": ASPHALT + [["terracotta", TERRA]], "fh": 2.9, "st": [1, 2], "fix": true, "ch": 0.1,
			"eq": 0.3, "ev": 0.6, "rv": {}},
		"apartments": {"w": [["render", LA_STUCCO]], "p": [["punched", 2], ["strip", 2]], "wn": "wide",
			"bay": 3.4, "fr": "#8a8c8e", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.9,
			"st": [2, 4], "fix": true, "eq": 0.5, "g": [["none", 1]], "rv": {"deep_balcony": 0.3}},
		"commercial": {"w": [["render", LA_STUCCO], ["glass", []]], "p": [["strip", 2], ["punched", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [1, 3], "fix": true, "g": [["shop", 1]],
			"rv": {"signage": 0.3, "awning": 0.2, "awning_colours": ["#7a1f24", "#1a3a6a", "#c8a24a"]}},
	},
	# Spanish Colonial and Mission Revival (Hollywood, Silver Lake,
	# Pasadena): white stucco, red barrel tile, arches, wrought iron.
	"la_spanish": {
		"house": {"w": [["render", ["#f2efe8", "#ece0c8", "#f0e8d8"]]], "p": "punched", "wn": "casement",
			"bay": 3.0, "fr": "#3a2a20", "sp": 0.0, "rl": 0.3, "r": [["gabled", 2], ["hipped", 2], ["flat", 1]],
			"pitch": 0.45, "rf": [["terracotta", TERRA]], "fh": 3.0, "st": [1, 2], "fix": true, "ch": 0.3,
			"ev": 0.4, "rv": {"balconette": 0.3}},
		"apartments": {"w": [["render", ["#f2efe8", "#ece0c8"]]], "p": "punched", "wn": "casement", "fr": "#3a2a20",
			"rl": 0.4, "r": [["hipped", 1], ["flat", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]],
			"st": [2, 4], "fix": true, "rv": {"balconette": 0.4}},
		"commercial": {"w": [["render", ["#f2efe8", "#ece0c8"]]], "p": "punched", "wn": "casement",
			"r": [["hipped", 1], ["flat", 1]], "pitch": 0.45, "rf": [["terracotta", TERRA]], "st": [1, 3],
			"fix": true, "g": [["shop", 1]], "rv": {"awning": 0.3, "awning_colours": ["#7a1f24", "#1f3b2c"]}},
	},
	"la_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 4.0, "st": [15, 70], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["render", LA_STUCCO]], "p": [["curtain", 2], ["balcony", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 35], "fix": true, "rv": {}},
	},
	# Roma, Condesa, Juárez: Porfirian and Art Deco apartment houses of
	# two to seven storeys, pastel render, iron balconies, flat roofs with
	# water tanks.
	"mexico_city": {
		"apartments": {"w": [["render", CDMX]], "p": [["punched", 3], ["ornate", 1], ["balcony", 1]],
			"wn": "french", "bay": 2.8, "fr": "#3a3d42", "sp": 0.0, "rl": 0.6, "r": [["flat", 1]],
			"rf": [["concrete", ["#c8c0b0", "#b8b0a0"]]], "fh": 3.3, "st": [3, 6], "fix": true, "ch": 0.0,
			"eq": 0.85, "g": [["shop", 2], ["none", 1]], "ev": 0.0,
			"rv": {"balconette": 0.6, "string_course": true, "awning": 0.2,
				"awning_colours": ["#7a1f24", "#1f3b2c", "#c8a24a"]}},
		"house": {"w": [["render", CDMX]], "p": "punched", "wn": "french", "fr": "#3a3d42", "rl": 0.4,
			"r": [["flat", 1]], "rf": [["concrete", ["#c8c0b0"]]], "st": [1, 2], "fix": true, "eq": 0.8,
			"rv": {"balconette": 0.4}},
		"commercial": {"w": [["render", CDMX], ["concrete", ["#c8c4bc"]]], "p": [["punched", 2], ["strip", 1]],
			"wn": "french", "r": [["flat", 1]], "rf": [["concrete", ["#c8c0b0"]]], "st": [2, 5], "fix": true,
			"g": [["shop", 1]], "rv": {"signage": 0.4}},
	},
	# The Centro Histórico: tezontle and chiluca stone palaces, Baroque
	# portals, two to four storeys round patios.
	"cdmx_colonial": {
		"commercial": {"w": [["stone", TEZONTLE], ["render", CDMX]], "p": "ornate", "wn": "french", "bay": 3.0,
			"fr": "#3a2a20", "rl": 0.8, "r": [["flat", 1]], "rf": [["concrete", ["#b8b0a0"]]], "fh": 4.0,
			"st": [2, 3], "fix": true, "g": [["shop", 1]], "rv": {"balconette": 0.8, "string_course": true, "quoins": true}},
		"apartments": {"w": [["stone", TEZONTLE], ["render", CDMX]], "p": "ornate", "wn": "french", "fr": "#3a2a20",
			"rl": 0.8, "r": [["flat", 1]], "rf": [["concrete", ["#b8b0a0"]]], "fh": 4.0, "st": [2, 4], "fix": true,
			"rv": {"balconette": 0.8, "string_course": true}},
		"civic": {"w": [["stone", TEZONTLE]], "p": "ornate", "wn": "french", "r": [["flat", 1], ["dome", 1]],
			"rf": [["concrete", ["#b8b0a0"]]], "st": [2, 3], "fix": true, "rv": {"string_course": true}},
	},
	"cdmx_modern": {
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc"]]], "p": [["curtain", 3], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [10, 55], "fix": true, "rv": {}},
		"apartments": {"w": [["concrete", ["#d8d0c0"]], ["glass", []]], "p": [["balcony", 2], ["strip", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 25], "fix": true, "rv": {}},
	},
	# Copacabana and Ipanema: ten- to fourteen-storey Art Deco and
	# modernist slabs in white and cream, a balcony on every flat, on
	# pilotis behind the beach.
	"rio": {
		"apartments": {"w": [["render", COPACABANA], ["concrete", ["#e0d8c8"]]], "p": [["balcony", 4], ["strip", 1]],
			"wn": "wide", "bay": 3.0, "fr": "#8a8c8e", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.9, "st": [8, 14], "fix": true, "ch": 0.0, "eq": 0.6, "g": [["shop", 1], ["none", 1]],
			"ev": 0.0, "rv": {"deep_balcony": 0.8}},
		"commercial": {"w": [["render", COPACABANA], ["glass", []]], "p": [["strip", 2], ["balcony", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 12], "fix": true,
			"g": [["shop", 1]], "rv": {"signage": 0.2}},
	},
	# Centro and Lapa: colonial and imperial two- to four-storey fronts in
	# pastel render, iron balconies, terracotta.
	"rio_colonial": {
		"commercial": {"w": [["render", CARIOCA]], "p": [["punched", 2], ["ornate", 1]], "wn": "french", "bay": 2.6,
			"fr": "#f4f1ea", "rl": 0.8, "r": [["hipped", 2], ["flat", 1]], "pitch": 0.5,
			"rf": [["terracotta", TERRA]], "fh": 3.6, "st": [2, 3], "fix": true, "g": [["shop", 1]],
			"rv": {"balconette": 0.8, "string_course": true}},
		"apartments": {"w": [["render", CARIOCA]], "p": "punched", "wn": "french", "fr": "#f4f1ea", "rl": 0.8,
			"r": [["hipped", 1]], "pitch": 0.5, "rf": [["terracotta", TERRA]], "st": [2, 4], "fix": true,
			"rv": {"balconette": 0.8}},
		"house": {"w": [["render", CARIOCA]], "p": "punched", "wn": "french", "rl": 0.6, "r": [["hipped", 1]],
			"pitch": 0.5, "rf": [["terracotta", TERRA]], "st": [1, 2], "fix": true, "rv": {"balconette": 0.5}},
	},
	"rio_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [15, 45], "fix": true, "rv": {}},
		"apartments": {"w": [["render", COPACABANA], ["glass", []]], "p": [["balcony", 3], ["curtain", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 30], "fix": true,
			"rv": {"deep_balcony": 0.6}},
	},
	# French academic Buenos Aires (Recoleta, Avenida de Mayo): five to
	# ten storeys of stone and render, French windows with balconettes,
	# slate mansards and corner domes.
	"buenos_aires": {
		"apartments": {"w": [["limestone", PORTENO], ["render", PORTENO]], "p": [["ornate", 3], ["punched", 2]],
			"wn": "french", "bay": 2.6, "fr": "#5a4a3a", "sh": "#4a4e52", "sp": 0.6, "rl": 0.8,
			"r": [["flat", 3], ["mansard", 2], ["dome", 1]], "pitch": 0.9, "rf": [["slate", ["#4f5760", "#5a626b"]]],
			"fh": 3.4, "st": [6, 9], "fix": true, "ch": 0.1, "dm": 0.4, "g": [["shop", 1], ["stone", 1]],
			"rv": {"balconette": 0.8, "string_course": true}},
		"commercial": {"w": [["limestone", PORTENO]], "p": "ornate", "wn": "french", "rl": 0.6,
			"r": [["mansard", 1], ["flat", 1], ["dome", 1]], "rf": [["slate", ["#4f5760"]]], "st": [5, 9],
			"fix": true, "g": [["shop", 1]], "rv": {"balconette": 0.6, "string_course": true}},
	},
	# Casas chorizo (San Telmo, Palermo): one- and two-storey Italianate
	# fronts in pastel render behind a parapet, tall shuttered windows.
	"ba_chorizo": {
		"house": {"w": [["render", CHORIZO]], "p": "punched", "wn": "french", "bay": 2.6, "fr": "#5a4a3a",
			"sh": ["#3f5a3a", "#4a4e52", "#6a5040"], "sp": 0.9, "rl": 0.4, "r": [["flat", 1]],
			"rf": [["concrete", ["#c8c0b0"]]], "fh": 4.0, "st": [1, 2], "fix": true, "ev": 0.0,
			"rv": {"balconette": 0.3, "string_course": true}},
		"commercial": {"w": [["render", CHORIZO]], "p": "punched", "wn": "french", "sh": "#3f5a3a", "sp": 0.6,
			"r": [["flat", 1]], "rf": [["concrete", ["#c8c0b0"]]], "fh": 4.0, "st": [1, 2], "fix": true,
			"g": [["shop", 1]], "rv": {"string_course": true}},
	},
	"ba_tower": {
		"apartments": {"w": [["concrete", ["#d8d0c0", "#e0d8c8"]], ["glass", []]], "p": [["balcony", 3], ["strip", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [13, 35], "fix": true,
			"rv": {"deep_balcony": 0.6}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [15, 45], "fix": true, "rv": {}},
	},
	# Interwar Sydney: red-brick walk-up flats and Federation houses with
	# terracotta roofs.
	"sydney": {
		"apartments": {"w": [["brick", ["#9c4a35", "#8a3f30", "#a8604a", "#6a3a2a"]]], "p": "punched", "wn": "casement",
			"bay": 3.0, "fr": "#f4f1ea", "r": [["hipped", 2], ["flat", 1]], "pitch": 0.5,
			"rf": [["terracotta", TERRA]], "st": [3, 4], "fix": true, "rv": {"deep_balcony": 0.3}},
		"house": {"w": [["brick", ["#9c4a35", "#8a3f30", "#a8604a"]]], "p": "punched", "wn": "casement",
			"fr": "#f4f1ea", "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.6, "rf": [["terracotta", TERRA]],
			"st": [1, 1], "fix": true, "ev": 0.5, "rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["stone", SYDNEY_SANDSTONE], ["brick", ["#9c4a35"]]], "p": [["punched", 2], ["ornate", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 6], "fix": true, "g": [["shop", 1]],
			"rv": {"string_course": true, "awning": 0.4, "awning_colours": ["#1f3b2c", "#7a1f24"]}},
	},
	# Victorian terraces (Paddington, Glebe, Surry Hills): two storeys of
	# render or brick, cast-iron lace verandahs, corrugated iron roofs.
	"sydney_terrace": {
		"house": {"w": [["render", TERRACE], ["brick", ["#9c4a35"]]], "p": "punched", "wn": "french", "bay": 2.4,
			"fr": "#f4f1ea", "sh": "#3f5a3a", "sp": 0.3, "rl": 0.6, "r": [["gabled", 2], ["skillion", 1], ["hipped", 1]],
			"pitch": 0.5, "rf": CORRUGATED + [["slate", ["#4f5760"]]], "fh": 3.2, "st": [2, 2], "fix": true,
			"ch": 0.6, "ev": 0.2, "rv": {"deep_balcony": 0.9, "balconette": 0.4}},
		"commercial": {"w": [["render", TERRACE], ["stone", SYDNEY_SANDSTONE]], "p": "punched", "wn": "french",
			"rl": 0.5, "r": [["flat", 1], ["gabled", 1]], "rf": CORRUGATED, "st": [2, 3], "fix": true,
			"g": [["shop", 1]], "rv": {"deep_balcony": 0.7}},
		"apartments": {"w": [["render", TERRACE]], "p": "punched", "wn": "french", "rl": 0.5, "r": [["gabled", 1]],
			"pitch": 0.5, "rf": CORRUGATED, "st": [2, 3], "fix": true, "rv": {"deep_balcony": 0.8}},
	},
	"sydney_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 4.0, "st": [15, 60], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", ["#e8e4dc"]]], "p": [["balcony", 3], ["curtain", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [10, 40], "fix": true,
			"rv": {"deep_balcony": 0.6}},
	},
	"melbourne": {
		"apartments": {"w": [["brick", MELB_BRICK]], "p": "punched", "wn": "casement", "bay": 3.0, "fr": "#f4f1ea",
			"r": [["hipped", 2], ["flat", 1]], "pitch": 0.5, "rf": [["terracotta", TERRA]], "st": [2, 4],
			"fix": true, "rv": {}},
		"house": {"w": [["brick", MELB_BRICK], ["wood", ["#e8e2d4", "#c8d0c8"]]], "p": "punched", "wn": "casement",
			"fr": "#f4f1ea", "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.6,
			"rf": [["terracotta", TERRA]] + CORRUGATED, "st": [1, 1], "fix": true, "ev": 0.5,
			"rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["stone", BLUESTONE], ["brick", MELB_BRICK], ["render", TERRACE]],
			"p": [["punched", 2], ["ornate", 1]], "r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 6],
			"fix": true, "g": [["shop", 1]], "rv": {"string_course": true, "awning": 0.4,
				"awning_colours": ["#1f3b2c", "#7a1f24"]}},
	},
	# Boom-style terraces (Fitzroy, Carlton): two storeys of polychrome
	# brick or render on bluestone, iron lace, corrugated iron and slate.
	"melbourne_terrace": {
		"house": {"w": [["brick", MELB_BRICK], ["render", TERRACE]], "p": [["punched", 2], ["ornate", 1]],
			"wn": "french", "bay": 2.4, "fr": "#f4f1ea", "rl": 0.6, "r": [["hipped", 2], ["skillion", 1]],
			"pitch": 0.5, "rf": CORRUGATED + [["slate", ["#4f5760"]]], "fh": 3.3, "st": [1, 2], "fix": true,
			"ch": 0.6, "g": [["stone", 1]], "rv": {"deep_balcony": 0.9, "balconette": 0.4, "string_course": true}},
		"commercial": {"w": [["render", TERRACE], ["brick", MELB_BRICK]], "p": "ornate", "wn": "french", "rl": 0.4,
			"r": [["flat", 1]], "rf": CORRUGATED, "st": [2, 3], "fix": true, "g": [["shop", 1]],
			"rv": {"deep_balcony": 0.6, "string_course": true}},
	},
	"melbourne_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 4.0, "st": [15, 60], "fix": true, "rv": {}},
		"apartments": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["curtain", 2], ["balcony", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 60], "fix": true, "rv": {}},
	},
	# Vedado, Centro and the Malecón: two- to five-storey pastel stucco,
	# deep balconies and arcaded ground floors, flat roofs behind a parapet.
	"havana": {
		"apartments": {"w": [["render", HAVANA]], "p": [["balcony", 3], ["punched", 2]], "wn": "casement", "bay": 3.0,
			"fr": "#f4f1ea", "r": [["flat", 5], ["gabled", 1]], "pitch": 0.3, "rf": [["membrane", []], ["terracotta", TERRA]],
			"fh": 3.8, "st": [2, 5], "fix": true, "g": [["shop", 1], ["none", 1]],
			"rv": {"deep_balcony": 0.5, "string_course": true}},
		"house": {"w": [["render", HAVANA]], "p": "punched", "wn": "casement", "bay": 3.0, "fr": "#f4f1ea",
			"r": [["flat", 3], ["hipped", 2]], "pitch": 0.5, "rf": [["terracotta", TERRA]], "fh": 3.8,
			"st": [1, 2], "fix": true, "rv": {"string_course": true}},
		"commercial": {"w": [["render", HAVANA]], "p": [["ornate", 1], ["punched", 1]], "wn": "casement",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.2, "st": [2, 4], "fix": true,
			"g": [["shop", 1]], "rv": {"deep_balcony": 0.3, "string_course": true}},
	},
	# Habana Vieja: colonial houses and palaces round the old squares, tall
	# ceilings, flat roofs and red clay tile, wide shuttered windows.
	"havana_colonial": {
		"apartments": {"w": [["render", HAVANA]], "p": "punched", "wn": "casement", "bay": 3.2, "fr": "#f4f1ea",
			"sh": "#3f5a3a", "sp": 0.4, "r": [["flat", 3], ["hipped", 2]], "pitch": 0.7, "rf": [["terracotta", TERRA]],
			"fh": 4.2, "st": [2, 3], "fix": true, "g": [["shop", 1], ["none", 1]],
			"rv": {"string_course": true, "awning": 0.4}},
		"house": {"w": [["render", HAVANA]], "p": "punched", "wn": "casement", "bay": 3.2, "fr": "#f4f1ea",
			"sh": "#3f5a3a", "sp": 0.4, "r": [["flat", 3], ["hipped", 2]], "pitch": 0.7, "rf": [["terracotta", TERRA]],
			"fh": 4.2, "st": [1, 2], "fix": true, "rv": {"string_course": true}},
		"civic": {"w": [["render", ["#e8d8b0", "#efe6d2"]], ["limestone", ["#e0d8c4"]]], "p": "ornate",
			"wn": "casement", "bay": 3.4, "r": [["flat", 2], ["hipped", 1]], "rf": [["terracotta", TERRA]],
			"fh": 4.8, "st": [2, 3], "fix": true, "rv": {"string_course": true, "quoins": true}},
	},
	# Alamar and the Soviet-built estates: five- to twelve-storey prefab slabs.
	"havana_soviet": {
		"apartments": {"w": [["concrete", SOVIET_PANEL_CU]], "p": [["panel", 3], ["balcony", 1]], "wn": "wide",
			"bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 2.8, "st": [5, 12], "fix": true,
			"g": [["none", 1]], "rv": {"deep_balcony": 0.3}},
	},
}
