class_name LandmarkSetSingapore
extends RefCounted

## Builders of the Singapore hero city landmark batch (`LandmarkRegistrySingapore`).
## Returns false for unknown types so `LandmarkBuilder` continues down the sets list.

const BEACON_TOWERS := {
	"guoco_tower_sg": 283.7,
	"uob_plaza_one_sg": 280.0,
	"republic_plaza_sg": 280.0,
	"capitaspring_sg": 280.0,
	"one_raffles_place_1_sg": 280.0,
	"capital_tower_sg": 254.0,
	"swissotel_stamford_sg": 226.0,
}

static func build(model: Node3D, type: String) -> bool:
	var spec := SgTowerSpecs.spec_for(type)
	if not spec.is_empty():
		TowerSpec.build(model, spec)
		if BEACON_TOWERS.has(type):
			model.set_meta(LandmarkLights.HALO_META, [
				[Vector3(0.0, float(BEACON_TOWERS[type]) + 0.5, 0.0), 2.6, Color(1.0, 0.14, 0.06)],
			])
		return true
	match type:
		# Phase 2: Marina Bay Hero Icons
		"marina_bay_sands":
			LandmarkSgMarinaBaySands.build(model)
		"esplanade_singapore":
			LandmarkSgEsplanade.build(model)
		"merlion_park":
			LandmarkSgMerlion.build(model)
		"singapore_flyer":
			LandmarkSgFlyer.build(model)
		"artscience_museum":
			LandmarkSgArtScience.build(model)
		"helix_bridge":
			LandmarkSgHelix.build(model)
		"fullerton_hotel":
			LandmarkSgFullerton.fullerton_hotel(model)
		"fullerton_waterfront":
			LandmarkSgFullerton.fullerton_waterfront(model)
		"supertree_grove":
			LandmarkSgSupertrees.build(model)
		"gardens_by_the_bay_domes":
			LandmarkSgGardensDomes.build(model)
		"marina_barrage":
			LandmarkSgMarinaBarrage.build(model)
		# Phase 3A: Civic District & Padang Core
		"national_gallery_sg":
			LandmarkSgNationalGallery.build(model)
		"supreme_court_sg":
			LandmarkSgCivicModern.supreme_court(model)
		"victoria_theatre_sg":
			LandmarkSgVictoria.victoria_theatre(model)
		"st_andrews_cathedral_sg":
			LandmarkSgCathedral.build(model)
		"arts_house_parliament_sg":
			LandmarkSgCivicModern.arts_house_parliament(model)
		"padang_ensemble_sg":
			LandmarkSgCivicModern.padang_ensemble(model)
		"civilian_war_memorial_sg":
			LandmarkSgCivicModern.civilian_war_memorial(model)
		"raffles_hotel_sg":
			LandmarkSgHeritageCivic.raffles_hotel(model)
		"old_hill_street_police_sg":
			LandmarkSgHeritageCivic.old_hill_street_police(model)
		"asian_civilisations_museum_sg":
			LandmarkSgVictoria.asian_civilisations_museum(model)
		# Phase 3B: Heritage Districts, River, Cultural Ring & Sports Hub
		"sri_mariamman_temple_sg":
			LandmarkSgChinatownTemples.sri_mariamman(model)
		"buddha_tooth_relic_sg":
			LandmarkSgChinatownTemples.buddha_tooth_relic(model)
		"thian_hock_keng_sg":
			LandmarkSgChinatownTemples.thian_hock_keng(model)
		"sultan_mosque_sg":
			LandmarkSgSultanLauClarke.sultan_mosque(model)
		"lau_pa_sat_sg":
			LandmarkSgSultanLauClarke.lau_pa_sat(model)
		"clarke_quay_sg":
			LandmarkSgSultanLauClarke.clarke_quay(model)
		"chijmes_sg":
			LandmarkSgCulturalRing.chijmes(model)
		"armenian_church_sg":
			LandmarkSgCulturalRing.armenian_church(model)
		"central_fire_station_sg":
			LandmarkSgCulturalRing.central_fire_station(model)
		"national_museum_sg":
			LandmarkSgCulturalRing.national_museum(model)
		"national_stadium_sg":
			LandmarkSgCulturalRing.national_stadium(model)
		# Phase 4: Bespoke Singapore River Bridges
		"cavenagh_bridge_sg":
			LandmarkSgBridges.cavenagh_bridge(model)
		"anderson_bridge_sg":
			LandmarkSgBridges.anderson_bridge(model)
		"elgin_bridge_sg":
			LandmarkSgBridges.elgin_bridge(model)
		_:
			return false
	return true
