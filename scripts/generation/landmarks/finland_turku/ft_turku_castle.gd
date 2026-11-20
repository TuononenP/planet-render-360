class_name FtTurkuCastle
extends RefCounted

## Turku Castle (Turun linna, 1280s medieval keep & 1550s-1588 Renaissance
## bailey / Esilinna) guarding the Aura River mouth.
## Origin at OSM way 466736288 centroid (60.435350 N, 22.228750 E), yaw_deg -1.4:
##   +X bears 88.6° (East, Renaissance Bailey, east gatehouse & Round Tower)
##   -X bears 268.6° (West, 38.0 m medieval keep with timber hoarding gallery)
##   +Z bears 178.6° (South, Sture Church lancets & Hexagonal corner tower)
##   -Z bears 358.6° (North, Pentagonal corner tower & Aura riverbank flank)
##
## Architectural & facade spec (Wikimedia Commons / Finna refs + OSM way
## 466736288, height_m = 38.0):
## - Distinct three-material historic masonry:
##   * Rough medieval fieldstone granite lower walls (FOUND = -2.5 m to 9.5 m)
##     with battered plinth, heavy buttresses and narrow gun loops.
##   * Medieval red-brick vault gables, arch surrounds & Sture Church lancets.
##   * Whitewashed Renaissance upper storeys (9.5..18/20/27 m) added by Duke
##     John with rhythmic Renaissance windows and dormers.
## - Main Castle (Päälinna, x = -70.4..-6.5, z = -17.0..24.2): tall west keep
##   with timber defensive hoarding gallery (ampumakäytävä) under the steep
##   slate hip roof peaking at 38.0 m; north & south wings around inner yard
##   with Sture Church tall pointed lancets on the south wing (+Z), east gate
##   tower (33.5 m), and the 1550 & 1558 octagonal courtyard stair towers.
## - Irregular polygonal Renaissance Bailey (Esilinna, x = -6.5..59, z = -33..31.5):
##   terracotta red tiled wings enclosing the outer bailey yard, Pentagonal
##   north corner tower, Hexagonal south tower, Square east tower, massive
##   Round Cannon Tower (Pyöreä torni, r = 10.0 m) at SE corner, and the
##   arched east entrance gatehouse with cobbled forecourt.
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on the keep, Sture Church south front, Round Tower and east gatehouse.

const FOUND := -2.5
const STONE_H := 9.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C877C", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8C4735", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DDD5C2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECE7DA", 2.5))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#534031", 1.8))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#464340", 2.0))
	lm.use("RoofRed", LandmarkMaterials.pbr("terracotta", "#87493A", 2.5))
	lm.use("Dark", LandmarkMaterials.pbr("slate", "#2A2927", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#1F272B"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A2", 0.72))

	_build_main_castle(lm)
	_build_courtyard_and_towers(lm)
	_build_bailey(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.91, 0.76)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-82.0, 1.0, 4.0), Vector3(-66.0, 18.0, 3.0), 34.0, 1.10, 95.0, warm],
		[Vector3(-36.0, 1.0, 36.0), Vector3(-36.0, 14.0, 22.0), 38.0, 1.00, 80.0, warm],
		[Vector3(-36.0, 1.0, -30.0), Vector3(-36.0, 14.0, -16.0), 38.0, 0.90, 80.0, warm],
		[Vector3(72.0, 1.0, 28.0), Vector3(59.0, 10.0, 21.0), 32.0, 1.05, 70.0, warm],
		[Vector3(68.0, 1.0, -14.0), Vector3(55.0, 9.0, -14.0), 34.0, 1.00, 65.0, warm],
	])

static func _build_main_castle(lm: LandmarkMesh) -> void:
	# Battered fieldstone foundation & plinth around the Main Castle.
	LandmarkFrKit.rect(lm, "Stone", -71.5, -5.5, -18.0, 25.2, FOUND, 1.6)
	# North & south wings, tall west keep, east block around the inner courtyard.
	_wing(lm, -56.0, -18.5, -17.0, -9.5, 18.0, 7.0, "Roof", 1, false, "Brick")
	_wing(lm, -56.0, -18.5, 16.5, 24.2, 18.0, 7.0, "Roof", 1, false, "Brick")
	_wing(lm, -70.4, -56.0, -17.0, 24.2, 26.8, 10.8, "Roof", -1, true, "Brick")
	_wing(lm, -18.5, -6.5, -17.0, 24.2, 20.0, 7.5, "Roof", 0, false, "Brick")
	# Inner courtyard cobble deck.
	LandmarkFrKit.rect(lm, "Stone", -56.0, -18.5, -9.5, 16.5, FOUND, 0.45)
	# Timber defensive hoarding gallery (ampumakäytävä) projecting around the west keep eaves!
	LandmarkFrKit.rect(lm, "Timber", -71.2, -55.2, -17.8, 25.0, 25.0, 26.8)
	for z_corb in 10:
		var cz := lerpf(-16.2, 23.4, float(z_corb) / 9.0)
		lm.box("Timber", Vector3(-70.9, 24.5, cz), Vector3(1.1, 0.85, 0.32), Basis(), 0.0)
	for x_corb in 4:
		var cx := lerpf(-69.0, -57.4, float(x_corb) / 3.0)
		lm.box("Timber", Vector3(cx, 24.5, -17.5), Vector3(0.32, 0.85, 1.1), Basis(), 0.0)
		lm.box("Timber", Vector3(cx, 24.5, 24.7), Vector3(0.32, 0.85, 1.1), Basis(), 0.0)
	# Outer facades: Renaissance upper windows, medieval brick surrounds, gun loops & buttresses.
	for side: Array in [[-17.0, -1.0], [24.2, 1.0]]:
		var z: float = side[0]
		var s: float = side[1]
		var n := Vector3(0.0, 0.0, s)
		if s < 0.0:
			LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-56.0, STONE_H, z), Vector3(-18.5, STONE_H, z),
				n, 18.0 - STONE_H, 9, 2, Vector2(1.2, 1.9), 1.5, 4.3, 0.25)
		else:
			# South wing (+Z): Sture Church tall pointed brick-framed lancet windows!
			for k in 5:
				var lx := -50.0 + 6.4 * float(k)
				LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(lx, 10.6, z), n,
					2.0, 5.8, LandmarkFrParts.HEAD_POINTED, 0.34, 0.16, 1)
				lm.box("WarmGlow", Vector3(lx, 13.0, z + 0.03), Vector3(1.15, 3.2, 0.04), Basis(), 0.0)
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-70.4, STONE_H, z), Vector3(-56.0, STONE_H, z),
			n, 25.0 - STONE_H, 3, 3, Vector2(1.1, 1.8), 1.6, 4.5, 0.25)
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-18.5, STONE_H, z), Vector3(-6.5, STONE_H, z),
			n, 20.0 - STONE_H, 3, 2, Vector2(1.1, 1.8), 1.8, 4.6, 0.25)
		LandmarkFrParts.gun_loops(lm, "Stone", "Dark", Vector3(-68.0, 3.2, z), Vector3(-9.0, 3.2, z), n, 12)
		LandmarkFrParts.band(lm, "Brick", -70.4, -6.5, z - 0.02 if s < 0.0 else z, z if s < 0.0 else z + 0.02,
			STONE_H - 0.22, 0.44, 0.16)
		for k in 4:
			LandmarkFrParts.buttress(lm, "Stone", Vector3(-50.0 + 10.5 * float(k), 0.0, z), n, 2.0, 2.3, 11.2, 2)
	# West keep facade & quoins.
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-70.4, STONE_H, 24.2), Vector3(-70.4, STONE_H, -17.0),
		Vector3.LEFT, 25.0 - STONE_H, 7, 3, Vector2(1.1, 1.8), 1.6, 4.5, 0.25)
	LandmarkFrParts.gun_loops(lm, "Stone", "Dark", Vector3(-70.4, 3.2, 22.0), Vector3(-70.4, 3.2, -15.0), Vector3.LEFT, 6)
	LandmarkFrParts.corner_strips(lm, "Stone", -70.4, -56.0, -17.0, 24.2, STONE_H, 25.0, 0.95, 0.16)
	# Roof trim, chimneys & dormers.
	LandmarkFrParts.roof_trim(lm, "Dark", -56.0, -18.5, -17.0, -9.5, 18.0, 7.0, 0.5, 1)
	LandmarkFrParts.roof_trim(lm, "Dark", -56.0, -18.5, 16.5, 24.2, 18.0, 7.0, 0.5, 1)
	LandmarkFrParts.roof_trim(lm, "Dark", -18.5, -6.5, -17.0, 24.2, 20.0, 7.5, 0.5, 0)
	for cx: float in [-50.0, -38.0, -26.0]:
		LandmarkFrParts.chimney(lm, "Brick", Vector3(cx, 22.0, -13.2), 26.8, 1.25)
		LandmarkFrParts.chimney(lm, "Brick", Vector3(cx + 4.0, 22.0, 20.4), 26.8, 1.25)
	for k in 4:
		var dx := -49.0 + 9.0 * float(k)
		LandmarkFrParts.dormer(lm, "Wall", "Roof", "Glass", Vector3(dx, 20.4, -16.0), Vector3.FORWARD, 1.6, 1.6, 1.4)
		LandmarkFrParts.dormer(lm, "Wall", "Roof", "Glass", Vector3(dx, 20.4, 23.2), Vector3.BACK, 1.6, 1.6, 1.4)
	# Finial on the west keep ridge peaking at exactly 38.0 m.
	lm.spire("Dark", Vector3(-63.2, 37.55, 3.6), 0.14, 0.45)

static func _build_courtyard_and_towers(lm: LandmarkMesh) -> void:
	# Small (1550) & Large (1558) octagonal courtyard stair towers.
	for st: Array in [[-40.0, -8.6, 2.45, 21.0], [-27.0, 15.6, 3.05, 23.2]]:
		var sx: float = st[0]
		var sz: float = st[1]
		var sr: float = st[2]
		var sh: float = st[3]
		lm.frustum("Stone", Vector3(sx, FOUND, sz), sr + 0.2, sr + 0.1, 4.5 - FOUND, 8, PI / 8.0)
		lm.frustum("Wall", Vector3(sx, 4.5, sz), sr, sr * 0.97, sh - 4.5, 8, PI / 8.0)
		lm.lathe("Roof", Vector3(sx, sh, sz), PackedVector2Array([
			Vector2(sr * 1.2, 0.0), Vector2(sr * 0.5, 2.3), Vector2(0.10, 5.2),
		]), 8, 1.0, 1.0, PI / 8.0, false)
		LandmarkFrParts.ring_openings(lm, "Brick", "Glass", Vector3(sx, 6.2, sz), sr, 4, 0.75, 1.45, LandmarkFrParts.HEAD_FLAT, PI / 8.0)
		LandmarkFrParts.ring_openings(lm, "Brick", "Glass", Vector3(sx, 13.2, sz), sr, 4, 0.75, 1.45, LandmarkFrParts.HEAD_FLAT, PI / 8.0)
	# Inner courtyard Renaissance windows & main brick-framed gate arch.
	for yz: Array in [[-9.5, 1.0], [16.5, -1.0]]:
		var zz: float = yz[0]
		var sn := Vector3(0.0, 0.0, float(yz[1]))
		LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(-54.0, 11.0, zz), Vector3(-20.0, 11.0, zz),
			sn, 8, 1.4, 2.3, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
		LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(-54.0, 14.6, zz), Vector3(-20.0, 14.6, zz),
			sn, 8, 1.2, 1.8, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
	LandmarkFrParts.opening(lm, "Brick", "Dark", Vector3(-6.4, 0.2, 3.5), Vector3.RIGHT, 3.5, 5.2, LandmarkFrParts.HEAD_ROUND, 0.55, 0.30)
	# East gate tower of the main castle with brick gable/band & pyramid cap.
	LandmarkFrKit.rect(lm, "Stone", -16.0, -9.0, -16.5, -9.5, FOUND, STONE_H)
	LandmarkFrKit.tower(lm, "Wall", "Roof", -12.5, -13.0, 3.45, STONE_H, 25.0, 7.0)
	LandmarkFrParts.band(lm, "Brick", -16.0, -9.0, -16.5, -9.5, 24.5, 0.55, 0.22)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0.0, 0.0, 1.0)
		LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(-12.5, 21.4, -13.0) + fn * 3.45, fn, 0.95, 1.65,
			LandmarkFrParts.HEAD_FLAT, 0.16, 0.10)
	lm.spire("Dark", Vector3(-12.5, 32.0, -13.0), 0.18, 1.6)

static func _build_bailey(lm: LandmarkMesh) -> void:
	# Renaissance Bailey (Esilinna): red-tiled wings enclosing outer bailey yard.
	_wing(lm, -6.5, 50.5, -33.2, -21.0, 12.2, 5.2, "RoofRed", 1, false, "Brick")
	_wing(lm, -6.5, 47.5, 21.0, 31.6, 12.2, 5.2, "RoofRed", 1, false, "Brick")
	_wing(lm, 43.0, 55.2, -25.0, 11.5, 12.2, 5.2, "RoofRed", 0, false, "Brick")
	# Outer bailey cobble yard + east entrance cobbled forecourt.
	LandmarkFrKit.rect(lm, "Stone", -6.5, 43.0, -21.0, 21.0, FOUND, 0.45)
	LandmarkFrKit.rect(lm, "Stone", 55.2, 66.5, -22.0, -6.0, FOUND, 0.25)
	LandmarkFrParts.roof_trim(lm, "Dark", -6.5, 50.5, -33.2, -21.0, 12.2, 5.2, 0.5, 1, 0.25)
	LandmarkFrParts.roof_trim(lm, "Dark", -6.5, 47.5, 21.0, 31.6, 12.2, 5.2, 0.5, 1, 0.25)
	LandmarkFrParts.roof_trim(lm, "Dark", 43.0, 55.2, -25.0, 11.5, 12.2, 5.2, 0.5, 0, 0.25)
	for bz: Array in [[-33.2, -1.0, 50.5], [31.6, 1.0, 47.5], [-21.0, 1.0, 43.0], [21.0, -1.0, 43.0]]:
		var z2: float = bz[0]
		var n2 := Vector3(0.0, 0.0, float(bz[1]))
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-6.5, STONE_H, z2), Vector3(float(bz[2]), STONE_H, z2),
			n2, 12.2 - STONE_H, 10, 1, Vector2(1.1, 1.6), 0.7, 2.8, 0.2)
		LandmarkFrParts.openings(lm, "Brick", "Glass", Vector3(-4.0, 4.2, z2), Vector3(float(bz[2]) - 4.0, 4.2, z2), n2,
			8, 0.95, 1.6, LandmarkFrParts.HEAD_ROUND, 0.26, 0.12)
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(55.2, STONE_H, -25.0), Vector3(55.2, STONE_H, 11.5),
		Vector3.RIGHT, 12.2 - STONE_H, 7, 1, Vector2(1.1, 1.6), 0.7, 2.8, 0.2)
	# East entrance gatehouse with arched timber portal & warm gatehouse lantern glow.
	LandmarkFrParts.opening(lm, "Brick", "Timber", Vector3(55.22, 0.25, -14.0), Vector3.RIGHT, 3.8, 5.4,
		LandmarkFrParts.HEAD_ROUND, 0.58, 0.35)
	lm.box("WarmGlow", Vector3(55.35, 6.2, -14.0), Vector3(0.18, 0.45, 0.45), Basis(), 0.0)
	# Pentagonal north corner tower (-3.0, -29.0).
	lm.frustum("Stone", Vector3(-3.0, FOUND, -29.0), 4.6, 4.0, 10.0 - FOUND, 5)
	lm.frustum("Wall", Vector3(-3.0, 10.0, -29.0), 4.0, 3.9, 9.2, 5)
	lm.lathe("RoofRed", Vector3(-3.0, 19.2, -29.0), PackedVector2Array([Vector2(5.1, 0.0), Vector2(0.0, 7.6)]), 5, 1.0, 1.0, 0.0, false)
	LandmarkFrParts.ring_openings(lm, "Brick", "Glass", Vector3(-3.0, 13.6, -29.0), 3.4, 5, 0.85, 1.55, LandmarkFrParts.HEAD_FLAT, PI / 5.0)
	# Hexagonal south wing tower (8.0, 28.5).
	lm.frustum("Stone", Vector3(8.0, FOUND, 28.5), 4.1, 3.6, 9.6 - FOUND, 6)
	lm.frustum("Wall", Vector3(8.0, 9.6, 28.5), 3.6, 3.5, 7.6, 6)
	lm.lathe("RoofRed", Vector3(8.0, 17.2, 28.5), PackedVector2Array([Vector2(4.5, 0.0), Vector2(0.0, 6.6)]), 6, 1.0, 1.0, 0.0, false)
	LandmarkFrParts.ring_openings(lm, "Brick", "Glass", Vector3(8.0, 12.2, 28.5), 3.1, 6, 0.85, 1.55, LandmarkFrParts.HEAD_FLAT, PI / 6.0)
	# Square east tower (52.0, -6.0).
	LandmarkFrKit.rect(lm, "Stone", 48.3, 55.7, -9.7, -2.3, FOUND, STONE_H)
	LandmarkFrKit.tower(lm, "Wall", "RoofRed", 52.0, -6.0, 3.65, STONE_H, 19.2, 8.0)
	LandmarkFrParts.band(lm, "Brick", 48.3, 55.7, -9.7, -2.3, 18.7, 0.45, 0.16)
	for f2 in 4:
		var rb2 := Basis(Vector3.UP, PI * 0.5 * float(f2))
		var fn2: Vector3 = rb2 * Vector3(0.0, 0.0, 1.0)
		LandmarkFrParts.opening(lm, "Brick", "Glass", Vector3(52.0, 14.0, -6.0) + fn2 * 3.65, fn2, 0.95, 1.65, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10)
	# Massive Round Cannon Tower (Pyöreä torni) at SE corner (59.0, 21.0, r = 10.0 m).
	lm.frustum("Stone", Vector3(59.0, FOUND, 21.0), 11.0, 10.2, 2.8 - FOUND, 28)
	LandmarkFrKit.round_tower(lm, "Stone", "RoofRed", 59.0, 21.0, 10.0, 2.6, 13.2, 5.4, 28)
	for k in 8:
		var a := -PI * 0.6 + PI * 1.2 * float(k) / 7.0
		var gn := Vector3(cos(a), 0.0, sin(a))
		LandmarkFrParts.opening(lm, "Brick", "Dark", Vector3(59.0, 6.2, 21.0) + gn * 9.92, gn, 0.72, 0.72, LandmarkFrParts.HEAD_ROUND, 0.26, 0.16)

static func _wing(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, eave: float,
		rise: float, roof: String, ridge_x: int, hipped: bool = false, gable_key: String = "Brick") -> void:
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, FOUND, STONE_H)
	LandmarkFrKit.rect(lm, "Wall", x0, x1, z0, z1, STONE_H, eave)
	LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, z0, z1, eave - 0.45, 0.45)
	if hipped:
		LandmarkFrKit.hip(lm, roof, x0, x1, z0, z1, eave, rise, 0.5)
	else:
		LandmarkFrKit.gable(lm, roof, x0, x1, z0, z1, eave, rise, 0.5, gable_key, ridge_x)
