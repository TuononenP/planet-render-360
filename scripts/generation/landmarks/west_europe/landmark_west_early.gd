class_name LandmarkWestEarly
extends RefCounted

## Three hill and plain sites of the west European batch in true metres:
## Mont-Saint-Michel, Stonehenge and Edinburgh Castle. The two crag
## sites have y = 0 on the summit platform with the rock and the
## retaining walls built below it.

## Mont-Saint-Michel (90 m above the summit platform): the granite rock
## with the village clinging to its flank, the north face of La Merveille,
## the abbey church — Romanesque nave, transept, Gothic choir — and the
## crossing tower with the 56 m spire and gilded Archangel Michael.
static func mont_saint_michel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8D8472", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A59D8C", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	var rock := PackedVector2Array([Vector2(72, -45), Vector2(62, -25), Vector2(56, -10), Vector2(53, -1),
		Vector2(50, 0)])
	lm.lathe("Rock", Vector3.ZERO, rock, 14, 1.0, 1.0, 0.3, false)
	# Village houses stepping down the rock, each sunk into the slope.
	for k in 22:
		var a := 0.62 * float(k)
		var y := -5.0 - float((k * 7) % 24)
		var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(-45, 72), Vector2(-25, 62),
			Vector2(-10, 56), Vector2(0, 50)]), y)
		var p := Vector3(cos(a), 0, sin(a)) * (rr - 1.0)
		LandmarkWestKit.blk(lm, "Granite", p.x, y - 2.0, p.z, 7.0, 6.0, 5.0, -a)
		lm.gable("Slate", Vector3(p.x, y + 4.0, p.z), 5.0, 7.0, 2.5, Basis(Vector3.UP, -a + PI * 0.5), 0.4, "Granite")
	# La Merveille: the 48 m north wall with buttresses, roofed hall block.
	LandmarkWestKit.blk(lm, "Granite", -2.0, -30.0, -21.0, 56.0, 48.0, 18.0)
	for k in 10:
		LandmarkWestKit.blk(lm, "Granite", -26.0 + 5.8 * float(k), -30.0, -30.8, 1.8, 40.0, 1.6)
	lm.gable("Slate", Vector3(-2.0, 18.0, -21.0), 18.0, 56.0, 6.0, rot, 0.6, "Granite")
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-28, 0, -30.1), Vector3(26, 0, -30.1), Vector3(0, 0, -1),
		5.8, 1.2, 3.5, [4.0, 12.0])
	# West terrace and its buttressed substructure.
	LandmarkWestKit.blk(lm, "Granite", -66.0, -40.0, 0, 26.0, 40.0, 40.0)
	LandmarkWestKit.merlons(lm, "Granite", Vector3(-79, 0, -20), Vector3(-79, 0, 20), 2.2, 1.0, 1.0, 1.0)
	# Abbey church: nave, transept, choir, apse.
	LandmarkWestKit.blk(lm, "Granite", -31.0, 0, 0, 50.0, 20.0, 20.0)
	lm.gable("Slate", Vector3(-31.0, 20.0, 0), 20.0, 50.0, 8.0, rot, 0.6, "Granite")
	LandmarkWestKit.blk(lm, "Granite", 1.0, 0, 0, 14.0, 24.0, 42.0)
	lm.gable("Slate", Vector3(1.0, 24.0, 0), 14.0, 42.0, 7.0, Basis(), 0.6, "Granite")
	LandmarkWestKit.blk(lm, "Granite", 25.0, 0, 0, 34.0, 24.0, 18.0)
	lm.gable("Slate", Vector3(25.0, 24.0, 0), 18.0, 34.0, 8.0, rot, 0.6, "Granite")
	lm.lathe("Granite", Vector3(42, 0, 0), PackedVector2Array([Vector2(9, 0), Vector2(9, 24)]), 10, 1.0, 1.0,
		0.0, false)
	lm.lathe("Slate", Vector3(42, 24, 0), PackedVector2Array([Vector2(9.8, 0), Vector2(0.0, 9.0)]), 10)
	for k in 7:
		LandmarkWestKit.blk(lm, "Granite", 12.0 + 5.2 * float(k), 0, 9.6, 1.4, 22.0, 1.6)
		LandmarkWestKit.blk(lm, "Granite", 12.0 + 5.2 * float(k), 0, -9.6, 1.4, 22.0, 1.6)
	for sz in [-1.0, 1.0]:
		lm.lathe("Granite", Vector3(-6, 0, sz * 9.0), PackedVector2Array([Vector2(2.4, 0), Vector2(2.2, 26.0)]), 10)
		lm.lathe("Slate", Vector3(-6, 26, sz * 9.0), PackedVector2Array([Vector2(2.7, 0), Vector2(0.0, 5.0)]), 10)
	# Crossing tower, spire (to 90 m) and the gilded archangel.
	LandmarkWestKit.blk(lm, "Granite", 1.0, 20.0, 0, 14.0, 14.0, 14.0)
	lm.lathe("Slate", Vector3(1, 34, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(3.8, 10.0),
		Vector2(2.2, 28.0), Vector2(1.0, 44.0), Vector2(0.35, 52.0), Vector2(0.1, 56.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.box("Gilt", Vector3(1, 87.0, 0), Vector3(0.6, 3.0, 0.6))
	lm.box("Gilt", Vector3(1, 88.2, 0), Vector3(0.4, 1.4, 3.4))
	lm.lathe("Gilt", Vector3(1, 88.0, 0), LandmarkWestKit.ball(0.5), 8)
	lm.box("Gilt", Vector3(1, 89.6, 0), Vector3(0.15, 0.8, 0.15))
	lm.commit(model)

## Stonehenge (7.3 m): the sarsen circle with its lintels as it stands
## today (gaps in the south-west and north), the five-trilithon horseshoe
## open to the midsummer sunrise (north-east), the bluestone circle and
## horseshoe, the Altar Stone, the Heel Stone and the earth bank.
static func stonehenge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sarsen", LandmarkMaterials.pbr("stone", "#8C877B", 2.5))
	lm.use("Blue", LandmarkMaterials.pbr("rock", "#6E767B", 2.0))
	lm.use("Bank", LandmarkMaterials.pbr("lawn", "#7C8F55", 4.0))
	# Midsummer-sunrise axis: the horseshoe opens along it (bearing 51 deg).
	var open := Vector2(sin(deg_to_rad(51.0)), -cos(deg_to_rad(51.0)))
	var back := atan2(-open.y, -open.x)
	var missing := [5, 6, 7, 8, 17, 18, 19, 25]
	for k in 30:
		var a := TAU * float(k) / 30.0
		if not k in missing:
			_stone(lm, "Sarsen", a, 15.0, 2.1, 1.1, 4.1)
		var b := TAU * float(k + 1) / 30.0
		if not k in missing and not (k + 1) % 30 in missing and k % 7 != 3:
			var m := (a + b) * 0.5
			lm.box("Sarsen", Vector3(cos(m) * 14.9, 4.5, sin(m) * 14.9), Vector3(3.5, 0.8, 1.2),
				Basis(Vector3.UP, -m - PI * 0.5))
	# Five trilithons (7.3 / 6.7 / 6.1 m including lintels).
	for t in [[0.0, 7.3], [0.84, 6.7], [-0.84, 6.7], [1.68, 6.1], [-1.68, 6.1]]:
		var a: float = back + float(t[0])
		var h: float = float(t[1]) - 0.8
		for s in [-1.4, 1.4]:
			var c: Vector2 = Vector2(cos(a), sin(a)) * 9.0 + Vector2(-sin(a), cos(a)) * s
			lm.box("Sarsen", Vector3(c.x, h * 0.5, c.y), Vector3(2.2, h, 1.4), Basis(Vector3.UP, -a - PI * 0.5))
		lm.box("Sarsen", Vector3(cos(a) * 9.0, h + 0.4, sin(a) * 9.0), Vector3(5.6, 0.8, 1.5),
			Basis(Vector3.UP, -a - PI * 0.5))
	# Bluestones: outer circle, inner horseshoe, Altar Stone, Heel Stone.
	for k in 40:
		if k % 9 != 4:
			_stone(lm, "Blue", TAU * float(k) / 40.0, 11.0, 1.1, 0.7, 2.0)
	for k in 19:
		_stone(lm, "Blue", back - 1.9 + 3.8 * float(k) / 18.0, 5.2, 0.9, 0.6, 2.3)
	lm.box("Blue", Vector3(cos(back) * 5.0, 0.25, sin(back) * 5.0), Vector3(4.8, 0.6, 1.0),
		Basis(Vector3.UP, -back))
	lm.box("Sarsen", Vector3(open.x * 77.0, 2.4, open.y * 77.0), Vector3(2.4, 4.8, 1.8),
		Basis(Vector3.UP, 0.3))
	# Earth bank and ditch, ~55 m from the centre.
	lm.lathe("Bank", Vector3.ZERO, PackedVector2Array([Vector2(47, 0), Vector2(51, 0.6), Vector2(55, 0)]), 40,
		1.0, 1.0, 0.0, true, false)
	lm.commit(model)

## One upright at angle `a` on a circle of `radius`, turned to the tangent.
static func _stone(lm: LandmarkMesh, key: String, a: float, radius: float, w: float, d: float, h: float) -> void:
	lm.box(key, Vector3(cos(a) * radius, h * 0.5, sin(a) * radius), Vector3(w, h, d),
		Basis(Vector3.UP, -a - PI * 0.5))

## Edinburgh Castle (26 m above the summit platform): the volcanic crag,
## the curtain wall and towers round the summit, Crown Square with the
## Royal Palace and its stair tower, the Great Hall, the Scottish
## National War Memorial and Queen Anne building, St Margaret's Chapel,
## the Half Moon Battery and the Portcullis Gate towards the Royal Mile
## (east, +X).
static func edinburgh_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7A7466", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A917F", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	lm.lathe("Rock", Vector3.ZERO, PackedVector2Array([Vector2(100, -60), Vector2(88, -35), Vector2(78, -12),
		Vector2(68, 0)]), 16, 1.6, 1.0, 0.2, false)
	# Curtain wall following the plateau edge, round towers every fourth post.
	var n := 24
	for k in n:
		var a0 := TAU * float(k) / float(n)
		var a1 := TAU * float(k + 1) / float(n)
		var p0 := Vector3(cos(a0) * 104.0, 0, sin(a0) * 65.0)
		var p1 := Vector3(cos(a1) * 104.0, 0, sin(a1) * 65.0)
		var d := p1 - p0
		lm.box("Stone", (p0 + p1) * 0.5 + Vector3(0, 4.0, 0), Vector3(3.0, 11.0, d.length()),
			Basis(Vector3.UP, atan2(d.x, d.z)))
		LandmarkWestKit.merlons(lm, "Stone", p0 + Vector3(0, 9.5, 0), p1 + Vector3(0, 9.5, 0), 2.4, 1.2, 1.0, 2.6)
		if k % 4 == 0:
			lm.frustum("Stone", p0 - Vector3(0, 6, 0), 4.6, 4.2, 20.0, 12)
			lm.lathe("Slate", p0 + Vector3(0, 14, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(0.0, 4.5)]), 12)
	# Crown Square: palace (east) with its stair tower, Great Hall (south),
	# War Memorial (north), Queen Anne building (west).
	LandmarkWestKit.blk(lm, "Stone", 18.0, 0, 0, 14.0, 17.0, 30.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(18.0, 17.0, 0), 15.0, 31.0, 5.0, 0.8)
	LandmarkWestKit.blk(lm, "Stone", 18.0, 0, -17.0, 7.0, 20.0, 7.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(18.0, 20.0, -17.0), 8.0, 8.0, 6.0, 0.0)
	LandmarkWestKit.blk(lm, "Stone", -2.0, 0, 17.0, 36.0, 12.0, 12.0)
	lm.gable("Slate", Vector3(-2.0, 12.0, 17.0), 12.0, 36.0, 8.0, rot, 0.6, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -17.0, 30.0, 12.0, 10.0)
	lm.gable("Slate", Vector3(0, 12.0, -17.0), 10.0, 30.0, 6.0, rot, 0.6, "Stone")
	LandmarkWestKit.blk(lm, "Stone", -20.0, 0, 0, 10.0, 15.0, 30.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(-20.0, 15.0, 0), 11.0, 31.0, 4.0, 0.7)
	LandmarkWestKit.blk(lm, "Stone", -42.0, 0, -6.0, 6.0, 3.5, 10.0)
	lm.gable("Slate", Vector3(-42.0, 3.5, -6.0), 6.0, 10.0, 3.0, Basis(), 0.3, "Stone")
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-17, 0, 10.9), Vector3(15, 0, 10.9), Vector3(0, 0, 1),
		6.0, 1.4, 3.0, [5.0])
	LandmarkWestKit.win_line(lm, "Glass", Vector3(11.1, 0, -14), Vector3(11.1, 0, 14), Vector3(-1, 0, 0),
		5.0, 1.4, 3.2, [5.0, 12.0])
	# Half Moon Battery and the Portcullis Gate.
	lm.lathe("Stone", Vector3(62, -12, 0), PackedVector2Array([Vector2(15, 0), Vector2(15, 26)]), 14, 1.0, 1.0,
		0.0, false)
	lm.lathe("Stone", Vector3(62, 14, 0), PackedVector2Array([Vector2(15.5, 0), Vector2(15.5, 1.0)]), 14)
	LandmarkWestKit.blk(lm, "Stone", 84.0, -10.0, 0, 12.0, 30.0, 12.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(84.0, 20.0, 0), 13.0, 13.0, 5.0, 0.0)
	lm.commit(model)
