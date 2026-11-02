class_name LandmarkGtMonuments
extends RefCounted

## Two monuments in true metres: the Theatre of Epidaurus and the White
## Tower of Thessaloniki (the Library of Celsus is LandmarkGtCelsus).

# --- Epidaurus ---------------------------------------------------------------

const EPI_SEGS := 66
const EPI_LOWER := 34
const EPI_UPPER := 21

## Ancient Theatre of Epidaurus (late 4th century BC, upper tier 2nd
## century BC), origin at the middle of the orchestra, audience to -Z
## looking toward +Z: the 20 m orchestra in its white border ring with
## the euripos drain and the thymele base; 34 lower rows in 12 wedges
## between 13 stairways and, past the 1.8 m diazoma, 21 upper rows in 22
## wedges between 23 stairways, every row a limestone seat with its
## moulded front lip and the sunken footway of the row behind, the
## seats of honour with backrests on the first row of each tier; the
## analemma walls closing the cavea, the 118 m rim and the hill banked
## behind; the proskenion's 14 half-column stumps, the stage building's
## footings and the two restored double gates across the parodoi. The
## top row sits 21 m up the slope.
static func epidaurus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Seat", LandmarkMaterials.pbr("limestone", "#CDC2A9", 3.0))
	lm.use("Stair", LandmarkMaterials.pbr("limestone", "#E3DAC4", 3.0))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#C4B68F", 4.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#A99B81", 3.0))
	lm.use("Bank", LandmarkMaterials.pbr("lawn", "#7C8456", 5.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6DFD0", 2.5))
	# Row table: (r_in, r_out, y below, y of the seat top).
	var rows: Array = []
	for i in EPI_LOWER:
		rows.append([11.4 + 0.8 * float(i), 12.2 + 0.8 * float(i), 0.36 * float(i), 0.36 * float(i + 1)])
	var dz_y := 0.36 * float(EPI_LOWER)
	var r_up := 11.4 + 0.8 * float(EPI_LOWER) + 1.82
	rows.append([11.4 + 0.8 * float(EPI_LOWER), r_up, dz_y, dz_y])
	for i in EPI_UPPER:
		rows.append([r_up + 0.82 * float(i), r_up + 0.82 * float(i + 1), dz_y + 0.42 * float(i), dz_y + 0.42 * float(i + 1)])
	var top_y := dz_y + 0.42 * float(EPI_UPPER)
	var rim := r_up + 0.82 * float(EPI_UPPER)
	for ri in rows.size():
		var row: Array = rows[ri]
		_seat_row(lm, row, ri == 0 or ri == EPI_LOWER + 1)
	# Analemmata: the coped retaining walls along both flanks.
	for sgn in [-1.0, 1.0]:
		var pe: float = _phi(0 if sgn < 0.0 else EPI_SEGS)
		var tn: Vector3 = Vector3(cos(pe), 0, sin(pe)) * sgn
		var dir := Vector3(sin(pe), 0, -cos(pe))
		var bas := Basis(dir, Vector3.UP, tn)
		for row in rows:
			var r0: float = row[0]
			var r1: float = row[1]
			var y1: float = row[3]
			var m := dir * (r0 + r1) * 0.5 + tn * 0.6
			lm.box("Wall", m + Vector3(0, (y1 + 0.5) * 0.5, 0), Vector3(r1 - r0 + 0.02, y1 + 0.5, 1.2), bas)
			lm.box("Stair", m + Vector3(0, y1 + 0.58, 0), Vector3(r1 - r0 + 0.04, 0.16, 1.35), bas, 0.0)
	# Rear retaining wall and the hill piled behind it.
	for s in EPI_SEGS:
		var pa := _phi(s)
		var pb := _phi(s + 1)
		var pm := (pa + pb) * 0.5
		lm.quad("Wall", _at(rim, pa, 0.0), _at(rim, pb, 0.0), _at(rim, pb, top_y + 0.6), _at(rim, pa, top_y + 0.6),
			Vector3(sin(pm), 0, -cos(pm)))
		lm.quad("Wall", _at(rim - 0.6, pa, top_y + 0.6), _at(rim - 0.6, pb, top_y + 0.6), _at(rim, pb, top_y + 0.6),
			_at(rim, pa, top_y + 0.6), Vector3.UP)
		lm.quad("Wall", _at(rim - 0.6, pa, top_y), _at(rim - 0.6, pb, top_y), _at(rim - 0.6, pb, top_y + 0.6),
			_at(rim - 0.6, pa, top_y + 0.6), Vector3(-sin(pm), 0, cos(pm)))
		lm.quad("Bank", _at(rim, pa, top_y), _at(rim, pb, top_y), _at(rim + 14.0, pb, 0.0),
			_at(rim + 14.0, pa, 0.0), Vector3(sin(pm), 1.0, -cos(pm)).normalized())
	for sgn2 in [-1.0, 1.0]:
		var pc: float = _phi(0 if sgn2 < 0.0 else EPI_SEGS)
		var tc: Vector3 = Vector3(cos(pc), 0, sin(pc)) * sgn2
		lm.tri("Bank", _at(rim, pc, top_y), _at(rim + 14.0, pc, 0.0), _at(rim, pc, 0.0), tc, tc, tc,
			Vector2(0, -top_y), Vector2(14.0, 0), Vector2(0, 0))
	# Stairways: 13 through the lower tier, 23 through the upper.
	for tier in [[12, 0, EPI_LOWER], [22, EPI_LOWER + 1, rows.size()]]:
		for k in int(tier[0]) + 1:
			var phi: float = _phi(0) + (_phi(EPI_SEGS) - _phi(0)) * float(k) / float(tier[0])
			for ri in range(int(tier[1]), int(tier[2])):
				_stair(lm, phi, rows[ri])
	# Orchestra: floor, white border ring, euripos and the thymele base.
	lm.disc("Floor", Vector3(0, 0.02, 0), Vector3.UP, 10.0, 48)
	lm.lathe("Marble", Vector3(0, 0, 0), PackedVector2Array([Vector2(10.4, 0.0), Vector2(10.4, 0.1),
		Vector2(10.0, 0.1), Vector2(10.0, 0.0)]), 64, 1.0, 1.0, 0.0, false, false)
	lm.lathe("Wall", Vector3(0, 0, 0), PackedVector2Array([Vector2(11.4, 0.0), Vector2(11.4, 0.06),
		Vector2(10.4, 0.06), Vector2(10.4, 0.0)]), 64, 1.0, 1.0, 0.0, false, false)
	lm.frustum("Marble", Vector3.ZERO, 0.9, 0.85, 0.25, 16)
	lm.frustum("Marble", Vector3(0, 0.25, 0), 0.7, 0.68, 0.12, 16)
	_stage(lm)
	lm.commit(model)

## One curved row of seats over every segment: the face below the lip,
## the projecting moulded lip, the seat top, the step down and the
## footway of the row behind; `honour` adds the seats' backrests.
static func _seat_row(lm: LandmarkMesh, row: Array, honour: bool) -> void:
	var r_in: float = row[0]
	var r_out: float = row[1]
	var y0: float = row[2]
	var y1: float = row[3]
	var flat := y1 <= y0
	var foot := 0.0 if flat else 0.06
	var rs := r_in + (r_out - r_in) * 0.55
	for s in EPI_SEGS:
		var pa := _phi(s)
		var pb := _phi(s + 1)
		var pm := (pa + pb) * 0.5
		var fwd := Vector3(-sin(pm), 0, cos(pm))
		if flat:
			lm.quad("Seat", _at(r_in, pa, y1), _at(r_in, pb, y1), _at(r_out, pb, y1), _at(r_out, pa, y1), Vector3.UP)
			continue
		var yb := maxf(y0 - foot, 0.0)
		lm.quad("Seat", _at(r_in, pa, yb), _at(r_in, pb, yb), _at(r_in, pb, y1 - 0.08), _at(r_in, pa, y1 - 0.08), fwd)
		lm.quad("Seat", _at(r_in - 0.05, pa, y1 - 0.08), _at(r_in - 0.05, pb, y1 - 0.08), _at(r_in, pb, y1 - 0.08),
			_at(r_in, pa, y1 - 0.08), Vector3.DOWN)
		lm.quad("Seat", _at(r_in - 0.05, pa, y1 - 0.08), _at(r_in - 0.05, pb, y1 - 0.08), _at(r_in - 0.05, pb, y1),
			_at(r_in - 0.05, pa, y1), fwd)
		lm.quad("Seat", _at(r_in - 0.05, pa, y1), _at(r_in - 0.05, pb, y1), _at(rs, pb, y1), _at(rs, pa, y1), Vector3.UP)
		lm.quad("Seat", _at(rs, pa, y1 - foot), _at(rs, pb, y1 - foot), _at(rs, pb, y1), _at(rs, pa, y1), -fwd)
		lm.quad("Seat", _at(rs, pa, y1 - foot), _at(rs, pb, y1 - foot), _at(r_out, pb, y1 - foot),
			_at(r_out, pa, y1 - foot), Vector3.UP)
		if honour:
			lm.quad("Marble", _at(rs, pa, y1), _at(rs, pb, y1), _at(rs + 0.05, pb, y1 + 0.55), _at(rs + 0.05, pa, y1 + 0.55),
				fwd)
			lm.quad("Marble", _at(rs + 0.05, pa, y1 + 0.55), _at(rs + 0.05, pb, y1 + 0.55), _at(rs + 0.2, pb, y1 + 0.55),
				_at(rs + 0.2, pa, y1 + 0.55), Vector3.UP)
			lm.quad("Marble", _at(rs + 0.2, pa, y1 - foot), _at(rs + 0.2, pb, y1 - foot), _at(rs + 0.2, pb, y1 + 0.55),
				_at(rs + 0.2, pa, y1 + 0.55), -fwd)

## Stairway through one row at angle phi: two steps per row (each half
## the seat height), 0.8 m wide, laid over the seat.
static func _stair(lm: LandmarkMesh, phi: float, row: Array) -> void:
	var r_in: float = row[0]
	var r_out: float = row[1]
	var y0: float = row[2]
	var y1: float = row[3]
	if y1 <= y0:
		return
	var tg := Vector3(cos(phi), 0, sin(phi)) * 0.4
	var f := Vector3(-sin(phi), 0, cos(phi))
	var rm := (r_in + r_out) * 0.5
	var ym := (y0 + y1) * 0.5
	for st in [[r_in - 0.06, rm, ym], [rm, r_out, y1]]:
		var ra: float = st[0]
		var rb: float = st[1]
		var yt: float = float(st[2]) + 0.02
		var a := _at(ra, phi, yt)
		var b := _at(rb, phi, yt)
		lm.quad("Stair", a - tg, a + tg, b + tg, b - tg, Vector3.UP)
		var yl := maxf(yt - (y1 - y0) * 0.5 - 0.04, 0.0)
		var a0 := _at(ra, phi, yl)
		lm.quad("Stair", a0 - tg, a0 + tg, a + tg, a - tg, f)
		for sg in [-1.0, 1.0]:
			var sv: Vector3 = tg * float(sg)
			lm.quad("Stair", a0 + sv, a + sv, b + sv, _at(rb, phi, yl) + sv, sv.normalized())

## Stage building: the proskenion's stylobate with its 14 Ionic
## half-column stumps, the skene and paraskenia footings, the ramps to
## the logeion, and the two double gates across the parodoi.
static func _stage(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Wall", -12.0, 12.0, 0.0, 0.5, 12.2, 14.0)
	for k in 14:
		var x := -10.8 + 21.6 * float(k) / 13.0
		LandmarkGtUtil.fluted(lm, "Marble", Vector3(x, 0.5, 12.5), Vector3(x, 1.0 + 1.1 * LandmarkGtUtil.hash01(k, 3), 12.5),
			0.27, 0.27, 24)
	for w in [[-14.0, 14.0, 14.0, 15.0], [-14.0, 14.0, 20.4, 21.4], [-14.0, -13.0, 14.0, 21.4], [13.0, 14.0, 14.0, 21.4],
			[-4.5, -3.7, 15.0, 20.4], [3.7, 4.5, 15.0, 20.4], [-18.0, -14.0, 13.0, 14.0], [14.0, 18.0, 13.0, 14.0],
			[-18.0, -17.0, 14.0, 19.0], [17.0, 18.0, 14.0, 19.0]]:
		LandmarkGtUtil.block(lm, "Wall", w[0], w[1], 0.0, 1.0 + 0.3 * LandmarkGtUtil.hash01(int(float(w[0]) * 3.0 + float(w[2])), 7),
			w[2], w[3])
	for sx in [-1.0, 1.0]:
		var gx: float = sx * 21.0
		# Double gate across the parodos: three piers with Ionic half
		# columns front and back, two doorways, architrave, frieze, cornice.
		var z0 := 4.6
		var z1 := 12.2
		for k in 3:
			var pz := lerpf(z0 + 0.4, z1 - 0.4, float(k) / 2.0)
			LandmarkGtUtil.block(lm, "Marble", gx - 0.45, gx + 0.45, 0.0, 0.35, pz - 0.55, pz + 0.55)
			LandmarkGtUtil.block(lm, "Seat", gx - 0.4, gx + 0.4, 0.35, 4.6, pz - 0.4, pz + 0.4)
			for fx in [-1.0, 1.0]:
				LandmarkDetail.column(lm, "Marble", Vector3(gx + fx * 0.42, 0.35, pz), 0.24, 4.25, "ionic", 20)
		var mid := Vector3(gx, 0, (z0 + z1) * 0.5)
		var bas := Basis(Vector3.BACK, Vector3.UP, Vector3.RIGHT * -1.0)
		for f in 3:
			lm.box("Marble", mid + Vector3(0, 4.68 + 0.18 * float(f), 0), Vector3(z1 - z0 + 0.1 * float(f), 0.18,
				1.1 + 0.05 * float(f)), bas, 0.0)
		lm.box("Seat", mid + Vector3(0, 5.42, 0), Vector3(z1 - z0, 0.5, 1.0), bas)
		for fx2 in [-1.0, 1.0]:
			LandmarkDetail.cornice(lm, "Marble", Vector3(gx + fx2 * 0.5, 5.67, z0 - 0.2), Vector3(gx + fx2 * 0.5, 5.67, z1 + 0.2),
				Vector3(fx2, 0, 0), 0.35, true)

## Angle (from the audience axis -Z) of segment edge `s`.
static func _phi(s: int) -> float:
	return deg_to_rad(-102.0 + 204.0 * float(s) / float(EPI_SEGS))

## Point at radius r, angle phi from -Z (positive turns toward +X) and height y.
static func _at(r: float, phi: float, y: float) -> Vector3:
	return Vector3(sin(phi) * r, y, -cos(phi) * r)

# --- White Tower ---------------------------------------------------------------

const WT_TOP := 33.9
const WT_DECK := 27.9

## White Tower of Thessaloniki (Ottoman, c. 1535), origin at its axis:
## the 22.7 m drum on its sloping plinth, six storeys lit by small
## framed embrasures climbing round with the inner ramp, the arched
## door on the landward (north, -Z) side, two string courses, the
## parapet on stepped corbels at the roof terrace with its merlons and
## gun slits, and the 12 m turret, 6 m high, with arched windows, a
## door to the terrace, its cornice and crenellated parapet.
static func white_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD3BE", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#B9AD94", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A3228", 3.0))
	lm.use("Frame", LandmarkMaterials.pbr("limestone", "#C9BFA8", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3238"))
	lm.lathe("Base", Vector3.ZERO, PackedVector2Array([Vector2(12.5, 0), Vector2(12.2, 0.6), Vector2(11.9, 1.4),
		Vector2(11.75, 1.6)]), 64)
	lm.frustum("Stone", Vector3(0, 1.0, 0), 11.7, 10.9, 24.0, 64)
	for y in [1.6, 8.4, 15.6]:
		lm.lathe("Frame", Vector3(0, y, 0), PackedVector2Array([Vector2(_wt_r(y), 0), Vector2(_wt_r(y) + 0.25, 0.08),
			Vector2(_wt_r(y) + 0.3, 0.3), Vector2(_wt_r(y), 0.42)]), 64)
	# Embrasures: six storeys of small framed openings, each storey's
	# ring turned on so they climb round with the ramp inside.
	for tier in [[4.6, 10, 0.0, 0.7, 1.1], [7.8, 10, 0.18, 0.7, 1.1], [11.4, 10, 0.36, 0.8, 1.3],
			[14.4, 10, 0.54, 0.8, 1.3], [18.6, 9, 0.12, 1.0, 1.7], [22.4, 9, 0.6, 1.0, 1.7]]:
		var n: int = tier[1]
		for k in n:
			var a := TAU * (float(k) + float(tier[2])) / float(n)
			if float(tier[0]) < 6.0 and absf(wrapf(a + PI * 0.5, -PI, PI)) < 0.3:
				continue
			_wt_window(lm, a, float(tier[0]), float(tier[3]), float(tier[4]), false)
	_wt_door(lm)
	# Corbelled parapet round the roof terrace: stepped consoles, the
	# parapet ring with its merlons and gun slits, the paved deck.
	lm.lathe("Stone", Vector3(0, 25.0, 0), PackedVector2Array([Vector2(10.9, 0), Vector2(11.3, 0.9),
		Vector2(11.3, 1.9), Vector2(10.9, 1.9)]), 64)
	for k in 40:
		var ac := TAU * float(k) / 40.0
		var d := Vector3(cos(ac), 0, sin(ac))
		var bas := Basis(Vector3.UP, PI * 0.5 - ac)
		for st in 3:
			lm.box("Base", d * (11.25 + 0.28 * float(st)) + Vector3(0, 25.35 + 0.42 * float(st), 0),
				Vector3(0.55, 0.42, 0.6 + 0.1 * float(st)), bas)
	lm.lathe("Stone", Vector3(0, 26.6, 0), PackedVector2Array([Vector2(11.6, 0), Vector2(12.25, 0.1),
		Vector2(12.25, WT_DECK - 26.6 + 1.0), Vector2(11.6, WT_DECK - 26.6 + 1.0), Vector2(11.6, 0)]), 64,
		1.0, 1.0, 0.0, false, false)
	lm.lathe("Frame", Vector3(0, WT_DECK + 0.95, 0), PackedVector2Array([Vector2(12.3, 0), Vector2(12.3, 0.12),
		Vector2(11.55, 0.12)]), 64, 1.0, 1.0, 0.0, false, false)
	lm.lathe("Base", Vector3(0, WT_DECK, 0), PackedVector2Array([Vector2(11.6, 0.0), Vector2(0.0, 0.0)]), 48)
	for k in 30:
		var am := TAU * float(k) / 30.0
		lm.box("Stone", Vector3(cos(am) * 11.92, WT_DECK + 1.5, sin(am) * 11.92), Vector3(1.4, 1.0, 0.65),
			Basis(Vector3.UP, PI * 0.5 - am))
		lm.box("Dark", Vector3(cos(am) * 12.26, WT_DECK + 0.5, sin(am) * 12.26), Vector3(0.14, 0.5, 0.04),
			Basis(Vector3.UP, PI * 0.5 - am), 0.0)
	# Turret: 12 m across, arched windows, door, cornice and merlons.
	var tt := WT_TOP - 0.8
	lm.frustum("Stone", Vector3(0, WT_DECK, 0), 6.1, 6.0, tt - WT_DECK, 48)
	lm.frustum("Frame", Vector3(0, WT_DECK, 0), 6.3, 6.25, 0.4, 48)
	for k in 10:
		var at := TAU * (float(k) + 0.5) / 10.0
		var d2 := Vector3(cos(at), 0, sin(at))
		if k == 7:
			LandmarkDetail.window(lm, "Frame", "Dark", d2 * 6.05 + Vector3(0, WT_DECK + 1.3, 0), d2, 1.2, 2.4, true, 0.2)
		else:
			LandmarkDetail.window(lm, "Frame", "Glass", d2 * 6.05 + Vector3(0, WT_DECK + 2.6, 0), d2, 0.9, 1.6, true, 0.2)
	lm.lathe("Frame", Vector3(0, tt - 0.5, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(6.2, 0.15),
		Vector2(6.35, 0.4), Vector2(6.35, 0.5), Vector2(6.0, 0.5)]), 48)
	for k in 16:
		var am2 := TAU * float(k) / 16.0
		lm.box("Stone", Vector3(cos(am2) * 5.95, tt + 0.4, sin(am2) * 5.95), Vector3(1.1, 0.8, 0.55),
			Basis(Vector3.UP, PI * 0.5 - am2))
	lm.commit(model)

## One embrasure at angle a and sill-centre height y on the drum: a dark
## splayed recess with a stone frame (jambs, lintel, sill) standing
## proud of the wall.
static func _wt_window(lm: LandmarkMesh, a: float, y: float, w: float, h: float, arched: bool) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var r := _wt_r(y)
	var c := d * r + Vector3(0, y, 0)
	var bas := Basis(Vector3.UP, PI * 0.5 - a)
	var side := Vector3.UP.cross(d).normalized()
	lm.box("Dark", c - d * 0.1, Vector3(w, h, 0.5), bas, 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Frame", c + side * (w * 0.5 + 0.15) * float(s) + d * 0.12, Vector3(0.3, h + 0.3, 0.42), bas)
	lm.box("Frame", c + Vector3(0, h * 0.5 + 0.18, 0) + d * 0.12, Vector3(w + 0.6, 0.36, 0.42), bas)
	lm.box("Frame", c - Vector3(0, h * 0.5 + 0.12, 0) + d * 0.16, Vector3(w + 0.5, 0.24, 0.5), bas)
	if arched:
		LandmarkDetail.arch(lm, "Frame", c + Vector3(0, h * 0.5, 0) + d * 0.1, d, w, 0.25, 0.3)

## The arched door on the landward side (-Z), with its stone surround.
static func _wt_door(lm: LandmarkMesh) -> void:
	var d := Vector3(0, 0, -1)
	var r := _wt_r(2.0)
	var c := d * r
	var bas := Basis(Vector3.UP, PI)
	lm.box("Dark", c + Vector3(0, 1.6, 0), Vector3(1.8, 3.2, 0.6), bas, 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Frame", c + Vector3(float(s) * 1.15, 1.6, 0) + d * 0.15, Vector3(0.5, 3.2, 0.5), bas)
	LandmarkDetail.arch(lm, "Frame", c + Vector3(0, 3.2, 0) + d * 0.1, d, 1.8, 0.45, 0.4)
	lm.box("Frame", c + Vector3(0, 0.1, 0) + d * 0.6, Vector3(2.6, 0.2, 1.0), bas)

## Radius of the tapering drum at height y.
static func _wt_r(y: float) -> float:
	return 11.7 - 0.8 * (y - 1.0) / 24.0
