class_name LandmarkSetItalyHistoric
extends RefCounted

## Builders of the italy_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryItalyHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"pompeii_forum": LandmarkItlAncient.pompeii_forum(model)
		"verona_arena": LandmarkItlAncient.verona_arena(model)
		"palazzo_vecchio": LandmarkItlTowns.palazzo_vecchio(model)
		"torre_del_mangia": LandmarkItlTowns.torre_del_mangia(model)
		"san_gimignano_towers": LandmarkItlSkyline.san_gimignano(model)
		"bologna_two_towers": LandmarkItlSkyline.bologna(model)
		"mole_antonelliana": LandmarkItlChurches.mole_antonelliana(model)
		"st_marks_basilica_venice": LandmarkItlVenice.basilica(model)
		"bridge_of_sighs": LandmarkItlVenice.bridge_of_sighs(model)
		"basilica_st_francis_assisi": LandmarkItlChurches.assisi(model)
		_:
			return false
	return true
