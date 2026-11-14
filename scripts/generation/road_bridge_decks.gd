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

## Wear seed of a deck whose road has none to match.
const DEFAULT_SEED := 0.3
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
## Deck-to-deck clearance where a way passes under another bridge way
## (headroom plus the upper deck's depth), metres: over a footway or
## cycleway, and over a road.
const CLEAR_PATH_M := 3.4
const CLEAR_ROAD_M := 5.4
## Least the upper deck rises above a lower way that cannot dip further:
## enough to hide its parapet under the upper slab (parapet, deck depth
## and a little air), metres; a full-headroom hump on a short bridge piece
## read worse than a tight underpass.
const HIDE_M := 2.0
## How far beyond the upper deck's edge a way passing under it leaves its
## parapets off and keeps dipping, metres.
const UNDER_MARGIN_M := 4.0
## A footway or cycleway deck under another bridge is thin: it may sit
## this close above the water, metres.
const PATH_WATER_M := 0.5
## Ways crossing at more than this angle (|cos| below it) cross, not run beside.
const CROSS_DOT := 0.5
## How far along a group a lead way's deck still sets a member's level, metres.
const GROUP_REACH_M := 30.0

## Road bridge ways of one world: [points, half width, layer] each, a
## grid of their segments, and their deck profiles once computed.
class Index extends RefCounted:
	var lines: Array = []  ## {"points", "half", "layer"} per road bridge way.
	var _grid := {}  ## Cell -> PackedInt32Array of line index, segment index pairs.
	var _cell := 1.0
	var _profiles := {}  ## Line index -> [dense points, deck heights].
	var _profile_mutex := Mutex.new()  ## Road chunks profile in parallel.
	var _by_ends := {}  ## [first, last] point -> line indices (a way's own line).
	var _roots := PackedInt32Array()  ## Line -> its structure group's root, once grouped.
	var _members := {}  ## Group root -> PackedInt32Array of its lines.
	var _group_mutex := Mutex.new()
	## The world's bridge structures (BridgeStructures.Plan), or null: their
	## member lines read the structure's level as their profile.
	var structures: BridgeStructures.Plan = null

	func _init(roads: Array = []) -> void:
		var m := WorldScale.metres_to_units()
		_cell = CELL_M * m
		for ri in roads.size():
			var w: Variant = roads[ri]
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
				"layer": int(d.get("layer", 0)), "cls": str(d.get("class", "")), "road": d, "ri": ri})
			var ends := Vector4(pts[0].x, pts[0].y, pts[pts.size() - 1].x, pts[pts.size() - 1].y)
			var same: PackedInt32Array = _by_ends.get(ends, PackedInt32Array())
			same.append(li)
			_by_ends[ends] = same
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

	## The index of the way mapped as `own`, or -1.
	func line_of(own: PackedVector2Array) -> int:
		if own.size() < 2:
			return -1
		# Two ways can share both end nodes: compare the whole line.
		for li in (_by_ends.get(Vector4(own[0].x, own[0].y, own[own.size() - 1].x, own[own.size() - 1].y),
				PackedInt32Array()) as PackedInt32Array):
			if (lines[li]["points"] as PackedVector2Array) == own:
				return li
		return -1

	## The lines of `li`'s structure group: road bridge ways chained side by
	## side (A beside B beside C), grouped once per world.
	func members_of(li: int, surf: RoadBuilder._Surface, m2u: float) -> PackedInt32Array:
		_group_mutex.lock()
		if _roots.is_empty():
			_group(surf, m2u)
		var out: PackedInt32Array = _members.get(_roots[li], PackedInt32Array([li]))
		_group_mutex.unlock()
		return out

	func _group(surf: RoadBuilder._Surface, m2u: float) -> void:
		var parent := PackedInt32Array()
		for li in lines.size():
			parent.append(li)
		for li in lines.size():
			var line: Dictionary = lines[li]
			var own: PackedVector2Array = line["points"]
			var pts := RoadBuilder._resample(own, 8.0 * m2u)
			for i in pts.size():
				var j := mini(i, pts.size() - 2)
				var along := (pts[j + 1] - pts[j]).normalized()
				var left := Vector2(-along.y, along.x)
				var hits := RoadBridgeDecks._hits_in(self, pts[i], along, left, float(line["half"]), m2u, own) \
					+ RoadBridgeDecks._hits_in(self, pts[i], along, -left, float(line["half"]), m2u, own)
				for hit: Array in hits:
					# Ways stacked on different layers are separate structures.
					if int(lines[int(hit[0])]["layer"]) != int(line["layer"]):
						continue
					var a := _root(parent, li)
					var b := _root(parent, int(hit[0]))
					if a != b:
						parent[maxi(a, b)] = mini(a, b)
		_roots.resize(lines.size())
		for li in lines.size():
			_roots[li] = _root(parent, li)
			var members: PackedInt32Array = _members.get(_roots[li], PackedInt32Array())
			members.append(li)
			_members[_roots[li]] = members

	## Group root of `li`, halving the path on the way (a long chain of ways
	## side by side stays near-linear to group).
	static func _root(parent: PackedInt32Array, li: int) -> int:
		while parent[li] != li:
			parent[li] = parent[parent[li]]
			li = parent[li]
		return li

	## Line `li`'s dense points and deck heights, profiled with its own
	## width and layer, or on a bridge structure at the structure's level
	## (computed once per world).
	func profile(li: int, surf: RoadBuilder._Surface, m2u: float) -> Array:
		_profile_mutex.lock()
		var hit: Array = _profiles.get(li, [])
		_profile_mutex.unlock()
		if not hit.is_empty():
			return hit
		var line: Dictionary = lines[li]
		var dense := RoadBuilder._resample(line["points"], surf.step * 0.34)
		var made: Array
		var on: BridgeStructures.Structure = structures.of_line(li) if structures != null else null
		if on != null:
			structures.prepare(surf, m2u)
			made = [dense, BridgeStructureMembers.heights(on, dense, line, surf, m2u)]
		else:
			made = [dense, RoadBuilder.deck_profile(dense, surf, m2u,
				RoadBridgeDecks.grade_half(float(line["half"]), str(line["cls"]), m2u), int(line["layer"]))]
		_profile_mutex.lock()
		if not _profiles.has(li):
			_profiles[li] = made
		hit = _profiles[li]
		_profile_mutex.unlock()
		return hit

## Builds a road bridge way: RoadBuilder._bridge at its structure's level,
## under or over the bridge ways it crosses, open toward parallel
## neighbours and toward a deck it runs onto, then the deck strips
## filling the gap to its neighbours. `own` is the way's mapped points (so
## it never pairs with itself), `cls` its road class, `road` its parsed
## entry (lanes, one-way, rank: the deck top carries the road's markings).
static func build(batches: Dictionary, pts: PackedVector2Array, width: float,
		surf: RoadBuilder._Surface, m2u: float, structure: String, layer: int,
		own: PackedVector2Array = PackedVector2Array(), cls: String = "", road: Dictionary = {},
		wear_seed: float = DEFAULT_SEED) -> void:
	var inside := PackedVector2Array()
	for p in pts:
		if surf.inside(p):
			inside.append(p)
	if inside.size() < 2:
		return
	var half := width * 0.5
	if surf.road_bridges == null:
		RoadBuilder._bridge(batches, inside, width, surf, m2u, "bridge", structure, layer)
		return
	# A way on a bridge structure is laid with it (BridgeStructures.build).
	var plan: BridgeStructures.Plan = surf.road_bridges.structures
	if plan != null and plan.of_line(surf.road_bridges.line_of(own)) != null:
		return
	var sides := beside(inside, half, surf, m2u, own)
	var on: Array = []  # An Array: a packed one would come back as a copy.
	var deck := levelled(inside, half, layer, surf, m2u, own, cls, on)
	if deck.size() != inside.size():
		return
	# Under a structure with no room for it (a path on a bank right under
	# a low deck), the way runs into the abutment, as into a culvert: drawn
	# there it stood up through the deck above.
	var buried := _no_room(inside, deck, half, layer, surf, m2u)
	if not buried.has(1):
		_lay(batches, inside, deck, on, sides, width, surf, m2u, structure, layer, road, wear_seed)
		return
	var n := inside.size()
	var i := 0
	while i < n:
		if buried[i] != 0:
			i += 1
			continue
		var j := i
		while j + 1 < n and buried[j + 1] == 0:
			j += 1
		if j > i:
			var part := {}
			if not sides.is_empty():
				part = {"d": [(sides["d"][0] as PackedFloat32Array).slice(i, j), (sides["d"][1] as PackedFloat32Array).slice(i, j)],
					"half": [(sides["half"][0] as PackedFloat32Array).slice(i, j), (sides["half"][1] as PackedFloat32Array).slice(i, j)]}
			_lay(batches, inside.slice(i, j + 1), deck.slice(i, j + 1), on.slice(i, j + 1), part, width, surf, m2u,
				structure, layer, road, wear_seed)
		i = j + 1

## 1 where the way passes under a bridge structure with less than the
## upper slab's depth and a little air between their decks.
static func _no_room(pts: PackedVector2Array, deck: PackedFloat32Array, half: float, layer: int,
		surf: RoadBuilder._Surface, m2u: float) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(pts.size())
	var plan: BridgeStructures.Plan = surf.road_bridges.structures
	if plan == null or plan.structures.is_empty():
		return out
	for i in pts.size():
		for st: BridgeStructures.Structure in plan.near(pts[i], half):
			if st.layer > layer and st.contains(pts[i], half) and st.level_at(pts[i]) - deck[i] < st.depth + 0.3 * m2u:
				out[i] = 1
	return out

## Lays the deck of `inside` at `deck`: RoadBuilder._bridge, open toward
## the ways beside it (`sides`) and the decks it runs onto (`on`), then its
## lane attributes, paint and the strips filling the gaps beside it.
static func _lay(batches: Dictionary, inside: PackedVector2Array, deck: PackedFloat32Array, on: Array,
		sides: Dictionary, width: float, surf: RoadBuilder._Surface, m2u: float, structure: String,
		layer: int, road: Dictionary, wear_seed: float = DEFAULT_SEED) -> void:
	var half := width * 0.5
	var open := []
	var any_open := false
	for s in 2:
		var flags := PackedByteArray()
		for i in inside.size() - 1:
			var beside_here := not sides.is_empty() and (sides["d"][s] as PackedFloat32Array)[i] > 0.0
			var onto := int(on[i]) != 0 and int(on[i + 1]) != 0
			flags.append(1 if beside_here or onto else 0)
			any_open = any_open or beside_here or onto
		open.append(flags)
	var fit := {"deck": deck, "railing": str(road.get("class", "")) in PATH_CLASSES}
	if any_open:
		fit["open"] = open
	var top := RoadBuilder._batch(batches, "bridge")
	top.pad()
	var k0 := top.verts.size()
	RoadBuilder._bridge(batches, inside, width, surf, m2u, "bridge", structure, layer, fit)
	_mark(top, k0, width, m2u, road, wear_seed, urban_at(inside, surf, road))
	_paint(batches, inside, deck, width, surf, m2u, road, wear_seed)
	if not sides.is_empty():
		_fill(RoadBuilder._batch(batches, "bridge"), inside, deck, half, sides, m2u)

## True where RoadBuilder lays the road as an urban street (a kerb band):
## ranked roads over land the land-use map calls urban.
static func urban_at(pts: PackedVector2Array, surf: RoadBuilder._Surface, road: Dictionary) -> bool:
	if pts.is_empty() or int(road.get("rank", 0)) < 1:
		return false
	var mid := pts[pts.size() / 2]
	return surf.ground.land_class_at(mid.x, mid.y) == "urban"

## Gives the deck top's vertices from `k0` on the road's surface attributes
## (RoadSurface: lanes and one-way in COLOR.r, rank in COLOR.g, the width
## in metres in UV2.x), so its lanes and edge lines run on across the
## bridge. A bare deck (width 0, no lanes) read as a dark sunken slab
## between the marked carriageways on either side.
static func _mark(top: RoadBuilder._Batch, k0: int, width: float, m2u: float, road: Dictionary,
		wear_seed: float = DEFAULT_SEED, urban: bool = false) -> void:
	top.pad()
	if road.is_empty():
		return
	var lanes := clampf(float(road.get("lanes", 0)), 0.0, 8.0) + (16.0 if int(road.get("oneway", 0)) != 0 else 0.0)
	# The road's own chain wear and kerb flag, as its approach ribbons carry
	# them (RoadBuilder._road): a deck of another tone read as a patch laid
	# over the road.
	var attr := Color(lanes / 32.0, float(road.get("rank", 0)) / 2.0, RoadSurface.wear_attr(urban, wear_seed), 1.0)
	for i in range(k0, top.verts.size()):
		top.colors[i] = attr
		top.uv2s[i] = Vector2(width / m2u, 0.0)

## Lane, centre and edge lines painted on the deck at its own height:
## RoadPaint lays them draped on the terrain and leaves bridges out, so a
## marked carriageway lost its lines for the length of every bridge and
## the bare deck read as a sunken slab between them. The same layout
## (RoadPaint.lane_lines), carrier strips and paint material as on land.
static func _paint(batches: Dictionary, pts: PackedVector2Array, deck: PackedFloat32Array, width: float,
		surf: RoadBuilder._Surface, m2u: float, road: Dictionary, wear_seed: float = DEFAULT_SEED,
		raw: Dictionary = {}, rise: Callable = Callable()) -> void:
	if road.is_empty() or int(road.get("rank", 0)) < 1:
		return
	var cls := str(road.get("class", ""))
	var urban := urban_at(pts, surf, road) or (not raw.is_empty() and RoadPaint.in_town(raw))
	var kind := RoadPaint.kind_of(cls, urban)
	# The place's own paint, as its approach lines are laid (RoadPaint.lay):
	# line width, a yellow centre line, lanes per direction.
	var place: LocationData = surf.place
	var style := RoadPaint.style_for(place.country if place != null else "", kind)
	var opts := RoadPaint.layout_opts(raw, false, place) if place != null and not raw.is_empty() else {"class": cls}
	var yellow := place != null and RoadSurface.yellow_centre(place)
	var lines := RoadPaint.lane_lines(width / m2u, int(road.get("lanes", 0)), int(road.get("oneway", 0)) != 0,
		int(road.get("rank", 0)), urban, float(style[2]), Vector2.ZERO, 0, opts)
	if lines.is_empty():
		return
	var b := RoadBuilder._batch(batches, "paint")
	var hc := RoadPaint.CARRIER_M * 0.5 * m2u
	var lift := 0.03 * m2u
	for l: Dictionary in lines:
		var code := RoadPaint.SOLID if bool(l["solid"]) else int(RoadPaint.PATTERN[kind])
		if bool(l["centre"]) and yellow:
			code |= RoadPaint.YELLOW_BIT
		var attr := Color(float(l["half"]) / RoadPaint.HALF_MAX_M, float(code) / 15.0, wear_seed, 1.0)
		b.pad()
		var k0 := b.verts.size()
		var along := 0.0
		for i in pts.size():
			if i > 0:
				along += pts[i].distance_to(pts[i - 1])
			var side := RoadBuilder._side(pts, i)
			# RoadBuilder._side points right of travel; lines are offset left.
			var c := pts[i] - side * float(l["x"]) * m2u
			var sl := side.normalized() * hc
			for e: Vector2 in [c + sl, c - sl]:
				# Over the deck's cross slope where it has one (_abutment_fit).
				var y: float = float(rise.call(i, e)) if rise.is_valid() else deck[i]
				b.verts.append(Vector3(e.x, y + lift, e.y))
				b.normals.append(Vector3.UP)
				b.colors.append(attr)
				b.uv2s.append(Vector2(RoadPaint.CARRIER_M, RoadPaint.LAYER))
			b.uvs.append(Vector2(0.0, along / m2u / 4.0))
			b.uvs.append(Vector2(RoadPaint.CARRIER_M / 4.0, along / m2u / 4.0))
		for i in pts.size() - 1:
			RoadBuilder._quad_up(b, k0 + i * 2, k0 + i * 2 + 1, k0 + i * 2 + 2, k0 + i * 2 + 3)

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
	return _hits_in(surf.road_bridges, p, along, dir, half, m2u, own)

## _hits on a bridge index (the grouping needs no surface).
static func _hits_in(index: Index, p: Vector2, along: Vector2, dir: Vector2,
		half: float, m2u: float, own: PackedVector2Array) -> Array:
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

## The way's deck profile set to its structure's level, then passed under
## or over the bridge ways it crosses on another layer. The level is the
## deck of the widest way of its group (ways chained side by side), its
## own when it is the widest, the highest of equally wide ones, wherever
## such a way runs within GROUP_REACH_M: all ways of one overpass meet, and
## a narrow way does not lift a road to a footpath's steep ramps. Points
## the level or a crossing sets are eased into at the ramp grade. `on`, if
## given, is filled with 1 where the way runs onto a wider same-layer deck
## it crosses (no parapet there).
static func levelled(pts: PackedVector2Array, half: float, layer: int, surf: RoadBuilder._Surface,
		m2u: float, own: PackedVector2Array = PackedVector2Array(), cls: String = "",
		on: Array = []) -> PackedFloat32Array:
	var deck := RoadBuilder.deck_profile(pts, surf, m2u, grade_half(half, cls, m2u), layer)
	var n := pts.size()
	on.resize(n)
	on.fill(0)
	if deck.size() != n or n < 2 or surf.road_bridges == null:
		return deck
	var index: Index = surf.road_bridges
	var fixed := PackedByteArray()
	fixed.resize(n)
	var own_li := index.line_of(own)
	if own_li >= 0:
		_level_group(deck, pts, fixed, half, own_li, index, surf, m2u)
	else:
		_level_beside(deck, pts, fixed, half, index, surf, m2u, own)
	_structures(deck, pts, fixed, on, half, layer, cls, index, surf, m2u, true)
	# Once levelled, the way is part of a road structure: its free ends
	# ease in at the road grade, not a footway's steep one.
	var ease_half := grade_half(half, cls, m2u)
	if fixed.has(1):
		ease_half = maxf(ease_half, (RoadBuilder.PATH_WIDTH_M * 0.5 + 0.05) * m2u)
	_ease(deck, pts, fixed, ease_half, m2u)
	# Crossings come after the level: the points a crossing sets are the
	# anchors the rest of the deck (levelled points too) eases toward.
	var crossed := PackedByteArray()
	crossed.resize(n)
	_cross(deck, pts, crossed, on, half, layer, cls, own_li, index, surf, m2u)
	_structures(deck, pts, crossed, on, half, layer, cls, index, surf, m2u, false)
	_ease(deck, pts, crossed, ease_half, m2u)
	return deck

## Group level: the highest of the widest member ways' decks (each at its
## dense point nearest, within GROUP_REACH_M and not past its ends), this
## way's own among them when it is one of the widest.
static func _level_group(deck: PackedFloat32Array, pts: PackedVector2Array, fixed: PackedByteArray,
		half: float, own_li: int, index: Index, surf: RoadBuilder._Surface, m2u: float) -> void:
	var members := index.members_of(own_li, surf, m2u)
	if members.size() < 2:
		return
	var widest := half
	for li in members:
		widest = maxf(widest, float(index.lines[li]["half"]))
	var lead: Array = []
	# Every member, the widest included, reads the same cached profiles,
	# so they all land on exactly one level.
	for li in members:
		if float(index.lines[li]["half"]) >= widest - SAME_WIDTH_M * m2u:
			lead.append(index.profile(li, surf, m2u))
	var reach := GROUP_REACH_M * m2u
	for i in pts.size():
		var level := -INF
		var near_any := false
		for prof: Array in lead:
			var dense: PackedVector2Array = prof[0]
			var heights: PackedFloat32Array = prof[1]
			if heights.size() != dense.size() or dense.is_empty():
				continue
			var k := _closest(dense, pts[i])
			# Only where the lead runs beside this point: past its ends (a
			# landing tail, a ramp turning away) the way keeps its own deck.
			if k == 0 or k == dense.size() - 1 or dense[k].distance_to(pts[i]) > reach:
				continue
			near_any = true
			level = maxf(level, heights[k])
		if near_any and level > -INF:
			deck[i] = level
			fixed[i] = 1

## Per-point level from the ways beside each point (a way not in the
## index, e.g. one a test builds without its mapped points).
static func _level_beside(deck: PackedFloat32Array, pts: PackedVector2Array, fixed: PackedByteArray,
		half: float, index: Index, surf: RoadBuilder._Surface, m2u: float, own: PackedVector2Array) -> void:
	var n := pts.size()
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
			level = maxf(level, heights[_closest(dense, hit[1])])
		if level > -INF:
			deck[i] = level
			fixed[i] = 1

## Crossings with other road bridge ways. On another layer the lower way
## passes under the upper with CLEAR_PATH_M / CLEAR_ROAD_M to spare: it
## dips, and where water or ground keeps it up the upper rises (both ways
## of a crossing reach the same answer); under the upper deck and
## UNDER_MARGIN_M beyond it the lower way leaves its parapets off (`on`).
## On the same layer a narrower way running onto a wider deck takes that
## deck's height there and leaves its parapets off too.
static func _cross(deck: PackedFloat32Array, pts: PackedVector2Array, fixed: PackedByteArray,
		on: Array, half: float, layer: int, cls: String, own_li: int, index: Index,
		surf: RoadBuilder._Surface, m2u: float) -> void:
	var n := pts.size()
	var own_path := cls in PATH_CLASSES
	for i in n:
		var j := mini(i, n - 2)
		var along := (pts[j + 1] - pts[j]).normalized()
		var segs := index.near(pts[i], half + 20.0 * m2u)
		for k in range(0, segs.size(), 2):
			var li := segs[k]
			if li == own_li or (index.structures != null and index.structures.of_line(li) != null):
				continue  # Itself, or a way on a structure (_structures).
			var line: Dictionary = index.lines[li]
			var lp: PackedVector2Array = line["points"]
			var a := lp[segs[k + 1] - 1]
			var ab := lp[segs[k + 1]] - a
			var len2 := ab.length_squared()
			if len2 < 1e-9 or absf(ab.dot(along)) > CROSS_DOT * sqrt(len2):
				continue
			var q := a + ab * clampf((pts[i] - a).dot(ab) / len2, 0.0, 1.0)
			var other_half := float(line["half"])
			var other_layer := int(line["layer"])
			# A way passing under reaches UNDER_MARGIN_M beyond the upper deck:
			# its parapets stop short of it there, and it dips across the margin.
			var reach := half + other_half + (UNDER_MARGIN_M * m2u if other_layer > layer else 0.0)
			if q.distance_to(pts[i]) > reach:
				continue
			var prof := index.profile(li, surf, m2u)
			var dense: PackedVector2Array = prof[0]
			var heights: PackedFloat32Array = prof[1]
			if heights.size() != dense.size() or dense.is_empty():
				continue
			var other := heights[_closest(dense, q)]
			if other_layer == layer:
				if other_half > half + SAME_WIDTH_M * m2u and pts[i].distance_to(q) <= other_half:
					deck[i] = other
					fixed[i] = 1
					on[i] = 1
			elif other_layer > layer:
				# This way is the lower one: it dips under, down to its floor.
				var clear := (CLEAR_PATH_M if own_path else CLEAR_ROAD_M) * m2u
				var floor_y := _floor_at(pts[i], surf, m2u, own_path)
				var target := maxf(other - clear, floor_y)
				# Under a low bridge a path has a railing, not a parapet wall
				# standing at the upper road's level across its lanes.
				on[i] = 1
				if deck[i] > target:
					deck[i] = target
					fixed[i] = 1
			else:
				# This way is the upper one: it rises only where the lower way
				# cannot dip far enough, and then just enough to hide it.
				var lower_path := str(line["cls"]) in PATH_CLASSES
				var clear := (CLEAR_PATH_M if lower_path else CLEAR_ROAD_M) * m2u
				var need := _floor_at(q, surf, m2u, lower_path) + HIDE_M * m2u
				if other > deck[i] - clear and deck[i] < need:
					deck[i] = need
					fixed[i] = 1

## The bridge structures (BridgeStructures) a way meets. `same`: on its
## own layer it runs onto a structure, takes its level there and leaves
## its parapets off. Otherwise: under a structure it dips by CLEAR_PATH_M
## / CLEAR_ROAD_M, down to its floor, parapets off under the deck and
## UNDER_MARGIN_M beyond (the structure has already risen where it cannot,
## BridgeStructures._settle); over one it rises, if it must, to hide it.
static func _structures(deck: PackedFloat32Array, pts: PackedVector2Array, fixed: PackedByteArray,
		on: Array, half: float, layer: int, cls: String, index: Index, surf: RoadBuilder._Surface,
		m2u: float, same: bool) -> void:
	var plan: BridgeStructures.Plan = index.structures
	if plan == null or plan.structures.is_empty():
		return
	plan.prepare(surf, m2u)
	var own_path := cls in PATH_CLASSES
	var margin := half + UNDER_MARGIN_M * m2u
	for i in pts.size():
		for s: BridgeStructures.Structure in plan.near(pts[i], margin):
			var p := pts[i]
			if s.layer == layer:
				if same and s.contains(p, BridgeStructures.ON_M * m2u):
					deck[i] = s.level_at(p)
					fixed[i] = 1
					on[i] = 1
			elif same:
				continue
			elif s.layer > layer:
				if s.contains(p, margin):
					var clear := (CLEAR_PATH_M if own_path else CLEAR_ROAD_M) * m2u
					var target := maxf(s.level_at(p) - clear, _floor_at(p, surf, m2u, own_path))
					on[i] = 1
					if deck[i] > target:
						deck[i] = target
						fixed[i] = 1
			elif s.contains(p, half):
				var clear := (CLEAR_PATH_M if s.path else CLEAR_ROAD_M) * m2u
				var need := _floor_at(p, surf, m2u, s.path) + HIDE_M * m2u
				if s.level_at(p) > deck[i] - clear and deck[i] < need:
					deck[i] = need
					fixed[i] = 1

## Lowest a deck can stand at `p`: the ground, or over water its surface
## plus the slab and a little air (as RoadBuilder._deck_floor); a thin
## path deck (`path`) may sit PATH_WATER_M over the water.
static func _floor_at(p: Vector2, surf: RoadBuilder._Surface, m2u: float, path: bool = false) -> float:
	var h := surf.height(p.x, p.y)
	if surf.ground.water_at(p.x, p.y) > 0.0:
		var air := PATH_WATER_M if path else RoadBuilder.DECK_DEPTH_M + 0.5
		h = maxf(h, surf.ground.water_level_at(p.x, p.y) + air * m2u)
	return h

static func _closest(dense: PackedVector2Array, q: Vector2) -> int:
	var k := 0
	for c in dense.size():
		if dense[c].distance_squared_to(q) < dense[k].distance_squared_to(q):
			k = c
	return k

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
