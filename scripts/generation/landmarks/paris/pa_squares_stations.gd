class_name LandmarkPaSquaresStations
extends RefCounted

## Iconic Parisian monumental columns & grand Beaux-Arts railway terminals (`PA-4`):
## - Place Vendôme & Colonne Vendôme (44.3 m bronze spiral column crowned by Napoleon)
## - Place de la Bastille (50.5 m Colonne de Juillet with gilded Génie de la Liberté + Opéra Bastille)
## - Gare de Lyon (67 m Beaux-Arts Tour de l'Horloge clock tower & terminal facade)
## - Gare de l'Est (38 m Beaux-Arts grand arched rose-window train-shed facade)

## Colonne Vendôme (44.3 m; way 227762241):
## Green-patinated bronze spiral relief column cast from Austerlitz cannon on a stepped marble
## plinth, topped by viewing gallery and bronze statue of Napoleon Bonaparte.
static func place_vendome(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkPaKit.ashlar("#A8A296", 2.4))
	lm.use("Bronze", LandmarkPaKit.verdigris("#486B5D"))
	lm.use("DarkBronze", LandmarkPaKit.bronze("#323B35"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Stepped octagonal plaza base & bronze-clad pedestal (0..8.6 m)
	lm.frustum("Granite", Vector3(0.0, 0.0, 0.0), 7.8, 7.2, 0.9, 8)
	lm.box("DarkBronze", Vector3(0.0, 4.7, 0.0), Vector3(5.2, 7.6, 5.2))
	lm.box("Bronze", Vector3(0.0, 8.6, 0.0), Vector3(5.8, 0.8, 5.8))
	# 30 m spiral bronze column shaft (8.8..38.2 m) with spiral frieze rings
	lm.frustum("Bronze", Vector3(0.0, 8.8, 0.0), 1.95, 1.65, 29.4, 20)
	for k in 22:
		var y := 9.8 + float(k) * 1.25
		var r := lerpf(1.98, 1.70, float(k) / 21.0)
		lm.frustum("DarkBronze", Vector3(0.0, y, 0.0), r, r, 0.22, 20)
	# Capital, square viewing gallery, lantern dome & Napoleon statue reaching 44.3 m
	lm.box("DarkBronze", Vector3(0.0, 38.8, 0.0), Vector3(4.8, 1.2, 4.8))
	lm.frustum("Bronze", Vector3(0.0, 39.4, 0.0), 1.4, 0.8, 1.5, 12)
	lm.frustum("DarkBronze", Vector3(0.0, 40.9, 0.0), 0.52, 0.36, 3.4, 10)
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		LandmarkPaKit.paris_lamp(lm, "DarkBronze", "Lamp", Vector3(cos(a) * 11.0, 0.0, sin(a) * 11.0), 4.4)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(12.0, 1.5, 12.0), Vector3(0.0, 26.0, 0.0), 48.0, 1.1, 58.0],
		[Vector3(-12.0, 1.5, -12.0), Vector3(0.0, 26.0, 0.0), 48.0, 1.1, 58.0],
	])

## Place de la Bastille: Colonne de Juillet (50.5 m) & Opéra Bastille companion facade:
static func bastille_ensemble(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#D8CCB2", 3.2))
	lm.use("Bronze", LandmarkPaKit.verdigris("#4A7364"))
	lm.use("DarkBronze", LandmarkPaKit.bronze("#353F38"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#486274"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Circular stepped marble podium + square sculpted pedestal (0..13.0 m)
	lm.frustum("Stone", Vector3(0.0, 0.0, 0.0), 11.0, 9.8, 3.2, 24)
	lm.box("Stone", Vector3(0.0, 6.4, 0.0), Vector3(7.6, 6.4, 7.6))
	lm.box("DarkBronze", Vector3(0.0, 11.2, 0.0), Vector3(6.2, 3.4, 6.2))
	# Fluted Corinthian bronze column shaft (12.9..41.5 m) with gilt battle rings
	lm.frustum("Bronze", Vector3(0.0, 12.9, 0.0), 1.9, 1.65, 28.6, 20)
	for ry in [18.5, 25.0, 31.5, 38.0]:
		lm.frustum("Gilt", Vector3(0.0, float(ry), 0.0), 1.88, 1.88, 0.45, 20)
	# Ornate bronze capital, square balcony & gleaming gilded winged Génie de la Liberté (50.5 m!)
	lm.box("Bronze", Vector3(0.0, 42.4, 0.0), Vector3(5.2, 1.8, 5.2))
	lm.frustum("Gilt", Vector3(0.0, 43.3, 0.0), 1.3, 0.9, 2.2, 12)
	# Winged Spirit of Liberty poised on one foot holding aloft a torch
	lm.frustum("Gilt", Vector3(0.0, 45.5, 0.0), 0.48, 0.34, 3.8, 8)
	lm.beam("Gilt", Vector3(0.0, 48.0, 0.0), Vector3(0.6, 50.5, 0.3), 0.24, 0.24)
	for sx in [-1.0, 1.0]:
		lm.beam("Gilt", Vector3(0.0, 47.6, 0.0), Vector3(float(sx) * 2.4, 49.6, -0.8), 0.55, 0.16)
	# Sweeping curved granite & glass facade of Carlos Ott's Opéra Bastille framing the SE edge (+X/+Z)
	lm.box("Stone", Vector3(72.0, 16.0, 34.0), Vector3(24.0, 32.0, 74.0))
	lm.box("Glass", Vector3(59.8, 16.0, 34.0), Vector3(1.2, 26.0, 66.0))
	lm.box("Stone", Vector3(56.0, 29.0, 34.0), Vector3(10.0, 4.0, 56.0))
	for k in 6:
		var a := TAU * float(k) / 6.0
		LandmarkPaKit.paris_lamp(lm, "DarkBronze", "Lamp", Vector3(cos(a) * 14.5, 0.0, sin(a) * 14.5), 4.4)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(14.0, 2.0, 14.0), Vector3(0.0, 32.0, 0.0), 52.0, 1.15, 68.0],
		[Vector3(-14.0, 2.0, -14.0), Vector3(0.0, 32.0, 0.0), 52.0, 1.15, 68.0],
	])

## Paris-Gare-de-Lyon (Marius Toudoire, 1900; 67 m Tour de l'Horloge; 112 x 68 m):
static func gare_de_lyon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#465058", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#486274"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF2C8", 1.85))
	# Ornate Beaux-Arts station facade facing Place Louis-Armand (-Z) & grand arched train shed behind (+Z)
	lm.box("Ashlar", Vector3(0.0, 2.5, -18.0), Vector3(108.0, 5.0, 28.0))
	lm.box("Stone", Vector3(0.0, 13.0, -18.0), Vector3(104.0, 16.5, 24.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 21.2, -18.0), 102.0, 23.0, 6.2, 12)
	LandmarkPaKit.win_grid_z(lm, "Glass", -46.0, 46.0, -30.15, [8.5, 15.5], 11, 3.2, 4.8)
	# Twin iron-and-glass arched train sheds behind the headhouse
	for sx in [-1.0, 1.0]:
		lm.box("Glass", Vector3(float(sx) * 24.0, 12.0, 14.0), Vector3(42.0, 18.0, 44.0))
		lm.gable("Slate", Vector3(float(sx) * 24.0, 21.0, 14.0), 42.0, 44.0, 6.5, Basis(), 0.5, "Stone")
	# Iconic 67 m Tour de l'Horloge square belfry on the east corner (x = +46 m, z = -24 m)
	var tc := Vector3(46.0, 0.0, -24.0)
	lm.box("Stone", tc + Vector3(0.0, 25.0, 0.0), Vector3(12.0, 50.0, 12.0))
	lm.box("Ashlar", tc + Vector3(0.0, 49.5, 0.0), Vector3(13.2, 1.6, 13.2))
	# Four giant 6.5 m backlit white clock dials facing all four cardinal directions!
	for i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(i))
		var n := rot * Vector3(0.0, 0.0, 1.0)
		lm.box("Gilt", tc + Vector3(0.0, 41.5, 0.0) + n * 6.08, Vector3(6.8, 6.8, 0.35), rot)
		lm.disc("ClockLamp", tc + Vector3(0.0, 41.5, 0.0) + n * 6.28, n, 3.0, 18)
	# Domed copper/slate belfry pavilion & gilded finial reaching 67.0 m
	lm.box("Stone", tc + Vector3(0.0, 53.5, 0.0), Vector3(9.4, 7.0, 9.4))
	lm.lathe("Slate", tc + Vector3(0.0, 57.0, 0.0), LandmarkWestKit.dome_prof(5.2, 7.2, 8, 1.15), 16)
	lm.frustum("Gilt", tc + Vector3(0.0, 64.0, 0.0), 0.7, 0.1, 3.0, 8)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(46.0, 4.0, -44.0), Vector3(46.0, 42.0, -24.0), 54.0, 1.15, 78.0],
		[Vector3(-12.0, 2.0, -46.0), Vector3(-12.0, 16.0, -30.0), 66.0, 0.95, 65.0],
	])

## Paris-Gare-de-l'Est (François Duquesney, 1849; 38 m; 156 x 64 m):
static func gare_de_lest(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD0B4", 3.5))
	lm.use("Slate", LandmarkPaKit.slate("#465058", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#5A7484"))
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF2C8", 1.65))
	# Wide symmetric Beaux-Arts headhouse with twin iconic arched glass-gable rose windows (east & west halls)
	lm.box("Stone", Vector3(0.0, 11.0, -14.0), Vector3(154.0, 22.0, 26.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 22.0, -14.0), 152.0, 25.0, 5.2, 16)
	for sx in [-1.0, 1.0]:
		var hx := float(sx) * 38.0
		lm.box("Stone", Vector3(hx, 16.0, -22.0), Vector3(34.0, 30.0, 12.0))
		lm.gable("Stone", Vector3(hx, 30.5, -22.0), 34.0, 12.0, 7.5, Basis(), 0.5, "Stone")
		lm.disc("Glass", Vector3(hx, 20.0, -28.15), Vector3(0.0, 0.0, -1.0), 9.5, 20)
		lm.disc("ClockLamp", Vector3(hx, 32.5, -28.2), Vector3(0.0, 0.0, -1.0), 2.1, 14)
		# Glazed train shed extending behind (+Z)
		lm.box("Glass", Vector3(hx, 13.0, 14.0), Vector3(34.0, 20.0, 40.0))
		lm.gable("Slate", Vector3(hx, 23.0, 14.0), 34.0, 40.0, 7.0, Basis(), 0.5, "Stone")
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-38.0, 2.0, -44.0), Vector3(-38.0, 20.0, -28.0), 62.0, 1.0, 62.0],
		[Vector3(38.0, 2.0, -44.0), Vector3(38.0, 20.0, -28.0), 62.0, 1.0, 62.0],
	])
