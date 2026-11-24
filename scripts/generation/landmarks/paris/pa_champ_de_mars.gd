class_name LandmarkPaChampDeMars
extends RefCounted

## Foreground landmarks around the Champ de Mars & Quai Branly (`PA-3`):
## - École Militaire (Ange-Jacques Gabriel, 1773; closes the Champ de Mars Eiffel vista)
## - Musée du Quai Branly (Jean Nouvel & Patrick Blanc, 2006; living green wall & coloured boxes)
## - Cathédrale de la Sainte-Trinité (Jean-Michel Wilmotte, 2016; 5 matte-gold onion domes)

## École Militaire (38 m to the Pavillon de l'Horloge finial; 156 x 64 m):
## Classical French limestone palace with central eight-column giant Corinthian portico,
## sculpted pediment, steep quadrangular slate pavilion dome, flanking wings and Cour d'Honneur.
static func ecole_militaire(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD0B4", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B699", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#454E58", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Main Chateau range facing NW (-Z toward Eiffel Tower & Champ de Mars)
	lm.box("Ashlar", Vector3(0.0, 2.0, 0.0), Vector3(148.0, 4.0, 28.0))
	lm.box("Stone", Vector3(0.0, 12.0, 0.0), Vector3(144.0, 16.0, 26.0))
	lm.box("Stone", Vector3(0.0, 20.5, 0.0), Vector3(146.0, 1.2, 27.6))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 21.1, 0.0), 144.0, 26.0, 6.2, 16)
	# Flanking wing pavilions framing the foreground court
	for sx in [-1.0, 1.0]:
		var wx := float(sx) * 64.0
		lm.box("Stone", Vector3(wx, 10.5, -18.0), Vector3(22.0, 21.0, 32.0))
		LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(wx, 21.0, -18.0), 22.6, 32.6, 7.0, 3, 4)
		LandmarkPaKit.win_grid_z(lm, "Glass", float(sx) * 18.0, float(sx) * 52.0, -13.1, [6.5, 12.2, 17.2], 7, 1.8, 3.2)
		LandmarkPaKit.win_grid_z(lm, "Glass", float(sx) * 18.0, float(sx) * 52.0, 13.1, [6.5, 12.2, 17.2], 7, 1.8, 3.2)
	# Iconic central Pavillon de l'Horloge: 8 giant Corinthian columns, pediment & quadrangular slate dome (38 m)
	lm.box("Stone", Vector3(0.0, 12.0, -2.5), Vector3(32.0, 24.0, 29.0))
	LandmarkPaKit.colonnade_x(lm, "Stone", -12.0, 12.0, 4.0, -17.6, 8, 16.0, 0.62)
	LandmarkPaKit.pediment_z(lm, "Stone", 0.0, 21.6, -17.5, 28.0, 5.2, 2.4)
	LandmarkPaKit.pavilion_dome(lm, "Slate", "Gilt", Vector3(0.0, 24.2, -2.0), 28.0, 22.0, 12.5)
	lm.box("Gilt", Vector3(0.0, 37.35, -2.0), Vector3(7.5, 1.3, 5.5))
	# Clock medallion & Champ de Mars court lamps
	lm.disc("Gilt", Vector3(0.0, 23.4, -18.8), Vector3(0.0, 0.0, -1.0), 1.4, 14)
	for lx in [-36.0, -16.0, 16.0, 36.0]:
		LandmarkPaKit.paris_lamp(lm, "Slate", "Lamp", Vector3(float(lx), 0.0, -28.0), 4.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.0, -34.0), Vector3(-36.0, 18.0, -13.0), 62.0, 0.9, 68.0],
		[Vector3(0.0, 2.0, -36.0), Vector3(0.0, 24.0, -15.0), 60.0, 1.1, 72.0],
		[Vector3(42.0, 2.0, -34.0), Vector3(36.0, 18.0, -13.0), 62.0, 0.9, 68.0],
	])

## Musée du Quai Branly – Jacques Chirac (22 m; 165 x 48 m):
## Jean Nouvel's glass acoustic screen along Quai Jacques-Chirac, Patrick Blanc's lush
## vertical-garden wall, and cantilevered ochre, terracotta & burgundy museum boxes on stilts.
static func musee_quai_branly(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#3B4D54"))
	lm.use("Steel", LandmarkMaterials.paint("#3E3B38", 0.45, 0.65))
	lm.use("GreenWall", LandmarkMaterials.paint("#3D6A3B", 0.85, 0.05))
	lm.use("Ochre", LandmarkMaterials.paint("#B86E2E", 0.62, 0.12))
	lm.use("Rust", LandmarkMaterials.paint("#8A2E26", 0.60, 0.15))
	lm.use("Slate", LandmarkMaterials.paint("#4E5358", 0.55, 0.35))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE0A2", 1.35))
	# Transparent glass acoustic wall along the Seine quay (-Z)
	lm.box("Glass", Vector3(0.0, 5.5, -21.0), Vector3(156.0, 11.0, 0.35))
	for i in 19:
		var mx := lerpf(-76.0, 76.0, float(i) / 18.0)
		lm.box("Steel", Vector3(mx, 5.5, -21.0), Vector3(0.28, 11.2, 0.48))
	# Patrick Blanc's famous vegetated "Mur Végétal" administration block on the west-north quay corner
	lm.box("GreenWall", Vector3(-62.0, 9.0, -11.0), Vector3(34.0, 18.0, 14.0))
	LandmarkPaKit.win_grid_z(lm, "Glass", -76.0, -48.0, -18.1, [5.0, 10.0, 14.5], 5, 2.2, 2.8)
	# Elevated main curved-deck gallery bridge resting on dark steel pilotis
	lm.box("Steel", Vector3(12.0, 11.5, 4.0), Vector3(132.0, 9.5, 22.0))
	lm.box("Glass", Vector3(12.0, 11.5, -7.12), Vector3(128.0, 7.6, 0.2))
	lm.box("Slate", Vector3(12.0, 17.5, 4.0), Vector3(128.0, 2.6, 20.0))
	# Signature cantilevered polychrome exhibition boxes jutting out toward the Seine
	var boxes := [
		[-36.0, 12.0, -10.5, 16.0, 7.8, 8.5, "Rust"],
		[-12.0, 11.2, -11.0, 14.0, 6.8, 9.0, "Ochre"],
		[14.0, 13.0, -10.2, 18.0, 8.2, 8.2, "Rust"],
		[40.0, 11.6, -10.8, 15.0, 7.2, 8.8, "Ochre"],
		[62.0, 12.6, -9.8, 14.0, 7.6, 7.5, "Slate"],
	]
	for b in boxes:
		lm.box(str(b[6]), Vector3(float(b[0]), float(b[1]), float(b[2])),
			Vector3(float(b[3]), float(b[4]), float(b[5])))
	# Supporting irregular steel pilotis beneath the bridge gallery
	for i in 12:
		var px := lerpf(-48.0, 68.0, float(i) / 11.0)
		for pz in [-3.5, 11.5]:
			lm.frustum("Steel", Vector3(px, 0.0, float(pz)), 0.55, 0.45, 7.0, 8)
	# Rooftop restaurant Les Ombres steel pergola reaching 22.0 m + warm under-gallery lighting
	lm.box("Steel", Vector3(12.0, 20.4, 4.0), Vector3(44.0, 3.2, 14.0))
	for i in 9:
		var lx := lerpf(-48.0, 64.0, float(i) / 8.0)
		lm.box("Lamp", Vector3(lx, 6.5, -6.0), Vector3(1.4, 0.25, 0.6))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-62.0, 2.0, -28.0), Vector3(-62.0, 12.0, -18.0), 60.0, 0.9, 45.0],
		[Vector3(12.0, 2.0, -26.0), Vector3(12.0, 12.0, -8.0), 68.0, 0.9, 55.0],
	])

## Cathédrale de la Sainte-Trinité (Quai Branly; Jean-Michel Wilmotte, 2016; 37 m):
## White Burgundy-limestone cube crowned by five iconic matte-gold onion domes & crosses.
static func cathedrale_sainte_trinite(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#EAE4D6", 3.0))
	lm.use("Gold", LandmarkMaterials.paint("#D8B154", 0.34, 0.78))
	lm.use("Glass", LandmarkMaterials.glass("#2A353E"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A4", 1.3))
	# Crisp modern Burgundy-limestone sanctuary block (24 x 24 x 19 m) + vaulted roofline
	lm.box("Stone", Vector3(0.0, 9.5, 0.0), Vector3(24.0, 19.0, 24.0))
	lm.box("Stone", Vector3(0.0, 19.6, 0.0), Vector3(24.8, 1.2, 24.8))
	# Tall narrow slit windows on all four limestone walls
	for i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(i))
		for kx in [-5.5, 0.0, 5.5]:
			lm.box("Glass", rot * Vector3(float(kx), 10.5, 12.08), Vector3(1.2, 11.5, 0.16), rot)
		lm.box("Lamp", rot * Vector3(0.0, 2.8, 12.25), Vector3(3.6, 0.35, 0.25), rot)
	# Central drum + large matte-gold onion dome & Orthodox cross (reaches 37.0 m!)
	lm.frustum("Stone", Vector3(0.0, 19.5, 0.0), 4.4, 4.3, 4.8, 20)
	_onion_dome(lm, "Gold", Vector3(0.0, 24.2, 0.0), 5.6, 9.6)
	LandmarkWestKit.cross(lm, "Gold", Vector3(0.0, 33.4, 0.0), 3.6)
	# Four flanking corner drums + matte-gold onion domes
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cp := Vector3(float(sx) * 7.6, 19.5, float(sz) * 7.6)
			lm.frustum("Stone", cp, 2.5, 2.4, 3.6, 16)
			_onion_dome(lm, "Gold", cp + Vector3(0.0, 3.5, 0.0), 3.3, 5.8)
			LandmarkWestKit.cross(lm, "Gold", cp + Vector3(0.0, 9.1, 0.0), 2.3)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 24.0), Vector3(0.0, 24.0, 0.0), 62.0, 1.0, 62.0],
		[Vector3(0.0, 2.0, -24.0), Vector3(0.0, 24.0, 0.0), 62.0, 1.0, 62.0],
	])

static func _onion_dome(lm: LandmarkMesh, mat: String, base: Vector3, r: float, h: float) -> void:
	var prof := PackedVector2Array([
		Vector2(r * 0.72, 0.0),
		Vector2(r * 0.96, h * 0.22),
		Vector2(r * 1.00, h * 0.42),
		Vector2(r * 0.80, h * 0.64),
		Vector2(r * 0.44, h * 0.80),
		Vector2(r * 0.16, h * 0.92),
		Vector2(0.0, h),
	])
	lm.lathe(mat, base, prof, 20)
