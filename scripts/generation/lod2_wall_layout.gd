class_name Lod2WallLayout
extends RefCounted

## Decodes LoD2.2 and tall sloped-roof wall triangle soups into matched windowed
## and blank-cladding surfaces so windows are never sliced by gable slopes,
## skillion ramps, vertical corners, facade steps or narrow wall strips.
##
## Per connected coplanar wall patch (clustered using each triangle's own plane
## normal so wide walls angled off bucket centres never split along diagonals):
##   1. Snaps horizontal window bays (`u`) to an integer count across the patch
##      width so vertical wall edges and corners always fall on solid piers.
##   2. Anchors vertical storeys (`y`) consistently so floor lines align across
##      corners, wing steps and sloped eaves without chopping window rows.
##   3. Tests every (bay, storey) cell's safe window box against the 2D wall
##      patch; cells that fit wholly inside stay windowed, while cells clipped
##      by gable/skillion slopes or narrow strips route to blank masonry with
##      identical (u, v) coordinates so courses continue unbroken across the seam.

const MIN_BAY_M := 1.6
const MIN_BAY_SHARE := 0.62
const MIN_WALL_H := 2.2
const PAD_U := 0.06
const PAD_Y := 0.05
const SEAM_TOL_M := 0.04
const PLANE_OFFSET_M := 0.14
const PATCH_TOUCH_M := 0.08
const NORMAL_COS_MIN := 0.994


static func decode(buf: PackedInt32Array, v_off: int, i_off: int, n_verts: int, n_idx: int,
		ox: float, oy: float, oz: float, m2u: float, bay_m: float, bays: float,
		floor_h: float, sink_u: float, split_blank: bool) -> Dictionary:
	var n_tri := n_idx / 3
	var win := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	var blank := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	var s := 0.01 * m2u
	var sink_m := sink_u / m2u if sink_u > 0.0 else 0.0
	var min_w := maxf(MIN_BAY_M, bay_m * MIN_BAY_SHARE)

	var raw_tris: Array = []
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
		var cross := (p2 - p0).cross(p1 - p0)
		var nl := cross.length()
		if nl < 1e-6:
			continue
		var n := cross / nl
		var hn := Vector2(n.x, n.z)
		var hl := hn.length()
		if hl < 0.75:
			continue
		hn /= hl
		var lx0 := float(buf[v0]) * 0.01
		var ly0 := float(buf[v0 + 1]) * 0.01
		var lz0 := float(buf[v0 + 2]) * 0.01
		var lx1 := float(buf[v1]) * 0.01
		var ly1 := float(buf[v1 + 1]) * 0.01
		var lz1 := float(buf[v1 + 2]) * 0.01
		var lx2 := float(buf[v2]) * 0.01
		var ly2 := float(buf[v2 + 1]) * 0.01
		var lz2 := float(buf[v2 + 2]) * 0.01
		raw_tris.append([
			p0, p1, p2, n, hn, nl * 0.5,
			lx0, ly0, lz0, lx1, ly1, lz1, lx2, ly2, lz2,
			buf[v0 + 1] <= 40, buf[v1 + 1] <= 40, buf[v2 + 1] <= 40,
		])

	for patch: Array in _cluster_coplanar(raw_tris):
		_emit_patch(win, blank, patch, bay_m, bays, floor_h, sink_m, min_w, split_blank, false)

	return {"windowed": win, "blank": blank}


## Dresses an extracted vertical gable / skillion side-wall mesh (`RoofGeometry.split_gables`)
## with uncut windows aligned to the base wall's `top_y` datum and `unit_h_u` storey height.
## Returns `[win_mesh_or_null, blank_mesh_or_null]`.
static func dress_gable_mesh(gable_mesh: ArrayMesh, top_y: float, unit_h_u: float,
		bay_m: float, bays: float, split_blank: bool) -> Array:
	if gable_mesh == null or MeshArrays.surface_count(gable_mesh) == 0:
		return [null, null]
	var src := MeshArrays.surface(gable_mesh, 0)
	var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	var sn: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	var n_tri := sv.size() / 3
	if n_tri <= 0:
		return [null, null]
	var m2u := WorldScale.metres_to_units()
	var inv_m := 1.0 / maxf(m2u, 1e-4)
	var ox := sv[0].x
	var oz := sv[0].z
	var raw_tris: Array = []
	for t in n_tri:
		var p0 := sv[t * 3]
		var p1 := sv[t * 3 + 1]
		var p2 := sv[t * 3 + 2]
		var cross := (p2 - p0).cross(p1 - p0)
		if sn.size() == sv.size() and cross.dot(sn[t * 3]) < 0.0:
			var tmp := p1
			p1 = p2
			p2 = tmp
			cross = -cross
		var nl := cross.length()
		if nl < 1e-6:
			continue
		var n := cross / nl
		var hn := Vector2(n.x, n.z)
		var hl := hn.length()
		if hl < 0.75:
			continue
		hn /= hl
		raw_tris.append([
			p0, p1, p2, n, hn, nl * 0.5,
			(p0.x - ox) * inv_m, (p0.y - top_y) * inv_m, (p0.z - oz) * inv_m,
			(p1.x - ox) * inv_m, (p1.y - top_y) * inv_m, (p1.z - oz) * inv_m,
			(p2.x - ox) * inv_m, (p2.y - top_y) * inv_m, (p2.z - oz) * inv_m,
			false, false, false,
		])
	if raw_tris.is_empty():
		return [null, null]
	var win := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	var blank := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	var sh_m := maxf(unit_h_u * inv_m, 2.0)
	var min_w := maxf(MIN_BAY_M, bay_m * MIN_BAY_SHARE)
	for patch: Array in _cluster_coplanar(raw_tris):
		_emit_patch(win, blank, patch, bay_m, bays, sh_m, 0.0, min_w, split_blank, true)
	return [_to_mesh(win), _to_mesh(blank)]


static func _to_mesh(arr: Array) -> ArrayMesh:
	var verts: PackedVector3Array = arr[0]
	var idx: PackedInt32Array = arr[3]
	if verts.is_empty() or idx.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = arr[1]
	arrays[Mesh.ARRAY_TEX_UV] = arr[2]
	arrays[Mesh.ARRAY_TANGENT] = MassBatch.tangents(verts, arr[1], arr[2], idx)
	arrays[Mesh.ARRAY_INDEX] = idx
	return MeshArrays.mesh(arrays)


## Clusters coplanar connected triangles using each triangle's own horizontal
## normal (preventing wide angled walls from splitting across diagonal edges),
## then projects each cluster onto its area-weighted mean tangent frame `(tu, y)`.
static func _cluster_coplanar(raw_tris: Array) -> Array:
	var m := raw_tris.size()
	if m == 0:
		return []
	var parent := PackedInt32Array()
	parent.resize(m)
	var cells: Dictionary = {}
	var meta: Array = []
	meta.resize(m)
	for i in m:
		parent[i] = i
		var r: Array = raw_tris[i]
		var hn: Vector2 = r[4]
		var x0 := minf(float(r[6]), minf(float(r[9]), float(r[12])))
		var x1 := maxf(float(r[6]), maxf(float(r[9]), float(r[12])))
		var y0 := minf(float(r[7]), minf(float(r[10]), float(r[13])))
		var y1 := maxf(float(r[7]), maxf(float(r[10]), float(r[13])))
		var z0 := minf(float(r[8]), minf(float(r[11]), float(r[14])))
		var z1 := maxf(float(r[8]), maxf(float(r[11]), float(r[14])))
		var cx := (float(r[6]) + float(r[9]) + float(r[12])) / 3.0
		var cz := (float(r[8]) + float(r[11]) + float(r[14])) / 3.0
		meta[i] = [hn, Vector2(cx, cz), x0, x1, y0, y1, z0, z1]
		var nk := Vector2i(roundi(hn.x * 8.0), roundi(hn.y * 8.0))
		if not cells.has(nk):
			cells[nk] = []
		(cells[nk] as Array).append(i)

	for nk: Vector2i in cells:
		var list_a: Array = cells[nk]
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var nk2 := Vector2i(nk.x + dx, nk.y + dz)
				if nk2.x < nk.x or (nk2.x == nk.x and nk2.y < nk.y) or not cells.has(nk2):
					continue
				var list_b: Array = cells[nk2]
				var same_cell := nk == nk2
				for ia in list_a.size():
					var i: int = list_a[ia]
					var ma: Array = meta[i]
					var hna: Vector2 = ma[0]
					var ca: Vector2 = ma[1]
					var ax0 := float(ma[2]) - PATCH_TOUCH_M
					var ax1 := float(ma[3]) + PATCH_TOUCH_M
					var ay0 := float(ma[4]) - PATCH_TOUCH_M
					var ay1 := float(ma[5]) + PATCH_TOUCH_M
					var az0 := float(ma[6]) - PATCH_TOUCH_M
					var az1 := float(ma[7]) + PATCH_TOUCH_M
					var start_b := ia + 1 if same_cell else 0
					for ib in range(start_b, list_b.size()):
						var j: int = list_b[ib]
						var mb: Array = meta[j]
						if ax0 > float(mb[3]) or float(mb[2]) > ax1 \
								or ay0 > float(mb[5]) or float(mb[4]) > ay1 \
								or az0 > float(mb[7]) or float(mb[6]) > az1:
							continue
						var hnb: Vector2 = mb[0]
						if hna.dot(hnb) < NORMAL_COS_MIN:
							continue
						var d_xz: Vector2 = (mb[1] as Vector2) - ca
						if absf(d_xz.dot(hna)) > PLANE_OFFSET_M or absf(d_xz.dot(hnb)) > PLANE_OFFSET_M:
							continue
						var ri := _find(parent, i)
						var rj := _find(parent, j)
						if ri != rj:
							parent[ri] = rj

	var comps: Dictionary = {}
	for i in m:
		var root_i := _find(parent, i)
		if not comps.has(root_i):
			comps[root_i] = []
		(comps[root_i] as Array).append(raw_tris[i])

	var out: Array = []
	for grp: Array in comps.values():
		var hsum := Vector2.ZERO
		for r: Array in grp:
			hsum += (r[4] as Vector2) * maxf(float(r[5]), 1e-4)
		var bhn := hsum.normalized() if hsum.length_squared() > 1e-8 else (grp[0][4] as Vector2)
		var tu := Vector2(bhn.y, -bhn.x)
		var patch: Array = []
		for r: Array in grp:
			var u0 := float(r[6]) * tu.x + float(r[8]) * tu.y
			var ly0 := float(r[7])
			var u1 := float(r[9]) * tu.x + float(r[11]) * tu.y
			var ly1 := float(r[10])
			var u2 := float(r[12]) * tu.x + float(r[14]) * tu.y
			var ly2 := float(r[13])
			patch.append([
				r[0], r[1], r[2], r[3],
				u0, ly0, u1, ly1, u2, ly2,
				0.0,
				minf(u0, minf(u1, u2)), maxf(u0, maxf(u1, u2)),
				minf(ly0, minf(ly1, ly2)), maxf(ly0, maxf(ly1, ly2)),
				r[15], r[16], r[17],
			])
		out.append(patch)
	return out


static func _find(parent: PackedInt32Array, x: int) -> int:
	while parent[x] != x:
		parent[x] = parent[parent[x]]
		x = parent[x]
	return x


static func _emit_patch(win: Array, blank: Array, patch: Array, bay_m: float, bays: float,
		floor_h: float, sink_m: float, min_w: float, split_blank: bool, lock_sh: bool) -> void:
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
	var y_base := 0.0 if (lock_sh or y_min <= 0.6) else y_min
	var span_y := y_max - y_base

	if span_u < min_w or span_y < MIN_WALL_H:
		var bw_b := maxf(bay_m, 1.0)
		var sh_b := floor_h if lock_sh else maxf(floor_h, 2.5)
		var u_orig := u_min if split_blank else (u_min - 0.14 * bw_b)
		var y_anc_b := float(ceili(y_max / sh_b)) * sh_b if lock_sh else y_max
		_emit_patch_raw(blank if split_blank else win, patch, u_orig, bw_b, bays, y_anc_b, sh_b, sink_m)
		return

	var n_cols := maxi(1, roundi(span_u / maxf(bay_m, 1.0)))
	var bw := span_u / float(n_cols)

	# Fast path for clean rectangular walls: when the triangles fill the AABB
	# rectangle and every vertex sits at top or bottom, every cell is valid.
	var aabb_area := span_u * (y_max - y_min)
	if aabb_area > 0.0 and area_sum >= aabb_area * 0.985 and area_sum <= aabb_area * 1.015 \
			and (not split_blank or (not lock_sh and y_min <= 0.6)) \
			and _is_rect_patch(patch, y_min, y_max):
		var sh_r := floor_h if (lock_sh or y_min > 0.6) else _snap_storey_h(span_y, floor_h)
		var y_anc_r := float(ceili(y_max / sh_r)) * sh_r if (lock_sh or y_min > 0.6) \
			else (y_base + float(maxi(1, roundi(span_y / sh_r))) * sh_r)
		_emit_patch_raw(win, patch, u_min, bw, bays, y_anc_r, sh_r, sink_m)
		return

	var tris_2d := _prep_tris_2d(patch)

	var sh := floor_h
	var y_origin := 0.0 if (lock_sh or y_min > 0.6) else y_base
	if not lock_sh and y_min <= 0.6:
		var eave_y := _find_eave_y(tris_2d, u_min, u_max, n_cols, bw, y_base, y_max)
		if eave_y - y_base >= MIN_WALL_H:
			var span_e := (y_max - y_base) if (y_max - eave_y <= 0.20) else (eave_y - y_base)
			sh = _snap_storey_h(span_e, floor_h)
	var n_rows := maxi(1, ceili((y_max - y_origin - 1e-4) / sh))
	var y_anchor := y_origin + float(n_rows) * sh

	if not split_blank:
		_emit_patch_raw(win, patch, u_min, bw, bays, y_anchor, sh, sink_m)
		return

	var r0 := maxi(0, floori((y_min - y_origin) / sh))
	var active_rows := maxi(1, n_rows - r0)
	var valid: Array = []
	valid.resize(active_rows)
	var any_win := false
	var any_blank := false
	var pad_u := bw * PAD_U
	var pad_y := sh * PAD_Y
	for ar in active_rows:
		var r := r0 + ar
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
		valid[ar] = row_v

	if not any_win:
		_emit_patch_raw(blank, patch, u_min, bw, bays, y_anchor, sh, sink_m)
		return
	if not any_blank:
		_emit_patch_raw(win, patch, u_min, bw, bays, y_anchor, sh, sink_m)
		return

	var inv_u := 1.0 / (bw * bays)
	var inv_v := 1.0 / sh
	var dv_s := sink_m * inv_v
	var h_cuts := PackedFloat32Array()
	for ar in range(1, active_rows):
		var prev: PackedByteArray = valid[ar - 1]
		var curr: PackedByteArray = valid[ar]
		for c in n_cols:
			if prev[c] != curr[c]:
				h_cuts.append(y_origin + float(r0 + ar) * sh)
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
			var ar := clampi(floori((cy - y_origin) / sh) - r0, 0, active_rows - 1)
			var row_v: PackedByteArray = valid[ar]
			var v_cuts := PackedFloat32Array()
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


## Finds the lowest flat/outer eave height: outer vertical edges first, then
## flat horizontal steps (`|dy/du| <= 0.12`) across interior bay centres so a
## diagonal slope never pulls the eave height down to a low corner.
static func _find_eave_y(tris_2d: Array, u_min: float, u_max: float, n_cols: int, bw: float,
		y_base: float, y_max: float) -> float:
	var eave := INF
	for uq in [u_min + 0.02, u_max - 0.02]:
		var ext := _vertical_extent_at_u(tris_2d, uq)
		if ext.x <= y_base + 0.6 and ext.y - y_base >= MIN_WALL_H:
			eave = minf(eave, ext.y)
	for c in n_cols:
		var uc := u_min + (float(c) + 0.5) * bw
		var ext_l := _vertical_extent_at_u(tris_2d, uc - 0.15)
		var ext_r := _vertical_extent_at_u(tris_2d, uc + 0.15)
		if ext_l.x <= y_base + 0.6 and ext_r.x <= y_base + 0.6 \
				and ext_l.y - y_base >= MIN_WALL_H and absf(ext_r.y - ext_l.y) <= 0.04:
			eave = minf(eave, (ext_l.y + ext_r.y) * 0.5)
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
