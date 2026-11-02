class_name LandmarkLpLevant
extends RefCounted

## Roman temples of the Levant in true metres: the Temple of Bel at
## Palmyra and the Temples of Jupiter and Bacchus at Baalbek. Ruins are
## built as they stand (Bel as it stood before August 2015). The Jerash
## monuments are in LandmarkLpJerash.

# --- Palmyra, Temple of Bel ---

## Compass frame. The temple (dedicated AD 32) stands in the middle of its
## 205 m square temenos: a 30 x 55 m stylobate under a peristyle of 8 x 15
## fluted Corinthian columns 15.8 m tall (before 2015 the west row stood
## under its entablature beside the portal; elsewhere mostly the bases),
## round the 13.9 x 39.5 m cella. The cella opens west, off-centre to the
## south, through its great framed portal; two pairs of windows high in
## the long walls, pilasters, a cornice crowned with stepped merlons and
## the stair turrets at three corners (22 m). The temenos wall is windowed
## outside and pilastered, with ruined porticoes inside (double on the
## north, east and south, a single taller one on the west) and the
## propylaeum, fortified as a gate in 1132, in the middle of the west side.
static func palmyra_bel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCC393", 4.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CDB88F", 6.0))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#1C1712", 3.0, 0.92))
	lm.box("Court", Vector3(0, 0.1, 0), Vector3(205, 0.2, 205), Basis(), 0.0)
	_bel_temple(lm)
	_bel_temenos(lm)
	# Altar and the lustral basin in the court before the portal.
	lm.box("Stone", Vector3(-40, 1.0, 3.0), Vector3(6, 1.8, 5))
	lm.box("Stone", Vector3(-40, 2.05, 3.0), Vector3(6.6, 0.3, 5.6))
	lm.box("Stone", Vector3(-40, 0.5, -16.0), Vector3(9, 0.8, 5))
	lm.box("Door", Vector3(-40, 0.92, -16.0), Vector3(7.6, 0.06, 3.6), Basis(), 0.0)
	lm.commit(model)

## The temple: stylobate and west stair, peristyle, cella.
static func _bel_temple(lm: LandmarkMesh) -> void:
	var y0 := 2.0
	lm.box("Stone", Vector3(0, y0 * 0.5, 0), Vector3(30, y0, 55))
	lm.box("Stone", Vector3(0, y0 - 0.15, 0), Vector3(30.6, 0.3, 55.6))
	LandmarkLpParts.steps(lm, "Stone", Vector3(-15.0 - 4.0, 0, 3.0), Vector3(1, 0, 0), 12.0, 4.0, y0, 6)
	# Peristyle: 8 x 15 column positions round the stylobate edge.
	var cx := 13.4
	var cz := 26.0
	var col_h := 15.8
	var pos: Array[Vector3] = []
	var standing: Array[bool] = []
	for i in 15:
		var z := -cz + 2.0 * cz * float(i) / 14.0
		pos.append(Vector3(-cx, y0, z))
		standing.append(absf(z - 3.0) > 2.5)
		pos.append(Vector3(cx, y0, z))
		standing.append(i <= 1 or i >= 13)
	for i in range(1, 7):
		var x := -cx + 2.0 * cx * float(i) / 7.0
		for z in [-cz, cz]:
			pos.append(Vector3(x, y0, z))
			standing.append(false)
	for k in pos.size():
		if standing[k]:
			LandmarkDetail.column(lm, "Stone", pos[k], 0.75, col_h, "corinthian", 20)
		else:
			lm.box("Stone", pos[k] + Vector3(0, 0.2, 0), Vector3(2.0, 0.4, 2.0))
			lm.lathe("Stone", pos[k] + Vector3(0, 0.4, 0), PackedVector2Array([Vector2(0.95, 0), Vector2(0.98, 0.15),
				Vector2(0.8, 0.35), Vector2(0.76, 1.2)]), 14)
	# Entablature over the standing west row (both runs either side of the portal).
	var et := y0 + col_h
	for run in [[-cz - 1.0, 0.0], [6.5, cz + 1.0]]:
		var z0: float = run[0]
		var z1: float = run[1]
		var zm := (z0 + z1) * 0.5
		var zl := z1 - z0
		lm.box("Stone", Vector3(-cx, et + 0.45, zm), Vector3(1.9, 0.9, zl))
		lm.box("Stone", Vector3(-cx - 0.05, et + 1.0, zm), Vector3(2.0, 0.2, zl))
		lm.box("Stone", Vector3(-cx, et + 1.5, zm), Vector3(1.7, 0.8, zl))
		LandmarkDetail.cornice(lm, "Stone", Vector3(-cx - 0.85, et + 1.9, z0), Vector3(-cx - 0.85, et + 1.9, z1),
			Vector3(-1, 0, 0), 0.7)
	_bel_cella(lm, y0)

## Cella 13.86 x 39.45 m: walls, pilasters, windows, portal, merlons, turrets.
static func _bel_cella(lm: LandmarkMesh, y0: float) -> void:
	var hx := 6.93
	var hz := 19.73
	var top := 18.2
	lm.box("Stone", Vector3(0, (y0 + top) * 0.5, 0), Vector3(hx * 2.0, top - y0, hz * 2.0))
	# Base moulding and the crowning entablature with a cornice all round.
	lm.box("Stone", Vector3(0, y0 + 0.4, 0), Vector3(hx * 2.0 + 0.6, 0.8, hz * 2.0 + 0.6))
	lm.box("Stone", Vector3(0, top - 0.9, 0), Vector3(hx * 2.0 + 0.3, 1.0, hz * 2.0 + 0.3))
	var cr := [Vector3(-hx - 0.15, top - 0.4, -hz - 0.15), Vector3(hx + 0.15, top - 0.4, -hz - 0.15),
		Vector3(hx + 0.15, top - 0.4, hz + 0.15), Vector3(-hx - 0.15, top - 0.4, hz + 0.15)]
	var outs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
	for i in 4:
		LandmarkDetail.cornice(lm, "Stone", cr[i], cr[(i + 1) % 4], outs[i], 0.6, false)
	# Pilasters: seven bays on the long walls, three on the ends, with capitals.
	for i in 8:
		var z := -hz + 2.0 * hz * float(i) / 7.0
		for s in [-1.0, 1.0]:
			if s < 0.0 and absf(z - 3.0) < 4.0:
				continue
			_pilaster(lm, Vector3(float(s) * (hx + 0.15), y0 + 0.8, z), Vector3(float(s), 0, 0), top - 1.4 - y0 - 0.8)
	for i in 4:
		var x := -hx + 2.0 * hx * float(i) / 3.0
		for s in [-1.0, 1.0]:
			_pilaster(lm, Vector3(x, y0 + 0.8, float(s) * (hz + 0.15)), Vector3(0, 0, float(s)), top - 1.4 - y0 - 0.8)
	# Two pairs of windows high in the long walls.
	for s in [-1.0, 1.0]:
		for z in [-9.0, 13.0]:
			LandmarkDetail.window(lm, "Stone", "Door", Vector3(float(s) * hx, y0 + 11.6, z), Vector3(float(s), 0, 0),
				1.6, 3.2, false, 0.3)
	# West portal: a door 4.4 x 9.4 m in a stepped frame, lintel, cornice and consoles.
	var pz := 3.0
	var dw := 4.4
	var dh := 9.4
	lm.box("Door", Vector3(-hx - 0.02, y0 + dh * 0.5, pz), Vector3(0.1, dh, dw), Basis(), 0.0)
	for k in 3:
		var fw := 0.55
		var off := dw * 0.5 + fw * (float(k) + 0.5)
		var proud := 0.6 - 0.15 * float(k)
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(-hx - proud * 0.5, y0 + (dh + fw * float(k)) * 0.5, pz + float(s) * off),
				Vector3(proud, dh + fw * float(k), fw))
		lm.box("Stone", Vector3(-hx - proud * 0.5, y0 + dh + fw * (float(k) + 0.5), pz),
			Vector3(proud, fw, dw + fw * 2.0 * float(k + 1)))
	lm.box("Stone", Vector3(-hx - 0.5, y0 + dh + 1.9, pz), Vector3(1.0, 0.5, dw + 4.2))
	LandmarkDetail.cornice(lm, "Stone", Vector3(-hx - 0.9, y0 + dh + 2.15, pz - dw * 0.5 - 2.2),
		Vector3(-hx - 0.9, y0 + dh + 2.15, pz + dw * 0.5 + 2.2), Vector3(-1, 0, 0), 0.6)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(-hx - 0.7, y0 + dh + 1.2, pz + float(s) * (dw * 0.5 + 1.9)), Vector3(0.6, 1.4, 0.5))
	# Parapet: stepped merlons along the top, stair turrets at three corners.
	var mc := [Vector3(-hx, top, -hz), Vector3(hx, top, -hz), Vector3(hx, top, hz), Vector3(-hx, top, hz)]
	for i in 4:
		LandmarkLpDetail.stepped_merlons(lm, "Stone", mc[i], mc[(i + 1) % 4], 1.2, 1.6, 0.7, 1.9)
	for i in [0, 1, 3]:
		var c: Vector3 = mc[i]
		var tc := c + Vector3(-signf(c.x) * 1.9, 0, -signf(c.z) * 1.9)
		lm.box("Stone", tc + Vector3(0, 1.6, 0), Vector3(3.4, 3.2, 3.4))
		lm.box("Stone", tc + Vector3(0, 3.5, 0), Vector3(3.8, 0.4, 3.8))
		lm.box("Door", tc + Vector3(-signf(c.x) * 1.71, 1.2, 0), Vector3(0.06, 1.8, 0.9), Basis(), 0.0)

## Flat pilaster on a wall facing `n`, from `foot` up `h`, with its capital.
static func _pilaster(lm: LandmarkMesh, foot: Vector3, n: Vector3, h: float) -> void:
	var b := Basis.looking_at(n)
	lm.box("Stone", foot + Vector3(0, 0.25, 0) + n * 0.2, Vector3(1.3, 0.5, 0.45), b)
	lm.box("Stone", foot + Vector3(0, h * 0.5, 0) + n * 0.15, Vector3(1.0, h, 0.3), b)
	lm.box("Stone", foot + Vector3(0, h - 0.35, 0) + n * 0.22, Vector3(1.3, 0.7, 0.45), b)

## Temenos wall 205 m square: windowed, pilastered outside, porticoes in
## ruin inside, and the west propylaeum gate with its stair.
static func _bel_temenos(lm: LandmarkMesh) -> void:
	var half := 102.5
	var th := 2.4
	var wh := 11.0
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var f := LandmarkLpParts.outward(yaw)
		var r := LandmarkLpParts.across(yaw)
		var basis := Basis(Vector3.UP, yaw)
		var mid := f * (half - th * 0.5)
		var west := k == 3
		if west:
			for s in [-1.0, 1.0]:
				lm.box("Stone", mid + r * (float(s) * 61.25) + Vector3(0, wh * 0.5, 0), Vector3(82.5, wh, th), basis)
		else:
			lm.box("Stone", mid + Vector3(0, wh * 0.5, 0), Vector3(half * 2.0, wh, th), basis)
		lm.box("Stone", mid + Vector3(0, wh + 0.3, 0), Vector3(half * 2.0 + 0.8, 0.6, th + 0.8), basis)
		# Outer face: windows between pilasters (skipped across the gate).
		var face := f * half
		for i in 30:
			var u := -half + 3.4 + 6.6 * float(i)
			if west and absf(u) < 24.0:
				continue
			lm.box("Stone", face + r * u + f * 0.2 + Vector3(0, wh * 0.5, 0), Vector3(1.2, wh, 0.4), basis)
			if i < 29:
				var wu := u + 3.3
				if west and absf(wu) < 24.0:
					continue
				lm.box("Door", face + r * wu + f * 0.02 + Vector3(0, 6.6, 0), Vector3(1.4, 2.6, 0.08), basis, 0.0)
				lm.box("Stone", face + r * wu + f * 0.12 + Vector3(0, 5.2, 0), Vector3(2.0, 0.2, 0.25), basis, 0.0)
				lm.box("Stone", face + r * wu + f * 0.12 + Vector3(0, 8.0, 0), Vector3(2.0, 0.25, 0.25), basis, 0.0)
		# Porticoes: double on N, E, S (10 m), single 13 m on the west, mostly fallen.
		var rows := [8.0] if west else [7.0, 14.0]
		var ch := 13.0 if west else 10.0
		for ri in rows.size():
			var inset: float = rows[ri]
			var span := half - inset - 2.0
			var n := int(span * 2.0 / 4.6) + 1
			for i in n:
				var u := -span + 2.0 * span * float(i) / float(n - 1)
				if west and absf(u) < 22.0:
					continue
				var p := f * (half - th - inset) + r * u
				var hsh := (i * 37 + ri * 11 + k * 5) % 10
				if hsh < 3:
					LandmarkLpParts.column(lm, "Stone", p, 0.5, ch, 0.9, 10)
				else:
					lm.box("Stone", p + Vector3(0, 0.25, 0), Vector3(1.3, 0.5, 1.3))
					lm.frustum("Stone", p + Vector3(0, 0.5, 0), 0.52, 0.5, 0.6 + float(hsh % 3) * 0.7, 8)
	# Propylaeum: the gate block, its doorways, merlons and the stair with column bases.
	var gx := -half - 4.0
	lm.box("Stone", Vector3(gx, 7.5, 0), Vector3(10.0, 15.0, 44.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(gx - 0.6, 7.5, float(s) * 21.0), Vector3(11.2, 15.0, 3.0))
	LandmarkLpDetail.stepped_merlons(lm, "Stone", Vector3(gx - 5.0, 15.0, -22.0), Vector3(gx - 5.0, 15.0, 22.0),
		1.2, 1.4, 0.8, 2.2)
	for d in [[0.0, 3.2, 8.5], [-9.0, 1.8, 5.0], [9.0, 1.8, 5.0]]:
		var z: float = d[0]
		var w: float = d[1]
		var h: float = d[2]
		lm.box("Door", Vector3(gx - 5.02, 2.2 + h * 0.5, z), Vector3(0.1, h, w * 2.0), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(gx - 5.25, 2.2 + h * 0.5, z + float(s) * (w + 0.3)), Vector3(0.5, h, 0.6))
		lm.box("Stone", Vector3(gx - 5.3, 2.2 + h + 0.4, z), Vector3(0.6, 0.8, w * 2.0 + 1.6))
	lm.box("Stone", Vector3(gx - 6.5, 1.1, 0), Vector3(3.0, 2.2, 38.0))
	LandmarkLpParts.steps(lm, "Stone", Vector3(gx - 8.0 - 10.0, 0, 0), Vector3(1, 0, 0), 36.0, 10.0, 2.2, 8)
	for i in 8:
		lm.frustum("Stone", Vector3(gx - 7.0, 2.2, -15.75 + 4.5 * float(i)), 0.75, 0.7, 1.4, 10)

# --- Baalbek, Temples of Jupiter and Bacchus ---

## Baalbek in compass frame, both temples facing east. The Jupiter
## podium (88 x 48 m, 13 m high over the megalithic courses with the
## Trilithon on the west) carries the six surviving unfluted Corinthian
## columns of the south flank (19.9 m with base and capital, 2.2 m thick)
## under their richly carved entablature (37.5 m), and the bases of the
## rest of its 10 x 19 peristyle. The Temple of Bacchus (66 x 35 m on a
## 5 m podium, 31 m) stands to the south-east: its cella walls with the
## crowning entablature, the 42-column peristyle (8 x 15, nearly 20 m)
## of which the north flank and four south columns stand under the
## coffered ceiling slabs, and the great 13 m east portal.
static func baalbek(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6BC8C", 5.0))
	lm.use("Megalith", LandmarkMaterials.pbr("stone", "#BFA076", 8.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#BAA67E", 6.0))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#1C1712", 3.0, 0.92))
	lm.box("Court", Vector3(0, 0.1, 2), Vector3(170, 0.2, 130), Basis(), 0.0)
	_jupiter(lm, Vector3(-27, 0, -30))
	_bacchus(lm, Vector3(38, 0, 35))
	lm.commit(model)

static func _jupiter(lm: LandmarkMesh, j: Vector3) -> void:
	# Megalith base: three coursed tiers, the Trilithon course on the west.
	for c in 3:
		var y := 2.2 * float(c)
		lm.box("Megalith", j + Vector3(0, y + 1.1, 0), Vector3(94 - float(c) * 0.6, 2.2, 54 - float(c) * 0.6))
	for k in 3:
		lm.box("Megalith", j + Vector3(-47.4, 6.6 + 2.1, -10.0 + 19.4 * float(k) - 9.4), Vector3(0.8, 4.2, 19.0))
	for i in 9:
		for sz in [-1.0, 1.0]:
			lm.box("Megalith", j + Vector3(-42.0 + 10.4 * float(i), 1.1, float(sz) * 27.15), Vector3(10.0, 2.0, 0.4))
	# Temple podium with its base and crowning mouldings.
	lm.box("Stone", j + Vector3(0, 9.75, 0), Vector3(87.75, 6.5, 47.7))
	lm.box("Stone", j + Vector3(0, 6.9, 0), Vector3(88.6, 0.8, 48.5))
	lm.box("Stone", j + Vector3(0, 12.7, 0), Vector3(88.6, 0.6, 48.5))
	LandmarkLpParts.steps(lm, "Megalith", j + Vector3(67, 0, 0), Vector3(-1, 0, 0), 28.0, 23.1, 13.0, 16)
	# Bases of the fallen peristyle (10 x 19).
	for i in 19:
		var x := j.x - 40.5 + 4.5 * float(i)
		for s in [-1.0, 1.0]:
			if not (s > 0.0 and i >= 4 and i <= 9):
				_base_stump(lm, Vector3(x, 13.0, j.z + float(s) * 18.5), 1.1)
	for i in range(1, 9):
		for x in [-40.5, 40.5]:
			_base_stump(lm, Vector3(j.x + float(x), 13.0, j.z - 18.5 + 4.11 * float(i)), 1.1)
	# The six columns and their entablature: architrave (three fasciae),
	# frieze with consoles and lion / bull protomes, modillion cornice.
	var y0 := 13.0
	var ch := 19.9
	for i in 6:
		LandmarkDetail.column(lm, "Stone", Vector3(j.x - 22.5 + 4.5 * float(i), y0, j.z + 18.5), 1.1, ch,
			"corinthian", 0)
	var x0 := j.x - 22.5 - 2.8
	var x1 := j.x + 2.8
	var xm := (x0 + x1) * 0.5
	var xl := x1 - x0
	var ez := j.z + 18.5
	var ey := y0 + ch
	for k in 3:
		lm.box("Stone", Vector3(xm, ey + 0.3 + 0.55 * float(k), ez), Vector3(xl, 0.55, 2.4 + 0.12 * float(k)))
	lm.box("Stone", Vector3(xm, ey + 2.4, ez), Vector3(xl, 1.3, 2.3))
	for i in 16:
		var x := x0 + 0.9 + (xl - 1.8) * float(i) / 15.0
		lm.box("Stone", Vector3(x, ey + 2.4, ez + 1.3), Vector3(0.5, 1.1, 0.4))
		if i % 2 == 0:
			lm.lathe("Stone", Vector3(x + 0.85, ey + 2.1, ez + 1.15), LandmarkLpParts.dome_profile(0.32, 0.55, 3), 8)
	LandmarkDetail.cornice(lm, "Stone", Vector3(x0, ey + 3.05, ez + 1.15), Vector3(x1, ey + 3.05, ez + 1.15),
		Vector3(0, 0, 1), 1.45)
	lm.box("Stone", Vector3(xm, ey + 3.8, ez - 0.2), Vector3(xl, 1.4, 2.0))

## Attic base and a broken drum of a fallen column.
static func _base_stump(lm: LandmarkMesh, p: Vector3, r: float) -> void:
	lm.box("Stone", p + Vector3(0, 0.3, 0), Vector3(r * 2.7, 0.6, r * 2.7))
	lm.lathe("Stone", p + Vector3(0, 0.6, 0), PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r * 1.32, 0.2),
		Vector2(r * 1.1, 0.4), Vector2(r * 1.04, 0.9)]), 14)

static func _bacchus(lm: LandmarkMesh, b: Vector3) -> void:
	var py := 5.0
	lm.box("Stone", b + Vector3(0, py * 0.5, 0), Vector3(66, py, 35))
	lm.box("Stone", b + Vector3(0, 0.4, 0), Vector3(66.8, 0.8, 35.8))
	lm.box("Stone", b + Vector3(0, py - 0.3, 0), Vector3(66.8, 0.6, 35.8))
	LandmarkLpParts.steps(lm, "Stone", b + Vector3(43, 0, 0), Vector3(-1, 0, 0), 20.0, 10.0, py, 12)
	# Cella walls: plinth, wall to 19 m, the crowning entablature.
	var cw := 21.2
	var cl := 49.0
	lm.box("Stone", b + Vector3(-2.0, py + 9.5, 0), Vector3(cl, 19.0, cw))
	lm.box("Stone", b + Vector3(-2.0, py + 0.6, 0), Vector3(cl + 0.8, 1.2, cw + 0.8))
	lm.box("Stone", b + Vector3(-2.0, py + 19.6, 0), Vector3(cl + 1.0, 1.2, cw + 1.0))
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Stone", b + Vector3(-2.0 - cl * 0.5 - 0.5, py + 20.2, float(s) * (cw * 0.5 + 0.5)),
			b + Vector3(-2.0 + cl * 0.5 + 0.5, py + 20.2, float(s) * (cw * 0.5 + 0.5)), Vector3(0, 0, float(s)), 1.0, false)
	# Pilasters on the cella corners (antae) and along the flanks.
	for i in 9:
		var x := b.x - 2.0 - cl * 0.5 + cl * float(i) / 8.0
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(x, py + 9.6, b.z + float(s) * (cw * 0.5 + 0.2)), Vector3(1.4, 17.6, 0.4))
	# East portal: 6.5 x 13 m door in a moulded frame with the slipped keystone.
	var px := b.x - 2.0 + cl * 0.5
	lm.box("Door", Vector3(px + 0.02, b.y + py + 6.5, b.z), Vector3(0.1, 13.0, 6.5), Basis(), 0.0)
	for k in 3:
		var off := 3.25 + 0.5 * (float(k) + 0.5)
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(px + 0.35 - 0.1 * float(k), py + (13.0 + 0.5 * float(k)) * 0.5,
				b.z + float(s) * off), Vector3(0.7 - 0.2 * float(k), 13.0 + 0.5 * float(k), 0.5))
	lm.box("Stone", Vector3(px + 0.4, py + 14.0, b.z), Vector3(0.8, 2.0, 9.6))
	lm.box("Stone", Vector3(px + 0.5, py + 12.6, b.z), Vector3(0.8, 1.6, 1.6))
	# Peristyle 8 x 15 (pitch 4.07 x 4.23 m): the north flank and four south
	# columns stand; the rest are bases.
	var ch := 19.6
	var z_side := 14.8
	for s in [-1.0, 1.0]:
		for i in 15:
			var p := b + Vector3(-28.5 + 4.07 * float(i), py, float(s) * z_side)
			if s < 0.0 or i < 4:
				LandmarkDetail.column(lm, "Stone", p, 0.95, ch, "corinthian", 0)
			else:
				_base_stump(lm, p, 0.95)
	for sx in [-1.0, 1.0]:
		for i in range(1, 7):
			_base_stump(lm, b + Vector3(float(sx) * 28.5, py, -z_side + 4.23 * float(i)), 0.95)
	# North entablature and the coffered ceiling slabs to the cella wall.
	var et := py + ch
	var nz := b.z - z_side
	lm.box("Stone", Vector3(b.x, et + 0.8, nz), Vector3(59.0, 1.6, 2.3))
	lm.box("Stone", Vector3(b.x, et + 2.1, nz), Vector3(59.0, 1.0, 2.1))
	LandmarkDetail.cornice(lm, "Stone", Vector3(b.x - 29.5, et + 2.6, nz - 1.05), Vector3(b.x + 29.5, et + 2.6, nz - 1.05),
		Vector3(0, 0, -1), 1.0)
	var gap := z_side - cw * 0.5
	for i in 14:
		var x := b.x - 26.5 + 4.07 * float(i)
		lm.box("Stone", Vector3(x, et + 0.6, nz + gap * 0.5), Vector3(3.9, 1.2, gap - 0.6))
		for k in 2:
			lm.box("Door", Vector3(x, et - 0.02, nz + 1.0 + (gap - 2.0) * (float(k) + 0.5) * 0.5),
				Vector3(1.6, 0.06, (gap - 2.4) * 0.4), Basis(), 0.0)
