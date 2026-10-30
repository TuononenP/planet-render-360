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
			"c": PackedColorArray(), "i": PackedInt32Array()}
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
	var col: PackedColorArray = g["c"]
	var idx: PackedInt32Array = g["i"]
	g["v"] = null
	g["n"] = null
	g["uv"] = null
	g["c"] = null
	g["i"] = null
	var base := v.size()
	v.append_array(verts)
	nr.append_array(normals)
	uv.append_array(uvs)
	# One mass = one building: the same seeded wall / roof tint the real
	# buildings carry, so the distant city is not one uniform material.
	col.resize(v.size())
	var tint := _tint(mat, verts[0] if not verts.is_empty() else Vector3.ZERO)
	for t in range(base, v.size()):
		col[t] = tint
	g["v"] = v
	g["n"] = nr
	g["uv"] = uv
	g["c"] = col
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
	var arr := MeshArrays.surface(mesh, 0)
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
		arrays[Mesh.ARRAY_COLOR] = g["c"]
		arrays[Mesh.ARRAY_TANGENT] = tangents(g["v"], g["n"], g["uv"], g["i"])
		arrays[Mesh.ARRAY_INDEX] = g["i"]
		# Building impostors are merged by LodRing afterwards; keep their
		# arrays (far-city batches are never merged, so they do not).
		var mesh := MeshArrays.mesh(arrays, str(meta.get("lod_layer", "")) == "Buildings")
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

## Wall / roof tint for a mass at `p` (white for other materials).
static func _tint(mat: Material, p: Vector3) -> Color:
	if WallVariety.is_wall(mat):
		return WallVariety.tint_for(p.x, p.z)
	if RoofVariety.is_roof(mat):
		return RoofVariety.tint_for(p.x, p.z)
	return Color.WHITE

## Per-vertex tangents from UV gradients (Godot convention: +u tangent,
## w so the binormal points to −v), so the shared facade and roof normal
## maps light batched masses the way they light real buildings.
static func tangents(v: PackedVector3Array, n: PackedVector3Array,
		uv: PackedVector2Array, idx: PackedInt32Array) -> PackedFloat32Array:
	var tu := PackedVector3Array()
	tu.resize(v.size())
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for t in idx.size() / 3:
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		var e1 := v[i1] - v[i0]
		var e2 := v[i2] - v[i0]
		var d1 := uv[i1] - uv[i0]
		var d2 := uv[i2] - uv[i0]
		var det := d1.x * d2.y - d2.x * d1.y
		if absf(det) < 1e-12:
			continue
		var r := 1.0 / det
		var su := (e1 * d2.y - e2 * d1.y) * r
		var sv := (e2 * d1.x - e1 * d2.x) * r
		for i in [i0, i1, i2]:
			tu[i] += su
			tv[i] += sv
	var out := PackedFloat32Array()
	out.resize(v.size() * 4)
	for i in v.size():
		var nn := n[i]
		var t := tu[i] - nn * nn.dot(tu[i])
		if t.length_squared() < 1e-12:
			t = Vector3(1, 0, 0) if absf(nn.x) < 0.9 else Vector3(0, 0, 1)
			t = (t - nn * nn.dot(t))
		t = t.normalized()
		var w := 1.0 if nn.cross(t).dot(-tv[i]) >= 0.0 else -1.0
		out[i * 4] = t.x
		out[i * 4 + 1] = t.y
		out[i * 4 + 2] = t.z
		out[i * 4 + 3] = w
	return out
