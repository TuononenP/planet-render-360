class_name LandmarkRmAForum
extends RefCounted

## The Roman Forum in true metres, origin at the middle of the Forum
## square (+X east, -Z north), every monument set at its surveyed spot and
## turned to its real bearing: the Temple of Saturn and the Arch of
## Septimius Severus at the Capitoline end, the Column of Phocas, the Curia
## Julia, the three columns of the Temple of Castor, the Temple of Vesta
## ruin and the Temple of Antoninus and Faustina with its baroque church.

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
	# The square's paving, laid along the Forum axis (bearing 125 degrees).
	lm.box("Paving", Vector3(10, -0.45, 28), Vector3(44, 1.0, 140), Basis(Vector3.UP, deg_to_rad(55.0)))
	lm.place(-109.0, 6.0, 125.0)
	_saturn(lm)
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

## Temple of Saturn: 22.5 x 40.5 m podium, 18-step stair, and the eight
## surviving Ionic granite columns (six on the front, two behind) with the
## front entablature and its restoration inscription.
static func _saturn(lm: RmAMesh) -> void:
	lm.box("Concrete", Vector3(0, 2.3, 0), Vector3(22.5, 4.6, 40.5))
	lm.box("Travertine", Vector3(0, 4.7, 0), Vector3(23.1, 0.3, 41.1))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, 20.25), Vector3.BACK, 10.0, 0.5, 0.26, 18)
	for i in 6:
		var x := -9.9 + 3.96 * float(i)
		RmAUtil.column(lm, "Granite", Vector3(x, 4.8, 17.85), 11.0, 0.72, "ionic")
	for sx in [-9.9, 9.9]:
		RmAUtil.column(lm, "Granite", Vector3(float(sx), 4.8, 13.65), 11.0, 0.72, "ionic")
		RmAUtil.entablature(lm, "Travertine", Vector3(float(sx), 15.8, 17.85),
			Vector3(float(sx), 15.8, 13.65), 2.6, 2.4)
	RmAUtil.entablature(lm, "Travertine", Vector3(-9.9, 15.8, 17.85), Vector3(9.9, 15.8, 17.85), 2.6, 2.4)
	lm.box("Shadow", Vector3(0, 17.1, 19.12), Vector3(17.0, 0.9, 0.1))
	# Ruined cella: side walls, back wall and the rear of the front wall.
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(-8.6, 4.8, 12.0), Vector3(-8.6, 4.8, -19.0), 2.2, 0.0, 2.0, 5.5, 2.2, 1.0)
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(8.6, 4.8, 12.0), Vector3(8.6, 4.8, -19.0), 2.2, 0.0, 2.0, 5.5, 2.2, 2.0)
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(-8.6, 4.8, -19.0), Vector3(8.6, 4.8, -19.0), 2.2, 0.0, 2.0, 4.5, 2.2, 3.0)

## Arch of Septimius Severus: 23 x 11.2 m, 20.88 m, Pentelic marble, three
## passages, eight composite columns, victory reliefs and the attic
## inscription (the bronze quadriga is lost).
static func _septimius(lm: RmAMesh) -> void:
	var w := 23.0
	var d := 11.2
	var hw := w * 0.5
	RmAUtil.arch_wall(lm, "Marble", "Shadow", Vector3(0, 0, d * 0.5), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 15.4, [[-7.8, 3.0, 6.3, 0.0], [0.0, 6.97, 8.5, 0.0], [7.8, 3.0, 6.3, 0.0]], d, 10)
	lm.box("Marble", Vector3(0, 15.8, 0), Vector3(w + 0.6, 0.8, d + 0.6))
	lm.box("Marble", Vector3(0, 18.15, 0), Vector3(w - 0.6, 3.9, d - 0.6))
	lm.box("Marble", Vector3(0, 20.49, 0), Vector3(w + 0.6, 0.78, d + 0.6))
	for sz in [-1.0, 1.0]:
		var zf: float = sz * (d * 0.5 + 0.7)
		for cx in [-10.2, -5.0, 5.0, 10.2]:
			var x: float = cx
			lm.box("Marble", Vector3(x, 1.3, zf), Vector3(1.9, 2.6, 1.9))
			RmAUtil.column(lm, "Marble", Vector3(x, 2.6, zf), 8.4, 0.6, "corinthian", 10)
			lm.box("Marble", Vector3(x, 11.8, zf), Vector3(1.9, 1.6, 1.9))
		var zw: float = sz * (d * 0.5 + 0.05)
		for sx in [-7.8, 7.8]:
			lm.box("Shadow", Vector3(float(sx), 11.2, zw), Vector3(4.2, 2.6, 0.12))
		lm.box("Shadow", Vector3(0, 18.15, sz * (d * 0.5 - 0.25)), Vector3(14.0, 2.4, 0.12))

## Column of Phocas (608): a 13.6 m Corinthian column on a brick plinth
## and five steps.
static func _phocas(lm: RmAMesh) -> void:
	for k in 5:
		lm.box("Travertine", Vector3(0, 0.15 + 0.3 * float(k), 0), Vector3(5.2 - 0.4 * float(k), 0.3, 5.2 - 0.4 * float(k)))
	lm.box("Brick", Vector3(0, 2.35, 0), Vector3(2.5, 1.7, 2.5))
	RmAUtil.column(lm, "Marble", Vector3(0, 3.2, 0), 10.4, 0.72, "corinthian", 14)

## Curia Julia, the Senate house: brick walls on a travertine base under a
## shallow gabled roof, 17.6 x 25.2 m and 21 m high, a tall portal and a
## row of three upper windows on the front.
static func _curia(lm: RmAMesh) -> void:
	var w := 17.6
	var d := 25.2
	lm.box("Travertine", Vector3(0, 1.1, 0), Vector3(w + 0.8, 2.2, d + 0.8))
	lm.box("Brick", Vector3(0, 10.1, 0), Vector3(w, 17.8, d))
	lm.box("Travertine", Vector3(0, 9.0, 0), Vector3(w + 0.4, 0.5, d + 0.4))
	lm.box("Travertine", Vector3(0, 18.2, 0), Vector3(w + 0.8, 0.7, d + 0.8))
	lm.gable("Roof", Vector3(0, 18.5, 0), w, d, 2.5, Basis(), 0.4, "Brick")
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, d * 0.5 + 0.4), Vector3.BACK, 7.0, 0.5, 0.27, 4)
	SEuUtil.opening(lm, "Shadow", Vector3(0, 2.1, d * 0.5 + 0.06), Vector3.RIGHT, Vector3.UP, 4.2, 7.0)
	for k in 3:
		var x := -4.8 + 4.8 * float(k)
		SEuUtil.opening(lm, "Shadow", Vector3(x, 11.4, d * 0.5 + 0.06), Vector3.RIGHT, Vector3.UP, 1.8, 3.8)
	for sx in [-1.0, 1.0]:
		for k in 4:
			var z := -8.4 + 5.6 * float(k)
			SEuUtil.opening(lm, "Shadow", Vector3(sx * (w * 0.5 + 0.06), 11.4, z),
				Vector3(0, 0, -sx), Vector3.UP, 1.8, 3.8)

## Temple of Antoninus and Faustina: 21.3 x 39 m podium and its 21-step
## stair, the ten monolithic cipollino Corinthian columns (17 m) with the
## griffin frieze, the tuff cella walls and the baroque facade of
## San Lorenzo in Miranda built into the portico (1602).
static func _antoninus(lm: RmAMesh) -> void:
	var w := 21.3
	lm.box("Concrete", Vector3(0, 2.5, 0), Vector3(w, 5.0, 39.0))
	lm.box("Travertine", Vector3(0, 5.1, 0), Vector3(w + 0.6, 0.3, 39.6))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, 19.5), Vector3.BACK, 10.0, 0.5, 0.24, 21)
	for i in 6:
		RmAUtil.column(lm, "Cipollino", Vector3(-9.5 + 3.8 * float(i), 5.2, 16.1), 17.0, 0.78, "corinthian", 12)
	for sx in [-9.5, 9.5]:
		for z in [12.3, 8.5]:
			RmAUtil.column(lm, "Cipollino", Vector3(float(sx), 5.2, float(z)), 17.0, 0.78, "corinthian", 12)
		RmAUtil.entablature(lm, "Marble", Vector3(float(sx), 22.2, 16.1), Vector3(float(sx), 22.2, 8.5), 3.0, 2.6)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.5, 22.2, 16.1), Vector3(9.5, 22.2, 16.1), 3.0, 2.6)
	lm.box("Shadow", Vector3(0, 23.7, 17.46), Vector3(18.0, 1.1, 0.1))
	# Cella: tuff walls, with the church facade and its pediment in front.
	lm.box("Concrete", Vector3(0, 13.5, 6.6), Vector3(w - 1.4, 16.8, 2.2))
	for sx in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(sx * 9.6, 13.5, -6.6), Vector3(2.2, 16.8, 28.0))
	lm.box("Concrete", Vector3(0, 13.5, -19.4), Vector3(w - 1.4, 16.8, 2.2))
	lm.box("Stucco", Vector3(0, 11.3, 9.0), Vector3(11.5, 12.4, 2.6))
	RmAUtil.pediment(lm, "Stucco", Vector3(0, 17.5, 9.0), Vector3.RIGHT, Vector3.BACK, 11.5, 2.4, 2.6)
	SEuUtil.opening(lm, "Shadow", Vector3(0, 5.2, 10.34), Vector3.RIGHT, Vector3.UP, 2.6, 5.2)
	lm.box("Shadow", Vector3(0, 12.8, 10.34), Vector3(2.0, 2.6, 0.1))

## Temple of Vesta: the 15 m round podium with the low rim of the cella
## wall and the three Corinthian columns reconstructed in 1930.
static func _vesta(lm: RmAMesh) -> void:
	lm.frustum("Concrete", Vector3.ZERO, 7.8, 7.6, 1.3, 24)
	for i in 14:
		var a := TAU * float(i) / 14.0
		var f := absf(sin(float(i) * 12.9898 + 5.0))
		lm.box("Concrete", Vector3(cos(a) * 4.6, 1.3 + (0.5 + 1.6 * f) * 0.5, sin(a) * 4.6),
			Vector3(1.4, 0.5 + 1.6 * f, 2.3), Basis(Vector3.UP, -a))
	for k in 3:
		var a := 4.0 + 0.314 * float(k)
		RmAUtil.column(lm, "Marble", Vector3(cos(a) * 6.5, 1.3, sin(a) * 6.5), 6.0, 0.46, "corinthian", 10)
	var a0 := 4.0
	var a2 := 4.628
	RmAUtil.entablature(lm, "Marble", Vector3(cos(a0) * 6.5, 7.3, sin(a0) * 6.5),
		Vector3(cos(a2) * 6.5, 7.3, sin(a2) * 6.5), 1.2, 1.2, 0.1)

## Temple of Castor and Pollux: the 28 x 40 m podium and the three
## 12.5 m Corinthian columns of the south-east corner with a piece of
## entablature.
static func _castor(lm: RmAMesh) -> void:
	lm.box("Concrete", Vector3(0, 3.25, 0), Vector3(28.0, 6.5, 40.0))
	lm.box("Travertine", Vector3(0, 6.6, 0), Vector3(28.6, 0.3, 40.6))
	for p in [[-9.5, 16.0], [-5.5, 16.0], [-9.5, 12.0]]:
		RmAUtil.column(lm, "Marble", Vector3(float(p[0]), 6.75, float(p[1])), 12.5, 0.75, "corinthian", 12)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.5, 19.25, 12.0), Vector3(-9.5, 19.25, 16.0), 2.4, 2.2)
	RmAUtil.entablature(lm, "Marble", Vector3(-9.5, 19.25, 16.0), Vector3(-5.5, 19.25, 16.0), 2.4, 2.2)
	RmAUtil.ruin_wall(lm, "Concrete", Vector3(-12.0, 6.75, -17.0), Vector3(12.0, 6.75, -17.0), 2.4, 0.0, 1.0, 3.0, 2.4, 4.0)
