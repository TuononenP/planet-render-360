class_name SolarPosition
extends RefCounted

## True solar position (T6.2): the NOAA solar-calculator equations
## (Meeus-derived; ~0.01° against an ephemeris for 1950-2050).
## Geometric position, no refraction. Elevation is degrees above the
## horizon, azimuth degrees clockwise from true north, hour angle degrees
## (negative before solar noon). All times are UTC; a utc_hour outside
## 0-24 rolls into the neighbouring day.

## Julian day of `date` ({year, month, day}) at `utc_hour`.
static func julian_day(date: Dictionary, utc_hour: float) -> float:
	var unix := Time.get_unix_time_from_datetime_dict({
		"year": int(date.get("year", 2026)), "month": int(date.get("month", 1)),
		"day": int(date.get("day", 1)), "hour": 0, "minute": 0, "second": 0})
	return float(unix) / 86400.0 + 2440587.5 + utc_hour / 24.0

static func compute(lat: float, lon: float, date: Dictionary, utc_hour: float) -> Dictionary:
	var t := (julian_day(date, utc_hour) - 2451545.0) / 36525.0
	var l0 := fposmod(280.46646 + t * (36000.76983 + t * 0.0003032), 360.0)
	var m := 357.52911 + t * (35999.05029 - 0.0001537 * t)
	var e := 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
	var c := sin(deg_to_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) \
		+ sin(deg_to_rad(2.0 * m)) * (0.019993 - 0.000101 * t) \
		+ sin(deg_to_rad(3.0 * m)) * 0.000289
	var omega := deg_to_rad(125.04 - 1934.136 * t)
	var lam := deg_to_rad(l0 + c - 0.00569 - 0.00478 * sin(omega))
	var eps0 := 23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
	var eps := deg_to_rad(eps0 + 0.00256 * cos(omega))
	var decl := asin(sin(eps) * sin(lam))
	var y := pow(tan(eps / 2.0), 2.0)
	var l0r := deg_to_rad(l0)
	var mr := deg_to_rad(m)
	var eq_time := 4.0 * rad_to_deg(y * sin(2.0 * l0r) - 2.0 * e * sin(mr)
		+ 4.0 * e * y * sin(mr) * cos(2.0 * l0r) - 0.5 * y * y * sin(4.0 * l0r)
		- 1.25 * e * e * sin(2.0 * mr))
	var ha_deg := fposmod(utc_hour * 15.0 + eq_time / 4.0 + lon, 360.0) - 180.0
	var ha := deg_to_rad(ha_deg)
	# Poles: keep cos(lat) off zero so the azimuth stays defined.
	var la := deg_to_rad(clampf(lat, -89.99, 89.99))
	var cos_z := clampf(sin(la) * sin(decl) + cos(la) * cos(decl) * cos(ha), -1.0, 1.0)
	var az := rad_to_deg(atan2(sin(ha), cos(ha) * sin(la) - tan(decl) * cos(la))) + 180.0
	return {
		"elevation": 90.0 - rad_to_deg(acos(cos_z)),
		"azimuth": fposmod(az, 360.0),
		"hour_angle": ha_deg,
		"declination": rad_to_deg(decl),
	}

## Low-precision Moon (Astronomical Almanac series, ~1°; no parallax):
## elevation / azimuth as in compute(), `phase` 0 new -> 0.5 full -> 1
## and `illum`, the lit fraction of the disc.
static func moon(lat: float, lon: float, date: Dictionary, utc_hour: float) -> Dictionary:
	var d := julian_day(date, utc_hour) - 2451545.0
	var lam := deg_to_rad(218.316 + 13.176396 * d + 6.289 * sin(deg_to_rad(134.963 + 13.064993 * d)))
	var beta := deg_to_rad(5.128 * sin(deg_to_rad(93.272 + 13.229350 * d)))
	var g := deg_to_rad(357.529 + 0.98560028 * d)
	var lam_sun := deg_to_rad(280.459 + 0.98564736 * d + 1.915 * sin(g) + 0.020 * sin(2.0 * g))
	var eps := deg_to_rad(23.439 - 0.0000004 * d)
	var ra := atan2(cos(eps) * sin(lam) - tan(beta) * sin(eps), cos(lam))
	var decl := asin(sin(beta) * cos(eps) + cos(beta) * sin(eps) * sin(lam))
	var ha := deg_to_rad(fposmod(280.46061837 + 360.98564736629 * d + lon - rad_to_deg(ra), 360.0))
	var la := deg_to_rad(clampf(lat, -89.99, 89.99))
	var sin_el := clampf(sin(la) * sin(decl) + cos(la) * cos(decl) * cos(ha), -1.0, 1.0)
	var az := rad_to_deg(atan2(sin(ha), cos(ha) * sin(la) - tan(decl) * cos(la))) + 180.0
	var elong := cos(beta) * cos(lam - lam_sun)
	return {
		"elevation": rad_to_deg(asin(sin_el)),
		"azimuth": fposmod(az, 360.0),
		"phase": fposmod(rad_to_deg(lam - lam_sun), 360.0) / 360.0,
		"illum": (1.0 - elong) * 0.5,
	}

## World-space unit vector toward the sun (x east, y up, z south — the
## WorldScale frame, where north is -Z).
static func direction(elevation: float, azimuth: float) -> Vector3:
	var el := deg_to_rad(elevation)
	var az := deg_to_rad(azimuth)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
