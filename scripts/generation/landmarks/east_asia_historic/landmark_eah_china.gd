class_name LandmarkEahChina
extends RefCounted

## Historic China in true metres: Tiananmen (33.7 m: the 66 x 37 m red
## gate platform pierced by five arched doorways under the nine-bay
## double-eave hall with yellow glazed roofs, and the marble huabiao
## columns), the Tower of Buddhist Incense at the Summer Palace (61 m:
## the octagonal three-eave tower, 41 m, on its 20 m terraced stone
## platform) and the Leshan Giant Buddha (71 m: the seated Maitreya
## carved out of the red cliff, river level at y = 0). Fronts face south
## (+Z); the Buddha's front is turned onto the river by yaw_deg.

# --- Tiananmen ---

const TIAN_M := 33.7
## Doorways [x, width, height] of the gate platform.
const TIAN_ARCHES := [[-25.4, 4.6, 7.4], [-12.7, 4.6, 7.4], [0.0, 5.5, 8.8], [12.7, 4.6, 7.4],
	[25.4, 4.6, 7.4]]

static func tiananmen(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E0D6", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#9E3328", 4.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#A82E26", 0.65, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D9A52C", 2.0, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	# Gate platform 10 m: wall segments between the five doorways, each
	# door a square passage under a dark half-round on both faces.
	var x0 := -33.0
	for a in TIAN_ARCHES:
		var ax := float(a[0])
		var aw := float(a[1])
		var ah := float(a[2])
		var spring := ah - aw * 0.5
		var left := ax - aw * 0.5
		lm.box("Wall", Vector3((x0 + left) * 0.5, 5.0, 0), Vector3(left - x0, 10.0, 37.0))
		lm.box("Wall", Vector3(ax, (spring + 10.0) * 0.5, 0), Vector3(aw, 10.0 - spring, 37.0))
		for s in [-1.0, 1.0]:
			lm.disc("Shadow", Vector3(ax, spring, s * 18.53), Vector3(0, 0, s), aw * 0.5, 16)
		lm.box("Shadow", Vector3(ax, 0.02, 0), Vector3(aw, 0.04, 37.0))
		x0 = ax + aw * 0.5
	lm.box("Wall", Vector3((x0 + 33.0) * 0.5, 5.0, 0), Vector3(33.0 - x0, 10.0, 37.0))
	# Marble cornice and balustrade round the platform top.
	lm.box("Marble", Vector3(0, 10.0, 0), Vector3(67.2, 0.6, 38.2))
	var y0 := 10.3
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, y0 + 0.55, s * 18.2), Vector3(66.0, 1.1, 0.5))
		lm.box("Marble", Vector3(s * 32.8, y0 + 0.55, 0), Vector3(0.5, 1.1, 36.0))
	# Lower storey: red core ringed by columns, dark door bays, blue-green
	# bracket band.
	LandmarkEahParts.colonnade(lm, "Lacquer", Vector2.ZERO, Vector2(58.0, 28.8), y0, 7.6, 9, 4, 0.42)
	lm.box("Lacquer", Vector3(0, y0 + 3.8, 0), Vector3(54.4, 7.6, 25.2))
	for s in [-1.0, 1.0]:
		for i in 9:
			lm.box("Shadow", Vector3(-24.2 + 6.05 * i, y0 + 2.6, s * 12.66), Vector3(3.0, 4.6, 0.12))
	lm.box("Bracket", Vector3(0, y0 + 8.1, 0), Vector3(60.0, 1.0, 30.0))
	# Skirt roof, upper storey and the hip-and-gable roof.
	LandmarkAeParts.hip_roof(lm, "Roof", Vector3(0, y0 + 8.6, 0), Vector2(65.0, 34.0), Vector2(54.0, 22.0), 3.2, 1.0)
	var y1 := y0 + 11.8
	LandmarkEahParts.colonnade(lm, "Lacquer", Vector2.ZERO, Vector2(54.0, 22.0), y1, 3.8, 9, 3, 0.38)
	lm.box("Lacquer", Vector3(0, y1 + 1.9, 0), Vector3(52.0, 3.8, 20.0))
	lm.box("Bracket", Vector3(0, y1 + 4.25, 0), Vector3(55.5, 0.9, 23.5))
	var y2 := y1 + 4.7
	LandmarkEahParts.irimoya(lm, "Roof", "Wall", Vector3(0, y2, 0), Vector2(61.0, 30.0),
		Vector2(40.0, 9.0), 2.8, 2.6, 1.0)
	var ridge := y2 + 5.4
	lm.box("Roof", Vector3(0, ridge + 0.2, 0), Vector3(40.0, 0.4, 1.6))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.horn(lm, "Gold", Vector3(s * 20.0, ridge, 0), TIAN_M - ridge, -s, 0.5)
	# Marble huabiao: octagonal column, cloud plate, crowning beast.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_huabiao(lm, Vector3(sx * 22.0, 0, sz * 36.0))
	lm.commit(model)

static func _huabiao(lm: LandmarkMesh, at: Vector3) -> void:
	LandmarkEahParts.slab(lm, "Marble", at + Vector3(-1.7, -0.5, -1.7), at + Vector3(1.7, 0.8, 1.7))
	LandmarkEahParts.slab(lm, "Marble", at + Vector3(-1.2, 0.8, -1.2), at + Vector3(1.2, 1.6, 1.2))
	lm.frustum("Marble", at + Vector3(0, 1.6, 0), 0.56, 0.48, 6.5, 8, PI / 8.0)
	lm.box("Marble", at + Vector3(0, 8.25, 0), Vector3(0.5, 0.3, 4.4))
	lm.lathe("Marble", at + Vector3(0, 8.4, 0), PackedVector2Array([Vector2(0.75, 0), Vector2(0.75, 0.3),
		Vector2(0.4, 0.75), Vector2(0.3, 1.17)]), 10)

# --- Tower of Buddhist Incense ---

const INCENSE_M := 61.0

static func incense_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A9A395", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E0D6", 3.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#9A2B22", 0.65, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D9A52C", 2.0, 0.35))
	lm.use("Green", LandmarkMaterials.pbr("terracotta", "#2F7A58", 2.0, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	# Terraced platform (20 m): battered stone, marble cornice and ledge
	# balustrade, upper battered stage, marble terrace, central stair.
	LandmarkAeParts.batter(lm, "Stone", 0, 0, 66.0, 42.0, 58.0, 36.0, -1.0, 7.0)
	LandmarkEahParts.slab(lm, "Marble", Vector3(-29.5, 7.0, -18.5), Vector3(29.5, 7.6, 18.5))
	LandmarkAeParts.batter(lm, "Stone", 0, 0, 50.0, 30.0, 44.0, 26.0, 7.6, 17.0)
	LandmarkEahParts.slab(lm, "Marble", Vector3(-22.5, 17.0, -14.5), Vector3(22.5, 17.8, 14.5))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, 8.05, s * 18.2), Vector3(59.0, 0.9, 0.4))
		lm.box("Marble", Vector3(s * 29.3, 8.05, 0), Vector3(0.4, 0.9, 36.0))
		lm.box("Marble", Vector3(0, 18.25, s * 14.2), Vector3(45.0, 0.9, 0.4))
		lm.box("Marble", Vector3(s * 22.3, 18.25, 0), Vector3(0.4, 0.9, 29.0))
	LandmarkEahParts.stairs(lm, "Stone", 0.0, 26.0, 0.0, 8.0, 34, 0.5, 0.38)
	lm.frustum("Marble", Vector3(0, 17.8, 0), 15.0, 14.2, 2.2, 8, PI / 8.0)
	# Tower, 41 m on the platform: red octagonal storeys [radius, height]
	# under three yellow roofs [eave radius, top radius, rise].
	var y := 20.0
	var bodies := [[9.8, 8.5], [7.4, 5.5], [5.6, 5.0]]
	var roofs := [[17.0, 8.2, 5.2], [13.0, 6.4, 4.6], [9.6, 0.9, 7.0]]
	for t in 3:
		var r: float = bodies[t][0]
		var h: float = bodies[t][1]
		lm.frustum("Lacquer", Vector3(0, y, 0), r, r, h, 8, PI / 8.0)
		var apothem := r * cos(PI / 8.0)
		for k in 8:
			var ang := PI * 0.25 * k
			var n := Vector3(cos(ang), 0, sin(ang))
			lm.box("Shadow", n * (apothem + 0.05) + Vector3(0, y + h * 0.5, 0),
				Vector3(r * 0.26, h * 0.58, 0.14), Basis(Vector3.UP, PI * 0.5 - ang))
		if t == 0:
			for k in 16:
				var col_r := 12.2 if k % 2 == 1 else 12.2 * cos(PI / 8.0)
				var ang := TAU * k / 16.0
				LandmarkEahParts.column(lm, "Lacquer", Vector3(col_r * cos(ang), y, col_r * sin(ang)), h - 0.2, 0.45)
		y += h
		lm.frustum("Bracket", Vector3(0, y, 0), r + 3.2 - t, r + 3.2 - t, 0.8, 8, PI / 8.0)
		y += 0.8
		var re: float = roofs[t][0]
		var rt: float = roofs[t][1]
		var rise: float = roofs[t][2]
		var prof := PackedVector2Array([Vector2(re + 0.6, 0.5), Vector2(re, 0.0),
			Vector2(lerpf(re, rt, 0.45), rise * 0.28), Vector2(lerpf(re, rt, 0.8), rise * 0.62), Vector2(rt, rise)])
		lm.lathe("Roof", Vector3(0, y, 0), prof, 8, 1.0, 1.0, PI / 8.0, false)
		var edge := prof[1].lerp(prof[2], 0.22)
		lm.lathe("Green", Vector3(0, y + 0.06, 0), PackedVector2Array([prof[0], prof[1], edge]), 8,
			1.0, 1.0, PI / 8.0, false, false)
		y += rise
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(1.0, 0.5),
		Vector2(0.7, 1.1), Vector2(0.25, 1.6), Vector2(0.12, INCENSE_M - y)]), 10)
	lm.commit(model)

# --- Leshan Giant Buddha ---

const LESHAN_M := 71.0

static func leshan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7A5B46", 6.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8A688", 3.0))
	lm.use("Hair", LandmarkMaterials.pbr("rock", "#5B4B3D", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#2A231C", 0.9, 0.0))
	# The red sandstone cliff: back wall of the niche (top level with the
	# crown) and two stepped flanks coming forward either side.
	LandmarkEahParts.slab(lm, "Rock", Vector3(-22.0, -8.0, -48.0), Vector3(22.0, 70.0, -4.0))
	var tiers := [[22.0, 10.0, -8.0, 44.0], [24.0, -2.0, 44.0, 58.0], [30.0, -14.0, 58.0, 66.0]]
	for s in [-1.0, 1.0]:
		for t in tiers:
			var xi: float = float(t[0]) * s
			LandmarkEahParts.slab(lm, "Rock", Vector3(minf(xi, 56.0 * s), float(t[2]), -48.0),
				Vector3(maxf(xi, 56.0 * s), float(t[3]), float(t[1])))
	# Legs: feet at the water, vertical shins, horizontal thighs.
	for s in [-1.0, 1.0]:
		var x: float = s * 8.6
		lm.box("Stone", Vector3(x, 1.6, 27.5), Vector3(8.5, 3.4, 11.0))
		for toe in 5:
			lm.box("Stone", Vector3(x + (toe - 2) * 1.55, 1.2, 33.2), Vector3(1.3, 2.4, 1.6))
		LandmarkAeParts.batter(lm, "Stone", x, 23.0, 8.6, 6.0, 10.2, 8.0, 3.0, 24.0)
		lm.box("Stone", Vector3(x, 26.5, 15.0), Vector3(10.8, 7.0, 25.0))
	# Torso (28 m across the shoulders), neck.
	var torso := PackedVector2Array([Vector2(11.5, 0), Vector2(12.2, 6.0), Vector2(12.8, 14.0),
		Vector2(13.6, 24.0), Vector2(14.0, 29.5), Vector2(11.0, 31.0), Vector2(6.0, 32.0), Vector2(3.6, 32.5)])
	lm.lathe("Stone", Vector3(0, 24.0, 3.0), torso, 24, 1.0, 0.52)
	lm.frustum("Stone", Vector3(0, 56.0, 4.0), 3.6, 3.2, 1.4, 12)
	# Arms: upper arm down the flank, forearm forward, hand flat on the knee.
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(s * 13.2, 53.5, 3.0), Vector3(s * 13.6, 38.5, 5.5), 4.8, 5.2, Vector3(1, 0, 0))
		lm.beam("Stone", Vector3(s * 13.4, 38.5, 5.5), Vector3(s * 10.5, 32.5, 20.0), 4.2, 4.2, Vector3(1, 0, 0))
		lm.box("Stone", Vector3(s * 10.2, 31.3, 24.2), Vector3(4.6, 2.4, 8.3))
	# Head 14.7 m high (10 m wide): face ellipsoid, hair cap of 1,021 curls,
	# crowning bun, long ears, nose, brows, eyes, mouth.
	var face := PackedVector2Array()
	for j in 11:
		var phi := PI * float(j) / 10.0
		face.append(Vector2(5.0 * sin(phi), -5.2 * cos(phi)))
	lm.lathe("Stone", Vector3(0, 61.4, 4.2), face, 20, 1.0, 1.08)
	var cap := PackedVector2Array()
	for j in 6:
		var a := PI * 0.5 * float(j) / 5.0
		cap.append(Vector2(5.2 * cos(a), 5.0 * sin(a)))
	lm.lathe("Hair", Vector3(0, 64.6, 4.2), cap, 20, 1.0, 1.08)
	lm.lathe("Hair", Vector3(0, 69.4, 4.2), PackedVector2Array([Vector2(2.6, 0), Vector2(2.3, 0.8),
		Vector2(1.2, 1.4), Vector2(0.0, LESHAN_M - 69.4)]), 14)
	for row in 4:
		var hy := 65.2 + 1.4 * row
		var hr := 5.2 * sqrt(maxf(1.0 - pow((hy - 64.6) / 5.0, 2.0), 0.05))
		var count := int(TAU * hr / 1.7)
		for k in count:
			var a := TAU * (float(k) + 0.5 * (row % 2)) / count
			LandmarkAeParts.ball(lm, "Hair", Vector3(hr * 0.97 * cos(a), hy, 4.2 + 1.08 * hr * 0.97 * sin(a)), 0.78, 8, 4)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 5.5, 60.0, 4.5), Vector3(1.3, 7.0, 1.7))
		lm.box("Shadow", Vector3(s * 2.6, 62.3, 9.4), Vector3(3.3, 0.5, 0.4))
		lm.box("Stone", Vector3(s * 2.6, 63.4, 9.4), Vector3(3.8, 0.5, 0.7))
	lm.box("Stone", Vector3(0, 60.4, 9.9), Vector3(1.4, 4.4, 1.8))
	lm.box("Shadow", Vector3(0, 58.0, 8.6), Vector3(3.3, 0.45, 0.4))
	lm.commit(model)
