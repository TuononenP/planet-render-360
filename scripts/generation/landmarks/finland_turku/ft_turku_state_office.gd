class_name FtTurkuStateOffice
extends RefCounted

## Turku State Office Building (Valtion virastotalo, 1967, Luukkonen &
## Stenros): monumental modernist civic office complex on Itäinen Rantakatu
## between City Theatre and WAM (+X ENE along river, -Z NNW facing Aurajoki,
## yaw_deg = -31.0°, height_m = 34.5):
##   - Elevated granite riverside plaza & open pilotis colonnade plinth
##     raising the main office volume above Itsenäisyydenaukio.
##   - Crisp 9-storey white/pale-grey precast concrete slab (76 x 18 m,
##     H 34.5 m) with rhythmic vertical precast facade fins, continuous
##     recessed ribbon windows, and warm night office bands.
##   - Low 2-storey civic customer-service podium wing wrapping the riverside
##     forecourt (-Z, H 8.2 m).
## Surfaces: 7 merged PBR parts (White, Concrete, Stone, Roof, Frame,
## Glass, Lamp).

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#ECE9E2", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B7B2", 2.8))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7A7874", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C5054", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#2A2E33", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#243440"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC2", 1.25))

	# Elevated granite riverside plaza & low 2-storey civic podium (-Z toward Aurajoki).
	LandmarkFrKit.rect(lm, "Stone", -42.0, 42.0, -26.0, 18.0, FOUND, 1.0)
	LandmarkFrKit.rect(lm, "White", -38.0, 38.0, -22.0, -6.0, 5.4, 8.2)
	LandmarkFrKit.rect(lm, "Roof", -37.6, 37.6, -21.6, -6.4, 8.2, 8.5)
	LandmarkFrKit.rect(lm, "Glass", -36.5, 36.5, -21.8, -21.6, 1.1, 5.4)
	LandmarkFrKit.rect(lm, "Lamp", -34.0, 34.0, -20.2, -19.8, 1.4, 5.0)
	for k in 13:
		var px := lerpf(-36.0, 36.0, float(k) / 12.0)
		lm.box("Concrete", Vector3(px, 3.25, -22.0), Vector3(0.45, 4.5, 0.45))
	# Elevated pilotis colonnade supporting the 9-storey main office slab (76 x 18 m, H 34.5 m).
	for k in 13:
		var px := lerpf(-36.0, 36.0, float(k) / 12.0)
		for pz: float in [-4.5, 11.5]:
			lm.box("Concrete", Vector3(px, 3.6, pz), Vector3(0.75, 5.2, 0.75))
	LandmarkFrKit.rect(lm, "Glass", -34.0, 34.0, -3.5, 10.5, 1.0, 6.2)
	# Main 9-storey precast concrete office slab (y = 6.2..33.6 m + rooftop plant to 34.6 m).
	LandmarkFrKit.rect(lm, "White", -38.0, 38.0, -5.5, 12.5, 6.2, 33.6)
	LandmarkFrKit.rect(lm, "Roof", -37.6, 37.6, -5.1, 12.1, 33.6, 34.0)
	LandmarkFrKit.rect(lm, "Concrete", -18.0, 18.0, 0.0, 7.5, 33.6, 34.6)
	# Eight continuous recessed horizontal office ribbon-window floors + rhythmic precast fins.
	for fl in 8:
		var wy := 7.2 + float(fl) * 3.25
		LandmarkFrKit.rect(lm, "Glass", -37.6, 37.6, -5.58, -5.42, wy, wy + 1.85)
		LandmarkFrKit.rect(lm, "Glass", -37.6, 37.6, 12.42, 12.58, wy, wy + 1.85)
		if fl % 2 == 0:
			LandmarkFrKit.rect(lm, "Lamp", -35.0, 35.0, -4.8, -4.5, wy + 0.25, wy + 1.6)
	for k in 25:
		var fx := lerpf(-37.2, 37.2, float(k) / 24.0)
		lm.box("Concrete", Vector3(fx, 19.9, -5.66), Vector3(0.24, 27.2, 0.36))
		lm.box("Concrete", Vector3(fx, 19.9, 12.66), Vector3(0.24, 27.2, 0.36))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 2.0, -28.0), Vector3(-20.0, 18.0, -5.5), 60.0, 0.75, 52.0, Color(0.95, 0.94, 0.90)],
		[Vector3(22.0, 2.0, -28.0), Vector3(20.0, 18.0, -5.5), 60.0, 0.75, 52.0, Color(0.95, 0.94, 0.90)],
	])
