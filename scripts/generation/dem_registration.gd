class_name DemRegistration
extends RefCounted

## Geodetic DEM resample for GroundTruth (scorecard (a) finding,
## 2026-10-29). The T3.1 remap scaled post indices by extent/window,
## which left two registration errors that grow with distance from the
## viewpoint: GroundTruth posts are extent/(size−1) apart while the
## heights grid is window/size, and WorldScale's metres per degree of
## latitude (110 540) differ from the tiles' Web-Mercator pixel size by
## ~0.7% at mid latitudes. Together the terrain sat ~1% compressed
## toward the centre (≈8 m on an Interlaken slope 800 m out). Each post
## is now sampled at its own position: the post's WorldScale lat/lon
## (the transform OSM features use, so terrain and buildings register by
## construction) → Web-Mercator pixel at the source zoom → heights-grid
## index relative to the viewpoint pixel DemFetcher centred its window on.

## Whether the heights grid came from a real fetch window this class can
## invert (z14 mosaic or the z12 fallback tile).
static func applies(data: LocationData) -> bool:
	var zoom := int(data.dem_source.get("source_zoom", 0))
	return zoom == DemFetcher.ZOOM_NEAR or zoom == DemFetcher.ZOOM_MID

## Fractional heights-grid index for surface post (x, z) of a `size`
## grid whose posts are `step_m` metres apart, post size/2 at the
## viewpoint. GroundTruth does the read (the one ground-truth reader).
static func grid_index(data: LocationData, size: int, step_m: float,
		x: int, z: int) -> Vector2:
	var zoom := int(data.dem_source.get("source_zoom", 0))
	var window_px := DemFetcher.WINDOW_NEAR_PX if zoom == DemFetcher.ZOOM_NEAR else 144.0
	var grid := data.grid_size
	var step_px := window_px / float(maxi(grid, 1))
	var ll := WorldScale.latlon_from_xz((float(x) - float(size) * 0.5) * step_m,
		(float(z) - float(size) * 0.5) * step_m, data.latitude, data.longitude)
	var d := _px(ll.x, ll.y, zoom) - _px(data.latitude, data.longitude, zoom)
	# DemFetcher.sample_bilinear reads pixel floor(f) at integer f, i.e.
	# the value centred half a pixel further on; undo that here.
	return Vector2(float(grid) * 0.5 + (d.x - 0.5) / step_px,
		float(grid) * 0.5 + (d.y - 0.5) / step_px)

## Global Web-Mercator pixel of lat/lon at `zoom` (256 px tiles).
static func _px(lat: float, lon: float, zoom: int) -> Vector2:
	var n := float(1 << zoom) * 256.0
	return Vector2((lon + 180.0) / 360.0 * n,
		(1.0 - asinh(tan(deg_to_rad(lat))) / PI) / 2.0 * n)
