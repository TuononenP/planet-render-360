class_name LandmarkSgMerlion
extends RefCounted

## Merlion Park (8.6 m statue + jetty + Merlion Cub, SG-2.3):
## - Sculpted 8.6 m white cement/porcelain Merlion statue facing east (+X) across Marina Bay
##   on its fluted wave pedestal: carved lion head & mane, open mouth, relief fish-scale body,
##   and sweeping curled fish tail.
## - Translucent arcing water jet from mouth into Marina Bay with circular splash foam ring.
## - Stepped over-water viewing promontory jetty (`base: water`) with railings and the 2 m
##   Merlion Cub behind on the plaza (node 6283080658).

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F4F3EE", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9E9B94", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#C8C2B6", 3.0))
	lm.use("Rail", LandmarkMaterials.pbr("sheet_metal", "#5E646C", 2.0, 0.35, 0.72))
	lm.use("Jet", LandmarkMaterials.glass("#D8F2FA"))
	lm.use("Foam", LandmarkMaterials.lit("#E8F6FC", 0.8))

	# Stepped over-water viewing jetty promontory extending east into Marina Bay.
	lm.box("Granite", Vector3(-6.0, 0.0, 0.0), Vector3(34.0, 4.0, 22.0))
	lm.box("Deck", Vector3(6.0, 1.2, 0.0), Vector3(18.0, 1.4, 16.0))
	# Jetty amphitheatre steps & perimeter railings.
	for i in 3:
		lm.box("Granite", Vector3(-14.0 + float(i) * 1.4, 2.2 + float(i) * 0.35, 0.0), Vector3(1.4, 0.4, 18.0))
	for side: float in [-1.0, 1.0]:
		lm.beam("Rail", Vector3(-20.0, 3.0, side * 10.6), Vector3(14.5, 3.0, side * 7.8), 0.14, 0.14)
		for p in 8:
			var t := float(p) / 7.0
			var rx := lerpf(-20.0, 14.5, t)
			var rz := lerpf(side * 10.6, side * 7.8, t)
			lm.beam("Rail", Vector3(rx, 1.9, rz), Vector3(rx, 3.0, rz), 0.10, 0.10)

	# Fluted wave plinth + 8.6 m Merlion statue at (0, 2.0, 0) facing +X (east).
	_build_merlion_statue(lm, Vector3(0.0, 1.9, 0.0), 1.0)

	# Arcing water jet from the Merlion's mouth (x=1.5, y=7.6) out into Marina Bay (x=18.5, y=0.2).
	var prev := Vector3(1.45, 7.55, 0.0)
	for i in range(1, 17):
		var t := float(i) / 16.0
		var jx := 1.45 + 17.5 * t
		var jy := 7.55 + 1.15 * t - 8.5 * t * t
		var cur := Vector3(jx, maxf(jy, 0.15), 0.0)
		var r := lerpf(0.14, 0.42, t)
		lm.beam("Jet", prev, cur, r, r)
		prev = cur
	# Circular splash foam ring on bay water surface.
	lm.frustum("Foam", Vector3(18.8, 0.05, 0.0), 2.6, 2.2, 0.25, 16)
	lm.frustum("Jet", Vector3(18.8, 0.2, 0.0), 1.4, 0.8, 0.9, 12)

	# 2 m Merlion Cub statue behind on the west plaza.
	_build_merlion_statue(lm, Vector3(-16.0, 2.1, -4.5), 0.28)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(5.5, 2.4, 4.5), Vector3(0.0, 6.2, 0.0), 48.0, 1.8],
		[Vector3(5.5, 2.4, -4.5), Vector3(0.0, 6.2, 0.0), 48.0, 1.8],
		[Vector3(12.0, 2.2, 0.0), Vector3(10.0, 4.0, 0.0), 55.0, 1.0],
	])

static func _build_merlion_statue(lm: LandmarkMesh, base: Vector3, s: float) -> void:
	# Wave pedestal.
	lm.frustum("White", base, 2.2 * s, 1.8 * s, 1.3 * s, 14)
	# Sweeping S-curved fish torso with scale relief bands.
	var prev := base + Vector3(-0.3 * s, 1.2 * s, 0.0)
	for i in range(1, 11):
		var t := float(i) / 10.0
		var bx := (-0.3 + 0.65 * sin(t * PI * 0.85)) * s
		var by := (1.2 + 4.1 * t) * s
		var rad := lerpf(1.25, 0.85, t) * s
		var cur := base + Vector3(bx, by, 0.0)
		lm.beam("White", prev, cur, rad * 1.4, rad * 1.6)
		# Relief fish-scale collar rings.
		if i % 2 == 0:
			lm.frustum("White", cur + Vector3(0.0, -0.15 * s, 0.0), rad * 1.08, rad * 0.96, 0.26 * s, 12)
		prev = cur
	# Curled fish tail flaring back-west (-X).
	lm.beam("White", base + Vector3(-0.5 * s, 1.5 * s, 0.0), base + Vector3(-1.8 * s, 2.3 * s, 0.0), 0.9 * s, 1.2 * s)
	lm.box("White", base + Vector3(-2.1 * s, 2.7 * s, 0.0), Vector3(0.7 * s, 1.4 * s, 1.8 * s), Basis(Vector3.FORWARD, 0.35))
	# Sculpted Lion Head, Mane & Snout facing east (+X).
	var head := base + Vector3(0.45 * s, 5.55 * s, 0.0)
	LandmarkAsiaSouthUtil.dome(lm, "White", head + Vector3(-0.2 * s, -0.6 * s, 0.0), 1.35 * s, 1.75 * s, 12, 6)
	# Layered mane ridges around neck/head.
	for k in 8:
		var a := TAU * float(k) / 8.0
		var mp := head + Vector3(-0.15 * s + cos(a) * 0.65 * s, 0.15 * s + sin(a) * 0.85 * s, sin(a) * 0.65 * s)
		lm.box("White", mp, Vector3(0.7 * s, 0.45 * s, 0.55 * s), Basis(Vector3.FORWARD, a * 0.4))
	# Lion snout & jaw (open mouth for water jet).
	lm.box("White", head + Vector3(0.85 * s, 0.25 * s, 0.0), Vector3(1.05 * s, 0.62 * s, 0.82 * s))
	lm.box("White", head + Vector3(0.80 * s, -0.25 * s, 0.0), Vector3(0.95 * s, 0.36 * s, 0.72 * s))
	# Crown crest reaching full 8.6 m height (1.9 + 6.7 = 8.6 m).
	lm.frustum("White", head + Vector3(0.0, 0.75 * s, 0.0), 0.85 * s, 0.45 * s, 0.40 * s, 10)
