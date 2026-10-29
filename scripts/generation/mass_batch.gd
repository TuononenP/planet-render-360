class_name MassBatch
extends RefCounted

## T7.3 — build-time geometry batching for low-poly city masses: real
## buildings past the preset cap (impostors) and the distant city
## (FarCityBuilder). Triangles are appended straight into one array set
## per (caller key, material) and committed as one MeshInstance3D each,
## so thousands of masses cost a handful of draw calls and no per-mass
## node/mesh churn at build time.

var _groups := {}
## Meta copied onto every committed node (lod_layer etc.).
var meta := {}
var cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON
var triangles := 0

func _group(key: String, mat: Material) -> Dictionary:
	var k := "%s|%d" % [key, mat.get_instance_id() if mat != null else 0]
	if not _groups.has(k):
		_groups[k] = {"key": key, "mat": mat, "v": PackedVector3Array(),
			"n": PackedVector3Array(), "uv": PackedVector2Array(),
			"i": PackedInt32Array()}
	return _groups[k]

## Indexed triangles (indices relative to the passed vertices).
func add(key: String, mat: Material, verts: PackedVector3Array,
		normals: PackedVector3Array, uvs: PackedVector2Array,
		indices: PackedInt32Array) -> void:
	var g := _group(key, mat)
	# Packed arrays are copy-on-write values: take each out of the dict
	# (dropping the dict's reference so appends do not copy the whole
	# array), append, then store it back.
	var v: PackedVector3Array = g["v"]
	var nr: PackedVector3Array = g["n"]
	var uv: PackedVector2Array = g["uv"]
	var idx: PackedInt32Array = g["i"]
	g["v"] = null
	g["n"] = null
	g["uv"] = null
	g["i"] = null
	var base := v.size()
	v.append_array(verts)
	nr.append_array(normals)
	uv.append_array(uvs)
	g["v"] = v
	g["n"] = nr
	g["uv"] = uv
	var start := idx.size()
	idx.resize(start + indices.size())
	for t in indices.size():
		idx[start + t] = indices[t] + base
	g["i"] = idx
	triangles += indices.size() / 3

## Surface 0 of an ArrayMesh (indexed or not), e.g. RoofGeometry forms.
func add_mesh(key: String, mat: Material, mesh: Mesh) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var arr := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] \
		if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	if normals.size() != verts.size():
		normals.resize(verts.size())
		normals.fill(Vector3.UP)
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] \
		if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	if uvs.size() != verts.size():
		uvs.resize(verts.size())
	var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] \
		if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		indices.resize(verts.size())
		for i in verts.size():
			indices[i] = i
	add(key, mat, verts, normals, uvs, indices)

func is_empty() -> bool:
	return _groups.is_empty()

## One MeshInstance3D per (key, material) under root; returns the count.
## extra_meta(key) -> Dictionary adds per-key meta (e.g. ring radius).
func commit(root: Node3D, prefix: String, extra_meta: Callable = Callable()) -> int:
	var n := 0
	for k in _groups:
		var g: Dictionary = _groups[k]
		if (g["i"] as PackedInt32Array).is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = g["v"]
		arrays[Mesh.ARRAY_NORMAL] = g["n"]
		arrays[Mesh.ARRAY_TEX_UV] = g["uv"]
		arrays[Mesh.ARRAY_INDEX] = g["i"]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = "%s_%d" % [prefix, n]
		mi.mesh = mesh
		mi.material_override = g["mat"]
		mi.cast_shadow = cast_shadow
		for m in meta:
			mi.set_meta(m, meta[m])
		if extra_meta.is_valid():
			var em: Dictionary = extra_meta.call(str(g["key"]))
			for m in em:
				mi.set_meta(m, em[m])
		root.add_child(mi)
		n += 1
	_groups.clear()
	return n
