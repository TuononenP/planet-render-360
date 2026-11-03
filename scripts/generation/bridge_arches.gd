class_name BridgeArches
extends RefCounted

## Piers and arch openings under a long bridge deck (Ultra pass, all
## tiers: it is a few hundred triangles). RoadBuilder draws a bridge as a
## 0.9 m slab with parapets, so Westminster Bridge read as a plank over
## the Thames. Where a deck crosses at least MIN_WET_M of water:
## * piers every ~SPAN_M between the abutments, PIER_M thick, down to
##   below the waterline;
## * the spandrel walls on both edges dropping from the slab to a
##   segmental arch (springing SPRING_UP_M over the water, crowning at the
##   slab's underside), so each span shows an arched opening;
## * a soffit strip under each arch closing the gap between the walls,
##   and the piers' end faces.
## Everything goes into RoadBuilder's "deck" batch (the concrete PBR).

const MIN_WET_M := 45.0
const SPAN_M := 32.0
const PIER_M := 3.0
const SPRING_UP_M := 1.0
const SEG := 8
const MIN_SPANS := 2
const MAX_SPANS := 10
## Piers reach this far below the water surface (m).
const PIER_BELOW_M := 1.5

## Known structures where OSM ways often omit bridge:structure. Explicit
## tags take precedence; unknown bridges retain a plain deck.
const KNOWN_STRUCTURES := {"västerbron": "steel_arch", "vasterbron": "steel_arch", "centralbron": "girder"}

static func structure(road: Dictionary) -> String:
	var tag := str(road.get("bridge_structure", "")).strip_edges().to_lower().replace("-", "_")
	var material := str(road.get("bridge_material", "")).strip_edges().to_lower()
	if tag in ["masonry", "masonry_arch", "stone_arch"]:
		return "masonry"
	if tag in ["arch", "arch_bridge"]:
		if material in ["stone", "brick", "masonry"]:
			return "masonry"
		return "steel_arch" if material in ["steel", "iron"] else "unknown"
	if tag in ["steel_arch", "girder", "beam", "suspension", "cable_stayed", "truss"]:
		return tag
	if tag != "":
		return "unknown"
	return str(KNOWN_STRUCTURES.get(str(road.get("name", "")).strip_edges().to_lower(), "unknown"))

## Adds the arches under the deck `deck` (one Y per point of `pts`, with
## cumulative distances `dist`) into `side`. `half` is the half deck
## width and `depth` the slab depth, in world units. Returns the number
## of spans (0 when the bridge is too short or dry).
static func add(side: RoadBuilder._Batch, pts: PackedVector2Array, dist: PackedFloat32Array,
		deck: PackedFloat32Array, half: float, depth: float, ground: GroundTruth,
		m2u: float) -> int:
	var first := -1
	var last := -1
	for i in pts.size():
		if ground.water_at(pts[i].x, pts[i].y) > 0.3 * m2u:
			if first < 0:
				first = i
			last = i
	if first < 0 or last <= first:
		return 0
	var d0 := dist[first]
	var wet_len := dist[last] - d0
	if wet_len < MIN_WET_M * m2u:
		return 0
	var n := clampi(roundi(wet_len / (SPAN_M * m2u)), MIN_SPANS, MAX_SPANS)
	var pier := PIER_M * m2u
	for j in n:
		var a := d0 + wet_len * float(j) / float(n) + (pier * 0.5 if j > 0 else 0.0)
		var b := d0 + wet_len * float(j + 1) / float(n) - (pier * 0.5 if j < n - 1 else 0.0)
		_span(side, pts, dist, deck, half, depth, ground, m2u, a, b)
		if j > 0:
			_pier(side, pts, dist, deck, half, depth, ground, m2u, a - pier, a)
	return n

## One arched opening from distance `a` to `b` along the deck.
static func _span(side: RoadBuilder._Batch, pts: PackedVector2Array, dist: PackedFloat32Array,
		deck: PackedFloat32Array, half: float, depth: float, ground: GroundTruth, m2u: float,
		a: float, b: float) -> void:
	var left: Array = []
	var right: Array = []
	var lows: Array = []
	var tops: Array = []
	for i in SEG + 1:
		var t := float(i) / float(SEG)
		var d := lerpf(a, b, t)
		var at := _at(pts, dist, deck, d)
		var p: Vector2 = at[0]
		var nrm: Vector2 = at[1]
		var wy := ground.water_level_at(p.x, p.y)
		var spring := wy + SPRING_UP_M * m2u
		var crown := float(at[2]) - depth
		var k := 1.0 - pow(2.0 * t - 1.0, 2.0)
		var low := minf(spring + (crown - spring) * k, crown)
		left.append(p + nrm * half)
		right.append(p - nrm * half)
		lows.append(low)
		tops.append(crown)
	for i in SEG:
		# Spandrel walls above the arch curve on both edges, outward faces.
		var la: Vector2 = left[i]
		var lb: Vector2 = left[i + 1]
		RoadBuilder._wall(side, la, lb, lows[i], lows[i + 1], tops[i], tops[i + 1],
			((left[i] as Vector2) - (right[i] as Vector2)).normalized())
		var ra: Vector2 = right[i]
		var rb: Vector2 = right[i + 1]
		RoadBuilder._wall(side, ra, rb, lows[i], lows[i + 1], tops[i], tops[i + 1],
			((right[i] as Vector2) - (left[i] as Vector2)).normalized())
		# Soffit between the walls, facing down into the opening.
		_soffit(side, [Vector3(la.x, lows[i], la.y), Vector3(ra.x, lows[i], ra.y),
			Vector3(lb.x, lows[i + 1], lb.y), Vector3(rb.x, lows[i + 1], rb.y)])

## A pier between `a` and `b` along the deck: its two long faces up to the
## slab and its end faces down to below the water.
static func _pier(side: RoadBuilder._Batch, pts: PackedVector2Array, dist: PackedFloat32Array,
		deck: PackedFloat32Array, half: float, depth: float, ground: GroundTruth, m2u: float,
		a: float, b: float) -> void:
	var pa := _at(pts, dist, deck, a)
	var pb := _at(pts, dist, deck, b)
	var wy := ground.water_level_at((pa[0] as Vector2).x, (pa[0] as Vector2).y)
	var foot := wy - PIER_BELOW_M * m2u
	var dir := ((pb[0] as Vector2) - (pa[0] as Vector2)).normalized()
	var la: Vector2 = (pa[0] as Vector2) + (pa[1] as Vector2) * half
	var ra: Vector2 = (pa[0] as Vector2) - (pa[1] as Vector2) * half
	var lb: Vector2 = (pb[0] as Vector2) + (pb[1] as Vector2) * half
	var rb: Vector2 = (pb[0] as Vector2) - (pb[1] as Vector2) * half
	var ta := float(pa[2]) - depth
	var tb := float(pb[2]) - depth
	RoadBuilder._wall(side, la, lb, foot, foot, ta, tb, (la - ra).normalized())
	RoadBuilder._wall(side, ra, rb, foot, foot, ta, tb, (ra - la).normalized())
	# End faces, up to the arch springing only (above it the span opens).
	var spring := wy + SPRING_UP_M * m2u
	RoadBuilder._wall(side, la, ra, foot, foot, spring, spring, -dir)
	RoadBuilder._wall(side, lb, rb, foot, foot, spring, spring, dir)

## Deck position, side normal and deck Y at distance `d` along the bridge.
static func _at(pts: PackedVector2Array, dist: PackedFloat32Array, deck: PackedFloat32Array,
		d: float) -> Array:
	var i := 0
	while i < pts.size() - 2 and dist[i + 1] < d:
		i += 1
	var seg := maxf(dist[i + 1] - dist[i], 1e-6)
	var t := clampf((d - dist[i]) / seg, 0.0, 1.0)
	return [pts[i].lerp(pts[i + 1], t), RoadBuilder._side(pts, i).lerp(RoadBuilder._side(pts, i + 1), t).normalized(),
		lerpf(deck[i], deck[i + 1], t)]

## Quad of four points [l0, r0, l1, r1] facing down.
static func _soffit(b: RoadBuilder._Batch, v: Array) -> void:
	var k := b.verts.size()
	for p in v:
		b.verts.push_back(p)
		b.normals.append(Vector3.DOWN)
	b.uvs.push_back(Vector2(0, 0)); b.uvs.push_back(Vector2(1, 0))
	b.uvs.push_back(Vector2(0, 1)); b.uvs.push_back(Vector2(1, 1))
	var front := (b.verts[k + 2] - b.verts[k]).cross(b.verts[k + 1] - b.verts[k])
	if front.y <= 0.0:
		b.indices.push_back(k); b.indices.push_back(k + 1); b.indices.push_back(k + 2)
		b.indices.push_back(k + 1); b.indices.push_back(k + 3); b.indices.push_back(k + 2)
	else:
		b.indices.push_back(k); b.indices.push_back(k + 2); b.indices.push_back(k + 1)
		b.indices.push_back(k + 1); b.indices.push_back(k + 2); b.indices.push_back(k + 3)
