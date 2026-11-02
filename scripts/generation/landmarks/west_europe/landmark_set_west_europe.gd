class_name LandmarkSetWestEurope
extends RefCounted

## Builders of the west europe landmark batch: one `match` arm per
## registry type of LandmarkRegistryWestEurope. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"notre_dame": LandmarkParisChurches.notre_dame(model)
		"sacre_coeur": LandmarkSacreCoeur.sacre_coeur(model)
		"pantheon_paris": LandmarkParisDomes.pantheon(model)
		"les_invalides": LandmarkParisDomes.invalides(model)
		"arc_de_triomphe": LandmarkParisMonuments.arc_de_triomphe(model)
		"louvre_pyramid": LandmarkParisMonuments.louvre_pyramid(model)
		"versailles": LandmarkVersailles.versailles(model)
		"atomium": LandmarkWestModern.atomium(model)
		"london_eye": LandmarkWestModern.london_eye(model)
		"shard": LandmarkWestModern.shard(model)
		"st_mary_axe": LandmarkWestModern.gherkin(model)
		"st_pauls": LandmarkLondonHeritage.st_pauls(model)
		"tower_of_london": LandmarkLondonPalaces.tower_of_london(model)
		"buckingham_palace": LandmarkLondonPalaces.buckingham(model)
		"westminster_abbey": LandmarkLondonHeritage.westminster_abbey(model)
		"mont_saint_michel": LandmarkWestEarly.mont_saint_michel(model)
		"stonehenge": LandmarkWestEarly.stonehenge(model)
		"edinburgh_castle": LandmarkEdinburgh.edinburgh_castle(model)
		_:
			return false
	return true
