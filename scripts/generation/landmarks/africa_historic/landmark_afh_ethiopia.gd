class_name LandmarkAfhEthiopia
extends RefCounted

## Two Ethiopian monuments in true metres: the rock-hewn Church of
## St George at Lalibela and the Obelisk of Axum with the fallen Great
## Stele.

# --- Church of St George, Lalibela ---

const LA_FLOOR := 0.35
const LA_RIM := 15.0
const LA_X := 30.0
const LA_Z := 27.5
## Half-width and arm half-length of the cross-shaped trench round the church.
const LA_WV := 6.9
const LA_LV := 10.8

## The monolithic Greek-cross church as it would look with the surrounding
## ground cut away: y = 0 is the trench floor and the ground outside, and the
## 60 x 55 m rock mass stands 15 m above it, stepped on its outer faces,
## with the cross-shaped trench cut into it and a rock-cut stair climbing
## out of the west arm. The church (three-step plinth, three window tiers,
## cross-within-cross roof) stands in the trench with its roof flush with
## the rim. Origin at the centre of the church; arms along the axes.
static func lalibela_st_george(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tuff", LandmarkMaterials.pbr("stone", "#A85C44", 5.0))
	lm.use("Church", LandmarkMaterials.pbr("stone", "#B96B4E", 3.0))
	lm.use("Dark", LandmarkMaterials.glass("#2A1812"))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#8E5E48", 4.0))
	lm.box("Floor", Vector3(0, 0.0, 0), Vector3(LA_X * 2.0 + 1.0, LA_FLOOR * 2.0, LA_Z * 2.0 + 1.0))
	_la_rock(lm)
	var f := LA_FLOOR
	_cross(lm, "Church", f, f + 0.6, 3.7, 7.6)
	_cross(lm, "Church", f + 0.6, f + 1.2, 3.1, 7.0)
	_cross(lm, "Church", f + 1.2, f + 1.8, 2.6, 6.5)
	_cross(lm, "Church", f + 1.8, f + 12.0, 2.1, 6.0)
	_cross(lm, "Church", f + 5.6, f + 6.1, 2.3, 6.2)
	_cross(lm, "Church", f + 9.7, f + 10.2, 2.3, 6.2)
	# Stepped roof carved as a cross within a cross.
	_cross(lm, "Church", f + 12.0, f + 12.8, 2.5, 6.4)
	_cross(lm, "Church", f + 12.8, f + 13.7, 1.5, 5.4)
	_cross(lm, "Church", f + 13.7, f + 14.6, 0.8, 3.8)
	for a in 4:
		var rot := Basis(Vector3.UP, float(a) * PI * 0.5)
		var dir: Vector3 = rot * Vector3(1, 0, 0)
		var side: Vector3 = rot * Vector3(0, 0, 1)
		# Arm end: a door (west, north and south arms; the east arm holds
		# the sanctuary), then two tiers of windows and a small top light.
		var end := dir * 6.0
		if a != 0:
			LandmarkAfhDetail.niche(lm, "Church", "Dark", end + Vector3(0, f + 1.8, 0), dir, 1.4, 2.8, "rect",
				0.3, 0.2, false)
			LandmarkAfhDetail.niche(lm, "Church", "Dark", end + Vector3(0, f + 6.4, 0), dir, 1.0, 1.8, "rect",
				0.22, 0.16, true)
			_aksumite_heads(lm, end + Vector3(0, f + 6.4, 0), dir, 1.0, 1.8)
		else:
			for u in [-0.9, 0.9]:
				var p: Vector3 = end + side * float(u) + Vector3(0, f + 2.6, 0)
				LandmarkAfhDetail.niche(lm, "Church", "Church", p, dir, 0.8, 1.6, "rect", 0.22, 0.16, true)
				_aksumite_heads(lm, p, dir, 0.8, 1.6)
				LandmarkAfhDetail.niche(lm, "Church", "Dark", end + side * float(u) + Vector3(0, f + 6.4, 0), dir,
					0.8, 1.8, "rect", 0.2, 0.16, true)
		for u in [-1.0, 1.0]:
			_ogive(lm, end + side * float(u) + Vector3(0, f + 10.3, 0), dir, 0.7, 1.3)
		# Arm sides: a blind Aksumite window below, a real one in the
		# middle tier and a pointed (floral ogive) light above.
		for sgn in [-1.0, 1.0]:
			var out: Vector3 = side * float(sgn)
			var o: Vector3 = dir * 4.05 + out * 2.1
			var lo: Vector3 = o + Vector3(0, f + 2.6, 0)
			LandmarkAfhDetail.niche(lm, "Church", "Church", lo, out, 0.9, 1.7, "rect", 0.22, 0.16, true)
			_aksumite_heads(lm, lo, out, 0.9, 1.7)
			var mid: Vector3 = o + Vector3(0, f + 6.5, 0)
			LandmarkAfhDetail.niche(lm, "Church", "Dark", mid, out, 0.9, 1.6, "rect", 0.2, 0.16, true)
			_aksumite_heads(lm, mid, out, 0.9, 1.6)
			_ogive(lm, o + Vector3(0, f + 10.3, 0), out, 0.8, 1.3)
	# Roof: raised borders tracing the nested crosses.
	for k in 3:
		var hw: float = [2.5, 1.5, 0.8][k]
		var arm: float = [6.4, 5.4, 3.8][k]
		var y: float = f + [12.8, 13.7, 14.6][k] - 0.05
		_cross_rim(lm, y, hw, arm)
	_la_tombs(lm)
	lm.commit(model)

## Upper-tier floral ogive window: a pointed opening whose frame holds
## a trefoil tracery inside.
static func _ogive(lm: LandmarkMesh, p: Vector3, out: Vector3, w: float, h: float) -> void:
	LandmarkAfhDetail.niche(lm, "Church", "Dark", p, out, w, h, "pointed", 0.16, 0.12, true)
	LandmarkAfhDetail.niche(lm, "Church", "Dark", p + Vector3(0, h * 0.12, 0), out, w * 0.62, h * 0.72, "lobed",
		0.05, 0.07, false, 3)
	lm.beam("Church", p + out * 0.035, p + out * 0.035 + Vector3(0, h * 0.12, 0), 0.06, 0.07, out)

## Projecting frame-beam ends ("monkey heads") at the four corners of an
## Aksumite window frame whose sill centre is `p` on a face.
static func _aksumite_heads(lm: LandmarkMesh, p: Vector3, out: Vector3, w: float, h: float) -> void:
	var right := Vector3.UP.cross(out).normalized()
	for su in [-1.0, 1.0]:
		for sv in [0.0, 1.0]:
			var q: Vector3 = p + right * (w * 0.5 + 0.24) * float(su) + Vector3(0, -0.12 + (h + 0.24) * float(sv), 0)
			lm.beam("Church", q, q + out * 0.32, 0.22, 0.22, Vector3.UP, true)

## Low rim (a cross outline of beams) at height y round a cross of
## centre half-width hw and arm reach `arm`.
static func _cross_rim(lm: LandmarkMesh, y: float, hw: float, arm: float) -> void:
	var pts: Array[Vector2] = []
	for q in 4:
		var r := Basis(Vector3.UP, float(q) * PI * 0.5)
		for v in [Vector3(arm, 0, -hw), Vector3(arm, 0, hw), Vector3(hw, 0, hw)]:
			var w: Vector3 = r * (v as Vector3)
			pts.append(Vector2(w.x, w.z))
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		lm.beam("Church", Vector3(a.x, y + 0.08, a.y), Vector3(b.x, y + 0.08, b.y), 0.2, 0.16, Vector3.UP)

## Open tombs cut into the trench walls (rectangular cells with
## rock-cut frames), at varying heights round the cross.
static func _la_tombs(lm: LandmarkMesh) -> void:
	var w := LA_WV
	var l := LA_LV
	var spots := [[Vector3(l, 0, -4.0), Vector3(-1, 0, 0)], [Vector3(l, 0, 4.0), Vector3(-1, 0, 0)],
		[Vector3(-4.0, 0, l), Vector3(0, 0, -1)], [Vector3(4.0, 0, l), Vector3(0, 0, -1)],
		[Vector3(-4.0, 0, -l), Vector3(0, 0, 1)], [Vector3(4.0, 0, -l), Vector3(0, 0, 1)],
		[Vector3(w, 0, 8.5), Vector3(-1, 0, 0)], [Vector3(-w, 0, 8.5), Vector3(1, 0, 0)],
		[Vector3(w, 0, -8.5), Vector3(-1, 0, 0)], [Vector3(-w, 0, -8.5), Vector3(1, 0, 0)],
		[Vector3(8.5, 0, w), Vector3(0, 0, -1)], [Vector3(8.5, 0, -w), Vector3(0, 0, 1)],
		[Vector3(-8.5, 0, w), Vector3(0, 0, -1)], [Vector3(-8.5, 0, -w), Vector3(0, 0, 1)]]
	for i in spots.size():
		var p: Vector3 = spots[i][0]
		var out: Vector3 = spots[i][1]
		var y := 1.0 + 6.0 * LandmarkAfhParts.hash01(i, 3)
		LandmarkAfhDetail.niche(lm, "Tuff", "Dark", p + Vector3(0, y, 0), out, 1.2 + 0.6 * LandmarkAfhParts.hash01(i, 9),
			1.4, "rect", 0.25, 0.18, true)

## The rock mass round the trench: eight blocks (four corners, four arm
## ends) each stacked in four layers that step in from the outer faces. The
## west arm end is split by a 4 m channel holding the rock-cut stair.
static func _la_rock(lm: LandmarkMesh) -> void:
	var w := LA_WV
	var l := LA_LV
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x0: float = w if sx > 0.0 else -LA_X
			var x1: float = LA_X if sx > 0.0 else -w
			var z0: float = w if sz > 0.0 else -LA_Z
			var z1: float = LA_Z if sz > 0.0 else -w
			_la_block(lm, x0, x1, z0, z1, sx < 0.0, sx > 0.0, sz < 0.0, sz > 0.0)
	_la_block(lm, l, LA_X, -w, w, false, true, false, false)
	_la_block(lm, -w, w, -LA_Z, -l, false, false, true, false)
	_la_block(lm, -w, w, l, LA_Z, false, false, false, true)
	_la_block(lm, -LA_X, -l, -w, -2.0, true, false, false, false)
	_la_block(lm, -LA_X, -l, 2.0, w, true, false, false, false)
	# Rock-cut stair up the channel, 0.6 m risers, out to the stepped face.
	for k in 12:
		var h := 0.6 * float(k + 1)
		lm.box("Tuff", Vector3(-l - 1.5 * (float(k) + 0.5), h * 0.5, 0), Vector3(1.5, h, 3.9))

## One rock block over x0..x1, z0..z1 in four layers up to the rim; the
## flagged sides are outer faces that step in 2.5 m per layer.
static func _la_block(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float,
		in_xmin: bool, in_xmax: bool, in_zmin: bool, in_zmax: bool) -> void:
	var tops: Array[float] = [4.0, 8.0, 12.0, LA_RIM]
	var y0 := -0.3
	for k in 4:
		var d := 2.5 * float(k)
		var ax := x0 + (d if in_xmin else 0.0)
		var bx := x1 - (d if in_xmax else 0.0)
		var az := z0 + (d if in_zmin else 0.0)
		var bz := z1 - (d if in_zmax else 0.0)
		lm.box("Tuff", Vector3((ax + bx) * 0.5, (y0 + tops[k]) * 0.5, (az + bz) * 0.5),
			Vector3(bx - ax, tops[k] - y0, bz - az))
		y0 = tops[k]

## Greek-cross plan from y0 to y1: centre square of half-width hw and four
## arms out to `arm` from the centre.
static func _cross(lm: LandmarkMesh, key: String, y0: float, y1: float, hw: float, arm: float) -> void:
	var h := y1 - y0
	var cy := (y0 + y1) * 0.5
	var mid := (hw + arm) * 0.5
	var arm_len := arm - hw
	lm.box(key, Vector3(0, cy, 0), Vector3(hw * 2.0, h, hw * 2.0))
	for s in [-1.0, 1.0]:
		lm.box(key, Vector3(s * mid, cy, 0), Vector3(arm_len, h, hw * 2.0))
		lm.box(key, Vector3(0, cy, s * mid), Vector3(hw * 2.0, h, arm_len))

# --- Obelisk of Axum ---

## Origin at the foot of the 24.6 m obelisk (re-erected on its two-step
## base, broad face south): a granite-grey stela of ten false storeys
## with log-end bands, windows and a false door, rounded at the top. To
## the south lies the 33 m Great Stele, broken in four pieces, its
## decorated face up.
static func aksum_obelisk(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stele", LandmarkMaterials.pbr("stone", "#857868", 2.5))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#9B9183", 3.0))
	lm.use("Dark", LandmarkMaterials.glass("#1E1A16"))
	lm.box("Base", Vector3(0, 0.15, 0), Vector3(4.4, 0.3, 3.5))
	lm.box("Base", Vector3(0, 0.45, 0), Vector3(3.5, 0.3, 2.7))
	_stele(lm, Transform3D(Basis(), Vector3(0, 0.6, 0)), [24.0, 2.32, 1.36, 1.55, 0.95, 10, 2.2], -1, 10)
	# The Great Stele, lying head to the east: length 33 m, 3.84 x 2.35 m
	# at the foot. Piece k starts at element `starts[k]`, shifted and turned
	# a little where it broke.
	var heading := deg_to_rad(80.0)
	var along := Vector3(sin(heading), 0, cos(heading))
	var across := Vector3.UP.cross(along).normalized()
	var xf := Transform3D(Basis(across, along, Vector3.UP), Vector3(-30, 0.8, 34))
	var spec := [33.0, 3.84, 2.35, 2.65, 1.7, 13, 3.0]
	var sh := (33.0 - 3.0 - 1.325) / 13.0
	var pieces := [[-1, 3, 0.0], [4, 6, 0.5], [7, 9, 1.1], [10, 13, 1.6]]
	var rolls := [0.0, 2.0, -3.0, 4.0]
	var lateral := [0.0, 0.35, -0.5, 0.2]
	for k in 4:
		var e0: int = pieces[k][0]
		var e1: int = pieces[k][1]
		var ys: float = 0.0 if e0 < 0 else 3.0 + sh * float(e0)
		var rot := Basis(Vector3(0, 0, 1), deg_to_rad(float(rolls[k])))
		var pivot := Vector3(0, ys, 0)
		var adj := Transform3D(rot, pivot - rot * pivot + Vector3(float(lateral[k]), float(pieces[k][2]), 0))
		_stele(lm, xf * adj, spec, e0, e1)
	lm.commit(model)

## One stele (or a run of its elements) in the frame `xf`: local Y runs up
## its length, X across the broad face, Z through the thickness. `spec` =
## [length, foot width, foot depth, head width, head depth, storeys, base
## height]. Elements: -1 the base block with the false door, 0..n-1 the
## storeys (windows and a log-end band each), n the semicircular crown.
static func _stele(lm: LandmarkMesh, xf: Transform3D, spec: Array, e0: int, e1: int) -> void:
	var length: float = spec[0]
	var w0: float = spec[1]
	var d0: float = spec[2]
	var w1: float = spec[3]
	var d1: float = spec[4]
	var n: int = spec[5]
	var base_h: float = spec[6]
	var crown := w1 * 0.5
	var sh := (length - base_h - crown) / float(n)
	var bx := xf.basis.x.normalized()
	var by := xf.basis.y.normalized()
	var bz := xf.basis.z.normalized()
	for e in range(e0, e1 + 1):
		if e == n:
			# Semicircular crown as six stacked slices.
			for j in 6:
				var yc := crown * (float(j) + 0.5) / 6.0
				var wj := 2.0 * sqrt(maxf(crown * crown - yc * yc, 0.0))
				var dj := lerpf(d0, d1, 1.0)
				var ya := length - crown + crown * float(j) / 6.0
				LandmarkAfhParts.tapered(lm, "Stele", xf, ya, ya + crown / 6.0, wj, dj, wj, dj)
			continue
		var y0 := 0.0 if e < 0 else base_h + sh * float(e)
		var y1 := base_h if e < 0 else y0 + sh
		var wa := lerpf(w0, w1, y0 / length)
		var da := lerpf(d0, d1, y0 / length)
		var wb := lerpf(w0, w1, y1 / length)
		var db := lerpf(d0, d1, y1 / length)
		LandmarkAfhParts.tapered(lm, "Stele", xf, y0, y1, wa, da, wb, db)
		if e < 0:
			for sgn in [-1.0, 1.0]:
				_false_door(lm, xf * Vector3(0, 0.1, float(sgn) * (da * 0.5)), bx, by, bz * float(sgn),
					wa * 0.42, base_h * 0.78)
			continue
		LandmarkAfhParts.tapered(lm, "Stele", xf, y1 - 0.3, y1, wb + 0.22, db + 0.22, wb + 0.22, db + 0.22)
		var wm := (wa + wb) * 0.5
		var dm := (da + db) * 0.5
		var wy := y0 + sh * 0.2
		for sgn in [-1.0, 1.0]:
			for u in [-0.28, 0.0, 0.28]:
				var p: Vector3 = xf * Vector3(float(u) * wm, wy, float(sgn) * (dm * 0.5))
				_framed(lm, p, bx, by, bz * float(sgn), wm * 0.14, sh * 0.5)
			var q: Vector3 = xf * Vector3(float(sgn) * (wm * 0.5), wy, 0)
			_framed(lm, q, bz, by, bx * float(sgn), dm * 0.3, sh * 0.5)
			# Round beam ends ("monkey heads") in the band under the cornice.
			var nb := maxi(int(wb / 0.32), 3)
			for k in nb:
				var u := (float(k) + 0.5) / float(nb) - 0.5
				var hp: Vector3 = xf * Vector3(u * wb * 0.92, y1 - 0.55, float(sgn) * db * 0.5)
				lm.beam("Stele", hp, hp + bz * float(sgn) * 0.1, 0.16, 0.16, by, true)
			var ns := maxi(int(db / 0.32), 2)
			for k in ns:
				var u := (float(k) + 0.5) / float(ns) - 0.5
				var hp: Vector3 = xf * Vector3(float(sgn) * wb * 0.5, y1 - 0.55, u * db * 0.9)
				lm.beam("Stele", hp, hp + bx * float(sgn) * 0.1, 0.16, 0.16, by, true)

## A carved false door w x h whose sill centre `p` lies on the face:
## a framed door with its beam-end corners, two panels and the lock.
static func _false_door(lm: LandmarkMesh, p: Vector3, right: Vector3, up: Vector3, out: Vector3,
		w: float, h: float) -> void:
	_window(lm, p, right, up, out, w, h)
	for su in [-1.0, 1.0]:
		lm.beam("Stele", p + right * (w * 0.5 + 0.06) * float(su) + out * 0.05,
			p + right * (w * 0.5 + 0.06) * float(su) + out * 0.05 + up * (h + 0.12), 0.12, 0.1, out)
		for sv in [0.0, 1.0]:
			var q: Vector3 = p + right * (w * 0.5 + 0.1) * float(su) + up * (h + 0.06) * float(sv)
			lm.beam("Stele", q, q + out * 0.14, 0.16, 0.16, up, true)
	lm.beam("Stele", p + up * (h + 0.06) - right * (w * 0.5 + 0.12) + out * 0.05,
		p + up * (h + 0.06) + right * (w * 0.5 + 0.12) + out * 0.05, 0.12, 0.1, out)
	# Door leaves (two panels) and the carved lock.
	for sv in [0.25, 0.7]:
		var c: Vector3 = p + up * h * float(sv) + out * 0.045
		lm.beam("Stele", c - right * w * 0.3, c + right * w * 0.3, 0.05, h * 0.3, out)
	lm.beam("Stele", p + up * h * 0.5 + right * w * 0.25, p + up * h * 0.5 + right * w * 0.25 + out * 0.08,
		0.08, 0.14, up, true)

## Framed window recess at `p` (bottom centre on the face): a dark
## opening with a thin projecting frame and its cross mullion.
static func _framed(lm: LandmarkMesh, p: Vector3, right: Vector3, up: Vector3, out: Vector3,
		w: float, h: float) -> void:
	_window(lm, p, right, up, out, w, h)
	var f := 0.05
	for su in [-1.0, 1.0]:
		lm.beam("Stele", p + right * (w * 0.5 + f * 0.5) * float(su) + out * 0.03 - up * f,
			p + right * (w * 0.5 + f * 0.5) * float(su) + out * 0.03 + up * (h + f), f, 0.06, out)
	for sv in [0.0, 1.0]:
		lm.beam("Stele", p + up * (h + f * 0.5) * float(sv) - up * f * 0.5 * (1.0 - float(sv)) * 2.0
			- right * (w * 0.5 + f) + out * 0.03, p + up * (h + f * 0.5) * float(sv)
			- up * f * 0.5 * (1.0 - float(sv)) * 2.0 + right * (w * 0.5 + f) + out * 0.03, f, 0.06, out)
	lm.beam("Stele", p + up * h * 0.5 - right * w * 0.5 + out * 0.02, p + up * h * 0.5 + right * w * 0.5 + out * 0.02,
		0.04, 0.04, out)
	lm.beam("Stele", p + out * 0.02, p + up * h + out * 0.02, 0.04, 0.04, out)

## Dark recess quad at `p` (bottom centre), w wide along `right`, h tall.
static func _window(lm: LandmarkMesh, p: Vector3, right: Vector3, up: Vector3, out: Vector3,
		w: float, h: float) -> void:
	var q := p + out * 0.025
	LandmarkAfhParts.quad_out(lm, "Dark", q - right * w * 0.5, q + right * w * 0.5,
		q + right * w * 0.5 + up * h, q - right * w * 0.5 + up * h, out)
