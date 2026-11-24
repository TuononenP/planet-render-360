class_name ArchitectureParis
extends RefCounted

## Paris era rows (BuildingEra picks one per building; all inherit from
## the "haussmann" city row in ArchitectureRegions, then france).
## Same key legend as ArchitectureData. `rv` is the 3D relief schema
## (docs/architecture-styles.md); a row's rv replaces its parent's.

## Zinc / slate mansard family (PRD §4.2, #46525E).
const ZINC := ["#46525e", "#4f5b66", "#56616b", "#4a5560"]
## Weathered standing-seam Parisian zinc (muted blue-grey, PRD §4.2 family).
const ZINC_METAL := ["#5a646e", "#66707a", "#525c66", "#6d7780"]
## Haussmann limestone (around PRD #D6C5A3). Post-Haussmann rows use the
## same palette, bay and pattern so both eras share facade materials
## (they differ in relief and storeys): the per-place budget (T7.2).
const STONE := ["#d6c5a3", "#dccbaa", "#cfbf9e"]
## Café awnings: oxblood, bottle green, mustard, navy, brick red.
const CAFE := ["#7a1f24", "#1f3b2c", "#c8a24a", "#2a2f4a", "#8a2a1a"]
## Parisian garden allées sablées (stabilised crushed Lutetian limestone sand) & blond stone paving.
const PARK_GRAVEL_HEX := "#C6B89A"
const PAVING_HEX := "#A69E90"
const SETT_HEX := "#938C80"

static func applies(data: LocationData) -> bool:
	return data != null and CityDetail.city_at(data.latitude, data.longitude) == "paris"

static func palette_overrides(data: LocationData) -> Dictionary:
	return {"path": Color.html(PARK_GRAVEL_HEX)} if applies(data) else {}

## Footways, pedestrian alleys and cycle paths inside Parisian parks & formal
## gardens (Jardins du Trocadéro, Champ de Mars, Tuileries, Luxembourg) are laid
## in pale cream-ochre stabilised limestone sand rather than dark road tarmac.
static func park_way(road: Dictionary, parks: Array) -> bool:
	if parks.is_empty() or bool(road.get("crossing", false)) or bool(road.get("bridge", false)) \
			or bool(road.get("area", false)) or bool(road.get("kerb_line", false)):
		return false
	if str(road.get("class", "")) not in ["footway", "path", "pedestrian", "cycleway"]:
		return false
	if str(road.get("surface", "")).to_lower() in ["sett", "paving_stones", "cobblestone", "unhewn_cobblestone"]:
		return false
	var pts: PackedVector2Array = road.get("points", PackedVector2Array())
	return not pts.is_empty() and GroundMaterial._grass_at(pts[pts.size() / 2], parks)

## Fills the un-surveyed sloped park bosquets of Jardins du Trocadéro flanking
## the Fontaine de Varsovie (`|fx| = 36.5..63 m, fz = -92..+68 m`) with real
## multi-card 3D Parisian park trees (Horse Chestnut, London Plane, Lime, Oak),
## bridging the gap between the stone monument (`±34.5 m`) and the Paris OpenData
## street/alley alignment register (`±65 m`). Strictly obeys `mask` & `_site_ok`.
static func plant_trocadero_bosquets(plan: Dictionary, data: LocationData,
		ground: GroundTruth, mask: VegetationMask, ctx: Dictionary) -> void:
	if str(ctx.get("city", "")) != "paris":
		return
	var entry := LocationData.entry_for_type("fontaine_de_varsovie")
	if entry.is_empty():
		return
	var m2u: float = ctx["m2u"]
	var f_at := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
		data.latitude, data.longitude)
	if f_at.length() > 950.0 * m2u:
		return
	var ax := LandmarkSites.axis(entry)
	var sd := Vector2(-ax.y, ax.x)
	var species := ["horse_chestnut", "plane", "lime", "oak"]
	var idx := 0
	var fz := -90.0
	while fz <= 66.0:
		var fx := 37.5
		while fx <= 61.5:
			for sx in [-1.0, 1.0]:
				idx += 1
				var jx := (sin(float(idx) * 12.9898) * 0.5) * 3.2
				var jz := (cos(float(idx) * 78.233) * 0.5) * 3.6
				var p := f_at + (ax * (float(sx) * (fx + jx)) + sd * (fz + jz)) * m2u
				if mask.cover_at(p.x, p.y) < 0:
					continue
				if not VegetationBuilder._site_ok(p.x, p.y, ground, mask,
						VegetationBuilder.SYNTHETIC_BITS, 1.1, ctx):
					continue
				var sp: String = species[idx % species.size()]
				var sc := 0.88 + fposmod(sin(float(idx) * 43.758) * 19.3, 0.28)
				VegetationBuilder._add(plan, p.x, p.y, ground, sp, sc, 1.05, false)
			fx += 7.8
		fz += 8.5

const BASE := {
	"paris_post_haussmann": "haussmann", "paris_faubourg": "haussmann",
	"paris_royal": "haussmann", "paris_marais": "haussmann",
	"paris_hbm": "haussmann", "paris_modern": "haussmann", "paris_pavillon": "haussmann",
}

const REGIONS := {
	# Belle Époque (1895–1914): taller (the 1902 code
	# allowed bow windows and higher rooflines), more balconies.
	"paris_post_haussmann": {
		"apartments": {"w": [["limestone", STONE]], "p": "haussmann",
			"bay": 2.4, "r": [["mansard", 1]], "pitch": 1.1,
			"rf": [["slate", ZINC], ["sheet_metal", ZINC_METAL]],
			"fh": 3.2, "st": [6, 8], "fix": true, "ch": 0.8, "dm": 1.0, "eq": 0.0, "g": [], "ev": 0.0,
			"rv": {"balcony_rows": [2, 5, 6], "balconette": 0.75, "oriel": 0.35,
				"string_course": true, "awning": 0.45, "awning_colours": CAFE}},
		"commercial": {"w": [["limestone", STONE]], "p": "haussmann", "bay": 2.4,
			"r": [["mansard", 1]], "rf": [["slate", ZINC], ["sheet_metal", ZINC_METAL]],
			"fh": 3.3, "st": [5, 7], "fix": true,
			"ch": 0.6, "dm": 1.0, "eq": 0.1, "g": [], "ev": 0.0,
			"rv": {"balcony_rows": [2, 5], "balconette": 0.7, "oriel": 0.3,
				"string_course": true, "awning": 0.6, "awning_colours": CAFE}},
	},
	# Pre-1850 faubourg / Marais houses: rendered walls, shutters, steep
	# tiled or slate roofs with dormers, narrow bays, low storeys.
	"paris_faubourg": {
		"apartments": {"w": [["render", ["#e8dcc4", "#e2d2b4", "#d9c7a4", "#ebe3d2", "#d8c0a0"]],
				["limestone", ["#e0d0b0", "#d8c8a8"]]],
			"p": "punched", "wn": "french", "bay": 2.0, "fr": "#f1ede4",
			"sh": ["#6b7a72", "#8a8f88", "#5b6b5f", "#7a6a58"], "sp": 0.7, "rl": 0.25,
			"r": [["gabled", 3], ["mansard", 2], ["hipped", 1]], "pitch": 1.25,
			"rf": [["slate", ZINC], ["terracotta", ["#9a4a2c", "#a8552f", "#8a4030"]]],
			"fh": 2.8, "st": [3, 5], "fix": true, "ch": 0.9, "dm": 0.7, "eq": 0.0,
			"g": [["shop", 3], ["none", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.15,
			"rv": {"balconette": 0.25, "string_course": true, "awning": 0.3,
				"awning_colours": CAFE}},
		"commercial": {"w": [["render", ["#e8dcc4", "#e2d2b4", "#d9c7a4"]]], "p": "punched",
			"wn": "french", "bay": 2.0, "sh": ["#6b7a72", "#5b6b5f"], "sp": 0.6, "rl": 0.2,
			"r": [["gabled", 2], ["mansard", 1]], "pitch": 1.2, "rf": [["slate", ZINC]],
			"fh": 2.9, "st": [3, 5], "fix": true, "ch": 0.8, "dm": 0.6,
			"g": [["shop", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.15,
			"rv": {"balconette": 0.2, "string_course": true, "awning": 0.55,
				"awning_colours": CAFE}},
		"house": {"w": [["render", ["#e8dcc4", "#e2d2b4", "#d9c7a4"]], ["stone", ["#c8b08a", "#bfa27a"]]],
			"p": "punched", "wn": "french", "bay": 2.2, "sh": ["#6b7a72", "#7a6a58"], "sp": 0.8,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 1.3,
			"rf": [["terracotta", ["#9a4a2c", "#a8552f"]], ["slate", ZINC]],
			"fh": 2.7, "st": [2, 3], "fix": true, "ch": 0.9, "dm": 0.6, "ev": 0.25,
			"rv": {"string_course": false, "quoins": true}},
	},
	# HBM ring (1919–1939, by the Périphérique): red / ochre brick, bow
	# windows, brick string courses, flat or low roofs.
	"paris_hbm": {
		"apartments": {"w": [["brick", ["#a8553a", "#b8683f", "#c27a4a", "#9a4a33", "#b8865a"]]],
			"p": [["punched", 3], ["ornate", 2]], "wn": "casement", "bay": 2.8, "fr": "#f1ede4",
			"sh": "#5b6b4f", "sp": 0.0, "rl": 0.1,
			"r": [["flat", 3], ["hipped", 1]], "pitch": 0.5,
			"rf": [["membrane", []], ["terracotta", ["#9a4a2c", "#8a4030"]]],
			"fh": 2.8, "st": [6, 8], "fix": true, "ch": 0.3, "dm": 0.1, "eq": 0.2,
			"g": [["none", 3], ["shop", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.2,
			"rv": {"deep_balcony": 0.15, "oriel": 0.25, "string_course": true,
				"awning": 0.1, "awning_colours": CAFE}},
	},
	# Post-war Paris (1950+): concrete / glass slabs and towers, ribbon or
	# panel windows, deep balconies, flat roofs (Front de Seine, 13e).
	"paris_modern": {
		"apartments": {"w": [["concrete", ["#c8c4bc", "#b8b4ac", "#d8d4cc"]],
				["render", ["#ecebe6", "#e0ddd6"]]],
			"p": [["balcony", 3], ["strip", 2], ["panel", 2]], "wn": "wide", "bay": 3.0,
			"fr": "#5a5e62", "sh": "#5a5e62", "sp": 0.0, "rl": 0.0,
			"r": [["flat", 1]], "pitch": 1.0, "rf": [["membrane", []]],
			"fh": 2.8, "st": [8, 16], "fix": true, "ch": 0.0, "dm": 0.0, "eq": 0.6,
			"g": [["none", 2], ["shop", 1]], "ev": 0.0,
			"rv": {"deep_balcony": 0.55, "awning": 0.15, "awning_colours": CAFE}},
		"commercial": {"w": [["glass", []], ["concrete", ["#c8c4bc", "#b8b4ac"]]],
			"p": [["strip", 2], ["curtain", 1]], "bay": 3.2, "fr": "#3a3d42",
			"r": [["flat", 1]], "rf": [["membrane", []]], "fh": 3.6, "st": [6, 20], "fix": true,
			"ch": 0.0, "dm": 0.0, "eq": 0.8, "g": [["shop", 1]], "ev": 0.0, "rv": {}},
		"civic": {"w": [["concrete", ["#c8c4bc", "#d8d4cc"]], ["glass", []]], "p": "strip",
			"bay": 3.4, "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 6], "fix": true,
			"ch": 0.0, "dm": 0.0, "g": [["none", 1]], "ev": 0.0, "rv": {}},
		"house": {"w": [["render", ["#ecebe6", "#e0ddd6"]], ["concrete", ["#c8c4bc"]]],
			"p": "strip", "r": [["flat", 2], ["skillion", 1]], "rf": [["membrane", []]],
			"st": [2, 3], "fix": true, "ch": 0.0, "dm": 0.0, "ev": 0.2, "rv": {}},
	},
	# Grand Siècle classical stone (Place Vendôme, Rue de Rivoli, Palais-Royal,
	# Île Saint-Louis, Concorde): ashlar limestone, steep blue-black Angers slate mansards.
	"paris_royal": {
		"apartments": {"w": [["limestone", ["#dfd4b8", "#d7caa8", "#e3d9c0"]]], "p": "haussmann",
			"bay": 2.5, "r": [["mansard", 1]], "pitch": 1.25,
			"rf": [["slate", ["#424b54", "#4a535c", "#3c454e"]]],
			"fh": 3.3, "st": [4, 6], "fix": true, "ch": 0.9, "dm": 1.0, "eq": 0.0, "g": [], "ev": 0.0,
			"rv": {"balcony_rows": [2], "balconette": 0.65, "string_course": true,
				"awning": 0.25, "awning_colours": CAFE}},
		"commercial": {"w": [["limestone", ["#dfd4b8", "#d7caa8"]]], "p": "haussmann",
			"bay": 2.6, "r": [["mansard", 1]], "pitch": 1.25,
			"rf": [["slate", ["#424b54", "#4a535c"]]],
			"fh": 3.4, "st": [4, 6], "fix": true, "ch": 0.8, "dm": 1.0, "eq": 0.0, "g": [], "ev": 0.0,
			"rv": {"balcony_rows": [2], "balconette": 0.6, "string_course": true,
				"awning": 0.35, "awning_colours": CAFE}},
	},
	# Le Marais & Place des Vosges hôtels particuliers: warm limestone, shuttered
	# render and Louis XIII brick-and-stone accents under steep slate/terracotta roofs.
	"paris_marais": {
		"apartments": {"w": [["limestone", ["#dfd2b5", "#d6c7a6"]], ["render", ["#e6d8be", "#ded0b4"]],
				["brick", ["#a44e3d", "#9a4636"]]],
			"p": "punched", "wn": "french", "bay": 2.1, "fr": "#f1ede4",
			"sh": ["#5c6d63", "#7a8078", "#6d6052"], "sp": 0.65, "rl": 0.25,
			"r": [["mansard", 3], ["gabled", 2]], "pitch": 1.25,
			"rf": [["slate", ["#424b54", "#4a535c"]], ["terracotta", ["#9a4a2c", "#a8552f"]]],
			"fh": 2.95, "st": [4, 5], "fix": true, "ch": 0.9, "dm": 0.8, "eq": 0.0,
			"g": [["shop", 3], ["none", 1]], "gc": ArchitectureData.FASCIA, "ev": 0.1,
			"rv": {"balconette": 0.4, "string_course": true, "quoins": true, "awning": 0.35,
				"awning_colours": CAFE}},
	},
	# Pavillons (outer arrondissements / petite couronne): millstone
	# (meulière) or render with brick quoins, tiled roofs.
	"paris_pavillon": {
		"house": {"w": [["stone", ["#c8b08a", "#bfa27a", "#d0bc98"]], ["render", ["#e8dcc4", "#efe6d4"]]],
			"p": "punched", "wn": "french", "bay": 2.6, "fr": "#f1ede4",
			"sh": ["#7a8a9a", "#5b6b4f", "#8a7a68"], "sp": 0.6,
			"r": [["gabled", 3], ["hipped", 3]], "pitch": 1.2,
			"rf": [["terracotta", ["#a8482a", "#b5542f", "#9a4a2c"]], ["slate", ArchitectureData.SLATE]],
			"fh": 2.9, "st": [2, 3], "fix": true, "ch": 0.8, "dm": 0.3, "ev": 0.4,
			"rv": {"balconette": 0.1, "quoins": true}},
	},
}
