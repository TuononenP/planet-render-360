class_name LandmarkMiPortTerminalA
extends RefCounted

## Royal Caribbean Terminal A "Crown of Miami" - PortMiami (MI-2C).
## Site: 25.778600, -80.162800, yaw_deg -64.0, footprint 165 x 62 m, height 36.0 m.
## Architects: Broadway Malyan (2018).
##   - Concrete boarding podium (y = -0.2..6.2 m) under a hall of five faceted,
##     crystalline glass pyramids (y = 6.2..peak) whose touching valleys read as a
##     giant "M" / crown from the water; centre peak exactly 36.0 m.
##   - White aluminium fold ribs along every pyramid arris, cyan crown strips (CrownLamp).
##   - Elevated boarding gangways on the water side and a parking-garage wing behind.

const HEIGHT_M := 36.0
const BASE_Y := 6.2
const PEAKS := [24.0, 31.0, 36.0, 31.0, 24.0]
const HW := 16.5
const HZ := 22.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C9C7C1", 5.0))
	lm.use("WhiteAlu", LandmarkMaterials.paint("#F3F5F7", 0.30, 0.50))
	lm.use("Glass", LandmarkMaterials.glass("#1F4A66"))
	lm.use("Steel", LandmarkMaterials.paint("#9AA3AB", 0.40, 0.60))
	lm.use("Garage", LandmarkMaterials.pbr("concrete", "#A9A8A2", 4.0))
	lm.use("CrownLamp", LandmarkMaterials.lit("#33C8FF", 2.4))

	lm.box("Podium", Vector3(0.0, 3.0, 0.0), Vector3(165.0, 6.4, 62.0))
	for i: int in 5:
		var cx := -66.0 + 33.0 * float(i)
		var h: float = PEAKS[i] - BASE_Y
		lm.lathe("Glass", Vector3(cx, BASE_Y, 0.0),
			PackedVector2Array([Vector2(1.4142, 0.0), Vector2(0.0, h)]), 4, HW, HZ, PI * 0.25, false)
		var peak := Vector3(cx, PEAKS[i], 0.0)
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var corner := Vector3(cx + sx * HW, BASE_Y, sz * HZ)
				lm.beam("WhiteAlu", corner, peak, 0.55, 0.55)
				if sz > 0.0:
					lm.beam("CrownLamp", corner + Vector3(0, 0.2, 0.35), peak + Vector3(0, -0.1, 0.35), 0.22, 0.22)
		lm.box("WhiteAlu", Vector3(cx, BASE_Y + 0.15, 0.0), Vector3(2.0 * HW, 0.3, 2.0 * HZ))
	# Parking garage wing behind the hall
	lm.box("Garage", Vector3(0.0, BASE_Y + 6.0, -26.5), Vector3(150.0, 12.0, 9.0))
	for k: int in 4:
		lm.box("Steel", Vector3(0.0, BASE_Y + 2.5 + float(k) * 3.0, -21.9), Vector3(150.0, 0.5, 0.3))
	# Elevated boarding gangways
	for gx: float in [-45.0, 0.0, 45.0]:
		lm.box("WhiteAlu", Vector3(gx, 10.0, 37.0), Vector3(4.2, 3.0, 12.0))
		lm.box("Glass", Vector3(gx, 10.0, 37.0), Vector3(4.3, 1.4, 12.1))
		for gz: float in [33.0, 41.0]:
			lm.box("Steel", Vector3(gx, 4.5, gz), Vector3(1.0, 9.0, 1.0))
	lm.commit(model)

	var cyan := Color(0.20, 0.78, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-60.0, 5.0, 50.0), Vector3(-33.0, 22.0, 0.0), 80.0, 1.2, 70.0, cyan],
		[Vector3(0.0, 5.0, 52.0), Vector3(0.0, 28.0, 0.0), 80.0, 1.4, 70.0, cyan],
		[Vector3(60.0, 5.0, 50.0), Vector3(33.0, 22.0, 0.0), 80.0, 1.2, 70.0, cyan],
	])
