class_name LandmarkParisChurches
extends RefCounted

## Notre-Dame de Paris in true metres, y = 0 at the parvis. (Sacré-Cœur
## is LandmarkSacreCoeur.)

## Notre-Dame (96 m to the tip of the flèche, 128 m long, 48 m across
## the transept): the 41 m west facade with its two 69 m towers, three
## recessed portals, the Gallery of Kings (28 statues), the 9.6 m west
## rose between twin lancets, the Gallery of the Virgin, the open Grand
## Gallery and the belfries with their 16 m lancets; the nave with
## double aisles, side chapels, clerestory lancets and 15 m flying
## buttresses with pinnacles; the 13 m transept roses; the chevet's
## radiating flyers; and Viollet-le-Duc's oak and lead flèche with its
## sixteen copper apostles and evangelists. Nave along X, facade west (-X).
static func notre_dame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C4B493", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6F767A", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Copper", LandmarkMaterials.paint("#6E9C8A", 0.55, 0.4))
	var rot := Basis(Vector3.UP, PI * 0.5)
	_nd_body(lm, rot)
	_nd_facade(lm)
	_nd_fleche(lm)
	lm.commit(model)

## Nave, aisles, chapels, transept and chevet with their windows and
## buttressing.
static func _nd_body(lm: LandmarkMesh, rot: Basis) -> void:
	# Aisles (20 m) and clerestory (to 30 m) with the 43 m lead roof.
	LandmarkWestKit.blk(lm, "Stone", -5.0, 0.0, 0.0, 90.0, 20.0, 40.0)
	LandmarkWestKit.blk(lm, "Lead", -5.0, 20.0, 0.0, 88.0, 0.8, 38.0)
	LandmarkWestKit.blk(lm, "Stone", -5.0, 20.0, 0.0, 90.0, 10.0, 17.0)
	lm.gable("Lead", Vector3(-5.0, 30.0, 0), 17.0, 90.0, 13.0, rot, 0.8, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.rail(lm, "Stone", Vector3(-49.0, 30.0, sz * 8.8), Vector3(39.0, 30.0, sz * 8.8), 1.0)
		LandmarkWestKit.rail(lm, "Stone", Vector3(-49.0, 20.8, sz * 20.2), Vector3(39.0, 20.8, sz * 20.2), 0.9)
	# Ridge cresting.
	for k in 44:
		lm.box("Lead", Vector3(-49.0 + 2.0 * float(k), 43.3, 0), Vector3(0.25, 0.9, 0.25), Basis(), 0.0)
	# Chevet: aisle ring, clerestory half-round, lead half-cone.
	lm.lathe("Stone", Vector3(40, 0, 0), PackedVector2Array([Vector2(20, 0), Vector2(20, 20)]), 16,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(40, 20, 0), PackedVector2Array([Vector2(19.5, 0), Vector2(19.5, 0.8)]), 16)
	lm.lathe("Stone", Vector3(40, 20, 0), PackedVector2Array([Vector2(8.5, 0), Vector2(8.5, 10)]), 10,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(40, 30, 0), PackedVector2Array([Vector2(9.4, 0), Vector2(0.4, 13)]), 10,
		1.0, 1.0, 0.0, false)
	# Transept (48 m) with its gables, 13 m roses, portals and corner pinnacles.
	LandmarkWestKit.blk(lm, "Stone", 4.0, 0.0, 0.0, 17.0, 30.0, 48.0)
	lm.gable("Lead", Vector3(4.0, 30.0, 0), 17.0, 48.0, 13.0, Basis(), 0.8, "Stone")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var f := Vector3(4.0, 0, sz * 24.0)
		LandmarkWestKit.rose(lm, "Stone", "Glass", f + Vector3(0, 21.5, sz * 0.1), n, 6.4, 16)
		for k in 7:
			LandmarkWestKit.lancet(lm, "Stone", "Glass", f + Vector3(-6.0 + 2.0 * float(k), 12.0, 0), n, 1.3, 3.4, false)
		LandmarkWestKit.portal(lm, "Stone", "Lead", f, n, 4.6, 10.5, 4, true)
		lm.gable("Stone", f + Vector3(0, 10.5, sz * 1.8), 8.0, 1.2, 4.6, Basis(), 0.1)
		LandmarkWestKit.rose(lm, "Stone", "Glass", f + Vector3(0, 34.5, sz * 0.15), n, 2.2, 8)
		for sx in [-1.0, 1.0]:
			LandmarkWestKit.buttress(lm, "Stone", f + Vector3(sx * 8.5, 0, 0), n, 2.0, 2.4, 28.0, 2)
			LandmarkWestKit.pinnacle(lm, "Stone", f + Vector3(sx * 8.5, 28.0, sz * 0.6), 1.0, 11.0)
	# Nave bays: chapel lancets, clerestory lancets, piers, pinnacles, flyers.
	for k in 11:
		var x := -46.0 + 8.4 * float(k)
		for sz in [-1.0, 1.0]:
			var n := Vector3(0, 0, sz)
			if absf(x - 4.0) > 9.0:
				LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x + 4.2, 4.0, sz * 20.0), n, 3.2, 11.0, true)
				LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x + 4.2, 21.5, sz * 8.5), n, 3.0, 7.5, true)
				lm.gable("Lead", Vector3(x + 4.2, 19.8, sz * 19.0), 6.0, 2.4, 2.2, Basis(), 0.0, "Stone")
			lm.box("Stone", Vector3(x, 12.0, sz * 20.9), Vector3(1.8, 24.0, 1.8))
			LandmarkWestKit.pinnacle(lm, "Stone", Vector3(x, 24.0, sz * 20.9), 0.9, 6.5)
			LandmarkWestKit.flyer(lm, "Stone", Vector3(x, 24.5, sz * 20.0), Vector3(x, 28.5, sz * 8.6), 1.0)
	# Chevet: clerestory lancets and the radiating flyers round the apse.
	for k in 9:
		var a := -PI * 0.5 + PI * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := Vector3(40, 0, 0) + d * 22.5
		lm.box("Stone", p + Vector3(0, 12.0, 0), Vector3(2.0, 24.0, 2.0), Basis(Vector3.UP, -a))
		LandmarkWestKit.pinnacle(lm, "Stone", p + Vector3(0, 24.0, 0), 1.0, 7.0)
		LandmarkWestKit.flyer(lm, "Stone", p + Vector3(0, 24.5, 0) - d * 1.0, Vector3(40, 28.5, 0) + d * 8.6, 1.0, 6)
		if k < 8:
			var a2 := a + PI / 16.0
			var d2 := Vector3(cos(a2), 0, sin(a2))
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(40, 21.5, 0) + d2 * 8.55, d2, 2.4, 7.0, false)
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(40, 5.0, 0) + d2 * 20.05, d2, 3.0, 10.0, true)

## West facade: towers, portals, kings, rose, galleries and belfries.
static func _nd_facade(lm: LandmarkMesh) -> void:
	var w := Vector3(-1, 0, 0)
	for sz in [-1.0, 1.0]:
		var tz: float = sz * 13.4
		LandmarkWestKit.blk(lm, "Stone", -57.0, 0.0, tz, 14.0, 67.5, 14.0)
		LandmarkWestKit.blk(lm, "Stone", -57.0, 45.0, tz, 14.6, 0.8, 14.6)
		LandmarkWestKit.blk(lm, "Stone", -57.0, 66.7, tz, 14.8, 0.8, 14.8)
		# Twin lancets flanking the rose, and the belfry lancets on all faces.
		for wz in [-3.0, 3.0]:
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(-64.0, 25.5, tz + wz), w, 2.2, 9.5, true)
		for s in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(s))
			var n: Vector3 = b * Vector3(-1, 0, 0)
			for wz in [-2.6, 2.6]:
				var c: Vector3 = Vector3(-57.0, 48.5, tz) + n * 7.0 + b * Vector3(0, 0, wz)
				LandmarkWestKit.lancet(lm, "Stone", "Glass", c, n, 2.4, 16.0, true)
		# Openwork parapet and corner turrets on the tower top.
		var t0 := Vector3(-57.0, 67.5, tz)
		var cs: Array[Vector3] = [Vector3(-7, 0, -7), Vector3(7, 0, -7), Vector3(7, 0, 7), Vector3(-7, 0, 7)]
		for i in 4:
			LandmarkWestKit.rail(lm, "Stone", t0 + cs[i], t0 + cs[(i + 1) % 4], 1.4, 0.9)
			LandmarkWestKit.blk(lm, "Stone", t0.x + cs[i].x, 67.5, t0.z + cs[i].z, 1.4, 1.4, 1.4)
	LandmarkWestKit.blk(lm, "Stone", -57.0, 0.0, 0.0, 14.0, 44.0, 13.0)
	# Facade buttresses up to the tower tops.
	for pz in [-20.2, -6.4, 6.4, 20.2]:
		LandmarkWestKit.buttress(lm, "Stone", Vector3(-64.0, 0, pz), w, 2.0, 1.8, 45.0, 2)
		LandmarkWestKit.blk(lm, "Stone", -64.4, 45.0, pz, 0.9, 21.0, 1.6)
	# Three portals: Virgin (north), Last Judgement (centre), St Anne (south).
	for pc in [[-12.8, 5.0, 12.0], [0.0, 6.4, 14.0], [12.8, 5.0, 12.0]]:
		LandmarkWestKit.portal(lm, "Stone", "Lead", Vector3(-64.0, 0, float(pc[0])), w, float(pc[1]), float(pc[2]), 5, true)
	# Gallery of Kings: 28 statues on their ledge under an arcade.
	LandmarkWestKit.blk(lm, "Stone", -64.9, 19.0, 0, 1.8, 0.6, 41.0)
	LandmarkWestKit.blk(lm, "Stone", -64.6, 23.6, 0, 1.2, 0.5, 41.0)
	for k in 28:
		var z := -19.3 + 38.6 * float(k) / 27.0
		LandmarkWestKit.figure(lm, "Stone", Vector3(-64.7, 19.6, z), 3.2)
		lm.box("Stone", Vector3(-64.6, 21.4, z + 0.69), Vector3(0.6, 3.6, 0.22), Basis(), 0.0)
	# Gallery of the Virgin balustrade and the west rose (9.6 m).
	LandmarkWestKit.rail(lm, "Stone", Vector3(-65.0, 24.1, -20.4), Vector3(-65.0, 24.1, 20.4), 1.2, 0.8)
	LandmarkWestKit.rose(lm, "Stone", "Glass", Vector3(-64.1, 30.5, 0), w, 4.8, 12)
	for k in 3:
		LandmarkKits.statue_figure(lm, "Stone", Vector3(-64.8, 24.2, -2.5 + 2.5 * float(k)), 3.6)
	# Grand Gallery: open arcade of colonnettes with pointed heads.
	for k in 34:
		var z := -20.0 + 40.0 * float(k) / 33.0
		lm.frustum("Stone", Vector3(-64.5, 38.0, z), 0.22, 0.2, 5.0, 6)
		if k < 33:
			var z1 := -20.0 + 40.0 * float(k + 1) / 33.0
			var pts := LandmarkWestKit.pointed_pts(z1 - z, 2)
			for i in pts.size() - 1:
				lm.beam("Stone", Vector3(-64.5, 43.0 + pts[i].y, (z + z1) * 0.5 + pts[i].x),
					Vector3(-64.5, 43.0 + pts[i + 1].y, (z + z1) * 0.5 + pts[i + 1].x), 0.18, 0.3)
	LandmarkWestKit.blk(lm, "Stone", -64.5, 37.4, 0, 1.4, 0.6, 41.0)
	LandmarkWestKit.blk(lm, "Stone", -64.5, 44.4, 0, 1.4, 0.6, 41.0)
	LandmarkWestKit.rail(lm, "Stone", Vector3(-64.6, 45.0, -6.4), Vector3(-64.6, 45.0, 6.4), 1.3, 0.8)

## The flèche over the crossing (96 m) and the copper apostles.
static func _nd_fleche(lm: LandmarkMesh) -> void:
	var c := Vector3(4.0, 0, 0)
	lm.lathe("Lead", c + Vector3(0, 36, 0), PackedVector2Array([Vector2(5.2, 0), Vector2(5.2, 10)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, -a + PI * 0.5)
		lm.gable("Lead", c + Vector3(0, 46.0, 0) + d * 4.6, 3.8, 0.8, 3.4, b, 0.1)
		var a2 := a + PI / 8.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		LandmarkWestKit.pinnacle(lm, "Lead", c + Vector3(0, 46.0, 0) + d2 * 5.3, 0.45, 7.5)
		lm.box("Glass", c + Vector3(0, 41.5, 0) + d * 4.82, Vector3(1.6, 6.0, 0.1), b, 0.0)
	# Open lantern stage: eight colonnettes round the core.
	lm.frustum("Lead", c + Vector3(0, 46.0, 0), 4.4, 3.6, 10.0, 8, PI / 8.0)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		lm.frustum("Lead", c + Vector3(0, 46.0, 0) + Vector3(cos(a), 0, sin(a)) * 4.3, 0.22, 0.2, 10.0, 6)
	lm.frustum("Lead", c + Vector3(0, 56.0, 0), 4.0, 3.9, 0.8, 8, PI / 8.0)
	# Needle with crockets on its eight arrises.
	var needle := PackedVector2Array([Vector2(3.6, 0), Vector2(2.4, 12), Vector2(1.2, 26), Vector2(0.45, 34),
		Vector2(0.0, 39.2)])
	lm.lathe("Lead", c + Vector3(0, 56.8, 0), needle, 8, 1.0, 1.0, PI / 8.0, false)
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 9:
			var y := 2.0 + 3.6 * float(j)
			var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 3.6), Vector2(12, 2.4),
				Vector2(26, 1.2), Vector2(34, 0.45)]), y) / cos(PI / 8.0)
			lm.box("Lead", c + Vector3(0, 56.8 + y, 0) + d * (rr + 0.15), Vector3(0.5, 0.35, 0.3),
				Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Gilt", c + Vector3(0, 90.5, 0), LandmarkWestKit.ball(0.45), 8)
	LandmarkWestKit.cross(lm, "Gilt", c + Vector3(0, 91.4, 0), 4.0)
	lm.box("Gilt", c + Vector3(0, 95.6, 0), Vector3(0.8, 0.8, 0.25), Basis(), 0.0)
	# Apostles and evangelist symbols stepping down the four roof ridges.
	for arm in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(arm))
		for k in 4:
			var p: Vector3 = c + b * Vector3(7.0 + 2.2 * float(k), 0, 0)
			var y := 42.0 - 0.9 * float(k)
			lm.box("Lead", p + Vector3(0, y + 0.3, 0), Vector3(1.4, 0.6, 1.4))
			LandmarkWestKit.figure(lm, "Copper", p + Vector3(0, y + 0.6, 0), 3.4)
