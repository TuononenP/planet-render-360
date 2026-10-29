class_name ArchitectureData
extends RefCounted

## Reviewable data tables behind ArchitectureStyle (plan risk R5: regional
## defaults "with the table documented and reviewable"). Nothing here
## outranks real data: OSM `building:material` / `building:colour` /
## `roof:*` / `height` / `building:levels` and the satellite roof sample
## always win; these rows only fill what the map does not say.
## Documented for reviewers in docs/architecture-styles.md.
##
## Kind profile keys (all optional in a region override; GENERIC is complete):
##   w     wall finishes      [[wall set, [sRGB hex tints]], ...] (empty tints = photo colour)
##   p     window pattern     FacadeComposer.PATTERNS id
##   bay   metres per window bay (UV tiling, so windows keep real size)
##   fr    window frame hex    sh/sp  shutter hex / probability per bay
##   r     roof shapes        [[flat|gabled|hipped|mansard|pyramidal|dome, weight], ...]
##   pitch roof rise multiplier (1.0 = BuildingBuilder default rise)
##   rf    roof finishes      [[roof set, [sRGB hex tints]], ...]
##   fh    metres per storey  st  untagged storey range [min, max]
##   ch/dm/eq  chimney / dormer / rooftop-equipment probability
##   tw    religious tower: spire | bell | onion | minaret | pagoda | shikhara

## Ordered first-match boxes [region, south, west, north, east]. Coarse by
## design — borders are approximate, and neighbouring regions share most
## traits — but specific/small areas come before the large ones that
## contain them. tests/architecture_test.gd pins ~45 cities.
const BOXES := [
	["haussmann", 48.80, 2.22, 48.91, 2.47],           # Paris core
	["southeast_asia", 1.15, 103.55, 1.50, 104.15],    # Singapore
	["east_asia", 22.10, 113.80, 22.65, 114.50],       # Hong Kong
	["mediterranean", 35.70, 14.10, 36.20, 14.60],     # Malta
	["mediterranean", 34.50, 32.20, 35.80, 34.70],     # Cyprus
	["mediterranean", 27.50, -18.50, 29.50, -13.20],   # Canary Islands
	["middle_east", 30.00, 7.50, 37.50, 11.60],        # Tunisia
	["eastern_europe", 59.50, 28.60, 60.60, 31.00],    # St Petersburg
	["eastern_europe", 53.90, 20.90, 59.70, 28.30],    # Baltics
	["alpine", 45.80, 5.95, 47.85, 10.50],             # Switzerland
	["alpine", 46.40, 9.50, 47.70, 13.80],             # Tyrol / Salzburg / Bavarian Alps
	["alpine", 44.80, 5.90, 46.40, 7.70],              # French Alps
	["west_europe_brick", 49.80, -10.70, 60.90, 1.80], # Ireland + UK
	["west_europe_brick", 49.50, 2.50, 53.60, 7.25],   # Belgium + Netherlands
	["west_europe_brick", 54.50, 8.00, 57.80, 15.20],  # Denmark
	["nordic", 63.20, -24.60, 66.60, -13.40],          # Iceland
	["nordic", 59.70, 20.50, 70.20, 29.80],            # Finland
	["nordic", 55.30, 10.90, 69.10, 24.20],            # Sweden
	["nordic", 57.90, 4.50, 71.20, 31.20],             # Norway
	["mediterranean", 36.80, -9.60, 42.20, -6.10],     # Portugal
	["mediterranean", 36.00, -9.40, 43.90, -1.00],     # Spain west/south
	["mediterranean", 38.00, -1.00, 43.90, 4.40],      # Spain east + Balearics
	["mediterranean", 36.60, 6.60, 47.10, 18.60],      # Italy
	["france", 41.30, -5.20, 51.20, 9.70],             # France
	["central_europe", 47.20, 5.80, 55.10, 15.10],     # Germany
	["central_europe", 45.40, 9.50, 51.10, 22.90],     # Austria, Czechia, Slovakia, Hungary, Slovenia
	["central_europe", 49.00, 14.10, 54.90, 24.20],    # Poland
	["mediterranean", 41.80, 13.40, 45.40, 19.60],     # Dalmatian coast
	["mediterranean", 34.80, 19.30, 41.80, 26.30],     # Greece
	["mediterranean", 35.80, 26.90, 36.80, 28.40],     # Dodecanese
	["middle_east", 38.80, 40.00, 43.60, 50.40],       # Caucasus
	["eastern_europe", 41.20, 19.00, 52.50, 41.00],    # Balkans, Romania, Ukraine, Belarus
	["middle_east", 35.80, 26.00, 42.20, 44.80],       # Turkey
	["middle_east", 21.90, 24.70, 31.70, 36.90],       # Egypt
	["middle_east", 12.00, 34.20, 37.40, 60.00],       # Levant, Iraq, Arabia, Gulf
	["middle_east", 25.00, 44.00, 39.80, 63.50],       # Iran
	["middle_east", 19.00, -17.50, 37.60, 24.70],      # Morocco, Algeria, Libya
	["middle_east", 29.30, 60.50, 38.50, 70.00],       # Afghanistan
	["eastern_europe", 38.50, 46.50, 55.50, 87.40],    # Central Asia
	["eastern_europe", 50.50, 27.30, 81.90, 180.00],   # Russia
	["eastern_europe", 41.20, 27.30, 50.50, 60.00],    # European Russia south
	["sub_saharan_africa", -35.00, -18.00, 19.00, 52.00],
	["east_asia", 33.00, 124.50, 43.10, 129.70],       # Korea
	["japan", 24.00, 122.90, 45.70, 146.00],
	["east_asia", 21.80, 119.90, 25.40, 122.10],       # Taiwan
	["southeast_asia", 5.60, 97.30, 23.40, 109.60],    # Thailand, Laos, Cambodia, Vietnam
	["southeast_asia", -11.00, 95.00, 19.60, 141.00],  # Malay archipelago, Philippines
	["south_asia", 5.50, 66.50, 32.50, 97.50],         # India core before China's west edge
	["east_asia", 18.00, 73.50, 53.60, 135.00],        # China, Mongolia
	["south_asia", 5.50, 66.50, 36.00, 97.50],
	["australia", -44.00, 112.00, -10.00, 154.00],
	["australia", -47.50, 166.00, -34.00, 179.00],     # New Zealand
	["north_america", 18.80, -160.60, 22.40, -154.70], # Hawaii
	["north_america", 51.00, -170.00, 72.00, -129.00], # Alaska
	["north_america", 41.60, -141.00, 83.00, -52.00],  # Canada
	["north_america", 31.30, -125.00, 49.50, -97.00],  # US west
	["north_america", 25.00, -97.00, 49.50, -66.90],   # US east
	["latin_america", -56.00, -118.50, 32.80, -34.00],
]

## Regions that inherit unlisted kinds from another before GENERIC.
const BASE := {
	"alpine": "central_europe",
	"haussmann": "france",
	"france": "central_europe",
}

## OSM `building=*` values that name a kind outright. `yes`, `residential`
## and friends are decided by levels / footprint / density instead.
const KIND_TAGS := {
	"house": "house", "detached": "house", "semidetached_house": "house",
	"terrace": "house", "bungalow": "house", "cabin": "house",
	"apartments": "apartments", "dormitory": "apartments",
	"commercial": "commercial", "retail": "commercial", "office": "commercial",
	"hotel": "commercial", "supermarket": "commercial", "bank": "commercial",
	"industrial": "industrial", "warehouse": "industrial", "factory": "industrial",
	"manufacture": "industrial", "service": "industrial", "hangar": "industrial",
	"depot": "industrial", "storage_tank": "industrial",
	"church": "religious", "cathedral": "religious", "chapel": "religious",
	"mosque": "religious", "temple": "religious", "synagogue": "religious",
	"shrine": "religious", "monastery": "religious", "religious": "religious",
	"school": "civic", "university": "civic", "college": "civic",
	"kindergarten": "civic", "hospital": "civic", "civic": "civic",
	"public": "civic", "government": "civic", "fire_station": "civic",
	"train_station": "civic", "transportation": "civic", "stadium": "civic",
	"sports_hall": "civic", "museum": "civic", "library": "civic",
	"barn": "farm", "farm": "farm", "farm_auxiliary": "farm", "stable": "farm",
	"cowshed": "farm", "greenhouse": "farm", "silo": "farm", "sty": "farm",
	"shed": "outbuilding", "garage": "outbuilding", "garages": "outbuilding",
	"carport": "outbuilding", "roof": "outbuilding", "hut": "outbuilding",
	"kiosk": "outbuilding", "container": "outbuilding",
	"static_caravan": "outbuilding", "allotment_house": "outbuilding",
}

## `use` hints (amenity / shop / office / tourism ...) for `building=yes`.
const USE_TAGS := {
	"place_of_worship": "religious", "school": "civic", "kindergarten": "civic",
	"college": "civic", "university": "civic", "hospital": "civic",
	"clinic": "civic", "townhall": "civic", "library": "civic",
	"theatre": "civic", "fire_station": "civic", "police": "civic",
	"courthouse": "civic", "museum": "civic",
	"shop": "commercial", "office": "commercial", "hotel": "commercial",
	"restaurant": "commercial", "cafe": "commercial", "bank": "commercial",
	"marketplace": "commercial", "fuel": "commercial", "supermarket": "commercial",
	"industrial": "industrial", "works": "industrial",
}

## Untagged-building mix per region for procedural infill (weights per
## kind). Regions not listed use INFILL_DEFAULT.
const INFILL_DEFAULT := {
	"house": 52, "apartments": 20, "commercial": 8, "industrial": 5,
	"civic": 4, "farm": 3, "outbuilding": 8,
}
const INFILL_MIX := {
	"haussmann": {"apartments": 78, "commercial": 10, "civic": 6, "house": 2, "outbuilding": 4},
	"eastern_europe": {"apartments": 48, "house": 28, "commercial": 6, "industrial": 6, "civic": 4, "outbuilding": 8},
	"east_asia": {"apartments": 62, "commercial": 14, "house": 12, "civic": 4, "industrial": 4, "outbuilding": 4},
	"japan": {"house": 46, "apartments": 30, "commercial": 12, "industrial": 4, "outbuilding": 8},
	"alpine": {"house": 58, "farm": 12, "apartments": 12, "commercial": 6, "civic": 4, "outbuilding": 8},
	"north_america": {"house": 64, "commercial": 10, "apartments": 10, "industrial": 6, "outbuilding": 10},
	"australia": {"house": 68, "apartments": 10, "commercial": 6, "industrial": 6, "outbuilding": 10},
	"middle_east": {"house": 34, "apartments": 36, "commercial": 12, "outbuilding": 12, "civic": 6},
	"south_asia": {"house": 40, "apartments": 28, "commercial": 16, "outbuilding": 12, "civic": 4},
	"sub_saharan_africa": {"house": 62, "apartments": 10, "commercial": 10, "outbuilding": 14, "civic": 4},
}

const SLATE := ["#4f5760", "#5a626b", "#46505a"]
const TERRA := ["#b5542f", "#a8482a", "#c0643a", "#9a4a2c"]
const WARM_RENDER := ["#e9dfc4", "#f0e6d0", "#d9c9a0", "#e5d4c0", "#e8e4dc", "#d8b9a0"]
const BRICK := ["#9c4a35", "#8a3f30", "#b0634a", "#7b4a3a"]
const CONCRETE := ["#cfcac0", "#bdb8ac", "#d8d0c0", "#a8b0a8"]
## Shopfront fascia lacquers (sRGB): dark greens, oxblood, navy, umber.
const FASCIA := ["#2e3b34", "#4a1c22", "#283040", "#4a3a2a", "#1e2a24"]

## Complete fallback profile ("temperate mixed"). Every region row below
## overrides only what differs, per kind. T4.6 keys (optional, defaulted):
##   p   may also be weighted [[pattern, weight], ...] (per-building pick)
##   wn  window vocabulary: casement | french | sash | wide | small
##   rl  balconette (wrought-iron rail) share of punched windows
##   g   ground storey [[none|shop|signage|render|stone, weight], ...]
##   gc  shop fascia palette (sRGB)        ev  roof eave overhang, metres
const GENERIC := {
	"house": {"w": [["render", WARM_RENDER], ["brick", BRICK]], "p": "punched", "bay": 3.2,
		"fr": "#efece4", "sh": "#5b6b4f", "sp": 0.15,
		"r": [["gabled", 3], ["hipped", 2]], "pitch": 1.0,
		"rf": [["terracotta", TERRA], ["slate", SLATE]],
		"fh": 2.9, "st": [1, 2], "ch": 0.4, "dm": 0.1, "eq": 0.0, "ev": 0.45},
	"apartments": {"w": [["render", WARM_RENDER], ["concrete", CONCRETE]],
		"p": [["punched", 5], ["balcony", 2]], "bay": 3.2,
		"fr": "#efece4", "sh": "#5b6b4f", "sp": 0.1,
		"r": [["flat", 5], ["hipped", 2], ["gabled", 2]], "pitch": 0.8,
		"rf": [["membrane", []], ["slate", SLATE]],
		"fh": 3.0, "st": [4, 6], "ch": 0.2, "dm": 0.0, "eq": 0.3,
		"g": [["none", 3], ["shop", 1]], "gc": FASCIA, "ev": 0.3},
	"commercial": {"w": [["concrete", CONCRETE], ["render", WARM_RENDER], ["glass", []]],
		"p": [["strip", 2], ["punched", 2]], "bay": 3.4,
		"fr": "#3a3d42", "sh": "#3a3d42", "sp": 0.0,
		"r": [["flat", 1]], "pitch": 1.0, "rf": [["membrane", []]],
		"fh": 3.6, "st": [2, 5], "ch": 0.0, "dm": 0.0, "eq": 0.6,
		"g": [["shop", 1]], "gc": FASCIA},
	"industrial": {"w": [["concrete", CONCRETE]], "p": "industrial", "bay": 4.0,
		"fr": "#3a3d42", "sh": "#3a3d42", "sp": 0.0,
		"r": [["gabled", 3], ["flat", 2]], "pitch": 0.35,
		"rf": [["slate", ["#8d8a86", "#6a7580", "#7a7e80"]], ["membrane", []]],
		"fh": 5.0, "st": [1, 2], "ch": 0.0, "dm": 0.0, "eq": 0.5, "ev": 0.2},
	"religious": {"w": [["stone", []], ["render", WARM_RENDER]], "p": "punched", "bay": 4.4,
		"fr": "#2f2a26", "sh": "#2f2a26", "sp": 0.0, "wn": "french",
		"r": [["gabled", 1]], "pitch": 1.1,
		"rf": [["slate", SLATE]], "fh": 4.6, "st": [2, 3], "ch": 0.0, "dm": 0.0,
		"eq": 0.0, "tw": "spire", "ev": 0.2},
	"civic": {"w": [["render", WARM_RENDER], ["brick", BRICK], ["concrete", CONCRETE]], "p": "punched", "bay": 3.6,
		"fr": "#efece4", "sh": "#5b6b4f", "sp": 0.0,
		"r": [["hipped", 3], ["flat", 3]], "pitch": 0.7,
		"rf": [["slate", SLATE], ["membrane", []]],
		"fh": 3.8, "st": [2, 4], "ch": 0.1, "dm": 0.0, "eq": 0.4,
		"g": [["none", 2], ["stone", 1]], "ev": 0.3},
	"farm": {"w": [["wood", ["#8a6a48", "#7a5a3a", "#9a7a56"]], ["render", WARM_RENDER]], "p": "clapboard", "bay": 3.0,
		"fr": "#efece4", "sh": "#5b6b4f", "sp": 0.0,
		"r": [["gabled", 1]], "pitch": 0.8,
		"rf": [["slate", ["#7c4a38", "#6a7580", "#8d8a86"]], ["terracotta", TERRA]],
		"fh": 3.6, "st": [1, 2], "ch": 0.1, "dm": 0.0, "eq": 0.0, "ev": 0.6},
	"outbuilding": {"w": [["render", WARM_RENDER], ["concrete", CONCRETE], ["wood", []]], "p": "punched", "bay": 2.8,
		"fr": "#efece4", "sh": "#5b6b4f", "sp": 0.0, "wn": "small",
		"r": [["gabled", 2], ["flat", 2]], "pitch": 0.6,
		"rf": [["slate", SLATE], ["membrane", []]],
		"fh": 2.8, "st": [1, 1], "ch": 0.0, "dm": 0.0, "eq": 0.0, "ev": 0.3},
}

## Per-region, per-kind overrides (merged over BASE chain, then GENERIC).
const REGIONS := {
	"haussmann": {
		# PRD §4.2: limestone, 1.8–2.4 m window pitch, zinc/slate mansards
		# (#46525E family); the ground floor is drawn in the full facade.
		"apartments": {"w": [["limestone", []]], "p": "haussmann", "bay": 2.4,
			"r": [["mansard", 1]], "pitch": 1.0,
			"rf": [["slate", ["#46525e", "#4f5b66", "#56616b", "#4a5560"]]],
			"fh": 3.1, "st": [5, 7], "ch": 0.8, "dm": 1.0, "eq": 0.0, "g": [], "ev": 0.0},
		"commercial": {"w": [["limestone", []]], "p": "haussmann", "bay": 2.4, "r": [["mansard", 1]],
			"rf": [["slate", ["#46525e", "#4f5b66"]]], "fh": 3.1, "st": [4, 6], "ch": 0.6, "dm": 1.0,
			"eq": 0.1, "g": [], "ev": 0.0},
		"civic": {"w": [["limestone", []]], "p": "haussmann", "bay": 2.6, "r": [["mansard", 2], ["hipped", 1]],
			"rf": [["slate", ["#46525e", "#56616b"]]], "fh": 3.6, "st": [3, 5], "ch": 0.4, "dm": 0.6,
			"eq": 0.1, "g": [], "ev": 0.0},
		"house": {"w": [["limestone", []], ["render", WARM_RENDER]], "sp": 0.5, "wn": "french",
			"r": [["gabled", 1], ["hipped", 1]], "rf": [["slate", ["#4f5b66", "#56616b"]]], "st": [2, 3]},
	},
	"france": {
		"house": {"w": [["limestone", ["#e8dcc0", "#e0d0b0", "#d8c8a0"]], ["render", ["#e8e0d0", "#e9dfc4", "#d9c9a0"]]],
			"fr": "#f1ede4", "sh": "#7a8a9a", "sp": 0.7, "wn": "french",
			"r": [["hipped", 3], ["gabled", 2]], "pitch": 1.15,
			"rf": [["terracotta", TERRA], ["slate", SLATE]], "st": [1, 3], "ch": 0.7, "dm": 0.4},
		"apartments": {"w": [["limestone", []], ["render", WARM_RENDER]], "sh": "#5b6b4f", "sp": 0.5,
			"p": [["punched", 4], ["balcony", 1]], "wn": "french", "rl": 0.6,
			"r": [["mansard", 2], ["hipped", 2], ["flat", 2]], "pitch": 1.0,
			"rf": [["slate", SLATE]], "st": [3, 6], "ch": 0.5, "dm": 0.5,
			"g": [["none", 2], ["shop", 2]]},
		"civic": {"w": [["limestone", []]], "wn": "french", "r": [["hipped", 2], ["mansard", 1]], "rf": [["slate", SLATE]]},
	},
	"central_europe": {
		"house": {"w": [["render", ["#e9dfc4", "#f0e6d0", "#d9c9a0", "#e5d4c0", "#cfd8c8", "#e0cfa8", "#d8b9a0"]]],
			"sh": "#5b6b4f", "sp": 0.4,
			"r": [["hipped", 3], ["gabled", 3]], "pitch": 1.3,
			"rf": [["terracotta", ["#b5542f", "#9a4a2c", "#8a3f30"]], ["slate", SLATE]],
			"st": [2, 3], "ch": 0.6, "dm": 0.4, "ev": 0.5},
		"apartments": {"w": [["render", ["#e9dfc4", "#f0e6d0", "#d9c9a0", "#e5d4c0", "#d8c8a8", "#cfd8c8"]], ["concrete", CONCRETE]],
			"sp": 0.2, "p": [["punched", 6], ["balcony", 1]],
			"r": [["hipped", 3], ["gabled", 2], ["flat", 2]], "pitch": 1.1,
			"rf": [["terracotta", TERRA], ["slate", SLATE]], "st": [4, 6], "ch": 0.5, "dm": 0.3,
			"g": [["none", 2], ["shop", 1]]},
		"religious": {"w": [["stone", []], ["render", ["#e8e0cc"]]], "pitch": 1.4, "tw": "spire"},
		"farm": {"w": [["wood", ["#7a5a3a", "#8a6a48"]], ["render", WARM_RENDER]], "r": [["gabled", 1]], "pitch": 1.1,
			"rf": [["terracotta", TERRA]]},
	},
	"alpine": {
		# Chalet: white rendered ground storey, timber upper storeys with
		# shuttered small windows and balcony rails, wide low-pitch eaves.
		"house": {"w": [["wood", ["#7a5234", "#8a6040", "#6b4a2f", "#94704a"]]],
			"p": "clapboard", "bay": 2.6, "fr": "#efe6d2", "sh": "#3f5f3a", "sp": 0.6,
			"wn": "small", "rl": 0.5, "g": [["render", 1]],
			"r": [["gabled", 1]], "pitch": 0.55,
			"rf": [["wood", ["#6e5a45", "#5e4e3e", "#7a6650"]], ["slate", ["#6a6e70", "#7a7e80"]],
				["terracotta", ["#9a4a2c", "#8a3f30"]]],
			"st": [2, 3], "ch": 0.5, "dm": 0.15, "ev": 1.3},
		"apartments": {"w": [["render", ["#f2ead8", "#efe3c8", "#e8dcc0", "#f4efe4", "#e6dccb"]]],
			"p": [["punched", 4], ["balcony", 2]], "sh": "#3f5f3a", "sp": 0.5, "rl": 0.3,
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.7,
			"rf": [["terracotta", ["#9a4a2c", "#8a3f30", "#a8552f"]], ["slate", ["#5d6268", "#6a6e70"]]],
			"st": [3, 5], "ch": 0.4, "dm": 0.3, "g": [["none", 2], ["shop", 1]], "ev": 0.9},
		# Belle Époque hotels: cream render, tall French windows with
		# balconettes, hipped/mansard slate roofs.
		"commercial": {"w": [["render", ["#f4ead2", "#efe0c0", "#f2e6d6", "#e8d8b8"]]],
			"p": "punched", "bay": 2.8, "fr": "#f4f0e6", "wn": "french", "rl": 0.8,
			"sh": "#5b6b4f", "sp": 0.3,
			"r": [["hipped", 3], ["mansard", 2]], "pitch": 1.0,
			"rf": [["slate", ["#55606a", "#4f5a5e", "#5a6670"]], ["terracotta", ["#9a4a2c"]]],
			"fh": 3.4, "st": [4, 6], "ch": 0.5, "dm": 0.6, "eq": 0.1,
			"g": [["shop", 2], ["stone", 1]], "ev": 0.6},
		"farm": {"w": [["wood", ["#5a3f2a", "#6b4a2f"]]], "r": [["gabled", 1]], "pitch": 0.5,
			"rf": [["wood", ["#6e5a45", "#5a4a3a"]], ["slate", ["#7a7e80"]]], "st": [1, 2], "ev": 1.2},
		"religious": {"w": [["render", ["#f2ece0"]], ["stone", []]], "pitch": 1.2, "tw": "onion"},
	},
	"west_europe_brick": {
		"house": {"w": [["brick", ["#9c4a35", "#8a3f30", "#b0634a", "#7b4a3a", "#b59d6e"]]],
			"fr": "#f1ede4", "sp": 0.0, "wn": "sash",
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 1.0,
			"rf": [["slate", SLATE], ["terracotta", ["#a8482a", "#9a4a2c"]]],
			"fh": 2.8, "st": [2, 2], "ch": 0.9, "dm": 0.15, "ev": 0.25},
		"apartments": {"w": [["brick", ["#9c4a35", "#8a3f30", "#7b4a3a", "#b59d6e"]], ["concrete", CONCRETE]],
			"fr": "#f1ede4", "sp": 0.0, "wn": "sash", "p": [["punched", 5], ["balcony", 1]],
			"r": [["flat", 3], ["gabled", 3]], "pitch": 0.7,
			"rf": [["slate", SLATE], ["membrane", []]], "st": [3, 6], "ch": 0.4,
			"g": [["none", 2], ["shop", 1]], "gc": ["#1f2a3a", "#3a1c20", "#20302a", "#2a2a2a"]},
		"commercial": {"w": [["brick", BRICK], ["concrete", CONCRETE], ["glass", []]],
			"p": [["strip", 1], ["punched", 2]], "wn": "sash"},
		"civic": {"w": [["brick", ["#9c4a35", "#8a3f30"]], ["stone", []]], "sp": 0.0, "wn": "sash",
			"r": [["hipped", 2], ["gabled", 2]], "rf": [["slate", SLATE]], "ch": 0.5},
		"religious": {"w": [["brick", ["#8a3f30", "#7b4a3a"]], ["stone", []]], "pitch": 1.2, "tw": "spire"},
	},
	"nordic": {
		# Painted timber: falu red, ochre, cream, pale green; white frames.
		"house": {"w": [["wood", ["#8c2f22", "#9a3a28", "#e0c070", "#e8e4da", "#c9a24a", "#9aae8a", "#e8d8a8"]]],
			"p": "clapboard", "bay": 2.9, "fr": "#f4f1ea", "sp": 0.0, "wn": "casement",
			"r": [["gabled", 4], ["hipped", 1]], "pitch": 0.7,
			"rf": [["slate", ["#4b5560", "#7a2f2a", "#5d6670", "#556068"]], ["terracotta", ["#9a4a2c"]]],
			"fh": 2.8, "st": [1, 2], "ch": 0.7, "dm": 0.05, "ev": 0.5},
		# Rendered/painted plaster blocks (ochre, yellow, pale green,
		# red-brown, cream) and brick; punched windows, not ribbons.
		"apartments": {"w": [["render", ["#d9b765", "#e3c98a", "#c9d4b4", "#b8664a", "#e8dcc0", "#c4ccc8", "#d8a878", "#efe2b0"]],
				["brick", ["#8a4a3c", "#7a4434", "#9a5a48"]]],
			"p": [["punched", 6], ["balcony", 2], ["strip", 1]], "bay": 2.8, "fr": "#f4f1ea", "sp": 0.0,
			"r": [["flat", 4], ["gabled", 2], ["hipped", 2]], "pitch": 0.4,
			"rf": [["membrane", []], ["slate", ["#4b5560", "#5d6670", "#7a2f2a"]]],
			"st": [3, 6], "ch": 0.15, "eq": 0.4, "g": [["none", 3], ["shop", 1]],
			"gc": ["#2b3440", "#3a2a28", "#1f3a2c", "#4a4a48"]},
		"commercial": {"w": [["concrete", CONCRETE], ["brick", ["#8a3f30", "#9c4a35"]],
				["render", ["#d9b765", "#e3c98a", "#e8dcc0"]], ["glass", []]],
			"p": [["strip", 2], ["punched", 3]]},
		"civic": {"w": [["render", ["#e8dcc0", "#d9c9a0", "#d9b765"]], ["brick", ["#8a3f30", "#9c4a35"]]],
			"p": [["punched", 3], ["strip", 1]], "r": [["hipped", 2], ["flat", 2]], "pitch": 0.5},
		"religious": {"w": [["brick", ["#8a3f30", "#9c4a35"]], ["render", ["#e8e0cc"]]], "pitch": 1.0, "tw": "bell"},
		"farm": {"w": [["wood", ["#8c2f22", "#8a3a2a", "#e8e4da"]]], "p": "clapboard", "r": [["gabled", 1]],
			"pitch": 0.6, "rf": [["slate", ["#4b5560", "#7a2f2a"]]]},
	},
	"mediterranean": {
		"house": {"w": [["render", ["#efe3c8", "#e6c9a0", "#d9a878", "#f2ede0", "#d8b890", "#c9a070"]]],
			"fr": "#efe6d2", "sh": "#4f6a4a", "sp": 0.7, "rl": 0.3,
			"r": [["gabled", 3], ["hipped", 3]], "pitch": 0.6,
			"rf": [["terracotta", ["#b5542f", "#c0643a", "#a8482a"]]],
			"fh": 2.9, "st": [1, 3], "ch": 0.15, "eq": 0.25, "ev": 0.3},
		"apartments": {"w": [["render", ["#efe3c8", "#e6c9a0", "#d9a878", "#f2ede0", "#d8b890", "#e8c8a8"]]],
			"fr": "#efe6d2", "sp": 0.6, "sh": "#4f6a4a", "wn": "french", "rl": 0.6,
			"p": [["punched", 3], ["balcony", 3]],
			"r": [["flat", 4], ["hipped", 3]], "pitch": 0.5,
			"rf": [["terracotta", TERRA], ["membrane", []]], "st": [3, 6], "ch": 0.0, "eq": 0.6,
			"g": [["none", 1], ["shop", 1]], "gc": ["#2e3b34", "#5a2a1a", "#283040", "#6a4a2a"]},
		"commercial": {"w": [["render", ["#efe3c8", "#f2ede0"]], ["concrete", CONCRETE]], "p": [["strip", 1], ["punched", 2]]},
		"religious": {"w": [["render", ["#f2ece0", "#e6d9b8"]], ["stone", []]], "r": [["gabled", 1]],
			"rf": [["terracotta", TERRA]], "pitch": 0.7, "tw": "bell"},
		"civic": {"w": [["render", ["#e6d9b8", "#efe3c8"]]], "sp": 0.5, "r": [["hipped", 2], ["flat", 1]],
			"rf": [["terracotta", TERRA]]},
	},
	"middle_east": {
		"house": {"w": [["render", ["#d8c6a0", "#cdb88e", "#e0d2b0", "#c9b090"]], ["stone", []]],
			"p": "adobe", "bay": 3.6, "fr": "#5a4a3a", "sp": 0.0, "wn": "small",
			"r": [["flat", 1]], "pitch": 1.0, "rf": [["concrete", ["#c8b898", "#b8aa90"]]],
			"fh": 3.2, "st": [1, 3], "ch": 0.0, "eq": 0.85, "ev": 0.0},
		"apartments": {"w": [["render", ["#d8c6a0", "#cdb88e", "#e0d2b0", "#e8dcc4"]], ["concrete", CONCRETE]],
			"p": [["adobe", 3], ["balcony", 2]], "bay": 3.6, "fr": "#5a4a3a", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["concrete", ["#c8b898", "#b8aa90"]]], "st": [3, 8], "ch": 0.0, "eq": 0.9,
			"g": [["none", 2], ["shop", 1]], "gc": ["#3a3020", "#20302a", "#5a4a3a", "#2a3a4a"], "ev": 0.0},
		"commercial": {"w": [["concrete", CONCRETE], ["glass", []]], "p": "strip", "r": [["flat", 1]],
			"rf": [["concrete", []]]},
		"religious": {"w": [["render", ["#f2ece0", "#e6d9b8"]], ["stone", []]], "p": "adobe",
			"r": [["flat", 1]], "rf": [["concrete", []]], "tw": "minaret"},
		"civic": {"w": [["render", ["#e0d2b0", "#d8c6a0"]]], "p": "adobe", "r": [["flat", 1]],
			"rf": [["concrete", []]]},
		"farm": {"w": [["render", ["#d8c6a0", "#cdb88e"]]], "p": "adobe", "r": [["flat", 1]],
			"rf": [["concrete", []]]},
	},
	"japan": {
		# Mixed mid-rise: pale tiled/concrete fronts, aluminium sliders,
		# balcony slabs, signage-band ground floors, rooftop plant.
		"house": {"w": [["render", ["#e8e4dc", "#d8d0c0", "#c8c0b0", "#e0dcd4"]], ["wood", ["#6b5a48", "#8a7a64"]]],
			"p": "punched", "bay": 2.4, "fr": "#8a8c8e", "sp": 0.0, "wn": "wide",
			"r": [["gabled", 3], ["hipped", 3]], "pitch": 0.6,
			"rf": [["slate", ["#5a6068", "#6a7078", "#4d555c"]]],
			"fh": 2.8, "st": [1, 2], "ch": 0.0, "eq": 0.3, "ev": 0.6},
		"apartments": {"w": [["render", ["#e4e2dc", "#d8d6d0", "#ecebe6", "#cfccc4", "#efece4", "#e6e0d2", "#d8d0c4"]],
				["concrete", ["#d8d6d0", "#cfccc4"]]],
			"p": [["balcony", 4], ["tiles", 3], ["punched", 2]], "bay": 3.0, "fr": "#9a9c9e", "sp": 0.0,
			"wn": "wide", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [4, 10], "ch": 0.0, "eq": 0.85,
			"g": [["none", 2], ["signage", 1]]},
		"commercial": {"w": [["render", ["#e8e4dc", "#d0ccc4", "#bfb8ac", "#e6dccc", "#d8d6d0"]], ["glass", []]],
			"p": [["tiles", 3], ["strip", 2], ["punched", 2]], "bay": 3.0, "fr": "#8a8c8e", "wn": "wide",
			"st": [3, 10], "eq": 0.9, "g": [["signage", 1]]},
		"religious": {"w": [["wood", ["#6b5a48", "#5a4a3a"]], ["stone", []]], "p": "punched",
			"r": [["hipped", 1]], "pitch": 0.6, "rf": [["slate", ["#4d555c", "#5a6068"]]], "tw": "pagoda", "ev": 1.0},
		"civic": {"w": [["concrete", ["#d8d6d0", "#c8c4bc"]]], "p": [["strip", 1], ["tiles", 1]], "r": [["flat", 1]],
			"rf": [["membrane", []]]},
	},
	"east_asia": {
		"house": {"w": [["concrete", ["#d8d0c0", "#c8c0b0"]], ["brick", ["#9c4a35", "#b0634a"]]],
			"p": "punched", "bay": 3.0, "fr": "#6a6e72", "sp": 0.0, "wn": "wide",
			"r": [["hipped", 2], ["gabled", 2], ["flat", 2]], "pitch": 0.6,
			"rf": [["slate", ["#6a6e72", "#5a626b"]], ["terracotta", ["#9a4a2c", "#7c4a38"]]],
			"st": [1, 3], "ch": 0.0, "eq": 0.4, "ev": 0.6},
		"apartments": {"w": [["concrete", ["#e0d8c8", "#d8d0c0", "#c8c0b0", "#e8e0d0", "#b8c0c8"]]],
			"p": [["balcony", 4], ["tiles", 2]], "bay": 3.2, "fr": "#6a6e72", "sp": 0.0, "wn": "wide",
			"r": [["flat", 5], ["hipped", 1]], "rf": [["membrane", []]],
			"fh": 3.0, "st": [8, 26], "ch": 0.0, "eq": 0.9, "g": [["none", 2], ["signage", 1]]},
		"commercial": {"w": [["glass", []], ["concrete", ["#d8d0c0"]]], "p": "curtain", "bay": 3.4,
			"fh": 3.8, "st": [5, 24], "eq": 0.9, "g": [["signage", 1]]},
		"religious": {"w": [["wood", ["#8a3f30", "#6b4a2f"]], ["stone", []]], "r": [["hipped", 1]],
			"pitch": 0.9, "rf": [["terracotta", ["#4d555c", "#9a4a2c"]]], "tw": "pagoda", "ev": 1.0},
		"civic": {"w": [["concrete", ["#d8d0c0", "#e0d8c8"]]], "p": "strip", "r": [["flat", 1]],
			"rf": [["membrane", []]], "st": [3, 8]},
	},
	"south_asia": {
		"house": {"w": [["render", ["#e0a878", "#d88a70", "#e8d098", "#a8c0b0", "#d0c0e0", "#c8d8a8"]]],
			"p": "adobe", "bay": 3.2, "fr": "#3a3d42", "sp": 0.0,
			"r": [["flat", 1]], "pitch": 1.0, "rf": [["concrete", []]],
			"fh": 3.0, "st": [1, 3], "ch": 0.0, "eq": 0.9, "ev": 0.0},
		"apartments": {"w": [["render", ["#e0a878", "#d88a70", "#e8d098", "#c8d8a8", "#e8dcc4"]], ["concrete", CONCRETE]],
			"p": "balcony", "bay": 3.2, "fr": "#3a3d42", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["concrete", []]], "st": [4, 9], "ch": 0.0, "eq": 0.9,
			"g": [["none", 1], ["shop", 1]], "gc": ["#8a2a1a", "#1a4a6a", "#2a5a2a", "#c8901a"]},
		"commercial": {"w": [["render", ["#e0a878", "#e8d098"]], ["concrete", CONCRETE]], "p": "strip",
			"r": [["flat", 1]], "rf": [["concrete", []]], "gc": ["#8a2a1a", "#1a4a6a", "#2a5a2a", "#c8901a"]},
		"religious": {"w": [["stone", []], ["render", ["#e8d098", "#e0a878"]]], "r": [["flat", 1]],
			"rf": [["concrete", []]], "tw": "shikhara"},
	},
	"southeast_asia": {
		"house": {"w": [["render", ["#e8d8b0", "#c8d8c0", "#e0c0a0", "#b8c8d8"]], ["wood", ["#8a6a48", "#7a5a3a"]]],
			"p": "punched", "bay": 2.8, "fr": "#efece4", "sp": 0.2, "sh": "#5b6b4f",
			"r": [["gabled", 4], ["hipped", 2]], "pitch": 0.8,
			"rf": [["terracotta", ["#b5542f", "#9a4a2c"]], ["slate", ["#7c4a38", "#6a7580", "#8d8a86"]]],
			"fh": 2.9, "st": [1, 3], "ch": 0.0, "eq": 0.35, "ev": 0.9},
		"apartments": {"w": [["render", ["#e8d8b0", "#c8d8c0", "#e0c0a0", "#b8c8d8", "#e8e0d0"]]],
			"p": "balcony", "bay": 3.0, "fr": "#3a3d42", "sp": 0.0,
			"r": [["flat", 4], ["gabled", 2]], "pitch": 0.6, "rf": [["membrane", []], ["terracotta", TERRA]],
			"st": [3, 8], "eq": 0.7, "g": [["none", 1], ["shop", 1]]},
		# Shophouses: pastel render, tall shuttered windows, shop below.
		"commercial": {"w": [["render", ["#e8d8b0", "#e8e0d0", "#c8d8c0", "#e8c0b0"]], ["glass", []]],
			"p": [["punched", 3], ["strip", 1]], "wn": "french", "sh": "#4f6a5a", "sp": 0.6, "eq": 0.8},
		"religious": {"w": [["render", ["#f2ece0", "#e6d9b8"]], ["wood", ["#8a3f30"]]], "r": [["hipped", 1]],
			"pitch": 1.1, "rf": [["terracotta", ["#b5542f", "#c0643a"]]], "tw": "pagoda", "ev": 1.0},
	},
	"north_america": {
		"house": {"w": [["wood", ["#e8e4da", "#c9b898", "#a8b4b8", "#d8c8a0", "#8a9aa0", "#b89878", "#a84a3a"]]],
			"p": "clapboard", "bay": 3.2, "fr": "#f4f1ea", "sh": "#3f4f5f", "sp": 0.3, "wn": "sash",
			"r": [["gabled", 4], ["hipped", 3]], "pitch": 0.75,
			"rf": [["slate", ["#5a5652", "#625c56", "#4f4c4a", "#6b5d52"]]],
			"fh": 2.9, "st": [1, 2], "ch": 0.5, "dm": 0.1, "ev": 0.4},
		"apartments": {"w": [["brick", ["#9c4a35", "#8a3f30", "#a05a3a"]], ["concrete", CONCRETE]],
			"fr": "#f1ede4", "sp": 0.0, "wn": "sash", "p": "punched",
			"r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 9], "ch": 0.1, "eq": 0.7,
			"g": [["none", 1], ["shop", 1]]},
		"commercial": {"w": [["glass", []], ["brick", ["#9c4a35", "#8a3f30"]], ["concrete", CONCRETE]],
			"p": [["strip", 2], ["punched", 1]], "r": [["flat", 1]], "fh": 3.8, "st": [2, 20], "eq": 0.85},
		"industrial": {"w": [["concrete", CONCRETE], ["render", ["#cfcac0", "#bdb8ac"]]]},
		"religious": {"w": [["wood", ["#f4f1ea", "#e8e4da"]], ["brick", ["#9c4a35"]]], "p": "clapboard",
			"r": [["gabled", 1]], "pitch": 1.2,
			"rf": [["slate", ["#5a5652", "#625c56"]]], "tw": "spire"},
		"civic": {"w": [["brick", ["#9c4a35", "#8a3f30"]], ["stone", []]], "sp": 0.0, "wn": "sash",
			"r": [["hipped", 2], ["flat", 3]], "rf": [["slate", ["#5a5652"]], ["membrane", []]]},
	},
	"latin_america": {
		"house": {"w": [["render", ["#e8c070", "#e08a68", "#a8c8b0", "#d8e0f0", "#e8a8a0", "#f0e0b0", "#b0c8e0"]]],
			"fr": "#3a3d42", "sh": "#3f5f6f", "sp": 0.25, "rl": 0.4, "wn": "french",
			"r": [["flat", 4], ["gabled", 2], ["hipped", 2]], "pitch": 0.55,
			"rf": [["terracotta", TERRA], ["concrete", []]],
			"fh": 2.9, "st": [1, 3], "ch": 0.0, "eq": 0.5, "ev": 0.4},
		"apartments": {"w": [["render", ["#e8c070", "#e08a68", "#a8c8b0", "#e8a8a0", "#f0e0b0"]], ["concrete", CONCRETE]],
			"p": [["balcony", 3], ["punched", 1]], "bay": 3.2, "fr": "#3a3d42", "sp": 0.0,
			"r": [["flat", 1]], "rf": [["concrete", []]], "st": [4, 12], "ch": 0.0, "eq": 0.7,
			"g": [["none", 1], ["shop", 1]]},
		"commercial": {"w": [["render", ["#e8c070", "#f0e0b0"]], ["concrete", CONCRETE], ["glass", []]], "p": "strip"},
		"religious": {"w": [["render", ["#f2ece0", "#e8c070"]], ["stone", []]], "r": [["gabled", 1]],
			"pitch": 0.7, "rf": [["terracotta", TERRA]], "tw": "bell"},
	},
	"australia": {
		"house": {"w": [["brick", ["#a05a3a", "#8a4a35", "#b0805a", "#c0a080"]],
				["wood", ["#e8e4da", "#a8b4b8", "#d8c8a0"]]],
			"p": "punched", "fr": "#f4f1ea", "sp": 0.0,
			"r": [["hipped", 4], ["gabled", 3]], "pitch": 0.5,
			"rf": [["slate", ["#6e7a73", "#5b6e5f", "#8a4a3a", "#c8c2b4", "#5a626b"]], ["terracotta", ["#b5542f", "#9a4a2c"]]],
			"fh": 2.7, "st": [1, 2], "ch": 0.3, "eq": 0.3, "ev": 0.6},
		"apartments": {"w": [["brick", ["#a05a3a", "#8a4a35", "#b0805a"]], ["render", WARM_RENDER]],
			"p": "balcony", "r": [["flat", 1]], "rf": [["membrane", []]], "st": [3, 8], "eq": 0.6},
		"commercial": {"w": [["glass", []], ["concrete", CONCRETE], ["brick", ["#a05a3a"]]], "p": "strip", "st": [2, 12]},
		"industrial": {"rf": [["slate", ["#8d8a86", "#c8c2b4", "#5b6e5f"]]]},
		"religious": {"w": [["brick", ["#a05a3a", "#8a4a35"]], ["stone", []]], "pitch": 1.1, "tw": "bell"},
	},
	"eastern_europe": {
		"apartments": {"w": [["concrete", ["#cfcac0", "#bdb8ac", "#d8d0c0", "#a8b0a8", "#e0c8a0"]]],
			"p": [["balcony", 3], ["punched", 1]], "bay": 3.0, "fr": "#6a6e72", "sp": 0.0,
			"r": [["flat", 4], ["gabled", 2]], "pitch": 0.4,
			"rf": [["membrane", []], ["slate", ["#6b6e72", "#7c4a38"]]],
			"fh": 2.8, "st": [5, 9], "ch": 0.0, "eq": 0.5},
		"house": {"w": [["render", ["#e0d0b0", "#c8a888", "#a8c0a0", "#d8c8a0"]], ["brick", BRICK]],
			"fr": "#efece4", "sh": "#5b4a3a", "sp": 0.25,
			"r": [["gabled", 4], ["hipped", 2]], "pitch": 0.8,
			"rf": [["slate", ["#6b6e72", "#7c4a38", "#6a7580"]]],
			"st": [1, 2], "ch": 0.7},
		"commercial": {"w": [["concrete", CONCRETE], ["glass", []]], "p": "strip", "r": [["flat", 1]]},
		"civic": {"w": [["render", ["#e8d890", "#e8e4dc", "#d8c07a"]]], "sp": 0.0, "r": [["hipped", 1]],
			"rf": [["slate", ["#6b6e72", "#5a626b"]]], "pitch": 0.6},
		"religious": {"w": [["render", ["#f2ece0", "#e8e4dc"]]], "r": [["hipped", 1]],
			"rf": [["slate", ["#5a626b", "#4f5760"]]], "pitch": 0.9, "tw": "onion"},
	},
	"sub_saharan_africa": {
		"house": {"w": [["render", ["#d8c8a8", "#c8b898", "#e0d0b8", "#c0a888", "#a8c0b8", "#e0b898"]],
				["concrete", CONCRETE]],
			"p": "adobe", "bay": 3.2, "fr": "#4a3a2a", "sp": 0.0,
			"r": [["gabled", 4], ["flat", 2]], "pitch": 0.35,
			"rf": [["slate", ["#8d8a86", "#7c4a38", "#6a7580", "#a0a09a"]]],
			"fh": 2.8, "st": [1, 2], "ch": 0.0, "eq": 0.2, "ev": 0.5},
		"apartments": {"w": [["concrete", CONCRETE], ["render", ["#d8c8a8", "#e0b898"]]],
			"p": "balcony", "r": [["flat", 3], ["gabled", 1]], "pitch": 0.3,
			"rf": [["concrete", []], ["slate", ["#8d8a86"]]], "st": [3, 8], "eq": 0.6},
		"commercial": {"w": [["concrete", CONCRETE], ["render", ["#e0d0b8"]]], "p": "strip",
			"r": [["gabled", 1], ["flat", 2]], "rf": [["slate", ["#8d8a86", "#6a7580"]], ["membrane", []]],
			"gc": ["#c8301a", "#1a5a9a", "#e8b820", "#2a7a3a"]},
		"religious": {"w": [["render", ["#f2ece0", "#e0d0b8"]]], "r": [["gabled", 1]], "pitch": 0.5,
			"rf": [["slate", ["#8d8a86"]]], "tw": "bell"},
	},
}
