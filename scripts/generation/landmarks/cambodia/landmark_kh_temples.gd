class_name LandmarkKhTemples
extends RefCounted

## Khmer temples away from Angkor Thom in true metres: Banteay Srei, Phnom
## Bakheng, Preah Vihear and the Koh Ker pyramid.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const SREI = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_srei.gd")

## Banteay Srei (9.8 m): the miniature pink-sandstone temple with its carved
## pediments, built by landmark_kh_srei.gd. Built facing +X (east).
static func banteay_srei(model: Node3D) -> void:
	SREI.build(model)

## Phnom Bakheng (22 m): the temple-mountain pyramid (c. 900) on its hill:
## a laterite base and five receding sandstone tiers, 76 m square at the
## foot narrowing to 47 m at the summit, 13 m high, with a stair up the
## middle of each face; the 108 towers of the cosmic plan: 44 brick towers
## round the foot, twelve small sandstone towers on every tier (60) and the
## quincunx of five sanctuary towers on top. The hill itself is terrain,
## not part of the model. Built facing +X (east).
static func phnom_bakheng(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A7A62", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#9C8C72", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E5A3E", 3.0))
	lm.box("Laterite", Vector3(0, 1.0, 0), Vector3(76.0, 2.0, 76.0))
	lm.box("Laterite", Vector3(0, 0.2, 0), Vector3(77.0, 0.4, 77.0))
	lm.box("Trim", Vector3(0, 1.85, 0), Vector3(76.6, 0.3, 76.6))
	var widths: Array[float] = [35.0, 32.1, 29.2, 26.4, 23.5]
	var y := 2.0
	for j in 5:
		var w := widths[j]
		# Tier: moulded base, die, cornice.
		lm.box("Stone", Vector3(0, y + 0.2, 0), Vector3(w * 2.0 + 0.5, 0.4, w * 2.0 + 0.5))
		lm.box("Stone", Vector3(0, y + 1.2, 0), Vector3(w * 2.0, 2.4, w * 2.0))
		lm.box("Trim", Vector3(0, y + 1.6, 0), Vector3(w * 2.0 + 0.2, 0.2, w * 2.0 + 0.2), Basis(), 0.0)
		lm.box("Trim", Vector3(0, y + 2.25, 0), Vector3(w * 2.0 + 0.7, 0.3, w * 2.0 + 0.7))
		# Twelve small towers a tier: three a side, pairs flanking each stair.
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for t in [-1.0, -0.5, 0.5]:
				var tx: float = t * (w - 1.6)
				if absf(tx) < 4.0:
					tx = signf(tx) * 4.2
				U.small_tower(lm, "Trim", b * Vector3(tx, y + 2.4, w - 1.6), 0.7, 2.6)
		y += 2.4
	# Stairs up every face: the base, then tier by tier, with stepped
	# cheek walls (lions once sat on them).
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.stair(lm, "Stone", b * Vector3(0, 0.0, 38.0), b, 6.0, 5, 0.8, 0.4)
		for sx in [-1.0, 1.0]:
			lm.box("Trim", b * Vector3(sx * 3.4, 1.0, 40.0), Vector3(0.8, 2.0, 4.0), b)
		for j in 5:
			var yb: float = 2.0 + 2.4 * float(j)
			U.stair(lm, "Stone", b * Vector3(0, yb, widths[j]), b, 5.0, 6, 0.48, 0.4)
			for sx in [-1.0, 1.0]:
				lm.box("Trim", b * Vector3(sx * 2.9, yb + 1.4, widths[j] + 1.4), Vector3(0.8, 2.8, 2.8), b)
	# 44 brick towers round the foot of the pyramid (eleven a side, a gap
	# at each stair).
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for i in 12:
			var tx := -36.0 + 72.0 * float(i) / 11.0
			if absf(tx) < 4.0:
				continue
			U.small_tower(lm, "Brick", b * Vector3(tx, 0.0, 41.5), 1.0, 4.0)
	# Quincunx on the summit: the central tower and four corner towers.
	var top := 14.0
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, top, 0), 3.0, 8.0, 3, 0.28)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.prasat(lm, "Stone", "Trim", "Dark", Vector3(sx * 9.5, top, sz * 9.5), 2.1, 6.0, 3, 0.28)
	lm.commit(model)

## Preah Vihear (26 m): the temple on the Dangrek cliff edge, its 800 m
## north-south axis compressed to 160 m from the great stair end to the
## sanctuary: five gopuras on rising terraces joined by steep stairs (naga
## balustrades on the upper flights), avenues lined with lotus-bud posts,
## the walled sanctuary court and the lotus-bud central tower. Built with the sanctuary toward -Z; the
## registry yaw (180) puts it on the south end, facing the stair to the north.
static func preah_vihear(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A8D70", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#B2A688", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#26231F", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#6F6454", 6.0))
	# Terraces (z from, z to, height) rising toward the sanctuary at -Z.
	var segs := [[48.0, 70.0, 0.5], [20.0, 48.0, 2.0], [-12.0, 20.0, 3.5], [-38.0, -12.0, 5.0],
		[-58.0, -38.0, 6.5], [-90.0, -58.0, 8.0]]
	for sg in segs:
		var z0: float = sg[0]
		var z1: float = sg[1]
		var yh: float = sg[2]
		lm.box("Rock", Vector3(0, yh * 0.5, (z0 + z1) * 0.5), Vector3(40.0, yh, z1 - z0))
		lm.box("Trim", Vector3(0, yh - 0.05, (z0 + z1) * 0.5), Vector3(14.0, 0.2, z1 - z0))
	for k in 5:
		var zb: float = segs[k][0]
		var y_lo: float = segs[k][2]
		var y_hi: float = segs[k + 1][2]
		# The stair rises toward -Z, so its higher side is segment k + 1.
		var n := 5
		U.stair(lm, "Stone", Vector3(0, y_lo, zb), Basis(), 9.0, n, 0.55, (y_hi - y_lo) / float(n))
		# Naga balustrades flank the stairs between the upper levels.
		if k >= 2:
			for sx in [-1.0, 1.0]:
				U.naga_rail(lm, "Trim", Vector3(sx * 5.0, y_lo, zb), Basis(), 2.75, y_hi - y_lo, 0.0, 0.45, 7)
	# Gopuras I-V along the axis, III the largest.
	var gops := [[56.0, 0.5, 20.0], [28.0, 2.0, 22.0], [0.0, 3.5, 24.0], [-26.0, 5.0, 22.0],
		[-48.0, 6.5, 20.0]]
	var xb := Basis(Vector3.UP, PI * 0.5)
	for g in gops:
		var z: float = g[0]
		var y: float = g[1]
		var gl: float = g[2]
		U.hall(lm, "Stone", "Trim", "Stone", "Trim", Vector3(0, y, z), xb, 6.4, gl, 0.4, 4.2, 2.4, 2, 0)
		lm.box("Dark", Vector3(0, y + 2.6, z + 3.35), Vector3(2.6, 4.2, 0.2))
		lm.box("Dark", Vector3(0, y + 2.6, z - 3.35), Vector3(2.6, 4.2, 0.2))
	# Processional avenues: lotus-bud boundary posts down both sides of the
	# paved way on every terrace.
	for si in 5:
		var za: float = segs[si][0]
		var zc: float = segs[si][1]
		var yp: float = segs[si][2]
		var np := int((zc - za) / 3.0)
		for i in np:
			var z := za + 1.5 + 3.0 * float(i)
			var near := false
			for g in [56.0, 28.0, 0.0, -26.0, -48.0]:
				near = near or absf(z - g) < 6.0
			if near or z > zc - 3.0:
				continue
			for sx in [-1.0, 1.0]:
				lm.frustum("Trim", Vector3(sx * 6.5, yp, z), 0.24, 0.2, 1.4, 6)
				U.lotus_bud(lm, "Trim", Vector3(sx * 6.5, yp + 1.4, z), 0.26, 0.6, 6)
	# Gopura III is flanked by two long halls and crowned by a small tower.
	for s in [-1.0, 1.0]:
		U.hall(lm, "Stone", "Trim", "Stone", "Trim", Vector3(s * 15.5, 3.5, 0.0), Basis(), 5.0, 12.0, 0.4,
			3.4, 2.0, 2, 0)
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, 8.0, 0), 2.4, 10.0, 2, 0.35)
	# Sanctuary court: walls, mandapa and the central tower.
	U.wall_run(lm, "Stone", "Trim", Vector3(-12.0, 8.0, -90.0), Vector3(12.0, 8.0, -90.0), 3.6, 1.6)
	for s in [-1.0, 1.0]:
		U.wall_run(lm, "Stone", "Trim", Vector3(s * 12.0, 8.0, -90.0), Vector3(s * 12.0, 8.0, -60.0), 3.6, 1.6)
	U.hall(lm, "Stone", "Trim", "Stone", "Trim", Vector3(0, 8.0, -62.0), xb, 6.4, 12.0, 0.4, 3.8, 2.2, 2, 0)
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, 8.0, -76.0), 3.6, 18.0, 3, 0.28)
	lm.commit(model)

## Prasat Thom at Koh Ker (36 m, from 928): the Prang, Jayavarman IV's
## seven-tier stepped pyramid on a 62 m square base, each tier faced with
## rows of framed niches, the seventh carried by Garudas, a steep stair
## between cheek walls up the east face and the plinth of the lost linga
## shrine on the summit. Facing +X.
static func koh_ker(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A7B66", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#9B8C75", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	var th := 5.1
	var eb := Basis(Vector3.UP, PI * 0.5)
	for t in 7:
		var w := 62.0 - 6.0 * float(t)
		var y0 := th * float(t)
		lm.box("Stone", Vector3(0, y0 + th * 0.5, 0), Vector3(w, th, w))
		lm.box("Trim", Vector3(0, y0 + th - 0.2, 0), Vector3(w + 0.8, 0.4, w + 0.8))
		lm.box("Trim", Vector3(0, y0 + 0.3, 0), Vector3(w + 0.5, 0.6, w + 0.5))
		var nn := int(w / 7.0)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for i in nn:
				var x := -w * 0.5 + 3.0 + (w - 6.0) * (float(i) + 0.5) / float(nn)
				if side == 1 and absf(x) < 5.5:
					continue
				var nc := b * Vector3(x, y0 + th * 0.5, w * 0.5)
				lm.box("Dark", nc + b * Vector3(0, 0, 0.02), Vector3(1.8, 2.2, 0.14), b, 0.0)
				for sx in [-1.0, 1.0]:
					lm.box("Trim", nc + b * Vector3(sx * 1.05, 0, 0.12), Vector3(0.3, 2.6, 0.24), b, 0.0)
				lm.box("Trim", nc + b * Vector3(0, 1.3, 0.14), Vector3(2.6, 0.3, 0.28), b, 0.0)
				lm.box("Trim", nc + b * Vector3(0, -1.2, 0.14), Vector3(2.4, 0.2, 0.28), b, 0.0)
	# East stair, tier by tier.
	U.stair(lm, "Stone", eb * Vector3(0, 0, 31.0), eb, 8.0, 10, 0.6, th / 10.0)
	for t in 6:
		var wt := 62.0 - 6.0 * float(t + 1)
		U.stair(lm, "Stone", eb * Vector3(0, th * float(t + 1), wt * 0.5), eb, 8.0, 8, 0.36, th / 8.0)
	# Stair cheek walls up the east face.
	for sx in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(37.0, 0.6, sx * 4.4), Vector3(31.0, th + 0.6, sx * 4.4), 1.0, 1.2,
			Vector3(0, 0, 1))
		lm.beam("Trim", Vector3(31.0, th + 0.6, sx * 4.4), Vector3(13.5, th * 7.0 - 0.6, sx * 4.4), 1.0, 1.2,
			Vector3(0, 0, 1))
	# Garudas with raised arms carry the seventh tier, at its corners and
	# along every side.
	var w7 := 62.0 - 36.0
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for t in [-1.0, -0.5, 0.5, 1.0]:
			var x: float = t * (w7 * 0.5 - 1.2)
			if side == 1 and absf(x) < 5.5:
				continue
			_garuda(lm, "Trim", b * Vector3(x, th * 6.0, w7 * 0.5 + 0.35), b, th * 0.85)
	# Summit plinth of the lost sanctuary, a moulded base of the linga
	# shrine (about 15 m high in its day).
	lm.box("Trim", Vector3(0, th * 7.0 + 0.15, 0), Vector3(12.0, 0.3, 12.0))
	lm.box("Stone", Vector3(0, th * 7.0 + 0.3 + 0.08, 0), Vector3(9.0, 0.16, 9.0), Basis(), 0.0)
	lm.commit(model)

## Garuda atlant of height h on a tier face (basis +Z out of the wall):
## squat legs, chest, outspread wings, arms raised to the cornice and the
## beaked head.
static func _garuda(lm: LandmarkMesh, key: String, base: Vector3, b: Basis, h: float) -> void:
	for sx in [-1.0, 1.0]:
		lm.beam(key, base + b * Vector3(sx * h * 0.08, h * 0.35, 0), base + b * Vector3(sx * h * 0.18, h * 0.02, 0.1),
			h * 0.1, h * 0.1)
		lm.beam(key, base + b * Vector3(sx * h * 0.12, h * 0.68, 0), base + b * Vector3(sx * h * 0.42, h * 0.48, -0.1),
			h * 0.22, h * 0.06, b * Vector3.UP)
		lm.beam(key, base + b * Vector3(sx * h * 0.12, h * 0.68, 0.05), base + b * Vector3(sx * h * 0.2, h * 0.98, 0.05),
			h * 0.07, h * 0.07)
	lm.box(key, base + b * Vector3(0, h * 0.52, 0), Vector3(h * 0.26, h * 0.36, h * 0.18), b, 0.0)
	lm.box(key, base + b * Vector3(0, h * 0.8, 0.02), Vector3(h * 0.16, h * 0.16, h * 0.16), b, 0.0)
	lm.spire(key, base + b * Vector3(0, h * 0.82, 0.12), h * 0.04, h * 0.12, 0.0)
