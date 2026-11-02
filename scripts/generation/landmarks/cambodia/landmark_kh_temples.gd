class_name LandmarkKhTemples
extends RefCounted

## Khmer temples away from Angkor Thom in true metres: Banteay Srei, Phnom
## Bakheng, Preah Vihear and the Koh Ker pyramid.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Banteay Srei (9.8 m): the miniature pink-sandstone sanctuary: three
## towers on a low platform, the mandapa and two brick-and-sandstone
## libraries inside the nested brick and laterite enclosures, east and west
## gopuras. Built facing +X (east).
static func banteay_srei(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#B9776A", 2.5))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#8A5C46", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9B5A40", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2522", 2.0))
	var eb := Basis(Vector3.UP, PI * 0.5)
	# T-shaped platform, 0.9 m high, and the three towers at its west end.
	lm.box("Pink", Vector3(0, 0.45, 0), Vector3(9.0, 0.9, 22.0))
	lm.box("Pink", Vector3(8.0, 0.45, 0), Vector3(12.0, 0.9, 7.0))
	U.prasat(lm, "Pink", "Pink", "Dark", Vector3(0, 0.9, 0), 1.9, 8.9, 3, 0.28)
	for s in [-1.0, 1.0]:
		U.prasat(lm, "Pink", "Pink", "Dark", Vector3(0, 0.9, s * 7.2), 1.6, 7.4, 3, 0.28)
	# Mandapa east of the central tower, libraries in the courtyard corners.
	U.hall(lm, "Pink", "Pink", "Pink", "Pink", Vector3(7.0, 0.9, 0), eb, 4.6, 9.0, 0.0, 2.4, 1.8, 2, 0)
	for s in [-1.0, 1.0]:
		U.hall(lm, "Brick", "Pink", "Pink", "Pink", Vector3(11.0, 0.0, s * 8.0), eb, 3.2, 6.6, 0.8, 2.2,
			1.5, 2, 0)
	# Enclosures: brick (24 m), laterite (42 x 38 m) and the outer laterite wall.
	_ring(lm, "Brick", "Pink", 12.0, 12.0, 2.6, 1.0, 2.5)
	_ring(lm, "Laterite", "Laterite", 21.0, 19.0, 3.0, 1.4, 3.2)
	_ring(lm, "Laterite", "Laterite", 55.0, 47.5, 3.4, 1.8, 3.6)
	for sx in [-1.0, 1.0]:
		U.hall(lm, "Laterite", "Pink", "Pink", "Pink", Vector3(sx * 21.0, 0, 0), eb, 3.8, 7.0, 0.4,
			3.2, 2.2, 2, 0)
		U.hall(lm, "Laterite", "Pink", "Pink", "Pink", Vector3(sx * 55.0, 0, 0), eb, 4.4, 8.0, 0.4,
			3.4, 2.6, 2, 0)
	# Paved causeway east of the outer gopura.
	lm.box("Laterite", Vector3(66.0, 0.1, 0), Vector3(22.0, 0.2, 3.6))
	lm.commit(model)

## Walled rectangle with half-sizes hx, hz and a `gap`-wide opening in the
## middle of the east and west sides.
static func _ring(lm: LandmarkMesh, key: String, cap: String, hx: float, hz: float, h: float,
		t: float, gap: float) -> void:
	for s in [-1.0, 1.0]:
		U.wall_run(lm, key, cap, Vector3(-hx, 0, s * hz), Vector3(hx, 0, s * hz), h, t)
		U.wall_run(lm, key, cap, Vector3(s * hx, 0, -hz), Vector3(s * hx, 0, -gap), h, t)
		U.wall_run(lm, key, cap, Vector3(s * hx, 0, gap), Vector3(s * hx, 0, hz), h, t)

## Phnom Bakheng (22 m): the temple-mountain pyramid on its hill: a base and
## five receding sandstone tiers with a stair up each face, rings of small
## shrine towers, and the quincunx of five sanctuary towers on top. The
## foundation runs below y = 0 into the hill. Built facing +X (east).
static func phnom_bakheng(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A7A62", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#9C8C72", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7A5438", 3.0))
	lm.box("Laterite", Vector3(0, -5.0, 0), Vector3(76.0, 14.0, 76.0))
	lm.box("Trim", Vector3(0, 1.85, 0), Vector3(76.6, 0.3, 76.6))
	var widths: Array[float] = [34.0, 29.6, 25.2, 20.8, 16.4]
	var y := 2.0
	for j in 5:
		var w := widths[j]
		lm.box("Stone", Vector3(0, y + 1.2, 0), Vector3(w * 2.0, 2.4, w * 2.0))
		lm.box("Trim", Vector3(0, y + 2.25, 0), Vector3(w * 2.0 + 0.7, 0.3, w * 2.0 + 0.7))
		# Small towers on the four sides of every terrace.
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for t in [-1.0, -0.5, 0.5]:
				U.small_tower(lm, "Trim", b * Vector3(t * (w - 1.6), y + 2.4, w - 1.6), 0.7, 2.6)
		y += 2.4
	# Stairs up every face, tier by tier.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.stair(lm, "Stone", b * Vector3(0, 0.0, 38.0), b, 6.0, 5, 0.8, 0.4)
		U.stair(lm, "Stone", b * Vector3(0, 2.0, 34.0), b, 5.0, 6, 0.65, 0.4)
		for j in 4:
			var yb: float = 4.4 + 2.4 * float(j)
			U.stair(lm, "Stone", b * Vector3(0, yb, widths[j + 1]), b, 5.0, 6, 0.7, 0.4)
	# Quincunx on the summit: the central tower and four corner towers.
	var top := 14.0
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, top, 0), 3.0, 8.0, 3, 0.28)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.prasat(lm, "Stone", "Trim", "Dark", Vector3(sx * 9.5, top, sz * 9.5), 2.1, 6.0, 3, 0.28)
	lm.commit(model)

## Preah Vihear (26 m): the temple on the Dangrek cliff edge, compressed to
## the axis from the great stair end to the sanctuary: five gopuras on
## rising terraces joined by steep stairs, the walled sanctuary court and the
## lotus-bud central tower. Built with the sanctuary toward -Z; the
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
		lm.box("Rock", Vector3(0, (yh - 10.0) * 0.5, (z0 + z1) * 0.5), Vector3(40.0, yh + 10.0, z1 - z0))
		lm.box("Trim", Vector3(0, yh - 0.05, (z0 + z1) * 0.5), Vector3(14.0, 0.2, z1 - z0))
	for k in 5:
		var zb: float = segs[k][0]
		var y_lo: float = segs[k][2]
		var y_hi: float = segs[k + 1][2]
		# The stair rises toward -Z, so its higher side is segment k + 1.
		var n := 5
		U.stair(lm, "Stone", Vector3(0, y_lo, zb), Basis(), 9.0, n, 0.55, (y_hi - y_lo) / float(n))
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

## Prasat Thom at Koh Ker (36 m): the Prang, a seven-tier stepped pyramid on
## a 62 m square base, each tier faced with rows of dark niches, a steep
## stair up the east face and the shrine plinth on the summit. Facing +X.
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
				lm.box("Dark", b * Vector3(x, y0 + th * 0.5, w * 0.5 + 0.02), Vector3(1.8, 2.2, 0.14), b)
	# East stair, tier by tier.
	U.stair(lm, "Stone", eb * Vector3(0, 0, 31.0), eb, 8.0, 10, 0.6, th / 10.0)
	for t in 6:
		var wt := 62.0 - 6.0 * float(t + 1)
		U.stair(lm, "Stone", eb * Vector3(0, th * float(t + 1), wt * 0.5), eb, 8.0, 8, 0.36, th / 8.0)
	# Summit plinth of the lost sanctuary.
	lm.box("Trim", Vector3(0, th * 7.0 + 0.15, 0), Vector3(12.0, 0.3, 12.0))
	lm.commit(model)
