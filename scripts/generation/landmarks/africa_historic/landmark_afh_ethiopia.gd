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
		SEuUtil.face_row(lm, "Dark", dir * 6.0, side, dir, f + 2.4, 2, 1.8, 1.1, 2.8)
		SEuUtil.face_row(lm, "Dark", dir * 6.0, side, dir, f + 6.4, 2, 1.8, 1.0, 2.2)
		SEuUtil.face_row(lm, "Dark", dir * 6.0, side, dir, f + 10.5, 1, 1.0, 0.9, 1.1)
		for sgn in [-1.0, 1.0]:
			var o: Vector3 = dir * 4.05 + side * float(sgn) * 2.1
			var out: Vector3 = side * float(sgn)
			SEuUtil.face_row(lm, "Dark", o, dir, out, f + 2.4, 1, 1.0, 1.0, 2.6)
			SEuUtil.face_row(lm, "Dark", o, dir, out, f + 6.4, 1, 1.0, 0.9, 2.0)
			SEuUtil.face_row(lm, "Dark", o, dir, out, f + 10.5, 1, 1.0, 0.8, 1.0)
	lm.commit(model)

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
				var p: Vector3 = xf * Vector3(0, 0.1, float(sgn) * (da * 0.5 + 0.03))
				_window(lm, p, bx, by, bz * float(sgn), wa * 0.3, base_h * 0.7)
			continue
		LandmarkAfhParts.tapered(lm, "Stele", xf, y1 - 0.3, y1, wb + 0.22, db + 0.22, wb + 0.22, db + 0.22)
		var wm := (wa + wb) * 0.5
		var dm := (da + db) * 0.5
		var wy := y0 + sh * 0.2
		for sgn in [-1.0, 1.0]:
			for u in [-0.28, 0.0, 0.28]:
				var p: Vector3 = xf * Vector3(float(u) * wm, wy, float(sgn) * (dm * 0.5 + 0.03))
				_window(lm, p, bx, by, bz * float(sgn), wm * 0.14, sh * 0.5)
			var q: Vector3 = xf * Vector3(float(sgn) * (wm * 0.5 + 0.03), wy, 0)
			_window(lm, q, bz, by, bx * float(sgn), dm * 0.3, sh * 0.5)

## Dark recess quad at `p` (bottom centre), w wide along `right`, h tall.
static func _window(lm: LandmarkMesh, p: Vector3, right: Vector3, up: Vector3, out: Vector3,
		w: float, h: float) -> void:
	LandmarkAfhParts.quad_out(lm, "Dark", p - right * w * 0.5, p + right * w * 0.5,
		p + right * w * 0.5 + up * h, p - right * w * 0.5 + up * h, out)
