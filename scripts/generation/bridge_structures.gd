class_name BridgeStructures
extends RefCounted

## One deck per real bridge structure. OSM maps a bridge's structure as a
## man_made=bridge outline, and the carriageways, links and paths on it as
## bridge ways. Built way by way, each got its own slab, level and
## parapets, so one overpass read as a box of separate decks with parapet
## stubs and steps between them. Here each outline is a structure. The
## road bridge ways mostly inside it are its members. It has one level:
## its spine's deck profile (the widest member), read at the nearest spine
## point, so every member and the slab stand at exactly the same height.
## One slab is cut from the outline, with parapets only along the
## outline's edges, open where a member road leaves it. Members lay only
## their asphalt and lane paint on it. Crossings between structures, and
## with bridge ways passing under or over them, are settled once per
## world. Ways on no outline keep RoadBridgeDecks.

## Share of a way's length inside an outline that makes it a member.
const MEMBER_SHARE := 0.6
## Spine sample spacing, and the slab's cell size, metres.
const SPINE_STEP_M := 2.0
const SLICE_M := 4.0
## Most slab cells per structure (a long viaduct outline takes larger ones).
const MAX_CELLS := 1500
## Grid cell of the outline index, metres.
const CELL_M := 32.0
## A member's asphalt lies this far over the slab, a depth layer up.
const RIBBON_LIFT_M := 0.02
const RIBBON_LAYER := 2.0
## A parapet opens this far beyond each edge of a road leaving the outline.
const OPEN_PAD_M := 0.5
## A member end this close inside an edge still opens it (an abutment).
const END_REACH_M := 3.0
## How far outside an outline a point still counts as on it, metres.
const ON_M := 0.3
## An outline edge more across the spine than this (|cos| below it) is
## part of an end; an end where a member ends is an open abutment.
const END_DOT := 0.6
## How far along its approach an abutment seeks the road's first dry
## point, metres.
const ABUTMENT_SEEK_M := 20.0
## The deck eases onto its approach's ground over this far before an
## abutment (further at BLEND_GRADE for a larger step), by at most
## FIT_MAX_M / PATH_FIT_MAX_M (beyond that a bank falls away, and the
## abutment wall faces it), metres.
const BLEND_M := 5.0
const BLEND_GRADE := 0.12
const FIT_MAX_M := 1.5
const PATH_FIT_MAX_M := 1.5
## Slab depth as span / SPAN_DEPTH_RATIO, at least MIN_DEPTH_M (metres)
## and at most RoadBuilder.DECK_DEPTH_M.
const SPAN_DEPTH_RATIO := 20.0
const MIN_DEPTH_M := 0.5
## Air between a deck's underside and the water it spans, metres.
const WATER_AIR_M := 0.6
## A deck runs this far past its outer roads' edges (edge beam and
## parapet), and fills gaps up to twice DECK_CLOSE_M between them, metres.
const EDGE_BEAM_M := 0.5
const DECK_CLOSE_M := 4.0
## Ways on no outline share a deck when their decks' edges lie within
## twice this, metres.
const LOOSE_CLOSE_M := 2.0
## Barriers stop this far outside an outline (StreetProps).
const BARRIER_GROW_M := 2.0
const PARAPET_THICK_M := 0.25

## One structure: its outline, layer, members and level.
class Structure extends RefCounted:
	var ring := PackedVector2Array()  ## Outline, no closing point.
	var bounds := Rect2()
	var layer := 1
	var kind := "unknown"  ## BridgeArches.structure of the outline's tags.
	var members := PackedInt32Array()  ## RoadBridgeDecks.Index lines on it.
	var rails: Array = []  ## Rail bridge ways on it (RailDecks lays their bed).
	var path := true  ## Every member is a footway or cycleway class.
	var half := 0.0  ## Half width of the widest member.
	var spine := PackedVector2Array()  ## The widest member, resampled.
	var spine_line := -1  ## Its index line.
	var heights := PackedFloat32Array()
	var dist := PackedFloat32Array()  ## Distance along the spine.
	## Members leaving the spine's side (a ramp arm of a T-shaped outline):
	## [points, heights] each, at the main level where they meet it.
	var branches: Array = []
	## How far beside the spine the members running along it reach.
	var reach := 0.0
	## The deck at the spine's two ends where they are abutments (a road
	## goes on from there on the ground), NAN at a joint in mid-air.
	var abutments := Vector2(NAN, NAN)
	## Slab depth, world units: a short beam span is shallower than a long one.
	var depth := 0.9
	var loose := false  ## Cut from ways on no mapped outline.
	## Along each abutment edge: [points, how far the approach's ground
	## lies over (or under) the level there] (BridgeStructures._abutment_fit).
	var fits: Array = []

	## True inside the outline or within `grow` of it.
	func contains(p: Vector2, grow: float = 0.0) -> bool:
		if not bounds.grow(grow).has_point(p):
			return false
		if Geometry2D.is_point_in_polygon(p, ring):
			return true
		if grow <= 0.0:
			return false
		for i in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
			if q.distance_to(p) <= grow:
				return true
		return false

	## [segment, fraction] of the spine point nearest `p`.
	func _foot(p: Vector2) -> Vector2:
		var best := INF
		var out := Vector2.ZERO
		for i in spine.size() - 1:
			var a := spine[i]
			var ab := spine[i + 1] - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			var d := p.distance_squared_to(a + ab * t)
			if d < best:
				best = d
				out = Vector2(i, t)
		return out

	## The structure's level at `p`: the deck of the nearest spine (the
	## main one, or an arm's) at its nearest point.
	func level_at(p: Vector2) -> float:
		var best := main_at(p)
		for b: Array in branches:
			var on := BridgeStructures._on_line(b[0], b[1], p)
			if on.y < best.y:
				best = on
		return best.x

	## The deck's top at `p`: the level, eased over the last BLEND_M before
	## an abutment onto the ground the approach lies on there (the DEM
	## slopes across a road the level cannot follow).
	func surface_at(p: Vector2) -> float:
		var y := level_at(p)
		var best := Vector2(0.0, INF)
		for f: Array in fits:
			var on := BridgeStructures._on_line(f[0], f[1], p)
			if on.y < best.y:
				best = on
		if best.y == INF:
			return y
		# Over BLEND_M, or as far as BLEND_GRADE needs for a larger step.
		var blend := maxf(BridgeStructures.BLEND_M * WorldScale.metres_to_units(), absf(best.x) / BridgeStructures.BLEND_GRADE)
		return y + best.x * (1.0 - smoothstep(0.0, blend, sqrt(best.y)))

	## The main spine's [deck, squared distance] at its point nearest `p`.
	func main_at(p: Vector2) -> Vector2:
		if heights.size() < 2:
			return Vector2(heights[0] if heights.size() == 1 else 0.0, 0.0)
		var f := _foot(p)
		var i := int(f.x)
		var q := spine[i].lerp(spine[i + 1], f.y)
		return Vector2(lerpf(heights[i], heights[i + 1], f.y), q.distance_squared_to(p))

	## Distance along the spine of the point nearest `p`.
	func along(p: Vector2) -> float:
		if dist.size() < 2:
			return 0.0
		var f := _foot(p)
		var i := int(f.x)
		return lerpf(dist[i], dist[i + 1], f.y)

	## Sets the level to `y` between `s0` and `s1` along the spine, eased
	## out at `grade` beyond: raised (`up`) or lowered to it.
	func bump(s0: float, s1: float, y: float, up: bool, grade: float) -> void:
		for k in heights.size():
			var off := maxf(maxf(s0 - dist[k], dist[k] - s1), 0.0)
			if up:
				heights[k] = maxf(heights[k], y - grade * off)
			else:
				heights[k] = minf(heights[k], y + grade * off)

	func grade(m2u: float) -> float:
		return RoadBuilder.PATH_RAMP_GRADE if path and half * 2.0 <= RoadBuilder.PATH_WIDTH_M * m2u \
			else RoadBuilder.RAMP_GRADE

## The structures of one world: outlines with their members, an index of
## them, and their levels once settled.
class Plan extends RefCounted:
	var structures: Array = []  ## Structure each.
	var _of_line := {}  ## Index line -> its Structure.
	var _grid := {}  ## Cell -> Array of Structures whose bounds touch it.
	var _cell := 1.0
	var _ready := false
	var _mutex := Mutex.new()

	func _init(areas: Array = [], index: RoadBridgeDecks.Index = null, railways: Array = []) -> void:
		var m := WorldScale.metres_to_units()
		_cell = BridgeStructures.CELL_M * m
		var all: Array = []
		for a: Variant in areas:
			if not (a is Dictionary):
				continue
			var ring: PackedVector2Array = (a as Dictionary).get("points", PackedVector2Array())
			if ring.size() >= 2 and ring[0].distance_to(ring[ring.size() - 1]) < 0.01 * m:
				ring = ring.slice(0, ring.size() - 1)
			if ring.size() < 3 or absf(_area(ring)) < 1.0 * m * m:
				continue
			var s := Structure.new()
			s.ring = ring
			s.bounds = RingGeometry.aabb(ring)
			s.layer = int((a as Dictionary).get("layer", 1))
			s.kind = BridgeArches.structure(a)
			all.append(s)
		if index == null:
			return
		var grid := _bounds_grid(all)
		for li in index.lines.size():
			var pts: PackedVector2Array = index.lines[li]["points"]
			var best: Structure = null
			var best_share := 0.0
			for s: Structure in _candidates(grid, RingGeometry.aabb(pts)):
				var share := BridgeStructures.inside_share(pts, s)
				if share > best_share:
					best_share = share
					best = s
			if best != null and best_share >= BridgeStructures.MEMBER_SHARE:
				best.members.append(li)
		for w: Variant in railways:
			if not (w is Dictionary) or not bool((w as Dictionary).get("bridge", false)):
				continue
			var rp: PackedVector2Array = (w as Dictionary).get("points", PackedVector2Array())
			if rp.size() < 2:
				continue
			for s: Structure in _candidates(grid, RingGeometry.aabb(rp)):
				if BridgeStructures.inside_share(rp, s) >= BridgeStructures.MEMBER_SHARE:
					s.rails.append(w)
					break
		# Road bridge ways on no outline: each deck is cut from the roads
		# themselves. Ways whose edges nearly touch (a road and the footway
		# on it) share one; separate carriageways side by side stand each on
		# their own, held to their own approaches. A footbridge alone keeps
		# RoadBridgeDecks and its own ramps.
		var taken := {}
		for s: Structure in all:
			for li in s.members:
				taken[li] = true
		var free := PackedInt32Array()
		for li in index.lines.size():
			if not taken.has(li):
				free.append(li)
		for ring: PackedVector2Array in BridgeStructureSlab._deck_pieces(free, index, m, BridgeStructures.LOOSE_CLOSE_M * m):
			var s := Structure.new()
			s.ring = ring
			s.bounds = RingGeometry.aabb(ring)
			s.loose = true
			var road := false
			for li in free:
				if not taken.has(li) and s.bounds.intersects(RingGeometry.aabb(index.lines[li]["points"]), true) \
						and BridgeStructures.inside_share(index.lines[li]["points"], s) >= BridgeStructures.MEMBER_SHARE:
					s.members.append(li)
					road = road or not (str(index.lines[li]["cls"]) in RoadBridgeDecks.PATH_CLASSES)
			if road:
				for li in s.members:
					taken[li] = true
				all.append(s)
		# An outline carrying no road (a rail bridge, an unmapped deck) is
		# left to RailDecks and the ways themselves; a masonry bridge keeps
		# its arches (RoadBridgeBuild._bridge).
		for s: Structure in all:
			var masonry := s.kind == "masonry"
			for li in s.members:
				masonry = masonry or BridgeArches.structure(index.lines[li]["road"]) == "masonry"
			if s.members.is_empty() or masonry:
				continue
			if not s.loose:
				BridgeStructureSlab._fit_deck(s, index, m)
			var on := PackedInt32Array()
			for li in s.members:
				if BridgeStructures.inside_share(index.lines[li]["points"], s) >= BridgeStructures.MEMBER_SHARE:
					on.append(li)
			s.members = on
			if on.is_empty():
				continue
			var top := -100
			for li in s.members:
				top = maxi(top, int(index.lines[li]["layer"]))
				s.half = maxf(s.half, float(index.lines[li]["half"]))
				s.path = s.path and str(index.lines[li]["cls"]) in RoadBridgeDecks.PATH_CLASSES
				_of_line[li] = s
			s.layer = top
			structures.append(s)
		_grid = _bounds_grid(structures)

	## Signed area of a ring (shoelace).
	static func _area(ring: PackedVector2Array) -> float:
		var a := 0.0
		for i in ring.size():
			var p := ring[i]
			var q := ring[(i + 1) % ring.size()]
			a += p.x * q.y - q.x * p.y
		return a * 0.5

	func _bounds_grid(list: Array) -> Dictionary:
		var grid := {}
		for s: Structure in list:
			for cx in range(floori(s.bounds.position.x / _cell), floori(s.bounds.end.x / _cell) + 1):
				for cz in range(floori(s.bounds.position.y / _cell), floori(s.bounds.end.y / _cell) + 1):
					var key := Vector2i(cx, cz)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append(s)
		return grid

	func _candidates(grid: Dictionary, box: Rect2) -> Array:
		var out: Array = []
		for cx in range(floori(box.position.x / _cell), floori(box.end.x / _cell) + 1):
			for cz in range(floori(box.position.y / _cell), floori(box.end.y / _cell) + 1):
				for s: Structure in (grid.get(Vector2i(cx, cz), []) as Array):
					if not out.has(s) and s.bounds.intersects(box, true):
						out.append(s)
		return out

	## Structures whose bounds lie within `reach` of `p`.
	func near(p: Vector2, reach: float = 0.0) -> Array:
		return _candidates(_grid, Rect2(p - Vector2(reach, reach), Vector2(reach, reach) * 2.0))

	## The structure index line `li` is a member of, or null.
	func of_line(li: int) -> Structure:
		return _of_line.get(li, null)

	## Drops the structures a registry bridge's model carries (any member
	## inside one of LandmarkSites.bridge_spans): their ways go back to
	## RoadBuilder, which leaves the span to the model.
	func exclude_spans(spans: Array, index: RoadBridgeDecks.Index, m2u: float) -> void:
		if spans.is_empty():
			return
		var kept: Array = []
		for s: Structure in structures:
			var covered := false
			for li in s.members:
				var dense := RoadBuilder._resample(index.lines[li]["points"], 2.0 * m2u)
				var outside := 0
				for piece: PackedVector2Array in LandmarkSites.outside_spans(dense, spans):
					outside += piece.size()
				covered = covered or outside < dense.size()
			if covered:
				for li in s.members:
					_of_line.erase(li)
			else:
				kept.append(s)
		structures = kept
		_grid = _bounds_grid(structures)

	## Levels every structure and settles their crossings, once.
	func prepare(surf: RoadBuilder._Surface, m2u: float) -> void:
		_mutex.lock()
		if not _ready:
			var index: RoadBridgeDecks.Index = surf.road_bridges
			for s: Structure in structures:
				BridgeStructures._level(s, index, surf, m2u)
			BridgeStructures._settle(self, index, surf, m2u)
			for s: Structure in structures:
				BridgeStructures._branches(s, index, surf, m2u)
				BridgeStructures._abutment_fit(s, index, surf, m2u)
			_ready = true
		_mutex.unlock()

## Share of polyline `pts`'s length inside `s`'s outline (ON_M grown).
static func inside_share(pts: PackedVector2Array, s: Structure) -> float:
	var total := 0.0
	var inside := 0.0
	var on := ON_M * WorldScale.metres_to_units()
	for i in range(1, pts.size()):
		var len := pts[i].distance_to(pts[i - 1])
		var n := maxi(1, ceili(len / (2.0 * WorldScale.metres_to_units())))
		for k in n:
			var p := pts[i - 1].lerp(pts[i], (float(k) + 0.5) / float(n))
			total += len / float(n)
			if s.contains(p, on):
				inside += len / float(n)
	return inside / total if total > 0.0 else 0.0

## The spine and its level: the longest of the widest members (roads
## before paths), its deck
## profile at the road grade (ends at the bank or the approach, a land
## viaduct's layer clearance), raised to every other widest member's deck
## beside it, so twin carriageways on one structure meet.
static func _level(s: Structure, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface, m2u: float) -> void:
	# The widest members of the structure's own kind: a road's carriageway
	# when it carries one (a cycleway as wide as a one-lane road beside it,
	# or a long ramp arm, does not set a road's level), else its paths.
	var widest := 0.0
	for li in s.members:
		if s.path or not (str(index.lines[li]["cls"]) in RoadBridgeDecks.PATH_CLASSES):
			widest = maxf(widest, float(index.lines[li]["half"]))
	var leads: Array[int] = []
	for li in s.members:
		if (s.path or not (str(index.lines[li]["cls"]) in RoadBridgeDecks.PATH_CLASSES)) \
				and float(index.lines[li]["half"]) >= widest - RoadBridgeDecks.SAME_WIDTH_M * m2u:
			leads.append(li)
	var spine_li := leads[0]
	for li in leads:
		if _length(index.lines[li]["points"]) > _length(index.lines[spine_li]["points"]):
			spine_li = li
	var line: Dictionary = index.lines[spine_li]
	s.spine_line = spine_li
	s.spine = RoadBuilder._resample(line["points"], SPINE_STEP_M * m2u)
	s.heights = _own(s.spine, line, surf, m2u)
	s.dist = PackedFloat32Array([0.0])
	for i in range(1, s.spine.size()):
		s.dist.append(s.dist[i - 1] + s.spine[i].distance_to(s.spine[i - 1]))
	# A beam's depth runs about a twentieth of its span: a 13 m creek
	# bridge is a 0.65 m slab, not the 0.9 m of a long viaduct.
	s.depth = clampf(s.dist[s.dist.size() - 1] / m2u / SPAN_DEPTH_RATIO, MIN_DEPTH_M,
		RoadBuilder.DECK_DEPTH_M) * m2u
	var reach := RoadBridgeDecks.GROUP_REACH_M * m2u
	for li in leads:
		if li == spine_li:
			continue
		var other: Dictionary = index.lines[li]
		var dense := RoadBuilder._resample(other["points"], SPINE_STEP_M * m2u)
		var deck := _own(dense, other, surf, m2u)
		if deck.size() != dense.size():
			continue
		for i in s.spine.size():
			var k := _closest(dense, s.spine[i])
			if k == 0 or k == dense.size() - 1 or dense[k].distance_to(s.spine[i]) > reach:
				continue
			s.heights[i] = maxf(s.heights[i], deck[k])
	# An end a road goes on from on the ground is an abutment, whatever
	# other bridge way also ends there (a link leaving the same node, a
	# path bridge on another layer passing by): the deck meets the ground
	# there. Taken for joints, the spine's own profile stood up there at
	# the layer's clearance.
	var n := s.spine.size()
	if n >= 2:
		var slab := (RoadBuilder.DECK_DEPTH_M + 0.5) * m2u
		for end: Array in [[0, 1], [n - 1, n - 2]]:
			var i := int(end[0])
			var p := s.spine[i]
			var road := BridgeLandings.approach_from(surf, p, (p - s.spine[int(end[1])]).normalized())
			if road.is_empty():
				continue
			var y := RoadBridgeBuild._deck_floor(s.spine, i, surf, slab, s.half) + 0.05 * m2u
			# The approach's ribbon starts at its first dry point (RoadBuilder
			# drops it over water): a bank carved down under the end is not
			# where the road is.
			var dry := _first_dry(road, surf, ABUTMENT_SEEK_M * m2u)
			if not is_nan(dry):
				y = dry + 0.05 * m2u
			if i == 0:
				s.abutments.x = y
			else:
				s.abutments.y = y

## The approach's ground where the deck meets it: the ground at the way's
## end, or where that is over water, the highest dry ground along `line`
## within `reach` (its embankment's top: the first dry point can be the
## foot of the bank), or NAN.
static func _first_dry(line: PackedVector2Array, surf: RoadBuilder._Surface, reach: float) -> float:
	var dense := RoadBuilder._resample(line, 1.0 * WorldScale.metres_to_units())
	if surf.ground.water_at(dense[0].x, dense[0].y) <= 0.0:
		return surf.height(dense[0].x, dense[0].y)  # The road starts right at the deck's end.
	var run := 0.0
	var best := NAN
	for i in dense.size():
		if i > 0:
			run += dense[i].distance_to(dense[i - 1])
		if run > reach:
			break
		if surf.ground.water_at(dense[i].x, dense[i].y) <= 0.0:
			var h := surf.height(dense[i].x, dense[i].y)
			best = h if is_nan(best) else maxf(best, h)
	return best

## Samples every abutment edge (an open end where a member ends) every
## metre: how far the ground the approach lies on stands over the level
## there (at most FIT_MAX_M, none over water), smoothed along the edge.
## surface_at eases the deck onto it, so the deck meets the road across
## its whole width.
static func _abutment_fit(s: Structure, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface, m2u: float) -> void:
	var opens := _openings(s, index, surf, m2u)
	var lift := 0.05 * m2u
	for e in s.ring.size():
		var a := s.ring[e]
		var b := s.ring[(e + 1) % s.ring.size()]
		for run: Array in _runs(opens[e] as Array):
			if int(run[2]) != 2:
				continue
			var pa := a.lerp(b, float(run[0]))
			var pb := a.lerp(b, float(run[1]))
			var most := FIT_MAX_M * m2u
			if _ends_path(s, index, (pa + pb) * 0.5):
				most = PATH_FIT_MAX_M * m2u
			var n := maxi(1, ceili(pa.distance_to(pb) / m2u))
			var pts := PackedVector2Array()
			var dy := PackedFloat32Array()
			for k in n + 1:
				var p := pa.lerp(pb, float(k) / float(n))
				var d := clampf(surf.height(p.x, p.y) + lift - s.level_at(p), -most, most)
				pts.append(p)
				dy.append(0.0 if surf.ground.water_at(p.x, p.y) > 0.0 else d)
			# Smoothed along the edge: the deck bends, it does not kink.
			for pass_i in 2:
				var was := dy.duplicate()
				for k in range(1, dy.size() - 1):
					dy[k] = (was[k - 1] + was[k] * 2.0 + was[k + 1]) * 0.25
			s.fits.append([pts, dy])

## Lifts the slab clear of the water it spans (its depth and WATER_AIR_M
## under it), eased out at the ramp grade, before _pin holds it to its
## abutments: where the DEM carves the approach down to the water's edge
## the road meeting its deck wins, and the deck clears the water only as
## far as the ramp grade from its ends allows.
static func _over_water(s: Structure, surf: RoadBuilder._Surface, m2u: float) -> void:
	var g := s.grade(m2u)
	var air := s.depth + WATER_AIR_M * m2u
	for k in s.spine.size():
		var p := s.spine[k]
		if surf.ground.water_at(p.x, p.y) <= 0.0:
			continue
		var need := surf.ground.water_level_at(p.x, p.y) + air
		if s.heights[k] < need:
			s.bump(s.dist[k], s.dist[k], need, true, g)

## True when the member ending nearest `p` is a footway or cycleway.
static func _ends_path(s: Structure, index: RoadBridgeDecks.Index, p: Vector2) -> bool:
	var best := INF
	var path := false
	for li in s.members:
		var pts: PackedVector2Array = index.lines[li]["points"]
		for q: Vector2 in [pts[0], pts[pts.size() - 1]]:
			if q.distance_squared_to(p) < best:
				best = q.distance_squared_to(p)
				path = str(index.lines[li]["cls"]) in RoadBridgeDecks.PATH_CLASSES
	return path

## Holds a structure to its abutments: within the ramp grade of the
## approach at each end, both ways, and on the straight line between two
## abutments the grade cannot span. A crossing's rise eased out
## past the abutment left the deck standing over the road it meets (the
## DEM's valley under a low creek bridge is shallower than the real one);
## what clearance that costs is taken by the way under it.
static func _pin(s: Structure, m2u: float) -> void:
	var g := s.grade(m2u)
	var total := maxf(s.dist[s.dist.size() - 1], 1e-6)
	var ax := s.abutments.x
	var ay := s.abutments.y
	for k in s.heights.size():
		var d := s.dist[k]
		var cap := INF
		var low := -INF
		if not is_nan(ax):
			cap = minf(cap, ax + g * d)
			low = maxf(low, ax - g * d)
		if not is_nan(ay):
			cap = minf(cap, ay + g * (total - d))
			low = maxf(low, ay - g * (total - d))
		# Abutments further apart in height than the grade spans: the girder
		# runs straight from one to the other, meeting both.
		if not is_nan(ax) and not is_nan(ay):
			var line := lerpf(ax, ay, d / total)
			cap = maxf(cap, line)
			low = minf(low, line)
		s.heights[k] = clampf(s.heights[k], low, maxf(cap, low))

## Members leaving the spine's side become arms: a member running beside
## the spine (twin carriageways, a link, a cycleway alongside) stands at
## the main level, but one that leaves it (the ramp arm of a T-shaped
## footbridge outline) ramps straight from the main level, where it meets
## the spine's members, to its own far end (the path it lands on), never
## under the ground or into the water. Held at the main level it ran flat
## to its far end and stepped down to the path there; on its own viaduct
## profile it humped up to the layer's clearance and back.
static func _branches(s: Structure, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface, m2u: float) -> void:
	s.reach = s.half
	var arms: Array = []
	for li in s.members:
		if li == s.spine_line:
			continue
		var line: Dictionary = index.lines[li]
		var dense := RoadBuilder._resample(line["points"], SPINE_STEP_M * m2u)
		var far := 0.0
		for p in dense:
			far = maxf(far, sqrt(s.main_at(p).y))
		var half := float(line["half"])
		if far <= s.half + half + RoadBridgeDecks.BESIDE_GAP_M * m2u:
			s.reach = maxf(s.reach, far + half)
		else:
			arms.append([line, dense])
	for arm: Array in arms:
		var line: Dictionary = arm[0]
		var dense: PackedVector2Array = arm[1]
		var own := _own(dense, line, surf, m2u)
		var n := dense.size()
		# Anchors: the points beside the spine's members at the main level,
		# and the arm's own two ends; straight ramps run between them.
		var anchor := PackedByteArray()
		anchor.resize(n)
		var deck := own.duplicate()
		var reach := s.reach + float(line["half"])
		for i in n:
			var on := s.main_at(dense[i])
			if sqrt(on.y) <= reach:
				deck[i] = on.x
				anchor[i] = 1
		# A free end lands on the ground, at the path that goes on from it
		# where one does.
		for end: Array in [[0, 1], [n - 1, n - 2]]:
			var i := int(end[0])
			if anchor[i] != 0:
				continue
			anchor[i] = 1
			var p := dense[i]
			var road := BridgeLandings.approach_from(surf, p, (p - dense[int(end[1])]).normalized())
			if road.is_empty() and (surf.bridge_joint(p, (p - dense[int(end[1])]).normalized())
					or surf.ground.water_at(p.x, p.y) > 0.0):
				continue  # It goes on as another bridge, or over the water.
			var dry := _first_dry(road, surf, ABUTMENT_SEEK_M * m2u) if not road.is_empty() else NAN
			deck[i] = (dry if not is_nan(dry) else surf.height(p.x, p.y)) + 0.05 * m2u
		var along := RoadBridgeBuild._dist_of(dense)
		var prev := 0
		for i in range(1, n):
			if anchor[i] == 0:
				continue
			for k in range(prev + 1, i):
				deck[k] = lerpf(deck[prev], deck[i], (along[k] - along[prev]) / maxf(along[i] - along[prev], 1e-6))
			prev = i
		var slab := (RoadBuilder.DECK_DEPTH_M + 0.5) * m2u
		for i in n:
			deck[i] = maxf(deck[i], RoadBridgeBuild._deck_floor(dense, i, surf, slab, 0.0))
		s.branches.append([dense, deck])

## [deck, squared distance] of polyline `pts` (decks `hs`) at its point
## nearest `p`.
static func _on_line(pts: PackedVector2Array, hs: PackedFloat32Array, p: Vector2) -> Vector2:
	var best := Vector2(hs[0] if not hs.is_empty() else 0.0, INF)
	for i in pts.size() - 1:
		var ab := pts[i + 1] - pts[i]
		var t := clampf((p - pts[i]).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var d := p.distance_squared_to(pts[i] + ab * t)
		if d < best.y:
			best = Vector2(lerpf(hs[i], hs[i + 1], t), d)
	return best

## A line's own deck profile (as RoadBridgeDecks.Index.profile makes it).
static func _own(pts: PackedVector2Array, line: Dictionary, surf: RoadBuilder._Surface, m2u: float) -> PackedFloat32Array:
	var deck := RoadBridgeBuild.deck_profile(pts, surf, m2u,
		RoadBridgeDecks.grade_half(float(line["half"]), str(line["cls"]), m2u), int(line["layer"]))
	if deck.size() != pts.size():
		deck.resize(pts.size())
		for i in pts.size():
			deck[i] = surf.height(pts[i].x, pts[i].y)
	return deck

## Crossings, settled once: a structure rises where something under it
## cannot dip far enough (to that thing's floor plus HIDE_M) and clear of
## the water it spans, held down to its abutments (_pin), then every
## structure dips under the decks over it (their level less the
## clearance, down to its floor). Bridge ways on no outline dip under a
## structure themselves (RoadBridgeDecks._cross); the structure rises
## for them here when they cannot.
static func _settle(plan: Plan, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface, m2u: float) -> void:
	var margin := 1.0 * m2u
	for s: Structure in plan.structures:
		var g := s.grade(m2u)
		for o: Structure in plan.near(s.bounds.get_center(), s.bounds.size.length() * 0.5):
			if o.layer >= s.layer:
				continue
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(s.ring, o.ring):
				_rise_over(s, piece, func(p: Vector2) -> float: return o.level_at(p), o.path, g, margin, surf, m2u)
		for li in _lines_near(index, s, m2u):
			var line: Dictionary = index.lines[li]
			if plan.of_line(li) != null or int(line["layer"]) >= s.layer:
				continue
			var under := PackedVector2Array()
			var prof := index.profile(li, surf, m2u)
			var dense: PackedVector2Array = prof[0]
			var deck: PackedFloat32Array = prof[1]
			if deck.size() != dense.size():
				continue
			for p in dense:
				if s.contains(p, float(line["half"])):
					under.append(p)
			if not under.is_empty():
				_rise_over(s, under, func(p: Vector2) -> float: return deck[BridgeStructures._closest(dense, p)],
					str(line["cls"]) in RoadBridgeDecks.PATH_CLASSES, g, margin, surf, m2u)
		_over_water(s, surf, m2u)
		_pin(s, m2u)
	for s: Structure in plan.structures:
		var g := s.grade(m2u)
		for o: Structure in plan.near(s.bounds.get_center(), s.bounds.size.length() * 0.5):
			if o.layer <= s.layer:
				continue
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(s.ring, o.ring):
				var clear := (RoadBridgeDecks.CLEAR_PATH_M if s.path else RoadBridgeDecks.CLEAR_ROAD_M) * m2u
				var target := INF
				var s0 := INF
				var s1 := -INF
				for p in piece:
					target = minf(target, maxf(o.level_at(p) - clear, RoadBridgeDecks._floor_at(p, surf, m2u, s.path)))
					s0 = minf(s0, s.along(p))
					s1 = maxf(s1, s.along(p))
				if target < INF:
					s.bump(s0 - margin, s1 + margin, target, false, g)

## Raises `s` over the points `pts` of something lower whose deck is
## `low.call(p)`, where that cannot dip CLEAR_* under it: to its floor
## plus HIDE_M (RoadBridgeDecks._cross makes the same call per way).
static func _rise_over(s: Structure, pts: PackedVector2Array, low: Callable, low_path: bool, g: float,
		margin: float, surf: RoadBuilder._Surface, m2u: float) -> void:
	var clear := (RoadBridgeDecks.CLEAR_PATH_M if low_path else RoadBridgeDecks.CLEAR_ROAD_M) * m2u
	var need := -INF
	var s0 := INF
	var s1 := -INF
	for p in pts:
		var u := s.level_at(p)
		var want := RoadBridgeDecks._floor_at(p, surf, m2u, low_path) + RoadBridgeDecks.HIDE_M * m2u
		if float(low.call(p)) > u - clear and u < want:
			need = maxf(need, want)
		s0 = minf(s0, s.along(p))
		s1 = maxf(s1, s.along(p))
	if need > -INF:
		s.bump(s0 - margin, s1 + margin, need, true, g)

## Index lines with a segment near `s`'s outline.
static func _lines_near(index: RoadBridgeDecks.Index, s: Structure, m2u: float) -> Array:
	var seen := {}
	var c := s.bounds.get_center()
	var segs := index.near(c, s.bounds.size.length() * 0.5 + 10.0 * m2u)
	for k in range(0, segs.size(), 2):
		seen[segs[k]] = true
	return seen.keys()

static func _length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	return total

static func _closest(dense: PackedVector2Array, q: Vector2) -> int:
	var k := 0
	for c in dense.size():
		if dense[c].distance_squared_to(q) < dense[k].distance_squared_to(q):
			k = c
	return k

## Builds every structure of `surf`'s world into `batches`: the slab, its
## parapets and abutments, then each member's asphalt and paint on it.
static func build(batches: Dictionary, surf: RoadBuilder._Surface, m2u: float) -> void:
	var index: RoadBridgeDecks.Index = surf.road_bridges
	if index == null or index.structures == null or index.structures.structures.is_empty():
		return
	var plan: Plan = index.structures
	plan.prepare(surf, m2u)
	for s: Structure in plan.structures:
		if not surf.inside(s.bounds.get_center()):
			continue
		var opens := _openings(s, index, surf, m2u)
		BridgeStructureSlab._slab(batches, s, surf, m2u)
		BridgeStructureSlab._edges(batches, s, opens, index, surf, m2u)
		for li in s.members:
			BridgeStructureMembers.lay(batches, s, index.lines[li], surf, m2u)

## Per outline edge, the [from, to, end] stretches (fractions along the
## edge) a member road leaves through: no parapet there. `end` marks a
## member's mapped end (an abutment) rather than a way running on.
static func _openings(s: Structure, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface, m2u: float) -> Array:
	var out: Array = []
	out.resize(s.ring.size())
	for e in s.ring.size():
		out[e] = []
	var pad := OPEN_PAD_M * m2u
	var reach := END_REACH_M * m2u
	for li in s.members:
		var line: Dictionary = index.lines[li]
		var pts: PackedVector2Array = line["points"]
		var half := float(line["half"])
		# The way extended past both mapped ends: an end a little inside
		# the outline still opens the edge it faces.
		var ext := pts.duplicate()
		ext[0] = pts[0] + (pts[0] - pts[1]).normalized() * reach
		ext[ext.size() - 1] = pts[pts.size() - 1] + (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized() * reach
		for e in s.ring.size():
			var a := s.ring[e]
			var b := s.ring[(e + 1) % s.ring.size()]
			var ab := b - a
			var len := ab.length()
			if len < 1e-6:
				continue
			for j in range(1, ext.size()):
				var hit: Variant = Geometry2D.segment_intersects_segment(ext[j - 1], ext[j], a, b)
				if hit == null:
					continue
				var dir := (ext[j] - ext[j - 1]).normalized()
				var sin_a := maxf(absf(dir.cross(ab / len)), 0.3)
				var w := (half / sin_a + pad) / len
				var t := ((hit as Vector2) - a).dot(ab) / (len * len)
				# 2: an abutment (a road goes on from this end on the ground);
				# 1: an end joining another bridge in mid-air; 0: a way running on.
				var end := 0
				if j == 1 or j == ext.size() - 1:
					var first := j == 1 and (j != ext.size() - 1 \
						or (hit as Vector2).distance_squared_to(pts[0]) <= (hit as Vector2).distance_squared_to(pts[pts.size() - 1]))
					var at := pts[0] if first else pts[pts.size() - 1]
					var back := pts[1] if first else pts[pts.size() - 2]
					end = 1 if BridgeLandings.approach_from(surf, at, (at - back).normalized()).is_empty() else 2
				(out[e] as Array).append([t - w, t + w, end])
	# An abutment is the whole end of the outline, not only the road's
	# width: a chain of edges across the spine where a member ends opens
	# from corner to corner (mapped with the way's end node in its middle,
	# the shoulders kept parapets standing across the carriageway).
	var across := PackedByteArray()
	across.resize(s.ring.size())
	for e in s.ring.size():
		var a := s.ring[e]
		var b := s.ring[(e + 1) % s.ring.size()]
		if a.distance_to(b) > 1e-6:
			across[e] = 1 if absf((b - a).normalized().dot(_direction_near(s, (a + b) * 0.5))) < END_DOT else 0
	for e in s.ring.size():
		if across[e] == 0 or across[(e + s.ring.size() - 1) % s.ring.size()] != 0:
			continue
		var chain: Array[int] = []
		var k := e
		while across[k] != 0 and chain.size() < s.ring.size():
			chain.append(k)
			k = (k + 1) % s.ring.size()
		var ends := 0
		for c in chain:
			for o: Array in out[c]:
				ends = maxi(ends, int(o[2]))
		if ends > 0:
			for c in chain:
				out[c] = [[0.0, 1.0, ends]]
	return out

## Unit direction of the spine (main or arm) nearest `p`.
static func _direction_near(s: Structure, p: Vector2) -> Vector2:
	var best := INF
	var dir := Vector2.RIGHT
	var lines: Array = [s.spine]
	for br: Array in s.branches:
		lines.append(br[0])
	for line: PackedVector2Array in lines:
		for i in line.size() - 1:
			var ab := line[i + 1] - line[i]
			if ab.length_squared() < 1e-9:
				continue
			var q := Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])
			var d := q.distance_squared_to(p)
			if d < best:
				best = d
				dir = ab.normalized()
	return dir

## An edge's [from, to, kind] runs covering 0..1: 0 a parapet, 1 open
## (a way runs on), 2 an abutment (a member ends there).
static func _runs(opens: Array) -> Array:
	var cuts: Array = []
	for o: Array in opens:
		var lo := clampf(float(o[0]), 0.0, 1.0)
		var hi := clampf(float(o[1]), 0.0, 1.0)
		if hi > lo:
			cuts.append([lo, hi, 2 if int(o[2]) == 2 else 1])
	cuts.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var out: Array = []
	var at := 0.0
	for c: Array in cuts:
		if float(c[0]) > at:
			out.append([at, float(c[0]), 0])
		var from := maxf(at, float(c[0]))
		if float(c[1]) > from:
			out.append([from, float(c[1]), int(c[2])])
		at = maxf(at, float(c[1]))
	if at < 1.0:
		out.append([at, 1.0, 0])
	return out

## The structures a barrier must stop short of: every outline of the
## world's bridge areas, grown by BARRIER_GROW_M ([ring, bounds] each).
static func barrier_rings(data: LocationData, m2u: float) -> Array:
	var out: Array = []
	var grow := BARRIER_GROW_M * m2u
	for a: Variant in data.bridge_areas:
		if not (a is Dictionary):
			continue
		var ring: PackedVector2Array = (a as Dictionary).get("points", PackedVector2Array())
		if ring.size() < 4:
			continue
		# The grown outline: the largest ring offset_polygon returns (any
		# other is a hole it left).
		var best := PackedVector2Array()
		for g: PackedVector2Array in Geometry2D.offset_polygon(ring, grow):
			if absf(Plan._area(g)) > absf(Plan._area(best)):
				best = g
		if best.size() >= 3:
			out.append([best, RingGeometry.aabb(best)])
	return out

## True where `p` lies inside one of `rings` (barrier_rings).
static func in_rings(p: Vector2, rings: Array) -> bool:
	for r: Array in rings:
		if (r[1] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, r[0]):
			return true
	return false
