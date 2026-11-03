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
##   parks the same cars. One MultiMesh per kind.

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

## Cars [position, basis, kind, colour] for `data`'s streets, nearest first.
static func plan(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var cars: Array = []
	var centre := View360.spawn_xz(data)
	var r2 := pow(RADIUS_M * m2u, 2.0)
	var junc := RoadSurface.junctions(data)
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
				_kerb(cars, pts, (half - KERB_IN_M) * float(side[1]) * m2u, centre, r2, junc, ground, m2u)
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
		junc: Dictionary, ground: GroundTruth, m2u: float) -> void:
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
			var fw := dir if _hash(p.x, p.y, 3.1) < 0.97 else -dir
			# Parked with the traffic on its side: a left-kerb car faces back.
			if off > 0.0:
				fw = -fw
			var front := p + fw * length * 0.4
			var back := p - fw * length * 0.4
			var yf := ground.height_at_world(front.x, front.y)
			var yb := ground.height_at_world(back.x, back.y)
			var forward := Vector3(fw.x * length * 0.8, yf - yb, fw.y * length * 0.8).normalized()
			var side := forward.cross(Vector3.UP).normalized()
			var up := side.cross(forward).normalized()
			var basis := Basis(forward, up, forward.cross(up))
			var pos := Vector3(p.x, (yf + yb) * 0.5 + 0.04 * m2u, p.y)
			var colour: Color = PAINT[int(_hash(p.x, p.y, 4.9) * PAINT.size()) % PAINT.size()]
			cars.append([pos, basis.scaled(Vector3.ONE * m2u), kind, colour, d2])

static func _near_junction(p: Vector2, junc: Dictionary, cut: float) -> bool:
	var cell := Vector2i(floori(p.x / RoadSurface.JUNCTION_M), floori(p.y / RoadSurface.JUNCTION_M))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q in (junc.get(cell + Vector2i(dx, dz), PackedVector2Array()) as PackedVector2Array):
				if q.distance_to(p) < cut:
					return true
	return false

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
	for kind in ["sedan", "hatch", "wagon", "suv", "van"]:
		var list := cars.filter(func(c: Array) -> bool: return c[2] == kind)
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh(kind)
		mm.instance_count = list.size()
		for i in list.size():
			var c: Array = list[i]
			mm.set_instance_transform(i, Transform3D(c[1], c[0]))
			mm.set_instance_color(i, c[3])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Cars_%s" % kind
		mmi.multimesh = mm
		holder.add_child(mmi)
	root.add_child(holder)
	return cars.size()

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
	var cabin_x := -length * (0.06 if kind == "sedan" else 0.1)
	if kind == "van":
		cabin_l = length * 0.78
		cabin_x = -length * 0.08
	# Lower body, then the glasshouse: raked windscreen and rear window,
	# tumblehome sides (all glazed) under a painted roof. A box cabin read
	# as a white crate at street distance.
	_body(buf.call("body"), length, wide, sill, body_h)
	var y0 := sill + body_h
	var y1 := y0 + cabin_h
	var rake_f := cabin_h * (0.35 if kind == "van" else 1.1)
	var rake_b := cabin_h * (0.15 if kind in ["van", "suv", "hatch", "wagon"] else 0.7)
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
	_face(buf.call("body"), [hi[0], hi[1], hi[2], hi[3]], mid)
	# Painted centre pillars break up the side glass.
	for edge in [0, 2]:
		var a: Vector3 = lo[edge]
		var b: Vector3 = lo[(edge + 1) % 4]
		var c: Vector3 = hi[(edge + 1) % 4]
		var d: Vector3 = hi[edge]
		var offset := Vector3(0, 0, -0.006 if edge == 0 else 0.006)
		_face(buf.call("body"), [a.lerp(b, 0.48) + offset, a.lerp(b, 0.52) + offset,
			d.lerp(c, 0.52) + offset, d.lerp(c, 0.48) + offset], mid)
	for z in [-1.0, 1.0]:
		StreetProps._box(buf.call("trim"), Vector3(xf - cabin_l * 0.12, y0 + 0.09, z * (wide * 0.5 + 0.045)),
			Vector3(0.20, 0.10, 0.18))
	for z in [-wide * 0.34, wide * 0.34]:
		StreetProps._box(buf.call("headlight"), Vector3(length * 0.5 - 0.01, sill + body_h * 0.55, z),
			Vector3(0.045, 0.12, wide * 0.18))
		StreetProps._box(buf.call("taillight"), Vector3(-length * 0.5 + 0.01, sill + body_h * 0.60, z),
			Vector3(0.045, 0.14, wide * 0.16))
	StreetProps._box(buf.call("trim"), Vector3(length * 0.5 + 0.012, sill + body_h * 0.32, 0),
		Vector3(0.035, 0.14, wide * 0.48))
	# Bumpers and the dark sill between the wheels.
	StreetProps._box(buf.call("trim"), Vector3(0.0, sill + 0.08, 0.0), Vector3(length + 0.06, 0.16, wide + 0.02))
	var wr := 0.33 if kind != "hatch" else 0.31
	for x in [length * 0.32, -length * 0.32]:
		for z in [wide * 0.5 - 0.04, -wide * 0.5 + 0.04]:
			TreeMeshLibrary._tube(buf.call("tyre"), [Vector3(x, wr, z - 0.11), Vector3(x, wr, z + 0.11)],
				[wr, wr], 12, 1.0, 1.0)
			_wheel_face(buf.call("tyre"), Vector3(x, wr, z + signf(z) * 0.112), wr, signf(z))
			_wheel_face(buf.call("hub"), Vector3(x, wr, z + signf(z) * 0.115), wr * 0.55, signf(z))
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
	for row in [[-0.5, 0.88, 0.80], [-0.42, 1.0, 1.0], [0.36, 1.0, 1.0], [0.5, 0.86, 0.72]]:
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
			_face(b, [rings[i][j], rings[i + 1][j], rings[i + 1][(j + 1) % 8], rings[i][(j + 1) % 8]], centre)
	for i in [0, rings.size() - 1]:
		var ring: Array = rings[i]
		var cap := Vector3((ring[0] as Vector3).x, sill + height * 0.4, 0)
		for j in 8:
			_face(b, [cap, ring[j], ring[(j + 1) % 8], cap], centre)

static func _wheel_face(b: TreeMeshLibrary.Buf, centre: Vector3, radius: float, side: float) -> void:
	for i in 12:
		var a := TAU * float(i) / 12.0
		var c := TAU * float(i + 1) / 12.0
		var p := centre + Vector3(cos(a) * radius, sin(a) * radius, 0)
		var q := centre + Vector3(cos(c) * radius, sin(c) * radius, 0)
		_face(b, [centre, p, q, centre], centre - Vector3(0, 0, side))

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

static func _material(name: String) -> StandardMaterial3D:
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
	return m
