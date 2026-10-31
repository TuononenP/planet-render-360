class_name CityStyles
extends RefCounted

## City style zones, checked by ArchitectureStyle.region_for before the
## coarse country boxes: a viewpoint inside one gets that city's own
## region row (which inherits from its country via ArchitectureData.BASE),
## so London is not "generic UK brick" and Manhattan is not "US suburb".
## BuildingEra then refines each building to a sub-style (era / type) of
## its city from real cues (start_date, heritage, building:architecture,
## levels, roof:shape, footprint) and its distance from the city core.
## Data only plus a few pure helpers; documented in
## docs/architecture-styles.md.

## [city, region, lat, lon, radius_km]. First match wins, so a city may
## list several circles (Manhattan + inner Brooklyn + inner Queens).
## Radii are deliberately tight: the zone is the historic/dense core
## whose fabric the city rows describe; suburbs fall to the country row.
## Paris keeps its ArchitectureData box too (the inner suburbs inside it
## stay "haussmann"); the zone only makes the city/era cues available.
const ZONES := [
	["paris", "haussmann", 48.8566, 2.3522, 5.5],
	["london", "london", 51.5074, -0.1278, 12.0],
	["amsterdam", "amsterdam", 52.3676, 4.9041, 7.0],
	["berlin", "berlin", 52.5200, 13.4050, 12.0],
	["barcelona", "barcelona", 41.3874, 2.1686, 8.0],
	["rome", "rome", 41.9028, 12.4964, 9.0],
	["new_york", "new_york", 40.7831, -73.9712, 11.0],  # Manhattan
	["new_york", "new_york", 40.6800, -73.9600, 7.0],   # inner Brooklyn
	["new_york", "new_york", 40.7500, -73.8950, 5.5],   # inner Queens
	["chicago", "chicago", 41.8781, -87.6298, 11.0],
	["san_francisco", "san_francisco", 37.7749, -122.4194, 8.0],
	["tokyo", "tokyo", 35.6812, 139.7671, 18.0],
	["hong_kong", "hong_kong", 22.3193, 114.1694, 14.0],
	["singapore", "singapore", 1.3521, 103.8198, 22.0],
]

## Cores the era rules measure distance from (historic centre or CBD,
## not the zone centre). Several cores = distance to the nearest
## (New York: Midtown and Downtown).
const CORES := {
	"paris": [[48.8566, 2.3522]],                          # Île de la Cité
	"london": [[51.5136, -0.0890]],                        # Bank (City of London)
	"amsterdam": [[52.3731, 4.8922]],                      # Dam
	"berlin": [[52.5170, 13.3889]],                        # Mitte
	"barcelona": [[41.3874, 2.1686]],                      # Plaça de Catalunya
	"rome": [[41.8986, 12.4769]],                          # Pantheon
	"new_york": [[40.7549, -73.9840], [40.7075, -74.0113]],  # Midtown, Downtown
	"chicago": [[41.8819, -87.6278]],                      # the Loop
	"san_francisco": [[37.7936, -122.3965]],               # Financial District
	"tokyo": [[35.6812, 139.7671], [35.6896, 139.6995]],   # Marunouchi, Shinjuku
	"hong_kong": [[22.2830, 114.1585], [22.2980, 114.1720]],  # Central, Tsim Sha Tsui
	"singapore": [[1.2840, 103.8510]],                     # Raffles Place
}

## Named districts with a dominant sub-style: [city, era, lat, lon,
## radius_km, weight multiplier]. Soft — they only scale the era's
## weight in BuildingEra's last-resort seeded pick, never override a
## real cue (a tagged 1970 tower in the Marais stays modern).
const DISTRICTS := [
	["paris", "paris_faubourg", 48.8590, 2.3620, 0.9, 5.0],      # Le Marais
	["paris", "paris_faubourg", 48.8867, 2.3431, 0.6, 5.0],      # Montmartre
	["paris", "paris_modern", 48.8920, 2.2380, 0.9, 30.0],       # La Défense
	["paris", "paris_modern", 48.8270, 2.3650, 0.7, 8.0],        # Olympiades
	["paris", "paris_modern", 48.8480, 2.2830, 0.4, 8.0],        # Front de Seine
	["london", "london_stucco", 51.4975, -0.1560, 1.2, 8.0],     # Belgravia
	["london", "london_stucco", 51.4990, -0.1900, 1.5, 6.0],     # Kensington
	["london", "london_stucco", 51.5115, -0.2050, 0.9, 6.0],     # Notting Hill
	["london", "london_georgian", 51.5220, -0.1260, 1.1, 5.0],   # Bloomsbury
	["london", "london_modern", 51.5054, -0.0235, 1.0, 20.0],    # Canary Wharf
	["london", "london_modern", 51.5140, -0.0830, 0.8, 8.0],     # the City
	["amsterdam", "amsterdam", 52.3700, 4.8880, 1.4, 4.0],       # Grachtengordel
	["amsterdam", "amsterdam_school", 52.3530, 4.8960, 1.0, 6.0],  # De Pijp
	["amsterdam", "amsterdam_school", 52.3480, 4.9010, 0.9, 6.0],  # Rivierenbuurt
	["amsterdam", "amsterdam_school", 52.3890, 4.8800, 0.6, 6.0],  # Spaarndammerbuurt
	["amsterdam", "amsterdam_modern", 52.3380, 4.8730, 0.9, 20.0],  # Zuidas
	["berlin", "berlin_plattenbau", 52.5250, 13.4700, 2.2, 8.0],  # Lichtenberg
	["berlin", "berlin_plattenbau", 52.5200, 13.4150, 0.8, 5.0],  # Alexanderplatz
	["berlin", "berlin_plattenbau", 52.5450, 13.5650, 2.5, 20.0],  # Marzahn
	["berlin", "berlin_modern", 52.5096, 13.3760, 0.6, 20.0],    # Potsdamer Platz
	["barcelona", "barcelona_gothic", 41.3830, 2.1760, 0.9, 10.0],  # Ciutat Vella
	["barcelona", "barcelona_modern", 41.4040, 2.2050, 1.2, 10.0],  # 22@ / Diagonal Mar
	["rome", "rome_modern", 41.8320, 12.4680, 1.5, 10.0],        # EUR
	["new_york", "nyc_brownstone", 40.6760, -73.9780, 1.8, 8.0],  # Park Slope
	["new_york", "nyc_brownstone", 40.6960, -73.9950, 0.8, 8.0],  # Brooklyn Heights
	["new_york", "nyc_brownstone", 40.6840, -73.9420, 1.5, 8.0],  # Bed-Stuy
	["new_york", "nyc_brownstone", 40.8100, -73.9450, 1.4, 5.0],  # Harlem
	["new_york", "nyc_glass", 40.7549, -73.9840, 1.3, 6.0],      # Midtown
	["new_york", "nyc_glass", 40.7075, -74.0113, 0.9, 6.0],      # Downtown
	["chicago", "chicago_greystone", 41.9214, -87.6513, 2.0, 5.0],  # Lincoln Park
	["chicago", "chicago_tower", 41.8819, -87.6278, 1.3, 10.0],  # the Loop
	["san_francisco", "sf_victorian", 37.7700, -122.4350, 2.2, 6.0],  # Haight / Alamo Sq
	["san_francisco", "sf_victorian", 37.7600, -122.4150, 1.2, 4.0],  # Mission
	["san_francisco", "sf_tower", 37.7936, -122.3965, 1.0, 20.0],  # FiDi
	["tokyo", "tokyo_tower", 35.6896, 139.6995, 0.9, 20.0],      # Shinjuku
	["tokyo", "tokyo_tower", 35.6812, 139.7671, 0.8, 20.0],      # Marunouchi
	["tokyo", "tokyo_tower", 35.6605, 139.7292, 0.5, 10.0],      # Roppongi
	["hong_kong", "hk_tenement", 22.3300, 114.1620, 1.2, 6.0],   # Sham Shui Po
	["hong_kong", "hk_tenement", 22.3190, 114.1700, 0.8, 4.0],   # Mong Kok
	["hong_kong", "hk_office", 22.2830, 114.1585, 0.8, 20.0],    # Central
	["singapore", "sg_shophouse", 1.2830, 103.8440, 0.7, 20.0],  # Chinatown
	["singapore", "sg_shophouse", 1.3020, 103.8590, 0.5, 20.0],  # Kampong Glam
	["singapore", "sg_shophouse", 1.3066, 103.8518, 0.6, 20.0],  # Little India
	["singapore", "sg_shophouse", 1.3120, 103.9010, 0.8, 10.0],  # Joo Chiat
	["singapore", "sg_tower", 1.2840, 103.8510, 1.0, 20.0],      # CBD
]

## The zone row containing (lat, lon), or [] outside every city.
static func zone_at(lat: float, lon: float) -> Array:
	for z in ZONES:
		var row: Array = z
		if _km(lat, lon, float(row[2]), float(row[3])) <= float(row[4]):
			return row
	return []

## City region for a viewpoint ("" outside every zone).
static func region_at(lat: float, lon: float) -> String:
	var z := zone_at(lat, lon)
	return "" if z.is_empty() else str(z[1])

## City key owning a region row ("haussmann" -> "paris"), "" if none.
static func city_of_region(region: String) -> String:
	for z in ZONES:
		if str((z as Array)[1]) == region:
			return str((z as Array)[0])
	return ""

## Per-build city frame for BuildingEra, in the local metre frame of a
## viewpoint (x east, z south, origin at the viewpoint — the frame the
## building dicts' x/z use): {"city", "cores": Array[Vector2],
## "districts": [[era, Vector2 centre, radius_m, mult], ...]}, or {}
## when the region is not a city's.
static func local_frame(region: String, lat: float, lon: float) -> Dictionary:
	var city := city_of_region(region)
	if city == "":
		return {}
	var cores: Array = []
	for c in (CORES.get(city, []) as Array):
		cores.append(WorldScale.xz_from_latlon(float(c[0]), float(c[1]), lat, lon))
	var districts: Array = []
	for d in DISTRICTS:
		var row: Array = d
		if str(row[0]) != city:
			continue
		var at := WorldScale.xz_from_latlon(float(row[2]), float(row[3]), lat, lon)
		# Only districts that can reach the detailed extent matter.
		if at.length() - float(row[4]) * 1000.0 > WorldScale.DETAILED_EXTENT_M * 2.0:
			continue
		districts.append([str(row[1]), at, float(row[4]) * 1000.0, float(row[5])])
	return {"city": city, "cores": cores, "districts": districts}

## Great-circle-ish distance in km (equirectangular; fine at city scale).
static func _km(lat_a: float, lon_a: float, lat_b: float, lon_b: float) -> float:
	var x := (lon_a - lon_b) * cos(deg_to_rad((lat_a + lat_b) * 0.5)) * 111.32
	var y := (lat_a - lat_b) * 110.54
	return sqrt(x * x + y * y)
