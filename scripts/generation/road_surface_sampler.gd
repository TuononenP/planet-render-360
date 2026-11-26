class_name RoadSurfaceSampler
extends RefCounted

## The rendered ground surface for RoadBuilder: the terrain mesh's own triangle
## under a point (TerrainBuilder._terrain_mesh splits each grid cell a-b-c /
## b-d-c), never below GroundTruth's bilinear surface, so a ribbon lies on what
## is drawn whichever way the cell is split. Aliased as RoadBuilder._Surface.

var ground: GroundTruth
## Building centres (OverheadWires._centre_grid, LIT_BUILT_M cells): a
## way or square among buildings is lit (StreetGlow's pools).
var built: Dictionary = {}
## The same in LIT_MAJOR_M cells, for major roads and squares.
var built_major: Dictionary = {}
var districts: Array = []
## Green polygons of a Finnish place (GroundMaterial._grass_polys), else none.
var parks: Array = []
var size := 0
var step := 1.0
## The preset's terrain mesh (TerrainBuilder._terrain_mesh): coarser
## than the post grid below Ultra, its posts sampled bilinearly. Its
## chords sit above GroundTruth in every hollow, so a ribbon draped
## on the full grid alone vanishes under it in patches.
var mesh_size := 0
var mesh_step := 1.0
## RibbonDraper (native/, tools/build_native.sh) set up on this
## surface by use_native(), else null: _ribbon lays its ribbons.
var native: Object = null
var native_shore := false
## Ends of bridge ways by node, and how many bridge ways end there.
var _bridge_ends := {}
## Non-bridge ways by vertex node ([points, index]): approaches.
var _way_nodes := {}
## Bridge way end points: a joint may sit metres off the node.
var _bridge_end_pts := PackedVector2Array()
var _bridge_lines: Array = []  ## Bridge polylines (beside-joints).
var road_bridges: RoadBridgeDecks.Index = null  ## Road bridge ways sharing structures.
var _pier_lines: Array = []  ## Pier polylines (landings).
var _vessel_rings: Array = []  ## Mapped vessel footprints (gangplanks).
var roof_sites: Array = []  ## Registry landmark roofs (LandmarkRoofs).
## The place and the roads' chain wear seeds (RoadSurface.wear_seeds), so
## a bridge deck is laid and painted like the road it carries.
var place: LocationData = null
var wear_seeds := PackedFloat32Array()
## Roads on the ground (StreetProps._road_grid): no pier stands on one.
var ground_roads := {}
## Pedestrian squares on the ground ([ring, aabb, holes]): paths across
## one are drawn only outside it (RoadBuilder._road).
var squares: Array = []
## Junction aprons ({cell: [rings]}, RoadMarkings' grid): a footway
## (and the plain paving of a crossing's stub) stops at their edge, as
## at a kerb. Laid on into the junction it poked through the apron
## wherever their two drapes disagree.
var aprons: Dictionary = {}
## The same aprons as [ring, bounds]: they are cut out of paved areas.
var apron_rings: Array = []
var skipped_bridges: Dictionary = {}

func in_square(p: Vector2) -> bool:
	for sq: Array in squares:
		if not (sq[1] as Rect2).has_point(p) or not Geometry2D.is_point_in_polygon(p, sq[0]):
			continue
		var in_hole := false
		for hole: Variant in sq[2]:
			if hole is PackedVector2Array and Geometry2D.is_point_in_polygon(p, hole):
				in_hole = true
				break
		if not in_hole:
			return true
	return false

static func _node(p: Vector2) -> Vector2i:
	var m := WorldScale.metres_to_units()
	return Vector2i(roundi(p.x * 100.0 / m), roundi(p.y * 100.0 / m))

## True where two bridge ways meet (BridgeLandings.joint).
func bridge_joint(p: Vector2, outward: Vector2 = Vector2.ZERO) -> bool:
	return BridgeLandings.joint(self, p, outward)

func landmark_roof_y(p: Vector2) -> float:  ## Roof Y covering `p`.
	return LandmarkRoofs.roof_y(roof_sites, p, height)

func _index_way(w: Variant) -> void:
	if not (w is Dictionary):
		return
	var ends: PackedVector2Array = (w as Dictionary).get("points", PackedVector2Array())
	if ends.size() < 2:
		return
	if bool((w as Dictionary).get("bridge", false)):
		_bridge_lines.append(ends)
		for e: Vector2 in [ends[0], ends[ends.size() - 1]]:
			_bridge_ends[_node(e)] = int(_bridge_ends.get(_node(e), 0)) + 1
			_bridge_end_pts.append(e)
	elif not bool((w as Dictionary).get("tunnel", false)) \
			and not bool((w as Dictionary).get("area", false)):
		for vi in ends.size():
			var node := _node(ends[vi])
			if not _way_nodes.has(node):
				_way_nodes[node] = []
			(_way_nodes[node] as Array).append([ends, vi])

func _init(data: LocationData, g: GroundTruth) -> void:
	ground = g
	place = data
	for pier in data.piers:
		if pier is Dictionary:
			_pier_lines.append((pier as Dictionary).get("points", PackedVector2Array()))
	_vessel_rings = ShipBuilder.vessel_rings(data, 3.0 * WorldScale.metres_to_units())
	skipped_bridges = BridgeLandings.orphan_gangplanks(data, ground)
	road_bridges = RoadBridgeDecks.Index.new(data.roads, skipped_bridges)
	road_bridges.structures = BridgeStructures.Plan.new(data.bridge_areas, road_bridges, data.railways)
	roof_sites = LandmarkRoofs.collect(data)
	for ri in data.roads.size():
		if skipped_bridges.has(ri):
			continue
		_index_way(data.roads[ri])
	for rw: Variant in data.railways:
		_index_way(rw)

	var region := CityStyles.region_at(data.latitude, data.longitude)
	districts = CityStyles.local_frame(region, data.latitude, data.longitude).get("districts", [])
	if FinnishGranite.applies(data) or ArchitectureParis.applies(data):
		parks = GroundMaterial._grass_polys(data)
	size = data.grid_size
	step = WorldScale.detailed_extent_units() / float(maxi(size - 1, 1))
	mesh_size = mini(CityDetail.terrain_mesh_posts(data), size)
	if ground.shoreline != null and ground.shoreline.ready:
		mesh_size = size
		step = ground._step_units
	mesh_step = WorldScale.detailed_extent_units() / float(maxi(mesh_size - 1, 1))
	if ground.shoreline != null and ground.shoreline.ready:
		mesh_step = step

func use_native() -> void:
	if ClassDB.class_exists("RibbonDraper"):
		native = ClassDB.instantiate("RibbonDraper")
		native.setup(ground._surface, ground._size, ground._step_units, ground.water_level_m,
			size, step, mesh_size, mesh_step)
		if ground.shoreline != null and ground.shoreline.ready and ground.shoreline.sampler != null \
				and native.has_method("set_shore_sampler"):
			native.set_shore_sampler(ground.shoreline.sampler)
			native_shore = true

func near_shore(points: PackedVector2Array, radius: float) -> bool:
	if ground.shoreline == null or not ground.shoreline.ready:
		return false
	var model: ShorelineModel = ground.shoreline
	for p in points:
		var lo := model.cell_at(p - Vector2.ONE * radius)
		var hi := model.cell_at(p + Vector2.ONE * radius)
		for x in range(lo.x, hi.x + 1):
			for z in range(lo.y, hi.y + 1):
				if model.patches.has(Vector2i(x, z)):
					return true
	return false

## True inside the drawn mesh, EDGE_M clear of its edge.
const EDGE_M := 2.0

func inside(p: Vector2) -> bool:
	var lo := -float(mesh_size) * 0.5 * mesh_step + EDGE_M
	var hi := (float(mesh_size) * 0.5 - 1.0) * mesh_step - EDGE_M
	return p.x >= lo and p.x <= hi and p.y >= lo and p.y <= hi

func height(x: float, z: float) -> float:
	if ground.shoreline != null and ground.shoreline.ready \
			and ground.shoreline.patches.has(ground.shoreline.cell_at(Vector2(x, z))):
		return ground.height_at_world(x, z)
	if mesh_size >= 2 and mesh_size != size:
		return maxf(_mesh_tri(x, z), ground.height_at_world(x, z))
	if size < 2:
		return ground.height_at_world(x, z)
	var fx := clampf(x / step + float(size) * 0.5, 0.0, float(size - 1))
	var fz := clampf(z / step + float(size) * 0.5, 0.0, float(size - 1))
	var x0 := mini(int(fx), size - 2)
	var z0 := mini(int(fz), size - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var ha: float = ground.surface_at_post(x0, z0)
	var hb: float = ground.surface_at_post(x0 + 1, z0)
	var hc: float = ground.surface_at_post(x0, z0 + 1)
	var hd: float = ground.surface_at_post(x0 + 1, z0 + 1)
	var a := lerpf(ha, hb, tx)
	var b := lerpf(hc, hd, tx)
	var bil := lerpf(a, b, tz)
	var tri: float
	if tx + tz <= 1.0:
		tri = ha + (hb - ha) * tx + (hc - ha) * tz
	else:
		tri = hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz)
	return maxf(tri, bil)

## Height of the coarse mesh's own triangle (split a-b-c / b-d-c).
func _mesh_tri(x: float, z: float) -> float:
	var hs := float(mesh_size) * 0.5
	var fx := clampf(x / mesh_step + hs, 0.0, float(mesh_size - 1))
	var fz := clampf(z / mesh_step + hs, 0.0, float(mesh_size - 1))
	var x0 := mini(int(fx), mesh_size - 2)
	var z0 := mini(int(fz), mesh_size - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var px := (float(x0) - hs) * mesh_step
	var pz := (float(z0) - hs) * mesh_step
	var hb := ground.height_at_world(px + mesh_step, pz)
	var hc := ground.height_at_world(px, pz + mesh_step)
	if tx + tz <= 1.0:
		var ha := ground.height_at_world(px, pz)
		return ha + (hb - ha) * tx + (hc - ha) * tz
	var hd := ground.height_at_world(px + mesh_step, pz + mesh_step)
	return hd + (hc - hd) * (1.0 - tx) + (hb - hd) * (1.0 - tz)

func normal(x: float, z: float) -> Vector3:
	var e := step * 0.5
	var dx := height(x + e, z) - height(x - e, z)
	var dz := height(x, z + e) - height(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()

## Breaks the surf -> road_bridges -> structures -> Structure.ground -> surf
## reference cycle once road/bridge generation is done so LocationData and
## GroundTruth (and their textures/indices) are freed between stretches.
func release() -> void:
	if road_bridges != null and road_bridges.structures != null:
		for s: BridgeStructures.Structure in road_bridges.structures.structures:
			s.ground = null
		road_bridges.structures = null
	road_bridges = null
	ground = null
	place = null
	native = null
