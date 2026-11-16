class_name LandmarkCoreBArchStation
extends RefCounted

## The `station` archetype: a railway station building drawn on its real
## outline (model frame: +X the long axis, +Z the forecourt side away from
## the tracks). A `style` dictionary (a registry row's `style`, see
## tools/capital_stations.tsv) says what the real building has; every key
## is optional and every height is a total above the ground:
##   eave      body height (default: `h`)
##   roof      "flat" (parapet), "hip" (sloped skirt `roof_rise` tall) or
##             "overhang" (a thin slab oversailing by `overhang` m)
##   glass     true: curtain walls with floor bands, not punched windows
##   storey    storey height for the window rows (default 4.5 m)
##   tower     "centre" / "side" / "twin" / "ends": clock towers standing
##             proud of the forecourt face (a side tower beside the hall or
##             centre block), `tower_w` wide, `tower_h` to the tip, cap
##             `tower_cap`: "spire", "pavilion", "dome", "flat", "pyramid",
##             "star" (belvedere and needle with a star), "dome_spire"
##             (dome under a gilt needle), "belvedere" (an open lantern of
##             columns under a hip) or "belfry" (arched belfry, cupola)
##   cap_hex   the tower roofs and dome in their own colour (sheet metal)
##   dome      a dome over the middle: `dome_r` radius, `dome_top` tip
##   hall      true: the arched booking hall in the middle of the front,
##             `hall_top` to its crown, with its lunette and clock
##   centre_h  a raised centre block on the front, `centre_w` wide,
##             glazed when `centre_glass`, its roof `centre_roof` ("flat",
##             "gable" or "mansard") rising `centre_rise` above it
##   band_hex  a cladding band `band_h` tall round the upper facade
##   louvre_hex horizontal louvre bands across the upper floors
##   centre_blank the centre block as a blank wall with a frieze
##   shell_canopy [depth, rise]: a cantilevered shell flush with the roof,
##             ribs curving `rise` down to the front, inclined end legs
##   portal    [w, h, arched, massive]: a framed central portal with a deep
##             canopy, or (massive) a clad block with broad piers and head
##   screens   true: sun-screen fins over a dark recessed ground floor
##   floor_band_hex a coloured band between the floors, glass-block panels
##   roof "gable": a long pitched roof along the building
##   front_clock one clock over the middle of the front
##   windows   "rect": plain rectangular windows, no arched ground floor
##   pavilions [w, h]: taller pavilions at both ends of the front
##   arcade    [n, w, h]: n great glazed arches across the front (in the
##             curtain glass when `glass_hex` is set)
##   cantilever [depth, lift]: a ribbed canopy cantilevered over the
##             forecourt from the eaves
##   hall_belfry h: the hall's front as a round-topped masonry gable
##             framing the clock, with a belfry `h` tall on its crown
##   colonnade n columns across the front, `col_h` tall
##   shells    "umbrella": a field of umbrella shells `shell_top` high;
##             "folded": a folded-plate roof `shell_top` high
##   underground true: the station is below ground; only an entrance
##             pavilion stands on the outline's front
## Without a style the station is a plain body to `h` with a canopy: a
## hall, clock or tower is drawn only where the real building has one.
## Features stand on the forecourt face where it crosses their x
## (front_point), not on the bounds, so irregular outlines keep them
## attached.
## Materials: the archetype's Walls, Roof, Trim, Windows, Gilt plus Dial
## and Steel.

const STOREY_M := 4.5

## Builds the station; returns the model's highest point (metres).
static func build(lm: LandmarkMesh, h: float, raw: PackedVector2Array, style: Dictionary = {}) -> float:
	# Footprints smoothed to within 0.6 m: survey jitter in an outline
	# would otherwise show as ragged roof edges and slivers at notches.
	var poly := simple(simplify(clean(raw), 0.6))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var mid := Vector2((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5)
	if bool(style.get("underground", false)):
		var w := clampf((hi.x - lo.x) * 0.25, 10.0, 24.0)
		var e := front_point(poly, mid.x, lo, hi)
		LandmarkStationKit.block(lm, "Walls", "Trim", "Windows", "Roof", e.x, e.z - 6.0, w, 12.0, 0.0,
			h, "flat", 0.0, 3.5, 4.0, true)
		return h
	var eave := float(style.get("eave", h))
	var top := _body(lm, poly, eave, style)
	# The front: where the outline's forecourt face crosses its middle.
	var front := front_point(poly, mid.x, lo, hi)
	var hall_w := 0.0
	if style.has("colonnade"):
		var n := int(style["colonnade"])
		var ch := float(style.get("col_h", eave * 0.7))
		var run := front_run(poly, front, lo, hi)
		var span := minf((run.y - run.x) - 4.0, float(n) * 4.5)
		var cx := (run.x + run.y) * 0.5
		if span >= 12.0:
			var c0 := Vector3(cx - span * 0.5, 0, front.z + 1.8)
			var c1 := Vector3(cx + span * 0.5, 0, front.z + 1.8)
			LandmarkFhUtil.columns(lm, "Trim", c0, c1, mini(n, int(span / 4.0) + 1), ch, 0.55)
			lm.box("Trim", Vector3(cx, ch + 0.5, front.z + 1.2), Vector3(span + 1.5, 1.0, 3.6))
	if style.has("centre_h"):
		# A raised centre block on the front (a pavilion or glass hall),
		# with its own roof (`centre_roof` "flat", "gable" or "mansard").
		var cw := float(style.get("centre_w", (hi.x - lo.x) * 0.25))
		var cd := clampf((front.z - lo.y) * 0.85, 8.0, 60.0)
		var ch := float(style["centre_h"])
		var cg := bool(style.get("centre_glass", false))
		var kind := str(style.get("centre_roof", "flat"))
		var rise := float(style.get("centre_rise", 0.0))
		var roof := {"gable": "gable_z", "mansard": "mansard"}.get(kind, "flat") as String
		# A blank centre (`centre_blank`) is a frieze wall with no window grid.
		var blank := bool(style.get("centre_blank", false))
		LandmarkStationKit.block(lm, "Curtain" if cg else "Walls", "Trim", "Curtain" if cg else ("Walls" if blank else "Windows"),
			"Roof",
			front.x, front.z + 0.5 - cd * 0.5, cw, cd, 0.0, ch, roof, rise, 3.6, 4.5, not cg)
		if cg:
			LandmarkFhParts.ribs(lm, "Steel", front + Vector3(-cw * 0.5, 0, 0.55), front + Vector3(cw * 0.5, 0, 0.55),
				Vector3.BACK, 0.0, ch, 3.0, 0.25, 0.25)
		top = maxf(top, ch + (rise if roof != "flat" else 0.0))
		hall_w = maxf(hall_w, cw)
		if blank:
			lm.box("Trim", Vector3(front.x, ch - 2.2, front.z + 0.7), Vector3(cw - 2.0, 1.4, 0.3))
	if style.has("pavilions"):
		# Taller pavilions at both ends of the front, with arched windows.
		var pv: Array = style["pavilions"]
		var pw := float(pv[0])
		var ph := float(pv[1])
		var run := front_run(poly, front, lo, hi)
		for x in [run.x + pw * 0.5, run.y - pw * 0.5]:
			var f := front_point(poly, float(x), lo, hi)
			LandmarkStationKit.block(lm, "Walls", "Trim", "Windows", "Roof", f.x, f.z - pw * 0.5 + 1.0, pw, pw, 0.0, ph,
				"flat", 0.0, 3.6, 5.0, true)
		top = maxf(top, ph)
	if style.has("arcade"):
		# A row of great glazed arches across the middle of the front.
		var ar: Array = style["arcade"]
		var n := int(ar[0])
		var aw := float(ar[1])
		var ah := minf(float(ar[2]), eave - 1.0)
		var span := float(n) * (aw + 1.6)
		LandmarkStationKit.arch_row(lm, "Trim", "Curtain" if style.has("glass_hex") else "Windows",
			front + Vector3(-span * 0.5, 0, 0.1), front + Vector3(span * 0.5, 0, 0.1), Vector3.BACK, 0.3, n, aw, ah, 3)
	if style.has("cantilever"):
		# A ribbed concrete canopy cantilevered over the forecourt, rising
		# from the eaves as it reaches out (Ouagadougou).
		var cv: Array = style["cantilever"]
		var depth := float(cv[0])
		var lift := float(cv[1])
		var run := front_run(poly, front, lo, hi)
		# Over the middle of the front only: a canopy reaching an end wall
		# would hang past it wherever that wall steps back.
		var inset := (run.y - run.x) * 0.15 + 3.0
		var x0 := run.x + inset
		var x1 := run.y - inset
		var a := Vector3(x0, eave, front.z)
		var b := Vector3(x1, eave, front.z)
		var c := Vector3(x1, eave + lift, front.z + depth)
		var dd := Vector3(x0, eave + lift, front.z + depth)
		var up := (b - a).cross(dd - a).normalized()
		if up.y < 0.0:
			up = -up
		lm.quad("Roof", a, b, c, dd, up)
		lm.quad("Roof", b, a, dd, c, -up)
		var ribs := maxi(int((x1 - x0) / 4.0), 2)
		for k in ribs + 1:
			var x := x0 + (x1 - x0) * float(k) / float(ribs)
			lm.beam("Roof", Vector3(x, eave - 0.6, front.z), Vector3(x, eave + lift - 0.6, front.z + depth), 0.5, 1.1)
		lm.box("Roof", Vector3((x0 + x1) * 0.5, eave + lift - 0.4, front.z + depth), Vector3(x1 - x0, 1.2, 0.5))
		top = maxf(top, eave + lift + 0.2)
	if style.has("shell_canopy"):
		# A cantilevered concrete shell over the forecourt (Ouagadougou): a
		# deep slab flush with the roof `depth` out from the front, ribs under
		# it curving down `rise` to the facade, an inclined leg at each end.
		var sc: Array = style["shell_canopy"]
		var depth := float(sc[0])
		var rise := float(sc[1])
		var run := front_run(poly, front, lo, hi)
		var inset := 2.0
		var x0 := run.x + inset
		var x1 := run.y - inset
		var under := eave - 1.5
		lm.box("Shell", Vector3((x0 + x1) * 0.5, eave - 0.75, front.z + depth * 0.5), Vector3(x1 - x0, 1.5, depth))
		# The outer fascia hangs a little below the slab.
		lm.box("Shell", Vector3((x0 + x1) * 0.5, under - 0.5, front.z + depth - 0.4), Vector3(x1 - x0, 1.0, 0.8))
		var ribs := maxi(int((x1 - x0) / 4.0), 2)
		var seg := 6
		for r in ribs + 1:
			var x := x0 + (x1 - x0) * float(r) / float(ribs)
			for k in seg:
				var t0 := float(k) / float(seg)
				var t1 := float(k + 1) / float(seg)
				lm.beam("Shell", Vector3(x, under - rise * cos(t0 * PI * 0.5) + 0.3, front.z + t0 * depth),
					Vector3(x, under - rise * cos(t1 * PI * 0.5) + 0.3, front.z + t1 * depth), 0.6, 1.2)
		for x in [x0, x1]:
			var out := -1.0 if x == x0 else 1.0
			lm.beam("Shell", Vector3(x, eave - 0.75, front.z + depth - 0.6),
				Vector3(x + out * eave * 0.45, 0.0, front.z + depth * 0.4), 1.6, 1.6, Vector3.ZERO, true)
		top = maxf(top, eave)
	if style.has("portal"):
		# A framed central portal: stone piers and lintel round a full-height
		# glazed or arched opening, a deep flat canopy over its foot.
		var pt: Array = style["portal"]
		var pw := float(pt[0])
		var ph := float(pt[1])
		var arched := pt.size() > 2 and bool(pt[2])
		var massive := pt.size() > 3 and bool(pt[3])
		# The frame stands 2 m proud of the facade and the glazing 1 m: in the
		# wall's own plane it would flicker into it.
		var f := front + Vector3(0, 0, 2.0)
		for s in [-1.0, 1.0]:
			lm.box("Trim", f + Vector3(s * (pw * 0.5 + 1.0), ph * 0.5, 0.0), Vector3(2.0, ph, 2.0))
		lm.box("Trim", f + Vector3(0, ph - 1.0, 0.0), Vector3(pw + 4.0, 2.0, 2.0))
		if arched:
			LandmarkStationKit.arch_window(lm, "Trim", "Curtain", f + Vector3(0, 0.2, -1.0), Vector3.BACK, pw, ph - 2.4, 5, 0.6)
		else:
			var gh := ph * 0.62 if massive else ph - 2.0
			lm.box("Curtain", f + Vector3(0, gh * 0.5, -1.0), Vector3(pw, gh, 0.2), Basis(), 0.0)
			LandmarkFhParts.ribs(lm, "Steel", f + Vector3(-pw * 0.5, 0, -0.85), f + Vector3(pw * 0.5, 0, -0.85), Vector3.BACK,
				0.0, gh, 2.0, 0.15, 0.15)
		if massive:
			# A clad entrance block (Abuja): broad piers and a deep head over
			# the glazing, rising above the wings, its soffit over the doors.
			var head := ph * 0.62
			for s in [-1.0, 1.0]:
				lm.box("Trim", f + Vector3(s * (pw * 0.5 + 2.5), ph * 0.5, 1.0), Vector3(5.0, ph, 6.0))
			lm.box("Trim", f + Vector3(0, (head + ph) * 0.5, 1.0), Vector3(pw + 10.0, ph - head, 6.0))
		else:
			lm.box("Roof", f + Vector3(0, minf(6.0, ph * 0.4), 3.0), Vector3(pw + 2.0, 0.6, 6.0))
		top = maxf(top, ph)
	if bool(style.get("screens", false)):
		# Sun-screen fins across the upper front over a dark recessed ground
		# floor (Tunis).
		var run2 := front_run(poly, front, lo, hi)
		var fz := front.z + 0.35
		lm.box("Windows", Vector3((run2.x + run2.y) * 0.5, 2.0, fz - 0.3), Vector3(run2.y - run2.x - 2.0, 4.0, 0.1), Basis(), 0.0)
		var nf := maxi(int((run2.y - run2.x) / 1.2), 4)
		for k in nf:
			var x := run2.x + 1.0 + (run2.y - run2.x - 2.0) * (float(k) + 0.5) / float(nf)
			lm.box("Louvre", Vector3(x, (4.6 + eave - 0.6) * 0.5, fz + 0.3), Vector3(0.18, eave - 5.2, 0.9))
	if style.has("floor_band_hex"):
		# A coloured band between the floors and glass-block panels on the
		# front (San José).
		lm.poly_prism("FloorBand", Geometry2D.offset_polygon(poly, 0.12)[0] as PackedVector2Array,
			float(style.get("storey", STOREY_M)) + 0.6, float(style.get("storey", STOREY_M)) + 1.4, false)
		var run3 := front_run(poly, front, lo, hi)
		for k in 3:
			var x := run3.x + (run3.y - run3.x) * (0.25 + 0.25 * float(k))
			lm.box("Blocks", Vector3(x, eave * 0.5, front.z + 0.12), Vector3(4.0, eave * 0.6, 0.1), Basis(), 0.0)
	if bool(style.get("front_clock", false)):
		# One clock over the middle of the front, under the eaves.
		LandmarkStationKit.clock(lm, "Dial", "Trim", front + Vector3(0, eave - 2.2, 0.4), Vector3.BACK, 1.3)
	if bool(style.get("hall", false)):
		var ht := float(style.get("hall_top", eave + 8.0))
		top = maxf(top, _hall(lm, front, lo, hi, eave, ht, not style.has("hall_belfry")))
		if style.has("hall_belfry"):
			# The hall's front closed by a round-topped masonry gable that
			# frames the clock, a belfry on its crown.
			var hl := clampf((hi.x - lo.x) * 0.3, 12.0, 46.0)
			var rise := clampf(hl * 0.3, 2.0, maxf(ht - eave - 1.0, 2.0))
			var g := front + Vector3(0, 0, 0.75)
			LandmarkStationKit.lunette(lm, "Trim", "Walls", g + Vector3(0, ht - rise, 0), Vector3.BACK, hl, rise * 0.98, 12, 0)
			LandmarkStationKit.clock(lm, "Dial", "Trim", g + Vector3(0, ht - rise * 0.55, 0.3), Vector3.BACK,
				clampf(rise * 0.28, 1.0, 2.4))
			var bh := float(style["hall_belfry"])
			_cap(lm, "belfry", g + Vector3(0, ht - 0.2, -1.5), 3.2, bh + 0.2)
			top = maxf(top, ht + bh)
		hall_w = maxf(hall_w, clampf((hi.x - lo.x) * 0.3, 12.0, 46.0))
	if style.has("dome"):
		var r := float(style.get("dome_r", 8.0))
		var tip := float(style.get("dome_top", eave + r * 1.6))
		var c := _inside(poly, Vector3(mid.x, 0, mid.y))
		var drum := maxf(tip - r * 0.9 - 1.2, eave)
		lm.lathe("Walls", c + Vector3.UP * (eave - 0.5), PackedVector2Array([Vector2(r, 0.0), Vector2(r, drum - eave + 0.5)]),
			20)
		lm.lathe("Cap" if style.has("cap_hex") else "Roof", c + Vector3.UP * drum, LandmarkFhUtil.dome_prof(r * 1.04, tip - drum - 1.2), 20)
		lm.frustum("Gilt", c + Vector3.UP * (tip - 1.2), 0.25, 0.05, 1.2, 6)
		top = maxf(top, tip)
	if style.has("tower"):
		top = maxf(top, _towers(lm, poly, style, lo, hi, mid, eave, hall_w))
	match str(style.get("shells", "")):
		"umbrella":
			top = maxf(top, _umbrellas(lm, poly, lo, hi, float(style.get("shell_top", eave + 6.0))))
		"folded":
			top = maxf(top, _folded(lm, lo, hi, float(style.get("shell_top", eave + 4.0))))
	if bool(style.get("canopy", true)) and eave >= 5.0 and not style.has("colonnade") and not style.has("portal") \
			and not style.has("shell_canopy"):
		var cw := minf((hi.x - lo.x) * 0.4, 40.0)
		LandmarkStationKit.canopy(lm, "Steel", "Steel", front + Vector3(-cw * 0.5, 0, 0.3),
			front + Vector3(cw * 0.5, 0, 0.3), Vector3.BACK, 4.0, minf(4.6, eave - 0.5), 4)
	return top

## The clock towers the style asks for, standing proud of the forecourt
## face so their shafts read on the facade; returns the tip.
static func _towers(lm: LandmarkMesh, poly: PackedVector2Array, style: Dictionary, lo: Vector2, hi: Vector2, mid: Vector2,
		eave: float, hall_w: float) -> float:
	var tw := float(style.get("tower_w", clampf(minf(hi.x - lo.x, hi.y - lo.y) * 0.22, 6.0, 12.0)))
	var tip := float(style.get("tower_h", eave + 15.0))
	var cap := str(style.get("tower_cap", "pavilion"))
	var cap_h := clampf((tip - eave) * 0.3, 3.0, 22.0)
	var xs: Array = []
	match str(style["tower"]):
		"centre": xs = [mid.x]
		# Beside the hall or centre block when there is one, else at the end.
		"side": xs = [mid.x + hall_w * 0.5 + tw * 0.5 + 1.0] if hall_w > 0.0 else [hi.x - tw * 0.5 - 2.0]
		"twin":
			var off := maxf(hall_w * 0.5 + tw * 0.5 + 1.0, (hi.x - lo.x) * 0.2)
			xs = [mid.x - off, mid.x + off]
		"ends": xs = [lo.x + tw * 0.5 + 1.0, hi.x - tw * 0.5 - 1.0]
	# The tower roof in its own colour when the style names one (`cap_hex`).
	var rk := "Cap" if style.has("cap_hex") else "Roof"
	for x in xs:
		var f := front_point(poly, float(x), lo, hi)
		var base := f + Vector3(0, 0, tw * 0.5 - 0.6)
		match cap:
			"star", "dome_spire", "belvedere", "belfry":
				var shaft := tip - cap_h * (2.0 if cap == "star" or cap == "dome_spire" else 1.0)
				LandmarkStationKit.clock_tower(lm, "Walls", "Trim", rk, "Dial", "Windows", base, tw, shaft, "flat", 0.3)
				_cap(lm, cap, base + Vector3.UP * shaft, tw, tip - shaft)
			_:
				LandmarkStationKit.clock_tower(lm, "Walls", "Trim", rk, "Dial", "Windows", base, tw, tip - cap_h, cap,
					cap_h)
	return tip

## The landmark tower tops, `h` tall on the shaft top `at`: "star" a
## needle with its star (Yerevan), "dome_spire" a dome under a gilt needle
## (Ashgabat), "belvedere" a tiered open lantern of columns under a small
## roof (Pyongyang), "belfry" an arched open belfry under a cupola (Havana).
static func _cap(lm: LandmarkMesh, cap: String, at: Vector3, tw: float, h: float) -> void:
	match cap:
		"star":
			_belvedere(lm, at, tw * 0.7, h * 0.3)
			lm.spire("Roof", at + Vector3.UP * h * 0.3, tw * 0.18, h * 0.7 - 1.4)
			lm.box("Gilt", at + Vector3.UP * (h - 0.7), Vector3(1.4, 1.4, 0.3))
		"dome_spire":
			lm.lathe("Walls", at, PackedVector2Array([Vector2(tw * 0.45, 0.0), Vector2(tw * 0.45, h * 0.12)]), 16)
			lm.lathe("Roof", at + Vector3.UP * h * 0.12, LandmarkFhUtil.dome_prof(tw * 0.5, h * 0.2), 16)
			lm.frustum("Gilt", at + Vector3.UP * h * 0.32, tw * 0.08, 0.03, h * 0.68, 8)
		"belvedere":
			_belvedere(lm, at, tw * 0.85, h * 0.4)
			lm.box("Walls", at + Vector3.UP * (h * 0.4 + h * 0.08), Vector3(tw * 0.62, h * 0.16, tw * 0.62))
			_belvedere(lm, at + Vector3.UP * h * 0.56, tw * 0.55, h * 0.24)
			LandmarkFhUtil.hip(lm, "Roof", at + Vector3.UP * h * 0.8, tw * 0.62, tw * 0.62, h * 0.2, 0.0)
		"belfry":
			_belvedere(lm, at, tw * 0.9, h * 0.55)
			lm.lathe("Roof", at + Vector3.UP * h * 0.55, LandmarkFhUtil.dome_prof(tw * 0.42, h * 0.35), 12)
			lm.frustum("Trim", at + Vector3.UP * h * 0.9, 0.2, 0.05, h * 0.1, 6)

## An open stage of eight columns round a `w`-wide platform, `h` tall,
## with its cornice.
static func _belvedere(lm: LandmarkMesh, at: Vector3, w: float, h: float) -> void:
	lm.box("Trim", at + Vector3.UP * 0.2, Vector3(w, 0.4, w))
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Walls", at + Vector3(cos(a), 0, sin(a)) * w * 0.42, w * 0.05, w * 0.045, h - 0.6, 6)
	lm.box("Trim", at + Vector3.UP * (h - 0.3), Vector3(w + 0.4, 0.6, w + 0.4))

## The point on the outline's forecourt face at `x`: scanning from the
## front of the bounds back until the outline is reached.
static func front_point(poly: PackedVector2Array, x: float, lo: Vector2, hi: Vector2) -> Vector3:
	var z := hi.y
	while z > lo.y:
		if Geometry2D.is_point_in_polygon(Vector2(x, z - 0.5), poly):
			return Vector3(x, 0, z)
		z -= 1.0
	var c := _inside(poly, Vector3(x, 0, hi.y))
	return Vector3(c.x, 0, c.z)

## The outline as a walled block to `eave` with its roof; returns the top.
## The walls are left open on top so no cap lies coplanar with the roof.
static func _body(lm: LandmarkMesh, poly: PackedVector2Array, eave: float, style: Dictionary) -> float:
	var glass := bool(style.get("glass", false))
	var storey := float(style.get("storey", STOREY_M))
	lm.poly_prism("Curtain" if glass else "Walls", poly, 0.0, eave, false)
	var rings := Geometry2D.offset_polygon(poly, 0.3, Geometry2D.JOIN_ROUND)
	var ring: PackedVector2Array = rings[0] if not rings.is_empty() else poly
	lm.poly_prism("Trim", ring, 0.0, 0.8, false)
	if glass:
		var y := storey
		while y < eave - 1.0:
			lm.poly_prism("Steel", ring, y - 0.25, y + 0.25, false)
			y += storey
	else:
		_windows(lm, poly, eave, storey, str(style.get("windows", "arched")) == "rect")
	if style.has("louvre_hex"):
		# Horizontal louvre bands across the upper floors (Tunis).
		var y2 := storey * 1.6
		while y2 < eave - 0.8:
			lm.poly_prism("Louvre", ring, y2 - 0.6, y2 + 0.6, false)
			y2 += storey * 0.5
	if style.has("band_hex"):
		# A cladding band round the upper facade (Belgrade's copper).
		lm.poly_prism("Band", ring, eave - float(style.get("band_h", 6.0)), eave - 0.05, false)
	# The cornice band under the eaves; the roof covers its top.
	lm.poly_prism("Trim", ring, eave - 0.9, eave - 0.05, false)
	var top := eave
	match str(style.get("roof", "flat")):
		"hip":
			var rise := float(style.get("roof_rise", 5.0))
			_hip(lm, ring, eave, rise)
			top = eave + rise
		"gable":
			# A long pitched roof, its ridge along the building (a corrugated
			# roof); only on a near-rectangular plan, else a hip.
			var rise := float(style.get("roof_rise", 3.0))
			var rect := simplify(ring, 1.5)
			if not (rect.size() <= 6 and _convex(rect)):
				_hip(lm, ring, eave, rise)
				return eave + rise
			flat_cap(lm, "Roof", ring, eave)
			var glo := Vector2(INF, INF)
			var ghi := Vector2(-INF, -INF)
			for q in ring:
				glo = glo.min(q)
				ghi = ghi.max(q)
			LandmarkFhUtil.ridge_x(lm, "Roof", "Walls", Vector3((glo.x + ghi.x) * 0.5, eave + 0.02, (glo.y + ghi.y) * 0.5),
				ghi.x - glo.x, ghi.y - glo.y, rise - 0.02, 0.6)
			top = eave + rise
		"overhang":
			var over := float(style.get("overhang", 4.0))
			# One slab over the main outline: smaller offset pieces would
			# overlap it and show as slits.
			# Grown past its inlets then shrunk back: the slab closes over
			# narrow slots in the outline instead of showing them as grooves.
			var pieces: Array = []
			for grown in Geometry2D.offset_polygon(simplify(poly, 1.5), over + 4.0, Geometry2D.JOIN_MITER):
				pieces.append_array(Geometry2D.offset_polygon(grown as PackedVector2Array, -4.0, Geometry2D.JOIN_MITER))
			var slab: PackedVector2Array = ring
			for pc in pieces:
				if absf(RingGeometry.signed_area(pc as PackedVector2Array)) > absf(RingGeometry.signed_area(slab)):
					slab = pc as PackedVector2Array
			lm.poly_prism("Roof", slab, eave, eave + 1.0, false)
			flat_cap(lm, "Roof", slab, eave + 1.0)
			top = eave + 1.0
		_:
			# The flat roof covers the cornice band to its outer edge.
			flat_cap(lm, "Roof", ring, eave)
	return top

## A hipped roof over any outline. The eaves ledge covers the cornice
## band. A convex outline (most station blocks) gets a true hip, its
## skirts mitred at the corners and sloping to an inset ridge cap. A
## complex wing plan gets a mansard read as an attic: the outline's true
## inset rises with vertical roof-coloured walls to a flat top, so wing
## junctions have no sloped pieces to tilt, cross or poke out.
static func _hip(lm: LandmarkMesh, detailed: PackedVector2Array, eave: float, rise: float) -> void:
	flat_cap(lm, "Roof", detailed, eave)
	# The roof follows the outline without its small jogs (pilasters,
	# recesses under 1.5 m).
	var ring := simplify(detailed, 1.5)
	var shortest := INF
	for i in ring.size():
		shortest = minf(shortest, ring[i].distance_to(ring[(i + 1) % ring.size()]))
	if ring.size() <= 8 and _convex(ring):
		var cen := LandmarkFhParts.centre(ring)
		var d := rise * 1.3
		for i in ring.size():
			d = minf(d, Geometry2D.get_closest_point_to_segment(cen, ring[i], ring[(i + 1) % ring.size()]).distance_to(cen)
				* 0.85)
		_skirts(lm, ring, eave + 0.02, rise - 0.02, clampf(minf(d, shortest * 0.45), 0.3, 1e9))
		return
	for inset in Geometry2D.offset_polygon(ring, -minf(1.6, rise * 0.4)):
		var attic := clean(inset as PackedVector2Array)
		lm.poly_prism("Roof", attic, eave, eave + rise, false)
		flat_cap(lm, "Roof", attic, eave + rise)

## A closed outline simplified (Douglas-Peucker) to within `tol` metres,
## starting from its two farthest-apart points so neither half collapses.
static func simplify(poly: PackedVector2Array, tol: float) -> PackedVector2Array:
	var n := poly.size()
	if n <= 4:
		return poly
	var far := 0
	for i in n:
		if poly[0].distance_to(poly[i]) > poly[0].distance_to(poly[far]):
			far = i
	var a := poly.slice(0, far + 1)
	var b := poly.slice(far)
	b.append(poly[0])
	var out := _dp(a, tol)
	out.remove_at(out.size() - 1)
	var tail := _dp(b, tol)
	tail.remove_at(tail.size() - 1)
	out.append_array(tail)
	return out if out.size() >= 3 else poly

static func _dp(pts: PackedVector2Array, tol: float) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var a := pts[0]
	var b := pts[pts.size() - 1]
	var idx := 0
	var far := 0.0
	for i in range(1, pts.size() - 1):
		var d := Geometry2D.get_closest_point_to_segment(pts[i], a, b).distance_to(pts[i])
		if d > far:
			far = d
			idx = i
	if far <= tol:
		return PackedVector2Array([a, b])
	var left := _dp(pts.slice(0, idx + 1), tol)
	left.remove_at(left.size() - 1)
	left.append_array(_dp(pts.slice(idx), tol))
	return left

## True when `poly` turns the same way at every corner.
static func _convex(poly: PackedVector2Array) -> bool:
	var sign := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var c := poly[(i + 2) % poly.size()]
		var z := (b - a).cross(c - b)
		if absf(z) < 1e-4:
			continue
		if sign == 0.0:
			sign = signf(z)
		elif signf(z) != sign:
			return false
	return true

## The x range of the straight front face through `front`: the outline
## crossed just behind it, scanned left and right of its x.
static func front_run(poly: PackedVector2Array, front: Vector3, lo: Vector2, hi: Vector2) -> Vector2:
	var z := front.z - 0.6
	var x0 := front.x
	while x0 - 1.0 > lo.x and Geometry2D.is_point_in_polygon(Vector2(x0 - 1.0, z), poly) \
			and not Geometry2D.is_point_in_polygon(Vector2(x0 - 1.0, z + 1.2), poly):
		x0 -= 1.0
	var x1 := front.x
	while x1 + 1.0 < hi.x and Geometry2D.is_point_in_polygon(Vector2(x1 + 1.0, z), poly) \
			and not Geometry2D.is_point_in_polygon(Vector2(x1 + 1.0, z + 1.2), poly):
		x1 += 1.0
	return Vector2(x0, x1)

## Storeys of windows on every wall (outward normals from the winding, so
## a concave outline keeps them on every face), round-headed openings on
## the forecourt's ground floor.
static func _windows(lm: LandmarkMesh, poly: PackedVector2Array, eave: float, storey: float, rect: bool = false) -> void:
	var rows := maxi(int((eave - 1.5) / storey), 1)
	var wind := 1.0 if RingGeometry.signed_area(poly) > 0.0 else -1.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var run := a.distance_to(b)
		if run < 5.0:
			continue
		var d := (b - a) / run
		var out := Vector3(d.y, 0, -d.x) * wind
		var p0 := Vector3(a.x, 0, a.y) + out * 0.02
		var p1 := Vector3(b.x, 0, b.y) + out * 0.02
		var n := maxi(int(run / 4.2), 1)
		if out.z > 0.7 and eave >= 7.0 and not rect:
			LandmarkStationKit.arch_row(lm, "Trim", "Windows", p0, p1, out, 0.8, n, 2.4, minf(storey, eave * 0.45), 1)
			LandmarkFhUtil.window_grid(lm, "Windows", p0, p1, out, storey + 1.7, maxi(rows - 1, 0), storey, n, 1.6,
				storey * 0.53)
		else:
			LandmarkFhUtil.window_grid(lm, "Windows", p0, p1, out, 1.4, rows, storey, n, 1.6, storey * 0.53)

## The arched booking hall standing on the forecourt face at `front`, its
## glazed arched end forming the front, `tip` to its crown; returns the tip.
static func _hall(lm: LandmarkMesh, front: Vector3, lo: Vector2, hi: Vector2, eave: float, tip: float,
		with_clock: bool = true) -> float:
	var hl := clampf((hi.x - lo.x) * 0.3, 12.0, 46.0)
	var hd := clampf((front.z - lo.y) * 0.8, 10.0, 60.0)
	var hc := front + Vector3(0, 0, 0.6 - hd * 0.5)
	var rise := clampf(hl * 0.3, 2.0, maxf(tip - eave - 1.0, 2.0))
	var hall_eave := tip - rise
	lm.box("Walls", hc + Vector3.UP * hall_eave * 0.5, Vector3(hl, hall_eave, hd))
	lm.box("Trim", hc + Vector3.UP * (hall_eave - 0.4), Vector3(hl + 0.8, 0.7, hd + 0.8))
	_vault(lm, hc + Vector3(0, hall_eave, -hd * 0.5), hc + Vector3(0, hall_eave, hd * 0.5), hl * 0.5 + 0.3, rise)
	var f := hc + Vector3(0, 0, hd * 0.5)
	var aw := hl * 0.62
	var ah := minf(hall_eave * 0.82, aw * 1.15)
	LandmarkStationKit.arch_window(lm, "Trim", "Windows", f + Vector3(0, 0.6, 0.02), Vector3.BACK, aw, ah,
		maxi(int(aw / 2.5), 3), 0.7)
	LandmarkStationKit.lunette(lm, "Trim", "Windows", f + Vector3(0, hall_eave, 0.05), Vector3.BACK, hl, rise * 0.96, 12, 5)
	if with_clock:
		var r := clampf(hl * 0.09, 1.0, 2.6)
		LandmarkStationKit.clock(lm, "Dial", "Trim", f + Vector3(0, minf(0.6 + ah + r * 1.6, hall_eave + rise * 0.45), 0.35),
			Vector3.BACK, r)
	return tip

## A field of umbrella shells (inverted hypar umbrellas on single stems)
## over the outline, crowns `tip` high (Kamalapur, Dhaka).
static func _umbrellas(lm: LandmarkMesh, poly: PackedVector2Array, lo: Vector2, hi: Vector2, tip: float) -> float:
	var size := 24.0
	var nx := maxi(int((hi.x - lo.x) / size), 1)
	var nz := maxi(int((hi.y - lo.y) / size), 1)
	var sx := (hi.x - lo.x) / float(nx)
	var sz := (hi.y - lo.y) / float(nz)
	for i in nx:
		for j in nz:
			var c := Vector2(lo.x + sx * (float(i) + 0.5), lo.y + sz * (float(j) + 0.5))
			if not Geometry2D.is_point_in_polygon(c, poly):
				continue
			var stem := Vector3(c.x, 0, c.y)
			var low := tip - 3.0
			# Each shell: four warped quarters rising from the stem head to
			# raised edges, its crown line at `tip` on the edge midpoints.
			var corners := [Vector3(-sx, 0, -sz), Vector3(sx, 0, -sz), Vector3(sx, 0, sz), Vector3(-sx, 0, sz)]
			for k in 4:
				var a: Vector3 = corners[k] * 0.5
				var b: Vector3 = corners[(k + 1) % 4] * 0.5
				var m := (a + b) * 0.5
				var head := stem + Vector3.UP * low
				lm.tri("Roof", head, stem + a + Vector3.UP * (tip - 1.0), stem + m + Vector3.UP * tip,
					Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
				lm.tri("Roof", head, stem + m + Vector3.UP * tip, stem + b + Vector3.UP * (tip - 1.0),
					Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
				lm.tri("Roof", head, stem + m + Vector3.UP * tip, stem + a + Vector3.UP * (tip - 1.0),
					Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
				lm.tri("Roof", head, stem + b + Vector3.UP * (tip - 1.0), stem + m + Vector3.UP * tip,
					Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
			lm.frustum("Trim", stem, 0.7, 1.4, low, 10)
	return tip

## A folded-plate roof over the outline's bounds: ridges across the short
## side every 12 m, valleys 3 m lower, `tip` at the ridges (Hung Hom).
static func _folded(lm: LandmarkMesh, lo: Vector2, hi: Vector2, tip: float) -> float:
	var n := maxi(int((hi.x - lo.x) / 6.0), 2)
	var step := (hi.x - lo.x) / float(n)
	for i in n:
		var x0 := lo.x + step * float(i)
		var x1 := x0 + step
		var y0 := tip if i % 2 == 0 else tip - 3.0
		var y1 := tip - 3.0 if i % 2 == 0 else tip
		lm.quad("Roof", Vector3(x0, y0, lo.y), Vector3(x1, y1, lo.y), Vector3(x1, y1, hi.y), Vector3(x0, y0, hi.y), Vector3.UP)
		lm.quad("Roof", Vector3(x1, y1, lo.y), Vector3(x0, y0, lo.y), Vector3(x0, y0, hi.y), Vector3(x1, y1, hi.y), Vector3.DOWN)
		# Close the sawtooth ends down to the wall tops.
		for z in [lo.y, hi.y]:
			var nz := Vector3(0, 0, -1.0 if z == lo.y else 1.0)
			lm.quad("Roof", Vector3(x0, eave_of(tip), z), Vector3(x1, eave_of(tip), z), Vector3(x1, y1, z), Vector3(x0, y0, z), nz)
	for x in [lo.x, hi.x]:
		var y := tip if (x == lo.x) else (tip if n % 2 == 0 else tip - 3.0)
		var nx := Vector3(-1.0 if x == lo.x else 1.0, 0, 0)
		lm.quad("Roof", Vector3(x, eave_of(tip), lo.y), Vector3(x, eave_of(tip), hi.y), Vector3(x, y, hi.y), Vector3(x, y, lo.y), nx)
	return tip

## The wall top a folded roof `tip` high stands on (the archetype puts the
## valleys 3 m under the ridges and the walls below them).
static func eave_of(tip: float) -> float:
	return tip - 6.0

## `p` pulled toward the outline's middle until it stands inside it.
static func _inside(poly: PackedVector2Array, p: Vector3) -> Vector3:
	var c := LandmarkFhParts.centre(poly)
	var q := Vector2(p.x, p.z)
	for k in 10:
		if Geometry2D.is_point_in_polygon(q, poly):
			break
		q = q.lerp(c, 0.25)
	return Vector3(q.x, p.y, q.y)

## A plain barrel vault from `a` to `b` (half-span `r`, `rise` tall) with
## closed ends: no seam strips, which shimmer into rings at a distance.
static func _vault(lm: LandmarkMesh, a: Vector3, b: Vector3, r: float, rise: float) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var seg := 12
	for k in seg:
		var t0 := PI * float(k) / float(seg)
		var t1 := PI * float(k + 1) / float(seg)
		var o0 := side * cos(t0) * r + Vector3.UP * sin(t0) * rise
		var o1 := side * cos(t1) * r + Vector3.UP * sin(t1) * rise
		var n := (o0 + o1).normalized()
		lm.quad("Roof", a + o0, b + o0, b + o1, a + o1, n)
		lm.tri("Roof", a, a + o0, a + o1, -dir, -dir, -dir, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		lm.tri("Roof", b, b + o1, b + o0, dir, dir, dir, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))

## `poly` without repeated or near points (under 0.8 m) and without
## corners on a straight line, so triangulation and offsets of real OSM
## outlines stay well defined.
static func clean(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	# Points closer than 0.8 m merge: an outline's tiny jogs would each
	# get a steep sliver of roof skirt that shades dark at the ridge.
	for p in poly:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.8:
			out.append(p)
	if out.size() > 3 and out[0].distance_to(out[out.size() - 1]) <= 0.8:
		out.remove_at(out.size() - 1)
	var changed := true
	while changed and out.size() > 3:
		changed = false
		for i in out.size():
			var a := out[(i - 1 + out.size()) % out.size()]
			var b := out[i]
			var c := out[(i + 1) % out.size()]
			if absf((b - a).cross(c - b)) < 0.02 * (b - a).length() * (c - b).length() + 1e-6:
				out.remove_at(i)
				changed = true
				break
	return out if out.size() >= 3 else poly

## `poly` as a simple polygon: an outline whose cleaned points cross
## itself would turn some walls inside out (culled, so the roof would sit
## over nothing). A tiny grow-and-shrink untangles it.
static func simple(poly: PackedVector2Array) -> PackedVector2Array:
	var grown := Geometry2D.offset_polygon(poly, 0.05, Geometry2D.JOIN_MITER)
	if grown.is_empty():
		return poly
	var best: PackedVector2Array = grown[0]
	for g in grown:
		if absf(RingGeometry.signed_area(g as PackedVector2Array)) > absf(RingGeometry.signed_area(best)):
			best = g as PackedVector2Array
	var back := Geometry2D.offset_polygon(best, -0.05, Geometry2D.JOIN_MITER)
	return clean(back[0] as PackedVector2Array) if not back.is_empty() else poly

## A flat roof face over `poly` at `y`, facing up: triangulated, or built
## from the outline's convex pieces when the triangulation finds no answer.
static func flat_cap(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float) -> void:
	if poly.size() < 3:
		return
	var tris := Geometry2D.triangulate_polygon(poly)
	if not tris.is_empty():
		for t in range(0, tris.size(), 3):
			var a := poly[tris[t]]
			var b := poly[tris[t + 1]]
			var c := poly[tris[t + 2]]
			lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, Vector3.UP, Vector3.UP,
				a, b, c)
		return
	for piece in Geometry2D.decompose_polygon_in_convex(poly):
		var pc := piece as PackedVector2Array
		for i in range(1, pc.size() - 1):
			lm.tri(key, Vector3(pc[0].x, y, pc[0].y), Vector3(pc[i].x, y, pc[i].y), Vector3(pc[i + 1].x, y, pc[i + 1].y),
				Vector3.UP, Vector3.UP, Vector3.UP, pc[0], pc[i], pc[i + 1])

## The skirts of a roof over `ring`: every wall's skirt rises `h` while
## moving in `d`, its inner corners on the mitres of the inset edges, and
## the inner ring capped flat.
static func _skirts(lm: LandmarkMesh, ring: PackedVector2Array, eave: float, h: float, d: float) -> void:
	var n := ring.size()
	if n < 3:
		return
	var wind := 1.0 if RingGeometry.signed_area(ring) > 0.0 else -1.0
	var inner := PackedVector2Array()
	for i in n:
		var p := ring[i]
		var a := ring[(i - 1 + n) % n]
		var b := ring[(i + 1) % n]
		var e0 := (p - a).normalized()
		var e1 := (b - p).normalized()
		var n0 := Vector2(-e0.y, e0.x) * wind
		var n1 := Vector2(-e1.y, e1.x) * wind
		var q := p + (n0 + n1).normalized() * d
		if absf(e0.cross(e1)) > 0.05:
			var hit: Variant = Geometry2D.line_intersects_line(a + n0 * d, e0, p + n1 * d, e1)
			if hit != null and (hit as Vector2).distance_to(p) < d * 4.0:
				q = hit as Vector2
		inner.append(q)
	for i in n:
		var j := (i + 1) % n
		var e := (ring[j] - ring[i]).normalized()
		var out := Vector3(e.y, 0, -e.x) * wind
		lm.quad("Roof", Vector3(ring[i].x, eave, ring[i].y), Vector3(ring[j].x, eave, ring[j].y),
			Vector3(inner[j].x, eave + h, inner[j].y), Vector3(inner[i].x, eave + h, inner[i].y),
			(out * h + Vector3.UP * d).normalized())
	flat_cap(lm, "Roof", inner, eave + h)
