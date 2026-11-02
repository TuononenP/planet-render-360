class_name LandmarkRmAImperial
extends RefCounted

## Imperial ruins of the Forum quarter in true metres: the Basilica of
## Maxentius, the Palatine palace (Domus Flavia and Augustana) and
## Trajan's Markets with the Torre delle Milizie.

# --- Basilica of Maxentius ----------------------------------------------

## The north aisle of the Basilica Nova, built along X with the three
## arches open to +Z (the vanished nave): three coffered concrete barrel
## vaults of 20.5 m span and 24.5 m crown height on 5.9 m brick piers,
## the windowed north wall, and the stumps of the nave's groin vaults.
static func basilica(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6B4D", 2.5))
	lm.use("Vault", LandmarkMaterials.pbr("concrete", "#958B79", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	var half := 42.55
	var centres := [-26.4, 0.0, 26.4]
	var opens: Array = []
	for cx in centres:
		opens.append([float(cx), 20.5, 14.0, 9.5])
	# Front face of the aisle: arch heads over the nave side, then the vaults.
	RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(0, 0, 12.25), Vector3.RIGHT, Vector3.BACK,
		-half, half, 0.0, 24.5, opens, 1.0, 12)
	for cx in centres:
		RmAUtil.barrel_vault(lm, "Vault", "Shadow", Vector3(float(cx), 14.0, 11.25), Vector3(0, 0, -1),
			Vector3.RIGHT, 24.5, 20.5, 9.5, 1.0, 5, 5, 12)
	for px in [-39.6, -13.2, 13.2, 39.6]:
		lm.box("Brick", Vector3(float(px), 12.25, -1.0), Vector3(5.9, 24.5, 24.5))
	# North wall with its tall arched windows, the buttress ribs behind it.
	RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(0, 0, -12.25), Vector3.RIGHT, Vector3.FORWARD,
		-half, half, 0.0, 24.5, [[-26.4, 7.0, 12.0, 0.0], [0.0, 7.0, 12.0, 0.0], [26.4, 7.0, 12.0, 0.0]], 1.9, 10)
	for px in [-39.6, -13.2, 13.2, 39.6]:
		lm.box("Brick", Vector3(float(px), 9.0, -16.0), Vector3(3.6, 18.0, 6.0))
	# Stumps of the nave piers and groin vault springers on the open side.
	for px in [-39.6, -13.2, 13.2, 39.6]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(float(px), 0, 12.25), Vector3(float(px), 0, 20.0), 4.2, 0.0, 6.0, 15.0, 3.9, px)
	lm.commit(model)

# --- Palatine palace ------------------------------------------------------

## The imperial palace on the Palatine, compact on the summit (foundations
## sunk below y = 0): the Domus Flavia's grassed peristyle with its
## octagonal fountain ring, the broken walls and apse of the Aula Regia
## to the north, the triclinium with two oval nymphaea to the south and,
## over the Circus Maximus, the two-storey brick arcades of the Domus
## Augustana. Aula Regia's flank wall stands highest at 16 m.
static func palatine(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6B4D", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#968B78", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D2C9B6", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4338", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6B7A47", 4.0))
	lm.box("Concrete", Vector3(0, -7.05, -4.0), Vector3(50.0, 13.9, 90.0))
	lm.box("Lawn", Vector3(0, 0.1, -4.0), Vector3(29.0, 0.2, 33.0))
	# Peristyle: broken outer walls and the stumps of the portico columns.
	var corners := [Vector3(-16, 0, -22), Vector3(16, 0, -22), Vector3(16, 0, 14), Vector3(-16, 0, 14)]
	for i in 4:
		RmAUtil.ruin_wall(lm, "Brick", corners[i], corners[(i + 1) % 4], 1.5, 0.0, 1.5, 5.0, 2.6, float(i))
	for i in 9:
		for sx in [-13.4, 13.4]:
			var f := absf(sin(float(i) * 3.1 + sx))
			lm.frustum("Marble", Vector3(sx, 0, -19.0 + 4.1 * float(i)), 0.55, 0.5, 0.8 + 2.4 * f, 8)
	# Octagonal fountain: two concentric broken rings.
	for rr in [7.0, 4.6]:
		for i in 8:
			var a0 := TAU * float(i) / 8.0 + PI / 8.0
			var a1 := TAU * float(i + 1) / 8.0 + PI / 8.0
			RmAUtil.seg_box(lm, "Brick", Vector3(cos(a0) * rr, 0, -4.0 + sin(a0) * rr),
				Vector3(cos(a1) * rr, 0, -4.0 + sin(a1) * rr), 0.7, 0.0, 1.1)
	# Aula Regia: flank walls, the apse and the tall standing fragment.
	RmAUtil.ruin_wall(lm, "Brick", Vector3(-11.0, 0, -22.0), Vector3(-11.0, 0, -36.0), 3.0, 0.0, 8.0, 15.0, 2.8, 1.0)
	RmAUtil.ruin_wall(lm, "Brick", Vector3(11.0, 0, -22.0), Vector3(11.0, 0, -36.0), 3.0, 0.0, 6.0, 13.0, 2.8, 2.0)
	lm.box("Brick", Vector3(-11.0, 8.0, -23.6), Vector3(3.0, 16.0, 3.2))
	for i in 10:
		var a := PI * (float(i) + 0.5) / 10.0
		var f := absf(sin(float(i) * 7.7 + 3.0))
		lm.box("Brick", Vector3(cos(a) * 9.5, (6.0 + 6.0 * f) * 0.5, -36.0 - sin(a) * 9.5),
			Vector3(3.0, 6.0 + 6.0 * f, 6.2), Basis(Vector3.UP, a))
	# Triclinium (south of the peristyle) and its two oval nymphaea.
	RmAUtil.ruin_wall(lm, "Brick", Vector3(-9.0, 0, 14.0), Vector3(-9.0, 0, 26.0), 2.4, 0.0, 5.0, 10.0, 2.4, 3.0)
	RmAUtil.ruin_wall(lm, "Brick", Vector3(9.0, 0, 14.0), Vector3(9.0, 0, 26.0), 2.4, 0.0, 5.0, 10.0, 2.4, 4.0)
	for sx in [-16.5, 16.5]:
		for i in 12:
			var a := TAU * float(i) / 12.0
			var f := absf(sin(float(i) * 5.3 + sx))
			lm.box("Brick", Vector3(sx + cos(a) * 5.2, (2.0 + 4.0 * f) * 0.5, 21.0 + sin(a) * 5.2),
				Vector3(1.5, 2.0 + 4.0 * f, 3.4), Basis(Vector3.UP, -a))
	# Domus Augustana: two stepped brick arcades facing the Circus Maximus.
	lm.box("Brick", Vector3(0, 3.8, 29.4), Vector3(44.0, 7.6, 1.3))
	RmAUtil.arcade(lm, "Brick", "Shadow", Vector3(-22.0, 0, 36.0), Vector3(22.0, 0, 36.0), Vector3.BACK,
		8, 0.0, 7.5, 0.58, 0.5, 6.0)
	lm.box("Brick", Vector3(0, 10.9, 28.4), Vector3(39.0, 6.5, 1.3))
	RmAUtil.arcade(lm, "Brick", "Shadow", Vector3(-19.5, 7.5, 31.0), Vector3(19.5, 7.5, 31.0), Vector3.BACK,
		7, 0.0, 6.5, 0.5, 0.45, 2.6)
	for sx in [-22.0, 22.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx, 0, 30.0), Vector3(sx, 0, 14.0), 1.8, 0.0, 6.5, 8.0, 2.8, sx)
	lm.commit(model)

# --- Trajan's Markets ---------------------------------------------------------

## The brick hemicycle in four stepped tiers cut into the Quirinal (tabernae,
## pedimented gallery windows, the Via Biberatica tier and the parapet),
## the Great Hall with its tall upper windows, and the Torre delle
## Milizie, the 42 m medieval keep (bands of tuff and brick, battlements).
## Origin between hemicycle and tower; elements set at their bearings.
static func markets(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A06B4A", 2.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4338", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8F5C43", 3.0))
	lm.use("Tuff", LandmarkMaterials.pbr("stone", "#A29476", 3.0))
	lm.place(-29.0, 30.0, 217.0)
	var tiers := [[21.0, 0.0, 5.4, 14, 0.5, 0.55], [25.6, 5.4, 10.8, 17, 0.4, 0.5],
		[30.2, 10.8, 16.2, 20, 0.4, 0.5], [34.8, 16.2, 19.6, 24, 0.3, 0.45]]
	for t in tiers:
		var r: float = t[0]
		RmAUtil.arc_arcade(lm, "Brick", "Shadow", Vector3.ZERO, r, -PI, 0.0, int(t[3]), float(t[1]),
			float(t[2]), float(t[4]), float(t[5]), 4.6, true, true)
		# Travertine cornice between the tiers.
		var n := int(t[3])
		for i in n:
			var a0 := -PI + PI * float(i) / float(n)
			var a1 := -PI + PI * float(i + 1) / float(n)
			var p0 := Vector3(cos(a0) * (r - 0.2), float(t[2]) - 0.25, sin(a0) * (r - 0.2))
			var p1 := Vector3(cos(a1) * (r - 0.2), float(t[2]) - 0.25, sin(a1) * (r - 0.2))
			lm.beam("Travertine", p0, p1, 0.5, 0.9, Vector3.UP)
			# Gallery windows (second tier) carry alternate pediments.
			if float(t[1]) == 5.4 and i % 2 == 0:
				var am := (a0 + a1) * 0.5
				var tang := Vector3(-sin(am), 0, cos(am))
				var inward := Vector3(-cos(am), 0, -sin(am))
				RmAUtil.pediment(lm, "Travertine", Vector3(cos(am) * (r - 0.1), 9.0, sin(am) * (r - 0.1)),
					tang, inward, 2.4, 0.7, 0.4)
	# Great Hall (Aula Traiana), its high windows over the road side.
	lm.box("Brick", Vector3(36.0, 9.0, -20.0), Vector3(12.0, 18.0, 30.0))
	lm.box("Brick", Vector3(36.0, 18.8, -20.0), Vector3(12.4, 1.2, 30.4))
	SEuUtil.face_row(lm, "Shadow", Vector3(36.0, 0, -5.0), Vector3.RIGHT, Vector3(0, 0, 1), 11.0, 3, 4.0, 2.4, 6.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(36.0, 0, -5.0), Vector3.RIGHT, Vector3(0, 0, 1), 3.0, 3, 4.0, 2.0, 4.5)
	# Torre delle Milizie.
	lm.place(36.5, -33.4, 180.0)
	var stages := [[15.0, 0.0, 13.0, "Tuff"], [13.2, 13.0, 27.0, "Brick"], [11.6, 27.0, 40.0, "Brick"]]
	for s in stages:
		var w: float = s[0]
		var y0: float = s[1]
		var y1: float = s[2]
		lm.box(str(s[3]), Vector3(0, (y0 + y1) * 0.5, 0), Vector3(w, y1 - y0, w))
		lm.box("Travertine", Vector3(0, y1 - 0.2, 0), Vector3(w + 0.6, 0.5, w + 0.6))
		for k in 4:
			var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
			var right := Vector3.UP.cross(out)
			for ox in [-2.1, 2.1]:
				SEuUtil.opening(lm, "Shadow", out * (w * 0.5 + 0.05) + right * float(ox) + Vector3(0, y0 + 4.5, 0),
					right, Vector3.UP, 1.4, 3.6)
	lm.box("Travertine", Vector3(0, 40.4, 0), Vector3(12.6, 0.8, 12.6))
	for k in 4:
		var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
		var right := Vector3.UP.cross(out)
		for m in 4:
			lm.box("Brick", out * 5.9 + right * (-4.2 + 2.8 * float(m)) + Vector3(0, 41.6, 0),
				Vector3(1.4, 1.6, 1.2), Basis(Vector3.UP, PI * 0.5 * float(k)))
	lm.commit(model)
