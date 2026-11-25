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
	lm.use("White", LandmarkMaterials.pbr("concrete", "#F3F2EE", 2.0))
	lm.use("Underside", LandmarkMaterials.pbr("concrete", "#DBD8D0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#5A8298"))
	lm.use("Pond", LandmarkMaterials.pool_water())
	lm.use("Deck", LandmarkMaterials.pbr("stone", "#C4BEB2", 3.0))
	lm.use("SkylightLamp", LandmarkMaterials.lit("#FFF2D6", 1.8))

	# Circular reflective lily pond & promenade ring deck.
	lm.frustum("Deck", Vector3(0.0, 0.0, 0.0), 38.0, 38.0, 1.2, 32)
	lm.frustum("Pond", Vector3(0.0, 1.2, 0.0), 34.5, 34.5, 0.35, 32)
	# Entry walkway bridges across the lily pond.
	lm.box("Deck", Vector3(0.0, 1.7, 24.0), Vector3(9.0, 0.6, 26.0))
	lm.box("Deck", Vector3(0.0, 1.7, -24.0), Vector3(8.0, 0.6, 24.0))

	# Cylindrical central stem rising from the lily pond.
	lm.frustum("Underside", Vector3(0.0, 1.5, 0.0), 15.5, 17.0, 13.0, 20)
	lm.frustum("Glass", Vector3(0.0, 1.6, 0.0), 16.0, 16.2, 6.0, 20)
	# Central dish bowl tying all 10 petals.
	lm.frustum("White", Vector3(0.0, 13.5, 0.0), 17.0, 24.0, 9.0, 20)

	# 10 asymmetric upward-curving lotus petals lofted radially.
	for i in PETAL_HEIGHTS.size():
		var ang := TAU * float(i) / float(PETAL_HEIGHTS.size())
		var h := float(PETAL_HEIGHTS[i])
		var reach := 28.0 + (h - 38.0) * 0.42
		_build_petal(lm, ang, h, reach)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(32.0, 2.5, 0.0), Vector3(12.0, 32.0, 0.0), 62.0, 1.4],
		[Vector3(-32.0, 2.5, 0.0), Vector3(-12.0, 32.0, 0.0), 62.0, 1.4],
		[Vector3(0.0, 2.5, 32.0), Vector3(0.0, 32.0, 12.0), 62.0, 1.4],
		[Vector3(0.0, 2.5, -32.0), Vector3(0.0, 32.0, -12.0), 62.0, 1.4],
	])

static func _build_petal(lm: LandmarkMesh, ang: float, top_y: float, reach: float) -> void:
	var dir := Vector3(cos(ang), 0.0, sin(ang))
	var perp := Vector3(-sin(ang), 0.0, cos(ang))
	var steps := 8
	var prev := dir * 13.5 + Vector3(0.0, 14.0, 0.0)
	for s in range(1, steps + 1):
		var t := float(s) / float(steps)
		# Petal curves outward from central dish, then sweeps steeply upward to skylight tip.
		var r := 13.5 + (reach - 13.5) * pow(sin(t * PI * 0.56), 0.85)
		var y := 14.0 + (top_y - 14.0) * pow(t, 1.35)
		var cur := dir * r + Vector3(0.0, y, 0.0)
		var w := lerpf(9.6, 5.2, t)
		var thick := lerpf(6.5, 3.8, t)
		lm.beam("White", prev, cur, w, thick)
		prev = cur
	# Glazed skylight aperture cap at the finger tip.
	var tip_dir := (prev - (dir * (reach * 0.8) + Vector3(0.0, top_y * 0.8, 0.0))).normalized()
	lm.box("Glass", prev + Vector3(0.0, 0.3, 0.0), Vector3(4.6, 1.2, 3.6), Basis(Vector3.UP, -ang))
	lm.box("SkylightLamp", prev + Vector3(0.0, -0.4, 0.0) + perp * 0.0, Vector3(3.8, 0.6, 2.8), Basis(Vector3.UP, -ang))
	var _unused := tip_dir
