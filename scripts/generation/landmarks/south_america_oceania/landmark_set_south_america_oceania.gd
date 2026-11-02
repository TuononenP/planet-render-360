class_name LandmarkSetSouthAmericaOceania
extends RefCounted

## Builders of the south america oceania landmark batch: one `match` arm per
## registry type of LandmarkRegistrySouthAmericaOceania. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"christ_redeemer": LandmarkSaoRio.christ(model)
		"rio_cathedral": LandmarkSaoRio.cathedral(model)
		"machu_picchu": LandmarkSaoAncient.machu_picchu(model)
		"moai_tongariki": LandmarkSaoAncient.moai(model)
		"brasilia_cathedral": LandmarkSaoBrasilia.cathedral(model)
		"brazil_congress": LandmarkSaoBrasilia.congress(model)
		"obelisco_buenos_aires": LandmarkSaoCities.obelisco(model)
		"gran_torre_santiago": LandmarkSaoCities.gran_torre(model)
		"teatro_amazonas": LandmarkSaoCities.teatro_amazonas(model)
		"auckland_sky_tower": LandmarkSaoTowers.sky_tower(model)
		"sydney_tower": LandmarkSaoTowers.sydney_tower(model)
		"flinders_street_station": LandmarkSaoAustralia.flinders(model)
		"parliament_house_canberra": LandmarkSaoCanberra.parliament(model)
		_:
			return false
	return true
