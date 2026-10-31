class_name LegacyBoxBuilder
extends RefCounted

## The box-mesh fallback for buildings whose footprint cannot be extruded
## even as its AABB rectangle (corrupt geometry, v1 dicts without a
## footprint): a facade box, a roof form or v1 mansard, and the v1
## dormer/chimney dressing. Split out of BuildingBuilder unchanged.

static func _box_mat(root: Node3D, pos: Vector3, scl: Vector3, mat: Material) -> void:
	var mi := TerrainBuilder._add(root, TerrainBuilder._box_mesh(), mat)
	mi.position = pos
	mi.scale = scl

static func _box(root: Node3D, pos: Vector3, scl: Vector3, color: Color) -> void:
	_box_mat(root, pos, scl, TerrainBuilder._mat(color))

static func _mansard(root: Node3D, cx: float, base_y: float, cz: float,
		size_x: float, size_z: float, roof_h: float, seed_v: float,
		mat: Material = null) -> void:
	var mi := TerrainBuilder._add(root, TerrainBuilder._cyl(0.52, 1.0, 1.0, 4),
		mat if mat != null else MaterialLibrary.slate())
	mi.rotation.y = PI / 4.0
	mi.position = Vector3(cx, base_y + roof_h / 2.0, cz)
	mi.scale = Vector3(size_x * 0.48, roof_h, size_z * 0.48)

static func building(root: Node3D, pos: Vector3, size_x: float, size_z: float,
		height_world: float, seed_v: float, data: LocationData = null,
		roof_shape: String = "", roof_h_world: float = -1.0,
		b: Dictionary = {}) -> void:
	# T4.3: wall/roof resolve from OSM tags → satellite sample →
	# regional defaults, with one window row per real storey; blocks
	# past the fidelity radius share the ≤6 distant materials.
	# Box-mesh fallback (corrupt footprints, AABB-only v1 dicts): box UVs
	# cannot tile, so it keeps the legacy one-texture-per-wall materials.
	var region := BuildingBuilder._legacy_region(data)
	var fidelity := MaterialLibrary.fidelity_for_preset(
		data.quality_preset) if data != null else 2
	var m2u := WorldScale.metres_to_units()
	var distant := data != null and pos.length() / m2u \
		> MaterialLibrary.full_detail_radius_m(fidelity)
	var floor_h := float((BuildingWalls.LEGACY_BOX[region] as Dictionary)["floor_h"])
	var storeys := int(b.get("levels", 0))
	if storeys <= 0:
		storeys = maxi(1, roundi(height_world / m2u / floor_h))
	var facade := FacadeMaterials.facade_for_building(b, region, storeys,
		fidelity, distant, seed_v)
	_box_mat(root, pos + Vector3(0, height_world / 2.0, 0),
		Vector3(size_x, height_world, size_z), facade)
	# T4.2: the v1 "everything gets a mansard" default is gone — an
	# untagged roof takes the regional default (mansard only where the
	# tag or the Haussmann region says so). height_world is the WALL
	# height; the roof rises above it by roof_h_world (explicit from
	# real-data callers, v1-auto when negative).
	var shape := BuildingBuilder._effective_shape(roof_shape,
		str((BuildingWalls.LEGACY_BOX[region] as Dictionary)["default_roof"]), false)
	var hint := Color(0, 0, 0, 0)
	if data != null:
		hint = MaterialLibrary.sampled_roof_color(data, pos.x, pos.z,
			size_x, size_z, Callable(TerrainBuilder, "satellite_uv"))
	var roof_mat := FacadeMaterials.roof_for_building(b, region, shape,
		hint, fidelity, distant, seed_v)
	var rh := roof_h_world
	if rh < 0.0:
		if shape == "flat":
			rh = 0.0
		elif shape == "mansard":
			rh = clampf(minf(size_x, size_z) * 0.22, 2.8, 8.0)
		else:
			var span_m := minf(size_x, size_z) / WorldScale.metres_to_units()
			rh = BuildingBuilder._roof_height_m(shape, span_m, 0.0) * WorldScale.metres_to_units()
	if shape == "flat":
		_box_mat(root, pos + Vector3(0, height_world + 0.72, 0),
			Vector3(size_x * 1.02, 1.44, size_z * 1.02), roof_mat)
		return
	if shape == "mansard":
		_mansard(root, pos.x, pos.y + height_world, pos.z, size_x, size_z, rh, seed_v, roof_mat)
	else:
		var hx := size_x * 0.5
		var hz := size_z * 0.5
		var rect := PackedVector2Array([Vector2(pos.x - hx, pos.z - hz),
			Vector2(pos.x + hx, pos.z - hz), Vector2(pos.x + hx, pos.z + hz),
			Vector2(pos.x - hx, pos.z + hz)])
		BuildingBuilder._roof_form(root, rect, pos.y + height_world, rh, shape, roof_mat)
	# Dormers + chimneys break the roofline (PRD §4.2); near blocks only.
	# (metres since the T7.0 cutover; v1 unit values x4)
	if pos.length() < BuildingDetail.NEAR_RADIUS and height_world > 12.8:
		var n_d := clampi(int(size_x / 6.4), 1, 4)
		for di in n_d:
			var dx := (float(di) - float(n_d - 1) / 2.0) * 6.0
			_box_mat(root, pos + Vector3(dx, height_world + rh * 0.52, size_z * 0.30),
				Vector3(1.68, 2.08, 1.2), roof_mat)
		_box_mat(root, pos + Vector3(size_x * 0.28, height_world + rh + 0.88, 0),
			Vector3(1.36, 2.2, 1.36), MaterialLibrary.pbr_material("brick"))
