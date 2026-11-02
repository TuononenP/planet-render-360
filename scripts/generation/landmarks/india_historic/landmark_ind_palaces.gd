class_name LandmarkIndPalaces
extends RefCounted

## Three Indian palaces in true metres: the Mysore Palace, the Victoria
## Memorial of Kolkata and the Amber Fort of Jaipur. Fronts face +Z
## (south) unless noted; the registry yaw turns each onto its bearing.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")

## Mysore Palace (44 m): the Indo-Saracenic palace of grey-green granite
## and cream plaster. The 110 m east facade (built here on +Z, origin at
## its centre, the building running back along -Z) has three storeys of
## arcades with balconies, the five-storey central tower under its gilt
## onion dome and kiosk, pink domed turrets and corner towers; behind it
## the courtyard with the octagonal Kalyana Mantapa under its glass dome
## and the side and rear ranges.
static func mysore_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E3D3B0", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("render", "#D58C7A", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8E80", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4A3F38", 2.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#3E5A6A"))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B5A58C", 4.0))
	lm.box("Pave", Vector3(0, 0.05, 15), Vector3(150.0, 0.1, 40.0))
	lm.box("Granite", Vector3(0, 0.75, -75), Vector3(114.0, 1.5, 154.0))
	# Front block, three storeys (21 m) over the 1.5 m plinth, and the rear range.
	lm.box("Cream", Vector3(0, 12.0, -22.5), Vector3(110.0, 21.0, 45.0))
	lm.box("Granite", Vector3(0, 22.7, -22.5), Vector3(111.0, 0.8, 46.0))
	lm.box("Pink", Vector3(0, 21.8, 0.3), Vector3(112.0, 0.9, 1.4))
	lm.box("Cream", Vector3(0, 10.5, -132.5), Vector3(110.0, 18.0, 35.0))
	lm.box("Granite", Vector3(0, 19.7, -132.5), Vector3(111.0, 0.8, 36.0))
	for sx in [-1.0, 1.0]:
		lm.box("Cream", Vector3(sx * 45.0, 9.5, -80.0), Vector3(20.0, 16.0, 70.0))
		lm.box("Granite", Vector3(sx * 45.0, 17.8, -80.0), Vector3(21.0, 0.8, 71.0))
		IU.arcade(lm, "Recess", Vector3(sx * 55.05, 1.5, -80.0), Basis(Vector3.UP, sx * PI * 0.5), 9, 7.5, 3.6, 6.0)
		IU.arcade(lm, "Recess", Vector3(sx * 55.05, 9.0, -80.0), Basis(Vector3.UP, sx * PI * 0.5), 9, 7.5, 3.4, 5.4)
	# Facade arcades: three floors of eleven arches, each upper floor on a balcony.
	for fl in 3:
		var y := 1.5 + 7.0 * float(fl)
		IU.arcade(lm, "Recess", Vector3(0, y, 0.05), Basis(), 11, 9.0, 5.2 - 0.4 * float(fl), 5.2)
		if fl > 0:
			for k in 11:
				lm.box("Pink", Vector3((float(k) - 5.0) * 9.0, y - 0.3, 0.6), Vector3(5.8, 0.5, 1.3))
	for sx in [-1.0, 1.0]:
		IU.arcade(lm, "Recess", Vector3(sx * 55.05, 1.5, -22.5), Basis(Vector3.UP, sx * PI * 0.5), 5, 8.5, 4.4, 5.2)
		IU.arcade(lm, "Recess", Vector3(sx * 55.05, 8.5, -22.5), Basis(Vector3.UP, sx * PI * 0.5), 5, 8.5, 4.4, 5.2)
		IU.arcade(lm, "Recess", Vector3(sx * 55.05, 15.5, -22.5), Basis(Vector3.UP, sx * PI * 0.5), 5, 8.5, 4.4, 5.2)
	# Central porch: the great arch flanked by two smaller arches each side.
	lm.box("Cream", Vector3(0, 12.0, 1.5), Vector3(40.0, 21.0, 3.0))
	lm.box("Pink", Vector3(0, 22.4, 1.5), Vector3(41.0, 0.8, 4.0))
	IU.arch_panel(lm, "Pink", Vector3(0, 1.5, 3.04), Basis(), 13.6, 17.5)
	IU.arch_panel(lm, "Recess", Vector3(0, 1.5, 3.08), Basis(), 12.0, 16.0)
	for sx in [-1.0, 1.0]:
		for k in 2:
			var ax: float = sx * (10.4 + 5.2 * float(k))
			IU.arch_panel(lm, "Pink", Vector3(ax, 1.5, 3.04), Basis(), 4.4, 10.0)
			IU.arch_panel(lm, "Recess", Vector3(ax, 1.5, 3.08), Basis(), 3.6, 9.2)
			IU.arch_panel(lm, "Recess", Vector3(ax, 13.5, 3.08), Basis(), 3.6, 7.0)
	# Central tower: two open arcaded storeys, drum, gilt dome and kiosk to 44 m.
	lm.box("Cream", Vector3(0, 29.0, -14.0), Vector3(17.0, 13.0, 17.0))
	lm.box("Granite", Vector3(0, 35.8, -14.0), Vector3(19.0, 0.8, 19.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		IU.arcade(lm, "Recess", b * Vector3(0, 23.5, 8.55) + Vector3(0, 0, -14.0), b, 3, 4.6, 3.4, 5.4)
		IU.arcade(lm, "Recess", b * Vector3(0, 30.0, 8.55) + Vector3(0, 0, -14.0), b, 3, 4.6, 3.4, 5.4)
	lm.frustum("Cream", Vector3(0, 36.2, -14.0), 6.0, 6.0, 1.3, 8)
	U.onion(lm, "Gilt", Vector3(0, 37.5, -14.0), 6.0, 4.2, 24)
	U.chhatri(lm, "Cream", "Gilt", Vector3(0, 41.7, -14.0), 2.6, 0.7, 1.1)
	# Pink domed turrets on the roof and the corner towers with onion domes.
	for sx in [-1.0, 1.0]:
		U.chhatri(lm, "Cream", "Pink", Vector3(sx * 24.0, 23.1, -8.0), 7.0, 3.0, 4.6)
		U.chhatri(lm, "Cream", "Pink", Vector3(sx * 34.0, 23.1, -8.0), 5.0, 2.6, 3.4)
		lm.box("Cream", Vector3(sx * 49.0, 27.0, -8.0), Vector3(11.0, 9.0, 11.0))
		lm.box("Granite", Vector3(sx * 49.0, 31.8, -8.0), Vector3(12.0, 0.8, 12.0))
		U.onion(lm, "Pink", Vector3(sx * 49.0, 32.2, -8.0), 4.8, 5.0, 20)
		U.finial(lm, "Gilt", Vector3(sx * 49.0, 36.6, -8.0), 2.4, 0.3)
	# Kalyana Mantapa in the courtyard: octagon under its glass dome.
	lm.frustum("Cream", Vector3(0, 1.5, -80.0), 15.0, 14.5, 13.0, 8)
	lm.frustum("Pink", Vector3(0, 14.5, -80.0), 15.8, 15.8, 0.8, 8)
	lm.lathe("Glass", Vector3(0, 15.3, -80.0), PackedVector2Array([Vector2(14.0, 0), Vector2(13.0, 3.0),
		Vector2(10.0, 5.6), Vector2(5.5, 7.4), Vector2(0.5, 8.0)]), 16)
	lm.commit(model)

## Victoria Memorial (56 m to the Angel of Victory): the 103 x 69 m
## white Makrana marble hall with two floors of arcades, four domed
## octagonal corner towers, the Doric-columned north portico with its
## pediment, the great central dome on its drum with four small corner
## domes and the bronze Angel of Victory on top. The north (front) side is
## built on -Z.
static func victoria_memorial_kolkata(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F2EFE7", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#5A5048", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4B3F2F", 2.0, 0.4, 0.6))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6F8F4D", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#BDB19A", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.box("Lawn", Vector3(0, -0.2, 0), Vector3(170.0, 0.4, 150.0))
	lm.box("Pave", Vector3(0, 0.05, -52), Vector3(14.0, 0.1, 40.0))
	lm.box("Water", Vector3(0, 0.06, 70), Vector3(60.0, 0.1, 18.0))
	lm.box("Marble", Vector3(0, 0.9, 0), Vector3(106.0, 1.8, 70.0))
	lm.box("Marble", Vector3(0, 0.4, 0), Vector3(110.0, 0.8, 74.0))
	# Main body: 92 x 58 m, two floors of round-headed arches, cornice.
	lm.box("Marble", Vector3(0, 11.0, 0), Vector3(92.0, 18.4, 58.0))
	lm.box("Marble", Vector3(0, 20.5, 0), Vector3(94.0, 1.4, 60.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var n := 9 if side % 2 == 0 else 5
		var hl := 29.05 if side % 2 == 0 else 46.05
		for y in [3.2, 11.4]:
			IU.arcade(lm, "Recess", b * Vector3(0, y, hl), b, n, 9.0 if side % 2 == 0 else 8.5,
				4.4, 6.6 if y < 5.0 else 6.0, false)
	# Corner octagons with domes.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 46.0, 1.8, sz * 29.0)
			lm.frustum("Marble", p, 7.2, 7.0, 22.0, 8)
			lm.frustum("Marble", p + Vector3(0, 21.0, 0), 8.0, 8.0, 1.2, 8)
			for k in 8:
				var a := TAU * (float(k) + 0.5) / 8.0
				lm.box("Recess", p + Vector3(cos(a), 0, sin(a)) * 6.62 + Vector3(0, 10.0, 0), Vector3(2.4, 6.0, 0.3),
					Basis(Vector3.UP, PI * 0.5 - a))
			U.dome(lm, "Marble", p + Vector3(0, 22.2, 0), 7.0, 6.5, 24, 6)
			U.finial(lm, "Marble", p + Vector3(0, 28.4, 0), 2.6, 0.3)
	# North portico (to -Z): Doric columns, entablature, pediment, steps.
	lm.box("Marble", Vector3(0, 2.4, -34.0), Vector3(30.0, 1.2, 12.0))
	IU.stairs(lm, "Marble", Vector3(0, 0, -40.0), Basis(Vector3.UP, PI), 24.0, 4, 0.7, 1.0)
	lm.box("Recess", Vector3(0, 9.0, -29.05), Vector3(9.0, 12.0, 0.3))
	for k in 6:
		lm.frustum("Marble", Vector3(-12.5 + 5.0 * float(k), 3.0, -38.0), 1.0, 0.85, 14.5, 12)
	lm.box("Marble", Vector3(0, 18.1, -34.0), Vector3(30.0, 1.6, 12.4))
	lm.gable("Marble", Vector3(0, 18.9, -34.0), 30.0, 12.0, 4.8, Basis(), 0.4, "Marble")
	# South and the lateral porticos: low pedimented bays.
	lm.box("Marble", Vector3(0, 8.0, 31.0), Vector3(24.0, 14.0, 4.0))
	lm.box("Marble", Vector3(0, 15.4, 31.0), Vector3(26.0, 1.0, 5.0))
	for sx in [-1.0, 1.0]:
		lm.box("Marble", Vector3(sx * 48.0, 8.0, 0), Vector3(4.0, 14.0, 20.0))
		lm.box("Marble", Vector3(sx * 48.0, 15.4, 0), Vector3(5.0, 1.0, 22.0))
	# Central hall, drum, great dome, corner domelets and the Angel of Victory.
	lm.box("Marble", Vector3(0, 26.0, 0), Vector3(40.0, 12.0, 40.0))
	lm.box("Marble", Vector3(0, 32.4, 0), Vector3(42.0, 1.2, 42.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		IU.arcade(lm, "Recess", b * Vector3(0, 21.5, 20.05), b, 5, 7.0, 4.0, 7.5, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.chhatri(lm, "Marble", "Marble", Vector3(sx * 17.5, 33.0, sz * 17.5), 6.0, 3.6, 4.2)
	LandmarkKits.dome_on_drum(lm, "Marble", "Marble", Vector3(0, 33.0, 0), 11.5, 7.0, 11.1, 0.0, 32)
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 51.1, 0), 4.9, true)
	lm.commit(model)

## Amber Fort (36 m above the lowest court): the hill fort-palace in four
## terraces climbing -Z from the Jaleb Chowk (y 0): the Singh Pol, the
## Diwan-i-Am hall court, the painted Ganesh Pol over the garden court
## with the Sheesh Mahal and Sukh Niwas, and the Zenana courtyard with
## the Man Singh palace and its kiosks. Walls and foundations run down to
## -14 m so the terraces stand on any slope; ridge walls with bastions
## climb either side.
static func amber_fort(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#C8A27C", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("stone", "#B5583C", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE6D4", 3.0))
	lm.use("Fresco", LandmarkMaterials.pbr("render", "#C79058", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4A3A30", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#7A8C52", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#BFAE90", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Terrace floors: z0, z1, floor height. The retaining walls reach -14 m.
	var floors := [[10.0, 70.0, 0.0], [-25.0, 10.0, 6.5], [-55.0, -25.0, 13.0], [-88.0, -55.0, 20.0]]
	for t in floors:
		var z0: float = t[0]
		var z1: float = t[1]
		var fy: float = t[2]
		lm.box("Sand", Vector3(0, (fy - 14.0) * 0.5, (z0 + z1) * 0.5), Vector3(70.0, fy + 14.0, z1 - z0))
		lm.box("Pave", Vector3(0, fy + 0.03, (z0 + z1) * 0.5), Vector3(66.0, 0.1, z1 - z0 - 4.0))
		for sx in [-1.0, 1.0]:
			IU.wall_run(lm, "Sand", Vector2(sx * 34.0, z0), Vector2(sx * 34.0, z1), fy - 14.0, fy + 6.0, 3.0)
			IU.merlons(lm, "Sand", Vector2(sx * 34.0, z0), Vector2(sx * 34.0, z1), fy + 6.0, 3.2, 1.6, 1.3, 1.0)
	# Front wall with the Suraj Pol gate, and bastions up the ridge walls.
	IU.gate(lm, "Sand", "Marble", Vector3(0, 0, 70.0), Basis(), 26.0, 12.0, 9.0, 7.0, 9.0, 3.0, 13.0, 3)
	for sx in [-1.0, 1.0]:
		IU.wall_run(lm, "Sand", Vector2(sx * 13.0, 70.0), Vector2(sx * 34.0, 70.0), -14.0, 7.0, 3.0)
		for z in [60.0, 25.0, -10.0, -40.0, -70.0]:
			var fy := 0.0 if z > 10.0 else (6.5 if z > -25.0 else (13.0 if z > -55.0 else 20.0))
			IU.bastion(lm, "Sand", "Marble", Vector3(sx * 35.0, fy - 8.0, z), 3.6, 13.5)
	# Singh Pol: the lion gate into the Diwan-i-Am court, with the stair of the ascent.
	IU.gate(lm, "Sand", "Marble", Vector3(0, 6.5, 4.0), Basis(), 30.0, 11.0, 8.0, 6.0, 8.0, 2.6, 12.0, 3)
	IU.stairs(lm, "Sand", Vector3(0, 0, 10.0), Basis(), 12.0, 7, 0.93, 1.0)
	# Diwan-i-Am: pillared red sandstone hall with a marble cornice (west side).
	lm.box("Red", Vector3(-20.0, 8.0, -21.0), Vector3(26.0, 3.0, 8.0))
	for k in 7:
		lm.box("Red", Vector3(-20.0 + (float(k) - 3.0) * 3.9, 11.4, -17.5), Vector3(1.0, 4.0, 1.0))
		lm.box("Red", Vector3(-20.0 + (float(k) - 3.0) * 3.9, 11.4, -24.5), Vector3(1.0, 4.0, 1.0))
	lm.box("Marble", Vector3(-20.0, 13.7, -21.0), Vector3(28.0, 0.8, 10.0))
	for k in 3:
		U.chhatri(lm, "Marble", "Marble", Vector3(-20.0 + (float(k) - 1.0) * 9.0, 14.1, -21.0), 4.0, 1.8, 2.2)
	# Ganesh Pol: three-storey painted gate with the kiosks on its crest.
	IU.stairs(lm, "Sand", Vector3(0, 6.5, -25.0), Basis(), 12.0, 7, 0.93, 1.0)
	U.arch_wall(lm, "Fresco", Vector3(0, 13.0, -30.0), Basis(), 26.0, 15.0, 7.0, 5.6, 8.0)
	lm.box("Marble", Vector3(0, 28.4, -30.0), Vector3(27.0, 0.8, 8.0))
	for k in 5:
		lm.box("Marble", Vector3(0, 16.0 + 3.4 * float(k % 2), -26.45), Vector3(1.2, 1.6, 0.3))
	for k in 3:
		U.chhatri(lm, "Marble", "Marble", Vector3((float(k) - 1.0) * 8.0, 28.8, -30.0), 3.8, 1.5, 2.0)
	# Garden court: charbagh lawn with the central pool, Sukh Niwas, Sheesh Mahal.
	lm.box("Lawn", Vector3(0, 13.1, -40.0), Vector3(40.0, 0.12, 24.0))
	lm.box("Water", Vector3(0, 13.2, -40.0), Vector3(8.0, 0.1, 14.0))
	lm.box("Marble", Vector3(-22.0, 18.0, -50.0), Vector3(22.0, 10.0, 10.0))
	lm.box("Marble", Vector3(-22.0, 23.3, -50.0), Vector3(23.0, 0.8, 11.0))
	U.chhatri(lm, "Marble", "Marble", Vector3(-22.0, 23.7, -50.0), 5.0, 2.2, 2.6)
	lm.box("Sand", Vector3(22.0, 18.0, -50.0), Vector3(22.0, 10.0, 10.0))
	lm.box("Marble", Vector3(22.0, 23.3, -50.0), Vector3(23.0, 0.8, 11.0))
	IU.arcade(lm, "Recess", Vector3(-22.0, 13.2, -44.9), Basis(), 4, 5.0, 3.4, 6.5)
	IU.arcade(lm, "Recess", Vector3(22.0, 13.2, -44.9), Basis(), 4, 5.0, 3.4, 6.5)
	# Zenana and the Man Singh palace: two storeys round a court, chhatris on the roof.
	lm.box("Sand", Vector3(0, 25.25, -80.0), Vector3(62.0, 10.5, 14.0))
	lm.box("Marble", Vector3(0, 30.9, -80.0), Vector3(63.0, 0.8, 15.0))
	IU.arcade(lm, "Recess", Vector3(0, 20.2, -72.95), Basis(), 8, 7.0, 3.6, 5.2)
	IU.arcade(lm, "Recess", Vector3(0, 26.0, -72.95), Basis(), 8, 7.0, 3.6, 4.4)
	for sx in [-1.0, 1.0]:
		lm.box("Sand", Vector3(sx * 28.0, 24.0, -65.0), Vector3(8.0, 8.0, 20.0))
	for k in 5:
		U.chhatri(lm, "Marble", "Marble", Vector3((float(k) - 2.0) * 13.0, 31.3, -80.0), 5.0, 1.9, 2.3)
	lm.box("Marble", Vector3(0, 23.5, -63.0), Vector3(12.0, 6.6, 12.0))
	U.chhatri(lm, "Marble", "Marble", Vector3(0, 26.8, -63.0), 11.0, 3.0, 3.6)
	lm.commit(model)
