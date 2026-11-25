class_name DroneObstacles
extends RefCounted

## 3D obstacle & surface collision for ViewDrone: the drone is modelled as a
## sphere of RADIUS_M (0.5 m, larger than the 0.25 m camera near-plane corner
## reach so no wall, roof, terrain slope, statue or vehicle ever clips into
## the view frustum). Sweeps sub-step at MAX_SUBSTEP_M so even 3x boosted
## flight (83 m/s) cannot tunnel through thin barriers, poles, cars or walls.
## Geometric kernels live in DroneCollisionMath.

const RADIUS_M := 0.5
const MAX_SUBSTEP_M := 0.25
const SLOPE_PROBE_M := 0.38
const DEPEN_ITERS := 3

const SKIP_LAYERS := ["FarTerrain", "FarCity", "GroundCover", "GrassCarpet"]
const WATER_SOLID_NAMES := ["Quays", "ShoreWalls", "ShoreAbutments", "StockholmQuay",
	"StockholmLocks", "BangkokWaterfront", "VeniceWaterfront", "AmsterdamWaterfront"]

var _data: LocationData
var _ground: GroundTruth
var _world_id := 0
var _world_children := -1
var _bldg_count := -1
var _stat_sig := ""

var _prism_cells: Dictionary = {}  # Vector2i -> PackedInt32Array
var _prisms: Array = []            # Dictionary {ring, holes, rect, y_lo, y_hi}
var _obb_cells: Dictionary = {}    # Vector2i -> PackedInt32Array
var _obbs: Array = []              # Dictionary {c, ax, ay, az, ext, min_xz, max_xz, y_lo, y_hi}
var _mesh_cells: Dictionary = {}   # Vector2i -> PackedInt32Array
var _meshes: Array = []            # Dictionary {mesh, xf, inv_xf, aabb}
var _mesh_grids: Dictionary = {}   # mesh instance_id -> Dictionary {verts, cells}
var _route_drivers: Array = []     # Array[RouteBoatDriver]
var _air_drivers: Array = []       # Array[AircraftDriver]
var _mover_nodes: Dictionary = {}  # Node instance_id -> true

func invalidate() -> void:
	_data = null
	_ground = null
	_world_id = 0
	_world_children = -1
	_bldg_count = -1
	_stat_sig = ""
	_prism_cells.clear()
	_prisms.clear()
	_obb_cells.clear()
	_obbs.clear()
	_mesh_cells.clear()
	_meshes.clear()
	_mesh_grids.clear()
	_route_drivers.clear()
	_air_drivers.clear()
	_mover_nodes.clear()

## Continuous ground / water / authored-island surface Y at world XZ `p`.
static func surface_y(data: LocationData, ground: GroundTruth, p: Vector2) -> float:
	if ground == null:
		return 0.0
	var gy := LandmarkTerrain.ground_y(data, ground, p) if data != null \
		else ground.height_at_world(p.x, p.y)
	var wy := ground.height_at_world(p.x, p.y) + ground.water_at(p.x, p.y)
	var y := maxf(gy, wy)
	if data != null and LandmarkTerrain.has_sea(data) \
			and (ground.shoreline == null or ground.shoreline.empty()):
		y = maxf(y, ground.render_y(0.0))
	return y

## Lowest camera centre Y over terrain/water at `p`, sampling a small cross
## around `p` so the camera near plane stays clear of steep slopes and quays.
static func terrain_floor_y(data: LocationData, ground: GroundTruth, p: Vector2) -> float:
	if ground == null:
		return RADIUS_M
	var s := surface_y(data, ground, p)
	for o in [Vector2(SLOPE_PROBE_M, 0.0), Vector2(-SLOPE_PROBE_M, 0.0),
			Vector2(0.0, SLOPE_PROBE_M), Vector2(0.0, -SLOPE_PROBE_M)]:
		var q: Vector2 = p + o
		if ground.is_inside(q.x, q.y):
			s = maxf(s, surface_y(data, ground, q))
	return s + RADIUS_M

## Lowest Y the drone may descend to over `xz` among `buildings` and `ground`
## when descending from above: terrain floor outside footprints (and inside
## open courtyards), roof + RADIUS_M directly over any building footprint.
static func floor_among(buildings: Array, ground: GroundTruth, xz: Vector2,
		data: LocationData = null) -> float:
	var low := terrain_floor_y(data, ground, xz)
	if ground == null:
		return low
	for b in buildings:
		if not (b is Dictionary):
			continue
		var d := b as Dictionary
		var fp := DroneCollisionMath.footprint_of(d)
		if fp.size() < 3 or View360._ring_distance(xz, fp) > RADIUS_M:
			continue
		if DroneCollisionMath.in_courtyard(xz, d.get("holes", []), RADIUS_M):
			continue
		low = maxf(low, DroneCollisionMath.building_top_y(d, ground) + RADIUS_M)
	return low

## Supporting surface Y (without RADIUS_M added) directly under `p_xz` at or
## below `current_y`: terrain/water or the highest solid top beneath the drone.
func support_y(v: View360, p_xz: Vector2, current_y: float) -> float:
	_ensure_for_view(v)
	var base := terrain_floor_y(_data, _ground, p_xz) - RADIUS_M
	var tol := current_y - RADIUS_M + 0.25
	for idx in DroneCollisionMath.cell_lookup(_prism_cells, p_xz, RADIUS_M):
		var pr: Dictionary = _prisms[idx]
		var y_hi := float(pr["y_hi"])
		if y_hi <= tol and y_hi > base and (pr["rect"] as Rect2).has_point(p_xz):
			if View360._ring_distance(p_xz, pr["ring"]) <= RADIUS_M \
					and not DroneCollisionMath.in_courtyard(p_xz, pr["holes"], RADIUS_M):
				base = y_hi
	for idx in DroneCollisionMath.cell_lookup(_obb_cells, p_xz, RADIUS_M):
		var ob: Dictionary = _obbs[idx]
		var y_hi := float(ob["y_hi"])
		if y_hi <= tol and y_hi > base and DroneCollisionMath.obb_overlaps_xz(ob, p_xz, RADIUS_M):
			base = maxf(base, y_hi)
	for idx in DroneCollisionMath.cell_lookup(_mesh_cells, p_xz, RADIUS_M):
		var md: Dictionary = _meshes[idx]
		var wb: AABB = md["aabb"]
		if wb.position.y > tol or wb.end.y <= base:
			continue
		if p_xz.x < wb.position.x - RADIUS_M or p_xz.x > wb.end.x + RADIUS_M \
				or p_xz.y < wb.position.z - RADIUS_M or p_xz.y > wb.end.z + RADIUS_M:
			continue
		var mtop := DroneCollisionMath.mesh_support_at(_mesh_grids, md, p_xz, tol, RADIUS_M)
		if mtop > base:
			base = mtop
	for ob: Dictionary in _dynamic_obbs(v, p_xz, RADIUS_M + 4.0):
		var y_hi := float(ob["y_hi"])
		if y_hi <= tol and y_hi > base and DroneCollisionMath.obb_overlaps_xz(ob, p_xz, RADIUS_M):
			base = maxf(base, y_hi)
	return base

## Sweeps the drone sphere from `from` to `to` against terrain, water, static
## solids, scene meshes and live moving vehicles.
func sweep(from: Vector3, to: Vector3, v: View360) -> Dictionary:
	_ensure_for_view(v)
	var mid := Vector2((from.x + to.x) * 0.5, (from.z + to.z) * 0.5)
	var reach := Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z)) * 0.5 + RADIUS_M + 4.0
	return _sweep_internal(from, to, _dynamic_obbs(v, mid, reach))

## Standalone obstacle index from `data`, `ground` and optional `world` Node3D.
static func from_data(data: LocationData, ground: GroundTruth, world: Node3D = null) -> DroneObstacles:
	var obs := DroneObstacles.new()
	obs._rebuild(data, ground, world, null)
	return obs

func sweep_standalone(from: Vector3, to: Vector3, extra_obbs: Array = []) -> Dictionary:
	return _sweep_internal(from, to, extra_obbs)

func _sweep_internal(from: Vector3, to: Vector3, dyn_obbs: Array) -> Dictionary:
	var delta := to - from
	var steps := maxi(1, ceili(delta.length() / MAX_SUBSTEP_M))
	var start_fix := _depenetrate(from, dyn_obbs)
	var cur: Vector3 = start_fix["pos"]
	var hit_floor := bool(start_fix["hit_floor"])
	var hit_ceil := bool(start_fix["hit_ceil"])
	var hit_wall := bool(start_fix["hit_wall"])
	var wall_normal: Vector2 = start_fix["normal_xz"]

	var step_vec := delta / float(steps)
	for _s in steps:
		var res := _depenetrate(cur + step_vec, dyn_obbs)
		cur = res["pos"]
		if bool(res["hit_floor"]):
			hit_floor = true
		if bool(res["hit_ceil"]):
			hit_ceil = true
		if bool(res["hit_wall"]):
			hit_wall = true
			wall_normal += res["normal_xz"] as Vector2
	if wall_normal.length_squared() > 1e-6:
		wall_normal = wall_normal.normalized()
	return {
		"pos": cur,
		"hit_floor": hit_floor,
		"hit_ceil": hit_ceil,
		"hit_wall": hit_wall,
		"normal_xz": wall_normal,
	}

func _depenetrate(p: Vector3, dyn_obbs: Array) -> Dictionary:
	var cur := p
	var hit_floor := false
	var hit_ceil := false
	var hit_wall := false
	var n_xz := Vector2.ZERO
	var r2 := RADIUS_M * RADIUS_M

	for _iter in DEPEN_ITERS:
		var moved := false
		var tf := terrain_floor_y(_data, _ground, Vector2(cur.x, cur.z))
		if cur.y < tf:
			cur.y = tf
			hit_floor = true
			moved = true

		for idx in DroneCollisionMath.cell_lookup(_prism_cells, Vector2(cur.x, cur.z), RADIUS_M):
			var pr: Dictionary = _prisms[idx]
			if cur.y < float(pr["y_lo"]) - RADIUS_M or cur.y > float(pr["y_hi"]) + RADIUS_M:
				continue
			if not (pr["rect"] as Rect2).has_point(Vector2(cur.x, cur.z)):
				continue
			var push := DroneCollisionMath.push_from_prism(cur, pr, RADIUS_M, r2)
			if push != Vector3.ZERO:
				cur += push
				moved = true
				var hlen := Vector2(push.x, push.z).length()
				if push.y > 0.001 and absf(push.y) >= hlen:
					hit_floor = true
				elif push.y < -0.001 and absf(push.y) >= hlen:
					hit_ceil = true
				else:
					hit_wall = true
					n_xz += Vector2(push.x, push.z).normalized()

		for idx in DroneCollisionMath.cell_lookup(_obb_cells, Vector2(cur.x, cur.z), RADIUS_M):
			var push := DroneCollisionMath.push_from_obb(cur, _obbs[idx], RADIUS_M, r2)
			if push != Vector3.ZERO:
				cur += push
				moved = true
				var hlen := Vector2(push.x, push.z).length()
				if push.y > 0.001 and absf(push.y) >= hlen:
					hit_floor = true
				elif push.y < -0.001 and absf(push.y) >= hlen:
					hit_ceil = true
				else:
					hit_wall = true
					n_xz += Vector2(push.x, push.z).normalized()

		for ob: Dictionary in dyn_obbs:
			var push := DroneCollisionMath.push_from_obb(cur, ob, RADIUS_M, r2)
			if push != Vector3.ZERO:
				cur += push
				moved = true
				var hlen := Vector2(push.x, push.z).length()
				if push.y > 0.001 and absf(push.y) >= hlen:
					hit_floor = true
				elif push.y < -0.001 and absf(push.y) >= hlen:
					hit_ceil = true
				else:
					hit_wall = true
					n_xz += Vector2(push.x, push.z).normalized()

		for idx in DroneCollisionMath.cell_lookup(_mesh_cells, Vector2(cur.x, cur.z), RADIUS_M):
			var md: Dictionary = _meshes[idx]
			var wb: AABB = md["aabb"]
			if cur.x < wb.position.x - RADIUS_M or cur.x > wb.end.x + RADIUS_M \
					or cur.y < wb.position.y - RADIUS_M or cur.y > wb.end.y + RADIUS_M \
					or cur.z < wb.position.z - RADIUS_M or cur.z > wb.end.z + RADIUS_M:
				continue
			var push := DroneCollisionMath.push_from_mesh(_mesh_grids, cur, md, RADIUS_M, r2)
			if push != Vector3.ZERO:
				cur += push
				moved = true
				var hlen := Vector2(push.x, push.z).length()
				if push.y > 0.001 and absf(push.y) >= hlen:
					hit_floor = true
				elif push.y < -0.001 and absf(push.y) >= hlen:
					hit_ceil = true
				else:
					hit_wall = true
					n_xz += Vector2(push.x, push.z).normalized()

		var tf_end := terrain_floor_y(_data, _ground, Vector2(cur.x, cur.z))
		if cur.y < tf_end:
			cur.y = tf_end
			hit_floor = true
			moved = true
		if not moved:
			break

	if n_xz.length_squared() > 1e-6:
		n_xz = n_xz.normalized()
	return {
		"pos": cur,
		"hit_floor": hit_floor,
		"hit_ceil": hit_ceil,
		"hit_wall": hit_wall,
		"normal_xz": n_xz,
	}

# --- Index construction ---------------------------------------------------

func _ensure_for_view(v: View360) -> void:
	if v == null or v._data == null or v._ground == null:
		return
	var world := v._generated if is_instance_valid(v._generated) else null
	var wid := world.get_instance_id() if world != null else 0
	var wch := world.get_child_count() if world != null else -1
	var bc := v._data.buildings.size()
	var sig := "%d/%d/%d/%d/%d/%s/%d" % [bc, v._data.trees.size(), v._data.street_furniture.size(),
		v._data.barriers.size(), v._data.roads.size(), v._data.landmark_type,
		1 if v._mover != null else 0]
	if _data == v._data and _ground == v._ground and _world_id == wid \
			and _world_children == wch and _bldg_count == bc and _stat_sig == sig:
		return
	_rebuild(v._data, v._ground, world, v._mover)
	_stat_sig = sig

func _rebuild(data: LocationData, ground: GroundTruth, world: Node3D, mover: VehicleMover) -> void:
	var new_wid := world.get_instance_id() if world != null else 0
	if new_wid != _world_id:
		_mesh_grids.clear()
	_prism_cells.clear()
	_prisms.clear()
	_obb_cells.clear()
	_obbs.clear()
	_mesh_cells.clear()
	_meshes.clear()
	_route_drivers.clear()
	_air_drivers.clear()
	_mover_nodes.clear()
	_data = data
	_ground = ground
	_world_id = new_wid
	_world_children = world.get_child_count() if world != null else -1
	_bldg_count = data.buildings.size() if data != null else -1
	if data == null or ground == null:
		return

	if mover != null:
		for t: Dictionary in mover._trains:
			for row in t.get("nodes", []):
				for n in row:
					if n is Node:
						_mover_nodes[(n as Node).get_instance_id()] = true

	_gather_data_buildings(data, ground, world != null)
	_gather_data_props(data, ground, world)
	if world != null:
		_gather_world_nodes(world, Transform3D.IDENTITY, "")
	else:
		_gather_landmark_fallbacks(data, ground)

func _gather_data_buildings(data: LocationData, ground: GroundTruth, has_world: bool) -> void:
	var site := TerrainBuilder.landmark_site_xz(data) if data.landmark_type != "none" else Vector2.INF
	var edge := WorldScale.detailed_extent_units() * 0.5 * 0.98
	var m := WorldScale.metres_to_units()
	for raw in data.buildings:
		if not (raw is Dictionary):
			continue
		var b := raw as Dictionary
		if has_world and b.has("x") and b.has("z"):
			if (data.landmark_type != "none" or not data.landmark_candidates.is_empty()) \
					and not BuildingBuilder._accepted(data, b, site, edge):
				continue
			if BuildingBuilder._in_open_water(ground, b):
				continue
		if StatueBuilder.accepts(b):
			var sf := StatueBuilder.frame(b)
			var c: Vector2 = sf["centre"]
			var l := float(sf["length"]) + 0.42 * m
			var w := float(sf["width"]) + 0.42 * m
			var rider := str(b.get("statue", "")) == "equestrian"
			var s := clampf(float(sf["length"]) * StatueBuilder.HORSE_FILL / (StatueBuilder.HORSE_LEN_M * m), 0.6, 2.0) * m
			var fig_h := 4.2 * s if rider else clampf(float(sf["width"]) * 1.3, 1.8 * m, 6.0 * m)
			var ph := clampf(float(sf["width"]) * StatueBuilder.PEDESTAL_K,
				StatueBuilder.PEDESTAL_MIN_M * m, StatueBuilder.PEDESTAL_MAX_M * m)
			if str(b.get("height_source", "")) == "tag_height":
				ph = maxf(float(b.get("height", 0.0)) * m - fig_h, StatueBuilder.PEDESTAL_MIN_M * m)
			var gy := ground.height_at_world(c.x, c.y)
			_add_box_xz(c, sf["heading"], l, w, gy - 0.5, gy + ph + fig_h)
			continue
		if ShipBuilder.accepts(b):
			var vf := ShipBuilder.frame(b)
			var vc: Vector2 = vf["centre"]
			var vlen := float(vf["length"])
			var wy := surface_y(data, ground, vc)
			_add_box_xz(vc, vf["axis"], vlen, float(vf["beam"]), wy - 1.5, wy + ShipBuilder.height(b, vlen))
			continue
		var fp := DroneCollisionMath.footprint_of(b)
		if fp.size() < 3:
			continue
		var holes: Array = b.get("holes", [])
		var gy_range := DroneCollisionMath.ring_ground_range(fp, b, ground)
		var h := DroneCollisionMath.building_height_m(b, 3.0)
		var roof_extra := DroneCollisionMath.roof_allowance(b)
		var min_m := maxf(float(b.get("min_height_m", 0.0)), float(int(b.get("min_level", 0))) * 3.2)
		var y_lo := gy_range.x - 1.5
		var y_hi := gy_range.y + h + roof_extra
		if str(b.get("kind", "")) in ["roof", "carport"] and min_m <= 0.0:
			y_lo = gy_range.x + maxf(h - 1.2, 2.4)
		elif min_m > 0.0:
			y_lo = gy_range.x + min_m
			y_hi = maxf(y_hi, y_lo + 1.0)
		_add_prism(fp, holes, y_lo, y_hi)
		for part_v in b.get("parts", []):
			if not (part_v is Dictionary):
				continue
			var part := part_v as Dictionary
			var ph := DroneCollisionMath.building_height_m(part, 0.0)
			if ph <= 0.0:
				continue
			var pfp: PackedVector2Array = part.get("footprint", PackedVector2Array())
			var use_fp := pfp if pfp.size() >= 3 else fp
			var p_gy := DroneCollisionMath.ring_ground_range(use_fp, part if pfp.size() >= 3 else b, ground)
			var p_min := maxf(float(part.get("min_height_m", 0.0)), float(int(part.get("min_level", 0))) * 3.2)
			var py_lo := p_gy.x + p_min if p_min > 0.0 else p_gy.x - 1.0
			var py_hi := maxf(p_gy.y + ph + DroneCollisionMath.roof_allowance(part), py_lo + 1.0)
			_add_prism(use_fp, [] if pfp.size() >= 3 else holes, py_lo, py_hi)

	if data.has_meta(&"infill_prisms"):
		for ip: Dictionary in data.get_meta(&"infill_prisms"):
			_add_prism(ip["ring"], [], float(ip["y_lo"]), float(ip["y_hi"]))

func _gather_data_props(data: LocationData, ground: GroundTruth, world: Node3D) -> void:
	for br in data.barriers:
		if not (br is Dictionary):
			continue
		var pts: PackedVector2Array = br.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var row: Array = StreetProps.BARRIERS.get(str(br.get("class", "")), [])
		var height := float(br.get("height_m", NAN))
		if is_nan(height):
			height = float(row[1]) if not row.is_empty() else 1.2
		if height < 0.25:
			continue
		var thick := maxf(float(row[2]) if not row.is_empty() else 0.3, 0.25)
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg_len := a.distance_to(b)
			if seg_len < 0.05:
				continue
			var g_lo := minf(ground.height_at_world(a.x, a.y), ground.height_at_world(b.x, b.y))
			var g_hi := maxf(ground.height_at_world(a.x, a.y), ground.height_at_world(b.x, b.y))
			_add_box_xz((a + b) * 0.5, b - a, seg_len + thick, thick, g_lo - 0.4, g_hi + height)

	var headless := DisplayServer.get_name() == "headless"
	if world == null or world.find_child(TreeLod.SET_NAME, true, false) == null:
		for t in data.trees:
			if t is Dictionary:
				var tx := float(t.get("x", 0.0))
				var tz := float(t.get("z", 0.0))
				var ty := ground.height_at_world(tx, tz)
				var th := maxf(float(t.get("height", 8.5)), 3.0)
				_add_box_xz(Vector2(tx, tz), Vector2.RIGHT, 0.7, 0.7, ty - 0.3, ty + th * 0.45)
				_add_box_xz(Vector2(tx, tz), Vector2.RIGHT, 3.2, 3.2, ty + th * 0.42, ty + th)

	if headless or world == null or world.find_child("StreetFurniture", true, false) == null:
		for f in data.street_furniture:
			if f is Dictionary:
				var fx := float(f.get("x", 0.0))
				var fz := float(f.get("z", 0.0))
				var fy := ground.height_at_world(fx, fz)
				var fkind := str(f.get("kind", "bench"))
				var fh := 2.6 if bool(f.get("shelter", false)) else (5.2 if fkind == "signals" else 1.2)
				var fw := 2.2 if bool(f.get("shelter", false)) else 0.9
				_add_box_xz(Vector2(fx, fz), Vector2.RIGHT, fw, fw, fy - 0.2, fy + fh)

	if (headless or world == null or world.find_child("ParkedCars", true, false) == null) \
			and RenderQuality.ultra_desktop(data.quality_preset) and not data.roads.is_empty():
		for car in ParkedCars.plan(data, ground, WorldScale.metres_to_units()):
			var pos: Vector3 = car[0]
			var basis: Basis = car[1]
			var kind := str(car[2])
			var spec := CarSpecs.spec(kind) if CarSpecs.has(kind) else CarSpecs.BASE
			var ch := float(spec.get("h", 1.5)) * basis.y.length()
			var cl := CarSpecs.length_m(kind) * basis.x.length()
			var cw := CarSpecs.width_m(kind) * basis.z.length()
			_add_obb_from_aabb(Transform3D(basis.orthonormalized(), pos),
				AABB(Vector3(-cl * 0.5, 0.0, -cw * 0.5), Vector3(cl, ch, cw)))

func _gather_landmark_fallbacks(data: LocationData, ground: GroundTruth) -> void:
	for solid: Dictionary in ViewWalk._landmark_solids(data):
		var fp: PackedVector2Array = solid.get("footprint", PackedVector2Array())
		if fp.size() >= 3:
			var gy := DroneCollisionMath.ring_ground_range(fp, solid, ground)
			var kind := str(solid.get("kind", ""))
			var h := 18.0 if kind == "gate" else (6.5 if kind == "wall" else 8.0)
			_add_prism(fp, [], gy.x - 1.0, gy.y + h)
	if data.landmark_type == "gwanghwamun":
		var pos := WorldScale.xz_from_latlon(data.landmark_lat, data.landmark_lon, data.latitude, data.longitude)
		var entry := LocationData.entry_for_type("gwanghwamun")
		var lintel := ViewWalk._moved(ViewWalk.rect_solid(Vector2.ZERO, Vector2.RIGHT,
			LandmarkGwanghwamun.BASE.x, LandmarkGwanghwamun.BASE.z, "lintel"), pos, float(entry.get("yaw_deg", 0.0)))
		var gy := ground.height_at_world(pos.x, pos.y)
		_add_prism(lintel["footprint"], [], gy + 5.8, gy + 18.5)

func _gather_world_nodes(node: Node, parent_xf: Transform3D, inherited_layer: String) -> void:
	if node is RouteBoatDriver:
		_route_drivers.append(node)
		return
	if node is AircraftDriver:
		_air_drivers.append(node)
		return
	if not (node is Node3D):
		return
	var n3 := node as Node3D
	var nm := String(n3.name)
	if nm == "AirTraffic":
		for c in n3.get_children():
			if c is AircraftDriver:
				_air_drivers.append(c)
		return
	var layer := str(n3.get_meta("lod_layer", inherited_layer if inherited_layer != "" else nm))
	if layer in SKIP_LAYERS or nm in ["FarTerrain", "Terrain", "Trams",
			"RoadDecals", "TreePits", "Kerbs", "StreetGlowMap", "LandmarkLights",
			"BeaconHalos", "ShopLights", "StreetLights", "VehicleLights"]:
		return
	if bool(n3.get_meta("lod_impostor", false)) and bool(n3.get_meta("impostor_only", false)):
		return
	if n3.has_meta("boat_id") or n3.has_meta("flight_id") or _mover_nodes.has(n3.get_instance_id()):
		return
	if nm.begins_with("OverheadWires_") or nm.begins_with("UtilityCables_") \
			or nm.ends_with("Shadows") or nm.ends_with("_shadow") or nm.ends_with("_glass") \
			or nm in ["RotorDisc", "VesselWake", "VesselCollar", "Sparkle", "Icicles", "Impostor"]:
		return

	var xf := parent_xf * n3.transform
	if layer == "Water" and nm == "Water":
		for c in n3.get_children():
			if String(c.name) in WATER_SOLID_NAMES:
				_gather_world_nodes(c, xf, "WaterSolid")
		return

	if n3 is MultiMeshInstance3D:
		_gather_multimesh(n3 as MultiMeshInstance3D, xf)
	elif n3 is MeshInstance3D:
		_gather_mesh_instance(n3 as MeshInstance3D, xf, layer)

	for c in n3.get_children():
		_gather_world_nodes(c, xf, layer)

func _gather_multimesh(mmi: MultiMeshInstance3D, xf: Transform3D) -> void:
	if mmi.visibility_range_begin > 0.0 \
			or mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
			or bool(mmi.get_meta("impostor_skip", false)):
		return
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null or mm.instance_count <= 0:
		return
	var nm := String(mmi.name)
	if nm.ends_with("_far"):
		return
	var lb := mm.mesh.get_aabb()
	if lb.size.y < 0.15:
		return
	if nm.begins_with("VegTrees_"):
		if DisplayServer.get_name() == "headless":
			var origins: PackedVector3Array = mmi.get_meta("origins", PackedVector3Array())
			var th := maxf(lb.size.y, 3.0)
			var cw := maxf(maxf(lb.size.x, lb.size.z) * 0.52, 2.2)
			for o in origins:
				var wp := xf * o
				_add_box_xz(Vector2(wp.x, wp.z), Vector2.RIGHT, 0.7, 0.7, wp.y - 0.3, wp.y + th * 0.45)
				_add_box_xz(Vector2(wp.x, wp.z), Vector2.RIGHT, cw, cw, wp.y + th * 0.42, wp.y + th * 0.92)
		else:
			var tcount := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			var trunk := AABB(
				Vector3(-lb.size.x * 0.09, lb.position.y, -lb.size.z * 0.09),
				Vector3(lb.size.x * 0.18, lb.size.y * 0.45, lb.size.z * 0.18))
			var crown := AABB(
				Vector3(-lb.size.x * 0.28, lb.position.y + lb.size.y * 0.42, -lb.size.z * 0.28),
				Vector3(lb.size.x * 0.56, lb.size.y * 0.50, lb.size.z * 0.56))
			for i in mini(tcount, mm.instance_count):
				var ixf := xf * mm.get_instance_transform(i)
				_add_obb_from_aabb(ixf, trunk)
				_add_obb_from_aabb(ixf, crown)
		return
	if DisplayServer.get_name() == "headless":
		return
	var count := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
	for i in mini(count, mm.instance_count):
		_add_obb_from_aabb(xf * mm.get_instance_transform(i), lb)

func _gather_mesh_instance(mi: MeshInstance3D, xf: Transform3D, layer: String) -> void:
	if mi.mesh == null or mi.visibility_range_begin > 0.0 \
			or mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
			or bool(mi.get_meta("lod_impostor", false)) \
			or bool(mi.get_meta("impostor_skip", false)):
		return
	var nm := String(mi.name)
	if nm.ends_with("_far"):
		return
	if layer == "Buildings" and (nm.begins_with("LodCell_") or bool(mi.get_meta("lod_detail", false))):
		return
	if layer == "Roads" and mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
			and not nm.begins_with("Stair"):
		return
	var lb := mi.mesh.get_aabb()
	if lb.size.y < 0.12:
		return
	if mi.mesh is BoxMesh:
		_add_obb_from_aabb(xf, lb)
		return
	var wb := xf * lb
	var edge := WorldScale.detailed_extent_units() * 0.5 + 100.0
	if wb.end.x < -edge or wb.position.x > edge or wb.end.z < -edge or wb.position.z > edge:
		return
	var midx := _meshes.size()
	_meshes.append({"mesh": mi.mesh, "xf": xf, "inv_xf": xf.affine_inverse(), "aabb": wb})
	DroneCollisionMath.insert_rect(_mesh_cells,
		Rect2(Vector2(wb.position.x, wb.position.z), Vector2(wb.size.x, wb.size.z)), midx)

# --- Dynamic moving vehicles (queried live each frame) --------------------

func _dynamic_obbs(v: View360, near_xz: Vector2, radius: float) -> Array:
	var out: Array = []
	if v == null:
		return out
	if v._mover != null:
		for t: Dictionary in v._mover._trains:
			if bool(t.get("hidden", false)):
				continue
			var rows: Array = t.get("nodes", [])
			if not rows.is_empty():
				for row in rows:
					var mi := (row as Array)[0] as MeshInstance3D
					if mi != null and is_instance_valid(mi) and mi.mesh != null:
						var o := mi.global_position
						if Vector2(o.x, o.z).distance_to(near_xz) <= radius + 30.0:
							var ob := DroneCollisionMath.make_obb(mi.global_transform, mi.mesh.get_aabb())
							if not ob.is_empty():
								out.append(ob)
			elif t.has("route"):
				var route: TramRoute = t["route"]
				var s := float(t.get("s", 0.0))
				var mid := route.xz_at(s)
				if mid.distance_to(near_xz) <= radius + float(t.get("length", 30.0)):
					var dir := route.xz_at(minf(s + 2.0, route.length_m)) - route.xz_at(maxf(s - 2.0, 0.0))
					var gy := surface_y(_data, _ground, mid)
					var ob := DroneCollisionMath.make_box_xz(mid, dir, float(t.get("length", 30.0)), 2.8, gy, gy + 3.8)
					if not ob.is_empty():
						out.append(ob)

	for drv in _route_drivers:
		if not is_instance_valid(drv):
			continue
		var rd := drv as RouteBoatDriver
		if rd._cum.is_empty() and not rd.boats.is_empty():
			rd._bind()
		for b: Dictionary in rd.boats:
			var pos := rd.position_of(int(b["id"]))
			var blen := float(b.get("length", 28.0))
			if pos == Vector2.INF or pos.distance_to(near_xz) > radius + blen:
				continue
			var yaw := float(b.get("yaw", rd._heading(b)))
			var wy := float(b.get("y", surface_y(_data, _ground, pos)))
			var ob := DroneCollisionMath.make_box_xz(pos, Vector2(cos(yaw), -sin(yaw)),
				blen, maxf(blen * 0.24, 5.5), wy - 1.0, wy + maxf(blen * 0.34, 7.5))
			if not ob.is_empty():
				out.append(ob)

	for drv in _air_drivers:
		if not is_instance_valid(drv):
			continue
		var ad := drv as AircraftDriver
		if not ad._bound and not ad.flights.is_empty():
			ad._bind()
		for f: Dictionary in ad.flights:
			if not bool(f.get("visible", true)):
				continue
			var pos: Vector3 = f.get("pos", Vector3.ZERO)
			var kind := str(f.get("kind", "narrow"))
			var span := AircraftSpecs.span_m(kind)
			var length := AircraftSpecs.length_m(kind)
			if Vector2(pos.x, pos.z).distance_to(near_xz) > radius + maxf(span, length):
				continue
			var yaw := float(f.get("yaw", 0.0))
			var fwd := Vector2(cos(yaw), sin(yaw))
			var fh := 4.2 if kind == "helicopter" else clampf(length * 0.28, 3.2, 17.5)
			var fw := 3.2 if kind == "helicopter" else clampf(length * 0.11, 1.8, 6.5)
			var fuse := DroneCollisionMath.make_box_xz(Vector2(pos.x, pos.z), fwd, length, fw, pos.y - 0.5, pos.y + fh)
			if not fuse.is_empty():
				out.append(fuse)
			var wing_h := fh if kind == "helicopter" else clampf(fh * 0.42, 2.2, 6.5)
			var wing := DroneCollisionMath.make_box_xz(Vector2(pos.x, pos.z), fwd,
				span if kind == "helicopter" else maxf(length * 0.22, 2.4), span,
				pos.y + (fh * 0.55 if kind == "helicopter" else 0.8), pos.y + wing_h)
			if not wing.is_empty():
				out.append(wing)
	return out

func _add_prism(ring: PackedVector2Array, holes: Array, y_lo: float, y_hi: float) -> void:
	if ring.size() < 3 or y_hi <= y_lo:
		return
	var r := Rect2(ring[0], Vector2.ZERO)
	for p in ring:
		r = r.expand(p)
	var idx := _prisms.size()
	_prisms.append({"ring": ring, "holes": holes, "rect": r.grow(RADIUS_M + 0.05), "y_lo": y_lo, "y_hi": y_hi})
	DroneCollisionMath.insert_rect(_prism_cells, r, idx)

func _add_box_xz(centre: Vector2, forward: Vector2, length: float, width: float, y_lo: float, y_hi: float) -> void:
	var ob := DroneCollisionMath.make_box_xz(centre, forward, length, width, y_lo, y_hi)
	if not ob.is_empty():
		_register_obb(ob)

func _add_obb_from_aabb(xf: Transform3D, local_box: AABB) -> void:
	var ob := DroneCollisionMath.make_obb(xf, local_box)
	if not ob.is_empty():
		_register_obb(ob)

func _register_obb(ob: Dictionary) -> void:
	var idx := _obbs.size()
	_obbs.append(ob)
	var mn: Vector2 = ob["min_xz"]
	var mx: Vector2 = ob["max_xz"]
	DroneCollisionMath.insert_rect(_obb_cells, Rect2(mn, mx - mn), idx)
