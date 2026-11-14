class_name TowerTop
extends RefCounted

## What stands on a flat tower roof at skyline scale: a louvred mechanical
## penthouse sized to the tower, cooling blocks on it and, on the tallest, a
## mast. Skyline shape, so it stays out of the near LOD ring. Emits through
## the wall and roof helpers, so it batches with a distant tower.

const MIN_WALL_M := 60.0
const MAST_MIN_WALL_M := 200.0
const MAST_SHARE := 0.25

const SINK_M := 3.0

static func height_m(wall_m: float) -> float:
	return clampf(0.035 * wall_m, 4.5, 14.0)

## How far the tower's parapet rises above its wall top.
static func parapet_m(wall_m: float) -> float:
	return clampf(0.02 * wall_m, 0.85, 2.4)

## The penthouse as a ring inset to 35-60% of the roof, [] if none fits.
static func footprint(ring: PackedVector2Array, seed_v: float) -> PackedVector2Array:
	var share := 0.35 + 0.25 * ArchitectureStyle._h(seed_v, 81)
	var side := sqrt(absf(RingGeometry.signed_area(ring)))
	return BuildingMasses._inset_ring(ring, side * (1.0 - sqrt(share)) * 0.5)

## A roof `top` over `wall_m` metres of tower. False when none fits.
static func penthouse(root: Node3D, ring: PackedVector2Array, top: float, wall_m: float,
		seed_v: float, louvre: Material, roof: Material) -> bool:
	if wall_m < MIN_WALL_M:
		return false
	var box := footprint(ring, seed_v)
	if box.size() < 3:
		return false
	var idx := Geometry2D.triangulate_polygon(box)
	if idx.size() < 3:
		return false
	var m := WorldScale.metres_to_units()
	var y1 := top + height_m(wall_m) * m
	# Down past the sunk roof deck, so no gap shows under it.
	BuildingWalls._walls(root, box, top - SINK_M * m, y1, louvre, 1.0)
	BuildingWalls._roof_cap(root, box, idx, y1, roof)
	return true

## The penthouse, cooling blocks and any mast.
static func add(root: Node3D, ring: PackedVector2Array, top: float, wall_m: float,
		seed_v: float, louvre: Material, roof: Material) -> void:
	if not penthouse(root, ring, top, wall_m, seed_v, louvre, roof):
		return
	var m := WorldScale.metres_to_units()
	# The street-side parapet grows with the tower, above the near trim's.
	BuildingWalls._walls(root, ring, top, top + parapet_m(wall_m) * m, roof, 1.0)
	var box := footprint(ring, seed_v)
	var y1 := top + height_m(wall_m) * m
	var c := RingGeometry.centroid(box)
	var u := (box[1] - box[0]).normalized()
	var side := sqrt(absf(RingGeometry.signed_area(box)))
	var half := clampf(side * 0.12, 1.5, 4.5) * m
	for i in 2:
		var at := c + u * side * m * (0.22 if i == 0 else -0.22)
		var block := _rect(at, u, half, half * 0.7)
		BuildingWalls._walls(root, block, y1, y1 + 3.2 * m, louvre, 1.0)
		BuildingWalls._roof_cap(root, block, Geometry2D.triangulate_polygon(block), y1 + 3.2 * m, roof)
	if wall_m >= MAST_MIN_WALL_M and ArchitectureStyle._h(seed_v, 82) < MAST_SHARE:
		var mast_h := lerpf(6.0, 25.0, ArchitectureStyle._h(seed_v, 83)) * m
		BuildingWalls._walls(root, _rect(c, u, 0.45 * m, 0.45 * m), y1, y1 + mast_h, louvre, 1.0)

static func _rect(c: Vector2, u: Vector2, a: float, b: float) -> PackedVector2Array:
	var v := Vector2(-u.y, u.x)
	return PackedVector2Array([c - u * a - v * b, c + u * a - v * b, c + u * a + v * b, c - u * a + v * b])
