class_name LandmarkBuilder
extends RefCounted

## Procedural, on-the-fly landmark models (no downloaded assets):
## each registry type from LocationData.landmarks() gets a low-poly
## silhouette built from primitives at world scale (1 unit = 4 m),
## recognisable at panorama distance — brick cathedral with a single
## tall spire for Turku, lattice tower for the Eiffel, shells for the
## Sydney Opera House, and so on. Root sits at ground level (y=0);
## TerrainBuilder positions it at the landmark's real bearing.

static func _mat(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func _add(parent: Node, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	return mi

static func _box(root: Node3D, pos: Vector3, scl: Vector3, mat: Material) -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var mi := _add(root, box, mat)
	mi.position = pos
	mi.scale = scl

static func _cyl(top_r: float, bottom_r: float, height: float, segments: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = height
	c.radial_segments = segments
	return c

static func _part(root: Node3D, mesh: Mesh, mat: Material, pos: Vector3,
		scl: Vector3 = Vector3.ONE, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := _add(root, mesh, mat)
	mi.position = pos
	mi.scale = scl
	mi.rotation.y = rot_y
	return mi

## Steep pitched roof / spire base: a 4-sided tapered box, as in
## TerrainBuilder._mansard.
static func _roof(root: Node3D, pos: Vector3, size_x: float, size_z: float,
		height: float, mat: Material) -> void:
	var mi := _add(root, _cyl(0.45, 1.0, 1.0, 4), mat)
	mi.rotation.y = PI / 4.0
	mi.position = pos + Vector3(0, height / 2.0, 0)
	mi.scale = Vector3(size_x * 0.50, height, size_z * 0.50)

static func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var mi := _add(parent, _cyl(radius * 0.8, radius, 1.0, 6), mat)
	var dir := to - from
	var length := dir.length()
	var y_axis := dir / length
	var x_axis := Vector3.UP.cross(y_axis).normalized()
	if x_axis.length() < 0.01:
		x_axis = Vector3.RIGHT
	var z_axis := x_axis.cross(y_axis).normalized()
	x_axis = y_axis.cross(z_axis).normalized()
	mi.transform = Transform3D(
		Basis(x_axis * radius, y_axis * length, z_axis * radius), (from + to) / 2.0)

static func build(type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Landmark_%s" % type
	match type:
		"eiffel": _eiffel(root)
		"tokyo": _tokyo(root)
		"turku_cathedral": _turku_cathedral(root)
		"helsinki_cathedral": _helsinki_cathedral(root)
		"big_ben": _big_ben(root)
		"colosseum": _colosseum(root)
		"sagrada": _sagrada(root)
		"pyramid": _pyramid(root)
		"statue_liberty": _statue_liberty(root)
		"sydney_opera": _sydney_opera(root)
		_: _generic_tower(root)
	return root

# --- Towers already proven in the skyline ---

static func _eiffel(root: Node3D) -> void:
	# Four legs converging through two platforms to a spire, at
	# world scale (330 m tower -> ~80 units, base ~90 m -> ±9).
	var iron := _mat(Color(0.38, 0.29, 0.20), 0.8)
	var base_corners: Array[Vector3] = [Vector3(-9, 0, -9), Vector3(9, 0, -9),
		Vector3(-9, 0, 9), Vector3(9, 0, 9)]
	var mid_corners: Array[Vector3] = []
	var top_corners: Array[Vector3] = []
	for c in base_corners:
		mid_corners.append(Vector3(c.x * 0.46, 15.0, c.z * 0.46))
		top_corners.append(Vector3(c.x * 0.22, 30.0, c.z * 0.22))
	for i in 4:
		_beam(root, base_corners[i], mid_corners[i], 0.85, iron)
		_beam(root, mid_corners[i], top_corners[i], 0.55, iron)
	_box(root, Vector3(0, 15.5, 0), Vector3(10.5, 1.2, 10.5), iron)
	_box(root, Vector3(0, 30.5, 0), Vector3(5.6, 1.1, 5.6), iron)
	var shaft := _part(root, _cyl(0.7, 2.0, 34.0, 8), iron, Vector3(0, 48.0, 0))
	shaft.rotation.y = PI / 4.0
	_part(root, _cyl(0.10, 0.6, 15.0), iron, Vector3(0, 72.0, 0))

static func _tokyo(root: Node3D) -> void:
	# Tokyo Tower: four legs to two decks, then a red/white shaft
	# and antenna (333 m -> ~80 units, same scale as the Eiffel).
	var red := _mat(Color(0.72, 0.24, 0.14), 0.75)
	var white := _mat(Color(0.92, 0.90, 0.86), 0.75)
	var t_base: Array[Vector3] = [Vector3(-7, 0, -7), Vector3(7, 0, -7),
		Vector3(-7, 0, 7), Vector3(7, 0, 7)]
	for i in 4:
		var c := t_base[i]
		_beam(root, c, Vector3(c.x * 0.45, 15.0, c.z * 0.45), 0.65, red)
		_beam(root, Vector3(c.x * 0.45, 15.0, c.z * 0.45),
			Vector3(c.x * 0.20, 30.0, c.z * 0.20), 0.45, white)
	_box(root, Vector3(0, 15.5, 0), Vector3(8.6, 1.2, 8.6), red)
	_box(root, Vector3(0, 30.5, 0), Vector3(4.8, 1.1, 4.8), white)
	var seg_cols: Array = [red, white, red]
	for s in 3:
		_part(root, _cyl(1.5 - s * 0.35, 1.85 - s * 0.35, 11.0, 8),
			seg_cols[s], Vector3(0, 36.5 + s * 11.0, 0))
	_part(root, _cyl(0.08, 0.35, 14.0, 6), red, Vector3(0, 71.0, 0))

# --- Cathedrals ---

static func _turku_cathedral(root: Node3D) -> void:
	# Turku Cathedral (Turun tuomiokirkko, 60.4524, 22.2781): Finland's
	# medieval brick basilica — long nave, steep roof, and ONE tall
	# west tower with an octagonal spire (85 m -> ~21 units overall).
	# That single tower over a brick nave is the skyline signature.
	var brick := _mat(Color(0.52, 0.31, 0.22), 0.95)
	var brick_dark := _mat(Color(0.44, 0.26, 0.19), 0.95)
	var slate := _mat(Color(0.23, 0.25, 0.29), 0.85)
	var dark := _mat(Color(0.16, 0.15, 0.16), 0.7)
	var gold := _mat(Color(0.85, 0.65, 0.25), 0.4)
	# Nave along X, tower at the west (-X) end.
	_box(root, Vector3(3, 2.5, 0), Vector3(22, 5, 7), brick)
	_roof(root, Vector3(3, 5.0, 0), 22, 7, 3.2, slate)
	# Transept crossing near the east end.
	_box(root, Vector3(9, 2.5, 0), Vector3(5, 5, 10.5), brick)
	_roof(root, Vector3(9, 5.0, 0), 5, 10.5, 3.0, slate)
	# Tall narrow windows down both nave sides.
	for i in 6:
		var wx := -5.5 + float(i) * 3.4
		_box(root, Vector3(wx, 2.8, 3.56), Vector3(1.1, 3.2, 0.14), dark)
		_box(root, Vector3(wx, 2.8, -3.56), Vector3(1.1, 3.2, 0.14), dark)
	# Buttresses between the windows.
	for i in 5:
		var bx := -3.8 + float(i) * 3.4
		_box(root, Vector3(bx, 2.0, 3.75), Vector3(0.8, 4.0, 0.6), brick_dark)
		_box(root, Vector3(bx, 2.0, -3.75), Vector3(0.8, 4.0, 0.6), brick_dark)
	# The tower: shaft, belfry openings, corner pinnacles, spire.
	_box(root, Vector3(-10.5, 6.5, 0), Vector3(5.5, 13, 5.5), brick)
	_box(root, Vector3(-10.5, 10.5, 2.82), Vector3(1.3, 2.6, 0.14), dark)
	_box(root, Vector3(-10.5, 10.5, -2.82), Vector3(1.3, 2.6, 0.14), dark)
	_box(root, Vector3(-13.32, 10.5, 0), Vector3(0.14, 2.6, 1.3), dark)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_part(root, _cyl(0.05, 0.55, 2.6, 6), slate,
				Vector3(-10.5 + sx * 2.45, 14.2, sz * 2.45))
	_part(root, _cyl(0.12, 2.9, 7.5, 8), slate, Vector3(-10.5, 16.8, 0))
	_part(root, _cyl(0.05, 0.10, 2.2, 6), gold, Vector3(-10.5, 21.6, 0))
	var orb := SphereMesh.new()
	orb.radial_segments = 8
	orb.rings = 5
	orb.radius = 0.42
	orb.height = 0.84
	_part(root, orb, gold, Vector3(-10.5, 20.4, 0))

static func _helsinki_cathedral(root: Node3D) -> void:
	# Helsinki Cathedral: white cruciform nave, one large green central
	# dome and four small ones (62 m -> ~15 units).
	var white := _mat(Color(0.93, 0.92, 0.88), 0.9)
	var green := _mat(Color(0.25, 0.48, 0.40), 0.6)
	var gold := _mat(Color(0.85, 0.65, 0.25), 0.4)
	_box(root, Vector3(0, 3, 0), Vector3(16, 6, 7), white)
	_box(root, Vector3(0, 3, 0), Vector3(7, 6, 14), white)
	_roof(root, Vector3(0, 6.0, 0), 16, 7, 1.6, green)
	_part(root, _cyl(3.1, 3.4, 2.2, 12), white, Vector3(0, 7.6, 0))
	var dome := SphereMesh.new()
	dome.radial_segments = 12
	dome.rings = 6
	dome.radius = 3.2
	dome.height = 5.6
	_part(root, dome, green, Vector3(0, 10.6, 0))
	_part(root, _cyl(0.05, 0.12, 2.4, 6), gold, Vector3(0, 14.6, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var small := SphereMesh.new()
			small.radial_segments = 8
			small.rings = 5
			small.radius = 1.25
			small.height = 2.4
			_part(root, small, green, Vector3(sx * 5.4, 7.4, sz * 5.4))

static func _generic_tower(root: Node3D) -> void:
	var tower := _part(root, _cyl(1.7, 3.2, 30.0), _mat(Color(0.66, 0.63, 0.58), 0.9),
		Vector3(0, 15, 0))
	tower.position.y = 15
	_box(root, Vector3(0, 30.8, 0), Vector3(5.2, 1.4, 5.2), _mat(Color(0.42, 0.45, 0.50), 0.85))

# --- Other skyline icons ---

static func _big_ben(root: Node3D) -> void:
	# Elizabeth Tower (96 m -> ~24 units): stone clock tower, white
	# clock faces, dark spire, long low Parliament block beside it.
	var stone := _mat(Color(0.78, 0.70, 0.55), 0.9)
	var dark := _mat(Color(0.20, 0.22, 0.26), 0.8)
	var face := _mat(Color(0.94, 0.93, 0.88), 0.5)
	_box(root, Vector3(7, 3, 0), Vector3(14, 6, 4.5), stone)
	_roof(root, Vector3(7, 6.0, 0), 14, 4.5, 1.8, dark)
	_box(root, Vector3(-3, 9.5, 0), Vector3(4.2, 19, 4.2), stone)
	for i in 5:
		_box(root, Vector3(2.0 + float(i) * 2.6, 3.4, 2.32), Vector3(1.2, 3.4, 0.14), dark)
		_part(root, _cyl(0.04, 0.4, 1.8, 6), dark,
			Vector3(1.0 + float(i) * 3.0, 7.6, 1.8))
	_box(root, Vector3(-3, 16.5, 2.16), Vector3(2.6, 2.6, 0.14), face)
	_box(root, Vector3(-3, 16.5, -2.16), Vector3(2.6, 2.6, 0.14), face)
	_box(root, Vector3(-5.16, 16.5, 0), Vector3(0.14, 2.6, 2.6), face)
	_part(root, _cyl(0.08, 2.6, 5.5, 4), dark, Vector3(-3, 21.8, 0), Vector3.ONE, PI / 4.0)

static func _colosseum(root: Node3D) -> void:
	# Colosseum: elliptical tiered arena wall with arched openings and
	# a dark arena floor inside the broken rim (48 m -> 12 units).
	var stone := _mat(Color(0.76, 0.68, 0.54), 0.95)
	var dark := _mat(Color(0.30, 0.26, 0.20), 0.9)
	var wall := _part(root, _cyl(13.0, 13.5, 11.0, 24), stone, Vector3(0, 5.5, 0))
	wall.scale = Vector3(1.25, 1.0, 1.0)
	var arena := _part(root, _cyl(10.6, 10.6, 0.6, 24), dark, Vector3(0, 10.9, 0))
	arena.scale = Vector3(1.25, 1.0, 1.0)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var pos := Vector3(cos(a) * 16.6, 3.4, sin(a) * 13.3)
		_box(root, pos, Vector3(1.7, 3.6, 0.5), dark)
		var pos2 := Vector3(cos(a) * 16.6, 8.2, sin(a) * 13.3)
		_box(root, pos2, Vector3(1.7, 2.8, 0.5), dark)

static func _sagrada(root: Node3D) -> void:
	# Sagrada Familia: cluster of tapered stone spires with pointed
	# tips over a low nave (tallest spires ~170 m planned; the built
	# ones read as a forest of tapering towers).
	var stone := _mat(Color(0.72, 0.62, 0.48), 0.9)
	var tip := _mat(Color(0.55, 0.45, 0.33), 0.85)
	_box(root, Vector3(0, 3, 0), Vector3(16, 6, 9), stone)
	var heights: Array = [17.0, 20.0, 19.0, 16.0, 14.0, 15.0]
	for i in heights.size():
		var hx := -7.5 + float(i) * 3.0
		var h: float = heights[i]
		_part(root, _cyl(0.7, 1.5, h, 8), stone, Vector3(hx, h / 2.0, -2.5 if i % 2 == 0 else 2.5))
		_part(root, _cyl(0.05, 0.7, 3.0, 8), tip,
			Vector3(hx, h + 1.5, -2.5 if i % 2 == 0 else 2.5))

static func _pyramid(root: Node3D) -> void:
	# Giza: the Great Pyramid with Khafre's beside it (146 m -> ~30
	# units, slightly compressed so it stays inside the terrain).
	var sand := _mat(Color(0.78, 0.66, 0.45), 1.0)
	var sand_dark := _mat(Color(0.70, 0.58, 0.39), 1.0)
	var p1 := _part(root, _cyl(0.05, 21.0, 26.0, 4), sand, Vector3(-6, 13, 0))
	p1.rotation.y = PI / 4.0
	var p2 := _part(root, _cyl(0.05, 15.0, 18.0, 4), sand_dark, Vector3(16, 9, 10))
	p2.rotation.y = PI / 4.0
	var p3 := _part(root, _cyl(0.05, 10.0, 12.0, 4), sand, Vector3(24, 6, -8))
	p3.rotation.y = PI / 4.0
	# Weathered limestone cap on Khafre's pyramid, plus the Sphinx.
	_part(root, _cyl(0.05, 5.5, 5.0, 4), _mat(Color(0.88, 0.80, 0.62), 1.0),
		Vector3(16, 15.5, 10), Vector3.ONE, PI / 4.0)
	_box(root, Vector3(0, 0.4, 0), Vector3(52, 0.8, 40), sand_dark)
	_box(root, Vector3(-20, 1.5, 14), Vector3(9, 3, 3.2), sand_dark)
	_box(root, Vector3(-24.5, 3.6, 14), Vector3(2.6, 4.2, 2.8), sand)
	_box(root, Vector3(-24.5, 6.2, 14), Vector3(3.2, 1.2, 3.2), sand_dark)

static func _statue_liberty(root: Node3D) -> void:
	# Statue of Liberty (93 m with pedestal -> ~23 units): stone
	# pedestal, verdigris robe and crown, raised torch arm.
	var stone := _mat(Color(0.72, 0.66, 0.56), 0.9)
	var copper := _mat(Color(0.35, 0.66, 0.60), 0.7)
	var gold := _mat(Color(0.90, 0.70, 0.25), 0.35)
	_box(root, Vector3(0, 2.5, 0), Vector3(9, 5, 9), stone)
	_box(root, Vector3(0, 6.5, 0), Vector3(5.5, 3, 5.5), stone)
	_part(root, _cyl(1.1, 2.3, 8.0, 8), copper, Vector3(0, 12, 0))
	_part(root, _cyl(0.85, 1.1, 3.5, 8), copper, Vector3(0, 17.5, 0))
	var head := SphereMesh.new()
	head.radial_segments = 8
	head.rings = 5
	head.radius = 0.95
	head.height = 1.9
	_part(root, head, copper, Vector3(0, 20.1, 0))
	for i in 7:
		var a := -0.9 + float(i) * 0.3
		_part(root, _cyl(0.02, 0.09, 1.1, 4), copper,
			Vector3(sin(a) * 0.85, 21.2, -cos(a) * 0.3 + 0.25))
	_beam(root, Vector3(0.7, 18.6, 0), Vector3(2.6, 22.4, 0), 0.28, copper)
	var torch := SphereMesh.new()
	torch.radial_segments = 8
	torch.rings = 5
	torch.radius = 0.55
	torch.height = 1.1
	_part(root, torch, gold, Vector3(2.7, 22.9, 0))

static func _sydney_opera(root: Node3D) -> void:
	# Sydney Opera House: white shell sails rising from a podium at
	# the water's edge, largest shell ~67 m -> ~16 units.
	var shell_mat := _mat(Color(0.94, 0.92, 0.86), 0.65)
	var podium := _mat(Color(0.62, 0.55, 0.45), 0.95)
	_box(root, Vector3(0, 1, 0), Vector3(20, 2, 11), podium)
	# Glass walls under the shells and the smaller shell group behind.
	var glass := _mat(Color(0.35, 0.48, 0.55), 0.4)
	_box(root, Vector3(-1, 2.8, 0), Vector3(10, 1.8, 7), glass)
	_box(root, Vector3(7, 2.5, 0), Vector3(6, 1.4, 6), glass)
	_box(root, Vector3(-8, 2.4, 0), Vector3(4, 1.2, 5), glass)
	var sails: Array = [[-5.0, 7.5, 3.4], [-1.0, 9.5, 4.1], [3.5, 8.0, 3.6], [7.5, 5.5, 2.8],
		[-8.5, 4.5, 2.4], [10.5, 4.0, 2.2]]
	for s in sails:
		var shell := SphereMesh.new()
		shell.radial_segments = 10
		shell.rings = 6
		shell.radius = 1.0
		shell.height = 2.0
		var mi := _part(root, shell, shell_mat, Vector3(s[0], 2.0 + s[1] * 0.38, 0))
		mi.scale = Vector3(s[2], s[1] * 0.55, s[2] * 0.62)
		mi.rotation.z = -0.18
