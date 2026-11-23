class_name FtSuomenJoutsenRig
extends RefCounted

## Full-rigged 3-masted sailing rig of Suomen Joutsen (1902, St-Nazaire):
##   - 3 raked steel/wood masts: Fore (+20 m -> 40.5 m), Main (-1 m -> 44.0 m),
##     Mizzen (-22 m -> 38.0 m) with authentic 3-tone paint: gleaming white
##     lower mast & topmast, warm varnished mahogany topgallant/royal mast,
##     white masthead pole & gilded truck ball.
##   - White D-shaped fighting tops & crosstrees.
##   - 15 gleaming white tapered square-rig yards (5 per mast: course, paired
##     lower & upper topsails, topgallant, royal) slightly braced (~8°) with
##     neat white furled sail covers, dark gaskets, drooping footropes, lifts,
##     and braces running aft to the next mast or stern quarters.
##   - Mizzen spanker boom & gaff over the poop deck.
##   - Full standing rigging: 6 lower shrouds/side with ratlines, 4 topmast
##     shrouds/side with ratlines, topgallant shrouds, triple backstays, and
##     fan of 4 forestays to the bowsprit/jibboom + inter-mast stays.

const MASTS := [
	[20.0, 40.5, 0.93],
	[-1.0, 44.0, 1.00],
	[-22.0, 38.0, 0.86],
]
## Course, paired double topsails (lower & upper), topgallant, royal.
const YARD_FRACS := [0.29, 0.43, 0.50, 0.68, 0.84]
const YARD_WIDTHS := [21.0, 18.4, 17.0, 13.4, 9.6]
const RAKE := -0.042
const BRACE_RAD := 0.14 # ~8 deg brace angle matching moored photos

static func build(lm: LandmarkMesh, spec: Dictionary, bow_pts: Dictionary) -> void:
	var heads: Array = []
	for i in MASTS.size():
		var m: Array = MASTS[i]
		heads.append(_build_mast(lm, spec, float(m[0]), float(m[1]), float(m[2])))
	for i in MASTS.size():
		_build_standing(lm, spec, heads, i, bow_pts)
		_build_braces(lm, spec, heads, i)
	_build_spanker(lm, spec, heads[2])

static func _axis(info: Dictionary, y: float) -> Vector3:
	return Vector3(float(info["x"]) + RAKE * (y - float(info["deck"])), y, 0.0)

static func _build_mast(lm: LandmarkMesh, spec: Dictionary, mx: float, mh: float, sc: float) -> Dictionary:
	var deck := HullLoft.sheer(spec, mx)
	var span := mh - deck
	var y_top := deck + span * 0.37
	var y_cross := deck + span * 0.63
	var y_royal := deck + span * 0.87
	var info := {
		"x": mx, "deck": deck, "mh": mh, "sc": sc,
		"top": y_top, "cross": y_cross, "royal": y_royal,
		"yards": [],
	}
	var p_base := _axis(info, deck)
	var p_top := _axis(info, y_top)
	var p_cross := _axis(info, y_cross)
	var p_royal := _axis(info, y_royal)
	var p_pole := _axis(info, mh - 2.4 * sc)
	var p_truck := _axis(info, mh - 0.25)

	# 1. White lower mast (steel) + white topmast (slightly forward of lower masthead).
	var fwd := Vector3(0.14 * sc, 0.0, 0.0)
	HullLoft.tube(lm, "Hull", [p_base, p_top + Vector3(0, 1.0, 0)], 0.38 * sc, 10)
	HullLoft.tube(lm, "Hull", [p_top - Vector3(0, 1.2, 0) + fwd, p_cross + Vector3(0, 0.9, 0) + fwd], 0.26 * sc, 8)
	# 2. Warm varnished mahogany topgallant & royal mast above crosstrees.
	var fwd2 := Vector3(0.24 * sc, 0.0, 0.0)
	HullLoft.tube(lm, "MastWood", [p_cross - Vector3(0, 0.8, 0) + fwd2, p_pole + fwd2], 0.16 * sc, 8)
	# 3. Crisp white masthead pole & gilded truck ball.
	HullLoft.tube(lm, "Hull", [p_pole - Vector3(0, 0.1, 0) + fwd2, p_truck + fwd2], 0.08 * sc, 6)
	lm.lathe("Brass", p_truck + fwd2, LandmarkFrKit.ball(0.18), 8)
	# Masthead cap bands (white/dark iron).
	lm.box("Dark", p_top + Vector3(0.08 * sc, 0.95, 0.0), Vector3(0.72 * sc, 0.22, 0.56 * sc))
	lm.box("Dark", p_cross + Vector3(0.18 * sc, 0.82, 0.0), Vector3(0.52 * sc, 0.18, 0.42 * sc))
	# Warm masthead navigation lamp just below fighting top.
	lm.lathe("Lamp", p_top + Vector3(0.55 * sc, -0.35, 0.0), LandmarkFrKit.ball(0.14), 6)

	# Sleek white D-shaped fighting top platform with dark underside grating.
	var top_w := 4.0 * sc
	var top_l := 2.2 * sc
	VesselForms.slab(lm, "Hull", p_top + Vector3(0.12, 0.0, 0.0), Vector3(top_l, 0.16, top_w), top_w * 0.28)
	lm.box("Dark", p_top + Vector3(0.12, -0.10, 0.0), Vector3(top_l * 0.85, 0.08, top_w * 0.85))
	# White topmast crosstrees (spreaders).
	var cw := 2.5 * sc
	lm.beam("Hull", p_cross + fwd + Vector3(0, 0, -cw), p_cross + fwd + Vector3(0, 0, cw), 0.10, 0.12)
	lm.beam("Hull", p_cross + fwd + Vector3(-0.45 * sc, 0, -cw * 0.85),
		p_cross + fwd + Vector3(-0.45 * sc, 0, cw * 0.85), 0.09, 0.10)
	lm.beam("Hull", p_cross + fwd + Vector3(-0.75 * sc, 0, -0.45 * sc),
		p_cross + fwd + Vector3(0.65 * sc, 0, -0.45 * sc), 0.09, 0.09)
	lm.beam("Hull", p_cross + fwd + Vector3(-0.75 * sc, 0, 0.45 * sc),
		p_cross + fwd + Vector3(0.65 * sc, 0, 0.45 * sc), 0.09, 0.09)

	# Five gleaming white tapered square-rig yards per mast.
	for k in YARD_FRACS.size():
		var yy := deck + span * float(YARD_FRACS[k])
		var ylen := float(YARD_WIDTHS[k]) * sc
		(info["yards"] as Array).append(_build_yard(lm, info, yy, ylen, k))
	return info

static func _build_yard(lm: LandmarkMesh, info: Dictionary, yy: float, ylen: float, k: int) -> Dictionary:
	var sc: float = info["sc"]
	var mh: float = info["mh"]
	var fwd_off := 0.48 * sc if k < 3 else 0.36 * sc
	var ctr := _axis(info, yy) + Vector3(fwd_off, 0.0, 0.0)
	var hw := ylen * 0.5
	var yr := lerpf(0.19, 0.085, float(k) / 4.0) * sc
	# Subtle brace angle so yards read cleanly in both broadside & quarter views.
	var ydir := Vector3(sin(BRACE_RAD), 0.0, cos(BRACE_RAD))
	var p_lo := ctr - ydir * hw
	var p_hi := ctr + ydir * hw
	# Three-stage smoothly tapered white yard spar.
	HullLoft.tube(lm, "Hull", [p_lo, p_hi], yr * 0.50, 6)
	HullLoft.tube(lm, "Hull", [ctr - ydir * (hw * 0.65), ctr + ydir * (hw * 0.65)], yr * 0.78, 6)
	HullLoft.tube(lm, "Hull", [ctr - ydir * (hw * 0.32), ctr + ydir * (hw * 0.32)], yr, 8)
	# Sleek furled white sail cover on the course & topsail yards (with dark gaskets).
	if k <= 3:
		var sr := yr * (1.20 if k <= 2 else 0.95)
		var bundle: Array = []
		for j in 9:
			var t := float(j) / 8.0
			var fat := sin(PI * lerpf(0.12, 0.88, t))
			var along := lerpf(-hw * 0.86, hw * 0.86, t)
			bundle.append(ctr + ydir * along + Vector3(0.06, yr + sr * 0.45 + 0.06 * fat, 0.0))
		HullLoft.tube(lm, "Sail", bundle, sr, 6)
		for g in [2, 4, 6]:
			var gp: Vector3 = bundle[g]
			HullLoft.tube(lm, "Dark", [gp + Vector3(0, sr * 0.9, 0), gp + Vector3(0, -yr * 1.4, 0)], 0.014, 3)
	# Drooping dark footrope underneath the yard + vertical stirrups.
	var fr_drop := clampf(ylen * 0.042, 0.32, 0.75)
	var fr_a := ctr - ydir * (hw * 0.92) + Vector3(-0.08, -0.10, 0.0)
	var fr_b := ctr + ydir * (hw * 0.92) + Vector3(-0.08, -0.10, 0.0)
	VesselEquipment.line(lm, fr_a, fr_b, fr_drop, 0.015)
	for st in [0.22, 0.50, 0.78]:
		var top_pt := ctr + ydir * lerpf(-hw * 0.92, hw * 0.92, st) + Vector3(-0.04, -yr * 0.5, 0.0)
		var bot_pt := fr_a.lerp(fr_b, st) - Vector3.UP * sin(PI * st) * fr_drop
		HullLoft.tube(lm, "Dark", [top_pt, bot_pt], 0.012, 3)
	# Yard lifts from both yardarms up to the mast above.
	var lift_y := minf(yy + lerpf(3.8, 2.2, float(k) / 4.0), mh - 0.5)
	var lift_top := _axis(info, lift_y) + Vector3(0.18 * sc, 0.0, 0.0)
	for s: float in [-1.0, 1.0]:
		HullLoft.tube(lm, "Dark", [ctr + ydir * (hw * 0.96 * s), lift_top], 0.018, 3)
	return {"y": yy, "ctr": ctr, "dir": ydir, "hw": hw}

static func _build_standing(lm: LandmarkMesh, spec: Dictionary, heads: Array, i: int, bow_pts: Dictionary) -> void:
	var info: Dictionary = heads[i]
	var mx: float = info["x"]
	var sc: float = info["sc"]
	var y_top: float = info["top"]
	var y_cross: float = info["cross"]
	var y_royal: float = info["royal"]
	var mh: float = info["mh"]
	var p_top := _axis(info, y_top)
	var p_cross := _axis(info, y_cross) + Vector3(0.14 * sc, 0.0, 0.0)
	var p_royal := _axis(info, y_royal) + Vector3(0.24 * sc, 0.0, 0.0)

	for s: float in [-1.0, 1.0]:
		# 6 lower shrouds from hull sheer/channels up to fighting top + dense ratlines.
		var feet: Array = []
		var heads_up: Array = []
		for j in 6:
			var fx := mx - 2.8 + float(j) * 0.92
			var fy := HullLoft.sheer(spec, fx) + 0.95
			var fz := (HullLoft.half(spec, fx) + 0.08) * s
			var f := Vector3(fx, fy, fz)
			var u := p_top + Vector3(-0.65 + 0.25 * float(j), -0.20, (0.35 + 0.22 * float(j)) * sc * s)
			HullLoft.tube(lm, "Dark", [f, u], 0.028, 4)
			feet.append(f)
			heads_up.append(u)
		var f0: Vector3 = feet[0]
		var f5: Vector3 = feet[5]
		var u0: Vector3 = heads_up[0]
		var u5: Vector3 = heads_up[5]
		var rungs := int((y_top - 0.5 - f0.y) / 0.58)
		for r in range(2, rungs):
			var t := float(r) / float(rungs + 1)
			HullLoft.tube(lm, "Dark", [f0.lerp(u0, t), f5.lerp(u5, t)], 0.013, 3)

		# 4 topmast shrouds from fighting top edge to crosstrees + ratlines.
		var t_feet: Array = []
		var t_up: Array = []
		for j in 4:
			var tf := p_top + Vector3(0.75 * sc - 0.50 * sc * float(j), 0.08, (1.55 + 0.10 * float(j)) * sc * s)
			var tu := p_cross + Vector3(0.15 - 0.15 * float(j), -0.10, (0.30 + 0.12 * float(j)) * sc * s)
			HullLoft.tube(lm, "Dark", [tf, tu], 0.022, 3)
			t_feet.append(tf)
			t_up.append(tu)
		var t_rungs := int((y_cross - y_top) / 0.65)
		for r in range(1, t_rungs):
			var t := float(r) / float(t_rungs + 1)
			HullLoft.tube(lm, "Dark", [(t_feet[0] as Vector3).lerp(t_up[0], t),
				(t_feet[3] as Vector3).lerp(t_up[3], t)], 0.011, 3)

		# Topgallant shrouds from crosstrees to royal masthead.
		for j in 2:
			var cf := p_cross + Vector3(0.1 - 0.35 * float(j), 0.05, (2.05 + 0.15 * float(j)) * sc * s)
			HullLoft.tube(lm, "Dark", [cf, p_royal + Vector3(0, -0.2, 0.15 * s)], 0.018, 3)

		# Triple backstays sweeping aft from topmast, topgallant & royal mastheads to hull quarters.
		var b_offs := [6.5, 9.5, 12.2]
		var b_tops := [p_cross + Vector3(0, 0.0, 0.35 * s),
			p_royal + Vector3(0, 0.0, 0.20 * s),
			_axis(info, mh - 2.6 * sc) + Vector3(0.24 * sc, 0.0, 0.10 * s)]
		for b in 3:
			var bx := maxf(mx - float(b_offs[b]), -float(spec["length"]) * 0.45)
			var q := Vector3(bx, HullLoft.sheer(spec, bx) + 0.95, (HullLoft.half(spec, bx) + 0.06) * s)
			HullLoft.tube(lm, "Dark", [q, b_tops[b]], 0.024 - 0.003 * float(b), 3)

	# Fore-and-aft standing stays.
	if i == 0:
		var stem_top: Vector3 = bow_pts["stem_top"]
		var cap: Vector3 = bow_pts["cap"]
		var mid_jib: Vector3 = bow_pts["mid_jib"]
		var tip: Vector3 = bow_pts["tip"]
		VesselEquipment.line(lm, p_top + Vector3(0.3, 0, 0), stem_top + Vector3(-1.2, 0.6, 0), 0.18, 0.036)
		VesselEquipment.line(lm, p_cross, cap, 0.25, 0.030)
		VesselEquipment.line(lm, p_royal, mid_jib, 0.30, 0.025)
		VesselEquipment.line(lm, _axis(info, mh - 2.4 * sc) + Vector3(0.24 * sc, 0, 0), tip, 0.36, 0.022)
	else:
		var ahead: Dictionary = heads[i - 1]
		var ax: float = ahead["x"]
		var adeck: float = ahead["deck"]
		VesselEquipment.line(lm, p_top, Vector3(ax + 0.8, adeck + 1.4, 0.0), 0.16, 0.034)
		VesselEquipment.line(lm, p_cross, _axis(ahead, float(ahead["top"]) + 0.6), 0.20, 0.028)
		VesselEquipment.line(lm, p_royal, _axis(ahead, float(ahead["cross"]) + 0.6), 0.24, 0.024)
		VesselEquipment.line(lm, _axis(info, mh - 2.4 * sc) + Vector3(0.24 * sc, 0, 0),
			_axis(ahead, float(ahead["royal"]) + 0.4), 0.28, 0.020)

static func _build_braces(lm: LandmarkMesh, spec: Dictionary, heads: Array, i: int) -> void:
	var info: Dictionary = heads[i]
	for yd: Dictionary in info["yards"]:
		var ctr: Vector3 = yd["ctr"]
		var ydir: Vector3 = yd["dir"]
		var hw: float = yd["hw"]
		var yy: float = yd["y"]
		for s: float in [-1.0, 1.0]:
			var arm := ctr + ydir * (hw * 0.95 * s)
			var to := Vector3.ZERO
			if i < heads.size() - 1:
				var aft: Dictionary = heads[i + 1]
				to = _axis(aft, clampf(yy - 2.2, float(aft["deck"]) + 4.0, float(aft["mh"]) - 4.0)) \
					+ Vector3(0.4, 0.0, 0.45 * s)
			else:
				var bx := -37.5
				to = Vector3(bx, HullLoft.sheer(spec, bx) + 1.1, (HullLoft.half(spec, bx) - 0.15) * s)
			HullLoft.tube(lm, "Dark", [arm, to], 0.015, 3)

static func _build_spanker(lm: LandmarkMesh, spec: Dictionary, miz: Dictionary) -> void:
	# White mizzen spanker boom & gaff extending aft over the poop deck.
	var mx: float = miz["x"]
	var deck: float = miz["deck"]
	var y_top: float = miz["top"]
	var boom_a := _axis(miz, deck + 3.4) + Vector3(-0.35, 0.0, 0.0)
	var boom_b := Vector3(-40.5, deck + 4.6, 0.0)
	HullLoft.tube(lm, "Hull", [boom_a, boom_b], 0.14, 8)
	var gaff_a := _axis(miz, y_top - 0.8) + Vector3(-0.32, 0.0, 0.0)
	var gaff_b := Vector3(-36.0, y_top + 4.6, 0.0)
	HullLoft.tube(lm, "Hull", [gaff_a, gaff_b], 0.11, 8)
	# Peak halyard & boom topping lift.
	HullLoft.tube(lm, "Dark", [gaff_b, _axis(miz, float(miz["cross"]) - 1.0)], 0.016, 3)
	HullLoft.tube(lm, "Dark", [boom_b, _axis(miz, y_top + 0.4)], 0.016, 3)
	HullLoft.tube(lm, "Dark", [gaff_b, boom_b], 0.014, 3)
