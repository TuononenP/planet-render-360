class_name LandmarkChPoland
extends RefCounted

## Three landmarks of Poland in true metres: Wawel Royal Castle and
## Cathedral in Krakow (arcaded Renaissance courtyard, round towers, the
## cathedral with the gilded Sigismund Chapel dome and the 56 m Sigismund
## Tower), St Mary's Basilica in Krakow (brick Gothic, the 81 m and 69 m
## towers, west front at -X) and the Palace of Culture and Science in
## Warsaw (Stalinist stepped tower with its 237 m spire, front to +Z).

# --- Wawel Royal Castle and Cathedral ---

const WAWEL_TOP := 56.0

static func wawel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D9CDB0", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B7AD97", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A9502F", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9A86", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#8E8672", 4.0))
	_castle(lm)
	_cathedral(lm)
	# Retaining wall round the hilltop, deep below the base ground.
	var rim := [Vector3(-45, 0, -52), Vector3(45, 0, -52), Vector3(45, 0, 54), Vector3(-45, 0, 54)]
	for i in 4:
		LandmarkChParts.wall(lm, "Rock", rim[i], rim[(i + 1) % 4], -14.0, 0.6, 3.0)
	lm.commit(model)

## Four three-storey wings round a 42 x 26 m courtyard (centre z 25) with
## three tiers of arcades, steep tiled roofs and three corner towers.
static func _castle(lm: LandmarkMesh) -> void:
	var cc := Vector3(0, 0, 25.0)
	for w in [[0.0, 6.0, 66.0, 12.0], [0.0, 44.0, 66.0, 12.0], [-27.0, 25.0, 12.0, 26.0], [27.0, 25.0, 12.0, 26.0]]:
		lm.box("Wall", Vector3(w[0], 9.5, w[1]), Vector3(w[2], 19.0, w[3]))
	for z in [6.0, 44.0]:
		lm.gable("Roof", Vector3(0, 19.0, z), 12.0, 66.0, 8.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Wall")
	for x in [-27.0, 27.0]:
		lm.gable("Roof", Vector3(x, 19.0, 25.0), 12.0, 26.0, 8.5, Basis(), 0.6, "Wall")
	# Courtyard arcades: side 0 is the north wing, then west, south, east.
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * s)
		var wall_d := 13.0 if s % 2 == 0 else 21.0
		var count := 11 if s % 2 == 0 else 4
		var step := 3.6 if s % 2 == 0 else 4.0
		for t in 3:
			var y0 := 6.2 * t
			var r0: float = [0.42, 0.3, 0.2][t]
			for i in count:
				var x := step * (float(i) - float(count - 1) * 0.5)
				lm.frustum("Stone", cc + b * Vector3(x, y0, 3.0 - wall_d), r0, r0 * 0.85, 5.8, 10)
			var half := step * float(count) * 0.5 + 0.2
			LandmarkChParts.wall(lm, "Stone", cc + b * Vector3(-half, 0, 3.0 - wall_d), cc + b * Vector3(half, 0, 3.0 - wall_d),
				y0 + 5.8, y0 + 6.2, 1.0)
			LandmarkChParts.row(lm, "Windows", cc + b * Vector3(0, y0 + 1.2, -wall_d), count - 1 if s % 2 == 0 else 5,
				step, 1.2, 3.2, b, false)
		var half_c := step * float(count) * 0.5 + 0.2
		LandmarkChParts.wall(lm, "Stone", cc + b * Vector3(-half_c, 0, 1.8 - wall_d), cc + b * Vector3(half_c, 0, 1.8 - wall_d),
			18.4, 19.2, 3.6)
	# Outer faces: three window rows on every side.
	for f in [[0.0, 0.0, PI, 14, 4.4], [0.0, 50.0, 0.0, 14, 4.4], [-33.0, 25.0, -PI * 0.5, 5, 4.8],
			[33.0, 25.0, PI * 0.5, 5, 4.8]]:
		var b := Basis(Vector3.UP, float(f[2]))
		for y in [3.0, 9.5, 15.5]:
			LandmarkChParts.row(lm, "Windows", Vector3(f[0], y, f[1]), int(f[3]), float(f[4]), 1.2, 2.4, b, false)
	# Towers: the Danish and Senators' towers round, the Hen's Foot square.
	for tw in [[-33.0, 0.0, 5.0, 26.0], [-33.0, 50.0, 5.6, 30.0]]:
		var p := Vector3(tw[0], 0, tw[1])
		var r: float = tw[2]
		var h: float = tw[3]
		lm.frustum("Wall", p, r, r * 0.95, h, 14)
		lm.frustum("Stone", p + Vector3(0, h, 0), r * 1.12, r * 1.12, 1.0, 14)
		lm.lathe("Copper", p + Vector3(0, h + 1.0, 0), PackedVector2Array([Vector2(r * 1.1, 0), Vector2(r * 1.0, 1.0),
			Vector2(r * 0.65, 5.0), Vector2(r * 0.3, 9.0), Vector2(0.15, 12.5)]), 14)
		LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + 13.5, 0), 2.0, 0.4)
	lm.box("Wall", Vector3(33.0, 15.0, 50.0), Vector3(9.0, 30.0, 9.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(33.0, 30.0, 50.0), 10.0, 10.0, 11.0)

## The cathedral north of the castle: copper-roofed nave and choir with
## three west towers, the Sigismund Tower tallest, and the side chapels.
static func _cathedral(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, -32.0)
	lm.box("Stone", c + Vector3(-4.5, 8.5, 0), Vector3(49.0, 17.0, 20.0))
	lm.gable("Copper", c + Vector3(-4.5, 17.0, 0), 20.0, 49.0, 9.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	lm.box("Stone", c + Vector3(25.5, 8.5, 0), Vector3(11.0, 17.0, 20.0))
	lm.gable("Copper", c + Vector3(25.5, 17.0, 0), 20.0, 11.0, 9.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	lm.frustum("Stone", c + Vector3(31.0, 0, 0), 11.0, 11.0, 17.0, 8, PI / 8.0)
	lm.lathe("Copper", c + Vector3(31.0, 17.0, 0), PackedVector2Array([Vector2(11.6, 0), Vector2(0.0, 10.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for x in [-22.0, -15.0, -8.0, -1.0, 6.0, 13.0, 20.0, 27.0]:
		LandmarkChParts.pointed(lm, "Windows", c + Vector3(x, 5.0, -10.0), 2.0, 8.0, Basis(Vector3.UP, PI))
	# Sigismund Tower (shaft, belfry, copper helm) between two lower towers.
	var st := c + Vector3(-34.0, 0, 0)
	lm.box("Stone", st + Vector3(0, 16.0, 0), Vector3(11.0, 32.0, 11.0))
	LandmarkChParts.band(lm, "Wall", 32.0, 5.5, 5.5, 0.8, 0.4, st)
	lm.box("Stone", st + Vector3(0, 35.9, 0), Vector3(9.6, 6.2, 9.6))
	LandmarkChParts.band(lm, "Wall", 39.0, 4.8, 4.8, 0.6, 0.4, st)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", st + b * Vector3(0, 8.0, 5.5), 1, 1.0, 1.6, 5.5, b)
		LandmarkChParts.row(lm, "Windows", st + b * Vector3(0, 20.0, 5.5), 2, 3.0, 1.6, 5.5, b)
		LandmarkChParts.row(lm, "Windows", st + b * Vector3(0, 33.4, 4.8), 2, 4.2, 2.2, 4.6, b, false)
	var hb := st + Vector3(0, 39.6, 0)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(6.2, 0), Vector2(6.8, 1.0), Vector2(6.0, 3.0),
		Vector2(3.8, 6.0), Vector2(2.5, 8.0)]), 12)
	lm.frustum("Stone", hb + Vector3(0, 8.0, 0), 2.2, 2.0, 3.0, 8)
	lm.lathe("Copper", hb + Vector3(0, 11.0, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(1.6, 1.2),
		Vector2(0.5, 2.5)]), 8)
	LandmarkChParts.finial(lm, "Gilt", hb + Vector3(0, 13.5, 0), WAWEL_TOP - 53.1, 0.6)
	for sz in [-1.0, 1.0]:
		var tp := st + Vector3(1.0, 0, sz * 9.5)
		lm.box("Stone", tp + Vector3(0, 12.0, 0), Vector3(8.0, 24.0, 8.0))
		LandmarkChParts.row(lm, "Windows", tp + Vector3(0, 10.0, 0) + Vector3(-4.0, 0, 0), 1, 1.0, 1.4, 5.0,
			Basis(Vector3.UP, -PI * 0.5))
		lm.lathe("Copper", tp + Vector3(0, 24.0, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(5.2, 0.8),
			Vector2(4.2, 2.6), Vector2(2.6, 4.6), Vector2(1.2, 6.0), Vector2(0.2, 7.0)]), 10)
		LandmarkChParts.finial(lm, "Gilt", tp + Vector3(0, 31.0, 0), 2.4, 0.4)
	# Side chapels: Vasa, Sigismund (gilded dome) and Potocki to the south,
	# three smaller ones to the north.
	for ch in [[-14.0, 4.0, 14.0, 3.0], [17.0, 3.5, 13.0, 2.5]]:
		_chapel(lm, c + Vector3(ch[0], 0, 10.0 + ch[1]), ch[1], ch[2], "Copper", ch[3])
	for x in [-16.0, -2.0, 14.0]:
		_chapel(lm, c + Vector3(x, 0, -13.2), 3.2, 11.0, "Copper", 2.2)
	var sg := c + Vector3(2.0, 0, 15.75)
	lm.box("Stone", sg + Vector3(0, 8.5, 0), Vector3(11.5, 17.0, 11.5))
	lm.frustum("Stone", sg + Vector3(0, 17.0, 0), 5.0, 5.0, 8.0, 8, PI / 8.0)
	LandmarkChParts.row(lm, "Windows", sg + Vector3(0, 19.5, 0) + Vector3(0, 0, 4.6), 1, 1.0, 1.2, 4.0)
	lm.lathe("Gilt", sg + Vector3(0, 25.0, 0), PackedVector2Array([Vector2(4.9, 0), Vector2(5.0, 1.0),
		Vector2(4.7, 2.8), Vector2(3.9, 5.0), Vector2(2.7, 7.0), Vector2(1.5, 8.4), Vector2(0.9, 9.2),
		Vector2(0.9, 9.8)]), 16)
	lm.frustum("Gilt", sg + Vector3(0, 34.8, 0), 1.0, 0.9, 3.0, 8)
	lm.lathe("Gilt", sg + Vector3(0, 37.8, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(1.0, 0.4),
		Vector2(0.5, 1.4), Vector2(0.06, 2.2)]), 8)
	LandmarkChParts.finial(lm, "Gilt", sg + Vector3(0, 40.0, 0), 1.8, 0.3)

## Square chapel of half-width `half` with a drum-less copper dome.
static func _chapel(lm: LandmarkMesh, p: Vector3, half: float, h: float, dome: String, dome_h: float) -> void:
	lm.box("Stone", p + Vector3(0, h * 0.5, 0), Vector3(half * 2.0, h, half * 2.0))
	lm.lathe(dome, p + Vector3(0, h, 0), LandmarkChParts.swell(half * 1.05, dome_h * 2.4), 12)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + dome_h * 2.4, 0), 1.6, 0.3)

# --- St Mary's Basilica, Krakow ---

const MARY_TOP := 81.0

static func marys(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9B4B33", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CBBFA4", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#7F3A28", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F7A6C", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave under the high roof, aisles with lean-to roofs, chancel and apse.
	lm.box("Brick", Vector3(-4.0, 15.0, 0), Vector3(48.0, 30.0, 15.6))
	lm.gable("Roof", Vector3(-4.0, 30.0, 0), 15.6, 48.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Brick")
	for sz in [-1.0, 1.0]:
		lm.box("Brick", Vector3(-4.0, 8.5, sz * 11.0), Vector3(48.0, 17.0, 6.4))
		lm.quad("Roof", Vector3(-28.0, 17.0, sz * 14.6), Vector3(20.0, 17.0, sz * 14.6), Vector3(20.0, 23.0, sz * 7.8),
			Vector3(-28.0, 23.0, sz * 7.8), Vector3(0, 6.8, sz * 6.0).normalized())
		var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		for i in 8:
			var x := -25.0 + 5.8 * i
			LandmarkChParts.pointed(lm, "Windows", Vector3(x, 4.0, sz * 14.2), 2.4, 9.0, b)
			lm.box("Stone", Vector3(x + 2.9, 8.0, sz * 14.8), Vector3(1.2, 16.0, 1.6))
			LandmarkChParts.pointed(lm, "Windows", Vector3(x + 1.0, 24.0, sz * 7.8), 2.0, 5.2, b)
	lm.box("Brick", Vector3(29.0, 15.0, 0), Vector3(18.0, 30.0, 15.6))
	lm.gable("Roof", Vector3(29.0, 30.0, 0), 15.6, 18.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Brick")
	lm.frustum("Brick", Vector3(38.0, 0, 0), 8.45, 8.45, 30.0, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(38.0, 30.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(0.0, 12.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	for sz in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		LandmarkChParts.row(lm, "Windows", Vector3(29.0, 6.0, sz * 7.8), 4, 4.5, 2.4, 18.0, b)
		for i in 4:
			lm.box("Stone", Vector3(24.5 + 4.5 * i, 14.0, sz * 8.4), Vector3(1.4, 28.0, 1.6))
	# West front: the gabled bay between the towers and the portal.
	lm.box("Brick", Vector3(-34.0, 18.0, 0), Vector3(12.0, 36.0, 7.0))
	lm.gable("Roof", Vector3(-34.0, 36.0, 0), 7.0, 12.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Brick")
	LandmarkChParts.pointed(lm, "Windows", Vector3(-40.0, 16.0, 0), 2.8, 15.0, Basis(Vector3.UP, -PI * 0.5))
	LandmarkChParts.pointed(lm, "Windows", Vector3(-40.0, 0.0, 0), 3.0, 8.0, Basis(Vector3.UP, -PI * 0.5))
	# North tower (81 m): octagonal belfry, four turrets and the crowned spire.
	var nt := Vector3(-34.0, 0, -9.5)
	_tower_shaft(lm, nt, 44.0)
	lm.frustum("Brick", nt + Vector3(0, 44.0, 0), 5.84, 5.84, 18.0, 8, PI / 8.0)
	for f in 8:
		var b := Basis(Vector3.UP, PI * 0.25 * f)
		LandmarkChParts.pointed(lm, "Windows", nt + Vector3(0, 47.0, 0) + b * Vector3(0, 0, 5.4), 1.6, 9.0, b)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkChParts.turret(lm, "Stone", "Copper", nt + Vector3(sx * 5.0, 44.0, sz * 5.0), 1.1, 17.0, 5.0)
	lm.lathe("Copper", nt + Vector3(0, 62.0, 0), PackedVector2Array([Vector2(5.9, 0), Vector2(5.0, 3.0),
		Vector2(3.6, 8.0), Vector2(2.2, 13.0), Vector2(1.2, 17.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", nt + Vector3(0, 79.0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.3, 0.5),
		Vector2(1.2, 1.0), Vector2(0.6, 1.6), Vector2(0.05, MARY_TOP - 79.0)]), 8)
	# South tower (69 m): square shaft, octagon and the Renaissance helm.
	var stw := Vector3(-34.0, 0, 9.5)
	_tower_shaft(lm, stw, 48.0)
	lm.frustum("Stone", stw + Vector3(0, 48.0, 0), 5.5, 5.5, 7.0, 8, PI / 8.0)
	lm.lathe("Copper", stw + Vector3(0, 55.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(6.8, 1.0),
		Vector2(5.8, 3.2), Vector2(3.6, 5.6), Vector2(2.2, 7.2)]), 12)
	lm.frustum("Stone", stw + Vector3(0, 62.2, 0), 2.0, 1.8, 3.5, 8)
	lm.lathe("Copper", stw + Vector3(0, 65.7, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(1.4, 1.0),
		Vector2(0.4, 2.0)]), 8)
	LandmarkChParts.finial(lm, "Gilt", stw + Vector3(0, 67.7, 0), 69.0 - 67.7, 0.4)
	lm.commit(model)

## Square brick tower shaft of 12 m with stone string courses and windows.
static func _tower_shaft(lm: LandmarkMesh, p: Vector3, h: float) -> void:
	lm.box("Brick", p + Vector3(0, h * 0.5, 0), Vector3(12.0, h, 12.0))
	for y in [14.0, 26.0, 38.0]:
		if y < h:
			LandmarkChParts.band(lm, "Stone", y, 6.0, 6.0, 0.7, 0.3, p)
	LandmarkChParts.band(lm, "Stone", h - 0.8, 6.0, 6.0, 1.0, 0.5, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 6.0, 6.0), 1, 1.0, 1.8, 7.0, b)
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 28.0, 6.0), 2, 3.4, 1.6, 7.0, b)
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, h - 11.0, 6.0), 2, 3.4, 1.6, 8.0, b)

# --- Palace of Culture and Science, Warsaw ---

const PALACE_TOP := 237.0
## Tower tiers: half-width, base and top height.
const PALACE_TIERS := [[40.0, 0.0, 46.0], [28.0, 46.0, 112.0], [22.0, 112.0, 148.0], [17.0, 148.0, 172.0],
	[12.0, 172.0, 187.0]]

static func palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#C4B9A0", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#8F8672", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E907F", 2.0, 0.55, 0.3))
	lm.use("Steel", LandmarkMaterials.paint("#8B96A0", 0.4, 0.6))
	lm.use("Clock", LandmarkMaterials.paint("#ECE9DE", 0.5, 0.1))
	lm.box("Dark", Vector3(0, 0.6, 8.0), Vector3(160.0, 1.2, 116.0))
	for t in PALACE_TIERS:
		_tier(lm, Vector3.ZERO, float(t[0]), float(t[1]), float(t[2]), 6.0 if float(t[0]) > 20.0 else 4.5)
	# Slim copper pinnacles at the corners of the upper setbacks.
	for t in PALACE_TIERS.slice(1, 4):
		var q: float = float(t[0]) - 2.0
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				LandmarkChParts.turret(lm, "Wall", "Copper", Vector3(sx * q, float(t[2]) + 3.2, sz * q), 1.5, 9.0, 6.0)
	# Four tall corner pavilions round the foot of the tower.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 32.0, 0, sz * 32.0)
			_tier(lm, p, 9.0, 46.0, 92.0, 6.0)
			lm.spire("Copper", p + Vector3(0, 93.0, 0), 8.0, 12.0, 0.0, 4)
	# Side wings forward of the tower leave a front court.
	for sx in [-1.0, 1.0]:
		lm.box("Wall", Vector3(sx * 58.0, 15.0, 10.0), Vector3(36.0, 30.0, 100.0))
		lm.box("Dark", Vector3(sx * 58.0, 30.5, 10.0), Vector3(37.0, 1.0, 101.0))
		for r in 4:
			var y := 5.0 + 6.0 * r
			LandmarkChParts.row(lm, "Windows", Vector3(sx * 76.0, y, 10.0), 15, 6.4, 2.0, 3.8,
				Basis(Vector3.UP, PI * 0.5 * sx), false)
			LandmarkChParts.row(lm, "Windows", Vector3(sx * 40.0, y, 50.0), 4, 6.0, 2.0, 3.8,
				Basis(Vector3.UP, -PI * 0.5 * sx), false)
			LandmarkChParts.row(lm, "Windows", Vector3(sx * 58.0, y, 60.0), 5, 6.4, 2.0, 3.8, Basis(), false)
		var corners := [Vector3(sx * 76.0, 31.0, -40.0), Vector3(sx * 76.0, 31.0, 60.0),
			Vector3(sx * 40.0, 31.0, 60.0), Vector3(sx * 40.0, 31.0, -40.0)]
		for i in 3:
			LandmarkCeParts.merlons(lm, "Wall", corners[i], corners[i + 1], 3.6, 1.6, 1.8, 1.2)
	# Portico of the entrance, then the spire.
	for i in 12:
		lm.frustum("Wall", Vector3(-22.0 + 4.0 * i, 1.2, 43.0), 1.2, 1.1, 15.0, 12)
	lm.box("Wall", Vector3(0, 17.0, 42.0), Vector3(52.0, 2.4, 6.0))
	lm.lathe("Steel", Vector3(0, 187.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(3.2, 10.0),
		Vector2(1.9, 25.0), Vector2(1.0, 38.0), Vector2(0.35, PALACE_TOP - 187.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		lm.disc("Clock", b * Vector3(0, 160.0, 17.15), b.z, 4.0, 28)
	lm.commit(model)

## One square tier of the tower: walls, window rows and a toothed Polish attic.
static func _tier(lm: LandmarkMesh, c: Vector3, hw: float, y0: float, y1: float, row_h: float) -> void:
	lm.box("Wall", c + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
	lm.box("Dark", c + Vector3(0, y1 + 0.5, 0), Vector3(hw * 2.0 + 1.6, 1.0, hw * 2.0 + 1.6))
	var rows := int((y1 - y0 - 8.0) / row_h)
	var count := maxi(int(hw * 2.0 / 5.0) - 1, 2)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		for r in rows:
			LandmarkChParts.row(lm, "Windows", c + b * Vector3(0, y0 + 4.0 + row_h * r, hw), count, 5.0, 1.8,
				row_h * 0.6, b, false)
		var along := b * Vector3(1, 0, 0)
		var a := c + b * Vector3(-hw, y1 + 1.0, hw)
		LandmarkCeParts.merlons(lm, "Wall", a, a + along * hw * 2.0, 3.6, 1.6, 2.0, 1.2)
