class_name LandmarkAtAcropolis
extends RefCounted

## The Erechtheion, the Propylaea and the Temple of Athena Nike on the
## Acropolis in true metres. Pentelic marble (cream), Hymettus-honey
## weathered stone and the dark Eleusinian limestone of the friezes.

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6DAC4", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BB93", 2.5))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4D4944", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#C4B8A2", 2.5))

# --- Erechtheion ------------------------------------------------------

## Origin at the middle of the cella, east porch toward +X (yaw_deg turns
## it onto the real axis). 25 m long: the hexastyle Ionic east porch on
## the high floor, the west wall with four engaged half-columns over a
## basement, the tall tetrastyle north porch on the lower ground and the
## Caryatid porch on its podium at the south-west. Ridge at 13.8 m.
static func erechtheion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5347", 2.5))
	var e := 3.2  # east floor level above the west ground
	AtUtil.steps(lm, "Marble", Vector3(0, e, 0), 24.0, 12.4, 3, 0.35, 0.35, 3.0)
	lm.box("Honey", Vector3(-2.35, 5.3, 0), Vector3(18.7, 12.6, 11.6))
	# East porch: six Ionic columns, architrave, dark frieze, cornice.
	for i in 6:
		AtUtil.ionic(lm, "Marble", Vector3(10.9, e, -5.0 + 2.0 * float(i)), 6.6, 0.42, 16, PI * 0.5)
	lm.box("Shadow", Vector3(7.05, e + 2.2, 0), Vector3(0.12, 4.4, 2.2))
	lm.box("Marble", Vector3(10.9, 10.25, 0), Vector3(1.3, 0.9, 12.0))
	lm.box("Dark", Vector3(10.9, 11.1, 0), Vector3(1.2, 0.8, 12.0))
	lm.box("Marble", Vector3(10.9, 11.75, 0), Vector3(1.9, 0.5, 12.4))
	# Cornice and frieze round the long walls and the west end.
	for s in [-1.0, 1.0]:
		lm.box("Dark", Vector3(-0.5, 11.1, s * 5.85), Vector3(22.4, 0.8, 0.12))
		lm.box("Marble", Vector3(-0.5, 11.75, s * 6.0), Vector3(23.2, 0.5, 0.9))
	lm.box("Marble", Vector3(-11.95, 11.75, 0), Vector3(0.9, 0.5, 12.9))
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0.1, 12.0, 0), 12.4, 24.4, 1.8, 0.3,
		Basis(Vector3.UP, PI * 0.5))
	# West wall: ledge, four engaged half-columns and three windows.
	lm.box("Marble", Vector3(-12.0, 4.8, 0), Vector3(0.7, 0.4, 11.8))
	for i in 4:
		AtUtil.ionic(lm, "Marble", Vector3(-12.0, 5.0, -3.9 + 2.6 * float(i)), 5.75, 0.4, 14, PI * 0.5)
	for i in 3:
		lm.box("Shadow", Vector3(-11.74, 8.0, -2.6 + 2.6 * float(i)), Vector3(0.12, 3.2, 1.5))
	# North porch: four Ionic columns on the front, one at each inner side.
	lm.box("Honey", Vector3(-5.5, -1.25, -9.2), Vector3(7.0, 3.5, 6.8))
	AtUtil.steps(lm, "Marble", Vector3(-5.5, 0.5, -9.2), 6.6, 6.4, 2, 0.25, 0.3, 1.0)
	for i in 4:
		AtUtil.ionic(lm, "Marble", Vector3(-8.1 + 1.75 * float(i), 0.5, -11.8), 7.6, 0.5, 16, 0.0)
	for x in [-8.1, -2.85]:
		AtUtil.ionic(lm, "Marble", Vector3(x, 0.5, -9.0), 7.6, 0.5, 16, PI * 0.5)
	lm.box("Marble", Vector3(-5.5, 8.55, -11.8), Vector3(7.0, 0.9, 1.3))
	lm.box("Dark", Vector3(-5.5, 9.4, -11.8), Vector3(7.0, 0.8, 1.2))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(-5.5 + s * 2.65, 8.55, -8.8), Vector3(1.3, 0.9, 6.0))
		lm.box("Dark", Vector3(-5.5 + s * 2.65, 9.4, -8.8), Vector3(1.2, 0.8, 6.0))
	lm.box("Marble", Vector3(-5.5, 10.05, -8.6), Vector3(7.4, 0.5, 6.8))
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(-5.5, 10.3, -8.6), 7.4, 6.8, 1.4)
	lm.box("Shadow", Vector3(-5.5, 3.0, -5.84), Vector3(2.0, 5.0, 0.12))
	# Caryatid porch: six maidens on a high podium under a flat slab.
	lm.box("Honey", Vector3(-8.0, 0.7, 7.8), Vector3(6.2, 7.4, 4.0))
	lm.box("Marble", Vector3(-8.0, 4.5, 7.8), Vector3(6.5, 0.25, 4.3))
	for i in 4:
		AtUtil.caryatid(lm, "Marble", Vector3(-10.2 + 1.47 * float(i), 4.625, 9.2), 2.6, 0.32)
	for x in [-10.2, -5.8]:
		AtUtil.caryatid(lm, "Marble", Vector3(x, 4.625, 7.2), 2.6, 0.32)
	lm.box("Marble", Vector3(-8.0, 7.7, 7.8), Vector3(6.6, 1.0, 4.4))
	lm.commit(model)

# --- Propylaea --------------------------------------------------------

## Mnesikles' gateway, origin at the middle of the passage, west front
## toward +Z (yaw_deg). The hexastyle Doric west porch (wide central
## bay) under its pediment, the cross wall with five doors, the six
## Ionic columns of the passage, the east porch, the north wing
## (Pinakotheke) and the smaller south wing, each with a three-column
## Doric porch toward the road. Ridge at 15.7 m above the lowest step.
static func propylaea(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5347", 2.5))
	var y0 := 1.4
	lm.box("Honey", Vector3(0, (y0 - 6.0) * 0.5, 0), Vector3(50.0, y0 + 6.0, 24.0))
	for k in range(1, 5):
		var top := y0 - 0.35 * float(k)
		lm.box("Marble", Vector3(0, (top - 6.0) * 0.5, 12.3 + 0.6 * float(k)),
			Vector3(20.0, top + 6.0, 0.6))
	var xs: Array[float] = [-7.9, -5.2, -2.5, 2.5, 5.2, 7.9]
	var h := 8.57
	for zc in [11.0, -10.5]:
		var z: float = zc
		for x in xs:
			AtUtil.doric(lm, "Marble", Vector3(x, y0, z), h, 0.78, 16)
		lm.box("Marble", Vector3(0, y0 + h + 0.55, z), Vector3(18.4, 1.1, 1.6))
		lm.box("Honey", Vector3(0, y0 + h + 1.8, z), Vector3(18.4, 1.4, 1.5))
		lm.box("Marble", Vector3(0, y0 + h + 2.95, z), Vector3(19.0, 0.9, 2.4))
		AtUtil.row_boxes(lm, "Dark", Vector3(-8.4, y0 + h + 1.8, z + 0.8 * signf(z)),
			Vector3(8.4, y0 + h + 1.8, z + 0.8 * signf(z)), 13, Vector3(0.5, 1.15, 0.2))
	var yc := y0 + h + 3.4
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0, yc, 0.25), 19.0, 24.0, 2.3)
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(s * 9.2, y0 + 5.99, 0.2), Vector3(1.4, 11.97, 21.5))
		lm.box("Marble", Vector3(s * 9.2, yc - 0.45, 0.2), Vector3(2.0, 0.9, 21.5))
	# Cross wall with five doors and the Ionic columns of the passage.
	lm.box("Honey", Vector3(0, y0 + 5.5, 4.5), Vector3(18.4, 11.0, 1.6))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, y0, 5.3), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 1, 0.0, 4.2, 7.2)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, y0, 5.3), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 2, 8.6, 2.4, 5.2)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, y0, 5.3), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 2, 14.6, 2.4, 5.2)
	for s in [-1.0, 1.0]:
		for z in [1.0, -2.5, -6.0]:
			AtUtil.ionic(lm, "Marble", Vector3(s * 3.4, y0, z), 9.6, 0.5, 16, PI * 0.5)
		lm.box("Marble", Vector3(s * 3.4, y0 + 9.95, -2.5), Vector3(1.0, 0.7, 9.0))
	# Wings: block, cornice, low gabled roof and a three-column porch.
	for wing in [[-1.0, 10.0, 16.5, 1.5], [1.0, 7.3, 11.5, 0.5]]:
		var s: float = wing[0]
		var wd: float = wing[1]
		var ln: float = wing[2]
		var zc: float = wing[3]
		var xc := s * (14.2 + wd * 0.5)
		lm.box("Honey", Vector3(xc, y0 + 4.3, zc), Vector3(wd, 8.6, ln))
		lm.box("Marble", Vector3(xc, y0 + 8.9, zc), Vector3(wd + 0.8, 0.8, ln + 0.8))
		AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(xc, y0 + 9.3, zc), wd + 0.8, ln + 0.8, 1.3)
		for i in 3:
			AtUtil.doric(lm, "Marble", Vector3(s * 12.9, y0, zc + ln * 0.5 - 1.2 - 3.0 * float(i)), 5.7, 0.55, 14)
		lm.box("Marble", Vector3(s * 12.9, y0 + 5.7 + 0.45, zc + ln * 0.5 - 4.2), Vector3(1.2, 0.9, 7.8))
		lm.box("Honey", Vector3(s * 12.9, y0 + 5.7 + 1.3, zc + ln * 0.5 - 4.2), Vector3(1.1, 0.8, 7.8))
		lm.box("Marble", Vector3(s * 12.9, y0 + 5.7 + 1.9, zc + ln * 0.5 - 4.2), Vector3(1.8, 0.4, 8.2))
	lm.commit(model)

# --- Temple of Athena Nike ---------------------------------------------

## The little Ionic amphiprostyle temple (8.3 x 5.3 m, four columns each
## end, continuous frieze) on its limestone bastion with the parapet of
## the Nike balustrade. Origin at the bastion centre, front to +Z (the
## real front looks east; yaw_deg), top at 11.3 m.
static func athena_nike(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.box("Honey", Vector3(0, -1.1, 0), Vector3(13.0, 11.8, 14.0))
	lm.box("Marble", Vector3(0, 4.85, 0), Vector3(13.2, 0.2, 14.2))
	lm.box("Marble", Vector3(0, 5.35, -6.78), Vector3(13.0, 1.0, 0.45))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 6.28, 5.35, 0), Vector3(0.45, 1.0, 14.0))
		lm.box("Marble", Vector3(s * 3.85, 5.35, 6.78), Vector3(5.3, 1.0, 0.45))
	AtUtil.steps(lm, "Marble", Vector3(0, 5.4, 0), 5.34, 8.27, 3, 0.2, 0.25, 0.1)
	for s in [-1.0, 1.0]:
		for i in 4:
			AtUtil.ionic(lm, "Marble", Vector3(-2.2 + 1.47 * float(i), 5.4, s * 3.7), 4.0, 0.31, 14, 0.0)
		lm.box("Marble", Vector3(0, 9.625, s * 3.7), Vector3(5.3, 0.45, 0.75))
		lm.box("Dark", Vector3(0, 10.07, s * 3.7), Vector3(5.2, 0.45, 0.65))
		lm.box("Marble", Vector3(s * 2.2, 9.625, 0), Vector3(0.75, 0.45, 7.8))
		lm.box("Dark", Vector3(s * 2.2, 10.07, 0), Vector3(0.65, 0.45, 7.8))
		lm.box("Honey", Vector3(s * 1.85, 7.4, 0), Vector3(0.5, 4.0, 4.6))
	lm.box("Honey", Vector3(0, 7.4, -2.2), Vector3(3.8, 4.0, 0.5))
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(s * 1.35, 7.4, 2.2), Vector3(0.8, 4.0, 0.5))
	lm.box("Marble", Vector3(0, 10.425, 0), Vector3(5.9, 0.25, 8.3))
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0, 10.55, 0), 5.7, 8.3, 0.75, 0.2)
	lm.commit(model)
