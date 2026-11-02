class_name SEuAlhambra
extends RefCounted

## The Alhambra and the Parthenon in true metres.

# --- Alhambra ---------------------------------------------------------------

## The Nasrid palaces of the Alhambra on the Sabika hill, origin at the
## Comares Tower: the 45 m crenellated tower over the north wing, the
## Court of the Myrtles pool with its galleries, the Court of the Lions
## to the east, Charles V's square Renaissance palace with its round
## court to the south and, drawn closer than it stands, the Alcazaba
## fort with the Torre de la Vela to the west. Walls are the red-ochre
## rammed earth that gave the hill its name; foundations drop 14 m for
## the slope.
static func alhambra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#B98859", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A5583A", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBB9B", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#473F35", 3.0))
	lm.use("Water", LandmarkMaterials.glass("#2C6670"))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E2D3B2", 2.0))
	# Comares Tower: shaft, upper stage, merlons and a pitched cap.
	lm.box("Wall", Vector3(0, 14.0, 0), Vector3(24.0, 56.0, 24.0))
	lm.box("Wall", Vector3(0, 41.0, 0), Vector3(25.0, 1.4, 25.0))
	lm.box("Wall", Vector3(0, 42.2, 0), Vector3(21.0, 4.0, 21.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", out * 12.0, right, out, 12.0, 2, 8.0, 1.6, 4.4, true)
		SEuUtil.face_row(lm, "Shadow", out * 12.0, right, out, 24.0, 3, 6.0, 1.4, 3.6, true)
		SEuUtil.face_row(lm, "Trim", out * 10.5, right, out, 41.0, 2, 8.0, 1.8, 3.0, true)
		SEuUtil.crenels(lm, "Wall", out * 10.5 - right * 10.5 + Vector3(0, 44.0, 0),
			out * 10.5 + right * 10.5 + Vector3(0, 44.0, 0), 0.7, 1.0, 0.8)
	# Nasrid palace wings round the Myrtles and Lions courts.
	for wing in [[Vector3(-22.0, 0, 28.0), Vector3(8.0, 10.0, 40.0)],
			[Vector3(22.0, 0, 28.0), Vector3(8.0, 10.0, 40.0)],
			[Vector3(0, 0, 50.0), Vector3(52.0, 12.0, 8.0)],
			[Vector3(50.0, 0, 28.0), Vector3(36.0, 9.0, 8.0)],
			[Vector3(50.0, 0, 58.0), Vector3(36.0, 9.0, 8.0)],
			[Vector3(70.0, 0, 43.0), Vector3(8.0, 9.0, 30.0)]]:
		var c: Vector3 = wing[0]
		var s: Vector3 = wing[1]
		lm.box("Wall", c + Vector3(0, s.y * 0.5, 0), s)
		lm.gable("Tile", c + Vector3(0, s.y, 0), s.x if s.x < s.z else s.z, maxf(s.x, s.z),
			1.8, Basis() if s.z > s.x else Basis(Vector3.UP, PI * 0.5), 0.5)
		SEuUtil.face_row(lm, "Shadow", c + Vector3(0, 0, s.z * 0.5) , Vector3.RIGHT, Vector3(0, 0, 1),
			2.0, maxi(int(s.x / 5.0), 1), 4.8, 1.3, 4.0, true)
	lm.box("Water", Vector3(0, 0.15, 30.0), Vector3(12.0, 0.3, 36.0))
	lm.box("Stone", Vector3(50.0, 0.4, 43.0), Vector3(6.0, 0.8, 6.0))
	# Palace of Charles V: four wings round the circular court.
	var pc := Vector3(-10.0, 0, 112.0)
	for wing in [[Vector3(0, 0, -23.5), Vector3(63.0, 17.0, 16.0)], [Vector3(0, 0, 23.5), Vector3(63.0, 17.0, 16.0)],
			[Vector3(-23.5, 0, 0), Vector3(16.0, 17.0, 31.0)], [Vector3(23.5, 0, 0), Vector3(16.0, 17.0, 31.0)]]:
		var s2: Vector3 = wing[1]
		lm.box("Stone", pc + wing[0] + Vector3(0, s2.y * 0.5, 0), s2)
	lm.box("Trim", pc + Vector3(0, 8.7, 31.9), Vector3(64.0, 0.8, 1.2))
	SEuUtil.face_row(lm, "Shadow", pc + Vector3(0, 0, 31.5), Vector3.RIGHT, Vector3(0, 0, 1), 1.0, 9, 6.6, 2.0, 5.6)
	SEuUtil.face_row(lm, "Shadow", pc + Vector3(0, 0, 31.5), Vector3.RIGHT, Vector3(0, 0, 1), 10.0, 9, 6.6, 1.6, 4.8)
	SEuUtil.face_row(lm, "Shadow", pc + Vector3(0, 0, -31.5), Vector3.RIGHT, Vector3(0, 0, -1), 1.0, 9, 6.6, 2.0, 5.6)
	SEuUtil.face_row(lm, "Shadow", pc + Vector3(0, 0, -31.5), Vector3.RIGHT, Vector3(0, 0, -1), 10.0, 9, 6.6, 1.6, 4.8)
	# Alcazaba: curtain wall with towers, keep and the Torre de la Vela.
	var ac := Vector3(-128.0, 0, 30.0)
	for e in [[Vector3(0, 0, -20.0), Vector3(54.0, 10.0, 2.5)], [Vector3(0, 0, 20.0), Vector3(54.0, 10.0, 2.5)],
			[Vector3(-26.0, 0, 0), Vector3(2.5, 10.0, 40.0)], [Vector3(26.0, 0, 0), Vector3(2.5, 10.0, 40.0)]]:
		var es: Vector3 = e[1]
		lm.box("Wall", ac + e[0] + Vector3(0, es.y * 0.5 - 4.0, 0), es + Vector3(0, 8.0, 0))
	for t in [[Vector3(-26.0, 0, -20.0), 22.0], [Vector3(26.0, 0, -20.0), 22.0], [Vector3(26.0, 0, 20.0), 20.0],
			[Vector3(0, 0, -20.0), 20.0], [Vector3(0, 0, 20.0), 18.0], [Vector3(-26.0, 0, 20.0), 27.0]]:
		var tp: Vector3 = ac + (t[0] as Vector3)
		var th: float = t[1]
		var big := th > 26.0
		var tw := 10.0 if big else 7.0
		lm.box("Wall", tp + Vector3(0, th * 0.5 - 4.0, 0), Vector3(tw, th + 4.0, tw))
		SEuUtil.crenels(lm, "Wall", tp + Vector3(-tw * 0.5, th, tw * 0.5), tp + Vector3(tw * 0.5, th, tw * 0.5), 0.6, 1.2, 0.8)
		SEuUtil.crenels(lm, "Wall", tp + Vector3(-tw * 0.5, th, -tw * 0.5), tp + Vector3(tw * 0.5, th, -tw * 0.5), 0.6, 1.2, 0.8)
	lm.commit(model)

# --- Parthenon -----------------------------------------------------------------

## The Doric temple of Athena on the Acropolis, origin at its centre, front
## to the east (+X), y = 0 the stylobate (the three steps drop below):
## 8 x 17 fluted columns of Pentelic marble under the architrave, frieze
## and cornice, both pediments and the roofless cella walls as they stand
## today; 17.1 m from stylobate to pediment apex.
static func parthenon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D6BE", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BB93", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#6A5F52", 2.5))
	for k in 3:
		var g := 0.5 * float(k + 1)
		lm.box("Marble", Vector3(0, -0.55 * float(k) - 0.275, 0), Vector3(69.5 + g * 2.0, 0.55, 30.9 + g * 2.0))
	lm.box("Marble", Vector3(0, -1.9, 0), Vector3(74.0, 1.0, 35.0))
	var h := 10.43
	for i in 17:
		var x := -33.2 + 4.15 * float(i)
		for s in [-1.0, 1.0]:
			_column(lm, Vector3(x, 0, s * 14.2), h)
	for i in range(1, 7):
		var z := -14.2 + 28.4 * float(i) / 7.0
		for s in [-1.0, 1.0]:
			_column(lm, Vector3(s * 33.2, 0, z), h)
	# Entablature ring: architrave, triglyph frieze, cornice.
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, h + 0.7, s * 14.2), Vector3(69.0, 1.4, 2.3))
		lm.box("Honey", Vector3(0, h + 2.0, s * 14.2), Vector3(69.2, 1.3, 2.3))
		lm.box("Marble", Vector3(0, h + 3.1, s * 14.4), Vector3(70.2, 0.9, 3.0))
		lm.box("Marble", Vector3(s * 33.2, h + 0.7, 0), Vector3(2.3, 1.4, 28.5))
		lm.box("Honey", Vector3(s * 33.2, h + 2.0, 0), Vector3(2.3, 1.3, 28.6))
		lm.box("Marble", Vector3(s * 33.4, h + 3.1, 0), Vector3(3.0, 0.9, 30.2))
		for k in 47:
			var t := -33.2 + 66.4 * float(k) / 46.0
			lm.box("Shadow", Vector3(t, h + 2.0, s * 15.4), Vector3(0.45, 1.1, 0.2))
	# Pediments (tympanum between raking cornices) at both ends.
	for s in [-1.0, 1.0]:
		lm.gable("Marble", Vector3(s * 33.4, h + 3.55, 0), 30.4, 1.4, 3.1, Basis(Vector3.UP, PI * 0.5), 0.0, "Honey")
	# Cella: roofless walls with the porch columns of the east room.
	for e in [[Vector3(0, 0, 9.6), Vector3(59.0, 10.0, 1.6)], [Vector3(0, 0, -9.6), Vector3(59.0, 10.0, 1.6)],
			[Vector3(29.5, 0, 0), Vector3(1.6, 10.0, 19.2)], [Vector3(-29.5, 0, 0), Vector3(1.6, 10.0, 19.2)],
			[Vector3(-10.0, 0, 0), Vector3(1.6, 10.0, 19.2)]]:
		var es: Vector3 = e[1]
		lm.box("Honey", (e[0] as Vector3) + Vector3(0, es.y * 0.5, 0), es)
	lm.commit(model)

## One fluted Doric column: tapering shaft, echinus and abacus.
static func _column(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.frustum("Marble", base, 0.95, 0.77, h - 0.6, 12)
	lm.frustum("Marble", base + Vector3(0, h - 0.6, 0), 0.77, 1.05, 0.4, 12)
	lm.box("Marble", base + Vector3(0, h - 0.1, 0), Vector3(2.1, 0.2, 2.1))
