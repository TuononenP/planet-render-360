class_name StockholmShore
extends RefCounted

## Stockholm's two worst banks, mended in the map data before the shoreline is
## classified (GroundTruth calls prepare once per LocationData):
##  - Riddarholmen: the island's water edge is a dressed granite quay but
##    carries no mapped wall, so its bank classed as unproven natural shore and
##    drew a pale sloping slab. Each ring edge inside RIDDARHOLMEN is mapped as
##    a quay wall ("embankment": a wall, but not the upper wall of a low quay).
##  - Slussen: the lock chambers are separate mapped water polygons, each
##    levelled from its own bank samples, so the panes stood at different
##    heights on bare earth (the orthophoto's building site). Their edges are
##    walled the same way, a stone-paved court is laid under them, and
##    level_locks() puts every pane at one level.
## Riddarholmen's ground, unmapped, also drew pale tan mounds at the foot of
## its buildings: it gets a paved court too. Stockholm only; idempotent (a
## marker on the courts).

## (lat, lon, height deg, width deg) boxes.
const RIDDARHOLMEN := Rect2(59.3228, 18.0600, 0.0042, 0.0095)
const SLUSSEN := Rect2(59.3199, 18.0700, 0.0030, 0.0085)
## The paved court reaches this far past the lock panes, metres.
const COURT_MARGIN_M := 40.0
const MARKER := "sto_shore"

## True for a water polygon of the Slussen locks (see prepare).
static func lock_site(poly: Dictionary) -> bool:
	return bool(poly.get("lock_site", false))

static func prepare(data: LocationData) -> void:
	if not ShoreApron.stockholm(data):
		return
	for poly in data.land_polygons:
		if poly is Dictionary and poly.has(MARKER):
			return
	var island := _xz_box(data, RIDDARHOLMEN)
	var locks := _xz_box(data, SLUSSEN)
	var m := WorldScale.metres_to_units()
	var court := Rect2()
	var found := false
	var n := 0
	for poly in data.land_polygons:
		if not (poly is Dictionary) or str(poly.get("class", "")) != "water":
			continue
		var rings: Array = [poly.get("points", PackedVector2Array())]
		for h in poly.get("holes", []):
			rings.append(h)
		var pane := false
		var box := RingGeometry.aabb(rings[0]) if (rings[0] as PackedVector2Array).size() > 2 else Rect2()
		# A lock pane is a small polygon wholly inside the Slussen box.
		if locks.encloses(box) and box.size.x < 400.0 * m and box.size.y < 400.0 * m:
			pane = true
			poly["lock_site"] = true
			court = box if not found else court.merge(box)
			found = true
		for ring: PackedVector2Array in rings:
			for i in ring.size():
				var a := ring[i]
				var b := ring[(i + 1) % ring.size()]
				var mid := (a + b) * 0.5
				if a.distance_squared_to(b) < 0.0001 or not (pane or island.has_point(mid)):
					continue
				data.shore_structures.append({"points": PackedVector2Array([a, b]), "kind": "embankment",
					"id": "sto:quay:%d" % n, "material": "granite", "height_m": 0.0})
				n += 1
	# Stone-paved courts under both, last in the list so every mapped polygon
	# (water first) still wins; the footprints and streets paint over them.
	if found:
		data.land_polygons.append(_court(court.grow(COURT_MARGIN_M * m)))
	data.land_polygons.append(_court(island))

## A paved rectangle (class "sett", the marker set).
static func _court(box: Rect2) -> Dictionary:
	return {"class": "sett", MARKER: true, "holes": [], "points": PackedVector2Array([box.position,
		Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y), box.position])}

## Every Slussen pane at the lowest of their levels: one water, not steps.
static func level_locks(domains: ShoreDomains, data: LocationData) -> void:
	var low := INF
	var ids: Array[int] = []
	for id in domains.bodies.size():
		var source := int(domains.bodies[id].get("source", -1))
		if source >= 0 and source < data.land_polygons.size() and lock_site(data.land_polygons[source]):
			ids.append(id)
			low = minf(low, float(domains.bodies[id]["level"]))
	for id in ids:
		domains.bodies[id]["level"] = low
		# On the body itself: the world builders may see another copy of the data.
		domains.bodies[id]["lock_site"] = true

## Plinth aprons: the elevation model carries a building's mass into the ground
## as a ramp up to its foot, which the sun then blows out as a pale heap. On
## Riddarholmen every post within APRON_M of a footprint is lowered to the
## ground level a few metres off its walls (the lower third of the posts
## APRON_PROBE_M out, outside every footprint), fully within APRON_FULL_M of the
## wall and fading out beyond; a post never rises. `surface` is the ground's
## post grid in source metres, before the shoreline model copies it.
const APRON_M := 9.0
const APRON_FULL_M := 4.0
const APRON_PROBE_M := Vector2(3.0, 10.0)
## The apron keeps this much of the ground's own relief, metres (a plinth is
## not a billiard table).
const APRON_KEEP_M := 0.12

static func flatten_plinths(surface: PackedFloat32Array, size: int, step: float, data: LocationData) -> int:
	if not ShoreApron.stockholm(data) or size < 4 or surface.size() != size * size:
		return 0
	var island := _xz_box(data, RIDDARHOLMEN)
	var rings: Array = []
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		if ring.size() < 3:
			continue
		var box := RingGeometry.aabb(ring)
		if island.has_point(box.get_center()):
			rings.append([ring, box])
	var half := float(size) * 0.5
	var lowered := PackedFloat32Array()
	lowered.resize(surface.size())
	lowered.fill(0.0)
	var count := 0
	for entry: Array in rings:
		var ring: PackedVector2Array = entry[0]
		var box: Rect2 = (entry[1] as Rect2).grow(APRON_M)
		var x0 := clampi(floori(box.position.x / step + half), 0, size - 1)
		var x1 := clampi(ceili(box.end.x / step + half), 0, size - 1)
		var z0 := clampi(floori(box.position.y / step + half), 0, size - 1)
		var z1 := clampi(ceili(box.end.y / step + half), 0, size - 1)
		var probes: Array[float] = []
		var near: Array = []
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var p := Vector2((float(x) - half) * step, (float(z) - half) * step)
				var d := _ring_distance(p, ring)
				if d <= APRON_M:
					near.append([z * size + x, d])
				if d >= APRON_PROBE_M.x and d <= APRON_PROBE_M.y and not _in_any(p, rings, ring):
					probes.append(surface[z * size + x])
		if probes.size() < 3 or near.is_empty():
			continue
		probes.sort()
		var target := probes[probes.size() / 3] + APRON_KEEP_M
		for hit: Array in near:
			var i: int = hit[0]
			var w := 1.0 - smoothstep(APRON_FULL_M, APRON_M, float(hit[1]))
			var cut := maxf(0.0, surface[i] - target) * w
			lowered[i] = maxf(lowered[i], cut)
	for i in surface.size():
		if lowered[i] > 0.0:
			surface[i] -= lowered[i]
			count += 1
	return count

## Distance from `p` to the ring's outline, 0 inside it.
static func _ring_distance(p: Vector2, ring: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(p, ring):
		return 0.0
	var best := INF
	for i in ring.size():
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()]).distance_to(p))
	return best

## True when `p` lies inside a footprint of `rings` other than `skip`.
static func _in_any(p: Vector2, rings: Array, skip: PackedVector2Array) -> bool:
	for entry: Array in rings:
		var ring: PackedVector2Array = entry[0]
		if ring != skip and (entry[1] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, ring):
			return true
	return false

## A (lat, lon, height, width) box as world XZ.
static func _xz_box(data: LocationData, box: Rect2) -> Rect2:
	var a := WorldScale.xz_from_latlon(box.position.x, box.position.y, data.latitude, data.longitude)
	var b := WorldScale.xz_from_latlon(box.end.x, box.end.y, data.latitude, data.longitude)
	return Rect2(a.min(b), (b - a).abs())
