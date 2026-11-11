class_name LandmarkCathedrals
extends RefCounted

## Finland's two registry cathedrals in true metres.

## Turku Cathedral (Turun tuomiokirkko): the medieval red-brick
## basilica on Unikankare, 89 m long and 38 m wide — the tall nave and
## aisles under one steep roof (vaults raised to 24 m in the late 15th
## century), the row of side chapels along both flanks with their own
## stepped gables and whitewashed blind niches, buttresses, the
## polygonal choir to the east with the sacristy on its north side —
## and the massive square west tower whose Engel (1830s) top carries
## the clock stage and the tall octagonal spire, 86 m above the
## churchyard (101 m above sea). Nave along X, tower at the west (-X).
static func turku(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4A36", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#6E3A2C", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3F40", 2.0))
	lm.use("Spire", LandmarkMaterials.paint("#2F3A36", 0.55, 0.45))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E9E4D8", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_turku_body(lm)
	_turku_choir(lm)
	_turku_tower(lm)
	lm.commit(model)

const _TK_X0 := -15.5
const _TK_X1 := 40.0
const _TK_EAVE := 24.0

## Nave and aisles (one 26 m wide hall-like body to the 24 m eaves) and
## the 15 m-pitch roof; five chapels a side between buttresses, each
## with a stepped gable, a two-light window and blind niches; the tall
## clerestory lancets above the chapel roofs.
static func _turku_body(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	var len_x := _TK_X1 - _TK_X0
	var cx := (_TK_X0 + _TK_X1) * 0.5
	lm.box("Brick", Vector3(cx, 0.6, 0), Vector3(len_x + 0.6, 1.2, 26.6))
	lm.box("Brick", Vector3(cx, _TK_EAVE * 0.5, 0), Vector3(len_x, _TK_EAVE, 26.0))
	lm.gable("Roof", Vector3(cx, _TK_EAVE, 0), 26.0, len_x, 15.0, rot, 0.8, "Brick")
	# Eaves corbel table (stepped brick) and the roof ridge.
	for sz in [-1.0, 1.0]:
		lm.box("BrickDark", Vector3(cx, _TK_EAVE - 0.5, sz * 13.15), Vector3(len_x, 1.0, 0.5))
		for k in 46:
			lm.box("BrickDark", Vector3(_TK_X0 + 0.6 + float(k) * len_x / 46.0, _TK_EAVE - 1.3, sz * 13.15),
				Vector3(0.5, 0.7, 0.35), Basis(), 0.0)
	lm.box("Roof", Vector3(cx, _TK_EAVE + 15.05, 0), Vector3(len_x + 1.6, 0.35, 0.5))
	for sz in [-1.0, 1.0]:
		var o := Vector3(0, 0, sz)
		for k in 5:
			var x := -9.0 + float(k) * 9.5
			# Chapel: brick box, its own gabled roof and stepped gable.
			lm.box("Brick", Vector3(x, 6.5, sz * 15.5), Vector3(8.0, 13.0, 5.0))
			lm.gable("Roof", Vector3(x, 13.0, sz * 15.5), 8.0, 5.0, 5.0, Basis(), 0.3, "Brick")
			LandmarkCoreAGothic.stepped_gable(lm, "Brick", "Trim", Vector3(x, 13.0, sz * 18.0), o, 8.4, 6.5,
				0.6, 4, 3)
			LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(x, 3.5, sz * 18.0), o, 2.6, 7.5, 0.4, 2)
			# Clerestory lancet over the chapel roof.
			LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(x, 18.3, sz * 13.0), o, 2.4, 4.2, 0.35, 2, 0.75)
		# Buttresses between and at the ends of the chapels.
		for k in 6:
			var x := -13.75 + float(k) * 9.5
			LandmarkCoreAGothic.buttress(lm, "BrickDark", Vector3(x, 0, sz * 18.0), o, 1.4, 1.6, 11.0, 2)
			LandmarkCoreAGothic.buttress(lm, "BrickDark", Vector3(x, 13.0, sz * 13.0), o, 1.2, 1.2, 10.0, 2)
	# The south porch (Engel-era entrance) between the 2nd and 3rd chapels.
	lm.box("Brick", Vector3(5.25, 4.5, 19.6), Vector3(5.0, 9.0, 3.2))
	lm.gable("Roof", Vector3(5.25, 9.0, 19.6), 5.0, 3.2, 3.0, Basis(), 0.25, "Brick")
	LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(5.25, 0.3, 21.2), Vector3.BACK, 2.4, 5.0, 0.5, 1,
		1.0, true, 0.45)

## Polygonal choir (five-sided apse) with stepped buttresses and tall
## three-light windows, its conical roof, and the two-storey sacristy
## on the north side with its stepped east gable.
static func _turku_choir(lm: LandmarkMesh) -> void:
	var c := Vector3(_TK_X1, 0, 0)
	var r := 12.0
	lm.lathe("Brick", c, PackedVector2Array([Vector2(r + 0.4, 0), Vector2(r + 0.4, 1.2), Vector2(r, 1.2),
		Vector2(r, _TK_EAVE)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", c + Vector3(0, _TK_EAVE, 0), PackedVector2Array([Vector2(r + 1.0, 0),
		Vector2(0.5, 15.0)]), 10, 1.0, 1.0, 0.0, false)
	var apo := r * cos(PI / 10.0)
	for k in 5:
		var a := -PI * 0.4 + PI * 0.2 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", c + d * apo + Vector3(0, 7.0, 0), d, 2.8, 13.0, 0.4, 3)
	for k in 6:
		var a := -PI * 0.5 + PI * 0.2 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCoreAGothic.buttress(lm, "BrickDark", c + d * r, d, 1.4, 2.4, 20.0, 3)
	# Sacristy (north of the choir).
	var sc := Vector3(46.0, 0, -15.0)
	lm.box("Brick", sc + Vector3(0, 5.5, 0), Vector3(10.0, 11.0, 7.0))
	lm.gable("Roof", sc + Vector3(0, 11.0, 0), 7.0, 10.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Brick")
	LandmarkCoreAGothic.stepped_gable(lm, "Brick", "Trim", sc + Vector3(5.0, 11.0, 0), Vector3.RIGHT, 7.4,
		6.0, 0.6, 4, 3)
	for k in 2:
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", sc + Vector3(-2.5 + 5.0 * float(k), 2.0, -3.5),
			Vector3.FORWARD, 1.6, 3.6, 0.3, 1)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", sc + Vector3(-2.5 + 5.0 * float(k), 6.6, -3.5),
			Vector3.FORWARD, 1.4, 3.0, 0.3, 1)

## West tower: 17 m square brick shaft to 47 m with clasping corner
## buttresses, the deep west portal, string courses and tiers of tall
## whitewashed blind niches; Engel's clock stage with round-arched
## belfry openings and gilt dials; the octagonal drum and spire.
static func _turku_tower(lm: LandmarkMesh) -> void:
	var tx := -24.0
	var w := 17.0
	var shaft := 47.0
	var t := Vector3(tx, 0, 0)
	lm.box("Brick", t + Vector3(0, 0.75, 0), Vector3(w + 0.8, 1.5, w + 0.8))
	lm.box("Brick", t + Vector3(0, shaft * 0.5, 0), Vector3(w, shaft, w))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out := r * Vector3(0, 0, 1)
		var rt := r * Vector3(1, 0, 0)
		var face := t + out * w * 0.5
		# Clasping corner buttresses, stepping in up the shaft.
		for k in [-1.0, 1.0]:
			LandmarkCoreAGothic.buttress(lm, "Brick", face + rt * k * (w * 0.5 - 1.1), out, 2.2, 1.5, 34.0, 3)
		# String courses.
		for y in [12.0, 24.0, 36.0]:
			lm.box("BrickDark", face + Vector3(0, y, 0) + out * 0.2, Vector3(w, 0.5, 0.4), r, 0.0)
		# Blind niches: two tiers of three tall whitewashed lancets.
		for tier in 2:
			for k in 3:
				var x := -4.6 + 4.6 * float(k)
				LandmarkCoreAGothic.lancet(lm, "Brick", "Trim", face + rt * x + Vector3(0, 13.5 + tier * 12.0, 0),
					out, 2.4, 9.0, 0.35, 1, 0.9, false)
		# Belfry slits in the top tier.
		for k in 2:
			LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", face + rt * (-2.3 + 4.6 * float(k)) + Vector3(0, 38.0, 0),
				out, 1.6, 6.0, 0.35, 1)
		lm.box("Trim", face + Vector3(0, shaft - 0.6, 0) + out * 0.3, Vector3(w + 0.6, 1.2, 0.6), r)
	# West portal: deep recessed pointed doorway with three orders.
	var wf := t + Vector3(-w * 0.5, 0, 0)
	for k in 3:
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", wf + Vector3(-0.5 * float(2 - k), 1.5, 0),
			Vector3.LEFT, 3.2 + 1.2 * float(k), 7.0 + 1.0 * float(k), 0.5, 1, 1.0, k == 2, 0.5)
	LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", wf + Vector3(-0.4, 15.0, 0), Vector3.LEFT, 3.6, 9.0, 0.45, 3)
	# Engel top: setback clock stage with white corner pilasters, the
	# round-arched belfry openings and gilt-ringed dials.
	var sw := 14.0
	lm.box("Brick", Vector3(tx, shaft + 5.0, 0), Vector3(sw, 10.0, sw))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out := r * Vector3(0, 0, 1)
		var c := Vector3(tx, 0, 0) + r * Vector3(0, shaft + 6.6, sw * 0.5)
		lm.disc("Gilt", c + out * 0.05, out, 1.9, 24)
		lm.disc("Spire", c + out * 0.1, out, 1.6, 24)
		for hr in 12:
			var a := TAU * float(hr) / 12.0
			lm.box("Gilt", c + out * 0.14 + r * Vector3(sin(a), cos(a), 0) * 1.35, Vector3(0.14, 0.4, 0.06),
				r * Basis(Vector3.BACK, -a), 0.0)
		lm.beam("Gilt", c + out * 0.18, c + out * 0.18 + r * Vector3(0.7, 0.6, 0), 0.12, 0.05, out)
		lm.beam("Gilt", c + out * 0.18, c + out * 0.18 + r * Vector3(-0.2, 1.3, 0), 0.09, 0.05, out)
		for k in [-1.0, 1.0]:
			lm.box("Trim", Vector3(tx, 0, 0) + r * Vector3(k * (sw * 0.5 - 0.5), shaft + 5.0, sw * 0.5 + 0.1),
				Vector3(1.0, 10.0, 0.3), r)
			LandmarkCoreAGothic.lancet(lm, "Trim", "Windows", Vector3(tx, 0, 0) + r * Vector3(k * 3.2, shaft + 0.8, sw * 0.5),
				out, 1.6, 3.4, 0.25, 1, 0.5, false)
		LandmarkDetail.cornice(lm, "Trim", Vector3(tx, 0, 0) + r * Vector3(-sw * 0.5 - 0.1, shaft + 9.2, sw * 0.5),
			Vector3(tx, 0, 0) + r * Vector3(sw * 0.5 + 0.1, shaft + 9.2, sw * 0.5), out, 0.9, true)
	lm.box("Trim", Vector3(tx, shaft + 10.4, 0), Vector3(sw + 0.8, 0.8, sw + 0.8))
	# Octagonal drum with oculi, then the spire with its eight ribs,
	# ball and cross.
	lm.frustum("Spire", Vector3(tx, shaft + 10.8, 0), 6.2, 5.8, 3.2, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.disc("Gilt", Vector3(tx, shaft + 12.4, 0) + d * 5.95, d, 0.55, 12)
	lm.lathe("Spire", Vector3(tx, shaft + 14.0, 0), PackedVector2Array([Vector2(5.8, 0),
		Vector2(4.2, 4.0), Vector2(0.18, 23.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := Vector3(tx, shaft + 14.0, 0) + d * 5.85
		var p1 := Vector3(tx, shaft + 18.0, 0) + d * 4.25
		var p2 := Vector3(tx, shaft + 36.6, 0) + d * 0.3
		lm.beam("Spire", p0, p1, 0.3, 0.25, d.cross(Vector3.UP))
		lm.beam("Spire", p1, p2, 0.25, 0.2, d.cross(Vector3.UP))
	# Lucarnes: four small gabled dormers on the spire's foot.
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side) + PI * 0.5)
		var p := Vector3(tx, shaft + 15.0, 0) + r * Vector3(0, 0, 4.2)
		lm.box("Spire", p + r * Vector3(0, 1.0, 0.6), Vector3(1.4, 2.0, 1.6), r)
		lm.gable("Spire", p + r * Vector3(0, 2.0, 0.6), 1.4, 1.6, 1.0, r, 0.1, "Spire")
		lm.box("Windows", p + r * Vector3(0, 1.0, 1.42), Vector3(0.7, 1.4, 0.05), r, 0.0)
	lm.lathe("Gilt", Vector3(tx, shaft + 36.4, 0), _ball(0.5), 8)
	lm.box("Gilt", Vector3(tx, shaft + 38.0, 0), Vector3(0.2, 2.2, 0.2))
	lm.box("Gilt", Vector3(tx, shaft + 38.4, 0), Vector3(1.1, 0.2, 0.2))

## Helsinki Cathedral (Engel 1830–52, completed by Lohrmann): the
## white Greek-cross church on its high platform over Senate Square —
## a hexastyle Corinthian portico with a pediment on each of the four
## arms, round-arched windows between pilasters, the tall green central
## dome on a drum ringed by 24 Corinthian columns (62 m to the cross),
## Lohrmann's four small corner domes on colonnaded drums, the twelve
## zinc apostles on the pediment apexes and corners (1849), and the
## monumental stair down to the square (south, +Z) between cheek walls.
static func helsinki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#ECE9E1", 3.0))
	lm.use("Green", LandmarkMaterials.pbr("concrete", "#4E8C74", 2.0, 0.55, 0.3))
	lm.use("Stairs", LandmarkMaterials.pbr("limestone", "#A79C8C", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#262D31"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# y = 0 is Senate Square at the stair's foot (registry `base_at_m`);
	# the terrace stands 9.8 m above it, level with the hilltop in the
	# city's elevation model. Its walls and the cheeks go `found` m below
	# y = 0 so the lower streets east and north never show a gap.
	var plat := 9.8
	var found := 4.0
	lm.box("Stairs", Vector3(0, (plat - found) * 0.5, 0), Vector3(78.0, plat + found, 78.0))
	lm.box("Stairs", Vector3(0, plat + 0.3, 0), Vector3(78.6, 0.6, 78.6))
	# Monumental stair: a 2 m landing, then 49 risers of 0.2 m over 30 m
	# (z 41..71), 64 m wide, between cheeks. Each step sits on a 1 m
	# footing so the square's slope never opens under it.
	lm.box("Stairs", Vector3(0, (plat - 1.0) * 0.5, 40.0), Vector3(64.0, plat + 1.0, 2.0), Basis(), 0.0)
	var risers := 49
	var tread := 30.0 / float(risers)
	for k in risers:
		var z := 41.0 + float(k) * tread
		var h := plat * (1.0 - float(k + 1) / float(risers + 1))
		lm.box("Stairs", Vector3(0, (h - 1.0) * 0.5, z + tread * 0.5), Vector3(64.0, h + 1.0, tread), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		lm.box("Stairs", Vector3(sx * 33.0, (plat + 0.6 - found) * 0.5, 55.0), Vector3(2.0, plat + 0.6 + found, 32.0))
	var arm_l := 54.0
	var arm_w := 22.0
	var wall := 17.0
	for s in 2:
		var r := Basis(Vector3.UP, PI * 0.5 * float(s))
		lm.box("White", Vector3(0, plat + wall * 0.5, 0), Vector3(arm_w, wall, arm_l), r)
		lm.box("White", Vector3(0, plat + 0.6, 0), Vector3(arm_w + 0.8, 1.2, arm_l + 0.8), r)
		lm.gable("Green", Vector3(0, plat + wall + 0.9, 0), arm_w, arm_l, 5.0, r, 0.9, "White")
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out := r * Vector3(0, 0, 1)
		var rt := r * Vector3(1, 0, 0)
		_portico(lm, r, plat, arm_l * 0.5, arm_w, wall)
		var end := out * arm_l * 0.5
		for kv in [-1.0, 1.0]:
			var k: float = kv
			lm.box("Windows", r * Vector3(k * 6.0, plat + 9.0, arm_l * 0.5 + 0.05), Vector3(2.4, 5.0, 0.1), r)
			LandmarkDetail.window(lm, "White", "Windows", end + rt * k * 6.0 + Vector3(0, plat + 9.0, 0), out,
				2.4, 5.2, true)
			# The arm's flank between the corner tower and the end.
			var fl := rt * k * arm_w * 0.5 + out * 23.25
			LandmarkDetail.window(lm, "White", "Windows", fl + Vector3(0, plat + 9.0, 0), rt * k, 2.4, 5.2, true)
			LandmarkDetail.window(lm, "White", "Windows", fl + Vector3(0, plat + 3.2, 0), rt * k, 1.6, 2.0, false)
			# Corner pilasters on the arm's end.
			var pc := end + rt * k * (arm_w * 0.5 - 0.6)
			lm.box("White", pc + Vector3(0, plat + wall * 0.5, 0) + out * 0.25, Vector3(1.4, wall - 2.0, 0.5), r)
			lm.box("White", pc + Vector3(0, plat + wall - 1.6, 0) + out * 0.4, Vector3(1.8, 1.0, 0.8), r)
			lm.box("White", fl + rt * k * 0.25 + out * 3.15 + Vector3(0, plat + wall * 0.5, 0),
				Vector3(0.5, wall - 2.0, 1.4), r)
			# Cornice along the flank.
			LandmarkDetail.cornice(lm, "White", rt * k * arm_w * 0.5 + out * 19.5 + Vector3(0, plat + wall - 0.9, 0),
				rt * k * arm_w * 0.5 + out * arm_l * 0.5 + Vector3(0, plat + wall - 0.9, 0), rt * k, 0.9)
		# Frieze band round the arm's end.
		lm.box("White", end + Vector3(0, plat + wall - 2.2, 0) + out * 0.15, Vector3(arm_w, 0.5, 0.3), r)
	# Corner towers with small domes on colonnaded drums.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 15.5, plat, sz * 15.5)
			lm.box("White", p + Vector3(0, (wall + 4.0) * 0.5, 0), Vector3(8.0, wall + 4.0, 8.0))
			for d in [Vector3(sx, 0, 0), Vector3(0, 0, sz)]:
				LandmarkDetail.window(lm, "White", "Windows", p + d * 4.0 + Vector3(0, 10.0, 0), d, 1.8, 4.2, true)
				LandmarkDetail.cornice(lm, "White", p + d * 4.0 + d.cross(Vector3.UP) * 4.0 + Vector3(0, wall + 3.2, 0),
					p + d * 4.0 - d.cross(Vector3.UP) * 4.0 + Vector3(0, wall + 3.2, 0), d, 0.8)
			var dr := p + Vector3(0, wall + 4.0, 0)
			lm.frustum("White", dr, 3.0, 3.0, 3.2, 16)
			lm.frustum("White", dr, 3.9, 3.9, 0.4, 16)
			for k in 8:
				var a := TAU * (float(k) + 0.5) / 8.0
				var cp := dr + Vector3(cos(a), 0, sin(a)) * 3.45 + Vector3(0, 0.4, 0)
				lm.frustum("White", cp, 0.2, 0.17, 2.6, 8)
				lm.box("White", cp + Vector3(0, 2.7, 0), Vector3(0.5, 0.2, 0.5), Basis(), 0.0)
			lm.frustum("White", dr + Vector3(0, 3.2, 0), 3.9, 3.8, 0.6, 16)
			lm.lathe("Green", dr + Vector3(0, 3.8, 0), _dome(3.8, 4.4), 16)
			lm.frustum("White", dr + Vector3(0, 8.0, 0), 0.9, 0.9, 1.2, 8)
			lm.lathe("Green", dr + Vector3(0, 9.2, 0), _dome(1.0, 0.9), 8)
			lm.lathe("Gilt", dr + Vector3(0, 10.1, 0), _ball(0.25), 8)
			lm.box("Gilt", dr + Vector3(0, 11.4, 0), Vector3(0.18, 2.2, 0.18))
			lm.box("Gilt", dr + Vector3(0, 11.9, 0), Vector3(0.9, 0.16, 0.16))
	# Central drum with its colonnade, dome, lantern and cross, 62 m above
	# the square: the drum gives back what the measured terrace added.
	var c := Vector3(0, plat + wall + 2.0, 0)
	var drum := 13.0 - (plat - 7.0)
	lm.frustum("White", c - Vector3(0, 2.0, 0), 11.0, 11.0, 2.0, 32)
	lm.frustum("White", c, 9.0, 9.0, drum, 32)
	lm.frustum("White", c, 11.0, 11.0, 0.5, 32)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.column(lm, "White", c + d * 10.0 + Vector3(0, 0.5, 0), 0.48, drum - 2.0, "corinthian", 0)
		if k % 2 == 0:
			var aw := TAU * (float(k) + 0.5) / 24.0
			var dw := Vector3(cos(aw), 0, sin(aw))
			LandmarkDetail.window(lm, "White", "Windows", c + dw * 9.0 + Vector3(0, drum * 0.46, 0), dw, 1.4, drum * 0.34, true,
				0.18)
	lm.frustum("White", c + Vector3(0, drum - 1.5, 0), 11.0, 10.8, 1.0, 32)
	lm.lathe("White", c + Vector3(0, drum - 0.5, 0), PackedVector2Array([Vector2(10.8, 0), Vector2(11.3, 0.4),
		Vector2(11.4, 0.8), Vector2(10.0, 0.8)]), 32)
	lm.lathe("Green", c + Vector3(0, drum + 0.3, 0), _dome(10.0, 12.0), 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := c + d * 10.05 + Vector3(0, drum + 0.3, 0)
		for j in range(1, 7):
			var t := PI * 0.5 * float(j) / 8.0
			var q := c + d * (cos(t) * 10.05) + Vector3(0, drum + 0.3 + sin(t) * 12.0 * (0.85 + 0.15 * sin(t)), 0)
			lm.beam("Green", prev, q, 0.4, 0.3, d.cross(Vector3.UP))
			prev = q
	var lan := c + Vector3(0, drum + 11.6, 0)
	lm.frustum("White", lan, 2.6, 2.6, 4.2, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		lm.frustum("White", lan + Vector3(cos(a), 0, sin(a)) * 2.85, 0.18, 0.15, 3.4, 8)
		lm.box("White", lan + Vector3(cos(a), 0, sin(a)) * 2.85 + Vector3(0, 3.5, 0), Vector3(0.45, 0.2, 0.45),
			Basis(), 0.0)
	lm.frustum("White", lan + Vector3(0, 3.6, 0), 3.1, 3.0, 0.6, 16)
	lm.lathe("Green", lan + Vector3(0, 4.2, 0), _dome(2.9, 3.2), 16)
	lm.lathe("Gilt", lan + Vector3(0, 7.4, 0), _ball(0.45), 8)
	var top := 62.0
	lm.box("Gilt", Vector3(0, (lan.y + 8.3 + top) * 0.5, 0), Vector3(0.3, top - lan.y - 8.3, 0.3))
	lm.box("Gilt", Vector3(0, top - 1.6, 0), Vector3(1.6, 0.3, 0.3))
	lm.commit(model)

## Hexastyle Corinthian portico: columns on a stylobate, architrave,
## frieze and cornice, the pediment with raking cornices, and three
## apostle statues (apex and both corners).
static func _portico(lm: LandmarkMesh, r: Basis, plat: float, z: float, w: float, h: float) -> void:
	var out := r * Vector3(0, 0, 1)
	var rt := r * Vector3(1, 0, 0)
	# Stylobate: a step above the terrace slab (top plat + 0.6), never
	# coplanar with it, so the column bases do not z-fight the paving.
	lm.box("White", r * Vector3(0, plat + 0.75, z + 3.0), Vector3(w + 0.8, 0.3, 6.4), r)
	for k in 6:
		var x := -w * 0.42 + w * 0.84 * float(k) / 5.0
		LandmarkDetail.column(lm, "White", r * Vector3(x, plat + 0.9, z + 3.5), 0.85, h - 2.9, "corinthian", 0)
	lm.box("White", r * Vector3(0, plat + h - 1.4, z + 3.0), Vector3(w + 0.8, 1.0, 6.0), r)
	lm.box("White", r * Vector3(0, plat + h - 0.5, z + 3.0), Vector3(w + 0.6, 0.8, 5.8), r)
	var front := r * Vector3(0, plat + h, z + 5.9)
	LandmarkDetail.cornice(lm, "White", front - rt * (w * 0.5 + 0.4), front + rt * (w * 0.5 + 0.4), out, 0.8)
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "White", r * Vector3(s * (w * 0.5 + 0.4), plat + h, z),
			r * Vector3(s * (w * 0.5 + 0.4), plat + h, z + 5.9), rt * s, 0.8, false)
	lm.gable("White", r * Vector3(0, plat + h + 0.8, z + 3.0), w + 0.8, 6.0, 4.4, r, 0.4, "White")
	# Raking cornices along the pediment's slopes.
	var apex := front + Vector3(0, 0.8 + 4.4, 0) + out * 0.25
	for sv in [-1.0, 1.0]:
		var s: float = sv
		var eave := front + rt * s * (w * 0.5 + 0.8) + Vector3(0, 0.8, 0) + out * 0.25
		lm.beam("White", eave, apex, 0.7, 0.6, out)
	for k in 3:
		var x := -w * 0.45 + w * 0.45 * float(k)
		var p := r * Vector3(x, plat + h + 0.8 + (4.4 if k == 1 else 0.0), z + 5.3)
		lm.box("White", p + Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 1.2), r)
		LandmarkKits.statue_figure(lm, "Green", p + Vector3(0, 0.6, 0), 3.2, k == 1)

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
