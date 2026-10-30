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

## World-space unit vector toward the sun (x east, y up, z south — the
## WorldScale frame, where north is -Z).
static func direction(elevation: float, azimuth: float) -> Vector3:
	var el := deg_to_rad(elevation)
	var az := deg_to_rad(azimuth)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
