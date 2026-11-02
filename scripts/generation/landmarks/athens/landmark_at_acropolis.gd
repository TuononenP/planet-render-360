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
## it onto the real axis). The 11.6 m wide temple on two levels (the
## west ground 3.2 m below the east floor): the hexastyle Ionic east
## porch with its door and two windows, the west wall with four engaged
## Ionic half-columns and windows over a high basement, the 7.6 m
## columns of the tetrastyle north porch on the lower ground round the
## great north door with its consoles, and the Caryatid porch: six
## 2.3 m maidens on a 1.8 m podium wall. Eleusinian frieze all round,
## marble tiled roof, ridge at 13.8 m.
static func erechtheion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5347", 2.5))
	var e := 3.2  # east floor level above the west ground
	var rq := Basis(Vector3.UP, PI * 0.5)
	AtUtil.steps(lm, "Marble", Vector3(9.4, e, 0), 4.8, 12.4, 3, 0.35, 0.35)
	lm.box("Honey", Vector3(-2.35, 5.8, 0), Vector3(18.7, 11.6, 11.6))
	# Wall base and the anthemion band under the frieze.
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(-2.35, 0.35, s * 5.85), Vector3(18.9, 0.7, 0.2))
		lm.box("Marble", Vector3(-2.35, 9.55, s * 5.86), Vector3(18.9, 0.5, 0.2))
	# East porch: six Ionic columns, entablature, door and windows.
	for i in 6:
		AtUtil.ionic(lm, "Marble", Vector3(10.9, e, -5.0 + 2.0 * float(i)), 6.6, 0.42, 24, PI * 0.5)
	AtUtil.entab(lm, "Marble", "Dark", Vector3(10.9, e + 6.6, 0), 12.0, 1.3, 0.9, 0.8, 0.5, rq)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(8.95, e + 7.05, s * 5.6), Vector3(3.9, 0.9, 1.0))
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(7.0, e, 0), Vector3.RIGHT, 2.2, 4.6)
	for s in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "Marble", "Shadow", Vector3(7.0, e + 3.4, s * 3.2), Vector3.RIGHT, 1.3, 2.2)
	# Frieze and cornice round the long walls and the west end.
	for s in [-1.0, 1.0]:
		AtUtil.entab(lm, "Honey", "Dark", Vector3(-2.35, 9.8, s * 5.6), 18.7, 0.9, 0.9, 0.8, 0.5)
	AtUtil.entab(lm, "Honey", "Dark", Vector3(-11.25, 9.8, 0), 12.0, 0.9, 0.9, 0.8, 0.5, rq)
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0.1, 12.0, 0), 12.4, 24.4, 1.8, 0.3, rq)
	AtUtil.roof_tiles(lm, "Roof", Vector3(0.1, 12.0, 0), 12.4, 24.4, 1.8, rq, 0.3, 0.75, true)
	# West wall: basement, ledge, four engaged half-columns and windows.
	lm.box("Marble", Vector3(-11.9, 4.8, 0), Vector3(0.7, 0.4, 11.8))
	lm.box("Marble", Vector3(-11.85, 0.3, 0), Vector3(0.6, 0.6, 11.8))
	for i in 4:
		AtUtil.ionic(lm, "Marble", Vector3(-12.0, 5.0, -3.9 + 2.6 * float(i)), 4.8, 0.4, 24, PI * 0.5)
	for i in 3:
		LandmarkDetail.window(lm, "Marble", "Shadow", Vector3(-11.7, 7.6, -2.6 + 2.6 * float(i)),
			Vector3.LEFT, 1.4, 2.6)
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(-11.7, 0.0, 3.2), Vector3.LEFT, 1.2, 2.4)
	# North porch: four Ionic columns on the front, one at each inner side.
	AtUtil.steps(lm, "Marble", Vector3(-5.5, 0.5, -9.2), 6.6, 6.4, 2, 0.25, 0.3)
	for i in 4:
		AtUtil.ionic(lm, "Marble", Vector3(-8.1 + 1.75 * float(i), 0.5, -11.8), 7.6, 0.5, 24, 0.0)
	for x in [-8.1, -2.85]:
		AtUtil.ionic(lm, "Marble", Vector3(x, 0.5, -9.0), 7.6, 0.5, 24, PI * 0.5)
	AtUtil.entab(lm, "Marble", "Dark", Vector3(-5.5, 8.1, -11.8), 7.0, 1.3, 0.9, 0.8, 0.5)
	for s in [-1.0, 1.0]:
		AtUtil.entab(lm, "Marble", "Dark", Vector3(-5.5 + s * 2.65, 8.1, -8.8), 6.0, 1.3, 0.9, 0.8, 0.5, rq)
	lm.box("Marble", Vector3(-5.5, 9.9, -8.6), Vector3(7.0, 0.3, 6.4))
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(-5.5, 10.3, -8.6), 7.4, 6.8, 1.4)
	AtUtil.roof_tiles(lm, "Roof", Vector3(-5.5, 10.3, -8.6), 7.4, 6.8, 1.4, Basis(), 0.3, 0.7, true)
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(-5.5, 0.5, -5.8), Vector3.FORWARD, 2.4, 4.9, true)
	# Caryatid porch: six maidens on a high podium under a flat slab.
	lm.box("Honey", Vector3(-8.0, 2.2, 7.8), Vector3(6.2, 4.4, 4.0))
	lm.box("Marble", Vector3(-8.0, 0.25, 7.8), Vector3(6.5, 0.5, 4.3))
	lm.box("Marble", Vector3(-8.0, 4.5, 7.8), Vector3(6.5, 0.25, 4.3))
	for i in 4:
		AtUtil.caryatid(lm, "Marble", Vector3(-10.2 + 1.47 * float(i), 4.625, 9.2), 2.6, 0.32)
	for x in [-10.2, -5.8]:
		AtUtil.caryatid(lm, "Marble", Vector3(x, 4.625, 7.2), 2.6, 0.32)
	for k in 3:
		lm.box("Marble", Vector3(-8.0, 7.35 + 0.17 * float(k), 7.8), Vector3(6.6 + 0.08 * float(k), 0.17,
			4.4 + 0.08 * float(k)))
	for i in 9:
		lm.disc("Marble", Vector3(-10.9 + 0.72 * float(i), 7.55, 10.05), Vector3.BACK, 0.12, 8)
	lm.box("Marble", Vector3(-8.0, 8.0, 7.8), Vector3(6.9, 0.5, 4.7))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-11.45, 7.85, 10.15), Vector3(-4.55, 7.85, 10.15),
		Vector3.BACK, 0.45)
	lm.commit(model)

# --- Propylaea --------------------------------------------------------

## Mnesikles' gateway, origin at the middle of the passage, west front
## toward +Z (yaw_deg). The hexastyle Doric west porch (8.8 m columns,
## the central bay one triglyph wider for the chariot road) under its
## pediment, the cross wall with its five graded doors (the central one
## 4.1 x 7.4 m), the three Ionic columns each side of the passage, the
## east porch, the north wing (Pinakotheke, a door and two windows) and
## the smaller south wing, each with a tristyle in antis Doric porch
## toward the road. Ridge at 15.7 m above the lowest step.
static func propylaea(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5347", 2.5))
	var y0 := 1.4
	lm.box("Honey", Vector3(0, y0 * 0.5, 0), Vector3(50.0, y0, 24.0))
	for k in range(1, 5):
		var top := y0 - 0.35 * float(k)
		lm.box("Marble", Vector3(0, top * 0.5, 12.3 + 0.6 * float(k)), Vector3(20.0, top, 0.6))
	var xs: Array[float] = [-7.9, -5.2, -2.5, 2.5, 5.2, 7.9]
	var h := 8.57
	for zc in [11.0, -10.5]:
		var z: float = zc
		var o := signf(z)
		for x in xs:
			AtUtil.doric(lm, "Marble", Vector3(x, y0, z), h, 0.78, 20)
		var top := AtUtil.entab(lm, "Marble", "Honey", Vector3(0, y0 + h, z), 18.4, 1.6, 1.1, 1.4, 0.9,
			Basis(), false, false)
		# Triglyphs over each column, one in each bay, two in the wide middle bay.
		var tx: Array[float] = []
		for i in xs.size():
			tx.append(xs[i])
			if i < xs.size() - 1:
				if i == 2:
					tx.append(-0.85)
					tx.append(0.85)
				else:
					tx.append((xs[i] + xs[i + 1]) * 0.5)
		for x in tx:
			AtUtil.triglyphs(lm, "Dark", Vector3(x, y0 + h + 1.8, z + 0.8 * o),
				Vector3(x + 0.01, y0 + h + 1.8, z + 0.8 * o), 1, Vector3(0, 0, o), 1.15, 0.55)
		lm.box("Marble", Vector3(0, top - 0.2, 0.25), Vector3(18.6, 0.4, 0.3))
	var yc := y0 + h + 3.4
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0, yc, 0.25), 19.0, 24.0, 2.3)
	AtUtil.roof_tiles(lm, "Roof", Vector3(0, yc, 0.25), 19.0, 24.0, 2.3, Basis(), 0.3, 0.8)
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(s * 9.2, y0 + 5.99, 0.2), Vector3(1.4, 11.97, 21.5))
		lm.box("Marble", Vector3(s * 9.2, yc - 0.45, 0.2), Vector3(2.0, 0.9, 21.5))
		for z in [10.3, -9.8]:
			lm.box("Marble", Vector3(s * 9.2, y0 + h * 0.5, z), Vector3(1.6, h, 1.0))
	# Cross wall with five graded doors and the Ionic columns of the passage.
	lm.box("Honey", Vector3(0, y0 + 5.5, 4.5), Vector3(18.4, 11.0, 1.6))
	var doors := [[0.0, 4.13, 7.38], [-4.3, 2.8, 5.6], [4.3, 2.8, 5.6], [-7.3, 1.45, 3.4], [7.3, 1.45, 3.4]]
	for d in doors:
		for side in [1.0, -1.0]:
			var fz: float = 4.5 + 0.8 * float(side)
			AtUtil.doorway(lm, "Marble", "Shadow", Vector3(float(d[0]), y0, fz), Vector3(0, 0, float(side)),
				float(d[1]), float(d[2]))
	for s in [-1.0, 1.0]:
		for z in [1.0, -2.5, -6.0]:
			AtUtil.ionic(lm, "Marble", Vector3(s * 3.4, y0, z), 9.6, 0.5, 24, PI * 0.5)
		lm.box("Marble", Vector3(s * 3.4, y0 + 9.95, -2.5), Vector3(1.0, 0.7, 9.0))
	# Marble ceiling beams over the passage.
	for i in 6:
		lm.box("Marble", Vector3(0, y0 + 10.45, 3.4 - 1.9 * float(i)), Vector3(6.6, 0.5, 0.5))
	# Wings: block, cornice, low gabled roof and a tristyle in antis porch.
	for wing in [[-1.0, 10.0, 16.5, 1.5], [1.0, 7.3, 11.5, 0.5]]:
		var s: float = wing[0]
		var wd: float = wing[1]
		var ln: float = wing[2]
		var zc: float = wing[3]
		var xc := s * (14.2 + wd * 0.5)
		lm.box("Honey", Vector3(xc, y0 + 4.3, zc), Vector3(wd, 8.6, ln))
		lm.box("Marble", Vector3(xc, y0 + 0.3, zc), Vector3(wd + 0.3, 0.6, ln + 0.3))
		lm.box("Marble", Vector3(xc, y0 + 8.9, zc), Vector3(wd + 0.8, 0.8, ln + 0.8))
		LandmarkDetail.cornice(lm, "Marble", Vector3(xc - wd * 0.5 - 0.4, y0 + 9.3, zc + ln * 0.5 + 0.4),
			Vector3(xc + wd * 0.5 + 0.4, y0 + 9.3, zc + ln * 0.5 + 0.4), Vector3.BACK, 0.4, false)
		AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(xc, y0 + 9.3, zc), wd + 0.8, ln + 0.8, 1.3)
		AtUtil.roof_tiles(lm, "Roof", Vector3(xc, y0 + 9.3, zc), wd + 0.8, ln + 0.8, 1.3, Basis(), 0.3, 0.8)
		var pz := zc + ln * 0.5 - 4.2
		for i in 3:
			AtUtil.doric(lm, "Marble", Vector3(s * 12.9, y0, zc + ln * 0.5 - 1.2 - 3.0 * float(i)), 5.7, 0.55, 20)
		lm.box("Marble", Vector3(s * 12.9, y0 + 2.85, pz - 4.6), Vector3(1.2, 5.7, 0.9))
		AtUtil.entab(lm, "Marble", "Honey", Vector3(s * 12.9, y0 + 5.7, pz), 8.2, 1.2, 0.9, 0.8, 0.4,
			Basis(Vector3.UP, PI * 0.5), false, false)
		AtUtil.triglyphs(lm, "Dark", Vector3(s * 12.25, y0 + 7.0, pz + 3.9), Vector3(s * 12.25, y0 + 7.0, pz - 3.9),
			7, Vector3(-s, 0, 0), 0.75, 0.4)
	# Pinakotheke front: the door and two windows on its porch wall.
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(-14.2, y0, 3.6), Vector3.RIGHT, 1.8, 3.6)
	for z in [6.8, 0.4]:
		LandmarkDetail.window(lm, "Marble", "Shadow", Vector3(-14.2, y0 + 3.0, z), Vector3.RIGHT, 1.2, 1.9)
	lm.commit(model)

# --- Temple of Athena Nike ---------------------------------------------

## The little Ionic amphiprostyle temple (8.3 x 5.5 m, four monolithic
## columns each end in 7:1 proportion, continuous frieze, 7 m to the
## pediment) on its limestone bastion with the parapet of the Nike
## balustrade, whose outer face carries the relief Victories. Origin at
## the bastion centre, front to +Z (the real front looks east; yaw_deg).
static func athena_nike(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5347", 2.5))
	lm.box("Honey", Vector3(0, 2.425, 0), Vector3(13.0, 4.85, 14.0))
	lm.box("Honey", Vector3(0, 0.3, 0), Vector3(13.4, 0.6, 14.4))
	lm.box("Marble", Vector3(0, 4.85, 0), Vector3(13.2, 0.2, 14.2))
	# Parapet with the relief Victories on its outer face (open to the front).
	var walls := [[Vector3(0, 0, -6.78), 13.0, 0.0, Vector3.FORWARD], [Vector3(-6.28, 0, 0), 14.0, PI * 0.5, Vector3.LEFT],
		[Vector3(6.28, 0, 0), 14.0, PI * 0.5, Vector3.RIGHT], [Vector3(-3.85, 0, 6.78), 5.3, 0.0, Vector3.BACK],
		[Vector3(3.85, 0, 6.78), 5.3, 0.0, Vector3.BACK]]
	for wl in walls:
		var p: Vector3 = wl[0]
		var ln: float = wl[1]
		var b := Basis(Vector3.UP, float(wl[2]))
		lm.box("Marble", p + Vector3(0, 5.45, 0), Vector3(ln, 1.0, 0.4), b)
		lm.box("Marble", p + Vector3(0, 6.0, 0), Vector3(ln + 0.1, 0.12, 0.55), b, 0.0)
		var out: Vector3 = wl[3]
		var n := int(ln / 2.2)
		for i in n:
			var c := p + b.x * (-ln * 0.5 + ln * (float(i) + 0.5) / float(n)) + out * 0.22 + Vector3(0, 5.0, 0)
			LandmarkKits.statue_figure(lm, "Marble", c, 0.9, i % 2 == 0)
	AtUtil.steps(lm, "Marble", Vector3(0, 5.4, 0), 5.34, 8.27, 3, 0.2, 0.25)
	for s in [-1.0, 1.0]:
		for i in 4:
			AtUtil.ionic(lm, "Marble", Vector3(-2.2 + 1.47 * float(i), 5.4, s * 3.7), 4.04, 0.29, 24, 0.0)
		AtUtil.entab(lm, "Marble", "Honey", Vector3(0, 9.44, s * 3.7), 5.3, 0.75, 0.42, 0.42, 0.3)
		AtUtil.entab(lm, "Marble", "Honey", Vector3(s * 2.2, 9.44, 0), 7.0, 0.75, 0.42, 0.42, 0.3,
			Basis(Vector3.UP, PI * 0.5))
		lm.box("Honey", Vector3(s * 1.85, 7.4, 0), Vector3(0.5, 4.0, 4.6))
		lm.box("Marble", Vector3(s * 1.85, 7.4, 2.35), Vector3(0.62, 4.0, 0.3))
	lm.box("Honey", Vector3(0, 7.4, -2.2), Vector3(3.8, 4.0, 0.5))
	# The cella front: two pillars between the antae, the door behind.
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(s * 0.55, 7.4, 2.2), Vector3(0.45, 4.0, 0.45))
	lm.box("Marble", Vector3(0, 9.2, 2.2), Vector3(3.8, 0.4, 0.55))
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(0, 5.4, -1.95), Vector3.BACK, 1.6, 2.9)
	lm.box("Marble", Vector3(0, 10.66, 0), Vector3(5.9, 0.1, 8.3))
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0, 10.7, 0), 5.7, 8.3, 0.8, 0.2)
	AtUtil.roof_tiles(lm, "Roof", Vector3(0, 10.7, 0), 5.7, 8.3, 0.8, Basis(), 0.2, 0.55, true)
	lm.commit(model)
