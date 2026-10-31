class_name BuildingDetail
extends RefCounted

## Kind- and region-specific roofline detail on top of the extruded mass:
## chimneys (northern/western houses), dormers (steep tiled roofs),
## rooftop plant and water tanks (flat roofs in hot or dense regions), and
## the tower of a place of worship — spire, bell tower, onion dome,
## minaret + dome, pagoda tiers or shikhara — so a Finnish church, a
## Cairo mosque and a Kyoto temple stop sharing one silhouette.
## Probabilities and tower kinds come from the building's ArchitectureStyle
## look; every roll is seeded by the building, so output is stable.
## All pieces of one building merge into a single MeshInstance3D with one
## surface per material (draw cost, not node count, is what the PRD §6
## budget counts).

## Detail radius in internal units (~250 m): beyond it a chimney is a
## sub-pixel speck. Towers of worship are exempt (skyline).
const NEAR_RADIUS := 250.0

static var _unit_arrays: Dictionary = {}
static var _mats: Dictionary = {}

## Merges unit primitives, transformed, into one multi-surface mesh.
class Batch extends RefCounted:
	var surfaces: Dictionary = {}

	func add(kind: String, xf: Transform3D, mat: Material) -> void:
		var src: Array = BuildingDetail._arrays(kind)
		if not surfaces.has(mat):
			surfaces[mat] = [PackedVector3Array(), PackedVector3Array(),
				PackedVector2Array(), PackedInt32Array()]
		var dst: Array = surfaces[mat]
		var verts: PackedVector3Array = dst[0]
		var normals: PackedVector3Array = dst[1]
		var uvs: PackedVector2Array = dst[2]
		var indices: PackedInt32Array = dst[3]
		var offset := verts.size()
		var nb := xf.basis.inverse().transposed()
		for v in (src[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			verts.append(xf * v)
		for n in (src[Mesh.ARRAY_NORMAL] as PackedVector3Array):
			normals.append((nb * n).normalized())
		uvs.append_array(src[Mesh.ARRAY_TEX_UV] as PackedVector2Array)
		for i in (src[Mesh.ARRAY_INDEX] as PackedInt32Array):
			indices.append(i + offset)

	func flush(root: Node3D) -> void:
		if surfaces.is_empty():
			return
		var mesh := ArrayMesh.new()
		for mat in surfaces:
			var s: Array = surfaces[mat]
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = s[0]
			arrays[Mesh.ARRAY_NORMAL] = s[1]
			arrays[Mesh.ARRAY_TEX_UV] = s[2]
			arrays[Mesh.ARRAY_TANGENT] = MassBatch.tangents(s[0], s[1], s[2], s[3])
			arrays[Mesh.ARRAY_INDEX] = s[3]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			MeshArrays.keep_surface(mesh, arrays)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat as Material)
		var mi := MeshInstance3D.new()
		mi.name = "Detail"
		mi.mesh = mesh
		root.add_child(mi)

## Cached arrays of a unit primitive (box, 4-sided cone/pyramid, 12-sided
## cylinder, sphere, hemisphere), all centred on the origin, 1 unit tall.
static func _arrays(kind: String) -> Array:
	if _unit_arrays.has(kind):
		return _unit_arrays[kind] as Array
	var mesh: PrimitiveMesh
	match kind:
		"box":
			var b := BoxMesh.new()
			b.size = Vector3.ONE
			mesh = b
		"pyramid":
			# Base square of side 1 with edges on the axes (a 4-segment
			# cylinder has its corners on them, so turn it 45°).
			mesh = _cyl(0.0, 0.70711, 4)
		"cyl":
			mesh = _cyl(0.5, 0.5, 12)
		"cone":
			mesh = _cyl(0.0, 0.5, 12)
		"hemi":
			var h := SphereMesh.new()
			h.radius = 0.5
			h.height = 0.5
			h.is_hemisphere = true
			h.radial_segments = 12
			h.rings = 4
			mesh = h
		_:
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 1.0
			sp.radial_segments = 12
			sp.rings = 6
			mesh = sp
	var arrays := mesh.get_mesh_arrays()
	if kind == "pyramid":
		var turn := Basis(Vector3.UP, PI / 4.0)
		var pv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var pn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in pv.size():
			pv[i] = turn * pv[i]
			pn[i] = turn * pn[i]
		arrays[Mesh.ARRAY_VERTEX] = pv
		arrays[Mesh.ARRAY_NORMAL] = pn
	_unit_arrays[kind] = arrays
	return arrays

static func _cyl(top_r: float, bottom_r: float, segments: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = 1.0
	c.radial_segments = segments
	return c

static func _flat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key] as Material
	var m: Material
	match key:
		"brick":
			# Unit-box UVs per face: ~1 repeat per chimney face keeps
			# brick courses at real size (8 drew 11 cm bricks).
			m = MaterialLibrary.pbr_material("brick", Color.WHITE, 1.0)
		"concrete":
			m = MaterialLibrary.pbr_material("concrete", Color.WHITE, 1.5)
		"ac":
			m = _flat(Color(0.62, 0.64, 0.66), 0.7)
		"tank":
			m = _flat(Color(0.16, 0.2, 0.28), 0.55)
		"gold":
			var g := _flat(Color(0.78, 0.62, 0.22), 0.35)
			g.metallic = 0.6
			m = g
		"lead":
			m = _flat(Color(0.42, 0.50, 0.48), 0.6)
		"cream":
			m = _flat(Color(0.93, 0.90, 0.82), 0.85)
		_:
			m = _flat(Color(0.5, 0.5, 0.5), 0.9)
	_mats[key] = m
	return m

## One building's detail. `top` is the eaves/roof-cap Y, `wall_h` the wall
## height, both in internal units; `near` gates everything except towers.
static func add(root: Node3D, ring: PackedVector2Array, top: float,
		wall_h: float, shape: String, roof_h: float, look: Dictionary,
		wall_mat: Material, roof_mat: Material, seed_v: float, near: bool,
		party: PackedByteArray = PackedByteArray(), gable_front: bool = false) -> void:
	var religious := str(look["kind"]) == "religious" and str(look["tower"]) != ""
	if not near and not religious:
		return
	var c := RingGeometry.interior_point(ring)
	if not RingGeometry.point_in_ring(c, ring):
		return
	var m2u := WorldScale.metres_to_units()
	var u := RingGeometry.dominant_axis(ring)
	var v := Vector2(-u.y, u.x)
	var lu := RingGeometry.half_extent(ring, c, u)
	var lv := RingGeometry.half_extent(ring, c, v)
	if lu < 1.2 * m2u or lv < 1.2 * m2u:
		return
	var batch := Batch.new()
	var basis := Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(v.x, 0, v.y))
	if religious:
		_tower(batch, ring, c, u, lu, lv, top, wall_h, basis, look, wall_mat, roof_mat)
	if near:
		var area_m2 := lu * lv * 4.0 / (m2u * m2u)
		var stacks := RooflineDetail.party_stacks(batch, ring, c, top, roof_h, party, look)
		if not stacks:
			_chimneys(batch, ring, c, u, v, lu, lv, top, roof_h, shape, basis, look, seed_v, area_m2)
		if not RooflineDetail.bay_dormers(batch, ring, top, roof_h, shape, party,
				gable_front, look, roof_mat, seed_v):
			_dormers(batch, c, u, v, lu, lv, top, roof_h, shape, basis, look, roof_mat, seed_v)
		if shape == "flat":
			_plant(batch, ring, c, u, v, lu, lv, top, basis, look, seed_v, area_m2)
	batch.flush(root)

## Roof surface height above the eaves at an offset from the centre, by
## shape (gable: slopes across v; hip/pyramid/dome: both ways).
static func _roof_y(shape: String, du: float, dv: float, lu: float, lv: float,
		roof_h: float) -> float:
	match shape:
		"gabled":
			return roof_h * clampf(1.0 - absf(dv) / lv, 0.0, 1.0)
		"flat":
			return 0.0
	return roof_h * clampf(1.0 - maxf(absf(du) / lu, absf(dv) / lv), 0.0, 1.0)

static func _xf(basis: Basis, origin: Vector3, scale: Vector3) -> Transform3D:
	return Transform3D(basis.scaled_local(scale), origin)

static func _at(c: Vector2, u: Vector2, v: Vector2, du: float, dv: float, y: float) -> Vector3:
	var p := c + u * du + v * dv
	return Vector3(p.x, y, p.y)

static func _chimneys(batch: Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float,
		roof_h: float, shape: String, basis: Basis, look: Dictionary,
		seed_v: float, area_m2: float) -> void:
	if ArchitectureStyle._h(seed_v, 21) >= float(look["chimney"]):
		return
	var m2u := WorldScale.metres_to_units()
	var count := 2 if area_m2 > 160.0 else 1
	var wall_mat := _mat("brick")
	for i in count:
		var du := lu * (0.45 - 0.9 * float(i) if count == 2 else 0.35)
		var dv := lv * 0.30 * (1.0 if ArchitectureStyle._h(seed_v, 22 + i) < 0.5 else -1.0)
		if not RingGeometry.point_in_ring(c + u * du + v * dv, ring):
			continue
		var surface := _roof_y(shape, du, dv, lu, lv, roof_h)
		var ridge := roof_h
		# Rises 0.9 m above the ridge line, buried 0.4 m into the roof.
		var h := (ridge - surface) + 0.9 * m2u + 0.4 * m2u
		batch.add("box", _xf(basis, _at(c, u, v, du, dv, top + surface - 0.4 * m2u + h * 0.5),
			Vector3(0.9 * m2u, h, 0.9 * m2u)), wall_mat)

static func _dormers(batch: Batch, c: Vector2, u: Vector2, v: Vector2,
		lu: float, lv: float, top: float, roof_h: float, shape: String,
		basis: Basis, look: Dictionary, roof_mat: Material, seed_v: float) -> void:
	if shape == "flat" or shape == "dome" or roof_h < 1.4 * WorldScale.metres_to_units():
		return
	if ArchitectureStyle._h(seed_v, 25) >= float(look["dormer"]):
		return
	var m2u := WorldScale.metres_to_units()
	var n := clampi(int(lu * 2.0 / m2u / 5.0), 1, 3)
	for i in n:
		var du := (float(i) - float(n - 1) / 2.0) * lu * 2.0 / float(n + 1) * 1.0
		var dv := lv * 0.45
		var surface := _roof_y(shape, du, dv, lu, lv, roof_h)
		batch.add("box", _xf(basis, _at(c, u, v, du, dv, top + surface + 0.35 * m2u),
			Vector3(1.1 * m2u, 1.5 * m2u, 1.0 * m2u)), roof_mat)

## Rooftop plant on flat roofs: AC units, stair/lift core, water tanks.
static func _plant(batch: Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float,
		basis: Basis, look: Dictionary, seed_v: float, area_m2: float) -> void:
	if area_m2 < 90.0 or ArchitectureStyle._h(seed_v, 31) >= float(look["equip"]):
		return
	var m2u := WorldScale.metres_to_units()
	var tanks := str(look["region"]) in ["middle_east", "south_asia", "sub_saharan_africa", "latin_america"]
	var n := 1 + int(ArchitectureStyle._h(seed_v, 32) * 3.0)
	for i in n:
		var du := (ArchitectureStyle._h(seed_v, 33 + i * 3) - 0.5) * lu * 1.2
		var dv := (ArchitectureStyle._h(seed_v, 34 + i * 3) - 0.5) * lv * 1.2
		if not RingGeometry.point_in_ring(c + u * du + v * dv, ring):
			continue
		var pick := ArchitectureStyle._h(seed_v, 35 + i * 3)
		if tanks and pick < 0.6:
			batch.add("cyl", _xf(basis, _at(c, u, v, du, dv, top + 0.9 * m2u),
				Vector3(1.6 * m2u, 1.8 * m2u, 1.6 * m2u)), _mat("tank"))
		elif pick < 0.8:
			batch.add("box", _xf(basis, _at(c, u, v, du, dv, top + 0.4 * m2u),
				Vector3(1.4 * m2u, 0.8 * m2u, 1.0 * m2u)), _mat("ac"))
		else:
			batch.add("box", _xf(basis, _at(c, u, v, du, dv, top + 1.2 * m2u),
				Vector3(2.6 * m2u, 2.4 * m2u, 2.6 * m2u)), _mat("concrete"))

## Place-of-worship tower at one end of the nave (or the centre when that
## end falls outside an irregular footprint).
static func _tower(batch: Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, lu: float, lv: float, top: float, wall_h: float,
		basis: Basis, look: Dictionary, wall_mat: Material,
		roof_mat: Material) -> void:
	var m2u := WorldScale.metres_to_units()
	var p := c + u * lu * 0.6
	if not RingGeometry.point_in_ring(p, ring):
		p = c
	var side := clampf(lv * 0.7, 2.0 * m2u, 4.5 * m2u)
	var base_y := top - wall_h
	var rise := maxf(wall_h * 0.6, 3.5 * m2u)
	var kind := str(look["tower"])
	var tx := func(y: float, sx: float, sy: float, sz: float) -> Transform3D:
		return _xf(basis, Vector3(p.x, y, p.y), Vector3(sx, sy, sz))
	match kind:
		"spire", "bell":
			var body_h := wall_h + rise
			batch.add("box", tx.call(base_y + body_h * 0.5, side, body_h, side), wall_mat)
			var cap_h := side * (2.4 if kind == "spire" else 0.9)
			batch.add("pyramid", tx.call(base_y + body_h + cap_h * 0.5, side * 1.5, cap_h, side * 1.5), roof_mat)
		"onion":
			var drum_h := wall_h + rise * 0.6
			batch.add("cyl", tx.call(base_y + drum_h * 0.5, side * 1.1, drum_h, side * 1.1), wall_mat)
			batch.add("sphere", tx.call(base_y + drum_h + side * 0.75, side * 1.5, side * 1.7, side * 1.5), _mat("gold"))
			batch.add("cone", tx.call(base_y + drum_h + side * 1.9, side * 0.3, side * 0.9, side * 0.3), _mat("gold"))
		"minaret":
			var h := maxf(wall_h * 2.2, 14.0 * m2u)
			var r := side * 0.32
			batch.add("cyl", tx.call(base_y + h * 0.5, r * 1.7, h, r * 1.7), _mat("cream"))
			batch.add("cyl", tx.call(base_y + h * 0.78, r * 3.2, 0.35 * m2u, r * 3.2), _mat("cream"))
			batch.add("cone", tx.call(base_y + h + r * 2.2, r * 2.4, r * 4.4, r * 2.4), _mat("lead"))
			# Prayer-hall dome on the main roof.
			batch.add("hemi", _xf(basis, Vector3(c.x, top, c.y),
				Vector3(lv * 1.5, lv * 1.5, lv * 1.5)), _mat("lead"))
		"pagoda":
			var tier_w := side * 1.6
			var y := base_y
			for t in 3:
				var tier_h := (wall_h + rise * 0.4) / 3.0
				batch.add("box", tx.call(y + tier_h * 0.5, tier_w, tier_h, tier_w), wall_mat)
				batch.add("pyramid", tx.call(y + tier_h + tier_h * 0.28, tier_w * 1.9, tier_h * 0.55, tier_w * 1.9), roof_mat)
				y += tier_h + tier_h * 0.4
				tier_w *= 0.78
			batch.add("cone", tx.call(y + side * 0.6, side * 0.12, side * 1.4, side * 0.12), _mat("gold"))
		"shikhara":
			var sh := wall_h + rise * 1.1
			batch.add("pyramid", tx.call(base_y + sh * 0.5, side * 2.2, sh, side * 2.2), wall_mat)
			batch.add("sphere", tx.call(base_y + sh + side * 0.25, side * 0.5, side * 0.5, side * 0.5), _mat("gold"))
