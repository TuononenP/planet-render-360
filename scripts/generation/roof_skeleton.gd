class_name RoofSkeleton
extends RefCounted

## Concentric-band roof for footprints a single ridge cannot span (courtyard
## blocks, concave civic wings, curved outlines): the roof height rises
## through exact inward offset tiers (Clipper) from the eaves and courtyard
## holes, and each annular slope band between consecutive tiers is
## triangulated with Earcut so edges stay locked to the contour lines (no
## unconstrained Delaunay jumps across the mansard break or courtyard eaves).

const MIN_AREA_M2 := 0.02
static var _earcut := ClassDB.class_exists("EarcutKernels")

## Appends the roof's triangles (soup, via RoofGeometry.push_tri) rising
## rh above `top`. Returns false when nothing could be built.
static func faces(ring: PackedVector2Array, holes: Array, top: float, rh: float,
		mansard: bool, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, fu: Vector2) -> bool:
	var m := WorldScale.metres_to_units()
	var d_max := _depth(ring, holes) * 0.96
	if d_max < 0.3 * m:
		return false
	var knots: Array = []  # Array of [d, f]
	if mansard:
		var d1 := minf(clampf(rh * 0.36, 0.9 * m, 2.4 * m), d_max * 0.38)
		if d1 < 0.25 * m:
			d1 = minf(d_max * 0.5, 0.5 * m)
		# Keep the lower mansard slope realistic (≤ ~68°) even on narrow wings.
		rh = minf(rh, d1 * 3.4)
		var d_end := minf(maxf(d1 + 1.2 * m, clampf(rh * 2.2, 3.6 * m, 8.0 * m)), d_max)
		knots.append([d1, 0.72])
		if d_end - d1 > 2.6 * m:
			knots.append([(d1 + d_end) * 0.5, 0.86])
		if d_end - d1 > 0.35 * m:
			knots.append([d_end, 1.0])
		else:
			knots[0][1] = 1.0
	else:
		var run := minf(clampf(rh * 1.5, 1.4 * m, 8.0 * m), d_max)
		if run < 0.3 * m:
			return false
		# Keep hip/gable slopes ≤ ~50° on narrow wings.
		rh = minf(rh, run * 1.2)
		if run >= 1.8 * m:
			knots.append([run * 0.5, 0.5])
		knots.append([run, 1.0])
	var min_area := MIN_AREA_M2 * m * m
	var clean_holes: Array = []
	for h in holes:
		var hr := h as PackedVector2Array
		if hr.size() >= 3 and absf(RingGeometry.signed_area(hr)) >= min_area:
			clean_holes.append(hr)
	# Tier 0 is the eave footprint minus courtyard holes.
	var tiers: Array = [[{"outer": ring, "holes": clean_holes}]]
	var ys: PackedFloat32Array = PackedFloat32Array([top])
	var prev_d := 0.0
	for knot in knots:
		var d: float = float(knot[0])
		var dd := d - prev_d
		if dd < 0.05 * m:
			continue
		var next_comps := _inset_region(tiers.back() as Array, dd, min_area)
		if next_comps.is_empty():
			break
		tiers.append(next_comps)
		ys.append(top + rh * float(knot[1]))
		prev_d = d
	if tiers.size() < 2:
		return false
	# Subdivide every tier contour once so consecutive tiers share exact
	# vertices (watertight, zero T-junctions) and CDT keeps triangles local.
	var step := clampf(d_max * 0.55, 1.8 * m, 3.2 * m)
	for ti in tiers.size():
		tiers[ti] = _subdivide_region(tiers[ti] as Array, step)
	var before := verts.size()
	for k in tiers.size() - 1:
		_emit_band(tiers[k] as Array, ys[k], tiers[k + 1] as Array, ys[k + 1],
			verts, normals, uvs, fu)
	# Top plateau (or ridge strip) at the highest tier.
	var top_y := ys[ys.size() - 1]
	for comp in (tiers.back() as Array):
		var c: Dictionary = comp
		var choles: Array = c["holes"]
		var hys := PackedFloat32Array()
		hys.resize(choles.size())
		hys.fill(top_y)
		_triangulate_piece(c["outer"] as PackedVector2Array, top_y, choles, hys,
			verts, normals, uvs, fu)
	return verts.size() > before

## Offsets a multi-component region inward by `dd` (outer rings shrink by -dd,
## holes grow by +dd and clip out of the shrunk outer rings), guaranteeing the
## result lies strictly inside the input region.
static func _inset_region(comps: Array, dd: float, min_area: float) -> Array:
	var out: Array = []
	for comp in comps:
		var c: Dictionary = comp
		var shrunk := _solid_rings(Geometry2D.offset_polygon(c["outer"] as PackedVector2Array,
			-dd, Geometry2D.JOIN_MITER), min_area)
		if shrunk.is_empty():
			continue
		var choles: Array = c["holes"]
		if choles.is_empty():
			for s in shrunk:
				out.append({"outer": s, "holes": []})
			continue
		var grown: Array = []
		for h in choles:
			for g in _solid_rings(Geometry2D.offset_polygon(h as PackedVector2Array,
					dd, Geometry2D.JOIN_MITER), min_area):
				grown.append(g)
		grown = _merge_disjoint(grown, min_area)
		for s in shrunk:
			var pieces: Array = [{"outer": s, "holes": []}]
			for g in grown:
				var next_pieces: Array = []
				for p in pieces:
					var pd: Dictionary = p
					var clipped := Geometry2D.clip_polygons(pd["outer"] as PackedVector2Array,
						g as PackedVector2Array)
					if clipped.is_empty():
						continue
					var split := _split_winding(clipped, min_area)
					var new_outers: Array = split[0]
					var new_holes: Array = split[1]
					var prev_holes: Array = pd["holes"]
					for no in new_outers:
						var nor := no as PackedVector2Array
						var hs: Array = []
						for nh in new_holes:
							var nhr := nh as PackedVector2Array
							if RingGeometry.point_in_ring(nhr[0], nor):
								hs.append(nhr)
						for eh in prev_holes:
							var ehr := eh as PackedVector2Array
							if RingGeometry.point_in_ring(ehr[0], nor) and not _in_any(ehr[0], hs):
								hs.append(ehr)
						next_pieces.append({"outer": nor, "holes": hs})
				pieces = next_pieces
			out.append_array(pieces)
	return out

## Emits all slope band pieces for R_k \ R_{k+1}, where R_{k+1} lies strictly
## inside R_k.
static func _emit_band(r0: Array, y0: float, r1: Array, y1: float,
		verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, fu: Vector2) -> void:
	var r1_holes: Array = []
	for c1 in r1:
		r1_holes.append_array((c1 as Dictionary)["holes"] as Array)
	# 1. Outer-bounded bands: each component of R_k minus inner R_{k+1} outers
	# and any R_k holes not absorbed into an R_{k+1} hole.
	for c0 in r0:
		var d0: Dictionary = c0
		var o0: PackedVector2Array = d0["outer"]
		var h0s: Array = d0["holes"]
		var band_holes: Array = []
		var hole_ys := PackedFloat32Array()
		for c1 in r1:
			var o1: PackedVector2Array = (c1 as Dictionary)["outer"]
			if RingGeometry.point_in_ring(o1[0], o0) and not _in_any(o1[0], h0s):
				band_holes.append(o1)
				hole_ys.append(y1)
		for h0 in h0s:
			var hr := h0 as PackedVector2Array
			if not _in_any(hr[0], r1_holes):
				band_holes.append(hr)
				hole_ys.append(y0)
		_triangulate_piece(o0, y0, band_holes, hole_ys, verts, normals, uvs, fu)
	# 2. Inner courtyard bands: each grown hole H' of R_{k+1} (at y1) minus the
	# courtyard holes of R_k (at y0) enclosed inside H'.
	for h1 in r1_holes:
		var h1r := h1 as PackedVector2Array
		var inner_holes: Array = []
		var inner_ys := PackedFloat32Array()
		for c0 in r0:
			for h0 in ((c0 as Dictionary)["holes"] as Array):
				var h0r := h0 as PackedVector2Array
				if RingGeometry.point_in_ring(h0r[0], h1r):
					inner_holes.append(h0r)
					inner_ys.append(y0)
		if not inner_holes.is_empty():
			_triangulate_piece(h1r, y1, inner_holes, inner_ys, verts, normals, uvs, fu)

## Triangulates one polygon with holes, assigning `outer_y` to `outer` and
## `hole_ys[j]` to `holes[j]`.
static func _triangulate_piece(outer: PackedVector2Array, outer_y: float,
		holes: Array, hole_ys: PackedFloat32Array,
		verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, fu: Vector2) -> void:
	if outer.size() < 3:
		return
	var pts := PackedVector2Array()
	var ys := PackedFloat32Array()
	var idx: PackedInt32Array
	if _earcut:
		pts.append_array(outer)
		for _i in outer.size():
			ys.append(outer_y)
		for j in holes.size():
			var h := holes[j] as PackedVector2Array
			pts.append_array(h)
			var hy := hole_ys[j]
			for _i in h.size():
				ys.append(hy)
		idx = ClassDB.class_call_static("EarcutKernels", "triangulate", outer, holes)
	else:
		var bridged := _bridge_with_y(outer, outer_y, holes, hole_ys)
		pts = bridged[0]
		ys = bridged[1]
		idx = Geometry2D.triangulate_polygon(pts)
		if not holes.is_empty():
			idx = RingGeometry.drop_hole_triangles(pts, idx, holes)
	# Collect non-degenerate CCW triangles, then flip interior diagonals to
	# Constrained Delaunay so no long skinny cross-band sliver turns steep in 3D.
	var tris: Array = []
	for k in range(0, idx.size() - 2, 3):
		var a := idx[k]
		var b := idx[k + 1]
		var c := idx[k + 2]
		var cr := _orient2d(pts[a], pts[b], pts[c])
		if absf(cr) < 1e-6:
			continue
		if cr < 0.0:
			var t := b
			b = c
			c = t
		tris.append([a, b, c])
	if not holes.is_empty() and tris.size() >= 2:
		_lawson_cdt(pts, tris)
	for tri in tris:
		var t: Array = tri
		var a: int = t[0]
		var b: int = t[1]
		var c: int = t[2]
		RoofGeometry.push_tri(verts, normals, uvs, Vector2.ZERO,
			Vector3(pts[a].x, ys[a], pts[a].y),
			Vector3(pts[b].x, ys[b], pts[b].y),
			Vector3(pts[c].x, ys[c], pts[c].y), fu, true)

static func _orient2d(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

## True when `d` lies strictly inside the circumcircle of CCW triangle (a, b, c).
static func _in_circle(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var adx := a.x - d.x
	var ady := a.y - d.y
	var bdx := b.x - d.x
	var bdy := b.y - d.y
	var cdx := c.x - d.x
	var cdy := c.y - d.y
	var al := adx * adx + ady * ady
	var bl := bdx * bdx + bdy * bdy
	var cl := cdx * cdx + cdy * cdy
	var det := al * (bdx * cdy - bdy * cdx) - bl * (adx * cdy - ady * cdx) + cl * (adx * bdy - ady * bdx)
	var scale := maxf(al, maxf(bl, cl))
	return det > 1e-6 * scale * scale

## Flips interior shared edges (edges belonging to two triangles) toward
## Constrained Delaunay; boundary edges of the band remain locked.
static func _lawson_cdt(pts: PackedVector2Array, tris: Array) -> void:
	var max_passes := 32
	var changed := true
	for _pass in max_passes:
		if not changed:
			break
		changed = false
		var edges := {}
		for ti in tris.size():
			var t: Array = tris[ti]
			for e in 3:
				var u: int = t[e]
				var v: int = t[(e + 1) % 3]
				var key := Vector2i(mini(u, v), maxi(u, v))
				if not edges.has(key):
					edges[key] = [[ti, e]]
				else:
					(edges[key] as Array).append([ti, e])
		var used := {}
		for key in edges:
			var pair: Array = edges[key]
			if pair.size() != 2:
				continue
			var t0: int = pair[0][0]
			var t1: int = pair[1][0]
			if used.has(t0) or used.has(t1):
				continue
			var e0: int = pair[0][1]
			var e1: int = pair[1][1]
			var tr0: Array = tris[t0]
			var tr1: Array = tris[t1]
			var a: int = tr0[e0]
			var b: int = tr0[(e0 + 1) % 3]
			var c: int = tr0[(e0 + 2) % 3]
			var d: int = tr1[(e1 + 2) % 3]
			if d == a or d == b or d == c or pts[a].is_equal_approx(pts[b]):
				continue
			if tr1[e1] != b or tr1[(e1 + 1) % 3] != a:
				continue
			# Both replacement triangles [c, d, b] and [d, c, a] must be strictly CCW.
			if _orient2d(pts[c], pts[d], pts[b]) <= 1e-6 or _orient2d(pts[d], pts[c], pts[a]) <= 1e-6:
				continue
			if _in_circle(pts[a], pts[b], pts[c], pts[d]):
				tris[t0] = [c, d, b]
				tris[t1] = [d, c, a]
				used[t0] = true
				used[t1] = true
				changed = true

static func _subdivide_ring(r: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := r.size()
	for i in n:
		var a := r[i]
		var b := r[(i + 1) % n]
		var parts := maxi(1, ceili((b - a).length() / step))
		for s in parts:
			out.append(a.lerp(b, float(s) / float(parts)))
	return out

static func _subdivide_region(comps: Array, step: float) -> Array:
	var out: Array = []
	for comp in comps:
		var c: Dictionary = comp
		var hs: Array = []
		for h in (c["holes"] as Array):
			hs.append(_subdivide_ring(h as PackedVector2Array, step))
		out.append({"outer": _subdivide_ring(c["outer"] as PackedVector2Array, step), "holes": hs})
	return out

## Pure-GDScript fallback when EarcutKernels is unavailable: bridges holes into
## `outer` while carrying each vertex's exact tier elevation.
static func _bridge_with_y(outer: PackedVector2Array, outer_y: float,
		holes: Array, hole_ys: PackedFloat32Array) -> Array:
	var out := PackedVector2Array(outer)
	var out_y := PackedFloat32Array()
	out_y.resize(outer.size())
	out_y.fill(outer_y)
	if holes.is_empty():
		return [out, out_y]
	var ccw := RingGeometry.signed_area(outer) > 0.0
	var order: Array = range(holes.size())
	order.sort_custom(func(i: int, j: int) -> bool:
		return RingGeometry.aabb(holes[i]).end.x > RingGeometry.aabb(holes[j]).end.x)
	var all_holes: Array = holes
	for hi_idx in order:
		var hole := PackedVector2Array(holes[hi_idx] as PackedVector2Array)
		if hole.size() < 3:
			continue
		if (RingGeometry.signed_area(hole) > 0.0) == ccw:
			hole.reverse()
		var hy := hole_ys[hi_idx]
		var hi := 0
		for i in hole.size():
			if hole[i].x > hole[hi].x:
				hi = i
		var oi := RingGeometry._visible_vertex(out, hole[hi], all_holes)
		var seam := PackedVector2Array()
		var seam_y := PackedFloat32Array()
		for k in hole.size() + 1:
			seam.append(hole[(hi + k) % hole.size()])
			seam_y.append(hy)
		seam.append(out[oi])
		seam_y.append(out_y[oi])
		var joined := out.slice(0, oi + 1)
		joined.append_array(seam)
		joined.append_array(out.slice(oi + 1))
		var joined_y := out_y.slice(0, oi + 1)
		joined_y.append_array(seam_y)
		joined_y.append_array(out_y.slice(oi + 1))
		out = joined
		out_y = joined_y
	return [out, out_y]

## Merges overlapping solid polygons into pairwise disjoint solid rings.
static func _merge_disjoint(rings: Array, min_area: float) -> Array:
	if rings.size() <= 1:
		return rings
	var out: Array = rings.duplicate()
	var i := 0
	while i < out.size():
		var merged := false
		for j in range(i + 1, out.size()):
			if not Geometry2D.intersect_polygons(out[i] as PackedVector2Array,
					out[j] as PackedVector2Array).is_empty():
				var u := _solid_rings(Geometry2D.merge_polygons(out[i] as PackedVector2Array,
					out[j] as PackedVector2Array), min_area)
				if u.size() == 1:
					out[i] = u[0]
					out.remove_at(j)
					merged = true
					break
		if not merged:
			i += 1
	return out

## Solid outer rings of a Clipper output (same winding as the largest polygon).
static func _solid_rings(polys: Array, min_area: float) -> Array:
	return _split_winding(polys, min_area)[0]

## Splits Clipper polygons into [outers, holes] by comparing winding against the
## largest polygon (whose winding is guaranteed to be an outer boundary).
static func _split_winding(polys: Array, min_area: float) -> Array:
	var largest := 0.0
	var cw := false
	for p in polys:
		var pr := p as PackedVector2Array
		if pr.size() < 3:
			continue
		var a := absf(RingGeometry.signed_area(pr))
		if a > largest:
			largest = a
			cw = Geometry2D.is_polygon_clockwise(pr)
	var outers: Array = []
	var holes: Array = []
	if largest < min_area:
		return [outers, holes]
	for p in polys:
		var pr := p as PackedVector2Array
		if pr.size() < 3 or absf(RingGeometry.signed_area(pr)) < min_area:
			continue
		if Geometry2D.is_polygon_clockwise(pr) == cw:
			outers.append(pr)
		else:
			holes.append(pr)
	return [outers, holes]

## Deepest inset (units) the footprint minus its courtyards allows: the
## largest d whose inward offset is still non-empty (bisection).
static func _depth(ring: PackedVector2Array, holes: Array) -> float:
	var lo := 0.0
	var hi := RingGeometry.aabb(ring).size.length() * 0.5
	for _i in 10:
		var d := (lo + hi) * 0.5
		if _survives(ring, holes, d):
			lo = d
		else:
			hi = d
	return lo

static func _survives(ring: PackedVector2Array, holes: Array, d: float) -> bool:
	var inner := _solid_rings(Geometry2D.offset_polygon(ring, -d, Geometry2D.JOIN_MITER), 0.001)
	for h in holes:
		var next: Array = []
		for g in _solid_rings(Geometry2D.offset_polygon(h as PackedVector2Array, d, Geometry2D.JOIN_MITER), 0.001):
			for c in inner:
				next.append_array(_solid_rings(Geometry2D.clip_polygons(c as PackedVector2Array, g as PackedVector2Array), 0.001))
		inner = next
	return not inner.is_empty()

static func _in_any(p: Vector2, rings: Array) -> bool:
	for r in rings:
		if RingGeometry.point_in_ring(p, r as PackedVector2Array):
			return true
	return false
