class_name StoIslandRig
extends RefCounted

## The rig of af Chapman (full-rigged ship, 1888): three tall masts in
## true metres, +X bow, y = 0 at the waterline, centred on the hull.
##
## From the photos (visual-plan/refs/landmarks/af_chapman/): the masts stand
## at 0.29 / -0.01 / -0.29 of the hull length from the middle, 42.0 m (fore),
## 44.0 m (main) and 37.0 m (mizzen) above the water, with a slight rake aft.
## Each is in four stepped sections (lower mast, topmast, topgallant and
## royal mast) in cream-varnished steel, with a top platform and crosstrees
## at the heads of the lower mast and topmast and a gilt truck.
## Every mast carries five square yards (course, lower and upper topsail,
## topgallant, royal), 17.5 / 14.5 / 13 / 9.5 / 7 m long on fore and main
## (mizzen 0.9 of that), tapered round spars hung forward of the mast with
## the sail furled on top, lifts to the mast and braces leading aft.
## Standing rigging: six shrouds a side to each top with ratlines, topmast
## shrouds and backstays to the quarters, and stays from each mast head
## forward to the next mast or the bowsprit.

## Mast x as a share of the hull length, height above the water (m).
const MASTS := [[0.29, 42.0], [-0.01, 44.0], [-0.29, 37.0]]
## Yard heights as shares of the mast above its deck, and their lengths (m).
const YARD_AT := [0.29, 0.43, 0.54, 0.72, 0.86]
const YARD_LEN := [17.5, 14.5, 13.0, 9.5, 7.0]
const RAKE := -0.025

static func build(lm: LandmarkMesh, spec: Dictionary, jib: Array) -> void:
	var length: float = spec["length"]
	var heads: Array = []
	for i in MASTS.size():
		var m: Array = MASTS[i]
		var info := _mast(lm, spec, length * float(m[0]), float(m[1]), 0.9 if i == 2 else 1.0)
		heads.append(info)
	for i in MASTS.size():
		_standing(lm, spec, heads, i, jib)
		_braces(lm, spec, heads, i)

## A point on a mast's axis at height `y`.
static func axis(info: Dictionary, y: float) -> Vector3:
	return Vector3(float(info["x"]) + RAKE * (y - float(info["deck"])), y, 0.0)

static func _mast(lm: LandmarkMesh, spec: Dictionary, mx: float, top: float, scale: float) -> Dictionary:
	var deck := HullLoft.sheer(spec, mx)
	var span := top - deck
	var info := {"x": mx, "deck": deck, "top": top,
		"low": deck + span * 0.46, "head": deck + span * 0.76, "yards": []}
	var low: float = info["low"]
	var head: float = info["head"]
	HullLoft.tube(lm, "Mast", [axis(info, deck), axis(info, low + 0.8)], 0.36, 10)
	HullLoft.tube(lm, "Mast", [axis(info, low - 1.0) + Vector3(0.1, 0, 0), axis(info, head + 0.6) + Vector3(0.1, 0, 0)], 0.22, 8)
	HullLoft.tube(lm, "Mast", [axis(info, head - 0.8) + Vector3(0.2, 0, 0), axis(info, top - 0.4) + Vector3(0.2, 0, 0)], 0.12, 6)
	var t := axis(info, top - 0.4) + Vector3(0.2, 0, 0)
	lm.lathe("Gilt", t, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.13, 0.08), Vector2(0.17, 0.2),
		Vector2(0.11, 0.34), Vector2(0.0, 0.4)]), 8)
	# Tops at the lower mast head, a narrower trestle at the topmast head.
	var a := axis(info, low)
	lm.box("Dark", a + Vector3(0.1, 0, 0), Vector3(2.3, 0.14, 3.6 * scale))
	for s: float in [-1.0, 1.0]:
		lm.beam("Dark", a + Vector3(0.9, -0.2, 1.7 * s * scale), a + Vector3(-0.9, -0.2, 1.7 * s * scale), 0.1, 0.1)
	var b := axis(info, head) + Vector3(0.1, 0, 0)
	lm.box("Dark", b, Vector3(1.4, 0.1, 2.2 * scale))
	lm.beam("Dark", b + Vector3(0, 0, -1.1 * scale), b + Vector3(0, 0, 1.1 * scale), 0.1, 0.12)
	for k in YARD_AT.size():
		var y := deck + span * float(YARD_AT[k])
		(info["yards"] as Array).append(_yard(lm, info, y, float(YARD_LEN[k]) * scale, k))
	return info

## A round tapered yard hung forward of the mast with its sail furled on
## top; lifts run to the mast above. Returns {"y", "half", "x"}.
static func _yard(lm: LandmarkMesh, info: Dictionary, y: float, span: float, k: int) -> Dictionary:
	var c := axis(info, y) + Vector3(0.55, 0, 0)
	var half := span * 0.5
	var ry := 0.07 + span * 0.0055
	HullLoft.tube(lm, "Mast", [c + Vector3(0, 0, -half), c + Vector3(0, 0, half)], ry * 0.55, 6)
	HullLoft.tube(lm, "Mast", [c + Vector3(0, 0, -half * 0.55), c + Vector3(0, 0, half * 0.55)], ry, 8)
	var bundle: Array = []
	for j in 9:
		var t := float(j) / 8.0
		var fat := sin(PI * lerpf(0.1, 0.9, t))
		bundle.append(c + Vector3(0.04, ry + 0.12 + 0.1 * fat, lerpf(-half * 0.92, half * 0.92, t)))
	HullLoft.tube(lm, "Sail", bundle, ry * 1.5, 8)
	HullLoft.tube(lm, "Sail", [bundle[3], bundle[4], bundle[5]], ry * 2.0, 8)
	# Gaskets round the furled sail and the lifts to the mast above.
	for j in [2, 6]:
		HullLoft.tube(lm, "Dark", [bundle[j] + Vector3(0, ry * 1.2, 0), bundle[j] + Vector3(0, -ry * 1.5, 0)], 0.012, 3)
	var lift_to := axis(info, y + 2.6 + 0.6 * float(k))
	for s: float in [-1.0, 1.0]:
		HullLoft.tube(lm, "Dark", [c + Vector3(0, 0, half * 0.96 * s), lift_to], 0.018, 3)
	return {"y": y, "half": half, "x": c.x}

## Shrouds with ratlines, topmast shrouds, backstays and stays for mast i.
static func _standing(lm: LandmarkMesh, spec: Dictionary, heads: Array, i: int, jib: Array) -> void:
	var info: Dictionary = heads[i]
	var mx: float = info["x"]
	var deck: float = info["deck"]
	var low: float = info["low"]
	var head: float = info["head"]
	var top: float = info["top"]
	for s: float in [-1.0, 1.0]:
		# Lower shrouds from the chain plates up to the top, ratlines between.
		var feet: Array = []
		var heads_up: Array = []
		for j in 6:
			var fx := mx - 2.2 + float(j) * 0.8
			var f := Vector3(fx, HullLoft.sheer(spec, fx) + 0.9, (HullLoft.half(spec, fx) + 0.05) * s)
			var u := axis(info, low - 0.3) + Vector3(-0.5 + 0.2 * float(j), 0.0, (0.35 + 0.25 * float(j)) * s)
			HullLoft.tube(lm, "Dark", [f, u], 0.03, 4)
			feet.append(f)
			heads_up.append(u)
		var a: Vector3 = feet[0]
		var b: Vector3 = feet[5]
		var ua: Vector3 = heads_up[0]
		var ub: Vector3 = heads_up[5]
		var rungs := int((low - 0.3 - a.y) / 0.55) - 2
		for r in rungs:
			var t := (float(r) + 2.0) / float(rungs + 3)
			HullLoft.tube(lm, "Dark", [a.lerp(ua, t), b.lerp(ub, t)], 0.014, 3)
		# Topmast shrouds from the edge of the top to the crosstrees.
		for j in 3:
			var foot := axis(info, low) + Vector3(0.9 - 0.6 * float(j), 0.1, (1.3 + 0.2 * float(j)) * s)
			HullLoft.tube(lm, "Dark", [foot, axis(info, head) + Vector3(0.1, -0.1, 0.7 * s)], 0.022, 3)
		# Backstays from the topmast head and the truck to the quarter.
		var bx := mx - 9.0
		var quarter := Vector3(bx, HullLoft.sheer(spec, bx) + 0.9, (HullLoft.half(spec, bx) + 0.05) * s)
		HullLoft.tube(lm, "Dark", [axis(info, head) + Vector3(0.1, 0, 0.3 * s), quarter], 0.028, 4)
		var bx2 := mx - 12.0
		var quarter2 := Vector3(bx2, HullLoft.sheer(spec, bx2) + 0.9, (HullLoft.half(spec, bx2) + 0.05) * s)
		HullLoft.tube(lm, "Dark", [axis(info, top - 1.0) + Vector3(0.2, 0, 0.1 * s), quarter2], 0.022, 3)
	# Stays: forward and down to the next mast or the bowsprit.
	if i == 0:
		var cap: Vector3 = jib[0]
		var tip: Vector3 = jib[1]
		HullLoft.tube(lm, "Dark", [axis(info, head) + Vector3(0.1, 0, 0), cap], 0.04, 4)
		HullLoft.tube(lm, "Dark", [axis(info, top - 1.0) + Vector3(0.2, 0, 0), tip], 0.03, 4)
		HullLoft.tube(lm, "Dark", [axis(info, low), Vector3(float(spec["length"]) * 0.45, 4.6, 0)], 0.035, 4)
	else:
		var ahead: Dictionary = heads[i - 1]
		HullLoft.tube(lm, "Dark", [axis(info, head) + Vector3(0.1, 0, 0), Vector3(float(ahead["x"]) + 1.0, float(ahead["deck"]) + 1.0, 0)], 0.035, 4)
		HullLoft.tube(lm, "Dark", [axis(info, top - 1.0) + Vector3(0.2, 0, 0), axis(ahead, float(ahead["low"]) + 1.0)], 0.028, 4)
		HullLoft.tube(lm, "Dark", [axis(info, low), axis(ahead, float(ahead["head"]) - 2.0)], 0.03, 4)

## Braces from both ends of every yard back to the mast astern (or the hull
## at the mizzen).
static func _braces(lm: LandmarkMesh, spec: Dictionary, heads: Array, i: int) -> void:
	var info: Dictionary = heads[i]
	for yd: Dictionary in info["yards"]:
		for s: float in [-1.0, 1.0]:
			var end := Vector3(float(yd["x"]), float(yd["y"]), float(yd["half"]) * s * 0.97)
			var to := Vector3(0, 0, 0)
			if i < heads.size() - 1:
				var aft: Dictionary = heads[i + 1]
				to = axis(aft, float(yd["y"]) - 1.5) + Vector3(0.6, 0, 0.5 * s)
			else:
				var bx := float(info["x"]) - 11.0
				to = Vector3(bx, HullLoft.sheer(spec, bx) + 0.9, (HullLoft.half(spec, bx) - 0.2) * s)
			HullLoft.tube(lm, "Dark", [end, to], 0.016, 3)
