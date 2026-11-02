class_name LandmarkSaoAustralia
extends RefCounted

## Australian civic landmarks in true metres: Melbourne's Flinders Street
## Station and Parliament House on Canberra's Capitol Hill.

# --- Flinders Street Station ---

const FACADE_Z := 14.0
const EAVE_Y := 18.0
const DOME_X := -97.0
const ENTRY_X := -66.0

## The Edwardian terminus: ochre-rendered front along Flinders Street
## (facing +Z) with two rows of windows under a green roof, the domed
## corner tower at the Swanston Street end, the pedimented entrance arch
## with its row of clocks, and the train sheds behind.
static func flinders(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D8B46A", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8DCC0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#5E8D78", 3.0, 0.5, 0.2))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	lm.use("Clock", LandmarkMaterials.lit("#F4F0E0", 0.3))
	lm.box("Wall", Vector3(0, 9.0, 0), Vector3(220.0, 18.0, 28.0))
	lm.box("Trim", Vector3(0, 1.0, 0), Vector3(220.8, 2.0, 28.8))
	lm.box("Trim", Vector3(0, EAVE_Y + 0.6, 0), Vector3(221.0, 1.2, 29.0))
	lm.gable("Roof", Vector3(0, EAVE_Y + 1.2, 0), 28.0, 220.0, 3.5, Basis(Vector3.UP, PI * 0.5),
		0.4, "Wall")
	for k in 38:
		var x := -80.0 + 4.9 * float(k)
		if absf(x - ENTRY_X) < 17.0:
			continue
		lm.box("Windows", Vector3(x, 6.5, FACADE_Z + 0.05), Vector3(2.2, 5.0, 0.2))
		lm.box("Windows", Vector3(x, 13.5, FACADE_Z + 0.05), Vector3(2.2, 3.6, 0.2))
		lm.box("Trim", Vector3(x, 10.0, FACADE_Z + 0.1), Vector3(2.8, 0.5, 0.3))
	_entrance(lm)
	_corner_dome(lm)
	# Train sheds: three gabled bays behind the front block.
	lm.box("Wall", Vector3(0, 4.0, -62.0), Vector3(190.0, 8.0, 96.0))
	for x in [-63.0, 0.0, 63.0]:
		lm.gable("Roof", Vector3(x, 8.0, -62.0), 62.0, 96.0, 6.0, Basis(), 0.3, "Wall")
	lm.commit(model)

## Projecting arched entrance pavilion with pediment and clock row.
static func _entrance(lm: LandmarkMesh) -> void:
	var c := Vector3(ENTRY_X, 0, FACADE_Z + 3.0)
	lm.box("Wall", c + Vector3(0, 13.0, 0), Vector3(28.0, 26.0, 6.0))
	lm.box("Windows", c + Vector3(0, 8.0, 3.05), Vector3(12.0, 14.0, 0.2))
	lm.box("Trim", c + Vector3(0, 16.2, 3.1), Vector3(14.0, 1.0, 0.3))
	lm.gable("Trim", c + Vector3(0, 26.0, 0), 28.0, 6.0, 3.6, Basis(), 0.3, "Trim")
	for k in 9:
		lm.disc("Clock", c + Vector3(-11.2 + 2.8 * float(k), 20.5, 3.12), Vector3.BACK, 1.0, 14)

## The domed corner tower: block, octagonal drum, copper dome, lantern.
static func _corner_dome(lm: LandmarkMesh) -> void:
	var b := Vector3(DOME_X, 0, 0)
	lm.box("Wall", b + Vector3(0, 12.0, 0), Vector3(26.0, 24.0, 28.0))
	lm.box("Trim", b + Vector3(0, 24.4, 0), Vector3(27.0, 1.0, 29.0))
	for y in [7.0, 15.0]:
		lm.box("Windows", b + Vector3(0, y, FACADE_Z + 0.05), Vector3(3.0, 5.0, 0.2))
	lm.frustum("Trim", b + Vector3(0, 24.9, 0), 8.0, 8.0, 5.1, 8, PI / 8.0)
	var prof := PackedVector2Array()
	for i in 8:
		var a := PI * 0.5 * float(i) / 7.0
		prof.append(Vector2(7.6 * cos(a), 7.0 * sin(a)))
	lm.lathe("Roof", b + Vector3(0, 30.0, 0), prof, 24)
	lm.frustum("Trim", b + Vector3(0, 37.0, 0), 1.5, 1.1, 2.0, 10)
	lm.spire("Trim", b + Vector3(0, 39.0, 0), 0.6, 1.0, 0.0, 8)

# --- Parliament House, Canberra ---

const CAPITOL_Y := 26.0
const MAST_H := 81.0

## Capitol Hill, built facing -Z (the registry yaw turns it up the land
## axis): the stone drum capped by the grass-covered hill, the marble
## foyer with its colonnade and glazed front, the steel quadripod and
## the 81 m flag mast. The two curved wings are merged into one
## elliptical mound.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#BFB4A2", 4.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 5.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DED0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Steel", LandmarkMaterials.paint("#C8CBCE", 0.4, 0.6))
	lm.use("Flag", LandmarkMaterials.paint("#1E2F6A", 0.6, 0.0))
	lm.frustum("Stone", Vector3(0, -2.0, 0), 100.0, 100.0, 16.0, 40, 0.0, 1.3, 0.95)
	lm.lathe("Lawn", Vector3.ZERO, PackedVector2Array([Vector2(100.0, 14.0), Vector2(70.0, 19.0),
		Vector2(36.0, CAPITOL_Y)]), 40, 1.3, 0.95)
	_foyer(lm)
	_flag_mast(lm)
	lm.commit(model)

## Marble foyer pavilion in front of the drum with its glazed wall and
## a colonnade of fourteen columns.
static func _foyer(lm: LandmarkMesh) -> void:
	lm.box("Marble", Vector3(0, 7.0, -100.0), Vector3(64.0, 14.0, 30.0))
	lm.box("Glass", Vector3(0, 6.0, -115.05), Vector3(58.0, 10.0, 0.2))
	lm.box("Marble", Vector3(0, 15.0, -104.0), Vector3(66.0, 2.0, 40.0))
	for k in 14:
		lm.frustum("Marble", Vector3(-26.0 + 4.0 * float(k), 0.0, -118.0), 0.8, 0.7, 14.0, 12)

## Steel quadripod rising from the hill and the stainless mast above it.
static func _flag_mast(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(sx * 24.0, CAPITOL_Y, sz * 24.0), Vector3(sx * 1.5, 60.0, sz * 1.5), 2.2, 2.2)
	lm.frustum("Steel", Vector3(0, 60.0, 0), 1.1, 0.2, MAST_H - 60.0, 10)
	lm.quad("Flag", Vector3(0.3, 74.0, 0), Vector3(13.1, 74.0, 0), Vector3(13.1, 80.4, 0),
		Vector3(0.3, 80.4, 0), Vector3.BACK)
	lm.quad("Flag", Vector3(0.3, 80.4, 0), Vector3(13.1, 80.4, 0), Vector3(13.1, 74.0, 0),
		Vector3(0.3, 74.0, 0), Vector3.FORWARD)
