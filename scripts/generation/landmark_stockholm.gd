class_name LandmarkStockholm
extends RefCounted

## Stockholm City Hall (Östberg, 1923) in true metres: the dark red
## brick block round its two courts — the open Borgargården to the west
## and the covered Blue Hall to the east — under verdigris copper roofs,
## the arcaded water front to Riddarfjärden (+Z, south), the slim NE
## turret with its copper lantern, and the 106 m tower at the south-east
## corner: brick shaft, belfry stage, copper lantern and spire carrying
## the three gilded crowns.

const TOP_M := 106.0
const SIZE := Vector2(116.0, 74.0)
const WALL_M := 26.0
const WING_M := 12.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7E3B2C", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#5E2C22", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#22292D"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D8CFBE", 3.0))
	var hx := SIZE.x * 0.5
	var hz := SIZE.y * 0.5
	# Perimeter wings [centre x, centre z, length x, depth z, height].
	var wings := [[0.0, -hz + WING_M * 0.5, SIZE.x, WING_M, WALL_M],
		[-hx + WING_M * 0.5, 0.0, WING_M, SIZE.y, WALL_M],
		[hx - WING_M * 0.5, 0.0, WING_M, SIZE.y, WALL_M],
		[8.0, 0.0, WING_M, SIZE.y, WALL_M + 2.0],
		[0.0, hz - 5.0, SIZE.x, 10.0, 15.0]]
	for w in wings:
		var c := Vector3(float(w[0]), 0, float(w[1]))
		var size := Vector3(float(w[2]), float(w[4]), float(w[3]))
		lm.box("Brick", c + Vector3(0, size.y * 0.5, 0), size)
		lm.box("Stone", c + Vector3(0, size.y - 0.3, 0), size + Vector3(0.4, 0.6 - size.y, 0.4))
		var along_x := size.x > size.z
		lm.gable("Copper", c + Vector3(0, size.y, 0), minf(size.x, size.z), maxf(size.x, size.z),
			minf(size.x, size.z) * 0.32, Basis(Vector3.UP, PI * 0.5) if along_x else Basis(), 0.5, "Brick")
	# The covered Blue Hall fills the eastern court.
	lm.box("Brick", Vector3(hx * 0.5 + 4.0, 11.0, 0), Vector3(hx - 2.0 * WING_M + 4.0, 22.0, SIZE.y - 2.0 * WING_M))
	lm.box("Copper", Vector3(hx * 0.5 + 4.0, 22.3, 0), Vector3(hx - 2.0 * WING_M + 4.0, 0.6, SIZE.y - 2.0 * WING_M))
	# Windows: three rows on the north front, one over the water arcade.
	for k in 26:
		var x := -hx + 3.0 + (SIZE.x - 6.0) * k / 25.0
		for row in 3:
			lm.box("Windows", Vector3(x, 6.0 + 6.5 * row, -hz - 0.1),
				Vector3(1.4, 3.2 if row < 2 else 2.4, 0.2))
		lm.box("Windows", Vector3(x, 10.5, hz + 0.1), Vector3(1.2, 2.6, 0.2))
	# Water-front arcade: dark openings and stone columns.
	for k in 14:
		var x := -hx + 6.0 + (SIZE.x - 30.0) * k / 13.0
		lm.box("BrickDark", Vector3(x, 3.0, hz + 0.1), Vector3(4.6, 6.0, 0.2))
		lm.lathe("Stone", Vector3(x + 3.0, 0, hz + 0.4), PackedVector2Array([Vector2(0.45, 0),
			Vector2(0.4, 6.0)]), 8)
	# NE turret with its copper lantern.
	var tc := Vector3(hx - 6.0, 0, -hz + 6.0)
	lm.box("Brick", tc + Vector3(0, 21.0, 0), Vector3(6.0, 42.0, 6.0))
	lm.frustum("Copper", tc + Vector3(0, 42.0, 0), 3.6, 2.4, 4.0, 8, PI / 8.0)
	lm.lathe("Copper", tc + Vector3(0, 46.0, 0), PackedVector2Array([Vector2(2.4, 0),
		Vector2(2.0, 1.6), Vector2(0.9, 3.4), Vector2(0.0, 7.0)]), 8)
	lm.frustum("Gilt", tc + Vector3(0, 53.0, 0), 0.3, 0.05, 1.6, 6)
	# The tower at the south-east corner by the water.
	var t := Vector3(hx - 9.0, 0, hz - 9.0)
	var shaft := 76.0
	lm.box("Brick", t + Vector3(0, shaft * 0.5, 0), Vector3(16.0, shaft, 16.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in 3:
			lm.box("BrickDark", t + r * Vector3(-4.5 + 4.5 * k, 46.0, 8.1), Vector3(1.6, 40.0, 0.2), r)
		lm.box("Windows", t + r * Vector3(0, 8.0, 8.05), Vector3(2.0, 5.0, 0.2), r)
	lm.box("Stone", t + Vector3(0, shaft + 0.5, 0), Vector3(17.6, 1.0, 17.6))
	# Belfry stage with tall arched openings and its gallery.
	lm.box("Brick", t + Vector3(0, shaft + 6.0, 0), Vector3(13.0, 10.0, 13.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in [-1.0, 1.0]:
			lm.box("BrickDark", t + r * Vector3(k * 3.0, shaft + 6.0, 6.55), Vector3(2.2, 7.0, 0.2), r)
		for k in [-1.0, 1.0]:
			lm.lathe("Copper", t + r * Vector3(k * 6.2, shaft + 11.0, 6.2), PackedVector2Array([
				Vector2(0.7, 0), Vector2(0.0, 2.6)]), 6)
	lm.box("Stone", t + Vector3(0, shaft + 11.2, 0), Vector3(14.2, 0.6, 14.2))
	# Copper lantern, ribbed in gilt, and the spire.
	var ly := shaft + 11.5
	lm.lathe("Copper", t + Vector3(0, ly, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(5.4, 3.0),
		Vector2(3.6, 5.0), Vector2(3.2, 8.0), Vector2(1.6, 10.0), Vector2(0.7, 13.5)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * k
		lm.beam("Gilt", t + Vector3(cos(a) * 6.05, ly, sin(a) * 6.05),
			t + Vector3(cos(a) * 3.65, ly + 5.0, sin(a) * 3.65), 0.25, 0.15)
	# The three crowns stacked on the spire tip.
	var cy := ly + 13.5
	lm.frustum("Gilt", t + Vector3(0, cy, 0), 0.25, 0.25, TOP_M - cy, 6)
	for k in 3:
		var a := TAU * k / 3.0
		var off := Vector3(cos(a), 0, sin(a)) * 0.9
		_crown(lm, t + off + Vector3(0, TOP_M - 2.4, 0), 0.7)
	lm.commit(model)

## A small open crown: a gilt band with four points, r in radius.
static func _crown(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	lm.frustum("Gilt", base, r, r * 1.15, r * 0.7, 12)
	for k in 4:
		var a := TAU * k / 4.0
		lm.frustum("Gilt", base + Vector3(cos(a) * r, r * 0.7, sin(a) * r), r * 0.2, 0.0, r * 0.8, 4)

## Riddarholmen Church (Riddarholmskyrkan, late 13th century) in true
## metres, the nave along +X (east): a red-brown Gothic brick nave under
## a steep copper roof, lower aisles lined with burial chapels, the two
## copper-domed royal chapels (the Caroline to the north, the Gustavian
## to the south), a polygonal choir at the east end, and at the west end
## the square brick tower with its belfry stage under the cast-iron
## openwork spire of 1841 (after the 1835 lightning fire), a lattice of
## X-braced faces tapering to the 90 m tip.
const RIDDARHOLMEN_TOP_M := 90.0

static func riddarholmen(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7A3A2A", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#1E2427"))
	lm.use("Iron", LandmarkMaterials.paint("#2A2C2D", 0.5, 0.7))
	lm.use("Gilt", LandmarkMaterials.gold())
	var along := Basis(Vector3.UP, PI * 0.5)  # gable ridges run along X
	# Nave, aisles with their chapels, steep copper roofs.
	lm.box("Brick", Vector3(4, 9, 0), Vector3(48, 18, 13))
	lm.gable("Copper", Vector3(4, 18, 0), 13, 48, 8.5, along, 0.6, "Brick")
	for sgn in [-1.0, 1.0]:
		lm.box("Brick", Vector3(4, 5.5, 9.5 * sgn), Vector3(40, 11, 6))
		lm.box("Copper", Vector3(4, 11.3, 9.5 * sgn), Vector3(41, 0.6, 6.6))
		# Royal chapels: square brick drums under copper domes.
		var cc := Vector3(10, 0, 15.2 * sgn)
		lm.box("Brick", cc + Vector3(0, 6.5, 0), Vector3(9.5, 13, 9.5))
		lm.lathe("Copper", cc + Vector3(0, 13, 0), PackedVector2Array([Vector2(5.0, 0),
			Vector2(4.7, 2.2), Vector2(3.7, 4.4), Vector2(1.9, 6.1), Vector2(0.5, 6.9),
			Vector2(0.3, 8.6), Vector2(0.0, 9.0)]), 16)
		# Tall lancet windows down the nave above the aisle roofs.
		for k in 7:
			var x := -16.0 + k * 6.0
			lm.box("Windows", Vector3(x, 14.5, 6.55 * sgn), Vector3(1.6, 5.5, 0.12))
	# Polygonal choir to the east.
	var apse := PackedVector2Array()
	for k in 7:
		var a := -PI * 0.5 + PI * float(k) / 6.0
		apse.append(Vector2(28 + cos(a) * 6.5, sin(a) * 6.5))
	lm.poly_prism("Brick", apse, 0.0, 18.0)
	lm.lathe("Copper", Vector3(28, 18, 0), PackedVector2Array([Vector2(7.1, 0), Vector2(0.0, 6.5)]), 6)
	# West tower: brick shaft, belfry stage with arched openings.
	var tx := -24.5
	lm.box("Brick", Vector3(tx, 19, 0), Vector3(10, 38, 10))
	lm.box("Brick", Vector3(tx, 42, 0), Vector3(9.6, 8, 9.6))
	for f in 4:
		var n := Vector3(cos(f * PI * 0.5), 0, sin(f * PI * 0.5))
		var side := n.cross(Vector3.UP)
		for s in [-1.8, 1.8]:
			lm.box("Windows", Vector3(tx, 42.5, 0) + n * 4.86 + side * s,
				Vector3(1.2, 5.0, 1.2) * (Vector3.ONE - n.abs()) + n.abs() * 0.12)
		lm.box("Windows", Vector3(tx, 30, 0) + n * 5.06, Vector3(1.4, 4.0, 1.4) * (Vector3.ONE - n.abs()) + n.abs() * 0.12)
	lm.box("Iron", Vector3(tx, 46.3, 0), Vector3(10.2, 0.6, 10.2))
	# The openwork spire: four X-braced faces from 46.6 m, corner ribs,
	# rings every stage, a thin needle and gilt finial to 90 m.
	var y0 := 46.6
	var y1 := 86.0
	var stages := 7
	for k in stages:
		var ya := lerpf(y0, y1, float(k) / float(stages))
		var yb := lerpf(y0, y1, float(k + 1) / float(stages))
		var ha := lerpf(4.4, 0.35, float(k) / float(stages))
		var hb := lerpf(4.4, 0.35, float(k + 1) / float(stages))
		var ring_a := _square(tx, ya, ha)
		var ring_b := _square(tx, yb, hb)
		for f in 4:
			var g := (f + 1) % 4
			lm.lattice_panel("Iron", ring_a[f], ring_a[g], ring_b[f], ring_b[g], 0.16)
			lm.beam("Iron", ring_a[f], ring_b[f], 0.3, 0.3)
	lm.beam("Iron", Vector3(tx, y1, 0), Vector3(tx, RIDDARHOLMEN_TOP_M - 1.2, 0), 0.22, 0.22)
	lm.lathe("Gilt", Vector3(tx, RIDDARHOLMEN_TOP_M - 1.2, 0), PackedVector2Array([Vector2(0.3, 0),
		Vector2(0.4, 0.5), Vector2(0.0, 1.2)]), 8)
	lm.commit(model)

static func _square(x: float, y: float, h: float) -> Array:
	return [Vector3(x - h, y, -h), Vector3(x + h, y, -h), Vector3(x + h, y, h), Vector3(x - h, y, h)]
