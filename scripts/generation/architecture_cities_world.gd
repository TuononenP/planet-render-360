class_name ArchitectureCitiesWorld
extends RefCounted

## Asian, Middle Eastern and African city rows (CityStyles zones) and
## their era rows (BuildingEra): Kyoto, Shanghai, Beijing, Bangkok,
## Mumbai, Cairo, Cape Town. City rows inherit from their country row;
## eras from their city. Same key legend as ArchitectureData; `rv` = 3D
## relief (replaces the parent's). ERAS rows carry a storey band and a
## heritage flag (BuildingEra._banded); an era without a band is reached
## only by its year, style tag or district.

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]

const KAWARA := ["#3a3e44", "#454a52", "#2f343a"]
const GREY_TILE := ["#55595e", "#4a4e54", "#606468"]
const COPPER_CN := ["#5f8f7f", "#6a9a88"]
## Kyoto machiya: dark timber lattice, clay plaster; the mid-rise beige
## and brown tile the city's height and colour rules keep.
const MACHIYA_WOOD := ["#4a3626", "#3e2e22", "#5a4230"]
const KYOTO := ["#d8ccb4", "#c8b89c", "#b8a88c", "#e0d8c8", "#a89078"]
## Shanghai: shikumen grey brick banded with red, concession stone,
## tiled residential towers.
const SHIKUMEN := ["#7a7a78", "#6a6a6a", "#8a8682", "#9a4a35"]
const BUND := ["#d8ccb0", "#c8bca0", "#e0d4b8", "#b8ac90"]
const CN_TILE := ["#e8e0d0", "#e0d0c0", "#d8c8b8", "#e8d8d0", "#c8c8c0", "#d8d0b8"]
## Beijing hutong grey brick, red lacquer doors; Soviet-era red and grey brick slabs.
const HUTONG := ["#808080", "#8a8a88", "#707272", "#9a9890"]
const SOVIET_BRICK := ["#9a5040", "#8a4a3a", "#7a7470", "#a86048"]
## Bangkok shophouse paint (weathered), Rattanakosin royal yellows/creams,
## Ratchadamnoen streamline cream, temple whites/oranges, and Yaowarat neon.
const SHOPHOUSE := ["#d8d0c0", "#c8c0b0", "#e0c8a0", "#c8d0c8", "#e8d8c0", "#b8b0a0"]
const SHUTTER := ["#6a6e72", "#5a5e62", "#4a6a8a"]
const RATTANAKOSIN_CREAM := ["#f2e6bc", "#eedba2", "#f5eed6", "#e6d8ad", "#dce4cc", "#f0e2b6"]
const RATTANAKOSIN_CIVIC := ["#f0dc98", "#eed484", "#f4ead0", "#e8d292", "#f2e5b8"]
const RATCHADAMNOEN_CREAM := ["#eee4cc", "#e8dcc0", "#f2ead6", "#e2d4b4"]
const TEAK_SHUTTER := ["#2d4c3b", "#385a46", "#4e3829", "#5c4230"]
const THAI_CLAY_ROOF := ["#b84e28", "#a64422", "#c4582c", "#8e3e24"]
const CIVIC_ROOF_TILE := [["terracotta", ["#b84a27", "#c4542a"]], ["slate", ["#2f6c4e", "#357857"]]]
const WAT_WALL := ["#f6f3ea", "#f0ece0", "#ebe4d2"]
const WAT_ORANGE_ROOF := ["#cc4e20", "#d85a24", "#be451c"]
const YAOWARAT_SIGNS := ["#d8221c", "#f0b818", "#188c42", "#e63e1c", "#f5e8c8"]
const THAI_TIMBER := ["#6e4e34", "#7e5c3e", "#5a402c", "#8a6848"]
const DISTRICT_ONLY_BANGKOK := ["bangkok_oldtown", "bangkok_ratchadamnoen",
	"bangkok_khaosan", "bangkok_yaowarat", "bangkok_timber", "bangkok_mall", "bangkok_hotel_river"]
const OLDTOWN_DISTRICTS_BANGKOK := ["bangkok_oldtown", "bangkok_civic", "bangkok_ratchadamnoen",
	"bangkok_khaosan", "bangkok_shophouse", "bangkok_yaowarat", "bangkok_timber"]
## Mumbai: monsoon-stained white and cream RCC, Art Deco pastels, Kurla basalt and buff stone.
const MUMBAI := ["#d8d4cc", "#c8c4b8", "#e0d8c8", "#b8b4a8", "#d8ccb4", "#c8c0a8"]
const DECO := ["#efe6d2", "#e8d8b8", "#e8c8b0", "#d8e0d0", "#f2ede0"]
const BOMBAY_STONE := ["#b8a888", "#a89878", "#8a7a68", "#c8b898"]
## Cairo: Khedival stone and buff render; the unplastered red brick of
## the informal blocks; Islamic Cairo limestone.
const KHEDIVAL := ["#d8c8a8", "#c8b898", "#e0d0b0", "#b8a888", "#d0b890"]
const RAW_BRICK := ["#a8603f", "#b8704a", "#9a5a3a", "#c07850"]
const CAIRO_STONE := ["#c8b48e", "#b8a480", "#d8c4a0"]
## Cape Town: Bo-Kaap brights, Victorian whites and pastels.
const BO_KAAP := ["#e83a6a", "#38a8d8", "#e8d040", "#58b858", "#e87a2a", "#a858c8", "#f0f0e8"]
const CAPE := ["#f2efe8", "#e8e0d0", "#e0d0b8", "#d8e0d8", "#e8d8c8"]
## Delhi: Lutyens cream stucco over red sandstone; Old Delhi's aged render;
## the modern city's pale render and concrete.
const LUTYENS := ["#efe6d2", "#e8dcc0", "#f2ede0", "#e0d4b8", "#d8c8a8"]
const RED_SANDSTONE := ["#a8503a", "#9a4a35", "#b8603f"]
const OLD_DELHI := ["#c8b898", "#b8a888", "#a89878", "#d8c8a8", "#e0d0b0", "#b08868"]
const NEW_DELHI := ["#e8dcc8", "#d8ccb8", "#e0d4c0", "#c8c0b0", "#b8b0a0"]

const SIEM_REAP_RENDER := ["#e8d8b0", "#d8e0c8", "#e8c8a8", "#c8d8e0", "#f0e8d8", "#e0b8a0"]
const SIEM_REAP_ROOFS := [["slate", ["#9a9c9c", "#7d8488", "#a8aaa6"]], ["slate", ["#4f7a86", "#3f5f7a", "#5a7a6a"]],
	["slate", ["#8a4a3a", "#7c4a38", "#6f6a62"]], ["membrane", []], ["terracotta", ["#a8583a", "#8f4a30"]]]

const BASE := {
	"kyoto": "japan", "kyoto_machiya": "kyoto",
	"shanghai": "east_asia", "shanghai_shikumen": "shanghai", "shanghai_bund": "shanghai",
	"shanghai_walkup": "shanghai", "shanghai_tower": "shanghai",
	"beijing": "east_asia", "beijing_hutong": "beijing", "beijing_brick": "beijing",
	"beijing_tower": "beijing",
	"bangkok": "southeast_asia", "bangkok_oldtown": "bangkok", "bangkok_khaosan": "bangkok_oldtown",
	"bangkok_civic": "bangkok", "bangkok_ratchadamnoen": "bangkok", "bangkok_shophouse": "bangkok",
	"bangkok_yaowarat": "bangkok_shophouse", "bangkok_wat": "bangkok", "bangkok_timber": "bangkok",
	"bangkok_mall": "bangkok", "bangkok_hotel_river": "bangkok", "bangkok_condo": "bangkok",
	"bangkok_tower": "bangkok",
	"siem_reap": "southeast_asia",
	"mumbai": "south_asia", "mumbai_gothic": "mumbai", "mumbai_deco": "mumbai", "mumbai_tower": "mumbai",
	"cairo": "middle_east", "cairo_khedival": "cairo", "cairo_islamic": "cairo", "cairo_tower": "cairo",
	"cape_town": "sub_saharan_africa", "cape_town_bokaap": "cape_town", "cape_town_modern": "cape_town",
	"delhi": "south_asia", "delhi_lutyens": "delhi", "delhi_old": "delhi",
}

## [era, kinds, from, to, building:architecture, weight, km from, km to,
## (storey band), (heritage era)] (BuildingEra.ERAS).
const ERAS := {
	"kyoto": [
		["kyoto_machiya", ["house", "commercial"], 1600, 1950, ["machiya", "kyo_machiya",
			"traditional", "minka", "sukiya"], 2.0, 0.0, 99.0, [1, 2], true],
		["kyoto", ALL, 1951, 2100, [], 5.0, 0.0, 99.0, [3, 99]],
	],
	"shanghai": [
		["shanghai_shikumen", ["house", "apartments"], 1860, 1949, ["shikumen", "lilong",
			"lane_house"], 1.0, 0.0, 6.0, [2, 3], true],
		["shanghai_bund", ["commercial", "civic"], 1900, 1949, ["neoclassicism", "art_deco",
			"beaux_arts", "colonial", "eclectic"], 0.8, 0.0, 3.0],
		["shanghai_walkup", APT, 1950, 2000, ["socialist_modernism"], 2.0, 0.0, 99.0, [4, 8]],
		["shanghai", APT, 1990, 2100, [], 5.0, 0.0, 99.0, [9, 45]],
		["shanghai_tower", ["commercial", "civic"], 1990, 2100, [], 2.0, 0.0, 99.0, [10, 99]],
	],
	"beijing": [
		["beijing_hutong", ["house", "commercial"], 1400, 1949, ["siheyuan", "hutong", "traditional",
			"ming", "qing"], 1.0, 0.0, 8.0, [1, 1], true],
		["beijing_brick", APT, 1950, 1989, ["socialist_realism", "soviet", "socialist_modernism",
			"stalinist"], 2.0, 0.0, 99.0, [3, 6]],
		["beijing", APT, 1990, 2100, [], 5.0, 0.0, 99.0, [7, 40]],
		["beijing_tower", ["commercial", "civic"], 1990, 2100, [], 2.0, 0.0, 99.0, [8, 99]],
	],
	# Siem Reap is one low town: no condominium or tower rows.
	"siem_reap": [
		["siem_reap", ALL, 1000, 2100, [], 5.0, 0.0, 99.0],
	],
	"bangkok": [
		["bangkok_oldtown", HAC, 1850, 1955, ["sino_portuguese", "colonial", "neoclassicism"],
			4.0, 0.0, 3.0, [2, 3], true],
		["bangkok_civic", ACC, 1870, 1980, ["neoclassical", "palladian"], 2.0, 0.0, 4.0, [2, 5]],
		["bangkok_ratchadamnoen", ACC, 1938, 1952, ["art_deco", "streamline_moderne"], 2.0, 0.0, 2.0, [4, 4]],
		["bangkok_khaosan", HAC, 1930, 2005, [], 2.0, 0.0, 2.5, [2, 4]],
		["bangkok_shophouse", HAC, 1950, 2005, ["shophouse"], 5.0, 0.0, 99.0, [2, 5]],
		["bangkok_yaowarat", HAC, 1920, 2010, ["chinese_shophouse"], 3.0, 0.0, 4.0, [3, 6]],
		["bangkok_timber", ["house", "commercial"], 1880, 1985, ["traditional", "vernacular", "wooden"],
			2.0, 0.0, 99.0, [1, 2]],
		["bangkok_mall", ["commercial", "civic"], 1985, 2100, [], 1.5, 0.0, 99.0, [4, 10]],
		["bangkok_hotel_river", AC, 1975, 2100, [], 1.5, 0.0, 99.0, [10, 34]],
		["bangkok", ALL, 1975, 2100, [], 3.0, 2.2, 99.0, [3, 8]],
		["bangkok_condo", APT, 1990, 2100, ["condominium"], 2.5, 3.0, 99.0, [9, 55]],
		["bangkok_tower", ["commercial", "civic"], 1985, 2100, [], 1.5, 2.5, 99.0, [10, 99]],
	],
	"mumbai": [
		["mumbai_gothic", ALL, 1850, 1929, ["victorian_gothic", "gothic_revival", "indo_saracenic",
			"neoclassicism", "colonial"], 0.8, 0.0, 4.0, [2, 5], true],
		["mumbai_deco", AC, 1930, 1955, ["art_deco", "streamline_moderne"], 0.8, 0.0, 6.0],
		["mumbai", HAC, 1956, 2100, [], 5.0, 0.0, 99.0, [3, 15]],
		["mumbai_tower", ACC, 1990, 2100, [], 1.5, 0.0, 99.0, [16, 99]],
	],
	"cairo": [
		["cairo_islamic", ALL, 969, 1850, ["mamluk", "fatimid", "ottoman", "islamic",
			"vernacular"], 0.8, 0.0, 3.0, [1, 4], true],
		["cairo_khedival", AC, 1860, 1952, ["eclectic", "neoclassicism", "belle_epoque",
			"art_deco", "neo_mamluk", "beaux_arts"], 1.0, 0.0, 3.0],
		["cairo", HAC, 1953, 2100, [], 5.0, 0.0, 99.0, [3, 16]],
		["cairo_tower", ACC, 1980, 2100, [], 0.6, 0.0, 99.0, [17, 99]],
	],
	"cape_town": [
		["cape_town_bokaap", ["house"], 1760, 1900, ["cape_malay", "cape_dutch", "georgian"],
			0.4, 0.0, 99.0, [1, 2], true],
		["cape_town", HAC, 1840, 1959, ["victorian", "edwardian", "georgian", "cape_dutch"],
			5.0, 0.0, 99.0, [1, 3]],
		["cape_town_modern", ACC, 1960, 2100, [], 1.5, 0.0, 99.0, [4, 99]],
	],
	"delhi": [
		["delhi_lutyens", ["house", "apartments", "civic"], 1911, 1947, ["lutyens", "indo_saracenic",
			"colonial", "neoclassicism", "art_deco"], 2.0, 0.0, 99.0, [1, 3], true],
		["delhi_old", HAC, 1600, 1910, ["mughal", "haveli", "vernacular"], 1.5, 0.0, 99.0, [2, 4], true],
		["delhi", HAC, 1948, 2100, [], 5.0, 0.0, 99.0, [3, 10]],
	],
}

const REGIONS := {
	# Mid-rise central Kyoto (height-capped, muted by the city's colour
	# rules): beige and brown tile and concrete, four to eight storeys.
	"kyoto": {
		"apartments": {"w": [["concrete", KYOTO], ["render", KYOTO]], "p": [["tiles", 2], ["balcony", 2], ["punched", 1]],
			"wn": "wide", "bay": 2.8, "fr": "#6a5a4a", "sp": 0.0, "r": [["flat", 3], ["hipped", 1]],
			"pitch": 0.5, "rf": [["membrane", []], ["slate", KAWARA]], "fh": 3.0, "st": [4, 7], "fix": true,
			"ch": 0.0, "eq": 0.6, "g": [["shop", 1], ["none", 1]], "ev": 0.2, "rv": {"deep_balcony": 0.3, "signage": 0.15}},
		"commercial": {"w": [["concrete", KYOTO], ["render", KYOTO]], "p": [["tiles", 2], ["strip", 2]],
			"wn": "wide", "fr": "#6a5a4a", "r": [["flat", 2], ["hipped", 1]], "pitch": 0.5,
			"rf": [["membrane", []], ["slate", KAWARA]], "st": [3, 7], "fix": true, "g": [["shop", 1]],
			"rv": {"signage": 0.2}},
		"house": {"w": [["render", ["#d8ccb4", "#c8b89c"]], ["wood", MACHIYA_WOOD]], "p": "punched", "wn": "small",
			"fr": "#4a3626", "r": [["gabled", 2], ["hipped", 1]], "pitch": 0.6, "rf": [["slate", KAWARA]],
			"st": [2, 2], "fix": true, "ev": 0.7},
	},
	# Machiya townhouses (Gion, Higashiyama, Nishijin): two low storeys
	# of dark timber lattice and clay plaster under kawara tile, deep
	# eaves, a tiled pent roof between the floors.
	"kyoto_machiya": {
		"house": {"w": [["wood", MACHIYA_WOOD], ["render", ["#d8ccb4", "#c8b898"]]], "p": "punched", "wn": "small",
			"bay": 1.8, "fr": "#3e2e22", "sp": 0.0, "r": [["gabled", 4], ["hipped", 1]], "pitch": 0.55,
			"rf": [["slate", KAWARA]], "fh": 2.8, "st": [2, 2], "fix": true, "ch": 0.0, "eq": 0.1,
			"g": [["none", 1]], "ev": 1.0, "rv": {"string_course": true}},
		"commercial": {"w": [["wood", MACHIYA_WOOD], ["render", ["#d8ccb4"]]], "p": "punched", "wn": "small",
			"bay": 1.8, "fr": "#3e2e22", "r": [["gabled", 3], ["hipped", 1]], "pitch": 0.55,
			"rf": [["slate", KAWARA]], "fh": 2.8, "st": [2, 2], "fix": true, "eq": 0.1,
			"g": [["shop", 1]], "gc": ["#3e2e22", "#5a2a1a", "#2a2a2a"], "ev": 1.0,
			"rv": {"string_course": true, "signage": 0.15}},
	},
	# Residential towers of the reform era: 12–30 storeys of pale tile,
	# balconies and bay windows, rooftop pavilions.
	"shanghai": {
		"apartments": {"w": [["concrete", CN_TILE]], "p": [["tiles", 2], ["balcony", 3]], "wn": "wide",
			"bay": 3.0, "fr": "#8a8c8e", "sp": 0.0, "r": [["flat", 4], ["pyramidal", 1]], "pitch": 0.4,
			"rf": [["membrane", []], ["slate", ["#5a626b"]]], "fh": 2.9, "st": [12, 30], "fix": true,
			"eq": 0.7, "g": [["none", 2], ["shop", 1]], "rv": {"deep_balcony": 0.2}},
	},
	# Lilong lanes: two- and three-storey grey brick terraces banded with
	# red brick, carved stone gateways, grey tile gables.
	"shanghai_shikumen": {
		"house": {"w": [["brick", SHIKUMEN]], "p": "punched", "wn": "casement", "bay": 3.0, "fr": "#4a3a2a",
			"sp": 0.0, "r": [["gabled", 1]], "pitch": 0.6, "rf": [["slate", GREY_TILE]], "fh": 3.2,
			"st": [2, 3], "fix": true, "ch": 0.0, "g": [["stone", 1]], "rv": {"string_course": true}},
		"apartments": {"w": [["brick", SHIKUMEN]], "p": "punched", "wn": "casement", "bay": 3.0, "fr": "#4a3a2a",
			"r": [["gabled", 1]], "pitch": 0.6, "rf": [["slate", GREY_TILE]], "fh": 3.2, "st": [2, 3],
			"fix": true, "g": [["stone", 1], ["shop", 1]], "rv": {"string_course": true}},
	},
	# The Bund and the old concessions: granite and render banks and
	# hotels, neoclassical and Art Deco, five to twelve storeys.
	"shanghai_bund": {
		"commercial": {"w": [["stone", BUND], ["limestone", ["#e0d4b8"]]], "p": "ornate", "wn": "casement",
			"bay": 3.2, "fr": "#3a3d42", "r": [["flat", 2], ["hipped", 1], ["pyramidal", 1]], "pitch": 0.6,
			"rf": [["membrane", []], ["slate", COPPER_CN]], "fh": 4.2, "st": [5, 10], "fix": true,
			"g": [["stone", 1]], "rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["stone", BUND]], "p": "ornate", "wn": "casement", "r": [["flat", 1], ["dome", 1]],
			"rf": [["slate", COPPER_CN]], "st": [3, 6], "fix": true, "rv": {"string_course": true}},
	},
	"shanghai_walkup": {
		"apartments": {"w": [["concrete", ["#d8d0c0", "#c8c0b0", "#e0d8c8"]], ["render", CN_TILE]],
			"p": [["punched", 2], ["balcony", 2]], "wn": "wide", "bay": 3.0, "fr": "#8a8c8e",
			"r": [["flat", 2], ["gabled", 1]], "pitch": 0.4, "rf": [["membrane", []], ["terracotta", ["#9a4a2c"]]],
			"fh": 2.8, "st": [5, 7], "fix": true, "eq": 0.5, "rv": {"deep_balcony": 0.3}},
	},
	"shanghai_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "fr": "#8a9098", "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 4.2, "st": [20, 70], "fix": true, "rv": {}},
		"civic": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": "curtain", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 20], "fix": true, "rv": {}},
	},
	# Residential compounds of the 1990s on: 12–30 storey slabs and
	# towers in beige, salmon and grey tile.
	"beijing": {
		"apartments": {"w": [["concrete", CN_TILE + ["#d8b8a0", "#c8a890"]]], "p": [["tiles", 2], ["balcony", 3]],
			"wn": "wide", "bay": 3.0, "fr": "#8a8c8e", "sp": 0.0, "r": [["flat", 4], ["hipped", 1]],
			"pitch": 0.4, "rf": [["membrane", []], ["slate", GREY_TILE]], "fh": 2.9, "st": [12, 28], "fix": true,
			"eq": 0.6, "g": [["none", 2], ["shop", 1]], "rv": {"deep_balcony": 0.2}},
	},
	# Siheyuan courtyard houses in the hutongs: one storey of grey brick
	# under curved grey tile gables, red lacquered gates.
	"beijing_hutong": {
		"house": {"w": [["brick", HUTONG]], "p": "punched", "wn": "small", "bay": 3.0, "fr": "#8a2a1a",
			"sp": 0.0, "r": [["gabled", 1]], "pitch": 0.6, "rf": [["slate", GREY_TILE]], "fh": 3.4,
			"st": [1, 1], "fix": true, "ch": 0.0, "eq": 0.2, "ev": 0.5, "rv": {}},
		"commercial": {"w": [["brick", HUTONG]], "p": "punched", "wn": "small", "bay": 3.0, "fr": "#8a2a1a",
			"r": [["gabled", 1]], "pitch": 0.6, "rf": [["slate", GREY_TILE]], "fh": 3.4, "st": [1, 2],
			"fix": true, "g": [["shop", 1]], "gc": ["#8a2a1a", "#2a2a2a", "#c8901a"], "ev": 0.5,
			"rv": {"signage": 0.3}},
	},
	"beijing_brick": {
		"apartments": {"w": [["brick", SOVIET_BRICK]], "p": "punched", "wn": "wide", "bay": 3.0, "fr": "#6a6e72",
			"r": [["flat", 2], ["gabled", 1]], "pitch": 0.35, "rf": [["membrane", []], ["slate", GREY_TILE]],
			"fh": 2.9, "st": [4, 6], "fix": true, "eq": 0.3, "rv": {"deep_balcony": 0.2}},
	},
	"beijing_tower": {
		"commercial": {"w": [["glass", []], ["stone", ["#c8c4bc"]]], "p": [["curtain", 3], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.0, "st": [15, 60], "fix": true, "rv": {}},
		"civic": {"w": [["stone", ["#c8c4bc", "#d8d0c0"]]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [4, 12], "fix": true, "rv": {}},
	},
	# Siem Reap: a low town of two-to-four-storey shophouses and rendered or
	# timber houses under corrugated metal (bare, grey, teal, blue, rust-red)
	# with flat concrete decks on newer rows and clay tile on old houses.
	"siem_reap": {
		"house": {"w": [["render", SIEM_REAP_RENDER], ["wood", ["#7a5a3a", "#8a6a48", "#5e4a36"]]],
			"p": "punched", "bay": 3.0, "fr": "#efece4", "sh": "#4f6a5a", "sp": 0.3,
			"r": [["gabled", 4], ["hipped", 2], ["flat", 2]], "pitch": 0.6, "rf": SIEM_REAP_ROOFS,
			"fh": 3.0, "st": [1, 2], "ch": 0.0, "eq": 0.4, "ev": 0.9},
		"apartments": {"w": [["render", SIEM_REAP_RENDER], ["concrete", SHOPHOUSE]],
			"p": [["shophouse", 2], ["punched", 2], ["balcony", 1]], "wn": "wide", "bay": 4.0,
			"fr": "#6a6e72", "sh": SHUTTER, "sp": 0.2, "r": [["flat", 3], ["gabled", 2]], "pitch": 0.5,
			"rf": SIEM_REAP_ROOFS, "fh": 3.2, "st": [2, 4], "fix": true, "eq": 0.8,
			"g": [["shop", 2], ["none", 1]], "rv": {"signage": 0.4, "awning": 0.4,
				"awning_colours": ["#2a4a6a", "#c8301a", "#e8b820", "#2a7a3a"]}},
		"commercial": {"w": [["render", SIEM_REAP_RENDER], ["concrete", SHOPHOUSE]],
			"p": [["shophouse", 3], ["punched", 1]], "wn": "wide", "bay": 4.0, "fr": "#6a6e72",
			"sh": SHUTTER, "sp": 0.3, "r": [["flat", 3], ["gabled", 2]], "pitch": 0.5,
			"rf": SIEM_REAP_ROOFS, "fh": 3.3, "st": [2, 4], "fix": true, "eq": 0.9,
			"g": [["shop", 2], ["signage", 1]], "gc": ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a"],
			"rv": {"signage": 0.6, "awning": 0.5, "awning_colours": ["#2a4a6a", "#c8301a", "#e8b820"]}},
	},
	# Bangkok general mid-rise fabric outside conservation & tower cores, plus
	# the city-wide Thai wat religious hall profile (BK-3.4: steep orange-tile
	# gabled roof, whitewashed walls, no East Asian pagoda tower).
	"bangkok": {
		"apartments": {"w": [["render", SHOPHOUSE], ["concrete", ["#e6e2d8", "#dad4c8"]]],
			"p": [["balcony", 3], ["punched", 2]], "wn": "wide", "bay": 3.2, "fr": "#787a7c", "sp": 0.1,
			"r": [["flat", 4], ["hipped", 1]], "pitch": 0.45, "rf": [["membrane", []], ["terracotta", THAI_CLAY_ROOF]],
			"fh": 3.1, "st": [4, 8], "fix": true, "eq": 0.7, "g": [["shop", 2], ["none", 1]],
			"rv": {"deep_balcony": 0.35, "signage": 0.25, "awning": 0.25,
				"awning_colours": ["#2a526e", "#b83220", "#d8a420"]}},
		"commercial": {"w": [["render", SHOPHOUSE], ["concrete", SHOPHOUSE]], "p": [["shophouse", 2], ["strip", 2]],
			"wn": "wide", "bay": 3.8, "fr": "#6a6e72", "sh": SHUTTER, "sp": 0.2, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.4, "st": [3, 6], "fix": true, "eq": 0.8,
			"g": [["shop", 2], ["signage", 1]], "rv": {"signage": 0.45, "awning": 0.35,
				"awning_colours": ["#2a4a6a", "#c8301a", "#e8b820"]}},
		"house": {"w": [["render", RATTANAKOSIN_CREAM], ["wood", THAI_TIMBER]], "p": "punched",
			"bay": 3.0, "fr": "#f4f0e6", "sh": TEAK_SHUTTER, "sp": 0.35, "r": [["hipped", 3], ["gabled", 3]],
			"pitch": 0.7, "rf": [["terracotta", THAI_CLAY_ROOF], ["slate", ["#68727a", "#7a4a38"]]],
			"fh": 3.0, "st": [2, 2], "fix": true, "ch": 0.0, "eq": 0.2, "ev": 0.85, "rv": {}},
		"religious": {"w": [["render", WAT_WALL]], "p": "ornate", "wn": "casement", "bay": 3.4,
			"fr": "#c89624", "sh": "#7a221c", "sp": 0.5, "r": [["gabled", 1]], "pitch": 1.35,
			"rf": [["terracotta", WAT_ORANGE_ROOF]], "fh": 5.5, "st": [1, 2], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.0, "tw": "none", "g": [["stone", 1]], "ev": 1.15,
			"rv": {"thai_wat": true, "string_course": true}},
	},
	"bangkok_wat": {
		"religious": {"w": [["render", WAT_WALL]], "p": "ornate", "wn": "casement", "bay": 3.4,
			"fr": "#c89624", "sh": "#7a221c", "sp": 0.5, "r": [["gabled", 1]], "pitch": 1.35,
			"rf": [["terracotta", WAT_ORANGE_ROOF]], "fh": 5.5, "st": [1, 2], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.0, "tw": "none", "g": [["stone", 1]], "ev": 1.15,
			"rv": {"thai_wat": true, "string_course": true}},
	},
	# Condominium towers (Sukhumvit, Silom, Rama IX): 20–45 storeys of white
	# render and tinted glass with deep balconies.
	"bangkok_condo": {
		"apartments": {"w": [["render", ["#f0eee8", "#e8e4dc", "#e0dcd4"]], ["glass", []]],
			"p": [["balcony", 3], ["curtain", 1]], "wn": "wide", "bay": 3.0, "fr": "#8a8c8e", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.0, "st": [20, 45], "fix": true,
			"eq": 0.7, "g": [["none", 1], ["shop", 1]], "rv": {"deep_balcony": 0.5}},
	},
	# Rattanakosin historic shophouses (Sao Chingcha, Phraeng Phuthon, Bamrung
	# Mueang): 2–3 storeys of royal yellow, cream and celadon render, dark
	# green/teak louvred shutters, clay-tile hipped/gabled roofs and awnings.
	"bangkok_oldtown": {
		"commercial": {"w": [["render", RATTANAKOSIN_CREAM]], "p": [["shophouse", 3], ["ornate", 1]],
			"wn": "french", "bay": 3.8, "fr": "#f4efe2", "sh": TEAK_SHUTTER, "sp": 0.7,
			"r": [["hipped", 3], ["gabled", 3]], "pitch": 0.65, "rf": [["terracotta", THAI_CLAY_ROOF]],
			"fh": 3.5, "st": [2, 3], "fix": true, "ch": 0.0, "eq": 0.1, "g": [["shop", 3], ["render", 1]],
			"gc": ["#285840", "#8e2c22", "#3e2e22", "#1e4a68"], "ev": 0.75,
			"rv": {"string_course": true, "awning": 0.55,
				"awning_colours": ["#285840", "#982c22", "#c88e22", "#ece4d0"], "signage": 0.25}},
		"apartments": {"w": [["render", RATTANAKOSIN_CREAM]], "p": [["shophouse", 3], ["punched", 2]],
			"wn": "french", "bay": 3.8, "fr": "#f4efe2", "sh": TEAK_SHUTTER, "sp": 0.65,
			"r": [["hipped", 3], ["gabled", 3]], "pitch": 0.65, "rf": [["terracotta", THAI_CLAY_ROOF]],
			"fh": 3.4, "st": [2, 3], "fix": true, "ch": 0.0, "eq": 0.1, "g": [["shop", 3], ["render", 1]],
			"gc": ["#285840", "#8e2c22", "#3e2e22"], "ev": 0.75,
			"rv": {"string_course": true, "awning": 0.45,
				"awning_colours": ["#285840", "#982c22", "#ece4d0"], "signage": 0.2}},
		"house": {"w": [["render", RATTANAKOSIN_CREAM], ["wood", THAI_TIMBER]], "p": "punched",
			"wn": "casement", "bay": 3.2, "fr": "#f4efe2", "sh": TEAK_SHUTTER, "sp": 0.6,
			"r": [["hipped", 3], ["gabled", 3]], "pitch": 0.7, "rf": [["terracotta", THAI_CLAY_ROOF]],
			"fh": 3.2, "st": [2, 2], "fix": true, "ch": 0.0, "eq": 0.05, "ev": 0.85,
			"rv": {"string_course": true}},
		"civic": {"w": [["render", RATTANAKOSIN_CIVIC]], "p": "ornate", "wn": "casement",
			"bay": 3.8, "fr": "#f6f2e8", "sh": TEAK_SHUTTER, "sp": 0.45,
			"r": [["hipped", 3], ["flat", 2]], "pitch": 0.65, "rf": CIVIC_ROOF_TILE,
			"fh": 3.8, "st": [3, 4], "fix": true, "ch": 0.0, "eq": 0.15, "g": [["stone", 2], ["render", 1]],
			"ev": 0.65, "rv": {"string_course": true, "quoins": true, "cornice": 0.6}},
	},
	# Banglamphu & Khao San Road: 2–4 storey Rattanakosin shophouses packed
	# with guesthouse signboards, vertical banners and street awnings.
	"bangkok_khaosan": {
		"commercial": {"w": [["render", RATTANAKOSIN_CREAM + SHOPHOUSE]], "p": [["shophouse", 3], ["punched", 1]],
			"wn": "french", "bay": 3.8, "fr": "#6a6862", "sh": TEAK_SHUTTER, "sp": 0.45,
			"r": [["flat", 2], ["hipped", 2], ["gabled", 2]], "pitch": 0.55,
			"rf": [["terracotta", THAI_CLAY_ROOF], ["membrane", []]], "fh": 3.4, "st": [2, 4],
			"fix": true, "eq": 0.5, "g": [["signage", 3], ["shop", 2]],
			"gc": ["#c8301a", "#1f6a4a", "#e8b020", "#1e5090"], "ev": 0.4,
			"rv": {"signage": 0.85, "sign_stack": 0.55, "screens": 0.35, "awning": 0.65,
				"awning_colours": ["#c8301a", "#1f6a4a", "#e8b020", "#1e5090"]}},
		"apartments": {"w": [["render", RATTANAKOSIN_CREAM + SHOPHOUSE]], "p": [["shophouse", 2], ["punched", 2]],
			"wn": "wide", "bay": 3.8, "fr": "#6a6862", "sh": TEAK_SHUTTER, "sp": 0.4,
			"r": [["flat", 2], ["hipped", 2]], "pitch": 0.55,
			"rf": [["terracotta", THAI_CLAY_ROOF], ["membrane", []]], "fh": 3.3, "st": [2, 4],
			"fix": true, "eq": 0.5, "g": [["shop", 2], ["signage", 2]],
			"rv": {"signage": 0.7, "sign_stack": 0.4, "awning": 0.5,
				"awning_colours": ["#c8301a", "#1f6a4a", "#e8b020"]}},
	},
	# Royal Rattanakosin & Dusit ministries: warm yellow and cream neo-classical
	# and late-modern civic blocks (including 4–5 storey Bangkok City Hall).
	"bangkok_civic": {
		"civic": {"w": [["render", RATTANAKOSIN_CIVIC], ["limestone", ["#efe6ce"]]],
			"p": [["ornate", 3], ["punched", 2]], "wn": "casement", "bay": 3.8, "fr": "#f6f2e8",
			"sh": TEAK_SHUTTER, "sp": 0.45, "r": [["hipped", 4], ["flat", 1]], "pitch": 0.7,
			"rf": CIVIC_ROOF_TILE, "fh": 3.9, "st": [2, 4], "fix": true, "ch": 0.0, "eq": 0.1,
			"g": [["stone", 2], ["render", 2]], "ev": 0.75,
			"rv": {"string_course": true, "quoins": true, "cornice": 0.7}},
		"commercial": {"w": [["render", RATTANAKOSIN_CIVIC]], "p": [["ornate", 2], ["shophouse", 2]],
			"wn": "french", "bay": 3.8, "fr": "#f6f2e8", "sh": TEAK_SHUTTER, "sp": 0.55,
			"r": [["hipped", 4], ["gabled", 1]], "pitch": 0.65, "rf": CIVIC_ROOF_TILE,
			"fh": 3.6, "st": [2, 3], "fix": true, "ch": 0.0, "eq": 0.1,
			"g": [["shop", 2], ["stone", 1]], "ev": 0.75,
			"rv": {"string_course": true, "quoins": true, "awning": 0.3,
				"awning_colours": ["#285840", "#8e2c22"]}},
		"apartments": {"w": [["render", RATTANAKOSIN_CIVIC]], "p": [["ornate", 2], ["punched", 2]],
			"wn": "casement", "bay": 3.6, "fr": "#f6f2e8", "sh": TEAK_SHUTTER, "sp": 0.5,
			"r": [["hipped", 4], ["gabled", 1]], "pitch": 0.65, "rf": CIVIC_ROOF_TILE,
			"fh": 3.5, "st": [2, 3], "fix": true, "ch": 0.0, "eq": 0.1,
			"g": [["render", 2], ["shop", 1]], "ev": 0.75, "rv": {"string_course": true}},
		"house": {"w": [["render", RATTANAKOSIN_CIVIC]], "p": "punched", "wn": "casement",
			"bay": 3.2, "fr": "#f6f2e8", "sh": TEAK_SHUTTER, "sp": 0.5,
			"r": [["hipped", 4], ["gabled", 1]], "pitch": 0.7, "rf": CIVIC_ROOF_TILE,
			"fh": 3.3, "st": [2, 2], "fix": true, "ch": 0.0, "eq": 0.05, "ev": 0.8, "rv": {}},
	},
	# Ratchadamnoen Klang 1939–48 uniform streamline Art Deco avenue blocks:
	# fixed 4 storeys of warm cream stucco, vertical mullions, flat roof behind parapet.
	"bangkok_ratchadamnoen": {
		"commercial": {"w": [["render", RATCHADAMNOEN_CREAM]], "p": [["strip", 2], ["punched", 2]],
			"wn": "wide", "bay": 3.6, "fr": "#58524a", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", ["#cdc4b2", "#bfb6a4"]]], "fh": 3.7, "st": [4, 4], "fix": true,
			"ch": 0.0, "eq": 0.15, "g": [["shop", 3], ["stone", 1]],
			"gc": ["#7a2820", "#3a352f", "#9e7420"], "ev": 0.0,
			"rv": {"string_course": true, "cornice": 0.85, "mullion": true, "awning": 0.25,
				"awning_colours": ["#8a2a20", "#c89628"]}},
		"apartments": {"w": [["render", RATCHADAMNOEN_CREAM]], "p": [["strip", 2], ["punched", 2]],
			"wn": "wide", "bay": 3.6, "fr": "#58524a", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", ["#cdc4b2", "#bfb6a4"]]], "fh": 3.7, "st": [4, 4], "fix": true,
			"ch": 0.0, "eq": 0.15, "g": [["shop", 3], ["stone", 1]],
			"gc": ["#7a2820", "#3a352f"], "ev": 0.0,
			"rv": {"string_course": true, "cornice": 0.85, "mullion": true}},
		"civic": {"w": [["render", RATCHADAMNOEN_CREAM]], "p": [["strip", 2], ["ornate", 1]],
			"wn": "wide", "bay": 3.8, "fr": "#58524a", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", ["#cdc4b2"]]], "fh": 3.8, "st": [4, 4], "fix": true,
			"ch": 0.0, "eq": 0.1, "g": [["stone", 1]], "ev": 0.0,
			"rv": {"string_course": true, "cornice": 0.9, "mullion": true}},
	},
	# Shophouse rows: three to five storeys of weathered painted concrete,
	# roll-down shutters, caged balconies, roof water tanks and vertical signs.
	"bangkok_shophouse": {
		"commercial": {"w": [["concrete", SHOPHOUSE], ["render", SHOPHOUSE]], "p": [["shophouse", 3], ["punched", 2]],
			"wn": "wide", "bay": 4.0, "fr": "#6a6e72", "sh": SHUTTER, "sp": 0.25, "r": [["flat", 4], ["gabled", 1]],
			"pitch": 0.4, "rf": [["membrane", []], ["slate", ["#8a3a2a", "#5a626b"]]], "fh": 3.3, "st": [3, 5],
			"fix": true, "eq": 0.9, "g": [["signage", 2], ["shop", 2]],
			"gc": ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a"], "ev": 0.2,
			"rv": {"signage": 0.75, "sign_stack": 0.35, "deep_balcony": 0.3, "awning": 0.45,
				"awning_colours": ["#2a4a6a", "#c8301a", "#e8b820", "#e8e4da"]}},
		"apartments": {"w": [["concrete", SHOPHOUSE], ["render", SHOPHOUSE]], "p": [["shophouse", 2], ["punched", 2]],
			"wn": "wide", "bay": 4.0, "fr": "#6a6e72", "sh": SHUTTER, "sp": 0.2, "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 3.2, "st": [3, 5], "fix": true, "eq": 0.9,
			"g": [["shop", 2], ["signage", 1]],
			"rv": {"signage": 0.5, "sign_stack": 0.2, "deep_balcony": 0.35, "awning": 0.35,
				"awning_colours": ["#2a4a6a", "#c8301a"]}},
		"house": {"w": [["concrete", SHOPHOUSE], ["render", RATTANAKOSIN_CREAM]], "p": "punched", "wn": "wide",
			"bay": 4.0, "fr": "#6a6e72", "r": [["flat", 2], ["gabled", 2]], "pitch": 0.45,
			"rf": [["membrane", []], ["terracotta", THAI_CLAY_ROOF]], "st": [2, 3], "fix": true,
			"eq": 0.7, "rv": {}},
	},
	# Yaowarat & Sampheng (Chinatown): gold-shop red/gold ground fronts and
	# dense vertical red, gold and jade-green neon signboards on 3–6 storey rows.
	"bangkok_yaowarat": {
		"commercial": {"w": [["concrete", SHOPHOUSE], ["render", ["#e2d4b8", "#d8c8a8", "#e8dcc4"]]],
			"p": [["shophouse", 3], ["strip", 1]], "wn": "wide", "bay": 3.8, "fr": "#7a241c",
			"sh": "#2c5e3e", "sp": 0.2, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.4, "st": [3, 6], "fix": true, "eq": 0.95, "g": [["signage", 4], ["shop", 1]],
			"gc": YAOWARAT_SIGNS, "ev": 0.0,
			"rv": {"signage": 0.95, "sign_stack": 0.85, "sign_bands": 0.45, "screens": 0.75,
				"awning": 0.5, "awning_colours": ["#c82018", "#e8b018", "#187a3c"]}},
		"apartments": {"w": [["concrete", SHOPHOUSE], ["render", ["#e2d4b8", "#d8c8a8"]]],
			"p": [["shophouse", 2], ["punched", 2]], "wn": "wide", "bay": 3.8, "fr": "#6a6862",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.3, "st": [3, 6], "fix": true,
			"eq": 0.9, "g": [["signage", 3], ["shop", 1]], "gc": YAOWARAT_SIGNS, "ev": 0.0,
			"rv": {"signage": 0.85, "sign_stack": 0.7, "sign_bands": 0.35, "screens": 0.5,
				"awning": 0.4, "awning_colours": ["#c82018", "#e8b018"]}},
	},
	# Thonburi canal-side (Bangkok Noi, Bangkok Yai, Kudi Chin): 1–2 storey
	# teak and painted timber houses under corrugated metal and clay-tile roofs.
	"bangkok_timber": {
		"house": {"w": [["wood", THAI_TIMBER], ["render", RATTANAKOSIN_CREAM]], "p": "clapboard",
			"wn": "casement", "bay": 2.8, "fr": "#e8e2d4", "sh": TEAK_SHUTTER, "sp": 0.4,
			"r": [["gabled", 4], ["hipped", 2]], "pitch": 0.7,
			"rf": [["sheet_metal", ["#7a8086", "#6c4838", "#3e6478"]], ["terracotta", THAI_CLAY_ROOF]],
			"fh": 2.9, "st": [1, 2], "fix": true, "ch": 0.0, "eq": 0.15, "ev": 0.95, "rv": {}},
		"apartments": {"w": [["render", RATTANAKOSIN_CREAM], ["wood", THAI_TIMBER]],
			"p": [["punched", 3], ["shophouse", 1]], "wn": "casement", "bay": 3.2, "fr": "#6a6862",
			"r": [["gabled", 3], ["hipped", 2], ["flat", 1]], "pitch": 0.6,
			"rf": [["sheet_metal", ["#7a8086", "#6c4838"]], ["terracotta", THAI_CLAY_ROOF]],
			"fh": 3.0, "st": [2, 3], "fix": true, "eq": 0.25, "ev": 0.8, "rv": {}},
		"commercial": {"w": [["render", RATTANAKOSIN_CREAM], ["wood", THAI_TIMBER]], "p": "shophouse",
			"wn": "casement", "bay": 3.5, "fr": "#6a6862", "r": [["gabled", 3], ["flat", 1]],
			"pitch": 0.6, "rf": [["sheet_metal", ["#7a8086", "#6c4838"]], ["terracotta", THAI_CLAY_ROOF]],
			"fh": 3.1, "st": [2, 3], "fix": true, "eq": 0.3, "g": [["shop", 1]], "ev": 0.8,
			"rv": {"awning": 0.4, "awning_colours": ["#285840", "#b83220"]}},
	},
	# Siam / Ratchaprasong shopping malls: wide 5–10 storey stone/metal podiums with LED screens.
	"bangkok_mall": {
		"commercial": {"w": [["concrete", ["#e8e4dc", "#d8d4cc"]], ["glass", []]],
			"p": [["panel", 2], ["curtain", 2]], "wn": "wide", "bay": 4.2, "fr": "#4a4e54",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.5, "st": [5, 10], "fix": true,
			"eq": 0.9, "g": [["shop", 2], ["signage", 2]], "ev": 0.0,
			"rv": {"screens": 0.85, "signage": 0.7, "sign_bands": 0.4}},
		"civic": {"w": [["concrete", ["#e8e4dc"]], ["glass", []]], "p": "curtain", "r": [["flat", 1]],
			"rf": [["membrane", []]], "fh": 4.4, "st": [4, 10], "fix": true, "rv": {"screens": 0.5}},
	},
	# Chao Phraya riverfront hotels (Bang Rak / Charoen Krung): warm cream concrete & glass slabs.
	"bangkok_hotel_river": {
		"apartments": {"w": [["render", ["#f2ece0", "#e8dfd0"]], ["glass", []]],
			"p": [["balcony", 3], ["curtain", 1]], "wn": "wide", "bay": 3.4, "fr": "#7a7670",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.3, "st": [10, 32], "fix": true,
			"eq": 0.7, "g": [["stone", 2], ["shop", 1]], "rv": {"deep_balcony": 0.55}},
		"commercial": {"w": [["render", ["#f2ece0", "#e8dfd0"]], ["glass", []]],
			"p": [["strip", 2], ["curtain", 2]], "wn": "wide", "bay": 3.6, "fr": "#7a7670",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [8, 28], "fix": true,
			"eq": 0.7, "g": [["stone", 2], ["shop", 1]], "rv": {"deep_balcony": 0.3}},
	},
	"bangkok_tower": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 4.0, "st": [20, 60], "fix": true, "rv": {}},
		"civic": {"w": [["glass", []], ["concrete", ["#e0dcd4"]]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [5, 15], "fix": true, "rv": {}},
	},
	# RCC apartment blocks: five to twelve storeys of monsoon-stained
	# white and cream, window grilles, chajjas, water tanks on the roof.
	"mumbai": {
		"apartments": {"w": [["concrete", MUMBAI], ["render", MUMBAI]], "p": [["punched", 3], ["balcony", 2]],
			"wn": "wide", "bay": 3.0, "fr": "#5a5e62", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", ["#b8b4a8", "#a8a498"]]], "fh": 3.0, "st": [5, 10], "fix": true, "ch": 0.0,
			"eq": 0.85, "g": [["shop", 2], ["none", 1]], "gc": ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a"],
			"ev": 0.4, "rv": {"deep_balcony": 0.3, "awning": 0.3, "signage": 0.3,
				"awning_colours": ["#2a4a6a", "#c8301a", "#e8b820"]}},
		"commercial": {"w": [["concrete", MUMBAI], ["glass", []]], "p": [["strip", 2], ["punched", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["concrete", ["#b8b4a8"]]], "st": [3, 8], "fix": true,
			"g": [["signage", 2], ["shop", 1]], "rv": {"signage": 0.6}},
	},
	# Fort and Kala Ghoda: Victorian Gothic and Indo-Saracenic stone, buff
	# and basalt, arcades, pointed windows, steep slate and domes.
	"mumbai_gothic": {
		"commercial": {"w": [["stone", BOMBAY_STONE]], "p": "ornate", "wn": "casement", "bay": 3.0,
			"fr": "#3a3d42", "r": [["hipped", 2], ["gabled", 2], ["dome", 1]], "pitch": 1.0,
			"rf": [["slate", ["#5a626b", "#7a3a2a"]]], "fh": 4.2, "st": [3, 5], "fix": true,
			"g": [["stone", 1]], "rv": {"string_course": true, "quoins": true}},
		"civic": {"w": [["stone", BOMBAY_STONE]], "p": "ornate", "wn": "casement", "r": [["gabled", 2], ["dome", 1]],
			"pitch": 1.1, "rf": [["slate", ["#5a626b", "#7a3a2a"]]], "fh": 4.5, "st": [3, 5], "fix": true,
			"rv": {"string_course": true, "quoins": true}},
		"apartments": {"w": [["stone", BOMBAY_STONE], ["render", DECO]], "p": "ornate", "wn": "casement",
			"r": [["hipped", 1], ["flat", 1]], "rf": [["slate", ["#5a626b"]]], "st": [3, 5], "fix": true,
			"rv": {"string_course": true, "deep_balcony": 0.3}},
	},
	# Marine Drive and the Oval: Art Deco apartment blocks in cream and
	# pastel render, curved corners, eyebrow sunshades.
	"mumbai_deco": {
		"apartments": {"w": [["render", DECO]], "p": [["strip", 2], ["balcony", 2]], "wn": "wide", "bay": 3.0,
			"fr": "#5a5e62", "r": [["flat", 1]], "rf": [["concrete", ["#c8c4b8"]]], "fh": 3.2, "st": [4, 7],
			"fix": true, "rv": {"deep_balcony": 0.5, "string_course": true}},
		"commercial": {"w": [["render", DECO]], "p": "strip", "wn": "wide", "r": [["flat", 1]],
			"rf": [["concrete", ["#c8c4b8"]]], "st": [3, 6], "fix": true, "g": [["shop", 1]],
			"rv": {"string_course": true}},
	},
	"mumbai_tower": {
		"apartments": {"w": [["concrete", ["#e8e4dc", "#d8d4cc"]], ["glass", []]], "p": [["balcony", 2], ["curtain", 2]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1, "st": [20, 60], "fix": true,
			"eq": 0.7, "rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["glass", []]], "p": "curtain", "r": [["flat", 1]], "rf": [["membrane", []]],
			"st": [15, 40], "fix": true, "rv": {}},
	},
	# The informal and post-1952 city: concrete frames infilled with
	# unplastered red brick, eight to fourteen storeys, rebar stubs and
	# satellite dishes on the roofs.
	"cairo": {
		"apartments": {"w": [["brick", RAW_BRICK], ["render", KHEDIVAL]], "p": [["punched", 3], ["balcony", 2]],
			"wn": "wide", "bay": 3.2, "fr": "#5a4a3a", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", ["#b8a888", "#a89878"]]], "fh": 3.0, "st": [6, 12], "fix": true, "ch": 0.0,
			"eq": 0.95, "g": [["shop", 2], ["none", 1]], "gc": ["#3a3020", "#20302a", "#5a4a3a"], "ev": 0.0,
			"rv": {"deep_balcony": 0.3, "awning": 0.2, "awning_colours": ["#5a4a3a", "#2a3a4a", "#8a6a3a"]}},
	},
	# Khedival downtown (Wust el-Balad): European eclectic stone and
	# render blocks of five to seven storeys, balconies, ornate cornices.
	"cairo_khedival": {
		"apartments": {"w": [["stone", KHEDIVAL], ["render", KHEDIVAL]], "p": [["ornate", 3], ["punched", 1]],
			"wn": "french", "bay": 2.8, "fr": "#5a4a3a", "sh": "#5a4a3a", "sp": 0.6, "rl": 0.6,
			"r": [["flat", 3], ["dome", 1]], "rf": [["concrete", ["#c8b898"]]], "fh": 3.8, "st": [5, 7],
			"fix": true, "g": [["shop", 1]], "rv": {"balconette": 0.6, "string_course": true, "quoins": true}},
		"commercial": {"w": [["stone", KHEDIVAL]], "p": "ornate", "wn": "french", "rl": 0.5, "r": [["flat", 1]],
			"rf": [["concrete", ["#c8b898"]]], "fh": 4.0, "st": [4, 7], "fix": true, "g": [["shop", 1]],
			"rv": {"string_course": true}},
	},
	# Islamic Cairo (al-Muizz, the Citadel quarter): limestone and render
	# houses behind mashrabiya screens, two to four storeys.
	"cairo_islamic": {
		"house": {"w": [["stone", CAIRO_STONE], ["render", CAIRO_STONE]], "p": "adobe", "wn": "small",
			"bay": 2.8, "fr": "#4a3626", "sh": "#4a3626", "sp": 0.5, "r": [["flat", 1]],
			"rf": [["concrete", CAIRO_STONE]], "fh": 3.4, "st": [2, 3], "fix": true, "ev": 0.0,
			"rv": {"oriel": 0.4}},
		"apartments": {"w": [["stone", CAIRO_STONE], ["render", CAIRO_STONE]], "p": "adobe", "wn": "small",
			"sh": "#4a3626", "sp": 0.5, "r": [["flat", 1]], "rf": [["concrete", CAIRO_STONE]], "st": [3, 4],
			"fix": true, "g": [["shop", 1]], "rv": {"oriel": 0.4, "awning": 0.2, "awning_colours": ["#5a4a3a"]}},
		"commercial": {"w": [["stone", CAIRO_STONE]], "p": "adobe", "wn": "small", "r": [["flat", 1]],
			"rf": [["concrete", CAIRO_STONE]], "st": [2, 3], "fix": true, "g": [["shop", 1]], "rv": {}},
	},
	"cairo_tower": {
		"commercial": {"w": [["glass", []], ["concrete", ["#d8ccb4"]]], "p": [["curtain", 2], ["strip", 1]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 40], "fix": true, "rv": {}},
		"apartments": {"w": [["concrete", ["#d8ccb4", "#c8bca4"]], ["glass", []]], "p": [["balcony", 2], ["strip", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [15, 30], "fix": true, "rv": {}},
	},
	# Victorian and Edwardian Cape Town (Woodstock, Tamboerskloof): one-
	# and two-storey houses in white and pastel render, cast-iron
	# verandahs, corrugated iron roofs.
	"cape_town": {
		"house": {"w": [["render", CAPE]], "p": "punched", "wn": "sash", "bay": 2.6, "fr": "#f4f1ea",
			"sh": "#3f5a3a", "sp": 0.3, "r": [["hipped", 2], ["gabled", 2], ["flat", 1]], "pitch": 0.6,
			"rf": [["slate", ["#8a3a2a", "#5a626b", "#4a6a5a"]]], "fh": 3.2, "st": [1, 2], "fix": true,
			"ch": 0.4, "ev": 0.5, "rv": {"deep_balcony": 0.4}},
		"apartments": {"w": [["render", CAPE]], "p": "punched", "wn": "sash", "fr": "#f4f1ea", "r": [["hipped", 1], ["flat", 1]],
			"rf": [["slate", ["#8a3a2a", "#5a626b"]]], "st": [2, 4], "fix": true, "rv": {"deep_balcony": 0.4}},
		"commercial": {"w": [["render", CAPE], ["stone", ["#a89878"]]], "p": [["punched", 2], ["ornate", 1]],
			"wn": "sash", "r": [["flat", 1], ["hipped", 1]], "rf": [["slate", ["#5a626b"]]], "st": [2, 4],
			"fix": true, "g": [["shop", 1]], "rv": {"deep_balcony": 0.3, "string_course": true}},
	},
	# Bo-Kaap: flat-roofed Cape Malay cottages painted in brights, with
	# parapets and stoeps.
	"cape_town_bokaap": {
		"house": {"w": [["render", BO_KAAP]], "p": "punched", "wn": "sash", "bay": 2.4, "fr": "#f4f1ea",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["concrete", ["#c8c4bc"]]], "fh": 3.2, "st": [1, 2],
			"fix": true, "ch": 0.2, "ev": 0.0, "rv": {"stoop": 0.6, "string_course": true}},
	},
	"cape_town_modern": {
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d4cc"]]], "p": [["curtain", 2], ["strip", 2]],
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [8, 30], "fix": true, "rv": {}},
		"apartments": {"w": [["concrete", ["#e8e4dc"]], ["glass", []]], "p": [["balcony", 3], ["strip", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [5, 15], "fix": true,
			"rv": {"deep_balcony": 0.5}},
	},
	# The modern city's colonies and flats: three to ten storeys of pale
	# render and concrete, deep balconies, flat roofs with water tanks.
	"delhi": {
		"apartments": {"w": [["render", NEW_DELHI], ["concrete", ["#d8d4cc"]]], "p": [["balcony", 3], ["punched", 2]],
			"wn": "wide", "bay": 3.0, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1, "st": [3, 10],
			"fix": true, "eq": 0.5, "g": [["shop", 1], ["none", 1]], "rv": {"deep_balcony": 0.4}},
		"house": {"w": [["render", NEW_DELHI]], "p": [["punched", 3], ["balcony", 1]], "wn": "casement", "bay": 3.0,
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1, "st": [2, 3], "fix": true, "eq": 0.4,
			"rv": {"deep_balcony": 0.3}},
		"commercial": {"w": [["render", NEW_DELHI], ["glass", []]], "p": [["strip", 2], ["curtain", 1]],
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 12], "fix": true,
			"g": [["shop", 1]], "rv": {}},
	},
	# Lutyens' Delhi: cream stucco and red sandstone bungalows, offices and
	# ministries of one to three storeys, deep verandas, flat roofs and domes.
	"delhi_lutyens": {
		"house": {"w": [["render", LUTYENS], ["stone", RED_SANDSTONE]], "p": "punched", "wn": "casement", "bay": 3.4,
			"fr": "#f4f1ea", "r": [["flat", 2], ["hipped", 2]], "pitch": 0.3, "rf": [["terracotta", ["#a8482a", "#9a4a2c"]], ["membrane", []]],
			"fh": 4.5, "st": [1, 2], "fix": true, "rv": {"string_course": true, "deep_balcony": 0.2}},
		"apartments": {"w": [["render", LUTYENS]], "p": [["ornate", 1], ["punched", 2]], "wn": "casement", "bay": 3.2,
			"fr": "#f4f1ea", "r": [["flat", 3], ["hipped", 1]], "pitch": 0.3, "rf": [["membrane", []]],
			"fh": 4.0, "st": [3, 5], "fix": true, "rv": {"string_course": true}},
		"civic": {"w": [["stone", RED_SANDSTONE], ["limestone", ["#e8dcc0", "#efe6d2"]]], "p": "ornate", "wn": "casement",
			"bay": 3.6, "r": [["flat", 3], ["dome", 1]], "rf": [["concrete", []]], "fh": 5.0, "st": [2, 4],
			"fix": true, "rv": {"string_course": true, "quoins": true}},
	},
	# Shahjahanabad: dense three- and four-storey havelis and shops of aged
	# render and red sandstone, jharokha balconies, flat roofs.
	"delhi_old": {
		"apartments": {"w": [["render", OLD_DELHI], ["stone", RED_SANDSTONE]], "p": [["ornate", 2], ["punched", 3]],
			"wn": "casement", "bay": 2.4, "fr": "#d8d0c0", "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 3.2, "st": [3, 4], "fix": true, "g": [["shop", 1]],
			"rv": {"deep_balcony": 0.6, "oriel": 0.4, "string_course": true}},
		"house": {"w": [["render", OLD_DELHI], ["stone", RED_SANDSTONE]], "p": [["ornate", 1], ["punched", 2]],
			"wn": "casement", "bay": 2.4, "r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.2, "st": [2, 4],
			"fix": true, "rv": {"deep_balcony": 0.5, "oriel": 0.4}},
		"commercial": {"w": [["render", OLD_DELHI]], "p": [["ornate", 1], ["punched", 2]], "wn": "casement",
			"bay": 2.4, "r": [["flat", 1]], "rf": [["membrane", []]], "st": [2, 4], "fix": true,
			"g": [["shop", 1]], "rv": {"deep_balcony": 0.5, "oriel": 0.3}},
	},
}

## Structural rules (BuildingEra._rules) for Bangkok (BK-3.2):
##   - Tall mapped buildings (8+ levels) reach `bangkok_condo` / `bangkok_tower` / `bangkok_hotel_river`.
##   - Inside Rattanakosin and inner historic circles, untagged/low buildings follow their
##     district (`bangkok_ratchadamnoen` 4-storey Art Deco, `bangkok_civic` ministries & City Hall,
##     `bangkok_oldtown` 2–3 storey yellow/cream shophouses, `bangkok_khaosan`, `bangkok_yaowarat`,
##     `bangkok_timber`); large civic/office footprints in old town become `bangkok_civic`.
static func bangkok_rule(kind: String, c: Dictionary) -> String:
	var lv := int(c["lv"])
	var area := float(c["area"])
	var district := str(c["district"])
	if lv >= 12:
		if district == "bangkok_hotel_river":
			return "bangkok_hotel_river"
		return "bangkok_condo" if kind == "apartments" else "bangkok_tower"
	if lv >= 8:
		if district == "bangkok_hotel_river":
			return "bangkok_hotel_river"
		if district == "bangkok_mall" and kind != "apartments":
			return "bangkok_mall"
		return "bangkok_condo" if kind == "apartments" else "bangkok_tower"
	if district == "bangkok_ratchadamnoen" and kind != "house":
		return "bangkok_civic" if area >= 4500.0 and kind == "civic" else "bangkok_ratchadamnoen"
	if district in ["bangkok_oldtown", "bangkok_civic"]:
		if kind == "civic" or (area >= 1200.0 and kind != "house"):
			return "bangkok_civic"
		return district
	if district in ["bangkok_khaosan", "bangkok_yaowarat", "bangkok_timber", "bangkok_shophouse"]:
		return district
	if district == "bangkok_mall" and kind in ["commercial", "civic"]:
		return "bangkok_mall"
	if district == "bangkok_hotel_river" and kind in ["apartments", "commercial"] and lv >= 6:
		return "bangkok_hotel_river"
	if kind == "house":
		return "bangkok_oldtown" if bool(c["heritage"]) else "bangkok"
	if lv >= 1 and lv <= 5:
		return "bangkok_shophouse"
	return "bangkok"

