extends RefCounted

## Imported, metre-scaled Comrade1280 cars. One mesh and shared materials per kind.
const PAINT_SHADER = preload("res://scripts/generation/car_paint.gdshader")
static var _meshes := {}

static func mesh(kind: String) -> ArrayMesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var packed := load("res://assets/vehicles/%s.glb" % kind) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var source := _find_mesh(root)
	if source == null or not source.mesh is ArrayMesh:
		root.free()
		return null
	var result := (source.mesh as ArrayMesh).duplicate() as ArrayMesh
	for i in result.get_surface_count():
		var original := result.surface_get_material(i)
		var name := original.resource_name.to_lower() if original else ""
		result.surface_set_material(i, _material(name, kind))
	root.free()
	_meshes[kind] = result
	return result

static func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null:
			return found
	return null

static func _material(name: String, kind: String) -> Material:
	if name.begins_with("body"):
		var paint := ShaderMaterial.new()
		paint.shader = PAINT_SHADER
		paint.set_shader_parameter("body_map", load("res://assets/vehicles/%s_body.png" % kind))
		return paint
	var material := StandardMaterial3D.new()
	if name.begins_with("glass"):
		material.albedo_color = Color(0.075, 0.105, 0.13)
		material.roughness = 0.18
	elif name.begins_with("optic"):
		material.albedo_texture = load("res://assets/vehicles/lights.jpg")
		material.roughness = 0.25
	else:
		material.albedo_texture = load("res://assets/vehicles/wheel.jpg")
		material.roughness = 0.6
	return material
