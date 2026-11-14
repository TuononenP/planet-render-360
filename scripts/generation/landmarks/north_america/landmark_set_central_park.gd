class_name LandmarkSetCentralPark
extends RefCounted

## Builders of LandmarkRegistryCentralPark. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"bethesda_fountain": LandmarkCentralPark.bethesda_fountain(model)
		"bow_bridge": LandmarkCentralPark.bow_bridge(model)
		"gapstow_bridge": LandmarkCentralPark.gapstow_bridge(model)
		"belvedere_castle": LandmarkCentralPark.belvedere_castle(model)
		"cleopatras_needle": LandmarkCentralPark.cleopatras_needle(model)
		_:
			return false
	return true
