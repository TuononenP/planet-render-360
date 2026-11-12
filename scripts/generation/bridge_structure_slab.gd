class_name BridgeStructureSlab
extends RefCounted

## The concrete of a bridge structure (BridgeStructures): the deck's shape
## cut to the roads it carries, its slab in cells that follow the deck
## top, and along the outline's
## edges the fascia, the parapets (railings beside a footway or cycleway)
## and, under an open end, the abutment wall down to the ground.

## A deck edge carries a parapet where the ground BESIDE_M out from it
## lies more than DROP_M under the deck, metres.
const BESIDE_M := 1.0
const DROP_M := 0.6
## How far a deck's edge beam stands out past its parapet, metres.
const EDGE_BEAM_LIP_M := 0.12

## True when the member running nearest `p` is a footway or cycleway.
static func _beside_path(s: BridgeStructures.Structure, index: RoadBridgeDecks.Index, p: Vector2) -> bool:
	var best := INF
	var path := false
	for li in s.members:
		var pts: PackedVector2Array = index.lines[li]["points"]
		for i in pts.size() - 1:
			var d := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1]).distance_squared_to(p)
			if d < best:
				best = d
				path = str(index.lines[li]["cls"]) in RoadBridgeDecks.PATH_CLASSES
	return path

## The outline's top and underside, cut in cells about SLICE_M square
## (_slices) so the slab follows the deck top (BridgeStructures.Structure.surface_at).
static func _slab(batches: Dictionary, s: BridgeStructures.Structure, surf: RoadBuilder._Surface, m2u: float) -> void:
	var top := RoadBuilder._batch(batches, "bridge")
	var side := RoadBuilder._batch(batches, "deck")
	var depth := s.depth
	for piece: PackedVector2Array in _slices(s, m2u):
		var tri := Geometry2D.triangulate_polygon(piece)
		if tri.is_empty():
			continue
		top.pad()
		var kt := top.verts.size()
		var ks := side.verts.size()
		for p in piece:
			var y := s.surface_at(p)
			top.verts.append(Vector3(p.x, y, p.y))
			top.normals.append(Vector3.UP)
			top.uvs.append(p / m2u / 4.0)
			side.verts.append(Vector3(p.x, y - depth, p.y))
			side.normals.append(Vector3.DOWN)
			side.uvs.append(p / m2u / 4.0)
		top.pad()
		for t in range(0, tri.size(), 3):
			_tri(top, kt + tri[t], kt + tri[t + 1], kt + tri[t + 2], true)
			_tri(side, ks + tri[t], ks + tri[t + 1], ks + tri[t + 2], false)

## Triangle a-b-c wound to face up (`up`) or down.
static func _tri(b: RoadBuilder._Batch, a: int, bb: int, c: int, up: bool) -> void:
	var front := (b.verts[c] - b.verts[a]).cross(b.verts[bb] - b.verts[a])
	if (front.y >= 0.0) == up:
		b.indices.push_back(a); b.indices.push_back(bb); b.indices.push_back(c)
	else:
		b.indices.push_back(a); b.indices.push_back(c); b.indices.push_back(bb)

## The outline cut into cells about BridgeStructures.SLICE_M square, aligned with the
## spine's chord, so the slab's vertices follow the level along the spine
## and along any arm leaving it. A large outline takes larger cells (at
## most BridgeStructures.MAX_CELLS of them).
static func _slices(s: BridgeStructures.Structure, m2u: float) -> Array:
	var axis := (s.spine[s.spine.size() - 1] - s.spine[0])
	axis = axis.normalized() if axis.length() > 0.01 * m2u else Vector2.RIGHT
	var across := Vector2(-axis.y, axis.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in s.ring:
		var q := Vector2((p - s.spine[0]).dot(axis), (p - s.spine[0]).dot(across))
		lo = lo.min(q)
		hi = hi.max(q)
	var size := hi - lo
	var step := maxf(BridgeStructures.SLICE_M * m2u, sqrt(size.x * size.y / float(BridgeStructures.MAX_CELLS)))
	var nx := maxi(1, ceili(size.x / step))
	var nz := maxi(1, ceili(size.y / step))
	if nx * nz == 1:
		return [s.ring]
	var out: Array = []
	var pad := 0.5 * m2u
	for i in nx:
		for k in nz:
			# Cells overlap by a hair inside and reach past the outline outside.
			var x0 := lo.x + size.x * float(i) / float(nx) - (pad if i == 0 else 0.0)
			var x1 := lo.x + size.x * float(i + 1) / float(nx) + (pad if i == nx - 1 else 0.0)
			var z0 := lo.y + size.y * float(k) / float(nz) - (pad if k == 0 else 0.0)
			var z1 := lo.y + size.y * float(k + 1) / float(nz) + (pad if k == nz - 1 else 0.0)
			var o := s.spine[0]
			var cell := PackedVector2Array([o + axis * x0 + across * z0, o + axis * x1 + across * z0,
				o + axis * x1 + across * z1, o + axis * x0 + across * z1])
			out.append_array(Geometry2D.intersect_polygons(s.ring, cell))
	return out

## Fascia, parapets and abutments along the outline's edges: a parapet
## (a railing beside a footway or cycleway) wherever no member leaves
## through the edge, and where one does,
## the slab's bare face over the abutment wall down to the ground.
static func _edges(batches: Dictionary, s: BridgeStructures.Structure, opens: Array, index: RoadBridgeDecks.Index,
		surf: RoadBuilder._Surface, m2u: float) -> void:
	var side := RoadBuilder._batch(batches, "deck")
	var depth := s.depth
	var para := RoadBuilder.PARAPET_M * m2u
	var thick := BridgeStructures.PARAPET_THICK_M * m2u
	for e in s.ring.size():
		var a := s.ring[e]
		var b := s.ring[(e + 1) % s.ring.size()]
		var len := a.distance_to(b)
		if len < 0.01 * m2u:
			continue
		var out := Vector2(-(b - a).y, (b - a).x).normalized()
		if Geometry2D.is_point_in_polygon((a + b) * 0.5 + out * 0.05 * m2u, s.ring):
			out = -out
		for run: Array in BridgeStructures._runs(opens[e] as Array):
			var t0 := float(run[0])
			var t1 := float(run[1])
			var kind := int(run[2])  # 0 parapet, 1 open, 2 abutment
			var n := maxi(1, ceili((t1 - t0) * len / (BridgeStructures.SLICE_M * m2u)))
			for k in n:
				var pa := a.lerp(b, lerpf(t0, t1, float(k) / float(n)))
				var pb := a.lerp(b, lerpf(t0, t1, float(k + 1) / float(n)))
				var ya := s.surface_at(pa)
				var yb := s.surface_at(pb)
				if kind != 0:
					RoadBuilder._wall(side, pa, pb, ya - depth, yb - depth, ya, yb, out)
					# The abutment wall down to the ground under an end a road
					# goes on from, seen from under the deck and from the bank
					# beside it. Not at a joint with another bridge in mid-air,
					# and never across the water: the creek runs on under the deck.
					var ga := surf.height(pa.x, pa.y) - 0.3 * m2u
					var gb := surf.height(pb.x, pb.y) - 0.3 * m2u
					var wet := surf.ground.water_at(pa.x, pa.y) > 0.0 or surf.ground.water_at(pb.x, pb.y) > 0.0
					if kind == 2 and not wet and (ga < ya - depth or gb < yb - depth):
						RoadBuilder._wall(side, pa, pb, ga, gb, ya - depth, yb - depth, -out)
						RoadBuilder._wall(side, pa, pb, ga, gb, ya - depth, yb - depth, out)
					continue
				# No parapet where the deck's edge lies on the ground (the step
				# between two roads' staggered ends, a deck let into its bank):
				# a wall there stood on the approach road.
				var beside := (pa + pb) * 0.5 + out * BESIDE_M * m2u
				if surf.ground.water_at(beside.x, beside.y) <= 0.0 \
						and surf.height(beside.x, beside.y) > minf(ya, yb) - DROP_M * m2u:
					RoadBuilder._wall(side, pa, pb, ya - depth, yb - depth, ya, yb, out)
					continue
				if _beside_path(s, index, (pa + pb) * 0.5):
					# A footway or cycleway edge: the slab's face and a railing.
					RoadBuilder._wall(side, pa, pb, ya - depth, yb - depth, ya, yb, out)
					RoadBridgeBuild.railing(side, pa - out * thick * 0.5, pb - out * thick * 0.5, ya, yb, out, m2u)
					continue
				var ia := pa - out * thick
				var ib := pb - out * thick
				# The edge beam stands a little proud of the parapet and its
				# face is textured on its own: one wall from the waterline to
				# the parapet's top read as a fence, not a bridge.
				var lip := out * EDGE_BEAM_LIP_M * m2u
				RoadBuilder._wall(side, pa + lip, pb + lip, ya - depth, yb - depth, ya, yb, out, true)
				var kl := side.verts.size()
				for q: Vector3 in [Vector3(pa.x, ya - depth, pa.y), Vector3(pa.x + lip.x, ya - depth, pa.y + lip.y),
						Vector3(pb.x, yb - depth, pb.y), Vector3(pb.x + lip.x, yb - depth, pb.y + lip.y)]:
					side.verts.push_back(q)
					side.normals.append(Vector3.DOWN)
					side.uvs.append(Vector2.ZERO)
				RoadBuilder._quad_up(side, kl, kl + 1, kl + 2, kl + 3)
				var kt := side.verts.size()
				for q: Vector3 in [Vector3(pa.x, ya, pa.y), Vector3(pa.x + lip.x, ya, pa.y + lip.y),
						Vector3(pb.x, yb, pb.y), Vector3(pb.x + lip.x, yb, pb.y + lip.y)]:
					side.verts.push_back(q)
					side.normals.append(Vector3.UP)
					side.uvs.append(Vector2.ZERO)
				RoadBuilder._quad_up(side, kt, kt + 1, kt + 2, kt + 3)
				RoadBuilder._wall(side, pa, pb, ya, yb, ya + para, yb + para, out)
				RoadBuilder._wall(side, ia, ib, ya, yb, ya + para, yb + para, -out)
				var kc := side.verts.size()
				side.verts.push_back(Vector3(pa.x, ya + para, pa.y))
				side.verts.push_back(Vector3(ia.x, ya + para, ia.y))
				side.verts.push_back(Vector3(pb.x, yb + para, pb.y))
				side.verts.push_back(Vector3(ib.x, yb + para, ib.y))
				for q in 4:
					side.normals.append(Vector3.UP)
					side.uvs.append(Vector2(float(q % 2), float(q / 2)))
				RoadBuilder._quad_up(side, kc, kc + 1, kc + 2, kc + 3)

## Cuts the structure's deck to the roads it carries: each member's
## width and an EDGE_BEAM_M each side, the gaps between members up to
## 2 x DECK_CLOSE_M filled, clipped to the mapped outline. The outline
## takes in the shoulders, verges and wing walls, so a deck cut from it
## flared out past the carriageway it continued.
static func _fit_deck(s: BridgeStructures.Structure, index: RoadBridgeDecks.Index, m2u: float) -> void:
	var best := PackedVector2Array()
	for shrunk: PackedVector2Array in _deck_pieces(s.members, index, m2u, BridgeStructures.DECK_CLOSE_M * m2u):
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(shrunk, s.ring):
			if not Geometry2D.is_polygon_clockwise(piece) and absf(BridgeStructures.Plan._area(piece)) > absf(BridgeStructures.Plan._area(best)):
				best = piece
	if best.size() >= 3 and absf(BridgeStructures.Plan._area(best)) > absf(BridgeStructures.Plan._area(s.ring)) * 0.25:
		s.ring = best
		s.bounds = RingGeometry.aabb(best)

## The decks of index lines `members`: each line's width and an
## EDGE_BEAM_M each side, merged where their edges lie within 2 x `close`
## of each other; one ring per separate deck.
static func _deck_pieces(members: PackedInt32Array, index: RoadBridgeDecks.Index, m2u: float, close: float) -> Array:
	var merged: Array = []
	for li in members:
		var line: Dictionary = index.lines[li]
		var pts: PackedVector2Array = (line["points"] as PackedVector2Array).duplicate()
		var n := pts.size()
		# Run on past both ends by the closing distance, which the shrink
		# below takes back: the deck ends where the way does.
		pts[0] = pts[0] + (pts[0] - pts[1]).normalized() * close
		pts[n - 1] = pts[n - 1] + (pts[n - 1] - pts[n - 2]).normalized() * close
		var grow := float(line["half"]) + BridgeStructures.EDGE_BEAM_M * m2u + close
		for poly: PackedVector2Array in Geometry2D.offset_polyline(pts, grow, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT):
			merged = _union(merged, poly)
	var out: Array = []
	for poly: PackedVector2Array in merged:
		if Geometry2D.is_polygon_clockwise(poly):
			continue  # A hole the union left: the deck fills it.
		for shrunk: PackedVector2Array in Geometry2D.offset_polygon(poly, -close, Geometry2D.JOIN_MITER):
			if shrunk.size() >= 3 and not Geometry2D.is_polygon_clockwise(shrunk):
				out.append(shrunk)
	return out

## `polys` (outer rings) with `poly` merged in: joined with every ring it
## overlaps, until none is left that the grown ring reaches.
static func _union(polys: Array, poly: PackedVector2Array) -> Array:
	var acc := poly
	var box := RingGeometry.aabb(acc)
	var rest := polys
	var changed := true
	while changed:
		changed = false
		var out: Array = []
		for other: PackedVector2Array in rest:
			if box.intersects(RingGeometry.aabb(other), true):
				var outers: Array = []
				for j: PackedVector2Array in Geometry2D.merge_polygons(acc, other):
					if not Geometry2D.is_polygon_clockwise(j):
						outers.append(j)
				if outers.size() == 1:
					acc = outers[0]
					box = RingGeometry.aabb(acc)
					changed = true
					continue
			out.append(other)
		rest = out
	rest.append(acc)
	return rest
