extends RefCounted

## Slussen: the new Guldbron (OSM relation 15753921 "Slussbron", loc_name
## Guldbron, `bridge:structure=beam`; 2020s) and, 200 m to the west on its
## hill, Stadsmuseet (Södra stadshuset, OSM way 37265277) which
## sto_stadsmuseet.gd builds as a ground-seated child.
##
## Frame: origin on the Guldbron outline's centroid (59.320992, 18.073648),
## registry yaw -64.3: +X runs along the bridge at bearing 25.7 (north-north-east,
## Södermalm end at -X, Gamla stan end at +X) and +Z is east-south-east, toward
## Stadsgårdskajen. y = 0 is the water level (`base: water`).
##
## Guldbron, from the refs in visual-plan/refs/landmarks/slussen_guldbron/:
## a long flat steel bridge, 141 x 45.5 m, whose box girder and deck plate are
## clad in dull gold-olive panels (the "gilded" bridge): a cantilevered
## edge 2 m deep over a central box 1.8 m deeper, its soffit a
## smooth plate with a few round concrete columns under steel pier heads. The
## deck top stands 10.4 m over the water and carries a two-lane carriageway in
## the middle, wide pale pedestrian and cycle strips on both sides, a steel
## and rail parapet along both edges, and lamp standards (top at 18 m).
## The south-west corner is cut back where the deck meets Katarinavägen.
## Concrete abutment stubs close both ends under the girder.

const Museum = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_stadsmuseet.gd")

const OUTLINE := [Vector2(-69.7, 22.8), Vector2(-45.7, 23.3), Vector2(71.7, 21.1), Vector2(71.6, 17.8),
	Vector2(71.2, 8.8), Vector2(70.5, -11.1), Vector2(70.0, -22.5), Vector2(-66.6, -22.4),
	Vector2(-69.8, -22.4), Vector2(-69.8, -17.7), Vector2(-69.8, -9.2), Vector2(-69.8, 11.0)]
## Stadsmuseet's origin (the centroid of its mapped outline) in this frame.
const MUSEUM_AT := Vector3(-192.5, 0.0, -67.5)

const DECK_TOP := 10.4
const GIRDER_BOT := 6.6
const EDGE_BOT := 8.4
const TOP := 18.0
const COLS_X := [-47.0, -1.0, 45.0]
const COLS_Z := [-15.0, 0.0, 15.0]

static func materials() -> Dictionary:
	return {
		"Gold": LandmarkMaterials.pbr("concrete", "#8F8547", 3.0, 0.42, 0.5),
		"Deck": LandmarkMaterials.pbr("concrete", "#3A3C3F", 3.0, 0.8),
		"Walk": LandmarkMaterials.pbr("pavement", "#B7B1A4", 2.5),
		"Concrete": LandmarkMaterials.pbr("concrete", "#8E8D88", 3.0),
		"Granite": LandmarkMaterials.pbr("stone", "#7B746E", 3.0),
		"Iron": LandmarkMaterials.paint("#34393B", 0.5, 0.5),
		"Paint": LandmarkMaterials.paint("#E8E8E0", 0.7, 0.0),
		"Lamp": LandmarkMaterials.lit("#FFE2A8", 1.2),
	}

static func build(model: Node3D) -> void:
	var mats := materials()
	var lm := LandmarkMesh.new()
	for k in mats:
		lm.use(str(k), mats[k])
	var poly := PackedVector2Array()
	for p in OUTLINE:
		poly.append(p)
	_girder(lm, poly)
	_deck(lm, poly)
	_piers(lm)
	_parapet(lm)
	_lamps(lm)
	lm.commit(model)
	Museum.build(model, MUSEUM_AT)
	var warm := Color(1.0, 0.88, 0.7)
	var spots: Array = []
	for x in [-50.0, 0.0, 50.0]:
		spots.append([Vector3(float(x), 1.0, 30.0), Vector3(float(x), 8.0, 0.0), 46.0, 0.8, 46.0, warm])
	spots.append([Vector3(MUSEUM_AT.x + 30.0, 1.5, MUSEUM_AT.z + 28.0), Vector3(MUSEUM_AT.x, 8.0, MUSEUM_AT.z), 50.0, 0.9, 50.0, warm])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

## Cantilevered edge plate and the deeper central box girder (gold steel).
static func _girder(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	lm.poly_prism("Gold", poly, EDGE_BOT, DECK_TOP, false)
	var inner := Geometry2D.offset_polygon(poly, -4.5)
	if not inner.is_empty():
		lm.poly_prism("Gold", inner[0], GIRDER_BOT, EDGE_BOT, false)
		# Soffit plate under the box, closed so the underside reads as one skin.
		var idx := Geometry2D.triangulate_polygon(inner[0])
		for t in range(0, idx.size(), 3):
			var a := (inner[0] as PackedVector2Array)[idx[t]]
			var b := (inner[0] as PackedVector2Array)[idx[t + 1]]
			var c := (inner[0] as PackedVector2Array)[idx[t + 2]]
			lm.tri("Gold", Vector3(a.x, GIRDER_BOT, a.y), Vector3(c.x, GIRDER_BOT, c.y), Vector3(b.x, GIRDER_BOT, b.y),
				Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, c, b)
	var under := Geometry2D.offset_polygon(poly, -0.01)
	if not under.is_empty():
		var u: PackedVector2Array = under[0]
		var idx2 := Geometry2D.triangulate_polygon(u)
		for t in range(0, idx2.size(), 3):
			var a := u[idx2[t]]
			var b := u[idx2[t + 1]]
			var c := u[idx2[t + 2]]
			lm.tri("Gold", Vector3(a.x, EDGE_BOT, a.y), Vector3(c.x, EDGE_BOT, c.y), Vector3(b.x, EDGE_BOT, b.y),
				Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, c, b)

## Asphalt carriageway, pale pedestrian and cycle strips, lane marks.
static func _deck(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var top := Geometry2D.offset_polygon(poly, -0.4)
	if not top.is_empty():
		lm.poly_prism("Deck", top[0], DECK_TOP, DECK_TOP + 0.07)
	var y := DECK_TOP + 0.07
	# Pedestrian/cycle strips along both edges (the south-west corner is cut back).
	_rb(lm, "Walk", -44.0, 70.5, y, y + 0.06, 13.5, 21.9)
	_rb(lm, "Walk", -69.0, 70.5, y, y + 0.06, -21.9, -13.5)
	_rb(lm, "Walk", -69.0, -45.0, y, y + 0.06, 11.5, 13.5)
	# Kerbs, centre line (dashes), cycle-lane line.
	_rb(lm, "Concrete", -69.0, 70.5, y, y + 0.16, 13.3, 13.6)
	_rb(lm, "Concrete", -69.0, 70.5, y, y + 0.16, -13.6, -13.3)
	var x := -66.0
	while x < 68.0:
		_rb(lm, "Paint", x, x + 3.0, y, y + 0.08, -0.1, 0.1)
		x += 7.0
	_rb(lm, "Paint", -44.0, 70.0, y + 0.06, y + 0.1, 18.0, 18.12)
	_rb(lm, "Paint", -69.0, 70.0, y + 0.06, y + 0.1, -18.0, -17.88)

static func _rb(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, y1 - y0, z1 - z0),
		Basis(), 0.0)

## Round columns in three rows under steel pier heads, abutment stubs.
static func _piers(lm: LandmarkMesh) -> void:
	for x: float in COLS_X:
		_rb(lm, "Iron", x - 1.7, x + 1.7, GIRDER_BOT - 1.1, GIRDER_BOT, -19.0, 19.0)
		for z: float in COLS_Z:
			lm.frustum("Concrete", Vector3(x, -3.0, z), 1.35, 1.15, GIRDER_BOT - 1.1 + 3.0, 14)
			lm.frustum("Iron", Vector3(x, GIRDER_BOT - 1.45, z), 1.25, 1.7, 0.35, 10)
	_rb(lm, "Granite", -69.0, -62.0, -3.0, GIRDER_BOT, -21.0, 21.0)
	_rb(lm, "Granite", 63.0, 70.0, -3.0, GIRDER_BOT, -21.0, 21.0)

## Steel posts and rails along both long edges.
static func _parapet(lm: LandmarkMesh) -> void:
	var centres := PackedVector3Array()
	var sizes := PackedVector3Array()
	var x := -68.0
	while x <= 71.0:
		for z in [-22.0, 22.0]:
			centres.append(Vector3(x, DECK_TOP + 0.6, float(z)))
			sizes.append(Vector3(0.09, 1.2, 0.09))
		x += 2.5
	lm.boxes("Iron", centres, sizes, Basis(), 0.0)
	for z in [-22.0, 22.0]:
		_rb(lm, "Gold", -69.0, 71.2, DECK_TOP + 1.12, DECK_TOP + 1.22, float(z) - 0.08, float(z) + 0.08)
		_rb(lm, "Iron", -69.0, 71.2, DECK_TOP + 0.55, DECK_TOP + 0.6, float(z) - 0.03, float(z) + 0.03)

## Lamp standards along the strips, glowing heads at 18 m.
static func _lamps(lm: LandmarkMesh) -> void:
	for x in [-60.0, -30.0, 0.0, 30.0, 60.0]:
		for z in [-17.0, 17.0]:
			var p := Vector3(float(x), DECK_TOP + 0.13, float(z))
			var h := TOP - DECK_TOP - 0.13 - 0.5
			lm.frustum("Iron", p, 0.16, 0.09, h, 8)
			var toward := -signf(float(z)) * 2.0
			lm.beam("Iron", p + Vector3(0, h - 0.2, 0), p + Vector3(0, h + 0.1, toward), 0.1)
			lm.box("Lamp", p + Vector3(0, h + 0.2, toward), Vector3(0.9, 0.22, 0.4), Basis(), 0.0)
