class_name TreePits
extends RefCounted

## Small soil openings for mapped street trees, near the eye on Ultra.
## Grass and park trees keep their ground cover; trees inside buildings,
## water or the carriageway are excluded like VegetationBuilder's trees.
const RADIUS_M := 400.0
const SEARCH_M := 16.0
const HALF_M := 0.8
const MAX_PITS := 500

static func plan(data: LocationData, mask: VegetationMask, m: float, ground: GroundTruth = null) -> Array:
	if not RenderQuality.ultra_desktop(data.quality_preset) \
			or CityStyles.region_at(data.latitude, data.longitude) != "new_york":
		return []
	var centre := View360.spawn_xz(data)
	var roads := StreetFurniture.RoadIndex.new(data, m, (RADIUS_M + SEARCH_M) * m, centre)
	var out: Array = []
	for tree in data.trees:
		if not (tree is Dictionary):
			continue
		var p := Vector2(float(tree.get("x", 0.0)), float(tree.get("z", 0.0)))
		if p.distance_squared_to(centre) > pow(RADIUS_M * m, 2.0) \
				or mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER):
			continue
		# Where VegetationBuilder planted no tree (water, the landmark's
		# keep-out), there is no pit either.
		if ground != null and ground.water_at(p.x, p.y) > 0.0:
			continue
		if data.landmark_type != "none" \
				and p.distance_to(TerrainBuilder.landmark_world_pos(data)) < VegetationBuilder.LANDMARK_CLEAR_M * m:
			continue
		var paved := mask.blocked(p.x, p.y, VegetationMask.ROAD_EDGE)
		if mask.cover_at(p.x, p.y) >= 0 and not paved:
			continue
		var road := roads.nearest(p, SEARCH_M * m)
		if road.is_empty():
			continue
		var kerb_dist := p.distance_to(road["point"]) - float(road["half"])
		if kerb_dist < 0.0 or kerb_dist > 8.0 * m:
			continue
		out.append([p, road["dir"]])
	out.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[0] as Vector2).distance_squared_to(centre) < (b[0] as Vector2).distance_squared_to(centre))
	return out.slice(0, MAX_PITS)

static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask) -> int:
	var m := WorldScale.metres_to_units()
	var pits := plan(data, mask, m, ground)
	if pits.is_empty():
		return 0
	var buf := TreeMeshLibrary.Buf.new()
	for pit in pits:
		var p: Vector2 = pit[0]
		var d: Vector2 = pit[1]
		var n := Vector2(-d.y, d.x)
		var vertices: Array = []
		for off in [d + n, d - n, -d - n, -d + n]:
			var at: Vector2 = p + off * HALF_M * m
			vertices.append(Vector3(at.x, ground.height_at_world(at.x, at.y) + 0.035 * m, at.y))
		TreeMeshLibrary._card(buf, vertices, [Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP], [1.0, 1.0, 1.0, 1.0])
	var arrays := buf.arrays()
	arrays[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(arrays[Mesh.ARRAY_INDEX])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "TreePits"
	mi.mesh = mesh
	mi.material_override = MaterialLibrary.pbr_material("forest", Color(0.55, 0.51, 0.43), 1.6)
	root.add_child(mi)
	return pits.size()
