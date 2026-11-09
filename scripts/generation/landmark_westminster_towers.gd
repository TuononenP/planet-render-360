class_name LandmarkWestminsterTowers
extends RefCounted

## The great masses of the Palace of Westminster besides the Elizabeth
## Tower, at their surveyed places (OpenStreetMap parts, LandmarkWestminsterPlan):
## Westminster Hall (1097, 73 x 20.7 m inside, 28 m to the ridge, Pearson's
## buttressed walls and the north front on New Palace Yard), the Central
## Tower (octagonal, 91 m, spire over the Central Lobby) and the Victoria
## Tower (98.5 m, 24 m square, Sovereign's Entrance in its west face,
## square panelled stages, corner turrets, flagstaff).

static func build(lm: LandmarkMesh) -> void:
	_hall(lm)
	_central_tower(lm)
	_victoria(lm)

static func _face_basis(side: int) -> Basis:
	return Basis(Vector3.UP, PI * 0.5 * float(side))

## Westminster Hall: buttressed walls with tall lancets under the long
## low roof and its louvre; north front with the great window between
## two square towers; the south end runs into St Stephen's.
static func _hall(lm: LandmarkMesh) -> void:
	var r := LandmarkWestminsterPlan.HALL
	var cx := r.get_center().x
	var zc := r.get_center().y
	var z0 := r.position.y
	var z1 := r.end.y
	var body := r.size.x - 5.0
	var wall := 17.0
	lm.box("Palace", Vector3(cx, wall * 0.5, zc), Vector3(body, wall, z1 - z0), Basis(), 0.0)
	lm.gable("Roof", Vector3(cx, wall, zc), body, z1 - z0, 11.0, Basis(), 0.5, "Palace")
	lm.box("Iron", Vector3(cx, wall + 11.3, zc), Vector3(0.18, 0.6, z1 - z0), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		var out := Vector3(float(sx), 0, 0)
		var face := cx + float(sx) * body * 0.5
		for k in 10:
			var z := z0 + 4.5 + float(k) * 7.3
			LandmarkCoreAGothic.buttress(lm, "Palace", Vector3(face, 0, z), out, 1.5, 2.4, wall - 1.0, 3)
			if k < 9:
				LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", Vector3(face, 6.0, z + 3.65), out, 2.2, 8.0, 0.3, 2,
					0.8)
		LandmarkCoreAGothic.parapet(lm, "Palace", Vector3(face, wall, z0), Vector3(face, wall, z1), out, 1.0, 0.45, 3.65)
	# Louvre lantern on the ridge.
	lm.frustum("Roof", Vector3(cx, wall + 10.5, zc), 2.4, 2.2, 3.6, 8)
	lm.lathe("Roof", Vector3(cx, wall + 14.1, zc), PackedVector2Array([Vector2(2.8, 0), Vector2(0.1, 4.5)]), 8)
	# North front: great window and the twin towers.
	var nf := Vector3.FORWARD
	LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", Vector3(cx, 7.5, z0), nf, 9.0, 13.0, 0.6, 4, 0.8)
	LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", Vector3(cx, 0.5, z0), nf, 5.0, 6.0, 0.6, 1, 0.8)
	lm.gable("Palace", Vector3(cx, wall, z0 + 0.4), body - 6.0, 0.8, 5.0, Basis(), 0.0, "Palace")
	for sx in [-1.0, 1.0]:
		var p := Vector3(cx + float(sx) * (body * 0.5 + 0.2), 0, z0 + 1.8)
		lm.box("Palace", p + Vector3(0, 12.5, 0), Vector3(5.2, 25.0, 5.2), Basis(), 0.0)
		LandmarkCoreAGothic.parapet(lm, "Palace", p + Vector3(-2.6, 25.0, -2.6), p + Vector3(2.6, 25.0, -2.6), nf, 1.2,
			0.4, 2.6)
		for kv in [-1.0, 1.0]:
			LandmarkCoreAGothic.pinnacle(lm, "Palace", p + Vector3(float(kv) * 2.3, 25.0, -2.3), 0.5, 4.5)
		lm.spire("Roof", p + Vector3(0, 25.0, 0), 2.1, 6.0, 0.0)
		for k in 3:
			LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", p + Vector3(0, 3.0 + 7.5 * float(k), -2.6), nf, 1.4, 4.2,
				0.25, 1, 0.8, false)
	# South end: St Stephen's Hall and Porch, the cross-range to the Central Lobby.
	lm.box("Palace", Vector3(cx + 2.0, 12.0, z1 + 8.0), Vector3(body + 6.0, 24.0, 16.0), Basis(), 0.0)
	lm.gable("Roof", Vector3(cx + 2.0, 24.0, z1 + 8.0), body + 6.0, 16.0, 6.0, Basis(), 0.4, "Palace")
	for i in 5:
		LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", Vector3(cx - body * 0.5 + 3.5 + float(i) * 5.2, 4.0, z1 + 16.0),
			Vector3.BACK, 2.2, 6.0, 0.3, 1, 0.8)

## Central Tower: stone octagon over the Central Lobby with corner
## pinnacles, an upper octagon of tall two-light lancets, then the iron
## spire with gabled lucarnes to 91 m.
static func _central_tower(lm: LandmarkMesh) -> void:
	var r := LandmarkWestminsterPlan.CENTRAL
	var ct := Vector3(r.get_center().x, 0, r.get_center().y)
	var apo := 10.8
	var rad := apo / cos(PI / 8.0)
	lm.frustum("Palace", ct + Vector3(0, 0, 0), rad, rad, 27.0, 8, PI / 8.0)
	lm.frustum("Palace", ct + Vector3(0, 27.0, 0), rad + 0.5, rad + 0.5, 1.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", ct + d * apo + Vector3(0, 12.0, 0), d, 3.0, 11.0, 0.4, 2)
		LandmarkCoreAGothic.lancet(lm, "Palace", "Palace", ct + d * apo + Vector3(0, 2.5, 0), d, 2.4, 6.5, 0.3, 1, 0.8,
			false)
		var ca := a + PI / 8.0
		var cp := ct + Vector3(cos(ca), 0, sin(ca)) * (rad + 0.2)
		LandmarkCoreAGothic.pinnacle(lm, "Palace", cp + Vector3(0, 28.0, 0), 0.8, 9.0)
	# Upper octagon.
	var apo2 := 8.2
	var rad2 := apo2 / cos(PI / 8.0)
	lm.frustum("Palace", ct + Vector3(0, 28.0, 0), rad2, rad2, 21.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", ct + d * apo2 + Vector3(0, 32.0, 0), d, 2.6, 13.0, 0.35, 2)
		var ca := a + PI / 8.0
		var cp := ct + Vector3(cos(ca), 0, sin(ca)) * rad2
		lm.beam("Palace", cp + Vector3(0, 28.0, 0), cp + Vector3(0, 49.0, 0), 0.7, 0.7)
		LandmarkCoreAGothic.pinnacle(lm, "Palace", cp + Vector3(0, 49.0, 0), 0.55, 6.5, false)
	lm.frustum("Palace", ct + Vector3(0, 49.0, 0), rad2 + 0.6, rad2 + 0.6, 0.8, 8, PI / 8.0)
	# Iron spire with lucarne tiers.
	lm.lathe("Iron", ct + Vector3(0, 49.8, 0), PackedVector2Array([Vector2(rad2, 0), Vector2(rad2 * 0.62, 11.0),
		Vector2(rad2 * 0.3, 27.0), Vector2(0.3, 38.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for tier in 2:
		var y := 52.0 + 10.0 * float(tier)
		var k := 1.0 - 0.36 * float(tier)
		for s in 4:
			var rot := _face_basis(s)
			var out := rot * Vector3(0, 0, 1)
			var rr := rad2 * 0.83 * k
			lm.box("Iron", ct + out * rr + Vector3(0, y + 1.5, 0), Vector3(2.4, 3.0, 1.8), rot, 0.0)
			lm.gable("Iron", ct + out * rr + Vector3(0, y + 3.0, 0), 2.4, 1.8, 1.6, rot, 0.0, "Iron")
			lm.box("Gilt", ct + out * (rr + 0.95) + Vector3(0, y + 1.5, 0), Vector3(1.2, 1.9, 0.05), rot, 0.0)
	lm.frustum("Gilt", ct + Vector3(0, 87.3, 0), 0.25, 0.1, 3.5, 6)
	lm.box("Gilt", ct + Vector3(0, 90.2, 0), Vector3(0.1, 1.4, 0.1), Basis(), 0.0)

## Victoria Tower: 98.5 m. The Sovereign's Entrance in the west face, three
## stages of tall lancets between panelled piers, string courses, the
## panelled parapet at 84 m, octagonal corner turrets with gilt pyramid
## roofs to 96 m, the octagonal lantern turret and the flagstaff.
static func _victoria(lm: LandmarkMesh) -> void:
	var r := LandmarkWestminsterPlan.VICTORIA
	var vt := Vector3(r.get_center().x, 0, r.get_center().y)
	var vh := 84.0
	var w := 20.2
	lm.box("Palace", vt + Vector3(0, 1.0, 0), Vector3(w + 2.6, 2.0, w + 2.6), Basis(), 0.0)
	lm.box("Palace", vt + Vector3(0, vh * 0.5, 0), Vector3(w, vh, w), Basis(), 0.0)
	for side in 4:
		var rot := _face_basis(side)
		var out := rot * Vector3(0, 0, 1)
		var face := vt + out * w * 0.5
		var west := side == 3
		# Three columns of lights per stage between panelled piers.
		for stage in 3:
			var y0 := 22.0 + 19.0 * float(stage)
			var lh := 13.0 + 2.5 * float(stage)
			for k in 3:
				var x := -5.8 + 5.8 * float(k)
				LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", face + rot * Vector3(x, y0, 0), out, 3.0, lh, 0.5,
					2, 0.85)
		# Blind panelling on the lower stage (the entrance replaces the middle on the west).
		for k in 5:
			var x := -7.6 + 3.8 * float(k)
			if west and absf(x) < 4.5:
				continue
			LandmarkCoreAGothic.lancet(lm, "Palace", "Palace", face + rot * Vector3(x, 3.0, 0), out, 2.2, 12.0, 0.3, 1,
				0.85, false)
		for k in 4:
			var x := -8.8 + 5.9 * float(k)
			lm.box("Palace", face + rot * Vector3(x, 49.0, 0.0) + out * 0.28, Vector3(0.7, 70.0, 0.5), rot, 0.0)
		for y in [18.5, 36.0, 55.0, 74.5, 81.0]:
			lm.box("Palace", face + Vector3(0, y, 0) + out * 0.3, Vector3(w + 0.8, 0.6, 0.7), rot, 0.0)
		LandmarkCoreAGothic.parapet(lm, "Palace", vt + rot * Vector3(-w * 0.5 - 0.3, vh, w * 0.5 + 0.2),
			vt + rot * Vector3(w * 0.5 + 0.3, vh, w * 0.5 + 0.2), out, 2.2, 0.8, 2.5, 2.6)
	# Sovereign's Entrance: the great arch in the west face.
	var wout := Vector3.LEFT
	LandmarkCoreAGothic.lancet(lm, "Palace", "Windows", vt + wout * w * 0.5 + Vector3(0, 0.5, 0), wout, 9.0, 16.0, 1.1,
		1, 0.85, true, 1.1)
	lm.box("Palace", vt + wout * (w * 0.5 + 1.6) + Vector3(0, 0.2, 0), Vector3(2.4, 0.4, 14.0), Basis(), 0.0)
	# Corner turrets: octagonal, panelled, in stages, gilt pyramid roofs.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := vt + Vector3(float(sx) * w * 0.5, 0, float(sz) * w * 0.5)
			lm.frustum("Palace", p, 2.5, 2.3, vh + 5.0, 8, PI / 8.0)
			for y in [18.0, 36.0, 55.0, 74.0]:
				lm.frustum("Palace", p + Vector3(0, y, 0), 2.75, 2.75, 0.6, 8, PI / 8.0)
			for k in 8:
				var a := TAU * float(k) / 8.0 + PI / 8.0
				lm.beam("Palace", p + Vector3(cos(a), 0, sin(a)) * 2.35 + Vector3(0, 12.0, 0),
					p + Vector3(cos(a), 0, sin(a)) * 2.35 + Vector3(0, vh + 4.0, 0), 0.3, 0.3)
			lm.frustum("Palace", p + Vector3(0, vh + 5.0, 0), 2.9, 2.9, 0.6, 8, PI / 8.0)
			lm.spire("Roof", p + Vector3(0, vh + 5.6, 0), 2.6, 5.6, 0.0, 8)
			lm.frustum("Gilt", p + Vector3(0, vh + 11.0, 0), 0.14, 0.05, 2.2, 6)
	# Octagonal lantern turret and the flagstaff.
	lm.frustum("Palace", vt + Vector3(0, vh, 0), 5.2, 4.6, 4.5, 8, PI / 8.0)
	lm.frustum("Palace", vt + Vector3(0, vh + 4.5, 0), 5.0, 5.0, 0.5, 8, PI / 8.0)
	lm.frustum("Iron", vt + Vector3(0, vh + 5.0, 0), 0.35, 0.18, 9.5, 6)
	lm.box("Gilt", vt + Vector3(0, vh + 14.1, 0), Vector3(0.1, 0.8, 0.1), Basis(), 0.0)
