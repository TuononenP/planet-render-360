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
##      city core (ctx.cores, metres in the build's local frame);
##   4. seeded pick over ERAS weights, x0.12 outside an era's distance
##      band, x district multiplier inside a CityStyles district.
## Regions that are not a city's come back unchanged. Documented in
## docs/architecture-styles.md.

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
## values, weight, distance band from km, to km]. The city's own region
## (its signature fabric) is listed like any era. Kinds no era lists
## (industrial, religious, farm, outbuilding) keep the city row.
const ERAS := {
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
	"new_york": [
		["new_york", AC, 1870, 1929, ["tenement", "renaissance_revival",
			"romanesque_revival", "walk_up"], 5.0, 0.0, 99.0],
		["nyc_brownstone", ["house", "apartments"], 1840, 1899, ["brownstone",
			"italianate", "neo_grec", "rowhouse", "greek_revival"], 2.0, 1.5, 99.0],
		["nyc_prewar", ACC, 1900, 1945, ["art_deco", "beaux_arts", "gothic_revival",
			"neo_gothic", "prewar"], 1.0, 0.0, 99.0],
		["nyc_glass", ACC, 1950, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"chicago": [
		["chicago", HAC, 1880, 1940, ["chicago_school", "two_flat", "prairie_school",
			"bungalow"], 5.0, 0.0, 99.0],
		["chicago_greystone", ["house", "apartments"], 1890, 1925, ["greystone",
			"romanesque_revival", "richardsonian_romanesque"], 1.5, 2.0, 99.0],
		["chicago_tower", ACC, 1950, 2100, MODERN, 1.0, 0.0, 99.0],
	],
	"san_francisco": [
		["san_francisco", HAC, 1906, 1945, ["edwardian", "mission_revival", "art_deco"],
			4.0, 0.0, 99.0],
		["sf_victorian", ["house", "apartments"], 1850, 1905, ["victorian", "queen_anne",
			"italianate", "stick", "eastlake"], 3.0, 1.0, 99.0],
		["sf_tower", ACC, 1950, 2100, MODERN, 0.8, 0.0, 99.0],
	],
	"tokyo": [
		["tokyo", AC, 1950, 2100, [], 5.0, 0.0, 99.0],
		["tokyo_house", ["house"], 1000, 2100, ["minka", "machiya", "traditional",
			"sukiya"], 1.0, 0.0, 99.0],
		["tokyo_tower", ACC, 1990, 2100, ["high-tech", "metabolism", "skyscraper",
			"postmodern"], 0.6, 0.0, 99.0],
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
}

## Sub-region key for one building (see the class doc). `ctx` is the
## build context (BuildingHeights._height_context): its `cores` give the
## distance cue; an empty ctx simply leaves that cue unknown.
static func refine(region: String, kind: String, b: Dictionary, ctx: Dictionary,
		seed_v: float, area_m2: float) -> String:
	var city := CityStyles.city_of_region(region)
	if city == "" or not ERAS.has(city):
		return region
	var cands: Array = []
	for e in (ERAS[city] as Array):
		if ((e as Array)[1] as Array).has(kind):
			cands.append(e)
	if cands.is_empty():
		return region
	var c := cues(b, ctx, area_m2)
	var arch := str(c["arch"])
	if arch != "":
		for e in cands:
			if ((e as Array)[4] as Array).has(arch):
				return str((e as Array)[0])
	var year := int(c["year"])
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
	if lv <= 0 and str(b.get("height_source", "")) == "tag_height":
		lv = roundi(float(b.get("height", 0.0)) / 3.2)
	var dist := -1.0
	var cores: Array = ctx.get("cores", [])
	if not cores.is_empty() and b.has("x"):
		var pos := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))) \
			/ WorldScale.metres_to_units()
		dist = INF
		for core in cores:
			dist = minf(dist, (pos - (core as Vector2)).length() / 1000.0)
	return {"arch": str(b.get("architecture", "")).strip_edges().to_lower().replace(" ", "_"),
		"year": int(b.get("start_year", 0)), "lv": lv,
		"roof": str(b.get("roof_shape", "")).strip_edges().to_lower(),
		"area": area_m2, "heritage": bool(b.get("heritage", false)), "dist": dist}

## Last resort: seeded pick over the eras' weights, scaled by the
## distance band and any district the building stands in.
static func _weighted(cands: Array, c: Dictionary, ctx: Dictionary, b: Dictionary,
		seed_v: float) -> String:
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
	return ArchitectureStyle._pick_weighted(pairs, seed_v, 21)

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
		"new_york":
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
			if lv >= 9:
				return "sf_tower"
			if kind == "house" or old or (lv >= 2 and lv <= 3 and small):
				return "sf_victorian"
			if lv >= 3:
				return "san_francisco"
		"tokyo":
			if kind == "house":
				return "tokyo_house"
			if lv >= 15:
				return "tokyo_tower"
			if lv >= 1:
				return "tokyo"
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
	return ""
