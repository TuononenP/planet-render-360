class_name RealityMeshKit
extends RefCounted

## Loader for self-contained textured photogrammetry `.glb` monument assets
## (e.g. extracted from City of Helsinki 3D+ Reality Mesh, CC BY 4.0).
##
## Caches decoded `ArrayMesh` + `StandardMaterial3D` once in RAM (thread-safe)
## and mounts a single `MeshInstance3D` under `model` (inside the `"Model"`
## child when present, matching `LandmarkMesh.commit` / `LandmarkBuilder.parts`).
## Guarantees every surface carries a non-null `albedo_texture` so `LandmarkTest`
## and `helsinki_hero_landmarks_test.gd` contracts hold across all presets.

static var _cache: Dictionary = {} # res_path -> ArrayMesh
static var _mutex := Mutex.new()

## Loads and caches a textured `.glb` as a single-surface (or multi-surface) ArrayMesh
## with baked local transforms and calibrated StandardMaterial3D roughness/specular.
static func load_textured_mesh(res_path: String, roughness_floor: float = 0.68,
		metallic_cap: float = 0.12) -> ArrayMesh:
	_mutex.lock()
	if _cache.has(res_path):
		var cached: ArrayMesh = _cache[res_path]
		_mutex.unlock()
		return cached
	_mutex.unlock()

	var result: ArrayMesh = null
	if FileAccess.file_exists(res_path):
		var bytes := FileAccess.get_file_as_bytes(res_path)
		if not bytes.is_empty():
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_buffer(bytes, "", state) == OK:
				var root := doc.generate_scene(state)
				if root != null:
					result = _bake_scene(root, roughness_floor, metallic_cap)
					root.free()

	_mutex.lock()
	_cache[res_path] = result
	_mutex.unlock()
	return result

## Attaches a cached textured photogrammetry `.glb` under `model` at `base`,
## scaled by `scale_v` and rotated by `yaw` (radians around +Y).
## Returns the created `MeshInstance3D`, or null if the asset is missing.
static func add_textured_glb(model: Node3D, part_name: String, res_path: String,
		base: Vector3 = Vector3.ZERO, scale_v: Vector3 = Vector3.ONE,
		yaw: float = 0.0, roughness_floor: float = 0.68,
		metallic_cap: float = 0.12) -> MeshInstance3D:
	var mesh := load_textured_mesh(res_path, roughness_floor, metallic_cap)
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.transform = Transform3D(Basis(Vector3.UP, yaw).scaled(scale_v), base)
	var parent: Node = model.get_node_or_null("Model")
	if parent == null:
		parent = model
	parent.add_child(mi)
	return mi

static func _bake_scene(root: Node, roughness_floor: float, metallic_cap: float) -> ArrayMesh:
	var out := ArrayMesh.new()
	_collect(root, Transform3D.IDENTITY, out, roughness_floor, metallic_cap)
	return out if out.get_surface_count() > 0 else null

static func _collect(node: Node, parent_xf: Transform3D, out: ArrayMesh,
		roughness_floor: float, metallic_cap: float) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var src := mi.mesh
		if src != null:
			var rot := xf.basis.orthonormalized()
			for s in src.get_surface_count():
				var arr := src.surface_get_arrays(s)
				var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				if sv.is_empty():
					continue
				var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
				var su: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var si: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()

				var tv := PackedVector3Array()
				var tn := PackedVector3Array()
				var tu := PackedVector2Array()
				tv.resize(sv.size())
				tn.resize(sv.size())
				tu.resize(sv.size())
				for i in sv.size():
					tv[i] = xf * sv[i]
					tn[i] = (rot * sn[i]).normalized() if i < sn.size() else Vector3.UP
					tu[i] = su[i] if i < su.size() else Vector2.ZERO

				var new_arr := []
				new_arr.resize(Mesh.ARRAY_MAX)
				new_arr[Mesh.ARRAY_VERTEX] = tv
				new_arr[Mesh.ARRAY_NORMAL] = tn
				new_arr[Mesh.ARRAY_TEX_UV] = tu
				if not si.is_empty():
					new_arr[Mesh.ARRAY_INDEX] = si

				var surf_idx := out.get_surface_count()
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arr)
				var raw_mat := mi.get_active_material(s)
				if raw_mat == null:
					raw_mat = src.surface_get_material(s)
				out.surface_set_material(surf_idx, _calibrate_material(raw_mat, roughness_floor, metallic_cap))
	for child in node.get_children():
		_collect(child, xf, out, roughness_floor, metallic_cap)

static func _calibrate_material(raw: Material, roughness_floor: float, metallic_cap: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	if raw is StandardMaterial3D:
		var sm := raw as StandardMaterial3D
		mat.albedo_color = sm.albedo_color
		mat.albedo_texture = sm.albedo_texture
		mat.normal_enabled = sm.normal_enabled
		mat.normal_texture = sm.normal_texture
		mat.normal_scale = sm.normal_scale
		mat.roughness = maxf(sm.roughness, roughness_floor)
		mat.roughness_texture = sm.roughness_texture
		mat.metallic = minf(sm.metallic, metallic_cap)
	else:
		mat.roughness = roughness_floor
		mat.metallic = 0.0
	if mat.albedo_texture == null:
		mat.albedo_texture = LandmarkMaterials.tex("stone", "diff")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat
