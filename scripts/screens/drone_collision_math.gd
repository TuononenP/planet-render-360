class_name DroneCollisionMath
extends RefCounted

## Pure 3D geometry, spatial-hash and sphere-depenetration kernels for
## DroneObstacles (polygon prisms, oriented bounding boxes, and lazily
## binned 3D triangle meshes).

const CELL_M := 16.0
const TRI_CELL_M := 4.0

static func make_box_xz(centre: Vector2, forward: Vector2, length: float, width: float,
		y_lo: float, y_hi: float) -> Dictionary:
	if length <= 0.01 or width <= 0.01 or y_hi <= y_lo:
		return {}
	var f := forward.normalized()
	if f == Vector2.ZERO:
		f = Vector2.RIGHT
	var ax := Vector3(f.x, 0.0, f.y)
	var ay := Vector3.UP
	var az := Vector3(-f.y, 0.0, f.x)
	var ext := Vector3(length * 0.5, (y_hi - y_lo) * 0.5, width * 0.5)
	var c := Vector3(centre.x, (y_lo + y_hi) * 0.5, centre.y)
	var rx := absf(ax.x) * ext.x + absf(az.x) * ext.z
	var rz := absf(ax.z) * ext.x + absf(az.z) * ext.z
	return {
		"c": c, "ax": ax, "ay": ay, "az": az, "ext": ext,
		"min_xz": Vector2(c.x - rx, c.z - rz),
		"max_xz": Vector2(c.x + rx, c.z + rz),
		"y_lo": y_lo, "y_hi": y_hi,
	}

static func make_obb(xf: Transform3D, local_box: AABB) -> Dictionary:
	var sx := xf.basis.x.length()
	var sy := xf.basis.y.length()
	var sz := xf.basis.z.length()
	if sx < 0.001 or sy < 0.001 or sz < 0.001:
		return {}
	var ax := xf.basis.x / sx
	var ay := xf.basis.y / sy
	var az := xf.basis.z / sz
	var ext := local_box.size * 0.5 * Vector3(sx, sy, sz)
	if ext.x <= 0.01 or ext.y <= 0.01 or ext.z <= 0.01:
		return {}
	var c := xf * (local_box.position + local_box.size * 0.5)
	var rx := absf(ax.x) * ext.x + absf(ay.x) * ext.y + absf(az.x) * ext.z
	var ry := absf(ax.y) * ext.x + absf(ay.y) * ext.y + absf(az.y) * ext.z
	var rz := absf(ax.z) * ext.x + absf(ay.z) * ext.y + absf(az.z) * ext.z
	return {
		"c": c, "ax": ax, "ay": ay, "az": az, "ext": ext,
		"min_xz": Vector2(c.x - rx, c.z - rz),
		"max_xz": Vector2(c.x + rx, c.z + rz),
		"y_lo": c.y - ry, "y_hi": c.y + ry,
	}

static func insert_rect(grid: Dictionary, r: Rect2, idx: int) -> void:
	var x0 := floori(r.position.x / CELL_M)
	var x1 := floori(r.end.x / CELL_M)
	var z0 := floori(r.position.y / CELL_M)
	var z1 := floori(r.end.y / CELL_M)
	for cz in range(z0, z1 + 1):
		for cx in range(x0, x1 + 1):
			var key := Vector2i(cx, cz)
			if not grid.has(key):
				grid[key] = PackedInt32Array([idx])
			else:
				var arr: PackedInt32Array = grid[key]
				arr.append(idx)
				grid[key] = arr

static func cell_lookup(grid: Dictionary, p: Vector2, pad: float) -> PackedInt32Array:
	var x0 := floori((p.x - pad) / CELL_M)
	var x1 := floori((p.x + pad) / CELL_M)
	var z0 := floori((p.y - pad) / CELL_M)
	var z1 := floori((p.y + pad) / CELL_M)
	if x0 == x1 and z0 == z1:
		return grid.get(Vector2i(x0, z0), PackedInt32Array())
	var seen := {}
	var out := PackedInt32Array()
	for cz in range(z0, z1 + 1):
		for cx in range(x0, x1 + 1):
			var arr: PackedInt32Array = grid.get(Vector2i(cx, cz), PackedInt32Array())
			for idx in arr:
				if not seen.has(idx):
					seen[idx] = true
					out.append(idx)
	return out

static func push_from_prism(p: Vector3, pr: Dictionary, radius: float, r2: float) -> Vector3:
	var ring: PackedVector2Array = pr["ring"]
	var holes: Array = pr["holes"]
	var y_lo := float(pr["y_lo"])
	var y_hi := float(pr["y_hi"])
	var xz := Vector2(p.x, p.z)
	var in_outer := Geometry2D.is_point_in_polygon(xz, ring)
	var in_hole_idx := -1
	if in_outer:
		for hi in holes.size():
			var h := holes[hi] as PackedVector2Array
			if h.size() >= 3 and Geometry2D.is_point_in_polygon(xz, h):
				in_hole_idx = hi
				break
	var inside_xz := in_outer and in_hole_idx < 0
	if not inside_xz:
		var q_xz := closest_ring_point(xz, holes[in_hole_idx] as PackedVector2Array) \
			if in_hole_idx >= 0 else closest_ring_point(xz, ring)
		var closest := Vector3(q_xz.x, clampf(p.y, y_lo, y_hi), q_xz.y)
		var diff := p - closest
		var d2 := diff.length_squared()
		if d2 >= r2:
			return Vector3.ZERO
		if d2 > 1e-8:
			var dist := sqrt(d2)
			return diff * ((radius - dist) / dist)
		return Vector3(0.0, radius, 0.0)

	if p.y >= y_hi:
		var dy := p.y - y_hi
		return Vector3(0.0, radius - dy, 0.0) if dy < radius else Vector3.ZERO
	if p.y <= y_lo:
		var dy := y_lo - p.y
		return Vector3(0.0, -(radius - dy), 0.0) if dy < radius else Vector3.ZERO

	var best_wall := closest_ring_point(xz, ring)
	var best_d := xz.distance_to(best_wall)
	for h in holes:
		var hole := h as PackedVector2Array
		if hole.size() >= 3:
			var hq := closest_ring_point(xz, hole)
			var hd := xz.distance_to(hq)
			if hd < best_d:
				best_d = hd
				best_wall = hq
	var d_top := y_hi - p.y
	var d_bot := p.y - y_lo
	if d_top <= best_d and d_top <= d_bot:
		return Vector3(0.0, d_top + radius, 0.0)
	if d_bot <= best_d and d_bot <= d_top:
		return Vector3(0.0, -(d_bot + radius), 0.0)
	var out_dir := (best_wall - xz).normalized()
	if out_dir == Vector2.ZERO:
		out_dir = Vector2(0.0, 1.0)
	return Vector3(out_dir.x * (best_d + radius), 0.0, out_dir.y * (best_d + radius))

static func push_from_obb(p: Vector3, ob: Dictionary, radius: float, r2: float) -> Vector3:
	if p.y < float(ob["y_lo"]) - radius or p.y > float(ob["y_hi"]) + radius:
		return Vector3.ZERO
	var mn: Vector2 = ob["min_xz"]
	var mx: Vector2 = ob["max_xz"]
	if p.x < mn.x - radius or p.x > mx.x + radius or p.z < mn.y - radius or p.z > mx.y + radius:
		return Vector3.ZERO
	var c: Vector3 = ob["c"]
	var ax: Vector3 = ob["ax"]
	var ay: Vector3 = ob["ay"]
	var az: Vector3 = ob["az"]
	var ext: Vector3 = ob["ext"]
	var d := p - c
	var lx := d.dot(ax)
	var ly := d.dot(ay)
	var lz := d.dot(az)
	if absf(lx) <= ext.x and absf(ly) <= ext.y and absf(lz) <= ext.z:
		var px := ext.x - absf(lx)
		var py := ext.y - absf(ly)
		var pz := ext.z - absf(lz)
		if py <= px and py <= pz:
			return ay * ((py + radius) * (1.0 if ly >= 0.0 else -1.0))
		if px <= pz:
			return ax * ((px + radius) * (1.0 if lx >= 0.0 else -1.0))
		return az * ((pz + radius) * (1.0 if lz >= 0.0 else -1.0))
	var closest := c + ax * clampf(lx, -ext.x, ext.x) \
		+ ay * clampf(ly, -ext.y, ext.y) + az * clampf(lz, -ext.z, ext.z)
	var diff := p - closest
	var d2 := diff.length_squared()
	if d2 >= r2:
		return Vector3.ZERO
	if d2 > 1e-8:
		var dist := sqrt(d2)
		return diff * ((radius - dist) / dist)
	return ay * radius

static func obb_overlaps_xz(ob: Dictionary, xz: Vector2, pad: float) -> bool:
	var mn: Vector2 = ob["min_xz"]
	var mx: Vector2 = ob["max_xz"]
	if xz.x < mn.x - pad or xz.x > mx.x + pad or xz.y < mn.y - pad or xz.y > mx.y + pad:
		return false
	var c: Vector3 = ob["c"]
	var ax: Vector3 = ob["ax"]
	var az: Vector3 = ob["az"]
	var ext: Vector3 = ob["ext"]
	var f2 := Vector2(ax.x, ax.z)
	var s2 := Vector2(az.x, az.z)
	var fl := f2.length()
	var sl := s2.length()
	if fl < 0.01 or sl < 0.01:
		return true
	f2 /= fl
	s2 /= sl
	var rel := Vector2(xz.x - c.x, xz.y - c.z)
	return absf(rel.dot(f2)) <= ext.x * fl + pad and absf(rel.dot(s2)) <= ext.z * sl + pad

static func ensure_mesh_grid(cache: Dictionary, mesh: Mesh) -> Dictionary:
	var mid := mesh.get_instance_id()
	if cache.has(mid):
		return cache[mid]
	var tris := PackedVector3Array()
	var sc := MeshArrays.surface_count(mesh)
	for s in sc:
		var arr := MeshArrays.surface(mesh, s)
		if arr.is_empty() or arr[Mesh.ARRAY_VERTEX] == null:
			continue
		var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if sv.is_empty():
			continue
		if arr[Mesh.ARRAY_INDEX] != null and not (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
			var si: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var base := tris.size()
			tris.resize(base + si.size())
			for i in si.size():
				tris[base + i] = sv[si[i]]
		else:
			tris.append_array(sv)
	var cells := {}
	var tri_count := int(tris.size() / 3)
	for t in tri_count:
		var a := tris[t * 3]
		var b := tris[t * 3 + 1]
		var c := tris[t * 3 + 2]
		var x0 := floori(minf(a.x, minf(b.x, c.x)) / TRI_CELL_M)
		var x1 := floori(maxf(a.x, maxf(b.x, c.x)) / TRI_CELL_M)
		var z0 := floori(minf(a.z, minf(b.z, c.z)) / TRI_CELL_M)
		var z1 := floori(maxf(a.z, maxf(b.z, c.z)) / TRI_CELL_M)
		for cz in range(z0, z1 + 1):
			for cx in range(x0, x1 + 1):
				var key := Vector2i(cx, cz)
				if not cells.has(key):
					cells[key] = PackedInt32Array([t])
				else:
					var list: PackedInt32Array = cells[key]
					list.append(t)
					cells[key] = list
	var built := {"verts": tris, "cells": cells}
	cache[mid] = built
	return built

static func push_from_mesh(cache: Dictionary, p: Vector3, md: Dictionary, radius: float, r2: float) -> Vector3:
	var grid := ensure_mesh_grid(cache, md["mesh"] as Mesh)
	var tris: PackedVector3Array = grid["verts"]
	if tris.is_empty():
		return Vector3.ZERO
	var cells: Dictionary = grid["cells"]
	var xf: Transform3D = md["xf"]
	var inv_xf: Transform3D = md["inv_xf"]
	var lp := inv_xf * p
	var pad_x := (absf(inv_xf.basis.x.x) + absf(inv_xf.basis.y.x) + absf(inv_xf.basis.z.x)) * radius
	var pad_z := (absf(inv_xf.basis.x.z) + absf(inv_xf.basis.y.z) + absf(inv_xf.basis.z.z)) * radius
	var x0 := floori((lp.x - pad_x) / TRI_CELL_M)
	var x1 := floori((lp.x + pad_x) / TRI_CELL_M)
	var z0 := floori((lp.z - pad_z) / TRI_CELL_M)
	var z1 := floori((lp.z + pad_z) / TRI_CELL_M)
	var seen := {}
	var cur := p
	for cz in range(z0, z1 + 1):
		for cx in range(x0, x1 + 1):
			var arr: PackedInt32Array = cells.get(Vector2i(cx, cz), PackedInt32Array())
			for t in arr:
				if seen.has(t):
					continue
				seen[t] = true
				var wa := xf * tris[t * 3]
				var wb := xf * tris[t * 3 + 1]
				var wc := xf * tris[t * 3 + 2]
				var q := closest_point_on_triangle(cur, wa, wb, wc)
				var diff := cur - q
				var d2 := diff.length_squared()
				if d2 >= r2:
					continue
				var dist := sqrt(d2)
				if dist > 1e-6:
					cur += diff * ((radius - dist) / dist)
				else:
					var n := (wb - wa).cross(wc - wa).normalized()
					cur += (n if n != Vector3.ZERO else Vector3.UP) * radius
	return cur - p

static func mesh_support_at(cache: Dictionary, md: Dictionary, p_xz: Vector2, max_y: float, radius: float) -> float:
	var grid := ensure_mesh_grid(cache, md["mesh"] as Mesh)
	var tris: PackedVector3Array = grid["verts"]
	if tris.is_empty():
		return -INF
	var cells: Dictionary = grid["cells"]
	var xf: Transform3D = md["xf"]
	var inv_xf: Transform3D = md["inv_xf"]
	var lp := inv_xf * Vector3(p_xz.x, max_y, p_xz.y)
	var pad_x := (absf(inv_xf.basis.x.x) + absf(inv_xf.basis.z.x)) * radius
	var pad_z := (absf(inv_xf.basis.x.z) + absf(inv_xf.basis.z.z)) * radius
	var x0 := floori((lp.x - pad_x) / TRI_CELL_M)
	var x1 := floori((lp.x + pad_x) / TRI_CELL_M)
	var z0 := floori((lp.z - pad_z) / TRI_CELL_M)
	var z1 := floori((lp.z + pad_z) / TRI_CELL_M)
	var top := -INF
	var seen := {}
	for cz in range(z0, z1 + 1):
		for cx in range(x0, x1 + 1):
			var arr: PackedInt32Array = cells.get(Vector2i(cx, cz), PackedInt32Array())
			for t in arr:
				if seen.has(t):
					continue
				seen[t] = true
				var wa := xf * tris[t * 3]
				var wb := xf * tris[t * 3 + 1]
				var wc := xf * tris[t * 3 + 2]
				var tri_hi := maxf(wa.y, maxf(wb.y, wc.y))
				if tri_hi <= top or tri_hi > max_y:
					continue
				var n := (wb - wa).cross(wc - wa)
				if absf(n.y) <= Vector2(n.x, n.z).length():
					continue
				var t2 := PackedVector2Array([Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), Vector2(wc.x, wc.z)])
				if View360._ring_distance(p_xz, t2) <= radius:
					top = maxf(top, tri_hi)
	return top

## Exact closest 3D point on triangle (a, b, c) to `p` (Ericson §5.1.5).
static func closest_point_on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		var denom := d1 - d3
		return a + ab * (d1 / denom) if denom > 1e-10 else a
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		var denom := d2 - d6
		return a + ac * (d2 / denom) if denom > 1e-10 else a
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		var denom := (d4 - d3) + (d5 - d6)
		return b + (c - b) * ((d4 - d3) / denom) if denom > 1e-10 else b
	var sum := va + vb + vc
	if sum <= 1e-10:
		return a
	var inv := 1.0 / sum
	return a + ab * (vb * inv) + ac * (vc * inv)

static func closest_ring_point(p: Vector2, ring: PackedVector2Array) -> Vector2:
	var best := ring[0]
	var best_d2 := INF
	var n := ring.size()
	for i in n:
		var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % n])
		var d2 := p.distance_squared_to(q)
		if d2 < best_d2:
			best_d2 = d2
			best = q
	return best

static func in_courtyard(xz: Vector2, holes: Array, clear_m: float) -> bool:
	for h in holes:
		var hole := h as PackedVector2Array
		if hole.size() >= 3 and Geometry2D.is_point_in_polygon(xz, hole):
			return xz.distance_to(closest_ring_point(xz, hole)) > clear_m
	return false

static func footprint_of(b: Dictionary) -> PackedVector2Array:
	var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if fp.size() >= 3:
		return fp
	var sx := float(b.get("size_x", 0.0))
	var sz := float(b.get("size_z", 0.0))
	if sx <= 0.0 or sz <= 0.0:
		return PackedVector2Array()
	var cx := float(b.get("x", 0.0))
	var cz := float(b.get("z", 0.0))
	var hx := sx * 0.5
	var hz := sz * 0.5
	return PackedVector2Array([
		Vector2(cx - hx, cz - hz), Vector2(cx + hx, cz - hz),
		Vector2(cx + hx, cz + hz), Vector2(cx - hx, cz + hz)])

static func ring_ground_range(ring: PackedVector2Array, b: Dictionary, ground: GroundTruth) -> Vector2:
	var cx := float(b.get("x", ring[0].x))
	var cz := float(b.get("z", ring[0].y))
	var cg := ground.height_at_world(cx, cz)
	var lo := cg
	var hi := cg
	var step := maxi(1, int(ring.size() / 8))
	for i in range(0, ring.size(), step):
		var g := ground.height_at_world(ring[i].x, ring[i].y)
		lo = minf(lo, g)
		hi = maxf(hi, g)
	return Vector2(lo, hi)

static func roof_allowance(b: Dictionary) -> float:
	var rh := float(b.get("roof_height", 0.0))
	if rh > 0.0:
		return rh
	var shape := str(b.get("roof_shape", ""))
	if shape in ["gabled", "hipped", "pyramidal", "dome", "mansard", "gambrel", "onion"]:
		return 2.5
	return 0.0

static func building_height_m(b: Dictionary, floor_min: float = 3.0) -> float:
	var h := float(b.get("height", 0.0))
	var lv := float(b.get("levels", 0.0))
	if lv > 0.0:
		h = maxf(h, lv * 3.3)
	return maxf(h, floor_min)

static func building_top_y(b: Dictionary, ground: GroundTruth) -> float:
	var fp := footprint_of(b)
	var gy := ring_ground_range(fp, b, ground).y if fp.size() >= 3 \
		else ground.height_at_world(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	var h := building_height_m(b, 0.0)
	for part in b.get("parts", []):
		if part is Dictionary:
			h = maxf(h, building_height_m(part as Dictionary, 0.0))
	return gy + h + roof_allowance(b)
