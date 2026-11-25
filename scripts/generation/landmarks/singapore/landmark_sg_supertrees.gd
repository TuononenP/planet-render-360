class_name LandmarkSgSupertrees
extends RefCounted

## Supertree Grove & OCBC Skyway (50 m tallest tree, SG-2.8):
## - 12 parametric vertical-garden Supertrees (25–50 m tall) arranged in the iconic grove plan:
##   reinforced concrete core, flared steel planting-skin trellis trunk draped in lush green/bronze/magenta
##   foliage, inverted-umbrella radial steel canopy ribs.
## - 128 m OCBC Skyway suspended aerial walkway at y=22 m linking the central pair of Supertrees
##   with steel railings and glowing underside LED ribbon.
## - Supertree Observatory crown pavilion on top of the tallest 50 m tree.
## - Night: iconic vibrant purple, magenta, cyan, and gold illuminated canopies (`PurpleLamp`, `CyanLamp`).

const TREES := [
	# [x, z, height_m, canopy_r, lamp_key]
	[0.0, 0.0, 50.0, 16.5, "PurpleLamp"],       # Tallest central observatory Supertree
	[-38.0, -14.0, 42.0, 14.0, "CyanLamp"],     # Skyway west anchor
	[36.0, -18.0, 42.0, 14.0, "PurpleLamp"],    # Skyway east anchor
	[-16.0, -36.0, 34.0, 11.5, "GoldLamp"],
	[18.0, -40.0, 32.0, 11.0, "PurpleLamp"],
	[-52.0, 16.0, 30.0, 10.5, "PurpleLamp"],
	[-22.0, 28.0, 36.0, 12.5, "CyanLamp"],
	[24.0, 24.0, 35.0, 12.0, "GoldLamp"],
	[54.0, 12.0, 29.0, 10.0, "CyanLamp"],
	[-62.0, -24.0, 26.0, 9.0, "GoldLamp"],
	[62.0, -22.0, 27.0, 9.5, "PurpleLamp"],
	[4.0, 44.0, 25.0, 8.8, "CyanLamp"],
]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("concrete", "#BEB9AE", 3.0))
	lm.use("Skin", LandmarkMaterials.pbr("forest", "#3B6B38", 3.0))
	lm.use("Trellis", LandmarkMaterials.pbr("sheet_metal", "#7C3E5A", 2.0, 0.35, 0.65))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#5E505A", 2.0, 0.35, 0.72))
	lm.use("Glass", LandmarkMaterials.glass("#6898AE"))
	lm.use("PurpleLamp", LandmarkMaterials.lit("#C848FF", 2.8))
	lm.use("CyanLamp", LandmarkMaterials.lit("#42D8FF", 2.6))
	lm.use("GoldLamp", LandmarkMaterials.lit("#FFC448", 2.4))

	for t in TREES:
		_build_supertree(lm, Vector3(float(t[0]), 0.0, float(t[1])), float(t[2]), float(t[3]), str(t[4]))

	# Supertree Observatory glass & steel crown pavilion on top of the 50 m central Supertree.
	lm.frustum("Glass", Vector3(0.0, 45.2, 0.0), 8.2, 9.2, 3.8, 16)
	lm.frustum("Trellis", Vector3(0.0, 49.0, 0.0), 10.5, 8.0, 1.0, 16)

	# 128 m curved OCBC Skyway suspended walkway at y=22 m linking west (-38,-14) -> centre (0,0) -> east (36,-18).
	var sky_pts: Array = [
		Vector3(-38.0, 22.0, -14.0), Vector3(-24.0, 22.0, -24.0), Vector3(-6.0, 22.0, -16.0),
		Vector3(10.0, 22.0, -22.0), Vector3(24.0, 22.0, -24.0), Vector3(36.0, 22.0, -18.0),
	]
	for i in sky_pts.size() - 1:
		var a: Vector3 = sky_pts[i]
		var b: Vector3 = sky_pts[i + 1]
		var d := b - a
		var yaw := -atan2(d.z, d.x)
		var bas := Basis(Vector3.UP, yaw)
		lm.box("Steel", (a + b) * 0.5, Vector3(d.length() + 0.4, 0.55, 2.8), bas)
		lm.beam("GoldLamp", a + Vector3(0.0, -0.35, 0.0), b + Vector3(0.0, -0.35, 0.0), 0.22, 0.22)
		# Suspension cables up to nearest Supertree canopies.
		var anchor := Vector3(-38.0, 38.0, -14.0) if i < 2 else (Vector3(0.0, 44.0, 0.0) if i == 2 else Vector3(36.0, 38.0, -18.0))
		lm.beam("Steel", (a + b) * 0.5 + Vector3(0.0, 0.3, 0.0), anchor, 0.14, 0.14)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 22.0), Vector3(0.0, 34.0, 0.0), 65.0, 1.4],
		[Vector3(-38.0, 2.0, 10.0), Vector3(-38.0, 28.0, -14.0), 62.0, 1.1],
		[Vector3(36.0, 2.0, 8.0), Vector3(36.0, 28.0, -18.0), 62.0, 1.1],
	])

static func _build_supertree(lm: LandmarkMesh, base: Vector3, h: float, canopy_r: float, lamp_key: String) -> void:
	# Concrete core + lush planted steel-trellis hyperboloid trunk (wide base, pinched waist, flaring crown).
	lm.frustum("Core", base, canopy_r * 0.26, canopy_r * 0.16, h * 0.88, 10)
	var tiers := 6
	for i in tiers:
		var t0 := float(i) / float(tiers)
		var t1 := float(i + 1) / float(tiers)
		var y0 := base.y + h * 0.84 * t0
		var y1 := base.y + h * 0.84 * t1
		var r0 := _trunk_r(t0, canopy_r)
		var r1 := _trunk_r(t1, canopy_r)
		lm.frustum("Skin", Vector3(base.x, y0, base.z), r0, r1, y1 - y0 + 0.1, 12)
	# Flaring magenta/bronze steel exo-trellis ribs sweeping up into inverted-umbrella canopy.
	var ribs := 12
	var top_y := base.y + h * 0.94
	for k in ribs:
		var a := TAU * float(k) / float(ribs)
		var ca := cos(a); var sa := sin(a)
		var p_base := base + Vector3(ca * canopy_r * 0.42, 0.0, sa * canopy_r * 0.42)
		var p_waist := base + Vector3(ca * canopy_r * 0.28, h * 0.52, sa * canopy_r * 0.28)
		var p_flare := base + Vector3(ca * canopy_r * 0.72, h * 0.86, sa * canopy_r * 0.72)
		var p_rim := base + Vector3(ca * canopy_r, top_y, sa * canopy_r)
		lm.beam("Trellis", p_base, p_waist, 0.34, 0.34)
		lm.beam("Trellis", p_waist, p_flare, 0.32, 0.32)
		lm.beam("Trellis", p_flare, p_rim, 0.28, 0.28)
		# Illuminated radial canopy branch rib.
		lm.beam(lamp_key, p_flare + Vector3(0.0, 0.3, 0.0), p_rim + Vector3(0.0, 0.3, 0.0), 0.24, 0.24)
	# Perimeter canopy ring + glowing night ring.
	for k in ribs:
		var a0 := TAU * float(k) / float(ribs)
		var a1 := TAU * float(k + 1) / float(ribs)
		var q0 := base + Vector3(cos(a0) * canopy_r, top_y, sin(a0) * canopy_r)
		var q1 := base + Vector3(cos(a1) * canopy_r, top_y, sin(a1) * canopy_r)
		lm.beam("Trellis", q0, q1, 0.36, 0.36)
		lm.beam(lamp_key, q0 + Vector3(0.0, -0.35, 0.0), q1 + Vector3(0.0, -0.35, 0.0), 0.26, 0.26)

static func _trunk_r(t: float, canopy_r: float) -> float:
	# Hyperboloid waist at t=0.52, flaring softly at ground and top.
	var d := t - 0.52
	return canopy_r * (0.24 + 0.55 * d * d)
