class_name FtPinellaPorthan
extends RefCounted

## Pinella Pavilion & H.G. Porthan Monument (1848 / 1864, Porthaninpuisto):
## Historic white neoclassical riverside pavilion by Tuomiokirkkosilta plus
## C.E. Sjöstrand's 1864 bronze H.G. Porthan statue (+X ENE along Aurajoki,
## -Z NNW facing Aurajoki, +Z SSE into Porthaninpuisto, yaw_deg = -34.0°,
## height_m = 8.0):
##   - White neoclassical Pinella pavilion (24 x 11 m, eaves 5.4 m, low hipped
##     copper/slate roof to 7.8 m) with 6-column fluted Doric colonnade portico
##     facing Aurajoki (-Z), entablature & triangular pediment.
##   - Contemporary glazed river terrace café pavilion along the riverfront (-Z)
##     with warm glowing evening interior.
##   - H.G. Porthan Monument in Porthaninpuisto (+Z = +16 m): stepped grey-
##     granite base, polished red-granite plinth, and seated bronze statue of
##     Henrik Gabriel Porthan (top 6.8 m).
## Surfaces: 8 merged PBR parts (White, Stone, RedGranite, Bronze, Roof,
## Frame, Glass, Lamp).

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F2EFE6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#86827B", 2.4))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#8A4E44", 2.2))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#3D4E45", 1.8, 0.40, 0.72))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A4044", 2.2))
	lm.use("Frame", LandmarkMaterials.paint("#2B3035", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263742"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BA", 1.45))

	# Pinella white neoclassical pavilion (24 x 10.5 m, eaves 5.4 m, hipped roof 7.8 m).
	LandmarkFrKit.rect(lm, "Stone", -12.4, 12.4, -5.8, 5.4, FOUND, 0.85)
	LandmarkFrKit.rect(lm, "White", -12.0, 12.0, -2.5, 5.0, 0.85, 5.4)
	LandmarkFrParts.cornice_ring(lm, "White", -12.0, 12.0, -5.4, 5.0, 5.05, 0.42)
	LandmarkFrKit.hip(lm, "Roof", -12.0, 12.0, -5.4, 5.0, 5.4, 2.45, 0.45)
	# Iconic 6-column Doric portico facing Aurajoki (-Z) with central pediment.
	LandmarkFrKit.rect(lm, "White", -12.0, 12.0, -5.4, -2.5, 4.75, 5.4)
	for k in 6:
		var cx := lerpf(-10.6, 10.6, float(k) / 5.0)
		lm.frustum("White", Vector3(cx, 0.85, -5.05), 0.30, 0.25, 3.9, 12)
		lm.box("White", Vector3(cx, 4.72, -5.05), Vector3(0.68, 0.16, 0.68))
	LandmarkFrParts.gable_wall(lm, "White", Vector3(0.0, 5.4, -5.35), Vector3.RIGHT, Vector3.FORWARD, 11.4, 1.95, 0.45)
	# Tall neoclassical arched windows under the portico & warm glowing dining hall.
	LandmarkFrParts.openings(lm, "White", "Glass", Vector3(-9.5, 1.25, -2.5), Vector3(9.5, 1.25, -2.5),
		Vector3.FORWARD, 5, 1.85, 3.2, LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)
	LandmarkFrParts.openings(lm, "White", "Glass", Vector3(-9.5, 1.25, 5.0), Vector3(9.5, 1.25, 5.0),
		Vector3.BACK, 5, 1.75, 3.0, LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)
	LandmarkFrKit.rect(lm, "Lamp", -9.0, 9.0, -1.8, -1.5, 1.5, 4.2)
	# Modern glazed riverside terrace pavilion (-Z = -10.5..-5.8).
	LandmarkFrKit.rect(lm, "Stone", -11.5, 11.5, -10.8, -5.8, FOUND, 0.32)
	LandmarkFrKit.rect(lm, "Glass", -10.8, 10.8, -10.2, -5.9, 0.32, 3.35)
	LandmarkFrKit.rect(lm, "Frame", -11.2, 11.2, -10.5, -5.7, 3.35, 3.68)
	for k in 9:
		var mx := lerpf(-10.6, 10.6, float(k) / 8.0)
		lm.box("Frame", Vector3(mx, 1.85, -10.24), Vector3(0.12, 3.05, 0.14))
	LandmarkFrKit.rect(lm, "Lamp", -9.6, 9.6, -9.2, -6.8, 3.15, 3.32)
	# H.G. Porthan Monument (C.E. Sjöstrand, 1864) in Porthaninpuisto (+Z = +16.0).
	var pc := Vector3(0.0, 0.0, 16.0)
	LandmarkFrKit.rect(lm, "Stone", -3.2, 3.2, 12.8, 19.2, FOUND, 0.45)
	LandmarkFrKit.rect(lm, "Stone", -2.2, 2.2, 13.8, 18.2, 0.45, 0.95)
	LandmarkFrKit.rect(lm, "RedGranite", -1.45, 1.45, 14.55, 17.45, 0.95, 3.95)
	LandmarkFrKit.rect(lm, "RedGranite", -1.65, 1.65, 14.35, 17.65, 3.75, 4.05)
	# Seated bronze figure of H.G. Porthan (chair, torso, head & book scroll).
	lm.box("Bronze", pc + Vector3(0.0, 4.65, 0.25), Vector3(1.15, 1.25, 0.95))
	lm.frustum("Bronze", pc + Vector3(0.0, 4.65, -0.05), 0.52, 0.42, 1.35, 10)
	lm.lathe("Bronze", pc + Vector3(0.0, 6.02, -0.05), LandmarkFrKit.ball(0.28), 10)
	lm.box("Bronze", pc + Vector3(0.45, 5.15, -0.35), Vector3(0.26, 0.55, 0.38))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.2, -14.5), Vector3(0.0, 4.0, -5.0), 64.0, 0.85, 28.0, Color(1.0, 0.88, 0.68)],
		[Vector3(0.0, 1.0, 21.5), Vector3(0.0, 5.2, 16.0), 42.0, 0.80, 18.0, Color(1.0, 0.86, 0.64)],
	])
