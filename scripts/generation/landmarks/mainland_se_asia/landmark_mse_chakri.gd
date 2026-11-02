class_name LandmarkMseChakri
extends RefCounted

## The throne halls of the Grand Palace in true metres, in the Bangkok
## palette of LandmarkMseBangkok: the Chakri Maha Prasat (1876-1882, a
## three-storey Renaissance body by John Clunis, 87 m long, under Thai
## roofs and three seven-tier prasat spires) and the Dusit Maha Prasat
## (the cruciform audience hall of Rama I under crossed stepped roofs
## and a tiered spire).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

## Chakri Maha Prasat: a long three-storey body in cream plaster with a
## projecting central pavilion (four bays) and end pavilions (three
## bays), square ground-floor windows and two rows of round-arched
## windows between pilasters, string courses and a cornice, the grand
## stair, then the Thai roofs: a gabled roof along the body, a roof
## across each pavilion and three prasat spires, the central one to
## `top_m`. `b` turns the front (+Z in its own frame) to face north.
static func chakri(lm: LandmarkMesh, o: Vector3, b: Basis, top_m: float) -> void:
	lm.box("Stone", o + b * Vector3(0, 1.1, 0), Vector3(88, 2.2, 29), b)
	# [centre x, half width, front z]: central pavilion, wings, end pavilions.
	var segs := [[0.0, 11.0, 18.0, 4], [-16.5, 5.5, 11.0, 2], [16.5, 5.5, 11.0, 2], [-31.0, 8.0, 14.0, 3],
		[31.0, 8.0, 14.0, 3]]
	var fn: Vector3 = b * Vector3(0, 0, 1)
	for sg in segs:
		var cx: float = sg[0]
		var hw: float = sg[1]
		var fz: float = sg[2]
		var bays: int = sg[3]
		lm.box("Wall", o + b * Vector3(cx, 9.95, (fz - 11.0) * 0.5), Vector3(hw * 2.0, 15.5, fz + 11.0), b)
		for y in [2.6, 7.6, 12.7]:
			lm.box("Wall", o + b * Vector3(cx, y, fz), Vector3(hw * 2.0 + 0.4, 0.45, 0.5), b)
		lm.box("Wall", o + b * Vector3(cx, 17.3, (fz - 11.0) * 0.5), Vector3(hw * 2.0 + 1.0, 0.8, fz + 12.0), b)
		lm.box("Wall", o + b * Vector3(cx, 17.9, (fz - 11.0) * 0.5), Vector3(hw * 2.0 + 1.8, 0.4, fz + 12.8), b)
		var pitch := hw * 2.0 / float(bays)
		for i in bays + 1:
			lm.box("Wall", o + b * Vector3(cx - hw + pitch * float(i), 10.2, fz + 0.15), Vector3(0.9, 15.0, 0.3), b)
		for i in bays:
			var x := cx - hw + pitch * (float(i) + 0.5)
			LandmarkDetail.window(lm, "Wall", "Glass", o + b * Vector3(x, 5.0, fz + 0.02), fn, 1.6, 2.4, false, 0.25)
			for row in 2:
				LandmarkDetail.window(lm, "Wall", "Glass", o + b * Vector3(x, 10.0 + 5.1 * float(row), fz + 0.02), fn,
					1.6, 3.2, true, 0.25)
	# Back and end walls: arched windows in the two upper rows, square below.
	var bn: Vector3 = b * Vector3(0, 0, -1)
	for i in 14:
		var x := -36.4 + 5.6 * float(i)
		LandmarkDetail.window(lm, "Wall", "Glass", o + b * Vector3(x, 5.0, -11.02), bn, 1.6, 2.4, false, 0.25)
		for row in 2:
			LandmarkDetail.window(lm, "Wall", "Glass", o + b * Vector3(x, 10.0 + 5.1 * float(row), -11.02), bn,
				1.6, 3.2, true, 0.25)
	for sx in [-1.0, 1.0]:
		var sn: Vector3 = b * Vector3(sx, 0, 0)
		for i in 4:
			var z := -8.0 + 5.4 * float(i)
			for row in 2:
				LandmarkDetail.window(lm, "Wall", "Glass", o + b * Vector3(sx * 39.02, 10.0 + 5.1 * float(row), z), sn,
					1.6, 3.2, true, 0.25)
	# Main door and the grand stair with its balustrades.
	lm.box("Dark", o + b * Vector3(0, 4.6, 18.06), Vector3(3.6, 4.8, 0.1), b, 0.0)
	LandmarkDetail.arch(lm, "Wall", o + b * Vector3(0, 7.0, 18.0), fn, 3.6)
	U.stairs(lm, "Stone", o + b * Vector3(0, 0, 18), b, 14.0, 5, 0.6, 0.44)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", o + b * Vector3(sx * 7.3, 1.6, 19.5), Vector3(0.6, 1.4, 3.2), b)
	# Thai roofs: along the body, across the three pavilions, and the spires.
	var rb := b * Basis(Vector3.UP, PI * 0.5)
	K.roof_piece(lm, "Orange", "Green", "Gold", "Wall", o + b * Vector3(0, 18.1, 0), rb, 22.0, 78.0, 4.2, 1.0,
		1.0, 2.2)
	K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", o + b * Vector3(0, 18.1, 3.5), b, 18.0, 29.0, 4.8, 1.2,
		1, 0, 2.2)
	for sx in [-1.0, 1.0]:
		K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", o + b * Vector3(sx * 31, 18.1, 1.5), b, 14.0, 25.0, 4.4,
			1.1, 1, 0, 2.0)
		var pc := o + b * Vector3(sx * 31, 22.6, 1.5)
		lm.box("Wall", pc + Vector3(0, 0.8, 0), Vector3(8.0, 1.6, 8.0), b)
		lm.spire("Green", pc + Vector3(0, 1.6, 0), 4.8, 2.2, 3.6)
		U.prasat_spire(lm, "Wall", "Orange", "Gold", pc + Vector3(0, 3.8, 0), 3.6, 32.0 - 26.4, 7)
	var cc := o + b * Vector3(0, 23.0, 3.5)
	lm.box("Wall", cc + Vector3(0, 0.9, 0), Vector3(10.0, 1.8, 10.0), b)
	lm.spire("Orange", cc + Vector3(0, 1.8, 0), 6.4, 2.6, 4.8)
	lm.spire("Green", cc + Vector3(0, 4.4, 0), 5.0, 2.0, 3.6)
	U.prasat_spire(lm, "Wall", "Orange", "Gold", cc + Vector3(0, 6.4, 0), 4.2, top_m - cc.y - 6.4, 7)

## Dusit Maha Prasat: the cruciform audience hall on its moulded plinth,
## four arms under stepped Thai roofs with gilded gable trim, pointed
## windows down each arm, the throne porch on the north arm and the
## seven-tier busabok spire over the crossing (27 m).
static func dusit(lm: LandmarkMesh, o: Vector3) -> void:
	K.plinth(lm, "Stone", o, Basis(), 32.0, 32.0, 1.4)
	var y0 := 1.4
	for b in [Basis(), Basis(Vector3.UP, PI * 0.5)]:
		lm.box("Wall", o + Vector3(0, y0 + 4.5, 0), Vector3(9.0, 9.0, 26.0), b)
		K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", o + Vector3(0, y0 + 9.0, 0), b, 10.0, 28.0, 4.0, 1.2,
			2, 1, 1.8)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		K.thai_window(lm, "Wall", "Dark", "Gold", o + b * Vector3(0, y0, 13.02), b, 2.6, 5.2)
		for sx in [-1.0, 1.0]:
			for zz in [7.0, 10.6]:
				K.thai_window(lm, "Wall", "Dark", "Gold", o + b * Vector3(sx * 4.52, y0 + 2.2, zz),
					b * Basis(Vector3.UP, PI * 0.5 * sx), 1.3, 3.0)
	var nb := Basis(Vector3.UP, PI)
	for sx in [-1.0, 1.0]:
		for zz in [14.2, 17.0]:
			K.thai_column(lm, "Gold", "Gold", o + nb * Vector3(sx * 3.4, y0, zz), 0.6, 7.0)
	K.roof_piece(lm, "Orange", "Green", "Gold", "Wall", o + nb * Vector3(0, y0 + 7.4, 15.6), nb, 8.0, 3.6, 2.6,
		0.8, 0.8, 1.4, 1)
	lm.box("Wall", o + Vector3(0, y0 + 14.8, 0), Vector3(6.0, 2.0, 6.0))
	U.prasat_spire(lm, "Wall", "Orange", "Gold", o + Vector3(0, y0 + 15.8, 0), 4.0, 27.0 - y0 - 15.8, 7)
