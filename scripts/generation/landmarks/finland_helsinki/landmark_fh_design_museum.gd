extends RefCounted

## Design Museum (Designmuseo, Korkeavuorenkatu 23; the Swedish-language
## school, Gustaf Nystrom, 1894), Kaartinkaupunki. Front +Z is the street
## face; the registry yaw (86.3) turns it west, onto OSM way 22500092's
## 41.7 m long face.
##
## From the Commons photos in visual-plan/refs/landmarks/design_museum_helsinki/:
## - a red-brick Gothic/Renaissance Revival block of three bands: a high
##   plinth of cream rusticated stone with small arched basement windows,
##   a first floor of tall rectangular windows with cream sills, a cream
##   string course, and a second floor of round-headed windows with cream hood
##   moulds, under a dentilled cornice;
## - eleven bays: two wings of three bays either side of a taller central
##   pavilion, with the arched entrance in a stone surround at its middle;
## - the pavilion carries five small stepped gables over paired lancet
##   windows, a round rose window in the middle one, corner turrets with grey
##   zinc spires, and a tall grey zinc spire over the middle on a grey
##   hipped roof;
## - the wings have a low hipped roof behind a plain parapet.
##
## Measured: outline and position (OSM; 21.9 m central pavilion, wings 9-10
## m each). Estimated by scaling the front photograph against the 41.7 m
## face: plinth 2.5 m, cornice 12.2 m, gables 16.4 m, turret tips 18.7 m,
## spire tip 24.5 m. LoD2 was not readable in this run.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "design_museum_helsinki", "name": "Design Museum, Helsinki", "lat": 60.163087, "lon": 24.946615,
	"radius_m": 1500.0, "wiki_title": "Design Museum (Helsinki)", "height_m": 24.5, "clear_m": 26.0,
	"yaw_deg": 86.3, "kind": "Museum", "aliases": ["design museum, helsinki", "designmuseo", "designmuseet"]}

const X0 := -20.9
const X1 := 20.8
const ZF := 12.7
const ZB := -10.2
const PX0 := -11.7
const PX1 := 10.2
const PLINTH := 2.5
const BAND := 6.3
const CORNICE := 12.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E3B2D", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#D6C9A8", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE6D2", 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#8A8E94", 0.5, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#2E383E"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3624", 1.5))
	_body(lm)
	_windows(lm)
	_pavilion(lm)
	lm.commit(model)

## Plinth, brick body, string course, cornice and the plain roofs.
static func _body(lm: LandmarkMesh) -> void:
	var cx := (X0 + X1) * 0.5
	var cz := (ZB + ZF) * 0.5
	var w := X1 - X0
	var d := ZF - ZB
	U.blk(lm, "Stone", cx, 0.0, cz, w + 0.3, PLINTH, d + 0.3)
	U.blk(lm, "Brick", cx, PLINTH, cz, w, CORNICE - PLINTH, d)
	# Rear and side projections of the central pavilion.
	U.blk(lm, "Stone", (PX0 + PX1) * 0.5, 0.0, 0.0, PX1 - PX0 + 0.3, PLINTH, 27.3)
	U.blk(lm, "Brick", (PX0 + PX1) * 0.5, PLINTH, 0.0, PX1 - PX0, CORNICE - PLINTH, 27.0)
	U.blk(lm, "Trim", cx, BAND, cz, w + 0.5, 0.55, d + 0.5)
	U.blk(lm, "Trim", cx, CORNICE - 0.8, cz, w + 0.7, 0.8, d + 0.7)
	# Dentils under the cornice, front and back.
	for s: float in [-1.0, 1.0]:
		var z := ZF + 0.35 if s > 0.0 else ZB - 0.35
		var n := int(w / 0.5)
		for k in n:
			lm.box("Trim", Vector3(X0 + (float(k) + 0.5) * w / float(n), CORNICE - 1.0, z), Vector3(0.22, 0.25, 0.2))
	# Low hipped zinc roof over the wings, a taller one over the pavilion.
	U.hip(lm, "Roof", Vector3(cx, CORNICE, cz), w + 1.4, d + 1.4, 2.0, 0.45)
	U.blk(lm, "Brick", (PX0 + PX1) * 0.5, CORNICE, 0.0, PX1 - PX0, 2.2, 25.0)
	U.hip(lm, "Roof", Vector3((PX0 + PX1) * 0.5, CORNICE + 2.2, 0.0), PX1 - PX0 + 1.0, 26.0, 2.2, 0.12)
	# Chimney stacks on the roof.
	for p in [[-14.0, -5.0], [14.0, -5.0], [-3.0, -8.0], [6.0, -8.0]]:
		U.blk(lm, "Brick", p[0], CORNICE + 1.2, p[1], 1.3, 3.2, 1.3)

## Framed windows: first floor rectangular, second round-headed, basement
## arches, the arched entrance with its stone surround and steps.
static func _windows(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var zf := ZF
	for run in [[-19.6, -12.9], [12.6, 19.6]]:
		var a := Vector3(run[0], 0, zf)
		var b := Vector3(run[1], 0, zf)
		P.win_row(lm, "Trim", "Glass", a, b, out, 3.1, 3, 1.5, 2.4, false, 0.25)
		P.win_row(lm, "Trim", "Glass", a, b, out, 7.5, 3, 1.5, 2.9, true, 0.25)
		for k in 6:
			var x: float = float(run[0]) + (float(run[1]) - float(run[0])) * (float(k) + 0.5) / 6.0
			lm.box("Trim", Vector3(x, 8.6, zf + 0.15), Vector3(0.6, 0.35, 0.3))
	# Central pavilion, 3 + door + 3 bays.
	var pz := 13.5
	P.win_row(lm, "Trim", "Glass", Vector3(-10.4, 0, pz), Vector3(-4.2, 0, pz), out, 3.1, 2, 1.5, 2.4, false, 0.25)
	P.win_row(lm, "Trim", "Glass", Vector3(2.6, 0, pz), Vector3(8.8, 0, pz), out, 3.1, 2, 1.5, 2.4, false, 0.25)
	P.win_row(lm, "Trim", "Glass", Vector3(-10.0, 0, pz), Vector3(-6.0, 0, pz), out, 7.5, 1, 1.6, 3.0, true, 0.25)
	P.win_row(lm, "Trim", "Glass", Vector3(4.6, 0, pz), Vector3(8.6, 0, pz), out, 7.5, 1, 1.6, 3.0, true, 0.25)
	P.win_row(lm, "Trim", "Glass", Vector3(-6.0, 0, pz), Vector3(5.0, 0, pz), out, 7.5, 3, 1.6, 3.0, true, 0.25)
	# Basement arches along the plinth.
	for x in range(-19, 21, 3):
		if x > -5 and x < 5:
			continue
		P.win_row(lm, "Trim", "Glass", Vector3(float(x), 0, zf), Vector3(float(x), 0, zf), out, 0.7, 1, 0.9, 1.3, true, 0.15)
	# Entrance: stone surround, arched door with fanlight, steps.
	var ez := pz + 0.1
	U.blk(lm, "Trim", -0.7, 0.0, ez, 4.2, 5.2, 0.5)
	U.opening(lm, "Door", Vector3(-0.7, 0.6, ez + 0.3), out, 2.2, 4.2, true)
	lm.box("Trim", Vector3(-0.7, 5.3, ez + 0.1), Vector3(4.6, 0.35, 0.7))
	U.steps(lm, "Stone", Vector3(-0.7, 0, ez + 0.4), Vector3.BACK, 3.6, 0.4, 0.16, 3)
	# Rear and end windows in the same rhythm.
	P.win_row(lm, "Trim", "Glass", Vector3(-19.5, 0, ZB), Vector3(19.5, 0, ZB), Vector3(0, 0, -1), 3.1, 13, 1.5, 2.4, false, 0.2)
	P.win_row(lm, "Trim", "Glass", Vector3(-19.5, 0, ZB), Vector3(19.5, 0, ZB), Vector3(0, 0, -1), 7.5, 13, 1.5, 2.9, true, 0.2)
	for s: float in [-1.0, 1.0]:
		P.win_row(lm, "Trim", "Glass", Vector3(s * X1, 0, ZB + 2.0), Vector3(s * X1, 0, ZF - 2.0), Vector3(s, 0, 0), 3.1, 5, 1.5, 2.4, false, 0.2)
		P.win_row(lm, "Trim", "Glass", Vector3(s * X1, 0, ZB + 2.0), Vector3(s * X1, 0, ZF - 2.0), Vector3(s, 0, 0), 7.5, 5, 1.5, 2.9, true, 0.2)

## The five stepped gables with lancet pairs, the rose, the turrets and the
## central zinc spire.
static func _pavilion(lm: LandmarkMesh) -> void:
	var pz := 13.5
	var span := PX1 - PX0
	var gw := span / 5.0
	for k in 5:
		var x := PX0 + gw * (float(k) + 0.5)
		var raise := 0.7 if k == 2 else 0.0
		U.blk(lm, "Brick", x, CORNICE, pz - 0.5, gw - 0.1, 1.6 + raise, 1.0)
		U.ridge_z(lm, "Roof", "Brick", Vector3(x, CORNICE + 1.6 + raise, pz - 0.5), gw - 0.1, 1.0, 1.9 + raise * 0.5, 0.1)
		lm.box("Trim", Vector3(x, CORNICE + 3.0 + raise, pz + 0.05), Vector3(0.5, 0.5, 0.08))
		P.win_row(lm, "Trim", "Glass", Vector3(x - 0.5, 0, pz), Vector3(x + 0.5, 0, pz), Vector3(0, 0, 1), CORNICE + 0.6, 2, 0.6, 1.6, true, 0.15)
	P.ring(lm, "Trim", Vector3(PX0 + gw * 2.5, CORNICE + 2.95 + 0.7, pz + 0.1), Vector3(0, 0, 1), 0.3, 0.6, 0.1, 12)
	# Corner turrets, four of them, with zinc spires.
	for x: float in [PX0 - 0.3, PX1 + 0.3, PX0 + gw * 2.0, PX0 + gw * 3.0]:
		var big := x < PX0 or x > PX1
		var h := 3.4 if big else 1.8
		U.blk(lm, "Brick", x, CORNICE, pz - 0.6, 1.1, h, 1.1)
		lm.spire("Roof", Vector3(x, CORNICE + h, pz - 0.6), 0.6, 3.6 if big else 2.4, 0.0, 8)
		if big:
			U.blk(lm, "Brick", x, CORNICE, -pz + 0.6, 1.1, h, 1.1)
			lm.spire("Roof", Vector3(x, CORNICE + h, -pz + 0.6), 0.6, 3.6, 0.0, 8)
	# Central spire: octagonal, on the pavilion roof.
	var c := Vector3((PX0 + PX1) * 0.5, CORNICE + 4.4, 5.0)
	lm.frustum("Roof", c - Vector3(0, 0.3, 0), 1.9, 1.5, 1.0, 8, PI / 8.0)
	lm.spire("Roof", c + Vector3(0, 0.7, 0), 1.45, 7.2, 0.0, 8)
