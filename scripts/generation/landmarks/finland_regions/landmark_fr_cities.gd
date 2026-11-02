class_name LandmarkFrCities
extends RefCounted

## Landmarks of the Finnish towns Kuopio, Oulu and Vaasa in true metres,
## in the frame of the real plan (+X east, +Z south, turned onto the map
## by yaw_deg): Puijo Tower, Kuopio Cathedral, Oulu Cathedral and the
## Vaasa Church. Plans follow the OpenStreetMap footprints.

## Puijo Tower (Puijon torni), Kuopio, 1963: the 75 m concrete tower on
## the 232 m Puijo hill with the revolving restaurant and observation
## decks in its head and the mast above. y = 0 is the base platform.
const PUIJO_TOP := 75.0

static func puijo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C6BE", 4.0))
	lm.use("Head", LandmarkMaterials.paint("#E6E3DA", 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#26323A"))
	lm.use("Mast", LandmarkMaterials.paint("#C4C7C8", 0.5, 0.5))
	lm.use("Lit", LandmarkMaterials.lit("#FF9B3D", 0.8))
	lm.frustum("Concrete", Vector3(0, -3.0, 0), 6.3, 6.0, 8.5, 12, 0.3)
	lm.lathe("Concrete", Vector3(0, 5.0, 0), PackedVector2Array([Vector2(3.7, 0), Vector2(3.3, 22.0),
		Vector2(3.1, 44.0)]), 16)
	lm.lathe("Head", Vector3(0, 49.0, 0), PackedVector2Array([Vector2(3.1, 0), Vector2(4.4, 1.2),
		Vector2(7.0, 3.4), Vector2(8.3, 5.4), Vector2(8.6, 7.4)]), 20)
	lm.frustum("Glass", Vector3(0, 56.4, 0), 8.6, 8.6, 4.2, 20)
	lm.lathe("Head", Vector3(0, 60.6, 0), PackedVector2Array([Vector2(8.9, 0), Vector2(8.7, 0.8),
		Vector2(5.0, 2.6), Vector2(2.4, 3.8)]), 20)
	lm.lathe("Mast", Vector3(0, 64.4, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.0, 4.0),
		Vector2(0.6, 7.5), Vector2(0.25, 10.6)]), 10)
	lm.frustum("Lit", Vector3(0, 66.4, 0), 1.2, 1.0, 4.0, 8)
	lm.commit(model)

## Kuopio Cathedral (Kuopion tuomiokirkko), Pehr Granstedt, 1815: the
## Neoclassical cross-plan church in cream stucco with white trim, hipped
## transept ends with small Tuscan porches and the square bell tower
## (35.5 m to the roof) at the east end, its green cupola over a lantern.
## The altar end is west (+Z in this frame), the tower east (-Z).
const KUOPIO_TOP := 35.5

static func kuopio_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E1D6B0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1ECDF", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4B5054", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#5E8F7C"))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var eave := 11.0
	LandmarkFrKit.rect(lm, "Trim", -7.9, 9.1, -24.5, 30.8, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Wall", -7.6, 8.8, -24.2, 30.5, 0.0, eave)
	LandmarkFrKit.gable(lm, "Roof", -7.6, 8.8, -24.2, 30.5, eave, 6.5, 0.6, "Wall", 0)
	LandmarkFrKit.rect(lm, "Wall", -26.9, 28.0, -4.9, 11.6, 0.0, eave)
	LandmarkFrKit.gable(lm, "Roof", -26.9, 28.0, -4.9, 11.6, eave, 6.5, 0.6, "Wall", 1)
	# Porches of the transept ends: four columns and a pediment each.
	for sx in [-1.0, 1.0]:
		var px: float = sx * 29.4
		LandmarkFrKit.rect(lm, "Trim", px - 1.6, px + 1.6, 0.6, 7.2, 0.0, 0.6)
		for k in 4:
			lm.frustum("Trim", Vector3(px + sx * 1.0, 0.6, 1.4 + 1.65 * float(k)), 0.38, 0.32, 7.6, 10)
		lm.box("Trim", Vector3(px, 8.5, 3.9), Vector3(3.4, 0.9, 6.6))
		LandmarkFrKit.gable(lm, "Trim", px - 1.7, px + 1.7, 0.6, 7.2, 8.9, 1.5, 0.2, "Trim", 1)
	# Arched windows along the nave and transept fronts.
	for sx in [-1.0, 1.0]:
		for z in [14.5, 20.5, 26.5, -9.5, -15.5, -21.0]:
			lm.box("Glass", Vector3(8.0 * sx + (0.85 if sx > 0.0 else -0.45), 6.2, z), Vector3(0.15, 4.6, 1.5))
	for k in 3:
		lm.box("Glass", Vector3(-3.5 + 3.5 * float(k), 6.2, 30.55), Vector3(1.3, 4.6, 0.15))
		lm.box("Glass", Vector3(-20.0 + 5.0 * float(k), 6.2, -4.95), Vector3(1.5, 4.6, 0.15))
		lm.box("Glass", Vector3(-20.0 + 5.0 * float(k), 6.2, 11.65), Vector3(1.5, 4.6, 0.15))
		lm.box("Glass", Vector3(9.5 + 5.0 * float(k), 6.2, 11.65), Vector3(1.5, 4.6, 0.15))
		lm.box("Glass", Vector3(9.5 + 5.0 * float(k), 6.2, -4.95), Vector3(1.5, 4.6, 0.15))
	# Bell tower: stucco shaft with cornice, belfry with clocks, lantern,
	# green cupola, ball and cross.
	var tx := 0.45
	var tz := -27.35
	LandmarkFrKit.rect(lm, "Wall", tx - 4.65, tx + 4.65, -30.5, -24.2, 0.0, 22.0)
	LandmarkFrKit.rect(lm, "Trim", tx - 5.0, tx + 5.0, -30.9, -23.9, 21.6, 22.6)
	LandmarkFrKit.rect(lm, "Wall", tx - 3.1, tx + 3.1, tz - 3.1, tz + 3.1, 22.6, 29.4)
	LandmarkFrKit.clocks(lm, "Gilt", "Trim", tx, tz, 3.1, 26.0, 1.2)
	LandmarkFrKit.rect(lm, "Trim", tx - 3.5, tx + 3.5, tz - 3.5, tz + 3.5, 29.0, 29.8)
	lm.frustum("Trim", Vector3(tx, 29.8, tz), 2.4, 2.2, 2.6, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(tx, 32.4, tz), PackedVector2Array([Vector2(2.6, 0), Vector2(2.4, 0.6),
		Vector2(1.3, 1.5), Vector2(0.15, 2.0)]), 8, 1.0, 1.0, PI / 8.0)
	lm.lathe("Gilt", Vector3(tx, 34.3, tz), LandmarkFrKit.ball(0.3), 8)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(tx, 34.7, tz), 0.8)
	lm.box("Glass", Vector3(tx, 4.5, -30.55), Vector3(2.4, 5.0, 0.15))
	lm.commit(model)

## Oulu Cathedral (Oulun tuomiokirkko), Carl Ludvig Engel, 1832: the
## Neoclassical Greek-cross church in cream stucco whose old stone walls
## carry the green copper central dome, with the tall square bell tower
## (56.5 m to the cross, completed 1845) at the west end.
## Tower at the west (-X) end of this frame.
const OULU_TOP := 56.5

static func oulu_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6DFC8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F3EFE3", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5155", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#5F9180"))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var eave := 12.0
	# Greek cross: central square with four arms and the lower side annex.
	LandmarkFrKit.rect(lm, "Wall", -4.1, 14.3, -10.3, 8.9, 0.0, eave + 1.0)
	LandmarkFrKit.rect(lm, "Wall", -21.8, -4.1, -10.3, 8.9, 0.0, eave)
	LandmarkFrKit.rect(lm, "Wall", 14.3, 32.0, -10.3, 8.9, 0.0, eave)
	LandmarkFrKit.rect(lm, "Wall", -4.1, 14.5, -21.0, -10.3, 0.0, eave)
	LandmarkFrKit.rect(lm, "Wall", -4.1, 14.3, 8.9, 20.9, 0.0, eave)
	LandmarkFrKit.rect(lm, "Wall", 14.5, 23.1, -17.8, -10.3, 0.0, 8.0)
	LandmarkFrKit.gable(lm, "Roof", -21.8, -4.1, -10.3, 8.9, eave, 5.0, 0.6, "Wall", 1)
	LandmarkFrKit.gable(lm, "Roof", 14.3, 32.0, -10.3, 8.9, eave, 5.0, 0.6, "Wall", 1)
	LandmarkFrKit.gable(lm, "Roof", -4.1, 14.5, -21.0, -10.3, eave, 5.0, 0.6, "Wall", 0)
	LandmarkFrKit.gable(lm, "Roof", -4.1, 14.3, 8.9, 20.9, eave, 5.0, 0.6, "Wall", 0)
	LandmarkFrKit.gable(lm, "Roof", 14.5, 23.1, -17.8, -10.3, 8.0, 3.0, 0.4, "Wall", 1)
	LandmarkFrKit.rect(lm, "Trim", -4.4, 14.6, -10.6, 9.2, eave + 0.6, eave + 1.4)
	# Portico columns on the east and south and north gables.
	for k in 4:
		lm.frustum("Trim", Vector3(32.4, 0, -6.0 + 3.9 * float(k)), 0.5, 0.42, 10.0, 12)
	lm.box("Trim", Vector3(32.0, 10.5, 0), Vector3(1.4, 1.0, 19.0))
	lm.gable("Trim", Vector3(32.0, 11.0, 0), 19.0, 1.4, 2.6, Basis(Vector3.UP, PI * 0.5), 0.0, "Trim")
	# Windows in the arm walls.
	for k in 3:
		lm.box("Glass", Vector3(-4.0 + 5.0 * float(k), 6.5, 20.95), Vector3(1.5, 5.4, 0.15))
		lm.box("Glass", Vector3(-4.0 + 5.0 * float(k), 6.5, -21.05), Vector3(1.5, 5.4, 0.15))
		lm.box("Glass", Vector3(-16.0 + 4.5 * float(k), 6.5, 8.95), Vector3(1.5, 5.4, 0.15))
		lm.box("Glass", Vector3(-16.0 + 4.5 * float(k), 6.5, -10.35), Vector3(1.5, 5.4, 0.15))
	# Central drum and the green dome with its lantern and cross.
	var c := Vector3(5.1, eave + 1.4, -0.7)
	lm.frustum("Wall", c, 8.6, 8.6, 4.4, 24)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		lm.box("Glass", c + Vector3(cos(a) * 8.65, 2.2, sin(a) * 8.65), Vector3(0.15, 2.4, 1.6),
			Basis(Vector3.UP, -a + PI * 0.5))
	lm.frustum("Trim", c + Vector3(0, 4.4, 0), 9.2, 9.0, 0.8, 24)
	lm.lathe("Copper", c + Vector3(0, 5.2, 0), LandmarkFrKit.dome(8.9, 7.4), 24)
	lm.frustum("Trim", c + Vector3(0, 12.6, 0), 1.9, 1.9, 2.4, 10)
	lm.lathe("Copper", c + Vector3(0, 15.0, 0), LandmarkFrKit.dome(2.2, 2.4), 10)
	LandmarkFrKit.cross(lm, "Gilt", c + Vector3(0, 17.4, 0), 1.8)
	# West bell tower on the 10 m block: shaft, belfry, lantern, copper spire.
	var tx := -27.0
	LandmarkFrKit.rect(lm, "Wall", -32.2, -21.8, -5.2, 5.2, 0.0, 27.0)
	LandmarkFrKit.rect(lm, "Trim", -32.6, -21.4, -5.6, 5.6, 26.4, 27.6)
	LandmarkFrKit.windows(lm, "Glass", Vector3(tx, 11.0, -5.25), Vector3.RIGHT, 2, 4.0, Vector3(1.4, 4.0, 0.15))
	LandmarkFrKit.windows(lm, "Glass", Vector3(tx, 11.0, 5.25), Vector3.RIGHT, 2, 4.0, Vector3(1.4, 4.0, 0.15))
	lm.box("Glass", Vector3(-32.25, 5.0, 0), Vector3(0.15, 7.0, 3.0))
	LandmarkFrKit.rect(lm, "Wall", tx - 3.8, tx + 3.8, -3.8, 3.8, 27.6, 36.0)
	LandmarkFrKit.clocks(lm, "Gilt", "Trim", tx, 0.0, 3.8, 32.0, 1.5)
	LandmarkFrKit.rect(lm, "Trim", tx - 4.2, tx + 4.2, -4.2, 4.2, 35.6, 36.6)
	lm.frustum("Wall", Vector3(tx, 36.6, 0), 3.0, 2.8, 3.6, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(tx, 40.2, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(3.0, 1.0),
		Vector2(1.8, 5.0), Vector2(0.9, 9.0), Vector2(0.12, 13.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", Vector3(tx, 53.2, 0), LandmarkFrKit.ball(0.45), 8)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(tx, 54.0, 0), 2.5)
	lm.commit(model)

## Vaasa Church, the Holy Trinity Church (Vaasan kirkko), Carl Axel
## Setterberg, 1869: the long three-nave red-brick church in English Gothic
## with buttressed walls and pointed windows under a steep slate roof,
## the polygonal apse at the east and the west tower with its tall slate
## spire. Tower at the west (-X) end, apse east (+X).
const VAASA_TOP := 49.3

static func vaasa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A0503A", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C9C2B2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5054", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave and aisles, porches and chapels.
	LandmarkFrKit.rect(lm, "Stone", -19.4, 23.6, -13.9, 13.2, 0.0, 1.0)
	LandmarkFrKit.house(lm, "Brick", "Roof", -19.1, 23.4, -11.1, 11.0, 0.0, 11.0, 8.0, 0.6, 1)
	LandmarkFrKit.house(lm, "Brick", "Roof", -1.4, 5.2, -14.8, 14.8, 0.0, 10.0, 4.2, 0.4, 0)
	LandmarkFrKit.house(lm, "Brick", "Roof", 13.1, 23.4, -13.5, 12.8, 0.0, 8.0, 3.0, 0.3, 0)
	# Polygonal apse with a conical roof.
	lm.frustum("Brick", Vector3(21.5, 0, 0), 6.4, 6.2, 11.0, 6)
	lm.lathe("Roof", Vector3(21.5, 11.0, 0), PackedVector2Array([Vector2(7.2, 0), Vector2(0.0, 8.0)]), 6,
		1.0, 1.0, 0.0, false)
	# Buttresses and pointed windows along the long fronts.
	for sz in [-1.0, 1.0]:
		for k in 7:
			var x := -15.0 + 5.2 * float(k)
			if absf(x - 1.9) < 4.6:
				continue
			lm.box("Stone", Vector3(x, 5.5, sz * 11.3), Vector3(0.9, 11.0, 0.8))
			lm.box("Glass", Vector3(x + 2.6, 6.0, sz * 11.1), Vector3(1.5, 5.4, 0.15))
	for k in 3:
		lm.box("Glass", Vector3(-5.0 + 5.0 * float(k), 5.5, 14.85), Vector3(1.4, 5.0, 0.15))
	# West tower: brick shaft, stone string courses, louvred belfry, corner
	# pinnacles and the tall slate spire with a gilt cross.
	var tx := -23.45
	LandmarkFrKit.rect(lm, "Brick", tx - 4.45, tx + 4.45, -4.45, 4.45, 0.0, 30.0)
	for y in [10.0, 20.0, 29.4]:
		LandmarkFrKit.rect(lm, "Stone", tx - 4.7, tx + 4.7, -4.7, 4.7, y, y + 0.6)
	lm.box("Glass", Vector3(tx - 4.5, 5.0, 0), Vector3(0.15, 6.0, 2.4))
	LandmarkFrKit.ring_windows(lm, "Glass", tx, 0.0, 4.5, 16.0, 1, 1.0, Vector3(1.2, 4.0, 0.15))
	LandmarkFrKit.rect(lm, "Brick", tx - 3.9, tx + 3.9, -3.9, 3.9, 30.0, 38.0)
	LandmarkFrKit.ring_windows(lm, "Glass", tx, 0.0, 3.95, 34.0, 1, 1.0, Vector3(1.6, 4.6, 0.15))
	LandmarkFrKit.rect(lm, "Stone", tx - 4.3, tx + 4.3, -4.3, 4.3, 37.6, 38.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(tx + sx * 3.8, 39.6, sz * 3.8), Vector3(0.9, 2.4, 0.9))
			lm.spire("Roof", Vector3(tx + sx * 3.8, 40.8, sz * 3.8), 0.6, 3.2)
	lm.lathe("Roof", Vector3(tx, 38.4, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(3.6, 3.0),
		Vector2(1.3, 8.4), Vector2(0.14, 10.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Gilt", Vector3(tx, 48.5, 0), Vector3(0.14, 1.6, 0.14))
	lm.box("Gilt", Vector3(tx, 48.9, 0), Vector3(0.8, 0.14, 0.14))
	lm.commit(model)
