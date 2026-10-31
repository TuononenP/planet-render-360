class_name BuildingWalls
extends RefCounted

## Wall and roof-cap geometry for BuildingBuilder: ring cleaning,
## textured wall extrusion and roof caps. Batch state stays on
## BuildingBuilder (_batch/_batch_key) so FarCityBuilder is unchanged.
static func _clean_ring(raw: PackedVector2Array) -> PackedVector2Array:
	var ring := PackedVector2Array(raw)
	while ring.size() > 1 \
			and ring[0].distance_to(ring[ring.size() - 1]) < 0.01:
		ring.remove_at(ring.size() - 1)
	if ring.size() < 3:
		return PackedVector2Array()
	if absf(RingGeometry.signed_area(ring)) < 0.01:
		return PackedVector2Array()
	return ring

## Vertical wall quads, one per ring edge. Outward normals come from
## the winding (exact for simple rings however concave — a centroid
## test can flip inside deep notches); `invert` flips them for a
## courtyard ring, whose walls face into the hole. Triangle order is
## picked per edge so the Godot front face (clockwise viewed from
## outside) lands on the outward normal. Wall UVs match BoxMesh (v = 1 at
## the base), so the facade grime stays at the ground and cornices stay
## upright. `cover` (PartyWalls.ring_cover, one partition per edge) splits
## an edge at its neighbours: wall below a neighbour's top is skipped,
## wall above a lower neighbour goes to `fire` (a blank firewall), and
## only exposed stretches carry the windowed facade.
static func _walls(root: Node3D, ring: PackedVector2Array, base: float,
		top: float, mat: Material, v_repeat: float = 1.0, cover: Array = [],
		fire: Material = null, invert: bool = false) -> void:
	var ccw := RingGeometry.signed_area(ring) > 0.0
	# Style facades map UVs in real window bays (and, for tiled patterns,
	# real storeys) so windows keep their size on any wall; legacy
	# materials stretch 0..1 over the edge.
	var uvp := FacadeMaterials.facade_uv(mat)
	var m2u := WorldScale.metres_to_units()
	var face := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	var blank := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	for i in ring.size():
		var ea := ring[i]
		var eb := ring[(i + 1) % ring.size()]
		if (eb - ea).length() < 0.001:
			continue
		var n := Vector2((eb - ea).y, -(eb - ea).x).normalized() if ccw \
			else Vector2(-(eb - ea).y, (eb - ea).x).normalized()
		if invert:
			n = -n
		var pieces: Array = cover[i] if i < cover.size() else [[0.0, 1.0, PartyWalls.OPEN]]
		for pc in pieces:
			var a := ea.lerp(eb, float(pc[0]))
			var b := ea.lerp(eb, float(pc[1]))
			var nb_top := float(pc[2])
			if is_inf(nb_top):
				var u1 := 1.0
				var v0 := 1.0
				if uvp.x > 0.0:
					var len_m := (b - a).length() / m2u
					# An edge under half a bay shows only the blank margin left
					# of the first window (a pillar must not become a zebra).
					u1 = 0.03 if len_m < uvp.x * 0.5 else maxf(1.0, roundf(len_m / uvp.x)) / uvp.y
					if uvp.z > 0.0:
						v0 = v_repeat
				_quad(face, a, b, base, top, n, Vector2(u1, v0))
			elif nb_top < top - 0.3 * m2u:
				var y0 := maxf(base, nb_top)
				var arr := blank if fire != null else face
				_quad(arr, a, b, y0, top, n, Vector2((b - a).length() / m2u / 4.0,
					(top - y0) / m2u / 4.0))
	_emit(root, face, mat)
	if fire != null:
		_emit(root, blank, fire)

## One wall quad a→b from y0 to y1 facing n into `arr` [verts, normals,
## uvs, tangents, indices]; `uv` is the far corner (u at b, v at the base).
static func _quad(arr: Array, a: Vector2, b: Vector2, y0: float, y1: float,
		n: Vector2, uv: Vector2) -> void:
	var verts: PackedVector3Array = arr[0]
	var normals: PackedVector3Array = arr[1]
	var uvs: PackedVector2Array = arr[2]
	var tangents: PackedFloat32Array = arr[3]
	var indices: PackedInt32Array = arr[4]
	var e := b - a
	var n3 := Vector3(n.x, 0.0, n.y)
	var k := verts.size()
	verts.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y),
		Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)])
	# Tangent along +u (a → b); w makes cross(N, T) · w point up, the
	# −v direction (v = 0 at the top), as Godot's own generate_tangents
	# writes it — the facade normal maps and window parallax need it.
	var t3 := Vector3(e.x, 0.0, e.y).normalized()
	var w := 1.0 if n3.cross(t3).y > 0.0 else -1.0
	for j in 4:
		normals.append(n3)
		tangents.append_array([t3.x, t3.y, t3.z, w])
	uvs.append_array([Vector2(0, uv.y), Vector2(uv.x, uv.y),
		Vector2(uv.x, 0), Vector2(0, 0)])
	# Forward order faces (e.y, -e.x): with s < 0 that is the
	# outward normal already, else the reversed order is emitted.
	var s := e.x * n.y - e.y * n.x
	if s > 0.0:
		indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])
	else:
		indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])

static func _emit(root: Node3D, arr: Array, mat: Material) -> void:
	if (arr[4] as PackedInt32Array).is_empty():
		return
	if BuildingBuilder._batch != null:
		BuildingBuilder._batch.add(BuildingBuilder._batch_key, mat, arr[0], arr[1], arr[2], arr[4])
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = arr[0]
	arrays[Mesh.ARRAY_NORMAL] = arr[1]
	arrays[Mesh.ARRAY_TEX_UV] = arr[2]
	arrays[Mesh.ARRAY_TANGENT] = arr[3]
	arrays[Mesh.ARRAY_INDEX] = arr[4]
	# Arrays kept: LodRing merges these on the build thread (T7.5).
	TerrainBuilder._add(root, MeshArrays.mesh(arrays), mat)

## Flat roof cap over the triangulated ring: the whole roof for flat
## shapes, the eave-level seal under pitched T4.2 forms (it closes the
## gaps concave rings leave in apex fans). Triplets flip when the
## emitted triangle faces down, so the front face points up — the same
## convention as the terrain mesh.
## `cap` is the ring `idx` indexes when it is not `ring` (a courtyard
## block's keyhole ring, RingGeometry.bridge_holes); party edges get no
## cornice or parapet (the neighbour's wall continues there).
static func _roof_cap(root: Node3D, ring: PackedVector2Array,
		idx: PackedInt32Array, top: float, mat: Material, trim: int = 0,
		cap: PackedVector2Array = PackedVector2Array(),
		party: PackedByteArray = PackedByteArray()) -> void:
	# Cornice / parapet relief at the wall top (BuildingTrim, near only);
	# a parapet sinks the deck behind it.
	BuildingTrim.add(root, ring, top, trim, party)
	top = BuildingTrim.deck(top, trim)
	if not cap.is_empty():
		ring = cap
	# triangulate_polygon normalizes its output winding (a CW input
	# still yields CCW triplets), so the flip is read off the first
	# emitted triangle, not the ring: front.y equals its 2D cross.
	var flip := false
	if idx.size() >= 3:
		var p0 := ring[idx[0]]
		var p1 := ring[idx[1]]
		var p2 := ring[idx[2]]
		flip = (p1.x - p0.x) * (p2.y - p0.y) \
			- (p1.y - p0.y) * (p2.x - p0.x) < 0.0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for p in ring:
		verts.append(Vector3(p.x, top, p.y))
		normals.append(Vector3.UP)
		uvs.append(p * 0.05)
	var indices := PackedInt32Array()
	for t in idx.size() / 3:
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		if flip:
			indices.append_array([i0, i2, i1])
		else:
			indices.append_array([i0, i1, i2])
	if BuildingBuilder._batch != null:
		BuildingBuilder._batch.add(BuildingBuilder._batch_key, mat, verts, normals, uvs, indices)
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	# +X tangent: the cap's normal map lights correctly (+v runs to +Z).
	var tangents := PackedFloat32Array()
	for i in verts.size():
		tangents.append_array([1.0, 0.0, 0.0, 1.0])
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_INDEX] = indices
	# Arrays kept: LodRing merges these on the build thread (T7.5).
	TerrainBuilder._add(root, MeshArrays.mesh(arrays), mat)

## Floor height / default roof for the legacy box-mesh fallback only
## (corrupt footprints, AABB-only v1 dicts): box UVs cannot tile, so that
## path keeps the original Paris-vs-everywhere-else defaults. Every other
## building takes its numbers from ArchitectureStyle (T4.2 heights and
## roofs, now by region and kind).
const LEGACY_BOX = {
	"haussmann": {"floor_h": 3.1, "default_roof": "mansard"},
	"urban": {"floor_h": 3.0, "default_roof": "flat"},
}

static func _rect_ring(c: Vector2, size: Vector2, yaw: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		ring.append(c + (corner * size * 0.5).rotated(yaw))
	return ring


static func _aabb_footprint(b: Dictionary) -> Dictionary:
	var out := b.duplicate()
	out.erase("parts")
	out["footprint"] = _rect_ring(Vector2(float(b["x"]), float(b["z"])),
		Vector2(float(b["size_x"]), float(b["size_z"])), 0.0)
	return out

## True-footprint masses for one §2.4 building: its building:part
## sub-polygons when present (OSM parts tile the parent outline, each
## with its own height, so the parent shell is skipped — extruding
## both would double coplanar walls), else the parent footprint alone.
## Returns true when at least one mass extruded; false routes to the
## logged AABB fallback in _real_buildings.
