class_name LandmarkFtChurches
extends RefCounted

## Turku's three landmark churches beyond the Cathedral, in true metres
## (+X east, +Z south, turned onto the OSM footprint by registry yaw_deg):
##  - St. Michael's Church (Mikaelinkirkko, 1905, Lars Sonck, 77 m spire)
##  - St. Martin's Church (Martinkirkko, 1933, Totti Sora & Gunnar Wahlroos)
##  - Turku Orthodox Church (1845, C.L. Engel, yellow neoclassical rotunda)

## St. Michael's Church (Mikaelinkirkko), 1905: Neo-Gothic / Jugendstil
## red-brick hall church with granite plinth, transepts, rose window,
## steep dark-slate/copper roofs and its iconic 77 m asymmetric corner
## bell tower with four corner pinnacles and tall green-copper spire.
static func mikaelinkirkko(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#944532", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#733526", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#86827B", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EAE4D6", 3.0))
	lm.use("Copper", LandmarkFrKit.copper("#4E7E6C"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A4240", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#1E262B"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Granite plinth and main nave (46 x 20 m, eaves 15 m, steep 11 m roof).
	LandmarkFrKit.rect(lm, "Stone", -23.5, 23.5, -10.5, 10.5, 0.0, 2.0)
	LandmarkFrKit.rect(lm, "Brick", -23.0, 23.0, -10.0, 10.0, 2.0, 15.0)
	LandmarkFrKit.gable(lm, "Roof", -23.0, 23.0, -10.0, 10.0, 15.0, 11.5, 0.7, "Brick", 1)
	# Transept crossing (16 x 34 m).
	LandmarkFrKit.rect(lm, "Stone", -6.5, 9.5, -17.5, 17.5, 0.0, 2.0)
	LandmarkFrKit.rect(lm, "Brick", -6.0, 9.0, -17.0, 17.0, 2.0, 15.0)
	LandmarkFrKit.gable(lm, "Roof", -6.0, 9.0, -17.0, 17.0, 15.0, 11.5, 0.7, "Brick", 0)
	# Choir apse at +X.
	lm.lathe("Stone", Vector3(23.0, 0.0, 0.0), PackedVector2Array([Vector2(8.4, 0), Vector2(8.4, 2.0)]), 8, 1.0, 1.0, 0.0, false)
	lm.lathe("Brick", Vector3(23.0, 2.0, 0.0), PackedVector2Array([Vector2(8.0, 0), Vector2(8.0, 12.0)]), 8, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(23.0, 14.0, 0.0), PackedVector2Array([Vector2(8.6, 0), Vector2(0.3, 8.5)]), 8, 1.0, 1.0, 0.0, false)
	# Buttresses & tall pointed lancets along nave and transept gables.
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for x: float in [-17.0, -11.0, 15.0]:
			LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(x, 4.2, sz * 10.0), n, 2.2, 8.0,
				LandmarkFrParts.HEAD_POINTED, 0.35, 0.14, 1)
		for bx: float in [-20.0, -14.0, 12.0, 18.0]:
			LandmarkFrParts.buttress(lm, "BrickDark", Vector3(bx, 0, sz * 10.0), n, 1.3, 1.6, 13.0, 2)
		# Transept rose window + triple lancet below.
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(1.5, 11.5, sz * 17.0), n, 4.6, 4.6,
			LandmarkFrParts.HEAD_ROUND, 0.35, 0.15)
		for k in 3:
			LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(-2.5 + 4.0 * float(k), 3.6, sz * 17.0),
				n, 1.8, 6.2, LandmarkFrParts.HEAD_POINTED, 0.3, 0.12, 1)
	# West entrance portal.
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(-23.0, 0.2, 0.0), Vector3.LEFT, 3.6, 6.2,
		LandmarkFrParts.HEAD_POINTED, 0.55, 0.35)
	# Iconic 77 m bell tower on the north-west corner (-18, -10).
	var tx := -17.5
	var tz := -10.5
	var tw := 9.2
	LandmarkFrKit.rect(lm, "Stone", tx - tw * 0.5 - 0.3, tx + tw * 0.5 + 0.3, tz - tw * 0.5 - 0.3, tz + tw * 0.5 + 0.3, 0.0, 3.0)
	LandmarkFrKit.rect(lm, "Brick", tx - tw * 0.5, tx + tw * 0.5, tz - tw * 0.5, tz + tw * 0.5, 3.0, 42.0)
	LandmarkFrParts.band(lm, "Trim", tx - tw * 0.5, tx + tw * 0.5, tz - tw * 0.5, tz + tw * 0.5, 41.2, 0.8, 0.2)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx, 32.0, tz) + fn * (tw * 0.5), fn, 2.4, 7.2,
			LandmarkFrParts.HEAD_POINTED, 0.35, 0.18, 1)
		LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(tx, 19.0, tz) + fn * (tw * 0.5), fn, 1.6, 5.5,
			LandmarkFrParts.HEAD_POINTED, 0.3, 0.14)
	# Four corner turret pinnacles around the spire base.
	for cx: float in [-1.0, 1.0]:
		for cz: float in [-1.0, 1.0]:
			var px := tx + cx * (tw * 0.5 - 0.6)
			var pz := tz + cz * (tw * 0.5 - 0.6)
			lm.frustum("Brick", Vector3(px, 40.0, pz), 1.2, 1.05, 6.0, 6)
			lm.lathe("Copper", Vector3(px, 46.0, pz), PackedVector2Array([Vector2(1.25, 0), Vector2(0.08, 6.5)]), 6, 1.0, 1.0, 0.0, false)
	# Tall octagonal green-copper spire up to 77 m with gilded cross.
	lm.lathe("Copper", Vector3(tx, 42.0, tz), PackedVector2Array([
		Vector2(4.6, 0.0), Vector2(3.8, 4.0), Vector2(2.4, 14.0), Vector2(1.1, 24.0), Vector2(0.18, 32.5)]),
		8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Gilt", Vector3(tx, 75.8, tz), Vector3(0.22, 2.6, 0.22))
	lm.box("Gilt", Vector3(tx, 76.2, tz), Vector3(1.4, 0.22, 0.22))
	lm.commit(model)

## St. Martin's Church (Martinkirkko), 1933: Functionalist / Nordic
## Classicist pale-ochre rendered hall church with copper saddle roof,
## tall vertical window bays and a sleek 52 m campanile bell tower.
static func martinkirkko(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E2D6BE", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A867E", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0EAE0", 3.0))
	lm.use("Copper", LandmarkFrKit.copper("#4E7D6A"))
	lm.use("Glass", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Main nave (42 x 20 m, eaves 15 m, low copper gable).
	LandmarkFrKit.rect(lm, "Stone", -21.5, 21.5, -10.5, 10.5, 0.0, 1.6)
	LandmarkFrKit.rect(lm, "Wall", -21.0, 21.0, -10.0, 10.0, 1.6, 15.2)
	LandmarkFrKit.gable(lm, "Copper", -21.0, 21.0, -10.0, 10.0, 15.2, 5.2, 0.5, "Wall", 1)
	LandmarkFrParts.cornice_ring(lm, "Trim", -21.0, 21.0, -10.0, 10.0, 14.7, 0.5)
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 7:
			var x := -15.0 + 5.0 * float(k)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, 3.8, sz * 10.0), n, 1.7, 9.2,
				LandmarkFrParts.HEAD_FLAT, 0.25, 0.14, 1)
	# Entrance portico (-X).
	LandmarkFrKit.rect(lm, "Stone", -25.0, -21.0, -7.0, 7.0, 0.0, 1.4)
	LandmarkFrKit.rect(lm, "Wall", -24.0, -21.0, -6.5, 6.5, 1.4, 11.0)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(-24.0, 1.4, 0.0), Vector3.LEFT, 3.8, 5.5,
		LandmarkFrParts.HEAD_FLAT, 0.4, 0.25)
	# Tall sleek 52 m functionalist bell tower at (-15, 13.5).
	var tx := -14.0
	var tz := 13.5
	LandmarkFrKit.rect(lm, "Stone", tx - 4.2, tx + 4.2, tz - 4.2, tz + 4.2, 0.0, 2.0)
	LandmarkFrKit.rect(lm, "Wall", tx - 3.9, tx + 3.9, tz - 3.9, tz + 3.9, 2.0, 41.0)
	LandmarkFrParts.cornice_ring(lm, "Trim", tx - 3.9, tx + 3.9, tz - 3.9, tz + 3.9, 40.4, 0.6)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		LandmarkFrParts.louvre(lm, "Copper", Vector3(tx, 33.0, tz) + fn * 3.9, fn, 2.6, 5.5, 7)
	# Copper lantern and cross to 52 m.
	lm.frustum("Copper", Vector3(tx, 41.0, tz), 3.6, 2.4, 4.5, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(tx, 45.5, tz), PackedVector2Array([Vector2(2.4, 0), Vector2(0.15, 4.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Gilt", Vector3(tx, 50.9, tz), Vector3(0.2, 2.2, 0.2))
	lm.box("Gilt", Vector3(tx, 51.3, tz), Vector3(1.2, 0.2, 0.2))
	lm.commit(model)

## Turku Orthodox Church (Pyhän marttyyrikeisarinna Aleksandran kirkko,
## 1845, C.L. Engel) on Kauppatori: yellow neoclassical rotunda with white
## pilasters, four projecting entrance porticos, high cylindrical drum,
## hemispherical copper dome and gilded Orthodox cross (27 m).
static func turku_orthodox_church(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6CA78", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F0E6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#96928A", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4A7462"))
	lm.use("Glass", LandmarkMaterials.glass("#20282E"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Granite plinth and main rotunda (radius 11 m, wall 10.5 m).
	lm.frustum("Stone", Vector3.ZERO, 11.6, 11.4, 1.4, 24)
	lm.frustum("Wall", Vector3(0, 1.4, 0), 11.0, 11.0, 9.2, 24)
	lm.frustum("Trim", Vector3(0, 10.2, 0), 11.4, 11.4, 0.7, 24)
	# Four cross-axis entrance porticos with triangular pediments.
	for f in 4:
		var ang := PI * 0.5 * float(f)
		var rb := Basis(Vector3.UP, ang)
		var out: Vector3 = rb * Vector3(0, 0, 1)
		var c := out * 11.6
		lm.box("Stone", c + Vector3(0, 0.7, 0), Vector3(8.2, 1.4, 3.6), rb)
		lm.box("Wall", c + Vector3(0, 5.4, 0), Vector3(7.6, 8.0, 2.8), rb)
		lm.box("Trim", c + Vector3(0, 9.6, 0), Vector3(8.2, 0.7, 3.4), rb)
		lm.gable("Copper", c + Vector3(0, 9.95, 0), 8.2, 3.4, 2.2, rb, 0.15, "Trim")
		# Portico columns / pilasters and arched doorway.
		for k in [-2.8, -1.0, 1.0, 2.8]:
			var rt: Vector3 = rb * Vector3(k, 0, 0)
			lm.frustum("Trim", c + rt + out * 1.45 + Vector3(0, 1.4, 0), 0.34, 0.30, 8.0, 10)
		LandmarkFrParts.opening(lm, "Trim", "Glass", c + out * 1.42 + Vector3(0, 1.4, 0), out, 2.2, 4.6,
			LandmarkFrParts.HEAD_ROUND, 0.3, 0.18)
	# Cylindrical drum with arched windows (r=7.2 m, y=10.9..17.2 m).
	lm.frustum("Wall", Vector3(0, 10.9, 0), 7.2, 7.2, 6.3, 24)
	lm.frustum("Trim", Vector3(0, 16.8, 0), 7.5, 7.5, 0.6, 24)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(0, 12.6, 0), 7.2, 8, 1.2, 2.8,
		LandmarkFrParts.HEAD_ROUND, PI / 8.0)
	# Hemispherical copper dome, lantern, onion finial and cross to 27 m.
	lm.lathe("Copper", Vector3(0, 17.4, 0), PackedVector2Array([
		Vector2(7.4, 0.0), Vector2(7.0, 1.6), Vector2(5.9, 3.3), Vector2(4.2, 4.7), Vector2(2.0, 5.5), Vector2(1.1, 5.8)]),
		24, 1.0, 1.0, 0.0, false)
	lm.frustum("Trim", Vector3(0, 23.0, 0), 1.2, 1.1, 1.6, 12)
	lm.lathe("Gilt", Vector3(0, 24.6, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(0.85, 0.5), Vector2(0.12, 1.3)]), 12)
	lm.box("Gilt", Vector3(0, 26.4, 0), Vector3(0.14, 1.4, 0.14))
	lm.box("Gilt", Vector3(0, 26.6, 0), Vector3(0.85, 0.14, 0.14))
	lm.commit(model)
