class_name AmsDamEnsemble
extends RefCounted

## Dam Square & Singel foreground landmarks (56–320 m from capital centre):
##   - Koninklijk Paleis / Royal Palace of Amsterdam (51.75 m)
##   - De Nieuwe Kerk (60.0 m)
##   - Nationaal Monument (22.0 m)
##   - De Bijenkorf (34.0 m)
##   - Magna Plaza (38.0 m)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")

## Jacob van Campen's 1655 Royal Palace on Dam Square: Bentheimer sandstone
## quadrangle (80 x 63 m around two inner light courts), twin pilastered
## fronts, rusticated 7-arch ground arcade, sculpted central pediments with
## bronze rooftop figures, hipped dark-slate roof, and 51.75 m octagonal
## carillon cupola with gilded cog-ship weathervane.
static func royal_palace_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#CFC3A8", "#3B4249")
	lm.use("SandDark", LandmarkMaterials.pbr("limestone", "#B8AB90", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4B524A", 2.0, 0.42, 0.65))
	# Rusticated base & main sandstone quadrangle (around inner courts)
	lm.box("SandDark", Vector3(0.0, 2.2, 0.0), Vector3(80.0, 4.4, 62.0))
	# Four perimeter ranges enclosing two light courts
	lm.box("Stone", Vector3(0.0, 14.2, 23.0), Vector3(80.0, 19.6, 16.0))
	lm.box("Stone", Vector3(0.0, 14.2, -23.0), Vector3(80.0, 19.6, 16.0))
	lm.box("Stone", Vector3(-32.0, 14.2, 0.0), Vector3(16.0, 19.6, 30.0))
	lm.box("Stone", Vector3(32.0, 14.2, 0.0), Vector3(16.0, 19.6, 30.0))
	# Central Burgerzaal hall dividing the two courts
	lm.box("Stone", Vector3(0.0, 15.0, 0.0), Vector3(26.0, 21.2, 32.0))
	# Projecting corner & central pavilions on Dam (+Z) and Voorburgwal (-Z)
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0.0, 14.5, sz * 31.6), Vector3(28.0, 20.2, 1.8))
		for sx in [-1.0, 1.0]:
			lm.box("Stone", Vector3(sx * 32.5, 14.5, sz * 31.4), Vector3(15.0, 20.2, 1.4))
		# Seven arched Dam entrance bays in rusticated base
		K.window_row(lm, "Dark", Vector3(-11.0, 0.0, sz * 32.55), Vector3(11.0, 0.0, sz * 32.55),
			Vector3(0.0, 0.0, sz), 0.3, 7, 1.8, 3.4)
		# Two grand Corinthian pilaster window tiers (flush on both recessed & projecting bays)
		for y0 in [6.2, 11.4, 16.6, 20.6]:
			K.window_row(lm, "Glass", Vector3(-37.0, 0.0, sz * 32.56), Vector3(37.0, 0.0, sz * 32.56),
				Vector3(0.0, 0.0, sz), y0, 19, 1.7, 2.8 if y0 < 16.0 else 2.1)
		# Classical pilasters along the front
		for i in 15:
			var px := -35.0 + 5.0 * float(i)
			lm.box("SandDark", Vector3(px, 14.2, sz * 32.45), Vector3(0.75, 19.2, 0.7))
		# Sculpted central triangular pediment & rooftop bronze figures
		K.pediment(lm, "Stone", "SandDark", Vector3(0.0, 24.4, sz * 31.8),
			Vector3(0.0, 0.0, sz), 27.0, 5.4, 1.6)
		for ox in [-12.5, 0.0, 12.5]:
			var py := 30.0 if absf(ox) < 1.0 else 25.0
			lm.frustum("Bronze", Vector3(ox, py, sz * 31.8), 0.65, 0.38, 3.2, 8)
	# Side elevation windows & stringcourses
	for sx in [-1.0, 1.0]:
		for y0 in [6.2, 11.4, 16.6]:
			K.window_row(lm, "Glass", Vector3(sx * 40.05, 0.0, -26.0), Vector3(sx * 40.05, 0.0, 26.0),
				Vector3(sx, 0.0, 0.0), y0, 13, 1.7, 2.7)
	K.stone_band(lm, "SandDark", 0.0, 0.0, 80.2, 62.2, 4.5, 0.6, 0.35)
	K.stone_band(lm, "Stone", 0.0, 0.0, 80.8, 62.8, 24.1, 0.9, 0.55)
	# Steep hipped slate roofs over the four ranges & Burgerzaal
	K.pitched_roof(lm, "Roof", Vector3(0.0, 24.5, 23.0), 79.0, 16.5, 6.2, true)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 24.5, -23.0), 79.0, 16.5, 6.2, true)
	K.pitched_roof(lm, "Roof", Vector3(-32.0, 24.5, 0.0), 16.5, 48.0, 6.2, false)
	K.pitched_roof(lm, "Roof", Vector3(32.0, 24.5, 0.0), 16.5, 48.0, 6.2, false)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 25.6, 0.0), 26.0, 32.0, 5.5, false)
	# Iconic 51.75 m octagonal carillon cupola rising above the Dam front
	var c := Vector3(0.0, 24.5, 19.5)
	lm.box("Stone", c + Vector3.UP * 4.5, Vector3(11.6, 9.0, 11.6))
	K.stone_band(lm, "SandDark", c.x, c.z, 12.2, 12.2, c.y + 9.0, 0.7, 0.35)
	# Open columned carillon octagon
	lm.frustum("Stone", c + Vector3.UP * 9.5, 5.2, 5.0, 4.2, 8)
	for k in 8:
		var ang := float(k) * TAU / 8.0
		lm.frustum("Stone", c + Vector3(cos(ang) * 4.3, 13.7, sin(ang) * 4.3), 0.48, 0.42, 5.4, 8)
	lm.frustum("Lamp", c + Vector3.UP * 14.3, 2.2, 2.0, 4.2, 8)
	lm.frustum("Stone", c + Vector3.UP * 19.1, 5.1, 4.8, 0.8, 8)
	# Ribbed lead/slate cupola dome + lantern + gilded cog-ship weathervane
	lm.lathe("Roof", c + Vector3.UP * 19.9, PackedVector2Array([
		Vector2(4.6, 0.0), Vector2(4.4, 1.8), Vector2(3.1, 3.6), Vector2(1.4, 4.6), Vector2(0.4, 4.9),
	]), 16)
	lm.frustum("Gold", c + Vector3.UP * 24.8, 0.32, 0.08, 2.45, 8)
	# Warm Dam facade uplight strips & LandmarkLights flood spots for night
	lm.box("Lamp", Vector3(0.0, 4.8, 32.4), Vector3(26.0, 0.35, 0.3))
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-24.0, 1.5, 42.0), Vector3(-24.0, 16.0, 31.0), 52.0, 1.1],
		[Vector3(0.0, 1.5, 44.0), Vector3(0.0, 22.0, 30.0), 58.0, 1.35],
		[Vector3(24.0, 1.5, 42.0), Vector3(24.0, 16.0, 31.0), 52.0, 1.1],
		[Vector3(0.0, 24.0, 28.0), Vector3(0.0, 44.0, 19.5), 42.0, 1.2],
	])
	lm.commit(model)

## De Nieuwe Kerk (15th-century late-Gothic cruciform basilica beside Dam Square):
## buff sandstone & dark-brick walls, steep dark-slate nave & transept roofs,
## stepped buttresses, pointed Gothic windows, and slender 60 m crossing spire.
static func nieuwe_kerk_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#6E3A2F", "#C9BEA6", "#373E46")
	# Cruciform nave (62 x 16 m along X) + transept (16 x 28 m along Z), matching OSM 66 x 28 m
	lm.box("Stone", Vector3(0.0, 10.5, 0.0), Vector3(58.0, 21.0, 16.0))
	lm.box("Stone", Vector3(4.0, 10.5, 0.0), Vector3(16.0, 21.0, 28.0))
	# Lower side aisles & polygonal apse
	lm.box("Brick", Vector3(-2.0, 5.8, 0.0), Vector3(52.0, 11.6, 22.0))
	lm.frustum("Stone", Vector3(28.0, 0.0, 0.0), 8.2, 8.0, 20.5, 8)
	# Steep slate roofs over nave, transept & apse
	K.pitched_roof(lm, "Roof", Vector3(0.0, 21.0, 0.0), 58.5, 16.6, 11.5, true)
	K.pitched_roof(lm, "Roof", Vector3(4.0, 21.0, 0.0), 16.6, 28.5, 11.5, false)
	lm.frustum("Roof", Vector3(28.0, 20.5, 0.0), 8.3, 0.4, 11.0, 8)
	# Transept & west gable walls + Gothic lancet windows around nave & apse
	K.step_gable(lm, "Stone", "White", Vector3(-29.0, 21.0, 0.0), Vector3.LEFT, 16.0, 11.2, 6, 1.0)
	for sz in [-1.0, 1.0]:
		K.step_gable(lm, "Stone", "White", Vector3(4.0, 21.0, sz * 14.0), Vector3(0.0, 0.0, sz), 16.0, 11.2, 6, 1.0)
		K.window_row(lm, "Glass", Vector3(-22.0, 0.0, sz * 8.12), Vector3(22.0, 0.0, sz * 8.12),
			Vector3(0.0, 0.0, sz), 11.8, 9, 2.0, 7.2)
		K.window_row(lm, "Glass", Vector3(-1.0, 0.0, sz * 14.12), Vector3(9.0, 0.0, sz * 14.12),
			Vector3(0.0, 0.0, sz), 4.5, 3, 2.2, 13.0)
		# Gothic buttress piers
		for i in 8:
			var bx := -23.0 + 6.6 * float(i)
			lm.box("Stone", Vector3(bx, 10.0, sz * 11.2), Vector3(1.0, 20.0, 1.2))
			lm.frustum("Stone", Vector3(bx, 20.0, sz * 11.2), 0.55, 0.12, 2.4, 6)
	# Tall Gothic apse lancets around the polygonal east choir
	for k in 5:
		var ang := deg_to_rad(-80.0 + float(k) * 40.0)
		var n := Vector3(cos(ang), 0.0, sin(ang))
		lm.box("Glass", Vector3(28.0, 11.5, 0.0) + n * 8.18, Vector3(2.0, 11.5, 0.22),
			Basis(Vector3.UP, atan2(n.x, n.z)))
	# Slender 60 m neo-Gothic crossing spire (flèche)
	var sc := Vector3(4.0, 31.5, 0.0)
	lm.frustum("Roof", sc, 2.8, 2.4, 5.5, 8)
	lm.frustum("Lamp", sc + Vector3.UP * 5.5, 1.8, 1.6, 3.2, 8)
	for k in 8:
		var ang := float(k) * TAU / 8.0
		lm.frustum("Stone", sc + Vector3(cos(ang) * 2.1, 5.5, sin(ang) * 2.1), 0.22, 0.16, 3.4, 6)
	lm.frustum("Roof", sc + Vector3.UP * 8.7, 2.3, 0.10, 19.8, 8)
	lm.commit(model)

## Nationaal Monument on Dam Square (J.J.P. Oud, 1956): 22 m white travertine
## conical pylon, relief niches, stepped circular plinth, curved urn wall & lions.
static func nationaal_monument_dam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#E5DFD0", "#4A5058")
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#ECE7DA", 2.2))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#C8C2B6", 2.8))
	# Circular terraced stone platform
	lm.frustum("Steps", Vector3.ZERO, 14.0, 13.4, 0.55, 24)
	lm.frustum("Steps", Vector3(0.0, 0.55, 0.0), 11.4, 10.8, 0.55, 24)
	lm.frustum("Travertine", Vector3(0.0, 1.1, 0.0), 8.6, 8.2, 0.65, 20)
	# 22 m tapered conical travertine obelisk pylon
	lm.frustum("Travertine", Vector3(0.0, 1.75, 0.0), 2.35, 1.38, 19.6, 20)
	lm.frustum("Travertine", Vector3(0.0, 21.35, 0.0), 1.38, 0.12, 0.65, 16)
	# Sculpted front relief plinth & figures facing Dam Palace (+Z)
	lm.box("Stone", Vector3(0.0, 4.4, 2.2), Vector3(3.2, 5.4, 1.4))
	lm.box("Travertine", Vector3(0.0, 9.2, 1.85), Vector3(1.4, 3.6, 0.9))
	# Curved urn memorial wall behind (-Z arc)
	for i in 9:
		var ang := deg_to_rad(-145.0 + float(i) * 13.75)
		var p := Vector3(cos(ang) * 10.8, 2.2, sin(ang) * 10.8)
		lm.box("Travertine", p, Vector3(2.8, 2.8, 0.9), Basis(Vector3.UP, -ang + PI * 0.5))
		lm.frustum("Stone", Vector3(p.x, 3.6, p.z), 0.36, 0.28, 0.75, 8)
	# Flanking crouched heraldic lions on front pedestals
	for sx in [-1.0, 1.0]:
		lm.box("Steps", Vector3(sx * 5.8, 1.9, 6.4), Vector3(1.8, 1.6, 3.2))
		lm.box("Travertine", Vector3(sx * 5.8, 3.2, 6.4), Vector3(1.1, 1.2, 2.3))
	lm.box("Lamp", Vector3(0.0, 1.85, 2.8), Vector3(2.8, 0.25, 0.35))
	lm.commit(model)

## De Bijenkorf (1914 Beaux-Arts / early Art Deco sandstone department store
## facing Dam Square): cream sandstone & terracotta facades, twin peaked corner
## towers (34 m), pedimented window bays, mansard slate roof, bronze canopies.
static func de_bijenkorf_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8F5A43", "#DCD0B8", "#3B4249")
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4E4335", 2.0, 0.4, 0.7))
	# Matches real OSM footprint (40 m wide x 106 m long along Damrak/Beursplein)
	lm.box("Stone", Vector3(0.0, 12.0, 0.0), Vector3(38.0, 24.0, 102.0))
	lm.box("Roof", Vector3(0.0, 25.8, 0.0), Vector3(34.0, 3.6, 98.0))
	K.stone_band(lm, "White", 0.0, 0.0, 38.6, 102.6, 5.2, 0.65, 0.35)
	K.stone_band(lm, "White", 0.0, 0.0, 38.8, 102.8, 23.6, 0.9, 0.5)
	for sx in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(sx * 20.2, 4.6, 0.0), Vector3(2.4, 0.45, 100.0))
		K.window_row(lm, "Glass", Vector3(sx * 19.08, 0.0, -46.0), Vector3(sx * 19.08, 0.0, 46.0),
			Vector3(sx, 0.0, 0.0), 0.6, 18, 3.4, 3.6)
		for y0 in [6.4, 11.4, 16.4, 20.2]:
			K.window_row(lm, "Glass", Vector3(sx * 19.08, 0.0, -46.0), Vector3(sx * 19.08, 0.0, 46.0),
				Vector3(sx, 0.0, 0.0), y0, 20, 2.0, 3.2 if y0 < 19.0 else 2.2)
		K.pediment(lm, "Stone", "Brick", Vector3(sx * 19.1, 24.0, 0.0), Vector3(sx, 0.0, 0.0), 22.0, 5.2, 1.4)
	for sz in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(0.0, 4.6, sz * 52.2), Vector3(36.0, 0.45, 2.4))
		for y0 in [6.4, 11.4, 16.4, 20.2]:
			K.window_row(lm, "Glass", Vector3(-15.0, 0.0, sz * 51.08), Vector3(15.0, 0.0, sz * 51.08),
				Vector3(0.0, 0.0, sz), y0, 8, 2.0, 3.2 if y0 < 19.0 else 2.2)
	# Four corner turret pavilions rising to 34 m
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := Vector3(sx * 15.5, 24.0, sz * 47.5)
			lm.box("Stone", tc + Vector3.UP * 2.5, Vector3(8.0, 5.0, 8.0))
			lm.frustum("Roof", tc + Vector3.UP * 5.0, 4.8, 0.35, 5.0, 8)
	lm.commit(model)

## Magna Plaza (C.H. Peters, 1899 — 56 m from capital centre): neo-Gothic /
## Dutch neo-Renaissance former Main Post Office in red brick & cream sandstone
## with arched ground loggia, stepped central gable & iconic pear/cone turrets.
static func magna_plaza(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8D3B2C", "#E2D6BD", "#3A424A")
	# Exact OSM footprint (36 x 74 m, 22 m eaves)
	lm.box("Brick", Vector3(0.0, 11.0, 0.0), Vector3(36.0, 22.0, 74.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 22.0, 0.0), 36.4, 74.4, 6.2, false)
	for y in [4.8, 10.5, 16.2, 21.6]:
		K.stone_band(lm, "Stone", 0.0, 0.0, 36.2, 74.2, y, 0.55, 0.25)
	for sx in [-1.0, 1.0]:
		for y0 in [1.2, 6.0, 11.8, 17.4]:
			K.window_row(lm, "Glass", Vector3(sx * 18.08, 0.0, -32.0), Vector3(sx * 18.08, 0.0, 32.0),
				Vector3(sx, 0.0, 0.0), y0, 14, 2.0, 3.0)
		K.step_gable(lm, "Brick", "Stone", Vector3(sx * 18.2, 22.0, 0.0), Vector3(sx, 0.0, 0.0), 16.0, 8.8, 5, 1.0)
	for sz in [-1.0, 1.0]:
		for y0 in [1.2, 6.0, 11.8, 17.4]:
			K.window_row(lm, "Glass", Vector3(-14.0, 0.0, sz * 37.08), Vector3(14.0, 0.0, sz * 37.08),
				Vector3(0.0, 0.0, sz), y0, 7, 2.0, 3.0)
		K.step_gable(lm, "Brick", "Stone", Vector3(0.0, 22.0, sz * 37.2), Vector3(0.0, 0.0, sz), 16.0, 8.8, 5, 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var t := Vector3(sx * 17.4, 0.0, sz * 36.2)
			lm.frustum("Brick", t, 3.4, 3.3, 24.0, 10)
			lm.frustum("Stone", t + Vector3.UP * 24.0, 3.7, 3.6, 0.8, 10)
			lm.lathe("Roof", t + Vector3.UP * 24.8, PackedVector2Array([
				Vector2(3.4, 0.0), Vector2(3.6, 2.8), Vector2(2.4, 6.0), Vector2(0.95, 9.8), Vector2(0.08, 13.2),
			]), 12)
	lm.frustum("Copper", Vector3(0.0, 28.0, 0.0), 2.4, 0.12, 8.5, 8)
	lm.box("Lamp", Vector3(18.3, 5.2, 0.0), Vector3(0.3, 0.35, 18.0))
	lm.commit(model)
