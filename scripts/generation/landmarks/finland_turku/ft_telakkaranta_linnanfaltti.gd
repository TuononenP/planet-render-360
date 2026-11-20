class_name FtTelakkarantaLinnanfaltti
extends RefCounted

## Telakkaranta Waterfront & Harppuuna Residential Ensemble at the Aura River
## mouth (Itäinen Rantakatu / Telakkaranta opposite Forum Marinum & Turku Castle).
## Origin at 60.436600 N, 22.241200 E, yaw_deg -34.0.
##
## Architectural & facade spec:
## - Contemporary maritime brick, corten-steel & white-terrace residential
##   ensemble (44.0 x 26.0 m) stepping from a 5-storey riverside wing up to a
##   7-storey point block peaking at 27.0 m (matching turku_lod2 27.0 m).
## - Granite quay plinth, cantilevered glazed river balconies, warm timber
##   soffits, vertical corten fin accents & penthouse roof terraces.

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86827B", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#964E38", 2.5))
	lm.use("Corten", LandmarkMaterials.paint("#8E482A", 0.65, 0.55))
	lm.use("White", LandmarkMaterials.pbr("render", "#ECEAE2", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#A8784E", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#22303A"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A8", 0.85))

	# Granite riverside podium & lower 5-storey brick wing (-22..6, -12..10, h = 18.5 m).
	LandmarkFrKit.rect(lm, "Granite", -22.2, 22.2, -12.4, 12.4, FOUND, 1.6)
	LandmarkFrKit.rect(lm, "Brick", -22.0, 5.0, -11.5, 10.0, 1.6, 18.2)
	LandmarkFrKit.rect(lm, "White", -22.3, 5.3, -11.8, 10.3, 18.0, 18.6)
	# Recessed rooftop penthouse on lower wing.
	LandmarkFrKit.rect(lm, "Corten", -18.0, 1.5, -8.5, 6.5, 18.6, 21.8)

	# Taller 7-storey white-and-corten point block (+X = 5..22, peaking at 27.0 m).
	LandmarkFrKit.rect(lm, "White", 5.0, 22.0, -12.0, 11.5, 1.6, 24.4)
	LandmarkFrKit.rect(lm, "Corten", 7.0, 20.5, -9.8, 9.2, 24.4, 27.0)
	# Vertical corten architectural fins on the riverfront elevation.
	for i in 5:
		var fx := lerpf(6.2, 20.8, float(i) / 4.0)
		LandmarkFrKit.rect(lm, "Corten", fx - 0.18, fx + 0.18, 11.3, 12.1, 1.6, 24.4)

	# Cantilevered glazed balcony stacks with warm timber soffits facing Aurajoki (+Z).
	for fl in 5:
		var by := 4.4 + float(fl) * 3.25
		# Lower wing balconies.
		for bx: float in [-16.5, -8.5, -0.5]:
			LandmarkFrKit.rect(lm, "Wood", bx - 2.6, bx + 2.6, 10.0, 12.0, by - 0.22, by)
			LandmarkFrKit.rect(lm, "Glass", bx - 2.6, bx + 2.6, 11.85, 12.0, by, by + 1.15)
		# Taller point block balconies.
		for bx: float in [9.5, 17.5]:
			LandmarkFrKit.rect(lm, "Wood", bx - 2.4, bx + 2.4, 11.5, 13.4, by - 0.22, by)
			LandmarkFrKit.rect(lm, "Glass", bx - 2.4, bx + 2.4, 13.25, 13.4, by, by + 1.15)
	# Extra 2 floors of balconies on the 7-storey tower.
	for fl in [5, 6]:
		var by := 4.4 + float(fl) * 3.25
		for bx: float in [9.5, 17.5]:
			LandmarkFrKit.rect(lm, "Wood", bx - 2.4, bx + 2.4, 11.5, 13.4, by - 0.22, by)
			LandmarkFrKit.rect(lm, "Glass", bx - 2.4, bx + 2.4, 13.25, 13.4, by, by + 1.15)

	# Rhythmic glazed apartment windows on both river and rear facades.
	for i in 10:
		var x := lerpf(-19.5, 19.5, float(i) / 9.0)
		var max_fl := 7 if x > 5.0 else 5
		var fz := 11.52 if x > 5.0 else 10.02
		var bz := -12.02 if x > 5.0 else -11.52
		for fl in max_fl:
			var wy := 2.2 + float(fl) * 3.15
			var g := "WarmGlow" if ((i + fl) % 3 == 0) else "Glass"
			lm.box(g, Vector3(x, wy + 1.0, fz), Vector3(2.2, 2.0, 0.08), Basis(), 0.0)
			lm.box("Glass", Vector3(x, wy + 1.0, bz), Vector3(2.2, 2.0, 0.08), Basis(), 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 1.0, 17.5), Vector3(-6.0, 11.0, 10.5), 30.0, 0.8, 60.0, warm],
		[Vector3(14.0, 1.0, 18.5), Vector3(14.0, 16.0, 11.5), 32.0, 0.85, 60.0, warm],
	])
