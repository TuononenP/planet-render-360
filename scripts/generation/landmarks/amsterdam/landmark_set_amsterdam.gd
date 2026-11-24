class_name LandmarkSetAmsterdam
extends RefCounted

## Landmark builder dispatch for the Amsterdam batch (`PLAN_Amsterdam_super_realistic.md`).
## Returns `true` if `type` is owned by Amsterdam, `false` otherwise.

static func build(model: Node3D, type: String) -> bool:
	var tower_spec := AmsTowerSpecs.spec_for(type)
	if not tower_spec.is_empty():
		TowerSpec.build(model, tower_spec)
		return true
	match type:
		# Dam Square & Singel foreground (`AMS-2.1`–`2.4`)
		"royal_palace_amsterdam":
			AmsDamEnsemble.royal_palace_amsterdam(model)
		"nieuwe_kerk_amsterdam":
			AmsDamEnsemble.nieuwe_kerk_amsterdam(model)
		"nationaal_monument_dam":
			AmsDamEnsemble.nationaal_monument_dam(model)
		"de_bijenkorf_amsterdam":
			AmsDamEnsemble.de_bijenkorf_amsterdam(model)
		"magna_plaza":
			AmsDamEnsemble.magna_plaza(model)
		# Historic canal-ring churches & towers (`AMS-2.5`, `2.7`, `2.8`)
		"westerkerk":
			AmsChurchesTowers.westerkerk(model)
		"oude_kerk_amsterdam":
			AmsChurchesTowers.oude_kerk_amsterdam(model)
		"zuiderkerk":
			AmsChurchesTowers.zuiderkerk(model)
		"munttoren":
			AmsChurchesTowers.munttoren(model)
		"waag_amsterdam":
			AmsChurchesTowers.waag_amsterdam(model)
		"koepelkerk_amsterdam":
			AmsChurchesTowers.koepelkerk_amsterdam(model)
		"noorderkerk":
			AmsChurchesTowers.noorderkerk(model)
		"de_krijtberg":
			AmsChurchesTowers.de_krijtberg(model)
		# Centraal, Damrak & East Waterfront historic (`AMS-2.6`, `2.9`, `2.10`)
		"amsterdam_centraal":
			AmsCentraalAndEast.amsterdam_centraal(model)
		"beurs_van_berlage":
			AmsCentraalAndEast.beurs_van_berlage(model)
		"sint_nicolaasbasiliek":
			AmsCentraalAndEast.sint_nicolaasbasiliek(model)
		"schreierstoren":
			AmsCentraalAndEast.schreierstoren(model)
		"montelbaanstoren":
			AmsCentraalAndEast.montelbaanstoren(model)
		"scheepvaarthuis":
			AmsCentraalAndEast.scheepvaarthuis(model)
		# Museumplein & South Canal Ring (`AMS-3.1`, `3.2`)
		"rijksmuseum":
			AmsMuseumplein.rijksmuseum(model)
		"van_gogh_museum":
			AmsMuseumplein.van_gogh_museum(model)
		"stedelijk_museum":
			AmsMuseumplein.stedelijk_museum(model)
		"concertgebouw":
			AmsMuseumplein.concertgebouw(model)
		"pathe_tuschinski":
			AmsMuseumplein.pathe_tuschinski(model)
		"de_bazel":
			AmsMuseumplein.de_bazel(model)
		"stadsschouwburg_amsterdam":
			AmsMuseumplein.stadsschouwburg_amsterdam(model)
		"heineken_experience":
			AmsMuseumplein.heineken_experience(model)
		"vondelkerk":
			AmsMuseumplein.vondelkerk(model)
		# Amstel & Jewish Cultural Quarter / East Heritage (`AMS-3.3`)
		"stopera_amsterdam":
			AmsAmstelAndEast.stopera_amsterdam(model)
		"hart_amstelhof":
			AmsAmstelAndEast.hart_amstelhof(model)
		"theater_carre":
			AmsAmstelAndEast.theater_carre(model)
		"amstel_hotel":
			AmsAmstelAndEast.amstel_hotel(model)
		"portugese_synagoge":
			AmsAmstelAndEast.portugese_synagoge(model)
		"tropenmuseum":
			AmsAmstelAndEast.tropenmuseum(model)
		"molen_de_gooyer":
			AmsAmstelAndEast.molen_de_gooyer(model)
		# IJ Waterfront, Oosterdok, Overhoeks, Harbour & Stadiums (`AMS-3.4`, `3.5`)
		"nemo_amsterdam":
			AmsIjWaterfront.nemo_amsterdam(model)
		"scheepvaartmuseum":
			AmsIjWaterfront.scheepvaartmuseum(model)
		"eye_filmmuseum":
			AmsIjWaterfront.eye_filmmuseum(model)
		"adam_toren":
			AmsIjWaterfront.adam_toren(model)
		"muziekgebouw_bimhuis":
			AmsIjWaterfront.muziekgebouw_bimhuis(model)
		"oba_oosterdok":
			AmsIjWaterfront.oba_oosterdok(model)
		"het_schip":
			AmsIjWaterfront.het_schip(model)
		"pontsteiger":
			AmsIjWaterfront.pontsteiger(model)
		"silodam":
			AmsIjWaterfront.silodam(model)
		"gashouder_amsterdam":
			AmsIjWaterfront.gashouder_amsterdam(model)
		"olympisch_stadion_amsterdam":
			AmsIjWaterfront.olympisch_stadion_amsterdam(model)
		"johan_cruijff_arena":
			AmsIjWaterfront.johan_cruijff_arena(model)
		# Bespoke Monumental Bridges (`AMS-4.1`)
		"magere_brug":
			AmsBridges.magere_brug(model)
		"blauwbrug":
			AmsBridges.blauwbrug(model)
		"torensluis":
			AmsBridges.torensluis(model)
		"python_bridge":
			AmsBridges.python_bridge(model)
		_:
			return false
	return true
