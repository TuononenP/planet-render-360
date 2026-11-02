class_name LandmarkSetCentralHistoric
extends RefCounted

## Builders of the central_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryCentralHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"prague_orloj_tower": LandmarkChTowers.orloj(model)
		"powder_tower_prague": LandmarkChTowers.powder(model)
		"fishermans_bastion_budapest": LandmarkChBudapest.bastion(model)
		"wawel_castle": LandmarkChPoland.wawel(model)
		"st_marys_basilica_krakow": LandmarkChPoland.marys(model)
		"palace_of_culture_warsaw": LandmarkChWarsaw.palace(model)
		"frauenkirche_munich": LandmarkChGermany.munich(model)
		"dresden_frauenkirche": LandmarkChGermany.dresden(model)
		"berlin_cathedral": LandmarkChBerlin.berlin(model)
		"heidelberg_castle": LandmarkChCastles.heidelberg(model)
		"hohensalzburg_fortress": LandmarkChCastles.hohensalzburg(model)
		"porta_nigra": LandmarkChPorta.porta_nigra(model)
		_:
			return false
	return true
