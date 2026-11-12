class_name BridgeStructureSlab
extends RefCounted

## The concrete of a bridge structure (BridgeStructures): its slab cut from
## the outline in cells that follow the deck top, and along the outline's
## edges the fascia, the parapets (railings beside a footway or cycleway)
## and, under an open end, the abutment wall down to the ground.

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
					# The abutment wall down to the ground under an open end,
					# seen from the creek under the deck and from the bank
					# beside it: a deck end does not hang in the air. Never
					# across the water: the creek runs on under the deck.
					var ga := surf.height(pa.x, pa.y) - 0.3 * m2u
					var gb := surf.height(pb.x, pb.y) - 0.3 * m2u
					var wet := surf.ground.water_at(pa.x, pa.y) > 0.0 or surf.ground.water_at(pb.x, pb.y) > 0.0
					if not wet and (ga < ya - depth or gb < yb - depth):
						RoadBuilder._wall(side, pa, pb, ga, gb, ya - depth, yb - depth, -out)
						RoadBuilder._wall(side, pa, pb, ga, gb, ya - depth, yb - depth, out)
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
