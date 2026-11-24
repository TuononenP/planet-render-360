class_name AircraftSpecs
extends RefCounted

## Real-scale aircraft dimensions, performance parameters, and regional
## airline / EMS helicopter livery palettes for AirportPlanes & AircraftModel.

const SPECS := {
	"wide": {
		"length_m": 58.8, "span_m": 60.3, "clear_m": 64.0, "shadow_l": 56.0, "shadow_w": 58.0,
		"taxi_ms": 8.0, "takeoff_ms": 78.0, "approach_ms": 72.0, "climb_ms": 115.0,
		"accel_ms2": 2.4, "brake_ms2": 2.6, "rotate_deg": 13.0,
	},
	"narrow": {
		"length_m": 37.6, "span_m": 35.8, "clear_m": 40.0, "shadow_l": 36.0, "shadow_w": 34.0,
		"taxi_ms": 7.5, "takeoff_ms": 70.0, "approach_ms": 65.0, "climb_ms": 105.0,
		"accel_ms2": 2.7, "brake_ms2": 2.9, "rotate_deg": 14.0,
	},
	"turboprop": {
		"length_m": 31.0, "span_m": 28.4, "clear_m": 32.0, "shadow_l": 29.0, "shadow_w": 27.0,
		"taxi_ms": 6.5, "takeoff_ms": 52.0, "approach_ms": 48.0, "climb_ms": 78.0,
		"accel_ms2": 2.3, "brake_ms2": 2.8, "rotate_deg": 11.0,
	},
	"light": {
		"length_m": 8.3, "span_m": 11.0, "clear_m": 15.0, "shadow_l": 8.5, "shadow_w": 11.0,
		"taxi_ms": 4.5, "takeoff_ms": 34.0, "approach_ms": 30.0, "climb_ms": 46.0,
		"accel_ms2": 2.1, "brake_ms2": 3.0, "rotate_deg": 10.0,
	},
	"helicopter": {
		"length_m": 12.2, "span_m": 10.4, "clear_m": 15.0, "shadow_l": 11.5, "shadow_w": 10.5,
		"cruise_ms": 42.0, "climb_ms": 6.5,
	},
}

## Regional airline palettes: [id, body, belly, tail, accent, engine].
const REGIONAL_LIVERIES := {
	"nordic": [
		["nordic_blue",   "#F4F6F8", "#D2D7DC", "#0B245B", "#0B245B", "#ECEFF2"],
		["nordic_navy",   "#F2F4F6", "#C8CFD6", "#102C68", "#D62828", "#E6E9ED"],
		["nordic_red",    "#F4F5F6", "#D4D8DC", "#C8102E", "#C8102E", "#ECEFF2"],
		["nordic_gold",   "#F3F4F5", "#CFD5DC", "#0A3A75", "#F2A900", "#E8ECEF"],
	],
	"west_eu": [
		["eu_navy",       "#F4F5F7", "#CCD2D9", "#0D234A", "#C8102E", "#EAECEF"],
		["eu_sky",        "#F3F6F8", "#D0D7DE", "#0072B8", "#00A1DE", "#E6ECF2"],
		["eu_crimson",    "#F4F5F6", "#CFD4DA", "#B81D24", "#182B54", "#ECEEF0"],
		["eu_orange",     "#F5F5F5", "#D4D7DB", "#FF6600", "#FF6600", "#F0F1F3"],
		["eu_gold",       "#F4F5F6", "#CFD4DA", "#0B2552", "#F5B800", "#ECEEF0"],
		["eu_emerald",    "#F3F5F4", "#CFD6D2", "#007A4D", "#007A4D", "#E8ECEA"],
	],
	"north_am": [
		["na_navy",       "#F2F4F6", "#C6CDD5", "#0E2B5C", "#C8102E", "#E6EAEE"],
		["na_blue",       "#F4F6F8", "#CBD2DA", "#005DAA", "#003B73", "#EAECEF"],
		["na_crimson",    "#F3F4F6", "#C8CFD6", "#B3192C", "#13294B", "#E8ECEF"],
		["na_teal",       "#F4F6F7", "#CED5DB", "#006A78", "#E03A3E", "#EAECEF"],
		["na_gold",       "#F2F4F7", "#C9D0D8", "#1C3F94", "#F4B41A", "#E6EAEE"],
	],
	"east_asia": [
		["ea_cobalt",     "#F4F6F8", "#CFD5DC", "#0A2E73", "#0072CE", "#EAECEF"],
		["ea_red",        "#F5F5F5", "#D4D7DB", "#CC0018", "#CC0018", "#ECEEF0"],
		["ea_sky",        "#EBF4FA", "#C4D9E8", "#0082C8", "#D2232A", "#E2EEF6"],
		["ea_plum",       "#F4F5F7", "#D0D5DC", "#6E2585", "#D4A017", "#EAECEF"],
	],
	"se_asia": [
		["sea_navy_gold", "#F4F5F7", "#CFD5DC", "#13294B", "#F2A900", "#EAECEF"],
		["sea_purple",    "#F4F5F7", "#D0D5DC", "#5C246E", "#E1A100", "#EAECEF"],
		["sea_red",       "#F5F4F4", "#D4D6DA", "#D41A23", "#D41A23", "#ECEEF0"],
		["sea_teal",      "#F3F6F6", "#CDD6D6", "#006B68", "#006B68", "#E8EEEE"],
	],
	"middle_east": [
		["me_crimson",    "#F4F4F2", "#D2D3D0", "#C8102E", "#C69C6D", "#ECECE9"],
		["me_burgundy",   "#F3F3F2", "#CFCFD0", "#5C0931", "#5C0931", "#EAEAE8"],
		["me_gold",       "#F4F3EE", "#D5D0C5", "#9E7A38", "#1F355E", "#ECEAE3"],
	],
	"oceania": [
		["oc_red",        "#F4F5F6", "#D2D6DA", "#D51C24", "#D51C24", "#ECEEF0"],
		["oc_teal",       "#F4F6F7", "#CDD5DA", "#007A87", "#1B2A38", "#EAECEF"],
		["oc_black",      "#F3F4F6", "#C8CDD3", "#1A1D21", "#008080", "#E6E8EB"],
	],
	"south_am": [
		["sa_sky",        "#F4F6F8", "#CFD6DD", "#008ED6", "#008ED6", "#EAECEF"],
		["sa_indigo",     "#F4F5F7", "#CDD2DA", "#1B2868", "#E21B4D", "#EAECEF"],
		["sa_gold",       "#F4F5F6", "#D0D5DA", "#003B70", "#F2B705", "#EAECEF"],
	],
	"africa": [
		["af_green",      "#F4F5F4", "#CFD5D0", "#007A4D", "#F2A900", "#EAECE9"],
		["af_red",        "#F4F5F6", "#D0D4D8", "#B81D24", "#006847", "#ECEEF0"],
		["af_blue",       "#F4F6F7", "#CED4DB", "#0E3C75", "#D62828", "#EAECEF"],
	],
}

const HELI_EMS := [
	["heli_ems_yellow", "#F2C314", "#D41A23", "#D41A23", "#D41A23", "#2A2E33"],
	["heli_ems_white",  "#F4F5F6", "#C8102E", "#C8102E", "#C8102E", "#2A2E33"],
]

const HELI_CIVIL := [
	["heli_navy",       "#F2F4F6", "#18335B", "#18335B", "#C69C6D", "#2A2E33"],
	["heli_charcoal",   "#343A42", "#1F242A", "#252B33", "#D69E2E", "#22262B"],
	["heli_white_red",  "#F4F5F6", "#B81D24", "#B81D24", "#1F2937", "#2A2E33"],
	["heli_rescue_org", "#F4F5F6", "#E05A1E", "#E05A1E", "#12345B", "#2A2E33"],
]

static func spec(kind: String) -> Dictionary:
	return SPECS.get(kind, SPECS["narrow"])

static func length_m(kind: String) -> float:
	return float(spec(kind)["length_m"])

static func span_m(kind: String) -> float:
	return float(spec(kind)["span_m"])

static func clear_m(kind: String) -> float:
	return float(spec(kind)["clear_m"])

static func region_palette(country: String, region: String) -> String:
	var cc := country.to_upper()
	if cc in ["FI", "SE", "NO", "DK", "IS", "EE", "LV", "LT"]:
		return "nordic"
	if cc in ["US", "CA", "MX"]:
		return "north_am"
	if cc in ["JP", "KR", "CN", "TW", "HK", "MO"]:
		return "east_asia"
	if cc in ["SG", "TH", "MY", "ID", "VN", "PH", "KH", "LA", "MM"]:
		return "se_asia"
	if cc in ["AE", "QA", "SA", "OM", "KW", "BH", "IL", "JO", "TR", "EG"]:
		return "middle_east"
	if cc in ["AU", "NZ", "FJ"]:
		return "oceania"
	if cc in ["BR", "AR", "CL", "CO", "PE", "EC", "UY", "VE"]:
		return "south_am"
	if cc in ["ZA", "KE", "ET", "MA", "NG", "GH", "TZ", "MZ"]:
		return "africa"
	if region.contains("nordic"):
		return "nordic"
	if region.contains("asia"):
		return "east_asia"
	return "west_eu"

## Picks a deterministic livery dictionary for `kind` at a given place & hash [0, 1).
static func pick_livery(kind: String, country: String, region: String, h_val: float,
		emergency: bool = false) -> Dictionary:
	if kind == "helicopter":
		var pool: Array = HELI_EMS if emergency else HELI_CIVIL
		var row: Array = pool[clampi(int(floor(h_val * float(pool.size()))), 0, pool.size() - 1)]
		return _dict(row)
	if kind == "light":
		var ga := [
			["ga_red",   "#F4F4F2", "#B81D24", "#B81D24", "#B81D24", "#30343A"],
			["ga_blue",  "#F4F5F6", "#164A8A", "#164A8A", "#164A8A", "#30343A"],
			["ga_gold",  "#F4F3EE", "#C98A1B", "#C98A1B", "#C98A1B", "#30343A"],
			["ga_green", "#F4F5F4", "#1B6B44", "#1B6B44", "#1B6B44", "#30343A"],
		]
		var row: Array = ga[clampi(int(floor(h_val * float(ga.size()))), 0, ga.size() - 1)]
		return _dict(row)
	var pal_key := region_palette(country, region)
	var pal: Array = REGIONAL_LIVERIES.get(pal_key, REGIONAL_LIVERIES["west_eu"])
	var idx := clampi(int(floor(h_val * float(pal.size()))), 0, pal.size() - 1)
	return _dict(pal[idx])

## Livery dictionary from a single tail hex (for LandmarkAircraft compatibility).
static func livery_from_tail(tail_hex: String) -> Dictionary:
	return {
		"id": "tail_" + tail_hex.trim_prefix("#"),
		"body": "#F3F5F7",
		"belly": "#CFD5DC",
		"tail": tail_hex,
		"accent": tail_hex,
		"engine": "#EAECEF",
	}

## Picks a fixed-wing aircraft class for an airport tier ("hub", "regional", "ga").
static func pick_fixed_wing_kind(airport_class: String, h_val: float) -> String:
	match airport_class:
		"hub":
			if h_val < 0.28:
				return "wide"
			if h_val < 0.88:
				return "narrow"
			return "turboprop"
		"regional":
			if h_val < 0.58:
				return "narrow"
			if h_val < 0.90:
				return "turboprop"
			return "light"
		_:
			return "turboprop" if h_val < 0.20 else "light"

static func _dict(row: Array) -> Dictionary:
	return {
		"id": str(row[0]),
		"body": str(row[1]),
		"belly": str(row[2]),
		"tail": str(row[3]),
		"accent": str(row[4]),
		"engine": str(row[5]),
	}
