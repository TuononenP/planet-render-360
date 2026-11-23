class_name LandmarkMiPortTerminalV
extends RefCounted

## Virgin Voyages Terminal V "Palm Grove" - PortMiami (MI-2C).
## Site: way:123899159 (25.780120, -80.180182), yaw_deg 21.0, footprint 80.8 x 175.4 m, 22.0 m.
## Architects: Arquitectonica.
##   - Faceted white-and-bronze canopy of 18 overlapping hipped palm-frond tiles
##     (3 x 6 grid, apexes exactly 22.0 m) carried on slender Y-shaped columns.
##   - Canted glass curtain hall beneath, royal palms along the forecourt.
##   - Warm crimson-amber Virgin accent lighting (VirginLamp).

const HEIGHT_M := 22.0
const ROOF_Y := 18.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#C6C4BE", 5.0))
	lm.use("WhiteRoof", LandmarkMaterials.paint("#F5F3EE", 0.40, 0.30))
	lm.use("Bronze", LandmarkMaterials.paint("#9A6A3A", 0.38, 0.70))
	lm.use("Glass", LandmarkMaterials.glass("#27434F"))
	lm.use("PalmTrunk", LandmarkMaterials.paint("#8D8A82", 0.80, 0.0))
	lm.use("PalmFrond", LandmarkMaterials.paint("#3C7A36", 0.75, 0.0))
	lm.use("VirginLamp", LandmarkMaterials.lit("#FF3A2A", 2.2))

	lm.box("Slab", Vector3(0.0, 0.1, 0.0), Vector3(80.8, 0.6, 175.4))
	for ix: int in 3:
		for iz: int in 6:
			var cx := -26.0 + 26.0 * float(ix)
			var cz := -72.5 + 29.0 * float(iz)
			var key := "WhiteRoof" if (ix + iz) % 2 == 0 else "Bronze"
			lm.lathe(key, Vector3(cx, ROOF_Y, cz),
				PackedVector2Array([Vector2(1.4142, 0.0), Vector2(0.0, HEIGHT_M - ROOF_Y)]),
				4, 13.0, 14.5, PI * 0.25, false)
			lm.box("Bronze", Vector3(cx, ROOF_Y - 0.25, cz), Vector3(26.0, 0.5, 29.0))
			# Y-shaped column: stem then two branches
			lm.beam("Bronze", Vector3(cx, 0.4, cz), Vector3(cx, 10.0, cz), 0.7, 0.7)
			for sx: float in [-1.0, 1.0]:
				lm.beam("Bronze", Vector3(cx, 10.0, cz), Vector3(cx + sx * 4.5, ROOF_Y - 0.5, cz), 0.5, 0.5)
			if ix == 1:
				lm.box("VirginLamp", Vector3(cx, ROOF_Y - 0.55, cz), Vector3(8.0, 0.14, 0.14))
	# Canted glass curtain hall
	lm.box("Glass", Vector3(-6.0, 6.0, 0.0), Vector3(1.0, 12.5, 150.0), Basis(Vector3(0, 0, 1), -0.14), 0.0)
	lm.box("Glass", Vector3(6.0, 6.0, 0.0), Vector3(1.0, 12.5, 150.0), Basis(Vector3(0, 0, 1), 0.14), 0.0)
	lm.box("WhiteRoof", Vector3(0.0, 12.5, 0.0), Vector3(16.0, 0.5, 150.0))
	for iz: int in 7:
		var pz := -78.0 + 26.0 * float(iz)
		for sx: float in [-1.0, 1.0]:
			LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", Vector3(sx * 34.0, 0.4, pz), 11.0, float(iz))
	lm.commit(model)

	var amber := Color(1.0, 0.62, 0.30)
	var crimson := Color(1.0, 0.18, 0.14)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-38.0, 4.0, -60.0), Vector3(0.0, 17.0, -30.0), 70.0, 1.2, 75.0, amber],
		[Vector3(38.0, 4.0, 60.0), Vector3(0.0, 17.0, 30.0), 70.0, 1.2, 75.0, crimson],
		[Vector3(-38.0, 4.0, 60.0), Vector3(0.0, 17.0, 30.0), 70.0, 1.0, 75.0, amber],
		[Vector3(38.0, 4.0, -60.0), Vector3(0.0, 17.0, -30.0), 70.0, 1.0, 75.0, crimson],
	])
