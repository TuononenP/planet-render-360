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
##   each car sits on the ground under its own wheels, so it pitches with
##   the street.
## * Cars: sedans, hatchbacks, wagons, SUVs and vans modelled from their
##   specs (CarModel); paint mostly white, black, grey and
##   silver, some colour; most coloured and grey paints are metallic, and
##   each car carries some road grime (CarPaint). Placement hashes
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
const KINDS: Array[String] = ["sedan", "sedan", "hatch", "hatch", "wagon", "suv", "suv", "van"]
## Roughly the fleet's shares: white, black, grey and silver lead.
const PAINT := [Color(0.85, 0.85, 0.84), Color(0.85, 0.85, 0.84), Color(0.85, 0.85, 0.84),
	Color(0.03, 0.03, 0.035), Color(0.03, 0.03, 0.035), Color(0.30, 0.31, 0.32), Color(0.30, 0.31, 0.32),
	Color(0.55, 0.56, 0.57), Color(0.55, 0.56, 0.57), Color(0.20, 0.04, 0.04), Color(0.04, 0.08, 0.20),
	Color(0.42, 0.40, 0.34)]
## Off-square parking: yaw (degrees) and sideways play (m) either way.
const YAW_JITTER_DEG := 1.2
const KERB_JITTER_M := 0.1

static var _meshes: Dictionary = {}
const CELL_M := 40.0
const DETAIL_M := 110.0

## Cars [position, basis, kind, colour, distance², finish] for `data`'s
## streets, nearest first; finish is the CarPaint instance data.
static func plan(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var cars: Array = []
	var centre := View360.spawn_xz(data)
	var r2 := pow(RADIUS_M * m2u, 2.0)
	var junc := RoadSurface.junctions(data)
	var obstacles := obstacle_grid(data, m2u)
	var left_traffic := RoadSurface.left_traffic(data)
	var nyc := CityStyles.region_at(data.latitude, data.longitude) == "new_york"
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
		var half := float(road.get("width_m", 6.0)) * 0.5
		if half < 2.5:
			continue
		for side in [[1, 1.0], [2, -1.0]]:
			if sides & int(side[0]) != 0:
				_kerb(cars, pts, (half - KERB_IN_M) * float(side[1]) * m2u, centre, r2, junc, ground, m2u,
				int(road.get("oneway", 0)), left_traffic, obstacles, nyc)
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
		left_traffic: bool, obstacles: Dictionary, nyc: bool) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
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
			var kind := KINDS[int(_hash(p.x, p.y, 2.7) * KINDS.size()) % KINDS.size()]
			var length := _length_m(kind) * m2u
			if blocked(p, obstacles, m2u):
				continue
			var fw := facing(dir, off, oneway, left_traffic).rotated(
				deg_to_rad(YAW_JITTER_DEG) * (_hash(p.x, p.y, 6.1) * 2.0 - 1.0))
			var q := p + left * KERB_JITTER_M * m2u * (_hash(p.x, p.y, 7.3) * 2.0 - 1.0)
			var front := q + fw * length * 0.4
			var back := q - fw * length * 0.4
			var yf := ground.height_at_world(front.x, front.y)
			var yb := ground.height_at_world(back.x, back.y)
			var forward := Vector3(fw.x * length * 0.8, yf - yb, fw.y * length * 0.8).normalized()
			var side := forward.cross(Vector3.UP).normalized()
			var up := side.cross(forward).normalized()
			var basis := Basis(forward, up, forward.cross(up))
			var pos := Vector3(q.x, (yf + yb) * 0.5 + 0.04 * m2u, q.y)
			var colour := paint_for(p, kind, nyc)
			cars.append([pos, basis.scaled(Vector3.ONE * m2u), kind, colour, d2,
				finish_for(p, colour, nyc)])

static func _near_junction(p: Vector2, junc: Dictionary, cut: float) -> bool:
	var cell := Vector2i(floori(p.x / RoadSurface.JUNCTION_M), floori(p.y / RoadSurface.JUNCTION_M))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q in (junc.get(cell + Vector2i(dx, dz), PackedVector2Array()) as PackedVector2Array):
				if q.distance_to(p) < cut:
					return true
	return false

## A small deterministic share of New York sedans carry taxi yellow.
static func paint_for(p: Vector2, kind: String, nyc: bool) -> Color:
	if nyc and kind == "sedan" and _hash(p.x, p.y, 9.1) < 0.12:
		return Color(0.95, 0.62, 0.02)
	return PAINT[int(_hash(p.x, p.y, 4.9) * PAINT.size()) % PAINT.size()]

## CarPaint instance data: r metallic (0/1), g grime. Most grey and
## coloured paints are metallic, few whites and blacks; cabs are solid.
static func finish_for(p: Vector2, colour: Color, nyc: bool) -> Color:
	var solid_shade := colour.v > 0.8 or colour.v < 0.05
	var taxi := nyc and colour == Color(0.95, 0.62, 0.02)
	var share := 0.0 if taxi else (0.25 if solid_shade else 0.85)
	var metallic := 1.0 if _hash(p.x, p.y, 5.3) < share else 0.0
	return Color(metallic, 0.2 + 0.65 * _hash(p.x, p.y, 8.2), 0.0, 0.0)

static func _width_m(kind: String) -> float:
	return CarSpecs.width_m(kind)

static func _length_m(kind: String) -> float:
	return CarSpecs.length_m(kind)

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)

static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset) or data.roads.is_empty():
		return 0
	var cars := plan(data, ground, WorldScale.metres_to_units())
	if cars.is_empty():
		return 0
	var holder := Node3D.new()
	holder.name = "ParkedCars"
	var cells := {}
	var cell_size := CELL_M * WorldScale.metres_to_units()
	for car in cars:
		var p: Vector3 = car[0]
		var key := Vector3i(floori(p.x / cell_size), floori(p.z / cell_size), 0)
		var group_key := "%s_%d_%d" % [car[2], key.x, key.y]
		if not cells.has(group_key):
			cells[group_key] = []
		cells[group_key].append(car)
	for group_key in cells:
		var list: Array = cells[group_key]
		var kind: String = list[0][2]
		var detail := CarModel.mesh(kind)
		var distant := CarModel.mesh(kind, true)
		var near := _add_batch(holder, list, detail, str(group_key) + "_near", 0.0, DETAIL_M)
		var far := _add_batch(holder, list, distant, str(group_key) + "_far", DETAIL_M, 0.0)
		# Visibility ranges measure from the AABB centre; differing mesh
		# bounds would otherwise leave a gap or overlap at the switch.
		var bounds := _batch_bounds(list, detail.get_aabb().merge(distant.get_aabb()))
		near.custom_aabb = bounds
		far.custom_aabb = bounds
		_add_batch(holder, list, shadow_mesh(kind), str(group_key) + "_shadow", 0.0, 0.0)
	root.add_child(holder)
	return cars.size()

static func _add_batch(holder: Node3D, cars: Array, car_mesh: Mesh, batch_name: String,
		begin_m: float, end_m: float) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = car_mesh
	mm.instance_count = cars.size()
	for i in cars.size():
		var c: Array = cars[i]
		mm.set_instance_transform(i, Transform3D(c[1], c[0]))
		mm.set_instance_color(i, c[3])
		mm.set_instance_custom_data(i, c[5])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Cars_" + batch_name
	mmi.multimesh = mm
	# LodRing would clear the ranges and draw both meshes at every distance.
	mmi.set_meta("lod_own", true)
	mmi.visibility_range_begin = begin_m * WorldScale.metres_to_units()
	mmi.visibility_range_end = end_m * WorldScale.metres_to_units()
	if car_mesh is PlaneMesh:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mmi)
	return mm

static func _batch_bounds(cars: Array, local_bounds: AABB) -> AABB:
	var bounds := AABB()
	for i in cars.size():
		var c: Array = cars[i]
		var car_bounds: AABB = Transform3D(c[1], c[0]) * local_bounds
		bounds = car_bounds if i == 0 else bounds.merge(car_bounds)
	return bounds

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

static func obstacle_grid(data: LocationData, m2u: float) -> Dictionary:
	var grid := {}
	for nodes in [data.trees, data.street_furniture]:
		for node in nodes:
			var p := Vector2(float(node.get("x", 0.0)), float(node.get("z", 0.0)))
			var key := Vector2i(floori(p.x / (OBSTACLE_CELL_M * m2u)), floori(p.y / (OBSTACLE_CELL_M * m2u)))
			if not grid.has(key):
				grid[key] = []
			(grid[key] as Array).append([p, p, 1.5 * m2u])
	for rail in data.railways:
		if str(rail.get("class", "")) != "tram" or bool(rail.get("tunnel", false)):
			continue
		var pts: PackedVector2Array = rail.get("points", PackedVector2Array())
		for i in pts.size() - 1:
			var pad := Vector2.ONE * 2.0 * m2u
			var lo := (pts[i].min(pts[i + 1]) - pad) / (OBSTACLE_CELL_M * m2u)
			var hi := (pts[i].max(pts[i + 1]) + pad) / (OBSTACLE_CELL_M * m2u)
			for x in range(floori(lo.x), floori(hi.x) + 1):
				for z in range(floori(lo.y), floori(hi.y) + 1):
					var key := Vector2i(x, z)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append([pts[i], pts[i + 1], (float(rail.get("gauge_m", 1.435)) * 0.5 + 1.0) * m2u])
	return grid

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
