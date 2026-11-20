class_name FtAboAkademiBookTower
extends RefCounted

## Åbo Akademi Book Tower (Kirjatorni, 1935, Erik Bryggman):
## Stark white functionalist library tower on Tuomiokirkonkatu 2-4
## (`skyline: true`, +X ENE, -Z NNW toward Cathedral/Aurajoki, yaw_deg =
## -32.0°, height_m = 26.0):
##   - Crisp cubic 18 x 18 m white rendered book-stack tower rising to 26.0 m
##     with recessed penthouse terrace & thin functionalist roof slab, flush
##     continuous horizontal strip windows on 6 stack tiers, and dark steel
##     mullions with warm reading-stack glow at night.
##   - Attached 2-storey white functionalist reading-room podium (-X, 18 x 14 m,
##     H 8.4 m) with curved corner glazing & granite entrance steps.
## Surfaces: 6 merged PBR parts (White, Concrete, Stone, Frame, Glass, Lamp).

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F2F0E8", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B6B0", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7B75", 2.4))
	lm.use("Frame", LandmarkMaterials.paint("#2A2E33", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263642"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEBC2", 1.35))

	# Granite base & main 18 x 18 m functionalist white book tower (H 24.4 m + penthouse 26.0 m).
	LandmarkFrKit.rect(lm, "Stone", -9.3, 9.3, -9.3, 9.3, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "White", -9.0, 9.0, -9.0, 9.0, 1.4, 24.4)
	LandmarkFrKit.rect(lm, "Concrete", -8.7, 8.7, -8.7, 8.7, 24.4, 24.65)
	# Recessed functionalist rooftop terrace parapet & top stair/lift penthouse (26.0 m).
	for sx: float in [-1.0, 1.0]:
		lm.beam("Frame", Vector3(sx * 8.6, 25.45, -8.6), Vector3(sx * 8.6, 25.45, 8.6), 0.06, 0.06)
		lm.beam("Frame", Vector3(-8.6, 25.45, sx * 8.6), Vector3(8.6, 25.45, sx * 8.6), 0.06, 0.06)
	LandmarkFrKit.rect(lm, "White", -4.5, 4.5, -4.5, 4.5, 24.4, 25.85)
	LandmarkFrKit.rect(lm, "Concrete", -4.7, 4.7, -4.7, 4.7, 25.85, 26.05)
	# Six continuous functionalist horizontal strip-window tiers around all four tower faces.
	for tier in 6:
		var wy := 3.0 + float(tier) * 3.45
		LandmarkFrKit.rect(lm, "Glass", -9.08, 9.08, -7.8, 7.8, wy, wy + 1.55)
		LandmarkFrKit.rect(lm, "Glass", -7.8, 7.8, -9.08, 9.08, wy, wy + 1.55)
		for k in 7:
			var m := lerpf(-7.5, 7.5, float(k) / 6.0)
			lm.box("Frame", Vector3(m, wy + 0.78, -9.10), Vector3(0.12, 1.58, 0.14))
			lm.box("Frame", Vector3(m, wy + 0.78, 9.10), Vector3(0.12, 1.58, 0.14))
			lm.box("Frame", Vector3(-9.10, wy + 0.78, m), Vector3(0.14, 1.58, 0.12))
			lm.box("Frame", Vector3(9.10, wy + 0.78, m), Vector3(0.14, 1.58, 0.12))
		if tier % 2 == 1:
			LandmarkFrKit.rect(lm, "Lamp", -8.3, 8.3, -8.3, 8.3, wy + 0.2, wy + 1.35)
	# Attached 2-storey reading-room wing (-X = -25..-9, H 8.4 m) with glazed reading hall.
	LandmarkFrKit.rect(lm, "Stone", -25.3, -9.0, -7.3, 7.3, FOUND, 1.2)
	LandmarkFrKit.rect(lm, "White", -25.0, -9.0, -7.0, 7.0, 1.2, 8.4)
	LandmarkFrKit.rect(lm, "Concrete", -24.7, -9.2, -6.7, 6.7, 8.4, 8.65)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Glass", -23.6, -10.4, sz * 7.0 - 0.08, sz * 7.0 + 0.08, 2.2, 6.8)
		for k in 6:
			var rx := lerpf(-23.2, -10.8, float(k) / 5.0)
			lm.box("Frame", Vector3(rx, 4.5, sz * 7.06), Vector3(0.14, 4.6, 0.16))
	LandmarkFrKit.rect(lm, "Lamp", -22.5, -11.5, -5.8, 5.8, 2.6, 6.2)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, -17.0), Vector3(0.0, 16.0, -9.0), 54.0, 0.85, 42.0, Color(0.96, 0.94, 0.88)],
		[Vector3(-18.0, 1.5, -14.0), Vector3(-16.0, 6.0, -7.0), 58.0, 0.70, 30.0, Color(1.0, 0.90, 0.74)],
	])
