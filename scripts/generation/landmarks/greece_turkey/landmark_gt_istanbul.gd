class_name LandmarkGtIstanbul
extends RefCounted

## Sinan's Suleymaniye Mosque in Istanbul in true metres (the Topkapi
## Palace is LandmarkGtTopkapi).

const SULEY_TOP := 76.0
const HX := 29.25
const HZ := 28.75
const COURT_Z := -75.75
const ARC_H := 5.0
const ARC_TOP := 9.6

## Suleymaniye Mosque (1550-57), origin under the great dome, courtyard
## to -Z and the qibla wall to +Z: the 58.5 x 57.5 m prayer hall, its
## 26.5 m dome on a drum of 32 windows rising to 53 m on the square of
## four weight turrets, with the semi-domes on the qibla axis and the
## arched, windowed tympana either side, five domes of alternating size
## down each aisle; tiers of pointed windows in stone frames, the
## two-storey arcaded galleries along both side facades, the portal on
## the courtyard front; the 57 x 47 m courtyard whose arcade of 24
## columns carries 28 domes, its outer walls and monumental gate, the
## ablution fountain; and the four minarets at its corners, the pair by
## the hall 76 m tall with three balconies, the far pair 56 m with two.
static func suleymaniye(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#CFC6B1", 4.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#E1D9C6", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#767D84", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#B9B1A0", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A352E", 3.0))
	_hall(lm)
	_hall_windows(lm)
	_galleries(lm)
	_courtyard(lm)
	for sx in [-1.0, 1.0]:
		LandmarkGtOttoman.minaret(lm, "Pale", "Lead", "Gilt", Vector3(sx * 30.6, 0, -HZ - 0.4), 2.0, SULEY_TOP,
			[0.53, 0.68, 0.82])
		LandmarkGtOttoman.minaret(lm, "Pale", "Lead", "Gilt", Vector3(sx * 30.6, 0, COURT_Z - 1.2), 1.7, 56.0, [0.62, 0.8])
	lm.commit(model)

## Prayer hall masses: the walls and their cornice, the central square,
## the semi-domes, the four weight turrets, the tympana, the great dome
## with its windows and alem, and the aisle domes.
static func _hall(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Wall", -HX, HX, 0.0, 24.0, -HZ, HZ)
	for e in [[Vector3(-HX, 24.0, HZ), Vector3(HX, 24.0, HZ), Vector3.BACK], [Vector3(HX, 24.0, -HZ), Vector3(-HX, 24.0, -HZ),
			Vector3.FORWARD], [Vector3(HX, 24.0, HZ), Vector3(HX, 24.0, -HZ), Vector3.RIGHT],
			[Vector3(-HX, 24.0, -HZ), Vector3(-HX, 24.0, HZ), Vector3.LEFT]]:
		LandmarkDetail.cornice(lm, "Pale", e[0], e[1], e[2], 0.8, false)
	LandmarkGtUtil.block(lm, "Pale", -HX, HX, 24.0, 24.8, -HZ, HZ)
	LandmarkGtUtil.block(lm, "Wall", -13.25, 13.25, 24.8, 36.5, -13.25, 13.25)
	for end in [-1.0, 1.0]:
		var z0: float = minf(end * 13.25, end * 26.5)
		var z1: float = maxf(end * 13.25, end * 26.5)
		LandmarkGtUtil.block(lm, "Wall", -13.25, 13.25, 24.8, 28.5, z0, z1)
		LandmarkGtUtil.half_dome(lm, "Lead", Vector3(0, 28.5, end * 13.25), 13.25, 11.5, Vector3(0, 0, end), 8, 20)
		# Windows round the semi-dome's foot.
		for k in 7:
			var a := PI * (float(k) + 0.5) / 7.0 - PI * 0.5
			var d := Vector3(sin(a), 0, cos(a) * end)
			LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(0, 25.3, end * 13.25) + d * 13.2, d, 1.1, 2.2, 0.25)
		for sx in [-1.0, 1.0]:
			# Weight turret at each corner of the central square.
			var tp := Vector3(sx * 13.25, 24.8, end * 13.25)
			lm.frustum("Wall", tp, 2.75, 2.55, 14.2, 8, PI / 8.0)
			for k2 in 8:
				var a2 := TAU * float(k2) / 8.0
				var d2 := Vector3(cos(a2), 0, sin(a2))
				LandmarkGtOttoman.window(lm, "Pale", "Dark", tp + d2 * 2.45 + Vector3(0, 10.0, 0), d2, 0.6, 1.6, 0.15)
			LandmarkGtOttoman.small_dome(lm, "Pale", "Lead", "Gilt", tp + Vector3(0, 14.2, 0), 2.4, 0.8, 12)
	# Tympana either side of the central square: great arch and windows.
	for sx in [-1.0, 1.0]:
		var xf: float = sx * 13.25
		var n := Vector3(sx, 0, 0)
		LandmarkGtOttoman.pointed_arch(lm, "Pale", Vector3(xf + sx * 0.1, 25.8, -10.0), Vector3(xf + sx * 0.1, 25.8, 10.0),
			10.0, 0.9, 0.5)
		for row in [[27.0, 5, 1.4, 3.0], [31.2, 4, 1.2, 2.6]]:
			for k in int(row[1]):
				var z := -9.0 + 18.0 * (float(k) + 0.5) / float(row[1])
				LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(xf, float(row[0]), z), n, float(row[2]),
					float(row[3]), 0.3)
	# Great dome, the 32 drum windows between its pilasters, the alem.
	var dc := Vector3(0, 36.5, 0)
	LandmarkKits.dome_on_drum(lm, "Wall", "Lead", dc, 13.25, 4.5, 10.6, 0.9, 40)
	for k in 32:
		var a3 := TAU * (float(k) + 0.25) / 32.0
		var d3 := Vector3(cos(a3), 0, sin(a3))
		LandmarkGtOttoman.window(lm, "Pale", "Windows", dc + d3 * 13.3 + Vector3(0, 0.8, 0), d3, 1.1, 2.9, 0.3)
	lm.frustum("Gilt", Vector3(0, 52.0, 0), 0.18, 0.12, 1.0, 8)
	lm.lathe("Gilt", Vector3(0, 52.6, 0), SEuUtil.dome(0.35, 0.3, 4), 10)
	# Aisle domes, large and small alternating, on low drums.
	for sx2 in [-1.0, 1.0]:
		for i in 5:
			var r := 5.0 if i % 2 == 0 else 3.8
			LandmarkGtOttoman.small_dome(lm, "Wall", "Lead", "Gilt", Vector3(sx2 * 21.2, 24.8, -22.8 + 11.4 * float(i)),
				r, 1.2, 18)

## Tiers of pointed windows on the qibla, side and courtyard facades,
## and the courtyard portal with its muqarnas hood.
static func _hall_windows(lm: LandmarkMesh) -> void:
	var bays := 7
	for i in bays:
		var t := -HX + 2.0 * HX * (float(i) + 0.5) / float(bays)
		for tier in [[2.4, 1.9, 3.2], [9.2, 2.2, 4.4], [16.2, 2.0, 4.0], [21.0, 1.3, 2.2]]:
			LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(t, float(tier[0]), HZ), Vector3.BACK,
				float(tier[1]), float(tier[2]), 0.35)
			if float(tier[0]) > 12.0:
				for sx in [-1.0, 1.0]:
					LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(sx * HX, float(tier[0]), t), Vector3(sx, 0, 0),
						float(tier[1]), float(tier[2]), 0.35)
				if absf(t) > 6.0:
					LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(t, float(tier[0]), -HZ), Vector3.FORWARD,
						float(tier[1]), float(tier[2]), 0.35)
	# Portal: projecting frame, dark doorway, muqarnas hood in tiers.
	var pz := -HZ
	LandmarkGtUtil.block(lm, "Pale", -4.5, 4.5, 0.0, 15.5, pz - 1.2, pz)
	LandmarkGtUtil.block(lm, "Dark", -1.6, 1.6, 0.0, 5.2, pz - 1.25, pz - 1.2)
	for k in 5:
		var w := 6.4 - 0.9 * float(k)
		LandmarkGtUtil.block(lm, "Pale", -w * 0.5, w * 0.5, 13.2 - 1.2 * float(k), 13.8 - 1.2 * float(k),
			pz - 1.25 - 0.18 * float(k), pz - 1.2)
	LandmarkGtOttoman.pointed_arch(lm, "Pale", Vector3(-3.4, 8.0, pz - 1.3), Vector3(3.4, 8.0, pz - 1.3), 5.6, 0.6, 0.35)
	LandmarkDetail.cornice(lm, "Pale", Vector3(-4.6, 15.5, pz - 1.2), Vector3(4.6, 15.5, pz - 1.2), Vector3.FORWARD, 0.6,
		false)

## Two-storey arcaded galleries along both side facades: piers and
## columns, pointed arches on both storeys, the upper floor, its
## parapet and the lead lean-to roof against the wall.
static func _galleries(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var xo: float = sx * (HX + 4.2)
		var z0 := -23.0
		var z1 := 23.0
		var n := 9
		LandmarkGtUtil.block(lm, "Pale", minf(sx * HX, xo), maxf(sx * HX, xo), 0.0, 0.5, z0 - 0.8, z1 + 0.8)
		var y0 := 0.5
		for st in 2:
			var ch := 4.0 if st == 0 else 3.0
			for k in n + 1:
				var z := lerpf(z0, z1, float(k) / float(n))
				LandmarkGtOttoman.column(lm, "Pale", Vector3(xo, y0, z), 0.42 if st == 0 else 0.34, ch)
			for k2 in n:
				var za := lerpf(z0, z1, float(k2) / float(n))
				var zb := lerpf(z0, z1, float(k2 + 1) / float(n))
				LandmarkGtOttoman.pointed_arch(lm, "Pale", Vector3(xo, y0 + ch, za), Vector3(xo, y0 + ch, zb), 2.6, 0.4, 0.8)
			var sp := y0 + ch + 3.0
			LandmarkGtUtil.block(lm, "Wall", minf(sx * HX, xo - sx * 0.4), maxf(sx * HX, xo + sx * 0.4), sp, sp + 0.6, z0 - 0.8,
				z1 + 0.8)
			if st == 0:
				LandmarkGtUtil.block(lm, "Pale", xo - 0.3, xo + 0.3, sp + 0.6, sp + 1.6, z0 - 0.8, z1 + 0.8)
			y0 = sp + 0.6
		var ry := y0
		var hi := Vector3(sx * HX, ry + 0.9, 0)
		var lo := Vector3(xo + sx * 0.6, ry, 0)
		lm.quad("Lead", hi + Vector3(0, 0, z0 - 0.9), hi + Vector3(0, 0, z1 + 0.9), lo + Vector3(0, 0, z1 + 0.9),
			lo + Vector3(0, 0, z0 - 0.9), Vector3(sx * 0.9, 4.8, 0).normalized())
		for ez in [z0 - 0.8, z1 + 0.8]:
			LandmarkGtUtil.block(lm, "Wall", minf(sx * HX, xo + sx * 0.6), maxf(sx * HX, xo + sx * 0.6), 0.0, ry,
				float(ez) - 0.6, float(ez) + 0.6)

## Courtyard: paving, the arcade of 24 columns with pointed arches and
## 28 domes, the outer walls with their windows, the gate and the
## ablution fountain.
static func _courtyard(lm: LandmarkMesh) -> void:
	var cx := 28.5
	var zf := -HZ
	var zb := COURT_Z
	var ix := cx - 6.333
	var zi_f := zf - 6.25
	var zi_b := zb + 6.25
	LandmarkGtUtil.block(lm, "Court", -cx, cx, 0.0, 0.15, zb, zf)
	# Arcade columns: 8 along each long side, 4 more along each short side.
	var cols: Array = []
	for k in 8:
		var x := -ix + 2.0 * ix * float(k) / 7.0
		cols.append(Vector3(x, 0.15, zi_f))
		cols.append(Vector3(x, 0.15, zi_b))
	for j in range(1, 5):
		var z := zi_f + (zi_b - zi_f) * float(j) / 5.0
		cols.append(Vector3(-ix, 0.15, z))
		cols.append(Vector3(ix, 0.15, z))
	for p in cols:
		LandmarkGtOttoman.column(lm, "Pale", p, 0.45, ARC_H)
	# Arches along the inner lines, the roof slab with its cornice.
	var lines := [[Vector3(-ix, 0, zi_f), Vector3(ix, 0, zi_f), 7], [Vector3(-ix, 0, zi_b), Vector3(ix, 0, zi_b), 7],
		[Vector3(-ix, 0, zi_f), Vector3(-ix, 0, zi_b), 5], [Vector3(ix, 0, zi_f), Vector3(ix, 0, zi_b), 5]]
	for ln in lines:
		var a: Vector3 = ln[0]
		var b: Vector3 = ln[1]
		var nb: int = ln[2]
		for k in nb:
			var pa := a.lerp(b, float(k) / float(nb)) + Vector3(0, ARC_H + 0.15, 0)
			var pb := a.lerp(b, float(k + 1) / float(nb)) + Vector3(0, ARC_H + 0.15, 0)
			LandmarkGtOttoman.pointed_arch(lm, "Pale", pa, pb, pa.distance_to(pb) * 0.52, 0.5, 0.95)
	for band in [[-cx, cx, zi_f - 0.6, zf], [-cx, cx, zb, zi_b + 0.6], [-cx, -ix + 0.6, zi_b, zi_f], [ix - 0.6, cx, zi_b, zi_f]]:
		LandmarkGtUtil.block(lm, "Pale", band[0], band[1], ARC_TOP - 0.6, ARC_TOP, band[2], band[3])
	for e in [[Vector3(-ix - 0.6, ARC_TOP - 0.6, zi_f - 0.6), Vector3(ix + 0.6, ARC_TOP - 0.6, zi_f - 0.6), Vector3.FORWARD],
			[Vector3(ix + 0.6, ARC_TOP - 0.6, zi_b + 0.6), Vector3(-ix - 0.6, ARC_TOP - 0.6, zi_b + 0.6), Vector3.BACK]]:
		LandmarkDetail.cornice(lm, "Pale", e[0], e[1], e[2], 0.45, false)
	# Spandrel walls over the arches up to the roof slab.
	for ln2 in lines:
		var a2: Vector3 = ln2[0]
		var b2: Vector3 = ln2[1]
		var dir := (b2 - a2).normalized()
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		lm.box("Wall", (a2 + b2) * 0.5 + Vector3(0, ARC_TOP - 1.2, 0), Vector3(a2.distance_to(b2) + 1.0, 1.2, 0.9), bas)
	# The 28 domes: nine on each long side (the middle one over the hall
	# portico larger), five down each short side.
	for k in 9:
		var x2 := -cx + 2.0 * cx * (float(k) + 0.5) / 9.0
		LandmarkGtOttoman.small_dome(lm, "Wall", "Lead", "Gilt", Vector3(x2, ARC_TOP, (zf + zi_f) * 0.5),
			3.3 if k == 4 else 2.8, 1.0, 16)
		LandmarkGtOttoman.small_dome(lm, "Wall", "Lead", "Gilt", Vector3(x2, ARC_TOP, (zb + zi_b) * 0.5), 2.8, 1.0, 16)
	for j in 5:
		var z2 := zi_f + (zi_b - zi_f) * (float(j) + 0.5) / 5.0
		for sx in [-1.0, 1.0]:
			LandmarkGtOttoman.small_dome(lm, "Wall", "Lead", "Gilt", Vector3(sx * (cx + ix) * 0.5, ARC_TOP, z2), 2.8, 1.0, 16)
	# Outer walls with a window in every bay, and the gate.
	LandmarkGtUtil.block(lm, "Wall", -cx, cx, 0.0, ARC_TOP - 0.6, zb - 1.2, zb)
	for sx2 in [-1.0, 1.0]:
		LandmarkGtUtil.block(lm, "Wall", sx2 * cx - 0.6, sx2 * cx + 0.6, 0.0, ARC_TOP - 0.6, zb, zf)
		for j2 in 5:
			var z3 := zi_f + (zi_b - zi_f) * (float(j2) + 0.5) / 5.0
			LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(sx2 * (cx + 0.6), 1.6, z3), Vector3(sx2, 0, 0), 1.4, 3.0, 0.3)
	for k2 in 9:
		if k2 == 4:
			continue
		var x3 := -cx + 2.0 * cx * (float(k2) + 0.5) / 9.0
		LandmarkGtOttoman.window(lm, "Pale", "Windows", Vector3(x3, 1.6, zb - 1.2), Vector3.FORWARD, 1.4, 3.0, 0.3)
	LandmarkGtUtil.block(lm, "Pale", -4.0, 4.0, 0.0, 13.0, zb - 2.2, zb + 0.4)
	LandmarkGtUtil.block(lm, "Dark", -1.5, 1.5, 0.0, 4.6, zb - 2.25, zb - 2.2)
	for k3 in 4:
		var w := 5.6 - 0.9 * float(k3)
		LandmarkGtUtil.block(lm, "Pale", -w * 0.5, w * 0.5, 10.8 - 1.0 * float(k3), 11.3 - 1.0 * float(k3),
			zb - 2.25 - 0.16 * float(k3), zb - 2.2)
	LandmarkGtOttoman.pointed_arch(lm, "Pale", Vector3(-3.0, 6.5, zb - 2.3), Vector3(3.0, 6.5, zb - 2.3), 4.8, 0.55, 0.3)
	LandmarkDetail.cornice(lm, "Pale", Vector3(-4.1, 13.0, zb - 2.2), Vector3(4.1, 13.0, zb - 2.2), Vector3.FORWARD, 0.5, false)
	# Ablution fountain: an octagonal basin, columns and a lead roof.
	var fc := Vector3(0, 0.15, (zf + zb) * 0.5)
	lm.frustum("Pale", fc, 3.6, 3.4, 0.9, 8, PI / 8.0)
	lm.frustum("Pale", fc + Vector3(0, 0.9, 0), 2.2, 2.2, 2.2, 8, PI / 8.0)
	for k4 in 8:
		var af := TAU * float(k4) / 8.0
		LandmarkGtOttoman.column(lm, "Pale", fc + Vector3(cos(af) * 3.0, 0.9, sin(af) * 3.0), 0.2, 3.0)
	lm.frustum("Lead", fc + Vector3(0, 3.9, 0), 4.2, 1.2, 1.4, 8, PI / 8.0)
	LandmarkGtOttoman.small_dome(lm, "Pale", "Lead", "Gilt", fc + Vector3(0, 5.3, 0), 1.3, 0.4, 12)
