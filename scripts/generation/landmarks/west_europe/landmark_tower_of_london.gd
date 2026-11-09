class_name LandmarkTowerOfLondon
extends RefCounted

## HM Tower of London in true metres, y = 0 at street level, origin at the
## centre of the White Tower, +X east and the Thames to the south (+Z,
## the wharf; registry yaw 0). Key dimensions: the White Tower 36 x 32 m
## (118 x 105 ft) and about 27 m to the south battlements (the model
## stops its vane at 29.4 m for the catalogue height of 27.5 m), its
## square corner turrets on the west and south-east and the round
## north-east stair turret, the semicircular apse of St John's Chapel at
## the south-east, the entrance and forebuilding on the south face; the
## inner ward's 13 curtain towers clockwise from the south-west (Bell,
## Beauchamp, Devereux, Flint, Bowyer, Brick, Martin, Constable, Broad
## Arrow, Salt, Lanthorn, Wakefield, Bloody), Edward I's outer curtain
## with the Byward and Middle Towers on the west causeway, Legge's Mount
## and the Brass Mount at the north corners, Develin Tower, Well and
## Cradle Towers and St Thomas's Tower over Traitors' Gate on the river
## front; Waterloo Barracks (1845) north of the White Tower, the Chapel
## Royal of St Peter ad Vincula and Tower Green, the Queen's House, the
## dry moat (west, north, east) and the riverside wharf with its guns.
## Plan from the Wikipedia article and the Historic Royal Palaces map;
## the ward walls are placed to scale from them, not surveyed.
## https://en.wikipedia.org/wiki/Tower_of_London
## https://en.wikipedia.org/wiki/White_Tower_(Tower_of_London)

const W_TOP := 24.0
const INNER_H := 11.5
const OUTER_H := 8.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#D6CFBC", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9B907E", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Timber", LandmarkMaterials.paint("#3B3026", 0.8, 0.0))
	lm.use("Render", LandmarkMaterials.pbr("render", "#E8E2D2", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A49C8C", 4.0))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#9A8E78", 4.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A5A46", 3.0))
	lm.use("Foliage", LandmarkMaterials.pbr("forest", "#5C7440", 3.0))
	_ground(lm)
	_white_tower(lm)
	_inner_ward(lm)
	_outer_ward(lm)
	_gatehouses(lm)
	_wharf(lm)
	_waterloo_barracks(lm)
	_green_buildings(lm)
	_trees(lm)
	lm.commit(model)

static func _v(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)

# ---- Ground: dry moat, ward gravel, inner-ward paving, Tower Green, paths.

static func _ground(lm: LandmarkMesh) -> void:
	var moat := PackedVector2Array([Vector2(-168, 100), Vector2(-172, -62), Vector2(-152, -132),
		Vector2(0, -144), Vector2(138, -136), Vector2(152, -40), Vector2(150, 54), Vector2(142, 100)])
	var outer := PackedVector2Array([Vector2(-128, 98), Vector2(-132, -60), Vector2(-120, -100), Vector2(0, -108),
		Vector2(98, -103), Vector2(114, -40), Vector2(113, 50), Vector2(102, 98)])
	var inner := PackedVector2Array(_inner_pts())
	var green := PackedVector2Array([Vector2(-82, -10), Vector2(-52, -12), Vector2(-36, 4), Vector2(-40, 24),
		Vector2(-64, 36), Vector2(-84, 22)])
	lm.poly_prism("Lawn", moat, 0.0, 0.03)
	lm.poly_prism("Gravel", outer, 0.0, 0.06)
	lm.poly_prism("Paving", inner, 0.0, 0.09)
	lm.poly_prism("Lawn", green, 0.0, 0.12)
	# Gravel footpaths: the west approach, round the White Tower, the
	# walks of Tower Green and the road along the wharf front.
	for r in [[-150.0, 76.0, -90.0, 76.0, 4.0], [-90.0, 76.0, -42.0, 76.0, 4.0], [-42.0, 76.0, -42.0, 52.0, 4.0],
			[-42.0, 56.0, -2.0, 56.0, 3.0], [-60.0, 6.0, -26.0, 6.0, 2.4], [-26.0, -30.0, -26.0, 24.0, 2.4],
			[-110.0, 40.0, -110.0, -80.0, 3.5], [40.0, -90.0, 90.0, 80.0, 3.0]]:
		var a := Vector3(float(r[0]), 0.0, float(r[1]))
		var b := Vector3(float(r[2]), 0.0, float(r[3]))
		var d := b - a
		lm.box("Gravel", (a + b) * 0.5 + Vector3(0, 0.15, 0), Vector3(float(r[4]), 0.06, d.length()),
			Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
	# Flagged apron round the White Tower, and the courses of its plinth.
	LandmarkWestKit.blk(lm, "Paving", 0, 0.09, 0, 52.0, 0.08, 48.0)
	# Low raised lawn beds in the outer ward and the Waterloo parade.
	for p in [Vector3(-60, 0, -80), Vector3(60, 0, -85), Vector3(-80, 0, 68), Vector3(40, 0, 76)]:
		lm.box("Lawn", p + Vector3(0, 0.1, 0), Vector3(30.0, 0.1, 14.0))

static func _inner_pts() -> Array[Vector2]:
	var p: Array[Vector2] = [Vector2(-92, 35), Vector2(-96, -12), Vector2(-92, -52), Vector2(-65, -66),
		Vector2(-34, -70), Vector2(-5, -70), Vector2(36, -68), Vector2(46, -40), Vector2(48, -8),
		Vector2(45, 28), Vector2(12, 56), Vector2(-14, 56), Vector2(-42, 52)]
	return p

# ---- The White Tower.

static func _white_tower(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "White", 0, 0, 0, 38.0, 1.4, 34.0)
	LandmarkWestKit.blk(lm, "White", 0, 0, 0, 36.0, W_TOP, 32.0)
	LandmarkWestKit.blk(lm, "White", 0, W_TOP - 1.4, 0, 36.8, 0.4, 32.8)
	# Four faces: pilaster strips, tiers of round-headed windows, battlements.
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var south_or_north := f % 2 == 0
		var half: float = 16.0 if south_or_north else 18.0
		var width: float = 36.0 if south_or_north else 32.0
		var n: Vector3 = r * Vector3(0, 0, 1)
		var bays := 4 if south_or_north else 3
		LandmarkWestKit.merlons(lm, "White", r * Vector3(-width * 0.5, W_TOP, half), r * Vector3(width * 0.5, W_TOP, half),
			2.4, 1.3, 1.3, 0.9)
		for k in bays + 1:
			var x := -width * 0.5 + width * float(k) / float(bays)
			lm.box("White", r * Vector3(x, W_TOP * 0.5, half + 0.3), Vector3(2.4 if k % bays == 0 else 1.6, W_TOP, 0.6), r)
		for k in bays:
			var bx := -width * 0.5 + width * (float(k) + 0.5) / float(bays)
			var pw := width / float(bays)
			# Storey 1 is the entrance floor; storey 2 the great hall
			# and chapel level with the tall Wren windows; slits below.
			for sx in [-1.0, 1.0]:
				LandmarkDetail.window(lm, "White", "Glass", r * Vector3(bx + float(sx) * pw * 0.19, 14.2, half), n,
					1.1, 3.1, true, 0.25)
				LandmarkDetail.window(lm, "White", "Glass", r * Vector3(bx + float(sx) * pw * 0.19, 20.4, half), n,
					1.1, 3.0, true, 0.25)
			lm.box("Glass", r * Vector3(bx, 3.6, half + 0.02), Vector3(0.3, 1.6, 0.05), r, 0.0)
			lm.box("Glass", r * Vector3(bx, 8.4, half + 0.02), Vector3(0.5, 2.0, 0.05), r, 0.0)
	# The roof behind the parapet: two lead-covered pitches.
	lm.gable("Slate", Vector3(0, W_TOP, 0), 28.0, 33.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.0, "White")
	# Three square turrets (west and south-east) and the round stair
	# turret at the north-east, each with an ogee lead cupola and vane.
	for s in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var t := Vector3(s.x * 16.0, 0, s.y * 14.0)
		LandmarkWestKit.blk(lm, "White", t.x, 0, t.z, 6.2, 26.0, 6.2)
		LandmarkWestKit.blk(lm, "White", t.x, 26.0, t.z, 6.9, 0.4, 6.9)
		for q in 4:
			var tb := Basis(Vector3.UP, PI * 0.5 * float(q))
			LandmarkWestKit.merlons(lm, "White", t + tb * Vector3(-3.1, 26.4, 3.1), t + tb * Vector3(3.1, 26.4, 3.1),
				1.8, 0.8, 0.6, 0.4)
			lm.box("Glass", t + tb * Vector3(0, 21.0, 3.12), Vector3(0.4, 1.8, 0.05), tb, 0.0)
			lm.box("Glass", t + tb * Vector3(0, 14.0, 3.12), Vector3(0.4, 1.8, 0.05), tb, 0.0)
		lm.lathe("Slate", t + Vector3(0, 26.4, 0), LandmarkWestKit.ogee_prof(2.8, 1.9), 4, 1.0, 1.0, PI * 0.25, false)
		_vane(lm, t + Vector3(0, 28.3, 0))
	var ne := Vector3(16, 0, -14)
	lm.frustum("White", ne, 4.4, 4.4, 26.0, 16)
	lm.frustum("White", ne + Vector3(0, 26.0, 0), 4.8, 4.8, 0.4, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.box("White", ne + Vector3(cos(a), 0, sin(a)) * 4.6 + Vector3(0, 26.7, 0), Vector3(0.9, 0.7, 1.3),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	for k in 6:
		var a := PI * 0.25 + TAU * float(k) / 6.0
		lm.box("Glass", ne + Vector3(cos(a), 0, sin(a)) * 4.42 + Vector3(0, 6.0 + 4.0 * float(k % 3), 0), Vector3(0.3, 1.3, 0.3),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.lathe("Slate", ne + Vector3(0, 26.4, 0), LandmarkWestKit.ogee_prof(4.2, 1.9), 16)
	_vane(lm, ne + Vector3(0, 28.3, 0))
	_apse_and_stair(lm)

## St John's Chapel apse on the east face, the forebuilding stair on the
## south face and the entrance door at first-floor level.
static func _apse_and_stair(lm: LandmarkMesh) -> void:
	var ac := Vector3(18, 0, 5.5)
	lm.lathe("White", ac, PackedVector2Array([Vector2(6.0, 0), Vector2(5.6, 1.4), Vector2(5.6, 22.0)]), 16, 1.0, 1.0, 0.0, true)
	lm.frustum("White", ac + Vector3(0, 21.6, 0), 5.8, 5.8, 0.5, 16)
	lm.lathe("Slate", ac + Vector3(0, 22.1, 0), PackedVector2Array([Vector2(5.5, 0), Vector2(0.0, 2.2)]), 16, 1.0, 1.0, 0.0, false)
	for k in 5:
		var a := -PI * 0.5 + PI * float(k) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("White", ac + d * 5.7 + Vector3(0, 11.0, 0), Vector3(0.9, 22.0, 0.9), Basis(Vector3.UP, -a + PI * 0.5), 0.0)
		if k % 2 == 1:
			continue
		LandmarkDetail.window(lm, "White", "Glass", ac + d * 5.6 + Vector3(0, 15.0, 0), d, 1.2, 3.4, true, 0.25)
		lm.box("Glass", ac + d * 5.62 + Vector3(0, 6.5, 0), Vector3(0.3, 1.6, 0.1), Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	# Entrance stair rising to the south door (the forebuilding site).
	LandmarkWestKit.blk(lm, "White", -8.0, 0, 18.4, 12.0, 6.0, 4.4)
	LandmarkWestKit.blk(lm, "White", -8.0, 6.0, 18.4, 12.6, 0.5, 4.9)
	for k in 9:
		lm.box("Timber", Vector3(-1.0 + 1.1 * float(k) - 12.0, 0.5 * float(k) + 0.25, 22.0), Vector3(1.1, 0.5, 2.0), Basis(), 0.0)
	lm.beam("Timber", Vector3(-13.0, 1.4, 23.2), Vector3(-3.4, 5.9, 23.2), 0.15, 0.15)
	lm.box("Timber", Vector3(-8.0, 9.2, 16.1), Vector3(2.0, 3.6, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "White", Vector3(-8.0, 7.4, 16.05), Vector3(0, 0, 1), 2.4, 0.4, 0.3)

## Gilt weathervane: a slim spindle, a pennant and a ball.
static func _vane(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Gilt", base + Vector3(0, 0.4, 0), Vector3(0.07, 0.8, 0.07), Basis(), 0.0)
	lm.box("Gilt", base + Vector3(0.22, 0.62, 0), Vector3(0.44, 0.24, 0.03), Basis(), 0.0)
	lm.lathe("Gilt", base + Vector3(0, 0.66, 0), LandmarkWestKit.ball(0.12), 6)

# ---- Curtain walls and towers.

## One curtain wall a -> b, h tall, with a battered foot, crenellations
## and a loop every 16 m on both faces.
static func _wall(lm: LandmarkMesh, a: Vector3, b: Vector3, h: float, thick: float) -> void:
	var d := b - a
	var yaw := atan2(d.x, d.z)
	var m := (a + b) * 0.5
	lm.box("Wall", m + Vector3(0, h * 0.5, 0), Vector3(thick, h, d.length()), Basis(Vector3.UP, yaw))
	lm.box("Wall", m + Vector3(0, 0.7, 0), Vector3(thick + 1.0, 1.4, d.length()), Basis(Vector3.UP, yaw))
	LandmarkWestKit.merlons(lm, "Wall", a + Vector3(0, h, 0), b + Vector3(0, h, 0), 2.4, 1.2, 1.1, thick * 0.9)
	var nrm := Vector3(d.z, 0, -d.x).normalized()
	var cnt := int(d.length() / 16.0)
	for k in cnt:
		var p := a.lerp(b, (float(k) + 0.5) / float(cnt)) + Vector3(0, h * 0.55, 0)
		for sgn in [-1.0, 1.0]:
			lm.box("Glass", p + nrm * float(sgn) * (thick * 0.5 + 0.02), Vector3(0.3, 1.6, 0.06), Basis(Vector3.UP, yaw), 0.0)

## Crenellated drum with arrow loops; `cap` is "flat" (battlements) or
## "cone" (slated conical roof).
static func _drum(lm: LandmarkMesh, base: Vector3, d: float, h: float, cap: String) -> void:
	var r := d * 0.5
	lm.lathe("Wall", base, PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r * 1.08, h * 0.12), Vector2(r, h * 0.2),
		Vector2(r, h)]), 16, 1.0, 1.0, 0.0, true)
	lm.frustum("Wall", base + Vector3(0, h * 0.7, 0), r * 1.05, r * 1.05, 0.35, 16)
	lm.frustum("Wall", base + Vector3(0, h, 0), r * 1.1, r * 1.04, 0.5, 16)
	var cnt := maxi(int(TAU * r / 2.2), 6)
	for k in cnt:
		var a := TAU * float(k) / float(cnt)
		var dir := Vector3(cos(a), 0, sin(a))
		if cap == "flat" or k % 2 == 0:
			lm.box("Wall", base + dir * r * 1.0 + Vector3(0, h + 1.1, 0), Vector3(0.7, 1.1, r * 0.18),
				Basis(Vector3.UP, -a + PI * 0.5), 0.0)
		if k % 2 == 0:
			lm.box("Glass", base + dir * (r + 0.02) + Vector3(0, h * 0.55, 0), Vector3(0.25, 1.5, 0.06),
				Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	if cap == "cone":
		lm.lathe("Slate", base + Vector3(0, h + 0.5, 0), PackedVector2Array([Vector2(r * 1.14, 0), Vector2(r * 0.5, h * 0.18),
			Vector2(0.0, h * 0.42)]), 16, 1.0, 1.0, 0.0, false)
		lm.frustum("Gilt", base + Vector3(0, h + 0.5 + h * 0.42 - 0.2, 0), 0.1, 0.02, 1.0, 6)

## Crenellated rectangular tower w x d x h turned by yaw, with a slim
## corner stair turret and loops on every face.
static func _keep(lm: LandmarkMesh, c: Vector3, w: float, d: float, h: float, yaw: float) -> void:
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z, w + 1.0, 1.3, d + 1.0, yaw)
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z, w, h, d, yaw)
	LandmarkWestKit.blk(lm, "Wall", c.x, h - 0.9, c.z, w + 0.7, 0.9, d + 0.7, yaw)
	var b := Basis(Vector3.UP, yaw)
	for s in 4:
		var bs := b * Basis(Vector3.UP, PI * 0.5 * float(s))
		var half: float = (d if s % 2 == 0 else w) * 0.5
		var span: float = (w if s % 2 == 0 else d)
		LandmarkWestKit.merlons(lm, "Wall", c + bs * Vector3(-span * 0.5, h, half), c + bs * Vector3(span * 0.5, h, half),
			1.9, 1.0, 1.1, 0.8)
		for y in [h * 0.35, h * 0.68]:
			lm.box("Glass", c + bs * Vector3(0, float(y), half + 0.02), Vector3(0.35, 1.7, 0.05), bs, 0.0)
	var tc := c + b * Vector3(w * 0.5 - 0.7, 0, -d * 0.5 + 0.7)
	lm.frustum("Wall", tc, 1.3, 1.2, h + 2.6, 8)
	lm.lathe("Slate", tc + Vector3(0, h + 2.6, 0), LandmarkWestKit.ogee_prof(1.5, 1.8), 8)

## Inner ward: the curtain wall, the 13 towers and the shaped features.
static func _inner_ward(lm: LandmarkMesh) -> void:
	var pts := _inner_pts()
	for i in pts.size():
		_wall(lm, _v(pts[i]), _v(pts[(i + 1) % pts.size()]), INNER_H, 3.0)
	# Bell (belfry cupola), Beauchamp, Devereux, Flint, Bowyer, Brick,
	# Martin, Constable, Broad Arrow, Salt, Lanthorn, Wakefield, Bloody.
	_drum(lm, _v(pts[0]), 9.0, 14.0, "flat")
	var bt := _v(pts[0]) + Vector3(0, 14.0, 0)
	lm.frustum("Timber", bt, 1.9, 1.9, 2.6, 8)
	lm.lathe("Slate", bt + Vector3(0, 2.6, 0), LandmarkWestKit.ogee_prof(2.4, 2.6), 8)
	_beauchamp(lm, _v(pts[1]))
	_drum(lm, _v(pts[2]), 10.0, 15.0, "cone")
	_drum(lm, _v(pts[3]), 9.0, 14.0, "flat")
	_keep(lm, _v(pts[4]), 10.0, 9.0, 14.0, 0.2)
	_keep(lm, _v(pts[5]), 9.0, 9.0, 14.0, 0.0)
	_drum(lm, _v(pts[6]), 10.0, 16.0, "cone")
	_keep(lm, _v(pts[7]), 12.0, 11.0, 16.0, -0.3)
	_keep(lm, _v(pts[8]), 8.0, 9.0, 15.0, 0.0)
	_keep(lm, _v(pts[9]), 11.0, 10.0, 16.0, 0.5)
	_drum(lm, _v(pts[10]), 9.0, 17.0, "cone")
	_wakefield(lm, _v(pts[11]))
	_bloody(lm, _v(pts[12]))

## Beauchamp Tower: a D-shaped brick-faced tower on the west wall with a
## half-round front, crenellations and corner turrets.
static func _beauchamp(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkWestKit.blk(lm, "Wall", c.x + 3.0, 0, c.z, 10.0, 15.0, 11.0)
	lm.lathe("Wall", c + Vector3(-2.0, 0, 0), PackedVector2Array([Vector2(5.9, 0), Vector2(5.5, 1.4), Vector2(5.5, 15.0)]), 12,
		1.0, 1.0, 0.0, true)
	lm.frustum("Wall", c + Vector3(-2.0, 14.0, 0), 5.8, 5.9, 1.0, 12)
	for k in 7:
		var a := PI * 0.5 + PI * float(k) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Wall", c + Vector3(-2.0, 15.6, 0) + d * 5.7, Vector3(0.8, 1.1, 1.4), Basis(Vector3.UP, -a + PI * 0.5), 0.0)
		if k % 2 == 1:
			LandmarkDetail.window(lm, "Wall", "Glass", c + Vector3(-2.0, 9.5, 0) + d * 5.52, d, 0.8, 1.8, false, 0.15)
	LandmarkWestKit.merlons(lm, "Wall", c + Vector3(-2.0, 15.0, 5.5), c + Vector3(8.0, 15.0, 5.5), 2.0, 1.0, 1.1, 0.8)
	LandmarkWestKit.merlons(lm, "Wall", c + Vector3(-2.0, 15.0, -5.5), c + Vector3(8.0, 15.0, -5.5), 2.0, 1.0, 1.1, 0.8)
	LandmarkWestKit.merlons(lm, "Wall", c + Vector3(8.0, 15.0, -5.5), c + Vector3(8.0, 15.0, 5.5), 2.0, 1.0, 1.1, 0.8)
	for sz in [-1.0, 1.0]:
		lm.frustum("Wall", c + Vector3(7.6, 0, float(sz) * 5.2), 1.3, 1.2, 17.5, 8)
		lm.lathe("Slate", c + Vector3(7.6, 17.5, float(sz) * 5.2), LandmarkWestKit.ogee_prof(1.5, 1.8), 8)

## Wakefield Tower: a chunky octagon (about 14 m across, 19 m high) with
## battlements and a stair turret, the Crown Jewels' former home.
static func _wakefield(lm: LandmarkMesh, c: Vector3) -> void:
	lm.lathe("Wall", c, PackedVector2Array([Vector2(7.6, 0), Vector2(7.2, 1.6), Vector2(7.0, 19.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Wall", c + Vector3(0, 12.0, 0), 7.2, 7.2, 0.4, 8, PI / 8.0)
	lm.frustum("Wall", c + Vector3(0, 19.0, 0), 7.7, 7.1, 0.7, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var tang := Vector3(-sin(a), 0, cos(a))
		for q in 3:
			lm.box("Wall", c + d * 7.1 + tang * (float(q) - 1.0) * 1.9 + Vector3(0, 20.2, 0), Vector3(0.8, 1.2, 1.1),
				Basis(Vector3.UP, -a + PI * 0.5), 0.0)
		LandmarkWestKit.lancet(lm, "Wall", "Glass", c + d * 7.0 + Vector3(0, 12.6 if k % 2 == 0 else 7.0, 0), d, 1.0, 3.2,
			false, 0.2)
	var st := c + Vector3(5.2, 0, -5.2)
	lm.frustum("Wall", st, 1.6, 1.5, 22.5, 8)
	lm.lathe("Slate", st + Vector3(0, 22.5, 0), LandmarkWestKit.ogee_prof(1.9, 2.2), 8)

## Bloody Tower: the water-gate tower on the south curtain, a stone gate
## block with a round-headed passage north-south (Water Lane), battlements
## and a corner turret.
static func _bloody(lm: LandmarkMesh, c: Vector3) -> void:
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Wall", c.x + float(sx) * 4.2, 0, c.z, 3.6, 3.4, 10.0)
	LandmarkWestKit.arch_wall(lm, "Wall", Basis(), c, 6.0, 5.0, 2.4, 3.4, 16.5)
	LandmarkWestKit.blk(lm, "Wall", c.x, 16.5, c.z, 12.8, 0.6, 10.8)
	for s in 4:
		var bs := Basis(Vector3.UP, PI * 0.5 * float(s))
		var half: float = 5.4 if s % 2 == 0 else 6.4
		var span: float = 12.8 if s % 2 == 0 else 10.8
		LandmarkWestKit.merlons(lm, "Wall", c + bs * Vector3(-span * 0.5, 17.1, half), c + bs * Vector3(span * 0.5, 17.1, half),
			1.9, 1.0, 1.1, 0.8)
	for s in [-1.0, 1.0]:
		var n := Vector3(0, 0, float(s))
		LandmarkDetail.window(lm, "Wall", "Glass", c + n * 5.0 + Vector3(-3.4, 9.4, 0), n, 1.2, 2.6, true, 0.2)
		LandmarkDetail.window(lm, "Wall", "Glass", c + n * 5.0 + Vector3(3.4, 9.4, 0), n, 1.2, 2.6, true, 0.2)
		LandmarkDetail.window(lm, "Wall", "Glass", c + n * 5.0 + Vector3(0, 12.4, 0), n, 1.4, 2.4, true, 0.2)
		lm.box("Timber", c + n * 4.9 + Vector3(0, 1.7, 0), Vector3(4.4, 3.2, 0.1), Basis(), 0.0)
	var st := c + Vector3(5.6, 0, 4.4)
	lm.frustum("Wall", st, 1.5, 1.4, 19.5, 8)
	lm.lathe("Slate", st + Vector3(0, 19.5, 0), LandmarkWestKit.ogee_prof(1.8, 2.0), 8)

# ---- Outer ward and gatehouses.

static func _outer_ward(lm: LandmarkMesh) -> void:
	var pts: Array[Vector2] = [Vector2(-128, 98), Vector2(-132, -60), Vector2(-120, -100), Vector2(0, -108),
		Vector2(98, -103), Vector2(114, -40), Vector2(113, 50), Vector2(102, 98)]
	for i in pts.size():
		_wall(lm, _v(pts[i]), _v(pts[(i + 1) % pts.size()]), OUTER_H, 2.4)
	# Corner and mid-wall drums: Legge's Mount and the Brass Mount are
	# the large D-shaped bastions of the north corners.
	for k in [[-132, -60, 7.0, 10.0], [114, -40, 7.0, 10.0], [113, 50, 7.0, 10.0], [102, 98, 9.0, 10.5],
			[-128, 98, 8.0, 10.0], [-62, -104, 7.0, 9.5], [48, -106, 7.0, 9.5], [62, 98, 8.0, 10.0]]:
		_drum(lm, Vector3(float(k[0]), 0, float(k[1])), float(k[2]), float(k[3]), "flat")
	for k in [[-120, -100], [98, -103]]:
		var c := Vector3(float(k[0]), 0, float(k[1]))
		_drum(lm, c, 15.0, 10.5, "flat")
		lm.frustum("Wall", c + Vector3(0, 0, 0), 8.4, 8.0, 1.6, 16)

## Byward and Middle Towers on the west causeway, St Thomas's Tower with
## Traitors' Gate, the Cradle Tower on the river front.
static func _gatehouses(lm: LandmarkMesh) -> void:
	# Byward Tower: twin-drum gatehouse in the west curtain, passage W-E.
	var by := Vector3(-128, 0, 76)
	var rot := Basis(Vector3.UP, PI * 0.5)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Wall", by.x, 0, by.z + float(sz) * 4.6, 12.0, 3.2, 3.8)
	LandmarkWestKit.arch_wall(lm, "Wall", rot, by, 6.0, 6.0, 2.6, 3.2, 11.5)
	LandmarkWestKit.blk(lm, "Wall", by.x, 11.5, by.z, 12.0, 0.5, 12.6)
	LandmarkWestKit.merlons(lm, "Wall", by + Vector3(-6.2, 12.0, -6.3), by + Vector3(-6.2, 12.0, 6.3), 2.0, 1.1, 1.1, 0.8)
	LandmarkWestKit.merlons(lm, "Wall", by + Vector3(6.2, 12.0, -6.3), by + Vector3(6.2, 12.0, 6.3), 2.0, 1.1, 1.1, 0.8)
	LandmarkWestKit.merlons(lm, "Wall", by + Vector3(-6.0, 12.0, -6.3), by + Vector3(6.0, 12.0, -6.3), 2.0, 1.1, 1.1, 0.8)
	LandmarkWestKit.merlons(lm, "Wall", by + Vector3(-6.0, 12.0, 6.3), by + Vector3(6.0, 12.0, 6.3), 2.0, 1.1, 1.1, 0.8)
	for sz in [-1.0, 1.0]:
		_drum(lm, by + Vector3(-7.0, 0, float(sz) * 6.4), 6.0, 11.5, "cone")
	LandmarkWestKit.blk(lm, "Render", by.x + 1.5, 11.5, by.z, 7.0, 3.0, 11.0)
	lm.gable("Slate", by + Vector3(1.5, 14.5, 0), 7.0, 11.0, 2.4, Basis(), 0.2, "Render")
	lm.box("Timber", by + Vector3(-6.05, 2.6, 0), Vector3(0.1, 5.0, 4.8), Basis(), 0.0)
	# Middle Tower beyond the moat, and the stone causeway to it.
	var mid := Vector3(-152, 0, 76)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Wall", mid.x, 0, mid.z + float(sz) * 4.3, 10.0, 3.0, 3.8)
	LandmarkWestKit.arch_wall(lm, "Wall", rot, mid, 6.3, 5.0, 2.4, 3.0, 10.0)
	LandmarkWestKit.blk(lm, "Wall", mid.x, 10.0, mid.z, 10.0, 0.5, 12.6)
	for s in 4:
		var bs := Basis(Vector3.UP, PI * 0.5 * float(s))
		var half: float = 6.3 if s % 2 == 0 else 5.1
		var span: float = 10.0 if s % 2 == 0 else 12.6
		LandmarkWestKit.merlons(lm, "Wall", mid + bs * Vector3(-span * 0.5, 10.5, half), mid + bs * Vector3(span * 0.5, 10.5, half),
			2.0, 1.1, 1.1, 0.8)
	for sz in [-1.0, 1.0]:
		_drum(lm, mid + Vector3(-5.6, 0, float(sz) * 6.0), 5.5, 10.0, "cone")
	LandmarkWestKit.blk(lm, "Paving", -164.0, 0, 76.0, 22.0, 0.5, 9.0)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Wall", -164.0, 0.5, 76.0 + float(sz) * 4.4, 22.0, 1.0, 0.5)
	# Cradle Tower: a square river-gate tower on the south curtain.
	_keep(lm, Vector3(25, 0, 98), 10.0, 10.0, 11.0, 0.0)
	# St Thomas's Tower: a long stone block over Traitors' Gate, whose
	# pointed water-gate opens on the wharf; the Bloody Tower's Water
	# Lane runs north from it.
	var st := Vector3(-30, 0, 98)
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Wall", st.x + float(sx) * 9.3, 0, st.z, 11.4, 5.6, 14.0)
	LandmarkWestKit.arch_wall(lm, "Wall", Basis(), st, 15.0, 7.0, 3.6, 5.6, 12.0)
	LandmarkWestKit.blk(lm, "Wall", st.x, 12.0, st.z, 30.6, 0.6, 14.6)
	for s in 4:
		var bs := Basis(Vector3.UP, PI * 0.5 * float(s))
		var half: float = 7.3 if s % 2 == 0 else 15.3
		var span: float = 30.6 if s % 2 == 0 else 14.6
		LandmarkWestKit.merlons(lm, "Wall", st + bs * Vector3(-span * 0.5, 12.6, half), st + bs * Vector3(span * 0.5, 12.6, half),
			2.2, 1.2, 1.1, 0.9)
	for sx in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "Wall", "Glass", st + Vector3(float(sx) * 9.0, 8.4, 7.0), Vector3(0, 0, 1), 1.3, 2.4, true, 0.2)
		LandmarkDetail.window(lm, "Wall", "Glass", st + Vector3(float(sx) * 5.0, 8.4, 7.0), Vector3(0, 0, 1), 1.3, 2.4, true, 0.2)
		LandmarkDetail.window(lm, "Wall", "Glass", st + Vector3(float(sx) * 13.0, 8.4, 7.0), Vector3(0, 0, 1), 1.3, 2.4, true, 0.2)
	# Timber water-gate closing the arch, a portcullis grille and the sill.
	lm.box("Timber", st + Vector3(0, 3.2, 6.9), Vector3(6.6, 6.4, 0.2), Basis(), 0.0)
	for k in 6:
		lm.box("Glass", st + Vector3(-2.5 + float(k), 3.6, 7.05), Vector3(0.12, 5.6, 0.1), Basis(), 0.0)
	LandmarkWestKit.blk(lm, "Wall", st.x, 0, st.z + 8.6, 8.0, 0.35, 3.0)
	# Pointed arches and the small side turrets of the water-gate front.
	for sx in [-1.0, 1.0]:
		var tc := st + Vector3(float(sx) * 14.0, 0, 6.2)
		lm.frustum("Wall", tc, 1.8, 1.7, 14.0, 8)
		lm.lathe("Slate", tc + Vector3(0, 14.0, 0), LandmarkWestKit.ogee_prof(2.1, 2.4), 8)

# ---- The wharf along the river front.

static func _wharf(lm: LandmarkMesh) -> void:
	# Raised granite wharf with a river wall, a gravel promenade, kerbs,
	# lamp posts and the line of ceremonial guns.
	LandmarkWestKit.blk(lm, "Paving", -9.0, 0, 112.0, 262.0, 0.5, 28.0)
	LandmarkWestKit.blk(lm, "Gravel", -9.0, 0.5, 112.0, 250.0, 0.04, 6.0)
	LandmarkWestKit.blk(lm, "Wall", -9.0, 0, 126.3, 262.0, 3.0, 1.4)
	LandmarkWestKit.blk(lm, "Wall", -9.0, 3.0, 126.3, 262.4, 0.35, 1.8)
	LandmarkWestKit.blk(lm, "Wall", -9.0, 0.5, 98.9, 262.0, 0.12, 1.6)
	for k in 14:
		var x := -126.0 + 19.0 * float(k)
		LandmarkWestKit.blk(lm, "Wall", x, 0.5, 124.6, 0.7, 0.9, 0.7)
		lm.frustum("Wall", Vector3(x + 9.0, 0.5, 104.0), 0.28, 0.2, 1.1, 8)
		lm.frustum("Gilt", Vector3(x + 9.0, 1.6, 104.0), 0.2, 0.05, 0.3, 6)
		LandmarkCoreBBridgeKit.lamp(lm, "Slate", "Gilt", Vector3(x + 9.0, 0.5, 118.0), 4.4, Vector3(0, 0, 0.5))
	for k in 17:
		var x := -126.0 + 15.0 * float(k)
		LandmarkWestKit.blk(lm, "Timber", x, 0.5, 120.4, 1.5, 0.55, 1.0)
		lm.box("Timber", Vector3(x, 1.05, 120.2), Vector3(1.7, 0.15, 1.2), Basis(), 0.0)
		LandmarkWestKit.tube(lm, "Slate", Vector3(x, 1.25, 119.9), Vector3(x, 1.5, 122.6), 0.2)
		lm.lathe("Slate", Vector3(x, 1.5, 122.7), LandmarkWestKit.ball(0.2), 6)

# ---- Waterloo Barracks, the Chapel Royal, the Queen's House.

## Waterloo Barracks (1845, Gothic Revival; now the Jewel House) north
## of the White Tower: 66 m long, three storeys of paired lights under
## a castellated parapet, projecting corner towers and a central bay.
static func _waterloo_barracks(lm: LandmarkMesh) -> void:
	var c := Vector3(4, 0, -47)
	var w := 66.0
	var d := 17.0
	var h := 14.5
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z, w + 0.6, 1.4, d + 0.6)
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z, w, h, d)
	LandmarkWestKit.blk(lm, "Wall", c.x, h - 0.7, c.z, w + 0.6, 0.7, d + 0.6)
	LandmarkWestKit.hip(lm, "Slate", c + Vector3(0, h + 0.6, 0), w - 1.0, d - 1.0, 2.8, 0.7)
	for fz in [-1.0, 1.0]:
		var n := Vector3(0, 0, float(fz))
		LandmarkDetail.pierced_face(lm, "Wall", "Glass", c + Vector3(-float(fz) * w * 0.5, 0, float(fz) * d * 0.5),
			Vector3(float(fz), 0, 0), n, w, h - 0.8, 22, 3, Vector2(1.5, 2.5), 2.0, 4.4, 0.35)
		LandmarkWestKit.merlons(lm, "Wall", c + Vector3(-w * 0.5, h + 0.3, float(fz) * (d * 0.5 + 0.3)),
			c + Vector3(w * 0.5, h + 0.3, float(fz) * (d * 0.5 + 0.3)), 2.2, 1.1, 1.1, 0.7)
	for fx in [-1.0, 1.0]:
		LandmarkWestKit.merlons(lm, "Wall", c + Vector3(float(fx) * (w * 0.5 + 0.3), h + 0.3, -d * 0.5),
			c + Vector3(float(fx) * (w * 0.5 + 0.3), h + 0.3, d * 0.5), 2.2, 1.1, 1.1, 0.7)
	# Corner turrets and the central entrance bay on the south front.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var t := c + Vector3(float(sx) * (w * 0.5 - 0.5), 0, float(sz) * (d * 0.5 - 0.5))
			lm.frustum("Wall", t, 2.4, 2.2, h + 3.8, 8, PI / 8.0)
			lm.frustum("Wall", t + Vector3(0, h + 3.8, 0), 2.7, 2.7, 0.5, 8, PI / 8.0)
			lm.lathe("Slate", t + Vector3(0, h + 4.3, 0), PackedVector2Array([Vector2(2.7, 0), Vector2(0.0, 3.6)]), 8,
				1.0, 1.0, PI / 8.0, false)
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z + d * 0.5 + 1.0, 10.0, h + 2.4, 2.4)
	LandmarkWestKit.merlons(lm, "Wall", c + Vector3(-5.0, h + 2.4, d * 0.5 + 2.2), c + Vector3(5.0, h + 2.4, d * 0.5 + 2.2),
		1.8, 0.9, 1.0, 0.6)
	LandmarkWestKit.portal(lm, "Wall", "Timber", c + Vector3(0, 0, d * 0.5 + 2.3), Vector3(0, 0, 1), 3.0, 5.6, 2, true)
	LandmarkWestKit.lancet(lm, "Wall", "Glass", c + Vector3(0, 8.0, d * 0.5 + 2.3), Vector3(0, 0, 1), 2.0, 4.6, false, 0.2)

## Chapel Royal of St Peter ad Vincula with its west bell turret, and the
## jettied half-timbered Queen's House beside Tower Green.
static func _green_buildings(lm: LandmarkMesh) -> void:
	var c := Vector3(-66.0, 0, -24.0)
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z, 30.0, 8.0, 11.0)
	lm.gable("Slate", c + Vector3(0, 8.0, 0), 11.0, 30.0, 4.4, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	for k in 5:
		LandmarkWestKit.lancet(lm, "White", "Glass", c + Vector3(-12.0 + 6.0 * float(k), 1.8, 5.5), Vector3(0, 0, 1),
			2.0, 4.6, true, 0.2)
	for k in 4:
		LandmarkWestKit.buttress(lm, "Wall", c + Vector3(-9.0 + 6.0 * float(k) + 3.0, 0, 5.5), Vector3(0, 0, 1), 0.8, 0.8, 6.0, 2)
	LandmarkWestKit.blk(lm, "Wall", c.x - 13.5, 0, c.z, 4.0, 13.0, 4.0)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(c.x - 15.5, 13.0, c.z + 2.0), Vector3(c.x - 11.5, 13.0, c.z + 2.0), 1.3, 0.6, 0.8, 0.4)
	lm.frustum("Render", c + Vector3(-13.5, 13.0, 0), 1.0, 1.0, 2.0, 8)
	lm.lathe("Slate", c + Vector3(-13.5, 15.0, 0), LandmarkWestKit.ogee_prof(1.2, 1.8), 8)
	_vane(lm, c + Vector3(-13.5, 16.8, 0))
	var q := Vector3(-66.0, 0, 37.0)
	LandmarkWestKit.blk(lm, "Render", q.x, 0, q.z, 26.0, 4.0, 9.0)
	LandmarkWestKit.blk(lm, "Render", q.x, 4.0, q.z - 0.4, 26.0, 4.0, 9.8)
	LandmarkWestKit.blk(lm, "Render", q.x, 8.0, q.z - 0.8, 26.0, 3.6, 10.6)
	lm.gable("Slate", q + Vector3(0, 11.6, -0.8), 10.6, 26.0, 4.6, Basis(Vector3.UP, PI * 0.5), 0.5, "Render")
	var fz := q.z - 4.5
	for st in 3:
		var z := fz - 0.4 * float(st) - 0.04
		for k in 27:
			lm.box("Timber", Vector3(q.x - 13.0 + float(k), 4.0 * float(st) + 2.0, z), Vector3(0.22, 3.8, 0.06), Basis(), 0.0)
		lm.box("Timber", Vector3(q.x, 4.0 * float(st) + 0.15, z), Vector3(26.0, 0.3, 0.08), Basis(), 0.0)
		for k in 5:
			lm.box("Glass", Vector3(q.x - 10.0 + 5.0 * float(k), 4.0 * float(st) + 2.0, z - 0.02), Vector3(2.4, 1.4, 0.04), Basis(), 0.0)
	for k in 4:
		lm.gable("Slate", Vector3(q.x - 9.0 + 6.0 * float(k), 11.6, fz + 1.0), 3.6, 2.0, 2.4, Basis(), 0.2, "Render")
		LandmarkWestKit.chimney(lm, "Brick", Vector3(q.x - 12.0 + 8.0 * float(k), 14.0, q.z + 1.0), 1.0, 1.6, 3.2)

## Plane trees on Tower Green and in the wards.
static func _trees(lm: LandmarkMesh) -> void:
	for p in [Vector3(-70, 0, 8), Vector3(-58, 0, 14), Vector3(-48, 0, 2), Vector3(-74, 0, 22), Vector3(-52, 0, 26),
			Vector3(-84, 0, -34), Vector3(36, 0, -20), Vector3(34, 0, 18), Vector3(70, 0, -70), Vector3(-90, 0, 78),
			Vector3(-100, 0, -80), Vector3(70, 0, 60)]:
		var h := 9.0 + 1.4 * sin(p.x * 0.7 + p.z)
		lm.frustum("Timber", p + Vector3(0, 0.1, 0), 0.5, 0.35, h * 0.45, 8)
		lm.lathe("Foliage", p + Vector3(0, h * 0.4, 0), LandmarkWestKit.dome_prof(h * 0.34, h * 0.6, 5, 0.6), 10)
		lm.lathe("Foliage", p + Vector3(h * 0.1, h * 0.7, h * 0.06), LandmarkWestKit.dome_prof(h * 0.24, h * 0.34, 5, 0.6), 10)
