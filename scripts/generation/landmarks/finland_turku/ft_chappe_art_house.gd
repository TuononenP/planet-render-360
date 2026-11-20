class_name FtChappeArtHouse
extends RefCounted

## Contemporary Art House Chappe (JKMM Architects, 2023):
## Sculpted contemporary copper-and-bronze gallery wedged along Läntinen
## Rantakatu beside the Old Library (+X ENE along river, +Z SE toward
## Aurajoki, turned by yaw_deg = -35.5°, height_m = 12.5):
##   - Sweeping dark patinated bronze/copper shingle facade (26 x 15 m, eaves
##     9.2 m, asymmetric sculpted curved/pitched copper roofline rising to
##     12.5 m) with vertical standing-seam ribs.
##   - Sculpted arched street-level picture windows opening onto the riverside
##     promenade with warm illuminated gallery interior visible at night.
##   - Recessed timber-and-glass entrance vestibule & rooftop skylight lantern.
## Surfaces: 7 merged PBR parts (Bronze, Patina, Stone, Timber, Frame, Glass, Lamp).

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4C3B31", 2.0, 0.44, 0.62))
	lm.use("Patina", LandmarkFrKit.copper("#4A6358"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#787672", 2.4))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#B48454", 2.0, 0.66))
	lm.use("Frame", LandmarkMaterials.paint("#23272B", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#24333E"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC2", 1.45))

	# Granite riverside plinth & main gallery mass (26 x 15 m).
	LandmarkFrKit.rect(lm, "Stone", -13.3, 13.3, -7.8, 7.8, FOUND, 0.65)
	LandmarkFrKit.rect(lm, "Bronze", -13.0, 13.0, -7.5, 7.5, 0.65, 9.2)
	# Sweeping asymmetric sculpted copper roof profile (gable-curve rising to 12.5 m).
	var segs := 10
	var x0 := -13.1
	var x1 := 13.1
	var z0 := -7.6
	var z1 := 7.6
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var za := lerpf(z0, z1, t0)
		var zb := lerpf(z0, z1, t1)
		var ya := 9.2 + 3.3 * sin(PI * pow(t0, 0.82))
		var yb := 9.2 + 3.3 * sin(PI * pow(t1, 0.82))
		var p0 := Vector3(x0, ya, za)
		var p1 := Vector3(x1, ya, za)
		var p2 := Vector3(x1, yb, zb)
		var p3 := Vector3(x0, yb, zb)
		lm.quad("Bronze", p0, p3, p2, p1, Vector3.UP)
		# End gable walls closing the curved roof profile.
		lm.quad("Bronze", Vector3(x0, 9.1, za), Vector3(x0, 9.1, zb), p3, p0, Vector3.LEFT)
		lm.quad("Bronze", Vector3(x1, 9.1, zb), Vector3(x1, 9.1, za), p1, p2, Vector3.RIGHT)
	# Rhythmic vertical standing-seam bronze/patina shingle ribs on all walls.
	for k in 17:
		var rx := lerpf(-12.4, 12.4, float(k) / 16.0)
		lm.box("Patina", Vector3(rx, 4.9, 7.56), Vector3(0.14, 8.4, 0.16))
		lm.box("Patina", Vector3(rx, 4.9, -7.56), Vector3(0.14, 8.4, 0.16))
	for k in 9:
		var rz := lerpf(-6.8, 6.8, float(k) / 8.0)
		lm.box("Patina", Vector3(-13.06, 4.9, rz), Vector3(0.16, 8.4, 0.14))
		lm.box("Patina", Vector3(13.06, 4.9, rz), Vector3(0.16, 8.4, 0.14))
	# Signature sculpted arched street-level picture windows facing Aurajoki (+Z) & warm glow.
	for ax: float in [-7.6, 0.0, 7.6]:
		LandmarkFrParts.opening(lm, "Frame", "Glass", Vector3(ax, 0.75, 7.52), Vector3.BACK, 4.6, 5.4,
			LandmarkFrParts.HEAD_ROUND, 0.28, 0.20, 1)
		LandmarkFrKit.rect(lm, "Timber", ax - 2.2, ax + 2.2, 6.4, 7.2, 0.8, 5.2)
		LandmarkFrKit.rect(lm, "Lamp", ax - 1.9, ax + 1.9, 6.8, 7.1, 1.1, 4.8)
	# Recessed timber-lined west entrance loggia (-X) & rooftop gallery skylight monitor.
	LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(-13.02, 0.75, 1.5), Vector3.LEFT, 4.2, 4.6,
		LandmarkFrParts.HEAD_ROUND, 0.32, 0.24, 1)
	LandmarkFrKit.rect(lm, "Frame", -6.5, 6.5, -1.8, 1.8, 11.4, 12.5)
	LandmarkFrKit.rect(lm, "Glass", -6.2, 6.2, -1.5, 1.5, 12.42, 12.54)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 1.2, 13.5), Vector3(-6.0, 5.5, 7.5), 58.0, 0.80, 28.0, Color(1.0, 0.86, 0.64)],
		[Vector3(6.0, 1.2, 13.5), Vector3(6.0, 5.5, 7.5), 58.0, 0.80, 28.0, Color(1.0, 0.86, 0.64)],
	])
