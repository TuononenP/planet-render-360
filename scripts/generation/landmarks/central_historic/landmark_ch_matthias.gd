class_name LandmarkChMatthias
extends RefCounted

## Matthias Church (Church of Our Lady of Buda) for the Fisherman's
## Bastion model, in true metres: a Gothic hall church (14th century,
## restored by Frigyes Schulek 1874-96) with its west front to -X, a
## steep roof of diamond-patterned Zsolnay tiles, buttresses with
## pinnacles, a polygonal choir to the east, the 80 m Matthias tower at
## the south west corner (square shaft, two octagonal stages with
## balcony galleries, crocketed stone spire) and the low Romanesque Bela
## tower at the north west corner. Draws on the bastion's material keys.

## West front x, choir east end x, half-width of the hall.
const WEST := -72.0
const EAST := -34.0
const HALF := 12.0
const EAVE := 18.0
const RISE := 15.0

static func church(lm: LandmarkMesh) -> void:
	_hall(lm)
	_roof_pattern(lm)
	_west_front(lm)
	_matthias_tower(lm, Vector3(WEST + 5.5, 0, HALF + 4.0))
	_bela_tower(lm, Vector3(WEST + 4.0, 0, -HALF - 2.6))

## Hall walls, roof, buttresses with pinnacles, two-light lancets, the
## choir and its five-sided apse, and the south (Mary) porch.
static func _hall(lm: LandmarkMesh) -> void:
	var len_ := EAST - WEST
	var cx := (WEST + EAST) * 0.5
	lm.box("Wall", Vector3(cx, EAVE * 0.5, 0), Vector3(len_, EAVE, HALF * 2.0))
	lm.gable("Roof", Vector3(cx, EAVE, 0), HALF * 2.0, len_, RISE, Basis(Vector3.UP, PI * 0.5), 0.6, "Wall")
	LandmarkChParts.band(lm, "White", 0.0, len_ * 0.5, HALF, 1.0, 0.25, Vector3(cx, 0, 0))
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		LandmarkDetail.cornice(lm, "White", Vector3(WEST, EAVE - 0.7, sz * HALF), Vector3(EAST, EAVE - 0.7, sz * HALF),
			n, 0.7, false)
		for i in 7:
			var x := WEST + 2.0 + (len_ - 4.0) * float(i) / 6.0
			LandmarkChParts.buttress(lm, "White", Vector3(x, 0, sz * HALF), n, 1.4, 2.2, EAVE - 2.0, 3)
			LandmarkChParts.pinnacle(lm, "White", Vector3(x, EAVE - 2.0, sz * (HALF + 0.4)), 0.9, 5.0)
			if i < 6:
				var wx := x + (len_ - 4.0) / 12.0
				if sz > 0.0 and i == 3:
					continue
				LandmarkChParts.lancet(lm, "White", "Windows", Vector3(wx, 4.5, sz * HALF), n, 2.4, 10.5, 1, 0.3)
	# South porch with its gable over the Mary portal.
	var pc := Vector3(WEST + (len_ - 4.0) * 3.5 / 6.0 + 2.0, 0, HALF)
	lm.box("White", pc + Vector3(0, 4.5, 2.0), Vector3(6.0, 9.0, 4.0))
	lm.gable("Roof", pc + Vector3(0, 9.0, 2.0), 6.0, 4.0, 4.0, Basis(), 0.3, "White")
	LandmarkChParts.lancet(lm, "White", "Windows", pc + Vector3(0, 0.3, 4.0), Vector3.BACK, 3.0, 6.5, 1, 0.35)
	LandmarkChParts.wimperg(lm, "White", pc + Vector3(0, 6.8, 4.0), Vector3.BACK, 4.4, 3.2, 0.3)
	for sx in [-1.0, 1.0]:
		LandmarkChParts.pinnacle(lm, "White", pc + Vector3(sx * 3.0, 9.0, 4.0), 0.7, 4.0)
	# Choir: narrower, then the apse.
	var cl := 10.0
	var ch := 9.0
	lm.box("Wall", Vector3(EAST + cl * 0.5, EAVE * 0.5, 0), Vector3(cl, EAVE, ch * 2.0))
	lm.gable("Roof", Vector3(EAST + cl * 0.5, EAVE, 0), ch * 2.0, cl, RISE * 0.8, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	var ac := Vector3(EAST + cl, 0, 0)
	lm.frustum("Wall", ac, ch * 1.08, ch * 1.08, EAVE, 8, PI / 8.0, 1.0, 1.0)
	lm.lathe("Roof", ac + Vector3(0, EAVE, 0), PackedVector2Array([Vector2(ch * 1.15, 0), Vector2(0.0, RISE * 0.8)]),
		8, 1.0, 1.0, PI / 8.0, false)
	# Octagon faces face multiples of 45 degrees; buttresses at the angles.
	for k in [-1, 0, 1]:
		var a := PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.lancet(lm, "White", "Windows", ac + d * ch + Vector3(0, 4.5, 0), d, 1.8, 10.5, 1, 0.3)
	for k in [-2, -1, 0, 1]:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.buttress(lm, "White", ac + d * ch * 1.04, d, 1.2, 2.0, EAVE - 2.5, 3)
		LandmarkChParts.pinnacle(lm, "White", ac + d * (ch + 0.5) + Vector3(0, EAVE - 2.5, 0), 0.8, 4.5)
	for sz in [-1.0, 1.0]:
		LandmarkChParts.lancet(lm, "White", "Windows", Vector3(EAST + cl * 0.5, 4.5, sz * ch), Vector3(0, 0, sz), 2.2,
			10.0, 1, 0.3)

## Zsolnay roof tiles: rows of green, ochre and blue diamonds over the
## orange field on both slopes of the hall roof.
static func _roof_pattern(lm: LandmarkMesh) -> void:
	var keys := ["RoofG", "RoofY", "RoofB"]
	var cols := 15
	var rows := 6
	var dx := (EAST - WEST) / float(cols)
	for sz in [-1.0, 1.0]:
		var s: float = sz
		var slope := Vector3(0, RISE, -s * HALF).normalized()
		var nrm := Vector3(0, HALF, s * RISE).normalized()
		var span := Vector3(0, RISE, -s * HALF).length()
		for j in rows:
			var t := (float(j) + 0.5) / float(rows)
			for i in cols:
				if (i + j) % 2 == 1:
					continue
				var c := Vector3(WEST + dx * (float(i) + 0.5), EAVE, s * HALF) + slope * span * t + nrm * 0.1
				var hu := dx * 0.5
				var hv := span / float(rows) * 0.5
				lm.quad(keys[j % 3], c - Vector3(hu, 0, 0), c - slope * hv, c + Vector3(hu, 0, 0), c + slope * hv, nrm)

## West front: the gable wall with pinnacles, the rose window and the
## main portal with its porch, tympanum and wimperg.
static func _west_front(lm: LandmarkMesh) -> void:
	var n := Vector3.LEFT
	var x := WEST
	# Gable wall rising in front of the roof, with tracery blind arcade.
	lm.tri("White", Vector3(x - 0.3, EAVE, -HALF), Vector3(x - 0.3, EAVE, HALF), Vector3(x - 0.3, EAVE + RISE + 1.0, 0),
		n, n, n, Vector2(-HALF, 0), Vector2(HALF, 0), Vector2(0, -RISE))
	for i in 5:
		var z := -6.0 + 3.0 * i
		var hmax := (RISE + 1.0) * (1.0 - absf(z) / HALF) - 2.0
		LandmarkChParts.lancet(lm, "White", "Wall", Vector3(x - 0.3, EAVE + 0.8, z), n, 1.6, maxf(hmax - 0.8, 2.0), 0, 0.2)
	LandmarkChParts.finial(lm, "White", Vector3(x - 0.3, EAVE + RISE + 1.0, 0), 2.6, 0.5)
	# Rose window.
	var rc := Vector3(x - 0.2, 12.0, 0)
	lm.disc("Windows", rc + n * 0.02, n, 3.2, 24)
	var prev := rc + Vector3(0, 0, 3.5)
	for k in 24:
		var a := TAU * float(k + 1) / 24.0
		var q := rc + Vector3(0, sin(a), cos(a)) * 3.5
		lm.beam("White", prev + n * 0.15, q + n * 0.15, 0.5, 0.4, n)
		prev = q
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.beam("White", rc + n * 0.15, rc + Vector3(0, sin(a), cos(a)) * 3.2 + n * 0.15, 0.16, 0.25, n)
		var pc := rc + Vector3(0, sin(a), cos(a)) * 2.2 + n * 0.15
		lm.frustum("White", pc - n * 0.1, 0.42, 0.42, 0.12, 8)
	# Main portal: deep porch, pointed portal with tympanum, wimperg.
	lm.box("White", Vector3(x - 2.0, 5.0, 0), Vector3(4.0, 10.0, 9.0))
	lm.gable("Roof", Vector3(x - 2.0, 10.0, 0), 9.0, 4.0, 4.5, Basis(), 0.3, "White")
	LandmarkChParts.lancet(lm, "White", "Windows", Vector3(x - 4.0, 0.3, 0), n, 4.0, 7.6, 1, 0.4)
	LandmarkChParts.wimperg(lm, "White", Vector3(x - 4.0, 7.6, 0), n, 6.0, 4.5, 0.35)
	for sz in [-1.0, 1.0]:
		LandmarkChParts.pinnacle(lm, "White", Vector3(x - 4.0, 10.0, sz * 4.5), 0.8, 4.6)
		LandmarkChParts.buttress(lm, "White", Vector3(x, 0, sz * (HALF - 1.0)), n, 1.6, 2.4, EAVE - 2.0, 3)

## Matthias tower: square Gothic shaft with buttressed corners and
## string courses, two octagonal stages each with a corbelled balcony
## and tracery parapet, corner pinnacles, the crocketed stone spire and
## the gilt finial to 80 m.
static func _matthias_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var hw := 5.2
	var sh := 36.0
	lm.box("Wall", p + Vector3(0, sh * 0.5, 0), Vector3(hw * 2.0, sh, hw * 2.0))
	for y in [9.0, 18.0, 27.0]:
		LandmarkChParts.band(lm, "White", y, hw, hw, 0.6, 0.3, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, hw)
		for s in [-1.0, 1.0]:
			LandmarkChParts.buttress(lm, "White", face + b * Vector3(s * (hw - 0.8), 0, 0), n, 1.2, 1.4, sh - 3.0, 4)
		LandmarkChParts.lancet(lm, "White", "Windows", face + Vector3(0, 11.0, 0), n, 1.4, 5.0, 0, 0.25)
		LandmarkChParts.lancet(lm, "White", "Windows", face + Vector3(0, 20.0, 0), n, 1.8, 5.6, 1, 0.25)
		LandmarkChParts.lancet(lm, "White", "Windows", face + Vector3(0, 28.5, 0), n, 2.4, 6.0, 1, 0.3)
		LandmarkChParts.wimperg(lm, "White", face + Vector3(0, 34.0, 0.2), n, 3.0, 2.6, 0.25)
		LandmarkChParts.corbels(lm, "White", face + b * Vector3(-hw + 0.5, sh, 0), face + b * Vector3(hw - 0.5, sh, 0),
			n * 0.8, 1.0, 1.0)
	lm.box("White", p + Vector3(0, sh + 0.3, 0), Vector3(hw * 2.0 + 1.6, 0.6, hw * 2.0 + 1.6))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.tracery_parapet(lm, "White", p + b * Vector3(-hw - 0.6, sh + 0.6, hw + 0.65),
			p + b * Vector3(hw + 0.6, sh + 0.6, hw + 0.65), 1.2, 1.1, 0.22)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkChParts.pinnacle(lm, "White", p + Vector3(sx * (hw + 0.2), sh + 0.6, sz * (hw + 0.2)), 1.0, 7.0)
	# Octagonal stages with balcony galleries.
	var y := sh + 0.6
	for st in [[4.6, 9.0], [3.8, 7.0]]:
		var r: float = st[0]
		var h: float = st[1]
		lm.frustum("Wall", p + Vector3(0, y, 0), r, r, h, 8, PI / 8.0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkChParts.lancet(lm, "White", "Windows", p + d * r * 0.92 + Vector3(0, y + 1.0, 0), d, r * 0.42,
				h - 3.0, 1 if r > 4.0 else 0, 0.25)
			LandmarkChParts.wimperg(lm, "White", p + d * r * 0.92 + Vector3(0, y + h - 2.2, 0), d, r * 0.6, 1.9, 0.2)
		y += h
		lm.frustum("White", p + Vector3(0, y, 0), r + 0.9, r + 0.9, 0.5, 8, PI / 8.0)
		for k in 8:
			var a0 := TAU * (float(k) - 0.5) / 8.0 + PI / 8.0
			var a1 := TAU * (float(k) + 0.5) / 8.0 + PI / 8.0
			var rr := (r + 0.75) / cos(PI / 8.0)
			LandmarkChParts.tracery_parapet(lm, "White", p + Vector3(cos(a0) * rr, y + 0.5, sin(a0) * rr),
				p + Vector3(cos(a1) * rr, y + 0.5, sin(a1) * rr), 1.0, 0.9, 0.18)
		y += 0.5
	# Spire with crockets up its eight arrises, then the finial.
	var spire_h := BASTION_SPIRE_TOP - y
	lm.lathe("Spire", p + Vector3(0, y, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(2.8, spire_h * 0.25),
		Vector2(1.6, spire_h * 0.6), Vector2(0.6, spire_h * 0.88), Vector2(0.12, spire_h)]), 8, 1.0, 1.0, 0.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for i in 8:
			var t := (float(i) + 0.7) / 9.0
			var rr := lerpf(3.6, 0.3, t)
			lm.box("Spire", p + d * (rr + 0.12) + Vector3(0, y + spire_h * t, 0), Vector3(0.4, 0.35, 0.4),
				Basis(Vector3.UP, -a), 0.0)
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var lc := p + d * 2.9 + Vector3(0, y + 2.0, 0)
		var b := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("White", lc, Vector3(1.2, 2.4, 0.9), b)
		LandmarkChParts.wimperg(lm, "White", lc + d * 0.45 + Vector3(0, 1.2, 0), d, 1.3, 1.5, 0.15)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, BASTION_SPIRE_TOP - 0.3, 0),
		LandmarkChBudapest.BASTION_TOP - BASTION_SPIRE_TOP + 0.3, 0.45)

## Spire tip below the gilt finial and cross.
const BASTION_SPIRE_TOP := 76.5

## Bela tower: low square Romanesque tower with arched twin windows and
## a pyramid cap, at the north west corner.
static func _bela_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var hw := 3.4
	var h := 26.0
	lm.box("Wall", p + Vector3(0, h * 0.5, 0), Vector3(hw * 2.0, h, hw * 2.0))
	for y in [8.0, 16.0]:
		LandmarkChParts.band(lm, "White", y, hw, hw, 0.4, 0.2, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, hw)
		LandmarkChParts.arched_window(lm, "White", "Windows", face + Vector3(0, 10.0, 0), n, 0.9, 3.0, 0.2)
		for x in [-0.7, 0.7]:
			LandmarkChParts.arched_window(lm, "White", "Windows", face + b * Vector3(x, 18.5, 0), n, 0.9, 3.4, 0.22)
		for i in 5:
			LandmarkChParts.arched_window(lm, "White", "Wall", face + b * Vector3(-2.4 + 1.2 * i, h - 1.6, 0), n,
				0.8, 1.0, 0.12, 4)
	lm.box("White", p + Vector3(0, h + 0.25, 0), Vector3(hw * 2.0 + 0.6, 0.5, hw * 2.0 + 0.6))
	lm.spire("Roof", p + Vector3(0, h + 0.5, 0), hw + 0.4, 8.0)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + 8.5, 0), 1.8, 0.3)
