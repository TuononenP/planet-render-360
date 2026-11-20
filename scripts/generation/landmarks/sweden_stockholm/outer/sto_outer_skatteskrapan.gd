class_name StoOuterSkatteskrapan
extends RefCounted

## Skatteskrapan, the Tax Agency tower (Skatteverket, Hammarbybacken side of
## Södermalm; 1960s, glazed in the 2000s), 85.5 m. True metres from the
## OSM outline of way 37046494 (x east, z south from its centroid, no yaw:
## registry `yaw_deg` 0); the 23 m low wing part 1558319802 is part of the
## model, the other low parts stay generated buildings.
##
## Facade spec, from visual-plan/refs/landmarks/skatteskrapan/ (front,
## quarter, aerial):
## - A pinwheel of four 12 m wide, 24-storey wings (81.5 m, 3.0 m storeys)
##   round a square core. Each wing has one end face and one long face of
##   pale-grey granulated concrete walls with a grey-blue curtain wall on
##   the other faces: the wing's end carries a 12-bay glass grid between
##   wide concrete piers, and its long side stands as a concrete wall with
##   a rank of narrow vertical window slots between concrete fins.
## - In the re-entrant corners the core shows as a black-glazed stair slot
##   with a cantilevered balcony landing at every storey.
## - On the core a flat glazed crown storey (81.5-84.8 m, OSM part
##   1558319797 to 85.5 m) under a pale concrete roof slab that overhangs
##   the glass by 1.5 m and carries a flat metal roof with a plant house.
## - The wing roofs are flat with a pale concrete rim and silver metal
##   roofing, a ventilation plant box each; two radio masts rise on the
##   south-west wing, the taller with a red aviation lamp, to 86 m.
## - The 23 m low wing joins the tower on the north-west side: a pale
##   concrete block with a glazed band.
## Window bays and the wing roof plant are scaled from the photos.
## Surfaces (9): Curtain, Concrete, Dark, Crown, Roof, Trim, Plant, Mast, Lamp.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const RING := [Vector2(-16.5, -20.9), Vector2(-12.1, -3.6), Vector2(-10.8, 1.4), Vector2(-25.0, 5.0),
	Vector2(-22.0, 16.5), Vector2(0.9, 10.7), Vector2(4.3, 23.9), Vector2(16.1, 20.9), Vector2(10.5, -1.1),
	Vector2(25.3, -4.8), Vector2(22.3, -16.5), Vector2(15.9, -14.9), Vector2(-1.3, -10.5), Vector2(-4.8, -23.9)]
const CORE := [Vector2(-6.6, 10.6), Vector2(10.4, 6.3), Vector2(6.1, -10.7), Vector2(-11.0, -6.4)]
const LOW_WING := [Vector2(-21.6, 16.4), Vector2(-16.9, 34.4), Vector2(5.5, 28.7), Vector2(0.9, 10.7)]
const BODY := 81.5
const CROWN_GLASS := 84.8
const TOP := 85.5
const STOREY := 3.0
const LOW_TOP := 23.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#B5BBBF", 3.0, 0.5, 0.45))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#C9C6BE", 3.0))
	lm.use("Plant", LandmarkMaterials.pbr("concrete", "#8D9093", 3.0))
	lm.use("Mast", LandmarkMaterials.paint("#9A9EA0", 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FF3A2A", 1.2))
	var kit := SkyKit.new(lm)
	kit.wall("Curtain", "silver_reflective", 3.0, STOREY)
	kit.wall("Concrete", "white_panel", 3.0, STOREY)
	kit.wall("Dark", "black_glass", 2.6, STOREY)
	kit.wall("Crown", "clear_fin", 3.0, 3.3)
	_body(lm, kit)
	_slots(lm)
	_crown(lm, kit)
	_roofs(lm)
	_low_wing(lm, kit)
	lm.commit(model, "Skatteskrapan_")

## Tower walls edge by edge: end faces curtain-glazed, long faces concrete,
## the short re-entrant edges black glass; then the metal roof and rim.
static func _body(lm: LandmarkMesh, kit: SkyKit) -> void:
	var ring := PackedVector2Array(RING)
	var w := SkyKit.winding(ring)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var len := a.distance_to(b)
		var n := SkyKit._edge_normal(a, b, w)
		var key := "Concrete"
		if len >= 9.0 and len <= 12.6:
			key = "Curtain"
		elif len < 9.0:
			key = "Dark"
		kit.face(key, a, b, 0.0, BODY, n)
		if key == "Curtain":
			_piers(lm, a, b, n)
		elif key == "Concrete":
			_fins(lm, a, b, n)
	lm.poly_prism("Roof", ring, BODY, BODY + 0.05, true)
	# Pale concrete rim round the wing roofs.
	lm.poly_prism("Trim", F.offset(ring, 0.25), BODY - 0.1, BODY + 0.9, false)

## Wide concrete piers at both ends of a glazed end face, and mullion fins.
static func _piers(lm: LandmarkMesh, a: Vector2, b: Vector2, n: Vector3) -> void:
	var along := (b - a).normalized()
	var basis := Basis(Vector3.UP, -atan2(along.y, along.x))
	var out := Vector2(n.x, n.z)
	for t in [0.9, b.distance_to(a) - 0.9]:
		var c := a + along * float(t) + out * 0.2
		lm.box("Trim", Vector3(c.x, BODY * 0.5, c.y), Vector3(1.8, BODY, 0.4), basis, 0.0)
	var count := int(a.distance_to(b) / 1.5)
	for k in range(1, count):
		var c := a + along * (float(k) * a.distance_to(b) / float(count)) + out * 0.1
		lm.box("Trim", Vector3(c.x, BODY * 0.5, c.y), Vector3(0.1, BODY, 0.2), basis, 0.0)

## Concrete fins between the slot windows of a long wing face.
static func _fins(lm: LandmarkMesh, a: Vector2, b: Vector2, n: Vector3) -> void:
	var along := (b - a).normalized()
	var basis := Basis(Vector3.UP, -atan2(along.y, along.x))
	var out := Vector2(n.x, n.z)
	var count := int(a.distance_to(b) / 2.4)
	for k in range(1, count):
		var c := a + along * (float(k) * a.distance_to(b) / float(count)) + out * 0.15
		lm.box("Trim", Vector3(c.x, BODY * 0.5, c.y), Vector3(0.7, BODY, 0.3), basis, 0.0)

## Balcony landings up the black-glazed stair slots (the short edges).
static func _slots(lm: LandmarkMesh) -> void:
	var ring := PackedVector2Array(RING)
	var w := SkyKit.winding(ring)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var len := a.distance_to(b)
		if len >= 9.0 or len < 4.0:
			continue
		var n := SkyKit._edge_normal(a, b, w)
		var along := (b - a).normalized()
		var basis := Basis(Vector3.UP, -atan2(along.y, along.x))
		var c := (a + b) * 0.5 + Vector2(n.x, n.z) * 0.5
		for s in 26:
			lm.box("Trim", Vector3(c.x, 3.0 + STOREY * float(s), c.y), Vector3(len, 0.14, 1.0), basis, 0.0)

## Glazed crown storey on the core under the overhanging roof slab.
static func _crown(lm: LandmarkMesh, kit: SkyKit) -> void:
	var core := PackedVector2Array(CORE)
	kit.prism("Crown", core, BODY, CROWN_GLASS)
	var slab := F.offset(core, 1.5)
	lm.poly_prism("Trim", slab, CROWN_GLASS, TOP - 0.3, true)
	lm.poly_prism("Roof", F.offset(core, 1.0), TOP - 0.3, TOP - 0.1, true)
	var c := Vector2(2.0, 0.0)
	lm.box("Plant", Vector3(c.x - 3.0, TOP + 0.3, c.y - 2.0), Vector3(4.0, 1.0, 3.0), Basis(), 0.0)

## Plant boxes and the two radio masts on the wing roofs.
static func _roofs(lm: LandmarkMesh) -> void:
	for p in [[Vector2(-18.0, 6.5), 3.5], [Vector2(16.0, 3.0), 3.0], [Vector2(12.0, 15.0), 3.0],
			[Vector2(-9.0, -15.5), 3.0]]:
		var c: Vector2 = p[0]
		var s: float = p[1]
		lm.box("Plant", Vector3(c.x, BODY + 1.4, c.y), Vector3(s, 1.8, s * 0.8), Basis(Vector3.UP, -0.25), 0.0)
		lm.box("Roof", Vector3(c.x, BODY + 2.35, c.y), Vector3(s + 0.3, 0.1, s * 0.8 + 0.3), Basis(Vector3.UP, -0.25), 0.0)
	var m := Vector2(12.5, 10.5)
	lm.beam("Mast", Vector3(m.x, BODY, m.y), Vector3(m.x, TOP + 0.5, m.y), 0.1, 0.1)
	lm.beam("Mast", Vector3(m.x + 1.6, BODY, m.y - 0.8), Vector3(m.x + 1.6, TOP, m.y - 0.8), 0.1, 0.1)
	lm.box("Lamp", Vector3(m.x, TOP + 0.5, m.y), Vector3(0.35, 0.35, 0.35), Basis(), 0.0)

## The 23 m wing joined to the tower: pale concrete with a glazed band.
static func _low_wing(lm: LandmarkMesh, kit: SkyKit) -> void:
	var poly := PackedVector2Array(LOW_WING)
	var w := SkyKit.winding(poly)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 3.0:
			continue
		var n := SkyKit._edge_normal(a, b, w)
		kit.face("Concrete", a, b, 0.0, LOW_TOP, n)
	lm.poly_prism("Roof", poly, LOW_TOP, LOW_TOP + 0.05, true)
	lm.poly_prism("Trim", F.offset(poly, 0.2), LOW_TOP - 0.1, LOW_TOP + 0.7, false)
