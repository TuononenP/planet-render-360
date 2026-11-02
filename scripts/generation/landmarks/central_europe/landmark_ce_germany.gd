class_name LandmarkCeGermany
extends RefCounted

## Two German icons in true metres: Cologne Cathedral (Gothic cross
## plan along X, twin openwork spires at the west front, 157.4 m) and
## Neuschwanstein Castle (white limestone Palas with its round tower on
## a rock spur, slate cones, 65 m above the courtyard).

# --- Cologne Cathedral ---

const KOELN_TOP := 157.4

static func cologne(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6E6862", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("stone", "#8A8379", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5258", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#202A30"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8F7A", 2.0, 0.55, 0.3))
	# Nave and choir with their steep slate roof; transept across.
	lm.box("Stone", Vector3(3.0, 22.0, 0), Vector3(96.0, 44.0, 45.0))
	lm.gable("Roof", Vector3(3.0, 44.0, 0), 45.0, 96.0, 17.0, Basis(Vector3.UP, PI * 0.5), 0.8, "Stone")
	lm.box("Stone", Vector3(8.0, 22.0, 0), Vector3(40.0, 44.0, 86.0))
	lm.gable("Roof", Vector3(8.0, 44.0, 0), 40.0, 86.0, 15.0, Basis(), 0.8, "Stone")
	# Polygonal choir apse with a chevet of chapels.
	lm.lathe("Stone", Vector3(46.0, 0, 0), PackedVector2Array([Vector2(21.0, 0), Vector2(21.0, 44.0)]), 14, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(46.0, 44.0, 0), PackedVector2Array([Vector2(22.0, 0), Vector2(0.0, 17.0)]), 14, 1.0, 1.0, 0.0, false)
	for k in 7:
		var a := PI * (-0.5 + float(k) / 6.0)
		lm.frustum("Pale", Vector3(46.0 + cos(a) * 22.5, 0, sin(a) * 22.5), 4.5, 4.5, 20.0, 8)
		lm.lathe("Roof", Vector3(46.0 + cos(a) * 22.5, 20.0, sin(a) * 22.5),
			PackedVector2Array([Vector2(5.0, 0), Vector2(0.0, 8.0)]), 8, 1.0, 1.0, 0.0, false)
	# Buttresses with pinnacles and flying arches along both sides.
	for sz in [-1.0, 1.0]:
		for i in 10:
			var x := -34.0 + 9.0 * i
			lm.box("Pale", Vector3(x, 17.0, sz * 28.5), Vector3(2.4, 34.0, 8.0))
			lm.spire("Pale", Vector3(x, 34.0, sz * 28.5), 1.1, 11.0)
			lm.beam("Pale", Vector3(x, 37.0, sz * 27.0), Vector3(x, 43.0, sz * 22.5), 1.6, 1.6)
			lm.beam("Pale", Vector3(x, 33.5, sz * 28.0), Vector3(x, 37.0, sz * 27.0), 1.6, 1.6)
			LandmarkCeParts.windows(lm, "Windows", Vector3(x + 4.5, 22.0, sz * 22.6), Vector3(0, 0, 1), 1, 1.0,
				Vector3(2.4, 20.0, 0.2))
	# Crossing spire (flèche), rising from the roof ridge.
	lm.lathe("Pale", Vector3(8.0, 59.0, 0), PackedVector2Array([Vector2(3.8, 0), Vector2(2.0, 22.0),
		Vector2(1.0, 38.0), Vector2(0.0, 50.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Twin west towers: four square stages, an octagon, then the spire.
	for sz in [-1.0, 1.0]:
		_koeln_tower(lm, Vector3(-57.5, 0, sz * 16.0))
	lm.box("Stone", Vector3(-57.5, 18.0, 0), Vector3(29.0, 36.0, 4.0))
	lm.gable("Roof", Vector3(-57.5, 36.0, 0), 4.0, 3.0, 9.0, Basis(), 0.4, "Stone")
	lm.commit(model)

static func _koeln_tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 30.0, 0), Vector3(29.0, 60.0, 29.0))
	lm.box("Stone", c + Vector3(0, 66.0, 0), Vector3(23.0, 12.0, 23.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in [-1.0, 0.0, 1.0]:
			lm.box("Windows", c + r * Vector3(k * 7.0, 40.0, 14.55), Vector3(2.4, 18.0, 0.2), r)
		lm.box("Windows", c + r * Vector3(0, 68.0, 11.6), Vector3(5.0, 8.0, 0.2), r)
		for s in [-1.0, 1.0]:
			var cp := c + r * Vector3(s * 12.4, 0, 12.4)
			lm.box("Pale", cp + Vector3(0, 40.0, 0), Vector3(3.6, 80.0, 3.6))
			lm.spire("Pale", cp + Vector3(0, 80.0, 0), 2.1, 15.0)
	lm.frustum("Stone", c + Vector3(0, 72.0, 0), 11.5, 10.0, 28.0, 8, PI / 8.0)
	# Openwork octagonal spire to the tip at KOELN_TOP.
	var base_y := 100.0
	lm.lathe("Pale", c + Vector3(0, base_y, 0), PackedVector2Array([Vector2(10.5, 0), Vector2(8.0, 14.0),
		Vector2(5.2, 32.0), Vector2(2.8, 46.0), Vector2(1.2, 54.0), Vector2(0.25, KOELN_TOP - base_y)]),
		8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		lm.beam("Pale", c + Vector3(cos(a) * 9.8, base_y, sin(a) * 9.8),
			c + Vector3(cos(a) * 1.0, base_y + 54.0, sin(a) * 1.0), 1.0, 1.0)

# --- Neuschwanstein ---

const NEU_TOP := 65.0

static func neuschwanstein(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#E6E0D2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5E6A74", 2.5))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8A8274", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#B7AD99", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Rock spur below the courtyard (hidden under the ground at y = 0).
	lm.lathe("Rock", Vector3(0, -24.0, 0), PackedVector2Array([Vector2(48.0, 0), Vector2(40.0, 14.0),
		Vector2(36.0, 24.0)]), 10, 1.0, 0.85)
	# Palas: long block with a steep gabled roof and stepped end gables.
	lm.box("Wall", Vector3(0, 13.0, 0), Vector3(44.0, 26.0, 15.0))
	lm.gable("Roof", Vector3(0, 26.0, 0), 15.0, 44.0, 14.0, Basis(Vector3.UP, PI * 0.5), 0.6, "Wall")
	for row in 4:
		LandmarkCeParts.windows(lm, "Windows", Vector3(0, 5.0 + 5.2 * row, 7.6), Vector3(1, 0, 0), 9, 4.6,
			Vector3(1.4, 2.8, 0.2))
	# Round main tower at the west end of the Palas with its slate cone.
	var tc := Vector3(-22.0, 0, 5.0)
	lm.frustum("Wall", tc, 7.5, 7.0, 47.0, 20)
	lm.box("Trim", tc + Vector3(0, 41.0, 0), Vector3(17.0, 1.0, 17.0))
	lm.lathe("Roof", tc + Vector3(0, 47.0, 0), PackedVector2Array([Vector2(8.4, 0), Vector2(7.0, 4.0),
		Vector2(4.0, 12.0), Vector2(0.4, NEU_TOP - 47.0)]), 20)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * k
		var tp := tc + Vector3(cos(a) * 6.6, 47.0, sin(a) * 6.6)
		lm.frustum("Wall", tp, 1.6, 1.6, 6.0, 10)
		lm.lathe("Roof", tp + Vector3(0, 6.0, 0), PackedVector2Array([Vector2(2.0, 0), Vector2(0.0, 6.5)]), 10)
	for row in 6:
		lm.box("Windows", tc + Vector3(0, 8.0 + 6.0 * row, 7.55), Vector3(1.3, 3.2, 0.2))
	# Knights' House with its round tower (east), Gatehouse and Bower (south).
	lm.box("Wall", Vector3(30.0, 9.0, 4.0), Vector3(16.0, 18.0, 12.0))
	lm.gable("Roof", Vector3(30.0, 18.0, 4.0), 12.0, 16.0, 7.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	lm.frustum("Wall", Vector3(37.0, 0, 11.0), 5.0, 4.6, 30.0, 16)
	lm.lathe("Roof", Vector3(37.0, 30.0, 11.0), PackedVector2Array([Vector2(5.8, 0), Vector2(0.3, 15.0)]), 16)
	lm.box("Wall", Vector3(-6.0, 11.0, 24.0), Vector3(12.0, 22.0, 12.0))
	lm.frustum("Wall", Vector3(-6.0, 22.0, 24.0), 5.0, 4.4, 8.0, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(-6.0, 30.0, 24.0), PackedVector2Array([Vector2(5.4, 0), Vector2(0.3, 14.0)]), 8)
	lm.box("Wall", Vector3(14.0, 7.0, 22.0), Vector3(20.0, 14.0, 9.0))
	lm.gable("Roof", Vector3(14.0, 14.0, 22.0), 9.0, 20.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	# Gilt finial on the Palas gable and a pennant on the great tower.
	lm.beam("Gilt", Vector3(0, 40.0, 0), Vector3(0, 44.0, 0), 0.4, 0.4)
	lm.commit(model)
