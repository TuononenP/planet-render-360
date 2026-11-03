class_name LandmarkSetSwedenStockholm
extends RefCounted

## Builders of the sweden_stockholm landmark batch: one `match` arm per
## registry type of LandmarkRegistrySwedenStockholm. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
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
