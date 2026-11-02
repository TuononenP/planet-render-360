class_name LandmarkSetAsiaSouth
extends RefCounted

## Builders of the south and south-east Asia landmark batch: one `match`
## arm per registry type of LandmarkRegistryAsiaSouth. Returns false for a
## type it does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"taj_mahal":
			LandmarkAgraDelhi.taj_mahal(model)
		"india_gate":
			LandmarkAgraDelhi.india_gate(model)
		"qutub_minar":
			LandmarkAgraDelhi.qutub_minar(model)
		"gateway_of_india":
			LandmarkIndiaMisc.gateway_of_india(model)
		"lotus_temple":
			LandmarkIndiaMisc.lotus_temple(model)
		"hawa_mahal":
			LandmarkIndiaMisc.hawa_mahal(model)
		"charminar":
			LandmarkIndiaMisc.charminar(model)
		"golden_temple":
			LandmarkIndiaShrines.golden_temple(model)
		"boudhanath":
			LandmarkIndiaShrines.boudhanath(model)
		"angkor_wat":
			LandmarkSeaTemples.angkor_wat(model)
		"wat_arun":
			LandmarkSeaTemples.wat_arun(model)
		"shwedagon":
			LandmarkSeaStupas.shwedagon(model)
		"borobudur":
			LandmarkSeaStupas.borobudur(model)
		"petronas_towers":
			LandmarkSeaTowers.petronas(model)
		"marina_bay_sands":
			LandmarkSeaTowers.marina_bay_sands(model)
		"monas":
			LandmarkSeaTowers.monas(model)
		_:
			return false
	return true
