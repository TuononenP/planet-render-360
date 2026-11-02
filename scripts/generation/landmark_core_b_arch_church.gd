class_name LandmarkCoreBArchChurch
extends RefCounted

## Generic church and cathedral for LandmarkArchetypes, in true metres,
## long axis along local Z (west front at −Z, apse at +Z). Typology
## after the European parish church and the Gothic cathedral (Chartres,
## Cologne, Reims): a nave with lean-to aisles, stepped buttresses
## between window bays, traceried lancets in aisle and clerestory, a
## polygonal apse; the cathedral adds a transept with rose windows,
## pinnacled pier buttresses with flying buttresses to the clerestory,
## a twin-towered west front with three portals and a rose, and a
## crossing flèche. Tower tops follow the regional style (spire with
## lucarnes, baroque bell cap, onion, helm). Uses the keys Walls, Roof,
## Trim, Windows, Gilt registered by LandmarkArchetypes.

static func build(lm: LandmarkMesh, h: float, w: float, l: float, twin: bool, style: String) -> void:
	# Plan: nave + two aisles inside the footprint, buttresses included.
	var nw := clampf(w * 0.42, 7.0, 18.0 if twin else 14.0)
	var aw := nw * 0.5
	var bd := clampf(aw * 0.35, 0.8, 3.0)  # buttress depth
	var W := nw + aw * 2.0
	if W + bd * 2.0 > w * 0.98:
		var k := w * 0.98 / (W + bd * 2.0)
		nw *= k
		aw *= k
		bd *= k
		W = nw + aw * 2.0
	var L := minf(l * 0.98 - 3.0, W * (3.2 if twin else 3.0))
	var z0 := -L * 0.5 + 1.0
	var nave_rise := nw * 0.6
	var E := clampf(h * (0.36 if twin else 0.3), 7.0, 34.0)
	E = minf(E, h * 0.78 - nave_rise)
	E = maxf(E, 5.0)
	var aE := E * (0.5 if twin else 0.62)
	var tw := clampf(W * 0.3, 5.0, 13.0) if twin else clampf(nw * 0.95, 5.0, 14.0)
	var ar := nw * 0.5
	var zs := z0 + tw * (0.85 if not twin else 0.95)  # nave west end
	var za := L * 0.5 - ar  # apse centre
	var nl := za - zs
	var zc := (zs + za) * 0.5
	# Nave, aisles and their roofs.
	lm.box("Walls", Vector3(0, E * 0.5, zc), Vector3(nw, E, nl))
	lm.gable("Roof", Vector3(0, E, zc), nw, nl, nave_rise, Basis(), 0.5, "Walls")
	lm.box("Walls", Vector3(0, aE * 0.5, zc), Vector3(W, aE, nl))
	var lean_top := aE + (E - aE) * 0.3
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		lm.quad("Roof", Vector3(s * (W * 0.5 + 0.4), aE, zs), Vector3(s * (W * 0.5 + 0.4), aE, za),
			Vector3(s * nw * 0.5, lean_top, za), Vector3(s * nw * 0.5, lean_top, zs),
			Vector3(s * (lean_top - aE), aw, 0).normalized())
		# Eave courses: corbel tables under the nave and aisle eaves.
		lm.box("Trim", Vector3(s * (nw * 0.5 + 0.15), E - 0.25, zc), Vector3(0.5, 0.5, nl))
		lm.box("Trim", Vector3(s * (W * 0.5 + 0.15), aE - 0.25, zc), Vector3(0.5, 0.5, nl))
		lm.box("Trim", Vector3(s * (W * 0.5 + 0.12), 0.5, zc), Vector3(0.4, 1.0, nl))
	# Transept (cathedral) across the eastern third.
	var zt := zs + nl * 0.66
	var tl := minf(w * 0.98 - 3.0, W + nw * 1.4) if twin else 0.0
	var bay := clampf(E * (0.6 if twin else 0.42), 4.5, 10.0)
	var nb := maxi(3, int(nl / bay))
	bay = nl / float(nb)
	for k in nb + 1:
		var z := zs + bay * float(k)
		var in_tr := twin and absf(z - zt) < nw * 0.5 + 0.5
		for sx in [-1.0, 1.0]:
			var s := float(sx)
			var n := Vector3(s, 0, 0)
			if k < nb:
				var zm := z + bay * 0.5
				if not (twin and absf(zm - zt) < nw * 0.5 + bay * 0.3):
					LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", Vector3(s * W * 0.5, aE * 0.18, zm), n,
						bay * 0.42, aE * 0.62, 0.3, false)
				var cl_y := lean_top + 0.4
				var cl_h := E - cl_y - 1.0
				if cl_h > 1.5 and not (twin and absf(zm - zt) < nw * 0.5 + bay * 0.3):
					LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", Vector3(s * nw * 0.5, cl_y, zm), n,
						minf(bay * 0.45, cl_h * 0.6), cl_h, 0.25, twin)
			if in_tr:
				continue
			if twin:
				# Pier buttress with pinnacle, flying buttress to the clerestory.
				var pier_h := aE + (E - aE) * 0.45
				var foot := Vector3(s * W * 0.5, 0, z)
				LandmarkCoreBArchKit.buttress(lm, "Walls", foot, n, bay * 0.16, bd, pier_h)
				LandmarkCoreBArchKit.pinnacle(lm, "Trim", foot + n * bd * 0.45 + Vector3.UP * pier_h, bd * 0.3, E * 0.22)
				var p0 := Vector3(s * (W * 0.5 + bd * 0.2), pier_h * 0.95, z)
				var p1 := Vector3(s * nw * 0.5, E * 0.86, z)
				var prev := p0
				for i in range(1, 4):
					var t := float(i) / 3.0
					var p := p0.lerp(p1, t) + Vector3.UP * sin(PI * t) * -(E - aE) * 0.12
					lm.beam("Walls", prev, p, bay * 0.1, maxf(bay * 0.12, 0.5), Vector3(0, 0, 1))
					prev = p
				lm.beam("Walls", p0 + Vector3.UP * 1.2, p1 + Vector3.UP * 0.8, bay * 0.08, 0.5, Vector3(0, 0, 1))
			else:
				LandmarkCoreBArchKit.buttress(lm, "Walls", Vector3(s * W * 0.5, 0, z), n, bay * 0.14, bd, aE * 1.02)
	if twin:
		_transept(lm, zt, nw, tl, E, nave_rise, aE)
	# Polygonal apse with its own buttresses and lancets.
	lm.lathe("Walls", Vector3(0, 0, za), PackedVector2Array([Vector2(ar, 0), Vector2(ar, E)]), 8,
		1.0, 1.0, PI / 8.0, false)
	lm.lathe("Roof", Vector3(0, E, za), PackedVector2Array([Vector2(ar * 1.06, 0), Vector2(0.0, nave_rise)]),
		8, 1.0, 1.0, PI / 8.0, false)
	for i in 5:
		var a := -PI * 0.5 + PI * float(i) / 4.0
		var d := Vector3(sin(a), 0, cos(a))
		var ap := ar * cos(PI / 8.0)
		var fa := a + PI / 8.0
		var fd := Vector3(sin(fa), 0, cos(fa))
		if i < 4:
			LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", Vector3(0, E * 0.22, za) + fd * ap, fd, minf(ar * 0.35, 3.0),
				E * 0.6, 0.25, twin)
		LandmarkCoreBArchKit.buttress(lm, "Walls", Vector3(0, 0, za) + d * ar, d, bay * 0.14, bd * 0.8, E * 0.9)
	# West end and towers.
	var tz := z0 + tw * 0.5
	if twin:
		var xs := W * 0.5 - tw * 0.5
		for sx in [-1.0, 1.0]:
			_tower(lm, Vector3(float(sx) * xs, 0, tz), tw, h, style)
		var fw := W - tw * 2.0
		lm.box("Walls", Vector3(0, E * 0.5, tz), Vector3(fw, E, tw))
		lm.gable("Walls", Vector3(0, E, tz), fw, tw, nave_rise * 0.9, Basis(), 0.0, "Walls")
		var face := z0
		_portal(lm, Vector3(0, 0, face), fw * 0.42, E * 0.42)
		for sx in [-1.0, 1.0]:
			_portal(lm, Vector3(float(sx) * xs, 0, face), tw * 0.36, E * 0.32)
		LandmarkCoreBArchKit.rose(lm, "Trim", "Windows", Vector3(0, E * 0.66, face - 0.05), Vector3(0, 0, -1),
			minf(fw * 0.32, E * 0.2))
		# Gallery of arcading across the front under the rose.
		var ga := maxi(int(fw / 1.6), 4)
		for i in ga:
			var x := -fw * 0.5 + fw * (float(i) + 0.5) / float(ga)
			lm.box("Trim", Vector3(x, E * 0.47, face - 0.3), Vector3(0.3, E * 0.06, 0.3))
		lm.box("Trim", Vector3(0, E * 0.5 + 0.2, face - 0.35), Vector3(fw, 0.4, 0.7))
		lm.box("Trim", Vector3(0, E * 0.44, face - 0.35), Vector3(fw, 0.4, 0.7))
		# Crossing flèche over the transept.
		_fleche(lm, Vector3(0, E + nave_rise * 0.9, zt), nw * 0.16, minf(h * 0.82, h - 2.0) - E - nave_rise * 0.9,
			style)
	else:
		_tower(lm, Vector3(0, 0, tz), tw, h, style)
		_portal(lm, Vector3(0, 0, z0), tw * 0.42, minf(E * 0.5, tw * 1.1))
		if style == "onion":
			var oc := Vector3(0, E + nave_rise * 0.9, zc)
			var os := minf(nw, (h * 0.92 - oc.y) / 1.08)
			if os > 1.0:
				lm.frustum("Walls", oc, os * 0.2, os * 0.2, os * 0.35, 8, PI / 8.0)
				lm.lathe("Gilt", oc + Vector3.UP * os * 0.35, LandmarkCoreBArchKit.onion(os * 0.24, os * 0.6), 16)
				LandmarkCoreBArchKit.cross(lm, "Gilt", oc + Vector3.UP * os * 0.88, os * 0.2)
	LandmarkCoreBArchKit.cross(lm, "Trim", Vector3(0, E + nave_rise, za), minf(nave_rise * 0.3, 2.0))

## Cathedral transept: arms across the crossing under a gable roof,
## end façades with a rose window, portal and corner buttresses.
static func _transept(lm: LandmarkMesh, zt: float, nw: float, tl: float, E: float, rise: float,
		aE: float) -> void:
	var turn := Basis(Vector3.UP, PI * 0.5)
	lm.box("Walls", Vector3(0, E * 0.5, zt), Vector3(tl, E, nw))
	lm.gable("Roof", Vector3(0, E, zt), nw, tl, rise, turn, 0.5, "Walls")
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		var n := Vector3(s, 0, 0)
		var face := Vector3(s * tl * 0.5, 0, zt)
		_portal(lm, face, nw * 0.36, aE * 0.6, n)
		LandmarkCoreBArchKit.rose(lm, "Trim", "Windows", face + n * 0.05 + Vector3.UP * E * 0.68, n, minf(nw * 0.3, E * 0.2))
		for sz in [-1.0, 1.0]:
			LandmarkCoreBArchKit.buttress(lm, "Walls", face + Vector3(0, 0, float(sz) * nw * 0.5) - n * 0.5, n, nw * 0.1,
				nw * 0.12, E * 0.95)
			LandmarkCoreBArchKit.pinnacle(lm, "Trim", face + Vector3(0, E, float(sz) * nw * 0.5), nw * 0.05, E * 0.18)
		for sz in [-1.0, 1.0]:
			var side := Vector3(0, 0, sz)
			LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", Vector3(s * (tl * 0.5 - nw * 0.45), E * 0.3, zt + float(sz) * nw * 0.5),
				side, nw * 0.22, E * 0.5, 0.25, true)

## Pointed portal of `wd` x `ht` at `foot` (face centre at ground):
## recessed orders of archivolts, jamb shafts, the dark door, a
## crocketed gable (gablet) over it.
static func _portal(lm: LandmarkMesh, foot: Vector3, wd: float, ht: float, n: Vector3 = Vector3(0, 0, -1)) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var rise := LandmarkCoreBArchKit.pointed_rise(wd)
	var sh := maxf(ht - rise, 1.0)
	var d := foot + nn * 0.04
	lm.quad("Windows", d - right * wd * 0.5, d + right * wd * 0.5, d + right * wd * 0.5 + Vector3.UP * sh,
		d - right * wd * 0.5 + Vector3.UP * sh, nn)
	var arc := LandmarkCoreBArchKit.pointed(d + Vector3.UP * sh, right, wd, 4)
	for i in arc.size() - 1:
		lm.tri("Windows", d + Vector3.UP * sh, arc[i], arc[i + 1], nn, nn, nn, Vector2.ZERO,
			Vector2(arc[i].x, -arc[i].y), Vector2(arc[i + 1].x, -arc[i + 1].y))
	var ow := clampf(wd * 0.1, 0.2, 0.8)
	for o in 3:
		var span := wd + ow * (1.0 + 2.0 * float(o))
		var dep := ow * (1.0 + float(o))
		var c := foot + nn * dep * 0.5
		for s in [-1.0, 1.0]:
			lm.lathe("Trim", c + right * span * 0.5 * float(s), PackedVector2Array([Vector2(ow * 0.4, 0),
				Vector2(ow * 0.4, sh)]), 8)
		var ring := LandmarkCoreBArchKit.pointed(c + Vector3.UP * sh, right, span, 5)
		for i in ring.size() - 1:
			lm.beam("Trim", ring[i], ring[i + 1], ow, dep, nn.cross(ring[i + 1] - ring[i]))
	# Trumeau and lintel under a tympanum.
	lm.box("Trim", d + Vector3.UP * sh * 0.5, Vector3(ow * 0.8, sh, ow * 0.8), Basis(right, Vector3.UP, nn))
	lm.box("Trim", d + Vector3.UP * (sh - ow * 0.4), Vector3(wd, ow * 0.8, ow * 0.6), Basis(right, Vector3.UP, nn))
	var gw := wd + ow * 7.0
	var gb := foot + nn * ow * 3.2 + Vector3.UP * (sh + rise * 0.7)
	lm.gable("Trim", gb, ow * 1.2, gw, rise * 1.2, Basis(nn, Vector3.UP, -right), 0.0, "Trim")

## West tower: clasping corner buttresses, string courses between
## stages, lancets, clock faces, a louvred belfry and the regional top.
## The top of the finial lands at h.
static func _tower(lm: LandmarkMesh, base: Vector3, tw: float, h: float, style: String) -> void:
	var frac := {"spire": 0.55, "bell": 0.74, "onion": 0.66, "minaret": 0.6,
		"pagoda": 0.78, "shikhara": 0.6}.get(style, 0.55) as float
	var th := h * frac
	lm.box("Walls", base + Vector3(0, th * 0.5, 0), Vector3(tw, th, tw))
	var stages := 4 if th > 36.0 else 3
	var sh := th / float(stages)
	var cb := tw * 0.16
	for st in stages:
		var y0 := sh * float(st)
		var setk := 1.0 - 0.18 * float(st)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var c := base + Vector3(float(sx) * (tw * 0.5 + cb * 0.15 * setk), y0 + sh * 0.5,
					float(sz) * (tw * 0.5 + cb * 0.15 * setk))
				lm.box("Walls", c, Vector3(cb * setk * 1.3, sh, cb * setk * 1.3))
		lm.box("Trim", base + Vector3(0, y0 + sh - 0.2, 0), Vector3(tw + 0.5, 0.4, tw + 0.5))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(f))
			var n := r * Vector3(0, 0, 1)
			var face := base + n * tw * 0.5
			if st == stages - 1:
				# Belfry: paired louvred lancets.
				for s in [-1.0, 1.0]:
					var bw := tw * 0.2
					var foot := face + r * Vector3(float(s) * tw * 0.18, y0 + sh * 0.18, 0)
					LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", foot, n, bw, sh * 0.62, 0.3, false)
					for k in 5:
						lm.box("Roof", foot + n * 0.12 + Vector3.UP * sh * (0.06 + 0.08 * float(k)),
							Vector3(bw * 0.95, 0.12, 0.2), r * Basis(Vector3.RIGHT, 0.5), 0.0)
			elif st == stages - 2:
				# Clock dial with hour marks and hands.
				var cc := face + n * 0.08 + Vector3.UP * (y0 + sh * 0.5)
				var cr := minf(tw * 0.24, sh * 0.35)
				lm.disc("Trim", cc, n, cr, 24)
				LandmarkCoreBArchKit.ring_beams(lm, "Gilt", cc + n * 0.05, n, cr * 0.95, cr * 0.08, 16)
				lm.beam("Gilt", cc + n * 0.1, cc + n * 0.1 + Vector3.UP * cr * 0.75, cr * 0.07, 0.05)
				lm.beam("Gilt", cc + n * 0.1, cc + n * 0.1 + r * Vector3(cr * 0.5, -cr * 0.1, 0), cr * 0.09, 0.05)
			elif st > 0:
				LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", face + Vector3.UP * (y0 + sh * 0.25), n, tw * 0.14, sh * 0.5, 0.25)
	var top := base + Vector3(0, th, 0)
	var rest := h - th
	match style:
		"onion":
			lm.frustum("Walls", top, tw * 0.42, tw * 0.4, rest * 0.22, 8, PI / 8.0)
			for f in 8:
				var a := PI * 0.25 * float(f)
				var d := Vector3(cos(a), 0, sin(a))
				lm.box("Windows", top + d * tw * 0.4 + Vector3.UP * rest * 0.11, Vector3(tw * 0.08, rest * 0.12, 0.08),
					Basis.looking_at(d), 0.0)
			lm.frustum("Trim", top + Vector3.UP * rest * 0.21, tw * 0.45, tw * 0.45, rest * 0.02, 16)
			lm.lathe("Gilt", top + Vector3.UP * rest * 0.23, LandmarkCoreBArchKit.onion(tw * 0.46, rest * 0.6), 20)
			LandmarkCoreBArchKit.cross(lm, "Gilt", top + Vector3.UP * rest * 0.77, rest * 0.23)
		"bell", "pagoda":
			# Baroque bell cap, open lantern, spirelet and cross.
			lm.frustum("Trim", top, tw * 0.55, tw * 0.55, 0.6, 8, PI / 8.0)
			lm.lathe("Roof", top + Vector3.UP * 0.6, PackedVector2Array([Vector2(tw * 0.62, 0),
				Vector2(tw * 0.6, rest * 0.08), Vector2(tw * 0.42, rest * 0.2), Vector2(tw * 0.3, rest * 0.3),
				Vector2(tw * 0.22, rest * 0.36)]), 8, 1.0, 1.0, PI / 8.0, true)
			var ly := top + Vector3.UP * (0.6 + rest * 0.36)
			for f in 8:
				var a := PI / 8.0 + PI * 0.25 * float(f)
				lm.beam("Roof", ly + Vector3(cos(a), 0, sin(a)) * tw * 0.2,
					ly + Vector3(cos(a), 0, sin(a)) * tw * 0.2 + Vector3.UP * rest * 0.14, tw * 0.03)
			lm.frustum("Roof", ly + Vector3.UP * rest * 0.14, tw * 0.24, tw * 0.05, rest * 0.12, 8, PI / 8.0)
			lm.lathe("Gilt", ly + Vector3.UP * rest * 0.26, LandmarkCoreBArchKit.dome(tw * 0.05, tw * 0.05, 4), 8)
			var ct := ly + Vector3.UP * rest * 0.26
			lm.frustum("Roof", ct, tw * 0.03, tw * 0.02, h - ct.y - rest * 0.1, 6)
			LandmarkCoreBArchKit.cross(lm, "Gilt", Vector3(base.x, h - rest * 0.1, base.z), rest * 0.1)
		_:
			# Parapet with corner pinnacles, octagonal spire with lucarnes.
			for f in 4:
				var r := Basis(Vector3.UP, PI * 0.5 * float(f))
				var a := top + r * Vector3(-tw * 0.5, 0, tw * 0.5)
				var b := top + r * Vector3(tw * 0.5, 0, tw * 0.5)
				LandmarkCoreBArchKit.battlement(lm, "Trim", a, b, r * Vector3(0, 0, 1), 0.5, maxf(tw * 0.07, 0.5))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					LandmarkCoreBArchKit.pinnacle(lm, "Trim", top + Vector3(float(sx), 0, float(sz)) * tw * 0.44, tw * 0.07, rest * 0.16)
			var sp_h := rest * 0.92
			lm.lathe("Roof", top, PackedVector2Array([Vector2(tw * 0.46, 0), Vector2(tw * 0.4, sp_h * 0.08),
				Vector2(0.15, sp_h)]), 8, 1.0, 1.0, PI / 8.0, false)
			for f in 4:
				var r := Basis(Vector3.UP, PI * 0.5 * float(f))
				for tier in 2:
					var yy := sp_h * (0.14 + 0.3 * float(tier))
					var rr := lerpf(tw * 0.4, 0.15, (yy - sp_h * 0.08) / (sp_h * 0.92))
					var sz2 := tw * (0.12 - 0.04 * float(tier))
					var lc := top + Vector3.UP * yy + r * Vector3(0, 0, rr * 0.85)
					lm.box("Roof", lc + Vector3.UP * sz2 * 0.6, Vector3(sz2, sz2 * 1.2, sz2 * 1.2), r)
					lm.box("Windows", lc + r * Vector3(0, sz2 * 0.55, sz2 * 0.62), Vector3(sz2 * 0.5, sz2 * 0.8, 0.05), r, 0.0)
					lm.gable("Roof", lc + Vector3.UP * sz2 * 1.2, sz2, sz2 * 1.3, sz2 * 0.6, r, 0.05)
			lm.lathe("Gilt", top + Vector3.UP * sp_h, LandmarkCoreBArchKit.dome(0.35, 0.5, 4), 8)
			LandmarkCoreBArchKit.cross(lm, "Gilt", top + Vector3.UP * (sp_h + 0.4), h - th - sp_h - 0.4)

## Slender crossing flèche: open octagonal stage and needle spire.
static func _fleche(lm: LandmarkMesh, base: Vector3, r: float, h: float, style: String) -> void:
	if h < 3.0:
		return
	lm.frustum("Roof", base, r * 1.1, r, h * 0.12, 8, PI / 8.0)
	for f in 8:
		var a := PI / 8.0 + PI * 0.25 * float(f)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Trim", base + d * r + Vector3.UP * h * 0.12, base + d * r * 0.95 + Vector3.UP * h * 0.3, r * 0.12)
	if style == "onion":
		lm.lathe("Gilt", base + Vector3.UP * h * 0.3, LandmarkCoreBArchKit.onion(r * 1.6, h * 0.55), 16)
		LandmarkCoreBArchKit.cross(lm, "Gilt", base + Vector3.UP * h * 0.8, h * 0.2)
		return
	lm.frustum("Roof", base + Vector3.UP * h * 0.3, r * 1.05, 0.05, h * 0.62, 8, PI / 8.0)
	LandmarkCoreBArchKit.cross(lm, "Gilt", base + Vector3.UP * h * 0.9, h * 0.1)
