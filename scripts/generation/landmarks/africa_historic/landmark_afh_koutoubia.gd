class_name LandmarkAfhKoutoubia
extends RefCounted

## The Koutoubia Mosque of Marrakesh (second mosque, 1158) in true
## metres. Qibla (mihrab) wall to the south (+Z), origin at the centre of
## the 90 x 60 m mosque: 17 naves of about 5.3 m under parallel green-tile
## gables (the central nave and the qibla aisle raised into a T), the
## 45 x 23 m courtyard in the north between the outer naves, four gates
## on each side wall, stepped merlons on every wall, and the 77 m
## sandstone minaret at the north-east corner.

const HX := 45.0
const ZN := -30.0
const ZS := 30.0
const NAVE := 90.0 / 17.0
const COURT_HX := 22.5
const COURT_ZS := -7.0
const EAVE := 9.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sandstone", LandmarkMaterials.pbr("stone", "#C58B69", 4.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D8B48C", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#2E7A55", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.glass("#2A1E16"))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#D9C6A4", 5.0))
	_hall(lm)
	_roofs(lm)
	_court(lm)
	_gates(lm)
	_minaret(lm, Vector3(30, 0, -26))
	lm.commit(model)

## Walls of the prayer hall and the side naves flanking the court.
static func _hall(lm: LandmarkMesh) -> void:
	lm.box("Court", Vector3(0, -0.4, 0), Vector3(HX * 2.0 + 12.0, 0.8, ZS - ZN + 12.0))
	# Prayer hall across the south, side wings along the court.
	lm.box("Plaster", Vector3(0, EAVE * 0.5, (COURT_ZS + ZS) * 0.5 + 1.2),
		Vector3(HX * 2.0, EAVE, ZS - COURT_ZS - 2.4))
	for s in [-1.0, 1.0]:
		var wx: float = s * (HX + COURT_HX + 1.4) * 0.5
		lm.box("Plaster", Vector3(wx, EAVE * 0.5, (ZN + COURT_ZS + 2.4) * 0.5),
			Vector3(HX - COURT_HX - 1.4, EAVE, COURT_ZS + 2.4 - ZN))
	# North wall of the court, low with a gate in the middle.
	for s in [-1.0, 1.0]:
		lm.box("Plaster", Vector3(s * 12.75, 3.75, ZN + 0.6), Vector3(19.5, 7.5, 1.2))
	lm.box("Plaster", Vector3(0, 6.6, ZN + 0.6), Vector3(6.0, 1.8, 1.2))
	LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", Vector3(0, 0, ZN), Vector3(0, 0, -1), 3.4, 5.6,
		"horseshoe", 0.45, 0.3, false)
	# Mihrab bay projecting from the qibla wall under its own small roof.
	lm.box("Plaster", Vector3(0, 4.5, ZS + 1.6), Vector3(7.0, 9.0, 3.2))
	lm.spire("Tile", Vector3(0, 9.0, ZS + 1.6), 3.9, 2.0, 0.0)
	# Buttress strips on the long outer walls, one per nave line.
	for i in 18:
		var x := -HX + NAVE * float(i)
		lm.box("Sandstone", Vector3(x, EAVE * 0.5, ZS + 0.4), Vector3(1.1, EAVE, 0.8))
	for j in 12:
		var z := ZN + 5.0 * float(j) + 2.5
		for s in [-1.0, 1.0]:
			lm.box("Sandstone", Vector3(s * (HX + 0.4), EAVE * 0.5, z), Vector3(0.8, EAVE, 1.1))
	# High windows: polylobed on the qibla wall, horseshoe on the sides.
	for i in 17:
		var x := -HX + NAVE * (float(i) + 0.5)
		if absf(x) < 4.0:
			continue
		LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", Vector3(x, 5.6, ZS), Vector3(0, 0, 1), 1.2, 2.4,
			"lobed", 0.22, 0.18, true, 5)
	# Stepped merlons on every wall top.
	var tops := [[-HX, ZS, HX, ZS], [-HX, ZN, -HX, ZS], [HX, ZN, HX, ZS],
		[-HX, ZN, -COURT_HX - 1.4, ZN], [COURT_HX + 1.4, ZN, HX, ZN]]
	for t in tops:
		LandmarkAfhDetail.merlon_row(lm, "Plaster", Vector3(t[0], EAVE, t[1]), Vector3(t[2], EAVE, t[3]),
			0.9, 1.3, 0.5, 1.7)
	LandmarkAfhDetail.merlon_row(lm, "Plaster", Vector3(-COURT_HX - 1.4, 7.5, ZN + 0.6),
		Vector3(COURT_HX + 1.4, 7.5, ZN + 0.6), 0.8, 1.1, 0.45, 1.6)

## Seventeen parallel gables running north-south over the naves (longer
## over the side naves), the central nave raised, and the qibla aisle's
## transverse gable across the south.
static func _roofs(lm: LandmarkMesh) -> void:
	for i in 17:
		var x := -HX + NAVE * (float(i) + 0.5)
		var z0 := COURT_ZS if absf(x) < COURT_HX else ZN
		var z1 := ZS - 5.4
		var eave := EAVE + (0.9 if i == 8 else 0.0)
		var rise := 2.6 if i == 8 else 2.1
		var zc := (z0 + z1) * 0.5
		lm.gable("Tile", Vector3(x, eave, zc), NAVE - 0.3, z1 - z0, rise, Basis(), 0.15, "Plaster")
		lm.beam("Tile", Vector3(x, eave + rise + 0.08, z0 - 0.1), Vector3(x, eave + rise + 0.08, z1 + 0.1),
			0.32, 0.22, Vector3.RIGHT)
	# Qibla aisle along the mihrab wall.
	lm.gable("Tile", Vector3(0, EAVE + 0.9, ZS - 2.7), 5.4, HX * 2.0 - 0.4, 2.6,
		Basis(Vector3.UP, PI * 0.5), 0.15, "Plaster")
	lm.beam("Tile", Vector3(-HX, EAVE + 3.58, ZS - 2.7), Vector3(HX, EAVE + 3.58, ZS - 2.7), 0.32, 0.22,
		Vector3.BACK)
	# Cupola lanterns along the central nave (they show as small tiled pyramids).
	for z in [COURT_ZS + 6.0, 6.0, 14.0, ZS - 2.7]:
		lm.box("Plaster", Vector3(0, EAVE + 3.2, float(z)), Vector3(3.6, 1.6, 3.6))
		lm.spire("Tile", Vector3(0, EAVE + 4.0, float(z)), 2.1, 1.6, 0.0, 8)

## Courtyard arcades: nine arches into the prayer hall on the south side,
## the side naves opening on east and west, the fountain in the middle.
static func _court(lm: LandmarkMesh) -> void:
	var zf := COURT_ZS
	LandmarkAfhDetail.arcade(lm, "Plaster", "Plaster", Vector3(-COURT_HX, 0, zf),
		Vector3(COURT_HX, 0, zf), Vector3(0, 0, -1), 9, 4.0, EAVE, 1.2, 0.45)
	lm.quad("Dark", Vector3(-COURT_HX, 0.02, zf + 1.25), Vector3(COURT_HX, 0.02, zf + 1.25),
		Vector3(COURT_HX, 6.5, zf + 1.25), Vector3(-COURT_HX, 6.5, zf + 1.25), Vector3(0, 0, -1))
	for s in [-1.0, 1.0]:
		var x: float = s * COURT_HX
		LandmarkAfhDetail.arcade(lm, "Plaster", "Plaster", Vector3(x, 0, ZN + 1.2), Vector3(x, 0, zf),
			Vector3(-s, 0, 0), 4, 4.0, EAVE, 1.2, 0.45)
		lm.quad("Dark", Vector3(x + s * 1.25, 0.02, ZN + 1.2), Vector3(x + s * 1.25, 0.02, zf),
			Vector3(x + s * 1.25, 6.5, zf), Vector3(x + s * 1.25, 6.5, ZN + 1.2), Vector3(-s, 0, 0))
		LandmarkAfhDetail.merlon_row(lm, "Plaster", Vector3(x, EAVE, ZN + 1.2), Vector3(x, EAVE, zf),
			0.8, 1.1, 0.45, 1.6)
	LandmarkAfhDetail.merlon_row(lm, "Plaster", Vector3(-COURT_HX, EAVE, zf), Vector3(COURT_HX, EAVE, zf),
		0.8, 1.1, 0.45, 1.6)
	# Ablution fountain.
	var fc := Vector3(0, 0, (ZN + zf) * 0.5)
	lm.lathe("Sandstone", fc, PackedVector2Array([Vector2(2.4, 0), Vector2(2.4, 0.5), Vector2(2.1, 0.55),
		Vector2(2.1, 0.3), Vector2(0.5, 0.3), Vector2(0.4, 1.0), Vector2(0.9, 1.2), Vector2(0.0, 1.25)]), 16)

## Four gates in each side wall: horseshoe arches in rectangular alfiz
## frames, and the minaret's door.
static func _gates(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var out := Vector3(s, 0, 0)
		for z in [-22.0, -2.0, 10.0, 22.0]:
			var c := Vector3(s * (HX + 0.8), 0, z)
			lm.box("Sandstone", c + Vector3(0, 3.6, 0), Vector3(1.6, 7.2, 5.6))
			var face: Vector3 = c + out * 0.8
			LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", face, out, 3.0, 5.0, "horseshoe", 0.35, 0.22, false)
			LandmarkAfhDetail.alfiz(lm, "Plaster", face, out, 4.6, 6.0, 0.25, 0.15)
			LandmarkAfhParts.face_quad(lm, "Plaster", face, out, 0.0, 6.4, 4.4, 0.6, 0.08)

## 77 m minaret: 12.81 m square shaft of sandstone rubble to 55.68 m, a
## different arrangement of framed windows and blind arches on every
## face, sebka panels in the upper register, the row of four interlaced
## polylobed arches, the green and white zellij frieze and stepped
## merlons; then the 6.88 m upper shaft (to 69.5 m) with a pair of
## windows and a sebka panel on each face, its fluted dome and the
## finial of three copper balls (the largest 2 m) beside the flag pole.
static func _minaret(lm: LandmarkMesh, b: Vector3) -> void:
	var hw := 6.405
	lm.box("Sandstone", b + Vector3(0, 27.84, 0), Vector3(hw * 2.0, 55.68, hw * 2.0))
	lm.box("Sandstone", b + Vector3(0, 0.6, 0), Vector3(hw * 2.0 + 0.6, 1.2, hw * 2.0 + 0.6))
	var faces: Array[Vector3] = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for f in 4:
		var out: Vector3 = faces[f]
		var right := Vector3.UP.cross(out).normalized()
		var c := b + out * hw
		# Margins framing each face.
		for s in [-1.0, 1.0]:
			lm.beam("Sandstone", c + right * (hw - 0.6) * float(s) + out * 0.1 + Vector3(0, 1.2, 0),
				c + right * (hw - 0.6) * float(s) + out * 0.1 + Vector3(0, 50.4, 0), 0.2, 0.9, out)
		# Five storeys of windows lighting the ramp, shapes varying by face.
		for k in 5:
			var y := 9.0 + 7.4 * float(k)
			var us: Array[float] = [0.0]
			if (f + k) % 3 == 1:
				us = [-2.3, 2.3]
			elif (f + k) % 3 == 2:
				us = [-3.6, 0.0, 3.6]
			var shape := "horseshoe" if (f + k) % 2 == 0 else "lobed"
			for u in us:
				var p: Vector3 = c + right * u + Vector3(0, y, 0)
				LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", p, out, 1.2, 2.6, shape, 0.28, 0.22, true, 5)
				LandmarkAfhDetail.alfiz(lm, "Plaster", p - Vector3(0, 0.3, 0), out, 2.3, 3.4, 0.2, 0.1)
		# Upper register: sebka lattice on two faces, twin lobed blind arches on the others.
		if f % 2 == 0:
			LandmarkAfhDetail.sebka(lm, "Sandstone", "Dark", c + Vector3(0, 43.2, 0), out, 9.6, 3.6, 6, 2,
				0.22, 0.18)
		else:
			for u in [-2.6, 2.6]:
				var p: Vector3 = c + right * float(u) + Vector3(0, 43.0, 0)
				LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", p, out, 3.2, 3.8, "lobed", 0.3, 0.2, false, 7)
		# Four interlaced polylobed blind arches under the frieze.
		for u in [-4.5, -1.5, 1.5, 4.5]:
			LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", c + right * float(u) + Vector3(0, 47.4, 0), out,
				2.4, 3.2, "lobed", 0.26, 0.2, false, 5)
		lm.beam("Sandstone", c + out * 0.15 - right * hw + Vector3(0, 47.2, 0),
			c + out * 0.15 + right * hw + Vector3(0, 47.2, 0), 0.3, 0.3, out)
		# Zellij frieze: green band set with white lozenges.
		for i in 16:
			var u := -hw + 0.8 * (float(i) + 0.5)
			var p := c + out * 0.32 + right * u + Vector3(0, 52.2, 0)
			lm.quad("Plaster", p - right * 0.3, p - Vector3(0, 0.55, 0), p + right * 0.3, p + Vector3(0, 0.55, 0), out)
		# Lantern: a pair of windows and a sebka panel per face.
		var lc := b + out * 3.44
		for u in [-1.15, 1.15]:
			LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", lc + right * float(u) + Vector3(0, 58.6, 0), out,
				1.0, 2.8, "horseshoe", 0.22, 0.18, true)
		LandmarkAfhDetail.sebka(lm, "Sandstone", "Dark", lc + Vector3(0, 62.6, 0), out, 4.8, 2.8, 4, 2,
			0.18, 0.15)
	LandmarkAfhDetail.niche(lm, "Sandstone", "Dark", b + Vector3(0, 0, -hw), Vector3(0, 0, -1), 2.6, 4.6,
		"horseshoe", 0.4, 0.3, false)
	lm.box("Tile", b + Vector3(0, 52.3, 0), Vector3(hw * 2.0 + 0.5, 2.6, hw * 2.0 + 0.5))
	lm.box("Sandstone", b + Vector3(0, 54.5, 0), Vector3(hw * 2.0 + 0.9, 0.5, hw * 2.0 + 0.9))
	lm.box("Sandstone", b + Vector3(0, 55.4, 0), Vector3(hw * 2.0 + 0.4, 0.56, hw * 2.0 + 0.4))
	for f in 4:
		var out: Vector3 = faces[f]
		var right := Vector3.UP.cross(out).normalized()
		var e := b + out * (hw - 0.3) + Vector3(0, 55.68, 0)
		LandmarkAfhDetail.merlon_row(lm, "Sandstone", e - right * hw, e + right * hw, 1.0, 1.6, 0.6, 1.6)
	# Upper shaft (lantern) 6.88 m square.
	var lw := 3.44
	lm.box("Sandstone", b + Vector3(0, 62.59, 0), Vector3(lw * 2.0, 13.82, lw * 2.0))
	lm.box("Tile", b + Vector3(0, 67.4, 0), Vector3(lw * 2.0 + 0.3, 1.2, lw * 2.0 + 0.3))
	lm.box("Sandstone", b + Vector3(0, 68.3, 0), Vector3(lw * 2.0 + 0.6, 0.4, lw * 2.0 + 0.6))
	for f in 4:
		var out: Vector3 = faces[f]
		var right := Vector3.UP.cross(out).normalized()
		var e := b + out * (lw - 0.25) + Vector3(0, 68.5, 0)
		LandmarkAfhDetail.merlon_row(lm, "Sandstone", e - right * lw, e + right * lw, 0.7, 1.0, 0.45, 1.15)
	# Fluted dome with ribs, then the jamur finial.
	var db := b + Vector3(0, 68.5, 0)
	lm.frustum("Sandstone", db, 2.7, 2.7, 1.0, 16)
	lm.lathe("Tile", db + Vector3(0, 1.0, 0), LandmarkMaParts.dome_profile(2.7, 2.6, 6), 16)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var prev := db + Vector3(cos(a) * 2.75, 1.0, sin(a) * 2.75)
		for k in range(1, 6):
			var t := PI * 0.5 * float(k) / 5.0
			var p := db + Vector3(cos(a) * 2.75 * cos(t), 1.0 + 2.65 * sin(t), sin(a) * 2.75 * cos(t))
			lm.beam("Tile", prev, p, 0.16, 0.12)
			prev = p
	LandmarkMaParts.needle(lm, "Gold", b + Vector3(0, 71.9, 0),
		PackedVector2Array([Vector2(0, 0.16), Vector2(5.1, 0.06)]), 6)
	LandmarkMaParts.sphere(lm, "Gold", b + Vector3(0, 73.0, 0), 1.0, 14, 8)
	LandmarkMaParts.sphere(lm, "Gold", b + Vector3(0, 74.8, 0), 0.75, 12, 6)
	LandmarkMaParts.sphere(lm, "Gold", b + Vector3(0, 76.0, 0), 0.5, 10, 6)
	# Flag pole (the jamur's side gallows) for the green flag on Fridays.
	lm.beam("Gold", b + Vector3(2.6, 69.0, 0), b + Vector3(2.6, 74.0, 0), 0.12)
	lm.beam("Gold", b + Vector3(2.6, 73.8, 0), b + Vector3(0.9, 73.8, 0), 0.1)
