class_name LandmarkSetAngkorThom
extends RefCounted

## Builders of the Siem Reap batch A: one `match` arm per registry type of
## LandmarkRegistryAngkorThom. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"baphuon":
			LandmarkAngThom.baphuon(model)
		"phimeanakas":
			LandmarkAngThom.phimeanakas(model)
		"terrace_of_the_elephants":
			LandmarkAngTerraces.elephants(model)
		"terrace_of_the_leper_king":
			LandmarkAngTerraces.leper_king(model)
		"preah_palilay":
			LandmarkAngSmall.preah_palilay(model)
		"thommanon":
			LandmarkAngSmall.thommanon(model)
		"chau_say_tevoda":
			LandmarkAngSmall.chau_say_tevoda(model)
		_:
			return false
	return true
