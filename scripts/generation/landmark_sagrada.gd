class_name LandmarkSagrada
extends RefCounted

## Sagrada Família in true metres, as built in 2026: the Latin-cross
## basilica (five-aisled nave 90 m long and 45 m wide toward the
## unfinished Glory façade, 60 m transept, apse to the NW) with its
## parabolic windows, buttress pinnacles crowned by mosaic fruit
## baskets and the stepped nave roof with its lanterns; the four
## Nativity bell towers (NE, 98–107 m) and four Passion towers (SW,
## 107–112 m) — hollow parabolic shafts ribbed and pierced by
## spiralling louvres, the Hosanna band, Venetian-mosaic mitre
## pinnacles with their white-balled crosses; the four Evangelist
## towers (135 m), the Tower of the Virgin Mary with its star (138 m)
## and the Tower of Jesus Christ with its four-armed cross (172.5 m,
## topped out 2026) over the crossing. The Nativity front has its three
## portals and the green Tree of Life cypress with white doves; the
## Passion portico its six inclined bone columns, the pediment of 18
## bone columns and the gilt Risen Christ on the bridge between the
## central towers. Local frame: +X = Nativity (NE), -Z = apse (NW),
## +Z = Glory (SE); turned 45° on build.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#A99A82", 4.0))
	lm.use("NewStone", LandmarkMaterials.pbr("limestone", "#CFC6B6", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#8E8170", 3.0))
	lm.use("Openings", LandmarkMaterials.pbr("stone", "#2E2924", 3.0))
	lm.use("Mosaic", LandmarkMaterials.pbr("render", "#B8432F", 1.5, 0.35))
	lm.use("MosaicGold", LandmarkMaterials.gold())
	lm.use("Crown", LandmarkMaterials.lit("#F4F1E8", 0.25))
	lm.use("Cypress", LandmarkMaterials.pbr("render", "#4F7A4A", 1.5, 0.4))
	_basilica(lm)
	_nativity(lm)
	_passion(lm)
	var nativity := [98.0, 107.0, 107.0, 98.0]
	var passion := [107.0, 112.0, 112.0, 107.0]
	var zs := [-22.0, -9.5, 9.5, 22.0]
	for k in 4:
		var z: float = zs[k]
		_bell_tower(lm, Vector3(35.0, 0, z), nativity[k], "Stone")
		_bell_tower(lm, Vector3(-35.0, 0, z), passion[k], "NewStone")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_great_tower(lm, Vector3(float(sx) * 14.0, 0, float(sz) * 14.0), 135.0, 6.2, "evangelist")
	_great_tower(lm, Vector3(0, 0, -32.0), 138.0, 6.8, "star")
	_great_tower(lm, Vector3(0, 0, 0), 172.5, 9.5, "cross")
	lm.commit(model)
	model.rotation.y = deg_to_rad(45.0)

## Five-aisle nave toward the Glory end (+Z), transept to the façades,
## the apse ring of chapels, stepped roofs with lanterns, parabolic
## windows, and buttress pinnacles with their mosaic fruit.
static func _basilica(lm: LandmarkMesh) -> void:
	lm.box("NewStone", Vector3(0, 22.0, 32.0), Vector3(45.0, 44.0, 60.0))
	# Outer aisles: a lower stage along both flanks.
	for sx in [-1.0, 1.0]:
		lm.box("NewStone", Vector3(float(sx) * 20.0, 15.0, 36.0), Vector3(5.0, 30.0, 52.0))
	# Glory façade (under construction): five portals, the rose and the
	# great stair platform.
	lm.box("NewStone", Vector3(0, 1.5, 66.0), Vector3(50.0, 3.0, 8.0))
	for k in 5:
		LandmarkCoreAGothic.lancet(lm, "NewStone", "Openings", Vector3(-16.0 + float(k) * 8.0, 3.0, 62.0),
			Vector3.BACK, 4.6, 16.0, 0.8, 1, 0.75, false, 0.8)
	lm.disc("Openings", Vector3(0, 31.0, 62.1), Vector3.BACK, 6.0, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.beam("NewStone", Vector3(0, 31.0, 62.3), Vector3(cos(a) * 6.0, 31.0 + sin(a) * 6.0, 62.3), 0.4, 0.4)
	# Nave roof: steep ridge with the stepped lanterns along it.
	lm.gable("Roof", Vector3(0, 44.0, 32.0), 28.0, 60.0, 14.0)
	for k in 5:
		var z := 10.0 + float(k) * 11.0
		var p := Vector3(0, 44.0 + 14.0 * 0.5, z)
		lm.lathe("Roof", p, PackedVector2Array([Vector2(3.4, 0), Vector2(2.4, 5.0), Vector2(1.6, 6.5),
			Vector2(1.6, 9.0), Vector2(0.6, 12.0), Vector2(0.0, 13.5)]), 12)
		lm.lathe("Crown", p + Vector3(0, 13.0, 0), _ball(0.7), 8)
	lm.box("Stone", Vector3(0, 22.0, 0), Vector3(66.0, 44.0, 30.0))
	lm.gable("Roof", Vector3(0, 44.0, 0), 28.0, 66.0, 14.0, Basis(Vector3.UP, PI * 0.5))
	# Apse: polygonal ring of chapels with pinnacles.
	lm.lathe("Stone", Vector3(0, 0, -24.0), PackedVector2Array([Vector2(22.0, 0),
		Vector2(22.0, 30.0), Vector2(16.0, 46.0), Vector2(6.0, 56.0)]), 14, 1.0, 1.0, 0.0, false)
	for k in 7:
		var a := PI + PI * float(k) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := Vector3(0, 0, -24.0) + d * 23.0
		lm.frustum("Stone", p, 2.4, 2.0, 30.0, 12)
		lm.lathe("Stone", p + Vector3(0, 30.0, 0), PackedVector2Array([Vector2(2.2, 0), Vector2(1.6, 3.0),
			Vector2(1.8, 4.5), Vector2(0.9, 7.5), Vector2(0.0, 10.0)]), 12)
		lm.lathe("Crown", p + Vector3(0, 9.6, 0), _ball(0.5), 8)
		if k < 6:
			var am := PI + PI * (float(k) + 0.5) / 6.0
			var dm := Vector3(cos(am), 0, sin(am))
			LandmarkCoreAGothic.lancet(lm, "Stone", "Openings", Vector3(0, 0, -24.0) + dm * 21.6 + Vector3(0, 8.0, 0),
				dm, 3.4, 16.0, 0.5, 2, 0.7)
	# Nave flanks: tall parabolic two-light windows over aisle windows,
	# buttress pinnacles crowned by mosaic fruit baskets.
	for sx in [-1.0, 1.0]:
		var out := Vector3(float(sx), 0, 0)
		for k in 6:
			var z := 12.0 + float(k) * 8.5
			LandmarkCoreAGothic.lancet(lm, "NewStone", "Openings", Vector3(float(sx) * 22.5, 31.0, z), out, 4.2,
				12.0, 0.6, 2, 0.7)
			LandmarkCoreAGothic.lancet(lm, "NewStone", "Openings", Vector3(float(sx) * 22.5, 6.0, z), out, 3.4,
				18.0, 0.6, 2, 0.7)
			var bp := Vector3(float(sx) * 23.4, 0, z + 4.25)
			lm.frustum("Stone", bp, 1.4, 1.2, 46.0, 10)
			_fruit(lm, bp + Vector3(0, 46.0, 0), 1.6)

## Mosaic fruit basket on a buttress: a stem, a ring of coloured fruit
## round a central cluster, a white crowning ball.
static func _fruit(lm: LandmarkMesh, p: Vector3, s: float) -> void:
	lm.lathe("Stone", p, PackedVector2Array([Vector2(s * 0.8, 0), Vector2(s * 0.5, s * 1.2),
		Vector2(s * 1.2, s * 2.2), Vector2(s * 1.3, s * 2.6)]), 10)
	for i in 6:
		var a := TAU * float(i) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.lathe("Mosaic" if i % 2 == 0 else "MosaicGold", p + d * s * 0.85 + Vector3(0, s * 2.4, 0), _ball(s * 0.55), 8)
	lm.lathe("Mosaic", p + Vector3(0, s * 2.6, 0), _ball(s * 0.8), 10)
	lm.lathe("Crown", p + Vector3(0, s * 4.1, 0), _ball(s * 0.4), 8)

## Nativity façade (Gaudí's own, 1894–1930): the transept front between
## the four towers — three deep portals (Hope, Charity, Faith), each
## under a sculpted gable that drips with stone, and the green Tree of
## Life cypress crowning the central Charity portal, with white doves.
static func _nativity(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(34.0, 20.0, 0), Vector3(6.0, 40.0, 40.0))
	for k in 3:
		var z := -12.0 + float(k) * 12.0
		var wide := 7.0 if k == 1 else 5.6
		for o in 3:
			LandmarkCoreAGothic.lancet(lm, "Stone", "Openings", Vector3(37.0 + 0.6 * float(o), 1.0, z), Vector3.RIGHT,
				wide - 1.2 * float(o), 16.0 - 1.6 * float(o), 0.6, 1, 0.75, o == 2, 0.6)
		var gh := 26.0 if k == 1 else 18.0
		lm.spire("Stone", Vector3(38.0, 22.0, z), wide * 0.6, gh, 0.4, 8)
		# Dripping sculpture: stalactite clusters hung under the gable.
		for i in 9:
			var a := TAU * float(i) / 9.0
			var dp := Vector3(39.2, 22.0, z) + Vector3(0, 0, cos(a) * wide * 0.45)
			lm.frustum("Stone", dp - Vector3(0, 2.4 + absf(sin(a * 2.0)) * 1.6, 0), 0.05, 0.35,
				2.4 + absf(sin(a * 2.0)) * 1.6, 6)
		for i in 7:
			var y := 24.0 + float(i) * gh * 0.11
			var hw := wide * 0.6 * (1.0 - (y - 22.0) / gh)
			for sv in [-1.0, 1.0]:
				lm.lathe("Stone", Vector3(38.3, y, z + float(sv) * hw * 0.9), _ball(0.55), 6)
	# Tree of Life: the green cypress over the Charity portal, with
	# the white doves perched on it and the cross and Tau on top.
	var t := Vector3(38.5, 46.0, 0)
	var prof := PackedVector2Array()
	for i in 13:
		var f := float(i) / 12.0
		prof.append(Vector2(lerpf(3.4, 0.2, pow(f, 1.2)) * (1.0 + 0.12 * sin(f * 40.0)), f * 20.0))
	lm.lathe("Cypress", t, prof, 14)
	for i in 14:
		var a := float(i) * 2.4
		var y := 2.0 + float(i) * 1.2
		var r := lerpf(3.4, 0.4, y / 20.0) + 0.3
		lm.lathe("Crown", t + Vector3(cos(a) * r, y, sin(a) * r), _ball(0.35), 6)
	lm.box("Crown", t + Vector3(0, 21.5, 0), Vector3(0.4, 3.0, 0.4))
	lm.box("Crown", t + Vector3(0, 22.2, 0), Vector3(1.6, 0.4, 0.4))
	lm.lathe("Stone", Vector3(37.0, 40.0, 0), PackedVector2Array([Vector2(4.5, 0), Vector2(5.0, 3.0),
		Vector2(3.8, 6.0)]), 12)

## Passion façade (Subirachs, 1987–2018): austere, bone-like — six
## inclined columns with knotted joints carrying the porch, the
## pediment of 18 slim bone columns under a cornice, and the bridge
## between the central towers with the gilt Risen Christ.
static func _passion(lm: LandmarkMesh) -> void:
	lm.box("NewStone", Vector3(-34.0, 22.0, 0), Vector3(6.0, 44.0, 40.0))
	for k in 3:
		LandmarkCoreAGothic.lancet(lm, "NewStone", "Openings", Vector3(-37.0, 1.0, -12.0 + float(k) * 12.0),
			Vector3.LEFT, 5.0, 14.0, 0.6, 1, 0.6, false, 0.5)
	# Porch roof slab.
	lm.box("NewStone", Vector3(-46.0, 25.5, 0), Vector3(6.0, 3.0, 46.0))
	for k in 6:
		var z := -17.5 + float(k) * 7.0
		var foot := Vector3(-49.0, 1.0, z)
		var head := Vector3(-44.5, 24.0, z * 0.8)
		var knot := foot.lerp(head, 0.42)
		lm.box("NewStone", Vector3(-49.0, 0.5, z), Vector3(4.0, 1.0, 4.0))
		lm.beam("NewStone", foot, knot, 3.4, 3.4)
		lm.lathe("NewStone", knot - Vector3(0, 1.2, 0), _ball(1.3), 10, 1.0, 1.0)
		lm.beam("NewStone", knot, head, 2.6, 2.6)
		lm.box("NewStone", head + Vector3(0, 0.6, 0), Vector3(4.0, 1.2, 4.0))
	# Pediment: 18 inclined bone columns under the crowning cornice.
	for k in 18:
		var z := -21.0 + float(k) * (42.0 / 17.0)
		var lean := 0.25 * sin(float(k) * 0.9)
		lm.beam("NewStone", Vector3(-46.5, 27.0, z), Vector3(-46.0, 37.0, z + lean), 0.9, 0.9)
		lm.lathe("NewStone", Vector3(-46.25, 31.4, z + lean * 0.5), _ball(0.7), 6)
	lm.box("NewStone", Vector3(-46.0, 38.0, 0), Vector3(4.0, 2.0, 46.0))
	lm.box("NewStone", Vector3(-43.0, 31.0, 0), Vector3(2.0, 18.0, 12.0))
	# Bridge between the two central towers with the Risen Christ.
	lm.box("NewStone", Vector3(-35.0, 66.0, 0), Vector3(3.0, 2.0, 15.0))
	LandmarkKits.statue_figure(lm, "MosaicGold", Vector3(-35.0, 67.0, 0), 5.0, true)

## A façade bell tower: round, hollow shaft with vertical ribs and
## spiralling louvre slots, a parabolic taper with the Hosanna band,
## and the mosaic mitre pinnacle.
static func _bell_tower(lm: LandmarkMesh, base: Vector3, h: float, key: String) -> void:
	var r := 3.7
	var shaft := h * 0.62
	var prof := PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r, shaft * 0.4),
		Vector2(r * 0.9, shaft), Vector2(r * 0.66, shaft + h * 0.08),
		Vector2(r * 0.36, shaft + h * 0.14), Vector2(r * 0.14, shaft + h * 0.18)])
	lm.lathe(key, base, prof, 20)
	# Six ribs up the shaft and its taper.
	for i in 6:
		var a := TAU * float(i) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 1:
			lm.beam(key, base + d * (prof[j].x + 0.15) + Vector3(0, prof[j].y, 0),
				base + d * (prof[j + 1].x + 0.15) + Vector3(0, prof[j + 1].y, 0), 0.45, 0.35, d.cross(Vector3.UP))
	# Spiralling louvre slots (the "hollow" read of the towers).
	var n := int(shaft / 1.6)
	for k in n:
		var y := 26.0 + float(k) * (shaft - 28.0) / float(maxi(n, 1))
		if y > shaft - 2.0:
			continue
		for j in 2:
			var a := float(k) * 0.9 + PI * float(j)
			var d := Vector3(cos(a), 0, sin(a))
			var rr := lerpf(r, r * 0.9, clampf((y - shaft * 0.4) / (shaft * 0.6), 0.0, 1.0))
			lm.box("Openings", base + d * (rr - 0.05) + Vector3(0, y, 0), Vector3(1.6, 0.9, 0.35),
				Basis(Vector3.UP, -a + PI * 0.5) * Basis(Vector3.RIGHT, 0.4), 0.0)
	# Hosanna band where the shaft turns into the parabolic spire.
	lm.frustum("Crown", base + Vector3(0, shaft + h * 0.03, 0), r * 0.83, r * 0.79, 1.4, 20)
	# Mitre pinnacle: stem, gold boss, red-and-gold cross of mitres,
	# white balls crowning each arm.
	var p := base + Vector3(0, shaft + h * 0.18, 0)
	var top := h - (shaft + h * 0.18)
	lm.frustum("MosaicGold", p, 0.9, 0.7, top * 0.25, 8)
	lm.lathe("Mosaic", p + Vector3(0, top * 0.25, 0), PackedVector2Array([Vector2(0.6, 0),
		Vector2(2.2, top * 0.22), Vector2(2.4, top * 0.45), Vector2(0.4, top * 0.75)]), 8, 1.0, 1.0, 0.0, false)
	for s in 4:
		var d := Vector3(1, 0, 0).rotated(Vector3.UP, PI * 0.5 * float(s))
		var arm := p + Vector3(0, top * 0.55, 0) + d * 2.6
		lm.beam("MosaicGold", p + Vector3(0, top * 0.5, 0), arm, 0.9, 0.9)
		lm.lathe("Crown", arm, _ball(0.7), 8)
		for b in 3:
			var bd := d.rotated(Vector3.UP, (float(b) - 1.0) * 0.5)
			lm.lathe("Crown", p + Vector3(0, top * 0.38, 0) + bd * 2.2, _ball(0.3), 6)
	lm.lathe("Crown", p + Vector3(0, top * 0.8, 0), _ball(1.0), 10)

## Evangelist / Mary / Jesus towers: square-to-round stepped bases,
## long ribbed parabolic shafts with slatted window strips, then the
## crown of each.
static func _great_tower(lm: LandmarkMesh, base: Vector3, h: float, r: float, kind: String) -> void:
	var shaft := h * (0.80 if kind == "cross" else 0.86)
	lm.lathe("NewStone", base, PackedVector2Array([Vector2(r * 1.25, 0),
		Vector2(r * 1.2, 50.0), Vector2(r, 60.0), Vector2(r * 0.92, shaft * 0.7),
		Vector2(r * 0.62, shaft * 0.9), Vector2(r * 0.25, shaft)]), 16, 1.0, 1.0, 0.0, false)
	# Vertical ribs up the shaft, slatted window strips between them.
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := base + d * r * 1.22 + Vector3(0, 50.0, 0)
		var p1 := base + d * r * 0.98 + Vector3(0, 60.0, 0)
		var p2 := base + d * r * 0.62 + Vector3(0, shaft * 0.9, 0)
		lm.beam("NewStone", p0, p1, 0.7, 0.9, d.cross(Vector3.UP))
		lm.beam("NewStone", p1, p2, 0.7, 0.9, d.cross(Vector3.UP))
		var aw := a + TAU / 32.0
		var dw := Vector3(cos(aw), 0, sin(aw))
		for j in 6:
			var y := 64.0 + float(j) * (shaft * 0.75 - 64.0) / 6.0
			var rr := lerpf(r, r * 0.92, (y - 60.0) / (shaft * 0.7 - 60.0)) - 0.05
			lm.box("Openings", base + dw * rr + Vector3(0, y + 1.5, 0), Vector3(0.9, 3.0, 0.3),
				Basis(Vector3.UP, -aw + PI * 0.5), 0.0)
	var top := base + Vector3(0, shaft, 0)
	match kind:
		"cross":
			# The shaft's glazed upper body, then the four-armed cross of
			# white glazed tile and glass, 17 m tall.
			for k in 8:
				var a := TAU * float(k) / 8.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.beam("Crown", base + d * r * 0.62 + Vector3(0, shaft * 0.9, 0), top + d * 0.6, 0.5, 0.4)
			var c := top + Vector3(0, h - shaft - 17.0, 0)
			lm.frustum("Crown", top, 2.4, 1.8, h - shaft - 17.0, 12)
			lm.box("Crown", c + Vector3(0, 8.5, 0), Vector3(2.6, 17.0, 2.6))
			for s in 2:
				lm.box("Crown", c + Vector3(0, 11.5, 0), Vector3(13.6, 2.6, 2.6),
					Basis(Vector3.UP, PI * 0.5 * float(s)))
			for s in 4:
				var d := Vector3(1, 0, 0).rotated(Vector3.UP, PI * 0.5 * float(s))
				lm.box("MosaicGold", c + Vector3(0, 11.5, 0) + d * 6.85, Vector3(0.3, 2.9, 2.9),
					Basis(Vector3.UP, PI * 0.5 * float(s)), 0.0)
		"star":
			lm.frustum("NewStone", top, 1.8, 1.4, h - shaft - 7.0, 12)
			var c := base + Vector3(0, h - 3.5, 0)
			for k in 12:
				var d := Vector3.UP.rotated(Vector3.BACK, TAU * float(k) / 12.0)
				lm.beam("Crown", c, c + d * 3.4, 0.9, 0.9)
				# The star is three-dimensional: each point also turned 90°.
				lm.beam("Crown", c, c + d.rotated(Vector3.UP, PI * 0.5) * 3.0, 0.6, 0.6)
			lm.lathe("Crown", c - Vector3(0, 1.2, 0), _ball(1.2), 12)
		_:
			lm.frustum("Crown", top, 2.0, 1.6, h - shaft - 5.0, 12)
			# The Evangelist's symbol on its sphere: a winged form drawn
			# as the sphere with two swept wings and a head.
			var sp := base + Vector3(0, h - 5.0, 0)
			lm.lathe("Crown", sp, _ball(2.5), 12)
			for sv in [-1.0, 1.0]:
				lm.beam("MosaicGold", sp + Vector3(0, 2.6, 0), sp + Vector3(float(sv) * 2.4, 4.2, 0), 1.2, 0.3)
			lm.lathe("MosaicGold", sp + Vector3(0, 3.9, 0.4), _ball(0.55), 8)

static func _ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr
