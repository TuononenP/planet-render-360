class_name LandmarkVersailles
extends RefCounted

## The Palace of Versailles in true metres, y = 0 at the Marble Court.

## Palace of Versailles (40 m to the Royal Chapel's ridge): Le Vau and
## Hardouin-Mansart's 670 m garden front facing west (-X) — the central
## block of 25 bays (the Hall of Mirrors' 17 arched windows) with its
## three Ionic avant-corps, set forward of the North and South Wings —
## in the Italian manner: rusticated ground floor of arched windows, the
## tall arched windows of the piano nobile between pilasters, the attic
## and the flat roof behind a balustrade of trophies and vases. Behind
## it the brick-and-stone Louis XIII château round the Marble Court
## under steep slate roofs with dormers and gilded leadwork, the Royal
## Chapel, the ministers' wings, Louis XIV on horseback and the gilded
## Royal Gate (east, +X).
static func versailles(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBE9F", 4.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4503B", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4D555B", 2.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#C9BFA9", 5.0))
	lm.use("Bronze", LandmarkMaterials.paint("#4C4A40", 0.5, 0.6))
	_garden_front(lm)
	_old_chateau(lm)
	_chapel(lm)
	lm.commit(model)

## West garden front: central block (x -75..-40, z +-50) and the two
## wings set back 13 m (x -62..-38, z 50..290 each side).
static func _garden_front(lm: LandmarkMesh) -> void:
	var w := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Stone", -57.5, 0, 0, 35.0, 19.5, 100.0)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", -50.0, 0, sz * 170.0, 24.0, 19.5, 240.0)
		LandmarkWestKit.blk(lm, "Stone", -52.0, 0, sz * 284.0, 28.0, 20.0, 14.0)
		# Wing garden faces and their end returns: pierced storeys and pilasters.
		var z0: float = 50.0 if sz > 0.0 else -278.0
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-62.0, 0, z0), Vector3(0, 0, 1), w, 228.0, 19.5,
			57, 3, Vector2(2.0, 4.4), 1.0, 6.4, 0.4)
		for k in 58:
			lm.box("Stone", Vector3(-62.5, 9.0, z0 + 228.0 * float(k) / 57.0), Vector3(0.5, 16.0, 0.9), Basis(), 0.0)
		LandmarkWestKit.rail(lm, "Stone", Vector3(-62.3, 19.5, sz * 50.0), Vector3(-62.3, 19.5, sz * 277.0), 1.3, 1.0)
		LandmarkDetail.cornice(lm, "Stone", Vector3(-62.0, 18.3, sz * 50.0), Vector3(-62.0, 18.3, sz * 277.0), w, 1.2, false)
		for k in 30:
			var p := Vector3(-62.3, 20.8, sz * (52.0 + 7.6 * float(k)))
			lm.lathe("Stone", p, _vase(), 8)
		# End pavilions with a pediment.
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-66.0, 0, sz * 284.0 - 7.0), Vector3(0, 0, 1), w, 14.0,
			20.0, 3, 3, Vector2(2.0, 4.4), 1.0, 6.4, 0.4)
		lm.gable("Stone", Vector3(-65.5, 20.0, sz * 284.0), 14.0, 1.6, 3.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	# Central block: 25 bays on three storeys.
	var p0 := Vector3(-75.0, 0, 50.0)
	var p1 := Vector3(-75.0, 0, -50.0)
	LandmarkWestKit.bay_run(lm, "Stone", "Glass", p0, p1, w, 25, [1.2, 7.4, 15.3],
		[Vector2(2.2, -4.4), Vector2(2.4, -5.8), Vector2(1.7, 1.9)], 0.0)
	for k in 26:
		var z := 50.0 - 4.0 * float(k)
		lm.box("Stone", Vector3(-75.2, 3.2, z), Vector3(0.4, 6.4, 1.2), Basis(), 0.0)
		lm.box("Stone", Vector3(-75.25, 10.6, z), Vector3(0.5, 7.6, 0.9), Basis(), 0.0)
		lm.box("Stone", Vector3(-75.2, 16.6, z), Vector3(0.4, 3.0, 0.8), Basis(), 0.0)
	for y in [6.6, 14.4]:
		LandmarkWestKit.blk(lm, "Stone", -75.3, y, 0, 0.7, 0.6, 100.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-75.0, 18.3, -50.0), Vector3(-75.0, 18.3, 50.0), w, 1.3)
	LandmarkWestKit.rail(lm, "Stone", Vector3(-75.3, 19.5, -50.0), Vector3(-75.3, 19.5, 50.0), 1.3, 1.0)
	# Three avant-corps: four Ionic columns each, statues on the attic.
	for zc in [-32.0, 0.0, 32.0]:
		LandmarkWestKit.blk(lm, "Stone", -76.0, 6.6, zc, 2.0, 0.8, 16.0)
		for k in 4:
			var z: float = zc - 6.0 + 4.0 * float(k)
			LandmarkDetail.column(lm, "Stone", Vector3(-76.6, 7.4, z), 0.42, 7.0, "ionic", 0)
			LandmarkWestKit.figure(lm, "Stone", Vector3(-76.6, 20.5, z), 2.4)
		LandmarkWestKit.blk(lm, "Stone", -76.2, 14.4, zc, 1.6, 1.0, 16.0)
	# Trophies and vases on the balustrade.
	for k in 13:
		var p := Vector3(-75.3, 20.8, -48.0 + 8.0 * float(k))
		if k % 2 == 0:
			lm.box("Stone", p + Vector3(0, 0.9, 0), Vector3(0.7, 1.8, 1.4))
			lm.lathe("Stone", p + Vector3(0, 1.8, 0), LandmarkWestKit.ball(0.5), 8)
		else:
			lm.lathe("Stone", p, _vase(), 8)
	# Flat roofs (leads) behind the balustrades.
	LandmarkWestKit.blk(lm, "Slate", -57.5, 19.5, 0, 34.0, 0.4, 99.0)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Slate", -50.0, 19.5, sz * 170.0, 23.0, 0.4, 239.0)

## Vase on the balustrade (lathe profile).
static func _vase() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.35, 0), Vector2(0.2, 0.2), Vector2(0.45, 0.6), Vector2(0.5, 0.9),
		Vector2(0.3, 1.2), Vector2(0.15, 1.3), Vector2(0.0, 1.6)])

## Louis XIII château round the Marble Court, the royal wings, the
## ministers' wings, the statue and the gate.
static func _old_chateau(lm: LandmarkMesh) -> void:
	var e := Vector3(1, 0, 0)
	LandmarkWestKit.blk(lm, "Brick", -32.5, 0, 0, 15.0, 18.0, 70.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(-32.5, 18, 0), 16.0, 71.0, 9.0, 0.35)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-25.0, 0, 21.0), Vector3(0, 0, -1), e, 42.0, 18.0, 11, 2,
		Vector2(1.8, 4.2), 1.2, 7.6, 0.3)
	# Gilded balcony of the King's Bedchamber and the clock pediment.
	LandmarkWestKit.blk(lm, "Gilt", -24.7, 8.0, 0, 0.8, 0.5, 8.0)
	LandmarkWestKit.rail(lm, "Gilt", Vector3(-24.4, 8.5, -4.0), Vector3(-24.4, 8.5, 4.0), 1.0, 0.4)
	lm.gable("Stone", Vector3(-24.8, 18.0, 0), 10.0, 1.2, 3.5, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	lm.disc("Gilt", Vector3(-24.2, 19.5, 0), e, 1.0, 16)
	for k in 6:
		LandmarkWestKit.figure(lm, "Stone", Vector3(-24.7, 18.0, -7.5 + 3.0 * float(k)), 2.0)
	for k in 9:
		var z := -28.0 + 7.0 * float(k)
		LandmarkWestKit.dormer(lm, "Stone", "Slate", "Glass", Vector3(-25.6, 18.6, z), e, 1.8, 2.8, 2.0)
		lm.lathe("Gilt", Vector3(-32.5, 27.0, z), LandmarkWestKit.ogee_prof(0.3, 1.6), 6)
	for zc in [-24.0, -8.0, 8.0, 24.0]:
		LandmarkWestKit.chimney(lm, "Brick", Vector3(-32.5, 24.0, zc), 1.4, 3.0, 5.0)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, -sz)
		LandmarkWestKit.blk(lm, "Brick", -4.0, 0, sz * 31.5, 56.0, 18.0, 7.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(-4.0, 18, sz * 31.5), 57.0, 8.0, 8.0, 0.4)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-32.0 if sz > 0.0 else 24.0, 0, sz * 28.0),
			Vector3(sz, 0, 0), n, 56.0, 18.0, 14, 2, Vector2(1.8, 4.2), 1.2, 7.6, 0.3)
		for k in 12:
			LandmarkWestKit.dormer(lm, "Stone", "Slate", "Glass", Vector3(-28.0 + 4.5 * float(k), 18.6, sz * 28.6), n, 1.6, 2.6, 2.0)
		LandmarkWestKit.blk(lm, "Stone", 12.0, 0, sz * 31.5, 10.0, 22.0, 9.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(12.0, 22, sz * 31.5), 11.0, 10.0, 8.0, 0.0)
		# Royal wings and the long ministers' wings round the entrance court.
		LandmarkWestKit.blk(lm, "Stone", 50.0, 0, sz * 62.0, 70.0, 19.0, 18.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(50.0, 19, sz * 62.0), 71.0, 19.0, 5.5, 0.8)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(15.0 if sz > 0.0 else 85.0, 0, sz * 53.0),
			Vector3(1.0 if sz > 0.0 else -1.0, 0, 0), n, 70.0, 19.0, 17, 3, Vector2(1.8, 3.6), 1.2, 6.0, 0.3)
		LandmarkWestKit.blk(lm, "Stone", 160.0, 0, sz * 105.0, 200.0, 17.0, 17.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(160.0, 17, sz * 105.0), 201.0, 18.0, 5.0, 0.8)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(62.0 if sz > 0.0 else 236.0, 0, sz * 96.5),
			Vector3(1.0 if sz > 0.0 else -1.0, 0, 0), n, 174.0, 17.0, 30, 2, Vector2(1.7, 3.6), 3.0, 6.8, 0.3)
		for k in 30:
			LandmarkWestKit.dormer(lm, "Stone", "Slate", "Glass", Vector3(64.9 + 5.8 * float(k), 17.4, sz * 97.2), n, 1.5, 2.2, 1.8)
		LandmarkWestKit.blk(lm, "Stone", 250.0, 0, sz * 105.0, 30.0, 22.0, 30.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(250.0, 22, sz * 105.0), 31.0, 31.0, 8.0, 0.0)
		LandmarkWestKit.blk(lm, "Stone", 80.0, 0, sz * 83.0, 16.0, 17.0, 26.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(80.0, 17, sz * 83.0), 17.0, 27.0, 5.0, 0.6)
	LandmarkWestKit.blk(lm, "Court", -2.0, 0, 0, 44.0, 0.3, 56.0)
	# Louis XIV on horseback in the forecourt.
	LandmarkWestKit.blk(lm, "Stone", 120.0, 0, 0, 4.0, 4.2, 6.5)
	var hb := Vector3(120.0, 4.2, 0)
	lm.beam("Bronze", hb + Vector3(0, 2.0, -1.5), hb + Vector3(0, 2.3, 1.4), 1.2, 1.4)
	for lz in [-1.2, 1.2]:
		for lx in [-0.4, 0.4]:
			lm.beam("Bronze", hb + Vector3(lx, 1.8, lz), hb + Vector3(lx, 0.0, lz + 0.1), 0.22)
	lm.beam("Bronze", hb + Vector3(0, 2.6, 1.4), hb + Vector3(0, 3.6, 2.1), 0.5, 0.6)
	LandmarkKits.statue_figure(lm, "Bronze", hb + Vector3(0, 2.3, -0.2), 2.6, true)
	# The gilded Royal Gate and its railings.
	LandmarkWestKit.merlons(lm, "Gilt", Vector3(262.0, 0, -86.0), Vector3(262.0, 0, 86.0), 1.5, 0.2, 2.8, 0.2)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", 262.0, 0, sz * 8.0, 1.6, 4.0, 1.6)
		lm.lathe("Gilt", Vector3(262.0, 4.0, sz * 8.0), LandmarkWestKit.ball(0.6), 8)
	lm.lathe("Gilt", Vector3(262.0, 3.0, 0), LandmarkWestKit.ogee_prof(1.2, 3.2), 10)

## Royal Chapel: tall nave with two tiers of arched windows, a balustrade
## of statues, the high slate roof with its gilded ridge (40 m) and the
## rounded east apse.
static func _chapel(lm: LandmarkMesh) -> void:
	var c := Vector3(-19.0, 0, -94.0)
	LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 42.0, 25.0, 22.0)
	lm.frustum("Stone", c + Vector3(21.0, 0, 0), 11.0, 11.0, 25.0, 16)
	lm.gable("Slate", c + Vector3(0, 25.0, 0), 22.0, 42.0, 13.0, Basis(Vector3.UP, PI * 0.5), 0.8, "Stone")
	lm.lathe("Slate", c + Vector3(21.0, 25.0, 0), PackedVector2Array([Vector2(11.6, 0), Vector2(0.0, 13.0)]), 16,
		1.0, 1.0, 0.0, false)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 6:
			var x := c.x - 17.5 + 7.0 * float(k)
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(x, 5.5, c.z + sz * 11.0), n, 2.4, 6.0, true)
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(x, 15.5, c.z + sz * 11.0), n, 2.6, 8.0, true)
			lm.box("Stone", Vector3(x + 3.5, 12.5, c.z + sz * 11.3), Vector3(1.0, 25.0, 0.6))
			LandmarkWestKit.figure(lm, "Stone", Vector3(x, 26.2, c.z + sz * 10.8), 2.2)
		LandmarkWestKit.rail(lm, "Stone", Vector3(c.x - 21.0, 25.0, c.z + sz * 11.2), Vector3(c.x + 21.0, 25.0, c.z + sz * 11.2), 1.2, 0.8)
	# Gilded lead cresting on the ridge, finials to 40 m.
	for k in 22:
		var x := c.x - 20.0 + 2.0 * float(k)
		lm.box("Gilt", Vector3(x, 38.4, c.z), Vector3(0.2, 0.9, 0.2), Basis(), 0.0)
	lm.beam("Gilt", Vector3(c.x - 21.0, 38.85, c.z), Vector3(c.x + 21.0, 38.85, c.z), 0.2, 0.15)
	for sx in [-1.0, 1.0]:
		lm.lathe("Gilt", Vector3(c.x + sx * 19.0, 38.0, c.z), LandmarkWestKit.ogee_prof(0.5, 2.0), 8)
