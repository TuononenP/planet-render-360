class_name MeshArrays
extends RefCounted

## CPU-side surface arrays for meshes built on the world-build thread
## (T7.5). Reading a surface back from the server (surface_get_arrays,
## SurfaceTool.append_from) on a worker thread waits for the main
## thread's next frame flush: thousands of such reads made the threaded
## Paris build several times slower than the same work run serially.
## Meshes that a later merge reads keep their source arrays as meta, and
## mergers read them through surface(); everything else still works,
## just with a read-back.

const META := "src_arrays"

## One-surface ArrayMesh from `arrays`; `keep` stores them for merging.
static func mesh(arrays: Array, keep: bool = true) -> ArrayMesh:
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if keep:
		m.set_meta(META, [arrays])
	return m

## Records `arrays` as the next surface of `m` (multi-surface meshes
## built with add_surface_from_arrays directly).
static func keep_surface(m: ArrayMesh, arrays: Array) -> void:
	var all: Array = m.get_meta(META, [])
	all.append(arrays)
	m.set_meta(META, all)

## Surface `s` of `m`, without a server read-back when its arrays were
## kept. Primitive meshes are read back once and cached on the resource
## (shared unit boxes are merged thousands of times).
static func surface(m: Mesh, s: int) -> Array:
	if m.has_meta(META):
		var all: Array = m.get_meta(META)
		if s < all.size():
			return all[s]
	var arrays := m.surface_get_arrays(s)
	if m is PrimitiveMesh:
		m.set_meta(META, [arrays])
	return arrays

## Appends `src` (one surface's arrays) transformed by `xf` onto `dst`
## (an ARRAY_MAX-sized array; empty slots are null). Vertex, normal,
## tangent, UV, UV2 and colour channels are carried; `dst` is always
## indexed. Each slot is released from `dst` while it grows, so the
## packed array is not copied on write (as MassBatch.add).
static func append(dst: Array, src: Array, xf: Transform3D) -> void:
	var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	if sv.is_empty():
		return
	var base := 0 if dst[Mesh.ARRAY_VERTEX] == null else (dst[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	# A channel only one side carries (wall tangents, roof tint) is
	# padded with its neutral value so the merged arrays stay aligned.
	if base > 0:
		_pad(dst, src, Mesh.ARRAY_TANGENT, base)
		_pad(dst, src, Mesh.ARRAY_COLOR, base)
	src = src.duplicate()
	_pad(src, dst, Mesh.ARRAY_TANGENT, sv.size())
	_pad(src, dst, Mesh.ARRAY_COLOR, sv.size())
	var dv: PackedVector3Array = _take(dst, Mesh.ARRAY_VERTEX, PackedVector3Array())
	dv.append_array(xf * sv)
	dst[Mesh.ARRAY_VERTEX] = dv
	var nb := xf.basis
	if src[Mesh.ARRAY_NORMAL] != null:
		# Unnormalized under scale; the octahedral normal encoding of
		# add_surface_from_arrays normalizes (as SurfaceTool.append_from).
		var dn: PackedVector3Array = _take(dst, Mesh.ARRAY_NORMAL, PackedVector3Array())
		dn.append_array(Transform3D(nb, Vector3.ZERO) * (src[Mesh.ARRAY_NORMAL] as PackedVector3Array))
		dst[Mesh.ARRAY_NORMAL] = dn
	if src[Mesh.ARRAY_TANGENT] != null:
		var dt: PackedFloat32Array = _take(dst, Mesh.ARRAY_TANGENT, PackedFloat32Array())
		var st: PackedFloat32Array = src[Mesh.ARRAY_TANGENT]
		var t0 := dt.size()
		dt.resize(t0 + st.size())
		for i in range(0, st.size(), 4):
			var t := (nb * Vector3(st[i], st[i + 1], st[i + 2])).normalized()
			dt[t0 + i] = t.x
			dt[t0 + i + 1] = t.y
			dt[t0 + i + 2] = t.z
			dt[t0 + i + 3] = st[i + 3]
		dst[Mesh.ARRAY_TANGENT] = dt
	for slot in [Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
		if src[slot] == null:
			continue
		if dst[slot] == null:
			dst[slot] = src[slot].duplicate()
		else:
			var d = _take(dst, slot, null)
			d.append_array(src[slot])
			dst[slot] = d
	var di: PackedInt32Array = _take(dst, Mesh.ARRAY_INDEX, PackedInt32Array())
	var start := di.size()
	if src[Mesh.ARRAY_INDEX] != null:
		var si: PackedInt32Array = src[Mesh.ARRAY_INDEX]
		di.resize(start + si.size())
		for i in si.size():
			di[start + i] = si[i] + base
	else:
		di.resize(start + sv.size())
		for i in sv.size():
			di[start + i] = base + i
	dst[Mesh.ARRAY_INDEX] = di

## Gives `a` a neutral `slot` channel for its `count` vertices when `b`
## has that channel and `a` does not (tangent +U, colour white).
static func _pad(a: Array, b: Array, slot: int, count: int) -> void:
	if a[slot] != null or b[slot] == null:
		return
	if slot == Mesh.ARRAY_COLOR:
		var c := PackedColorArray()
		c.resize(count)
		c.fill(Color.WHITE)
		a[slot] = c
	else:
		var t := PackedFloat32Array()
		t.resize(count * 4)
		for i in count:
			t[i * 4] = 1.0
			t[i * 4 + 3] = 1.0
		a[slot] = t

static func _take(dst: Array, slot: int, empty: Variant) -> Variant:
	var v: Variant = dst[slot]
	dst[slot] = null
	return empty if v == null else v
