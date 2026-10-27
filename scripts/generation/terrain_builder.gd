class_name TerrainBuilder
extends RefCounted

## Builds renderable 3D from a LocationData height grid.

const WORLD_SIZE := 220.0

static func build_world(data: LocationData) -> Node3D:
	var root := Node3D.new()
	root.name = "GeneratedWorld"
	root.add_child(_terrain_mesh(data))
	root.add_child(_water(data))
	if data.buildings.is_empty():
		_buildings(root, data)
	else:
		_real_buildings(root, data)
		_roads(root, data)
	if data.landmark_type != "none":
		root.add_child(_landmark(data))
	_vegetation(root, data)
	return root

static func _mat(color: Color, roughness: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func _terrain_mesh(data: LocationData) -> MeshInstance3D:
	var size := data.grid_size
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var step := WORLD_SIZE / float(size - 1)
	var grass := Color(0.55, 0.62, 0.48)
	var dry := Color(0.76, 0.70, 0.55)
	var rock := Color(0.55, 0.52, 0.47)
	for z in size:
		for x in size:
			var h := data.height_at(x, z)
			var wx := (x - size / 2.0) * step
			var wz := (z - size / 2.0) * step
			verts.append(Vector3(wx, h, wz))
			normals.append(Vector3.UP)
			var t := clampf((h + 10.0) / 45.0, 0.0, 1.0)
			var base_color := grass.lerp(dry, t) if t < 0.7 \
				else dry.lerp(rock, (t - 0.7) / 0.3)
			colors.append(land_color(Vector2(wx, wz), data.land_polygons, base_color))
	for z in size - 1:
		for x in size - 1:
			var a := z * size + x
			var b := a + 1
			var c := a + size
			var d := c + 1
			indices.append_array([a, b, c, b, d, c])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mi.material_override = mat
	return mi

static func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in polygon.size():
		var pi := polygon[i]
		var pj := polygon[j]
		if (pi.y > point.y) != (pj.y > point.y) \
				and point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x:
			inside = not inside
		j = i
	return inside

static func land_color(point: Vector2, land: Array, fallback: Color) -> Color:
	for poly in land:
		if point_in_polygon(point, poly["points"]):
			match str(poly["class"]):
				"water": return Color(0.42, 0.60, 0.66)
				"forest": return Color(0.30, 0.44, 0.30)
				"grass": return Color(0.52, 0.64, 0.42)
				"field": return Color(0.72, 0.66, 0.46)
				"urban": return Color(0.66, 0.63, 0.58)
	return fallback

static func _water(data: LocationData) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
	mi.mesh = plane
	mi.position.y = data.water_level
	mi.material_override = _mat(Color(0.36, 0.55, 0.62, 0.92), 0.25)
	return mi

static func _box(root: Node3D, pos: Vector3, scl: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mi.mesh = box
	mi.position = pos
	mi.scale = scl
	mi.material_override = _mat(color)
	root.add_child(mi)

static func _buildings(root: Node3D, data: LocationData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 7
	var wall := Color(0.84, 0.78, 0.66)
	var roof := Color(0.38, 0.42, 0.48)
	for i in 90:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(38.0, 98.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var gx := int((pos.x / WORLD_SIZE + 0.5) * data.grid_size)
		var gz := int((pos.z / WORLD_SIZE + 0.5) * data.grid_size)
		var ground := data.height_at(gx, gz)
		if ground < data.water_level + 0.5:
			continue
		var h := rng.randf_range(4.0, 9.0)
		pos.y = ground
		_box(root, pos + Vector3(0, h / 2.0, 0),
			Vector3(rng.randf_range(5, 9), h, rng.randf_range(5, 9)), wall)
		_box(root, pos + Vector3(0, h + 0.6, 0),
			Vector3(6.5, 1.2, 6.5), roof)

static func _ground_at(data: LocationData, world_x: float, world_z: float) -> float:
	var gx := int((world_x / WORLD_SIZE + 0.5) * data.grid_size)
	var gz := int((world_z / WORLD_SIZE + 0.5) * data.grid_size)
	return data.height_at(gx, gz)

static func _real_buildings(root: Node3D, data: LocationData) -> void:
	var wall := Color(0.84, 0.78, 0.66)
	var roof := Color(0.38, 0.42, 0.48)
	for b in data.buildings:
		var pos := Vector3(float(b["x"]), 0, float(b["z"]))
		if absf(pos.x) > 105.0 or absf(pos.z) > 105.0:
			continue
		pos.y = _ground_at(data, pos.x, pos.z)
		var h := float(b["height"]) * 0.6
		_box(root, pos + Vector3(0, h / 2.0, 0),
			Vector3(float(b["size_x"]), h, float(b["size_z"])), wall)
		_box(root, pos + Vector3(0, h + 0.4, 0),
			Vector3(float(b["size_x"]) + 0.6, 0.9, float(b["size_z"]) + 0.6), roof)

static func _roads(root: Node3D, data: LocationData) -> void:
	var asphalt := Color(0.32, 0.33, 0.34)
	for line in data.roads:
		var pts: PackedVector2Array = line
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var mid := (a + b) / 2.0
			if absf(mid.x) > 108.0 or absf(mid.y) > 108.0:
				continue
			var seg := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			seg.mesh = box
			var length := a.distance_to(b)
			seg.scale = Vector3(length, 0.18, 2.2)
			seg.position = Vector3(mid.x, _ground_at(data, mid.x, mid.y) + 0.25, mid.y)
			seg.rotation.y = -atan2(b.y - a.y, b.x - a.x)
			seg.material_override = _mat(asphalt)
			root.add_child(seg)

static func _landmark(data: LocationData) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(18, data.height_at(30, 24), -14)
	var iron := Color(0.32, 0.24, 0.18)
	if data.landmark_type == "eiffel":
		# Tapered square frustums read as the tower silhouette at MVP scale.
		var sections: Array = [
			[7.5, 5.2, 11.0, 5.5],   # bottom_r, top_r, height, y
			[5.0, 3.0, 10.0, 16.0],
			[2.8, 1.1, 11.0, 26.0],
		]
		for s in sections:
			var mi := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.radial_segments = 4
			cyl.bottom_radius = s[0]
			cyl.top_radius = s[1]
			cyl.height = s[2]
			mi.mesh = cyl
			mi.rotation.y = PI / 4.0
			mi.position.y = s[3]
			mi.material_override = _mat(iron)
			root.add_child(mi)
		var spire := MeshInstance3D.new()
		var tip := CylinderMesh.new()
		tip.top_radius = 0.15
		tip.bottom_radius = 0.9
		tip.height = 8.0
		spire.mesh = tip
		spire.position.y = 35.0
		spire.material_override = _mat(iron)
		root.add_child(spire)
	else:
		var tower := MeshInstance3D.new()
		var cyl2 := CylinderMesh.new()
		cyl2.top_radius = 2.0
		cyl2.bottom_radius = 3.5
		cyl2.height = 34
		tower.mesh = cyl2
		tower.position.y = 17
		tower.material_override = _mat(Color(0.62, 0.60, 0.56))
		root.add_child(tower)
	return root

static func _vegetation(root: Node3D, data: LocationData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 21
	var leaf := _mat(Color(0.30, 0.42, 0.28))
	for i in 140:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(16.0, 100.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var gx := int((pos.x / WORLD_SIZE + 0.5) * data.grid_size)
		var gz := int((pos.z / WORLD_SIZE + 0.5) * data.grid_size)
		var ground := data.height_at(gx, gz)
		if ground < data.water_level + 0.4:
			continue
		var tree := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.1
		cone.bottom_radius = rng.randf_range(1.2, 2.0)
		cone.height = rng.randf_range(4.0, 7.0)
		tree.mesh = cone
		tree.position = pos + Vector3(0, ground + cone.height / 2.0, 0)
		tree.material_override = leaf
		root.add_child(tree)
