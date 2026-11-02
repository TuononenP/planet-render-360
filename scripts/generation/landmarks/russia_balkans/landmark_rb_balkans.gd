class_name LandmarkRbBalkans
extends RefCounted

## Saint Sophia Cathedral in Kyiv in true metres (1037, rebuilt in
## Ukrainian Baroque 1690-1707): 41.7 m east-west by 54.6 m north-south,
## the five-nave cross-domed core stepping up inside its two-tier inner
## and outer galleries, five apses on the east, thirteen green and
## gilded pear domes and the curved Baroque gables; with the four-tier
## Baroque bell tower (1699-1706, fourth tier 1851-1852), 76 m.

const SOPHIA_TOP := 76.0

## Pear-shaped Ukrainian-baroque dome of base radius r and height h.
static func _pear(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 16) -> void:
	var f := [[0.82, 0.0], [1.0, 0.1], [1.08, 0.26], [0.92, 0.42], [0.6, 0.58], [0.38, 0.7],
		[0.3, 0.76], [0.36, 0.8], [0.2, 0.88], [0.0, 1.0]]
	var p := PackedVector2Array()
	for q in f:
		p.append(Vector2(r * float(q[0]), h * float(q[1])))
	lm.lathe(key, base, p, seg)

## Drum with pilasters and arched windows, cornice ring, pear dome,
## lantern neck and cross on `base`; returns the cross tip y.
static func _dome(lm: LandmarkMesh, wall: String, dome: String, gilt: String, base: Vector3,
		r: float, drum_h: float, dome_h: float, cross_h: float) -> float:
	lm.frustum(wall, base, r, r, drum_h, 16)
	var nw := 8 if r > 3.0 else 6
	for i in nw:
		var a := TAU * float(i) / float(nw)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box(wall, base + d * (r + 0.08) + Vector3(0, drum_h * 0.5, 0), Vector3(r * 0.14, drum_h, 0.2), Basis.looking_at(d), 0.0)
		var wa := a + PI / float(nw)
		SEuUtil.opening(lm, "Windows", base + Vector3(cos(wa), 0, sin(wa)) * (r * cos(PI / 16.0) + 0.04)
			+ Vector3(0, drum_h * 0.22, 0), Vector3.UP.cross(Vector3(cos(wa), 0, sin(wa))), Vector3.UP, r * 0.26, drum_h * 0.55)
	lm.frustum(wall, base + Vector3(0, drum_h, 0), r * 1.12, r * 1.12, r * 0.12, 16)
	var top := base + Vector3(0, drum_h + r * 0.12, 0)
	_pear(lm, dome, top, r * 1.05, dome_h)
	LandmarkRbParts.cross(lm, gilt, top + Vector3(0, dome_h, 0), cross_h)
	return top.y + dome_h + cross_h

## Ukrainian Baroque gable of width w on `c` (foot centre on the wall
## face looking along `out`): curved ogee crest over a stepped panel,
## scroll ends and a finial.
static func _gable(lm: LandmarkMesh, c: Vector3, out: Vector3, w: float) -> void:
	var b := LandmarkRbParts.facing(out)
	var right := b.x
	lm.box("Wall", c + Vector3(0, w * 0.18, 0) - out * 0.3, Vector3(w, w * 0.36, 0.8), b)
	LandmarkRbParts.kokoshnik(lm, "White", "Wall", c + Vector3(0, w * 0.36, 0), out, w * 0.62, 0.5, true)
	lm.box("Wall", c + Vector3(0, w * 0.36 + w * 0.2, 0) - out * 0.3, Vector3(w * 0.5, w * 0.4, 0.8), b)
	for s in [-1.0, 1.0]:
		lm.disc("White", c + right * (s * w * 0.42) + Vector3(0, w * 0.3, 0) + out * 0.12, out, w * 0.07, 10)
		lm.beam("White", c + right * (s * w * 0.5) + out * 0.1, c + right * (s * w * 0.31) + Vector3(0, w * 0.36, 0) + out * 0.1,
			0.35, 0.3, out)
	LandmarkDetail.window(lm, "White", "Windows", c + Vector3(0, w * 0.3, 0) + out * 0.12, out, w * 0.1, w * 0.18, true, 0.15)
	lm.lathe("Gilt", c + Vector3(0, w * 0.36 + w * 0.62 * 0.5 * 1.6, 0), LandmarkRbParts.dome_profile(0.35, 0.6, 3), 8)

## Origin at the cathedral centre; the apses face +X, the galleries
## wrap the north (-Z), west (-X) and south (+Z) sides; the bell tower
## stands 71 m off to the +X, -Z side.
static func kyiv_sophia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFEADB", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F7F4EA", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9A9486", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6E7F74", 3.0, 0.6, 0.2))
	lm.use("Green", LandmarkMaterials.pbr("concrete", "#4F8A6C", 2.5, 0.4, 0.45))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Stepped masses: outer galleries (two storeys after the Baroque
	# raising, 11 m), the inner galleries and naves (17 m) and the cross
	# under the central dome (24.5 m).
	lm.box("Plinth", Vector3(-4.5, 0.4, 0), Vector3(36.0, 0.8, 55.2))
	lm.box("Wall", Vector3(-4.5, 5.5, 0), Vector3(35.0, 11.0, 54.6))
	lm.box("White", Vector3(-4.5, 11.2, 0), Vector3(35.8, 0.5, 55.4))
	lm.box("Roof", Vector3(-4.5, 11.5, 0), Vector3(34.0, 0.2, 53.6))
	lm.box("Wall", Vector3(-1.5, 8.5, 0), Vector3(29.0, 17.0, 42.0))
	lm.box("White", Vector3(-1.5, 17.2, 0), Vector3(29.8, 0.5, 42.8))
	lm.box("Wall", Vector3(-1.5, 12.25, 0), Vector3(29.0, 24.5, 12.0))
	lm.box("Wall", Vector3(0, 12.25, 0), Vector3(12.0, 24.5, 30.0))
	lm.box("White", Vector3(-1.5, 24.7, 0), Vector3(29.8, 0.5, 12.8))
	lm.box("White", Vector3(0, 24.7, 0), Vector3(12.8, 0.5, 30.8))
	for sz in [-1.0, 1.0]:
		lm.gable("Roof", Vector3(0, 24.9, sz * 10.5), 12.0, 9.0, 3.0, Basis(), 0.3, "Wall")
	lm.gable("Roof", Vector3(-12.0, 24.9, 0), 12.0, 8.0, 3.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Wall")
	# Five apses on the east: the central one rises to the naves' roof.
	for z in [-14.0, -7.0, 0.0, 7.0, 14.0]:
		var big := absf(z) < 1.0
		var r := 6.0 if big else (3.2 if absf(z) < 8.0 else 2.8)
		var h := 15.0 if big else (12.0 if absf(z) < 8.0 else 9.5)
		lm.frustum("Wall", Vector3(13.0, 0, z), r, r, h, 16, -PI * 0.5)
		lm.frustum("White", Vector3(13.0, h, z), r + 0.4, r + 0.4, 0.5, 16)
		lm.lathe("Roof", Vector3(13.0, h + 0.5, z), LandmarkRbParts.dome_profile(r + 0.2, r * 0.6, 5), 16)
		for k in [-1.0, 0.0, 1.0]:
			var a := float(k) * 0.55
			var d := Vector3(cos(a), 0, sin(a))
			if big or k == 0.0:
				LandmarkDetail.window(lm, "White", "Windows", Vector3(13.0, h * 0.55, z) + d * (r - 0.05), d,
					1.2 if big else 0.9, 3.2 if big else 2.6, true, 0.2)
		for k in 5:
			var a := -PI * 0.4 + PI * 0.2 * float(k)
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("White", Vector3(13.0, h * 0.5, z) + d * (r + 0.08), Vector3(0.5, h, 0.25), Basis.looking_at(d), 0.0)
	# Outer gallery fronts: two storeys of framed windows between
	# buttresses, Baroque gables on the roofline.
	var fronts := [[Vector3(0, 0, 1), Vector3(-4.5, 0, 27.3), 35.0, 3], [Vector3(0, 0, -1), Vector3(-4.5, 0, -27.3), 35.0, 3],
		[Vector3(-1, 0, 0), Vector3(-22.0, 0, 0), 54.6, 5]]
	for f in fronts:
		var out: Vector3 = f[0]
		var o: Vector3 = f[1]
		var wl: float = f[2]
		var ng: int = f[3]
		var b := LandmarkRbParts.facing(out)
		var right := b.x
		var n := roundi(wl / 4.6)
		var pitch := wl / float(n)
		for i in n:
			var x := -wl * 0.5 + pitch * (float(i) + 0.5)
			LandmarkDetail.window(lm, "White", "Windows", o + right * x + Vector3(0, 3.6, 0), out, 1.5, 3.4, true, 0.25)
			LandmarkDetail.window(lm, "White", "Windows", o + right * x + Vector3(0, 8.4, 0), out, 1.4, 2.8, true, 0.25)
		for i in n + 1:
			var x := -wl * 0.5 + pitch * float(i)
			# Stepped buttress.
			lm.box("Wall", o + right * x + out * 0.6 + Vector3(0, 3.5, 0), Vector3(1.0, 7.0, 1.2), b)
			lm.box("Wall", o + right * x + out * 0.35 + Vector3(0, 8.5, 0), Vector3(0.9, 3.0, 0.7), b)
			lm.box("White", o + right * x + out * 0.85 + Vector3(0, 7.1, 0), Vector3(1.1, 0.25, 0.8), b, 0.0)
		for g in ng:
			var gx := -wl * 0.5 + wl * (float(g) + 0.5) / float(ng)
			_gable(lm, o + right * gx + Vector3(0, 11.4, 0), out, 8.0 if ng == 3 else 7.0)
	# Inner (17 m) and core (24.5 m) walls: clerestory windows, pilasters.
	for sz in [-1.0, 1.0]:
		var out := Vector3(0, 0, sz)
		for i in 5:
			var x := -1.5 + (float(i) - 2.0) * 5.6
			LandmarkDetail.window(lm, "White", "Windows", Vector3(x, 14.0, sz * 21.0), out, 1.3, 3.0, true, 0.2)
			lm.box("White", Vector3(x + 2.8, 14.3, sz * 21.1), Vector3(0.6, 5.0, 0.25), Basis(), 0.0)
		for x in [-3.0, 3.0]:
			LandmarkDetail.window(lm, "White", "Windows", Vector3(float(x), 20.5, sz * 15.0), out, 1.4, 3.4, true, 0.2)
	for x in [-6.0, 6.0]:
		LandmarkDetail.window(lm, "White", "Windows", Vector3(-16.0, 20.5, float(x) * 0.6), Vector3(-1, 0, 0), 1.3, 3.2, true, 0.2)
	# Thirteen domes: the gilded crossing dome, four green ones round it,
	# four gilded over the inner galleries' corners, three over the
	# apses and one over the west porch.
	_dome(lm, "Wall", "Gilt", "Gilt", Vector3(0, 24.95, 0), 4.7, 7.5, 6.8, 4.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_dome(lm, "Wall", "Green", "Gilt", Vector3(sx * 9.5 - 1.5, 17.4, sz * 10.5), 3.0, 6.0, 5.2, 3.0)
			_dome(lm, "Wall", "Gilt", "Gilt", Vector3(-1.5 + sx * 11.5, 17.4, sz * 17.5), 2.4, 5.0, 4.4, 2.6)
	for z in [-7.0, 0.0, 7.0]:
		_dome(lm, "Wall", "Green", "Gilt", Vector3(13.0, 17.4 if z == 0.0 else 13.6, z), 2.2 if z == 0.0 else 1.9, 3.0, 4.0, 2.2)
	_dome(lm, "Wall", "Green", "Gilt", Vector3(-19.0, 11.7, 0), 2.4, 4.5, 4.4, 2.6)
	_sophia_tower(lm, Vector3(43.1, 0, -56.4))
	lm.commit(model)

## The four-tier Baroque bell tower: the gate tier (archway and
## loopholes), the open gallery tier, the tier with round windows, the
## octagonal bell tier and the gilded pear dome with its cross (76 m).
static func _sophia_tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Plinth", c + Vector3(0, 0.5, 0), Vector3(19.0, 1.0, 19.0))
	lm.box("Wall", c + Vector3(0, 11.5, 0), Vector3(17.0, 21.0, 17.0))
	lm.box("White", c + Vector3(0, 22.0, 0), Vector3(18.4, 2.0, 18.4))
	lm.box("Wall", c + Vector3(0, 32.0, 0), Vector3(14.0, 18.0, 14.0))
	lm.box("White", c + Vector3(0, 41.5, 0), Vector3(15.4, 1.5, 15.4))
	lm.box("Wall", c + Vector3(0, 49.5, 0), Vector3(11.0, 14.0, 11.0))
	lm.box("White", c + Vector3(0, 57.0, 0), Vector3(12.4, 1.4, 12.4))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var b := LandmarkRbParts.facing(out)
		var right := b.x
		# Gate tier: the archway, loopholes, paired pilasters, cornice.
		SEuUtil.opening(lm, "Windows", c + out * 8.55 + Vector3(0, 1.0, 0), right, Vector3.UP, 5.0, 11.0)
		LandmarkDetail.arch(lm, "White", c + out * 8.5 + Vector3(0, 9.5, 0), out, 5.0, 0.7, 0.4)
		for sgn in [-1.0, 1.0]:
			lm.box("Windows", c + out * 8.52 + right * sgn * 5.0 + Vector3(0, 15.0, 0), Vector3(0.6, 1.4, 0.05), b, 0.0)
			LandmarkDetail.window(lm, "White", "Windows", c + out * 8.52 + right * sgn * 5.0 + Vector3(0, 6.0, 0), out, 1.4, 3.0, true, 0.2)
			for p in [3.2, 7.2]:
				LandmarkRbParts.pilaster(lm, "White", c + out * 8.5 + right * (sgn * float(p)) + Vector3(0, 1.0, 0), out, 0.8, 20.0, 0.25)
		LandmarkDetail.cornice(lm, "White", c + out * 8.5 - right * 8.5 + Vector3(0, 20.3, 0), c + out * 8.5 + right * 8.5
			+ Vector3(0, 20.3, 0), out, 0.8, true)
		# Gallery tier: three arched openings between columns.
		for i in 3:
			var x := (float(i) - 1.0) * 4.0
			SEuUtil.opening(lm, "Windows", c + out * 7.05 + right * x + Vector3(0, 25.0, 0), right, Vector3.UP, 2.6, 9.0)
			LandmarkDetail.arch(lm, "White", c + out * 7.0 + right * x + Vector3(0, 32.7, 0), out, 2.6, 0.4, 0.3)
		for i in 4:
			LandmarkRbParts.order_column(lm, "White", c + out * 7.4 + right * ((float(i) - 1.5) * 4.0) + Vector3(0, 23.0, 0),
				0.4, 17.0, "ionic", out, 8)
		LandmarkRbParts.balustrade(lm, "White", c + out * 7.6 - right * 7.0 + Vector3(0, 42.25, 0),
			c + out * 7.6 + right * 7.0 + Vector3(0, 42.25, 0), 1.0, 0.6, 3.5)
		# Third tier: round windows over arched ones, corner pilasters.
		lm.disc("White", c + out * 5.52 + Vector3(0, 52.5, 0), out, 1.7, 16)
		lm.disc("Windows", c + out * 5.56 + Vector3(0, 52.5, 0), out, 1.3, 16)
		for sgn in [-1.0, 1.0]:
			SEuUtil.opening(lm, "Windows", c + out * 5.55 + right * sgn * 2.4 + Vector3(0, 44.0, 0), right, Vector3.UP, 1.6, 5.5)
			LandmarkRbParts.pilaster(lm, "White", c + out * 5.5 + right * (sgn * 4.9) + Vector3(0, 42.3, 0), out, 0.8, 14.0, 0.25)
	# Small gilded domes at the corners of the second tier.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.lathe("Gilt", c + Vector3(sx * 6.2, 42.4, sz * 6.2), LandmarkRbParts.dome_profile(1.1, 2.6, 4), 8)
			LandmarkRbParts.urn(lm, "White", c + Vector3(sx * 5.0, 57.7, sz * 5.0), 1.8)
	# Octagonal bell tier with arched openings, the pear dome and cross.
	lm.frustum("Wall", c + Vector3(0, 57.7, 0), 4.6, 4.2, 5.5, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Windows", c + Vector3(0, 57.7, 0), 4.4, 8, 8, 0.8, 1.6, 4.0, false, 0.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.box("White", c + Vector3(cos(a) * 4.45, 60.45, sin(a) * 4.45), Vector3(0.5, 5.5, 0.5), Basis(Vector3.UP, -a))
	lm.frustum("White", c + Vector3(0, 63.2, 0), 4.9, 4.9, 0.6, 8, PI / 8.0)
	_pear(lm, "Gilt", c + Vector3(0, 63.8, 0), 4.6, 8.7, 20)
	LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 72.5, 0), SOPHIA_TOP - 72.5)
