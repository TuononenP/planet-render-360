class_name LandmarkPaPompidouHdv
extends RefCounted

## Beaubourg, Hôtel de Ville & Île de la Cité riverfront (`PA-4`):
## - Centre Pompidou (Piano & Rogers, 1977; 42 m high-tech exoskeleton & coloured pipes)
## - Hôtel de Ville de Paris (Ballu & Deperthes, 1882; 50 m Neo-Renaissance belfry & slate pavilions)
## - Conciergerie & Palais de Justice (47 m medieval circular slate towers & Tour de l'Horloge)

## Centre Georges Pompidou (42 m; 166 x 60 m):
## White steel gerberette exoskeleton, cross-braced bays, iconic diagonal transparent escalator
## "caterpillar" across the west Piazza facade (-X), and primary colour-coded external service ducts
## (blue HVAC, green water, yellow electrical, red lifts/circulation) on the east Rue du Renard side.
static func centre_pompidou(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.paint("#E6E8EA", 0.38, 0.52))
	lm.use("Glass", LandmarkMaterials.glass("#6C8898"))
	lm.use("Blue", LandmarkMaterials.paint("#1D5CA8", 0.42, 0.35))
	lm.use("Red", LandmarkMaterials.paint("#C62828", 0.42, 0.35))
	lm.use("Yellow", LandmarkMaterials.paint("#E0A81E", 0.42, 0.35))
	lm.use("Green", LandmarkMaterials.paint("#2E8646", 0.42, 0.35))
	lm.use("TubeLamp", LandmarkMaterials.lit("#FFF2D4", 1.45))
	# Recessed glazed box core (44 x 160 x 38 m, long axis along Z)
	lm.box("Glass", Vector3(0.0, 19.0, 0.0), Vector3(44.0, 38.0, 156.0))
	# Six floor decks + roof deck
	for fl in 7:
		var y := float(fl) * 6.3 + 0.5
		lm.box("White", Vector3(0.0, y, 0.0), Vector3(50.0, 0.8, 160.0))
	# Iconic white external steel structural exoskeleton (13 bays along Z) on both west (-X) & east (+X) faces
	for sx in [-1.0, 1.0]:
		var ex := float(sx) * 25.5
		for i in 14:
			var z := lerpf(-78.0, 78.0, float(i) / 13.0)
			lm.frustum("White", Vector3(ex, 0.0, z), 0.55, 0.55, 39.5, 8)
			if i < 13:
				var z2 := lerpf(-78.0, 78.0, float(i + 1) / 13.0)
				# Diagonal cross-bracing tension rods every 2 storeys
				for fl in [0, 2, 4]:
					var y0 := float(fl) * 6.3 + 0.5
					var y1 := float(fl + 2) * 6.3 + 0.5
					lm.beam("White", Vector3(ex, y0, z), Vector3(ex, y1, z2), 0.28, 0.28)
					lm.beam("White", Vector3(ex, y1, z), Vector3(ex, y0, z2), 0.28, 0.28)
	# Signature diagonal glass & red-belly escalator "caterpillar" climbing the West Piazza face (-X)
	var esc_a := Vector3(-27.2, 2.5, 58.0)
	var esc_b := Vector3(-27.2, 34.5, -52.0)
	lm.beam("Glass", esc_a, esc_b, 4.4, 3.8)
	lm.beam("Red", esc_a + Vector3(0.0, -2.0, 0.0), esc_b + Vector3(0.0, -2.0, 0.0), 1.0, 3.6)
	lm.beam("TubeLamp", esc_a + Vector3(-0.3, 0.0, 0.0), esc_b + Vector3(-0.3, 0.0, 0.0), 0.55, 0.4)
	# Iconic primary-colour external mechanical ducts on East face (+X) & rooftop air-handling towers (to 42.0 m)
	for i in 6:
		var z := lerpf(-64.0, 64.0, float(i) / 5.0)
		lm.frustum("Blue", Vector3(27.2, 4.0, z), 1.4, 1.4, 36.0, 10)
		lm.frustum("Green", Vector3(27.0, 4.0, z + 4.0), 0.9, 0.9, 34.0, 8)
		lm.frustum("Yellow", Vector3(26.8, 4.0, z - 4.0), 0.65, 0.65, 33.0, 8)
	# Horizontal blue/yellow/red service manifolds along east wall
	lm.box("Blue", Vector3(27.4, 14.0, 0.0), Vector3(2.2, 2.4, 148.0))
	lm.box("Green", Vector3(27.2, 22.0, 0.0), Vector3(1.8, 1.8, 148.0))
	lm.box("Yellow", Vector3(27.0, 29.0, 0.0), Vector3(1.6, 1.4, 148.0))
	# Red vertical lift towers & rooftop blue/red sculptural HVAC chimneys reaching 42.0 m
	for rz in [-42.0, 0.0, 42.0]:
		lm.box("Red", Vector3(-26.5, 20.0, float(rz)), Vector3(3.4, 39.0, 6.2))
		lm.frustum("Blue", Vector3(10.0, 38.0, float(rz)), 2.2, 2.2, 4.0, 10)
		lm.frustum("White", Vector3(-8.0, 38.0, float(rz)), 1.6, 1.6, 4.0, 8)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.0, -34.0), Vector3(-25.0, 22.0, -34.0), 66.0, 1.0, 68.0],
		[Vector3(-42.0, 2.0, 34.0), Vector3(-25.0, 22.0, 34.0), 66.0, 1.0, 68.0],
		[Vector3(42.0, 2.0, 0.0), Vector3(26.0, 22.0, 0.0), 68.0, 0.95, 72.0],
	])

## Hôtel de Ville de Paris (50 m to central belfry finial; 118 x 82 m):
## Monumental Neo-Renaissance limestone palace with niche statues, steep blue-black Angers slate
## corner & central pavilions, dormer rows, and central ornate clock belfry.
static func hotel_de_ville_paris(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#3F4852", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF0C0", 1.65))
	# Quadrangle body (114 x 78 m) around interior courts
	lm.box("Ashlar", Vector3(0.0, 2.2, 0.0), Vector3(114.0, 4.4, 78.0))
	lm.box("Stone", Vector3(0.0, 12.2, 0.0), Vector3(110.0, 16.5, 74.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 20.5, 0.0), 108.0, 72.0, 7.2, 14, 8)
	# Four tall corner Neo-Renaissance pavilions with steep hipped slate roofs
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx := float(sx) * 48.0
			var cz := float(sz) * 32.0
			lm.box("Stone", Vector3(cx, 13.0, cz), Vector3(22.0, 24.0, 18.0))
			LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt", Vector3(cx, 25.0, cz), 21.5, 17.5, 10.5)
	# Central frontispiece pavilion & ornate 50 m clock belfry spire facing Place de l'Hôtel de Ville (-X)
	lm.box("Stone", Vector3(-48.0, 13.5, 0.0), Vector3(18.0, 25.0, 30.0))
	LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt", Vector3(-48.0, 26.0, 0.0), 17.0, 26.0, 11.0)
	lm.box("Stone", Vector3(-50.0, 38.5, 0.0), Vector3(7.0, 5.5, 7.0))
	lm.disc("ClockLamp", Vector3(-53.6, 38.2, 0.0), Vector3(-1.0, 0.0, 0.0), 1.9, 16)
	lm.frustum("Slate", Vector3(-50.0, 41.2, 0.0), 3.4, 0.2, 7.6, 8)
	lm.frustum("Gilt", Vector3(-50.0, 48.6, 0.0), 0.35, 0.06, 1.4, 8)
	# Dense Neo-Renaissance mullioned windows across all four faces
	LandmarkPaKit.win_grid_x(lm, "Glass", -55.15, -34.0, 34.0, [7.5, 13.2, 18.0], 12, 1.8, 3.0)
	LandmarkPaKit.win_grid_x(lm, "Glass", 55.15, -34.0, 34.0, [7.5, 13.2, 18.0], 12, 1.8, 3.0)
	LandmarkPaKit.win_grid_z(lm, "Glass", -48.0, 48.0, 37.15, [7.5, 13.2, 18.0], 16, 1.8, 3.0)
	LandmarkPaKit.win_grid_z(lm, "Glass", -48.0, 48.0, -37.15, [7.5, 13.2, 18.0], 16, 1.8, 3.0)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-72.0, 2.0, -24.0), Vector3(-55.0, 20.0, -24.0), 62.0, 1.0, 68.0],
		[Vector3(-74.0, 2.0, 0.0), Vector3(-52.0, 28.0, 0.0), 60.0, 1.15, 75.0],
		[Vector3(-72.0, 2.0, 24.0), Vector3(-55.0, 20.0, 24.0), 62.0, 1.0, 68.0],
	])

## Conciergerie & Palais de Justice riverfront (Quai de l'Horloge, Île de la Cité; 47 m):
## Iconic medieval royal palace overlooking the Seine: square Tour de l'Horloge with Paris's
## gilded blue-and-gold public clock, flanked by conical-slate-capped circular towers
## (Tour César, Tour d'Argent, Tour Bonbec) and Gothic gabled curtain walls.
static func conciergerie(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#CFC2A6", 3.2))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#B3A68C", 3.0))
	lm.use("Slate", LandmarkPaKit.slate("#3D4650", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFE4A0", 1.7))
	# Medieval fortified limestone curtain wall along Quai de l'Horloge (-Z faces north across the Seine)
	lm.box("Ashlar", Vector3(0.0, 3.0, 0.0), Vector3(132.0, 6.0, 32.0))
	lm.box("Stone", Vector3(0.0, 13.0, 0.0), Vector3(130.0, 16.0, 28.0))
	lm.gable("Slate", Vector3(0.0, 21.0, 0.0), 28.0, 128.0, 10.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	LandmarkPaKit.win_grid_z(lm, "Glass", -56.0, 56.0, -14.15, [10.0, 16.5], 14, 1.7, 3.6)
	# Three iconic circular medieval riverfront towers with tall pointed conical slate roofs:
	# Tour Bonbec (-44 m, crenellated), Tour d'Argent (-8 m), Tour César (+14 m)
	for td in [[-44.0, 6.2, 23.0, 12.5], [-8.0, 6.6, 25.0, 15.0], [14.0, 6.6, 25.0, 15.0]]:
		var tx := float(td[0])
		var tr := float(td[1])
		var th := float(td[2])
		var sh := float(td[3])
		lm.frustum("Stone", Vector3(tx, 0.0, -14.5), tr, tr * 0.96, th, 16)
		lm.frustum("Ashlar", Vector3(tx, th - 1.2, -14.5), tr + 0.5, tr + 0.5, 1.2, 16)
		lm.frustum("Slate", Vector3(tx, th, -14.5), tr + 0.4, 0.15, sh, 16)
		lm.frustum("Gilt", Vector3(tx, th + sh, -14.5), 0.3, 0.05, 1.6, 8)
	# Iconic square Tour de l'Horloge on the NE corner (x = +62 m, height 47.0 m) with gilded public clock!
	lm.box("Stone", Vector3(62.0, 18.0, -12.0), Vector3(11.5, 36.0, 11.5))
	lm.box("Ashlar", Vector3(62.0, 35.8, -12.0), Vector3(12.6, 1.4, 12.6))
	lm.frustum("Slate", Vector3(62.0, 36.5, -12.0), 6.8, 0.3, 9.0, 4, PI * 0.25)
	lm.frustum("Gilt", Vector3(62.0, 45.3, -12.0), 0.4, 0.08, 1.7, 8)
	# Paris's oldest public clock (1370) in ornate gold frame facing east (+X) & north (-Z)
	lm.box("Gilt", Vector3(67.85, 16.5, -12.0), Vector3(0.3, 4.8, 4.4))
	lm.disc("ClockLamp", Vector3(68.05, 16.5, -12.0), Vector3(1.0, 0.0, 0.0), 1.6, 16)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-44.0, 2.0, -32.0), Vector3(-44.0, 22.0, -14.0), 58.0, 0.95, 58.0],
		[Vector3(3.0, 2.0, -34.0), Vector3(3.0, 24.0, -14.0), 62.0, 1.05, 62.0],
		[Vector3(62.0, 2.0, -30.0), Vector3(62.0, 26.0, -12.0), 56.0, 1.05, 65.0],
	])
