class_name LandmarkAngSmall
extends RefCounted

## Three small Angkor Thom sanctuaries in true metres: Thommanon and Chau Say
## Tevoda, the twin 12th-century Angkor Wat style temples by the Victory Gate
## road, and Preah Palilay with its Buddhist terrace and gopura.

const P = preload("res://scripts/generation/landmarks/angkor/landmark_ang_parts.gd")
const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Thommanon (13 m): the single sandstone sanctuary tower (four storeys on a
## 2.5 m base, c. 1130) with the mandapa and vestibule on its east side, the
## small library to the south-east, the east and west gopuras with three
## passages each, the low laterite remnants of the 60 x 45 m enclosure and the
## causeway running east. Built facing +X (east).
static func thommanon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#867A66")
	var e := P.facing(1)
	P.block(lm, "Stone", "Trim", Vector3(-6.0, 0, 0), 6.2, 5.4, 2.5)
	U.prasat(lm, "Stone", "Roof", "Dark", Vector3(-6.0, 2.5, 0), 2.7, 10.5, 4, 0.28)
	U.hall(lm, "Stone", "Trim", "Roof", "Dark", Vector3(3.9, 0, 0), e, 3.8, 7.4, 0.8, 2.8, 1.8, 2, 0)
	U.hall(lm, "Stone", "Trim", "Roof", "Dark", Vector3(3.0, 0, 12.0), e, 3.0, 5.6, 0.7, 2.4, 1.5, 1, 0)
	_triple_gopura(lm, Vector3(27.5, 0, 0), e, 9.0, 6.5)
	_triple_gopura(lm, Vector3(-27.5, 0, 0), P.facing(3), 6.5, 5.2)
	_enclosure_remnant(lm, 30.0, 22.5, 8.0)
	lm.box("Laterite", Vector3(42.0, 0.25, 0), Vector3(20.0, 0.5, 3.6))
	_rubble(lm, Vector3(-6.0, 0, 0), 9.0, 7)
	lm.commit(model)

## Chau Say Tevoda (12.5 m): Thommanon's twin across the road, a few decades
## younger (mid 12th c.): the sanctuary tower on its platform (the top partly
## fallen), the mandapa, two libraries in the east corners of the 50 x 40 m
## enclosure with its four gopuras, and the long raised causeway east toward
## the river, ending in naga fans. Built facing +X (east).
static func chau_say_tevoda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#8A7D68")
	var e := P.facing(1)
	P.block(lm, "Stone", "Trim", Vector3(-5.0, 0, 0), 5.5, 5.0, 2.2)
	U.prasat(lm, "Stone", "Roof", "Dark", Vector3(-5.0, 2.2, 0), 2.5, 10.3, 3, 0.3)
	U.hall(lm, "Stone", "Trim", "Roof", "Dark", Vector3(3.9, 0, 0), e, 3.6, 6.8, 0.8, 2.6, 1.6, 1, 0)
	for s in [-1.0, 1.0]:
		U.hall(lm, "Stone", "Trim", "Roof", "Dark", Vector3(8.0, 0, s * 12.0), e, 3.0, 5.4, 0.7, 2.4, 1.5, 1, 0)
	_triple_gopura(lm, Vector3(22.0, 0, 0), e, 8.5, 6.0)
	_triple_gopura(lm, Vector3(-22.0, 0, 0), P.facing(3), 6.0, 5.0)
	_triple_gopura(lm, Vector3(0, 0, -17.0), P.facing(2), 6.0, 5.0)
	_triple_gopura(lm, Vector3(0, 0, 17.0), P.facing(0), 6.0, 5.0)
	_enclosure_remnant(lm, 25.0, 20.0, 6.0)
	# Raised causeway with posts and the naga fans at its far end.
	lm.box("Stone", Vector3(44.0, 0.6, 0), Vector3(36.0, 1.2, 4.6))
	for k in 12:
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(27.5 + 3.0 * float(k), 1.7, s * 2.1), Vector3(0.5, 1.0, 0.5), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		U.naga_fan(lm, "Stone", Vector3(62.0, 1.2, s * 2.0), e, 5, 2.0)
	_rubble(lm, Vector3(-5.0, 0, 0), 8.5, 11)
	for k in 6:
		var a := 1.3 * float(k)
		lm.box("Moss", Vector3(-5.0 + cos(a) * 3.5, 2.24, sin(a) * 3.8), Vector3(1.6, 0.06, 1.2),
			Basis(Vector3.UP, a), 0.0)
	lm.commit(model)

## Gopura of three passages (hall w wide, l long, its axis along the basis
## +Z): a plinth, the gabled hall under a pediment and a dark doorway for
## each of the three passages at both ends.
static func _triple_gopura(lm: LandmarkMesh, base: Vector3, basis: Basis, w: float, l: float) -> void:
	var wall_h := minf(w * 0.38, 3.6)
	U.hall(lm, "Stone", "Trim", "Roof", "Dark", base, basis, w, l, 1.0, wall_h, w * 0.3, 2, 0)
	for s in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			lm.box("Dark", base + basis * Vector3(z * w * 0.32, 1.0 + wall_h * 0.35, s * (l * 0.5 + 0.03)),
				Vector3(minf(w * 0.12, 1.2), wall_h * 0.7, 0.1), basis, 0.0)

## Low laterite remnants of an enclosure (half-sizes hx, hz): the wall
## survives as base courses with long gaps, and a `gate`-wide opening in the
## middle of each side.
static func _enclosure_remnant(lm: LandmarkMesh, hx: float, hz: float, gate: float) -> void:
	for s in [-1.0, 1.0]:
		U.wall_run(lm, "Laterite", "Stone", Vector3(-hx, 0, s * hz), Vector3(-hx * 0.45, 0, s * hz), 1.4, 1.3, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(hx * 0.1, 0, s * hz), Vector3(hx * 0.5, 0, s * hz), 1.0, 1.3, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(hx * 0.8, 0, s * hz), Vector3(hx, 0, s * hz), 1.4, 1.3, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(s * hx, 0, -hz), Vector3(s * hx, 0, -gate), 1.4, 1.3, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(s * hx, 0, gate), Vector3(s * hx, 0, hz), 1.4, 1.3, 0.1)

## Fallen blocks strewn round a sanctuary at `c` out to radius r.
static func _rubble(lm: LandmarkMesh, c: Vector3, r: float, n: int) -> void:
	for k in n:
		var a := 2.4 * float(k) + 0.5
		var rr := r * (0.75 + 0.25 * sin(float(k) * 1.9))
		lm.box("Stone", c + Vector3(cos(a) * rr, 0.3, sin(a) * rr), Vector3(1.1, 0.6, 0.8),
			Basis(Vector3.UP, a * 2.0), 0.0)

## Preah Palilay (15 m): the Buddhist sanctuary of laterite and sandstone
## (late 12th-13th c.): a three-level base under the cruciform cella with its
## four porches and the tall chimney-like tower, inside a 50 m square laterite
## wall; the sandstone east gopura with three entrances, the 33 m causeway and
## the cross-shaped terrace with seven-headed naga railings, lions and the
## later shrine of the seated Buddha. Built facing +X (east).
static func preah_palilay(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#7C7563")
	lm.use("Statue", LandmarkMaterials.pbr("stone", "#8D8573", 3.0))
	var e := P.facing(1)
	# Three-level base, cella, porches and the tower above it.
	P.block(lm, "Stone", "Trim", Vector3.ZERO, 7.5, 7.5, 2.0)
	P.block(lm, "Stone", "Trim", Vector3(0, 2.0, 0), 6.0, 6.0, 2.0)
	P.block(lm, "Stone", "Trim", Vector3(0, 4.0, 0), 4.6, 4.6, 2.0)
	lm.box("Stone", Vector3(0, 8.0, 0), Vector3(7.0, 4.0, 7.0))
	for side in 4:
		var b := P.facing(side)
		lm.box("Stone", b * Vector3(0, 7.5, 4.2), Vector3(3.2, 3.0, 1.6), b)
		lm.box("Dark", b * Vector3(0, 7.2, 5.02), Vector3(1.2, 2.2, 0.1), b, 0.0)
		lm.gable("Stone", b * Vector3(0, 9.0, 4.2), 3.6, 1.8, 0.9, b, 0.0, "Stone")
	lm.box("Trim", Vector3(0, 10.2, 0), Vector3(7.6, 0.4, 7.6))
	lm.box("Stone", Vector3(0, 11.4, 0), Vector3(5.4, 2.0, 5.4))
	lm.box("Trim", Vector3(0, 12.5, 0), Vector3(5.8, 0.2, 5.8), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 13.3, 0), Vector3(4.4, 1.6, 4.4))
	U.lotus_bud(lm, "Roof", Vector3(0, 14.1, 0), 1.7, 0.9, 10)
	_rubble(lm, Vector3.ZERO, 10.5, 8)
	# The laterite enclosure, east side split for the gopura.
	for s in [-1.0, 1.0]:
		U.wall_run(lm, "Laterite", "Stone", Vector3(-25.0, 0, s * 25.0), Vector3(25.0, 0, s * 25.0), 3.0, 1.4, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(25.0, 0, s * 25.0), Vector3(25.0, 0, s * 6.0), 3.0, 1.4, 0.1)
	U.wall_run(lm, "Laterite", "Stone", Vector3(-25.0, 0, 25.0), Vector3(-25.0, 0, -25.0), 3.0, 1.4, 0.1)
	_triple_gopura(lm, Vector3(25.0, 0, 0), e, 8.5, 5.5)
	# Causeway, cross-shaped terrace with its stair and seven-headed nagas.
	lm.box("Stone", Vector3(44.5, 0.45, 0), Vector3(33.0, 0.9, 4.0))
	for k in 11:
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(29.0 + 3.0 * float(k), 1.15, s * 1.8), Vector3(0.4, 0.5, 0.4), Basis(), 0.0)
	lm.box("Stone", Vector3(65.25, 0.6, 0), Vector3(8.5, 1.2, 12.0))
	lm.box("Stone", Vector3(67.5, 0.6, 0), Vector3(4.0, 1.2, 30.0))
	lm.box("Trim", Vector3(65.25, 1.25, 0), Vector3(8.9, 0.1, 12.4), Basis(), 0.0)
	lm.box("Trim", Vector3(67.5, 1.25, 0), Vector3(4.4, 0.1, 30.4), Basis(), 0.0)
	P.stair(lm, "Stone", Vector3(69.5, 0, 0), e, 3.0, 1.2, 0.3, 0.5)
	for s in [-1.0, 1.0]:
		U.naga_rail(lm, "Stone", Vector3(69.5, 0, s * 2.4), e, 2.0, 1.2, 0.0, 0.5, 7)
		P.lion(lm, "Stone", Vector3(62.5, 1.2, s * 5.0), e, 1.4)
	# The later shrine: an open pavilion over the seated Buddha on his lotus.
	var sc := Vector3(48.0, 0, -9.0)
	lm.box("Stone", sc + Vector3(0, 0.3, 0), Vector3(4.4, 0.6, 4.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", sc + Vector3(sx * 1.9, 2.3, sz * 1.9), Vector3(0.3, 3.4, 0.3), Basis(), 0.0)
	lm.gable("Roof", sc + Vector3(0, 4.0, 0), 4.4, 4.6, 1.2, e, 0.3, "Stone")
	lm.lathe("Statue", sc + Vector3(0, 0.6, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(1.4, 0.2),
		Vector2(1.0, 0.4), Vector2(0.9, 0.6), Vector2(0.7, 1.1), Vector2(0.6, 1.6), Vector2(0.45, 2.0),
		Vector2(0.38, 2.3), Vector2(0.22, 2.55), Vector2(0.0, 2.7)]), 10)
	lm.commit(model)
