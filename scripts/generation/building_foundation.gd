class_name BuildingFoundation
extends RefCounted

## Accepted buildings near known water need dry floors and a visible
## foundation, rather than walls extruded out of the carved bed.
## Estimated freeboard clears the shader's 1.13 m swell plus surface lift.
## This is a fallback construction detail, not a surveyed floor elevation.
const FREEBOARD_M := 1.5
const DECK_M := 0.24
const POST_SPACING_M := 4.0
## Low pier relief can be DEM interpolation across its water boundary.
## A steep bank must not lift the whole waterfront building to its top.
const SLAB_RELIEF_M := 4.0

static func sample(ground: GroundTruth, ring: PackedVector2Array, centre: Vector2,
		sea_y: float = -INF) -> Dictionary:
	var low := ground.height_at_world(centre.x, centre.y)
	var high := low
	var water := maxf(sea_y, ground.water_level_at(centre.x, centre.y, -INF))
	for p in ring:
		var h := ground.height_at_world(p.x, p.y)
		low = minf(low, h)
		high = maxf(high, h)
		water = maxf(water, ground.water_level_at(p.x, p.y, -INF))
	var freeboard := FREEBOARD_M
	# Legacy sea grids retain a 1.3 m upward swell offset.
	if ground.shoreline == null or not ground.shoreline.ready:
		freeboard += 1.3
	var raised := is_finite(water) and low < water + freeboard * WorldScale.metres_to_units()
	var floor_y := water + freeboard * WorldScale.metres_to_units() if raised else low
	if raised and high - low <= SLAB_RELIEF_M * WorldScale.metres_to_units():
		floor_y = maxf(floor_y, high)
	return {"floor": floor_y,
		"water": water, "raised": raised}

static func build(root: Node3D, ring: PackedVector2Array, holes: Array,
		footing: Dictionary, building: Dictionary) -> void:
	if not bool(footing["raised"]):
		return
	var m := WorldScale.metres_to_units()
	var floor_y := float(footing["floor"])
	var water := float(footing["water"])
	var timber := str(building.get("kind", "")) in ["shrine", "temple", "boathouse", "roof"]
	var lm := LandmarkMesh.new()
	lm.use("Deck", MaterialLibrary.pbr_material("wood" if timber else "concrete",
		Color("#938268") if timber else Color("#8a8580"), 0.5))
	lm.use("Piles", MaterialLibrary.pbr_material("wood" if timber else "concrete",
		Color("#574c40") if timber else Color("#77736b"), 0.5))
	var outer := RoofGeometry.offset_ring(ring, 0.75 * m)
	var cap := RingGeometry.bridge_holes(outer, holes) if not holes.is_empty() else outer
	var indices := Geometry2D.triangulate_polygon(cap)
	if not holes.is_empty():
		indices = RingGeometry.drop_hole_triangles(cap, indices, holes)
	for i in range(0, indices.size(), 3):
		var a := cap[indices[i]]
		var b := cap[indices[i + 1]]
		var c := cap[indices[i + 2]]
		lm.tri("Deck", Vector3(a.x, floor_y, a.y), Vector3(b.x, floor_y, b.y),
			Vector3(c.x, floor_y, c.y), Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)
		lm.tri("Deck", Vector3(a.x, floor_y - DECK_M * m, a.y),
			Vector3(b.x, floor_y - DECK_M * m, b.y), Vector3(c.x, floor_y - DECK_M * m, c.y),
			Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, b, c)
	var edges: Array = [outer]
	edges.append_array(holes)
	for edge_index in edges.size():
		var edge_ring: PackedVector2Array = edges[edge_index]
		var outward := signf(RingGeometry.signed_area(edge_ring)) * (1.0 if edge_index == 0 else -1.0)
		for i in edge_ring.size():
			var a: Vector2 = edge_ring[i]
			var b: Vector2 = edge_ring[(i + 1) % edge_ring.size()]
			var d := b - a
			lm.quad("Deck", Vector3(a.x, floor_y - DECK_M * m, a.y),
				Vector3(b.x, floor_y - DECK_M * m, b.y), Vector3(b.x, floor_y, b.y),
				Vector3(a.x, floor_y, a.y), Vector3(d.y, 0, -d.x).normalized() * outward)
	# Pilings end below the local surface; erroneous deep coastal DEM
	# samples must not produce hundreds of metres of hidden geometry.
	var bottom := water - 2.0 * m
	var top := floor_y - DECK_M * m
	var winding := signf(RingGeometry.signed_area(ring))
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var d := b - a
		var inward := Vector2(-d.y, d.x).normalized() * winding * 0.35 * m
		var count := clampi(ceili(d.length() / (POST_SPACING_M * m)), 1, 64)
		for j in count:
			var p := a.lerp(b, (float(j) + 0.5) / float(count)) + inward
			lm.box("Piles", Vector3(p.x, (bottom + top) * 0.5, p.y),
				Vector3(0.32 * m, top - bottom, 0.32 * m), Basis(), 0.0)
	if BuildingBuilder._batch != null:
		lm.append_to_batch(BuildingBuilder._batch, BuildingBuilder._batch_key)
		return
	for part in lm.commit(root, "WaterFoundation"):
		part.set_meta("water_foundation", true)
