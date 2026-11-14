class_name LandmarkAngCloister
extends RefCounted

## Two Bayon-period temples east of Angkor Thom in true metres: Ta Som, the
## small fig-strangled shrine, and Banteay Kdei, the cloistered "citadel of
## the cells" with its four nested enclosures and the Hall of Dancers.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const A = preload("res://scripts/generation/landmarks/angkor/landmark_ang_util.gd")

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7B7363", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", LandmarkAngParts.ROOF, 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	lm.use("Root", LandmarkMaterials.pbr("rock", "#4D4438", 3.0))
	lm.use("Leaf", LandmarkMaterials.pbr("forest", "#3F5530", 4.0))

## Ta Som (17 m): the single-level Bayon-style shrine of Jayavarman VII
## behind its moat: three laterite enclosures (240 x 200 m, 92 x 76 m and
## the 36 x 24 m inner court) broken by an east and a west gopura each, the
## outer and second gopuras crowned by four-faced towers, the outer east one
## strangled by a sacred fig. In the inner court the cruciform sanctuary with
## a porch on each arm and its four corner pavilions; two small libraries
## beside the east approach and the causeway over the moat. Built facing +X
## (east).
static func ta_som(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	A.ring(lm, "Laterite", "Stone", 120.0, 100.0, 0.0, 3.6, 1.8, 5.5)
	A.ring(lm, "Laterite", "Stone", 46.0, 38.0, 0.0, 3.2, 1.4, 4.5)
	A.ring(lm, "Stone", "Roof", 18.0, 12.0, 0.0, 2.6, 1.0, 2.5)
	for side in [1, 3]:
		var b := A.face(side)
		var top := A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, 120.0), b, 12.0, 8.0, 4.6)
		U.face_tower(lm, "Stone", "Dark", Vector3(0, top, 0) + b * Vector3(0, 0, 120.0), 4.2, 8.0)
		top = A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, 46.0), b, 9.0, 6.0, 3.6)
		U.face_tower(lm, "Stone", "Dark", Vector3(0, top, 0) + b * Vector3(0, 0, 46.0), 3.6, 6.2)
		A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, 18.0), b, 5.0, 4.0, 2.8)
	# Causeway over the moat, east of the outer gopura.
	lm.box("Laterite", Vector3(134.5, 0.35, 0), Vector3(19.4, 0.7, 7.0))
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box("Stone", Vector3(134.5, 0.8, sg * 3.4), Vector3(19.6, 0.2, 0.5), Basis(), 0.0)
	# Cruciform sanctuary: plinth, a porch on each arm, the tower over the
	# crossing and the four corner pavilions.
	lm.box("Stone", Vector3(0, 0.5, 0), Vector3(12.0, 1.0, 11.0))
	U.prasat(lm, "Stone", "Roof", "Dark", Vector3(0, 1.0, 0), 2.4, 10.0, 3, 0.28)
	for side in 4:
		var b := A.face(side)
		lm.box("Stone", b * Vector3(0, 2.5, 4.0), Vector3(2.6, 3.0, 2.6), b)
		lm.box("Dark", b * Vector3(0, 2.3, 5.32), Vector3(1.2, 2.2, 0.1), b, 0.0)
		lm.gable("Roof", b * Vector3(0, 4.0, 4.0), 2.8, 2.8, 1.2, b, 0.2, "Stone")
	for s in [-1.0, 1.0]:
		var sg: float = s
		for t in [-1.0, 1.0]:
			var tg: float = t
			U.prasat(lm, "Stone", "Roof", "Dark", Vector3(sg * 12.5, 0, tg * 7.0), 1.5, 6.5, 2, 0.3)
	# Libraries between the inner and the second enclosure, doors west.
	for s in [-1.0, 1.0]:
		var sg: float = s
		A.hall(lm, "Stone", "Stone", "Roof", "Dark", Vector3(30.0, 0, sg * 9.0),
			Basis(Vector3.UP, -PI * 0.5), 4.0, 6.4, 3.0, 1.6, 2)
	# The fig strangling the east gopura.
	A.fig_tree(lm, "Root", "Leaf", Vector3(123.0, 0, 6.5), 1.6, 17.0)
	lm.commit(model)

## Banteay Kdei (13.8 m): the Bayon-period monastery temple on one level.
## Four nested laterite enclosures: the 320 x 300 m outer wall with a
## four-faced gopura on each side, the 160 x 128 m third enclosure with its
## east and west face-tower gopuras and, inside the east gate, the
## cruciform Hall of Dancers; the 65 x 50 m second enclosure with the east
## gopura and the libraries either side of the approach; and the 36 x 30 m
## inner gallery with four corner towers, the gallery linking the central
## sanctuary to the east and west doors. Strangler figs on the walls. Built
## facing +X (east).
static func banteay_kdei(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	A.ring(lm, "Laterite", "Stone", 160.0, 150.0, 0.0, 3.5, 1.8, 5.5, 5.5)
	A.ring(lm, "Laterite", "Stone", 80.0, 64.0, 0.0, 3.0, 1.5, 4.5, 3.5)
	A.ring(lm, "Laterite", "Stone", 32.5, 25.0, 0.0, 3.0, 1.3, 3.5, 2.5)
	A.ring(lm, "Stone", "Roof", 18.0, 15.0, 0.0, 3.2, 1.2, 2.2)
	# Outer gopuras with face towers on all four sides.
	for side in 4:
		var b := A.face(side)
		var d := 150.0 if side % 2 == 0 else 160.0
		var top := A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, d), b, 12.0, 9.0, 4.4)
		U.face_tower(lm, "Stone", "Dark", Vector3(0, top, 0) + b * Vector3(0, 0, d), 4.6, 8.4)
	# Third enclosure: east and west face-tower gopuras, small north/south gates.
	for side in 4:
		var b := A.face(side)
		var d := 64.0 if side % 2 == 0 else 80.0
		if side % 2 == 1:
			var top := A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, d), b, 9.0, 7.0, 3.8)
			U.face_tower(lm, "Stone", "Dark", Vector3(0, top, 0) + b * Vector3(0, 0, d), 3.8, 6.5)
		else:
			A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, d), b, 6.0, 5.0, 3.2)
	# Hall of Dancers: two crossing colonnaded halls inside the east gate.
	var hall_c := Vector3(60.0, 0, 0)
	A.hall(lm, "Stone", "Stone", "Roof", "Dark", hall_c, A.face(1), 8.0, 30.0, 3.4, 1.6, 4)
	A.hall(lm, "Stone", "Stone", "Roof", "Dark", hall_c, A.face(0), 8.0, 24.0, 3.4, 1.6, 3)
	for s in [-1.0, 1.0]:
		var sg: float = s
		for q in [-1.0, 1.0]:
			var qg: float = q
			U.columns(lm, "Stone", Vector3(60.0 + qg * 5.5, 0.6, sg * 4.9), Vector3(60.0 + qg * 14.0, 0.6, sg * 4.9), 4, 3.2, 0.5)
			U.columns(lm, "Stone", Vector3(60.0 + sg * 4.9, 0.6, qg * 5.5), Vector3(60.0 + sg * 4.9, 0.6, qg * 10.0), 3, 3.2, 0.5)
	# Second enclosure: east gopura with a tower, the lesser west gopura, libraries.
	for side in [1, 3]:
		var b := A.face(side)
		if side == 1:
			var top := A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, 32.5), b, 9.0, 7.0, 3.6)
			U.prasat(lm, "Stone", "Roof", "Dark", Vector3(0, top, 0) + b * Vector3(0, 0, 32.5), 1.6, 5.6, 2, 0.3)
		else:
			A.gopura(lm, "Stone", "Stone", "Roof", "Dark", b * Vector3(0, 0, 32.5), b, 6.0, 5.0, 3.2)
	for s in [-1.0, 1.0]:
		var sg: float = s
		A.hall(lm, "Stone", "Stone", "Roof", "Dark", Vector3(25.0, 0, sg * 19.5),
			Basis(Vector3.UP, -PI * 0.5), 4.2, 6.6, 3.2, 1.7, 2)
	# Inner gallery: gopura-less doors east and west, galleries to the sanctuary,
	# four corner towers and the central sanctuary.
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box("Stone", Vector3(sg * 10.4, 1.4, 0), Vector3(13.6, 2.8, 3.0))
		lm.box("Roof", Vector3(sg * 10.4, 3.0, 0), Vector3(14.4, 0.4, 3.8))
		for t in [-1.0, 1.0]:
			var tg: float = t
			U.prasat(lm, "Stone", "Roof", "Dark", Vector3(sg * 14.5, 0, tg * 11.5), 1.8, 9.0, 2, 0.3)
	lm.box("Stone", Vector3(0, 0.5, 0), Vector3(8.0, 1.0, 8.0))
	U.prasat(lm, "Stone", "Roof", "Dark", Vector3(0, 1.0, 0), 2.6, 10.5, 3, 0.28)
	# Strangler figs on the walls.
	A.fig_tree(lm, "Root", "Leaf", Vector3(31.0, 0, 22.0), 1.5, 12.0)
	A.fig_tree(lm, "Root", "Leaf", Vector3(-82.0, 0, 6.0), 1.7, 13.0)
	lm.commit(model)
