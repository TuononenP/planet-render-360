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
##   r     roof shapes        [[shape, weight], ...] — flat, gabled, hipped, mansard,
##         pyramidal, dome, gambrel, skillion, half-hipped, saltbox, round
##   pitch roof rise multiplier (1.0 = BuildingBuilder default rise)
##   rf    roof finishes      [[roof set, [sRGB hex tints]], ...]
##   fh    metres per storey  st  untagged storey range [min, max]
##   ch/dm/eq  chimney / dormer / rooftop-equipment probability
##   tw    religious tower: spire | bell | onion | minaret | pagoda | shikhara
##   fix   true = `st` is the typology's real range (no density stretch)
##   sh    may also be a palette [hex, ...] (one colour per building)
##   rv    3D relief Dictionary (look["relief"]; a row's rv replaces its
##         parent's): balcony_rows Array[int] (storeys from ground=0),
##         balconette, deep_balcony, awning, fire_escape, stoop, signage,
##         oriel (0..1 odds), awning_colours [sRGB hex], string_course,
##         quoins (bool), gable "" | step | neck | bell (or weighted
##         [[gable, w], ...], picked per building)

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
	["mountain_lodge", 50.95, -116.50, 51.45, -115.20], # Banff, Lake Louise, Canmore
	["mountain_lodge", 52.78, -118.25, 53.00, -117.90], # Jasper
	["mountain_lodge", 50.05, -123.05, 50.20, -122.85], # Whistler
	["mountain_lodge", 35.80, -121.98, 36.45, -121.55], # Big Sur
	["mountain_lodge", 38.85, -120.30, 39.35, -119.85], # Lake Tahoe
	["mountain_lodge", 39.12, -106.92, 39.25, -106.75], # Aspen
	["mountain_lodge", 43.40, -110.90, 43.60, -110.65], # Jackson Hole
	["north_america", 18.80, -160.60, 22.40, -154.70], # Hawaii
	["north_america", 51.00, -170.00, 72.00, -129.00], # Alaska
	["north_america", 41.60, -141.00, 83.00, -52.00],  # Canada
	["north_america", 31.30, -125.00, 49.50, -97.00],  # US west
	["north_america", 25.00, -97.00, 49.50, -66.90],   # US east
	["latin_america", -56.00, -118.50, 32.80, -34.00],
]

## Regions that inherit unlisted kinds from another before GENERIC.
## City and era rows add their own links (ArchitectureParis / Cities*),
## merged into BASE below.
const COUNTRY_BASE := {
	"alpine": "central_europe",
	"haussmann": "france",
	"france": "central_europe",
}
static var BASE: Dictionary = _merged([COUNTRY_BASE, ArchitectureMountain.BASE, ArchitectureParis.BASE,
	ArchitectureCitiesEurope.BASE, ArchitectureCitiesAmericas.BASE,
	ArchitectureCitiesAsia.BASE])

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
## kind). Regions not listed use their BASE chain's mix, else
## INFILL_DEFAULT.
const INFILL_DEFAULT := {
	"house": 52, "apartments": 20, "commercial": 8, "industrial": 5,
	"civic": 4, "farm": 3, "outbuilding": 8,
}
const INFILL_MIX := {
	"haussmann": {"apartments": 78, "commercial": 10, "civic": 6, "house": 2, "outbuilding": 4},
	"london": {"house": 46, "apartments": 34, "commercial": 10, "civic": 4, "outbuilding": 6},
	"amsterdam": {"house": 30, "apartments": 50, "commercial": 12, "civic": 4, "outbuilding": 4},
	"berlin": {"apartments": 72, "commercial": 12, "civic": 6, "house": 4, "outbuilding": 6},
	"barcelona": {"apartments": 76, "commercial": 12, "civic": 6, "house": 2, "outbuilding": 4},
	"rome": {"apartments": 70, "commercial": 14, "civic": 6, "house": 6, "outbuilding": 4},
	"new_york": {"apartments": 66, "commercial": 16, "house": 10, "civic": 4, "outbuilding": 4},
	"chicago": {"apartments": 44, "house": 34, "commercial": 12, "civic": 4, "outbuilding": 6},
	"san_francisco": {"apartments": 50, "house": 34, "commercial": 10, "outbuilding": 6},
	"tokyo": {"house": 38, "apartments": 36, "commercial": 18, "industrial": 2, "outbuilding": 6},
	"hong_kong": {"apartments": 74, "commercial": 18, "civic": 4, "outbuilding": 4},
	"singapore": {"apartments": 66, "commercial": 20, "civic": 6, "house": 4, "outbuilding": 4},
	"eastern_europe": {"apartments": 48, "house": 28, "commercial": 6, "industrial": 6, "civic": 4, "outbuilding": 8},
	"east_asia": {"apartments": 62, "commercial": 14, "house": 12, "civic": 4, "industrial": 4, "outbuilding": 4},
	"japan": {"house": 46, "apartments": 30, "commercial": 12, "industrial": 4, "outbuilding": 8},
	"alpine": {"house": 58, "farm": 12, "apartments": 12, "commercial": 6, "civic": 4, "outbuilding": 8},
	"north_america": {"house": 64, "commercial": 10, "apartments": 10, "industrial": 6, "outbuilding": 10},
	"mountain_lodge": {"house": 56, "apartments": 12, "commercial": 10, "civic": 4, "farm": 4, "outbuilding": 14},
	"australia": {"house": 68, "apartments": 10, "commercial": 6, "industrial": 6, "outbuilding": 10},
	"middle_east": {"house": 34, "apartments": 36, "commercial": 12, "outbuilding": 12, "civic": 6},
	"south_asia": {"house": 40, "apartments": 28, "commercial": 16, "outbuilding": 12, "civic": 4},
	"sub_saharan_africa": {"house": 62, "apartments": 10, "commercial": 10, "outbuilding": 14, "civic": 4},
}

const SLATE := ["#4f5760", "#5a626b", "#46505a"]
const TERRA := ["#b5542f", "#a8482a", "#c0643a", "#9a4a2c"]
const WARM_RENDER := ["#e9dfc4", "#f0e6d0", "#d9c9a0", "#e5d4c0", "#e8e4dc", "#d8b9a0"]
const BRICK := ["#9c4a35", "#8a3f30", "#b0634a", "#7b4a3a"]
const CONCRETE := ["#b6b1a7", "#a7a296", "#bfb7a8", "#959c95"]
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
		"r": [["gabled", 3], ["flat", 2], ["round", 1]], "pitch": 0.35,
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

## Per-region profiles live in ArchitectureRegions (countries) and the
## city / era files (data-only split), merged once here.
static var REGIONS: Dictionary = _merged([ArchitectureRegions.REGIONS, ArchitectureMountain.REGIONS,
	ArchitectureParis.REGIONS, ArchitectureCitiesEurope.REGIONS,
	ArchitectureCitiesAmericas.REGIONS, ArchitectureCitiesAsia.REGIONS])

static func _merged(tables: Array) -> Dictionary:
	var out := {}
	for t in tables:
		for k in (t as Dictionary):
			assert(not out.has(k), "duplicate architecture region " + str(k))
			out[k] = (t as Dictionary)[k]
	return out
