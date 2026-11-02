class_name LandmarkAfhMorocco
extends RefCounted

## Three Moroccan monuments in true metres: the Koutoubia Mosque of
## Marrakesh (77 m sandstone minaret), the unfinished Hassan Tower of
## Rabat with its field of column stumps, and the rammed-earth ksar of
## Ait Benhaddou climbing its hill.

# --- Koutoubia Mosque ---

## Qibla (mihrab) wall to the south (+Z), origin at the centre of the
## 92 x 62 m mosque: the courtyard in the north part between two wings,
## the prayer hall across the south under a green-tile T of nave and
## transept, and the 77 m minaret at the north-east corner.
static func koutoubia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sandstone", LandmarkMaterials.pbr("stone", "#C58B69", 4.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D8B48C", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#2E7A55", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.glass("#2A1E16"))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#D9C6A4", 5.0))
	_koutoubia_hall(lm)
	_koutoubia_minaret(lm, Vector3(30, 0, -26))
	lm.commit(model)

static func _koutoubia_hall(lm: LandmarkMesh) -> void:
	lm.box("Court", Vector3(0, -0.4, 1), Vector3(104, 0.8, 72))
	lm.box("Plaster", Vector3(0, 5.5, 17), Vector3(92, 11, 30))
	lm.box("Plaster", Vector3(0, 4.0, -27), Vector3(46, 8, 6))
	for s in [-1.0, 1.0]:
		lm.box("Plaster", Vector3(s * 34.5, 4.5, -14), Vector3(23, 9, 32))
	# Green-tile roof: the central nave meets the transept along the qibla wall.
	lm.gable("Tile", Vector3(0, 11, 14.5), 10.0, 25.0, 3.0, Basis(), 0.2, "Plaster")
	lm.gable("Tile", Vector3(0, 11, 27), 10.0, 92.0, 3.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Plaster")
	# Arcades on the courtyard faces, small windows on the outer walls.
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Dark", Vector3(s * 23.0, 0, -11), Vector3(0, 0, 1),
			Vector3(-s, 0, 0), 0.0, 6, 4.0, 2.2, 4.8)
		SEuUtil.face_row(lm, "Dark", Vector3(s * 46.0, 0, -14), Vector3(0, 0, 1),
			Vector3(s, 0, 0), 5.0, 6, 5.0, 1.0, 2.2)
		SEuUtil.face_row(lm, "Dark", Vector3(s * 46.0, 0, 17), Vector3(0, 0, 1),
			Vector3(s, 0, 0), 5.5, 5, 5.5, 1.0, 2.4)
		SEuUtil.face_row(lm, "Dark", Vector3(s * 34.5, 0, -30), Vector3(1, 0, 0),
			Vector3(0, 0, -1), 4.0, 3, 6.0, 1.0, 2.2)
	SEuUtil.face_row(lm, "Dark", Vector3(0, 0, -24), Vector3(1, 0, 0), Vector3(0, 0, 1),
		0.0, 9, 4.8, 2.4, 5.0)
	SEuUtil.face_row(lm, "Dark", Vector3(0, 0, 2), Vector3(1, 0, 0), Vector3(0, 0, -1),
		0.0, 11, 4.0, 2.6, 6.8)
	SEuUtil.face_row(lm, "Dark", Vector3(0, 0, 32), Vector3(1, 0, 0), Vector3(0, 0, 1),
		5.5, 10, 8.5, 1.1, 2.4)
	# Plaster merlons crown every wall.
	var edges := [[-46, 32, 46, 32, 11], [-46, 2, -46, 32, 11], [46, 2, 46, 32, 11],
		[-46, 2, 46, 2, 11], [-46, -30, -46, 2, 9], [46, -30, 46, 2, 9],
		[-46, -30, -23, -30, 9], [23, -30, 46, -30, 9], [-23, -30, -23, 2, 9],
		[23, -30, 23, 2, 9], [-23, -30, 23, -30, 8], [-23, -24, 23, -24, 8]]
	for e in edges:
		SEuUtil.crenels(lm, "Plaster", Vector3(e[0], e[4], e[1]), Vector3(e[2], e[4], e[3]),
			0.8, 1.1, 0.7)

## 77 m minaret: 12.8 m square shaft of pink sandstone (55.7 m) with a
## different arrangement of windows and blind arches on every face, a
## green and white zellij frieze and merlons, then the 6.4 m lantern
## (to 69.5 m), its small dome and the finial of three copper balls.
static func _koutoubia_minaret(lm: LandmarkMesh, b: Vector3) -> void:
	var hw := 6.4
	lm.box("Sandstone", b + Vector3(0, 27.84, 0), Vector3(12.8, 55.68, 12.8))
	var faces: Array[Vector3] = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for f in 4:
		var out: Vector3 = faces[f]
		var c := b + out * hw
		for k in 5:
			var y := 11.0 + 7.6 * float(k)
			var us: Array[float] = [0.0]
			if (f + k) % 3 == 1:
				us = [-2.4, 2.4]
			elif (f + k) % 3 == 2:
				us = [-3.8, 0.0, 3.8]
			for u in us:
				LandmarkAfhParts.face_quad(lm, "Plaster", c, out, u, y - 0.4, 2.4, 4.2, 0.04)
				LandmarkAfhParts.face_quad(lm, "Dark", c, out, u, y, 1.2, 2.6, 0.09)
		# Row of four blind polylobed arches under the frieze.
		for u in [-4.5, -1.5, 1.5, 4.5]:
			LandmarkAfhParts.face_quad(lm, "Plaster", c, out, u, 46.6, 2.6, 3.6, 0.04)
			LandmarkAfhParts.face_quad(lm, "Dark", c, out, u, 47.1, 1.6, 2.4, 0.09)
		# Lantern windows.
		var lc := b + out * 3.2
		LandmarkAfhParts.face_quad(lm, "Plaster", lc, out, 0.0, 58.0, 4.4, 5.4, 0.04)
		LandmarkAfhParts.face_quad(lm, "Dark", lc, out, 0.0, 58.8, 2.4, 3.8, 0.09)
	LandmarkAfhParts.face_quad(lm, "Dark", b + Vector3(0, 0, -hw), Vector3(0, 0, -1), 0.0, 0.0,
		3.4, 5.0, 0.09)
	lm.box("Tile", b + Vector3(0, 53.0, 0), Vector3(13.0, 2.4, 13.0))
	LandmarkAfhParts.merlon_ring(lm, "Sandstone", b + Vector3(0, 55.68, 0), hw, hw, 0.9, 1.4)
	lm.box("Sandstone", b + Vector3(0, 62.59, 0), Vector3(6.4, 13.82, 6.4))
	lm.box("Tile", b + Vector3(0, 67.0, 0), Vector3(6.7, 1.2, 6.7))
	LandmarkAfhParts.merlon_ring(lm, "Sandstone", b + Vector3(0, 69.5, 0), 3.2, 3.2, 0.8, 1.1)
	LandmarkMaParts.dome(lm, "Tile", b + Vector3(0, 69.5, 0), 3.0, 2.8, 12, 0.35)
	# Finial: pole with three copper balls shrinking upward (2.0 m widest).
	LandmarkMaParts.needle(lm, "Gold", b + Vector3(0, 72.0, 0),
		PackedVector2Array([Vector2(0, 0.16), Vector2(5.0, 0.06)]), 6)
	LandmarkMaParts.sphere(lm, "Gold", b + Vector3(0, 73.0, 0), 1.0, 14, 8)
	LandmarkMaParts.sphere(lm, "Gold", b + Vector3(0, 74.8, 0), 0.75, 12, 6)
	LandmarkMaParts.sphere(lm, "Gold", b + Vector3(0, 76.0, 0), 0.55, 10, 6)

# --- Hassan Tower, Rabat ---

## Origin at the foot of the tower in the north wall of the unfinished
## Almohad mosque; the qibla points south (+Z). The 44 m red sandstone
## tower (16 m square, six panelled storeys, broken top) and, south of it,
## the 183 x 139 m ground plan with about 350 column stumps and the low
## remains of the perimeter wall.
static func hassan_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tower", LandmarkMaterials.pbr("stone", "#B26749", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CE9677", 3.0))
	lm.use("Column", LandmarkMaterials.pbr("limestone", "#D8C3B0", 2.5))
	lm.use("Dark", LandmarkMaterials.glass("#2A1A14"))
	lm.use("Rubble", LandmarkMaterials.pbr("rock", "#9A7A5E", 4.0))
	_hassan_body(lm)
	_hassan_columns(lm)
	_hassan_walls(lm)
	lm.commit(model)

static func _hassan_body(lm: LandmarkMesh) -> void:
	lm.box("Tower", Vector3(0, 21.5, 0), Vector3(16, 43.0, 16))
	lm.box("Trim", Vector3(0, 5.6, 0), Vector3(16.5, 0.8, 16.5))
	lm.box("Trim", Vector3(0, 41.3, 0), Vector3(16.5, 1.0, 16.5))
	var faces: Array[Vector3] = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for f in 4:
		var out: Vector3 = faces[f]
		var c := out * 8.0
		for k in 6:
			var y := 7.0 + 5.6 * float(k)
			var us: Array[float] = [-3.9, 3.9]
			var w := 6.0
			if (f + k) % 2 == 0:
				us = [-5.2, 0.0, 5.2]
				w = 3.8
			for u in us:
				LandmarkAfhParts.face_quad(lm, "Trim", c, out, u, y, w, 4.4, 0.05)
				LandmarkAfhParts.face_quad(lm, "Dark", c, out, u, y + 0.7, w * 0.5, 3.0, 0.1)
	LandmarkAfhParts.face_quad(lm, "Dark", Vector3(0, 0, 8), Vector3(0, 0, 1), 0.0, 0.0, 3.4, 5.0, 0.1)
	# Broken parapet: stumps of uneven height round the top edge.
	var n := 0
	for i in 5:
		var p := -7.0 + 3.5 * float(i)
		for s in [-1.0, 1.0]:
			var ha := 0.3 + 0.7 * LandmarkAfhParts.hash01(i, n)
			var hb := 0.3 + 0.7 * LandmarkAfhParts.hash01(n, i)
			lm.box("Tower", Vector3(p, 43.0 + ha * 0.5, s * 7.3), Vector3(2.2, ha, 1.4))
			lm.box("Tower", Vector3(s * 7.3, 43.0 + hb * 0.5, p), Vector3(1.4, hb, 2.2))
			n += 1

## Column stumps on a 7.25 x 6.3 m grid across the prayer hall and the
## side colonnades; the sahn beside the tower stays open.
static func _hassan_columns(lm: LandmarkMesh) -> void:
	for i in 25:
		var x := -87.0 + 7.25 * float(i)
		for j in 19:
			var z := 16.0 + 6.3 * float(j)
			if (absf(x) < 45.0 and z < 50.0) or LandmarkAfhParts.hash01(i, j) < 0.14:
				continue
			var h := 1.2 + 3.0 * LandmarkAfhParts.hash01(j + 31, i)
			lm.frustum("Column", Vector3(x, -0.3, z), 0.58, 0.52, h + 0.3, 8)

## Stubs of the perimeter wall (north z = -8, south z = 131, x = +-91.5).
static func _hassan_walls(lm: LandmarkMesh) -> void:
	for i in 20:
		var x := -91.5 + 9.15 * (float(i) + 0.5)
		for k in 2:
			var z := -8.0 if k == 0 else 131.0
			if (k == 0 and absf(x) < 10.0) or LandmarkAfhParts.hash01(i, k + 7) < 0.3:
				continue
			var h := 0.5 + 1.6 * LandmarkAfhParts.hash01(k + 3, i)
			lm.box("Rubble", Vector3(x, h * 0.5 - 0.2, z), Vector3(9.0, h + 0.4, 1.8))
	for j in 15:
		var z := -8.0 + 9.27 * (float(j) + 0.5)
		for k in 2:
			if LandmarkAfhParts.hash01(j + 50, k) < 0.3:
				continue
			var h := 0.5 + 1.6 * LandmarkAfhParts.hash01(j, k + 9)
			lm.box("Rubble", Vector3(-91.5 if k == 0 else 91.5, h * 0.5 - 0.2, z), Vector3(1.8, h + 0.4, 9.2))

# --- Ait Benhaddou ---

## Ground of the hill under the ksar: -3 m at the edges of the mesh, about
## 0 at the river-side toe (z = +43) and 33 m on the crest in the north.
static func _ait_ground(x: float, z: float) -> float:
	var u := clampf((60.0 - z) / 100.0, 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var fade := clampf((z + 85.0) / 20.0, 0.0, 1.0)
	var l := clampf((absf(x - 6.0) - 48.0) / 30.0, 0.0, 1.0)
	l = 1.0 - l * l * (3.0 - 2.0 * l)
	return -3.0 + 36.0 * u * fade * l

## The fortified rammed-earth village on its hillside, facing the river to
## the south (+Z): about 80 stacked clay houses inside a crenellated
## wall, eight corner towers with zigzag bands in their upper parts, a
## gate between two low towers, and the agadir (granary fort) on the crest.
static func ait_benhaddou(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Earth", LandmarkMaterials.pbr("render", "#B58459", 3.0))
	lm.use("Hill", LandmarkMaterials.pbr("rock", "#9C7653", 8.0))
	lm.use("Decor", LandmarkMaterials.pbr("render", "#DDBE92", 2.0))
	lm.use("Dark", LandmarkMaterials.glass("#2B1C12"))
	var rows: Array = []
	for j in 31:
		var row := PackedVector3Array()
		for i in 31:
			var x := -76.0 + 164.0 * float(i) / 30.0
			var z := -85.0 + 150.0 * float(j) / 30.0
			row.append(Vector3(x, _ait_ground(x, z), z))
		rows.append(row)
	lm.grid("Hill", rows, Vector3.UP)
	_ait_houses(lm)
	_ait_defences(lm)
	lm.commit(model)

static func _ait_houses(lm: LandmarkMesh) -> void:
	for iz in range(-5, 6):
		for ix in range(-6, 7):
			var x := 4.0 + 9.6 * float(ix) + 4.8 * float(iz % 2) + 2.0 * LandmarkAfhParts.hash01(ix, iz)
			var z := -6.0 + 9.2 * float(iz) + 2.0 * LandmarkAfhParts.hash01(iz + 9, ix)
			var d2 := pow((x - 4.0) / 58.0, 2.0) + pow((z + 6.0) / 48.0, 2.0)
			if d2 > 1.0 or z > 36.0 or x < -52.0 or x > 56.0 or (z < -36.0 and absf(x - 6.0) < 20.0):
				continue
			var w := 6.0 + 3.0 * LandmarkAfhParts.hash01(ix + 20, iz)
			var d := 5.5 + 2.5 * LandmarkAfhParts.hash01(ix, iz + 20)
			var h := 5.5 + 3.5 * LandmarkAfhParts.hash01(ix + 40, iz + 40)
			var gy := _ait_ground(x, z)
			var low := minf(minf(_ait_ground(x - w * 0.5, z + d * 0.5), _ait_ground(x + w * 0.5, z + d * 0.5)),
				minf(_ait_ground(x - w * 0.5, z - d * 0.5), _ait_ground(x + w * 0.5, z - d * 0.5))) - 2.0
			var top := gy + h
			lm.box("Earth", Vector3(x, (top + low) * 0.5, z), Vector3(w, top - low, d))
			var face := Vector3(x, 0, z + d * 0.5)
			LandmarkAfhParts.face_quad(lm, "Dark", face, Vector3(0, 0, 1), -w * 0.25, gy + 2.2, 0.7, 1.0, 0.04)
			LandmarkAfhParts.face_quad(lm, "Dark", face, Vector3(0, 0, 1), w * 0.25, gy + 2.2, 0.7, 1.0, 0.04)
			if h > 7.2:
				LandmarkAfhParts.face_quad(lm, "Dark", face, Vector3(0, 0, 1), 0.0, gy + 5.0, 0.6, 0.8, 0.04)

## Wall ring, corner and gate towers and the agadir on the crest.
static func _ait_defences(lm: LandmarkMesh) -> void:
	var ring := [Vector2(-58, 10), Vector2(-50, 36), Vector2(-14, 43), Vector2(-5, 43.5)]
	for i in ring.size() - 1:
		_ait_wall(lm, ring[i], ring[i + 1])
	var ring2 := [Vector2(5, 43.7), Vector2(16, 44), Vector2(54, 34), Vector2(62, 2),
		Vector2(48, -32), Vector2(24, -48), Vector2(-34, -44), Vector2(-58, -14), Vector2(-58, 10)]
	for i in ring2.size() - 1:
		_ait_wall(lm, ring2[i], ring2[i + 1])
	var towers := [[-58, 10, 15.0], [-50, 36, 14.0], [16, 44, 14.0], [54, 34, 15.0], [62, 2, 16.0],
		[48, -32, 14.5], [-34, -44, 14.5], [-58, -14, 15.0], [-5, 43.5, 10.0], [5, 43.7, 10.0]]
	for t in towers:
		_ait_tower(lm, float(t[0]), float(t[1]), float(t[2]), 3.4, 2.7)
	# Agadir on the crest: a walled granary with four corner towers.
	var c := Vector3(6, 0, -46)
	var gy := _ait_ground(c.x, c.z)
	lm.box("Earth", Vector3(c.x, gy + 2.0, c.z), Vector3(26, 10, 16))
	lm.box("Earth", Vector3(c.x, gy + 8.0, c.z), Vector3(14, 6, 9))
	LandmarkAfhParts.merlon_ring(lm, "Earth", Vector3(c.x, gy + 7.0, c.z), 13.0, 8.0, 0.9, 1.1)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_ait_tower(lm, c.x + sx * 13.0, c.z + sz * 8.0, 11.5, 3.0, 2.4)

static func _ait_wall(lm: LandmarkMesh, a: Vector2, b: Vector2) -> void:
	var seg_len := a.distance_to(b)
	var steps := maxi(int(seg_len / 3.5), 1)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(dir.x, dir.y))
	for s in steps:
		var p := a.lerp(b, (float(s) + 0.5) / float(steps))
		var gy := _ait_ground(p.x, p.y)
		var step_len := seg_len / float(steps) + 0.1
		lm.box("Earth", Vector3(p.x, gy + 2.0, p.y), Vector3(1.6, 8.0, step_len), basis)
		if s % 2 == 0:
			lm.box("Earth", Vector3(p.x, gy + 6.5, p.y), Vector3(1.6, 1.0, 1.2), basis)

## Tapering square tower `h` m above the ground at (x, z), half-width hw0
## at the base to hw1 at the top, two zigzag bands and a merlon crown.
static func _ait_tower(lm: LandmarkMesh, x: float, z: float, h: float, hw0: float, hw1: float) -> void:
	var gy := _ait_ground(x, z)
	var base := Vector3(x, gy - 2.0, z)
	lm.spire("Earth", base, hw0, h + 2.0, hw1)
	for fr in [0.55, 0.75]:
		var y := gy + h * float(fr)
		var hw := lerpf(hw0, hw1, (y - base.y) / (h + 2.0))
		for out in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			LandmarkAfhParts.zigzag(lm, "Decor", Vector3(x, 0, z) + (out as Vector3) * hw, out, hw, y, 1.4, 5)
	lm.box("Earth", Vector3(x, gy + h + 0.4, z), Vector3(hw1 * 2.0 + 0.8, 0.8, hw1 * 2.0 + 0.8))
	LandmarkAfhParts.merlon_ring(lm, "Earth", Vector3(x, gy + h + 0.8, z), hw1 + 0.4, hw1 + 0.4, 0.8, 1.0)
	LandmarkAfhParts.face_quad(lm, "Dark", Vector3(x, 0, z + hw0 - 0.3), Vector3(0, 0, 1), 0.0,
		gy + h * 0.3, 0.6, 1.2, 0.1)
