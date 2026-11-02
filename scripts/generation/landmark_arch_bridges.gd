class_name LandmarkArchBridges
extends RefCounted

## Arch bridges in true metres, built along +X.

## Sydney Harbour Bridge (1932; y = 0 at the harbour, `base: water`):
## the 503 m two-hinged steel arch of 28 panels, its two trussed ribs
## 30 m apart rising to 134 m (18 m deep at the crown, 57 m at the
## ends), with lateral and sway bracing between them, hangers down to
## the 48.8 m wide deck at 49 m where it hangs and posts up to it where
## it rides above the arch; the four granite-faced pylons (89 m) with
## their stepped Art Deco crowns and lookout windows at the arch ends;
## and the five approach spans each side, steel deck trusses on
## granite piers, 1149 m end to end.
const SH_SPAN := 503.0
const SH_TOP_M := 134.0
const SH_DECK_M := 49.0
const SH_LENGTH := 1149.0
const SH_HALF_W := 24.4
const SH_RIB_Z := 15.0
const SH_HINGE_M := 5.0
const SH_PANELS := 28
const SH_PYLON_M := 89.0

static func harbour(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#7D8287", 0.55, 0.45))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B9AE9B", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B3A8", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	var half := SH_SPAN * 0.5
	_sh_arch(lm, half)
	_sh_deck(lm, half)
	for s in [-1.0, 1.0]:
		_sh_pylons(lm, float(s), half)
		_sh_approach(lm, float(s), half)
	lm.commit(model)

## The two trussed ribs and the bracing between them, the hangers and
## posts carrying the deck.
static func _sh_arch(lm: LandmarkMesh, half: float) -> void:
	var n := SH_PANELS
	for rz in [-SH_RIB_Z, SH_RIB_Z]:
		var z: float = rz
		var bot := PackedVector3Array()
		var top := PackedVector3Array()
		for k in n + 1:
			var x := -half + SH_SPAN * k / n
			bot.append(Vector3(x, _sh_bottom(x), z))
			top.append(Vector3(x, _sh_top(x), z))
		for k in n + 1:
			lm.beam("Steel", bot[k], top[k], 1.4, 1.4, Vector3(0, 0, 1))
			if k == n:
				break
			lm.beam("Steel", bot[k], bot[k + 1], 2.6, 3.4, Vector3(0, 0, 1))
			lm.beam("Steel", top[k], top[k + 1], 2.4, 2.0, Vector3(0, 0, 1))
			# Diagonals slope down towards the crown; deep end panels are
			# split by a mid-depth strut and a second diagonal.
			var a := bot[k] if k < n / 2 else bot[k + 1]
			var b := top[k + 1] if k < n / 2 else top[k]
			lm.beam("Steel", a, b, 1.1, 1.1, Vector3(0, 0, 1))
			var depth := top[k].y - bot[k].y
			if depth > 28.0:
				var m0 := bot[k].lerp(top[k], 0.5)
				var m1 := bot[k + 1].lerp(top[k + 1], 0.5)
				lm.beam("Steel", m0, m1, 0.9, 0.9, Vector3(0, 0, 1))
				lm.beam("Steel", m0 if k < n / 2 else m1, (top[k + 1] if k < n / 2 else top[k]).lerp(
					m1 if k < n / 2 else m0, 0.5), 0.7, 0.7, Vector3(0, 0, 1))
	# Bracing between the ribs: transverse struts at every node on both
	# chords, X-bracing in the top and bottom chord planes, sway frames.
	for k in n + 1:
		var x := -half + SH_SPAN * k / n
		var yt := _sh_top(x)
		var yb := _sh_bottom(x)
		lm.beam("Steel", Vector3(x, yt, -SH_RIB_Z), Vector3(x, yt, SH_RIB_Z), 1.2, 1.2)
		lm.beam("Steel", Vector3(x, yb, -SH_RIB_Z), Vector3(x, yb, SH_RIB_Z), 1.2, 1.2)
		if k % 2 == 0 and yt - yb > 2.0:
			lm.beam("Steel", Vector3(x, yt, -SH_RIB_Z), Vector3(x, yb, SH_RIB_Z), 0.7, 0.7)
			lm.beam("Steel", Vector3(x, yt, SH_RIB_Z), Vector3(x, yb, -SH_RIB_Z), 0.7, 0.7)
		if k < n:
			var x1 := -half + SH_SPAN * (k + 1) / n
			for which in 2:
				var y0 := _sh_top(x) if which == 0 else _sh_bottom(x)
				var y1 := _sh_top(x1) if which == 0 else _sh_bottom(x1)
				lm.beam("Steel", Vector3(x, y0, -SH_RIB_Z), Vector3(x1, y1, SH_RIB_Z), 0.6, 0.6)
				lm.beam("Steel", Vector3(x, y0, SH_RIB_Z), Vector3(x1, y1, -SH_RIB_Z), 0.6, 0.6)
	# Hangers (deck below the arch) and posts (deck above the arch).
	for k in range(1, n):
		var x := -half + SH_SPAN * k / n
		var yb := _sh_bottom(x)
		for z in [-SH_RIB_Z, SH_RIB_Z]:
			if yb > SH_DECK_M + 1.0:
				for o in [-0.5, 0.5]:
					lm.beam("Steel", Vector3(x + float(o), SH_DECK_M - 1.0, z), Vector3(x + float(o), yb, z), 0.5, 1.2,
						Vector3(1, 0, 0))
			else:
				lm.beam("Steel", Vector3(x, yb, z), Vector3(x, SH_DECK_M - 2.6, z), 1.6, 1.6)

## Deck over the whole length: roadway, the rail and road separation,
## footway and cycleway, cross girders at every arch panel point and
## the longitudinal stringers, with the handrails.
static func _sh_deck(lm: LandmarkMesh, half: float) -> void:
	lm.box("Deck", Vector3(0, SH_DECK_M + 0.2, 0), Vector3(SH_LENGTH, 0.4, SH_HALF_W * 2.0))
	for gz in [-SH_HALF_W + 0.6, -12.0, -SH_RIB_Z, SH_RIB_Z, 12.0, SH_HALF_W - 0.6]:
		lm.box("Steel", Vector3(0, SH_DECK_M - 1.4, float(gz)), Vector3(SH_LENGTH, 2.4, 0.8))
	# Kerbs dividing the rail tracks (west) and the footway (east).
	for kz in [-11.0, 21.0]:
		lm.box("Concrete", Vector3(0, SH_DECK_M + 0.6, float(kz)), Vector3(SH_LENGTH, 0.8, 0.6))
	for rz in [-17.5, -13.0, -22.0, -19.0]:
		lm.box("Steel", Vector3(0, SH_DECK_M + 0.5, float(rz)), Vector3(SH_LENGTH, 0.2, 0.2), Basis(), 0.0)
	var pitch := SH_SPAN / SH_PANELS
	var x := -SH_LENGTH * 0.5
	while x <= SH_LENGTH * 0.5:
		lm.beam("Steel", Vector3(x, SH_DECK_M - 1.6, -SH_HALF_W), Vector3(x, SH_DECK_M - 1.6, SH_HALF_W), 0.8, 2.6)
		x += pitch * 0.5
	for side in [-1.0, 1.0]:
		var z: float = side * SH_HALF_W
		lm.box("Steel", Vector3(0, SH_DECK_M + 1.4, z), Vector3(SH_LENGTH, 0.12, 0.12), Basis(), 0.0)
		var px := -SH_LENGTH * 0.5
		while px <= SH_LENGTH * 0.5:
			lm.box("Steel", Vector3(px, SH_DECK_M + 0.8, z), Vector3(0.12, 1.2, 0.12), Basis(), 0.0)
			px += 3.0

## One end's pair of pylons on their abutment towers, the arch hinges
## and the granite abutment under the deck between them.
static func _sh_pylons(lm: LandmarkMesh, s: float, half: float) -> void:
	var px := s * (half + 12.0)
	lm.box("Granite", Vector3(px, (SH_DECK_M - 3.0) * 0.5, 0), Vector3(24.0, SH_DECK_M - 3.0, SH_HALF_W * 2.0))
	for k in 3:
		lm.box("Granite", Vector3(px - s * 12.05, 14.0 + 12.0 * k, 0), Vector3(0.1, 4.0, 30.0), Basis(), 0.0)
	lm.box("Granite", Vector3(s * half, (SH_HINGE_M + 1.0) * 0.5, 0), Vector3(12.0, SH_HINGE_M + 1.0, SH_RIB_Z * 2.0 + 6.0))
	for z in [-SH_RIB_Z, SH_RIB_Z]:
		lm.lathe("Steel", Vector3(s * half, SH_HINGE_M + 1.0, float(z)), PackedVector2Array([Vector2(3.0, 0),
			Vector2(1.6, 2.0), Vector2(1.4, 3.0)]), 12)
	for side in [-1.0, 1.0]:
		var pz: float = side * (SH_HALF_W + 7.0)
		var c := Vector3(px, 0, pz)
		# Battered base, tapering shaft, string courses.
		lm.box("Granite", c + Vector3(0, 4.0, 0), Vector3(26.0, 8.0, 17.0))
		lm.lathe("Granite", c + Vector3(0, 8.0, 0), PackedVector2Array([Vector2(sqrt(2.0), 0),
			Vector2(sqrt(2.0) * 0.9, 70.0)]), 4, 11.0, 7.0, PI * 0.25, false)
		for y in [SH_DECK_M + 2.0, 60.0, 72.0]:
			var f := 1.0 - 0.1 * (float(y) - 8.0) / 70.0
			lm.box("Granite", c + Vector3(0, float(y), 0), Vector3(22.0 * f + 1.0, 1.0, 14.0 * f + 1.0))
		# Recessed vertical panels and the lookout windows near the top.
		for f in [-1.0, 1.0]:
			for k in 3:
				lm.box("Windows", c + Vector3(-6.0 + 6.0 * k, 75.0, float(f) * 6.35), Vector3(2.0, 3.6, 0.2), Basis(), 0.0)
			for k in 2:
				lm.box("Granite", c + Vector3(-3.0 + 6.0 * k, 40.0, float(f) * 6.9), Vector3(1.4, 56.0, 0.6))
			lm.box("Windows", c + Vector3(float(f) * 10.05, 75.0, 0), Vector3(0.2, 3.6, 3.0), Basis(), 0.0)
		# Stepped Art Deco crown.
		var steps := [[78.0, 20.6, 13.2, 3.0], [81.0, 18.6, 11.6, 3.0], [84.0, 16.0, 9.6, 2.5],
			[86.5, 12.0, 7.0, SH_PYLON_M - 86.5]]
		for st in steps:
			var y0 := float(st[0])
			lm.box("Granite", c + Vector3(0, y0 + float(st[3]) * 0.5, 0), Vector3(float(st[1]), float(st[3]), float(st[2])))

## Five approach spans: granite-faced piers carrying steel deck trusses.
static func _sh_approach(lm: LandmarkMesh, s: float, half: float) -> void:
	var x0 := half + 24.0
	var x1 := SH_LENGTH * 0.5
	var spans := 5
	var sl := (x1 - x0) / spans
	var td := 7.0
	for k in spans + 1:
		var x := s * (x0 + sl * k)
		if k > 0:
			lm.box("Granite", Vector3(x, (SH_DECK_M - td) * 0.5, 0), Vector3(7.0, SH_DECK_M - td, SH_HALF_W * 2.0 - 4.0))
			lm.box("Granite", Vector3(x, SH_DECK_M - td - 0.6, 0), Vector3(8.0, 1.2, SH_HALF_W * 2.0 - 3.0))
			lm.box("Granite", Vector3(x, 1.5, 0), Vector3(9.0, 3.0, SH_HALF_W * 2.0 - 2.0))
		if k == spans:
			break
		for tz in [-21.0, -7.0, 7.0, 21.0]:
			var bot := PackedVector3Array()
			var top := PackedVector3Array()
			var panels := 8
			for j in panels + 1:
				var xx := s * (x0 + sl * k + sl * j / panels)
				bot.append(Vector3(xx, SH_DECK_M - td, float(tz)))
				top.append(Vector3(xx, SH_DECK_M - 2.6, float(tz)))
			LandmarkCoreBBridgeKit.truss(lm, "Steel", bot, top, 0.9, 0.5, Vector3(0, 0, 1))

## Bottom chord of the arch: hinge at ±half rising to the crown, 17 m
## under the top chord's centre.
static func _sh_bottom(x: float) -> float:
	var u := x / (SH_SPAN * 0.5)
	return SH_HINGE_M + (SH_TOP_M - 18.0 - SH_HINGE_M) * (1.0 - u * u)

## Top chord: 17 m over the bottom at the crown (its top at 134 m), 57 m
## at the ends where it meets the pylons.
static func _sh_top(x: float) -> float:
	var u := x / (SH_SPAN * 0.5)
	return _sh_bottom(x) + 17.0 + 40.0 * u * u

## Bixby Creek Bridge (1932; y = 0 at the creek bed, `base: ground`):
## the reinforced-concrete open-spandrel arch of 98 m (320 ft), twin
## ribs deepening towards the springings and tied by struts, the paired
## spandrel columns with their cross ties and bent caps, the two heavy
## Art Deco buttress piers at the arch ends, the tall braced bents of
## the approaches climbing the canyon walls, and the 7.3 m deck 79 m
## above the creek with its corbelled fascia and post-and-rail parapet,
## 218 m (714 ft) end to end.
const BX_SPAN := 98.0
const BX_DECK_M := 78.0
const BX_TOP_M := 79.0
const BX_LENGTH := 218.0
const BX_HALF_W := 3.65
const BX_RIB_Z := 2.8
const BX_SPRING_M := 12.0

static func bixby(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFC9BC", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	var half := BX_SPAN * 0.5
	var crown := BX_DECK_M - 3.0
	# Twin arch ribs, deeper at the springings, on footings at the rock.
	var segs := 48
	for k in range(2, segs - 1, 3):
		var sx := -half + BX_SPAN * k / segs
		lm.beam("Concrete", Vector3(sx, _bx_rib(sx, crown), -BX_RIB_Z), Vector3(sx, _bx_rib(sx, crown), BX_RIB_Z), 0.8, 1.2)
	for rz in [-BX_RIB_Z, BX_RIB_Z]:
		var z: float = rz
		for k in segs:
			var xa := -half + BX_SPAN * k / segs
			var xb := -half + BX_SPAN * (k + 1) / segs
			var depth := lerpf(2.4, 4.2, absf((xa + xb) * 0.5) / half)
			lm.beam("Concrete", Vector3(xa, _bx_rib(xa, crown), z), Vector3(xb, _bx_rib(xb, crown), z), 1.8, depth,
				Vector3(0, 0, 1))
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * half, BX_SPRING_M * 0.5, 0), Vector3(10.0, BX_SPRING_M, 9.0))
	# Spandrel bents: paired columns on the ribs with cross ties, caps
	# and struts between the ribs.
	var x := -half + 7.0
	while x < half - 3.0:
		var yb := _bx_rib(x, crown)
		var hgt := BX_DECK_M - 0.8 - yb
		lm.box("Concrete", Vector3(x, yb, 0), Vector3(1.4, 1.0, BX_RIB_Z * 2.0 + 1.4), Basis(), 0.0)
		if hgt > 1.5:
			for z in [-BX_RIB_Z, BX_RIB_Z]:
				lm.box("Concrete", Vector3(x, yb + hgt * 0.5, float(z)), Vector3(1.1, hgt, 1.1))
				# Pedestal on the rib and the flared Art Deco cap.
				lm.box("Concrete", Vector3(x, yb + 0.9, float(z)), Vector3(1.6, 0.8, 1.6))
				if hgt > 3.0:
					lm.box("Concrete", Vector3(x, BX_DECK_M - 2.3, float(z)), Vector3(1.5, 0.6, 1.5))
			lm.box("Concrete", Vector3(x, BX_DECK_M - 1.4, 0), Vector3(1.4, 1.2, BX_RIB_Z * 2.0 + 1.6))
			var ty := yb + 7.0
			while ty < BX_DECK_M - 5.0:
				lm.box("Concrete", Vector3(x, ty, 0), Vector3(0.8, 0.9, BX_RIB_Z * 2.0), Basis(), 0.0)
				ty += 7.0
		x += 7.0
	# The two heavy buttress piers over the springings: stepped faces and
	# vertical Art Deco channels, rising to the deck.
	for s in [-1.0, 1.0]:
		var px: float = s * (half + 2.0)
		lm.box("Concrete", Vector3(px, (BX_SPRING_M + BX_DECK_M) * 0.5, 0), Vector3(6.0, BX_DECK_M - BX_SPRING_M, 8.6))
		lm.box("Concrete", Vector3(px, BX_SPRING_M + 6.0, 0), Vector3(7.0, 12.0, 9.6))
		lm.box("Concrete", Vector3(px, BX_DECK_M - 2.4, 0), Vector3(6.8, 1.6, 9.4))
		lm.box("Concrete", Vector3(px, BX_SPRING_M + 30.0, 0), Vector3(6.6, 1.0, 9.2))
		lm.box("Concrete", Vector3(px, BX_SPRING_M + 48.0, 0), Vector3(6.6, 1.0, 9.2))
		for f in [-1.0, 1.0]:
			for k in 3:
				lm.box("Concrete", Vector3(px - 2.0 + 2.0 * k, (BX_SPRING_M + BX_DECK_M) * 0.5 + 3.0, float(f) * 4.45),
					Vector3(0.9, BX_DECK_M - BX_SPRING_M - 12.0, 0.4))
			for k in 2:
				lm.box("Concrete", Vector3(px + float(f) * 3.15, (BX_SPRING_M + BX_DECK_M) * 0.5 + 3.0, -1.8 + 3.6 * k),
					Vector3(0.4, BX_DECK_M - BX_SPRING_M - 12.0, 1.2))
	# Approach bents climbing the canyon walls: paired columns with ties.
	for s in [-1.0, 1.0]:
		for off in [16.0, 31.0, 46.0]:
			var pxs: float = s * (half + float(off))
			var base := maxf(0.0, -10.0 + float(off) * 0.9)
			for z in [-BX_RIB_Z, BX_RIB_Z]:
				lm.box("Concrete", Vector3(pxs, (base + BX_DECK_M - 0.8) * 0.5, float(z)),
					Vector3(1.8, BX_DECK_M - 0.8 - base, 1.8))
				lm.box("Concrete", Vector3(pxs, base + 1.0, float(z)), Vector3(3.0, 2.0, 3.0))
				lm.box("Concrete", Vector3(pxs, BX_DECK_M - 2.4, float(z)), Vector3(2.4, 0.8, 2.4))
				for f in [-1.0, 1.0]:
					lm.box("Concrete", Vector3(pxs + float(f) * 0.95, (base + BX_DECK_M) * 0.5, float(z)),
						Vector3(0.2, BX_DECK_M - base - 6.0, 0.6), Basis(), 0.0)
			lm.box("Concrete", Vector3(pxs, BX_DECK_M - 1.4, 0), Vector3(2.0, 1.2, BX_RIB_Z * 2.0 + 2.0))
			var y := base + 8.0
			while y < BX_DECK_M - 4.0:
				lm.box("Concrete", Vector3(pxs, y, 0), Vector3(1.2, 1.2, BX_RIB_Z * 2.0))
				y += 8.0
	# Deck, fascia beams and the corbels under the cantilevered edge.
	lm.box("Deck", Vector3(0, BX_DECK_M + 0.15, 0), Vector3(BX_LENGTH, 0.3, BX_HALF_W * 2.0))
	lm.box("Concrete", Vector3(0, BX_DECK_M - 0.4, 0), Vector3(BX_LENGTH, 0.8, BX_HALF_W * 2.0 + 0.4))
	for z in [-BX_HALF_W, BX_HALF_W]:
		lm.box("Concrete", Vector3(0, BX_DECK_M - 1.1, float(z) * 0.9), Vector3(BX_LENGTH, 0.8, 0.5))
		var cx := -BX_LENGTH * 0.5 + 0.875
		while cx < BX_LENGTH * 0.5:
			lm.box("Concrete", Vector3(cx, BX_DECK_M - 1.0, float(z)), Vector3(0.4, 0.8, 0.6), Basis(), 0.0)
			cx += 1.75
	# Longitudinal girders under the column lines, haunched at each bent.
	var gx := -BX_LENGTH * 0.5
	while gx < BX_LENGTH * 0.5:
		for z in [-BX_RIB_Z, BX_RIB_Z]:
			lm.box("Concrete", Vector3(gx + 3.5, BX_DECK_M - 1.5, float(z)), Vector3(7.0, 1.2, 0.7))
			lm.box("Concrete", Vector3(gx, BX_DECK_M - 2.2, float(z)), Vector3(2.4, 0.6, 0.8), Basis(), 0.0)
		gx += 7.0
	# Parapet: base kerb, posts, mid and top rails, pilasters at the bents.
	for z in [-BX_HALF_W, BX_HALF_W]:
		var zz: float = z
		lm.box("Concrete", Vector3(0, BX_DECK_M + 0.25, zz), Vector3(BX_LENGTH, 0.5, 0.35))
		lm.box("Concrete", Vector3(0, BX_TOP_M - 0.1, zz), Vector3(BX_LENGTH, 0.2, 0.3), Basis(), 0.0)
		lm.box("Concrete", Vector3(0, BX_DECK_M + 0.65, zz), Vector3(BX_LENGTH, 0.12, 0.2), Basis(), 0.0)
		var rx := -BX_LENGTH * 0.5
		var k := 0
		while rx <= BX_LENGTH * 0.5:
			if k % 4 == 0:
				lm.box("Concrete", Vector3(rx, (BX_DECK_M + BX_TOP_M) * 0.5 + 0.1, zz), Vector3(0.5, BX_TOP_M - BX_DECK_M + 0.2, 0.45))
			else:
				lm.box("Concrete", Vector3(rx, (BX_DECK_M + BX_TOP_M) * 0.5, zz), Vector3(0.18, BX_TOP_M - BX_DECK_M, 0.18), Basis(), 0.0)
			rx += 1.75
			k += 1
	lm.commit(model)

## Height of the rib's centre line at x: a parabola from the springings
## (±half) to the crown.
static func _bx_rib(x: float, crown: float) -> float:
	var u := x / (BX_SPAN * 0.5)
	return BX_SPRING_M + (crown - BX_SPRING_M) * (1.0 - u * u)
