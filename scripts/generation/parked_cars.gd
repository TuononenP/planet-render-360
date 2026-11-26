class_name ParkedCars
extends RefCounted

## Cars parked along the kerbs (desktop Ultra): a city street with empty
## kerbs read as a model, not a place — San Francisco's hills are lined
## bumper to bumper, pitched with the grade.
## * Where: street classes in CLASSES within RADIUS_M of the eye, on the
##   sides the road's `parking` tag names; untagged, on both sides where
##   the measured kerb width leaves room past the lanes (RoadWidths
##   `parking_m`: one lane's room parks the right side, two both).
## * How: a slot every SLOT_M along the kerb, CUT_M clear of every
##   junction (corners and crossings stay open), OCCUPIED of them taken;
##   each car sits on the ground under its own wheels, so it pitches and
##   leans with the street.
## * Cars: the place's fleet (CarFleet: body kinds, paint shares, the
##   local taxi), each kind modelled from its spec (CarModel); most
##   coloured and grey paints are metallic, and each car carries some
##   road grime (CarPaint) and is a little longer or taller than the next. Placement hashes
##   positions, so a street always parks the same cars, each a little off
##   square to the kerb. MultiMeshes group nearby cars by kind; distant
##   groups use simpler meshes, and a soft contact shadow sits under every
##   car.

const RADIUS_M := 320.0
const MAX_CARS := 1500
const CLASSES: Array[String] = ["residential", "tertiary", "secondary", "unclassified",
	"primary", "living_street"]
const SLOT_M := 6.0
const CUT_M := 9.0
const OCCUPIED := 0.78
## Car centreline inside the kerb (m).
const KERB_IN_M := 1.15
## Off-square parking: yaw (degrees) and sideways play (m) either way.
const YAW_JITTER_DEG := 1.2
const KERB_JITTER_M := 0.1
## No two cars of a kind are quite one size: length and height either way.
const LENGTH_JITTER := 0.03
const HEIGHT_JITTER := 0.02

static var _meshes: Dictionary = {}
static var _native_props := ClassDB.class_exists("PropKernels")
const CELL_M := 40.0
const DETAIL_M := 110.0
## Render layer of the cars (and buses): off the default layer, so the
## street's decals (RoadDecals: manhole covers, gutter grates, leaf litter,
## cull mask without this bit) do not project onto bonnets and roofs, where a
## grate beside the kerb drew a dark striped patch.
const CAR_LAYER := 2

static func _shore_body_levels(ground: GroundTruth) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	if ground.shoreline == null or not ground.shoreline.ready or ground.shoreline.domains == null:
		return out
	var bodies: Array = ground.shoreline.domains.bodies
	out.resize(bodies.size() * 6)
	for i in bodies.size():
		var b: Dictionary = bodies[i]
		out[i * 6 + 0] = float(b.get("level", 0.0))
		if b.has("level_end"):
			var ax: PackedVector2Array = b["axis"]
			out[i * 6 + 1] = float(b["level_end"])
			out[i * 6 + 2] = ax[0].x
			out[i * 6 + 3] = ax[0].y
			out[i * 6 + 4] = ax[1].x
			out[i * 6 + 5] = ax[1].y
		else:
			out[i * 6 + 1] = NAN
			out[i * 6 + 2] = 0.0
			out[i * 6 + 3] = 0.0
			out[i * 6 + 4] = 0.0
			out[i * 6 + 5] = 0.0
	return out

static func _plan_native(data: LocationData, ground: GroundTruth, m2u: float, shared_junc: Dictionary, transit_fp: Array = []) -> Array:
	var centre := View360.spawn_xz(data)
	var r_u := RADIUS_M * m2u
	var r2 := r_u * r_u
	var road_pad := (RADIUS_M + 25.0) * m2u
	var min_x := centre.x - road_pad
	var max_x := centre.x + road_pad
	var min_z := centre.y - road_pad
	var max_z := centre.y + road_pad
	var grid_r := (RADIUS_M + 40.0) * m2u
	var g_min_x := centre.x - grid_r
	var g_max_x := centre.x + grid_r
	var g_min_z := centre.y - grid_r
	var g_max_z := centre.y + grid_r
	var roads_in: Array = []
	for r in data.roads:
		if not (r is Dictionary):
			continue
		var road: Dictionary = r
		if not str(road.get("class", "")) in CLASSES or bool(road.get("tunnel", false)) \
				or bool(road.get("bridge", false)) or bool(road.get("area", false)):
			continue
		var sides := sides_of(road)
		if sides == 0:
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var rmin_x := pts[0].x; var rmax_x := rmin_x
		var rmin_z := pts[0].y; var rmax_z := rmin_z
		for pi in range(1, pts.size()):
			var pt := pts[pi]
			if pt.x < rmin_x: rmin_x = pt.x
			elif pt.x > rmax_x: rmax_x = pt.x
			if pt.y < rmin_z: rmin_z = pt.y
			elif pt.y > rmax_z: rmax_z = pt.y
		if rmax_x < min_x or rmin_x > max_x or rmax_z < min_z or rmin_z > max_z:
			continue
		var half := float(road.get("width_m", 6.0)) * 0.5
		if half < 2.5:
			continue
		var off := (half - KERB_IN_M) * m2u
		roads_in.append([pts, off, -off, sides, int(road.get("oneway", 0))])
	if roads_in.is_empty():
		return []
	var junc := shared_junc if not shared_junc.is_empty() else RoadSurface.junctions(data)
	var junc_pts := PackedVector2Array()
	for v in junc.values():
		if v is PackedVector2Array:
			junc_pts.append_array(v)
	var obs_segs := PackedFloat32Array()
	for nodes in [data.trees, data.street_furniture]:
		for node in nodes:
			var px := float(node.get("x", 0.0))
			var pz := float(node.get("z", 0.0))
			if px < g_min_x or px > g_max_x or pz < g_min_z or pz > g_max_z:
				continue
			obs_segs.push_back(px); obs_segs.push_back(pz); obs_segs.push_back(px); obs_segs.push_back(pz); obs_segs.push_back(1.5 * m2u)
	for rail in data.railways:
		if str(rail.get("class", "")) != "tram" or bool(rail.get("tunnel", false)):
			continue
		var rpts: PackedVector2Array = rail.get("points", PackedVector2Array())
		var rad := (float(rail.get("gauge_m", 1.435)) * 0.5 + 1.0) * m2u
		for i in rpts.size() - 1:
			var a := rpts[i]; var b := rpts[i + 1]
			if maxf(a.x, b.x) < g_min_x or minf(a.x, b.x) > g_max_x or maxf(a.y, b.y) < g_min_z or minf(a.y, b.y) > g_max_z:
				continue
			obs_segs.push_back(a.x); obs_segs.push_back(a.y); obs_segs.push_back(b.x); obs_segs.push_back(b.y); obs_segs.push_back(rad)
	var fp_src := transit_fp if not transit_fp.is_empty() else TransitVehicles.footprints(data, ground, m2u)
	for item: Array in fp_src:
		var a: Vector2 = item[0]; var b: Vector2 = item[1]
		obs_segs.push_back(a.x); obs_segs.push_back(a.y); obs_segs.push_back(b.x); obs_segs.push_back(b.y); obs_segs.push_back(float(item[2]))
	var bldg_rings: Array = []
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var fp: Variant = (b as Dictionary).get("footprint", null)
		if not (fp is PackedVector2Array) or (fp as PackedVector2Array).size() < 3:
			continue
		var ring := fp as PackedVector2Array
		var bx0 := ring[0].x; var bx1 := bx0; var bz0 := ring[0].y; var bz1 := bz0
		for v in ring:
			if v.x < bx0: bx0 = v.x
			elif v.x > bx1: bx1 = v.x
			if v.y < bz0: bz0 = v.y
			elif v.y > bz1: bz1 = v.y
		if bx1 < g_min_x or bx0 > g_max_x or bz1 < g_min_z or bz0 > g_max_z:
			continue
		bldg_rings.append(ring)
	var fleet := CarFleet.profile(data)
	var taxi: Dictionary = fleet["taxi"]
	var kind_names: Array[String] = []
	var kind_id := {}
	var add_kind := func(k: String) -> int:
		if not kind_id.has(k):
			kind_id[k] = kind_names.size()
			kind_names.append(k)
		return int(kind_id[k])
	var taxi_kidx: int = add_kind.call(str(taxi["kind"]))
	var sports_kidx: int = add_kind.call("sports")
	var fk := PackedInt32Array()
	for k in fleet["kinds"]:
		fk.append(add_kind.call(str(k)))
	var tuk_kidx: int = int(kind_id.get("tuk_tuk", -1))
	var klens := PackedFloat32Array()
	var kwids := PackedFloat32Array()
	for k in kind_names:
		klens.append(_length_m(k))
		kwids.append(_width_m(k))
	var to_pca := func(arr: Array) -> PackedColorArray:
		var pca := PackedColorArray()
		for c in arr:
			pca.append(c)
		return pca
	var shore_ready: bool = ground.shoreline != null and ground.shoreline.ready and ground.shoreline.sampler != null
	var shore_empty: bool = ground.shoreline != null and ground.shoreline.empty()
	var params := {
		"roads": roads_in,
		"centre": centre, "r2": r2, "m2u": m2u,
		"left_traffic": RoadSurface.left_traffic(data), "max_cars": MAX_CARS,
		"junc_cell": RoadSurface.JUNCTION_M, "junc_pts": junc_pts,
		"obs_segs": obs_segs, "bldg_rings": bldg_rings,
		"shore_sampler": ground.shoreline.sampler if shore_ready else null,
		"shore_domains": ground.shoreline.domains.native if shore_ready and ground.shoreline.domains != null else null,
		"shore_bounds": ground.shoreline.bounds if shore_ready else Rect2(),
		"shore_empty": shore_empty,
		"body_levels": _shore_body_levels(ground),
		"surface": ground._surface, "level": ground._level,
		"grid_size": ground._size, "step_units": ground._step_units,
		"half_units": ground._half_units, "water_level_m": ground.water_level_m,
		"fleet": {
			"taxi_share": float(taxi.get("share", CarFleet.TAXI_SHARE)),
			"sports_share": float(fleet.get("sports_share", CarFleet.SPORTS_SHARE)),
			"taxi_kind_idx": taxi_kidx, "sports_kind_idx": sports_kidx, "tuk_kind_idx": tuk_kidx,
			"fleet_kinds": fk, "kind_lens": klens, "kind_widths": kwids,
			"paint": to_pca.call(fleet["paint"]),
			"taxi_paint": to_pca.call(taxi["paint"]),
			"sports_paint": to_pca.call(CarFleet.SPORTS_PAINT),
			"tuk_paint": to_pca.call(CarFleet.TUK_TUK_PAINT),
		},
	}
	var res: Dictionary = ClassDB.class_call_static("PropKernels", "parked_cars_plan", params)
	var pos_a: PackedVector3Array = res["pos"]
	var bx_a: PackedVector3Array = res["bx"]
	var by_a: PackedVector3Array = res["by"]
	var bz_a: PackedVector3Array = res["bz"]
	var kind_a: PackedInt32Array = res["kind"]
	var col_a: PackedColorArray = res["col"]
	var fin_a: PackedColorArray = res["finish"]
	var d2_a: PackedFloat32Array = res["d2"]
	var out: Array = []
	out.resize(pos_a.size())
	for i in pos_a.size():
		out[i] = [pos_a[i], Basis(bx_a[i], by_a[i], bz_a[i]), kind_names[kind_a[i]], col_a[i], d2_a[i], fin_a[i]]
	return out

## Cars [position, basis, kind, colour, distance², finish] for `data`'s
## streets, nearest first; finish is the CarPaint instance data.
static func plan(data: LocationData, ground: GroundTruth, m2u: float, shared_junc: Dictionary = {}, transit_fp: Array = []) -> Array:
	if _native_props and not data.roads.is_empty():
		return _plan_native(data, ground, m2u, shared_junc, transit_fp)
	var cars: Array = []
	var centre := View360.spawn_xz(data)
	var r_u := RADIUS_M * m2u
	var r2 := r_u * r_u
	var grid_r := (RADIUS_M + 40.0) * m2u
	var junc := shared_junc if not shared_junc.is_empty() else RoadSurface.junctions(data)
	var obstacles := obstacle_grid(data, m2u, centre, grid_r)
	var walls := building_grid(data, m2u, centre, grid_r)
	# Standing trams and buses hold their kerb.
	for item: Array in TransitVehicles.footprints(data, ground, m2u):
		_add_obstacle(obstacles, item[0], item[1], float(item[2]), m2u)
	var left_traffic := RoadSurface.left_traffic(data)
	var fleet := CarFleet.profile(data)
	var road_pad := (RADIUS_M + 25.0) * m2u
	var min_x := centre.x - road_pad
	var max_x := centre.x + road_pad
	var min_z := centre.y - road_pad
	var max_z := centre.y + road_pad
	for r in data.roads:
		if not (r is Dictionary):
			continue
		var road: Dictionary = r
		if not str(road.get("class", "")) in CLASSES or bool(road.get("tunnel", false)) \
				or bool(road.get("bridge", false)) or bool(road.get("area", false)):
			continue
		var sides := sides_of(road)
		if sides == 0:
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var rmin_x := pts[0].x
		var rmax_x := rmin_x
		var rmin_z := pts[0].y
		var rmax_z := rmin_z
		for pi in range(1, pts.size()):
			var pt := pts[pi]
			if pt.x < rmin_x: rmin_x = pt.x
			elif pt.x > rmax_x: rmax_x = pt.x
			if pt.y < rmin_z: rmin_z = pt.y
			elif pt.y > rmax_z: rmax_z = pt.y
		if rmax_x < min_x or rmin_x > max_x or rmax_z < min_z or rmin_z > max_z:
			continue
		var half := float(road.get("width_m", 6.0)) * 0.5
		if half < 2.5:
			continue
		for side in [[1, 1.0], [2, -1.0]]:
			if sides & int(side[0]) != 0:
				_kerb(cars, pts, (half - KERB_IN_M) * float(side[1]) * m2u, centre, r2, junc, ground, m2u,
				int(road.get("oneway", 0)), left_traffic, obstacles, fleet, walls, min_x, max_x, min_z, max_z)
	cars.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[4]) < float(b[4]))
	return cars.slice(0, MAX_CARS)

## Parked sides (bits 1 left, 2 right) of a road: its `parking` tag, else
## the measured room past its lanes.
static func sides_of(road: Dictionary) -> int:
	var tagged := int(road.get("parking", -1))
	if tagged >= 0:
		return tagged
	var room := float(road.get("parking_m", 0.0))
	if room >= 2.0 * OsmTags.PARKING_LANE_M - 0.6:
		return 3
	if room >= OsmTags.PARKING_LANE_M - 0.3:
		return 2
	return 0

## One kerb: slots along the polyline offset `off` to its left.
static func _kerb(cars: Array, pts: PackedVector2Array, off: float, centre: Vector2, r2: float,
		junc: Dictionary, ground: GroundTruth, m2u: float, oneway: int,
		left_traffic: bool, obstacles: Dictionary, fleet: Dictionary, walls: Dictionary = {},
		min_x: float = -INF, max_x: float = INF, min_z: float = -INF, max_z: float = INF) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		if maxf(a.x, b.x) < min_x or minf(a.x, b.x) > max_x \
				or maxf(a.y, b.y) < min_z or minf(a.y, b.y) > max_z:
			continue
		var len := a.distance_to(b)
		if len < SLOT_M * m2u:
			continue
		var dir := (b - a) / len
		var left := Vector2(dir.y, -dir.x)
		var slots := int(len / (SLOT_M * m2u))
		for k in slots:
			var t := (float(k) + 0.5) * len / float(slots)
			var p := a + dir * t + left * off
			var d2 := (p - centre).length_squared()
			if d2 > r2 or _near_junction(p, junc, CUT_M * m2u):
				continue
			if _hash(p.x, p.y, 1.3) > OCCUPIED:
				continue
			var car: Array = CarFleet.pick(fleet, p)
			var kind: String = car[0]
			var length := _length_m(kind) * m2u
			# A causeway or quay road the map does not call a bridge.
			if blocked(p, obstacles, m2u) or ground.water_at(p.x, p.y) > 0.0:
				continue
			var fw := facing(dir, off, oneway, left_traffic).rotated(
				deg_to_rad(YAW_JITTER_DEG) * (_hash(p.x, p.y, 6.1) * 2.0 - 1.0))
			var q := p + left * KERB_JITTER_M * m2u * (_hash(p.x, p.y, 7.3) * 2.0 - 1.0)
			var front := q + fw * length * 0.4
			var back := q - fw * length * 0.4
			# A road the map runs through a building's footprint (a plaza, an
			# arcade) would park the car in the wall.
			if _in_building(q, fw, length, _width_m(kind) * m2u, walls, m2u):
				continue
			var yf := ground.height_at_world(front.x, front.y)
			var yb := ground.height_at_world(back.x, back.y)
			var forward := Vector3(fw.x * length * 0.8, yf - yb, fw.y * length * 0.8).normalized()
			# Lean with the camber too: on a street that falls away to one
			# side a level car hung its downhill wheels in the air.
			var across := Vector2(-fw.y, fw.x) * 0.8 * m2u
			var lean := Vector3(across.x * 2.0, ground.height_at_world(q.x + across.x, q.y + across.y)
				- ground.height_at_world(q.x - across.x, q.y - across.y), across.y * 2.0).normalized()
			var up := lean.cross(forward).normalized()
			if up.y < 0.0:
				up = -up
			var basis := Basis(forward, up, forward.cross(up))
			var pos := Vector3(q.x, (yf + yb) * 0.5 + 0.04 * m2u, q.y)
			var size := Vector3(1.0 + LENGTH_JITTER * (_hash(p.x, p.y, 3.4) * 2.0 - 1.0),
				1.0 + HEIGHT_JITTER * (_hash(p.x, p.y, 3.9) * 2.0 - 1.0), 1.0)
			cars.append([pos, basis * Basis.from_scale(size * m2u), kind, car[1], d2, car[2]])

static func _near_junction(p: Vector2, junc: Dictionary, cut: float) -> bool:
	var cell := Vector2i(floori(p.x / RoadSurface.JUNCTION_M), floori(p.y / RoadSurface.JUNCTION_M))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q in (junc.get(cell + Vector2i(dx, dz), PackedVector2Array()) as PackedVector2Array):
				if q.distance_to(p) < cut:
					return true
	return false

static func _width_m(kind: String) -> float:
	return TukTukModel.WIDTH_M if kind == "tuk_tuk" else CarSpecs.width_m(kind)

static func _length_m(kind: String) -> float:
	return TukTukModel.LENGTH_M if kind == "tuk_tuk" else CarSpecs.length_m(kind)

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)

static func build(root: Node3D, data: LocationData, ground: GroundTruth, shared_junc: Dictionary = {}, transit_fp: Array = []) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset) or data.roads.is_empty():
		return 0
	var cars := plan(data, ground, WorldScale.metres_to_units(), shared_junc, transit_fp)
	if cars.is_empty():
		return 0
	var holder := Node3D.new()
	holder.name = "ParkedCars"
	var cells := CellBatches.group(cars, CELL_M * WorldScale.metres_to_units(),
		func(car: Array) -> Vector3: return car[0], func(car: Array) -> String: return car[2])
	for group_key in cells:
		var list: Array = cells[group_key]
		var kind: String = list[0][2]
		var detail := TukTukModel.mesh(false) if kind == "tuk_tuk" else CarModel.mesh(kind)
		var distant := TukTukModel.mesh(true) if kind == "tuk_tuk" else CarModel.mesh(kind, true)
		var near := _add_batch(holder, list, detail, str(group_key) + "_near", 0.0, DETAIL_M)
		var far := _add_batch(holder, list, distant, str(group_key) + "_far", DETAIL_M, 0.0)
		# Visibility ranges measure from the AABB centre; differing mesh
		# bounds would otherwise leave a gap or overlap at the switch.
		var bounds := _batch_bounds(list, detail.get_aabb().merge(distant.get_aabb()))
		near.custom_aabb = bounds
		far.custom_aabb = bounds
		_add_batch(holder, list, shadow_mesh(kind), str(group_key) + "_shadow", 0.0, 0.0)
		var glass := null if kind == "tuk_tuk" else CarModel.glass_shadow_mesh(kind)
		if glass != null:
			_add_batch(holder, list, glass, str(group_key) + "_glass", 0.0, DETAIL_M)
			(holder.get_child(holder.get_child_count() - 1) as GeometryInstance3D).cast_shadow = \
				GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	root.add_child(holder)
	return cars.size()

static func _add_batch(holder: Node3D, cars: Array, car_mesh: Mesh, batch_name: String,
		begin_m: float, end_m: float) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = car_mesh
	var count := cars.size()
	mm.instance_count = count
	# Direct MultiMesh.buffer upload (stride 20: 3x4 transform + RGBA color + RGBA custom_data).
	var buf := PackedFloat32Array()
	buf.resize(count * 20)
	for i in count:
		var c: Array = cars[i]
		var b: Basis = c[1]
		var o: Vector3 = c[0]
		var col: Color = c[3]
		var cd: Color = c[5]
		var idx := i * 20
		buf[idx] = b.x.x;      buf[idx + 1] = b.y.x;  buf[idx + 2] = b.z.x;  buf[idx + 3] = o.x
		buf[idx + 4] = b.x.y;  buf[idx + 5] = b.y.y;  buf[idx + 6] = b.z.y;  buf[idx + 7] = o.y
		buf[idx + 8] = b.x.z;  buf[idx + 9] = b.y.z;  buf[idx + 10] = b.z.z; buf[idx + 11] = o.z
		buf[idx + 12] = col.r; buf[idx + 13] = col.g; buf[idx + 14] = col.b; buf[idx + 15] = col.a
		buf[idx + 16] = cd.r;  buf[idx + 17] = cd.g;  buf[idx + 18] = cd.b;  buf[idx + 19] = cd.a
	mm.buffer = buf
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Cars_" + batch_name
	mmi.multimesh = mm
	mmi.layers = CAR_LAYER
	CellBatches.ranged(mmi, begin_m * WorldScale.metres_to_units(), end_m * WorldScale.metres_to_units())
	if car_mesh is PlaneMesh:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mmi)
	return mm

## Shared near/far bounds of `cars` ([basis, origin, ...]) placing `local_bounds`.
static func _batch_bounds(cars: Array, local_bounds: AABB) -> AABB:
	return CellBatches.bounds(cars.map(func(c: Array) -> Transform3D: return Transform3D(c[1], c[0])), local_bounds)

## The contact shadow under a `kind` car: a ground quad a little past its
## footprint, just over the road (metres, like the car).
static func shadow_mesh(kind: String) -> PlaneMesh:
	var key := kind + "_shadow"
	if not _meshes.has(key):
		var plane := PlaneMesh.new()
		plane.size = Vector2(_length_m(kind) * 1.18, _width_m(kind) * 1.3)
		# Cars stand 4 cm up; this puts the quad 7 cm over the ground,
		# above the road ribbon's lift (CarPaint.SHADOW_CODE).
		plane.center_offset = Vector3(0.0, 0.03, 0.0)
		plane.material = CarPaint.shadow_material()
		_meshes[key] = plane
	return _meshes[key]

## The box, card and tube helpers wind their triangles counter-clockwise
## about the outward normal, which Godot culls as back faces (a car read
## as a hollow box from close by): reverse every triangle.
static func front_faces(idx: PackedInt32Array) -> PackedInt32Array:
	var out := idx.duplicate()
	for t in range(0, out.size() - 2, 3):
		var b := out[t + 1]
		out[t + 1] = out[t + 2]
		out[t + 2] = b
	return out

## Kerb traffic follows the mapped direction on both sides of a one-way.
static func facing(dir: Vector2, off: float, oneway: int, left_traffic: bool) -> Vector2:
	if oneway != 0:
		return dir * signi(oneway)
	return dir if (off < 0.0) != left_traffic else -dir

const OBSTACLE_CELL_M := 6.0
## Cell of the building index (m): coarser, a building spans many cells.
const BUILDING_CELL_M := 24.0

static func obstacle_grid(data: LocationData, m2u: float, centre: Vector2 = Vector2.ZERO, max_r: float = INF) -> Dictionary:
	var grid := {}
	var bounded := is_finite(max_r)
	var min_x := centre.x - max_r
	var max_x := centre.x + max_r
	var min_z := centre.y - max_r
	var max_z := centre.y + max_r
	var cell := OBSTACLE_CELL_M * m2u
	for nodes in [data.trees, data.street_furniture]:
		for node in nodes:
			var p := Vector2(float(node.get("x", 0.0)), float(node.get("z", 0.0)))
			if bounded and (p.x < min_x or p.x > max_x or p.y < min_z or p.y > max_z):
				continue
			var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
			if not grid.has(key):
				grid[key] = []
			(grid[key] as Array).append([p, p, 1.5 * m2u])
	for rail in data.railways:
		if str(rail.get("class", "")) != "tram" or bool(rail.get("tunnel", false)):
			continue
		var pts: PackedVector2Array = rail.get("points", PackedVector2Array())
		var pad := Vector2.ONE * 2.0 * m2u
		var rad := (float(rail.get("gauge_m", 1.435)) * 0.5 + 1.0) * m2u
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			if bounded and (maxf(a.x, b.x) < min_x or minf(a.x, b.x) > max_x \
					or maxf(a.y, b.y) < min_z or minf(a.y, b.y) > max_z):
				continue
			var lo := (a.min(b) - pad) / cell
			var hi := (a.max(b) + pad) / cell
			for x in range(floori(lo.x), floori(hi.x) + 1):
				for z in range(floori(lo.y), floori(hi.y) + 1):
					var key := Vector2i(x, z)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append([a, b, rad])
	return grid

## A segment obstacle a-b of `radius` (world units) into `grid`.
static func _add_obstacle(grid: Dictionary, a: Vector2, b: Vector2, radius: float, m2u: float) -> void:
	var cell := OBSTACLE_CELL_M * m2u
	var lo := (a.min(b) - Vector2.ONE * radius) / cell
	var hi := (a.max(b) + Vector2.ONE * radius) / cell
	for x in range(floori(lo.x), floori(hi.x) + 1):
		for z in range(floori(lo.y), floori(hi.y) + 1):
			var key := Vector2i(x, z)
			if not grid.has(key):
				grid[key] = []
			(grid[key] as Array).append([a, b, radius])

## Building outlines [ring, box] in every BUILDING_CELL_M cell their box touches.
static func building_grid(data: LocationData, m2u: float, centre: Vector2 = Vector2.ZERO, max_r: float = INF) -> Dictionary:
	var grid := {}
	var bounded := is_finite(max_r)
	var min_x := centre.x - max_r
	var max_x := centre.x + max_r
	var min_z := centre.y - max_r
	var max_z := centre.y + max_r
	var cell := BUILDING_CELL_M * m2u
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var fp: Variant = (b as Dictionary).get("footprint", null)
		if not (fp is PackedVector2Array) or (fp as PackedVector2Array).size() < 3:
			continue
		var ring := fp as PackedVector2Array
		var box := Rect2(ring[0], Vector2.ZERO)
		for v in ring:
			box = box.expand(v)
		if bounded and (box.end.x < min_x or box.position.x > max_x \
				or box.end.y < min_z or box.position.y > max_z):
			continue
		var rec := [ring, box]
		for cx in range(floori(box.position.x / cell), floori(box.end.x / cell) + 1):
			for cz in range(floori(box.position.y / cell), floori(box.end.y / cell) + 1):
				var key := Vector2i(cx, cz)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(rec)
	return grid

## True when a car of `length` x `width` (world units) at `q` facing `fw`
## has its centre, ends or corners inside a building's outline.
static func _in_building(q: Vector2, fw: Vector2, length: float, width: float, grid: Dictionary,
		m2u: float) -> bool:
	if grid.is_empty():
		return false
	var side := Vector2(-fw.y, fw.x)
	var pts: Array[Vector2] = [q]
	for e: float in [-0.5, 0.0, 0.5]:
		for s: float in [-0.5, 0.5]:
			pts.append(q + fw * length * e + side * width * s)
	pts.append(q + fw * length * 0.5)
	pts.append(q - fw * length * 0.5)
	var cell := BUILDING_CELL_M * m2u
	for p in pts:
		var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
		for rec in grid.get(key, []):
			if (rec[1] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, rec[0] as PackedVector2Array):
				return true
	return false

static func blocked(p: Vector2, grid: Dictionary, m2u: float) -> bool:
	var key := Vector2i(floori(p.x / (OBSTACLE_CELL_M * m2u)), floori(p.y / (OBSTACLE_CELL_M * m2u)))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for item in grid.get(key + Vector2i(dx, dz), []):
				var a: Vector2 = item[0]
				var b: Vector2 = item[1]
				var q := Geometry2D.get_closest_point_to_segment(p, a, b) if a != b else a
				if p.distance_to(q) < float(item[2]):
					return true
	return false
