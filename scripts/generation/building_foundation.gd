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
const BURY_MAX_M := 0.3
const PLINTH_TALL_M := 10.0
## The least wall a building keeps above its floor once a plinth has come
## out of its tagged height.
const MIN_BODY_M := 2.6
## The ground is read this often along each wall: a crown or a hollow
## between two corners counts.
const EDGE_STEP_M := 2.0
const EDGE_SAMPLES_MAX := 48
## An edge needs a skirt only where its ground lies this far under the floor.
const EDGE_GAP_M := 0.15
## Deepest a pile reaches under the water surface, whatever the bed reads.
const PILE_DEPTH_M := 12.0

## Floor and plinth for a dry seat on `low`..`high` ground.
static func _dry_seat(low: float, high: float, tall_m: float) -> Array:
	var m := WorldScale.metres_to_units()
	var relief := high - low
	var lift := minf(relief, PLINTH_MAX_M * m)
	if relief > PLINTH_MAX_M * m:
		lift = clampf(relief - BURY_MAX_M * m, PLINTH_MAX_M * m, tall_m * m)
	if lift >= PLINTH_MIN_M * m:
		return [low + lift, lift]
	return [low, 0.0]

## `tall_m` is the tallest plinth it may stand on (BuildingTerraces
## raises it for a piece on a cliff no terrace can step up), and a
## `snap_m` above zero lifts the floor to the next multiple of it, so the
## terraces of one building stand level or a clear step apart.
static func sample(ground: GroundTruth, ring: PackedVector2Array, centre: Vector2,
		sea_y: float = -INF, tall_m: float = PLINTH_TALL_M, snap_m: float = 0.0) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var all_low: float
	var all_high: float
	var dry_low: float
	var dry_high: float
	var dry_n: int
	var wet_n: int
	var water: float
	var centre_wet: bool
	# The same reads natively when the shoreline's sampler has them.
	var reads: PackedFloat64Array = ground.shoreline.footing(ring, centre, sea_y, EDGE_STEP_M * m, EDGE_SAMPLES_MAX) \
		if ground.shoreline != null and ground.shoreline.ready else PackedFloat64Array()
	if reads.size() == 8:
		all_low = reads[0]
		all_high = reads[1]
		dry_low = reads[2]
		dry_high = reads[3]
		dry_n = int(reads[4])
		wet_n = int(reads[5])
		water = reads[6]
		centre_wet = reads[7] > 0.0
	else:
		all_low = ground.height_at_world(centre.x, centre.y)
		all_high = all_low
		dry_low = INF
		dry_high = -INF
		dry_n = 0
		wet_n = 0
		var centre_level := ground.water_level_at(centre.x, centre.y, -INF)
		centre_wet = is_finite(centre_level) and all_low < centre_level
		if not centre_wet:
			# The centre informs low/high but is not a ring sample: wet_samples
			# and dry_samples stay comparable counts along the ring.
			var centre_dry := ground.dry_height_at_world(centre.x, centre.y)
			dry_low = minf(dry_low, centre_dry)
			dry_high = maxf(dry_high, centre_dry)
		water = maxf(sea_y, centre_level)
		var step := EDGE_STEP_M * m
		for i in ring.size():
			var p := ring[i]
			var q := ring[(i + 1) % ring.size()]
			water = maxf(water, ground.water_level_at(p.x, p.y, -INF))
			var n := clampi(ceili(p.distance_to(q) / step), 1, EDGE_SAMPLES_MAX)
			for k in n:
				var at := p.lerp(q, float(k) / float(n))
				var h := ground.height_at_world(at.x, at.y)
				all_low = minf(all_low, h)
				all_high = maxf(all_high, h)
				var level_at := ground.water_level_at(at.x, at.y, -INF)
				if is_finite(level_at) and h < level_at:
					wet_n += 1
				else:
					var dry_h := ground.dry_height_at_world(at.x, at.y)
					dry_low = minf(dry_low, dry_h)
					dry_high = maxf(dry_high, dry_h)
					dry_n += 1
	# The carved bed under a water-clipped edge is not the building's
	# ground. Seat on the dry samples; the bed only remains as the
	# fallback for a footprint with no dry ground at all.
	var has_dry := is_finite(dry_low)
	var low := dry_low if has_dry else all_low
	var high := dry_high if has_dry else all_high
	var freeboard := FREEBOARD_M
	# Legacy sea grids retain a 1.3 m upward swell offset.
	if ground.shoreline == null or not ground.shoreline.ready:
		freeboard += 1.3
	# A dry-centred building whose dry side carries most of its ring is a
	# quayside building the water polygon clips, not a pier: it seats on
	# its dry ground (cleared over the water) on a solid plinth.
	var grounded := has_dry and wet_n > 0 and not centre_wet and dry_n >= wet_n
	var raised := false
	var floor_y := low
	var plinth := 0.0
	if grounded:
		var seat := _dry_seat(low, high, tall_m)
		floor_y = float(seat[0])
		plinth = float(seat[1])
		if is_finite(water):
			var cleared := water + freeboard * m
			if floor_y < cleared:
				plinth += cleared - floor_y
				floor_y = cleared
	else:
		# Mostly wet is a pier however high its one dry corner stands.
		raised = is_finite(water) and (wet_n > dry_n or low < water + freeboard * m)
		floor_y = water + freeboard * m if raised else low
		if raised and high - low <= SLAB_RELIEF_M * m:
			floor_y = maxf(floor_y, high)
		elif raised:
			# A waterfront building climbing a steep bank: its deck clears the
			# water and its floor still rises toward the uphill ground, as a
			# dry hillside building's does, so the bank does not bury it.
			floor_y = maxf(floor_y, minf(high - BURY_MAX_M * m,
				floor_y + maxf(tall_m, BANK_TALL_M) * m))
		if not raised:
			var seat := _dry_seat(low, high, tall_m)
			floor_y = float(seat[0])
			plinth = float(seat[1])
	if snap_m > 0.0:
		var snapped := ceilf(floor_y / (snap_m * m)) * snap_m * m
		if plinth > 0.0:
			plinth += snapped - floor_y
		floor_y = snapped
	return {"floor": floor_y, "low": low, "high": high, "plinth": plinth,
		"water": water, "raised": raised, "wet_samples": wet_n, "dry_samples": dry_n}

## Granite foundation wall from each edge's lowest ground up to the
## walls' own base, on the downhill edges of a building raised onto a
## slope, under a dressed coping where it stands tall enough to show one
## (PlinthStyle). Uphill and level edges are buried and get none.
static func plinth(root: Node3D, ring: PackedVector2Array, holes: Array,
		footing: Dictionary, ground: GroundTruth) -> void:
	if float(footing.get("plinth", 0.0)) <= 0.0:
		return
	var m := WorldScale.metres_to_units()
	var y1 := float(footing["floor"]) - SINK_M * m
	var face := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	var coping := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	var rings: Array = [ring]
	rings.append_array(holes)
	for r in rings.size():
		var edge_ring: PackedVector2Array = rings[r]
		var ccw := RingGeometry.signed_area(edge_ring) > 0.0
		var miters := PlinthStyle.miters(edge_ring, (1.0 if ccw else -1.0) * (-1.0 if r > 0 else 1.0))
		var grounds := _edge_grounds(ground, edge_ring)
		for i in edge_ring.size():
			var a := edge_ring[i]
			var b := edge_ring[(i + 1) % edge_ring.size()]
			var d := b - a
			if d.length() < 0.001:
				continue
			# The dry bank, or the carved bed where water clips the edge,
			# so a quayside wall reaches down into the water.
			var mid := (a + b) * 0.5
			var edge_low := minf(_ground_at(ground, grounds, i, a),
				minf(_ground_at(ground, grounds, (i + 1) % edge_ring.size(), b),
				_ground_at(ground, grounds, edge_ring.size() + i, mid)))
			if float(footing["floor"]) - edge_low < EDGE_GAP_M * m:
				continue
			var y0 := edge_low - SINK_M * m
			var n := Vector2(d.y, -d.x).normalized() if ccw else Vector2(-d.y, d.x).normalized()
			if r > 0:
				n = -n
			BuildingWalls._quad(face, a, b, y0, y1, n,
				Vector2(d.length() / m / 4.0, (y1 - y0) / m / 4.0))
			if y1 - edge_low >= PlinthStyle.COPING_MIN_M * m:
				PlinthStyle.coping(coping, a, b, miters[i], miters[(i + 1) % edge_ring.size()], n, y1)
	BuildingWalls._emit(root, face, PlinthStyle.body_material())
	BuildingWalls._emit(root, coping, PlinthStyle.coping_material())

## _edge_ground at each corner of `ring` then each edge's midpoint, read
## natively in one call when the shoreline sampler can (else empty).
static func _edge_grounds(ground: GroundTruth, ring: PackedVector2Array) -> PackedFloat64Array:
	if ground.shoreline == null or not ground.shoreline.ready:
		return PackedFloat64Array()
	var points := ring.duplicate()
	for i in ring.size():
		points.append((ring[i] + ring[(i + 1) % ring.size()]) * 0.5)
	return ground.shoreline.edge_grounds(points)

## Entry `k` of _edge_grounds, or _edge_ground at `p` where it has none.
static func _ground_at(ground: GroundTruth, grounds: PackedFloat64Array, k: int, p: Vector2) -> float:
	return grounds[k] if k < grounds.size() and not is_nan(grounds[k]) else _edge_ground(ground, p)

## Ground a plinth wall stands on at `p`: the dry (pre-carve) height,
## or the rendered bed where `p` is under water.
static func _edge_ground(ground: GroundTruth, p: Vector2) -> float:
	var dry := ground.dry_height_at_world(p.x, p.y)
	return minf(dry, ground.height_at_world(p.x, p.y)) if ground.water_at(p.x, p.y) > 0.0 else dry

static func build(root: Node3D, ring: PackedVector2Array, holes: Array,
		footing: Dictionary, building: Dictionary, ground: GroundTruth = null) -> void:
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
	# Wet piles only where the building has wet ground: a dry stretch
	# stands on its ground (or the plinth wall), never on stilts over
	# land. A raised building with no wet stretch at all (low dry land
	# lifted by the freeboard) keeps its piles, else its deck floats.
	var top := floor_y - DECK_M * m
	var winding := signf(RingGeometry.signed_area(ring))
	var candidates: Array = []
	var any_wet := ground == null
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var d := b - a
		var inward := Vector2(-d.y, d.x).normalized() * winding * 0.35 * m
		var count := clampi(ceili(d.length() / (POST_SPACING_M * m)), 1, 64)
		for j in count:
			var p := a.lerp(b, (float(j) + 0.5) / float(count)) + inward
			var wet := true
			var ground_h := -INF
			if ground != null:
				ground_h = ground.height_at_world(p.x, p.y)
				wet = ground.water_at(p.x, p.y) > 0.0 or ground_h < water
			any_wet = any_wet or wet
			candidates.append([p, wet, ground_h])
	var pile_at := PackedVector3Array()
	var pile_size := PackedVector3Array()
	for candidate in candidates:
		var p: Vector2 = candidate[0]
		if ground != null and any_wet and not bool(candidate[1]):
			continue
		var ground_h: float = candidate[2]
		if ground != null and ground_h >= top:
			continue
		var bottom := water - 2.0 * m
		if ground != null:
			# Down to the bed, but never past PILE_DEPTH_M under the water:
			# a bad deep DEM sample must not grow a pile hundreds of metres.
			bottom = maxf(minf(bottom, ground_h), water - PILE_DEPTH_M * m)
		if top <= bottom:
			continue
		pile_at.append(Vector3(p.x, (bottom + top) * 0.5, p.y))
		pile_size.append(Vector3(0.32 * m, top - bottom, 0.32 * m))
	lm.boxes("Piles", pile_at, pile_size, Basis(), 0.0)
	if BuildingBuilder._batch != null:
		lm.append_to_batch(BuildingBuilder._batch, BuildingBuilder._batch_key)
		return
	# Kept arrays: LodRing merges these on the build thread (T7.5).
	for part in lm.commit(root, "WaterFoundation", true):
		part.set_meta("water_foundation", true)
