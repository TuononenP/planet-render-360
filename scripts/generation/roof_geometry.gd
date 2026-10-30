class_name RoofGeometry
extends RefCounted

## Pitched roof meshes over a cleaned footprint ring (T4.2 forms, split
## out of BuildingBuilder in T4.6): gabled/hipped/mansard ridge faces
## along the footprint's own long side, pyramidal/dome apex fans, and
## eave overhangs (offset_ring) so a chalet's roof reaches past its
## walls. A leaf class like RingGeometry: it names no builder, returns
## meshes, and the caller attaches materials.

## The ring offset outward by d (mitred, miter capped at 3d) — the eave
## line of an overhanging roof. Winding-agnostic; d <= 0 returns it as is.
static func offset_ring(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	if d <= 0.0 or ring.size() < 3:
		return ring
	var ccw := RingGeometry.signed_area(ring) > 0.0
	var out := PackedVector2Array()
	var n := ring.size()
	for i in n:
		var p := ring[i]
		var e0 := p - ring[(i - 1 + n) % n]
		var e1 := ring[(i + 1) % n] - p
		if e0.length() < 0.0001 or e1.length() < 0.0001:
			out.append(p)
			continue
		var n0 := Vector2(e0.y, -e0.x).normalized() if ccw else Vector2(-e0.y, e0.x).normalized()
		var n1 := Vector2(e1.y, -e1.x).normalized() if ccw else Vector2(-e1.y, e1.x).normalized()
		var denom := 1.0 + n0.dot(n1)
		var off := (n0 + n1) * d / maxf(denom, 0.0001)
		if off.length() > d * 3.0:
			off = off.normalized() * d * 3.0
		out.append(p + off)
	return out

## Pitched roof over a cleaned ring, rising rh from the eave level top:
## gabled/hipped/mansard build ridge faces along the long axis, the
## apex family fans to the centroid. Triangle soup with computed face
## normals (front = clockwise from outside, Godot convention). Rings
## whose centroid falls outside (extreme concavity) keep the flat seal
## cap only — a closed roof beats a broken fancy one.
static func form_mesh(ring: PackedVector2Array, top: float,
		rh: float, shape: String) -> ArrayMesh:
	if rh <= 0.01 or ring.size() < 3:
		return null
	var c := RingGeometry.interior_point(ring)
	if not RingGeometry.point_in_ring(c, ring):
		return null
	# Ridge along the footprint's own long side, so a block rotated 30°
	# to its street keeps its roof aligned with it (axis-aligned
	# footprints reduce to the old AABB axis).
	var u := RingGeometry.dominant_axis(ring)
	var lu := RingGeometry.half_extent(ring, c, u)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	match shape:
		"gabled":
			ridge_faces(ring, c, u, lu * 0.98, top, rh, verts, normals, uvs)
		"hipped":
			ridge_faces(ring, c, u, lu * 0.45, top, rh, verts, normals, uvs)
		"mansard":
			mansard_faces(ring, c, u, lu * 0.45, top, rh, verts, normals, uvs)
		"pyramidal":
			apex_faces(ring, c, top, rh, verts, normals, uvs, false)
		"dome":
			apex_faces(ring, c, top, rh, verts, normals, uvs, true)
		_:
			return null
	if verts.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TANGENT] = tangents_for(normals)
	# Arrays kept: MassBatch / LodRing merge roofs on the build thread.
	return MeshArrays.mesh(arrays)

## Ridge half-length shrunk until both ends sit inside the ring (0.0
## when no fit — the caller falls back to an apex fan).
static func fit_ridge(c: Vector2, u: Vector2, ru: float,
		ring: PackedVector2Array) -> float:
	var guard := 0
	while ru > 0.05 and guard < 12 \
			and (not RingGeometry.point_in_ring(c + u * ru, ring) \
				or not RingGeometry.point_in_ring(c - u * ru, ring)):
		ru *= 0.85
		guard += 1
	if not RingGeometry.point_in_ring(c + u * ru, ring) \
			or not RingGeometry.point_in_ring(c - u * ru, ring):
		return 0.0
	return ru

## One quad per ring edge from the eaves to the raised ridge segment:
## full-span ridges read as gabled (near-vertical gable ends), short
## ridges as hipped.
static func ridge_faces(ring: PackedVector2Array, c: Vector2, u: Vector2,
		ru: float, top: float, rh: float, verts: PackedVector3Array,
		normals: PackedVector3Array, uvs: PackedVector2Array) -> void:
	ru = fit_ridge(c, u, ru, ring)
	if ru <= 0.0:
		apex_faces(ring, c, top, rh, verts, normals, uvs, false)
		return
	var r1 := c + u * ru
	var r2 := c - u * ru
	var d := r2 - r1
	var denom := maxf(d.length_squared(), 0.000001)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if (b - a).length() < 0.001:
			continue
		var pa := r1 + d * clampf((a - r1).dot(d) / denom, 0.0, 1.0)
		var pb := r1 + d * clampf((b - r1).dot(d) / denom, 0.0, 1.0)
		var a3 := Vector3(a.x, top, a.y)
		var b3 := Vector3(b.x, top, b.y)
		var pa3 := Vector3(pa.x, top + rh, pa.y)
		var pb3 := Vector3(pb.x, top + rh, pb.y)
		push_tri(verts, normals, uvs, c, a3, pa3, pb3)
		push_tri(verts, normals, uvs, c, a3, pb3, b3)

## Two pitches per edge: a steep lower slope to a mid ring, then a
## shallow upper slope to the short ridge — the mansard profile.
static func mansard_faces(ring: PackedVector2Array, c: Vector2, u: Vector2,
		ru: float, top: float, rh: float, verts: PackedVector3Array,
		normals: PackedVector3Array, uvs: PackedVector2Array) -> void:
	ru = fit_ridge(c, u, ru, ring)
	if ru <= 0.0:
		apex_faces(ring, c, top, rh, verts, normals, uvs, false)
		return
	var r1 := c + u * ru
	var r2 := c - u * ru
	var d := r2 - r1
	var denom := maxf(d.length_squared(), 0.000001)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if (b - a).length() < 0.001:
			continue
		var qa := r1 + d * clampf((a - r1).dot(d) / denom, 0.0, 1.0)
		var qb := r1 + d * clampf((b - r1).dot(d) / denom, 0.0, 1.0)
		var a3 := Vector3(a.x, top, a.y)
		var b3 := Vector3(b.x, top, b.y)
		var ma := a.lerp(qa, 0.38)
		var mb := b.lerp(qb, 0.38)
		var ma3 := Vector3(ma.x, top + rh * 0.62, ma.y)
		var mb3 := Vector3(mb.x, top + rh * 0.62, mb.y)
		var ta3 := Vector3(qa.x, top + rh, qa.y)
		var tb3 := Vector3(qb.x, top + rh, qb.y)
		push_tri(verts, normals, uvs, c, a3, b3, mb3)
		push_tri(verts, normals, uvs, c, a3, mb3, ma3)
		push_tri(verts, normals, uvs, c, ma3, mb3, tb3)
		push_tri(verts, normals, uvs, c, ma3, tb3, ta3)

## Fan to a raised centroid apex (domed adds a mid ring at 70% rise);
## triangles whose centroid falls outside the ring are culled — the
## flat seal cap underneath keeps concave roofs closed.
static func apex_faces(ring: PackedVector2Array, c: Vector2, top: float,
		rh: float, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, domed: bool) -> void:
	var apex := Vector3(c.x, top + rh, c.y)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if (b - a).length() < 0.001:
			continue
		if domed:
			var ma := a.lerp(c, 0.42)
			var mb := b.lerp(c, 0.42)
			var a3 := Vector3(a.x, top, a.y)
			var b3 := Vector3(b.x, top, b.y)
			var ma3 := Vector3(ma.x, top + rh * 0.70, ma.y)
			var mb3 := Vector3(mb.x, top + rh * 0.70, mb.y)
			if RingGeometry.point_in_ring((a + b + ma + mb) * 0.25, ring):
				push_tri(verts, normals, uvs, c, a3, b3, mb3)
				push_tri(verts, normals, uvs, c, a3, mb3, ma3)
			if RingGeometry.point_in_ring((ma + mb + c) / 3.0, ring):
				push_tri(verts, normals, uvs, c, ma3, mb3, apex)
		elif RingGeometry.point_in_ring((a + b + c) / 3.0, ring):
			push_tri(verts, normals, uvs, c, Vector3(a.x, top, a.y),
				Vector3(b.x, top, b.y), apex)

## One soup triangle, wound so its Godot front face (v2−v0)×(v1−v0)
## points outward-and-up from the roof centroid; degenerates dropped.
static func push_tri(verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, c: Vector2, v0: Vector3, v1: Vector3,
		v2: Vector3) -> void:
	var front := (v2 - v0).cross(v1 - v0)
	if front.length_squared() < 0.00000001:
		return
	front = front.normalized()
	var mid := (v0 + v1 + v2) / 3.0
	var ref := Vector3(mid.x - c.x, 0.35, mid.z - c.y)
	if front.dot(ref) < 0.0:
		var t := v1
		v1 = v2
		v2 = t
		front = -front
	verts.append_array([v0, v1, v2])
	for j in 3:
		normals.append(front)
	# UVs measured on the roof plane: u along the eave, v down the slope,
	# so tile courses run parallel to the eave and keep their size on a
	# steep mansard instead of stretching like a plan projection.
	var ax := slope_axes(front)
	for v in [v0, v1, v2]:
		uvs.append(Vector2(v.dot(ax[0]), v.dot(ax[1])) * 0.05)

## [along-eave, down-slope] unit axes on a roof plane of normal `n`
## (world X/Z on near-flat faces).
static func slope_axes(n: Vector3) -> Array:
	var h := Vector2(n.x, n.z)
	if h.length() < 0.05:
		return [Vector3(1, 0, 0), Vector3(0, 0, 1)]
	h = h.normalized()
	var d := Vector3(h.x, 0.0, h.y)
	var down := (d - n * d.dot(n)).normalized()
	return [Vector3(-h.y, 0.0, h.x), down]

## Tangents for soup faces built by push_tri: +u along the eave, w so the
## binormal points to −v (Godot generate_tangents convention).
static func tangents_for(normals: PackedVector3Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for n in normals:
		var ax := slope_axes(n)
		var t: Vector3 = ax[0]
		var w := 1.0 if n.cross(t).dot(-(ax[1] as Vector3)) > 0.0 else -1.0
		out.append_array([t.x, t.y, t.z, w])
	return out
