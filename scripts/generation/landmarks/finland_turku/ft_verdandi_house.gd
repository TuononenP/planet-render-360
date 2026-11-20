class_name FtVerdandiHouse
extends RefCounted

## Verdandi House (Verdandin talo, 1898, Frithiof Strandell):
## Monumental Neo-Renaissance corner palace at Aurakatu 1 / Linnankatu across
## from City Hall (+X ENE along Linnankatu, +Z SE toward Aurajoki/City Hall,
## turned by yaw_deg = -34.7°, height_m = 27.0):
##   - L-shaped 4-storey stone-and-plaster palace (46 x 40 m, eaves 19.2 m,
##     steep hipped dark-metal roof to 23.6 m) with rusticated granite shop
##     arcade at street level, ornate plaster quoins, symmetric wrought-iron
##     balconies, arched upper windows, and iconic corner cylindrical/octagonal
##     turrets crowned by bulbous copper domes & finials reaching 27.2 m.
## Surfaces: 8 merged PBR parts (Plaster, Stone, Trim, Roof, Copper, Iron,
## Glass, Lamp).

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D9CBB2", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#868077", 2.4))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1ECE0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#373C41", 2.2))
	lm.use("Copper", LandmarkFrKit.copper("#4E7D6A"))
	lm.use("Iron", LandmarkMaterials.paint("#23272B", 0.45, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.3))

	# Main Linnankatu / Aurakatu L-block: south wing (46 x 16 m) + west wing (16 x 38 m).
	LandmarkFrKit.rect(lm, "Stone", -23.3, 23.3, 3.8, 20.3, FOUND, 5.0)
	LandmarkFrKit.rect(lm, "Plaster", -23.0, 23.0, 4.0, 20.0, 5.0, 19.2)
	LandmarkFrParts.band(lm, "Trim", -23.0, 23.0, 4.0, 20.0, 4.95, 0.55, 0.18)
	LandmarkFrParts.band(lm, "Trim", -23.0, 23.0, 4.0, 20.0, 14.5, 0.42, 0.15)
	LandmarkFrParts.cornice_ring(lm, "Trim", -23.0, 23.0, 4.0, 20.0, 18.5, 0.72)
	LandmarkFrKit.hip(lm, "Roof", -23.0, 23.0, 4.0, 20.0, 19.2, 4.4, 0.55)

	LandmarkFrKit.rect(lm, "Stone", -23.3, -6.7, -18.3, 4.2, FOUND, 5.0)
	LandmarkFrKit.rect(lm, "Plaster", -23.0, -7.0, -18.0, 4.2, 5.0, 19.2)
	LandmarkFrParts.band(lm, "Trim", -23.0, -7.0, -18.0, 4.2, 4.95, 0.55, 0.18)
	LandmarkFrParts.cornice_ring(lm, "Trim", -23.0, -7.0, -18.0, 4.2, 18.5, 0.72)
	LandmarkFrKit.hip(lm, "Roof", -23.0, -7.0, -18.0, 4.2, 19.2, 4.4, 0.55)

	# Arched ground-floor granite shopfronts & 3 upper Neo-Renaissance window tiers (+Z & -X).
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-18.5, 0.6, 20.3), Vector3(18.5, 0.6, 20.3),
		Vector3.BACK, 9, 2.4, 3.6, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-23.3, 0.6, -15.5), Vector3(-23.3, 0.6, 15.5),
		Vector3.LEFT, 7, 2.4, 3.6, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 1)
	for wy: float in [6.2, 10.6, 15.1]:
		var head := LandmarkFrParts.HEAD_ROUND if wy > 14.0 else LandmarkFrParts.HEAD_FLAT
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-18.5, wy, 20.0), Vector3(18.5, wy, 20.0),
			Vector3.BACK, 9, 1.55, 2.75, head, 0.20, 0.14, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-23.0, wy, -15.5), Vector3(-23.0, wy, 15.5),
			Vector3.LEFT, 7, 1.55, 2.75, head, 0.20, 0.14, 1)
	# Symmetric wrought-iron balconies on the 2nd & 3rd floors (+Z Linnankatu front).
	for bx: float in [-11.5, 0.0, 11.5]:
		for by: float in [10.3, 14.8]:
			lm.box("Trim", Vector3(bx, by, 20.65), Vector3(4.6, 0.28, 1.25))
			lm.box("Iron", Vector3(bx, by + 0.62, 21.22), Vector3(4.6, 0.92, 0.08))
	# Ornate corner Neo-Renaissance cupola towers at (-22.5, +19.5) and (+22.5, +19.5) to 27.2 m.
	for tc: Array in [[-22.4, 19.4, 3.2, 27.2], [22.4, 19.4, 2.6, 25.8], [-22.4, -17.4, 2.6, 25.8]]:
		var tx: float = tc[0]
		var tz: float = tc[1]
		var r: float = tc[2]
		var top_h: float = tc[3]
		lm.frustum("Stone", Vector3(tx, FOUND, tz), r + 0.15, r + 0.10, 5.0 - FOUND, 12)
		lm.frustum("Plaster", Vector3(tx, 5.0, tz), r, r * 0.96, 15.2, 12)
		lm.frustum("Trim", Vector3(tx, 19.8, tz), r * 1.08, r * 1.08, 0.65, 12)
		LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(tx, 15.4, tz), r * 0.98, 6, 0.95, 2.4,
			LandmarkFrParts.HEAD_ROUND)
		var dome_h := top_h - 20.45
		lm.lathe("Copper", Vector3(tx, 20.45, tz), PackedVector2Array([
			Vector2(r * 1.12, 0.0), Vector2(r * 1.02, dome_h * 0.22),
			Vector2(r * 0.55, dome_h * 0.55), Vector2(r * 0.18, dome_h * 0.78),
			Vector2(0.06, dome_h)]), 12, 1.0, 1.0, 0.0, false)
	# Warm ground-floor shopfront glow strips inside the arched windows.
	LandmarkFrKit.rect(lm, "Lamp", -18.0, 18.0, 19.3, 19.6, 1.0, 3.6)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-28.0, 2.0, 26.0), Vector3(-22.4, 16.0, 19.4), 52.0, 0.90, 44.0, Color(1.0, 0.88, 0.66)],
		[Vector3(0.0, 2.0, 28.0), Vector3(0.0, 12.0, 20.0), 60.0, 0.80, 40.0, Color(1.0, 0.88, 0.66)],
		[Vector3(-30.0, 2.0, 0.0), Vector3(-23.0, 12.0, 0.0), 58.0, 0.75, 38.0, Color(1.0, 0.88, 0.66)],
	])
