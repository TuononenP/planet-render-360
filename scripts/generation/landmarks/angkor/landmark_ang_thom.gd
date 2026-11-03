class_name LandmarkAngThom
extends RefCounted

## The two temple mountains of the Royal Palace of Angkor Thom in true
## metres: Baphuon (the "golden mountain" with its long pillared causeway and
## the reclining Buddha on its back) and Phimeanakas (the laterite pyramid
## with lions and elephants at the corners).

const P = preload("res://scripts/generation/landmarks/angkor/landmark_ang_parts.gd")
const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Baphuon pyramid levels: half-size east-west, half-size north-south, foot
## and top height. Gallery height and rise of each gopura beside them.
const BAPHUON_LEVELS := [[60.0, 50.0, 0.0, 6.0], [49.0, 39.0, 6.0, 14.0],
	[37.0, 28.0, 14.0, 22.0], [25.0, 19.0, 22.0, 28.0]]
const BAPHUON_GOPURA_H := [9.0, 8.0, 7.0, 5.0]
const BAPHUON_GOPURA_HW := [4.0, 3.6, 3.2, 2.6]

## Baphuon (34 m): the three-tiered temple mountain of Udayadityavarman II
## (c. 1060), 120 x 100 m at the foot: four stepped levels of sandstone over a
## laterite base, each topped by a roofed gallery with corner pavilions and
## cardinal gopuras, steep stairs up all four faces, the summit platform with
## the stump of the vanished bronze tower, the 16th-century reclining Buddha
## built into the west wall, the 200 m causeway on three rows of pillars
## leading east to the cruciform terrace and gopura of its enclosure.
## Built facing +X (east).
static func baphuon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#7B7363")
	for i in BAPHUON_LEVELS.size():
		var lv: Array = BAPHUON_LEVELS[i]
		var hx: float = lv[0]
		var hz: float = lv[1]
		var y0: float = lv[2]
		var y1: float = lv[3]
		P.block(lm, "Laterite" if i == 0 else "Stone", "Trim", Vector3(0, y0, 0), hx, hz, y1 - y0)
		# Roofed gallery on the edge of the level, pavilions in its corners.
		P.ring(lm, "Stone", "Roof", "Dark", y1, hx - 1.2, hz - 1.2, 3.0, 3.2, 11.0)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				U.small_tower(lm, "Stone", Vector3(sx * (hx - 3.2), y1, sz * (hz - 3.2)), 1.5, 6.0)
		# Stairs up all four faces to this level, a gopura on the gallery axis.
		for side in 4:
			var b := P.facing(side)
			var east_west := side == 1 or side == 3
			var edge: float = hx if east_west else hz
			var width: float = 9.0 - float(i) if side == 1 else 6.0
			if not (i == 1 and side == 3):
				P.stair(lm, "Stone", b * Vector3(0, y0, edge + 0.3), b, width, y1 - y0, 0.4, 0.36)
			P.gopura(lm, "Stone", "Roof", "Dark", b * Vector3(0, y1, edge - 2.7), b,
				BAPHUON_GOPURA_HW[i], BAPHUON_GOPURA_H[i], 5.0, side == 1)
	_baphuon_summit(lm)
	_reclining_buddha(lm)
	_baphuon_approach(lm)
	lm.commit(model)

## The summit: a platform carrying the cruciform stump of the sanctuary
## (the bronze tower of Zhou Daguan is gone), doorways on four sides.
static func _baphuon_summit(lm: LandmarkMesh) -> void:
	P.block(lm, "Stone", "Trim", Vector3(0, 28.0, 0), 15.0, 11.0, 2.0)
	lm.box("Stone", Vector3(0, 31.6, 0), Vector3(9.0, 3.2, 9.0))
	for side in 4:
		var b := P.facing(side)
		lm.box("Stone", b * Vector3(0, 31.2, 5.6), Vector3(4.6, 2.8, 2.4), b)
		lm.box("Dark", b * Vector3(0, 31.0, 6.82), Vector3(1.6, 2.2, 0.1), b, 0.0)
		lm.box("Trim", b * Vector3(0, 32.7, 5.6), Vector3(5.0, 0.4, 2.8), b, 0.0)
	lm.box("Trim", Vector3(0, 33.4, 0), Vector3(9.6, 0.5, 9.6))
	lm.box("Stone", Vector3(0, 33.825, 0), Vector3(6.6, 0.35, 6.6))

## The reclining Buddha (70 m long, 9 m high) made of the west wall of the
## second level in the 15th century: head to the north on a pillow, the
## torso, drawn-up legs and feet to the south, resting on a long bench.
static func _reclining_buddha(lm: LandmarkMesh) -> void:
	var x := -50.8
	lm.box("Stone", Vector3(x, 6.45, 0), Vector3(3.6, 0.9, 72.0))
	lm.box("Stone", Vector3(x, 8.7, -7.0), Vector3(3.0, 3.6, 38.0))
	for k in 3:
		lm.box("Trim", Vector3(x - 1.55, 8.7 + float(k) * 0.9 - 0.9, -7.0), Vector3(0.12, 0.18, 38.0), Basis(), 0.0)
	lm.box("Stone", Vector3(x, 8.4, 23.0), Vector3(2.8, 2.6, 22.0))
	lm.box("Stone", Vector3(x, 8.0, 35.0), Vector3(2.4, 2.2, 4.0))
	lm.box("Stone", Vector3(x, 7.6, -31.5), Vector3(3.4, 1.1, 6.0))
	lm.box("Stone", Vector3(x, 10.1, -31.5), Vector3(3.4, 4.2, 5.0))
	lm.box("Dark", Vector3(x - 1.72, 10.4, -31.5), Vector3(0.06, 0.3, 3.2), Basis(), 0.0)
	lm.spire("Stone", Vector3(x, 12.2, -31.5), 1.2, 1.4, 0.15)
	lm.beam("Stone", Vector3(x, 9.8, -27.0), Vector3(x, 9.4, -33.5), 1.0, 1.0)

## The 200 m raised causeway on three rows of sandstone pillars, the cruciform
## terrace at its end, the east gopura and the laterite wall round the
## 375 x 125 m enclosure.
static func _baphuon_approach(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(161.0, 1.7, 0), Vector3(202.0, 0.4, 7.6))
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(161.0, 2.15, s * 3.55), Vector3(202.0, 0.5, 0.5), Basis(), 0.0)
	for i in 57:
		var x := 62.0 + 3.5 * float(i)
		for z in [-3.0, 0.0, 3.0]:
			lm.box("Stone", Vector3(x, 0.75, z), Vector3(0.6, 1.5, 0.6), Basis(), 0.0)
	# Cruciform terrace and the steps up to the gopura.
	lm.box("Stone", Vector3(271.0, 0.8, 0), Vector3(22.0, 1.6, 7.6))
	lm.box("Stone", Vector3(271.0, 0.8, 0), Vector3(8.0, 1.6, 22.0))
	lm.box("Trim", Vector3(271.0, 1.65, 0), Vector3(22.4, 0.2, 8.0), Basis(), 0.0)
	lm.box("Trim", Vector3(271.0, 1.65, 0), Vector3(8.4, 0.2, 22.4), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			P.lion(lm, "Stone", Vector3(271.0 + sx * 3.0, 1.6, sz * 9.5), P.facing(0 if sz > 0.0 else 2), 1.6)
	P.stair(lm, "Stone", Vector3(282.0, 0, 0), P.facing(1), 5.0, 1.6, 0.4, 0.6)
	P.gopura(lm, "Stone", "Roof", "Dark", Vector3(294.0, 0, 0), P.facing(1), 4.0, 12.0, 7.0)
	for s in [-1.0, 1.0]:
		U.wall_run(lm, "Laterite", "Stone", Vector3(-75.0, 0, s * 62.5), Vector3(300.0, 0, s * 62.5), 3.5, 1.5, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(-75.0, 0, s * 62.5), Vector3(-75.0, 0, 0), 3.5, 1.5, 0.1)
		U.wall_run(lm, "Laterite", "Stone", Vector3(300.0, 0, s * 62.5), Vector3(300.0, 0, s * 6.0), 3.5, 1.5, 0.1)

## Phimeanakas (21 m): the three-tiered laterite pyramid inside the palace
## enclosure (c. 1000): 35 x 28 m at the foot and 12 m high with very steep
## stairs on all four faces, lions and elephants on the tier corners, the
## roofed gallery round the summit platform with a small tower on each axis,
## and the ruined cruciform sandstone sanctuary where the "golden tower" of
## Zhou Daguan stood. Built facing +X (east).
static func phimeanakas(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#7F7666")
	var tiers := [[17.5, 14.0, 0.0, 4.6], [15.0, 11.5, 4.6, 9.0], [12.5, 9.5, 9.0, 12.2]]
	for i in tiers.size():
		var tv: Array = tiers[i]
		var hx: float = tv[0]
		var hz: float = tv[1]
		var y0: float = tv[2]
		var y1: float = tv[3]
		P.block(lm, "Laterite", "Trim", Vector3(0, y0, 0), hx, hz, y1 - y0)
		for side in 4:
			var b := P.facing(side)
			var edge: float = hx if side % 2 == 1 else hz
			P.stair(lm, "Laterite", b * Vector3(0, y0, edge + 0.3), b, 3.2, y1 - y0, 0.46, 0.24)
		# Elephants on the corners of the first and third tier, lions on the second.
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var cb := Basis(Vector3.UP, atan2(sx, sz))
				var cp := Vector3(sx * (hx - 1.1), y1, sz * (hz - 1.1))
				if i == 1:
					P.lion(lm, "Stone", cp, cb, 2.0)
				else:
					P.elephant(lm, "Stone", cp, cb, 2.2)
	# Moss on the weathered laterite and fallen blocks on the top terrace.
	for k in 10:
		var a := 1.7 * float(k)
		lm.box("Moss", Vector3(cos(a) * 9.0, 12.24, sin(a) * 6.0), Vector3(2.2, 0.08, 1.6),
			Basis(Vector3.UP, a), 0.0)
		lm.box("Stone", Vector3(cos(a * 2.3) * 8.0, 12.55, sin(a * 1.7) * 5.5), Vector3(1.0, 0.7, 0.7),
			Basis(Vector3.UP, a * 3.0))
	# Gallery round the summit with its axial towers.
	P.ring(lm, "Stone", "Roof", "Dark", 12.2, 11.6, 8.6, 2.2, 2.6, 5.0)
	for side in 4:
		var b := P.facing(side)
		var edge: float = 11.6 if side % 2 == 1 else 8.6
		U.small_tower(lm, "Stone", b * Vector3(0, 12.2, edge - 1.1), 1.3, 5.0)
	# The sanctuary: platform, cruciform cella, doorways, corbelled top.
	P.block(lm, "Stone", "Trim", Vector3(0, 12.2, 0), 5.4, 5.4, 1.3)
	lm.box("Stone", Vector3(0, 16.25, 0), Vector3(5.6, 5.5, 5.6))
	for side in 4:
		var b := P.facing(side)
		lm.box("Stone", b * Vector3(0, 15.7, 3.6), Vector3(2.8, 4.4, 2.0), b)
		lm.box("Dark", b * Vector3(0, 15.2, 4.62), Vector3(1.1, 2.6, 0.1), b, 0.0)
		lm.box("Trim", b * Vector3(0, 18.0, 3.6), Vector3(3.2, 0.3, 2.4), b, 0.0)
	for q in 3:
		var w := 5.2 - 1.5 * float(q)
		lm.box("Stone", Vector3(0, 19.0 + 0.67 * (float(q) + 0.5), 0), Vector3(w, 0.67, w))
	lm.box("Moss", Vector3(1.2, 21.02, -0.8), Vector3(1.4, 0.06, 1.0), Basis(), 0.0)
	lm.commit(model)
