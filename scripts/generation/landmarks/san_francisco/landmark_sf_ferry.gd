class_name LandmarkSfFerry
extends RefCounted

## San Francisco Ferry Building in true metres on LandmarkMesh, centred
## on the 201 m facade with y = 0 at the ground. Local +X runs along
## the facade (registry yaw 55 puts it on bearing 145), the Market
## Street front faces +Z (south-west) and the bay side -Z.

const HALF_L := 100.5
const WALL_HW := 14.0
const SKIN := 0.35
const GROUND_H := 8.2
const CORNICE_Y := 16.4
const BAY_M := 6.708
const BAYS := 12
const WING_X0 := 12.0
const END_X0 := 92.5
const TOWER_Z := 8.0
const TOWER_TOP_M := 75.0

## Ferry Building (1898, A. Page Brown): the 201 m Beaux-Arts front of
## Colusa sandstone, an arcade of round arches under two floors of
## arched windows between pilasters, the dentilled cornice, end
## pavilions and low tiled roofs, and the 75 m tower after the Giralda
## of Seville: a plain base with its three entrance arches, the shaft of
## paired arched windows, the clock stage with four 6.7 m dials, the
## open belfry, the balustraded cornice and the tiled pyramid with its
## lantern. Behind it the bay-side wall and the ferry apron.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B3A1", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D0CAB8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F3B42"))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8A5242", 3.0))
	lm.use("Metal", LandmarkMaterials.paint("#58796B", 0.5, 0.6))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#8D8A84", 3.0))
	lm.use("Dial", LandmarkMaterials.paint("#F2EEE2", 0.5, 0.1))
	_body(lm)
	_front(lm)
	_roofs(lm)
	_rear(lm)
	LandmarkSfFerryTower.tower(lm)
	lm.commit(model)

## Mass of the wings and apron slabs.
static func _body(lm: LandmarkMesh) -> void:
	var hw := WALL_HW - SKIN
	lm.box("Stone", Vector3(0, (CORNICE_Y + 1.0) * 0.5, 0), Vector3(HALF_L * 2.0 - 0.8, CORNICE_Y + 1.0, hw * 2.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var x: float = s * (END_X0 + HALF_L) * 0.5
		lm.box("Stone", Vector3(x, 19.6 * 0.5, 0.55), Vector3(HALF_L - END_X0, 19.6, WALL_HW * 2.0 + 1.1), Basis(), 0.0)
	lm.box("Pave", Vector3(0, 0.15, 24.0), Vector3(HALF_L * 2.0 + 10.0, 0.3, 20.0), Basis(), 0.0)
	lm.box("Pave", Vector3(0, 0.15, -25.0), Vector3(HALF_L * 2.0 + 10.0, 0.3, 22.0), Basis(), 0.0)

## Front (+Z): plinth, pilasters, the arcade, the arched upper windows,
## string course, cornice, and the end pavilions.
static func _front(lm: LandmarkMesh) -> void:
	var zf := WALL_HW
	lm.box("Trim", Vector3(0, 0.55, zf + 0.15), Vector3(HALF_L * 2.0, 1.1, 0.5), Basis(), 0.0)
	lm.box("Trim", Vector3(0, GROUND_H, zf + 0.2), Vector3(HALF_L * 2.0, 0.6, 0.55), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		for i in BAYS:
			var x: float = s * (WING_X0 + BAY_M * (float(i) + 0.5))
			_bay(lm, x, zf)
		for i in BAYS + 1:
			var px: float = s * (WING_X0 + BAY_M * float(i))
			lm.box("Trim", Vector3(px, CORNICE_Y * 0.5, zf + 0.2), Vector3(0.8, CORNICE_Y, 0.5), Basis(), 0.0)
		# End pavilion: raised, with a single wide arch and window.
		var ex: float = s * (END_X0 + HALF_L) * 0.5
		var pz := WALL_HW + 1.1
		_bay(lm, ex, pz, 1.3)
		lm.box("Trim", Vector3(s * END_X0, 19.2 * 0.5, pz + 0.1), Vector3(0.9, 19.2, 0.6), Basis(), 0.0)
		lm.box("Trim", Vector3(s * (HALF_L - 0.2), 19.2 * 0.5, pz + 0.1), Vector3(0.9, 19.2, 0.6), Basis(), 0.0)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * END_X0 - s * 0.45, 19.2, pz), Vector3(s * (HALF_L - 0.2) + s * 0.45, 19.2, pz),
			Vector3.BACK, 1.5, true)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-END_X0 - 0.45, CORNICE_Y, zf), Vector3(END_X0 + 0.45, CORNICE_Y, zf),
		Vector3.BACK, 1.4, true)

## One bay at x on the wall plane z: arched ground-floor opening and
## the arched window of the floor above; `k` widens the openings.
static func _bay(lm: LandmarkMesh, x: float, z: float, k: float = 1.0) -> void:
	var span := 3.8 * k
	var spring := 4.2
	lm.box("Glass", Vector3(x, spring * 0.5 + 0.55, z + 0.03), Vector3(span, spring - 1.1, 0.06), Basis(), 0.0)
	var c := Vector3(x, spring, z + 0.03)
	for i in 8:
		var t0 := PI * float(i) / 8.0
		var t1 := PI * float(i + 1) / 8.0
		lm.tri("Glass", c, c + Vector3(cos(t0), sin(t0), 0) * span * 0.5, c + Vector3(cos(t1), sin(t1), 0) * span * 0.5,
			Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2.ZERO, Vector2(cos(t0), sin(t0)) * span * 0.5,
			Vector2(cos(t1), sin(t1)) * span * 0.5)
	LandmarkDetail.arch(lm, "Trim", Vector3(x, spring, z + 0.02), Vector3.BACK, span, 0.36, 0.3, 12)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 12.3, z), Vector3.BACK, 2.1 * k, 4.2, true, 0.25)

## Low tiled roofs: a long gable on each wing and a hip over each pavilion.
static func _roofs(lm: LandmarkMesh) -> void:
	var along_x := Basis(Vector3.UP, PI * 0.5)
	for s in [-1.0, 1.0]:
		var len := END_X0 - WING_X0 + 0.6
		lm.gable("Roof", Vector3(s * (END_X0 + WING_X0) * 0.5, CORNICE_Y + 1.0, 0), WALL_HW * 2.0 - 0.6, len, 5.4,
			along_x, 0.9, "Stone")
		var ex: float = s * (END_X0 + HALF_L) * 0.5
		LandmarkNaParts.hip(lm, "Roof", Vector3(ex, 19.6, 0.55), Basis(), (HALF_L - END_X0) * 0.5 + 0.7,
			WALL_HW + 1.7, 0.45, 5.0)
	# The great nave: a raised gabled hall behind the tower.
	lm.box("Stone", Vector3(0, CORNICE_Y + 2.4, -3.0), Vector3(40.0, 4.8, 15.0), Basis(), 0.0)
	lm.gable("Roof", Vector3(0, CORNICE_Y + 4.8, -3.0), 16.0, 41.0, 5.0, along_x, 0.8, "Stone")

## Bay side (-Z): the plain wall with two floors of window openings, a
## cornice and the ferry-gate canopy along the apron.
static func _rear(lm: LandmarkMesh) -> void:
	var zb := -WALL_HW
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(HALF_L - 0.4, 0, zb + SKIN), Vector3.LEFT,
		Vector3.FORWARD, HALF_L * 2.0 - 0.8, CORNICE_Y, 31, 2, Vector2(2.4, 4.0), 2.2, GROUND_H, SKIN)
	LandmarkDetail.cornice(lm, "Trim", Vector3(HALF_L - 0.4, CORNICE_Y, zb), Vector3(-HALF_L + 0.4, CORNICE_Y, zb),
		Vector3.FORWARD, 1.2, false)
	# Canopy over the ferry gates: a low steel-and-glass roof on posts.
	var cz := zb - 8.0
	lm.box("Metal", Vector3(0, 6.6, cz), Vector3(HALF_L * 1.5, 0.35, 15.0), Basis(), 0.0)
	lm.box("Glass", Vector3(0, 6.9, cz), Vector3(HALF_L * 1.5 - 1.0, 0.1, 14.0), Basis(), 0.0)
	var posts := 24
	for i in posts + 1:
		var x := -HALF_L * 0.75 + HALF_L * 1.5 * float(i) / float(posts)
		lm.box("Metal", Vector3(x, 3.3, cz - 7.0), Vector3(0.35, 6.6, 0.35), Basis(), 0.0)
