class_name LandmarkSetIndiaHistoric
extends RefCounted

## Builders of the india_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryIndiaHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

const RF = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_red_fort.gd")
const AF = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_amber.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"red_fort_delhi":
			RF.red_fort_delhi(model)
		"humayuns_tomb":
			LandmarkIndMughal.humayuns_tomb(model)
		"jama_masjid_delhi":
			LandmarkIndMughal.jama_masjid_delhi(model)
		"konark_sun_temple":
			LandmarkIndNagara.konark_sun_temple(model)
		"khajuraho_kandariya_mahadeva":
			LandmarkIndNagara.kandariya_mahadeva(model)
		"brihadisvara_temple":
			LandmarkIndSouth.brihadisvara_temple(model)
		"meenakshi_temple":
			LandmarkIndSouth.meenakshi_temple(model)
		"mysore_palace":
			LandmarkIndPalaces.mysore_palace(model)
		"victoria_memorial_kolkata":
			LandmarkIndPalaces.victoria_memorial_kolkata(model)
		"amber_fort":
			AF.amber_fort(model)
		_:
			return false
	return true
