class_name LandmarkMiBiltmore
extends RefCounted

## Biltmore Hotel, Coral Gables — MI-10 Centre F. Schultze & Weaver (1926).
## Footprint 152 x 106.7 m (X x Z), height 96.0 m (315 ft Giralda tower).
## Plan: front block along -Z carrying the tower, two wings running south (+Z) that frame
## the monumental lagoon pool (T-shaped), coral-stone pergolas, loggias and royal palms.
##   - Wings y 0..24 m, warm coral-ochre stucco, terracotta barrel-tile roofs.
##   - Giralda: shaft y 24..58, LandmarkMiKit.giralda_tier belfries to 84, copper cupola, finial 96.

const HEIGHT_M := 96.0
const FRONT_Z := -36.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#E6C28F", 3.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCBA8", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B4573A", 2.2))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#5E8E79", 2.5))
	lm.use("Window", LandmarkMaterials.glass("#26313A"))
	lm.use("Water", LandmarkMaterials.pool_water("#35A6B8"))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#E4D9C0", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	_build_wings(lm)
	_build_pool(lm)
	_build_tower(lm)
	_build_palms(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.84, 0.54)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 1.5, -10.0), Vector3(0.0, 50.0, FRONT_Z), 70.0, 1.3, 90.0, warm],
		[Vector3(30.0, 1.5, -10.0), Vector3(0.0, 50.0, FRONT_Z), 70.0, 1.3, 90.0, warm],
		[Vector3(0.0, 1.5, 10.0), Vector3(0.0, 70.0, FRONT_Z), 70.0, 1.3, 90.0, warm],
		[Vector3(0.0, 24.5, FRONT_Z + 8.0), Vector3(0.0, 80.0, FRONT_Z), 50.0, 1.3, 60.0, warm],
	])

static func _hip(lm: LandmarkMesh, cx: float, cz: float, hx: float, hz: float, eaves: float, ridge: float, depth: float) -> void:
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx - hx, cz - hz), Vector2(cx + hx, cz - hz), eaves, ridge, depth, Vector2(0.0, -1.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx - hx, cz + hz), Vector2(cx + hx, cz + hz), eaves, ridge, depth, Vector2(0.0, 1.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx - hx, cz - hz), Vector2(cx - hx, cz + hz), eaves, ridge, depth, Vector2(-1.0, 0.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx + hx, cz - hz), Vector2(cx + hx, cz + hz), eaves, ridge, depth, Vector2(1.0, 0.0))

static func _wing(lm: LandmarkMesh, cx: float, cz: float, sx: float, sz: float, ground_arches: bool) -> void:
	lm.box("Stone", Vector3(cx, 3.0, cz), Vector3(sx + 0.8, 6.0, sz + 0.8))
	lm.box("Stucco", Vector3(cx, 14.5, cz), Vector3(sx, 17.0, sz))
	lm.box("Stone", Vector3(cx, 23.2, cz), Vector3(sx + 1.2, 0.9, sz + 1.2))
	lm.box("Stone", Vector3(cx, 6.2, cz), Vector3(sx + 0.9, 0.5, sz + 0.9))
	_hip(lm, cx, cz, sx * 0.5 - 1.5, sz * 0.5 - 1.5, 23.65, 27.0, 4.0)
	lm.box("Tile", Vector3(cx, 26.4, cz), Vector3(maxf(sx - 8.0, 2.0), 1.6, maxf(sz - 8.0, 2.0)))
	# Window bays on the long faces, 4 storeys
	var long_x := sx > sz
	var n := int((sx if long_x else sz) / 4.5) - 1
	var span := (sx if long_x else sz)
	for i: int in n:
		var o := -span * 0.5 + 3.0 + float(i) * ((span - 6.0) / float(maxi(n - 1, 1)))
		for wy: float in [9.0, 13.2, 17.4, 21.0]:
			for side: float in [-1.0, 1.0]:
				if long_x:
					lm.box("Window", Vector3(cx + o, wy, cz + side * (sz * 0.5 + 0.03)), Vector3(1.4, 2.2, 0.2), Basis(), 0.0)
				else:
					lm.box("Window", Vector3(cx + side * (sx * 0.5 + 0.03), wy, cz + o), Vector3(0.2, 2.2, 1.4), Basis(), 0.0)
		if ground_arches:
			var arch_pos := Vector3(cx + o, 3.2, cz + (sz * 0.5 + 0.04)) if long_x else Vector3(cx + (sx * 0.5 + 0.04), 3.2, cz + o)
			var dim := Vector3(2.4, 4.0, 0.2) if long_x else Vector3(0.2, 4.0, 2.4)
			lm.box("Window", arch_pos, dim, Basis(), 0.0)

static func _build_wings(lm: LandmarkMesh) -> void:
	# Front block (north) along X with the tower in its centre
	_wing(lm, 0.0, FRONT_Z, 152.0, 26.0, true)
	# Two long wings extending south around the pool
	for sx: float in [-1.0, 1.0]:
		_wing(lm, sx * 64.0, FRONT_Z + 13.0 + 24.0, 24.0, 48.0, true)
	# Arched colonnade (loggia) fronting the south side of the front block
	for i: int in 9:
		var x := -28.0 + float(i) * 7.0
		lm.box("Stone", Vector3(x, 3.6, FRONT_Z + 14.0), Vector3(1.4, 7.2, 1.4))
		lm.box("Window", Vector3(x + 3.5, 3.4, FRONT_Z + 13.1), Vector3(4.4, 5.6, 0.2), Basis(), 0.0)
	lm.box("Stone", Vector3(0.0, 7.4, FRONT_Z + 14.0), Vector3(57.0, 0.8, 2.0))

static func _build_pool(lm: LandmarkMesh) -> void:
	# Monumental T / lagoon pool south of the front block, between the wings
	lm.box("Deck", Vector3(0.0, 0.0, 4.0), Vector3(104.0, 0.4, 76.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0.0, 0.1, -2.0), Vector3(64.0, 0.4, 24.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0.0, 0.1, 18.0), Vector3(28.0, 0.4, 28.0), Basis(), 0.0)
	lm.box("Water", Vector3(0.0, 0.25, -2.0), Vector3(62.0, 0.2, 22.0), Basis(), 0.0)
	lm.box("Water", Vector3(0.0, 0.25, 18.0), Vector3(26.0, 0.2, 26.0), Basis(), 0.0)
	# Coral-stone pergolas on each side with loggia posts and beams
	for sx: float in [-1.0, 1.0]:
		var px := sx * 40.0
		for i: int in 6:
			var z := 8.0 + float(i) * 6.0
			lm.box("Stone", Vector3(px, 2.1, z), Vector3(0.9, 4.2, 0.9))
			lm.box("Stone", Vector3(px + sx * 5.0, 2.1, z), Vector3(0.9, 4.2, 0.9))
			lm.beam("Stone", Vector3(px, 4.4, z), Vector3(px + sx * 5.0, 4.4, z), 0.5, 0.4)
		lm.beam("Stone", Vector3(px, 4.8, 8.0), Vector3(px, 4.8, 38.0), 0.5, 0.5)
		lm.beam("Stone", Vector3(px + sx * 5.0, 4.8, 8.0), Vector3(px + sx * 5.0, 4.8, 38.0), 0.5, 0.5)
	# Diving platform and lagoon-side cabanas
	lm.box("Stone", Vector3(0.0, 2.0, 28.0), Vector3(3.0, 4.0, 3.0))
	lm.box("Stone", Vector3(0.0, 4.2, 28.0), Vector3(4.0, 0.4, 4.0))

static func _build_tower(lm: LandmarkMesh) -> void:
	var c2 := Vector2(0.0, FRONT_Z)
	# Central tower shaft y 24..58 with corner pilasters and panelled bays
	lm.box("Stucco", Vector3(0.0, 41.0, FRONT_Z), Vector3(14.0, 34.0, 14.0), Basis(), 0.04)
	lm.box("Stone", Vector3(0.0, 24.6, FRONT_Z), Vector3(15.4, 1.2, 15.4))
	for side: int in 4:
		var ang := float(side) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var basis := Basis(t3, Vector3.UP, n3)
		for wy: float in [30.0, 38.0, 46.0, 53.0]:
			lm.box("Window", Vector3(0.0, wy, FRONT_Z) + n3 * 7.03, Vector3(2.4, 3.6, 0.2), basis, 0.0)
			lm.box("Stone", Vector3(0.0, wy + 2.1, FRONT_Z) + n3 * 7.1, Vector3(3.2, 0.4, 0.35), basis, 0.0)
		for sg: float in [-1.0, 1.0]:
			lm.box("Stone", Vector3(0.0, 41.0, FRONT_Z) + n3 * 7.0 + t3 * (sg * 6.2), Vector3(1.6, 33.0, 0.5), basis, 0.0)
	# Belfry tiers via the shared Giralda kit
	LandmarkMiKit.giralda_tier(lm, "Stucco", "Stone", "Window", c2, 58.0, 12.0, 11.6, false, 2, true)
	LandmarkMiKit.giralda_tier(lm, "Stucco", "Stone", "Window", c2, 70.0, 9.0, 8.4, true, 1, false)
	LandmarkMiKit.giralda_tier(lm, "Stucco", "Stone", "Window", c2, 79.0, 5.0, 5.4, true, 1, false)
	# Copper cupola, lantern and finial reaching exactly 96.0 m
	lm.lathe("Copper", Vector3(0.0, 84.2, FRONT_Z), PackedVector2Array([
		Vector2(2.6, 0.0), Vector2(2.5, 1.0), Vector2(2.0, 2.6), Vector2(1.2, 4.0), Vector2(0.5, 5.0), Vector2(0.3, 5.6)]), 16)
	lm.frustum("Stone", Vector3(0.0, 89.8, FRONT_Z), 0.5, 0.35, 1.8, 8)
	lm.beam("Gold", Vector3(0.0, 91.6, FRONT_Z), Vector3(0.0, HEIGHT_M, FRONT_Z), 0.16, 0.16, Vector3.RIGHT, true)
	lm.lathe("Gold", Vector3(0.0, 92.6, FRONT_Z), PackedVector2Array([
		Vector2(0.05, 0.0), Vector2(0.4, 0.4), Vector2(0.05, 0.8)]), 10)

static func _build_palms(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		for i: int in 5:
			var z := 10.0 + float(i) * 8.0
			LandmarkMiKit.royal_palm(lm, "Stone", "Copper", Vector3(sx * 30.0, 0.0, z), 14.0, float(i) * 0.7)
	for i: int in 5:
		LandmarkMiKit.royal_palm(lm, "Stone", "Copper", Vector3(-24.0 + float(i) * 12.0, 0.0, 48.0), 15.0, float(i))
