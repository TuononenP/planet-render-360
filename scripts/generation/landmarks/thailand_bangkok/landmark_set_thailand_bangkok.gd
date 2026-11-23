class_name LandmarkSetThailandBangkok
extends RefCounted

## Builders of the Bangkok landmark batch (`LandmarkRegistryThailandBangkok`).
## Returns false for unknown types so `LandmarkBuilder` continues down the sets list.

static func build(model: Node3D, type: String) -> bool:
	var spec := BkTowerSpecs.spec_for(type)
	if not spec.is_empty():
		TowerSpec.build(model, spec)
		return true
	match type:
		"giant_swing":
			LandmarkBkGiantSwing.build(model)
		"wat_suthat":
			LandmarkBkWatSuthat.build(model)
		"democracy_monument":
			LandmarkBkDemocracyMonument.build(model)
		"loha_prasat":
			LandmarkBkLohaPrasat.build(model)
		"golden_mount":
			LandmarkBkGoldenMount.build(model)
		"mahakan_fort":
			LandmarkBkMahakanFort.build(model)
		"bangkok_city_pillar":
			LandmarkBkCityPillar.build(model)
		"ministry_of_defence_bangkok":
			LandmarkBkMinistryDefence.build(model)
		"thammasat_dome":
			LandmarkBkThammasatDome.build(model)
		"national_museum_bangkok":
			LandmarkBkNationalMuseum.build(model)
		"wat_ratchabophit":
			LandmarkBkWatRatchabophit.build(model)
		"wat_ratchapradit":
			LandmarkBkWatRatchapradit.build(model)
		"wat_bowonniwet":
			LandmarkBkWatBowonniwet.build(model)
		"phra_sumen_fort":
			LandmarkBkPhraSumenFort.build(model)
		"santa_cruz_church":
			LandmarkBkSantaCruz.build(model)
		"wat_kalayanamit":
			LandmarkBkWatKalayanamit.build(model)
		"wat_prayun":
			LandmarkBkWatPrayun.build(model)
		"san_chao_pho_suea":
			LandmarkBkTigerShrine.build(model)
		"king_prajadhipok_museum":
			LandmarkBkPrajadhipokMuseum.build(model)
		"wat_benchamabophit":
			LandmarkBkWatBenchamabophit.build(model)
		"chinatown_gate_wat_traimit":
			LandmarkBkChinatownTraimit.build(model)
		"ananta_samakhom":
			LandmarkBkAnantaSamakhom.build(model)
		"wat_mangkon_kamalawat":
			LandmarkBkWatMangkon.build(model)
		_:
			return false
	return true
