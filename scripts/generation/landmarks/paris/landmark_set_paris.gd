class_name LandmarkSetParis
extends RefCounted

## Builders of the Paris landmark batch (`LandmarkRegistryParis`).
## Returns false for unknown types so `LandmarkBuilder` continues down the sets list.

static func build(model: Node3D, type: String) -> bool:
	var spec := PaTowerSpecs.spec_for(type)
	if not spec.is_empty():
		TowerSpec.build(model, spec)
		if type == "tour_montparnasse":
			model.set_meta(LandmarkLights.HALO_META, [
				[Vector3(-22.0, 210.5, 0.0), 2.8, Color(1.0, 0.12, 0.05)],
				[Vector3(22.0, 210.5, 0.0), 2.8, Color(1.0, 0.12, 0.05)],
			])
		elif type == "tour_the_link":
			model.set_meta(LandmarkLights.HALO_META, [[Vector3(14.0, 241.5, 0.0), 2.8, Color(1.0, 0.12, 0.05)]])
		elif type == "tour_first":
			model.set_meta(LandmarkLights.HALO_META, [[Vector3(0.0, 231.0, 0.0), 2.8, Color(1.0, 0.12, 0.05)]])
		elif type == "tour_hekla":
			model.set_meta(LandmarkLights.HALO_META, [[Vector3(0.0, 220.5, 0.0), 2.6, Color(1.0, 0.12, 0.05)]])
		return true
	match type:
		"palais_de_chaillot":
			LandmarkPaChaillot.build(model)
		"ecole_militaire":
			LandmarkPaChampDeMars.ecole_militaire(model)
		"musee_quai_branly":
			LandmarkPaChampDeMars.musee_quai_branly(model)
		"cathedrale_sainte_trinite":
			LandmarkPaChampDeMars.cathedrale_sainte_trinite(model)
		"palais_de_tokyo":
			LandmarkPaSeineWest.palais_de_tokyo(model)
		"maison_de_la_radio":
			LandmarkPaSeineWest.maison_de_la_radio(model)
		"statue_liberte_paris":
			LandmarkPaSeineWest.statue_liberte_paris(model)
		"grand_palais":
			LandmarkPaGrandPetitPalais.grand_palais(model)
		"petit_palais":
			LandmarkPaGrandPetitPalais.petit_palais(model)
		"place_de_la_concorde":
			LandmarkPaConcordeBourbon.place_de_la_concorde(model)
		"palais_bourbon":
			LandmarkPaConcordeBourbon.palais_bourbon(model)
		"palais_du_louvre":
			LandmarkPaLouvreOrsay.palais_du_louvre(model)
		"musee_dorsay":
			LandmarkPaLouvreOrsay.musee_dorsay(model)
		"centre_pompidou":
			LandmarkPaPompidouHdv.centre_pompidou(model)
		"hotel_de_ville_paris":
			LandmarkPaPompidouHdv.hotel_de_ville_paris(model)
		"conciergerie_palais_justice":
			LandmarkPaPompidouHdv.conciergerie(model)
		"eglise_madeleine":
			LandmarkPaClassicalChurches.eglise_madeleine(model)
		"saint_sulpice":
			LandmarkPaClassicalChurches.saint_sulpice(model)
		"saint_eustache":
			LandmarkPaClassicalChurches.saint_eustache(model)
		"palais_luxembourg":
			LandmarkPaPalacesLeftbank.palais_luxembourg(model)
		"institut_de_france":
			LandmarkPaPalacesLeftbank.institut_de_france(model)
		"palais_royal_bourse":
			LandmarkPaPalacesLeftbank.palais_royal(model)
		"place_des_vosges":
			LandmarkPaPalacesLeftbank.place_des_vosges(model)
		"place_vendome":
			LandmarkPaSquaresStations.place_vendome(model)
		"bastille_ensemble":
			LandmarkPaSquaresStations.bastille_ensemble(model)
		"gare_de_lyon":
			LandmarkPaSquaresStations.gare_de_lyon(model)
		"gare_de_lest":
			LandmarkPaSquaresStations.gare_de_lest(model)
		"grande_arche":
			LandmarkPaModernIcons.grande_arche(model)
		"fondation_louis_vuitton":
			LandmarkPaModernIcons.fondation_louis_vuitton(model)
		"bnf_mitterrand":
			LandmarkPaModernIcons.bnf_mitterrand(model)
		"pont_de_bir_hakeim":
			LandmarkPaBridgeBirHakeim.build(model)
		"pont_alexandre_iii":
			LandmarkPaBridgeAlexandreIII.build(model)
		"pont_d_iena":
			LandmarkPaBridgeIena.build(model)
		"pont_neuf":
			LandmarkPaBridgeNeuf.build(model)
		"passerelle_debilly":
			LandmarkPaBridgeDebilly.build(model)
		_:
			return false
	return true
