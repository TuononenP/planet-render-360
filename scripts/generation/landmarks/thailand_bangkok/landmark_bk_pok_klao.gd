class_name LandmarkBkPokKlao
extends RefCounted

## Phra Pok Klao Bridge & Chao Phraya Sky Park (`สะพานพระปกเกล้า / สวนลอยฟ้าเจ้าพระยา`) — BK-6.2
## Site: BridgeSpecsSoutheastAsiaAuNz `br_bangkok_pok_klao_bridge` (`13.73921, 100.49865`,
## `bearing: 18.8°`, `spans: [65.0, 100.0, 65.0] = 230.0 m`, `width: 37.7 m`, `clear: 11.0 m`).
## Builds the twin concrete box-girder road decks via `BridgeParam` plus the central elevated
## planted **Chao Phraya Sky Park** promenade (2020 adaptive reuse of the 1984 Lavalin viaduct):
## stepped cream concrete walkway & planters (`z = -4.2..+4.2 m`), lush green trees & hedges,
## and white lookout pergolas.

static func build(model: Node3D, row: Dictionary) -> void:
	BridgeParam.build(model, row)
	var lm := LandmarkMesh.new()
	lm.use("SkyWalk", LandmarkMaterials.pbr("limestone", "#ECE6D8", 3.0))
	lm.use("Foliage", LandmarkMaterials.pbr("grass", "#3E7434", 3.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E5C38", 2.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8AE", 1.5))

	var h := BridgeParam.half_length(row)
	var c := float(row["clear"])
	var sky_y := c + 1.35
	# Elevated central Sky Park viaduct spine (`8.4 m` wide, raised 1.35 m above carriageway)
	lm.box("SkyWalk", Vector3(0.0, c + 0.68, 0.0), Vector3(h * 2.0 - 4.0, 1.36, 8.4))
	lm.box("Wood", Vector3(0.0, sky_y + 0.05, 0.0), Vector3(h * 2.0 - 6.0, 0.10, 4.8), Basis(), 0.0)

	# Continuous green planter beds along both edges of the Sky Park + 14 shade trees & 3 white lookout pergolas
	for sz in [-1.0, 1.0]:
		var z := float(sz) * 3.1
		lm.box("SkyWalk", Vector3(0.0, sky_y + 0.38, z), Vector3(h * 2.0 - 8.0, 0.76, 1.8))
		lm.box("Foliage", Vector3(0.0, sky_y + 0.88, z), Vector3(h * 2.0 - 10.0, 0.55, 1.45))

	var tree := LandmarkMesh.new()
	for k in ["Wood", "Foliage"]:
		tree.use(k, LandmarkMaterials.gold())
	tree.beam("Wood", Vector3.ZERO, Vector3(0, 1.9, 0), 0.22, 0.22)
	tree.lathe("Foliage", Vector3(0, 1.5, 0), PackedVector2Array([
		Vector2(0.4, 0.0), Vector2(1.85, 0.7), Vector2(1.65, 1.7), Vector2(0.0, 2.3)]), 8)

	for i in 14:
		var tx := -h + 16.0 + (h * 2.0 - 32.0) * float(i) / 13.0
		var tz := 3.1 if i % 2 == 0 else -3.1
		lm.merge(tree, Transform3D(Basis(), Vector3(tx, sky_y + 0.75, tz)))

	for px in [-56.0, 0.0, 56.0]:
		for sx in [-3.5, 3.5]:
			for sz in [-3.6, 3.6]:
				lm.box("SkyWalk", Vector3(px + sx, sky_y + 1.5, sz), Vector3(0.28, 3.0, 0.28), Basis(), 0.0)
		lm.box("SkyWalk", Vector3(px, sky_y + 3.05, 0.0), Vector3(8.2, 0.24, 7.8))
		lm.box("Lamp", Vector3(px, sky_y + 2.88, 0.0), Vector3(5.6, 0.08, 0.35), Basis(), 0.0)

	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)
