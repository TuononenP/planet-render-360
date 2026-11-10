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
## A waterfront building on a steeper bank stands this far above the
## water at most, to keep its landward ground floor out of the bank.
const BANK_TALL_M := 16.0
## Walls sink this far below the lowest ground (no floating on slopes).
const SINK_M := 0.6
## On a slope the floor rises to the uphill ground while that is within
## PLINTH_MAX_M of the lowest footprint ground; a plinth fills the
## downhill gap. On steeper ground the floor keeps rising, so the hill
## never stands more than BURY_MAX_M up the uphill wall (under a window
## sill, a step down to a door), until the plinth is PLINTH_TALL_M: the
## basement or garage storeys a house on a hill shows the street below
## (BuildingBasement gives them doors and windows).
const PLINTH_MAX_M := 2.5
const PLINTH_MIN_M := 0.3
const BURY_MAX_M := 0.5
const PLINTH_TALL_M := 10.0
## The least wall a building keeps above its floor once a plinth has come
## out of its tagged height.
const MIN_BODY_M := 2.6
## The ground is read this often along each wall: a crown or a hollow
## between two corners counts.
const EDGE_STEP_M := 4.0
const EDGE_SAMPLES_MAX := 24
## An edge needs a skirt only where its ground lies this far under the floor.
const EDGE_GAP_M := 0.15
static var _plinth_mat: Material

## `tall_m` is the tallest plinth it may stand on (BuildingTerraces
## raises it for a piece on a cliff no terrace can step up).
static func sample(ground: GroundTruth, ring: PackedVector2Array, centre: Vector2,
		sea_y: float = -INF, tall_m: float = PLINTH_TALL_M) -> Dictionary:
	var low := ground.height_at_world(centre.x, centre.y)
	var high := low
	var water := maxf(sea_y, ground.water_level_at(centre.x, centre.y, -INF))
	var step := EDGE_STEP_M * WorldScale.metres_to_units()
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		water = maxf(water, ground.water_level_at(p.x, p.y, -INF))
		var n := clampi(ceili(p.distance_to(q) / step), 1, EDGE_SAMPLES_MAX)
		for k in n:
			var at := p.lerp(q, float(k) / float(n))
			var h := ground.height_at_world(at.x, at.y)
			low = minf(low, h)
			high = maxf(high, h)
	var freeboard := FREEBOARD_M
	# Legacy sea grids retain a 1.3 m upward swell offset.
	if ground.shoreline == null or not ground.shoreline.ready:
		freeboard += 1.3
	var raised := is_finite(water) and low < water + freeboard * WorldScale.metres_to_units()
	var floor_y := water + freeboard * WorldScale.metres_to_units() if raised else low
	if raised and high - low <= SLAB_RELIEF_M * WorldScale.metres_to_units():
		floor_y = maxf(floor_y, high)
	elif raised:
		# A waterfront building climbing a steep bank: its deck clears the
		# water and its floor still rises toward the uphill ground, as a
		# dry hillside building's does, so the bank does not bury it.
		floor_y = maxf(floor_y, minf(high - BURY_MAX_M * WorldScale.metres_to_units(),
			floor_y + maxf(tall_m, BANK_TALL_M) * WorldScale.metres_to_units()))
	var plinth := 0.0
	if not raised:
		var m := WorldScale.metres_to_units()
		var relief := high - low
		var lift := minf(relief, PLINTH_MAX_M * m)
		if relief > PLINTH_MAX_M * m:
			lift = clampf(relief - BURY_MAX_M * m, PLINTH_MAX_M * m, tall_m * m)
		if lift >= PLINTH_MIN_M * m:
			floor_y = low + lift
			plinth = lift
	return {"floor": floor_y, "low": low, "high": high, "plinth": plinth,
		"water": water, "raised": raised}

## Concrete foundation wall from each edge's lowest ground up to the
## walls' own base, on the downhill edges of a building raised onto a
## slope. Uphill and level edges are buried and get none.
static func plinth(root: Node3D, ring: PackedVector2Array, holes: Array,
		footing: Dictionary, ground: GroundTruth) -> void:
	if float(footing.get("plinth", 0.0)) <= 0.0:
		return
	var m := WorldScale.metres_to_units()
	var y1 := float(footing["floor"]) - SINK_M * m
	if _plinth_mat == null:
		_plinth_mat = MaterialLibrary.pbr_material("concrete", Color(0.62, 0.60, 0.57), 0.5)
	var face := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	var rings: Array = [ring]
	rings.append_array(holes)
	for r in rings.size():
		var edge_ring: PackedVector2Array = rings[r]
		var ccw := RingGeometry.signed_area(edge_ring) > 0.0
		for i in edge_ring.size():
			var a := edge_ring[i]
			var b := edge_ring[(i + 1) % edge_ring.size()]
			var d := b - a
			if d.length() < 0.001:
				continue
			var edge_low := minf(ground.height_at_world(a.x, a.y),
				minf(ground.height_at_world(b.x, b.y),
				ground.height_at_world((a.x + b.x) * 0.5, (a.y + b.y) * 0.5)))
			if float(footing["floor"]) - edge_low < EDGE_GAP_M * m:
				continue
			var y0 := edge_low - SINK_M * m
			var n := Vector2(d.y, -d.x).normalized() if ccw else Vector2(-d.y, d.x).normalized()
			if r > 0:
				n = -n
			BuildingWalls._quad(face, a, b, y0, y1, n,
				Vector2(d.length() / m / 4.0, (y1 - y0) / m / 4.0))
	BuildingWalls._emit(root, face, _plinth_mat)

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
