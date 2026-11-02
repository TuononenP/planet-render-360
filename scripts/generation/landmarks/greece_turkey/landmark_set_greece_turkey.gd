class_name LandmarkSetGreeceTurkey
extends RefCounted

## Builders of the greece_turkey landmark batch: one `match` arm per
## registry type of LandmarkRegistryGreeceTurkey. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"temple_of_poseidon_sounion": LandmarkGtSanctuaries.sounion(model)
		"delphi_temple_of_apollo": LandmarkGtSanctuaries.delphi(model)
		"olympia_temple_of_zeus": LandmarkGtOlympia.olympia(model)
		"mycenae_lion_gate": LandmarkGtBronzeAge.lion_gate(model)
		"knossos_palace": LandmarkGtKnossos.knossos(model)
		"epidaurus_theatre": LandmarkGtMonuments.epidaurus(model)
		"library_of_celsus": LandmarkGtCelsus.celsus(model)
		"white_tower_thessaloniki": LandmarkGtMonuments.white_tower(model)
		"topkapi_palace": LandmarkGtTopkapi.topkapi(model)
		"suleymaniye_mosque": LandmarkGtIstanbul.suleymaniye(model)
		_:
			return false
	return true
