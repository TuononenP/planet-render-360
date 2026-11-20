extends RefCounted

## Builders for data/stockholm/sto_reg_hero.gd.
## Returns false for a type it does not own.

const HeroSkyline = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_hero_skyline.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"grona_lund_eclipse": HeroSkyline.eclipse(model)
		"royal_palace_stockholm": LandmarkSsRoyal.palace(model)
		"storkyrkan": LandmarkSsRoyal.storkyrkan(model)
		"katarina_church": LandmarkSsRoyal.katarina(model)
		"hedvig_eleonora_church": LandmarkSsRoyal.hedvig_eleonora(model)
		"ericsson_globe": LandmarkSsLandmarks.globe(model)
		"kaknas_tower": LandmarkSsLandmarks.kaknas(model)
		"vasa_museum": LandmarkSsLandmarks.vasa(model)
		"nordic_museum": LandmarkSsCivic.nordic(model)
		"stockholm_public_library": StoHeroLibrary.build(model)
		"stockholm_concert_hall": StoHeroConcert.build(model)
		"riksdag_building": LandmarkSsCivic.riksdag(model)
		_:
			return false
	return true
