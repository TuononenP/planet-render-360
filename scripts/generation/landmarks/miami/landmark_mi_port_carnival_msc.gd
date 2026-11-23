class_name LandmarkMiPortCarnivalMsc
extends RefCounted

## MSC Cruise Terminal AA & Carnival Terminal F - PortMiami (MI-2C).
## Site: 25.773500, -80.155500, yaw_deg -64.0, footprint 240 x 72 m, height 26.0 m.
## Architects: Arquitectonica (MSC terminal opened Apr 2025).
##   - Four-level sweeping cantilevered glass hall with white fins (y = 0..22 m),
##     multi-deck boarding fingers on the water side, garage wing at the rear.
##   - South-side red-and-white Post-Panamax container gantry crane frame,
##     portal girder exactly 26.0 m.

const HEIGHT_M := 26.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Apron", LandmarkMaterials.pbr("concrete", "#BDBBB5", 6.0))
	lm.use("WhiteFin", LandmarkMaterials.paint("#F4F6F8", 0.32, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#23566E"))
	lm.use("Garage", LandmarkMaterials.pbr("concrete", "#A8A7A1", 4.0))
	lm.use("CraneRed", LandmarkMaterials.paint("#C42B22", 0.50, 0.30))
	lm.use("CraneWhite", LandmarkMaterials.paint("#EEF0F2", 0.50, 0.30))
	lm.use("DeckLamp", LandmarkMaterials.lit("#FFD79A", 1.4))

	lm.box("Apron", Vector3(0.0, 0.05, 0.0), Vector3(240.0, 0.5, 72.0))
	# Four-level cantilevered hall, each deck stepping toward the water (+z)
	for lv: int in 4:
		var y0 := 0.3 + float(lv) * 5.5
		var w := 220.0 - float(lv) * 10.0
		var zc := -4.0 + float(lv) * 2.5
		lm.box("Glass", Vector3(0.0, y0 + 2.5, zc), Vector3(w, 5.0, 36.0))
		lm.box("WhiteFin", Vector3(0.0, y0 + 5.2, zc + 1.5), Vector3(w + 4.0, 0.6, 41.0), Basis(), 0.1)
		lm.box("DeckLamp", Vector3(0.0, y0 + 4.85, zc + 22.2), Vector3(w * 0.9, 0.12, 0.12))
		for i: int in 23:
			var fx := -w * 0.5 + w * float(i) / 22.0
			lm.box("WhiteFin", Vector3(fx, y0 + 2.6, zc + 18.4), Vector3(0.5, 5.2, 1.4))
	# Multi-deck boarding fingers
	for fx: float in [-70.0, -10.0, 50.0, 100.0]:
		for lv: int in 3:
			var y := 6.5 + float(lv) * 5.5
			lm.box("WhiteFin", Vector3(fx, y, 40.0), Vector3(5.0, 3.0, 22.0))
			lm.box("Glass", Vector3(fx, y, 40.0), Vector3(5.1, 1.4, 22.1))
	# Garage wing
	lm.box("Garage", Vector3(0.0, 11.0, -27.5), Vector3(200.0, 22.0, 15.0))
	# Gantry crane (south side) - portal frame, girder top at 26.0 m
	for cx: float in [-20.0, 20.0]:
		for cz: float in [-34.0, -26.0]:
			lm.beam("CraneRed", Vector3(cx, 0.3, cz), Vector3(cx, 25.2, cz), 1.2, 1.2)
	for cx: float in [-20.0, 20.0]:
		lm.box("CraneRed", Vector3(cx, 25.6, -30.0), Vector3(1.6, 0.8, 10.0))
	lm.box("CraneWhite", Vector3(0.0, 25.6, -30.0), Vector3(44.0, 0.8, 2.0))
	lm.beam("CraneWhite", Vector3(-20.0, 25.2, -30.0), Vector3(-52.0, 21.0, -30.0), 1.0, 1.0)
	lm.beam("CraneWhite", Vector3(20.0, 25.2, -30.0), Vector3(52.0, 21.0, -30.0), 1.0, 1.0)
	lm.commit(model)

	var warm := Color(1.0, 0.84, 0.58)
	var cool := Color(0.70, 0.88, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-90.0, 4.0, 58.0), Vector3(-40.0, 12.0, 20.0), 90.0, 1.2, 70.0, warm],
		[Vector3(0.0, 4.0, 58.0), Vector3(0.0, 12.0, 20.0), 90.0, 1.2, 70.0, cool],
		[Vector3(90.0, 4.0, 58.0), Vector3(40.0, 12.0, 20.0), 90.0, 1.2, 70.0, warm],
	])
