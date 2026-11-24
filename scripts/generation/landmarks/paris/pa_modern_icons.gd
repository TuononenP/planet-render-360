class_name LandmarkPaModernIcons
extends RefCounted

## Modern Parisian architectural icons (`PA-4`):
## - Grande Arche de la Défense (Johann Otto von Spreckelsen, 1989; 110.9 m hollow marble hypercube)
## - Fondation Louis Vuitton (Frank Gehry, 2014; 46 m twelve curving translucent glass sails)
## - Bibliothèque François-Mitterrand / BnF (Dominique Perrault, 1995; four 79 m L-shaped open-book towers)

## Grande Arche de la Défense (110.9 m; 108 x 112 m):
## Iconic hollow white Carrara-marble & dark-glass open hypercube closing the Axe Historique
## 5.1 km NW of Trocadéro, complete with chamfered inner portal, sweeping white marble grand stairs,
## tensioned PTFE "Nuage" (Cloud) canopy, and panoramic external glass elevator shafts.
static func grande_arche(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#ECEAE2", 3.5))
	lm.use("Glass", LandmarkMaterials.glass("#3B4D5C"))
	lm.use("Frame", LandmarkMaterials.paint("#C6CCD2", 0.35, 0.7))
	lm.use("Cloud", LandmarkMaterials.paint("#F0EFEA", 0.48, 0.08))
	lm.use("Deck", LandmarkMaterials.pbr("pavement", "#C9C5BC", 4.0))
	lm.use("ArchLamp", LandmarkMaterials.lit("#FFF2D8", 1.5))
	# Grand sweeping Carrara-marble entrance steps & podium terrace (y = 0..7 m)
	for k in 8:
		var t := float(k) / 7.0
		lm.box("Marble", Vector3(0.0, 0.45 * float(k + 1), 62.0 - t * 14.0), Vector3(70.0, 0.9, 2.2))
	lm.box("Deck", Vector3(0.0, 3.5, 0.0), Vector3(110.0, 7.0, 112.0))
	# Two massive 104 m vertical legs (x = +/-43 m, each 20 m thick x 110 m deep) — leaving 70 m open void!
	for sx in [-1.0, 1.0]:
		var lx := float(sx) * 44.0
		lm.box("Marble", Vector3(lx, 59.0, 0.0), Vector3(20.0, 103.8, 110.0))
		# Recessed dark-glass 35-storey office grids on outer faces (+/-X)
		lm.box("Glass", Vector3(lx + float(sx) * 10.12, 59.0, 0.0), Vector3(0.24, 88.0, 92.0))
		# Crisp white marble grid frames across outer glass curtain wall
		for j in 6:
			var gz := lerpf(-42.0, 42.0, float(j) / 5.0)
			lm.box("Marble", Vector3(lx + float(sx) * 10.22, 59.0, gz), Vector3(0.4, 90.0, 1.8))
		for j in 6:
			var gy := lerpf(16.0, 100.0, float(j) / 5.0)
			lm.box("Marble", Vector3(lx + float(sx) * 10.22, gy, 0.0), Vector3(0.4, 1.8, 94.0))
		# Chamfered beveled inner marble portal walls on both +Z and -Z faces
		for sz in [-1.0, 1.0]:
			lm.beam("Marble", Vector3(lx - float(sx) * 10.0, 7.0, float(sz) * 55.0),
				Vector3(lx - float(sx) * 10.0, 99.0, float(sz) * 55.0), 4.0, 4.0)
	# Massive horizontal roof plateau (y = 97.5..110.9 m, 108 x 110 m) bridging the two legs
	lm.box("Marble", Vector3(0.0, 104.2, 0.0), Vector3(108.0, 13.4, 110.0))
	# Iconic tensioned white PTFE "Nuage" (Cloud) canopy suspended above the open parvis
	lm.box("Cloud", Vector3(0.0, 16.5, 10.0), Vector3(52.0, 0.8, 42.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Frame", Vector3(float(sx) * 24.0, 16.8, 10.0 + float(sz) * 19.0),
				Vector3(float(sx) * 34.0, 42.0, 10.0 + float(sz) * 24.0), 0.25, 0.25)
	# Panoramic external glass elevator tower rising through the open void on the north-west inner side
	lm.box("Frame", Vector3(-16.0, 52.0, -28.0), Vector3(5.5, 90.0, 5.5))
	lm.box("Glass", Vector3(-16.0, 52.0, -28.0), Vector3(4.8, 88.0, 4.8))
	# Glowing white inner soffit light strip & red aviation beacons on the roof corners
	lm.box("ArchLamp", Vector3(0.0, 97.3, 0.0), Vector3(64.0, 0.5, 96.0))
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(-52.0, 111.5, -52.0), 2.5, Color(1.0, 0.12, 0.05)],
		[Vector3(52.0, 111.5, 52.0), 2.5, Color(1.0, 0.12, 0.05)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 8.0, 76.0), Vector3(0.0, 62.0, 45.0), 72.0, 1.1, 120.0],
		[Vector3(0.0, 8.0, -76.0), Vector3(0.0, 62.0, -45.0), 72.0, 1.1, 120.0],
	])

## Fondation Louis Vuitton (Frank Gehry, 2014; 46 m; 138 x 64 m):
## Sculptural white Ductal-concrete "iceberg" galleries wrapped in 12 billowing translucent glass sails
## rising above a stepped cascading water basin in the Bois de Boulogne.
static func fondation_louis_vuitton(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#ECEAE4", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#A6C2CE"))
	lm.use("Steel", LandmarkMaterials.paint("#C8CDD2", 0.32, 0.78))
	lm.use("Water", LandmarkMaterials.pool_water())
	lm.use("SailLamp", LandmarkMaterials.lit("#FFF2D4", 1.35))
	# Cascading reflecting water pool at base
	lm.box("White", Vector3(0.0, 0.5, 16.0), Vector3(132.0, 1.0, 26.0))
	lm.box("Water", Vector3(0.0, 1.05, 16.0), Vector3(126.0, 0.16, 22.0))
	# Clustered white "iceberg" gallery blocks
	lm.box("White", Vector3(-34.0, 12.0, -4.0), Vector3(34.0, 24.0, 28.0))
	lm.box("White", Vector3(2.0, 16.0, -6.0), Vector3(38.0, 32.0, 30.0))
	lm.box("White", Vector3(38.0, 13.0, -2.0), Vector3(32.0, 26.0, 26.0))
	# Twelve billowing tilted & curved glass sails soaring to 46.0 m
	var sails := [
		[-50.0, 14.0, 4.0, 26.0, 24.0, 0.28, -0.20],
		[-30.0, 20.0, 10.0, 30.0, 30.0, 0.22, -0.14],
		[-12.0, 23.0, 12.0, 34.0, 36.0, 0.18, -0.06],
		[8.0, 25.4, 10.0, 36.0, 40.0, 0.16, 0.08],
		[28.0, 22.0, 8.0, 30.0, 32.0, 0.24, 0.18],
		[48.0, 16.0, 4.0, 26.0, 24.0, 0.30, 0.24],
		[-36.0, 19.0, -18.0, 30.0, 28.0, -0.22, 0.12],
		[-4.0, 24.4, -20.0, 36.0, 38.0, -0.18, -0.08],
		[30.0, 21.0, -18.0, 32.0, 30.0, -0.24, -0.16],
	]
	for sl in sails:
		var rot := Basis(Vector3.UP, float(sl[6])) * Basis(Vector3.RIGHT, float(sl[5]))
		var pos := Vector3(float(sl[0]), float(sl[1]), float(sl[2]))
		lm.box("Glass", pos, Vector3(float(sl[3]), float(sl[4]), 0.45), rot)
		# Curved structural steel mullions framing each sail
		lm.box("Steel", pos + rot * Vector3(0.0, float(sl[4]) * 0.48, 0.0), Vector3(float(sl[3]), 0.55, 0.7), rot)
		lm.box("Steel", pos + rot * Vector3(-float(sl[3]) * 0.48, 0.0, 0.0), Vector3(0.55, float(sl[4]), 0.7), rot)
		lm.box("Steel", pos + rot * Vector3(float(sl[3]) * 0.48, 0.0, 0.0), Vector3(0.55, float(sl[4]), 0.7), rot)
	# Warm interior gallery lights glowing behind the sails
	lm.box("SailLamp", Vector3(2.0, 26.0, 0.0), Vector3(68.0, 1.2, 16.0))
	lm.commit(model)
	var fk := FountainKit.new()
	fk.cascade_sheet(Vector3(-42.0, 0.0, 5.2), Vector3(42.0, 0.0, 5.2), 2.05, 1.13, Vector3(0.0, 0.0, 1.0), 0.35, 0.65)
	fk.splash_strip(Vector3(-42.0, 1.13, 5.5), Vector3(42.0, 1.13, 5.5), Vector3(0.0, 0.0, 1.0), 1.4, 0.72)
	fk.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 42.0), Vector3(0.0, 24.0, 0.0), 72.0, 1.05, 85.0],
	])

## Bibliothèque nationale de France – Site François-Mitterrand (Dominique Perrault, 1995; 79 m):
## Iconic elevated timber esplanade (280 x 170 m) around a sunken forest courtyard, crowned at its
## four corners by four 79 m L-shaped "open-book" glass towers lined with warm timber shutters.
static func bnf_mitterrand(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#8E6946", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#5A7686"))
	lm.use("Steel", LandmarkMaterials.paint("#5C6268", 0.45, 0.65))
	lm.use("Forest", LandmarkMaterials.paint("#3A5F36", 0.85, 0.05))
	lm.use("TowerLamp", LandmarkMaterials.lit("#FFE2A4", 1.3))
	# Elevated timber podium esplanade framing the sunken pine forest courtyard
	for sz in [-1.0, 1.0]:
		lm.box("Timber", Vector3(0.0, 4.5, float(sz) * 64.0), Vector3(244.0, 9.0, 32.0))
	for sx in [-1.0, 1.0]:
		lm.box("Timber", Vector3(float(sx) * 102.0, 4.5, 0.0), Vector3(40.0, 9.0, 98.0))
	lm.box("Forest", Vector3(0.0, 2.0, 0.0), Vector3(160.0, 4.0, 92.0))
	# Four 79 m L-shaped "open-book" glass & timber-shutter corner towers
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx := float(sx) * 92.0
			var cz := float(sz) * 56.0
			# Two perpendicular book-cover wings forming each "L" facing inward toward the courtyard
			lm.box("Glass", Vector3(cx - float(sx) * 10.0, 44.0, cz), Vector3(36.0, 70.0, 12.0))
			lm.box("Timber", Vector3(cx - float(sx) * 10.0, 44.0, cz), Vector3(32.0, 68.0, 9.2))
			lm.box("Glass", Vector3(cx, 44.0, cz - float(sz) * 10.0), Vector3(12.0, 70.0, 36.0))
			lm.box("Timber", Vector3(cx, 44.0, cz - float(sz) * 10.0), Vector3(9.2, 68.0, 32.0))
			lm.box("Steel", Vector3(cx - float(sx) * 10.0, 78.6, cz), Vector3(36.4, 0.8, 12.4))
			lm.box("Steel", Vector3(cx, 78.6, cz - float(sz) * 10.0), Vector3(12.4, 0.8, 36.4))
			lm.box("TowerLamp", Vector3(cx - float(sx) * 10.0, 77.6, cz), Vector3(30.0, 0.8, 12.6))
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(-92.0, 79.5, -56.0), 1.8, Color(1.0, 0.14, 0.05)],
		[Vector3(92.0, 79.5, 56.0), 1.8, Color(1.0, 0.14, 0.05)],
	])
