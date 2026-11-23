class_name LandmarkMiTowerTheater
extends RefCounted

## Tower Theater & Maximo Gomez Domino Park - Calle Ocho, Little Havana (MI-6.5).
## Site: way:318008207 (25.765480, -80.219667), yaw_deg 88.8, footprint 41.4 x 17.6 m, 18.0 m.
##   - 1926 Art Deco / Streamline Moderne cinema in cream, coral and turquoise stucco,
##     cantilevered neon marquee, glass-block bands and a stepped chrome-and-neon vertical
##     tower fin whose crown is exactly 18.0 m (MarqueeLamp).
##   - Domino Park beside it: wrought-iron fence, terracotta-roofed shade pavilions, tables.

const HEIGHT_M := 18.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("render", "#EFE4C8", 4.0))
	lm.use("Coral", LandmarkMaterials.paint("#F0765E", 0.7, 0.0))
	lm.use("Turquoise", LandmarkMaterials.paint("#2BB5B0", 0.6, 0.05))
	lm.use("Chrome", LandmarkMaterials.paint("#D8DDE2", 0.2, 0.9))
	lm.use("MarqueeLamp", LandmarkMaterials.lit("#FF4FA0", 2.4))
	lm.use("GlassBlock", LandmarkMaterials.glass("#6FA6B8"))
	lm.use("Terracotta", LandmarkMaterials.pbr("terracotta", "#B8613A", 3.0))
	lm.use("Iron", LandmarkMaterials.paint("#1E2024", 0.6, 0.5))
	lm.use("Table", LandmarkMaterials.pbr("wood", "#8A5E3B", 2.0))
	lm.use("Pavement", LandmarkMaterials.pbr("concrete", "#B2B0A8", 3.0))

	lm.box("Pavement", Vector3(0.0, -0.05, 0.0), Vector3(41.4, 0.3, 17.6))
	# Theater block (west half) with coral base band and turquoise parapet
	lm.box("Cream", Vector3(-9.0, 5.5, 0.0), Vector3(23.0, 11.0, 15.0), Basis(), 0.1)
	lm.box("Coral", Vector3(-9.0, 1.2, 0.0), Vector3(23.4, 2.4, 15.4), Basis(), 0.05)
	lm.box("Turquoise", Vector3(-9.0, 11.3, 0.0), Vector3(23.8, 0.7, 15.8), Basis(), 0.05)
	lm.box("GlassBlock", Vector3(-9.0, 7.6, 7.55), Vector3(18.0, 1.8, 0.2), Basis(), 0.0)
	lm.box("Turquoise", Vector3(-9.0, 4.0, 7.6), Vector3(5.0, 3.0, 0.3), Basis(), 0.0)
	# Cantilevered neon marquee
	lm.box("Coral", Vector3(-9.0, 5.0, 9.2), Vector3(10.0, 1.1, 3.4), Basis(), 0.05)
	lm.box("MarqueeLamp", Vector3(-9.0, 4.35, 10.95), Vector3(9.6, 0.18, 0.12), Basis(), 0.0)
	lm.box("MarqueeLamp", Vector3(-9.0, 5.65, 10.95), Vector3(9.6, 0.18, 0.12), Basis(), 0.0)
	for sx: float in [-1.0, 1.0]:
		lm.beam("Chrome", Vector3(-9.0 + sx * 4.6, 5.0, 10.5), Vector3(-9.0 + sx * 4.6, 0.0, 10.5), 0.25, 0.25)
	# Stepped vertical tower fin, top exactly 18.0 m
	var steps := [[3.4, 11.6, 4.0], [2.6, 14.4, 2.8], [1.8, 16.4, 2.0], [1.0, 17.6, 0.8]]
	var y := 11.6
	for st: Array in steps:
		var w: float = st[0]
		var top: float = st[1]
		lm.box("Chrome", Vector3(-9.0, (y + top) * 0.5, 7.0), Vector3(w, top - y, 1.0), Basis(), 0.03)
		y = top
	lm.box("MarqueeLamp", Vector3(-9.0, 17.9, 7.0), Vector3(0.5, 0.2, 0.5), Basis(), 0.0)
	lm.beam("MarqueeLamp", Vector3(-9.0, 11.8, 7.65), Vector3(-9.0, 17.0, 7.65), 0.3, 0.12)
	for sx: float in [-1.0, 1.0]:
		lm.beam("MarqueeLamp", Vector3(-9.0 + sx * 1.0, 11.8, 7.55), Vector3(-9.0 + sx * 0.5, 16.8, 7.55), 0.14, 0.1)
	# Domino Park: iron fence, shade pavilions, tables
	for i: int in 15:
		var fx := 3.0 + 1.2 * float(i)
		lm.beam("Iron", Vector3(fx, 0.0, 8.2), Vector3(fx, 2.0, 8.2), 0.08, 0.08)
	lm.beam("Iron", Vector3(3.0, 1.9, 8.2), Vector3(19.8, 1.9, 8.2), 0.1, 0.1)
	for pxc: float in [8.0, 16.0]:
		for cx: float in [-2.2, 2.2]:
			for cz: float in [-2.2, 2.2]:
				lm.beam("Iron", Vector3(pxc + cx, 0.0, cz - 1.0), Vector3(pxc + cx, 3.6, cz - 1.0), 0.18, 0.18)
		lm.spire("Terracotta", Vector3(pxc, 3.6, -1.0), 3.4, 1.6)
		lm.box("Table", Vector3(pxc, 0.8, -1.0), Vector3(1.8, 0.1, 1.2))
		lm.box("Table", Vector3(pxc, 0.4, -1.0), Vector3(0.2, 0.8, 0.2))
	lm.commit(model)

	var pink := Color(1.0, 0.35, 0.65)
	var warm := Color(1.0, 0.85, 0.6)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-9.0, 7.0, 16.0), Vector3(-9.0, 14.0, 7.0), 30.0, 1.3, 60.0, pink],
		[Vector3(12.0, 5.0, 6.0), Vector3(12.0, 0.5, -1.0), 20.0, 1.1, 80.0, warm],
	])
