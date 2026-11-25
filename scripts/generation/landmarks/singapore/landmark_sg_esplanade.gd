class_name LandmarkSgEsplanade
extends RefCounted

## Esplanade – Theatres on the Bay (35 m, SG-2.2):
## - Twin asymmetric rounded shells: Concert Hall (96 x 73 m, way 256163011) and Lyric Theatre
##   (78 x 107 m, way 256163012), linked by a glazed concourse podium (way 97582570).
## - Signature "durian" sunshade skin: thousands of folded triangular brushed-aluminium sunshades
##   whose beak angle varies dynamically with surface normal (flatter near crown, sharply angled
##   on east/west flanks) over dark tinted structural glass.
## - Waterfront Outdoor Theatre stage with sculptural curved sail canopy + warm golden night glow.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Durian", LandmarkMaterials.pbr("sheet_metal", "#D6D8DC", 2.0, 0.28, 0.82))
	lm.use("Glass", LandmarkMaterials.glass("#263542"))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#DCD8CE", 3.0))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#4C535C", 2.0, 0.35, 0.72))
	lm.use("Canopy", LandmarkMaterials.pbr("concrete", "#ECEBE6", 3.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFCA7A", 1.9))

	# Base podium & concourse platform (trimmed to stay clear of the Marina Reservoir quay).
	lm.box("Podium", Vector3(0.0, 3.0, 0.0), Vector3(170.0, 6.0, 108.0))
	lm.box("Glass", Vector3(0.0, 9.0, 0.0), Vector3(44.0, 9.0, 68.0))
	lm.box("WarmLamp", Vector3(0.0, 8.5, 0.0), Vector3(36.0, 7.0, 58.0))

	# Shell 1: Concert Hall (south-west shell, 46 x 35 m radii, top 34.5 m).
	var c1 := Vector3(-44.0, 6.0, -4.0)
	LandmarkSgKit.loft_shell(lm, "Glass", c1, 45.0, 34.5, 27.5, 12, 28, 0.74)
	LandmarkSgKit.loft_shell(lm, "WarmLamp", c1 + Vector3(0.0, 0.5, 0.0), 40.5, 30.5, 23.5, 6, 16, 0.74)
	LandmarkSgKit.durian_shades(lm, "Durian", c1, 45.8, 35.2, 28.3, 18, 42, 0.74, 1.75)

	# Shell 2: Lyric Theatre (north-east shell, larger & slightly taller, 38 x 51 m radii, top 35.0 m).
	var c2 := Vector3(46.0, 6.0, 6.0)
	LandmarkSgKit.loft_shell(lm, "Glass", c2, 37.5, 50.0, 28.2, 12, 28, 0.72)
	LandmarkSgKit.loft_shell(lm, "WarmLamp", c2 + Vector3(0.0, 0.5, 0.0), 33.5, 45.5, 24.2, 6, 16, 0.72)
	LandmarkSgKit.durian_shades(lm, "Durian", c2, 38.2, 50.8, 29.0, 18, 44, 0.72, 1.85)

	# Waterfront Outdoor Theatre (bay-facing stage + sculptural tensioned sail canopy).
	var st := Vector3(12.0, 0.0, 72.0)
	lm.box("Podium", st + Vector3(0.0, 1.2, 0.0), Vector3(36.0, 2.4, 22.0))
	lm.beam("Steel", st + Vector3(-14.0, 2.4, -6.0), st + Vector3(-16.0, 14.5, 2.0), 0.45, 0.45)
	lm.beam("Steel", st + Vector3(14.0, 2.4, -6.0), st + Vector3(16.0, 14.5, 2.0), 0.45, 0.45)
	lm.box("Canopy", st + Vector3(0.0, 13.0, 0.0), Vector3(34.0, 0.6, 18.0), Basis(Vector3.RIGHT, 0.22))
	lm.box("WarmLamp", st + Vector3(0.0, 12.2, 0.0), Vector3(24.0, 0.3, 10.0), Basis(Vector3.RIGHT, 0.22))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-44.0, 4.0, 48.0), Vector3(-44.0, 22.0, 0.0), 62.0, 1.2],
		[Vector3(46.0, 4.0, 66.0), Vector3(46.0, 24.0, 8.0), 62.0, 1.2],
		[Vector3(0.0, 4.0, -56.0), Vector3(0.0, 22.0, 0.0), 66.0, 1.0],
	])
