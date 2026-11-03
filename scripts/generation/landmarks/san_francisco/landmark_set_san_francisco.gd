class_name LandmarkSetSanFrancisco
extends RefCounted

## Builders of the San Francisco landmark batch: one `match` arm per
## registry type of LandmarkRegistrySanFrancisco. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"salesforce_tower": LandmarkSfTowers.salesforce_tower(model)
		"coit_tower": LandmarkSfTowers.coit_tower(model)
		"sutro_tower": LandmarkSfSutro.build(model)
		"ferry_building": LandmarkSfFerry.build(model)
		"alcatraz": LandmarkSfAlcatraz.build(model)
		"bay_bridge_west": LandmarkSfBayBridge.west(model)
		"bay_bridge_east": LandmarkSfBayBridge.east(model)
		"sf_city_hall": LandmarkSfCivic.city_hall(model)
		"palace_of_fine_arts": LandmarkSfPalace.build(model)
		_:
			return false
	return true
