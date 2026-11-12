class_name ShoreBankMesh
extends RefCounted

## Joined, zero-overlap retaining faces at the real shoreline. Their
## tops are the same constraints used by the adjoining surface patches.
static func build(root: Node3D, model: ShorelineModel, abort: BuildAbort = null, data: LocationData = null) -> void:
	if model.hard_count() == 0:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	# A bridge's abutment (ShoreEvidence._abutments) is concrete, as the
	# bridge's own walls are: in the quay's plain render it read as an
	# untextured grey slab under the deck.
	var abut_verts := PackedVector3Array()
	var abut_normals := PackedVector3Array()
	var abut_indices := PackedInt32Array()
	var seen := {}
	var defenses := SuomenlinnaSite.rings(data.buildings) if data != null else []
	for segment in model.segments:
		if abort != null and abort.requested:
			return
		if str(segment["kind"]) != "hard":
			continue
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		if SuomenlinnaFortress.owns_bank(a, b, defenses):
			continue
		var key := [a, b] if a.x < b.x or (a.x == b.x and a.y < b.y) else [b, a]
		var hash_key := str(key)
		if seen.has(hash_key):
			continue
		seen[hash_key] = true
		var top_a := float(segment["top_a"])
		var top_b := float(segment["top_b"])
		var level_a := float(segment["water_a"])
		var level_b := float(segment["water_b"])
		if maxf(top_a - level_a, top_b - level_b) < 0.1:
			continue
		var land: Vector2 = segment["land"]
		var normal := Vector3(-land.x, 0.0, -land.y)
		var face := PackedVector3Array([Vector3(a.x, level_a - 0.6, a.y), Vector3(b.x, level_b - 0.6, b.y),
			Vector3(b.x, top_b, b.y), Vector3(a.x, top_a, a.y)])
		if _abutment(segment):
			_append_face(abut_verts, abut_normals, abut_indices, face, normal)
		else:
			_append_face(verts, normals, indices, face, normal)
	var caps := transition_caps(model, abort)
	if abort != null and abort.requested:
		return
	for cap in caps:
		var face: PackedVector3Array = cap["face"]
		var normal: Vector3 = cap["normal"]
		var k := verts.size()
		verts.append_array(face)
		for i in 4:
			normals.append(normal)
		if (face[1] - face[0]).cross(face[2] - face[0]).dot(normal) < 0.0:
			indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
		else:
			indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])
	if not abut_indices.is_empty():
		var abut := TerrainBuilder._add(root, _mesh(abut_verts, abut_normals, abut_indices), abutment_material())
		abut.name = "ShoreAbutments"
	if indices.is_empty():
		return
	var node := TerrainBuilder._add(root, _mesh(verts, normals, indices), QuayBuilder.stone_material(data))
	node.name = "ShoreWalls"
	node.set_meta("shore_transitions", caps.size())

static var _abutment_mat: Material = null

## The bridge deck's concrete (RoadBuilder "deck"), mapped in world space:
## the shore walls carry no UVs.
static func abutment_material() -> Material:
	if _abutment_mat == null:
		var m := (RoadBuilder._material("deck") as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE / WorldScale.metres_to_units()
		_abutment_mat = m
	return _abutment_mat

## True for a bank ShoreEvidence made a bridge's abutment.
static func _abutment(segment: Dictionary) -> bool:
	for source in segment.get("sources", []):
		if str(source).begins_with("abutment:"):
			return true
	return false

static func _append_face(verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array,
		face: PackedVector3Array, normal: Vector3) -> void:
	var k := verts.size()
	verts.append_array(face)
	for i in 4:
		normals.append(normal)
	if (face[1] - face[0]).cross(face[2] - face[0]).dot(normal) < 0.0:
		indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

static func _mesh(verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## A quay can end beside a sloping natural bank. Close the height
## discontinuity with masonry returning landward, using the exact two
## adjoining surface edges. This avoids unsupported terrain curtains.
static func transition_caps(model: ShorelineModel, abort: BuildAbort = null) -> Array:
	var hard_edges := {}
	for patch in model.patches.values():
		if abort != null and abort.requested:
			return []
		var triangles: PackedVector3Array = patch["triangles"]
		for i in range(0, triangles.size(), 3):
			if int(patch["owners"][i / 3]) >= 0 or int(patch["hard"][i / 3]) == 0:
				continue
			for edge in 3:
				var a := triangles[i + edge]
				var b := triangles[i + (edge + 1) % 3]
				var key := _edge_key(a, b)
				if hard_edges.has(key):
					hard_edges[key] = null
				else:
					if a.x != key.x or a.z != key.y:
						var swap := a
						a = b
						b = swap
					hard_edges[key] = [a, b, (triangles[i] + triangles[i + 1] + triangles[i + 2]) / 3.0]
	var out: Array = []
	for patch in model.patches.values():
		if abort != null and abort.requested:
			return []
		var triangles: PackedVector3Array = patch["triangles"]
		for i in range(0, triangles.size(), 3):
			if int(patch["owners"][i / 3]) >= 0 or int(patch["hard"][i / 3]) != 0:
				continue
			for edge in 3:
				var a := triangles[i + edge]
				var b := triangles[i + (edge + 1) % 3]
				var key := _edge_key(a, b)
				var hard: Variant = hard_edges.get(key)
				if hard == null:
					continue
				hard_edges[key] = null
				if a.x != key.x or a.z != key.y:
					var swap := a
					a = b
					b = swap
				if maxf(absf(a.y - hard[0].y), absf(b.y - hard[1].y)) < 0.01:
					continue
				var outward: Vector3 = (a + b) * 0.5 - hard[2]
				outward.y = 0.0
				outward = outward.normalized()
				_append_cap(out, hard[0], hard[1], a, b, outward)
	return out

static func _append_cap(out: Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	var da := a.y - c.y
	var db := b.y - d.y
	if da * db < 0.0:
		# Split where the two surfaces cross rather than emitting a bow tie.
		var t := da / (da - db)
		var mid := a.lerp(b, t)
		_append_cap(out, a, mid, c, mid, normal)
		_append_cap(out, mid, b, mid, d, normal)
		return
	if absf(da) + absf(db) < 0.001:
		return
	out.append({"face": PackedVector3Array([a, b, d, c]), "normal": normal if da + db >= 0.0 else -normal})

static func _edge_key(a: Vector3, b: Vector3) -> Vector4:
	return Vector4(a.x, a.z, b.x, b.z) if a.x < b.x or (a.x == b.x and a.z < b.z) else Vector4(b.x, b.z, a.x, a.z)
