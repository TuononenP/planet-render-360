class_name ArchitectureCitiesFlorida
extends RefCounted

## Greater Miami & South Florida city row (`miami`) and its 12 sub-era /
## district rows (`BuildingEra`): South Beach Tropical Art Deco, Biscayne &
## Mid/North Beach MiMo, Coral Gables & Coconut Grove Mediterranean Revival,
## Brickell / Downtown / Edgewater white-balcony condo towers & glass offices,
## Wynwood mural warehouses, Calle Ocho & arterial CBS strips, Little Havana /
## Little Haiti bungalows, postwar CBS ranches, waterfront villas, and open
## parking decks. Same row schema as ArchitectureData; real OSM tags always win.

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]
const ALL_IND := ["house", "apartments", "commercial", "civic", "industrial"]
const GARAGE_KINDS := ["outbuilding", "commercial", "apartments", "civic", "industrial", "house"]

## South Beach Tropical Deco pastels: flamingo pink, seafoam mint, lemon,
## aqua, coral peach and crisp stucco white.
const SOBE_PASTEL := ["#F6D2D8", "#CFECE4", "#F7EAB8", "#C8E8F0", "#FADAC6", "#F5F3EE"]
## Coral Gables & Coconut Grove Mediterranean Revival stucco: warm cream,
## sun-baked ochre and coral-salmon.
const GABLES_STUCCO := ["#EFE3CA", "#E5CE9F", "#E4BBA3", "#F2EAD8"]
## Brickell, Edgewater & Sunny Isles condo slab whites and cool greys.
const CONDO_WHITE := ["#F2F3F5", "#E8ECEF", "#DCE6EB", "#F6F5F0"]
## Concrete-block-and-stucco (CBS) low-rise residential & commercial render.
const CBS_LOWRISE := ["#EAE6DC", "#DFD9CA", "#D8E2DC", "#EFE7D6"]
## Wynwood Arts District vibrant street-mural palette mixed with painted CBS.
const WYNWOOD_MURAL := ["#E84A5F", "#2A9D8F", "#F4A261", "#3A86FF", "#FFBE0B", "#E9ECEF"]
## Elastomeric white / cool-grey South Florida flat roofs.
const COOL_ROOF := ["#E6E8EA", "#DCDFE2", "#F0F1F2"]
## Spanish clay barrel-tile roofs of Coral Gables, the Grove and Bay Islands.
const BARREL_TILE := ["#C45B33", "#B54D28", "#D16A3E", "#A94726"]

const MIMO_PASTEL := ["#CFECE4", "#C8E8F0", "#F5F3EE", "#F7EAB8", "#E8ECEF"]
const BUNGALOW_PASTEL := ["#EAE0CC", "#F2D5C4", "#D8EAD8", "#CFECE4", "#F7EAB8"]
const CORAL_STONE := ["#EAE0CC", "#E2D5BC", "#DFD2B8"]
const DECO_AWNINGS := ["#28B5B5", "#E85D75", "#F5B700", "#1E56A0"]

const BASE := {
	"miami": "north_america",
	"mi_deco": "miami",
	"mi_mimo": "miami",
	"mi_med_revival": "miami",
	"mi_condo_tower": "miami",
	"mi_condo_slab": "miami",
	"mi_office_glass": "miami",
	"mi_warehouse": "miami",
	"mi_strip": "miami",
	"mi_ranch": "miami",
	"mi_bungalow": "miami",
	"mi_mansion": "miami",
	"mi_garage": "miami",
}

## Miami district fabrics restricted to their own CityStyles circles unless an
## explicit `building:architecture` tag (or `industrial` kind for warehouses) names them.
const DISTRICT_ONLY_MIAMI := ["mi_deco", "mi_mimo", "mi_med_revival", "mi_warehouse"]

const ERAS := {
	"miami": [
		["mi_deco", ALL, 1925, 1945, ["art_deco", "streamline_moderne", "tropical_deco",
			"art_moderne"], 2.5, 0.0, 10.0, [2, 4], true],
		["mi_mimo", ACC, 1946, 1969, ["mimo", "miami_modern", "mid_century_modern",
			"googie"], 2.0, 0.0, 18.0, [2, 8]],
		["mi_med_revival", ALL, 1915, 1942, ["mediterranean_revival",
			"spanish_colonial_revival", "mission_revival", "italian_renaissance_revival"],
			2.5, 0.0, 16.0, [1, 5], true],
		["mi_bungalow", ["house"], 1910, 1947, ["bungalow", "craftsman", "conch",
			"bahamian", "frame_vernacular", "masonry_vernacular"], 3.0, 0.5, 12.0, [1, 2]],
		["mi_ranch", ["house"], 1948, 2100, ["ranch", "florida_ranch"], 4.5, 1.5, 99.0, [1, 2]],
		["mi_mansion", ["house"], 1920, 2100, ["villa", "mansion"], 1.5, 1.0, 99.0, [2, 3]],
		["mi_warehouse", ALL_IND, 1920, 1995, ["warehouse", "industrial"], 1.5, 0.5, 12.0, [1, 3]],
		["mi_strip", ACC, 1945, 2100, [], 3.5, 0.5, 99.0, [1, 2]],
		["miami", ALL, 1950, 2100, [], 3.5, 0.0, 99.0, [2, 6]],
		["mi_condo_slab", ACC, 1960, 2100, [], 3.0, 0.0, 99.0, [8, 18]],
		["mi_condo_tower", ACC, 1980, 2100, ["condominium", "residential_tower"],
			3.0, 0.0, 99.0, [16, 48]],
		["mi_office_glass", ACC, 1975, 2100, ["modern", "modernism", "modernist",
			"contemporary", "international_style", "postmodern", "high-tech", "high_tech",
			"skyscraper"], 2.5, 0.0, 99.0, [10, 40]],
		["mi_garage", GARAGE_KINDS, 1920, 2100, ["parking"], 0.5, 0.0, 99.0, [4, 9]],
	],
}

const REGIONS := {
	# Subtropical South Florida CBS / stucco baseline (overrides North America's
	# northern brick, clapboard, chimneys, dormers and fire escapes).
	"miami": {
		"house": {"w": [["render", CBS_LOWRISE], ["render", GABLES_STUCCO]], "p": "punched",
			"wn": "wide", "bay": 3.4, "fr": "#F6F5F0", "sh": "#3C6E71", "sp": 0.15,
			"r": [["hipped", 4], ["gabled", 2], ["flat", 2]], "pitch": 0.45,
			"rf": [["terracotta", BARREL_TILE], ["sheet_metal", COOL_ROOF], ["membrane", COOL_ROOF]],
			"fh": 3.0, "st": [1, 2], "ch": 0.0, "dm": 0.0, "eq": 0.1, "ev": 0.55,
			"rv": {"garage": 0.45}},
		"apartments": {"w": [["render", CONDO_WHITE], ["concrete", CONDO_WHITE], ["render", CBS_LOWRISE]],
			"p": [["balcony", 3], ["balcony_band", 2], ["punched", 2]], "wn": "wide",
			"bay": 3.4, "fr": "#F2F3F5", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.1, "st": [3, 6], "ch": 0.0, "dm": 0.0,
			"eq": 0.65, "g": [["none", 2], ["shop", 1]], "ev": 0.2,
			"rv": {"deep_balcony": 0.35}},
		"commercial": {"w": [["render", CBS_LOWRISE], ["concrete", CONDO_WHITE], ["glass", []]],
			"p": [["strip", 3], ["punched", 1]], "wn": "wide", "bay": 3.6, "fr": "#DCE2E6",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 3.6,
			"st": [2, 6], "ch": 0.0, "dm": 0.0, "eq": 0.75, "g": [["shop", 3], ["signage", 1]],
			"rv": {"awning": 0.3, "awning_colours": DECO_AWNINGS, "signage": 0.3}},
		"industrial": {"w": [["concrete", CBS_LOWRISE], ["render", CONDO_WHITE]],
			"p": [["industrial", 3], ["strip", 1]], "wn": "wide", "bay": 4.5, "fr": "#545B62",
			"sp": 0.0, "r": [["flat", 4], ["gabled", 1]], "pitch": 0.25,
			"rf": [["membrane", COOL_ROOF], ["sheet_metal", COOL_ROOF]],
			"fh": 4.8, "st": [1, 2], "ch": 0.0, "dm": 0.0, "eq": 0.6, "ev": 0.15, "rv": {}},
		"civic": {"w": [["render", CONDO_WHITE], ["render", GABLES_STUCCO], ["concrete", CONDO_WHITE]],
			"p": [["strip", 2], ["punched", 2]], "wn": "wide", "bay": 3.8, "fr": "#F2F3F5",
			"sp": 0.0, "r": [["flat", 3], ["hipped", 2]], "pitch": 0.5,
			"rf": [["membrane", COOL_ROOF], ["terracotta", BARREL_TILE]],
			"fh": 3.9, "st": [2, 5], "ch": 0.0, "dm": 0.0, "eq": 0.5, "rv": {}},
		"religious": {"w": [["render", GABLES_STUCCO], ["render", CONDO_WHITE]], "p": "ornate",
			"wn": "french", "bay": 3.8, "fr": "#F5F3EE", "sp": 0.0,
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.75,
			"rf": [["terracotta", BARREL_TILE]], "fh": 4.6, "st": [1, 2], "ch": 0.0, "dm": 0.0,
			"eq": 0.0, "tw": "bell", "ev": 0.4, "rv": {"string_course": true}},
		"outbuilding": {"w": [["render", CBS_LOWRISE], ["concrete", CONDO_WHITE]], "p": "punched",
			"wn": "small", "bay": 3.0, "fr": "#F2F3F5", "sp": 0.0,
			"r": [["flat", 3], ["hipped", 2]], "pitch": 0.4,
			"rf": [["membrane", COOL_ROOF], ["terracotta", BARREL_TILE]],
			"fh": 2.8, "st": [1, 1], "ch": 0.0, "dm": 0.0, "eq": 0.0, "rv": {}},
	},
	# Ocean Drive, Collins & Flamingo Park (1925–45): pastel smooth stucco,
	# eyebrow ledges, stepped/ziggurat deco parapets and striped canvas awnings.
	"mi_deco": {
		"commercial": {"w": [["render", SOBE_PASTEL]], "p": [["strip", 3], ["punched", 2]],
			"wn": ["wide", "casement"], "bay": 3.2, "fr": "#F7F6F2", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 3.4, "st": [2, 4],
			"fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.2, "g": [["shop", 3], ["render", 1]],
			"gc": DECO_AWNINGS, "ev": 0.0,
			"rv": {"deco_front": true, "string_course": true, "awning": 0.45,
				"awning_colours": DECO_AWNINGS}},
		"apartments": {"w": [["render", SOBE_PASTEL]], "p": [["punched", 3], ["strip", 2]],
			"wn": ["wide", "casement"], "bay": 3.1, "fr": "#F7F6F2", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 3.2, "st": [2, 4],
			"fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.2, "g": [["render", 2], ["shop", 1]],
			"gc": DECO_AWNINGS, "ev": 0.0,
			"rv": {"deco_front": true, "string_course": true, "awning": 0.45,
				"awning_colours": DECO_AWNINGS}},
		"civic": {"w": [["render", SOBE_PASTEL]], "p": [["strip", 2], ["ornate", 2]],
			"wn": ["wide", "casement"], "bay": 3.4, "fr": "#F7F6F2", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 3.6, "st": [2, 4],
			"fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.2, "ev": 0.0,
			"rv": {"deco_front": true, "string_course": true, "awning": 0.45,
				"awning_colours": DECO_AWNINGS}},
		"house": {"w": [["render", SOBE_PASTEL]], "p": "punched", "wn": ["wide", "casement"],
			"bay": 3.0, "fr": "#F7F6F2", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.1, "st": [1, 2], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.1, "ev": 0.0,
			"rv": {"deco_front": true, "string_course": true, "awning": 0.45,
				"awning_colours": DECO_AWNINGS}},
	},
	# Biscayne Boulevard, Mid-Beach & North Beach MiMo (1946–69): aqua, mint
	# and crisp white render/concrete, catwalk balconies and canted/flat roofs.
	"mi_mimo": {
		"apartments": {"w": [["render", MIMO_PASTEL], ["concrete", CONDO_WHITE]],
			"p": [["balcony", 3], ["strip", 2]], "wn": "wide", "bay": 3.4, "fr": "#F5F6F7",
			"sp": 0.0, "r": [["flat", 4], ["skillion", 1]], "pitch": 0.22,
			"rf": [["membrane", COOL_ROOF]], "fh": 3.1, "st": [2, 8], "fix": true,
			"ch": 0.0, "eq": 0.45, "g": [["none", 2], ["shop", 1]], "ev": 0.25,
			"rv": {"deep_balcony": 0.55, "awning": 0.35, "awning_colours": DECO_AWNINGS}},
		"commercial": {"w": [["render", MIMO_PASTEL], ["concrete", CONDO_WHITE]],
			"p": [["strip", 3], ["balcony", 2]], "wn": "wide", "bay": 3.6, "fr": "#F5F6F7",
			"sp": 0.0, "r": [["flat", 3], ["skillion", 1]], "pitch": 0.22,
			"rf": [["membrane", COOL_ROOF]], "fh": 3.4, "st": [2, 8], "fix": true,
			"ch": 0.0, "eq": 0.5, "g": [["shop", 3], ["signage", 1]], "ev": 0.3,
			"rv": {"deep_balcony": 0.55, "awning": 0.35, "awning_colours": DECO_AWNINGS}},
		"civic": {"w": [["render", MIMO_PASTEL], ["concrete", CONDO_WHITE]],
			"p": "strip", "wn": "wide", "bay": 3.6, "fr": "#F5F6F7", "sp": 0.0,
			"r": [["flat", 3], ["skillion", 1]], "pitch": 0.2, "rf": [["membrane", COOL_ROOF]],
			"fh": 3.6, "st": [2, 6], "fix": true, "rv": {"deep_balcony": 0.35, "awning": 0.35,
				"awning_colours": DECO_AWNINGS}},
	},
	# Coral Gables & Coconut Grove Village (1915–42): ochre, cream & coral
	# stucco, arched/ornate openings, wrought-iron balconettes & barrel tile.
	"mi_med_revival": {
		"commercial": {"w": [["render", GABLES_STUCCO], ["limestone", CORAL_STONE]],
			"p": [["ornate", 3], ["punched", 2]], "wn": ["french", "casement"], "bay": 3.2,
			"fr": "#4A3828", "sh": "#2F4F3E", "sp": 0.25, "rl": 0.35,
			"r": [["hipped", 4], ["gabled", 2]], "pitch": 0.55,
			"rf": [["terracotta", BARREL_TILE]], "fh": 3.6, "st": [2, 5], "fix": true,
			"ch": 0.0, "eq": 0.15, "g": [["shop", 3], ["stone", 2]], "ev": 0.55,
			"rv": {"string_course": true, "balconette": 0.35, "quoins": true}},
		"apartments": {"w": [["render", GABLES_STUCCO], ["limestone", CORAL_STONE]],
			"p": [["ornate", 2], ["punched", 3]], "wn": ["french", "casement"], "bay": 3.1,
			"fr": "#4A3828", "sh": "#2F4F3E", "sp": 0.3, "rl": 0.35,
			"r": [["hipped", 4], ["gabled", 2]], "pitch": 0.55,
			"rf": [["terracotta", BARREL_TILE]], "fh": 3.3, "st": [2, 5], "fix": true,
			"ch": 0.0, "eq": 0.15, "g": [["stone", 2], ["shop", 1]], "ev": 0.55,
			"rv": {"string_course": true, "balconette": 0.35, "quoins": true}},
		"civic": {"w": [["render", GABLES_STUCCO], ["limestone", CORAL_STONE]],
			"p": "ornate", "wn": ["french", "casement"], "bay": 3.6, "fr": "#4A3828",
			"sp": 0.15, "r": [["hipped", 4], ["gabled", 1]], "pitch": 0.6,
			"rf": [["terracotta", BARREL_TILE]], "fh": 4.0, "st": [2, 5], "fix": true,
			"ch": 0.0, "eq": 0.1, "g": [["stone", 1]], "ev": 0.6,
			"rv": {"string_course": true, "balconette": 0.35, "quoins": true}},
		"house": {"w": [["render", GABLES_STUCCO], ["limestone", CORAL_STONE]],
			"p": [["punched", 3], ["ornate", 2]], "wn": ["french", "casement"], "bay": 3.2,
			"fr": "#4A3828", "sh": "#2F4F3E", "sp": 0.35, "rl": 0.25,
			"r": [["hipped", 4], ["gabled", 2]], "pitch": 0.58,
			"rf": [["terracotta", BARREL_TILE]], "fh": 3.2, "st": [1, 3], "fix": true,
			"ch": 0.0, "eq": 0.0, "ev": 0.65,
			"rv": {"string_course": true, "balconette": 0.35, "quoins": true}},
	},
	# Brickell, Edgewater, Park West & South of Fifth (1980–present): tall
	# white slab-edge continuous balcony condo towers over blue-green glass.
	"mi_condo_tower": {
		"apartments": {"w": [["concrete", CONDO_WHITE], ["render", CONDO_WHITE], ["glass", []]],
			"p": "balcony_band", "wn": "wide", "bay": 3.6, "fr": "#E8ECEF", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 3.15,
			"st": [16, 48], "fix": true, "ch": 0.0, "eq": 0.85,
			"g": [["none", 2], ["shop", 1]], "ev": 0.0, "rv": {"glazed_balcony": 0.55}},
		"commercial": {"w": [["concrete", CONDO_WHITE], ["glass", []]],
			"p": [["balcony_band", 3], ["curtain", 2]], "wn": "wide", "bay": 3.6,
			"fr": "#E8ECEF", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]],
			"fh": 3.4, "st": [16, 42], "fix": true, "eq": 0.85,
			"g": [["shop", 2], ["stone", 1]], "rv": {"glazed_balcony": 0.55}},
		"civic": {"w": [["concrete", CONDO_WHITE], ["glass", []]], "p": "balcony_band",
			"wn": "wide", "bay": 3.6, "fr": "#E8ECEF", "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.5, "st": [16, 32], "fix": true,
			"rv": {"glazed_balcony": 0.45}},
	},
	# Mid-rise condo & resort hotel slabs (Collins Ave, South Brickell, Midtown):
	# 8–18 storeys of crisp white concrete & continuous balcony bands.
	"mi_condo_slab": {
		"apartments": {"w": [["render", CONDO_WHITE], ["concrete", CONDO_WHITE]],
			"p": [["balcony_band", 3], ["balcony", 2]], "wn": "wide", "bay": 3.4,
			"fr": "#E8ECEF", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]],
			"fh": 3.1, "st": [8, 18], "fix": true, "ch": 0.0, "eq": 0.75,
			"g": [["none", 2], ["shop", 1]], "ev": 0.0, "rv": {"deep_balcony": 0.45}},
		"commercial": {"w": [["render", CONDO_WHITE], ["concrete", CONDO_WHITE]],
			"p": [["balcony_band", 2], ["balcony", 2], ["strip", 1]], "wn": "wide",
			"bay": 3.5, "fr": "#E8ECEF", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.3, "st": [8, 18], "fix": true,
			"eq": 0.75, "g": [["shop", 2], ["render", 1]], "rv": {"deep_balcony": 0.45}},
		"civic": {"w": [["concrete", CONDO_WHITE], ["render", CONDO_WHITE]],
			"p": [["strip", 2], ["balcony", 1]], "wn": "wide", "bay": 3.6,
			"fr": "#E8ECEF", "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]],
			"fh": 3.6, "st": [8, 16], "fix": true, "rv": {"deep_balcony": 0.3}},
	},
	# Downtown CBD, Brickell Ave & Health/Civic office towers: reflective
	# blue-green / silver glass curtain walls.
	"mi_office_glass": {
		"commercial": {"w": [["glass", []]], "p": "curtain", "wn": "wide", "bay": 3.6,
			"fr": "#C8D2D8", "sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]],
			"fh": 3.9, "st": [10, 40], "fix": true, "ch": 0.0, "eq": 0.85,
			"g": [["shop", 2], ["stone", 1]], "ev": 0.0, "rv": {"mullion": true}},
		"apartments": {"w": [["glass", []], ["concrete", CONDO_WHITE]], "p": "curtain",
			"wn": "wide", "bay": 3.6, "fr": "#C8D2D8", "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.3, "st": [10, 40], "fix": true,
			"eq": 0.8, "rv": {"mullion": true}},
		"civic": {"w": [["glass", []], ["concrete", CONDO_WHITE]],
			"p": [["curtain", 3], ["strip", 1]], "wn": "wide", "bay": 3.8, "fr": "#C8D2D8",
			"r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 4.0, "st": [6, 24],
			"fix": true, "eq": 0.8, "rv": {"mullion": true}},
	},
	# Wynwood Arts District, Allapattah & PortMiami: 1–2 storey CBS warehouses
	# and galleries with bold street-art mural walls and cool white flat roofs.
	"mi_warehouse": {
		"industrial": {"w": [["render", WYNWOOD_MURAL], ["concrete", CBS_LOWRISE]],
			"p": [["industrial", 3], ["strip", 2]], "wn": "wide", "bay": 4.4, "fr": "#383E44",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 4.6,
			"st": [1, 2], "fix": true, "ch": 0.0, "eq": 0.55, "ev": 0.0,
			"rv": {"sign_bands": 0.35, "awning": 0.25, "awning_colours": WYNWOOD_MURAL}},
		"commercial": {"w": [["render", WYNWOOD_MURAL], ["concrete", CBS_LOWRISE]],
			"p": [["strip", 3], ["industrial", 2]], "wn": "wide", "bay": 4.2, "fr": "#383E44",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 4.4,
			"st": [1, 2], "fix": true, "ch": 0.0, "eq": 0.55,
			"g": [["shop", 3], ["signage", 2]], "gc": WYNWOOD_MURAL, "ev": 0.0,
			"rv": {"sign_bands": 0.35, "awning": 0.25, "awning_colours": WYNWOOD_MURAL}},
		"apartments": {"w": [["render", CBS_LOWRISE], ["render", WYNWOOD_MURAL]],
			"p": [["strip", 2], ["punched", 2]], "wn": "wide", "bay": 3.8, "fr": "#383E44",
			"sp": 0.0, "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]], "fh": 3.5,
			"st": [1, 3], "fix": true, "eq": 0.45, "ev": 0.0,
			"rv": {"sign_bands": 0.2, "awning": 0.25, "awning_colours": WYNWOOD_MURAL}},
		"civic": {"w": [["render", WYNWOOD_MURAL], ["concrete", CBS_LOWRISE]],
			"p": "strip", "wn": "wide", "bay": 4.2, "fr": "#383E44", "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 4.5, "st": [1, 2], "fix": true,
			"rv": {"sign_bands": 0.35, "awning": 0.25, "awning_colours": WYNWOOD_MURAL}},
		"house": {"w": [["render", CBS_LOWRISE]], "p": "punched", "wn": "wide", "bay": 3.2,
			"fr": "#F2F3F5", "r": [["flat", 2], ["gabled", 2]], "pitch": 0.35,
			"rf": [["membrane", COOL_ROOF]], "fh": 3.1, "st": [1, 2], "fix": true, "rv": {}},
	},
	# Calle Ocho, SW 8th St, Flagler & arterial commercial strips: 1–2 storey
	# stucco retail rows with continuous shopfronts, signage fascias & awnings.
	"mi_strip": {
		"commercial": {"w": [["render", CBS_LOWRISE]], "p": "strip", "wn": "wide",
			"bay": 3.6, "fr": "#42484E", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.8, "st": [1, 2], "fix": true,
			"ch": 0.0, "eq": 0.65, "g": [["shop", 4], ["signage", 2]],
			"gc": ["#1E56A0", "#28B5B5", "#C83E37", "#D89A1E"], "ev": 0.0,
			"rv": {"signage": 0.65, "awning": 0.5, "awning_colours": DECO_AWNINGS}},
		"apartments": {"w": [["render", CBS_LOWRISE]], "p": [["punched", 2], ["balcony", 2]],
			"wn": "wide", "bay": 3.4, "fr": "#F2F3F5", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["membrane", COOL_ROOF]], "fh": 3.0, "st": [2, 4], "fix": true,
			"eq": 0.5, "g": [["shop", 2], ["none", 2]],
			"rv": {"awning": 0.35, "awning_colours": DECO_AWNINGS}},
		"civic": {"w": [["render", CBS_LOWRISE]], "p": "strip", "wn": "wide", "bay": 3.6,
			"fr": "#42484E", "r": [["flat", 1]], "rf": [["membrane", COOL_ROOF]],
			"fh": 3.8, "st": [1, 2], "fix": true, "rv": {"awning": 0.35,
				"awning_colours": DECO_AWNINGS}},
	},
	# Postwar South Florida CBS suburban ranch house (1948–present): single
	# storey, low-pitched barrel-tile or white metal/cool roof and carport/garage.
	"mi_ranch": {
		"house": {"w": [["render", CBS_LOWRISE]], "p": "punched", "wn": "wide", "bay": 3.5,
			"fr": "#F4F3EE", "sh": "#4A646C", "sp": 0.15,
			"r": [["hipped", 4], ["flat", 2]], "pitch": 0.42,
			"rf": [["terracotta", BARREL_TILE], ["sheet_metal", COOL_ROOF], ["membrane", COOL_ROOF]],
			"fh": 2.9, "st": [1, 1], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.0, "ev": 0.65,
			"rv": {"garage": 0.55}},
	},
	# Little Havana, Shenandoah, Little Haiti & Overtown pre-1948 bungalows:
	# pastel/cream stucco and oolitic coral-stone cottages under gabled/hipped roofs.
	"mi_bungalow": {
		"house": {"w": [["render", BUNGALOW_PASTEL], ["limestone", CORAL_STONE]],
			"p": "punched", "wn": ["casement", "sash"], "bay": 2.9, "fr": "#F7F5EE",
			"sh": "#2D5A4C", "sp": 0.35, "r": [["gabled", 3], ["hipped", 2]], "pitch": 0.58,
			"rf": [["terracotta", BARREL_TILE], ["sheet_metal", ["#D8DCE0", "#5C7A72"]]],
			"fh": 3.0, "st": [1, 2], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.0, "ev": 0.7,
			"rv": {}},
	},
	# Star, Palm, Hibiscus & Venetian Islands, Key Biscayne & Coconut Grove
	# waterfront estates: crisp white modernist or Mediterranean barrel-tile villas.
	"mi_mansion": {
		"house": {"w": [["render", CONDO_WHITE + GABLES_STUCCO], ["limestone", CORAL_STONE]],
			"p": [["punched", 2], ["balcony", 2]], "wn": ["french", "wide"], "bay": 3.8,
			"fr": "#F5F4EF", "sp": 0.1, "r": [["hipped", 3], ["flat", 2]], "pitch": 0.52,
			"rf": [["terracotta", BARREL_TILE], ["membrane", COOL_ROOF]],
			"fh": 3.5, "st": [2, 3], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.15,
			"ev": 0.55, "rv": {"deep_balcony": 0.4}},
	},
	# Open-deck concrete parking structures (Downtown, Brickell, Miami Beach, Health District).
	"mi_garage": {
		"outbuilding": {"w": [["concrete", CONDO_WHITE]], "p": [["louvre", 3], ["strip", 2]],
			"wn": "wide", "bay": 4.2, "fr": "#CFD6DC", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", COOL_ROOF]], "fh": 3.1, "st": [4, 9], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.3, "ev": 0.0, "rv": {}},
		"commercial": {"w": [["concrete", CONDO_WHITE]], "p": [["louvre", 3], ["strip", 2]],
			"wn": "wide", "bay": 4.2, "fr": "#CFD6DC", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", COOL_ROOF]], "fh": 3.1, "st": [4, 9], "fix": true,
			"ch": 0.0, "eq": 0.3, "g": [["shop", 1], ["none", 2]], "ev": 0.0, "rv": {}},
		"apartments": {"w": [["concrete", CONDO_WHITE]], "p": [["louvre", 3], ["strip", 2]],
			"wn": "wide", "bay": 4.2, "fr": "#CFD6DC", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", COOL_ROOF]], "fh": 3.1, "st": [4, 9], "fix": true,
			"eq": 0.3, "ev": 0.0, "rv": {}},
		"civic": {"w": [["concrete", CONDO_WHITE]], "p": [["louvre", 3], ["strip", 2]],
			"wn": "wide", "bay": 4.2, "fr": "#CFD6DC", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", COOL_ROOF]], "fh": 3.1, "st": [4, 9], "fix": true,
			"eq": 0.3, "ev": 0.0, "rv": {}},
		"industrial": {"w": [["concrete", CONDO_WHITE]], "p": [["louvre", 3], ["strip", 2]],
			"wn": "wide", "bay": 4.2, "fr": "#CFD6DC", "sp": 0.0, "r": [["flat", 1]],
			"rf": [["concrete", COOL_ROOF]], "fh": 3.1, "st": [4, 9], "fix": true,
			"eq": 0.3, "ev": 0.0, "rv": {}},
		"house": {"w": [["concrete", CONDO_WHITE]], "p": "louvre", "wn": "wide", "bay": 4.0,
			"fr": "#CFD6DC", "r": [["flat", 1]], "rf": [["concrete", COOL_ROOF]],
			"fh": 3.0, "st": [2, 4], "fix": true, "rv": {}},
	},
}

## Structural rules (BuildingEra._rules) for Greater Miami:
##   - Parking structures (`garage`, `garages`, `parking`) -> `mi_garage`.
##   - Tall towers (`lv >= 15`) -> `mi_office_glass` (commercial) else `mi_condo_tower`.
##   - Mid/high slabs (`lv >= 8`) -> `mi_office_glass` in office districts else `mi_condo_slab`.
##   - Historic & arts districts (`mi_deco`, `mi_mimo`, `mi_med_revival`, `mi_warehouse`,
##     `mi_mansion`) shape low/mid-rise buildings inside their circles.
##   - Detached houses resolve to `mi_bungalow` in pre-war neighbourhoods or by pre-1948
##     date, else `mi_ranch` (or `mi_mansion` on large 2+ storey footprints).
static func miami_rule(kind: String, c: Dictionary) -> String:
	var district := str(c["district"])
	var lv := int(c["lv"])
	var year := int(c["year"])
	var tag := str(c["tag"])
	var area := float(c["area"])
	if tag in ["garage", "garages", "parking"]:
		return "mi_garage"
	if lv >= 15:
		return "mi_office_glass" if kind == "commercial" else "mi_condo_tower"
	if lv >= 8:
		return "mi_office_glass" if kind == "commercial" and district == "mi_office_glass" else "mi_condo_slab"
	if district == "mi_deco" and lv <= 6:
		return "mi_deco"
	if district == "mi_mimo" and lv <= 9:
		return "mi_mimo"
	if district == "mi_med_revival" and lv <= 7:
		return "mi_med_revival"
	if district == "mi_warehouse" and lv <= 3:
		return "mi_warehouse"
	if district == "mi_mansion" and kind == "house":
		return "mi_mansion"
	if kind == "industrial":
		return "mi_warehouse"
	if kind == "commercial" and lv >= 1 and lv <= 2:
		return "mi_strip"
	if kind == "house":
		if district in ["mi_bungalow", "mi_strip"] or (year > 0 and year < 1948):
			return "mi_bungalow"
		if area >= 420.0 and lv >= 2:
			return "mi_mansion"
		return "mi_ranch"
	if district != "" and (lv == 0 or district in ["mi_condo_slab", "mi_strip"]):
		return district
	return "mi_condo_slab" if lv >= 5 else "mi_strip"
