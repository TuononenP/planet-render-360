class_name FtTurkuFireStation
extends RefCounted

## Turku Central Fire Station (Turun keskuspaloasema, J. Eskil Hindersson, 1916)
## at Eerikinkatu 35.
## Origin at 60.448350 N, 22.258250 E, yaw_deg -35.0.
##
## Architectural & facade spec:
## - Monumental red-brick Classicist/Jugend fire station (46.0 x 26.0 m) on
##   a grey-granite plinth (y = -1.8..1.8 m), eaves 12.0 m, steep terracotta
##   hipped roof (ridge 16.0 m).
## - 6 rhythmic arched appliance garage bays along Eerikinkatu (+Z) with
##   deep crimson-red framed glazed doors and granite keystones.
## - Iconic 27.7 m square red-brick hose-drying & lookout tower on the rear
##   corner (+X/-Z) with granite trim, clock dials, open belfry gallery &
##   patinated green-copper hipped lantern roof peaking at 27.7 m.

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86827A", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#944432", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E8E2D4", 2.0))
	lm.use("RedDoor", LandmarkMaterials.pbr("wood", "#8E2822", 1.8))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9C4A34", 2.2))
	lm.use("Copper", LandmarkFrKit.copper("#487464"))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.9))

	# Main red-brick station block (46.0 x 22.0 m, eaves 12.0 m).
	LandmarkFrKit.rect(lm, "Granite", -23.2, 23.2, -11.2, 11.2, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Brick", -23.0, 23.0, -11.0, 11.0, 1.8, 12.0)
	LandmarkFrKit.rect(lm, "Trim", -23.3, 23.3, -11.3, 11.3, 11.75, 12.25)
	LandmarkFrKit.hip(lm, "Tile", (0.0) - (46.8) * 0.5, (0.0) + (46.8) * 0.5, (0.0) - (22.8) * 0.5, (0.0) + (22.8) * 0.5, 12.25, 3.8, 0.0)

	# 6 rhythmic arched appliance garage doors along Eerikinkatu (+Z).
	for i in 6:
		var gx := lerpf(-16.5, 16.5, float(i) / 5.0)
		LandmarkFrParts.opening(lm, "Granite", "RedDoor", Vector3(gx, 0.1, 11.05), Vector3(0, 0, 1),
			3.8, 4.3, LandmarkFrParts.HEAD_ROUND, 0.30, 0.18, 2)
		# Upper fanlight glow inside appliance bay.
		lm.box("WarmGlow", Vector3(gx, 3.3, 11.10), Vector3(3.0, 0.85, 0.06), Basis(), 0.0)
		# Two upper residential/office storeys above each bay.
		for fl in 2:
			var wy := 5.8 + float(fl) * 3.0
			LandmarkFrParts.opening(lm, "Trim", "WarmGlow" if (i + fl) % 3 == 0 else "Glass",
				Vector3(gx, wy, 11.02), Vector3(0, 0, 1), 1.65, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass",
				Vector3(gx, wy, -11.02), Vector3(0, 0, -1), 1.65, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)

	# Central pedimented gable over the main appliance bays.
	LandmarkFrKit.rect(lm, "Brick", -5.8, 5.8, 10.8, 11.5, 12.0, 14.4)
	LandmarkFrKit.gable(lm, "Tile", (0.0) - (12.0) * 0.5, (0.0) + (12.0) * 0.5, (10.4) - (3.2) * 0.5, (10.4) + (3.2) * 0.5, 12.25, 3.4, 0.0, "", 0)

	# Tall red-brick hose-drying & lookout tower (+X = 16.5, -Z = -9.5, peaking at 27.7 m).
	var tx := 16.5
	var tz := -9.5
	LandmarkFrKit.rect(lm, "Granite", tx - 3.4, tx + 3.4, tz - 3.4, tz + 3.4, FOUND, 2.2)
	LandmarkFrKit.rect(lm, "Brick", tx - 3.2, tx + 3.2, tz - 3.2, tz + 3.2, 2.2, 21.8)
	LandmarkFrKit.rect(lm, "Trim", tx - 3.45, tx + 3.45, tz - 3.45, tz + 3.45, 21.55, 22.1)
	# Vertical hose-tower slit windows & lookout gallery openings.
	for d in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var n: Vector3 = d
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx, 14.0, tz) + n * 3.22, n,
			1.1, 5.2, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
		LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(tx, 19.6, tz) + n * 3.22, n,
			1.8, 1.5, LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)
	# Copper lantern roof peaking at 27.7 m.
	lm.frustum("Copper", Vector3(tx, 22.1, tz), 4.5, 1.8, 2.6, 4)
	lm.frustum("Trim", Vector3(tx, 24.7, tz), 1.6, 1.6, 1.1, 8)
	lm.frustum("Copper", Vector3(tx, 25.8, tz), 1.75, 0.08, 1.9, 8)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 0.9, 16.5), Vector3(0.0, 7.5, 11.0), 32.0, 0.95, 60.0, warm],
		[Vector3(22.0, 1.2, -15.0), Vector3(16.5, 18.0, -9.5), 34.0, 1.0, 55.0, warm],
	])
