class_name LandmarkRmLHills
extends RefCounted

## Piazza del Campidoglio and the Quirinal Palace with its piazza, in
## true metres.

# --- Capitoline Hill ------------------------------------------------------

## Origin at Michelangelo's piazza, over the equestrian Marcus Aurelius;
## y = 0 is the foot of the Cordonata and the piazza paving lies at 8 m
## on a stone platform. Palazzo Senatorio closes the -Z end (double
## stair, rusticated base, giant pilasters, the 50 m campanile); Palazzo
## Nuovo (-X) and Palazzo dei Conservatori (+X) face each other across
## the square and the Cordonata climbs from +Z between the Dioscuri.
static func capitoline(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D3C29E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DCC4", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#B98F66", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CFC2A6", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5B6B50", 0.5, 0.5))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	var py := 8.0
	lm.box("Stone", Vector3(0, py * 0.5 - 0.1, -22.0), Vector3(92.0, py - 0.2, 100.0))
	lm.box("Steps", Vector3(0, py - 0.1, -22.0), Vector3(92.0, 0.2, 100.0))
	# Cordonata with balustrades, the Dioscuri at the top, lions at the foot.
	LandmarkRmLUtil.flight(lm, "Steps", 0.0, 15.0, 78.0, 28.0, 0.2, py, 34)
	for s in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(s * 8.3, 1.2, 78.0), Vector3(s * 8.3, 9.2, 28.0), 0.6, 1.0, Vector3.RIGHT)
		lm.box("Trim", Vector3(s * 27.5, py + 0.5, 27.8), Vector3(37.0, 1.0, 0.6))
		lm.box("Marble", Vector3(s * 10.8, py + 0.5, 30.0), Vector3(3.2, 1.0, 5.4))
		LandmarkRmLUtil.horse(lm, "Marble", Vector3(s * 10.8, py + 1.0, 30.0))
		LandmarkKits.statue_figure(lm, "Marble", Vector3(s * 9.4, py + 1.0, 28.8), 5.0)
		lm.box("Bronze", Vector3(s * 9.0, 1.1, 77.0), Vector3(1.6, 1.2, 3.0))
	# Marcus Aurelius on his pedestal.
	lm.box("Marble", Vector3(0, py + 1.5, 0), Vector3(3.4, 3.0, 6.4))
	LandmarkRmLUtil.horse(lm, "Bronze", Vector3(0, py + 3.0, 0))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, py + 5.4, -0.2), 2.4)
	_senatorio(lm, py)
	for s in [-1.0, 1.0]:
		var out := Vector3(-s, 0, 0)
		LandmarkRmLUtil.block(lm, "Stone", Vector3(s * 33.0, py, -22.0), 40.0, 22.0, 22.0, out, 2, 7, 2.0, 4.4)
		LandmarkRmLUtil.pilasters(lm, "Trim", Vector3(s * 22.0, py, -22.0), out, 8, 5.0, 17.0, 1.2, 0.6)
		lm.box("Trim", Vector3(s * 33.0, py + 23.3, -22.0), Vector3(22.6, 1.0, 41.0))
		for i in 7:
			LandmarkKits.statue_figure(lm, "Marble", Vector3(s * 22.6, py + 23.8, -22.0 + (float(i) - 3.0) * 5.5), 3.2)
	lm.commit(model)

## Palazzo Senatorio at z = -42 with the Campanile above its centre.
static func _senatorio(lm: LandmarkMesh, py: float) -> void:
	lm.box("Stone", Vector3(0, py + 4.8, -57.0), Vector3(48.0, 9.6, 30.0))
	lm.box("Plaster", Vector3(0, py + 17.8, -57.0), Vector3(48.0, 16.4, 30.0))
	lm.box("Trim", Vector3(0, py + 26.4, -57.0), Vector3(50.4, 0.8, 32.0))
	lm.gable("Tile", Vector3(0, py + 26.8, -57.0), 30.0, 48.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	LandmarkRmLUtil.pilasters(lm, "Trim", Vector3(0, py + 9.6, -42.0), Vector3(0, 0, 1), 9, 5.6, 15.8, 1.2, 0.6)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, py, -42.0), Vector3.RIGHT, Vector3(0, 0, 1), 1.0, 8, 5.6, 2.2, 5.4)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, py + 9.6, -42.0), Vector3.RIGHT, Vector3(0, 0, 1), 3.0, 8, 5.6, 1.8, 4.6)
	# Michelangelo's double ramp meeting at the central landing.
	for s in [-1.0, 1.0]:
		for k in 14:
			var h := 9.6 * float(k + 1) / 14.0
			lm.box("Steps", Vector3(s * (18.5 - (float(k) + 0.5) * 15.0 / 14.0), py + h * 0.5, -40.2),
				Vector3(15.0 / 14.0, h, 3.6))
	lm.box("Steps", Vector3(0, py + 4.8, -40.2), Vector3(7.0, 9.6, 3.6))
	SEuUtil.opening(lm, "Shadow", Vector3(0, py, -38.34), Vector3.RIGHT, Vector3.UP, 3.6, 5.2)
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, py + 0.2, -38.6), 4.4)
	LandmarkRmLUtil.tower(lm, "Plaster", Vector3(0, py + 27.0, -57.0),
		PackedVector2Array([Vector2(5.5, 3.7), Vector2(5.5, 3.3)]), 15.0)

# --- Quirinal Palace ------------------------------------------------------

## Origin between the palace and the Dioscuri fountain; the palace faces
## the piazza along +Z (yaw_deg turns it onto the hill). The 110 m
## yellow-ochre front in three storeys under a tiled roof, the central
## pavilion with Bernini's balcony portal and the Torrino clock tower
## (38 m) behind; in the piazza the red-granite obelisk between the
## colossal Dioscuri and their horses over the granite basin.
static func quirinal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D4B57C", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DCC4", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B5B4B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBE9E", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	lm.use("Gold", LandmarkMaterials.gold())
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(-45.0, 0, -51.0), 110.0, 22.0, 22.0, Vector3(0, 0, 1), 3, 21, 1.5, 3.2)
	lm.gable("Tile", Vector3(-45.0, 22.8, -51.0), 22.0, 110.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Plaster")
	# Central pavilion with the portal, balcony and pediment.
	lm.box("Plaster", Vector3(-45.0, 12.0, -39.0), Vector3(24.0, 24.0, 2.0))
	lm.box("Trim", Vector3(-45.0, 24.4, -39.0), Vector3(25.0, 0.8, 3.0))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(-45.0, 24.8, -39.0), 24.0, 3.0, 2.4)
	SEuUtil.column_row(lm, "Trim", Vector3(-48.6, 0, -37.5), Vector3(-41.4, 0, -37.5), 4, 9.0, 0.6, 12)
	lm.box("Trim", Vector3(-45.0, 9.6, -37.7), Vector3(9.6, 1.2, 2.0))
	lm.box("Trim", Vector3(-45.0, 10.6, -37.0), Vector3(9.6, 1.0, 0.4))
	SEuUtil.opening(lm, "Shadow", Vector3(-45.0, 0, -37.94), Vector3.RIGHT, Vector3.UP, 3.2, 6.0)
	LandmarkRmLUtil.tower(lm, "Plaster", Vector3(-45.0, 24.0, -50.0),
		PackedVector2Array([Vector2(4.0, 4.6), Vector2(4.5, 4.0)]), 14.0)
	# Piazza fountain: basin, pedestal, obelisk and the Dioscuri.
	var o := Vector3(43.5, 0, 35.6)
	var rim := PackedVector2Array([Vector2(5.4, 0.0), Vector2(5.4, 1.0), Vector2(4.6, 1.0), Vector2(4.6, 0.7)])
	lm.lathe("Stone", o, rim, 24, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", o + Vector3(0, 0.85, 0), Vector3.UP, 4.7, 24)
	lm.box("Stone", o + Vector3(0, 2.0, 0), Vector3(3.0, 4.0, 3.0))
	LandmarkRmLUtil.obelisk(lm, "Granite", o + Vector3(0, 4.0, 0), 14.63, 0.85)
	SEuUtil.finial(lm, "Gold", o + Vector3(0, 18.63, 0), 2.2)
	for s in [-1.0, 1.0]:
		lm.box("Stone", o + Vector3(s * 7.0, 1.0, 0), Vector3(3.2, 2.0, 6.2))
		LandmarkRmLUtil.horse(lm, "Marble", o + Vector3(s * 7.0, 2.0, -0.2))
		LandmarkKits.statue_figure(lm, "Marble", o + Vector3(s * 7.0 - s * 1.5, 2.0, 0.6), 5.2, true)
	lm.commit(model)
