class_name LandmarkEahLeshan
extends RefCounted

## The Leshan Giant Buddha in true metres (71 m: the seated Maitreya
## carved 713-803 out of the red sandstone cliff at the meeting of the
## Min and Dadu rivers, river level at y = 0): shoulders 28 m across, the
## head 14.7 m high and 10 m wide under 1,021 spiral curls, 7 m ears,
## 5.6 m nose and brows, 3.3 m eyes and mouth, hands resting on the knees
## with 8.3 m fingers, an 8.5 m instep; the robe falls in diagonal folds
## from the left shoulder. The cliff niche steps forward either side,
## with a guardian figure carved on each flank and the Nine-Turn Plank
## Road zig-zagging down the north cliff. The front faces +Z; the
## registry yaw turns it onto the river.

const LESHAN_M := 71.0
const CURLS := 1021
const HEAD := Vector3(0, 61.4, 4.2)

static func leshan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7A5B46", 6.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8A688", 3.0))
	lm.use("Hair", LandmarkMaterials.pbr("rock", "#5B4B3D", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#2A231C", 0.9, 0.0))
	_cliff(lm)
	_body(lm)
	_head(lm)
	lm.commit(model)

## The cliff: back wall of the niche (top level with the crown), three
## stepped flanks coming forward either side, the riverside platform at
## the feet, the guardians and the plank road.
static func _cliff(lm: LandmarkMesh) -> void:
	LandmarkEahParts.slab(lm, "Rock", Vector3(-22.0, 0.0, -48.0), Vector3(22.0, 70.0, -4.0))
	var tiers := [[22.0, 10.0, 0.0, 44.0], [24.0, -2.0, 44.0, 58.0], [30.0, -14.0, 58.0, 66.0]]
	for s in [-1.0, 1.0]:
		for t in tiers:
			var xi: float = float(t[0]) * s
			LandmarkEahParts.slab(lm, "Rock", Vector3(minf(xi, 56.0 * s), float(t[2]), -48.0),
				Vector3(maxf(xi, 56.0 * s), float(t[3]), float(t[1])))
		# Weathered ledges on the south niche wall (the plank road takes
		# the north one).
		for k in (6 if s < 0.0 else 0):
			var y := 6.0 + 6.5 * k
			LandmarkEahParts.slab(lm, "Rock", Vector3(minf(s * 21.0, s * 22.5), y, -4.0),
				Vector3(maxf(s * 21.0, s * 22.5), y + 1.2, 9.0 - 0.6 * k))
		# Guardian (dharmapala) in a niche on each flank, about 16 m.
		LandmarkEahParts.slab(lm, "Shadow", Vector3(s * 23.0 - 3.5, 12.0, 9.9), Vector3(s * 23.0 + 3.5, 31.0, 10.05))
		LandmarkEahParts.slab(lm, "Rock", Vector3(s * 23.0 - 3.0, 11.0, 9.0), Vector3(s * 23.0 + 3.0, 12.5, 13.5))
		LandmarkKits.statue_figure(lm, "Stone", Vector3(s * 23.0, 12.5, 11.2), 17.0, false)
	# Riverside platform at the feet.
	LandmarkEahParts.slab(lm, "Rock", Vector3(-26.0, 0.0, 10.0), Vector3(26.0, 1.0, 40.0))
	# The Nine-Turn Plank Road: nine flights down the north (+X) cliff
	# face of the niche, each with a landing and an outer railing.
	var top := 44.0
	for f in 9:
		var y0 := top - f * 4.8
		var dir := 1.0 if f % 2 == 0 else -1.0
		var za := 8.0 - dir * 7.0
		var zb := 8.0 + dir * 7.0
		for k in 14:
			var t := float(k) / 14.0
			var z := lerpf(za, zb, t)
			lm.box("Stone", Vector3(21.2, y0 - 4.8 * t - 0.2, z), Vector3(1.6, 0.35, 1.0), Basis(), 0.0)
		lm.beam("Stone", Vector3(20.45, y0 + 0.9, za), Vector3(20.45, y0 - 3.9, zb), 0.1, 0.1)
		LandmarkEahParts.slab(lm, "Stone", Vector3(20.4, y0 - 5.0, zb - 1.0), Vector3(22.0, y0 - 4.8, zb + 1.0))

## Body: legs, feet with toes, torso with robe folds, arms and hands.
static func _body(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var x: float = s * 8.6
		# Foot (instep 8.5 m) on the platform, toes with nails.
		lm.box("Stone", Vector3(x, 2.6, 27.5), Vector3(8.5, 3.2, 11.0))
		for toe in 5:
			var tx := x + (toe - 2) * 1.55
			lm.box("Stone", Vector3(tx, 2.2, 33.2), Vector3(1.3, 2.4, 1.6))
			lm.box("Hair", Vector3(tx, 2.6, 34.02), Vector3(0.9, 0.9, 0.06), Basis(), 0.0)
		LandmarkAeParts.batter(lm, "Stone", x, 23.0, 8.6, 6.0, 10.2, 8.0, 4.0, 24.0)
		lm.box("Stone", Vector3(x, 26.5, 15.0), Vector3(10.8, 7.0, 25.0))
		# Vertical robe folds down the shins, the hem over the feet.
		for k in 4:
			var fx := x + (k - 1.5) * 2.3
			LandmarkAeParts.tube(lm, "Stone", Vector3(fx, 5.0, 27.8 + 0.4 * absf(k - 1.5)), Vector3(fx, 22.5, 27.3), 0.4, 0.3, 6)
		lm.beam("Stone", Vector3(x - 5.0, 4.6, 27.6), Vector3(x + 5.0, 4.6, 27.6), 0.8, 1.4)
	# Torso (28 m across the shoulders), neck with its three folds.
	var torso := PackedVector2Array([Vector2(11.5, 0), Vector2(12.2, 6.0), Vector2(12.8, 14.0),
		Vector2(13.6, 24.0), Vector2(14.0, 29.5), Vector2(11.0, 31.0), Vector2(6.0, 32.0), Vector2(3.6, 32.5)])
	lm.lathe("Stone", Vector3(0, 24.0, 3.0), torso, 32, 1.0, 0.52)
	lm.frustum("Stone", Vector3(0, 56.0, 4.0), 3.6, 3.2, 1.4, 16)
	for k in 3:
		lm.frustum("Stone", Vector3(0, 55.4 + 0.5 * k, 4.0), 3.75 - 0.1 * k, 3.75 - 0.1 * k, 0.18, 16)
	# Robe folds: diagonal from the left shoulder across the chest and
	# belly, following the torso surface; the hem of the robe at the collar.
	for f in 11:
		var yf := 51.0 - 2.4 * f
		var pts: Array[Vector3] = []
		for i in 13:
			var a := lerpf(0.25, PI - 0.25, float(i) / 12.0)
			var y := yf + 4.5 * (float(i) / 12.0 - 0.5)
			var r := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 11.5), Vector2(6, 12.2),
				Vector2(14, 12.8), Vector2(24, 13.6), Vector2(29.5, 14.0)]), y - 24.0)
			pts.append(Vector3(cos(a) * r, y, 3.0 + sin(a) * r * 0.52 + 0.15))
		for i in 12:
			LandmarkAeParts.tube(lm, "Stone", pts[i], pts[i + 1], 0.42, 0.42, 6)
	for i in 16:
		var a0 := lerpf(0.15, PI - 0.15, float(i) / 16.0)
		var a1 := lerpf(0.15, PI - 0.15, float(i + 1) / 16.0)
		var p0 := Vector3(cos(a0) * 5.8, 55.0 - 2.5 * sin(a0), 4.0 + sin(a0) * 4.6)
		var p1 := Vector3(cos(a1) * 5.8, 55.0 - 2.5 * sin(a1), 4.0 + sin(a1) * 4.6)
		LandmarkAeParts.tube(lm, "Stone", p0, p1, 0.6, 0.6, 8)
	# Arms: upper arm down the flank, forearm forward, the hand resting on
	# the knee: palm, four 8.3 m fingers and the thumb.
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(s * 13.2, 53.5, 3.0), Vector3(s * 13.6, 38.5, 5.5), 4.8, 5.2, Vector3(1, 0, 0))
		lm.beam("Stone", Vector3(s * 13.4, 38.5, 5.5), Vector3(s * 10.5, 32.5, 20.0), 4.2, 4.2, Vector3(1, 0, 0))
		LandmarkAeParts.ball(lm, "Stone", Vector3(s * 13.4, 38.5, 5.5), 2.4, 12, 6)
		lm.box("Stone", Vector3(s * 10.4, 31.2, 21.4), Vector3(4.6, 2.0, 3.6))
		for k in 4:
			var fx: float = s * (8.6 + 1.15 * k)
			var a := Vector3(fx, 31.0, 23.0)
			var b := Vector3(fx, 30.4, 31.0)
			LandmarkAeParts.tube(lm, "Stone", a, b, 0.55, 0.5, 8)
			LandmarkAeParts.ball(lm, "Stone", b, 0.5, 8, 4)
		LandmarkAeParts.tube(lm, "Stone", Vector3(s * 8.2, 31.3, 21.0), Vector3(s * 7.4, 30.9, 25.5), 0.6, 0.55, 8)

## Head 14.7 m high (10 m wide): face ellipsoid, hair cap of 1,021
## curls, crowning bun, long ears, nose, brows, eyes, mouth.
static func _head(lm: LandmarkMesh) -> void:
	var face := PackedVector2Array()
	for j in 15:
		var phi := PI * float(j) / 14.0
		face.append(Vector2(5.0 * sin(phi), -5.2 * cos(phi)))
	lm.lathe("Stone", HEAD, face, 28, 1.0, 1.08)
	var cap_c := HEAD + Vector3(0, 3.2, 0)
	var cap := PackedVector2Array()
	for j in 9:
		var a := PI * 0.5 * float(j) / 8.0
		cap.append(Vector2(5.2 * cos(a), 5.0 * sin(a)))
	lm.lathe("Hair", cap_c, cap, 28, 1.0, 1.08)
	var bun := HEAD + Vector3(0, 8.0, 0)
	lm.lathe("Hair", bun, PackedVector2Array([Vector2(2.6, 0), Vector2(2.5, 0.5), Vector2(2.2, 1.0),
		Vector2(1.2, 1.45), Vector2(0.0, LESHAN_M - bun.y)]), 16)
	_curls(lm, cap_c, bun)
	# Ears: long lobes hanging to the jaw.
	for s in [-1.0, 1.0]:
		var ex: float = s * 5.4
		lm.beam("Stone", Vector3(ex, 64.0, 4.6), Vector3(ex + s * 0.3, 57.4, 4.9), 1.3, 1.8, Vector3.FORWARD)
		LandmarkAeParts.ball(lm, "Stone", Vector3(ex + s * 0.3, 57.4, 4.9), 0.95, 10, 5)
		lm.box("Shadow", Vector3(ex + s * 0.68, 61.0, 4.8), Vector3(0.06, 3.6, 0.7), Basis(), 0.0)
		# Brows (5.6 m), half-closed eyes (3.3 m) with lids, cheeks.
		lm.beam("Stone", Vector3(s * 0.6, 63.0, 9.6), Vector3(s * 4.2, 63.6, 8.7), 0.55, 0.7, Vector3.UP)
		lm.box("Shadow", Vector3(s * 2.3, 61.9, 9.62), Vector3(3.3, 0.35, 0.3), Basis(Vector3.FORWARD, -s * 0.06), 0.0)
		lm.beam("Stone", Vector3(s * 0.7, 62.25, 9.55), Vector3(s * 3.9, 62.1, 9.0), 0.45, 0.5, Vector3.UP)
		LandmarkAeParts.ball(lm, "Stone", Vector3(s * 2.6, 59.0, 8.6), 1.4, 10, 5)
	# Nose (5.6 m) with nostrils, lips (3.3 m), chin.
	lm.beam("Stone", Vector3(0, 63.0, 9.6), Vector3(0, 58.2, 10.6), 1.0, 1.0, Vector3.RIGHT)
	lm.box("Stone", Vector3(0, 58.1, 10.2), Vector3(2.0, 0.9, 1.0))
	for s in [-1.0, 1.0]:
		lm.box("Shadow", Vector3(s * 0.45, 57.7, 10.2), Vector3(0.4, 0.12, 0.3), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 56.9, 9.65), Vector3(3.3, 0.45, 0.6), Basis(), 0.0)
	lm.box("Shadow", Vector3(0, 56.6, 9.65), Vector3(3.3, 0.12, 0.4), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 56.3, 9.6), Vector3(2.8, 0.45, 0.55), Basis(), 0.0)
	LandmarkAeParts.ball(lm, "Stone", Vector3(0, 55.2, 9.0), 1.2, 10, 5)

## The 1,021 spiral curls: rings on the hair cap (from the hairline up)
## and on the bun, as many per ring as its circumference allows.
static func _curls(lm: LandmarkMesh, cap_c: Vector3, bun: Vector3) -> void:
	var bun_rings := [[2.55, 0.25, 15], [2.3, 0.85, 13], [1.6, 1.35, 9], [0.0, 1.35, 1]]
	var on_bun := 0
	for b in bun_rings:
		on_bun += int(b[2])
	var rows := 14
	var weights: Array[float] = []
	var total := 0.0
	for j in rows:
		var th := deg_to_rad(78.0) * (float(j) + 0.3) / float(rows)
		weights.append(cos(th))
		total += cos(th)
	var left := CURLS - on_bun
	for j in rows:
		var th := deg_to_rad(78.0) * (float(j) + 0.3) / float(rows)
		var n := int(round(float(left) * weights[j] / total)) if j < rows - 1 else left
		left -= n
		total -= weights[j]
		for k in n:
			var ph := TAU * (float(k) + 0.5 * (j % 2)) / float(n)
			var p := cap_c + Vector3(5.2 * cos(th) * cos(ph), 5.0 * sin(th), 1.08 * 5.2 * cos(th) * sin(ph))
			LandmarkAeParts.ball(lm, "Hair", p, 0.3, 6, 3)
	for b in bun_rings:
		var n := int(b[2])
		for k in n:
			var ph := TAU * float(k) / float(n)
			var r := float(b[0])
			LandmarkAeParts.ball(lm, "Hair", bun + Vector3(r * cos(ph), float(b[1]), r * sin(ph)), 0.3, 6, 3)
