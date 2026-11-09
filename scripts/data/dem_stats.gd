class_name DemStats
extends RefCounted

## Summary figures of a place's elevation grid.

## Valley floor around the viewpoint (m ASL): a low percentile of the ground,
## so one deep gully does not set it.
static func valley_asl_m(data: LocationData) -> float:
	if data.heights.is_empty():
		return data.centre_elevation_m
	var sorted := data.heights.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 20]
