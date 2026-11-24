class_name LandmarkPaConcordeBourbon
extends RefCounted

## Place de la Concorde & Palais Bourbon (Assemblée Nationale) (`PA-3`):
## - Place de la Concorde (26.5 m): 23 m pink-granite Luxor Obelisk with gilded pyramidion,
##   twin bronze & gilt Fontaine des Mers & Fontaine des Fleuves, rostral lamps, and the
##   twin colonnaded Gabriel palaces (Hôtel de la Marine & Hôtel de Crillon) framing Rue Royale.
## - Palais Bourbon (28 m): 12-column Corinthian Greek-temple riverfront overlooking the Seine.

static func place_de_la_concorde(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#C89B86", 2.2))
	lm.use("Plinth", LandmarkPaKit.ashlar("#B9B0A0", 3.0))
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.4))
	lm.use("Sculpture", LandmarkMaterials.marble("#E5DAC2", 0.36))
	lm.use("Bronze", LandmarkPaKit.bronze("#353F38"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.pool_water())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A6", 1.45))
	# Central stepped octagonal terrace & Luxor Obelisk (pedestal 3.5 m + 23 m shaft = 26.5 m)
	lm.frustum("Plinth", Vector3(0.0, 0.0, 0.0), 11.5, 10.8, 0.6, 8)
	lm.box("Plinth", Vector3(0.0, 2.0, 0.0), Vector3(4.6, 3.0, 4.6))
	lm.box("Gilt", Vector3(0.0, 2.2, 2.36), Vector3(3.0, 1.8, 0.1))
	lm.box("Gilt", Vector3(0.0, 2.2, -2.36), Vector3(3.0, 1.8, 0.1))
	# Pink Syene granite obelisk shaft (3.5..23.3 m) + gleaming gilded pyramidion (23.3..26.5 m)
	lm.frustum("Granite", Vector3(0.0, 3.5, 0.0), 1.65, 1.05, 19.8, 4, PI * 0.25)
	lm.frustum("Gilt", Vector3(0.0, 23.3, 0.0), 1.05, 0.03, 3.2, 4, PI * 0.25)
	# Twin monumental fountains: Fontaine des Fleuves (-Z north) & Fontaine des Mers (+Z south)
	for sz in [-1.0, 1.0]:
		var fc := Vector3(0.0, 0.0, float(sz) * 58.0)
		lm.lathe("Plinth", fc, PackedVector2Array([
			Vector2(9.6, 0.0), Vector2(9.6, 0.55), Vector2(9.35, 0.95),
			Vector2(8.8, 0.95), Vector2(8.7, 0.50),
		]), 32, 1.0, 1.0, 0.0, true, false)
		lm.disc("Water", fc + Vector3(0.0, 0.86, 0.0), Vector3.UP, 8.75, 32)
		lm.lathe("Bronze", fc + Vector3(0.0, 0.85, 0.0), PackedVector2Array([
			Vector2(3.6, 0.0), Vector2(3.1, 0.65), Vector2(2.45, 1.85), Vector2(2.85, 2.65),
		]), 18)
		# Hittorff's six bronze Nereids & Tritons seated around the lower pedestal spouting water
		for k in 6:
			var a := TAU * float(k) / 6.0 + PI / 6.0
			var d := Vector3(cos(a), 0.0, sin(a))
			SculptureKit.triton_figure(lm, "Bronze", fc + d * 3.15 + Vector3(0.0, 0.95, 0.0),
				2.35, atan2(d.x, d.z), k % 2 == 0)
		# Moulded lower & upper gilded-rim vasques and upper caryatid/genius figures
		lm.lathe("Gilt", fc + Vector3(0.0, 3.45, 0.0), PackedVector2Array([
			Vector2(1.6, 0.0), Vector2(3.8, 0.35), Vector2(4.65, 0.78),
			Vector2(4.35, 0.82), Vector2(1.4, 0.45),
		]), 24)
		lm.lathe("Bronze", fc + Vector3(0.0, 4.15, 0.0), PackedVector2Array([
			Vector2(1.45, 0.0), Vector2(1.12, 1.25), Vector2(1.22, 2.45),
		]), 14)
		for k in 3:
			var a := TAU * float(k) / 3.0
			SculptureKit.classical_figure(lm, "Bronze", fc + Vector3(cos(a) * 1.25, 4.25, sin(a) * 1.25),
				2.15, false, atan2(cos(a), sin(a)))
		lm.lathe("Gilt", fc + Vector3(0.0, 6.55, 0.0), PackedVector2Array([
			Vector2(0.85, 0.0), Vector2(1.85, 0.30), Vector2(2.25, 0.62), Vector2(1.95, 0.65),
		]), 20)
	# Ornate black-and-gold rostral lamp columns ringing the square
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var lp := Vector3(cos(a) * 34.0, 0.0, sin(a) * 44.0)
		LandmarkPaKit.candelabrum(lm, "Bronze", "Lamp", lp, 6.2)
	# Four corner neoclassical pavilions crowned by sculpted allegorical statues of French cities
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pp := Vector3(float(sx) * 78.0, 0.0, float(sz) * 86.0)
			lm.box("Stone", pp + Vector3(0.0, 3.0, 0.0), Vector3(7.0, 6.0, 7.0))
			lm.box("Plinth", pp + Vector3(0.0, 6.2, 0.0), Vector3(7.4, 0.4, 7.4))
			SculptureKit.classical_figure(lm, "Sculpture", pp + Vector3(0.0, 6.4, 0.0),
				3.5, false, atan2(-float(sx), -float(sz)))
	lm.commit(model)
	_concorde_fountain_flow(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(12.0, 1.5, 12.0), Vector3(0.0, 16.0, 0.0), 48.0, 1.1, 45.0],
		[Vector3(-12.0, 1.5, -12.0), Vector3(0.0, 16.0, 0.0), 48.0, 1.1, 45.0],
		[Vector3(0.0, 1.5, 72.0), Vector3(0.0, 6.0, 58.0), 58.0, 0.9, 32.0],
		[Vector3(0.0, 1.5, -72.0), Vector3(0.0, 6.0, -58.0), 58.0, 0.9, 32.0],
	])

static func _concorde_fountain_flow(model: Node3D) -> void:
	var fk := FountainKit.new()
	for sz in [-1.0, 1.0]:
		var fc := Vector3(0.0, 0.0, float(sz) * 58.0)
		var wat_y := 0.92
		# Cresting central vertical plume above the top gilded bowl.
		fk.jet_plume(fc + Vector3(0.0, 7.15, 0.0), 2.8, 0.16, 0.48)
		# Overflowing water curtains cascading from upper gilded bowl -> main bowl -> grand basin.
		fk.bowl_curtain(fc, 1.95, 7.10, 4.20, 0.65, 22)
		fk.bowl_curtain(fc, 4.30, 4.15, wat_y, 1.15, 28)
		fk.splash_ring(fc + Vector3(0.0, wat_y, 0.0), 6.4, 0.90)
		# Six arched jets leaping outward from the bronze triton & nereid figures around the basin.
		for k in 6:
			var a := TAU * float(k) / 6.0 + PI / 6.0
			var d := Vector3(cos(a), 0.0, sin(a))
			fk.arc_stream(fc + d * 3.2 + Vector3(0.0, 2.8, 0.0), fc + d * 6.9 + Vector3(0.0, wat_y, 0.0),
				1.05, 0.11, 0.28)
			fk.splash_ring(fc + d * 6.9 + Vector3(0.0, wat_y, 0.0), 1.35, 0.82)
		fk.mist_emitter(fc + Vector3(0.0, wat_y + 0.45, 0.0), 2.4, 1.5, 5)
	fk.commit(model)

## Palais Bourbon / Assemblée Nationale (28 m; 96 x 78 m):
## Poyet's 1806 12-column Corinthian temple front overlooking Quai d'Orsay & Pont de la Concorde,
## broad ceremonial staircase flanked by seated statues, sculpted pediment, and classical wings.
static func palais_bourbon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#46505A", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Main chamber block & flanking classical wings
	lm.box("Ashlar", Vector3(0.0, 2.2, 0.0), Vector3(92.0, 4.4, 62.0))
	lm.box("Stone", Vector3(0.0, 12.5, 6.0), Vector3(88.0, 17.5, 48.0))
	LandmarkPaKit.mansard(lm, "Slate", "Stone", "Glass", Vector3(0.0, 21.2, 6.0), 86.0, 46.0, 5.2, 10)
	# Iconic 12-column Corinthian Greek-temple portico facing North (-Z toward Place de la Concorde!)
	for k in 8:
		var t := float(k) / 7.0
		lm.box("Ashlar", Vector3(0.0, 0.28 * float(k + 1), -38.0 + t * 9.0), Vector3(48.0 - t * 2.0, 0.56, 1.6))
	lm.box("Ashlar", Vector3(0.0, 2.2, -24.0), Vector3(46.0, 4.4, 14.0))
	LandmarkPaKit.colonnade_x(lm, "Stone", -21.0, 21.0, 4.4, -29.2, 12, 14.8, 0.62)
	lm.box("Stone", Vector3(0.0, 20.4, -24.0), Vector3(46.0, 2.2, 14.0))
	LandmarkPaKit.pediment_z(lm, "Stone", 0.0, 21.5, -29.4, 46.5, 4.6, 3.2)
	# Seated allegorical statues (Sully, Colbert, L'Hôpital, d'Aguesseau) flanking the grand stairs
	for sx in [-22.0, -14.0, 14.0, 22.0]:
		lm.box("Ashlar", Vector3(float(sx), 2.0, -39.5), Vector3(2.8, 4.0, 2.8))
		SculptureKit.classical_figure(lm, "Stone", Vector3(float(sx), 4.0, -39.5), 2.8, false, PI)
	LandmarkPaKit.win_grid_z(lm, "Glass", -40.0, -24.0, -18.2, [8.0, 14.0], 3, 2.0, 3.6)
	LandmarkPaKit.win_grid_z(lm, "Glass", 24.0, 40.0, -18.2, [8.0, 14.0], 3, 2.0, 3.6)
	for lx in [-26.0, 26.0]:
		LandmarkPaKit.paris_lamp(lm, "Slate", "Lamp", Vector3(float(lx), 0.0, -42.0), 4.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 2.0, -46.0), Vector3(-14.0, 16.0, -29.0), 58.0, 1.0, 58.0],
		[Vector3(18.0, 2.0, -46.0), Vector3(14.0, 16.0, -29.0), 58.0, 1.0, 58.0],
	])
