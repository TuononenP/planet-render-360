class_name BuildingEra
extends RefCounted

## Sub-style (era / building type) of one building inside a city zone
## (CityStyles): Paris is not one Haussmann block repeated — it is
## Haussmann, faubourg houses older than the boulevards, Belle Époque
## bow windows, the red-brick HBM ring by the Périphérique, post-war
## slabs and suburban pavillons. `refine` returns a region key whose row
## inherits (ArchitectureData.BASE) from the city row, from REAL cues
## first and a seeded weighted pick only as the last resort:
##   1. `building:architecture` (b.architecture) naming an era's style;
##   2. `start_date` (b.start_year) inside an era's years — several
##      matches go to the structural rules, then the narrowest range;
##   3. structural rules per city: levels (or tagged height / 3.2 m),
##      `roof:shape`, footprint area, `heritage`, distance from the
##      city core (ctx.cores, metres in the build's local frame) and,
##      for San Francisco, the most local district circle it stands in;
##   4. seeded pick over ERAS weights, x0.12 outside an era's distance
##      band, x district multiplier inside a CityStyles district.
## Outside a city zone a country region's periods (ArchitectureCountryEras)
## are picked the same way; other regions come back unchanged. Documented
## in docs/architecture-styles.md.

const APT := ["apartments"]
const AC := ["apartments", "commercial"]
const ACC := ["apartments", "commercial", "civic"]
const HAC := ["house", "apartments", "commercial"]
const ALL := ["house", "apartments", "commercial", "civic"]
## `building:architecture` values that mean "post-war modern" anywhere.
const MODERN := ["modern", "modernism", "modernist", "brutalist", "brutalism",
	"contemporary", "international_style", "postmodern", "postmodernism",
	"high-tech", "high_tech", "functionalism", "functionalist",
	"deconstructivism", "neo-futurism", "metabolism", "skyscraper"]
## Distance-band weight factor outside an era's [d_lo, d_hi] km.
const OUT_OF_BAND := 0.12

## Per city: [era key, kinds, year from, year to, building:architecture
## values, weight, distance band from km, to km, (storey band [min, max]),
## (heritage era)]. The city's own region (its signature fabric) is listed
## like any era. Kinds no era lists (industrial, religious, farm,
## outbuilding) keep the city row. The two optional columns stand in for a
## city's own structural rules (see _banded); city files add their cities'
## rows through ERAS below.
const CITY_ERAS := {
	"paris": [
		["haussmann", ACC, 1850, 1914, ["haussmann", "haussmannian", "haussmannien",
			"second_empire", "napoleon_iii", "neoclassicism", "neoclassical"], 6.0, 0.0, 6.0],
		["paris_post_haussmann", AC, 1895, 1914, ["post_haussmannian", "art_nouveau",
			"belle_epoque", "jugendstil"], 1.5, 0.0, 9.0],
		["paris_faubourg", HAC, 1000, 1849, ["classicism", "classical", "baroque", "medieval",
			"gothic", "renaissance", "louis_xiii", "louis_xiv", "louis_xv", "louis_xvi",
			"vernacular", "directoire", "restauration"], 2.0, 0.0, 9.0],
		["paris_hbm", APT, 1915, 1949, ["art_deco", "hbm", "habitation_bon_marche",
			"interwar"], 1.0, 4.0, 99.0],
		["paris_modern", ALL, 1950, 2100, MODERN, 0.8, 0.0, 99.0],
		["paris_pavillon", ["house"], 1850, 1949, ["pavillon", "villa", "eclectic"], 3.0, 0.0, 99.0],
	],
	"london": [
		["london", HAC, 1840, 1914, ["victorian", "edwardian", "gothic_revival",
			"queen_anne"], 5.0, 0.0, 99.0],
		["london_georgian", HAC, 1714, 1839, ["georgian", "regency", "palladian",
			"classicism", "neoclassical", "neoclassicism"], 2.0, 0.0, 6.0],
		["london_stucco", HAC, 1825, 1860, ["stucco", "italianate"], 0.6, 0.0, 8.0],
		["london_mansion", APT, 1880, 1914, ["mansion_block", "arts_and_crafts",
			"queen_anne_revival", "baroque_revival"], 1.5, 0.0, 9.0],
		["london_council", APT, 1945, 1985, ["brutalist", "brutalism", "council",
			"social_housing"], 1.2, 0.0, 99.0],
		["london_modern", ACC, 1986, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"amsterdam": [
		["amsterdam", HAC, 1500, 1909, ["dutch_renaissance", "renaissance", "baroque",
			"classicism", "golden_age", "canal_house", "neoclassicism"], 4.0, 0.0, 2.5],
		["amsterdam_school", ACC, 1910, 1945, ["amsterdam_school", "amsterdamse_school",
			"expressionism", "expressionist", "art_deco"], 1.5, 1.2, 99.0],
		["amsterdam_modern", ALL, 1946, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"berlin": [
		["berlin", HAC, 1860, 1918, ["gruenderzeit", "gründerzeit", "historicism",
			"historism", "wilhelminian", "neo-renaissance", "neo_renaissance",
			"jugendstil", "art_nouveau", "eclectic"], 5.0, 0.0, 8.0],
		["berlin_plattenbau", APT, 1960, 1990, ["plattenbau", "socialist_modernism",
			"socialist_realism", "stalinist", "prefab"], 1.5, 1.5, 99.0],
		["berlin_modern", ALL, 1991, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"barcelona": [
		["barcelona", HAC, 1860, 1936, ["modernisme", "modernista", "art_nouveau",
			"eixample", "noucentisme", "eclectic"], 5.0, 0.0, 6.0],
		["barcelona_gothic", HAC, 1000, 1859, ["gothic", "catalan_gothic", "medieval",
			"baroque", "neoclassicism", "romanesque"], 1.5, 0.0, 2.0],
		["barcelona_modern", ALL, 1950, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"rome": [
		["rome", ALL, 1400, 1939, ["baroque", "renaissance", "neoclassicism",
			"umbertino", "eclectic", "mannerism"], 5.0, 0.0, 3.5],
		["rome_palazzina", APT, 1945, 1990, ["palazzina", "neorealism"], 1.5, 2.0, 99.0],
		["rome_modern", ACC, 1991, 2100, MODERN + ["rationalism", "rationalist",
			"razionalismo"], 0.5, 0.0, 99.0],
	],
	"venice": [
		["venice", ALL, 1100, 1945, ["gothic", "venetian_gothic", "byzantine", "renaissance",
			"baroque", "neoclassicism", "vernacular", "palazzo"], 8.0, 0.0, 99.0],
		["venice_modern", ACC, 1946, 2100, MODERN, 0.3, 0.0, 99.0],
	],
	"stockholm": [
		["stockholm_medieval", ALL, 1200, 1799, ["medieval", "gothic", "baroque", "renaissance"], 2.0, 0.0, 3.0, [3, 5]],
		["stockholm_wood", ["house", "apartments"], 1700, 1919, ["wooden", "vernacular"], 0.5, 0.0, 99.0, [1, 2]],
		["stockholm_stone", ACC, 1800, 1919, ["national_romantic", "art_nouveau", "jugendstil"], 4.0, 0.0, 5.0, [4, 6]],
		["stockholm_grace", ACC, 1920, 1932, ["swedish_grace", "nordic_classicism", "classicism", "neoclassicism"], 2.0, 0.0, 8.0, [4, 6]],
		["stockholm_funkis", ACC, 1933, 1964, ["functionalism", "functionalist", "funkis"], 2.0, 0.0, 99.0, [3, 6]],
		["stockholm_miljon", ACC, 1965, 1989, ["million_programme", "prefab", "brutalist"], 2.0, 0.0, 99.0, [4, 9]],
		["stockholm_eco", ACC, 1990, 2100, MODERN, 2.0, 0.0, 99.0, [5, 12]],
	],
	"new_york": [
		["new_york", AC, 1870, 1929, ["tenement", "renaissance_revival",
			"romanesque_revival", "walk_up"], 5.0, 0.0, 99.0],
		["nyc_brownstone", ["house", "apartments"], 1840, 1899, ["brownstone",
			"italianate", "neo_grec", "rowhouse", "greek_revival"], 2.0, 1.5, 99.0],
		["nyc_prewar", ACC, 1900, 1945, ["art_deco", "beaux_arts", "gothic_revival",
			"neo_gothic", "prewar"], 1.0, 0.0, 99.0],
		["nyc_glass", ACC, 1950, 2100, MODERN, 1.0, 0.0, 99.0],
		["nyc_castiron", AC, 1840, 1910, ["cast_iron", "castiron"], 1.0, 0.0, 99.0],
		["nyc_loft", AC, 1850, 1945, ["industrial_loft", "warehouse"], 1.0, 0.0, 99.0],
		["nyc_nycha", ["apartments"], 1935, 1980, ["nycha"], 1.0, 0.0, 99.0],
		["nyc_pencil", AC, 2000, 2100, ["supertall", "pencil_tower"], 1.0, 0.0, 99.0],
		["nyc_international", ["commercial"], 1946, 1980, ["international_style"], 1.0, 0.0, 99.0],
	],
	"chicago": [
		["chicago", HAC, 1880, 1940, ["chicago_school", "two_flat", "prairie_school",
			"bungalow"], 5.0, 0.0, 99.0],
		["chicago_greystone", ["house", "apartments"], 1890, 1925, ["greystone",
			"romanesque_revival", "richardsonian_romanesque"], 1.5, 2.0, 99.0],
		["chicago_tower", ACC, 1950, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"san_francisco": [
		["san_francisco", HAC, 1906, 1925, ["edwardian", "colonial_revival", "classical_revival"],
			4.0, 0.0, 5.0],
		["sf_victorian", ["house", "apartments"], 1850, 1905, ["victorian", "queen_anne",
			"italianate", "stick", "eastlake"], 3.0, 1.0, 5.5],
		["sf_stucco", ["house", "apartments"], 1926, 1955, ["mediterranean_revival",
			"spanish_colonial_revival", "mission_revival", "marina_style", "streamline_moderne",
			"art_moderne", "storybook"], 3.0, 3.5, 99.0],
		["sf_prewar", ACC, 1906, 1949, ["art_deco", "beaux_arts", "neoclassical", "neoclassicism",
			"gothic_revival", "renaissance_revival", "chicago_school"], 0.6, 0.0, 99.0],
		["sf_chinatown", AC, 1906, 1930, ["chinese", "chinese_revival", "chinoiserie"], 0.2, 0.0, 2.5],
		["sf_tower", ACC, 1950, 2100, MODERN, 0.8, 0.0, 99.0],
	],
	"hong_kong": [
		["hong_kong", APT, 1970, 2100, ["public_housing", "residential_tower"], 5.0, 0.0, 99.0],
		["hk_tenement", AC, 1900, 1969, ["tong_lau", "tenement", "shophouse",
			"art_deco"], 1.5, 0.0, 99.0],
		["hk_office", ["commercial", "civic"], 1970, 2100, MODERN, 3.0, 0.0, 99.0],
	],
	"singapore": [
		["singapore", APT, 1960, 2100, ["hdb", "public_housing"], 5.0, 0.0, 99.0],
		["sg_shophouse", HAC, 1840, 1959, ["shophouse", "straits_eclectic", "peranakan",
			"art_deco", "colonial"], 1.5, 0.0, 99.0],
		["sg_tower", ACC, 1980, 2100, MODERN + ["condominium"], 1.0, 0.0, 99.0],
	],
	"dubai": [
		["dubai", AC, 1975, 2100, [], 5.0, 0.0, 99.0],
		["dubai_tower", ACC, 1995, 2100, MODERN, 2.0, 0.0, 99.0],
		["dubai_heritage", ["house", "commercial"], 1800, 1969, ["traditional", "vernacular",
			"emirati", "gulf_vernacular", "islamic"], 0.4, 0.0, 99.0],
		["dubai_villa", ["house"], 1970, 2100, ["villa"], 4.0, 0.0, 99.0],
	],
	"monaco": [
		["monaco", AC, 1860, 1945, ["belle_epoque", "art_nouveau", "neoclassicism",
			"eclectic", "art_deco", "historicism"], 5.0, 0.0, 99.0],
		["monaco_old", HAC, 1200, 1859, ["genoese", "baroque", "vernacular", "medieval",
			"renaissance"], 0.4, 0.0, 99.0],
		["monaco_tower", ACC, 1960, 2100, MODERN, 2.5, 0.0, 99.0],
	],
	"interlaken": [
		["interlaken", HAC, 1500, 2100, ["chalet", "swiss_chalet", "heimatstil", "vernacular"],
			5.0, 0.0, 99.0],
		["interlaken_hotel", ["commercial", "apartments"], 1860, 1930, ["belle_epoque",
			"historicism", "neo-baroque", "neoclassicism", "grand_hotel"], 1.0, 0.0, 1.5],
		["interlaken_modern", ACC, 1955, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"banff": [
		["banff", AC, 1950, 2100, ["rustic", "mountain_rustic", "national_park_rustic"],
			5.0, 0.0, 99.0],
		["banff_heritage", ["commercial", "civic", "apartments"], 1885, 1949, ["scottish_baronial",
			"chateau", "chateauesque", "tudor_revival", "arts_and_crafts"], 0.6, 0.0, 99.0],
		["banff_house", ["house"], 1900, 2100, ["cottage", "bungalow", "craftsman"], 3.0, 0.0, 99.0],
	],
}

static var ERAS: Dictionary = ArchitectureData._merged([CITY_ERAS, ArchitectureCitiesNorth.ERAS, ArchitectureCitiesFinland.ERAS,
	ArchitectureCitiesSouth.ERAS, ArchitectureCitiesCentral.ERAS, ArchitectureCitiesWorld.ERAS,
	ArchitectureCitiesNewWorld.ERAS, ArchitectureCitiesEastAsia.ERAS])

## Sub-region key for one building (see the class doc). `ctx` is the
## build context (BuildingHeights._height_context): its `cores` give the
## distance cue; an empty ctx simply leaves that cue unknown.
static func refine(region: String, kind: String, b: Dictionary, ctx: Dictionary,
		seed_v: float, area_m2: float) -> String:
	var city := CityStyles.city_of_region(region)
	if city == "" or not ERAS.has(city):
		return _country(region, kind, b, ctx, seed_v, area_m2)
	var cands: Array = []
	for e in (ERAS[city] as Array):
		if ((e as Array)[1] as Array).has(kind):
			cands.append(e)
	if cands.is_empty():
		return region
	var c := cues(b, ctx, area_m2)
	# Empire fabric is local to the old centre; an undated suburban
	# house or a heritage modernist building must not become Engel ochre.
	if city == "helsinki" and not _empire(kind, c):
		cands = cands.filter(func(e: Array) -> bool: return str(e[0]) != "helsinki_empire")
	if city == "helsinki" and int(c["lv"]) < 10:
		# A recent date alone does not turn an unheighted shop or sauna
		# into a skyscraper; retain the contemporary mid-rise fabric.
		cands = cands.filter(func(e: Array) -> bool: return str(e[0]) != "helsinki_modern")
	var arch := str(c["arch"])
	if arch != "":
		for e in cands:
			if ((e as Array)[4] as Array).has(arch):
				return str((e as Array)[0])
	# A Seoul palace hall comes from the walls' circles or a heritage
	# hall (ArchitectureCitiesEastAsia.seoul_rule), never by elimination:
	# a church, whose kind only the palace row lists, keeps the city fabric.
	if city == "seoul" and _rules(city, kind, c) != "seoul_palace":
		cands = cands.filter(func(e: Array) -> bool: return str(e[0]) != "seoul_palace")
		if cands.is_empty():
			return region
	var year := int(c["year"])
	# Tall historic New York buildings keep their masonry even when a
	# broad, overlapping year band would otherwise choose walk-up fabric.
	if city == "new_york" and int(c["lv"]) >= 10 and (bool(c["heritage"]) or (year > 0 and year < 1945)):
		for e in cands:
			if str((e as Array)[0]) == "nyc_prewar":
				return "nyc_prewar"
	if city == "new_york":
		var local := _rules(city, kind, c)
		var specific := ["nyc_castiron", "nyc_loft", "nyc_nycha", "nyc_pencil", "nyc_international"]
		if local in specific:
			for e in cands:
				if str((e as Array)[0]) == local:
					return local
		# These fabrics need a district, slenderness or dated style cue;
		# overlapping dates alone must not spread them across the city.
		cands = cands.filter(func(e: Array) -> bool: return str(e[0]) not in specific)
	if year > 0:
		var dated: Array = []
		for e in cands:
			if year >= int((e as Array)[2]) and year <= int((e as Array)[3]):
				dated.append(e)
		if dated.size() == 1:
			return str((dated[0] as Array)[0])
		if dated.size() > 1:
			var ruled := _rules(city, kind, c)
			for e in dated:
				if str((e as Array)[0]) == ruled:
					return ruled
			dated.sort_custom(func(x, y): return int(x[3]) - int(x[2]) < int(y[3]) - int(y[2]))
			return str((dated[0] as Array)[0])
	var by_rule := _rules(city, kind, c)
	if by_rule != "":
		for e in cands:
			if str((e as Array)[0]) == by_rule:
				return by_rule
	return _weighted(cands, c, ctx, b, seed_v)

## The cues one building offers: arch tag, year, levels (or tagged
## height / 3.2 m), roof tag, footprint, heritage, distance km (-1 = unknown).
static func cues(b: Dictionary, ctx: Dictionary, area_m2: float) -> Dictionary:
	var lv := int(b.get("levels", 0))
	if lv <= 0 and str(b.get("height_source", "")) in ["tag_height", "reference"]:
		lv = roundi(float(b.get("height", 0.0)) / 3.2)
	var dist := -1.0
	var cores: Array = ctx.get("cores", [])
	if not cores.is_empty() and b.has("x"):
		var pos := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))) \
			/ WorldScale.metres_to_units()
		dist = INF
		for core in cores:
			dist = minf(dist, (pos - (core as Vector2)).length() / 1000.0)
	# The most local district circle the building stands in (its era key).
	var district := ""
	if b.has("x"):
		var at := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))) / WorldScale.metres_to_units()
		var best := INF
		for d in (ctx.get("districts", []) as Array):
			var dr: Array = d
			if float(dr[2]) < best and (at - (dr[1] as Vector2)).length() <= float(dr[2]):
				best = float(dr[2])
				district = str(dr[0])
	return {"arch": str(b.get("architecture", "")).strip_edges().to_lower().replace(" ", "_").replace("-", "_"),
		"year": int(b.get("start_year", 0)), "lv": lv, "district": district,
		"roof": str(b.get("roof_shape", "")).strip_edges().to_lower(),
		"tag": str(b.get("kind", "")).to_lower(), "name": str(b.get("name", "")),
		"area": area_m2, "heritage": bool(b.get("heritage", false)), "dist": dist}

## Block size (m) and the share of untagged buildings whose era follows
## their block rather than their own seed.
const BLOCK_M := 64.0
const BLOCK_SHARE := 0.6

## Last resort: seeded pick over the eras' weights, scaled by the
## distance band and any district the building stands in.
static func _weighted(cands: Array, c: Dictionary, ctx: Dictionary, b: Dictionary,
		seed_v: float, cell_m: float = BLOCK_M) -> String:
	var dist := float(c["dist"])
	var pos := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))) \
		/ WorldScale.metres_to_units()
	var pairs: Array = []
	for e in cands:
		var row: Array = e
		var w := float(row[5])
		if dist >= 0.0 and (dist < float(row[6]) or dist > float(row[7])):
			w *= OUT_OF_BAND
		if b.has("x"):
			for d in (ctx.get("districts", []) as Array):
				var dr: Array = d
				if str(dr[0]) == str(row[0]) and (pos - (dr[1] as Vector2)).length() <= float(dr[2]):
					w *= float(dr[3])
		pairs.append([str(row[0]), w])
	# A block is built and renovated together: most of the time the pick is
	# seeded by the 64 m block the building stands in, so neighbours share an
	# era (the rest keep their own seed, so a block is not a clone).
	var pick_seed := seed_v
	if b.has("x") and ArchitectureStyle._h(seed_v, 22.0) < BLOCK_SHARE:
		pick_seed = TerrainBuilder._hash(floorf(pos.x / cell_m) * 3.7 + 0.5,
			floorf(pos.y / cell_m) * 1.9 + 0.5)
	return ArchitectureStyle._pick_weighted(pairs, pick_seed, 21)

## A country region's period for one building: a named style, then the
## start_date, then what its height and heritage say; else the neighbourhood's
## seeded pick. Rows run oldest to newest (ArchitectureCountryEras.ERAS).
static func _country(region: String, kind: String, b: Dictionary, ctx: Dictionary,
		seed_v: float, area_m2: float) -> String:
	var cands: Array = (ArchitectureCountryEras.ERAS.get(region, []) as Array).filter(
		func(e: Array) -> bool: return (e[1] as Array).has(kind))
	if cands.is_empty():
		return region
	var c := cues(b, ctx, area_m2)
	var arch := str(c["arch"])
	var year := int(c["year"])
	for e: Array in cands:
		if arch != "" and (e[4] as Array).has(arch):
			return str(e[0])
	for e: Array in cands:
		if year > 0 and year >= int(e[2]) and year <= int(e[3]):
			return str(e[0])
	var lv := int(c["lv"])
	if lv >= 11:
		return str((cands.back() as Array)[0])
	if bool(c["heritage"]) and lv <= 6:
		return str((cands.front() as Array)[0])
	if str(c["roof"]) == "flat" and lv >= 5 and ArchitectureData.REGIONS.has(region + "_postwar"):
		return region + "_postwar"
	return _weighted(cands, c, ctx, b, seed_v, ArchitectureCountryEras.CELL_M)

## Structural rules per city ("" = undecided). Only levels, roof tag,
## footprint, heritage and distance — the year and arch tag are read
## before these. A rule naming an era the kind cannot have is ignored.
static func _rules(city: String, kind: String, c: Dictionary) -> String:
	var lv := int(c["lv"])
	var area := float(c["area"])
	var dist := float(c["dist"])
	var roof := str(c["roof"])
	var old := bool(c["heritage"])
	var small := area > 0.0 and area <= 250.0
	match city:
		"paris":
			if kind == "house":
				return "paris_faubourg" if old else "paris_pavillon"
			# 9-11 tagged levels in the core are mostly Haussmann blocks and
			# department stores (BHV, Samaritaine) counting their roof storeys.
			var core := dist >= 0.0 and dist < 3.0
			if lv >= 12 or (lv >= 9 and not core) or (roof == "flat" and lv >= 7):
				return "paris_modern"
			if lv >= 6 and lv <= 8 and dist > 4.5:
				return "paris_hbm"
			if (old and lv >= 1 and lv <= 5) or (lv >= 1 and lv <= 4):
				return "paris_faubourg"
			if roof == "mansard" or lv >= 5:
				return "haussmann"
			if old:
				return "paris_faubourg" if small else "haussmann"
		"london":
			if lv >= 10 or (kind == "commercial" and dist >= 0.0 and dist < 1.6
					and (lv >= 7 or area >= 1500.0)):
				return "london_modern"
			if kind == "apartments" and (lv >= 8 or (roof == "flat" and lv >= 5)):
				return "london_council"
			if kind == "apartments" and lv >= 5 and area >= 350.0:
				return "london_mansion"
			if old and lv >= 3 and lv <= 5:
				return "london_georgian"
			if lv >= 1 and lv <= 3 and small:
				return "london"
		"amsterdam":
			if lv >= 7 or (roof == "flat" and area >= 800.0):
				return "amsterdam_modern"
			if (small and lv <= 6) or old:
				return "amsterdam"
			if lv >= 3 and lv <= 5 and area >= 500.0 and dist > 1.2:
				return "amsterdam_school"
		"berlin":
			if lv >= 9 or (roof == "flat" and lv >= 5 and area >= 1000.0):
				return "berlin_modern" if dist >= 0.0 and dist < 1.2 else "berlin_plattenbau"
			if (lv >= 4 and lv <= 6) or old:
				return "berlin"
		"barcelona":
			if lv >= 10:
				return "barcelona_modern"
			if (small or old) and lv <= 6 and dist >= 0.0 and dist < 1.5:
				return "barcelona_gothic"
			if lv >= 5:
				return "barcelona"
		"rome":
			if lv >= 10:
				return "rome_modern"
			if kind == "apartments" and lv >= 5 and dist > 3.5 and not old:
				return "rome_palazzina"
			if old or (dist >= 0.0 and dist < 2.5):
				return "rome"
		"venice":
			if lv >= 6 or (roof == "flat" and lv >= 4 and area >= 600.0):
				return "venice_modern"
			if old or lv >= 1:
				return "venice"
		"helsinki":
			var district := str(c["district"])
			if _empire(kind, c):
				return "helsinki_empire"
			if kind == "house":
				return "helsinki_wood" if district == "helsinki_wood" or bool(c["heritage"]) else "helsinki_suburb"
			if lv >= 10:
				return "helsinki_modern"
			if district in ["helsinki_wood", "helsinki_classicism", "helsinki_functional", "helsinki_suburb",
					"helsinki_element", "helsinki_midrise"]:
				return district
			if district == "helsinki" and lv >= 4 and lv <= 7:
				return "helsinki"
			if roof == "flat" and lv >= 5 and area >= 500.0 and dist > 2.5:
				return "helsinki_element"
			if dist > 3.0:
				return "helsinki_suburb"
			return "helsinki" if lv >= 4 else "helsinki_classicism"
		"espoo":
			var district := str(c["district"])
			if kind == "house":
				return "kauniainen" if district == "kauniainen" or old else "tapiola"
			if district == "otaniemi":
				return "otaniemi"
			if lv >= 12 or district == "espoo_modern":
				return "espoo_modern"
			return "tapiola"
		"stockholm":
			var district := str(c["district"])
			if kind == "house":
				return "stockholm_wood"
			if district in ["stockholm_medieval", "stockholm_stone", "stockholm_grace", "stockholm_funkis", "stockholm_miljon", "stockholm_eco"]:
				return district
			if district == "stockholm_wood" and lv <= 2:
				return district
			if old:
				return "stockholm_stone"
			return "stockholm_miljon" if lv >= 9 else "stockholm_stone"
		"new_york":
			var district := str(c["district"])
			var year := int(c["year"])
			if district in ["nyc_castiron", "nyc_loft"] and lv < 10 and (year == 0 or year <= 1945):
				return district
			if district == "nyc_nycha" and kind == "apartments" and lv >= 8 and (year == 0 or (year >= 1935 and year <= 1980)):
				return "nyc_nycha"
			if lv >= 55 and area > 0.0 and area <= 850.0 and (year == 0 or year >= 2000):
				return "nyc_pencil"
			if kind == "commercial" and lv >= 15 and year >= 1946 and year <= 1980:
				return "nyc_international"
			if lv >= 10 and (old or district == "nyc_prewar"):
				return "nyc_prewar"
			if district == "nyc_brownstone" and (kind == "house" or (lv >= 3 and lv <= 4 and small)):
				return "nyc_brownstone"
			if lv >= 20:
				return "nyc_glass"
			if lv >= 10:
				return "nyc_prewar"
			if kind == "house" or (lv >= 3 and lv <= 4 and small):
				return "nyc_brownstone"
			if lv >= 3:
				return "new_york"
		"chicago":
			if lv >= 12:
				return "chicago_tower"
			if old and lv <= 3:
				return "chicago_greystone"
			if lv >= 2:
				return "chicago"
		"san_francisco":
			# The district a building stands in is the strongest cue here:
			# Victorian belts west of Van Ness, Edwardian rebuilding east of
			# it after 1906, stucco Marina and Sunset, Nob Hill high-rises.
			var district := str(c["district"])
			if lv >= 9:
				var pre := int(c["year"]) > 0 and int(c["year"]) < 1950
				if lv <= 30 and (pre or old or district == "sf_prewar"):
					return "sf_prewar"
				return "sf_tower"
			if district == "sf_chinatown" and kind != "house":
				return "sf_chinatown"
			if kind == "house" or (lv >= 2 and lv <= 3 and small):
				if district in ["sf_stucco", "sf_victorian", "san_francisco"]:
					return district
				return "sf_victorian" if old else ""
			if lv >= 3 or (lv <= 0 and district != "sf_tower"):
				return "sf_stucco" if district == "sf_stucco" else "san_francisco"
		"tokyo":
			return ArchitectureCitiesEastAsia.tokyo_rule(kind, c)
		"hong_kong":
			if kind == "commercial" and lv >= 12:
				return "hk_office"
			if lv >= 1 and lv <= 9:
				return "hk_tenement"
			if lv >= 10:
				return "hong_kong"
		"singapore":
			if lv >= 1 and lv <= 4:
				return "sg_shophouse"
			if lv >= 30 or (kind == "commercial" and lv >= 8):
				return "sg_tower"
			if lv >= 5:
				return "singapore"
		"seoul":
			return ArchitectureCitiesEastAsia.seoul_rule(kind, c)
		"dubai":
			if lv >= 20 or (kind == "commercial" and lv >= 12):
				return "dubai_tower"
			if kind == "house":
				return "dubai_heritage" if old else "dubai_villa"
			if old and lv <= 3:
				return "dubai_heritage"
			if lv >= 4:
				return "dubai"
		"monaco":
			if lv >= 10:
				return "monaco_tower"
			if old and lv <= 5:
				return "monaco_old"
			if lv >= 4:
				return "monaco"
		"interlaken":
			if kind == "commercial" and (area >= 700.0 or lv >= 5):
				return "interlaken_hotel"
			if lv >= 6 or (roof == "flat" and lv >= 3):
				return "interlaken_modern"
			if kind == "house" or (lv >= 1 and lv <= 4):
				return "interlaken"
		"banff":
			if kind == "house":
				return "banff_house"
			if old:
				return "banff_heritage"
			if lv >= 1:
				return "banff"
	return _banded(city, kind, c)

## The data-driven rule for cities without their own arm above: a
## heritage building goes to the city's heritage era, else the first
## era (in listed order) whose storey band holds the building's levels.
static func _banded(city: String, kind: String, c: Dictionary) -> String:
	var lv := int(c["lv"])
	var rows: Array = []
	for e in (ERAS.get(city, []) as Array):
		var row: Array = e
		if row.size() > 8 and (row[1] as Array).has(kind):
			rows.append(row)
	if bool(c["heritage"]):
		for row in rows:
			if row.size() > 9 and bool(row[9]):
				return str(row[0])
	if lv <= 0:
		return ""
	for row in rows:
		var band: Array = row[8]
		if lv >= int(band[0]) and lv <= int(band[1]):
			return str(row[0])
	return ""

static func _empire(kind: String, c: Dictionary) -> bool:
	var year := int(c["year"])
	var district := str(c["district"])
	var core := float(c["dist"]) >= 0.0 and float(c["dist"]) <= 1.2
	if kind == "house" and not bool(c["heritage"]):
		return false
	return district == "helsinki_empire" or (core and (bool(c["heritage"]) or (year > 0 and year < 1880)))
