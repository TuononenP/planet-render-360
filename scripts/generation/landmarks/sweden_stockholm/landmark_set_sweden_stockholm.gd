class_name LandmarkSetSwedenStockholm
extends RefCounted

## Builders of the sweden_stockholm landmark batch: one `match` arm per
## registry type of LandmarkRegistrySwedenStockholm. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

const GermanChurch = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_german_church.gd")
const HeroPalaces = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_hero_palaces.gd")
const HeroChurches = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_hero_churches.gd")
const HeroSkyline = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_hero_skyline.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"hotorg_1", "hotorg_2", "hotorg_3", "hotorg_4", "hotorg_5": HeroSkyline.hotorg(model)
		"katarinahissen": HeroSkyline.katarinahissen(model)
		"grona_lund_eclipse": HeroSkyline.eclipse(model)
		"kastellet_stockholm": HeroSkyline.kastellet(model)
		"royal_opera_stockholm": HeroSkyline.opera(model)
		"grand_hotel_stockholm": HeroSkyline.grand_hotel(model)
		"soder_torn": HeroSkyline.soder_torn(model)
		"riddarhuset_stockholm": HeroPalaces.riddarhuset(model)
		"wrangel_palace": HeroPalaces.wrangel(model)
		"bonde_palace": HeroPalaces.bonde(model)
		"nationalmuseum_stockholm": HeroPalaces.nationalmuseum(model)
		"klara_church": HeroChurches.klara(model)
		"sofia_church_stockholm": HeroChurches.sofia(model)
		"tyska_kyrkan": GermanChurch.build(model)
		"royal_palace_stockholm": LandmarkSsRoyal.palace(model)
		"storkyrkan": LandmarkSsRoyal.storkyrkan(model)
		"katarina_church": LandmarkSsRoyal.katarina(model)
		"hedvig_eleonora_church": LandmarkSsRoyal.hedvig_eleonora(model)
		"ericsson_globe": LandmarkSsLandmarks.globe(model)
		"kaknas_tower": LandmarkSsLandmarks.kaknas(model)
		"vasa_museum": LandmarkSsLandmarks.vasa(model)
		"nordic_museum": LandmarkSsCivic.nordic(model)
		"stockholm_public_library": LandmarkSsCivic.library(model)
		"stockholm_concert_hall": LandmarkSsCivic.concert_hall(model)
		"riksdag_building": LandmarkSsCivic.riksdag(model)
		_:
			return false
	return true
