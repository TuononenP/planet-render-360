class_name CapitalContinents
extends RefCounted

## Which continent each quick pick belongs to, for the picker's shelf
## filter. Groups follow the UN geoscheme with the overseas territories
## placed by where they lie (Christmas and Cocos Islands with Oceania,
## South Georgia with South America), and Turkey and the Caucasus with Asia.

const FEATURED := "featured"
const EUROPE := "europe"
const ASIA := "asia"
const AFRICA := "africa"
const NORTH_AMERICA := "north_america"
const SOUTH_AMERICA := "south_america"
const OCEANIA := "oceania"

## Filter order and chip text; Featured is the curated opening shelf.
const FILTERS := [
	[FEATURED, "Featured"],
	[EUROPE, "Europe"],
	[ASIA, "Asia"],
	[AFRICA, "Africa"],
	[NORTH_AMERICA, "North America"],
	[SOUTH_AMERICA, "South America"],
	[OCEANIA, "Oceania"],
]

const COUNTRIES := {
	EUROPE: ["AD", "AL", "AT", "AX", "BA", "BE", "BG", "BY", "CH", "CY", "CZ", "DE", "DK",
		"EE", "ES", "FI", "FO", "FR", "GB", "GG", "GI", "GR", "HR", "HU", "IE", "IM", "IS",
		"IT", "JE", "LI", "LT", "LU", "LV", "MC", "MD", "ME", "MK", "MT", "NL", "NO", "PL",
		"PT", "RO", "RS", "RU", "SE", "SI", "SJ", "SK", "SM", "UA", "VA", "XK"],
	ASIA: ["AE", "AF", "AM", "AZ", "BD", "BH", "BN", "BT", "CN", "GE", "HK", "ID", "IL",
		"IN", "IO", "IQ", "IR", "JO", "JP", "KG", "KH", "KP", "KR", "KW", "KZ", "LA", "LB",
		"LK", "MM", "MN", "MO", "MV", "MY", "NP", "OM", "PH", "PK", "PS", "QA", "SA", "SG",
		"SY", "TH", "TJ", "TL", "TM", "TR", "TW", "UZ", "VN", "YE"],
	AFRICA: ["AO", "BF", "BI", "BJ", "BW", "CD", "CF", "CG", "CI", "CM", "CV", "DJ", "DZ",
		"EG", "EH", "ER", "ET", "GA", "GH", "GM", "GN", "GQ", "GW", "KE", "KM", "LR", "LS",
		"LY", "MA", "MG", "ML", "MR", "MU", "MW", "MZ", "NA", "NE", "NG", "RE", "RW", "SC",
		"SD", "SH", "SL", "SN", "SO", "SS", "ST", "SZ", "TD", "TF", "TG", "TN", "TZ", "UG",
		"YT", "ZA", "ZM", "ZW"],
	NORTH_AMERICA: ["AG", "AI", "AW", "BB", "BL", "BM", "BS", "BZ", "CA", "CR", "CU", "CW",
		"DM", "DO", "GD", "GL", "GP", "GT", "HN", "HT", "JM", "KN", "KY", "LC", "MF", "MQ",
		"MS", "MX", "NI", "PA", "PM", "PR", "SV", "SX", "TC", "TT", "US", "VC", "VG", "VI"],
	SOUTH_AMERICA: ["AR", "BO", "BR", "CL", "CO", "EC", "FK", "GF", "GS", "GY", "PE", "PY",
		"SR", "UY", "VE"],
	OCEANIA: ["AS", "AU", "CC", "CK", "CX", "FJ", "FM", "GU", "KI", "MH", "MP", "NC", "NF",
		"NR", "NU", "NZ", "PF", "PG", "PN", "PW", "SB", "TO", "TV", "VU", "WF", "WS"],
}

static var _by_country := {}
static var _by_name := {}

## Continent key of a country code, "" when unknown.
static func of_country(code: String) -> String:
	_ensure()
	return str(_by_country.get(code, ""))

## Continent key of a quick-pick place name: "Nairobi, Kenya" and "Banff,
## Canada" resolve through the country after the last comma; a one-word
## name (Monaco) is its own country.
static func of_place(place_name: String) -> String:
	_ensure()
	var country := place_name.get_slice(",", place_name.count(",")).strip_edges()
	return str(_by_name.get(country, ""))

## The filter chip text of a key ("north_america" -> "North America").
static func label_of(key: String) -> String:
	for filter in FILTERS:
		if filter[0] == key:
			return str(filter[1])
	return ""

static func _ensure() -> void:
	if not _by_country.is_empty():
		return
	for continent in COUNTRIES:
		for code in COUNTRIES[continent]:
			_by_country[code] = continent
	for row in CapitalCatalog.ROWS:
		var continent := str(_by_country.get(str(row[0]), ""))
		if continent != "":
			_by_name[str(row[2])] = continent
