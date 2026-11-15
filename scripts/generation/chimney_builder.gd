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
## Sides of the shaft (near, far). The far count stays under 10 so the
## lathe's Ultra doubling (LandmarkMesh.lathe) leaves it at its few sides.
const SEGMENTS := 20
const FAR_SEGMENTS := 9
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
	var area := absf(RingGeometry.signed_area(ring)) if ring.size() >= 3 \
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
	var tag := str(b.get("material", "")).strip_edges().to_lower()
	var brick := tag in ["bricks", "clinker"] or str(MaterialLibrary.MATERIAL_TAGS.get(tag, "")) == "brick"
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
	# The lathe caps both ends, so the band's top closes the stack.
	lm.frustum("Cap", Vector3(c.x, y + h - cap, c.y), r_cap + 0.08, r1, cap, segments)
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
	# The shaft has no plinth: it rises from the lowest ground, sunk as
	# walls are, so a slope or a raised floor leaves no gap under it.
	var foot := float(footing["low"]) - BuildingFoundation.SINK_M * WorldScale.metres_to_units()
	for part in mesh(b, foot).commit(root, "Chimney_"):
		part.set_meta("mapped_chimney", true)
		part.set_meta("osm_id", str(b.get("osm_id", "")))
	return true

## Appends the far city's shaft (fewer sides) to `batch` under `key`.
static func append_far(batch: MassBatch, key: String, b: Dictionary, base_y: float) -> void:
	mesh(b, base_y, FAR_SEGMENTS).append_to_batch(batch, key)
