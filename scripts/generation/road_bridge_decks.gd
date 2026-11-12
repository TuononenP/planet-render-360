class_name RoadBridgeDecks
extends RefCounted

## Road bridge ways that share one structure. An overpass is often mapped
## as several parallel bridge ways (each carriageway, cycleway and
## footway on it): built one by one, each got parapets on both edges, a
## deck only its own width and its own ramp, so the structure read as a
## lattice of walls at different heights with the road below showing
## through the gaps. Here a way stands at the level of the widest road
## beside it, an edge another bridge way runs beside carries no parapet,
## and the deck is widened to the middle of the gap between their edges.
## Only road ways count: a rail bridge beside a road bridge is its own
## structure (RailDecks levels tracks), and a pedestrian area is no deck.
## Also decides when an elevated way crossing a little water (a ditch or
## brook under an overpass) keeps its layer's clearance and piers.

## Widest gap between this deck's edge and a parallel neighbour's edge
## that still counts as one structure, metres.
const BESIDE_GAP_M := 8.0
## Parallel enough to share a deck (|cos| of the angle between them).
const PARALLEL_DOT := 0.85
## Share of a span's length over water above which an elevated way is a
## water crossing (RoadBuilder keeps its bank-to-bank water profile).
const WATER_SHARE := 0.35
## Grid cell of the bridge segment index, metres.
const CELL_M := 32.0
## Ways whose half widths differ by less than this count as equally wide.
const SAME_WIDTH_M := 0.25
## Classes that ramp like a footway (steep, with steps); any other class
## is a road and ramps at the road grade however narrow (a one-lane
## carriageway of a dual road is no footpath).
const PATH_CLASSES: Array[String] = ["footway", "path", "cycleway", "steps", "pedestrian", "bridleway", "corridor"]

## Road bridge ways of one world: [points, half width, layer] each, a
## grid of their segments, and their deck profiles once computed.
class Index extends RefCounted:
	var lines: Array = []  ## {"points", "half", "layer"} per road bridge way.
	var _grid := {}  ## Cell -> PackedInt32Array of line index, segment index pairs.
	var _cell := 1.0
	var _profiles := {}  ## Line index -> [dense points, deck heights].

	func _init(roads: Array = []) -> void:
		var m := WorldScale.metres_to_units()
		_cell = CELL_M * m
		for w: Variant in roads:
			if not (w is Dictionary):
				continue
			var d: Dictionary = w
			if not bool(d.get("bridge", false)) or bool(d.get("area", false)) or bool(d.get("tunnel", false)):
				continue
			var pts: PackedVector2Array = d.get("points", PackedVector2Array())
			if pts.size() < 2:
				continue
			var li := lines.size()
			lines.append({"points": pts, "half": float(d.get("width_m", 6.0)) * 0.5 * m,
				"layer": int(d.get("layer", 0)), "cls": str(d.get("class", ""))})
			for j in range(1, pts.size()):
				var lo := pts[j - 1].min(pts[j])
				var hi := pts[j - 1].max(pts[j])
				for cx in range(floori(lo.x / _cell), floori(hi.x / _cell) + 1):
					for cz in range(floori(lo.y / _cell), floori(hi.y / _cell) + 1):
						var key := Vector2i(cx, cz)
						if not _grid.has(key):
							_grid[key] = PackedInt32Array()
						var cell: PackedInt32Array = _grid[key]
						cell.append(li)
						cell.append(j)
						_grid[key] = cell

	## Segments ([line, segment] pairs, flattened) in the cells within
	## `reach` of `p`, each once.
	func near(p: Vector2, reach: float) -> PackedInt32Array:
		var out := PackedInt32Array()
		var seen := {}
		for cx in range(floori((p.x - reach) / _cell), floori((p.x + reach) / _cell) + 1):
			for cz in range(floori((p.y - reach) / _cell), floori((p.y + reach) / _cell) + 1):
				var cell: PackedInt32Array = _grid.get(Vector2i(cx, cz), PackedInt32Array())
				for k in range(0, cell.size(), 2):
					var key := cell[k] * 65536 + cell[k + 1]
					if not seen.has(key):
						seen[key] = true
						out.append(cell[k])
						out.append(cell[k + 1])
		return out

	## Line `li`'s dense points and deck heights, profiled with its own
	## width and layer (computed once per world).
	func profile(li: int, surf: RoadBuilder._Surface, m2u: float) -> Array:
		if not _profiles.has(li):
			var line: Dictionary = lines[li]
			var dense := RoadBuilder._resample(line["points"], surf.step * 0.34)
			_profiles[li] = [dense, RoadBuilder.deck_profile(dense, surf, m2u,
				RoadBridgeDecks.grade_half(float(line["half"]), str(line["cls"]), m2u), int(line["layer"]))]
		return _profiles[li]

## Builds a road bridge way: RoadBuilder._bridge levelled with and open
## toward parallel neighbours, then the deck strips filling the gap to
## them. `own` is the way's mapped points (so it never pairs with itself).
static func build(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: RoadBuilder._Surface, m2u: float, structure: String, layer: int,
		own: PackedVector2Array = PackedVector2Array(), cls: String = "") -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	var half := width * 0.5
	var sides := beside(inside, half, surf, m2u, own)
	if sides.is_empty():
		RoadBuilder._bridge(batches, inside, width, surf, m2u, "bridge", structure, layer)
		return
	var deck := levelled(inside, half, layer, surf, m2u, own, cls)
	if deck.size() != inside.size():
		return
	var open := []
	for s in 2:
		var flags := PackedByteArray()
		for d: float in (sides["d"][s] as PackedFloat32Array):
			flags.append(1 if d > 0.0 else 0)
		open.append(flags)
	RoadBuilder._bridge(batches, inside, width, surf, m2u, "bridge", structure, layer,
		{"deck": deck, "open": open})
	_fill(RoadBuilder._batch(batches, "bridge"), inside, deck, half, sides, m2u)

## Per segment and side, the nearest parallel road bridge way beside this
## one: {"d": [left, right] centreline distances (0 where none), "half":
## [left, right] their half widths}; empty when no segment has one.
static func beside(pts: PackedVector2Array, half: float, surf: RoadBuilder._Surface,
		m2u: float, own: PackedVector2Array = PackedVector2Array()) -> Dictionary:
	var any := false
	# Packed arrays are values: fill locals, not copies read out of an Array.
	var dl := PackedFloat32Array()
	var dr := PackedFloat32Array()
	var hl := PackedFloat32Array()
	var hr := PackedFloat32Array()
	for i in pts.size() - 1:
		var mid := (pts[i] + pts[i + 1]) * 0.5
		var along := (pts[i + 1] - pts[i]).normalized()
		var left := RoadBuilder._side(pts, i).normalized()
		var a := _nearest(_hits(surf, mid, along, left, half, m2u, own))
		var b := _nearest(_hits(surf, mid, along, -left, half, m2u, own))
		dl.append(0.0 if a.is_empty() else float(a[2]))
		hl.append(0.0 if a.is_empty() else float(a[3]))
		dr.append(0.0 if b.is_empty() else float(b[2]))
		hr.append(0.0 if b.is_empty() else float(b[3]))
		any = any or not a.is_empty() or not b.is_empty()
	return {"d": [dl, dr], "half": [hl, hr]} if any else {}

static func _nearest(hits: Array) -> Array:
	var best: Array = []
	for hit: Array in hits:
		if best.is_empty() or float(hit[2]) < float(best[2]):
			best = hit
	return best

## Every parallel road bridge way beside `p` on side `dir` whose edge is
## within BESIDE_GAP_M of this deck's edge: [line index, foot point,
## centreline distance, its half width], nearest foot point per way.
static func _hits(surf: RoadBuilder._Surface, p: Vector2, along: Vector2, dir: Vector2,
		half: float, m2u: float, own: PackedVector2Array) -> Array:
	var index: Index = surf.road_bridges
	if index == null or index.lines.is_empty():
		return []
	var gap := BESIDE_GAP_M * m2u
	var found := {}
	var segs := index.near(p, half + gap + 30.0 * m2u)
	for k in range(0, segs.size(), 2):
		var li := segs[k]
		var line: Dictionary = index.lines[li]
		var pts: PackedVector2Array = line["points"]
		if not own.is_empty() and pts == own:
			continue
		var other_half := float(line["half"])
		var a := pts[segs[k + 1] - 1]
		var ab := pts[segs[k + 1]] - a
		var len2 := ab.length_squared()
		if len2 < 1e-9 or absf(ab.dot(along)) < PARALLEL_DOT * sqrt(len2):
			continue
		var t := (p - a).dot(ab) / len2
		if t < 0.0 or t > 1.0:
			continue
		var q := a + ab * t
		var off := q - p
		var d := off.dot(dir)
		# Its own line lies under it (d ~ 0); beside, not ahead: the foot
		# point lies across this deck (within ~35 degrees of its side).
		if d <= 0.3 * m2u or d < off.length() * 0.8 or d - half - other_half > gap:
			continue
		if not found.has(li) or d < float((found[li] as Array)[2]):
			found[li] = [li, q, d, other_half]
	return found.values()

## The way's deck profile set to its structure's level: wherever parallel
## road bridge ways stand beside it, the deck of the widest of them (its
## own when it is the widest; the highest of equally wide ones), so all
## ways of one overpass meet. A narrow way does not lift a road to a
## footpath's steep ramps. The rest of the deck eases in and out of the
## levelled stretch at the ramp grade instead of stepping.
static func levelled(pts: PackedVector2Array, half: float, layer: int, surf: RoadBuilder._Surface,
		m2u: float, own: PackedVector2Array = PackedVector2Array(), cls: String = "") -> PackedFloat32Array:
	var deck := RoadBuilder.deck_profile(pts, surf, m2u, grade_half(half, cls, m2u), layer)
	var n := pts.size()
	if deck.size() != n or n < 2 or surf.road_bridges == null:
		return deck
	var index: Index = surf.road_bridges
	var fixed := PackedByteArray()
	fixed.resize(n)
	for i in n:
		var j := mini(i, n - 2)
		var along := (pts[j + 1] - pts[j]).normalized()
		var left := RoadBuilder._side(pts, i).normalized()
		var hits := _hits(surf, pts[i], along, left, half, m2u, own) + _hits(surf, pts[i], along, -left, half, m2u, own)
		if hits.is_empty():
			continue
		var widest := half
		for hit: Array in hits:
			widest = maxf(widest, float(hit[3]))
		var level := deck[i] if half >= widest - SAME_WIDTH_M * m2u else -INF
		for hit: Array in hits:
			if float(hit[3]) < widest - SAME_WIDTH_M * m2u:
				continue
			var prof := index.profile(int(hit[0]), surf, m2u)
			var dense: PackedVector2Array = prof[0]
			var heights: PackedFloat32Array = prof[1]
			if heights.size() != dense.size() or dense.is_empty():
				continue
			var q: Vector2 = hit[1]
			var k := 0
			for c in dense.size():
				if dense[c].distance_squared_to(q) < dense[k].distance_squared_to(q):
					k = c
			level = maxf(level, heights[k])
		if level > -INF:
			deck[i] = level
			fixed[i] = 1
	# Once levelled, the way is part of a road structure: its free ends
	# ease in at the road grade, not a footway's steep one.
	_ease(deck, pts, fixed, maxf(grade_half(half, cls, m2u), (RoadBuilder.PATH_WIDTH_M * 0.5 + 0.05) * m2u), m2u)
	return deck

## The half width a deck is profiled with: a road class never ramps at
## the footway grade (RoadBuilder picks that by width alone).
static func grade_half(half: float, cls: String, m2u: float) -> float:
	if cls == "" or cls in PATH_CLASSES:
		return half
	return maxf(half, (RoadBuilder.PATH_WIDTH_M * 0.5 + 0.05) * m2u)

## Eases the unlevelled points toward the levelled stretch at the ramp
## grade (a footway's steeper one for a narrow way), both ways along.
static func _ease(deck: PackedFloat32Array, pts: PackedVector2Array, fixed: PackedByteArray,
		half: float, m2u: float) -> void:
	if not fixed.has(1):
		return  # Nothing levelled: the way keeps its own profile.
	var grade := RoadBuilder.PATH_RAMP_GRADE if half * 2.0 <= RoadBuilder.PATH_WIDTH_M * m2u else RoadBuilder.RAMP_GRADE
	var n := pts.size()
	for pass_i in 2:
		var order := range(1, n) if pass_i == 0 else range(n - 2, -1, -1)
		for i: int in order:
			var prev := i - 1 if pass_i == 0 else i + 1
			if fixed[i] != 0:
				continue
			var run := grade * pts[i].distance_to(pts[prev])
			deck[i] = clampf(deck[i], deck[prev] - run, deck[prev] + run)

## Deck strips from each open edge out to the middle of the gap between
## this deck's edge and its neighbour's, at this deck's height (mitred as
## RoadBuilder._bridge mitres its edges, so they meet without a sliver).
static func _fill(top: RoadBuilder._Batch, pts: PackedVector2Array, deck: PackedFloat32Array,
		half: float, sides: Dictionary, m2u: float) -> void:
	for s in 2:
		var ds: PackedFloat32Array = sides["d"][s]
		var hs: PackedFloat32Array = sides["half"][s]
		var sgn := 1.0 if s == 0 else -1.0
		for i in pts.size() - 1:
			if ds[i] <= 0.0:
				continue
			var reach := half + (ds[i] - half - hs[i]) * 0.5
			if reach <= half:
				continue
			var na := RoadBuilder._side(pts, i) * sgn
			var nb := RoadBuilder._side(pts, i + 1) * sgn
			var k := top.verts.size()
			var corners := [pts[i] + na * half, pts[i] + na * reach, pts[i + 1] + nb * half, pts[i + 1] + nb * reach]
			var heights := [deck[i], deck[i], deck[i + 1], deck[i + 1]]
			for c in 4:
				var p: Vector2 = corners[c]
				top.verts.append(Vector3(p.x, float(heights[c]), p.y))
				top.normals.append(Vector3.UP)
				top.uvs.append(Vector2(p.x, p.y) / m2u / 4.0)
			RoadBuilder._quad_up(top, k, k + 1, k + 2, k + 3)

## True for an elevated way whose span is mostly over land: a ditch or
## brook under an overpass does not make it a water crossing.
static func mostly_land(pts: PackedVector2Array, surf: RoadBuilder._Surface) -> bool:
	var total := 0.0
	var wet := 0.0
	for i in range(1, pts.size()):
		var len := pts[i].distance_to(pts[i - 1])
		var mid := (pts[i] + pts[i - 1]) * 0.5
		total += len
		if surf.ground.water_at(mid.x, mid.y) > 0.0:
			wet += len
	return total > 0.0 and wet <= total * WATER_SHARE
