class_name LandmarkCoreBArchTemple
extends RefCounted

## Generic mosques and temples for LandmarkArchetypes, in true metres,
## long side along local Z: the Ottoman courtyard mosque, the East Asian
## pagoda, the North Indian (Nagara) shikhara temple and the Greek
## peripteral temple. Uses the keys Walls, Roof, Trim, Windows, Gilt
## registered by LandmarkArchetypes plus their own.

## Courtyard mosque (Süleymaniye, Sultan Ahmed): the prayer hall at +Z
## under a central dome on a windowed drum with four weight turrets,
## semi-domes along the qibla axis and corner domes; arched windows in
## two rows, the portal (pishtaq) with a muqarnas hood facing the
## arcaded, domed courtyard (−Z) with its ablution fountain; slender
## minarets with corbelled galleries reach h.
static func mosque(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#5E6E78", 2.0, 0.45, 0.4))
	var mr := clampf(h * 0.032, 1.2, 3.0)
	var hall_w := minf(w * 0.98 - mr * 6.4, w * 0.82)
	var hall_l := l * 0.5
	var hz0 := -l * 0.02
	var hc := Vector3(0, 0, hz0 + hall_l * 0.5)
	var hall_h := clampf(h * 0.22, 7.0, 22.0)
	lm.box("Walls", hc + Vector3.UP * hall_h * 0.5, Vector3(hall_w, hall_h, hall_l))
	lm.box("Trim", hc + Vector3.UP * (hall_h - 0.3), Vector3(hall_w + 0.5, 0.6, hall_l + 0.5))
	lm.box("Trim", hc + Vector3.UP * 0.6, Vector3(hall_w + 0.4, 1.2, hall_l + 0.4))
	# Two rows of arched windows on the sides and the qibla wall.
	for f in 3:
		var r := Basis(Vector3.UP, [PI * 0.5, -PI * 0.5, 0.0][f])
		var n := r * Vector3(0, 0, 1)
		var span := hall_l if f < 2 else hall_w
		var half := (hall_w if f < 2 else hall_l) * 0.5
		var nwin := clampi(int(span / 6.0), 2, 7)
		for i in nwin:
			var x := -span * 0.5 + span * (float(i) + 0.5) / float(nwin)
			for row in 2:
				var c := hc + r * Vector3(x, hall_h * (0.28 + 0.38 * float(row)), half)
				LandmarkDetail.window(lm, "Trim", "Windows", c, n, minf(1.6, span / float(nwin) * 0.4),
					hall_h * 0.22, true, 0.2)
	# Central dome square, drum with windows, weight turrets, the dome.
	var dr := minf(hall_w, hall_l) * 0.32
	dr = minf(dr, (h * 0.8 - hall_h) / 1.5)
	var dc := hc + Vector3.UP * hall_h
	lm.box("Walls", dc + Vector3.UP * dr * 0.08, Vector3(dr * 2.1, dr * 0.16, dr * 2.1))
	var drum_h := dr * 0.26
	var db := dc + Vector3.UP * dr * 0.16
	lm.frustum("Walls", db, dr * 1.02, dr * 1.0, drum_h, 32)
	var nd := clampi(int(TAU * dr / 3.0), 12, 20)
	for k in nd:
		var a := TAU * (float(k) + 0.5) / float(nd)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", db + d * dr * 1.0 + Vector3.UP * drum_h * 0.5, d,
			minf(TAU * dr / float(nd) * 0.4, 1.4), drum_h * 0.6, true, 0.12)
		if k % 2 == 0:
			lm.box("Walls", db + d * dr * 1.02 + Vector3.UP * drum_h * 0.45, Vector3(0.6, drum_h * 0.9, dr * 0.08),
				Basis.looking_at(d))
	lm.frustum("Trim", db + Vector3.UP * drum_h, dr * 1.05, dr * 1.05, 0.4, 32)
	var dome_h := dr * 0.92
	var dt := db + Vector3.UP * (drum_h + 0.4)
	lm.lathe("Dome", dt, LandmarkCoreBArchKit.dome(dr * 1.0, dome_h, 10), 32)
	# Alem finial: ball stack and crescent.
	var fy := dt + Vector3.UP * dome_h
	lm.frustum("Gilt", fy - Vector3.UP * 0.1, dr * 0.04, dr * 0.02, dr * 0.12, 8)
	lm.lathe("Gilt", fy + Vector3.UP * dr * 0.12, LandmarkCoreBArchKit.dome(dr * 0.04, dr * 0.05, 4), 8)
	LandmarkCoreBArchKit.ring_beams(lm, "Gilt", fy + Vector3.UP * dr * 0.22, Vector3(0, 0, 1), dr * 0.05,
		dr * 0.015, 10)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := dc + Vector3(float(sx), 0, float(sz)) * dr * 1.0
			lm.frustum("Walls", tc, dr * 0.12, dr * 0.11, dr * 0.42, 8, PI / 8.0)
			lm.frustum("Trim", tc + Vector3.UP * dr * 0.42, dr * 0.13, dr * 0.13, 0.3, 8, PI / 8.0)
			lm.lathe("Dome", tc + Vector3.UP * (dr * 0.42 + 0.3), LandmarkCoreBArchKit.dome(dr * 0.11, dr * 0.12, 5), 12)
			lm.frustum("Gilt", tc + Vector3.UP * (dr * 0.54 + 0.3), 0.12, 0.02, dr * 0.1, 6)
	# Semi-domes on the qibla axis, and corner domes.
	var sr := minf(dr, hall_l * 0.5 - dr)
	if sr > dr * 0.4:
		for sz in [-1.0, 1.0]:
			var sc := dc + Vector3(0, 0, float(sz) * dr)
			lm.lathe("Dome", sc, LandmarkCoreBArchKit.dome(sr, sr * 0.8, 8), 24)
	var cr := minf(minf(hall_w, hall_l) * 0.11, dr * 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cc := dc + Vector3(float(sx) * (hall_w * 0.5 - cr * 1.3), 0, float(sz) * (hall_l * 0.5 - cr * 1.3))
			lm.frustum("Walls", cc, cr, cr, cr * 0.3, 12)
			lm.lathe("Dome", cc + Vector3.UP * cr * 0.3, LandmarkCoreBArchKit.dome(cr, cr * 0.85, 6), 16)
	# Portal on the courtyard side: frame, pointed niche, muqarnas tiers.
	var pw := hall_w * 0.28
	var ph := minf(hall_h * 1.18, h * 0.5)
	var pf := Vector3(0, 0, hz0 - 0.8)
	lm.box("Trim", pf + Vector3.UP * ph * 0.5, Vector3(pw, ph, 1.6))
	var niche_w := minf(pw * 0.62, ph * 0.5)
	var nf := pf + Vector3(0, 0, -0.82)
	var rise := LandmarkCoreBArchKit.pointed_rise(niche_w)
	var nsh := ph * 0.82 - rise
	lm.quad("Windows", nf - Vector3(niche_w * 0.5, 0, 0), nf + Vector3(niche_w * 0.5, 0, 0),
		nf + Vector3(niche_w * 0.5, nsh, 0), nf + Vector3(-niche_w * 0.5, nsh, 0), Vector3(0, 0, -1))
	var arc := LandmarkCoreBArchKit.pointed(nf + Vector3.UP * nsh, Vector3.RIGHT, niche_w, 5)
	for i in arc.size() - 1:
		lm.tri("Windows", nf + Vector3.UP * nsh, arc[i], arc[i + 1], Vector3.FORWARD, Vector3.FORWARD,
			Vector3.FORWARD, Vector2.ZERO, Vector2(arc[i].x, -arc[i].y), Vector2(arc[i + 1].x, -arc[i + 1].y))
	for row in 3:
		var cells := 7 - row * 2
		for i in cells:
			var x := -niche_w * 0.4 + niche_w * 0.8 * (float(i) + 0.5) / float(cells)
			lm.box("Trim", nf + Vector3(x, nsh + float(row) * rise * 0.28 - 0.4, -0.25 - 0.2 * float(row)),
				Vector3(niche_w * 0.8 / float(cells) * 0.85, 0.7, 0.5), Basis(), 0.0)
	lm.box("Windows", nf + Vector3(0, minf(nsh * 0.35, 2.6), -0.05), Vector3(niche_w * 0.4, minf(nsh * 0.7, 5.2), 0.1),
		Basis(), 0.0)
	# Arcaded courtyard with a dome over every bay, and the fountain.
	var cz0 := -l * 0.49
	var cl := hz0 - cz0
	var ah := clampf(hall_h * 0.45, 4.0, 8.0)
	var depth := clampf(hall_w * 0.12, 3.5, 6.0)
	var sides := [[Vector3(-hall_w * 0.5, 0, cz0), Vector3(-hall_w * 0.5, 0, hz0), Vector3(1, 0, 0)],
		[Vector3(hall_w * 0.5, 0, hz0), Vector3(hall_w * 0.5, 0, cz0), Vector3(-1, 0, 0)],
		[Vector3(hall_w * 0.5, 0, cz0), Vector3(-hall_w * 0.5, 0, cz0), Vector3(0, 0, 1)]]
	for sd in sides:
		var a: Vector3 = sd[0]
		var b: Vector3 = sd[1]
		var inn: Vector3 = sd[2]
		var dir := (b - a).normalized()
		var basis := Basis(dir, Vector3.UP, inn)
		var ln := a.distance_to(b)
		lm.box("Walls", (a + b) * 0.5 + inn * 0.5 + Vector3.UP * ah * 0.5, Vector3(ln, ah, 1.0), basis)
		lm.box("Walls", (a + b) * 0.5 + inn * depth * 0.5 + Vector3.UP * (ah + 0.3), Vector3(ln, 0.6, depth), basis)
		var bays := maxi(int(ln / depth), 2)
		var bw := ln / float(bays)
		for i in bays + 1:
			var p := a + dir * bw * float(i) + inn * depth
			lm.lathe("Trim", p, PackedVector2Array([Vector2(0.4, 0), Vector2(0.32, ah * 0.62),
				Vector2(0.5, ah * 0.66)]), 10)
		for i in bays:
			var p := a + dir * bw * (float(i) + 0.5) + inn * depth
			var ring := LandmarkCoreBArchKit.pointed(p + Vector3.UP * ah * 0.66, dir, bw * 0.92, 3)
			for j in ring.size() - 1:
				lm.beam("Trim", ring[j], ring[j + 1], 0.45, 0.6, inn.cross(ring[j + 1] - ring[j]))
			var dcn := a + dir * bw * (float(i) + 0.5) + inn * depth * 0.5 + Vector3.UP * (ah + 0.6)
			lm.lathe("Dome", dcn, LandmarkCoreBArchKit.dome(minf(bw, depth) * 0.42, minf(bw, depth) * 0.36, 5), 12)
	var fc := Vector3(0, 0, (cz0 + hz0) * 0.5)
	lm.frustum("Trim", fc, 3.4, 3.4, 0.8, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		lm.lathe("Trim", fc + Vector3(cos(a), 0, sin(a)) * 3.0, PackedVector2Array([Vector2(0.18, 0), Vector2(0.15, 3.2)]), 6)
	lm.lathe("Dome", fc + Vector3.UP * 3.2, PackedVector2Array([Vector2(4.2, 0), Vector2(3.0, 0.8), Vector2(0.0, 2.2)]), 16)
	# Minarets at the hall's courtyard corners, and at the courtyard's
	# far corners on larger mosques.
	var balc := 3 if h > 60.0 else 2
	var mx := hall_w * 0.5 + mr * 1.6
	var spots := [Vector3(-mx, 0, hz0), Vector3(mx, 0, hz0)]
	if w * l > 2500.0:
		spots.append(Vector3(-mx, 0, cz0 + mr * 1.6))
		spots.append(Vector3(mx, 0, cz0 + mr * 1.6))
	for p in spots:
		lm.box("Trim", (p as Vector3) + Vector3.UP * 1.5, Vector3(mr * 3.0, 3.0, mr * 3.0))
		LandmarkKits.minaret(lm, "Walls", "Dome", (p as Vector3) + Vector3.UP * 3.0, mr, h - 3.6, balc)

## Temple by region: pagoda (East Asia), shikhara (South Asia), else a
## Greek peripteral temple.
static func temple(lm: LandmarkMesh, h: float, w: float, l: float, style: String) -> void:
	match style:
		"pagoda": _pagoda(lm, h, w)
		"shikhara": _shikhara(lm, h, w, l)
		_: _classical(lm, h, w, l)

## Five-storey pagoda (Hōryū-ji, Tō-ji, Bulguksa): a stone podium with
## stairs on all sides, storeys diminishing upward, each with posts,
## lattice doors, a balcony railing, tiers of bracket sets (dougong /
## tokyō) under deep concave eaves with upturned corners, and the
## bronze sōrin finial of nine rings and a water-flame to h.
static func _pagoda(lm: LandmarkMesh, h: float, w: float) -> void:
	lm.use("Timber", LandmarkMaterials.paint("#8E2B20", 0.7, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#3F7A66", 0.65, 0.0))
	var tiers := clampi(int(h / 9.0), 3, 7)
	if tiers % 2 == 0:
		tiers -= 1
	var B := clampf(w * 0.62, 7.0, 30.0)
	var plat := clampf(h * 0.04, 1.0, 2.4)
	lm.box("Trim", Vector3(0, plat * 0.5, 0), Vector3(B * 1.3, plat, B * 1.3))
	lm.box("Trim", Vector3(0, plat - 0.15, 0), Vector3(B * 1.34, 0.3, B * 1.34))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		for s in 3:
			lm.box("Trim", r * Vector3(0, plat * (float(s) + 0.5) / 3.0, B * 0.65 + 0.4 * (2.5 - float(s))),
				Vector3(B * 0.22, plat / 3.0, 0.4 * (3.0 - float(s)) + 0.2), r)
	var fl := h * 0.17
	var tier_h := (h - fl - plat) / float(tiers)
	for k in tiers:
		var s := B * (1.0 - 0.09 * float(k))
		var y := plat + tier_h * float(k)
		var core := s * 0.72
		var wall_h := tier_h * 0.55
		lm.box("Walls", Vector3(0, y + wall_h * 0.5, 0), Vector3(core, wall_h, core))
		lm.box("Timber", Vector3(0, y + wall_h - 0.2, 0), Vector3(core + 0.3, 0.4, core + 0.3))
		lm.box("Timber", Vector3(0, y + 0.15, 0), Vector3(core + 0.3, 0.3, core + 0.3))
		var posts := 4 if k == 0 else 3
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(f))
			var n := r * Vector3(0, 0, 1)
			for i in posts:
				var x := -core * 0.5 + core * float(i) / float(posts - 1)
				lm.lathe("Timber", r * Vector3(x, y, core * 0.5 + 0.05), PackedVector2Array([Vector2(0.22, 0),
					Vector2(0.2, wall_h)]), 8)
			# Central lattice door between the posts.
			var dw := core / float(posts - 1) * 0.7
			var dc := r * Vector3(0, y + wall_h * 0.45, core * 0.5 + 0.03)
			lm.box("Windows", dc, Vector3(dw, wall_h * 0.75, 0.05), r, 0.0)
			for q in 4:
				lm.box("Timber", dc + r * Vector3(-dw * 0.3 + dw * 0.2 * float(q), 0, 0.05), Vector3(0.08, wall_h * 0.75, 0.08), r, 0.0)
			lm.box("Timber", dc + r * Vector3(0, 0, 0.06), Vector3(dw, 0.08, 0.08), r, 0.0)
			if k > 0:
				# Balcony railing round the storey.
				var bo := core * 0.5 + 0.5
				lm.box("Timber", r * Vector3(0, y + 0.9, bo), Vector3(core + 1.0, 0.12, 0.12), r, 0.0)
				for q in 7:
					lm.box("Timber", r * Vector3(-core * 0.5 + core * float(q) / 6.0, y + 0.45, bo),
						Vector3(0.1, 0.9, 0.1), r, 0.0)
				lm.box("Walls", r * Vector3(0, y + 0.05, bo - 0.3), Vector3(core + 1.0, 0.1, 0.9), r, 0.0)
			# Bracket sets: three stepped tiers under the eave.
			var nb := maxi(int(core / 1.3), 3)
			for i in nb:
				var x := -core * 0.5 + core * (float(i) + 0.5) / float(nb)
				for t in 3:
					lm.box("Bracket", r * Vector3(x, y + wall_h + 0.18 + 0.3 * float(t), core * 0.5 + 0.2 + 0.28 * float(t)),
						Vector3(0.5 + 0.12 * float(t), 0.26, 0.5), r, 0.0)
		var eave := s * 0.62
		var top := (B * (1.0 - 0.09 * float(k + 1))) * 0.36
		var ry := y + wall_h + 1.0
		var rise := tier_h - wall_h - 1.0
		if k == tiers - 1:
			top = s * 0.12
			rise = tier_h * 0.7
		_hip_roof(lm, ry, eave, top, rise, tier_h * 0.12)
	# Sōrin: base, dew basin, nine rings, water flame, jewel.
	var sy := plat + tier_h * float(tiers - 1) + tier_h * 0.55 + 1.0 + tier_h * 0.7
	var rem := maxf(h - sy, 1.0)
	lm.box("Gilt", Vector3(0, sy + rem * 0.03, 0), Vector3(B * 0.08, rem * 0.06, B * 0.08))
	lm.lathe("Gilt", Vector3(0, sy + rem * 0.06, 0), PackedVector2Array([Vector2(B * 0.03, 0),
		Vector2(B * 0.06, rem * 0.04), Vector2(B * 0.05, rem * 0.08)]), 10)
	lm.frustum("Gilt", Vector3(0, sy + rem * 0.08, 0), 0.18, 0.12, rem * 0.84, 8)
	for i in 9:
		lm.frustum("Gilt", Vector3(0, sy + rem * (0.14 + 0.055 * float(i)), 0), B * 0.045, B * 0.04, rem * 0.02, 12)
	for f in 4:
		var a := PI * 0.5 * float(f)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gilt", Vector3(0, sy + rem * 0.68, 0) + d * 0.1, Vector3(0, sy + rem * 0.8, 0) + d * B * 0.035, 0.18, 0.06)
	lm.lathe("Gilt", Vector3(0, sy + rem * 0.88, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(rem * 0.04, rem * 0.04),
		Vector2(rem * 0.03, rem * 0.09), Vector2(0.0, rem * 0.12)]), 10)

## Concave hipped roof from an eave square (half-width `eave`) at y up
## to a top square (half-width `top`), `rise` high, with the corners
## swept up by `lift`, hip ridges and a cap.
static func _hip_roof(lm: LandmarkMesh, y: float, eave: float, top: float, rise: float, lift: float) -> void:
	var rows: Array = []
	for k in 6:
		var t := float(k) / 5.0
		var f := 1.0 - pow(1.0 - t, 1.8)
		var hw := lerpf(eave, top, f)
		var ring: Array = []
		for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			ring.append(Vector3(c.x * hw, y + rise * t, c.y * hw))
		rows.append(ring)
	for side in 4:
		var strip: Array = []
		for k in rows.size():
			var r: Array = rows[k]
			var a: Vector3 = r[side]
			var b: Vector3 = r[side + 1]
			var line := PackedVector3Array()
			for q in 7:
				var p := a.lerp(b, float(q) / 6.0)
				var edge := absf(float(q) / 6.0 - 0.5) * 2.0
				line.append(p + Vector3.UP * pow(edge, 3.0) * lift * (1.0 - float(k) / 5.0))
			strip.append(line)
		lm.grid("Roof", strip, Vector3(0, y - 50.0, 0), true)
		# Hip ridge from the upturned corner to the top.
		var c0: Vector3 = (rows[0] as Array)[side]
		var c1: Vector3 = (rows[5] as Array)[side]
		lm.beam("Roof", c0 + Vector3.UP * (lift + 0.15), c1 + Vector3.UP * 0.15, 0.35, 0.35)
		lm.beam("Roof", c0 + Vector3.UP * (lift + 0.15), c0 * Vector3(1.06, 1, 1.06) + Vector3.UP * (lift * 1.6 + 0.3), 0.3, 0.3)
	var last: Array = rows[5]
	var cap := PackedVector2Array()
	for i in 4:
		var v: Vector3 = last[i]
		cap.append(Vector2(v.x, v.z))
	lm.poly_prism("Roof", cap, y + rise - 0.2, y + rise)

## Nagara temple (Kandariya Mahadeva, Lingaraja): a moulded plinth
## (jagati) with front stairs, the pillared mandapa under a stepped
## pyramidal roof, and over the sanctum the curvilinear shikhara of
## storey courses (bhumi) with central projections and corner
## amalakas, clustered sub-spires (urushringa), the ribbed amalaka and
## the gilt kalasha finial at h.
static func _shikhara(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	var W := w * 0.95
	var L := l * 0.95 - 4.5
	var pj := clampf(h * 0.05, 1.5, 4.0)
	for i in 3:
		var k := 1.0 - 0.03 * float(i)
		lm.box("Trim", Vector3(0, pj * (float(i) + 0.5) / 3.0, 0), Vector3(W * k, pj / 3.0, L * k))
	for s in 5:
		lm.box("Trim", Vector3(0, pj * (float(s) + 0.5) / 5.0, -L * 0.5 - 0.4 * (4.5 - float(s))),
			Vector3(W * 0.18, pj / 5.0, 0.4 * (5.0 - float(s)) + 0.3))
	var sw := clampf(minf(W, L * 0.45) * 0.4, 3.0, 16.0)
	var sc := Vector3(0, pj, L * 0.18)
	var wall_h := h * 0.16
	_ratha_block(lm, sc, sw, wall_h)
	# Shikhara courses.
	var kal := maxf(h * 0.06, 1.0)
	var am := sw * 0.32
	var y0 := pj + wall_h
	var ya := h - kal - am
	var levels := 10
	var dh := (ya - y0) / float(levels)
	for i in levels:
		var t := float(i) / float(levels)
		var f := sw * (1.0 - 0.62 * pow(t, 1.5))
		var f1 := sw * (1.0 - 0.62 * pow(t + 1.0 / float(levels), 1.5))
		var c := Vector3(sc.x, y0 + dh * float(i), sc.z)
		lm.frustum("Walls", c, f * 1.41, f1 * 1.41, dh, 4, PI * 0.25)
		for fc in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(fc))
			lm.box("Walls", c + r * Vector3(0, dh * 0.5, (f + f1) * 0.5), Vector3((f + f1) * 0.7, dh, f * 0.24), r)
			lm.box("Trim", c + r * Vector3(0, dh - 0.12, (f + f1) * 0.5 + f * 0.12), Vector3((f + f1) * 0.72, 0.24, 0.3), r)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.lathe("Trim", c + Vector3(float(sx) * f * 0.92, dh * 0.7, float(sz) * f * 0.92),
					PackedVector2Array([Vector2(f * 0.06, 0), Vector2(f * 0.13, dh * 0.15), Vector2(f * 0.06, dh * 0.3)]), 8)
	# Urushringas: half-height sub-spires against each face.
	for fc in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(fc))
		if fc == 2:
			continue
		var uc := sc + r * Vector3(0, wall_h, sw * 0.9)
		var uw := sw * 0.42
		var uh := (ya - y0) * 0.45
		for i in 5:
			var t := float(i) / 5.0
			var f := uw * (1.0 - 0.6 * pow(t, 1.4))
			var f1 := uw * (1.0 - 0.6 * pow(t + 0.2, 1.4))
			lm.frustum("Walls", uc + Vector3.UP * uh * t, f * 1.41, f1 * 1.41, uh * 0.2, 4, PI * 0.25)
			lm.box("Trim", uc + Vector3.UP * (uh * (t + 0.2) - 0.1), Vector3(f1 * 2.1, 0.2, f1 * 2.1), r, 0.0)
		lm.lathe("Trim", uc + Vector3.UP * uh, PackedVector2Array([Vector2(uw * 0.35, 0), Vector2(uw * 0.55, uw * 0.12),
			Vector2(uw * 0.35, uw * 0.24)]), 12)
	# Amalaka (ribbed cushion stone) and kalasha.
	var at := Vector3(sc.x, ya, sc.z)
	var ar := sw * 0.42
	lm.frustum("Walls", at - Vector3.UP * 0.01, ar * 0.7, ar * 0.7, am * 0.15, 12)
	lm.lathe("Trim", at + Vector3.UP * am * 0.15, PackedVector2Array([Vector2(ar * 0.7, 0), Vector2(ar * 1.05, am * 0.25),
		Vector2(ar * 1.1, am * 0.45), Vector2(ar * 1.0, am * 0.65), Vector2(ar * 0.5, am * 0.82)]), 24)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Trim", at + d * ar * 0.75 + Vector3.UP * am * 0.17, at + d * ar * 1.12 + Vector3.UP * am * 0.45, ar * 0.12)
		lm.beam("Trim", at + d * ar * 1.12 + Vector3.UP * am * 0.45, at + d * ar * 0.55 + Vector3.UP * am * 0.8, ar * 0.12)
	lm.frustum("Trim", at + Vector3.UP * am * 0.82, ar * 0.5, ar * 0.45, am * 0.18, 12)
	var ky := ya + am
	lm.lathe("Gilt", Vector3(sc.x, ky, sc.z), PackedVector2Array([Vector2(kal * 0.15, 0), Vector2(kal * 0.3, kal * 0.2),
		Vector2(kal * 0.28, kal * 0.4), Vector2(kal * 0.1, kal * 0.55), Vector2(kal * 0.12, kal * 0.65),
		Vector2(kal * 0.04, kal * 0.8), Vector2(0.0, kal)]), 12)
	# Mandapa: pillared hall with a stepped pyramidal roof.
	var mz := -L * 0.16
	var mw := minf(W * 0.7, sw * 2.2)
	var md := minf(L * 0.36, mw)
	var mh := wall_h * 0.85
	var mc := Vector3(0, pj, mz)
	lm.box("Walls", mc + Vector3(0, mh * 0.5, md * 0.25), Vector3(mw * 0.7, mh, md * 0.5))
	for i in 4:
		for j in 4:
			if (i == 1 or i == 2) and (j == 1 or j == 2):
				continue
			var p := mc + Vector3(-mw * 0.45 + mw * 0.3 * float(i), 0, -md * 0.45 + md * 0.3 * float(j))
			lm.box("Trim", p + Vector3.UP * 0.4, Vector3(0.9, 0.8, 0.9))
			lm.lathe("Trim", p + Vector3.UP * 0.8, PackedVector2Array([Vector2(0.38, 0), Vector2(0.42, mh * 0.3),
				Vector2(0.32, mh * 0.6), Vector2(0.36, mh - 1.6)]), 8)
			lm.box("Trim", p + Vector3.UP * (mh - 0.4), Vector3(1.4, 0.8, 1.4))
	lm.box("Walls", mc + Vector3.UP * (mh + 0.3), Vector3(mw + 1.0, 0.6, md + 1.0))
	var steps := 6
	var roof_h := minf(mh * 1.2, (ya - pj) * 0.5)
	for s in steps:
		var k := 1.0 - float(s) / float(steps)
		var y := mh + 0.6 + roof_h * float(s) / float(steps)
		lm.box("Walls", mc + Vector3.UP * (y + roof_h / float(steps) * 0.4), Vector3((mw + 0.6) * k, roof_h / float(steps) * 0.8,
			(md + 0.6) * k))
		lm.box("Trim", mc + Vector3.UP * (y + roof_h / float(steps) * 0.85), Vector3((mw + 1.0) * k, 0.2, (md + 1.0) * k), Basis(), 0.0)
	lm.lathe("Gilt", mc + Vector3.UP * (mh + 0.6 + roof_h), PackedVector2Array([Vector2(0.4, 0), Vector2(0.6, 0.4),
		Vector2(0.15, 0.9), Vector2(0.0, 1.3)]), 10)

## Sanctum walls on a cross plan: core, projecting bays with niches and
## pilasters, base mouldings and a crowning course.
static func _ratha_block(lm: LandmarkMesh, c: Vector3, sw: float, h: float) -> void:
	lm.box("Walls", c + Vector3.UP * h * 0.5, Vector3(sw * 2.0, h, sw * 2.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var n := r * Vector3(0, 0, 1)
		lm.box("Walls", c + r * Vector3(0, h * 0.5, sw + sw * 0.08), Vector3(sw * 0.8, h, sw * 0.16), r)
		lm.box("Walls", c + r * Vector3(0, h * 0.5, sw + sw * 0.16 + 0.05), Vector3(sw * 0.4, h, 0.1), r)
		lm.box("Windows", c + n * (sw * 1.22) + Vector3.UP * h * 0.5, Vector3(sw * 0.24, h * 0.36, 0.06), r, 0.0)
		lm.gable("Trim", c + n * (sw * 1.26) + Vector3.UP * h * 0.7, 0.3, sw * 0.34, sw * 0.12, r * Basis(Vector3.UP, PI * 0.5), 0.0)
		for s in [-1.0, 1.0]:
			lm.box("Trim", c + r * Vector3(float(s) * sw * 0.65, h * 0.5, sw + 0.1), Vector3(sw * 0.1, h * 0.9, 0.2), r)
		for k in 3:
			lm.box("Trim", c + r * Vector3(0, 0.3 + 0.5 * float(k), sw + sw * 0.17), Vector3(sw * 2.2 - 0.3 * float(k), 0.3, 0.3), r)
		lm.box("Trim", c + r * Vector3(0, h - 0.2, sw + sw * 0.17), Vector3(sw * 2.2, 0.4, 0.4), r)

## Greek Doric peripteral temple (Parthenon, Hephaisteion): a
## three-stepped crepidoma, a peristyle of fluted Doric columns, the
## cella with its porch, an entablature with triglyphs and mutules,
## pediments with raking cornices, tiled roof with antefixes and the
## central acroterion at h.
static func _classical(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	var W := minf(w * 0.95, l * 0.6)
	var L := minf(l * 0.95, W * 2.25)
	var st := clampf(h * 0.06, 1.0, 3.0)
	for k in 3:
		var i := float(k)
		lm.box("Trim", Vector3(0, st * (i + 0.5) / 3.0, 0), Vector3(W - i * st * 0.6, st / 3.0, L - i * st * 0.6))
	var Ws := W - st * 1.2
	var Ls := L - st * 1.2
	var col_h := (h - st) * 0.62
	var entab := col_h * 0.26
	var ped := h - st - col_h - entab
	var acro := minf(ped * 0.2, minf(col_h / 11.0, Ws / 14.0) * 3.0)
	var rise := ped - acro
	var r := minf(col_h / 11.0, Ws / 14.0)
	var nx := clampi(roundi((Ws - r * 2.6) / (r * 4.6)) + 1, 4, 8)
	if nx % 2 == 1:
		nx += 1
	var sp := (Ws - r * 2.6) / float(nx - 1)
	var nz := clampi(roundi((Ls - r * 2.6) / sp) + 1, 5, 17)
	var spz := (Ls - r * 2.6) / float(nz - 1)
	var x0 := -(Ws - r * 2.6) * 0.5
	var z0 := -(Ls - r * 2.6) * 0.5
	for i in nx:
		for s in [-1.0, 1.0]:
			LandmarkDetail.column(lm, "Trim", Vector3(x0 + sp * float(i), st, float(s) * -z0), r, col_h, "doric", 12)
	for j in range(1, nz - 1):
		for s in [-1.0, 1.0]:
			LandmarkDetail.column(lm, "Trim", Vector3(float(s) * -x0, st, z0 + spz * float(j)), r, col_h, "doric", 12)
	# Cella with antae and a porch door.
	var cw := Ws - sp * 2.0
	var cl := Ls - spz * 2.6
	lm.box("Walls", Vector3(0, st + col_h * 0.5, spz * 0.2), Vector3(cw, col_h, cl))
	lm.box("Trim", Vector3(0, st + 0.4, spz * 0.2), Vector3(cw + 0.4, 0.8, cl + 0.4))
	var cf := spz * 0.2 - cl * 0.5
	lm.box("Windows", Vector3(0, st + col_h * 0.3, cf - 0.04), Vector3(cw * 0.22, col_h * 0.6, 0.1), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		LandmarkDetail.column(lm, "Trim", Vector3(float(s) * cw * 0.2, st, cf - r * 1.6), r * 0.9, col_h, "doric", 12)
	# Entablature: architrave, triglyph frieze, cornice with mutules.
	var ey := st + col_h
	var eb := entab * 0.4
	lm.box("Trim", Vector3(0, ey + eb * 0.5, 0), Vector3(Ws - r * 0.4, eb, Ls - r * 0.4))
	lm.box("Walls", Vector3(0, ey + eb + entab * 0.2, 0), Vector3(Ws - r * 0.5, entab * 0.4, Ls - r * 0.5))
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var span := Ws if f % 2 == 0 else Ls
		var half := (Ls if f % 2 == 0 else Ws) * 0.5 - r * 0.25
		var step := (sp if f % 2 == 0 else spz) * 0.5
		var nt := int(span / step)
		for t in nt + 1:
			var x := -step * float(nt) * 0.5 + step * float(t)
			lm.box("Trim", rb * Vector3(x, ey + eb + entab * 0.2, half + 0.05), Vector3(step * 0.32, entab * 0.38, 0.12), rb, 0.0)
		LandmarkDetail.cornice(lm, "Trim", rb * Vector3(-span * 0.5 - r * 0.3, ey + entab * 0.8, half - r * 0.1),
			rb * Vector3(span * 0.5 + r * 0.3, ey + entab * 0.8, half - r * 0.1), rb * Vector3(0, 0, 1), minf(entab * 0.25, r * 0.8), false)
	# Pediments, raking cornices, tiled roof, antefixes, acroteria.
	var py := ey + entab
	var pw := Ws + r * 0.3
	lm.gable("Roof", Vector3(0, py, 0), pw, Ls, rise, Basis(), r * 0.5, "Walls")
	for s in [-1.0, 1.0]:
		var z := float(s) * (Ls * 0.5 + r * 0.25)
		for sx in [-1.0, 1.0]:
			lm.beam("Trim", Vector3(float(sx) * (pw * 0.5 + r * 0.5), py, z), Vector3(0, py + rise + 0.1, z),
				minf(entab * 0.25, r * 0.8), minf(entab * 0.3, r))
		lm.lathe("Trim", Vector3(0, py + rise, z), PackedVector2Array([Vector2(acro * 0.3, 0), Vector2(acro * 0.45, acro * 0.5),
			Vector2(acro * 0.2, acro * 0.85), Vector2(0.0, acro)]), 8, 1.0, 0.4)
		for sx in [-1.0, 1.0]:
			lm.box("Trim", Vector3(float(sx) * pw * 0.5, py + acro * 0.25, z), Vector3(acro * 0.3, acro * 0.5, acro * 0.15))
	for sx in [-1.0, 1.0]:
		var na := int(Ls / (spz * 0.5))
		for i in na + 1:
			var z := -Ls * 0.5 + Ls * float(i) / float(na)
			lm.box("Trim", Vector3(float(sx) * (pw * 0.5 + r * 0.45), py + 0.25, z), Vector3(0.12, 0.5, 0.35), Basis(), 0.0)
