class_name VnProcuratie
extends RefCounted

## Piazza San Marco 3-sided monumental Istrian-stone enclosure (`VN-4.1`):
## - Procuratie Vecchie (north, -Z: 152 m, Bartolomeo Bon's 50-arch ground arcade + double upper arcades + scalloped merlons)
## - Procuratie Nuove (south, +Z: Scamozzi's 3-tier Doric/Ionic/Corinthian arcade with pedimented windows + Caffè Florian lamps)
## - Ala Napoleonica / Museo Correr (west, -X: monumental attic with classical emperors' statues & triumphal arch)
## Plus geometric Piazza San Marco white-Istrian inlay paving strips.
## Local frame: +X toward Basilica, -X Ala Napoleonica, -Z north, +Z south. Height = 22.0 m.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F2ECE0", 3.0))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#FAF6EE", 2.2))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B604A", 2.6))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B8B2A5", 3.0))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE1A0", 1.9))

	# Procuratie Vecchie (north wing, z = -44 m, stopped 14 m short of Torre dell'Orologio on east end!)
	_wing_x(lm, -44.0, 130.0, 16.0, 19.2, 1.0, true, -8.0)
	# Procuratie Nuove (south wing, z = +44 m, length 146 m, depth 18 m, height 22.0 m)
	_wing_x(lm, 44.0, 146.0, 18.0, 20.0, -1.0, false, 0.0)
	# Ala Napoleonica / Museo Correr (west closing wing, x = -74 m, width 18 m, span 76 m, height 21.5 m)
	_wing_west(lm, -74.0, 18.0, 76.0, 19.5)

	# Piazza San Marco white Istrian-stone geometric linear inlay bands across the trachyte floor
	for sz in [-28.0, -14.0, 0.0, 14.0, 28.0]:
		lm.box("Trim", Vector3(-6.0, 0.04, float(sz)), Vector3(120.0, 0.06, 0.45))
	for sx in [-54.0, -30.0, -6.0, 18.0, 42.0]:
		lm.box("Trim", Vector3(float(sx), 0.04, 0.0), Vector3(0.45, 0.06, 62.0))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.0, -28.0), Vector3(-42.0, 12.0, -36.0), 58.0, 0.8],
		[Vector3(18.0, 2.0, -28.0), Vector3(18.0, 12.0, -36.0), 58.0, 0.8],
		[Vector3(-42.0, 2.0, 28.0), Vector3(-42.0, 12.0, 35.0), 58.0, 0.8],
		[Vector3(18.0, 2.0, 28.0), Vector3(18.0, 12.0, 35.0), 58.0, 0.8],
		[Vector3(-56.0, 2.0, 0.0), Vector3(-65.0, 12.0, 0.0), 58.0, 0.9],
	])

static func _wing_x(lm: LandmarkMesh, zc: float, length: float, depth: float, eave: float,
		face_dir: float, vecchie: bool, x_off: float = 0.0) -> void:
	var fz := zc + face_dir * (depth * 0.5)
	var out := Vector3(0.0, 0.0, face_dir)
	# Recessed core behind the ground arcade + full upper body
	lm.box("Stone", Vector3(x_off, 3.1, zc - face_dir * 1.4), Vector3(length, 6.2, depth - 2.8))
	lm.box("Stone", Vector3(x_off, 6.2 + (eave - 6.2) * 0.5, zc), Vector3(length, eave - 6.2, depth))
	lm.gable("Roof", Vector3(x_off, eave, zc), depth + 0.5, length + 0.5, 2.0, Basis(Vector3.UP, PI * 0.5), 0.25, "Stone")
	# String courses & crowning cornice
	for sy in [6.3, 12.6, eave - 0.35]:
		lm.box("Trim", Vector3(x_off, float(sy), fz + face_dir * 0.18), Vector3(length + 0.4, 0.48, 0.55))
	# Regular classical arcade bays along the Piazza front
	var bays := 26 if vecchie else 28
	var pitch := length / float(bays)
	for i in bays + 1:
		var x := x_off - length * 0.5 + pitch * float(i)
		# Ground-floor stout arcade pier
		lm.box("Trim", Vector3(x, 3.1, fz - face_dir * 0.2), Vector3(0.85, 6.2, 1.1))
		# Upper pilasters
		lm.box("Trim", Vector3(x, 12.8, fz + face_dir * 0.10), Vector3(0.55, eave - 6.5, 0.32))
	for i in bays:
		var xm := x_off - length * 0.5 + pitch * (float(i) + 0.5)
		# Ground archway shadow + warm arcade lamp every 3rd bay
		lm.box("Glass", Vector3(xm, 2.6, fz - face_dir * 2.5), Vector3(pitch * 0.72, 4.6, 0.12))
		if i % 3 == 1:
			lm.box("Lamp", Vector3(xm, 5.2, fz - face_dir * 1.1), Vector3(0.38, 0.46, 0.38))
		# Two upper tiers of arched or pedimented classical windows
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(xm, 9.4, fz + face_dir * 0.04), out, 1.7, 3.8, true, 0.16)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(xm, 15.6, fz + face_dir * 0.04), out, 1.5, 3.2, not vecchie, 0.16)
		if vecchie:
			# Scalloped Venetian merlon parapet along Procuratie Vecchie roofline
			lm.spire("Trim", Vector3(xm, eave, fz), 0.55, 1.4, 0.0, 4)
		elif i % 2 == 0:
			# Classical pedimented gables on Procuratie Nuove piano nobile
			lm.gable("Trim", Vector3(xm, 11.4, fz + face_dir * 0.14), 2.2, 0.35, 0.65, Basis(), 0.0, "Trim")

static func _wing_west(lm: LandmarkMesh, xc: float, depth: float, span: float, eave: float) -> void:
	var fx := xc + depth * 0.5
	var out := Vector3(1.0, 0.0, 0.0)
	lm.box("Stone", Vector3(xc - 1.4, 3.1, 0.0), Vector3(depth - 2.8, 6.2, span))
	lm.box("Stone", Vector3(xc, 6.2 + (eave - 6.2) * 0.5, 0.0), Vector3(depth, eave - 6.2, span))
	lm.gable("Roof", Vector3(xc, eave, 0.0), depth + 0.5, span + 0.5, 2.0, Basis(), 0.25, "Stone")
	# Monumental central Napoleonic attic rising to 21.8 m with classical emperors' statues
	lm.box("Trim", Vector3(fx - 1.0, eave + 1.1, 0.0), Vector3(2.4, 2.2, 34.0))
	for i in 15:
		var z := -span * 0.5 + span * (float(i) + 0.5) / 15.0
		lm.box("Trim", Vector3(fx - 0.2, 3.1, z - span / 30.0), Vector3(1.1, 6.2, 0.85))
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(fx + 0.05, 9.6, z), out, 1.8, 4.0, true, 0.16)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(fx + 0.05, 15.6, z), out, 1.6, 3.4, false, 0.16)
		if i % 3 == 1:
			lm.box("Lamp", Vector3(fx - 1.1, 5.2, z), Vector3(0.38, 0.46, 0.38))
	for k in 7:
		var sz := -14.0 + 4.65 * float(k)
		LandmarkKits.statue_figure(lm, "Trim", Vector3(fx + 0.1, eave + 2.2, sz), 1.8)
