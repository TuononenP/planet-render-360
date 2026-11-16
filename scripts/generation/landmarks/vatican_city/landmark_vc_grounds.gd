class_name LandmarkVcGrounds
extends RefCounted

## The Vatican Gardens round the Casina of Pius IV, and the Leonine Wall
## with the Torre San Giovanni, in true metres.

const GARDEN_YAW := -31.5

# --- Vatican Gardens ---------------------------------------------------------------

## Origin at the middle of the Casina of Pius IV (Pirro Ligorio,
## 1558-62), long axis along X: the two-storey villa at the west end with
## its loggia onto the oval court, the stuccoed nymphaeum loggia closing
## the east end behind a basin, the low court wall and its paving, the
## clipped parterres and gravel walks of the Italian garden, the Casina
## del Giardiniere and the Mater Ecclesiae monastery, and the stone pines
## and cypresses of the grounds.
static func gardens(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D8C49A", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DCC3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B9AE98", 3.0))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#BDB097", 3.0))
	lm.use("Hedge", LandmarkMaterials.pbr("forest", "#3F5A34", 2.0))
	lm.use("Pine", LandmarkMaterials.pbr("forest", "#31472B", 4.0))
	lm.use("Water", LandmarkMaterials.glass("#3A6E7A"))
	lm.use("Trunk", LandmarkMaterials.pbr("wood", "#5A4630", 2.0))
	var yaw := GARDEN_YAW
	# Villa: two floors with a three-arched loggia on the court.
	LandmarkRmLUtil.block(lm, "Stucco", Vector3(-16.5, 0, 0), 22.0, 11.0, 13.0, Vector3(-1, 0, 0), 2, 5, 1.1, 2.0, "Tile")
	LandmarkRmLKit.arcade(lm, "Stucco", "Shadow", Vector3(-11.0, 0.0, 6.0), Vector3(0, 0, -1), Vector3(1, 0, 0),
		12.0, 5.2, 3, 3.0, 3.1, 1.0)
	# Nymphaeum loggia: stuccoed front, three arched bays, parapet.
	LandmarkRmLUtil.block(lm, "Stucco", Vector3(19.5, 0, 0), 17.0, 9.0, 7.0, Vector3(1, 0, 0), 1, 3, 1.4, 2.4, "")
	LandmarkRmLKit.arcade(lm, "Stucco", "Shadow", Vector3(15.0, 0.0, -6.0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
		12.0, 6.5, 3, 3.2, 4.0, 1.0)
	for k in 4:
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(16.0, 0, -6.0 + 4.0 * float(k)), Vector3(0, 0, 1), Vector3(-1, 0, 0), 0.7, 6.8, 0.3, true)
	# Oval court: paving, low wall, basin and water.
	lm.frustum("Paving", Vector3(4.0, 0, 0), 1.0, 1.0, 0.18, 36, 0.0, 14.0, 8.8)
	lm.lathe("Trim", Vector3(4.0, 0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.0, 1.1), Vector2(0.96, 1.1),
		Vector2(0.96, 0)]), 36, 15.0, 9.8, 0.0, true, false)
	lm.frustum("Trim", Vector3(4.0, 0, 0), 2.6, 2.4, 0.7, 14)
	lm.frustum("Water", Vector3(4.0, 0.7, 0), 2.2, 2.2, 0.02, 14)
	lm.frustum("Trim", Vector3(4.0, 0.7, 0), 0.4, 0.3, 1.8, 8)
	# Parterres and gravel walks, set north and south of the court.
	for s in [-1.0, 1.0]:
		for k in 3:
			var x := -2.0 + 15.0 * float(k)
			lm.box("Gravel", Vector3(x, 0.07, s * 22.0), Vector3(12.0, 0.1, 9.0))
			lm.box("Hedge", Vector3(x, 0.45, s * 22.0 - 3.6), Vector3(12.0, 0.9, 0.7))
			lm.box("Hedge", Vector3(x, 0.45, s * 22.0 + 3.6), Vector3(12.0, 0.9, 0.7))
			lm.box("Hedge", Vector3(x - 5.6, 0.45, s * 22.0), Vector3(0.7, 0.9, 7.2))
			lm.box("Hedge", Vector3(x + 5.6, 0.45, s * 22.0), Vector3(0.7, 0.9, 7.2))
	lm.box("Gravel", Vector3(8.0, 0.06, 0), Vector3(70.0, 0.1, 2.4))
	# Outbuildings, placed by their real offset from the casina.
	LandmarkVcUtil.rbox(lm, "Stucco", -41.0, -111.0, yaw, 0.0, 11.8, 7.0, 11.9, 75.8)
	LandmarkVcUtil.rbox(lm, "Tile", -41.0, -111.0, yaw, 7.0, 12.4, 1.6, 12.5, 75.8)
	LandmarkVcUtil.rbox(lm, "Stucco", -121.0, -42.0, yaw, 0.0, 15.7, 9.0, 13.3, 1.9)
	LandmarkVcUtil.rbox(lm, "Tile", -121.0, -42.0, yaw, 9.0, 16.3, 1.8, 13.9, 1.9)
	LandmarkVcUtil.rbox(lm, "Stucco", -132.0, -43.0, yaw, 0.0, 10.7, 6.0, 20.5, 92.8)
	# Stone pines and cypresses (fixed rings round the court and the walks).
	var pines := [Vector2(-34, 20), Vector2(-26, -26), Vector2(30, 36), Vector2(42, -30), Vector2(-48, -2),
		Vector2(58, 8), Vector2(-14, 40), Vector2(8, -42), Vector2(-62, 30), Vector2(70, -22), Vector2(-70, -40),
		Vector2(24, 52), Vector2(-40, 58), Vector2(52, 44), Vector2(-92, 6)]
	for i in pines.size():
		LandmarkVcUtil.pine(lm, "Trunk", "Pine", Vector3(pines[i].x, 0, pines[i].y), 12.0 + float(i % 4) * 0.7)
	for i in 14:
		var a := TAU * float(i) / 14.0
		LandmarkVcUtil.cypress(lm, "Pine", Vector3(cos(a) * 30.0 + 8.0, 0, sin(a) * 18.0), 9.0 + float(i % 3))
	lm.commit(model)

# --- Leonine Wall and Torre San Giovanni -------------------------------------------

## Origin at the tower. Leo IV's 9th-century wall runs north-east
## (50 degrees above east) from the Torre San Giovanni, 9.5 m high and
## 3.2 m thick with a crenellated parapet and walk, and square bastions
## every 40 m; the round tower (19 m across) rises 23 m in three
## courses to a crenellated terrace and a small turret, with the low
## Marconi radio centre and the Lourdes grotto's rock beside it.
static func tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#A8805E", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C7B791", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D3B98F", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8A8478", 3.0))
	lm.use("Hedge", LandmarkMaterials.pbr("forest", "#3F5A34", 2.0))
	# The tower: battered base, three courses of brick, corbelled terrace.
	var r := 9.5
	lm.frustum("Stone", Vector3.ZERO, r + 1.2, r, 4.0, 20)
	lm.frustum("Wall", Vector3(0, 4.0, 0), r, r - 0.3, 17.0, 20)
	for y in [10.0, 16.0]:
		lm.lathe("Stone", Vector3(0, y, 0), PackedVector2Array([Vector2(r - 0.1, 0), Vector2(r + 0.35, 0.15),
			Vector2(r + 0.35, 0.5), Vector2(r - 0.1, 0.5)]), 20, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Stone", Vector3(0, 20.4, 0), PackedVector2Array([Vector2(r - 0.4, 0), Vector2(r + 1.0, 0.5),
		Vector2(r + 1.0, 1.4), Vector2(r - 0.4, 1.4)]), 20, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Stone", Vector3(0, 21.8, 0), r + 0.9, r + 0.9, 0.3, 20)
	for k in 20:
		var a := TAU * (float(k) + 0.5) / 20.0
		lm.box("Wall", Vector3(cos(a) * (r + 0.55), 22.5, sin(a) * (r + 0.55)), Vector3(1.4, 1.6, 1.0),
			Basis(Vector3.UP, -a + PI * 0.5))
	for k in 6:
		var a := TAU * float(k) / 6.0 + 0.3
		var wy := 7.0 + 5.5 * float(k % 2)
		lm.box("Shadow", Vector3(cos(a) * (r - 0.3), wy, sin(a) * (r - 0.3)), Vector3(1.0, 2.2, 0.5),
			Basis(Vector3.UP, -a + PI * 0.5))
	# Turret on the terrace, its tiled cone and a flagstaff.
	lm.frustum("Wall", Vector3(3.5, 21.8, 2.0), 2.2, 2.0, 5.0, 10)
	lm.spire("Tile", Vector3(3.5, 26.8, 2.0), 2.7, 3.2, 0.0, 8)
	# Wall to the north-east, crenellated, with bastions.
	var dir := Vector3(cos(deg_to_rad(50.0)), 0, -sin(deg_to_rad(50.0)))
	var side := Vector3.UP.cross(dir)
	var a0 := dir * (r + 1.0)
	var length := 165.0
	var a1 := dir * length
	lm.beam("Wall", a0 + Vector3(0, 4.75, 0), a1 + Vector3(0, 4.75, 0), 3.2, 9.5, side)
	lm.beam("Stone", a0 + Vector3(0, 9.55, 0), a1 + Vector3(0, 9.55, 0), 3.7, 0.5, side)
	for s in [-1.0, 1.0]:
		SEuUtil.crenels(lm, "Wall", a0 + side * s * 1.5 + Vector3(0, 9.8, 0), a1 + side * s * 1.5 + Vector3(0, 9.8, 0), 0.9, 1.2, 0.5)
	for k in 4:
		var p := dir * (45.0 + 40.0 * float(k))
		lm.box("Wall", p + Vector3(0, 6.5, 0), Vector3(5.6, 13.0, 5.6), Basis(Vector3.UP, atan2(dir.x, dir.z) + PI * 0.5), 0.0)
		lm.box("Stone", p + Vector3(0, 13.2, 0), Vector3(6.4, 0.5, 6.4), Basis(Vector3.UP, atan2(dir.x, dir.z) + PI * 0.5), 0.0)
		lm.box("Shadow", p + side * 2.9 + Vector3(0, 8.0, 0), Vector3(0.2, 1.6, 0.8), Basis(Vector3.UP, atan2(dir.x, dir.z) + PI * 0.5), 0.0)
	# Marconi radio centre (1931) and the grotto of Lourdes.
	LandmarkVcUtil.rbox(lm, "Plaster", 73.8, 27.1, 0.0, 0.0, 38.8, 7.0, 28.7, 153.4)
	LandmarkVcUtil.rbox(lm, "Tile", 73.8, 27.1, 0.0, 7.0, 40.0, 1.4, 30.0, 153.4)
	LandmarkVcUtil.rbox(lm, "Rock", 77.6, 137.2, 0.0, 0.0, 12.1, 7.0, 7.0, 140.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		LandmarkVcUtil.cypress(lm, "Hedge", Vector3(86.0 + cos(a) * 12.0, 0, -60.0 + sin(a) * 6.0), 9.0)
	lm.commit(model)
