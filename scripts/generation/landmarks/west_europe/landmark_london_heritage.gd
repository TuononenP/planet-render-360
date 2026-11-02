class_name LandmarkLondonHeritage
extends RefCounted

## Two London churches in true metres, y = 0 at street level: St Paul's
## Cathedral and Westminster Abbey. (The Tower of London and Buckingham
## Palace are LandmarkLondonPalaces.)

## St Paul's Cathedral (111 m): Wren's cruciform Portland-stone church
## (1675-1710), nave along X with the west front at -X: the two-storey
## screen walls — coupled Corinthian pilasters below, Composite above,
## arched windows, blind upper windows and the 1718 balustrade; the
## semicircular transept porticoes under pediments; the west portico of
## twelve coupled columns below and eight above with the pediment and
## the statues of Paul, Peter and James; the two Baroque west towers; and
## the dome — peristyle of 32 columns with eight buttress niches, the
## Stone Gallery, the windowed attic, the 32-ribbed lead dome, the Golden
## Gallery, the lantern, the golden ball and the cross.
static func st_pauls(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2CCBF", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8A9195", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Cross-plan walls under flat lead roofs and the apse.
	LandmarkWestKit.blk(lm, "Stone", -4.0, 0, 0, 132.0, 30.0, 50.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 50.0, 30.0, 75.0)
	LandmarkWestKit.blk(lm, "Lead", -4.0, 30.0, 0, 131.0, 0.8, 49.0)
	LandmarkWestKit.blk(lm, "Lead", 0, 30.0, 0, 49.0, 0.8, 74.0)
	lm.gable("Lead", Vector3(-4.0, 30.8, 0), 18.0, 128.0, 6.0, rot, 0.3)
	lm.lathe("Stone", Vector3(62, 0, 0), PackedVector2Array([Vector2(13, 0), Vector2(13, 30.8)]), 20,
		1.0, 1.0, 0.0, false)
	# Screen walls: two orders of coupled pilasters, windows, cornices, balustrade.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for seg in [[-66.0, -25.0], [25.0, 62.0]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			var bays := int((x1 - x0) / 6.2)
			for k in bays:
				var x := lerpf(x0, x1, (float(k) + 0.5) / float(bays))
				LandmarkDetail.window(lm, "Stone", "Glass", Vector3(x, 8.0, sz * 25.0), n, 2.2, 5.0, true)
				LandmarkDetail.window(lm, "Stone", "Glass", Vector3(x, 21.5, sz * 25.0), n, 2.0, 4.2, false)
			for k in bays + 1:
				var x := lerpf(x0, x1, float(k) / float(bays))
				for px in [-0.75, 0.75]:
					lm.box("Stone", Vector3(x + px, 7.0, sz * 25.25), Vector3(0.8, 14.0, 0.5), Basis(), 0.0)
					lm.box("Stone", Vector3(x + px, 22.0, sz * 25.25), Vector3(0.7, 12.0, 0.5), Basis(), 0.0)
			LandmarkDetail.cornice(lm, "Stone", Vector3(x0, 14.2, sz * 25.0), Vector3(x1, 14.2, sz * 25.0), n, 1.0, false)
			LandmarkDetail.cornice(lm, "Stone", Vector3(x0, 28.8, sz * 25.0), Vector3(x1, 28.8, sz * 25.0), n, 1.2)
			LandmarkWestKit.rail(lm, "Stone", Vector3(x0, 30.0, sz * 25.6), Vector3(x1, 30.0, sz * 25.6), 1.4, 0.7)
		# Transept front: semicircular portico of six columns, half-dome, pediment.
		var f := Vector3(0, 0, sz * 37.5)
		for k in 6:
			var a := PI * float(k) / 5.0
			LandmarkDetail.column(lm, "Stone", f + Vector3(cos(a) * 6.5, 1.5, sz * sin(a) * 6.5), 0.7, 13.0,
				"corinthian", 0)
		for k in 10:
			var a0 := PI * float(k) / 10.0
			var a1 := PI * float(k + 1) / 10.0
			lm.beam("Stone", f + Vector3(cos(a0) * 6.9, 15.0, sz * sin(a0) * 6.9), f + Vector3(cos(a1) * 6.9, 15.0,
				sz * sin(a1) * 6.9), 1.6, 1.4)
			for j in 4:
				var t0 := PI * 0.5 * float(j) / 4.0
				var t1 := PI * 0.5 * float(j + 1) / 4.0
				var p0 := Vector3(cos(a0) * cos(t0), sin(t0), sz * sin(a0) * cos(t0)) * 6.8
				var p1 := Vector3(cos(a0) * cos(t1), sin(t1), sz * sin(a0) * cos(t1)) * 6.8
				var q1 := Vector3(cos(a1) * cos(t1), sin(t1), sz * sin(a1) * cos(t1)) * 6.8
				var q0 := Vector3(cos(a1) * cos(t0), sin(t0), sz * sin(a1) * cos(t0)) * 6.8
				var b := f + Vector3(0, 15.8, 0)
				lm.quad("Lead", b + p0, b + q0, b + q1, b + p1, ((p0 + q1) * 0.5).normalized())
		lm.frustum("Stone", f, 7.6, 7.6, 1.5, 20)
		for k in 3:
			LandmarkWestKit.blk(lm, "Stone", 0, 0, f.z + sz * (10.0 - float(k)), 16.0 - 2.0 * float(k), 0.5 * float(k + 1), 1.0)
		LandmarkDetail.cornice(lm, "Stone", f + Vector3(-12.5, 28.8, 0), f + Vector3(12.5, 28.8, 0), n, 1.2)
		lm.gable("Stone", f + Vector3(0, 30.0, -sz * 1.0), 25.0, 2.0, 5.5, Basis(), 0.5, "Stone")
		for x in [-12.0, 0.0, 12.0]:
			LandmarkWestKit.figure(lm, "Stone", f + Vector3(x, 30.0 + (5.5 if x == 0.0 else 0.4), sz * 0.2), 3.0)
	_st_pauls_west(lm, rot)
	_st_pauls_dome(lm, Vector3(0, 30.8, 0))
	lm.commit(model)

## West portico, steps and the two Baroque towers.
static func _st_pauls_west(lm: LandmarkMesh, rot: Basis) -> void:
	for k in 5:
		LandmarkWestKit.blk(lm, "Stone", -86.0 - 1.4 * float(4 - k), 0, 0, 2.8, 0.8 * float(k + 1), 42.0 - 2.0 * float(4 - k))
	LandmarkWestKit.blk(lm, "Stone", -78.0, 0, 0, 14.0, 4.0, 38.0)
	for pair in 6:
		var z := -15.0 + 6.0 * float(pair)
		for dz in [-0.9, 0.9]:
			LandmarkDetail.column(lm, "Stone", Vector3(-82.0, 4.0, z + dz), 0.6, 11.0, "corinthian", 0)
	LandmarkWestKit.blk(lm, "Stone", -78.0, 15.0, 0, 12.0, 2.0, 38.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-84.0, 16.4, -19.0), Vector3(-84.0, 16.4, 19.0), Vector3(-1, 0, 0), 0.9)
	for pair in 4:
		var z := -9.0 + 6.0 * float(pair)
		for dz in [-0.8, 0.8]:
			LandmarkDetail.column(lm, "Stone", Vector3(-80.0, 17.6, z + dz), 0.5, 8.4, "corinthian", 0)
	LandmarkWestKit.blk(lm, "Stone", -78.0, 26.0, 0, 12.0, 2.0, 30.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-84.0, 27.6, -15.0), Vector3(-84.0, 27.6, 15.0), Vector3(-1, 0, 0), 0.9)
	lm.gable("Stone", Vector3(-78.0, 28.0, 0), 30.0, 12.0, 7.0, rot, 0.4, "Stone")
	for k in 9:
		var z := -8.0 + 2.0 * float(k)
		LandmarkWestKit.figure(lm, "Stone", Vector3(-83.9, 28.1, z), 2.6 - absf(z) * 0.12)
	LandmarkKits.statue_figure(lm, "Stone", Vector3(-83.0, 35.0, 0), 3.4)
	for sz in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Stone", Vector3(-83.0, 28.0, sz * 14.0), 3.2)
	for sz in [-1.0, 1.0]:
		var c := Vector3(-70.0, 0, sz * 22.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 12.0, 42.0, 12.0)
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(-6.0, 28.8, -6.0), c + Vector3(-6.0, 28.8, 6.0), Vector3(-1, 0, 0), 1.2)
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(-6.0, 20.0, 0), Vector3(-1, 0, 0), 2.4, 5.0, true)
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(-6.0, 7.0, 0), Vector3(-1, 0, 0), 2.4, 5.0, true)
		# Belfry stage: four faces of coupled columns round an arched opening.
		LandmarkWestKit.blk(lm, "Stone", c.x, 30.0, c.z, 10.0, 12.0, 10.0)
		for s in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(s))
			var n: Vector3 = b * Vector3(0, 0, 1)
			LandmarkDetail.window(lm, "Stone", "Glass", c + n * 5.0 + Vector3(0, 36.0, 0), n, 2.6, 7.0, true)
			lm.disc("Gilt", c + n * 5.05 + Vector3(0, 40.4, 0), n, 1.2, 16)
			for q in [-1.0, 1.0]:
				LandmarkWestKit.shaft(lm, "Stone", c + n * 5.4 + b * Vector3(q * 4.4, 30.0, 0), 0.35, 11.0, 8)
		LandmarkWestKit.blk(lm, "Stone", c.x, 42.0, c.z, 9.0, 8.0, 9.0)
		for s in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(s) + PI * 0.25)
			lm.lathe("Stone", c + b * Vector3(0, 42.0, 6.4), LandmarkWestKit.ogee_prof(0.9, 3.0), 8)
		lm.frustum("Stone", c + Vector3(0, 50, 0), 4.4, 4.0, 6.0, 12, PI / 8.0)
		LandmarkWestKit.col_ring(lm, "Stone", c + Vector3(0, 50, 0), 4.5, 8, 0.3, 0.28, 6.0)
		lm.lathe("Lead", c + Vector3(0, 56, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(5.0, 1.5),
			Vector2(4.0, 3.5), Vector2(2.0, 6.0), Vector2(0.6, 9.0), Vector2(0.0, 11.0)]), 12)
		lm.lathe("Gilt", c + Vector3(0, 66, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.8, 0.6),
			Vector2(0.7, 1.4), Vector2(0.0, 2.2)]), 8)

## Wren's dome over the crossing (111 m to the cross tip).
static func _st_pauls_dome(lm: LandmarkMesh, d: Vector3) -> void:
	lm.frustum("Stone", d, 22.5, 22.5, 4.2, 40)
	lm.frustum("Stone", d + Vector3(0, 4.2, 0), 16.5, 16.5, 16.0, 40)
	for k in 32:
		var a := TAU * float(k) / 32.0
		var dir := Vector3(cos(a), 0, sin(a))
		if k % 4 == 2:
			# Buttress wall with a niche, every fourth intercolumniation.
			lm.box("Stone", d + dir * 18.3 + Vector3(0, 11.5, 0), Vector3(3.6, 13.0, 2.4), Basis.looking_at(dir))
			LandmarkDetail.window(lm, "Stone", "Glass", d + dir * 19.5 + Vector3(0, 10.5, 0), dir, 1.4, 4.0, true, 0.2)
		else:
			LandmarkWestKit.shaft(lm, "Stone", d + dir * 18.3 + Vector3(0, 5.0, 0), 0.55, 13.0, 10)
	lm.frustum("Stone", d + Vector3(0, 18.0, 0), 19.3, 19.3, 2.2, 40)
	for k in 40:
		var a0 := TAU * float(k) / 40.0
		var a1 := TAU * float(k + 1) / 40.0
		LandmarkWestKit.rail(lm, "Stone", d + Vector3(cos(a0) * 19.0, 20.2, sin(a0) * 19.0),
			d + Vector3(cos(a1) * 19.0, 20.2, sin(a1) * 19.0), 1.2, 0.7)
	# Attic: pilasters between windows, cornice.
	lm.frustum("Stone", d + Vector3(0, 20.2, 0), 16.5, 16.5, 6.0, 40)
	for k in 32:
		var a := TAU * float(k) / 32.0
		var dir := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", d + dir * 16.65 + Vector3(0, 23.2, 0), Vector3(0.9, 6.0, 0.4), Basis.looking_at(dir), 0.0)
		var a2 := a + PI / 32.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		lm.box("Glass", d + d2 * 16.55 + Vector3(0, 23.0, 0), Vector3(1.1, 2.4, 0.1), Basis.looking_at(d2), 0.0)
	lm.lathe("Stone", d + Vector3(0, 25.6, 0), PackedVector2Array([Vector2(16.5, 0), Vector2(17.0, 0.4),
		Vector2(17.1, 0.6)]), 40)
	# Lead dome with 32 ribs, Golden Gallery.
	var prof := LandmarkWestKit.dome_prof(16.8, 30.0, 16, 1.05)
	lm.lathe("Lead", d + Vector3(0, 26.2, 0), prof, 40)
	for k in 32:
		var dir := Vector3(cos(TAU * float(k) / 32.0), 0, sin(TAU * float(k) / 32.0))
		for j in prof.size() - 4:
			lm.beam("Lead", d + Vector3(0, 26.2, 0) + dir * (prof[j].x + 0.12) + Vector3(0, prof[j].y, 0),
				d + Vector3(0, 26.2, 0) + dir * (prof[j + 1].x + 0.12) + Vector3(0, prof[j + 1].y, 0), 0.45, 0.3)
	lm.frustum("Gilt", d + Vector3(0, 55.0, 0), 5.8, 5.6, 0.8, 24)
	for k in 16:
		var a0 := TAU * float(k) / 16.0
		var a1 := TAU * float(k + 1) / 16.0
		LandmarkWestKit.rail(lm, "Gilt", d + Vector3(cos(a0) * 5.6, 55.8, sin(a0) * 5.6),
			d + Vector3(cos(a1) * 5.6, 55.8, sin(a1) * 5.6), 1.0, 0.5)
	# Lantern: core, four porticos of columns, cupola, ball and cross.
	lm.frustum("Stone", d + Vector3(0, 56.2, 0), 4.6, 4.2, 12.0, 16)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s) + PI * 0.25)
		for q in [-1.0, 1.0]:
			LandmarkWestKit.shaft(lm, "Stone", d + b * Vector3(q * 1.2, 56.2, 5.0), 0.3, 6.5, 8)
		lm.box("Stone", d + b * Vector3(0, 63.0, 5.0), Vector3(3.4, 0.6, 1.0), b)
		LandmarkDetail.window(lm, "Stone", "Glass", d + b * Vector3(0, 59.5, 4.45), b * Vector3(0, 0, 1), 1.2, 3.4, true, 0.15)
	lm.lathe("Lead", d + Vector3(0, 68.2, 0), LandmarkWestKit.dome_prof(4.4, 3.5, 6, 1.8), 16)
	lm.lathe("Gilt", d + Vector3(0, 71.7, 0), LandmarkWestKit.ball(1.5), 12)
	LandmarkWestKit.cross(lm, "Gilt", Vector3(0, 105.0, 0), 6.0)

## Westminster Abbey (69 m): the Gothic coronation church — nave along
## X with Hawksmoor's 69 m west towers (1745) at -X: the 31 m vault
## under a lead roof, double-tiered flying buttresses with pinnacles,
## two-light aisle and clerestory windows; the north transept front
## (-Z, "Solomon's Porch") with its rose, three portals and octagonal
## turrets; the low crossing lantern; the chevet; Henry VII's Lady
## Chapel (1503-1519) with its octagonal turret-buttresses and ogee
## cupolas; the octagonal Chapter House and the cloister (south, +Z).
static func westminster_abbey(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDAF8F", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6E757A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	LandmarkWestKit.blk(lm, "Stone", -1.5, 0, 0, 127.0, 20.0, 34.0)
	LandmarkWestKit.blk(lm, "Lead", -1.5, 20.0, 0, 126.0, 0.6, 33.0)
	LandmarkWestKit.blk(lm, "Stone", -1.5, 20.0, 0, 127.0, 11.0, 17.0)
	lm.gable("Lead", Vector3(-1.5, 31.0, 0), 17.0, 127.0, 9.0, rot, 0.8, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 8.0, 0, 0, 18.0, 31.0, 62.0)
	lm.gable("Lead", Vector3(8.0, 31.0, 0), 18.0, 62.0, 9.0, Basis(), 0.8, "Stone")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		LandmarkWestKit.rail(lm, "Stone", Vector3(-63.0, 31.0, sz * 8.7), Vector3(56.0, 31.0, sz * 8.7), 1.0, 1.0)
		LandmarkWestKit.rail(lm, "Stone", Vector3(-63.0, 20.6, sz * 17.2), Vector3(56.0, 20.6, sz * 17.2), 0.9, 1.0)
		for k in 14:
			var x := -60.0 + 8.6 * float(k)
			if absf(x + 4.3 - 8.0) > 9.0 and x + 4.3 < 56.0:
				LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x + 4.3, 5.0, sz * 17.0), n, 3.0, 10.5, true)
				LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x + 4.3, 22.0, sz * 8.5), n, 3.0, 8.0, true)
			lm.box("Stone", Vector3(x, 12.0, sz * 17.8), Vector3(1.6, 24.0, 1.6))
			LandmarkWestKit.pinnacle(lm, "Stone", Vector3(x, 24.0, sz * 17.8), 0.8, 5.5)
			LandmarkWestKit.flyer(lm, "Stone", Vector3(x, 22.5, sz * 17.2), Vector3(x, 28.5, sz * 8.6), 0.9)
			LandmarkWestKit.flyer(lm, "Stone", Vector3(x, 17.0, sz * 17.2), Vector3(x, 22.0, sz * 8.6), 0.7, 4)
		# Transept fronts: rose, lancets, portals, octagonal turrets.
		var f := Vector3(8.0, 0, sz * 31.0)
		LandmarkWestKit.rose(lm, "Stone", "Glass", f + Vector3(0, 25.0, sz * 0.1), n, 4.6, 16)
		for k in 5:
			LandmarkWestKit.lancet(lm, "Stone", "Glass", f + Vector3(-5.0 + 2.5 * float(k), 13.5, 0), n, 1.6, 5.0, false)
		for px in [-5.0, 0.0, 5.0]:
			LandmarkWestKit.portal(lm, "Stone", "Lead", f + Vector3(px, 0, 0), n, 2.6 if px != 0.0 else 3.4,
				8.0 if px != 0.0 else 10.0, 3, true)
		for sx in [-1.0, 1.0]:
			var tp := f + Vector3(sx * 9.0, 0, sz * 0.5)
			lm.frustum("Stone", tp, 2.2, 2.0, 38.0, 8, PI / 8.0)
			LandmarkWestKit.pinnacle(lm, "Stone", tp + Vector3(0, 38.0, 0), 1.4, 9.0)
	# Crossing lantern (Wren and Hawksmoor's stump).
	LandmarkWestKit.blk(lm, "Stone", 8.0, 38.0, 0, 9.0, 8.0, 9.0)
	LandmarkWestKit.hip(lm, "Lead", Vector3(8.0, 46.0, 0), 10.0, 10.0, 5.0, 0.0)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(8.0 + q.x * 4.3, 46.0, q.y * 4.3), 0.5, 4.0)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s))
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(8.0, 39.5, 0) + b * Vector3(0, 0, 4.5), b * Vector3(0, 0, 1),
			1.6, 5.0, false)
	# Chevet: apse with radiating flyers.
	lm.lathe("Stone", Vector3(56, 0, 0), PackedVector2Array([Vector2(13, 0), Vector2(13, 20)]), 16,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(56, 20, 0), PackedVector2Array([Vector2(14, 0), Vector2(8.0, 5.0),
		Vector2(0.0, 16.0)]), 16, 1.0, 1.0, 0.0, false)
	for k in 7:
		var a := -PI * 0.5 + PI * float(k) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(56, 20.0, 0) + d * 13.5, 0.8, 5.0)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(56, 5.0, 0) + d * 13.05, d, 2.6, 10.0, true)
	_henry_vii(lm)
	_abbey_west(lm, rot)
	# Chapter House (octagon, 1250s) and the cloister garth to the south.
	var ch := Vector3(40.0, 0, 34.0)
	lm.frustum("Stone", ch, 10.0, 10.0, 18.0, 8, PI / 8.0)
	lm.spire("Lead", ch + Vector3(0, 18, 0), 9.6, 9.0, 0.0, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.buttress(lm, "Stone", ch + d * 9.2, d, 1.4, 6.0, 15.0, 2)
		LandmarkWestKit.pinnacle(lm, "Stone", ch + d * 12.5 + Vector3(0, 15.0, 0), 0.6, 4.0)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", ch + Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * 9.3
			+ Vector3(0, 4.0, 0), Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)), 4.0, 12.0, true)
	for e in [[Vector3(-40.0, 0, 21.0), Vector3(-2.0, 0, 21.0)], [Vector3(-40.0, 0, 55.0), Vector3(-2.0, 0, 55.0)],
			[Vector3(-40.0, 0, 21.0), Vector3(-40.0, 0, 55.0)], [Vector3(-2.0, 0, 21.0), Vector3(-2.0, 0, 55.0)]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var mid := (a + b) * 0.5
		var along := (b - a).normalized()
		var inward := (Vector3(-21.0, 0, 38.0) - mid).normalized()
		inward = (inward - along * inward.dot(along)).normalized()
		lm.box("Stone", mid + Vector3(0, 3.5, 0), Vector3(6.0, 7.0, a.distance_to(b) + 6.0), Basis.looking_at(along))
		lm.gable("Lead", mid + Vector3(0, 7.0, 0), 6.0, a.distance_to(b) + 6.0, 2.0, Basis.looking_at(along), 0.4, "Stone")
		var cnt := int(a.distance_to(b) / 3.8)
		for k in cnt:
			var p := a.lerp(b, (float(k) + 0.5) / float(cnt)) + inward * 3.0
			LandmarkWestKit.lancet(lm, "Stone", "Glass", p + Vector3(0, 0.6, 0), inward, 2.4, 4.8, true, 0.25)
	lm.commit(model)

## Henry VII's Lady Chapel: clerestory with flyers, bay windows,
## octagonal turret-buttresses with ogee cupolas.
static func _henry_vii(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "Stone", 76.0, 0, 0, 24.0, 15.0, 26.0)
	LandmarkWestKit.blk(lm, "Stone", 76.0, 15.0, 0, 24.0, 9.0, 16.0)
	lm.gable("Lead", Vector3(76.0, 24.0, 0), 16.0, 24.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	lm.frustum("Stone", Vector3(88.0, 0, 0), 8.0, 8.0, 24.0, 8, PI / 8.0)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 5:
			var x := 66.0 + 5.0 * float(k)
			var tp := Vector3(x - 2.5, 0, sz * 13.6)
			lm.frustum("Stone", tp, 1.3, 1.2, 25.0, 8, PI / 8.0)
			lm.lathe("Lead", tp + Vector3(0, 25.0, 0), LandmarkWestKit.ogee_prof(1.5, 3.2), 8)
			lm.lathe("Gilt", tp + Vector3(0, 28.2, 0), LandmarkWestKit.ball(0.25), 6)
			LandmarkWestKit.flyer(lm, "Stone", tp + Vector3(0, 21.0, -sz * 1.0), Vector3(x - 2.5, 23.0, sz * 8.1), 0.6, 4)
			if k < 4:
				# Canted bay window between the turrets.
				var bc := Vector3(x, 1.5, sz * 13.0)
				lm.box("Glass", bc + Vector3(0, 6.0, sz * 0.9), Vector3(3.0, 11.0, 0.1), Basis(), 0.0)
				for e in [-1.0, 1.0]:
					lm.box("Glass", bc + Vector3(e * 1.9, 6.0, sz * 0.45), Vector3(0.1, 11.0, 1.2), Basis(Vector3.UP, e * sz * 0.6), 0.0)
				for m in 4:
					lm.box("Stone", bc + Vector3(-1.5 + 1.0 * float(m), 6.0, sz * 0.95), Vector3(0.15, 11.0, 0.15), Basis(), 0.0)
				for t in 3:
					lm.box("Stone", bc + Vector3(0, 2.0 + 4.0 * float(t), sz * 0.95), Vector3(3.2, 0.15, 0.15), Basis(), 0.0)
				LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x, 16.0, sz * 8.0), n, 3.0, 6.5, true)
		LandmarkWestKit.rail(lm, "Stone", Vector3(64.0, 24.0, sz * 8.2), Vector3(88.0, 24.0, sz * 8.2), 1.0, 0.8)

## West front: towers with belfries, clock, pinnacles; the great west
## window and the west door.
static func _abbey_west(lm: LandmarkMesh, rot: Basis) -> void:
	var w := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Stone", -71.5, 0, 0, 13.0, 31.0, 11.0)
	lm.gable("Stone", Vector3(-71.5, 31.0, 0), 11.0, 13.0, 9.0, rot, 0.0, "Stone")
	LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(-78.0, 13.0, 0), w, 6.0, 16.0, true, 0.5)
	LandmarkWestKit.portal(lm, "Stone", "Lead", Vector3(-78.0, 0, 0), w, 3.8, 9.5, 4, true)
	for sz in [-1.0, 1.0]:
		var c := Vector3(-71.5, 0, sz * 11.25)
		LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 13.0, 60.0, 11.5)
		LandmarkWestKit.blk(lm, "Stone", c.x, 60.0, c.z, 11.0, 6.0, 10.0)
		LandmarkWestKit.blk(lm, "Stone", c.x, 66.0, c.z, 12.0, 0.6, 11.0)
		for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
			LandmarkWestKit.pinnacle(lm, "Stone", c + Vector3(q.x * 5.2, 66.6, q.y * 4.6), 0.7, 2.4)
			# Octagonal corner buttress-turrets up the tower.
			lm.frustum("Stone", c + Vector3(q.x * 6.6, 0, q.y * 5.9), 1.1, 1.0, 60.0, 8, PI / 8.0)
		for s in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(s))
			var off: float = 5.75 if s % 2 == 0 else 6.5
			var n: Vector3 = r * Vector3(0, 0, 1)
			LandmarkWestKit.lancet(lm, "Stone", "Glass", c + n * off + Vector3(0, 33.0, 0), n, 2.4, 14.0, true)
			LandmarkWestKit.lancet(lm, "Stone", "Glass", c + n * (off - 0.7) + Vector3(0, 60.8, 0), n, 2.2, 4.4, false)
			LandmarkWestKit.rail(lm, "Stone", c + Vector3(0, 66.6, 0) + r * Vector3(-5.5, 0, off - 0.3),
				c + Vector3(0, 66.6, 0) + r * Vector3(5.5, 0, off - 0.3), 1.2, 0.7)
		lm.disc("Gilt", c + Vector3(-6.55, 50.0, 0), w, 1.6, 20)
		LandmarkWestKit.figure(lm, "Stone", c + Vector3(-6.8, 20.0, 0), 2.6)
