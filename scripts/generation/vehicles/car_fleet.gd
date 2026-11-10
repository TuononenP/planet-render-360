class_name CarFleet
extends RefCounted

## What parks on a street, by place: the mix of body kinds, the paint
## shares and the local taxi. A city's own row (CityStyles region) wins,
## then its country's fleet, then the default. Picks hash the kerb
## position, so a street always parks the same cars.
## * Fleets: North America runs to pickups and SUVs, Japan to light cars
##   and minivans in white and silver, the Nordics to estates and SUVs,
##   southern Europe to small hatchbacks, the rest of Europe between.
## * Taxis: a small share of slots. New York's are yellow, London's black
##   cabs, Lisbon's black under a green roof, Tokyo's dark saloons;
##   elsewhere an ordinary saloon under a roof sign.

const WHITE := Color(0.85, 0.85, 0.84)
const BLACK := Color(0.03, 0.03, 0.035)
const GREY := Color(0.3, 0.31, 0.32)
const SILVER := Color(0.55, 0.56, 0.57)
const RED := Color(0.2, 0.04, 0.04)
const BLUE := Color(0.04, 0.08, 0.2)
const BEIGE := Color(0.42, 0.4, 0.34)
const GREEN := Color(0.05, 0.12, 0.08)
const TAXI_YELLOW := Color(0.95, 0.62, 0.02)

## Roughly the world fleet's shares: white, black, grey and silver lead.
const PAINT := [WHITE, WHITE, WHITE, BLACK, BLACK, GREY, GREY, SILVER, SILVER, RED, BLUE, BEIGE]

const FLEETS := {
	"default": {"kinds": ["sedan", "sedan", "hatch", "hatch", "wagon", "suv", "compact_suv", "van"]},
	"north_america": {"kinds": ["sedan", "sedan", "suv", "suv", "compact_suv", "pickup", "pickup",
		"minivan", "hatch", "van"]},
	"japan": {"kinds": ["kei", "kei", "kei", "minivan", "minivan", "hatch", "sedan", "compact_suv"],
		"paint": [WHITE, WHITE, WHITE, WHITE, SILVER, SILVER, BLACK, BLACK, GREY, BLUE, BEIGE, RED]},
	"nordic": {"kinds": ["wagon", "wagon", "suv", "compact_suv", "compact_suv", "hatch", "sedan", "van"],
		"paint": [WHITE, WHITE, BLACK, BLACK, GREY, GREY, GREY, SILVER, SILVER, BLUE, RED, GREEN]},
	"south_europe": {"kinds": ["hatch", "hatch", "hatch", "compact_suv", "sedan", "wagon", "van", "suv"],
		"paint": [WHITE, WHITE, WHITE, WHITE, GREY, GREY, SILVER, SILVER, BLACK, RED, BLUE, BEIGE]},
	"europe": {"kinds": ["hatch", "hatch", "wagon", "compact_suv", "compact_suv", "sedan", "suv", "van"]},
}
const COUNTRY_FLEET := {
	"US": "north_america", "CA": "north_america", "MX": "north_america", "AU": "north_america",
	"JP": "japan",
	"FI": "nordic", "SE": "nordic", "NO": "nordic", "DK": "nordic", "IS": "nordic", "EE": "nordic",
	"PT": "south_europe", "ES": "south_europe", "IT": "south_europe", "GR": "south_europe",
	"MT": "south_europe", "HR": "south_europe", "TR": "south_europe",
	"GB": "europe", "IE": "europe", "FR": "europe", "DE": "europe", "NL": "europe", "BE": "europe",
	"AT": "europe", "CH": "europe", "PL": "europe", "CZ": "europe", "HU": "europe", "LU": "europe",
}
## Region fleets where the map data names no country.
const REGION_FLEET := {
	"new_york": "north_america", "chicago": "north_america", "san_francisco": "north_america",
	"banff": "north_america", "tokyo": "japan", "helsinki": "nordic", "espoo": "nordic",
	"stockholm": "nordic", "oslo": "nordic", "copenhagen": "nordic", "lisbon": "south_europe",
	"madrid": "south_europe", "barcelona": "south_europe", "rome": "south_europe", "milan": "south_europe",
	"florence": "south_europe", "athens": "south_europe", "london": "europe", "paris": "europe",
	"berlin": "europe", "amsterdam": "europe", "vienna": "europe", "brussels": "europe",
	"dublin": "europe", "edinburgh": "europe",
}
const TAXI_SHARE := 0.05
## kind, body colours, share of slots (default TAXI_SHARE).
const TAXIS := {
	"new_york": {"kind": "taxi", "paint": [TAXI_YELLOW], "share": 0.1},
	"london": {"kind": "cab_london", "paint": [BLACK, BLACK, BLACK, Color(0.12, 0.02, 0.03)]},
	"edinburgh": {"kind": "cab_london", "paint": [BLACK]},
	"lisbon": {"kind": "taxi_lisbon", "paint": [BLACK]},
	"tokyo": {"kind": "taxi", "paint": [BLACK, BLACK, Color(0.02, 0.05, 0.12), Color(0.05, 0.12, 0.08)]},
}

## The fleet at `data`'s place: {kinds, paint, taxi}.
static func profile(data: LocationData) -> Dictionary:
	return profile_for(CityStyles.region_at(data.latitude, data.longitude), data.country)

static func profile_for(region: String, country: String) -> Dictionary:
	var name: String = COUNTRY_FLEET.get(country.to_upper(), REGION_FLEET.get(region, "default"))
	var fleet: Dictionary = FLEETS[name]
	return {
		"kinds": fleet["kinds"],
		"paint": fleet.get("paint", PAINT),
		"taxi": TAXIS.get(region, {"kind": "taxi", "paint": []}),
	}

## The car in the slot at `p`: [kind, colour, CarPaint finish]. The
## finish is r metallic (0/1), g grime: most grey and coloured paints
## are metallic, few whites and blacks; cabs are solid.
static func pick(fleet: Dictionary, p: Vector2) -> Array:
	var taxi: Dictionary = fleet["taxi"]
	var kinds: Array = fleet["kinds"]
	var paints: Array = fleet["paint"]
	var is_taxi := ParkedCars._hash(p.x, p.y, 9.1) < float(taxi.get("share", TAXI_SHARE))
	var kind: String = taxi["kind"] if is_taxi else kinds[int(ParkedCars._hash(p.x, p.y, 2.7) * kinds.size()) % kinds.size()]
	var cab_paint: Array = taxi["paint"]
	if is_taxi and not cab_paint.is_empty():
		paints = cab_paint
	var colour: Color = paints[int(ParkedCars._hash(p.x, p.y, 4.9) * paints.size()) % paints.size()]
	var solid_shade := colour.v > 0.8 or colour.v < 0.05
	var share := 0.0 if is_taxi else (0.25 if solid_shade else 0.85)
	var metallic := 1.0 if ParkedCars._hash(p.x, p.y, 5.3) < share else 0.0
	return [kind, colour, Color(metallic, 0.2 + 0.65 * ParkedCars._hash(p.x, p.y, 8.2), 0.0, 0.0)]
