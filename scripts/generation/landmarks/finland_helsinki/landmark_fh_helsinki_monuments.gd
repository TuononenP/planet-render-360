class_name LandmarkFhHelsinkiMonuments
extends RefCounted

## Four Finnish monuments in true metres: the Sibelius Monument (steel
## organ pipes), the Suomenlinna sea fortress (church with its light
## tower, rampart and King's Gate), the Helsinki Olympic Stadium with its
## 72.71 m tower and the Hanko water tower.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- Sibelius Monument ----------------------------------------------

## Eila Hiltunen's monument (1967): about 600 welded stainless-steel pipes
## in a flowing cluster 8.5 m high, 10.5 m wide and 6.5 m deep on the rock
## of Sibelius Park. Origin at the centre of the sculpture's base.
static func sibelius(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#C3C9CC", 2.0, 0.25, 0.85))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7C776E", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8782", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F4A3C", 2.0, 0.4, 0.6))
	# Rock outcrop and the granite plinth.
	lm.lathe("Rock", Vector3(0, -2.2, 0), PackedVector2Array([Vector2(11.0, 0), Vector2(9.5, 1.4),
		Vector2(7.5, 2.1), Vector2(6.8, 2.2)]), 14, 1.1, 0.9, 0.4, false, false)
	lm.box("Granite", Vector3(0, 0.1, 0), Vector3(11.4, 0.4, 7.4))
	# A rolling field of pipes: tallest at the back left, tapering in waves.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1967
	var pipes: Array = []
	var top_max := 0.0
	for ix in 16:
		for iz in 9:
			var x := -5.0 + 10.0 * float(ix) / 15.0 + rng.randf_range(-0.12, 0.12)
			var z := -3.0 + 6.0 * float(iz) / 8.0 + rng.randf_range(-0.12, 0.12)
			var swell := exp(-(pow(x + 2.4, 2.0) / 10.0 + pow(z + 0.5, 2.0) / 6.0))
			var top := 3.4 + 4.0 * swell + 1.3 * sin(0.62 * x + 0.4 * z) + 0.9 * sin(1.2 * z - 0.25 * x)
			pipes.append([x, z, top, rng.randf_range(0.2, 0.4)])
			top_max = maxf(top_max, top)
	var scale_h := 8.5 / top_max
	for p in pipes:
		var h: float = float(p[2]) * scale_h
		lm.frustum("Steel", Vector3(float(p[0]), 0.3, float(p[1])), float(p[3]), float(p[3]), h - 0.3, 8, 0.0,
				1.0, 1.0)
	# The bronze-dark portrait relief plaque beside the pipes.
	lm.box("Bronze", Vector3(5.8, 0.9, 3.2), Vector3(1.4, 1.2, 0.4), Basis(Vector3.UP, 0.5))
	lm.commit(model)

# --- Suomenlinna ------------------------------------------------------

## The sea fortress of Suomenlinna in one frame, origin at the church
## (registry yaw -62, the church axis turned onto the map): the church
## of 1854 with its 42 m central tower carrying the light of 1929, four
## corner turrets, west porch and east apse, plus a stretch of granite
## rampart with an earth bank, a bastion and the King's Gate. The gate and
## rampart stand compressed beside the church (the real gate is ~900 m
## south on Kustaanmiekka).
static func suomenlinna(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E6DDB8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1ECDA", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8F7C", 2.0, 0.5, 0.3))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7A7872", 4.0))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#6D7A4A", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE9B8", 0.9))
	# Church body 23 x 23 m on a granite plinth, low copper hip roof.
	FhU.blk(lm, "Granite", 0.0, -1.0, -0.1, 24.0, 2.0, 24.0)
	FhU.blk(lm, "Plaster", 0.0, 1.0, -0.1, 23.0, 10.0, 23.4)
	FhU.blk(lm, "Trim", 0.0, 10.6, -0.1, 23.8, 0.8, 24.2)
	FhU.hip(lm, "Copper", Vector3(0, 11.4, -0.1), 22.0, 22.4, 2.6, 0.5)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		var off := 11.75
		for k in [-1.0, 1.0]:
			FhU.opening(lm, "Glass", Vector3(0, 3.2, -0.1) + out * off + r * Vector3(k * 4.6, 0, 0), out, 2.0, 5.6)
	# Four corner turrets, 4 x 4 m, under small copper spires.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := Vector3(sx * 9.6, 0.0, sz * 9.6 - 0.1)
			FhU.blk(lm, "Plaster", tc.x, 11.2, tc.z, 4.2, 6.6, 4.2)
			FhU.blk(lm, "Trim", tc.x, 17.6, tc.z, 4.8, 0.5, 4.8)
			FhU.hip(lm, "Copper", Vector3(tc.x, 18.1, tc.z), 4.6, 4.6, 4.4)
			FhU.opening(lm, "Glass", Vector3(tc.x, 12.4, tc.z + sz * 2.12), Vector3(0, 0, sz), 1.0, 3.2)
	# West porch and east apse.
	FhU.blk(lm, "Plaster", -14.0, 1.0, 0.0, 6.0, 9.0, 9.0)
	FhU.ridge_x(lm, "Copper", "Plaster", Vector3(-14.0, 10.0, 0.0), 6.0, 9.0, 3.2, 0.4)
	FhU.opening(lm, "Glass", Vector3(-17.05, 1.0, 0.0), Vector3(-1, 0, 0), 2.8, 5.5)
	lm.frustum("Plaster", Vector3(13.5, 1.0, -0.6), 5.2, 5.2, 8.0, 10)
	lm.lathe("Copper", Vector3(13.5, 9.0, -0.6), PackedVector2Array([Vector2(5.5, 0), Vector2(0, 3.2)]), 10)
	# Central tower: 12 m shaft, drum, glazed light, copper dome and finial.
	FhU.blk(lm, "Plaster", 0.0, 11.0, -0.1, 12.0, 16.0, 12.0)
	FhU.blk(lm, "Trim", 0.0, 26.8, -0.1, 13.0, 0.8, 13.0)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		FhU.opening(lm, "Glass", Vector3(0, 16.5, -0.1) + out * 6.05, out, 1.8, 6.5)
		FhU.opening(lm, "Glass", Vector3(0, 20.5, -0.1) + out * 6.05, out, 1.8, 4.0)
	lm.frustum("Plaster", Vector3(0, 27.6, -0.1), 5.0, 5.0, 4.8, 8, PI / 8.0)
	lm.frustum("Trim", Vector3(0, 32.4, -0.1), 5.4, 5.4, 0.6, 8, PI / 8.0)
	lm.frustum("Lamp", Vector3(0, 33.0, -0.1), 3.0, 3.0, 3.4, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(0, 36.4, -0.1), FhU.dome_prof(3.4, 3.4, 8), 8, 1.0, 1.0, PI / 8.0)
	lm.box("Copper", Vector3(0, 40.8, -0.1), Vector3(0.3, 2.4, 0.3))
	# Rampart: granite wall with merlons, earth bank behind, bastion at the end.
	FhU.blk(lm, "Granite", 22.5, -2.0, 38.0, 85.0, 10.0, 5.0)
	FhU.blk(lm, "Granite", 22.5, 8.0, 38.0, 86.0, 0.6, 5.8)
	FhU.merlons(lm, "Granite", Vector3(-20.0, 8.6, 40.2), Vector3(65.0, 8.6, 40.2), 3.0, 1.6, 1.2, 1.0)
	FhU.wedge(lm, "Grass", "Grass", -20.0, 65.0, 26.0, 35.5, 0.0, 0.5, 8.0)
	lm.frustum("Granite", Vector3(62.0, -2.0, 42.0), 14.0, 11.5, 10.6, 5, 0.3)
	lm.frustum("Grass", Vector3(62.0, 8.6, 42.0), 10.0, 9.6, 0.4, 5, 0.3)
	# King's Gate: central block with its arched passage, wings and flagpole.
	FhU.blk(lm, "Granite", 8.0, 0.0, 37.0, 13.0, 11.0, 8.0)
	FhU.blk(lm, "Trim", 8.0, 11.0, 37.0, 14.0, 0.7, 9.0)
	FhU.hip(lm, "Copper", Vector3(8.0, 11.7, 37.0), 13.6, 8.6, 3.0, 0.3)
	FhU.opening(lm, "Glass", Vector3(8.0, 0.0, 41.05), Vector3(0, 0, 1), 4.2, 6.6)
	FhU.opening(lm, "Glass", Vector3(8.0, 0.0, 32.95), Vector3(0, 0, -1), 4.2, 6.6)
	for s in [-1.0, 1.0]:
		FhU.blk(lm, "Granite", 8.0 + s * 9.0, 0.0, 37.0, 5.0, 8.0, 7.0)
		FhU.blk(lm, "Trim", 8.0 + s * 9.0, 8.0, 37.0, 5.6, 0.5, 7.6)
	lm.box("Trim", Vector3(8.0, 17.0, 37.0), Vector3(0.18, 5.0, 0.18))
	lm.commit(model)

# --- Helsinki Olympic Stadium -------------------------------------------

## Lindegren and Jäntti's stadium (1938), origin at the OSM centre, the
## long axis north-south: the cream concrete ring wall, the roof ring
## over the stands, the seating bowl and pitch, and the 72.71 m tower at
## the south-west stand (the length of Matti Järvinen's 1932 javelin
## throw) with its observation deck.
static func stadium(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#E6E1D2", 4.0))
	lm.use("Band", LandmarkMaterials.pbr("limestone", "#CFC9B8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8E8F8C", 3.0, 0.5, 0.3))
	lm.use("Seat", LandmarkMaterials.pbr("concrete", "#7A8794", 3.0))
	lm.use("Pitch", LandmarkMaterials.pbr("grass", "#5E8A44", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var foot := PackedVector2Array([Vector2(-68.7, 78.4), Vector2(-88.6, -35.0), Vector2(-86.0, -68.8),
		Vector2(-75.7, -89.0), Vector2(-50.5, -110.8), Vector2(-18.6, -120.7), Vector2(10.4, -119.4),
		Vector2(27.1, -113.9), Vector2(38.7, -108.2), Vector2(52.4, -94.8), Vector2(64.5, -80.4),
		Vector2(70.4, -61.2), Vector2(89.4, 44.7), Vector2(86.2, 71.2), Vector2(72.9, 93.6),
		Vector2(45.0, 114.6), Vector2(23.6, 121.2), Vector2(0.8, 122.2), Vector2(-20.0, 118.0),
		Vector2(-39.5, 107.5), Vector2(-54.6, 91.8), Vector2(-58.6, 76.6)])
	var wall_h := 22.0
	var n := foot.size()
	for i in n:
		var a := foot[i]
		var b := foot[(i + 1) % n]
		var mid := (a + b) * 0.5
		var d := mid.normalized()
		var out := Vector3(d.x, 0, d.y)
		# Outer wall with two horizontal bands, roof ring, fascia and seating bowl.
		lm.quad("Wall", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(b.x, wall_h, b.y),
				Vector3(a.x, wall_h, a.y), out)
		for h in [7.0, 14.5]:
			lm.quad("Band", Vector3(a.x, h, a.y) + out * 0.15, Vector3(b.x, h, b.y) + out * 0.15,
				Vector3(b.x, h + 1.2, b.y) + out * 0.15, Vector3(a.x, h + 1.2, a.y) + out * 0.15, out)
		var qa := a * 0.64
		var qb := b * 0.64
		lm.quad("Roof", Vector3(a.x, wall_h, a.y), Vector3(b.x, wall_h, b.y), Vector3(qb.x, wall_h, qb.y),
			Vector3(qa.x, wall_h, qa.y), Vector3.UP)
		lm.quad("Roof", Vector3(qa.x, wall_h, qa.y), Vector3(qb.x, wall_h, qb.y), Vector3(qb.x, wall_h - 1.8, qb.y),
			Vector3(qa.x, wall_h - 1.8, qa.y), -out)
		var sa := a * 0.62
		var sb := b * 0.62
		var pa := a * 0.4
		var pb := b * 0.4
		var slope := Vector3(-d.x * 16.0, mid.length() * 0.22, -d.y * 16.0).normalized()
		lm.quad("Seat", Vector3(sa.x, 19.0, sa.y), Vector3(sb.x, 19.0, sb.y), Vector3(pb.x, 2.5, pb.y),
			Vector3(pa.x, 2.5, pa.y), slope)
	var pitch := PackedVector2Array()
	for p in foot:
		pitch.append(p * 0.4)
	lm.poly_prism("Pitch", pitch, 0.0, 2.5)
	# The tower: shaft, observation deck, upper shaft and mast.
	var t := Vector2(-68.0, 72.0)
	FhU.blk(lm, "Wall", t.x, 0.0, t.y, 5.6, 58.0, 8.2)
	for k in 4:
		FhU.openings(lm, "Glass", Vector3(t.x, 8.0 + 12.0 * float(k), t.y + 4.12),
				Vector3(t.x, 8.0 + 12.0 * float(k), t.y + 4.12),
			Vector3(0, 0, 1), 0.0, 1, 1.0, 5.0, false)
	FhU.blk(lm, "Band", t.x, 58.0, t.y, 7.4, 1.0, 10.0)
	FhU.blk(lm, "Glass", t.x, 59.0, t.y, 6.4, 4.6, 9.0)
	FhU.blk(lm, "Band", t.x, 63.6, t.y, 7.4, 0.8, 10.0)
	FhU.blk(lm, "Wall", t.x, 64.4, t.y, 4.4, 8.3, 6.4)
	lm.commit(model)

# --- Hanko Water Tower --------------------------------------------------

## The water tower on Vartiovuori in Hanko (Liljequist, 1943, replacing
## the granite tower of 1910 blown up in 1941): a 12 m octagonal brick shaft
## on a granite base with narrow slits, the wider tank storey with its
## viewing gallery, and a low copper cone roof, 48 m in all.
static func hanko(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B79B6B", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#868680", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8F7C", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Band", LandmarkMaterials.pbr("concrete", "#B8B4AA", 3.0))
	lm.frustum("Granite", Vector3(0, -1.0, 0), 7.2, 6.6, 8.0, 8, PI / 8.0)
	lm.frustum("Brick", Vector3(0, 7.0, 0), 6.4, 6.0, 30.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var out := Vector3(cos(a), 0, sin(a))
		for h in [12.0, 20.0, 28.0]:
			var rr: float = (6.4 - 0.4 * (float(h) - 7.0) / 30.0) * cos(PI / 8.0) + 0.05
			FhU.opening(lm, "Glass", Vector3(0, h, 0) + out * rr, out, 0.8, 4.0, false)
	lm.frustum("Band", Vector3(0, 37.0, 0), 6.6, 8.0, 1.2, 8, PI / 8.0)
	lm.frustum("Brick", Vector3(0, 38.2, 0), 7.7, 7.7, 6.0, 8, PI / 8.0)
	lm.frustum("Glass", Vector3(0, 41.0, 0), 7.78, 7.78, 2.2, 8, PI / 8.0)
	lm.frustum("Band", Vector3(0, 44.2, 0), 8.2, 8.2, 0.7, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(0, 44.9, 0),
			PackedVector2Array([Vector2(8.3, 0), Vector2(4.0, 1.9), Vector2(0.4, 3.1)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.commit(model)
