class_name LandmarkCathedrals
extends RefCounted

## Finland's two registry cathedrals in true metres.

## Turku Cathedral (Turun tuomiokirkko): the medieval red-brick
## basilica on Unikankare — long nave under a steep dark roof, side
## chapels, the polygonal choir to the east — and the massive square
## west tower whose Engel (1830s) top carries the clock stage and the
## tall octagonal spire, 86 m above the churchyard (101 m above sea).
## Nave along X, tower at the west (-X) end.
static func turku(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4A36", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#6E3A2C", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3F40", 2.0))
	lm.use("Spire", LandmarkMaterials.paint("#2F3A36", 0.55, 0.45))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E9E4D8", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Nave and aisles (hall-like), 24 m to the eaves, steep roof.
	lm.box("Brick", Vector3(12.0, 12.0, 0), Vector3(56.0, 24.0, 26.0))
	lm.gable("Roof", Vector3(12.0, 24.0, 0), 26.0, 56.0, 15.0, rot, 0.8, "Brick")
	# Side chapels with their own low gables.
	for sz in [-1.0, 1.0]:
		for k in 5:
			var x := -8.0 + float(k) * 9.5
			lm.box("Brick", Vector3(x, 6.5, sz * 15.5), Vector3(8.0, 13.0, 5.0))
			lm.gable("Roof", Vector3(x, 13.0, sz * 15.5), 8.0, 5.0, 4.0, Basis(), 0.3, "Brick")
			lm.box("Windows", Vector3(x, 8.0, sz * 18.05), Vector3(2.0, 5.5, 0.1))
			lm.box("Windows", Vector3(x, 18.0, sz * 13.05), Vector3(2.2, 7.0, 0.1))
			lm.box("BrickDark", Vector3(x + 4.75, 9.0, sz * 13.8), Vector3(1.4, 18.0, 1.6))
	# Choir: polygonal east end, tall windows.
	lm.lathe("Brick", Vector3(40.0, 0, 0), PackedVector2Array([Vector2(12.0, 0),
		Vector2(12.0, 24.0)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(40.0, 24.0, 0), PackedVector2Array([Vector2(13.0, 0),
		Vector2(0.5, 15.0)]), 10, 1.0, 1.0, 0.0, false)
	for k in 5:
		var a := -PI * 0.4 + PI * 0.2 * float(k)
		lm.box("Windows", Vector3(40.0 + cos(a) * 11.6, 12.0, sin(a) * 11.6),
			Vector3(0.3, 12.0, 2.0), Basis(Vector3.UP, -a))
	# West tower: 17 m square brick shaft with blind arcading.
	var tx := -24.0
	var w := 17.0
	var shaft := 47.0
	lm.box("Brick", Vector3(tx, shaft * 0.5, 0), Vector3(w, shaft, w))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 3:
			lm.box("BrickDark", Vector3(tx, 0, 0) + r * Vector3(-5.0 + 5.0 * float(k), 30.0, w * 0.5 + 0.1),
				Vector3(2.6, 14.0, 0.25), r)
		lm.box("Trim", Vector3(tx, 0, 0) + r * Vector3(0, shaft - 0.6, w * 0.5 + 0.3),
			Vector3(w + 0.6, 1.2, 0.6), r)
	# Engel top: setback clock stage with white trim and clock faces.
	var sw := 14.0
	lm.box("Brick", Vector3(tx, shaft + 5.0, 0), Vector3(sw, 10.0, sw))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out := r * Vector3(0, 0, 1)
		var c := Vector3(tx, 0, 0) + r * Vector3(0, shaft + 5.5, sw * 0.5)
		lm.disc("Gilt", c + out * 0.05, out, 1.9, 24)
		lm.disc("Spire", c + out * 0.1, out, 1.6, 24)
		for k in [-1.0, 1.0]:
			lm.box("Trim", Vector3(tx, 0, 0) + r * Vector3(k * (sw * 0.5 - 0.5), shaft + 5.0, sw * 0.5 + 0.1),
				Vector3(1.0, 10.0, 0.3), r)
		lm.box("Windows", Vector3(tx, 0, 0) + r * Vector3(0, shaft + 1.8, sw * 0.5 + 0.02),
			Vector3(3.0, 2.6, 0.1), r)
	lm.box("Trim", Vector3(tx, shaft + 10.4, 0), Vector3(sw + 0.8, 0.8, sw + 0.8))
	# Octagonal drum and the tall spire, ball and cross.
	lm.frustum("Spire", Vector3(tx, shaft + 10.8, 0), 6.2, 5.8, 3.2, 8, PI / 8.0)
	lm.lathe("Spire", Vector3(tx, shaft + 14.0, 0), PackedVector2Array([Vector2(5.8, 0),
		Vector2(4.2, 4.0), Vector2(0.18, 23.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", Vector3(tx, shaft + 36.4, 0), _ball(0.5), 8)
	lm.box("Gilt", Vector3(tx, shaft + 38.0, 0), Vector3(0.2, 2.2, 0.2))
	lm.box("Gilt", Vector3(tx, shaft + 38.4, 0), Vector3(1.1, 0.2, 0.2))
	lm.commit(model)

## Helsinki Cathedral (Engel/Lohrmann): white Greek-cross church on its
## high platform over Senate Square, a Corinthian portico with pediment
## on every arm, the green central dome on a colonnaded drum (62 m to
## the cross), four small corner domes, zinc apostles on the roofline,
## and the monumental stair down to the square (south, +Z).
static func helsinki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#ECE9E1", 3.0))
	lm.use("Green", LandmarkMaterials.pbr("concrete", "#4E8C74", 2.0, 0.55, 0.3))
	lm.use("Stairs", LandmarkMaterials.pbr("limestone", "#A79C8C", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#262D31"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var plat := 7.0
	lm.box("Stairs", Vector3(0, plat * 0.5, 0), Vector3(78.0, plat, 78.0))
	for k in 14:
		var z := 39.0 + float(k) * 1.6
		var h := plat * (1.0 - float(k) / 14.0)
		lm.box("Stairs", Vector3(0, h * 0.5, z + 0.8), Vector3(64.0, h, 1.6))
	var arm_l := 54.0
	var arm_w := 22.0
	var wall := 17.0
	for s in 2:
		var r := Basis(Vector3.UP, PI * 0.5 * float(s))
		lm.box("White", Vector3(0, plat + wall * 0.5, 0), Vector3(arm_w, wall, arm_l), r)
		lm.gable("Green", Vector3(0, plat + wall, 0), arm_w, arm_l, 5.0, r, 0.6, "White")
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		_portico(lm, r, plat, arm_l * 0.5, arm_w, wall)
		for k in [-1.0, 1.0]:
			lm.box("Windows", r * Vector3(k * 6.0, plat + 9.0, arm_l * 0.5 + 0.05),
				Vector3(2.4, 5.0, 0.1), r)
	# Corner towers with small domes.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 15.5, plat, sz * 15.5)
			lm.box("White", p + Vector3(0, (wall + 4.0) * 0.5, 0), Vector3(8.0, wall + 4.0, 8.0))
			lm.frustum("White", p + Vector3(0, wall + 4.0, 0), 3.6, 3.6, 3.0, 16)
			lm.lathe("Green", p + Vector3(0, wall + 7.0, 0), _dome(3.8, 4.6), 16)
			lm.frustum("Green", p + Vector3(0, wall + 11.4, 0), 0.9, 0.7, 2.0, 8)
			lm.box("Gilt", p + Vector3(0, wall + 14.0, 0), Vector3(0.25, 2.4, 0.25))
	# Central drum with its colonnade, dome, lantern and cross (62 m).
	var c := Vector3(0, plat + wall + 2.0, 0)
	lm.frustum("White", c - Vector3(0, 2.0, 0), 11.0, 11.0, 2.0, 24)
	lm.frustum("White", c, 9.0, 9.0, 13.0, 24)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.frustum("White", c + d * 10.0, 0.55, 0.45, 11.5, 8)
		if k % 2 == 0:
			lm.box("Windows", c + d * 9.02 + Vector3(0, 6.0, 0), Vector3(1.6, 4.5, 0.1),
				Basis(Vector3.UP, -a + PI * 0.5))
	lm.frustum("White", c + Vector3(0, 11.5, 0), 11.0, 10.6, 1.8, 24)
	lm.lathe("Green", c + Vector3(0, 13.3, 0), _dome(10.0, 12.0), 24)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Green", c + d * 9.8 + Vector3(0, 13.4, 0), c + d * 4.8 + Vector3(0, 23.0, 0), 0.45, 0.3)
	var lan := c + Vector3(0, 24.6, 0)
	lm.frustum("White", lan, 2.6, 2.6, 4.2, 12)
	lm.lathe("Green", lan + Vector3(0, 4.2, 0), _dome(2.9, 3.2), 12)
	lm.lathe("Gilt", lan + Vector3(0, 7.6, 0), _ball(0.45), 8)
	var top := 62.0
	lm.box("Gilt", Vector3(0, (lan.y + 8.4 + top) * 0.5, 0), Vector3(0.3, top - lan.y - 8.4, 0.3))
	lm.box("Gilt", Vector3(0, top - 1.6, 0), Vector3(1.6, 0.3, 0.3))
	lm.commit(model)

## Hexastyle Corinthian portico with pediment and three apostle statues.
static func _portico(lm: LandmarkMesh, r: Basis, plat: float, z: float, w: float, h: float) -> void:
	for k in 6:
		var x := -w * 0.42 + w * 0.84 * float(k) / 5.0
		lm.frustum("White", r * Vector3(x, plat, z + 3.5), 0.85, 0.72, h - 2.0, 12)
		lm.box("White", r * Vector3(x, plat + h - 1.6, z + 3.5), Vector3(2.0, 0.9, 2.0), r)
	lm.box("White", r * Vector3(0, plat + h - 0.6, z + 3.0), Vector3(w + 0.8, 1.6, 6.0), r)
	lm.gable("White", r * Vector3(0, plat + h + 0.2, z + 3.0), w + 0.8, 6.0, 4.4, r, 0.4, "White")
	for k in 3:
		var x := -w * 0.45 + w * 0.45 * float(k)
		var p := r * Vector3(x, plat + h + (4.6 if k == 1 else 0.2), z + 5.6)
		lm.frustum("Green", p, 0.5, 0.4, 2.6, 8)
		lm.lathe("Green", p + Vector3(0, 2.6, 0), _ball(0.35), 8)

static func _dome(r: float, h: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 9:
		var t := PI * 0.5 * float(k) / 8.0
		pr.append(Vector2(cos(t) * r, sin(t) * h * (0.85 + 0.15 * sin(t))))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr

static func _ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr
