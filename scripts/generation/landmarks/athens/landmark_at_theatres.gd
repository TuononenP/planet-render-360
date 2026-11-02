class_name LandmarkAtTheatres
extends RefCounted

## The Odeon of Herodes Atticus, the Theatre of Dionysus and the
## Panathenaic Stadium in true metres: real stepped rows on the correct
## plan curvature (semicircle, 190-degree cavea, marble horseshoe).

# --- Odeon of Herodes Atticus ---------------------------------------

## Origin at the middle of the footprint, the arcaded facade toward +Z
## (yaw_deg onto the street side). Semicircular cavea of 80 m: 20 lower
## and 11 upper rows round a diazoma, five stair-cut wedges each, round
## a paved semicircular orchestra; stage podium; the 28 m three-tier
## stone facade of 23 arches per tier on the Dionysiou Areopagitou side.
static func odeon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D7C0", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9B48E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4439", 3.0))
	lm.use("Floor", LandmarkMaterials.pbr("stone", "#B9AD98", 2.5))
	var c := Vector3(0, 0, 12.5)
	var orch := PackedVector2Array()
	for i in 21:
		var a := PI + PI * float(i) / 20.0
		orch.append(Vector2(c.x + cos(a) * 10.05, c.z + sin(a) * 10.05))
	lm.poly_prism("Floor", orch, -2.0, 1.0)
	AtUtil.cavea_wedges(lm, "Marble", "Floor", c, 10.0, 20, 0.9, 0.42, PI, TAU, 1.0, -3.0, 5, 0.05)
	AtUtil.cavea(lm, "Floor", c, 28.0, 1, 1.8, 0.0, PI, TAU, 9.4, -3.0)
	AtUtil.cavea_wedges(lm, "Marble", "Floor", c, 29.8, 11, 0.9, 0.42, PI, TAU, 9.4, -3.0, 5, 0.05)
	AtUtil.cavea(lm, "Stone", c, 39.7, 1, 1.4, 0.0, PI, TAU, 15.2, -3.0)
	# Stage podium, the wall closing the cavea corners and the stage block.
	lm.box("Floor", Vector3(0, -0.5, 14.0), Vector3(80.0, 5.0, 3.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 25.5, 5.9, 14.0), Vector3(31.0, 17.8, 3.0))
	lm.box("Stone", Vector3(0, 12.2, 21.5), Vector3(82.0, 30.4, 12.0))
	lm.box("Marble", Vector3(0, 27.7, 21.5), Vector3(83.0, 0.6, 13.0))
	# Facade: three tiers of arches (the top tier shorter) with string courses.
	var o := Vector3(0, 0, 27.5)
	SEuUtil.face_row(lm, "Shadow", o, Vector3.RIGHT, Vector3(0, 0, 1), 0.5, 23, 3.3, 2.4, 7.6)
	SEuUtil.face_row(lm, "Shadow", o, Vector3.RIGHT, Vector3(0, 0, 1), 9.0, 23, 3.3, 2.4, 7.6)
	SEuUtil.face_row(lm, "Shadow", o, Vector3.RIGHT, Vector3(0, 0, 1), 17.8, 23, 3.3, 2.0, 7.2)
	for y in [8.55, 17.05, 25.7]:
		lm.box("Marble", Vector3(0, y, 27.6), Vector3(82.4, 0.5, 0.4))
	# Inner face of the stage block (scaenae frons): niche tiers.
	var f := Vector3(0, 2.0, 15.5)
	SEuUtil.face_row(lm, "Shadow", f, Vector3.RIGHT, Vector3(0, 0, -1), 0.0, 9, 8.6, 3.0, 6.5)
	SEuUtil.face_row(lm, "Shadow", f, Vector3.RIGHT, Vector3(0, 0, -1), 8.5, 9, 8.6, 3.0, 6.5)
	SEuUtil.face_row(lm, "Shadow", f, Vector3.RIGHT, Vector3(0, 0, -1), 17.0, 9, 8.6, 3.0, 6.0)
	lm.commit(model)

# --- Theatre of Dionysus -----------------------------------------------

## Origin at the orchestra centre, the stage toward +Z (yaw_deg onto the
## south slope). Paved orchestra circle of 20 m, a ring of marble
## thrones (proedria), 20 lower rows, the diazoma and 14 upper rows over
## 190 degrees, each in 13 wedges split by stair aisles, the Roman stage
## front with its relief wall and the ruined stage building behind.
static func dionysus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Seat", LandmarkMaterials.pbr("limestone", "#BDB3A0", 2.5))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D7C0", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB892", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5A5148", 2.5))
	lm.use("Floor", LandmarkMaterials.pbr("stone", "#B7AB96", 2.5))
	var a0 := PI * 1.5 - 1.658
	var a1 := PI * 1.5 + 1.658
	var orch := PackedVector2Array()
	for i in 32:
		var a := TAU * float(i) / 32.0
		orch.append(Vector2(cos(a) * 10.05, sin(a) * 10.05))
	lm.poly_prism("Floor", orch, -0.8, 0.0)
	AtUtil.cavea(lm, "Marble", Vector3.ZERO, 10.0, 1, 0.9, 0.55, a0, a1, 0.0, -3.0)
	AtUtil.cavea_wedges(lm, "Seat", "Floor", Vector3.ZERO, 10.9, 20, 0.78, 0.4, a0, a1, 0.55, -3.0, 13, 0.04)
	AtUtil.cavea(lm, "Floor", Vector3.ZERO, 26.5, 1, 2.2, 0.0, a0, a1, 8.55, -3.0)
	AtUtil.cavea_wedges(lm, "Seat", "Floor", Vector3.ZERO, 28.7, 14, 0.78, 0.4, a0, a1, 8.55, -3.0, 13, 0.04)
	AtUtil.cavea(lm, "Honey", Vector3.ZERO, 39.6, 1, 1.3, 0.0, a0, a1, 15.0, -3.0)
	# Roman stage: platform, relief wall (Bema of Phaedrus), back wall.
	lm.box("Honey", Vector3(0, -0.5, 14.5), Vector3(44.0, 5.0, 6.0))
	lm.box("Marble", Vector3(0, 2.15, 14.5), Vector3(44.4, 0.3, 6.4))
	lm.box("Dark", Vector3(0, 1.0, 11.45), Vector3(38.0, 1.5, 0.12))
	for i in 7:
		lm.box("Marble", Vector3(-18.0 + 6.0 * float(i), 1.0, 11.4), Vector3(0.9, 1.7, 0.4))
	lm.box("Honey", Vector3(0, 2.75, 19.5), Vector3(48.0, 11.5, 2.0))
	for i in 6:
		lm.box("Marble", Vector3(-20.0 + 8.0 * float(i), 8.9, 19.5), Vector3(1.4, 1.3, 2.2))
	lm.commit(model)

# --- Panathenaic Stadium ---------------------------------------------

## Origin at the middle of the stadium, the open end toward +Z and the
## sphendone toward -Z (yaw_deg onto the valley). The white Pentelic
## marble horseshoe: a 204 m arena 33 m wide, 28 lower tiers, a
## diazoma and 17 upper tiers of 1 m treads (47 rows, 127 m across at
## the rim) and a continuous parapet at 20 m.
static func panathenaic(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE2D1", 3.0))
	lm.use("Track", LandmarkMaterials.pbr("gravel", "#C2AC8C", 4.0))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BB93", 3.0))
	var z_open := 125.5
	var z_c := -62.0
	var arena := PackedVector2Array()
	arena.append(Vector2(-16.5, z_open))
	for i in range(0, 25):
		var t := PI + PI * float(i) / 24.0
		arena.append(Vector2(16.5 * cos(t), z_c + 16.5 * sin(t)))
	arena.append(Vector2(16.5, z_open))
	lm.poly_prism("Track", arena, -1.0, 0.0)
	AtUtil.u_rows(lm, "Marble", z_open, z_c, 16.5, 28, 1.0, 0.42, 0.0, -3.0)
	AtUtil.u_band(lm, "Honey", z_open, z_c, 44.5, 47.0, -3.0, 11.76)
	AtUtil.u_rows(lm, "Marble", z_open, z_c, 47.0, 17, 1.0, 0.42, 11.76, -3.0)
	AtUtil.u_band(lm, "Honey", z_open, z_c, 64.0, 64.6, -3.0, 20.0)
	lm.commit(model)
