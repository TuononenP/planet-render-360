class_name LandmarkSetEgypt
extends RefCounted

## Builders of the egypt landmark batch: one `match` arm per
## registry type of LandmarkRegistryEgypt. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"pyramid_of_khafre": LandmarkEgGiza.khafre(model)
		"pyramid_of_menkaure": LandmarkEgGiza.menkaure(model)
		"step_pyramid_djoser": LandmarkEgSaqqara.djoser(model)
		"bent_pyramid": LandmarkEgSaqqara.bent(model)
		"red_pyramid": LandmarkEgSaqqara.red_pyramid(model)
		"pyramid_of_meidum": LandmarkEgSaqqara.meidum(model)
		"karnak_temple": LandmarkEgKarnak.karnak(model)
		"luxor_temple": LandmarkEgKarnak.luxor(model)
		"hatshepsut_temple": LandmarkEgThebesWest.hatshepsut(model)
		"colossi_of_memnon": LandmarkEgThebesWest.memnon(model)
		"ramesseum": LandmarkEgThebesWest.ramesseum(model)
		"philae_temple": LandmarkEgNile.philae(model)
		"edfu_temple": LandmarkEgNile.edfu(model)
		"kom_ombo_temple": LandmarkEgNile.kom_ombo(model)
		"muhammad_ali_mosque": LandmarkEgCairo.muhammad_ali(model)
		"sultan_hassan_mosque": LandmarkEgCairo.sultan_hassan(model)
		"qaitbay_citadel": LandmarkEgAlexandria.qaitbay(model)
		"bibliotheca_alexandrina": LandmarkEgAlexandria.bibliotheca(model)
		_:
			return false
	return true
