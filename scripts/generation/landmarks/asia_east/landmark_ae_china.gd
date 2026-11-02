class_name LandmarkAeChina
extends RefCounted

## Palaces and ramparts of China in true metres: the Hall of Supreme
## Harmony (35 m: three marble terraces, red double-eave hall under yellow
## glazed tiles), the Temple of Heaven's Hall of Prayer (38 m: round, on
## three marble terraces under three blue roofs and a gilt finial), a
## 400 m piece of the Great Wall at Badaling (watchtowers on a brick
## rampart, 12 m) and the Potala Palace (117 m: white plinth and wings,
## red palace, gilded roofs). Halls face south (+Z); the wall runs along +X.

# --- Hall of Supreme Harmony ---

static func supreme_harmony(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E0D6", 3.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#9A2B22", 0.65, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D9A52C", 2.0, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	# Three marble terraces of 2.71 m (8.13 m) with a balustrade round each.
	var sizes := [Vector2(116, 84), Vector2(106, 74), Vector2(96, 64)]
	for t in 3:
		var sz: Vector2 = sizes[t]
		var y := 2.71 * t
		lm.box("Marble", Vector3(0, y + 0.855, 0), Vector3(sz.x, 3.71, sz.y))
		lm.box("Marble", Vector3(0, y + 2.71 + 0.45, sz.y * 0.5 - 0.3), Vector3(sz.x, 0.9, 0.5))
		lm.box("Marble", Vector3(0, y + 2.71 + 0.45, -sz.y * 0.5 + 0.3), Vector3(sz.x, 0.9, 0.5))
		for s in [-1.0, 1.0]:
			lm.box("Marble", Vector3(s * (sz.x * 0.5 - 0.3), y + 2.71 + 0.45, 0), Vector3(0.5, 0.9, sz.y))
	# Hall: 11 x 5 bays of red walls, bracket sets, lower roof, upper storey, upper roof.
	var y0 := 8.13
	lm.box("Lacquer", Vector3(0, y0 + 3.8, 0), Vector3(60.0, 7.6, 33.0))
	lm.box("Bracket", Vector3(0, y0 + 8.1, 0), Vector3(62.0, 1.0, 35.0))
	LandmarkAeParts.hip_roof(lm, "Roof", Vector3(0, y0 + 8.6, 0), Vector2(76.0, 46.0), Vector2(54.0, 26.0), 5.4, 1.2)
	var y1 := y0 + 12.4
	lm.box("Lacquer", Vector3(0, y1 + 2.3, 0), Vector3(52.0, 4.6, 24.0))
	lm.box("Bracket", Vector3(0, y1 + 5.1, 0), Vector3(54.0, 1.0, 26.0))
	LandmarkAeParts.hip_roof(lm, "Roof", Vector3(0, y1 + 5.6, 0), Vector2(70.0, 40.0), Vector2(24.0, 1.2), 7.4, 1.0)
	var ridge := y1 + 5.6 + 7.4
	lm.box("Gold", Vector3(0, ridge + 0.4, 0), Vector3(25.0, 0.8, 1.3))
	for s in [-1.0, 1.0]:
		lm.box("Gold", Vector3(s * 12.2, 35.0 - 1.2, 0), Vector3(1.3, 2.4, 1.3))
	lm.commit(model)

# --- Temple of Heaven (Hall of Prayer for Good Harvests) ---

static func temple_of_heaven(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2DED4", 3.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#8E2A22", 0.65, 0.0))
	lm.use("Blue", LandmarkMaterials.pbr("terracotta", "#1F5C9E", 2.0, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	for t in 3:
		var r := 45.5 - 8.0 * t
		lm.frustum("Marble", Vector3(0, 2.0 * t - 1.0, 0), r, r, 3.0, 36)
		lm.frustum("Marble", Vector3(0, 2.0 * t + 2.0, 0), r - 0.4, r - 0.4, 0.9, 36)
	lm.frustum("Lacquer", Vector3(0, 6.0, 0), 14.0, 14.0, 9.2, 28)
	lm.frustum("Marble", Vector3(0, 5.9, 0), 15.5, 15.5, 0.5, 28)
	# Three roofs [eave radius, eave y, rise, top radius] with red necks between.
	var roofs := [[19.5, 15.0, 5.5, 14.0], [16.8, 22.0, 5.0, 11.4], [13.8, 28.5, 6.0, 1.2]]
	for rf in roofs:
		var re := float(rf[0])
		var ye := float(rf[1])
		var rise := float(rf[2])
		var prof := PackedVector2Array([Vector2(re + 0.6, 0.5), Vector2(re, 0.0),
			Vector2(lerpf(re, float(rf[3]), 0.45), rise * 0.28), Vector2(lerpf(re, float(rf[3]), 0.8), rise * 0.62),
			Vector2(float(rf[3]), rise)])
		lm.lathe("Blue", Vector3(0, ye, 0), prof, 32)
	lm.frustum("Lacquer", Vector3(0, 20.0, 0), 13.8, 13.0, 3.0, 24)
	lm.frustum("Lacquer", Vector3(0, 26.5, 0), 11.2, 10.6, 3.0, 24)
	# Gilt ball finial to 38 m.
	LandmarkAeParts.ball(lm, "Gold", Vector3(0, 35.9, 0), 1.2, 12, 6)
	lm.lathe("Gold", Vector3(0, 36.4, 0), PackedVector2Array([Vector2(0.6, 0), Vector2(0.4, 0.8),
		Vector2(0.05, 38.0 - 36.4)]), 8)
	lm.commit(model)

# --- Great Wall at Badaling ---

const WALL_HALF := 200.0
const WALL_TOWERS := [-165.0, -55.0, 55.0, 165.0]

static func great_wall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F8A82", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9C968C", 3.0))
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#5A5D60", 2.0))
	# Footing (below ground), rampart, paved walkway and the two parapets.
	lm.box("Stone", Vector3(0, -3.0, 0), Vector3(WALL_HALF * 2.0, 11.0, 7.8))
	lm.box("Brick", Vector3(0, 4.0, 0), Vector3(WALL_HALF * 2.0, 4.0, 6.8))
	lm.box("Stone", Vector3(0, 6.1, 0), Vector3(WALL_HALF * 2.0, 0.2, 5.6))
	lm.box("Brick", Vector3(0, 6.6, 3.0), Vector3(WALL_HALF * 2.0, 1.0, 0.6))
	lm.box("Brick", Vector3(0, 6.9, -3.0), Vector3(WALL_HALF * 2.0, 1.6, 0.8))
	var x := -WALL_HALF + 1.2
	while x < WALL_HALF - 1.0:
		lm.box("Brick", Vector3(x, 7.9, -3.0), Vector3(1.4, 0.9, 0.8))
		x += 2.4
	for tx in WALL_TOWERS:
		_tower(lm, float(tx))
	lm.commit(model)

## Two-storey watchtower astride the wall at x: pierced body, deck with
## merlons, small upper hall under a low tiled pyramid roof (12 m).
static func _tower(lm: LandmarkMesh, x: float) -> void:
	lm.box("Stone", Vector3(x, -3.0, 0), Vector3(12.4, 11.0, 12.4))
	lm.box("Brick", Vector3(x, 5.0, 0), Vector3(11.4, 9.2, 11.4))
	lm.box("Stone", Vector3(x, 9.75, 0), Vector3(12.0, 0.3, 12.0))
	for s in [-1.0, 1.0]:
		lm.box("Shadow", Vector3(x + s * 5.75, 7.6, 0), Vector3(0.12, 3.2, 3.0))
		for wz in [-2.4, 2.4]:
			lm.box("Shadow", Vector3(x + wz, 7.9, s * 5.75), Vector3(1.4, 1.9, 0.12))
		for i in 5:
			var o := -5.0 + 2.5 * i
			lm.box("Brick", Vector3(x + o, 10.4, s * 5.7), Vector3(1.0, 1.0, 0.7))
			lm.box("Brick", Vector3(x + s * 5.7, 10.4, o), Vector3(0.7, 1.0, 1.0))
	lm.box("Brick", Vector3(x, 10.4, 0), Vector3(6.0, 1.0, 6.0))
	lm.spire("Tile", Vector3(x, 10.9, 0), 4.3, 1.1, 0.3)

# --- Potala Palace ---

static func potala(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE8DE", 4.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#8E2F25", 4.0))
	lm.use("Maroon", LandmarkMaterials.paint("#5A2B22", 0.8, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	# Battered plinth and the two White Palace wings; rows of dark windows.
	LandmarkAeParts.batter(lm, "White", 0, 0, 330.0, 66.0, 306.0, 58.0, -25.0, 45.0)
	_windows(lm, 0.0, 140.0, [8.0, 19.0, 30.0, 41.0], Vector4(33.0, 29.0, -25.0, 45.0))
	for s in [-1.0, 1.0]:
		LandmarkAeParts.batter(lm, "White", s * 102.0, 0, 96.0, 50.0, 90.0, 46.0, 44.0, 80.0)
		lm.box("Maroon", Vector3(s * 102.0, 81.5, 0), Vector3(92.0, 3.0, 48.0))
		_windows(lm, s * 102.0, 40.0, [52.0, 62.0, 72.0], Vector4(25.0, 23.0, 44.0, 80.0))
	# Red Palace: white base course, red storeys, maroon parapet band.
	LandmarkAeParts.batter(lm, "White", 0, 0, 112.0, 52.0, 108.0, 50.0, 44.0, 62.0)
	LandmarkAeParts.batter(lm, "Red", 0, 0, 108.0, 50.0, 102.0, 46.0, 62.0, 96.0)
	lm.box("Maroon", Vector3(0, 99.0, 0), Vector3(106.0, 6.0, 48.0))
	lm.box("Red", Vector3(0, 104.5, 0), Vector3(84.0, 5.0, 36.0))
	_windows(lm, 0.0, 36.0, [68.0, 80.0, 90.0], Vector4(25.0, 23.0, 62.0, 96.0))
	# Gilded roofs: the great central one and a small pavilion at each end.
	LandmarkAeParts.hip_roof(lm, "Gold", Vector3(0, 107.0, 0), Vector2(64.0, 32.0), Vector2(34.0, 3.0), 8.0, 1.0)
	lm.box("Gold", Vector3(0, 115.4, 0), Vector3(36.0, 0.8, 1.4))
	for s in [-1.0, 1.0]:
		lm.box("Gold", Vector3(s * 17.0, 116.0, 0), Vector3(1.4, 2.0, 1.4))
		lm.box("Red", Vector3(s * 47.0, 103.5, 0), Vector3(10.0, 3.0, 10.0))
		LandmarkAeParts.hip_roof(lm, "Gold", Vector3(s * 47.0, 105.0, 0), Vector2(16.0, 16.0), Vector2(6.0, 2.0), 5.5, 0.8)
	lm.commit(model)

## A row of dark window boxes at each height on the battered south face;
## `face` = (z at the bottom, z at the top, bottom y, top y) of the wall.
static func _windows(lm: LandmarkMesh, cx: float, half: float, ys: Array, face: Vector4) -> void:
	for y in ys:
		var z := lerpf(face.x, face.y, (float(y) - face.z) / (face.w - face.z))
		var x := cx - half
		while x <= cx + half:
			lm.box("Shadow", Vector3(x, float(y), z), Vector3(2.0, 3.2, 0.3))
			x += 7.0
