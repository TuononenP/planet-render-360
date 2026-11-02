class_name LandmarkAtAgora
extends RefCounted

## The Stoa of Attalos, the Tower of the Winds, the Choragic Monument of
## Lysicrates and the Monument of Philopappos in true metres.

# --- Stoa of Attalos ---------------------------------------------------

## Origin at the middle of the stoa, colonnade toward +Z (yaw_deg turns it
## west onto the Agora). The reconstructed two-storey hall, 115 x 19.6 m,
## 12 m to the ridge: outer Doric colonnade below and Ionic above, the
## inner Ionic row, a back wall and a shop wall with 21 doors per floor,
## projecting end pavilions and the low pitched tile roof.
static func stoa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D7BF", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CBB993", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4439", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B2663F", 3.0))
	var y0 := 0.6
	AtUtil.steps(lm, "Stone", Vector3(0, y0, 0), 115.0, 19.6, 2, 0.3, 0.5, 2.0)
	lm.box("Stone", Vector3(0, 5.8, -9.1), Vector3(115.0, 10.4, 1.4))
	lm.box("Stone", Vector3(0, 5.8, -5.0), Vector3(115.0, 10.4, 0.8))
	lm.box("Stone", Vector3(0, 6.5, 2.0), Vector3(115.0, 0.4, 14.0))
	for i in 21:
		var x := -52.0 + 5.2 * float(i)
		lm.box("Shadow", Vector3(x, y0 + 1.6, -4.55), Vector3(1.8, 3.2, 0.1))
		lm.box("Shadow", Vector3(x, 6.7 + 1.6, -4.55), Vector3(1.8, 3.2, 0.1))
	# Outer colonnades: Doric below (41 columns), Ionic above.
	for i in 41:
		var x := -50.0 + 2.5 * float(i)
		AtUtil.doric(lm, "Marble", Vector3(x, y0, 8.5), 4.8, 0.37, 12)
		AtUtil.ionic(lm, "Marble", Vector3(x, 6.7, 8.0), 3.3, 0.28, 10, 0.0)
	for i in 22:
		AtUtil.ionic(lm, "Marble", Vector3(-52.5 + 5.0 * float(i), y0, 1.5), 6.1, 0.4, 10, 0.0)
	lm.box("Marble", Vector3(0, 5.675, 8.5), Vector3(101.0, 0.55, 1.0))
	lm.box("Stone", Vector3(0, 6.225, 8.5), Vector3(100.9, 0.55, 0.9))
	lm.box("Marble", Vector3(0, 6.6, 8.5), Vector3(101.2, 0.2, 1.3))
	AtUtil.row_boxes(lm, "Shadow", Vector3(-50.0, 6.225, 9.0), Vector3(50.0, 6.225, 9.0), 81,
		Vector3(0.3, 0.45, 0.1))
	lm.box("Marble", Vector3(0, 7.25, 8.0), Vector3(101.0, 1.1, 0.3))
	lm.box("Marble", Vector3(0, 10.2, 8.0), Vector3(101.0, 0.4, 0.9))
	lm.box("Stone", Vector3(0, 10.575, 8.0), Vector3(100.9, 0.35, 0.8))
	lm.box("Marble", Vector3(0, 10.875, 8.0), Vector3(101.2, 0.25, 1.1))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 54.25, 5.8, 7.5), Vector3(6.5, 10.4, 5.0))
		lm.box("Marble", Vector3(s * 54.25, 10.9, 7.5), Vector3(7.0, 0.25, 5.6))
		lm.box("Shadow", Vector3(s * 54.25, 2.4, 10.05), Vector3(2.0, 3.4, 0.1))
		lm.box("Shadow", Vector3(s * 54.25, 8.4, 10.05), Vector3(2.0, 2.6, 0.1))
	AtUtil.roof(lm, "Roof", "Marble", "Stone", Vector3(0, 11.0, 0), 19.6, 115.0, 1.0, 0.3,
		Basis(Vector3.UP, PI * 0.5))
	lm.commit(model)

# --- Tower of the Winds --------------------------------------------------

## Origin at the centre of the octagon, faces to the compass points: the
## 8 m marble Horologion of Andronikos Kyrrhestes, 12 m with its conical
## roof of marble slabs, the frieze of the eight winds over eight
## sundials, the two columned porches (north-east and north-west) and the
## ruined cylindrical cistern on the south side.
static func tower_of_winds(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DFD3BA", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB78F", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F463B", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#D5C8AC", 2.0))
	var rot := PI / 8.0
	var rr := 4.0 / cos(rot)
	lm.frustum("Honey", Vector3(0, -2.0, 0), 6.2, 6.2, 2.3, 8, rot)
	lm.frustum("Marble", Vector3(0, 0.3, 0), 5.9, 5.9, 0.3, 8, rot)
	lm.frustum("Marble", Vector3(0, 0.3, 0), 5.3, 5.3, 0.3, 8, rot)
	lm.frustum("Marble", Vector3(0, 0.6, 0), rr, rr, 8.3, 8, rot)
	lm.frustum("Honey", Vector3(0, 7.4, 0), rr * 1.02, rr * 1.02, 1.1, 8, rot)
	lm.frustum("Marble", Vector3(0, 8.5, 0), rr * 1.1, rr * 1.1, 0.4, 8, rot)
	lm.lathe("Roof", Vector3.ZERO, PackedVector2Array([Vector2(4.95, 8.9), Vector2(0.35, 11.6),
		Vector2(0.35, 11.75), Vector2(0, 12.0)]), 8, 1.0, 1.0, rot, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, atan2(dir.x, dir.z))
		var tang := b.x
		# Wind relief panel in the frieze and the sundial lines below it.
		lm.box("Shadow", dir * 4.1 + Vector3(0, 7.95, 0), Vector3(1.9, 0.8, 0.12), b)
		var apex := dir * 4.04 + Vector3(0, 6.6, 0)
		for j in 5:
			var foot := dir * 4.04 + tang * (-1.6 + 0.8 * float(j)) + Vector3(0, 2.4, 0)
			lm.beam("Shadow", apex, foot, 0.06, 0.04, tang)
	# Porches on the north-east and north-west faces.
	for a in [-PI * 0.25, -PI * 0.75]:
		var dir := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, atan2(dir.x, dir.z))
		lm.box("Marble", dir * 5.0 + Vector3(0, 0.3, 0), Vector3(3.0, 0.6, 2.2), b)
		lm.box("Shadow", dir * 4.04 + Vector3(0, 2.0, 0), Vector3(1.3, 2.6, 0.1), b)
		for t in [-0.95, 0.95]:
			AtUtil.corinthian(lm, "Marble", dir * 5.6 + b.x * t + Vector3(0, 0.6, 0), 3.6, 0.2, 10)
		lm.box("Marble", dir * 4.9 + Vector3(0, 4.425, 0), Vector3(2.6, 0.45, 1.8), b)
		lm.box("Honey", dir * 4.9 + Vector3(0, 4.775, 0), Vector3(2.9, 0.25, 2.1), b)
	# The cistern: a round tank with a worn rim.
	lm.frustum("Honey", Vector3(0, -2.0, 6.4), 2.6, 2.6, 7.0, 16)
	lm.frustum("Marble", Vector3(0, 5.0, 6.4), 2.8, 2.8, 0.3, 16)
	lm.commit(model)

# --- Choragic Monument of Lysicrates -----------------------------------

## Origin at the centre of the square base. The 335 BC prize monument: a
## square limestone podium, a round marble cella ringed by six engaged
## Corinthian columns, a frieze, the roof carved as overlapping leaves
## and the acanthus finial that carried the bronze tripod (9.9 m).
static func lysicrates(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4D8C0", 2.0))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB892", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5A5044", 2.0))
	AtUtil.steps(lm, "Honey", Vector3(0, 0.4, 0), 3.5, 3.5, 2, 0.2, 0.3, 2.0)
	lm.box("Honey", Vector3(0, 2.25, 0), Vector3(3.1, 3.7, 3.1))
	lm.box("Marble", Vector3(0, 4.275, 0), Vector3(3.5, 0.35, 3.5))
	lm.frustum("Marble", Vector3(0, 4.45, 0), 1.25, 1.25, 3.25, 24)
	for k in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		AtUtil.corinthian(lm, "Marble", Vector3(cos(a) * 1.45, 4.45, sin(a) * 1.45), 3.25, 0.2, 10)
	lm.frustum("Marble", Vector3(0, 7.7, 0), 1.65, 1.65, 0.3, 24)
	lm.frustum("Shadow", Vector3(0, 8.0, 0), 1.5, 1.5, 0.35, 24)
	lm.frustum("Marble", Vector3(0, 8.35, 0), 1.8, 1.8, 0.2, 24)
	lm.lathe("Marble", Vector3(0, 8.55, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.55, 0.05),
		Vector2(1.25, 0.35), Vector2(0.8, 0.65), Vector2(0.4, 0.85)]), 24)
	lm.lathe("Honey", Vector3(0, 9.4, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.5, 0.15),
		Vector2(0.28, 0.3), Vector2(0.3, 0.45), Vector2(0.0, 0.5)]), 10)
	lm.commit(model)

# --- Monument of Philopappos ---------------------------------------------

## Origin at the middle of the socle, the concave facade toward -Z
## (yaw_deg onto the Acropolis). What survives of the AD 114-116 tomb of
## Gaius Julius Antiochus Philopappos: the 3 m socle, the curved front of
## Pentelic marble with its carved frieze, four pilasters, three niches
## holding the statues of Antiochus IV, Philopappos and Seleucus I, and
## the cornice.
static func philopappos(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E1D5BC", 2.0))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BE98", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5C5246", 2.0))
	AtUtil.steps(lm, "Honey", Vector3(0, 0.0, 0), 10.4, 9.3, 2, 0.25, 0.5, 3.0)
	lm.box("Honey", Vector3(0, 1.54, 0), Vector3(9.8, 3.08, 9.3))
	lm.box("Marble", Vector3(0, 3.23, -0.2), Vector3(10.2, 0.3, 9.7))
	var arc := PackedVector2Array()
	for i in 11:
		var x := -4.9 + 0.98 * float(i)
		arc.append(Vector2(x, _front_z(x)))
	var poly: PackedVector2Array = arc.duplicate()
	poly.append(Vector2(4.9, 3.0))
	poly.append(Vector2(-4.9, 3.0))
	lm.poly_prism("Marble", poly, 3.38, 9.0)
	for i in 10:
		var p0 := arc[i]
		var p1 := arc[i + 1]
		lm.quad("Honey", Vector3(p0.x, 3.9, p0.y - 0.08), Vector3(p1.x, 3.9, p1.y - 0.08),
			Vector3(p1.x, 4.9, p1.y - 0.08), Vector3(p0.x, 4.9, p0.y - 0.08), Vector3(0, 0, -1))
	for x in [-4.5, -1.5, 1.5, 4.5]:
		var xx: float = x
		lm.box("Honey", Vector3(xx, 6.9, _front_z(xx) - 0.17), Vector3(0.7, 3.85, 0.35))
		lm.box("Honey", Vector3(xx, 8.95, _front_z(xx) - 0.2), Vector3(0.95, 0.35, 0.45))
	for x in [-3.0, 0.0, 3.0]:
		var xx: float = x
		SEuUtil.opening(lm, "Shadow", Vector3(xx, 5.3, _front_z(xx) - 0.06), Vector3(-1, 0, 0),
			Vector3.UP, 1.6, 3.0)
		LandmarkKits.statue_figure(lm, "Marble", Vector3(xx, 5.3, _front_z(xx) - 0.3), 2.2)
	lm.box("Marble", Vector3(0, 9.2, -0.9), Vector3(10.4, 0.4, 7.8))
	lm.commit(model)

## Front surface of the curved facade: the centre sits back, the ends come forward.
static func _front_z(x: float) -> float:
	return -3.6 - 1.0 * (x / 4.9) * (x / 4.9)
