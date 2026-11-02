class_name LandmarkMaMosques
extends RefCounted

## Four great mosques in true metres: the Sheikh Zayed Grand Mosque
## (Abu Dhabi), the Hassan II Mosque (Casablanca), the mud-brick Great
## Mosque of Djenne (Mali) and the Dome of the Rock (Jerusalem).

# --- Sheikh Zayed Grand Mosque ---

## White marble complex: a courtyard (z -150..-10) ringed by domed
## arcades on three sides and four 107 m minarets at its corners, the
## prayer hall to the south (+Z) under the 85 m main dome with two
## flanking domes and a ring of smaller ones.
static func sheikh_zayed(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F1EEE6", 6.0))
	lm.use("Floor", LandmarkMaterials.pbr("pavement", "#E4DCCB", 5.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2A3A3C"))
	lm.box("Floor", Vector3(0, -1.0, -20), Vector3(270, 4, 300))
	_arcade(lm, Vector3(-60, 0, -80), Vector3(0, 0, 1), 140.0, Vector3(1, 0, 0))
	_arcade(lm, Vector3(60, 0, -80), Vector3(0, 0, 1), 140.0, Vector3(-1, 0, 0))
	_arcade(lm, Vector3(0, 0, -150), Vector3(1, 0, 0), 120.0, Vector3(0, 0, 1))
	# Prayer hall, its courtyard front of arched windows and roof domes.
	lm.box("Marble", Vector3(0, 11, 50), Vector3(160, 22, 120))
	for i in 9:
		lm.box("Glass", Vector3(-64.0 + 16.0 * i, 7, -10.1), Vector3(7, 10, 0.4))
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(cos(a) * 64.0, 22, 50.0 + sin(a) * 46.0)
		LandmarkMaParts.dome(lm, "Marble", p, 5.0, 6.5, 12)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 42.0, 14, 50), Vector3(24, 28, 40))
		LandmarkMaParts.dome(lm, "Marble", Vector3(s * 42.0, 28, 50), 11.0, 12.5, 16, 0.2)
		LandmarkMaParts.needle(lm, "Gold", Vector3(s * 42.0, 40.5, 50),
			PackedVector2Array([Vector2(0, 0.6), Vector2(4, 0.15)]), 8)
	# Main dome: block, drum and the 85 m dome with its gilded finial.
	lm.box("Marble", Vector3(0, 22.5, 50), Vector3(56, 45, 60))
	lm.frustum("Marble", Vector3(0, 45, 50), 19.0, 19.0, 10.0, 32)
	LandmarkMaParts.dome(lm, "Marble", Vector3(0, 55, 50), 19.8, 25.0, 32, 0.25)
	LandmarkMaParts.needle(lm, "Gold", Vector3(0, 80, 50),
		PackedVector2Array([Vector2(0, 1.4), Vector2(2.5, 0.9), Vector2(5, 0.12)]), 10)
	for sx in [-1.0, 1.0]:
		for z in [-152.0, -8.0]:
			_minaret(lm, Vector3(sx * 64.0, 0, z))
	lm.commit(model)
	model.rotation.y = deg_to_rad(50.0)

## Colonnade wall along `along` with a small dome per bay and a row of
## windows on its `inward` face.
static func _arcade(lm: LandmarkMesh, mid: Vector3, along: Vector3, length: float,
		inward: Vector3) -> void:
	var basis := Basis(Vector3.UP, atan2(along.x, along.z))
	lm.box("Marble", mid + Vector3(0, 6, 0), Vector3(7, 12, length), basis)
	var bays := roundi(length / 8.0)
	for i in bays:
		var p := mid + along * (-length * 0.5 + (float(i) + 0.5) * length / bays)
		LandmarkMaParts.dome(lm, "Marble", p + Vector3(0, 12, 0), 3.4, 4.4, 12)
		lm.box("Glass", p + Vector3(0, 5, 0) + inward * 3.55, Vector3(0.4, 7, 4.4), basis)

## 107 m minaret: square base, octagonal shaft, balcony, glazed lantern
## and a gilded cap.
static func _minaret(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Marble", base + Vector3(0, 9, 0), Vector3(9, 18, 9))
	lm.frustum("Marble", base + Vector3(0, 18, 0), 4.4, 3.8, 52.0, 8, PI / 8.0)
	lm.frustum("Marble", base + Vector3(0, 70, 0), 5.6, 5.6, 2.0, 8, PI / 8.0)
	lm.frustum("Marble", base + Vector3(0, 72, 0), 3.5, 3.0, 20.0, 8, PI / 8.0)
	lm.frustum("Glass", base + Vector3(0, 92, 0), 3.1, 3.1, 5.0, 8, PI / 8.0)
	lm.frustum("Gold", base + Vector3(0, 97, 0), 3.4, 3.4, 1.0, 8, PI / 8.0)
	LandmarkMaParts.dome(lm, "Gold", base + Vector3(0, 98, 0), 3.0, 9.0, 8, 0.8)
	for y in [30.0, 46.0, 58.0]:
		lm.frustum("Glass", base + Vector3(0, y, 0), 4.0, 4.0, 4.0, 8, PI / 8.0)

# --- Hassan II Mosque ---

## Casablanca: 200 x 100 m prayer hall under a green-tiled roof on a
## stone terrace, arched south colonnade, and the 210 m square minaret
## banded in zellige with a green pyramid cap and gilded finial.
static func hassan_ii(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E9E1CE", 6.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#2E6B52", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2B7A78", 3.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#D8CDB6", 5.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#1F2E2D"))
	lm.box("Plaza", Vector3(0, -2, 50), Vector3(290, 6, 300))
	lm.box("Stone", Vector3(0, 23, 0), Vector3(200, 46, 100))
	lm.box("Tile", Vector3(0, 41, 0), Vector3(200.8, 3, 100.8))
	lm.gable("Roof", Vector3(0, 46, 0), 100.0, 200.0, 9.0, Basis(Vector3.UP, PI * 0.5), 1.5, "Stone")
	for i in 16:
		lm.box("Glass", Vector3(-90.0 + 12.0 * i, 14, 50.1), Vector3(6.5, 18, 0.4))
	for i in 25:
		lm.frustum("Stone", Vector3(-96.0 + 8.0 * i, 0, 58.0), 1.2, 1.2, 16.0, 10)
	lm.box("Stone", Vector3(0, 17, 58), Vector3(200, 2, 3))
	_hassan_minaret(lm, Vector3(85, 0, -80))
	lm.commit(model)

static func _hassan_minaret(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Stone", base + Vector3(0, 10, 0), Vector3(30, 20, 30))
	lm.spire("Stone", base + Vector3(0, 20, 0), 12.5, 145.0, 11.3)
	for y in [45.0, 90.0, 130.0]:
		var hw: float = 12.5 - 1.2 * (y - 20.0) / 145.0
		lm.box("Tile", base + Vector3(0, y, 0), Vector3(hw * 2.0 + 0.8, 4, hw * 2.0 + 0.8))
		for s in [-1.0, 1.0]:
			lm.box("Glass", base + Vector3(s * (hw + 0.1), y + 14.0, 0), Vector3(0.4, 14, 7))
			lm.box("Glass", base + Vector3(0, y + 14.0, s * (hw + 0.1)), Vector3(7, 14, 0.4))
	lm.box("Stone", base + Vector3(0, 166, 0), Vector3(28, 2, 28))
	lm.box("Stone", base + Vector3(0, 176, 0), Vector3(15, 18, 15))
	lm.spire("Tile", base + Vector3(0, 185, 0), 9.5, 14.0)
	LandmarkMaParts.sphere(lm, "Gold", base + Vector3(0, 201, 0), 2.0, 12, 6)
	LandmarkMaParts.needle(lm, "Gold", base + Vector3(0, 203, 0),
		PackedVector2Array([Vector2(0, 0.6), Vector2(7, 0.1)]), 6)

# --- Great Mosque of Djenne ---

## Sudano-Sahelian mud-brick mosque on its 3 m plinth: prayer hall to
## the east (+X) behind a buttressed qibla wall with three tapering
## towers (tallest 20 m) crowned by ostrich eggs and pierced by toron
## beams, open courtyard to the west.
static func djenne(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Mud", LandmarkMaterials.pbr("render", "#A6865E", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9A8666", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4F35", 1.5))
	lm.use("Egg", LandmarkMaterials.pbr("render", "#E6DDC8", 1.0))
	lm.box("Plinth", Vector3(0, 1.5, 0), Vector3(84, 3, 84))
	lm.box("Mud", Vector3(21, 8, 0), Vector3(32, 10, 74))
	lm.box("Mud", Vector3(-36, 6.5, 0), Vector3(2, 7, 74))
	for s in [-1.0, 1.0]:
		lm.box("Mud", Vector3(-16, 6.5, s * 36.0), Vector3(42, 7, 2))
	# Pilasters topped by conical pinnacles round the walls.
	for i in 23:
		var z := -35.2 + 3.2 * i
		_pilaster(lm, Vector3(37.2, 0, z), 11.5)
		_pilaster(lm, Vector3(-37.2, 0, z), 8.0)
	for i in 10:
		var x := 8.0 + 3.2 * i
		_pilaster(lm, Vector3(x, 0, -37.2), 11.5)
		_pilaster(lm, Vector3(x, 0, 37.2), 11.5)
	for i in 10:
		var x := -33.0 + 4.0 * i
		_pilaster(lm, Vector3(x, 0, -37.2), 8.0)
		_pilaster(lm, Vector3(x, 0, 37.2), 8.0)
	for z in [-17.0, 0.0, 17.0]:
		_tower(lm, Vector3(35.0, 3, z), 20.0 if is_zero_approx(z) else 17.0)
	lm.commit(model)

static func _pilaster(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Mud", base + Vector3(0, 3.0 + h * 0.5, 0), Vector3(1.6, h, 1.6))
	lm.spire("Mud", base + Vector3(0, 3.0 + h, 0), 0.9, 1.8, 0.0)

## Tapering tower from y=3 to `top`: toron beams, a cap and the egg.
static func _tower(lm: LandmarkMesh, base: Vector3, top: float) -> void:
	var body := top - 3.0 - 2.2
	lm.spire("Mud", base, 3.8, body, 1.8)
	for y in [7.0, 11.0, top - 6.0]:
		var hw := lerpf(3.8, 1.8, (y - 3.0) / body) + 0.9
		for k in [-1.2, 0.0, 1.2]:
			lm.beam("Wood", Vector3(base.x + k, y, base.z - hw), Vector3(base.x + k, y, base.z + hw), 0.4)
			lm.beam("Wood", Vector3(base.x - hw, y, base.z + k), Vector3(base.x + hw, y, base.z + k), 0.4)
	lm.spire("Mud", base + Vector3(0, body, 0), 1.9, 1.0, 0.9)
	LandmarkMaParts.sphere(lm, "Egg", Vector3(base.x, top - 1.05, base.z), 0.7, 10, 6, 1.5)

# --- Dome of the Rock ---

## Octagonal shrine (26.9 m circumradius): marble lower wall, blue
## tiled upper wall, shallow lead roof, 16-sided tiled drum and the
## gilded 20 m dome with its finial; four gabled porches.
static func dome_of_rock(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DFD0", 5.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#2F76A6", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8D98A3", 5.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Platform", LandmarkMaterials.pbr("stone", "#CFC5AE", 6.0))
	lm.use("Door", LandmarkMaterials.glass("#1E2426"))
	var rr := 26.9
	lm.box("Platform", Vector3(0, -3, 0), Vector3(120, 6, 120))
	lm.frustum("Marble", Vector3.ZERO, rr, rr, 4.8, 8, PI / 8.0)
	lm.frustum("Tile", Vector3(0, 4.8, 0), rr, rr, 4.7, 8, PI / 8.0)
	lm.frustum("Marble", Vector3(0, 9.5, 0), rr + 0.5, rr + 0.5, 0.8, 8, PI / 8.0)
	lm.lathe("Lead", Vector3(0, 10.3, 0), PackedVector2Array([Vector2(rr, 0), Vector2(rr * 0.9, 0.6),
		Vector2(21.0, 3.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Tile", Vector3(0, 13.7, 0), 11.3, 11.3, 8.8, 16)
	lm.frustum("Marble", Vector3(0, 22.5, 0), 11.0, 11.0, 0.5, 16)
	LandmarkMaParts.dome(lm, "Gold", Vector3(0, 22.5, 0), 10.5, 10.5, 24, 0.15)
	LandmarkMaParts.sphere(lm, "Gold", Vector3(0, 33.2, 0), 0.8, 8, 4)
	LandmarkMaParts.needle(lm, "Gold", Vector3(0, 33.0, 0),
		PackedVector2Array([Vector2(0, 0.7), Vector2(1.2, 0.5), Vector2(2.3, 0.12)]), 6)
	var apothem := rr * cos(PI / 8.0)
	for k in 4:
		var d := Vector3(sin(PI * 0.5 * k), 0, cos(PI * 0.5 * k))
		var basis := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("Marble", d * (apothem + 2.2) + Vector3(0, 4.5, 0), Vector3(9, 9, 4.4), basis)
		lm.box("Door", d * (apothem + 4.45) + Vector3(0, 3.0, 0), Vector3(4.5, 6, 0.3), basis)
		lm.gable("Lead", d * (apothem + 2.2) + Vector3(0, 9, 0), 9.0, 4.4, 2.5, basis, 0.4, "Marble")
	lm.commit(model)
