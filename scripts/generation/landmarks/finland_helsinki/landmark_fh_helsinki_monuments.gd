class_name LandmarkFhHelsinkiMonuments
extends RefCounted

## Four Finnish monuments in true metres: the Sibelius Monument (steel
## organ pipes), the Suomenlinna sea fortress (church with its light
## tower, rampart and King's Gate), the Helsinki Olympic Stadium with its
## 72.71 m tower and the Hanko water tower.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

# --- Sibelius Monument ----------------------------------------------

## Eila Hiltunen's "Passio Musicae" (1967): more than 600 welded pipes of
## acid-proof stainless steel, 24 tonnes, in a wave-like cluster 8.5 m
## high, 10.5 m long and 6.5 m deep, lifted off the rock on a few legs so
## the lower ends hang free at varying heights, the open ends cut and
## textured; beside it on its own rock the steel portrait of Sibelius.
## Origin at the centre of the sculpture's footprint.
static func sibelius(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#C3C9CC", 2.0, 0.25, 0.85))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7C776E", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8782", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F4A3C", 2.0, 0.4, 0.6))
	# The rock of Sibelius Park under the sculpture.
	lm.lathe("Rock", Vector3(0, 0, 0), PackedVector2Array([Vector2(10.5, 0), Vector2(9.0, 0.5),
		Vector2(7.2, 0.8), Vector2(6.4, 0.85)]), 18, 1.1, 0.9, 0.4, false)
	# Pipes on a packed staggered grid: tops rise in a swell toward the
	# back left and fall in waves; the bottoms hang free in a second wave.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1967
	var tops: Array = []
	var top_max := 0.0
	for iz in 20:
		for ix in 32:
			var x := -5.1 + 10.2 * float(ix) / 31.0 + (0.16 if iz % 2 == 1 else 0.0)
			var z := -3.1 + 6.2 * float(iz) / 19.0
			var e := pow(x / 5.25, 2.0) + pow(z / 3.25, 2.0)
			if e > 1.0 or rng.randf() < 0.04:
				continue
			var swell := exp(-(pow(x + 2.0, 2.0) / 9.0 + pow(z + 0.6, 2.0) / 5.0))
			var top := 3.6 + 4.2 * swell + 1.2 * sin(0.7 * x + 0.5 * z) + 0.7 * sin(1.4 * z - 0.3 * x) \
				+ rng.randf_range(-0.35, 0.35)
			tops.append([x, z, top, rng.randf_range(0.08, 0.17)])
			top_max = maxf(top_max, top)
	var scale_h := 8.5 / top_max
	for p in tops:
		var x: float = p[0]
		var z: float = p[1]
		var top: float = float(p[2]) * scale_h
		var bot := 1.3 + 0.9 * sin(0.9 * x + 1.1 * z) + 0.4 * sin(2.3 * x) + (top - 4.0) * 0.12
		bot = clampf(bot, 0.9, top - 1.5)
		var r: float = p[3]
		lm.frustum("Steel", Vector3(x, bot, z), r, r, top - bot, 6, x * 3.0)
		# Cut, flared lower ends on a few pipes.
		if int(absf(x * 7.0 + z * 3.0)) % 5 == 0:
			lm.frustum("Steel", Vector3(x, bot - 0.08, z), r * 1.25, r, 0.12, 6, x)
	# Legs carrying the cluster down to the rock.
	for q in [Vector3(-3.4, 0.8, -1.2), Vector3(-1.0, 0.8, 1.6), Vector3(1.6, 0.8, -1.4), Vector3(3.6, 0.8, 0.8),
			Vector3(-0.2, 0.8, -0.2)]:
		lm.frustum("Steel", q, 0.22, 0.18, 1.2, 8)
	# The portrait of Sibelius on its own rock beside the pipes.
	var ph := Vector3(6.4, 0.0, 3.6)
	lm.lathe("Rock", ph, PackedVector2Array([Vector2(1.8, 0), Vector2(1.5, 0.9), Vector2(1.0, 1.4), Vector2(0.6, 1.5)]),
		10, 1.0, 0.8, 0.3, false)
	var pb := Basis(Vector3.UP, 0.5)
	lm.box("Steel", ph + Vector3(0, 1.6, 0), Vector3(0.3, 0.3, 0.3), pb)
	lm.lathe("Steel", ph + Vector3(0, 1.7, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.45, 0.1),
		Vector2(0.62, 0.5), Vector2(0.66, 1.0), Vector2(0.58, 1.5), Vector2(0.4, 1.85), Vector2(0.0, 2.0)]), 14, 0.8, 1.0)
	for k in 9:
		lm.beam("Bronze", ph + pb * Vector3(-0.5 + 0.12 * float(k), 3.2, 0.1),
			ph + pb * Vector3(-0.6 + 0.15 * float(k), 3.85, 0.0), 0.08, 0.06)
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
	FhU.blk(lm, "Granite", 0.0, 0.0, -0.1, 24.0, 1.0, 24.0)
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
	# Classical detail of the 1929 renovation: pilasters and pediments on
	# the four fronts, the lantern's glazing bars.
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = r * Vector3(0, 0, 1)
		var rt: Vector3 = r * Vector3(1, 0, 0)
		var fc := Vector3(0, 0, -0.1) + out * 11.6
		FhP.strips(lm, "Trim", fc - rt * 7.2, fc + rt * 7.2, out, 1.0, 9.6, 4, 0.7, 0.25)
		lm.gable("Copper", Vector3(0, 11.4, -0.1) + out * 9.6, 9.0, 4.4, 2.2, r, 0.2, "Trim")
		FhP.win_row(lm, "Trim", "Glass", fc - rt * 2.0, fc + rt * 2.0, out, 3.2, 1, 2.0, 5.6, true, 0.25)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Trim", Vector3(cos(a) * 3.0, 34.7, sin(a) * 3.0 - 0.1), Vector3(0.12, 3.4, 0.12), Basis(), 0.0)
	# The fence of upright cannon barrels and hanging chains (1870s).
	var fence := PackedVector2Array([Vector2(-19.0, -14.5), Vector2(19.5, -14.5), Vector2(19.5, 14.5),
		Vector2(-19.0, 14.5)])
	for i in 4:
		var p0 := fence[i]
		var p1 := fence[(i + 1) % 4]
		var n := int(p0.distance_to(p1) / 3.2)
		var prev := Vector3.ZERO
		for k in n + 1:
			var p := Vector2(p0.lerp(p1, float(k) / float(n)))
			var cb := Vector3(p.x, 0.0, p.y)
			lm.frustum("Granite", cb, 0.2, 0.12, 1.5, 8)
			lm.frustum("Granite", cb + Vector3(0, 1.5, 0), 0.16, 0.16, 0.12, 8)
			if k > 0:
				var mid := (prev + cb) * 0.5 + Vector3(0, 0.75, 0)
				lm.beam("Granite", prev + Vector3(0, 1.2, 0), mid, 0.06, 0.06)
				lm.beam("Granite", mid, cb + Vector3(0, 1.2, 0), 0.06, 0.06)
			prev = cb
	# Rampart: granite wall with merlons, earth bank behind, bastion at the end.
	FhU.blk(lm, "Granite", 22.5, 0.0, 38.0, 85.0, 8.0, 5.0)
	FhU.blk(lm, "Granite", 22.5, 8.0, 38.0, 86.0, 0.6, 5.8)
	FhU.merlons(lm, "Granite", Vector3(-20.0, 8.6, 40.2), Vector3(65.0, 8.6, 40.2), 3.0, 1.6, 1.2, 1.0)
	FhU.wedge(lm, "Grass", "Grass", -20.0, 65.0, 26.0, 35.5, 0.0, 0.5, 8.0)
	lm.frustum("Granite", Vector3(62.0, 0.0, 42.0), 13.6, 11.5, 8.6, 5, 0.3)
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

## Lindegren and Jäntti's functionalist stadium (1938, renewed 2016-20),
## origin at the OSM centre, the long axis north-south: the white
## concrete outer wall with its ribbon windows and stair towers, the
## canopy ring over the stands on its struts, the tiered seating bowl,
## the running track and pitch (105 x 68 m), and the 72.71 m tower (the
## length of Matti Järvinen's 1932 javelin record) at the south-west:
## slender white shaft with its vertical window slit, the glazed lookout
## and the mast.
static func stadium(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#E6E1D2", 4.0))
	lm.use("Band", LandmarkMaterials.pbr("limestone", "#CFC9B8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8E8F8C", 3.0, 0.5, 0.3))
	lm.use("Seat", LandmarkMaterials.pbr("concrete", "#7A8794", 3.0))
	lm.use("Pitch", LandmarkMaterials.pbr("grass", "#5E8A44", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Track", LandmarkMaterials.pbr("concrete", "#9A4A3A", 3.0))
	var foot := PackedVector2Array([Vector2(-68.7, 78.4), Vector2(-88.6, -35.0), Vector2(-86.0, -68.8),
		Vector2(-75.7, -89.0), Vector2(-50.5, -110.8), Vector2(-18.6, -120.7), Vector2(10.4, -119.4),
		Vector2(27.1, -113.9), Vector2(38.7, -108.2), Vector2(52.4, -94.8), Vector2(64.5, -80.4),
		Vector2(70.4, -61.2), Vector2(89.4, 44.7), Vector2(86.2, 71.2), Vector2(72.9, 93.6),
		Vector2(45.0, 114.6), Vector2(23.6, 121.2), Vector2(0.8, 122.2), Vector2(-20.0, 118.0),
		Vector2(-39.5, 107.5), Vector2(-54.6, 91.8), Vector2(-58.6, 76.6)])
	var wall_h := 18.0
	var n := foot.size()
	lm.poly_prism("Wall", foot, 0.0, wall_h, false)
	for i in n:
		var a := foot[i]
		var b := foot[(i + 1) % n]
		var mid := (a + b) * 0.5
		var d := mid.normalized()
		var out := FhP.edge_out(foot, i)
		var a3 := Vector3(a.x, 0, a.y)
		var b3 := Vector3(b.x, 0, b.y)
		# Ribbon windows in two bands, pier fins and the parapet band.
		for y in [6.0, 12.0]:
			lm.quad("Glass", a3 + out * 0.03 + Vector3(0, y, 0), b3 + out * 0.03 + Vector3(0, y, 0),
				b3 + out * 0.03 + Vector3(0, y + 1.6, 0), a3 + out * 0.03 + Vector3(0, y + 1.6, 0), out)
			FhP.ribs(lm, "Wall", a3, b3, out, y, y + 1.6, 2.2, 0.25, 0.12)
		FhP.band(lm, "Band", a3, b3, out, wall_h - 0.8, 0.8, 0.3)
		FhP.band(lm, "Band", a3, b3, out, 0.0, 0.6, 0.2)
		# Canopy over the stands: a sloping roof plate from the wall top
		# out over the seats, its fascia, and the struts holding it.
		var qa := a * 0.66
		var qb := b * 0.66
		lm.quad("Roof", Vector3(a.x, wall_h + 3.0, a.y), Vector3(b.x, wall_h + 3.0, b.y), Vector3(qb.x, wall_h + 5.0, qb.y),
			Vector3(qa.x, wall_h + 5.0, qa.y), Vector3.UP)
		lm.quad("Roof", Vector3(qa.x, wall_h + 5.0, qa.y), Vector3(qb.x, wall_h + 5.0, qb.y),
			Vector3(qb.x, wall_h + 3.8, qb.y), Vector3(qa.x, wall_h + 3.8, qa.y), -Vector3(d.x, 0, d.y))
		lm.quad("Wall", Vector3(a.x, wall_h, a.y), Vector3(b.x, wall_h, b.y), Vector3(b.x, wall_h + 3.0, b.y),
			Vector3(a.x, wall_h + 3.0, a.y), out)
		lm.beam("Band", Vector3(a.x, wall_h, a.y), Vector3(qa.x, wall_h + 4.9, qa.y), 0.4, 0.5)
		# Tiered seating: stepped rows down to the track.
		var rows := 7
		for k in rows:
			var t0 := float(k) / float(rows)
			var t1 := float(k + 1) / float(rows)
			var s0 := lerpf(0.66, 0.43, t0)
			var s1 := lerpf(0.66, 0.43, t1)
			var y0 := lerpf(wall_h - 1.0, 1.2, t0)
			var y1 := lerpf(wall_h - 1.0, 1.2, t1)
			var p0 := a * s0
			var p1 := b * s0
			var r0 := a * s1
			var r1 := b * s1
			lm.quad("Seat", Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(r1.x, y0, r1.y),
				Vector3(r0.x, y0, r0.y), Vector3.UP)
			lm.quad("Seat", Vector3(r0.x, y0, r0.y), Vector3(r1.x, y0, r1.y), Vector3(r1.x, y1, r1.y),
				Vector3(r0.x, y1, r0.y), -Vector3(d.x, 0, d.y))
	# Track and pitch.
	var track := PackedVector2Array()
	var pitch := PackedVector2Array()
	for p in foot:
		track.append(p * 0.43)
		pitch.append(p * 0.33)
	lm.poly_prism("Track", track, 0.0, 1.2)
	lm.poly_prism("Pitch", pitch, 1.2, 1.25)
	# The tower: shaft with corner fins and its window slit, lookout, mast.
	var t := Vector2(-67.05, 74.3)
	var tb := Basis(Vector3.UP, -0.17)
	lm.box("Wall", Vector3(t.x, 29.0, t.y), Vector3(6.5, 58.0, 8.7), tb)
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(t.x, 29.0, t.y) + tb * Vector3(s * 3.4, 0, 0), Vector3(0.6, 58.0, 9.2), tb)
		lm.box("Glass", Vector3(t.x, 29.0, t.y) + tb * Vector3(0, 0, s * 4.37), Vector3(1.2, 52.0, 0.06), tb, 0.0)
		for k in 17:
			lm.box("Band", Vector3(t.x, 4.5 + 3.1 * float(k), t.y) + tb * Vector3(0, 0, s * 4.4), Vector3(1.4, 0.2, 0.12),
				tb, 0.0)
	lm.box("Band", Vector3(t.x, 58.4, t.y), Vector3(7.6, 0.8, 10.0), tb)
	lm.box("Glass", Vector3(t.x, 61.1, t.y), Vector3(6.6, 4.6, 9.0), tb)
	for k in 6:
		lm.box("Band", Vector3(t.x, 61.1, t.y) + tb * Vector3(-3.3 + 1.32 * float(k), 0, 0), Vector3(0.18, 4.6, 9.1), tb,
			0.0)
	lm.box("Band", Vector3(t.x, 63.8, t.y), Vector3(7.6, 0.8, 10.0), tb)
	lm.box("Wall", Vector3(t.x, 66.2, t.y), Vector3(4.4, 4.0, 6.4), tb)
	lm.box("Band", Vector3(t.x, 68.4, t.y), Vector3(4.8, 0.4, 6.8), tb)
	lm.frustum("Band", Vector3(t.x, 68.6, t.y), 0.12, 0.06, 4.1, 6)
	lm.commit(model)

# --- Hanko Water Tower --------------------------------------------------

## The water tower on Vartiovuori in Hanko (Bertel Liljequist, 1942-43,
## replacing the tower blown up in December 1941), 48 m on a hill 65 m
## above the sea: a red-brick cylinder 13 m across on a granite base,
## rows of slit windows up the stair, pilaster ribs, the wider tank storey
## and the glazed lookout with its gallery under a low copper roof.
static func hanko(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4E3A", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#868680", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8F7C", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Band", LandmarkMaterials.pbr("concrete", "#B8B4AA", 3.0))
	lm.frustum("Granite", Vector3(0, 0, 0), 6.9, 6.6, 6.0, 32)
	lm.frustum("Band", Vector3(0, 5.8, 0), 6.75, 6.75, 0.4, 32)
	lm.frustum("Brick", Vector3(0, 6.0, 0), 6.3, 6.0, 30.0, 32)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Brick", d * 6.2 + Vector3(0, 21.0, 0), Vector3(0.7, 30.0, 0.35), Basis.looking_at(d))
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		for j in 6:
			var y := 9.0 + 4.4 * float(j)
			var rr := 6.3 - 0.3 * (y - 6.0) / 30.0
			FhU.opening(lm, "Glass", d * (rr + 0.04) + Vector3(0, y, 0), d, 0.5, 2.6, false)
	FhU.opening(lm, "Glass", Vector3(0, 0, 6.72), Vector3(0, 0, 1), 1.6, 2.6, false)
	lm.lathe("Brick", Vector3(0, 36.0, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(6.4, 0.6),
		Vector2(6.9, 1.4)]), 32)
	lm.frustum("Band", Vector3(0, 37.4, 0), 7.0, 7.0, 0.4, 32)
	lm.frustum("Brick", Vector3(0, 37.8, 0), 6.7, 6.7, 4.4, 32)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Band", d * 6.75 + Vector3(0, 40.0, 0), Vector3(0.3, 4.4, 0.2), Basis.looking_at(d), 0.0)
	# Lookout storey: glazed band, gallery slab and rail, copper roof.
	lm.frustum("Band", Vector3(0, 42.2, 0), 7.6, 7.6, 0.3, 32)
	lm.frustum("Glass", Vector3(0, 42.5, 0), 6.4, 6.4, 2.6, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Band", d * 6.42 + Vector3(0, 43.8, 0), Vector3(0.2, 2.6, 0.2), Basis.looking_at(d), 0.0)
		lm.frustum("Band", d * 7.45 + Vector3(0, 42.5, 0), 0.04, 0.04, 1.1, 4)
	lm.frustum("Band", Vector3(0, 43.55, 0), 7.5, 7.5, 0.08, 32)
	lm.frustum("Band", Vector3(0, 45.1, 0), 7.0, 7.0, 0.35, 32)
	lm.lathe("Copper", Vector3(0, 45.45, 0), PackedVector2Array([Vector2(7.1, 0), Vector2(4.0, 1.6),
		Vector2(0.6, 2.4), Vector2(0.0, 2.45)]), 32)
	lm.frustum("Copper", Vector3(0, 47.5, 0), 0.08, 0.04, 0.5, 6)
	lm.commit(model)
