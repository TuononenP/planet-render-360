extends RefCounted

## Sederholm House (Sederholmin talo, 1757), the oldest stone building in
## the centre, Aleksanterinkatu 16. Model origin at the centre of the OSM
## outline (way 38101163, 18.4 x 11.8 m), front +Z; registry yaw 178 turns
## the front north onto the street.
##
## From the photos (visual-plan/refs/landmarks/sederholm_house/): two
## storeys of pale blue-grey render with white corner quoins and string
## courses, five window bays, the door in the second bay, a wrought-iron
## balcony rail on every first-floor window, a white cornice, a black
## double-pitched (gambrel) roof with two dormers and a central triangular
## pediment holding the coat of arms, and chimneys at the back. Roof to 11 m.
##
## Measured: footprint, bearing (OSM); 11 m top (published storeys and the
## photos). Counted: five bays, two storeys, two dormers. Estimated: storey
## heights, roof breaks, render hue (sampled by eye from the photos).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "sederholm_house", "name": "Sederholm House", "lat": 60.168968, "lon": 24.953807,
	"radius_m": 1500.0, "wiki_title": "Sederholm House", "height_m": 11.0, "clear_m": 10.0,
	"clear_offsets_m": [[0.0, 0.0]],
	"yaw_deg": 178.0, "kind": "House", "aliases": ["sederholm house", "sederholmin talo", "sederholmska huset"]}

const HW := 9.2
const HD := 5.9
const PLINTH := 0.6
const F1 := 3.8
const EAVE := 7.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#A3ACBD", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE9DD", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7F80", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#1F2124", 0.75, 0.05))
	lm.use("Glass", LandmarkMaterials.glass("#2B3237"))
	lm.use("Iron", LandmarkMaterials.paint("#222426", 0.5, 0.5))
	lm.use("Door", LandmarkMaterials.paint("#56635F", 0.6))
	lm.use("Arms", LandmarkMaterials.gold())
	U.blk(lm, "Stone", 0.0, 0.0, 0.0, HW * 2.0 + 0.3, PLINTH, HD * 2.0 + 0.3)
	U.blk(lm, "Wall", 0.0, PLINTH, 0.0, HW * 2.0, EAVE - PLINTH, HD * 2.0)
	_front(lm)
	_sides(lm)
	_roof(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.64)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-7.0, 1.5, 17.0), Vector3(-3.0, 5.5, 5.9), 44.0, 0.9, 32.0, warm],
		[Vector3(7.0, 1.5, 17.0), Vector3(3.0, 5.5, 5.9), 44.0, 0.9, 32.0, warm],
		[Vector3(20.0, 1.5, -10.0), Vector3(8.0, 5.0, -2.0), 44.0, 0.75, 34.0, warm],
	])

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var a := Vector3(-HW + 1.5, 0, HD)
	var b := Vector3(HW - 1.5, 0, HD)
	E.row(lm, "Trim", "Glass", a, b, out, 1.1, 5, 1.2, 2.2, "rect", [1])
	E.row(lm, "Trim", "Glass", a, b, out, 4.6, 5, 1.2, 2.2, "rect")
	# The door in the second bay.
	var dx := lerpf(a.x, b.x, 1.5 / 5.0)
	U.blk(lm, "Trim", dx, PLINTH, HD + 0.1, 2.0, 3.0, 0.2)
	U.blk(lm, "Door", dx, PLINTH, HD + 0.22, 1.4, 2.4, 0.06)
	# Iron balcony rails across the first-floor windows.
	for i in 5:
		var x := lerpf(a.x, b.x, (float(i) + 0.5) / 5.0)
		lm.box("Iron", Vector3(x, 4.6 + 0.95, HD + 0.28), Vector3(1.8, 0.06, 0.06), Basis(), 0.0)
		lm.box("Iron", Vector3(x, 4.6 + 0.3, HD + 0.28), Vector3(1.8, 0.05, 0.05), Basis(), 0.0)
		for k in 5:
			lm.box("Iron", Vector3(x - 0.8 + 0.4 * float(k), 4.6 + 0.62, HD + 0.28), Vector3(0.03, 0.7, 0.03), Basis(), 0.0)
	var a2 := Vector2(-HW, HD)
	var b2 := Vector2(HW, HD)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F1 - 0.2, 0.3, 0.1)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), PLINTH - 0.05, 0.25, 0.12)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-HW, EAVE - 0.7, HD), Vector3(HW, EAVE - 0.7, HD), out, 0.9, false)
	# White corner quoins on the whole height.
	for s in [-1.0, 1.0]:
		for k in 6:
			var y := PLINTH + 0.1 + float(k) * 1.1
			U.blk(lm, "Trim", s * (HW - 0.4), y, HD + 0.03, 0.8, 0.55, 0.12)
			U.blk(lm, "Trim", s * (HW + 0.03), y, HD - 0.4, 0.12, 0.55, 0.8)

static func _sides(lm: LandmarkMesh) -> void:
	var rows := [[1.1, 1.1, 2.0, "plain"], [4.6, 1.1, 2.0, "plain"]]
	E.run(lm, "Trim", "Glass", Vector2(HW, -HD), Vector2(-HW, -HD), Vector2(0, -1), 3.4, rows, 1.5)
	E.run(lm, "Trim", "Glass", Vector2(HW, -HD), Vector2(HW, HD), Vector2(1, 0), 3.5, rows, 1.4)
	E.run(lm, "Trim", "Glass", Vector2(-HW, -HD), Vector2(-HW, HD), Vector2(-1, 0), 3.5, rows, 1.4)

static func _roof(lm: LandmarkMesh) -> void:
	# Gambrel: a steep lower pitch, a shallow upper one, both black.
	var w := HW * 2.0 + 0.6
	var d := HD * 2.0 + 0.6
	U.hip(lm, "Roof", Vector3(0, EAVE, 0), w, d, 2.5, 0.78)
	U.hip(lm, "Roof", Vector3(0, EAVE + 2.5, 0), w * 0.78, d * 0.78, 1.3, 0.3)
	# Central pediment with the coat of arms.
	lm.gable("Trim", Vector3(0, EAVE - 0.3, HD - 0.5), 8.4, 1.4, 2.5, Basis(), 0.0, "Wall")
	lm.disc("Arms", Vector3(0, EAVE + 0.75, HD + 0.24), Vector3(0, 0, 1), 0.45, 14)
	# Two dormers on the front slope.
	for s in [-1.0, 1.0]:
		var x: float = s * 6.6
		U.blk(lm, "Roof", x, EAVE + 0.5, HD - 1.5, 1.5, 1.7, 1.2)
		lm.gable("Roof", Vector3(x, EAVE + 2.2, HD - 1.5), 1.5, 1.2, 0.7, Basis(), 0.1, "Roof")
		lm.quad("Glass", Vector3(x - 0.5, EAVE + 0.8, HD - 0.88), Vector3(x + 0.5, EAVE + 0.8, HD - 0.88),
			Vector3(x + 0.5, EAVE + 2.0, HD - 0.88), Vector3(x - 0.5, EAVE + 2.0, HD - 0.88), Vector3(0, 0, 1))
	# Chimneys on the back slope.
	for x in [-5.5, 5.0]:
		U.blk(lm, "Wall", x, EAVE + 1.8, -2.0, 0.9, 3.0, 0.9)
		U.blk(lm, "Trim", x, EAVE + 4.7, -2.0, 1.15, 0.2, 1.15)
