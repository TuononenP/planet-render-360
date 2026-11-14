class_name LandmarkTsCloister
extends RefCounted

## The roofed cloister (hoerang) round Geunjeongjeon's courtyard, in the
## frame of LandmarkTsGyeongbokgung.geunjeongjeon: four double corridors
## following OSM way 279961015 (outer ring about 117 x 135 m), each a
## stone stylobate, three rows of red columns, a plastered spine wall,
## painted beams and a tiled gabled roof; Geunjeongmun in the south range,
## Sajeongmun in the north, Wolhwamun and Ilhwamun in the west and east.

const EAVE := 4.2
const BAY := 3.6

static func build(lm: LandmarkMesh) -> void:
	# [x0, z0, x1, z1, ridge along x, gaps as [from, to] along the ridge]
	var wings := [
		[-57.8, -65.0, 58.9, -55.5, true, [[-3.9, 7.2]]],
		[-57.9, 61.9, 60.1, 70.3, true, [[-9.2, 11.6]]],
		[-57.7, -60.2, -46.5, 66.1, false, [[11.1, 21.5]]],
		[48.6, -60.2, 59.6, 66.1, false, [[15.6, 24.3]]],
	]
	for w in wings:
		var row: Array = w
		_wing(lm, Rect2(float(row[0]), float(row[1]), float(row[2]) - float(row[0]), float(row[3]) - float(row[1])),
			bool(row[4]), row[5])
	_gate(lm, Vector3(1.3, 0, 67.0), true, Basis())
	_gate(lm, Vector3(1.6, 0, -60.2), false, Basis())
	_gate(lm, Vector3(-56.5, 0, 16.3), false, Basis(Vector3.UP, PI * 0.5))
	_gate(lm, Vector3(57.8, 0, 20.0), false, Basis(Vector3.UP, PI * 0.5))

## One corridor range over `r`, split at each [from, to] gap along its
## ridge so a gate can stand there.
static func _wing(lm: LandmarkMesh, r: Rect2, along_x: bool, gaps: Array) -> void:
	var a := r.position.x if along_x else r.position.y
	var b := r.end.x if along_x else r.end.y
	var cuts: Array = [a]
	for g in gaps:
		cuts.append(float((g as Array)[0]))
		cuts.append(float((g as Array)[1]))
	cuts.append(b)
	for i in range(0, cuts.size(), 2):
		var s0: float = cuts[i]
		var s1: float = cuts[i + 1]
		if s1 - s0 < 1.0:
			continue
		var piece := Rect2(s0, r.position.y, s1 - s0, r.size.y) if along_x \
			else Rect2(r.position.x, s0, r.size.x, s1 - s0)
		_range(lm, piece, along_x)

## A straight run of double corridor over rectangle `r`.
static func _range(lm: LandmarkMesh, r: Rect2, along_x: bool) -> void:
	var c := r.get_center()
	var length := r.size.x if along_x else r.size.y
	var width := r.size.y if along_x else r.size.x
	var d := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var across := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	var basis := Basis(d, Vector3.UP, d.cross(Vector3.UP).normalized())
	var centre := Vector3(c.x, 0, c.y)
	lm.box("Granite", centre + Vector3(0, 0.22, 0), Vector3(length, 0.45, width), basis)
	# Spine wall with its timber head beam.
	lm.box("Plaster", centre + Vector3(0, 0.45 + (EAVE - 0.9) * 0.5, 0), Vector3(length, EAVE - 0.9, 0.3), basis, 0.0)
	var n := maxi(int(round(length / BAY)), 1)
	for rowk in [-1.0, 0.0, 1.0]:
		var off: Vector3 = across * rowk * (width * 0.5 - 0.7)
		for k in n + 1:
			var p := centre + off + d * (-length * 0.5 + length * float(k) / float(n)) + Vector3(0, 0.45, 0)
			lm.lathe("Timber", p, PackedVector2Array([Vector2(0.22, 0.0), Vector2(0.2, EAVE - 0.95)]), 8, 1.0, 1.0, 0.0,
				true, false)
		lm.box("Timber", centre + off + Vector3(0, EAVE - 0.3, 0), Vector3(length, 0.4, 0.34), basis, 0.0)
		lm.box("Dancheong", centre + off + Vector3(0, EAVE - 0.0, 0), Vector3(length, 0.25, 0.3), basis, 0.0)
	# Gabled roof with the ridge roll; gable ends close the cut runs.
	var rise := width * 0.27
	lm.gable("Tiles", centre + Vector3(0, EAVE + 0.15, 0), width, length, rise,
		Basis(across, Vector3.UP, -d) if along_x else Basis(across, Vector3.UP, d), 1.1, "Plaster")
	lm.beam("Tiles", centre - d * length * 0.5 + Vector3(0, EAVE + 0.15 + rise, 0),
		centre + d * length * 0.5 + Vector3(0, EAVE + 0.15 + rise, 0), 0.4, 0.4)

## A gate in the cloister about `at`: Geunjeongmun (two storeys of 3 x 2
## bays to about 13.5 m) or a single-storey side gate, each on its stone
## base, built about the origin and placed with `basis`.
static func _gate(lm: LandmarkMesh, at: Vector3, main: bool, basis: Basis) -> void:
	var g := LandmarkMesh.new()
	LandmarkKoreanRoof.materials(g)
	if main:
		g.box("Granite", Vector3(0, 0.3, 0), Vector3(20.0, 0.6, 12.6))
		g.box("Granite", Vector3(0, 0.9, 0), Vector3(17.5, 0.6, 10.0))
		LandmarkKoreanRoof.two_storey(g, 1.2, Vector2(15.5, 8.0), Vector2(13.0, 6.0), 3.6, 2.8, 13.5)
	else:
		g.box("Granite", Vector3(0, 0.3, 0), Vector3(11.0, 0.6, 9.5))
		LandmarkKoreanRoof.one_storey(g, 0.6, Vector2(8.6, 6.4), 3.4, 8.6, Vector2i(3, 1))
	LandmarkKoreanRoof.place(lm, g, at, basis)
