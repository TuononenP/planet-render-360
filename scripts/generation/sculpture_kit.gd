class_name SculptureKit
extends RefCounted

## High-resolution figurative sculpture loader & organic loft helpers on LandmarkMesh.
## Loads normalized public-domain / CC0 museum scan .glb meshes from `assets/statues/`
## via `GLTFDocument`, caches their raw vertex/normal/UV/index arrays once in RAM,
## and merges transformed geometry straight into `LandmarkMesh` under the caller's
## exact material key (preserving single-draw-call batching, `LandmarkMaterials`
## bronze/marble PBR, and Desktop Ultra `LandmarkShader` weathering).

const STATUE_DIR := "res://assets/statues/"

static var _mesh_cache: Dictionary = {} # name -> Dictionary { "v", "n", "uv", "idx" }
static var _mutex := Mutex.new()

## Loads and caches the triangle arrays for `res://assets/statues/<asset_name>.glb`.
static func _load_glb(asset_name: String) -> Dictionary:
	_mutex.lock()
	if _mesh_cache.has(asset_name):
		var cached: Dictionary = _mesh_cache[asset_name]
		_mutex.unlock()
		return cached
	_mutex.unlock()

	var path := STATUE_DIR + asset_name + ".glb"
	var out := {}
	if FileAccess.file_exists(path):
		var bytes := FileAccess.get_file_as_bytes(path)
		if not bytes.is_empty():
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_buffer(bytes, "", state) == OK:
				var root := doc.generate_scene(state)
				if root != null:
					var verts := PackedVector3Array()
					var norms := PackedVector3Array()
					var uvs := PackedVector2Array()
					var indices := PackedInt32Array()
					_collect_meshes(root, Transform3D.IDENTITY, verts, norms, uvs, indices)
					root.free()
					if not verts.is_empty():
						out = {"v": verts, "n": norms, "uv": uvs, "idx": indices}

	_mutex.lock()
	_mesh_cache[asset_name] = out
	_mutex.unlock()
	return out

static func _collect_meshes(node: Node, parent_xf: Transform3D, verts: PackedVector3Array,
		norms: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			var rot := xf.basis.orthonormalized()
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				if sv.is_empty():
					continue
				var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
				var su: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var si: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				var base_v := verts.size()
				for i in sv.size():
					verts.append(xf * sv[i])
					norms.append((rot * sn[i]).normalized() if i < sn.size() else Vector3.UP)
					uvs.append(su[i] if i < su.size() else Vector2.ZERO)
				if not si.is_empty():
					for k in si.size():
						indices.append(base_v + si[k])
				else:
					for k in sv.size():
						indices.append(base_v + k)
	for child in node.get_children():
		_collect_meshes(child, xf, verts, norms, uvs, indices)

## Stamps a cached statue .glb directly into LandmarkMesh surface `key`.
static func _stamp_glb(lm: LandmarkMesh, key: String, asset_name: String, base: Vector3,
		scale_v: Vector3, yaw: float = 0.0, pitch: float = 0.0) -> bool:
	var data := _load_glb(asset_name)
	if data.is_empty():
		return false
	var sv: PackedVector3Array = data["v"]
	var sn: PackedVector3Array = data["n"]
	var su: PackedVector2Array = data["uv"]
	var si: PackedInt32Array = data["idx"]
	if si.size() < 3:
		return false
	var rot := Basis(Vector3.UP, yaw)
	if absf(pitch) > 0.001:
		rot = rot * Basis(Vector3.RIGHT, pitch)
	var uv_scale := (scale_v.x + scale_v.y + scale_v.z) / 3.0
	var s: LandmarkMesh.Surf = lm._surfs[key]
	var tri_n := si.size() / 3
	for t in tri_n:
		var i0 := si[t * 3]
		var i1 := si[t * 3 + 1]
		var i2 := si[t * 3 + 2]
		var v0 := base + rot * (sv[i0] * scale_v)
		var v1 := base + rot * (sv[i1] * scale_v)
		var v2 := base + rot * (sv[i2] * scale_v)
		var n0 := rot * sn[i0]
		var n1 := rot * sn[i1]
		var n2 := rot * sn[i2]
		# glTF front faces are CCW; LandmarkMesh / Godot ArrayMesh front faces are CW
		if (v2 - v0).cross(v1 - v0).dot(n0 + n1 + n2) < 0.0:
			s.v.append_array([v0, v2, v1])
			s.n.append_array([n0, n2, n1])
			s.uv.append_array([su[i0] * uv_scale, su[i2] * uv_scale, su[i1] * uv_scale])
		else:
			s.v.append_array([v0, v1, v2])
			s.n.append_array([n0, n1, n2])
			s.uv.append_array([su[i0] * uv_scale, su[i1] * uv_scale, su[i2] * uv_scale])
	return true

## Public helper to stamp any cached `.glb` from `assets/statues/` into LandmarkMesh.
static func stamp_asset(lm: LandmarkMesh, key: String, asset_name: String, base: Vector3,
		scale_v: Vector3, yaw: float = 0.0, pitch: float = 0.0) -> bool:
	return _stamp_glb(lm, key, asset_name, base, scale_v, yaw, pitch)

## Classical / Baroque standing statue (draped Zenobia or heroic trident-bearing Neptune).
static func classical_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		arm_up: bool = false, yaw: float = 0.0) -> void:
	if h <= 0.15:
		return
	var asset := "classical_hero" if arm_up else "classical_draped"
	_stamp_glb(lm, key, asset, base, Vector3(h, h, h), yaw)

## Standing contrapposto nude sculpture (Ville Vallgren's Havis Amanda).
static func contrapposto_nude(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0) -> void:
	if h <= 0.15:
		return
	# Tuck thin plinth base slightly into the sculpted bronze shell capital so feet meet the waves
	_stamp_glb(lm, key, "contrapposto_nude", base - Vector3(0.0, h * 0.04, 0.0),
		Vector3(h * 1.04, h * 1.04, h * 1.04), yaw)

## Winged Neo-Classical angel sculpture (Emma Stebbins' Bethesda Angel of the Waters).
static func winged_angel(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0) -> void:
	if h <= 0.15:
		return
	_stamp_glb(lm, key, "winged_angel", base, Vector3(h, h, h), yaw)

## Baroque Triton blowing a conch horn (`blowing_conch = true`) or bearded River God
## with water urn (`blowing_conch = false`).
static func triton_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0, blowing_conch: bool = true) -> void:
	if h <= 0.15:
		return
	var asset := "triton_conch" if blowing_conch else "river_god"
	_stamp_glb(lm, key, asset, base, Vector3(h, h, h), yaw)

## Art Nouveau spouting bronze sea lion gripping a rim plinth. Returns 3D mouth spout point.
static func sea_lion(lm: LandmarkMesh, key: String, base: Vector3, length: float,
		yaw: float = 0.0) -> Vector3:
	var rot := Basis(Vector3.UP, yaw)
	_stamp_glb(lm, key, "sea_lion", base - Vector3(0.0, 0.04 * length, 0.0), Vector3(length, length, length), yaw)
	return base + rot * Vector3(0.0, 0.66 * length, 0.24 * length)

## Sculpted rearing / surging Baroque horse (Poly Haven CC0 Horse Statue 01, height-normalized).
static func rearing_horse(lm: LandmarkMesh, key: String, base: Vector3, scale_m: float = 1.0,
		yaw: float = 0.0, rear_pitch: float = 0.0) -> void:
	var h := scale_m * 2.45
	_stamp_glb(lm, key, "rearing_horse", base, Vector3(h, h, h), yaw, -rear_pitch * 0.25)

## Monumental couchant lion (Trafalgar Square Landseer lions, Piazza del Popolo, Navona; height-normalized).
static func couchant_lion(lm: LandmarkMesh, key: String, base: Vector3, length: float,
		yaw: float = 0.0) -> Vector3:
	var rot := Basis(Vector3.UP, yaw)
	var h := length * 0.54
	_stamp_glb(lm, key, "couchant_lion", base, Vector3(h, h, h), yaw)
	return base + rot * Vector3(0.0, 0.62 * h, 0.36 * h)

# --- Shared organic loft helpers (used by scalloped shell capitals & bronze fish) ---

## Emits a closed periodic surface from cross-section `rows` around per-ring `centers`.
static func emit_rings(lm: LandmarkMesh, key: String, centers: PackedVector3Array,
		rows: Array) -> void:
	var nv := rows.size()
	if nv < 2 or centers.size() != nv:
		return
	var nu := (rows[0] as PackedVector3Array).size()
	if nu < 3:
		return
	var segs := nu - 1
	var closed_u := (rows[0] as PackedVector3Array)[0].distance_to((rows[0] as PackedVector3Array)[segs]) < 0.004 \
		and (rows[nv / 2] as PackedVector3Array)[0].distance_to((rows[nv / 2] as PackedVector3Array)[segs]) < 0.004
	var norms: Array = []
	var axis_end0 := (centers[0] - centers[mini(1, nv - 1)]).normalized()
	var axis_end1 := (centers[nv - 1] - centers[maxi(nv - 2, 0)]).normalized()
	for j in nv:
		var row: PackedVector3Array = rows[j]
		var c := centers[j]
		var nr := PackedVector3Array()
		for i in nu:
			var idx := (i % segs) if (closed_u and i == segs) else i
			var ip := ((idx - 1 + segs) % segs) if closed_u else maxi(idx - 1, 0)
			var inx := ((idx + 1) % segs) if closed_u else mini(idx + 1, nu - 1)
			var du := row[inx] - row[ip]
			var dv := (rows[mini(j + 1, nv - 1)] as PackedVector3Array)[idx] \
				- (rows[maxi(j - 1, 0)] as PackedVector3Array)[idx]
			var rad := row[idx] - c
			var is_pole := (j == 0 or j == nv - 1) and rad.length_squared() < 1e-4
			var n: Vector3
			if is_pole:
				n = axis_end0 if j == 0 else axis_end1
			else:
				n = du.cross(dv)
				if n.length_squared() < 1e-10:
					n = rad.normalized() if rad.length_squared() > 1e-8 else (axis_end0 if j == 0 else axis_end1)
				else:
					n = n.normalized()
					var hint := rad if rad.length_squared() > 1e-8 else (axis_end0 if j == 0 else axis_end1)
					if hint.length_squared() > 1e-10 and n.dot(hint) < 0.0:
						n = -n
			nr.append(n if n.length_squared() > 0.1 else Vector3.UP)
		norms.append(nr)

	var vacc := PackedFloat32Array()
	vacc.resize(nu)
	for j in nv - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		var n0: PackedVector3Array = norms[j]
		var n1: PackedVector3Array = norms[j + 1]
		var u0 := 0.0
		for i in segs:
			var step_u := maxf(r0[i].distance_to(r0[i + 1]), r1[i].distance_to(r1[i + 1]))
			var u1 := u0 + step_u
			var va := vacc[i]
			var vb := vacc[i + 1]
			var vc := vb + r0[i + 1].distance_to(r1[i + 1])
			var vd := va + r0[i].distance_to(r1[i])
			if r0[i].distance_squared_to(r0[i + 1]) > 1e-10:
				lm.tri(key, r0[i], r0[i + 1], r1[i + 1], n0[i], n0[i + 1], n1[i + 1],
					Vector2(u0, va), Vector2(u1, vb), Vector2(u1, vc))
			if r1[i].distance_squared_to(r1[i + 1]) > 1e-10:
				lm.tri(key, r0[i], r1[i + 1], r1[i], n0[i], n1[i + 1], n1[i],
					Vector2(u0, va), Vector2(u1, vc), Vector2(u0, vd))
			u0 = u1
		for i in nu:
			vacc[i] += r0[i].distance_to(r1[i])

## Lofts a smooth organic tube along `spine` with parallel-transport frames and rounded dome caps.
static func loft_tube(lm: LandmarkMesh, key: String, spine: PackedVector3Array,
		radii: PackedVector2Array, segs: int = 16, cap_ends: bool = true) -> void:
	var n := spine.size()
	if n < 2 or radii.size() != n:
		return
	var tangents := PackedVector3Array()
	var sides := PackedVector3Array()
	var fwds := PackedVector3Array()
	for j in n:
		var t_dir: Vector3
		if j == 0:
			t_dir = spine[1] - spine[0]
		elif j == n - 1:
			t_dir = spine[n - 1] - spine[n - 2]
		else:
			t_dir = spine[j + 1] - spine[j - 1]
		t_dir = t_dir.normalized() if t_dir.length_squared() > 1e-8 else Vector3.UP
		tangents.append(t_dir)
		var side: Vector3
		if j == 0:
			var ref := Vector3.FORWARD if absf(t_dir.x) > 0.9 else Vector3.RIGHT
			side = (ref - t_dir * ref.dot(t_dir)).normalized()
		else:
			var q := Quaternion(tangents[j - 1], t_dir)
			side = (q * sides[j - 1])
			side = (side - t_dir * side.dot(t_dir)).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		sides.append(side)
		fwds.append(side.cross(t_dir).normalized())

	var centers := PackedVector3Array()
	var rows: Array = []
	var make_ring := func(c: Vector3, sd: Vector3, fd: Vector3, rx: float, rz: float) -> PackedVector3Array:
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs) if i < segs else 0.0
			row.append(c + sd * (cos(a) * rx) + fd * (sin(a) * rz))
		return row

	if cap_ends and (radii[0].x > 0.003 or radii[0].y > 0.003):
		var d0 := minf(minf(radii[0].x, radii[0].y) * 0.65, spine[0].distance_to(spine[1]) * 0.45)
		var c_apex := spine[0] - tangents[0] * d0
		centers.append(c_apex)
		rows.append(make_ring.call(c_apex, sides[0], fwds[0], 0.0004, 0.0004))
		var c_mid := spine[0] - tangents[0] * (d0 * 0.55)
		centers.append(c_mid)
		rows.append(make_ring.call(c_mid, sides[0], fwds[0], radii[0].x * 0.68, radii[0].y * 0.68))

	for j in n:
		var rx := maxf(radii[j].x, 0.0008)
		var rz := maxf(radii[j].y, 0.0008)
		centers.append(spine[j])
		rows.append(make_ring.call(spine[j], sides[j], fwds[j], rx, rz))

	if cap_ends and (radii[n - 1].x > 0.003 or radii[n - 1].y > 0.003):
		var d1 := minf(minf(radii[n - 1].x, radii[n - 1].y) * 0.65, spine[n - 1].distance_to(spine[n - 2]) * 0.45)
		var c_mid := spine[n - 1] + tangents[n - 1] * (d1 * 0.55)
		centers.append(c_mid)
		rows.append(make_ring.call(c_mid, sides[n - 1], fwds[n - 1], radii[n - 1].x * 0.68, radii[n - 1].y * 0.68))
		var c_apex := spine[n - 1] + tangents[n - 1] * d1
		centers.append(c_apex)
		rows.append(make_ring.call(c_apex, sides[n - 1], fwds[n - 1], 0.0004, 0.0004))

	emit_rings(lm, key, centers, rows)
