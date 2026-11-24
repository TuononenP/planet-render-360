class_name VnSanGiorgio
extends RefCounted

## Basilica di San Giorgio Maggiore (Andrea Palladio, 1566–1610) + 75 m
## red-brick campanile + Benedictine monastery front + twin white Bacino
## boat-harbour lighthouses.
## Local frame: +Z faces the Bacino di San Marco / Piazzetta (~290°, yaw 110°).

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1ECE1", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B85840", 2.6))
	lm.use("Roof", LandmarkVnKit.terracotta("#A4644B", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A8", 2.2))

	# Raised Istrian-stone island platform & broad steps along Bacino front (+Z)
	lm.box("Algae", Vector3(0.0, 0.15, 4.0), Vector3(92.0, 0.5, 68.0))
	lm.box("Stone", Vector3(0.0, 0.8, 4.0), Vector3(90.0, 1.0, 66.0))
	for k in 4:
		lm.box("Trim", Vector3(0.0, 0.35 + 0.25 * float(k), 34.5 - 0.9 * float(k)),
			Vector3(34.0, 0.3, 1.0))

	# Palladio's dazzling white interlocking twin-temple facade at z = +26.5 m
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(0.0, 1.3, 26.5), Vector3.RIGHT, Vector3(0, 0, 1),
		34.0, 19.5, 22.0, 13.5, 6.2, 4)

	# Cruciform brick basilica nave, side aisles, transept apses & pitched terracotta roof
	lm.box("Brick", Vector3(0.0, 10.5, -2.0), Vector3(19.0, 19.0, 56.0))
	lm.box("Brick", Vector3(0.0, 6.8, -2.0), Vector3(33.0, 11.6, 52.0))
	lm.gable("Roof", Vector3(0.0, 20.0, -2.0), 19.8, 56.4, 4.2, Basis(), 0.3, "Brick")
	# Transept arms with semicircular apses
	lm.box("Brick", Vector3(0.0, 10.2, -10.0), Vector3(44.0, 18.2, 16.0))
	lm.gable("Roof", Vector3(0.0, 19.3, -10.0), 16.6, 44.4, 3.6, Basis(Vector3.UP, PI * 0.5), 0.3, "Brick")
	for sx in [-1.0, 1.0]:
		lm.frustum("Brick", Vector3(sx * 22.0, 1.2, -10.0), 7.8, 7.8, 16.5, 16)
		lm.frustum("Roof", Vector3(sx * 22.0, 17.7, -10.0), 8.2, 0.4, 3.0, 16)

	# Great crossing ribbed lead dome + lantern + gilt finial (~46 m)
	LandmarkVnKit.venetian_dome(lm, "Brick", "Trim", "Lead", "Glass", "Gold",
		Vector3(0.0, 20.5, -10.0), 8.2, 7.6, 10.2, 5.2, 2.5)
	lm.frustum("Lamp", Vector3(0.0, 38.6, -10.0), 1.6, 1.6, 2.6, 8)

	# 75.0 m square Venetian red-brick campanile with white Istrian belfry & conical spire (south-east of church)
	LandmarkVnKit.campanile(lm, "Brick", "Trim", "Trim", "Glass", "Gold",
		Vector3(24.0, 1.2, -2.0), 9.4, 73.8, 0.0, false)
	lm.box("Lamp", Vector3(24.0, 50.8, -2.0), Vector3(5.8, 6.2, 5.8))

	# Benedictine monastery & Palladian cloister wing flanking to the right (-X)
	lm.box("Brick", Vector3(-31.0, 8.2, -4.0), Vector3(26.0, 14.0, 44.0))
	lm.box("Trim", Vector3(-31.0, 15.4, -4.0), Vector3(26.8, 0.6, 44.8))
	lm.gable("Roof", Vector3(-31.0, 15.7, -4.0), 26.6, 44.6, 3.4, Basis(), 0.25, "Brick")
	for i in 5:
		var wz := -18.0 + 9.0 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-44.0, 9.0, wz), Vector3(-1, 0, 0), 1.8, 3.4, true, 0.16)

	# Twin white Istrian-stone small boat-harbour lighthouse towers guarding the Bacino basin (+Z)
	for sx in [-1.0, 1.0]:
		var lp := Vector3(sx * 36.0, 0.6, 35.0)
		lm.box("Stone", lp + Vector3(0, 1.6, 0), Vector3(4.6, 3.2, 4.6))
		lm.frustum("Trim", lp + Vector3(0, 3.2, 0), 1.45, 1.2, 5.4, 12)
		lm.frustum("Lamp", lp + Vector3(0, 8.6, 0), 0.95, 0.95, 1.4, 10)
		lm.lathe("Lead", lp + Vector3(0, 10.0, 0), LandmarkVnKit.dome_profile(1.2, 1.4), 10)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-10.0, 1.8, 36.0), Vector3(-6.0, 16.0, 26.5), 50.0, 1.05],
		[Vector3(10.0, 1.8, 36.0), Vector3(6.0, 16.0, 26.5), 50.0, 1.05],
		[Vector3(24.0, 1.8, 16.0), Vector3(24.0, 48.0, -2.0), 42.0, 1.0],
		[Vector3(0.0, 22.0, 6.0), Vector3(0.0, 36.0, -10.0), 48.0, 0.85],
	])
