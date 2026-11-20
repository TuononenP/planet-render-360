class_name FtResurrectionChapel
extends RefCounted

## Resurrection Chapel (Ylösnousemuskappeli, Erik Bryggman, 1941) at Turku Cemetery.
## Origin at 60.433750 N, 22.307500 E, yaw_deg 15.0.
##
## Architectural & facade spec:
## - Asymmetric white-rendered modernist chapel hall (32.0 x 16.0 m, eaves 9.5 m,
##   gently pitched patinated copper roof to 12.2 m).
## - South flank (+Z) opens completely through a continuous tall glazed sanctuary
##   wall framed by slender limestone/plaster piers toward the pine cemetery.
## - Rough-hewn limestone/sandstone entry loggia (-X) with relief-carved pillars
##   and granite steps leading to the main portal.
## - Freestanding cylindrical white/sandstone bell tower (+X = 18.5, -Z = -4.5)
##   with open columned belfry lantern, copper cap & slender cross peaking at 18.0 m.

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A89F90", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F0ECE2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E2DCCE", 2.2))
	lm.use("Copper", LandmarkFrKit.copper("#4A7464"))
	lm.use("Glass", LandmarkMaterials.glass("#243038"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE4A8", 0.95))
	lm.use("Gilt", LandmarkMaterials.gold())

	# Limestone/granite terrace podium & main asymmetric chapel nave (30 x 14 m).
	LandmarkFrKit.rect(lm, "Stone", -16.5, 15.5, -8.5, 8.5, FOUND, 1.1)
	LandmarkFrKit.rect(lm, "Wall", -14.0, 14.0, -7.2, 4.5, 1.1, 9.6)
	# Sweeping gently pitched copper roof over the nave (ridge 12.2 m).
	LandmarkFrKit.gable(lm, "Copper", (0.0) - (29.6) * 0.5, (0.0) + (29.6) * 0.5, (-0.4) - (15.6) * 0.5, (-0.4) + (15.6) * 0.5, 9.6, 2.6, 0.0, "", 1)

	# Full-height south glazed sanctuary wall (+Z = 4.5..6.8) with 7 rhythmic stone piers.
	LandmarkFrKit.rect(lm, "WarmGlow", -13.2, 12.8, 4.5, 6.4, 1.1, 9.0)
	LandmarkFrKit.rect(lm, "Trim", -13.6, 13.4, 4.4, 6.8, 8.85, 9.55)
	for i in 8:
		var px := lerpf(-13.2, 12.8, float(i) / 7.0)
		LandmarkFrKit.rect(lm, "Stone", px - 0.32, px + 0.32, 6.1, 6.85, 1.1, 9.0)
		# Horizontal bronze/trim transoms across the sanctuary glass.
		if i < 7:
			var mx := px + 1.85
			lm.box("Trim", Vector3(mx, 3.8, 6.48), Vector3(3.5, 0.14, 0.12), Basis(), 0.0)
			lm.box("Trim", Vector3(mx, 6.4, 6.48), Vector3(3.5, 0.14, 0.12), Basis(), 0.0)

	# West sandstone entry loggia (-X = -14..-19) with 4 carved columns & steps.
	LandmarkFrKit.rect(lm, "Stone", -20.0, -14.0, -6.5, 6.5, FOUND, 1.1)
	for s in 4:
		LandmarkFrKit.rect(lm, "Stone", -20.0 - float(s + 1) * 0.45, -19.8, -5.8, 5.8, FOUND, lerpf(0.85, 0.2, float(s) / 3.0))
	LandmarkFrKit.rect(lm, "Wall", -19.2, -13.8, -6.2, 6.2, 6.6, 7.3)
	LandmarkFrKit.gable(lm, "Copper", (-16.5) - (5.8) * 0.5, (-16.5) + (5.8) * 0.5, (0.0) - (12.8) * 0.5, (0.0) + (12.8) * 0.5, 7.3, 1.0, 0.0, "", 1)
	for i in 4:
		var cz := lerpf(-4.6, 4.6, float(i) / 3.0)
		lm.frustum("Stone", Vector3(-18.4, 1.1, cz), 0.38, 0.34, 5.6, 12)
	LandmarkFrParts.opening(lm, "Stone", "WarmGlow", Vector3(-14.02, 1.2, 0.0), Vector3(-1, 0, 0),
		2.8, 4.4, LandmarkFrParts.HEAD_FLAT, 0.26, 0.14, 2)

	# Freestanding cylindrical bell tower (+X = 18.5, -Z = -4.5, peaking at 18.0 m).
	var tx := 18.5
	var tz := -4.5
	lm.frustum("Stone", Vector3(tx, FOUND, tz), 2.7, 2.6, 2.4 - FOUND, 20)
	lm.frustum("Wall", Vector3(tx, 2.4, tz), 2.45, 2.35, 10.6, 20)
	lm.frustum("Trim", Vector3(tx, 12.8, tz), 2.55, 2.6, 0.35, 20)
	# Open 8-column belfry lantern (y = 13.15..15.6 m) + copper cone & cross to 18.0 m.
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.frustum("Stone", Vector3(tx + cos(a) * 1.85, 13.15, tz + sin(a) * 1.85), 0.16, 0.14, 2.45, 8)
	lm.frustum("WarmGlow", Vector3(tx, 13.6, tz), 0.7, 0.5, 1.4, 10)
	lm.frustum("Copper", Vector3(tx, 15.6, tz), 2.65, 0.12, 1.35, 20)
	lm.frustum("Gilt", Vector3(tx, 16.9, tz), 0.07, 0.05, 1.1, 8)
	lm.box("Gilt", Vector3(tx, 17.65, tz), Vector3(0.65, 0.09, 0.09), Basis(), 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.76)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 0.8, 12.5), Vector3(0.0, 5.5, 5.5), 28.0, 0.9, 65.0, warm],
		[Vector3(23.5, 1.0, -9.0), Vector3(18.5, 13.0, -4.5), 28.0, 0.95, 55.0, warm],
	])
