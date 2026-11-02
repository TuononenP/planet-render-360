class_name LandmarkIndUtil
extends RefCounted

## Shared parts of the india_historic landmark batch, in true metres on
## LandmarkMesh: flat arched facade panels, striped marble domes, wall
## runs with merlons, stairs and Mughal gate blocks. Every part takes the
## material KEYS to draw with (registered by the caller with lm.use).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")
## (radius factor, height factor) of the Mughal onion dome, as U.onion.
const ONION: Array = [[0.74, 0.0], [0.97, 0.1], [1.0, 0.26], [0.9, 0.43], [0.62, 0.6],
	[0.34, 0.76], [0.13, 0.9]]

## Horizontal (x, z) of a point.
static func xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## Flat arched panel facing local +Z (basis turns it), floor centre at
## `base`: w wide, h tall, pointed (Mughal) or round-headed.
static func arch_panel(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, w: float,
		h: float, pointed: bool = true, steps: int = 6) -> void:
	var r := w * 0.5
	var spring := h - r * (1.4 if pointed else 1.0)
	var right := PackedVector2Array()
	for i in steps + 1:
		var s := float(i) / float(steps)
		if pointed:
			right.append(Vector2(r * (1.0 - pow(s, 1.7)), spring + (h - spring) * s))
		else:
			right.append(Vector2(r * cos(s * PI * 0.5), spring + r * sin(s * PI * 0.5)))
	var pts := PackedVector2Array([Vector2(-r, 0.0), Vector2(r, 0.0)])
	pts.append_array(right)
	for i in range(steps - 1, -1, -1):
		pts.append(Vector2(-right[i].x, right[i].y))
	var idx := Geometry2D.triangulate_polygon(pts)
	var n := basis * Vector3(0, 0, 1)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		lm.tri(key, base + basis * Vector3(a.x, a.y, 0), base + basis * Vector3(b.x, b.y, 0),
			base + basis * Vector3(c.x, c.y, 0), n, n, n, Vector2(a.x, -a.y), Vector2(b.x, -b.y),
			Vector2(c.x, -c.y))

## Row of `count` arch panels at `pitch` centred on `base` along local X.
static func arcade(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, count: int,
		pitch: float, w: float, h: float, pointed: bool = true) -> void:
	for k in count:
		arch_panel(lm, key, base + basis * Vector3((float(k) - float(count - 1) * 0.5) * pitch, 0, 0),
			basis, w, h, pointed)

## Onion dome with `stripes` black marble stripes (needs seg = 2 x stripes).
static func striped_onion(lm: LandmarkMesh, white: String, black: String, base: Vector3,
		r: float, h: float, stripes: int = 16) -> void:
	U.onion(lm, white, base, r, h, stripes * 2)
	var da := TAU / float(stripes * 2)
	for s in stripes:
		var a0 := TAU * float(s) / float(stripes)
		var rows: Array = []
		for e in ONION:
			var rr := r * float(e[0]) * 1.012
			var y := h * float(e[1])
			rows.append(PackedVector3Array([base + Vector3(cos(a0) * rr, y, sin(a0) * rr),
				base + Vector3(cos(a0 + da) * rr, y, sin(a0 + da) * rr)]))
		lm.grid(black, rows, base + Vector3(0, h * 0.3, 0), true)

## Thick straight wall between two XZ points from y0 to y1.
static func wall_run(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, y0: float, y1: float,
		thick: float) -> void:
	var d := b - a
	var c := (a + b) * 0.5
	lm.box(key, Vector3(c.x, (y0 + y1) * 0.5, c.y), Vector3(d.length() + thick * 0.6, y1 - y0, thick),
		Basis(Vector3.UP, atan2(-d.y, d.x)))

## Row of kangura merlons along a wall top at height y, one per `pitch`
## metres: a block with a pointed cap and a loophole slot below it.
static func merlons(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, y: float,
		pitch: float, w: float, h: float, d: float) -> void:
	var n := maxi(int(a.distance_to(b) / pitch), 1)
	var bas := Basis(Vector3.UP, atan2(-(b - a).y, (b - a).x))
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box(key, Vector3(p.x, y + h * 0.4, p.y), Vector3(w, h * 0.8, d), bas, 0.0)
		lm.lathe(key, Vector3(p.x, y + h * 0.8, p.y), PackedVector2Array([Vector2(w * 0.62, 0),
			Vector2(w * 0.4, h * 0.25), Vector2(0.0, h * 0.42)]), 4, 1.0, d / w, atan2((b - a).y, (b - a).x)
			+ PI * 0.25, false)

## Flight of `n` steps rising toward local -Z from `base` (ground level at
## the foot), w wide: the top step meets a platform n x rise high.
static func stairs(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, w: float,
		n: int, rise: float, run: float) -> void:
	for k in n:
		var hh := float(n - k) * rise
		lm.box(key, base + basis * Vector3(0, hh * 0.5, (float(k) + 0.5) * run),
			Vector3(w, hh, run), basis)

## Pillared kiosk for wall tops and roofs: eight columns, a chhajja and a
## lotus onion dome (height pillar_h + 0.5 + dome_h).
static func kiosk(lm: LandmarkMesh, key: String, base: Vector3, w: float, pillar_h: float,
		dome_h: float) -> void:
	ID.chhatri_fit(lm, key, key, base, w, pillar_h + 0.5 + dome_h)

## Round bastion: a battered 16-sided tower of height h with string
## courses, a merloned parapet and a pillared kiosk on top (total
## h + 2.7 + dome_h).
static func bastion(lm: LandmarkMesh, wall: String, cap: String, p: Vector3, r: float, h: float,
		dome_h: float = 2.4) -> void:
	lm.frustum(wall, p, r * 1.12, r, h, 16)
	for t in [0.45, 0.8]:
		var rr := lerpf(r * 1.12, r, t)
		lm.frustum(wall, p + Vector3(0, h * t, 0), rr * 1.03, rr * 1.03, 0.4, 16)
	lm.frustum(cap, p + Vector3(0, h, 0), r * 1.25, r * 1.25, 0.5, 16)
	for i in 12:
		var a := TAU * float(i) / 12.0
		lm.box(wall, p + Vector3(cos(a) * r * 1.15, h + 0.95, sin(a) * r * 1.15), Vector3(0.9, 0.9, 0.45),
			Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	ID.chhatri_fit(lm, cap, cap, p + Vector3(0, h + 0.5, 0), r * 1.1, 2.2 + dome_h)

## Mughal gate on `base` facing local +Z: arched block w x h x d with a
## passage open_w x open_h set in a tall pointed iwan, two tiers of
## arched niches either side (front and back), a chhajja and merloned
## parapet, a 16-sided turret at each end banded with string courses and
## crowned by a pillared kiosk (turret_h + 5 m), and `kiosks` small domed
## kiosks along the parapet. `recess` fills the niches (wall if empty).
static func gate(lm: LandmarkMesh, wall: String, trim: String, base: Vector3, basis: Basis,
		w: float, h: float, d: float, open_w: float, open_h: float, turret_r: float,
		turret_h: float, kiosks: int = 3, recess: String = "") -> void:
	var rk := wall if recess == "" else recess
	U.arch_wall(lm, wall, base, basis, w, h, d, open_w, open_h)
	lm.box(trim, base + basis * Vector3(0, h + 0.3, 0), Vector3(w + 0.8, 0.6, d + 0.8), basis)
	var iw := minf(open_w * 1.6, w * 0.45)
	var ih := minf(open_h * 1.3, h - 1.2)
	var side_w := (w - iw) * 0.5 - turret_r * 0.6
	for face in [0.0, PI]:
		var fb := basis * Basis(Vector3.UP, face)
		var fo := base + fb * Vector3(0, 0, d * 0.5)
		# The iwan: a deep pointed frame round the passage.
		ID.arcade_wall(lm, trim, "", fo, fb, iw + 1.6, ih + 1.0, 0.7, 1, iw, ih, "pointed")
		if side_w > 1.5:
			for sx in [-1.0, 1.0]:
				var cx: float = sx * (iw * 0.5 + 0.8 + side_w * 0.5)
				var bay := maxi(int(side_w / 4.0), 1)
				ID.arcade_wall(lm, wall, rk, fo + fb * Vector3(cx, 0.6, 0), fb, side_w, h * 0.46, 0.35, bay,
					side_w / float(bay) * 0.62, h * 0.36, "pointed")
				ID.arcade_wall(lm, wall, rk, fo + fb * Vector3(cx, 0.6 + h * 0.5, 0), fb, side_w, h * 0.42,
					0.35, bay, side_w / float(bay) * 0.62, h * 0.32, "pointed")
		ID.chhajja(lm, trim, fo + fb * Vector3(-w * 0.5, h - 0.6, 0.7), fo + fb * Vector3(w * 0.5, h - 0.6, 0.7),
			fb * Vector3(0, 0, 1), 1.2, 0.5, 2.0)
		merlons(lm, wall, xz(fo + fb * Vector3(-w * 0.5 + 1.0, 0, -0.4)), xz(fo + fb * Vector3(w * 0.5 - 1.0, 0, -0.4)),
			base.y + h + 0.6, 2.4, 1.2, 1.2, 0.6)
	for sx in [-1.0, 1.0]:
		var p: Vector3 = base + basis * Vector3(sx * w * 0.5, 0, 0)
		lm.frustum(wall, p, turret_r * 1.1, turret_r, turret_h, 16)
		for t in [0.3, 0.55, 0.8]:
			var rr := lerpf(turret_r * 1.1, turret_r, t)
			lm.frustum(trim, p + Vector3(0, turret_h * t, 0), rr * 1.05, rr * 1.05, 0.35, 16)
		lm.frustum(trim, p + Vector3(0, turret_h - 0.5, 0), turret_r * 1.3, turret_r * 1.3, 0.5, 16)
		ID.chhatri_fit(lm, trim, trim, p + Vector3(0, turret_h, 0), turret_r * 1.25, 5.0)
	for k in kiosks:
		var x := (float(k) - float(kiosks - 1) * 0.5) * w * 0.7 / float(maxi(kiosks - 1, 1))
		ID.chhatri_fit(lm, trim, trim, base + basis * Vector3(x, h + 0.6, 0), 2.4, 3.9)

## Dravida gopura on `base` facing local +Z: a two-storey granite gate
## block (w x d, stone_h tall, passage open_w x open_h) on a moulded
## plinth with pilasters, `n` receding stucco tiers of tier_h cycling
## through the `tiers` keys, each with pilasters, a curved kapota eave and
## a parapet of kuta and shala pavilions, a barrel (shala) roof with its
## kirtimukha ends and a row of gilded kalasas along the ridge (odd count,
## more on the taller gates). Returns the height of the top.
static func gopura(lm: LandmarkMesh, stone: String, tiers: Array[String], gold: String, base: Vector3,
		basis: Basis, w: float, d: float, stone_h: float, n: int, tier_h: float, open_w: float,
		open_h: float) -> float:
	U.arch_wall(lm, stone, base, basis, w, stone_h, d, open_w, open_h)
	lm.box(stone, base + basis * Vector3(0, stone_h + 0.25, 0), Vector3(w + 1.0, 0.5, d + 1.0), basis)
	# Plinth mouldings and the stone storeys' pilasters and mid band.
	lm.box(stone, base + basis * Vector3(0, 0.6, 0), Vector3(w + 0.8, 1.2, d + 0.8), basis)
	lm.box(stone, base + basis * Vector3(0, stone_h * 0.5, 0), Vector3(w + 0.5, 0.45, d + 0.5), basis)
	for face in 4:
		var fb := basis * Basis(Vector3.UP, PI * 0.5 * float(face))
		var run := w if face % 2 == 0 else d
		var off := (d if face % 2 == 0 else w) * 0.5
		for half in [[0.0, stone_h * 0.5], [stone_h * 0.5 + 0.25, stone_h * 0.5 - 0.25]]:
			var y0: float = half[0]
			var hh: float = half[1]
			# Runs of pilasters: either side of the passage on the fronts.
			var runs: Array = [[-run * 0.5, -open_w * 0.5 - 0.8], [open_w * 0.5 + 0.8, run * 0.5]] \
				if face % 2 == 0 else [[-run * 0.5, run * 0.5]]
			for e in runs:
				var x0: float = e[0]
				var x1: float = e[1]
				ID.pilasters(lm, stone, base + fb * Vector3(x0, y0 + 1.2, off), base + fb * Vector3(x1, y0 + 1.2, off),
					fb * Vector3(0, 0, 1), maxi(int((x1 - x0) / 3.6), 1), hh - 1.4, 0.7, 0.3)
	var y := stone_h + 0.5
	var f := 0.9
	for i in n:
		f = lerpf(0.9, 0.42, pow(float(i) / float(maxi(n - 1, 1)), 0.85))
		var key := tiers[i % tiers.size()]
		var tw := w * f
		var td := d * f
		var wall_h := tier_h * 0.5
		lm.box(key, base + basis * Vector3(0, y + wall_h * 0.5, 0), Vector3(tw, wall_h, td), basis)
		# Pilasters on the long faces with a dark niche in each middle bay.
		for sz in [-1.0, 1.0]:
			var fb := basis * Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			ID.pilasters(lm, key, base + fb * Vector3(-tw * 0.5, y, td * 0.5), base + fb * Vector3(tw * 0.5, y, td * 0.5),
				fb * Vector3(0, 0, 1), maxi(int(tw / 3.4), 3), wall_h, 0.4, 0.25)
			lm.box("Dark", base + fb * Vector3(0, y + wall_h * 0.45, td * 0.5 + 0.03), Vector3(tw * 0.14,
				wall_h * 0.7, 0.1), fb, 0.0)
		# Kapota: a curved eave band all round.
		var ey := y + wall_h
		lm.box(stone, base + basis * Vector3(0, ey + 0.15, 0), Vector3(tw + 0.9, 0.3, td + 0.9), basis, 0.0)
		lm.box(key, base + basis * Vector3(0, ey + 0.45, 0), Vector3(tw + 0.6, 0.3, td + 0.6), basis, 0.0)
		# Parapet of pavilions on the tier's terrace, set in from the eave.
		var hb := ey + 0.6
		ID.hara(lm, key, key, base + basis * Vector3(0, hb, 0), tw - 0.2, td - 0.2,
			tier_h - wall_h - 0.8, 3)
		lm.box(key, base + basis * Vector3(0, hb + (tier_h - wall_h - 0.8) * 0.3, 0),
			Vector3(tw * 0.78, (tier_h - wall_h - 0.8) * 0.6, td * 0.7), basis, 0.0)
		lm.box(stone, base + basis * Vector3(0, y + tier_h - 0.2, 0), Vector3(tw * 0.86, 0.4, td * 0.78),
			basis, 0.0)
		y += tier_h
	var rise := d * f * 0.45
	var rk := tiers[(n + 1) % tiers.size()]
	lm.gable(rk, base + basis * Vector3(0, y, 0), d * f, w * f, rise,
		basis * Basis(Vector3.UP, PI * 0.5), 0.4, rk)
	# Kirtimukha: the horseshoe gable ends with a dark window.
	for sx in [-1.0, 1.0]:
		var ge := base + basis * Vector3(sx * (w * f * 0.5 + 0.35), y, 0)
		var gb := basis * Basis(Vector3.UP, sx * PI * 0.5)
		ID.arcade_wall(lm, rk, "Dark", ge, gb, d * f * 0.95, rise * 1.05, 0.35, 1, d * f * 0.45, rise * 0.85,
			"round")
	var kal := 5 + 2 * clampi((n - 3) / 2, 0, 4)
	for k in kal:
		var x := (float(k) - float(kal - 1) * 0.5) * w * f * 0.84 / float(kal - 1)
		U.finial(lm, gold, base + basis * Vector3(x, y + rise - 0.1, 0), 2.4, 0.35)
	return y + rise + 2.3
