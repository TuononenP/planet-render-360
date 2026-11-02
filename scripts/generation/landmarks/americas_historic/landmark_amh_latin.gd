class_name LandmarkAmhLatin
extends RefCounted

## Two great domed buildings of Spanish America in true metres: Mexico
## City's Metropolitan Cathedral on the Zócalo and Havana's neoclassical
## El Capitolio on the Paseo del Prado.

const CATHEDRAL_TOP_M := 67.0
const CAPITOLIO_TOP_M := 91.7

## Metropolitan Cathedral: the 59 x 118 m grey-stone church, its Baroque
## three-tier central portal and side portals between the two bell
## towers (67 m: three stages, octagonal belfry, bell-shaped crowns and
## crosses), the raised nave and transept roofs, and Tolsá's drum and
## dome over the crossing. The facade faces +Z (south, onto the Zócalo).
static func mexico_city_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8B80", 4.0))
	lm.use("Carved", LandmarkMaterials.pbr("limestone", "#B9B2A0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F7473", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#8E9892", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Stone", Vector3(0, -0.5, 0), Vector3(62.0, 2.0, 122.0))
	# Aisles and chapels, the raised nave and transept, their roofs.
	lm.box("Stone", Vector3(0, 11.5, 0), Vector3(59.0, 21.0, 118.0))
	lm.box("Roof", Vector3(0, 22.1, 0), Vector3(59.4, 0.4, 118.4))
	lm.box("Stone", Vector3(0, 28.0, -6.0), Vector3(24.0, 12.0, 104.0))
	lm.box("Stone", Vector3(0, 28.0, 2.0), Vector3(59.0, 12.0, 24.0))
	lm.gable("Roof", Vector3(0, 34.0, -6.0), 24.0, 104.0, 2.5, Basis(), 0.3)
	lm.gable("Roof", Vector3(0, 34.0, 2.0), 24.0, 59.0, 2.5, Basis(Vector3.UP, PI * 0.5), 0.3)
	for s in [-1.0, 1.0]:
		LandmarkNaParts.windows(lm, "Windows", Vector3(s * 29.5, 0, -2.0), Basis(Vector3.UP, s * PI * 0.5),
			100.0, 8.0, 18.0, 1, 12, Vector2(2.2, 6.0), 0.15)
		LandmarkNaParts.windows(lm, "Windows", Vector3(s * 12.0, 0, -6.0), Basis(Vector3.UP, s * PI * 0.5),
			90.0, 25.0, 31.0, 1, 10, Vector2(2.0, 4.5), 0.15)
		for i in 16:
			lm.box("Carved", Vector3(s * 29.5, 23.4, -58.0 + 7.4 * float(i)), Vector3(1.3, 2.8, 1.3))
	_cathedral_facade(lm)
	for s in [-1.0, 1.0]:
		_bell_tower(lm, s * 22.15)
	_cathedral_dome(lm, Vector3(0, 34.0, 2.0))
	lm.commit(model)

## Facade screen between the towers with the central three-tier portal
## (paired columns, relief panel, round window, pediment), the side
## portals at the tower feet and the statued parapet.
static func _cathedral_facade(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 17.5, 56.0), Vector3(30.6, 33.0, 6.0))
	lm.box("Carved", Vector3(0, 13.0, 59.8), Vector3(19.0, 24.0, 1.6))
	LandmarkAmhParts.opening(lm, "Windows", Vector3(0, 5.75, 60.6), Basis(), 5.0, 9.5, 0.4)
	LandmarkNaParts.columns(lm, "Carved", Vector3(-8.0, 1.0, 61.0), Vector3(-5.6, 1.0, 61.0), 2, 0.65, 0.55, 10.5, 12)
	LandmarkNaParts.columns(lm, "Carved", Vector3(5.6, 1.0, 61.0), Vector3(8.0, 1.0, 61.0), 2, 0.65, 0.55, 10.5, 12)
	lm.box("Carved", Vector3(0, 12.7, 60.4), Vector3(20.5, 1.4, 2.6))
	lm.box("Carved", Vector3(0, 18.4, 60.7), Vector3(13.0, 9.0, 0.5))
	for x in [-5.0, 5.0]:
		LandmarkAmhParts.opening(lm, "Windows", Vector3(x, 17.2, 61.0), Basis(), 1.4, 3.0, 0.3)
		lm.box("Carved", Vector3(x, 20.6, 61.1), Vector3(2.0, 0.5, 0.6))
	lm.disc("Windows", Vector3(0, 20.5, 61.0), Vector3.BACK, 1.6, 20)
	lm.gable("Carved", Vector3(0, 23.6, 59.8), 14.0, 2.0, 3.0, Basis(), 0.0, "Carved")
	lm.box("Carved", Vector3(0, 34.6, 58.5), Vector3(30.6, 1.2, 1.0))
	for i in 9:
		lm.box("Carved", Vector3(-13.6 + 3.4 * float(i), 36.3, 58.5), Vector3(0.9, 2.2, 0.9))
	for s in [-1.0, 1.0]:
		lm.box("Carved", Vector3(s * 22.15, 7.0, 59.6), Vector3(6.6, 12.0, 1.2))
		LandmarkAmhParts.opening(lm, "Windows", Vector3(s * 22.15, 4.75, 60.25), Basis(), 3.2, 7.5, 0.4)
		for dx in [-3.5, 3.5]:
			lm.box("Carved", Vector3(s * 22.15 + dx, 8.0, 60.0), Vector3(0.9, 14.0, 0.9))
		for y in [17.0, 22.0]:
			LandmarkAmhParts.opening(lm, "Windows", Vector3(s * 22.15, y, 59.1), Basis(), 1.6, 3.2, 0.3)

## One bell tower centred at `x` on the facade: square base and bell
## stages, octagonal belfry, bell-shaped crown, lantern and gilded cross.
static func _bell_tower(lm: LandmarkMesh, x: float) -> void:
	lm.box("Stone", Vector3(x, 14.0, 52.0), Vector3(14.7, 26.0, 14.0))
	lm.box("Carved", Vector3(x, 27.0, 52.0), Vector3(15.5, 0.8, 14.8))
	lm.box("Stone", Vector3(x, 33.75, 52.0), Vector3(12.6, 13.5, 12.0))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var off := 6.0 if q % 2 == 0 else 6.3
		LandmarkAmhParts.opening(lm, "Windows", Vector3(x, 0, 52.0) + r * Vector3(0, 34.0, off), r, 2.6, 6.0, 0.3)
	lm.box("Carved", Vector3(x, 40.7, 52.0), Vector3(13.6, 0.8, 13.0))
	var oct := Vector3(x, 41.1, 52.0)
	lm.frustum("Stone", oct, 6.2, 5.8, 10.0, 8, PI / 8.0)
	for q in 8:
		var a := TAU * float(q) / 8.0
		var r := Basis(Vector3.UP, PI * 0.5 - a)
		LandmarkAmhParts.opening(lm, "Windows", oct + r * Vector3(0, 5.0, 5.6), r, 1.9, 4.6, 0.3)
	var crown := Vector3(x, 51.1, 52.0)
	lm.lathe("Dome", crown, PackedVector2Array([Vector2(6.4, 0.0), Vector2(6.8, 0.8), Vector2(6.6, 2.2),
		Vector2(5.9, 3.8), Vector2(4.8, 5.4), Vector2(3.4, 6.9), Vector2(2.2, 8.2), Vector2(1.6, 9.3)]), 16)
	lm.frustum("Stone", crown + Vector3(0, 9.3, 0), 1.5, 1.3, 3.0, 12)
	lm.lathe("Dome", crown + Vector3(0, 12.3, 0), PackedVector2Array([Vector2(1.6, 0.0), Vector2(1.2, 0.8),
		Vector2(0.0, 2.2)]), 12)
	var cross := crown + Vector3(0, 14.5, 0)
	lm.beam("Gold", cross, cross + Vector3(0, CATHEDRAL_TOP_M - 65.6, 0), 0.22, 0.22)
	lm.beam("Gold", cross + Vector3(-0.5, 0.9, 0), cross + Vector3(0.5, 0.9, 0), 0.2, 0.2)

## Octagonal-fenestrated drum with its ring of columns, entablature,
## ribbed dome, lantern and cross over the crossing at `c`.
static func _cathedral_dome(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Stone", c, 11.6, 11.6, 11.0, 24)
	LandmarkAmhParts.column_ring(lm, "Carved", c, 11.9, 20, 0.55, 0.5, 11.0, 0.0, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var r := Basis(Vector3.UP, PI * 0.5 - a)
		LandmarkAmhParts.opening(lm, "Windows", c + r * Vector3(0, 5.5, 11.55), r, 1.8, 4.5, 0.4)
	lm.frustum("Carved", c + Vector3(0, 11.0, 0), 12.6, 12.6, 1.4, 24)
	var d := c + Vector3(0, 12.4, 0)
	lm.lathe("Dome", d, PackedVector2Array([Vector2(11.6, 0.0), Vector2(11.4, 1.0), Vector2(10.6, 3.2),
		Vector2(9.1, 5.4), Vector2(7.0, 7.4), Vector2(4.6, 8.8), Vector2(2.4, 9.6), Vector2(1.5, 9.9)]), 24)
	lm.frustum("Carved", d + Vector3(0, 9.9, 0), 1.9, 1.7, 3.2, 12)
	lm.lathe("Dome", d + Vector3(0, 13.1, 0), PackedVector2Array([Vector2(2.1, 0.0), Vector2(1.7, 0.8),
		Vector2(0.0, 2.4)]), 12)
	var t := d + Vector3(0, 15.5, 0)
	lm.beam("Gold", t, t + Vector3(0, 2.4, 0), 0.3, 0.3)
	lm.beam("Gold", t + Vector3(-0.7, 1.5, 0), t + Vector3(0.7, 1.5, 0), 0.25, 0.25)

## El Capitolio: the 205 m neoclassical block on its rusticated
## basement, two long wings of colossal pilasters and windows under
## hipped roofs, the 36 m portico of twelve Ionic columns above the
## 56-step stair with its two bronze Zanelli figures, and the forward
## dome on its colonnaded drum, tholos lantern and gilded finial to
## 91.7 m. The front faces +X; yaw turns it onto the Paseo del Prado.
static func el_capitolio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#DCD3BC", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("limestone", "#C4BBA3", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#B3AFA5", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7C8584", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("limestone", "#E0DBCD", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bronze", LandmarkMaterials.paint("#5C4B34", 0.5, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Base", Vector3(-3.0, 3.2, 0), Vector3(66.0, 10.4, 205.0))
	lm.box("Wall", Vector3(-3.0, 19.7, 0), Vector3(66.0, 22.6, 36.0))
	lm.box("Wall", Vector3(-3.0, 31.6, 0), Vector3(68.0, 1.2, 38.0))
	for s in [-1.0, 1.0]:
		var zc: float = s * 60.25
		lm.box("Wall", Vector3(-3.0, 18.5, zc), Vector3(66.0, 20.2, 84.5))
		lm.box("Wall", Vector3(-3.0, 29.2, zc), Vector3(68.0, 1.2, 86.5))
		LandmarkNaParts.hip(lm, "Roof", Vector3(-3.0, 29.8, zc), Basis(), 33.0, 43.25, 0.8, 3.0)
		LandmarkNaParts.windows(lm, "Windows", Vector3(30.0, 0, zc), Basis(Vector3.UP, PI * 0.5),
			80.0, 11.0, 27.0, 3, 14, Vector2(1.8, 3.4), 0.15)
		LandmarkNaParts.windows(lm, "Windows", Vector3(-36.0, 0, zc), Basis(Vector3.UP, -PI * 0.5),
			80.0, 11.0, 27.0, 3, 14, Vector2(1.8, 3.4), 0.15)
		LandmarkNaParts.windows(lm, "Windows", Vector3(-3.0, 0, zc + s * 42.25),
			Basis(Vector3.UP, 0.0 if s > 0.0 else PI), 56.0, 11.0, 27.0, 3, 9, Vector2(1.8, 3.4), 0.15)
		for i in 15:
			lm.box("Wall", Vector3(30.25, 17.8, zc - 40.0 + 80.0 * float(i) / 14.0), Vector3(0.6, 18.8, 1.1))
	LandmarkNaParts.windows(lm, "Windows", Vector3(-36.0, 0, 0), Basis(Vector3.UP, -PI * 0.5),
		30.0, 11.0, 29.0, 3, 6, Vector2(1.8, 3.4), 0.15)
	# Portico, stair and figures.
	lm.box("Base", Vector3(38.0, 3.2, 0), Vector3(16.0, 10.4, 48.0))
	for x in [34.0, 40.0]:
		LandmarkNaParts.columns(lm, "Wall", Vector3(x, 8.4, -14.5), Vector3(x, 8.4, 14.5), 6, 0.85, 0.75, 14.1, 14)
	lm.box("Wall", Vector3(36.0, 24.0, 0), Vector3(13.5, 3.0, 38.5))
	lm.box("Wall", Vector3(36.0, 27.2, 0), Vector3(13.0, 3.4, 38.0))
	lm.box("Wall", Vector3(36.0, 29.4, 0), Vector3(13.4, 1.0, 38.4))
	LandmarkAmhParts.opening(lm, "Windows", Vector3(30.1, 13.2, 0), Basis(Vector3.UP, PI * 0.5), 7.2, 9.6, 0.3)
	for z in [-10.5, 10.5]:
		LandmarkAmhParts.opening(lm, "Windows", Vector3(30.1, 12.0, z), Basis(Vector3.UP, PI * 0.5), 4.2, 7.2, 0.3)
	var east := Basis(Vector3.UP, PI * 0.5)
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, east, 36.0, 65.6, 0.0, 46.0, 8.4, 40.0, 56)
	LandmarkAmhParts.rails(lm, "Steps", Vector3.ZERO, east, 36.0, 65.6, 0.0, 46.0, 8.4, 2.2, 1.8)
	for s in [-1.0, 1.0]:
		lm.box("Steps", Vector3(43.5, 9.6, s * 21.5), Vector3(3.4, 2.4, 3.4))
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(43.5, 10.8, s * 21.5), 6.5)
	_capitolio_dome(lm, Vector3(6.0, 32.2, 0))
	lm.commit(model)

## Colonnaded drum, attic, dome, tholos lantern and gilded finial.
static func _capitolio_dome(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Wall", c, 16.5, 16.5, 3.0, 40)
	var d := c + Vector3(0, 3.0, 0)
	lm.frustum("Wall", d, 14.5, 14.5, 11.0, 40)
	LandmarkAmhParts.column_ring(lm, "Wall", d, 15.6, 20, 0.6, 0.5, 11.0, 0.0, 10)
	for k in 10:
		var a := TAU * float(k) / 10.0 + PI / 20.0
		var r := Basis(Vector3.UP, PI * 0.5 - a)
		LandmarkAmhParts.opening(lm, "Windows", d + r * Vector3(0, 5.5, 14.4), r, 1.8, 5.0, 0.4)
	lm.frustum("Wall", d + Vector3(0, 11.0, 0), 16.8, 16.8, 1.8, 40)
	lm.frustum("Wall", d + Vector3(0, 12.8, 0), 14.2, 14.2, 2.2, 40)
	var b := d + Vector3(0, 15.0, 0)
	lm.lathe("Dome", b, PackedVector2Array([Vector2(14.2, 0.0), Vector2(14.0, 1.5), Vector2(13.2, 4.5),
		Vector2(11.6, 8.5), Vector2(9.4, 12.5), Vector2(6.9, 16.0), Vector2(4.6, 18.8), Vector2(3.4, 20.4),
		Vector2(3.0, 21.0)]), 40)
	var t := b + Vector3(0, 21.0, 0)
	lm.frustum("Wall", t, 4.2, 4.2, 0.8, 16)
	lm.frustum("Dome", t + Vector3(0, 0.8, 0), 2.9, 2.9, 5.2, 16)
	LandmarkAmhParts.column_ring(lm, "Wall", t + Vector3(0, 0.8, 0), 3.4, 12, 0.28, 0.26, 5.2, 0.0, 8)
	lm.frustum("Wall", t + Vector3(0, 6.0, 0), 4.0, 4.0, 0.8, 16)
	lm.lathe("Dome", t + Vector3(0, 6.8, 0), PackedVector2Array([Vector2(3.8, 0.0), Vector2(3.2, 1.2),
		Vector2(2.0, 3.6), Vector2(0.9, 5.4), Vector2(0.5, 6.2)]), 16)
	var f := t + Vector3(0, 13.0, 0)
	lm.lathe("Gold", f, PackedVector2Array([Vector2(0.9, 0.0), Vector2(1.1, 0.7), Vector2(0.5, 1.6),
		Vector2(0.6, 2.6), Vector2(0.25, 4.4), Vector2(0.1, CAPITOLIO_TOP_M - f.y)]), 10)
