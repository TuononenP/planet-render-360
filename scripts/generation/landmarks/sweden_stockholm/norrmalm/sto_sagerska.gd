extends RefCounted

## Sagerska huset (Sagerska palatset), Strömgatan 18 beside Rosenbad: the
## 1890s neo-baroque town palace in pale stone. Origin at the OSM footprint
## centre (way 141844590, 24.2 x 19.5 m, bearing 152.5). The registry yaw
## 62.5 turns +X onto SSE, so the 19.5 m front faces +X (toward the water);
## Arvfurstens palats stands beside it on the -Z side, Rosenbad on +Z.
## 17.4 m to the flat top of the central mansard bay.
##
## From the photos (visual-plan/refs/landmarks/sagerska_huset/):
## - Three storeys of cream plaster-and-stone: a rusticated low ground
##   floor (barred windows between two doors, one with a small awning), a
##   first floor of seven windows each with a wrought-iron balcony rail on
##   scroll brackets, and a tall piano nobile whose four outer windows
##   (two a side) sit over iron balconies, with a cartouche between window
##   and oriel.
## - The centre carries a three-window, full-height stone oriel on a
##   corbelled base under a small zinc-grey hip roof.
## - Above the cornice a stone balustrade runs the front and a dark scaly
##   mansard (steep slope, flat top) with pedimented dormers at the outer
##   bays, round oeil-de-boeuf windows between them and, over the oriel, a
##   taller pavilion carrying the large ornate dormer.
## Sources: docs/stockholm-landmark-sources.md; the Commons photos (front.jpg
## scaled at 72 px/m from the 19.5 m front gives 17.4 m to the pavilion top
## and storey heights of 3.0 / 3.6 / 5.2 m). Window counts follow front.jpg.

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")
const Pal = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")
const Nm = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_nm_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const HX := 12.1
const HZ := 9.75
const EAVE := 11.8
const FRONT := Vector3(1, 0, 0)
## Mansard: [inset, rise] of the eave, the break and the flat top.
const MANSARD := [[0.0, 0.0], [1.6, 3.4], [3.4, 4.4]]
const PAVILION := [[0.0, 0.0], [1.2, 4.6], [2.4, 5.6]]
## Tilt of the mansard's lower slope off vertical (radians).
const TILT := 0.5

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := Kit.fresh(mats)
	_body(lm)
	_front_windows(lm, mats)
	_oriel(lm, mats)
	_balconies(lm, mats)
	_sides(lm, mats)
	_roof(lm, mats)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr("render", "#E9DCBC", 3.0),
		"Trim": LandmarkMaterials.pbr("limestone", "#F0E7D2", 2.6),
		"Rust": LandmarkMaterials.pbr("render", "#D3C39C", 3.0),
		"Slate": LandmarkMaterials.pbr("slate", "#2F2C29", 2.5),
		"Frame": LandmarkMaterials.paint("#6E3328", 0.6, 0.0),
		"Iron": LandmarkMaterials.paint("#222426"),
		"Glass": LandmarkMaterials.glass("#2A3A34"),
	}

## Body, rusticated ground floor, string courses, cornice and balustrade.
static func _body(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Wall", 0.0, 0.0, 0.0, HX * 2.0, EAVE, HZ * 2.0)
	Pal.courses(lm, "Rust", Vector3(HX, 0, 0), FRONT, HZ * 2.0, 0.0, 3.0, 0.55, 0.1, 0.06)
	for s in [-1.0, 1.0]:
		var sg: float = s
		Pal.courses(lm, "Rust", Vector3(0, 0, sg * HZ), Vector3(0, 0, sg), HX * 2.0, 0.0, 3.0, 0.55, 0.1, 0.06)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, 3.0, 0.3, 0.12)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, EAVE - 0.9, 0.9, 0.45)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, EAVE - 0.3, 0.3, 0.7)
	# Pilaster strips frame the front at its ends and flank the oriel.
	for z in [-9.2, -4.1, 4.1, 9.2]:
		lm.box("Trim", Vector3(HX + 0.08, 8.4, float(z)), Vector3(0.2, 5.2, 0.5), Basis(), 0.0)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(HX + 0.3, EAVE, -HZ + 0.1), Vector3(HX + 0.3, EAVE, HZ - 0.1), 0.95, 3.4, 6)

## Ground-floor doors and barred windows, the first-floor row and the tall
## upper windows.
static func _front_windows(lm: LandmarkMesh, mats: Dictionary) -> void:
	var a := Vector3(HX, 0, -HZ)
	var b := Vector3(HX, 0, HZ)
	var barred := Nm.window(mats, "Trim", 1.0, 1.5)
	Kit.row(lm, barred, a, b, FRONT, 0.8, 8, [0, 7])
	for i in [0, 7]:
		var z := lerpf(-HZ, HZ, (float(i) + 0.5) / 8.0)
		lm.box("Frame", Vector3(HX + 0.08, 1.4, z), Vector3(0.14, 2.8, 1.8), Basis(), 0.0)
		lm.box("Trim", Vector3(HX + 0.05, 2.95, z), Vector3(0.2, 0.25, 2.3), Basis(), 0.0)
	Pal.awning(lm, "Iron", Vector3(HX + 0.1, 3.0, -8.53), FRONT, 2.4, 1.0, 0.5)
	var mid := Nm.window(mats, "Trim", 1.0, 2.2)
	Kit.row(lm, mid, a, b, FRONT, 3.5, 7)
	var tall := Nm.window(mats, "Trim", 1.3, 3.2)
	for z in [-8.2, -5.9, 5.9, 8.2]:
		Kit.put(lm, tall, Vector3(HX, 7.3, float(z)), FRONT)
	# Cartouches between the oriel and the outer windows.
	var cart := Kit.roundel(mats, "Trim", 0.75)
	for z in [-3.6, 3.6]:
		Kit.put(lm, cart, Vector3(HX + 0.05, 8.9, float(z)), FRONT)

## The central oriel: corbelled base, four posts, panes, a zinc hip.
static func _oriel(lm: LandmarkMesh, mats: Dictionary) -> void:
	var x := HX + 0.6
	lm.box("Trim", Vector3(x, 6.0, 0), Vector3(1.4, 0.5, 5.8), Basis(), 0.0)
	for k in 3:
		lm.box("Trim", Vector3(HX + 0.3, 5.5 - float(k) * 0.0, (float(k) - 1.0) * 1.8), Vector3(0.5, 0.5, 0.5), Basis(), 0.0)
	for k in 4:
		lm.box("Trim", Vector3(x + 0.45, 8.9, (float(k) - 1.5) * 1.85), Vector3(0.28, 5.3, 0.28), Basis(), 0.0)
	lm.box("Trim", Vector3(x, 11.4, 0), Vector3(1.5, 0.4, 5.9), Basis(), 0.0)
	var pane := Nm.window(mats, "Trim", 1.35, 4.4)
	for k in 3:
		Kit.put(lm, pane, Vector3(x + 0.32, 6.4, (float(k) - 1.0) * 1.85), FRONT)
	Kit.hip(lm, "Slate", Vector3(x, 11.6, 0), 0.8, 3.0, [[0.0, 0.0], [0.7, 0.8]])

## Wrought-iron balconies under the first-floor windows and the tall ones.
static func _balconies(lm: LandmarkMesh, mats: Dictionary) -> void:
	for i in 7:
		var z := lerpf(-HZ, HZ, (float(i) + 0.5) / 7.0)
		lm.box("Trim", Vector3(HX + 0.3, 3.55, z), Vector3(0.7, 0.12, 1.5), Basis(), 0.0)
		Kit.railing(lm, "Iron", Vector3(HX + 0.62, 3.6, z - 0.7), Vector3(HX + 0.62, 3.6, z + 0.7), 0.85, 0.3)
	for z in [-5.9, 5.9]:
		var zz: float = z
		lm.box("Trim", Vector3(HX + 0.5, 6.6, zz), Vector3(1.0, 0.25, 2.4), Basis(), 0.0)
		Kit.railing(lm, "Iron", Vector3(HX + 1.0, 6.7, zz - 1.1), Vector3(HX + 1.0, 6.7, zz + 1.1), 1.0, 0.3)
		for s in [-1.0, 1.0]:
			lm.box("Trim", Vector3(HX + 0.2, 6.0, zz + float(s) * 0.9), Vector3(0.4, 0.5, 0.3), Basis(), 0.0)

## Plain side and rear walls: three rows of windows.
static func _sides(lm: LandmarkMesh, mats: Dictionary) -> void:
	var low := Nm.window(mats, "Trim", 1.0, 1.5)
	var mid := Nm.window(mats, "Trim", 1.2, 2.4)
	var tall := Nm.window(mats, "Trim", 1.3, 3.2)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var a := Vector3(-HX, 0, sg * HZ)
		var b := Vector3(HX, 0, sg * HZ)
		var out := Vector3(0, 0, sg)
		Kit.row(lm, low, a, b, out, 0.8, 5)
		Kit.row(lm, mid, a, b, out, 3.6, 5)
		Kit.row(lm, tall, a, b, out, 7.3, 5)
	var a2 := Vector3(-HX, 0, -HZ)
	var b2 := Vector3(-HX, 0, HZ)
	Kit.row(lm, low, a2, b2, Vector3(-1, 0, 0), 0.8, 4)
	Kit.row(lm, mid, a2, b2, Vector3(-1, 0, 0), 3.6, 4)
	Kit.row(lm, tall, a2, b2, Vector3(-1, 0, 0), 7.3, 4)

## Mansard, central pavilion, dormers and the round windows between them.
static func _roof(lm: LandmarkMesh, mats: Dictionary) -> void:
	Kit.hip(lm, "Slate", Vector3(0, EAVE, 0), HX + 0.2, HZ + 0.2, MANSARD)
	Kit.hip(lm, "Slate", Vector3(8.2, EAVE, 0), 4.2, 3.0, PAVILION)
	var dormer := Nm.dormer(mats, "Trim", 1.6, 2.0)
	for z in [-5.7, 5.7]:
		Kit.put(lm, dormer, Vector3(11.5, 12.9, float(z)), FRONT)
	var big := Nm.dormer(mats, "Trim", 2.6, 2.3)
	Kit.put(lm, big, Vector3(11.3, 13.7, 0), FRONT)
	var eye := Kit.roundel(mats, "Trim", 0.6)
	for z in [-8.2, -3.5, 3.5, 8.2]:
		Nm.put_tilted(lm, eye, Vector3(11.5, 13.5, float(z)), FRONT, TILT)
