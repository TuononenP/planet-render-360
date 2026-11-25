class_name LandmarkSgFlyer
extends RefCounted

## Singapore Flyer (165 m tall, 150 m rim diameter, SG-2.4):
## - Slender open ladder-truss rim (twin outer & inner rings + radial cross-braces) so it reads
##   as a delicate transparent ring from Padang & Marina Bay, never a solid disc.
## - Tension cable spokes radiating from the central hub to the 150 m rim.
## - 28 air-conditioned glass capsules mounted OUTSIDE the rim (`LandmarkWheel.DIAMETER_PER_HEIGHT` proportions).
## - Twin inclined A-frame leg supports with diagonal tie stays anchored to the 3-storey
##   circular-atrium terminal podium.
## - Night: glowing rim LEDs (`RimLamp`), warm capsule glow (`CapLamp`), and top aviation beacon (`HALO_META`).

const RIM_R := 72.0
const HUB_Y := 88.0
const CAPSULES := 28

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#D6DAE0", 2.0, 0.28, 0.78))
	lm.use("DarkSteel", LandmarkMaterials.pbr("sheet_metal", "#4C535C", 2.0, 0.35, 0.72))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#DDD9D0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#6E9AB2"))
	lm.use("Trees", LandmarkMaterials.pbr("forest", "#2E6430", 3.0))
	lm.use("RimLamp", LandmarkMaterials.lit("#8CD4FF", 2.6))
	lm.use("CapLamp", LandmarkMaterials.lit("#FFE4AC", 1.8))

	# 3-storey terminal building with central circular tropical rainforest atrium.
	lm.box("Podium", Vector3(0.0, 6.0, 0.0), Vector3(96.0, 12.0, 44.0))
	lm.box("Glass", Vector3(0.0, 6.5, 22.3), Vector3(84.0, 9.0, 0.6))
	lm.box("Glass", Vector3(0.0, 6.5, -22.3), Vector3(84.0, 9.0, 0.6))
	lm.frustum("Trees", Vector3(0.0, 12.0, 0.0), 16.0, 14.0, 4.5, 16)

	# Twin inclined A-frame support legs + central axle hub.
	var hub_a := Vector3(0.0, HUB_Y, -10.5)
	var hub_b := Vector3(0.0, HUB_Y, 10.5)
	lm.beam("Steel", hub_a, hub_b, 4.2, 4.2)
	for side: float in [-1.0, 1.0]:
		var hz := side * 10.5
		var fz := side * 18.0
		lm.beam("Steel", Vector3(-34.0, 11.0, fz), Vector3(0.0, HUB_Y, hz), 2.8, 2.8)
		lm.beam("Steel", Vector3(34.0, 11.0, fz), Vector3(0.0, HUB_Y, hz), 2.8, 2.8)
		lm.beam("DarkSteel", Vector3(-18.0, 50.0, lerpf(fz, hz, 0.5)), Vector3(18.0, 50.0, lerpf(fz, hz, 0.5)), 1.2, 1.2)
	# Cross-bracing between A-frames.
	lm.beam("Steel", Vector3(-34.0, 11.0, -18.0), Vector3(-34.0, 11.0, 18.0), 1.8, 1.8)
	lm.beam("Steel", Vector3(34.0, 11.0, -18.0), Vector3(34.0, 11.0, 18.0), 1.8, 1.8)

	# Slender ladder-truss rim (56 segments): twin outer rails (z=±3.8 m), inner spine (r-4.2 m),
	# radial braces, tension cable spokes, and glowing RimLamp ring.
	var segs := 56
	var r_out := RIM_R
	var r_in := RIM_R - 4.4
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var c0 := cos(a0); var s0 := sin(a0)
		var c1 := cos(a1); var s1 := sin(a1)
		for side: float in [-1.0, 1.0]:
			var p0 := Vector3(c0 * r_out, HUB_Y + s0 * r_out, side * 3.6)
			var p1 := Vector3(c1 * r_out, HUB_Y + s1 * r_out, side * 3.6)
			lm.beam("Steel", p0, p1, 0.72, 0.72)
			lm.beam("RimLamp", p0 + Vector3(0.0, 0.0, side * 0.45), p1 + Vector3(0.0, 0.0, side * 0.45), 0.32, 0.32)
		var q0 := Vector3(c0 * r_in, HUB_Y + s0 * r_in, 0.0)
		var q1 := Vector3(c1 * r_in, HUB_Y + s1 * r_in, 0.0)
		lm.beam("Steel", q0, q1, 0.65, 0.65)
		# Truss struts & tension spokes every 2nd segment (28 spokes).
		if i % 2 == 0:
			var o_l := Vector3(c0 * r_out, HUB_Y + s0 * r_out, -3.6)
			var o_r := Vector3(c0 * r_out, HUB_Y + s0 * r_out, 3.6)
			lm.beam("Steel", o_l, o_r, 0.42, 0.42)
			lm.beam("Steel", o_l, q0, 0.36, 0.36)
			lm.beam("Steel", o_r, q0, 0.36, 0.36)
			lm.beam("DarkSteel", hub_a, o_l, 0.18, 0.18)
			lm.beam("DarkSteel", hub_b, o_r, 0.18, 0.18)

	# 28 external cylindrical glass capsules mounted OUTSIDE the rim (r = RIM_R + 3.2 m).
	for k in CAPSULES:
		var a := TAU * float(k) / float(CAPSULES)
		var cp := Vector3(cos(a) * (RIM_R + 3.0), HUB_Y + sin(a) * (RIM_R + 3.0), 0.0)
		lm.beam("Steel", Vector3(cos(a) * RIM_R, HUB_Y + sin(a) * RIM_R, 0.0), cp, 0.6, 0.6)
		lm.box("Glass", cp, Vector3(4.2, 3.8, 7.2))
		lm.box("CapLamp", cp, Vector3(3.2, 2.2, 5.8))
		lm.box("Steel", cp + Vector3(0.0, 2.0, 0.0), Vector3(3.6, 0.35, 7.4))

	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(0.0, HUB_Y + RIM_R + 4.5, 0.0), 3.0, Color(1.0, 0.12, 0.05)],
	])
