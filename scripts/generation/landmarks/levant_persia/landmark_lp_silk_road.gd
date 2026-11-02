class_name LandmarkLpSilkRoad
extends RefCounted

## Persian and Timurid Islamic architecture in true metres: the Imam
## (Shah) Mosque of Isfahan and the Po-i-Kalyan complex of Bukhara (the
## Registan is in LandmarkLpRegistan). Glazed tile (cobalt, turquoise)
## over baked brick, tall pointed iwan portals (pishtaqs), bulbous domes
## and tapering minarets.

# --- Imam (Shah) Mosque, Isfahan ---

## Built with the portal facing +Z (yaw 177 turns it onto the north-facing
## square). The courtyard turned 45 degrees to the qibla (axis towards +X,
## -Z) with four iwans and two storeys of tiled arched niches between
## them, each in its frame; the sanctuary with the 52 m double-shell dome
## (turquoise bulb on a windowed cobalt drum with its inscription band)
## and the 48 m minarets at its iwan; the domed halls through the side
## iwans; the 33 m vestibule dome and the 27.5 m entrance portal with its
## muqarnas hood between minarets whose galleries stand at 33.5 m, between
## the two arcaded wings on the square.
static func imam_mosque(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C8A569", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2459A8", 2.0, 0.34))
	lm.use("Turq", LandmarkMaterials.pbr("render", "#2BA7B0", 2.0, 0.3))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E6D9B6", 2.0, 0.5))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CBB890", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#17120E", 3.0, 0.92))
	lm.use("Gold", LandmarkMaterials.gold())
	var phi := -PI * 0.25
	var rot := Basis(Vector3.UP, phi)
	lm.box("Court", Vector3(0, 0.1, 0), Vector3(80, 0.2, 80), rot, 0.0)
	lm.box("Dark", Vector3(0, 0.25, 0), Vector3(20, 0.1, 12), rot, 0.0)
	# Courtyard walls (two storeys of framed niches) with the four iwans.
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var turn := Basis(Vector3.UP, yaw)
		var inward := turn * Vector3(0, 0, 1)
		var along := turn * Vector3(1, 0, 0)
		var sanct := k == 0
		var iw := 32.0 if sanct else 24.0
		var seg := (70.0 - iw) * 0.5
		for s in [-1.0, 1.0]:
			var cu: float = s * (iw * 0.5 + seg * 0.5)
			var wc := -inward * 37.5 + along * cu
			lm.box("Brick", rot * (wc + along * (float(s) * 2.5) + Vector3(0, 7.0, 0)), Vector3(seg + 5.0, 14.0, 5.0),
				rot * turn)
			lm.box("Turq", rot * (wc + Vector3(0, 14.3, 0) + inward * 2.2), Vector3(seg, 0.6, 0.8), rot * turn)
			var face := rot * (-inward * 35.0 + along * cu)
			var n := int(seg / 5.6)
			var lower := LandmarkLpDetail.bays(n, seg, 1.8, 3.4, 2.3)
			var upper := LandmarkLpDetail.bays(n, seg, 1.6, 2.6, 2.0)
			LandmarkLpDetail.arcade_skin(lm, "Tile", "Dark", face + Vector3(0, 0.2, 0), yaw + phi, seg, 7.0, lower, 0.7, 6)
			LandmarkLpDetail.arcade_skin(lm, "Tile", "Dark", face + Vector3(0, 7.2, 0), yaw + phi, seg, 6.8, upper, 0.7, 6)
			for ar in lower:
				var u: float = ar[0]
				var r := rot * along
				LandmarkLpDetail.alfiz(lm, "Turq", face + r * u + Vector3(0, 0.2, 0), yaw + phi, 1.8, 6.1, 0.24, 0.05)
				LandmarkLpDetail.alfiz(lm, "Turq", face + r * u + Vector3(0, 7.2, 0), yaw + phi, 1.6, 5.0, 0.22, 0.05)
		var front := rot * (-inward * 34.0) + Vector3(0, 0.2, 0)
		var ih := 34.0 if sanct else 21.0
		var a := 7.5 if sanct else 5.0
		var sp := 17.0 if sanct else 10.0
		var ri := 11.5 if sanct else 7.0
		LandmarkLpParts.iwan(lm, "Tile", "Dark", front, yaw + phi, iw, ih, a, sp, ri, 8.0 if sanct else 5.0)
		_pishtaq_dress(lm, front, yaw + phi, iw, ih, a, sp, ri)
	# Sanctuary: iwan hall, dome chamber, side prayer halls, the 52 m dome, minarets.
	lm.box("Brick", rot * Vector3(0, 14.0, -48.0), Vector3(32, 28.0, 12), rot)
	lm.box("Brick", rot * Vector3(0, 13.5, -72.0), Vector3(36, 27.0, 36), rot)
	lm.box("Tile", rot * Vector3(0, 27.4, -72.0), Vector3(36.6, 0.8, 36.6), rot)
	for s in [-1.0, 1.0]:
		var hp := rot * Vector3(float(s) * 28.0, 0, -72.0)
		lm.box("Brick", hp + Vector3(0, 8.0, 0), Vector3(20, 16.0, 36), rot)
		_drum(lm, hp + Vector3(0, 16.0, 0), 6.0, 3.0, 12)
		lm.lathe("Turq", hp + Vector3(0, 19.0, 0), LandmarkLpParts.bulb_profile(6.2, 7.5, 1.08), 24)
		LandmarkLpDetail.tile_minaret(lm, "Brick", "Tile", rot * Vector3(float(s) * 18.5, 0, -39.0), 2.2, 48.0,
			38.0, "Gold")
	var dc := rot * Vector3(0, 0, -72.0)
	_drum(lm, dc + Vector3(0, 27.8, 0), 12.5, 7.4, 16)
	lm.lathe("Turq", dc + Vector3(0, 35.2, 0), LandmarkLpParts.bulb_profile(12.7, 15.6, 1.1, 16, 1.25), 40)
	LandmarkLpParts.needle(lm, "Gold", dc + Vector3(0, 50.8, 0),
		PackedVector2Array([Vector2(0, 0.4), Vector2(0.4, 0.3), Vector2(0.7, 0.12), Vector2(1.2, 0.06)]), 8)
	# Entrance: wings on the square, vestibule dome, portal and its minarets.
	var zf := 68.0
	for s in [-1.0, 1.0]:
		var wc := Vector3(-30.0 + float(s) * 31.0, 0, zf - 3.0)
		lm.box("Brick", wc + Vector3(0, 6.5, 0), Vector3(32, 13.0, 6.0))
		lm.box("Turq", wc + Vector3(0, 13.3, 0.6), Vector3(32.4, 0.6, 5.2))
		var lower := LandmarkLpDetail.bays(5, 32.0, 2.0, 3.4, 2.4)
		var upper := LandmarkLpDetail.bays(5, 32.0, 1.7, 2.6, 2.0)
		LandmarkLpDetail.arcade_skin(lm, "Brick", "Dark", wc + Vector3(0, 0.2, 3.7), 0.0, 32.0, 6.6, lower, 0.7, 6)
		LandmarkLpDetail.arcade_skin(lm, "Brick", "Dark", wc + Vector3(0, 6.8, 3.7), 0.0, 32.0, 6.2, upper, 0.7, 6)
		for ar in lower:
			LandmarkLpDetail.alfiz(lm, "Tile", wc + Vector3(float(ar[0]), 0.2, 3.7), 0.0, 2.0, 6.2, 0.25, 0.05)
	lm.box("Brick", Vector3(-30.0, 10.0, 46.0), Vector3(26, 20.0, 30))
	_drum(lm, Vector3(-30.0, 20.0, 46.0), 9.0, 4.0, 12)
	lm.lathe("Turq", Vector3(-30.0, 24.0, 46.0), LandmarkLpParts.bulb_profile(9.2, 9.0, 1.1), 32)
	var pf := Vector3(-30.0, 0.2, zf + 1.0)
	LandmarkLpParts.iwan(lm, "Tile", "Dark", pf, 0.0, 30.0, 27.3, 6.6, 14.0, 8.8, 8.0)
	_pishtaq_dress(lm, pf, 0.0, 30.0, 27.3, 6.6, 14.0, 8.8)
	for s in [-1.0, 1.0]:
		LandmarkLpDetail.tile_minaret(lm, "Brick", "Tile", Vector3(-30.0 + float(s) * 12.8, 0, zf - 3.0), 1.9, 42.0,
			33.5, "Gold")
	lm.commit(model)

## Tile dress of an iwan front (front plane `front`, the face pw x ph, the
## niche a / spring / rise): turquoise frame, cream inscription band under
## the cornice, the cable archivolt and the stepped muqarnas hood.
static func _pishtaq_dress(lm: LandmarkMesh, front: Vector3, yaw: float, pw: float, ph: float, a: float,
		spring: float, rise: float) -> void:
	var f := LandmarkLpParts.outward(yaw)
	LandmarkLpDetail.alfiz(lm, "Turq", front, yaw, pw * 0.5 - 1.0, ph - 1.2, 0.6, 0.15)
	LandmarkLpDetail.alfiz(lm, "Cream", front, yaw, a + 0.9, spring + rise + 1.0, 0.45, 0.1)
	lm.box("Cream", front + f * 0.1 + Vector3(0, ph - 2.3, 0), Vector3(pw - 3.0, 1.0, 0.2), Basis(Vector3.UP, yaw), 0.0)
	LandmarkLpDetail.arch_band(lm, "Turq", front, yaw, a, spring, rise, 0.4, 0.08, 8)
	LandmarkLpDetail.muqarnas_hood(lm, "Cream", front, yaw, a, spring, rise, 4, 0.8)

## Cobalt drum with `n` grilled windows, a cream inscription band and a
## turquoise cornice ring.
static func _drum(lm: LandmarkMesh, base: Vector3, r: float, h: float, n: int) -> void:
	lm.frustum("Tile", base, r, r, h, 40)
	lm.frustum("Cream", base + Vector3(0, h * 0.68, 0), r + 0.06, r + 0.06, h * 0.2, 40)
	lm.frustum("Turq", base + Vector3(0, h - 0.4, 0), r + 0.1, r + 0.3, 0.4, 40)
	for k in n:
		var t := TAU * (float(k) + 0.5) / float(n)
		var d := Vector3(cos(t), 0, sin(t))
		LandmarkLpParts.arch_panel(lm, "Dark", base + d * (r + 0.02) + Vector3(0, h * 0.12, 0), PI * 0.5 - t,
			r * 0.07, h * 0.32, r * 0.08)

# --- Kalyan Minaret and Po-i-Kalyan, Bukhara ---

## The baked-brick Kalyan Minaret (1127, 45.6 m to the lantern cornice, 9 m
## across at the base, 6 m at the top) at the south-east corner of the
## Kalyan Mosque (about 127 x 78 m): its court ringed by arcaded galleries
## under 288 small domes, the tiled east portal and the blue 30 m dome on
## its drum over the west sanctuary. The Mir-i-Arab Madrasa (1535, 73 x 55
## m) faces it from the east with its portal, two blue domes and corner
## guldastas; bazaar and baths close the square on the north and south.
## Compass frame.
static func kalyan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C4A068", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2A63B0", 2.0, 0.34))
	lm.use("Turq", LandmarkMaterials.pbr("render", "#30AEB6", 2.0, 0.3))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CBB78E", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#17120E", 3.0, 0.92))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E6D9B6", 2.0, 0.5))
	lm.box("Court", Vector3(-30, 0.1, -5), Vector3(176, 0.2, 90), Basis(), 0.0)
	_kalyan_mosque(lm)
	# Mir-i-Arab Madrasa (east, faces west), its two blue domes, guldastas.
	LandmarkLpRegistan.madrasa(lm, Vector3(62, 0.2, -5.0), -PI * 0.5, 73.0, 55.0, 14.0, 24.0, 30.0, 6.0, 15.0,
		9.5, 0.0)
	for s in [-1.0, 1.0]:
		var dp := Vector3(62.0 + 20.0, 14.0, -5.0 + float(s) * 16.0)
		_drum(lm, dp, 7.5, 6.0, 12)
		lm.lathe("Turq", dp + Vector3(0, 6.0, 0), LandmarkLpParts.bulb_profile(7.8, 11.0, 1.1, 12, 1.2), 32)
	# Bazaar (north) and baths (south) of the square with their small domes.
	for z in [-49.0, 40.0]:
		lm.box("Brick", Vector3(32, 3.5, z), Vector3(60, 7.0, 10.0))
		for i in 8:
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(5.5 + 7.5 * float(i), 0.2, float(z) + 5.02 * (1.0 if z < 0.0 else -1.0)),
				0.0 if z < 0.0 else PI, 1.2, 2.2, 1.4)
		for x in [16.0, 28.0, 40.0, 52.0]:
			_small_dome(lm, Vector3(float(x), 7.0, float(z)), 3.4)
	_kalyan_minaret(lm, Vector3(8.0, 0, 50.5))
	lm.commit(model)

## Kalyan Mosque: outer walls, the gallery bays round the court each under
## its own small dome, the arcaded court fronts, east portal, west dome.
static func _kalyan_mosque(lm: LandmarkMesh) -> void:
	var x0 := -118.0
	var x1 := -2.0
	var z0 := -44.0
	var z1 := 34.0
	var wh := 9.0
	var pitch := 4.6
	# Courtyard (inside the galleries): x -88 .. -14, z -30 .. 20.
	var cx0 := -88.0
	var cx1 := -14.0
	var cz0 := -30.0
	var cz1 := 20.0
	# Gallery masses: north, south, east ranges and the west sanctuary block.
	lm.box("Brick", Vector3((x0 + x1) * 0.5, wh * 0.5, (z0 + cz0) * 0.5), Vector3(x1 - x0, wh, cz0 - z0))
	lm.box("Brick", Vector3((x0 + x1) * 0.5, wh * 0.5, (cz1 + z1) * 0.5), Vector3(x1 - x0, wh, z1 - cz1))
	lm.box("Brick", Vector3((cx1 + x1) * 0.5, wh * 0.5, (cz0 + cz1) * 0.5), Vector3(x1 - cx1, wh, cz1 - cz0))
	lm.box("Brick", Vector3((x0 + cx0) * 0.5, wh * 0.5, (cz0 + cz1) * 0.5), Vector3(cx0 - x0, wh, cz1 - cz0))
	# Small domes over every gallery bay (skipping the main dome and portal).
	var dc := Vector3(-103.0, 0, -5.0)
	var n_x := int((x1 - x0) / pitch)
	var n_z := int((z1 - z0) / pitch)
	for i in n_x:
		for j in n_z:
			var p := Vector3(x0 + pitch * (float(i) + 0.5), wh, z0 + pitch * (float(j) + 0.5))
			var in_court := p.x > cx0 and p.x < cx1 and p.z > cz0 and p.z < cz1
			var under_dome := absf(p.x - dc.x) < 13.0 and absf(p.z - dc.z) < 13.0
			if in_court or under_dome or (p.x > cx1 and absf(p.z + 5.0) < 13.0):
				continue
			_small_dome(lm, p, 1.9)
	# Arcaded court fronts: pointed arches in a tiled-frame brick skin.
	var fronts := [[Vector3((cx0 + cx1) * 0.5, 0.2, cz0), PI * 0.0, cx1 - cx0],
		[Vector3((cx0 + cx1) * 0.5, 0.2, cz1), PI, cx1 - cx0],
		[Vector3(cx1, 0.2, (cz0 + cz1) * 0.5), -PI * 0.5, cz1 - cz0],
		[Vector3(cx0, 0.2, (cz0 + cz1) * 0.5), PI * 0.5, cz1 - cz0]]
	for fr in fronts:
		var fp: Vector3 = fr[0]
		var yaw: float = fr[1]
		var w: float = fr[2]
		var n := int(w / pitch)
		var ar := LandmarkLpDetail.bays(n, w, 1.5, 3.4, 2.0)
		LandmarkLpDetail.arcade_skin(lm, "Brick", "Dark", fp + LandmarkLpParts.outward(yaw) * 0.6, yaw, w, wh - 0.2,
			ar, 0.6, 6)
		lm.box("Tile", fp + LandmarkLpParts.outward(yaw) * 0.7 + Vector3(0, wh - 1.2, 0),
			Vector3(absf(LandmarkLpParts.across(yaw).x) * w + 0.1, 0.5, absf(LandmarkLpParts.across(yaw).z) * w + 0.1),
			Basis(), 0.0)
	# West sanctuary: pishtaq on the court, drum and the 30 m blue dome.
	var sf := Vector3(cx0 + 1.0, 0.2, -5.0)
	LandmarkLpParts.iwan(lm, "Tile", "Dark", sf, PI * 0.5, 20.0, 21.0, 4.5, 10.0, 6.5, 5.0)
	_pishtaq_dress(lm, sf, PI * 0.5, 20.0, 21.0, 4.5, 10.0, 6.5)
	lm.box("Brick", dc + Vector3(0, 8.0, 0), Vector3(24, 16.0, 24))
	_drum(lm, dc + Vector3(0, 16.0, 0), 8.6, 5.0, 16)
	lm.lathe("Turq", dc + Vector3(0, 21.0, 0), LandmarkLpParts.bulb_profile(8.8, 8.2, 1.08, 14, 1.1), 40)
	LandmarkLpParts.needle(lm, "Turq", dc + Vector3(0, 29.2, 0), PackedVector2Array([Vector2(0, 0.25), Vector2(0.8, 0.06)]), 8)
	# East portal on the square: tall pishtaq with corner turrets.
	var ef := Vector3(3.5, 0.2, -5.0)
	LandmarkLpParts.iwan(lm, "Tile", "Dark", ef, PI * 0.5, 24.0, 28.0, 6.0, 14.0, 9.5, 6.0)
	_pishtaq_dress(lm, ef, PI * 0.5, 24.0, 28.0, 6.0, 14.0, 9.5)
	for s in [-1.0, 1.0]:
		var g := Vector3(1.8, 0.2, -5.0 + float(s) * 12.4)
		lm.frustum("Brick", g, 1.4, 1.2, 28.6, 16)
		lm.frustum("Tile", g + Vector3(0, 28.6, 0), 1.5, 1.5, 0.5, 16)
		lm.lathe("Turq", g + Vector3(0, 29.1, 0), LandmarkLpParts.bulb_profile(1.2, 1.6, 1.1, 6, 1.2), 12)
	# Outer corner turrets of the mosque.
	for c in [Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3(x1, 0, z0)]:
		lm.frustum("Brick", (c as Vector3) + Vector3(0, 0.2, 0), 2.4, 2.1, wh + 2.0, 16)
		lm.lathe("Brick", (c as Vector3) + Vector3(0, wh + 2.2, 0), LandmarkLpParts.dome_profile(2.2, 1.8, 4), 12)

static func _small_dome(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	lm.frustum("Brick", base, r * 1.05, r * 1.0, r * 0.25, 8)
	lm.lathe("Brick", base + Vector3(0, r * 0.25, 0), LandmarkLpParts.dome_profile(r, r * 0.8, 3), 8)

## The minaret: stone plinth with three limestone bands, the tapering
## brick shaft (9 m to 6 m across) girdled by fourteen ornamental brick
## belts (lozenge bonding on every other one) and the blue-glazed
## inscription frieze, the muqarnas cornice, the sixteen-arched lantern,
## its crowning cornice and the low cap (47 m).
static func _kalyan_minaret(lm: LandmarkMesh, base: Vector3) -> void:
	lm.frustum("Brick", base, 5.4, 5.3, 1.4, 24)
	for k in 3:
		lm.frustum("Cream", base + Vector3(0, 0.15 + 0.42 * float(k), 0), 5.45, 5.45, 0.22, 24)
	var sb := base + Vector3(0, 1.4, 0)
	var sh := 35.1
	var r0 := 4.5
	var r1 := 3.0
	lm.lathe("Brick", sb, PackedVector2Array([Vector2(r0, 0.0), Vector2(lerpf(r0, r1, 0.45), sh * 0.5),
		Vector2(r1, sh)]), 32)
	for k in 14:
		var y := 1.6 + 2.45 * float(k)
		var rr := lerpf(r0, r1, (y - 0.8) / sh) + 0.05
		lm.frustum("Brick", sb + Vector3(0, y, 0), rr, rr - 0.01, 0.35, 32)
		if k % 2 == 1:
			var n := int(TAU * rr / 0.9)
			for i in n:
				var a := TAU * (float(i) + 0.5) / float(n)
				var d := Vector3(cos(a), 0, sin(a))
				lm.box("Brick", sb + d * (rr - 0.02) + Vector3(0, y + 1.2, 0), Vector3(0.45, 0.45, 0.1),
					Basis.looking_at(d) * Basis(Vector3(0, 0, 1), PI * 0.25), 0.0)
	var rt := lerpf(r0, r1, 31.0 / sh) + 0.08
	lm.frustum("Tile", sb + Vector3(0, 30.6, 0), rt, rt - 0.02, 1.6, 32)
	# Muqarnas cornice: five corbel rings flaring out under the lantern.
	var cb := sb + Vector3(0, sh, 0)
	for k in 5:
		var t0 := float(k) / 5.0
		var t1 := float(k + 1) / 5.0
		lm.frustum("Brick", cb + Vector3(0, 0.7 * float(k), 0), lerpf(r1, 4.3, t0 * t0), lerpf(r1, 4.3, t1 * t1), 0.7, 32)
	lm.frustum("Brick", cb + Vector3(0, 3.5, 0), 4.4, 4.4, 0.4, 32)
	# Lantern: sixteen arched openings between brick piers.
	var lb := cb + Vector3(0, 3.9, 0)
	lm.frustum("Brick", lb, 3.1, 3.1, 4.6, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkLpParts.arch_panel(lm, "Dark", lb + d * 3.12 + Vector3(0, 0.6, 0), PI * 0.5 - a, 0.42, 2.0, 0.6)
		var dp := Vector3(cos(a + PI / 16.0), 0, sin(a + PI / 16.0))
		lm.box("Brick", lb + dp * 3.15 + Vector3(0, 2.0, 0), Vector3(0.4, 4.0, 0.3), Basis.looking_at(dp))
	lm.frustum("Tile", lb + Vector3(0, 3.6, 0), 3.18, 3.18, 0.5, 32)
	lm.frustum("Brick", lb + Vector3(0, 4.6, 0), 3.15, 3.5, 0.5, 32)
	lm.lathe("Brick", lb + Vector3(0, 5.1, 0), PackedVector2Array([Vector2(3.4, 0.0), Vector2(2.4, 0.45),
		Vector2(1.0, 0.75), Vector2(0.1, 0.8)]), 24)
