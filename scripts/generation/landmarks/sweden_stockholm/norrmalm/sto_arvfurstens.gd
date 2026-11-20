extends RefCounted

## Arvfurstens palats (the Heir Apparent's Palace, 1783-94, Tessin the
## Younger's design after Carl Hårleman), Gustav Adolfs torg, beside the
## Opera. Origin at the OSM footprint centre (relation 279567, 65.3 x 38.3 m,
## bearing 151.9). The registry yaw 61.9 turns +X onto SSE, so the 38.3 m
## pedimented front faces +X (the water) and the long plain wing runs back
## along -X (Fredsgatan). 25 m to the chimney caps (22.6 m at the flat top of the copper roof).
##
## From the photos (visual-plan/refs/landmarks/arvfurstens_palats/):
## - A rusticated ground floor 6.4 m high in dull red-brown stucco with
##   nine round-headed bays on the front (a doorway in the middle, small
##   balcony over it), returning round the corners.
## - Two piano-nobile floors of ochre-yellow panels between pale grey
##   pilasters: the front has nine window bays, the middle five projecting
##   slightly as a risalit between six Corinthian pilasters, under a
##   triangular pediment with an oculus; grey surrounds, the first floor
##   with moulded heads. Wide pilaster piers close each corner.
## - A heavy entablature, then a pale green copper hip roof with a flat top.
## - The long sides are plain ochre plaster on a sandstone plinth: 14 bays
##   in three rows and, on the Fredsgatan side, a rusticated stone portal
##   (columns, lions, arms).
## Sources: docs/stockholm-landmark-sources.md; the Commons photos (storey
## heights scaled from side.jpg at 39 px/m against the 38.3 m front).

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")
const Pal = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")
const Nm = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_nm_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const HX := 32.65
const HZ := 19.15
const GROUND := 6.4
const EAVE := 17.8
const FRONT := Vector3(1, 0, 0)
const ROOF_RISE := 4.8
const PEDIMENT_RISE := 3.4

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := Kit.fresh(mats)
	_body(lm)
	_front(lm, mats)
	_pilasters(lm, mats)
	_sides(lm, mats)
	_portal(lm)
	_roof(lm, mats)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Rust": LandmarkMaterials.pbr("render", "#B0766A", 3.0),
		"Wall": LandmarkMaterials.pbr("render", "#E4B260", 3.0),
		"Pilaster": LandmarkMaterials.pbr("limestone", "#BDBEB6", 2.6),
		"Trim": LandmarkMaterials.pbr("limestone", "#D2D1C8", 2.6),
		"Stone": LandmarkMaterials.pbr("limestone", "#B79E74", 2.6),
		"Copper": LandmarkMaterials.pbr("copper", "#8DAA9A", 2.0),
		"Frame": LandmarkMaterials.paint("#9B7B3C", 0.6, 0.0),
		"Iron": LandmarkMaterials.paint("#242628"),
		"Glass": LandmarkMaterials.glass("#2A3238"),
	}

## Masses: the ochre block, the rusticated skin on the front and its
## returns, the risalit, plinth, string course and the entablature.
static func _body(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Wall", 0.0, 0.0, 0.0, HX * 2.0, EAVE, HZ * 2.0)
	FhU.blk(lm, "Rust", HX + 0.15, 0.0, 0.0, 0.3, GROUND, HZ * 2.0 + 0.6)
	for s in [-1.0, 1.0]:
		var sg: float = s
		FhU.blk(lm, "Rust", HX - 4.0, 0.0, sg * (HZ + 0.15), 8.6, GROUND, 0.3)
	Pal.courses(lm, "Trim", Vector3(HX + 0.3, 0, 0), FRONT, HZ * 2.0, 0.0, GROUND, 0.8, 0.1, 0.06)
	Nm.ring(lm, "Stone", 0.0, 0.0, HX * 2.0, HZ * 2.0, 0.0, 1.1, 0.18)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, GROUND, 0.35, 0.3)
	# Risalit across the middle five bays.
	FhU.blk(lm, "Wall", HX + 0.3, GROUND, 0.0, 0.6, EAVE - GROUND - 1.4, 22.0)
	# Entablature, projecting further over the risalit.
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, EAVE - 1.4, 1.1, 0.55)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, EAVE - 0.3, 0.3, 0.95)
	lm.box("Trim", Vector3(HX + 0.65, EAVE - 0.85, 0), Vector3(1.5, 1.1, 22.6), Basis(), 0.0)
	lm.box("Trim", Vector3(HX + 0.7, EAVE - 0.15, 0), Vector3(1.6, 0.3, 23.0), Basis(), 0.0)

## Round-headed ground bays, the door and balcony, both piano-nobile rows.
static func _front(lm: LandmarkMesh, mats: Dictionary) -> void:
	var gx := HX + 0.3
	var offs := [-16.8, -12.6, -8.4, -4.2, 4.2, 8.4, 12.6, 16.8]
	Pal.wins(lm, "Frame", "Glass", Vector3(gx, 0, 0), FRONT, offs, 0.9, 1.6, 3.6, true, 0.25)
	# Centre doorway.
	FhU.opening(lm, "Frame", Vector3(gx + 0.05, 0.1, 0), FRONT, 2.3, 4.4, true)
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box("Trim", Vector3(gx + 0.15, 2.4, sg * 1.45), Vector3(0.4, 4.8, 0.5), Basis(), 0.0)
	lm.box("Trim", Vector3(gx + 0.15, 5.0, 0), Vector3(0.45, 0.5, 3.4), Basis(), 0.0)
	lm.box("Trim", Vector3(gx + 0.55, GROUND + 0.1, 0), Vector3(1.2, 0.3, 3.2), Basis(), 0.0)
	Kit.railing(lm, "Iron", Vector3(gx + 1.1, GROUND + 0.25, -1.5), Vector3(gx + 1.1, GROUND + 0.25, 1.5), 0.95, 0.3)
	# First floor: five risalit windows with moulded heads, two outer a side.
	var w1_mid := [-8.4, -4.2, 0.0, 4.2, 8.4]
	var w1_out := [-16.8, -12.6, 12.6, 16.8]
	Pal.wins(lm, "Trim", "Glass", Vector3(HX + 0.6, 0, 0), FRONT, w1_mid, 7.4, 1.5, 3.0, false, 0.3)
	Pal.wins(lm, "Trim", "Glass", Vector3(HX, 0, 0), FRONT, w1_out, 7.4, 1.5, 3.0, false, 0.25)
	Pal.wins(lm, "Trim", "Glass", Vector3(HX + 0.6, 0, 0), FRONT, w1_mid, 12.3, 1.5, 2.6, false, 0.2)
	Pal.wins(lm, "Trim", "Glass", Vector3(HX, 0, 0), FRONT, w1_out, 12.3, 1.5, 2.6, false, 0.2)

## Six Corinthian pilasters on the risalit and the wide corner piers.
static func _pilasters(lm: LandmarkMesh, mats: Dictionary) -> void:
	var ped_h := EAVE - 1.4 - GROUND
	var corinthian := Kit.pilaster(mats, "Pilaster", ped_h, 0.95, 0.45, "corinthian")
	for z in [-10.5, -6.3, -2.1, 2.1, 6.3, 10.5]:
		Kit.put(lm, corinthian, Vector3(HX + 0.6, GROUND, float(z)), FRONT)
	var pier := Kit.pilaster(mats, "Pilaster", ped_h, 1.5, 0.4, "corinthian")
	for s in [-1.0, 1.0]:
		var sg: float = s
		Kit.put(lm, pier, Vector3(HX, GROUND, sg * (HZ - 0.8)), FRONT)
		Kit.put(lm, pier, Vector3(HX - 0.8, GROUND, sg * HZ), Vector3(0, 0, sg))

## The long ochre sides and the plain rear: 14 and 8 bays, three rows.
static func _sides(lm: LandmarkMesh, mats: Dictionary) -> void:
	var low := Nm.window(mats, "Trim", 1.3, 1.9)
	var upper := Nm.window(mats, "Trim", 1.4, 2.7)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var a := Vector3(-HX, 0, sg * HZ)
		var b := Vector3(HX, 0, sg * HZ)
		var out := Vector3(0, 0, sg)
		# The east two bays stand on the rusticated return: left bare.
		Kit.row(lm, low, a, b, out, 1.2, 14, [12, 13])
		Kit.row(lm, upper, a, b, out, 7.4, 14)
		Kit.row(lm, upper, a, b, out, 12.3, 14)
	var a2 := Vector3(-HX, 0, -HZ)
	var b2 := Vector3(-HX, 0, HZ)
	var back := Vector3(-1, 0, 0)
	Kit.row(lm, low, a2, b2, back, 1.2, 8)
	Kit.row(lm, upper, a2, b2, back, 7.4, 8)
	Kit.row(lm, upper, a2, b2, back, 12.3, 8)

## The Fredsgatan portal: sandstone surround, door, ball-topped piers,
## a lion on each and a cartouche.
static func _portal(lm: LandmarkMesh) -> void:
	var z := HZ + 0.35
	var x := -6.0
	FhU.opening(lm, "Frame", Vector3(x, 0.4, z + 0.05), Vector3(0, 0, 1), 2.3, 3.9, true)
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box("Stone", Vector3(x + sg * 1.75, 3.3, z + 0.3), Vector3(1.0, 6.6, 0.9), Basis(), 0.0)
		lm.box("Stone", Vector3(x + sg * 1.75, 6.9, z + 0.3), Vector3(1.3, 0.6, 1.2), Basis(), 0.0)
		lm.lathe("Stone", Vector3(x + sg * 1.75, 7.2, z + 0.3), FhU.ball(0.5), 8)
		lm.box("Stone", Vector3(x + sg * 1.4, 7.7, z + 0.1), Vector3(0.9, 0.9, 1.2), Basis(), 0.0)
	lm.box("Stone", Vector3(x, 5.0, z + 0.3), Vector3(4.6, 1.2, 1.0), Basis(), 0.0)
	lm.box("Stone", Vector3(x, 6.4, z + 0.2), Vector3(2.4, 2.4, 0.5), Basis(), 0.0)
	FhU.steps(lm, "Stone", Vector3(x, 0.0, z), Vector3(0, 0, 1), 3.6, 0.35, 0.16, 3)

## Copper hip roof with its flat top, the front pediment and the oculus.
static func _roof(lm: LandmarkMesh, mats: Dictionary) -> void:
	Kit.hip(lm, "Copper", Vector3(0, EAVE, 0), HX + 0.7, HZ + 0.7, [[0.0, 0.0], [11.6, ROOF_RISE]])
	FhU.ridge_x(lm, "Trim", "Wall", Vector3(HX - 2.15, EAVE, 0), 7.0, 22.4, PEDIMENT_RISE, 0.5)
	var eye := Kit.roundel(mats, "Trim", 1.0)
	Kit.put(lm, eye, Vector3(HX + 1.35, EAVE + 1.45, 0), FRONT)
	for p in [[-12.0, 5.0], [8.0, -5.0], [-18.0, -5.0]]:
		Nm.chimney(lm, "Wall", "Trim", Vector3(float(p[0]), EAVE + ROOF_RISE - 0.1, float(p[1])), 1.8, 1.8, 2.3)
