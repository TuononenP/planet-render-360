class_name BuildingTrim
extends RefCounted

## Real roofline relief on near buildings (the same on every tier, AC-12:
## a tier never moves geometry; a few quads per building): the facade
## textures paint cornices and parapets, but painted relief has no
## silhouette, casts no shadow and vanishes edge-on. Here:
## - pitched/mansard roofs get a projecting stone cornice at the eave:
##   soffit, front face and a weathered top, so every block reads with a
##   shadow line under its roof;
## - flat roofs get a parapet: the roof deck sits PARAPET_H_M below the
##   wall top behind an inner face and a coping that oversails the wall.
## Both stay within the building's real height (OSM heights include the
## parapet), so no top moves.
## One stone material each per build (few draw calls; LodRing merges
## them per cell with the rest of the building).

const NONE := 0
const CORNICE := 1
const PARAPET := 2
## Cornice: projection, depth of its face, drop of its soffit below the
## wall top (m). Parapet: height, thickness, coping oversail (m).
const CORNICE_OUT_M := 0.38
const CORNICE_FACE_M := 0.32
const CORNICE_DROP_M := 0.55
const PARAPET_H_M := 0.85
const PARAPET_T_M := 0.25
const COPING_M := 0.06
const COPING_H_M := 0.08
## Trim only within this distance of the viewpoint (m), on every tier.
const RADIUS_M := 320.0

static var _mats: Dictionary = {}

## Trim kind for a building `dist_m` from the viewpoint.
static func kind(shape: String, dist_m: float) -> int:
	if dist_m > RADIUS_M:
		return NONE
	return PARAPET if shape == "flat" else CORNICE

## Height of the roof deck under `trim` (a parapet sinks it).
static func deck(top: float, trim: int) -> float:
	return top - PARAPET_H_M * WorldScale.metres_to_units() if trim == PARAPET else top

static func add(root: Node3D, ring: PackedVector2Array, top: float, trim: int) -> void:
	if trim == NONE or ring.size() < 3 or BuildingBuilder._batch != null:
		return
	var m := WorldScale.metres_to_units()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	if trim == CORNICE:
		var outer := _offset(ring, CORNICE_OUT_M * m)
		var y0 := top - CORNICE_DROP_M * m
		var y1 := y0 + CORNICE_FACE_M * m
		for i in ring.size():
			var j := (i + 1) % ring.size()
			var a := ring[i]
			var b := ring[j]
			var oa := outer[i]
			var ob := outer[j]
			var out := _out_normal(ring, i)
			# Soffit (faces down), front (faces out), wash (faces up/out).
			_quad(verts, normals, uvs, idx, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y),
				Vector3(ob.x, y0, ob.y), Vector3(oa.x, y0, oa.y), Vector3.DOWN)
			_quad(verts, normals, uvs, idx, Vector3(oa.x, y0, oa.y), Vector3(ob.x, y0, ob.y),
				Vector3(ob.x, y1, ob.y), Vector3(oa.x, y1, oa.y), Vector3(out.x, 0.0, out.y))
			_quad(verts, normals, uvs, idx, Vector3(oa.x, y1, oa.y), Vector3(ob.x, y1, ob.y),
				Vector3(b.x, top, b.y), Vector3(a.x, top, a.y),
				Vector3(out.x * 0.6, 0.8, out.y * 0.6).normalized())
	else:
		var inner := _offset(ring, -PARAPET_T_M * m)
		var cin := _offset(ring, -(PARAPET_T_M + COPING_M) * m)
		var cout := _offset(ring, COPING_M * m)
		var y0 := deck(top, trim)
		var y1 := top - COPING_H_M * m
		for i in ring.size():
			var j := (i + 1) % ring.size()
			var o3 := Vector3(_out_normal(ring, i).x, 0.0, _out_normal(ring, i).y)
			# Inner face looks onto the sunk deck (the wall is the outer).
			_quad(verts, normals, uvs, idx, Vector3(inner[i].x, y0, inner[i].y),
				Vector3(inner[j].x, y0, inner[j].y), Vector3(inner[j].x, y1, inner[j].y),
				Vector3(inner[i].x, y1, inner[i].y), -o3)
			# Coping: oversailing slab — underside lip, outer edge, top.
			_quad(verts, normals, uvs, idx, Vector3(ring[i].x, y1, ring[i].y),
				Vector3(ring[j].x, y1, ring[j].y), Vector3(cout[j].x, y1, cout[j].y),
				Vector3(cout[i].x, y1, cout[i].y), Vector3.DOWN)
			_quad(verts, normals, uvs, idx, Vector3(cout[i].x, y1, cout[i].y),
				Vector3(cout[j].x, y1, cout[j].y), Vector3(cout[j].x, top, cout[j].y),
				Vector3(cout[i].x, top, cout[i].y), o3)
			_quad(verts, normals, uvs, idx, Vector3(cin[i].x, top, cin[i].y),
				Vector3(cin[j].x, top, cin[j].y), Vector3(cout[j].x, top, cout[j].y),
				Vector3(cout[i].x, top, cout[i].y), Vector3.UP)
	if idx.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TANGENT] = MassBatch.tangents(verts, normals, uvs, idx)
	arrays[Mesh.ARRAY_INDEX] = idx
	# Arrays kept: LodRing merges these on the build thread.
	TerrainBuilder._add(root, MeshArrays.mesh(arrays), _material(trim))

## Quad a-b-c-d wound so its Godot front face points along `n`; UVs in
## metres / 2 along the edge and up the face.
static func _quad(verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, idx: PackedInt32Array, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3, n: Vector3) -> void:
	var k := verts.size()
	verts.append_array([a, b, c, d])
	for q in 4:
		normals.append(n)
	var e := (b - a).length()
	var h := (d - a).length()
	uvs.append_array([Vector2(a.x + a.z, 0.0) * 0.5, Vector2(a.x + a.z + e, 0.0) * 0.5,
		Vector2(a.x + a.z + e, h) * 0.5, Vector2(a.x + a.z, h) * 0.5])
	var front := (c - a).cross(b - a)
	if front.dot(n) >= 0.0:
		idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		idx.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

## Outward unit normal (XZ) of edge i → i+1.
static func _out_normal(ring: PackedVector2Array, i: int) -> Vector2:
	var e := ring[(i + 1) % ring.size()] - ring[i]
	var ccw := RingGeometry.signed_area(ring) > 0.0
	return (Vector2(e.y, -e.x) if ccw else Vector2(-e.y, e.x)).normalized()

## The ring offset by d (outward > 0, inward < 0), mitred, miter capped.
static func _offset(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := ring.size()
	for i in n:
		var n0 := _out_normal(ring, (i - 1 + n) % n)
		var n1 := _out_normal(ring, i)
		var denom := 1.0 + n0.dot(n1)
		var off := (n0 + n1) * d / maxf(denom, 0.0001)
		if off.length() > absf(d) * 3.0:
			off = off.normalized() * absf(d) * 3.0
		out.append(ring[i] + off)
	return out

static func _material(trim: int) -> Material:
	if _mats.has(trim):
		return _mats[trim]
	var m: Material
	if trim == CORNICE:
		m = MaterialLibrary.pbr_material("limestone",
			FacadeMaterials._calib("limestone", MaterialLibrary.PRD_LIMESTONE * 0.92), 1.0)
	else:
		m = MaterialLibrary.pbr_material("concrete",
			FacadeMaterials._calib("concrete", Color(0.36, 0.35, 0.33)), 1.0)
	_mats[trim] = m
	return m
