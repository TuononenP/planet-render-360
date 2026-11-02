class_name LandmarkAmhUsa
extends RefCounted

## Two American founding landmarks in true metres: the Jefferson
## Memorial on Washington's Tidal Basin and Independence Hall in
## Philadelphia.

const JEFFERSON_TOP_M := 33.8
const INDEPENDENCE_TOP_M := 51.4

## Jefferson Memorial: the circular marble steps, the Ionic colonnade of
## 26 columns (43 ft, 1.6 m through) round the rotunda with its three
## openings, the north portico of twelve columns under the pediment,
## and the shallow dome, to 33.8 m. The portico faces north (-Z) over
## the Tidal Basin.
static func jefferson_memorial(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDEBE4", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D8D5CC", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#A9AFAC", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	lm.frustum("Steps", Vector3(0, -3.0, 0), 31.5, 30.5, 3.0, 48)
	lm.frustum("Steps", Vector3.ZERO, 30.0, 30.0, 1.4, 48)
	lm.frustum("Steps", Vector3(0, 1.4, 0), 27.7, 27.7, 1.4, 48)
	lm.frustum("Steps", Vector3(0, 2.8, 0), 25.4, 25.4, 1.5, 48)
	var floor_y := 4.3
	# Rotunda wall, colonnade, entablature, attic.
	lm.frustum("Marble", Vector3(0, floor_y, 0), 16.2, 16.2, 16.7, 48)
	for k in 26:
		var a := TAU * float(k) / 26.0
		var cx := cos(a) * 17.4
		var cz := sin(a) * 17.4
		if cz < 0.0 and absf(cx) < 13.5:
			continue
		if absf(a) < 0.15 or absf(a - PI) < 0.15 or absf(a - PI * 0.5) < 0.15:
			continue
		lm.frustum("Marble", Vector3(cx, floor_y, cz), 0.82, 0.74, 13.1, 12)
	lm.frustum("Marble", Vector3(0, 17.4, 0), 18.3, 18.3, 3.6, 48)
	lm.frustum("Marble", Vector3(0, 20.5, 0), 18.8, 18.8, 0.5, 48)
	lm.frustum("Marble", Vector3(0, 21.0, 0), 15.8, 15.4, 4.4, 48)
	# Shallow dome: a spherical cap 8.4 m high on a 15.4 m radius.
	var sphere_r := (15.4 * 15.4 + 8.4 * 8.4) / (2.0 * 8.4)
	var prof := PackedVector2Array()
	for i in 9:
		var r := 15.4 * (1.0 - float(i) / 8.0)
		prof.append(Vector2(r, sqrt(sphere_r * sphere_r - r * r) - (sphere_r - 8.4)))
	lm.lathe("Dome", Vector3(0, 25.4, 0), prof, 48)
	for a in [0.0, PI * 0.5, PI]:
		var r := Basis(Vector3.UP, PI * 0.5 - float(a))
		LandmarkAmhParts.opening(lm, "Door", Vector3(0, floor_y + 4.75, 0) + r * Vector3(0, 0, 16.25),
			r, 6.0, 9.5, 0.4)
	# North portico: 8 columns in front, 4 behind, entablature and pediment.
	var north := Basis(Vector3.UP, PI)
	lm.box("Steps", Vector3(0, 2.15, -25.5), Vector3(29.0, 4.3, 17.0))
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, north, 28.0, 44.0, 0.0, 34.0, floor_y, 30.0, 15)
	LandmarkAmhParts.rails(lm, "Steps", Vector3.ZERO, north, 28.0, 44.0, 0.0, 34.0, floor_y, 2.4, 1.6)
	for i in 8:
		lm.frustum("Marble", Vector3((float(i) - 3.5) * 3.7, floor_y, -30.0), 0.82, 0.74, 13.1, 12)
	for x in [-12.95, -9.25, 9.25, 12.95]:
		lm.frustum("Marble", Vector3(x, floor_y, -21.5), 0.82, 0.74, 13.1, 12)
	lm.box("Marble", Vector3(0, 19.2, -24.7), Vector3(28.2, 3.6, 13.8))
	lm.gable("Marble", Vector3(0, 21.0, -24.7), 28.2, 13.8, 3.9, Basis(), 0.0, "Marble")
	lm.commit(model)

## Independence Hall: the red-brick Georgian State House (33 x 15 m,
## two storeys under a hipped roof with four chimneys, nine bays with
## the central door on Chestnut Street), the arcaded hyphens and the
## two wings, and on the south (+Z) face the brick tower carrying
## Strickland's white steeple, to 51.4 m. The long axis runs along X.
static func independence_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A44A36", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EAE6DA", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5D6368", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A9488", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Gold", LandmarkMaterials.gold())
	# Central block, nine bays, cornice, hipped roof and chimneys.
	lm.box("Stone", Vector3(0, -0.05, 0), Vector3(33.6, 1.9, 15.6))
	lm.box("Brick", Vector3(0, 6.0, 0), Vector3(33.0, 10.8, 15.0))
	lm.box("Trim", Vector3(0, 11.75, 0), Vector3(34.0, 0.7, 16.2))
	LandmarkNaParts.hip(lm, "Roof", Vector3(0, 12.1, 0), Basis(), 17.0, 8.1, 0.5, 4.0)
	for cx in [-11.0, 11.0]:
		for cz in [-3.0, 3.0]:
			lm.box("Brick", Vector3(cx, 15.65, cz), Vector3(1.5, 3.5, 1.5))
	for q in 2:
		var r := Basis(Vector3.UP, PI * float(q))
		for i in range(-4, 5):
			var x := 3.5 * float(i)
			if q == 0 and absi(i) <= 1:
				continue
			if i == 0:
				lm.box("Trim", r * Vector3(x, 2.7, 7.55), Vector3(3.2, 4.6, 0.12), r)
				LandmarkAmhParts.opening(lm, "Windows", r * Vector3(x, 2.5, 7.62), r, 2.4, 3.8, 0.1)
			else:
				lm.box("Trim", r * Vector3(x, 4.6, 7.55), Vector3(1.9, 3.4, 0.12), r)
				LandmarkAmhParts.opening(lm, "Windows", r * Vector3(x, 4.6, 7.62), r, 1.4, 3.0, 0.1)
			lm.box("Trim", r * Vector3(x, 9.0, 7.55), Vector3(1.9, 3.2, 0.12), r)
			LandmarkAmhParts.opening(lm, "Windows", r * Vector3(x, 9.0, 7.62), r, 1.4, 2.8, 0.1)
	# Hyphens and wings, mirrored east and west.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 20.5, -0.05, 0), Vector3(8.4, 1.9, 6.8))
		lm.box("Brick", Vector3(s * 20.5, 3.3, 0), Vector3(8.0, 5.4, 6.4))
		lm.box("Trim", Vector3(s * 20.5, 6.25, 0), Vector3(8.4, 0.5, 6.8))
		LandmarkNaParts.hip(lm, "Roof", Vector3(s * 20.5, 6.5, 0), Basis(), 4.2, 3.4, 0.6, 1.4)
		for z in [-3.25, 3.25]:
			LandmarkAmhParts.opening(lm, "Windows", Vector3(s * 20.5, 2.6, z), Basis(), 2.2, 3.6, 0.3)
		lm.box("Stone", Vector3(s * 33.0, -0.05, 0), Vector3(17.4, 1.9, 10.9))
		lm.box("Brick", Vector3(s * 33.0, 5.0, 0), Vector3(17.0, 8.8, 10.5))
		lm.box("Trim", Vector3(s * 33.0, 9.65, 0), Vector3(17.6, 0.5, 11.1))
		LandmarkNaParts.hip(lm, "Roof", Vector3(s * 33.0, 9.9, 0), Basis(), 8.8, 5.5, 0.55, 3.4)
		lm.box("Brick", Vector3(s * 36.5, 14.3, 0), Vector3(1.4, 4.0, 1.4))
		for q in 2:
			var r := Basis(Vector3.UP, PI * float(q))
			LandmarkNaParts.windows(lm, "Windows", Vector3(s * 33.0, 0, 0), r, 14.0, 2.4, 8.0, 2, 4,
				Vector2(1.4, 2.6), 5.3)
		LandmarkNaParts.windows(lm, "Windows", Vector3(s * 41.5, 0, 0), Basis(Vector3.UP, s * PI * 0.5),
			6.0, 2.4, 8.0, 2, 2, Vector2(1.4, 2.6), 0.1)
	_steeple_tower(lm)
	lm.commit(model)

## The brick tower on the south face and the white wooden steeple above
## it: belfry, octagonal stages, small dome, lantern, spire and vane.
static func _steeple_tower(lm: LandmarkMesh) -> void:
	lm.box("Brick", Vector3(0, 14.05, 11.0), Vector3(9.4, 26.9, 9.4))
	for y in [12.6, 22.0]:
		lm.box("Trim", Vector3(0, y, 11.0), Vector3(9.9, 0.45, 9.9))
	lm.box("Trim", Vector3(0, 8.6, 15.75), Vector3(4.0, 7.4, 0.15))
	LandmarkAmhParts.opening(lm, "Windows", Vector3(0, 8.4, 15.82), Basis(), 3.0, 6.4, 0.1)
	lm.box("Trim", Vector3(0, 17.0, 15.75), Vector3(2.4, 4.2, 0.15))
	LandmarkAmhParts.opening(lm, "Windows", Vector3(0, 17.0, 15.82), Basis(), 1.6, 3.4, 0.1)
	lm.box("Trim", Vector3(0, 27.8, 11.0), Vector3(10.0, 0.6, 10.0))
	var top := Vector3(0, 28.1, 11.0)
	lm.frustum("Trim", top, 4.3, 4.0, 6.5, 8, PI / 8.0)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		LandmarkAmhParts.opening(lm, "Windows", top + r * Vector3(0, 3.4, 3.8), r, 1.6, 3.4, 0.2)
	lm.frustum("Trim", top + Vector3(0, 6.5, 0), 4.4, 4.4, 0.4, 8, PI / 8.0)
	lm.frustum("Trim", top + Vector3(0, 6.5, 0), 3.3, 3.0, 4.0, 8, PI / 8.0)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		LandmarkAmhParts.opening(lm, "Windows", top + r * Vector3(0, 8.5, 2.8), r, 1.0, 2.0, 0.2)
	lm.lathe("Roof", top + Vector3(0, 10.5, 0), PackedVector2Array([Vector2(3.4, 0.0), Vector2(3.5, 0.4),
		Vector2(3.0, 1.6), Vector2(2.1, 2.7), Vector2(1.1, 3.4), Vector2(0.5, 3.7)]), 16)
	lm.frustum("Trim", top + Vector3(0, 14.2, 0), 0.9, 0.8, 2.0, 8, PI / 8.0)
	lm.spire("Roof", top + Vector3(0, 16.2, 0), 0.7, 5.4, 0.12, 8)
	lm.lathe("Gold", top + Vector3(0, 21.6, 0), PackedVector2Array([Vector2(0.1, 0.0), Vector2(0.35, 0.2),
		Vector2(0.45, 0.45), Vector2(0.3, 0.75), Vector2(0.1, 0.9)]), 10)
	lm.beam("Gold", top + Vector3(0, 22.5, 0), Vector3(0, INDEPENDENCE_TOP_M, 11.0), 0.12, 0.12)
