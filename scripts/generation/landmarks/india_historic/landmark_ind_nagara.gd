class_name LandmarkIndNagara
extends RefCounted

## Two north and east Indian temples in true metres: the Konark Sun
## Temple (Kalinga style, as it stands) and the Kandariya Mahadeva Temple
## of Khajuraho (nagara style). Both face +X (east).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")

## Konark Sun Temple (30 m, the jagamohana as it stands; c. 1250): the
## temple as Surya's chariot. The moulded platform with 24 carved wheels
## (12 pairs, about 3 m across, eight broad and eight slender spokes) and
## the seven horses at the east stair; the walls of the sanctum (deul)
## that fell in the 19th century, with the green chlorite Surya images in
## their niches; the jagamohana, 30 m square and 30 m high, its
## pancha-ratha walls with chlorite-framed doors under a pida roof of three
## tiers of six receding pidas, musicians standing on the two terraces
## between them and the bell crown with its ribbed amalaka; and the
## roofless Nata Mandir on its carved platform to the east.
static func konark_sun_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E7B66", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5A4E44", 2.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#9A6A48", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#7C8C55", 4.0))
	lm.box("Lawn", Vector3(0, 0.02, 0), Vector3(150.0, 0.04, 100.0))
	# Chariot platform under the deul and jagamohana: plinth mouldings and
	# carved friezes, 72 x 38 m, 4.5 m high.
	var px := -17.0
	lm.box("Laterite", Vector3(px, 0.5, 0), Vector3(74.0, 1.0, 40.0))
	lm.box("Stone", Vector3(px, 2.75, 0), Vector3(72.0, 3.5, 38.0))
	for y in [1.4, 2.6, 3.8]:
		lm.box("Dark", Vector3(px, y, 0), Vector3(72.6, 0.35, 38.6), Basis(), 0.0)
	lm.box("Stone", Vector3(px, 4.4, 0), Vector3(72.8, 0.4, 38.8))
	for k in 12:
		for s in [-1.0, 1.0]:
			_wheel(lm, Vector3(-50.0 + 5.9 * float(k), 2.0, s * 19.25), s)
	# The seven horses: four south and three north of the east stair.
	for i in 7:
		var s := -1.0 if i < 4 else 1.0
		var k := i if i < 4 else i - 4
		_horse(lm, Vector3(23.5 + 1.6 * float(k % 2), 0, s * (5.0 + 2.6 * float(k))))
	IU.stairs(lm, "Stone", Vector3(19, 0, 0), Basis(Vector3.UP, PI * 0.5), 10.0, 6, 0.75, 0.8)
	_deul_ruin(lm, Vector3(-36, 4.5, 0))
	_jagamohana(lm, Vector3(0, 4.5, 0))
	_nata_mandir(lm, Vector3(42, 0, 0))
	lm.commit(model)

## The deul as it stands: its pancha-ratha walls broken off at 9-16 m,
## the three chlorite Surya niches (north, west, south) and the step
## down into the open sanctum.
static func _deul_ruin(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 0.5, 0), Vector3(32.0, 1.0, 32.0))
	var tops := [12.0, 9.0, 15.5]
	for side in 3:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side + 1))
		var top: float = tops[side]
		# Walls of three stepped planes: kanika corners, anuratha, raha.
		lm.box("Stone", c + b * Vector3(0, 1.0 + top * 0.5, 13.0), Vector3(28.0, top, 4.0), b)
		lm.box("Stone", c + b * Vector3(0, 1.0 + top * 0.45, 15.2), Vector3(16.0, top * 0.9, 0.8), b)
		lm.box("Stone", c + b * Vector3(0, 1.0 + top * 0.42, 16.0), Vector3(9.0, top * 0.84, 0.8), b)
		for y in [3.0, 6.0]:
			lm.box("Dark", c + b * Vector3(0, y, 15.65), Vector3(28.4, 0.35, 0.5), b, 0.0)
		# Parshvadevata: Surya in his chlorite niche on the raha.
		ID.arcade_wall(lm, "Dark", "Dark", c + b * Vector3(0, 3.5, 16.4), b, 6.0, 7.2, 0.6, 1, 3.6, 6.4, "round")
		LandmarkKits.statue_figure(lm, "Dark", c + b * Vector3(0, 3.6, 16.5), 4.2, false)
	for sz in [-1.0, 1.0]:
		lm.box("Stone", c + Vector3(13.0, 1.0 + 5.0, sz * 9.0), Vector3(4.0, 10.0, 10.0))

## The jagamohana on the platform at `c`: pancha-ratha walls (bada) to
## 10 m with chlorite-framed doors east, north and south, then three
## tiers of six pidas following the projections, musicians on the two
## terraces, the bell (ghanta), ribbed amalaka and crown to 30 m.
static func _jagamohana(lm: LandmarkMesh, c: Vector3) -> void:
	var half := 15.0
	var bh := 10.0
	lm.box("Stone", c + Vector3(0, bh * 0.5, 0), Vector3(half * 2.0 - 3.0, bh, half * 2.0 - 3.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Projections: anurathas then the raha, each stepped forward.
		lm.box("Stone", c + b * Vector3(0, bh * 0.5, half - 1.1), Vector3(19.0, bh, 0.8), b)
		lm.box("Stone", c + b * Vector3(0, bh * 0.5, half - 0.4), Vector3(10.0, bh, 0.8), b)
		# Bada mouldings: pabhaga at the foot, bandhana band, baranda at the top.
		for t in [[0.4, 0.8], [1.2, 0.5], [5.2, 0.5], [bh - 0.6, 1.2]]:
			lm.box("Stone", c + b * Vector3(0, float(t[0]), half - 1.2), Vector3(half * 2.0 - 2.0, float(t[1]), 2.6),
				b, 0.0)
		# Sculpture niches on the anurathas and kanikas, two registers.
		for sx in [-1.0, 1.0]:
			for xo in [7.4, 12.6]:
				for y in [1.6, 5.6]:
					ID.arcade_wall(lm, "Stone", "Dark", c + b * Vector3(sx * xo, y, half - 0.7 if xo < 10.0 else
						half - 1.5), b, 2.6, 3.6, 0.35, 1, 1.4, 3.0, "round")
		if side != 2:
			# Door on the raha: chlorite frame and a sealed dark leaf.
			lm.box("Dark", c + b * Vector3(0, 3.5, half + 0.45), Vector3(6.4, 7.0, 0.5), b)
			ID.arcade_wall(lm, "Stone", "Dark", c + b * Vector3(0, 0.0, half + 0.7), b, 5.0, 6.6, 0.4, 1, 3.0, 5.8,
				"pointed", 0.4)
	# Pida roof: three tiers of six receding pidas; y0, step height, start
	# half width, end half width.
	var tiers := [[bh, 0.6, 14.6, 11.6], [bh + 4.2, 0.55, 10.4, 8.0], [bh + 7.9, 0.4, 7.2, 5.4]]
	for ti in 3:
		var y0: float = tiers[ti][0]
		var sh: float = tiers[ti][1]
		for i in 6:
			var hw := lerpf(float(tiers[ti][2]), float(tiers[ti][3]), float(i) / 5.0)
			var y := y0 + float(i) * sh
			lm.box("Stone", c + Vector3(0, y + sh * 0.5, 0), Vector3(hw * 2.0, sh, hw * 2.0))
			# The pida's projecting raha and anuratha follow the walls.
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				lm.box("Stone", c + b * Vector3(0, y + sh * 0.45, hw + 0.25), Vector3(hw * 0.7, sh * 0.9, 0.5), b, 0.0)
				lm.box("Stone", c + b * Vector3(0, y + sh * 0.45, hw + 0.6), Vector3(hw * 0.32, sh * 0.9, 0.3), b, 0.0)
		var ty := y0 + 6.0 * sh
		if ti < 2:
			# The terrace between tiers with its standing musicians.
			lm.box("Dark", c + Vector3(0, ty + 0.3, 0), Vector3(float(tiers[ti][3]) * 2.0 - 0.6, 0.6,
				float(tiers[ti][3]) * 2.0 - 0.6))
			var hw2: float = float(tiers[ti][3]) - 1.0
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				for sx in [-1.0, 1.0]:
					LandmarkKits.statue_figure(lm, "Stone", c + b * Vector3(sx * hw2 * 0.55, ty + 0.6, hw2 - 0.4),
						2.6 - 0.4 * float(ti), sx > 0.0)
	# Crown: neck (beki), bell (ghanta), ribbed amalaka and the cap to 30 m.
	var top := bh + 7.9 + 2.4
	lm.frustum("Stone", c + Vector3(0, top, 0), 4.6, 4.0, 0.8, 16)
	lm.lathe("Stone", c + Vector3(0, top + 0.8, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(4.2, 0.9),
		Vector2(3.6, 1.6), Vector2(2.6, 2.0)]), 24)
	lm.frustum("Stone", c + Vector3(0, top + 2.8, 0), 2.2, 2.2, 0.6, 16)
	var amy := top + 3.4
	lm.lathe("Stone", c + Vector3(0, amy, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(3.2, 0.35),
		Vector2(3.4, 0.7), Vector2(3.2, 1.05), Vector2(2.2, 1.4)]), 24)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Stone", c + d * 3.0 + Vector3(0, amy + 0.15, 0), c + d * 3.0 + Vector3(0, amy + 1.25, 0),
			0.4, 0.5, d.cross(Vector3.UP))
	lm.frustum("Stone", c + Vector3(0, amy + 1.4, 0), 1.6, 1.2, 0.5, 12)

## Roofless Nata Mandir (dance hall) at `c`: the 5 m platform with its
## carved mouldings and dancer niches, stairs on three sides and the
## carved pillars and pilasters left standing at various heights.
static func _nata_mandir(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 0.5, 0), Vector3(19.0, 1.0, 18.0))
	lm.box("Stone", c + Vector3(0, 2.75, 0), Vector3(18.0, 3.5, 17.0))
	lm.box("Dark", c + Vector3(0, 4.9, 0), Vector3(18.4, 0.4, 17.4))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var run := 18.0 if side % 2 == 0 else 17.0
		var off := (17.0 if side % 2 == 0 else 18.0) * 0.5
		ID.arcade_wall(lm, "Stone", "Dark", c + b * Vector3(0, 1.2, off), b, run, 3.2, 0.3, 7, 1.2, 2.6, "round")
	for i in 4:
		for j in 4:
			var p := c + Vector3(-7.5 + 5.0 * float(i), 5.1, -7.5 + 5.0 * float(j))
			var h := 2.4 + 2.2 * absf(sin(float(i * 4 + j) * 1.7))
			lm.box("Stone", p + Vector3(0, 0.3, 0), Vector3(1.6, 0.6, 1.6))
			lm.frustum("Stone", p + Vector3(0, 0.6, 0), 0.62, 0.58, h, 8, PI / 8.0)
			for y in [0.3, 0.6]:
				lm.frustum("Dark", p + Vector3(0, 0.6 + h * y, 0), 0.68, 0.68, 0.25, 8, PI / 8.0)
	IU.stairs(lm, "Stone", c + Vector3(9.0, 0, 0), Basis(Vector3.UP, PI * 0.5), 8.0, 6, 0.85, 0.9)
	for s in [-1.0, 1.0]:
		IU.stairs(lm, "Stone", c + Vector3(0, 0, s * 8.5), Basis(Vector3.UP, 0.0 if s > 0.0 else PI), 6.0, 6, 0.85, 0.9)

## One chariot wheel on the platform side: a dark face disc, a beaded
## rim, eight broad spokes with carved medallions, eight slender spokes
## between, the hub and the axle boss. `s` is the side (+1 south, -1
## north face); the axle runs along Z.
static func _wheel(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	var r := 1.48
	lm.disc("Dark", c, Vector3(0, 0, s), r, 20)
	var zc := c + Vector3(0, 0, s * 0.22)
	for i in 20:
		var a0 := TAU * float(i) / 20.0
		var a1 := TAU * float(i + 1) / 20.0
		lm.beam("Stone", zc + Vector3(cos(a0), sin(a0), 0) * (r - 0.12), zc + Vector3(cos(a1), sin(a1), 0) *
			(r - 0.12), 0.3, 0.45, Vector3(0, 0, 1))
		lm.beam("Stone", zc + Vector3(cos(a0), sin(a0), 0) * (r - 0.4), zc + Vector3(cos(a1), sin(a1), 0) *
			(r - 0.4), 0.12, 0.3, Vector3(0, 0, 1))
	for i in 16:
		var a := TAU * float(i) / 16.0
		var broad := i % 2 == 0
		var d := Vector3(cos(a), sin(a), 0)
		lm.beam("Stone", zc + d * 0.32, zc + d * (r - 0.4), 0.3 if broad else 0.12, 0.3 if broad else 0.22,
			Vector3(0, 0, 1))
		if broad:
			lm.frustum("Stone", zc + d * 0.85 - Vector3(0, 0.05, 0), 0.2, 0.2, 0.1, 8)
	lm.lathe("Stone", zc - Vector3(0, 0, 0), PackedVector2Array([Vector2(0.42, 0), Vector2(0.42, 0.1)]), 12)
	lm.box("Stone", zc + Vector3(0, 0, s * 0.2), Vector3(0.6, 0.6, 0.5))
	lm.box("Stone", zc + Vector3(0, 0, s * 0.5), Vector3(0.3, 0.3, 0.4), Basis(), 0.0)

## One rearing chariot horse on its pedestal, facing east (+X).
static func _horse(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Stone", p + Vector3(0, 0.5, 0), Vector3(3.6, 1.0, 1.6))
	var b := p + Vector3(0, 1.0, 0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var hip := b + Vector3(sx * 0.9, 1.6, sz * 0.3)
			var hoof := b + Vector3(sx * 1.0 + (0.35 if sx > 0.0 else 0.0), 0.0 if sx < 0.0 else 0.7, sz * 0.3)
			lm.beam("Stone", hip, hoof, 0.28, 0.3)
	lm.box("Stone", b + Vector3(0, 1.9, 0), Vector3(2.4, 1.0, 0.9))
	lm.beam("Stone", b + Vector3(1.0, 2.1, 0), b + Vector3(1.6, 3.1, 0), 0.6, 0.55)
	lm.beam("Stone", b + Vector3(1.5, 3.1, 0), b + Vector3(2.1, 2.7, 0), 0.4, 0.45)
	for sz in [-1.0, 1.0]:
		lm.box("Stone", b + Vector3(1.5, 3.35, sz * 0.12), Vector3(0.12, 0.3, 0.1), Basis(), 0.0)
	lm.beam("Stone", b + Vector3(-1.2, 2.2, 0), b + Vector3(-1.6, 1.2, 0), 0.25, 0.25)

## Kandariya Mahadeva Temple (31 m; c. 1030): the largest Khajuraho
## temple, 31 x 20 m on its 4 m plinth, a train of rising roofs from the
## porch (with its makara torana) through the mandapa and the maha
## mandapa (with balconied windows north and south) to the curvilinear
## shikhara of the sanctum: its walls in three registers of sculpture,
## the spire banded on the corners by bhumi-amalakas with projecting raha
## faces, ringed by 84 clinging miniature spires (urushringas and
## shringas), the ribbed amalaka and the kalasha on top.
static func kandariya_mahadeva(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B79776", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#C7AE8E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5E4C3E", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#7C8C55", 4.0))
	lm.box("Lawn", Vector3(0, 0.02, 0), Vector3(90.0, 0.04, 70.0))
	lm.box("Stone", Vector3(0, 0.6, 0), Vector3(46.0, 1.2, 30.0))
	lm.box("Stone", Vector3(0, 2.6, 0), Vector3(44.0, 2.8, 28.0))
	for y in [1.6, 2.6, 3.6]:
		lm.box("Pale", Vector3(0, y, 0), Vector3(44.4, 0.3, 28.4), Basis(), 0.0)
	lm.box("Dark", Vector3(0, 4.05, 0), Vector3(44.4, 0.3, 28.4))
	IU.stairs(lm, "Stone", Vector3(22, 0, 0), Basis(Vector3.UP, PI * 0.5), 6.0, 9, 0.45, 0.5)
	# Blocks from the sanctum to the porch: x0, x1, half width, wall top, roof steps.
	var blocks := [[-17.0, -3.0, 6.6, 13.0, 0], [-3.0, 7.0, 7.4, 12.2, 8], [7.0, 12.5, 5.2, 10.5, 6],
		[12.5, 17.0, 4.0, 9.0, 5]]
	for bk in blocks:
		_kandariya_block(lm, float(bk[0]), float(bk[1]), float(bk[2]), float(bk[3]), int(bk[4]))
	# Balconied windows (kakshasana) on the transepts of the maha mandapa
	# and the sanctum, north and south.
	for sz in [-1.0, 1.0]:
		for bx in [2.0, -10.0, 9.8]:
			var hz := 7.4 if bx == 2.0 else (6.6 if bx < 0.0 else 5.2)
			_balcony(lm, Vector3(bx, 4.2, sz * hz), sz, 6.0 if bx == 2.0 else 4.4)
	# Porch: makara torana arch and the door.
	ID.arcade_wall(lm, "Pale", "Dark", Vector3(17.0, 4.2, 0), Basis(Vector3.UP, PI * 0.5), 7.0, 4.6, 0.4, 1, 3.6, 4.0,
		"cusped")
	_kandariya_shikhara(lm, Vector3(-10.0, 13.0, 0))
	lm.commit(model)

## One block of the temple train: walls with three registers of
## sculpture niches between mouldings, the cornice, and a phamsana roof
## of receding slabs crowned by an amalaka and kalasha.
static func _kandariya_block(lm: LandmarkMesh, x0: float, x1: float, hz: float, top: float, steps: int) -> void:
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	lm.box("Stone", Vector3(cx, (4.2 + top) * 0.5, 0), Vector3(w, top - 4.2, hz * 2.0))
	lm.box("Pale", Vector3(cx, top + 0.2, 0), Vector3(w + 0.8, 0.5, hz * 2.0 + 0.8))
	for y in [5.0, 7.6, 10.0]:
		if y < top - 0.5:
			lm.box("Pale", Vector3(cx, y, 0), Vector3(w + 0.3, 0.3, hz * 2.0 + 0.3), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		var fb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		var bays := maxi(int(w / 1.6), 2)
		for y in [5.15, 7.75]:
			if y + 2.2 < top:
				ID.arcade_wall(lm, "Stone", "Dark", Vector3(cx, y, sz * hz), fb, w, 2.3, 0.25, bays, 0.9, 1.9, "round")
				for k in bays:
					var p := Vector3(x0 + w * (float(k) + 0.5) / float(bays), y + 0.1, sz * (hz + 0.1))
					lm.lathe("Pale", p, PackedVector2Array([Vector2(0.18, 0), Vector2(0.22, 0.5),
						Vector2(0.16, 1.1), Vector2(0.14, 1.35), Vector2(0.0, 1.6)]), 6)
	var y := top + 0.45
	for i in steps:
		var f := float(i) / float(steps)
		lm.box("Stone", Vector3(cx, y + 0.45, 0), Vector3(w * (1.02 - 0.5 * f), 0.9, hz * 2.0 * (1.0 - 0.66 * f)))
		lm.box("Pale", Vector3(cx, y + 0.1, 0), Vector3(w * (1.06 - 0.5 * f), 0.2, hz * 2.0 * (1.04 - 0.66 * f)),
			Basis(), 0.0)
		y += 0.9
	if steps > 0:
		lm.lathe("Pale", Vector3(cx, y, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(1.5, 0.3),
			Vector2(1.5, 0.55), Vector2(0.9, 0.8)]), 16)
		lm.lathe("Pale", Vector3(cx, y + 0.8, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.55, 0.3),
			Vector2(0.3, 0.7), Vector2(0.0, 0.9)]), 8)

## Balconied window on the side of a block: a seat on the wall, slim
## pillars, a sloping seat back (kakshasana), an eave and a small roof.
static func _balcony(lm: LandmarkMesh, p: Vector3, sz: float, w: float) -> void:
	lm.box("Pale", p + Vector3(0, 2.0, sz * 0.8), Vector3(w, 1.0, 1.6))
	lm.lathe("Pale", p + Vector3(0, 2.5, sz * 0.8), PackedVector2Array([Vector2(1.0, 0), Vector2(1.25, 0.9)]), 4,
		w * 0.5, 0.8, PI * 0.25, false, false)
	for sx in [-1.0, 1.0]:
		for k in 2:
			var x: float = sx * (w * 0.5 - 0.3 - float(k) * w * 0.3)
			lm.frustum("Pale", p + Vector3(x, 3.4, sz * 1.4), 0.16, 0.14, 2.4, 8)
	lm.box("Dark", p + Vector3(0, 4.4, sz * 0.05), Vector3(w * 0.7, 2.2, 0.2))
	ID.chhajja(lm, "Pale", p + Vector3(-w * 0.5, 5.9, sz * 1.6), p + Vector3(w * 0.5, 5.9, sz * 1.6),
		Vector3(0, 0, sz), 0.8, 0.4, 1.6)
	lm.spire("Stone", p + Vector3(0, 6.0, sz * 0.9), w * 0.45, 1.8, 0.4)

## Shikhara of the sanctum on the wall top at `tower`: the curved square
## spire (13 -> 27.5 m) with a projecting raha band up each face, the
## corner bhumi-amalakas, 84 clinging miniature spires in four rings, and
## the amalaka and kalasha to 31 m.
static func _kandariya_shikhara(lm: LandmarkMesh, tower: Vector3) -> void:
	var hwf := func(t: float) -> float:
		return 6.0 * (1.0 - 0.62 * pow(t, 1.5))
	var prof := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		prof.append(Vector2(float(hwf.call(t)) * 1.414, 14.5 * t))
	lm.lathe("Stone", tower, prof, 4, 1.0, 1.0, PI * 0.25, false)
	for side in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(side))
		for i in 12:
			var t0 := float(i) / 12.0
			var t1 := float(i + 1) / 12.0
			var h0: float = hwf.call(t0)
			var h1: float = hwf.call(t1)
			# Raha (central projection) and the lata bands either side.
			lm.beam("Stone", tower + rb * Vector3(0, 14.5 * t0, h0 + 0.3),
				tower + rb * Vector3(0, 14.5 * t1, h1 + 0.3), h0 * 0.6, 0.7, rb * Vector3(1, 0, 0))
			for sx in [-1.0, 1.0]:
				lm.beam("Pale", tower + rb * Vector3(sx * h0 * 0.42, 14.5 * t0, h0 + 0.6),
					tower + rb * Vector3(sx * h1 * 0.42, 14.5 * t1, h1 + 0.6), 0.35, 0.3, rb * Vector3(1, 0, 0))
		# Bhumi-amalakas: ribbed discs marking the storeys on the corners.
		for i in 8:
			var t := (float(i) + 0.5) / 8.5
			var hw: float = hwf.call(t)
			lm.frustum("Pale", tower + rb * Vector3(hw * 0.97, 14.5 * t, hw * 0.97), 0.55, 0.55, 0.32, 8)
	# Clinging spires: (t on the tower, count per face, half width, height).
	var rings := [[0.0, 7, 1.3, 5.2], [0.18, 6, 1.2, 4.8], [0.36, 5, 1.0, 4.0], [0.54, 3, 0.8, 3.2]]
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for rg in rings:
			var t: float = rg[0]
			var n: int = rg[1]
			var hw: float = hwf.call(t)
			for k in n:
				var x := (float(k) - float(n - 1) * 0.5) * (hw * 1.7 / float(n - 1))
				var big := k == n / 2 and t < 0.3
				var mw: float = float(rg[2]) * (2.0 if big else 1.0)
				var mh: float = float(rg[3]) * (1.7 if big else 1.0)
				_mini(lm, "Stone", tower + b * Vector3(x, 14.5 * t, hw + mw * 0.3), mw, mh, b)
	# Amalaka (ribbed disc) and kalasha: 27.5 -> 31 m.
	lm.frustum("Stone", tower + Vector3(0, 14.5, 0), 2.5, 2.3, 0.3, 16)
	lm.lathe("Pale", tower + Vector3(0, 14.8, 0), PackedVector2Array([Vector2(2.5, 0), Vector2(3.3, 0.45),
		Vector2(3.4, 0.8), Vector2(3.1, 1.1), Vector2(2.4, 1.45), Vector2(1.7, 1.7)]), 28)
	for i in 28:
		var a := TAU * float(i) / 28.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Pale", tower + d * 3.15 + Vector3(0, 14.95, 0), tower + d * 3.15 + Vector3(0, 15.85, 0), 0.28, 0.35,
			d.cross(Vector3.UP))
	lm.lathe("Pale", tower + Vector3(0, 16.5, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.3, 0.45),
		Vector2(1.0, 0.95), Vector2(0.5, 1.25), Vector2(0.15, 1.4), Vector2(0.0, 1.5)]), 12)

## Miniature spire (urushringa / shringa): a curved square spire of half
## width hw and height h at `p` with its own ribbed amalaka and finial.
static func _mini(lm: LandmarkMesh, key: String, p: Vector3, hw: float, h: float, _b: Basis) -> void:
	var r := hw * 1.414
	lm.lathe(key, p, PackedVector2Array([Vector2(r, 0), Vector2(r * 1.04, h * 0.2), Vector2(r * 0.92, h * 0.45),
		Vector2(r * 0.7, h * 0.68), Vector2(r * 0.46, h * 0.86)]), 4, 1.0, 1.0, PI * 0.25, false)
	lm.lathe("Pale", p + Vector3(0, h * 0.86, 0), PackedVector2Array([Vector2(hw * 0.45, 0),
		Vector2(hw * 0.62, h * 0.04), Vector2(hw * 0.45, h * 0.08), Vector2(hw * 0.12, h * 0.14),
		Vector2(0.0, h * 0.18)]), 8)
