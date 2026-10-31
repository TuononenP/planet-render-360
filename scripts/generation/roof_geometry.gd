class_name RoofGeometry
extends RefCounted

## Pitched roof meshes over a cleaned footprint ring (T4.2 forms, split
## out of BuildingBuilder in T4.6): gabled/hipped/mansard ridge faces
## along the footprint's own long side, pyramidal/dome apex fans, and
## eave overhangs (offset_ring) so a chalet's roof reaches past its
## walls. A leaf class like RingGeometry: it names no builder, returns
## meshes, and the caller attaches materials.

## Footprints at least this large (m²) and this far from convex (ring
## area over hull area) take the inset roof: a single ridge or apex
## cannot span a courtyard block's wings, and fans from one point shear
## into spokes of stretched slivers with a serrated eave.
const INSET_MIN_AREA_M2 := 380.0
const INSET_CONVEX_RATIO := 0.94

## The ring offset outward by d (mitred, miter capped at 3d) — the eave
## line of an overhanging roof. Winding-agnostic; d <= 0 returns it as is.
static func offset_ring(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	if d <= 0.0 or ring.size() < 3:
		return ring
	return _shift_ring(ring, d)

static func _shift_ring(ring: PackedVector2Array, d: float,
		miter: float = 3.0) -> PackedVector2Array:
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
		if off.length() > absf(d) * miter:
			off = off.normalized() * absf(d) * miter
		out.append(p + off)
	return out

## Pitched roof over a cleaned ring, rising rh from the eave level top:
## gabled/hipped/mansard build ridge faces along the long axis, the
## apex family fans to the centroid. Triangle soup with computed face
## normals (front = clockwise from outside, Godot convention). Rings
## whose centroid falls outside (extreme concavity) keep the flat seal
## cap only — a closed roof beats a broken fancy one.
## `party` (one flag per ring edge, PartyWalls) keeps gables on shared
## walls; `gable_front` turns a terrace ridge to face them with gables;
## `holes` (courtyards) take a chamfered roof sloping to both eaves.
static func form_mesh(ring: PackedVector2Array, top: float,
		rh: float, shape: String, party: PackedByteArray = PackedByteArray(),
		gable_front: bool = false, holes: Array = []) -> ArrayMesh:
	if rh <= 0.01 or ring.size() < 3:
		return null
	var pitched := shape in RoofForms.RIDGED or shape == "pyramidal"
	var inset := pitched and (not holes.is_empty() or needs_inset(ring) or ring.size() > 8)
	var c := RingGeometry.interior_point(ring)
	if not inset and not RingGeometry.point_in_ring(c, ring):
		return null
	# Ridge along the footprint's own long side, so a block rotated 30°
	# to its street keeps its roof aligned with it (axis-aligned
	# footprints reduce to the old AABB axis).
	var u := RingGeometry.dominant_axis(ring)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	if inset:
		# Courtyard blocks, concave masses and curved outlines slope to every
		# eave (RoofSkeleton): party gables or a fitted ridge there stood as
		# screens and shards across the roofscape.
		if not RoofSkeleton.faces(ring, holes, top, rh, shape in ["mansard", "gambrel"],
				verts, normals, uvs, u) and holes.is_empty():
			apex_faces(ring, c, top, rh, verts, normals, uvs, false, u)
		shape = ""
	elif not RoofForms.boxy(ring):
		party = PackedByteArray()  # party gables only on parcel-like rings
	if shape in RoofForms.RIDGED:
		if not RoofForms.ridged(ring, c, top, rh, shape, party, gable_front, verts, normals, uvs):
			apex_faces(ring, c, top, rh, verts, normals, uvs, false, u)
		shape = ""
	match shape:
		"pyramidal":
			apex_faces(ring, c, top, rh, verts, normals, uvs, false, u)
		"dome":
			apex_faces(ring, c, top, rh, verts, normals, uvs, true, u)
		"skillion":
			RoofForms.skillion(ring, c, top, rh, party, verts, normals, uvs)
		"round":
			if not RoofForms.barrel(ring, c, top, rh, verts, normals, uvs) \
					and not RoofForms.ridged(ring, c, top, rh, "gabled", party, gable_front, verts, normals, uvs):
				apex_faces(ring, c, top, rh, verts, normals, uvs, false, u)
		"":
			pass
		_:
			return null
	if verts.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TANGENT] = tangents_for(normals, u)
	# Arrays kept: MassBatch / LodRing merge roofs on the build thread.
	return MeshArrays.mesh(arrays)

## True for a large footprint that is clearly not convex (courtyard
## blocks, U and L wings): see INSET_MIN_AREA_M2.
static func needs_inset(ring: PackedVector2Array) -> bool:
	var m2u := WorldScale.metres_to_units()
	var area := absf(RingGeometry.signed_area(ring))
	if area / (m2u * m2u) < INSET_MIN_AREA_M2:
		return false
	var hull_area := absf(RingGeometry.signed_area(Geometry2D.convex_hull(ring)))
	return hull_area > 0.0 and area / hull_area < INSET_CONVEX_RATIO

## Fan to a raised centroid apex (domed adds a mid ring at 70% rise);
## triangles whose centroid falls outside the ring are culled — the
## flat seal cap underneath keeps concave roofs closed.
static func apex_faces(ring: PackedVector2Array, c: Vector2, top: float,
		rh: float, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, domed: bool, fu: Vector2 = Vector2.ZERO) -> void:
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
				push_tri(verts, normals, uvs, c, a3, b3, mb3, fu)
				push_tri(verts, normals, uvs, c, a3, mb3, ma3, fu)
			if RingGeometry.point_in_ring((ma + mb + c) / 3.0, ring):
				push_tri(verts, normals, uvs, c, ma3, mb3, apex, fu)
		elif RingGeometry.point_in_ring((a + b + c) / 3.0, ring):
			push_tri(verts, normals, uvs, c, Vector3(a.x, top, a.y),
				Vector3(b.x, top, b.y), apex, fu)

## One soup triangle, wound so its Godot front face (v2−v0)×(v1−v0)
## points outward-and-up from the roof centroid; degenerates dropped.
static func push_tri(verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, c: Vector2, v0: Vector3, v1: Vector3,
		v2: Vector3, fu: Vector2 = Vector2.ZERO, up_only: bool = false) -> void:
	var front := (v2 - v0).cross(v1 - v0)
	if front.length_squared() < 0.00000001:
		return
	front = front.normalized()
	var mid := (v0 + v1 + v2) / 3.0
	var ref := Vector3(0.0, 1.0, 0.0) if up_only else Vector3(mid.x - c.x, 0.35, mid.z - c.y)
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
	# steep mansard instead of stretching like a plan projection. The
	# facing snaps to the roof's own axes (`fu`), so the many facets over
	# a curved footprint share a few courses instead of fanning out as
	# spokes of rotated tiles.
	var ax := slope_axes(front, fu)
	for v in [v0, v1, v2]:
		uvs.append(Vector2(v.dot(ax[0]), v.dot(ax[1])) * 0.05)

## [along-eave, down-slope] unit axes on a roof plane of normal `n`
## (world X/Z on near-flat faces).
static func slope_axes(n: Vector3, fu: Vector2 = Vector2.ZERO) -> Array:
	var h := Vector2(n.x, n.z)
	if h.length() < 0.05:
		return [Vector3(1, 0, 0), Vector3(0, 0, 1)]
	h = h.normalized()
	if fu != Vector2.ZERO:
		var f := fu.normalized()
		var q := roundf(atan2(h.dot(Vector2(-f.y, f.x)), h.dot(f)) / (PI * 0.5)) * (PI * 0.5)
		h = f.rotated(q)
	var d := Vector3(h.x, 0.0, h.y)
	var down := (d - n * d.dot(n)).normalized()
	return [Vector3(-h.y, 0.0, h.x), down]

## Tangents for soup faces built by push_tri: +u along the eave, w so the
## binormal points to −v (Godot generate_tangents convention).
static func tangents_for(normals: PackedVector3Array,
		fu: Vector2 = Vector2.ZERO) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for n in normals:
		var ax := slope_axes(n, fu)
		var t: Vector3 = ax[0]
		var w := 1.0 if n.cross(t).dot(-(ax[1] as Vector3)) > 0.0 else -1.0
		out.append_array([t.x, t.y, t.z, w])
	return out
