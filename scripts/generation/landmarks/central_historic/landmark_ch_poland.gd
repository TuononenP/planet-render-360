class_name LandmarkChPoland
extends RefCounted

## Two landmarks of Krakow in true metres: Wawel Royal Castle and
## Cathedral (Renaissance courtyard of 1507-36 with three tiers of
## arcades, the top tier double-height columns carrying the eaves, steep
## tiled hip roofs, round towers; the cathedral with the gilded dome of
## the Sigismund Chapel and the 56 m Sigismund Tower) and St Mary's
## Basilica (brick Gothic, nave 28 m high, the 81 m Hejnal tower to the
## north (-Z) with its ring of eight turrets and gilded crown, the 69 m
## bell tower with its Renaissance helm to the south, west front at -X).
## The Palace of Culture in Warsaw is LandmarkChWarsaw.

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
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9B5A40", 3.0))
	_castle(lm)
	_courtyard(lm)
	_castle_towers(lm)
	LandmarkChWawel.cathedral(lm)
	# Hilltop terrace wall with its coping round the whole precinct.
	var rim := [Vector3(-45, 0, -52), Vector3(45, 0, -52), Vector3(45, 0, 54), Vector3(-45, 0, 54)]
	for i in 4:
		LandmarkChParts.wall(lm, "Brick", rim[i], rim[(i + 1) % 4], 0.0, 2.4, 1.6)
		LandmarkChParts.wall(lm, "Stone", rim[i], rim[(i + 1) % 4], 2.4, 2.7, 1.9)
	lm.commit(model)

## Four three-storey wings round the courtyard (centre z 25): walls,
## steep hipped tile roofs with dormers and chimneys, a cornice, and
## stone-framed windows on every outer face.
static func _castle(lm: LandmarkMesh) -> void:
	var wings := [[0.0, 6.0, 66.0, 12.0], [0.0, 44.0, 66.0, 12.0], [-27.0, 25.0, 12.0, 26.0], [27.0, 25.0, 12.0, 26.0]]
	for w in wings:
		lm.box("Wall", Vector3(w[0], 9.5, w[1]), Vector3(w[2], 19.0, w[3]))
		lm.box("Stone", Vector3(w[0], 0.6, w[1]), Vector3(float(w[2]) + 0.4, 1.2, float(w[3]) + 0.4))
	for z in [6.0, 44.0]:
		LandmarkCeParts.hip(lm, "Roof", Vector3(0, 19.0, z), 67.2, 13.2, 8.5)
	for x in [-27.0, 27.0]:
		lm.gable("Roof", Vector3(x, 19.0, 25.0), 12.0, 26.0, 8.5, Basis(), 0.6, "Wall")
	# Eaves cornice on the outer faces.
	var o := [Vector3(-33, 18.4, 0), Vector3(33, 18.4, 0), Vector3(33, 18.4, 50), Vector3(-33, 18.4, 50)]
	var outs := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
	for i in 4:
		LandmarkDetail.cornice(lm, "Stone", o[i], o[(i + 1) % 4], outs[i], 0.6, false)
	# Outer faces: three storeys of stone-framed windows, a string course.
	for f in [[0.0, 0.0, PI, 14, 4.4], [0.0, 50.0, 0.0, 14, 4.4], [-33.0, 25.0, -PI * 0.5, 10, 4.8],
			[33.0, 25.0, PI * 0.5, 10, 4.8]]:
		var b := Basis(Vector3.UP, float(f[2]))
		var n := b.z
		var c := Vector3(f[0], 0, f[1])
		var count: int = f[3]
		var step: float = f[4]
		for y in [4.2, 10.4, 16.0]:
			for i in count:
				var x := step * (float(i) - float(count - 1) * 0.5)
				LandmarkChParts.frame_window(lm, "Stone", "Windows", c + b * Vector3(x, y, 0), n, 1.3,
					2.5 if y < 15.0 else 2.0, 0.22, 0.18)
		var half := step * float(count) * 0.5
		lm.box("Stone", c + b * Vector3(0, 7.6, 0.1), Vector3(half * 2.0, 0.35, 0.3), b, 0.0)
	# Dormers and chimneys on the long roofs.
	for z in [6.0, 44.0]:
		for i in 7:
			var x := -24.0 + 8.0 * i
			for sz in [-1.0, 1.0]:
				var dp := Vector3(x, 19.8, z + float(sz) * 4.0)
				var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
				lm.box("Wall", dp + Vector3(0, 0.9, 0), Vector3(1.6, 1.8, 1.6), b)
				lm.gable("Roof", dp + Vector3(0, 1.8, 0), 1.6, 1.6, 1.0, b, 0.12, "Wall")
				LandmarkChParts.frame_window(lm, "Stone", "Windows", dp + b * Vector3(0, 0.9, 0.8), b.z, 0.7, 1.0,
					0.12, 0.1)
			if i % 2 == 1:
				lm.box("Brick", Vector3(x + 4.0, 26.0, z), Vector3(1.1, 3.0, 1.6))
				lm.box("Stone", Vector3(x + 4.0, 27.6, z), Vector3(1.4, 0.3, 1.9), Basis(), 0.0)

## Courtyard arcades on all four sides: round arches on slender columns
## on the ground and first floors, the second-floor gallery on columns
## twice as tall carrying the roof, each tier with its parapet.
static func _courtyard(lm: LandmarkMesh) -> void:
	var cc := Vector3(0, 0, 25.0)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * s)
		var long := s % 2 == 0
		var d := 10.0 if long else 18.0
		var count := 11 if long else 6
		var span := 36.0 if long else 20.0
		var step := span / float(count - 1)
		var n := b.z
		for t in 3:
			var y0: float = [0.0, 6.2, 12.4][t]
			var ch: float = [4.8, 4.8, 6.0][t]
			var r: float = [0.32, 0.26, 0.22][t]
			for i in count:
				var x := step * (float(i) - float(count - 1) * 0.5)
				LandmarkChParts.ren_column(lm, "Stone", cc + b * Vector3(x, y0 + (0.0 if t == 0 else 1.0), -d), r,
					ch - (0.0 if t == 0 else 1.0))
			var half := span * 0.5 + step * 0.5
			if t < 2:
				for i in count - 1:
					var x := step * (float(i) + 0.5 - float(count - 1) * 0.5)
					LandmarkChParts.arch_band(lm, "Stone", cc + b * Vector3(x, y0 + ch - 0.1, -d + 0.2), n, step - 0.6,
						0.35, 0.4, 8)
				# Spandrel wall and floor slab of the gallery above.
				LandmarkChParts.wall(lm, "Wall", cc + b * Vector3(-half, 0, -d), cc + b * Vector3(half, 0, -d),
					y0 + ch + step * 0.5 - 0.6, y0 + 6.2, 0.6)
				lm.box("Stone", cc + b * Vector3(0, y0 + 6.1, -d + 1.4), Vector3(half * 2.0, 0.3, 3.2), b, 0.0)
				# Parapet on the upper galleries.
				LandmarkChParts.wall(lm, "Stone", cc + b * Vector3(-half, 0, -d), cc + b * Vector3(half, 0, -d),
					y0 + 6.2, y0 + 7.2, 0.4)
			else:
				lm.box("Stone", cc + b * Vector3(0, y0 + ch + 0.2, -d + 1.2), Vector3(half * 2.0, 0.4, 3.4), b, 0.0)
				LandmarkDetail.cornice(lm, "Stone", cc + b * Vector3(-half, y0 + ch + 0.4, -d),
					cc + b * Vector3(half, y0 + ch + 0.4, -d), n, 0.5, false)
		# Back wall of the galleries: doors and windows behind the arcade.
		for t in 3:
			for i in count - 1:
				var x := step * (float(i) + 0.5 - float(count - 1) * 0.5)
				LandmarkChParts.frame_window(lm, "Stone", "Windows", cc + b * Vector3(x, 6.2 * t + 2.4, -d - 2.95), n,
					1.2, 2.4 if t < 2 else 3.0, 0.2, 0.15)

## Castle towers: the round Danish and Senators' towers with copper
## helms, the square Hen's Foot tower with its hip roof.
static func _castle_towers(lm: LandmarkMesh) -> void:
	for tw in [[-33.0, 0.0, 5.0, 26.0], [-33.0, 50.0, 5.6, 30.0]]:
		var p := Vector3(tw[0], 0, tw[1])
		var r: float = tw[2]
		var h: float = tw[3]
		lm.frustum("Brick", p, r * 1.08, r, 3.0, 24)
		lm.frustum("Wall", p + Vector3(0, 3.0, 0), r, r * 0.95, h - 3.0, 24)
		for k in 16:
			var a := TAU * float(k) / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Stone", p + d * (r * 0.97 + 0.3) + Vector3(0, h - 0.6, 0), Vector3(0.4, 1.2, 0.6),
				Basis(Vector3.UP, -a + PI * 0.5), 0.0)
			if k % 4 == 0:
				for y in [6.0, 12.0, 18.0]:
					LandmarkChParts.frame_window(lm, "Stone", "Windows", p + d * (r * 0.96) + Vector3(0, y, 0), d,
						1.0, 1.8, 0.18, 0.15)
		lm.frustum("Stone", p + Vector3(0, h, 0), r * 1.14, r * 1.12, 1.0, 24)
		lm.lathe("Copper", p + Vector3(0, h + 1.0, 0), PackedVector2Array([Vector2(r * 1.1, 0), Vector2(r * 1.0, 1.0),
			Vector2(r * 0.65, 5.0), Vector2(r * 0.3, 9.0), Vector2(0.15, 12.5)]), 16)
		for k in 4:
			var a := TAU * float(k) / 4.0 + PI * 0.25
			var d := Vector3(cos(a), 0, sin(a))
			var lc := p + d * r * 0.85 + Vector3(0, h + 2.4, 0)
			var b := Basis(Vector3.UP, atan2(d.x, d.z))
			lm.box("Wall", lc, Vector3(1.2, 1.6, 1.2), b)
			lm.gable("Copper", lc + Vector3(0, 0.8, 0), 1.2, 1.2, 0.8, b, 0.1, "Wall")
		LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + 13.5, 0), 2.0, 0.4)
	var hf := Vector3(33.0, 0, 50.0)
	lm.box("Wall", hf + Vector3(0, 15.0, 0), Vector3(9.0, 30.0, 9.0))
	# The three buttresses that give the Hen's Foot its name.
	for a in [0.0, PI * 0.5, PI * 0.25]:
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.buttress(lm, "Brick", hf + d * 4.5, d, 2.0, 3.5, 14.0, 3)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		for y in [18.0, 23.0, 27.0]:
			LandmarkChParts.frame_window(lm, "Stone", "Windows", hf + b * Vector3(0, y, 4.5), b.z, 1.0, 1.8, 0.18, 0.15)
	LandmarkCeParts.hip(lm, "Roof", hf + Vector3(0, 30.0, 0), 10.0, 10.0, 11.0)
	LandmarkChParts.finial(lm, "Gilt", hf + Vector3(0, 41.0, 0), 1.8, 0.3)

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
	_marys_body(lm)
	_hejnal_tower(lm, Vector3(-34.0, 0, -9.5))
	_bell_tower(lm, Vector3(-34.0, 0, 9.5))
	lm.commit(model)

## Basilican body: nave of four bays with clerestory under the high
## roof, chapel-lined aisles with lean-to roofs, the long chancel with
## its tall lancets and polygonal apse, buttresses and the west porch.
static func _marys_body(lm: LandmarkMesh) -> void:
	lm.box("Brick", Vector3(-4.0, 15.0, 0), Vector3(48.0, 30.0, 15.6))
	lm.gable("Roof", Vector3(-4.0, 30.0, 0), 15.6, 48.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Brick")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		lm.box("Brick", Vector3(-4.0, 8.5, sz * 11.0), Vector3(48.0, 17.0, 6.4))
		lm.quad("Roof", Vector3(-28.0, 17.0, sz * 14.6), Vector3(20.0, 17.0, sz * 14.6), Vector3(20.0, 23.0, sz * 7.8),
			Vector3(-28.0, 23.0, sz * 7.8), Vector3(0, 6.8, sz * 6.0).normalized())
		LandmarkDetail.cornice(lm, "Stone", Vector3(-28.0, 16.4, sz * 14.2), Vector3(20.0, 16.4, sz * 14.2), n, 0.6, false)
		LandmarkDetail.cornice(lm, "Stone", Vector3(-28.0, 29.4, sz * 7.8), Vector3(20.0, 29.4, sz * 7.8), n, 0.6, false)
		for i in 4:
			var x := -22.0 + 12.0 * i
			# Two chapel windows per bay in the aisle, a big clerestory lancet.
			for dx in [-2.6, 2.6]:
				LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(x + dx, 4.0, sz * 14.2), n, 2.0, 9.5, 1, 0.3)
			LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(x, 23.6, sz * 7.8), n, 3.0, 5.4, 2, 0.3)
			LandmarkChParts.buttress(lm, "Brick", Vector3(x + 6.0, 0, sz * 14.2), n, 1.4, 1.8, 16.0, 2)
			if i < 3:
				lm.beam("Brick", Vector3(x + 6.0, 23.0, sz * 8.4), Vector3(x + 6.0, 17.2, sz * 13.6), 1.0, 1.0)
	# Chancel: long, tall, with stone buttresses and five-sided apse.
	lm.box("Brick", Vector3(29.0, 15.0, 0), Vector3(18.0, 30.0, 15.6))
	lm.gable("Roof", Vector3(29.0, 30.0, 0), 15.6, 18.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Brick")
	lm.frustum("Brick", Vector3(38.0, 0, 0), 8.45, 8.45, 30.0, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(38.0, 30.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(0.0, 12.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for i in 3:
			LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(24.5 + 4.6 * i, 6.0, sz * 7.8), n, 2.6, 19.0, 1, 0.3)
		for i in 4:
			LandmarkChParts.buttress(lm, "Stone", Vector3(22.2 + 4.6 * i, 0, sz * 7.8), n, 1.4, 2.4, 27.0, 3)
			LandmarkChParts.pinnacle(lm, "Stone", Vector3(22.2 + 4.6 * i, 27.0, sz * 8.3), 0.9, 4.0)
	for k in [-1, 0, 1]:
		var a := PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(38.0, 6.0, 0) + d * 7.8, d, 2.6, 19.0, 1, 0.3)
	for k in [-2, -1, 0, 1]:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.buttress(lm, "Stone", Vector3(38.0, 0, 0) + d * 8.4, d, 1.4, 2.4, 27.0, 3)
		LandmarkChParts.pinnacle(lm, "Stone", Vector3(38.0, 27.0, 0) + d * 8.9, 0.9, 4.0)
	# West front between the towers: gable with blind tracery, the great
	# west window and the baroque porch over the portal.
	lm.box("Brick", Vector3(-34.0, 18.0, 0), Vector3(12.0, 36.0, 7.0))
	lm.gable("Roof", Vector3(-34.0, 36.0, 0), 7.0, 12.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Brick")
	LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(-40.0, 14.0, 0), Vector3.LEFT, 3.4, 15.0, 2, 0.35)
	for z in [-2.4, 0.0, 2.4]:
		LandmarkChParts.lancet(lm, "Stone", "Brick", Vector3(-40.0, 30.5, z), Vector3.LEFT, 1.4, 4.5 - absf(z) * 0.6, 0, 0.2)
	lm.box("Stone", Vector3(-42.0, 4.0, 0), Vector3(4.0, 8.0, 6.0))
	lm.lathe("Copper", Vector3(-42.0, 8.0, 0), LandmarkChParts.swell(2.6, 3.0), 12, 1.0, 1.4)
	LandmarkChParts.finial(lm, "Gilt", Vector3(-42.0, 11.0, 0), 1.2, 0.25)
	LandmarkChParts.arched_window(lm, "Stone", "Windows", Vector3(-44.0, 0.2, 0), Vector3.LEFT, 2.4, 5.0, 0.3)

## Square brick tower shaft, 12 m, of `h`: stone string courses every
## storey, corner buttresses, two-light lancets and blind tracery.
static func _tower_shaft(lm: LandmarkMesh, p: Vector3, h: float) -> void:
	lm.box("Brick", p + Vector3(0, h * 0.5, 0), Vector3(12.0, h, 12.0))
	var y := 6.0
	while y < h - 2.0:
		LandmarkChParts.band(lm, "Stone", y, 6.0, 6.0, 0.45, 0.2, p)
		y += 6.0
	LandmarkChParts.band(lm, "Stone", h - 0.8, 6.0, 6.0, 1.0, 0.5, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, 6.0)
		for s in [-1.0, 1.0]:
			LandmarkChParts.buttress(lm, "Brick", face + b * Vector3(s * 5.2, 0, 0), n, 1.3, 1.4, minf(h - 8.0, 30.0), 3)
		var k := 0
		var wy := 7.0
		while wy + 4.6 < h - 1.0:
			if k % 2 == 0:
				LandmarkChParts.lancet(lm, "Stone", "Windows", face + Vector3(0, wy, 0), n, 1.5, 4.4, 1, 0.25)
			else:
				for x in [-1.8, 1.8]:
					LandmarkChParts.lancet(lm, "Stone", "Brick", face + b * Vector3(x, wy, 0), n, 1.1, 4.4, 0, 0.2)
			wy += 6.0
			k += 1

## The Hejnal tower (81 m): square to the ninth storey, then the
## octagon with pointed windows; the 1478 Gothic helm ringed by eight
## turrets, the gilded crown of 1666 and the spike.
static func _hejnal_tower(lm: LandmarkMesh, p: Vector3) -> void:
	_tower_shaft(lm, p, 44.0)
	lm.frustum("Brick", p + Vector3(0, 44.0, 0), 5.84, 5.84, 18.0, 8, PI / 8.0)
	for f in 8:
		var a := PI * 0.25 * f
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.lancet(lm, "Stone", "Windows", p + Vector3(0, 46.5, 0) + d * 5.4, d, 1.6, 6.5, 1, 0.25)
		LandmarkChParts.lancet(lm, "Stone", "Windows", p + Vector3(0, 54.5, 0) + d * 5.4, d, 1.4, 5.0, 0, 0.25)
	LandmarkChParts.band(lm, "Stone", 53.6, 5.4, 5.4, 0.4, 0.2, p)
	lm.frustum("Stone", p + Vector3(0, 61.6, 0), 6.1, 6.1, 0.5, 8, PI / 8.0)
	# Ring of eight turrets round the foot of the helm.
	for k in 8:
		var a := PI * 0.25 * k + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var tp := p + d * 5.5 + Vector3(0, 62.1, 0)
		lm.frustum("Copper", tp, 0.7, 0.65, 3.4, 8)
		lm.lathe("Copper", tp + Vector3(0, 3.4, 0), PackedVector2Array([Vector2(0.85, 0), Vector2(0.5, 1.6),
			Vector2(0.06, 5.2)]), 8)
		LandmarkChParts.finial(lm, "Gilt", tp + Vector3(0, 8.6, 0), 0.8, 0.12)
	# Helm: octagonal spire with lucarnes, the crown, upper needle.
	var hb := p + Vector3(0, 62.1, 0)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(5.0, 0), Vector2(4.2, 3.0), Vector2(3.0, 7.0),
		Vector2(1.9, 11.0), Vector2(1.1, 14.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 4:
		var a := PI * 0.5 * k
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, atan2(d.x, d.z))
		var lc := hb + d * 3.9 + Vector3(0, 2.6, 0)
		lm.box("Copper", lc, Vector3(1.0, 1.6, 0.8), b)
		lm.gable("Copper", lc + Vector3(0, 0.8, 0), 1.0, 0.8, 0.8, b, 0.08, "Copper")
	var cr := hb + Vector3(0, 14.4, 0)
	lm.frustum("Gilt", cr, 1.2, 1.2, 0.3, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gilt", cr + d * 1.15 + Vector3(0, 0.3, 0), cr + d * 1.3 + Vector3(0, 1.3, 0), 0.22, 0.12)
		lm.lathe("Gilt", cr + d * 1.3 + Vector3(0, 1.3, 0), PackedVector2Array([Vector2(0.12, 0), Vector2(0.16, 0.12),
			Vector2(0.0, 0.3)]), 6)
	lm.lathe("Copper", cr + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.6, 1.0),
		Vector2(0.2, 2.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", cr + Vector3(0, 2.6, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.4, 0.3),
		Vector2(0.35, 0.6), Vector2(0.05, MARY_TOP - cr.y - 2.6)]), 8)

## Bell tower (69 m): square shaft to 48 m, the octagonal drum with
## four corner domelets and the Renaissance helm of 1592 with its
## openwork lantern.
static func _bell_tower(lm: LandmarkMesh, p: Vector3) -> void:
	_tower_shaft(lm, p, 48.0)
	lm.frustum("Stone", p + Vector3(0, 48.0, 0), 5.5, 5.5, 7.0, 8, PI / 8.0)
	for f in 8:
		var a := PI * 0.25 * f
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Stone", "Windows", p + Vector3(0, 49.6, 0) + d * 5.1, d, 1.3, 3.8, 0.22)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cp := p + Vector3(sx * 5.0, 48.0, sz * 5.0)
			lm.frustum("Stone", cp, 1.0, 1.0, 3.0, 8)
			lm.lathe("Copper", cp + Vector3(0, 3.0, 0), LandmarkChParts.swell(1.1, 1.8), 10)
			LandmarkChParts.finial(lm, "Gilt", cp + Vector3(0, 4.8, 0), 1.0, 0.18)
	lm.lathe("Copper", p + Vector3(0, 55.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(6.8, 1.0),
		Vector2(5.8, 3.2), Vector2(3.6, 5.6), Vector2(2.2, 7.2)]), 16)
	# Openwork lantern: eight posts round a core, cornice, little cap.
	var lb := p + Vector3(0, 62.2, 0)
	lm.frustum("Stone", lb, 1.2, 1.1, 3.5, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Stone", lb + Vector3(cos(a), 0, sin(a)) * 1.9, 0.18, 0.16, 3.5, 6)
	lm.frustum("Stone", lb + Vector3(0, 3.5, 0), 2.3, 2.3, 0.3, 12)
	lm.lathe("Copper", p + Vector3(0, 66.0, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(1.4, 0.8),
		Vector2(0.4, 1.8)]), 12)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, 67.8, 0), 69.0 - 67.8, 0.4)
