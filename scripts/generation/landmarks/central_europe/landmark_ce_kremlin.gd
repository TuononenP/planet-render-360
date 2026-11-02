class_name LandmarkCeKremlin
extends RefCounted

## Red Square in true metres: Saint Basil's Cathedral (1555-61: the
## tent-roofed Church of the Intercession, 47.5 m, ringed by four tall
## axial and four smaller diagonal chapels under striped onion domes,
## all on an arcaded gallery podium, with the bell tower) and the
## Spasskaya Tower of the Kremlin wall (1491 gate tower crowned in
## 1625 with the white-stone pinnacled stage, four 6 m clock faces,
## the octagonal belfry, tent spire and 3.75 m ruby star, 71 m).

const BASIL_TOP := 47.2
const BASIL_PODIUM := 6.0

static func basil(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B0493B", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EFE8DA", 3.0))
	lm.use("Tent", LandmarkMaterials.pbr("terracotta", "#A8442F", 2.5))
	lm.use("DomeRed", LandmarkMaterials.pbr("terracotta", "#B8362B", 2.0, 0.45, 0.2))
	lm.use("DomeGreen", LandmarkMaterials.pbr("concrete", "#3E8F55", 2.0, 0.45, 0.3))
	lm.use("DomeBlue", LandmarkMaterials.pbr("concrete", "#3A6FAE", 2.0, 0.45, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Podium", LandmarkMaterials.pbr("stone", "#C2B8A6", 3.0))
	_basil_podium(lm)
	var p := BASIL_PODIUM
	# Central church: octagonal shaft, three tiers of kokoshniki, the
	# white-ribbed tent with its diamond studs, lantern and gilt onion.
	lm.frustum("Brick", Vector3(0, p, 0), 8.6, 8.0, 22.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "White", "Windows", Vector3(0, p + 12.0, 0) + d * 7.5, d, 1.2, 3.2, true, 0.25)
		var ca := a + PI / 8.0
		lm.box("White", Vector3(0, p + 11.0, 0) + Vector3(cos(ca), 0, sin(ca)) * 8.2, Vector3(0.6, 22.0, 0.6),
			Basis(Vector3.UP, -ca), 0.0)
	for tier in 3:
		var ty := p + 20.0 + 2.6 * tier
		var tr := 8.1 - 0.5 * tier
		lm.frustum("White", Vector3(0, ty, 0), tr + 0.5, tr + 0.4, 0.4, 8, PI / 8.0)
		_kokoshniki(lm, "White", Vector3(0, ty + 0.4, 0), tr, 8, 2.6, PI / 8.0 * float(tier % 2))
	lm.frustum("Brick", Vector3(0, p + 22.0, 0), 8.0, 7.0, 8.0, 8, PI / 8.0)
	lm.lathe("Tent", Vector3(0, p + 30.0, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(4.8, 3.1),
		Vector2(2.6, 6.2), Vector2(1.9, 7.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var b0 := Vector3(0, p + 30.0, 0) + d * 7.1
		var b1 := Vector3(0, p + 37.0, 0) + d * 2.0
		lm.beam("White", b0, b1, 0.4, 0.3)
		# Diamond studs on each face of the tent.
		var fa := a + PI / 8.0
		var fd := Vector3(cos(fa), 0, sin(fa))
		for j in 4:
			var t := (float(j) + 0.5) / 4.5
			var rr := lerpf(6.4, 1.9, t)
			lm.box("Gilt", Vector3(0, p + 30.0 + 7.0 * t, 0) + fd * rr, Vector3(0.35, 0.35, 0.35),
				Basis(fd, PI * 0.25) * Basis(Vector3.UP, -fa), 0.0)
	lm.frustum("White", Vector3(0, p + 37.0, 0), 2.2, 2.0, 0.5, 8, PI / 8.0)
	lm.frustum("Brick", Vector3(0, p + 37.5, 0), 1.8, 1.8, 0.8, 12)
	LandmarkCeParts.onion(lm, "Gilt", Vector3(0, p + 38.3, 0), 1.9, 1.8, 12)
	LandmarkCeParts.cross(lm, "Gilt", Vector3(0, p + 39.9, 0), BASIL_TOP - p - 39.9)
	# Four tall axial chapels and four small diagonal ones.
	var big := [["DomeGreen", "Gilt"], ["Gilt", "DomeGreen"], ["DomeBlue", "White"], ["DomeRed", "DomeGreen"]]
	var small := [["DomeRed", "White"], ["DomeGreen", "DomeRed"], ["Gilt", "DomeBlue"], ["DomeBlue", "DomeGreen"]]
	var heights := [21.0, 23.0, 19.0, 22.0]
	for k in 4:
		var a := PI * 0.5 * k
		_chapel(lm, Vector3(cos(a) * 17.0, p, sin(a) * 17.0), 5.6, heights[k], big[k][0], big[k][1], 4.6, 7.0)
		var b := a + PI * 0.25
		_chapel(lm, Vector3(cos(b) * 15.0, p, sin(b) * 15.0), 3.8, 15.0 + k, small[k][0], small[k][1], 3.0, 5.0)
	# Bell tower: square base, octagonal arcaded belfry, tent and onion.
	var bt := Vector3(-14.0, 0, 26.0)
	lm.box("Brick", bt + Vector3(0, 6.0, 0), Vector3(7.0, 12.0, 7.0))
	lm.frustum("White", bt + Vector3(0, 12.0, 0), 3.9, 3.8, 0.6, 8, PI / 8.0)
	lm.frustum("Brick", bt + Vector3(0, 12.6, 0), 3.4, 3.3, 7.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Windows", bt + d * 3.15 + Vector3(0, 15.6, 0), Vector3(1.4, 3.6, 0.1), Basis(Vector3.UP, PI * 0.5 - a), 0.0)
		LandmarkDetail.arch(lm, "White", bt + d * 3.15 + Vector3(0, 17.4, 0), d, 1.4, 0.2, 0.2)
	lm.frustum("White", bt + Vector3(0, 19.6, 0), 3.8, 3.6, 0.5, 8, PI / 8.0)
	lm.lathe("Tent", bt + Vector3(0, 20.1, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(1.0, 8.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		lm.box("Windows", bt + Vector3(cos(a) * 2.3, 23.0, sin(a) * 2.3), Vector3(0.4, 0.7, 0.05),
			Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	LandmarkCeParts.onion(lm, "Gilt", bt + Vector3(0, 28.0, 0), 1.0, 1.4, 12)
	LandmarkCeParts.cross(lm, "Gilt", bt + Vector3(0, 29.2, 0), 1.6)
	lm.commit(model)

## Raised platform with the open arcaded gallery round the chapels and
## the two covered stairs (north and west) under small tents.
static func _basil_podium(lm: LandmarkMesh) -> void:
	var p := BASIL_PODIUM
	lm.box("Podium", Vector3(0, p * 0.5, 2.0), Vector3(54.0, p, 60.0))
	lm.box("White", Vector3(0, p - 0.2, 2.0), Vector3(54.6, 0.4, 60.6), Basis(), 0.0)
	for f in 4:
		var n := [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK][f] as Vector3
		var half := 30.0 if f < 2 else 27.0
		var out := 27.0 if f < 2 else 30.0
		var r := Vector3.UP.cross(n).normalized()
		var c := Vector3(0, 0, 2.0) + n * out
		var cnt := int(half * 2.0 / 3.6)
		for i in cnt:
			var q := c + r * (-half + 3.6 * (float(i) + 0.5))
			lm.box("Windows", q + Vector3(0, 2.4, 0) + n * 0.02, Vector3(1.8, 2.6, 0.05), Basis(r, Vector3.UP, n), 0.0)
			LandmarkDetail.arch(lm, "White", q + Vector3(0, 3.7, 0), n, 1.8, 0.25, 0.2)
	# Covered staircases (north and west): eight flights of steps up to
	# the gallery under a brick porch on four piers and a small tent.
	for s in [[Vector3(-27.0, 0, -8.0), Vector3.LEFT], [Vector3(10.0, 0, -28.0), Vector3.FORWARD]]:
		var sc: Vector3 = s[0]
		var sn: Vector3 = s[1]
		var sr := Vector3.UP.cross(sn).normalized()
		var sb := Basis(sr, Vector3.UP, sn)
		for k in 8:
			var sh := 0.75 * float(k + 1)
			lm.box("Podium", sc + sn * (5.2 - 0.65 * (float(k) + 0.5)) + Vector3(0, sh * 0.5, 0), Vector3(3.4, sh, 0.65), sb, 0.0)
		for e in [-1.0, 1.0]:
			for t in [0.4, 4.8]:
				lm.box("Brick", sc + sn * t + sr * e * 2.0 + Vector3(0, 4.5, 0), Vector3(0.7, 9.0, 0.7), sb)
		lm.box("Brick", sc + sn * 2.6 + Vector3(0, 9.8, 0), Vector3(4.8, 1.6, 5.4), sb)
		lm.lathe("Tent", sc + sn * 2.6 + Vector3(0, 10.6, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(0.6, 5.5)]),
			8, 1.0, 1.0, PI / 8.0, false)
		LandmarkCeParts.onion(lm, "DomeGreen", sc + sn * 2.6 + Vector3(0, 16.1, 0), 0.8, 1.2, 10)
		LandmarkCeParts.cross(lm, "Gilt", sc + sn * 2.6 + Vector3(0, 17.2, 0), 1.2)

## Ring of `count` kokoshniki (ogee-headed gables) round an octagon of
## radius r at `c`, each `h` tall, as framed arches with a pointed top.
static func _kokoshniki(lm: LandmarkMesh, key: String, c: Vector3, r: float, count: int, h: float,
		phase: float) -> void:
	for i in count:
		var a := phase + TAU * (float(i) + 0.5) / float(count)
		var d := Vector3(cos(a), 0, sin(a))
		var rt := d.cross(Vector3.UP).normalized()
		var w := TAU * r / float(count) * 0.46
		var b := c + d * (r * cos(PI / float(count)) + 0.15)
		var prev := b - rt * w
		for k in 7:
			var t := float(k + 1) / 7.0
			var x := lerpf(-w, w, t)
			var y := h * (0.75 * sin(PI * t) + (0.25 if absf(x) < w * 0.2 else 0.0) * (1.0 - absf(x) / (w * 0.2)))
			var q := b + rt * x + Vector3(0, y, 0)
			lm.beam(key, prev, q, 0.3, 0.3, d)
			prev = q
		lm.box(key, b + Vector3(0, h * 0.4, 0) - d * 0.05, Vector3(w * 1.6, h * 0.8, 0.15),
			Basis(rt, Vector3.UP, d), 0.0)

## One chapel: brick octagon with white bands and windows, a kokoshnik
## crown, the arcaded drum and a striped onion of `dome` with spiral
## bands of `stripe`, and a gilt cross.
static func _chapel(lm: LandmarkMesh, base: Vector3, r: float, h: float, dome: String, stripe: String,
		dome_r: float, dome_h: float) -> void:
	lm.frustum("Brick", base, r, r * 0.95, h, 8, PI / 8.0)
	for y in [h * 0.35, h * 0.68]:
		lm.frustum("White", base + Vector3(0, y, 0), r * 1.05, r * 1.04, 0.6, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "White", "Windows", base + d * (r * 0.92) + Vector3(0, h * 0.52, 0), d,
			r * 0.17, r * 0.45, true, 0.15)
	_kokoshniki(lm, "White", base + Vector3(0, h * 0.75, 0), r * 0.92, 8, h * 0.15, 0.0)
	# Drum with blind arcading.
	var dr := dome_r * 0.62
	var db := base + Vector3(0, h, 0)
	lm.frustum("Brick", db, dr, dr, 3.0, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("White", db + d * (dr + 0.05) + Vector3(0, 0.4, 0), db + d * (dr + 0.05) + Vector3(0, 2.3, 0), 0.18, 0.18)
	lm.frustum("White", db + Vector3(0, 2.6, 0), dr * 1.08, dr * 1.08, 0.4, 16)
	var ob := db + Vector3(0, 3.0, 0)
	LandmarkCeParts.onion(lm, dome, ob, dome_r * 0.52, dome_h * 0.52, 20, true)
	# Spiral stripes following the onion's profile.
	var prof := [[0.55, 0.0], [0.85, 0.07], [1.0, 0.24], [0.92, 0.42], [0.58, 0.62], [0.22, 0.82]]
	var rr := dome_r * 0.52
	var hh := dome_h * 0.52
	for k in 8:
		var prev := Vector3.ZERO
		for j in prof.size():
			var a := TAU * float(k) / 8.0 + 1.6 * float(j) / float(prof.size() - 1)
			var q := ob + Vector3(cos(a) * rr * float(prof[j][0]) * 1.03, hh * float(prof[j][1]), sin(a) * rr * float(prof[j][0]) * 1.03)
			if j > 0:
				lm.beam(stripe, prev, q, rr * 0.16, 0.08, (q - ob - Vector3(0, q.y - ob.y, 0)).normalized())
			prev = q
	LandmarkCeParts.cross(lm, "Gilt", ob + Vector3(0, hh * 0.95, 0), maxf(dome_h * 0.25, 1.4))

# --- Spasskaya Tower ---

const SPAS_TOP := 71.0

static func spasskaya(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8443A", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE6D6", 3.0))
	lm.use("Tent", LandmarkMaterials.pbr("terracotta", "#B0472F", 2.5))
	lm.use("Face", LandmarkMaterials.pbr("render", "#F3EEDF", 2.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Star", LandmarkMaterials.lit("#C3262E", 0.7))
	# The Kremlin wall with swallowtail merlons, running east-west.
	lm.box("Brick", Vector3(0, 4.0, 0), Vector3(90.0, 8.0, 6.0))
	for sx in [-1.0, 1.0]:
		for i in 14:
			var x: float = sx * (10.5 + 2.4 * i)
			for sz in [-1.0, 1.0]:
				_swallowtail(lm, Vector3(x, 8.0, sz * 2.6), 1.4, 2.2)
	# Gate shaft with the passage arch and the gate icon frame.
	lm.box("Brick", Vector3(0, 15.0, 0), Vector3(14.0, 30.0, 14.0))
	for f in 2:
		var r := Basis(Vector3.UP, PI * f)
		var n := r * Vector3(0, 0, 1)
		lm.box("Windows", r * Vector3(0, 4.0, 7.02), Vector3(4.4, 8.0, 0.05), r, 0.0)
		LandmarkDetail.arch(lm, "White", r * Vector3(0, 8.0, 7.0), n, 4.4, 0.6, 0.4)
		lm.box("Face", r * Vector3(0, 12.4, 7.02), Vector3(2.4, 2.8, 0.05), r, 0.0)
		lm.box("White", r * Vector3(0, 12.4, 7.1), Vector3(3.0, 3.4, 0.1), r, 0.0)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		for k in [-1.0, 1.0]:
			LandmarkDetail.window(lm, "White", "Windows", r * Vector3(k * 3.6, 21.0, 7.0), n, 0.9, 2.2, true, 0.2)
		for k in 6:
			lm.box("White", r * Vector3(-5.5 + 2.2 * k, 27.5, 7.15), Vector3(0.2, 3.0, 0.3), r, 0.0)
		# Machicolation corbels under the parapet walk.
		for k in 8:
			lm.box("Brick", r * Vector3(-6.1 + 1.75 * k, 29.4, 7.3), Vector3(0.6, 0.8, 0.6), r, 0.0)
	lm.box("White", Vector3(0, 30.4, 0), Vector3(15.2, 0.8, 15.2))
	# 1625 stage: arcaded white-stone lace, corner turrets and pinnacles.
	lm.box("Brick", Vector3(0, 34.6, 0), Vector3(12.6, 7.6, 12.6))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		for k in 3:
			var p := r * Vector3(-4.0 + 4.0 * k, 32.0, 6.3)
			lm.box("Windows", p + Vector3(0, 1.6, 0) + n * 0.02, Vector3(1.6, 3.2, 0.05), r, 0.0)
			LandmarkDetail.arch(lm, "White", p + Vector3(0, 3.2, 0), n, 1.6, 0.25, 0.25)
			LandmarkCeParts.wimperg(lm, "White", p + Vector3(0, 4.4, 0), n, 2.2, 1.6, 0.25)
		for k in [-1.0, 1.0]:
			LandmarkCeParts.pinnacle(lm, "White", r * Vector3(k * 6.6, 30.8, 6.6), 0.9, 5.4)
		LandmarkDetail.balustrade(lm, "White", r * Vector3(-6.3, 38.4, 6.4), r * Vector3(6.3, 38.4, 6.4), 0.9, 3.15)
	# Clock stage: four 6.1 m faces with hour marks and hands.
	lm.box("Brick", Vector3(0, 44.6, 0), Vector3(11.0, 12.4, 11.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		var cc := Vector3(0, 44.2, 0) + n * 5.52
		lm.box("White", cc - n * 0.04, Vector3(7.4, 7.4, 0.1), r, 0.0)
		lm.disc("Face", cc + n * 0.03, n, 3.05, 32)
		lm.frustum("Gilt", cc - n * 0.0, 3.2, 3.2, 0.01, 32)
		for k in 12:
			var a := TAU * float(k) / 12.0
			var rt := r * Vector3(1, 0, 0)
			lm.box("Gilt", cc + n * 0.06 + (rt * cos(a) + Vector3.UP * sin(a)) * 2.6, Vector3(0.3, 0.3, 0.05),
				Basis(n, a) * r, 0.0)
		lm.beam("Gilt", cc + n * 0.09, cc + n * 0.09 + (r * Vector3(1, 0, 0) * 0.7 + Vector3.UP * 0.7).normalized() * 1.6, 0.18, 0.05, n)
		lm.beam("Gilt", cc + n * 0.11, cc + n * 0.11 + Vector3.UP * 2.4, 0.12, 0.05, n)
		for k in [-1.0, 1.0]:
			LandmarkCeParts.pinnacle(lm, "White", r * Vector3(k * 5.7, 50.8, 5.7), 0.8, 4.0)
	lm.box("White", Vector3(0, 51.0, 0), Vector3(12.4, 0.8, 12.4))
	# Octagonal belfry with arched openings, gallery and the tent.
	lm.frustum("Brick", Vector3(0, 51.4, 0), 5.9, 5.5, 7.4, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Windows", d * 5.3 + Vector3(0, 54.6, 0), Vector3(1.8, 3.6, 0.05), Basis(Vector3.UP, PI * 0.5 - a), 0.0)
		LandmarkDetail.arch(lm, "White", d * 5.35 + Vector3(0, 56.4, 0), d, 1.8, 0.25, 0.25)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.box("White", Vector3(cos(a), 0, sin(a)) * 5.8 + Vector3(0, 55.1, 0), Vector3(0.5, 7.4, 0.5), Basis(Vector3.UP, -a), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var q := Vector3(sx * 5.4, 51.4, sz * 5.4)
			lm.frustum("White", q, 0.9, 0.7, 4.0, 8)
			lm.spire("Tent", q + Vector3(0, 4.0, 0), 1.0, 3.5, 0.0, 8)
			lm.box("Gilt", q + Vector3(0, 7.6, 0), Vector3(0.15, 0.6, 0.15), Basis(), 0.0)
	lm.frustum("White", Vector3(0, 58.8, 0), 6.2, 6.2, 0.6, 8, PI / 8.0)
	lm.lathe("Tent", Vector3(0, 59.4, 0), PackedVector2Array([Vector2(5.8, 0), Vector2(4.8, 2.4), Vector2(2.6, 6.0),
		Vector2(1.2, 8.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("White", d * 5.9 + Vector3(0, 59.4, 0), d * 1.3 + Vector3(0, 67.8, 0), 0.25, 0.2)
		var fa := a + PI / 8.0
		lm.box("Windows", Vector3(cos(fa), 0, sin(fa)) * 3.6 + Vector3(0, 63.4, 0), Vector3(0.6, 1.0, 0.05),
			Basis(Vector3.UP, PI * 0.5 - fa), 0.0)
	lm.frustum("Gilt", Vector3(0, 67.6, 0), 0.5, 0.35, 1.2, 8)
	lm.lathe("Gilt", Vector3(0, 66.8, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.7, 0.4), Vector2(0.4, 0.8)]), 10)
	# Ruby star (3.75 m) on the finial: five faceted rays, front and back.
	var sc := Vector3(0, SPAS_TOP - 1.85, 0)
	for k in 5:
		var a := TAU * k / 5.0
		var d := Vector3(sin(a), cos(a), 0)
		var side := Vector3(cos(a), -sin(a), 0)
		for s in [-1.0, 1.0]:
			lm.tri("Star", sc + Vector3(0, 0, s * 0.3), sc + d * 1.85, sc + side * 0.7 + d * 0.5,
				Vector3(0, 0, s), Vector3(0, 0, s), Vector3(0, 0, s), Vector2.ZERO, Vector2(0, 1.85), Vector2(0.7, 0.5))
			lm.tri("Star", sc + Vector3(0, 0, s * 0.3), sc + d * 1.85, sc - side * 0.7 + d * 0.5,
				Vector3(0, 0, s), Vector3(0, 0, s), Vector3(0, 0, s), Vector2.ZERO, Vector2(0, 1.85), Vector2(-0.7, 0.5))
		lm.beam("Gilt", sc + d * 1.85, sc + side * 0.75 + d * 0.5, 0.08, 0.6)
		lm.beam("Gilt", sc + d * 1.85, sc - side * 0.75 + d * 0.5, 0.08, 0.6)
	lm.commit(model)

## A Kremlin swallowtail merlon: a pier `w` wide forking into two horns.
static func _swallowtail(lm: LandmarkMesh, base: Vector3, w: float, h: float) -> void:
	lm.box("Brick", base + Vector3(0, h * 0.35, 0), Vector3(w, h * 0.7, 0.8))
	for s in [-1.0, 1.0]:
		lm.beam("Brick", base + Vector3(s * w * 0.18, h * 0.7, 0), base + Vector3(s * w * 0.5, h, 0), w * 0.35, 0.8)
