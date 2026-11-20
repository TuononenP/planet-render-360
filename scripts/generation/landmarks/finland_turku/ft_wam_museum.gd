class_name FtWamMuseum
extends RefCounted

## Wäinö Aaltonen Museum of Art (WAM, 1967, Irma & Matti Aaltonen):
## White travertine modernist riverside museum on Itäinen Rantakatu 38
## (+X ENE along river, -Z NNW facing Aurajoki, yaw_deg = -31.0°,
## height_m = 16.0):
##   - Stepped cubic white travertine/limestone gallery volumes following the
##     river curve (main sculpture hall 30 x 22 m rising to 15.8 m, flanking
##     gallery wings 11.2 m and 8.4 m) with crisp horizontal shadow reveals.
##   - Elevated panoramic granite sculpture terrace facing Aurajoki (-Z) with
##     wide steps, dark-bronze glazed lobby & café, and Wäinö Aaltonen's
##     monumental riverside bronze/granite sculptures on the quay terrace.
## Surfaces: 8 merged PBR parts (Travertine, Stone, Concrete, Roof, Frame,
## Bronze, Glass, Lamp).

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("stone", "#ECE7DC", 3.0, 0.70))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7C76", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C4BC", 2.8))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#505458", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#2A2E33", 0.45, 0.55))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#434E46", 1.8, 0.38, 0.74))
	lm.use("Glass", LandmarkMaterials.glass("#263642"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.4))

	# Panoramic riverside granite sculpture terrace & approach steps (-Z faces Aurajoki).
	LandmarkFrKit.rect(lm, "Stone", -32.0, 32.0, -24.5, 16.0, FOUND, 1.4)
	for step in 4:
		var t := float(step) / 3.0
		var sz := lerpf(-24.5, -26.8, t)
		var sy := lerpf(1.3, 0.2, t)
		LandmarkFrKit.rect(lm, "Stone", -18.0, 18.0, sz - 0.65, sz, FOUND, sy)
	# Central tall white travertine main sculpture hall (28 x 22 m, H 15.8 m).
	LandmarkFrKit.rect(lm, "Travertine", -14.0, 14.0, -8.0, 14.0, 1.4, 15.6)
	LandmarkFrKit.rect(lm, "Roof", -13.6, 13.6, -7.6, 13.6, 15.6, 15.95)
	# Clerestory skylight band wrapping the upper gallery crown.
	LandmarkFrKit.rect(lm, "Glass", -14.08, 14.08, -7.2, 13.2, 12.8, 14.4)
	LandmarkFrKit.rect(lm, "Glass", -13.2, 13.2, -8.08, 14.08, 12.8, 14.4)
	LandmarkFrKit.rect(lm, "Lamp", -12.6, 12.6, -6.8, 12.8, 13.0, 14.2)
	# Stepped west gallery wing (-X = -30..-14, H 11.2 m) & east foyer/café wing (+X = 14..30, H 8.4 m).
	LandmarkFrKit.rect(lm, "Travertine", -30.0, -14.0, -14.0, 12.0, 1.4, 11.0)
	LandmarkFrKit.rect(lm, "Roof", -29.6, -14.2, -13.6, 11.6, 11.0, 11.3)
	LandmarkFrKit.rect(lm, "Travertine", 14.0, 30.0, -16.0, 10.0, 6.2, 8.4)
	LandmarkFrKit.rect(lm, "Roof", 14.2, 29.6, -15.6, 9.6, 8.4, 8.7)
	# Panoramic glazed riverfront museum foyer & café (-Z = -16..-8).
	LandmarkFrKit.rect(lm, "Travertine", -14.0, 14.0, -16.5, -8.0, 6.2, 8.4)
	LandmarkFrKit.rect(lm, "Glass", -13.5, 29.4, -16.1, -15.9, 1.45, 6.2)
	LandmarkFrKit.rect(lm, "Glass", 29.4, 29.6, -15.9, 9.4, 1.45, 6.2)
	LandmarkFrKit.rect(lm, "Lamp", -12.5, 28.0, -14.8, -14.4, 1.8, 5.8)
	for k in 15:
		var mx := lerpf(-13.2, 29.2, float(k) / 14.0)
		lm.box("Frame", Vector3(mx, 3.85, -16.15), Vector3(0.16, 4.8, 0.24))
	# Architectural vertical stone joints on the travertine sculpture hall.
	for k in 11:
		var rx := lerpf(-13.0, 13.0, float(k) / 10.0)
		lm.box("Concrete", Vector3(rx, 8.5, -8.06), Vector3(0.12, 8.2, 0.12))
	# Monumental Wäinö Aaltonen bronze sculptures on granite pedestals on the riverside terrace (-Z).
	for sc: Array in [[-21.0, -20.0, 3.2], [6.0, -20.5, 2.8]]:
		var sx: float = sc[0]
		var sz: float = sc[1]
		var sh: float = sc[2]
		LandmarkFrKit.rect(lm, "Stone", sx - 1.2, sx + 1.2, sz - 1.2, sz + 1.2, 1.4, 2.55)
		lm.frustum("Bronze", Vector3(sx, 2.55, sz), 0.65, 0.35, sh, 10)
		lm.lathe("Bronze", Vector3(sx, 2.55 + sh, sz), LandmarkFrKit.ball(0.42), 8)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.8, -28.0), Vector3(0.0, 10.0, -8.0), 60.0, 0.85, 42.0, Color(1.0, 0.90, 0.74)],
		[Vector3(-22.0, 1.8, -26.0), Vector3(-22.0, 7.0, -14.0), 58.0, 0.70, 34.0, Color(1.0, 0.90, 0.74)],
		[Vector3(20.0, 1.8, -26.0), Vector3(20.0, 5.5, -16.0), 58.0, 0.75, 34.0, Color(1.0, 0.90, 0.74)],
	])
