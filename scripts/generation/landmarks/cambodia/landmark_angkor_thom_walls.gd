class_name LandmarkAngkorThomWalls
extends RefCounted

## The walled city of Angkor Thom round the Bayon, in true metres, +X east,
## +Z south, origin at the square's centre: the 8 m laterite wall (3.1 x
## 3.0 km, positions from the mapped citywalls) backed by its earth rampart,
## the Prasat Chrung shrines at its four corners, and the face-tower gates
## with their causeways over the moat: north, west, the Gate of the Dead
## (east, on the Bayon's axis) and the Victory Gate (east, on the Royal
## Palace's). The South Gate is its own model (LandmarkKhAngkor.south_gate),
## so the wall leaves its 144 m there. The moat is the map's water.

const KA = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_angkor.gd")
const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const LT = preload("res://scripts/generation/landmarks/asia_south/landmark_sea_temples.gd")

## Wall lines: west, east (x) and north, south (z).
const WEST := -1559.1
const EAST := 1559.1
const NORTH := -1525.5
const SOUTH := 1508.9
## Gate centres along their walls, and how far the wall stops either side
## (the gate model carries its own 72 m of wall).
const SOUTH_GATE_X := 55.2
const NORTH_GATE_X := 4.3
const WEST_GATE_Z := 23.2
const DEAD_GATE_Z := -33.2
const VICTORY_GATE_Z := -597.0
const GATE_HALF := 72.0
## Figures a side on the ruined causeways.
const RUINED_FIGURES := 12
const WALL_H := 8.0
const WALL_T := 7.0
## Earth rampart inside the wall: its top width and its slope's reach.
const RAMPART_H := 6.0
const RAMPART_TOP := 8.0
const RAMPART_RUN := 18.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	KA.gate_kit(lm)
	lm.use("Sand", LandmarkMaterials.pbr("stone", LandmarkAngParts.STONE_GREY, 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", LandmarkAngParts.ROOF, 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E3A33", 2.0))
	lm.use("Bank", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))
	# North and south faces (x runs), west and east faces (z runs), each
	# broken at its gates.
	_side(lm, true, NORTH, [NORTH_GATE_X], Vector3(0, 0, 1))
	_side(lm, true, SOUTH, [SOUTH_GATE_X], Vector3(0, 0, -1))
	_side(lm, false, WEST, [WEST_GATE_Z], Vector3(1, 0, 0))
	_side(lm, false, EAST, [VICTORY_GATE_Z, DEAD_GATE_Z], Vector3(-1, 0, 0))
	var gate := LandmarkMesh.new()
	KA.gate_kit(gate)
	KA.gate(gate, RUINED_FIGURES)
	# The gate faces +Z (out): turned so each looks out of the city.
	lm.merge(gate, Transform3D(Basis(Vector3.UP, PI), Vector3(NORTH_GATE_X, 0, NORTH)))
	lm.merge(gate, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(WEST, 0, WEST_GATE_Z)))
	lm.merge(gate, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(EAST, 0, DEAD_GATE_Z)))
	lm.merge(gate, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(EAST, 0, VICTORY_GATE_Z)))
	# Prasat Chrung: a small sandstone shrine inside each corner.
	for x in [WEST + 45.0, EAST - 45.0]:
		for z in [NORTH + 45.0, SOUTH - 45.0]:
			lm.box("Laterite", Vector3(x, 0.4, z), Vector3(16.0, 2.0, 16.0))
			LT._prang(lm, Vector3(x, 1.4, z), 3.4, 13.5)
	lm.commit(model)

## One face of the wall at `line` (z for an x run, x for a z run) from
## corner to corner, broken GATE_HALF either side of each gate centre,
## the rampart on the city side `inward`.
static func _side(lm: LandmarkMesh, along_x: bool, line: float, gates: Array, inward: Vector3) -> void:
	var lo := WEST if along_x else NORTH
	var hi := EAST if along_x else SOUTH
	var cuts: Array = gates.duplicate()
	cuts.sort()
	var start := lo
	for g in cuts:
		_run(lm, along_x, line, start, float(g) - GATE_HALF, inward)
		start = float(g) + GATE_HALF
	_run(lm, along_x, line, start, hi, inward)

static func _run(lm: LandmarkMesh, along_x: bool, line: float, a: float, b: float, inward: Vector3) -> void:
	if b - a < 1.0:
		return
	var pa := Vector3(a, 0, line) if along_x else Vector3(line, 0, a)
	var pb := Vector3(b, 0, line) if along_x else Vector3(line, 0, b)
	U.wall_run(lm, "Laterite", "Stone", pa, pb, WALL_H, WALL_T, 0.3)
	# Footing: the wall runs 3 m into the ground so no dip shows a gap.
	var d := pb - pa
	lm.box("Laterite", (pa + pb) * 0.5 + Vector3(0, -1.5, 0), Vector3(WALL_T, 3.0, d.length()),
		Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
	# Rampart: a flat top behind the wall, then the slope down to the city.
	var side := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var o0 := inward * (WALL_T * 0.5)
	var o1 := inward * (WALL_T * 0.5 + RAMPART_TOP)
	var o2 := inward * (WALL_T * 0.5 + RAMPART_TOP + RAMPART_RUN)
	var up := Vector3(0, RAMPART_H, 0)
	lm.quad("Bank", pa + o0 + up, pb + o0 + up, pb + o1 + up, pa + o1 + up, Vector3.UP)
	lm.quad("Bank", pa + o1 + up, pb + o1 + up, pb + o2 - Vector3(0, 0.5, 0), pa + o2 - Vector3(0, 0.5, 0),
		(Vector3.UP * RAMPART_RUN + inward * RAMPART_H).normalized())
	# Ends of the rampart at a gate or corner.
	for p in [pa, pb]:
		var q: Vector3 = p
		lm.quad("Bank", q + o0, q + o0 + up, q + o1 + up, q + o2 - Vector3(0, 0.5, 0),
			-side if q == pa else side)
