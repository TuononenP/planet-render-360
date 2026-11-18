class_name StreamLattice
extends RefCounted

## The fixed points streamed centres sit on. A stretch built around an
## arbitrary point asked every centre-keyed cache (map data, city
## registers, the 1 m ground, orthophotos, land cover) for a place nobody
## had fetched before; on the lattice the same centres come up again, on
## the way back and in the next session, and StreamScout's fetches ahead
## are for the very centre built later. Rows are whole LAT_MDEG
## thousandths of a degree (~445 m), columns the whole thousandths
## nearest that pitch at the row's latitude, so CacheStore.quant of a
## lattice point is exact.

const LAT_MDEG := 4

## The lattice point nearest `ll` (lat, lon). `cells` widens the pitch
## (a coarser lattice whose points are lattice points too).
static func snap(ll: Vector2, cells := 1) -> Vector2:
	var lat_step := LAT_MDEG * cells
	var lat_i := roundi(ll.x * 1000.0 / lat_step) * lat_step
	var shrink := maxf(cos(deg_to_rad(lat_i / 1000.0)), 0.01)
	var lon_step := maxi(LAT_MDEG, roundi(LAT_MDEG / shrink)) * cells
	var lon_i := roundi(ll.y * 1000.0 / lon_step) * lon_step
	return Vector2(lat_i / 1000.0, lon_i / 1000.0)
