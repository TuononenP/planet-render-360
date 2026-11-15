class_name CarDetails
extends RefCounted

## The near-only detail of the procedural cars (CarModel), on LandmarkMesh
## in the car's frame (metres; +X forward, wheels on y = 0):
## * interior(): what shows through the glass: front seats, a rear bench
##   (or a van's bulkhead), the dashboard with its steering wheel on the
##   driver's side, a saloon's parcel shelf. The body's own lining
##   (VehicleKit.body) closes the cabin round them.
## * bed(): a pickup's open load bed, walled from the loft's own deck edge
##   down to a ribbed fy, the rear arches standing in it.
## * front(): the grille modelled over the drawn one (a dark mesh, bars and a
##   surround), the lower intake with its fog lamps, and a badge.
## * rear(): third brake lamp, a hatch's rear wiper, bumper reflectors and
##   a badge.
## * plate_text(): characters on a number plate.

## A bar `w` thick along the body at end `end`, through face_point (u, t)
## pairs from `pts`, `lift` off the paint.
static func _rail(lm: LandmarkMesh, s: Dictionary, end: float, key: String, pts: Array, lift: float,
		w: float) -> void:
	var at: Array[Vector3] = []
	for q: Vector3 in pts:
		# q: (side, u, t).
		at.append(VehicleKit.face_point(s, end, q.x, q.y, q.z) + VehicleKit.face_normal(s, end, q.x, q.y, q.z) * lift)
	for i in at.size() - 1:
		var n := VehicleKit.face_normal(s, end, (pts[i] as Vector3).x, (pts[i] as Vector3).y, (pts[i] as Vector3).z)
		lm.beam(key, at[i], at[i + 1], w, w * 0.8, n, i == 0 or i == at.size() - 2)

## (side, u, t) points across the face at height share `t`, from u = -u1 to u1.
static func _across(u1: float, t: float, n: int) -> Array:
	var out := []
	for i in n + 1:
		var u := lerpf(-u1, u1, float(i) / float(n))
		out.append(Vector3(signf(u) if u != 0.0 else 1.0, absf(u), t))
	return out

static func _flat(b: Vector2) -> Callable:
	return func(_a: float) -> Vector2: return b

static func front(lm: LandmarkMesh, s: Dictionary) -> void:
	var bus := float(s["len"]) > 8.0
	var lamp: Vector2 = s["lamp_f"]
	var span := lamp.y - lamp.x
	var lk := float(s["lamp_k"])
	var w_end := VehicleKit.end_at(s, 1.0, 1.0, lamp.x).z
	var ug := lk - 0.04 / maxf(w_end, 0.3)
	var g := Vector2(lamp.x + 0.12 * span, lamp.y)
	var trim := "Chrome" if bool(s["chrome"]) else "Grille"
	if not bus:
		for side: float in [1.0, -1.0]:
			CarParts.patch(lm, s, 1.0, side, "Rubber", 0.0, ug, _flat(g), 0.004, false, false, 6)
		var face_h := VehicleKit.end_at(s, 1.0, 0.0, 1.0).y - VehicleKit.end_at(s, 1.0, 0.0, 0.0).y
		var bars := clampi(roundi((g.y - g.x) * face_h / 0.032), 3, 7)
		for i in bars:
			var t := lerpf(g.x, g.y, (float(i) + 0.5) / float(bars))
			_rail(lm, s, 1.0, "Grille", _across(ug * 0.97, t, 8), 0.009, 0.011)
		# The surround: across the top and the foot, down each end.
		_rail(lm, s, 1.0, trim, _across(ug, g.y, 8), 0.012, 0.016)
		_rail(lm, s, 1.0, trim, _across(ug, g.x, 8), 0.012, 0.014)
		for side: float in [1.0, -1.0]:
			_rail(lm, s, 1.0, trim, [Vector3(side, ug, g.x), Vector3(side, ug, (g.x + g.y) * 0.5), Vector3(side, ug, g.y)],
				0.012, 0.016)
		# Badge on the grille's top bar.
		var bp := VehicleKit.face_point(s, 1.0, 1.0, 0.0, lerpf(g.x, g.y, 0.62))
		var bn := VehicleKit.face_normal(s, 1.0, 1.0, 0.0, lerpf(g.x, g.y, 0.62))
		lm.disc("Chrome", bp + bn * 0.02, bn, 0.04, 16)
		lm.disc("Trim", bp + bn * 0.021, bn, 0.028, 16)
	# The lower intake: a dark mesh split by a bar, a fog lamp at each end.
	var gt: Vector2 = s["grille"]
	# Out past the drawn intake (CarPaint's, for the far mesh) so none shows.
	var ui := 0.88
	for side: float in [1.0, -1.0]:
		CarParts.patch(lm, s, 1.0, side, "Rubber", 0.0, ui, _flat(gt), 0.005, false, false, 8)
		var ft := (gt.x + gt.y) * 0.5
		var fu := ui * 0.86
		var fp := VehicleKit.face_point(s, 1.0, side, fu, ft)
		var fn := VehicleKit.face_normal(s, 1.0, side, fu, ft)
		var fr := clampf((gt.y - gt.x) * 0.25, 0.025, 0.045) * (1.6 if bus else 1.0)
		lm.disc("Trim", fp + fn * 0.006, fn, fr * 1.35, 16)
		lm.disc("Chrome", fp + fn * 0.008, fn, fr, 16)
		lm.disc("HeadLamp", fp + fn * 0.01, fn, fr * 0.6, 12)
	_rail(lm, s, 1.0, "Grille", _across(ui * 0.62, (gt.x + gt.y) * 0.5, 6), 0.007, 0.012)

static func rear(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var tail_glass := bool(s["tail_glass"])
	# A third brake lamp at the head of a sloping rear window.
	if bool(s["rear_glass"]) and not tail_glass and not bool(s["bed"]):
		var x := gh[1] - 0.03
		var y := VehicleKit.roof_on_mesh(s, x, 0.0)
		lm.box("TailGlow", Vector3(x, y + 0.008, 0.0), Vector3(0.04, 0.018, 0.34), Basis(), 0.006)
	if bool(s["rear_wiper"]):
		_rear_wiper(lm, s)
	# Reflectors low on the bumper corners, a badge on the boot or tailgate.
	for side: float in [1.0, -1.0]:
		CarParts.patch(lm, s, -1.0, side, "TailLamp", 0.66, 0.9, _flat(Vector2(0.2, 0.25)), 0.006)
	var lamp: Vector2 = s["lamp_r"]
	var bt := minf(lamp.y + 0.05, 0.92) if lamp.y < 0.8 else lamp.x - 0.08
	var bp := VehicleKit.face_point(s, -1.0, 1.0, 0.0, bt)
	var bn := VehicleKit.face_normal(s, -1.0, 1.0, 0.0, bt)
	lm.disc("Chrome", bp + bn * 0.006, bn, 0.035, 16)

## A hatch's wiper parked along the foot of its rear window, from a pivot
## on the centreline.
static func _rear_wiper(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var w := VehicleKit.half_width(s, gh[0])
	var foot := VehicleKit.roof_on_mesh(s, gh[0], 0.0)
	var x := gh[0]
	while x < gh[1] and VehicleKit.roof_on_mesh(s, x, 0.0) - foot < 0.06:
		x += 0.005
	var pivot: Vector3 = CarModel._on_glass(s, x, 0.0, 0.014)
	var n: Vector3 = CarModel._glass_n(s, x, 0.0)
	lm.disc("Trim", pivot, n, 0.025, 10)
	var pts: Array[Vector3] = []
	for k in 5:
		pts.append(CarModel._on_glass(s, x + 0.01 * float(k), -w * 0.62 * float(k) / 4.0, 0.012))
	for k in 4:
		lm.beam("Trim", pts[k], pts[k + 1], 0.016, 0.012, n, k == 0 or k == 3)
		lm.beam("Rim", pts[k] + n * 0.008, pts[k + 1] + n * 0.008, 0.02, 0.012, n, k == 0 or k == 3)

## Seats, dashboard and steering wheel (see the class notes).
static func interior(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var doors: PackedFloat32Array = s["doors"]
	var f := float(s["wid"]) / 1.8
	var belt := VehicleKit.soft(s["belt"], doors[1], 0.1)
	var fy := float(s["clear"]) + 0.16
	var seat := maxf(fy + 0.26, belt - 0.42)
	var zs := 0.37 * f
	var tilt := Basis(Vector3(0, 0, 1), 0.22)
	# Front seats: back just ahead of the centre pillar.
	var xb := doors[1] + 0.12
	for side: float in [1.0, -1.0]:
		_seat(lm, Vector3(xb, seat, side * zs), 0.5 * f, tilt)
	if bool(s["rear_seats"]):
		var xr := maxf(doors[0] + 0.08, gh[0] + float(s["rear_pillar"]) * 0.5)
		var top := VehicleKit.roof_at(s, xr, 0.0)
		var back_h := clampf(top - seat - 0.2, 0.42, 0.62)
		lm.box("Cabin", Vector3(xr + 0.3, seat - 0.06, 0.0), Vector3(0.5, 0.14, zs * 2.0 + 0.5 * f), Basis(), 0.04)
		lm.box("Cabin", Vector3(xr - 0.02, seat + back_h * 0.5, 0.0), Vector3(0.11, back_h, zs * 2.0 + 0.5 * f),
			tilt, 0.035)
		for z: float in [-zs, 0.0, zs]:
			lm.box("Cabin", Vector3(xr - 0.08, seat + back_h + 0.08, z), Vector3(0.09, 0.15, 0.24), tilt, 0.03)
		# A saloon's parcel shelf, from the bench's back to the rear window.
		if gh[0] > -float(s["len"]) * 0.5 + 0.35 and not bool(s["bed"]) and not bool(s["tail_glass"]):
			var y := VehicleKit.soft(s["belt"], gh[0], 0.1) + 0.03
			var x0 := gh[0] + 0.02
			var x1 := xr - 0.06
			if x1 > x0:
				lm.box("Trim", Vector3((x0 + x1) * 0.5, y, 0.0),
					Vector3(x1 - x0, 0.02, 2.0 * VehicleKit.half_width(s, gh[0]) - 0.3), Basis(), 0.0)
	else:
		# A van's bulkhead behind the cab.
		var xw := xb - 0.32
		var h := VehicleKit.roof_at(s, xw, 0.0) - 0.06 - fy
		lm.box("Cabin", Vector3(xw, fy + h * 0.5, 0.0), Vector3(0.04, h, 2.0 * VehicleKit.half_width(s, xw) - 0.2),
			Basis(), 0.0)
	# The dashboard under the windscreen, and the steering wheel.
	var xd := gh[3] - 0.05
	var dl := clampf((xd - (xb + 0.55)) * 0.75, 0.3, 0.6)
	var dy := VehicleKit.soft(s["belt"], xd, 0.1) + 0.03
	var dw := 2.0 * VehicleKit.half_width(s, xd - dl * 0.5) - 0.16
	lm.box("Trim", Vector3(xd - dl * 0.5, dy - 0.14, 0.0), Vector3(dl, 0.28, dw), Basis(), 0.04)
	var drv := (1.0 if bool(s["rhd"]) else -1.0) * zs
	var wc := Vector3(xd - dl - 0.08, dy - 0.04, drv)
	var nrm := Vector3(-0.8, 0.6, 0.0).normalized()
	var a := Vector3(0, 0, 1)
	var b := nrm.cross(a)
	var ring: Array[Vector3] = []
	for k in 16:
		var th := TAU * float(k) / 16.0
		ring.append(wc + (a * cos(th) + b * sin(th)) * 0.18)
	for k in 16:
		lm.beam("Trim", ring[k], ring[(k + 1) % 16], 0.028, 0.028, nrm)
	lm.disc("Trim", wc, nrm, 0.07, 12)
	lm.beam("Trim", wc, wc - b * 0.18, 0.05, 0.02, nrm)
	lm.beam("Trim", wc, wc + Vector3(0.3, -0.12, 0.0), 0.06, 0.06)

## A seat: cushion, back leaning by `tilt`, headrest.
static func _seat(lm: LandmarkMesh, at: Vector3, w: float, tilt: Basis) -> void:
	lm.box("Cabin", at + Vector3(0.25, -0.06, 0.0), Vector3(0.5, 0.13, w), Basis(), 0.04)
	lm.box("Cabin", at + Vector3(-0.04, 0.3, 0.0), Vector3(0.12, 0.6, w * 0.95), tilt, 0.04)
	lm.box("Cabin", at + Vector3(-0.12, 0.69, 0.0), Vector3(0.1, 0.17, w * 0.55), tilt, 0.035)

## A pickup's open bed between bed_x, its walls hung from the deck edge of
## the loft's rows (`c_roof`: the first roof point, the deck's edge).
static func bed(lm: LandmarkMesh, s: Dictionary, rows: Array, rx: PackedFloat32Array, re: PackedFloat32Array,
		c_roof: int) -> void:
	var bx: Vector2 = s["bed_x"]
	var fy := maxf(float(s["clear"]) + 0.42, VehicleKit.soft(s["belt"], 0.0, 0.1) - 0.48)
	var edge := PackedVector3Array()
	var sections: Array = []
	for r in rows.size():
		if re[r] == 0.0 and rx[r] >= bx.x - 0.002 and rx[r] <= bx.y + 0.002:
			var row: PackedVector3Array = rows[r]
			edge.append(row[c_roof])
			sections.append(row.slice(c_roof))
	if edge.size() < 2:
		return
	var low := PackedVector3Array()
	var mid_lo := PackedVector3Array()
	for p in edge:
		low.append(Vector3(p.x, fy, p.z))
		mid_lo.append(Vector3(p.x, fy, 0.0))
	_skin_facing(lm, [edge, low], Vector3(0, 0, -1))
	_skin_facing(lm, [low, mid_lo], Vector3.UP)
	# Cab back and tailgate: the deck's cross section down to the fy.
	for i: int in [0, sections.size() - 1]:
		var top: PackedVector3Array = sections[i]
		var foot := PackedVector3Array()
		for p in top:
			foot.append(Vector3(p.x, fy, p.z))
		_skin_facing(lm, [top, foot], Vector3(1, 0, 0) if i == 0 else Vector3(-1, 0, 0))
	# Ribs along the fy, and the rear arches standing in the bed.
	var zw := edge[0].z
	for k in 5:
		var z := lerpf(-zw, zw, (float(k) + 0.5) / 5.0)
		lm.box("Trim", Vector3((bx.x + bx.y) * 0.5, fy + 0.01, z), Vector3(bx.y - bx.x - 0.1, 0.02, 0.05), Basis(), 0.0)
	var ax := float(s["axle_r"])
	var ra := float(s["arch_r"])
	var top_y := float(s["wheel_r"]) + ra + 0.05
	if top_y > fy + 0.04:
		for side: float in [1.0, -1.0]:
			lm.box("Rubber", Vector3(ax, (fy + top_y) * 0.5, side * (zw - 0.12)),
				Vector3(ra * 2.0, top_y - fy, 0.24), Basis(), 0.04)

## skin() with mirroring, its quads turned to face `want` (on the +z half).
static func _skin_facing(lm: LandmarkMesh, rows: Array, want: Vector3) -> void:
	var p0: PackedVector3Array = rows[0]
	var p1: PackedVector3Array = rows[1]
	var n := Vector3.ZERO
	for c in p0.size() - 1:
		n += (p1[c + 1] - p0[c]).cross(p0[c + 1] - p1[c])
	VehicleKit.skin(lm, rows, func(_r: int, _c: int) -> String: return "Rubber", [], true, n.dot(want) < 0.0)

## Seven characters across a number plate whose face centre is `at`, in
## its frame `f` (x out of it, y up, z across), drawn as seven-segment
## strokes chosen by `code`.
static func plate_text(lm: LandmarkMesh, at: Vector3, f: Basis, code: int) -> void:
	const SEGS := [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71]
	var cw := 0.044
	var ch := 0.07
	var st := 0.008
	for i in 7:
		var zc := (float(i) - 3.0) * 0.062 + (0.012 if i >= 3 else -0.012)
		var bits: int = SEGS[(code * 7 + i * 13 + i * i * 5) % SEGS.size()]
		# Segments a..g: top, upper right, lower right, bottom, lower left,
		# upper left, middle (y, z offsets; vertical or not).
		var seg := [[ch * 0.5, 0.0, false], [ch * 0.25, cw * 0.5, true], [-ch * 0.25, cw * 0.5, true],
			[-ch * 0.5, 0.0, false], [-ch * 0.25, -cw * 0.5, true], [ch * 0.25, -cw * 0.5, true], [0.0, 0.0, false]]
		for k in 7:
			if bits & (1 << k) == 0:
				continue
			var sg: Array = seg[k]
			var size := Vector3(0.003, ch * 0.5 + st * 0.5, st) if sg[2] else Vector3(0.003, st, cw + st * 0.5)
			# f.z runs to the reader's left on both plates: read along -f.z.
			lm.box("Trim", at + f.y * float(sg[0]) - f.z * (zc + float(sg[1])), size, f, 0.0)
