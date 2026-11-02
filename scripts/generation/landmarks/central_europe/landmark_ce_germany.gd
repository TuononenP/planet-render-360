class_name LandmarkCeGermany
extends RefCounted

## Two German icons in true metres: Cologne Cathedral (Gothic cross
## plan along X, twin openwork spires at the west front, 157.4 m) and
## Neuschwanstein Castle (white limestone Palas with its 65 m stair
## tower, the courtyard buildings and the red-brick Gatehouse along the
## rock ridge, slate roofs).

# --- Cologne Cathedral ---

## Cologne Cathedral: 144.6 m long, 86.3 m across the transept, west
## front 61.5 m, transept fronts 40 m. A five-aisled nave whose central
## vessel (43.4 m inside, roof ridge 61.1 m) is braced by double flying
## buttresses over the two aisles, a choir with seven radiating
## chapels, the slender crossing spire, and twin 157 m west towers:
## square stages, an octagon and openwork spires with crockets and a
## cross-flower finial.
const KOELN_TOP := 157.4
const K_EAVE := 45.0
const K_AISLE := 21.0
const K_HALF := 8.0
const K_WEST := -43.0
const K_CHOIR := 46.0

static func cologne(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6E6862", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("stone", "#8A8379", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5258", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#202A30"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8F7A", 2.0, 0.55, 0.3))
	# Central vessels: nave and choir along X, transept across.
	var nl := K_CHOIR - K_WEST
	lm.box("Stone", Vector3((K_WEST + K_CHOIR) * 0.5, K_EAVE * 0.5, 0), Vector3(nl, K_EAVE, K_HALF * 2.0))
	lm.gable("Roof", Vector3((K_WEST + K_CHOIR) * 0.5, K_EAVE, 0), K_HALF * 2.0, nl, 61.1 - K_EAVE,
		Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	lm.box("Stone", Vector3(8.0, K_EAVE * 0.5, 0), Vector3(K_HALF * 2.0, K_EAVE, 86.0))
	lm.gable("Roof", Vector3(8.0, K_EAVE, 0), K_HALF * 2.0, 86.0, 61.1 - K_EAVE, Basis(), 0.6, "Stone")
	# Double aisles each side of nave and choir, and the transept aisles.
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(-27.5, K_AISLE * 0.5, sz * 15.5), Vector3(31.0, K_AISLE, 15.0))
		lm.box("Stone", Vector3(37.0, K_AISLE * 0.5, sz * 15.5), Vector3(18.0, K_AISLE, 15.0))
		for sx in [-1.0, 1.0]:
			lm.box("Stone", Vector3(8.0 + sx * 14.0, K_AISLE * 0.5, sz * 26.0), Vector3(12.0, K_AISLE, 34.0))
		# Lean-to aisle roofs.
		for seg in [[-43.0, -12.0], [28.0, 46.0]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			lm.quad("Roof", Vector3(x0, K_AISLE, sz * 23.2), Vector3(x1, K_AISLE, sz * 23.2),
				Vector3(x1, K_AISLE + 7.0, sz * K_HALF), Vector3(x0, K_AISLE + 7.0, sz * K_HALF),
				Vector3(0, 1.0, sz * 0.5).normalized())
	_koeln_chevet(lm)
	# Bays of nave and choir: aisle lancets, clerestory lancets with
	# wimpergs, buttress piers with pinnacles and double flyers.
	var bays: Array[float] = []
	for i in 5:
		bays.append(K_WEST + 3.9 + 7.75 * i)
	for i in 3:
		bays.append(28.0 + 3.0 + 6.0 * i)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for i in bays.size():
			var x: float = bays[i]
			var mid := x + (3.9 if i < 5 else 3.0)
			if i != 4 and i != 7:
				LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(mid, 5.0, sz * 23.05), n, 4.4, 12.5, 1)
				LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(mid, K_AISLE + 7.6, sz * K_HALF * 1.0), n,
					5.0, 15.5, 3)
				LandmarkCeParts.wimperg(lm, "Pale", Vector3(mid, K_EAVE - 1.6, sz * (K_HALF + 0.2)), n, 5.6, 5.0)
			# Outer buttress, intermediate pier and the two flyers.
			lm.box("Pale", Vector3(x, 14.0, sz * 25.0), Vector3(2.6, 28.0, 4.6))
			LandmarkCeParts.pinnacle(lm, "Pale", Vector3(x, 28.0, sz * 25.0), 2.2, 10.0)
			lm.box("Pale", Vector3(x, K_AISLE + 6.0, sz * 15.5), Vector3(1.8, 12.0, 2.4))
			LandmarkCeParts.pinnacle(lm, "Pale", Vector3(x, K_AISLE + 12.0, sz * 15.5), 1.6, 8.0)
			for lvl in [[31.0, 0.0], [38.0, 4.0]]:
				var y: float = lvl[0]
				var dy: float = lvl[1]
				lm.beam("Pale", Vector3(x, y - 6.0 + dy * 0.5, sz * 23.3), Vector3(x, y - 2.0 + dy * 0.5, sz * 16.6), 1.0, 1.4)
				lm.beam("Pale", Vector3(x, y - 2.0 + dy * 0.5, sz * 14.4), Vector3(x, y + dy * 0.5, sz * (K_HALF + 0.3)), 1.0, 1.4)
			lm.box("Pale", Vector3(x, K_EAVE - 3.0, sz * (K_HALF + 0.4)), Vector3(1.4, 6.0, 0.8))
			LandmarkCeParts.pinnacle(lm, "Pale", Vector3(x, K_EAVE, sz * (K_HALF + 0.4)), 1.0, 5.0)
	# Transept fronts: portal under a wimperg, great window, gable,
	# corner turrets.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var zf: float = sz * 43.05
		lm.box("Pale", Vector3(8.0, 4.5, zf + sz * 0.6), Vector3(9.0, 9.0, 1.2))
		LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(8.0, 0.6, zf + sz * 1.2), n, 5.0, 7.7, 1)
		LandmarkCeParts.wimperg(lm, "Pale", Vector3(8.0, 8.5, zf + sz * 1.0), n, 9.0, 8.0)
		LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(8.0, 20.0, zf), n, 11.0, 22.0, 5)
		for sx in [-1.0, 1.0]:
			var tp := Vector3(8.0 + sx * 9.0, 0, zf)
			lm.box("Pale", tp + Vector3(0, 26.0, 0), Vector3(3.2, 52.0, 3.2))
			LandmarkCeParts.pinnacle(lm, "Pale", tp + Vector3(0, 52.0, 0), 3.0, 14.0)
			lm.box("Pale", Vector3(8.0 + sx * 20.0, 12.0, zf), Vector3(2.4, 24.0, 2.8))
			LandmarkCeParts.pinnacle(lm, "Pale", Vector3(8.0 + sx * 20.0, 24.0, zf), 2.0, 8.0)
	# Crossing spire (flèche) on the ridge, copper over a lantern of lancets.
	var fb := Vector3(8.0, 58.0, 0)
	lm.frustum("Copper", fb, 4.2, 4.0, 10.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCeParts.pinnacle(lm, "Copper", fb + d * 4.4 + Vector3(0, 6.0, 0), 0.8, 8.0)
	lm.lathe("Copper", fb + Vector3(0, 10.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(2.2, 16.0),
		Vector2(0.9, 32.0), Vector2(0.0, 41.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Twin west towers and the centre of the front between them.
	for sz in [-1.0, 1.0]:
		_koeln_tower(lm, Vector3(-57.5, 0, sz * 19.0))
	_koeln_west(lm)
	lm.commit(model)

## Chevet: the choir apse (half of a ten-sided polygon), ambulatory and
## seven radiating chapels, with flyers from the chapel piers.
static func _koeln_chevet(lm: LandmarkMesh) -> void:
	var c := Vector3(K_CHOIR, 0, 0)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(K_HALF * 1.05, 0), Vector2(K_HALF * 1.05, K_EAVE)]),
		10, 1.0, 1.0, PI / 10.0, false)
	lm.lathe("Roof", c + Vector3(0, K_EAVE, 0), PackedVector2Array([Vector2(K_HALF * 1.12, 0), Vector2(0.0, 61.1 - K_EAVE)]),
		10, 1.0, 1.0, PI / 10.0, false)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(16.0, 0), Vector2(16.0, K_AISLE)]), 14, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", c + Vector3(0, K_AISLE, 0), PackedVector2Array([Vector2(16.4, 0), Vector2(K_HALF, 7.0)]),
		14, 1.0, 1.0, 0.0, false)
	for k in 7:
		var a := PI * (-0.5 + (float(k) + 0.5) / 7.0)
		var d := Vector3(cos(a), 0, sin(a))
		var cc := c + d * 19.5
		lm.lathe("Pale", cc, PackedVector2Array([Vector2(4.6, 0), Vector2(4.6, 17.0)]), 7, 1.0, 1.0, a, false)
		lm.lathe("Roof", cc + Vector3(0, 17.0, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(0.0, 6.5)]),
			7, 1.0, 1.0, a, false)
		LandmarkCeParts.lancet(lm, "Pale", "Windows", cc + d * 4.5 + Vector3(0, 4.0, 0), d, 2.6, 10.0, 1)
		# Pier between chapels with its pinnacle and the flyer to the apse.
		var pa := a + PI / 14.0
		var pd := Vector3(cos(pa), 0, sin(pa))
		if k < 6:
			lm.box("Pale", c + pd * 22.0 + Vector3(0, 14.0, 0), Vector3(2.4, 28.0, 2.4), Basis(Vector3.UP, -pa))
			LandmarkCeParts.pinnacle(lm, "Pale", c + pd * 22.0 + Vector3(0, 28.0, 0), 2.0, 9.0)
			lm.beam("Pale", c + pd * 21.0 + Vector3(0, 26.0, 0), c + pd * (K_HALF + 0.6) + Vector3(0, 36.0, 0), 1.0, 1.4)
			lm.beam("Pale", c + pd * 21.0 + Vector3(0, 31.0, 0), c + pd * (K_HALF + 0.6) + Vector3(0, 41.0, 0), 1.0, 1.4)
		# Clerestory lancet and wimperg on each apse face.
		var fa := PI * (-0.5 + (float(k) + 0.5) / 7.0)
		var fd := Vector3(cos(fa), 0, sin(fa))
		LandmarkCeParts.lancet(lm, "Pale", "Windows", c + fd * (K_HALF * 1.02) + Vector3(0, K_AISLE + 8.0, 0), fd,
			3.6, 15.0, 1)
		LandmarkCeParts.wimperg(lm, "Pale", c + fd * (K_HALF * 1.02) + Vector3(0, K_EAVE - 1.6, 0), fd, 4.0, 4.4)

## West front between the towers: the main portal under its wimperg,
## the great west window and the gable.
static func _koeln_west(lm: LandmarkMesh) -> void:
	var x := -70.0
	lm.box("Stone", Vector3(-57.5, 25.0, 0), Vector3(25.0, 50.0, 15.0))
	lm.gable("Roof", Vector3(-57.5, 50.0, 0), 15.0, 25.0, 11.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	var n := Vector3.LEFT
	lm.box("Pale", Vector3(x - 0.6, 7.0, 0), Vector3(1.6, 14.0, 12.0))
	LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(x - 1.45, 0.6, 0), n, 6.0, 11.1, 1, 0.5)
	LandmarkCeParts.wimperg(lm, "Pale", Vector3(x - 1.4, 13.6, 0), n, 11.0, 10.0, 0.6)
	LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(x, 22.0, 0), n, 9.0, 22.0, 3)
	LandmarkCeParts.wimperg(lm, "Pale", Vector3(x - 0.2, 44.0, 0), n, 10.0, 8.0)

## One west tower, 23.5 m square: buttressed lower stages with tall
## lancets, the octagon with gabled windows and corner pinnacles, and
## the openwork spire to KOELN_TOP.
static func _koeln_tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 32.0, 0), Vector3(23.5, 64.0, 23.5))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		# Two tall twin-light lancets per face on each of the two stages.
		for k in [-1.0, 1.0]:
			var p := c + r * Vector3(k * 5.2, 0, 11.8)
			LandmarkCeParts.lancet(lm, "Pale", "Windows", p + Vector3(0, 18.0, 0), n, 3.6, 16.0, 1)
			LandmarkCeParts.wimperg(lm, "Pale", p + Vector3(0, 33.2, 0), n, 4.2, 4.6)
			LandmarkCeParts.lancet(lm, "Pale", "Windows", p + Vector3(0, 41.0, 0), n, 3.8, 18.0, 1)
			LandmarkCeParts.wimperg(lm, "Pale", p + Vector3(0, 58.4, 0), n, 4.4, 5.0)
		# Stepped corner buttresses with pinnacles at each set-back.
		for s in [-1.0, 1.0]:
			var cp := c + r * Vector3(s * 12.4, 0, 12.4)
			lm.box("Pale", cp + Vector3(0, 32.0, 0), Vector3(3.6, 64.0, 3.6))
			for lvl in [[22.0, 2.0, 7.0], [44.0, 1.7, 7.0], [64.0, 2.2, 16.0]]:
				LandmarkCeParts.pinnacle(lm, "Pale", cp + r * Vector3(0, 0, 0.8) + Vector3(0, float(lvl[0]), 0),
					float(lvl[1]), float(lvl[2]))
		lm.box("Pale", c + r * Vector3(0, 64.0, 11.9), Vector3(24.0, 1.0, 1.2), r)
	# Octagon stage with its tall gabled windows.
	var ob := c + Vector3(0, 64.0, 0)
	lm.lathe("Stone", ob, PackedVector2Array([Vector2(11.4, 0), Vector2(10.8, 36.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCeParts.lancet(lm, "Pale", "Windows", ob + d * 10.4 + Vector3(0, 6.0, 0), d, 3.4, 20.0, 1)
		LandmarkCeParts.wimperg(lm, "Pale", ob + d * 10.4 + Vector3(0, 26.4, 0), d, 4.0, 5.5)
		var ca := a + PI / 8.0
		var cd := Vector3(cos(ca), 0, sin(ca))
		LandmarkCeParts.pinnacle(lm, "Pale", ob + cd * 11.4 + Vector3(0, 26.0, 0), 1.6, 13.0)
	# Openwork spire: solid core, eight crocketed ribs, tracery rings.
	var base_y := 100.0
	var sb := c + Vector3(0, base_y, 0)
	lm.lathe("Stone", sb, PackedVector2Array([Vector2(9.6, 0), Vector2(6.4, 18.0),
		Vector2(3.6, 36.0), Vector2(1.6, 50.0), Vector2(0.5, 53.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	var top := KOELN_TOP - base_y
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := sb + d * 10.4
		var p1 := sb + d * 1.0 + Vector3(0, 52.0, 0)
		lm.beam("Pale", p0, p1, 1.1, 1.1)
		for j in 12:
			var p := p0.lerp(p1, (float(j) + 0.5) / 12.0)
			lm.box("Pale", p + d * 0.75, Vector3(0.9, 0.6, 0.9), Basis(Vector3.UP, -a), 0.0)
	for j in 9:
		var t := float(j + 1) / 10.0
		var rr := lerpf(10.0, 1.4, t)
		lm.frustum("Pale", sb + Vector3(0, 52.0 * t, 0), rr, rr * 0.98, 0.6, 8, PI / 8.0)
	# Finial: the cross-flower at the tip.
	var fb := sb + Vector3(0, 52.0, 0)
	lm.frustum("Pale", fb, 1.4, 0.6, top - 52.0, 8, PI / 8.0)
	for k in 4:
		var a := PI * 0.5 * k
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Pale", fb + Vector3(0, 2.2, 0), fb + d * 1.8 + Vector3(0, 2.6, 0), 0.6, 0.5)
	lm.lathe("Pale", fb + Vector3(0, 1.0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.6, 0.8),
		Vector2(1.2, 1.6), Vector2(0.6, 2.0)]), 8)

# --- Neuschwanstein ---

## Neuschwanstein (1869-86) along its ridge, west (-X) to east: the
## five-storey Palas with the two-storey Throne Hall balcony on its
## west front and the 65 m northern stair tower; the upper courtyard
## with the 45 m Rectangular Tower, the Knights' House (north) and the
## Bower (south); the lower courtyard and the red-brick Gatehouse with
## its crow-stepped gable between two stair towers. White limestone,
## slate roofs. The rock is a raised plinth, not a pit.
const NEU_TOP := 65.0
const NEU_ROCK := 3.0

static func neuschwanstein(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#E6E0D2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5E6A74", 2.5))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8A8274", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#B7AD99", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9E4A35", 3.0))
	# Rock spur as a raised, ragged plinth under the whole complex.
	lm.lathe("Rock", Vector3(18.0, 0, 0), PackedVector2Array([Vector2(62.0, 0), Vector2(58.0, 1.6),
		Vector2(55.0, NEU_ROCK)]), 18, 1.0, 0.42, 0.2, false)
	var g := NEU_ROCK
	_neu_palas(lm, g)
	# Upper courtyard buildings.
	_neu_block(lm, Vector3(24.0, g, -15.0), Vector3(20.0, 15.0, 8.0), 7.0, 5, 3)
	_neu_block(lm, Vector3(24.0, g, 15.0), Vector3(20.0, 17.0, 9.0), 7.5, 5, 3)
	var bt := Vector3(32.0, g, 20.0)
	lm.lathe("Wall", bt, PackedVector2Array([Vector2(3.4, 0), Vector2(3.4, 22.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Roof", bt + Vector3(0, 22.0, 0), PackedVector2Array([Vector2(3.9, 0), Vector2(0.2, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Rectangular Tower: 45 m, crenellated platform with corner turrets.
	var rt := Vector3(38.0, g, -14.0)
	lm.box("Wall", rt + Vector3(0, 19.0, 0), Vector3(8.0, 38.0, 8.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		for k in 4:
			LandmarkDetail.window(lm, "Trim", "Windows", rt + n * 4.0 + Vector3(0, 9.0 + 7.5 * k, 0), n, 1.2, 2.6, true, 0.2)
	lm.lathe("Trim", rt + Vector3(0, 37.0, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(5.9, 1.0),
		Vector2(6.0, 2.0)]), 4, 1.0, 1.0, PI * 0.25, false)
	lm.box("Wall", rt + Vector3(0, 40.0, 0), Vector3(8.4, 2.0, 8.4))
	for sx in [-1.0, 1.0]:
		LandmarkCeParts.merlons(lm, "Wall", rt + Vector3(sx * 4.0, 41.0, -4.0), rt + Vector3(sx * 4.0, 41.0, 4.0), 1.3, 0.7, 1.0, 0.5)
		LandmarkCeParts.merlons(lm, "Wall", rt + Vector3(-4.0, 41.0, sx * 4.0), rt + Vector3(4.0, 41.0, sx * 4.0), 1.3, 0.7, 1.0, 0.5)
		for sz in [-1.0, 1.0]:
			var q := rt + Vector3(sx * 4.2, 33.0, sz * 4.2)
			lm.lathe("Trim", q, PackedVector2Array([Vector2(0.3, 0), Vector2(1.2, 2.0)]), 8)
			lm.frustum("Wall", q + Vector3(0, 2.0, 0), 1.2, 1.2, 7.0, 10)
			lm.lathe("Roof", q + Vector3(0, 9.0, 0), PackedVector2Array([Vector2(1.45, 0), Vector2(0.0, 3.0)]), 10)
	# Gallery with blind arcading linking the Knights' House to the tower.
	lm.box("Wall", Vector3(44.0, g + 5.0, -9.0), Vector3(14.0, 10.0, 3.0))
	for i in 5:
		LandmarkDetail.arch(lm, "Trim", Vector3(38.0 + 2.8 * i, g + 6.0, -7.5), Vector3.BACK, 2.0, 0.3, 0.2)
	# Lower courtyard walls and the Gatehouse.
	for sz in [-1.0, 1.0]:
		lm.box("Wall", Vector3(52.0, g + 3.0, sz * 13.0), Vector3(16.0, 6.0, 1.6))
		LandmarkCeParts.merlons(lm, "Wall", Vector3(44.5, g + 6.0, sz * 13.0), Vector3(59.5, g + 6.0, sz * 13.0), 1.6, 0.8, 1.0, 1.6)
	_neu_gatehouse(lm, Vector3(66.0, g, 0))
	lm.commit(model)

## The Palas: five storeys under a steep slate roof, Romanesque arched
## windows, the west balcony, corner turrets and the two stair towers.
static func _neu_palas(lm: LandmarkMesh, g: float) -> void:
	var c := Vector3(-12.0, g, 0)
	var size := Vector3(38.0, 30.0, 16.0)
	lm.box("Wall", c + Vector3(0, size.y * 0.5, 0), size)
	lm.gable("Roof", c + Vector3(0, size.y, 0), size.z, size.x, 13.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	for k in 5:
		lm.box("Trim", c + Vector3(0, 5.5 + 5.6 * k, 0), Vector3(size.x + 0.3, 0.3, size.z + 0.3), Basis(), 0.0)
	# Arched windows on both long fronts: paired lights on the upper floors.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for row in 5:
			for i in 8:
				var x := c.x - 15.75 + 4.5 * i
				var y := c.y + 2.6 + 5.6 * row
				if row >= 2:
					for s in [-0.55, 0.55]:
						LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x + s, y + 1.6, sz * 8.0), n, 0.8, 2.8, true, 0.2)
				else:
					LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, y + 1.4, sz * 8.0), n, 1.1, 2.4, true, 0.2)
		# Dormers on the roof.
		for i in 4:
			var dx := c.x - 13.0 + 8.6 * i
			var dp := Vector3(dx, c.y + size.y + 3.0, sz * 6.3)
			lm.box("Wall", dp, Vector3(2.6, 3.4, 3.0))
			lm.gable("Roof", dp + Vector3(0, 1.7, 0), 2.6, 3.0, 1.6, Basis(), 0.2, "Wall")
	# West front: Throne Hall balcony (two storeys of arcades) and gable
	# with the knight figure.
	var wf := c + Vector3(-size.x * 0.5, 0, 0)
	lm.box("Wall", wf + Vector3(-1.6, 17.0, 0), Vector3(3.2, 0.6, 10.0))
	lm.box("Wall", wf + Vector3(-1.6, 23.0, 0), Vector3(3.2, 0.6, 10.0))
	for lvl in [17.3, 23.3]:
		for i in 5:
			var z := -4.0 + 2.0 * i
			lm.frustum("Trim", wf + Vector3(-3.0, lvl, z), 0.18, 0.15, 4.4, 8)
			lm.box("Trim", wf + Vector3(-3.0, lvl + 4.5, z), Vector3(0.5, 0.25, 0.5), Basis(), 0.0)
		for i in 4:
			LandmarkDetail.arch(lm, "Trim", wf + Vector3(-3.0, lvl + 4.6, -3.0 + 2.0 * i), Vector3.LEFT, 1.6, 0.22, 0.25)
		for sz in [-1.0, 1.0]:
			lm.box("Wall", wf + Vector3(-1.6, lvl + 0.4, sz * 4.9), Vector3(3.0, 0.8, 0.25), Basis(), 0.0)
	for i in 6:
		lm.box("Trim", wf + Vector3(-1.6, 16.0 - 1.0 * i, 0), Vector3(3.0 - 0.45 * i, 0.45, 10.0 - 1.4 * i), Basis(), 0.0)
	for row in 2:
		for i in 3:
			LandmarkDetail.window(lm, "Trim", "Windows", wf + Vector3(0, 6.0 + 5.6 * row, -4.0 + 4.0 * i), Vector3.LEFT,
				1.1, 2.4, true, 0.2)
	LandmarkKits.statue_figure(lm, "Gilt", c + Vector3(-size.x * 0.5 - 0.3, size.y + 13.0, 0), 2.4, false)
	LandmarkKits.statue_figure(lm, "Gilt", c + Vector3(size.x * 0.5 + 0.3, size.y + 13.0, 0), 2.0, false)
	# Corbelled corner turrets.
	for sz in [-1.0, 1.0]:
		var q := wf + Vector3(0, 22.0, sz * 8.0)
		lm.lathe("Trim", q, PackedVector2Array([Vector2(0.4, 0), Vector2(1.6, 2.5)]), 10)
		lm.frustum("Wall", q + Vector3(0, 2.5, 0), 1.6, 1.6, 7.5, 12)
		lm.lathe("Roof", q + Vector3(0, 10.0, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.2, 1.6), Vector2(0.0, 6.5)]), 12)
		lm.beam("Gilt", q + Vector3(0, 16.5, 0), q + Vector3(0, 17.6, 0), 0.12, 0.12)
	# Northern stair tower (65 m) on the court side, with its turret.
	var nt := c + Vector3(size.x * 0.5 - 2.0, 0, -size.z * 0.5 - 1.5)
	lm.lathe("Wall", nt, PackedVector2Array([Vector2(4.2, 0), Vector2(4.0, 44.0)]), 12, 1.0, 1.0, 0.0, false)
	for k in 7:
		var a := 0.6 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", nt + d * 4.0 + Vector3(0, 6.0 + 5.6 * k, 0), d, 0.7, 1.8, true, 0.15)
	lm.lathe("Trim", nt + Vector3(0, 41.0, 0), PackedVector2Array([Vector2(4.0, 0), Vector2(4.8, 2.0),
		Vector2(4.8, 3.2)]), 12, 1.0, 1.0, 0.0, false)
	lm.lathe("Wall", nt + Vector3(0, 44.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(4.4, 3.0)]), 12, 1.0, 1.0, 0.0, false)
	for k in 12:
		var a := TAU * (float(k) + 0.5) / 12.0
		LandmarkDetail.window(lm, "Trim", "Windows", nt + Vector3(cos(a), 0, sin(a)) * 4.4 + Vector3(0, 45.4, 0),
			Vector3(cos(a), 0, sin(a)), 0.6, 1.6, true, 0.12)
	lm.lathe("Roof", nt + Vector3(0, 47.0, 0), PackedVector2Array([Vector2(4.9, 0), Vector2(3.6, 3.0),
		Vector2(1.6, 10.0), Vector2(0.3, NEU_TOP - 1.2 - g - 47.0)]), 12)
	lm.beam("Gilt", nt + Vector3(0, NEU_TOP - 1.4 - g, 0), Vector3(nt.x, NEU_TOP, nt.z), 0.14, 0.14)
	var tt := nt + Vector3(-2.0, 30.0, -3.2)
	lm.lathe("Trim", tt, PackedVector2Array([Vector2(0.3, 0), Vector2(1.3, 2.4)]), 10)
	lm.frustum("Wall", tt + Vector3(0, 2.4, 0), 1.3, 1.3, 14.0, 12)
	lm.lathe("Roof", tt + Vector3(0, 16.4, 0), PackedVector2Array([Vector2(1.6, 0), Vector2(0.0, 6.0)]), 12)
	# Southern stair tower, square below and octagonal above.
	var st := c + Vector3(size.x * 0.5 - 3.0, 0, size.z * 0.5 + 2.0)
	lm.box("Wall", st + Vector3(0, 18.0, 0), Vector3(6.0, 36.0, 6.0))
	lm.lathe("Wall", st + Vector3(0, 36.0, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(3.4, 5.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Roof", st + Vector3(0, 41.0, 0), PackedVector2Array([Vector2(3.9, 0), Vector2(2.6, 2.0), Vector2(0.2, 11.0)]),
		8, 1.0, 1.0, PI / 8.0, false)
	for k in 5:
		LandmarkDetail.window(lm, "Trim", "Windows", st + Vector3(0, 6.0 + 6.0 * k, 3.0), Vector3.BACK, 0.8, 2.0, true, 0.15)

## A gabled house block (Knights' House, Bower) from `c` (ground) of
## `size`, `rise` roof, `cols` x `rows` arched windows on both long sides.
static func _neu_block(lm: LandmarkMesh, c: Vector3, size: Vector3, rise: float, cols: int, rows: int) -> void:
	lm.box("Wall", c + Vector3(0, size.y * 0.5, 0), size)
	lm.gable("Roof", c + Vector3(0, size.y, 0), size.z, size.x, rise, Basis(Vector3.UP, PI * 0.5), 0.4, "Wall")
	lm.box("Trim", c + Vector3(0, size.y - 0.3, 0), Vector3(size.x + 0.4, 0.4, size.z + 0.4), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		for row in rows:
			for i in cols:
				var x := c.x - size.x * 0.5 + size.x * (float(i) + 0.5) / cols
				LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, c.y + 3.0 + 4.6 * row, c.z + sz * size.z * 0.5),
					Vector3(0, 0, sz), 1.1, 2.4, true, 0.2)

## Gatehouse: red brick with limestone trim, gate arch, crow-stepped
## gable facing east and two flanking stair towers.
static func _neu_gatehouse(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Brick", c + Vector3(0, 9.0, 0), Vector3(10.0, 18.0, 20.0))
	lm.gable("Roof", c + Vector3(0, 18.0, 0), 10.0, 20.0, 6.0, Basis(), 0.3, "Brick")
	# Crow steps on the east and west gables.
	for sx in [-1.0, 1.0]:
		for k in 5:
			var w := 20.0 - 4.0 * k
			lm.box("Brick", c + Vector3(sx * 5.0, 18.6 + 1.2 * k, 0), Vector3(0.8, 1.2, w))
		lm.box("Wall", c + Vector3(sx * 5.25, 4.2, 0), Vector3(0.5, 8.4, 5.6))
		LandmarkDetail.arch(lm, "Wall", c + Vector3(sx * 5.4, 6.0, 0), Vector3(sx, 0, 0), 3.6, 0.6, 0.4)
		lm.box("Windows", c + Vector3(sx * 5.52, 3.4, 0), Vector3(0.05, 5.2, 3.6), Basis(), 0.0)
		for i in 4:
			LandmarkDetail.window(lm, "Wall", "Windows", c + Vector3(sx * 5.0, 12.0, -6.0 + 4.0 * i), Vector3(sx, 0, 0),
				1.0, 2.4, true, 0.2)
		for i in 3:
			lm.box("Wall", c + Vector3(sx * 5.06, 9.2 + 6.0 * (i % 2), 0), Vector3(0.1, 0.4, 20.0), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		var t := c + Vector3(0, 0, sz * 11.5)
		lm.frustum("Brick", t, 3.4, 3.2, 24.0, 16)
		lm.frustum("Wall", t + Vector3(0, 23.0, 0), 3.6, 3.6, 1.0, 16)
		lm.lathe("Roof", t + Vector3(0, 24.0, 0), PackedVector2Array([Vector2(3.9, 0), Vector2(0.2, 9.0)]), 16)
		for k in 4:
			var a := 1.2 * float(k)
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkDetail.window(lm, "Wall", "Windows", t + d * 3.3 + Vector3(0, 4.0 + 4.8 * k, 0), d, 0.6, 1.6, true, 0.15)
