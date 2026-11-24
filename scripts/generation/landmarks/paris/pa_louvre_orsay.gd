class_name LandmarkPaLouvreOrsay
extends RefCounted

## Palais du Louvre & Musée d'Orsay (`PA-4`):
## - Palais du Louvre (36 m): complete Richelieu, Denon & Sully wings framing Cour Napoléon
##   (leaving the 106 x 106 m central court open for `louvre_pyramid`!), Cour Carrée & Perrault's
##   Colonnade, Pavillon de l'Horloge, Pavillon de Flore, Pavillon de Marsan, and Arc du Carrousel.
## - Musée d'Orsay (32 m): Victor Laloux's Beaux-Arts riverfront with giant backlit gilded clocks
##   and arched iron-and-glass barrel-vault nave.

static func palais_du_louvre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD0B4", 3.6))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B699", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#424B54", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkPaKit.verdigris("#4D7466"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Model origin = Cour Napoléon centre (same lat/lon/yaw as louvre_pyramid; +X east toward Cour Carrée, -X west toward Carrousel).
	# North (Richelieu) & South (Denon) long wings flanking Cour Napoléon & Jardin du Carrousel (keep |z| > 55 m!)
	for sz in [-1.0, 1.0]:
		var wz := float(sz) * 74.0
		# Main wing along X from -210..+96 (306 m long, 26 m deep)
		lm.box("Ashlar", Vector3(-56.0, 2.2, wz), Vector3(310.0, 4.4, 28.0))
		lm.box("Stone", Vector3(-56.0, 12.2, wz), Vector3(306.0, 16.0, 26.0))
		LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(-56.0, 20.2, wz), 305.0, 25.5, 5.6, 26)
		LandmarkPaKit.win_grid_z(lm, "Glass", -200.0, 88.0, wz - float(sz) * 13.1, [7.5, 13.5, 18.0], 28, 1.8, 3.0)
		LandmarkPaKit.win_grid_z(lm, "Glass", -200.0, 88.0, wz + float(sz) * 13.1, [7.5, 13.5, 18.0], 28, 1.8, 3.0)
		# Projecting grand mansard pavilions (Pavillon Richelieu / Denon at x=0, Mollien/Turgot at x=-85, Flore/Marsan at x=-205)
		for px in [-205.0, -88.0, 0.0, 86.0]:
			lm.box("Stone", Vector3(float(px), 12.5, wz), Vector3(26.0, 23.0, 32.0))
			LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt",
				Vector3(float(px), 24.0, wz), 25.0, 30.0, 9.5)
	# Sully Wing (East side of Cour Napoléon, x = +76 m) with iconic Pavillon de l'Horloge (36.0 m!)
	lm.box("Stone", Vector3(76.0, 11.5, 0.0), Vector3(22.0, 21.0, 126.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(76.0, 22.0, 0.0), 21.5, 124.0, 5.4, 0, 12)
	lm.box("Stone", Vector3(76.0, 12.5, 0.0), Vector3(28.0, 24.0, 26.0))
	LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt", Vector3(76.0, 24.5, 0.0), 25.0, 24.0, 10.6)
	lm.box("Gilt", Vector3(76.0, 35.5, 0.0), Vector3(6.0, 1.0, 6.0))
	# Cour Carrée (East quadrangle x = +76..+210 m) & Claude Perrault's famous East Colonnade (x = +210 m)
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(144.0, 11.5, float(sz) * 66.0), Vector3(136.0, 21.0, 20.0))
		LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass",
			Vector3(144.0, 22.0, float(sz) * 66.0), 135.0, 19.5, 5.2, 12)
	lm.box("Stone", Vector3(204.0, 11.5, 0.0), Vector3(20.0, 22.0, 148.0))
	LandmarkPaKit.colonnade_z(lm, "Stone", 215.2, 4.5, -64.0, 64.0, 24, 15.5, 0.58)
	# Arc de Triomphe du Carrousel (x = -168 m, aligning the Axe Historique toward Tuileries & Concorde)
	var ax := -168.0
	lm.box("Stone", Vector3(ax, 7.2, 0.0), Vector3(7.0, 14.4, 19.6))
	lm.box("Ashlar", Vector3(ax, 15.6, 0.0), Vector3(7.4, 2.4, 20.0))
	# Gilded bronze Quadriga chariot crowning Arc du Carrousel
	LandmarkPaKit.equestrian(lm, "Gilt", Vector3(ax, 16.8, -1.6), 0.72, -PI * 0.5, false)
	LandmarkPaKit.equestrian(lm, "Gilt", Vector3(ax, 16.8, 1.6), 0.72, -PI * 0.5, false)
	for lx in [-52.0, 52.0]:
		for lz in [-54.0, 54.0]:
			LandmarkPaKit.paris_lamp(lm, "Slate", "Lamp", Vector3(float(lx), 0.0, float(lz)), 4.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(46.0, 2.0, 0.0), Vector3(76.0, 22.0, 0.0), 64.0, 1.1, 72.0],
		[Vector3(0.0, 2.0, -48.0), Vector3(0.0, 18.0, -72.0), 68.0, 0.95, 72.0],
		[Vector3(0.0, 2.0, 48.0), Vector3(0.0, 18.0, 72.0), 68.0, 0.95, 72.0],
		[Vector3(-152.0, 2.0, 0.0), Vector3(-168.0, 14.0, 0.0), 54.0, 0.95, 48.0],
	])

## Musée d'Orsay (Victor Laloux, 1900; 32 m; 178 x 74 m):
## Beaux-Arts limestone railway station overlooking the Seine: arched river facade,
## two giant backlit gilded clocks, bronze animal parvis statues, and glazed barrel-vault nave.
static func musee_dorsay(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Steel", LandmarkPaKit.zinc("#5A656E", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#6C8694"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkPaKit.bronze("#424A40"))
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF0C4", 1.8))
	# Monumental Beaux-Arts riverfront block along X (176 m long, 68 m deep; -Z faces the Seine)
	lm.box("Ashlar", Vector3(0.0, 2.2, 0.0), Vector3(176.0, 4.4, 68.0))
	lm.box("Stone", Vector3(0.0, 11.8, 0.0), Vector3(172.0, 16.0, 64.0))
	lm.box("Stone", Vector3(0.0, 20.5, 0.0), Vector3(174.0, 1.4, 66.0))
	# Arched riverfront bays along -Z
	LandmarkPaKit.win_grid_z(lm, "Glass", -78.0, 78.0, -32.15, [9.5, 16.0], 14, 4.4, 5.2)
	LandmarkPaKit.win_grid_z(lm, "Glass", -78.0, 78.0, 32.15, [9.5, 16.0], 14, 4.4, 5.2)
	# Twin iconic clock pavilions on the Seine facade with giant backlit gilded clocks!
	for sx in [-1.0, 1.0]:
		var cx := float(sx) * 56.0
		lm.box("Stone", Vector3(cx, 23.0, -28.0), Vector3(18.0, 8.0, 12.0))
		lm.box("Gilt", Vector3(cx, 23.2, -34.1), Vector3(6.6, 6.6, 0.4))
		lm.disc("ClockLamp", Vector3(cx, 23.2, -34.35), Vector3(0.0, 0.0, -1.0), 2.8, 18)
		# Corner Beaux-Arts bell-roof pavilions
		lm.box("Stone", Vector3(float(sx) * 80.0, 13.0, 0.0), Vector3(18.0, 22.0, 66.0))
		LandmarkPaKit.mansard(lm, "Steel", "Stone", "Glass",
			Vector3(float(sx) * 80.0, 24.0, 0.0), 17.6, 65.0, 5.8, 2, 5)
	# Iconic iron-and-glass barrel-vault train-shed nave rising to 32.0 m along X
	var segs := 12
	var grid: Array[PackedVector3Array] = []
	for ix in [-68.0, 68.0]:
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := PI * float(i) / float(segs)
			row.append(Vector3(float(ix), 20.5 + sin(a) * 11.5, -cos(a) * 20.0))
		grid.append(row)
	lm.grid("Glass", grid)
	for r in 11:
		var rx := lerpf(-68.0, 68.0, float(r) / 10.0)
		for i in segs:
			var a0 := PI * float(i) / float(segs)
			var a1 := PI * float(i + 1) / float(segs)
			lm.beam("Steel", Vector3(rx, 20.5 + sin(a0) * 11.5, -cos(a0) * 20.0),
				Vector3(rx, 20.5 + sin(a1) * 11.5, -cos(a1) * 20.0), 0.55, 0.55)
	# Bronze animal sculptures (horse, rhinoceros, elephant) on the Seine parvis
	for bx in [-42.0, -14.0, 14.0, 42.0]:
		lm.box("Ashlar", Vector3(float(bx), 0.9, -36.5), Vector3(2.8, 1.8, 2.2))
		lm.box("Bronze", Vector3(float(bx), 2.7, -36.5), Vector3(2.2, 1.8, 1.2))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-56.0, 2.0, -46.0), Vector3(-56.0, 18.0, -32.0), 62.0, 1.0, 62.0],
		[Vector3(0.0, 2.0, -48.0), Vector3(0.0, 18.0, -32.0), 66.0, 0.95, 65.0],
		[Vector3(56.0, 2.0, -46.0), Vector3(56.0, 18.0, -32.0), 62.0, 1.0, 62.0],
	])
