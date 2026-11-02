class_name LandmarkSetIberia
extends RefCounted

## Builders of the iberia landmark batch: one `match` arm per
## registry type of LandmarkRegistryIberia. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"royal_palace_madrid": LandmarkIbRoyal.palace(model)
		"almudena_cathedral": LandmarkIbRoyal.almudena(model)
		"toledo_alcazar": LandmarkIbRoyal.toledo_alcazar(model)
		"segovia_aqueduct": LandmarkIbArches.segovia(model)
		"mezquita_cordoba": LandmarkIbArches.mezquita(model)
		"seville_alcazar": LandmarkIbArches.seville_alcazar(model)
		"santiago_cathedral": LandmarkIbAtlantic.santiago(model)
		"pena_palace": LandmarkIbAtlantic.pena(model)
		"jeronimos_monastery": LandmarkIbAtlantic.jeronimos(model)
		_:
			return false
	return true
