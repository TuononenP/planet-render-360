class_name LandmarkGtMonuments
extends RefCounted

## Three city monuments in true metres: the Theatre of Epidaurus, the
## Library of Celsus at Ephesus and the White Tower of Thessaloniki.

# --- Epidaurus ---------------------------------------------------------------

const EPI_R0 := 11.4
const EPI_SPAN := 1.78
const EPI_SEGS := 60

## Ancient Theatre of Epidaurus, origin at the middle of the orchestra,
## audience to -Z looking toward +Z: the 20.4 m orchestra, the 34 lower
## and 21 upper rows (55) in 12 and 22 wedges with their stairs, the
## diazoma between, the 118 m rim of the cavea, the proskenion and
## the two arched gates of the stage building. y = 0 is the orchestra;
## the top row sits 21 m up the slope.
static func epidaurus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Seat", LandmarkMaterials.pbr("limestone", "#CDC2A9", 3.0))
	lm.use("Stair", LandmarkMaterials.pbr("limestone", "#E3DAC4", 3.0))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#C4B68F", 4.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#A99B81", 3.0))
	lm.use("Bank", LandmarkMaterials.pbr("lawn", "#7C8456", 5.0))
	# Row table: (r_in, r_out, y below, y of the seat top).
	var rows: Array = []
	for i in 34:
		rows.append([11.4 + 0.8 * float(i), 12.2 + 0.8 * float(i), 0.36 * float(i), 0.36 * float(i + 1)])
	rows.append([38.6, 41.0, 12.24, 12.24])
	for i in 21:
		rows.append([41.0 + 0.82 * float(i), 41.82 + 0.82 * float(i), 12.24 + 0.42 * float(i), 12.24 + 0.42 * float(i + 1)])
	var top_y := 12.24 + 0.42 * 21.0
	var rim := 41.0 + 0.82 * 21.0
	for row in rows:
		var r_in: float = row[0]
		var r_out: float = row[1]
		var y0: float = row[2]
		var y1: float = row[3]
		for s in EPI_SEGS:
			var pa := _phi(s)
			var pb := _phi(s + 1)
			var pm := (pa + pb) * 0.5
			lm.quad("Seat", _at(r_in, pa, y1), _at(r_in, pb, y1), _at(r_out, pb, y1), _at(r_out, pa, y1), Vector3.UP)
			if y1 > y0:
				lm.quad("Seat", _at(r_in, pa, y0), _at(r_in, pb, y0), _at(r_in, pb, y1), _at(r_in, pa, y1),
					Vector3(-sin(pm), 0, cos(pm)))
		# Flanks of the cavea, down to the ground.
		for sgn in [-1.0, 1.0]:
			var pe: float = _phi(0 if sgn < 0.0 else EPI_SEGS)
			var tn: Vector3 = Vector3(cos(pe), 0, sin(pe)) * sgn
			lm.quad("Wall", _at(r_in, pe, 0.0), _at(r_out, pe, 0.0), _at(r_out, pe, y1), _at(r_in, pe, y1), tn)
	# Rear retaining wall and the earth bank piled behind it.
	for s in EPI_SEGS:
		var pa2 := _phi(s)
		var pb2 := _phi(s + 1)
		var pm2 := (pa2 + pb2) * 0.5
		lm.quad("Wall", _at(rim, pa2, 0.0), _at(rim, pb2, 0.0), _at(rim, pb2, top_y), _at(rim, pa2, top_y),
			Vector3(sin(pm2), 0, -cos(pm2)))
		lm.quad("Bank", _at(rim, pa2, top_y), _at(rim, pb2, top_y), _at(rim + 14.0, pb2, 0.0),
			_at(rim + 14.0, pa2, 0.0), Vector3(sin(pm2), 1.0, -cos(pm2)).normalized())
	for sgn2 in [-1.0, 1.0]:
		var pc: float = _phi(0 if sgn2 < 0.0 else EPI_SEGS)
		var tc: Vector3 = Vector3(cos(pc), 0, sin(pc)) * sgn2
		lm.tri("Bank", _at(rim, pc, top_y), _at(rim + 14.0, pc, 0.0), _at(rim, pc, 0.0), tc, tc, tc,
			Vector2(0, -top_y), Vector2(14.0, 0), Vector2(0, 0))
	# Stairs between the wedges: 12 below the diazoma, 22 above.
	for tier in [[11, 12, 0, 34, 0.8], [21, 22, 35, 56, 0.82]]:
		for k in range(1, int(tier[0]) + 1):
			var phi: float = _phi(0) + (_phi(EPI_SEGS) - _phi(0)) * float(k) / float(tier[1])
			var tg := Vector3(cos(phi), 0, sin(phi)) * 0.5
			for ri in range(int(tier[2]), int(tier[3])):
				var rw: Array = rows[ri]
				var a_in := Vector3(sin(phi) * float(rw[0]), float(rw[3]) + 0.02, -cos(phi) * float(rw[0]))
				var a_out := Vector3(sin(phi) * float(rw[1]), float(rw[3]) + 0.02, -cos(phi) * float(rw[1]))
				lm.quad("Stair", a_in - tg, a_in + tg, a_out + tg, a_out - tg, Vector3.UP)
				if float(rw[3]) > float(rw[2]):
					var f := Vector3(-sin(phi), 0, cos(phi))
					var b0 := Vector3(sin(phi) * float(rw[0]), float(rw[2]), -cos(phi) * float(rw[0])) + f * 0.02
					lm.quad("Stair", b0 - tg, b0 + tg, b0 + tg + Vector3(0, float(rw[3]) - float(rw[2]), 0),
						b0 - tg + Vector3(0, float(rw[3]) - float(rw[2]), 0), f)
	# Orchestra, its stone ring and the thymele.
	lm.disc("Floor", Vector3(0, 0.02, 0), Vector3.UP, EPI_R0, 48)
	lm.lathe("Seat", Vector3(0, 0.04, 0), PackedVector2Array([Vector2(10.9, 0), Vector2(10.2, 0)]), 48,
		1.0, 1.0, 0.0, false, false)
	lm.frustum("Wall", Vector3.ZERO, 0.9, 0.8, 0.6, 12)
	# Proskenion, the stage building's footing and the two arched gates.
	LandmarkGtUtil.block(lm, "Wall", -12.0, 12.0, 0.0, 2.6, 12.2, 13.6)
	LandmarkGtUtil.block(lm, "Wall", -14.0, 14.0, 0.0, 0.9, 13.6, 21.0)
	for sx in [-1.0, 1.0]:
		var gx: float = sx * 24.0
		LandmarkGtUtil.block(lm, "Seat", gx - 2.6, gx - 1.3, 0.0, 5.0, 12.4, 14.4)
		LandmarkGtUtil.block(lm, "Seat", gx + 1.3, gx + 2.6, 0.0, 5.0, 12.4, 14.4)
		LandmarkGtUtil.block(lm, "Seat", gx - 2.6, gx + 2.6, 5.0, 6.0, 12.4, 14.4)
	lm.commit(model)

## Angle (from the audience axis -Z) of segment edge `s`.
static func _phi(s: int) -> float:
	return deg_to_rad(-102.0 + 204.0 * float(s) / float(EPI_SEGS))

## Point at radius r, angle phi from -Z (positive turns toward +X) and height y.
static func _at(r: float, phi: float, y: float) -> Vector3:
	return Vector3(sin(phi) * r, y, -cos(phi) * r)

# --- Library of Celsus -------------------------------------------------------

const CEL_COLS := [-10.2, -7.4, -4.6, -1.8, 1.8, 4.6, 7.4, 10.2]
const CEL_TOP := 16.0

## Library of Celsus at Ephesus, front to +Z, origin at the foot of the
## middle of the steps: the nine steps up to the 21 m facade, its lower
## Ionic order of eight columns on pedestals around three doors and four
## statue niches, the upper Corinthian order with three windows over
## the doors, the entablatures with the alternating pediments, and the
## roofless hall behind with its side and rear walls.
static func celsus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DDD2B9", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B8AA8E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#40382E", 3.0))
	lm.use("Statue", LandmarkMaterials.pbr("limestone", "#EFE8D8", 2.0))
	# Steps, the platform and the hall behind.
	for k in 9:
		LandmarkGtUtil.block(lm, "Stone", -10.9, 10.9, 0.0, 2.7 - 0.3 * float(k), 0.0, 2.6 + 0.42 * float(k))
	LandmarkGtUtil.block(lm, "Stone", -10.5, 10.5, 2.7, 11.0, -17.4, -16.3)
	LandmarkGtUtil.block(lm, "Stone", -10.5, -9.4, 2.7, 11.0, -17.4, -1.0)
	LandmarkGtUtil.block(lm, "Stone", 9.4, 10.5, 2.7, 11.0, -17.4, -1.0)
	LandmarkGtUtil.block(lm, "Stone", -9.4, 9.4, 0.0, 2.7, -17.4, 0.0)
	# Facade wall in two storeys behind the columns.
	LandmarkGtUtil.block(lm, "Marble", -10.5, 10.5, 2.7, 14.7, -1.0, 0.0)
	var lower_top := 9.6
	var up_base := lower_top + 0.5
	for i in 8:
		var x: float = CEL_COLS[i]
		LandmarkGtUtil.block(lm, "Marble", x - 0.65, x + 0.65, 2.7, 3.3, 0.85, 2.15)
		_column(lm, Vector3(x, 3.3, 1.5), 4.9, 0.35, false)
		LandmarkGtUtil.block(lm, "Marble", x - 0.6, x + 0.6, lower_top, up_base, 0.9, 2.1)
		_column(lm, Vector3(x, up_base, 1.5), 3.7, 0.3, true)
	# Entablatures with breaks over the column pairs.
	LandmarkGtUtil.block(lm, "Marble", -10.9, 10.9, 8.2, 9.6, -0.5, 2.1)
	LandmarkGtUtil.block(lm, "Marble", -10.9, 10.9, 13.8, 14.7, -0.5, 2.0)
	LandmarkGtUtil.block(lm, "Marble", -11.0, 11.0, 14.7, 15.0, -0.7, 2.2)
	for k in 7:
		var bx: float = (float(CEL_COLS[k]) + float(CEL_COLS[k + 1])) * 0.5
		var bw: float = float(CEL_COLS[k + 1]) - float(CEL_COLS[k]) - 0.9
		if k % 2 == 1:
			# Door bay: opening, lintel and a pediment over the lower storey; window above.
			var dw: float = bw * 0.8
			lm.box("Dark", Vector3(bx, 2.7 + 1.9, 0.05), Vector3(dw, 3.8, 0.12))
			LandmarkGtUtil.block(lm, "Marble", bx - dw * 0.5 - 0.2, bx + dw * 0.5 + 0.2, 6.5, 6.9, -0.05, 0.3)
			LandmarkGtUtil.pediment(lm, "Marble", "Dark", Vector3(bx, lower_top, 1.9), Vector3.BACK,
				bw + 0.7, 0.9, 1.0)
			lm.box("Dark", Vector3(bx, 11.9, 0.05), Vector3(dw * 0.8, 2.1, 0.12))
			LandmarkGtUtil.pediment(lm, "Marble", "Dark", Vector3(bx, 13.0, 0.4), Vector3.BACK,
				dw * 0.8 + 0.6, 0.6, 0.4)
		else:
			# Statue niche below and above.
			lm.box("Dark", Vector3(bx, 2.7 + 2.0, 0.05), Vector3(bw * 0.75, 3.6, 0.12))
			lm.box("Dark", Vector3(bx, 11.7, 0.05), Vector3(bw * 0.7, 2.6, 0.12))
			LandmarkKits.statue_figure(lm, "Statue", Vector3(bx, 3.5, 0.55), 2.4)
			LandmarkKits.statue_figure(lm, "Statue", Vector3(bx, 10.6, 0.5), 1.9)
	# Central triangular pediment crowning the upper order.
	LandmarkGtUtil.pediment(lm, "Marble", "Dark", Vector3(0, 15.0, 2.2), Vector3.BACK, 6.0, CEL_TOP - 15.0, 2.9)
	LandmarkGtUtil.block(lm, "Marble", -10.5, 10.5, 14.7, 15.0, -1.0, -0.7)
	lm.commit(model)

## Facade column: base, smooth shaft, and an Ionic (volute) or Corinthian
## (acanthus bell) capital; `h` is the total height.
static func _column(lm: LandmarkMesh, base: Vector3, h: float, r: float, corinthian: bool) -> void:
	var cap_h := h * 0.14
	lm.frustum("Marble", base, r * 1.35, r * 1.2, h * 0.04, 12)
	lm.lathe("Marble", base + Vector3(0, h * 0.04, 0), PackedVector2Array([Vector2(r, 0),
		Vector2(r * 0.88, h - cap_h - h * 0.04)]), 14)
	var top := base + Vector3(0, h - cap_h, 0)
	if corinthian:
		lm.lathe("Marble", top, PackedVector2Array([Vector2(r * 0.88, 0), Vector2(r * 1.2, cap_h * 0.5),
			Vector2(r * 1.5, cap_h * 0.85)]), 12)
		lm.box("Marble", top + Vector3(0, cap_h * 0.93, 0), Vector3(r * 3.4, cap_h * 0.14, r * 3.4))
	else:
		lm.box("Marble", top + Vector3(0, cap_h * 0.5, 0), Vector3(r * 3.0, cap_h * 0.5, r * 2.2))
		for sx in [-1.0, 1.0]:
			LandmarkGtUtil.cylinder(lm, "Marble", top + Vector3(sx * r * 1.45, cap_h * 0.5, -r * 1.1),
				top + Vector3(sx * r * 1.45, cap_h * 0.5, r * 1.1), cap_h * 0.5, cap_h * 0.5, 8)
		lm.box("Marble", top + Vector3(0, cap_h * 0.93, 0), Vector3(r * 3.5, cap_h * 0.14, r * 3.0))

# --- White Tower ---------------------------------------------------------------

const WT_TOP := 33.9

## White Tower of Thessaloniki, origin at its axis: the round 22.7 m
## Ottoman bastion tower of 1535, drum with embrasures and arched windows
## in rising tiers, the corbelled gallery and parapet at 28 m and the
## 12 m turret above it.
static func white_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD3BE", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#B9AD94", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A3228", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7B8187", 2.5))
	lm.frustum("Base", Vector3(0, -2.0, 0), 13.4, 12.6, 3.0, 40)
	lm.frustum("Stone", Vector3(0, 1.0, 0), 11.7, 10.9, 25.0, 48)
	# String courses and embrasures / arched windows in staggered tiers.
	for y in [8.4, 15.6]:
		lm.frustum("Stone", Vector3(0, y, 0), _wt_r(y) + 0.3, _wt_r(y) + 0.3, 0.4, 48)
	for tier in [[5.0, 14, 0.0, 1.0, 1.6], [11.5, 12, 0.5, 1.1, 1.8], [19.0, 12, 0.0, 1.5, 2.8], [22.6, 12, 0.5, 1.5, 3.0]]:
		for k in int(tier[1]):
			var a := TAU * (float(k) + float(tier[2])) / float(tier[1])
			var rr := _wt_r(float(tier[0]))
			lm.box("Dark", Vector3(cos(a) * rr, float(tier[0]), sin(a) * rr),
				Vector3(float(tier[3]), float(tier[4]), 0.8), Basis(Vector3.UP, PI * 0.5 - a))
	# Corbelled gallery, parapet with merlons and the deck.
	lm.lathe("Stone", Vector3(0, 25.0, 0), PackedVector2Array([Vector2(10.9, 0), Vector2(11.6, 0.5),
		Vector2(12.1, 1.5), Vector2(12.2, 2.9), Vector2(11.4, 2.9)]), 48)
	for k in 36:
		var ac := TAU * float(k) / 36.0
		lm.box("Base", Vector3(cos(ac) * 11.7, 26.0, sin(ac) * 11.7), Vector3(0.7, 1.7, 0.6),
			Basis(Vector3.UP, PI * 0.5 - ac))
	lm.lathe("Stone", Vector3(0, 27.9, 0), PackedVector2Array([Vector2(12.2, 0), Vector2(12.2, 1.0),
		Vector2(11.5, 1.0)]), 48, 1.0, 1.0, 0.0, false, false)
	for k in 24:
		var am := TAU * float(k) / 24.0
		lm.box("Stone", Vector3(cos(am) * 11.9, 29.3, sin(am) * 11.9), Vector3(1.5, 0.8, 0.7),
			Basis(Vector3.UP, PI * 0.5 - am))
	# Turret: 12 m across, arched windows, cornice and a low cone.
	lm.frustum("Stone", Vector3(0, 27.9, 0), 6.1, 6.0, 4.8, 32)
	for k in 10:
		var at := TAU * (float(k) + 0.5) / 10.0
		lm.box("Dark", Vector3(cos(at) * 6.0, 30.3, sin(at) * 6.0), Vector3(1.3, 2.4, 0.6),
			Basis(Vector3.UP, PI * 0.5 - at))
	lm.lathe("Stone", Vector3(0, 32.7, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(6.5, 0.1), Vector2(6.5, 0.4),
		Vector2(6.1, 0.4)]), 32, 1.0, 1.0, 0.0, false, false)
	lm.lathe("Roof", Vector3(0, 32.7, 0), PackedVector2Array([Vector2(6.3, 0.4), Vector2(0, WT_TOP - 32.7)]), 32)
	lm.commit(model)

## Radius of the tapering drum at height y.
static func _wt_r(y: float) -> float:
	return 11.7 - 0.8 * (y - 1.0) / 25.0
