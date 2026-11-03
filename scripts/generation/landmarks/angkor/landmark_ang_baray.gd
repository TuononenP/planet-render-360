class_name LandmarkAngBaray
extends RefCounted

## The 10th-century brick temples of the Eastern Baray in true metres: Pre
## Rup, the laterite temple-mountain, and East Mebon on its island in the
## dry reservoir.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const A = preload("res://scripts/generation/landmarks/angkor/landmark_ang_util.gd")

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A5A40", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#8B5B42", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7D7565", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#665B4D", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#24211D", 2.0))

## Pre Rup (26 m): Rajendravarman's state temple of 961, a laterite pyramid
## 50 m square rising in three steep tiers (4 m each) to a 35 m summit
## platform on a raised inner court, with twelve small brick shrines on the
## lowest tier, a sandstone stair and guardian lions on every face, and the
## quincunx of five brick prasats on top (13 m centre, 11 m corners, each
## with an east vestibule). Two laterite walls (127 x 117 m and 87 x 77 m)
## with cross-shaped brick-and-sandstone gopuras on all four sides, the long
## laterite halls lining the outer court, the rows of small brick towers
## inside the east gate and the Nandi cistern. Built facing +X (east).
static func pre_rup(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	# Outer wall with four gopuras, the inner wall, the raised inner court.
	A.ring(lm, "Laterite", "Stone", 63.5, 58.5, 0.0, 2.8, 1.6, 5.0, 5.0)
	A.ring(lm, "Laterite", "Stone", 43.5, 38.5, 0.0, 3.0, 1.5, 4.0, 4.0)
	lm.box("Laterite", Vector3(0, 0.45, 0), Vector3(85.4, 0.9, 75.4))
	for side in 4:
		var b := A.face(side)
		var outer := 58.5 if side % 2 == 0 else 63.5
		var inner := 38.5 if side % 2 == 0 else 43.5
		var top := A.gopura(lm, "Brick", "Stone", "Roof", "Dark", b * Vector3(0, 0, outer), b, 10.0, 8.0, 3.8)
		U.small_tower(lm, "Brick", Vector3(0, top, 0) + b * Vector3(0, 0, outer), 1.7, 5.2)
		top = A.gopura(lm, "Brick", "Stone", "Roof", "Dark", b * Vector3(0, 0, inner), b, 8.0, 6.0, 3.2)
		U.small_tower(lm, "Brick", Vector3(0, top, 0) + b * Vector3(0, 0, inner), 1.4, 4.4)
	# Long halls along the outer wall, either side of each gate.
	for side in 4:
		var b := A.face(side)
		var off := 53.0 if side % 2 == 0 else 58.2
		var span := 44.0 if side % 2 == 0 else 38.0
		for s in [-1.0, 1.0]:
			var sg: float = s
			A.hall(lm, "Laterite", "Stone", "Roof", "Dark", b * Vector3(sg * (span * 0.5 + 9.0), 0, off),
				b * Basis(Vector3.UP, PI * 0.5), 4.4, span, 2.6, 1.5, 5)
	# Small brick towers inside the east gate (one of the six never built)
	# and the Nandi cistern on the axis.
	for k in 3:
		for s in [-1.0, 1.0]:
			var sg: float = s
			if k == 2 and sg < 0.0:
				continue
			U.small_tower(lm, "Brick", Vector3(52.0, 0, sg * (9.0 + 7.0 * float(k))), 1.1, 5.0)
	lm.box("Stone", Vector3(51.0, 0.5, 0), Vector3(3.0, 1.0, 2.0))
	lm.box("Stone", Vector3(51.0, 1.05, 0), Vector3(3.4, 0.2, 2.4), Basis(), 0.0)
	# Causeway east of the outer gopura.
	lm.box("Laterite", Vector3(78.0, 0.15, 0), Vector3(22.0, 0.3, 6.0))
	# Two libraries on the inner court either side of the walkway, doors west.
	for s in [-1.0, 1.0]:
		var sg: float = s
		A.hall(lm, "Brick", "Stone", "Roof", "Dark", Vector3(34.0, 0.9, sg * 10.0),
			Basis(Vector3.UP, -PI * 0.5), 4.0, 6.6, 3.0, 1.8, 2)
	# The pyramid: three laterite tiers, coping, stair and lions on each face.
	var y0 := 0.9
	var widths := [50.0, 43.0, 35.0]
	for q in 3:
		var w: float = widths[q]
		var yq := y0 + 4.0 * float(q)
		lm.box("Laterite", Vector3(0, yq + 2.0, 0), Vector3(w, 4.0, w))
		lm.box("Stone", Vector3(0, yq + 3.9, 0), Vector3(w + 0.5, 0.2, w + 0.5), Basis(), 0.0)
		lm.box("Stone", Vector3(0, yq + 0.15, 0), Vector3(w + 0.6, 0.3, w + 0.6), Basis(), 0.0)
		var up := 17.5 if q == 2 else 21.5 if q == 1 else 25.0
		for side in 4:
			var b := A.face(side)
			var tread := 0.5 if q != 1 else 0.4375
			U.stair(lm, "Stone", Vector3(0, yq, 0) + b * Vector3(0, 0, up), b, 7.0 - float(q), 8, tread, 0.5)
			if q != 1:
				for s in [-1.0, 1.0]:
					var sg: float = s
					A.lion(lm, "Stone", Vector3(0, yq, 0) + b * Vector3(sg * ((7.0 - float(q)) * 0.5 + 0.9), 0, up + 1.0), b, 0.9)
	# Twelve small brick shrines on the lowest tier: four corners and two a side.
	var ty := y0 + 4.0
	for s in [-1.0, 1.0]:
		var sg: float = s
		for t in [-1.0, 1.0]:
			var tg: float = t
			U.small_tower(lm, "Brick", Vector3(sg * 23.2, ty, tg * 23.2), 1.0, 3.8)
			U.small_tower(lm, "Brick", Vector3(sg * 9.0, ty, tg * 23.2), 1.0, 3.8)
			U.small_tower(lm, "Brick", Vector3(sg * 23.2, ty, tg * 9.0), 1.0, 3.8)
	# Summit: the five brick prasats in a quincunx, vestibules to the east.
	var sy := y0 + 12.0
	_summit_tower(lm, Vector3(0, sy, 0), 3.0, 13.0)
	for s in [-1.0, 1.0]:
		var sg: float = s
		for t in [-1.0, 1.0]:
			var tg: float = t
			_summit_tower(lm, Vector3(sg * 10.5, sy, tg * 10.5), 2.4, 11.0, 2)
	lm.commit(model)

## Brick prasat of half-width hw and height h with the sandstone vestibule
## that carries its east door.
static func _summit_tower(lm: LandmarkMesh, p: Vector3, hw: float, h: float, tiers: int = 3) -> void:
	U.prasat(lm, "Brick", "Roof", "Dark", p, hw, h, tiers, 0.28)
	lm.box("Stone", p + Vector3(hw * 1.225 + 0.9, 1.4, 0), Vector3(1.8, 2.8, hw * 1.1))
	lm.box("Dark", p + Vector3(hw * 1.225 + 1.82, 1.2, 0), Vector3(0.1, 2.0, hw * 0.55), Basis(), 0.0)
	lm.gable("Roof", p + Vector3(hw * 1.225 + 0.9, 2.8, 0), hw * 1.1, 1.8, 0.8, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")

## East Mebon (18 m): the island temple of 953 in the middle of the East
## Baray, on a 126 x 120 m laterite island with a boat landing stair on each
## side. Two enclosures (the 124 x 118 m outer wall lined with laterite long
## halls and the inner wall) with brick-and-sandstone gopuras on every side;
## three laterite tiers (2.2 m each) with a stair on each face and a
## sandstone elephant at each corner of the lower two tiers (eight in all);
## on top a central brick prasat with four smaller ones at the platform
## corners. Built facing +X (east).
static func east_mebon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	var y0 := 1.2
	# Island and the landing stages (the water itself is terrain).
	lm.box("Laterite", Vector3(0, y0 * 0.5, 0), Vector3(126.0, y0, 120.0))
	lm.box("Stone", Vector3(0, y0 - 0.05, 0), Vector3(126.8, 0.2, 120.8), Basis(), 0.0)
	for side in 4:
		var b := A.face(side)
		var half := 60.0 if side % 2 == 0 else 63.0
		U.stair(lm, "Stone", b * Vector3(0, 0, half), b, 8.0, 6, 0.5, 0.2)
		lm.box("Stone", b * Vector3(5.5, 0.5, half + 1.5), Vector3(0.6, 1.0, 3.2), b)
		lm.box("Stone", b * Vector3(-5.5, 0.5, half + 1.5), Vector3(0.6, 1.0, 3.2), b)
	# Outer and inner enclosure walls, gopuras on all four sides.
	A.ring(lm, "Laterite", "Stone", 62.0, 59.0, y0, 2.6, 1.6, 5.0, 5.0)
	A.ring(lm, "Laterite", "Stone", 41.0, 38.0, y0, 2.2, 1.4, 3.5, 3.5)
	for side in 4:
		var b := A.face(side)
		var outer := 59.0 if side % 2 == 0 else 62.0
		var inner := 38.0 if side % 2 == 0 else 41.0
		var top := A.gopura(lm, "Brick", "Stone", "Roof", "Dark", Vector3(0, y0, 0) + b * Vector3(0, 0, outer),
			b, 10.0, 7.0, 3.6)
		U.small_tower(lm, "Brick", Vector3(0, top, 0) + b * Vector3(0, 0, outer), 1.6, 5.0)
		top = A.gopura(lm, "Brick", "Stone", "Roof", "Dark", Vector3(0, y0, 0) + b * Vector3(0, 0, inner),
			b, 7.0, 5.0, 3.0)
		U.small_tower(lm, "Brick", Vector3(0, top, 0) + b * Vector3(0, 0, inner), 1.2, 4.0)
	# Long laterite halls inside the outer wall, either side of each gate.
	for side in 4:
		var b := A.face(side)
		var off := 55.0 if side % 2 == 0 else 58.2
		var span := 40.0 if side % 2 == 0 else 36.0
		for s in [-1.0, 1.0]:
			var sg: float = s
			A.hall(lm, "Laterite", "Stone", "Roof", "Dark", Vector3(0, y0, 0) + b * Vector3(sg * (span * 0.5 + 8.0), 0, off),
				b * Basis(Vector3.UP, PI * 0.5), 4.4, span, 2.6, 1.5, 5)
	# Three tiers with stairs and elephants.
	var hx := [33.0, 25.0, 17.0]
	var hz := [30.0, 22.0, 17.0]
	for q in 3:
		var yq := y0 + 2.2 * float(q)
		var qx: float = hx[q]
		var qz: float = hz[q]
		lm.box("Laterite", Vector3(0, yq + 1.1, 0), Vector3(qx * 2.0, 2.2, qz * 2.0))
		lm.box("Stone", Vector3(0, yq + 2.1, 0), Vector3(qx * 2.0 + 0.5, 0.2, qz * 2.0 + 0.5), Basis(), 0.0)
		lm.box("Stone", Vector3(0, yq + 0.15, 0), Vector3(qx * 2.0 + 0.6, 0.3, qz * 2.0 + 0.6), Basis(), 0.0)
		for side in 4:
			var b := A.face(side)
			var up := qz if side % 2 == 0 else qx
			U.stair(lm, "Stone", Vector3(0, yq, 0) + b * Vector3(0, 0, up), b, 6.0, 5, 0.6, 0.44)
		if q < 2:
			for s in [-1.0, 1.0]:
				var sg: float = s
				for t in [-1.0, 1.0]:
					var tg: float = t
					A.elephant(lm, "Stone", Vector3(sg * (qx - 2.4), yq + 2.2, tg * (qz - 2.4)),
						Basis(Vector3.UP, atan2(sg, tg)), 1.05)
	# Summit: central prasat and four corner prasats.
	var sy := y0 + 6.6
	_summit_tower(lm, Vector3(0, sy, 0), 2.7, 10.5)
	for s in [-1.0, 1.0]:
		var sg: float = s
		for t in [-1.0, 1.0]:
			var tg: float = t
			_summit_tower(lm, Vector3(sg * 11.5, sy, tg * 11.5), 2.0, 8.6, 2)
	lm.commit(model)
