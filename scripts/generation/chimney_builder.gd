class_name ChimneyBuilder
extends RefCounted

## A mapped chimney stack (OsmTags.is_chimney: man_made=chimney or
## building=chimney) as a round, slightly tapered shaft with a dark cap
## band: no facade, no windows, no roof. The OSM footprint only gives the
## base: its area-equivalent radius, so a square-mapped stack keeps its
## girth. Brick when mapped so, otherwise concrete; `building:colour`
## tints it. The near city builds it per building, the far city appends
## the same shaft to its batch.

## Top radius as a share of the base radius.
const TAPER := 0.72
## Height of the dark cap band at the top (m).
const CAP_M := 3.0
## Sides of the shaft (near, far).
const SEGMENTS := 20
const FAR_SEGMENTS := 10
## Radius bounds (m): a footprint mapped as a whole boiler house still
## stands a believable stack, a sliver still reads.
const MIN_RADIUS_M := 1.0
const MAX_RADIUS_M := 12.0
const BRICK_HEX := "#8A4B3A"
const CONCRETE_HEX := "#BDB8AE"
const CAP_HEX := "#3A3B3C"

static func accepts(b: Dictionary) -> bool:
	return bool(b.get("chimney", false))

## {centre: Vector2, r0, r1, height} in world units, from the footprint.
static func shape(b: Dictionary) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	var centre := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	var area := _area(ring) if ring.size() >= 3 \
		else float(b.get("size_x", 6.0)) * float(b.get("size_z", 6.0))
	var r0 := clampf(sqrt(area / PI) / m, MIN_RADIUS_M, MAX_RADIUS_M) * m
	return {"centre": centre, "r0": r0, "r1": r0 * TAPER,
		"height": maxf(float(b.get("height", 0.0)), CAP_M * 2.0) * m}

## The shaft as a LandmarkMesh with its foot at (centre.x, y, centre.y).
static func mesh(b: Dictionary, y: float, segments: int = SEGMENTS) -> LandmarkMesh:
	var s := shape(b)
	var c: Vector2 = s["centre"]
	var r0: float = s["r0"]
	var r1: float = s["r1"]
	var h: float = s["height"]
	var cap := CAP_M * WorldScale.metres_to_units()
	var brick := str(b.get("material", "")).strip_edges().to_lower() in ["brick", "bricks", "clinker"]
	var hex := BRICK_HEX if brick else CONCRETE_HEX
	var tint := MaterialLibrary.parse_colour_tag(str(b.get("colour", "")))
	if tint.a > 0.0:
		hex = "#" + tint.to_html(false)
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("brick" if brick else "concrete", hex, 3.0))
	lm.use("Cap", LandmarkMaterials.paint(CAP_HEX, 0.7))
	# The cap band follows the taper, so the shaft runs to h - cap at the
	# radius it would have there.
	var r_cap := lerpf(r0, r1, (h - cap) / h)
	lm.frustum("Shaft", Vector3(c.x, y, c.y), r0, r_cap, h - cap, segments)
	lm.frustum("Cap", Vector3(c.x, y + h - cap, c.y), r_cap + 0.08, r1, cap, segments)
	lm.disc("Cap", Vector3(c.x, y + h, c.y), Vector3.UP, r1, segments)
	return lm

## Builds `b` under `root` when it is a chimney; false otherwise.
static func build(root: Node3D, b: Dictionary, ground: GroundTruth, sea_y: float = -INF) -> bool:
	if not accepts(b):
		return false
	var s := shape(b)
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if ring.size() < 3:
		ring = BuildingWalls._rect_ring(s["centre"], Vector2(s["r0"], s["r0"]) * 2.0, 0.0)
	var footing := BuildingFoundation.sample(ground, ring, s["centre"], sea_y)
	for part in mesh(b, float(footing["floor"])).commit(root, "Chimney_"):
		part.set_meta("mapped_chimney", true)
		part.set_meta("osm_id", str(b.get("osm_id", "")))
	return true

## Appends the far city's shaft (fewer sides) to `batch` under `key`.
static func append_far(batch: MassBatch, key: String, b: Dictionary, base_y: float) -> void:
	mesh(b, base_y, FAR_SEGMENTS).append_to_batch(batch, key)

static func _area(ring: PackedVector2Array) -> float:
	var a := 0.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		a += p.x * q.y - q.x * p.y
	return absf(a) * 0.5
