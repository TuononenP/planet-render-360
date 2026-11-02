class_name LandmarkRmAForum
extends RefCounted

## The Roman Forum in true metres, origin at the middle of the Forum
## square (+X east, -Z north), every monument set at its surveyed spot and
## turned to its real bearing: the Temples of Saturn and Vespasian and the
## Arch of Septimius Severus at the Capitoline end, the Column of Phocas,
## the Curia Julia, the three columns of the Temple of Castor, the Temple
## of Vesta and the Temple of Antoninus and Faustina with its baroque
## church.

static func forum(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D9D1BF", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6B4D", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8B86", 2.5))
	lm.use("Cipollino", LandmarkMaterials.pbr("limestone", "#A3A793", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9C917E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#51483B", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B1A892", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8F6249", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#C9AD86", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#4E4A3A", 0.5, 0.5))
	# The square's paving, laid along the Forum axis (bearing 125 degrees).
	lm.box("Paving", Vector3(10, 0.05, 28), Vector3(44, 0.1, 140), Basis(Vector3.UP, deg_to_rad(55.0)), 0.0)
	lm.place(-109.0, 6.0, 125.0)
	_saturn(lm)
	lm.place(-104.0, -24.0, 125.0)
	_vespasian(lm)
	lm.place(-56.0, -41.0, 126.0)
	_septimius(lm)
	lm.place(-46.0, 2.0)
	_phocas(lm)
	lm.place(0.0, -58.0, 230.0)
	_curia(lm)
	lm.place(107.0, 34.0, 215.0)
	_antoninus(lm)
	lm.place(45.0, 70.0)
	_vesta(lm)
	lm.place(5.0, 58.0, 305.0)
	_castor(lm)
	lm.commit(model)

## Temple of Saturn: 22.5 x 40.5 m podium with its moulded crown and the
## 18-step stair, the eight surviving unfluted granite Ionic columns (six
## on the front, two behind) on Attic bases, the front entablature with
## the restoration inscription SENATVS POPVLVSQVE ROMANVS INCENDIO
## CONSVMPTVM RESTITVIT, and the ruined cella.
static func _saturn(lm: RmAMesh) -> void:
	lm.box("Concrete", Vector3(0, 2.3, 0), Vector3(22.5, 4.6, 40.5))
	lm.box("Travertine", Vector3(0, 0.3, 0), Vector3(23.1, 0.6, 41.1))
	lm.box("Travertine", Vector3(0, 4.7, 0), Vector3(23.1, 0.3, 41.1))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, 20.25), Vector3.BACK, 10.0, 0.5, 0.26, 18)
	for i in 6:
		var x := -9.9 + 3.96 * float(i)
		LandmarkDetail.column(lm, "Granite", Vector3(x, 4.85, 17.85), 0.72, 11.0, "ionic", 0)
	for sx in [-9.9, 9.9]:
		LandmarkDetail.column(lm, "Granite", Vector3(float(sx), 4.85, 13.65), 0.72, 11.0, "ionic", 0)
		RmAUtil.entablature(lm, "Travertine", Vector3(float(sx), 15.85, 17.85),
			Vector3(float(sx), 15.85, 13.65), 2.6, 2.4)
	RmAUtil.entablature(lm, "Travertine", Vector3(-9.9, 15.85, 17.85), Vector3(9.9, 15.85, 17.85), 2.6, 2.4)
	RmADetail.inscription(lm, "Shadow", Vector3(0, 17.12, 18.88), Vector3.BACK, 18.0, 0.95, 1, 0.5)
	# Ruined cella: side walls, back wall and the rear of the front wall.
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(-8.6, 4.8, 12.0), Vector3(-8.6, 4.8, -19.0), 2.2, 0.0, 2.0, 5.5, 2.2, 1.0)
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(8.6, 4.8, 12.0), Vector3(8.6, 4.8, -19.0), 2.2, 0.0, 2.0, 5.5, 2.2, 2.0)
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(-8.6, 4.8, -19.0), Vector3(8.6, 4.8, -19.0), 2.2, 0.0, 2.0, 4.5, 2.2, 3.0)

## Temple of Vespasian and Titus (c. AD 87): its high podium against the
## Tabularium and the three fluted Corinthian columns of the front corner
## (15.2 m) carrying the entablature with the frieze of sacrificial
## instruments and the end of the inscription [R]ESTITVER.
static func _vespasian(lm: RmAMesh) -> void:
	lm.box("Concrete", Vector3(0, 2.0, 0), Vector3(22.0, 4.0, 33.0))
	lm.box("Travertine", Vector3(0, 4.1, 0), Vector3(22.6, 0.2, 33.6))
	var pts := [Vector3(-9.0, 4.2, 15.0), Vector3(-5.2, 4.2, 15.0), Vector3(-9.0, 4.2, 11.2)]
	for p in pts:
		LandmarkDetail.column(lm, "Marble", p, 0.72, 15.2, "corinthian", 24)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.0, 19.4, 15.0), Vector3(-5.2, 19.4, 15.0), 2.9, 2.2)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.0, 19.4, 15.0), Vector3(-9.0, 19.4, 11.2), 2.9, 2.2)
	for k in 6:
		RmADetail.bucranium(lm, "Marble", Vector3(-9.6 + 0.85 * float(k), 20.55, 15.93), Vector3.BACK, 0.55)
	RmADetail.inscription(lm, "Shadow", Vector3(-7.1, 19.8, 16.0), Vector3.BACK, 3.6, 0.8, 1, 2.0)

## Arch of Septimius Severus (AD 203): 23 x 11.2 m, 20.88 m, Pentelic
## marble; three passages with imposts, archivolts, figured keystones and
## coffered soffits; Victories over the central arch and river gods over
## the side ones; eight fluted Composite columns on pedestals carved
## with captives, the entablature breaking over them; the four great
## panels of the Parthian wars with the small triumph frieze under them;
## the attic with its six-line dedication (the bronze quadriga is lost).
static func _septimius(lm: RmAMesh) -> void:
	var w := 23.0
	var d := 11.2
	var hw := w * 0.5
	var hd := d * 0.5
	var passages := [[-7.8, 3.0, 6.3], [0.0, 6.97, 8.5], [7.8, 3.0, 6.3]]
	var opens: Array = []
	for p in passages:
		opens.append([p[0], p[1], p[2], 0.0])
	RmAUtil.arch_wall(lm, "Marble", "Shadow", Vector3(0, 0, hd), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 15.4, opens, d, 12)
	for p in passages:
		var cx: float = p[0]
		var pw: float = p[1]
		var spring: float = p[2]
		for s in [-1.0, 1.0]:
			lm.box("Marble", Vector3(cx + float(s) * (pw * 0.5 - 0.05), spring - 0.2, 0), Vector3(0.3, 0.4, d + 0.2))
		RmAUtil.barrel_vault(lm, "Marble", "Shadow", Vector3(cx, spring, hd), Vector3(0, 0, -1), Vector3.RIGHT,
			d, pw - 0.1, pw * 0.5 - 0.05, 0.02, 5 if pw > 5.0 else 3, 6, 12)
		for sz in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Marble", Vector3(cx, spring, sz * hd), Vector3(0, 0, sz), pw,
				0.55 if pw > 5.0 else 0.4, 0.2)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var face: float = sz * hd
		var rsign := signf(Vector3.UP.cross(n).x)
		for cx in [-10.2, -5.0, 5.0, 10.2]:
			var x: float = cx
			var zf: float = sz * (hd + 0.7)
			RmADetail.pedestal(lm, "Marble", Vector3(x, 0, zf), 1.9, 1.9, 2.6)
			RmADetail.relief_figure(lm, "Marble", Vector3(x - 0.35, 0.6, zf + sz * 0.95), n, 1.4)
			RmADetail.relief_figure(lm, "Marble", Vector3(x + 0.35, 0.6, zf + sz * 0.95), n, 1.3)
			LandmarkDetail.column(lm, "Marble", Vector3(x, 2.6, zf), 0.55, 8.4, "corinthian", 24)
			lm.box("Marble", Vector3(x, 7.0, face + sz * 0.1), Vector3(0.9, 8.4, 0.2))
			lm.box("Marble", Vector3(x, 11.8, sz * (hd + 0.7)), Vector3(1.9, 1.6, 1.4 + 1.0))
			LandmarkDetail.cornice(lm, "Marble", Vector3(x - 0.95, 12.6, sz * (hd + 1.9)),
				Vector3(x + 0.95, 12.6, sz * (hd + 1.9)), n, 0.6, true)
		LandmarkDetail.cornice(lm, "Marble", Vector3(-hw, 12.6, face), Vector3(hw, 12.6, face), n, 0.6, true)
		for s in [-1.0, 1.0]:
			RmADetail.victory(lm, "Marble", Vector3(float(s) * 4.6, 10.6, face + sz * 0.15), n, -float(s) * rsign, 2.4)
		for sx in [-7.8, 7.8]:
			var bx: float = sx
			# River gods reclining in the side spandrels, the triumph frieze
			# and the Parthian war panel above.
			for s in [-1.0, 1.0]:
				lm.beam("Marble", Vector3(bx + float(s) * 2.4, 8.0, face + sz * 0.12),
					Vector3(bx + float(s) * 1.2, 8.6, face + sz * 0.12), 0.45, 0.3, n, true)
			lm.box("Marble", Vector3(bx, 9.2, face + sz * 0.04), Vector3(4.2, 0.6, 0.08), Basis(), 0.0)
			RmADetail.figure_row(lm, "Marble", Vector3(bx - 2.0, 8.95, face + sz * 0.08),
				Vector3(bx + 2.0, 8.95, face + sz * 0.08), n, 0.5, 14)
			RmADetail.panel(lm, "Marble", "Shadow", Vector3(bx, 11.1, face), n, 4.2, 2.8, 0.06, 0.18)
			for row in 3:
				RmADetail.figure_row(lm, "Marble", Vector3(bx - 1.9, 9.85 + 0.9 * float(row), face + sz * 0.08),
					Vector3(bx + 1.9, 9.85 + 0.9 * float(row), face + sz * 0.08), n, 0.8, 7)
		# Attic dedication.
		RmADetail.panel(lm, "Marble", "Marble", Vector3(0, 18.15, sz * (hd - 0.3)), n, 14.0, 3.0, 0.08, 0.3)
		RmADetail.inscription(lm, "Shadow", Vector3(0, 18.15, sz * (hd - 0.22)), n, 13.2, 2.7, 6, sz)
	lm.box("Marble", Vector3(0, 15.8, 0), Vector3(w + 0.6, 0.8, d + 0.6))
	lm.box("Marble", Vector3(0, 18.15, 0), Vector3(w - 0.6, 3.9, d - 0.6))
	lm.box("Marble", Vector3(0, 20.49, 0), Vector3(w + 0.6, 0.78, d + 0.6))

## Column of Phocas (608): a 13.6 m fluted Corinthian column re-used from
## an earlier monument, on its brick-cored plinth and five steps.
static func _phocas(lm: RmAMesh) -> void:
	for k in 5:
		lm.box("Travertine", Vector3(0, 0.15 + 0.3 * float(k), 0), Vector3(5.2 - 0.4 * float(k), 0.3, 5.2 - 0.4 * float(k)))
	RmADetail.pedestal(lm, "Marble", Vector3(0, 1.5, 0), 2.4, 2.4, 1.7)
	RmADetail.inscription(lm, "Shadow", Vector3(0, 2.35, 1.22), Vector3.BACK, 1.9, 0.9, 6, 4.0)
	LandmarkDetail.column(lm, "Marble", Vector3(0, 3.2, 0), 0.7, 10.4, "corinthian", 24)

## Curia Julia, the Senate house (rebuilt by Diocletian, 303): brick
## walls on a travertine base under a shallow gabled roof, 17.6 x 25.2 m
## and 21 m high; the travertine-framed portal with its bronze doors
## (copy of the originals at the Lateran), the three tall windows over
## it, the cornice on consoles, corner buttresses, side windows.
static func _curia(lm: RmAMesh) -> void:
	var w := 17.6
	var d := 25.2
	var hw := w * 0.5
	var hd := d * 0.5
	lm.box("Travertine", Vector3(0, 1.1, 0), Vector3(w + 0.8, 2.2, d + 0.8))
	lm.box("Brick", Vector3(0, 10.1, 0), Vector3(w, 17.8, d))
	lm.box("Travertine", Vector3(0, 9.0, 0), Vector3(w + 0.4, 0.5, d + 0.4))
	lm.box("Travertine", Vector3(0, 18.2, 0), Vector3(w + 0.8, 0.7, d + 0.8))
	lm.gable("Roof", Vector3(0, 18.5, 0), w, d, 2.5, Basis(), 0.4, "Brick")
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, hd + 0.4), Vector3.BACK, 7.0, 0.5, 0.27, 4)
	# Portal: travertine jambs, lintel and cornice, the bronze doors.
	var fz := hd
	for s in [-1.0, 1.0]:
		lm.box("Travertine", Vector3(float(s) * 2.4, 5.6, fz + 0.2), Vector3(0.7, 7.0, 0.4))
	lm.box("Travertine", Vector3(0, 9.4, fz + 0.2), Vector3(5.6, 0.7, 0.4))
	LandmarkDetail.cornice(lm, "Travertine", Vector3(-3.0, 9.75, fz + 0.4), Vector3(3.0, 9.75, fz + 0.4), Vector3.BACK, 0.5, true)
	for s in [-1.0, 1.0]:
		var dc := Vector3(float(s) * 1.0, 5.6, fz + 0.04)
		lm.box("Bronze", dc, Vector3(2.0, 7.0, 0.08), Basis(), 0.0)
		for row in 4:
			RmADetail.panel(lm, "Bronze", "Bronze", dc + Vector3(0, -2.6 + 1.73 * float(row), 0.04), Vector3.BACK,
				1.4, 1.3, 0.02, 0.1)
	# Three tall windows over the portal, cut through a skin on the brick.
	LandmarkDetail.pierced_face(lm, "Brick", "Shadow", Vector3(-hw, 10.0, fz), Vector3.RIGHT, Vector3.BACK,
		w, 8.2, 3, 1, Vector2(2.2, 5.6), 1.0, 6.0, 0.35)
	for k in 3:
		lm.box("Travertine", Vector3(-w / 3.0 + w / 3.0 * float(k), 10.85, fz + 0.5), Vector3(2.8, 0.2, 0.3))
	# Consoles under the gable cornice and corner buttresses.
	for k in 14:
		lm.box("Travertine", Vector3(-hw + 0.6 + (w - 1.2) * float(k) / 13.0, 17.6, fz + 0.5), Vector3(0.3, 0.5, 0.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Brick", Vector3(sx * (hw - 0.3), 10.1, sz * (hd + 0.35)), Vector3(1.6, 17.8, 0.7))
		for k in 4:
			var z := -8.4 + 5.6 * float(k)
			SEuUtil.opening(lm, "Shadow", Vector3(sx * (hw + 0.06), 11.4, z), Vector3(0, 0, -sx), Vector3.UP, 1.8, 3.8)
			lm.box("Travertine", Vector3(sx * (hw + 0.12), 11.3, z), Vector3(0.24, 0.2, 2.4))

## Temple of Antoninus and Faustina (AD 141): 21.3 x 39 m podium and its
## 21-step stair, the ten monolithic unfluted cipollino Corinthian columns
## (17 m) with the griffin-and-candelabra frieze and the dedication DIVO
## ANTONINO ET DIVAE FAVSTINAE EX S C, the tuff cella walls, and the
## baroque facade of San Lorenzo in Miranda built into the portico
## (1602): pilasters, portal, window, volutes and pediment.
static func _antoninus(lm: RmAMesh) -> void:
	var w := 21.3
	lm.box("Concrete", Vector3(0, 2.5, 0), Vector3(w, 5.0, 39.0))
	lm.box("Travertine", Vector3(0, 5.1, 0), Vector3(w + 0.6, 0.3, 39.6))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, 19.5), Vector3.BACK, 10.0, 0.5, 0.24, 21)
	for i in 6:
		LandmarkDetail.column(lm, "Cipollino", Vector3(-9.5 + 3.8 * float(i), 5.25, 16.1), 0.78, 17.0, "corinthian", 0)
	for sx in [-9.5, 9.5]:
		for z in [12.3, 8.5]:
			LandmarkDetail.column(lm, "Cipollino", Vector3(float(sx), 5.25, float(z)), 0.78, 17.0, "corinthian", 0)
		RmAUtil.entablature(lm, "Marble", Vector3(float(sx), 22.25, 16.1), Vector3(float(sx), 22.25, 8.5), 2.95, 2.6)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.5, 22.25, 16.1), Vector3(9.5, 22.25, 16.1), 2.95, 2.6)
	RmADetail.inscription(lm, "Shadow", Vector3(0, 22.67, 17.27), Vector3.BACK, 17.0, 0.8, 1, 3.0)
	RmADetail.inscription(lm, "Shadow", Vector3(0, 23.69, 17.2), Vector3.BACK, 15.0, 1.0, 1, 4.0)
	# Griffins facing across candelabra on the side friezes.
	for sx in [-1.0, 1.0]:
		for k in 4:
			var z := 9.2 + 1.9 * float(k)
			lm.lathe("Marble", Vector3(sx * 10.62, 23.3, z), PackedVector2Array([Vector2(0.0, 0), Vector2(0.18, 0.05),
				Vector2(0.12, 0.6), Vector2(0.2, 0.8), Vector2(0.0, 0.85)]), 8, 0.4, 1.0)
	# Cella: tuff walls, with the church facade and its pediment in front.
	lm.box("Concrete", Vector3(0, 13.5, 6.6), Vector3(w - 1.4, 16.8, 2.2))
	for sx in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(sx * 9.6, 13.5, -6.6), Vector3(2.2, 16.8, 28.0))
	lm.box("Concrete", Vector3(0, 13.5, -19.4), Vector3(w - 1.4, 16.8, 2.2))
	lm.box("Stucco", Vector3(0, 11.3, 9.0), Vector3(11.5, 12.4, 2.6))
	for px in [-5.2, -2.0, 2.0, 5.2]:
		lm.box("Stucco", Vector3(float(px), 11.0, 10.4), Vector3(0.8, 11.6, 0.3))
		lm.box("Stucco", Vector3(float(px), 16.95, 10.45), Vector3(1.0, 0.3, 0.4))
	LandmarkDetail.cornice(lm, "Stucco", Vector3(-5.75, 17.1, 10.3), Vector3(5.75, 17.1, 10.3), Vector3.BACK, 0.4, true)
	RmAUtil.pediment(lm, "Stucco", Vector3(0, 17.5, 9.0), Vector3.RIGHT, Vector3.BACK, 11.5, 2.4, 2.6)
	SEuUtil.opening(lm, "Shadow", Vector3(0, 5.2, 10.34), Vector3.RIGHT, Vector3.UP, 2.6, 5.2)
	LandmarkDetail.arch(lm, "Stucco", Vector3(0, 9.1, 10.3), Vector3.BACK, 2.6, 0.35, 0.15)
	LandmarkDetail.window(lm, "Stucco", "Shadow", Vector3(0, 13.8, 10.3), Vector3.BACK, 1.8, 2.6, false, 0.2)
	for s in [-1.0, 1.0]:
		lm.lathe("Stucco", Vector3(float(s) * 4.4, 17.9, 10.0), PackedVector2Array([Vector2(0.0, 0),
			Vector2(0.5, 0.1), Vector2(0.55, 0.6), Vector2(0.0, 0.8)]), 10, 1.0, 0.5)

## Temple of Vesta: the 15 m round podium with the low rim of the cella
## wall and the three fluted Corinthian columns reconstructed in 1930
## with their curved entablature.
static func _vesta(lm: RmAMesh) -> void:
	lm.frustum("Concrete", Vector3.ZERO, 7.8, 7.6, 1.3, 32)
	lm.lathe("Travertine", Vector3(0, 1.3, 0), PackedVector2Array([Vector2(7.7, 0), Vector2(7.8, 0.12),
		Vector2(7.6, 0.2)]), 32)
	for i in 14:
		var a := TAU * float(i) / 14.0
		var f := absf(sin(float(i) * 12.9898 + 5.0))
		lm.box("Concrete", Vector3(cos(a) * 4.6, 1.3 + (0.5 + 1.6 * f) * 0.5, sin(a) * 4.6),
			Vector3(1.4, 0.5 + 1.6 * f, 2.3), Basis(Vector3.UP, -a))
	for k in 3:
		var a := 4.0 + 0.314 * float(k)
		LandmarkDetail.column(lm, "Marble", Vector3(cos(a) * 6.5, 1.5, sin(a) * 6.5), 0.46, 5.8, "corinthian", 20)
	for k in 2:
		var a0 := 4.0 + 0.314 * float(k)
		var a1 := a0 + 0.314
		RmAUtil.entablature(lm, "Marble", Vector3(cos(a0) * 6.5, 7.3, sin(a0) * 6.5),
			Vector3(cos(a1) * 6.5, 7.3, sin(a1) * 6.5), 1.2, 1.2, 0.1)

## Temple of Castor and Pollux (rebuilt AD 6): the 28 x 40 m podium and
## the three fluted 12.5 m Corinthian columns of the south-east corner
## with their entablature and the modillioned cornice.
static func _castor(lm: RmAMesh) -> void:
	lm.box("Concrete", Vector3(0, 3.25, 0), Vector3(28.0, 6.5, 40.0))
	lm.box("Travertine", Vector3(0, 0.3, 0), Vector3(28.6, 0.6, 40.6))
	lm.box("Travertine", Vector3(0, 6.6, 0), Vector3(28.6, 0.3, 40.6))
	for p in [[-9.5, 16.0], [-5.5, 16.0], [-9.5, 12.0]]:
		LandmarkDetail.column(lm, "Marble", Vector3(float(p[0]), 6.75, float(p[1])), 0.75, 12.5, "corinthian", 24)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.5, 19.25, 12.0), Vector3(-9.5, 19.25, 16.0), 2.4, 2.2)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.5, 19.25, 16.0), Vector3(-5.5, 19.25, 16.0), 2.4, 2.2)
	for k in 6:
		lm.box("Marble", Vector3(-10.0 + 0.8 * float(k), 21.15, 17.3), Vector3(0.3, 0.22, 0.6), Basis(), 0.0)
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(-12.0, 6.75, -17.0), Vector3(12.0, 6.75, -17.0), 2.4, 0.0, 1.0, 3.0, 2.4, 4.0)
