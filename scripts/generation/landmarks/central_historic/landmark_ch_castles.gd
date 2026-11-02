class_name LandmarkChCastles
extends RefCounted

## Three old strongholds of the Rhine and Salzburg in true metres:
## Heidelberg Castle (red-sandstone ruin round its courtyard on a deep
## foundation), Hohensalzburg Fortress (white walls, the Hoher Stock
## and the Reckturm on the rock) and the Porta Nigra of Trier (dark
## Roman gate, field side with the round towers toward -Z, 29.6 m).

# --- Heidelberg Castle ---

const HEIDELBERG_TOP := 34.5

static func heidelberg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A86A52", 3.0))
	lm.use("Ruin", LandmarkMaterials.pbr("stone", "#8A5E4C", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#C79A7C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#58505A", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#7A6C5C", 4.0))
	# Deep foundation of the terraced hillside.
	var rock := PackedVector2Array([Vector2(-38, -38), Vector2(40, -38), Vector2(42, 34), Vector2(-38, 36)])
	lm.poly_prism("Rock", rock, -14.0, 0.0, false)
	# Friedrichsbau: north range under its steep slate roof, three gables.
	lm.box("Stone", Vector3(0, 11.0, -22.0), Vector3(40.0, 22.0, 14.0))
	lm.gable("Roof", Vector3(0, 22.0, -22.0), 14.0, 40.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	LandmarkChParts.band(lm, "Pale", 11.0, 20.0, 7.0, 0.6, 0.3, Vector3(0, 0, -22.0))
	for r in 4:
		LandmarkCeParts.windows(lm, "Windows", Vector3(0, 4.0 + 5.0 * r, -14.9), Vector3(1, 0, 0), 8, 4.6,
			Vector3(1.8, 2.8, 0.2))
		LandmarkCeParts.windows(lm, "Windows", Vector3(0, 4.0 + 5.0 * r, -29.1), Vector3(1, 0, 0), 8, 4.6,
			Vector3(1.8, 2.8, 0.2))
	for x in [-12.0, 0.0, 12.0]:
		lm.box("Pale", Vector3(x, 26.5, -15.5), Vector3(5.0, 9.0, 3.0))
		lm.gable("Roof", Vector3(x, 31.0, -15.5), 5.0, 3.0, HEIDELBERG_TOP - 31.0, Basis(), 0.2, "Pale")
		LandmarkCeParts.windows(lm, "Windows", Vector3(x, 26.5, -13.9), Vector3(1, 0, 0), 1, 1.0, Vector3(1.4, 2.6, 0.2))
	# Ottheinrichsbau: roofless Renaissance shell with its ornate east front.
	lm.box("Stone", Vector3(-20.0, 13.0, 1.0), Vector3(12.0, 26.0, 32.0))
	_jagged(lm, "Ruin", Vector3(-26.0, 26.0, -15.0), Vector3(-26.0, 26.0, 17.0), 1.6)
	_jagged(lm, "Ruin", Vector3(-14.0, 26.0, -15.0), Vector3(-14.0, 26.0, 17.0), 1.6)
	lm.box("Pale", Vector3(-13.5, 6.0, 1.0), Vector3(1.0, 12.0, 6.0))
	for r in 4:
		LandmarkCeParts.windows(lm, "Windows", Vector3(-13.9, 4.0 + 6.0 * r, 1.0), Vector3(0, 0, 1), 7, 4.2,
			Vector3(0.2, 3.2, 1.8))
		if r > 0:
			LandmarkChParts.band(lm, "Pale", 6.0 * r - 0.2, 6.0, 16.0, 0.4, 0.2, Vector3(-20.0, 0, 1.0))
	LandmarkCeParts.windows(lm, "Windows", Vector3(-13.9, 14.0, 1.0), Vector3(0, 0, 1), 2, 2.4, Vector3(0.2, 3.4, 1.0))
	# Gläserner Saalbau on the east side, also roofless.
	lm.box("Ruin", Vector3(24.0, 10.0, 0.0), Vector3(10.0, 20.0, 26.0))
	_jagged(lm, "Ruin", Vector3(19.0, 20.0, -13.0), Vector3(19.0, 20.0, 13.0), 1.4)
	_jagged(lm, "Ruin", Vector3(29.0, 20.0, -13.0), Vector3(29.0, 20.0, 13.0), 1.4)
	for r in 3:
		LandmarkCeParts.windows(lm, "Windows", Vector3(18.9, 5.0 + 5.5 * r, 0), Vector3(0, 0, 1), 6, 4.0,
			Vector3(0.2, 3.2, 1.8))
	# Gate tower with its hip roof, bell tower and the two round towers.
	var gt := Vector3(-28.0, 0, 26.0)
	lm.box("Stone", gt + Vector3(0, 12.0, 0), Vector3(9.0, 24.0, 9.0))
	LandmarkCeParts.hip(lm, "Roof", gt + Vector3(0, 24.0, 0), 10.0, 10.0, 10.0)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", gt + b * Vector3(0, 6.0, 4.5), 1, 1.0, 1.4, 3.0, b, false)
		LandmarkChParts.row(lm, "Windows", gt + b * Vector3(0, 15.0, 4.5), 1, 1.0, 1.4, 3.0, b, false)
	var bell := Vector3(24.0, 0, 20.0)
	lm.frustum("Stone", bell, 5.4, 5.0, 28.0, 8, PI / 8.0)
	_jagged_ring(lm, "Ruin", bell + Vector3(0, 28.0, 0), 5.0, 8)
	var fat := Vector3(-26.0, 0, -30.0)
	lm.frustum("Stone", fat, 8.0, 8.0, 22.0, 16)
	lm.frustum("Ruin", fat + Vector3(0, 22.0, 0), 8.6, 8.6, 1.2, 16)
	# The blown-up tower: a thick ring torn open on the courtyard side.
	var c := Vector2(29.5, -26.0)
	var ring := PackedVector2Array()
	for a in range(120, 421, 20):
		ring.append(c + Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a)))) * 10.5)
	for a in range(420, 119, -20):
		ring.append(c + Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a)))) * 4.5)
	lm.poly_prism("Ruin", ring, 0.0, 22.0)
	# Curtain wall closing the terrace.
	var wall_pts := [Vector3(-36, 0, -36), Vector3(38, 0, -36), Vector3(40, 0, 32), Vector3(-36, 0, 34)]
	for i in 4:
		LandmarkChParts.wall(lm, "Stone", wall_pts[i], wall_pts[(i + 1) % 4], 0.0, 6.0, 2.0)
	lm.commit(model)

## Broken wall top: boxes of changing height along a line, `thick` through.
static func _jagged(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, thick: float) -> void:
	var n := maxi(int(a.distance_to(b) / 2.6), 1)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	for i in n:
		var h := 0.8 + float((i * 5) % 4) * 0.9
		lm.box(key, a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, h * 0.5, 0), Vector3(2.6, h, thick), basis)

## Broken rim round a tower top: alternating teeth on a circle.
static func _jagged_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, count: int) -> void:
	for i in count:
		var a := TAU * float(i) / float(count)
		var h := 0.8 + float((i * 5) % 3) * 1.1
		lm.box(key, c + Vector3(cos(a) * r, h * 0.5, sin(a) * r), Vector3(2.0, h, 1.4), Basis(Vector3.UP, -a))

# --- Hohensalzburg Fortress ---

const SALZBURG_TOP := 48.0

static func hohensalzburg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E0D6BE", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#8A8272", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A24A32", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rock := PackedVector2Array([Vector2(-66, -18), Vector2(-44, -30), Vector2(8, -29), Vector2(50, -30),
		Vector2(68, -16), Vector2(70, 6), Vector2(50, 25), Vector2(0, 31), Vector2(-40, 27), Vector2(-64, 12)])
	lm.poly_prism("Rock", rock, -16.0, 0.0, false)
	# Curtain walls round the whole rock with a projecting cornice.
	for i in rock.size():
		var p := Vector3(rock[i].x, 0, rock[i].y)
		var q := Vector3(rock[(i + 1) % rock.size()].x, 0, rock[(i + 1) % rock.size()].y)
		LandmarkChParts.wall(lm, "Plaster", p, q, 0.0, 11.0, 2.4)
		LandmarkChParts.wall(lm, "Rock", p, q, 11.0, 11.8, 3.2)
	# Round bastion towers at four corners of the circuit.
	for k in [[0, 20.0, 8.0], [3, 18.0, 8.0], [5, 22.0, 9.0], [7, 17.0, 7.0]]:
		var v: Vector2 = rock[int(k[0])]
		var p := Vector3(v.x, 0, v.y)
		var h: float = k[1]
		lm.frustum("Plaster", p, 4.8, 4.6, h, 12)
		lm.frustum("Rock", p + Vector3(0, h, 0), 5.3, 5.3, 0.9, 12)
		lm.lathe("Roof", p + Vector3(0, h + 0.9, 0), PackedVector2Array([Vector2(5.5, 0), Vector2(4.6, 0.8),
			Vector2(2.4, float(k[2]) * 0.6), Vector2(0.2, float(k[2]))]), 12)
	# Hoher Stock: the great residence with its corner turrets and hip roof.
	var hs := Vector3(20.0, 0, -8.0)
	lm.box("Plaster", hs + Vector3(0, 15.0, 0), Vector3(36.0, 30.0, 20.0))
	LandmarkChParts.band(lm, "Rock", 29.5, 18.0, 10.0, 0.8, 0.5, hs)
	LandmarkCeParts.hip(lm, "Roof", hs + Vector3(0, 30.0, 0), 37.0, 21.0, 11.0)
	for r in 5:
		LandmarkCeParts.windows(lm, "Windows", hs + Vector3(0, 6.0 + 5.2 * r, 10.1), Vector3(1, 0, 0), 9, 3.8,
			Vector3(1.4, 2.4, 0.2))
		LandmarkCeParts.windows(lm, "Windows", hs + Vector3(0, 6.0 + 5.2 * r, -10.1), Vector3(1, 0, 0), 9, 3.8,
			Vector3(1.4, 2.4, 0.2))
	for sz in [-1.0, 1.0]:
		var p := hs + Vector3(-18.0, 0, sz * 10.0)
		lm.frustum("Plaster", p, 3.2, 3.0, 32.0, 10)
		lm.lathe("Roof", p + Vector3(0, 32.0, 0), PackedVector2Array([Vector2(3.8, 0), Vector2(3.2, 0.8),
			Vector2(1.6, 5.0), Vector2(0.15, 9.0)]), 10)
	# Reckturm at the east end with its pyramid cap and gilt finial.
	var rt := Vector3(44.0, 0, -8.0)
	lm.box("Plaster", rt + Vector3(0, 17.0, 0), Vector3(8.0, 34.0, 8.0))
	LandmarkChParts.band(lm, "Rock", 30.0, 4.0, 4.0, 0.8, 0.4, rt)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", rt + b * Vector3(0, 22.0, 4.0), 1, 1.0, 1.0, 2.6, b, false)
		LandmarkChParts.row(lm, "Windows", rt + b * Vector3(0, 12.0, 4.0), 1, 1.0, 0.8, 2.0, b, false)
	lm.spire("Roof", rt + Vector3(0, 34.0, 0), 4.6, 12.0, 0.0, 4)
	LandmarkChParts.finial(lm, "Gilt", rt + Vector3(0, 46.0, 0), SALZBURG_TOP - 46.0, 0.5)
	# St George's church with its small tower, the bell tower and the arsenal.
	lm.box("Plaster", Vector3(-14.0, 8.0, -6.0), Vector3(22.0, 16.0, 12.0))
	lm.gable("Roof", Vector3(-14.0, 16.0, -6.0), 12.0, 22.0, 8.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	var ct := Vector3(-27.0, 0, -6.0)
	lm.box("Plaster", ct + Vector3(0, 13.0, 0), Vector3(6.0, 26.0, 6.0))
	lm.spire("Roof", ct + Vector3(0, 26.0, 0), 3.4, 8.0, 0.0, 8)
	LandmarkChParts.row(lm, "Windows", Vector3(-14.0, 6.0, 0.1), 4, 4.8, 1.4, 5.0)
	var bt := Vector3(-48.0, 0, 8.0)
	lm.frustum("Plaster", bt, 4.8, 4.5, 24.0, 12)
	lm.lathe("Roof", bt + Vector3(0, 24.0, 0), PackedVector2Array([Vector2(5.3, 0), Vector2(4.5, 0.8),
		Vector2(2.2, 6.0), Vector2(0.2, 10.0)]), 12)
	lm.box("Plaster", Vector3(-26.0, 7.0, 15.0), Vector3(26.0, 14.0, 8.0))
	lm.gable("Roof", Vector3(-26.0, 14.0, 15.0), 8.0, 26.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	LandmarkChParts.row(lm, "Windows", Vector3(-26.0, 5.0, 19.1), 6, 4.0, 1.4, 2.6, Basis(), false)
	# Barrack ranges along the south wall and in the north and east wards.
	lm.box("Plaster", Vector3(26.0, 7.0, 16.0), Vector3(50.0, 14.0, 9.0))
	lm.gable("Roof", Vector3(26.0, 14.0, 16.0), 9.0, 50.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	LandmarkChParts.row(lm, "Windows", Vector3(26.0, 5.0, 20.6), 11, 4.2, 1.4, 2.6, Basis(), false)
	lm.box("Plaster", Vector3(-34.0, 6.0, -21.0), Vector3(28.0, 12.0, 8.0))
	lm.gable("Roof", Vector3(-34.0, 12.0, -21.0), 8.0, 28.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	lm.box("Plaster", Vector3(57.0, 6.0, -2.0), Vector3(14.0, 12.0, 16.0))
	lm.gable("Roof", Vector3(57.0, 12.0, -2.0), 14.0, 16.0, 5.0, Basis(), 0.5, "Plaster")
	LandmarkChParts.row(lm, "Windows", Vector3(-34.0, 5.0, -16.9), 6, 4.2, 1.4, 2.6, Basis(), false)
	lm.commit(model)

# --- Porta Nigra, Trier ---

const PORTA_TOP := 29.6

static func porta_nigra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6D645A", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4F4940", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	# Gate block: two piers and a centre pier leave two 3.2 m passages.
	var top := 21.0
	for x in [-4.5, 0.0, 4.5]:
		lm.box("Stone", Vector3(x, top * 0.5, 3.375), Vector3(1.0 if x != 0.0 else 1.6, top, 14.75))
	lm.box("Stone", Vector3(0, (5.0 + top) * 0.5, 3.375), Vector3(10.0, top - 5.0, 14.75))
	lm.box("Dark", Vector3(0, top + 0.4, 3.375), Vector3(10.8, 0.8, 15.55))
	for sx in [-1.0, 1.0]:
		LandmarkChParts.round_arch(lm, "Windows", Vector3(sx * 2.4, 5.0, -4.0), 3.2, 1.8, Basis(Vector3.UP, PI))
		LandmarkChParts.round_arch(lm, "Windows", Vector3(sx * 2.4, 5.0, 10.75), 3.2, 1.8)
	for y in [8.0, 14.5]:
		LandmarkChParts.row(lm, "Windows", Vector3(0, y, -4.0), 4, 2.4, 1.6, 3.6, Basis(Vector3.UP, PI), false)
		LandmarkChParts.row(lm, "Windows", Vector3(0, y, 10.75), 4, 2.4, 1.6, 3.6, Basis(), false)
	# The field towers: rectangular behind, semicircular in front, the
	# east one a storey higher.
	for sx in [-1.0, 1.0]:
		var h := PORTA_TOP - 0.8 if sx > 0.0 else 26.2
		var cx: float = sx * 11.5
		lm.box("Stone", Vector3(cx, h * 0.5, 3.5), Vector3(13.0, h, 14.5))
		lm.frustum("Stone", Vector3(cx, 0, -3.75), 6.5, 6.5, h, 24)
		lm.box("Dark", Vector3(cx, h + 0.4, 3.5), Vector3(13.8, 0.8, 15.3))
		lm.frustum("Dark", Vector3(cx, h, -3.75), 6.9, 6.9, 0.8, 24)
		var levels: Array[float] = [8.0, 14.5, 21.0]
		if sx > 0.0:
			levels.append(26.0)
		for y in levels:
			LandmarkChParts.band(lm, "Dark", y - 1.4, 6.5, 7.25, 0.5, 0.2, Vector3(cx, 0, 3.5))
			LandmarkChParts.row(lm, "Windows", Vector3(cx, y, 10.75), 3, 3.6, 1.6, 3.4 if y < 26.0 else 2.2, Basis(), false)
			LandmarkChParts.row(lm, "Windows", Vector3(sx * 18.0, y, 3.5), 3, 3.6, 1.6, 3.4 if y < 26.0 else 2.2,
				Basis(Vector3.UP, PI * 0.5 * sx), false)
			for k in 5:
				var a := deg_to_rad(-150.0 + 30.0 * k)
				var dir := Vector3(cos(a), 0, sin(a))
				LandmarkChParts.round_arch(lm, "Windows", Vector3(cx, y, -3.75) + dir * 6.38, 1.6,
					3.4 if y < 26.0 else 2.2, Basis(Vector3.UP, atan2(dir.x, dir.z)), 0.0)
	lm.commit(model)
