class_name LandmarkAmhMaya
extends RefCounted

## Four Mesoamerican pyramids in true metres: the Pyramid of the Sun at
## Teotihuacan, the Temple of the Inscriptions with the Palace tower at
## Palenque, Tikal's Temple I and the oval Pyramid of the Magician at
## Uxmal. Stairways are built facing the way noted on each model and the
## registry yaw turns them onto the real bearing.

const SUN_TOP_M := 65.5
const INSCRIPTIONS_TOP_M := 27.2
const TIKAL_TOP_M := 47.0
const MAGICIAN_TOP_M := 35.0

## Heights of the five stepped bodies of the Pyramid of the Sun.
const SUN_TIERS := [16.0, 14.0, 13.0, 12.0, 10.5]

## Pyramid of the Sun: 223 m square at the foot and 65.5 m high, five
## sloped bodies of volcanic rubble under pale stucco cornices with a
## 9 m terrace between each, the broad stairway climbing the front
## (+Z) in a flight per body with its side balustrades, and the low
## Adosada platform at the foot. The temple that crowned it is lost.
static func sun_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A735F", 4.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#C9B898", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#A99880", 3.0))
	var bx := 112.5
	var bz := 111.0
	var y := 0.0
	lm.box("Stone", Vector3(0, -1.0, 0), Vector3(2.0 * bx + 4.0, 2.0, 2.0 * bz + 4.0))
	lm.box("Stone", Vector3(0, 1.6, bz + 9.0), Vector3(78.0, 3.2, 26.0))
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), 30.0, bz + 28.0, 0.0,
		bz + 22.0, 3.2, bz + 18.0, 8)
	for k in SUN_TIERS.size():
		var h: float = SUN_TIERS[k]
		var slope := h - 0.9
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, y, 0), slope, bx, bz, bx - slope,
			bz - slope, false)
		# Cornice lip flaring out of the top of the slope.
		LandmarkAmhParts.slab(lm, "Stucco", Vector3(0, y + slope, 0), 0.9, bx - slope,
			bz - slope, bx - slope + 0.35, bz - slope + 0.35)
		var w := 38.0 - 4.0 * float(k)
		var foot_z := bz + 0.15
		var foot_y := y
		if k == 0:
			foot_y = 3.2
			foot_z = bz - 3.2 + 0.15
		var n := int(round((y + h - foot_y) / 0.6))
		var head_z := bz - h + 1.4
		LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), w, foot_z, foot_y,
			head_z, y + h, head_z - 4.5, n)
		LandmarkAmhParts.rails(lm, "Stucco", Vector3.ZERO, Basis(), w, foot_z, foot_y,
			head_z, y + h - 0.2, 2.6, 1.6)
		bx = bx - slope + 0.35 - 9.4
		bz = bz - slope + 0.35 - 9.4
		y += h
	lm.commit(model)

## Temple of the Inscriptions: the eight-stepped pyramid (60 x 42.5 m)
## under the temple of five doorways between six stuccoed piers, its
## double-pitched mansard roof and perforated roof comb, 27.2 m above
## the plaza, with the stair facing north (-Z). Beside it stands the
## four-storey tower of the Palace on its platform to the north-east.
static func inscriptions(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B09A", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CBC2AA", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D5CBB0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#9E9580", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	var tiers := 8
	var pyr_h := INSCRIPTIONS_TOP_M - 9.4
	var th := pyr_h / float(tiers)
	var front := Basis(Vector3.UP, PI)
	lm.box("Stone", Vector3(0, -1.0, 0), Vector3(62.0, 2.0, 44.5))
	for k in tiers:
		var hx := 30.0 - 2.0 * float(k)
		var hz := 21.25 - 1.66 * float(k)
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, th * float(k), 0), th, hx, hz,
			hx - 0.35, hz - 0.35)
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, front, 9.6, 21.85, 0.0, 8.1, pyr_h, 5.0, 60)
	LandmarkAmhParts.rails(lm, "Stone", Vector3.ZERO, front, 9.6, 21.85, 0.0, 8.1, pyr_h, 1.8, 1.5)
	# Temple: five doorways, six piers with stucco relief, cornice, mansard.
	var tc := Vector3(0, pyr_h, 2.5)
	lm.box("Stone", tc + Vector3(0, 2.2, 0), Vector3(25.5, 4.4, 9.0))
	for i in 5:
		var x := -9.6 + 4.8 * float(i)
		LandmarkAmhParts.opening(lm, "Door", tc + Vector3(x, 1.75, -4.5), Basis(), 2.7, 3.5, 0.3)
	for i in 6:
		var x := -12.0 + 4.8 * float(i)
		lm.box("Stucco", tc + Vector3(x, 2.0, -4.55), Vector3(1.8, 3.4, 0.16))
	lm.box("Stucco", tc + Vector3(0, 4.6, 0), Vector3(26.4, 0.45, 9.9))
	LandmarkNaParts.hip(lm, "Roof", tc + Vector3(0, 4.8, 0), Basis(), 13.2, 4.95, 0.93, 1.7)
	LandmarkNaParts.hip(lm, "Roof", tc + Vector3(0, 6.5, 0), Basis(), 12.28, 4.6, 0.78, 1.0)
	lm.box("Stone", tc + Vector3(0, 8.45, 0), Vector3(18.5, 1.9, 0.9))
	for i in 5:
		lm.box("Door", tc + Vector3(-6.0 + 3.0 * float(i), 8.2, -0.4), Vector3(1.0, 1.0, 0.3))
	_palace_tower(lm, Vector3(38.0, 0, -64.0))
	lm.commit(model)

## The Palace platform corner with its gallery and the four-storey
## square tower (7.5 m platform, 14 m of tower, hipped crown).
static func _palace_tower(lm: LandmarkMesh, pc: Vector3) -> void:
	lm.box("Stone", pc + Vector3(0, 3.25, 0), Vector3(60.0, 8.5, 40.0))
	lm.box("Stucco", pc + Vector3(0, 7.65, 0), Vector3(61.0, 0.3, 41.0))
	for gz in [-12.0, 12.0]:
		lm.box("Stone", pc + Vector3(0, 9.7, gz), Vector3(46.0, 3.8, 6.5))
		lm.box("Stucco", pc + Vector3(0, 11.85, gz), Vector3(47.0, 0.5, 7.5))
		var out: float = 3.25 if gz > 0.0 else -3.25
		for i in 5:
			LandmarkAmhParts.opening(lm, "Door", pc + Vector3(-16.0 + 8.0 * float(i), 9.3,
				gz + out), Basis(), 2.2, 3.0, 0.3)
	var sizes := [8.0, 7.2, 6.4, 5.6]
	var y := 7.8
	for k in 4:
		var s: float = sizes[k]
		var tc := pc + Vector3(-4.0, y, 3.0)
		lm.box("Stone", tc + Vector3(0, 1.75, 0), Vector3(s, 3.5, s))
		lm.box("Stucco", tc + Vector3(0, 3.65, 0), Vector3(s + 0.8, 0.35, s + 0.8))
		for q in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(q))
			LandmarkAmhParts.opening(lm, "Door", tc + r * Vector3(0, 1.7, s * 0.5), r, 1.4, 2.1, 0.3)
		y += 3.5
	LandmarkNaParts.hip(lm, "Roof", pc + Vector3(-4.0, y + 0.35, 3.0), Basis(), 3.4, 3.4, 0.45, 1.9)

## Tikal, Temple I (Temple of the Great Jaguar): the nine-tiered
## pyramid (33 m) with its steep central stair, the one-doorway shrine
## and the tall stepped roof comb carrying the king's relief, to 47 m.
## Built facing +Z; the real stair faces west onto the Great Plaza.
static func tikal_temple_i(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8AE97", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#C8BFA8", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D3CAB1", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	var py := 33.0
	var th := py / 9.0
	lm.box("Stone", Vector3(0, -1.0, 0), Vector3(34.0, 2.0, 38.0))
	for k in 9:
		var hx := 16.0 - float(k)
		var hz := 18.0 - 1.33 * float(k)
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, th * float(k), 0), th, hx, hz,
			hx - 0.4, hz - 0.5)
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), 8.4, 18.7, 0.0, 6.2, py, 3.0, 66)
	LandmarkAmhParts.rails(lm, "Stone", Vector3.ZERO, Basis(), 8.4, 18.7, 0.0, 6.2, py, 1.8, 1.6)
	lm.box("Stone", Vector3(0, py + 0.45, -0.9), Vector3(13.8, 0.9, 10.4))
	var sc := Vector3(0, py + 0.9, -1.8)
	lm.box("Stone", sc + Vector3(0, 2.65, 0), Vector3(11.6, 5.3, 7.4))
	LandmarkAmhParts.opening(lm, "Door", sc + Vector3(0, 1.8, 3.7), Basis(), 2.3, 3.6, 0.3)
	lm.box("Stucco", sc + Vector3(0, 5.7, 0), Vector3(12.4, 0.8, 8.2))
	lm.box("Stone", sc + Vector3(0, 6.75, 0), Vector3(9.6, 1.3, 6.0))
	# Roof comb: three set-back stages, ribs between, king's relief on the front.
	lm.box("Stone", sc + Vector3(0, 8.45, 0), Vector3(8.6, 2.1, 3.6))
	lm.box("Stone", sc + Vector3(0, 10.5, 0), Vector3(7.4, 2.0, 3.0))
	lm.box("Stone", sc + Vector3(0, 12.3, 0), Vector3(6.2, 1.6, 2.4))
	lm.box("Stucco", sc + Vector3(0, 9.5, 0), Vector3(9.4, 0.3, 4.2))
	lm.box("Stucco", sc + Vector3(0, 11.5, 0), Vector3(8.2, 0.3, 3.6))
	lm.box("Stucco", sc + Vector3(0, 9.6, 1.85), Vector3(4.2, 3.6, 0.3))
	for s in [-1.0, 1.0]:
		lm.box("Stucco", sc + Vector3(s * 3.4, 8.45, 1.9), Vector3(0.9, 2.0, 0.2))
	lm.commit(model)

## Pyramid of the Magician: the 35 m elliptical pyramid (69 x 49 m),
## five rounded bodies with their ledges, the steep west stair (+Z)
## to the Chenes temple with its Chaac-mask doorway, the summit
## temple with its roof comb above, and the east stair to the lower
## temple. Built with the stair facing +Z; yaw turns it onto the
## solstice-sunset bearing.
static func magician(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C5B99D", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D0C6AB", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D9CFB4", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	# Outer radius along the long axis (Z) of each body: foot, top, height.
	var bodies := [[34.5, 31.9, 6.5], [29.9, 27.3, 6.5], [25.3, 22.7, 6.5], [20.7, 18.5, 5.5],
		[16.5, 14.9, 4.0]]
	var outer := PackedVector2Array()
	var squash := 24.5 / 34.5
	lm.frustum("Stone", Vector3(0, -2.0, 0), 35.5, 34.5, 2.0, 56, 0.0, squash, 1.0)
	var y := 0.0
	for b in bodies:
		lm.frustum("Stone", Vector3(0, y, 0), b[0], b[1], b[2], 56, 0.0, squash, 1.0)
		outer.append(Vector2(b[0], y))
		outer.append(Vector2(b[1], y + float(b[2])))
		y += float(b[2])
	# West stair to the Chenes temple (y 26), east stair to the lower temple (y 22).
	var back := Basis(Vector3.UP, PI)
	LandmarkAmhParts.stair_hug(lm, "Steps", Vector3.ZERO, Basis(), 7.0, outer, 0.0, 26.0, 58,
		9.0, 0.45, 1.4, "Stone")
	LandmarkAmhParts.stair_hug(lm, "Steps", Vector3.ZERO, back, 6.0, outer, 0.0, 22.0, 50,
		9.0, 0.45, 1.2, "Stone")
	# Chenes temple: Chaac-mask doorway, fret rows, cornice.
	var fz := 14.5
	lm.box("Stone", Vector3(0, 25.5, 12.4), Vector3(9.4, 1.0, 7.4))
	lm.box("Stone", Vector3(0, 28.6, fz - 2.6), Vector3(8.8, 5.2, 5.2))
	lm.box("Stucco", Vector3(0, 28.3, fz + 0.1), Vector3(6.2, 4.6, 0.4))
	LandmarkAmhParts.opening(lm, "Door", Vector3(0, 27.5, fz + 0.35), Basis(), 2.2, 3.0, 0.3)
	lm.box("Stucco", Vector3(0, 30.3, fz + 0.3), Vector3(3.2, 1.4, 0.7))
	for s in [-1.0, 1.0]:
		lm.box("Stucco", Vector3(s * 1.5, 29.6, fz + 0.3), Vector3(0.9, 0.9, 0.6))
		lm.box("Stucco", Vector3(s * 3.5, 28.3, fz + 0.2), Vector3(0.8, 4.4, 0.4))
		for j in 2:
			lm.box("Stucco", Vector3(s * (2.5 + 0.9 * float(j)), 30.6, fz + 0.1), Vector3(0.7, 0.7, 0.3))
	for j in 7:
		lm.box("Stone", Vector3(-3.9 + 1.3 * float(j), 31.0, fz + 0.1), Vector3(0.9, 0.5, 0.3))
	lm.box("Stucco", Vector3(0, 31.45, fz - 2.6), Vector3(9.6, 0.5, 6.0))
	# Summit temple with its roof comb.
	lm.box("Stone", Vector3(0, 31.0, -4.0), Vector3(9.0, 4.0, 5.4))
	LandmarkAmhParts.opening(lm, "Door", Vector3(0, 30.3, -1.3), Basis(), 2.0, 2.6, 0.3)
	lm.box("Stucco", Vector3(0, 33.25, -4.0), Vector3(9.8, 0.5, 6.2))
	lm.box("Stone", Vector3(0, 34.25, -4.0), Vector3(7.2, 1.5, 0.9))
	# Lower east temple.
	lm.box("Stone", Vector3(0, 21.5, -17.4), Vector3(8.0, 1.0, 5.5))
	lm.box("Stone", Vector3(0, 23.8, -17.5), Vector3(7.2, 3.6, 3.6))
	LandmarkAmhParts.opening(lm, "Door", Vector3(0, 23.3, -19.3), back, 1.8, 2.4, 0.3)
	lm.box("Stucco", Vector3(0, 25.8, -17.5), Vector3(7.8, 0.4, 4.2))
	lm.commit(model)
