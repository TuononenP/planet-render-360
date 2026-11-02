class_name LandmarkEgSaqqara
extends RefCounted

## The early pyramids of the Memphite necropolis in true metres: Djoser's
## Step Pyramid at Saqqara with its enclosure wall and entrance
## colonnade, Sneferu's Bent and Red Pyramids at Dahshur and the
## collapsed tower of Meidum. Faces to the compass, +X east, -Z north.

# --- Step Pyramid of Djoser ---

## Six battered tiers 62.5 m high on a 125 x 109 m base, inside the 544 x
## 277 m panelled enclosure wall (10.5 m, the long side north-south,
## pyramid 300 m from the north wall), the roofed entrance colonnade of
## 40 ribbed columns at the south-east corner and the Heb-Sed court of
## dummy shrines east of the pyramid.
static func djoser(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#CDBA94", 3.2))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#DDD0AE", 3.4))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Sand", Vector3(0, -1.4, 0), Vector3(150.0, 3.2, 134.0))
	var heights: Array[float] = [12.0, 11.3, 10.6, 10.1, 9.5, 9.0]
	var w := 125.0
	var d := 109.0
	var y := 0.0
	for h in heights:
		var lean := h * 0.3
		LandmarkEgParts.taper(lm, "Stone", Vector3(0, y, 0), w, d, w - 2.0 * lean, d - 2.0 * lean, h)
		y += h
		w -= 2.0 * (lean + 2.8)
		d -= 2.0 * (lean + 2.8)
	# Enclosure wall: a plain core with a panelled buttress every 8 m.
	var x0 := -138.5
	var x1 := 138.5
	var z0 := -300.0
	var z1 := 244.0
	LandmarkEgParts.wall(lm, "Wall", Vector2(x0, z0), Vector2(x1, z0), 10.5, 3.2)
	LandmarkEgParts.wall(lm, "Wall", Vector2(x0, z1), Vector2(x1, z1), 10.5, 3.2)
	LandmarkEgParts.wall(lm, "Wall", Vector2(x0, z0), Vector2(x0, z1), 10.5, 3.2)
	LandmarkEgParts.wall(lm, "Wall", Vector2(x1, z0), Vector2(x1, z1), 10.5, 3.2)
	for i in 35:
		var x := x0 + 8.0 + 7.5 * i
		for z in [z0 - 1.6, z1 + 1.6]:
			lm.box("Wall", Vector3(x, 5.25, z), Vector3(3.4, 10.5, 1.0))
	for i in 67:
		var z := z0 + 8.0 + 8.0 * i
		for x in [x0 - 1.6, x1 + 1.6]:
			lm.box("Wall", Vector3(x, 5.25, z), Vector3(1.0, 10.5, 3.4))
	# Entrance colonnade: roofed corridor between two spur walls.
	lm.box("Wall", Vector3(112.0, 6.0, 213.0), Vector3(12.8, 1.2, 56.0))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(112.0 + s * 6.0, 3.0, 213.0), Vector3(1.8, 6.0, 56.0))
	for i in 20:
		for s in [-1.0, 1.0]:
			lm.frustum("Wall", Vector3(112.0 + s * 3.6, 0, 187.0 + 2.7 * i), 0.55, 0.5, 5.4, 8)
	lm.box("Dark", Vector3(112.0, 2.4, 241.4), Vector3(3.4, 4.8, 0.6))
	# Heb-Sed court: two rows of dummy shrines east of the pyramid.
	for i in 12:
		for x in [86.0, 100.0]:
			lm.box("Wall", Vector3(x, 2.4, -112.0 + 12.5 * i), Vector3(4.5, 4.8, 8.5))
	lm.commit(model)

# --- Bent Pyramid ---

## 188.6 m square, 104.7 m: the 54.5 degree lower slope turns at 47 m to
## 43.5 degrees, most of the Tura casing still on; the 52 m satellite
## pyramid 55 m south and the mortuary chapel on the east face.
static func bent(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Casing", LandmarkMaterials.pbr("stone", "#DDD0AB", 4.2))
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C4AE86", 3.6))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	var hb := 94.3
	var kink := 47.0
	var hw_kink := 60.7
	var apex_lower := kink / (1.0 - hw_kink / hb)
	var apex_top := 104.7
	var hb_upper := hw_kink / (1.0 - kink / apex_top)
	lm.box("Sand", Vector3(0, -1.0, 0), Vector3(hb * 2.0 + 24.0, 2.4, hb * 2.0 + 24.0))
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb, apex_lower, 0.0, kink)
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb_upper, apex_top, kink, apex_top)
	LandmarkEgParts.courses(lm, "Core", Vector3(0, 0, 165.0), 26.2, 37.0, 0.0, 24.0, 1.4, true)
	lm.box("Core", Vector3(108.0, 3.0, 0), Vector3(14.0, 6.0, 22.0))
	lm.box("Core", Vector3(128.0, 1.0, 0), Vector3(26.0, 2.0, 6.0))
	lm.commit(model)

# --- Red Pyramid ---

## 220 m square, 104 m (43.4 degrees): the first true smooth-sided
## pyramid, today stripped to its red-weathered core courses with a ring
## of the white casing left at the foot, and the chapel ruin east.
static func red_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C47A55", 3.8))
	lm.use("Casing", LandmarkMaterials.pbr("stone", "#DCCFAC", 4.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	var hb := 110.0
	var apex := 104.0
	lm.box("Sand", Vector3(0, -1.0, 0), Vector3(hb * 2.0 + 24.0, 2.4, hb * 2.0 + 24.0))
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb, apex, 0.0, 4.5)
	LandmarkEgParts.courses(lm, "Core", Vector3.ZERO, hb, apex, 4.5, apex, 1.3)
	lm.box("Core", Vector3(126.0, 2.5, 0), Vector3(16.0, 5.0, 24.0))
	lm.commit(model)

# --- Pyramid of Meidum ---

## The collapsed pyramid of Huni and Sneferu: a three-stage tower of core
## masonry 65 m high standing out of a 185 m wide mound of its own
## casing debris (the outer layers slid away in antiquity).
static func meidum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tower", LandmarkMaterials.pbr("stone", "#C2AB82", 3.6))
	lm.use("Rubble", LandmarkMaterials.pbr("gravel", "#B09A74", 5.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Sand", Vector3(0, -1.0, 0), Vector3(200.0, 2.4, 200.0))
	var talus := PackedVector2Array()
	for p in [[92.0, 0.0], [77.0, 7.0], [61.0, 16.0], [46.0, 26.0], [34.0, 34.0]]:
		talus.append(Vector2(p[0] / cos(PI / 8.0), p[1]))
	lm.lathe("Rubble", Vector3.ZERO, talus, 8, 1.0, 1.0, PI / 8.0, false, true)
	LandmarkEgParts.taper(lm, "Tower", Vector3(0, 30.0, 0), 66.0, 66.0, 60.0, 60.0, 15.0)
	LandmarkEgParts.taper(lm, "Tower", Vector3(0, 45.0, 0), 52.0, 52.0, 47.0, 47.0, 11.0)
	LandmarkEgParts.taper(lm, "Tower", Vector3(0, 56.0, 0), 39.0, 39.0, 34.0, 34.0, 9.0)
	lm.commit(model)
