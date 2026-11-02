class_name LandmarkStockholm
extends RefCounted

## Stockholm City Hall (Östberg, 1911-1923) in true metres: the dark
## red block of about eight million hand-made "munktegel" bricks round
## its two courts — the open Borgargården to the west and the covered
## Blue Hall to the east — under verdigris copper roofs with dormers, a
## pale stone plinth and string courses, rows of deep-set windows, the
## arcaded water front to Riddarfjärden (+Z, south) with its terrace
## and steps, the slim NE turret with its copper lantern and golden
## starlets, and the 106 m tower at the south-east corner: a brick
## shaft whose faces are cut by tall recessed niches, the belfry stage
## with arched openings, corner turrets and a gallery, the copper
## lantern, and the spire carrying the three gilded crowns; Birger
## Jarl's gilded cenotaph at its foot.

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
		lm.box("Stone", c + Vector3(0, 0.6, 0), size + Vector3(0.5, 1.2 - size.y, 0.5))
		var along_x := size.x > size.z
		var rb := Basis(Vector3.UP, PI * 0.5) if along_x else Basis()
		var rise := minf(size.x, size.z) * 0.32
		lm.gable("Copper", c + Vector3(0, size.y, 0), minf(size.x, size.z), maxf(size.x, size.z), rise, rb, 0.5, "Brick")
		# Copper ridge roll and standing seams down both slopes.
		var run := maxf(size.x, size.z)
		var half := minf(size.x, size.z) * 0.5 + 0.5
		lm.box("Copper", c + Vector3(0, size.y + rise + 0.15, 0), Vector3(0.4, 0.4, run + 0.5), rb, 0.0)
		var seams := int(run / 1.6)
		for k in seams + 1:
			var u := -run * 0.5 + run * k / seams
			for s in [-1.0, 1.0]:
				var e := rb * Vector3(s * half, 0, u)
				var t := rb * Vector3(0, 0, u)
				lm.beam("Copper", c + e + Vector3(0, size.y - 0.15 + 0.08, 0), c + t + Vector3(0, size.y + rise + 0.08, 0),
					0.08, 0.1)
		# Copper dormers along the long slopes of the tall wings.
		if size.y >= WALL_M:
			var nd := int(run / 9.0)
			for k in nd:
				var u := -run * 0.5 + run * (k + 0.5) / nd
				for s in [-1.0, 1.0]:
					var dc := c + rb * Vector3(s * half * 0.55, size.y + rise * 0.42, u)
					var fb := rb * Basis(Vector3.UP, s * PI * 0.5)
					lm.box("Copper", dc + Vector3(0, 0.9, 0), Vector3(1.8, 1.8, 2.0), fb)
					lm.box("Windows", dc + fb * Vector3(0, 0.9, 1.02), Vector3(1.0, 1.0, 0.05), fb, 0.0)
					lm.gable("Copper", dc + Vector3(0, 1.8, 0), 1.8, 2.0, 0.8, fb, 0.1, "Copper")
	# The covered Blue Hall fills the eastern court, its clerestory roof.
	var bh := Vector3(hx * 0.5 + 4.0, 0, 0)
	var bsize := Vector2(hx - 2.0 * WING_M + 4.0, SIZE.y - 2.0 * WING_M)
	lm.box("Brick", bh + Vector3(0, 11.0, 0), Vector3(bsize.x, 22.0, bsize.y))
	lm.box("Copper", bh + Vector3(0, 22.3, 0), Vector3(bsize.x, 0.6, bsize.y))
	for k in 6:
		lm.box("Windows", bh + Vector3(-bsize.x * 0.5 + bsize.x * (k + 0.5) / 6.0, 23.0, 0), Vector3(3.0, 1.2, bsize.y * 0.6))
	_north_front(lm, hx, hz)
	_water_front(lm, hx, hz)
	# West and east fronts: windows in three rows.
	# (the low water wing's ends are left out).
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		var z0: float = hz - 10.0 if s > 0.0 else -hz + 1.0
		LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(s * hx, 1.2, z0), Vector3(0, 0, -s), n,
			SIZE.y - 11.0, WALL_M - 2.0, 15, 3, Vector2(1.3, 2.8), 4.0, 6.5, 0.4)
	_ne_turret(lm, Vector3(hx - 6.0, 0, -hz + 6.0))
	_tower(lm, Vector3(hx - 9.0, 0, hz - 9.0))
	lm.commit(model)

## North front: windows in three rows set deep in the brick (real
## reveals), the grand doors under stone arches and stone sills.
static func _north_front(lm: LandmarkMesh, hx: float, hz: float) -> void:
	var n := Vector3(0, 0, -1)
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(hx, 1.2, -hz), Vector3(-1, 0, 0), n,
		SIZE.x, WALL_M - 2.0, 26, 3, Vector2(1.4, 3.0), 4.6, 6.5, 0.45)
	for k in 26:
		var x := hx - SIZE.x * (k + 0.5) / 26.0
		for row in 3:
			lm.box("Stone", Vector3(x, 1.2 + 4.6 + 6.5 * row - 0.12, -hz - 0.55), Vector3(1.8, 0.24, 0.3), Basis(), 0.0)
	for x in [-20.0, 20.0]:
		lm.box("BrickDark", Vector3(float(x), 2.6, -hz - 0.47), Vector3(3.0, 3.6, 0.1))
		_round_arch(lm, "Stone", Vector3(float(x), 4.4, -hz - 0.5), n, 3.4, 0.5)

## Water front: the arcade of stone columns and brick arches along the
## low south wing, a row of arched windows above it, the terrace with
## its steps down to Riddarfjärden.
static func _water_front(lm: LandmarkMesh, hx: float, hz: float) -> void:
	var n := Vector3(0, 0, 1)
	var z := hz + 0.2
	lm.box("BrickDark", Vector3(-12.0, 3.5, hz - 0.6), Vector3(SIZE.x - 30.0, 7.0, 1.2))
	var count := 14
	var span := (SIZE.x - 30.0) / count
	for k in count + 1:
		var x := -hx + 3.0 + span * k
		lm.lathe("Stone", Vector3(x, 0, z + 0.6), PackedVector2Array([Vector2(0.6, 0), Vector2(0.5, 0.4),
			Vector2(0.45, 0.6), Vector2(0.4, 4.6), Vector2(0.55, 5.0), Vector2(0.6, 5.4)]), 12)
	lm.box("Brick", Vector3(-12.0, 10.2, z + 0.6), Vector3(SIZE.x - 30.0, 9.6, 1.2))
	for k in count:
		var x := -hx + 3.0 + span * (k + 0.5)
		_round_arch(lm, "Brick", Vector3(x, 5.4, z + 1.2), n, span - 1.0, 0.7)
		_lunette(lm, Vector3(x, 5.4, z + 1.22), n, (span - 1.0) * 0.5)
	lm.box("Stone", Vector3(-12.0, 13.0, z + 0.7), Vector3(SIZE.x - 30.0, 0.4, 1.4))
	for k in count:
		var x := -hx + 3.0 + span * (k + 0.5)
		lm.box("Windows", Vector3(x, 10.4, z + 1.25), Vector3(1.2, 2.2, 0.06), Basis(), 0.0)
		_round_arch(lm, "Stone", Vector3(x, 11.5, z + 1.2), n, 1.2, 0.18)
	# Terrace and the steps to the water.
	lm.box("Stone", Vector3(0, 0.3, hz + 8.0), Vector3(SIZE.x, 0.6, 14.0))
	lm.box("Stone", Vector3(0, 1.0, hz + 14.8), Vector3(SIZE.x, 0.8, 0.5))
	for k in 4:
		lm.box("Stone", Vector3(-20.0, 0.075 + 0.15 * k, hz + 16.5 - 0.5 * k), Vector3(20.0, 0.15 + 0.3 * k, 0.5))

## Dark half-round fill under an arcade arch (the shadowed vault).
static func _lunette(lm: LandmarkMesh, c: Vector3, n: Vector3, r: float) -> void:
	var right := Vector3.UP.cross(n).normalized()
	for i in 10:
		var t0 := PI * i / 10.0
		var t1 := PI * (i + 1) / 10.0
		lm.tri("BrickDark", c, c + (right * cos(t0) + Vector3.UP * sin(t0)) * r,
			c + (right * cos(t1) + Vector3.UP * sin(t1)) * r, n, n, n, Vector2.ZERO,
			Vector2(cos(t0), sin(t0)) * r, Vector2(cos(t1), sin(t1)) * r)

## A light round arch (archivolt) of `segs` beams over a `span` opening
## springing at `c`, on a wall facing `n`.
static func _round_arch(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, span: float, band: float) -> void:
	var right := Vector3.UP.cross(n).normalized()
	var rad := span * 0.5 + band * 0.5
	var prev := c + right * rad
	for i in 10:
		var t := PI * float(i + 1) / 10.0
		var p := c + right * cos(t) * rad + Vector3(0, sin(t) * rad, 0)
		lm.beam(key, prev, p, band, band * 0.8, n)
		prev = p

## NE turret: brick shaft with string courses and slit windows, an
## octagonal copper lantern with openings, gilt starlets, cap and vane.
static func _ne_turret(lm: LandmarkMesh, tc: Vector3) -> void:
	lm.box("Brick", tc + Vector3(0, 21.0, 0), Vector3(6.0, 42.0, 6.0))
	for k in 3:
		lm.box("Stone", tc + Vector3(0, 28.0 + 5.0 * k, 0), Vector3(6.4, 0.3, 6.4), Basis(), 0.0)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in 2:
			lm.box("Windows", tc + r * Vector3(0, 32.0 + 5.0 * k, 3.02), Vector3(0.7, 2.6, 0.06), r, 0.0)
	lm.frustum("Copper", tc + Vector3(0, 42.0, 0), 3.6, 2.4, 4.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * k + PI / 8.0
		lm.box("Windows", tc + Vector3(cos(a) * 2.6, 44.6, sin(a) * 2.6), Vector3(0.8, 1.6, 0.06),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.lathe("Copper", tc + Vector3(0, 46.0, 0), PackedVector2Array([Vector2(2.4, 0),
		Vector2(2.0, 1.6), Vector2(0.9, 3.4), Vector2(0.0, 7.0)]), 16)
	for k in 8:
		var a := TAU * k / 8.0
		_star(lm, tc + Vector3(cos(a) * 2.1, 47.2, sin(a) * 2.1), 0.35)
	lm.frustum("Gilt", tc + Vector3(0, 53.0, 0), 0.3, 0.05, 1.6, 6)

## A gilt starlet: three crossed bars.
static func _star(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	for k in 3:
		var a := PI * k / 3.0
		var d := Vector3(cos(a) * r, sin(a) * r, 0)
		lm.beam("Gilt", c - d, c + d, r * 0.25, r * 0.25)

## The tower by the water: brick shaft cut on each face by three tall
## recessed niches between proud piers, small windows lighting the
## stair, the stone belt; the belfry stage with paired arched openings,
## four corner turrets and the gallery; the copper lantern ribbed in
## gilt, the spire and the three crowns.
static func _tower(lm: LandmarkMesh, t: Vector3) -> void:
	var shaft := 76.0
	var w := 16.0
	lm.box("Brick", t + Vector3(0, shaft * 0.5, 0), Vector3(w - 1.2, shaft, w - 1.2))
	lm.box("Stone", t + Vector3(0, 0.8, 0), Vector3(w + 0.6, 1.6, w + 0.6))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		# Piers: corners and between the niches, the niches' arched heads.
		for k in 4:
			var x := -w * 0.5 + 0.9 + (w - 1.8) * k / 3.0
			lm.box("Brick", t + r * Vector3(x, shaft * 0.5, w * 0.5 - 0.6), Vector3(1.8, shaft, 1.2), r)
		for k in 3:
			var x := -w * 0.5 + 0.9 + (w - 1.8) * (k + 0.5) / 3.0
			var nw := (w - 1.8) / 3.0 - 1.8
			lm.box("Brick", t + r * Vector3(x, 66.0 + 2.0, w * 0.5 - 0.6), Vector3(nw, 4.0, 1.2), r)
			_round_arch(lm, "BrickDark", t + r * Vector3(x, 66.0 - nw * 0.5, w * 0.5 - 0.3), r * Vector3.BACK, nw, 0.5)
			for m in 5:
				lm.box("Windows", t + r * Vector3(x, 14.0 + 10.0 * m, w * 0.5 - 1.18), Vector3(0.6, 1.6, 0.06), r, 0.0)
		# Ground storey portal and windows.
		lm.box("Windows", t + r * Vector3(0, 6.0, w * 0.5 + 0.02), Vector3(2.4, 5.0, 0.06), r, 0.0)
		_round_arch(lm, "Stone", t + r * Vector3(0, 8.5, w * 0.5 + 0.05), r * Vector3.BACK, 2.6, 0.4)
	lm.box("Stone", t + Vector3(0, shaft + 0.5, 0), Vector3(17.6, 1.0, 17.6))
	# Belfry stage: paired arched openings, corner turrets, gallery.
	var by := shaft + 1.0
	lm.box("Brick", t + Vector3(0, by + 5.0, 0), Vector3(13.0, 10.0, 13.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in [-1.0, 1.0]:
			lm.box("BrickDark", t + r * Vector3(k * 3.0, by + 4.0, 6.51), Vector3(2.2, 6.0, 0.1), r, 0.0)
			_round_arch(lm, "Stone", t + r * Vector3(k * 3.0, by + 7.0, 6.55), r * Vector3.BACK, 2.2, 0.35)
			for m in 4:
				lm.box("Brick", t + r * Vector3(k * 3.0, by + 2.0 + 1.3 * m, 6.6), Vector3(2.2, 0.15, 0.3), r, 0.0)
		# Gallery railing on the stone belt.
		for k in 17:
			lm.box("Copper", t + r * Vector3(-8.0 + k, shaft + 1.6, 8.4), Vector3(0.1, 1.2, 0.1), r, 0.0)
		lm.box("Copper", t + r * Vector3(0, shaft + 2.2, 8.4), Vector3(16.8, 0.12, 0.12), r, 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := t + Vector3(sx * 6.2, by, sz * 6.2)
			lm.frustum("Brick", tc, 0.9, 0.9, 10.0, 8, PI / 8.0)
			lm.lathe("Copper", tc + Vector3(0, 10.0, 0), PackedVector2Array([Vector2(1.1, 0), Vector2(0.7, 1.0),
				Vector2(0.0, 3.0)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.frustum("Gilt", tc + Vector3(0, 13.0, 0), 0.08, 0.02, 0.8, 4)
	lm.box("Stone", t + Vector3(0, shaft + 11.2, 0), Vector3(14.2, 0.6, 14.2))
	# Copper lantern: bell-shaped octagon, ribbed in gilt, with openings.
	var ly := shaft + 11.5
	var prof := PackedVector2Array([Vector2(6.0, 0), Vector2(5.4, 3.0),
		Vector2(3.6, 5.0), Vector2(3.2, 8.0), Vector2(1.6, 10.0), Vector2(0.7, 13.5)])
	lm.lathe("Copper", t + Vector3(0, ly, 0), prof, 8, 1.0, 1.0, PI / 8.0, false)
	var k8 := 1.0 / cos(PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * k
		for j in prof.size() - 1:
			lm.beam("Gilt", t + Vector3(cos(a) * (prof[j].x + 0.05), ly + prof[j].y, sin(a) * (prof[j].x + 0.05)),
				t + Vector3(cos(a) * (prof[j + 1].x + 0.05), ly + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.05)), 0.25, 0.15)
		var am := a + PI / 8.0
		lm.box("Windows", t + Vector3(cos(am), 0, sin(am)) * (3.4 / k8 + 0.06) + Vector3(0, ly + 6.5, 0),
			Vector3(0.9, 2.2, 0.06), Basis(Vector3.UP, -am + PI * 0.5), 0.0)
	# The spire and the three crowns.
	var cy := ly + 13.5
	lm.frustum("Gilt", t + Vector3(0, cy, 0), 0.25, 0.25, TOP_M - cy, 6)
	lm.lathe("Gilt", t + Vector3(0, cy + 1.0, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.45, 0.2),
		Vector2(0.5, 0.5), Vector2(0.45, 0.8), Vector2(0.0, 1.0)]), 10)
	for k in 3:
		var a := TAU * k / 3.0
		var off := Vector3(cos(a), 0, sin(a)) * 0.9
		_crown(lm, t + off + Vector3(0, TOP_M - 2.4, 0), 0.7)
		lm.beam("Gilt", t + Vector3(0, TOP_M - 3.4, 0), t + off + Vector3(0, TOP_M - 2.4, 0), 0.12, 0.12)
	# Birger Jarl's cenotaph under its canopy at the tower's east foot.
	var cen := t + Vector3(w * 0.5 + 3.0, 0, 0)
	lm.box("Stone", cen + Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 3.6))
	lm.box("Gilt", cen + Vector3(0, 1.3, 0), Vector3(1.6, 0.6, 2.8))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Stone", cen + Vector3(sx * 1.4, 0, sz * 2.0), 0.15, 0.15, 3.4, 6)
	lm.lathe("Copper", cen + Vector3(0, 3.4, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(0.0, 1.6)]), 4,
		0.8, 1.15, PI * 0.25, false)

## A small open crown: a gilt band with four points, r in radius.
static func _crown(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	lm.frustum("Gilt", base, r, r * 1.15, r * 0.7, 12)
	for k in 4:
		var a := TAU * k / 4.0
		lm.frustum("Gilt", base + Vector3(cos(a) * r, r * 0.7, sin(a) * r), r * 0.2, 0.0, r * 0.8, 4)
		lm.lathe("Gilt", base + Vector3(cos(a + PI * 0.25) * r * 1.1, r * 0.7, sin(a + PI * 0.25) * r * 1.1),
			PackedVector2Array([Vector2(0.0, 0), Vector2(r * 0.12, r * 0.12), Vector2(0.0, r * 0.24)]), 6)

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
