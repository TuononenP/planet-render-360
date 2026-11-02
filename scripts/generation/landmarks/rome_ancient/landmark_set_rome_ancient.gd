class_name LandmarkSetRomeAncient
extends RefCounted

## Builders of the rome_ancient landmark batch: one `match` arm per
## registry type of LandmarkRegistryRomeAncient. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"roman_forum": LandmarkRmAForum.forum(model)
		"arch_of_constantine": LandmarkRmAArches.constantine(model)
		"arch_of_titus": LandmarkRmAArches.titus(model)
		"porta_maggiore": LandmarkRmAArches.porta_maggiore(model)
		"trajans_column": LandmarkRmAColumns.trajan(model)
		"column_of_marcus_aurelius": LandmarkRmAColumns.marcus_aurelius(model)
		"pyramid_of_cestius": LandmarkRmAColumns.pyramid(model)
		"circus_maximus": LandmarkRmAArena.circus(model)
		"baths_of_caracalla": LandmarkRmAArena.baths(model)
		"theatre_of_marcellus": LandmarkRmAArena.marcellus(model)
		"basilica_of_maxentius": LandmarkRmAImperial.basilica(model)
		"palatine_palace": LandmarkRmAImperial.palatine(model)
		"trajans_market": LandmarkRmAImperial.markets(model)
		"mausoleum_of_augustus": LandmarkRmATombs.mausoleum(model)
		"ara_pacis": LandmarkRmATombs.ara_pacis(model)
		"tomb_of_cecilia_metella": LandmarkRmATombs.caecilia(model)
		_:
			return false
	return true
