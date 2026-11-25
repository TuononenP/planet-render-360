class_name LandmarkSgArtScience
extends RefCounted

## ArtScience Museum (60 m, SG-2.5):
## - Iconic Moshe Safdie lotus-flower museum on the Marina Bay waterfront promenade:
##   10 asymmetric upward-curving white FRP/concrete "fingers" rising from a cylindrical
##   central stem, each capped with a rectangular glazed skylight aperture.
## - Surrounded by a circular reflective `pool_water` lily pond with timber walkway bridges
##   and crisp white architectural night uplighting.

const PETAL_HEIGHTS := [58.5, 48.0, 54.0, 42.0, 50.0, 38.0, 46.0, 56.0, 44.0, 52.0]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#F5F3EE", 2.0))
	lm.use("Underside", LandmarkMaterials.pbr("concrete", "#D8D4CA", 3.0))
	lm.use("DarkBowl", LandmarkMaterials.pbr("sheet_metal", "#384048", 2.0, 0.45, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#263D4C"))
	lm.use("Pond", LandmarkMaterials.pool_water())
	lm.use("Deck", LandmarkMaterials.pbr("stone", "#C4BEB2", 3.0))
	lm.use("SkylightLamp", LandmarkMaterials.lit("#FFF2D6", 1.9))

	# Circular reflective lily pond & wide semi-circular waterfront promenade deck.
	lm.frustum("Deck", Vector3(0.0, 0.0, 0.0), 43.0, 43.0, 1.3, 36)
	lm.frustum("Pond", Vector3(0.0, 1.3, 0.0), 34.5, 34.5, 0.35, 36)
	# Radial curved white slatted pergola/trellis shade pavilions along the waterfront rim.
	for pi in 5:
		var pang := -0.85 + float(pi) * 0.44
		var pdir := Vector3(cos(pang), 0.0, sin(pang))
		var ppos := pdir * 38.5
		var pb := Basis(Vector3.UP, -pang)
		lm.box("White", ppos + Vector3(0.0, 4.6, 0.0), Vector3(4.8, 0.45, 13.5), pb)
		for sp in [-5.5, 0.0, 5.5]:
			var perp := Vector3(-sin(pang), 0.0, cos(pang))
			lm.frustum("White", ppos + perp * sp + Vector3(0.0, 1.3, 0.0), 0.24, 0.2, 3.3, 6)
	# Entry walkway bridges across the lily pond.
	lm.box("Deck", Vector3(0.0, 1.7, 24.0), Vector3(9.0, 0.6, 26.0))
	lm.box("Deck", Vector3(0.0, 1.7, -24.0), Vector3(8.0, 0.6, 24.0))

	# Glazed circular ground lobby & 10 angled white structural V-struts lifting the lotus bowl.
	lm.frustum("Glass", Vector3(0.0, 1.6, 0.0), 15.8, 16.0, 10.5, 24)
	lm.frustum("Underside", Vector3(0.0, 1.5, 0.0), 14.8, 15.2, 12.2, 24)
	for vi in 10:
		var va := TAU * float(vi) / 10.0
		var va2 := TAU * (float(vi) + 0.5) / 10.0
		var b_pt := Vector3(cos(va) * 15.6, 1.6, sin(va) * 15.6)
		var t_pt1 := Vector3(cos(va - 0.22) * 19.8, 14.5, sin(va - 0.22) * 19.8)
		var t_pt2 := Vector3(cos(va + 0.22) * 19.8, 14.5, sin(va + 0.22) * 19.8)
		lm.beam("White", b_pt, t_pt1, 0.7, 0.7)
		lm.beam("White", b_pt, t_pt2, 0.7, 0.7)
		var _u := va2
	# Sculpted central dish bowl & dark recessed oculus rainwater funnel.
	lm.frustum("White", Vector3(0.0, 13.0, 0.0), 16.5, 25.5, 9.5, 24)
	lm.frustum("DarkBowl", Vector3(0.0, 22.0, 0.0), 12.0, 8.5, 1.2, 20)

	# 10 smooth asymmetric upward-curving white lotus petals with glazed fingertip skylight windows.
	for i in PETAL_HEIGHTS.size():
		var ang := TAU * float(i) / float(PETAL_HEIGHTS.size())
		var h := float(PETAL_HEIGHTS[i])
		var reach := 29.0 + (h - 38.0) * 0.44
		_build_petal(lm, ang, h, reach)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(34.0, 2.5, 0.0), Vector3(12.0, 32.0, 0.0), 62.0, 1.4],
		[Vector3(-34.0, 2.5, 0.0), Vector3(-12.0, 32.0, 0.0), 62.0, 1.4],
		[Vector3(0.0, 2.5, 34.0), Vector3(0.0, 32.0, 12.0), 62.0, 1.4],
		[Vector3(0.0, 2.5, -34.0), Vector3(0.0, 32.0, -12.0), 62.0, 1.4],
	])

static func _build_petal(lm: LandmarkMesh, ang: float, top_y: float, reach: float) -> void:
	var dir := Vector3(cos(ang), 0.0, sin(ang))
	var perp := Vector3(-sin(ang), 0.0, cos(ang))
	var steps := 10
	var outer_grid: Array = []
	var inner_grid: Array = []
	var side_l: Array = []
	var side_r: Array = []
	var tip_c := Vector3.ZERO
	var prev_c := Vector3.ZERO
	for s in steps + 1:
		var t := float(s) / float(steps)
		var r := 14.0 + (reach - 14.0) * pow(sin(t * PI * 0.56), 0.82)
		var y := 14.0 + (top_y - 14.0) * pow(t, 1.32)
		var c := dir * r + Vector3(0.0, y, 0.0)
		var hw := lerpf(5.8, 2.9, pow(t, 0.85))
		var thick := lerpf(3.4, 1.9, t)
		# Outward normal tilts from mostly downward at belly to radially outward at fingertip.
		var out_n := (dir * lerpf(0.75, 0.96, t) + Vector3(0.0, lerpf(-0.66, -0.26, t), 0.0)).normalized()
		var row_o: Array = []
		var row_i: Array = []
		for k in 5:
			var u := -1.0 + 0.5 * float(k)
			var bulge := (1.0 - u * u) * lerpf(1.4, 0.55, t)
			var po := c + perp * (u * hw) + out_n * (thick * 0.5 + bulge)
			var pi_v := c + perp * (u * hw * 0.92) - out_n * (thick * 0.5)
			row_o.append(po)
			row_i.append(pi_v)
		outer_grid.append(row_o)
		inner_grid.append(row_i)
		side_l.append([row_o[0], row_i[0]])
		side_r.append([row_i[4], row_o[4]])
		if s == steps - 1:
			prev_c = c
		elif s == steps:
			tip_c = c
	lm.grid("White", outer_grid)
	lm.grid("Underside", inner_grid)
	lm.grid("White", side_l)
	lm.grid("White", side_r)
	# Crisp angled dark-glazed rectangular skylight window at each petal fingertip.
	var tip_tan := (tip_c - prev_c).normalized()
	var tilt := atan2(tip_tan.y, Vector2(tip_tan.x, tip_tan.z).length())
	var wb := Basis(Vector3.UP, -ang) * Basis(Vector3.FORWARD, tilt - PI * 0.5)
	lm.box("White", tip_c + Vector3(0.0, 0.1, 0.0), Vector3(2.4, 1.3, 5.6), wb)
	lm.box("Glass", tip_c + dir * 0.9 + Vector3(0.0, 0.4, 0.0), Vector3(1.6, 1.1, 4.6), wb)
	lm.box("SkylightLamp", tip_c - dir * 0.2 + Vector3(0.0, -0.35, 0.0), Vector3(1.4, 0.55, 4.0), wb)
