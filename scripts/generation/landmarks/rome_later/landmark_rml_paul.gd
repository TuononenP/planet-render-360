class_name LandmarkRmLPaul
extends RefCounted

## St Paul Outside the Walls and Santa Maria in Trastevere, two of Rome's
## early Christian basilicas, in true metres.

# --- St Paul Outside the Walls -----------------------------------------------

## Origin at the middle of the whole complex, facade facing +Z (west by the
## Via Ostiense; yaw_deg turns it): the basilica 131.66 m long, 65 m
## wide and 29.7 m high (rebuilt after the 1823 fire): the facade with
## its three registers of gold mosaic (prophets between the windows, the
## Lamb on the hill of the four rivers, Christ with Peter and Paul in the
## gable, 38 m), the 70 m quadriporticus of 150 granite columns with the
## statue of St Paul and palms in its garden, the nave with clerestory
## and aisle windows under the tiled roof, the transept and apse, and
## Poletti's 65 m campanile against the back of the apse: three square
## storeys, an octagonal colonnaded stage and a round tempietto.
static func paul(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C2A47C", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C8A7", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DFC8", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C8B87", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Garden", LandmarkMaterials.pbr("lawn", "#6E8F4E", 3.0))
	# Nave: aisles, clerestory, tiled ridge; transept and apse behind.
	lm.box("Wall", Vector3(0, 11.0, -4.0), Vector3(65.0, 22.0, 88.0))
	lm.box("Wall", Vector3(0, 25.85, -4.0), Vector3(26.0, 7.7, 88.0))
	lm.gable("Tile", Vector3(0, 29.7, -4.0), 26.0, 88.0, 4.3, Basis(), 0.5, "Wall")
	lm.box("Wall", Vector3(0, 15.0, -60.5), Vector3(94.0, 30.0, 25.0))
	lm.gable("Tile", Vector3(0, 30.0, -60.5), 25.0, 94.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	lm.frustum("Wall", Vector3(0, 0, -73.0), 14.0, 14.0, 26.0, 24)
	lm.lathe("Tile", Vector3(0, 26.0, -73.0), SEuUtil.dome(14.3, 5.0, 5), 24)
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		var r := Vector3.UP.cross(n)
		LandmarkDetail.pierced_face(lm, "Wall", "Shadow", Vector3(s * 13.0, 22.0, -4.0) - r * 44.0, r, n, 88.0, 7.7,
			10, 1, Vector2(2.4, 4.6), 1.6, 7.7)
		LandmarkDetail.pierced_face(lm, "Wall", "Shadow", Vector3(s * 32.5, 0.0, -4.0) - r * 44.0, r, n, 88.0, 21.0,
			9, 1, Vector2(2.4, 5.6), 10.0, 10.0)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 13.35, 29.0, 40.0), Vector3(s * 13.35, 29.0, -48.0), n, 0.7, false)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 32.85, 21.2, 40.0), Vector3(s * 32.85, 21.2, -48.0), n, 0.8, false)
		lm.quad("Tile", Vector3(s * 33.2, 22.0, 40.0), Vector3(s * 33.2, 22.0, -48.0), Vector3(s * 13.0, 23.6, -48.0),
			Vector3(s * 13.0, 23.6, 40.0), Vector3(s * 0.08, 1.0, 0).normalized())
		# Transept end: pilasters and a great window.
		var tn := Vector3(s, 0, 0)
		LandmarkRmLKit.pilaster_row(lm, "Trim", Vector3(s * 47.0, 0, -71.0), Vector3(0, 0, 1), tn, 21.0, 4, 1.2, 28.0, 0.5)
		LandmarkRmLKit.arcade(lm, "Wall", "Shadow", Vector3(s * 47.0, 12.0, -60.5) - Vector3.UP.cross(tn) * 3.5,
			Vector3.UP.cross(tn), tn, 7.0, 14.0, 1, 4.4, 8.0, 0.4)
	_paul_facade(lm)
	_quadriporticus(lm)
	_paul_campanile(lm, Vector3(0, 0, -93.0))
	lm.commit(model)

## The facade wall at z = 40..43 with its three mosaic registers.
static func _paul_facade(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, 16.0, 41.5), Vector3(65.0, 32.0, 3.0))
	lm.box("Trim", Vector3(0, 32.4, 41.5), Vector3(66.5, 0.8, 3.8))
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, 32.8, 40.0), r, n, 66.5, 5.2, 3.0, true)
	# Gable mosaic: Christ between Peter and Paul.
	lm.tri("Gold", Vector3(-28.0, 33.4, 43.05), Vector3(28.0, 33.4, 43.05), Vector3(0, 37.2, 43.05), n, n, n,
		Vector2.ZERO, Vector2(56, 0), Vector2(28, -3.8))
	lm.box("Gold", Vector3(0, 28.0, 43.1), Vector3(26.0, 7.0, 0.2), Basis(), 0.0)
	# Middle register: the Lamb on the hill between the cities, three
	# windows; lower register: prophets between the windows.
	lm.box("Gold", Vector3(0, 21.0, 43.1), Vector3(44.0, 4.4, 0.2), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Gold", Vector3(s * 22.0, 28.0, 43.1), Vector3(14.0, 7.0, 0.2), Basis(), 0.0)
	for x in [-22.0, -11.0, 0.0, 11.0, 22.0]:
		var c := Vector3(float(x), 12.0, 43.0)
		if absf(float(x)) < 15.0:
			LandmarkRmLKit.arcade(lm, "Stone", "Shadow", c - r * 2.2, r, n, 4.4, 8.0, 1, 3.0, 4.4, 0.3)
			LandmarkRmLKit.archivolts(lm, "Trim", c - r * 2.2, r, n, 4.4, 1, 3.0, 4.4, 0.3, 0.35)
		else:
			lm.box("Gold", c + Vector3(0, 3.5, 0.1), Vector3(7.0, 7.0, 0.2), Basis(), 0.0)
	for y in [10.8, 18.6, 23.4, 31.6]:
		lm.box("Trim", Vector3(0, float(y), 43.25), Vector3(64.0, 0.5, 0.5), Basis(), 0.0)
	for x in [-32.0, -16.5, 16.5, 32.0]:
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(float(x), 0, 43.0), r, n, 1.4, 32.0, 0.5, true)
	# The portico side of the court against the facade: the doors.
	for x in [-22.0, -11.0, 0.0, 11.0, 22.0]:
		var w := 3.35 if absf(float(x)) < 1.0 else 2.6
		lm.box("Shadow", Vector3(float(x), 3.75, 43.05), Vector3(w, 7.48, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(float(x), 0.4, 43.1), r, n, w, 7.48, 0)

## The quadriporticus: 70 m square in front of the facade (z 44 to
## 110), double colonnades on the sides and the far front, a single row
## along the facade: 150 granite columns; lean-to roofs and the garden.
static func _quadriporticus(lm: LandmarkMesh) -> void:
	lm.box("Garden", Vector3(0, 0.1, 77.0), Vector3(50.0, 0.2, 46.0))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 35.0, 6.0, 77.0), Vector3(1.0, 12.0, 66.0))
		lm.quad("Tile", Vector3(s * 35.0, 12.0, 110.0), Vector3(s * 35.0, 12.0, 44.0), Vector3(s * 25.5, 9.9, 44.0),
			Vector3(s * 25.5, 9.9, 110.0), Vector3(-s * 0.2, 1.0, 0).normalized())
		for row in [26.0, 30.5]:
			for i in 23:
				var z := 46.0 + 62.0 * float(i) / 22.0
				LandmarkRmLKit.column_lite(lm, "Granite", Vector3(s * float(row), 0, z), 0.5, 8.9)
			lm.box("Trim", Vector3(s * float(row), 9.35, 77.0), Vector3(1.2, 0.9, 64.0))
		# Palms in the garden.
		for z in [60.0, 94.0]:
			var p := Vector3(s * 16.0, 0, float(z))
			lm.frustum("Granite", p, 0.45, 0.3, 11.0, 8)
			for k in 9:
				var a := TAU * float(k) / 9.0
				lm.beam("Garden", p + Vector3(0, 11.0, 0), p + Vector3(cos(a) * 3.4, 9.6, sin(a) * 3.4), 0.9, 0.08, Vector3.UP)
	lm.box("Wall", Vector3(0, 6.0, 110.0), Vector3(70.0, 12.0, 1.0))
	lm.quad("Tile", Vector3(-35.0, 12.0, 110.0), Vector3(35.0, 12.0, 110.0), Vector3(35.0, 9.9, 100.5),
		Vector3(-35.0, 9.9, 100.5), Vector3(0, 1.0, -0.2).normalized())
	lm.quad("Tile", Vector3(-35.0, 11.0, 43.0), Vector3(35.0, 11.0, 43.0), Vector3(35.0, 9.9, 48.0),
		Vector3(-35.0, 9.9, 48.0), Vector3(0, 1.0, 0.2).normalized())
	for row in [101.0, 105.5]:
		for i in 19:
			LandmarkRmLKit.column_lite(lm, "Granite", Vector3(-23.4 + 46.8 * float(i) / 18.0, 0, float(row)), 0.5, 8.9)
		lm.box("Trim", Vector3(0, 9.35, float(row)), Vector3(54.0, 0.9, 1.2))
	for i in 20:
		LandmarkRmLKit.column_lite(lm, "Granite", Vector3(-23.75 + 47.5 * float(i) / 19.0, 0, 48.0), 0.5, 8.9)
	lm.box("Trim", Vector3(0, 9.35, 48.0), Vector3(54.0, 0.9, 1.2))
	# Entrance in the far wall and the statue of St Paul with his sword.
	lm.box("Shadow", Vector3(0, 3.5, 110.55), Vector3(4.0, 7.0, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(0, 0.4, 110.6), Vector3.RIGHT, Vector3(0, 0, 1), 4.0, 7.0, 1)
	lm.box("Marble", Vector3(0, 2.0, 77.0), Vector3(4.0, 4.0, 4.0))
	lm.box("Marble", Vector3(0, 4.15, 77.0), Vector3(4.4, 0.3, 4.4), Basis(), 0.0)
	lm.box("Marble", Vector3(0, 0.3, 77.0), Vector3(4.8, 0.6, 4.8), Basis(), 0.0)
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, 4.3, 77.0), 6.0, false)
	lm.beam("Marble", Vector3(0.7, 6.4, 77.6), Vector3(0.7, 4.6, 78.4), 0.12, 0.3)

## Poletti's campanile (65 m) behind the apse, centred on `c`.
static func _paul_campanile(lm: LandmarkMesh, c: Vector3) -> void:
	var tiers := [[0.0, 16.0, 5.5], [16.5, 13.0, 5.0], [30.0, 11.0, 4.6]]
	for t in tiers:
		var y0: float = t[0]
		var th: float = t[1]
		var hw: float = t[2]
		lm.box("Stone", c + Vector3(0, y0 + th * 0.5, 0), Vector3(hw * 2.0, th, hw * 2.0))
		lm.box("Trim", c + Vector3(0, y0 + th + 0.25, 0), Vector3(hw * 2.0 + 0.8, 0.5, hw * 2.0 + 0.8))
		for f in 4:
			var out := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
			var r := Vector3.UP.cross(out)
			for sd in [-1.0, 1.0]:
				LandmarkRmLKit.pilaster(lm, "Trim", c + out * hw + r * float(sd) * (hw - 0.6) + Vector3(0, y0, 0), r, out,
					0.9, th, 0.35)
			if y0 > 0.0:
				LandmarkRmLKit.arcade(lm, "Stone", "Shadow", c + out * (hw - 0.4) - r * (hw - 1.2) + Vector3(0, y0 + 0.6, 0),
					r, out, (hw - 1.2) * 2.0, th - 1.2, 1, hw * 0.75, th * 0.45, 0.4)
			else:
				lm.box("Shadow", c + out * (hw + 0.05) + Vector3(0, 10.0, 0), Vector3(1.6, 3.4, 0.1), Basis(r, Vector3.UP, out), 0.0)
				LandmarkRmLKit.frame_opening(lm, "Trim", c + out * (hw + 0.1) + Vector3(0, 8.3, 0), r, out, 1.6, 3.4, 1)
	# Octagonal stage ringed by columns, then the round tempietto.
	var oy := 41.5
	lm.frustum("Stone", c + Vector3(0, oy, 0), 3.6, 3.6, 8.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkRmLKit.column_lite(lm, "Trim", c + Vector3(cos(a) * 4.1, oy, sin(a) * 4.1), 0.32, 7.6)
	lm.frustum("Trim", c + Vector3(0, oy + 7.6, 0), 4.7, 4.7, 0.8, 8, PI / 8.0)
	var ty := oy + 8.4
	lm.frustum("Stone", c + Vector3(0, ty, 0), 2.6, 2.6, 6.0, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		LandmarkRmLKit.column_lite(lm, "Trim", c + Vector3(cos(a) * 3.0, ty, sin(a) * 3.0), 0.22, 5.6)
	lm.frustum("Trim", c + Vector3(0, ty + 5.6, 0), 3.4, 3.4, 0.6, 16)
	lm.lathe("Tile", c + Vector3(0, ty + 6.2, 0), PackedVector2Array([Vector2(3.2, 0.0), Vector2(2.2, 2.0),
		Vector2(1.0, 4.0), Vector2(0.3, 5.2)]), 16)
	SEuUtil.finial(lm, "Gold", c + Vector3(0, ty + 11.4, 0), 3.2)

# --- Santa Maria in Trastevere ----------------------------------------------------

## Origin at the middle of the church (56 x 30 m), facade facing +Z (east
## onto the piazza; yaw_deg turns it): Carlo Fontana's portico (1702)
## of five arches with a balustrade and four statues and its lean-to
## roof, over the 12th-century facade with the gold mosaic of the
## Madonna and the ten women with lamps, three arched windows and the
## gable; the nave and aisles under tile with their clerestory, the apse,
## the brick Romanesque campanile (31 m) with its mosaic niche beside
## the right aisle, and the octagonal fountain in the piazza.
static func trastevere(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#C9A877", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C8A7", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DFC8", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A06C4C", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	# Aisles, clerestory and roof; transept and apse.
	lm.box("Plaster", Vector3(0, 6.0, 2.0), Vector3(30.0, 12.0, 44.0))
	lm.box("Plaster", Vector3(0, 15.0, 2.0), Vector3(16.0, 6.0, 44.0))
	lm.gable("Tile", Vector3(0, 18.0, 2.0), 16.0, 44.0, 3.6, Basis(), 0.5, "Plaster")
	lm.box("Plaster", Vector3(0, 8.5, -24.0), Vector3(34.0, 17.0, 8.0))
	lm.gable("Tile", Vector3(0, 17.0, -24.0), 8.0, 34.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.4, "Plaster")
	lm.frustum("Plaster", Vector3(0, 0, -28.0), 6.5, 6.5, 14.0, 20)
	lm.lathe("Tile", Vector3(0, 14.0, -28.0), SEuUtil.dome(6.7, 2.6, 4), 20)
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		var r := Vector3.UP.cross(n)
		LandmarkRmLKit.arcade(lm, "Plaster", "Shadow", Vector3(s * 8.0, 12.6, 2.0) - r * 22.0, r, n, 44.0, 5.4, 8, 1.6, 2.4, 0.3, 0.8)
		LandmarkRmLKit.arcade(lm, "Plaster", "Shadow", Vector3(s * 15.0, 0.0, 2.0) - r * 22.0, r, n, 44.0, 11.4, 7, 1.8, 6.0, 0.3, 4.0)
		lm.quad("Tile", Vector3(s * 15.4, 12.0, 24.0), Vector3(s * 15.4, 12.0, -20.0), Vector3(s * 8.0, 12.9, -20.0),
			Vector3(s * 8.0, 12.9, 24.0), Vector3(s * 0.1, 1.0, 0).normalized())
		# Corbel frieze under the clerestory eaves.
		for k in 30:
			lm.box("Trim", Vector3(s * 8.35, 17.6, 23.0 - 1.4 * float(k)), Vector3(0.2, 0.3, 0.3), Basis(), 0.0)
	# The 12th-century facade over the portico.
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Plaster", Vector3(0, 11.0, 23.5), Vector3(30.0, 22.0, 1.0))
	lm.box("Trim", Vector3(0, 18.2, 24.1), Vector3(16.6, 0.5, 0.6))
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, 18.4, 23.0), r, n, 17.0, 3.6, 1.2, true)
	lm.box("Gold", Vector3(0, 16.0, 24.05), Vector3(15.6, 3.6, 0.1), Basis(), 0.0)
	for i in 11:
		LandmarkKits.statue_figure(lm, "Trim", Vector3(-7.0 + 1.4 * float(i), 14.4, 24.1), 2.6 if i == 5 else 2.2)
	LandmarkRmLKit.arcade(lm, "Plaster", "Shadow", Vector3(-6.0, 10.4, 24.0), r, n, 12.0, 3.4, 3, 1.4, 1.2, 0.3)
	LandmarkRmLKit.archivolts(lm, "Trim", Vector3(-6.0, 10.4, 24.0), r, n, 12.0, 3, 1.4, 1.2, 0.3, 0.25)
	lm.box("Gold", Vector3(0, 20.0, 24.1), Vector3(3.0, 2.4, 0.1), Basis(), 0.0)
	_trastevere_portico(lm)
	# Brick campanile with white cornice bands, mosaic niche, tiled spire.
	var tiers := PackedVector2Array([Vector2(9.0, 3.7), Vector2(3.8, 3.6), Vector2(3.8, 3.5),
		Vector2(3.8, 3.4), Vector2(3.4, 3.3)])
	var tb := Vector3(12.0, 0, 15.0)
	LandmarkRmLUtil.tower(lm, "Brick", tb, tiers, 29.7, "Tile")
	lm.disc("Gold", tb + Vector3(0, 25.4, 3.31), n, 0.7, 12)
	SEuUtil.finial(lm, "Gold", tb + Vector3(0, 29.7, 0), 1.3)
	# The octagonal fountain in the piazza.
	var fc := Vector3(0, 0, 52.0)
	for k in 3:
		lm.frustum("Stone", fc + Vector3(0, 0.3 * float(k), 0), 5.6 - 0.5 * float(k), 5.6 - 0.5 * float(k), 0.3, 8, PI / 8.0)
	lm.lathe("Stone", fc + Vector3(0, 0.9, 0), PackedVector2Array([Vector2(4.2, 0.0), Vector2(4.3, 0.8),
		Vector2(3.9, 0.8), Vector2(3.9, 0.3)]), 8, 1.0, 1.0, PI / 8.0, false, false)
	lm.disc("Water", fc + Vector3(0, 1.5, 0), Vector3.UP, 3.9, 8)
	lm.lathe("Stone", fc + Vector3(0, 0.9, 0), PackedVector2Array([Vector2(0.6, 0.0), Vector2(0.4, 1.4),
		Vector2(1.6, 2.0), Vector2(1.7, 2.3), Vector2(0.3, 2.4), Vector2(0.3, 3.4), Vector2(0.9, 3.8),
		Vector2(0.95, 4.0), Vector2(0.0, 4.4)]), 12)
	for k in 4:
		var a := PI * 0.5 * float(k)
		lm.lathe("Stone", fc + Vector3(cos(a) * 1.9, 2.3, sin(a) * 1.9), SEuUtil.dome(0.5, 0.4, 3), 8)
	lm.commit(model)

## Fontana's portico: five arches on granite piers, 24 m wide, 9.6 m
## high, a balustrade with four statues and a tiled lean-to behind it.
static func _trastevere_portico(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, 9.0, 26.0), Vector3(26.0, 1.4, 6.0))
	lm.box("Shadow", Vector3(0, 4.0, 24.05), Vector3(24.0, 8.0, 0.1), Basis(), 0.0)
	var o := Vector3(-13.0, 0, 28.0)
	LandmarkRmLKit.arcade(lm, "Stone", "Shadow", o, r, n, 26.0, 8.3, 5, 3.6, 4.4, 1.0)
	LandmarkRmLKit.archivolts(lm, "Trim", o, r, n, 26.0, 5, 3.6, 4.4, 1.0, 0.35)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 12.5, 4.15, 26.0), Vector3(1.0, 8.3, 4.0))
	for i in 6:
		var x := -13.0 + 26.0 / 5.0 * float(i)
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(x, 0, 29.0), r, n, 0.9, 8.3, 0.35)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-13.4, 8.3, 29.0), Vector3(13.4, 8.3, 29.0), n, 1.4, 0.6)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-13.0, 9.7, 29.2), Vector3(13.0, 9.7, 29.2), 1.1, 26.0 / 5.0)
	for i in 4:
		var x := -13.0 + 26.0 / 5.0 * float(i + 1)
		LandmarkKits.statue_figure(lm, "Trim", Vector3(x, 10.8, 29.2), 2.8, i % 2 == 0)
	lm.quad("Tile", Vector3(-13.0, 10.2, 28.6), Vector3(13.0, 10.2, 28.6), Vector3(13.0, 12.2, 24.0),
		Vector3(-13.0, 12.2, 24.0), Vector3(0, 1.0, 0.4).normalized())
