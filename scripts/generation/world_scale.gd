class_name WorldScale
extends RefCounted

## Single owner of unit conversions and the render origin (contract §1).
## v2: 1 internal unit = 1 metre end-to-end; axes +X = east, +Z = south
## (north = -Z), same handedness as v1 OsmFetcher.local_xz.
## Owner: B. Consumers: OsmFetcher, all builders, CameraRig, pipeline.
## Replaces OsmFetcher.WORLD_SCALE + TerrainBuilder.METRES_TO_WORLD /
## WORLD_SIZE (contract §7 V4–V7).

## Detailed (near-field) world extent in metres (contract §1.2). One
## extent on every preset (plan Open Q1, settled in T7.0/T7.1): presets
## differ only in LOD ring radii and density, never in layout (AC-12).
const DETAILED_EXTENT_M := 2400.0

## Metres→internal-units factor: identity (contract §1.1). The T1.2
## legacy_880m_equivalence flag (0.25, a 220-unit ≈ 880 m world) and its
## LEGACY_* constants were deleted at the metre cutover (T7.0); builders
## keep calling this so a model authored in metres stays explicit.
static func metres_to_units() -> float:
	return 1.0

## Detailed extent in internal units (= metres).
static func detailed_extent_units() -> float:
	return DETAILED_EXTENT_M

## Metre XZ of (lat, lon) relative to centre (c_lat, c_lon).
## Replaces OsmFetcher.local_xz (contract §1.3, §7 V4).
static func xz_from_latlon(lat: float, lon: float, c_lat: float, c_lon: float) -> Vector2:
	var east_m := (lon - c_lon) * 111320.0 * cos(deg_to_rad(c_lat))
	var north_m := (lat - c_lat) * 110540.0
	return Vector2(east_m, -north_m)

## Inverse of xz_from_latlon, for attribution/UV round-trips.
static func latlon_from_xz(x: float, z: float, c_lat: float, c_lon: float) -> Vector2:
	var north_m := -z
	var east_m := x
	return Vector2(c_lat + north_m / 110540.0,
		c_lon + east_m / (111320.0 * cos(deg_to_rad(c_lat))))

## Render-origin rebasing (contract §1.3): the pipeline sets the origin
## at the viewpoint once per place; builders emit metre geometry and the
## caller applies to_render, so the camera works near the float sweet
## spot. The local metre frame is already centre-relative, so only the
## Y datum (origin_elevation_m) shifts positions.
var origin_latitude := 0.0
var origin_longitude := 0.0
var origin_elevation_m := 0.0

func set_origin(lat: float, lon: float, elevation_m: float) -> void:
	origin_latitude = lat
	origin_longitude = lon
	origin_elevation_m = elevation_m

func to_render(metre_pos: Vector3) -> Vector3:
	return Vector3(metre_pos.x, metre_pos.y - origin_elevation_m, metre_pos.z)

## Ray-cast point-in-polygon test. Lives here (not on TerrainBuilder)
## because GroundTruth needs it and TerrainBuilder's signature names
## GroundTruth — the reverse reference was a cyclic dependency that
## broke compilation on the main-scene load order.
static func point_in_polygon(point: Vector2,
		polygon: PackedVector2Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in polygon.size():
		var pi := polygon[i]
		var pj := polygon[j]
		if (pi.y > point.y) != (pj.y > point.y) \
				and point.x < (pj.x - pi.x) * (point.y - pi.y) \
					/ (pj.y - pi.y) + pi.x:
			inside = not inside
		j = i
	return inside
