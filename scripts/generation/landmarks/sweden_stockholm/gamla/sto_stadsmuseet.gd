extends RefCounted

## Stadsmuseet (Stockholm City Museum, in Södra stadshuset, Nicodemus
## Tessin the Elder, 1680) on the Södermalm hill above Slussen, built as a
## child of the Slussen model seated on the ground under its own origin
## (LandmarkTerrain.SEAT_META). Plan from OSM way 37265277 (three storeys,
## `roof:shape=many`, `roof:colour=black`, `building:colour=white`): a bent
## range of two arms round the Ryssgården court, 51 x 45 m, the outline's ten
## vertices in metres about its centroid.
## No photo of it is in visual-plan/refs/landmarks/slussen_guldbron/: the
## look (pale yellow-cream plaster, dark plain roof broken into steps,
## three storeys of tall paired-bar windows over a stone plinth, a stone
## cornice, tall brick chimneys) is the building's published description and
## the mapped tags, not a photo-measured facade; window counts follow the
## edge lengths at a 3.2 m pitch.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_gamla_kit.gd")

const PTS := [Vector2(6.07, -36.91), Vector2(-13.23, -21.11), Vector2(-33.13, -4.51), Vector2(-12.93, 20.39),
	Vector2(-4.93, 30.29), Vector2(5.07, 22.09), Vector2(-12.53, 0.69), Vector2(7.07, -15.11),
	Vector2(24.37, 5.99), Vector2(34.17, -1.81)]
const EAVE := 13.5
const PITCH := 3.2

static func materials() -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr("render", "#DACB9C", 3.0),
		"Trim": LandmarkMaterials.pbr("limestone", "#E6E0D0", 2.5),
		"Roof": LandmarkMaterials.pbr("slate", "#33363A", 2.5),
		"Glass": LandmarkMaterials.glass("#2A3236"),
	}

static func build(model: Node3D, at: Vector3) -> void:
	var mats := materials()
	var lm := K.fresh(mats)
	var poly := PackedVector2Array()
	for p in PTS:
		poly.append(p)
	lm.poly_prism("Wall", poly, 0.0, EAVE)
	var plinth := Geometry2D.offset_polygon(poly, 0.18)
	if not plinth.is_empty():
		lm.poly_prism("Trim", plinth[0], 0.0, 1.0, false)
	var cornice := Geometry2D.offset_polygon(poly, 0.45)
	if not cornice.is_empty():
		lm.poly_prism("Trim", cornice[0], EAVE - 0.7, EAVE + 0.2)
	_roof(lm, poly)
	_windows(lm, mats, poly)
	_chimneys(lm)
	var child := Node3D.new()
	child.name = "Stadsmuseet"
	child.position = at
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## The dark roof as three stepped courses (an approximation of the broken,
## many-planed roof).
static func _roof(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var steps := [[0.5, EAVE + 0.2, EAVE + 1.7], [1.5, EAVE + 1.7, EAVE + 3.0], [2.6, EAVE + 3.0, EAVE + 4.1]]
	for s in steps:
		var ring := Geometry2D.offset_polygon(poly, -float(s[0]))
		if ring.is_empty():
			continue
		lm.poly_prism("Roof", ring[0], float(s[1]), float(s[2]))

## Three rows of windows on every long edge, an arched door in the court.
static func _windows(lm: LandmarkMesh, mats: Dictionary, poly: PackedVector2Array) -> void:
	var win := K.flat_window(mats, "Trim", 1.2, 2.4)
	var area := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		area += p.x * q.y - q.x * p.y
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var e := q - p
		var len := e.length()
		if len < 6.0:
			continue
		var dir := e / len
		var n2 := Vector2(e.y, -e.x).normalized() * (1.0 if area > 0.0 else -1.0)
		var a := p + dir * 1.6
		var b := q - dir * 1.6
		var n := int((len - 3.2) / PITCH) + 1
		var out := Vector3(n2.x, 0, n2.y)
		K.window_rows(lm, win, Vector3(a.x, 0, a.y) + out * 0.02, Vector3(b.x, 0, b.y) + out * 0.02, out,
			1.4, n, 3, 4.0)

static func _chimneys(lm: LandmarkMesh) -> void:
	for c in [Vector2(-14.0, -10.0), Vector2(-10.0, 12.0), Vector2(16.0, -8.0), Vector2(-24.0, 3.0)]:
		K.Pal.rb(lm, "Wall", c.x - 0.7, c.x + 0.7, EAVE + 2.6, EAVE + 4.3, c.y - 0.7, c.y + 0.7, 0.0)
		K.Pal.rb(lm, "Trim", c.x - 0.85, c.x + 0.85, EAVE + 4.3, EAVE + 4.4, c.y - 0.85, c.y + 0.85, 0.0)
