class_name LandmarkRbWinterPalace
extends RefCounted

## The Winter Palace, Saint Petersburg (Rastrelli, 1754-1762), in true
## metres: the closed Baroque rectangle round its Great Court, about
## 210 m on the Neva and 175 m on the Admiralty side, 23.5 m to the
## cornice. Pale green render with white giant-order columns (Ionic on
## the ground floor, Corinthian through the two upper floors), three
## projecting risalits on each long front (the Palace Square one pierced
## by the three gateway arches), the cour d'honneur on the Admiralty
## front, and the roof balustrade with its statues and vases.

const WP_TOP := 30.0
const WP_EAVE := 22.0
const WP_BAYS := 5.3
## Window bands: [bottom, top, window w, window h, sill above the band foot].
const BANDS := [[0.9, 7.2, 2.2, 3.8, 1.5], [7.2, 13.4, 2.3, 4.6, 1.0], [13.4, 19.4, 2.3, 3.9, 1.1]]

## Origin at the palace centre; long (Neva) front along X, the Palace
## Square front facing +Z, the Admiralty front -X. Plan 212 x 170 m
## round a 124 x 105 m court.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#7FB6A0", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F0EDE2", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8478", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#667A70", 3.0, 0.6, 0.2))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#4E8A74", 3.0, 0.5, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Wings round the court: Palace Square (+Z), Neva (-Z), the east wing
	# and the Admiralty wing, whose two end blocks embrace the forecourt.
	var wings := [[0.0, 67.5, 212.0, 35.0, 0], [0.0, -70.0, 212.0, 30.0, 0], [84.0, -2.5, 44.0, 105.0, 1],
		[-76.0, -2.5, 28.0, 105.0, 1], [-98.0, -42.5, 16.0, 25.0, 1], [-98.0, 37.5, 16.0, 25.0, 1]]
	for w in wings:
		var c := Vector3(float(w[0]), WP_EAVE * 0.5, float(w[1]))
		var sz := Vector3(float(w[2]), WP_EAVE, float(w[3]))
		lm.box("Wall", c, sz)
		# Low pitched iron roofs behind the balustrade.
		var along_z := int(w[4]) == 1
		var rb := Basis() if along_z else Basis(Vector3.UP, PI * 0.5)
		lm.gable("Roof", Vector3(c.x, WP_EAVE, c.z), (sz.x if along_z else sz.z) - 1.0,
			(sz.z if along_z else sz.x) - 1.0, 3.6, rb, 0.2, "Wall")
	# Granite plinth round the outer fronts.
	var plinth := [[0.0, 85.3, 213.0, 0.6], [0.0, -85.3, 213.0, 0.6], [106.3, 0.0, 0.6, 171.0],
		[-106.3, -57.5, 0.6, 55.0], [-106.3, 55.0, 0.6, 60.0], [-90.3, -2.5, 0.6, 55.0]]
	for p in plinth:
		lm.box("Plinth", Vector3(float(p[0]), 0.45, float(p[1])), Vector3(float(p[2]), 0.9, float(p[3])))
	# Outer fronts: the long ones carry the three risalits (the square's
	# central one with the gateway); the Admiralty front is split by the
	# forecourt. Then the plainer court fronts with pilasters.
	_face(lm, Vector3(0, 0, 85.0), Vector3(0, 0, 1), 212.0, true, 7, true, true)
	_face(lm, Vector3(0, 0, -85.0), Vector3(0, 0, -1), 212.0, true, 7, true, false)
	_face(lm, Vector3(106.0, 0, 0), Vector3(1, 0, 0), 170.0, true, 5, true, false)
	_face(lm, Vector3(-106.0, 0, -57.5), Vector3(-1, 0, 0), 55.0, true, 0, false, false)
	_face(lm, Vector3(-106.0, 0, 55.0), Vector3(-1, 0, 0), 60.0, true, 0, false, false)
	_face(lm, Vector3(-90.0, 0, -2.5), Vector3(-1, 0, 0), 55.0, true, 3, false, false)
	_face(lm, Vector3(-98.0, 0, -30.0), Vector3(0, 0, 1), 16.0, true, 0, false, false)
	_face(lm, Vector3(-98.0, 0, 25.0), Vector3(0, 0, -1), 16.0, true, 0, false, false)
	_face(lm, Vector3(0, 0, 50.0), Vector3(0, 0, -1), 124.0, false, 0, false, false)
	_face(lm, Vector3(0, 0, -55.0), Vector3(0, 0, 1), 124.0, false, 0, false, false)
	_face(lm, Vector3(62.0, 0, -2.5), Vector3(-1, 0, 0), 105.0, false, 0, false, false)
	_face(lm, Vector3(-62.0, 0, -2.5), Vector3(1, 0, 0), 105.0, false, 0, false, false)
	_great_church(lm, Vector3(76.0, WP_EAVE + 1.2, 58.0))
	lm.commit(model)

## The Great Church's cupola over the south-east corner: drum with
## arched windows and pilasters, green dome, gilded lantern and cross.
static func _great_church(lm: LandmarkMesh, cb: Vector3) -> void:
	lm.box("Wall", cb + Vector3(0, -0.6, 0), Vector3(11.0, 2.4, 11.0))
	lm.frustum("White", cb, 4.2, 4.2, 2.8, 16)
	SEuUtil.ring_openings(lm, "Windows", cb, 4.2, 16, 8, 0.4, 1.0, 2.0, false, PI / 8.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("White", cb + d * 4.25 + Vector3(0, 1.4, 0), Vector3(0.45, 2.8, 0.3), Basis.looking_at(d))
	lm.frustum("White", cb + Vector3(0, 2.8, 0), 4.6, 4.6, 0.4, 16)
	lm.lathe("Dome", cb + Vector3(0, 3.2, 0), LandmarkRbParts.dome_profile(4.6, 2.0), 16)
	lm.frustum("Gilt", cb + Vector3(0, 5.0, 0), 0.7, 0.6, 0.8, 8)
	LandmarkRbParts.cross(lm, "Gilt", cb + Vector3(0, 5.8, 0), WP_TOP - cb.y - 5.8)

## One wall of the palace. `o` is the wall centre at ground, `out` its
## outward normal. Bays of WP_BAYS split into segments: end risalits
## (3 bays, 1.5 m proud) when `ends`, a central risalit of `centre` bays
## (3 m proud), plain stretches between; `gate` opens the three middle
## bays of the central risalit as the archway to the court.
static func _face(lm: LandmarkMesh, o: Vector3, out: Vector3, length: float, outer: bool, centre: int,
		ends: bool, gate: bool) -> void:
	var b := LandmarkRbParts.facing(out)
	var bays := maxi(roundi(length / WP_BAYS), 1)
	if centre > 0 and (bays - centre) % 2 != 0:
		bays += 1
	var pitch := length / float(bays)
	var e := 3 if ends else 0
	var segs: Array = []
	if e > 0:
		segs.append([0, e, 1.5])
	if centre > 0:
		var c0 := (bays - centre) / 2
		segs.append([e, c0 - e, 0.0])
		segs.append([c0, centre, 3.0])
		segs.append([c0 + centre, bays - e - c0 - centre, 0.0])
	else:
		segs.append([e, bays - 2 * e, 0.0])
	if e > 0:
		segs.append([bays - e, e, 1.5])
	for sg in segs:
		var n: int = sg[1]
		if n <= 0:
			continue
		var i0: int = sg[0]
		var s0 := (float(i0) - float(bays) * 0.5) * pitch
		_segment(lm, o, out, b, s0, pitch, n, float(sg[2]), outer, gate and float(sg[2]) > 2.0,
			i0 == 0, i0 + n == bays)

## One segment of `n` bays starting `s0` along the face, `proj` proud.
static func _segment(lm: LandmarkMesh, o: Vector3, out: Vector3, b: Basis, s0: float, pitch: float, n: int,
		proj: float, outer: bool, gate: bool, first: bool, last: bool) -> void:
	var right := b.x
	var seg_len := pitch * float(n)
	var fo := o + out * proj
	var mid := fo + right * (s0 + seg_len * 0.5)
	if proj > 0.0:
		lm.box("Wall", o + right * (s0 + seg_len * 0.5) + out * (proj * 0.5) + Vector3(0, WP_EAVE * 0.5, 0),
			Vector3(seg_len, WP_EAVE, proj), b)
		lm.box("Plinth", mid + out * 0.3 + Vector3(0, 0.45, 0), Vector3(seg_len + 0.6, 0.9, 0.6), b)
	# Wall skin with real window openings, one skin per storey band.
	var origin := fo + right * s0
	for k in BANDS.size():
		var band: Array = BANDS[k]
		var y0: float = band[0]
		var bh: float = float(band[1]) - y0
		var win := Vector2(float(band[2]), float(band[3]))
		if k == 0 and gate:
			# Seven bays: two windows, the three gateway arches, two windows.
			var side := 2 if n >= 7 else 0
			LandmarkDetail.pierced_face(lm, "Wall", "Windows", origin + Vector3(0, y0, 0), right, out,
				pitch * side, bh, side, 1, win, float(band[4]), 10.0)
			LandmarkDetail.pierced_face(lm, "Wall", "Windows", origin + right * (pitch * (n - side)) + Vector3(0, y0, 0),
				right, out, pitch * side, bh, side, 1, win, float(band[4]), 10.0)
			var gw := pitch * float(n - 2 * side)
			LandmarkDetail.pierced_face(lm, "Wall", "Windows", origin + right * (pitch * side) + Vector3(0, y0, 0),
				right, out, gw, bh, n - 2 * side, 1, Vector2(pitch * 0.68, bh - 1.4), 0.0, 10.0, 0.9)
			for i in n - 2 * side:
				var gc := origin + right * (pitch * (float(side + i) + 0.5)) + Vector3(0, y0 + bh - 1.4, 0)
				LandmarkDetail.arch(lm, "White", gc - Vector3(0, pitch * 0.34, 0) + out * 0.9, out, pitch * 0.68, 0.45, 0.35)
			continue
		LandmarkDetail.pierced_face(lm, "Wall", "Windows", origin + Vector3(0, y0, 0), right, out,
			seg_len, bh, n, 1, win, float(band[4]), 10.0)
		if not outer:
			continue
		# Window dressings: keystone below, hood moulds on the main floor,
		# cornice heads on the top floor; sills throughout.
		for i in n:
			if gate and k == 0:
				continue
			var wc := origin + right * (pitch * (float(i) + 0.5)) + out * 0.35
			var sill_y: float = y0 + float(band[4])
			var top_y: float = sill_y + win.y
			lm.box("White", wc + Vector3(0, sill_y - 0.12, 0) + out * 0.12, Vector3(win.x + 0.6, 0.24, 0.3), b, 0.0)
			lm.box("White", wc + Vector3(0, top_y + 0.12, 0) + out * 0.06, Vector3(win.x + 0.5, 0.24, 0.16), b, 0.0)
			match k:
				0:
					lm.box("White", wc + Vector3(0, top_y + 0.3, 0) + out * 0.15, Vector3(0.6, 0.8, 0.3), b, 0.0)
				1:
					var prev := wc + Vector3(0, top_y + 0.35, 0) + out * 0.2 - right * (win.x * 0.5 + 0.35)
					for j in 4:
						var t := PI * (1.0 - float(j + 1) / 4.0)
						var p := wc + Vector3(0, top_y + 0.35 + sin(t) * 0.7, 0) + out * 0.2 \
							+ right * (cos(t) * (win.x * 0.5 + 0.35))
						lm.beam("White", prev, p, 0.24, 0.3, out)
						prev = p
					lm.box("White", wc + Vector3(0, top_y + 0.85, 0) + out * 0.2, Vector3(0.5, 0.9, 0.3), b, 0.0)
				_:
					lm.box("White", wc + Vector3(0, top_y + 0.42, 0) + out * 0.2, Vector3(win.x + 0.9, 0.3, 0.4), b, 0.0)
	var face := fo + out * 0.35
	var smid := face + right * (s0 + seg_len * 0.5)
	# String course, entablature and cornice.
	lm.box("White", smid + Vector3(0, 7.2, 0) + out * 0.3, Vector3(seg_len, 0.5, 0.6), b)
	if outer:
		lm.box("White", smid + Vector3(0, 20.35, 0) + out * 1.0, Vector3(seg_len, 1.9, 2.0), b)
		lm.box("White", smid + Vector3(0, 21.6, 0) + out * 1.3, Vector3(seg_len + 0.6, 0.8, 2.6), b)
		LandmarkDetail.cornice(lm, "White", face + right * s0 + Vector3(0, 21.1, 0) + out * 2.0,
			face + right * (s0 + seg_len) + Vector3(0, 21.1, 0) + out * 2.0, out, 0.6, false)
	else:
		lm.box("White", smid + Vector3(0, 20.6, 0) + out * 0.3, Vector3(seg_len, 1.4, 0.6), b)
		lm.box("White", smid + Vector3(0, 21.6, 0) + out * 0.6, Vector3(seg_len, 0.8, 1.2), b)
	# Order: on the outer fronts Corinthian columns through the two upper
	# floors (paired in the risalits, which add Ionic columns below);
	# pilasters on the court.
	var xs: Array[float] = []
	for i in n + 1:
		var x := s0 + pitch * float(i)
		if proj > 0.0:
			if i == 0:
				xs.append(x + 0.75)
			elif i == n:
				xs.append(x - 0.75)
			else:
				xs.append(x - 0.75)
				xs.append(x + 0.75)
		elif (i > 0 and i < n) or (i == 0 and first) or (i == n and last):
			xs.append(x)
	for x in xs:
		if not outer:
			LandmarkRbParts.pilaster(lm, "White", fo + right * x + out * 0.35 + Vector3(0, 7.45, 0), out, 0.9, 12.0, 0.3)
			continue
		var cp := face + right * x + out * 0.75
		LandmarkRbParts.order_column(lm, "White", cp + Vector3(0, 7.45, 0), 0.5, 11.95, "corinthian", out, 8)
		if proj > 2.0:
			LandmarkRbParts.order_column(lm, "White", cp + Vector3(0, 0.9, 0), 0.42, 6.05, "ionic", out, 8)
		# Statues over the plain fronts, vases over the risalits.
		var top := face + right * x + out * 1.6 + Vector3(0, WP_EAVE, 0)
		if proj == 0.0:
			LandmarkRbParts.figure(lm, "White", top, 2.8, 1.25)
		else:
			LandmarkRbParts.urn(lm, "White", top, 3.0)
	if outer:
		var y := Vector3(0, WP_EAVE, 0) + out * 1.6
		LandmarkRbParts.balustrade(lm, "White", face + right * s0 + y, face + right * (s0 + seg_len) + y, 1.2, 0.85,
			pitch)
