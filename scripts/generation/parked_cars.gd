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
## * Cars: sedans, hatchbacks, wagons, SUVs and vans with shaped bodywork,
##   glazing and wheels; paint mostly white, black, grey and
##   silver, some colour. Placement hashes positions, so a street always
##   parks the same cars. MultiMeshes group nearby cars by kind; distant
##   groups use simpler meshes.

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
const PAINT := [Color(0.85, 0.85, 0.84), Color(0.85, 0.85, 0.84), Color(0.03, 0.03, 0.035),
	Color(0.03, 0.03, 0.035), Color(0.30, 0.31, 0.32), Color(0.55, 0.56, 0.57), Color(0.55, 0.56, 0.57),
	Color(0.20, 0.04, 0.04), Color(0.04, 0.08, 0.20), Color(0.42, 0.40, 0.34)]

static var _meshes: Dictionary = {}
const CarModels = preload("res://scripts/generation/car_models.gd")
const CELL_M := 40.0
const DETAIL_M := 110.0

## Cars [position, basis, kind, colour] for `data`'s streets, nearest first.
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
			var fw := facing(dir, off, oneway, left_traffic)
			var front := p + fw * length * 0.4
			var back := p - fw * length * 0.4
			var yf := ground.height_at_world(front.x, front.y)
			var yb := ground.height_at_world(back.x, back.y)
			var forward := Vector3(fw.x * length * 0.8, yf - yb, fw.y * length * 0.8).normalized()
			var side := forward.cross(Vector3.UP).normalized()
			var up := side.cross(forward).normalized()
			var basis := Basis(forward, up, forward.cross(up))
			var pos := Vector3(p.x, (yf + yb) * 0.5 + 0.04 * m2u, p.y)
			var colour := paint_for(p, kind, nyc)
			cars.append([pos, basis.scaled(Vector3.ONE * m2u), kind, colour, d2])

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

static func _length_m(kind: String) -> float:
	match kind:
		"hatch":
			return 4.0
		"wagon":
			return 4.7
		"suv":
			return 4.7
		"van":
			return 5.0
	return 4.6

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
		var detail := CarModels.mesh(kind)
		if detail == null:
			_add_batch(holder, list, mesh(kind), str(group_key), 0.0, 0.0)
		else:
			var distant := mesh(kind)
			var near := _add_batch(holder, list, detail, str(group_key) + "_near", 0.0, DETAIL_M)
			var far := _add_batch(holder, list, distant, str(group_key) + "_far", DETAIL_M, 0.0)
			# Visibility ranges measure from the AABB centre; differing mesh
			# bounds would otherwise leave a gap or overlap at the switch.
			var bounds := _batch_bounds(list, detail.get_aabb().merge(distant.get_aabb()))
			near.custom_aabb = bounds
			far.custom_aabb = bounds
	root.add_child(holder)
	return cars.size()

static func _add_batch(holder: Node3D, cars: Array, car_mesh: ArrayMesh, batch_name: String,
		begin_m: float, end_m: float) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = car_mesh
	mm.instance_count = cars.size()
	for i in cars.size():
		var c: Array = cars[i]
		mm.set_instance_transform(i, Transform3D(c[1], c[0]))
		mm.set_instance_color(i, c[3])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Cars_" + batch_name
	mmi.multimesh = mm
	mmi.visibility_range_begin = begin_m * WorldScale.metres_to_units()
	mmi.visibility_range_end = end_m * WorldScale.metres_to_units()
	holder.add_child(mmi)
	return mm

static func _batch_bounds(cars: Array, local_bounds: AABB) -> AABB:
	var bounds := AABB()
	for i in cars.size():
		var c: Array = cars[i]
		var car_bounds: AABB = Transform3D(c[1], c[0]) * local_bounds
		bounds = car_bounds if i == 0 else bounds.merge(car_bounds)
	return bounds

## A car along +X, centred on its footprint, wheels on y = 0 (metres).
static func mesh(kind: String) -> ArrayMesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var surf := {}
	var buf := func(mat: String) -> TreeMeshLibrary.Buf:
		if not surf.has(mat):
			surf[mat] = TreeMeshLibrary.Buf.new()
		return surf[mat]
	var length := _length_m(kind)
	var wide := 1.95 if kind == "van" else (1.85 if kind == "suv" else 1.78)
	# The body's skirt hides the top of the wheels (a sill at the axle
	# height read as a table on legs).
	var sill := 0.3 if kind in ["suv", "van"] else 0.24
	var body_h := 1.1 if kind == "van" else (0.80 if kind == "suv" else 0.72)
	var cabin_h := 0.75 if kind == "van" else (0.68 if kind == "suv" else 0.55)
	var cabin_l := length * (0.48 if kind == "sedan" else (0.58 if kind == "hatch" else 0.68))
	var cabin_x := -length * 0.06 if kind == "sedan" else 0.0
	if kind == "van":
		cabin_l = length * 0.70
	# Lower body, then the glasshouse: raked windscreen and rear window,
	# tumblehome sides (all glazed) under a painted roof. A box cabin read
	# as a white crate at street distance.
	_body(buf.call("body"), length, wide, sill, body_h)
	var y0 := sill + body_h
	var y1 := y0 + cabin_h
	var rake_f := cabin_h * (0.55 if kind == "van" else 1.35)
	var rake_b := cabin_h * (0.30 if kind in ["van", "suv", "hatch", "wagon"] else 1.0)
	var xb := cabin_x - cabin_l * 0.5
	var xf := cabin_x + cabin_l * 0.5
	var zb := wide * 0.46
	var zt := wide * 0.40
	var lo := [Vector3(xb, y0, -zb), Vector3(xf, y0, -zb), Vector3(xf, y0, zb), Vector3(xb, y0, zb)]
	var hi := [Vector3(xb + rake_b, y1, -zt), Vector3(xf - rake_f, y1, -zt), Vector3(xf - rake_f, y1, zt),
		Vector3(xb + rake_b, y1, zt)]
	var mid := Vector3(cabin_x, (y0 + y1) * 0.5, 0.0)
	for k in 4:
		var corners := [lo[k], lo[(k + 1) % 4], hi[(k + 1) % 4], hi[k]]
		_face(buf.call("body"), corners, mid)
		var face_mid: Vector3 = (corners[0] + corners[1] + corners[2] + corners[3]) * 0.25
		var normal: Vector3 = (corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized()
		if normal.dot(face_mid - mid) < 0.0:
			normal = -normal
		var glass: Array = []
		for corner in corners:
			glass.append((corner as Vector3).lerp(face_mid, 0.12) + normal * 0.006)
		_face(buf.call("glass"), glass, mid)
	# Crown the roof and round its edges instead of a flat rectangular slab.
	var roof_back := xb + rake_b + 0.12
	var roof_front := xf - rake_f - 0.12
	var crown_y := y1 + cabin_h * 0.10
	var roof := [Vector3(roof_back, crown_y, -zt * 0.75), Vector3(roof_front, crown_y, -zt * 0.75),
		Vector3(roof_front, crown_y, zt * 0.75), Vector3(roof_back, crown_y, zt * 0.75)]
	for k in 4:
		_face(buf.call("body"), [hi[k], hi[(k + 1) % 4], roof[(k + 1) % 4], roof[k]], mid)
	_face(buf.call("body"), roof, mid)
	# Painted centre pillars break up the side glass.
	for edge in [0, 2]:
		var a: Vector3 = lo[edge]
		var b: Vector3 = lo[(edge + 1) % 4]
		var c: Vector3 = hi[(edge + 1) % 4]
		var d: Vector3 = hi[edge]
		var offset := Vector3(0, 0.012, -0.025 if edge == 0 else 0.025)
		_face(buf.call("trim"), [a.lerp(b, 0.48) + offset, a.lerp(b, 0.515) + offset,
			d.lerp(c, 0.515) + offset, d.lerp(c, 0.48) + offset], mid)
	for z in [-1.0, 1.0]:
		StreetProps._box(buf.call("trim"), Vector3(xf - cabin_l * 0.12, y0 + 0.09, z * (wide * 0.5 + 0.045)),
			Vector3(0.20, 0.10, 0.18))
		# Door handles and side skirt give scale to the otherwise plain flank.
		for x in [-length * 0.17, length * 0.13]:
			StreetProps._box(buf.call("trim"), Vector3(x, sill + body_h * 0.73, z * (wide * 0.5 + 0.005)),
				Vector3(0.16, 0.025, 0.018))
	for z in [-wide * 0.27, wide * 0.27]:
		StreetProps._box(buf.call("headlight"), Vector3(length * 0.5 + 0.002, sill + body_h * 0.49, z),
			Vector3(0.012, 0.085, wide * 0.20))
		StreetProps._box(buf.call("taillight"), Vector3(-length * 0.5 - 0.002, sill + body_h * 0.49, z),
			Vector3(0.012, 0.10, wide * 0.20))
	StreetProps._box(buf.call("trim"), Vector3(length * 0.5 + 0.012, sill + body_h * 0.32, 0),
		Vector3(0.035, 0.14, wide * 0.48))
	# Bumpers and the dark sill between the wheels.
	StreetProps._box(buf.call("trim"), Vector3(0.0, sill + 0.045, 0.0), Vector3(length * 0.88, 0.09, wide * 0.96))
	var wr := 0.33 if kind != "hatch" else 0.31
	for x in [length * 0.32, -length * 0.32]:
		for z in [wide * 0.5 - 0.04, -wide * 0.5 + 0.04]:
			_wheel_arch(buf.call("trim"), Vector3(x, wr, signf(z) * (wide * 0.5 + 0.006)), wr * 1.19, signf(z))
			TreeMeshLibrary._tube(buf.call("tyre"), [Vector3(x, wr, z - 0.11), Vector3(x, wr, z + 0.11)],
				[wr, wr], 20, 1.0, 1.0)
			_wheel_face(buf.call("tyre"), Vector3(x, wr, z + signf(z) * 0.112), wr, signf(z))
			var hub := Vector3(x, wr, z + signf(z) * 0.115)
			_wheel_face(buf.call("hub"), hub, wr * 0.62, signf(z))
			_wheel_face(buf.call("trim"), hub + Vector3(0, 0, signf(z) * 0.002), wr * 0.48, signf(z))
			_wheel_spokes(buf.call("hub"), hub + Vector3(0, 0, signf(z) * 0.004), wr * 0.48, signf(z))
	var m := ArrayMesh.new()
	for mat in surf:
		var arrays := (surf[mat] as TreeMeshLibrary.Buf).arrays()
		arrays[Mesh.ARRAY_INDEX] = front_faces(arrays[Mesh.ARRAY_INDEX])
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		m.surface_set_material(m.get_surface_count() - 1, _material(str(mat)))
	_meshes[kind] = m
	return m

## Bevelled cross sections taper the nose, tail and shoulders.
static func _body(b: TreeMeshLibrary.Buf, length: float, wide: float, sill: float, height: float) -> void:
	var rings: Array = []
	for row in [[-0.5, 0.79, 0.66], [-0.47, 0.91, 0.87], [-0.36, 1.0, 1.0],
			[0.28, 1.0, 1.0], [0.43, 0.94, 0.87], [0.5, 0.80, 0.62]]:
		var x: float = length * row[0]
		var w: float = wide * 0.5 * row[1]
		var top: float = sill + height * row[2]
		rings.append([Vector3(x, sill, -w * 0.86), Vector3(x, sill + height * 0.16, -w),
			Vector3(x, top - height * 0.16, -w), Vector3(x, top, -w * 0.86),
			Vector3(x, top, w * 0.86), Vector3(x, top - height * 0.16, w),
			Vector3(x, sill + height * 0.16, w), Vector3(x, sill, w * 0.86)])
	var centre := Vector3(0, sill + height * 0.5, 0)
	for i in rings.size() - 1:
		for j in 8:
			var corners := [rings[i][j], rings[i + 1][j], rings[i + 1][(j + 1) % 8], rings[i][(j + 1) % 8]]
			_smooth_body_face(b, corners, centre, length, height, wide)
	for i in [0, rings.size() - 1]:
		var ring: Array = rings[i]
		var cap := Vector3((ring[0] as Vector3).x, sill + height * 0.4, 0)
		for j in 8:
			_face(b, [cap, ring[j], ring[(j + 1) % 8], cap], centre)

static func _smooth_body_face(b: TreeMeshLibrary.Buf, corners: Array, centre: Vector3,
		length: float, height: float, wide: float) -> void:
	var normal: Vector3 = (corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized()
	var mid: Vector3 = (corners[0] + corners[1] + corners[2] + corners[3]) * 0.25
	if normal.dot(mid - centre) < 0.0:
		corners.reverse()
		normal = -normal
	var normals: Array = []
	for point in corners:
		var p: Vector3 = point
		var end := clampf((absf(p.x) / length - 0.32) / 0.18, 0.0, 1.0)
		var rounded := Vector3(signf(p.x) * end * 0.7, (p.y - centre.y) / height * 1.3,
			p.z / wide * 1.5).normalized()
		normals.append((normal * 0.35 + rounded * 0.65).normalized())
	TreeMeshLibrary._card(b, corners, normals, [1.0, 1.0, 1.0, 1.0])

static func _wheel_face(b: TreeMeshLibrary.Buf, centre: Vector3, radius: float, side: float) -> void:
	for i in 20:
		var a := TAU * float(i) / 20.0
		var c := TAU * float(i + 1) / 20.0
		var p := centre + Vector3(cos(a) * radius, sin(a) * radius, 0)
		var q := centre + Vector3(cos(c) * radius, sin(c) * radius, 0)
		_face(b, [centre, p, q, centre], centre - Vector3(0, 0, side))

static func _wheel_arch(b: TreeMeshLibrary.Buf, centre: Vector3, radius: float, side: float) -> void:
	for i in 10:
		var a := PI * float(i) / 10.0
		var c := PI * float(i + 1) / 10.0
		var p := Vector3(cos(a), sin(a), 0)
		var q := Vector3(cos(c), sin(c), 0)
		_face(b, [centre + p * radius, centre + q * radius, centre + q * (radius + 0.035),
			centre + p * (radius + 0.035)], centre - Vector3(0, 0, side))

static func _wheel_spokes(b: TreeMeshLibrary.Buf, centre: Vector3, radius: float, side: float) -> void:
	for i in 5:
		var a := TAU * float(i) / 5.0
		var dir := Vector3(cos(a), sin(a), 0)
		var across := Vector3(-dir.y, dir.x, 0) * radius * 0.12
		_face(b, [centre + dir * radius * 0.16 - across, centre + dir * radius - across * 0.55,
			centre + dir * radius + across * 0.55, centre + dir * radius * 0.16 + across],
			centre - Vector3(0, 0, side))
	_wheel_face(b, centre, radius * 0.22, side)

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

## One flat quad facing away from `centre` (winding and normal both).
static func _face(b: TreeMeshLibrary.Buf, c: Array, centre: Vector3) -> void:
	var p0: Vector3 = c[0]
	var n := ((c[1] as Vector3) - p0).cross((c[2] as Vector3) - p0).normalized()
	var mid := (p0 + (c[1] as Vector3) + (c[2] as Vector3) + (c[3] as Vector3)) * 0.25
	if n.dot(mid - centre) < 0.0:
		c = [c[3], c[2], c[1], c[0]]
		n = -n
	TreeMeshLibrary._card(b, c, [n, n, n, n], [1.0, 1.0, 1.0, 1.0])

static func _material(name: String) -> Material:
	var m := StandardMaterial3D.new()
	match name:
		"body":
			# Paint is a dielectric: a metallic body mirrored the sky and
			# read as a glass case.
			m.albedo_color = Color.WHITE
			m.vertex_color_use_as_albedo = true  # the instance colour
			m.roughness = 0.38
		"glass":
			# Tinted glass: dark, with a soft, weak sky reflection so the
			# window band still reads at a grazing look.
			m.albedo_color = Color(0.075, 0.105, 0.13)
			m.roughness = 0.18
			m.metallic_specular = 0.25
		"trim":
			m.albedo_color = Color(0.05, 0.05, 0.05)
			m.roughness = 0.6
		"headlight":
			m.albedo_color = Color(0.78, 0.82, 0.82)
			m.roughness = 0.25
		"taillight":
			m.albedo_color = Color(0.48, 0.025, 0.02)
			m.roughness = 0.3
		"hub":
			m.albedo_color = Color(0.48, 0.50, 0.51)
			m.metallic = 0.5
			m.roughness = 0.4
		"tyre":
			m.albedo_color = Color(0.03, 0.03, 0.03)
			m.roughness = 0.9
	return StreetSnow.material(m) if name == "body" else m

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
