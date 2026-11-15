class_name MapSources
extends RefCounted

## Which live OSM services the detailed map data comes from, and in what
## order. Postpass answers first by default: a live probe (2026-11-15, the
## app's own 1200 m query in Helsinki, New York and Tokyo) had it answer in
## about 2 s where Overpass took 45-58 s (32-34 s to the first byte) and
## then refused with 502 under load. Overpass stays as the next source and
## can be put first again without an app update (RemoteConfig
## `map_source_first`), and on iOS and Android it is off unless
## RemoteConfig `overpass_on_mobile` turns it on.

const POSTPASS := "postpass"
const OVERPASS := "overpass"
## The source asked first for the detailed layer: POSTPASS or OVERPASS.
const FIRST := POSTPASS

## Overpass endpoints. Each live query uses one instance, the first that
## is not paused (OverpassRequest.max_attempts): a failure goes straight
## to the next source instead of waiting on mirrors that rarely answer.
## private.coffee is only reached while the main instance is paused and a
## caller allows a second instance (the offline pack).
## Only full-planet instances belong here — regional ones (osm.ch,
## maprva.org, ...) silently return zero buildings outside their extract.
## The OSM-FR instance refuses unlisted clients (HTTP 403, live probe
## 2026-11-04). A probe (2026-10-31, Helsinki 1200 m) had private.coffee
## answering nothing, not even a one-node query; on 2026-11-11 it still
## accepted connections but sent nothing for 40 s. z.overpass-api.de
## refuses connections since 2026-11-11 (port 443 and 80, live probe) and
## was removed.
## No Russian-operated instance belongs here (see HostPolicy); the
## Russian-hosted mirror that used to be listed was removed for that reason.
const OVERPASS_ENDPOINTS: Array[String] = [
	"https://overpass-api.de/api/interpreter",
	"https://overpass.private.coffee/api/interpreter",
]

## Whether the detailed layer asks Postpass before Overpass.
static func postpass_first() -> bool:
	return str(RemoteConfig.value("map_source_first", FIRST)) == POSTPASS

## Whether this device may ask Overpass at all: not on iOS and Android,
## where waiting on it held up the stretches loaded ahead, unless the
## remote config allows it.
static func overpass_allowed() -> bool:
	return not OS.has_feature("mobile") or bool(RemoteConfig.value("overpass_on_mobile", false))

## The Overpass instances in use: OVERPASS_ENDPOINTS unless RemoteConfig
## replaces them, and none where Overpass is not allowed. With none, every
## query goes straight to its fallback and no status check runs.
static func overpass_endpoints() -> Array[String]:
	if not overpass_allowed():
		var none: Array[String] = []
		return none
	return RemoteConfig.value("overpass_endpoints", OVERPASS_ENDPOINTS)
