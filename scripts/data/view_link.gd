class_name ViewLink
extends RefCounted

## A view as text: where the world is centred, where the camera stands
## and looks, and optionally the time, season and date. One state shape
## serves the shareable link ("Copy view link", pasted into search) and
## the camera History keeps per place, so both reopen the exact view.
##
## Link: pr360://view?lat=48.8622&lon=2.2887&h=6.0&b=142.0&p=4.0&z=1.0&t=1050&s=1&d=2026-06-21
##   lat, lon   world origin; el, eo the camera's ground position when it
##              is not the origin
##   h          eye height over the ground in metres
##   b, p       bearing (compass degrees) and pitch (+ looks up)
##   z          FOV zoom factor     t   minutes since local midnight
##   s          season index        d   picked date (omitted: the season's)
##
## State (what View360 reads from LocationData.view when "restore" is set):
##   lat, lon, eye_lat, eye_lon, eye_m, bearing, pitch, zoom, minutes,
##   season, date {year, month, day}. Only lat, lon, eye_m, bearing and
##   pitch are always present.

const SCHEME := "pr360://view"
## Eye offsets below this (metres) are the origin itself.
const EYE_SAME_M := 1.0
## The eye must stand on the built ground: within this of the origin
## (half the detailed extent, less a margin for the clearance look), as
## the curated preset eyes do. A link whose eye lies farther (a typo, a
## hand-edited link) opens at its origin rather than over unbuilt land.
const EYE_MAX_M := WorldScale.DETAILED_EXTENT_M * 0.5 - 100.0

static func looks_like_link(text: String) -> bool:
	return text.strip_edges().to_lower().begins_with(SCHEME)

## The link for `state`.
static func encode(state: Dictionary) -> String:
	var parts: Array[String] = [
		"lat=%.5f" % float(state["lat"]), "lon=%.5f" % float(state["lon"])]
	if state.has("eye_lat"):
		parts.append("el=%.5f" % float(state["eye_lat"]))
		parts.append("eo=%.5f" % float(state["eye_lon"]))
	parts.append("h=%.1f" % float(state.get("eye_m", 30.0)))
	parts.append("b=%.1f" % fposmod(float(state.get("bearing", 0.0)), 360.0))
	parts.append("p=%.1f" % float(state.get("pitch", 0.0)))
	if state.has("zoom"):
		parts.append("z=%.2f" % float(state["zoom"]))
	if state.has("minutes"):
		parts.append("t=%d" % roundi(fposmod(float(state["minutes"]), 1440.0)))
	if state.has("season"):
		parts.append("s=%d" % LocationData.clamp_season(int(state["season"])))
	if state.has("date"):
		var d: Dictionary = state["date"]
		parts.append("d=%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])])
	return SCHEME + "?" + "&".join(parts)

## The state a link carries, {} when `text` is not a usable link.
static func parse(text: String) -> Dictionary:
	var s := text.strip_edges()
	if not looks_like_link(s):
		return {}
	var q := s.find("?")
	if q < 0:
		return {}
	var kv := {}
	for part in s.substr(q + 1).split("&", false):
		var eq := part.find("=")
		if eq > 0:
			kv[part.substr(0, eq).to_lower()] = part.substr(eq + 1).strip_edges()
	if not (_num(kv, "lat") and _num(kv, "lon")):
		return {}
	var lat := float(kv["lat"])
	var lon := float(kv["lon"])
	if absf(lat) > 90.0 or absf(lon) > 180.0:
		return {}
	var out := {"lat": lat, "lon": lon,
		"eye_m": clampf(float(kv["h"]) if _num(kv, "h") else 30.0, 1.0, 400.0),
		"bearing": fposmod(float(kv["b"]) if _num(kv, "b") else 0.0, 360.0),
		"pitch": clampf(float(kv["p"]) if _num(kv, "p") else 0.0, -68.0, 68.0)}
	if _num(kv, "el") and _num(kv, "eo"):
		out["eye_lat"] = clampf(float(kv["el"]), -90.0, 90.0)
		out["eye_lon"] = clampf(float(kv["eo"]), -180.0, 180.0)
		_drop_far_eye(out)
	if _num(kv, "z"):
		out["zoom"] = clampf(float(kv["z"]), 0.7, 2.8)
	if _num(kv, "t"):
		out["minutes"] = fposmod(float(kv["t"]), 1440.0)
	if _num(kv, "s"):
		out["season"] = LocationData.clamp_season(int(float(kv["s"])))
	if kv.has("d"):
		var date := parse_date(str(kv["d"]))
		if not date.is_empty():
			out["date"] = date
	return out

## "2026-06-21" as {year, month, day}, {} when it is not a real date.
static func parse_date(text: String) -> Dictionary:
	var bits := text.split("-")
	if bits.size() != 3 or not (bits[0].is_valid_int() and bits[1].is_valid_int() and bits[2].is_valid_int()):
		return {}
	var y := bits[0].to_int()
	var m := bits[1].to_int()
	var d := bits[2].to_int()
	if y < 1900 or y > 2200 or m < 1 or m > 12 or d < 1 or d > days_in_month(y, m):
		return {}
	return {"year": y, "month": m, "day": d}

static func days_in_month(year: int, month: int) -> int:
	if month == 2:
		return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
	return 30 if month in [4, 6, 9, 11] else 31

## Removes an eye position that does not stand on the built ground.
static func _drop_far_eye(state: Dictionary) -> void:
	if not state.has("eye_lat"):
		return
	var xz := WorldScale.xz_from_latlon(float(state["eye_lat"]), float(state.get("eye_lon", 0.0)),
		float(state["lat"]), float(state["lon"]))
	if xz.length() > EYE_MAX_M:
		state.erase("eye_lat")
		state.erase("eye_lon")

static func _num(kv: Dictionary, key: String) -> bool:
	return kv.has(key) and str(kv[key]).is_valid_float()

## The camera state of a shown view: `rig` yaw/pitch/zoom/position over
## `ground`, the world centred on `data`. `eye_m` is height above ground.
## Time, season and date join when `with_conditions` (links, not History).
static func capture(data: LocationData, ground: GroundTruth, rig: CameraRig,
		with_conditions: bool = false, minutes: float = -1.0, date: Dictionary = {}) -> Dictionary:
	var state := {"lat": data.latitude, "lon": data.longitude,
		"eye_m": maxf(rig.position.y - LandmarkTerrain.floor_y(data, ground, Vector2(rig.position.x, rig.position.z)), 1.0),
		"bearing": fposmod(rad_to_deg(-rig.yaw), 360.0),
		"pitch": rad_to_deg(rig.pitch), "zoom": rig.zoom_factor}
	var eye := Vector2(rig.position.x, rig.position.z)
	if eye.length() > EYE_SAME_M:
		var ll := WorldScale.latlon_from_xz(eye.x, eye.y, data.latitude, data.longitude)
		state["eye_lat"] = ll.x
		state["eye_lon"] = ll.y
	if with_conditions:
		state["season"] = data.season
		if minutes >= 0.0:
			state["minutes"] = minutes
		if not date.is_empty():
			state["date"] = date
	return state

## The LocationData.view row that reopens `state` exactly: the eye where
## it stood, no clearance lift, no opening-pitch floor ("restore").
static func to_view(state: Dictionary) -> Dictionary:
	var v := {"id": "restore", "lat": float(state["lat"]), "lon": float(state["lon"]),
		"eye_m": float(state.get("eye_m", 30.0)), "bearing": float(state.get("bearing", 0.0)),
		"pitch": float(state.get("pitch", 0.0)), "clear": false, "restore": true}
	for key in ["eye_lat", "eye_lon", "zoom", "minutes", "season", "date"]:
		if state.has(key):
			v[key] = state[key]
	_drop_far_eye(v)
	return v

## Season (LocationData.Season) of a calendar date at `lat`: the
## meteorological seasons, six months on in the southern hemisphere.
static func season_for_date(date: Dictionary, lat: float) -> int:
	var m := int(date.get("month", 6))
	if lat < 0.0:
		m = (m + 5) % 12 + 1
	if m in [3, 4, 5]:
		return LocationData.Season.SPRING
	if m in [6, 7, 8]:
		return LocationData.Season.SUMMER
	if m in [9, 10, 11]:
		return LocationData.Season.AUTUMN
	return LocationData.Season.WINTER
