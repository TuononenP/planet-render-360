class_name TallShipDetails
extends RefCounted

## Near-view barque for PassengerVesselModel's "tall_ship" variant (metres,
## +X bow, `spec` as HullLoft): solid bulwarks with a rounded cap rail, a
## painted port band, stern windows on the raked transom, a bowsprit and
## jib-boom with furled headsails, and three masts built in sections
## (lower mast, top, topmast, crosstrees, topgallant). Fore and main carry
## round tapered yards, the courses and topsails set (belled square sails),
## the topgallants furled; a jib on the forestay; the mizzen a gaff
## and spanker boom. Shrouds lead to channels outside the hull, stays run
## fore and aft. On deck: a rounded deckhouse with a skylight, a galley
## house, hatches and a spoked wheel. Only existing vessel surfaces are
## used (Hull, Deck, White, Glass, Steel, Dark, Sail), so the draw-call
## budget is unchanged. The far model keeps PassengerVesselModel's boxes.

const MASTS := [0.28, -0.02, -0.3]

## Returns the bowsprit's [cap, tip]. `p.masts` = false leaves the masts and
## stays to the caller (an authored ship with its own rig).
static func build(lm: LandmarkMesh, spec: Dictionary, p: Dictionary, deck_y: float, h: float) -> Array:
	var ultra := bool(p.get("ultra", false))
	_bulwarks(lm, spec)
	_band(lm, spec)
	_stern(lm, spec)
	var jib := _bowsprit(lm, spec)
	_deck(lm, spec, deck_y)
	if bool(p.get("masts", true)):
		var heads: Array = []
		for i in MASTS.size():
			heads.append(_mast(lm, spec, i, deck_y, h, ultra))
		_stays(lm, heads, jib, deck_y)
	VesselForms.fittings(lm, spec)
	if ultra:
		VesselEquipment.deck(lm, spec)
	return jib

## A point on the hull side `drop` m under the sheer at station `t`
## (port side, |z|). Follows the lofted section, rake included.
static func _side(spec: Dictionary, t: float, drop: float) -> Vector3:
	var pts := HullLoft.section(spec, t)
	var top: Vector3 = pts[0]
	var mid: Vector3 = pts[1]
	var q := top.lerp(mid, drop / maxf(top.y - mid.y, 0.2))
	return Vector3(q.x, q.y, absf(q.z))

## Solid bulwarks: hull-coloured outside, white inside, a rounded teak cap
## rail, closed across the transom and at the stem.
static func _bulwarks(lm: LandmarkMesh, spec: Dictionary) -> void:
	var bh := clampf(float(spec["freeboard"]) * 0.35, 0.8, 1.2)
	var th := 0.14
	var n := 48
	for s in [-1.0, 1.0]:
		var ob := PackedVector3Array()
		var ot := PackedVector3Array()
		var ib := PackedVector3Array()
		var it := PackedVector3Array()
		var cap: Array = []
		for i in n + 1:
			var q := _side(spec, lerpf(0.0, 0.975, float(i) / float(n)), 0.0)
			var zi := maxf(q.z - th, 0.03)
			ob.append(Vector3(q.x, q.y, q.z * s))
			ot.append(Vector3(q.x, q.y + bh, q.z * s))
			ib.append(Vector3(q.x, q.y, zi * s))
			it.append(Vector3(q.x, q.y + bh, zi * s))
			cap.append(Vector3(q.x, q.y + bh + 0.04, (q.z + zi) * 0.5 * s))
		lm.grid("Hull", [ob, ot], Vector3(0, 0, s))
		lm.grid("White", [ib, it], Vector3(0, 0, -s))
		HullLoft.tube(lm, "Deck", cap, th * 0.75, 6)
	# Across the transom and the stem head.
	for t in [0.0, 0.975]:
		var q := _side(spec, t, 0.0)
		var face := Vector3.LEFT if t == 0.0 else Vector3.RIGHT
		lm.quad("Hull", Vector3(q.x, q.y, q.z), Vector3(q.x, q.y, -q.z), Vector3(q.x, q.y + bh, -q.z), Vector3(q.x, q.y + bh, q.z), face)
		lm.quad("White", Vector3(q.x, q.y, -q.z), Vector3(q.x, q.y, q.z), Vector3(q.x, q.y + bh, q.z), Vector3(q.x, q.y + bh, -q.z), -face)
		HullLoft.tube(lm, "Deck", [Vector3(q.x, q.y + bh + 0.04, -q.z), Vector3(q.x, q.y + bh + 0.04, q.z)], th * 0.75, 6)

## A white band just under the sheer with painted black ports.
static func _band(lm: LandmarkMesh, spec: Dictionary) -> void:
	var fb: float = spec["freeboard"]
	var d0 := fb * 0.08
	var d1 := fb * 0.3
	var n := 40
	var port_w := clampf(fb * 0.14, 0.3, 0.5)
	var pitch := maxf(float(spec["length"]) * 0.04, port_w * 4.0)
	for s in [-1.0, 1.0]:
		var hi := PackedVector3Array()
		var lo := PackedVector3Array()
		for i in n + 1:
			var t := lerpf(0.05, 0.93, float(i) / float(n))
			var a := _side(spec, t, d0)
			var b := _side(spec, t, d1)
			hi.append(Vector3(a.x, a.y, (a.z + 0.02) * s))
			lo.append(Vector3(b.x, b.y, (b.z + 0.02) * s))
		lm.grid("White", [lo, hi], Vector3(0, 0, s))
		var x0 := float(lo[0].x) + pitch * 0.5
		var x1 := float(lo[n].x) - pitch * 0.5
		var x := x0
		while x <= x1:
			var t := HullLoft.t_of(spec, x)
			var c := _side(spec, t, (d0 + d1) * 0.5)
			var z := (c.z + 0.07) * float(s)
			var hw := port_w * 0.5
			var hh := (d1 - d0) * 0.32
			lm.quad("Dark", Vector3(c.x - hw, c.y - hh, z), Vector3(c.x + hw, c.y - hh, z),
				Vector3(c.x + hw, c.y + hh, z), Vector3(c.x - hw, c.y + hh, z), Vector3(0, 0, s))
			x += pitch

## Stern windows in a white frame band across the raked transom.
static func _stern(lm: LandmarkMesh, spec: Dictionary) -> void:
	var top := _side(spec, 0.0, 0.0)
	var y1 := top.y - 0.3
	var y0 := y1 - clampf(float(spec["freeboard"]) * 0.2, 0.5, 0.8)
	var hz := top.z * 0.72
	var xa := HullLoft.transom_x(spec, y0) - 0.03
	var xb := HullLoft.transom_x(spec, y1) - 0.03
	lm.quad("White", Vector3(xa, y0 - 0.12, hz + 0.15), Vector3(xa, y0 - 0.12, -hz - 0.15),
		Vector3(xb, y1 + 0.12, -hz - 0.15), Vector3(xb, y1 + 0.12, hz + 0.15), Vector3.LEFT)
	var count := 5
	var w := hz * 2.0 / float(count)
	for k in count:
		var zc := -hz + w * (float(k) + 0.5)
		lm.quad("Glass", Vector3(xa - 0.02, y0, zc + w * 0.36), Vector3(xa - 0.02, y0, zc - w * 0.36),
			Vector3(xb - 0.02, y1, zc - w * 0.36), Vector3(xb - 0.02, y1, zc + w * 0.36), Vector3.LEFT)

## Bowsprit and jib-boom with furled headsails, bobstay, dolphin striker
## and a scroll on the trailboards. Returns [bowsprit cap, jib-boom end].
static func _bowsprit(lm: LandmarkMesh, spec: Dictionary) -> Array:
	var length: float = spec["length"]
	var stem := _side(spec, 0.985, 0.0)
	var rise := tan(deg_to_rad(12.0))
	var r0 := clampf(float(spec["beam"]) * 0.02, 0.1, 0.22)
	var heel := Vector3(stem.x - length * 0.05, stem.y + 0.3, 0)
	var cap := Vector3(stem.x + length * 0.07, stem.y + 0.3 + (length * 0.12) * rise, 0)
	var tip := Vector3(stem.x + length * 0.15, stem.y + 0.3 + (length * 0.2) * rise, 0)
	var dir := (tip - heel).normalized()
	HullLoft.tube(lm, "White", [heel, cap + dir * r0], r0, 10)
	HullLoft.tube(lm, "Deck", [cap - dir * length * 0.035, tip], r0 * 0.55, 8)
	lm.box("Dark", cap + Vector3(0, r0 * 0.2, 0), Vector3(r0 * 1.2, r0 * 2.6, r0 * 2.2), Basis(), 0.0)
	# Headsails furled along the spars.
	HullLoft.tube(lm, "Sail", [stem + Vector3(length * 0.01, 0.3 + r0 * 1.6, 0), cap + Vector3(0, r0 * 1.4, 0),
		tip + Vector3(-length * 0.01, r0 * 0.9, 0)], r0 * 0.75, 8)
	var striker := cap + Vector3(-0.1, -clampf(length * 0.025, 0.8, 1.8), 0)
	HullLoft.tube(lm, "Dark", [cap, striker], r0 * 0.3, 6)
	HullLoft.tube(lm, "Dark", [tip, striker, Vector3(stem.x - 0.1, 0.4, 0)], 0.03, 4)
	HullLoft.tube(lm, "Dark", [cap, Vector3(stem.x - 0.05, 0.25, 0)], 0.035, 4)
	# Trailboard scroll on both bows.
	for s in [-1.0, 1.0]:
		var path: Array = []
		for i in 9:
			var q := _side(spec, lerpf(0.86, 0.975, float(i) / 8.0), float(spec["freeboard"]) * 0.18)
			path.append(Vector3(q.x, q.y, (q.z + 0.04) * s))
		HullLoft.tube(lm, "White", path, 0.05, 5)
		VesselEquipment.ring(lm, "White", (path[0] as Vector3) + Vector3(-0.15, -0.1, 0), Vector3(0, 0, s), 0.16, 0.04)
	return [cap, tip]

## Deckhouse with a skylight aft, a galley house forward, hatches and a
## spoked wheel.
static func _deck(lm: LandmarkMesh, spec: Dictionary, deck_y: float) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var hx := -length * 0.375
	var hl := length * 0.08
	var hw := minf(beam * 0.46, (HullLoft.half(spec, hx - hl * 0.5) - 0.7) * 2.0)
	var hh := 2.1
	VesselForms.cabin(lm, hx, hl, hw, deck_y, hh, 1.1, "White", 0.12)
	VesselForms.slab(lm, "Deck", Vector3(hx, deck_y + hh + 0.05, 0), Vector3(hl + 0.3, 0.1, hw + 0.3), minf(hw * 0.2, 0.6))
	VesselForms.slab(lm, "White", Vector3(hx, deck_y + hh + 0.25, 0), Vector3(hl * 0.35, 0.3, hw * 0.35), 0.1)
	for s in [-1.0, 1.0]:
		lm.quad("Glass", Vector3(hx - hl * 0.16, deck_y + hh + 0.41, 0), Vector3(hx + hl * 0.16, deck_y + hh + 0.41, 0),
			Vector3(hx + hl * 0.16, deck_y + hh + 0.31, hw * 0.17 * s), Vector3(hx - hl * 0.16, deck_y + hh + 0.31, hw * 0.17 * s),
			Vector3(0, 0.8, 0.6 * s))
	var gx := length * 0.13
	VesselForms.cabin(lm, gx, length * 0.07, beam * 0.34, deck_y, 1.9, 0.9, "White", 0.08)
	VesselForms.slab(lm, "Deck", Vector3(gx, deck_y + 1.95, 0), Vector3(length * 0.07 + 0.25, 0.1, beam * 0.34 + 0.25), 0.3)
	HullLoft.tube(lm, "Dark", [Vector3(gx - length * 0.02, deck_y + 1.9, beam * 0.08), Vector3(gx - length * 0.02, deck_y + 2.9, beam * 0.08)], 0.12, 8)
	for x in [-0.13, 0.205]:
		VesselForms.hatch(lm, Vector3(length * float(x), deck_y + 0.06, 0), length * 0.07, beam * 0.3)
	_wheel(lm, Vector3(-length * 0.44, HullLoft.sheer(spec, -length * 0.44), 0))

static func _wheel(lm: LandmarkMesh, at: Vector3) -> void:
	lm.box("Deck", at + Vector3(0, 0.5, 0), Vector3(0.3, 1.0, 0.25), Basis(), 0.03)
	var c := at + Vector3(0.2, 1.05, 0)
	VesselEquipment.ring(lm, "Deck", c, Vector3.RIGHT, 0.55, 0.035)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var dir := Vector3(0, cos(a), sin(a))
		HullLoft.tube(lm, "Deck", [c, c + dir * 0.72], 0.022, 4)

## One mast in sections. Returns {"top": lower masthead, "head": topmast
## head, "x": mast x}.
static func _mast(lm: LandmarkMesh, spec: Dictionary, i: int, deck_y: float, h: float, ultra: bool) -> Dictionary:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var mx := length * float(MASTS[i])
	var mh := h * (0.82 if i == 1 else 0.7) if i < 2 else h * 0.55
	var r := maxf(beam * 0.03, 0.12)
	var y_top := deck_y + mh * 0.46
	var y_cross := deck_y + mh * 0.76
	var tx := mx + r * 1.3
	lm.lathe("White", Vector3(mx, deck_y, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 0.85, y_top - deck_y + 0.4)]), 12)
	lm.lathe("Deck", Vector3(tx, y_top - mh * 0.04, 0), PackedVector2Array([Vector2(r * 0.7, 0), Vector2(r * 0.55, y_cross - y_top + mh * 0.06)]), 10)
	if i < 2:
		lm.lathe("Deck", Vector3(tx, y_cross - mh * 0.03, 0), PackedVector2Array([Vector2(r * 0.45, 0), Vector2(r * 0.25, deck_y + mh - y_cross + mh * 0.03)]), 8)
		lm.lathe("Dark", Vector3(tx, deck_y + mh, 0), PackedVector2Array([Vector2(r * 0.4, 0), Vector2(r * 0.4, r * 0.4)]), 8)
	# Top and crosstrees.
	var top_w := maxf(beam * 0.24, 1.4)
	VesselForms.slab(lm, "Deck", Vector3(mx + r * 0.6, y_top, 0), Vector3(maxf(beam * 0.13, 0.9), 0.12, top_w), top_w * 0.3)
	lm.beam("Deck", Vector3(tx, y_cross, -beam * 0.1), Vector3(tx, y_cross, beam * 0.1), 0.08)
	_shrouds(lm, spec, mx, Vector3(mx, y_top - 0.15, 0), r, top_w, Vector3(tx, y_cross, 0), y_top, ultra)
	if i < 2:
		var scale := 1.0 if i == 1 else 0.93
		var levels := [[0.43, 1.75], [0.64, 1.38], [0.87, 1.02]]
		for k in levels.size():
			var yy := deck_y + mh * float(levels[k][0])
			var ax := (mx if k == 0 else tx) + r * 1.2
			# The courses and topsails are set, the topgallants furled.
			var drop := mh * (0.3 if k == 0 else (0.19 if k == 1 else 0.0))
			_yard(lm, Vector3(ax, yy, 0), beam * float(levels[k][1]) * scale, beam, Vector3(mx if k == 0 else tx, yy + mh * 0.12, 0), drop)
	else:
		_spanker(lm, spec, mx, r, deck_y, mh)
	return {"top": Vector3(mx, y_top, 0), "head": Vector3(tx, y_cross, 0), "x": mx}

## A tapered round yard with its sail furled on top, a footrope and lifts.
static func _yard(lm: LandmarkMesh, at: Vector3, span: float, beam: float, lift_to: Vector3, drop: float = 0.0) -> void:
	var ry := maxf(beam * 0.014, 0.07)
	var half := span * 0.5
	HullLoft.tube(lm, "Dark", [at - Vector3(0, 0, half), at + Vector3(0, 0, half)], ry * 0.6, 6)
	HullLoft.tube(lm, "Dark", [at - Vector3(0, 0, half * 0.5), at + Vector3(0, 0, half * 0.5)], ry, 8)
	if drop > 0.0:
		_square_sail(lm, at, span, drop)
		for s in [-1.0, 1.0]:
			HullLoft.tube(lm, "Dark", [at + Vector3(0, 0, half * 0.97 * s), lift_to], 0.015, 4)
		return
	var rs := maxf(beam * 0.017, 0.09)
	var bundle: Array = []
	for k in 9:
		var t := float(k) / 8.0
		var z := lerpf(-half * 0.9, half * 0.9, t)
		var fat := sin(PI * lerpf(0.12, 0.88, t))
		bundle.append(at + Vector3(rs * 0.3, ry + rs * 0.5 + rs * 0.5 * fat - 0.04 * sin(PI * t), z))
	HullLoft.tube(lm, "Sail", bundle, rs, 8)
	# Thicker in the bunt, where the sail is gathered at the mast.
	HullLoft.tube(lm, "Sail", [bundle[3], bundle[4], bundle[5]], rs * 1.5, 8)
	VesselEquipment.line(lm, at + Vector3(-0.1, -0.15, -half * 0.94), at + Vector3(-0.1, -0.15, half * 0.94), clampf(span * 0.05, 0.3, 0.8), 0.015)
	for s in [-1.0, 1.0]:
		HullLoft.tube(lm, "Dark", [at + Vector3(0, 0, half * 0.97 * s), lift_to], 0.015, 4)

## A set square sail hanging `drop` m from the yard at `at`, wider at the foot
## and belled forward (+X) in the middle: five rows by eight columns, one
## surface (the double-sided canvas), about 80 triangles a sail.
static func _square_sail(lm: LandmarkMesh, at: Vector3, span: float, drop: float) -> void:
	var rows: Array = []
	var bell := minf(span * 0.1, 1.1)
	for j in 5:
		var v := float(j) / 4.0
		var row := PackedVector3Array()
		var w := span * 0.5 * lerpf(0.92, 1.0, v)
		for i in 9:
			var u := float(i) / 8.0
			row.append(Vector3(at.x + bell * sin(PI * u) * sin(PI * clampf(v * 0.85 + 0.1, 0.0, 1.0)),
				at.y - 0.1 - drop * v + 0.25 * sin(PI * u) * v, lerpf(-w, w, u)))
		rows.append(row)
	lm.grid("Sail", rows, Vector3.RIGHT)

## The mizzen's gaff and spanker boom, the sail furled on the boom.
static func _spanker(lm: LandmarkMesh, spec: Dictionary, mx: float, r: float, deck_y: float, mh: float) -> void:
	var length: float = spec["length"]
	var rb := maxf(float(spec["beam"]) * 0.014, 0.08)
	var boom_y := deck_y + 2.9
	var boom_end := Vector3(HullLoft.transom_x(spec, float(spec["freeboard"])) - length * 0.035, boom_y + 0.4, 0)
	HullLoft.tube(lm, "Deck", [Vector3(mx - r, boom_y, 0), boom_end], rb, 8)
	HullLoft.tube(lm, "Sail", [Vector3(mx - r - 0.3, boom_y + rb + 0.1, 0), boom_end + Vector3(length * 0.03, rb + 0.08, 0)], rb * 1.4, 8)
	var gaff_a := Vector3(mx - r, deck_y + mh * 0.5, 0)
	var gaff_b := gaff_a + Vector3(-length * 0.13, length * 0.06, 0)
	HullLoft.tube(lm, "Deck", [gaff_a, gaff_b], rb * 0.8, 8)
	HullLoft.tube(lm, "Dark", [gaff_b, boom_end], 0.015, 4)
	HullLoft.tube(lm, "Dark", [Vector3(mx, deck_y + mh * 0.7, 0), boom_end], 0.015, 4)

## Lower shrouds to channels outside the hull (deadeyes at their feet,
## ratlines on Ultra) and topmast shrouds to the edge of the top.
static func _shrouds(lm: LandmarkMesh, spec: Dictionary, mx: float, from: Vector3, r: float, top_w: float,
		head: Vector3, y_top: float, ultra: bool) -> void:
	var length: float = spec["length"]
	var cx0 := mx - length * 0.065
	var cx1 := mx + length * 0.01
	for s in [-1.0, 1.0]:
		var cz := HullLoft.half(spec, (cx0 + cx1) * 0.5) + 0.6
		var cy := HullLoft.sheer(spec, (cx0 + cx1) * 0.5) - 0.15
		lm.box("Dark", Vector3((cx0 + cx1) * 0.5, cy, (cz - 0.3) * s), Vector3(cx1 - cx0, 0.1, 0.7), Basis(), 0.0)
		var feet: Array = []
		for k in 4:
			var fx := lerpf(cx1 - 0.3, cx0 + 0.3, float(k) / 3.0)
			var foot := Vector3(fx, cy + 0.55, cz * s)
			feet.append(foot)
			HullLoft.tube(lm, "Dark", [foot, from + Vector3(0, 0, r * 1.1 * s)], 0.025, 4)
			lm.disc("Dark", foot + Vector3(0, -0.2, 0.03 * s), Vector3(0, 0, s), 0.13, 8)
			HullLoft.tube(lm, "Dark", [foot + Vector3(0, -0.3, 0), Vector3(fx, cy, cz * s)], 0.02, 4)
		if ultra:
			var a: Vector3 = feet[0]
			var b: Vector3 = feet[3]
			var rungs := int((y_top - a.y) / 0.42)
			for k in rungs:
				var t := (float(k) + 1.0) / float(rungs + 2)
				HullLoft.tube(lm, "Dark", [a.lerp(from, t), b.lerp(from, t)], 0.012, 4)
		for k in 3:
			var foot := Vector3(mx + r * 0.6 + lerpf(0.25, -0.35, float(k) / 2.0), y_top + 0.06, top_w * 0.47 * s)
			HullLoft.tube(lm, "Dark", [foot, head + Vector3(0, -0.1, 0.1 * s)], 0.02, 4)

## Forestays from each mast to the next one forward and the bowsprit.
static func _stays(lm: LandmarkMesh, heads: Array, jib: Array, deck_y: float) -> void:
	var fore: Dictionary = heads[0]
	var cap: Vector3 = jib[0]
	var tip: Vector3 = jib[1]
	_stay(lm, fore["top"], cap)
	_stay(lm, fore["head"], tip)
	# A jib set on the forestay: tack at the jib-boom end, head up the stay, clew on deck.
	var head: Vector3 = fore["head"]
	var luff := tip.lerp(head, 0.55)
	var clew := Vector3(float(fore["x"]) + 1.0, deck_y + 1.6, 0)
	lm.tri("Sail", tip + Vector3(0, 0.1, 0), luff, clew, Vector3.BACK, Vector3.BACK, Vector3.BACK,
		Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1))
	lm.tri("Sail", tip + Vector3(0, 0.1, 0), clew, luff, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
		Vector2(0, 0), Vector2(0.5, 1), Vector2(1, 0))
	for i in range(1, heads.size()):
		var m: Dictionary = heads[i]
		var ahead: Dictionary = heads[i - 1]
		_stay(lm, m["top"], Vector3(float(ahead["x"]) + 0.8, deck_y + 0.6, 0))
		_stay(lm, m["head"], ahead["top"])

static func _stay(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	VesselEquipment.line(lm, a, b, a.distance_to(b) * 0.01, 0.025)
