class_name LandmarkPaPalacesLeftbank
extends RefCounted

## Historic palaces & royal squares of Central & Left Bank Paris (`PA-4`):
## - Palais du Luxembourg (Salomon de Brosse, 1625; 34 m rusticated French Senate palace & Medici dome)
## - Institut de France (Louis Le Vau, 1670; 40 m curved Baroque wings & ribbed cupola)
## - Palais-Royal & Colonnes de Buren (26 m classical arcaded court & striped marble columns)
## - Place des Vosges (Henri IV, 1612; 28 m Louis XIII brick-and-stone arcaded royal square)

## Palais du Luxembourg / French Senate (34 m; 104 x 86 m):
static func palais_luxembourg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD0B4", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B699", 3.0))
	lm.use("Slate", LandmarkPaKit.slate("#424B54", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Main garden front (+Z facing Jardin du Luxembourg Grand Bassin) & side courtyard wings
	lm.box("Ashlar", Vector3(0.0, 2.0, 12.0), Vector3(102.0, 4.0, 28.0))
	lm.box("Stone", Vector3(0.0, 11.0, 12.0), Vector3(98.0, 14.5, 24.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 18.2, 12.0), 96.0, 23.0, 5.4, 12)
	for sx in [-1.0, 1.0]:
		var wx := float(sx) * 44.0
		lm.box("Stone", Vector3(wx, 10.5, -18.0), Vector3(18.0, 18.5, 56.0))
		LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(wx, 19.7, -18.0), 17.6, 55.0, 5.4, 2, 6)
		# Corner rusticated Medici pavilions
		lm.box("Stone", Vector3(float(sx) * 46.0, 12.0, 18.0), Vector3(20.0, 21.0, 20.0))
		LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt", Vector3(float(sx) * 46.0, 22.5, 18.0), 19.5, 19.5, 7.6)
	# North Rue de Vaugirard entrance screen & central Medici ribbed pavilion dome (34.0 m!)
	lm.box("Stone", Vector3(0.0, 9.5, -42.0), Vector3(72.0, 16.0, 14.0))
	lm.box("Stone", Vector3(0.0, 12.0, -42.0), Vector3(18.0, 22.0, 18.0))
	lm.frustum("Stone", Vector3(0.0, 22.5, -42.0), 6.2, 6.0, 3.6, 16)
	lm.lathe("Slate", Vector3(0.0, 26.0, -42.0), LandmarkWestKit.dome_prof(6.2, 5.8, 10, 1.15), 16)
	lm.frustum("Gilt", Vector3(0.0, 31.6, -42.0), 1.2, 0.15, 2.4, 8)
	# Garden front central pedimented avant-corps
	lm.box("Stone", Vector3(0.0, 12.0, 18.0), Vector3(24.0, 22.0, 20.0))
	LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt", Vector3(0.0, 23.0, 18.0), 22.0, 18.0, 8.2)
	LandmarkPaKit.win_grid_z(lm, "Glass", -38.0, 38.0, 24.15, [7.5, 13.5], 12, 1.8, 3.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 42.0), Vector3(0.0, 18.0, 18.0), 68.0, 1.0, 68.0],
		[Vector3(0.0, 2.0, -60.0), Vector3(0.0, 22.0, -42.0), 62.0, 1.0, 62.0],
	])

## Institut de France (Louis Le Vau, 1670; 40 m; 108 x 54 m):
## Iconic curving Baroque limestone wings embracing a half-moon forecourt overlooking Pont des Arts,
## framing the Corinthian chapel portico and tall ribbed lead-and-gilt cupola.
static func institut_de_france(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD0B4", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#465058", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Central Baroque chapel body + tall drum & ribbed elliptical cupola (40.0 m!)
	lm.box("Stone", Vector3(0.0, 10.5, 6.0), Vector3(28.0, 21.0, 26.0))
	LandmarkPaKit.colonnade_x(lm, "Stone", -10.5, 10.5, 1.5, -8.2, 6, 14.5, 0.56)
	LandmarkPaKit.pediment_z(lm, "Stone", 0.0, 17.5, -8.4, 24.0, 4.8, 2.4)
	lm.frustum("Stone", Vector3(0.0, 20.5, 6.0), 9.6, 9.4, 6.5, 24)
	lm.lathe("Slate", Vector3(0.0, 27.0, 6.0), LandmarkWestKit.dome_prof(9.4, 9.5, 12, 1.25), 24)
	# Gilded cupola ribs & lantern finial
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0.0, sin(a))
		lm.beam("Gilt", Vector3(0.0, 27.2, 6.0) + d * 9.3, Vector3(0.0, 36.2, 6.0) + d * 1.4, 0.25, 0.25)
	lm.frustum("Stone", Vector3(0.0, 36.0, 6.0), 2.1, 1.9, 2.4, 12)
	lm.frustum("Gilt", Vector3(0.0, 38.4, 6.0), 0.9, 0.1, 1.6, 8)
	# Iconic symmetrical curving Baroque wings arcing forward (-Z toward Pont des Arts) to square end pavilions
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		for i in 5:
			var a := lerpf(0.25, 1.25, (float(i) + 0.5) / 5.0) * s
			var p := Vector3(sin(a) * 44.0, 9.0, 26.0 - cos(a) * 34.0)
			var rot := Basis(Vector3.UP, -a * 0.8)
			lm.box("Stone", p, Vector3(11.5, 18.0, 12.0), rot)
			lm.box("Slate", p + Vector3(0.0, 10.6, 0.0), Vector3(11.2, 3.2, 11.4), rot)
		# Square classical riverfront end pavilions framing Quai de Conti
		lm.box("Stone", Vector3(s * 44.0, 10.5, -6.0), Vector3(18.0, 21.0, 20.0))
		LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(s * 44.0, 21.0, -6.0), 17.6, 19.6, 5.2, 3)
		LandmarkPaKit.win_grid_z(lm, "Glass", s * 37.0, s * 51.0, -16.1, [6.5, 13.0], 3, 1.8, 3.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, -24.0), Vector3(0.0, 26.0, 4.0), 66.0, 1.15, 68.0],
		[Vector3(-44.0, 2.0, -26.0), Vector3(-44.0, 14.0, -6.0), 58.0, 0.85, 48.0],
		[Vector3(44.0, 2.0, -26.0), Vector3(44.0, 14.0, -6.0), 58.0, 0.85, 48.0],
	])

## Palais-Royal & Colonnes de Buren (26 m; 96 x 118 m):
static func palais_royal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.4))
	lm.use("Slate", LandmarkPaKit.slate("#465058", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("White", LandmarkMaterials.paint("#EAE8E2", 0.35, 0.1))
	lm.use("Black", LandmarkMaterials.paint("#232528", 0.35, 0.15))
	# Three classical arcaded wings around the Cour d'Honneur
	lm.box("Stone", Vector3(0.0, 10.0, 44.0), Vector3(94.0, 20.0, 18.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 20.0, 44.0), 93.0, 17.5, 6.0, 12)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * 40.0, 10.0, -4.0), Vector3(14.0, 20.0, 92.0))
		LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass",
			Vector3(float(sx) * 40.0, 20.0, -4.0), 13.5, 91.0, 5.2, 0, 12)
	# Galerie d'Orléans double colonnade screen separating Cour d'Honneur from the garden
	LandmarkPaKit.colonnade_x(lm, "Stone", -32.0, 32.0, 0.0, -34.0, 14, 7.2, 0.42)
	# Daniel Buren's iconic black-and-white striped octagonal marble columns ("Les Deux Plateaux")
	for ix in 7:
		for iz in 6:
			var cx := lerpf(-24.0, 24.0, float(ix) / 6.0)
			var cz := lerpf(-24.0, 24.0, float(iz) / 5.0)
			var ch := 0.8 + fmod(absf(sin(float(ix * 7 + iz * 13))) * 3.8, 3.2)
			lm.frustum("White", Vector3(cx, 0.0, cz), 0.34, 0.34, ch, 8)
			lm.frustum("Black", Vector3(cx, ch * 0.35, cz), 0.36, 0.36, ch * 0.25, 8)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 0.0), Vector3(0.0, 14.0, 44.0), 70.0, 0.95, 65.0],
	])

## Place des Vosges (Henri IV, 1612; 28 m; 138 x 138 m):
## Symmetrical Louis XIII red-brick, cream-limestone-quoin & steep blue-slate arcaded square,
## anchored by the taller Pavillon du Roi (south) & Pavillon de la Reine (north).
static func place_des_vosges(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A44E3D", 2.8))
	lm.use("Stone", LandmarkPaKit.lutetian("#E1D5BC", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#404A54", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	# Four symmetrical perimeter ranges framing the 106 x 106 m central square garden
	for i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(i))
		# Stone ground arcade + red-brick upper storeys + steep slate mansard
		lm.box("Stone", rot * Vector3(0.0, 2.8, 62.0), Vector3(136.0, 5.6, 14.0), rot)
		lm.box("Brick", rot * Vector3(0.0, 10.6, 62.0), Vector3(134.0, 10.2, 13.6), rot)
		lm.box("Slate", rot * Vector3(0.0, 18.8, 62.0), Vector3(133.0, 6.4, 12.2), rot)
		# Cream stone vertical quoins & arched ground bays facing the square
		for k in 11:
			var qx := lerpf(-54.0, 54.0, float(k) / 10.0)
			lm.box("Stone", rot * Vector3(qx, 10.6, 55.1), Vector3(1.1, 10.2, 0.3), rot)
			lm.box("Glass", rot * Vector3(qx, 10.5, 55.05), Vector3(2.2, 6.2, 0.16), rot)
	# Taller Pavillon du Roi (+Z) & Pavillon de la Reine (-Z) reaching 28.0 m
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0.0, 3.6, float(sz) * 62.0), Vector3(22.0, 7.2, 16.5))
		lm.box("Brick", Vector3(0.0, 12.6, float(sz) * 62.0), Vector3(21.0, 11.0, 16.0))
		LandmarkPaKit.pavilion_dome(lm, "Slate", "Stone", Vector3(0.0, 18.1, float(sz) * 62.0), 21.0, 16.0, 9.8)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 38.0), Vector3(0.0, 16.0, 62.0), 66.0, 0.9, 55.0],
		[Vector3(0.0, 2.0, -38.0), Vector3(0.0, 16.0, -62.0), 66.0, 0.9, 55.0],
	])
