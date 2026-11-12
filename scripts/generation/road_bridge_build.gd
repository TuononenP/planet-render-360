class_name RoadBridgeBuild
extends RefCounted

## Bridge decks on mapped bridge ways, split out of RoadBuilder: the deck
## profile bank to bank (or ramped up to a land viaduct's layer), the slab
## with its fascias, parapets and underside, and the piers under a land
## viaduct. RoadBuilder keeps the constants and forwards its old entry
## points here, so RailBuilder, BridgeArches and the tests call them as
## before.

## Deck heights along a bridge polyline (world units, one per point):
## bank to bank, rising in a smooth arch toward RoadBuilder.BRIDGE_CLEAR_M over the
## water (0.6 m over ground) below, capped at RoadBuilder.BRIDGE_GRADE and
## RoadBuilder.BRIDGE_RISE_M so a short or low crossing stays nearly flat. The slab
## never dips into the water: an end the river carve reaches is lifted
## to the water, and every wet point keeps the slab above it. With a
## `half` width the flat deck also clears the ground under both edges
## (a bank sloping across the way), lifted like a ribbon. Without
## `arch` a deck over land alone runs straight from bank to bank: a
## railway's track does not hump over every bridge way it is mapped in.
static func deck_profile(pts: PackedVector2Array, surf: RoadBuilder._Surface, m2u: float,
		half: float = 0.0, layer: int = 0, arch: bool = true) -> PackedFloat32Array:
	var n := pts.size()
	var total := 0.0
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		total += pts[i].distance_to(pts[i - 1])
		dist.append(total)
	var deck := PackedFloat32Array()
	if total <= 0.0:
		return deck
	var slab := (RoadBuilder.DECK_DEPTH_M + 0.5) * m2u
	var h0 := _deck_floor(pts, 0, surf, slab, half)
	var h1 := _deck_floor(pts, n - 1, surf, slab, half)
	var need := 0.0
	for i in n:
		var t := dist[i] / total
		var under := surf.height(pts[i].x, pts[i].y)
		var water := surf.ground.water_at(pts[i].x, pts[i].y) > 0.0
		var floor_y := maxf(under, surf.ground.water_level_at(pts[i].x, pts[i].y) if water else under)
		var clear := RoadBuilder.BRIDGE_CLEAR_M * m2u if water else 0.6 * m2u
		# Points by the banks would need a huge arch to clear the
		# water there; the middle two-thirds set the rise.
		need = maxf(need, (floor_y + clear - lerpf(h0, h1, t)) / maxf(sin(PI * t), 0.5))
	var rise := clampf(need, 0.0, minf(RoadBuilder.BRIDGE_GRADE * total / PI, RoadBuilder.BRIDGE_RISE_M * m2u))
	if not arch and _land_bridge(pts, surf):
		rise = 0.0
	# Lift over the arch where the slab would touch the water, eased out
	# at RoadBuilder.RAMP_GRADE both ways so it reads as a ramp, not a step.
	var lift := PackedFloat32Array()
	for i in n:
		var t := dist[i] / total
		var arched := lerpf(h0, h1, t) + 0.05 * m2u + rise * sin(PI * t)
		deck.append(arched)
		lift.append(maxf(_deck_floor(pts, i, surf, slab, half) + 0.05 * m2u - arched, 0.0))
	for i in range(1, n):
		lift[i] = maxf(lift[i], lift[i - 1] - RoadBuilder.RAMP_GRADE * (dist[i] - dist[i - 1]))
	for i in range(n - 2, -1, -1):
		lift[i] = maxf(lift[i], lift[i + 1] - RoadBuilder.RAMP_GRADE * (dist[i + 1] - dist[i]))
	for i in n:
		deck[i] += lift[i]
	# A mapped elevated way over land is a viaduct, not a ground ribbon.
	# A mostly-water crossing keeps its bank-to-bank water profile.
	# It climbs from the ground at both ends at a ramp grade (steeper
	# for a path, which takes steps) up to the layer's clearance, so a
	# short bridge peaks lower instead of hovering flat at both ends.
	if layer > 0 and RoadBridgeDecks.mostly_land(pts, surf):
		var grade := RoadBuilder.PATH_RAMP_GRADE if half * 2.0 <= RoadBuilder.PATH_WIDTH_M * m2u else RoadBuilder.RAMP_GRADE
		# An end that joins another bridge way is a joint in mid-air, not a
		# bank: the deck stays up there. Ramped to the ground at every joint,
		# a viaduct mapped in pieces rose and fell piece by piece.
		var up := float(layer) * 5.0 * m2u
		var joint0 := surf.bridge_joint(pts[0], (pts[0] - pts[1]).normalized())
		var joint1 := surf.bridge_joint(pts[n - 1], (pts[n - 1] - pts[n - 2]).normalized())
		var end0 := surf.height(pts[0].x, pts[0].y) + up if joint0 else deck[0]
		var end1 := surf.height(pts[n - 1].x, pts[n - 1].y) + up if joint1 else deck[n - 1]
		# An end on a landmark roof starts there, joint or not: the
		# mapped park/concourse network leaves the roof at its edge.
		var roof0 := surf.landmark_roof_y(pts[0])
		var roof1 := surf.landmark_roof_y(pts[n - 1])
		if roof0 > -INF:
			end0 = roof0
		if roof1 > -INF:
			end1 = roof1
		for i in n:
			var ramp := minf(INF if joint0 and roof0 <= -INF else end0 + grade * dist[i],
				INF if joint1 and roof1 <= -INF else end1 + grade * (total - dist[i]))
			var high := _deck_floor(pts, i, surf, 0.0, half) + up
			var roof_y := surf.landmark_roof_y(pts[i])
			if roof_y > -INF:
				high = roof_y + 0.05 * m2u
			deck[i] = maxf(deck[i], minf(high, ramp))
		deck[0] = maxf(deck[0], end0)
		deck[n - 1] = maxf(deck[n - 1], end1)
		_straighten_deck(deck, dist)
	return deck

## Raises `deck` to the straight lines over its high points (its upper
## hull along `dist`): a deck is a girder, and one that followed every
## rise and hollow of the ground under it was a wavy ribbon on piers.
static func _straighten_deck(deck: PackedFloat32Array, dist: PackedFloat32Array) -> void:
	var hull := PackedInt32Array()
	for i in deck.size():
		while hull.size() >= 2:
			var a := hull[hull.size() - 2]
			var b := hull[hull.size() - 1]
			# Drop b when it lies on or under the line a-i.
			if (deck[b] - deck[a]) * (dist[i] - dist[a]) <= (deck[i] - deck[a]) * (dist[b] - dist[a]):
				hull.remove_at(hull.size() - 1)
			else:
				break
		hull.append(i)
	for k in hull.size() - 1:
		var a := hull[k]
		var b := hull[k + 1]
		for i in range(a + 1, b):
			deck[i] = lerpf(deck[a], deck[b], (dist[i] - dist[a]) / maxf(dist[b] - dist[a], 0.00001))

static func _land_bridge(pts: PackedVector2Array, surf: RoadBuilder._Surface) -> bool:
	for p in pts:
		if surf.ground.water_at(p.x, p.y) > 0.0:
			return false
	return true

## Lowest deck height at point i: the drawn ground under its centre and
## both edges (`half` out), or over water the water surface plus `slab`
## (slab depth and a little air).
static func _deck_floor(pts: PackedVector2Array, i: int, surf: RoadBuilder._Surface, slab: float,
		half: float) -> float:
	var p := pts[i]
	var h := surf.height(p.x, p.y)
	if half > 0.0:
		var s := RoadBuilder._side(pts, i) * half
		h = maxf(h, maxf(surf.height(p.x + s.x, p.y + s.y), surf.height(p.x - s.x, p.y - s.y)))
	if surf.ground.water_at(p.x, p.y) > 0.0:
		h = maxf(h, surf.ground.water_level_at(p.x, p.y) + slab)
	return h

## Bridge deck on a real `bridge=yes` way (profile from deck_profile),
## with slab fascias on both sides and parapets; the deck top goes to
## the `top_finish` batch (RailBuilder lays ballast there). `fit` is a
## deck among others (RailBuilder): "open" names the edges with no
## parapet, a byte per segment for the left and for the right side
## (another deck runs alongside there); "deck" gives the heights in
## place of the profile, "low" the fascias' foot under them, "side" the
## batch the fascias, parapets and underside go to (default "deck") and
## "metric_v" a fascia texture tiled by its height in metres.
static func _bridge(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: RoadBuilder._Surface, m2u: float, top_finish: String = "bridge", structure: String = "unknown", layer: int = 0,
		fit: Dictionary = {}) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	pts = inside
	var n := pts.size()
	var deck: PackedFloat32Array = fit.get("deck", PackedFloat32Array())
	if deck.size() != n:
		deck = deck_profile(pts, surf, m2u, width * 0.5, layer)
	if deck.is_empty():
		return
	var open: Array = fit.get("open", [])
	var low: PackedFloat32Array = fit.get("low", PackedFloat32Array())
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		dist.append(dist[i - 1] + pts[i].distance_to(pts[i - 1]))
	var top := RoadBuilder._batch(batches, top_finish)
	var side := RoadBuilder._batch(batches, str(fit.get("side", "deck")))
	var metric := bool(fit.get("metric_v", false))
	var half := width * 0.5
	var k0 := top.verts.size()
	for i in n:
		var s := RoadBuilder._side(pts, i) * half
		var l := pts[i] + s
		var r := pts[i] - s
		top.verts.append(Vector3(l.x, deck[i], l.y))
		top.verts.append(Vector3(r.x, deck[i], r.y))
		top.normals.append(Vector3.UP)
		top.normals.append(Vector3.UP)
		top.uvs.append(Vector2(0.0, dist[i] / m2u / 4.0))
		top.uvs.append(Vector2(width / m2u / 4.0, dist[i] / m2u / 4.0))
	for i in n - 1:
		var a := k0 + i * 2
		RoadBuilder._quad_up(top, a, a + 1, a + 2, a + 3)
	# Fascia + parapet walls along both edges (outer: slab bottom to
	# parapet top; inner: deck to parapet top), and the parapet cap.
	var depth := RoadBuilder.DECK_DEPTH_M * m2u
	var para := RoadBuilder.PARAPET_M * m2u
	var thick := 0.25 * m2u
	for sgn in [1.0, -1.0]:
		for i in n - 1:
			var sa: Vector2 = RoadBuilder._side(pts, i) * half * sgn
			var sb: Vector2 = RoadBuilder._side(pts, i + 1) * half * sgn
			var oa := pts[i] + sa
			var ob := pts[i + 1] + sb
			var ia := oa - sa.normalized() * thick
			var ib := ob - sb.normalized() * thick
			var foot_a := low[i] if low.size() == n else deck[i] - depth
			var foot_b := low[i + 1] if low.size() == n else deck[i + 1] - depth
			if not open.is_empty() and (open[0 if sgn > 0.0 else 1] as PackedByteArray)[i] != 0:
				# A hair under the deck, so it never shows along a slab laid beside it.
				RoadBuilder._wall(side, oa, ob, foot_a, foot_b, deck[i] - 0.02 * m2u, deck[i + 1] - 0.02 * m2u,
					sa.normalized(), metric)
				continue
			if bool(fit.get("railing", false)):
				# A footbridge: its slab's face and a railing, not a wall.
				RoadBuilder._wall(side, oa, ob, foot_a, foot_b, deck[i], deck[i + 1], sa.normalized(), metric)
				railing(side, ia, ib, deck[i], deck[i + 1], sa.normalized(), m2u)
				continue
			RoadBuilder._wall(side, oa, ob, foot_a, foot_b, deck[i] + para, deck[i + 1] + para, sa.normalized(), metric)
			RoadBuilder._wall(side, ia, ib, deck[i], deck[i + 1], deck[i] + para, deck[i + 1] + para,
				-sa.normalized())
			var k := side.verts.size()
			side.verts.push_back(Vector3(oa.x, deck[i] + para, oa.y))
			side.verts.push_back(Vector3(ia.x, deck[i] + para, ia.y))
			side.verts.push_back(Vector3(ob.x, deck[i + 1] + para, ob.y))
			side.verts.push_back(Vector3(ib.x, deck[i + 1] + para, ib.y))
			for q in 4:
				side.normals.append(Vector3.UP)
				side.uvs.append(Vector2(float(q % 2), float(q / 2)))
			RoadBuilder._quad_up(side, k, k + 1, k + 2, k + 3)
	# Slab underside (seen from the quay).
	var kb := side.verts.size()
	for i in n:
		var s := RoadBuilder._side(pts, i) * half
		side.verts.append(Vector3(pts[i].x + s.x, deck[i] - depth, pts[i].y + s.y))
		side.verts.append(Vector3(pts[i].x - s.x, deck[i] - depth, pts[i].y - s.y))
		side.normals.append(Vector3.DOWN)
		side.normals.append(Vector3.DOWN)
		side.uvs.append(Vector2(0, dist[i] / m2u / 4.0))
		side.uvs.append(Vector2(1, dist[i] / m2u / 4.0))
	for i in n - 1:
		var a := kb + i * 2
		var va := side.verts[a]
		var front := (side.verts[a + 2] - va).cross(side.verts[a + 1] - va)
		if front.y <= 0.0:
			side.indices.push_back(a); side.indices.push_back(a + 1); side.indices.push_back(a + 2)
			side.indices.push_back(a + 1); side.indices.push_back(a + 3); side.indices.push_back(a + 2)
		else:
			side.indices.push_back(a); side.indices.push_back(a + 2); side.indices.push_back(a + 1)
			side.indices.push_back(a + 1); side.indices.push_back(a + 2); side.indices.push_back(a + 3)
	if layer > 0 and top_finish == "bridge" and RoadBridgeDecks.mostly_land(pts, surf):
		_land_piers(side, pts, dist, deck, surf, m2u)
	# A long crossing stands on piers under arched spandrels.
	if top_finish == "bridge" and structure == "masonry":
		BridgeArches.add(side, pts, dist, deck, half, depth, surf.ground, m2u)

## Simple concrete columns beneath land viaducts, spaced along the
## mapped way. Their tops meet the deck and bottoms follow the terrain.
static func _land_piers(side: RoadBuilder._Batch, pts: PackedVector2Array, dist: PackedFloat32Array,
		deck: PackedFloat32Array, surf: RoadBuilder._Surface, m2u: float) -> void:
	var next := 15.0 * m2u
	for i in range(1, pts.size() - 1):
		if dist[i] < next:
			continue
		next = dist[i] + 30.0 * m2u
		var p := pts[i]
		if surf.ground.water_at(p.x, p.y) > 0.0:
			continue  # No column stands in the ditch or brook under it.
		var low := surf.height(p.x, p.y) - 0.1 * m2u
		var high := deck[i] - RoadBuilder.DECK_DEPTH_M * m2u
		if high <= low + 0.2 * m2u:
			continue
		var d := (pts[i + 1] - pts[i - 1]).normalized()
		var n := Vector2(-d.y, d.x)
		var x := d * 1.25 * m2u
		var z := n * 1.25 * m2u
		var corners := [p - x - z, p + x - z, p + x + z, p - x + z]
		for k in 4:
			var a: Vector2 = corners[k]
			var b: Vector2 = corners[(k + 1) % 4]
			RoadBuilder._wall(side, a, b, low, low, high, high, ((a + b) * 0.5 - p).normalized())

## A footbridge railing from `a` to `b` standing on the deck at `ya` /
## `yb`: posts every RAILING_POST_M, a top rail and a middle rail, thin
## enough to see through (a 1 m concrete parapet on a cycleway read as a
## wall standing in the grass where its ramp came down).
const RAILING_M := 1.1
const RAILING_POST_M := 2.0
const RAILING_BAR_M := 0.06

static func railing(side: RoadBuilder._Batch, a: Vector2, b: Vector2, ya: float, yb: float,
		out: Vector2, m2u: float) -> void:
	var h := RAILING_M * m2u
	var t := RAILING_BAR_M * m2u
	for f: float in [1.0, 0.5]:
		var ta := ya + h * f
		var tb := yb + h * f
		RoadBuilder._wall(side, a, b, ta - t, tb - t, ta, tb, out)
		RoadBuilder._wall(side, a - out * t, b - out * t, ta - t, tb - t, ta, tb, -out)
		var k := side.verts.size()
		for q: Vector3 in [Vector3(a.x, ta, a.y), Vector3(a.x - out.x * t, ta, a.y - out.y * t),
				Vector3(b.x, tb, b.y), Vector3(b.x - out.x * t, tb, b.y - out.y * t)]:
			side.verts.push_back(q)
			side.normals.append(Vector3.UP)
			side.uvs.append(Vector2.ZERO)
		RoadBuilder._quad_up(side, k, k + 1, k + 2, k + 3)
	var along := (b - a).normalized()
	var n := maxi(1, ceili(a.distance_to(b) / (RAILING_POST_M * m2u)))
	for k in n + 1:
		var c := a.lerp(b, float(k) / float(n)) - out * t * 0.5
		var y := lerpf(ya, yb, float(k) / float(n))
		var x := along * t * 0.5
		var z := out * t * 0.5
		var corners := [c - x - z, c + x - z, c + x + z, c - x + z]
		for j in 4:
			var p: Vector2 = corners[j]
			var q: Vector2 = corners[(j + 1) % 4]
			RoadBuilder._wall(side, p, q, y, y, y + h, y + h, ((p + q) * 0.5 - c).normalized())

## Cumulative distance along `pts`.
static func _dist_of(pts: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		out.append(out[i - 1] + pts[i].distance_to(pts[i - 1]))
	return out
