class_name LandmarkRoofs
extends RefCounted

## Registry landmark roofs under mapped ways. An elevated way mapped
## across a bespoke landmark (a rooftop park bridge, a station
## concourse) lands on its roof, not on the generic layer x 5 m
## viaduct clearance in RoadBuilder.deck_profile.

## [centre, entry, height_m] for every typed registry candidate and
## the primary landmark site of `data`. A skyscraper or a bridge carries no
## mapped way on its "roof": a ramp or viaduct beside or through a tower's
## base (the Park Avenue Viaduct round the MetLife Building), or under a
## bridge (the FDR Drive under the Brooklyn Bridge, whose height_m is its
## towers' and whose clearance runs its whole span), stays on its own deck
## instead of rising to the landmark's top. A bridge's own deck replaces
## its mapped one (LandmarkSites.outside_spans). A clock tower's height is
## its spire: Big Ben's clearance covers the Palace of Westminster, and a
## mapped footbridge by Old Palace Yard rose 96 m into the sky.
const NOT_ROOFS := ["Skyscraper", "Bridge", "Clock tower", "Airport"]
static func collect(data: LocationData) -> Array:
	var out: Array = []
	for c: Variant in data.landmark_candidates:
		if c is Dictionary and (c as Dictionary).has("type") \
				and float((c as Dictionary).get("height", 0.0)) > 0.0:
			var cd := c as Dictionary
			if str(LocationData.entry_for_type(str(cd["type"])).get("kind", "")) in NOT_ROOFS:
				continue
			out.append([Vector2(float(cd.get("x", 0.0)), float(cd.get("z", 0.0))), cd,
				float(cd["height"])])
	if data.has_landmark_site and data.landmark_type != "none":
		var entry := LocationData.entry_for_type(data.landmark_type)
		if not entry.is_empty() and float(entry.get("height_m", 0.0)) > 0.0 \
				and not str(entry.get("kind", "")) in NOT_ROOFS:
			out.append([WorldScale.xz_from_latlon(data.landmark_lat, data.landmark_lon,
				data.latitude, data.longitude), entry, float(entry["height_m"])])
	return out

## Render Y of the highest collected roof covering `p` (its site's
## terrain, sampled through `height_at`, plus its registered height),
## or -INF where no bespoke landmark stands under the point.
static func roof_y(sites: Array, p: Vector2, height_at: Callable) -> float:
	var best := -INF
	for site in sites:
		var at: Vector2 = site[0]
		var entry: Dictionary = site[1]
		# A landmark with an explicit precinct rect only covers points inside
		# that rect — adding clear_m outside it lifted nearby footbridges up
		# to adjacent tall buildings (County Hall lifted St Thomas' walkways 45 m).
		var hit := LandmarkSites.rect_dist(p, at, entry) <= 0.0 if entry.has("clear_rect_m") \
			else LandmarkSites.span_dist(p, at, entry) < LandmarkSites.clear_m(entry)
		if hit:
			best = maxf(best, float(height_at.call(at.x, at.y)) + float(site[2]) * WorldScale.metres_to_units())
	return best
