class_name LandmarkKhMonuments
extends RefCounted

## Phnom Penh monuments and towers in true metres: the Independence
## Monument, the Cambodia-Vietnam Friendship Monument and the Vattanac
## Capital Tower.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Independence Monument (37 m): Vann Molyvann's 1958 lotus-bud tower in the
## Angkorian manner. Two low aprons, a podium with a steep stair and naga
## balustrade on each of the four sides, five receding storeys of false doors
## and pediments, and the lotus-bud crown; red-brown sandstone colour.
static func independence(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A5623F", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#C48B63", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2E2420", 2.0))
	lm.use("Base", LandmarkMaterials.pbr("pavement", "#9A8F84", 3.0))
	lm.box("Base", Vector3(0, 0.225, 0), Vector3(21.0, 0.45, 21.0))
	lm.box("Base", Vector3(0, 0.675, 0), Vector3(19.4, 0.45, 19.4))
	lm.box("Stone", Vector3(0, 2.75, 0), Vector3(11.6, 3.7, 11.6))
	lm.box("Trim", Vector3(0, 4.45, 0), Vector3(12.2, 0.3, 12.2))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var top := Vector3(0, 0.9, 0)
		U.stair(lm, "Stone", top + b * Vector3(0, 0, 5.8), b, 4.4, 10, 0.38, 0.37)
		lm.box("Dark", top + b * Vector3(0, 2.0, 5.84), Vector3(2.2, 2.6, 0.12), b)
		for sx in [-1.0, 1.0]:
			var edge := top + b * Vector3(sx * 2.55, 0, 5.8)
			U.stair(lm, "Stone", edge, b, 0.9, 10, 0.38, 0.37)
			U.naga_rail(lm, "Trim", edge, b, 3.8, 3.7, 0.45, 0.7, 5)
		# Corner naga heads on the podium roof edge.
		var cb := Basis(Vector3.UP, PI * 0.5 * float(side) + PI * 0.25)
		U.naga_fan(lm, "Trim", Vector3(0, 4.6, 0) + cb * Vector3(0, 0, 6.2), cb, 5, 1.5)
	# Podium faces: relief panels between the stairs, a moulded base course.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Trim", b * Vector3(0, 1.15, 5.85), Vector3(11.8, 0.5, 0.2), b)
		for sx in [-1.0, 1.0]:
			lm.box("Trim", b * Vector3(sx * 4.4, 2.9, 5.84), Vector3(1.6, 2.4, 0.14), b, 0.0)
			lm.box("Dark", b * Vector3(sx * 4.4, 2.9, 5.86), Vector3(1.2, 2.0, 0.08), b, 0.0)
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, 4.6, 0), 5.0, 32.4, 5, 0.24, 0.82, true)
	# The rest of the hundred naga heads: a pair of three-headed fans along
	# every side of every storey, between the corner nagas.
	var storey_h := (32.4 * 0.76 * 0.88) / 5.0
	var y := 4.6 + 32.4 * 0.76 * 0.12
	var w := 5.0
	for k in 5:
		var ce := y + storey_h * 0.62 + storey_h * 0.08 + storey_h * 0.1
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for t in [-0.5, 0.5]:
				U.naga_fan(lm, "Trim", b * Vector3(t * w, ce, w * 0.98), b, 3, storey_h * 0.4)
		y += storey_h
		w *= 0.82
	lm.commit(model)

## Cambodia-Vietnam Friendship Monument (1979, Botum Park): a tall tapering
## concrete pylon with a gold-decorated crown, on a round stepped plaza, with
## the socialist-realist group of two soldiers guarding a mother and child
## and the flanking relief walls at its foot.
static func friendship(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C1AE", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("concrete", "#6E675B", 3.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#A39A8C", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F5A4A", 2.0, 0.5, 0.3))
	lm.frustum("Plaza", Vector3(0, 0, 0), 13.0, 12.6, 0.5, 20)
	lm.frustum("Plaza", Vector3(0, 0.5, 0), 10.6, 10.2, 0.5, 20)
	# Pylon: a plinth, a square shaft tapering to the crown with a shallow
	# setback every 5 m, recessed panels on its faces and the gilded top.
	lm.box("Concrete", Vector3(0, 2.0, 0), Vector3(9.0, 2.0, 7.0))
	var y := 3.0
	var hw := 3.2
	for k in 4:
		var hw1 := hw - 0.3
		lm.frustum("Concrete", Vector3(0, y, 0), hw * 1.4142, hw1 * 1.4142, 4.4, 4, PI * 0.25)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box("Shadow", b * Vector3(0, y + 2.2, (hw + hw1) * 0.5 + 0.05), Vector3(hw * 0.5, 3.2, 0.12), b)
		lm.box("Concrete", Vector3(0, y + 4.6, 0), Vector3(hw1 * 2.0 + 0.5, 0.4, hw1 * 2.0 + 0.5))
		y += 5.0
		hw = hw1 - 0.2
	lm.spire("Gold", Vector3(0, y, 0), hw + 0.1, 26.0 - y, 0.0, 4)
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(hw * 1.4, 0), Vector2(hw * 1.1, 0.8),
		Vector2(hw * 0.7, 1.4)]), 8)
	# Corner pilasters and string courses up every stage of the pylon.
	y = 3.0
	hw = 3.2
	for k in 4:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.beam("Concrete", Vector3(sx * hw, y, sz * hw), Vector3(sx * (hw - 0.3), y + 4.4, sz * (hw - 0.3)),
					0.5, 0.5, Vector3(sx, 0, -sz))
		for q in 2:
			var yy := y + 1.5 + 1.5 * float(q)
			var hq := hw - 0.3 * (yy - y) / 4.4
			lm.box("Shadow", Vector3(0, yy, 0), Vector3(hq * 2.0 + 0.16, 0.12, hq * 2.0 + 0.16), Basis(), 0.0)
		y += 5.0
		hw -= 0.5
	# Sculpture group at the foot: a Vietnamese and a Cambodian soldier
	# guarding a Cambodian mother with her child, on a stepped pedestal.
	lm.box("Concrete", Vector3(0, 1.3, 6.9), Vector3(2.0, 0.6, 2.4))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 1.6, 6.9), 4.6)
	lm.lathe("Bronze", Vector3(0.35, 1.6 + 4.6 * 0.6, 7.25), PackedVector2Array([Vector2(0.0, 0),
		Vector2(0.25, 0.08), Vector2(0.3, 0.4), Vector2(0.22, 0.75), Vector2(0.0, 0.9)]), 10)
	lm.lathe("Bronze", Vector3(0.35, 1.6 + 4.6 * 0.6 + 0.9, 7.25), PackedVector2Array([Vector2(0.0, 0),
		Vector2(0.16, 0.06), Vector2(0.18, 0.2), Vector2(0.0, 0.34)]), 10)
	for sx in [-1.0, 1.0]:
		# Rifles held across the chest.
		lm.beam("Bronze", Vector3(sx * 2.0 - 0.5, 1.0 + 5.2 * 0.55, 6.95), Vector3(sx * 2.0 + 0.4, 1.0 + 5.2 * 0.8,
			7.0), 0.12, 0.2)
	# Soldier pair before the pylon, a relief wall on each side.
	for sx in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(sx * 2.0, 1.0, 6.4), 5.2, sx > 0.0)
		lm.box("Concrete", Vector3(sx * 2.0, 0.85, 6.4), Vector3(2.4, 1.0, 2.4))
		lm.box("Concrete", Vector3(sx * 8.0, 1.6, 0.5), Vector3(3.0, 2.2, 9.0))
		lm.box("Shadow", Vector3(sx * 6.45, 1.6, 0.5), Vector3(0.1, 1.5, 6.5))
		# Relief figures (soldiers and townsfolk) proud of each wall.
		for i in 3:
			LandmarkKits.statue_figure(lm, "Bronze", Vector3(sx * 6.25, 0.6, -1.6 + 2.1 * float(i)), 1.9,
				i == 1)
	lm.commit(model)

## Vattanac Capital Tower (187.3 m, 39 storeys, Farrells 2014): a stone
## podium of retail floors (11,500 m2) under a glass tower with close-set
## vertical fins and a spandrel band per floor, a stepped crown, a sky-bar
## terrace cantilevered on the south face and the sloping dragon-crest roof.
static func vattanac(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#2E4650"))
	lm.use("Frame", LandmarkMaterials.paint("#B9BEC2", 0.45, 0.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC5B0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7F8A91", 3.0))
	lm.box("Stone", Vector3(0, 14.0, 0), Vector3(60.0, 28.0, 52.0))
	lm.box("Glass", Vector3(0, 15.0, 0), Vector3(60.6, 9.0, 52.6))
	lm.box("Glass", Vector3(0, 4.0, 0), Vector3(60.6, 4.0, 52.6))
	lm.box("Stone", Vector3(0, 28.5, 0), Vector3(62.0, 1.0, 54.0))
	# Podium mullions over the shopfront and upper retail glazing, and the
	# entrance canopy on the south front.
	for i in 21:
		var x := -30.0 + 3.0 * float(i)
		for sz in [-1.0, 1.0]:
			for yb in [[2.0, 6.0], [10.5, 19.5]]:
				lm.box("Frame", Vector3(x, (yb[0] + yb[1]) * 0.5, sz * 26.4), Vector3(0.25, yb[1] - yb[0], 0.3),
					Basis(), 0.0)
	for i in 18:
		var z := -25.5 + 3.0 * float(i)
		for sx in [-1.0, 1.0]:
			for yb in [[2.0, 6.0], [10.5, 19.5]]:
				lm.box("Frame", Vector3(sx * 30.4, (yb[0] + yb[1]) * 0.5, z), Vector3(0.3, yb[1] - yb[0], 0.25),
					Basis(), 0.0)
	lm.box("Frame", Vector3(0, 7.0, 29.0), Vector3(20.0, 0.5, 5.0))
	for sx in [-1.0, 1.0]:
		lm.box("Frame", Vector3(sx * 9.0, 3.5, 31.0), Vector3(0.6, 7.0, 0.6))
	# Tower shaft in three stages, each a little slimmer.
	var stages := [[28.0, 100.0, 44.0, 36.0], [100.0, 146.0, 40.0, 33.0], [146.0, 171.0, 36.0, 30.0]]
	for s in stages:
		var y0: float = s[0]
		var y1: float = s[1]
		var wx: float = s[2]
		var wz: float = s[3]
		lm.box("Glass", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(wx, y1 - y0, wz))
		var n := int(wx / 1.6)
		for i in n + 1:
			var x := -wx * 0.5 + wx * float(i) / float(n)
			for sz in [-1.0, 1.0]:
				lm.box("Frame", Vector3(x, (y0 + y1) * 0.5, sz * (wz * 0.5 + 0.2)),
					Vector3(0.5, y1 - y0, 0.6))
		var nz := int(wz / 1.6)
		for i in nz + 1:
			var z := -wz * 0.5 + wz * float(i) / float(nz)
			for sx in [-1.0, 1.0]:
				lm.box("Frame", Vector3(sx * (wx * 0.5 + 0.2), (y0 + y1) * 0.5, z),
					Vector3(0.6, y1 - y0, 0.5))
		lm.box("Frame", Vector3(0, y1 + 0.4, 0), Vector3(wx + 1.4, 0.8, wz + 1.4))
		# Floor-edge spandrel bands, one per 4.1 m storey.
		var nf := int((y1 - y0) / 4.1)
		for f in nf:
			var fy := y0 + (y1 - y0) * float(f + 1) / float(nf + 1)
			lm.box("Frame", Vector3(0, fy, 0), Vector3(wx + 0.5, 0.25, wz + 0.5), Basis(), 0.0)
	# Sky-bar terrace cantilevered on the south face, below the crown.
	lm.box("Stone", Vector3(0, 154.0, 19.0), Vector3(30.0, 1.2, 8.0))
	lm.box("Glass", Vector3(0, 156.4, 21.5), Vector3(28.0, 3.6, 0.4))
	# Curved crown: the roof sweeps up from 171.8 m at the back to 187.3 m
	# above the sky-bar front, like the dragon's crest.
	var hx := 18.0
	var hz := 15.0
	var yb := 171.8
	var yt := 187.3
	var curve := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		curve.append(Vector2(-hz + hz * 2.0 * t, yb + (yt - yb) * (t * t * 0.7 + t * 0.3)))
	var rows: Array = []
	for c in curve:
		rows.append(PackedVector3Array([Vector3(-hx, c.y, c.x), Vector3(hx, c.y, c.x)]))
	lm.grid("Roof", rows, Vector3(0, yb - 5.0, 0), true)
	lm.quad("Glass", Vector3(-hx, yb, hz), Vector3(hx, yb, hz), Vector3(hx, yt, hz),
		Vector3(-hx, yt, hz), Vector3.BACK)
	for sx in [-1.0, 1.0]:
		var n := Vector3(sx, 0, 0)
		for i in 8:
			var c0 := curve[i]
			var c1 := curve[i + 1]
			lm.tri("Frame", Vector3(sx * hx, yb, c0.x), Vector3(sx * hx, c0.y, c0.x), Vector3(sx * hx, c1.y, c1.x),
				n, n, n, Vector2(c0.x, 0), Vector2(c0.x, c0.y - yb), Vector2(c1.x, c1.y - yb))
			lm.tri("Frame", Vector3(sx * hx, yb, c0.x), Vector3(sx * hx, c1.y, c1.x), Vector3(sx * hx, yb, c1.x),
				n, n, n, Vector2(c0.x, 0), Vector2(c1.x, c1.y - yb), Vector2(c1.x, 0))
	lm.commit(model)
