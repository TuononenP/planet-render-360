class_name LandmarkSetWesternHistoric
extends RefCounted

## Builders of the western_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryWesternHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"sainte_chapelle": LandmarkWhParis.sainte_chapelle(model)
		"palais_garnier": LandmarkWhGarnier.palais_garnier(model)
		"chartres_cathedral": LandmarkWhCathedrals.chartres(model)
		"strasbourg_cathedral": LandmarkWhCathedrals.strasbourg(model)
		"palais_des_papes_avignon": LandmarkWhFortress.palais_des_papes(model)
		"carcassonne_cite": LandmarkWhFortress.carcassonne(model)
		"chateau_de_chambord": LandmarkWhChambord.chambord(model)
		"canterbury_cathedral": LandmarkWhEngland.canterbury(model)
		"york_minster": LandmarkWhEngland.york_minster(model)
		"windsor_castle": LandmarkWhWindsor.windsor_castle(model)
		"roman_baths_bath": LandmarkWhCivic.roman_baths(model)
		"brussels_town_hall": LandmarkWhLowCountries.brussels_town_hall(model)
		"bruges_belfry": LandmarkWhLowCountries.bruges_belfry(model)
		_:
			return false
	return true
