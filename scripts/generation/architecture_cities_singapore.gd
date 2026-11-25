class_name ArchitectureCitiesSingapore
extends RefCounted

## Singapore city fabric rules & 10 district/typology rows (`PLAN_Singapore_super_realistic.md`, SG-5):
## Replaces the naive `lv <= 4 -> sg_shophouse` fallback in `BuildingEra` with a district-first,
## footprint-geometry-aware rule that handles untyped `building=yes` (80% of OSM buildings in SG):
## - Shophouses (`sg_shophouse`) with five-foot-way arcades & pastel shutters ONLY in shophouse
##   districts or on narrow terraced 1–4 storey plots
## - HDB estates split by era (`sg_hdb_slab` 1960s–80s colour bands & block numbers,
##   `sg_hdb_point` 1990s point blocks, `sg_hdb_new` 2000s+ 30–50 storey BTO precast towers)
## - `sg_condo`, `sg_colonial` (Civic District), `sg_blackwhite`, `sg_artdeco` (Tiong Bahru),
##   `sg_mall` (Orchard/Bugis LED media facades), `sg_industrial`, `sg_house`.

const HDB_PASTELS := ["#ecebe6", "#e8e4dc", "#f0ece4", "#e4e0d8", "#e6e8ec"]
const HDB_ACCENTS := ["#c84a3a", "#3a6a9a", "#e8a030", "#4a8a5a", "#8a5a9a", "#d87a4a"]
const PERANAKAN := ["#f0d088", "#a8d4be", "#f0b0a8", "#b4d0e8", "#f2e2b4", "#d4e8c4", "#ecc0d2", "#c8dcf0"]
const COLONIAL_WHITE := ["#f4f2ec", "#efeae0", "#f6f4ee", "#eae4d8"]
const TIONG_BAHRU := ["#f2f0ea", "#eae8e2", "#e4e2dc"]
const CONDO_WALL := ["#eef0f2", "#e4e8ec", "#dfe4e8", "#eceae4"]

const BASE := {
	"sg_hdb_slab": "singapore",
	"sg_hdb_point": "singapore",
	"sg_hdb_new": "singapore",
	"sg_condo": "sg_tower",
	"sg_colonial": "singapore",
	"sg_blackwhite": "sg_colonial",
	"sg_artdeco": "singapore",
	"sg_mall": "sg_tower",
	"sg_industrial": "singapore",
	"sg_house": "singapore",
}

const REGIONS := {
	# 1960s–80s HDB slab blocks: long corridors, painted colour bands, void deck & block numbers.
	"sg_hdb_slab": {
		"apartments": {"w": [["render", HDB_PASTELS], ["concrete", ["#dcd8d0"]]],
			"p": [["panel", 3], ["balcony", 2]], "wn": "wide", "bay": 3.0, "fr": "#8a8c8e",
			"sh": HDB_ACCENTS, "sp": 1.0, "rl": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.8, "st": [10, 18], "fix": true, "ch": 0.0, "eq": 0.65,
			"g": [["none", 3], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.25, "danji_number": 0.85}},
	},
	# 1990s HDB point blocks: compact square plans, bay windows, pitched/hipped roof caps.
	"sg_hdb_point": {
		"apartments": {"w": [["render", HDB_PASTELS], ["concrete", ["#e0dcd4"]]],
			"p": [["panel", 2], ["balcony", 3]], "wn": "wide", "bay": 3.0, "fr": "#80868c",
			"sh": HDB_ACCENTS, "sp": 0.9, "rl": 0.0, "r": [["hipped", 2], ["flat", 1]], "pitch": 0.35,
			"rf": [["terracotta", ["#9a4834", "#5c6268"]], ["membrane", []]],
			"fh": 2.85, "st": [16, 26], "fix": true, "ch": 0.0, "eq": 0.6,
			"g": [["none", 3], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.35, "danji_number": 0.8}},
	},
	# 2000s–2020s tall BTO precast HDB towers: crisp white/grey/teal precast, sky-gardens.
	"sg_hdb_new": {
		"apartments": {"w": [["concrete", CONDO_WALL], ["render", HDB_PASTELS]],
			"p": [["balcony", 3], ["panel", 2]], "wn": "wide", "bay": 3.0, "fr": "#6a7278",
			"sh": HDB_ACCENTS, "sp": 0.6, "rl": 0.0, "r": [["flat", 1]], "rf": [["membrane", []]],
			"fh": 2.9, "st": [28, 48], "fix": true, "ch": 0.0, "eq": 0.75,
			"g": [["none", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.45, "danji_number": 0.7}},
	},
	# Private Singapore condominiums: glazed balconies, pale precast fins, pool-deck podiums.
	"sg_condo": {
		"apartments": {"w": [["glass", []], ["render", CONDO_WALL]],
			"p": [["balcony", 3], ["curtain", 2]], "wn": "wide", "bay": 3.0, "fr": "#58646e",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.1, "st": [18, 42], "fix": true,
			"ch": 0.0, "eq": 0.7, "g": [["none", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.55, "glazed_balcony": 0.6}},
	},
	# Civic District colonial heritage: white plaster, deep verandas, green shutters, terracotta roofs.
	"sg_colonial": {
		"civic": {"w": [["render", COLONIAL_WHITE], ["limestone", COLONIAL_WHITE]],
			"p": "shophouse", "wn": "french", "bay": 3.2, "fr": "#f4f1ea",
			"sh": ["#2d5a42", "#3a624a", "#4a443c"], "sp": 0.8, "rl": 0.5,
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.48,
			"rf": [["terracotta", ["#a64a32", "#98422c"]]], "fh": 4.2, "st": [2, 4], "fix": true,
			"ch": 0.0, "eq": 0.15, "g": [["none", 1]], "ev": 0.6,
			"rv": {"string_course": true, "cornice": 0.7}},
		"commercial": {"w": [["render", COLONIAL_WHITE]],
			"p": "shophouse", "wn": "french", "bay": 3.0, "fr": "#f4f1ea",
			"sh": ["#2d5a42", "#2a4a6a"], "sp": 0.8, "rl": 0.4,
			"r": [["hipped", 2], ["gabled", 1]], "pitch": 0.5,
			"rf": [["terracotta", ["#a64a32", "#b25236"]]], "fh": 3.8, "st": [2, 4], "fix": true,
			"g": [["shop", 2], ["none", 1]], "ev": 0.5, "rv": {"string_course": true, "cornice": 0.5}},
	},
	# Black-and-white colonial bungalows (Goodwood, Tanglin, Adam Park, Dempsey).
	"sg_blackwhite": {
		"house": {"w": [["render", ["#f5f4ef", "#f0eee8"]]],
			"p": "shophouse", "wn": "french", "bay": 3.0, "fr": "#1e2022",
			"sh": ["#1e2022", "#242824"], "sp": 0.9, "rl": 0.4,
			"r": [["hipped", 1]], "pitch": 0.52,
			"rf": [["terracotta", ["#9a442e", "#8e3e28"]]], "fh": 3.8, "st": [2, 2], "fix": true,
			"ev": 0.8, "rv": {"string_course": true}},
	},
	# Tiong Bahru 1930s Streamline Moderne / Art Deco curved white walk-up flats.
	"sg_artdeco": {
		"apartments": {"w": [["render", TIONG_BAHRU]],
			"p": [["strip", 3], ["balcony", 2]], "wn": "wide", "bay": 2.8, "fr": "#485258",
			"sp": 0.0, "rl": 0.0, "r": [["flat", 1]], "rf": [["concrete", ["#c8c4bc"]]],
			"fh": 3.2, "st": [3, 5], "fix": true, "ch": 0.0, "eq": 0.25,
			"g": [["shop", 1], ["none", 2]], "ev": 0.0,
			"rv": {"string_course": true, "deep_balcony": 0.4, "deco_front": true}},
	},
	# Orchard, Bugis & Marina shopping malls: glass + architectural screens & glowing LED media facades.
	"sg_mall": {
		"commercial": {"w": [["glass", []], ["concrete", ["#e2e0da", "#d4d8dc"]]],
			"p": [["curtain", 3], ["strip", 2]], "wn": "wide", "bay": 3.2, "fr": "#384048",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.8, "st": [4, 10], "fix": true,
			"ch": 0.0, "eq": 0.9, "g": [["shop", 3], ["signage", 2]], "ev": 0.0,
			"rv": {"signage": 0.8, "screens": 0.75, "awning": 0.2}},
	},
	# Singapore JTC flatted factories & industrial blocks.
	"sg_industrial": {
		"commercial": {"w": [["concrete", ["#d4d2cc", "#c8c6c0", "#dcdad4"]]],
			"p": "strip", "wn": "wide", "bay": 3.6, "fr": "#6a6e72",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 4.2, "st": [4, 9], "fix": true,
			"ch": 0.0, "eq": 0.85, "g": [["none", 1]], "ev": 0.0, "rv": {}},
	},
	# Landed terrace & semi-detached houses (Katong, River Valley, Bukit Timah).
	"sg_house": {
		"house": {"w": [["render", PERANAKAN]],
			"p": "punched", "wn": "french", "bay": 2.6, "fr": "#eae6de",
			"sh": ["#2f5a46", "#5a4236", "#2a4a6a"], "sp": 0.5, "rl": 0.2,
			"r": [["gabled", 2], ["hipped", 2]], "pitch": 0.48,
			"rf": [["terracotta", ["#a64a32", "#8e402c", "#54585e"]]], "fh": 3.2, "st": [2, 3], "fix": true,
			"ev": 0.5, "rv": {"balconette": 0.3, "string_course": true}},
	},
}

## District-first, footprint-geometry-aware Singapore building style rule (`BuildingEra` match arm).
static func singapore_rule(kind: String, c: Dictionary) -> String:
	var district := str(c.get("district", ""))
	var lv := int(c.get("levels", c.get("lv", 0)))
	var area := float(c.get("area", 0.0))
	var year := int(c.get("year", 0))
	var narrow := bool(c.get("small", false)) or (area > 0.0 and area <= 420.0)

	# 1. Tall towers anywhere in Singapore -> CBD/Marina glass tower, modern BTO HDB, or condo.
	if lv >= 30:
		if district in ["sg_hdb_slab", "sg_hdb_point", "sg_hdb_new"]:
			return "sg_hdb_new"
		if kind == "apartments" and district == "sg_condo":
			return "sg_condo"
		return "sg_tower"
	if lv >= 12 and kind == "commercial":
		return "sg_tower"

	# 2. District-first classification for Singapore's iconic heritage & residential quarters.
	match district:
		"sg_shophouse":
			if lv <= 4 and (narrow or area <= 900.0):
				return "sg_shophouse"
			if lv >= 12:
				return "sg_tower"
		"sg_colonial":
			if lv <= 6:
				return "sg_colonial"
			return "sg_tower"
		"sg_artdeco":
			if lv <= 6:
				return "sg_artdeco"
		"sg_mall":
			if lv <= 12 and area >= 900.0:
				return "sg_mall"
			if lv >= 12:
				return "sg_tower"
		"sg_condo":
			if kind == "apartments" or lv >= 6:
				return "sg_condo"
		"sg_hdb_slab", "sg_hdb_point", "sg_hdb_new":
			if kind == "apartments" or lv >= 6:
				if year >= 2002 or lv >= 26:
					return "sg_hdb_new"
				if area > 0.0 and area <= 950.0 and lv >= 14:
					return "sg_hdb_point"
				return "sg_hdb_slab"
		"sg_tower":
			if lv >= 8 or area >= 900.0:
				return "sg_tower"

	# 3. Shape & typology fallback (fixes the old bug where every 1–4 storey building became a shophouse).
	if kind == "house":
		return "sg_shophouse" if (district == "sg_shophouse" or (year > 0 and year < 1960 and narrow)) else "sg_house"
	if kind == "civic":
		return "sg_colonial" if (lv <= 5 and (year == 0 or year < 1965)) else "sg_tower"
	if kind == "industrial":
		return "sg_industrial"
	if lv >= 1 and lv <= 4:
		if narrow or (district == "" and kind == "commercial" and area < 1400.0):
			return "sg_shophouse"
		if area >= 1400.0:
			return "sg_mall" if kind == "commercial" else "sg_colonial"
		return "singapore"
	if lv >= 5:
		if kind == "commercial" and lv >= 8:
			return "sg_tower"
		return "singapore"
	return ""
