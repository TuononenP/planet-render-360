class_name FtSamppalinnaWindmill
extends RefCounted

## Samppalinna Restaurant (1865, C.J. von Heideken) & Samppalinna Windmill
## (1860): iconic wooden hilltop landmarks crowning Samppalinnanmäki
## overlooking Aurajoki (+X ENE, -Z NNW toward Aurajoki/Cathedral, yaw_deg =
## -32.2°, height_m = 14.5):
##   1. Samppalinna Restaurant (Samppalinnan ravintola, 1865) at (0, 0):
##      ornate Swiss-style wooden summer pavilion (24 x 16 m, eaves 7.2 m,
##      hipped/gabled roofs to 11.4 m) with wraparound white timber verandas,
##      decorative fretwork eaves, twin corner veranda towers, and warm
##      glowing riverside dining windows.
##   2. Samppalinna Windmill (Samppalinnan tuulimylly, 1860) as SEAT_META
##      child at (-24.0, -8.0): white octagonal wooden smock windmill on
##      rough granite base with rotating cap, gallery ring, and four dark
##      lattice wooden sails reaching 14.6 m.
## Surfaces: 11 merged PBR parts (7 restaurant + 4 windmill SEAT_META child).

const FOUND := -2.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WoodCream", LandmarkMaterials.pbr("wood", "#EFE8D6", 2.2, 0.74))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F7F4EC", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7A74", 2.4))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A4246", 2.2))
	lm.use("WoodDark", LandmarkMaterials.pbr("wood", "#5B4534", 2.0, 0.74))
	lm.use("Glass", LandmarkMaterials.glass("#24323C"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B6", 1.4))

	# Swiss-style wooden Samppalinna Restaurant pavilion (24 x 14 m, eaves 7.2 m, ridge 11.4 m).
	LandmarkFrKit.rect(lm, "Stone", -12.4, 12.4, -8.8, 7.4, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "WoodCream", -12.0, 12.0, -7.0, 7.0, 1.4, 7.2)
	LandmarkFrParts.cornice_ring(lm, "Trim", -12.0, 12.0, -7.0, 7.0, 6.85, 0.38)
	LandmarkFrKit.hip(lm, "Roof", -12.0, 12.0, -7.0, 7.0, 7.2, 4.2, 0.85)
	# Wraparound riverside Swiss timber veranda (-Z = -10.2..-7.0) with posts & balustrade.
	LandmarkFrKit.rect(lm, "WoodDark", -12.4, 12.4, -10.2, -7.0, 1.15, 1.45)
	LandmarkFrKit.rect(lm, "Roof", -12.8, 12.8, -10.6, -6.8, 4.65, 5.05)
	for k in 9:
		var px := lerpf(-11.8, 11.8, float(k) / 8.0)
		lm.box("Trim", Vector3(px, 3.05, -10.0), Vector3(0.18, 3.3, 0.18))
	lm.box("Trim", Vector3(0.0, 2.35, -10.0), Vector3(23.8, 0.12, 0.12))
	# Twin Swiss corner veranda gables & tall riverside dining windows with warm glow.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "WoodCream", sx * 9.5 - 2.6, sx * 9.5 + 2.6, -8.5, -6.8, 4.8, 8.6)
		LandmarkFrKit.gable(lm, "Roof", sx * 9.5 - 2.7, sx * 9.5 + 2.7, -8.7, -6.6, 8.6, 2.5, 0.45, "Trim", 0)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.5, 2.0, -7.0), Vector3(9.5, 2.0, -7.0),
		Vector3.FORWARD, 6, 1.5, 2.5, LandmarkFrParts.HEAD_ROUND, 0.16, 0.12, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.5, 4.9, -7.0), Vector3(9.5, 4.9, -7.0),
		Vector3.FORWARD, 6, 1.4, 1.85, LandmarkFrParts.HEAD_FLAT, 0.14, 0.10, 1)
	LandmarkFrKit.rect(lm, "Lamp", -9.0, 9.0, -6.3, -6.0, 2.2, 4.3)
	lm.commit(model)

	# Samppalinna Windmill (1860) seated on the adjacent hilltop crest via SEAT_META.
	var wlm := LandmarkMesh.new()
	for k: String in ["WoodCream", "Stone", "Roof", "WoodDark"]:
		wlm.use(k, (lm._surfs[k] as LandmarkMesh.Surf).mat)
	# Octagonal granite base & tapered white wooden smock body (H 9.6 m).
	wlm.frustum("Stone", Vector3(0.0, FOUND, 0.0), 3.9, 3.6, 2.0 - FOUND, 8, PI / 8.0)
	wlm.frustum("WoodCream", Vector3(0.0, 2.0, 0.0), 3.45, 2.15, 7.6, 8, PI / 8.0)
	# Rotating ogee dark cap (9.6 -> 11.4 m) & tailpole beam.
	wlm.lathe("Roof", Vector3(0.0, 9.6, 0.0), PackedVector2Array([
		Vector2(2.35, 0.0), Vector2(2.15, 0.7), Vector2(1.2, 1.4), Vector2(0.12, 1.85)]), 8, 1.0, 1.0, PI / 8.0, false)
	wlm.beam("WoodDark", Vector3(0.0, 9.5, 2.0), Vector3(0.0, 2.4, 6.2), 0.16, 0.16)
	# Four signature dark-timber lattice windmill sails facing -Z (top sail tip 14.6 m).
	var hub := Vector3(0.0, 9.9, -2.55)
	wlm.frustum("WoodDark", hub - Vector3(0, 0, -0.5), 0.35, 0.35, 0.9, 8)
	var sail_len := 5.1
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var dir := Vector3(cos(a), sin(a), 0.0)
		var perp := Vector3(-sin(a), cos(a), 0.0)
		wlm.beam("WoodDark", hub, hub + dir * sail_len, 0.16, 0.16)
		wlm.beam("WoodDark", hub + dir * 1.1 + perp * 0.85, hub + dir * sail_len + perp * 0.85, 0.07, 0.07)
		for r in 7:
			var t := lerpf(1.1, sail_len, float(r) / 6.0)
			wlm.beam("WoodDark", hub + dir * t - perp * 0.15, hub + dir * t + perp * 0.88, 0.06, 0.06)
	var child := Node3D.new()
	child.name = "SamppalinnaWindmill"
	child.position = Vector3(-24.0, 0.0, -8.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	wlm.commit(child)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, -16.0), Vector3(0.0, 5.5, -7.0), 62.0, 0.85, 32.0, Color(1.0, 0.88, 0.66)],
		[Vector3(-24.0, 1.5, -16.0), Vector3(-24.0, 8.5, -8.0), 54.0, 0.85, 30.0, Color(1.0, 0.88, 0.66)],
	])
