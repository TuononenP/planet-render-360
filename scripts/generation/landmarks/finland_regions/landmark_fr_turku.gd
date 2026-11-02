class_name LandmarkFrTurku
extends RefCounted

## The south-west Finland landmarks of the finland_regions batch in true
## metres, in the frame of the real plan (+X east, +Z south, turned onto
## the map by yaw_deg): Turku Castle on the Aura river mouth, the Naantali
## convent church and Rauma's Church of the Holy Cross. Plans follow the
## OpenStreetMap footprints.

## Turku Castle (Turun linna), founded in the 1280s: the medieval main
## castle in grey stone with its Renaissance upper floors added by Duke
## John (west, on the river mouth: a ring of wings round a long narrow
## courtyard, the five-storey west keep and the east gate block) and the
## Renaissance bailey beside it (east: a four-sided group of wings with a
## pentagonal, a hexagonal and a square tower and the round cannon tower).
const TURKU_TOP := 32.5
const TURKU_STONE_H := 9.0

static func turku_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkFrKit.palette(lm, "#8F8B80", "#D9D1BD", "#4A4642")
	lm.use("RoofRed", LandmarkMaterials.pbr("terracotta", "#85493A", 2.5))
	# Main castle: wings round the courtyard (x -70..-6.5, z -17..24).
	_wing(lm, -70.4, -6.5, -17.0, -9.5, 16.5, 6.5, "Roof", 1)
	_wing(lm, -70.4, -6.5, 16.5, 24.2, 16.5, 6.5, "Roof", 1)
	_wing(lm, -70.4, -56.0, -10.0, 17.0, 23.0, 9.5, "Roof", -1, true)
	_wing(lm, -18.5, -6.5, -17.0, 24.2, 20.0, 7.5, "Roof", 0)
	LandmarkFrKit.rect(lm, "Stone", -39.0, -36.0, -9.5, 16.5, 0.0, 12.0)
	LandmarkFrKit.rect(lm, "Stone", -56.0, -18.5, -9.5, 16.5, 0.0, 0.4)
	# Gate towers of the main castle with their pyramid caps.
	LandmarkFrKit.tower(lm, "Wall", "Roof", -12.5, -13.0, 3.0, TURKU_STONE_H, 24.0, 8.0)
	LandmarkFrKit.rect(lm, "Stone", -15.5, -9.5, -16.0, -10.0, 0.0, TURKU_STONE_H)
	# Bailey (x -6.5..52, z -33..31): wings of red roofs round its yard.
	_wing(lm, -6.5, 50.0, -33.0, -21.0, 12.0, 5.0, "RoofRed", 1)
	_wing(lm, -6.5, 47.0, 21.0, 31.5, 12.0, 5.0, "RoofRed", 1)
	_wing(lm, 43.0, 55.0, -25.0, 10.0, 12.0, 5.0, "RoofRed", 0)
	LandmarkFrKit.rect(lm, "Stone", -6.5, 43.0, -21.0, 21.0, 0.0, 0.4)
	# Pentagonal, hexagonal and square towers, round cannon tower.
	lm.frustum("Stone", Vector3(-3.0, 0, -29.0), 4.4, 4.0, 10.0, 5)
	lm.frustum("Wall", Vector3(-3.0, 10.0, -29.0), 4.0, 3.9, 9.0, 5)
	lm.lathe("RoofRed", Vector3(-3.0, 19.0, -29.0), PackedVector2Array([Vector2(5.0, 0), Vector2(0.0, 7.5)]), 5,
		1.0, 1.0, 0.0, false)
	lm.frustum("Stone", Vector3(8.0, 0, 28.5), 3.9, 3.6, 9.5, 6)
	lm.frustum("Wall", Vector3(8.0, 9.5, 28.5), 3.6, 3.5, 7.5, 6)
	lm.lathe("RoofRed", Vector3(8.0, 17.0, 28.5), PackedVector2Array([Vector2(4.4, 0), Vector2(0.0, 6.5)]), 6,
		1.0, 1.0, 0.0, false)
	LandmarkFrKit.tower(lm, "Wall", "RoofRed", 52.0, -6.0, 3.6, 0.0, 19.0, 8.0)
	LandmarkFrKit.round_tower(lm, "Stone", "RoofRed", 59.0, 21.0, 10.0, 0.0, 13.0, 5.0, 20)
	# Windows along the long fronts and the bailey yard.
	for z in [-17.1, 24.3]:
		var sgn := -1.0 if z < 0.0 else 1.0
		LandmarkFrKit.windows(lm, "Glass", Vector3(-38.0, 12.5, z + sgn * 0.02), Vector3.RIGHT, 12, 5.0,
			Vector3(1.3, 2.4, 0.2))
		LandmarkFrKit.windows(lm, "Glass", Vector3(-38.0, 5.5, z + sgn * 0.02), Vector3.RIGHT, 7, 8.0,
			Vector3(0.7, 1.6, 0.2))
	for z in [-33.1, 31.6]:
		var sgn2 := -1.0 if z < 0.0 else 1.0
		LandmarkFrKit.windows(lm, "Glass", Vector3(21.0, 7.0, z + sgn2 * 0.02), Vector3.RIGHT, 9, 5.0,
			Vector3(1.2, 2.2, 0.2))
	lm.commit(model)

## Stone base up to TURKU_STONE_H, whitewashed storeys above, then the roof
## (gabled with ridge along X when ridge_x = 1, along Z when 0; hipped).
static func _wing(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, eave: float,
		rise: float, roof: String, ridge_x: int, hipped: bool = false) -> void:
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, 0.0, TURKU_STONE_H)
	LandmarkFrKit.rect(lm, "Wall", x0, x1, z0, z1, TURKU_STONE_H, eave)
	if hipped:
		LandmarkFrKit.hip(lm, roof, x0, x1, z0, z1, eave, rise, 0.5)
	else:
		LandmarkFrKit.gable(lm, roof, x0, x1, z0, z1, eave, rise, 0.5, "Wall", ridge_x)

## Naantali Convent Church (Naantalin kirkko), 1460s-1480s, the Bridgettine
## convent church: a stone hall church under one steep shingled roof, the
## Baroque bell tower (1797) built against the west gable with four clock
## faces under a bell-shaped copper cupola, a lantern and the gilded vane.
## Nave along X, tower at the west (-X) end.
const NAANTALI_TOP := 47.1

static func naantali(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkFrKit.palette(lm, "#A19D94", "#D7D3C6", "#5A5148", "#EDE8DA")
	lm.use("Roof", LandmarkFrKit.shingle("#574E45"))
	lm.use("Copper", LandmarkFrKit.copper("#5E8F7C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Hall, plinth and the single steep roof (eaves 11.5, ridge 26 m).
	LandmarkFrKit.rect(lm, "Stone", -18.0, 29.8, -15.2, 15.2, 0.0, 1.4)
	LandmarkFrKit.rect(lm, "Wall", -18.0, 29.5, -14.9, 14.9, 1.4, 11.5)
	LandmarkFrKit.gable(lm, "Roof", -18.0, 29.5, -14.9, 14.9, 11.5, 14.5, 0.8, "Wall", 1)
	for sz in [-1.0, 1.0]:
		for k in 8:
			var x := -12.0 + 5.9 * float(k)
			lm.box("Stone", Vector3(x, 6.5, sz * 15.3), Vector3(1.3, 10.2, 0.9))
			if k < 7:
				lm.box("Glass", Vector3(x + 2.95, 7.0, sz * 14.95), Vector3(1.6, 5.6, 0.15))
	# East gable: three lancet windows and a blind niche above.
	for k in 3:
		lm.box("Glass", Vector3(29.55, 6.5, -4.0 + 4.0 * float(k)), Vector3(0.15, 6.0, 1.4))
	lm.box("Stone", Vector3(29.6, 17.0, 0), Vector3(0.2, 3.0, 1.2))
	# Bell tower on the west gable: base to above the ridge, clock stage,
	# bell-shaped cupola, lantern, small cupola, ball and vane.
	var tx := -24.0
	LandmarkFrKit.rect(lm, "Wall", -30.0, -18.0, -8.0, 8.0, 0.0, 24.5)
	LandmarkFrKit.rect(lm, "Trim", -30.4, -17.6, -8.4, 8.4, 24.0, 24.9)
	for k in 2:
		lm.box("Glass", Vector3(-30.05, 11.0 + 6.5 * float(k), 0), Vector3(0.15, 3.4, 1.5))
	LandmarkFrKit.rect(lm, "Wall", tx - 4.6, tx + 4.6, -4.6, 4.6, 24.9, 33.0)
	LandmarkFrKit.clocks(lm, "Gilt", "Trim", tx, 0.0, 4.6, 29.5, 1.7)
	LandmarkFrKit.rect(lm, "Trim", tx - 5.0, tx + 5.0, -5.0, 5.0, 32.6, 33.4)
	lm.lathe("Copper", Vector3(tx, 33.4, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(5.0, 0.9),
		Vector2(4.2, 2.6), Vector2(2.7, 4.2), Vector2(2.0, 5.0)]), 12)
	lm.frustum("Wall", Vector3(tx, 38.4, 0), 1.8, 1.7, 3.2, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(tx, 41.6, 0), PackedVector2Array([Vector2(2.3, 0), Vector2(1.5, 1.2),
		Vector2(0.4, 3.4)]), 8)
	lm.lathe("Gilt", Vector3(tx, 44.9, 0), LandmarkFrKit.ball(0.5), 8)
	lm.box("Gilt", Vector3(tx, 46.0, 0), Vector3(0.14, 2.2, 0.14))
	lm.commit(model)

## Church of the Holy Cross, Rauma (Pyhan Ristin kirkko), c. 1515-1520: the
## Franciscan friary's grey granite church in Old Rauma, a low two-aisle
## nave (about 24 x 19 m) under a high shingled roof, the choir to the
## east, the south porch and sacristy, and the white steeple (1816) built
## from the stones of the Holy Trinity ruin at the west end.
## Nave along X, tower at the west (-X) end.
const RAUMA_TOP := 38.5

static func rauma(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkFrKit.palette(lm, "#8C897F", "#B9B5A9", "#4A4138", "#EAE6DA")
	lm.use("Roof", LandmarkFrKit.shingle("#4B4239"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave, choir, sacristy and south porch in grey stone with high gables.
	LandmarkFrKit.house(lm, "Stone", "Roof", -14.2, 11.5, -16.3, 4.7, 0.0, 9.0, 9.5, 0.7, 1)
	LandmarkFrKit.house(lm, "Stone", "Roof", 11.5, 22.3, -12.2, 4.5, 0.0, 8.2, 6.8, 0.6, 1)
	LandmarkFrKit.house(lm, "Stone", "Roof", 11.6, 19.9, 4.5, 16.3, 0.0, 5.6, 4.2, 0.5, 0)
	LandmarkFrKit.house(lm, "Stone", "Roof", -7.7, -1.2, 4.7, 10.4, 0.0, 5.2, 3.6, 0.4, 0)
	LandmarkFrKit.house(lm, "Stone", "Roof", 13.3, 18.2, -15.5, -12.2, 0.0, 4.6, 3.0, 0.3, 0)
	for k in 5:
		lm.box("Glass", Vector3(-9.0 + 4.6 * float(k), 5.0, 4.75), Vector3(1.3, 4.2, 0.15))
		lm.box("Glass", Vector3(-9.0 + 4.6 * float(k), 5.0, -16.35), Vector3(1.3, 4.2, 0.15))
	lm.box("Glass", Vector3(22.35, 4.6, -3.8), Vector3(0.15, 4.4, 1.3))
	lm.box("Trim", Vector3(22.4, 12.0, -3.8), Vector3(0.2, 2.4, 2.4))
	# Tower: granite base, whitewashed clock stage and belfry, octagonal
	# lantern, tall slim steeple, ball and cross.
	var cx := -18.3
	var cz := -7.1
	LandmarkFrKit.tower(lm, "Stone", "Stone", cx, cz, 4.1, 0.0, 14.0, 0.0)
	LandmarkFrKit.rect(lm, "Trim", cx - 4.4, cx + 4.4, cz - 4.4, cz + 4.4, 13.6, 14.4)
	LandmarkFrKit.tower(lm, "Trim", "Trim", cx, cz, 3.5, 14.4, 21.5, 0.0)
	LandmarkFrKit.clocks(lm, "Gilt", "Wall", cx, cz, 3.5, 18.0, 1.4)
	LandmarkFrKit.tower(lm, "Trim", "Trim", cx, cz, 3.1, 21.5, 26.0, 0.0)
	LandmarkFrKit.windows(lm, "Glass", Vector3(cx, 23.8, cz + 3.15), Vector3.RIGHT, 1, 1.0, Vector3(1.6, 2.6, 0.15))
	LandmarkFrKit.windows(lm, "Glass", Vector3(cx, 23.8, cz - 3.15), Vector3.RIGHT, 1, 1.0, Vector3(1.6, 2.6, 0.15))
	lm.box("Glass", Vector3(cx + 3.15, 23.8, cz), Vector3(0.15, 2.6, 1.6))
	lm.box("Glass", Vector3(cx - 3.15, 23.8, cz), Vector3(0.15, 2.6, 1.6))
	LandmarkFrKit.rect(lm, "Trim", cx - 3.5, cx + 3.5, cz - 3.5, cz + 3.5, 25.8, 26.5)
	LandmarkFrKit.lantern(lm, "Trim", "Trim", cx, cz, 2.6, 26.5, 4.0, 6.0)
	lm.lathe("Gilt", Vector3(cx, 36.8, cz), LandmarkFrKit.ball(0.4), 8)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(cx, 37.5, cz), 1.0)
	lm.commit(model)
