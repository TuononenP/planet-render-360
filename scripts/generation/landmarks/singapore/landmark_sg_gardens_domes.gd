class_name LandmarkSgGardensDomes
extends RefCounted

## Flower Dome (38 m) & Cloud Forest (58 m) — Gardens by the Bay Conservatories (SG-2.9):
## - Twin asymmetric column-free glass gridshell conservatories by WilkinsonEyre:
##   - Flower Dome: low, sweeping seashell-curved glass dome (98 x 68 m, 38 m tall).
##   - Cloud Forest: taller, sharply peaked conical-shell glass dome (76 x 56 m, 58 m tall)
##     with its lush green indoor mist-mountain core readable through the translucent glass.
## - Crisp white external structural steel arch ribs standing proud of both glass skins.
## - Night: soft warm-cyan and amber interior glow shining through the glass shells.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#8EB8CC"))
	lm.use("WhiteSteel", LandmarkMaterials.pbr("sheet_metal", "#F0F2F4", 2.0, 0.24, 0.72))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#D6D2C8", 3.0))
	lm.use("Mountain", LandmarkMaterials.pbr("forest", "#2C6432", 3.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE4A8", 1.5))
	lm.use("MistLamp", LandmarkMaterials.lit("#8CE2FF", 1.6))

	# Shared waterfront garden podium, dark-green landscaped rim & linking glazed lobby plaza.
	lm.box("Podium", Vector3(0.0, 2.0, 0.0), Vector3(188.0, 4.0, 96.0))
	lm.box("Glass", Vector3(0.0, 7.0, 0.0), Vector3(30.0, 8.5, 34.0))
	lm.box("WhiteSteel", Vector3(0.0, 11.4, 0.0), Vector3(32.0, 0.8, 36.0))

	# 1. Flower Dome (west/south-west seashell gridshell: low, expansive, 38 m top)
	# with WilkinsonEyre's signature parallel crescent-sweeping white external steel arch ribs.
	var fd := Vector3(-44.0, 3.8, 4.0)
	LandmarkSgKit.loft_shell(lm, "Glass", fd, 50.0, 36.0, 34.2, 14, 32, 0.78)
	_crescent_arch_ribs(lm, "WhiteSteel", fd, 50.0, 36.0, 34.2, 11, 1.15, 0.9, 18, 0.78)
	LandmarkSgKit.loft_shell(lm, "WarmLamp", fd + Vector3(0.0, 1.0, 0.0), 42.0, 29.0, 24.0, 6, 16, 0.8)

	# 2. Cloud Forest (east/north-east shell: taller, sharply peaked, 58 m top)
	# with parallel crescent-sweeping external white steel arch ribs & misty Cloud Mountain core.
	var cf := Vector3(52.0, 3.8, -6.0)
	LandmarkSgKit.loft_shell(lm, "Glass", cf, 39.0, 30.0, 54.2, 16, 32, 0.62)
	_crescent_arch_ribs(lm, "WhiteSteel", cf, 39.0, 30.0, 54.2, 9, 1.25, 0.95, 20, 0.62)
	# Internal 38 m lush green Cloud Mountain & mist waterfall visible inside the glass dome.
	lm.frustum("Mountain", cf + Vector3(0.0, 0.5, 0.0), 18.0, 10.0, 38.0, 12)
	LandmarkAsiaSouthUtil.dome(lm, "Mountain", cf + Vector3(0.0, 38.0, 0.0), 10.0, 8.0, 10, 5)
	lm.frustum("MistLamp", cf + Vector3(0.0, 2.0, 0.0), 28.0, 18.0, 32.0, 14)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-44.0, 4.0, 48.0), Vector3(-44.0, 22.0, 4.0), 65.0, 1.2],
		[Vector3(52.0, 4.0, 34.0), Vector3(52.0, 34.0, -6.0), 65.0, 1.3],
	])

static func _crescent_arch_ribs(lm: LandmarkMesh, key: String, center: Vector3, rx: float, rz: float,
		height: float, rib_count: int, stand_off: float, tube_w: float, steps: int, power: float) -> void:
	# Parallel crescent-sweeping arch ribs spanning across Z along the X axis (signature seashell silhouette).
	for i in rib_count:
		var u := -0.82 + 1.64 * float(i) / float(maxi(rib_count - 1, 1))
		var x_base := center.x + u * rx
		var span_scale := sqrt(maxf(0.08, 1.0 - u * u))
		var prev := Vector3.ZERO
		for s in steps + 1:
			var w := -1.0 + 2.0 * float(s) / float(steps)
			var z_rel := w * span_scale
			var rad_sq := clampf(u * u + z_rel * z_rel, 0.0, 1.0)
			var elev := pow(sqrt(maxf(0.0, 1.0 - rad_sq)), power)
			var y := center.y + (height + stand_off) * elev
			# Subtle crescent sweep along X so ribs echo a nautilus shell.
			var x_sweep := x_base + (1.0 - w * w) * rx * 0.08
			var p := Vector3(x_sweep, y, center.z + z_rel * (rz + stand_off))
			if s > 0:
				lm.beam(key, prev, p, tube_w, tube_w * 1.15)
			prev = p
