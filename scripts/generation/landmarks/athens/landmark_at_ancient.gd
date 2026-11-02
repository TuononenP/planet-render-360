class_name LandmarkAtAncient
extends RefCounted

## The Temple of Olympian Zeus, Hadrian's Arch and the Temple of
## Hephaestus in true metres.

# --- Temple of Olympian Zeus ----------------------------------------

## Origin at the middle of the platform, long axis along X (east +X). The
## 107.75 x 41.1 m stylobate of the dipteral Corinthian temple (8 x 20
## columns, three deep at the ends, 104 in all) with the 15 columns that
## still stand: a block of 13 in the south-east corner joined by
## architraves and two at the north-west, 17.25 m tall, plus the drums
## of the column that fell in 1852.
static func olympieion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D6C29B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A9285", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2D6BE", 3.0))
	var ys := 1.5
	AtUtil.steps(lm, "Stone", Vector3(0, ys, 0), 107.75, 41.1, 3, 0.5, 0.5, 2.5)
	# Cella foundations: the 1.2 m walls outlining the naos and the pronaos.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, ys + 0.3, s * 9.5), Vector3(70.0, 0.6, 1.2))
		lm.box("Stone", Vector3(s * 34.4, ys + 0.3, 0), Vector3(1.2, 0.6, 19.0))
	var keep: Array[Vector2i] = []
	for i in 3:
		for j in range(5, 8):
			keep.append(Vector2i(i, j))
	for i in range(3, 5):
		for j in range(6, 8):
			keep.append(Vector2i(i, j))
	keep.append(Vector2i(19, 0))
	keep.append(Vector2i(18, 0))
	for k in keep:
		var x := 53.0 - 5.58 * float(k.x)
		var z := -19.7 + 5.63 * float(k.y)
		AtUtil.corinthian(lm, "Honey", Vector3(x, ys, z), 17.25, 0.85, 20)
	# Architraves still lying on the south-east corner columns.
	var top := ys + 17.25
	lm.box("Marble", Vector3(53.0 - 5.58, top + 0.75, 19.7), Vector3(13.2, 1.5, 1.9))
	lm.box("Marble", Vector3(53.0, top + 0.75, 16.9), Vector3(1.9, 1.5, 7.6))
	# The fallen column: eight drums lying along the ground north of the block.
	for i in 8:
		var p := Vector3(27.0 - 2.0 * float(i), ys + 0.85, 4.0 + 0.25 * float(i % 3))
		AtUtil.cyl(lm, "Honey", p - Vector3(0.95, 0, 0), p + Vector3(0.95, 0, 0), 0.82, 12)
	lm.commit(model)

# --- Arch of Hadrian -------------------------------------------------

## Origin at the foot of the gateway, broad face toward +Z (yaw_deg onto
## the road). 18 m high, 13.5 m wide and 2.3 m deep: the round arch
## between two piers with pilasters, the lower entablature, and the
## upper tier with a central opening flanked by two Corinthian columns
## each side and capped by a small pediment.
static func hadrians_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4D8C0", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D5C19B", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5C5246", 2.5))
	AtUtil.steps(lm, "Honey", Vector3(0, 0.0, 0), 13.8, 2.6, 2, 0.25, 0.3, 2.0)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 4.725, 4.6, 0), Vector3(4.05, 9.2, 2.3))
		for z in [-1.2, 1.2]:
			var zz: float = z
			for x in [3.35, 6.0]:
				lm.box("Marble", Vector3(s * x, 4.2, zz), Vector3(0.7, 8.4, 0.3))
				lm.box("Honey", Vector3(s * x, 8.65, zz), Vector3(1.0, 0.5, 0.4))
	AtUtil.arch_wall(lm, "Marble", 0.0, 6.0, 2.7, 9.2, -1.15, 1.15)
	lm.box("Marble", Vector3(0, 9.65, 0), Vector3(13.5, 0.9, 2.3))
	lm.box("Honey", Vector3(0, 10.275, 0), Vector3(14.2, 0.35, 2.7))
	# Upper tier: piers, a central opening between paired columns, lintel.
	var yu := 10.45
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 5.1, yu + 2.7, 0), Vector3(3.3, 5.4, 2.3))
		for z in [-0.5, 0.5]:
			var zz: float = z
			AtUtil.corinthian(lm, "Marble", Vector3(s * 2.3, yu, zz * 1.2), 5.4, 0.32, 12)
	lm.box("Marble", Vector3(0, yu + 5.4 + 0.45, 0), Vector3(13.5, 0.9, 2.3))
	lm.box("Honey", Vector3(0, yu + 5.4 + 1.075, 0), Vector3(14.2, 0.35, 2.7))
	lm.gable("Marble", Vector3(0, yu + 5.4 + 1.25, 0), 8.0, 2.6, 0.95, Basis(), 0.0, "Honey")
	lm.commit(model)

# --- Temple of Hephaestus --------------------------------------------

## Origin at the middle of the stylobate (13.7 x 31.8 m), entrance end
## toward +Z (yaw_deg turns it east). The best-preserved Doric temple:
## 6 x 13 fluted columns 5.7 m tall, triglyph frieze, low pediments, the
## cella with the pronaos and opisthodomos each distyle in antis, and the
## pitched roof (about 10.6 m to the ridge).
static func hephaestus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DDD0B6", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB68A", 2.5))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4F4A44", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A9745C", 2.5))
	var ys := 0.9
	AtUtil.steps(lm, "Marble", Vector3(0, ys, 0), 13.708, 31.775, 3, 0.3, 0.35, 3.0)
	var cx := 6.35
	var cz := 15.39
	for i in 6:
		for s in [-1.0, 1.0]:
			AtUtil.doric(lm, "Marble", Vector3(-cx + 2.54 * float(i), ys, s * cz), 5.72, 0.5, 16)
	for i in range(1, 12):
		for s in [-1.0, 1.0]:
			AtUtil.doric(lm, "Marble", Vector3(s * cx, ys, -cz + 2.565 * float(i)), 5.72, 0.5, 16)
	var yt := ys + 5.72
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, yt + 0.475, s * 15.4), Vector3(13.4, 0.95, 1.4))
		lm.box("Honey", Vector3(0, yt + 1.425, s * 15.4), Vector3(13.3, 0.95, 1.3))
		lm.box("Marble", Vector3(0, yt + 2.175, s * 15.4), Vector3(14.4, 0.55, 2.3))
		lm.box("Marble", Vector3(s * cx, yt + 0.475, 0), Vector3(1.4, 0.95, 31.0))
		lm.box("Honey", Vector3(s * cx, yt + 1.425, 0), Vector3(1.3, 0.95, 30.9))
		lm.box("Marble", Vector3(s * cx, yt + 2.175, 0), Vector3(2.3, 0.55, 32.2))
		AtUtil.row_boxes(lm, "Dark", Vector3(-cx, yt + 1.425, s * 16.1), Vector3(cx, yt + 1.425, s * 16.1),
			11, Vector3(0.42, 0.85, 0.14))
		AtUtil.row_boxes(lm, "Dark", Vector3(s * 7.05, yt + 1.425, -cz), Vector3(s * 7.05, yt + 1.425, cz),
			25, Vector3(0.14, 0.85, 0.42))
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0, yt + 2.45, 0), 14.0, 33.0, 1.55, 0.3)
	# Cella: side walls ending in antae, cross walls, two columns in antis.
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(s * 3.25, ys + 3.8, 0), Vector3(0.9, 7.6, 20.0))
		lm.box("Honey", Vector3(0, ys + 3.8, s * 6.5), Vector3(6.4, 7.6, 0.8))
		for x in [-1.4, 1.4]:
			AtUtil.doric(lm, "Marble", Vector3(x, ys, s * 9.7), 5.2, 0.42, 14)
		lm.box("Marble", Vector3(0, ys + 5.2 + 0.4, s * 9.7), Vector3(6.2, 0.8, 0.9))
		lm.box("Dark", Vector3(0, ys + 1.5, s * 6.95), Vector3(1.8, 3.0, 0.1))
	lm.commit(model)
