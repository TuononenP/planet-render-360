class_name LandmarkAeTall
extends RefCounted

## Tall landmarks of Japan and Korea in true metres: Tokyo Skytree
## (634 m: a steel-pipe tripod that turns from a triangle into a circle,
## two observation decks and the gain tower), N Seoul Tower (236.7 m:
## concrete shaft, glazed pod and antenna) and Lotte World Tower (555 m:
## a rounded-square glass tower tapering like a brush, mega-truss belts).

# --- Tokyo Skytree ---

const SKYTREE_M := 634.0
const TRIPOD_M := 300.0

static func skytree(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.paint("#D3DDE6", 0.45, 0.4))
	lm.use("Deck", LandmarkMaterials.glass("#8CA3B3"))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C8C5BC", 4.0))
	# Three legs closing from a 39 m circumradius to the 14 m ring, braced
	# on every face of the triangle.
	var steps := 12
	for k in steps:
		var y0 := TRIPOD_M * k / steps
		var y1 := TRIPOD_M * (k + 1) / steps
		var ra := 3.2 - 1.4 * y0 / TRIPOD_M
		var rb := 3.2 - 1.4 * y1 / TRIPOD_M
		for i in 3:
			var j := (i + 1) % 3
			LandmarkAeParts.tube(lm, "Frame", _leg(i, y0), _leg(i, y1), ra, rb, 8)
			lm.lattice_panel("Frame", _leg(i, y0), _leg(j, y0), _leg(i, y1), _leg(j, y1), 1.0, 1)
	# Round shaft above the tripod, the Tembo Deck, the upper shaft, the
	# Galleria and the gain tower.
	lm.frustum("Frame", Vector3(0, TRIPOD_M, 0), 14.0, 15.0, 42.0, 18)
	lm.lathe("Deck", Vector3(0, 340.0, 0), PackedVector2Array([Vector2(15.0, 0), Vector2(23.0, 3.0),
		Vector2(24.0, 8.0), Vector2(24.0, 14.0), Vector2(17.0, 19.0), Vector2(11.0, 20.0)]), 24)
	lm.frustum("Frame", Vector3(0, 360.0, 0), 11.0, 8.0, 85.0, 16)
	lm.lathe("Deck", Vector3(0, 443.0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(13.0, 3.0),
		Vector2(13.0, 8.0), Vector2(8.0, 12.0)]), 20)
	lm.frustum("Frame", Vector3(0, 455.0, 0), 7.0, 5.0, 42.0, 14)
	lm.lathe("Frame", Vector3(0, 497.0, 0), PackedVector2Array([Vector2(4.5, 0), Vector2(3.5, 50.0),
		Vector2(2.0, 90.0), Vector2(0.35, SKYTREE_M - 497.0)]), 12)
	var tri := PackedVector2Array()
	for i in 3:
		var a := TAU * i / 3.0 + PI * 0.5
		tri.append(Vector2(cos(a), sin(a)) * 60.0)
	lm.poly_prism("Podium", tri, -3.0, 9.0)
	lm.commit(model)

## Leg i of the tripod at height y: 39 m radius at the ground, 14 m at 300 m.
static func _leg(i: int, y: float) -> Vector3:
	var r := 14.0 + 25.0 * pow(1.0 - y / TRIPOD_M, 1.6)
	var a := TAU * i / 3.0 + PI * 0.5
	return Vector3(r * cos(a), y, r * sin(a))

# --- N Seoul Tower ---

const SEOUL_M := 236.7

static func n_seoul(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#D8D5CE", 4.0))
	lm.use("Pod", LandmarkMaterials.glass("#74899A"))
	lm.use("Mast", LandmarkMaterials.paint("#E6E6E2", 0.4, 0.5))
	lm.frustum("Shaft", Vector3(0, -2.0, 0), 14.0, 12.0, 8.0, 12, PI / 12.0)
	lm.frustum("Shaft", Vector3(0, 0, 0), 6.2, 4.4, 100.0, 20)
	# Observation pod: lower rim, glazed drum, crown.
	lm.lathe("Pod", Vector3(0, 95.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(10.5, 3.0),
		Vector2(17.5, 8.0), Vector2(17.5, 17.0), Vector2(15.0, 23.0), Vector2(9.0, 27.0),
		Vector2(4.0, 30.0)]), 28)
	lm.frustum("Shaft", Vector3(0, 125.0, 0), 4.0, 3.4, 15.0, 16)
	lm.lathe("Mast", Vector3(0, 140.0, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(2.2, 30.0),
		Vector2(1.2, 70.0), Vector2(0.3, SEOUL_M - 140.0)]), 12)
	lm.frustum("Mast", Vector3(0, 165.0, 0), 5.0, 5.0, 1.2, 16)
	lm.commit(model)

# --- Lotte World Tower ---

const LOTTE_M := 555.0
static var LOTTE_HW := PackedVector2Array([Vector2(0, 36.0), Vector2(0.1, 34.5),
	Vector2(0.3, 29.5), Vector2(0.5, 24.5), Vector2(0.75, 17.5), Vector2(0.9, 11.5),
	Vector2(0.97, 8.0), Vector2(1.0, 7.0)])

static func lotte(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#8FA5B2"))
	lm.use("Frame", LandmarkMaterials.paint("#B7BEC3", 0.35, 0.8))
	lm.use("Beacon", LandmarkMaterials.lit("#CFE3F2", 0.9))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CBC7BE", 4.0))
	var rings: Array = []
	var slices := 48
	for k in slices + 1:
		rings.append(_lotte_ring(float(k) / slices, 1.0))
	LandmarkAeParts.loft(lm, "Glass", rings)
	for f in [0.17, 0.34, 0.52, 0.7, 0.86]:
		LandmarkAeParts.loft(lm, "Frame", [_lotte_ring(f, 1.025), _lotte_ring(f + 5.0 / LOTTE_M, 1.025)], false)
	# Lit slits down the four faces of the crown.
	var hw := LandmarkMesh.profile_at(LOTTE_HW, 0.96)
	for s in [-1.0, 1.0]:
		lm.box("Beacon", Vector3(s * hw, 536.0, 0), Vector3(1.4, 38.0, 6.0))
		lm.box("Beacon", Vector3(0, 536.0, s * hw), Vector3(6.0, 38.0, 1.4))
	lm.box("Podium", Vector3(0, 6.0, 0), Vector3(96.0, 14.0, 96.0))
	lm.commit(model)

## Rounded-square (superellipse) section at height fraction f.
static func _lotte_ring(f: float, grow: float) -> PackedVector3Array:
	var hw := LandmarkMesh.profile_at(LOTTE_HW, f) * grow
	var shape: Callable = func(th: float) -> float:
		return hw / pow(pow(absf(cos(th)), 3.5) + pow(absf(sin(th)), 3.5), 1.0 / 3.5)
	return LandmarkAeParts.ring(40, LOTTE_M * f, shape)
