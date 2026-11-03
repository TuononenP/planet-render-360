class_name LandmarkSsRoyal
extends RefCounted

## Stockholm Palace (Kungliga slottet, Nicodemus Tessin the Younger,
## 1697-1754) in true metres, built in the palace's own frame: +X its
## nominal east (Logården), +Z its nominal south (Slottsbacken, the
## front), turned onto the map by the registry yaw_deg (-31.5: the real
## fronts face 58.5 and 148.5 degrees, after the OpenStreetMap outline,
## relation 34394). The Italian-Baroque main block, 115 x 120 m round
## the 78 x 89 m Inner Court, with 18 m ranges to 35 m (the official
## figure for the northern front, plus its 1.5 m balustrade): a stone
## socle, the rusticated ground floor and entresol, the bel étage under
## alternating triangular and segmental pediments, the upper storey and
## the frieze windows, the crowning cornice, the plain roof balustrade
## (its top, 36.5 m, is the model's) and the low copper roofs sloping in
## to the court. Risalits
## step forward at the centres and corners with giant pilasters through
## the two main storeys; the south front holds the triumphal arch of the
## South Portal between three colossal Corinthian columns a side with
## statues in niches, the west front its ten caryatids; four arched
## portals open into the court. The four lower wings off the corners
## (48 m long; the south-west one 11.5 m because of Storkyrkan), and on
## the north the Lejonbacken terrace, its two ramps and their bronze
## lions. Sources: OpenStreetMap relation 34394 (footprint, inner
## court), Wikipedia "Stockholm Palace" (115 x 120 m block, court, wing
## sizes, facade programme), kungligaslotten.se "Why is the palace so
## big?" (northern front approx. 35 m + 1.5 m balustrade, 212 m long).
## Storkyrkan, Katarina and Hedvig Eleonora churches live in
## LandmarkSsRoyal2.

const PAL_TOP_M := 36.5
const HX := 57.5
const HZ := 60.0
const COURT_X := 39.0
const COURT_Z0 := -46.5
const COURT_Z1 := 42.5
const TOP_M := 35.0
const WING_M := 26.0
const RIS_M := 0.5
const RUST := 0
const PED := 1
const CORN := 2
const PLAIN := 3

## Storeys of the main block [y0, y1, window w, window h, sill, kind].
const MAIN_LEVELS := [[0.0, 3.5, 1.2, 1.0, 1.4, RUST], [3.5, 10.0, 2.0, 3.4, 1.7, RUST],
	[10.0, 14.0, 1.8, 1.8, 1.1, RUST], [14.0, 22.4, 2.1, 4.4, 1.5, PED],
	[22.4, 29.5, 2.0, 3.6, 1.4, CORN], [29.5, 33.6, 1.4, 1.1, 1.4, PLAIN]]
## String courses [y, h, projection].
const MAIN_BANDS := [[3.5, 0.5, 0.5], [14.0, 0.7, 0.6], [22.4, 0.3, 0.35], [29.5, 0.5, 0.45]]
const WING_LEVELS := [[0.0, 3.5, 1.2, 1.0, 1.4, RUST], [3.5, 10.0, 2.0, 3.4, 1.7, RUST],
	[10.0, 14.0, 1.8, 1.8, 1.1, RUST], [14.0, 21.4, 2.0, 3.8, 1.6, CORN], [21.4, 24.6, 1.4, 1.2, 1.0, PLAIN]]
const WING_BANDS := [[3.5, 0.5, 0.5], [14.0, 0.7, 0.6], [21.4, 0.4, 0.4]]

static func palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#B49B7B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C9BA9B", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#22292D"))
	lm.use("Bronze", LandmarkMaterials.paint("#4B4436", 0.45, 0.7))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A332B", 3.0))
	# The four ranges round the Inner Court, to the cornice top.
	var ranges := [[-HX, HX, -HZ, COURT_Z0], [-HX, HX, COURT_Z1, HZ], [-HX, -COURT_X, COURT_Z0, COURT_Z1],
		[COURT_X, HX, COURT_Z0, COURT_Z1]]
	for rg in ranges:
		_mass(lm, "Render", float(rg[0]), float(rg[1]), float(rg[2]), float(rg[3]), TOP_M)
	# Wings [x0, x1, z0, z1]: NE and NW reach 14.5 m past the north front.
	var wings := [[HX, 106.0, -74.6, -44.8], [-105.5, -HX, -74.6, -44.8], [HX, 106.0, 43.6, 60.4],
		[-69.0, -HX, 36.0, HZ]]
	for w in wings:
		_mass(lm, "Render", float(w[0]), float(w[1]), float(w[2]), float(w[3]), WING_M)
	_main_fronts(lm)
	_wing_fronts(lm, wings)
	_court(lm)
	_roofs(lm, wings)
	_lejonbacken(lm)
	lm.commit(model)

static func _mass(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, h: float) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0), Basis(), 0.0)

## Box in a front's frame: x along `r`, y up, d out along `o` from `a`.
static func _fb(lm: LandmarkMesh, key: String, a: Vector3, r: Vector3, o: Vector3, x: float, y: float,
		d: float, size: Vector3) -> void:
	lm.box(key, a + r * x + Vector3.UP * y + o * d, size, Basis(r, Vector3.UP, o), 0.0)

## The four outer fronts of the main block, each with its central and
## corner risalits, and their set pieces.
static func _main_fronts(lm: LandmarkMesh) -> void:
	var south_ris := [[0, 2], [9, 13], [20, 22]]
	var side_ris := [[0, 2], [10, 14], [22, 24]]
	# [left end, right, out, length, bays, risalits, runs behind wings]
	var fronts := [[Vector3(-HX, 0, HZ), Vector3.RIGHT, Vector3.BACK, 2.0 * HX, 23, south_ris, []],
		[Vector3(HX, 0, -HZ), Vector3.LEFT, Vector3.FORWARD, 2.0 * HX, 23, south_ris, []],
		[Vector3(HX, 0, HZ), Vector3.FORWARD, Vector3.RIGHT, 2.0 * HZ, 25, side_ris, [[0.0, 16.4], [104.8, 120.0]]],
		[Vector3(-HX, 0, -HZ), Vector3.BACK, Vector3.LEFT, 2.0 * HZ, 25, side_ris, [[0.0, 15.2], [96.0, 120.0]]]]
	for f in fronts:
		var a: Vector3 = f[0]
		var r: Vector3 = f[1]
		var o: Vector3 = f[2]
		_front(lm, a, r, o, float(f[3]), int(f[4]), MAIN_LEVELS, MAIN_BANDS, f[5] as Array, TOP_M, true,
			f[6] as Array)
		var mid := float(f[3]) * 0.5
		_portal(lm, a, r, o, mid, 0.4 + RIS_M, 4.6, 7.4 if o != Vector3.FORWARD else 10.0)
	_triumphal_arch(lm)
	# West front: the ten caryatids of Gotland sandstone (about 4.5 m)
	# flanking the five central bays of the bel étage.
	var pitch := 2.0 * HZ / 25.0
	for i in range(10, 15):
		for s in [-1.0, 1.0]:
			var z := -HZ + pitch * (float(i) + 0.5) + float(s) * 1.75
			LandmarkKits.statue_figure(lm, "Stone", Vector3(-HX - 0.4 - RIS_M - 0.75, 14.7, z), 4.5)
			lm.box("Stone", Vector3(-HX - 0.4 - RIS_M - 0.7, 14.5, z), Vector3(1.4, 0.4, 1.4), Basis(), 0.0)

## A front from `a` (its left end on the wall line at ground, seen from
## outside) along `r` for `length` m facing `o`: the storeys of `levels`
## as real window openings in `bays` axes, the risalits `ris` ([first
## bay, last bay]) stepped RIS_M forward with giant pilasters through
## the main storeys (`giant`), rusticated piers, window surrounds
## (alternating pediments on the bel étage, cornice heads above), the
## string courses `bands`, the crowning cornice under `top` and the roof
## balustrade. Bay detail below the wings' height is left
## out along the runs `hidden` ([x0, x1]) that a wing covers.
static func _front(lm: LandmarkMesh, a: Vector3, r: Vector3, o: Vector3, length: float, bays: int,
		levels: Array, bands: Array, ris: Array, top: float, giant: bool, hidden: Array = []) -> void:
	var pitch := length / float(bays)
	var off := PackedFloat32Array()
	off.resize(bays)
	for rr in ris:
		for i in range(int(rr[0]), int(rr[1]) + 1):
			off[i] = RIS_M
	# Segments [x0, x1, offset] of equal step.
	var segs: Array = []
	var s0 := 0
	for i in range(1, bays + 1):
		if i == bays or off[i] != off[s0]:
			segs.append([pitch * s0, pitch * i, off[s0], i - s0])
			s0 = i
	for lv in levels:
		var y0: float = lv[0]
		var y1: float = lv[1]
		var win := Vector2(float(lv[2]), float(lv[3]))
		var sill: float = lv[4]
		var kind: int = lv[5]
		var wall := "Stone" if kind == RUST else "Render"
		LandmarkDetail.pierced_face(lm, wall, "Glass", a + Vector3.UP * y0, r, o, length, y1 - y0, bays, 1,
			win, sill, y1 - y0, 0.4)
		for sg in segs:
			if float(sg[2]) > 0.0:
				LandmarkDetail.pierced_face(lm, wall, "Glass", a + r * float(sg[0]) + Vector3.UP * y0 + o * 0.4,
					r, o, float(sg[1]) - float(sg[0]), y1 - y0, int(sg[3]), 1, win, sill, y1 - y0, RIS_M)
		var wy0 := y0 + sill
		var wy1 := wy0 + win.y
		for i in bays:
			var x := pitch * (float(i) + 0.5)
			var f := 0.4 + off[i]
			if y1 <= WING_M + 0.1 and _covered(hidden, x):
				continue
			match kind:
				PED, CORN:
					for s in [-1.0, 1.0]:
						_fb(lm, "Stone", a, r, o, x + float(s) * (win.x * 0.5 + 0.14), (wy0 + wy1) * 0.5, f + 0.06,
							Vector3(0.28, win.y + 0.2, 0.12))
					_fb(lm, "Stone", a, r, o, x, wy0 - 0.12, f + 0.12, Vector3(win.x + 0.7, 0.24, 0.24))
					_fb(lm, "Stone", a, r, o, x, wy1 + 0.2, f + 0.12, Vector3(win.x + 0.8, 0.3, 0.24))
					if kind == PED:
						_pediment(lm, a + r * x + Vector3.UP * (wy1 + 0.35) + o * (f + 0.12), r, o, win.x + 1.0,
							i % 2 == 0)
				RUST:
					_fb(lm, "Stone", a, r, o, x, wy1 - 0.15, f + 0.1, Vector3(0.5, 0.7, 0.2))
		if kind == RUST and y0 > 0.0:
			_rustication(lm, a, r, o, pitch, bays, off, segs, hidden, y0, y1, win, sill)
	for sg in segs:
		var x0: float = sg[0]
		var x1: float = sg[1]
		var f := 0.4 + float(sg[2])
		for b in bands:
			_fb(lm, "Stone", a, r, o, (x0 + x1) * 0.5, float(b[0]), f + float(b[2]) * 0.5 - 0.1,
				Vector3(x1 - x0 + float(b[2]), float(b[1]), float(b[2]) + 0.2))
		LandmarkDetail.cornice(lm, "Stone", a + r * x0 + Vector3.UP * (top - 1.4) + o * f,
			a + r * x1 + Vector3.UP * (top - 1.4) + o * f, o, 1.4, giant)
		if giant and float(sg[2]) > 0.0:
			for k in int(sg[3]) + 1:
				var px := clampf(x0 + pitch * float(k), x0 + 0.45, x1 - 0.45)
				_fb(lm, "Stone", a, r, o, px, 21.75, f + 0.15, Vector3(0.9, 15.5, 0.3))
				_fb(lm, "Stone", a, r, o, px, 14.35, f + 0.2, Vector3(1.1, 0.5, 0.4))
				_fb(lm, "Stone", a, r, o, px, 29.25, f + 0.22, Vector3(1.25, 0.5, 0.45))
	_balustrade(lm, a + Vector3.UP * top + o * 0.25, a + r * length + Vector3.UP * top + o * 0.25, 1.5, 10.0, false)

## Rusticated courses 0.72 m high with 0.28 m channels: a course clear
## of the windows runs the whole segment, one at window height is cut
## into piers between the openings.
static func _rustication(lm: LandmarkMesh, a: Vector3, r: Vector3, o: Vector3, pitch: float, bays: int,
		off: PackedFloat32Array, segs: Array, hidden: Array, y0: float, y1: float, win: Vector2,
		sill: float) -> void:
	var wy0 := y0 + sill
	var wy1 := wy0 + win.y
	for k in int(y1 - y0):
		var y := y0 + float(k) + 0.5
		if y + 0.36 < wy0 or y - 0.36 > wy1:
			for sg in segs:
				var sa: float = sg[0]
				var sb: float = sg[1]
				_fb(lm, "Stone", a, r, o, (sa + sb) * 0.5, y, 0.44 + float(sg[2]), Vector3(sb - sa - 0.06, 0.72, 0.08))
			continue
		for i in bays + 1:
			var xl := 0.0 if i == 0 else pitch * (float(i) - 0.5) + win.x * 0.5
			var xr := pitch * float(bays) if i == bays else pitch * (float(i) + 0.5) - win.x * 0.5
			if _covered(hidden, (xl + xr) * 0.5):
				continue
			var parts: Array = []
			if i > 0 and i < bays and off[i - 1] != off[i]:
				parts = [[xl, pitch * i, off[i - 1]], [pitch * i, xr, off[i]]]
			else:
				parts = [[xl, xr, off[mini(i, bays - 1)]]]
			for p in parts:
				var pa: float = p[0]
				var pb: float = p[1]
				if pb - pa >= 0.2:
					_fb(lm, "Stone", a, r, o, (pa + pb) * 0.5, y, 0.44 + float(p[2]), Vector3(pb - pa - 0.06, 0.72, 0.08))

## True when `x` lies on one of the runs [x0, x1] in `runs`.
static func _covered(runs: Array, x: float) -> bool:
	for run in runs:
		if x > float(run[0]) and x < float(run[1]):
			return true
	return false

## Window pediment over a head at `c` (centre of its base) `w` wide:
## triangular, or segmental when `tri_ped` is false.
static func _pediment(lm: LandmarkMesh, c: Vector3, r: Vector3, o: Vector3, w: float, tri_ped: bool) -> void:
	if tri_ped:
		var apex := c + Vector3.UP * w * 0.28
		for s in [-1.0, 1.0]:
			lm.beam("Stone", c + r * float(s) * w * 0.5, apex, 0.22, 0.24, o)
	else:
		var prev := c - r * w * 0.5
		for k in 4:
			var t := float(k + 1) / 4.0
			var ang := lerpf(PI * 0.82, PI * 0.18, t)
			var p := c + r * (cos(ang) * w * 0.5 / cos(PI * 0.18)) + Vector3.UP * (sin(ang) - sin(PI * 0.18)) * w * 0.6
			lm.beam("Stone", prev, p, 0.22, 0.24, o)
			prev = p

## An arched portal centred `x` along a front, its face `f` out: dark
## opening `w` wide springing at `h`, stone archivolt and keystone.
static func _portal(lm: LandmarkMesh, a: Vector3, r: Vector3, o: Vector3, x: float, f: float, w: float,
		h: float) -> void:
	_fb(lm, "Dark", a, r, o, x, h * 0.5, f + 0.06, Vector3(w, h, 0.08))
	var c := a + r * x + Vector3.UP * h + o * (f + 0.1)
	for i in 10:
		var t0 := PI * float(i) / 10.0
		var t1 := PI * float(i + 1) / 10.0
		lm.tri("Dark", c, c + (r * cos(t0) + Vector3.UP * sin(t0)) * w * 0.5,
			c + (r * cos(t1) + Vector3.UP * sin(t1)) * w * 0.5, o, o, o, Vector2.ZERO,
			Vector2(cos(t0), sin(t0)) * w * 0.5, Vector2(cos(t1), sin(t1)) * w * 0.5)
	LandmarkDetail.arch(lm, "Stone", a + r * x + Vector3.UP * h + o * f, o, w, 0.7, 0.4)
	for s in [-1.0, 1.0]:
		_fb(lm, "Stone", a, r, o, x + float(s) * (w * 0.5 + 0.35), h * 0.5, f + 0.2, Vector3(0.7, h, 0.4))

## South front centre (Slottsbacken): the triumphal arch, three colossal
## Corinthian columns a side on pedestals, the entablature breaking
## forward over them and statues in niches between the columns.
static func _triumphal_arch(lm: LandmarkMesh) -> void:
	var f := HZ + 0.4 + RIS_M
	var cz := f + 1.4
	for s in [-1.0, 1.0]:
		for k in 3:
			var x := float(s) * (3.6 + 2.7 * float(k))
			lm.box("Stone", Vector3(x, 1.75, cz), Vector3(2.9, 3.5, 2.9))
			lm.box("Stone", Vector3(x, 3.35, cz), Vector3(3.2, 0.3, 3.2), Basis(), 0.0)
			LandmarkDetail.column(lm, "Stone", Vector3(x, 3.5, cz), 1.1, 26.0, "corinthian", 0, 14)
		for k in 2:
			var x := float(s) * (4.95 + 2.7 * float(k))
			lm.box("Dark", Vector3(x, 17.2, f + 0.05), Vector3(1.4, 4.2, 0.1), Basis(), 0.0)
			LandmarkKits.statue_figure(lm, "Bronze", Vector3(x, 15.2, f + 0.6), 3.2)
			lm.box("Stone", Vector3(x, 15.0, f + 0.5), Vector3(1.2, 0.4, 1.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 30.55, f + 1.4), Vector3(23.6, 2.1, 2.8))
	lm.box("Stone", Vector3(0, 32.4, f + 1.45), Vector3(24.0, 1.6, 2.9))
	LandmarkDetail.cornice(lm, "Stone", Vector3(-12.0, 33.2, f + 2.9), Vector3(12.0, 33.2, f + 2.9), Vector3.BACK,
		1.6, true)
	lm.box("Stone", Vector3(0, 21.0, f + 0.12), Vector3(5.0, 0.3, 0.24), Basis(), 0.0)

## The wings: rusticated below, two storeys and an attic above, cornice
## and balustrade at WING_M; their long sides and free end get fronts,
## and the north wings' inner sides where they flank the Lejonbacken.
static func _wing_fronts(lm: LandmarkMesh, wings: Array) -> void:
	for w in wings:
		var x0: float = w[0]
		var x1: float = w[1]
		var z0: float = w[2]
		var z1: float = w[3]
		var east := x0 >= HX - 0.01
		var bays := maxi(int(round((x1 - x0) / 4.8)), 2)
		_front(lm, Vector3(x0, 0, z1), Vector3.RIGHT, Vector3.BACK, x1 - x0, bays, WING_LEVELS, WING_BANDS, [],
			WING_M, false)
		_front(lm, Vector3(x1, 0, z0), Vector3.LEFT, Vector3.FORWARD, x1 - x0, bays, WING_LEVELS, WING_BANDS, [],
			WING_M, false)
		var bays_e := maxi(int(round((z1 - z0) / 4.8)), 2)
		if east:
			_front(lm, Vector3(x1, 0, z1), Vector3.FORWARD, Vector3.RIGHT, z1 - z0, bays_e, WING_LEVELS,
				WING_BANDS, [], WING_M, false)
		else:
			_front(lm, Vector3(x0, 0, z0), Vector3.BACK, Vector3.LEFT, z1 - z0, bays_e, WING_LEVELS,
				WING_BANDS, [], WING_M, false)
		if z0 < -HZ:
			if east:
				_front(lm, Vector3(x0, 0, z0), Vector3.BACK, Vector3.LEFT, -HZ - z0, 3, WING_LEVELS, WING_BANDS,
					[], WING_M, false)
			else:
				_front(lm, Vector3(x1, 0, -HZ), Vector3.FORWARD, Vector3.RIGHT, -HZ - z0, 3, WING_LEVELS,
					WING_BANDS, [], WING_M, false)

## The Inner Court: plainer fronts of five window storeys, a band at
## the main floor, the cornice, and the four arched portals (valv).
static func _court(lm: LandmarkMesh) -> void:
	var fronts := [[Vector3(-COURT_X, 0, COURT_Z0), Vector3.RIGHT, Vector3.BACK, 2.0 * COURT_X],
		[Vector3(COURT_X, 0, COURT_Z1), Vector3.LEFT, Vector3.FORWARD, 2.0 * COURT_X],
		[Vector3(-COURT_X, 0, COURT_Z1), Vector3.FORWARD, Vector3.RIGHT, COURT_Z1 - COURT_Z0],
		[Vector3(COURT_X, 0, COURT_Z0), Vector3.BACK, Vector3.LEFT, COURT_Z1 - COURT_Z0]]
	for f in fronts:
		var a: Vector3 = f[0]
		var r: Vector3 = f[1]
		var o: Vector3 = f[2]
		var length: float = f[3]
		var bays := int(round(length / 4.8))
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", a, r, o, length, 10.0, bays, 1, Vector2(1.9, 3.2), 3.6,
			6.0, 0.4)
		LandmarkDetail.pierced_face(lm, "Render", "Glass", a + Vector3.UP * 10.0, r, o, length, TOP_M - 11.4, bays,
			4, Vector2(1.9, 3.2), 1.6, 5.6, 0.4)
		_fb(lm, "Stone", a, r, o, length * 0.5, 10.0, 0.5, Vector3(length, 0.5, 0.3))
		_fb(lm, "Stone", a, r, o, length * 0.5, 0.6, 0.5, Vector3(length, 1.2, 0.3))
		LandmarkDetail.cornice(lm, "Stone", a + Vector3.UP * (TOP_M - 1.4) + o * 0.4,
			a + r * length + Vector3.UP * (TOP_M - 1.4) + o * 0.4, o, 1.4, false)
		_portal(lm, a, r, o, length * 0.5, 0.4, 4.4, 6.0)

## Low copper roofs: each range slopes from just inside its balustrade
## (36.4 m) down to the court, closed at the ends, with standing seams;
## the wings slope back from their fronts the same way.
static func _roofs(lm: LandmarkMesh, wings: Array) -> void:
	var hi := TOP_M + 1.4
	_shed(lm, Vector3(-HX, 0, -HZ + 0.9), Vector3(HX, 0, -HZ + 0.9), Vector3.BACK, COURT_Z0 + HZ - 0.9, hi, TOP_M)
	_shed(lm, Vector3(HX, 0, HZ - 0.9), Vector3(-HX, 0, HZ - 0.9), Vector3.FORWARD, HZ - COURT_Z1 - 0.9, hi, TOP_M)
	_shed(lm, Vector3(-HX + 0.9, 0, COURT_Z1), Vector3(-HX + 0.9, 0, COURT_Z0), Vector3.RIGHT, HX - COURT_X - 0.9,
		hi, TOP_M)
	_shed(lm, Vector3(HX - 0.9, 0, COURT_Z0), Vector3(HX - 0.9, 0, COURT_Z1), Vector3.LEFT, HX - COURT_X - 0.9,
		hi, TOP_M)
	for w in wings:
		var x0: float = w[0]
		var x1: float = w[1]
		var z0: float = w[2]
		var z1: float = w[3]
		var zc := (z0 + z1) * 0.5
		var whi := WING_M + 2.2
		# A low gable along the wing, ridge on its axis.
		lm.gable("Copper", Vector3((x0 + x1) * 0.5, WING_M, zc), z1 - z0 - 1.6, x1 - x0 - 1.6, whi - WING_M,
			Basis(Vector3.UP, PI * 0.5), 0.0, "Copper")
		var run := x1 - x0 - 1.6
		var seams := int(run / 1.4)
		for k in seams + 1:
			var x := x0 + 0.8 + run * float(k) / float(seams)
			for s in [-1.0, 1.0]:
				lm.beam("Copper", Vector3(x, WING_M + 0.05, zc + float(s) * (z1 - z0 - 1.6) * 0.5),
					Vector3(x, whi + 0.05, zc), 0.08, 0.1)

## Monopitch copper roof from the line a-b (at height hi) falling
## `depth` m along `inw` to lo, with its fascia, closed ends and seams.
static func _shed(lm: LandmarkMesh, a: Vector3, b: Vector3, inw: Vector3, depth: float, hi: float,
		lo: float) -> void:
	var a0 := Vector3(a.x, hi, a.z)
	var b0 := Vector3(b.x, hi, b.z)
	var al := Vector3(a.x, lo, a.z)
	var bl := Vector3(b.x, lo, b.z)
	var a1 := al + inw * depth
	var b1 := bl + inw * depth
	var n := (Vector3.UP * depth + inw * (hi - lo)).normalized()
	lm.quad("Copper", a0, b0, b1, a1, n)
	lm.quad("Copper", al, bl, b0, a0, -inw)
	var dir := (b - a).normalized()
	lm.tri("Copper", a0, al, a1, -dir, -dir, -dir, Vector2.ZERO, Vector2(0, hi - lo), Vector2(depth, hi - lo))
	lm.tri("Copper", b0, bl, b1, dir, dir, dir, Vector2.ZERO, Vector2(0, hi - lo), Vector2(depth, hi - lo))
	var count := int(a.distance_to(b) / 1.3)
	for k in count + 1:
		var t := float(k) / float(count)
		lm.beam("Copper", a0.lerp(b0, t) + n * 0.05, a1.lerp(b1, t) + n * 0.05, 0.08, 0.1)

## Stone balustrade along a-b (a and b on its foot line, may slope):
## plinth, square balusters, handrail, piers every `pier_m` / 2 metres
## and (with `urns`) an urn every `pier_m`.
static func _balustrade(lm: LandmarkMesh, a: Vector3, b: Vector3, h: float, pier_m: float,
		urns: bool = true) -> void:
	var d := b - a
	var hz := Vector3(d.x, 0, d.z).normalized()
	var side := hz.cross(Vector3.UP).normalized()
	var up := Vector3.UP
	lm.beam("Stone", a + up * h * 0.08, b + up * h * 0.08, 0.5, h * 0.16, side)
	lm.beam("Stone", a + up * h * 0.93, b + up * h * 0.93, 0.56, h * 0.14, side)
	var length := d.length()
	var bas := Basis(hz, up, side)
	var count := int(length / 0.6)
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		lm.box("Stone", p + up * h * 0.5, Vector3(0.16, h * 0.72, 0.16), bas, 0.0)
	var piers := maxi(int(length / pier_m * 2.0), 1)
	var urn := PackedVector2Array([Vector2(0.22, 0), Vector2(0.14, 0.12), Vector2(0.32, 0.45), Vector2(0.36, 0.7),
		Vector2(0.18, 0.95), Vector2(0.26, 1.08), Vector2(0.0, 1.5)])
	for i in piers + 1:
		var p := a.lerp(b, float(i) / float(piers))
		lm.box("Stone", p + up * h * 0.5, Vector3(0.55, h, 0.62), bas, 0.0)
		if urns and i % 2 == 0:
			lm.lathe("Stone", p + up * h, urn, 8)

## Lejonbacken: the terrace across the north front between the wings,
## its rusticated retaining wall and balustrade, the two ramps rising
## from the ends to the landing before the North Portal, and the bronze
## lions on their pedestals at the ramps' feet.
static func _lejonbacken(lm: LandmarkMesh) -> void:
	var th := 5.0
	var tz0 := -80.0
	lm.box("Stone", Vector3(0, th * 0.5, (tz0 - HZ) * 0.5), Vector3(132.0, th, -HZ - tz0), Basis(), 0.0)
	for k in 5:
		lm.box("Stone", Vector3(0, 0.5 + float(k), tz0 - 0.04), Vector3(132.0, 0.62, 0.08), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var sx: float = s
		_balustrade(lm, Vector3(sx * 9.0, th, tz0 + 0.3), Vector3(sx * 66.0, th, tz0 + 0.3), 1.1, 6.0)
		# The ramp: a sloped deck from the ground at x = 46 to the landing.
		var lo := Vector3(sx * 46.0, 0, 0)
		var hi := Vector3(sx * 9.0, th, 0)
		var z0 := tz0 - 6.0
		lm.quad("Stone", lo + Vector3(0, 0, z0), hi + Vector3(0, 0, z0), hi + Vector3(0, 0, tz0),
			lo + Vector3(0, 0, tz0), Vector3(sx * th, 37.0, 0).normalized())
		lm.tri("Stone", lo + Vector3(0, 0, z0), hi + Vector3(0, 0, z0), Vector3(hi.x, 0, z0), Vector3.FORWARD,
			Vector3.FORWARD, Vector3.FORWARD, Vector2.ZERO, Vector2(37.0, -th), Vector2(37.0, 0))
		_balustrade(lm, lo + Vector3(0, 0, z0 + 0.3), hi + Vector3(0, 0, z0 + 0.3), 1.1, 6.0)
		_lion(lm, Vector3(sx * 48.5, 0, z0 + 1.5), Vector3.FORWARD)
	# The landing in front of the North Portal.
	lm.box("Stone", Vector3(0, th * 0.5, tz0 - 3.0), Vector3(18.0, th, 6.0), Basis(), 0.0)
	_balustrade(lm, Vector3(-9.0, th, tz0 - 5.7), Vector3(9.0, th, tz0 - 5.7), 1.1, 6.0)

## A bronze lion on a stone pedestal at `base`, facing `face`: body,
## mane, head and muzzle, four legs, a forepaw on a ball and the tail.
static func _lion(lm: LandmarkMesh, base: Vector3, face: Vector3) -> void:
	var side := Vector3.UP.cross(face).normalized()
	var bas := Basis(side, Vector3.UP, face)
	lm.box("Stone", base + Vector3.UP * 1.1, Vector3(2.0, 2.2, 3.6), bas)
	lm.box("Stone", base + Vector3.UP * 2.3, Vector3(2.3, 0.25, 3.9), bas)
	var b := base + Vector3.UP * 2.42
	lm.beam("Bronze", b - face * 1.1 + Vector3.UP * 1.05, b + face * 0.6 + Vector3.UP * 1.2, 0.85, 0.95)
	lm.lathe("Bronze", b + face * 0.8 + Vector3.UP * 0.75, PackedVector2Array([Vector2(0.0, 0), Vector2(0.5, 0.2),
		Vector2(0.68, 0.6), Vector2(0.62, 1.05), Vector2(0.36, 1.4), Vector2(0.0, 1.5)]), 10)
	lm.box("Bronze", b + face * 1.15 + Vector3.UP * 1.85, Vector3(0.62, 0.62, 0.62), bas)
	lm.box("Bronze", b + face * 1.5 + Vector3.UP * 1.72, Vector3(0.38, 0.32, 0.42), bas)
	for sx in [-1.0, 1.0]:
		for fz in [-1.0, 0.75]:
			var top := b + side * float(sx) * 0.3 + face * float(fz) + Vector3.UP * 1.0
			var foot := b + side * float(sx) * 0.3 + face * (float(fz) + 0.05)
			if sx > 0.0 and fz > 0.0:
				foot = b + side * 0.3 + face * 1.3 + Vector3.UP * 0.55
			lm.beam("Bronze", top, foot, 0.26, 0.3)
	lm.lathe("Bronze", b + side * 0.3 + face * 1.35, LandmarkFhUtil.ball(0.3), 10)
	lm.beam("Bronze", b - face * 1.15 + Vector3.UP * 1.1, b - face * 1.6 + Vector3.UP * 0.4, 0.12, 0.12)
	lm.beam("Bronze", b - face * 1.6 + Vector3.UP * 0.4, b - face * 1.5 + Vector3.UP * 0.05, 0.12, 0.12)

# --- Churches (built in LandmarkSsRoyal2) -----------------------------

static func storkyrkan(model: Node3D) -> void:
	LandmarkSsRoyal2.storkyrkan(model)

static func katarina(model: Node3D) -> void:
	LandmarkSsRoyal2.katarina(model)

static func hedvig_eleonora(model: Node3D) -> void:
	LandmarkSsRoyal2.hedvig_eleonora(model)
