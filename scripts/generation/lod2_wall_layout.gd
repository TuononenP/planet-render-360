class_name Lod2WallLayout
extends RefCounted

## Decodes LoD2.2 wall triangle soups into matched windowed and blank-masonry
## surfaces so windows are never sliced by gable slopes, pitched roofs, vertical
## corners, facade steps or narrow wall strips.
##
## Per connected coplanar wall patch:
##   1. Snaps horizontal window bays (`u`) to an integer count across the patch
##      width so vertical wall edges and corners always fall on solid piers.
##   2. Snaps vertical storeys (`y`) to the patch's flat eave height so flat
##      eaves never chop the top row of windows.
##   3. Tests every (bay, storey) cell's safe window box against the 2D wall
##      patch; cells that fit wholly inside stay windowed, while cells clipped
##      by gable slopes, sloped roofs, steps or narrow strips route to blank
##      masonry with the exact same (u, v) coordinates so brick courses and
##      weathering continue unbroken across the seam.

const MIN_BAY_M := 1.6
const MIN_BAY_SHARE := 0.62
const MIN_WALL_H := 2.2
## Safe inset inside each (bay, storey) cell (as fraction of bay width / storey
## height): strict enough that no lintel, pediment, sill or shutter is grazed by
## a roof slope, loose enough (~15 cm) to tolerate CityJSON vertex rounding.
const PAD_U := 0.06
const PAD_Y := 0.05
## 2D point-in-triangle seam tolerance (m) bridging tiny CityJSON face gaps.
const SEAM_TOL_M := 0.04
## Coplanar patch merge tolerances (normal bucket, plane offset, 2D AABB touch).
const PLANE_OFFSET_M := 0.12
const PATCH_TOUCH_M := 0.08


static func decode(buf: PackedInt32Array, v_off: int, i_off: int, n_verts: int, n_idx: int,
		ox: float, oy: float, oz: float, m2u: float, bay_m: float, bays: float,
		floor_h: float, sink_u: float, split_blank: bool) -> Dictionary:
	var n_tri := n_idx / 3
	var win := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	var blank := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	var s := 0.01 * m2u
	var sink_m := sink_u / m2u if sink_u > 0.0 else 0.0
	var min_w := maxf(MIN_BAY_M, bay_m * MIN_BAY_SHARE)

	# Pass 1: bucket valid wall triangles by horizontal outward normal.
	var buckets: Dictionary = {}
	for t in n_tri:
		var bi := i_off + t * 3
		var i0 := buf[bi]
		var i1 := buf[bi + 1]
		var i2 := buf[bi + 2]
		if i0 < 0 or i0 >= n_verts or i1 < 0 or i1 >= n_verts or i2 < 0 or i2 >= n_verts:
			continue
		var v0 := v_off + i0 * 3
		var v1 := v_off + i1 * 3
		var v2 := v_off + i2 * 3
		var p0 := _pt(buf, v0, ox, oy, oz, s, sink_u)
		var p1 := _pt(buf, v1, ox, oy, oz, s, sink_u)
		var p2 := _pt(buf, v2, ox, oy, oz, s, sink_u)
		var n := (p2 - p0).cross(p1 - p0)
		var nl := n.length()
		if nl < 1e-6:
			continue
		n /= nl
		var hn := Vector2(n.x, n.z)
		var hl := hn.length()
		if hl < 0.15:
			continue
		hn /= hl
		var nk := Vector2i(roundi(hn.x * 12.0), roundi(hn.y * 12.0))
		if not buckets.has(nk):
			buckets[nk] = {"hn": hn, "tris": []}
		var lx0 := float(buf[v0]) * 0.01
		var ly0 := float(buf[v0 + 1]) * 0.01
		var lz0 := float(buf[v0 + 2]) * 0.01
		var lx1 := float(buf[v1]) * 0.01
		var ly1 := float(buf[v1 + 1]) * 0.01
		var lz1 := float(buf[v1 + 2]) * 0.01
		var lx2 := float(buf[v2]) * 0.01
		var ly2 := float(buf[v2 + 1]) * 0.01
		var lz2 := float(buf[v2 + 2]) * 0.01
		var bkt: Dictionary = buckets[nk]
		var bhn: Vector2 = bkt["hn"]
		var tu := Vector2(bhn.y, -bhn.x)
		var d_plane := (bhn.x * (lx0 + lx1 + lx2) + bhn.y * (lz0 + lz1 + lz2)) / 3.0
		var u0 := lx0 * tu.x + lz0 * tu.y
		var u1 := lx1 * tu.x + lz1 * tu.y
		var u2 := lx2 * tu.x + lz2 * tu.y
		(bkt["tris"] as Array).append([
			p0, p1, p2, n,
			u0, ly0, u1, ly1, u2, ly2,
			d_plane,
			minf(u0, minf(u1, u2)), maxf(u0, maxf(u1, u2)),
			minf(ly0, minf(ly1, ly2)), maxf(ly0, maxf(ly1, ly2)),
			buf[v0 + 1] <= 40, buf[v1 + 1] <= 40, buf[v2 + 1] <= 40,
		])

	# Pass 2: cluster coplanar connected patches and lay out uncut windows per patch.
	for nk in buckets:
		var tris: Array = (buckets[nk] as Dictionary)["tris"]
		var patches := _cluster_patches(tris)
		for patch: Array in patches:
			_emit_patch(win, blank, patch, bay_m, bays, floor_h, sink_m, min_w, split_blank)

	return {"windowed": win, "blank": blank}


## Groups triangles sharing a normal bucket into connected coplanar patches
## (within PLANE_OFFSET_M in depth and PATCH_TOUCH_M in 2D (u, y) AABB).
static func _cluster_patches(tris: Array) -> Array:
	var m := tris.size()
	if m <= 1:
		return [tris] if m == 1 else []
	var parent := PackedInt32Array()
	parent.resize(m)
	for i in m:
		parent[i] = i
	for i in m:
		var a: Array = tris[i]
		var da := float(a[10])
		var au0 := float(a[11]) - PATCH_TOUCH_M
		var au1 := float(a[12]) + PATCH_TOUCH_M
		var ay0 := float(a[13]) - PATCH_TOUCH_M
		var ay1 := float(a[14]) + PATCH_TOUCH_M
		for j in range(i + 1, m):
			var b: Array = tris[j]
			if absf(da - float(b[10])) > PLANE_OFFSET_M:
				continue
			if au0 <= float(b[12]) and float(b[11]) <= au1 \
					and ay0 <= float(b[14]) and float(b[13]) <= ay1:
				var ri := _find(parent, i)
				var rj := _find(parent, j)
				if ri != rj:
					parent[ri] = rj
	var comps: Dictionary = {}
	for i in m:
		var r := _find(parent, i)
		if not comps.has(r):
			comps[r] = []
		(comps[r] as Array).append(tris[i])
	return comps.values()


static func _find(parent: PackedInt32Array, x: int) -> int:
	while parent[x] != x:
		parent[x] = parent[parent[x]]
		x = parent[x]
	return x


static func _emit_patch(win: Array, blank: Array, patch: Array, bay_m: float, bays: float,
		floor_h: float, sink_m: float, min_w: float, split_blank: bool) -> void:
	var u_min := INF
	var u_max := -INF
	var y_min := INF
	var y_max := -INF
	var area_sum := 0.0
	for t: Array in patch:
		u_min = minf(u_min, float(t[11]))
		u_max = maxf(u_max, float(t[12]))
		y_min = minf(y_min, float(t[13]))
		y_max = maxf(y_max, float(t[14]))
		var ax := float(t[4]); var ay := float(t[5])
		var bx := float(t[6]); var by := float(t[7])
		var cx := float(t[8]); var cy := float(t[9])
		area_sum += absf((bx - ax) * (cy - ay) - (by - ay) * (cx - ax)) * 0.5
	var span_u := u_max - u_min
	var y_base := 0.0 if y_min <= 0.6 else y_min
	var span_y := y_max - y_base
	var dst_blank := blank if split_blank else win

	# Narrow wall strips (pilasters, dormer cheeks, turret facets) or short
	# parapets cannot hold a full window: emit pure blank masonry with real-world UVs.
	if split_blank and (span_u < min_w or span_y < MIN_WALL_H):
		var bw_b := maxf(bay_m, 1.0)
		var sh_b := maxf(floor_h, 2.5)
		_emit_patch_raw(dst_blank, patch, u_min, bw_b, bays, y_max, sh_b, sink_m)
		return

	# Horizontal bay grid snapped to an integer bay count across this patch.
	var n_cols := maxi(1, roundi(span_u / maxf(bay_m, 1.0)))
	var bw := span_u / float(n_cols)

	# Fast path for clean rectangular walls (~75% of all LoD2 patches): when the
	# triangles fill the AABB rectangle and every vertex sits at top or bottom,
	# every snapped (bay, storey) cell is guaranteed valid with zero clipping.
	var aabb_area := span_u * (y_max - y_min)
	if aabb_area > 0.0 and area_sum >= aabb_area * 0.985 and area_sum <= aabb_area * 1.015 \
			and _is_rect_patch(patch, y_min, y_max):
		var sh_r := _snap_storey_h(span_y, floor_h)
		var n_st_r := maxi(1, roundi(span_y / sh_r))
		_emit_patch_raw(win, patch, u_min, bw, bays, y_base + float(n_st_r) * sh_r, sh_r, sink_m)
		return

	var tris_2d := _prep_tris_2d(patch)

	# Vertical storey grid anchored to the patch's eave height so flat eaves
	# never slice the top window row and corners align across gabled/side faces.
	var eave_y := _find_eave_y(tris_2d, u_min, u_max, n_cols, bw, y_base, y_max)
	var sh := floor_h
	if eave_y - y_base >= MIN_WALL_H:
		var span_e := (y_max - y_base) if (y_max - eave_y <= 0.20) else (eave_y - y_base)
		sh = _snap_storey_h(span_e, floor_h)
	var y_origin := y_base
	var n_rows := maxi(1, ceili((y_max - y_origin - 1e-4) / sh))
	var y_anchor := y_origin + float(n_rows) * sh

	if not split_blank:
		_emit_patch_raw(win, patch, u_min, bw, bays, y_anchor, sh, sink_m)
		return

	# Evaluate which (row, col) cells safely contain an uncut window opening.
	var valid: Array = []
	valid.resize(n_rows)
	var any_win := false
	var any_blank := false
	var pad_u := bw * PAD_U
	var pad_y := sh * PAD_Y
	for r in n_rows:
		var row_v := PackedByteArray()
		row_v.resize(n_cols)
		var yb := y_origin + float(r) * sh
		var yt := yb + sh
		for c in n_cols:
			var ul := u_min + float(c) * bw
			var ur := ul + bw
			var ok := _rect_inside_patch(tris_2d, ul + pad_u, ur - pad_u, yb + pad_y, yt - pad_y)
			row_v[c] = 1 if ok else 0
			if ok:
				any_win = true
			else:
				any_blank = true
		valid[r] = row_v

	# Fast paths: uniform patches emit with zero clipping or extra triangles.
	if not any_win:
		_emit_patch_raw(blank, patch, u_min, bw, bays, y_anchor, sh, sink_m)
		return
	if not any_blank:
		_emit_patch_raw(win, patch, u_min, bw, bays, y_anchor, sh, sink_m)
		return

	# Mixed patch: build convex vertex polygons with exact seamless UVs, then
	# split ONLY along grid lines where cell validity actually transitions.
	var inv_u := 1.0 / (bw * bays)
	var inv_v := 1.0 / sh
	var dv_s := sink_m * inv_v
	var h_cuts: PackedFloat32Array = PackedFloat32Array()
	for r in range(1, n_rows):
		var prev: PackedByteArray = valid[r - 1]
		var curr: PackedByteArray = valid[r]
		for c in n_cols:
			if prev[c] != curr[c]:
				h_cuts.append(y_origin + float(r) * sh)
				break

	for t: Array in patch:
		var n: Vector3 = t[3]
		var poly := [
			[t[0], Vector2((float(t[4]) - u_min) * inv_u, (y_anchor - float(t[5])) * inv_v + (dv_s if bool(t[15]) else 0.0)), float(t[4]), float(t[5])],
			[t[1], Vector2((float(t[6]) - u_min) * inv_u, (y_anchor - float(t[7])) * inv_v + (dv_s if bool(t[16]) else 0.0)), float(t[6]), float(t[7])],
			[t[2], Vector2((float(t[8]) - u_min) * inv_u, (y_anchor - float(t[9])) * inv_v + (dv_s if bool(t[17]) else 0.0)), float(t[8]), float(t[9])],
		]
		var h_polys: Array = [poly]
		for cut_y in h_cuts:
			var next_h: Array = []
			for hp: Array in h_polys:
				_split_poly_append(hp, 3, cut_y, next_h)
			h_polys = next_h
		for hp: Array in h_polys:
			var cy := _poly_mean(hp, 3)
			var r := clampi(floori((cy - y_origin) / sh), 0, n_rows - 1)
			var row_v: PackedByteArray = valid[r]
			var v_cuts: PackedFloat32Array = PackedFloat32Array()
			for c in range(1, n_cols):
				if row_v[c - 1] != row_v[c]:
					v_cuts.append(u_min + float(c) * bw)
			if v_cuts.is_empty():
				_emit_poly(win if row_v[0] == 1 else blank, hp, n)
				continue
			var v_polys: Array = [hp]
			for cut_u in v_cuts:
				var next_v: Array = []
				for vp: Array in v_polys:
					_split_poly_append(vp, 2, cut_u, next_v)
				v_polys = next_v
			for vp: Array in v_polys:
				var cu := _poly_mean(vp, 2)
				var c := clampi(floori((cu - u_min) / bw), 0, n_cols - 1)
				_emit_poly(win if row_v[c] == 1 else blank, vp, n)


static func _emit_patch_raw(dst: Array, patch: Array, u_min: float, bw: float, bays: float,
		y_anchor: float, sh: float, sink_m: float) -> void:
	var verts: PackedVector3Array = dst[0]
	var norms: PackedVector3Array = dst[1]
	var uvs: PackedVector2Array = dst[2]
	var indices: PackedInt32Array = dst[3]
	var inv_u := 1.0 / (bw * bays)
	var inv_v := 1.0 / sh
	var dv_s := sink_m * inv_v
	var k := verts.size()
	verts.resize(k + patch.size() * 3)
	norms.resize(k + patch.size() * 3)
	uvs.resize(k + patch.size() * 3)
	indices.resize(k + patch.size() * 3)
	for t: Array in patch:
		var n: Vector3 = t[3]
		verts[k] = t[0]
		verts[k + 1] = t[1]
		verts[k + 2] = t[2]
		norms[k] = n
		norms[k + 1] = n
		norms[k + 2] = n
		uvs[k] = Vector2((float(t[4]) - u_min) * inv_u, (y_anchor - float(t[5])) * inv_v + (dv_s if bool(t[15]) else 0.0))
		uvs[k + 1] = Vector2((float(t[6]) - u_min) * inv_u, (y_anchor - float(t[7])) * inv_v + (dv_s if bool(t[16]) else 0.0))
		uvs[k + 2] = Vector2((float(t[8]) - u_min) * inv_u, (y_anchor - float(t[9])) * inv_v + (dv_s if bool(t[17]) else 0.0))
		indices[k] = k
		indices[k + 1] = k + 1
		indices[k + 2] = k + 2
		k += 3


## Precomputes 2D triangle edge vectors and inverse lengths for fast metric
## point-in-triangle tests.
static func _prep_tris_2d(patch: Array) -> Array:
	var out: Array = []
	for t: Array in patch:
		var a := Vector2(float(t[4]), float(t[5]))
		var b := Vector2(float(t[6]), float(t[7]))
		var c := Vector2(float(t[8]), float(t[9]))
		var e0 := b - a
		var e1 := c - b
		var e2 := a - c
		var l0 := e0.length()
		var l1 := e1.length()
		var l2 := e2.length()
		var a2 := e0.x * (c.y - a.y) - e0.y * (c.x - a.x)
		if l0 < 1e-5 or l1 < 1e-5 or l2 < 1e-5 or absf(a2) < 1e-5:
			continue
		var sgn := 1.0 if a2 > 0.0 else -1.0
		out.append([
			a, b, c, e0, e1, e2, sgn / l0, sgn / l1, sgn / l2,
			minf(a.x, minf(b.x, c.x)) - SEAM_TOL_M, maxf(a.x, maxf(b.x, c.x)) + SEAM_TOL_M,
			minf(a.y, minf(b.y, c.y)) - SEAM_TOL_M, maxf(a.y, maxf(b.y, c.y)) + SEAM_TOL_M,
		])
	return out


## Finds the lowest full-height top height across the patch's outer edges and
## bay centres — matching the flat eave on rectangular, gabled and stepped walls.
static func _find_eave_y(tris_2d: Array, u_min: float, u_max: float, n_cols: int, bw: float,
		y_base: float, y_max: float) -> float:
	var samples := PackedFloat32Array()
	samples.append(u_min)
	samples.append(u_max)
	for c in n_cols:
		samples.append(u_min + (float(c) + 0.5) * bw)
	var eave := INF
	for uq in samples:
		var ext := _vertical_extent_at_u(tris_2d, uq)
		if ext.x <= y_base + 0.6 and ext.y - y_base >= MIN_WALL_H:
			eave = minf(eave, ext.y)
	return eave if eave < 1e8 else y_max


static func _snap_storey_h(span_e: float, floor_h: float) -> float:
	var n_st := maxi(1, roundi(span_e / floor_h))
	var sh := span_e / float(n_st)
	while sh > 3.85:
		n_st += 1
		sh = span_e / float(n_st)
	while sh < 2.35 and n_st > 1:
		n_st -= 1
		sh = span_e / float(n_st)
	return sh


static func _is_rect_patch(patch: Array, y_min: float, y_max: float) -> bool:
	var lo_lim := y_min + 0.15
	var hi_lim := y_max - 0.15
	for t: Array in patch:
		for yi in [5, 7, 9]:
			var y := float(t[yi])
			if y > lo_lim and y < hi_lim:
				return false
	return true


static func _vertical_extent_at_u(tris_2d: Array, uq: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for td: Array in tris_2d:
		if uq < float(td[9]) or uq > float(td[10]):
			continue
		var p0: Vector2 = td[0]
		var p1: Vector2 = td[1]
		var p2: Vector2 = td[2]
		var ext := _edge_y_at_u(p0, p1, uq, lo, hi)
		ext = _edge_y_at_u(p1, p2, uq, ext.x, ext.y)
		ext = _edge_y_at_u(p2, p0, uq, ext.x, ext.y)
		lo = ext.x
		hi = ext.y
	return Vector2(lo, hi)


static func _edge_y_at_u(a: Vector2, b: Vector2, uq: float, lo: float, hi: float) -> Vector2:
	var du := b.x - a.x
	if absf(du) < 1e-5:
		if absf(uq - a.x) <= SEAM_TOL_M:
			return Vector2(minf(lo, minf(a.y, b.y)), maxf(hi, maxf(a.y, b.y)))
		return Vector2(lo, hi)
	var t := (uq - a.x) / du
	if t >= -0.001 and t <= 1.001:
		var y := a.y + (b.y - a.y) * clampf(t, 0.0, 1.0)
		return Vector2(minf(lo, y), maxf(hi, y))
	return Vector2(lo, hi)


## True iff the safe window rectangle [u0, u1] x [y0, y1] lies completely inside
## the 2D wall patch (4 corners first for fast reject, then edge midpoints & centre).
static func _rect_inside_patch(tris_2d: Array, u0: float, u1: float, y0: float, y1: float) -> bool:
	if u1 <= u0 or y1 <= y0:
		return false
	if not _pt_in_patch(tris_2d, u0, y0) or not _pt_in_patch(tris_2d, u1, y0) \
			or not _pt_in_patch(tris_2d, u1, y1) or not _pt_in_patch(tris_2d, u0, y1):
		return false
	var um := (u0 + u1) * 0.5
	var ym := (y0 + y1) * 0.5
	return _pt_in_patch(tris_2d, um, y0) and _pt_in_patch(tris_2d, um, y1) \
		and _pt_in_patch(tris_2d, u0, ym) and _pt_in_patch(tris_2d, u1, ym) \
		and _pt_in_patch(tris_2d, um, ym)


static func _pt_in_patch(tris_2d: Array, px: float, py: float) -> bool:
	for td: Array in tris_2d:
		if px < float(td[9]) or px > float(td[10]) or py < float(td[11]) or py > float(td[12]):
			continue
		var a: Vector2 = td[0]
		var e0: Vector2 = td[3]
		if (e0.x * (py - a.y) - e0.y * (px - a.x)) * float(td[6]) < -SEAM_TOL_M:
			continue
		var b: Vector2 = td[1]
		var e1: Vector2 = td[4]
		if (e1.x * (py - b.y) - e1.y * (px - b.x)) * float(td[7]) < -SEAM_TOL_M:
			continue
		var c: Vector2 = td[2]
		var e2: Vector2 = td[5]
		if (e2.x * (py - c.y) - e2.y * (px - c.x)) * float(td[8]) < -SEAM_TOL_M:
			continue
		return true
	return false


## Splits a convex polygon along axis `coord_idx` (2 = u, 3 = y) at `cut`,
## appending each non-degenerate resulting polygon to `out`.
static func _split_poly_append(poly: Array, coord_idx: int, cut: float, out: Array) -> void:
	var has_lo := false
	var has_hi := false
	for v: Array in poly:
		var val := float(v[coord_idx])
		if val < cut - 1e-4:
			has_lo = true
		elif val > cut + 1e-4:
			has_hi = true
	if not has_lo or not has_hi:
		out.append(poly)
		return
	var lo: Array = []
	var hi: Array = []
	var n := poly.size()
	for i in n:
		var a: Array = poly[i]
		var b: Array = poly[(i + 1) % n]
		var va := float(a[coord_idx])
		var vb := float(b[coord_idx])
		var a_lo := va <= cut
		var b_lo := vb <= cut
		if a_lo:
			lo.append(a)
		else:
			hi.append(a)
		if a_lo != b_lo:
			var t := clampf((cut - va) / (vb - va), 0.0, 1.0)
			var mid := [
				(a[0] as Vector3).lerp(b[0] as Vector3, t),
				(a[1] as Vector2).lerp(b[1] as Vector2, t),
				lerpf(float(a[2]), float(b[2]), t),
				lerpf(float(a[3]), float(b[3]), t),
			]
			lo.append(mid)
			hi.append(mid)
	if lo.size() >= 3:
		out.append(lo)
	if hi.size() >= 3:
		out.append(hi)


static func _poly_mean(poly: Array, coord_idx: int) -> float:
	var sum := 0.0
	for v: Array in poly:
		sum += float(v[coord_idx])
	return sum / float(poly.size())


static func _emit_poly(dst: Array, poly: Array, normal: Vector3) -> void:
	var n := poly.size()
	if n < 3:
		return
	var verts: PackedVector3Array = dst[0]
	var norms: PackedVector3Array = dst[1]
	var uvs: PackedVector2Array = dst[2]
	var indices: PackedInt32Array = dst[3]
	var v0: Array = poly[0]
	var p0: Vector3 = v0[0]
	var uv0: Vector2 = v0[1]
	for i in range(1, n - 1):
		var v1: Array = poly[i]
		var v2: Array = poly[i + 1]
		var p1: Vector3 = v1[0]
		var p2: Vector3 = v2[0]
		if (p2 - p0).cross(p1 - p0).length_squared() < 1e-12:
			continue
		var k := verts.size()
		verts.push_back(p0)
		verts.push_back(p1)
		verts.push_back(p2)
		norms.push_back(normal)
		norms.push_back(normal)
		norms.push_back(normal)
		uvs.push_back(uv0)
		uvs.push_back(v1[1] as Vector2)
		uvs.push_back(v2[1] as Vector2)
		indices.push_back(k)
		indices.push_back(k + 1)
		indices.push_back(k + 2)


static func _pt(buf: PackedInt32Array, vi: int, ox: float, oy: float, oz: float,
		s: float, sink_u: float) -> Vector3:
	var y_cm := float(buf[vi + 1])
	var y := oy + y_cm * s
	if sink_u > 0.0 and y_cm <= 40.0:
		y -= sink_u
	return Vector3(ox + float(buf[vi]) * s, y, oz + float(buf[vi + 2]) * s)
