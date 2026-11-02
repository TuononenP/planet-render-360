class_name LandmarkChTowers
extends RefCounted

## Two Gothic towers of Prague in true metres: the Old Town Hall tower
## (square, 1364, 69.5 m) with the Astronomical Clock on its south face
## (+Z), the Marian chapel oriel (1381) on its east face and the row of
## town hall houses running west along the square, and the Powder Tower
## (late Gothic gate tower of 1475, 65 m, neo-Gothic dress by Josef
## Mocker 1875-86: gallery, corner turrets, hipped roof; passage along Z).

# --- Old Town Hall tower and Astronomical Clock ---

const ORLOJ_TOP := 69.5
## Half-width of the square tower shaft.
const ORLOJ_HW := 5.2
## Gallery floor level, at the head of the shaft.
const ORLOJ_GALLERY := 52.0

static func orloj(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B3A88F", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#CDC4AB", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4F5A55", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Blue", LandmarkMaterials.paint("#2D4F86", 0.45, 0.2))
	lm.use("Earth", LandmarkMaterials.paint("#3B2E26", 0.5, 0.1))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Wing", LandmarkMaterials.pbr("render", "#D8C697", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9A36B", 3.0))
	lm.use("Sgraffito", LandmarkMaterials.pbr("render", "#8C826F", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4A30", 2.5))
	_orloj_shaft(lm)
	_orloj_top(lm)
	_orloj_clock(lm)
	_orloj_oriel(lm)
	_orloj_houses(lm)
	lm.commit(model)

## Square stone shaft with corner lesenes, string courses and lancets.
static func _orloj_shaft(lm: LandmarkMesh) -> void:
	var hw := ORLOJ_HW
	var g := ORLOJ_GALLERY
	lm.box("Pale", Vector3(0, 0.5, 0), Vector3(hw * 2.0 + 0.8, 1.0, hw * 2.0 + 0.8))
	lm.box("Stone", Vector3(0, g * 0.5, 0), Vector3(hw * 2.0, g, hw * 2.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Pale", Vector3(sx * (hw - 0.3), g * 0.5, sz * (hw - 0.3)), Vector3(1.0, g, 1.0))
	for y in [14.5, 30.0, 42.0]:
		LandmarkChParts.band(lm, "Pale", y, hw, hw, 0.5, 0.25)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := b * Vector3(0, 0, hw)
		# The south face carries the clock low down; the others a lancet.
		if f != 0:
			LandmarkChParts.lancet(lm, "Pale", "Windows", face + Vector3(0, 7.0, 0), n, 1.3, 5.0, 1)
		LandmarkChParts.lancet(lm, "Pale", "Windows", face + Vector3(0, 19.0, 0), n, 1.4, 5.4, 1)
		for x in [-1.8, 1.8]:
			LandmarkChParts.lancet(lm, "Pale", "Windows", face + b * Vector3(x, 33.0, 0), n, 1.1, 5.0, 1)
			LandmarkChParts.lancet(lm, "Pale", "Windows", face + b * Vector3(x, 44.5, 0), n, 1.2, 5.2, 1)
		# Corbel table carrying the projecting gallery.
		var a := b * Vector3(-hw + 0.8, g, hw)
		var e := b * Vector3(hw - 0.8, g, hw)
		LandmarkChParts.corbels(lm, "Pale", a, e, n * 1.0, 1.1, 1.4)

## Gallery with tracery parapet, four corner bartizans with spires, the
## steep central roof with lucarnes and the gilt finial.
static func _orloj_top(lm: LandmarkMesh) -> void:
	var hw := ORLOJ_HW
	var g := ORLOJ_GALLERY
	var gw := hw + 1.0
	lm.box("Pale", Vector3(0, g + 0.35, 0), Vector3(gw * 2.0, 0.7, gw * 2.0))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.tracery_parapet(lm, "Pale", b * Vector3(-gw + 1.3, g + 0.7, gw - 0.15),
			b * Vector3(gw - 1.3, g + 0.7, gw - 0.15), 1.2, 1.1, 0.22)
	# Inner wall of the belvedere stage under the roof.
	lm.box("Stone", Vector3(0, g + 2.2, 0), Vector3(hw * 1.6, 3.0, hw * 1.6))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		for x in [-1.5, 1.5]:
			LandmarkChParts.lancet(lm, "Pale", "Windows", b * Vector3(x, g + 1.0, hw * 0.8), b.z, 0.8, 2.4, 0)
	# Corner bartizans on corbelled bases.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * (gw - 0.4), 0, sz * (gw - 0.4))
			lm.lathe("Pale", p + Vector3(0, g - 2.5, 0), PackedVector2Array([Vector2(0.15, 0), Vector2(0.6, 0.9),
				Vector2(1.05, 2.0), Vector2(1.2, 2.5)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.lathe("Stone", p + Vector3(0, g, 0), PackedVector2Array([Vector2(1.15, 0), Vector2(1.1, 4.8)]), 8,
				1.0, 1.0, PI / 8.0, false)
			lm.frustum("Pale", p + Vector3(0, g + 4.6, 0), 1.3, 1.3, 0.4, 8, PI / 8.0)
			for k in 4:
				var a := PI * 0.5 * float(k) + PI * 0.25
				var d := Vector3(cos(a), 0, sin(a))
				LandmarkChParts.lancet(lm, "Pale", "Windows", p + d * 1.1 + Vector3(0, g + 1.6, 0), d, 0.45, 1.8, 0, 0.12)
			lm.lathe("Roof", p + Vector3(0, g + 5.0, 0), PackedVector2Array([Vector2(1.45, 0), Vector2(1.0, 1.4),
				Vector2(0.5, 4.0), Vector2(0.05, 6.4)]), 8, 1.0, 1.0, PI / 8.0, false)
			LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, g + 11.4, 0), 1.2, 0.18)
	# Steep central roof, its lucarnes and the finial.
	var rb := Vector3(0, g + 3.7, 0)
	lm.lathe("Roof", rb, PackedVector2Array([Vector2(hw * 1.18, 0), Vector2(hw * 0.95, 1.2), Vector2(3.0, 4.6),
		Vector2(1.5, 8.0), Vector2(0.25, 11.2)]), 4, 1.0, 1.0, PI * 0.25, false)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var lc := rb + b * Vector3(0, 1.8, 3.6)
		lm.box("Stone", lc + Vector3(0, 0.8, 0), Vector3(1.4, 1.6, 1.6), b)
		lm.gable("Roof", lc + Vector3(0, 1.6, 0), 1.4, 1.6, 1.0, b, 0.1, "Stone")
		LandmarkChParts.lancet(lm, "Pale", "Windows", lc + b * Vector3(0, 0.2, 0.8), b.z, 0.6, 1.2, 0, 0.1)
	var tip := rb + Vector3(0, 11.2, 0)
	lm.lathe("Gilt", tip - Vector3(0, 0.4, 0), PackedVector2Array([Vector2(0.15, 0), Vector2(0.45, 0.5),
		Vector2(0.5, 0.8), Vector2(0.3, 1.2), Vector2(0.08, 1.4)]), 10)
	LandmarkChParts.finial(lm, "Gilt", tip + Vector3(0, 1.0, 0), ORLOJ_TOP - tip.y - 1.0, 0.25)

## The Astronomical Clock (1410) in its late Gothic stone case on the
## south face: the astronomical dial (blue day sky, dark night, the
## eccentric zodiac ring, 24 Old Czech hours) with two figures each side,
## the calendar dial below with four more, the apostles' windows and the
## crocketed canopy with the cockerel.
static func _orloj_clock(lm: LandmarkMesh) -> void:
	var z := ORLOJ_HW
	var n := Vector3.BACK
	# Stone case: back panel, side piers with pinnacles, base.
	lm.box("Pale", Vector3(0, 7.5, z + 0.2), Vector3(6.4, 12.0, 0.4))
	lm.box("Pale", Vector3(0, 1.4, z + 0.5), Vector3(7.0, 0.8, 1.0))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 3.3, 7.6, z + 0.5), Vector3(0.6, 12.4, 0.7))
		LandmarkChParts.pinnacle(lm, "Pale", Vector3(sx * 3.3, 13.8, z + 0.5), 0.6, 3.2)
	# Astronomical dial.
	var dc := Vector3(0, 8.4, z + 0.42)
	lm.disc("Gilt", dc, n, 1.95, 36)
	lm.disc("Blue", dc + n * 0.04, n, 1.72, 36)
	_horizon(lm, "Earth", dc + n * 0.07, 1.72, -0.55)
	var zc := dc + Vector3(0, 0.42, 0) + n * 0.12
	var prev := zc + Vector3(1.12, 0, 0)
	for k in 24:
		var a := TAU * float(k + 1) / 24.0
		var q := zc + Vector3(cos(a), sin(a), 0) * 1.12
		lm.beam("Gilt", prev, q, 0.14, 0.06, n)
		prev = q
	for k in 24:
		var a := TAU * (float(k) + 0.5) / 24.0
		lm.box("Gilt", dc + Vector3(cos(a), sin(a), 0) * 1.84 + n * 0.08, Vector3(0.12, 0.2, 0.05),
			Basis(Vector3.BACK, a - PI * 0.5), 0.0)
	lm.beam("Gilt", dc + n * 0.18, dc + Vector3(1.2, 1.1, 0) + n * 0.18, 0.08, 0.04, n)
	lm.disc("Gilt", dc + Vector3(0.95, 0.87, 0) + n * 0.22, n, 0.2, 12)
	lm.beam("Gilt", dc + n * 0.2, dc + Vector3(-0.9, 0.6, 0) + n * 0.2, 0.06, 0.04, n)
	lm.disc("Earth", dc + Vector3(-0.7, 0.47, 0) + n * 0.24, n, 0.16, 12)
	# Calendar dial below.
	var cc := Vector3(0, 3.7, z + 0.42)
	lm.disc("Gilt", cc, n, 1.6, 36)
	lm.disc("Blue", cc + n * 0.04, n, 1.35, 36)
	lm.disc("Gilt", cc + n * 0.08, n, 0.5, 20)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.disc("Ochre", cc + Vector3(cos(a), sin(a), 0) * 0.95 + n * 0.09, n, 0.3, 10)
	# Figures: Vanity, Avarice, Death and the Turk by the upper dial,
	# the philosopher, archangel, astronomer and chronicler by the lower.
	for sx in [-1.0, 1.0]:
		for k in 2:
			var x: float = sx * (2.25 + 0.55 * k)
			lm.box("Pale", Vector3(x, 7.0, z + 0.7), Vector3(0.5, 0.2, 0.5))
			LandmarkKits.statue_figure(lm, "Ochre", Vector3(x, 7.1, z + 0.7), 1.25, k == 0)
			lm.box("Pale", Vector3(x, 3.0, z + 0.7), Vector3(0.5, 0.2, 0.5))
			LandmarkKits.statue_figure(lm, "Ochre", Vector3(x, 3.1, z + 0.7), 1.3, k == 1)
	# Apostles' windows, the canopy and the cockerel.
	for sx in [-0.7, 0.7]:
		LandmarkChParts.arched_window(lm, "Pale", "Windows", Vector3(sx, 11.0, z + 0.4), n, 0.9, 1.4, 0.15)
	LandmarkChParts.wimperg(lm, "Pale", Vector3(0, 13.1, z + 0.4), n, 6.2, 4.2, 0.35)
	lm.box("Gilt", Vector3(0, 13.0, z + 0.7), Vector3(0.3, 0.4, 0.2), Basis(), 0.0)

## Night half of the astronomical dial: the disc below a chord at `cut`
## (a fraction of r below the centre is negative), facing +Z.
static func _horizon(lm: LandmarkMesh, key: String, c: Vector3, r: float, cut: float) -> void:
	var n := Vector3.BACK
	var a0 := asin(cut)
	var steps := 14
	var y := r * cut
	for i in steps:
		var t0 := lerpf(PI - a0, TAU + a0, float(i) / float(steps))
		var t1 := lerpf(PI - a0, TAU + a0, float(i + 1) / float(steps))
		lm.tri(key, c + Vector3(0, y, 0), c + Vector3(cos(t0), sin(t0), 0) * r, c + Vector3(cos(t1), sin(t1), 0) * r,
			n, n, n, Vector2.ZERO, Vector2(cos(t0), sin(t0)) * r, Vector2(cos(t1), sin(t1)) * r)

## Marian chapel oriel on the east face: a five-sided (5/8) bay on a
## corbel cone, tracery lancets between buttresses, a pointed roof.
static func _orloj_oriel(lm: LandmarkMesh) -> void:
	var c := Vector3(ORLOJ_HW, 0, 0)
	var poly := PackedVector2Array()
	for i in 5:
		var a := -PI * 0.5 + PI * float(i) / 4.0
		poly.append(Vector2(c.x + cos(a) * 2.6, sin(a) * 2.6))
	lm.lathe("Pale", c + Vector3(0, 8.0, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(1.6, 1.6),
		Vector2(2.5, 2.8), Vector2(2.7, 3.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.poly_prism("Pale", poly, 11.0, 19.0)
	lm.lathe("Roof", c + Vector3(0, 19.0, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(1.6, 3.0),
		Vector2(0.2, 5.5)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkChParts.finial(lm, "Gilt", c + Vector3(0, 24.4, 0), 1.2, 0.2)
	for k in 4:
		var a := -PI * 0.5 + PI * (float(k) + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.lancet(lm, "Stone", "Windows", c + d * 2.42 + Vector3(0, 12.0, 0), d, 0.9, 5.4, 1, 0.2)
		LandmarkChParts.wimperg(lm, "Stone", c + d * 2.42 + Vector3(0, 17.5, 0), d, 1.2, 1.6, 0.2)
	for k in 5:
		var a := -PI * 0.5 + PI * float(k) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", c + d * 2.7 + Vector3(0, 15.0, 0), Vector3(0.35, 8.0, 0.35), Basis(Vector3.UP, -a))
		LandmarkChParts.pinnacle(lm, "Stone", c + d * 2.7 + Vector3(0, 19.0, 0), 0.35, 2.2)

## The town hall houses west of the tower along the square: Kriz house
## (neo-Gothic), Mikes house (neo-Renaissance), the Cockerel house and
## the Minute house with its sgraffito and arcade, under tiled roofs.
static func _orloj_houses(lm: LandmarkMesh) -> void:
	# [west x, east x, eave height, wall key, arched windows]
	var houses := [[-15.0, -5.2, 17.0, "Ochre", true], [-24.0, -15.0, 18.0, "Wing", false],
		[-31.0, -24.0, 16.5, "Ochre", false], [-43.0, -31.0, 17.5, "Sgraffito", false]]
	var depth := 16.0
	for h in houses:
		var x0: float = h[0]
		var x1: float = h[1]
		var eave: float = h[2]
		var key: String = h[3]
		var wdt := x1 - x0
		var cx := (x0 + x1) * 0.5
		var zc := ORLOJ_HW - depth * 0.5
		lm.box(key, Vector3(cx, eave * 0.5, zc), Vector3(wdt, eave, depth))
		lm.box("Pale", Vector3(cx, eave - 0.3, zc), Vector3(wdt + 0.1, 0.6, depth + 0.8))
		LandmarkDetail.cornice(lm, "Pale", Vector3(x0, eave - 0.6, ORLOJ_HW), Vector3(x1, eave - 0.6, ORLOJ_HW),
			Vector3.BACK, 0.6, false)
		lm.gable("Tile", Vector3(cx, eave, zc), depth, wdt, 7.5, Basis(Vector3.UP, PI * 0.5), 0.4, key)
		# Dormers on the square side of the roof.
		var dn := maxi(int(wdt / 4.5), 1)
		for i in dn:
			var dx := x0 + wdt * (float(i) + 0.5) / float(dn)
			var dp := Vector3(dx, eave + 1.6, ORLOJ_HW - 2.4)
			lm.box(key, dp + Vector3(0, 0.8, 0), Vector3(1.6, 1.8, 1.6))
			lm.gable("Tile", dp + Vector3(0, 1.7, 0), 1.6, 1.8, 1.0, Basis(), 0.15, key)
			LandmarkDetail.window(lm, "Pale", "Windows", dp + Vector3(0, 0.9, 0.8), Vector3.BACK, 0.7, 1.0, false, 0.12)
		# Storeys of windows on the square front.
		var cols := maxi(int(wdt / 3.0), 2)
		for r in 3:
			var y := 5.6 + 4.0 * r
			for i in cols:
				var wx := x0 + wdt * (float(i) + 0.5) / float(cols)
				var wc := Vector3(wx, y, ORLOJ_HW)
				if bool(h[4]):
					LandmarkChParts.lancet(lm, "Pale", "Windows", wc - Vector3(0, 1.2, 0), Vector3.BACK, 1.1, 2.8, 1, 0.2)
				else:
					LandmarkDetail.window(lm, "Pale", "Windows", wc + Vector3(0, 0.2, 0), Vector3.BACK, 1.1, 2.0, false, 0.18)
		# Ground storey: doors, or the Minute house's arcade.
		if key == "Sgraffito":
			for i in 3:
				var ax := x0 + wdt * (float(i) + 0.5) / 3.0
				LandmarkDetail.arch(lm, "Pale", Vector3(ax, 2.6, ORLOJ_HW), Vector3.BACK, 3.0, 0.4, 0.3)
				lm.box("Windows", Vector3(ax, 1.6, ORLOJ_HW + 0.02), Vector3(3.0, 3.2, 0.04), Basis(), 0.0)
			# Sgraffito panels framed between the storeys.
			for r in 3:
				lm.box("Pale", Vector3((x0 + x1) * 0.5, 7.3 + 4.0 * r, ORLOJ_HW + 0.06), Vector3(wdt - 0.4, 0.25, 0.12),
					Basis(), 0.0)
		else:
			LandmarkDetail.arch(lm, "Pale", Vector3(cx, 2.4, ORLOJ_HW), Vector3.BACK, 2.0, 0.3, 0.25)
			lm.box("Windows", Vector3(cx, 1.2, ORLOJ_HW + 0.02), Vector3(2.0, 2.4, 0.04), Basis(), 0.0)
		LandmarkChParts.band(lm, "Pale", 0.0, wdt * 0.5, depth * 0.5, 0.8, 0.15, Vector3(cx, 0, zc))
	# West end gable of the Minute house, facing the little square.
	for r in 3:
		for i in 4:
			LandmarkDetail.window(lm, "Pale", "Windows", Vector3(-43.0, 5.8 + 4.0 * r, ORLOJ_HW - 2.5 - 3.6 * i),
				Vector3.LEFT, 1.0, 2.0, false, 0.18)

# --- Powder Tower ---

const POWDER_TOP := 65.0
## Half-width of the square tower (about 14 m across).
const POWDER_HALF := 7.0
## Gallery level at the head of the shaft.
const POWDER_GALLERY := 40.0

static func powder(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7B7568", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("stone", "#9A9382", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4E4A42", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3F4447", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_powder_body(lm)
	_powder_decor(lm)
	_powder_top(lm)
	lm.commit(model)

## Shaft with the vaulted gate passage (pointed arch, along Z).
static func _powder_body(lm: LandmarkMesh) -> void:
	var h := POWDER_HALF
	var g := POWDER_GALLERY
	var pw := 2.6
	var spring := 6.0
	for sx in [-1.0, 1.0]:
		lm.box("Pale", Vector3(sx * (h + pw) * 0.5, 0.6, 0), Vector3(h - pw + 0.8, 1.2, h * 2.0 + 0.8))
		lm.box("Stone", Vector3(sx * (h + pw) * 0.5, spring * 0.5, 0), Vector3(h - pw, spring, h * 2.0))
	lm.box("Stone", Vector3(0, (spring + 4.6 + g) * 0.5, 0), Vector3(h * 2.0, g - spring - 4.6, h * 2.0))
	# Spandrels and soffit of the pointed passage vault.
	var arc := LandmarkChParts.pointed_arc(pw, 4)
	for sz in [-1.0, 1.0]:
		var zf: float = sz * h
		var nz := Vector3(0, 0, sz)
		for i in arc.size() - 1:
			var a := Vector3(arc[i].x, spring + arc[i].y, zf)
			var b := Vector3(arc[i + 1].x, spring + arc[i + 1].y, zf)
			lm.quad("Stone", a, b, Vector3(b.x, spring + 4.6, zf), Vector3(a.x, spring + 4.6, zf), nz)
	for i in arc.size() - 1:
		var a := Vector3(arc[i].x, spring + arc[i].y, 0)
		var b := Vector3(arc[i + 1].x, spring + arc[i + 1].y, 0)
		var dn := Vector3(-(b - a).y, (b - a).x, 0).normalized()
		var mid := (a + b) * 0.5
		if dn.dot(Vector3(-mid.x, spring - mid.y, 0)) < 0.0:
			dn = -dn
		lm.quad("Dark", a + Vector3(0, 0, -h), b + Vector3(0, 0, -h), b + Vector3(0, 0, h), a + Vector3(0, 0, h), dn)
	for sx in [-1.0, 1.0]:
		lm.quad("Dark", Vector3(sx * pw, 0, -h), Vector3(sx * pw, 0, h), Vector3(sx * pw, spring, h),
			Vector3(sx * pw, spring, -h), Vector3(-sx, 0, 0))
	# Net-vault ribs across the passage.
	for k in 5:
		var zk := -h + h * 2.0 * (float(k) + 0.5) / 5.0
		for i in arc.size() - 1:
			lm.beam("Pale", Vector3(arc[i].x, spring + arc[i].y - 0.1, zk),
				Vector3(arc[i + 1].x, spring + arc[i + 1].y - 0.1, zk), 0.25, 0.2, Vector3(0, 0, 1))

## Facade dress on all four faces: gate archivolt and wimperg with the
## kings' statues (W and E faces), string courses, tiers of blind
## tracery and tall traceried lancets, buttress lesenes with pinnacles.
static func _powder_decor(lm: LandmarkMesh) -> void:
	var h := POWDER_HALF
	for y in [12.5, 22.0, 34.5]:
		LandmarkChParts.band(lm, "Pale", y, h, h, 0.6, 0.3)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := b * Vector3(0, 0, h)
		var gate := f % 2 == 0
		# Corner lesenes with pinnacles at each string course.
		for sx in [-1.0, 1.0]:
			lm.box("Pale", face + b * Vector3(sx * (h - 0.5), 18.0, 0.2), Vector3(0.8, 34.0, 0.4), b)
			for y in [13.1, 22.6]:
				LandmarkChParts.pinnacle(lm, "Pale", face + b * Vector3(sx * (h - 0.5), y, 0.45), 0.6, 3.0)
		if gate:
			# Archivolt, wimperg, and the two kings in canopied niches.
			var arc := LandmarkChParts.pointed_arc(3.0, 5)
			for i in arc.size() - 1:
				lm.beam("Pale", face + b * Vector3(arc[i].x, 6.0 + arc[i].y, 0.2),
					face + b * Vector3(arc[i + 1].x, 6.0 + arc[i + 1].y, 0.2), 0.5, 0.4, n)
			LandmarkChParts.wimperg(lm, "Pale", face + Vector3(0, 6.0, 0), n, 7.0, 6.2, 0.4)
			for sx in [-1.0, 1.0]:
				var sp := face + b * Vector3(sx * 4.6, 7.0, 0.5)
				lm.box("Pale", sp, Vector3(1.2, 0.4, 1.0), b)
				LandmarkKits.statue_figure(lm, "Pale", sp + Vector3(0, 0.2, 0), 2.2)
				LandmarkChParts.pinnacle(lm, "Pale", sp + Vector3(0, 2.6, 0), 1.1, 3.0)
		else:
			for sx in [-3.0, 0.0, 3.0]:
				LandmarkChParts.lancet(lm, "Pale", "Dark", face + b * Vector3(sx, 3.0, 0), n, 1.6, 7.0, 1, 0.25)
		# Blind tracery tier between the first two courses.
		for i in 5:
			var x := -4.4 + 2.2 * i
			LandmarkChParts.lancet(lm, "Pale", "Dark", face + b * Vector3(x, 14.0, 0), n, 1.3, 6.4, 1, 0.22)
			lm.box("Pale", face + b * Vector3(x + 1.1, 17.6, 0.15), Vector3(0.22, 7.2, 0.3), b, 0.0)
		# Tall traceried windows in the main stage with their wimpergs.
		for x in [-2.5, 2.5]:
			LandmarkChParts.lancet(lm, "Pale", "Windows", face + b * Vector3(x, 23.6, 0), n, 2.2, 9.5, 1, 0.3)
			LandmarkChParts.wimperg(lm, "Pale", face + b * Vector3(x, 31.0, 0.1), n, 2.8, 3.0, 0.3)
		# Blind arcade frieze under the corbel table.
		for i in 9:
			LandmarkChParts.lancet(lm, "Pale", "Dark", face + b * Vector3(-4.8 + 1.2 * i, 35.4, 0), n, 0.8, 2.6, 0, 0.18)
		LandmarkChParts.corbels(lm, "Pale", face + b * Vector3(-h + 0.6, POWDER_GALLERY, 0),
			face + b * Vector3(h - 0.6, POWDER_GALLERY, 0), n * 1.0, 1.2, 1.6)

## Gallery, corner turrets, the steep hipped roof with its lucarnes and
## the finial.
static func _powder_top(lm: LandmarkMesh) -> void:
	var h := POWDER_HALF
	var g := POWDER_GALLERY
	var gw := h + 1.0
	lm.box("Pale", Vector3(0, g + 0.4, 0), Vector3(gw * 2.0, 0.8, gw * 2.0))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.tracery_parapet(lm, "Pale", b * Vector3(-gw + 1.6, g + 0.8, gw - 0.15),
			b * Vector3(gw - 1.6, g + 0.8, gw - 0.15), 1.3, 1.2, 0.24)
	lm.box("Stone", Vector3(0, g + 3.3, 0), Vector3(h * 1.6, 5.0, h * 1.6))
	LandmarkChParts.band(lm, "Pale", g + 5.6, h * 0.8, h * 0.8, 0.5, 0.3)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		for x in [-2.2, 2.2]:
			LandmarkChParts.lancet(lm, "Pale", "Windows", b * Vector3(x, g + 1.6, h * 0.8), b.z, 1.0, 3.0, 0, 0.2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * (gw - 0.6), 0, sz * (gw - 0.6))
			lm.lathe("Pale", p + Vector3(0, g - 4.0, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.9, 1.6),
				Vector2(1.45, 3.4), Vector2(1.6, 4.0)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.lathe("Stone", p + Vector3(0, g, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.45, 7.0)]), 8,
				1.0, 1.0, PI / 8.0, false)
			for k in 4:
				var a := PI * 0.5 * float(k) + PI * 0.25
				var d := Vector3(cos(a), 0, sin(a))
				LandmarkChParts.lancet(lm, "Pale", "Windows", p + d * 1.42 + Vector3(0, g + 2.4, 0), d, 0.55, 2.6, 0, 0.12)
			lm.frustum("Pale", p + Vector3(0, g + 6.8, 0), 1.7, 1.7, 0.5, 8, PI / 8.0)
			lm.lathe("Roof", p + Vector3(0, g + 7.3, 0), PackedVector2Array([Vector2(1.75, 0), Vector2(1.2, 2.0),
				Vector2(0.5, 6.0), Vector2(0.05, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
			LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, g + 16.2, 0), 1.6, 0.22)
	# Hipped roof: steep faces, a gabled lucarne on each side.
	var rb := Vector3(0, g + 6.1, 0)
	lm.lathe("Roof", rb, PackedVector2Array([Vector2(h * 1.2, 0), Vector2(h * 0.95, 2.0), Vector2(3.4, 8.0),
		Vector2(1.2, 12.5), Vector2(0.3, 13.6)]), 4, 1.0, 1.0, PI * 0.25, false)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var lc := rb + b * Vector3(0, 2.2, 4.2)
		lm.box("Stone", lc + Vector3(0, 1.1, 0), Vector3(2.0, 2.2, 1.8), b)
		LandmarkChParts.wimperg(lm, "Pale", lc + b * Vector3(0, 2.2, 0.9), b.z, 2.2, 2.2, 0.2)
		lm.gable("Roof", lc + Vector3(0, 2.2, 0), 2.0, 1.8, 1.8, b, 0.1, "Stone")
		LandmarkChParts.lancet(lm, "Pale", "Windows", lc + b * Vector3(0, 0.3, 0.9), b.z, 0.8, 1.6, 0, 0.12)
	var tip := rb + Vector3(0, 13.6, 0)
	lm.lathe("Gilt", tip - Vector3(0, 0.3, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.55, 0.5),
		Vector2(0.6, 0.9), Vector2(0.35, 1.3), Vector2(0.1, 1.5)]), 10)
	LandmarkChParts.finial(lm, "Gilt", tip + Vector3(0, 1.1, 0), POWDER_TOP - tip.y - 1.1, 0.3)
