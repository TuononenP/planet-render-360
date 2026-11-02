class_name LandmarkEgGiza
extends RefCounted

## The second and third Giza pyramids in true metres as they stand
## today: Khafre with its surviving smooth Tura casing cap and granite
## foot, Menkaure with its red-granite lower courses and the vertical
## gash cut into the north face. Built about the pyramid centre, faces
## to the compass, mortuary temple on the east (+X).

# --- Pyramid of Khafre ---

## 215.25 m square (slope 53.13 deg, 4:3), 143.5 m when built, 136.4 m
## today: stripped coursed core, casing cap over the top 33 m, a granite
## foot, the ruined mortuary temple east and the small satellite pyramid
## south.
static func khafre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C9B48A", 3.8))
	lm.use("Casing", LandmarkMaterials.pbr("stone", "#E2D6B4", 5.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E5E4B", 2.4))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	var hb := 107.625
	var apex := 143.5
	var top := 136.4
	lm.box("Sand", Vector3(0, -1.0, 0), Vector3(hb * 2.0 + 30.0, 2.4, hb * 2.0 + 30.0))
	LandmarkEgParts.smooth(lm, "Granite", Vector3.ZERO, hb, apex, 0.0, 3.4)
	LandmarkEgParts.courses(lm, "Core", Vector3.ZERO, hb, apex, 3.4, 103.0, 1.4)
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb, apex, 103.0, top, true)
	LandmarkEgParts.courses(lm, "Core", Vector3(0, 0, 132.0), 10.5, 14.0, 0.0, 12.0, 1.0, true)
	# Mortuary temple: platform, enclosing walls, granite pillar hall.
	lm.box("Core", Vector3(138.0, 0.6, 0), Vector3(50.0, 1.4, 104.0))
	lm.box("Core", Vector3(158.0, 3.4, 0), Vector3(4.0, 6.0, 104.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(138.0, 3.4, s * 50.0), Vector3(50.0, 6.0, 4.0))
		lm.box("Core", Vector3(116.0, 3.4, s * 30.0), Vector3(4.0, 6.0, 40.0))
	for i in 7:
		for x in [124.0, 136.0]:
			lm.box("Granite", Vector3(x, 5.0, -36.0 + 12.0 * i), Vector3(2.4, 7.0, 2.4))
	lm.box("Core", Vector3(168.0, 1.5, 0), Vector3(18.0, 3.0, 8.0))
	lm.commit(model)

# --- Pyramid of Menkaure ---

## 104.6 m square (slope 51.3 deg), 65.5 m when built, 61 m today: the
## lower 16 courses (16 m) of red granite casing, coursed limestone core
## above, the dark gash down the north (-Z) face, the ruined mortuary
## temple east and the three small queens' pyramids south.
static func menkaure(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C2AB80", 3.4))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A5645", 2.2))
	lm.use("Gash", LandmarkMaterials.pbr("stone", "#3C3228", 3.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	var hb := 52.3
	var apex := 65.5
	var top := 61.0
	lm.box("Sand", Vector3(0, -1.0, 0), Vector3(hb * 2.0 + 24.0, 2.4, hb * 2.0 + 24.0))
	LandmarkEgParts.smooth(lm, "Granite", Vector3.ZERO, hb, apex, 0.0, 16.0)
	LandmarkEgParts.courses(lm, "Core", Vector3.ZERO, hb, apex, 16.0, top, 1.1, true)
	_gash(lm, hb, apex, 60.0, 24.0, 7.5, 3.0)
	# Queens' pyramids on the south side.
	for q in [[-34.0, 22.0], [8.0, 15.5], [40.0, 15.5]]:
		var qb: float = q[1]
		LandmarkEgParts.courses(lm, "Core", Vector3(q[0], 0, hb + 14.0 + qb), qb, qb * 1.25, 0.0,
			qb * 1.15, 1.0, true)
	# Ruined mortuary temple and the start of the causeway.
	lm.box("Core", Vector3(76.0, 0.6, 0), Vector3(40.0, 1.4, 52.0))
	lm.box("Core", Vector3(94.0, 2.6, 0), Vector3(4.0, 4.0, 52.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(76.0, 2.6, s * 24.0), Vector3(40.0, 4.0, 4.0))
	for z in [-9.0, 0.0, 9.0]:
		lm.box("Granite", Vector3(70.0, 3.5, z), Vector3(2.4, 5.0, 2.4))
	lm.box("Core", Vector3(110.0, 1.2, 0), Vector3(28.0, 2.4, 7.0))
	lm.commit(model)

## The cleft cut by Uthman in 1196: a dark wedge `w_top` wide at y_top
## narrowing to `w_bot` at y_bot, laid 0.4 m proud of the north face.
static func _gash(lm: LandmarkMesh, hb: float, apex: float, y_top: float, y_bot: float,
		w_top: float, w_bot: float) -> void:
	var n := Vector3(0, hb, -apex).normalized()
	var pts: Array[Vector3] = []
	for e in [[y_bot, w_bot], [y_top, w_top]]:
		var y: float = e[0]
		var w: float = e[1]
		var z := -hb * (1.0 - y / apex)
		pts.append(Vector3(-w * 0.5, y, z) + n * 0.4)
		pts.append(Vector3(w * 0.5, y, z) + n * 0.4)
	lm.quad("Gash", pts[0], pts[1], pts[3], pts[2], n)
