class_name LandmarkAfhMorocco
extends RefCounted

## Two Moroccan monuments in true metres: the unfinished Hassan Tower
## of Rabat with its field of column stumps, and the rammed-earth ksar of
## Ait Benhaddou climbing its hill. The Koutoubia is LandmarkAfhKoutoubia.

# --- Hassan Tower, Rabat ---

## Origin at the foot of the tower in the north wall of the unfinished
## Almohad mosque; the qibla points south (+Z). The 44 m red sandstone
## tower (16 m square, six ramp storeys, broken top) and, south of it,
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

## The 16 m square shaft to its unfinished 44 m top. Each face is framed
## by plain margins and composed differently, as on the real tower: the
## horseshoe windows of the ramp storeys up the middle and sides, a
## register of large polylobed blind arches in alfiz frames on engaged
## columns, and a sebka lattice of interlaced lozenges filling the upper
## part; a moulded band runs under the broken parapet.
static func _hassan_body(lm: LandmarkMesh) -> void:
	lm.box("Tower", Vector3(0, 21.5, 0), Vector3(16, 43.0, 16))
	lm.box("Trim", Vector3(0, 0.5, 0), Vector3(16.8, 1.0, 16.8))
	lm.box("Trim", Vector3(0, 41.3, 0), Vector3(16.5, 1.0, 16.5))
	lm.box("Trim", Vector3(0, 40.4, 0), Vector3(16.3, 0.5, 16.3))
	var faces: Array[Vector3] = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for f in 4:
		var out: Vector3 = faces[f]
		var right := Vector3.UP.cross(out).normalized()
		var c := out * 8.0
		for s in [-1.0, 1.0]:
			lm.beam("Trim", c + right * 7.4 * float(s) + out * 0.1 + Vector3(0, 1.0, 0),
				c + right * 7.4 * float(s) + out * 0.1 + Vector3(0, 40.2, 0), 0.2, 1.2, out)
		# Ramp-storey windows: the middle line on every face, the outer
		# lines on alternate storeys.
		for k in 4:
			var y := 5.0 + 4.6 * float(k)
			var us: Array[float] = [0.0]
			if (f + k) % 2 == 1:
				us = [-4.4, 0.0, 4.4]
			for u in us:
				var p: Vector3 = c + right * u + Vector3(0, y, 0)
				LandmarkAfhDetail.niche(lm, "Trim", "Dark", p, out, 1.1, 2.4, "horseshoe", 0.26, 0.2)
				LandmarkAfhDetail.alfiz(lm, "Trim", p - Vector3(0, 0.3, 0), out, 2.1, 3.1, 0.18, 0.08)
		# Blind polylobed arches on engaged columns, two or three per face.
		var na := 3 if f % 2 == 0 else 2
		var w := 3.6 if na == 3 else 5.4
		for i in na:
			var u := (float(i) - float(na - 1) * 0.5) * (w + 1.0)
			var p := c + right * u + Vector3(0, 23.6, 0)
			LandmarkAfhDetail.niche(lm, "Trim", "Dark", p, out, w, 5.6, "lobed", 0.34, 0.24, false, 7)
			LandmarkAfhDetail.alfiz(lm, "Trim", p - Vector3(0, 0.2, 0), out, w + 1.0, 6.3, 0.26, 0.12)
			for s in [-1.0, 1.0]:
				LandmarkAfhDetail.drum_column(lm, "Trim", p + right * (w * 0.5 + 0.12) * float(s) + out * 0.2,
					0.2, 3.1, 1, 8)
		# Sebka net over the upper register.
		LandmarkAfhDetail.sebka(lm, "Trim", "Dark", c + Vector3(0, 31.0, 0), out, 12.4, 8.6,
			5 if f % 2 == 0 else 4, 3, 0.32, 0.22)
	LandmarkAfhDetail.niche(lm, "Trim", "Dark", Vector3(0, 0, 8), Vector3(0, 0, 1), 3.0, 4.8, "horseshoe",
		0.45, 0.32, false)
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

## About 350 column stumps of stacked stone drums on a 7.25 x 6.3 m grid
## across the prayer hall and the side colonnades; the sahn beside the
## tower stays open. Most have been set up again to a few drums.
static func _hassan_columns(lm: LandmarkMesh) -> void:
	for i in 25:
		var x := -87.0 + 7.25 * float(i)
		for j in 19:
			var z := 16.0 + 6.3 * float(j)
			if (absf(x) < 45.0 and z < 50.0) or LandmarkAfhParts.hash01(i, j) < 0.14:
				continue
			var h := 1.2 + 3.0 * LandmarkAfhParts.hash01(j + 31, i)
			var drums := clampi(int(h / 0.75), 2, 5)
			LandmarkAfhDetail.drum_column(lm, "Column", Vector3(x, 0, z), 0.56, h, drums, 10, false)
			lm.lathe("Column", Vector3(x, 0, z), PackedVector2Array([Vector2(0.72, 0), Vector2(0.62, 0.12)]),
				10, 1.0, 1.0, 0.0, false, false)

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

## The fortified rammed-earth and adobe village (ighrem) on its hillside
## above the Ounila, facing the river to the south (+Z): about 80
## stacked clay houses with parapeted roof terraces, stepped merlon
## horns and small framed windows, the tall towered houses (tighremt)
## with decorated corner towers, inside a crenellated wall with eight
## corner towers banded with zigzags in their upper parts, a gate between
## two low towers, and the ruined agadir (granary fort) on the crest.
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
			_ait_house_top(lm, Vector3(x, top, z), w, d, h > 7.6, ix * 31 + iz)
			# Small framed windows high on the valley side, slits lower down.
			var face := Vector3(x, gy, z + d * 0.5)
			for u in [-w * 0.25, w * 0.25]:
				LandmarkAfhDetail.niche(lm, "Decor", "Dark", face + Vector3(float(u), 3.6, 0), Vector3(0, 0, 1),
					0.6, 0.8, "rect", 0.14, 0.1, true)
			LandmarkAfhDetail.niche(lm, "Earth", "Dark", face + Vector3(0, 1.4, 0), Vector3(0, 0, 1), 0.25, 0.9,
				"rect", 0.1, 0.08, false)
			if h > 7.2:
				LandmarkAfhDetail.niche(lm, "Decor", "Dark", face + Vector3(0, 6.0, 0), Vector3(0, 0, 1), 0.5, 0.7,
					"rect", 0.12, 0.1, true)
			var side := Vector3(x + w * 0.5, gy, z)
			LandmarkAfhDetail.niche(lm, "Decor", "Dark", side + Vector3(0, 3.8, 0), Vector3(1, 0, 0), 0.5, 0.7,
				"rect", 0.12, 0.1, true)

## Roof terrace of a house whose roof centre is `c`: a parapet with
## stepped merlon horns at the corners, or for a tighremt (fortified
## house) four tapering corner towers with zigzag and blind-arch work in
## their upper parts and merlon crowns.
static func _ait_house_top(lm: LandmarkMesh, c: Vector3, w: float, d: float, towered: bool, seed: int) -> void:
	var hx := w * 0.5
	var hz := d * 0.5
	for s in [-1.0, 1.0]:
		lm.box("Earth", c + Vector3(0, 0.3, s * (hz - 0.15)), Vector3(w, 0.6, 0.3), Basis(), 0.0)
		lm.box("Earth", c + Vector3(s * (hx - 0.15), 0.3, 0), Vector3(0.3, 0.6, d - 0.6), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := c + Vector3(sx * (hx - 0.6), 0, sz * (hz - 0.6))
			if towered:
				var th := 2.6 + 1.2 * LandmarkAfhParts.hash01(seed, int(sx + 2.0 * sz + 5.0))
				var base := corner - Vector3(0, 2.0, 0)
				lm.spire("Earth", base, 0.95, th + 2.0, 0.75)
				var out_x := Vector3(sx, 0, 0)
				var out_z := Vector3(0, 0, sz)
				var y := c.y + th - 1.5
				LandmarkAfhParts.zigzag(lm, "Decor", corner + out_z * 0.78, out_z, 0.7, y, 0.6, 3)
				LandmarkAfhParts.zigzag(lm, "Decor", corner + out_x * 0.78, out_x, 0.7, y, 0.6, 3)
				LandmarkAfhDetail.niche(lm, "Decor", "Dark", Vector3(corner.x, y - 1.3, corner.z) + out_z * 0.8,
					out_z, 0.35, 0.9, "pointed", 0.1, 0.08, false)
				var tc := corner + Vector3(0, th, 0)
				lm.box("Earth", tc + Vector3(0, 0.15, 0), Vector3(1.8, 0.3, 1.8), Basis(), 0.0)
				for e in 4:
					var rot := Basis(Vector3.UP, PI * 0.5 * float(e))
					var m: Vector3 = tc + rot * Vector3(0.65, 0.3, 0.65)
					LandmarkAfhDetail.stepped_merlon(lm, "Earth", m, rot * Vector3(1, 0, 0), 0.45, 0.7, 0.4)
			else:
				var m := c + Vector3(sx * (hx - 0.2), 0.6, sz * (hz - 0.2))
				LandmarkAfhDetail.stepped_merlon(lm, "Earth", m, Vector3(1, 0, 0), 0.5, 0.8, 0.4)

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
