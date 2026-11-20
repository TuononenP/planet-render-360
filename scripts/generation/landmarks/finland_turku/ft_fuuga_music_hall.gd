class_name FtFuugaMusicHall
extends RefCounted

## Turku Music Hall Fuuga (Musiikkitalo Fuuga, PES-Architects):
## Contemporary riverside concert hall beside City Theatre on Itäinen
## Rantakatu (+X ENE upstream, -Z NNW facing Aurajoki, yaw_deg = -31.2°,
## height_m = 21.0):
##   - Sculpted curved warm brass/copper & panoramic glass foyer facing
##     Aurajoki (-Z, 56 x 34 m) with rhythmic vertical golden-bronze acoustic
##     fins, cantilevered entrance canopy, and glowing curved timber concert
##     foyer visible through full-height river glazing.
##   - Stepped sculpted acoustic concert hall volume rising behind the foyer
##     to 21.0 m with landscaped rooftop garden terrace & parapet rails.
## Surfaces: 8 merged PBR parts (Brass, Timber, Concrete, Stone, Roof,
## Frame, Glass, Lamp).

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brass", LandmarkMaterials.pbr("concrete", "#B68C52", 2.4, 0.38, 0.68))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#B88450", 2.2, 0.66))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D6D2C8", 2.8))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7B75", 2.4))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C5254", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#2A2E33", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263844"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.5))

	# Granite riverside podium & approach terrace steps (-Z faces Aurajoki).
	LandmarkFrKit.rect(lm, "Stone", -29.0, 29.0, -21.0, 17.5, FOUND, 1.1)
	for step in 4:
		var t := float(step) / 3.0
		var sz := lerpf(-21.0, -23.0, t)
		var sy := lerpf(1.0, 0.2, t)
		LandmarkFrKit.rect(lm, "Stone", -20.0, 20.0, sz - 0.55, sz, FOUND, sy)
	# Sweeping curved panoramic glass & timber foyer facing Aurajoki (-Z).
	var segs := 20
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var x0 := lerpf(-27.0, 27.0, t0)
		var x1 := lerpf(-27.0, 27.0, t1)
		var z0 := -16.0 - 3.6 * sin(PI * t0)
		var z1 := -16.0 - 3.6 * sin(PI * t1)
		var n := Vector3(-(z1 - z0), 0.0, x1 - x0).normalized()
		if n.z > 0.0:
			n = -n
		# Full-height curved riverfront glass curtain wall (y = 1.1..11.2 m).
		lm.quad("Glass", Vector3(x0, 1.1, z0), Vector3(x1, 1.1, z1),
			Vector3(x1, 11.2, z1), Vector3(x0, 11.2, z0), n)
		# Overhanging brass/copper curved canopy fascia (y = 11.2..12.8 m) & timber soffit.
		var cz0 := z0 - 1.8
		var cz1 := z1 - 1.8
		lm.quad("Brass", Vector3(x0, 11.2, cz0), Vector3(x1, 11.2, cz1),
			Vector3(x1, 12.8, cz1), Vector3(x0, 12.8, cz0), n)
		lm.quad("Timber", Vector3(x0, 11.2, z0), Vector3(x1, 11.2, z1),
			Vector3(x1, 11.2, cz1), Vector3(x0, 11.2, cz0), Vector3.DOWN)
		lm.quad("Roof", Vector3(x0, 12.8, cz0), Vector3(x1, 12.8, cz1),
			Vector3(x1, 12.8, z1 + 8.0), Vector3(x0, 12.8, z0 + 8.0), Vector3.UP)
		# Rhythmic vertical golden-bronze acoustic mullions & horizontal transoms along the curve.
		lm.box("Brass", Vector3(x0, 6.2, z0 - 0.16), Vector3(0.22, 10.2, 0.44))
		lm.beam("Frame", Vector3(x0, 6.0, z0 - 0.12), Vector3(x1, 6.0, z1 - 0.12), 0.18, 0.22)
		lm.beam("Frame", Vector3(x0, 13.9, cz0 + 0.4), Vector3(x1, 13.9, cz1 + 0.4), 0.06, 0.06)
		lm.beam("Frame", Vector3(x0, 12.8, cz0 + 0.4), Vector3(x0, 13.95, cz0 + 0.4), 0.05, 0.05)
	# Warm glowing curved timber interior foyer shell visible behind the glass.
	LandmarkFrKit.rect(lm, "Timber", -24.0, 24.0, -14.8, -11.5, 1.2, 11.0)
	LandmarkFrKit.rect(lm, "Lamp", -23.5, 23.5, -15.2, -14.8, 1.6, 10.4)
	# Sculpted main concert hall acoustic mass rising behind foyer to 21.0 m.
	LandmarkFrKit.rect(lm, "Concrete", -27.0, 27.0, -12.0, 16.5, 1.1, 13.0)
	LandmarkFrKit.rect(lm, "Brass", -21.0, 21.0, -6.5, 15.0, 13.0, 20.7)
	LandmarkFrKit.rect(lm, "Roof", -20.5, 20.5, -6.0, 14.5, 20.7, 21.05)
	# Vertical golden-brass acoustic cladding ribs around the upper concert hall drum.
	for k in 17:
		var rx := lerpf(-20.2, 20.2, float(k) / 16.0)
		lm.box("Timber", Vector3(rx, 16.8, -6.58), Vector3(0.24, 7.6, 0.24))
		lm.box("Timber", Vector3(rx, 16.8, 15.08), Vector3(0.24, 7.6, 0.24))
	# Rooftop garden terrace parapet rails overlooking Aurajoki.
	lm.beam("Frame", Vector3(-26.0, 13.9, -15.5), Vector3(26.0, 13.9, -15.5), 0.06, 0.06)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-14.0, 1.8, -25.0), Vector3(-12.0, 8.0, -17.5), 60.0, 0.85, 40.0, Color(1.0, 0.86, 0.62)],
		[Vector3(14.0, 1.8, -25.0), Vector3(12.0, 8.0, -17.5), 60.0, 0.85, 40.0, Color(1.0, 0.86, 0.62)],
		[Vector3(0.0, 13.2, -14.0), Vector3(0.0, 17.5, -6.5), 56.0, 0.80, 34.0, Color(1.0, 0.82, 0.56)],
	])
