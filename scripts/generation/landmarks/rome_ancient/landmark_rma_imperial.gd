class_name LandmarkRmAImperial
extends RefCounted

## Imperial ruins of the Forum quarter in true metres: the Basilica of
## Maxentius, the Palatine palace (Domus Flavia and Augustana) and
## Trajan's Markets with the Torre delle Milizie.

# --- Basilica of Maxentius ----------------------------------------------

## The north aisle of the Basilica Nova (AD 308-312), built along X with
## the three arches open to +Z (the vanished nave): three coffered
## concrete barrel vaults of 20.5 m span and 24.5 m crown height on
## brick piers pierced by the arched passages that join the bays; the
## north wall with two tiers of three arched windows in the side bays
## and, in the middle bay, Constantine's apse with its two tiers of
## statue niches under a half-dome; the buttresses behind; on the nave
## side the stumps of the piers that carried the groin vaults and the
## bases of the 14.5 m Proconnesian columns that stood before them.
static func basilica(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6B4D", 2.5))
	lm.use("Vault", LandmarkMaterials.pbr("concrete", "#958B79", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D2C9B6", 3.0))
	var half := 42.55
	var centres := [-26.4, 0.0, 26.4]
	var opens: Array = []
	for cx in centres:
		opens.append([float(cx), 20.5, 14.0, 9.5])
	# Front face of the aisle: arch heads over the nave side, then the vaults.
	RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(0, 0, 12.25), Vector3.RIGHT, Vector3.BACK,
		-half, half, 0.0, 24.5, opens, 1.0, 16)
	for cx in centres:
		RmAUtil.barrel_vault(lm, "Vault", "Shadow", Vector3(float(cx), 14.0, 11.25), Vector3(0, 0, -1),
			Vector3.RIGHT, 22.5, 20.5, 9.5, 1.0, 9, 8, 16)
	# Piers: the end walls solid, the inner two pierced by passages.
	for px in [-39.6, 39.6]:
		lm.box("Brick", Vector3(float(px), 12.25, -1.0), Vector3(5.9, 24.5, 24.5))
	for px in [-13.2, 13.2]:
		RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(float(px) + 2.95, 0, -1.0), Vector3.FORWARD,
			Vector3.RIGHT, -12.25, 12.25, 0.0, 14.0, [[0.0, 8.0, 9.0, 0.0]], 5.9, 12)
		lm.box("Brick", Vector3(float(px), 19.25, -1.0), Vector3(5.9, 10.5, 24.5))
		for s in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Brick", Vector3(float(px) + float(s) * 2.95, 9.0, -1.0), Vector3(s, 0, 0), 8.0, 0.6, 0.2)
			lm.box("Marble", Vector3(float(px) + float(s) * 2.95, 13.8, -1.0), Vector3(0.5, 0.4, 24.0), Basis(), 0.0)
	# North wall: the apse opening in the middle bay, windows in the others.
	RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(0, 0, -12.25), Vector3.RIGHT, Vector3.FORWARD,
		-half, half, 0.0, 24.5, [[0.0, 15.0, 13.0, 0.0]], 1.9, 14)
	for cx in [-26.4, 26.4]:
		for s in [-1.0, 1.0]:
			var n := Vector3(0, 0, -s)
			var zf: float = -12.25 if s > 0.0 else -10.35
			for row in 2:
				for k in 3:
					RmADetail.niche(lm, "Brick", "Shadow", Vector3(float(cx) - 6.4 + 6.4 * float(k), 2.5 + 10.5 * float(row), zf),
						n, 3.6, 5.0, 0.5, 0.6)
	_apse(lm, Vector3(0, 0, -12.25))
	for px in [-39.6, -13.2, 13.2, 39.6]:
		lm.box("Brick", Vector3(float(px), 9.0, -17.0), Vector3(3.6, 18.0, 5.6))
		lm.box("Brick", Vector3(float(px), 18.75, -15.0), Vector3(3.6, 1.5, 1.6))
	# Stumps of the nave piers and groin vault springers on the open side,
	# with the column bases in front of them.
	for px in [-39.6, -13.2, 13.2, 39.6]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(float(px), 0, 12.25), Vector3(float(px), 0, 20.0), 4.2, 0.0, 6.0, 15.0, 3.9, px)
		RmADetail.broken_column(lm, "Marble", "Marble", Vector3(float(px), 0, 22.8), 0.95, 1.2 + absf(sin(float(px))) * 2.5)
	# Brick string course along the aisle front at the vault springing.
	LandmarkDetail.cornice(lm, "Marble", Vector3(-half, 13.6, 12.25), Vector3(half, 13.6, 12.25), Vector3.BACK, 0.5, false)
	lm.commit(model)

## Constantine's apse behind the middle bay, chord on the north wall's
## outer face at `c`: a half-round wall (r 7.5 m) with two tiers of five
## niches inside and a half-dome.
static func _apse(lm: RmAMesh, c: Vector3) -> void:
	var r := 7.5
	var n := 14
	for i in n:
		var a0 := PI * float(i) / float(n)
		var a1 := PI * float(i + 1) / float(n)
		RmAUtil.seg_box(lm, "Brick", c + Vector3(cos(a0) * (r + 0.8), 0, -sin(a0) * (r + 0.8)),
			c + Vector3(cos(a1) * (r + 0.8), 0, -sin(a1) * (r + 0.8)), 1.6, 0.0, 13.0)
	for row in 2:
		for k in 5:
			var a := PI * (float(k) + 0.5) / 5.0
			var out := Vector3(cos(a), 0, -sin(a))
			RmADetail.niche(lm, "Brick", "Shadow", c + out * r + Vector3(0, 2.0 + 5.2 * float(row), 0), -out,
				1.8, 2.4, 0.35, 0.3)
	var rows: Array = []
	for j in 7:
		var t := PI * 0.5 * float(j) / 6.0
		var row := PackedVector3Array()
		for i in 13:
			var a := PI * float(i) / 12.0
			row.append(c + Vector3(cos(a) * cos(t) * (r + 0.8), 13.0 + sin(t) * (r + 0.8), -sin(a) * cos(t) * (r + 0.8)))
		rows.append(row)
	lm.grid("Vault", rows, c + Vector3(0, 13.0, 0), true)

# --- Palatine palace ------------------------------------------------------

## The imperial palace on the Palatine, compact on the summit floor: the
## Domus Flavia's grassed peristyle with the broken portico columns on
## their bases and the octagonal maze fountain, the Aula Regia to the
## north with its statue niches, apse and tall standing fragment, the
## triclinium with its granite column stumps and two oval nymphaea with
## their islands to the south and, over the Circus Maximus, the brick
## arcades of the Domus Augustana in two storeys with their string
## courses. Aula Regia's flank wall stands highest at 16 m.
static func palatine(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6B4D", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#968B78", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D2C9B6", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4338", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6B7A47", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8B8985", 2.5))
	lm.box("Concrete", Vector3(0, 0.1, -4.0), Vector3(50.0, 0.2, 90.0))
	lm.box("Lawn", Vector3(0, 0.25, -4.0), Vector3(29.0, 0.1, 33.0))
	# Peristyle: broken outer walls and the portico columns on their bases.
	var corners := [Vector3(-16, 0, -22), Vector3(16, 0, -22), Vector3(16, 0, 14), Vector3(-16, 0, 14)]
	for i in 4:
		RmAUtil.ruin_wall(lm, "Brick", corners[i], corners[(i + 1) % 4], 1.5, 0.0, 1.5, 5.0, 2.6, float(i))
	for i in 9:
		for sx in [-13.4, 13.4]:
			var f := absf(sin(float(i) * 3.1 + sx))
			RmADetail.broken_column(lm, "Concrete", "Marble", Vector3(sx, 0.2, -19.0 + 4.1 * float(i)), 0.42, 0.5 + 2.6 * f)
	for i in 6:
		for sz in [-19.0, 13.8]:
			var f := absf(sin(float(i) * 2.3 + sz))
			RmADetail.broken_column(lm, "Concrete", "Marble", Vector3(-9.0 + 3.6 * float(i), 0.2, sz), 0.42, 0.5 + 2.0 * f)
	# Octagonal maze fountain: two concentric broken rings, the inner
	# pelta-shaped walls and the central basin.
	for rr in [7.0, 4.6]:
		for i in 8:
			var a0 := TAU * float(i) / 8.0 + PI / 8.0
			var a1 := TAU * float(i + 1) / 8.0 + PI / 8.0
			RmAUtil.seg_box(lm, "Brick", Vector3(cos(a0) * rr, 0, -4.0 + sin(a0) * rr),
				Vector3(cos(a1) * rr, 0, -4.0 + sin(a1) * rr), 0.7, 0.0, 1.1)
	for i in 8:
		var a := TAU * float(i) / 8.0
		for k in 3:
			var b0 := a - 0.3 + 0.2 * float(k)
			var b1 := b0 + 0.2
			RmAUtil.seg_box(lm, "Marble", Vector3(cos(b0) * 5.8, 0, -4.0 + sin(b0) * 5.8),
				Vector3(cos(b1) * 5.8, 0, -4.0 + sin(b1) * 5.8), 0.35, 0.0, 0.7)
		RmAUtil.seg_box(lm, "Marble", Vector3(cos(a) * 2.2, 0, -4.0 + sin(a) * 2.2),
			Vector3(cos(a) * 3.8, 0, -4.0 + sin(a) * 3.8), 0.35, 0.0, 0.7)
	lm.frustum("Marble", Vector3(0, 0, -4.0), 1.6, 1.5, 0.8, 16)
	# Aula Regia: flank walls with their statue niches, the apse and the
	# tall standing fragment.
	RmAUtil.ruin_wall(lm, "Brick", Vector3(-11.0, 0, -22.0), Vector3(-11.0, 0, -36.0), 3.0, 0.0, 8.0, 15.0, 2.8, 1.0)
	RmAUtil.ruin_wall(lm, "Brick", Vector3(11.0, 0, -22.0), Vector3(11.0, 0, -36.0), 3.0, 0.0, 6.0, 13.0, 2.8, 2.0)
	for sx in [-1.0, 1.0]:
		for k in 3:
			RmADetail.niche(lm, "Brick", "Shadow", Vector3(sx * 9.5, 0.6, -25.0 - 4.4 * float(k)), Vector3(-sx, 0, 0),
				2.2, 3.0, 0.45, 0.4)
	lm.box("Brick", Vector3(-11.0, 8.0, -23.6), Vector3(3.0, 16.0, 3.2))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-9.5, 6.0, -22.2), Vector3(-9.5, 6.0, -25.0), Vector3.RIGHT, 0.4, false)
	for i in 10:
		var a := PI * (float(i) + 0.5) / 10.0
		var f := absf(sin(float(i) * 7.7 + 3.0))
		lm.box("Brick", Vector3(cos(a) * 9.5, (6.0 + 6.0 * f) * 0.5, -36.0 - sin(a) * 9.5),
			Vector3(3.0, 6.0 + 6.0 * f, 6.2), Basis(Vector3.UP, a))
	# Triclinium (south of the peristyle), its column stumps, and the two
	# oval nymphaea with their stepped islands.
	RmAUtil.ruin_wall(lm, "Brick", Vector3(-9.0, 0, 14.0), Vector3(-9.0, 0, 26.0), 2.4, 0.0, 5.0, 10.0, 2.4, 3.0)
	RmAUtil.ruin_wall(lm, "Brick", Vector3(9.0, 0, 14.0), Vector3(9.0, 0, 26.0), 2.4, 0.0, 5.0, 10.0, 2.4, 4.0)
	lm.box("Marble", Vector3(0, 0.35, 20.0), Vector3(15.6, 0.3, 12.0))
	for i in 4:
		RmADetail.broken_column(lm, "Concrete", "Granite", Vector3(-6.0 + 4.0 * float(i), 0.5, 15.5), 0.55,
			1.0 + 3.0 * absf(sin(float(i) * 1.9)))
	for sx in [-16.5, 16.5]:
		for i in 12:
			var a := TAU * float(i) / 12.0
			var f := absf(sin(float(i) * 5.3 + sx))
			lm.box("Brick", Vector3(sx + cos(a) * 5.2, (2.0 + 4.0 * f) * 0.5, 21.0 + sin(a) * 5.2),
				Vector3(1.5, 2.0 + 4.0 * f, 3.4), Basis(Vector3.UP, -a))
		lm.lathe("Marble", Vector3(sx, 0, 21.0), PackedVector2Array([Vector2(2.2, 0), Vector2(2.2, 0.6),
			Vector2(1.6, 0.6), Vector2(1.6, 1.2), Vector2(0.9, 1.2), Vector2(0.9, 1.8)]), 20, 1.0, 0.7)
	# Domus Augustana: two stepped brick arcades facing the Circus Maximus.
	lm.box("Brick", Vector3(0, 3.8, 29.4), Vector3(44.0, 7.6, 1.3))
	RmAUtil.arcade(lm, "Brick", "Shadow", Vector3(-22.0, 0, 36.0), Vector3(22.0, 0, 36.0), Vector3.BACK,
		8, 0.0, 7.5, 0.58, 0.5, 6.0)
	lm.box("Brick", Vector3(0, 10.9, 28.4), Vector3(39.0, 6.5, 1.3))
	RmAUtil.arcade(lm, "Brick", "Shadow", Vector3(-19.5, 7.5, 31.0), Vector3(19.5, 7.5, 31.0), Vector3.BACK,
		7, 0.0, 6.5, 0.5, 0.45, 2.6)
	LandmarkDetail.cornice(lm, "Marble", Vector3(-22.0, 7.1, 36.0), Vector3(22.0, 7.1, 36.0), Vector3.BACK, 0.4, false)
	LandmarkDetail.cornice(lm, "Marble", Vector3(-19.5, 13.6, 31.0), Vector3(19.5, 13.6, 31.0), Vector3.BACK, 0.4, false)
	for i in 9:
		var x := -22.0 + 5.5 * float(i)
		lm.box("Brick", Vector3(x, 3.4, 36.25), Vector3(0.9, 6.8, 0.5))
		lm.box("Marble", Vector3(x, 0.2, 36.3), Vector3(1.2, 0.4, 0.7))
	for i in 8:
		var x := -19.5 + 39.0 / 7.0 * float(i)
		lm.box("Brick", Vector3(x, 10.7, 31.2), Vector3(0.8, 6.4, 0.4))
	for sx in [-22.0, 22.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx, 0, 30.0), Vector3(sx, 0, 14.0), 1.8, 0.0, 6.5, 8.0, 2.8, sx)
	lm.commit(model)

# --- Trajan's Markets ---------------------------------------------------------

## The brick hemicycle (c. AD 100-110) in four stepped tiers cut into the
## Quirinal: the tabernae of the ground floor with travertine door
## frames and the small windows over them, the gallery of arched windows
## between brick pilasters with alternately triangular and segmental
## pediments, the Via Biberatica tier with square windows and the
## parapet; the Great Hall (Aula Traiana) with its six cross-vaulted
## bays and clerestory; and the Torre delle Milizie, the 42 m medieval
## keep on its battered tuff base, banded in brick with marble string
## courses, windows and battlements. Origin between hemicycle and tower;
## elements set at their bearings.
static func markets(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A06B4A", 2.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4338", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8F5C43", 3.0))
	lm.use("Tuff", LandmarkMaterials.pbr("stone", "#A29476", 3.0))
	lm.place(-29.0, 30.0, 217.0)
	var hemi := lm.xf
	var tiers := [[21.0, 0.0, 5.4, 14, 0.5, 0.55], [25.6, 5.4, 10.8, 17, 0.4, 0.5],
		[30.2, 10.8, 16.2, 20, 0.4, 0.5], [34.8, 16.2, 19.6, 24, 0.3, 0.45]]
	for ti in tiers.size():
		var t: Array = tiers[ti]
		var r: float = t[0]
		var y0: float = t[1]
		var y1: float = t[2]
		var n := int(t[3])
		RmAUtil.arc_arcade(lm, "Brick", "Shadow", Vector3.ZERO, r, -PI, 0.0, n, y0, y1, float(t[4]), float(t[5]),
			4.6, true, true)
		for i in n:
			var a0 := -PI + PI * float(i) / float(n)
			var a1 := -PI + PI * float(i + 1) / float(n)
			var p0 := Vector3(cos(a0) * (r - 0.2), y1 - 0.25, sin(a0) * (r - 0.2))
			var p1 := Vector3(cos(a1) * (r - 0.2), y1 - 0.25, sin(a1) * (r - 0.2))
			lm.beam("Travertine", p0, p1, 0.5, 0.9, Vector3.UP)
			var am := (a0 + a1) * 0.5
			var bw := 2.0 * r * sin(PI * 0.5 / float(n))
			var ow := bw * float(t[4])
			# Bay dressings in the bay's own frame (local +Z toward the
			# forum, i.e. the hemicycle's centre).
			lm.xf = hemi * Transform3D(Basis(Vector3.UP, atan2(-cos(am), -sin(am))),
				Vector3(cos(am), 0, sin(am)) * r * cos(PI * 0.5 / float(n)))
			var sp := (y1 - y0) * float(t[5])
			match ti:
				0:
					for s in [-1.0, 1.0]:
						lm.box("Travertine", Vector3(float(s) * (ow * 0.5 + 0.15), y0 + sp * 0.5, 0.1), Vector3(0.3, sp, 0.25))
					lm.box("Travertine", Vector3(0, y0 + sp + 0.2, 0.12), Vector3(ow + 0.7, 0.4, 0.3))
				1:
					lm.box("Brick", Vector3(-bw * 0.5, y0 + (y1 - y0) * 0.45, 0.15), Vector3(0.6, (y1 - y0) * 0.8, 0.3))
					lm.box("Travertine", Vector3(-bw * 0.5, y0 + (y1 - y0) * 0.86, 0.2), Vector3(0.8, 0.25, 0.4))
					var py := y0 + sp + ow * 0.5 + 0.35
					if i % 2 == 0:
						RmAUtil.pediment(lm, "Travertine", Vector3(0, py, 0.2), Vector3.RIGHT, Vector3.BACK, ow + 0.6, 0.6, 0.35)
					else:
						for k in 6:
							var q0 := PI * float(k) / 6.0
							var q1 := PI * float(k + 1) / 6.0
							lm.beam("Travertine", Vector3(cos(q0) * (ow * 0.5 + 0.3), py + sin(q0) * 0.6, 0.2),
								Vector3(cos(q1) * (ow * 0.5 + 0.3), py + sin(q1) * 0.6, 0.2), 0.2, 0.35, Vector3.BACK)
					lm.box("Travertine", Vector3(0, py - 0.1, 0.2), Vector3(ow + 0.6, 0.2, 0.35))
				2:
					lm.box("Travertine", Vector3(0, y0 + 0.15, 0.15), Vector3(ow + 0.4, 0.3, 0.3))
				_:
					lm.box("Brick", Vector3(0, y1 + 0.5, -0.3), Vector3(bw, 1.0, 0.6))
			lm.xf = hemi
	# Great Hall (Aula Traiana): six cross-vaulted bays and clerestory.
	lm.box("Brick", Vector3(36.0, 7.5, -20.0), Vector3(12.0, 15.0, 30.0))
	lm.box("Travertine", Vector3(36.0, 15.2, -20.0), Vector3(12.4, 0.4, 30.4))
	for k in 6:
		var z := -32.5 + 5.0 * float(k)
		RmAUtil.barrel_vault(lm, "Roof", "Roof", Vector3(36.0, 15.4, z + 2.4), Vector3(0, 0, -1), Vector3.RIGHT,
			4.8, 11.6, 2.4, 0.15, 0, 0, 8)
		for sx in [-1.0, 1.0]:
			RmADetail.niche(lm, "Brick", "Shadow", Vector3(36.0 + sx * 6.0, 9.6, z), Vector3(sx, 0, 0), 2.4, 2.6,
				0.3, 0.35)
			RmADetail.niche(lm, "Brick", "Shadow", Vector3(36.0 + sx * 6.0, 1.0, z), Vector3(sx, 0, 0), 2.2, 2.4,
				0.3, 0.35)
	SEuUtil.face_row(lm, "Shadow", Vector3(36.0, 0, -5.0), Vector3.RIGHT, Vector3(0, 0, 1), 9.6, 3, 3.6, 2.2, 3.8)
	SEuUtil.face_row(lm, "Shadow", Vector3(36.0, 0, -5.0), Vector3.RIGHT, Vector3(0, 0, 1), 1.0, 3, 3.6, 2.0, 3.6)
	# Torre delle Milizie: battered tuff base, two brick stages.
	lm.place(36.5, -33.4, 180.0)
	lm.spire("Tuff", Vector3.ZERO, 8.6, 4.0, 7.5)
	var stages := [[15.0, 4.0, 13.0, "Tuff"], [13.2, 13.0, 27.0, "Brick"], [11.6, 27.0, 40.0, "Brick"]]
	for s in stages:
		var w: float = s[0]
		var y0: float = s[1]
		var y1: float = s[2]
		lm.box(str(s[3]), Vector3(0, (y0 + y1) * 0.5, 0), Vector3(w, y1 - y0, w))
		lm.box("Travertine", Vector3(0, y1 - 0.2, 0), Vector3(w + 0.6, 0.5, w + 0.6))
		lm.box("Travertine", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(w + 0.2, 0.2, w + 0.2), Basis(), 0.0)
		for k in 4:
			var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
			for ox in [-2.1, 2.1]:
				RmADetail.niche(lm, str(s[3]), "Shadow", out * w * 0.5 + Vector3.UP.cross(out) * float(ox)
					+ Vector3(0, y0 + 2.6, 0), out, 1.2, 2.4, 0.25, 0.3)
			for ox in [-1.4, 1.4]:
				SEuUtil.opening(lm, "Shadow", out * (w * 0.5 + 0.05) + Vector3.UP.cross(out) * float(ox)
					+ Vector3(0, y1 - 3.4, 0), Vector3.UP.cross(out), Vector3.UP, 0.4, 1.2)
	lm.box("Travertine", Vector3(0, 40.4, 0), Vector3(12.6, 0.8, 12.6))
	for k in 4:
		var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
		var right := Vector3.UP.cross(out)
		for m in 4:
			lm.box("Brick", out * 5.9 + right * (-4.2 + 2.8 * float(m)) + Vector3(0, 41.6, 0),
				Vector3(1.4, 1.6, 1.2), Basis(Vector3.UP, PI * 0.5 * float(k)))
		for m in 8:
			lm.box("Travertine", out * 6.2 + right * (-5.25 + 1.5 * float(m)) + Vector3(0, 40.1, 0),
				Vector3(0.3, 0.5, 0.4), Basis(Vector3.UP, PI * 0.5 * float(k)), 0.0)
	lm.commit(model)
